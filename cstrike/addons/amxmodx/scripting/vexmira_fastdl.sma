/* VEXMIRA FASTDL 5.4.3
 * - Sets the FastDL address (sv_downloadurl) so custom files are downloaded over HTTP (fast).
 *   Address: cvar vex_fastdl_url (default below), off: vex_fastdl 0.
 * - Reads the REAL list the server sends to players (ReHLDS resource list via ReAPI RH_SV_AddResource),
 *   so every file of every plugin (vexmira_core / gear / extra, giant bosses, map) is seen.
 *   Stock game files (players already have them) are skipped: data/vexmira_fastdl_stock.txt + valve folder.
 *   Lists with full FastDL links:
 *     addons/amxmodx/data/vexmira_fastdl/<map>.txt   (this map)
 *     addons/amxmodx/data/vexmira_fastdl/ALL.txt     (every map so far, no duplicates)
 * - Protection: a file sent to players but missing on the server -> logs/vexmira_fastdl.log
 * Console: vex_fastdl_files
 */
#include <amxmodx>
#include <reapi>

#define VXF_URL "http://f16.oyunyoneticisi.biz/cstrike/"

new g_pUrl, g_pOn;
new Array:g_aFiles, Trie:g_tSeen, Trie:g_tStock;
new g_iMissing, g_iCustom, g_iStock;

public plugin_precache()
{
	g_pUrl = register_cvar("vex_fastdl_url", VXF_URL);
	g_pOn = register_cvar("vex_fastdl", "1");
	g_aFiles = ArrayCreate(128);
	g_tSeen = TrieCreate();
	g_tStock = TrieCreate();
	LoadStock();
	RegisterHookChain(RH_SV_AddResource, "fw_AddResource", 0);
	ApplyUrl();
}

public plugin_init()
{
	register_plugin("Vexmira FastDL", "5.4.3", "Vexmira");
	register_concmd("vex_fastdl_files", "cmd_Files", ADMIN_RCON, "- FastDL dosya listesi");
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
