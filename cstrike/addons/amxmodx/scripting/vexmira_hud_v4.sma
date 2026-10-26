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
#pragma dynamic 32768
#include <amxmodx>
#include <reapi>

#pragma semicolon 1

native vxc_hud(id, field);
native vxc_ipad_card(id);

#define PL_VER "4.2"
#define TASK_FAST 7400500
#define TASK_SLOW 7400501
#define NOTE_SND "vexmira/ui/ipad_note.wav"
#define NOTE_FILE "sound/vexmira/ui/ipad_note.wav"
#define HIDE_ALL_DEFAULT 58      // flashlight 2 + health/armor 8 + timer 16 + money 32 (weapon list + ammo stay: weapon selection works)
#define SET_NO_HUD (1<<0)
#define SET_NO_DMGNUM (1<<1)

enum { F_MODE = 0, F_EVENT, F_ROUND, F_TOTAL, F_BOSS, F_BOSSPCT, F_BOSSTYPE, F_ZOMBIE, F_SPECIAL, F_ENDED,
	F_VC, F_AP, F_LANG, F_SET, F_LEVEL, F_UNREAD, F_PREF, F_TABLET, F_THEME, F_GAUGE, F_JOB };

new g_pOn, g_pHide, g_pAscii, g_pDmg, g_pFast, g_pGap;
new g_iMax, bool:g_bCore, g_iFrame, bool:g_bAscii;
new Float:g_fNoteUntil[33], bool:g_bFastSet[33], g_szNote[33][100];
// damage combo
new bool:g_bHs[33], bool:g_bBossHit[33], g_iComboVictim[33];
#define NUM_GAP 0.06
new const NUM_PAL[][3] = { {255,222,70}, {255,150,40}, {90,210,255}, {255,110,190}, {150,255,90}, {245,245,245}, {190,140,255} };
new g_iNumPend[33], Float:g_fNumAt[33], g_iNumCol[33], g_iNumSec[33], Float:g_fHpAt[33];

new const C_HUM[3] = { 92, 200, 255 };
new const C_ZOM[3] = { 255, 74, 74 };
new const C_GOLD[3] = { 255, 206, 92 };

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
	g_pHide = register_cvar("vx_hud4_hide", "58");         // default HUD parts hidden (58 = all but the weapon list/ammo; 59 also hides weapon selection)
	g_pAscii = register_cvar("vx_hud4_ascii", "1");   // 1 = plain ASCII only (the CS 1.6 font has no Turkish capitals like I-dot)
	g_pDmg = register_cvar("vx_hud4_damage", "1");         // damage combo numbers
	g_pFast = register_cvar("vx_hud4_fastswitch", "0");    // 1 = give hud_fastswitch 1 (only useful with vx_hud4_hide 59); 0 = restore the weapon menu once
	g_pGap = register_cvar("vx_hud4_topgap", "56");        // top board: space between HUMANS / ROUND / ZOMBIES (spaces)
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

stock Dots(out[], len, count, maxShown)
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

Dot(out[], len) { if (g_bAscii) copy(out, len, "|"); else copy(out, len, "•"); }

// characters on screen (UTF-8 continuation bytes do not count)
VisLen(const s[]) { new n; for (new i = 0; s[i]; i++) if ((s[i] & 0xC0) != 0x80) n++; return n; }
Spaces(out[], len, n) { new o; for (; o < n && o < len; o++) out[o] = ' '; out[o] = 0; }

// One-line block for the top board, drawn as a CENTRED message. Spaces push it next to the ROUND block on
// every resolution: left block = text + spaces, right block = spaces + text. A director message holds at
// most 128 bytes, so the block is a single line (two padded lines did not fit and were cut).
// A space is about half a letter wide, hence "letters + topgap" spaces. Gap: vx_hud4_topgap.
SideBlock(out[], len, const l1[], bool:left)
{
	new gap = min(VisLen(l1) + clamp(get_pcvar_num(g_pGap), 4, 90), 110 - strlen(l1));
	static g[128];
	Spaces(g, charsmax(g), gap);
	if (left) formatex(out, len, "%s%s", l1, g);
	else formatex(out, len, "%s%s", g, l1);
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
	if (!g_bFastSet[id])
	{
		g_bFastSet[id] = true;
		if ((hide & 1) && get_pcvar_num(g_pFast))
		{
			// the weapon list belongs to the ammo HUD that is hidden: switch weapons instantly with 1-5 / wheel
			client_cmd(id, "hud_fastswitch 1");
			client_print_color(id, print_team_default, En(id) ? "^4[VEXMIRA]^1 New HUD: weapons switch instantly with keys ^41-5^1 (hud_fastswitch 1)." : "^4[VEXMIRA]^1 Yeni HUD: silahlar ^41-5^1 tuslariyla aninda degisir (hud_fastswitch 1).");
		}
		else if (!(hide & 1)) client_cmd(id, "hud_fastswitch 0"); // HUD 4.1 had switched it on: weapon menu (1-5, wheel) opens again
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
		if (g_iNumPend[id] && now - g_fNumAt[id] >= NUM_GAP) NumFlush(id, now);
		new bool:alive = is_user_alive(id) ? true : false;
		if (alive && (vxc_hud(id, F_SET) & SET_NO_HUD)) continue;

		if (!alive) continue;
		ApplyHide(id);
		new bool:zombie = vxc_hud(id, F_ZOMBIE) != 0, bool:special = vxc_hud(id, F_SPECIAL) != 0, bool:en = En(id);

		// --- bottom left: health (+ armor) with ticked gauges
		new hp = floatround(Float:get_entvar(id, var_health)), mx = max(1, floatround(Float:get_entvar(id, var_max_health)));
		new pct = clamp(hp * 100 / mx, 0, 100), ar = rg_get_user_armor(id);
		Line(g1, charsmax(g1), pct, 20);
		// colour follows the health: blue above 250 (humans), then green -> yellow -> orange -> red (steady)
		new r, g, bl;
		if (special) { r = 214; g = 122; bl = 255; }
		else if (!zombie && hp > 250) { r = 80; g = 170; bl = 255; }
		else if (pct >= 75) { r = 70; g = 230; bl = 100; }
		else if (pct >= 50) { r = 200; g = 230; bl = 70; }
		else if (pct >= 25) { r = 255; g = 160; bl = 50; }
		else { r = 255; g = 60; bl = 50; }   // steady red (blinking looked like flicker)
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
		new bool:list = (get_pcvar_num(g_pHide) & 1) == 0;   // game weapon list / ammo visible -> no weapon line here
		new w = WeaponInfo(id, wn, charsmax(wn), clip, bp, maxclip);
		if (!list && !zombie && w && clip >= 0) n += formatex(c[n], charsmax(c) - n, "%s     %d / %d^n", wn, clip, bp);
		else if (!list && !zombie && w && wn[0]) n += formatex(c[n], charsmax(c) - n, "%s^n", wn);
		else if (zombie && special) n += formatex(c[n], charsmax(c) - n, "%s^n", en ? "SPECIAL ZOMBIE" : "OZEL ZOMBI");
		else if (zombie) { new ck[12]; formatex(ck, charsmax(ck), "CLASS_%d", vxc_hud(id, F_JOB)); n += formatex(c[n], charsmax(c) - n, "%L^n", id, ck); }   // zombi sinifinin adi
		Thousands(get_member(id, m_iAccount), money, charsmax(money));
		Thousands(vxc_hud(id, F_VC), vc, charsmax(vc));
		Thousands(vxc_hud(id, F_AP), ap, charsmax(ap));
		// level + job (the core's top-right player panel is off while this HUD runs)
		if (zombie) n += formatex(c[n], charsmax(c) - n, "Lv.%d^n", vxc_hud(id, F_LEVEL));
		else { new jk[12]; formatex(jk, charsmax(jk), "JOB_%d", vxc_hud(id, F_JOB)); n += formatex(c[n], charsmax(c) - n, "Lv.%d   %L^n", vxc_hud(id, F_LEVEL), id, jk); }
		n += formatex(c[n], charsmax(c) - n, "$ %s^nVexCoin %s^nAmmoPack %s", money, vc, ap);
		new un = vxc_hud(id, F_UNREAD);
		if (un > 0) formatex(c[n], charsmax(c) - n, "^niPad %s %d", dot, un);
		new bool:low = !list && clip >= 0 && maxclip > 0 && clip * 4 <= maxclip;
		if (vxc_hud(id, F_GAUGE)) continue;     // jetpack fuel gauge uses channel 2 while flying
		set_hudmessage(low ? 255 : C_GOLD[0], low ? 140 : C_GOLD[1], low ? 70 : C_GOLD[2], -0.012, list ? 0.755 : 0.83, 0, 0.0, 0.45, 0.0, 0.0, 2); // far right: a negative x right-aligns the block on every resolution
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
	static a[160], b[200], dot[8];
	Dot(dot, charsmax(dot));
	for (new id = 1; id <= g_iMax; id++)
	{
		if (!is_user_connected(id) || is_user_bot(id)) continue;
		if (is_user_alive(id) && (vxc_hud(id, F_SET) & SET_NO_HUD)) continue;
		new bool:en = En(id);
		// bottom centre: round time, digits only (red in the last 30 s)
		set_dhudmessage(hurry ? 255 : 245, hurry ? 70 : 245, hurry ? 60 : 250, -1.0, 0.94, 0, 0.0, 1.06, 0.0, 0.0);
		show_dhudmessage(id, "%d:%02d", left / 60, left % 60);
		// centre: ROUND x / y, mode, event (boss: boss name)
		{
			static mk[24], ek[24], mn[48], evn[48];
			formatex(mk, charsmax(mk), "MODE_NAME_%d", vxc_hud(0, F_MODE));
			if (bosspct >= 0) formatex(ek, charsmax(ek), "BOSS_NAME_%d", vxc_hud(0, F_BOSSTYPE));
			else formatex(ek, charsmax(ek), "EV_NAME_%d", vxc_hud(0, F_EVENT));
			formatex(mn, charsmax(mn), "%L", id, mk);
			formatex(evn, charsmax(evn), "%L", id, ek);
			if (containi(mn, "ML_NOTFOUND") != -1) mn[0] = 0;
			if (containi(evn, "ML_NOTFOUND") != -1) evn[0] = 0;
			set_dhudmessage(C_GOLD[0], C_GOLD[1], C_GOLD[2], -1.0, 0.014, 0, 0.0, 1.06, 0.0, 0.0);
			show_dhudmessage(id, "%s %d / %d^n%s^n%s", en ? "ROUND" : "RAUNT", vxc_hud(0, F_ROUND), vxc_hud(0, F_TOTAL), mn, evn);
		}
		// left / right blocks are centred messages padded with spaces (like the old board): they sit right
		// next to the ROUND block on every resolution instead of at a fixed screen x
		// sides: "HUMANS 3  • 6" (wins, alive) | "• 2  1 ZOMBIES" - one line each, right next to the ROUND block
		static l1[64], l2[64];
		formatex(l1, charsmax(l1), "%s %d   %s %d", en ? "HUMANS" : "INSANLAR", hw, dot, humans);
		SideBlock(a, charsmax(a), l1, true);
		set_dhudmessage(C_HUM[0], C_HUM[1], C_HUM[2], -1.0, 0.014, 0, 0.0, 1.06, 0.0, 0.0);
		show_dhudmessage(id, "%s", a);
		// right: zombies, or the boss with its HP percent
		if (bosspct >= 0)
		{
			formatex(l2, charsmax(l2), "%d%%  BOSS", bosspct);
			SideBlock(b, charsmax(b), l2, false);
			set_dhudmessage(214, 122, 255, -1.0, 0.014, 0, 0.0, 1.06, 0.0, 0.0);
		}
		else
		{
			formatex(l2, charsmax(l2), "%s %d   %d %s", dot, zombies, zw, en ? "ZOMBIES" : "ZOMBILER");
			SideBlock(b, charsmax(b), l2, false);
			set_dhudmessage(C_ZOM[0], C_ZOM[1], C_ZOM[2], -1.0, 0.014, 0, 0.0, 1.06, 0.0, 0.0);
		}
		show_dhudmessage(id, "%s", b);
	}
}

// ------------------------------------------------------------------ hit numbers + remaining HP
// v10.2: her vurus crosshair cevresinde rastgele bir noktada renkli bir sayi olarak cikar (art arda vuruslar
// etrafa dagilir); hedefin kalan HP si CS 1.6 nin orijinal sari orta yazisiyla (silah modu yazisi gibi) gosterilir.

public fw_TakeDamagePost(victim, inflictor, attacker, Float:damage, bits)
{
	return; // v10.6: the core shows remaining HP + damage numbers itself (works without this plugin)
	if (!g_bCore || !get_pcvar_num(g_pOn) || !get_pcvar_num(g_pDmg) || damage <= 0.0) return;
	if (!(1 <= attacker <= g_iMax) || attacker == victim || !(1 <= victim <= g_iMax) || is_user_bot(attacker) || !is_user_connected(attacker)) return;
	if (vxc_hud(attacker, F_ZOMBIE) == vxc_hud(victim, F_ZOMBIE)) return;
	if (vxc_hud(attacker, F_SET) & SET_NO_DMGNUM) return;
	new Float:now = get_gametime();
	if (g_iComboVictim[attacker] != victim) { g_iNumPend[attacker] = 0; g_bHs[attacker] = false; }
	g_iComboVictim[attacker] = victim;
	g_iNumPend[attacker] += max(1, floatround(damage));
	if ((bits & DMG_BULLET) && get_member(victim, m_LastHitGroup) == HIT_HEAD) g_bHs[attacker] = true;
	g_bBossHit[attacker] = vxc_hud(0, F_BOSS) == victim;
	if (now - g_fNumAt[attacker] >= NUM_GAP) NumFlush(attacker, now);
	if (now - g_fHpAt[attacker] >= 0.1 && is_user_alive(victim)) HpLine(attacker, victim, now);
}

public fw_KilledPost(victim, killer)
{
	return; // v10.6: in the core
	if (!(1 <= killer <= g_iMax) || killer == victim || is_user_bot(killer) || !is_user_connected(killer) || g_iComboVictim[killer] != victim) return;
	if (g_iNumPend[killer]) NumFlush(killer, get_gametime());
	new name[32]; get_user_name(victim, name, charsmax(name));
	client_print(killer, print_center, En(killer) ? "%s  -  KILLED" : "%s  -  OLDURULDU", name);
	g_iComboVictim[killer] = 0; g_fHpAt[killer] = get_gametime() + 0.6;   // kill yazisi biraz ekranda kalsin
}

// a number at a random point on a ring around the crosshair; every hit gets a new spot and colour
NumFlush(id, Float:now)
{
	new d = g_iNumPend[id]; if (d <= 0) return;
	g_iNumPend[id] = 0; g_fNumAt[id] = now;
	new r, g, b;
	if (g_bHs[id]) { r = 255; g = 52; b = 52; }
	else if (g_bBossHit[id]) { r = 214; g = 122; b = 255; }
	else { new c = (g_iNumCol[id] + 1 + random(sizeof NUM_PAL - 1)) % sizeof NUM_PAL; g_iNumCol[id] = c; r = NUM_PAL[c][0]; g = NUM_PAL[c][1]; b = NUM_PAL[c][2]; }
	// ring around the crosshair (never on it), each hit in another sector so consecutive numbers do not overlap
	g_iNumSec[id] = (g_iNumSec[id] + 2 + random(4)) % 8;
	new Float:ang = (float(g_iNumSec[id]) + random_float(0.15, 0.85)) * 0.7854, Float:rad = random_float(0.75, 1.0);
	new Float:x = 0.5 + floatcos(ang, radian) * 0.11 * rad - 0.015;
	new Float:y = 0.5 + floatsin(ang, radian) * 0.13 * rad - 0.015;
	set_dhudmessage(r, g, b, floatclamp(x, 0.0, 0.95), floatclamp(y, 0.0, 0.95), 0, 0.0, 0.45, 0.0, 0.25);
	if (g_bHs[id]) show_dhudmessage(id, "%d!", d); else show_dhudmessage(id, "%d", d);
	g_bHs[id] = false;
}

// remaining HP of the target: original CS 1.6 yellow centre text (same place as "Switched to burst-fire mode")
HpLine(id, victim, Float:now)
{
	if (now < g_fHpAt[id]) return;
	g_fHpAt[id] = now + 0.1;
	new name[32]; get_user_name(victim, name, charsmax(name));
	client_print(id, print_center, "%s  :  %d HP", name, get_user_health(victim));
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
		vxc_ipad_card(id);   // only the iOS bell card, drawn like the CSO cards (does not move with the view)
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
		g_iNumPend[p] = 25 + random(90); g_bHs[p] = kind == 1; g_bBossHit[p] = kind == 3; NumFlush(p, get_gametime());
		client_print(p, print_center, "Test  :  %d HP", 1000 + random(4000));
	}
	return PLUGIN_HANDLED;
}

public client_disconnected(id)
{

	g_fNoteUntil[id] = 0.0; g_bFastSet[id] = false; g_szNote[id][0] = 0;
	g_iNumPend[id] = 0; g_fNumAt[id] = 0.0; g_fHpAt[id] = 0.0; g_iComboVictim[id] = 0;
}
