/*  vexprobe - telemetry plugin for the Vexmira headless test server (NOT shipped)
 *
 *  Loaded FIRST (plugins.ini) so its precache hooks see every precache of the map:
 *    - exact engine precache slot usage (highest index returned by PF_precache_*_I + 1)
 *    - full precache name lists -> addons/amxmodx/logs/vexprobe_precache_<map>.txt
 *  During the game (every PROBE_INTERVAL s) one status line:
 *    teams / alive / infections (CT->T while alive) / max HP player (boss detection) /
 *    player model histogram / missing player-model files / entity count
 *  At map end: kills, rounds, round winners, vexmira sounds emitted (proof that skills ran).
 *  Map checks (run_test.py --maps-smoke):
 *    - every info_player_start / info_player_deathmatch: hull trace -> blocked / floating spawns
 *    - every player spawn: which spawn point was used (usage per team), spawned inside solid,
 *      spawned on top of another player, spawned away from any spawn point (plugin teleport)
 *    - alive bots sampled every second: "stuck" = pressing move keys but stayed within 48 units
 *      for STUCK_SECS while no enemy was within 160 units; "in_solid" = origin inside world solid
 *    - fall damage / fall deaths and deaths caused by the world or a non-player entity
 *
 *  Map interactivity (MAPS_v3.md section 4; use from run_test.py --cmd "<sec> <command>"):
 *    vexprobe_fire  <targetname> [usetype 0 off|1 on|3 toggle (default)] [activator #id]
 *                   Use every entity with that targetname (like the plugin's vex_* events)
 *    vexprobe_ents  <selector>   dump state: centre, solid, movetype, effects, health, render,
 *                   velocity, toggle state / ambient active / light on / multi_manager index
 *    vexprobe_break <targetname|#idx> [damage=100000]   damage breakables (as the first alive player)
 *    vexprobe_touch <targetname|#idx> [ct|t|#id]        touch triggers / doors with a living player
 *    vexprobe_tp    <ct|t|#id> <x> <y> <z>               teleport a living player (bot)
 *    selector: "*" (all map entities with a targetname or brush model), "#123" (entity index),
 *    "@name" / "@prefix*" (targetname), "classname" / "class_prefix*", "classname@x/y/z" (the entity
 *    of that class nearest to the point, e.g. a touch-door without targetname; use "/" because the
 *    console splits arguments at ","); fire/break/touch
 *    treat a bare word as a targetname. Activator / player arguments: ct | t | #id.
 *    Logged automatically: every Use of a scripted map entity ("use ..."), every map -> plugin
 *    relay ("vexcmd ..." = trigger_relay named vexcmd_*), every broken func_breakable ("broken ...").
 *
 *  All output goes through log_amx with the "[vexprobe]" prefix (parsed by run_test.py).
 */
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#define PROBE_INTERVAL 5.0
#define MOVE_INTERVAL 1.0
#define STUCK_SECS 10.0
#define MAX_SPAWNS 160

new g_iMaxMdl, g_iMaxSnd, g_iMaxGen;
new Trie:g_tMdl, Trie:g_tSnd, Trie:g_tGen, Trie:g_tEmit, Array:g_aEmit;
new Array:g_aMdlNames, Array:g_aSndNames, Array:g_aGenNames;
new HookChain:g_hcMdl, HookChain:g_hcSnd, HookChain:g_hcGen;
new g_iTeamPrev[33], g_iInfections, g_iKills, g_iRounds, g_iCTWin, g_iTWin, g_iMaxEnts, g_iTicks;
new Float:g_fStart;
new g_iEmitTotal;
// map checks
new Float:g_fSpawn[MAX_SPAWNS][3], g_iSpawnTeam[MAX_SPAWNS], g_iSpawnUse[MAX_SPAWNS], g_iSpawnCount;
new g_iSpawnBlocked, g_iSpawnFloating, g_iSpawnsTotal, g_iOffSpawn, g_iStacked, g_iSpawnStuck;
new Float:g_fAnchor[33][3], Float:g_fAnchorT[33], g_iWantMove[33], g_iSamples[33], bool:g_bStuckLogged[33];
new bool:g_bInSolid[33];
new g_iStuckEvents, g_iInSolid, g_iFallHurt, g_iFallDeaths, g_iWorldDeaths;
// NaN / runaway velocity watch (engine prints "PM Got a NaN velocity" without saying who/why)
new bool:g_bNanLogged[33], g_iNanEvents;
new g_szLastEmit[4][64], Float:g_fLastEmit[4], g_iLastEmitEnt[4], g_iLastEmitPos;
// map interactivity
#define PROBE_EDICTS 2048
new Float:g_fLastUse[PROBE_EDICTS], g_iMapUses, g_iVexcmd, g_iBroken;
new const USE_CLASSES[][] = {
    "trigger_relay", "multi_manager", "func_door", "func_door_rotating", "func_button", "func_rot_button",
    "func_breakable", "func_train", "func_tracktrain", "func_wall_toggle", "ambient_generic", "env_sprite",
    "light", "env_render", "game_text", "env_shake", "env_fade", "func_rotating", "multisource", "trigger_hurt",
    "trigger_once", "trigger_multiple", "env_beam", "env_laser", "func_plat", "game_counter",
    "trigger_changetarget", "func_pushable", "env_explosion", "func_conveyor", "game_team_master"
};

public plugin_precache()
{
    g_tMdl = TrieCreate(); g_tSnd = TrieCreate(); g_tGen = TrieCreate();
    g_aMdlNames = ArrayCreate(96); g_aSndNames = ArrayCreate(96); g_aGenNames = ArrayCreate(96);
    // engine-level (ReHLDS) hooks: see precaches from the game DLL, the map AND every AMXX plugin
    g_hcMdl = RegisterHookChain(RH_PF_precache_model_I, "fw_PcMdl", true);
    g_hcSnd = RegisterHookChain(RH_PF_precache_sound_I, "fw_PcSnd", true);
    g_hcGen = RegisterHookChain(RH_PF_precache_generic_I, "fw_PcGen", true);
}

Track(Trie:t, Array:a, const name[], &maxIdx)
{
    new idx = GetHookChainReturn(ATYPE_INTEGER);
    if (idx > maxIdx)
        maxIdx = idx;
    if (!TrieKeyExists(t, name))
    {
        TrieSetCell(t, name, idx);
        new s[96];
        formatex(s, charsmax(s), "%4d %s", idx, name);
        ArrayPushString(a, s);
    }
}
public fw_PcMdl(const name[]) { Track(g_tMdl, g_aMdlNames, name, g_iMaxMdl); return HC_CONTINUE; }
public fw_PcSnd(const name[]) { Track(g_tSnd, g_aSndNames, name, g_iMaxSnd); return HC_CONTINUE; }
public fw_PcGen(const name[]) { Track(g_tGen, g_aGenNames, name, g_iMaxGen); return HC_CONTINUE; }

public plugin_init()
{
    register_plugin("vexprobe", "1.0", "vexmira-devtools");
    RegisterHookChain(RG_CBasePlayer_Killed, "fw_Killed", true);
    RegisterHookChain(RG_CBasePlayer_Spawn, "fw_Spawn", true);
    RegisterHookChain(RG_CBasePlayer_TakeDamage, "fw_TakeDamage", false);
    register_logevent("ev_RoundStart", 2, "1=Round_Start");
    register_logevent("ev_RoundEnd", 2, "1=Round_End");
    RegisterHookChain(RH_SV_StartSound, "fw_Emit", false);
    register_forward(FM_StartFrame, "fw_StartFrame", 1);
    RegisterHookChain(RG_RoundEnd, "fw_RoundEnd", true);
    register_srvcmd("vexprobe_status", "srv_Status");
    register_srvcmd("vexprobe_fire", "srv_Fire");
    register_srvcmd("vexprobe_ents", "srv_Ents");
    register_srvcmd("vexprobe_break", "srv_Break");
    register_srvcmd("vexprobe_touch", "srv_Touch");
    register_srvcmd("vexprobe_tp", "srv_Tp");
    for (new i = 0; i < sizeof USE_CLASSES; i++)
        RegisterHam(Ham_Use, USE_CLASSES[i], "fw_MapUse", 0);
    RegisterHam(Ham_TakeDamage, "func_breakable", "fw_BreakPre", 0);
    RegisterHam(Ham_Use, "func_breakable", "fw_BreakPre", 0);
    RegisterHam(Ham_TakeDamage, "func_breakable", "fw_BreakDamaged", 1);
    RegisterHam(Ham_Use, "func_breakable", "fw_BreakUsed", 1);
    g_tEmit = TrieCreate();
    g_aEmit = ArrayCreate(96);
    g_fStart = get_gametime();
    set_task(PROBE_INTERVAL, "task_Status", 9301, _, _, "b");
    set_task(MOVE_INTERVAL, "task_Move", 9302, _, _, "b");
    CollectSpawns("info_player_start", 2);
    CollectSpawns("info_player_deathmatch", 1);
    new ct, t;
    for (new i = 0; i < g_iSpawnCount; i++)
        if (g_iSpawnTeam[i] == 2) ct++; else t++;
    log_amx("[vexprobe] spawnpoints ct=%d t=%d blocked=%d floating=%d", ct, t, g_iSpawnBlocked, g_iSpawnFloating);
}

CollectSpawns(const cls[], team)
{
    new ent = -1;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", cls)) > 0)
    {
        if (g_iSpawnCount >= MAX_SPAWNS)
            break;
        new Float:o[3], Float:e[3];
        pev(ent, pev_origin, o);
        o[2] += 1.0;                       // CBasePlayer::Spawn puts the player 1 unit above the entity
        g_fSpawn[g_iSpawnCount] = o;
        g_iSpawnTeam[g_iSpawnCount] = team;
        g_iSpawnCount++;
        new tr = create_tr2();
        engfunc(EngFunc_TraceHull, o, o, IGNORE_MONSTERS, HULL_HUMAN, 0, tr);
        if (get_tr2(tr, TR_StartSolid) || get_tr2(tr, TR_AllSolid))
        {
            g_iSpawnBlocked++;
            log_amx("[vexprobe] spawn_blocked %s %.0f %.0f %.0f (player hull inside solid)", team == 2 ? "ct" : "t",
                o[0], o[1], o[2]);
        }
        else
        {
            e = o;
            e[2] -= 512.0;
            engfunc(EngFunc_TraceHull, o, e, IGNORE_MONSTERS, HULL_HUMAN, 0, tr);
            new Float:f;
            get_tr2(tr, TR_flFraction, f);
            if (f * 512.0 > 18.0)
            {
                g_iSpawnFloating++;
                log_amx("[vexprobe] spawn_floating %s %.0f %.0f %.0f drop=%.0f", team == 2 ? "ct" : "t",
                    o[0], o[1], o[2], f * 512.0);
            }
        }
        free_tr2(tr);
    }
}

public fw_Spawn(const id)
{
    if (!is_user_alive(id))
        return HC_CONTINUE;
    new team = get_user_team(id);
    if (team != 1 && team != 2)
        return HC_CONTINUE;
    new Float:o[3];
    pev(id, pev_origin, o);
    g_iSpawnsTotal++;
    new best = -1, Float:bd = 999999.0;
    for (new i = 0; i < g_iSpawnCount; i++)
    {
        new Float:d = get_distance_f(o, g_fSpawn[i]);
        if (d < bd) { bd = d; best = i; }
    }
    if (best >= 0 && bd <= 4.0)
        g_iSpawnUse[best]++;
    else
        g_iOffSpawn++;
    new tr = create_tr2();
    engfunc(EngFunc_TraceHull, o, o, IGNORE_MONSTERS, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, tr);
    if (get_tr2(tr, TR_StartSolid) || get_tr2(tr, TR_AllSolid))
    {
        g_iSpawnStuck++;
        log_amx("[vexprobe] spawn_in_solid #%d team=%d %.0f %.0f %.0f", id, team, o[0], o[1], o[2]);
    }
    free_tr2(tr);
    for (new p = 1; p <= MaxClients; p++)
    {
        if (p == id || !is_user_alive(p))
            continue;
        new Float:q[3];
        pev(p, pev_origin, q);
        if (floatabs(q[0] - o[0]) < 32.0 && floatabs(q[1] - o[1]) < 32.0 && floatabs(q[2] - o[2]) < 72.0)
        {
            g_iStacked++;
            break;
        }
    }
    ResetAnchor(id, o);
    g_bInSolid[id] = false;
    return HC_CONTINUE;
}

ResetAnchor(id, const Float:o[3])
{
    g_fAnchor[id] = o;
    g_fAnchorT[id] = get_gametime();
    g_iWantMove[id] = 0;
    g_iSamples[id] = 0;
    g_bStuckLogged[id] = false;
}

public task_Move()
{
    new Float:now = get_gametime();
    for (new p = 1; p <= MaxClients; p++)
    {
        if (!is_user_alive(p) || !is_user_bot(p))
            continue;
        new Float:o[3];
        pev(p, pev_origin, o);
        if (engfunc(EngFunc_PointContents, o) == CONTENTS_SOLID)
        {
            if (!g_bInSolid[p])
            {
                g_iInSolid++;
                log_amx("[vexprobe] in_solid #%d team=%d %.0f %.0f %.0f", p, get_user_team(p), o[0], o[1], o[2]);
            }
            g_bInSolid[p] = true;
        }
        else
            g_bInSolid[p] = false;
        new Float:ms;
        pev(p, pev_maxspeed, ms);
        if ((pev(p, pev_flags) & FL_FROZEN) || ms < 5.0 || get_distance_f(o, g_fAnchor[p]) > 48.0)
        {
            ResetAnchor(p, o);
            continue;
        }
        if (EnemyNear(p, o, 160.0))       // fighting / clawing at a human is not "stuck"
        {
            ResetAnchor(p, o);
            continue;
        }
        g_iSamples[p]++;
        if (pev(p, pev_button) & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT))
            g_iWantMove[p]++;
        if (!g_bStuckLogged[p] && now - g_fAnchorT[p] >= STUCK_SECS && g_iWantMove[p] * 2 >= g_iSamples[p])
        {
            g_bStuckLogged[p] = true;
            g_iStuckEvents++;
            new name[32], mdl[32];
            get_user_name(p, name, charsmax(name));
            get_user_info(p, "model", mdl, charsmax(mdl));
            log_amx("[vexprobe] stuck #%d %s team=%d model=%s at %.0f %.0f %.0f (%.0fs within 48u, move keys %d/%d samples)",
                p, name, get_user_team(p), mdl, o[0], o[1], o[2], now - g_fAnchorT[p], g_iWantMove[p], g_iSamples[p]);
        }
    }
}

bool:EnemyNear(id, const Float:o[3], Float:r)
{
    new team = get_user_team(id);
    for (new q = 1; q <= MaxClients; q++)
    {
        if (q == id || !is_user_alive(q) || get_user_team(q) == team)
            continue;
        new Float:e[3];
        pev(q, pev_origin, e);
        if (get_distance_f(o, e) < r)
            return true;
    }
    return false;
}

public fw_TakeDamage(const id, const inflictor, const attacker, Float:dmg, const bits)
{
    if (!(bits & DMG_FALL) || !is_user_alive(id))
        return HC_CONTINUE;
    g_iFallHurt++;
    if (dmg >= float(get_user_health(id)))
    {
        g_iFallDeaths++;
        new Float:o[3];
        pev(id, pev_origin, o);
        log_amx("[vexprobe] fall_death #%d team=%d dmg=%.0f at %.0f %.0f %.0f", id, get_user_team(id), dmg, o[0], o[1], o[2]);
    }
    return HC_CONTINUE;
}

public plugin_cfg()
{
    // all plugin_precache calls are done by now (later ones would be engine errors anyway)
    DisableHookChain(g_hcMdl);
    DisableHookChain(g_hcSnd);
    DisableHookChain(g_hcGen);
    new map[64];
    get_mapname(map, charsmax(map));
    log_amx("[vexprobe] precache map=%s model=%d/512 sound=%d/512 generic=%d/512 (unique names: model %d sound %d generic %d)",
        map, g_iMaxMdl + 1, g_iMaxSnd + 1, g_iMaxGen + 1, TrieGetSize(g_tMdl), TrieGetSize(g_tSnd), TrieGetSize(g_tGen));
    new path[128];
    formatex(path, charsmax(path), "addons/amxmodx/logs/vexprobe_precache_%s.txt", map);
    delete_file(path);
    DumpList(path, "MODELS", g_aMdlNames);
    DumpList(path, "SOUNDS", g_aSndNames);
    DumpList(path, "GENERIC", g_aGenNames);
}

DumpList(const path[], const title[], Array:a)
{
    new s[96];
    formatex(s, charsmax(s), "== %s (%d)", title, ArraySize(a));
    write_file(path, s);
    for (new i = 0; i < ArraySize(a); i++)
    {
        ArrayGetString(a, i, s, charsmax(s));
        write_file(path, s);
    }
}

bool:BadVec(const Float:v[3])
{
    for (new i = 0; i < 3; i++)
        if (v[i] != v[i] || floatabs(v[i]) > 100000.0)
            return true;
    return false;
}

public fw_StartFrame()
{
    for (new p = 1; p <= MaxClients; p++)
    {
        if (!is_user_alive(p))
        {
            g_bNanLogged[p] = false;
            continue;
        }
        new Float:v[3], Float:o[3];
        pev(p, pev_velocity, v);
        pev(p, pev_origin, o);
        if (g_bNanLogged[p] || (!BadVec(v) && !BadVec(o)))
            continue;
        g_bNanLogged[p] = true;
        g_iNanEvents++;
        new mdl[32], recent[300], tmp[96];
        get_user_info(p, "model", mdl, charsmax(mdl));
        for (new k = 0; k < 4; k++)
        {
            new i = (g_iLastEmitPos + 3 - k) % 4;
            if (!g_szLastEmit[i][0])
                continue;
            formatex(tmp, charsmax(tmp), "%s[-%.1fs ent%d] %s", k ? ", " : "", get_gametime() - g_fLastEmit[i],
                g_iLastEmitEnt[i], g_szLastEmit[i]);
            add(recent, charsmax(recent), tmp);
        }
        log_amx("[vexprobe] nan_velocity #%d team=%d model=%s hp=%d vel=%f %f %f origin=%f %f %f flags=%d movetype=%d | last vexmira sounds: %s",
            p, get_user_team(p), mdl, get_user_health(p), v[0], v[1], v[2], o[0], o[1], o[2], pev(p, pev_flags),
            pev(p, pev_movetype), recent);
    }
}

public fw_Emit(const recipients, const ent, const chan, const sample[], const vol, Float:attn, const flags, const pitch)
{
    if (containi(sample, "vexmira") == -1)
        return HC_CONTINUE;
    g_iLastEmitPos = (g_iLastEmitPos + 1) % 4;
    copy(g_szLastEmit[g_iLastEmitPos], charsmax(g_szLastEmit[]), sample);
    g_fLastEmit[g_iLastEmitPos] = get_gametime();
    g_iLastEmitEnt[g_iLastEmitPos] = ent;
    g_iEmitTotal++;
    new n;
    if (TrieGetCell(g_tEmit, sample, n))
        TrieSetCell(g_tEmit, sample, n + 1);
    else
    {
        TrieSetCell(g_tEmit, sample, 1);
        ArrayPushString(g_aEmit, sample);
        log_amx("[vexprobe] first emit t=%.0f ent=%d %s", get_gametime() - g_fStart, ent, sample);
    }
    return HC_CONTINUE;
}

public fw_RoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
    static const W[][] = { "none", "ct", "t", "draw" };
    new st = _:status;
    if (st >= 0 && st < sizeof W)
    {
        if (st == 1) g_iCTWin++;
        else if (st == 2) g_iTWin++;
    }
    log_amx("[vexprobe] round_win t=%.0f status=%s event=%d", get_gametime() - g_fStart,
        (st >= 0 && st < sizeof W) ? W[st] : "?", _:event);
    return HC_CONTINUE;
}

public fw_Killed(const victim, const attacker, const gib)
{
    g_iKills++;
    {
        new Float:v[3];
        pev(victim, pev_velocity, v);
        if (BadVec(v))
        {
            new cls[32] = "world";
            if (attacker > 0 && pev_valid(attacker))
                pev(attacker, pev_classname, cls, charsmax(cls));
            log_amx("[vexprobe] nan_death #%d team=%d by #%d (%s) vel=%f %f %f", victim, get_user_team(victim), attacker, cls,
                v[0], v[1], v[2]);
        }
    }
    if (attacker != victim && (attacker < 1 || attacker > MaxClients))
    {
        g_iWorldDeaths++;
        new cls[32], Float:o[3];
        if (attacker > 0 && pev_valid(attacker))
            pev(attacker, pev_classname, cls, charsmax(cls));
        else
            copy(cls, charsmax(cls), "world");
        pev(victim, pev_origin, o);
        log_amx("[vexprobe] world_death #%d team=%d by %s at %.0f %.0f %.0f", victim, get_user_team(victim), cls, o[0], o[1], o[2]);
    }
    return HC_CONTINUE;
}

public ev_RoundStart() { g_iRounds++; log_amx("[vexprobe] round_start #%d t=%.0f", g_iRounds, get_gametime() - g_fStart); }
public ev_RoundEnd() { log_amx("[vexprobe] round_end t=%.0f kills=%d infections=%d", get_gametime() - g_fStart, g_iKills, g_iInfections); }

public srv_Status() { task_Status(); return PLUGIN_HANDLED; }

public task_Status()
{
    g_iTicks++;
    new ct, t, ctA, tA, spec, maxhp, maxid, nb;
    new Trie:hist = TrieCreate(), Array:keys = ArrayCreate(32);
    new mdl[32], path[96];
    for (new p = 1; p <= MaxClients; p++)
    {
        if (!is_user_connected(p))
        {
            g_iTeamPrev[p] = 0;
            continue;
        }
        if (is_user_bot(p)) nb++;
        new team = get_user_team(p);
        new alive = is_user_alive(p);
        if (team == 2) { ct++; if (alive) ctA++; }
        else if (team == 1) { t++; if (alive) tA++; }
        else spec++;
        if (alive && g_iTeamPrev[p] == 2 && team == 1)
            g_iInfections++;
        g_iTeamPrev[p] = team;
        if (!alive)
            continue;
        new hp = get_user_health(p);
        if (hp > maxhp) { maxhp = hp; maxid = p; }
        get_user_info(p, "model", mdl, charsmax(mdl));
        new c;
        if (TrieGetCell(hist, mdl, c))
            TrieSetCell(hist, mdl, c + 1);
        else
        {
            TrieSetCell(hist, mdl, 1);
            ArrayPushString(keys, mdl);
            formatex(path, charsmax(path), "models/player/%s/%s.mdl", mdl, mdl);
            if (mdl[0] && !file_exists(path))
                log_amx("[vexprobe] MISSING player model file %s (used by #%d)", path, p);
        }
    }
    new line[400], tmp[48];
    for (new i = 0; i < ArraySize(keys); i++)
    {
        new c;
        ArrayGetString(keys, i, mdl, charsmax(mdl));
        TrieGetCell(hist, mdl, c);
        formatex(tmp, charsmax(tmp), "%s%s x%d", i ? ", " : "", mdl, c);
        add(line, charsmax(line), tmp);
    }
    new ents = engfunc(EngFunc_NumberOfEntities);
    if (ents > g_iMaxEnts) g_iMaxEnts = ents;
    new mname[32], mmodel[32];
    if (maxid)
    {
        get_user_name(maxid, mname, charsmax(mname));
        get_user_info(maxid, "model", mmodel, charsmax(mmodel));
    }
    log_amx("[vexprobe] status t=%.0f players=%d bots=%d CT %d/%d T %d/%d spec=%d infections=%d kills=%d rounds=%d ents=%d maxhp=%d(%s %s) models: %s",
        get_gametime() - g_fStart, ct + t + spec, nb, ctA, ct, tA, t, spec, g_iInfections, g_iKills, g_iRounds, ents,
        maxhp, mname, mmodel, line);
    TrieDestroy(hist);
    ArrayDestroy(keys);
}

public plugin_end()
{
    log_amx("[vexprobe] final rounds=%d ct_wins=%d t_wins=%d kills=%d infections=%d max_ents=%d vexmira_sounds_emitted=%d unique=%d",
        g_iRounds, g_iCTWin, g_iTWin, g_iKills, g_iInfections, g_iMaxEnts, g_iEmitTotal, ArraySize(g_aEmit));
    new uct, ut, nct, nt;
    for (new i = 0; i < g_iSpawnCount; i++)
    {
        if (g_iSpawnTeam[i] == 2) { nct++; if (g_iSpawnUse[i]) uct++; }
        else { nt++; if (g_iSpawnUse[i]) ut++; }
    }
    log_amx("[vexprobe] spawn_usage ct=%d/%d t=%d/%d spawns=%d off_spawn=%d stacked=%d in_solid=%d",
        uct, nct, ut, nt, g_iSpawnsTotal, g_iOffSpawn, g_iStacked, g_iSpawnStuck);
    log_amx("[vexprobe] mapcheck stuck=%d in_solid=%d fall_hurt=%d fall_deaths=%d world_deaths=%d nan_velocity=%d | mapio uses=%d vexcmd=%d broken=%d",
        g_iStuckEvents, g_iInSolid, g_iFallHurt, g_iFallDeaths, g_iWorldDeaths, g_iNanEvents, g_iMapUses, g_iVexcmd, g_iBroken);
    new s[96], n;
    for (new i = 0; i < ArraySize(g_aEmit); i++)
    {
        ArrayGetString(g_aEmit, i, s, charsmax(s));
        TrieGetCell(g_tEmit, s, n);
        log_amx("[vexprobe] emitted %5d %s", n, s);
    }
}

/* ------------------------------------------------------------------ map interactivity tools */
Float:RoundTime() { return get_gametime() - g_fStart; }

EntCenter(ent, Float:c[3])
{
    new mdl[4];
    pev(ent, pev_model, mdl, charsmax(mdl));
    if (mdl[0] == '*')
    {
        new Float:a[3], Float:b[3];
        pev(ent, pev_absmin, a);
        pev(ent, pev_absmax, b);
        for (new i = 0; i < 3; i++)
            c[i] = (a[i] + b[i]) * 0.5;
    }
    else
        pev(ent, pev_origin, c);
}

EntLabel(ent, out[], len)
{
    if (ent <= 0 || !pev_valid(ent))
    {
        copy(out, len, ent == 0 ? "world" : "none");
        return;
    }
    new cls[32], tn[48];
    pev(ent, pev_classname, cls, charsmax(cls));
    pev(ent, pev_targetname, tn, charsmax(tn));
    if (tn[0])
        formatex(out, len, "%s#%d'%s'", cls, ent, tn);
    else
        formatex(out, len, "%s#%d", cls, ent);
}

public fw_MapUse(ent, caller, activator, usetype, Float:value)
{
    if (ent <= MaxClients || !pev_valid(ent))
        return HAM_IGNORED;
    g_iMapUses++;
    new cls[32], tn[64], who[96];
    pev(ent, pev_classname, cls, charsmax(cls));
    pev(ent, pev_targetname, tn, charsmax(tn));
    EntLabel(caller, who, charsmax(who));
    if (equal(cls, "trigger_relay") && equal(tn, "vexcmd_", 7))
    {
        g_iVexcmd++;
        log_amx("[vexprobe] vexcmd t=%.1f %s from %s activator=#%d", RoundTime(), tn, who, activator);
        return HAM_IGNORED;
    }
    new Float:now = get_gametime();
    if (ent < PROBE_EDICTS && now - g_fLastUse[ent] < 0.5)
        return HAM_IGNORED;
    if (ent < PROBE_EDICTS)
        g_fLastUse[ent] = now;
    new Float:c[3];
    EntCenter(ent, c);
    log_amx("[vexprobe] use t=%.1f %s#%d '%s' type=%d from %s activator=#%d at %.0f %.0f %.0f", RoundTime(), cls, ent, tn,
        usetype, who, activator, c[0], c[1], c[2]);
    return HAM_IGNORED;
}

new bool:g_bBrokenLogged[PROBE_EDICTS];

BreakCheck(ent, by, const how[])
{
    if (ent >= PROBE_EDICTS || !pev_valid(ent))
        return;
    new bool:gone = pev(ent, pev_solid) == SOLID_NOT || (pev(ent, pev_effects) & EF_NODRAW) != 0;
    if (!gone)
    {
        g_bBrokenLogged[ent] = false;
        return;
    }
    if (g_bBrokenLogged[ent])
        return;
    g_bBrokenLogged[ent] = true;
    g_iBroken++;
    new tn[64], Float:c[3];
    pev(ent, pev_targetname, tn, charsmax(tn));
    EntCenter(ent, c);
    log_amx("[vexprobe] broken t=%.1f func_breakable#%d '%s' at %.0f %.0f %.0f by #%d (%s)", RoundTime(), ent, tn, c[0], c[1],
        c[2], by, how);
}
public fw_BreakPre(ent)
{
    if (ent < PROBE_EDICTS && pev_valid(ent) && pev(ent, pev_solid) != SOLID_NOT && !(pev(ent, pev_effects) & EF_NODRAW))
        g_bBrokenLogged[ent] = false;
}
public fw_BreakDamaged(ent, inflictor, attacker, Float:dmg, bits) { BreakCheck(ent, attacker, "damage"); }
public fw_BreakUsed(ent, caller, activator, usetype, Float:value) { BreakCheck(ent, activator, "use"); }

// first living player of a team (2 = CT, 1 = T, 0 = any), CT preferred for 0
FindPlayer(team)
{
    for (new pass = 0; pass < 2; pass++)
    {
        for (new p = 1; p <= MaxClients; p++)
        {
            if (!is_user_alive(p))
                continue;
            new t = get_user_team(p);
            if (team ? (t == team) : (pass == 0 ? t == 2 : true))
                return p;
        }
        if (team)
            break;
    }
    return 0;
}

ParseWho(const arg[])
{
    if (arg[0] == '#')
    {
        new id = str_to_num(arg[1]);
        return (id >= 1 && id <= MaxClients && is_user_alive(id)) ? id : 0;
    }
    if (equali(arg, "ct"))
        return FindPlayer(2);
    if (equali(arg, "t"))
        return FindPlayer(1);
    return FindPlayer(0);
}

bool:WildMatch(const s[], const pat[])
{
    new n = strlen(pat);
    if (n > 0 && pat[n - 1] == '*')
        return n == 1 || equal(s, pat, n - 1);
    return bool:equal(s, pat);
}

// collect entities: "#idx", "@targetname[*]", "*", "classname[*]"; byName=true: bare word = targetname
CollectEnts(const sel[], list[], maxn, bool:byName)
{
    new n, ents = engfunc(EngFunc_NumberOfEntities), maxe = global_get(glb_maxEntities);
    if (sel[0] == '#')
    {
        new e = str_to_num(sel[1]);
        if (e > 0 && pev_valid(e))
            list[n++] = e;
        return n;
    }
    new at = contain(sel, "@");
    if (at > 0)
    {
        // classname@x,y,z -> nearest entity of that class
        new cname[32], pos[48], sx[16], sy[16], sz[16];
        copy(cname, min(at, charsmax(cname)), sel);
        copy(pos, charsmax(pos), sel[at + 1]);
        replace_all(pos, charsmax(pos), ",", " ");
        replace_all(pos, charsmax(pos), "/", " ");
        parse(pos, sx, charsmax(sx), sy, charsmax(sy), sz, charsmax(sz));
        new Float:p[3], Float:c[3], best = 0, Float:bd = 999999.0;
        p[0] = str_to_float(sx); p[1] = str_to_float(sy); p[2] = str_to_float(sz);
        new e = MaxClients;
        while ((e = engfunc(EngFunc_FindEntityByString, e, "classname", cname)) > 0)
        {
            EntCenter(e, c);
            new Float:d = get_distance_f(p, c);
            if (d < bd) { bd = d; best = e; }
        }
        if (best)
            list[n++] = best;
        return n;
    }
    new mode = 0, pat[64];       // 0 classname, 1 targetname, 2 all
    if (sel[0] == '@')
    {
        mode = 1;
        copy(pat, charsmax(pat), sel[1]);
    }
    else if (equal(sel, "*"))
        mode = 2;
    else
    {
        mode = byName ? 1 : 0;
        copy(pat, charsmax(pat), sel);
    }
    new cls[32], tn[64], mdl[4], seen;
    for (new e = MaxClients + 1; e < maxe && seen < ents && n < maxn; e++)
    {
        if (!pev_valid(e))
            continue;
        seen++;
        pev(e, pev_classname, cls, charsmax(cls));
        pev(e, pev_targetname, tn, charsmax(tn));
        if (mode == 1 && !(tn[0] && WildMatch(tn, pat)))
            continue;
        if (mode == 0 && !WildMatch(cls, pat))
            continue;
        if (mode == 2)
        {
            pev(e, pev_model, mdl, charsmax(mdl));
            if (!tn[0] && mdl[0] != '*')
                continue;
            if (equal(cls, "weaponbox") || equal(cls, "weapon_", 7) || equal(cls, "player"))
                continue;
        }
        list[n++] = e;
    }
    return n;
}

public srv_Fire()
{
    new name[64], a2[8], a3[8];
    read_argv(1, name, charsmax(name));
    if (!name[0])
    {
        server_print("usage: vexprobe_fire <targetname> [usetype 0|1|3] [activator #id]");
        return PLUGIN_HANDLED;
    }
    read_argv(2, a2, charsmax(a2));
    read_argv(3, a3, charsmax(a3));
    new usetype = a2[0] ? str_to_num(a2) : 3;
    new act = ParseWho(a3);
    new list[128], n = CollectEnts(name, list, sizeof list, true);
    new classes[200], cls[32];
    for (new i = 0; i < n; i++)
    {
        pev(list[i], pev_classname, cls, charsmax(cls));
        format(classes, charsmax(classes), "%s%s%s#%d", classes, i ? "," : "", cls, list[i]);
    }
    log_amx("[vexprobe] fire t=%.1f '%s' type=%d activator=#%d -> %d entities %s", RoundTime(), name, usetype, act, n, classes);
    for (new i = 0; i < n; i++)
        if (pev_valid(list[i]))
            ExecuteHamB(Ham_Use, list[i], act, act, usetype, 0.0);
    return PLUGIN_HANDLED;
}

public srv_Break()
{
    new name[64], a2[16];
    read_argv(1, name, charsmax(name));
    read_argv(2, a2, charsmax(a2));
    new Float:dmg = a2[0] ? str_to_float(a2) : 100000.0;
    new att = FindPlayer(0);
    new list[64], n = CollectEnts(name, list, sizeof list, true);
    log_amx("[vexprobe] break t=%.1f '%s' dmg=%.0f attacker=#%d -> %d entities", RoundTime(), name, dmg, att, n);
    for (new i = 0; i < n; i++)
        if (pev_valid(list[i]) && pev(list[i], pev_takedamage) != DAMAGE_NO)
            ExecuteHamB(Ham_TakeDamage, list[i], att, att, dmg, DMG_BULLET);
    return PLUGIN_HANDLED;
}

public srv_Touch()
{
    new name[64], a2[8];
    read_argv(1, name, charsmax(name));
    read_argv(2, a2, charsmax(a2));
    new who = ParseWho(a2);
    new list[64], n = CollectEnts(name, list, sizeof list, true);
    log_amx("[vexprobe] touch t=%.1f '%s' by #%d team=%d -> %d entities", RoundTime(), name, who, who ? get_user_team(who) : 0, n);
    if (!who)
        return PLUGIN_HANDLED;
    for (new i = 0; i < n; i++)
        if (pev_valid(list[i]))
            ExecuteHamB(Ham_Touch, list[i], who);
    return PLUGIN_HANDLED;
}

public srv_Tp()
{
    new a1[8], sx[16], sy[16], sz[16];
    read_argv(1, a1, charsmax(a1));
    read_argv(2, sx, charsmax(sx));
    read_argv(3, sy, charsmax(sy));
    read_argv(4, sz, charsmax(sz));
    new who = ParseWho(a1);
    if (!who || !sz[0])
    {
        log_amx("[vexprobe] tp failed (who=%s -> #%d)", a1, who);
        return PLUGIN_HANDLED;
    }
    new Float:o[3];
    o[0] = str_to_float(sx); o[1] = str_to_float(sy); o[2] = str_to_float(sz);
    engfunc(EngFunc_SetOrigin, who, o);
    set_pev(who, pev_velocity, Float:{0.0, 0.0, 0.0});
    ResetAnchor(who, o);
    log_amx("[vexprobe] tp t=%.1f #%d team=%d -> %.0f %.0f %.0f", RoundTime(), who, get_user_team(who), o[0], o[1], o[2]);
    return PLUGIN_HANDLED;
}

bool:IsToggleClass(const cls[])
{
    static const T[][] = { "func_door", "func_door_rotating", "func_button", "func_rot_button", "func_plat",
        "func_platrot", "func_train", "trigger_once", "trigger_multiple", "trigger_hurt", "momentary_door" };
    for (new i = 0; i < sizeof T; i++)
        if (equal(cls, T[i]))
            return true;
    return false;
}

public srv_Ents()
{
    new sel[64];
    read_argv(1, sel, charsmax(sel));
    if (!sel[0])
        copy(sel, charsmax(sel), "*");
    new list[256], n = CollectEnts(sel, list, sizeof list, false);
    log_amx("[vexprobe] ents t=%.1f '%s' -> %d", RoundTime(), sel, n);
    new cls[32], tn[48], extra[96], Float:c[3], Float:v[3], Float:av[3], Float:amt, Float:hp, Float:nt, Float:base;
    for (new i = 0; i < n; i++)
    {
        new e = list[i];
        pev(e, pev_classname, cls, charsmax(cls));
        pev(e, pev_targetname, tn, charsmax(tn));
        EntCenter(e, c);
        pev(e, pev_velocity, v);
        pev(e, pev_avelocity, av);
        pev(e, pev_renderamt, amt);
        pev(e, pev_health, hp);
        pev(e, pev_nextthink, nt);
        new mt = pev(e, pev_movetype);
        if (mt == MOVETYPE_PUSH)
            pev(e, pev_ltime, base);
        else
            base = get_gametime();
        extra[0] = 0;
        if (IsToggleClass(cls))
            formatex(extra, charsmax(extra), " toggle=%d", get_ent_data(e, "CBaseToggle", "m_toggle_state"));
        if (equal(cls, "func_door_rotating") || equal(cls, "func_rotating") || equal(cls, "func_rot_button"))
        {
            new Float:ang[3];
            pev(e, pev_angles, ang);
            format(extra, charsmax(extra), "%s ang=%.0f,%.0f,%.0f", extra, ang[0], ang[1], ang[2]);
        }
        if (equal(cls, "func_train"))
            format(extra, charsmax(extra), "%s active=%d", extra, get_ent_data(e, "CFuncTrain", "m_activated"));
        else if (equal(cls, "ambient_generic"))
            formatex(extra, charsmax(extra), " active=%d looping=%d", get_ent_data(e, "CAmbientGeneric", "m_fActive"),
                get_ent_data(e, "CAmbientGeneric", "m_fLooping"));
        else if (equal(cls, "multi_manager"))
            formatex(extra, charsmax(extra), " index=%d", get_ent_data(e, "CMultiManager", "m_index"));
        else if (equal(cls, "light") || equal(cls, "light_spot"))
            formatex(extra, charsmax(extra), " on=%d style=%d", !(pev(e, pev_spawnflags) & 1), get_ent_data(e, "CLight", "m_iStyle"));
        else if (equal(cls, "game_counter"))
        {
            new Float:fr;
            pev(e, pev_frags, fr);
            formatex(extra, charsmax(extra), " count=%.0f", fr);
        }
        else if (equal(cls, "trigger_relay") || equal(cls, "trigger_changetarget"))
        {
            new tg[48];
            pev(e, pev_target, tg, charsmax(tg));
            formatex(extra, charsmax(extra), " target='%s'", tg);
        }
        log_amx("[vexprobe] ent #%d %s '%s' at %.0f %.0f %.0f solid=%d move=%d fx=%d hp=%.0f dmg=%d rm=%d/%.0f vel=%.0f,%.0f,%.0f avel=%.0f nthink=%.1f sf=%d%s",
            e, cls, tn, c[0], c[1], c[2], pev(e, pev_solid), mt, pev(e, pev_effects), hp, pev(e, pev_takedamage),
            pev(e, pev_rendermode), amt, v[0], v[1], v[2], av[1], nt > 0.0 ? nt - base : -1.0, pev(e, pev_spawnflags), extra);
    }
    return PLUGIN_HANDLED;
}
