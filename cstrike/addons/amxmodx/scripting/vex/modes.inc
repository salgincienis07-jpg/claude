/* ================================================================== */
/*  Vexmira Zombie - modul: vex/modes.inc  (MODLAR)                   */
/*  Round akisi (ReAPI round hook'lari, kazanma kosulu), 1 sn tick,   */
/*  mod secimi ve baslatma, event'ler (meteor, firtina, simsek),      */
/*  mod / event oylamasi, round plani.                                */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  INIT                                                               */
/* ================================================================== */

// Round suresi dolunca oyun kendi bitirmesin (CheckWin bitirir); cfg unutulsa bile
public task_EnforceRoundInfinite()
{
    new v[32];
    get_cvar_string("mp_round_infinite", v, charsmax(v));
    if (!equal(v, "1") && contain(v, "a") == -1)
        set_cvar_string("mp_round_infinite", "abcdefghijk");
}


/* ================================================================== */
/*  ROUND AKISI (ReAPI)                                                */
/* ================================================================== */

// Oyunun kendi kazanma kontrolunu tamamen kapat: round'u plugin bitirir.
public rg_CheckWinConditions()
{
    return HC_SUPERCEDE;
}

// Bomba verilmesin
public rg_MakeBomber(id)
{
    SetHookChainReturn(ATYPE_BOOL, false);
    return HC_SUPERCEDE;
}

public rg_RestartRound()
{
    // Onceki roundun sesleri (kalp atisi, muzik, yanma, ruzgar...) tamamen susar.
    // "stopsound" haritanin dongulu ortam seslerini de susturur: kisa sure sonra yeniden baslar.
    if (get_pcvar_num(g_pRoundStopSnd))
    {
        StopAllClientSounds();
        remove_task(TASK_AMBREST);
        set_task(0.8, "task_AmbientRestore", TASK_AMBREST);
    }

    remove_task(TASK_ANNOUNCE);
    remove_task(TASK_BOSSCAST);
    remove_task(TASK_BOSSHIT);
    g_iMapVoteWait = 0;
    remove_task(TASK_BOSSFX);
    remove_task(TASK_INTRO);
    g_iBossPhase = 0;

    g_bRoundActive = false;
    g_bRoundEnded = false;
    g_bCounting = false;
    g_bWaiting = false;
    g_bEnraged = false;
    g_bLastAnn = false;
    g_bFirstInfect = false;
    g_iBoss = 0;
    g_iBossTick = 0;
    g_iMeteorTick = 0;
    g_iGlobalInfBombs = 0;
    g_iAirdropClock = 0;
    g_fEclipseEnd = 0.0;
    g_fBlizzardEnd = 0.0;
    for (new i = 0; i < sizeof g_fPoolEnd; i++)
        g_fPoolEnd[i] = 0.0;

    for (new f = 0; f < MAX_FLARES; f++)
        g_fFlareEnd[f] = 0.0;

    RemoveAllMines();
    RemoveAllDrops();
    BossCleanup();
    ZcCleanupAll();
    OvhRemoveAll();
    g_fSndKill = 0.0;
    TrieClear(g_tRoundBuys);
    g_iStartTries = 0;
    g_bAnnounced = false;
    remove_task(TASK_INTRO + 1);
    for (new t = 0; t < 30; t++)
        remove_task(TASK_BOSSHIT + t);

    for (new id = 1; id <= g_iMax; id++)
    {
        g_bZombie[id] = 0; g_bNemesis[id] = 0; g_bAssassin[id] = 0; g_bSurvivor[id] = 0; g_bSniper[id] = 0;
        g_bBoss[id] = 0; g_bMinion[id] = 0; g_bFirst[id] = 0; g_bForceZombie[id] = 0;
        g_fRespawnAt[id] = 0.0;
        g_bLmGiven[id] = false;
        ResetRoundData(id);
        ResetLifeData(id);
    }

    // Round numarasi oyunun kendi sayaci ile ayni (mp_maxrounds ile uyumlu)
    if (get_member_game(m_bCompleteReset))
        g_iRound = 1;
    else
        g_iRound = get_member_game(m_iTotalRoundsPlayed) + 2;

    // mp_maxrounds kapaliysa plan basa doner; aciksa son roundan sonra harita degisir
    new total = RoundsTotal();
    if (g_iRound > total)
    {
        if (get_cvar_num("mp_maxrounds") > 0)
        {
            g_iMode = MODE_INFECTION;
            g_iEvent = EV_NONE;
            ApplyWorldEvent();
            return;
        }
        g_iRound = ((g_iRound - 1) % total) + 1;
    }

    PickMode();
    PickCalmPreset();
    ApplyWorldEvent();
    ApplyHostname();

    set_task(1.2, "task_Announce", TASK_ANNOUNCE);
}

RoundsTotal()
{
    new m = get_cvar_num("mp_maxrounds");
    return (m > 0) ? m : max(1, get_pcvar_num(g_pRoundsTotal));
}

// "7 15 23 30" gibi listede bu round var mi?
bool:RoundInList(pcvar, round)
{
    new list[128], tmp[8], pos;
    get_pcvar_string(pcvar, list, charsmax(list));
    while ((pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
    {
        if (str_to_num(tmp) == round)
            return true;
    }
    return false;
}

bool:IsBossRound(round)
{
    new list[128];
    get_pcvar_string(g_pBossRounds, list, charsmax(list));
    trim(list);
    if (list[0])
        return RoundInList(g_pBossRounds, round);

    new every = max(1, get_pcvar_num(g_pBossEvery));
    return (round > 1 && round % every == 0) ? true : false;
}

// Siradaki boss roundu kac round sonra? (0 = yok)
RoundsToBoss()
{
    new total = RoundsTotal();
    for (new r = g_iRound + 1; r <= total; r++)
    {
        if (IsBossRound(r))
            return r - g_iRound;
    }
    return 0;
}

// Bosslar karisik sirayla gelir, ayni boss arka arkaya gelmez.
// v3.0: torbada sadece bu haritada YUKLENEN bosslar var (precache butcesi).
ShuffleBosses()
{
    new n = BossBagSize();
    new last = (g_iBossBagPos > 0 && g_iBossBagPos <= n) ? g_iBossBag[n - 1] : -1;
    for (new i = 0; i < n; i++)
        g_iBossBag[i] = g_iBossLoadN > 0 ? g_iBossLoadList[i] : i;
    for (new i = n - 1; i > 0; i--)
    {
        new j = random(i + 1), t = g_iBossBag[i];
        g_iBossBag[i] = g_iBossBag[j];
        g_iBossBag[j] = t;
    }
    if (n > 1 && g_iBossBag[0] == last)
    {
        new t = g_iBossBag[0];
        g_iBossBag[0] = g_iBossBag[n - 1];
        g_iBossBag[n - 1] = t;
    }
    g_iBossBagPos = 0;
}

BossBagSize()
{
    return g_iBossLoadN > 0 ? g_iBossLoadN : NUM_BOSSES;
}

NextBoss()
{
    if (g_iBossBagPos >= BossBagSize())
        ShuffleBosses();
    return g_iBossBag[clamp(g_iBossBagPos++, 0, NUM_BOSSES - 1)];
}

PickSpecialMode(players)
{
    new total, w[MODE_TOTAL];
    for (new m = MODE_NEMESIS; m < MODE_BOSS; m++)
    {
        if (m == g_iLastSpecial || players < MODE_MINPL[m])
            continue;
        w[m] = max(1, MODE_CHANCE[m]);
        total += w[m];
    }
    if (!total)
        return MODE_INFECTION;

    new roll = random_num(1, total), acc;
    for (new m = MODE_NEMESIS; m < MODE_BOSS; m++)
    {
        acc += w[m];
        if (w[m] && roll <= acc)
            return m;
    }
    return MODE_INFECTION;
}

PickMode()
{
    new players = CountPlaying();
    g_iMode = MODE_INFECTION;
    g_bFinalBoss = false;

    if (g_iForceMode >= 0)
    {
        g_iMode = g_iForceMode;
        g_iForceMode = -1;
    }
    else if (IsBossRound(g_iRound) && players >= MODE_MINPL[MODE_BOSS])
        g_iMode = MODE_BOSS;
    else if (RoundInList(g_pSpecialRounds, g_iRound))
        g_iMode = PickSpecialMode(players);
    else if (g_iRound >= 3 && random_num(1, 100) <= get_pcvar_num(g_pMultiChance))
        g_iMode = MODE_MULTI;

    if (g_iMode == MODE_BOSS)
    {
        g_bFinalBoss = (g_iRound >= RoundsTotal()) ? true : false;
        if (g_iForceBoss >= 0 && g_iForceBoss < NUM_BOSSES && BossIsLoaded(g_iForceBoss))
        {
            g_iBossType = g_iForceBoss;
            g_iForceBoss = -1;
        }
        else
            g_iBossType = NextBoss();
    }
    else if (g_iMode >= MODE_NEMESIS)
        g_iLastSpecial = g_iMode;


    // Event'ler sadece normal (infection / multi) roundlarda; ilk round sakin
    new last = g_iEvent;
    if (g_iMode != MODE_INFECTION && g_iMode != MODE_MULTI)
        g_iEvent = EV_NONE;
    else if (g_iForceEvent >= 0)
    {
        g_iEvent = g_iForceEvent;
        g_iForceEvent = -1;
    }
    else if (g_iRound > 1 && random_num(1, 100) <= get_pcvar_num(g_pEventChance))
    {
        g_iEvent = random_num(EV_BLOODMOON, EV_TOTAL - 1);
        if (g_iEvent == last)
            g_iEvent = (g_iEvent + random_num(1, EV_TOTAL - 2)) % EV_TOTAL;
        if (g_iEvent == EV_NONE)
            g_iEvent = EV_BLOODMOON;
    }
    else
        g_iEvent = EV_NONE;
}

public task_Announce()
{
    g_bAnnounced = true;
    new key[20];
    new total = RoundsTotal();

    // Moda ozel muzik (ini: MODE<n>_MUSIC)
    new mkey[16], mpath[128];
    formatex(mkey, charsmax(mkey), "MODE%d_MUSIC", g_iMode);
    if (TrieGetString(g_tRes, mkey, mpath, charsmax(mpath)) && mpath[0])
    {
        for (new p = 1; p <= g_iMax; p++)
        {
            if (is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_AMB))
                PlayKey(p, mkey);
        }
    }

    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p))
            client_print_color(p, print_team_default, "%s %L", ChatTag("ROUND_CHAT2"), p, "ROUND_CHAT2", g_iRound, total);
    }

    AssignQuests();

    // Son round
    if (g_iRound >= total)
    {
        PlayKey(0, "FINAL_ROUND");
        PlayVoxAll("VOX_FINAL");
        ChatAll("FINAL_ROUND_CHAT");
    }
    else if (total - g_iRound == 2)
        ChatAll("ROUNDS_LEFT_2");

    if (g_iMode == MODE_BOSS)
    {
        formatex(key, charsmax(key), "BOSS_ANN_%d", g_iBossType);
        HudAll(SL_ANN, BOSS_RGB[g_iBossType][0], BOSS_RGB[g_iBossType][1], BOSS_RGB[g_iBossType][2], 4.0, key);
        if (g_bFinalBoss)
            HudAll(SL_ALERT, CLR_DANGER, 3.0, "FINAL_BOSS_HUD");
        PlayKey(0, "BOSS_SPAWN");
        PlayVoxAll("VOX_BOSS");
        FadeAll(BOSS_RGB[g_iBossType][0] / 2, BOSS_RGB[g_iBossType][1] / 2, BOSS_RGB[g_iBossType][2] / 2, 90, 2.0);
        ShakeAll(6, 2.0, 3);
        if (get_pcvar_num(g_pLmEnable) && !get_pcvar_num(g_pLmBoss))
            ChatAll("LM_BOSS_BLOCKED");
        return;
    }

    if (g_iMode != MODE_INFECTION && g_iMode != MODE_MULTI)
    {
        formatex(key, charsmax(key), "MODE_ANN_%d", g_iMode);
        HudAll(SL_ANN, CLR_WARN, 4.0, key);
        PlayKey(0, "MODE_START");
        FadeAll(255, 80, 0, 50, 1.2);
        BossTeaser();
        return;
    }

    if (g_iEvent != EV_NONE)
    {
        formatex(key, charsmax(key), "EV_ANN_%d", g_iEvent);
        new r, g, b;
        EventColor(g_iEvent, r, g, b);
        HudAll(SL_ANN, r, g, b, 4.0, key);
        PlayKey(0, "EVENT_START");
        EventStartFx();
    }
    else
        HudAll(SL_ANN, CLR_CYAN, 3.5, "ROUND_CALM", g_iRound);

    BossTeaser();
}

// Boss yaklasiyor uyarisi (oyunculari heyecanlandirir)
BossTeaser()
{
    new left = RoundsToBoss();
    if (left == 1)
    {
        ChatAll("BOSS_SOON_1");
        PlayKey(0, "BOSS_SOON");
    }
    else if (left == 2)
        ChatAll("BOSS_SOON_2", left);
}

// Event renkleri (HUD + ekran)
EventColor(ev, &r, &g, &b)
{
    switch (ev)
    {
        case EV_BLOODMOON, EV_VAMPIRE: { r = 255; g = 40;  b = 40; }
        case EV_FOG:                   { r = 190; g = 200; b = 210; }
        case EV_SPEED:                 { r = 0;   g = 230; b = 255; }
        case EV_LOWGRAV:               { r = 150; g = 120; b = 255; }
        case EV_DOUBLEDMG, EV_HEADHUNTER: { r = 255; g = 130; b = 0; }
        case EV_NIGHT, EV_BLACKOUT:    { r = 120; g = 120; b = 255; }
        case EV_PLAGUE, EV_HORDE:      { r = 120; g = 255; b = 0; }
        case EV_SUPPLY, EV_GOLDRUSH:   { r = 255; g = 210; b = 0; }
        case EV_BERSERK, EV_TITAN:     { r = 255; g = 70;  b = 0; }
        case EV_ADRENALINE:            { r = 0;   g = 255; b = 140; }
        case EV_METEOR:                { r = 255; g = 100; b = 0; }
        case EV_STORM:                 { r = 230; g = 240; b = 255; }
        default:                       { r = 0;   g = 200; b = 255; }
    }
}

public rg_FreezeEnd()
{
    g_iCountdown = get_pcvar_num(g_pCountdown);
    g_bCounting = true;

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id))
            continue;

        ApplyHumanGravity(id);
        rg_reset_maxspeed(id);

        if (g_iEvent == EV_SUPPLY && !g_bZombie[id])
        {
            g_iFireNades[id]++;
            rg_give_item(id, "weapon_hegrenade");
            rg_set_user_armor(id, 200, ARMOR_VESTHELM);
            g_iFrostNades[id]++;
            rg_give_item(id, "weapon_smokegrenade");
        }
        if (g_iEvent == EV_SPEED)
            SpeedRushFx(id);
    }

    if (g_iEvent == EV_SUPPLY)
        g_iAirdropClock = 5;
}

public rg_RoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
    OnRoundEnd(status);
}

// Round sonu: odul, MVP, ozet. Hem kendi bitirisimizde hem oyunun bitirisinde
// tek sefer calisir (MVP artik her durumda gorunur).
OnRoundEnd(WinStatus:status)
{
    if (g_bRoundEnded)
        return;

    g_bRoundEnded = true;
    g_bCounting = false;

    // Mod / boss muzigi round bitince susar
    StopRoundMusic();
    // v3.0: sinif yetenekleri (kanca, lav, keseler, karartma...) round bitince durur
    ZcCleanupAll();
    // v3.0 (B): can barlari round bitince kalkar (ikonlar sonraki kontrolde yeniden gelir)
    OvhRemoveAll();

    new bool:wasActive = g_bRoundActive;
    g_bRoundActive = false;

    if (!wasActive)
        return;

    if (status == WINSTATUS_CTS)
    {
        g_iHumanStreak++;
        g_iZombieStreak = 0;
        if (g_iHumanStreak >= 3)
            LiveAll(0, "LIVE_HSTREAK", 2, g_iHumanStreak);

        HudAll(SL_ANN, CLR_GOOD, 4.0, "HUMANS_WIN");
        PlayKey(0, "HUMAN_WIN");

        new xp = get_pcvar_num(g_pWinHXP), ap = get_pcvar_num(g_pWinHAP);
        switch (g_iMode)
        {
            case MODE_BOSS:                     { xp = xp * 14 / 5; ap = ap * 5 / 2; }
            case MODE_SURVIVOR, MODE_SNIPER:    { xp = xp * 8 / 5;  ap = ap * 5 / 3; }
            case MODE_NEMESIS, MODE_ASSASSIN:   { xp = xp * 12 / 5; ap = ap * 2; }
            case MODE_ARMAGEDDON, MODE_PLAGUE:  { xp = xp * 2;      ap = ap * 5 / 3; }
        }

        new players[32];
        new n = GetHumans(players);
        for (new i = 0; i < n; i++)
        {
            g_iWins[players[i]]++;
            Reward(players[i], xp, ap);
            QuestEvent(players[i], 7, 1);
        }

        if (n == 1 && g_bLastAnn && !g_bSurvivor[players[0]] && !g_bSniper[players[0]])
            GrantAch(players[0], 7);
    }
    else if (status == WINSTATUS_TERRORISTS)
    {
        g_iZombieStreak++;
        g_iHumanStreak = 0;
        if (g_iZombieStreak >= 3)
            LiveAll(0, "LIVE_ZSTREAK", 2, g_iZombieStreak);

        HudAll(SL_ANN, CLR_DANGER, 4.0, "ZOMBIES_WIN");
        PlayKey(0, "ZOMBIE_WIN");

        for (new id = 1; id <= g_iMax; id++)
        {
            if (is_user_connected(id) && g_bZombie[id] && !g_bMinion[id])
                Reward(id, get_pcvar_num(g_pWinZXP), get_pcvar_num(g_pWinZAP));
        }
    }

    if (status == WINSTATUS_CTS || status == WINSTATUS_TERRORISTS)
        RoundSummary();

    if (g_iRound >= RoundsTotal())
        set_task(1.5, "task_MapEndAwards");
    // v3.0 (C): son round / RTV: oylanan haritaya gecis (odul + MVP akisindan sonra)
    MapOnRoundEnd();

    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id))
            SaveData(id);
    }
    SaveTop();
}

// MVP + kisisel round ozeti
RoundSummary()
{
    // MVP puani: verilen hasar + enfeksiyon * 600 + oldurme * 250
    new mvp, bestScore;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
            continue;
        new score = g_iRoundDmg[id] + g_iRoundInf[id] * 600 + g_iRoundKills[id] * 250;
        if (score > bestScore)
        {
            bestScore = score;
            mvp = id;
        }
    }

    new name[32], txt[128];
    g_iRoundMvp = mvp;   // v3.0: kafa ustu MVP ikonu (sonraki round boyunca)
    if (mvp)
    {
        get_user_name(mvp, name, charsmax(name));
        new vc = get_pcvar_num(g_pMvpVC), ap = get_pcvar_num(g_pMvpAP);
        g_iVC[mvp] += vc;
        AddAP(mvp, ap, false, false);

        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_connected(p) || is_user_bot(p))
                continue;
            formatex(txt, charsmax(txt), "%L", p, "MVP_HUD", name, g_iRoundDmg[mvp], g_iRoundKills[mvp], g_iRoundInf[mvp]);
            HudText(p, SL_ALERT, CLR_REWARD, 4.0, txt);
            client_print_color(p, mvp, "%s %L", ChatTag("MVP_CHAT2"), p, "MVP_CHAT2", name, g_iRoundDmg[mvp], g_iRoundKills[mvp], g_iRoundInf[mvp], ap, vc);
            if (!(g_iSet[p] & SET_NO_AMB))
                PlayKey(p, "MVP");
        }

        if (is_user_alive(mvp))
        {
            new Float:o[3];
            get_entvar(mvp, var_origin, o);
            FxRingEx(o, 255, 200, 40, 300, 12, 6);
            FxLight(o, 255, 200, 40, 30, 20, 10);
            set_user_rendering(mvp, kRenderFxGlowShell, 255, 200, 40, kRenderNormal, 20);
        }
    }

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_bot(id))
            continue;
        formatex(txt, charsmax(txt), "%L", id, "ROUND_SUMMARY", g_iRoundDmg[id], g_iRoundKills[id], g_iRoundInf[id], g_iRoundXP[id], g_iRoundAP[id]);
        new t = g_iTheme[id];
        HudText(id, SL_PERS, THEME_C[t][0], THEME_C[t][1], THEME_C[t][2], 4.0, txt);
    }
}

// Harita sonu: haritanin en iyileri odullendirilir
public task_MapEndAwards()
{
    // v3.0 (C): RTV + son round ayni anda olursa oduller bir kez verilir
    if (g_bMapAwards)
        return;
    g_bMapAwards = true;
    new topK, topI, topB, vK, vI, vB;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_bot(id))
            continue;
        if (g_iMapKills[id] > vK)    { vK = g_iMapKills[id];    topK = id; }
        if (g_iMapInf[id] > vI)      { vI = g_iMapInf[id];      topI = id; }
        if (g_iMapBossDmg[id] > vB)  { vB = g_iMapBossDmg[id];  topB = id; }
    }

    HudAll(SL_ANN, CLR_REWARD, 5.0, "MAPEND_HUD");
    PlayKey(0, "MAP_END");
    PlayVoxAll("VOX_MAPEND");
    ChatAll("MAPEND_TITLE");

    new name[32];
    if (topK)
    {
        get_user_name(topK, name, charsmax(name));
        g_iVC[topK] += 5;
        MapAwardLine("MAPEND_KILLS", topK, name, vK);
    }
    if (topI)
    {
        get_user_name(topI, name, charsmax(name));
        g_iVC[topI] += 5;
        MapAwardLine("MAPEND_INF", topI, name, vI);
    }
    if (topB)
    {
        get_user_name(topB, name, charsmax(name));
        g_iVC[topB] += 5;
        MapAwardLine("MAPEND_BOSS", topB, name, vB);
    }
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id))
            SaveData(id);
    }
}

MapAwardLine(const key[], who, const name[], val)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p))
            client_print_color(p, who, "%s %L", ChatTag(key), p, key, name, val);
    }
}

/* ---------------- Kazanma kontrolu ---------------- */

CheckWin()
{
    if (!g_bRoundActive || g_bRoundEnded)
        return;

    new humans = CountHumans(true);
    new zombies = CountZombies(true);

    if (humans == 0)
    {
        EndRound(WINSTATUS_TERRORISTS);
        return;
    }

    // Ayni anda tum zombiler olduyse insanlar kazanir (geri donus bekleyen olsa bile)
    if (zombies == 0)
    {
        EndRound(WINSTATUS_CTS);
        return;
    }

    if (RoundTimeLeft() <= 0)
        EndRound(WINSTATUS_CTS);
}

EndRound(WinStatus:status)
{
    if (g_bRoundEnded)
        return;

    OnRoundEnd(status);

    // Skor tablosu takim skorlari (harita oylamasi eklentileri de bunu kullanir)
    if (status == WINSTATUS_CTS)
        rg_update_teamscores(1, 0, true);
    else if (status == WINSTATUS_TERRORISTS)
        rg_update_teamscores(0, 1, true);

    rg_round_end(5.0, status, status == WINSTATUS_CTS ? ROUND_CTS_WIN : ROUND_TERRORISTS_WIN, "", "", true);
}

RoundTimeLeft()
{
    new Float:start = Float:get_member_game(m_fRoundStartTime);
    new total = get_member_game(m_iRoundTimeSecs);
    return floatround(float(total) - (get_gametime() - start), floatround_ceil);
}

// VIP'ler daha hizli geri doner
Float:RespawnDelay(id)
{
    new Float:d = get_pcvar_float(g_pRespawn);
    if (IsElite(id))
        d -= 2.0;
    else if (IsVip(id))
        d -= 1.0;
    return floatmax(1.0, d);
}

bool:AllowsInfection()
{
    return (g_iMode == MODE_INFECTION || g_iMode == MODE_MULTI) ? true : false;
}

bool:AllowsRespawn()
{
    if (g_bRespawnOff)
        return false;
    return (g_iMode == MODE_INFECTION || g_iMode == MODE_MULTI) ? true : false;
}

CountPlaying()
{
    new n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
            continue;
        new TeamName:t = get_member(id, m_iTeam);
        if (t == TEAM_TERRORIST || t == TEAM_CT)
            n++;
    }
    return n;
}

CountHumans(bool:alive)
{
    new n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (alive ? is_user_alive(id) : is_user_connected(id))
        {
            if (!g_bZombie[id])
                n++;
        }
    }
    return n;
}

CountZombies(bool:alive)
{
    new n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (alive ? is_user_alive(id) : is_user_connected(id))
        {
            if (g_bZombie[id])
                n++;
        }
    }
    return n;
}

GetHumans(players[32])
{
    new n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_alive(id) && !g_bZombie[id])
            players[n++] = id;
    }
    return n;
}


/* ================================================================== */
/*  TICK (1 sn)                                                        */
/* ================================================================== */

public task_Tick()
{
    g_iFrame++;

    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id) && !is_user_bot(id))
            g_iPlaySec[id]++;
    }

    if (g_bCounting)
    {
        if (g_iCountdown > 0)
        {
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_connected(p) || is_user_bot(p))
                    continue;
                if (g_iCountdown <= 5)
                    set_dhudmessage(CLR_DANGER, -1.0, Y_COUNT, 0, 0.0, 1.0, 0.0, 0.0);
                else
                    set_dhudmessage(THEME_A[g_iTheme[p]][0], THEME_A[g_iTheme[p]][1], THEME_A[g_iTheme[p]][2], -1.0, Y_COUNT, 0, 0.0, 1.0, 0.0, 0.0);
                show_dhudmessage(p, "%L", p, "COUNTDOWN", g_iCountdown);
            }
            if (g_iCountdown <= 10)
            {
                if (g_bVoxCountdown)
                {
                    new snd[32];
                    formatex(snd, charsmax(snd), "vox/%s.wav", VOX_NUM[g_iCountdown]);
                    for (new p = 1; p <= g_iMax; p++)
                    {
                        if (is_user_connected(p) && !(g_iSet[p] & SET_NO_AMB))
                            client_cmd(p, "spk ^"%s^"", snd);
                    }
                }
                else
                    PlayKey(0, "COUNTDOWN_BEEP");
            }
            g_iCountdown--;
        }
        else
        {
            g_bCounting = false;
            StartMode();
        }
    }

    // Oyuncu bekleme durumu: ikinci oyuncu gelince round yeniden baslar
    if (g_bWaiting)
    {
        if (CountPlaying() >= 2)
        {
            g_bWaiting = false;
            ChatAll("GAME_COMMENCING");
            // Haritanin basinda round sayaci 1'den baslasin (30 roundluk plan)
            if (g_iRound <= 1)
                set_member_game(m_bCompleteReset, true);
            rg_round_end(3.0, WINSTATUS_DRAW, ROUND_GAME_COMMENCE, "", "", false);
        }
        else if (g_iFrame % 3 == 0)
            ShowWaiting();
    }

    if ((g_bRoundActive || g_bCounting) && g_fEclipseEnd <= get_gametime()
        && (g_iEvent == EV_BLOODMOON || g_iEvent == EV_NIGHT || g_iMode == MODE_BOSS || g_iMode == MODE_ASSASSIN)
        && random_num(1, 9) == 1)
        Lightning();

    DrawHud();
    TickAfk();
    TickLotto();
    TickVip();
    TickCosmetics();
    TickMineHints();

    // Canli sunucu yorumlari (~2 dakikada bir)
    if (g_iFrame % 130 == 65)
        LiveChatter();
    TickFlares();

    // Bilgilendirme mesajlari
    if (g_iFrame % 80 == 0)
    {
        new k[10];
        formatex(k, charsmax(k), "ADV_%d", random_num(1, NUM_ADS));
        for (new p = 1; p <= g_iMax; p++)
        {
            if (is_user_connected(p) && !(g_iSet[p] & SET_NO_ADS))
                Chat(p, k);
        }
    }

    if (!g_bRoundActive)
        return;

    if (g_iFrame % 25 == 0 && random_num(1, 3) == 1)
    {
        for (new p = 1; p <= g_iMax; p++)
        {
            if (is_user_connected(p) && !(g_iSet[p] & SET_NO_AMB))
                PlayKey(p, "AMBIENT");
        }
    }

    TickAutoVote();
    MapVoteTick();

    // Son saniye uyarilari
    new tl = RoundTimeLeft();
    if (tl == 30)
        LiveAll(0, "LIVE_30S", 3);
    else if (tl == 10)
        HudAll(SL_ALERT, CLR_WARN, 2.0, "HUD_10S");

    TickPlayers();
    TickBoss();
    TickMeteor();
    TickEvents();
    TickAirdrop();
    TickPools();
    TickRespawns();
    CheckWin();
}

ShowWaiting()
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        set_dhudmessage(CLR_WARN, -1.0, Y_COUNT, 0, 0.0, 3.0, 0.0, 0.0);
        show_dhudmessage(p, "%L", p, "WAITING_PLAYERS", CountPlaying());
    }
}

Lightning()
{
    engfunc(EngFunc_LightStyle, 0, "z");
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p))
            continue;
        if (!(g_iSet[p] & SET_NO_FX))
            FadeOne(p, 255, 255, 255, 110, 0.25);
        if (!(g_iSet[p] & SET_NO_AMB))
            PlayKey(p, "LIGHTNING");
    }
    remove_task(TASK_LIGHT);
    set_task(0.2, "task_LightRestore", TASK_LIGHT);
}

public task_LightRestore()
{
    engfunc(EngFunc_LightStyle, 0, (g_fEclipseEnd > get_gametime()) ? "a" : g_szLight);
}

TickRespawns()
{
    new Float:now = get_gametime();

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_alive(id))
            continue;

        new TeamName:t = get_member(id, m_iTeam);
        if (t != TEAM_TERRORIST && t != TEAM_CT)
            continue;

        // Gec katilanlar / olen zombiler: respawn izni olan modlarda zombi olarak doner
        if (g_fRespawnAt[id] == 0.0)
        {
            if (AllowsRespawn() && RoundTimeLeft() > 20)
                g_fRespawnAt[id] = now + RespawnDelay(id);
            continue;
        }

        if (now >= g_fRespawnAt[id])
        {
            g_fRespawnAt[id] = 0.0;
            if (!AllowsRespawn())
                continue;

            g_bFirst[id] = 0;
            g_bForceZombie[id] = 1;
            rg_set_user_team(id, TEAM_TERRORIST, MODEL_UNASSIGNED, true, false);
            rg_round_respawn(id);
        }
        else if (!is_user_bot(id))
        {
            set_hudmessage(CLR_WARN, -1.0, Y_COUNT + 0.05, 0, 0.0, 1.1, 0.0, 0.0, 4);
            show_hudmessage(id, "%L", id, "RESPAWN_IN", floatround(g_fRespawnAt[id] - now, floatround_ceil));
        }
    }
}

/* ---------------- Meteor ---------------- */

TickMeteor()
{
    if (g_iEvent != EV_METEOR)
        return;

    if (++g_iMeteorTick < 4)
        return;
    g_iMeteorTick = 0;

    new alive[32], n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_alive(id))
            alive[n++] = id;
    }
    if (!n)
        return;

    new Float:o[3];
    get_entvar(alive[random(n)], var_origin, o);
    o[0] += random_float(-120.0, 120.0);
    o[1] += random_float(-120.0, 120.0);

    ZoneSpawn(o, 220.0, 255, 80, 0, 1.5, 0, false);
    FxLight(o, 255, 60, 0, 30, 15, 5);

    new params[4];
    params[0] = _:o[0];
    params[1] = _:o[1];
    params[2] = _:o[2];
    params[3] = 0;
    set_task(1.5, "task_MeteorHit", TASK_METEOR + (g_iFrame % 40), params, 4);
}

public task_MeteorHit(params[], tid)
{
    if (!g_bRoundActive)
        return;

    new Float:o[3], Float:po[3];
    o[0] = Float:params[0];
    o[1] = Float:params[1];
    o[2] = Float:params[2];

    new bool:bossMeteor = (params[3] == 1) ? true : false;

    FxSkyStrike(o, 255, 120, 0);
    FxExplosion(o);
    FxLava(o);
    FxRing(o, 255, 140, 0, 320);
    PlayKey(0, "METEOR");

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id))
            continue;
        if (bossMeteor && g_bZombie[id])
            continue;

        get_entvar(id, var_origin, po);
        if (get_distance_f(o, po) > 220.0)
            continue;

        ShakeOne(id);
        FadeOne(id, 255, 140, 0, 100, 0.8);
        if (bossMeteor)
            ExecuteHamB(Ham_TakeDamage, id, 0, (g_iBoss && is_user_connected(g_iBoss)) ? g_iBoss : 0, 35.0, DMG_BLAST);
        else
            ExecuteHamB(Ham_TakeDamage, id, 0, 0, g_bZombie[id] ? 150.0 : 25.0, DMG_BLAST);
    }
}


/* ================================================================== */
/*  MOD BASLATMA                                                       */
/* ================================================================== */

StartMode()
{
    new players[32];
    new n = GetHumans(players);

    if (n < 2)
    {
        // Takimda olup olu bekleyen oyuncular varsa round'u bozmadan dogur
        if (CountPlaying() > n && g_iStartTries < 3)
        {
            g_iStartTries++;
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_connected(p) || is_user_alive(p))
                    continue;
                new TeamName:t = get_member(p, m_iTeam);
                if (t == TEAM_TERRORIST || t == TEAM_CT)
                {
                    g_bForceZombie[p] = 0;
                    rg_round_respawn(p);
                }
            }
            // Bir saniye sonra tekrar dene
            g_iCountdown = 1;
            g_bCounting = true;
            return;
        }

        // Tek basina: geri sayimi tekrar tekrar baslatma, sakin bekle
        g_bWaiting = true;
        ShowWaiting();
        return;
    }
    g_iStartTries = 0;

    // Haritanin ilk roundu (oyun round'u yeniden baslatmadan basladi): plani simdi kur
    if (!g_bAnnounced)
    {
        remove_task(TASK_ANNOUNCE);
        PickMode();
        PickCalmPreset();
        ApplyWorldEvent();
        ApplyHostname();
        task_Announce();
    }

    // Yeterli oyuncu yoksa normal infection'a dus
    if (n < MODE_MINPL[g_iMode])
        g_iMode = MODE_INFECTION;

    g_bRoundActive = true;

    switch (g_iMode)
    {
        case MODE_INFECTION, MODE_MULTI: StartInfection(players, n);
        case MODE_NEMESIS:    StartNemesis(players, n, false);
        case MODE_ASSASSIN:   StartNemesis(players, n, true);
        case MODE_SURVIVOR:   StartSurvivor(players, n, false);
        case MODE_SNIPER:     StartSurvivor(players, n, true);
        case MODE_SWARM:      StartSwarm(players, n);
        case MODE_PLAGUE:     StartPlague(players, n);
        case MODE_ARMAGEDDON: StartArmageddon(players, n);
        case MODE_BOSS:       StartBoss(players, n);
    }

    if (g_iMode == MODE_ASSASSIN)
    {
        copy(g_szLight, charsmax(g_szLight), "a");
        engfunc(EngFunc_LightStyle, 0, g_szLight);
    }
}

PickRandom(players[32], &n)
{
    new idx = random(n);
    new id = players[idx];
    players[idx] = players[n - 1];
    n--;
    return id;
}

StartInfection(players[32], n)
{
    new count = 1;

    if (g_iMode == MODE_MULTI)
        count = max(2, n / 4);
    else if (g_iEvent == EV_HORDE)
        count = max(2, n / 3);
    else if (g_iEvent == EV_PLAGUE)
        count = max(2, n / 4);
    else if (n >= 12)
        count = 2;

    if (g_iEvent == EV_TITAN)
        count = 1;

    count = min(count, n - 1);

    for (new i = 0; i < count; i++)
    {
        new id = PickRandom(players, n);
        g_bFirst[id] = 1;
        MakeZombie(id);
        Chat(id, "YOU_FIRST_ZOMBIE");
        HudTo(id, SL_PERS, CLR_ZOMBIE, 3.5, "YOU_FIRST_ZOMBIE_HUD");
    }

    new key[20];
    formatex(key, charsmax(key), "MODE_START_%d", g_iMode);
    HudAll(SL_ALERT, CLR_DANGER, 3.0, key);
    PlayKey(0, "ROUND_START");
    PlayVoxAll("VOX_INFECT");
    FadeAll(0, 120, 0, 50, 1.0);
}

StartNemesis(players[32], n, bool:assassin)
{
    new id = PickRandom(players, n);

    if (assassin)
        g_bAssassin[id] = 1;
    else
        g_bNemesis[id] = 1;

    MakeZombie(id);
    AnnounceRole(id, assassin ? "ROLE_ASSASSIN" : "ROLE_NEMESIS");

    new key[20];
    formatex(key, charsmax(key), "MODE_START_%d", g_iMode);
    HudAll(SL_ALERT, CLR_DANGER, 3.5, key);
    PlaySpecialIntro(assassin);
    FadeAll(255, 0, 0, 80, 1.5);
    ShakeAll(8, 1.5, 4);
}

StartSurvivor(players[32], n, bool:sniper)
{
    new id = PickRandom(players, n);
    MakeSurvivor(id, sniper);
    AnnounceRole(id, sniper ? "ROLE_SNIPER" : "ROLE_SURVIVOR");

    for (new i = 0; i < n; i++)
    {
        g_bFirst[players[i]] = 0;
        MakeZombie(players[i]);
    }

    new key[20];
    formatex(key, charsmax(key), "MODE_START_%d", g_iMode);
    HudAll(SL_ALERT, CLR_HUMAN, 3.5, key);
    PlayKey(0, "MODE_START");
    FadeAll(0, 100, 255, 60, 1.5);
}

StartSwarm(players[32], n)
{
    new count = n / 2;
    for (new i = 0; i < count; i++)
    {
        new id = PickRandom(players, n);
        MakeZombie(id);
    }

    HudAll(SL_ALERT, CLR_WARN, 3.0, "MODE_START_6");
    PlayKey(0, "MODE_START");
}

StartPlague(players[32], n)
{
    new surv = PickRandom(players, n);
    MakeSurvivor(surv, false);
    AnnounceRole(surv, "ROLE_SURVIVOR");

    new nem = PickRandom(players, n);
    g_bNemesis[nem] = 1;
    MakeZombie(nem);
    AnnounceRole(nem, "ROLE_NEMESIS");

    new count = n / 2;
    for (new i = 0; i < count; i++)
    {
        new id = PickRandom(players, n);
        MakeZombie(id);
    }

    HudAll(SL_ALERT, CLR_DANGER, 3.5, "MODE_START_7");
    PlayKey(0, "MODE_START");
    FadeAll(150, 0, 255, 60, 1.5);
}

StartArmageddon(players[32], n)
{
    new half = n / 2;
    for (new i = 0; i < half; i++)
    {
        new id = PickRandom(players, n);
        g_bNemesis[id] = 1;
        MakeZombie(id);
    }
    for (new i = 0; i < n; i++)
        MakeSurvivor(players[i], false);

    HudAll(SL_ALERT, CLR_DANGER, 4.0, "MODE_START_8");
    PlaySpecialIntro(false);
    FadeAll(255, 60, 0, 90, 2.0);
}

AnnounceRole(id, const key[])
{
    new name[32], pkey[24];
    get_user_name(id, name, charsmax(name));
    ChatAllS(key, name);

    // Kisiye ozel ipucu
    formatex(pkey, charsmax(pkey), "%s_YOU", key);
    Chat(id, pkey);
    // v3.0: [F] calismazsa yedek tuslar (G / komut)
    if (g_bNemesis[id] || g_bAssassin[id])
        Chat(id, "SKILL_KEYS_HINT");
    HudTo(id, SL_PERS, CLR_WARN, 3.5, pkey);
}


/* ================================================================== */
/*  OYLAMA (mod / event) - canli sayacli menu                          */
/* ================================================================== */

#define VOTE_TIME 15
#define VOTE_OPTS 4

public cmd_vote(id)
{
    if (!(get_user_flags(id) & ADMIN_BAN))
        return PLUGIN_HANDLED;
    StartVote(id, 1);
    return PLUGIN_HANDLED;
}

// type: 1 = sonraki round modu, 2 = sonraki round eventi
StartVote(starter, type)
{
    if (g_iVoteType || g_bMapVoting)
    {
        if (starter)
            Chat(starter, "VOTE_RUNNING");
        return;
    }

    g_iVoteType = type;
    g_iVoteLeft = VOTE_TIME;

    // Rastgele, birbirinden farkli secenekler
    new pool[32], n;
    if (type == 1)
    {
        // Boss sadece plandaki roundlarda gelir
        for (new m = MODE_MULTI; m < MODE_BOSS; m++)
            pool[n++] = m;
    }
    else
    {
        for (new e = 1; e < EV_TOTAL; e++)
            pool[n++] = e;
    }

    for (new i = 0; i < VOTE_OPTS; i++)
    {
        new pick = random(n);
        g_iVoteOpt[i] = pool[pick];
        pool[pick] = pool[n - 1];
        n--;
        g_iVoteCount[i] = 0;
    }

    for (new p = 1; p <= g_iMax; p++)
        g_iVoted[p] = -1;

    new name[32];
    if (starter)
        get_user_name(starter, name, charsmax(name));
    else
        copy(name, charsmax(name), "Vexmira");

    FunAll(starter, type == 1 ? "VOTE_START_MODE" : "VOTE_START_EVENT", name, VOTE_TIME);
    PlayKey(0, "UI_VOTE_START");

    remove_task(TASK_VOTE);
    set_task(1.0, "task_VoteTick", TASK_VOTE, _, _, "a", VOTE_TIME + 1);
    task_VoteTick();
}

public task_VoteTick()
{
    if (!g_iVoteType)
        return;

    if (g_iVoteLeft <= 0)
    {
        FinishVote();
        return;
    }

    // Sadece henuz oy vermemis ve baska menu acmamis oyuncularda yenilenir
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p) || g_iVoted[p] >= 0)
            continue;
        if (VoteMenuOpen(p) || !AnyMenuOpen(p))
            ShowVoteMenu(p);
    }
    g_iVoteLeft--;
}

new g_iVoteMenu[33] = { -1, ... };

// v3.0 (C): ayrilan oyuncunun mod / event oyu duser
VoteDisconnect(id)
{
    if (g_iVoteType && 0 <= g_iVoted[id] < VOTE_OPTS)
        g_iVoteCount[g_iVoted[id]] = max(0, g_iVoteCount[g_iVoted[id]] - 1);
    g_iVoted[id] = -1;
}

bool:VoteMenuOpen(id)
{
    new m, nm, pg;
    player_menu_info(id, m, nm, pg);
    return (nm != -1 && nm == g_iVoteMenu[id]) ? true : false;
}

bool:AnyMenuOpen(id)
{
    new m, nm, pg;
    if (!player_menu_info(id, m, nm, pg))
        return false;
    return (m > 0 || nm != -1) ? true : false;
}

ShowVoteMenu(id)
{
    new title[192], item[96], key[16], nm[40];
    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, g_iVoteType == 1 ? "VOTE_TITLE_MODE" : "VOTE_TITLE_EVENT", id, "VOTE_LEFT", g_iVoteLeft);
    new menu = menu_create(title, "menu_vote_handler");

    for (new i = 0; i < VOTE_OPTS; i++)
    {
        formatex(key, charsmax(key), g_iVoteType == 1 ? "MODE_NAME_%d" : "EV_NAME_%d", g_iVoteOpt[i]);
        formatex(nm, charsmax(nm), "%L", id, key);

        if (g_iVoted[id] == i)
            formatex(item, charsmax(item), "\w%s \r[ \w%d %L\r ] \y<", nm, g_iVoteCount[i], id, "VOTE_VOTES");
        else
            formatex(item, charsmax(item), "%s%s \r[ \w%d %L\r ]", g_iVoted[id] >= 0 ? "\d" : "\y", nm, g_iVoteCount[i], id, "VOTE_VOTES");
        MenuAdd(menu, item, i);
    }

    new note[96];
    formatex(note, charsmax(note), "^n\d%L", id, "VOTE_TIE");
    menu_addtext(menu, note, 0);
    menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
    menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
    g_iVoteMenu[id] = menu;
    menu_display(id, menu, 0, 1);
}

public menu_vote_handler(id, menu, item)
{
    if (item < 0 || !g_iVoteType)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new opt = MenuInfo(menu, item);
    menu_destroy(menu);

    if (g_iVoted[id] >= 0 || opt < 0 || opt >= VOTE_OPTS)
        return PLUGIN_HANDLED;

    g_iVoted[id] = opt;
    g_iVoteCount[opt]++;

    new name[32], key[16];
    get_user_name(id, name, charsmax(name));
    formatex(key, charsmax(key), g_iVoteType == 1 ? "MODE_NAME_%d" : "EV_NAME_%d", g_iVoteOpt[opt]);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        new nm[40];
        formatex(nm, charsmax(nm), "%L", p, key);
        client_print_color(p, id, "%s %L", ChatTag("VOTE_CAST"), p, "VOTE_CAST", name, nm);
    }

    ShowVoteMenu(id);
    return PLUGIN_HANDLED;
}

FinishVote()
{
    new best = -1, bestc = 0, ties[VOTE_OPTS], nt;
    for (new i = 0; i < VOTE_OPTS; i++)
    {
        if (g_iVoteCount[i] > bestc)
        {
            bestc = g_iVoteCount[i];
            nt = 0;
            ties[nt++] = i;
        }
        else if (g_iVoteCount[i] == bestc)
            ties[nt++] = i;
    }
    best = ties[random(nt)];

    new key[16];
    formatex(key, charsmax(key), g_iVoteType == 1 ? "MODE_NAME_%d" : "EV_NAME_%d", g_iVoteOpt[best]);

    if (g_iVoteType == 1)
        g_iForceMode = g_iVoteOpt[best];
    else
        g_iForceEvent = g_iVoteOpt[best];

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        new nm[40];
        formatex(nm, charsmax(nm), "%L", p, key);
        client_print_color(p, print_team_default, "%s %L", ChatTag("VOTE_RESULT"), p, "VOTE_RESULT", nm, bestc);

        HudToS(p, SL_ALERT, CLR_EVENT, 3.5, "VOTE_RESULT_HUD", nm);
        if (VoteMenuOpen(p))
            show_menu(p, 0, "^n", 1);
    }
    PlayKey(0, "UI_VOTE_END");

    g_iVoteType = 0;
    remove_task(TASK_VOTE);
}

// Otomatik oylama: her N roundda bir, roundun ortasinda
TickAutoVote()
{
    new every = get_pcvar_num(g_pVoteEvery);
    if (every <= 0 || g_iVoteType || g_bMapVoting || g_iForceMode >= 0 || g_iRound % every != 0)
        return;

    // Siradaki round boss veya ozel mod roundu ise oylama yapilmaz (plan bozulmasin)
    if (IsBossRound(g_iRound + 1) || RoundInList(g_pSpecialRounds, g_iRound + 1))
        return;

    if (RoundTimeLeft() == 75 && CountPlaying() >= 2)
        StartVote(0, random_num(1, 3) == 1 ? 2 : 1);
}


/* ================================================================== */
/*  BOSS SISTEMI                                                       */
/*  - 9 boss, karisik sira (ayni boss arka arkaya gelmez)              */
/*  - Can oyuncu sayisina gore olceklenir (vex_boss_hp_per_player)     */
/*  - Sinematik giris: ekran kararir, gokten simsekler, boss 2.5 sn    */
/*    yerinde kukrer, buyuk isim yazisi                                */
/*  - 3 faz: %100-60 / %60-30 / %30-0 (DELILIK)                        */
/*  - Her yetenek once uyarilir (renkli alan + yazi): oyuncu kacabilir */
/*  - Her bossun kendi rengi, sesi, pasif aurasi ve 2 ozel yetenegi    */
/*  - Son round (30): FINAL BOSS, daha guclu                           */
/* ================================================================== */

// Bilgi: /round - harita plani
public cmd_roundplan(id)
{
    new list[128];
    get_pcvar_string(g_pBossRounds, list, charsmax(list));
    Chat(id, "PLAN_1", g_iRound, RoundsTotal());
    client_print_color(id, print_team_default, "%s %L", ChatTag("PLAN_2"), id, "PLAN_2", list);
    get_pcvar_string(g_pSpecialRounds, list, charsmax(list));
    client_print_color(id, print_team_default, "%s %L", ChatTag("PLAN_3"), id, "PLAN_3", list);
    // v3.0: bu haritada yuklenen bosslar (precache butcesi)
    list[0] = 0;
    new nm[40], key[16];
    for (new i = 0; i < g_iBossLoadN; i++)
    {
        formatex(key, charsmax(key), "BOSS_NAME_%d", g_iBossLoadList[i]);
        formatex(nm, charsmax(nm), "%s%L", i ? ", " : "", id, key);
        add(list, charsmax(list), nm);
    }
    if (list[0])
        Chat(id, "PLAN_5", list);
    Chat(id, "PLAN_4");
    return PLUGIN_HANDLED;
}


/* ================================================================== */
/*  HAVA IKMALI, ROUND GOREVLERI, ZOMBI EVRIMI, EVENT EFEKTLERI        */
/* ================================================================== */

/* ---------------- Event efektleri ---------------- */

EventStartFx()
{
    switch (g_iEvent)
    {
        case EV_BLOODMOON:
        {
            FadeAll(180, 0, 0, 110, 3.0);
            ShakeAll(6, 2.0, 3);
            PlayKey(0, "BOSS_SCREAM");
        }
        case EV_FOG:        FadeAll(200, 200, 210, 140, 2.0);
        case EV_SPEED:
        {
            FadeAll(0, 200, 255, 90, 1.0);
            PlayKey(0, "SPEED_START");
            PlayVoxAll("VOX_SPEED");
            ChatAll("SPEED_TIP");
        }
        case EV_LOWGRAV:    FadeAll(150, 120, 255, 70, 1.5);
        case EV_DOUBLEDMG, EV_HEADHUNTER: FadeAll(255, 130, 0, 60, 1.0);
        case EV_NIGHT:      FadeAll(0, 0, 0, 200, 2.0);
        case EV_PLAGUE, EV_HORDE: FadeAll(0, 180, 0, 80, 1.5);
        case EV_SUPPLY, EV_GOLDRUSH: FadeAll(255, 215, 0, 60, 1.5);
        case EV_BERSERK, EV_TITAN: FadeAll(255, 60, 0, 70, 1.5);
        case EV_ADRENALINE: FadeAll(0, 255, 140, 60, 1.2);
        case EV_METEOR:     FadeAll(255, 90, 0, 70, 1.5);
        case EV_VAMPIRE:    FadeAll(120, 0, 30, 90, 2.0);
        case EV_STORM:
        {
            Lightning();
            PlayVoxAll("VOX_STORM");
            ChatAll("STORM_TIP");
        }
        case EV_BLACKOUT:
        {
            PlayKey(0, "BLACKOUT");
            PlayVoxAll("VOX_BLACKOUT");
            FadeAll(0, 0, 0, 255, 1.5);
            ChatAll("BLACKOUT_TIP");
        }
    }
}

SpeedRushFx(id)
{
    new Float:o[3];
    get_entvar(id, var_origin, o);
    o[2] -= 30.0;
    FxRingSmall(o, 0, 220, 255);
    FxFollow(id, g_bZombie[id] ? 255 : 0, g_bZombie[id] ? 40 : 220, g_bZombie[id] ? 40 : 255, 6, 4);
    if (!is_user_bot(id) && !(g_iSet[id] & SET_NO_FX))
        FadeOne(id, 0, 200, 255, 60, 0.6);
}

// Her saniye: event'e ozel ortam efektleri
TickEvents()
{
    new Float:o[3];
    switch (g_iEvent)
    {
        case EV_SPEED:
        {
            if (g_iFrame % 6 == 0)
            {
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_AMB))
                        PlayKey(p, "SPEED_WIND");
                }
            }
            // Ayak altinda hiz dalgasi
            if (g_iFrame % 3 == 0)
            {
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p))
                        continue;
                    get_entvar(p, var_origin, o);
                    o[2] -= 30.0;
                    if (g_bZombie[p])
                        FxRingEx(o, 255, 40, 40, 90, 4, 3, 140);
                    else
                        FxRingEx(o, 0, 220, 255, 90, 4, 3, 140);
                }
            }
        }
        case EV_STORM:
        {
            if (g_iFrame % 5 == 0)
                StormStrike();
        }
        case EV_BLACKOUT, EV_NIGHT:
        {
            // Karanlikta zombilerin gozleri parlar
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_alive(p) || !g_bZombie[p] || g_bBoss[p])
                    continue;
                get_entvar(p, var_origin, o);
                o[2] += 26.0;
                FxLight(o, 255, 0, 0, 5, 11, 2);
            }
            if (g_iEvent == EV_BLACKOUT && g_iFrame % 9 == 0 && random_num(0, 1))
            {
                engfunc(EngFunc_LightStyle, 0, "f");
                remove_task(TASK_LIGHT);
                set_task(0.25, "task_LightRestore", TASK_LIGHT);
                PlayKey(0, "BLACKOUT");
            }
        }
        case EV_BLOODMOON:
        {
            if (g_iFrame % 10 == 0)
            {
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_FX))
                        FadeOne(p, 160, 0, 0, 50, 1.5);
                }
            }
        }
        case EV_LOWGRAV:
        {
            if (g_iFrame % 3 == 0)
            {
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p) || (get_entvar(p, var_flags) & FL_ONGROUND))
                        continue;
                    get_entvar(p, var_origin, o);
                    FxImplosion(o, 60, 8, 3);
                }
            }
        }
    }
}

// Firtina: gokten simsek, cogunlukla zombilere
StormStrike()
{
    new list[32], n;
    new bool:zombie = (random_num(1, 100) <= 75) ? true : false;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_alive(p) && (g_bZombie[p] ? true : false) == zombie)
            list[n++] = p;
    }
    if (!n)
        return;

    new target = list[random(n)];
    new Float:o[3], Float:po[3];
    get_entvar(target, var_origin, o);
    o[0] += random_float(-60.0, 60.0);
    o[1] += random_float(-60.0, 60.0);

    FxSkyStrike(o, 200, 220, 255);
    FxSkyStrike(o, 255, 255, 255);
    FxRingEx(o, 200, 220, 255, 220, 16, 5);
    PlayKey(0, "STORM_STRIKE");

    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !(g_iSet[p] & SET_NO_FX))
            FadeOne(p, 255, 255, 255, 50, 0.2);
    }

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p))
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > 160.0)
            continue;
        ShakeEx(p, 10, 1.0, 6);
        if (g_bZombie[p] && !g_bBoss[p])
        {
            g_fSlow[p] = get_gametime() + 1.5;
            rg_reset_maxspeed(p);
            ExecuteHamB(Ham_TakeDamage, p, 0, 0, 120.0, DMG_SHOCK);
        }
        else if (!g_bZombie[p])
            ExecuteHamB(Ham_TakeDamage, p, 0, 0, 10.0, DMG_SHOCK);
    }
}
