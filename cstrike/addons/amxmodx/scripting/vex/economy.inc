/* ================================================================== */
/*  Vexmira Zombie - modul: vex/economy.inc  (EKONOMI)                */
/*  AP / VC / XP odulleri, market (esya), ozel silah satin alma,      */
/*  kalici yetenekler (perk), VIP / ELITE, kozmetikler (iz, oldurme   */
/*  / enfeksiyon efekti).                                             */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  EKONOMI: XP / LEVEL / AP / VC / BASARIM                            */
/* ================================================================== */

// AP carpani: meslek, VIP, perk, event
Float:APMult(id)
{
    new Float:m = 1.0;
    if (g_iJob[id] == JOB_LOOTER)
        m += 0.5;
    if (IsElite(id))
        m += 0.50;
    else if (IsVip(id))
        m += 0.25;
    m += 0.10 * float(g_iPerk[id][PK_FORTUNE]);
    if (g_iEvent == EV_GOLDRUSH)
        m *= 2.0;
    return m;
}

AddAP(id, amount, bool:mult = true, bool:show = true)
{
    if (!is_user_connected(id) || amount == 0)
        return;

    if (mult && amount > 0 && g_iJob[id] == JOB_GAMBLER && random_num(1, 100) <= 10)
        amount *= 2;

    if (mult && amount > 0)
        amount = max(1, floatround(float(amount) * APMult(id)));

    g_iAP[id] = max(0, g_iAP[id] + amount);
    if (amount > 0)
        g_iRoundAP[id] += amount;

    SyncMoney(id);

    if (show && amount > 0 && !is_user_bot(id))
    {
        set_hudmessage(CLR_REWARD, 0.535, 0.47, 0, 0.0, 0.9, 0.05, 0.25, 4);
        show_hudmessage(id, "+%d AP", amount);
    }
}

// AP'yi CS para gostergesinde goster
SyncMoney(id)
{
    if (!is_user_connected(id) || is_user_hltv(id))
        return;
    // Bot / yeni baglanan oyuncuda ozel veri henuz hazir olmayabilir (client_putinserver)
    if (pev_valid(id) != 2)
        return;

    new TeamName:t = get_member(id, m_iTeam);
    if (t == TEAM_TERRORIST || t == TEAM_CT)
        rg_add_account(id, min(g_iAP[id], 999999), AS_SET, false);
}

Reward(id, xp, ap)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    if (IsElite(id))
        xp = xp * 3 / 2;
    else if (IsVip(id))
        xp = xp * 5 / 4;
    if (g_iEvent == EV_GOLDRUSH)
        xp *= 2;

    new old = g_iLevel[id];
    g_iXP[id] = max(0, g_iXP[id] + xp);
    g_iRoundXP[id] += xp;
    g_iLevel[id] = CalcLevel(g_iXP[id]);

    if (ap > 0)
        AddAP(id, ap, true, false);

    if (xp > 0 || ap > 0)
    {
        new txt[48];
        if (ap > 0)
            formatex(txt, charsmax(txt), "+%d XP   +%d AP", xp, max(1, floatround(float(ap) * APMult(id))));
        else
            formatex(txt, charsmax(txt), "+%d XP", xp);
        HudText(id, SL_REWARD, CLR_REWARD, 1.0, txt);
    }

    if (g_iLevel[id] > old)
        LevelUp(id, old);

    CheckAch(id);
}


/* ================================================================== */
/*  MENULER                                                            */
/* ================================================================== */

/* ---------------- Market ---------------- */

ShowShopMenu(id)
{
    new title[128], item[160], k1[12], k2[16], n1[40], n2[64];
    new isZ = g_bZombie[id] ? 1 : 0;

    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, isZ ? "MENU_SHOP_Z" : "MENU_SHOP_H", id, "MENU_WALLET_AP", g_iAP[id]);
    new menu = menu_create(title, "menu_shop_handler");

    for (new i = 0; i < NUM_ITEMS; i++)
    {
        if (ITEM_TEAM[i] != isZ)
            continue;

        new cost = ItemPrice(id, i);

        formatex(k1, charsmax(k1), "ITEM_%d", i);
        formatex(k2, charsmax(k2), "ITEM_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        if (g_iLevel[id] < ITEM_LVL[i])
            formatex(item, charsmax(item), "\d%s \r[\wLv.%d\r] \d%s", n1, ITEM_LVL[i], n2);
        else if (ITEM_LIMIT[i] && g_iBought[id][i] >= ITEM_LIMIT[i])
            formatex(item, charsmax(item), "\d%s \r[\w%L\r]", n1, id, "SHOP_SOLDOUT");
        else if (g_iAP[id] >= cost)
            formatex(item, charsmax(item), "\y%s \r[\w%d AP\r] \d%s", n1, cost, n2);
        else
            formatex(item, charsmax(item), "\d%s \r[\d%d AP\r] \d%s", n1, cost, n2);

        MenuAdd(menu, item, i);
    }

    if (!isZ)
    {
        formatex(item, charsmax(item), "\r%L", id, "SHOP_EXCHANGE", max(1, get_pcvar_num(g_pExchange)));
        MenuAdd(menu, item, 100);
    }

    MenuFinish(id, menu);
}

ItemPrice(id, i)
{
    new cost = ITEM_COST[i];
    if (g_iJob[id] == JOB_ENGINEER)
        cost = cost * 3 / 4;
    if (IsElite(id))
        cost = cost * 8 / 10;
    else if (IsVip(id))
        cost = cost * 9 / 10;
    if (i == IT_MEDKIT && g_iJob[id] == JOB_MEDIC)
        cost /= 2;
    return max(1, cost);
}

public menu_shop_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    if (sel == 100)
        Exchange(id);
    else
        BuyItem(id, sel);

    ShowShopMenu(id);
    return PLUGIN_HANDLED;
}

Exchange(id)
{
    new xc = max(1, get_pcvar_num(g_pExchange));
    if (g_iAP[id] < xc)
    {
        Chat(id, "SHOP_NOAP");
        return;
    }
    AddAP(id, -xc, false, false);
    g_iVC[id] += 1;
    PlayKey(id, "SHOP_BUY");
    Chat(id, "SHOP_EXCHANGED");
}

BuyItem(id, i)
{
    new isZ = g_bZombie[id] ? 1 : 0;
    new bool:dead = !is_user_alive(id);
    new Float:now = get_gametime();

    // Respawn jetonu olu iken alinir (sadece takimdaki oyuncular, izleyici degil)
    if (i == IT_RESPAWN)
    {
        new TeamName:myt = get_member(id, m_iTeam);
        if (!dead || g_bZombie[id] || !g_bRoundActive || !AllowsInfection() || RoundTimeLeft() < 60
            || (myt != TEAM_TERRORIST && myt != TEAM_CT))
        {
            Chat(id, "SHOP_UNAVAIL");
            return;
        }
    }
    else if (dead || ITEM_TEAM[i] != isZ || g_bBoss[id] || g_bMinion[id] || g_bNemesis[id] || g_bAssassin[id] || g_bSurvivor[id] || g_bSniper[id])
    {
        Chat(id, "SHOP_UNAVAIL");
        return;
    }

    if (g_iLevel[id] < ITEM_LVL[i])
    {
        Chat(id, "NEED_LEVEL", ITEM_LVL[i]);
        return;
    }

    if (ITEM_LIMIT[i] && g_iBought[id][i] >= ITEM_LIMIT[i])
    {
        Chat(id, "SHOP_LIMIT");
        return;
    }

    new val = ITEM_VAL[i];

    new cost = ItemPrice(id, i);
    if (g_iAP[id] < cost)
    {
        Chat(id, "SHOP_NOAP");
        return;
    }

    switch (i)
    {
        case IT_MEDKIT:
        {
            new mx = MaxHumanHP(id) + max(1, val);
            if (Float:get_entvar(id, var_health) >= float(mx))
            {
                Chat(id, "SHOP_ALREADY");
                return;
            }
            HealTo(id, max(1, val), mx);
        }
        case IT_ARMOR:    rg_set_user_armor(id, clamp(val, 1, 999), ARMOR_VESTHELM);
        case IT_FIRENADE:
        {
            for (new k = 0; k < max(1, val); k++)
            {
                g_iFireNades[id]++;
                GiveNadeStack(id, "weapon_hegrenade", WEAPON_HEGRENADE);
            }
        }
        case IT_FROSTNADE:
        {
            for (new k = 0; k < max(1, val); k++)
            {
                g_iFrostNades[id]++;
                GiveNadeStack(id, "weapon_smokegrenade", WEAPON_SMOKEGRENADE);
            }
        }
        case IT_FLARE:
        {
            for (new k = 0; k < max(1, val); k++)
            {
                g_iFlares[id]++;
                GiveNadeStack(id, "weapon_flashbang", WEAPON_FLASHBANG);
            }
        }
        case IT_DJUMP:
        {
            // Ekstra ziplama sadece VIP'lere ozel
            if (!IsVip(id)) { Chat(id, "VIP_ONLY"); return; }
            g_iExtraJumps[id] += max(1, val);
        }
        case IT_BOOTS:
        {
            g_bBoots[id] = 1;
            ApplyHumanGravity(id);
        }
        case IT_SERUM:
        {
            g_bSerum[id] = 1;
            rg_reset_maxspeed(id);
        }
        case IT_UNLCLIP:  g_bUnlClip[id] = 1;
        case IT_DMGAMP:   g_bDmgAmp[id] = 1;
        case IT_RESPAWN:
        {
            g_fRespawnAt[id] = 0.0;
            rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED, true, false);
            rg_round_respawn(id);
        }
        case IT_ANTIDOTE:
        {
            if (CountZombies(true) <= 1 || now - g_fInfectTime[id] < 5.0)
            {
                Chat(id, "SHOP_UNAVAIL");
                return;
            }
            MakeHuman(id);
        }
        case IT_MADNESS:
        {
            g_fMadness[id] = now + float(max(1, val));
            ApplyRender(id);
            EmitKey(id, "MADNESS");
        }
        case IT_INFBOMB:
        {
            if (!AllowsInfection() || g_iGlobalInfBombs >= max(1, val))
            {
                Chat(id, "SHOP_UNAVAIL");
                return;
            }
            g_iGlobalInfBombs++;
            g_iInfNades[id]++;
            rg_give_item(id, "weapon_hegrenade");
        }
        case IT_MUTAGEN:
        {
            g_iMaxHP[id] += max(1, val);
            set_entvar(id, var_health, Float:get_entvar(id, var_health) + float(max(1, val)));
        }
        case IT_RAGE:
        {
            if (g_bRage[id]) { Chat(id, "SHOP_ALREADY"); return; }
            g_bRage[id] = 1;
            rg_reset_maxspeed(id);
        }
        case IT_RECHARGE: g_fCool[id] = 0.0;
        case IT_ZARMOR:
        {
            if (g_bZArmor[id]) { Chat(id, "SHOP_ALREADY"); return; }
            g_bZArmor[id] = 1;
        }
        case IT_ADREN:
        {
            g_fHBoost[id] = now + float(max(1, val));
            rg_reset_maxspeed(id);
            FadeOne(id, 255, 255, 0, 60, 0.6);
        }
        case IT_HCLOAK:
        {
            g_fCloak[id] = now + float(max(1, val));
            ApplyRender(id);
        }
        case IT_NVG:
        {
            if (get_member(id, m_bHasNightVision)) { Chat(id, "SHOP_ALREADY"); return; }
            set_member(id, m_bHasNightVision, true);
        }
        case IT_ESHIELD:
        {
            g_iEShield[id] = max(1, val);
            set_user_rendering(id, kRenderFxGlowShell, 0, 255, 255, kRenderNormal, 18);
        }
        case IT_AMMO:
        {
            RefillAmmo(id);
            new sw = g_iSpecW[id];
            for (new s = 0; s < NUM_SPECIAL; s++)
            {
                if (sw & (1 << s))
                    rg_set_user_bpammo(id, SW_BASE_ID[s], SW_BPAMMO[s]);
            }
        }
        case IT_ZSPRINT:
        {
            g_fBurst[id] = now + float(max(1, val));
            rg_reset_maxspeed(id);
        }
        case IT_ZCLOAK:
        {
            g_fCloak[id] = now + float(max(1, val));
            ApplyRender(id);
        }
        // v3.1: kayitli (dogru) yercekiminden hesaplanir; anlik deger parasut vb. ile bozuk olabilir
        case IT_ZJUMP:   SetGravity(id, (g_fGrav[id] > 0.0 ? g_fGrav[id] : Float:get_entvar(id, var_gravity)) * float(clamp(val, 10, 100)) / 100.0);
        case IT_ZREGEN:  g_bZRegen[id] = 1;
        case IT_ZNOKB:   g_bNoKB[id] = 1;
    }

    g_iBought[id][i]++;
    AddAP(id, -cost, false, false);
    PlayKey(id, "SHOP_BUY");

    new key[12], nm[40];
    formatex(key, charsmax(key), "ITEM_%d", i);
    formatex(nm, charsmax(nm), "%L", id, key);
    Chat(id, "SHOP_BOUGHT", nm, cost);

    if (ITEM_ANNOUNCE[i])
        AnnounceBuy(id, key);
}

// "X, Y satin aldi!" - herkese kendi dilinde
AnnounceBuy(id, const itemKey[])
{
    new name[32], nm[48];
    get_user_name(id, name, charsmax(name));

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p) || p == id)
            continue;
        formatex(nm, charsmax(nm), "%L", p, itemKey);
        client_print_color(p, id, "%s %L", CHAT_PREFIX, p, g_bZombie[id] ? "BUY_ALL_Z" : "BUY_ALL_H", name, nm);
    }
}

/* ---------------- Ozel silahlar ---------------- */

ShowSpecialMenu(id)
{
    new title[128], item[160], k1[12], k2[16], n1[40], n2[64];

    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MENU_SPECIAL", id, "MENU_WALLET_AP", g_iAP[id]);
    new menu = menu_create(title, "menu_special_handler");

    for (new i = 0; i < NUM_SPECIAL; i++)
    {
        formatex(k1, charsmax(k1), "SW_%d", i);
        formatex(k2, charsmax(k2), "SW_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        if (g_iLevel[id] < SW_LVL[i])
            formatex(item, charsmax(item), "\d%s \r[\wLv.%d\r]", n1, SW_LVL[i]);
        else if (g_iSpecW[id] & (1 << i))
            formatex(item, charsmax(item), "\y%s \r[\w%L\r]", n1, id, "OWNED");
        else
            formatex(item, charsmax(item), "%s%s \r[\w%d AP\r] \d%s", g_iAP[id] >= SwPrice(id, i) ? "\y" : "\d", n1, SwPrice(id, i), n2);

        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

SwPrice(id, i)
{
    new c = SW_COST[i];
    if (IsElite(id))
        c = c * 8 / 10;
    else if (IsVip(id))
        c = c * 9 / 10;
    return c;
}

public menu_special_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new i = MenuInfo(menu, item);
    menu_destroy(menu);

    if (!is_user_alive(id) || g_bZombie[id] || g_bSurvivor[id] || g_bSniper[id])
    {
        Chat(id, "SHOP_UNAVAIL");
        return PLUGIN_HANDLED;
    }
    if (g_iLevel[id] < SW_LVL[i])
    {
        Chat(id, "NEED_LEVEL", SW_LVL[i]);
        return PLUGIN_HANDLED;
    }
    if (g_iSpecW[id] & (1 << i))
    {
        Chat(id, "SHOP_ALREADY");
        return PLUGIN_HANDLED;
    }
    if (g_iAP[id] < SwPrice(id, i))
    {
        Chat(id, "SHOP_NOAP");
        return PLUGIN_HANDLED;
    }

    // Ayni slottaki diger ozel silahi kaldir
    new bool:pistol = (SW_BASE_ID[i] == WEAPON_DEAGLE) ? true : false;
    for (new s = 0; s < NUM_SPECIAL; s++)
    {
        if ((SW_BASE_ID[s] == WEAPON_DEAGLE) == pistol)
            g_iSpecW[id] &= ~(1 << s);
    }

    g_iSpecW[id] |= (1 << i);
    rg_give_item(id, SW_BASE_ENT[i], GT_REPLACE);
    rg_set_user_bpammo(id, SW_BASE_ID[i], SW_BPAMMO[i]);
    engclient_cmd(id, SW_BASE_ENT[i]);

    AddAP(id, -SwPrice(id, i), false, false);
    PlayKey(id, "SHOP_BUY");

    new Float:o[3];
    get_entvar(id, var_origin, o);
    FxRing(o, SW_RGB[i][0], SW_RGB[i][1], SW_RGB[i][2], 180);

    new key[12], nm[40];
    formatex(key, charsmax(key), "SW_%d", i);
    formatex(nm, charsmax(nm), "%L", id, key);
    Chat(id, "SW_BOUGHT", nm);
    AnnounceBuy(id, key);
    return PLUGIN_HANDLED;
}

/* ---------------- Kalici yetenekler (perk) ---------------- */

ShowPerkMenu(id)
{
    new title[128], item[160], k1[12], k2[16], n1[32], n2[64];

    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MENU_PERKS", id, "MENU_WALLET_VC", g_iVC[id]);
    new menu = menu_create(title, "menu_perk_handler");

    for (new i = 0; i < NUM_PERKS; i++)
    {
        formatex(k1, charsmax(k1), "PERK_%d", i);
        formatex(k2, charsmax(k2), "PERK_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        new lv = g_iPerk[id][i];
        new stars[8];
        for (new s = 0; s < PERK_MAX; s++)
            stars[s] = (s < lv) ? '*' : '-';
        stars[PERK_MAX] = 0;

        if (lv >= PERK_MAX)
            formatex(item, charsmax(item), "\y%s \r[\w%s\r] \d%s \r[\wMAX\r]", n1, stars, n2);
        else
            formatex(item, charsmax(item), "\y%s \r[\w%s\r] \d%s %s%d VC", n1, stars, n2,
                g_iVC[id] >= (lv + 1) * PERK_COST_STEP ? "\y" : "\r", (lv + 1) * PERK_COST_STEP);

        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_perk_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new p = MenuInfo(menu, item);
    menu_destroy(menu);

    new lv = g_iPerk[id][p];
    if (lv >= PERK_MAX)
    {
        Chat(id, "PERK_MAXED");
    }
    else
    {
        new cost = (lv + 1) * PERK_COST_STEP;
        if (g_iVC[id] < cost)
            Chat(id, "SHOP_NOVC");
        else
        {
            g_iVC[id] -= cost;
            g_iPerk[id][p]++;
            PlayKey(id, "LEVEL_UP");
            ChatKeyName(id, "PERK_UP", "PERK_", p);
            CheckAch(id);
            SaveData(id);
        }
    }

    ShowPerkMenu(id);
    return PLUGIN_HANDLED;
}


/* ================================================================== */
/*  VIP SISTEMI                                                        */
/*  Kademeler: 1 = VIP, 2 = ELITE                                      */
/*  Kaynak: users.ini bayragi (t = VIP, s = ELITE) veya sureli VIP      */
/*  (vex_vip_add komutu, nvault'ta bitis tarihiyle saklanir)           */
/* ================================================================== */

LoadVip(id)
{
    g_iVip[id] = 0;
    g_iVipExpire[id] = 0;

    if (is_user_bot(id))
        return;

    // 1) Sureli VIP (nvault)
    if (g_hVipVault != INVALID_HANDLE)
    {
        new key[48], val[32];
        GetKey(id, key, charsmax(key));

        if (nvault_get(g_hVipVault, key, val, charsmax(val)))
        {
            new t[8], e[16];
            parse(val, t, charsmax(t), e, charsmax(e));
            new tier = clamp(str_to_num(t), 0, 2);
            new expire = str_to_num(e);

            if (expire > get_systime())
            {
                g_iVip[id] = tier;
                g_iVipExpire[id] = expire;
            }
            else if (expire > 0)
            {
                nvault_remove(g_hVipVault, key);
                set_task(6.0, "task_VipExpired", id + TASK_VIPMSG);
            }
        }
    }

    // 2) Kalici bayrak (users.ini)
    new flags = get_user_flags(id);
    if (flags & ADMIN_LEVEL_G)
        g_iVip[id] = 2;
    else if ((flags & ADMIN_LEVEL_H) && g_iVip[id] < 1)
        g_iVip[id] = 1;
}

public task_VipExpired(tid)
{
    new id = tid - TASK_VIPMSG;
    if (is_user_connected(id))
        Chat(id, "VIP_EXPIRED");
}

bool:IsVip(id)
{
    return (g_iVip[id] >= 1) ? true : false;
}

bool:IsElite(id)
{
    return (g_iVip[id] >= 2) ? true : false;
}

VipTierKey(id, out[], len)
{
    copy(out, len, IsElite(id) ? "VIP_TIER_2" : "VIP_TIER_1");
}

// Havada ekstra ziplama hakki: VIP 1 (cift), ELITE 2 (uclu), market +1
MaxAirJumps(id)
{
    if (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id] || g_bMinion[id])
        return 0;

    new n = g_iExtraJumps[id];
    if (IsVip(id))  n++;
    if (IsElite(id)) n++;
    return n;
}

// Baglaninca VIP karsilama
VipWelcome(id)
{
    if (!IsVip(id))
        return;

    new name[32], tier[16];
    get_user_name(id, name, charsmax(name));
    VipTierKey(id, tier, charsmax(tier));

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p) || p == id)
            continue;

        new tn[16];
        formatex(tn, charsmax(tn), "%L", p, tier);
        client_print_color(p, id, "%s %L", ChatTag("VIP_JOIN"), p, "VIP_JOIN", tn, name);

        new txt[128];
        formatex(txt, charsmax(txt), "%L", p, "VIP_JOIN_HUD", tn, name);
        HudText(p, SL_ALERT, CLR_REWARD, 3.0, txt);
    }
    PlayKey(0, "VIP_JOIN");

    // VIP'in kendisine ozel karsilama
    new tn2[16];
    formatex(tn2, charsmax(tn2), "%L", id, tier);
    Chat(id, "VIP_WELCOME_SELF", tn2, name);
    HudToS(id, SL_PERS, CLR_REWARD, 4.0, "VIP_WELCOME_HUD", tn2);

    if (g_iVipExpire[id] > 0)
    {
        new days = (g_iVipExpire[id] - get_systime()) / 86400;
        if (days <= 3)
            Chat(id, "VIP_ENDING", days + 1);
        else
            Chat(id, "VIP_DAYS_LEFT", days);
    }
}

/* ---------------- VIP menusu ---------------- */

public cmd_vip(id)
{
    if (!IsVip(id))
    {
        ShowVipInfo(id);
        return PLUGIN_HANDLED;
    }
    ShowVipMenu(id);
    return PLUGIN_HANDLED;
}

public cmd_vipinfo(id)
{
    ShowVipInfo(id);
    return PLUGIN_HANDLED;
}

ShowVipInfo(id)
{
    new contact[64];
    get_pcvar_string(g_pVipContact, contact, charsmax(contact));

    for (new i = 1; i <= 8; i++)
    {
        new key[16];
        formatex(key, charsmax(key), "VIPINFO_%d", i);
        Chat(id, key);
    }
    Chat(id, "VIPINFO_BUY", contact);
}

ShowVipMenu(id)
{
    new title[160], item[128], tier[16], tn[16], left[32];
    VipTierKey(id, tier, charsmax(tier));
    formatex(tn, charsmax(tn), "%L", id, tier);

    if (g_iVipExpire[id] > 0)
        formatex(left, charsmax(left), "%L", id, "VIP_LEFT_DAYS", max(0, (g_iVipExpire[id] - get_systime()) / 86400));
    else
        formatex(left, charsmax(left), "%L", id, "VIP_PERMANENT");

    formatex(title, charsmax(title), "%s \y%L^n\w%s \d|| %s^n", MENU_TAG, id, "MENU_VIP", tn, left);
    new menu = menu_create(title, "menu_vip_handler");

    formatex(item, charsmax(item), "%s%L", g_bVipFreeUsed[id] ? "\d" : "\y", id, g_bZombie[id] ? "VIPM_FREE_Z" : "VIPM_FREE_H");
    MenuAdd(menu, item, 1);

    new ak[16];
    formatex(ak, charsmax(ak), "AURA_%d", g_iVipAura[id]);
    formatex(item, charsmax(item), "\y%L \r[\w%L\r]", id, "VIPM_AURA", id, ak);
    MenuAdd(menu, item, 2);

    formatex(item, charsmax(item), "\y%L \r[%s%L\r]", id, "VIPM_TRAIL", g_bVipTrail[id] ? "\w" : "\d", id, g_bVipTrail[id] ? "ON" : "OFF");
    MenuAdd(menu, item, 3);

    formatex(item, charsmax(item), "\y%L", id, "VIPM_JUMPS");
    MenuAdd(menu, item, 4);

    formatex(item, charsmax(item), "\y%L", id, "VIPM_INFO");
    MenuAdd(menu, item, 5);

    MenuFinish(id, menu);
}

public menu_vip_handler(id, menu, item)
{
    if (item < 0 || !IsVip(id))
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    switch (sel)
    {
        case 1: VipFreePack(id);
        case 2:
        {
            g_iVipAura[id] = (g_iVipAura[id] + 1) % VIP_AURA_COUNT;
            ApplyRender(id);
        }
        case 3: g_bVipTrail[id] = !g_bVipTrail[id];
        case 4: Chat(id, IsElite(id) ? "VIP_JUMPS_ELITE" : "VIP_JUMPS_VIP");
        case 5:
        {
            ShowVipInfo(id);
            return PLUGIN_HANDLED;
        }
    }

    ShowVipMenu(id);
    return PLUGIN_HANDLED;
}

VipFreePack(id)
{
    if (g_bVipFreeUsed[id])
    {
        Chat(id, "VIP_FREE_USED");
        return;
    }
    if (!is_user_alive(id) || g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id] || g_bMinion[id] || g_bSurvivor[id] || g_bSniper[id])
    {
        Chat(id, "SHOP_UNAVAIL");
        return;
    }

    g_bVipFreeUsed[id] = 1;

    if (g_bZombie[id])
    {
        new Float:add = IsElite(id) ? 1000.0 : 500.0;
        g_iMaxHP[id] += floatround(add);
        set_entvar(id, var_health, Float:get_entvar(id, var_health) + add);
        if (IsElite(id))
            g_fCool[id] = 0.0;
        Chat(id, IsElite(id) ? "VIP_FREE_Z_ELITE" : "VIP_FREE_Z_VIP");
    }
    else
    {
        rg_set_user_armor(id, 200, ARMOR_VESTHELM);
        g_iFireNades[id]++;
        rg_give_item(id, "weapon_hegrenade");
        g_iFrostNades[id]++;
        rg_give_item(id, "weapon_smokegrenade");

        if (IsElite(id))
        {
            HealTo(id, 100, MaxHumanHP(id) + 100);
            g_bDmgAmp[id] = 1;
            g_iFlares[id]++;
            rg_give_item(id, "weapon_flashbang");
        }
        Chat(id, IsElite(id) ? "VIP_FREE_H_ELITE" : "VIP_FREE_H_VIP");
    }

    new Float:o[3];
    get_entvar(id, var_origin, o);
    FxRing(o, 255, 200, 0, 200);
    PlayKey(id, "SHOP_BUY");
}

// Her saniye: VIP iz efekti
TickVip()
{
    // VIP izi artik TickCosmetics icinde cizilir (gorunmezlik / zombi kontrolu ile)
}


/* ================================================================== */
/*  KOZMETIK (Vex Coin ile kalici): iz, oldurme efekti, enfeksiyon     */
/*  efekti. TUM ZAMANLARIN SIRALAMASI (ilk 15) + stil kartlari.        */
/*  IZLEYICI BILGISI: olu oyuncu izledigi kisinin bilgisini gorur.     */
/* ================================================================== */

// Iz renkleri: Buz, Toksik, Kan, Kraliyet, Altin, Gokkusagi (renk degistirir)
new const TRAIL_RGB[NUM_TRAILS][3] =
{
    {0, 200, 255}, {70, 255, 90}, {255, 30, 30}, {170, 70, 255}, {255, 200, 30}, {255, 255, 255}
};
new const RAINBOW_RGB[6][3] =
{
    {255, 40, 40}, {255, 150, 0}, {255, 240, 40}, {40, 255, 90}, {0, 180, 255}, {190, 70, 255}
};

/* ---------------- Kozmetik: fiyat / sahiplik ---------------- */

CosBit(cat, idx)
{
    switch (cat)
    {
        case 0: return (1 << idx);
        case 1: return (1 << (6 + idx));
    }
    return (1 << (12 + idx));
}

CosPrice(id, cat, idx)
{
    new p;
    switch (cat)
    {
        case 0: p = TRAIL_PRICE[idx];
        case 1: p = KFX_PRICE[idx];
        default: p = IFX_PRICE[idx];
    }
    if (IsElite(id))
        p = p * 80 / 100;
    else if (IsVip(id))
        p = p * 90 / 100;
    return max(1, p);
}

CosCount(cat)
{
    switch (cat)
    {
        case 0: return NUM_TRAILS;
        case 1: return NUM_KFX;
    }
    return NUM_IFX;
}

CosSelected(id, cat)
{
    switch (cat)
    {
        case 0: return g_iTrailSel[id];
        case 1: return g_iKfxSel[id];
    }
    return g_iIfxSel[id];
}

CosSetSelected(id, cat, val)
{
    switch (cat)
    {
        case 0: g_iTrailSel[id] = val;
        case 1: g_iKfxSel[id] = val;
        default: g_iIfxSel[id] = val;
    }
}

CosName(id, cat, idx, out[], len)
{
    new key[16];
    switch (cat)
    {
        case 0: formatex(key, charsmax(key), "COS_TRAIL_%d", idx);
        case 1: formatex(key, charsmax(key), "COS_KFX_%d", idx);
        default: formatex(key, charsmax(key), "COS_IFX_%d", idx);
    }
    formatex(out, len, "%L", id, key);
}

/* ---------------- Kozmetik menusu ---------------- */

public cmd_cosmetic(id)
{
    ShowCosmeticMenu(id);
    return PLUGIN_HANDLED;
}

ShowCosmeticMenu(id)
{
    new title[192], item[128], cur[48];
    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "COS_MENU", id, "COS_SUB", g_iVC[id]);
    new menu = menu_create(title, "menu_cos_handler");

    static const CATKEY[3][] = { "COS_CAT_TRAIL", "COS_CAT_KFX", "COS_CAT_IFX" };
    for (new c = 0; c < 3; c++)
    {
        new sel = CosSelected(id, c);
        if (sel > 0)
            CosName(id, c, sel - 1, cur, charsmax(cur));
        else
            formatex(cur, charsmax(cur), "%L", id, "COS_NONE");
        formatex(item, charsmax(item), "\y%L \r[\w%s\r]", id, CATKEY[c], cur);
        MenuAdd(menu, item, c);
    }
    MenuFinish(id, menu);
}

public menu_cos_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new cat = MenuInfo(menu, item);
    menu_destroy(menu);
    ShowCosList(id, cat);
    return PLUGIN_HANDLED;
}

ShowCosList(id, cat)
{
    new title[192], item[128], nm[48];
    static const CATKEY[3][] = { "COS_CAT_TRAIL", "COS_CAT_KFX", "COS_CAT_IFX" };
    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, CATKEY[cat], id, "COS_SUB", g_iVC[id]);
    new menu = menu_create(title, "menu_coslist_handler");

    new sel = CosSelected(id, cat);
    formatex(item, charsmax(item), sel == 0 ? "\y%L \r[\w*\r]" : "\y%L", id, "COS_NONE");
    MenuAdd(menu, item, cat * 100);

    for (new i = 0; i < CosCount(cat); i++)
    {
        CosName(id, cat, i, nm, charsmax(nm));
        if (sel == i + 1)
            formatex(item, charsmax(item), "\y%s \r[\w%L\r]", nm, id, "COS_EQUIPPED");
        else if (g_iCosOwned[id] & CosBit(cat, i))
            formatex(item, charsmax(item), "\y%s \d[%L]", nm, id, "COS_OWNED");
        else
            formatex(item, charsmax(item), "\y%s \r[\w%d VC\r]", nm, CosPrice(id, cat, i));
        MenuAdd(menu, item, cat * 100 + i + 1);
    }
    MenuFinish(id, menu);
}

public menu_coslist_handler(id, menu, item)
{
    if (item < 0)
    {
        // Cikista menuyu yeniden acma: oyuncu ayriliyorsa hata olusur
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new v = MenuInfo(menu, item);
    menu_destroy(menu);

    if (!is_user_connected(id))
        return PLUGIN_HANDLED;

    new cat = v / 100, idx = v % 100;
    if (cat < 0 || cat > 2)
        return PLUGIN_HANDLED;

    new nm[48], bool:changed;
    if (idx == 0)
    {
        if (CosSelected(id, cat) != 0)
        {
            CosSetSelected(id, cat, 0);
            if (cat == 0)
                KillTrail(id);
            changed = true;
        }
        Chat(id, "COS_OFF");
    }
    else
    {
        new i = idx - 1;
        if (i >= CosCount(cat))
            return PLUGIN_HANDLED;
        CosName(id, cat, i, nm, charsmax(nm));

        if (!(g_iCosOwned[id] & CosBit(cat, i)))
        {
            new price = CosPrice(id, cat, i);
            if (g_iVC[id] < price)
            {
                Chat(id, "COS_NOVC", price);
                ShowCosList(id, cat);
                return PLUGIN_HANDLED;
            }
            g_iVC[id] -= price;
            g_iCosOwned[id] |= CosBit(cat, i);
            PlayKey(id, "SHOP_BUY");
            Chat(id, "COS_BOUGHT", nm, price);
            CosPreview(id, cat, i);

            new name[32];
            get_user_name(id, name, charsmax(name));
            for (new p = 1; p <= g_iMax; p++)
            {
                if (p == id || !is_user_connected(p) || is_user_bot(p))
                    continue;
                new pn[48];
                CosName(p, cat, i, pn, charsmax(pn));
                client_print_color(p, id, "%s %L", ChatTag("COS_BOUGHT_ALL"), p, "COS_BOUGHT_ALL", name, pn);
            }
            changed = true;
        }
        if (CosSelected(id, cat) != idx)
        {
            CosSetSelected(id, cat, idx);
            changed = true;
        }
        Chat(id, "COS_EQUIP", nm);
    }

    if (changed)
        SaveData(id);
    ShowCosList(id, cat);
    return PLUGIN_HANDLED;
}

// Satin alinca / takilinca kucuk on izleme
CosPreview(id, cat, idx)
{
    if (!is_user_alive(id))
        return;

    new Float:o[3];
    get_entvar(id, var_origin, o);
    switch (cat)
    {
        case 0:
        {
            if (TrailAllowed(id))
                DrawTrail(id, idx);
        }
        case 1:
        {
            o[0] += 60.0;
            KillFx(idx, o);
        }
        default:
        {
            o[0] += 60.0;
            InfectFx(idx, o);
        }
    }
}

/* ---------------- Kozmetik efektleri ---------------- */

DrawTrail(id, idx)
{
    new r, g, b;
    if (idx == 5)
    {
        new c = (g_iFrame / 2) % 6;
        r = RAINBOW_RGB[c][0];
        g = RAINBOW_RGB[c][1];
        b = RAINBOW_RGB[c][2];
    }
    else
    {
        r = TRAIL_RGB[idx][0];
        g = TRAIL_RGB[idx][1];
        b = TRAIL_RGB[idx][2];
    }

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_KILLBEAM);
    write_short(id);
    message_end();

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMFOLLOW);
    write_short(id);
    write_short(g_sprBeam);
    write_byte(idx == 5 ? 16 : 12);
    write_byte(idx >= 4 ? 5 : 4);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    write_byte(160);
    message_end();
}

bool:TrailAllowed(id)
{
    if (!is_user_alive(id) || g_bZombie[id])
        return false;
    if (g_fCloak[id] > get_gametime() || g_iJob[id] == JOB_GHOST)
        return false;
    if (g_iEvent == EV_SPEED)
        return false;
    return true;
}

KillTrail(id)
{
    if (!g_bTrailOn[id])
        return;
    g_bTrailOn[id] = false;
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_KILLBEAM);
    write_short(id);
    message_end();
}

DrawVipTrail(id)
{
    new c = g_iVipAura[id] ? g_iVipAura[id] : 2;

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_KILLBEAM);
    write_short(id);
    message_end();

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMFOLLOW);
    write_short(id);
    write_short(g_sprBeam);
    write_byte(12);
    write_byte(3);
    write_byte(VIP_AURA_RGB[c][0]);
    write_byte(VIP_AURA_RGB[c][1]);
    write_byte(VIP_AURA_RGB[c][2]);
    write_byte(120);
    message_end();
}

// Her 2 sn: kozmetik iz (yoksa VIP izi). Gorunmezken / zombiyken iz silinir.
TickCosmetics()
{
    if (g_iFrame % 2)
        return;

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
            continue;

        new bool:want = (g_iTrailSel[id] > 0 || (IsVip(id) && g_bVipTrail[id])) ? true : false;
        if (!want || !TrailAllowed(id))
        {
            if (g_iEvent != EV_SPEED)
                KillTrail(id);
            else
                g_bTrailOn[id] = false;
            continue;
        }

        if (g_iTrailSel[id] > 0)
            DrawTrail(id, g_iTrailSel[id] - 1);
        else
            DrawVipTrail(id);
        g_bTrailOn[id] = true;
    }
}

// Zombi oldurunce
CosKillFx(killer, const Float:o[3])
{
    if (!(1 <= killer <= g_iMax) || !g_iKfxSel[killer])
        return;
    KillFx(g_iKfxSel[killer] - 1, o);
}

KillFx(idx, const Float:o[3])
{
    new Float:top[3];
    switch (idx)
    {
        case 0: // Yildirim
        {
            FxSkyStrike(o, 170, 210, 255);
            FxSparks(o);
            EmitKeyPos(o, "ZAP");
        }
        case 1: // Altin patlama
        {
            FxRingEx(o, 255, 200, 30, 220, 14, 5);
            FxLight(o, 255, 200, 30, 20, 10, 20);
            FxSparks(o);
            top = o;
            top[2] += 120.0;
            FxSpriteTrail(o, top, g_sprFlare, 14, 8, 2, 30, 20);
        }
        case 2: // Kan cesmesi
        {
            FxBlood(o, 30);
            FxLava(o);
            FxRingEx(o, 200, 0, 0, 160, 10, 4);
        }
        case 3: // Buz kirilmasi
        {
            FxStreak(o, 7, 60, 300);
            FxRingEx(o, 120, 220, 255, 200, 12, 5);
            FxLight(o, 0, 190, 255, 18, 8, 20);
            EmitKeyPos(o, "FREEZE");
        }
        case 4: // Bosluk cokusu
        {
            FxImplosion(o, 200, 50, 6);
            FxRingEx(o, 200, 0, 160, 240, 18, 6);
            FxLight(o, 200, 0, 160, 18, 8, 20);
        }
        case 5: // Havai fisek
        {
            for (new i = 0; i < 3; i++)
            {
                new c = random(6);
                new Float:p[3];
                p = o;
                p[2] += 40.0 + 30.0 * float(i);
                FxRingEx(p, RAINBOW_RGB[c][0], RAINBOW_RGB[c][1], RAINBOW_RGB[c][2], 120 + 50 * i, 8, 4);
            }
            top = o;
            top[2] += 160.0;
            FxSpriteTrail(o, top, g_sprFlare, 20, 10, 2, 40, 30);
            FxSparks(top);
        }
    }
}

// Enfekte edince (zombi kozmetigi)
CosInfectFx(zombie, const Float:o[3])
{
    if (!(1 <= zombie <= g_iMax) || !g_iIfxSel[zombie])
        return;
    InfectFx(g_iIfxSel[zombie] - 1, o);
}

InfectFx(idx, const Float:o[3])
{
    switch (idx)
    {
        case 0: // Zehir patlamasi
        {
            FxRingEx(o, 90, 255, 0, 260, 16, 5);
            FxSprite(o, g_sprSmoke, 18, 170);
        }
        case 1: // Golge
        {
            FxImplosion(o, 220, 60, 7);
            FxRingEx(o, 60, 0, 90, 220, 20, 6);
        }
        case 2: // Kan Ayi
        {
            FxSkyStrike(o, 255, 0, 0);
            FxBlood(o, 25);
            FxRingEx(o, 255, 0, 0, 280, 14, 5);
        }
    }
}
