/*  vexprobe - telemetry plugin for the Vexmira headless test server (NOT shipped)
 *
 *  Loaded FIRST (plugins.ini) so its precache hooks see every precache of the map:
 *    - exact engine precache slot usage (highest index returned by PF_precache_*_I + 1)
 *    - full precache name lists -> addons/amxmodx/logs/vexprobe_precache_<map>.txt
 *  During the game (every PROBE_INTERVAL s) one status line:
 *    teams / alive / infections (CT->T while alive) / max HP player (boss detection) /
 *    player model histogram / missing player-model files / entity count
 *  At map end: kills, rounds, round winners, vexmira sounds emitted (proof that skills ran).
 *
 *  All output goes through log_amx with the "[vexprobe]" prefix (parsed by run_test.py).
 */
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#define PROBE_INTERVAL 5.0

new g_iMaxMdl, g_iMaxSnd, g_iMaxGen;
new Trie:g_tMdl, Trie:g_tSnd, Trie:g_tGen, Trie:g_tEmit, Array:g_aEmit;
new Array:g_aMdlNames, Array:g_aSndNames, Array:g_aGenNames;
new HookChain:g_hcMdl, HookChain:g_hcSnd, HookChain:g_hcGen;
new g_iTeamPrev[33], g_iInfections, g_iKills, g_iRounds, g_iCTWin, g_iTWin, g_iMaxEnts, g_iTicks;
new Float:g_fStart;
new g_iEmitTotal;

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
    register_logevent("ev_RoundStart", 2, "1=Round_Start");
    register_logevent("ev_RoundEnd", 2, "1=Round_End");
    RegisterHookChain(RH_SV_StartSound, "fw_Emit", false);
    RegisterHookChain(RG_RoundEnd, "fw_RoundEnd", true);
    register_srvcmd("vexprobe_status", "srv_Status");
    g_tEmit = TrieCreate();
    g_aEmit = ArrayCreate(96);
    g_fStart = get_gametime();
    set_task(PROBE_INTERVAL, "task_Status", 9301, _, _, "b");
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
    new s[96], n;
    for (new i = 0; i < ArraySize(g_aEmit); i++)
    {
        ArrayGetString(g_aEmit, i, s, charsmax(s));
        TrieGetCell(g_tEmit, s, n);
        log_amx("[vexprobe] emitted %5d %s", n, s);
    }
}
