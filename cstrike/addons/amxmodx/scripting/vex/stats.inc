/* ================================================================== */
/*  Vexmira Zombie - modul: vex/stats.inc  (ISTATISTIK)               */
/*  nvault kayit / yukleme, level / rutbe / basarim / unvan /         */
/*  gunluk odul, round gorevleri, TOP 15 siralama, oyuncu karti.      */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  KAYIT (nvault)                                                     */
/* ================================================================== */

// Kayit anahtari: oyuncu yuklenince bir kez hesaplanir ve sabit kalir
// (isim degistirince ilerleme kopyalanmaz)
GetKey(id, key[], len)
{
    if (g_szKey[id][0])
    {
        copy(key, len, g_szKey[id]);
        return;
    }
    ComputeKey(id, key, len);
}

ComputeKey(id, key[], len)
{
    new auth[35];
    get_user_authid(id, auth, charsmax(auth));

    if (!auth[0] || equal(auth, "STEAM_ID_LAN") || equal(auth, "VALVE_ID_LAN") || equal(auth, "BOT")
        || equal(auth, "HLTV") || containi(auth, "PENDING") != -1 || containi(auth, "UNKNOWN") != -1)
    {
        new n[32];
        get_user_name(id, n, charsmax(n));
        formatex(key, len, "N_%s", n);
    }
    else
        copy(key, len, auth);
}

LoadData(id)
{
    if (is_user_bot(id))
    {
        g_iLang[id] = 1;
        return;
    }

    g_iAP[id] = get_pcvar_num(g_pStartAP);

    if (g_hVault == INVALID_HANDLE)
        return;

    new key[48], val[400];
    GetKey(id, key, charsmax(key));

    if (!nvault_get(g_hVault, key, val, charsmax(val)))
        return;

    g_bNewPlayer[id] = 0;

    new f[40], arg[16], pos, n;
    while (n < sizeof f && (pos = argparse(val, pos, arg, charsmax(arg))) != -1)
        f[n++] = str_to_num(arg);

    g_iXP[id]          = f[0];
    g_iAP[id]          = f[1];
    g_iVC[id]          = f[2];
    g_iKills[id]       = f[3];
    g_iInfects[id]     = f[4];
    g_iWins[id]        = f[5];
    g_iBossK[id]       = f[6];
    g_iHS[id]          = f[7];
    g_iAch[id]         = f[8];
    g_iTitle[id]       = f[9];
    g_iJob[id]         = f[10];
    g_iStyle[id]       = f[11];
    g_iSet[id]         = f[12];
    g_iTheme[id]       = f[13];
    g_iLang[id]        = f[14];
    g_iDailyDay[id]    = f[15];
    g_iDailyStreak[id] = f[16];
    g_iPrim[id]        = (n > 17) ? f[17] : -1;
    g_iSec[id]         = (n > 18) ? f[18] : -1;
    g_iPlaySec[id]     = f[19] * 60;
    for (new i = 0; i < NUM_PERKS; i++)
        g_iPerk[id][i] = clamp(f[20 + i], 0, PERK_MAX);
    g_iClass[id]       = f[26];
    g_iLastSeen[id]    = (n > 27) ? f[27] : 0;
    g_iHudPos[id]      = (n > 28) ? clamp(f[28], 0, NUM_HUDPOS - 1) : 0;
    g_iCosOwned[id]    = (n > 29) ? f[29] : 0;
    g_iTrailSel[id]    = (n > 30) ? clamp(f[30], 0, NUM_TRAILS) : 0;
    g_iKfxSel[id]      = (n > 31) ? clamp(f[31], 0, NUM_KFX) : 0;
    g_iIfxSel[id]      = (n > 32) ? clamp(f[32], 0, NUM_IFX) : 0;

    g_iLevel[id] = CalcLevel(g_iXP[id]);

    if (g_iTitle[id] < 0 || g_iTitle[id] >= NUM_TITLES) g_iTitle[id] = 0;
    if (g_iJob[id] < 0 || g_iJob[id] >= NUM_JOBS || g_iLevel[id] < JOB_LVL[g_iJob[id]]) g_iJob[id] = 0;
    if (g_iStyle[id] < 0 || g_iStyle[id] >= NUM_STYLES) g_iStyle[id] = 0;
    if (g_iTheme[id] < 0 || g_iTheme[id] >= NUM_THEMES) g_iTheme[id] = 0;
    if (g_iLang[id] < 0 || g_iLang[id] > 2) g_iLang[id] = 0;
    if (g_iPrim[id] >= sizeof PRIM_NAME) g_iPrim[id] = -1;
    if (g_iSec[id] >= sizeof SEC_NAME) g_iSec[id] = -1;
    if (g_iClass[id] < 0 || g_iClass[id] >= NUM_CLASSES || g_iLevel[id] < CLASS_LVL[g_iClass[id]]) g_iClass[id] = 0;
    if (g_iAP[id] < 0) g_iAP[id] = 0;
    if (g_iVC[id] < 0) g_iVC[id] = 0;
}

SaveData(id)
{
    if (g_hVault == INVALID_HANDLE || !is_user_connected(id) || is_user_bot(id) || !g_bLoaded[id])
        return;

    new key[48], val[400];
    GetKey(id, key, charsmax(key));

    formatex(val, charsmax(val), "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
        g_iXP[id], g_iAP[id], g_iVC[id], g_iKills[id], g_iInfects[id], g_iWins[id], g_iBossK[id], g_iHS[id],
        g_iAch[id], g_iTitle[id], g_iJobNext[id] >= 0 ? g_iJobNext[id] : g_iJob[id], g_iStyle[id], g_iSet[id], g_iTheme[id], g_iLang[id],
        g_iDailyDay[id], g_iDailyStreak[id], g_iPrim[id], g_iSec[id], g_iPlaySec[id] / 60,
        g_iPerk[id][0], g_iPerk[id][1], g_iPerk[id][2], g_iPerk[id][3], g_iPerk[id][4], g_iPerk[id][5],
        g_iClassNext[id] >= 0 ? g_iClassNext[id] : g_iClass[id], get_systime(), g_iHudPos[id],
        g_iCosOwned[id], g_iTrailSel[id], g_iKfxSel[id], g_iIfxSel[id]);

    nvault_set(g_hVault, key, val);
    UpdateTop(id, key);
}


/* ================================================================== */
/*  CHAT: TAG / STIL                                                   */
/* ================================================================== */

stock TitleName(id, viewer, out[], len)
{
    new key[16];
    if (g_iTitle[id] > 0)
        formatex(key, charsmax(key), "TITLE_%d", g_iTitle[id]);
    else
        formatex(key, charsmax(key), "RANK_%d", RankOf(g_iLevel[id]));
    formatex(out, len, "%L", viewer, key);
}


/* ================================================================== */
/*  EKONOMI: XP / LEVEL / AP / VC / BASARIM                            */
/* ================================================================== */

CalcLevel(xp)
{
    new lvl = 1 + floatround(floatsqroot(float(xp) / 25.0), floatround_floor);
    return min(lvl, MAX_LEVEL);
}

XPForLevel(lvl)
{
    return 25 * (lvl - 1) * (lvl - 1);
}

RankOf(lvl)
{
    new r;
    for (new i = 0; i < NUM_RANKS; i++)
    {
        if (lvl >= RANK_LVL[i])
            r = i;
    }
    return r;
}

LevelUp(id, old)
{
    new Float:o[3], name[32];
    get_entvar(id, var_origin, o);
    get_user_name(id, name, charsmax(name));

    // Her level 1 VC, her 10 levelde +5 VC bonus
    new vc = g_iLevel[id] - old;
    for (new l = old + 1; l <= g_iLevel[id]; l++)
    {
        if (l % 10 == 0)
            vc += 5;
    }
    g_iVC[id] += vc;

    FxRing(o, 0, 255, 140, 260);
    FxLight(o, 0, 255, 140, 25, 12, 30);
    FxSpr(o, g_sprFx[FXS_LEVELUP], 9, 230, 20.0);
    FadeOne(id, 0, 255, 140, 90, 0.6);
    PlayKey(id, "LEVEL_UP");
    HudTo(id, SL_PERS, CLR_REWARD, 3.5, "LEVEL_UP_HUD", g_iLevel[id]);
    Chat(id, "LEVELUP_VC", vc);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && p != id)
            client_print_color(p, id, "%s %L", ChatTag("LEVELUP_CHAT"), p, "LEVELUP_CHAT", name, g_iLevel[id]);
    }

    // Yeni acilan icerik bildirimi
    for (new j = 0; j < NUM_JOBS; j++)
    {
        if (JOB_LVL[j] > old && JOB_LVL[j] <= g_iLevel[id])
            ChatKeyName(id, "UNLOCK_JOB", "JOB_", j);
    }
    for (new c = 0; c < NUM_CLASSES; c++)
    {
        if (CLASS_LVL[c] > old && CLASS_LVL[c] <= g_iLevel[id])
            ChatKeyName(id, "UNLOCK_CLASS", "CLASS_", c);
    }
    for (new s = 0; s < NUM_SPECIAL; s++)
    {
        if (SW_LVL[s] > old && SW_LVL[s] <= g_iLevel[id])
            ChatKeyName(id, "UNLOCK_SW", "SW_", s);
    }

    if (RankOf(g_iLevel[id]) > RankOf(old))
    {
        new key[12];
        formatex(key, charsmax(key), "RANK_%d", RankOf(g_iLevel[id]));
        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_connected(p))
                continue;
            new rn[32];
            formatex(rn, charsmax(rn), "%L", p, key);
            client_print_color(p, id, "%s %L", ChatTag("RANKUP_CHAT"), p, "RANKUP_CHAT", name, rn);
        }
    }

    SaveData(id);
}

CheckAch(id)
{
    if (g_iInfects[id] >= 1)    GrantAch(id, 0);
    if (g_iKills[id] >= 50)     GrantAch(id, 1);
    if (g_iKills[id] >= 250)    GrantAch(id, 2);
    if (g_iInfects[id] >= 100)  GrantAch(id, 3);
    if (g_iBossK[id] >= 1)      GrantAch(id, 4);
    if (g_iBossK[id] >= 5)      GrantAch(id, 5);
    if (g_iWins[id] >= 10)      GrantAch(id, 6);
    if (g_iHS[id] >= 200)       GrantAch(id, 8);
    if (g_iLevel[id] >= 10)     GrantAch(id, 9);
    if (g_iLevel[id] >= 30)     GrantAch(id, 10);
    if (g_iLevel[id] >= 50)     GrantAch(id, 11);
    if (g_iDailyStreak[id] >= 7) GrantAch(id, 12);

    for (new i = 0; i < NUM_PERKS; i++)
    {
        if (g_iPerk[id][i] >= PERK_MAX)
        {
            GrantAch(id, 13);
            break;
        }
    }
}

GrantAch(id, bit)
{
    if (is_user_bot(id) || (g_iAch[id] & (1 << bit)))
        return;

    g_iAch[id] |= (1 << bit);
    g_iVC[id] += get_pcvar_num(g_pAchVC);
    AddAP(id, get_pcvar_num(g_pAchAP), false, false);

    new key[16], name[32], Float:o[3];
    formatex(key, charsmax(key), "ACH_NAME_%d", bit);
    get_user_name(id, name, charsmax(name));
    get_entvar(id, var_origin, o);

    new txt[128];
    formatex(txt, charsmax(txt), "%L^n%L  (+%d VC  +%d AP)", id, "ACH_POPUP", id, key, get_pcvar_num(g_pAchVC), get_pcvar_num(g_pAchAP));
    HudText(id, SL_PERS, CLR_REWARD, 4.0, txt);

    PlayKey(id, "ACH_UNLOCK");
    FxRing(o, 255, 215, 0, 260);
    FadeOne(id, 255, 215, 0, 70, 0.7);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p))
            continue;
        new an[48];
        formatex(an, charsmax(an), "%L", p, key);
        client_print_color(p, id, "%s %L", ChatTag("ACH_CHAT"), p, "ACH_CHAT", name, an);
    }

    // Unvan acildi mi?
    for (new t = 1; t < NUM_TITLES; t++)
    {
        if (TITLE_ACH[t] == bit)
            ChatKeyName(id, "UNLOCK_TITLE", "TITLE_", t);
    }
    SaveData(id);
}

/* ---------------- Gunluk odul ---------------- */

ClaimDaily(id)
{
    new today = get_systime() / 86400;

    if (g_iDailyDay[id] == today)
    {
        new left = 86400 - (get_systime() % 86400);
        Chat(id, "DAILY_WAIT", left / 3600, (left % 3600) / 60);
        return;
    }

    if (g_iDailyDay[id] == today - 1)
        g_iDailyStreak[id]++;
    else
        g_iDailyStreak[id] = 1;

    g_iDailyDay[id] = today;

    new s = min(g_iDailyStreak[id], 7);
    new ap = get_pcvar_num(g_pDailyAP) + 10 * s;
    new vc = 1 + s / 2;
    new xp = 50 + 25 * s;

    if (IsElite(id))
    {
        ap += 40;
        vc += 2;
    }
    else if (IsVip(id))
    {
        ap += 20;
        vc += 1;
    }

    g_iVC[id] += vc;
    AddAP(id, ap, false, false);
    Reward(id, xp, 0);

    PlayKey(id, "DAILY");
    new txt[128];
    formatex(txt, charsmax(txt), "%L", id, "DAILY_HUD", g_iDailyStreak[id], ap, vc, xp);
    HudText(id, SL_PERS, CLR_REWARD, 4.0, txt);
    Chat(id, "DAILY_CHAT", g_iDailyStreak[id], ap, vc, xp);

    if (g_iDailyStreak[id] < 7)
        Chat(id, "DAILY_NEXT");

    CheckAch(id);
    SaveData(id);
}


/* ================================================================== */
/*  MENULER                                                            */
/* ================================================================== */

/* ---------------- Unvan ---------------- */

ShowTitleMenu(id)
{
    new title[64], item[128], key[12], tn[40];

    formatex(title, charsmax(title), "%s \y%L^n", MENU_TAG, id, "MENU_TITLE");
    new menu = menu_create(title, "menu_title_handler");

    for (new i = 0; i < NUM_TITLES; i++)
    {
        formatex(key, charsmax(key), "TITLE_%d", i);
        formatex(tn, charsmax(tn), "%L", id, key);

        if (!TitleUnlocked(id, i))
        {
            new ak[16], an[40];
            formatex(ak, charsmax(ak), "ACH_NAME_%d", TITLE_ACH[i]);
            formatex(an, charsmax(an), "%L", id, ak);
            formatex(item, charsmax(item), "\d%s \r(%s)", tn, an);
        }
        else if (g_iTitle[id] == i)
            formatex(item, charsmax(item), "\y%s \r[\w*\r]", tn);
        else
            formatex(item, charsmax(item), "\y%s", tn);

        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

bool:TitleUnlocked(id, t)
{
    if (t == 0)
        return true;
    return (g_iAch[id] & (1 << TITLE_ACH[t])) ? true : false;
}

public menu_title_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new t = MenuInfo(menu, item);
    menu_destroy(menu);

    if (!TitleUnlocked(id, t))
    {
        Chat(id, "TITLE_LOCKED");
        ShowTitleMenu(id);
        return PLUGIN_HANDLED;
    }

    g_iTitle[id] = t;
    ChatKeyName(id, "TITLE_SELECTED", "TITLE_", t);
    SaveData(id);
    return PLUGIN_HANDLED;
}

/* ---------------- Basarimlar ---------------- */

ShowAchMenu(id)
{
    new title[96], item[160], k1[16], k2[16], n1[40], n2[64], count;

    for (new i = 0; i < NUM_ACH; i++)
    {
        if (g_iAch[id] & (1 << i))
            count++;
    }

    formatex(title, charsmax(title), "%s \y%L \r[\w%d/%d\r]^n", MENU_TAG, id, "MENU_ACH", count, NUM_ACH);
    new menu = menu_create(title, "menu_ach_handler");

    for (new i = 0; i < NUM_ACH; i++)
    {
        formatex(k1, charsmax(k1), "ACH_NAME_%d", i);
        formatex(k2, charsmax(k2), "ACH_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        if (g_iAch[id] & (1 << i))
            formatex(item, charsmax(item), "\r[\wX\r] \y%s \d%s", n1, n2);
        else
            formatex(item, charsmax(item), "\r[ \r] \d%s - %s", n1, n2);

        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_ach_handler(id, menu, item)
{
    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

/* ---------------- Istatistik / Top ---------------- */

ShowStats(id)
{
    new count, tname[32];
    for (new i = 0; i < NUM_ACH; i++)
    {
        if (g_iAch[id] & (1 << i))
            count++;
    }
    TitleName(id, id, tname, charsmax(tname));

    Chat(id, "STATS_1", g_iLevel[id], tname, g_iXP[id], XPForLevel(g_iLevel[id] + 1));
    Chat(id, "STATS_2", g_iAP[id], g_iVC[id]);
    Chat(id, "STATS_3", g_iKills[id], g_iInfects[id], g_iHS[id]);
    Chat(id, "STATS_4", g_iWins[id], g_iBossK[id], count, NUM_ACH);
    Chat(id, "STATS_5", g_iPlaySec[id] / 3600, (g_iPlaySec[id] % 3600) / 60, g_iDailyStreak[id]);
}

ShowTop(id)
{
    new ids[32], n, tmp;

    for (new i = 1; i <= g_iMax; i++)
    {
        if (is_user_connected(i) && !is_user_bot(i))
            ids[n++] = i;
    }

    for (new i = 0; i < n - 1; i++)
    {
        for (new j = i + 1; j < n; j++)
        {
            if (g_iXP[ids[j]] > g_iXP[ids[i]])
            {
                tmp = ids[i];
                ids[i] = ids[j];
                ids[j] = tmp;
            }
        }
    }

    Chat(id, "TOP_TITLE");

    new name[32];
    for (new i = 0; i < n && i < 5; i++)
    {
        get_user_name(ids[i], name, charsmax(name));
        Chat(id, "TOP_LINE", i + 1, name, g_iLevel[ids[i]], g_iXP[ids[i]]);
    }
}


/* ================================================================== */
/*  HAVA IKMALI, ROUND GOREVLERI, ZOMBI EVRIMI, EVENT EFEKTLERI        */
/* ================================================================== */

/* ---------------- Round gorevleri ----------------
   Her round herkese kucuk bir gorev: tamamlayan XP + AP kazanir. */

// tur: 0 zombi oldur, 1 hasar ver, 2 headshot, 4 enfekte et, 7 roundu insan olarak kazan
new const QUEST_TYPE[NUM_QUESTS] = { 0, 0, 1, 1, 2, 4, 4, 7 };
new g_iQuestProg[33];

AssignQuests()
{
    if (!get_pcvar_num(g_pQuests))
        return;

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_bot(id))
        {
            g_iQuest[id] = -1;
            continue;
        }

        new q, tries;
        do
        {
            q = random(NUM_QUESTS);
            tries++;
        }
        while (tries < 20 && (q == g_iQuest[id] || (QUEST_TYPE[q] == 4 && !AllowsInfection())));

        g_iQuest[id] = q;
        g_iQuestProg[id] = 0;
        g_bQuestDone[id] = false;

        new desc[64], key[12];
        formatex(key, charsmax(key), "QUEST_%d", q);
        formatex(desc, charsmax(desc), "%L", id, key, QUEST_NEED[q]);
        client_print_color(id, print_team_default, "%s %L", ChatTag("QUEST_NEW"), id, "QUEST_NEW", desc, QUEST_XP[q], QUEST_AP[q]);
    }
}

QuestEvent(id, type, amount)
{
    if (!get_pcvar_num(g_pQuests) || !(1 <= id <= g_iMax) || is_user_bot(id))
        return;
    new q = g_iQuest[id];
    if (q < 0 || q >= NUM_QUESTS || g_bQuestDone[id] || QUEST_TYPE[q] != type)
        return;

    g_iQuestProg[id] += amount;
    if (g_iQuestProg[id] < QUEST_NEED[q])
        return;

    g_iQuestProg[id] = QUEST_NEED[q];
    g_bQuestDone[id] = true;

    Reward(id, QUEST_XP[q], QUEST_AP[q]);
    PlayKey(id, "QUEST_DONE");
    HudTo(id, SL_PERS, CLR_REWARD, 3.0, "QUEST_DONE_HUD");

    new name[32];
    get_user_name(id, name, charsmax(name));
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p))
            client_print_color(p, id, "%s %L", ChatTag("QUEST_DONE_ALL"), p, "QUEST_DONE_ALL", name);
    }
}

QuestLine(id, out[], len)
{
    out[0] = 0;
    new q = g_iQuest[id];
    if (!get_pcvar_num(g_pQuests) || q < 0 || q >= NUM_QUESTS)
        return;

    if (g_bQuestDone[id])
    {
        formatex(out, len, "%L", id, "QUEST_LINE_DONE");
        return;
    }

    new key[12], desc[48];
    formatex(key, charsmax(key), "QSHORT_%d", q);
    formatex(desc, charsmax(desc), "%L", id, key);
    formatex(out, len, "%L", id, "QUEST_LINE", desc, min(g_iQuestProg[id], QUEST_NEED[q]), QUEST_NEED[q]);
}

public cmd_quest(id)
{
    new q = g_iQuest[id];
    if (!get_pcvar_num(g_pQuests) || q < 0 || q >= NUM_QUESTS)
    {
        Chat(id, "QUEST_NONE");
        return PLUGIN_HANDLED;
    }

    new desc[64], key[12];
    formatex(key, charsmax(key), "QUEST_%d", q);
    formatex(desc, charsmax(desc), "%L", id, key, QUEST_NEED[q]);
    if (g_bQuestDone[id])
        client_print_color(id, print_team_default, "%s %L", ChatTag("QUEST_INFO_DONE"), id, "QUEST_INFO_DONE", desc);
    else
        client_print_color(id, print_team_default, "%s %L", ChatTag("QUEST_INFO"), id, "QUEST_INFO", desc, min(g_iQuestProg[id], QUEST_NEED[q]), QUEST_NEED[q], QUEST_XP[q], QUEST_AP[q]);
    return PLUGIN_HANDLED;
}


/* ================================================================== */
/*  KOZMETIK (Vex Coin ile kalici): iz, oldurme efekti, enfeksiyon     */
/*  efekti. TUM ZAMANLARIN SIRALAMASI (ilk 15) + stil kartlari.        */
/*  IZLEYICI BILGISI: olu oyuncu izledigi kisinin bilgisini gorur.     */
/* ================================================================== */

/* ---------------- Tum zamanlarin siralamasi ---------------- */

TopFile(path[], len)
{
    get_datadir(path, len);
    add(path, len, "/vexmira_top.ini");
}

LoadTop()
{
    new path[128];
    TopFile(path, charsmax(path));
    g_iTopCount = 0;

    new fp = fopen(path, "rt");
    if (!fp)
        return;

    new line[160], key[48], name[32], s1[12], s2[12], s3[12], s4[12];
    while (!feof(fp) && g_iTopCount < TOP_MAX)
    {
        fgets(fp, line, charsmax(line));
        trim(line);
        if (!line[0] || line[0] == ';')
            continue;
        if (parse(line, key, charsmax(key), name, charsmax(name), s1, charsmax(s1), s2, charsmax(s2), s3, charsmax(s3), s4, charsmax(s4)) < 6)
            continue;

        new i = g_iTopCount++;
        copy(g_szTopKey[i], charsmax(g_szTopKey[]), key);
        copy(g_szTopName[i], charsmax(g_szTopName[]), name);
        g_iTopXP[i] = str_to_num(s1);
        g_iTopKills[i] = str_to_num(s2);
        g_iTopInf[i] = str_to_num(s3);
        g_iTopBoss[i] = str_to_num(s4);
    }
    fclose(fp);
    SortTop();
    g_bTopDirty = false;
}

SaveTop()
{
    if (!g_bTopDirty)
        return;

    new path[128];
    TopFile(path, charsmax(path));
    new fp = fopen(path, "wt");
    if (!fp)
        return;

    fprintf(fp, "; Vexmira - tum zamanlarin siralamasi (otomatik)^n");
    for (new i = 0; i < g_iTopCount; i++)
        fprintf(fp, "^"%s^" ^"%s^" %d %d %d %d^n", g_szTopKey[i], g_szTopName[i], g_iTopXP[i], g_iTopKills[i], g_iTopInf[i], g_iTopBoss[i]);
    fclose(fp);
    g_bTopDirty = false;
}

TopSwap(a, b)
{
    new tk[48], tn[32], t;
    copy(tk, charsmax(tk), g_szTopKey[a]);
    copy(g_szTopKey[a], charsmax(g_szTopKey[]), g_szTopKey[b]);
    copy(g_szTopKey[b], charsmax(g_szTopKey[]), tk);
    copy(tn, charsmax(tn), g_szTopName[a]);
    copy(g_szTopName[a], charsmax(g_szTopName[]), g_szTopName[b]);
    copy(g_szTopName[b], charsmax(g_szTopName[]), tn);
    t = g_iTopXP[a];    g_iTopXP[a] = g_iTopXP[b];       g_iTopXP[b] = t;
    t = g_iTopKills[a]; g_iTopKills[a] = g_iTopKills[b]; g_iTopKills[b] = t;
    t = g_iTopInf[a];   g_iTopInf[a] = g_iTopInf[b];     g_iTopInf[b] = t;
    t = g_iTopBoss[a];  g_iTopBoss[a] = g_iTopBoss[b];   g_iTopBoss[b] = t;
}

SortTop()
{
    for (new i = 1; i < g_iTopCount; i++)
    {
        for (new j = i; j > 0 && g_iTopXP[j] > g_iTopXP[j - 1]; j--)
            TopSwap(j, j - 1);
    }
    RefreshTopRanks();
}

RefreshTopRanks()
{
    new key[48];
    for (new id = 1; id <= g_iMax; id++)
    {
        g_iTopRank[id] = 0;
        if (!is_user_connected(id) || is_user_bot(id))
            continue;
        GetKey(id, key, charsmax(key));
        for (new i = 0; i < g_iTopCount; i++)
        {
            if (equal(g_szTopKey[i], key))
            {
                g_iTopRank[id] = i + 1;
                break;
            }
        }
    }
}

// Oyuncu kaydedilince siralamaya islenir
UpdateTop(id, const key[])
{
    if (is_user_bot(id) || g_iXP[id] <= 0)
        return;

    new slot = -1;
    for (new i = 0; i < g_iTopCount; i++)
    {
        if (equal(g_szTopKey[i], key))
        {
            slot = i;
            break;
        }
    }
    if (slot == -1)
    {
        if (g_iTopCount < TOP_MAX)
            slot = g_iTopCount++;
        else if (g_iXP[id] > g_iTopXP[TOP_MAX - 1])
            slot = TOP_MAX - 1;
        else
            return;
    }
    else if (g_iTopXP[slot] == g_iXP[id] && g_iTopKills[slot] == g_iKills[id] && g_iTopInf[slot] == g_iInfects[id])
        return;

    new name[32];
    get_user_name(id, name, charsmax(name));
    replace_all(name, charsmax(name), "^"", "'");

    copy(g_szTopKey[slot], charsmax(g_szTopKey[]), key);
    copy(g_szTopName[slot], charsmax(g_szTopName[]), name);
    g_iTopXP[slot] = g_iXP[id];
    g_iTopKills[slot] = g_iKills[id];
    g_iTopInf[slot] = g_iInfects[id];
    g_iTopBoss[slot] = g_iBossK[id];

    SortTop();
    g_bTopDirty = true;
}

// HTML icin guvenli isim
HtmlName(const src[], dst[], len)
{
    copy(dst, len, src);
    replace_all(dst, len, "&", "+");
    replace_all(dst, len, "<", "(");
    replace_all(dst, len, ">", ")");
}

public cmd_top10(id)
{
    ShowTop10(id);
    return PLUGIN_HANDLED;
}

ShowTop10(id)
{
    static html[1600];
    new len, nm[40];

    len = formatex(html, charsmax(html), "<html><head><style>body{background:#06080e;color:#cfe6ff;font-family:Verdana;font-size:12px;margin:8px}h2{color:#00c8ff;text-align:center;letter-spacing:6px;margin:4px}table{width:100%%;border-collapse:collapse}th{color:#ff4670;border-bottom:1px solid #1c3550;padding:4px}td{padding:3px;text-align:center}.n{text-align:left;color:#2ee6a6}.f{text-align:center;color:#7d90a6;margin-top:8px}</style></head><body>");
    len += formatex(html[len], charsmax(html) - len, "<h2>%L</h2><table><tr><th>#<th>%L<th>Lv<th>XP<th>%L<th>%L<th>Boss", id, "TOP10_TITLE", id, "TOP10_NAME", id, "TOP10_KILLS", id, "TOP10_INF");

    new shown = min(10, g_iTopCount);
    for (new i = 0; i < shown; i++)
    {
        HtmlName(g_szTopName[i], nm, 20);
        len += formatex(html[len], charsmax(html) - len, "<tr><td>%d<td class=n>%s<td>%d<td>%d<td>%d<td>%d<td>%d",
            i + 1, nm, CalcLevel(g_iTopXP[i]), g_iTopXP[i], g_iTopKills[i], g_iTopInf[i], g_iTopBoss[i]);
    }
    len += formatex(html[len], charsmax(html) - len, "</table><div class=f>");

    if (g_iTopRank[id] > 0)
        len += formatex(html[len], charsmax(html) - len, "%L", id, "TOP10_YOU", g_iTopRank[id]);
    else if (g_iTopCount >= TOP_MAX)
        len += formatex(html[len], charsmax(html) - len, "%L", id, "TOP10_NEED", max(0, g_iTopXP[TOP_MAX - 1] - g_iXP[id] + 1));
    else
        len += formatex(html[len], charsmax(html) - len, "%L", id, "TOP10_OPEN");

    formatex(html[len], charsmax(html) - len, "</div></body></html>");
    show_motd(id, html, "VEXMIRA | TOP 10");
}

// Stil kart: kisisel istatistik penceresi
public cmd_card(id)
{
    ShowCard(id, id);
    return PLUGIN_HANDLED;
}

ShowCard(id, target)
{
    if (!is_user_connected(target))
        return;

    static html[1600];
    new len, name[40], raw[32], tname[32], jn[32], key[16];
    get_user_name(target, raw, charsmax(raw));
    HtmlName(raw, name, charsmax(name));
    TitleName(target, id, tname, charsmax(tname));
    formatex(key, charsmax(key), "JOB_%d", g_iJob[target]);
    formatex(jn, charsmax(jn), "%L", id, key);

    new lvl = g_iLevel[target];
    new base = XPForLevel(lvl), need = XPForLevel(lvl + 1);
    new pct = (lvl >= MAX_LEVEL) ? 100 : clamp((g_iXP[target] - base) * 100 / max(1, need - base), 0, 100);

    new ach;
    for (new i = 0; i < NUM_ACH; i++)
    {
        if (g_iAch[target] & (1 << i))
            ach++;
    }

    len = formatex(html, charsmax(html), "<html><head><style>body{background:#06080e;color:#cfe6ff;font-family:Verdana;font-size:12px;margin:10px}h2{color:#00c8ff;letter-spacing:4px;margin:2px 0}.t{color:#ff4670;margin-bottom:6px}.bar{background:#13202f;height:14px;border:1px solid #1c3550}.fl{background:#00c8ff;height:14px}td{padding:4px 10px}b{color:#2ee6a6}</style></head><body>");
    len += formatex(html[len], charsmax(html) - len, "<h2>%s</h2><div class=t>Lv.%d &bull; %s", name, lvl, tname);
    if (g_iTopRank[target] > 0)
        len += formatex(html[len], charsmax(html) - len, " &bull; TOP #%d", g_iTopRank[target]);
    if (IsElite(target))
        len += formatex(html[len], charsmax(html) - len, " &bull; ELITE");
    else if (IsVip(target))
        len += formatex(html[len], charsmax(html) - len, " &bull; VIP");
    len += formatex(html[len], charsmax(html) - len, "</div><div class=bar><div class=fl style=^"width:%d%%^"></div></div>XP %d / %d (%d%%)<table>", pct, g_iXP[target], need, pct);

    len += formatex(html[len], charsmax(html) - len, "<tr><td>AP <b>%d</b><td>VC <b>%d</b><td>%L <b>%s</b>", g_iAP[target], g_iVC[target], id, "CARD_JOB", jn);
    len += formatex(html[len], charsmax(html) - len, "<tr><td>%L <b>%d</b><td>%L <b>%d</b><td>HS <b>%d</b>", id, "CARD_KILLS", g_iKills[target], id, "CARD_INF", g_iInfects[target], g_iHS[target]);
    len += formatex(html[len], charsmax(html) - len, "<tr><td>%L <b>%d</b><td>%L <b>%d</b><td>%L <b>%d/%d</b>", id, "CARD_WINS", g_iWins[target], id, "CARD_BOSS", g_iBossK[target], id, "CARD_ACH", ach, NUM_ACH);
    len += formatex(html[len], charsmax(html) - len, "<tr><td>%L <b>%d:%02d</b><td>%L <b>%d</b><td>%L <b>%d</b>", id, "CARD_TIME", g_iPlaySec[target] / 3600, (g_iPlaySec[target] % 3600) / 60, id, "CARD_DAILY", g_iDailyStreak[target], id, "CARD_MAPKILLS", g_iMapKills[target]);
    formatex(html[len], charsmax(html) - len, "</table></body></html>");

    show_motd(id, html, "VEXMIRA | PROFILE");
}

// Siralamadaki ilk 3 oyuncu girince herkese haber
TopJoinAnnounce(id)
{
    new r = g_iTopRank[id];
    if (r < 1 || r > 3)
        return;

    new name[32];
    get_user_name(id, name, charsmax(name));
    for (new p = 1; p <= g_iMax; p++)
    {
        if (p != id && is_user_connected(p) && !is_user_bot(p))
            client_print_color(p, id, "%s %L", ChatTag("TOP_JOIN"), p, "TOP_JOIN", r, name);
    }
}
