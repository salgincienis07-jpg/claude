/* VEXMIRA FASTDL 5.4.4
 * - Sets the FastDL address (sv_downloadurl) so custom files are downloaded over HTTP (fast).
 *   Address: cvar vex_fastdl_url (default below), off: vex_fastdl 0.
 * - Reads the REAL list the server sends to players (ReHLDS resource list via ReAPI RH_SV_AddResource),
 *   so every file of every plugin (vexmira_core / gear / extra, giant bosses, map) is seen.
 *   Stock game files (players already have them) are skipped: data/vexmira_fastdl_stock.txt + valve folder.
 *   Lists with full FastDL links:
 *     addons/amxmodx/data/vexmira_fastdl/<map>.txt   (this map)
 *     addons/amxmodx/data/vexmira_fastdl/ALL.txt     (every map so far, no duplicates)
 * - Protection: a file sent to players but missing on the server -> logs/vexmira_fastdl.log
 * Console: vex_fastdl_files | vex_fastdl_check [boss] (asks the FastDL web server for each file)
 * vex_fastdl_rate (100000): minimum rate, so a file missing on FastDL still downloads ~4x faster in game.
 */
#include <amxmodx>
#include <reapi>
#include <sockets>

#define VXF_URL "http://f16.oyunyoneticisi.biz/cstrike/"

new g_pUrl, g_pOn;
new Array:g_aFiles, Trie:g_tSeen, Trie:g_tStock;
new g_iMissing, g_iCustom, g_iStock;
new Array:g_aCustom, g_pRate;
// vex_fastdl_check state
new g_iChkIdx, g_iChkSock, g_iChkOk, g_iChkBad, g_iChkErr, g_iChkBy, Float:g_fChkT, bool:g_bChkBoss, g_szChkHost[96], g_szChkBase[96];

public plugin_precache()
{
	g_pUrl = register_cvar("vex_fastdl_url", VXF_URL);
	g_pOn = register_cvar("vex_fastdl", "1");
	g_aFiles = ArrayCreate(128);
	g_tSeen = TrieCreate();
	g_tStock = TrieCreate();
	g_aCustom = ArrayCreate(128);
	g_pRate = register_cvar("vex_fastdl_rate", "100000");
	LoadStock();
	RegisterHookChain(RH_SV_AddResource, "fw_AddResource", 0);
	ApplyUrl();
}

public plugin_init()
{
	register_plugin("Vexmira FastDL", "5.4.4", "Vexmira");
	register_concmd("vex_fastdl_files", "cmd_Files", ADMIN_RCON, "- FastDL dosya listesi");
	register_concmd("vex_fastdl_check", "cmd_Check", ADMIN_RCON, "[boss] - her ozel dosyanin FastDL sunucusunda olup olmadigini dener");
}

public plugin_cfg()
{
	ApplyUrl();
	set_task(3.0, "task_Apply"); // the panel / server.cfg may set its own value after us
	set_task(5.0, "task_Write");
}

public task_Apply() ApplyUrl();

ApplyUrl()
{
	if (!get_pcvar_num(g_pOn)) return;
	new url[192];
	get_pcvar_string(g_pUrl, url, charsmax(url));
	trim(url);
	if (!url[0]) return;
	new l = strlen(url);
	if (url[l - 1] != '/' && l < charsmax(url)) { url[l] = '/'; url[l + 1] = 0; }
	set_cvar_string("sv_downloadurl", url);
	set_cvar_num("sv_allowdownload", 1);
	if (cvar_exists("sv_send_resources")) set_cvar_num("sv_send_resources", 1);
	// a file that is NOT on FastDL falls back to the in-game (UDP) download, whose speed is the player's rate:
	// default 25000 = ~25 KB/s (a 700 KB boss = ~30 s). A higher minimum rate makes that fallback ~4x faster.
	new r = get_pcvar_num(g_pRate);
	if (r >= 25000)
	{
		if (get_cvar_num("sv_maxrate") < r) set_cvar_num("sv_maxrate", r);
		if (get_cvar_num("sv_minrate") < r) set_cvar_num("sv_minrate", r);
	}
}

LoadStock()
{
	new dir[160], fn[200], line[160];
	get_localinfo("amxx_datadir", dir, charsmax(dir));
	if (!dir[0]) copy(dir, charsmax(dir), "addons/amxmodx/data");
	formatex(fn, charsmax(fn), "%s/vexmira_fastdl_stock.txt", dir);
	new f = fopen(fn, "rt");
	if (!f) return;
	while (!feof(f))
	{
		fgets(f, line, charsmax(line));
		trim(line);
		if (!line[0] || line[0] == '/' || line[0] == ';') continue;
		strtolower(line);
		TrieSetCell(g_tStock, line, 1);
	}
	fclose(f);
}

// Called by the engine for every entry of the list that is sent to connecting players.
public fw_AddResource(ResourceType_t:type, const filename[], size, flags, index)
{
	new p[128];
	switch (type)
	{
		case t_sound: formatex(p, charsmax(p), "sound/%s", filename);
		case t_model, t_generic, t_world: copy(p, charsmax(p), filename);
		default: return HC_CONTINUE; // decals, event scripts, skins: stock / not downloadable here
	}
	if (!p[0] || p[0] == '*' || p[0] == '!') return HC_CONTINUE;
	replace_all(p, charsmax(p), "\", "/");
	if (TrieKeyExists(g_tSeen, p)) return HC_CONTINUE;
	TrieSetCell(g_tSeen, p, 1);
	ArrayPushString(g_aFiles, p);
	return HC_CONTINUE;
}

bool:IsStock(const p[])
{
	new low[128], v[140];
	copy(low, charsmax(low), p);
	strtolower(low);
	if (TrieKeyExists(g_tStock, low)) return true;
	formatex(v, charsmax(v), "../valve/%s", p); // Half-Life base files
	if (file_exists(v)) return true;
	if (!file_exists(p) && file_exists(p, true)) return true; // only inside the game's own packages (pak / valve) -> stock
	return false;
}

public task_Write()
{
	new dir[160], map[64], fn[200], url[192], line[320], p[128];
	get_localinfo("amxx_datadir", dir, charsmax(dir));
	if (!dir[0]) copy(dir, charsmax(dir), "addons/amxmodx/data");
	add(dir, charsmax(dir), "/vexmira_fastdl");
	if (!dir_exists(dir)) mkdir(dir);
	get_mapname(map, charsmax(map));
	get_pcvar_string(g_pUrl, url, charsmax(url));
	formatex(fn, charsmax(fn), "%s/%s.txt", dir, map);
	delete_file(fn);
	new f = fopen(fn, "wt");
	new Trie:all = TrieCreate();
	new allfn[200]; formatex(allfn, charsmax(allfn), "%s/ALL.txt", dir);
	new af = fopen(allfn, "rt");
	if (af) { while (!feof(af)) { fgets(af, line, charsmax(line)); trim(line); if (line[0]) TrieSetCell(all, line, 1); } fclose(af); }
	af = fopen(allfn, "at");
	new n = ArraySize(g_aFiles);
	g_iMissing = 0; g_iCustom = 0; g_iStock = 0;
	ArrayClear(g_aCustom);
	for (new i = 0; i < n; i++)
	{
		ArrayGetString(g_aFiles, i, p, charsmax(p));
		if (IsStock(p)) { g_iStock++; continue; }
		if (!file_exists(p, true))
		{
			g_iMissing++;
			log_to_file("vexmira_fastdl.log", "[FastDL] EKSIK (oyuncuya gidiyor ama sunucuda yok -> 'not found' cokmesi): %s", p);
			continue;
		}
		g_iCustom++;
		ArrayPushString(g_aCustom, p);
		formatex(line, charsmax(line), "%s%s", url, p);
		if (f) fprintf(f, "%s^n", line);
		if (af && !TrieKeyExists(all, line)) { fprintf(af, "%s^n", line); TrieSetCell(all, line, 1); }
	}
	if (f) fclose(f);
	if (af) fclose(af);
	TrieDestroy(all);
	log_amx("[FastDL] %s | listede %d dosya: %d ozel (FastDL'de olmali), %d stok (atlandi), %d EKSIK -> %s", url, n, g_iCustom, g_iStock, g_iMissing, fn);
}

public cmd_Files(id, level, cid)
{
	if (id && !(get_user_flags(id) & level)) return PLUGIN_HANDLED;
	new url[192]; get_cvar_string("sv_downloadurl", url, charsmax(url));
	console_print(id, "[FastDL] sv_downloadurl = %s", url);
	console_print(id, "[FastDL] oyuncuya giden %d dosya: %d OZEL, %d stok (oyuncuda zaten var), %d EKSIK", ArraySize(g_aFiles), g_iCustom, g_iStock, g_iMissing);
	console_print(id, "[FastDL] ozel dosya listesi: addons/amxmodx/data/vexmira_fastdl/<harita>.txt ve ALL.txt");
	return PLUGIN_HANDLED;
}

// ---- vex_fastdl_check: asks the FastDL web server for every custom file (HTTP HEAD) ----
public cmd_Check(id, level, cid)
{
	if (id && !(get_user_flags(id) & level)) return PLUGIN_HANDLED;
	if (g_iChkSock || task_exists(7741)) { console_print(id, "[FastDL] kontrol zaten calisiyor"); return PLUGIN_HANDLED; }
	new arg[16]; read_argv(1, arg, charsmax(arg));
	g_bChkBoss = equali(arg, "boss") ? true : false;
	new url[192]; get_pcvar_string(g_pUrl, url, charsmax(url));
	// http://host[:port]/base/
	new pos = contain(url, "://");
	new rest[192];
	if (pos != -1) copy(rest, charsmax(rest), url[pos + 3]); else copy(rest, charsmax(rest), url);
	new sl = contain(rest, "/");
	if (sl == -1) { copy(g_szChkHost, charsmax(g_szChkHost), rest); copy(g_szChkBase, charsmax(g_szChkBase), "/"); }
	else { copy(g_szChkBase, charsmax(g_szChkBase), rest[sl]); rest[sl] = 0; copy(g_szChkHost, charsmax(g_szChkHost), rest); }
	g_iChkIdx = 0; g_iChkOk = 0; g_iChkBad = 0; g_iChkErr = 0; g_iChkSock = 0; g_iChkBy = id;
	console_print(id, "[FastDL] %d ozel dosya %s uzerinde deneniyor%s... sonuc: logs/vexmira_fastdl.log", ArraySize(g_aCustom), g_szChkHost, g_bChkBoss ? " (sadece oyuncu/boss modelleri)" : "");
	log_to_file("vexmira_fastdl.log", "[FastDL] ---- KONTROL BASLADI (%s%s) ----", g_szChkHost, g_szChkBase);
	set_task(0.05, "task_Check", 7741, _, _, "b");
	return PLUGIN_HANDLED;
}

public task_Check()
{
	new n = ArraySize(g_aCustom), p[128];
	if (g_iChkSock)
	{
		static buf[256];
		if (socket_is_readable(g_iChkSock, 0))
		{
			buf[0] = 0;
			socket_recv(g_iChkSock, buf, charsmax(buf));
			ArrayGetString(g_aCustom, g_iChkIdx, p, charsmax(p));
			if (contain(buf, " 200") != -1) g_iChkOk++;
			else
			{
				g_iChkBad++;
				new code[16]; copy(code, charsmax(code), buf[contain(buf, " ") != -1 ? contain(buf, " ") + 1 : 0]); code[3] = 0;
				log_to_file("vexmira_fastdl.log", "[FastDL] FASTDL'DE YOK (%s) -> oyuncu bunu YAVAS indirir: %s", code, p);
			}
			socket_close(g_iChkSock); g_iChkSock = 0; g_iChkIdx++;
		}
		else if (get_gametime() - g_fChkT > 4.0)
		{
			ArrayGetString(g_aCustom, g_iChkIdx, p, charsmax(p));
			g_iChkErr++;
			log_to_file("vexmira_fastdl.log", "[FastDL] cevap yok (zaman asimi): %s", p);
			socket_close(g_iChkSock); g_iChkSock = 0; g_iChkIdx++;
		}
		return;
	}
	while (g_iChkIdx < n)
	{
		ArrayGetString(g_aCustom, g_iChkIdx, p, charsmax(p));
		if (!g_bChkBoss || equal(p, "models/player/", 14)) break;
		g_iChkIdx++;
	}
	if (g_iChkIdx >= n)
	{
		remove_task(7741);
		log_to_file("vexmira_fastdl.log", "[FastDL] ---- KONTROL BITTI: %d var, %d FASTDL'DE YOK, %d cevapsiz ----", g_iChkOk, g_iChkBad, g_iChkErr);
		log_amx("[FastDL] kontrol bitti: %d dosya FastDL'de var, %d YOK, %d cevapsiz (liste: logs/vexmira_fastdl.log)", g_iChkOk, g_iChkBad, g_iChkErr);
		if (g_iChkBy && is_user_connected(g_iChkBy)) client_print(g_iChkBy, print_console, "[FastDL] kontrol bitti: %d var, %d YOK, %d cevapsiz", g_iChkOk, g_iChkBad, g_iChkErr);
		return;
	}
	new err;
	g_iChkSock = socket_open(g_szChkHost, 80, SOCKET_TCP, err);
	if (!g_iChkSock || err)
	{
		g_iChkSock = 0; g_iChkErr++; g_iChkIdx++;
		log_to_file("vexmira_fastdl.log", "[FastDL] baglanti kurulamadi (%d): %s", err, g_szChkHost);
		return;
	}
	static req[400];
	new l = formatex(req, charsmax(req), "HEAD %s%s HTTP/1.1^r^nHost: %s^r^nUser-Agent: Half-Life^r^nConnection: close^r^n^r^n", g_szChkBase, p, g_szChkHost);
	socket_send(g_iChkSock, req, l);
	g_fChkT = get_gametime();
}
