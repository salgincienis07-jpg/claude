/* VEXMIRA FASTDL 5.4.2
 * - Sets the FastDL address (sv_downloadurl) so every custom file is downloaded over HTTP (fast)
 *   instead of the slow in-game download. Address: cvar vex_fastdl_url.
 * - Records EVERY file the server sends to players on this map (models, sounds, sprites, generic,
 *   giant boss copies, map) and writes the list with full FastDL links:
 *     addons/amxmodx/data/vexmira_fastdl/<map>.txt      (this map)
 *     addons/amxmodx/data/vexmira_fastdl/ALL.txt        (every map seen so far, no duplicates)
 * - Protection: a file that is sent to players but does not exist on the server is reported
 *   (logs/vexmira_fastdl.log) - such a file crashes players with "... not found".
 * Put this plugin at the TOP of plugins.ini (before vexmira_core) so it sees every file.
 * Console: vex_fastdl_files  -> counts + list location
 */
#include <amxmodx>
#include <fakemeta>

#define VXF_URL "http://f16.oyunyoneticisi.biz/cstrike/"

new g_pUrl, g_pOn;
new Array:g_aFiles, Trie:g_tSeen;
new g_iMissing;

public plugin_precache()
{
	g_pUrl = register_cvar("vex_fastdl_url", VXF_URL);
	g_pOn = register_cvar("vex_fastdl", "1");
	g_aFiles = ArrayCreate(128);
	g_tSeen = TrieCreate();
	register_forward(FM_PrecacheModel, "fw_PcModel", 1);
	register_forward(FM_PrecacheSound, "fw_PcSound", 1);
	register_forward(FM_PrecacheGeneric, "fw_PcGeneric", 1);
	new map[64], p[128];
	get_mapname(map, charsmax(map));
	formatex(p, charsmax(p), "maps/%s.bsp", map); AddFile(p);
	formatex(p, charsmax(p), "maps/%s.res", map); if (file_exists(p, true)) AddFile(p);
	ApplyUrl();
}

public plugin_init()
{
	register_plugin("Vexmira FastDL", "5.4.2", "Vexmira");
	register_concmd("vex_fastdl_files", "cmd_Files", ADMIN_RCON, "- FastDL dosya listesi");
}

public plugin_cfg()
{
	ApplyUrl();
	set_task(3.0, "task_Apply"); // the panel / server.cfg may set its own value after us
	set_task(4.0, "task_Write");
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

public fw_PcModel(const path[]) { if (path[0] && path[0] != '*') AddFile(path); return FMRES_IGNORED; }
public fw_PcGeneric(const path[]) { if (path[0]) AddFile(path); return FMRES_IGNORED; }
public fw_PcSound(const path[])
{
	if (!path[0] || path[0] == '!' || path[0] == '*') return FMRES_IGNORED;
	new p[128];
	formatex(p, charsmax(p), "sound/%s", path);
	AddFile(p);
	return FMRES_IGNORED;
}

AddFile(const path[])
{
	new p[128];
	copy(p, charsmax(p), path);
	replace_all(p, charsmax(p), "\", "/");
	if (TrieKeyExists(g_tSeen, p)) return;
	TrieSetCell(g_tSeen, p, 1);
	ArrayPushString(g_aFiles, p);
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
	new n = ArraySize(g_aFiles), custom;
	g_iMissing = 0;
	for (new i = 0; i < n; i++)
	{
		ArrayGetString(g_aFiles, i, p, charsmax(p));
		if (!file_exists(p, true))
		{
			g_iMissing++;
			log_to_file("vexmira_fastdl.log", "[FastDL] EKSIK (sunucuda yok, oyuncuyu cokertebilir): %s", p);
			continue;
		}
		if (!file_exists(p)) continue; // stock game file (inside the base game), no download
		custom++;
		formatex(line, charsmax(line), "%s%s", url, p);
		if (f) fprintf(f, "%s^n", line);
		if (af && !TrieKeyExists(all, line)) { fprintf(af, "%s^n", line); TrieSetCell(all, line, 1); }
	}
	if (f) fclose(f);
	if (af) fclose(af);
	TrieDestroy(all);
	log_amx("[FastDL] %s | %d dosya oyuncuya gidiyor, %d ozel dosya listelendi (%s), %d EKSIK", url, n, custom, fn, g_iMissing);
}

public cmd_Files(id, level, cid)
{
	if (!(get_user_flags(id) & level) && id) return PLUGIN_HANDLED;
	new url[192]; get_cvar_string("sv_downloadurl", url, charsmax(url));
	console_print(id, "[FastDL] sv_downloadurl = %s", url);
	console_print(id, "[FastDL] bu haritada %d dosya, %d EKSIK (logs/vexmira_fastdl.log)", ArraySize(g_aFiles), g_iMissing);
	console_print(id, "[FastDL] tam liste: addons/amxmodx/data/vexmira_fastdl/<harita>.txt ve ALL.txt");
	return PLUGIN_HANDLED;
}
