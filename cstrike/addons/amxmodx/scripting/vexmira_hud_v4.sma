/* VEXMIRA HUD v4 - the whole player HUD, drawn by the server (the game's own HUD is switched off).
 *
 *  top          : HUMANS  score + alive dots  |  ROUND x/y + mode/event (boss: name + HP line)  |  ZOMBIES
 *  bottom-left  : + health line, armor line (humans), round time line (gold, red in the last 30 s)
 *  bottom-right : weapon + clip/reserve with clip line, then $ money  VC  AP  (+ unread iPad count)
 *  near cross   : damage combo (sum of hits in a short window, x hits, HEADSHOT, KILL) - replaces the
 *                 core's old plain damage numbers
 *  top right    : iPad banner for messages / requests / sales (follows the tablet's Sound / Notification
 *                 switches)
 *
 * Lines are em dashes (U+2014): they join into one thin continuous bar in every Windows font.
 * vx_hud4_ascii 1 switches to plain ASCII ("|||...") for clients whose font misses a glyph.
 * Every element is ONE director message with a hold time just above its refresh time, so nothing
 * ghosts and the client's message pool is never full (about 9 slots at most).
 * Needs vxcore_v4 (native vxc_hud); the core then stops drawing its own bars / top board / numbers.
 * Tablet & Mod: smurfsexy
 */
#include <amxmodx>
#include <reapi>

#pragma semicolon 1

native vxc_hud(id, field);

#define PL_VER "4.1"
#define TASK_FAST 7400500
#define TASK_SLOW 7400501
#define NOTE_SND "vexmira/ui/ipad_note.wav"
#define NOTE_FILE "sound/vexmira/ui/ipad_note.wav"
#define HIDE_ALL_DEFAULT 59      // weapons/ammo 1 + flashlight 2 + health/armor 8 + timer 16 + money 32
#define SET_NO_HUD (1<<0)
#define SET_NO_DMGNUM (1<<1)

enum { F_MODE = 0, F_EVENT, F_ROUND, F_TOTAL, F_BOSS, F_BOSSPCT, F_BOSSTYPE, F_ZOMBIE, F_SPECIAL, F_ENDED,
	F_VC, F_AP, F_LANG, F_SET, F_LEVEL, F_UNREAD, F_PREF, F_TABLET, F_THEME, F_GAUGE };

new g_pOn, g_pHide, g_pAscii, g_pDmg, g_pFast;
new g_iMax, bool:g_bCore, g_iFrame, bool:g_bAscii;
new Float:g_fNoteUntil[33], bool:g_bFastSet[33], g_szNote[33][100];
// damage combo
new g_iCombo[33], g_iHits[33], bool:g_bHs[33], bool:g_bKill[33], bool:g_bBossHit[33], bool:g_bDirty[33];
new Float:g_fComboEnd[33], Float:g_fComboShow[33], g_iComboVictim[33];

new const C_HUM[3] = { 92, 200, 255 };
new const C_ZOM[3] = { 255, 74, 74 };
new const C_GOLD[3] = { 255, 206, 92 };
new const C_TXT[3] = { 238, 241, 246 };

public plugin_precache()
{
	if (file_exists(NOTE_FILE, true)) precache_sound(NOTE_SND);
}

public plugin_natives() set_native_filter("native_filter");

public native_filter(const name[], index, trap)
{
	if (!trap) return PLUGIN_HANDLED; // core missing -> HUD stays idle instead of failing to load
	return PLUGIN_CONTINUE;
}

public plugin_init()
{
	register_plugin("VEXMIRA HUD v4", PL_VER, "smurfsexy");
	register_dictionary("vexmira_zombie.txt");
	g_pOn = register_cvar("vx_hud4", "1");                 // 0 = core draws its old HUD again
	g_pHide = register_cvar("vx_hud4_hide", "59");         // default HUD parts hidden (59 = all, radar is hidden by the core)
	g_pAscii = register_cvar("vx_hud4_ascii", "0");
	g_pDmg = register_cvar("vx_hud4_damage", "1");         // damage combo numbers
	g_pFast = register_cvar("vx_hud4_fastswitch", "1");    // weapon list is hidden with the ammo HUD -> fast switch
	register_srvcmd("vx_hud4_testnote", "cmd_TestNote");
	register_srvcmd("vx_hud4_testdmg", "cmd_TestDmg");
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fw_TakeDamagePost", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "fw_KilledPost", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "fw_SpawnPost", true);
	g_iMax = get_maxplayers();
	set_task(0.25, "task_Fast", TASK_FAST, _, _, "b");
	set_task(1.0, "task_Slow", TASK_SLOW, _, _, "b");
}

public plugin_cfg()
{
	g_bCore = CoreRunning();
	if (!g_bCore) log_amx("[HUD v4] vxcore_v4 calismiyor -> HUD bekliyor (core duzelince harita degisiminde acilir)");
	if (g_bCore && get_pcvar_num(g_pOn)) vxc_hud(0, 99); // core: stop drawing the old bars / top board / numbers
}

// core must be loaded AND running (a paused core makes every native call an error)
bool:CoreRunning()
{
	// by plugin title (panel renames the .amxx files), and only when it is really running
	new ix = is_plugin_loaded("Vexmira Zombie Core");
	if (ix < 0) return false;
	new file[64], name[64], ver[16], author[32], status[16];
	get_plugin(ix, file, charsmax(file), name, charsmax(name), ver, charsmax(ver), author, charsmax(author), status, charsmax(status));
	return (equali(status, "running") || equali(status, "debug")) ? true : false;
}

// ------------------------------------------------------------------ helpers
bool:En(id) return g_bCore && vxc_hud(id, F_LANG) == 1;

Line(out[], len, pct, cells)
{
	new n = clamp((pct * cells + 50) / 100, 0, cells), o;
	if (pct > 0 && n == 0) n = 1;
	for (new i = 0; i < cells && o < len - 3; i++)
	{
		if (i < n) out[o++] = '|';
		else if (g_bAscii) out[o++] = '.';
		else { out[o++] = 0xC2; out[o++] = 0xA6; }   // U+00A6 broken bar
	}
	out[o] = 0;
}

Dots(out[], len, count, maxShown)
{
	new o, n = min(count, maxShown);
	for (new i = 0; i < n && o < len - 5; i++)
	{
		if (g_bAscii) out[o++] = 'o';
		else { out[o++] = 0xE2; out[o++] = 0x80; out[o++] = 0xA2; }
		out[o++] = ' ';
	}
	if (count > maxShown && o < len - 6) o += formatex(out[o], len - o, "+%d", count - maxShown);
	if (!count && o < len - 2) out[o++] = '-';
	out[o] = 0;
}

Dot(out[], len) { if (g_bAscii) copy(out, len, "*"); else copy(out, len, "•"); }

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

WeaponInfo(id, out[], len, &clip, &bp, &maxclip)
{
	out[0] = 0; clip = -1; bp = -1; maxclip = 0;
	new w = get_member(id, m_pActiveItem);
	if (w <= 0 || is_nullent(w)) return 0;
	new cls[32]; get_entvar(w, var_classname, cls, charsmax(cls));
	if (equal(cls, "weapon_", 7)) copy(out, len, cls[7]); else copy(out, len, cls);
	strtoupper(out);
	new WeaponIdType:wid = get_member(w, m_iId);
	if (wid == WEAPON_C4) { copy(out, len, "iPad"); return w; }
	if (wid == WEAPON_KNIFE || wid == WEAPON_NONE) return w;
	clip = get_member(w, m_Weapon_iClip);
	bp = rg_get_user_bpammo(id, wid);
	maxclip = rg_get_weapon_info(wid, WI_GUN_CLIP_SIZE);
	return w;
}

RoundLeft(&total)
{
	total = max(1, get_member_game(m_iRoundTimeSecs));
	new Float:start = Float:get_member_game(m_fRoundStartTime);
	return clamp(floatround(float(total) - (get_gametime() - start), floatround_ceil), 0, total);
}

// ------------------------------------------------------------------ default HUD off + fast switch
public fw_SpawnPost(id)
{
	if (!is_user_alive(id) || is_user_bot(id) || !g_bCore || !get_pcvar_num(g_pOn)) return;
	ApplyHide(id);
	new hide = get_pcvar_num(g_pHide);
	if ((hide & 1) && get_pcvar_num(g_pFast) && !g_bFastSet[id])
	{
		// the weapon list belongs to the ammo HUD that is hidden: switch weapons instantly with 1-5 / wheel
		g_bFastSet[id] = true;
		client_cmd(id, "hud_fastswitch 1");
		client_print_color(id, print_team_default, En(id) ? "^4[VEXMIRA]^1 New HUD: weapons switch instantly with keys ^41-5^1 (hud_fastswitch 1)." : "^4[VEXMIRA]^1 Yeni HUD: silahlar ^41-5^1 tuslariyla aninda degisir (hud_fastswitch 1).");
	}
}

ApplyHide(id)
{
	new hide = get_pcvar_num(g_pHide);
	if (hide <= 0) return;
	new cur = get_member(id, m_iHideHUD);
	if ((cur & hide) != hide) set_member(id, m_iHideHUD, cur | hide);
}

// ------------------------------------------------------------------ bottom HUD (4 per second)
// The client keeps only 8 director messages at once, so the HUD uses 5 (3 here + 2 on top) and every
// message is held just a little longer than its refresh time: no ghosting, room left for the damage
// combo, the iPad banner and the core's round announcements.
public task_Fast()
{
	if (!get_pcvar_num(g_pOn) || !g_bCore) return;
	g_iFrame++;
	g_bAscii = get_pcvar_num(g_pAscii) != 0;
	static a[200], c[200], g1[64], g2[64], wn[24], money[16], vc[16], ap[16], dot[8];
	new Float:now = get_gametime();
	Dot(dot, charsmax(dot));
	for (new id = 1; id <= g_iMax; id++)
	{
		if (!is_user_connected(id) || is_user_bot(id)) continue;
		if (g_bDirty[id] || (g_iCombo[id] && now >= g_fComboEnd[id])) ComboFlush(id, now);
		new bool:alive = is_user_alive(id) ? true : false;
		if (alive && (vxc_hud(id, F_SET) & SET_NO_HUD)) continue;

		if (!alive) continue;
		ApplyHide(id);
		new bool:zombie = vxc_hud(id, F_ZOMBIE) != 0, bool:special = vxc_hud(id, F_SPECIAL) != 0, bool:en = En(id);

		// --- bottom left: health (+ armor) with ticked gauges
		new hp = floatround(Float:get_entvar(id, var_health)), mx = max(1, floatround(Float:get_entvar(id, var_max_health)));
		new pct = clamp(hp * 100 / mx, 0, 100), ar = rg_get_user_armor(id);
		Line(g1, charsmax(g1), pct, 20);
		new r, g, bl;
		if (special) { r = 214; g = 122; bl = 255; }
		else if (zombie) { r = 150; g = 255; bl = 92; }
		else if (pct > 50) { r = C_TXT[0]; g = C_TXT[1]; bl = C_TXT[2]; }
		else if (pct > 25) { r = 255; g = 186; bl = 60; }
		else { r = 255; g = (g_iFrame & 1) ? 46 : 96; bl = 46; }
		if (!zombie && ar > 0)
		{
			Line(g2, charsmax(g2), clamp(ar, 0, 100), 20);
			formatex(a, charsmax(a), "%s %5d   %s^n%s %5d   %s", en ? "HP" : "CAN", hp, g1, en ? "AR" : "ZRH", ar, g2);
		}
		else formatex(a, charsmax(a), "%s %5d   %s", en ? "HP" : "CAN", hp, g1);
		set_hudmessage(r, g, bl, 0.022, 0.905, 0, 0.0, 0.45, 0.0, 0.0, 4);
		show_hudmessage(id, "%s", a);

		// --- bottom right: weapon + ammo, money / VexCoin / AP (one block)
		new clip, bp, maxclip, n = 0;
		c[0] = 0;
		new w = WeaponInfo(id, wn, charsmax(wn), clip, bp, maxclip);
		if (!zombie && w && clip >= 0) n += formatex(c[n], charsmax(c) - n, "%s     %d / %d^n", wn, clip, bp);
		else if (!zombie && w && wn[0]) n += formatex(c[n], charsmax(c) - n, "%s^n", wn);
		else if (zombie) n += formatex(c[n], charsmax(c) - n, "%s^n", special ? (en ? "SPECIAL ZOMBIE" : "ÖZEL ZOMBİ") : (en ? "ZOMBIE" : "ZOMBİ"));
		Thousands(get_member(id, m_iAccount), money, charsmax(money));
		Thousands(vxc_hud(id, F_VC), vc, charsmax(vc));
		Thousands(vxc_hud(id, F_AP), ap, charsmax(ap));
		n += formatex(c[n], charsmax(c) - n, "$ %s    VC %s    AP %s", money, vc, ap);
		new un = vxc_hud(id, F_UNREAD);
		if (un > 0) formatex(c[n], charsmax(c) - n, "^niPad %s %d", dot, un);
		new bool:low = clip >= 0 && maxclip > 0 && clip * 4 <= maxclip;
		if (vxc_hud(id, F_GAUGE)) continue;     // jetpack fuel gauge uses channel 2 while flying
		set_hudmessage(low ? 255 : C_GOLD[0], low ? 140 : C_GOLD[1], low ? 70 : C_GOLD[2], 0.78, 0.905, 0, 0.0, 0.45, 0.0, 0.0, 2);
		show_hudmessage(id, "%s", c);
	}
}

// ------------------------------------------------------------------ top: team counters (2 per second)
public task_Slow()
{
	if (!get_pcvar_num(g_pOn)) return;
	if (!g_bCore) { static tries; if (++tries % 5 == 0 && CoreRunning()) { g_bCore = true; vxc_hud(0, 99); } return; }
	new humans, zombies;
	for (new p = 1; p <= g_iMax; p++)
	{
		if (!is_user_alive(p)) continue;
		if (vxc_hud(p, F_ZOMBIE)) zombies++; else humans++;
	}
	new hw = get_member_game(m_iNumCTWins), zw = get_member_game(m_iNumTerroristWins);
	new bosspct = vxc_hud(0, F_BOSSPCT), total, left = RoundLeft(total), bool:hurry = left <= 30 && !vxc_hud(0, F_ENDED);
	new Float:now = get_gametime();
	static a[160], b[200], dots[96], line[64], dot[8];
	Dot(dot, charsmax(dot));
	for (new id = 1; id <= g_iMax; id++)
	{
		if (!is_user_connected(id) || is_user_bot(id)) continue;
		if (is_user_alive(id) && (vxc_hud(id, F_SET) & SET_NO_HUD)) continue;
		new bool:en = En(id);
		// bottom centre: round time, digits only (red in the last 30 s)
		set_dhudmessage(hurry ? 255 : 245, hurry ? 70 : 245, hurry ? 60 : 250, -1.0, 0.94, 0, 0.0, 1.06, 0.0, 0.0);
		show_dhudmessage(id, "%d:%02d", left / 60, left % 60);
		// iPad banner stays alive by being re-sent every second
		if (now < g_fNoteUntil[id] && g_szNote[id][0])
		{
			set_dhudmessage(245, 245, 250, 0.72, 0.10, 0, 0.0, 1.06, 0.0, 0.0);
			show_dhudmessage(id, "%s iPad   %s^n%s", dot, en ? "now" : "şimdi", g_szNote[id]);
		}
		// left: humans  "İNSAN  3  [12]" + one dot per living human
		Dots(dots, charsmax(dots), humans, 12);
		formatex(a, charsmax(a), "%s   %d^n%s", en ? "HUMANS" : "İNSANLAR", hw, dots);
		set_dhudmessage(C_HUM[0], C_HUM[1], C_HUM[2], 0.335, 0.014, 0, 0.0, 1.06, 0.0, 0.0);
		show_dhudmessage(id, "%s", a);
		// right: zombies, or the boss with its HP gauge
		if (bosspct >= 0)
		{
			Line(line, charsmax(line), bosspct, 20);
			formatex(b, charsmax(b), "BOSS  %d%%^n%s", bosspct, line);
			set_dhudmessage(214, 122, 255, 0.565, 0.014, 0, 0.0, 1.06, 0.0, 0.0);
		}
		else
		{
			Dots(dots, charsmax(dots), zombies, 12);
			formatex(b, charsmax(b), "%d   %s^n%s", zw, en ? "ZOMBIES" : "ZOMBİLER", dots);
			set_dhudmessage(C_ZOM[0], C_ZOM[1], C_ZOM[2], 0.565, 0.014, 0, 0.0, 1.06, 0.0, 0.0);
		}
		show_dhudmessage(id, "%s", b);
	}
}

// ------------------------------------------------------------------ damage combo
public fw_TakeDamagePost(victim, inflictor, attacker, Float:damage, bits)
{
	if (!g_bCore || !get_pcvar_num(g_pOn) || !get_pcvar_num(g_pDmg) || damage <= 0.0) return;
	if (!(1 <= attacker <= g_iMax) || attacker == victim || !(1 <= victim <= g_iMax) || is_user_bot(attacker) || !is_user_connected(attacker)) return;
	if (vxc_hud(attacker, F_ZOMBIE) == vxc_hud(victim, F_ZOMBIE)) return;
	if (vxc_hud(attacker, F_SET) & SET_NO_DMGNUM) return;
	new Float:now = get_gametime();
	if (g_iComboVictim[attacker] != victim || now >= g_fComboEnd[attacker]) { g_iCombo[attacker] = 0; g_iHits[attacker] = 0; g_bHs[attacker] = false; g_bKill[attacker] = false; }
	g_iComboVictim[attacker] = victim;
	g_iCombo[attacker] += floatround(damage);
	g_iHits[attacker]++;
	if ((bits & DMG_BULLET) && get_member(victim, m_LastHitGroup) == HIT_HEAD) g_bHs[attacker] = true;
	g_bBossHit[attacker] = vxc_hud(0, F_BOSS) == victim;
	g_fComboEnd[attacker] = now + 1.1;
	g_bDirty[attacker] = true;
	if (now >= g_fComboShow[attacker]) ComboFlush(attacker, now);
}

public fw_KilledPost(victim, killer)
{
	if (1 <= killer <= g_iMax && killer != victim && g_iComboVictim[killer] == victim && g_iCombo[killer] > 0)
	{
		g_bKill[killer] = true; g_bDirty[killer] = true;
		ComboFlush(killer, get_gametime());
	}
}

ComboFlush(id, Float:now)
{
	if (!g_iCombo[id]) { g_bDirty[id] = false; return; }
	if (!g_bDirty[id])
	{
		if (now >= g_fComboEnd[id]) { g_iCombo[id] = 0; g_iHits[id] = 0; }
		return;
	}
	if (now < g_fComboShow[id]) return;      // max ~4 updates per second
	g_bDirty[id] = false;
	g_fComboShow[id] = now + 0.33;
	new txt[96], n, bool:en = En(id);
	n = formatex(txt, charsmax(txt), "-%d", g_iCombo[id]);
	if (g_iHits[id] > 1) n += formatex(txt[n], charsmax(txt) - n, "   x%d", g_iHits[id]);
	if (g_bKill[id]) formatex(txt[n], charsmax(txt) - n, "^n%s", en ? "KILL" : "ÖLDÜRÜLDÜ");
	else if (g_bHs[id]) formatex(txt[n], charsmax(txt) - n, "^n%s", en ? "HEADSHOT" : "KAFADAN");
	new r, g, b;
	if (g_bKill[id]) { r = 255; g = 64; b = 64; }
	else if (g_bBossHit[id]) { r = 214; g = 122; b = 255; }
	else if (g_bHs[id]) { r = 255; g = 206; b = 70; }
	else if (vxc_hud(id, F_ZOMBIE)) { r = 150; g = 255; b = 92; }
	else { r = 160; g = 225; b = 255; }
	set_dhudmessage(r, g, b, 0.54, 0.54, 0, 0.0, g_bKill[id] ? 0.8 : 0.4, 0.0, 0.0);
	show_dhudmessage(id, "%s", txt);
	if (g_bKill[id]) { g_iCombo[id] = 0; g_iHits[id] = 0; g_bKill[id] = false; }
}

// ------------------------------------------------------------------ iPad notification banner
public vxc_notify(id, const text[])
{
	if (!(1 <= id <= g_iMax) || !is_user_connected(id) || is_user_bot(id) || !g_bCore) return;
	new pref = vxc_hud(id, F_PREF);           // bit0 sounds, bit1 notifications (tablet settings)
	if (pref & 2)
	{
		new Float:now = get_gametime();
		g_fNoteUntil[id] = now + 5.0;
		copy(g_szNote[id], charsmax(g_szNote[]), text);
		new dot[8]; Dot(dot, charsmax(dot));
		set_dhudmessage(245, 245, 250, 0.72, 0.10, 0, 0.0, 1.06, 0.0, 0.0);
		show_dhudmessage(id, "%s iPad   %s^n%s", dot, En(id) ? "now" : "şimdi", text);
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
	for (new p = 1; p <= g_iMax; p++) if (is_user_connected(p) && !is_user_bot(p)) { vxc_notify(p, t[0] ? t : "Test: iPad bildirimi"); }
	return PLUGIN_HANDLED;
}

public cmd_TestDmg()
{
	new a[16]; read_argv(1, a, charsmax(a)); new kind = str_to_num(a);
	for (new p = 1; p <= g_iMax; p++) if (is_user_connected(p) && !is_user_bot(p))
	{
		g_iCombo[p] = 245 + random(300); g_iHits[p] = 3 + random(5); g_bHs[p] = kind == 1; g_bKill[p] = kind == 2; g_bBossHit[p] = kind == 3;
		g_fComboEnd[p] = get_gametime() + 1.1; g_fComboShow[p] = 0.0; g_bDirty[p] = true; ComboFlush(p, get_gametime());
	}
	return PLUGIN_HANDLED;
}

public client_disconnected(id)
{
	g_fNoteUntil[id] = 0.0; g_bFastSet[id] = false; g_szNote[id][0] = 0;
	g_iCombo[id] = 0; g_iHits[id] = 0; g_bDirty[id] = false; g_iComboVictim[id] = 0;
}
