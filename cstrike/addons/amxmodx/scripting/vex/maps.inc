/* ================================================================== */
/*  Vexmira Zombie - modul: vex/maps.inc  (HARITALAR)                 */
/*  Harita oylamasi, Rock The Vote, sonraki harita, harita            */
/*  degisimi, harita ortam sesleri (ambient_generic geri yukleme).    */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  FX / YARDIMCILAR                                                   */
/* ================================================================== */

/* ---------------- v3.0 (C): harita ortam sesleri (ambient_generic) ---------------- */
// Oyun (ReGameDLL) her round basinda dongulu ambient_generic seslerini yeniden calar, ama
// eklentinin "stopsound" komutu istemcide ayni karede islenince onlari da susturur. Bu yuzden
// her ambient_generic'in son durumu (ses / ses duzeyi / perde / acik-kapali) kaydedilir ve
// "stopsound"dan sonra sadece ACIK + DONGULU olanlar yeniden calinir. Eklenti sesleri
// (spk / mp3 / emit) yeniden calinmaz: round sonunda susma garantisi aynen gecerli.
public fw_AmbientPost(ent, const Float:pos[3], const sample[], Float:vol, Float:attn, flags, pitch)
{
    if (g_bAmbReplay || ent <= MaxClients || !pev_valid(ent) || !sample[0])
        return FMRES_IGNORED;
    new cls[20];
    pev(ent, pev_classname, cls, charsmax(cls));
    if (!equal(cls, "ambient_generic") || (pev(ent, pev_spawnflags) & 32))   // 32 = dongusuz (tek sefer)
        return FMRES_IGNORED;

    new slot = -1;
    for (new i = 0; i < g_iAmbN; i++)
    {
        if (g_iAmbEnt[i] == ent)
        {
            slot = i;
            break;
        }
    }
    if (slot < 0)
    {
        if (g_iAmbN >= MAX_AMB)
            return FMRES_IGNORED;
        slot = g_iAmbN++;
        g_iAmbEnt[slot] = ent;
        g_bAmbOn[slot] = false;
    }

    if (flags & SND_STOP)
    {
        g_bAmbOn[slot] = false;
        return FMRES_IGNORED;
    }
    if (flags & (SND_CHANGE_VOL | SND_CHANGE_PITCH))
    {
        // Rampa / perde degisimi: sadece calan ses guncellenir
        if (flags & SND_CHANGE_VOL)
            g_fAmbVol[slot] = vol;
        if (flags & SND_CHANGE_PITCH)
            g_iAmbPitch[slot] = pitch;
        return FMRES_IGNORED;
    }
    copy(g_szAmbSnd[slot], charsmax(g_szAmbSnd[]), sample);
    g_fAmbVol[slot] = vol;
    g_fAmbAttn[slot] = attn;
    g_iAmbPitch[slot] = pitch;
    g_bAmbOn[slot] = true;   // ses duzeyi 0 olsa bile (spin-up rampasi) sonraki degisimler bu kanala uygulanir
    return FMRES_IGNORED;
}

public task_AmbientRestore()
{
    new Float:o[3], n;
    g_bAmbReplay = true;
    for (new i = 0; i < g_iAmbN; i++)
    {
        new ent = g_iAmbEnt[i];
        if (!g_bAmbOn[i] || !g_szAmbSnd[i][0] || !pev_valid(ent))
            continue;
        pev(ent, pev_origin, o);
        engfunc(EngFunc_EmitAmbientSound, ent, o, g_szAmbSnd[i], g_fAmbVol[i], g_fAmbAttn[i], 0, g_iAmbPitch[i]);
        n++;
    }
    g_bAmbReplay = false;
    if (n)
        g_iAmbRestored++;
}


/* ================================================================== */
/*  v3.0 (C): HARITA OYLAMASI + ROCK THE VOTE                          */
/*  - 30 roundluk haritanin vex_map_vote_round. roundunda (varsayilan: */
/*    son roundan bir onceki) paket haritalari arasinda oylama.        */
/*  - Mevcut harita ve sunucuda olmayan haritalar listelenmez.         */
/*  - Menude canli oy sayisi + yuzde, oy degistirilebilir, botlar oy   */
/*    vermez, esitlikte rastgele, sonuc chat + DHUD + arayuz sesi.     */
/*  - Son round bitince: odul / MVP akisi -> ara ekran -> changelevel. */
/*  - /nextmap /maps /rtv, admin: vex_mapvote + admin menusu.          */
/*  - mapchooser.amxx yukluyse duraklatilir (cift oylama olmasin).     */
/* ================================================================== */

#define MAPV_MAX 8

MapVoteInit()
{
    g_pMapVote        = register_cvar("vex_map_vote", "1");
    g_pMapPool        = register_cvar("vex_map_pool", "zm_vex_laboratory zm_vex_harbor zm_vex_ruins zm_vex_frostbase zm_vex_temple");
    g_pMapVoteRound   = register_cvar("vex_map_vote_round", "0");
    g_pMapVoteTime    = register_cvar("vex_map_vote_time", "20");
    g_pMapVoteExtend  = register_cvar("vex_map_vote_extend", "0");
    g_pMapExtendRounds = register_cvar("vex_map_extend_rounds", "10");
    g_pMapChangeDelay = register_cvar("vex_map_change_delay", "7.0");
    g_pMapChooserGuard = register_cvar("vex_map_vote_mapchooser", "1");
    g_pRtvRatio       = register_cvar("vex_rtv_ratio", "0.60");
    g_pRtvMinPlayers  = register_cvar("vex_rtv_minplayers", "2");
    g_pRtvMinRound    = register_cvar("vex_rtv_minround", "3");
    // Diger eklentiler / sunucu listesi icin (nextmap.amxx yoksa da var olsun)
    g_pAmxNextmap     = register_cvar("amx_nextmap", "", FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_SPONLY);

    get_mapname(g_szCurMap, charsmax(g_szCurMap));
    strtolower(g_szCurMap);
    for (new i = 0; i <= MAX_PLAYERS; i++)
        g_iMapVoted[i] = -1;

    RegisterSay("nextmap", "sonrakiharita", "cmd_nextmap");
    RegisterSay("maps",    "haritalar",     "cmd_maps");
    RegisterSay("rtv",     "haritadegis",   "cmd_rtv");
    RegisterSay("rockthevote", "",          "cmd_rtv");
    register_concmd("vex_mapvote", "cmd_adm_mapvote", ADMIN_VOTE, "[next | cancel] - harita oylamasi (varsayilan: kazanan harita round sonunda gelir)");
    RegisterHookChain(RG_CSGameRules_ChangeLevel, "rg_ChangeLevel", false);
    set_task(7.5, "task_MapChooserCheck", TASK_MAPWARN);
}

bool:MapVoteOn()
{
    return get_pcvar_num(g_pMapVote) > 0 ? true : false;
}

// Harita sunucuda var mi? (maps/<ad>.bsp + motorun kendi kontrolu)
bool:MapExists(const map[])
{
    if (!map[0])
        return false;
    new path[64];
    formatex(path, charsmax(path), "maps/%s.bsp", map);
    return (file_exists(path, true) && is_map_valid(map)) ? true : false;
}

// Havuzdaki gecerli haritalar (mevcut harita ve olmayanlar haric, tekrarsiz)
MapCandidates(out[][32], maxn)
{
    new list[256], tmp[32], pos, n;
    get_pcvar_string(g_pMapPool, list, charsmax(list));
    while (n < maxn && (pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
    {
        strtolower(tmp);
        if (!tmp[0] || equal(tmp, g_szCurMap) || !MapExists(tmp))
            continue;
        new bool:dup = false;
        for (new i = 0; i < n; i++)
        {
            if (equal(out[i], tmp))
            {
                dup = true;
                break;
            }
        }
        if (!dup)
            copy(out[n++], 31, tmp);
    }
    return n;
}

// Oylamanin yapilacagi round (0 = otomatik: son roundan bir onceki)
MapVoteRoundNum()
{
    new total = RoundsTotal();
    new r = get_pcvar_num(g_pMapVoteRound);
    if (r <= 0)
        r = total - 1;
    return clamp(r, 1, total);
}

bool:MapEndsByRounds()
{
    return get_cvar_num("mp_maxrounds") > 0 ? true : false;
}

SetNextMap(const map[])
{
    copy(g_szNextMap, charsmax(g_szNextMap), map);
    g_bMapDecided = true;
    if (g_pAmxNextmap)
        set_pcvar_string(g_pAmxNextmap, map);
    if (cvar_exists("nextmap"))
        set_cvar_string("nextmap", map);
    log_amx("[Vexmira] sonraki harita: %s", map);
}

// Oylama olmadiysa (oyuncu yok / oylama kapali iken RTV): havuzdan rastgele
MapPickFallback()
{
    if (g_bMapDecided && g_szNextMap[0])
        return;
    new maps[MAPV_MAX][32];
    new n = MapCandidates(maps, MAPV_MAX);
    if (n > 0)
        SetNextMap(maps[random(n)]);
}

// Her saniye (task_Tick): otomatik oylama zamani geldi mi?
MapVoteTick()
{
    if (g_bMapVoting || g_bMapChanging || !g_bRoundActive || g_bRoundEnded)
    {
        g_iMapVoteWait = 0;
        return;
    }
    if (!MapVoteOn() || !MapEndsByRounds() || g_bMapDecided || g_iVoteType)
        return;
    if (g_iRound < MapVoteRoundNum())
        return;
    // Round basindaki duyurular bitsin
    if (++g_iMapVoteWait < 8)
        return;
    StartMapVote(0, false);
}

StartMapVote(starter, bool:changeNow)
{
    if (g_bMapVoting || g_iVoteType)
    {
        if (starter)
            Chat(starter, "VOTE_RUNNING");
        return false;
    }

    new maps[MAPV_MAX][32];
    new n = MapCandidates(maps, MAPV_MAX);
    new bool:ext = (get_pcvar_num(g_pMapVoteExtend) > 0 && (changeNow || (MapEndsByRounds() && g_iMapExtends < 1))) ? true : false;

    if (n == 0)
    {
        if (starter)
            Chat(starter, "MAPV_NONE");
        log_amx("[Vexmira] harita oylamasi: havuzda (vex_map_pool) baska gecerli harita yok");
        // Bir daha denenmesin; harita sonunda oyunun kendi dongusu (mapcyclefile) gecerli
        g_bMapDecided = true;
        g_szNextMap[0] = 0;
        return false;
    }
    if (n == 1 && !ext)
    {
        SetNextMap(maps[0]);
        g_bMapChangeNow = changeNow;
        ChatAllS("MAPV_ONLY", maps[0]);
        if (changeNow)
            MapChangeAfterRound();
        return true;
    }

    // Karisik sira, en fazla MAPV_MAX secenek (uzatma dahil)
    new lim = ext ? MAPV_MAX - 1 : MAPV_MAX;
    for (new i = n - 1; i > 0; i--)
    {
        new j = random(i + 1);
        new t[32];
        copy(t, charsmax(t), maps[i]);
        copy(maps[i], 31, maps[j]);
        copy(maps[j], 31, t);
    }
    g_iMapOptN = 0;
    for (new i = 0; i < n && g_iMapOptN < lim; i++)
        copy(g_szMapOpt[g_iMapOptN++], charsmax(g_szMapOpt[]), maps[i]);
    g_iMapExtOpt = -1;
    if (ext)
    {
        g_iMapExtOpt = g_iMapOptN;
        g_szMapOpt[g_iMapOptN++][0] = 0;
    }
    for (new i = 0; i < MAPV_MAX; i++)
        g_iMapVotes[i] = 0;
    for (new p = 0; p <= MAX_PLAYERS; p++)
        g_iMapVoted[p] = -1;

    g_bMapVoting = true;
    g_bMapChangeNow = changeNow;
    g_iMapVoteLeft = clamp(get_pcvar_num(g_pMapVoteTime), 5, 60);

    new name[32];
    if (starter)
        get_user_name(starter, name, charsmax(name));
    else
        copy(name, charsmax(name), "Vexmira");
    FunAll(starter, "MAPV_START", name, g_iMapVoteLeft);
    HudAll(SL_ANN, CLR_BRAND, 3.0, "MAPV_START_HUD");
    PlayKey(0, "UI_VOTE_START");

    remove_task(TASK_MAPVOTE);
    set_task(1.0, "task_MapVoteTick", TASK_MAPVOTE, _, _, "b");
    task_MapVoteTick();
    return true;
}

public task_MapVoteTick()
{
    if (!g_bMapVoting)
    {
        remove_task(TASK_MAPVOTE);
        return;
    }
    if (g_iMapVoteLeft <= 0)
    {
        FinishMapVote();
        return;
    }
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        if (MapVoteMenuOpen(p) || !AnyMenuOpen(p))
            ShowMapVoteMenu(p);
    }
    g_iMapVoteLeft--;
}

bool:MapVoteMenuOpen(id)
{
    new m, nm, pg;
    player_menu_info(id, m, nm, pg);
    return (nm != -1 && nm == g_iMapVoteMenu[id]) ? true : false;
}

MapOptName(id, opt, out[], len)
{
    if (opt == g_iMapExtOpt)
    {
        if (g_bMapChangeNow)
            formatex(out, len, "%L", id, "MAPV_STAY");
        else
            formatex(out, len, "%L", id, "MAPV_EXTEND", get_pcvar_num(g_pMapExtendRounds));
    }
    else
        copy(out, len, g_szMapOpt[opt]);
}

ShowMapVoteMenu(id)
{
    new total;
    for (new i = 0; i < g_iMapOptN; i++)
        total += g_iMapVotes[i];

    new title[192], item[128], nm[64], desc[48], key[48];
    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MAPV_TITLE", id, "MAPV_LEFT", g_iMapVoteLeft, total);
    new menu = menu_create(title, "menu_mapvote_handler");

    for (new i = 0; i < g_iMapOptN; i++)
    {
        MapOptName(id, i, nm, charsmax(nm));
        desc[0] = 0;
        if (i != g_iMapExtOpt)
        {
            formatex(key, charsmax(key), "MAPDESC_%s", g_szMapOpt[i]);
            if (GetLangTransKey(key) != TransKey_Bad)
                formatex(desc, charsmax(desc), " \d%L", id, key);
        }
        new pct = total > 0 ? (g_iMapVotes[i] * 100 + total / 2) / total : 0;
        if (g_iMapVoted[id] == i)
            formatex(item, charsmax(item), "\w%s%s \r[\w%d \r- \w%d%%\r] \y<", nm, desc, g_iMapVotes[i], pct);
        else
            formatex(item, charsmax(item), "\y%s%s \r[\w%d \r- \w%d%%\r]", nm, desc, g_iMapVotes[i], pct);
        MenuAdd(menu, item, i);
    }

    new note[96];
    formatex(note, charsmax(note), "^n\d%L", id, "MAPV_NOTE");
    menu_addtext(menu, note, 0);
    menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
    menu_setprop(menu, MPROP_PERPAGE, 0);
    menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
    g_iMapVoteMenu[id] = menu;
    menu_display(id, menu, 0, 1);
}

public menu_mapvote_handler(id, menu, item)
{
    if (item < 0 || !g_bMapVoting)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new opt = MenuInfo(menu, item);
    menu_destroy(menu);
    if (opt < 0 || opt >= g_iMapOptN || is_user_bot(id))
        return PLUGIN_HANDLED;

    // Oy degistirme serbest
    new old = g_iMapVoted[id];
    if (old == opt)
    {
        ShowMapVoteMenu(id);
        return PLUGIN_HANDLED;
    }
    if (0 <= old < g_iMapOptN)
        g_iMapVotes[old] = max(0, g_iMapVotes[old] - 1);
    g_iMapVoted[id] = opt;
    g_iMapVotes[opt]++;
    PlayKey(id, "UI_MENU_SELECT");

    new name[32], nm[64];
    get_user_name(id, name, charsmax(name));
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        MapOptName(p, opt, nm, charsmax(nm));
        client_print_color(p, id, "%s %L", ChatTag(old >= 0 ? "MAPV_RECAST" : "MAPV_CAST"), p, old >= 0 ? "MAPV_RECAST" : "MAPV_CAST", name, nm);
    }
    // Herkesin menusu bir sonraki saniyede yeni sayilarla yenilenir; oy veren hemen gorur
    ShowMapVoteMenu(id);
    return PLUGIN_HANDLED;
}

FinishMapVote()
{
    if (!g_bMapVoting)
        return;
    g_bMapVoting = false;
    remove_task(TASK_MAPVOTE);

    new total, bestc = -1, ties[MAPV_MAX], nt;
    for (new i = 0; i < g_iMapOptN; i++)
        total += g_iMapVotes[i];
    for (new i = 0; i < g_iMapOptN; i++)
    {
        // Hic oy yoksa uzatma secilmez (rastgele bir harita)
        if (total == 0 && i == g_iMapExtOpt)
            continue;
        if (g_iMapVotes[i] > bestc)
        {
            bestc = g_iMapVotes[i];
            nt = 0;
            ties[nt++] = i;
        }
        else if (g_iMapVotes[i] == bestc)
            ties[nt++] = i;
    }
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p) && MapVoteMenuOpen(p))
            show_menu(p, 0, "^n", 1);
        g_iMapVoted[p] = -1;
    }
    if (nt == 0)
        return;
    new win = ties[random(nt)];
    new pct = total > 0 ? (bestc * 100 + total / 2) / total : 0;
    PlayKey(0, "UI_VOTE_END");

    if (win == g_iMapExtOpt)
    {
        RtvReset();
        if (g_bMapChangeNow)
        {
            // RTV / admin oylamasi: harita kalir
            g_bMapChangeNow = false;
            ChatAll("MAPV_STAYED", bestc);
            HudAll(SL_ALERT, CLR_EVENT, 3.5, "MAPV_STAYED_HUD");
            return;
        }
        new ext = clamp(get_pcvar_num(g_pMapExtendRounds), 1, 50);
        g_iMapExtends++;
        g_iMapExtendTo = get_cvar_num("mp_maxrounds") + ext;
        set_cvar_num("mp_maxrounds", g_iMapExtendTo);
        g_bMapDecided = false;
        g_iMapVoteWait = 0;
        ChatAll("MAPV_EXTENDED", ext);
        HudAll(SL_ALERT, CLR_EVENT, 3.5, "MAPV_EXTENDED_HUD", ext);
        return;
    }

    SetNextMap(g_szMapOpt[win]);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        if (total == 0)
            client_print_color(p, print_team_default, "%s %L", ChatTag("MAPV_NOVOTES"), p, "MAPV_NOVOTES", g_szNextMap);
        else
            client_print_color(p, print_team_default, "%s %L", ChatTag("MAPV_RESULT"), p, "MAPV_RESULT", g_szNextMap, bestc, pct);
        HudToS(p, SL_ANN, CLR_EVENT, 4.0, "MAPV_RESULT_HUD", g_szNextMap);
    }
    RtvReset();
    if (g_bMapChangeNow)
        MapChangeAfterRound();
}

// Kazanan harita: round surerken -> round sonunda, round yoksa birkac saniye sonra
MapChangeAfterRound()
{
    g_bMapChangeNow = true;
    if (g_bRoundActive && !g_bRoundEnded)
        ChatAllS("MAPV_ROUNDEND", g_szNextMap);
    else
        MapChangeBegin(false);
}

// Round sonu (OnRoundEnd): son round veya bekleyen degisim -> odul akisi + ara ekran + changelevel
MapOnRoundEnd()
{
    if (g_bMapChanging || !MapVoteOn())
        return;
    new bool:last = (MapEndsByRounds() && g_iRound >= RoundsTotal()) ? true : false;
    if (!last && !g_bMapChangeNow)
        return;
    MapChangeBegin(last);
}

MapChangeBegin(bool:lastRound)
{
    if (g_bMapChanging)
        return;
    if (g_bMapVoting)
        FinishMapVote();
    if (!g_bMapDecided || !g_szNextMap[0])
    {
        g_bMapDecided = false;
        MapPickFallback();
    }
    if (!g_szNextMap[0])
    {
        // Gidilecek harita yok: oyunun kendi akisi (mp_maxrounds -> ara ekran -> mapcyclefile)
        g_bMapChangeNow = false;
        return;
    }
    g_bMapChanging = true;
    // Son round degilse (RTV / admin) harita sonu odulleri burada verilir
    if (!lastRound && !g_bMapAwards)
        set_task(1.5, "task_MapEndAwards");
    // Yeni round baslamasin (ara ekrana kadar)
    set_task(0.2, "task_MapHold", TASK_MAPHOLD);
    remove_task(TASK_MAPCHG);
    set_task(floatclamp(get_pcvar_float(g_pMapChangeDelay), 3.0, 30.0), "task_MapIntermission", TASK_MAPCHG);
}

public task_MapHold()
{
    if (g_bMapChanging)
        set_member_game(m_flRestartRoundTime, get_gametime() + 60.0);
}

public task_MapIntermission()
{
    if (!MapExists(g_szNextMap))
    {
        // Oylamadan sonra dosya silindiyse: baska bir harita
        g_bMapDecided = false;
        g_szNextMap[0] = 0;
        MapPickFallback();
        if (!g_szNextMap[0])
        {
            g_bMapChanging = false;
            set_member_game(m_flRestartRoundTime, get_gametime() + 1.0);
            return;
        }
    }
    ChatAllS("MAPV_CHANGING", g_szNextMap);
    HudAllS(SL_ANN, CLR_BRAND, 4.0, "MAPV_CHANGING_HUD", g_szNextMap);
    PlayKey(0, "UI_VOTE_END");
    // Skor tablosu (ara ekran), sonra harita degisir
    message_begin(MSG_ALL, SVC_INTERMISSION);
    message_end();
    set_task(3.5, "task_DoChangeLevel", TASK_MAPCHG + 1);
}

public task_DoChangeLevel()
{
    if (!g_szNextMap[0])
        return;
    log_amx("[Vexmira] harita degisiyor: %s -> %s", g_szCurMap, g_szNextMap);
    server_cmd("changelevel %s", g_szNextMap);
}

// Oyunun kendi harita degisimi (mp_timelimit / mp_maxrounds ara ekrani): oylanan haritaya git
public rg_ChangeLevel()
{
    if (!MapVoteOn())
        return HC_CONTINUE;
    if (!g_bMapDecided || !MapExists(g_szNextMap))
    {
        g_bMapDecided = false;
        g_szNextMap[0] = 0;
        MapPickFallback();
    }
    if (!g_szNextMap[0])
        return HC_CONTINUE;
    log_amx("[Vexmira] harita degisiyor (oyun): %s -> %s", g_szCurMap, g_szNextMap);
    server_cmd("changelevel %s", g_szNextMap);
    return HC_SUPERCEDE;
}

/* ---------------- Rock The Vote ---------------- */

RtvReset()
{
    g_iRtvCount = 0;
    for (new p = 0; p <= MAX_PLAYERS; p++)
        g_bRtv[p] = false;
}

// ignore: ayrilmakta olan oyuncu (client_disconnected'da hala bagli gorunur)
RtvNeeded(ignore = 0)
{
    new humans = RtvHumans(ignore);
    new Float:ratio = floatclamp(get_pcvar_float(g_pRtvRatio), 0.01, 1.0);
    return max(1, floatround(float(humans) * ratio, floatround_ceil));
}

RtvHumans(ignore = 0)
{
    new humans;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (p != ignore && is_user_connected(p) && !is_user_bot(p) && !is_user_hltv(p))
            humans++;
    }
    return humans;
}

public cmd_rtv(id)
{
    if (is_user_bot(id))
        return PLUGIN_HANDLED;
    if (!MapVoteOn() || get_pcvar_float(g_pRtvRatio) <= 0.0)
    {
        Chat(id, "RTV_OFF");
        return PLUGIN_HANDLED;
    }
    if (g_bMapChanging || (g_bMapDecided && g_bMapChangeNow && g_szNextMap[0]))
    {
        Chat(id, "RTV_CHANGING", g_szNextMap);
        return PLUGIN_HANDLED;
    }
    if (g_bMapVoting || g_iVoteType)
    {
        Chat(id, "VOTE_RUNNING");
        return PLUGIN_HANDLED;
    }
    if (g_bMapDecided && g_szNextMap[0])
    {
        Chat(id, "RTV_DECIDED", g_szNextMap);
        return PLUGIN_HANDLED;
    }
    new cand[MAPV_MAX][32];
    if (!MapCandidates(cand, MAPV_MAX))
    {
        Chat(id, "MAPV_NONE");
        return PLUGIN_HANDLED;
    }
    new minr = get_pcvar_num(g_pRtvMinRound);
    if (g_iRound < minr)
    {
        Chat(id, "RTV_TOO_EARLY", minr);
        return PLUGIN_HANDLED;
    }
    new minp = get_pcvar_num(g_pRtvMinPlayers);
    if (RtvHumans() < minp)
    {
        Chat(id, "RTV_MINPL", minp);
        return PLUGIN_HANDLED;
    }
    new need = RtvNeeded();
    if (g_bRtv[id])
    {
        Chat(id, "RTV_ALREADY", g_iRtvCount, need);
        return PLUGIN_HANDLED;
    }
    g_bRtv[id] = true;
    g_iRtvCount++;

    new name[32];
    get_user_name(id, name, charsmax(name));
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p))
            client_print_color(p, id, "%s %L", ChatTag("RTV_ROCKED"), p, "RTV_ROCKED", name, g_iRtvCount, need);
    }
    RtvCheck();
    return PLUGIN_HANDLED;
}

RtvCheck(ignore = 0)
{
    if (g_iRtvCount <= 0 || g_bMapVoting || g_bMapChanging || g_bMapDecided)
        return;
    if (g_iRtvCount < RtvNeeded(ignore))
        return;
    ChatAll("RTV_START");
    if (!StartMapVote(0, true))
        RtvReset();
}

// Ayrilan oyuncunun oyu / RTV'si duser
MapVoteDisconnect(id)
{
    if (g_bMapVoting && 0 <= g_iMapVoted[id] < g_iMapOptN)
        g_iMapVotes[g_iMapVoted[id]] = max(0, g_iMapVotes[g_iMapVoted[id]] - 1);
    g_iMapVoted[id] = -1;
    g_iMapVoteMenu[id] = -1;
    if (g_bRtv[id])
    {
        g_bRtv[id] = false;
        g_iRtvCount = max(0, g_iRtvCount - 1);
    }
}

/* ---------------- /nextmap /maps ---------------- */

public cmd_nextmap(id)
{
    if (g_bMapDecided && g_szNextMap[0])
        Chat(id, g_bMapChangeNow || g_bMapChanging ? "MAPV_NEXT_NOW" : "MAPV_NEXT_IS", g_szNextMap);
    else if (MapVoteOn() && MapEndsByRounds())
        Chat(id, "MAPV_NEXT_VOTE", MapVoteRoundNum(), RoundsTotal());
    else
    {
        new nm[32];
        if (g_pAmxNextmap)
            get_pcvar_string(g_pAmxNextmap, nm, charsmax(nm));
        Chat(id, "MAPV_NEXT_CYCLE", nm[0] ? nm : "-");
    }
    return PLUGIN_HANDLED;
}

public cmd_maps(id)
{
    new list[256], tmp[32], pos, line[180], n;
    get_pcvar_string(g_pMapPool, list, charsmax(list));
    while ((pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
    {
        strtolower(tmp);
        if (!tmp[0])
            continue;
        if (n++)
            add(line, charsmax(line), "^1, ");
        if (equal(tmp, g_szCurMap))
            format(line, charsmax(line), "%s^3%s*", line, tmp);
        else if (!MapExists(tmp))
            format(line, charsmax(line), "%s^1%s(-)", line, tmp);
        else if (g_bMapDecided && equal(tmp, g_szNextMap))
            format(line, charsmax(line), "%s^4%s>", line, tmp);
        else
            format(line, charsmax(line), "%s^4%s", line, tmp);
    }
    Chat(id, "MAPV_LIST_HDR", RoundsTotal() - g_iRound > 0 ? RoundsTotal() - g_iRound : 0);
    if (line[0])
        client_print_color(id, print_team_default, "^1%s", line);
    Chat(id, "MAPV_LIST_KEY");
    return PLUGIN_HANDLED;
}

/* ---------------- Admin ---------------- */

public cmd_adm_mapvote(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;
    new arg[16];
    read_argv(1, arg, charsmax(arg));
    if (equali(arg, "cancel"))
    {
        if (g_bMapVoting)
        {
            g_bMapVoting = false;
            remove_task(TASK_MAPVOTE);
            for (new p = 1; p <= g_iMax; p++)
            {
                if (is_user_connected(p) && !is_user_bot(p) && MapVoteMenuOpen(p))
                    show_menu(p, 0, "^n", 1);
            }
            g_bMapChangeNow = false;
            RtvReset();
            AdminNotify(id, "ADM_MAPVOTE_CANCEL", 0);
        }
        else
            console_print(id, "[Vexmira] -");
        return PLUGIN_HANDLED;
    }
    AdminStartMapVote(id, equali(arg, "next") ? false : true);
    return PLUGIN_HANDLED;
}

AdminStartMapVote(id, bool:changeNow)
{
    if (g_bMapChanging)
    {
        if (id)
            Chat(id, "RTV_CHANGING", g_szNextMap);
        console_print(id, "[Vexmira] harita zaten degisiyor: %s", g_szNextMap);
        return;
    }
    // Admin yeniden oylatabilir (onceki sonuc iptal)
    g_bMapDecided = false;
    g_szNextMap[0] = 0;
    if (StartMapVote(id, changeNow))
        AdminNotify(id, "ADM_MAPVOTE", g_iMapOptN);
    else
        console_print(id, "[Vexmira] oylama baslatilamadi (havuzda gecerli harita yok veya baska oylama suruyor)");
}

// mapchooser.amxx ayni anda kendi oylamasini yapmasin (cift oylama)
public task_MapChooserCheck()
{
    if (!MapVoteOn() || is_plugin_loaded("mapchooser.amxx", true) == -1)
        return;
    if (get_pcvar_num(g_pMapChooserGuard) > 0)
    {
        pause("ac", "mapchooser.amxx");
        log_amx("[Vexmira] mapchooser.amxx yuklu: cift harita oylamasi olmasin diye DURAKLATILDI. plugins.ini'den kaldirin (veya vex_map_vote 0).");
    }
    else
        log_amx("[Vexmira] UYARI: mapchooser.amxx yuklu ve vex_map_vote 1: iki ayri harita oylamasi olabilir. plugins.ini'den kaldirin.");
}
