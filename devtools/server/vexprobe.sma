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
    RegisterHookChain(RG_RoundEnd, "fw_RoundEnd", true);
    register_srvcmd("vexprobe_status", "srv_Status");
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

public fw_Emit(const recipients, const ent, const chan, const sample[], const vol, Float:attn, const flags, const pitch)
{
    if (containi(sample, "vexmira") == -1)
        return HC_CONTINUE;
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
    log_amx("[vexprobe] mapcheck stuck=%d in_solid=%d fall_hurt=%d fall_deaths=%d world_deaths=%d",
        g_iStuckEvents, g_iInSolid, g_iFallHurt, g_iFallDeaths, g_iWorldDeaths);
    new s[96], n;
    for (new i = 0; i < ArraySize(g_aEmit); i++)
    {
        ArrayGetString(g_aEmit, i, s, charsmax(s));
        TrieGetCell(g_tEmit, s, n);
        log_amx("[vexprobe] emitted %5d %s", n, s);
    }
}
