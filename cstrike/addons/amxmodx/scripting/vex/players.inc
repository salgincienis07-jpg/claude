/* ================================================================== */
/*  Vexmira Zombie - modul: vex/players.inc  (OYUNCULAR)              */
/*  Baglanti / ayrilma, dil, oyuncu komutlari ve menuleri (ana        */
/*  menu, ayarlar, FPS, meslek), chat (say) isleyici, oyuncu ReAPI    */
/*  hook'lari (dogma, hasar, olum, hiz, ziplama, PreThink), eglence   */
/*  komutlari, canli sunucu sohbeti, AFK.                             */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  INIT                                                               */
/* ================================================================== */

// Chat komutu kaydi: /en ve /tr (ayrica !en, !tr) ayni fonksiyonu calistirir
RegisterSay(const en[], const tr[], const handler[])
{
    new fid = get_func_id(handler);
    if (fid == -1)
    {
        log_amx("[Vexmira] Komut fonksiyonu bulunamadi: %s", handler);
        return;
    }
    TrieSetCell(g_tCmds, en, fid);
    if (tr[0])
        TrieSetCell(g_tCmds, tr, fid);
}

// Tum chat buradan gecer (say / say_team)
public client_command(id)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return PLUGIN_CONTINUE;

    new cmd[12];
    read_argv(0, cmd, charsmax(cmd));

    if (equali(cmd, "say"))
        return SayHandler(id, false);
    if (equali(cmd, "say_team"))
        return SayHandler(id, true);

    return PLUGIN_CONTINUE;
}

// /komut -> kayitli fonksiyonu calistir
bool:RunChatCommand(id, const msg[])
{
    new word[32];
    new i, j;
    for (i = 1; msg[i] && msg[i] != ' ' && j < charsmax(word); i++)
        word[j++] = msg[i];
    word[j] = 0;
    strtolower(word);

    new fid;
    if (!word[0] || !TrieGetCell(g_tCmds, word, fid))
        return false;

    if (callfunc_begin_i(fid) == 1)
    {
        callfunc_push_int(id);
        callfunc_end();
    }
    return true;
}


/* ================================================================== */
/*  BAGLANTI                                                           */
/* ================================================================== */

// Baglanirken herkese "baglaniyor" bilgisi (harita degisiminde toplu giriste susar)
public client_connect(id)
{
    g_bWelcomed[id] = false;
    g_bMotdShown[id] = false;
    HudReset(id);

    if (!get_pcvar_num(g_pJoinMsg) || is_user_bot(id) || is_user_hltv(id))
        return;
    if (get_gametime() - g_fMapStart < 40.0)
        return;

    new name[32], ip[32], country[48];
    get_user_name(id, name, charsmax(name));
    get_user_ip(id, ip, charsmax(ip), 1);
    if (g_bGeoIP)
        geoip_country_ex(ip, country, charsmax(country));

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p) || p == id)
            continue;
        if (country[0])
            client_print_color(p, print_team_default, "%s %L", ChatTag("JOIN_CONNECTING_C"), p, "JOIN_CONNECTING_C", name, country);
        else
            client_print_color(p, print_team_default, "%s %L", ChatTag("JOIN_CONNECTING"), p, "JOIN_CONNECTING", name);
    }
}

public client_putinserver(id)
{
    ResetPlayer(id);
    HudReset(id);

    // Kayit anahtari (SteamID) hazirsa hemen yukle; degilse dogrulamayi bekle.
    // (STEAM_ID_PENDING iken yuklenip sonra kaydedilirse gercek profil ezilirdi.)
    if (is_user_bot(id) || AuthReady(id))
        DoLoad(id);
    else
    {
        ApplyLanguage(id);
        set_task(15.0, "task_LoadFallback", id + TASK_LOADWAIT);
    }

    if (is_user_bot(id))
    {
        g_iPrim[id] = random(5);
        g_iSec[id] = random(3);
        g_iClass[id] = random(NUM_CLASSES);
        g_iClassPicked[id] = 1;
        g_iJob[id] = random(3);
        return;
    }

    // Diger oyunculara giris duyurusu (onlar zaten oyunda, kesin gorurler)
    set_task(2.5, "task_JoinAnnounce", id + TASK_JOIN);
    // Karsilama: oyuncu takim secip dogunca gosterilir (MOTD / takim menusu
    // acikken yazilar kaybolmasin). Takim secmezse 25 sn sonra yine gosterilir.
    set_task(25.0, "task_Welcome", id + TASK_WELCOME2);
}

bool:AuthReady(id)
{
    new auth[35];
    get_user_authid(id, auth, charsmax(auth));
    return (auth[0] && containi(auth, "PENDING") == -1) ? true : false;
}

DoLoad(id)
{
    if (g_bLoaded[id])
        return;

    ComputeKey(id, g_szKey[id], charsmax(g_szKey[]));
    LoadData(id);
    LoadVip(id);
    ApplyLanguage(id);
    g_bLoaded[id] = true;
    RestoreRoundBuys(id);
    RefreshTopRanks();
    SyncMoney(id);
}

public client_authorized(id)
{
    if (is_user_connected(id) && !g_bLoaded[id])
    {
        remove_task(id + TASK_LOADWAIT);
        DoLoad(id);
    }
}

public task_LoadFallback(tid)
{
    new id = tid - TASK_LOADWAIT;
    if (is_user_connected(id) && !g_bLoaded[id])
        DoLoad(id);
}

// Ayni roundda cikip girerek limitli esyalari tekrar alma engeli
StoreRoundBuys(id)
{
    if (!g_bLoaded[id] || !g_szKey[id][0] || !g_bRoundActive)
        return;
    new data[NUM_ITEMS + 1];
    for (new i = 0; i < NUM_ITEMS; i++)
        data[i] = g_iBought[id][i];
    data[NUM_ITEMS] = g_bVipFreeUsed[id];
    TrieSetArray(g_tRoundBuys, g_szKey[id], data, sizeof data);
}

RestoreRoundBuys(id)
{
    new data[NUM_ITEMS + 1];
    if (!g_szKey[id][0] || !TrieGetArray(g_tRoundBuys, g_szKey[id], data, sizeof data))
        return;
    for (new i = 0; i < NUM_ITEMS; i++)
        g_iBought[id][i] = data[i];
    g_bVipFreeUsed[id] = data[NUM_ITEMS];
}

public task_JoinAnnounce(tid)
{
    new id = tid - TASK_JOIN;
    if (!is_user_connected(id))
        return;
    LoadVip(id);
    if (get_pcvar_num(g_pJoinMsg) && get_gametime() - g_fMapStart >= 40.0)
    {
        LiveJoin(id);
        TopJoinAnnounce(id);
        for (new p = 1; p <= g_iMax; p++)
        {
            if (p != id && is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_AMB))
                PlayKey(p, "PLAYER_JOIN");
        }
    }
    VipWelcome(id);
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
    remove_task(id + TASK_LOADWAIT);
    remove_task(id + TASK_WELCOME);
    remove_task(id + TASK_WELCOME2);
    remove_task(id + TASK_PLANT);
    remove_task(id + TASK_MOTD);
    RemovePlayerMines(id, false);
    HudReset(id);
    remove_task(id + TASK_LOADOUT);
    remove_task(id + TASK_JOIN);
    remove_task(id + TASK_SLOT);
    remove_task(id + TASK_VIPMSG);

    // Harita degisiminde (drop = false) herkes icin "ayrildi" yazilmaz
    if (drop && is_user_connected(id) && get_pcvar_num(g_pJoinMsg))
        LiveLeave(id);

    // Donen slot makinesinin bahsi iade; harita degisiminde piyango biletleri de iade
    if (g_bSlotting[id])
        g_iAP[id] += g_iSlotBet[id];
    if (!drop && g_iTickets[id] > 0)
        g_iAP[id] += g_iTickets[id] * 10;

    // Normal cikista piyango bileti iptal olur, ikramiye potta kalir
    g_iBounty[id] = 0;
    g_iTickets[id] = 0;
    g_bSlotting[id] = 0;

    StoreRoundBuys(id);
    SaveData(id);

    new bool:wasZombie = g_bZombie[id] ? true : false;

    if (g_bBoss[id])
        g_iBoss = 0;

    // v3.0 (C): mod/event + harita oyu / RTV duser (esik yeniden kontrol edilir)
    VoteDisconnect(id);
    MapVoteDisconnect(id);
    ResetPlayer(id);
    RtvCheck(id);

    // Son zombi cikarsa yerine yeni zombi sec
    if (g_bRoundActive && !g_bRoundEnded && wasZombie && AllowsInfection())
    {
        // Hemen yerine koy: aksi halde saniyelik kontrol insanlara bedava galibiyet verir
        if (CountZombies(true) == 0)
            task_ReplaceZombie();
    }
}

public task_ReplaceZombie()
{
    if (!g_bRoundActive || g_bRoundEnded || CountZombies(true) > 0)
        return;

    new players[32];
    new n = GetHumans(players);
    if (n < 2)
        return;

    new pick = players[random(n)];
    g_bFirst[pick] = 1;
    MakeZombie(pick);
    ChatAll("ZOMBIE_REPLACED");
}

ResetPlayer(id)
{
    g_bZombie[id] = 0; g_bNemesis[id] = 0; g_bAssassin[id] = 0; g_bSurvivor[id] = 0; g_bSniper[id] = 0;
    g_bBoss[id] = 0; g_bMinion[id] = 0; g_bFirst[id] = 0; g_bForceZombie[id] = 0;
    g_iClass[id] = 0; g_iClassPicked[id] = 0; g_iMaxHP[id] = 100;

    g_iXP[id] = 0; g_iLevel[id] = 1; g_iAP[id] = 0; g_iVC[id] = 0;
    g_iKills[id] = 0; g_iInfects[id] = 0; g_iWins[id] = 0; g_iBossK[id] = 0; g_iHS[id] = 0;
    g_iAch[id] = 0; g_iTitle[id] = 0; g_iJob[id] = 0; g_iStyle[id] = 0; g_iSet[id] = 0;
    g_iTheme[id] = 0; g_iLang[id] = 0; g_iDailyDay[id] = 0; g_iDailyStreak[id] = 0;
    g_iPrim[id] = -1; g_iSec[id] = -1; g_iPlaySec[id] = 0;
    g_iHudPos[id] = 0;
    g_iVip[id] = 0; g_iVipExpire[id] = 0; g_iVipAura[id] = 0; g_bVipTrail[id] = 0;
    g_iMapKills[id] = 0; g_iLastSeen[id] = 0; g_bNewPlayer[id] = 1; g_iBounty[id] = 0; g_iTickets[id] = 0;
    g_bSlotting[id] = 0; g_fFunCd[id] = 0.0; g_fGiftCd[id] = 0.0; g_fPlayerReplyCd[id] = 0.0;
    g_iMapInf[id] = 0; g_iMapBossDmg[id] = 0; g_bMineHint[id] = false; g_iBossDmg[id] = 0;
    g_iNadeMode[id][0] = 0; g_iNadeMode[id][1] = 0; g_iNadeMode[id][2] = 0;
    g_iQuest[id] = -1; g_bAlpha[id] = false; g_iMines[id] = 0;
    g_iCosOwned[id] = 0; g_iTrailSel[id] = 0; g_iKfxSel[id] = 0; g_iIfxSel[id] = 0;
    g_szKey[id][0] = 0; g_bLoaded[id] = false; g_iClassNext[id] = -1; g_iJobNext[id] = -1;
    g_bTrailOn[id] = false;
    g_bLmGiven[id] = false;
    g_iAfkSec[id] = 0;
    g_fNextBeat[id] = 0.0;
    for (new i = 0; i < NUM_PERKS; i++)
        g_iPerk[id][i] = 0;
    // v3.0: insan modeli oyuncu basina sabit (listeden rastgele); MVP ikonu el degistirir
    g_iHumanSkin[id] = g_iHumanModelN > 0 ? random(g_iHumanModelN) : 0;
    if (g_iRoundMvp == id)
        g_iRoundMvp = 0;
    // v3.0 (C): efekt zamanlayicilari + slotu devralan oyuncuya kalmamasi gereken durumlar
    g_fFxHitT[id] = 0.0;
    g_fFxHealT[id] = 0.0;
    ResetPlayerLate(id);

    ResetRoundData(id);
    ResetLifeData(id);
}

ResetRoundData(id)
{
    g_iRoundDmg[id] = 0; g_iRoundInf[id] = 0; g_iRoundAP[id] = 0; g_iRoundXP[id] = 0;
    g_iRoundKills[id] = 0; g_iRoundHS[id] = 0; g_bQuestDone[id] = false; g_bAlpha[id] = false;
    g_iMines[id] = 0; g_iPlantAction[id] = 0;
    g_bVipFreeUsed[id] = 0;
    for (new i = 0; i < NUM_ITEMS; i++)
        g_iBought[id][i] = 0;
}

ResetLifeData(id)
{
    g_iExtraJumps[id] = 0; g_iJumps[id] = 0; g_bBoots[id] = 0; g_bSerum[id] = 0; g_bRage[id] = 0;
    g_bUnlClip[id] = 0; g_bDmgAmp[id] = 0; g_bZArmor[id] = 0;
    g_fHBoost[id] = 0.0; g_iEShield[id] = 0; g_bZRegen[id] = 0; g_bNoKB[id] = 0;
    g_iFireNades[id] = 0; g_iFrostNades[id] = 0; g_iFlares[id] = 0; g_iInfNades[id] = 0; g_iSpecW[id] = 0;
    g_iBurn[id] = 0; g_iBurnBy[id] = 0; g_iPoison[id] = 0; g_iPoisonBy[id] = 0;
    g_fFrozen[id] = 0.0; g_fSlow[id] = 0.0; g_fMadness[id] = 0.0;
    g_fCool[id] = 0.0; g_fShield[id] = 0.0; g_fBurst[id] = 0.0; g_fCloak[id] = 0.0;
    g_iStreak[id] = 0; g_iMulti[id] = 0; g_fLastKill[id] = 0.0;
    g_fRage[id] = 0.0; g_fFCool[id] = 0.0;
    // v3.0: sinif yetenekleri (varliklar + kurban durumlari)
    ZcCleanup(id);
    g_fLeapCool[id] = 0.0;
    g_fSkillTrig[id][0] = 0.0; g_fSkillTrig[id][1] = 0.0; g_fSkillTrig[id][2] = 0.0;
    // v3.0 (B): kafa ustu gostergeler + boss / ozel karakter ses sayaclari
    OvhRemove(id);
    VoiceReset(id);
}

public task_Welcome(tid)
{
    new id = (tid >= TASK_WELCOME2) ? tid - TASK_WELCOME2 : tid - TASK_WELCOME;
    if (!is_user_connected(id) || is_user_bot(id) || g_bWelcomed[id])
        return;

    g_bWelcomed[id] = true;
    remove_task(id + TASK_WELCOME2);

    new name[32];
    get_user_name(id, name, charsmax(name));

    new t = g_iTheme[id];
    HudToS(id, SL_ANN, THEME_A[t][0], THEME_A[t][1], THEME_A[t][2], 6.0, "WELCOME_HUD", name);
    HudTo(id, SL_PERS, THEME_C[t][0], THEME_C[t][1], THEME_C[t][2], 6.0, "WELCOME_HUD2");
    PlayKey(id, "WELCOME");
    FadeOne(id, THEME_A[t][0], THEME_A[t][1], THEME_A[t][2], 60, 1.2);

    Chat(id, "WELCOME", name);
    Chat(id, "WELCOME_2");
    Chat(id, "WELCOME_3");
    Chat(id, "WELCOME_4");
    if (get_pcvar_num(g_pLmEnable))
        Chat(id, "LM_BIND_HINT");
    SendFogForEvent(id);

    if (g_iDailyDay[id] < get_systime() / 86400)
        set_task(3.0, "task_DailyHint", id + TASK_WELCOME);
}

public task_DailyHint(tid)
{
    new id = tid - TASK_WELCOME;
    if (is_user_connected(id))
        Chat(id, "DAILY_READY");
}

/* ---------------- Ozel karsilama penceresi (MOTD) ---------------- */

public msg_Motd(msgid, dest, id)
{
    if (!get_pcvar_num(g_pMotd))
        return PLUGIN_CONTINUE;

    if (1 <= id <= g_iMax && !g_bMotdShown[id])
    {
        g_bMotdShown[id] = true;
        set_task(0.3, "task_ShowMotd", id + TASK_MOTD);
    }
    return PLUGIN_HANDLED;
}

public task_ShowMotd(tid)
{
    new id = tid - TASK_MOTD;
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    new file[128];
    get_configsdir(file, charsmax(file));
    format(file, charsmax(file), "%s/vexmira_motd_%s.html", file, g_iLang[id] == 2 ? "tr" : "en");
    if (!file_exists(file))
    {
        get_configsdir(file, charsmax(file));
        add(file, charsmax(file), "/vexmira_motd_en.html");
        if (!file_exists(file))
            return;
    }
    show_motd(id, file, "VEXMIRA | Zombie Plague");
}


/* ================================================================== */
/*  DIL                                                                */
/* ================================================================== */

ApplyLanguage(id)
{
    // Kayitli dil yoksa: GeoIP ile ulke tespiti, yoksa oyuncu ayari
    if (!g_iLang[id])
    {
        new cur[8];
        get_user_info(id, "lang", cur, charsmax(cur));

        if (equali(cur, "tr"))
            g_iLang[id] = 2;
        else if (g_bGeoIP && !is_user_bot(id))
        {
            new ip[32], code[3];
            get_user_ip(id, ip, charsmax(ip), 1);
            if (geoip_code2_ex(ip, code) && (equali(code, "TR") || equali(code, "AZ") || equali(code, "CY")))
                g_iLang[id] = 2;
            else
                g_iLang[id] = 1;
        }
        else
            g_iLang[id] = 1;
    }

    if (!is_user_bot(id))
        set_user_info(id, "lang", g_iLang[id] == 2 ? "tr" : "en");
}

// Oyuncu bilgisi degisince (isim degisimi vb.) secilen dili koru
public client_infochanged(id)
{
    if (!is_user_connected(id) || is_user_bot(id) || !g_iLang[id])
        return;

    new cur[8];
    get_user_info(id, "lang", cur, charsmax(cur));
    if (!equali(cur, g_iLang[id] == 2 ? "tr" : "en"))
        set_user_info(id, "lang", g_iLang[id] == 2 ? "tr" : "en");
}

SetLanguage(id, lang)
{
    g_iLang[id] = lang;
    set_user_info(id, "lang", lang == 2 ? "tr" : "en");
    SaveData(id);
    Chat(id, "LANG_CHANGED");
}


/* ================================================================== */
/*  KOMUTLAR                                                           */
/* ================================================================== */

public cmd_menu(id)
{
    new TeamName:t = get_member(id, m_iTeam);
    if (t != TEAM_TERRORIST && t != TEAM_CT)
        return PLUGIN_CONTINUE;

    ShowMainMenu(id);
    return PLUGIN_HANDLED;
}

// N tusu: gece gorusu varsa acilsin, yoksa menu
public cmd_nvg(id)
{
    // v3.0: Volt EMP / Kabus sirasinda gece gorusu acilamaz
    if (is_user_alive(id) && !g_bZombie[id] && g_fNoLight[id] > get_gametime() && get_member(id, m_bHasNightVision))
    {
        LightsBlockedMsg(id);
        return PLUGIN_HANDLED;
    }
    if (is_user_alive(id) && get_member(id, m_bHasNightVision))
        return PLUGIN_CONTINUE;
    return cmd_menu(id);
}

public cmd_shop(id)     { ShowShopMenu(id);     return PLUGIN_HANDLED; }
public cmd_special(id)  { ShowSpecialMenu(id);  return PLUGIN_HANDLED; }
public cmd_class(id)    { ShowClassMenu(id);    return PLUGIN_HANDLED; }
public cmd_job(id)      { ShowJobMenu(id);      return PLUGIN_HANDLED; }
public cmd_perks(id)    { ShowPerkMenu(id);     return PLUGIN_HANDLED; }
public cmd_daily(id)    { ClaimDaily(id);       return PLUGIN_HANDLED; }
public cmd_title(id)    { ShowTitleMenu(id);    return PLUGIN_HANDLED; }
public cmd_ach(id)      { ShowAchMenu(id);      return PLUGIN_HANDLED; }
public cmd_stats(id)    { ShowStats(id); ShowCard(id, id); return PLUGIN_HANDLED; }
public cmd_top(id)      { ShowTop(id);          return PLUGIN_HANDLED; }
public cmd_style(id)    { ShowStyleMenu(id);    return PLUGIN_HANDLED; }
public cmd_settings(id) { ShowSettingsMenu(id); return PLUGIN_HANDLED; }
public cmd_fps(id)      { ShowFpsMenu(id);      return PLUGIN_HANDLED; }
public cmd_modes(id)    { ShowModesInfo(id);    return PLUGIN_HANDLED; }

public cmd_guns(id)
{
    if (!is_user_alive(id) || g_bZombie[id])
    {
        g_iPrim[id] = -1;
        g_iSec[id] = -1;
        Chat(id, "GUNS_RESET");
        return PLUGIN_HANDLED;
    }
    ShowPrimaryMenu(id);
    return PLUGIN_HANDLED;
}

public cmd_lang(id)
{
    SetLanguage(id, g_iLang[id] == 2 ? 1 : 2);
    return PLUGIN_HANDLED;
}

public cmd_help(id)
{
    for (new i = 1; i <= 6; i++)
    {
        new key[12];
        formatex(key, charsmax(key), "HELP_%d", i);
        Chat(id, key);
    }
    return PLUGIN_HANDLED;
}

ShowModesInfo(id)
{
    new key[16];
    for (new m = 0; m < MODE_TOTAL; m++)
    {
        formatex(key, charsmax(key), "MODE_DESC_%d", m);
        Chat(id, key);
    }
}

public cmd_unstuck(id)
{
    if (!is_user_alive(id))
        return PLUGIN_HANDLED;

    new Float:now = get_gametime();
    if (now < g_fUnstuck[id])
    {
        Chat(id, "UNSTUCK_WAIT", floatround(g_fUnstuck[id] - now, floatround_ceil));
        return PLUGIN_HANDLED;
    }
    g_fUnstuck[id] = now + 8.0;

    if (!IsStuck(id))
    {
        Chat(id, "UNSTUCK_NOT");
        return PLUGIN_HANDLED;
    }

    new Float:o[3], Float:t[3];
    get_entvar(id, var_origin, o);

    static const Float:OFFS[][3] =
    {
        {0.0, 0.0, 36.0}, {32.0, 0.0, 0.0}, {-32.0, 0.0, 0.0}, {0.0, 32.0, 0.0}, {0.0, -32.0, 0.0},
        {32.0, 32.0, 18.0}, {-32.0, -32.0, 18.0}, {32.0, -32.0, 18.0}, {-32.0, 32.0, 18.0},
        {0.0, 0.0, 72.0}, {64.0, 0.0, 0.0}, {-64.0, 0.0, 0.0}, {0.0, 64.0, 0.0}, {0.0, -64.0, 0.0}
    };

    for (new i = 0; i < sizeof OFFS; i++)
    {
        t[0] = o[0] + OFFS[i][0];
        t[1] = o[1] + OFFS[i][1];
        t[2] = o[2] + OFFS[i][2];

        if (IsHullFree(id, t))
        {
            engfunc(EngFunc_SetOrigin, id, t);
            Chat(id, "UNSTUCK_OK");
            return PLUGIN_HANDLED;
        }
    }

    Chat(id, "UNSTUCK_FAIL");
    return PLUGIN_HANDLED;
}

bool:IsStuck(id)
{
    new Float:o[3];
    get_entvar(id, var_origin, o);
    return !IsHullFree(id, o);
}

bool:IsHullFree(id, const Float:o[3])
{
    new hull = (get_entvar(id, var_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN;
    engfunc(EngFunc_TraceHull, o, o, 0, hull, id, 0);
    return !(get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen)) ? true : false;
}


/* ================================================================== */
/*  CHAT: TAG / STIL                                                   */
/* ================================================================== */

SayHandler(id, bool:teamOnly)
{
    new msg[160];
    read_args(msg, charsmax(msg));
    remove_quotes(msg);
    trim(msg);

    if (!msg[0] || msg[0] == '@')
        return PLUGIN_CONTINUE;

    // Vexmira komutlari: /menu, /zar, /slot 50, /hediye isim 20 ...
    if (msg[0] == '/' || msg[0] == '!')
    {
        if (HandleArgCommand(id, msg) || RunChatCommand(id, msg))
            return PLUGIN_HANDLED;
        return PLUGIN_CONTINUE;   // baska plugin'lerin komutlari (/rank, /top15 ...)
    }

    // v3.0 (C): harita oylamasi acikken "rtv" / "nextmap" / "maps" kelimeleri bu eklentide
    // (mesaj normal sohbette de gorunur, cevap ardindan gelir)
    new mapWord;
    if (MapVoteOn())
    {
        if (equali(msg, "rtv") || equali(msg, "rockthevote"))
            mapWord = 1;
        else if (equali(msg, "nextmap"))
            mapWord = 2;
        else if (equali(msg, "maps"))
            mapWord = 3;
    }

    // Diger plugin'lerin bilinen kelime komutlari (oylama vb.) dokunulmadan gecsin
    static const PASS[][] = { "rtv", "rockthevote", "nominate", "nextmap", "timeleft", "thetime", "currentmap", "ff", "motd" };
    for (new i = 0; i < sizeof PASS && !mapWord; i++)
    {
        if (equali(msg, PASS[i]) || (containi(msg, PASS[i]) == 0 && msg[strlen(PASS[i])] == ' '))
            return PLUGIN_CONTINUE;
    }

    // Basit flood korumasi
    new Float:now = get_gametime();
    if (now - g_fLastSay[id] < 0.7)
        return PLUGIN_HANDLED;
    g_fLastSay[id] = now;

    new name[32], staff[16], tname[32], pre[24], role[16];
    get_user_name(id, name, charsmax(name));
    GetStaffTag(id, staff, charsmax(staff));

    new bool:alive = is_user_alive(id) ? true : false;
    new TeamName:myTeam = get_member(id, m_iTeam);
    new flags = get_user_flags(id);

    // Yazi rengi rutbeye gore: yonetici YESIL, VIP/ELITE takim rengi, diger beyaz
    new bc[3];
    if (flags & (ADMIN_RCON | ADMIN_BAN))
        copy(bc, charsmax(bc), "^4");
    else if (IsVip(id))
        copy(bc, charsmax(bc), "^3");
    else
        copy(bc, charsmax(bc), "^1");

    // Neon: ^3 rengi rutbeye gore (kirmizi owner, mavi admin, VIP takim rengi, gri diger)
    new sender = id;
    if (g_iStyle[id] == 1)
    {
        if (flags & ADMIN_RCON)
            sender = print_team_red;
        else if (flags & ADMIN_BAN)
            sender = print_team_blue;
        else if (!IsVip(id))
            sender = print_team_grey;
    }

    for (new t = 1; t <= g_iMax; t++)
    {
        if (!is_user_connected(t))
            continue;
        if (!alive && is_user_alive(t))
            continue;
        if (teamOnly && get_member(t, m_iTeam) != myTeam)
            continue;

        formatex(pre, charsmax(pre), "%s%s",
            teamOnly ? "(Team) " : "",
            alive ? "" : "*DEAD* ");

        TitleName(id, t, tname, charsmax(tname));
        RoleTag(id, t, role, charsmax(role));

        switch (g_iStyle[id])
        {
            case 0: client_print_color(t, sender, "^1%s^4%s^1[^4Lv.%d^1 %s]%s ^3%s^1 : %s%s", pre, staff, g_iLevel[id], tname, role, name, bc, msg);
            case 1: client_print_color(t, sender, "^1%s^3%s^4<%d|%s>%s ^3%s^4 : %s%s", pre, staff, g_iLevel[id], tname, role, name, bc, msg);
            default: client_print_color(t, sender, "^1%s^4%s^3%s^1 : %s%s", pre, staff, name, bc, msg);
        }
    }

    LiveReply(id, msg);
    switch (mapWord)
    {
        case 1: cmd_rtv(id);
        case 2: cmd_nextmap(id);
        case 3: cmd_maps(id);
    }
    return PLUGIN_HANDLED;
}

GetStaffTag(id, tag[], len)
{
    new flags = get_user_flags(id);

    if (flags & ADMIN_RCON)
        copy(tag, len, "[OWNER] ");
    else if (flags & ADMIN_BAN)
        copy(tag, len, IsVip(id) ? "[ADMIN+VIP] " : "[ADMIN] ");
    else if (IsElite(id))
        copy(tag, len, "[ELITE] ");
    else if (IsVip(id))
        copy(tag, len, "[VIP] ");
    else
        tag[0] = 0;
}

RoleTag(id, viewer, out[], len)
{
    out[0] = 0;
    if (!is_user_alive(id))
        return;

    if (g_bBoss[id])           formatex(out, len, " ^3[BOSS]^1");
    else if (g_bNemesis[id])   formatex(out, len, " ^3[NEMESIS]^1");
    else if (g_bAssassin[id])  formatex(out, len, " ^3[ASSASSIN]^1");
    else if (g_bSurvivor[id])  formatex(out, len, " ^4[SURVIVOR]^1");
    else if (g_bSniper[id])    formatex(out, len, " ^4[SNIPER]^1");
    else if (g_bZombie[id])    formatex(out, len, " ^3[%L]^1", viewer, "TAG_ZOMBIE");
}


/* ================================================================== */
/*  TICK (1 sn)                                                        */
/* ================================================================== */

TickPlayers()
{
    new Float:now = get_gametime();
    new Float:o[3];
    new humans, last;

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id))
            continue;

        get_entvar(id, var_origin, o);

        // Ortak: donma / yavaslama / yanma
        if (g_fFrozen[id] > 0.0 && now > g_fFrozen[id])
        {
            g_fFrozen[id] = 0.0;
            ApplyRender(id);
            rg_reset_maxspeed(id);
        }
        if (g_fSlow[id] > 0.0 && now > g_fSlow[id])
        {
            g_fSlow[id] = 0.0;
            rg_reset_maxspeed(id);
        }
        if (g_iBurn[id] > 0)
        {
            g_iBurn[id]--;
            FxLight(o, 255, 120, 0, 20, 8, 10);
            FxSprite(o, g_sprExplode, 3, 200);
            new attacker = g_iBurnBy[id];
            if (!is_user_connected(attacker))
                attacker = 0;
            ExecuteHamB(Ham_TakeDamage, id, 0, attacker, get_pcvar_float(g_bZombie[id] ? g_pZombieBurnDmg : g_pBurnDmg), DMG_BURN);
            if (!is_user_alive(id))
                continue;
        }
        // Zehir (Kovan Kralicesi): yesil duman + saniyede hasar
        if (g_iPoison[id] > 0)
        {
            g_iPoison[id]--;
            FxSprite(o, g_sprSmoke, 6, 120);
            if (!(g_iSet[id] & SET_NO_FX))
                FadeOne(id, 110, 255, 0, 50, 0.6);
            new pz = g_iPoisonBy[id];
            if (!is_user_connected(pz))
                pz = 0;
            ExecuteHamB(Ham_TakeDamage, id, 0, pz, 6.0, DMG_POISON);
            if (!is_user_alive(id))
                continue;
        }

        // Hiz Tutkusu: genis gorus acisi (silah degisince oyun 90'a cektigi icin her saniye).
        // Durbunlu silahlarda uygulanmaz: oyun bu silahlarin isabetini gorus acisina gore hesaplar.
        if (g_iEvent == EV_SPEED && !is_user_bot(id) && get_member(id, m_iFOV) == 90)
        {
            new WeaponIdType:aw = GetActiveWeaponId(id);
            if (aw != WEAPON_AWP && aw != WEAPON_SCOUT && aw != WEAPON_G3SG1 && aw != WEAPON_SG550 && aw != WEAPON_AUG && aw != WEAPON_SG552 && aw != WEAPON_FAMAS)
            {
                new fov = clamp(get_pcvar_num(g_pSpeedFov), 90, 120);
                set_member(id, m_iFOV, fov);
                set_entvar(id, var_fov, float(fov));
            }
        }

        if (g_bZombie[id])
        {
            if (g_iEvent == EV_SPEED && g_iFrame % 2 == 1)
                FxFollow(id, 255, 40, 40, 6, 5);

            if (g_fBurst[id] > 0.0 && now > g_fBurst[id])
            {
                g_fBurst[id] = 0.0;
                rg_reset_maxspeed(id);
            }
            if ((g_fShield[id] > 0.0 && now > g_fShield[id]) || (g_fCloak[id] > 0.0 && now > g_fCloak[id])
                || (g_fMadness[id] > 0.0 && now > g_fMadness[id]))
            {
                if (now > g_fShield[id]) g_fShield[id] = 0.0;
                if (now > g_fCloak[id]) g_fCloak[id] = 0.0;
                if (now > g_fMadness[id]) g_fMadness[id] = 0.0;
                ApplyRender(id);
            }
            // Ara sira hirlama sesi (kiliktaki Taklitci / yeraltindaki Kostebek sessiz)
            if (!g_bBoss[id] && g_fDisguise[id] <= now && g_fBurrow[id] <= now && random_num(1, 15) == 1)
                EmitZombieSound(id, "IDLE", "ZOMBIE_IDLE");

            if (g_bZRegen[id])
                HealTo(id, max(1, ITEM_VAL[IT_ZREGEN]), g_iMaxHP[id]);
            if (g_iEvent == EV_BERSERK && !g_bBoss[id])
                HealTo(id, 40, g_iMaxHP[id]);

            if (g_bBoss[id] || g_bNemesis[id])
                FxLight(o, 255, 20, 20, 30, 11, 5);
            else if (g_bAssassin[id])
                FxLight(o, 90, 0, 140, 18, 11, 5);
            else if (g_fCloak[id] <= 0.0 && g_fDisguise[id] <= now && g_fBurrow[id] <= now)
            {
                new c = g_bMinion[id] ? 0 : g_iClass[id];
                FxLight(o, CLASS_RGB[c][0], CLASS_RGB[c][1], CLASS_RGB[c][2], 14, 11, 5);
            }
        }
        else
        {
            humans++;
            last = id;

            if (g_iEvent == EV_ADRENALINE)
                HealTo(id, 3, MaxHumanHP(id));
            if (g_iJob[id] == JOB_MEDIC && !g_bSurvivor[id] && !g_bSniper[id])
                HealTo(id, 2, MaxHumanHP(id));

            // Doctor: yakindaki takim arkadaslarini iyilestirir
            if (g_iJob[id] == JOB_DOCTOR)
                DoctorAura(id, o);

            if (g_fCloak[id] > 0.0 && now > g_fCloak[id])
            {
                g_fCloak[id] = 0.0;
                ApplyRender(id);
            }
            if (g_fHBoost[id] > 0.0 && now > g_fHBoost[id])
            {
                g_fHBoost[id] = 0.0;
                rg_reset_maxspeed(id);
            }

            // Gunner: her 10 sn yedek mermi doldurur
            if (g_iJob[id] == JOB_GUNNER && g_iFrame % 10 == 0)
                RefillAmmo(id);

            if (g_bSurvivor[id] || g_bSniper[id])
                FxLight(o, 0, 120, 255, 20, 11, 5);

            if (g_iEvent == EV_SPEED && g_iFrame % 2 == 0)
                FxFollow(id, 0, 220, 255, 6, 4);

            if (get_entvar(id, var_health) < 30.0 && !is_user_bot(id))
            {
                // Kalp atisi: tek seferlik ses, bitmeden tekrar calinmaz (ust uste binmez)
                if (now >= g_fNextBeat[id])
                {
                    PlayKey(id, "HEARTBEAT");
                    g_fNextBeat[id] = now + 1.1;
                }
                if (!(g_iSet[id] & SET_NO_FX))
                    FadeOne(id, 255, 0, 0, 45, 0.9);
            }
        }
    }

    if (humans == 1 && !g_bLastAnn && AllowsInfection())
    {
        g_bLastAnn = true;
        new name[32];
        get_user_name(last, name, charsmax(name));
        HudAll(SL_ALERT, CLR_WARN, 3.0, "LAST_HUMAN");
        ChatAllS("LAST_HUMAN_CHAT", name);
        PlayKey(0, "LAST_HUMAN");
        PlayVoxAll("VOX_LAST");
        set_user_rendering(last, kRenderFxGlowShell, 255, 215, 0, kRenderNormal, 15);
        rg_set_user_armor(last, 200, ARMOR_VESTHELM);
        set_entvar(last, var_health, Float:get_entvar(last, var_health) + get_pcvar_float(g_pLastHumanHP));
    }
}

RefillAmmo(id)
{
    for (new i = 0; i < sizeof PRIM_ENT; i++)
    {
        new WeaponIdType:w = WeaponIdType:rg_get_weapon_info(PRIM_ENT[i], WI_ID);
        if (rg_find_weapon_bpack_by_name(id, PRIM_ENT[i]))
            rg_set_user_bpammo(id, w, max(rg_get_user_bpammo(id, w), PRIM_AMMO[i]));
    }
    for (new i = 0; i < sizeof SEC_ENT; i++)
    {
        new WeaponIdType:w = WeaponIdType:rg_get_weapon_info(SEC_ENT[i], WI_ID);
        if (rg_find_weapon_bpack_by_name(id, SEC_ENT[i]))
            rg_set_user_bpammo(id, w, max(rg_get_user_bpammo(id, w), SEC_AMMO[i]));
    }
}

HealTo(id, amount, maxhp)
{
    new Float:hp = Float:get_entvar(id, var_health);
    if (hp < float(maxhp))
    {
        set_entvar(id, var_health, floatmin(float(maxhp), hp + float(amount)));
        // v3.0 (C): iyilesme sprite'i (kucuk / surekli iyilesmelerde 1 sn'de bir)
        if (amount >= 5)
            FxHeal(id);
    }
}

DoctorAura(id, const Float:o[3])
{
    new Float:po[3];
    for (new p = 1; p <= g_iMax; p++)
    {
        if (p == id || !is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) <= 300.0)
            HealTo(p, 3, MaxHumanHP(p));
    }
}

MaxHumanHP(id)
{
    new hp = max(1, get_pcvar_num(g_pHumanHP)) + 10 * g_iPerk[id][PK_VITALITY];
    if (g_iJob[id] == JOB_GUARDIAN)
        hp += 50;
    else if (g_iJob[id] == JOB_JUGGERNAUT)
        hp += 100;
    if (g_bSurvivor[id] || g_bSniper[id])
        hp = g_iMaxHP[id];
    return hp;
}


/* ================================================================== */
/*  ZOMBI / INSAN DONUSUMLERI                                          */
/* ================================================================== */

SendDeathMsg(killer, victim, const weapon[])
{
    message_begin(MSG_BROADCAST, g_msgDeath);
    write_byte(killer);
    write_byte(victim);
    write_byte(0);
    write_string(weapon);
    message_end();
}

UpdateScore(id)
{
    message_begin(MSG_BROADCAST, g_msgScore);
    write_byte(id);
    write_short(floatround(Float:get_entvar(id, var_frags)));
    write_short(get_member(id, m_iDeaths));
    write_short(0);
    write_short(_:get_member(id, m_iTeam));
    message_end();
}


/* ================================================================== */
/*  OYUNCU HOOK'LARI (ReAPI)                                           */
/* ================================================================== */

public rg_PlayerSpawn(id)
{
    if (!is_user_alive(id))
        return;

    g_fRespawnAt[id] = 0.0;
    ResetLifeData(id);

    // Zombi olarak yeniden dogma (respawn / boss minion)
    if (g_bForceZombie[id])
    {
        g_bForceZombie[id] = 0;
        g_bBoss[id] = 0;
        MakeZombie(id);

        if (g_bMinion[id] && g_iBoss && is_user_alive(g_iBoss))
        {
            new Float:o[3];
            get_entvar(g_iBoss, var_origin, o);
            o[0] += random_float(-90.0, 90.0);
            o[1] += random_float(-90.0, 90.0);
            o[2] += 40.0;
            if (IsHullFree(id, o))
                engfunc(EngFunc_SetOrigin, id, o);
        }
        else
        {
            // Respawn korumasi: 2 sn
            g_fMadness[id] = get_gametime() + 2.0;
            ApplyRender(id);
        }
        return;
    }

    g_bZombie[id] = 0; g_bNemesis[id] = 0; g_bAssassin[id] = 0; g_bSurvivor[id] = 0; g_bSniper[id] = 0;
    g_bBoss[id] = 0; g_bMinion[id] = 0; g_bFirst[id] = 0;
    g_bGunsGiven[id] = false;
    g_bNadesGiven[id] = false;

    // Bekleyen meslek secimi yeni doguste uygulanir
    if (g_iJobNext[id] >= 0)
    {
        g_iJob[id] = g_iJobNext[id];
        g_iJobNext[id] = -1;
    }

    if (get_member(id, m_iTeam) != TEAM_CT)
        rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED, true, false);

    rg_set_user_footsteps(id, g_iJob[id] == JOB_NINJA ? true : false);
    ApplyHumanModel(id);
    set_user_rendering(id);

    new hp = MaxHumanHP(id);
    g_iMaxHP[id] = hp;
    set_entvar(id, var_health, float(hp));
    set_entvar(id, var_max_health, float(hp));
    ApplyHumanGravity(id);

    // Zirh: perk + meslek + VIP
    new armor = 15 * g_iPerk[id][PK_PLATING];
    if (g_iJob[id] == JOB_HEAVY) armor += 100;
    if (g_iJob[id] == JOB_ELITE) armor += 25;
    if (IsElite(id)) armor += 100;
    else if (IsVip(id)) armor += 50;
    if (armor > 0)
        rg_set_user_armor(id, min(armor, 250), ARMOR_VESTHELM);

    // VIP: aura + hosgeldin ipucu
    if (IsVip(id))
        ApplyRender(id);

    SyncMoney(id);

    // Round basi lazer hakki (vex_lm_per_round; boss roundunda yok)
    GiveRoundMines(id);

    remove_task(id + TASK_LOADOUT);
    set_task(0.3, "task_Loadout", id + TASK_LOADOUT);

    // Karsilama: ilk dogusta (MOTD / takim menusu kapandiktan sonra)
    if (!g_bWelcomed[id] && !is_user_bot(id))
    {
        remove_task(id + TASK_WELCOME);
        set_task(1.5, "task_Welcome", id + TASK_WELCOME);
    }
}

public task_Loadout(tid)
{
    new id = tid - TASK_LOADOUT;
    if (!is_user_alive(id) || g_bZombie[id] || g_bSurvivor[id] || g_bSniper[id])
        return;

    if (g_iPrim[id] >= 0 && g_iSec[id] >= 0 && !(g_iSet[id] & SET_NO_AUTOGUN))
        GiveLoadout(id);
    else if (!is_user_bot(id))
        ShowPrimaryMenu(id);
    else
        GiveLoadout(id);

    // Bombalar silah seciminden bagimsiz: herkes her round tum bombalari alir
    GiveStartNades(id);
}

public rg_TakeDamage(victim, inflictor, attacker, Float:damage, bits)
{
    if (!is_user_connected(victim))
        return HC_CONTINUE;

    // Enfeksiyon baslamadan hasar yok
    if (!g_bRoundActive)
    {
        SetHookChainReturn(ATYPE_INTEGER, 0);
        return HC_SUPERCEDE;
    }

    new Float:now = get_gametime();
    new Float:dmg = damage;
    new bool:isPlayer = (1 <= attacker <= g_iMax && attacker != victim && is_user_connected(attacker)) ? true : false;
    g_iReflVictim = 0;

    // Madness / respawn korumasi
    if (g_bZombie[victim] && g_fMadness[victim] > now)
    {
        SetHookChainReturn(ATYPE_INTEGER, 0);
        return HC_SUPERCEDE;
    }

    // v3.0: Kostebek yeraltindayken hasar almaz ve veremez
    if ((g_bZombie[victim] && g_fBurrow[victim] > now) || (isPlayer && g_bZombie[attacker] && g_fBurrow[attacker] > now))
    {
        SetHookChainReturn(ATYPE_INTEGER, 0);
        return HC_SUPERCEDE;
    }
    // v3.0: Magma zombisine ates / yanma islemez
    if ((bits & DMG_BURN) && IsClassZombie(victim, ZC_MAGMA) && get_pcvar_num(g_pZc[ZCV_MAG_IMMUNE]))
    {
        if (isPlayer && !is_user_bot(attacker) && random_num(1, 4) == 1)
            SkillDeny(attacker, "MAGMA_IMMUNE");
        SetHookChainReturn(ATYPE_INTEGER, 0);
        return HC_SUPERCEDE;
    }

    if (isPlayer)
    {
        // ---------------- Zombi -> Insan ----------------
        if (g_bZombie[attacker] && !g_bZombie[victim])
        {
            if (inflictor != attacker)
                return HC_CONTINUE;
            // v3.0 (C): pence izi (zirh / kalkan / enfeksiyon dahil her isabet)
            FxClawHit(victim);

            // v3.0 Taklitci: kiliktayken ilk vurus x2 hasar ve kilik acilir
            new Float:mimicMult = 1.0;
            if (g_fDisguise[attacker] > now)
            {
                mimicMult = floatclamp(get_pcvar_float(g_pZc[ZCV_MIM_MULT]), 1.0, 10.0);
                MimicReveal(attacker, victim);
            }

            if (g_bBoss[attacker])
            {
                dmg = get_pcvar_float(g_pBossDmg);
                if (g_bEnraged)
                    dmg *= 1.25;
                if (g_bFinalBoss)
                    dmg *= 1.15;
                // Reaper Golge Adimi: sonraki vurus x2
                if (g_fBossEmpower > now)
                {
                    dmg *= 2.0;
                    g_fBossEmpower = 0.0;
                    ApplyRender(attacker);
                    new Float:vo[3];
                    get_entvar(victim, var_origin, vo);
                    FxImplosion(vo, 100, 30, 4);
                    FxSprite(vo, g_sprExplode, 5, 200);
                }
            }
            else if (g_bNemesis[attacker] || g_bAssassin[attacker])
            {
                // v2.0: Nemesis ve Assassin insanlari TEK VURUSTA indirir
                // (vex_nemesis_oneshot / vex_assassin_oneshot). Survivor / Sniper'a ayri hasar.
                new bool:nem = g_bNemesis[attacker] ? true : false;
                if (g_bSurvivor[victim] || g_bSniper[victim])
                    dmg = get_pcvar_float(g_pNemVsSurv);
                else if (get_pcvar_num(nem ? g_pNemOneShot : g_pAsnOneShot))
                    dmg = 999999.0;
                else
                    dmg = get_pcvar_float(nem ? g_pNemDmg : g_pAsnDmg);
                if (g_fRage[attacker] > now && dmg < 9000.0)
                    dmg *= 1.3;
            }
            else if (g_bMinion[attacker])
                dmg = get_pcvar_float(g_pMinionDmg);
            else if (g_bSurvivor[victim] || g_bSniper[victim])
                dmg = 30.0 * mimicMult;
            else if (AllowsInfection())
            {
                dmg *= mimicMult;
                // Enerji kalkani bir darbeyi tamamen engeller
                if (g_iEShield[victim] > 0)
                {
                    g_iEShield[victim]--;
                    if (!g_iEShield[victim])
                        ApplyRender(victim);
                    Chat(victim, "ESHIELD_HIT", g_iEShield[victim]);
                    FadeOne(victim, 0, 255, 255, 80, 0.4);
                    SetHookChainReturn(ATYPE_INTEGER, 0);
                    return HC_SUPERCEDE;
                }

                // Lucky: %7 sansla darbeden kacar
                if (g_iJob[victim] == JOB_LUCKY && random_num(1, 100) <= 7)
                {
                    Chat(victim, "LUCKY_DODGE");
                    SetHookChainReturn(ATYPE_INTEGER, 0);
                    return HC_SUPERCEDE;
                }

                // Zirh once delinir
                new ArmorType:atype;
                new armor = rg_get_user_armor(victim, atype);
                if (get_pcvar_num(g_pArmorProtect) && armor > 0)
                {
                    rg_set_user_armor(victim, max(0, armor - floatround(dmg)), atype);
                    if (!(g_iSet[victim] & SET_NO_FX))
                        FadeOne(victim, 255, 120, 0, 60, 0.3);
                    SetHookChainReturn(ATYPE_INTEGER, 0);
                    return HC_SUPERCEDE;
                }

                if (CountHumans(true) > 1)
                {
                    Infect(victim, attacker);
                    SetHookChainReturn(ATYPE_INTEGER, 0);
                    return HC_SUPERCEDE;
                }
                dmg = 9999.0; // son insan: oldurulur
            }
            else
                dmg = get_pcvar_float(g_pZombieDmg) * mimicMult;

            if (g_bRage[attacker] && dmg < 9000.0)
                dmg *= 1.0 + float(max(0, ITEM_VAL[IT_RAGE])) / 100.0;
            if (g_bAlpha[attacker] && dmg < 9000.0)
                dmg *= 1.2;
        }
        // ---------------- Insan -> Zombi ----------------
        else if (!g_bZombie[attacker] && g_bZombie[victim])
        {
            new Float:m = 1.0;
            new WeaponIdType:wid = GetActiveWeaponId(attacker);
            new bool:bulletHit = (inflictor == attacker && (bits & DMG_BULLET)) ? true : false;
            new bool:headshot = (bulletHit && get_member(victim, m_LastHitGroup) == HIT_HEAD) ? true : false;

            if (g_bSniper[attacker] && wid == WEAPON_AWP && bulletHit)
                dmg = 5000.0;
            if (g_bSurvivor[attacker])
                m *= 1.5;

            if (g_iEvent == EV_DOUBLEDMG)
                m *= 2.0;
            if (g_iEvent == EV_HEADHUNTER && headshot)
                m *= 2.0;

            m += 0.03 * float(g_iPerk[attacker][PK_FIREPOWER]);

            switch (g_iJob[attacker])
            {
                case JOB_MARKSMAN: m *= 1.2;
                case JOB_SNIPER: if (headshot) m *= 1.5;
                case JOB_DEMO: if (bits & DMG_GRENADE) m *= 1.5;
                case JOB_BERSERKER: if (Float:get_entvar(attacker, var_health) < 40.0) m *= 1.4;
            }

            if (HasCommanderNear(attacker))
                m *= 1.1;
            if (g_iJob[attacker] == JOB_ELITE)
                m *= 1.1;
            if (g_bDmgAmp[attacker])
                m *= 1.0 + float(max(0, ITEM_VAL[IT_DMGAMP])) / 100.0;

            new sw = SpecialIndex(attacker, wid);
            if (sw >= 0 && inflictor == attacker)
                m *= SW_MULT[sw];

            dmg *= m;

            if (g_bBoss[victim] || g_bNemesis[victim] || g_bAssassin[victim])
                dmg = floatmin(dmg, 3000.0);
        }
    }

    // Savunma
    if (g_bZombie[victim])
    {
        if (g_fShield[victim] > now)
            dmg *= 0.4;
        if (g_bZArmor[victim])
            dmg *= (100.0 - float(clamp(ITEM_VAL[IT_ZARMOR], 0, 90))) / 100.0;
        if (g_bBoss[victim] && g_fBossBuffEnd > now)
            dmg *= 0.7;
        if (g_bNemesis[victim] && g_fRage[victim] > now)
            dmg *= 0.7;
        // v3.0 Kale: tahkim (hasar azaltma + yansitma; yansima post hook'ta uygulanir)
        if (g_fFortify[victim] > now)
        {
            dmg *= (100.0 - floatclamp(get_pcvar_float(g_pZc[ZCV_BUL_REDUCE]), 0.0, 95.0)) / 100.0;
            if (isPlayer && !g_bZombie[attacker] && !g_bReflecting && dmg > 0.0)
            {
                g_iReflVictim = victim;
                g_iReflAttacker = attacker;
                g_fReflAmount = floatmin(dmg * floatclamp(get_pcvar_float(g_pZc[ZCV_BUL_REFLECT]), 0.0, 100.0) / 100.0, 60.0);
            }
        }
    }
    else if (dmg < 9000.0)
    {
        if (g_iJob[victim] == JOB_HEAVY && !g_bSurvivor[victim])
            dmg *= 0.85;
    }

    // AP birikimi (verilen hasar)
    if (isPlayer && !g_bZombie[attacker] && g_bZombie[victim])
    {
        new idmg = floatround(floatmin(dmg, Float:get_entvar(victim, var_health)));
        g_iRoundDmg[attacker] += idmg;
        if (g_bBoss[victim])
        {
            g_iBossDmg[attacker] += idmg;
            g_iMapBossDmg[attacker] += idmg;
        }
        g_iDmgBank[attacker] += idmg;
        QuestEvent(attacker, 1, idmg);

        new per = max(50, get_pcvar_num(g_pDmgPerAP));
        if (g_iDmgBank[attacker] >= per)
        {
            new gained = g_iDmgBank[attacker] / per;
            g_iDmgBank[attacker] %= per;
            AddAP(attacker, gained);
        }
    }

    if (dmg != damage)
        SetHookChainArg(4, ATYPE_FLOAT, dmg);

    return HC_CONTINUE;
}

public rg_TakeDamagePost(victim, inflictor, attacker, Float:damage, bits)
{
    // v3.0 Kale yansitmasi (oldurmez: insan en az 1 canda kalir)
    if (g_iReflVictim && g_iReflVictim == victim && g_iReflAttacker == attacker)
    {
        new Float:refl = g_fReflAmount;
        g_iReflVictim = 0;
        g_iReflAttacker = 0;
        g_fReflAmount = 0.0;
        if (is_user_alive(attacker) && !g_bZombie[attacker] && !g_bReflecting)
        {
            refl = floatmin(refl, Float:get_entvar(attacker, var_health) - 1.0);
            if (refl >= 1.0)
            {
                g_bReflecting = true;
                ExecuteHamB(Ham_TakeDamage, attacker, 0, is_user_connected(victim) ? victim : 0, refl, DMG_GENERIC);
                g_bReflecting = false;
                if (random_num(1, 3) == 1)
                {
                    new Float:ao[3];
                    get_entvar(attacker, var_origin, ao);
                    FxSparks(ao);
                }
                if (!is_user_bot(attacker))
                    FadeOne(attacker, 130, 150, 130, 50, 0.2);
            }
        }
    }

    if (!(1 <= attacker <= g_iMax) || attacker == victim || !is_user_connected(attacker))
        return;
    if (g_bZombie[attacker] || !g_bZombie[victim] || damage <= 0.0)
        return;

    new WeaponIdType:wid = GetActiveWeaponId(attacker);
    new bool:bullet = (inflictor == attacker && (bits & DMG_BULLET)) ? true : false;
    new bool:headshot = (bullet && get_member(victim, m_LastHitGroup) == HIT_HEAD) ? true : false;

    // Hasar gostergesi
    if (!is_user_bot(attacker) && !(g_iSet[attacker] & SET_NO_DMGNUM))
    {
        new Float:x = 0.52 + random_float(-0.02, 0.04);
        new Float:y = 0.45 + random_float(-0.02, 0.04);
        if (headshot)
        {
            set_hudmessage(255, 200, 40, x, y, 0, 0.0, 0.5, 0.0, 0.15, 4);
            show_hudmessage(attacker, "%d  HS", floatround(damage));
        }
        else if (g_bBoss[victim])
        {
            set_hudmessage(BOSS_RGB[g_iBossType][0], BOSS_RGB[g_iBossType][1], BOSS_RGB[g_iBossType][2], x, y, 0, 0.0, 0.45, 0.0, 0.15, 4);
            show_hudmessage(attacker, "-%d", floatround(damage));
        }
        else if (g_iEvent == EV_DOUBLEDMG)
        {
            set_hudmessage(255, 120, 0, x, y, 0, 0.0, 0.45, 0.0, 0.15, 4);
            show_hudmessage(attacker, "%d  x2", floatround(damage));
        }
        else
        {
            set_hudmessage(120, 220, 255, x, y, 0, 0.0, 0.45, 0.0, 0.15, 4);
            show_hudmessage(attacker, "%d", floatround(damage));
        }
    }

    if (!is_user_alive(victim))
        return;

    // Knockback
    if (bullet && get_pcvar_num(g_pKnockback))
        ApplyKnockback(victim, attacker, wid, damage);

    // Can calma (Vampire meslegi / Vampir Gecesi eventi / Vex Reaper)
    new sw = SpecialIndex(attacker, wid);
    new Float:steal = 0.0;
    if (g_iJob[attacker] == JOB_VAMPIRE)
        steal += 0.05;
    if (g_iEvent == EV_VAMPIRE)
        steal += 0.05;
    if (sw == 6)
        steal += 0.05;
    if (steal > 0.0)
        HealTo(attacker, max(1, floatround(damage * steal)), MaxHumanHP(attacker) + 50);

    if (!bullet)
        return;

    // Pyro / Cryo meslek efektleri
    if (g_iJob[attacker] == JOB_PYRO && random_num(1, 100) <= 15)
        Ignite(victim, attacker, 3);
    if (g_iJob[attacker] == JOB_CRYO && random_num(1, 100) <= 10)
        Freeze(victim, 1.0);

    // Ozel silah efektleri
    switch (sw)
    {
        case 1, 5: if (random_num(1, 100) <= 20) Ignite(victim, attacker, 3);
        case 2: ChainLightning(victim, attacker);
        case 3: if (random_num(1, 100) <= 25) Freeze(victim, 1.5);
    }
}

bool:HasCommanderNear(id)
{
    new Float:o[3], Float:po[3];
    get_entvar(id, var_origin, o);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (p == id || !is_user_alive(p) || g_bZombie[p] || g_iJob[p] != JOB_COMMANDER)
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) <= 400.0)
            return true;
    }
    return false;
}

ApplyKnockback(victim, attacker, WeaponIdType:wid, Float:damage)
{
    if (g_bBoss[victim] || g_bNoKB[victim] || g_fFrozen[victim] > get_gametime())
        return;
    // v3.0: Boga hucumda / Kale tahkimde / Kostebek yeraltinda geri tepmez
    if (g_fCharge[victim] > get_gametime() || g_fFortify[victim] > get_gametime() || g_fBurrow[victim] > get_gametime())
        return;

    new w = _:wid;
    if (w < 0 || w > 30 || KB_POWER[w] <= 0.0)
        return;

    new Float:power = KB_POWER[w];
    if (g_bNemesis[victim] || g_bAssassin[victim])
        power *= 0.25;
    else if (!g_bMinion[victim])
        power *= CLASS_KB[g_iClass[victim]];

    if (g_iJob[attacker] == JOB_TACTICIAN)
        power *= 1.3;

    if (SpecialIndex(attacker, wid) == 7)
        power *= 2.0;

    if (get_entvar(victim, var_flags) & FL_DUCKING)
        power *= 0.5;

    new Float:vo[3], Float:ao[3], Float:dir[3], Float:vel[3];
    get_entvar(victim, var_origin, vo);
    get_entvar(attacker, var_origin, ao);

    dir[0] = vo[0] - ao[0];
    dir[1] = vo[1] - ao[1];
    dir[2] = 0.0;

    new Float:len = floatsqroot(dir[0] * dir[0] + dir[1] * dir[1]);
    if (len < 1.0)
        return;

    new Float:force = floatmin(damage * power * 0.35, 450.0);

    get_entvar(victim, var_velocity, vel);
    vel[0] += dir[0] / len * force;
    vel[1] += dir[1] / len * force;
    set_entvar(victim, var_velocity, vel);
    if (g_iDirLogN[DIR_KNOCK] < DIR_LOG_MAX && get_pcvar_num(g_pDbgDirs))
    {
        // Saldirgandan kurbana (geri itme) ile eklenen hiz ayni yonde olmali
        new Float:add[3];
        add[0] = dir[0] / len * force;
        add[1] = dir[1] / len * force;
        DirCheck(DIR_KNOCK, "knockback", add, dir);
    }
}

// v3.0 (C): patlama hasariyla (DMG_BLAST) olen oyuncuyu oyun m_vBlastVector yonune savurur
// (hiz = v / |v|). Hasar inflictor'suz (0 = worldspawn) ya da ayni noktadan gelirse vektor
// sifir kalir -> NaN hiz ("Got a NaN velocity", silah kutusu da NaN). Sifirsa kucuk bir yon ver.
public rg_PlayerKilledPre(victim, attacker, gib)
{
    if (!is_user_connected(victim))
        return HC_CONTINUE;
    new Float:v[3];
    get_member(victim, m_vBlastVector, v);
    if (v[0] != v[0] || v[1] != v[1] || v[2] != v[2] || vector_length(v) < 1.0)
    {
        new Float:o[3], Float:ao[3];
        get_entvar(victim, var_origin, o);
        if (attacker != victim && attacker > 0 && is_entity(attacker))
        {
            get_entvar(attacker, var_origin, ao);
            v[0] = o[0] - ao[0];
            v[1] = o[1] - ao[1];
            v[2] = 0.0;
        }
        if (vector_length(v) < 1.0)
        {
            new Float:yaw = random_float(0.0, 360.0);
            v[0] = floatcos(yaw, degrees);
            v[1] = floatsin(yaw, degrees);
            v[2] = 0.0;
        }
        new Float:len = vector_length(v);
        v[0] = v[0] / len * 200.0;
        v[1] = v[1] / len * 200.0;
        v[2] = 0.0;
        set_member(victim, m_vBlastVector, v);
    }
    return HC_CONTINUE;
}

public rg_PlayerKilled(victim, attacker, gib)
{
    new bool:valid = (1 <= attacker <= g_iMax && attacker != victim && is_user_connected(attacker)) ? true : false;
    // v3.0: olenin yetenekleri / ustundeki etkiler (kanca, ninni, keseler...) temizlenir
    ZcCleanup(victim);
    OvhRemove(victim);
    // v3.0 (B): boss bir insani oldurdu -> alay sesi
    if (valid && g_bBoss[attacker] && !g_bZombie[victim])
        BossKillTaunt(attacker);
    new Float:o[3];
    get_entvar(victim, var_origin, o);

    if (g_bBoss[victim] || g_bNemesis[victim] || g_bAssassin[victim])
    {
        new name[32];
        if (valid)
            get_user_name(attacker, name, charsmax(name));
        else
            copy(name, charsmax(name), "???");

        FxRing(o, 0, 255, 120, 600);
        FxLight(o, 0, 255, 120, 50, 20, 20);
        FxExplosion(o);

        if (g_bBoss[victim])
            BossDeath(victim, o, name);
        else
        {
            ChatAllS(g_bNemesis[victim] ? "NEMESIS_DOWN" : "ASSASSIN_DOWN", name);
            // Ozel olum sesi (herkes duyar); yoksa genel boss olum sesi
            if (!EmitSpecialSound(victim, "DEATH", CHAN_VOICE, ATTN_NONE))
                PlayKey(0, "BOSS_DEATH");
        }

        if (valid && !g_bZombie[attacker])
        {
            g_iBossK[attacker]++;
            g_iVC[attacker] += g_bBoss[victim] ? get_pcvar_num(g_pBossKillVC) : max(0, get_pcvar_num(g_pBossKillVC) - 1);
            Reward(attacker, get_pcvar_num(g_bBoss[victim] ? g_pBossKillXP : g_pSpecKillXP), get_pcvar_num(g_bBoss[victim] ? g_pBossKillAP : g_pSpecKillAP));
        }
        if (valid && !g_bZombie[attacker])
        {
            for (new p = 1; p <= g_iMax; p++)
            {
                if (is_user_alive(p) && !g_bZombie[p] && p != attacker)
                    Reward(p, 30, 5);
            }
        }
    }
    else if (g_bZombie[victim])
    {
        FxBlood(o, 12);
        FxParticles(o, 40, 70, 6);

        // Bomber: olurken patlar
        if (g_iClass[victim] == 6 && !g_bMinion[victim])
            BomberExplode(victim, o);

        if (valid && !g_bZombie[attacker])
        {
            g_iKills[attacker]++;
            g_iMapKills[attacker]++;
            g_iRoundKills[attacker]++;
            if (g_iJob[attacker] == JOB_HUNTER)
                AddAP(attacker, 2, true, false);
            new kxp = get_pcvar_num(g_pKillXP);
            Reward(attacker, g_bAlpha[victim] ? kxp * 5 / 2 : kxp, get_pcvar_num(g_pKillAP) + (g_bAlpha[victim] ? 4 : 0));
            KillStreak(attacker, victim);
            QuestEvent(attacker, 0, 1);
            CosKillFx(attacker, o);
        }
    }
    else if (valid && g_bZombie[attacker])
    {
        // Zombi insani oldurdu (son insan / nemesis / swarm)
        Reward(attacker, 10, 3);
    }

    if (valid)
        PayBounty(attacker, victim);
    g_iBounty[victim] = 0;

    // Olen insanin lazerleri soner
    if (!g_bZombie[victim])
        RemovePlayerMines(victim, true);

    // Olen zombiye kisisel bilgi
    if (g_bZombie[victim] && g_bRoundActive && AllowsRespawn() && !g_bMinion[victim] && !is_user_bot(victim))
        Chat(victim, "YOU_DIED_ZOMBIE", floatround(RespawnDelay(victim)));

    g_bBoss[victim] = 0;
    KillTrail(victim);
    g_fShield[victim] = 0.0; g_fCloak[victim] = 0.0; g_fMadness[victim] = 0.0;
    g_fFrozen[victim] = 0.0; g_fSlow[victim] = 0.0;
    g_iBurn[victim] = 0;
    g_iStreak[victim] = 0;
    set_user_rendering(victim);

    // Respawn zamanlayicisi (sadece infection modlari)
    if (g_bRoundActive && AllowsRespawn() && !g_bMinion[victim] && RoundTimeLeft() > 20)
        g_fRespawnAt[victim] = get_gametime() + RespawnDelay(victim);
    else
        g_fRespawnAt[victim] = 0.0;

    CheckWin();
}

/* ---------------- Oldurme serisi / headshot / multi-kill ---------------- */

KillStreak(attacker, victim)
{
    if (is_user_bot(attacker))
        return;

    new Float:now = get_gametime();
    new bool:hs = (get_member(victim, m_LastHitGroup) == HIT_HEAD) ? true : false;

    g_iStreak[attacker]++;

    if (now - g_fLastKill[attacker] <= 4.0)
        g_iMulti[attacker]++;
    else
        g_iMulti[attacker] = 1;
    g_fLastKill[attacker] = now;

    new ktxt[96];
    if (hs)
    {
        g_iHS[attacker]++;
        g_iRoundHS[attacker]++;
        QuestEvent(attacker, 2, 1);
        new hsap = get_pcvar_num(g_pHsAP);
        AddAP(attacker, g_iEvent == EV_HEADHUNTER ? hsap * 3 : hsap, true, false);
        formatex(ktxt, charsmax(ktxt), "%L", attacker, "HUD_HEADSHOT");
        if (!(g_iSet[attacker] & SET_NO_STREAK))
            PlayKey(attacker, "HEADSHOT");
    }

    if (g_iMulti[attacker] >= 2)
    {
        new m = min(g_iMulti[attacker], 6);
        new key[16];
        formatex(key, charsmax(key), "MULTI_%d", m);

        if (ktxt[0])
            format(ktxt, charsmax(ktxt), "%s^n%L", ktxt, attacker, key);
        else
            formatex(ktxt, charsmax(ktxt), "%L", attacker, key);

        if (!(g_iSet[attacker] & SET_NO_STREAK))
        {
            switch (m)
            {
                case 2: PlayKey(attacker, "KILL_DOUBLE");
                case 3: PlayKey(attacker, "KILL_TRIPLE");
                case 4: PlayKey(attacker, "KILL_MULTI");
                case 5: PlayKey(attacker, "KILL_MEGA");
                default: PlayKey(attacker, "KILL_MONSTER");
            }
        }
        AddAP(attacker, m - 1, true, false);
    }

    if (ktxt[0])
        HudText(attacker, SL_KILL, CLR_WARN, 1.2, ktxt);

    new s = g_iStreak[attacker];
    if (s == 5 || s == 10 || s == 15 || (s > 15 && s % 5 == 0))
    {
        new name[32], key[16];
        get_user_name(attacker, name, charsmax(name));
        formatex(key, charsmax(key), "STREAK_%d", s >= 15 ? 15 : s);

        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_connected(p))
                continue;
            client_print_color(p, attacker, "%s %L", ChatTag(key), p, key, name, s);
            if (!(g_iSet[p] & SET_NO_STREAK))
                PlayKey(p, s >= 15 ? "STREAK_15" : (s >= 10 ? "STREAK_10" : "STREAK_5"));
        }
        AddAP(attacker, s / 2, true, true);
        g_iVC[attacker] += (s >= 15) ? 1 : 0;
    }
}

/* ---------------- Ozel karakterler kendini olduremez (kill) ---------------- */

public fw_ClientKill(id)
{
    if (is_user_alive(id) && (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id] || g_bSurvivor[id] || g_bSniper[id]))
    {
        Chat(id, "NO_SUICIDE");
        return FMRES_SUPERCEDE;
    }
    return FMRES_IGNORED;
}

/* ---------------- Hiz ---------------- */

public rg_ResetMaxSpeed(id)
{
    if (!is_user_alive(id))
        return;

    new Float:now = get_gametime();

    if (g_fFrozen[id] > now)
    {
        set_entvar(id, var_maxspeed, 1.0);
        return;
    }

    new Float:spd = Float:get_entvar(id, var_maxspeed);

    if (g_bBoss[id] && g_fBossIntro > now)
    {
        set_entvar(id, var_maxspeed, 1.0);
        return;
    }

    if (g_bBoss[id])
    {
        spd = float(BOSS_SPD[g_iBossType]);
        if (g_bEnraged)
            spd *= 1.2;
        if (g_fEclipseEnd > now)
            spd *= 1.15;
        if (g_fBossBuffEnd > now)
            spd *= 1.4;
    }
    else if (g_bNemesis[id])
    {
        spd = get_pcvar_float(g_pNemSpeed);
        if (g_fRage[id] > now)
            spd *= 1.25;
    }
    else if (g_bAssassin[id])
    {
        spd = get_pcvar_float(g_pAsnSpeed);
        if (g_fRage[id] > now)
            spd *= 1.2;
    }
    else if (g_bZombie[id])
    {
        spd = float(CLASS_SPD[g_bMinion[id] ? 0 : g_iClass[id]]) * get_pcvar_float(g_pZSpeed);

        if (g_iEvent == EV_SPEED)
            spd *= get_pcvar_float(g_pSpeedZombie);
        else if (g_iEvent == EV_BERSERK)
            spd *= 1.15;
        if (g_bAlpha[id])
            spd *= 1.08;

        if (g_fBurst[id] > now)
            spd *= 1.3;
        if (g_bRage[id])
            spd *= 1.15;
        // v3.0 sinif yetenekleri
        if (g_fBurrow[id] > now)
            spd *= floatclamp(get_pcvar_float(g_pZc[ZCV_BUR_SPEED]), 0.5, 3.0);
        if (g_fTerror[id] > now)
            spd *= floatclamp(get_pcvar_float(g_pZc[ZCV_NM_SPEED]), 0.5, 3.0);
        if (g_fCharge[id] > now)
            spd = floatmax(spd, get_pcvar_float(g_pZc[ZCV_CHG_SPEED]));
    }
    else
    {
        new Float:m = get_pcvar_float(g_pHSpeed);
        if (g_iEvent == EV_SPEED)       m *= get_pcvar_float(g_pSpeedHuman);
        if (g_fBlizzardEnd > now)       m *= 0.6;
        if (g_iEvent == EV_ADRENALINE)  m *= 1.08;
        if (g_bSerum[id])               m *= 1.0 + float(max(0, ITEM_VAL[IT_SERUM])) / 100.0;
        if (g_iJob[id] == JOB_SCOUT)    m *= 1.12;
        if (g_iJob[id] == JOB_NINJA)    m *= 1.06;
        if (g_iJob[id] == JOB_JUGGERNAUT) m *= 0.95;
        if (g_fHBoost[id] > now)        m *= 1.4;
        m += 0.02 * float(g_iPerk[id][PK_AGILITY]);
        spd *= m;
    }

    if (g_fSlow[id] > now)
        spd *= 0.5;

    set_entvar(id, var_maxspeed, spd);
}

public rg_FallDamage(id)
{
    if (g_bZombie[id] || g_iJob[id] == JOB_PARA || g_bBoots[id])
    {
        SetHookChainReturn(ATYPE_FLOAT, 0.0);
        return HC_SUPERCEDE;
    }
    return HC_CONTINUE;
}

/* ---------------- Zombi sesleri (bicak / aci / olum) ---------------- */

public fw_EmitSound(ent, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
    if (g_bEmitting || !(1 <= ent <= g_iMax) || !g_bZombie[ent] || !is_user_connected(ent))
        return FMRES_IGNORED;

    new ev[12], fallback[20];

    if (equal(sample, "weapons/knife_slash", 19))        { copy(ev, charsmax(ev), "SLASH");   copy(fallback, charsmax(fallback), "ZOMBIE_SLASH"); }
    else if (equal(sample, "weapons/knife_hitwall", 21)) { copy(ev, charsmax(ev), "HITWALL"); copy(fallback, charsmax(fallback), "ZOMBIE_HITWALL"); }
    else if (equal(sample, "weapons/knife_hit", 17))     { copy(ev, charsmax(ev), "HIT");     copy(fallback, charsmax(fallback), "ZOMBIE_HIT"); }
    else if (equal(sample, "weapons/knife_stab", 18))    { copy(ev, charsmax(ev), "STAB");    copy(fallback, charsmax(fallback), "ZOMBIE_STAB"); }
    else if (equal(sample, "player/bhit_flesh", 17) || equal(sample, "player/pl_pain", 14)) { copy(ev, charsmax(ev), "PAIN"); copy(fallback, charsmax(fallback), "ZOMBIE_PAIN"); }
    else if (equal(sample, "player/die", 10) || equal(sample, "player/death", 12))         { copy(ev, charsmax(ev), "DIE");  copy(fallback, charsmax(fallback), "ZOMBIE_DIE"); }
    else
        return FMRES_IGNORED;

    // v3.0 (B): boss / nemesis / assassin: aci (sirayla, bekleme sureli), olum, saldiri kukremesi
    new key[24], path[128];
    if (g_bBoss[ent] || g_bNemesis[ent] || g_bAssassin[ent])
    {
        new r = SpecialVoice(ent, ev);
        if (r != -1)
            return r;
        // Aci: darbe sesi (bhit_flesh) normal calar, insan aci sesi bastirilir
        if (equal(ev, "PAIN"))
            return equal(sample, "player/pl_pain", 14) ? FMRES_SUPERCEDE : FMRES_IGNORED;
    }

    formatex(key, charsmax(key), "Z%d_%s", g_iClass[ent], ev);
    if ((!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
        && (!TrieGetString(g_tRes, fallback, path, charsmax(path)) || !path[0]))
        return FMRES_IGNORED;

    if (containi(path, ".mp3") != -1 || equal(path, sample))
        return FMRES_IGNORED;

    EmitSafe(ent, channel, path, volume, attn, flags, pitch);
    return FMRES_SUPERCEDE;
}

/* ---------------- VIP cift / uclu ziplama ---------------- */

public fw_PreThink(id)
{
    if (!is_user_alive(id))
        return FMRES_IGNORED;

    // v3.0: kanca cekmesi, Boga hucumu, Avci inisi (her kare)
    ZcPreThink(id);
    if (!is_user_alive(id))
        return FMRES_IGNORED;
    // v3.1: parasut vb. disaridan bozulan yercekimi (kapaninca / yere inince) geri yuklenir
    FixGravity(id);

    // Hiz Tutkusu: zipladiktan sonra yavaslama yok (akici kosu)
    if (g_iEvent == EV_SPEED)
        set_entvar(id, var_fuser2, 0.0);

    new maxj = MaxAirJumps(id);
    if (!maxj)
        return FMRES_IGNORED;

    if (get_entvar(id, var_flags) & FL_ONGROUND)
    {
        g_iJumps[id] = maxj;
        return FMRES_IGNORED;
    }

    new btn = get_entvar(id, var_button);
    new old = get_entvar(id, var_oldbuttons);

    if ((btn & IN_JUMP) && !(old & IN_JUMP) && g_iJumps[id] > 0 && g_fFrozen[id] < get_gametime())
    {
        new Float:vel[3];
        g_iJumps[id]--;
        get_entvar(id, var_velocity, vel);
        vel[2] = IsElite(id) ? 300.0 : 285.0;
        set_entvar(id, var_velocity, vel);
        set_entvar(id, var_gaitsequence, 6);

        // Ayak altinda kucuk halka (sadece VIP'lerde, efekt ayari acik olanlara)
        if (IsVip(id))
        {
            new Float:o[3];
            get_entvar(id, var_origin, o);
            o[2] -= 30.0;
            new c = g_iVipAura[id] ? g_iVipAura[id] : 2;
            FxRingSmall(o, VIP_AURA_RGB[c][0], VIP_AURA_RGB[c][1], VIP_AURA_RGB[c][2]);
        }
    }
    return FMRES_IGNORED;
}

// Hiz Tutkusu: yerden ziplayinca kisa ileri atilma
public rg_PlayerJump(id)
{
    if (g_iEvent != EV_SPEED || !is_user_alive(id) || !(get_entvar(id, var_flags) & FL_ONGROUND))
        return HC_CONTINUE;

    new Float:vel[3];
    get_entvar(id, var_velocity, vel);
    new Float:len = floatsqroot(vel[0] * vel[0] + vel[1] * vel[1]);
    new Float:cap = Float:get_entvar(id, var_maxspeed) * 1.25;
    if (len > 50.0 && len < cap)
    {
        new Float:k = floatmin(1.12, cap / len);
        vel[0] *= k;
        vel[1] *= k;
        set_entvar(id, var_velocity, vel);
    }
    return HC_CONTINUE;
}


/* ================================================================== */
/*  MENULER                                                            */
/* ================================================================== */

/* ---------------- Ana menu ---------------- */

// Ana menu sirasi (anahtar MAIN_<no>): market, ozel silah, lazer, bomba modu, silah, sinif...
new const MAIN_ORDER[] = { 1, 2, 18, 19, 3, 4, 5, 6, 20, 8, 21, 9, 7, 10, 22, 11, 12, 13, 14, 15, 16, 17 };

ShowMainMenu(id)
{
    new title[192], item[96], key[12];

    formatex(title, charsmax(title), "\r[\wV E X M I R A\r] \d|| \y%L^n\d%L^n", id, "MENU_MAIN_SUB", id, "MENU_WALLET", g_iAP[id], g_iVC[id], g_iLevel[id]);
    new menu = menu_create(title, "menu_main_handler");
    PlayKey(id, "UI_OPEN");

    new bool:adm = (get_user_flags(id) & ADMIN_BAN) ? true : false;
    for (new k = 0; k < sizeof MAIN_ORDER; k++)
    {
        new i = MAIN_ORDER[k];
        if (i == 17 && !adm)
            continue;

        formatex(key, charsmax(key), "MAIN_%d", i);
        formatex(item, charsmax(item), "\y%L", id, key);

        if (i == 6 && g_iDailyDay[id] < get_systime() / 86400)
            add(item, charsmax(item), " \y(!)");
        if (i == 8)
            add(item, charsmax(item), IsVip(id) ? " \y[*]" : " \r[?]");
        if (i == 18)
        {
            new extra[32];
            formatex(extra, charsmax(extra), LasersAllowed() ? " \r[\w%d\r]" : " \d[-]", g_iMines[id]);
            add(item, charsmax(item), extra);
        }
        if (i == 20 && g_iQuest[id] >= 0 && g_bQuestDone[id])
            add(item, charsmax(item), " \r[\wOK\r]");

        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_main_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new sel = MenuInfo(menu, item);
    menu_destroy(menu);
    PlayKey(id, "UI_MENU_SELECT");

    switch (sel)
    {
        case 1:  ShowShopMenu(id);
        case 2:  ShowSpecialMenu(id);
        case 3:  cmd_guns(id);
        case 4:  ShowClassMenu(id);
        case 5:  ShowJobMenu(id);
        case 6:  ClaimDaily(id);
        case 7:  ShowPerkMenu(id);
        case 8:  cmd_vip(id);
        case 9:  ShowFunMenu(id);
        case 10: ShowProfileMenu(id);
        case 11: ShowSettingsMenu(id);
        case 12: ShowLangMenu(id);
        case 13: cmd_unstuck(id);
        case 14: ShowModesInfo(id);
        case 15: cmd_help(id);
        case 16: ShowTop(id);
        case 17: ShowAdminMenu(id);
        case 18: ShowMineMenu(id);
        case 19: ShowNadeMenu(id);
        case 20: cmd_quest(id);
        case 21: ShowCosmeticMenu(id);
        case 22: ShowTop10(id);
    }
    return PLUGIN_HANDLED;
}

/* ---------------- Profil alt menusu ---------------- */

ShowProfileMenu(id)
{
    new title[96], item[64];
    formatex(title, charsmax(title), "%s \y%L^n", MENU_TAG, id, "MENU_PROFILE");
    new menu = menu_create(title, "menu_profile_handler");

    formatex(item, charsmax(item), "\y%L", id, "PROF_1"); MenuAdd(menu, item, 1);
    formatex(item, charsmax(item), "\y%L", id, "PROF_2"); MenuAdd(menu, item, 2);
    formatex(item, charsmax(item), "\y%L", id, "PROF_3"); MenuAdd(menu, item, 3);
    formatex(item, charsmax(item), "\y%L", id, "PROF_4"); MenuAdd(menu, item, 4);

    MenuFinish(id, menu);
}

public menu_profile_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    switch (sel)
    {
        case 1: ShowCard(id, id);
        case 2: ShowAchMenu(id);
        case 3: ShowTitleMenu(id);
        case 4: ShowStyleMenu(id);
    }
    return PLUGIN_HANDLED;
}

/* ---------------- Meslek ---------------- */

ShowJobMenu(id)
{
    new title[96], item[160], k1[12], k2[16], n1[32], n2[72];

    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MENU_JOB", id, "MENU_JOB_SUB");
    new menu = menu_create(title, "menu_job_handler");

    for (new i = 0; i < NUM_JOBS; i++)
    {
        formatex(k1, charsmax(k1), "JOB_%d", i);
        formatex(k2, charsmax(k2), "JOB_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        if (g_iLevel[id] < JOB_LVL[i])
            formatex(item, charsmax(item), "\d%s \r[\wLv.%d\r]", n1, JOB_LVL[i]);
        else if (g_iJob[id] == i)
            formatex(item, charsmax(item), "\y%s \r[\w*\r] \d%s", n1, n2);
        else
            formatex(item, charsmax(item), "\y%s \d%s", n1, n2);

        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_job_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new job = MenuInfo(menu, item);
    menu_destroy(menu);

    if (g_iLevel[id] < JOB_LVL[job])
    {
        Chat(id, "NEED_LEVEL", JOB_LVL[job]);
        ShowJobMenu(id);
        return PLUGIN_HANDLED;
    }

    ChatKeyName(id, "JOB_CHOSEN", "JOB_", job);

    // Yasayan insan: meslek bir sonraki doguste gecerli (can/zirh suistimali olmasin)
    if (is_user_alive(id) && !g_bZombie[id] && g_iJob[id] != job)
    {
        g_iJobNext[id] = job;
        Chat(id, "JOB_NEXT");
    }
    else
    {
        g_iJob[id] = job;
        g_iJobNext[id] = -1;
    }
    SaveData(id);
    return PLUGIN_HANDLED;
}

/* ---------------- Chat stili ---------------- */

ShowStyleMenu(id)
{
    new title[64], item[160], k1[12], k2[16], n1[32], n2[64];

    formatex(title, charsmax(title), "%s \y%L^n", MENU_TAG, id, "MENU_STYLE");
    new menu = menu_create(title, "menu_style_handler");

    for (new i = 0; i < NUM_STYLES; i++)
    {
        formatex(k1, charsmax(k1), "STYLE_%d", i);
        formatex(k2, charsmax(k2), "STYLE_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        if (g_iStyle[id] == i)
            formatex(item, charsmax(item), "\y%s \r[\w*\r] \d%s", n1, n2);
        else
            formatex(item, charsmax(item), "\y%s \d%s", n1, n2);

        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_style_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    g_iStyle[id] = MenuInfo(menu, item);
    menu_destroy(menu);

    Chat(id, "STYLE_CHOSEN");
    SaveData(id);
    return PLUGIN_HANDLED;
}

/* ---------------- Kisisel ayarlar ---------------- */

ShowSettingsMenu(id)
{
    new title[96], item[96], key[12], onoff[16], tn[24];

    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MENU_SETTINGS", id, "MENU_SETTINGS_SUB");
    new menu = menu_create(title, "menu_settings_handler");

    for (new i = 0; i < 10; i++)
    {
        formatex(key, charsmax(key), "SET_%d", i);
        formatex(onoff, charsmax(onoff), "%L", id, (g_iSet[id] & (1 << i)) ? "OFF" : "ON");
        formatex(item, charsmax(item), "\y%L \r[%s%s\r]", id, key, (g_iSet[id] & (1 << i)) ? "\d" : "\w", onoff);
        MenuAdd(menu, item, i);
    }

    formatex(key, charsmax(key), "THEME_%d", g_iTheme[id]);
    formatex(tn, charsmax(tn), "%L", id, key);
    formatex(item, charsmax(item), "\y%L \r[\w%s\r]", id, "SET_THEME", tn);
    MenuAdd(menu, item, 20);

    formatex(key, charsmax(key), "HUDPOS_%d", g_iHudPos[id]);
    formatex(tn, charsmax(tn), "%L", id, key);
    formatex(item, charsmax(item), "\y%L \r[\w%s\r]", id, "SET_HUDPOS", tn);
    MenuAdd(menu, item, 23);

    formatex(item, charsmax(item), "\y%L \r[\w%s\r]", id, "SET_LANG", g_iLang[id] == 2 ? "Turkce" : "English");
    MenuAdd(menu, item, 21);

    formatex(item, charsmax(item), "\y%L", id, "SET_FPS");
    MenuAdd(menu, item, 22);

    MenuFinish(id, menu);
}

public menu_settings_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    if (sel < 10)
    {
        g_iSet[id] ^= (1 << sel);
        if (sel == 7)
            SendFogForEvent(id);
    }
    else if (sel == 20)
        g_iTheme[id] = (g_iTheme[id] + 1) % NUM_THEMES;
    else if (sel == 23)
        g_iHudPos[id] = (g_iHudPos[id] + 1) % NUM_HUDPOS;
    else if (sel == 21)
        SetLanguage(id, g_iLang[id] == 2 ? 1 : 2);
    else if (sel == 22)
    {
        ShowFpsMenu(id);
        return PLUGIN_HANDLED;
    }

    SaveData(id);
    ShowSettingsMenu(id);
    return PLUGIN_HANDLED;
}

/* ---------------- Dil ---------------- */

ShowLangMenu(id)
{
    new title[64];
    formatex(title, charsmax(title), "%s \y%L^n", MENU_TAG, id, "MENU_LANG");
    new menu = menu_create(title, "menu_lang_handler");

    MenuAdd(menu, g_iLang[id] == 1 ? "\yEnglish \r[\w*\r]" : "\yEnglish", 1);
    MenuAdd(menu, g_iLang[id] == 2 ? "\yTurkce \r[\w*\r]" : "\yTurkce", 2);

    MenuFinish(id, menu);
}

public menu_lang_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new l = MenuInfo(menu, item);
    menu_destroy(menu);

    SetLanguage(id, l);
    // Menu aninda yeni dilde tekrar acilir
    ShowMainMenu(id);
    return PLUGIN_HANDLED;
}

/* ---------------- FPS / performans ---------------- */

ShowFpsMenu(id)
{
    new title[192], item[96];
    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MENU_FPS", id, "MENU_FPS_SUB");
    new menu = menu_create(title, "menu_fps_handler");

    formatex(item, charsmax(item), "\y%L", id, "FPS_1"); MenuAdd(menu, item, 1);
    formatex(item, charsmax(item), "\y%L", id, "FPS_2"); MenuAdd(menu, item, 2);
    formatex(item, charsmax(item), "\y%L", id, "FPS_3"); MenuAdd(menu, item, 3);
    formatex(item, charsmax(item), "\y%L", id, "FPS_4"); MenuAdd(menu, item, 4);
    formatex(item, charsmax(item), "\y%L", id, "FPS_5"); MenuAdd(menu, item, 5);

    MenuFinish(id, menu);
}

public menu_fps_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    switch (sel)
    {
        case 1: // Performans
        {
            g_iSet[id] |= (SET_NO_FX | SET_NO_FOG | SET_NO_AMB | SET_NO_DMGNUM);
            Chat(id, "FPS_PRESET_PERF");
        }
        case 2: // Dengeli
        {
            g_iSet[id] &= ~(SET_NO_FX | SET_NO_DMGNUM);
            g_iSet[id] |= (SET_NO_FOG | SET_NO_AMB);
            Chat(id, "FPS_PRESET_BAL");
        }
        case 3: // Sinematik
        {
            g_iSet[id] &= ~(SET_NO_FX | SET_NO_FOG | SET_NO_AMB | SET_NO_DMGNUM);
            Chat(id, "FPS_PRESET_CINE");
        }
        case 4: PrintFpsConfig(id);
        case 5: PrintNetConfig(id);
    }

    SendFogForEvent(id);
    SaveData(id);
    if (sel <= 3)
        ShowFpsMenu(id);
    return PLUGIN_HANDLED;
}

// Not: Steam guncellemeleri (cl_filterstuffcmd) nedeniyle sunucu fps_max / rate
// gibi ayarlari oyuncuya zorla yazamaz. Bu yuzden komutlari konsola yazdiriyoruz.
PrintFpsConfig(id)
{
    console_print(id, "");
    console_print(id, "======== VEXMIRA - FPS BOOST ========");
    console_print(id, "// %L", id, "FPS_CONSOLE_HINT");
    console_print(id, "fps_max 99.5");
    console_print(id, "fps_override 0");
    console_print(id, "gl_vsync 0");
    console_print(id, "cl_weather 0");
    console_print(id, "cl_corpsestay 0");
    console_print(id, "cl_himodels 0");
    console_print(id, "cl_shadows 0");
    console_print(id, "gl_spriteblend 0");
    console_print(id, "r_dynamic 1");
    console_print(id, "r_decals 100");
    console_print(id, "max_shells 0");
    console_print(id, "max_smokepuffs 0");
    console_print(id, "fastsprites 1");
    console_print(id, "gl_max_size 256");
    console_print(id, "// Launch: -nofbo -noforcemparms -freq 144");
    console_print(id, "======================================");
    Chat(id, "FPS_PRINTED");
}

PrintNetConfig(id)
{
    console_print(id, "");
    console_print(id, "======== VEXMIRA - NET ========");
    console_print(id, "rate 100000");
    console_print(id, "cl_updaterate 102");
    console_print(id, "cl_cmdrate 105");
    console_print(id, "ex_interp 0.01");
    console_print(id, "cl_lc 1");
    console_print(id, "cl_lw 1");
    console_print(id, "===============================");
    Chat(id, "FPS_PRINTED");
}


/* ================================================================== */
/*  EGLENCE KOMUTLARI                                                  */
/* ================================================================== */

#define NUM_JOKES 12
#define NUM_BALL  12
#define NUM_RULES 6
#define LOTTO_TICKET 10
#define LOTTO_MAX    5

new const SLOT_SYM[][] = { "7", "BAR", "ZOMBI", "BEYIN", "KURU KAFA", "ALTIN" };

bool:FunReady(id)
{
    new Float:now = get_gametime();
    if (now < g_fFunCd[id])
    {
        Chat(id, "FUN_WAIT", floatround(g_fFunCd[id] - now, floatround_ceil));
        return false;
    }
    g_fFunCd[id] = now + 4.0;
    return true;
}

// Argumanli komutlar (say /slot 50 gibi) SayHandler'dan buraya gelir
bool:HandleArgCommand(id, const msg[])
{
    new cmd[24], rest[160];
    strtok(msg[1], cmd, charsmax(cmd), rest, charsmax(rest), ' ', 1);
    strtolower(cmd);

    if (equal(cmd, "slot") || equal(cmd, "kumar"))           { FunSlot(id, rest);   return true; }
    if (equal(cmd, "roll") || equal(cmd, "sayi"))            { FunRoll(id, rest);   return true; }
    if (equal(cmd, "soru") || equal(cmd, "8ball") || equal(cmd, "ask")) { FunBall(id, rest); return true; }
    if (equal(cmd, "hediye") || equal(cmd, "gift"))          { FunGift(id, rest);   return true; }
    if (equal(cmd, "odul") || equal(cmd, "bounty"))          { FunBounty(id, rest); return true; }
    if (equal(cmd, "me"))                                    { FunMe(id, rest);     return true; }
    if (equal(cmd, "piyango") || equal(cmd, "lotto"))        { FunLotto(id);        return true; }

    return false;
}

public cmd_dice(id)
{
    if (!FunReady(id)) return PLUGIN_HANDLED;
    new name[32];
    get_user_name(id, name, charsmax(name));
    new r = random_num(1, 6);
    FunAll(id, r == 6 ? "FUN_DICE_6" : "FUN_DICE", name, r);
    return PLUGIN_HANDLED;
}

public cmd_coin(id)
{
    if (!FunReady(id)) return PLUGIN_HANDLED;
    new name[32];
    get_user_name(id, name, charsmax(name));
    FunAll(id, random_num(0, 1) ? "FUN_COIN_HEADS" : "FUN_COIN_TAILS", name);
    return PLUGIN_HANDLED;
}

FunRoll(id, const arg[])
{
    if (!FunReady(id)) return;
    new mx = str_to_num(arg);
    if (mx < 2 || mx > 1000000) mx = 100;
    new name[32];
    get_user_name(id, name, charsmax(name));
    FunAll(id, "FUN_ROLL", name, random_num(1, mx), mx);
}

FunBall(id, const question[])
{
    if (!question[0])
    {
        Chat(id, "FUN_BALL_USAGE");
        return;
    }
    if (!FunReady(id)) return;

    new name[32], key[12];
    get_user_name(id, name, charsmax(name));
    formatex(key, charsmax(key), "BALL_%d", random_num(1, NUM_BALL));

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        client_print_color(p, id, "%s %L", ChatTag("FUN_BALL_Q"), p, "FUN_BALL_Q", name, question);
        client_print_color(p, id, "%s %L", ChatTag(key), p, key);
    }
}

public cmd_joke(id)
{
    if (!FunReady(id)) return PLUGIN_HANDLED;
    new key[12];
    formatex(key, charsmax(key), "JOKE_%d", random_num(1, NUM_JOKES));
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p))
            client_print_color(p, print_team_default, "%s %L", ChatTag(key), p, key);
    }
    return PLUGIN_HANDLED;
}

FunMe(id, const text[])
{
    if (!text[0] || !FunReady(id)) return;
    new name[32];
    get_user_name(id, name, charsmax(name));
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p))
            client_print_color(p, id, "^4* ^3%s^1 %s", name, text);
    }
}

public cmd_dance(id)
{
    if (!FunReady(id)) return PLUGIN_HANDLED;

    new name[32], key[12];
    get_user_name(id, name, charsmax(name));
    formatex(key, charsmax(key), "FUN_DANCE_%d", random_num(1, 4));
    FunAll(id, key, name);

    if (is_user_alive(id))
    {
        new Float:o[3];
        get_entvar(id, var_origin, o);
        FxRing(o, random(256), random(256), random(256), 120);
        FxLight(o, random(256), random(256), random(256), 15, 10, 20);
    }
    return PLUGIN_HANDLED;
}

public cmd_resetscore(id)
{
    set_entvar(id, var_frags, 0.0);
    set_member(id, m_iDeaths, 0);
    UpdateScore(id);
    Chat(id, "FUN_RS");
    return PLUGIN_HANDLED;
}

public cmd_time(id)
{
    new t[32];
    get_time("%H:%M  %d.%m.%Y", t, charsmax(t));
    Chat(id, "FUN_TIME", t);
    return PLUGIN_HANDLED;
}

public cmd_ping(id)
{
    new ping, loss;
    get_user_ping(id, ping, loss);
    Chat(id, ping < 60 ? "FUN_PING_GOOD" : (ping < 120 ? "FUN_PING_OK" : "FUN_PING_BAD"), ping, loss);
    return PLUGIN_HANDLED;
}

public cmd_who(id)
{
    new name[32], tag[16], count;
    Chat(id, "FUN_WHO_TITLE");
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;

        new flags = get_user_flags(p);
        if (flags & ADMIN_RCON)       copy(tag, charsmax(tag), "OWNER");
        else if (flags & ADMIN_BAN)   copy(tag, charsmax(tag), "ADMIN");
        else if (IsElite(p))          copy(tag, charsmax(tag), "ELITE");
        else if (IsVip(p))            copy(tag, charsmax(tag), "VIP");
        else continue;

        get_user_name(p, name, charsmax(name));
        client_print_color(id, p, "   ^4[%s] ^3%s", tag, name);
        count++;
    }
    if (!count)
        Chat(id, "FUN_WHO_NONE");
    return PLUGIN_HANDLED;
}

public cmd_founders(id)
{
    Chat(id, "FOUNDERS_1");
    Chat(id, "FOUNDERS_2");
    Chat(id, "FOUNDERS_3");
    return PLUGIN_HANDLED;
}

public cmd_contact(id)
{
    new c[64];
    get_pcvar_string(g_pVipContact, c, charsmax(c));
    Chat(id, "FUN_CONTACT", c);
    return PLUGIN_HANDLED;
}

public cmd_rules(id)
{
    for (new i = 1; i <= NUM_RULES; i++)
    {
        new key[12];
        formatex(key, charsmax(key), "RULE_%d", i);
        Chat(id, key);
    }
    return PLUGIN_HANDLED;
}

/* ---------------- Slot makinesi ---------------- */

FunSlot(id, const arg[])
{
    new bet = str_to_num(arg);
    if (bet < 5 || bet > 200)
    {
        Chat(id, "SLOT_USAGE");
        return;
    }
    if (g_bSlotting[id])
        return;
    if (g_iAP[id] < bet)
    {
        Chat(id, "SHOP_NOAP");
        return;
    }
    if (!FunReady(id)) return;

    AddAP(id, -bet, false, false);
    g_iSlotBet[id] = bet;
    g_bSlotting[id] = 1;

    new params[2];
    params[0] = id;
    params[1] = 0;
    set_task(0.1, "task_SlotFrame", TASK_SLOT + id, params, 2);
}

public task_SlotFrame(params[])
{
    new id = params[0], frame = params[1];
    if (!is_user_connected(id))
        return;

    if (frame < 4)
    {
        set_hudmessage(255, 200, 40, -1.0, Y_PERS, 0, 0.0, 0.4, 0.0, 0.0, 3);
        show_hudmessage(id, "[ %s ] [ %s ] [ %s ]", SLOT_SYM[random(sizeof SLOT_SYM)], SLOT_SYM[random(sizeof SLOT_SYM)], SLOT_SYM[random(sizeof SLOT_SYM)]);
        client_cmd(id, "spk buttons/blip1");

        new p2[2];
        p2[0] = id;
        p2[1] = frame + 1;
        set_task(0.3, "task_SlotFrame", TASK_SLOT + id, p2, 2);
        return;
    }

    // Sonuc (agirlikli: kazanc orani ~%90 geri donus)
    new a = random(sizeof SLOT_SYM), b = random(sizeof SLOT_SYM), c = random(sizeof SLOT_SYM);
    // Geri donus ~%90 (kasa her zaman biraz kazanir, AP basma acigi yok)
    if (random_num(1, 100) <= 5) b = a;
    if (random_num(1, 100) <= 3) c = a;

    new win, bet = g_iSlotBet[id];
    if (a == b && b == c)
        win = (a == 0) ? bet * 10 : bet * 5;
    else if (a == b || b == c || a == c)
        win = bet * 3 / 2;

    new stxt[64];
    formatex(stxt, charsmax(stxt), "[ %s ] [ %s ] [ %s ]", SLOT_SYM[a], SLOT_SYM[b], SLOT_SYM[c]);
    HudText(id, SL_PERS, win ? 0 : 255, win ? 255 : 90, win ? 140 : 90, 3.0, stxt);

    g_bSlotting[id] = 0;

    if (win)
    {
        AddAP(id, win, false, false);
        PlayKey(id, "SHOP_BUY");
        if (win >= bet * 5)
        {
            new name[32];
            get_user_name(id, name, charsmax(name));
            FunAll(id, "SLOT_JACKPOT", name, win);
            PlayKey(0, "MVP");
        }
        else
            Chat(id, "SLOT_WIN", win);
    }
    else
        Chat(id, "SLOT_LOSE", bet);
}

/* ---------------- Piyango ---------------- */

FunLotto(id)
{
    if (g_iTickets[id] >= LOTTO_MAX)
    {
        Chat(id, "LOTTO_MAX", LOTTO_MAX);
        return;
    }
    if (g_iAP[id] < LOTTO_TICKET)
    {
        Chat(id, "SHOP_NOAP");
        return;
    }

    AddAP(id, -LOTTO_TICKET, false, false);
    g_iTickets[id]++;
    g_iLottoPot += LOTTO_TICKET;

    new left = 600 - (g_iLottoClock % 600);
    Chat(id, "LOTTO_BOUGHT", g_iTickets[id], g_iLottoPot + 50, left / 60);
}

TickLotto()
{
    g_iLottoClock++;

    if (g_iLottoClock % 600 == 540 && g_iLottoPot > 0)
        ChatAll("LOTTO_SOON", g_iLottoPot + 50);

    if (g_iLottoClock % 600 != 0)
        return;

    new total, players;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (g_iTickets[p] > 0 && is_user_connected(p))
        {
            total += g_iTickets[p];
            players++;
        }
    }

    if (!total)
        return;

    if (players < 2)
    {
        for (new p = 1; p <= g_iMax; p++)
        {
            if (g_iTickets[p] > 0 && is_user_connected(p))
            {
                AddAP(p, g_iTickets[p] * LOTTO_TICKET, false, false);
                Chat(p, "LOTTO_REFUND");
            }
            g_iTickets[p] = 0;
        }
        g_iLottoPot = 0;
        return;
    }

    new pick = random_num(1, total), acc, winner;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (g_iTickets[p] <= 0 || !is_user_connected(p))
            continue;
        acc += g_iTickets[p];
        if (pick <= acc)
        {
            winner = p;
            break;
        }
    }

    new prize = g_iLottoPot + 50;
    if (winner)
    {
        new name[32];
        get_user_name(winner, name, charsmax(name));
        AddAP(winner, prize, false, false);
        FunAll(winner, "LOTTO_WINNER", name, prize, g_iTickets[winner]);
        PlayKey(0, "MVP");
    }

    for (new p = 1; p <= g_iMax; p++)
        g_iTickets[p] = 0;
    g_iLottoPot = 0;
}

/* ---------------- Hediye / odul ---------------- */

// "isim miktar" -> hedef ve miktari ayikla (isimde bosluk olabilir: son kelime miktar)
ParseTargetAmount(id, const arg[], &target, &amount)
{
    new buf[96];
    copy(buf, charsmax(buf), arg);
    trim(buf);

    new sp = -1;
    for (new i = strlen(buf) - 1; i >= 0; i--)
    {
        if (buf[i] == ' ')
        {
            sp = i;
            break;
        }
    }
    if (sp <= 0)
        return 0;

    amount = str_to_num(buf[sp + 1]);
    buf[sp] = 0;
    trim(buf);

    target = find_player_ex(FindPlayer_MatchNameSubstring | FindPlayer_CaseInsensitive | FindPlayer_ExcludeBots, buf);
    if (!target || target == id)
        return 0;
    return 1;
}

FunGift(id, const arg[])
{
    new target, amount;
    if (!ParseTargetAmount(id, arg, target, amount) || amount < 5)
    {
        Chat(id, "GIFT_USAGE");
        return;
    }
    if (g_iAP[id] < amount)
    {
        Chat(id, "SHOP_NOAP");
        return;
    }

    new Float:now = get_gametime();
    if (now < g_fGiftCd[id])
    {
        Chat(id, "FUN_WAIT", floatround(g_fGiftCd[id] - now, floatround_ceil));
        return;
    }
    g_fGiftCd[id] = now + 30.0;

    AddAP(id, -amount, false, false);
    AddAP(target, amount, false, true);

    new n1[32], n2[32];
    get_user_name(id, n1, charsmax(n1));
    get_user_name(target, n2, charsmax(n2));
    FunAll(id, "GIFT_DONE", n1, n2, amount);
    PlayKey(target, "DAILY");
}

FunBounty(id, const arg[])
{
    new target, amount;
    if (!ParseTargetAmount(id, arg, target, amount) || amount < 10)
    {
        Chat(id, "BOUNTY_USAGE");
        return;
    }
    if (!is_user_alive(target))
    {
        Chat(id, "BOUNTY_DEAD");
        return;
    }
    if (g_iAP[id] < amount)
    {
        Chat(id, "SHOP_NOAP");
        return;
    }

    AddAP(id, -amount, false, false);
    g_iBounty[target] += amount;

    new n1[32], n2[32];
    get_user_name(id, n1, charsmax(n1));
    get_user_name(target, n2, charsmax(n2));
    FunAll(id, "BOUNTY_SET", n1, n2, g_iBounty[target]);
    PlayKey(0, "STREAK_5");
}

// Infect / Killed icinden cagrilir
PayBounty(killer, victim)
{
    if (g_iBounty[victim] <= 0 || !is_user_connected(killer) || killer == victim)
        return;

    new n1[32], n2[32], amount = g_iBounty[victim];
    g_iBounty[victim] = 0;
    get_user_name(killer, n1, charsmax(n1));
    get_user_name(victim, n2, charsmax(n2));

    AddAP(killer, amount, false, true);
    FunAll(killer, "BOUNTY_PAID", n1, amount, n2);
    PlayKey(killer, "MVP");
}

/* ---------------- Ortak duyuru ---------------- */

stock FunAll(sender, const key[], any:...)
{
    new fmt[191], msg[191];
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        Translate(fmt, charsmax(fmt), key, p);
        vformat(msg, charsmax(msg), fmt, 3);
        client_print_color(p, sender, "%s %s", CHAT_PREFIX, msg);
    }
}

/* ---------------- Eglence menusu ---------------- */

public cmd_fun(id)
{
    ShowFunMenu(id);
    return PLUGIN_HANDLED;
}

ShowFunMenu(id)
{
    new title[96], item[96], key[12];
    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MENU_FUN", id, "MENU_FUN_SUB");
    new menu = menu_create(title, "menu_fun_handler");

    for (new i = 1; i <= 12; i++)
    {
        formatex(key, charsmax(key), "FUNM_%d", i);
        formatex(item, charsmax(item), "\y%L", id, key);
        MenuAdd(menu, item, i);
    }
    MenuFinish(id, menu);
}

public menu_fun_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    switch (sel)
    {
        case 1:  cmd_dice(id);
        case 2:  cmd_coin(id);
        case 3:  cmd_joke(id);
        case 4:  cmd_dance(id);
        case 5:  FunSlot(id, "10");
        case 6:  FunLotto(id);
        case 7:  Chat(id, "FUN_HINT_ARGS");
        case 8:  cmd_resetscore(id);
        case 9:  cmd_who(id);
        case 10: cmd_time(id);
        case 11: cmd_rules(id);
        case 12: cmd_founders(id);
    }

    if (sel <= 6)
        ShowFunMenu(id);
    return PLUGIN_HANDLED;
}


/* ================================================================== */
/*  CANLI SUNUCU: karsilama, sohbet cevaplari, ortam yorumlari          */
/* ================================================================== */

// Rastgele varyasyonlu duyuru: base_1 .. base_N
stock LiveAll(sender, const base[], count, any:...)
{
    new key[24], fmt[191], msg[191];
    formatex(key, charsmax(key), "%s_%d", base, random_num(1, count));

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        Translate(fmt, charsmax(fmt), key, p);
        vformat(msg, charsmax(msg), fmt, 4);
        client_print_color(p, sender, "^4Vexmira^1: %s", msg);
    }
}

stock LiveTo(id, const base[], count, any:...)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    new key[24], fmt[191], msg[191];
    formatex(key, charsmax(key), "%s_%d", base, random_num(1, count));
    Translate(fmt, charsmax(fmt), key, id);
    vformat(msg, charsmax(msg), fmt, 4);
    client_print_color(id, print_team_default, "^4Vexmira^1: %s", msg);
}

// Giris karsilamasi: yeni oyuncu / geri donen oyuncu
LiveJoin(id)
{
    if (is_user_bot(id))
        return;

    new name[32];
    get_user_name(id, name, charsmax(name));

    if (g_bNewPlayer[id])
        LiveAll(id, "LIVE_JOINNEW", 3, name);
    else
    {
        new days = (get_systime() - g_iLastSeen[id]) / 86400;
        if (days >= 2)
            LiveAll(id, "LIVE_JOINBACK", 3, name, days);
        else
            LiveAll(id, "LIVE_JOINSOON", 3, name);
    }

    new humans = CountPlaying() + 1;
    if (humans == 10 || humans == 16 || humans == 24 || humans == 32)
        LiveAll(0, "LIVE_CROWD", 2, humans);
}

LiveLeave(id)
{
    if (is_user_bot(id))
        return;
    new name[32];
    get_user_name(id, name, charsmax(name));
    LiveAll(0, "LIVE_LEAVE", 3, name);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (p != id && is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_AMB))
            PlayKey(p, "PLAYER_LEAVE");
    }
}

// Chat'e canli cevap
LiveReply(id, const msg[])
{
    new Float:now = get_gametime();
    if (now < g_fReplyCd || now < g_fPlayerReplyCd[id] || is_user_bot(id))
        return;

    new low[160];
    copy(low, charsmax(low), msg);
    strtolower(low);

    new base[24], count;

    if (equal(low, "sa") || equal(low, "slm") || equal(low, "sea") || containi(low, "selam") != -1
        || containi(low, "merhaba") != -1 || equal(low, "hi") || equal(low, "hello") || equal(low, "hey"))
    { copy(base, charsmax(base), "LIVE_HELLO"); count = 4; }
    else if (equal(low, "gg") || equal(low, "ggwp") || equal(low, "gg wp"))
    { copy(base, charsmax(base), "LIVE_GG"); count = 3; }
    else if (containi(low, "iyi geceler") != -1 || equal(low, "gn") || containi(low, "good night") != -1 || containi(low, "bb") == 0)
    { copy(base, charsmax(base), "LIVE_BYE"); count = 3; }
    else if (containi(low, "naber") != -1 || containi(low, "nasilsin") != -1 || containi(low, "how are you") != -1)
    { copy(base, charsmax(base), "LIVE_HOW"); count = 3; }
    else if (containi(low, "vexmira") != -1)
    { copy(base, charsmax(base), "LIVE_CALL"); count = 3; }
    else if (containi(low, "tesekkur") != -1 || containi(low, "sagol") != -1 || equal(low, "ty") || containi(low, "thanks") != -1)
    { copy(base, charsmax(base), "LIVE_THANKS"); count = 2; }
    else if (containi(low, "vip") != -1 && (containi(low, "nasil") != -1 || containi(low, "how") != -1 || containi(low, "fiyat") != -1))
    { copy(base, charsmax(base), "LIVE_VIPASK"); count = 1; }
    else if (containi(low, "lag") != -1 || containi(low, "fps") != -1)
    { copy(base, charsmax(base), "LIVE_LAG"); count = 2; }
    else
        return;

    g_fReplyCd = now + 6.0;
    g_fPlayerReplyCd[id] = now + 25.0;

    new params[2];
    params[0] = id;
    params[1] = count;
    copy(g_szReplyBase, charsmax(g_szReplyBase), base);
    set_task(random_float(0.8, 1.6), "task_LiveReply", TASK_REPLY, params, 2);
}

public task_LiveReply(params[])
{
    new id = params[0];
    if (!is_user_connected(id))
        return;
    new name[32];
    get_user_name(id, name, charsmax(name));

    if (equal(g_szReplyBase, "LIVE_VIPASK"))
    {
        new c[64];
        get_pcvar_string(g_pVipContact, c, charsmax(c));
        LiveAll(id, g_szReplyBase, params[1], name, c);
    }
    else
        LiveAll(id, g_szReplyBase, params[1], name);
}

// Periyodik ortam yorumu (her ~2 dk)
LiveChatter()
{
    new pick = random_num(1, 5);

    // 1) Haritanin en iyisi
    if (pick == 1)
    {
        new best, top;
        for (new p = 1; p <= g_iMax; p++)
        {
            if (is_user_connected(p) && !is_user_bot(p) && g_iMapKills[p] > top)
            {
                top = g_iMapKills[p];
                best = p;
            }
        }
        if (best && top >= 5)
        {
            new name[32];
            get_user_name(best, name, charsmax(name));
            LiveAll(best, "LIVE_TOPKILL", 3, name, top);
            return;
        }
    }

    // 2) Kazanma serileri
    if (pick == 2 && g_iHumanStreak >= 3)
    {
        LiveAll(0, "LIVE_HSTREAK", 2, g_iHumanStreak);
        return;
    }
    if (pick == 2 && g_iZombieStreak >= 3)
    {
        LiveAll(0, "LIVE_ZSTREAK", 2, g_iZombieStreak);
        return;
    }

    // 3) Gunun saatine gore
    if (pick == 3)
    {
        new h[4];
        get_time("%H", h, charsmax(h));
        new hour = str_to_num(h);
        new part = (hour < 6) ? 0 : (hour < 12) ? 1 : (hour < 18) ? 2 : 3;
        new key[16];
        formatex(key, charsmax(key), "LIVE_TIME%d", part);
        LiveAll(0, key, 2);
        return;
    }

    // 4-5) Genel sohbet
    LiveAll(0, "LIVE_RANDOM", 10);
}


/* ================================================================== */
/*  v2.0  AFK YONETICISI                                               */
/*  vex_afk_time saniye hic kipirdamayan (yer + bakis ayni) oyuncu     */
/*  once uyarilir, sonra izleyiciye alinir (vex_afk_action 1) veya     */
/*  sunucudan atilir (2). Yoneticiler (immunity) etkilenmez.           */
/* ================================================================== */

TickAfk()
{
    new limit = get_pcvar_num(g_pAfkTime);
    if (limit <= 0 || !g_bRoundActive)
        return;

    new Float:o[3], Float:a[3];
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || is_user_bot(id) || is_user_hltv(id))
        {
            g_iAfkSec[id] = 0;
            continue;
        }
        if (g_bBoss[id] || (get_user_flags(id) & ADMIN_IMMUNITY))
        {
            g_iAfkSec[id] = 0;
            continue;
        }

        get_entvar(id, var_origin, o);
        get_entvar(id, var_v_angle, a);
        if (get_distance_f(o, g_fAfkPos[id]) > 4.0 || floatabs(a[1] - g_fAfkAng[id][1]) > 0.5 || floatabs(a[0] - g_fAfkAng[id][0]) > 0.5)
        {
            g_fAfkPos[id] = o;
            g_fAfkAng[id] = a;
            g_iAfkSec[id] = 0;
            continue;
        }

        g_iAfkSec[id]++;
        if (g_iAfkSec[id] == limit - 15)
        {
            Chat(id, "AFK_WARN", 15);
            PlayKey(id, "BOSS_WARN");
        }
        else if (g_iAfkSec[id] >= limit)
        {
            g_iAfkSec[id] = 0;
            new name[32];
            get_user_name(id, name, charsmax(name));
            if (get_pcvar_num(g_pAfkAction) == 2)
            {
                ChatAllS("AFK_KICKED", name);
                server_cmd("kick #%d ^"AFK^"", get_user_userid(id));
            }
            else
            {
                ChatAllS("AFK_MOVED", name);
                user_silentkill(id);
                rg_set_user_team(id, TEAM_SPECTATOR, MODEL_UNASSIGNED, true, false);
                CheckWin();
            }
        }
    }
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

/* ---------------- v3.0 (C): ResetPlayer'in dosyada sonra tanimlanan dizileri ---------------- */
// Slotu devralan yeni oyuncuya onceki oyuncunun durumu kalmasin (bekleyen dogma, hasar
// bankasi, gorev ilerlemesi, oy / menu kimlikleri, round bayraklari, bekleme sureleri).
ResetPlayerLate(id)
{
    g_fRespawnAt[id] = 0.0;
    g_iDmgBank[id] = 0;
    g_iQuestProg[id] = 0;
    g_bClassSwitched[id] = false;
    g_bGunsGiven[id] = false;
    g_bNadesGiven[id] = false;
    g_fUnstuck[id] = 0.0;
    g_fLastSay[id] = 0.0;
    g_iVoted[id] = -1;
    g_iVoteMenu[id] = -1;
    g_iMapVoteMenu[id] = -1;
}
