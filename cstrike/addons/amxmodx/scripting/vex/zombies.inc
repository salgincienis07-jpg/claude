/* ================================================================== */
/*  Vexmira Zombie - modul: vex/zombies.inc  (ZOMBILER)               */
/*  Zombi / insan donusumleri, enfeksiyon, sinif menusu, [R] / [F]    */
/*  yetenekleri (0-11 eski, 12-23 v3 siniflari), Nemesis / Assassin   */
/*  yetenekleri, bot yetenek kullanimi, evrim.                        */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  ZOMBI / INSAN DONUSUMLERI                                          */
/* ================================================================== */

MakeZombie(id)
{
    if (!g_bZombie[id])
        RemovePlayerMines(id, true);
    KillTrail(id);

    // Bekleyen sinif secimi yeni enfeksiyonda uygulanir
    if (g_iClassNext[id] >= 0)
    {
        g_iClass[id] = g_iClassNext[id];
        g_iClassNext[id] = -1;
    }
    g_bClassSwitched[id] = false;

    // v3.0: kanca / ninni / karartma gibi insan durumlari ve onceki yetenekler temizlenir
    ZcCleanup(id);

    g_bZombie[id] = 1;
    g_bAlpha[id] = false;
    g_iMines[id] = 0;
    g_fInfectTime[id] = get_gametime();
    g_fCool[id] = 0.0;
    g_fLeapCool[id] = 0.0;
    g_fRespawnAt[id] = 0.0;
    g_iExtraJumps[id] = 0; g_bBoots[id] = 0; g_bSerum[id] = 0; g_bUnlClip[id] = 0; g_bDmgAmp[id] = 0;
    g_iFireNades[id] = 0; g_iFrostNades[id] = 0; g_iFlares[id] = 0; g_iSpecW[id] = 0;
    g_fHBoost[id] = 0.0; g_iEShield[id] = 0; g_fCloak[id] = 0.0;
    g_iStreak[id] = 0;

    rg_set_user_team(id, TEAM_TERRORIST, MODEL_UNASSIGNED, true, false);
    rg_remove_all_items(id);
    rg_give_item(id, "weapon_knife");

    ApplyZombieStats(id);

    new Float:o[3];
    get_entvar(id, var_origin, o);
    FxRing(o, 0, 255, 0, 300);
    FxRing(o, 120, 255, 0, 160);
    FxLight(o, 0, 255, 0, 30, 12, 20);
    FxSprite(o, g_sprSmoke, 12, 150);
    FxImplosion(o, 120, 30, 6);
    FxBlood(o, 10);

    if (!(g_iSet[id] & SET_NO_FX))
    {
        FadeOne(id, 0, 160, 0, 120, 1.5);
        ShakeOne(id);
    }
    EmitZombieSound(id, "INFECT", "ZOMBIE_INFECT");

    if (!g_bMinion[id] && !g_bNemesis[id] && !g_bAssassin[id] && !g_bBoss[id] && !g_iClassPicked[id] && !is_user_bot(id))
        ShowClassMenu(id);
}

ApplyZombieStats(id)
{
    new Float:hp, Float:grav, model[32];
    new cls = g_iClass[id];

    if (g_bNemesis[id])
    {
        hp = float(get_pcvar_num(g_pNemHP) + 500 * CountPlaying());
        if (g_iMode == MODE_ARMAGEDDON)
            hp *= 0.5;
        grav = get_pcvar_float(g_pNemGrav);
        copy(model, charsmax(model), g_szNemModel);
    }
    else if (g_bAssassin[id])
    {
        hp = float(get_pcvar_num(g_pAsnHP) + 300 * CountPlaying());
        grav = get_pcvar_float(g_pAsnGrav);
        copy(model, charsmax(model), g_szAsnModel);
    }
    else if (g_bMinion[id])
    {
        hp = float(max(1, get_pcvar_num(g_pMinionHP)));
        grav = 0.8;
        copy(model, charsmax(model), g_szZModel[0]);
    }
    else
    {
        hp = float(get_pcvar_num(g_bFirst[id] ? g_pFirstHP : g_pZombieHP)) * CLASS_HP[cls];
        hp *= 1.0 + 0.06 * float(g_iPerk[id][PK_HIDE]);
        grav = CLASS_GRAV[cls];
        copy(model, charsmax(model), g_szZModel[cls]);

        switch (g_iEvent)
        {
            case EV_BLOODMOON: hp *= 1.5;
            case EV_HORDE:     hp *= 0.6;
            case EV_TITAN:     if (g_bFirst[id]) hp *= 4.0;
        }

        if (g_iMode == MODE_SURVIVOR || g_iMode == MODE_SNIPER)
            hp *= 0.6;
        else if (g_iMode == MODE_SWARM || g_iMode == MODE_PLAGUE)
            hp *= 0.75;
    }

    if (g_iEvent == EV_LOWGRAV)
        grav *= 0.55;

    g_iMaxHP[id] = floatround(hp);
    set_entvar(id, var_health, hp);
    set_entvar(id, var_max_health, hp);
    SetGravity(id, grav);
    rg_set_user_armor(id, 0, ARMOR_NONE);

    if (model[0])
        rg_set_user_model(id, model);

    rg_set_user_footsteps(id, g_bAssassin[id] || (cls == 5 && !g_bNemesis[id]) ? true : false);
    ApplyRender(id);
    rg_reset_maxspeed(id);
}

// Zombi rolleri (boss, nemesis...) temizlenir; boss ise boss sistemi de durur
ClearZombieRoles(id)
{
    if (g_bBoss[id])
    {
        g_bBoss[id] = 0;
        if (g_iBoss == id)
        {
            BossCleanup();
            g_iBoss = 0;
            g_fBossIntro = 0.0;
            remove_task(TASK_BOSSCAST);
            remove_task(TASK_BOSSHIT);
            remove_task(TASK_BOSSFX);
        }
    }
    g_bNemesis[id] = 0;
    g_bAssassin[id] = 0;
    g_bMinion[id] = 0;
    g_bAlpha[id] = false;
}

MakeSurvivor(id, bool:sniper)
{
    ZcCleanup(id);
    ClearZombieRoles(id);
    g_bZombie[id] = 0;
    if (sniper)
        g_bSniper[id] = 1;
    else
        g_bSurvivor[id] = 1;

    rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED, true, false);
    rg_remove_all_items(id);
    rg_give_item(id, "weapon_knife");

    if (sniper)
    {
        rg_give_item(id, "weapon_awp");
        rg_set_user_bpammo(id, WEAPON_AWP, 100);
        g_iMaxHP[id] = get_pcvar_num(g_pSnipHP);
        if (g_szSnipModel[0]) rg_set_user_model(id, g_szSnipModel);
    }
    else
    {
        rg_give_item(id, "weapon_m249");
        rg_set_user_bpammo(id, WEAPON_M249, 400);
        rg_give_item(id, "weapon_deagle");
        rg_set_user_bpammo(id, WEAPON_DEAGLE, 100);
        g_iMaxHP[id] = get_pcvar_num(g_pSurvHP);
        if (g_iMode == MODE_ARMAGEDDON)
            g_iMaxHP[id] /= 2;
        if (g_szSurvModel[0]) rg_set_user_model(id, g_szSurvModel);
    }

    rg_give_item(id, "weapon_hegrenade");
    g_iFireNades[id]++;

    set_entvar(id, var_health, float(g_iMaxHP[id]));
    set_entvar(id, var_max_health, float(g_iMaxHP[id]));
    rg_set_user_armor(id, 200, ARMOR_VESTHELM);
    g_bUnlClip[id] = 1;
    ApplyRender(id);
    rg_reset_maxspeed(id);
}

// Zombi -> insan (Antidote)
MakeHuman(id)
{
    ZcCleanup(id);
    ClearZombieRoles(id);
    g_bZombie[id] = 0;
    g_bFirst[id] = 0;
    g_bGunsGiven[id] = false;
    g_bNadesGiven[id] = false;
    if (g_iJobNext[id] >= 0)
    {
        g_iJob[id] = g_iJobNext[id];
        g_iJobNext[id] = -1;
    }
    g_fShield[id] = 0.0; g_fBurst[id] = 0.0; g_fCloak[id] = 0.0; g_fMadness[id] = 0.0;
    g_bRage[id] = 0; g_bZArmor[id] = 0; g_iInfNades[id] = 0; g_bZRegen[id] = 0; g_bNoKB[id] = 0;

    rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED, true, false);
    rg_remove_all_items(id);
    rg_give_item(id, "weapon_knife");
    rg_set_user_footsteps(id, false);

    ApplyHumanModel(id);
    set_entvar(id, var_health, float(MaxHumanHP(id)));
    set_entvar(id, var_max_health, float(MaxHumanHP(id)));
    ApplyHumanGravity(id);
    ApplyRender(id);
    rg_reset_maxspeed(id);
    GiveRoundMines(id);

    if (g_iPrim[id] >= 0 && g_iSec[id] >= 0)
        GiveLoadout(id);
    else
        ShowPrimaryMenu(id);
    GiveStartNades(id);

    new Float:o[3];
    get_entvar(id, var_origin, o);
    FxRing(o, 0, 150, 255, 300);
    FadeOne(id, 0, 150, 255, 100, 1.0);
    EmitKey(id, "ANTIDOTE");

    new name[32];
    get_user_name(id, name, charsmax(name));
    ChatAllS("ANTIDOTE_ALL", name);
}

ApplyHumanModel(id)
{
    new flags = get_user_flags(id);

    if ((flags & ADMIN_BAN) && g_szAdminModel[0])
        rg_set_user_model(id, g_szAdminModel);
    else if (((flags & ADMIN_LEVEL_H) || IsVip(id)) && g_szVipModel[0])
        rg_set_user_model(id, g_szVipModel);
    else if (g_iHumanModelN > 0)
        rg_set_user_model(id, g_szHumanModels[clamp(g_iHumanSkin[id], 0, g_iHumanModelN - 1)]);
    else
        rg_reset_user_model(id);
}

// Yercekimini kaydet: baska bir plugin (or. parasut) bozarsa yere inince geri yuklenir
SetGravity(id, Float:grav)
{
    g_fGrav[id] = grav;
    set_entvar(id, var_gravity, grav);
}

// v3.1: her karede (fw_PreThink). Parasut eklentileri acikken yercekimini dusurur, kapaninca
// ya da yere inince 1.0'a (ya da eski degere) sabitler -> sinif / esya / event / survivor
// yercekimi kaybolurdu (eskiden yalniz yerde ve saniyede bir duzeltiliyordu, havada kapatilan
// parasut ve 'Ziplama' esyasi bozuk degeri kalici yapiyordu). Parasut acikken (havada + E
// basili) dokunulmaz; kapaninca / yere inince / suda / merdivende dogru deger geri yuklenir.
FixGravity(id)
{
    if (g_fGrav[id] <= 0.0)
        return;
    new Float:cur = Float:get_entvar(id, var_gravity);
    if (floatabs(cur - g_fGrav[id]) <= 0.001)
        return;
    if (!(get_entvar(id, var_flags) & FL_ONGROUND) && (get_entvar(id, var_button) & IN_USE)
        && get_entvar(id, var_movetype) != MOVETYPE_FLY && get_entvar(id, var_waterlevel) < 2)
        return;
    set_entvar(id, var_gravity, g_fGrav[id]);
    if (get_pcvar_num(g_pDbgDirs) && g_iDirLogN[DIR_GRAV] < DIR_LOG_MAX)
    {
        g_iDirLogN[DIR_GRAV]++;
        log_amx("[Vexmira] DIRCHK gravity_restore id=%d zombie=%d class=%d boss=%d nem=%d asn=%d surv=%d %.3f -> %.3f",
            id, g_bZombie[id], g_iClass[id], g_bBoss[id], g_bNemesis[id], g_bAssassin[id], g_bSurvivor[id], cur, g_fGrav[id]);
    }
}

// Gelistirici testi (vex_debug_dirs 1): "vex_debug_hooktest" - en fazla 3 normal zombi bot
// Kasap olur, en yakin insana doner ve kanca atar (zincir / cekme yonleri DIRCHK ile yazilir).
public srv_DbgHookTest()
{
    if (!get_pcvar_num(g_pDbgDirs))
        return PLUGIN_HANDLED;
    new n;
    for (new id = 1; id <= g_iMax && n < 3; id++)
    {
        if (!is_user_alive(id) || !is_user_bot(id) || !g_bZombie[id] || g_bMinion[id] || g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id])
            continue;
        new t = ZcNearestHuman(id, 900.0);
        if (!t)
            continue;
        g_iClass[id] = ZC_BUTCHER;
        ZcFace(id, t);
        if (ButcherHook(id))
            n++;
    }
    log_amx("[Vexmira] DIRCHK hook_test thrown=%d", n);
    return PLUGIN_HANDLED;
}

// Gelistirici testi (vex_debug_dirs 1): "vex_debug_gravtest" - parasut kapanisini taklit eder
// (canli herkesin yercekimini 1.0 / 0.1'e bozar); FixGravity bir sonraki karede duzeltmeli.
public srv_DbgGravTest()
{
    if (!get_pcvar_num(g_pDbgDirs))
        return PLUGIN_HANDLED;
    new n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || g_fGrav[id] <= 0.0)
            continue;
        set_entvar(id, var_gravity, (n % 2) ? 0.1 : 1.0);
        n++;
    }
    log_amx("[Vexmira] DIRCHK grav_test broken=%d", n);
    return PLUGIN_HANDLED;
}

ApplyHumanGravity(id)
{
    if (g_bZombie[id])
        return;

    new Float:gr = 1.0;
    if (g_iJob[id] == JOB_PARA)
        gr = 0.75;
    if (g_bBoots[id])
        gr = floatmin(gr, float(clamp(ITEM_VAL[IT_BOOTS], 10, 100)) / 100.0);
    if (g_iEvent == EV_LOWGRAV)
        gr *= 0.5;
    SetGravity(id, gr);
}

ApplyRender(id)
{
    if (!is_user_alive(id))
        return;

    // v3.0: Kostebek yeraltinda tamamen gorunmez, Taklitci kiliktayken parlamasiz insan gibi
    if (g_bZombie[id] && g_fBurrow[id] > get_gametime())
        set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0);
    else if (g_fFrozen[id] > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 0, 120, 255, kRenderNormal, 25);
    else if (g_fMadness[id] > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 40);
    else if (g_fCloak[id] > get_gametime())
        set_user_rendering(id, kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 20);
    else if (g_bZombie[id] && g_fDisguise[id] > get_gametime())
        set_user_rendering(id);
    else if (g_fShield[id] > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 40, 120, 255, kRenderNormal, 28);
    else if (g_bZombie[id] && g_fFortify[id] > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 130, 150, 130, kRenderNormal, 45);
    else if (g_bZombie[id] && g_fCharge[id] > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 230, 130, 50, kRenderNormal, 35);
    else if (g_bZombie[id] && g_fTerror[id] > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 90, 0, 0, kRenderNormal, 40);
    else if (g_bBoss[id] && g_fEclipseEnd > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 40, 0, 30, kRenderTransAlpha, 70);
    else if (g_bBoss[id] && g_fBossBuffEnd > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 255, 80, 0, kRenderNormal, 70);
    else if (g_bBoss[id] && g_fBossEmpower > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 120, 0, 200, kRenderNormal, 60);
    else if (g_bBoss[id])
    {
        if (g_bEnraged)
            set_user_rendering(id, kRenderFxGlowShell, 255, 20, 20, kRenderNormal, 40);
        else
            set_user_rendering(id, kRenderFxGlowShell, BOSS_RGB[g_iBossType][0], BOSS_RGB[g_iBossType][1], BOSS_RGB[g_iBossType][2], kRenderNormal, 32);
    }
    else if (g_bNemesis[id] && g_fRage[id] > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 255, 60, 0, kRenderNormal, 60);
    else if (g_bNemesis[id])
        set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 20);
    else if (g_bAssassin[id])
        set_user_rendering(id, kRenderFxGlowShell, 90, 0, 140, kRenderNormal, 12);
    else if (g_bSurvivor[id])
        set_user_rendering(id, kRenderFxGlowShell, 0, 100, 255, kRenderNormal, 15);
    else if (g_bSniper[id])
        set_user_rendering(id, kRenderFxGlowShell, 0, 255, 120, kRenderNormal, 15);
    else if (g_bMinion[id])
        set_user_rendering(id, kRenderFxGlowShell, 150, 0, 200, kRenderNormal, 10);
    else if (g_bZombie[id])
    {
        new c = g_iClass[id];
        set_user_rendering(id, kRenderFxGlowShell, CLASS_RGB[c][0], CLASS_RGB[c][1], CLASS_RGB[c][2], kRenderNormal, g_bAlpha[id] ? 22 : 6);
    }
    else if (!g_bZombie[id] && g_iJob[id] == JOB_GHOST)
        set_user_rendering(id, kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 120);
    else if (!g_bZombie[id] && g_iEShield[id] > 0)
        set_user_rendering(id, kRenderFxGlowShell, 0, 255, 255, kRenderNormal, 18);
    else if (IsVip(id) && g_iVipAura[id])
    {
        new a = g_iVipAura[id];
        set_user_rendering(id, kRenderFxGlowShell, VIP_AURA_RGB[a][0], VIP_AURA_RGB[a][1], VIP_AURA_RGB[a][2], kRenderNormal, 8);
    }
    else
        set_user_rendering(id);
}

Infect(victim, attacker)
{
    new vname[32], aname[32];
    get_user_name(victim, vname, charsmax(vname));
    get_user_name(attacker, aname, charsmax(aname));

    MakeZombie(victim);

    new Float:vo[3];
    get_entvar(victim, var_origin, vo);
    CosInfectFx(attacker, vo);
    FxSpr(vo, g_sprFx[FXS_INFECT], 7, 220, 10.0);

    // Skor tablosu + olum mesaji
    set_entvar(attacker, var_frags, Float:get_entvar(attacker, var_frags) + 1.0);
    set_member(victim, m_iDeaths, get_member(victim, m_iDeaths) + 1);
    SendDeathMsg(attacker, victim, "infection");
    UpdateScore(attacker);
    UpdateScore(victim);

    g_iInfects[attacker]++;
    g_iRoundInf[attacker]++;
    g_iMapInf[attacker]++;
    QuestEvent(attacker, 4, 1);
    CheckEvolve(attacker);

    // Leech: enfekte edince can calar
    if (g_iClass[attacker] == 4 && !g_bMinion[attacker])
        HealTo(attacker, 400, g_iMaxHP[attacker]);

    Reward(attacker, get_pcvar_num(g_pInfectXP), get_pcvar_num(g_pInfectAP));
    PayBounty(attacker, victim);

    // Kisisel bildirimler
    Chat(victim, "YOU_INFECTED", aname);
    Chat(attacker, "YOU_INFECTOR", vname);

    if (!g_bFirstInfect)
    {
        g_bFirstInfect = true;
        LiveAll(victim, "LIVE_FIRSTINF", 3, vname);
    }

    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p))
            client_print_color(p, victim, "%s %L", ChatTag("INFECTED_BY"), p, "INFECTED_BY", vname, aname);
    }

    CheckWin();
}


/* ================================================================== */
/*  ZOMBI YETENEKLERI ([R])                                            */
/* ================================================================== */

public fw_CmdStart(id, uc_handle, seed)
{
    if (!is_user_alive(id))
        return FMRES_IGNORED;

    new imp = get_uc(uc_handle, UC_Impulse);

    // Insan: Volt EMP / Kabus dehseti sirasinda fener acilamaz
    if (!g_bZombie[id])
    {
        if (imp == 100 && g_fNoLight[id] > get_gametime())
        {
            set_uc(uc_handle, UC_Impulse, 0);
            LightsBlockedMsg(id);
        }
        return FMRES_IGNORED;
    }

    // [F] (fener tusu, impulse 100): Boss = atilma, Nemesis = OFKE, Assassin = GOLGE PERDESI
    // (sinif zombilerinin feneri eskisi gibi calisir)
    if (imp == 100 && (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id]))
    {
        set_uc(uc_handle, UC_Impulse, 0);
        SkillTrigger(id, 2);
    }

    // [R] (IN_RELOAD, basildigi an): Boss = faza gore yetenek, Nemesis / Assassin = atilma, zombi = sinif yetenegi
    if ((get_uc(uc_handle, UC_Buttons) & IN_RELOAD) && !(get_entvar(id, var_oldbuttons) & IN_RELOAD))
        SkillTrigger(id, 1);

    return FMRES_IGNORED;
}

// ReAPI yedegi: impulse 100 CmdStart'ta yakalanamadiysa (baska plugin / istemci farki) burada islenir
public rg_ImpulseCommands(id)
{
    if (!is_user_alive(id) || get_entvar(id, var_impulse) != 100)
        return HC_CONTINUE;

    if (!g_bZombie[id])
    {
        if (g_fNoLight[id] > get_gametime())
        {
            set_entvar(id, var_impulse, 0);
            LightsBlockedMsg(id);
            return HC_SUPERCEDE;
        }
        return HC_CONTINUE;
    }

    if (!g_bBoss[id] && !g_bNemesis[id] && !g_bAssassin[id])
        return HC_CONTINUE;

    set_entvar(id, var_impulse, 0);
    SkillTrigger(id, 2);
    return HC_SUPERCEDE;
}

// G (drop): zombi bicagini zaten atamaz -> ozel karakterde [F] gucu, sinif zombisinde [R] yetenegi.
// Insanin silah atmasi aynen calisir.
public cmd_drop(id)
{
    if (!is_user_alive(id) || !g_bZombie[id] || !get_pcvar_num(g_pZc[ZCV_ALTKEYS]))
        return PLUGIN_CONTINUE;
    SkillTrigger(id, (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id]) ? 2 : 1);
    return PLUGIN_HANDLED;
}

// Konsol: vex_skill (R) / vex_skill2 (F), chat: /skill /skill2 (/beceri /beceri2)
public cmd_skill(id)
{
    if (is_user_alive(id) && g_bZombie[id])
        SkillTrigger(id, 1);
    else if (is_user_connected(id))
        SkillDeny(id, "SKILL_ONLY_ZOMBIE");
    return PLUGIN_HANDLED;
}

public cmd_skill2(id)
{
    if (is_user_alive(id) && g_bZombie[id])
        SkillTrigger(id, (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id]) ? 2 : 1);
    else if (is_user_connected(id))
        SkillDeny(id, "SKILL_ONLY_ZOMBIE");
    return PLUGIN_HANDLED;
}

public cmd_skill_release(id)
{
    return PLUGIN_HANDLED;
}

// Tek giris noktasi: slot 1 = [R], slot 2 = [F]. Ayni tetik 0.2 sn icinde (tus + komut ayni anda) tek sayilir.
// Her red durumunda oyuncuya neden calismadigi yazilir.
SkillTrigger(id, slot)
{
    if (!is_user_alive(id) || !g_bZombie[id])
        return;

    new Float:now = get_gametime();
    slot = clamp(slot, 1, 2);
    if (now - g_fSkillTrig[id][slot] < 0.2)
        return;
    g_fSkillTrig[id][slot] = now;

    if (!g_bRoundActive)
    {
        SkillDeny(id, "SKILL_ROUND_OVER");
        return;
    }
    if (g_bMinion[id])
    {
        SkillDeny(id, "SKILL_MINION");
        return;
    }
    if (g_fFrozen[id] > now)
    {
        SkillDeny(id, "SKILL_STUNNED", floatround(g_fFrozen[id] - now, floatround_ceil));
        return;
    }

    if (slot == 1)
    {
        if (g_bBoss[id])
            BossUseR(id);
        else if (g_bNemesis[id] || g_bAssassin[id])
            SpecialLeap(id);
        else
            UseAbility(id);
        return;
    }

    if (g_bBoss[id])
        SpecialLeap(id);
    else if (g_bNemesis[id] || g_bAssassin[id])
        SpecialFSkill(id);
    else
        UseAbility(id);
}

// Red / bekleme bildirimi (ekranin ortasi, kisa). Bekleme gri, diger nedenler turuncu.
SkillDeny(id, const key[], val = 0)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;
    if (equal(key, "ABILITY_COOL"))
        set_hudmessage(CLR_COOL, -1.0, 0.56, 0, 0.0, 1.0, 0.0, 0.1, 4);
    else
        set_hudmessage(CLR_WARN, -1.0, 0.56, 0, 0.0, 1.4, 0.0, 0.1, 4);
    show_hudmessage(id, "%L", id, key, val);
}

LightsBlockedMsg(id)
{
    if (is_user_bot(id))
        return;
    SkillDeny(id, "LIGHTS_BLOCKED", floatround(g_fNoLight[id] - get_gametime(), floatround_ceil));
}

SpecialLeap(id)
{
    new Float:now = get_gametime();
    if (g_bBoss[id] && g_fBossIntro > now)
    {
        SkillDeny(id, "SKILL_BOSS_INTRO", floatround(g_fBossIntro - now, floatround_ceil));
        return;
    }
    if (now < g_fLeapCool[id])
    {
        SkillDeny(id, "ABILITY_COOL", floatround(g_fLeapCool[id] - now, floatround_ceil));
        return;
    }
    if (!(get_entvar(id, var_flags) & FL_ONGROUND))
    {
        SkillDeny(id, "SKILL_NEED_GROUND");
        return;
    }

    new Float:cd = floatmax(1.0, get_pcvar_float(g_pSpecialLeapCd));
    LeapForward(id, g_bAssassin[id] ? 850.0 : (g_bBoss[id] ? 720.0 : 650.0), 320.0);
    g_fLeapCool[id] = now + (g_bAssassin[id] ? cd * 0.66 : cd);

    new Float:o[3];
    get_entvar(id, var_origin, o);
    if (g_bBoss[id])
        FxRingEx(o, BOSS_RGB[g_iBossType][0], BOSS_RGB[g_iBossType][1], BOSS_RGB[g_iBossType][2], 220, 16, 4);
    else
        FxRing(o, 255, 0, 0, 200);
    EmitKey(id, "ABILITY_LEAP");
}

// Nemesis: OFKE (hizli + dayanikli), Assassin: GOLGE PERDESI (neredeyse gorunmez + hizli)
SpecialFSkill(id)
{
    new Float:now = get_gametime();
    if (now < g_fFCool[id])
    {
        SkillDeny(id, "ABILITY_COOL", floatround(g_fFCool[id] - now, floatround_ceil));
        return;
    }

    new Float:o[3];
    get_entvar(id, var_origin, o);
    if (g_bNemesis[id])
    {
        new Float:dur = floatmax(1.0, get_pcvar_float(g_pNemRageTime));
        g_fRage[id] = now + dur;
        g_fFCool[id] = now + floatmax(dur + 1.0, get_pcvar_float(g_pNemRageCd));
        FxRingEx(o, 255, 30, 0, 320, 30, 5);
        FxLava(o);
        FxLight(o, 255, 30, 0, 40, 10, 10);
        ShakeAll(6, 1.0, 4);
        EmitKey(id, "NEM_RAGE", CHAN_STATIC, ATTN_NONE);
        HudTo(id, SL_PERS, CLR_ZOMBIE, 2.5, "NEM_RAGE_YOU");
        new name[32];
        get_user_name(id, name, charsmax(name));
        ChatAllS("NEM_RAGE_ALL", name);
    }
    else
    {
        new Float:dur = floatmax(1.0, get_pcvar_float(g_pAsnVeilTime));
        g_fRage[id] = now + dur;
        g_fCloak[id] = now + dur;
        g_fFCool[id] = now + floatmax(dur + 1.0, get_pcvar_float(g_pAsnVeilCd));
        FxSprite(o, g_sprSmoke, 25, 160);
        FxImplosion(o, 120, 30, 5);
        EmitKey(id, "ASN_VEIL");
        HudTo(id, SL_PERS, CLR_ZOMBIE, 2.5, "ASN_VEIL_YOU");
    }
    ApplyRender(id);
    rg_reset_maxspeed(id);
}

LeapForward(id, Float:power, Float:up)
{
    new Float:ang[3], Float:fwd[3], Float:vel[3];
    get_entvar(id, var_v_angle, ang);
    engfunc(EngFunc_MakeVectors, ang);
    global_get(glb_v_forward, fwd);

    vel[0] = fwd[0] * power;
    vel[1] = fwd[1] * power;
    vel[2] = up;
    set_entvar(id, var_velocity, vel);
    if (g_iDirLogN[DIR_LEAP] < DIR_LOG_MAX && get_pcvar_num(g_pDbgDirs))
    {
        new Float:hv[3], Float:hf[3];
        hv = vel; hv[2] = 0.0;
        hf = fwd; hf[2] = 0.0;
        DirCheck(DIR_LEAP, "leap", hv, hf);
    }
}

UseAbility(id)
{
    new Float:now = get_gametime();

    if (now < g_fCool[id])
    {
        SkillDeny(id, "ABILITY_COOL", floatround(g_fCool[id] - now, floatround_ceil));
        return;
    }
    if (g_fBurrow[id] > now)
    {
        SkillDeny(id, "SKILL_BURROWED");
        return;
    }

    new cls = clamp(g_iClass[id], 0, NUM_CLASSES - 1);
    new Float:o[3], Float:po[3];
    get_entvar(id, var_origin, o);

    switch (cls)
    {
        case 0: // Walker: hiz patlamasi
        {
            g_fBurst[id] = now + 4.0;
            rg_reset_maxspeed(id);
            FxRing(o, 255, 160, 0, 220);
            EmitZombieSound(id, "ABILITY", "ABILITY_BURST");
        }
        case 1: // Runner: uzun ziplama
        {
            if (!(get_entvar(id, var_flags) & FL_ONGROUND))
            {
                SkillDeny(id, "SKILL_NEED_GROUND");
                return;
            }
            LeapForward(id, 700.0, 320.0);
            FxRing(o, 255, 140, 0, 200);
            EmitZombieSound(id, "ABILITY", "ABILITY_LEAP");
        }
        case 2: // Tank: hasar kalkani
        {
            g_fShield[id] = now + 4.0;
            ApplyRender(id);
            FxRing(o, 40, 120, 255, 260);
            EmitZombieSound(id, "ABILITY", "ABILITY_SHIELD");
        }
        case 3: // Banshee: kor eden ciglik
        {
            FxRing(o, 220, 220, 255, 450);
            EmitZombieSound(id, "ABILITY", "ABILITY_SCREAM");
            for (new t = 1; t <= g_iMax; t++)
            {
                if (!is_user_alive(t) || g_bZombie[t])
                    continue;
                get_entvar(t, var_origin, po);
                if (get_distance_f(o, po) > 450.0)
                    continue;
                ShakeOne(t);
                FadeOne(t, 255, 255, 255, 230, 2.0);
            }
        }
        case 4: // Leech: can emme
        {
            HealTo(id, g_iMaxHP[id] / 4, g_iMaxHP[id]);
            FxRing(o, 200, 0, 0, 220);
            FxLight(o, 200, 0, 0, 30, 12, 20);
            EmitZombieSound(id, "ABILITY", "ABILITY_DRAIN");
        }
        case 5: // Stalker: gorunmezlik
        {
            g_fCloak[id] = now + 6.0;
            ApplyRender(id);
            FxRing(o, 0, 120, 120, 200);
            EmitZombieSound(id, "ABILITY", "ABILITY_CLOAK");
        }
        case 6: // Bomber: zehir patlamasi
        {
            FxRing(o, 120, 255, 0, 280);
            FxSprite(o, g_sprSmoke, 25, 200);
            EmitZombieSound(id, "ABILITY", "ABILITY_TOXIC");
            for (new t = 1; t <= g_iMax; t++)
            {
                if (!is_user_alive(t) || g_bZombie[t])
                    continue;
                get_entvar(t, var_origin, po);
                if (get_distance_f(o, po) > 280.0)
                    continue;
                FadeOne(t, 120, 255, 0, 120, 1.5);
                ExecuteHamB(Ham_TakeDamage, t, 0, id, 25.0, DMG_ACID);
            }
        }
        case 7: // Frost: buz halkasi, insanlari yavaslatir
        {
            FxRing(o, 0, 200, 255, 320);
            FxLight(o, 0, 200, 255, 30, 12, 20);
            EmitZombieSound(id, "ABILITY", "ABILITY_FROST");
            for (new t = 1; t <= g_iMax; t++)
            {
                if (!is_user_alive(t) || g_bZombie[t])
                    continue;
                get_entvar(t, var_origin, po);
                if (get_distance_f(o, po) > 320.0)
                    continue;
                g_fSlow[t] = now + 3.0;
                rg_reset_maxspeed(t);
                FadeOne(t, 0, 150, 255, 100, 1.5);
            }
        }
        case 8: // Spitter: onundeki koniye asit puskurtur
        {
            new Float:ang[3], Float:fwd[3], Float:dir[3], Float:eye[3];
            get_entvar(id, var_v_angle, ang);
            engfunc(EngFunc_MakeVectors, ang);
            global_get(glb_v_forward, fwd);
            eye = o;
            eye[2] += 20.0;

            EmitZombieSound(id, "ABILITY", "ZOMBIE_ACID");
            new hits;
            for (new t = 1; t <= g_iMax; t++)
            {
                if (!is_user_alive(t) || g_bZombie[t])
                    continue;
                get_entvar(t, var_origin, po);
                new Float:dist = get_distance_f(o, po);
                if (dist > 420.0 || dist < 1.0)
                    continue;

                dir[0] = (po[0] - o[0]) / dist;
                dir[1] = (po[1] - o[1]) / dist;
                dir[2] = (po[2] - o[2]) / dist;
                if (dir[0] * fwd[0] + dir[1] * fwd[1] + dir[2] * fwd[2] < 0.8)
                    continue;

                FxBeam(eye, po, g_sprBeam, 120, 255, 0, 20);
                FadeOne(t, 120, 255, 0, 140, 1.5);
                g_fSlow[t] = now + 2.0;
                rg_reset_maxspeed(t);
                ExecuteHamB(Ham_TakeDamage, t, 0, id, 25.0, DMG_ACID);
                hits++;
            }
            new Float:front[3];
            front[0] = o[0] + fwd[0] * 120.0;
            front[1] = o[1] + fwd[1] * 120.0;
            front[2] = o[2] + fwd[2] * 120.0;
            FxSprite(front, g_sprSmoke, 15, 180);
            FxParticles(front, 60, 53, 8);
        }
        case 9: // Hulk: sok dalgasi, insanlari savurur
        {
            EmitZombieSound(id, "ABILITY", "ZOMBIE_SHOCK");
            FxLava(o);
            FxRing(o, 255, 80, 0, 320);
            FxRing(o, 255, 200, 0, 200);
            for (new t = 1; t <= g_iMax; t++)
            {
                if (!is_user_alive(t) || g_bZombie[t])
                    continue;
                get_entvar(t, var_origin, po);
                new Float:dist = get_distance_f(o, po);
                if (dist > 300.0 || dist < 1.0)
                    continue;

                new Float:vel[3];
                vel[0] = (po[0] - o[0]) / dist * 600.0;
                vel[1] = (po[1] - o[1]) / dist * 600.0;
                vel[2] = 260.0;
                set_entvar(t, var_velocity, vel);
                ShakeOne(t);
                ExecuteHamB(Ham_TakeDamage, t, 0, id, 15.0, DMG_CRUSH);
            }
        }
        case 10: // Voodoo: yakindaki zombileri iyilestirir
        {
            EmitZombieSound(id, "ABILITY", "ZOMBIE_HEAL");
            FxImplosion(o, 200, 40, 8);
            FxRing(o, 255, 0, 180, 450);
            HealTo(id, g_iMaxHP[id] / 10, g_iMaxHP[id]);
            for (new t = 1; t <= g_iMax; t++)
            {
                if (t == id || !is_user_alive(t) || !g_bZombie[t] || g_bBoss[t])
                    continue;
                get_entvar(t, var_origin, po);
                if (get_distance_f(o, po) > 450.0)
                    continue;
                HealTo(t, g_iMaxHP[t] / 4, g_iMaxHP[t]);
                FxBeam(o, po, g_sprBeam, 255, 0, 180, 12);
                FxLight(po, 255, 0, 180, 20, 8, 20);
            }
        }
        case 11: // Phantom: ileri isinlanma
        {
            new Float:ang[3], Float:fwd[3], Float:dest[3], Float:best[3];
            get_entvar(id, var_v_angle, ang);
            ang[0] = 0.0;
            engfunc(EngFunc_MakeVectors, ang);
            global_get(glb_v_forward, fwd);

            new bool:found;
            for (new step = 8; step >= 2; step--)
            {
                dest[0] = o[0] + fwd[0] * 40.0 * float(step);
                dest[1] = o[1] + fwd[1] * 40.0 * float(step);
                dest[2] = o[2] + 5.0;

                // Arada duvar olmasin
                engfunc(EngFunc_TraceLine, o, dest, IGNORE_MONSTERS, id, 0);
                new Float:frac;
                get_tr2(0, TR_flFraction, frac);
                if (frac < 1.0)
                    continue;
                if (IsHullFree(id, dest))
                {
                    best = dest;
                    found = true;
                    break;
                }
            }
            if (!found)
            {
                SkillDeny(id, "SKILL_NO_SPACE");
                return;
            }

            FxTeleport(o);
            engfunc(EngFunc_SetOrigin, id, best);
            FxTeleport(best);
            FxRing(best, 120, 120, 255, 200);
            EmitZombieSound(id, "ABILITY", "ZOMBIE_BLINK");
        }
        default:
        {
            // v3.0 siniflari (12-23): basarisizsa bekleme baslamaz
            if (!UseAbilityV3(id, cls))
                return;
        }
    }

    g_fCool[id] = now + CLASS_COOL[cls];
}

// Zombi sesi: once sinifa ozel (Z<n>_<olay>), yoksa genel anahtar
EmitZombieSound(id, const ev[], const fallbackKey[])
{
    new key[24], path[128];
    formatex(key, charsmax(key), "Z%d_%s", g_iClass[id], ev);
    if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
    {
        if (!TrieGetString(g_tRes, fallbackKey, path, charsmax(path)) || !path[0])
            return;
    }
    if (containi(path, ".mp3") != -1)
        return;

    EmitSafe(id, CHAN_VOICE, path, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}


/* ================================================================== */
/*  OYUNCU HOOK'LARI (ReAPI)                                           */
/* ================================================================== */

BomberExplode(victim, const Float:o[3])
{
    new Float:po[3];
    FxExplosion(o);
    FxRing(o, 120, 255, 0, 260);

    for (new t = 1; t <= g_iMax; t++)
    {
        if (!is_user_alive(t) || g_bZombie[t])
            continue;
        get_entvar(t, var_origin, po);
        if (get_distance_f(o, po) > 220.0)
            continue;
        ShakeOne(t);
        FadeOne(t, 120, 255, 0, 100, 1.0);
        ExecuteHamB(Ham_TakeDamage, t, 0, victim, 35.0, DMG_ACID);
    }
}

/* ---------------- Zombi gorusu: zombiler karanlikta gorur ---------------- */

public task_ZombieVision()
{
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || !g_bZombie[id] || is_user_bot(id) || (g_iSet[id] & SET_NO_ZVISION))
            continue;

        new Float:o[3];
        get_entvar(id, var_origin, o);

        message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
        write_byte(TE_DLIGHT);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2]);
        write_byte(60);
        write_byte(110);
        write_byte(20);
        write_byte(20);
        write_byte(4);
        write_byte(0);
        message_end();
    }
}


/* ================================================================== */
/*  MENULER                                                            */
/* ================================================================== */

/* ---------------- Zombi sinifi ---------------- */

ShowClassMenu(id)
{
    new title[96], item[160], k1[16], k2[20], n1[32], n2[72];

    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MENU_CLASS", id, "MENU_CLASS_SUB");
    new menu = menu_create(title, "menu_class_handler");

    for (new i = 0; i < NUM_CLASSES; i++)
    {
        formatex(k1, charsmax(k1), "CLASS_%d", i);
        formatex(k2, charsmax(k2), "CLASS_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        if (g_iLevel[id] < CLASS_LVL[i])
            formatex(item, charsmax(item), "\d%s \r[\wLv.%d\r]", n1, CLASS_LVL[i]);
        else if (g_iClass[id] == i)
            formatex(item, charsmax(item), "\y%s \r[\w*\r] \d%s", n1, n2);
        else
            formatex(item, charsmax(item), "\y%s \d%s", n1, n2);

        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_class_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new cls = MenuInfo(menu, item);
    menu_destroy(menu);
    if (cls < 0 || cls >= NUM_CLASSES)
        return PLUGIN_HANDLED;

    if (g_iLevel[id] < CLASS_LVL[cls])
    {
        Chat(id, "NEED_LEVEL", CLASS_LVL[cls]);
        ShowClassMenu(id);
        return PLUGIN_HANDLED;
    }

    g_iClassPicked[id] = 1;
    ChatKeyName(id, "CLASS_CHOSEN", "CLASS_", cls);
    PlayKey(id, "UI_CLASS_SELECT");

    // Yeni enfekte olduysa (10 sn icinde, bir kez) sinifi hemen uygula;
    // aksi halde bir sonraki enfeksiyonda gecerli olur (hiz/can karisikligi olmasin)
    if (is_user_alive(id) && g_bZombie[id] && !g_bBoss[id] && !g_bMinion[id] && !g_bNemesis[id] && !g_bAssassin[id]
        && get_gametime() - g_fInfectTime[id] < 10.0 && !g_bClassSwitched[id])
    {
        g_iClass[id] = cls;
        g_iClassNext[id] = -1;
        g_bClassSwitched[id] = true;
        ApplyZombieStats(id);
    }
    else if (is_user_alive(id) && g_bZombie[id])
    {
        g_iClassNext[id] = cls;
        Chat(id, "CLASS_NEXT");
    }
    else
    {
        g_iClass[id] = cls;
        g_iClassNext[id] = -1;
    }

    SaveData(id);
    return PLUGIN_HANDLED;
}


/* ================================================================== */
/*  HAVA IKMALI, ROUND GOREVLERI, ZOMBI EVRIMI, EVENT EFEKTLERI        */
/* ================================================================== */

/* ---------------- Zombi evrimi ----------------
   Bir roundda N kisiyi enfekte eden zombi ALFA olur:
   +%50 can, daha hizli, daha guclu vurus, parlak aura. */

CheckEvolve(id)
{
    new need = get_pcvar_num(g_pEvolve);
    if (need <= 0 || g_bAlpha[id] || !g_bZombie[id] || g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id] || g_bMinion[id])
        return;
    if (g_iRoundInf[id] < need)
        return;

    g_bAlpha[id] = true;
    g_iMaxHP[id] = g_iMaxHP[id] * 3 / 2;
    set_entvar(id, var_max_health, float(g_iMaxHP[id]));
    set_entvar(id, var_health, float(g_iMaxHP[id]));
    ApplyRender(id);
    rg_reset_maxspeed(id);

    new Float:o[3];
    get_entvar(id, var_origin, o);
    FxSkyStrike(o, 120, 255, 0);
    FxRingEx(o, 120, 255, 0, 420, 30, 6);
    FxFunnel(o, g_sprFlare, true);
    EmitKey(id, "EVOLVE");
    ShakeEx(id, 10, 1.2, 5);

    new name[32];
    get_user_name(id, name, charsmax(name));
    ChatAllS("EVOLVE_CHAT", name);
    HudTo(id, SL_PERS, CLR_ZOMBIE, 3.0, "EVOLVE_HUD");
}


/* ================================================================== */
/*  v3.0  YENI ZOMBI SINIFLARI (12-23) - [R] YETENEKLERI                */
/*                                                                      */
/*  12 Kasap: et kancasi (zincirli mermi, insani ceker)                 */
/*  13 Avci: atilma + inis sersemletmesi   14 Boga: dumduz hucum        */
/*  15 Orumcek: ag mermisi (kok + yavaslama) 16 Magma: lav izi          */
/*  17 Volt: EMP (lazer / fener / gece gorusu kapanir)                  */
/*  18 Taklitci: insan kiligi 19 Kostebek: yeraltina dalis              */
/*  20 Siren: ninni (cekim) 21 Kale: tahkim 22 Spor Ana: spor kesesi    */
/*  23 Kabus: dehset (ekran kararir)                                    */
/*  Ayarlar: vexmira.cfg  vex_<sinif>_<ayar>                            */
/*  Temizlik: olum / enfeksiyon / cikis / round sonu -> ZcCleanup       */
/* ================================================================== */

Float:ZcF(c)
{
    return get_pcvar_float(g_pZc[c]);
}

ZcN(c)
{
    return get_pcvar_num(g_pZc[c]);
}

// Sadece normal sinif zombisi (boss / nemesis / assassin / yardimci degil)
bool:IsClassZombie(id, cls)
{
    if (!(1 <= id <= g_iMax) || !g_bZombie[id] || g_bMinion[id] || g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id])
        return false;
    return (g_iClass[id] == cls) ? true : false;
}

stock ZcEye(id, Float:eye[3])
{
    new Float:ofs[3];
    get_entvar(id, var_origin, eye);
    get_entvar(id, var_view_ofs, ofs);
    eye[0] += ofs[0];
    eye[1] += ofs[1];
    eye[2] += ofs[2];
}

stock ZcAimDir(id, Float:dir[3])
{
    new Float:ang[3];
    get_entvar(id, var_v_angle, ang);
    engfunc(EngFunc_MakeVectors, ang);
    global_get(glb_v_forward, dir);
}

// Kancanin cikis noktasi (el hizasi)
stock ZcHand(id, Float:out[3])
{
    new Float:dir[3];
    ZcEye(id, out);
    ZcAimDir(id, dir);
    out[0] += dir[0] * 12.0;
    out[1] += dir[1] * 12.0;
    out[2] += dir[2] * 12.0 - 10.0;
}

// a'nin gozunden b'nin gozune duvar var mi? (oyuncular engel sayilmaz)
stock bool:ZcVisible(a, b)
{
    new Float:ea[3], Float:eb[3], Float:frac;
    ZcEye(a, ea);
    ZcEye(b, eb);
    engfunc(EngFunc_TraceLine, ea, eb, IGNORE_MONSTERS, a, 0);
    get_tr2(0, TR_flFraction, frac);
    return (frac >= 1.0) ? true : false;
}

stock ZcNameOf(id, out[], len)
{
    if (is_user_connected(id))
        get_user_name(id, out, len);
    else
        copy(out, len, "?");
}

// Fener + gece gorusu kapanir ve 'dur' sn acilamaz (Volt EMP / Kabus)
LightsOut(p, Float:dur)
{
    new Float:until = get_gametime() + dur;
    if (g_fNoLight[p] < until)
        g_fNoLight[p] = until;

    new eff = get_entvar(p, var_effects);
    if (eff & EF_DIMLIGHT)
    {
        set_entvar(p, var_effects, eff & ~EF_DIMLIGHT);
        if (g_msgFlashlight && !is_user_bot(p))
        {
            message_begin(MSG_ONE, g_msgFlashlight, _, p);
            write_byte(0);
            write_byte(clamp(get_member(p, m_iFlashBattery), 0, 100));
            message_end();
        }
    }
    if (get_member(p, m_bNightVisionOn))
    {
        set_member(p, m_bNightVisionOn, false);
        if (g_msgNVGToggle && !is_user_bot(p))
        {
            message_begin(MSG_ONE, g_msgNVGToggle, _, p);
            write_byte(0);
            message_end();
        }
    }
}

/* ---------------- [R] dagitici (12-23) ---------------- */

bool:UseAbilityV3(id, cls)
{
    switch (cls)
    {
        case ZC_BUTCHER:     return ButcherHook(id);
        case ZC_HUNTER:      return HunterPounce(id);
        case ZC_CHARGER:     return ChargerCharge(id);
        case ZC_ARACHNE:     return ArachneWeb(id);
        case ZC_MAGMA:       return MagmaTrail(id);
        case ZC_VOLT:        return VoltEmp(id);
        case ZC_MIMIC:       return MimicDisguise(id);
        case ZC_BURROWER:    return BurrowerDive(id);
        case ZC_SIREN:       return SirenLure(id);
        case ZC_BULWARK:     return BulwarkFortify(id);
        case ZC_SPOREMOTHER: return SporePlant(id);
        case ZC_NIGHTMARE:   return NightmareTerror(id);
    }
    return false;
}

/* ---------------- Mermiler: kanca + ag (ortak) ---------------- */
// var_iuser1 = sahip, iuser2 = tur (ZP_HOOK / ZP_WEB), iuser3 = zincir isini, iuser4 = takilan insan
// fuser1 = gidilen yol, fuser2 = menzil, fuser3 = cekme bitisi, vuser1 = onceki konum

bool:ZProjValid(ent)
{
    if (ent <= g_iMax || is_nullent(ent))
        return false;
    new cls[16];
    get_entvar(ent, var_classname, cls, charsmax(cls));
    return equal(cls, ZPROJ_CLASS) ? true : false;
}

ZProjSpawn(owner, type, Float:speed, Float:range)
{
    new ent = rg_create_entity("info_target");
    if (is_nullent(ent))
        return 0;

    new Float:eye[3], Float:dir[3], Float:start[3], Float:vel[3], Float:ang[3], Float:frac;
    ZcEye(owner, eye);
    ZcAimDir(owner, dir);
    for (new i = 0; i < 3; i++)
    {
        start[i] = eye[i] + dir[i] * 18.0;
        vel[i] = dir[i] * floatclamp(speed, 200.0, 4000.0);
    }
    start[2] -= 6.0;
    // Duvara cok yakinsa mermi duvarin icinde dogmasin
    engfunc(EngFunc_TraceLine, eye, start, IGNORE_MONSTERS, owner, 0);
    get_tr2(0, TR_flFraction, frac);
    if (frac < 1.0)
        get_tr2(0, TR_vecEndPos, start);

    set_entvar(ent, var_classname, ZPROJ_CLASS);
    if (type == ZP_HOOK && g_szHookModel[0])
    {
        engfunc(EngFunc_SetModel, ent, g_szHookModel);
        set_entvar(ent, var_renderfx, kRenderFxGlowShell);
        set_entvar(ent, var_rendercolor, Float:{180.0, 30.0, 30.0});
        set_entvar(ent, var_renderamt, 6.0);
    }
    else
    {
        new spr[64];
        if (type == ZP_WEB && g_szSprWeb[0])
            copy(spr, charsmax(spr), g_szSprWeb);
        else
            copy(spr, charsmax(spr), g_szSprOrb);
        if (spr[0])
        {
            engfunc(EngFunc_SetModel, ent, spr);
            set_entvar(ent, var_rendermode, kRenderTransAdd);
            set_entvar(ent, var_renderamt, 230.0);
            if (type == ZP_WEB)
                set_entvar(ent, var_rendercolor, Float:{220.0, 190.0, 255.0});
            else
                set_entvar(ent, var_rendercolor, Float:{200.0, 40.0, 40.0});
            set_entvar(ent, var_scale, (type == ZP_WEB) ? 0.35 : 0.25);
        }
    }

    set_entvar(ent, var_movetype, MOVETYPE_NOCLIP);
    set_entvar(ent, var_solid, SOLID_NOT);
    engfunc(EngFunc_SetSize, ent, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});
    engfunc(EngFunc_SetOrigin, ent, start);
    set_entvar(ent, var_velocity, vel);
    engfunc(EngFunc_VecToAngles, vel, ang);
    set_entvar(ent, var_angles, ang);

    set_entvar(ent, var_iuser1, owner);
    set_entvar(ent, var_iuser2, type);
    set_entvar(ent, var_iuser3, 0);
    set_entvar(ent, var_iuser4, 0);
    set_entvar(ent, var_fuser1, 0.0);
    set_entvar(ent, var_fuser2, floatclamp(range, 100.0, 4000.0));
    set_entvar(ent, var_fuser3, 0.0);
    set_entvar(ent, var_vuser1, start);

    if (type == ZP_HOOK)
    {
        new Float:hand[3];
        ZcHand(owner, hand);
        set_entvar(ent, var_iuser3, ChainBeamCreate(hand, start, owner));
    }
    // fuser4 = 0: iz (TE_BEAMFOLLOW) ilk dusunmede gonderilir (varlik istemciye ulassin)
    set_entvar(ent, var_fuser4, 0.0);

    SetThink(ent, "fw_ZProjThink");
    set_entvar(ent, var_nextthink, get_gametime() + 0.02);
    return ent;
}

// Kanca zinciri: kalici isin varligi (titremesiz). chain.spr yoksa koyu kirmizi lazer.
// v3.1: zincir BEAM_ENTPOINT; baslangic = sahibin KONUMU (ek noktasi 0). Eskiden attachment 1
// kullaniliyordu: istemci onu modelin son cizilen pozundan alir; eki olmayan stok CS
// modellerinde ve atanin kendi birinci sahis bakisinda (kendi modeli cizilmez) ek bayat /
// (0,0,0) kalir ve zincir ters capraz yonden gelirdi. Konum her modelde dogru; yerel oyuncu
// icin istemcinin tahmin ettigi konum kullanilir (titremesiz). Sunucu noktasi (ZcHand)
// yalnizca PVS / BEAM_POINTS yedegi icin guncellenir.
ChainBeamCreate(const Float:a[3], const Float:b[3], owner = 0)
{
    new beam = rg_create_entity("beam");
    if (is_nullent(beam))
        return 0;

    set_entvar(beam, var_flags, get_entvar(beam, var_flags) | FL_CUSTOMENTITY);
    if (g_sprChain)
    {
        set_entvar(beam, var_model, g_szSprChain);
        set_entvar(beam, var_modelindex, g_sprChain);
        set_entvar(beam, var_scale, 12.0);
        BeamColor(beam, 255, 255, 255, 255);
    }
    else
    {
        set_entvar(beam, var_model, "sprites/laserbeam.spr");
        set_entvar(beam, var_modelindex, g_sprBeam);
        set_entvar(beam, var_scale, 5.0);
        BeamColor(beam, 150, 20, 20, 230);
    }
    set_entvar(beam, var_body, 0);
    set_entvar(beam, var_frame, 0.0);
    set_entvar(beam, var_animtime, 0.0);
    set_entvar(beam, var_skin, 0);
    set_entvar(beam, var_sequence, 0);
    set_entvar(beam, var_rendermode, (1 <= owner <= g_iMax) ? BEAM_ENTPOINT : BEAM_POINTS);
    if (1 <= owner <= g_iMax)
        set_entvar(beam, var_sequence, BeamEntHand(owner));
    set_entvar(beam, var_iuser1, BEAM_MARK_HOOK);
    BeamPoints(beam, a, b);
    return beam;
}

bool:ZProjOwnerOk(owner, type)
{
    if (!g_bRoundActive || !is_user_alive(owner))
        return false;
    return IsClassZombie(owner, (type == ZP_HOOK) ? ZC_BUTCHER : ZC_ARACHNE);
}

public fw_ZProjThink(ent)
{
    if (is_nullent(ent))
        return;

    new owner = get_entvar(ent, var_iuser1), type = get_entvar(ent, var_iuser2);
    if (!ZProjOwnerOk(owner, type))
    {
        ZProjRemove(ent);
        return;
    }

    new Float:now = get_gametime();
    new victim = get_entvar(ent, var_iuser4);
    if (victim)
    {
        HookPullThink(ent, owner, victim, now);
        return;
    }

    new Float:last[3], Float:cur[3], Float:wall[3], Float:seg[3], Float:frac;
    get_entvar(ent, var_vuser1, last);
    get_entvar(ent, var_origin, cur);

    // Duvar / zemin
    engfunc(EngFunc_TraceLine, last, cur, IGNORE_MONSTERS, ent, 0);
    get_tr2(0, TR_flFraction, frac);
    get_tr2(0, TR_vecEndPos, wall);
    if (frac < 1.0)
        seg = wall;
    else
        seg = cur;

    // Insan isabeti: segmente en yakin olan (govde kutusu biraz genisletilir)
    new best, Float:bestD = 999999.0, Float:mins[3], Float:maxs[3], Float:po[3];
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_absmin, mins);
        get_entvar(p, var_absmax, maxs);
        for (new i = 0; i < 3; i++)
        {
            mins[i] -= 10.0;
            maxs[i] += 10.0;
        }
        if (!SegmentHitsBox(last, seg, mins, maxs))
            continue;
        get_entvar(p, var_origin, po);
        new Float:d = get_distance_f(last, po);
        if (d < bestD)
        {
            bestD = d;
            best = p;
        }
    }
    if (best)
    {
        ZProjHit(ent, owner, type, best);
        return;
    }
    if (frac < 1.0)
    {
        ZProjMiss(ent, owner, type, wall);
        return;
    }

    new Float:trav = Float:get_entvar(ent, var_fuser1) + get_distance_f(last, cur);
    set_entvar(ent, var_fuser1, trav);
    set_entvar(ent, var_vuser1, cur);
    if (trav >= Float:get_entvar(ent, var_fuser2))
    {
        ZProjMiss(ent, owner, type, cur);
        return;
    }

    if (type == ZP_HOOK)
    {
        new beam = get_entvar(ent, var_iuser3), Float:hand[3];
        if (beam > 0 && !is_nullent(beam))
        {
            ZcHand(owner, hand);
            BeamPoints(beam, hand, cur);
            if (g_iDirLogN[DIR_HOOK] < DIR_LOG_MAX && trav > 60.0 && get_pcvar_num(g_pDbgDirs))
            {
                // Istemcinin cizdigi zincir: sahibin konumu -> kanca; atis yonuyle (mermi hizi) ayni olmali
                new Float:oo[3], Float:aim[3], Float:seg2[3];
                get_entvar(owner, var_origin, oo);
                get_entvar(ent, var_velocity, aim);
                for (new i = 0; i < 3; i++)
                    seg2[i] = cur[i] - oo[i];
                DirCheck(DIR_HOOK, "hook_beam", seg2, aim);
            }
        }
    }
    else if (Float:get_entvar(ent, var_fuser4) == 0.0 && trav > 20.0)
    {
        set_entvar(ent, var_fuser4, 1.0);
        FxTrail(ent, 190, 120, 255);
    }
    set_entvar(ent, var_nextthink, now + 0.02);
}

ZProjHit(ent, owner, type, p)
{
    new Float:po[3], name[32], vname[32];
    get_entvar(p, var_origin, po);
    ZcNameOf(owner, name, charsmax(name));
    ZcNameOf(p, vname, charsmax(vname));

    if (type == ZP_WEB)
    {
        WebHit(owner, p);
        ZProjRemove(ent);
        return;
    }

    // Kanca: Survivor / Sniper cekilemez, ayni anda iki kasap ayni insani cekemez
    if (g_bSurvivor[p] || g_bSniper[p] || g_iHookedBy[p])
    {
        FxSparks(po);
        EmitKeyPos(po, "HOOK_HIT");
        SkillDeny(owner, "HOOK_IMMUNE");
        ZProjRemove(ent);
        return;
    }

    new Float:now = get_gametime();
    g_iHookedBy[p] = owner;
    set_entvar(ent, var_iuser4, p);
    set_entvar(ent, var_fuser3, now + floatclamp(ZcF(ZCV_HOOK_TIME), 0.2, 5.0));
    set_entvar(ent, var_velocity, Float:{0.0, 0.0, 0.0});
    po[2] += 10.0;
    engfunc(EngFunc_SetOrigin, ent, po);

    FxBlood(po, 8);
    FxSparks(po);
    EmitKey(p, "HOOK_HIT", CHAN_ITEM);
    EmitKey(owner, "HOOK_CHAIN", CHAN_ITEM);
    EmitKey(p, "HOOK_PULL", CHAN_BODY);
    ShakeOne(p);
    FadeOne(p, 150, 0, 0, 100, 0.6);
    HudToS(p, SL_ALERT, CLR_DANGER, 2.0, "HOOK_PULLED", name);
    HudToS(owner, SL_PERS, CLR_ZOMBIE, 1.6, "HOOK_GOT_YOU", vname);

    new Float:dmg = ZcF(ZCV_HOOK_DMG);
    if (dmg > 0.0)
        ExecuteHamB(Ham_TakeDamage, p, 0, owner, dmg, DMG_SLASH);

    if (!is_nullent(ent))
        set_entvar(ent, var_nextthink, now + 0.02);
}

ZProjMiss(ent, owner, type, const Float:pos[3])
{
    if (type == ZP_WEB)
    {
        // Duvara yapisan ag
        FxSprite(pos, g_sprWeb ? g_sprWeb : g_sprSmoke, g_sprWeb ? 4 : 6, 200);
        EmitKeyPos(pos, "ARACHNE_WEBHIT");
    }
    else
    {
        FxSparks(pos);
        EmitKeyPos(pos, "HOOK_MISS");
        SkillDeny(owner, "HOOK_MISS_YOU");
    }
    ZProjRemove(ent);
}

// Kanca takiliyken: insanin cekilmesi fw_PreThink'te (her karede) yapilir, burada kopma kosullari
HookPullThink(ent, owner, victim, Float:now)
{
    new bool:stop;
    if (!is_user_alive(victim) || g_bZombie[victim] || g_iHookedBy[victim] != owner)
        stop = true;
    else if (now >= Float:get_entvar(ent, var_fuser3))
        stop = true;
    else
    {
        new Float:oo[3], Float:vv[3];
        get_entvar(owner, var_origin, oo);
        get_entvar(victim, var_origin, vv);
        if (get_distance_f(oo, vv) <= 60.0 || !ZcVisible(owner, victim))
            stop = true;
    }
    if (stop)
    {
        ZProjRemove(ent);
        return;
    }

    new Float:vo[3], Float:hand[3];
    get_entvar(victim, var_origin, vo);
    vo[2] += 10.0;
    engfunc(EngFunc_SetOrigin, ent, vo);
    new beam = get_entvar(ent, var_iuser3);
    if (beam > 0 && !is_nullent(beam))
    {
        ZcHand(owner, hand);
        BeamPoints(beam, hand, vo);
    }
    set_entvar(ent, var_nextthink, now + 0.02);
}

// Cekilen insan (her karede): kasaba dogru sabit hiz
HookPullVictim(id)
{
    new b = g_iHookedBy[id];
    if (!(1 <= b <= g_iMax) || !is_user_alive(b) || g_bZombie[id])
    {
        g_iHookedBy[id] = 0;
        return;
    }
    new Float:bo[3], Float:po[3], Float:dir[3], Float:vel[3];
    get_entvar(b, var_origin, bo);
    get_entvar(id, var_origin, po);
    new Float:d = get_distance_f(bo, po);
    if (d < 1.0)
        return;
    new Float:spd = floatclamp(ZcF(ZCV_HOOK_PULL), 100.0, 1500.0);
    for (new i = 0; i < 3; i++)
    {
        dir[i] = (bo[i] - po[i]) / d;
        vel[i] = dir[i] * spd;
    }
    if ((get_entvar(id, var_flags) & FL_ONGROUND) && vel[2] < 90.0)
        vel[2] = 90.0;
    set_entvar(id, var_velocity, vel);
    if (g_iDirLogN[DIR_PULL] < DIR_LOG_MAX && get_pcvar_num(g_pDbgDirs))
        DirCheck(DIR_PULL, "hook_pull", vel, dir);
}

ZProjRemove(ent)
{
    if (is_nullent(ent))
        return;

    new owner = get_entvar(ent, var_iuser1), type = get_entvar(ent, var_iuser2), victim = get_entvar(ent, var_iuser4);
    new beam = get_entvar(ent, var_iuser3);
    if (beam > 0 && !is_nullent(beam))
        set_entvar(beam, var_flags, FL_KILLME);

    if (type == ZP_HOOK && (1 <= owner <= g_iMax) && g_iHookEnt[owner] == ent)
        g_iHookEnt[owner] = 0;

    // Takili insan serbest: firlamasin diye hiz kirpilir, kisa yavaslama (kasap vurabilsin)
    if ((1 <= victim <= g_iMax) && g_iHookedBy[victim] == owner)
    {
        g_iHookedBy[victim] = 0;
        if (is_user_alive(victim) && !g_bZombie[victim])
        {
            new Float:vel[3];
            get_entvar(victim, var_velocity, vel);
            vel[0] *= 0.25;
            vel[1] *= 0.25;
            if (vel[2] > 0.0)
                vel[2] *= 0.25;
            set_entvar(victim, var_velocity, vel);
            SlowHuman(victim, 0.6);
        }
    }

    SetThink(ent, "");
    set_entvar(ent, var_iuser1, 0);
    set_entvar(ent, var_iuser3, 0);
    set_entvar(ent, var_iuser4, 0);
    set_entvar(ent, var_velocity, Float:{0.0, 0.0, 0.0});
    set_entvar(ent, var_classname, "vex_removed");
    set_entvar(ent, var_flags, FL_KILLME);
}

RemoveOwnedProj(id)
{
    new ent;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", ZPROJ_CLASS)) > 0)
    {
        if (get_entvar(ent, var_iuser1) == id || get_entvar(ent, var_iuser4) == id)
            ZProjRemove(ent);
    }
}

/* ---------------- 12 KASAP: et kancasi ---------------- */

bool:ButcherHook(id)
{
    if (g_iHookEnt[id] && ZProjValid(g_iHookEnt[id]))
    {
        SkillDeny(id, "SKILL_HOOK_BUSY");
        return false;
    }
    g_iHookEnt[id] = 0;

    new ent = ZProjSpawn(id, ZP_HOOK, ZcF(ZCV_HOOK_SPEED), ZcF(ZCV_HOOK_RANGE));
    if (!ent)
        return false;
    g_iHookEnt[id] = ent;

    EmitKey(id, "HOOK_THROW", CHAN_WEAPON);
    EmitZombieSound(id, "ABILITY", "");
    HudTo(id, SL_PERS, CLR_ZOMBIE, 1.2, "HOOK_THROW_YOU");
    return true;
}

/* ---------------- 13 AVCI: atilma + sersemletme ---------------- */

bool:HunterPounce(id)
{
    if (!(get_entvar(id, var_flags) & FL_ONGROUND))
    {
        SkillDeny(id, "SKILL_NEED_GROUND");
        return false;
    }
    new Float:o[3];
    get_entvar(id, var_origin, o);
    LeapForward(id, floatclamp(ZcF(ZCV_HUNT_POWER), 200.0, 2000.0), floatclamp(ZcF(ZCV_HUNT_UP), 50.0, 1000.0));
    g_fPounce[id] = get_gametime();

    FxRingEx(o, 120, 120, 150, 180, 10, 4);
    FxSprite(o, g_sprSmoke, 8, 110);
    EmitZombieSound(id, "ABILITY", "ABILITY_LEAP");
    HudTo(id, SL_PERS, CLR_ZOMBIE, 1.2, "HUNTER_POUNCE_YOU");
    return true;
}

PounceThink(id)
{
    new Float:t = get_gametime() - g_fPounce[id];
    if (t > 2.5)
    {
        g_fPounce[id] = 0.0;
        return;
    }
    if (t < 0.15)
        return;

    if (get_entvar(id, var_flags) & FL_ONGROUND)
    {
        HunterImpact(id);
        return;
    }
    // Havada insana carparsa aninda iner
    new Float:o[3], Float:po[3];
    get_entvar(id, var_origin, o);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) <= 52.0)
        {
            HunterImpact(id);
            return;
        }
    }
}

HunterImpact(id)
{
    g_fPounce[id] = 0.0;

    new Float:o[3], Float:po[3], vname[32], name[32], hits;
    get_entvar(id, var_origin, o);
    ZcNameOf(id, name, charsmax(name));
    new Float:rad = floatclamp(ZcF(ZCV_HUNT_RAD), 20.0, 400.0) + 16.0;
    new Float:stun = floatclamp(ZcF(ZCV_HUNT_STUN), 0.1, 5.0), Float:dmg = ZcF(ZCV_HUNT_DMG);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > rad)
            continue;

        if (g_bSurvivor[p] || g_bSniper[p])
            SlowHuman(p, stun + 0.5);
        else
            RootHuman(p, stun);
        ShakeOne(p);
        FadeOne(p, 70, 70, 100, 150, stun);
        HudToS(p, SL_ALERT, CLR_DANGER, 1.8, "HUNTER_STUNNED", name);
        if (dmg > 0.0)
            ExecuteHamB(Ham_TakeDamage, p, 0, id, dmg, DMG_CLUB);
        hits++;
        if (is_user_alive(p))
        {
            ZcNameOf(p, vname, charsmax(vname));
            HudToS(id, SL_PERS, CLR_ZOMBIE, 1.4, "HUNTER_HIT_YOU", vname);
        }
    }

    FxRingEx(o, 130, 130, 170, floatround(rad * 2.5), 14, 4);
    FxSprite(o, g_sprSmoke, 10, 120);
    FxSpr(o, g_sprFx[FXS_SHOCK], clamp(floatround(rad / 10.0), 6, 20), 200, -20.0);
    if (hits)
    {
        // Avinin ustune konar
        set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
        FxLight(o, 140, 140, 200, 18, 6, 20);
    }
    EmitKey(id, "HUNTER_IMPACT", CHAN_BODY);
}

/* ---------------- 14 BOGA: hucum ---------------- */

bool:ChargerCharge(id)
{
    if (!(get_entvar(id, var_flags) & FL_ONGROUND))
    {
        SkillDeny(id, "SKILL_NEED_GROUND");
        return false;
    }
    new Float:dir[3];
    ZcAimDir(id, dir);
    dir[2] = 0.0;
    new Float:len = floatsqroot(dir[0] * dir[0] + dir[1] * dir[1]);
    if (len < 0.1)
    {
        SkillDeny(id, "SKILL_NO_SPACE");
        return false;
    }
    dir[0] /= len;
    dir[1] /= len;

    new Float:now = get_gametime();
    g_fChargeDir[id] = dir;
    g_fChargeT0[id] = now;
    g_fCharge[id] = now + floatclamp(ZcF(ZCV_CHG_TIME), 0.3, 5.0);
    g_iChargeHit[id] = 0;
    rg_reset_maxspeed(id);
    ApplyRender(id);

    new Float:o[3];
    get_entvar(id, var_origin, o);
    FxRingEx(o, 200, 120, 60, 260, 16, 4);
    FxSprite(o, g_sprSmoke, 12, 140);
    EmitZombieSound(id, "ABILITY", "ABILITY_BURST");
    HudTo(id, SL_PERS, CLR_ZOMBIE, 1.2, "CHARGER_YOU");
    return true;
}

ChargeThink(id)
{
    new Float:now = get_gametime();
    if (now >= g_fCharge[id] || !is_user_alive(id) || g_fFrozen[id] > now)
    {
        ChargeEnd(id, false);
        return;
    }

    new Float:o[3], Float:vel[3], Float:ahead[3], Float:frac, Float:normal[3];
    new Float:spd = floatclamp(ZcF(ZCV_CHG_SPEED), 200.0, 1500.0);
    get_entvar(id, var_origin, o);
    get_entvar(id, var_velocity, vel);
    vel[0] = g_fChargeDir[id][0] * spd;
    vel[1] = g_fChargeDir[id][1] * spd;
    set_entvar(id, var_velocity, vel);

    // Duvara carpma (zemin / rampa sayilmaz)
    ahead[0] = o[0] + g_fChargeDir[id][0] * 40.0;
    ahead[1] = o[1] + g_fChargeDir[id][1] * 40.0;
    ahead[2] = o[2];
    engfunc(EngFunc_TraceLine, o, ahead, IGNORE_MONSTERS, id, 0);
    get_tr2(0, TR_flFraction, frac);
    get_tr2(0, TR_vecPlaneNormal, normal);
    if (frac < 1.0 && normal[2] < 0.7 && now - g_fChargeT0[id] > 0.12)
    {
        ChargeEnd(id, true);
        return;
    }

    // Yoldaki insanlar yana savrulur (her insan bir kez)
    new Float:po[3];
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p] || (g_iChargeHit[id] & (1 << (p - 1))))
            continue;
        get_entvar(p, var_origin, po);
        new Float:dx = po[0] - o[0], Float:dy = po[1] - o[1];
        if (dx * dx + dy * dy > 56.0 * 56.0 || floatabs(po[2] - o[2]) > 64.0)
            continue;
        g_iChargeHit[id] |= (1 << (p - 1));
        ChargeHitHuman(id, p, dx, dy);
        if (!is_user_alive(id))
            return;
    }
}

ChargeHitHuman(id, p, Float:dx, Float:dy)
{
    new Float:dir[3], Float:perp[2], Float:vel[3], name[32];
    dir = g_fChargeDir[id];
    perp[0] = -dir[1];
    perp[1] = dir[0];
    new Float:side = (dx * perp[0] + dy * perp[1] >= 0.0) ? 1.0 : -1.0;
    new Float:push = floatclamp(ZcF(ZCV_CHG_PUSH), 0.0, 2000.0);

    vel[0] = perp[0] * side * push + dir[0] * push * 0.6;
    vel[1] = perp[1] * side * push + dir[1] * push * 0.6;
    vel[2] = 260.0;
    set_entvar(p, var_velocity, vel);

    new Float:po[3];
    get_entvar(p, var_origin, po);
    FxBlood(po, 8);
    FxSprite(po, g_sprSmoke, 6, 120);
    ShakeOne(p);
    FadeOne(p, 200, 120, 60, 120, 0.6);
    EmitKey(p, "CHARGER_IMPACT", CHAN_BODY);
    ZcNameOf(id, name, charsmax(name));
    HudToS(p, SL_ALERT, CLR_DANGER, 1.6, "CHARGER_HIT", name);

    new Float:dmg = ZcF(ZCV_CHG_DMG);
    if (dmg > 0.0)
        ExecuteHamB(Ham_TakeDamage, p, 0, id, dmg, DMG_CLUB);
}

ChargeEnd(id, bool:crash)
{
    if (g_fCharge[id] <= 0.0)
        return;
    g_fCharge[id] = 0.0;
    g_iChargeHit[id] = 0;
    if (!is_user_alive(id))
        return;

    if (crash)
    {
        new Float:o[3], Float:front[3];
        get_entvar(id, var_origin, o);
        front[0] = o[0] + g_fChargeDir[id][0] * 24.0;
        front[1] = o[1] + g_fChargeDir[id][1] * 24.0;
        front[2] = o[2];
        g_fFrozen[id] = get_gametime() + floatclamp(ZcF(ZCV_CHG_STUN), 0.0, 3.0);
        set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
        FxSparks(front);
        FxSprite(front, g_sprSmoke, 10, 160);
        ShakeOne(id);
        EmitKey(id, "CHARGER_IMPACT", CHAN_BODY);
        HudTo(id, SL_PERS, CLR_COOL, 1.2, "CHARGER_CRASH");
    }
    else
    {
        // Hucum bitince hiz yumusakca kesilir
        new Float:vel[3];
        get_entvar(id, var_velocity, vel);
        vel[0] *= 0.4;
        vel[1] *= 0.4;
        set_entvar(id, var_velocity, vel);
    }
    rg_reset_maxspeed(id);
    ApplyRender(id);
}

/* ---------------- 15 ORUMCEK: ag atisi ---------------- */

bool:ArachneWeb(id)
{
    new ent = ZProjSpawn(id, ZP_WEB, ZcF(ZCV_WEB_SPEED), ZcF(ZCV_WEB_RANGE));
    if (!ent)
        return false;
    EmitZombieSound(id, "ABILITY", "ZOMBIE_ACID");
    HudTo(id, SL_PERS, CLR_ZOMBIE, 1.0, "ARACHNE_YOU");
    return true;
}

WebHit(owner, p)
{
    new Float:now = get_gametime(), Float:po[3], name[32], vname[32];
    get_entvar(p, var_origin, po);
    new Float:root = floatclamp(ZcF(ZCV_WEB_ROOT), 0.0, 5.0), Float:slow = floatclamp(ZcF(ZCV_WEB_SLOW), 0.0, 10.0);

    if (g_bSurvivor[p] || g_bSniper[p])
        SlowHuman(p, root + slow);
    else
    {
        if (root > 0.0)
            RootHuman(p, root);
        if (g_fSlow[p] < now + root + slow)
            g_fSlow[p] = now + root + slow;
        rg_reset_maxspeed(p);
        g_fWebbed[p] = now + root;
    }

    FxSprite(po, g_sprWeb ? g_sprWeb : g_sprSmoke, g_sprWeb ? 5 : 8, 220);
    FxLight(po, 170, 90, 255, 14, 6, 20);
    FadeOne(p, 200, 170, 255, 110, floatmax(0.5, root));
    EmitKey(p, "ARACHNE_WEBHIT", CHAN_ITEM);
    ZcNameOf(owner, name, charsmax(name));
    ZcNameOf(p, vname, charsmax(vname));
    HudToS(p, SL_ALERT, CLR_DANGER, 2.0, "ARACHNE_WEBBED", name);
    HudToS(owner, SL_PERS, CLR_ZOMBIE, 1.4, "ARACHNE_HIT_YOU", vname);

    new Float:dmg = ZcF(ZCV_WEB_DMG);
    if (dmg > 0.0)
        ExecuteHamB(Ham_TakeDamage, p, 0, owner, dmg, DMG_GENERIC);
}

/* ---------------- 16 MAGMA: lav izi ---------------- */

bool:MagmaTrail(id)
{
    new Float:o[3];
    get_entvar(id, var_origin, o);
    g_fLava[id] = get_gametime() + floatclamp(ZcF(ZCV_MAG_TIME), 0.5, 20.0);
    g_fLavaPos[id] = o;
    MagmaPool(id, o);

    FxLava(o);
    FxRingEx(o, 255, 90, 0, 240, 16, 5);
    FxLight(o, 255, 90, 0, 30, 10, 15);
    EmitZombieSound(id, "ABILITY", "BURN");
    HudTo(id, SL_PERS, CLR_ZOMBIE, 1.5, "MAGMA_YOU");
    return true;
}

MagmaPool(id, const Float:o[3])
{
    AddPool(o, 2, floatclamp(ZcF(ZCV_MAG_LIFE), 0.5, 30.0), floatclamp(ZcF(ZCV_MAG_RAD), 20.0, 300.0), id);
    FxSprite(o, g_sprFire ? g_sprFire : g_sprExplode, 4, 200);
}

// Lav havuzlari: 0.5 sn'de bir hasar + yanma (sahibi magma zombisi)
LavaDamage()
{
    new Float:now = get_gametime(), Float:po[3];
    new Float:dmg = floatmax(0.0, ZcF(ZCV_MAG_DMG)) * 0.5;
    for (new s = 0; s < MAX_POOLS; s++)
    {
        if (g_iPoolType[s] != 2 || g_fPoolEnd[s] < now)
            continue;
        new owner = g_iPoolOwner[s];
        if (!(1 <= owner <= g_iMax) || !is_user_connected(owner) || !g_bZombie[owner])
            owner = 0;
        new Float:rad = g_fPoolRad[s] + 16.0;
        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_alive(p) || g_bZombie[p])
                continue;
            get_entvar(p, var_origin, po);
            if (get_distance_f(g_fPoolPos[s], po) > rad || floatabs(po[2] - g_fPoolPos[s][2]) > 60.0)
                continue;
            g_iBurn[p] = max(g_iBurn[p], 1);
            g_iBurnBy[p] = owner;
            FadeOne(p, 255, 90, 0, 70, 0.4);
            if (dmg > 0.0)
                ExecuteHamB(Ham_TakeDamage, p, 0, owner, dmg, DMG_BURN);
        }
    }
}

/* ---------------- 17 VOLT: EMP ---------------- */

bool:VoltEmp(id)
{
    new Float:o[3], Float:po[3], Float:mo[3], Float:eye[3];
    get_entvar(id, var_origin, o);
    ZcEye(id, eye);
    new Float:now = get_gametime();
    new Float:rad = floatclamp(ZcF(ZCV_VOLT_RAD), 50.0, 2000.0);
    new Float:mineOff = floatclamp(ZcF(ZCV_VOLT_MINE), 0.0, 60.0);
    new Float:lightOff = floatclamp(ZcF(ZCV_VOLT_LIGHT), 0.0, 60.0);
    new Float:dmg = ZcF(ZCV_VOLT_DMG), Float:slow = floatclamp(ZcF(ZCV_VOLT_SLOW), 0.0, 10.0);
    new mines;

    // Lazer mayinlari gecici olarak kapanir (isin kaybolur, vurmaz)
    if (mineOff > 0.0)
    {
        new ent;
        while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", LM_CLASS)) > 0)
        {
            get_entvar(ent, var_origin, mo);
            if (get_distance_f(o, mo) > rad)
                continue;
            set_entvar(ent, var_fuser3, now + mineOff);
            FxBeam(eye, mo, g_sprLightning, 80, 180, 255, 18);
            FxSparks(mo);
            mines++;
        }
    }

    new name[32];
    ZcNameOf(id, name, charsmax(name));
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > rad)
            continue;
        if (lightOff > 0.0)
            LightsOut(p, lightOff);
        if (slow > 0.0)
            SlowHuman(p, slow);
        FxBeam(eye, po, g_sprLightning, 120, 200, 255, 24);
        FadeOne(p, 80, 180, 255, 90, 0.5);
        EmitKey(p, "VOLT_ZAP", CHAN_ITEM);
        HudToS(p, SL_ALERT, CLR_DANGER, 2.0, "VOLT_EMP_HIT", name);
        if (dmg > 0.0)
            ExecuteHamB(Ham_TakeDamage, p, 0, id, dmg, DMG_SHOCK);
    }

    FxRingEx(o, 80, 180, 255, floatround(rad), 20, 6);
    FxRingEx(o, 200, 240, 255, floatround(rad * 0.6), 10, 4);
    if (g_sprEmp)
        FxSprite(o, g_sprEmp, 18, 230);
    FxLight(o, 80, 180, 255, 45, 10, 20);
    FxSparks(o);
    EmitZombieSound(id, "ABILITY", "ZAP");
    HudTo(id, SL_PERS, CLR_ZOMBIE, 2.0, "VOLT_YOU", mines);
    return true;
}

// fw_MineThink'ten: EMP'li mayin kapali mi? (true = bu karede hicbir sey yapma)
bool:MineEmpCheck(ent, const Float:o[3], Float:now)
{
    new Float:emp = Float:get_entvar(ent, var_fuser3);
    if (emp <= 0.0)
        return false;

    new beam = get_entvar(ent, var_iuser3);
    if (emp > now)
    {
        if (beam > 0 && !is_nullent(beam))
            set_entvar(beam, var_effects, get_entvar(beam, var_effects) | EF_NODRAW);
        if (random_num(1, 8) == 1)
            FxSparks(o);
        return true;
    }

    set_entvar(ent, var_fuser3, 0.0);
    if (beam > 0 && !is_nullent(beam))
        set_entvar(beam, var_effects, get_entvar(beam, var_effects) & ~EF_NODRAW);
    EmitKey(ent, "LM_ACTIVATE");
    new r, g, b;
    MineColor(ent, r, g, b);
    FxRingSmall(o, r, g, b);
    return false;
}

/* ---------------- 18 TAKLITCI: insan kiligi ---------------- */

bool:MimicDisguise(id)
{
    new Float:o[3], model[32];
    get_entvar(id, var_origin, o);
    g_fDisguise[id] = get_gametime() + floatclamp(ZcF(ZCV_MIM_TIME), 1.0, 60.0);

    if (g_szHumanModel[0])
        copy(model, charsmax(model), g_szHumanModel);
    else
        copy(model, charsmax(model), "gign");
    rg_set_user_model(id, model);
    rg_set_user_footsteps(id, true);
    ApplyRender(id);

    FxSprite(o, g_sprSmoke, 14, 140);
    FxImplosion(o, 80, 20, 4);
    EmitZombieSound(id, "ABILITY", "ABILITY_CLOAK");
    HudTo(id, SL_PERS, CLR_ZOMBIE, 2.5, "MIMIC_YOU");
    return true;
}

// Kilik acilir. victim > 0: saldirarak acildi (x2 hasar bildirimi)
MimicReveal(id, victim = 0)
{
    if (g_fDisguise[id] <= 0.0)
        return;
    g_fDisguise[id] = 0.0;
    if (!is_user_alive(id) || !g_bZombie[id])
        return;

    new cls = clamp(g_iClass[id], 0, NUM_CLASSES - 1);
    if (g_szZModel[cls][0])
        rg_set_user_model(id, g_szZModel[cls]);
    else
        rg_reset_user_model(id);
    rg_set_user_footsteps(id, false);
    ApplyRender(id);

    new Float:o[3];
    get_entvar(id, var_origin, o);
    FxImplosion(o, 90, 25, 4);
    FxBlood(o, 10);
    if (victim)
    {
        new name[32];
        ZcNameOf(id, name, charsmax(name));
        EmitKey(id, "MIMIC_REVEAL");
        if (is_user_connected(victim))
            HudToS(victim, SL_ALERT, CLR_DANGER, 2.0, "MIMIC_REVEALED", name);
        HudTo(id, SL_PERS, CLR_ZOMBIE, 1.5, "MIMIC_STRIKE_YOU");
    }
    else
        HudTo(id, SL_PERS, CLR_COOL, 1.5, "MIMIC_END_YOU");
}

/* ---------------- 19 KOSTEBEK: yeraltina dalis ---------------- */

bool:BurrowerDive(id)
{
    if (!(get_entvar(id, var_flags) & FL_ONGROUND))
    {
        SkillDeny(id, "SKILL_NEED_GROUND");
        return false;
    }
    new Float:o[3], Float:fl[3];
    get_entvar(id, var_origin, o);
    FloorAt(o, fl);
    g_fBurrow[id] = get_gametime() + floatclamp(ZcF(ZCV_BUR_TIME), 0.5, 10.0);
    // Mermi / bicak hic islemez (kan efekti de cikmaz -> yeri belli olmaz)
    set_entvar(id, var_takedamage, DAMAGE_NO);
    rg_set_user_footsteps(id, true);
    ApplyRender(id);
    rg_reset_maxspeed(id);

    FxSprite(fl, g_sprSmoke, 22, 170);
    FxParticles(fl, 60, 22, 6);
    FxRingEx(fl, 140, 100, 50, 160, 12, 4);
    EmitZombieSound(id, "ABILITY", "ZOMBIE_SHOCK");
    HudTo(id, SL_PERS, CLR_ZOMBIE, 2.0, "BURROW_YOU");
    return true;
}

// Sure dolunca cikis: cevredeki insanlar havaya firlar
BurrowErupt(id)
{
    g_fBurrow[id] = 0.0;
    if (!is_user_alive(id))
        return;
    set_entvar(id, var_takedamage, DAMAGE_AIM);
    rg_set_user_footsteps(id, false);
    ApplyRender(id);
    rg_reset_maxspeed(id);

    new Float:o[3], Float:po[3], name[32];
    get_entvar(id, var_origin, o);
    ZcNameOf(id, name, charsmax(name));
    new Float:rad = floatclamp(ZcF(ZCV_BUR_RAD), 50.0, 1000.0), Float:up = floatclamp(ZcF(ZCV_BUR_UP), 0.0, 1500.0);
    new Float:dmg = ZcF(ZCV_BUR_DMG);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > rad)
            continue;
        PushFrom(p, o, 220.0, up);
        ShakeOne(p);
        FadeOne(p, 140, 100, 50, 130, 0.8);
        HudToS(p, SL_ALERT, CLR_DANGER, 1.8, "BURROW_HIT", name);
        if (dmg > 0.0)
            ExecuteHamB(Ham_TakeDamage, p, 0, id, dmg, DMG_CRUSH);
    }

    FxRingEx(o, 140, 100, 50, floatround(rad), 26, 5);
    FxRingEx(o, 200, 160, 90, floatround(rad * 0.5), 14, 3);
    FxSprite(o, g_sprSmoke, 35, 200);
    FxSpr(o, g_sprFx[FXS_SHOCK], clamp(floatround(rad / 12.0), 8, 30), 210, -20.0);
    FxParticles(o, 140, 22, 10);
    FxLight(o, 160, 110, 50, 30, 8, 20);
    EmitKey(id, "BURROWER_ERUPT", CHAN_BODY);
}

// Olum / temizlik: firlatma olmadan gorunur hale getir
BurrowCancel(id)
{
    g_fBurrow[id] = 0.0;
    if (!is_user_alive(id))
        return;
    set_entvar(id, var_takedamage, DAMAGE_AIM);
    rg_set_user_footsteps(id, false);
    ApplyRender(id);
    rg_reset_maxspeed(id);
}

/* ---------------- 20 SIREN: ninni ---------------- */

bool:SirenLure(id)
{
    new Float:o[3], Float:po[3], name[32], hits;
    get_entvar(id, var_origin, o);
    ZcNameOf(id, name, charsmax(name));
    new Float:now = get_gametime();
    new Float:rad = floatclamp(ZcF(ZCV_SIR_RAD), 50.0, 2000.0), Float:dur = floatclamp(ZcF(ZCV_SIR_TIME), 0.5, 10.0);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > rad || !ZcVisible(id, p))
            continue;
        g_fLure[p] = now + dur;
        g_iLureBy[p] = id;
        SlowHuman(p, dur);
        FadeEx(p, 255, 80, 200, 110, 0.6, dur - 0.6);
        HudToS(p, SL_ALERT, CLR_DANGER, 2.0, "SIREN_LURED", name);
        hits++;
    }
    if (!hits)
    {
        SkillDeny(id, "SKILL_NO_TARGET");
        return false;
    }

    FxRingEx(o, 255, 90, 200, floatround(rad), 16, 6);
    FxRingEx(o, 255, 170, 230, floatround(rad * 0.5), 8, 4);
    FxLight(o, 255, 90, 200, 30, 12, 15);
    EmitZombieSound(id, "ABILITY", "ABILITY_SCREAM");
    HudTo(id, SL_PERS, CLR_ZOMBIE, 2.0, "SIREN_YOU", hits);
    return true;
}

LureEnd(p, bool:clearFade)
{
    new bool:was = (g_fLure[p] > get_gametime()) ? true : false;
    g_fLure[p] = 0.0;
    g_iLureBy[p] = 0;
    if (clearFade && was)
        FadeClear(p);
}

LureTick(p, Float:now)
{
    new s = g_iLureBy[p];
    if (now >= g_fLure[p])
    {
        LureEnd(p, false);
        return;
    }
    if (!(1 <= s <= g_iMax) || !is_user_alive(s) || !IsClassZombie(s, ZC_SIREN))
    {
        LureEnd(p, true);
        return;
    }

    new Float:so[3], Float:po[3], Float:vel[3];
    get_entvar(s, var_origin, so);
    get_entvar(p, var_origin, po);
    new Float:dx = so[0] - po[0], Float:dy = so[1] - po[1];
    new Float:d = floatsqroot(dx * dx + dy * dy);
    if (d > 48.0)
    {
        new Float:pull = floatclamp(ZcF(ZCV_SIR_PULL), 0.0, 800.0);
        get_entvar(p, var_velocity, vel);
        vel[0] = vel[0] * 0.5 + dx / d * pull;
        vel[1] = vel[1] * 0.5 + dy / d * pull;
        set_entvar(p, var_velocity, vel);
    }
    if (g_iZcTick % 3 == 0)
    {
        so[2] += 20.0;
        po[2] += 10.0;
        FxBeam(so, po, g_sprBeam, 255, 90, 200, 6);
    }
}

/* ---------------- 21 KALE: tahkim ---------------- */

bool:BulwarkFortify(id)
{
    new Float:o[3];
    get_entvar(id, var_origin, o);
    g_fFortify[id] = get_gametime() + floatclamp(ZcF(ZCV_BUL_TIME), 0.5, 30.0);
    ApplyRender(id);
    FxRingEx(o, 130, 150, 130, 220, 24, 5);
    FxSparks(o);
    FxLight(o, 140, 160, 140, 25, 10, 15);
    EmitZombieSound(id, "ABILITY", "ABILITY_SHIELD");
    HudTo(id, SL_PERS, CLR_ZOMBIE, 2.0, "BULWARK_YOU");
    return true;
}

/* ---------------- 22 SPOR ANA: spor kesesi ---------------- */

bool:SporePlant(id)
{
    new Float:now = get_gametime();
    new maxp = clamp(ZcN(ZCV_SPO_MAX), 1, 6);

    // Sinira ulasildiysa en eski kese patlamadan soner
    new ent, n, oldest, Float:oldT = 999999.0;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", SPORE_CLASS)) > 0)
    {
        if (get_entvar(ent, var_iuser1) != id)
            continue;
        n++;
        if (Float:get_entvar(ent, var_fuser4) < oldT)
        {
            oldT = Float:get_entvar(ent, var_fuser4);
            oldest = ent;
        }
    }
    if (n >= maxp && oldest)
    {
        SporeRemove(oldest, true);
        n--;
    }

    new Float:o[3], Float:pos[3];
    get_entvar(id, var_origin, o);
    FloorAt(o, pos);

    ent = rg_create_entity("info_target");
    if (is_nullent(ent))
        return false;

    set_entvar(ent, var_classname, SPORE_CLASS);
    if (g_szSporeModel[0])
    {
        engfunc(EngFunc_SetModel, ent, g_szSporeModel);
        set_entvar(ent, var_sequence, 0);
        set_entvar(ent, var_framerate, 1.0);
        set_entvar(ent, var_animtime, now);
        set_entvar(ent, var_renderfx, kRenderFxGlowShell);
        set_entvar(ent, var_rendercolor, Float:{110.0, 200.0, 60.0});
        set_entvar(ent, var_renderamt, 6.0);
    }
    else
    {
        new spr[64];
        copy(spr, charsmax(spr), g_szSprSpore[0] ? g_szSprSpore : g_szSprOrb);
        if (spr[0])
        {
            engfunc(EngFunc_SetModel, ent, spr);
            set_entvar(ent, var_rendermode, kRenderTransAdd);
            set_entvar(ent, var_renderamt, 220.0);
            set_entvar(ent, var_rendercolor, Float:{110.0, 220.0, 60.0});
            set_entvar(ent, var_scale, 0.45);
        }
        pos[2] += 14.0;
    }

    new Float:hp = float(clamp(ZcN(ZCV_SPO_HP), 1, 5000));
    set_entvar(ent, var_movetype, MOVETYPE_NONE);
    set_entvar(ent, var_solid, SOLID_BBOX);
    engfunc(EngFunc_SetSize, ent, Float:{-10.0, -10.0, 0.0}, Float:{10.0, 10.0, 22.0});
    engfunc(EngFunc_SetOrigin, ent, pos);
    set_entvar(ent, var_takedamage, DAMAGE_YES);
    set_entvar(ent, var_health, hp);
    set_entvar(ent, var_max_health, hp);
    set_entvar(ent, var_iuser1, id);
    set_entvar(ent, var_fuser1, now + 1.0);                                          // kurulma
    set_entvar(ent, var_fuser2, now + floatclamp(ZcF(ZCV_SPO_LIFE), 5.0, 600.0));    // omur
    set_entvar(ent, var_fuser4, now);
    SetThink(ent, "fw_SporeThink");
    set_entvar(ent, var_nextthink, now + 0.2);

    FxRingSmall(pos, 110, 200, 60);
    FxParticles(pos, 30, 60, 4);
    EmitZombieSound(id, "ABILITY", "ABILITY_TOXIC");
    HudTo(id, SL_PERS, CLR_ZOMBIE, 1.5, "SPORE_YOU", n + 1);
    return true;
}

public fw_SporeThink(ent)
{
    if (is_nullent(ent))
        return;

    new owner = get_entvar(ent, var_iuser1);
    new Float:now = get_gametime();
    if (!g_bRoundActive || !is_user_alive(owner) || !IsClassZombie(owner, ZC_SPOREMOTHER) || now >= Float:get_entvar(ent, var_fuser2))
    {
        SporeRemove(ent, true);
        return;
    }

    new Float:o[3], Float:po[3];
    get_entvar(ent, var_origin, o);
    if (now >= Float:get_entvar(ent, var_fuser1))
    {
        new Float:rad = floatclamp(ZcF(ZCV_SPO_RAD), 20.0, 600.0);
        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_alive(p) || g_bZombie[p])
                continue;
            get_entvar(p, var_origin, po);
            if (get_distance_f(o, po) <= rad)
            {
                SporeBurst(ent, owner);
                return;
            }
        }
    }
    if (random_num(1, 6) == 1)
        FxLight(o, 110, 220, 60, 8, 5, 10);

    set_entvar(ent, var_nextthink, now + 0.2);
}

SporeBurst(ent, owner)
{
    new Float:o[3], Float:po[3], name[32];
    get_entvar(ent, var_origin, o);
    ZcNameOf(owner, name, charsmax(name));
    new Float:rad = floatclamp(ZcF(ZCV_SPO_RAD), 20.0, 600.0) * 1.4;
    new ticks = clamp(ZcN(ZCV_SPO_POISON), 0, 30), Float:slow = floatclamp(ZcF(ZCV_SPO_SLOW), 0.0, 10.0);
    new hits;

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > rad)
            continue;
        if (ticks > 0)
        {
            g_iPoison[p] = max(g_iPoison[p], ticks);
            g_iPoisonBy[p] = owner;
        }
        if (slow > 0.0)
            SlowHuman(p, slow);
        FadeOne(p, 110, 200, 60, 130, 1.2);
        HudToS(p, SL_ALERT, CLR_DANGER, 1.8, "SPORE_HIT", name);
        hits++;
    }

    FxSprite(o, g_sprSpore ? g_sprSpore : g_sprSmoke, g_sprSpore ? 12 : 25, 220);
    FxExploEl(o, EL_TOXIC, clamp(floatround(rad / 14.0), 8, 24), 14);
    FxParticles(o, 120, 60, 8);
    FxRingEx(o, 110, 200, 60, floatround(rad), 14, 4);
    FxLight(o, 110, 220, 60, 30, 8, 20);
    EmitKeyPos(o, "SPOREMOTHER_BURST");
    if (hits && is_user_connected(owner))
        HudTo(owner, SL_PERS, CLR_ZOMBIE, 1.5, "SPORE_BURST_YOU", hits);
    SporeRemove(ent, false);
}

// Kese hasari: sadece insanlar kirabilir (fw_EntTakeDamage)
SporeTakeDamage(ent, attacker, Float:damage)
{
    if (!(1 <= attacker <= g_iMax) || !is_user_connected(attacker) || g_bZombie[attacker])
        return HAM_SUPERCEDE;

    new Float:hp = Float:get_entvar(ent, var_health) - damage;
    if (hp > 0.0)
    {
        set_entvar(ent, var_health, hp);
        new Float:o[3];
        get_entvar(ent, var_origin, o);
        if (random_num(1, 3) == 1)
            FxParticles(o, 20, 60, 2);
        return HAM_SUPERCEDE;
    }

    new owner = get_entvar(ent, var_iuser1);
    if (is_user_connected(owner))
    {
        new name[32];
        ZcNameOf(attacker, name, charsmax(name));
        Chat(owner, "SPORE_DESTROYED", name);
    }
    AddAP(attacker, 1, true, true);
    SporeRemove(ent, true);
    return HAM_SUPERCEDE;
}

SporeRemove(ent, bool:puff)
{
    if (is_nullent(ent))
        return;
    if (puff)
    {
        new Float:o[3];
        get_entvar(ent, var_origin, o);
        FxSprite(o, g_sprSmoke, 6, 100);
        FxParticles(o, 30, 60, 3);
    }
    SetThink(ent, "");
    set_entvar(ent, var_takedamage, DAMAGE_NO);
    set_entvar(ent, var_solid, SOLID_NOT);
    set_entvar(ent, var_iuser1, 0);
    set_entvar(ent, var_classname, "vex_removed");
    set_entvar(ent, var_flags, FL_KILLME);
}

RemovePlayerSpores(id)
{
    new ent;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", SPORE_CLASS)) > 0)
    {
        if (get_entvar(ent, var_iuser1) == id)
            SporeRemove(ent, true);
    }
}

/* ---------------- 23 KABUS: dehset ---------------- */

bool:NightmareTerror(id)
{
    new Float:o[3], Float:po[3], name[32], hits;
    get_entvar(id, var_origin, o);
    ZcNameOf(id, name, charsmax(name));
    new Float:now = get_gametime();
    new Float:rad = floatclamp(ZcF(ZCV_NM_RAD), 50.0, 2000.0), Float:blind = floatclamp(ZcF(ZCV_NM_BLIND), 0.5, 10.0);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > rad || !ZcVisible(id, p))
            continue;
        g_fBlind[p] = now + blind;
        FadeEx(p, 0, 0, 0, 252, 0.7, floatmax(0.1, blind - 0.7));
        LightsOut(p, blind);
        ShakeOne(p);
        PlayKey(p, "HEARTBEAT");
        HudToS(p, SL_ALERT, CLR_DANGER, 2.0, "NIGHTMARE_HIT", name);
        hits++;
    }

    g_fTerror[id] = now + floatclamp(ZcF(ZCV_NM_BOOST), 0.5, 15.0);
    rg_reset_maxspeed(id);
    ApplyRender(id);

    FxRingEx(o, 120, 0, 0, floatround(rad), 30, 8);
    FxImplosion(o, 200, 40, 6);
    FxSprite(o, g_sprSmoke, 30, 50);
    FxLight(o, 160, 0, 0, 35, 10, 10);
    EmitZombieSound(id, "ABILITY", "ABILITY_SCREAM");
    HudTo(id, SL_PERS, CLR_ZOMBIE, 2.0, "NIGHTMARE_YOU", hits);
    return true;
}

// Sureli sinif yeteneginin kalan suresi (HUD: "[R] AKTIF")
Float:ZcActiveLeft(id)
{
    new Float:now = get_gametime(), Float:m = 0.0;
    new Float:t[6];
    t[0] = g_fCharge[id]; t[1] = g_fBurrow[id]; t[2] = g_fDisguise[id];
    t[3] = g_fFortify[id]; t[4] = g_fTerror[id]; t[5] = g_fLava[id];
    for (new i = 0; i < sizeof t; i++)
    {
        if (t[i] - now > m)
            m = t[i] - now;
    }
    if (g_iHookEnt[id] && ZProjValid(g_iHookEnt[id]))
        m = floatmax(m, 0.1);
    return m;
}

/* ---------------- Her kare (fw_PreThink) ---------------- */

ZcPreThink(id)
{
    if (g_iHookedBy[id])
        HookPullVictim(id);
    if (!g_bZombie[id])
        return;
    if (g_fCharge[id] > 0.0)
        ChargeThink(id);
    if (g_fPounce[id] > 0.0 && is_user_alive(id))
        PounceThink(id);
}

/* ---------------- 0.1 sn zamanlayici ---------------- */

public task_ZcTick()
{
    g_iZcTick++;
    if (!g_bRoundActive)
        return;

    new Float:now = get_gametime();
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id))
            continue;

        // Sersemletme / kok / yavaslama suresi hassas biter (saniyelik kontrolu beklemez)
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

        if (g_bZombie[id])
            ZcTickZombie(id, now);
        else
            ZcTickHuman(id, now);
    }

    if (g_iZcTick % 5 == 0)
    {
        LavaDamage();
        if (ZcN(ZCV_BOT))
            BotAbilities();
    }
}

ZcTickZombie(id, Float:now)
{
    if (g_fFortify[id] > 0.0 && now > g_fFortify[id])
    {
        g_fFortify[id] = 0.0;
        ApplyRender(id);
    }
    if (g_fTerror[id] > 0.0)
    {
        if (now > g_fTerror[id])
        {
            g_fTerror[id] = 0.0;
            rg_reset_maxspeed(id);
            ApplyRender(id);
        }
        else if (g_iZcTick % 3 == 0)
        {
            new Float:o[3];
            get_entvar(id, var_origin, o);
            FxLight(o, 140, 0, 0, 12, 4, 10);
        }
    }
    if (g_fDisguise[id] > 0.0 && now > g_fDisguise[id])
        MimicReveal(id);

    if (g_fBurrow[id] > 0.0)
    {
        if (now >= g_fBurrow[id])
            BurrowErupt(id);
        else
        {
            new Float:o[3], Float:fl[3];
            get_entvar(id, var_origin, o);
            FloorAt(o, fl);
            FxParticles(fl, 24, 22, 2);
            if (g_iZcTick % 3 == 0)
                FxSprite(fl, g_sprSmoke, 5, 90);
        }
    }

    if (g_fLava[id] > 0.0)
    {
        if (now > g_fLava[id])
            g_fLava[id] = 0.0;
        else
        {
            new Float:o[3];
            get_entvar(id, var_origin, o);
            if ((get_entvar(id, var_flags) & FL_ONGROUND) && get_distance_f(o, g_fLavaPos[id]) >= 64.0)
            {
                g_fLavaPos[id] = o;
                MagmaPool(id, o);
            }
            if (g_iZcTick % 2 == 0)
                FxLight(o, 255, 90, 0, 14, 3, 10);
        }
    }
}

ZcTickHuman(id, Float:now)
{
    if (g_fLure[id] > 0.0)
        LureTick(id, now);

    if (g_fWebbed[id] > 0.0)
    {
        if (now > g_fWebbed[id])
            g_fWebbed[id] = 0.0;
        else if (g_iZcTick % 5 == 0)
        {
            new Float:o[3];
            get_entvar(id, var_origin, o);
            FxSprite(o, g_sprWeb ? g_sprWeb : g_sprSmoke, g_sprWeb ? 3 : 4, 160);
        }
    }
    if (g_fNoLight[id] > 0.0 && now > g_fNoLight[id])
        g_fNoLight[id] = 0.0;
    if (g_fBlind[id] > 0.0 && now > g_fBlind[id])
        g_fBlind[id] = 0.0;
}

/* ---------------- Temizlik ---------------- */

// Oyuncunun tum sinif yetenegi durumlari + varliklari (hem zombi hem kurban tarafi)
ZcCleanup(id)
{
    if (!(1 <= id <= 32))
        return;

    // Zombi tarafi: kanca / ag / keseler
    if (g_iHookEnt[id] && ZProjValid(g_iHookEnt[id]))
        ZProjRemove(g_iHookEnt[id]);
    g_iHookEnt[id] = 0;
    RemoveOwnedProj(id);
    RemovePlayerSpores(id);

    if (g_fBurrow[id] > 0.0)
        BurrowCancel(id);
    if (g_fDisguise[id] > 0.0)
    {
        g_fDisguise[id] = 0.0;
        if (is_user_alive(id) && g_bZombie[id])
        {
            new cls = clamp(g_iClass[id], 0, NUM_CLASSES - 1);
            if (g_szZModel[cls][0])
                rg_set_user_model(id, g_szZModel[cls]);
            else
                rg_reset_user_model(id);
            rg_set_user_footsteps(id, false);
        }
    }
    new bool:render = (g_fCharge[id] > 0.0 || g_fFortify[id] > 0.0 || g_fTerror[id] > 0.0) ? true : false;
    g_fPounce[id] = 0.0;
    g_fCharge[id] = 0.0;
    g_iChargeHit[id] = 0;
    g_fLava[id] = 0.0;
    g_fFortify[id] = 0.0;
    g_fTerror[id] = 0.0;
    if (render && is_user_alive(id))
    {
        ApplyRender(id);
        rg_reset_maxspeed(id);
    }

    // Bu sirenin ninnisindeki insanlar serbest
    for (new p = 1; p <= g_iMax; p++)
    {
        if (g_iLureBy[p] == id)
            LureEnd(p, true);
    }

    // Kurban tarafi
    if (g_iHookedBy[id])
    {
        new b = g_iHookedBy[id];
        if ((1 <= b <= g_iMax) && g_iHookEnt[b] && ZProjValid(g_iHookEnt[b]))
            ZProjRemove(g_iHookEnt[b]);
        g_iHookedBy[id] = 0;
    }
    if (g_fLure[id] > 0.0)
        LureEnd(id, true);
    if (g_fBlind[id] > get_gametime())
        FadeClear(id);
    g_fBlind[id] = 0.0;
    g_fNoLight[id] = 0.0;
    g_fWebbed[id] = 0.0;
}

// Round sonu / yeni round: herkes + sahipsiz kalmis tum varliklar
ZcCleanupAll()
{
    for (new id = 1; id <= g_iMax; id++)
        ZcCleanup(id);

    new ent;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", ZPROJ_CLASS)) > 0)
        ZProjRemove(ent);
    ent = 0;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", SPORE_CLASS)) > 0)
        SporeRemove(ent, false);
    ent = 0;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "beam")) > 0)
    {
        if (get_entvar(ent, var_iuser1) == BEAM_MARK_HOOK)
            set_entvar(ent, var_flags, FL_KILLME);
    }
    for (new s = 0; s < MAX_POOLS; s++)
    {
        if (g_iPoolType[s] == 2)
            g_fPoolEnd[s] = 0.0;
    }
}

/* ---------------- Botlar: zombi yetenekleri ---------------- */

// Sinif yeteneginin kullanildigi en uzak mesafe (insan gorunur olmali)
new const Float:BOT_SKILL_RANGE[NUM_CLASSES] =
{
    500.0, 650.0, 350.0, 420.0, 9999.0, 700.0, 260.0, 300.0, 400.0, 280.0, 420.0, 600.0,
    800.0, 420.0, 520.0, 850.0, 350.0, 330.0, 900.0, 600.0, 380.0, 400.0, 600.0, 430.0
};

stock ZcNearestHuman(id, Float:range)
{
    new Float:o[3], Float:po[3], best, Float:bestD = range;
    get_entvar(id, var_origin, o);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        new Float:d = get_distance_f(o, po);
        if (d > bestD || !ZcVisible(id, p))
            continue;
        bestD = d;
        best = p;
    }
    return best;
}

// Botun bakisini hedefe cevir (yonlu yetenekler icin)
stock ZcFace(id, t)
{
    new Float:eye[3], Float:po[3], Float:dir[3], Float:ang[3];
    ZcEye(id, eye);
    get_entvar(t, var_origin, po);
    po[2] += 8.0;
    for (new i = 0; i < 3; i++)
        dir[i] = po[i] - eye[i];
    engfunc(EngFunc_VecToAngles, dir, ang);
    ang[0] = -ang[0];
    set_entvar(id, var_v_angle, ang);
    ang[0] = 0.0;
    set_entvar(id, var_angles, ang);
}

BotAbilities()
{
    new Float:now = get_gametime();
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || !is_user_bot(id) || !g_bZombie[id] || g_bMinion[id] || g_fFrozen[id] > now)
            continue;

        if (g_bBoss[id])
        {
            // Bossun R yetenegi BossAutoR'da; burada [F] atilma
            if (g_fBossIntro > now || now < g_fLeapCool[id] || random_num(1, 100) > 30)
                continue;
            new t = ZcNearestHuman(id, 800.0);
            if (t)
            {
                ZcFace(id, t);
                SkillTrigger(id, 2);
            }
            continue;
        }
        if (g_bNemesis[id] || g_bAssassin[id])
        {
            new t = ZcNearestHuman(id, 750.0);
            if (!t)
                continue;
            if (now >= g_fFCool[id] && random_num(1, 100) <= 35)
                SkillTrigger(id, 2);
            else if (now >= g_fLeapCool[id] && random_num(1, 100) <= 30)
            {
                ZcFace(id, t);
                SkillTrigger(id, 1);
            }
            continue;
        }

        if (now < g_fCool[id] || random_num(1, 100) > 45)
            continue;
        new cls = clamp(g_iClass[id], 0, NUM_CLASSES - 1);
        if (cls == ZC_LEECH && Float:get_entvar(id, var_health) > float(g_iMaxHP[id]) * 0.6)
            continue;
        new t = ZcNearestHuman(id, (cls == ZC_LEECH) ? 900.0 : BOT_SKILL_RANGE[cls]);
        if (!t)
            continue;
        ZcFace(id, t);
        SkillTrigger(id, 1);
    }
}
