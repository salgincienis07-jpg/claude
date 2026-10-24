/* VEXMIRA HUD v4 - themed player HUD + CS2-style top scoreboard + iPad notification banner.
 *
 *  bottom-left  : health (+ armor for humans) with solid block bars, colour by state
 *  bottom-right : weapon, clip/reserve with clip bar, money, VexCoin, AP, unread iPad count
 *  top centre   : humans score/alive | round timer + round + mode | zombies score/alive (boss HP in boss rounds)
 *  top right    : iPad banner when a message / friend request / sale arrives (sound + banner follow the
 *                 player's tablet settings: Sounds / Notifications)
 *
 * Needs vxcore_v4 (native vxc_hud). When this plugin runs, the core stops drawing its own text bars and
 * top board, so nothing is drawn twice. Everything uses director HUD messages with short hold times
 * (no ghosting), refreshed only for live players, bots skipped.
 * Tablet & Mod: smurfsexy
 */
#include <amxmodx>
#include <reapi>

#pragma semicolon 1

native vxc_hud(id, field);

#define PL_VER "4.0"
#define TASK_FAST 7400500
#define TASK_SLOW 7400501
#define NOTE_SND "vexmira/ui/ipad_note.wav"
#define NOTE_FILE "sound/vexmira/ui/ipad_note.wav"

enum { F_MODE = 0, F_EVENT, F_ROUND, F_TOTAL, F_BOSS, F_BOSSPCT, F_BOSSTYPE, F_ZOMBIE, F_SPECIAL, F_ENDED,
	F_VC, F_AP, F_LANG, F_SET, F_LEVEL, F_UNREAD, F_PREF, F_TABLET, F_THEME };

new g_pOn, g_pHideAmmo, g_pTopY, g_pBotY, g_pRightX;
new g_iMax, bool:g_bCore, g_iFrame, bool:g_bAscii, g_pAscii;
new Float:g_fNoteUntil[33], bool:g_bHidW[33];

// colours
new const C_HUM[3] = { 90, 200, 255 };
new const C_ZOM[3] = { 255, 72, 72 };
new const C_GOLD[3] = { 255, 210, 90 };
new const C_TXT[3] = { 236, 240, 246 };

public plugin_precache()
{
	if (file_exists(NOTE_FILE, true)) precache_sound(NOTE_SND);
}

public plugin_natives()
{
	set_native_filter("native_filter");
}

public native_filter(const name[], index, trap)
{
	if (!trap) return PLUGIN_HANDLED; // core missing -> plugin stays idle instead of failing
	return PLUGIN_CONTINUE;
}

public plugin_init()
{
	register_plugin("VEXMIRA HUD v4", PL_VER, "smurfsexy");
	register_dictionary("vexmira_zombie.txt");
	g_pOn = register_cvar("vx_hud4", "1");
	g_pHideAmmo = register_cvar("vx_hud4_hideammo", "0");   // 1 = also hide the default CS ammo numbers
	g_pTopY = register_cvar("vx_hud4_top_y", "0.012");
	g_pBotY = register_cvar("vx_hud4_bottom_y", "0.885");
	g_pRightX = register_cvar("vx_hud4_right_x", "0.775");
	g_pAscii = register_cvar("vx_hud4_ascii", "0");
	g_iMax = get_maxplayers();
	register_srvcmd("vx_hud4_testnote", "cmd_TestNote");
	set_task(0.2, "task_Fast", TASK_FAST, _, _, "b");
	set_task(0.5, "task_Slow", TASK_SLOW, _, _, "b");
}

public plugin_cfg()
{
	g_bCore = LibraryOk();
	if (g_bCore && get_pcvar_num(g_pOn)) vxc_hud(0, 99); // core: stop drawing the old bars/top board
}

bool:LibraryOk()
{
	return LibraryExists("vexmira_core45", LibType_Library) ? true : false;
}

// ------------------------------------------------------------------ helpers
bool:En(id) { return g_bCore && vxc_hud(id, F_LANG) == 1; }

Bar(out[], len, pct, cells)
{
	// em dashes (U+2014, in every Windows font) join into one continuous line: a thin CS2-like bar.
	// vx_hud4_ascii 1 -> "|||||....." for clients whose font lacks the dash.
	new n = clamp((pct * cells + 50) / 100, 0, cells), o;
	if (pct > 0 && n == 0) n = 1;
	if (g_bAscii)
	{
		for (new i = 0; i < cells && o < len - 1; i++) out[o++] = (i < n) ? '|' : '.';
	}
	else for (new i = 0; i < n && o < len - 4; i++) { out[o++] = 0xE2; out[o++] = 0x80; out[o++] = 0x94; }
	out[o] = 0;
}

Pips(out[], len, count, maxShown)
{
	// one bullet per alive player (U+2022, cp1252) or "o" in ASCII mode
	new o, n = min(count, maxShown);
	for (new i = 0; i < n && o < len - 5; i++)
	{
		if (g_bAscii) { out[o++] = 'o'; out[o++] = ' '; }
		else { out[o++] = 0xE2; out[o++] = 0x80; out[o++] = 0xA2; out[o++] = ' '; }
	}
	if (count > maxShown && o < len - 6) o += formatex(out[o], len - o, "+%d", count - maxShown);
	out[o] = 0;
}

Thousands(v, out[], len)
{
	new tmp[16]; num_to_str(v, tmp, charsmax(tmp));
	new l = strlen(tmp), o;
	for (new i = 0; i < l && o < len - 1; i++)
	{
		out[o++] = tmp[i];
		new rest = l - i - 1;
		if (rest > 0 && rest % 3 == 0 && tmp[0] != '-' && o < len - 1) out[o++] = '.';
	}
	out[o] = 0;
}

WeaponLabel(id, out[], len, &clip, &bp, &maxclip)
{
	out[0] = 0; clip = -1; bp = -1; maxclip = 0;
	new w = get_member(id, m_pActiveItem);
	if (w <= 0 || is_nullent(w)) return 0;
	new cls[32]; get_entvar(w, var_classname, cls, charsmax(cls));
	if (equal(cls, "weapon_", 7)) copy(out, len, cls[7]); else copy(out, len, cls);
	strtoupper(out);
	new WeaponIdType:wid = get_member(w, m_iId);
	if (wid == WEAPON_KNIFE || wid == WEAPON_C4) return w;
	clip = get_member(w, m_Weapon_iClip);
	bp = rg_get_user_bpammo(id, wid);
	maxclip = rg_get_weapon_info(wid, WI_GUN_CLIP_SIZE);
	return w;
}

// ------------------------------------------------------------------ bottom HUD (5x per second)
public task_Fast()
{
	if (!get_pcvar_num(g_pOn) || !g_bCore) return;
	g_iFrame++;
	g_bAscii = get_pcvar_num(g_pAscii) != 0;
	new hideAmmo = get_pcvar_num(g_pHideAmmo);
	static l[192], r[256], bar[96], bar2[96], wn[24], money[16], vc[16], ap[16];
	new Float:by = get_pcvar_float(g_pBotY), Float:rx = get_pcvar_float(g_pRightX);
	for (new id = 1; id <= g_iMax; id++)
	{
		if (!is_user_alive(id) || is_user_bot(id)) continue;
		if (vxc_hud(id, F_SET) & 1) continue;   // player turned the HUD off in /ayarlar
		// default ammo numbers: hidden while the iPad (C4 slot) is in hand, or always with vx_hud4_hideammo 1
		new bool:wantHide = hideAmmo || vxc_hud(id, F_TABLET) != 0, cur = get_member(id, m_iHideHUD);
		if (wantHide && !(cur & 1)) { set_member(id, m_iHideHUD, cur | 1); g_bHidW[id] = true; }
		else if (!wantHide && g_bHidW[id]) { set_member(id, m_iHideHUD, cur & ~1); g_bHidW[id] = false; }
		new bool:zombie = vxc_hud(id, F_ZOMBIE) != 0, bool:special = vxc_hud(id, F_SPECIAL) != 0;
		new hp = floatround(Float:get_entvar(id, var_health)), mx = max(1, floatround(Float:get_entvar(id, var_max_health)));
		new pct = clamp(hp * 100 / mx, 0, 100), ar = rg_get_user_armor(id);
		Bar(bar, charsmax(bar), pct, 14);
		new cr, cg, cb;
		if (special) { cr = 214; cg = 120; cb = 255; }
		else if (zombie) { cr = 150; cg = 255; cb = 90; }
		else if (pct > 50) { cr = C_TXT[0]; cg = C_TXT[1]; cb = C_TXT[2]; }
		else if (pct > 25) { cr = 255; cg = 190; cb = 60; }
		else { cr = 255; cg = (g_iFrame & 1) ? 50 : 90; cb = 50; }
		// U+2665 heart = E2 99 A5, U+2666 diamond = E2 99 A6
		if (!zombie && ar > 0)
		{
			Bar(bar2, charsmax(bar2), clamp(ar, 0, 100), 14);
			formatex(l, charsmax(l), "+ %d   %s^n%s %d   %s", hp, bar, g_bAscii ? "#" : "•", ar, bar2);
		}
		else formatex(l, charsmax(l), "+ %d   %s", hp, bar);
		set_dhudmessage(cr, cg, cb, 0.018, by, 0, 0.0, 0.24, 0.0, 0.0);
		show_dhudmessage(id, "%s", l);

		// right block: weapon + ammo, money / VC / AP
		new clip, bp, maxclip, n = 0;
		r[0] = 0;
		if (!zombie && WeaponLabel(id, wn, charsmax(wn), clip, bp, maxclip) && clip >= 0)
		{
			Bar(bar, charsmax(bar), maxclip > 0 ? clamp(clip * 100 / maxclip, 0, 100) : 100, 12);
			n += formatex(r[n], charsmax(r) - n, "%s^n%3d / %d   %s^n", wn, clip, bp, bar);
		}
		else if (zombie)
			n += formatex(r[n], charsmax(r) - n, "%s^n", special ? (En(id) ? "SPECIAL" : "ÖZEL") : (En(id) ? "ZOMBIE" : "ZOMBİ"));
		Thousands(get_member(id, m_iAccount), money, charsmax(money));
		Thousands(vxc_hud(id, F_VC), vc, charsmax(vc));
		Thousands(vxc_hud(id, F_AP), ap, charsmax(ap));
		n += formatex(r[n], charsmax(r) - n, "$ %s    %s VC    %s AP", money, vc, ap);
		new un = vxc_hud(id, F_UNREAD);
		if (un > 0) formatex(r[n], charsmax(r) - n, "    iPad %s %d", g_bAscii ? "*" : "•", un);
		new bool:low = clip >= 0 && maxclip > 0 && clip * 4 <= maxclip;
		set_dhudmessage(low ? 255 : C_GOLD[0], low ? 170 : C_GOLD[1], low ? 60 : C_GOLD[2], rx, by - 0.035, 0, 0.0, 0.24, 0.0, 0.0);
		show_dhudmessage(id, "%s", r);
	}
}

// ------------------------------------------------------------------ top scoreboard (2x per second)
public task_Slow()
{
	if (!get_pcvar_num(g_pOn) || !g_bCore) return;
	new humans, zombies;
	for (new p = 1; p <= g_iMax; p++)
	{
		if (!is_user_alive(p)) continue;
		if (vxc_hud(p, F_ZOMBIE)) zombies++; else humans++;
	}
	new hw = get_member_game(m_iNumCTWins), zw = get_member_game(m_iNumTerroristWins);
	new Float:start = Float:get_member_game(m_fRoundStartTime);
	new left = max(0, floatround(float(get_member_game(m_iRoundTimeSecs)) - (get_gametime() - start), floatround_ceil));
	new round = vxc_hud(0, F_ROUND), total = vxc_hud(0, F_TOTAL), mode = vxc_hud(0, F_MODE), bosspct = vxc_hud(0, F_BOSSPCT);
	new Float:ty = get_pcvar_float(g_pTopY);
	static a[160], b[160], c[200], pips[96], key[24], mn[48], ev[48], bar[96];
	for (new id = 1; id <= g_iMax; id++)
	{
		if (!is_user_connected(id) || is_user_bot(id)) continue;
		new bool:en = En(id);
		// left: humans
		Pips(pips, charsmax(pips), humans, 10);
		formatex(a, charsmax(a), "%s   %d^n%s", en ? "HUMANS" : "İNSANLAR", hw, pips);
		set_dhudmessage(C_HUM[0], C_HUM[1], C_HUM[2], 0.335, ty, 0, 0.0, 0.55, 0.0, 0.0);
		show_dhudmessage(id, "%s", a);
		// centre: timer, round, mode/event
		formatex(key, charsmax(key), "MODE_NAME_%d", mode); formatex(mn, charsmax(mn), "%L", id, key);
		if (bosspct >= 0) { formatex(key, charsmax(key), "BOSS_NAME_%d", vxc_hud(0, F_BOSSTYPE)); formatex(ev, charsmax(ev), "%L", id, key); }
		else { formatex(key, charsmax(key), "EV_NAME_%d", vxc_hud(0, F_EVENT)); formatex(ev, charsmax(ev), "%L", id, key); }
		formatex(c, charsmax(c), "%d:%02d^n%s %d/%d^n%s", left / 60, left % 60, en ? "ROUND" : "RAUNT", round, total, mn);
		set_dhudmessage(255, 255, 255, -1.0, ty, 0, 0.0, 0.55, 0.0, 0.0);
		show_dhudmessage(id, "%s", c);
		// right: zombies (or boss HP)
		if (bosspct >= 0)
		{
			Bar(bar, charsmax(bar), bosspct, 10);
			formatex(b, charsmax(b), "BOSS  %d%%^n%s", bosspct, bar);
			set_dhudmessage(214, 120, 255, 0.585, ty, 0, 0.0, 0.55, 0.0, 0.0);
		}
		else
		{
			Pips(pips, charsmax(pips), zombies, 10);
			formatex(b, charsmax(b), "%d   %s^n%s", zw, en ? "ZOMBIES" : "ZOMBİLER", pips);
			set_dhudmessage(C_ZOM[0], C_ZOM[1], C_ZOM[2], 0.585, ty, 0, 0.0, 0.55, 0.0, 0.0);
		}
		show_dhudmessage(id, "%s", b);
		// iPad banner still on screen? refresh nothing, it has its own hold time
	}
}

// ------------------------------------------------------------------ iPad notification banner
public vxc_notify(id, const text[])
{
	if (!(1 <= id <= g_iMax) || !is_user_connected(id) || is_user_bot(id) || !g_bCore) return;
	new pref = vxc_hud(id, F_PREF);           // bit0 sounds, bit1 notifications (tablet settings)
	if (pref & 2)
	{
		new Float:now = get_gametime();
		if (now >= g_fNoteUntil[id] - 3.5)     // at most one new banner per 1.5 s
		{
			g_fNoteUntil[id] = now + 5.0;
			set_dhudmessage(245, 245, 250, 0.735, 0.085, 0, 0.0, 4.6, 0.12, 0.35);
			show_dhudmessage(id, "%s iPad  %s^n%s", g_bAscii ? "*" : "•", En(id) ? "now" : "şimdi", text);
		}
	}
	if (pref & 1)
	{
		if (file_exists(NOTE_FILE, true)) client_cmd(id, "spk vexmira/ui/ipad_note");
		else client_cmd(id, "spk buttons/bell1");
	}
}

public cmd_TestNote()
{
	new t[96]; read_args(t, charsmax(t)); remove_quotes(t);
	for (new p = 1; p <= g_iMax; p++) if (is_user_connected(p) && !is_user_bot(p)) vxc_notify(p, t[0] ? t : "Test: iPad bildirimi");
	return PLUGIN_HANDLED;
}

public client_disconnected(id) { g_fNoteUntil[id] = 0.0; g_bHidW[id] = false; }
