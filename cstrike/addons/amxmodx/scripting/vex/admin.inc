/* ================================================================== */
/*  Vexmira Zombie - modul: vex/admin.inc  (ADMIN)                    */
/*  Admin menusu ve alt menuleri, admin konsol komutlari (mod /       */
/*  event / boss / AP / VC / XP / VIP).                               */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  KOMUTLAR                                                           */
/* ================================================================== */

/* ---------------- Admin ---------------- */

public cmd_adm_mode(id, level, cid)
{
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED;

    new arg[8];
    read_argv(1, arg, charsmax(arg));
    new m = str_to_num(arg);

    if (m < 0 || m >= MODE_TOTAL)
    {
        console_print(id, "[Vexmira] 0-%d", MODE_TOTAL - 1);
        return PLUGIN_HANDLED;
    }

    g_iForceMode = m;
    AdminNotify(id, "ADM_NEXT_MODE", m);
    return PLUGIN_HANDLED;
}

public cmd_adm_event(id, level, cid)
{
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED;

    new arg[8];
    read_argv(1, arg, charsmax(arg));
    new e = str_to_num(arg);

    if (e < 0 || e >= EV_TOTAL)
    {
        console_print(id, "[Vexmira] 0-%d", EV_TOTAL - 1);
        return PLUGIN_HANDLED;
    }

    g_iForceEvent = e;
    AdminNotify(id, "ADM_NEXT_EVENT", e);
    return PLUGIN_HANDLED;
}

AdminNotify(id, const key[], val)
{
    new name[32];
    if (id)
        get_user_name(id, name, charsmax(name));
    else
        copy(name, charsmax(name), "SERVER");

    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && (get_user_flags(p) & ADMIN_BAN))
            client_print_color(p, print_team_red, "%s %L", ChatTag(key), p, key, name, val);
    }
    console_print(id, "[Vexmira] OK (%d)", val);
}

GiveTarget(id, level, cid, type)
{
    if (!cmd_access(id, level, cid, 3))
        return;

    new who[32], amt[12];
    read_argv(1, who, charsmax(who));
    read_argv(2, amt, charsmax(amt));

    new target = cmd_target(id, who, CMDTARGET_ALLOW_SELF);
    if (!target)
        return;

    new n = str_to_num(amt);
    switch (type)
    {
        case 0: AddAP(target, n, false);
        case 1: g_iVC[target] = max(0, g_iVC[target] + n);
        case 2: Reward(target, n, 0);
    }
    SaveData(target);
    console_print(id, "[Vexmira] OK");
}

public cmd_adm_ap(id, level, cid) { GiveTarget(id, level, cid, 0); return PLUGIN_HANDLED; }
public cmd_adm_vc(id, level, cid) { GiveTarget(id, level, cid, 1); return PLUGIN_HANDLED; }
public cmd_adm_xp(id, level, cid) { GiveTarget(id, level, cid, 2); return PLUGIN_HANDLED; }


/* ================================================================== */
/*  VIP SISTEMI                                                        */
/*  Kademeler: 1 = VIP, 2 = ELITE                                      */
/*  Kaynak: users.ini bayragi (t = VIP, s = ELITE) veya sureli VIP      */
/*  (vex_vip_add komutu, nvault'ta bitis tarihiyle saklanir)           */
/* ================================================================== */

/* ---------------- Admin: sureli VIP ---------------- */

// vex_vip_add <isim | #userid | STEAM_ID> <gun> <1=VIP 2=ELITE>
public cmd_vip_add(id, level, cid)
{
    if (!cmd_access(id, level, cid, 4))
        return PLUGIN_HANDLED;

    new who[40], sdays[8], stier[4];
    read_argv(1, who, charsmax(who));
    read_argv(2, sdays, charsmax(sdays));
    read_argv(3, stier, charsmax(stier));

    new days = str_to_num(sdays);
    new tier = clamp(str_to_num(stier), 1, 2);

    if (days <= 0 || g_hVipVault == INVALID_HANDLE)
    {
        console_print(id, "[Vexmira] vex_vip_add <isim|#userid|STEAM_ID> <gun> <1|2>");
        return PLUGIN_HANDLED;
    }

    new key[48], target;
    if (equal(who, "STEAM_", 6) || equal(who, "VALVE_", 6))
        copy(key, charsmax(key), who);
    else
    {
        target = cmd_target(id, who, CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS);
        if (!target)
            return PLUGIN_HANDLED;
        GetKey(target, key, charsmax(key));
    }

    // Mevcut sureye ekle
    new val[32], base = get_systime();
    if (nvault_get(g_hVipVault, key, val, charsmax(val)))
    {
        new t[8], e[16];
        parse(val, t, charsmax(t), e, charsmax(e));
        if (str_to_num(e) > base)
            base = str_to_num(e);
    }

    new expire = base + clamp(days, 1, 3650) * 86400;
    formatex(val, charsmax(val), "%d %d", tier, expire);
    nvault_set(g_hVipVault, key, val);

    new aname[32];
    if (id) get_user_name(id, aname, charsmax(aname)); else copy(aname, charsmax(aname), "CONSOLE");
    log_to_file("vexmira_vip.log", "VIP EKLENDI: %s tier=%d gun=%d bitis=%d (admin: %s)", key, tier, days, expire, aname);
    console_print(id, "[Vexmira] VIP OK: %s  tier %d  +%d gun", key, tier, days);

    if (target && is_user_connected(target))
    {
        LoadVip(target);
        Chat(target, "VIP_GRANTED", days);
        VipWelcome(target);
    }
    return PLUGIN_HANDLED;
}

public cmd_vip_remove(id, level, cid)
{
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED;

    new who[40], key[48], target;
    read_argv(1, who, charsmax(who));

    if (equal(who, "STEAM_", 6) || equal(who, "VALVE_", 6))
        copy(key, charsmax(key), who);
    else
    {
        target = cmd_target(id, who, CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS);
        if (!target)
            return PLUGIN_HANDLED;
        GetKey(target, key, charsmax(key));
    }

    if (g_hVipVault != INVALID_HANDLE)
        nvault_remove(g_hVipVault, key);

    log_to_file("vexmira_vip.log", "VIP SILINDI: %s", key);
    console_print(id, "[Vexmira] VIP silindi: %s", key);

    if (target)
        LoadVip(target);
    return PLUGIN_HANDLED;
}

public cmd_vip_list(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;

    console_print(id, "[Vexmira] Online VIP listesi:");
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || !IsVip(p))
            continue;
        new name[32];
        get_user_name(p, name, charsmax(name));
        if (g_iVipExpire[p])
            console_print(id, "  %s  tier %d  kalan %d gun", name, g_iVip[p], (g_iVipExpire[p] - get_systime()) / 86400);
        else
            console_print(id, "  %s  tier %d  (kalici / users.ini)", name, g_iVip[p]);
    }
    return PLUGIN_HANDLED;
}


/* ================================================================== */
/*  ADMIN MENUSU                                                       */
/* ================================================================== */

public cmd_adminmenu(id)
{
    ShowAdminMenu(id);
    return PLUGIN_HANDLED;
}

ShowAdminMenu(id)
{
    if (!(get_user_flags(id) & ADMIN_BAN))
        return;

    new title[192], item[96];
    formatex(title, charsmax(title), "%s \r%L^n\d%L^n", MENU_TAG, id, "MENU_ADMIN", id, "MENU_ADMIN_SUB");
    new menu = menu_create(title, "menu_admin_handler");

    for (new i = 1; i <= 20; i++)
    {
        new key[12];
        formatex(key, charsmax(key), "ADMM_%d", i);
        formatex(item, charsmax(item), "\y%L", id, key);
        if (i == 17)
            add(item, charsmax(item), g_bRespawnOff ? " \r[OFF]" : " \w[ON]");
        else if (i == 18)
            add(item, charsmax(item), get_pcvar_num(g_pLmEnable) ? " \w[ON]" : " \r[OFF]");
        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_admin_handler(id, menu, item)
{
    if (item < 0 || !(get_user_flags(id) & ADMIN_BAN))
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    new name[32];
    get_user_name(id, name, charsmax(name));
    log_to_file("vexmira_admin.log", "%s -> admin menu #%d", name, sel);

    switch (sel)
    {
        case 1: ShowAdminModeMenu(id, false);
        case 2: ShowAdminModeMenu(id, true);
        case 3: ShowAdminEventMenu(id, false);
        case 4: ShowAdminEventMenu(id, true);
        case 5: ShowAdminBossMenu(id, false);
        case 6: ShowAdminBossMenu(id, true);
        case 7: ShowAdminPlayers(id);
        case 8: ShowAdminEnvMenu(id);
        case 9: StartVote(id, 1);
        case 10: StartVote(id, 2);
        case 11:
        {
            AdminNotify(id, "ADM_RESTART", 0);
            rg_round_end(2.0, WINSTATUS_DRAW, ROUND_END_DRAW, "", "", false);
        }
        case 12, 13:
        {
            if (g_bRoundActive && !g_bRoundEnded)
            {
                AdminNotify(id, sel == 12 ? "ADM_END_HUMANS" : "ADM_END_ZOMBIES", 0);
                EndRound(sel == 12 ? WINSTATUS_CTS : WINSTATUS_TERRORISTS);
            }
            else
                Chat(id, "ADM_NOT_ACTIVE");
        }
        case 14:
        {
            if (g_bRoundActive && g_szDropModel[0])
            {
                SpawnAirdrop();
                AdminNotify(id, "ADM_AIRDROP", 0);
            }
            else
                Chat(id, "ADM_NOT_ACTIVE");
        }
        case 15:
        {
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_alive(p) || g_bZombie[p])
                    continue;
                g_bNadesGiven[p] = false;
                GiveStartNades(p);
                if (LasersAllowed())
                    g_iMines[p] = max(g_iMines[p], RoundMines(p));
            }
            AdminNotify(id, "ADM_GAVE_NADES", 0);
            PlayKey(0, "AIRDROP_LOOT");
        }
        case 16:
        {
            for (new p = 1; p <= g_iMax; p++)
            {
                if (is_user_connected(p) && !is_user_bot(p))
                    AddAP(p, 50, false, true);
            }
            FunAll(id, "ADM_GIFT_ALL", name, 50);
            PlayKey(0, "DAILY");
        }
        case 17:
        {
            g_bRespawnOff = !g_bRespawnOff;
            AdminNotify(id, g_bRespawnOff ? "ADM_RESPAWN_OFF" : "ADM_RESPAWN_ON", 0);
        }
        case 18:
        {
            new on = get_pcvar_num(g_pLmEnable) ? 0 : 1;
            set_pcvar_num(g_pLmEnable, on);
            if (!on)
                RemoveAllMines();
            AdminNotify(id, on ? "ADM_LASER_ON" : "ADM_LASER_OFF", 0);
        }
        case 19:
        {
            new n = LoadMainConfig(false);
            AdminNotify(id, "ADM_RELOADED", n);
        }
        // v3.0 (C): harita oylamasi (kazanan harita bu round bitince gelir)
        case 20: AdminStartMapVote(id, true);
    }
    if (sel >= 11 && sel != 20)
        ShowAdminMenu(id);
    return PLUGIN_HANDLED;
}

/* ---------------- Admin: hava / isik (hemen) ---------------- */

ShowAdminEnvMenu(id)
{
    new title[128], item[96], key[16];
    formatex(title, charsmax(title), "%s \r%L^n", MENU_TAG, id, "ADMM_8");
    new menu = menu_create(title, "menu_admenv");
    for (new i = 0; i <= 9; i++)
    {
        formatex(key, charsmax(key), "ADME_%d", i);
        formatex(item, charsmax(item), "\y%L", id, key);
        MenuAdd(menu, item, i);
    }
    MenuFinish(id, menu);
}

public menu_admenv(id, menu, item)
{
    if (item < 0 || !(get_user_flags(id) & ADMIN_BAN)) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new sel = MenuInfo(menu, item);
    menu_destroy(menu);
    AdminSetEnv(sel);
    AdminNotify(id, "ADM_ENV_SET", sel);
    ShowAdminEnvMenu(id);
    return PLUGIN_HANDLED;
}

// 0 sifirla, 1 gunduz, 2 alacakaranlik, 3 gece, 4 yagmur, 5 kar, 6 sis, 7 firtina, 8 kan, 9 zifiri karanlik
AdminSetEnv(sel)
{
    if (sel <= 0)
    {
        ApplyWorldEvent();
        return;
    }
    static const L[10] = { 'm', 'm', 'h', 'c', 'i', 'k', 'g', 'e', 'c', 'a' };
    static const F[10][4] =
    {
        {0, 0, 0, 0}, {0, 0, 0, 0}, {90, 50, 30, 12}, {0, 0, 30, 20}, {70, 80, 90, 20},
        {180, 190, 210, 22}, {150, 150, 150, 45}, {60, 70, 90, 35}, {100, 0, 10, 30}, {0, 0, 0, 40}
    };
    static const W[10] = { 0, 0, 0, 0, 1, 2, 0, 1, 0, 0 };
    g_szLight[0] = L[sel];
    g_szLight[1] = 0;
    engfunc(EngFunc_LightStyle, 0, g_szLight);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        SendWeather(p, W[sel]);
        if (!(g_iSet[p] & SET_NO_FOG))
            SendFogEx(p, F[sel][0], F[sel][1], F[sel][2], F[sel][3]);
    }
    if (sel == 7)
        Lightning();
}

// now = true -> modu hemen baslat (round yeniden baslar)
ShowAdminModeMenu(id, bool:now)
{
    new title[192], item[96], key[16];
    formatex(title, charsmax(title), "%s \r%L^n", MENU_TAG, id, now ? "ADMM_2" : "ADMM_1");
    new menu = menu_create(title, now ? "menu_admmode_now" : "menu_admmode_next");

    for (new m = 0; m < MODE_TOTAL; m++)
    {
        formatex(key, charsmax(key), "MODE_NAME_%d", m);
        formatex(item, charsmax(item), "\y%L", id, key);
        MenuAdd(menu, item, m);
    }
    MenuFinish(id, menu);
}

public menu_admmode_next(id, menu, item)
{
    if (item < 0) { menu_destroy(menu); return PLUGIN_HANDLED; }
    g_iForceMode = MenuInfo(menu, item);
    menu_destroy(menu);
    AdminNotify(id, "ADM_NEXT_MODE", g_iForceMode);
    if (g_iForceMode == MODE_BOSS)
        ShowAdminBossMenu(id, false);
    return PLUGIN_HANDLED;
}

public menu_admmode_now(id, menu, item)
{
    if (item < 0) { menu_destroy(menu); return PLUGIN_HANDLED; }
    g_iForceMode = MenuInfo(menu, item);
    menu_destroy(menu);
    AdminNotify(id, "ADM_NOW_MODE", g_iForceMode);
    if (g_iForceMode == MODE_BOSS)
    {
        ShowAdminBossMenu(id, true);
        return PLUGIN_HANDLED;
    }
    rg_round_end(2.0, WINSTATUS_DRAW, ROUND_END_DRAW, "", "", false);
    return PLUGIN_HANDLED;
}

// Hangi boss gelsin? (rastgele veya secili)
ShowAdminBossMenu(id, bool:now)
{
    new title[128], item[96], key[16];
    formatex(title, charsmax(title), "%s \r%L^n", MENU_TAG, id, "ADM_BOSS_PICK");
    new menu = menu_create(title, now ? "menu_admboss_now" : "menu_admboss_next");

    formatex(item, charsmax(item), "\y%L", id, "ADM_BOSS_RANDOM");
    MenuAdd(menu, item, 99);
    // v3.0: sadece bu haritada yuklenen bosslar (digerlerinin modeli / sesi yok)
    for (new b = 0; b < NUM_BOSSES; b++)
    {
        if (!BossIsLoaded(b))
            continue;
        formatex(key, charsmax(key), "BOSS_NAME_%d", b);
        formatex(item, charsmax(item), "\y%L", id, key);
        MenuAdd(menu, item, b);
    }
    MenuFinish(id, menu);
}

public menu_admboss_next(id, menu, item)
{
    if (item < 0) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new b = MenuInfo(menu, item);
    menu_destroy(menu);
    g_iForceBoss = (b == 99) ? -1 : b;
    g_iForceMode = MODE_BOSS;
    AdminNotify(id, "ADM_NEXT_BOSS", b == 99 ? -1 : b);
    return PLUGIN_HANDLED;
}

public menu_admboss_now(id, menu, item)
{
    if (item < 0) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new b = MenuInfo(menu, item);
    menu_destroy(menu);
    g_iForceBoss = (b == 99) ? -1 : b;
    g_iForceMode = MODE_BOSS;
    AdminNotify(id, "ADM_NOW_BOSS", b == 99 ? -1 : b);
    rg_round_end(2.0, WINSTATUS_DRAW, ROUND_END_DRAW, "", "", false);
    return PLUGIN_HANDLED;
}

public cmd_adm_boss(id, level, cid)
{
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED;

    new arg[8];
    read_argv(1, arg, charsmax(arg));
    new b = str_to_num(arg);
    if (b < -1 || b >= NUM_BOSSES)
    {
        console_print(id, "[Vexmira] -1 .. %d", NUM_BOSSES - 1);
        return PLUGIN_HANDLED;
    }
    if (b >= 0 && !BossIsLoaded(b))
    {
        new list[64], nm[8];
        for (new i = 0; i < g_iBossLoadN; i++)
        {
            formatex(nm, charsmax(nm), "%s%d", i ? " " : "", g_iBossLoadList[i]);
            add(list, charsmax(list), nm);
        }
        console_print(id, "[Vexmira] Boss %d bu haritada yuklu degil (precache butcesi). Yuklu: %s  (vex_res BOSS_PRELOAD_LIST)", b, list);
        return PLUGIN_HANDLED;
    }
    g_iForceBoss = b;
    g_iForceMode = MODE_BOSS;
    AdminNotify(id, "ADM_NEXT_MODE", MODE_BOSS);
    return PLUGIN_HANDLED;
}

ShowAdminEventMenu(id, bool:now)
{
    new title[192], item[96], key[16];
    formatex(title, charsmax(title), "%s \r%L^n", MENU_TAG, id, now ? "ADMM_4" : "ADMM_3");
    new menu = menu_create(title, now ? "menu_admevent_now" : "menu_admevent");

    for (new e = 1; e < EV_TOTAL; e++)
    {
        formatex(key, charsmax(key), "EV_NAME_%d", e);
        formatex(item, charsmax(item), "\y%L", id, key);
        MenuAdd(menu, item, e);
    }
    MenuFinish(id, menu);
}

public menu_admevent(id, menu, item)
{
    if (item < 0) { menu_destroy(menu); return PLUGIN_HANDLED; }
    g_iForceEvent = MenuInfo(menu, item);
    menu_destroy(menu);
    AdminNotify(id, "ADM_NEXT_EVENT", g_iForceEvent);
    return PLUGIN_HANDLED;
}

// Event hemen: round yeniden baslar, normal enfeksiyon + secilen event
public menu_admevent_now(id, menu, item)
{
    if (item < 0) { menu_destroy(menu); return PLUGIN_HANDLED; }
    g_iForceEvent = MenuInfo(menu, item);
    g_iForceMode = MODE_INFECTION;
    menu_destroy(menu);
    AdminNotify(id, "ADM_NOW_EVENT", g_iForceEvent);
    rg_round_end(2.0, WINSTATUS_DRAW, ROUND_END_DRAW, "", "", false);
    return PLUGIN_HANDLED;
}

/* ---------------- Oyuncu islemleri ---------------- */

ShowAdminPlayers(id)
{
    new title[192], item[96], name[32];
    formatex(title, charsmax(title), "%s \r%L^n", MENU_TAG, id, "ADMM_4");
    new menu = menu_create(title, "menu_admplayers");

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p))
            continue;
        get_user_name(p, name, charsmax(name));
        formatex(item, charsmax(item), "\y%s \r[\w%s%s\r]", name, g_bZombie[p] ? "Z" : "H", IsVip(p) ? (IsElite(p) ? " ELITE" : " VIP") : "");
        MenuAdd(menu, item, get_user_userid(p));
    }
    MenuFinish(id, menu);
}

public menu_admplayers(id, menu, item)
{
    if (item < 0) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new uid = MenuInfo(menu, item);
    menu_destroy(menu);

    new target = find_player_ex(FindPlayer_MatchUserId, uid);
    if (!target)
    {
        Chat(id, "ADM_GONE");
        return PLUGIN_HANDLED;
    }
    g_iAdmTarget[id] = uid;
    ShowAdminActions(id);
    return PLUGIN_HANDLED;
}

ShowAdminActions(id)
{
    new target = find_player_ex(FindPlayer_MatchUserId, g_iAdmTarget[id]);
    if (!target || !is_user_connected(target))
    {
        Chat(id, "ADM_GONE");
        return;
    }

    new title[192], item[96], name[32];
    get_user_name(target, name, charsmax(name));
    formatex(title, charsmax(title), "%s \r%L^n\w%s \d|| Lv.%d \d|| %d AP \d|| %d VC^n", MENU_TAG, id, "ADMM_4", name, g_iLevel[target], g_iAP[target], g_iVC[target]);
    new menu = menu_create(title, "menu_admactions");

    for (new i = 1; i <= 17; i++)
    {
        new key[12];
        formatex(key, charsmax(key), "ADMA_%d", i);
        formatex(item, charsmax(item), "\y%L", id, key);
        MenuAdd(menu, item, i);
    }
    MenuFinish(id, menu);
}

public menu_admactions(id, menu, item)
{
    if (item < 0) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    new target = find_player_ex(FindPlayer_MatchUserId, g_iAdmTarget[id]);
    if (!target || !is_user_connected(target) || !(get_user_flags(id) & ADMIN_BAN))
    {
        Chat(id, "ADM_GONE");
        return PLUGIN_HANDLED;
    }

    // VC / XP / VIP verme RCON (owner) yetkisi ister
    if ((sel == 2 || sel == 3 || (sel >= 10 && sel <= 12)) && !(get_user_flags(id) & ADMIN_RCON))
    {
        Chat(id, "ADM_NEED_OWNER");
        ShowAdminActions(id);
        return PLUGIN_HANDLED;
    }

    new bool:alive = is_user_alive(target) ? true : false;
    new aname[32], tname[32], key[16];
    get_user_name(id, aname, charsmax(aname));
    get_user_name(target, tname, charsmax(tname));
    formatex(key, charsmax(key), "ADMA_%d", sel);

    switch (sel)
    {
        case 1: AddAP(target, 100, false, true);
        case 2: g_iVC[target] += 10;
        case 3: Reward(target, 1000, 0);
        case 4: if (alive && !g_bZombie[target] && g_bRoundActive) { MakeZombie(target); CheckWin(); }
        case 5: if (alive && g_bZombie[target] && g_bRoundActive) { MakeHuman(target); CheckWin(); }
        case 6: if (alive && g_bRoundActive) { ClearZombieRoles(target); g_bSurvivor[target] = 0; g_bSniper[target] = 0; g_bNemesis[target] = 1; MakeZombie(target); CheckWin(); }
        case 7: if (alive && g_bRoundActive) { MakeSurvivor(target, false); CheckWin(); }
        case 8:
        {
            if (!alive)
            {
                rg_set_user_team(target, g_bZombie[target] ? TEAM_TERRORIST : TEAM_CT, MODEL_UNASSIGNED, true, false);
                g_bForceZombie[target] = g_bZombie[target];
                rg_round_respawn(target);
            }
        }
        case 9: if (alive) user_kill(target, 1);
        case 10, 11: GiveVipDays(id, target, 30, sel == 10 ? 1 : 2);
        case 12:
        {
            new k[48];
            GetKey(target, k, charsmax(k));
            if (g_hVipVault != INVALID_HANDLE)
                nvault_remove(g_hVipVault, k);
            LoadVip(target);
        }
        case 13: if (alive && g_bRoundActive) { ClearZombieRoles(target); g_bSurvivor[target] = 0; g_bSniper[target] = 0; g_bAssassin[target] = 1; MakeZombie(target); CheckWin(); }
        case 14: if (alive && g_bRoundActive) { MakeSurvivor(target, true); CheckWin(); }
        case 15: if (alive && !g_bZombie[target]) { g_iMines[target] += 3; Chat(target, "LM_GIFT", 3); }
        case 16: if (alive && !g_bZombie[target]) { g_bNadesGiven[target] = false; GiveStartNades(target); }
        case 17:
        {
            if (alive)
            {
                g_fFrozen[target] = get_gametime() + 5.0;
                set_entvar(target, var_velocity, Float:{0.0, 0.0, 0.0});
                rg_reset_maxspeed(target);
                ApplyRender(target);
            }
        }
    }

    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && (get_user_flags(p) & ADMIN_BAN))
        {
            new act[48];
            formatex(act, charsmax(act), "%L", p, key);
            client_print_color(p, id, "%s %L", ChatTag("ADM_ACTION"), p, "ADM_ACTION", aname, tname, act);
        }
    }
    log_to_file("vexmira_admin.log", "%s -> %s : %s", aname, tname, key);

    SaveData(target);
    ShowAdminActions(id);
    return PLUGIN_HANDLED;
}

GiveVipDays(admin, target, days, tier)
{
    if (g_hVipVault == INVALID_HANDLE)
        return;

    new key[48], val[32], base = get_systime();
    GetKey(target, key, charsmax(key));

    if (nvault_get(g_hVipVault, key, val, charsmax(val)))
    {
        new t[8], e[16];
        parse(val, t, charsmax(t), e, charsmax(e));
        if (str_to_num(e) > base)
            base = str_to_num(e);
    }

    formatex(val, charsmax(val), "%d %d", tier, base + clamp(days, 1, 3650) * 86400);
    nvault_set(g_hVipVault, key, val);

    new aname[32];
    get_user_name(admin, aname, charsmax(aname));
    log_to_file("vexmira_vip.log", "VIP (menu): %s tier=%d gun=%d (admin: %s)", key, tier, days, aname);

    LoadVip(target);
    Chat(target, "VIP_GRANTED", days);
    VipWelcome(target);
}
