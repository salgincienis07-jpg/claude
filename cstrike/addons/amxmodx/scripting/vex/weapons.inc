/* ================================================================== */
/*  Vexmira Zombie - modul: vex/weapons.inc  (SILAHLAR)               */
/*  Silah dagitimi (birincil / ikincil menu), ozel silahlar (deploy   */
/*  / atis), ozel bombalar ve bomba modlari, lazer mayinlari, hava    */
/*  ikmali, isaret fisegi, firlatilan bomba modelleri.                */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  TICK (1 sn)                                                        */
/* ================================================================== */

/* ---------------- Isaret fisegi (flare) ---------------- */

TickFlares()
{
    new Float:now = get_gametime();
    for (new f = 0; f < MAX_FLARES; f++)
    {
        if (g_fFlareEnd[f] <= now)
            continue;
        FxLight(g_fFlarePos[f], 255, 60, 60, 45, 12, 2);
    }
}

AddFlare(const Float:o[3])
{
    new best, Float:min_end = 999999.0;
    for (new f = 0; f < MAX_FLARES; f++)
    {
        if (g_fFlareEnd[f] < min_end)
        {
            min_end = g_fFlareEnd[f];
            best = f;
        }
    }
    g_fFlarePos[best][0] = o[0];
    g_fFlarePos[best][1] = o[1];
    g_fFlarePos[best][2] = o[2] + 10.0;
    g_fFlareEnd[best] = get_gametime() + floatmax(1.0, get_pcvar_float(g_pNadeFlareTime));
}


/* ================================================================== */
/*  OYUNCU HOOK'LARI (ReAPI)                                           */
/* ================================================================== */

WeaponIdType:GetActiveWeaponId(id)
{
    new item = get_member(id, m_pActiveItem);
    if (is_nullent(item))
        return WEAPON_NONE;
    return get_member(item, m_iId);
}

SpecialIndex(id, WeaponIdType:wid)
{
    if (!g_iSpecW[id])
        return -1;
    for (new i = 0; i < NUM_SPECIAL; i++)
    {
        if ((g_iSpecW[id] & (1 << i)) && SW_BASE_ID[i] == wid)
            return i;
    }
    return -1;
}

Ignite(victim, attacker, ticks)
{
    if (!g_bZombie[victim] || g_bBoss[victim])
        return;
    if (IsClassZombie(victim, ZC_MAGMA) && get_pcvar_num(g_pZc[ZCV_MAG_IMMUNE]))
        return;
    if (g_iBurn[victim] <= 0)
        EmitKey(victim, "BURN");
    g_iBurn[victim] = max(g_iBurn[victim], ticks);
    g_iBurnBy[victim] = attacker;
}

Freeze(victim, Float:dur)
{
    if (!g_bZombie[victim])
        return;

    // Boss / nemesis donmaz, sadece yavaslar
    if (g_bBoss[victim] || g_bNemesis[victim] || g_bAssassin[victim])
    {
        g_fSlow[victim] = get_gametime() + dur;
        rg_reset_maxspeed(victim);
        return;
    }

    g_fFrozen[victim] = get_gametime() + dur;
    set_entvar(victim, var_velocity, Float:{0.0, 0.0, 0.0});
    rg_reset_maxspeed(victim);
    ApplyRender(victim);
    EmitKey(victim, "FREEZE");
    new Float:vo[3];
    get_entvar(victim, var_origin, vo);
    FxElSmall(vo, EL_ICE, 7);
}

ChainLightning(victim, attacker)
{
    if (g_bChaining)
        return;
    g_bChaining = true;

    new Float:vo[3], Float:po[3], hits;
    get_entvar(victim, var_origin, vo);

    for (new p = 1; p <= g_iMax && hits < 2; p++)
    {
        if (p == victim || !is_user_alive(p) || !g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(vo, po) > 320.0)
            continue;

        FxBeam(vo, po, g_sprLightning, 200, 220, 255, 30);
        ExecuteHamB(Ham_TakeDamage, p, attacker, attacker, 120.0, DMG_SHOCK);
        hits++;
    }

    if (hits)
        EmitKey(victim, "ZAP");

    g_bChaining = false;
}

/* ---------------- Esya kisitlama (zombiler silah alamaz) ---------------- */

public rg_HasRestrictItem(id, ItemID:item, ItemRestType:type)
{
    if (!g_bZombie[id])
    {
        // Insanlar oyun marketinden alis-veris yapamaz (kendi menumuz var)
        if (type == ITEM_TYPE_BUYING)
        {
            SetHookChainReturn(ATYPE_BOOL, true);
            return HC_SUPERCEDE;
        }
        return HC_CONTINUE;
    }

    if (item == ITEM_KNIFE)
        return HC_CONTINUE;

    SetHookChainReturn(ATYPE_BOOL, true);
    return HC_SUPERCEDE;
}

/* ---------------- View model (pence / ozel silah) ---------------- */

public rg_DefaultDeploy(weapon, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal)
{
    new id = get_member(weapon, m_pPlayer);
    if (!(1 <= id <= g_iMax))
        return HC_CONTINUE;

    new WeaponIdType:wid = get_member(weapon, m_iId);

    if (g_bZombie[id])
    {
        if (wid != WEAPON_KNIFE)
            return HC_CONTINUE;

        // Pence: boss > nemesis/assassin > sinif > genel
        new claw[96];
        if (g_bBoss[id] && g_szBClaw[g_iBossType][0])      copy(claw, charsmax(claw), g_szBClaw[g_iBossType]);
        else if (g_bNemesis[id] && g_szNemClaw[0])         copy(claw, charsmax(claw), g_szNemClaw);
        else if (g_bAssassin[id] && g_szAsnClaw[0])        copy(claw, charsmax(claw), g_szAsnClaw);
        else if (!g_bMinion[id] && g_szZClaw[g_iClass[id]][0]) copy(claw, charsmax(claw), g_szZClaw[g_iClass[id]]);
        else if (g_szClawModel[0])                         copy(claw, charsmax(claw), g_szClawModel);

        if (claw[0])
        {
            SetHookChainArg(2, ATYPE_STRING, claw);
            SetHookChainArg(3, ATYPE_STRING, "");
        }
        return HC_CONTINUE;
    }

    new sw = SpecialIndex(id, wid);
    if (sw >= 0)
    {
        if (g_szSWView[sw][0])
            SetHookChainArg(2, ATYPE_STRING, g_szSWView[sw]);
        if (g_szSWPlayer[sw][0])
            SetHookChainArg(3, ATYPE_STRING, g_szSWPlayer[sw]);
        return HC_CONTINUE;
    }

    new w = _:wid;
    if (0 < w < 31)
    {
        if (g_szWepV[w][0])
            SetHookChainArg(2, ATYPE_STRING, g_szWepV[w]);
        if (g_szWepP[w][0])
            SetHookChainArg(3, ATYPE_STRING, g_szWepP[w]);
    }
    return HC_CONTINUE;
}

/* ---------------- Atis: sinirsiz sarjor + ozel silah izleri ---------------- */

public fw_PrimaryAttackPost(weapon)
{
    new id = get_member(weapon, m_pPlayer);
    if (!(1 <= id <= g_iMax) || !is_user_alive(id) || g_bZombie[id])
        return HAM_IGNORED;

    new WeaponIdType:wid = get_member(weapon, m_iId);

    if (g_bUnlClip[id])
    {
        new clip = rg_get_weapon_info(wid, WI_GUN_CLIP_SIZE);
        if (clip > 0)
            set_member(weapon, m_Weapon_iClip, clip);
    }

    new sw = SpecialIndex(id, wid);
    if (sw < 0)
        return HAM_IGNORED;

    // Hizli silahlarda her atista iz cizme (performans)
    if ((sw == 1 || sw == 5) && (g_iFrame + id) % 2)
        return HAM_IGNORED;

    new Float:start[3], Float:end[3], Float:ofs[3], Float:ang[3], Float:fwd[3];
    get_entvar(id, var_origin, start);
    get_entvar(id, var_view_ofs, ofs);
    start[0] += ofs[0];
    start[1] += ofs[1];
    start[2] += ofs[2];

    get_entvar(id, var_v_angle, ang);
    engfunc(EngFunc_MakeVectors, ang);
    global_get(glb_v_forward, fwd);

    end[0] = start[0] + fwd[0] * 8192.0;
    end[1] = start[1] + fwd[1] * 8192.0;
    end[2] = start[2] + fwd[2] * 8192.0;

    engfunc(EngFunc_TraceLine, start, end, DONT_IGNORE_MONSTERS, id, 0);
    get_tr2(0, TR_vecEndPos, end);

    start[2] -= 6.0;
    FxBeam(start, end, (sw == 2) ? g_sprLightning : g_sprBeam, SW_RGB[sw][0], SW_RGB[sw][1], SW_RGB[sw][2], (sw == 2) ? 40 : 12);
    FxLight(end, SW_RGB[sw][0], SW_RGB[sw][1], SW_RGB[sw][2], 8, 3, 30);

    if (sw == 2 || sw == 7)
        EmitKey(id, "SW_FIRE");

    return HAM_IGNORED;
}


/* ================================================================== */
/*  OZEL BOMBALAR                                                      */
/* ================================================================== */

public rg_ThrowHe(id, Float:vecStart[3], Float:vecVelocity[3], Float:time, team, usEvent)
{
    new ent = GetHookChainReturn(ATYPE_INTEGER);
    if (is_nullent(ent))
        return;

    if (g_bZombie[id] && g_iInfNades[id] > 0)
    {
        g_iInfNades[id]--;
        set_entvar(ent, var_impulse, NADE_INFECT);
        FxTrail(ent, 0, 255, 0);
    }
    else if (!g_bZombie[id] && g_iFireNades[id] > 0)
    {
        g_iFireNades[id]--;
        set_entvar(ent, var_impulse, NADE_FIRE);
        FxTrail(ent, 255, 80, 0);
    }
    else if (!g_bZombie[id])
        FxTrail(ent, 255, 200, 120);

    NadeOnThrow(id, ent, 0);
}

public rg_ThrowSmoke(id, Float:vecStart[3], Float:vecVelocity[3], Float:time, usEvent)
{
    new ent = GetHookChainReturn(ATYPE_INTEGER);
    if (is_nullent(ent))
        return;

    if (!g_bZombie[id] && g_iFrostNades[id] > 0)
    {
        g_iFrostNades[id]--;
        set_entvar(ent, var_impulse, NADE_FROST);
        FxTrail(ent, 0, 150, 255);
    }
    NadeOnThrow(id, ent, 1);
}

public rg_ThrowFlash(id, Float:vecStart[3], Float:vecVelocity[3], Float:time)
{
    new ent = GetHookChainReturn(ATYPE_INTEGER);
    if (is_nullent(ent))
        return;

    if (!g_bZombie[id] && g_iFlares[id] > 0)
    {
        g_iFlares[id]--;
        set_entvar(ent, var_impulse, NADE_FLARE);
        FxTrail(ent, 255, 60, 60);
    }
    NadeOnThrow(id, ent, 2);
}

public rg_ExplodeHe(ent, tracehandle, bits)
{
    NadeCleanup(ent);
    new type = get_entvar(ent, var_impulse);

    // Parcali mod: ana patlamadan sonra cevreye kucuk patlamalar
    if (get_entvar(ent, var_iuser4) == NM_CLUSTER + 1)
        NadeCluster(ent, type);
    set_entvar(ent, var_iuser4, 0);

    if (type != NADE_FIRE && type != NADE_INFECT)
        return HC_CONTINUE;

    new owner = get_entvar(ent, var_owner);
    new Float:o[3], Float:po[3];
    get_entvar(ent, var_origin, o);

    if (type == NADE_FIRE)
    {
        if (!FxExploEl(o, EL_FIRE, 24, 16))
            FxExplosion(o);
        FxRing(o, 255, 80, 0, 300);
        FxLava(o);
        FxLight(o, 255, 80, 0, 40, 15, 20);
        PlayKey(0, "NADE_FIRE");

        new Float:frad = get_pcvar_float(g_pNadeFireRad), Float:fdmg = get_pcvar_float(g_pNadeFireDmg);
        new burn = max(1, get_pcvar_num(g_pNadeFireBurn));
        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_alive(p) || !g_bZombie[p])
                continue;
            get_entvar(p, var_origin, po);
            if (get_distance_f(o, po) > frad)
                continue;
            Ignite(p, owner, burn);
            if (is_user_connected(owner))
                ExecuteHamB(Ham_TakeDamage, p, ent, owner, fdmg, DMG_BURN | DMG_GRENADE);
        }
    }
    else
    {
        FxRing(o, 0, 255, 0, 300);
        FxLight(o, 0, 255, 0, 40, 15, 20);
        if (!FxExploEl(o, EL_TOXIC, 24, 14))
            FxSprite(o, g_sprSmoke, 30, 200);
        PlayKey(0, "NADE_INFECT");

        if (g_bRoundActive && AllowsInfection() && is_user_connected(owner) && g_bZombie[owner])
        {
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_alive(p) || g_bZombie[p] || g_bSurvivor[p] || g_bSniper[p])
                    continue;
                if (CountHumans(true) <= 1)
                    break;
                get_entvar(p, var_origin, po);
                if (get_distance_f(o, po) > get_pcvar_float(g_pNadeInfectRad))
                    continue;
                Infect(p, owner);
            }
        }
    }

    set_entvar(ent, var_flags, FL_KILLME);
    return HC_SUPERCEDE;
}

public rg_ExplodeSmoke(ent)
{
    NadeCleanup(ent);
    set_entvar(ent, var_iuser4, 0);
    if (get_entvar(ent, var_impulse) != NADE_FROST)
        return HC_CONTINUE;

    new Float:o[3], Float:po[3];
    get_entvar(ent, var_origin, o);

    FxRing(o, 0, 150, 255, 300);
    FxRing(o, 200, 240, 255, 200);
    FxExploEl(o, EL_ICE, 24, 14);
    FxDisk(o, 0, 120, 255, 260, 5);
    FxStreak(o, 7, 60, 300);
    FxLight(o, 0, 150, 255, 40, 15, 20);
    PlayKey(0, "NADE_FROST");

    new Float:rad = get_pcvar_float(g_pNadeFrostRad), Float:ft = get_pcvar_float(g_pNadeFrostTime);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || !g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > rad)
            continue;
        Freeze(p, ft);
    }

    set_entvar(ent, var_flags, FL_KILLME);
    return HC_SUPERCEDE;
}

public rg_ExplodeFlash(ent, tracehandle, bits)
{
    NadeCleanup(ent);
    set_entvar(ent, var_iuser4, 0);
    if (get_entvar(ent, var_impulse) != NADE_FLARE)
        return HC_CONTINUE;

    new Float:o[3];
    get_entvar(ent, var_origin, o);
    AddFlare(o);
    FxLight(o, 255, 60, 60, 50, 12, 2);
    FxRing(o, 255, 60, 60, 120);

    set_entvar(ent, var_flags, FL_KILLME);
    return HC_SUPERCEDE;
}


/* ================================================================== */
/*  MENULER                                                            */
/* ================================================================== */

// Ayni bombadan zaten varsa ustune ekle (oyun ikinciyi atmasin)
GiveNadeStack(id, const ent[], WeaponIdType:wid)
{
    new cur = rg_get_user_bpammo(id, wid);
    if (cur <= 0)
        rg_give_item(id, ent);
    else
        rg_set_user_bpammo(id, wid, cur + 1);
}

/* ---------------- Silah menusu ---------------- */

ShowPrimaryMenu(id)
{
    new title[96], item[64];

    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MENU_PRIMARY", id, "MENU_GUNS_SUB");
    new menu = menu_create(title, "menu_primary_handler");

    for (new i = 0; i < sizeof PRIM_NAME; i++)
    {
        if (g_iLevel[id] >= PRIM_LVL[i])
            formatex(item, charsmax(item), "\y%s", PRIM_NAME[i]);
        else
            formatex(item, charsmax(item), "\d%s \r[\wLv.%d\r]", PRIM_NAME[i], PRIM_LVL[i]);
        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_primary_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    if (g_iLevel[id] < PRIM_LVL[sel])
    {
        Chat(id, "NEED_LEVEL", PRIM_LVL[sel]);
        ShowPrimaryMenu(id);
        return PLUGIN_HANDLED;
    }

    g_iPrimTmp[id] = sel;
    ShowSecondaryMenu(id);
    return PLUGIN_HANDLED;
}

ShowSecondaryMenu(id)
{
    new title[64], item[64];

    formatex(title, charsmax(title), "%s \y%L^n", MENU_TAG, id, "MENU_SECONDARY");
    new menu = menu_create(title, "menu_secondary_handler");

    for (new i = 0; i < sizeof SEC_NAME; i++)
    {
        if (g_iLevel[id] >= SEC_LVL[i])
            formatex(item, charsmax(item), "\y%s", SEC_NAME[i]);
        else
            formatex(item, charsmax(item), "\d%s \r[\wLv.%d\r]", SEC_NAME[i], SEC_LVL[i]);
        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_secondary_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    if (g_iLevel[id] < SEC_LVL[sel])
    {
        Chat(id, "NEED_LEVEL", SEC_LVL[sel]);
        ShowSecondaryMenu(id);
        return PLUGIN_HANDLED;
    }

    g_iPrim[id] = g_iPrimTmp[id];
    g_iSec[id] = sel;

    Chat(id, "GUNS_SAVED");
    GiveLoadout(id);
    SaveData(id);
    return PLUGIN_HANDLED;
}

GiveLoadout(id)
{
    if (!is_user_alive(id) || g_bZombie[id] || g_bSurvivor[id] || g_bSniper[id])
        return;
    if (g_iPrim[id] < 0 || g_iSec[id] < 0)
        return;

    // Round basladiktan sonra her hayatta bir kez (birak-yeniden al suistimali olmasin)
    if (g_bRoundActive && g_bGunsGiven[id])
    {
        Chat(id, "GUNS_ONCE");
        return;
    }

    // Round icinde bedava mermi suistimalini engelle: ana silahi varsa verme
    if (g_bRoundActive)
    {
        for (new w = 0; w < sizeof PRIM_ENT; w++)
        {
            if (rg_find_weapon_bpack_by_name(id, PRIM_ENT[w]))
                return;
        }
    }

    new p = g_iPrim[id], s = g_iSec[id];

    rg_give_item(id, SEC_ENT[s], GT_REPLACE);
    rg_set_user_bpammo(id, WeaponIdType:rg_get_weapon_info(SEC_ENT[s], WI_ID), SEC_AMMO[s]);

    rg_give_item(id, PRIM_ENT[p], GT_REPLACE);
    rg_set_user_bpammo(id, WeaponIdType:rg_get_weapon_info(PRIM_ENT[p], WI_ID), PRIM_AMMO[p]);

    g_bGunsGiven[id] = true;
    GiveStartNades(id);
    engclient_cmd(id, PRIM_ENT[p]);
}

// v2.0: Her insana (CT) her dogusta TUM bombalar otomatik verilir; silah seciminden
// bagimsiz. vex_give_nades: a = ates (HE), b = buz (duman), c = isaret fisegi (flash)
GiveStartNades(id)
{
    if (!is_user_alive(id) || g_bZombie[id] || g_bNadesGiven[id])
        return;
    g_bNadesGiven[id] = true;

    new gn[8];
    get_pcvar_string(g_pGiveNades, gn, charsmax(gn));
    if (containi(gn, "a") != -1)
    {
        g_iFireNades[id] = max(1, g_iFireNades[id]);
        if (rg_get_user_bpammo(id, WEAPON_HEGRENADE) <= 0)
            rg_give_item(id, "weapon_hegrenade");
    }
    if (containi(gn, "b") != -1)
    {
        g_iFrostNades[id] = max(1, g_iFrostNades[id]);
        if (rg_get_user_bpammo(id, WEAPON_SMOKEGRENADE) <= 0)
            rg_give_item(id, "weapon_smokegrenade");
    }
    if (containi(gn, "c") != -1)
    {
        g_iFlares[id] = max(1, g_iFlares[id]);
        if (rg_get_user_bpammo(id, WEAPON_FLASHBANG) <= 0)
            rg_give_item(id, "weapon_flashbang");
    }

    // Demolitions / Grenadier: bedava bombalar
    if (g_iJob[id] == JOB_DEMO || g_iJob[id] == JOB_GRENADIER)
    {
        g_iFireNades[id]++;
        GiveNadeStack(id, "weapon_hegrenade", WEAPON_HEGRENADE);
    }
    if (g_iJob[id] == JOB_GRENADIER)
    {
        g_iFrostNades[id]++;
        GiveNadeStack(id, "weapon_smokegrenade", WEAPON_SMOKEGRENADE);
    }
}


/* ================================================================== */
/*  LAZER MAYINLARI (v2.0)                                             */
/*  - Her insana her round vex_lm_per_round (3) lazer hakki verilir;   */
/*    AP ile satin alma YOK.                                           */
/*  - V (+setlaser / setlaser): nisan alinan duvara / zemine kurar     */
/*  - C (radio3 / +dellaser / dellaser): kendi lazerini ANINDA sokup   */
/*    cantaya geri koyar (menuye girmeye gerek yok)                    */
/*  - Isina degen zombi TEK ATISTA olur (vex_lm_oneshot 1). Isin her   */
/*    0.1 sn tum zombilerin govde kutusuyla test edilir: ziplayan,     */
/*    parasutle suzulen, egilen, baska oyuncunun arkasindaki zombi de  */
/*    vurulur.                                                         */
/*  - Model / govde / animasyon / isin sprite'i vexmira.cfg'den        */
/*    (vex_res LASERMINE_MODEL / LASERMINE_BODY / SPR_LASER ...)       */
/*  - Zombiler pencesiyle mayini kirabilir; her oldurmede mayin asinir */
/*  - Boss roundlarinda kurulamaz (vex_lm_boss 0)                      */
/* ================================================================== */

#define LM_CLASS     "vex_lasermine"
#define BEAM_MARK_LM 7776
#define BEAM_MARK_NADE 7777
#define BEAM_MARK_DROP 7778

new Float:g_fLmCd[33], Float:g_fPlantPos[33][3], Float:g_fLmMsg[33];

// Oyuncuya ozel lazer renkleri (vex_lm_color_mode 1)
new const LM_PALETTE[8][3] =
{
    {0, 200, 255}, {255, 40, 40}, {60, 255, 90}, {255, 200, 0}, {200, 60, 255}, {255, 110, 0}, {0, 255, 220}, {255, 80, 200}
};

bool:LasersAllowed()
{
    if (!get_pcvar_num(g_pLmEnable))
        return false;
    if (g_iMode == MODE_BOSS && !get_pcvar_num(g_pLmBoss))
        return false;
    if (LmModeBlocked(g_iMode))
        return false;
    return true;
}

// v3.1: vex_lm_block_modes - lazerin kapali oldugu modlar (ad ya da numara, bosluk / virgul ile).
// Cvar degismedikce onbellekteki bit maskesi kullanilir.
new const LM_MODE_KEYS[MODE_TOTAL][] =
{
    "infection", "multi", "nemesis", "assassin", "survivor", "sniper", "swarm", "plague", "armageddon", "boss"
};

bool:LmModeBlocked(mode)
{
    if (!(0 <= mode < MODE_TOTAL))
        return false;
    new str[64];
    get_pcvar_string(g_pLmBlockModes, str, charsmax(str));
    if (g_iLmBlockMask < 0 || !equal(str, g_szLmBlockCache))
    {
        copy(g_szLmBlockCache, charsmax(g_szLmBlockCache), str);
        g_iLmBlockMask = 0;
        replace_all(str, charsmax(str), ",", " ");
        new tok[16], pos, len = strlen(str);
        while (pos < len)
        {
            while (pos < len && str[pos] == ' ')
                pos++;
            new n;
            while (pos < len && str[pos] != ' ')
            {
                if (n < charsmax(tok))
                    tok[n++] = str[pos];
                pos++;
            }
            tok[n] = 0;
            if (!n)
                continue;
            if (isdigit(tok[0]))
            {
                new m = str_to_num(tok);
                if (0 <= m < MODE_TOTAL)
                    g_iLmBlockMask |= (1 << m);
                continue;
            }
            for (new m = 0; m < MODE_TOTAL; m++)
            {
                if (equali(tok, LM_MODE_KEYS[m]))
                    g_iLmBlockMask |= (1 << m);
            }
        }
    }
    return (g_iLmBlockMask & (1 << mode)) ? true : false;
}

// Gelistirici testi (vex_debug_dirs 1): "vex_debug_lmtest [force]" - canli insanlar (botlar)
// icin yakin duvara mayin kurar (force: lazer kapali modda da). Izin / kurulum log'a yazilir.
public srv_DbgLmTest()
{
    if (!get_pcvar_num(g_pDbgDirs))
        return PLUGIN_HANDLED;
    new arg[8];
    read_argv(1, arg, charsmax(arg));
    new bool:force = equali(arg, "force") ? true : false;
    new bool:allowed = LasersAllowed();
    new planted, tries;
    for (new id = 1; id <= g_iMax && planted < 4; id++)
    {
        if (!is_user_alive(id) || g_bZombie[id])
            continue;
        tries++;
        if (!allowed && !force)
            continue;
        new Float:eye[3], Float:end[3], Float:pos[3], Float:nrm[3], Float:frac;
        ZcEye(id, eye);
        for (new k = 0; k < 8; k++)
        {
            end[0] = eye[0] + floatcos(float(k) * 45.0, degrees) * 128.0;
            end[1] = eye[1] + floatsin(float(k) * 45.0, degrees) * 128.0;
            end[2] = eye[2] - 16.0;
            engfunc(EngFunc_TraceLine, eye, end, IGNORE_MONSTERS, id, 0);
            get_tr2(0, TR_flFraction, frac);
            if (frac >= 1.0)
                continue;
            get_tr2(0, TR_vecEndPos, pos);
            get_tr2(0, TR_vecPlaneNormal, nrm);
            if (CreateMine(id, pos, nrm))
            {
                planted++;
                break;
            }
        }
    }
    log_amx("[Vexmira] DIRCHK lm_test mode=%d allowed=%d force=%d humans=%d planted=%d mines=%d", g_iMode, allowed, force, tries, planted, CountMines(0));
    return PLUGIN_HANDLED;
}

// Lazer neden kapali: boss / bu mod / genel
LmDenyReason(id)
{
    if (g_iMode == MODE_BOSS && !get_pcvar_num(g_pLmBoss))
    {
        LmMessage(id, "LM_NO_BOSS");
        return;
    }
    if (get_pcvar_num(g_pLmEnable) && LmModeBlocked(g_iMode))
    {
        new Float:now = get_gametime();
        if (now < g_fLmMsg[id])
            return;
        g_fLmMsg[id] = now + 1.0;
        new key[16], name[48];
        formatex(key, charsmax(key), "MODE_NAME_%d", g_iMode);
        Translate(name, charsmax(name), key, id);
        Chat(id, "LM_NO_MODE", name);
        PlayKey(id, "LM_DENY");
        return;
    }
    LmMessage(id, "LM_DISABLED");
}

// v3.1: lazerin kapali oldugu bir mod (vex_lm_block_modes) basladi: kurulu mayinlar kaldirilir
LmModeStart()
{
    if (!LmModeBlocked(g_iMode))
        return;
    new had[33], ent, n;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", LM_CLASS)) > 0)
    {
        new o = get_entvar(ent, var_iuser1);
        if (1 <= o <= g_iMax)
            had[o] = 1;
        n++;
    }
    if (!n)
        return;
    RemoveAllMines();
    log_amx("[Vexmira] lazer kapali mod (%d) basladi: %d mayin kaldirildi, kalan %d", g_iMode, n, CountMines(0));
    new key[16], name[48];
    formatex(key, charsmax(key), "MODE_NAME_%d", g_iMode);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!had[p] || !is_user_connected(p))
            continue;
        Translate(name, charsmax(name), key, p);
        Chat(p, "LM_MODE_REMOVED", name);
    }
}

// Ayni anda kurulu olabilecek lazer sayisi
MaxMines(id)
{
    new m = IsVip(id) ? get_pcvar_num(g_pLmMaxVip) : get_pcvar_num(g_pLmMax);
    if (g_iJob[id] == JOB_ENGINEER)
        m++;
    return max(0, m);
}

// Round basi verilen lazer hakki
RoundMines(id)
{
    new m = IsVip(id) ? get_pcvar_num(g_pLmPerRoundVip) : get_pcvar_num(g_pLmPerRound);
    if (g_iJob[id] == JOB_ENGINEER)
        m++;
    return clamp(m, 0, 20);
}

// Insan dogunca (roundda bir kez) lazer hakki verilir
GiveRoundMines(id)
{
    if (g_bLmGiven[id] || !LasersAllowed() || g_bZombie[id])
        return;
    g_bLmGiven[id] = true;
    g_iMines[id] = RoundMines(id);
}

bool:IsMine(ent)
{
    if (ent <= g_iMax || is_nullent(ent))
        return false;
    new cls[20];
    get_entvar(ent, var_classname, cls, charsmax(cls));
    return equal(cls, LM_CLASS) ? true : false;
}

CountMines(id)
{
    new ent, n;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", LM_CLASS)) > 0)
    {
        if (!id || get_entvar(ent, var_iuser1) == id)
            n++;
    }
    return n;
}

/* ---------------- Komutlar ---------------- */

public cmd_lm_menu(id)
{
    ShowMineMenu(id);
    return PLUGIN_HANDLED;
}

// C tusu (varsayilan radio3): insan kendi lazerine bakiyorsa aninda sokulur,
// bakmiyorsa normal telsiz menusu acilir.
public cmd_radio3(id)
{
    if (!get_pcvar_num(g_pLmEnable) || !is_user_alive(id) || g_bZombie[id])
        return PLUGIN_CONTINUE;
    new mine = AimedMine(id, get_pcvar_float(g_pLmTakeRange));
    if (!mine)
        return PLUGIN_CONTINUE;
    if (get_entvar(mine, var_iuser1) != id && !(get_user_flags(id) & ADMIN_BAN))
        return PLUGIN_CONTINUE;

    cmd_lm_take(id);
    return PLUGIN_HANDLED;
}

// -setlaser: kurulum basili tutuluyorsa iptal
public cmd_lm_release(id)
{
    if (g_iPlantAction[id] == 1)
        CancelPlant(id);
    return PLUGIN_HANDLED;
}

// -dellaser: sokme suresi varsa (vex_lm_take_time > 0) ve tus birakildiysa iptal
public cmd_lm_release_take(id)
{
    if (g_iPlantAction[id] == 2)
        CancelPlant(id);
    return PLUGIN_HANDLED;
}

CancelPlant(id)
{
    g_iPlantAction[id] = 0;
    remove_task(id + TASK_PLANT);
    if (is_user_connected(id))
        rg_send_bartime(id, 0, false);
}

LmMessage(id, const key[], val = 0)
{
    // Ayni uyari tekrar tekrar yazilmasin
    new Float:now = get_gametime();
    if (now < g_fLmMsg[id])
        return;
    g_fLmMsg[id] = now + 1.0;
    Chat(id, key, val);
    PlayKey(id, "LM_DENY");
}

public cmd_lm_plant(id)
{
    if (!is_user_alive(id) || g_bZombie[id] || g_iPlantAction[id])
        return PLUGIN_HANDLED;

    if (!LasersAllowed())
    {
        LmDenyReason(id);
        return PLUGIN_HANDLED;
    }
    if (!g_bRoundActive && !g_bCounting && !get_member_game(m_bFreezePeriod))
        return PLUGIN_HANDLED;

    if (g_iMines[id] <= 0)
    {
        LmMessage(id, "LM_NO_MINE", RoundMines(id));
        return PLUGIN_HANDLED;
    }
    if (CountMines(id) >= MaxMines(id))
    {
        LmMessage(id, "LM_LIMIT", MaxMines(id));
        return PLUGIN_HANDLED;
    }
    if (CountMines(0) >= get_pcvar_num(g_pLmTeamMax))
    {
        LmMessage(id, "LM_TEAM_LIMIT", get_pcvar_num(g_pLmTeamMax));
        return PLUGIN_HANDLED;
    }

    new Float:pos[3], Float:normal[3];
    if (!FindPlantSpot(id, pos, normal))
    {
        LmMessage(id, "LM_NO_WALL");
        return PLUGIN_HANDLED;
    }

    new Float:t = get_pcvar_float(g_pLmPlantTime);
    if (t <= 0.05)
    {
        g_iPlantAction[id] = 1;
        get_entvar(id, var_origin, g_fPlantPos[id]);
        task_PlantDone(id + TASK_PLANT);
        return PLUGIN_HANDLED;
    }

    get_entvar(id, var_origin, g_fPlantPos[id]);
    g_iPlantAction[id] = 1;
    rg_send_bartime(id, floatround(t, floatround_ceil), false);
    set_task(t, "task_PlantDone", id + TASK_PLANT);
    EmitKey(id, "LM_CHARGE");
    return PLUGIN_HANDLED;
}

public cmd_lm_take(id)
{
    if (!is_user_alive(id) || g_bZombie[id] || g_iPlantAction[id])
        return PLUGIN_HANDLED;

    new mine = AimedMine(id, get_pcvar_float(g_pLmTakeRange));
    if (!mine)
    {
        LmMessage(id, "LM_AIM_MINE");
        return PLUGIN_HANDLED;
    }
    if (get_entvar(mine, var_iuser1) != id && !(get_user_flags(id) & ADMIN_BAN))
    {
        LmMessage(id, "LM_NOT_YOURS");
        return PLUGIN_HANDLED;
    }

    get_entvar(id, var_origin, g_fPlantPos[id]);
    g_iPlantAction[id] = 2;

    // Varsayilan: ANINDA sokulur (C'ye bir kez basmak yeterli)
    new Float:t = get_pcvar_float(g_pLmTakeTime);
    if (t <= 0.05)
    {
        task_PlantDone(id + TASK_PLANT);
        return PLUGIN_HANDLED;
    }
    rg_send_bartime(id, floatround(t, floatround_ceil), false);
    set_task(t, "task_PlantDone", id + TASK_PLANT);
    return PLUGIN_HANDLED;
}

public task_PlantDone(tid)
{
    new id = tid - TASK_PLANT;
    new action = g_iPlantAction[id];
    g_iPlantAction[id] = 0;

    if (!is_user_alive(id) || g_bZombie[id] || !action)
        return;

    // Islem sirasinda yer degistirdiyse iptal
    new Float:o[3];
    get_entvar(id, var_origin, o);
    if (get_distance_f(o, g_fPlantPos[id]) > 48.0)
    {
        Chat(id, "LM_MOVED");
        return;
    }

    if (action == 1)
    {
        if (!LasersAllowed() || g_iMines[id] <= 0 || CountMines(id) >= MaxMines(id))
            return;

        new Float:pos[3], Float:normal[3];
        if (!FindPlantSpot(id, pos, normal))
        {
            Chat(id, "LM_NO_WALL");
            return;
        }
        if (CreateMine(id, pos, normal))
        {
            g_iMines[id]--;
            Chat(id, "LM_PLANTED", g_iMines[id]);
        }
    }
    else
    {
        new mine = AimedMine(id, get_pcvar_float(g_pLmTakeRange) + 10.0);
        if (!mine)
            return;
        new owner = get_entvar(mine, var_iuser1);
        if (owner != id && !(get_user_flags(id) & ADMIN_BAN))
            return;

        new Float:mo[3];
        get_entvar(mine, var_origin, mo);
        FxSparks(mo);
        MineRemove(mine);
        if (owner == id)
            g_iMines[id]++;
        else if (is_user_connected(owner))
            g_iMines[owner]++;
        EmitKey(id, "LM_PICKUP");
        Chat(id, "LM_TAKEN", g_iMines[id]);
    }
}

// Nisan alinan yuzey: duvar / zemin / tavan (sadece sabit dunya)
bool:FindPlantSpot(id, Float:pos[3], Float:normal[3])
{
    new Float:start[3], Float:end[3], Float:ofs[3], Float:ang[3], Float:fwd[3];
    get_entvar(id, var_origin, start);
    get_entvar(id, var_view_ofs, ofs);
    start[0] += ofs[0];
    start[1] += ofs[1];
    start[2] += ofs[2];

    get_entvar(id, var_v_angle, ang);
    engfunc(EngFunc_MakeVectors, ang);
    global_get(glb_v_forward, fwd);

    new Float:range = floatclamp(get_pcvar_float(g_pLmRange), 48.0, 256.0);
    end[0] = start[0] + fwd[0] * range;
    end[1] = start[1] + fwd[1] * range;
    end[2] = start[2] + fwd[2] * range;

    new tr = create_tr2();
    engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, id, tr);

    new Float:frac;
    get_tr2(tr, TR_flFraction, frac);
    new hit = get_tr2(tr, TR_pHit);
    get_tr2(tr, TR_vecEndPos, pos);
    get_tr2(tr, TR_vecPlaneNormal, normal);
    free_tr2(tr);

    if (frac >= 1.0)
        return false;

    // Hareketli kapi / asansor uzerine kurulmaz
    if (hit > 0)
    {
        new cls[32];
        get_entvar(hit, var_classname, cls, charsmax(cls));
        if (!equal(cls, "func_wall") && !equal(cls, "func_illusionary"))
            return false;
    }

    // pos yuzeyde kalir; modele gore ofset CreateMine'da (MineOrient) uygulanir
    return true;
}

// Nisan alinan / bakilan mayin: once tam nisan, sonra genis bir koni icinde en iyi aday
AimedMine(id, Float:range)
{
    new target, body;
    get_user_aiming(id, target, body, floatround(range));
    if (target > g_iMax && IsMine(target))
        return target;

    new Float:eye[3], Float:ofs[3], Float:ang[3], Float:fwd[3], Float:mo[3];
    get_entvar(id, var_origin, eye);
    get_entvar(id, var_view_ofs, ofs);
    eye[0] += ofs[0];
    eye[1] += ofs[1];
    eye[2] += ofs[2];
    get_entvar(id, var_v_angle, ang);
    engfunc(EngFunc_MakeVectors, ang);
    global_get(glb_v_forward, fwd);

    new ent, best, Float:bestScore = -1.0;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", LM_CLASS)) > 0)
    {
        get_entvar(ent, var_origin, mo);
        new Float:d = get_distance_f(eye, mo);
        if (d > range || d < 1.0)
            continue;
        new Float:dot = ((mo[0] - eye[0]) * fwd[0] + (mo[1] - eye[1]) * fwd[1] + (mo[2] - eye[2]) * fwd[2]) / d;
        // Yakindayken daha genis aci kabul edilir
        new Float:need = (d < 70.0) ? 0.55 : 0.82;
        if (dot < need)
            continue;
        new Float:score = dot - d / 2000.0;
        if (get_entvar(ent, var_iuser1) == id)
            score += 0.05;
        if (score > bestScore)
        {
            bestScore = score;
            best = ent;
        }
    }
    return best;
}

/* ---------------- Mayin yonu (v3.0 hizalama) ----------------
   Half-Life tripmine.cpp gibi: aci = VecToAngles(yuzey normali), model normal boyunca
   ofsetlenir. Istemci studio donusumu (StudioSetUpTransform: pitch ters, AngleMatrix):
   varlik acisi (P, Y, R) icin model +X = MakeVectors(-P, Y, R).forward, +Z = .up.
   Model eksenleri: E = isinin ciktigi yon, U = duvardayken yukari bakan yon.
   - HL v_tripmine (govde 3, "world"): E = +X, U = +Z, normal boyunca 8 birim, isin merkezden.
   - Vexmira lasermine.mdl: E = +X (lens ucu = attachment 0 = 10.3), montaj yuzu x = 0, 0.3 birim.
   - w_c4 yedegi: alt yuzu duvarda (E = +Z).
   Duvarda U dunya yukarisina; zemin / tavanda kuran oyuncunun bakis yonune (yamuk durmaz).
   cfg: LASERMINE_ANGLES "pitch yaw roll" (model uzayinda ek donus), LASERMINE_OFFSET (birim),
   LASERMINE_EMITTER "x y z" (model uzayinda isin cikis noktasi). Bos = modele gore otomatik. */
MinePreset(bool:tripmine, bool:c4, bool:fellBack)
{
    g_fMineAxE = Float:{1.0, 0.0, 0.0};
    g_fMineAxU = Float:{0.0, 0.0, 1.0};
    g_fMineAngOfs = Float:{0.0, 0.0, 0.0};
    if (tripmine)
    {
        g_fMineOff = 8.0;
        g_fMineEmit = Float:{0.0, 0.0, 0.0};
    }
    else if (c4)
    {
        g_fMineAxE = Float:{0.0, 0.0, 1.0};
        g_fMineAxU = Float:{1.0, 0.0, 0.0};
        g_fMineOff = 0.5;
        g_fMineEmit = Float:{0.0, 0.0, 5.0};
    }
    else
    {
        g_fMineOff = 0.3;
        g_fMineEmit = Float:{10.3, 0.0, 0.0};
    }
    if (fellBack)
        return;
    new txt[48], a[16], b[16], c[16];
    copy(txt, charsmax(txt), GetResString("LASERMINE_OFFSET", ""));
    trim(txt);
    if (txt[0])
        g_fMineOff = floatclamp(str_to_float(txt), -16.0, 32.0);
    copy(txt, charsmax(txt), GetResString("LASERMINE_EMITTER", ""));
    if (parse(txt, a, charsmax(a), b, charsmax(b), c, charsmax(c)) == 3)
    {
        g_fMineEmit[0] = str_to_float(a);
        g_fMineEmit[1] = str_to_float(b);
        g_fMineEmit[2] = str_to_float(c);
    }
    copy(txt, charsmax(txt), GetResString("LASERMINE_ANGLES", ""));
    if (parse(txt, a, charsmax(a), b, charsmax(b), c, charsmax(c)) == 3)
    {
        g_fMineAngOfs[0] = str_to_float(a);
        g_fMineAngOfs[1] = str_to_float(b);
        g_fMineAngOfs[2] = str_to_float(c);
    }
}

// Model uzayindaki v -> dunya: (E.v) n + (U.v) u + (W.v) w   (W = E x U)
stock MineMap(const Float:v[3], const Float:n[3], const Float:u[3], const Float:w[3], Float:out[3])
{
    new Float:W[3];
    W[0] = g_fMineAxE[1] * g_fMineAxU[2] - g_fMineAxE[2] * g_fMineAxU[1];
    W[1] = g_fMineAxE[2] * g_fMineAxU[0] - g_fMineAxE[0] * g_fMineAxU[2];
    W[2] = g_fMineAxE[0] * g_fMineAxU[1] - g_fMineAxE[1] * g_fMineAxU[0];
    new Float:de = g_fMineAxE[0] * v[0] + g_fMineAxE[1] * v[1] + g_fMineAxE[2] * v[2];
    new Float:du = g_fMineAxU[0] * v[0] + g_fMineAxU[1] * v[1] + g_fMineAxU[2] * v[2];
    new Float:dw = W[0] * v[0] + W[1] * v[1] + W[2] * v[2];
    for (new i = 0; i < 3; i++)
        out[i] = de * n[i] + du * u[i] + dw * w[i];
}

// Yuzey normali (+ kuran oyuncunun bakisi) -> varlik acisi + isin cikis noktasinin ofseti (dunya)
MineOrient(id, const Float:n[3], Float:ang[3], Float:emit[3])
{
    new Float:u[3], Float:w[3], Float:d;
    if (floatabs(n[2]) < 0.7 || !is_user_connected(id))
    {
        u[2] = 1.0;
    }
    else
    {
        new Float:va[3];
        get_entvar(id, var_v_angle, va);
        u[0] = floatcos(va[1], degrees);
        u[1] = floatsin(va[1], degrees);
    }
    d = u[0] * n[0] + u[1] * n[1] + u[2] * n[2];
    for (new i = 0; i < 3; i++)
        u[i] -= d * n[i];
    d = floatsqroot(u[0] * u[0] + u[1] * u[1] + u[2] * u[2]);
    if (d < 0.01)
    {
        // normal yukari / bakis normale paralel: herhangi bir dik eksen
        u[0] = 1.0 - n[0] * n[0]; u[1] = -n[0] * n[1]; u[2] = -n[0] * n[2];
        d = floatmax(0.001, floatsqroot(u[0] * u[0] + u[1] * u[1] + u[2] * u[2]));
    }
    for (new i = 0; i < 3; i++)
        u[i] /= d;
    w[0] = n[1] * u[2] - n[2] * u[1];
    w[1] = n[2] * u[0] - n[0] * u[2];
    w[2] = n[0] * u[1] - n[1] * u[0];

    // cfg aci ofseti: model uzayinda once bu donus (varlik acisi kurali ile)
    new Float:oa[3], Float:fx[3], Float:ry[3], Float:uz[3], Float:tmp[3], Float:X[3], Float:Z[3];
    oa[0] = -g_fMineAngOfs[0];
    oa[1] = g_fMineAngOfs[1];
    oa[2] = g_fMineAngOfs[2];
    engfunc(EngFunc_MakeVectors, oa);
    global_get(glb_v_forward, fx);
    global_get(glb_v_right, ry);
    global_get(glb_v_up, uz);
    MineMap(fx, n, u, w, X);
    MineMap(uz, n, u, w, Z);
    for (new i = 0; i < 3; i++)
        tmp[i] = g_fMineEmit[0] * fx[i] - g_fMineEmit[1] * ry[i] + g_fMineEmit[2] * uz[i];
    MineMap(tmp, n, u, w, emit);

    // Eksenler -> Euler (pitch +X'i yukari kaldirir; roll Z eksenini oturtur)
    engfunc(EngFunc_VecToAngles, X, ang);
    new Float:a0[3], Float:r0[3], Float:u0[3];
    a0[0] = -ang[0];
    a0[1] = ang[1];
    engfunc(EngFunc_MakeVectors, a0);
    global_get(glb_v_right, r0);
    global_get(glb_v_up, u0);
    ang[2] = floatatan2(Z[0] * r0[0] + Z[1] * r0[1] + Z[2] * r0[2], Z[0] * u0[0] + Z[1] * u0[1] + Z[2] * u0[2], degrees);
}

/* ---------------- Mayin varligi ---------------- */

// surf = yuzeydeki nokta (FindPlantSpot), normal = yuzey normali
CreateMine(id, const Float:surf[3], const Float:normal[3])
{
    if (!g_szMineModel[0])
        return 0;

    new ent = rg_create_entity("info_target");
    if (is_nullent(ent))
        return 0;

    set_entvar(ent, var_classname, LM_CLASS);
    engfunc(EngFunc_SetModel, ent, g_szMineModel);
    set_entvar(ent, var_body, g_iMineBody);
    set_entvar(ent, var_sequence, g_iMineSeq);
    set_entvar(ent, var_skin, g_iMineSkin);
    set_entvar(ent, var_framerate, 0.0);
    // v3.0: Vexmira lazer modeli: kurulum animasyonu ("deploy"), aktif olunca "idle" (lens nabzi)
    if (g_szMineDeploySeq[0])
        AnimByName(ent, g_szMineDeploySeq, g_iMineSeq, 1.0);
    else if (g_szMineSeqName[0])
        AnimByName(ent, g_szMineSeqName, g_iMineSeq, 1.0);
    set_entvar(ent, var_movetype, MOVETYPE_FLY);
    // Kurarken kati degil (oyuncu icinde kalmasin); aktif olunca kati olur ki pence ile kirilabilsin
    set_entvar(ent, var_solid, SOLID_NOT);

    // Yon: govde yuzeye oturur, isin cikisi normal boyunca disari bakar
    new Float:ang[3], Float:emit[3], Float:pos[3], Float:beamStart[3], Float:mins[3], Float:maxs[3];
    MineOrient(id, normal, ang, emit);
    for (new i = 0; i < 3; i++)
    {
        pos[i] = surf[i] + normal[i] * g_fMineOff;
        beamStart[i] = pos[i] + emit[i] + normal[i] * 0.5;
        // Kutu: montaj yuzunden isin cikisina kadar govde (+-3)
        new Float:back = -normal[i] * g_fMineOff;
        mins[i] = floatmin(floatmin(0.0, back), emit[i]) - 3.0;
        maxs[i] = floatmax(floatmax(0.0, back), emit[i]) + 3.0;
    }
    engfunc(EngFunc_SetSize, ent, mins, maxs);
    engfunc(EngFunc_SetOrigin, ent, pos);
    set_entvar(ent, var_angles, ang);
    set_entvar(ent, var_vuser3, beamStart);

    new Float:hp = float(max(50, get_pcvar_num(g_pLmHealth)));
    set_entvar(ent, var_takedamage, DAMAGE_YES);
    set_entvar(ent, var_health, hp);
    set_entvar(ent, var_max_health, hp);
    set_entvar(ent, var_iuser1, id);
    set_entvar(ent, var_iuser2, 0);
    set_entvar(ent, var_iuser3, 0);
    set_entvar(ent, var_iuser4, 0);
    set_entvar(ent, var_fuser1, get_gametime() + floatmax(0.2, get_pcvar_float(g_pLmArmTime)));
    set_entvar(ent, var_vuser1, normal);

    new r, g, b;
    MineColor(ent, r, g, b);
    new Float:c[3];
    c[0] = float(r);
    c[1] = float(g);
    c[2] = float(b);
    set_entvar(ent, var_renderfx, kRenderFxGlowShell);
    set_entvar(ent, var_rendercolor, c);
    set_entvar(ent, var_rendermode, kRenderNormal);
    set_entvar(ent, var_renderamt, 10.0);

    SetThink(ent, "fw_MineThink");
    set_entvar(ent, var_nextthink, get_gametime() + 0.1);

    EmitKey(ent, "LM_DEPLOY");
    FxRingSmall(pos, r, g, b);
    return ent;
}

MineColor(ent, &r, &g, &b)
{
    switch (get_pcvar_num(g_pLmColorMode))
    {
        case 1: // oyuncuya ozel renk
        {
            new owner = get_entvar(ent, var_iuser1);
            new c = (owner > 0) ? (owner % sizeof LM_PALETTE) : 0;
            r = LM_PALETTE[c][0];
            g = LM_PALETTE[c][1];
            b = LM_PALETTE[c][2];
            return;
        }
        case 2: // sabit renk (vex_lm_color "R G B")
        {
            new txt[16], cr[4], cg[4], cb[4];
            get_pcvar_string(g_pLmColor, txt, charsmax(txt));
            parse(txt, cr, charsmax(cr), cg, charsmax(cg), cb, charsmax(cb));
            r = clamp(str_to_num(cr), 0, 255);
            g = clamp(str_to_num(cg), 0, 255);
            b = clamp(str_to_num(cb), 0, 255);
            return;
        }
    }

    // Can durumuna gore: mavi -> sari -> kirmizi
    new Float:hp = Float:get_entvar(ent, var_health);
    new Float:mx = floatmax(1.0, Float:get_entvar(ent, var_max_health));
    new pct = floatround(hp * 100.0 / mx);
    if (pct > 60)      { r = 0;   g = 200; b = 255; }
    else if (pct > 30) { r = 255; g = 190; b = 0; }
    else               { r = 255; g = 40;  b = 40; }
}

// Isin dogrusu (a -> b) oyuncunun govde kutusundan geciyor mu?
// Kutu, oyuncunun son 0.1 sn'deki hareketi kadar genisletilir (hizli dusen / ziplayan da yakalanir).
bool:BeamHitsPlayer(const Float:a[3], const Float:b[3], p, Float:pad = 2.0)
{
    new Float:mins[3], Float:maxs[3], Float:vel[3];
    get_entvar(p, var_absmin, mins);
    get_entvar(p, var_absmax, maxs);
    get_entvar(p, var_velocity, vel);
    for (new i = 0; i < 3; i++)
    {
        new Float:d = vel[i] * 0.1;
        if (d > 0.0)
            mins[i] -= d;
        else
            maxs[i] -= d;
        mins[i] -= pad;
        maxs[i] += pad;
    }
    return SegmentHitsBox(a, b, mins, maxs);
}

// Dogru parcasi - eksen hizali kutu kesisimi (slab yontemi)
bool:SegmentHitsBox(const Float:a[3], const Float:b[3], const Float:mins[3], const Float:maxs[3])
{
    new Float:tmin = 0.0, Float:tmax = 1.0;
    for (new i = 0; i < 3; i++)
    {
        new Float:d = b[i] - a[i];
        if (floatabs(d) < 0.0001)
        {
            if (a[i] < mins[i] || a[i] > maxs[i])
                return false;
            continue;
        }
        new Float:t1 = (mins[i] - a[i]) / d;
        new Float:t2 = (maxs[i] - a[i]) / d;
        if (t1 > t2)
        {
            new Float:tt = t1;
            t1 = t2;
            t2 = tt;
        }
        if (t1 > tmin)
            tmin = t1;
        if (t2 < tmax)
            tmax = t2;
        if (tmin > tmax)
            return false;
    }
    return true;
}

// Bir noktanin isin uzerindeki en yakin noktasi
stock ClosestOnSegment(const Float:a[3], const Float:b[3], const Float:p[3], Float:out[3])
{
    new Float:ab[3], Float:len2, Float:t;
    for (new i = 0; i < 3; i++)
        ab[i] = b[i] - a[i];
    len2 = ab[0] * ab[0] + ab[1] * ab[1] + ab[2] * ab[2];
    if (len2 < 0.001)
    {
        out = a;
        return;
    }
    t = ((p[0] - a[0]) * ab[0] + (p[1] - a[1]) * ab[1] + (p[2] - a[2]) * ab[2]) / len2;
    t = floatclamp(t, 0.0, 1.0);
    for (new i = 0; i < 3; i++)
        out[i] = a[i] + ab[i] * t;
}

public fw_MineThink(ent)
{
    if (is_nullent(ent))
        return;

    new owner = get_entvar(ent, var_iuser1);
    if (!is_user_alive(owner) || g_bZombie[owner])
    {
        MineDestroy(ent, false);
        return;
    }

    new Float:now = get_gametime();
    new Float:o[3], Float:normal[3];
    get_entvar(ent, var_origin, o);
    get_entvar(ent, var_vuser1, normal);

    new Float:start[3], Float:end[3];
    // Isin modelin cikis noktasindan baslar (CreateMine'da hesaplanir)
    get_entvar(ent, var_vuser3, start);

    // Kurulum: kisa sarj, sonra isin acilir
    if (get_entvar(ent, var_iuser2) == 0)
    {
        if (now >= Float:get_entvar(ent, var_fuser1))
        {
            // v3.1: isin en fazla vex_lm_max_range kadar uzar; duvara ulasmazsa havada biter
            new Float:maxr = floatclamp(get_pcvar_float(g_pLmMaxRange), 32.0, 8192.0);
            end[0] = start[0] + normal[0] * maxr;
            end[1] = start[1] + normal[1] * maxr;
            end[2] = start[2] + normal[2] * maxr;

            engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ent, 0);
            get_tr2(0, TR_vecEndPos, end);
            set_entvar(ent, var_vuser2, end);

            new r, g, b;
            MineColor(ent, r, g, b);
            if (get_pcvar_num(g_pDbgDirs))
                log_amx("[Vexmira] DIRCHK lm_beam len=%.1f max=%.1f", get_distance_f(start, end), maxr);
            new beam = BeamCreate(start, end, r, g, b, clamp(get_pcvar_num(g_pLmBeamWidth), 1, 100), 200);
            if (beam)
                set_entvar(beam, var_iuser1, BEAM_MARK_LM);
            set_entvar(ent, var_iuser3, beam);
            set_entvar(ent, var_iuser2, 1);

            EmitKey(ent, "LM_ACTIVATE");
            if (g_szMineSeqName[0])
                AnimByName(ent, g_szMineSeqName, g_iMineSeq, 1.0);
            FxLight(o, r, g, b, 14, 8, 20);
            FxRingSmall(o, r, g, b);
        }
        set_entvar(ent, var_nextthink, now + 0.1);
        return;
    }

    // v3.0 Volt EMP: mayin gecici olarak kapali (isin gizli, vurmaz)
    if (MineEmpCheck(ent, o, now))
    {
        set_entvar(ent, var_nextthink, now + 0.1);
        return;
    }

    // Kimse ustunde degilse kati yap (zombi pencesi carpabilsin)
    if (get_entvar(ent, var_solid) == SOLID_NOT && !PlayerNear(o, 30.0))
    {
        set_entvar(ent, var_solid, SOLID_BBOX);
        engfunc(EngFunc_SetOrigin, ent, o);
    }

    // Vurus sonrasi parlama bitti mi?
    new Float:flash = Float:get_entvar(ent, var_fuser2);
    if (flash > 0.0 && now >= flash)
    {
        set_entvar(ent, var_fuser2, 0.0);
        MineRefreshColor(ent);
    }

    // Aktif: isina degen TUM zombiler (parasut / ziplama / egilme / arkada durma fark etmez)
    get_entvar(ent, var_vuser2, end);
    new Float:po[3], Float:hitp[3];
    for (new z = 1; z <= g_iMax; z++)
    {
        if (!is_user_alive(z) || !g_bZombie[z] || g_fBurrow[z] > now)
            continue;
        if (!BeamHitsPlayer(start, end, z))
            continue;

        get_entvar(z, var_origin, po);
        ClosestOnSegment(start, end, po, hitp);
        MineHit(ent, owner, z, hitp);
        if (is_nullent(ent) || (get_entvar(ent, var_flags) & FL_KILLME))
            return;
    }

    // Hafif nabiz isigi
    if (random_num(1, 15) == 1)
    {
        new r, g, b;
        MineColor(ent, r, g, b);
        FxLight(o, r, g, b, 6, 5, 10);
    }

    set_entvar(ent, var_nextthink, now + 0.1);
}

bool:PlayerNear(const Float:o[3], Float:dist)
{
    new Float:po[3];
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p))
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) < dist + 20.0)
            return true;
    }
    return false;
}

MineHit(ent, owner, zombie, const Float:point[3])
{
    new Float:now = get_gametime();
    if (now < g_fLmCd[zombie])
        return;
    g_fLmCd[zombie] = now + 0.25;

    new bool:special = (g_bBoss[zombie] || g_bNemesis[zombie] || g_bAssassin[zombie]) ? true : false;
    new bool:oneshot = get_pcvar_num(g_pLmOneShot) ? true : false;
    new Float:dmg;
    if (special)
        dmg = get_pcvar_float(g_pLmSpecialDmg);
    else if (oneshot)
        dmg = 999999.0;
    else
        dmg = get_pcvar_float(g_pLmDamage);

    new r, g, b;
    MineColor(ent, r, g, b);

    FxSparks(point);
    FxLight(point, r, g, b, 16, 4, 30);
    FadeOne(zombie, r, g, b, 120, 0.35);
    EmitKey(ent, "LM_HIT");

    // Isin kisa bir an parlar
    new beam = get_entvar(ent, var_iuser3);
    if (beam > 0 && !is_nullent(beam))
        BeamColor(beam, 255, 255, 255, 255);
    set_entvar(ent, var_fuser2, now + 0.15);

    // Tek atmayan modda (veya ozel karakterde) geri itme
    if (!oneshot || special)
    {
        new Float:vel[3];
        get_entvar(zombie, var_velocity, vel);
        vel[0] = -vel[0] * 0.9;
        vel[1] = -vel[1] * 0.9;
        vel[2] = 180.0;
        set_entvar(zombie, var_velocity, vel);
    }

    new bool:wasAlive = is_user_alive(zombie) ? true : false;
    ExecuteHamB(Ham_TakeDamage, zombie, ent, owner, dmg, DMG_ENERGYBEAM);

    if (wasAlive && !is_user_alive(zombie))
    {
        // Parcalanma efekti
        FxSprite(point, g_sprExplode, 6, 220);
        FxStreak(point, 7, 40, 220);
        FxLight(point, r, g, b, 30, 6, 30);
        EmitKey(ent, "LM_KILL");
        if (!is_nullent(ent))
            MineDamage(ent, get_pcvar_float(g_pLmKillWear), 0);
    }
    else if (!is_nullent(ent))
        MineDamage(ent, get_pcvar_float(g_pLmWear), zombie);
}

MineDamage(ent, Float:amount, attacker)
{
    if (amount <= 0.0)
        return;

    new Float:hp = Float:get_entvar(ent, var_health) - amount;
    if (hp <= 0.0)
    {
        new owner = get_entvar(ent, var_iuser1);
        if (is_user_connected(owner))
        {
            if (attacker && is_user_connected(attacker))
            {
                new name[32];
                get_user_name(attacker, name, charsmax(name));
                Chat(owner, "LM_DESTROYED", name);
            }
            else
                Chat(owner, "LM_WORN_OUT");
        }
        MineDestroy(ent, true);
        return;
    }
    set_entvar(ent, var_health, hp);
    MineRefreshColor(ent);
}

MineRefreshColor(ent)
{
    new r, g, b;
    MineColor(ent, r, g, b);
    new beam = get_entvar(ent, var_iuser3);
    if (beam > 0 && !is_nullent(beam))
        BeamColor(beam, r, g, b, 200);
    new Float:c[3];
    c[0] = float(r);
    c[1] = float(g);
    c[2] = float(b);
    set_entvar(ent, var_rendercolor, c);
}

// Mayin + ikmal kutusu hasari (info_target)
public fw_EntTakeDamage(ent, inflictor, attacker, Float:damage, bits)
{
    if (ent <= g_iMax || is_nullent(ent))
        return HAM_IGNORED;

    new cls[20];
    get_entvar(ent, var_classname, cls, charsmax(cls));

    if (equal(cls, "vex_airdrop"))
        return HAM_SUPERCEDE;
    if (equal(cls, "vex_egg"))
        return EggTakeDamage(ent, attacker, damage);
    if (equal(cls, SPORE_CLASS))
        return SporeTakeDamage(ent, attacker, damage);
    if (!equal(cls, LM_CLASS))
        return HAM_IGNORED;

    // Sadece zombiler kirabilir
    if (!(1 <= attacker <= g_iMax) || !is_user_connected(attacker) || !g_bZombie[attacker])
        return HAM_SUPERCEDE;

    new Float:mult = get_pcvar_float(g_pLmZMult);
    if (g_bNemesis[attacker] || g_bAssassin[attacker] || g_bBoss[attacker])
        mult *= 2.5;

    new Float:o[3];
    get_entvar(ent, var_origin, o);
    FxSparks(o);
    MineDamage(ent, damage * mult, attacker);
    return HAM_SUPERCEDE;
}

MineDestroy(ent, bool:explode)
{
    if (is_nullent(ent))
        return;

    new Float:o[3];
    get_entvar(ent, var_origin, o);

    if (explode)
    {
        FxExplosion(o);
        FxSparks(o);
        FxRingSmall(o, 255, 80, 0);
        EmitKey(ent, "LM_BREAK");

        // Kucuk patlama: yakindaki zombilere hafif hasar
        new owner = get_entvar(ent, var_iuser1);
        new Float:po[3];
        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_alive(p) || !g_bZombie[p])
                continue;
            get_entvar(p, var_origin, po);
            if (get_distance_f(o, po) <= 130.0)
                ExecuteHamB(Ham_TakeDamage, p, 0, is_user_connected(owner) ? owner : 0, 40.0, DMG_BLAST);
        }
    }
    MineRemove(ent);
}

MineRemove(ent)
{
    if (is_nullent(ent))
        return;

    new beam = get_entvar(ent, var_iuser3);
    if (beam > 0 && !is_nullent(beam))
        set_entvar(beam, var_flags, FL_KILLME);

    SetThink(ent, "");
    set_entvar(ent, var_iuser1, 0);
    set_entvar(ent, var_iuser3, 0);
    set_entvar(ent, var_takedamage, DAMAGE_NO);
    set_entvar(ent, var_solid, SOLID_NOT);
    set_entvar(ent, var_classname, "vex_removed");
    set_entvar(ent, var_flags, FL_KILLME);
}

RemovePlayerMines(id, bool:fx)
{
    new ent;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", LM_CLASS)) > 0)
    {
        if (get_entvar(ent, var_iuser1) != id)
            continue;
        if (fx)
        {
            new Float:o[3];
            get_entvar(ent, var_origin, o);
            FxSparks(o);
        }
        MineRemove(ent);
    }
}

RemoveAllMines()
{
    new ent;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", LM_CLASS)) > 0)
        MineRemove(ent);

    // Sahipsiz kalan isinlar (mayin / lazer bomba)
    ent = 0;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "beam")) > 0)
    {
        new mark = get_entvar(ent, var_iuser1);
        if (mark == BEAM_MARK_LM || mark == BEAM_MARK_NADE || mark == BEAM_MARK_DROP)
            set_entvar(ent, var_flags, FL_KILLME);
    }

    for (new id = 1; id <= g_iMax; id++)
    {
        if (g_iPlantAction[id])
            CancelPlant(id);
    }
}

/* ---------------- Bilgi / menu ---------------- */

// Lazere nisan alininca: sahibi + can
bool:MineAimInfo(id)
{
    new target, body;
    get_user_aiming(id, target, body, 600);
    if (target <= g_iMax || !IsMine(target))
        return false;

    new owner = get_entvar(target, var_iuser1), name[32];
    if (is_user_connected(owner))
        get_user_name(owner, name, charsmax(name));
    else
        copy(name, charsmax(name), "-");

    new r, g, b;
    MineColor(target, r, g, b);
    set_hudmessage(r, g, b, -1.0, Y_AIM, 0, 0.0, 0.9, 0.0, 0.1, 3);
    show_hudmessage(id, "%L", id, (owner == id) ? "LM_AIM_INFO_MINE" : "LM_AIM_INFO", name, floatround(Float:get_entvar(target, var_health)), floatround(Float:get_entvar(target, var_max_health)));
    return true;
}

TickMineHints()
{
    if (!g_bRoundActive || !LasersAllowed() || g_iFrame % 5)
        return;

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || is_user_bot(id) || g_bZombie[id] || g_bMineHint[id] || g_iMines[id] <= 0)
            continue;
        if (g_iSet[id] & SET_NO_TIPS)
            continue;
        g_bMineHint[id] = true;
        Chat(id, "LM_HINT", g_iMines[id]);
        set_hudmessage(CLR_HUMAN, -1.0, Y_AIM + 0.08, 0, 0.0, 5.0, 0.2, 0.5, 3);
        show_hudmessage(id, "%L", id, "LM_HINT_HUD");
    }
}

ShowMineMenu(id)
{
    new title[192], item[96];
    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "LM_MENU", id, "LM_MENU_SUB", g_iMines[id], CountMines(id), MaxMines(id));
    new menu = menu_create(title, "menu_mine_handler");

    new bool:ok = LasersAllowed();
    formatex(item, charsmax(item), ok ? "\y%L" : "\d%L", id, "LM_M_PLANT"); MenuAdd(menu, item, 1);
    formatex(item, charsmax(item), "\y%L", id, "LM_M_TAKE"); MenuAdd(menu, item, 2);
    formatex(item, charsmax(item), "\y%L", id, "LM_M_INFO"); MenuAdd(menu, item, 3);
    formatex(item, charsmax(item), "\y%L", id, "LM_M_BIND"); MenuAdd(menu, item, 4);

    if (!ok)
    {
        formatex(item, charsmax(item), "\d%L", id, (g_iMode == MODE_BOSS && !get_pcvar_num(g_pLmBoss)) ? "LM_NO_BOSS_SHORT" : (get_pcvar_num(g_pLmEnable) && LmModeBlocked(g_iMode)) ? "LM_NO_MODE_SHORT" : "LM_DISABLED_SHORT");
        menu_addtext(menu, item, 0);
    }
    else
    {
        formatex(item, charsmax(item), "\d%L", id, "LM_M_RULE", RoundMines(id));
        menu_addtext(menu, item, 0);
    }
    MenuFinish(id, menu);
}

public menu_mine_handler(id, menu, item)
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
        case 1: cmd_lm_plant(id);
        case 2: cmd_lm_take(id);
        case 3:
        {
            Chat(id, "LM_INFO_1", RoundMines(id));
            Chat(id, "LM_INFO_2");
            Chat(id, "LM_INFO_3");
            ShowMineMenu(id);
        }
        case 4:
        {
            console_print(id, "");
            console_print(id, "======== VEXMIRA - LAZER ========");
            console_print(id, "bind v +setlaser");
            console_print(id, "bind c +dellaser");
            console_print(id, "=================================");
            Chat(id, "LM_BIND_PRINTED");
        }
    }
    return PLUGIN_HANDLED;
}


/* ================================================================== */
/*  BOMBA MODLARI (bomba elindeyken SAG TIK ile degisir)               */
/*  Normal   : klasik sure                                             */
/*  Carpma   : ilk degdigi yerde patlar                                */
/*  Sensor   : yere oturur, zombi yaklasinca patlar (bekleme)          */
/*  Lazer    : yere oturur, attigin yone kirmizi lazer ceker; zombi    */
/*             lazeri kesince patlar                                   */
/*  Gudumlu  : en yakin zombiye yonelir (sadece HE / ates)             */
/*  Parcali  : patlayinca etrafa 4 kucuk bomba sacar (sadece HE / ates)*/
/* ================================================================== */

GrenadeSlot(WeaponIdType:wid)
{
    switch (wid)
    {
        case WEAPON_HEGRENADE: return 0;
        case WEAPON_SMOKEGRENADE: return 1;
        case WEAPON_FLASHBANG: return 2;
    }
    return -1;
}

bool:NadeModeAllowed(slot, mode, bool:zombie)
{
    if (mode == NM_NORMAL)
        return true;
    if (zombie)
        return (mode == NM_IMPACT) ? true : false;

    switch (slot)
    {
        case 0: return true;
        case 1: return (mode == NM_IMPACT || mode == NM_SENSOR || mode == NM_LASER) ? true : false;
        case 2: return (mode == NM_IMPACT) ? true : false;
    }
    return false;
}

ShowNadeMode(id, slot)
{
    if (is_user_bot(id))
        return;

    new key[16], nm[32];
    formatex(key, charsmax(key), "NMODE_%d", g_iNadeMode[id][slot]);
    formatex(nm, charsmax(nm), "%L", id, key);

    set_hudmessage(CLR_WARN, -1.0, 0.62, 0, 0.0, 2.0, 0.0, 0.3, 4);
    show_hudmessage(id, "%L", id, "NMODE_HUD", nm);
}

// Sag tik: sonraki mod
public fw_NadeAttack2(weapon)
{
    if (!get_pcvar_num(g_pNadeModes))
        return HAM_IGNORED;

    new id = get_member(weapon, m_pPlayer);
    if (!(1 <= id <= g_iMax) || !is_user_alive(id))
        return HAM_IGNORED;

    new Float:now = get_gametime();
    set_member(weapon, m_Weapon_flNextSecondaryAttack, 0.35);
    if (now < g_fNadeHud[id])
        return HAM_SUPERCEDE;
    g_fNadeHud[id] = now + 0.3;

    new slot = GrenadeSlot(WeaponIdType:get_member(weapon, m_iId));
    if (slot < 0)
        return HAM_IGNORED;

    new bool:zm = g_bZombie[id] ? true : false;
    new m = g_iNadeMode[id][slot];
    for (new i = 0; i < NUM_NMODES; i++)
    {
        m = (m + 1) % NUM_NMODES;
        if (NadeModeAllowed(slot, m, zm))
            break;
    }
    g_iNadeMode[id][slot] = m;

    ShowNadeMode(id, slot);
    PlayKey(id, "NADE_MODE");
    return HAM_SUPERCEDE;
}

public fw_NadeDeploy(weapon)
{
    if (!get_pcvar_num(g_pNadeModes))
        return HAM_IGNORED;

    new id = get_member(weapon, m_pPlayer);
    if (!(1 <= id <= g_iMax) || !is_user_alive(id))
        return HAM_IGNORED;

    new slot = GrenadeSlot(WeaponIdType:get_member(weapon, m_iId));
    if (slot >= 0)
    {
        if (!NadeModeAllowed(slot, g_iNadeMode[id][slot], g_bZombie[id] ? true : false))
            g_iNadeMode[id][slot] = NM_NORMAL;
        ShowNadeMode(id, slot);
    }
    return HAM_IGNORED;
}

// Atis aninda modu bombaya isle
// var_iuser4 = mod + 1, var_iuser3 = durum (0 havada, 1 yerlesti/kuruluyor, 2 aktif, 3 tetiklendi)
// var_iuser2 = lazer isini, var_fuser1 = omur sonu, var_fuser4 = kurulma zamani, var_fuser3 = sonraki bip
NadeOnThrow(id, ent, slot)
{
    if (!get_pcvar_num(g_pNadeModes) || is_nullent(ent))
        return;

    new mode = g_iNadeMode[id][slot];
    if (!NadeModeAllowed(slot, mode, g_bZombie[id] ? true : false) || mode == NM_NORMAL)
        return;

    new Float:now = get_gametime();
    set_entvar(ent, var_iuser4, mode + 1);
    set_entvar(ent, var_iuser3, 0);
    set_entvar(ent, var_iuser2, 0);
    set_entvar(ent, var_fuser4, now);
    set_entvar(ent, var_fuser3, now);

    // Atis yonu
    new Float:ang[3], Float:fwd[3];
    get_entvar(id, var_v_angle, ang);
    engfunc(EngFunc_MakeVectors, ang);
    global_get(glb_v_forward, fwd);
    set_entvar(ent, var_vuser4, fwd);

    switch (mode)
    {
        case NM_SENSOR:
        {
            set_entvar(ent, var_dmgtime, now + 9999.0);
            set_entvar(ent, var_fuser1, now + floatmax(5.0, get_pcvar_float(g_pNadeSensorLife)));
            FxTrail(ent, 255, 40, 40);
        }
        case NM_LASER:
        {
            set_entvar(ent, var_dmgtime, now + 9999.0);
            set_entvar(ent, var_fuser1, now + floatmax(5.0, get_pcvar_float(g_pNadeSensorLife)));
            FxTrail(ent, 255, 0, 60);
        }
        case NM_HOMING:
        {
            set_entvar(ent, var_dmgtime, now + 6.0);
            set_entvar(ent, var_gravity, 0.35);
            FxTrail(ent, 255, 40, 200);
        }
        case NM_IMPACT:
            FxTrail(ent, 255, 255, 255);
    }
}

// Patlama: hemen (duman bombasi icin yerde sayilmali)
NadeDetonateNow(ent)
{
    set_entvar(ent, var_velocity, Float:{0.0, 0.0, 0.0});
    set_entvar(ent, var_movetype, MOVETYPE_NONE);
    set_entvar(ent, var_flags, get_entvar(ent, var_flags) | FL_ONGROUND);
    set_entvar(ent, var_dmgtime, get_gametime());
    set_entvar(ent, var_nextthink, get_gametime() + 0.01);
}

public fw_GrenadeTouch(ent, other)
{
    new mode = get_entvar(ent, var_iuser4) - 1;
    if (mode != NM_IMPACT && mode != NM_HOMING && mode != NM_LASER)
        return HAM_IGNORED;
    if (other == get_entvar(ent, var_owner))
        return HAM_IGNORED;

    // LAZER TUZAK: degdigi duvara / zemine / tavana normal lazer mayini gibi YAPISIR
    if (mode == NM_LASER)
    {
        if (get_entvar(ent, var_iuser3) != 0)
            return HAM_SUPERCEDE;
        if (other > 0)
        {
            // Sadece sabit dunya parcalari (kapi / oyuncu / tetik degil)
            if (other <= g_iMax || get_entvar(other, var_solid) != SOLID_BSP)
                return HAM_IGNORED;
            new mt = get_entvar(other, var_movetype);
            if (mt != MOVETYPE_NONE && mt != MOVETYPE_PUSH)
                return HAM_IGNORED;
        }
        NadeStick(ent);
        return HAM_SUPERCEDE;
    }

    if (Float:get_entvar(ent, var_dmgtime) <= get_gametime())
        return HAM_IGNORED;

    // Sadece dunya veya oyuncu (silah kutusu vb. degil)
    if (other > g_iMax)
    {
        new cls[20];
        get_entvar(other, var_classname, cls, charsmax(cls));
        if (equal(cls, "weaponbox") || equal(cls, "grenade"))
            return HAM_IGNORED;
    }

    NadeDetonateNow(ent);
    return HAM_IGNORED;
}

// Lazer tuzak: carptigi yuzeye yapis, yuzey normalini kaydet
NadeStick(ent)
{
    new Float:o[3], Float:vel[3], Float:dir[3], Float:a[3], Float:b[3], Float:normal[3], Float:pos[3];
    get_entvar(ent, var_origin, o);
    get_entvar(ent, var_velocity, vel);

    new Float:len = floatsqroot(vel[0] * vel[0] + vel[1] * vel[1] + vel[2] * vel[2]);
    if (len < 1.0)
    {
        dir[0] = 0.0;
        dir[1] = 0.0;
        dir[2] = -1.0;
    }
    else
    {
        dir[0] = vel[0] / len;
        dir[1] = vel[1] / len;
        dir[2] = vel[2] / len;
    }

    new bool:found;
    new tr = create_tr2();
    for (new attempt = 0; attempt < 2 && !found; attempt++)
    {
        if (attempt == 1)
        {
            // Hareket yonunde yuzey yoksa: alta bak
            dir[0] = 0.0;
            dir[1] = 0.0;
            dir[2] = -1.0;
        }
        for (new i = 0; i < 3; i++)
        {
            a[i] = o[i] - dir[i] * 24.0;
            b[i] = o[i] + dir[i] * 32.0;
        }
        engfunc(EngFunc_TraceLine, a, b, IGNORE_MONSTERS, ent, tr);
        new Float:frac;
        get_tr2(tr, TR_flFraction, frac);
        if (frac < 1.0 && !get_tr2(tr, TR_AllSolid))
        {
            get_tr2(tr, TR_vecEndPos, pos);
            get_tr2(tr, TR_vecPlaneNormal, normal);
            found = true;
        }
    }
    free_tr2(tr);

    if (!found)
    {
        pos = o;
        normal[0] = -dir[0];
        normal[1] = -dir[1];
        normal[2] = -dir[2];
    }

    pos[0] += normal[0] * 3.0;
    pos[1] += normal[1] * 3.0;
    pos[2] += normal[2] * 3.0;

    set_entvar(ent, var_velocity, Float:{0.0, 0.0, 0.0});
    set_entvar(ent, var_avelocity, Float:{0.0, 0.0, 0.0});
    set_entvar(ent, var_movetype, MOVETYPE_NONE);
    set_entvar(ent, var_flags, get_entvar(ent, var_flags) | FL_ONGROUND);
    engfunc(EngFunc_SetOrigin, ent, pos);

    new Float:ang[3];
    engfunc(EngFunc_VecToAngles, normal, ang);
    ang[0] += 90.0;
    set_entvar(ent, var_angles, ang);

    new Float:now = get_gametime();
    set_entvar(ent, var_vuser2, normal);
    set_entvar(ent, var_iuser3, 1);
    set_entvar(ent, var_fuser4, now + floatmax(0.2, get_pcvar_float(g_pNadeLaserArm)));
    EmitKey(ent, "NADE_ARM", CHAN_ITEM);
    FxSparks(pos);
}

// Her 0.1 sn: sensor / lazer / gudumlu bombalar
public task_NadeTick()
{
    if (!get_pcvar_num(g_pNadeModes))
        return;

    new ent, Float:now = get_gametime();
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "grenade")) > 0)
    {
        new mode = get_entvar(ent, var_iuser4) - 1;
        if (mode != NM_SENSOR && mode != NM_LASER && mode != NM_HOMING)
            continue;
        if (get_entvar(ent, var_flags) & FL_KILLME)
            continue;

        switch (mode)
        {
            case NM_SENSOR: NadeSensor(ent, now);
            case NM_LASER:  NadeLaser(ent, now);
            case NM_HOMING: NadeHoming(ent, now);
        }
    }
}

bool:NadeLanded(ent)
{
    if (get_entvar(ent, var_flags) & FL_ONGROUND)
    {
        new Float:vel[3];
        get_entvar(ent, var_velocity, vel);
        return (vel[0] * vel[0] + vel[1] * vel[1] + vel[2] * vel[2] < 2500.0) ? true : false;
    }

    // Hiz cok dusuk ve altinda zemin var
    new Float:vel[3];
    get_entvar(ent, var_velocity, vel);
    if (vel[0] * vel[0] + vel[1] * vel[1] + vel[2] * vel[2] >= 400.0)
        return false;

    new Float:o[3], Float:down[3], Float:frac;
    get_entvar(ent, var_origin, o);
    down = o;
    down[2] -= 10.0;
    engfunc(EngFunc_TraceLine, o, down, IGNORE_MONSTERS, ent, 0);
    get_tr2(0, TR_flFraction, frac);
    return (frac < 1.0) ? true : false;
}

// Zombi gorus hattinda mi? (duvar arkasindaki zombi sensoru tetiklemez)
bool:NadeSees(ent, const Float:o[3], z)
{
    new Float:zo[3];
    get_entvar(z, var_origin, zo);
    engfunc(EngFunc_TraceLine, o, zo, IGNORE_MONSTERS, ent, 0);
    new Float:frac;
    get_tr2(0, TR_flFraction, frac);
    return (frac >= 0.99) ? true : false;
}

/* SENSOR: yere oturur, kurulur (bip), zombi menzile ve gorus hattina girince
   kisa bir uyari bipiyle patlar. Kendiliginden / hemen patlamaz. */
NadeSensor(ent, Float:now)
{
    new st = get_entvar(ent, var_iuser3);
    new Float:o[3], Float:eye[3];
    get_entvar(ent, var_origin, o);
    eye = o;
    eye[2] += 10.0;

    if (now > Float:get_entvar(ent, var_fuser1) && st < 3)
    {
        NadeDetonateNow(ent);
        return;
    }

    switch (st)
    {
        case 0: // havada
        {
            if (!NadeLanded(ent))
                return;
            set_entvar(ent, var_velocity, Float:{0.0, 0.0, 0.0});
            set_entvar(ent, var_movetype, MOVETYPE_NONE);
            set_entvar(ent, var_flags, get_entvar(ent, var_flags) | FL_ONGROUND);
            set_entvar(ent, var_fuser4, now + floatmax(0.3, get_pcvar_float(g_pNadeSensorArm)));
            set_entvar(ent, var_iuser3, 1);
            EmitKey(ent, "NADE_ARM", CHAN_ITEM);
            FxLight(o, 255, 200, 0, 6, 5, 10);
        }
        case 1: // kuruluyor
        {
            if (now < Float:get_entvar(ent, var_fuser4))
            {
                if (now >= Float:get_entvar(ent, var_fuser3))
                {
                    set_entvar(ent, var_fuser3, now + 0.5);
                    FxLight(o, 255, 200, 0, 5, 4, 10);
                }
                return;
            }
            set_entvar(ent, var_iuser3, 2);
            set_entvar(ent, var_fuser3, now);
            EmitKey(ent, "NADE_BEEP", CHAN_ITEM);
        }
        case 2: // aktif: zombi bekliyor
        {
            new Float:radius = floatmax(50.0, get_pcvar_float(g_pNadeProx));
            if (now >= Float:get_entvar(ent, var_fuser3))
            {
                set_entvar(ent, var_fuser3, now + 1.0);
                new Float:ring[3];
                ring = o;
                ring[2] -= 4.0;
                FxRingEx(ring, 255, 30, 30, floatround(radius), 4, 6, 120);
                FxLight(o, 255, 0, 0, 6, 5, 10);
                EmitKey(ent, "NADE_BEEP", CHAN_ITEM, ATTN_STATIC);
            }

            new Float:po[3];
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_alive(p) || !g_bZombie[p])
                    continue;
                get_entvar(p, var_origin, po);
                if (get_distance_f(o, po) > radius || !NadeSees(ent, eye, p))
                    continue;

                // Tetiklendi: kisa uyari, sonra patlama
                set_entvar(ent, var_iuser3, 3);
                set_entvar(ent, var_fuser4, now + 0.25);
                EmitKey(ent, "NADE_TRIGGER", CHAN_ITEM);
                FxLight(o, 255, 0, 0, 14, 3, 30);
                return;
            }
        }
        default: // tetiklendi
        {
            if (now >= Float:get_entvar(ent, var_fuser4))
                NadeDetonateNow(ent);
        }
    }
}

/* LAZER TUZAK: duvara / zemine yapisir, yuzeyden disari dik kirmizi lazer
   ceker. Lazeri kesen zombinin UZERINDE patlar. */
NadeLaser(ent, Float:now)
{
    new st = get_entvar(ent, var_iuser3);
    new Float:o[3], Float:normal[3], Float:start[3], Float:end[3];
    get_entvar(ent, var_origin, o);

    if (now > Float:get_entvar(ent, var_fuser1) && st >= 1)
    {
        NadeCleanup(ent);
        NadeDetonateNow(ent);
        return;
    }

    switch (st)
    {
        case 0: // havada: yere oturup durduysa (dokunma kacirildiysa) oldugu yere yapis
        {
            if (NadeLanded(ent))
                NadeStick(ent);
        }
        case 1: // yapisti, kuruluyor
        {
            if (now < Float:get_entvar(ent, var_fuser4))
                return;

            get_entvar(ent, var_vuser2, normal);
            for (new i = 0; i < 3; i++)
            {
                start[i] = o[i] + normal[i] * 4.0;
                end[i] = start[i] + normal[i] * floatmax(64.0, get_pcvar_float(g_pNadeLaser));
            }
            engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ent, 0);
            get_tr2(0, TR_vecEndPos, end);
            set_entvar(ent, var_vuser1, start);
            set_entvar(ent, var_vuser3, end);

            new beam = BeamCreate(start, end, 255, 20, 40, 6, 210);
            if (beam)
                set_entvar(beam, var_iuser1, BEAM_MARK_NADE);
            set_entvar(ent, var_iuser2, beam);
            set_entvar(ent, var_iuser3, 2);
            set_entvar(ent, var_fuser3, now);
            EmitKey(ent, "LM_ACTIVATE", CHAN_ITEM);
        }
        case 2: // aktif
        {
            get_entvar(ent, var_vuser1, start);
            get_entvar(ent, var_vuser3, end);

            new Float:po[3], Float:hitp[3];
            for (new z = 1; z <= g_iMax; z++)
            {
                if (!is_user_alive(z) || !g_bZombie[z])
                    continue;
                if (!BeamHitsPlayer(start, end, z))
                    continue;

                // Zombinin uzerinde patla
                get_entvar(z, var_origin, po);
                ClosestOnSegment(start, end, po, hitp);
                FxSparks(hitp);
                EmitKey(ent, "NADE_TRIGGER", CHAN_ITEM);
                NadeCleanup(ent);
                engfunc(EngFunc_SetOrigin, ent, hitp);
                NadeDetonateNow(ent);
                return;
            }

            if (now >= Float:get_entvar(ent, var_fuser3))
            {
                set_entvar(ent, var_fuser3, now + 1.5);
                FxLight(o, 255, 0, 0, 5, 5, 10);
            }
        }
    }
}

NadeHoming(ent, Float:now)
{
    if (now - Float:get_entvar(ent, var_fuser4) < 0.25)
        return;

    new Float:o[3], Float:po[3], best, Float:bd = get_pcvar_float(g_pNadeHoming);
    get_entvar(ent, var_origin, o);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || !g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        new Float:d = get_distance_f(o, po);
        if (d >= bd)
            continue;
        engfunc(EngFunc_TraceLine, o, po, IGNORE_MONSTERS, ent, 0);
        new Float:frac;
        get_tr2(0, TR_flFraction, frac);
        if (frac < 1.0)
            continue;
        bd = d;
        best = p;
    }
    if (!best)
        return;

    get_entvar(best, var_origin, po);
    po[2] += 10.0;

    new Float:vel[3], Float:want[3];
    get_entvar(ent, var_velocity, vel);
    new Float:d = floatmax(1.0, get_distance_f(o, po));
    want[0] = (po[0] - o[0]) / d * 560.0;
    want[1] = (po[1] - o[1]) / d * 560.0;
    want[2] = (po[2] - o[2]) / d * 560.0;

    vel[0] = vel[0] * 0.45 + want[0] * 0.55;
    vel[1] = vel[1] * 0.45 + want[1] * 0.55;
    vel[2] = vel[2] * 0.45 + want[2] * 0.55;
    set_entvar(ent, var_velocity, vel);
}

// Bomba kalkarken lazer isinini temizle
NadeCleanup(ent)
{
    if (get_entvar(ent, var_iuser4) - 1 != NM_LASER)
        return;
    new beam = get_entvar(ent, var_iuser2);
    if (beam > 0 && !is_nullent(beam))
        set_entvar(beam, var_flags, FL_KILLME);
    set_entvar(ent, var_iuser2, 0);
}

// Parcali: ana patlamanin etrafina kucuk patlamalar
NadeCluster(ent, type)
{
    new Float:o[3];
    get_entvar(ent, var_origin, o);
    new owner = get_entvar(ent, var_owner);
    new count = clamp(get_pcvar_num(g_pCluster), 1, 8);

    for (new i = 0; i < count; i++)
    {
        new Float:a = float(i) * (360.0 / float(count)) + random_float(-20.0, 20.0);
        new Float:dist = random_float(90.0, 160.0);
        new params[5];
        params[0] = _:(o[0] + floatcos(a, degrees) * dist);
        params[1] = _:(o[1] + floatsin(a, degrees) * dist);
        params[2] = _:(o[2] + 10.0);
        params[3] = owner;
        params[4] = type;
        set_task(0.25 + 0.15 * float(i), "task_ClusterBlast", TASK_CLUSTER + random(1000), params, 5);
    }
}

public task_ClusterBlast(params[])
{
    new Float:o[3], Float:po[3];
    o[0] = Float:params[0];
    o[1] = Float:params[1];
    o[2] = Float:params[2];
    new owner = params[3];
    if (!is_user_connected(owner))
        owner = 0;

    FxExplosion(o);
    FxSparks(o);
    FxRingSmall(o, 255, 120, 0);
    EmitKeyPos(o, "NADE_CLUSTER");

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || !g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > 120.0)
            continue;
        if (params[4] == NADE_FIRE)
            Ignite(p, owner, 3);
        ExecuteHamB(Ham_TakeDamage, p, 0, owner, get_pcvar_float(g_pNadeClusterDmg), DMG_GRENADE);
    }
}

/* ---------------- Bilgi menusu ---------------- */

public cmd_nade_menu(id)
{
    ShowNadeMenu(id);
    return PLUGIN_HANDLED;
}

ShowNadeMenu(id)
{
    new title[192], item[128], key[16], nm[32];
    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "NMENU_TITLE", id, "NMENU_SUB");
    new menu = menu_create(title, "menu_nade_handler");

    static const SLOTKEY[3][] = { "NMENU_HE", "NMENU_FROST", "NMENU_FLARE" };
    for (new s = 0; s < 3; s++)
    {
        formatex(key, charsmax(key), "NMODE_%d", g_iNadeMode[id][s]);
        formatex(nm, charsmax(nm), "%L", id, key);
        formatex(item, charsmax(item), "\y%L \r[\w%s\r]", id, SLOTKEY[s], nm);
        MenuAdd(menu, item, s);
    }
    formatex(item, charsmax(item), "\y%L", id, "NMENU_HELP");
    MenuAdd(menu, item, 9);
    MenuFinish(id, menu);
}

public menu_nade_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    if (sel == 9)
    {
        for (new i = 0; i < NUM_NMODES; i++)
        {
            new key[16];
            formatex(key, charsmax(key), "NMODE_DESC_%d", i);
            Chat(id, key);
        }
        return PLUGIN_HANDLED;
    }

    if (0 <= sel <= 2)
    {
        new bool:zm = (is_user_alive(id) && g_bZombie[id]) ? true : false;
        new m = g_iNadeMode[id][sel];
        for (new i = 0; i < NUM_NMODES; i++)
        {
            m = (m + 1) % NUM_NMODES;
            if (NadeModeAllowed(sel, m, zm))
                break;
        }
        g_iNadeMode[id][sel] = m;
        PlayKey(id, "NADE_MODE");
    }
    ShowNadeMenu(id);
    return PLUGIN_HANDLED;
}


/* ================================================================== */
/*  HAVA IKMALI, ROUND GOREVLERI, ZOMBI EVRIMI, EVENT EFEKTLERI        */
/* ================================================================== */

#define DROP_CLASS "vex_airdrop"
#define DROP_TOP_Z  22.0   // kutu modelinin ust yuzu (supply_crate: taban z = 0, cerceve 21.6 birim)
#define DROP_GLOW_Z 32.0   // isaret sprite'inin merkezi (kutunun ustunde)

/* ---------------- Hava ikmali ----------------
   Round icinde belirli araliklarla gokten parlayan bir kutu iner.
   Ilk dokunan insan rastgele bir odul kapar; zombi dokunursa kutu
   yok olur. Gokyuzune uzanan isik sutunu kutunun yerini gosterir. */

TickAirdrop()
{
    if (!get_pcvar_num(g_pAirdrop) || !g_bRoundActive || !g_szDropModel[0])
        return;
    if (g_iMode == MODE_ARMAGEDDON || g_iMode == MODE_SWARM)
        return;

    new every = (g_iEvent == EV_SUPPLY) ? 20 : max(20, get_pcvar_num(g_pAirdropEvery));
    if (++g_iAirdropClock < every)
        return;
    g_iAirdropClock = 0;

    if (RoundTimeLeft() > 25)
        SpawnAirdrop();
}

SpawnAirdrop()
{
    new alive[32], n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_alive(id) && !g_bZombie[id])
            alive[n++] = id;
    }
    if (!n)
        return;

    new Float:from[3], Float:base[3], Float:top[3], Float:frac;
    get_entvar(alive[random(n)], var_origin, from);
    base = from;
    base[0] += random_float(-220.0, 220.0);
    base[1] += random_float(-220.0, 220.0);

    // Duvarin icine dusmesin: oyuncudan noktaya serbest yol olmali
    engfunc(EngFunc_TraceLine, from, base, IGNORE_MONSTERS, 0, 0);
    get_tr2(0, TR_flFraction, frac);
    if (frac < 1.0)
    {
        // Duvara carptiysa duvardan biraz geri cekil
        get_tr2(0, TR_vecEndPos, base);
        new Float:dx = base[0] - from[0], Float:dy = base[1] - from[1];
        new Float:len = floatsqroot(dx * dx + dy * dy);
        if (len > 30.0)
        {
            base[0] -= dx / len * 24.0;
            base[1] -= dy / len * 24.0;
        }
        else
            base = from;
    }
    if (engfunc(EngFunc_PointContents, base) == CONTENTS_SOLID)
        base = from;

    top = base;
    top[2] += 700.0;
    engfunc(EngFunc_TraceLine, base, top, IGNORE_MONSTERS, 0, 0);
    get_tr2(0, TR_vecEndPos, top);
    top[2] -= 40.0;
    if (top[2] - base[2] < 80.0)
        top[2] = base[2] + 40.0;

    new ent = rg_create_entity("info_target");
    if (is_nullent(ent))
        return;

    set_entvar(ent, var_classname, DROP_CLASS);
    engfunc(EngFunc_SetModel, ent, g_szDropModel);
    // v3.0: Vexmira ikmal kutusu: dususte parasut govdesi + sallanma animasyonu
    if (g_szDropSeqFall[0])
    {
        set_entvar(ent, var_body, g_iDropBodyChute);
        AnimByName(ent, g_szDropSeqFall, 0, 1.0);
    }
    engfunc(EngFunc_SetSize, ent, Float:{-14.0, -14.0, 0.0}, Float:{14.0, 14.0, 20.0});
    set_entvar(ent, var_movetype, MOVETYPE_TOSS);
    set_entvar(ent, var_solid, SOLID_TRIGGER);
    set_entvar(ent, var_gravity, 0.12);
    engfunc(EngFunc_SetOrigin, ent, top);
    set_entvar(ent, var_velocity, Float:{0.0, 0.0, -40.0});
    set_entvar(ent, var_fuser1, get_gametime() + 45.0);
    set_entvar(ent, var_iuser1, 0);

    set_entvar(ent, var_renderfx, kRenderFxGlowShell);
    set_entvar(ent, var_rendercolor, Float:{255.0, 200.0, 40.0});
    set_entvar(ent, var_rendermode, kRenderNormal);
    set_entvar(ent, var_renderamt, 25.0);

    SetTouch(ent, "fw_DropTouch");
    SetThink(ent, "fw_DropThink");
    set_entvar(ent, var_nextthink, get_gametime() + 0.1);

    // v2.0 ALTIN ISIK: gokyuzune uzanan kalin altin isin sutunu (kalici varlik,
    // herkes gorur) + parlayan isaret sprite'i + kutunun etrafinda isik
    if (get_pcvar_num(g_pDropBeacon))
    {
        set_entvar(ent, var_effects, EF_DIMLIGHT);
        new Float:sky[3];
        DropSkyPoint(top, sky);
        new beam = BeamCreate(top, sky, 255, 200, 40, 60, 160);
        if (beam)
        {
            set_entvar(beam, var_iuser1, BEAM_MARK_DROP);
            set_entvar(beam, var_renderfx, 0);
        }
        set_entvar(ent, var_iuser2, beam);
        new core = BeamCreate(top, sky, 255, 255, 200, 14, 230);
        if (core)
            set_entvar(core, var_iuser1, BEAM_MARK_DROP);
        set_entvar(ent, var_iuser4, core);

        if (g_szSprBeacon[0])
        {
            new spr = rg_create_entity("info_target");
            if (!is_nullent(spr))
            {
                set_entvar(spr, var_classname, "vex_dropglow");
                engfunc(EngFunc_SetModel, spr, g_szSprBeacon);
                set_entvar(spr, var_rendermode, kRenderTransAdd);
                set_entvar(spr, var_renderamt, 255.0);
                set_entvar(spr, var_rendercolor, Float:{255.0, 200.0, 40.0});
                set_entvar(spr, var_scale, 1.2);
                // v3.0 hizalama: FOLLOW degil (istemci FOLLOW sprite'ini kutunun icine cizer).
                // Kutunun ustunde; kutuyla ayni hizla iner (NOCLIP + hiz, istemci yumusatir).
                set_entvar(spr, var_movetype, MOVETYPE_NOCLIP);
                set_entvar(spr, var_solid, SOLID_NOT);
                new Float:gp[3];
                gp = top;
                gp[2] += DROP_GLOW_Z;
                engfunc(EngFunc_SetOrigin, spr, gp);
                set_entvar(spr, var_velocity, Float:{0.0, 0.0, -40.0});
                set_entvar(ent, var_iuser3, spr);
            }
        }
    }

    FxTrail(ent, 255, 200, 40);
    HudAll(SL_ALERT, CLR_REWARD, 2.5, "AIRDROP_HUD");
    ChatAll("AIRDROP_CHAT");
    PlayKey(0, "AIRDROP_INCOMING");
    PlayVoxAll("VOX_AIRDROP");
}

public fw_DropThink(ent)
{
    if (is_nullent(ent))
        return;

    new Float:now = get_gametime();
    if (now > Float:get_entvar(ent, var_fuser1) || !g_bRoundActive)
    {
        DropRemove(ent);
        return;
    }

    new Float:o[3], Float:sky[3];
    get_entvar(ent, var_origin, o);
    new bool:landed = get_entvar(ent, var_iuser1) ? true : false;

    // Yere indi: toz + ses
    if (!landed && (get_entvar(ent, var_flags) & FL_ONGROUND))
    {
        landed = true;
        set_entvar(ent, var_iuser1, 1);
        if (g_szDropSeqFall[0])
        {
            set_entvar(ent, var_body, g_iDropBodyLanded);
            AnimByName(ent, g_szDropSeqIdle, 0, 1.0);
        }
        FxRingEx(o, 255, 200, 40, 260, 16, 6);
        FxSprite(o, g_sprSmoke, 15, 150);
        EmitKey(ent, "AIRDROP_LAND");
        ZoneSpawn(o, 70.0, 255, 200, 40, Float:get_entvar(ent, var_fuser1) - now, ent, false);
    }

    // Altin isin sutunu kutuyu takip eder (duserken de); kutunun ustunden baslar
    new Float:ct[3], Float:vel[3];
    ct = o;
    ct[2] += DROP_TOP_Z;
    DropSkyPoint(ct, sky);
    new beam = get_entvar(ent, var_iuser2);
    if (beam > 0 && !is_nullent(beam))
        BeamPoints(beam, ct, sky);
    new core = get_entvar(ent, var_iuser4);
    if (core > 0 && !is_nullent(core))
        BeamPoints(core, ct, sky);
    // Isaret sprite'i kutunun ustunde, kutunun hiziyla
    new glow = get_entvar(ent, var_iuser3);
    if (glow > 0 && !is_nullent(glow))
    {
        new Float:gp[3];
        gp = o;
        gp[2] += DROP_GLOW_Z;
        engfunc(EngFunc_SetOrigin, glow, gp);
        get_entvar(ent, var_velocity, vel);
        if (landed)
            vel[0] = vel[1] = vel[2] = 0.0;
        set_entvar(glow, var_velocity, vel);
    }

    // Altin nabiz isigi (eski ince sutun yedek olarak)
    if (!get_pcvar_num(g_pDropBeacon) || !beam)
        FxBeamEx(o, sky, g_sprBeam, 255, 200, 40, 60, 0, 11, 200);
    if (landed)
    {
        FxLight(o, 255, 200, 40, 28, 11, 5);
        if (g_iFrame % 2 == 0)
            FxRingSmall(o, 255, 200, 40);
    }

    set_entvar(ent, var_nextthink, now + (landed ? 1.0 : 0.1));
}

// Kutudan yukari: tavana / gokyuzune kadar (en fazla 1500)
DropSkyPoint(const Float:o[3], Float:sky[3])
{
    new Float:top[3];
    top = o;
    top[2] += 1500.0;
    engfunc(EngFunc_TraceLine, o, top, IGNORE_MONSTERS, 0, 0);
    get_tr2(0, TR_vecEndPos, sky);
}

DropRemove(ent)
{
    if (is_nullent(ent))
        return;
    new b = get_entvar(ent, var_iuser2);
    if (b > 0 && !is_nullent(b))
        set_entvar(b, var_flags, FL_KILLME);
    b = get_entvar(ent, var_iuser4);
    if (b > 0 && !is_nullent(b))
        set_entvar(b, var_flags, FL_KILLME);
    b = get_entvar(ent, var_iuser3);
    if (b > 0 && !is_nullent(b))
        set_entvar(b, var_flags, FL_KILLME);
    SetTouch(ent, "");
    SetThink(ent, "");
    set_entvar(ent, var_classname, "vex_removed");
    set_entvar(ent, var_flags, FL_KILLME);
}

public fw_DropTouch(ent, other)
{
    if (is_nullent(ent) || !(1 <= other <= g_iMax) || !is_user_alive(other))
        return;
    if (get_entvar(ent, var_flags) & FL_KILLME)
        return;

    new name[32];
    get_user_name(other, name, charsmax(name));

    new Float:o[3];
    get_entvar(ent, var_origin, o);
    DropRemove(ent);

    if (g_bZombie[other])
    {
        FxSprite(o, g_sprSmoke, 20, 180);
        FxRingSmall(o, 0, 255, 0);
        ChatAllS("AIRDROP_ZOMBIE", name);
        HealTo(other, get_pcvar_num(g_pAirdropHP), g_iMaxHP[other]);
        return;
    }

    FxRingEx(o, 255, 200, 40, 260, 16, 6);
    FxStreak(o, 4, 50, 250);
    EmitKey(other, "AIRDROP_LOOT");
    AirdropLoot(other, name);
}

AirdropLoot(id, const name[])
{
    new roll = random_num(1, 100);
    // Survivor / Sniper silahlarini ve bombalarini kaybetmesin: sadece AP / can
    if (g_bSurvivor[id] || g_bSniper[id])
        roll = random_num(1, 50);
    new key[20], amount;

    if (roll <= 30)
    {
        amount = random_num(10, 25);
        AddAP(id, amount, false, true);
        copy(key, charsmax(key), "LOOT_AP");
    }
    else if (roll <= 50)
    {
        HealTo(id, 60, MaxHumanHP(id) + 60);
        rg_set_user_armor(id, min(250, rg_get_user_armor(id) + 100), ARMOR_VESTHELM);
        copy(key, charsmax(key), "LOOT_HP");
    }
    else if (roll <= 64)
    {
        g_iFireNades[id] = max(1, g_iFireNades[id]);
        g_iFrostNades[id] = max(1, g_iFrostNades[id]);
        g_iFlares[id] = max(1, g_iFlares[id]);
        rg_give_item(id, "weapon_hegrenade");
        rg_give_item(id, "weapon_smokegrenade");
        rg_give_item(id, "weapon_flashbang");
        copy(key, charsmax(key), "LOOT_NADES");
    }
    else if (roll <= 76 && LasersAllowed() && get_pcvar_num(g_pAirdropLaser))
    {
        g_iMines[id] = min(RoundMines(id) + 2, g_iMines[id] + 1);
        copy(key, charsmax(key), "LOOT_MINE");
    }
    else if (roll <= 84)
    {
        g_bUnlClip[id] = 1;
        copy(key, charsmax(key), "LOOT_CLIP");
    }
    else if (roll <= 92)
    {
        g_bDmgAmp[id] = 1;
        copy(key, charsmax(key), "LOOT_DMG");
    }
    else if (roll <= 98)
    {
        new sw = random(NUM_SPECIAL);
        g_iSpecW[id] |= (1 << sw);
        rg_give_item(id, SW_BASE_ENT[sw], GT_REPLACE);
        rg_set_user_bpammo(id, SW_BASE_ID[sw], SW_BPAMMO[sw]);
        engclient_cmd(id, SW_BASE_ENT[sw]);
        copy(key, charsmax(key), "LOOT_SW");
        amount = sw;
    }
    else
    {
        g_iVC[id] += 3;
        copy(key, charsmax(key), "LOOT_VC");
    }

    // Bulana buyuk yazi, herkese chat
    new loot[64], txt[128];
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        if (equal(key, "LOOT_SW"))
        {
            new swk[12];
            formatex(swk, charsmax(swk), "SW_%d", amount);
            formatex(loot, charsmax(loot), "%L", p, swk);
        }
        else
            formatex(loot, charsmax(loot), "%L", p, key, amount);

        client_print_color(p, id, "%s %L", ChatTag("AIRDROP_GOT"), p, "AIRDROP_GOT", name, loot);
        if (p == id)
        {
            formatex(txt, charsmax(txt), "%L^n%s", p, "AIRDROP_YOU", loot);
            HudText(p, SL_PERS, CLR_REWARD, 3.0, txt);
        }
    }
    SaveData(id);
}

RemoveAllDrops()
{
    new ent;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", DROP_CLASS)) > 0)
        DropRemove(ent);
    ent = 0;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "vex_dropglow")) > 0)
        set_entvar(ent, var_flags, FL_KILLME);
}

// Insanlar icin pusula: en yakin ikmal kutusu - mesafe (metre) ve yon
bool:DropCompass(id, out[], len)
{
    out[0] = 0;
    if (!get_pcvar_num(g_pDropCompass))
        return false;

    new Float:o[3], Float:co[3], best, Float:bd = 999999.0;
    get_entvar(id, var_origin, o);
    new ent;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", DROP_CLASS)) > 0)
    {
        get_entvar(ent, var_origin, co);
        new Float:d = get_distance_f(o, co);
        if (d < bd)
        {
            bd = d;
            best = ent;
        }
    }
    if (!best)
        return false;

    get_entvar(best, var_origin, co);
    new Float:ang[3];
    get_entvar(id, var_v_angle, ang);
    new Float:want = floatatan2(co[1] - o[1], co[0] - o[0], degrees);
    new Float:diff = want - ang[1];
    while (diff > 180.0)
        diff -= 360.0;
    while (diff < -180.0)
        diff += 360.0;

    new arrow[8];
    if (floatabs(diff) <= 30.0)
        copy(arrow, charsmax(arrow), "^^^^");
    else if (floatabs(diff) >= 150.0)
        copy(arrow, charsmax(arrow), "vv");
    else if (diff > 0.0)
        copy(arrow, charsmax(arrow), "<<");
    else
        copy(arrow, charsmax(arrow), ">>");

    formatex(out, len, "%L", id, "HUD_DROP_COMPASS", floatround(bd * 0.0254), arrow);
    return true;
}


/* ================================================================== */
/*  v3.0 (B)  BOSS / NEMESIS / ASSASSIN SESLERI                         */
/*  INTRO (giris, herkese) - IDLE (ara sira hirlama, bekleme suresi    */
/*  vex_boss_idle_min..max) - PAIN / PAIN2 (sirayla, vex_boss_pain_cd) */
/*  STEP (hiza gore adim, vex_boss_step_dist) - ATTACK (pence savurma, */
/*  vex_boss_attack_cd) - PHASE (faz degisimi) - KILL (oldurme alayi)  */
/*  - DEATH. Eski anahtar adlari (SPAWN/ROAR/SCREAM/ABILITY) yeni      */
/*  olaylara baglidir.                                                 */
/* ================================================================== */

/* ---------------- Firlatilan bombalarin dunya modeli (SetModel) ---------------- */

// POST: oyunun kendi SetModel'i (boyut / fizik) aynen uygulanir, sonra sadece gorunen model degisir
public fw_SetModelPost(ent, const model[])
{
    if (ent <= g_iMax || model[0] != 'm' || is_nullent(ent))
        return FMRES_IGNORED;
    // Sadece "models/w_hegrenade.mdl" / w_smokegrenade / w_flashbang
    if (!equal(model, "models/w_", 9))
        return FMRES_IGNORED;
    new slot = -1;
    if (equal(model[9], "hegrenade.mdl"))           slot = 0;
    else if (equal(model[9], "smokegrenade.mdl"))   slot = 1;
    else if (equal(model[9], "flashbang.mdl"))      slot = 2;
    if (slot < 0 || !g_szWNade[slot][0])
        return FMRES_IGNORED;

    // Yerdeki silah kutusu (weaponbox) degil, firlatilan bomba
    new cls[12];
    get_entvar(ent, var_classname, cls, charsmax(cls));
    if (!equal(cls, "grenade"))
        return FMRES_IGNORED;
    // Zombinin enfeksiyon bombasi orijinal (yesil iz) kalir
    new owner = get_entvar(ent, var_owner);
    if (1 <= owner <= g_iMax && g_bZombie[owner])
        return FMRES_IGNORED;

    new Float:mins[3], Float:maxs[3];
    get_entvar(ent, var_mins, mins);
    get_entvar(ent, var_maxs, maxs);
    engfunc(EngFunc_SetModel, ent, g_szWNade[slot]);
    engfunc(EngFunc_SetSize, ent, mins, maxs);
    return FMRES_IGNORED;
}
