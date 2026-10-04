/* ================================================================== */
/*  Vexmira Zombie - modul: vex/bosses.inc  (BOSSLAR)                 */
/*  Boss baslatma / faz / olum, pasif yetenekler, fazli [R]           */
/*  yetenekleri (27), boss mermileri / yumurtalar, boss / Nemesis /   */
/*  Assassin sesleri.                                                 */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

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

StartBoss(players[32], n)
{
    new boss = players[random(n)];
    new humans = max(1, n - 1);

    BossCleanup();
    g_iBoss = boss;
    g_iBossTick = 0;
    g_iBossPhase = 1;
    g_bEnraged = false;
    g_fBossRCool = get_gametime() + 4.0;
    g_fBossRLast = get_gametime() + 2.5;
    g_bBoss[boss] = 1;
    g_bZombie[boss] = 1;
    g_fEclipseEnd = 0.0;
    g_fBlizzardEnd = 0.0;

    for (new p = 1; p <= g_iMax; p++)
        g_iBossDmg[p] = 0;

    rg_set_user_team(boss, TEAM_TERRORIST, MODEL_UNASSIGNED, true, false);
    rg_remove_all_items(boss);
    rg_give_item(boss, "weapon_knife");
    RemovePlayerMines(boss, false);

    new Float:hp = get_pcvar_float(g_pBossHP) * BOSS_HP_MULT[g_iBossType] + get_pcvar_float(g_pBossHPPer) * float(humans);
    if (g_bFinalBoss)
        hp *= floatmax(1.0, get_pcvar_float(g_pBossFinal));
    g_iBossMaxHP = max(1000, floatround(hp));
    g_iMaxHP[boss] = g_iBossMaxHP;

    set_entvar(boss, var_health, float(g_iBossMaxHP));
    set_entvar(boss, var_max_health, float(g_iBossMaxHP));
    SetGravity(boss, BOSS_GRAV[g_iBossType]);
    rg_set_user_armor(boss, 0, ARMOR_NONE);
    if (g_szBModel[g_iBossType][0])
        rg_set_user_model(boss, g_szBModel[g_iBossType]);
    // v3.0: bossa ozel adim sesi varsa oyunun ayak sesi susturulur (adimlar VoiceTick'te)
    new stepKey[24];
    rg_set_user_footsteps(boss, BossSndKey("STEP", stepKey, charsmax(stepKey)) ? true : false);
    ApplyRender(boss);

    // Giris: boss 2.5 sn yerinde kukrer
    g_fBossIntro = get_gametime() + 2.5;
    rg_reset_maxspeed(boss);
    set_entvar(boss, var_velocity, Float:{0.0, 0.0, 0.0});

    new name[32], key[20], Float:o[3];
    get_user_name(boss, name, charsmax(name));
    get_entvar(boss, var_origin, o);

    new r = BOSS_RGB[g_iBossType][0], g = BOSS_RGB[g_iBossType][1], b = BOSS_RGB[g_iBossType][2];

    // Sinematik giris
    FadeAll(0, 0, 0, 220, 0.8);
    FxTeleport(o);
    FxLava(o);
    FxFunnel(o, g_sprFlare, false);
    for (new i = 0; i < 5; i++)
        FxSkyStrike(o, r, g, b);
    FxRingEx(o, r, g, b, 700, 40, 8);
    FxRingEx(o, 255, 255, 255, 400, 20, 6);
    FxDisk(o, r, g, b, 350, 10);
    FxExplosion(o);
    FxLight(o, r, g, b, 60, 30, 10);
    ShakeAll(14, 3.0, 6);

    ChatAllS("BOSS_SPAWNED", name);
    formatex(key, charsmax(key), "BOSS_INFO_%d", g_iBossType);
    ChatAll(key);
    Chat(boss, "ROLE_BOSS_YOU");
    Chat(boss, "ROLE_BOSS_KEYS");
    Chat(boss, "SKILL_KEYS_HINT");
    if (!is_user_bot(boss))
    {
        new sk[16], skn[48];
        formatex(sk, charsmax(sk), "BSK_%d_1", g_iBossType);
        formatex(skn, charsmax(skn), "%L", boss, sk);
        Chat(boss, "BSK_FIRST_SKILL", skn);
    }

    // Buyuk isim: "B R U T E" + unvan
    new nm[32], spaced[64], txt[128];
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        formatex(key, charsmax(key), "BOSS_NAME_%d", g_iBossType);
        formatex(nm, charsmax(nm), "%L", p, key);
        SpaceOut(nm, spaced, charsmax(spaced));
        formatex(key, charsmax(key), "BOSS_TITLE_%d", g_iBossType);
        if (g_bFinalBoss)
            formatex(txt, charsmax(txt), "%L^n%s^n%L", p, "FINAL_BOSS_TAG", spaced, p, key);
        else
            formatex(txt, charsmax(txt), "%s^n%L", spaced, p, key);
        HudText(p, SL_ANN, r, g, b, 4.0, txt);
    }

    formatex(key, charsmax(key), "BOSS_START_%d", g_iBossType);
    HudAll(SL_ALERT, CLR_DANGER, 3.0, key);
    // v3.0: bossa ozel giris sesi (herkese); yoksa genel giris sesi
    if (!PlayBossSound("INTRO"))
        PlayKey(0, "BOSS_INTRO");
    VoiceReset(boss);

    set_task(0.9, "task_BossFlash", TASK_INTRO);
    set_task(2.5, "task_BossIntroEnd", TASK_INTRO + 1);
}

public task_BossFlash()
{
    if (!g_iBoss)
        return;
    FadeAll(BOSS_RGB[g_iBossType][0], BOSS_RGB[g_iBossType][1], BOSS_RGB[g_iBossType][2], 120, 1.5);
}

public task_BossIntroEnd()
{
    if (!g_iBoss || !is_user_alive(g_iBoss))
        return;

    g_fBossIntro = 0.0;
    rg_reset_maxspeed(g_iBoss);

    new Float:o[3];
    get_entvar(g_iBoss, var_origin, o);
    FxRingEx(o, BOSS_RGB[g_iBossType][0], BOSS_RGB[g_iBossType][1], BOSS_RGB[g_iBossType][2], 900, 60, 7);
    FxLava(o);
    EmitBossSound("PHASE");
    ShakeAll(10, 1.5, 5);
    // v3.0: can bari belirdi
    PlayKey(0, "UI_BOSS_BAR");
}

// Boss hasari: yetenek carpani + delilik + final
BossHurt(id, Float:dmg, bits)
{
    if (!is_user_alive(id) || g_bZombie[id])
        return;

    dmg *= get_pcvar_float(g_pBossAbil);
    if (g_bEnraged)
        dmg *= 1.3;
    if (g_bFinalBoss)
        dmg *= 1.15;

    // v3.0 (C): vurulan insanin ustunde bossun element izi (0.4 sn'de bir)
    if (0 <= g_iBossType < NUM_BOSSES && get_gametime() >= g_fFxHitT[id])
    {
        g_fFxHitT[id] = get_gametime() + 0.4;
        new Float:vo[3];
        get_entvar(id, var_origin, vo);
        FxElSmall(vo, BOSS_ELEM[g_iBossType], 6);
    }
    ExecuteHamB(Ham_TakeDamage, id, 0, (g_iBoss && is_user_connected(g_iBoss)) ? g_iBoss : 0, dmg, bits);
}

TickBoss()
{
    // Etkinlik bitisleri (boss olmus olsa bile)
    new Float:now = get_gametime();
    if (g_fEclipseEnd > 0.0 && now > g_fEclipseEnd)
        EndEclipse();
    if (g_fBlizzardEnd > 0.0 && now > g_fBlizzardEnd)
        EndBlizzard();

    if (!g_iBoss || !is_user_alive(g_iBoss))
        return;

    new boss = g_iBoss;
    new Float:o[3], Float:po[3];
    get_entvar(boss, var_origin, o);

    new r = BOSS_RGB[g_iBossType][0], g = BOSS_RGB[g_iBossType][1], b = BOSS_RGB[g_iBossType][2];

    // Faz kontrolu
    new hp = floatround(Float:get_entvar(boss, var_health));
    new pct = hp * 100 / max(1, g_iBossMaxHP);
    new p2 = clamp(get_pcvar_num(g_pBossPhase2), 2, 99), p3 = clamp(get_pcvar_num(g_pBossPhase3), 1, p2 - 1);
    new phase = (pct > p2) ? 1 : (pct > p3) ? 2 : 3;

    if (phase > g_iBossPhase)
    {
        g_iBossPhase = phase;
        BossPhaseChange();
    }

    BossHud(hp, pct);

    // Kalici gorunum: buyuk renkli isik, iz, bas isareti, adim dalgalari
    FxLight(o, r, g, b, g_bEnraged ? 55 : 42, 11, 5);
    if (g_iFrame % 2 == 0)
    {
        FxFollow(boss, r, g, b, 18, 10);
        // v3.1: boss zaten kafa ustu can bari / amblemiyle isaretli; ek isaret yalniz bunlar
        // yoksa ve sprite oyuncuya bagli cizilebiliyorsa (alphatest). Additive glow01 eskiden
        // TE_PLAYERATTACHMENT ile normal cizilip siyah zeminli beyaz kare olarak gorunuyordu.
        if (g_bHeadMarkAt && !g_iOvhBar[boss] && !g_iOvhEmb[boss])
            FxHeadMark(boss, g_sprHeadMark, 21, true);

        new Float:feet[3];
        feet = o;
        feet[2] -= 30.0;
        FxRingEx(feet, r, g, b, 160, 10, 4, 160);
        // v3.0: adim sesleri hiza gore VoiceTick'te, ara sira hirlama da orada
    }

    // Aura: her 3 sn yakindakileri sarsan, can yakan dalga
    if (g_iFrame % 3 == 0)
    {
        FxRing(o, r, g, b, 280);
        FxImplosion(o, 120, 20, 4);
        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_alive(p) || g_bZombie[p])
                continue;
            get_entvar(p, var_origin, po);
            if (get_distance_f(o, po) > 260.0)
                continue;
            ShakeOne(p);
            BossHurt(p, 6.0, DMG_CRUSH);
        }
    }

    BossPassive(boss, o);

    // Kar firtinasi: herkes donar, can kaybeder
    if (g_fBlizzardEnd > now)
    {
        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_alive(p) || g_bZombie[p])
                continue;
            get_entvar(p, var_origin, po);
            FxStreak(po, 7, 20, 120);
            BossHurt(p, 4.0, DMG_FREEZE);
        }
    }

    // [R] yapay zeka: bot boss / uzun sure R kullanmayan boss
    BossAutoR();

    // Otomatik saldirilar (uyarili). Faz ilerledikce siklasir; faz 2+ eski R yetenekleri de katilir.
    new interval = (g_iBossPhase == 1) ? 9 : (g_iBossPhase == 2) ? 7 : 5;
    if (get_pcvar_num(g_pBossAutoAbil) && g_fBossIntro <= now && ++g_iBossTick >= interval && !task_exists(TASK_BOSSCAST))
    {
        g_iBossTick = 0;

        if (!BossAutoOldSkill())
        {
            new ability = 0;
            if (g_iBossPhase >= 2 && random_num(0, 1))
                ability = 1;
            BossTelegraph(ability);
        }
    }
}

// Her bossun kendine has pasif etkisi
BossPassive(boss, const Float:o[3])
{
    new Float:po[3], Float:now = get_gametime();

    switch (g_iBossType)
    {
        case 1: // Banshee: yakindakilerin ekrani titrer
        {
            if (g_iFrame % 6 == 0)
            {
                EmitBossSound("IDLE", ATTN_NORM, 0.7);
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p) || g_bZombie[p])
                        continue;
                    get_entvar(p, var_origin, po);
                    if (get_distance_f(o, po) <= 320.0)
                        FadeOne(p, 200, 210, 255, 90, 0.6);
                }
            }
        }
        case 3: // Inferno: ayak altinda ates, yakindakiler tutusur
        {
            FxSprite(o, g_sprExplode, 6, 160);
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_alive(p) || g_bZombie[p])
                    continue;
                get_entvar(p, var_origin, po);
                if (get_distance_f(o, po) <= 170.0)
                {
                    g_iBurn[p] = max(g_iBurn[p], 2);
                    g_iBurnBy[p] = boss;
                }
            }
        }
        case 5: // Frostlord: soguk aura yavaslatir
        {
            FxStreak(o, 7, 30, 160);
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_alive(p) || g_bZombie[p])
                    continue;
                get_entvar(p, var_origin, po);
                if (get_distance_f(o, po) <= 240.0)
                {
                    g_fSlow[p] = now + 1.2;
                    rg_reset_maxspeed(p);
                    FadeOne(p, 120, 200, 255, 50, 0.5);
                }
            }
        }
        case 6: // Stormcaller: en yakindakine kucuk simsek
        {
            FxSparks(o);
            if (g_iFrame % 2 == 0)
            {
                new best, Float:bd = 300.0;
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p) || g_bZombie[p])
                        continue;
                    get_entvar(p, var_origin, po);
                    new Float:d = get_distance_f(o, po);
                    if (d < bd)
                    {
                        bd = d;
                        best = p;
                    }
                }
                if (best)
                {
                    get_entvar(best, var_origin, po);
                    FxBeamEntPoint(boss, po, g_sprLightning, 255, 240, 80, 25, 50, 2);
                    BossHurt(best, 5.0, DMG_SHOCK);
                    EmitKey(best, "ZAP");
                }
            }
        }
        case 7: // Hive Queen: yenilenir, zehirli spor saliyor
        {
            HealTo(boss, max(10, g_iBossMaxHP / 250), g_iBossMaxHP);
            if (g_iFrame % 2 == 0)
                FxSprite(o, g_sprSmoke, 15, 120);
        }
        case 8: // Void: yakindakileri kendine ceker
        {
            FxImplosion(o, 200, 30, 5);
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_alive(p) || g_bZombie[p])
                    continue;
                get_entvar(p, var_origin, po);
                new Float:d = get_distance_f(o, po);
                if (d > 340.0 || d < 40.0)
                    continue;
                new Float:vel[3];
                get_entvar(p, var_velocity, vel);
                vel[0] += (o[0] - po[0]) / d * 110.0;
                vel[1] += (o[1] - po[1]) / d * 110.0;
                set_entvar(p, var_velocity, vel);
            }
        }
    }
}

BossPhaseChange()
{
    new Float:o[3], key[20];
    get_entvar(g_iBoss, var_origin, o);

    // Yeni faz = yeni [R] yetenegi: hemen kullanilabilir
    g_fBossRCool = get_gametime() + 1.0;
    BossSkillUnlock();

    new r = BOSS_RGB[g_iBossType][0], g = BOSS_RGB[g_iBossType][1], b = BOSS_RGB[g_iBossType][2];

    FxLava(o);
    FxRingEx(o, r, g, b, 800, 50, 7);
    FxSkyStrike(o, r, g, b);
    FxSkyStrike(o, 255, 255, 255);
    FxFunnel(o, g_sprFlare, true);

    if (g_iBossPhase == 3)
    {
        g_bEnraged = true;
        rg_reset_maxspeed(g_iBoss);
        HudAll(SL_ALERT, CLR_DANGER, 3.0, "BOSS_ENRAGE");
        FadeAll(255, 0, 0, 120, 1.5);
        ShakeAll(15, 2.5, 7);
        PlayKey(0, "BOSS_ENRAGE");
        EmitBossSound("PHASE");
        ApplyRender(g_iBoss);

        for (new p = 1; p <= g_iMax; p++)
        {
            if (is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_FOG))
                SendFog(p, 120, 0, 0, true);
        }
    }
    else
    {
        formatex(key, charsmax(key), "BOSS_PHASE_%d", g_iBossPhase);
        HudAll(SL_ALERT, r, g, b, 3.0, key);
        PlayKey(0, "BOSS_PHASE");
        EmitBossSound("PHASE");
        FadeAll(r / 2, g / 2, b / 2, 70, 1.0);
        ShakeAll(10, 1.5, 5);
    }
}

/* ---------------- Yetenekler ---------------- */

// Yetenek yaricapi (uyari alani icin)
BossAbilityRadius(ability)
{
    static const R1[NUM_BOSSES] = { 480, 750, 500, 560, 300, 460, 0, 0, 750 };
    static const R2[NUM_BOSSES] = { 260, 0, 300, 0, 520, 0, 700, 500, 0 };
    return ability ? R2[g_iBossType] : R1[g_iBossType];
}

// 1.5 sn onceden uyari: renkli alan + halka + yazi
BossTelegraph(ability)
{
    new Float:o[3], key[20];
    get_entvar(g_iBoss, var_origin, o);

    new r = BOSS_RGB[g_iBossType][0], g = BOSS_RGB[g_iBossType][1], b = BOSS_RGB[g_iBossType][2];

    formatex(key, charsmax(key), ability ? "BOSS_WARN2_%d" : "BOSS_WARN_%d", g_iBossType);
    HudAll(SL_ALERT, CLR_WARN, 1.5, key);

    new radius = BossAbilityRadius(ability);
    if (radius > 0)
    {
        // Herkesin (T ve CT) kesin gordugu yer isareti; bossu takip eder
        ZoneSpawn(o, float(radius), r, g, b, g_bEnraged ? 1.2 : 1.5, g_iBoss, false);
        new Float:feet[3];
        feet = o;
        feet[2] -= 30.0;
        g_bFxReliable = true;
        FxRingEx(feet, 255, 30, 30, radius, 8, 15);
        g_bFxReliable = false;
    }
    FxRing(o, 255, 0, 0, 150);
    FxImplosion(o, 200, 40, 10);
    PlayKey(0, "BOSS_WARN");
    EmitBossSound("ATTACK");

    new params[1];
    params[0] = ability;
    set_task(g_bEnraged ? 1.2 : 1.5, "task_BossCast", TASK_BOSSCAST, params, 1);
}

public task_BossCast(params[])
{
    if (!g_iBoss || !is_user_alive(g_iBoss) || !g_bRoundActive)
        return;

    new Float:bo[3], key[20];
    get_entvar(g_iBoss, var_origin, bo);

    formatex(key, charsmax(key), params[0] ? "BOSS_ABIL2_%d" : "BOSS_ABIL_%d", g_iBossType);
    HudAll(SL_ALERT, BOSS_RGB[g_iBossType][0], BOSS_RGB[g_iBossType][1], BOSS_RGB[g_iBossType][2], 2.0, key);
    PlayBossSound("ABILITY");

    if (!params[0])
    {
        switch (g_iBossType)
        {
            case 0: BossSlam(bo);
            case 1: BossScream(bo);
            case 2: BossSummon(bo);
            case 3: BossInferno(bo);
            case 4: BossReaper(bo);
            case 5: BossFrostNova(bo);
            case 6: BossThunder();
            case 7: BossAcidPools();
            case 8: BossGravityWell(bo);
        }
    }
    else
    {
        switch (g_iBossType)
        {
            case 0: BossCharge();
            case 1: BossWail();
            case 2: BossDarkShield(bo);
            case 3: BossMeteorRain();
            case 4: BossHarvest(bo);
            case 5: BossBlizzard();
            case 6: BossChain(bo);
            case 7: BossBrood(bo);
            case 8: BossEclipse(bo);
        }
    }
}

// Yaricap icindeki insanlara hasar + sarsinti + renk
BossAoE(const Float:c[3], Float:radius, Float:dmg, r, g, b, Float:up = 0.0)
{
    new Float:po[3], Float:vel[3], hits;
    // v3.0 (C): bossun elementine gore patlama sprite'i
    FxBossElement(c, radius);
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || g_bZombie[id])
            continue;

        get_entvar(id, var_origin, po);
        if (get_distance_f(c, po) > radius)
            continue;

        if (up > 0.0)
        {
            get_entvar(id, var_velocity, vel);
            vel[2] = up;
            set_entvar(id, var_velocity, vel);
        }

        ShakeOne(id);
        FadeOne(id, r, g, b, 110, 0.8);
        BossHurt(id, dmg, DMG_BLAST);
        hits++;
    }
    return hits;
}

// 0 BRUTE: Yer darbesi
BossSlam(const Float:bo[3])
{
    PlayKey(0, "BOSS_SLAM");
    FxLava(bo);
    FxRing(bo, 255, 60, 0, 480);
    FxRing(bo, 255, 160, 0, 320);
    FxRing(bo, 255, 255, 0, 160);
    FxExplosion(bo);
    FxLight(bo, 255, 60, 0, 45, 10, 30);
    ShakeAll(12, 1.5, 6);
    BossAoE(bo, 480.0, 35.0, 255, 60, 0, 420.0);
}

// 1 BANSHEE: Sagir eden ciglik
BossScream(const Float:bo[3])
{
    EmitBossSound("SCREAM");
    FxRing(bo, 220, 220, 255, 750);
    FxRing(bo, 160, 160, 255, 500);
    FxImplosion(bo, 255, 60, 8);
    FxLight(bo, 200, 200, 255, 45, 10, 30);

    new Float:po[3], Float:now = get_gametime();
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || g_bZombie[id])
            continue;
        get_entvar(id, var_origin, po);
        if (get_distance_f(bo, po) > 750.0)
            continue;

        ShakeOne(id);
        FadeOne(id, 255, 255, 255, 255, 3.0);
        g_fSlow[id] = now + 3.0;
        rg_reset_maxspeed(id);
        BossHurt(id, 12.0, DMG_SONIC);
    }
}

// 2 OVERLORD: Olu cagirma + kendini iyilestirme
BossSummon(const Float:bo[3])
{
    PlayKey(0, "BOSS_SUMMON");
    FxTeleport(bo);
    FxRing(bo, 150, 0, 200, 500);
    FxLight(bo, 150, 0, 200, 45, 10, 30);
    FxFunnel(bo, g_sprFlare, true);

    SummonMinions(3);
    HealTo(g_iBoss, g_iBossMaxHP / 20, g_iBossMaxHP);
}

SummonMinions(maxCount)
{
    new c;
    for (new id = 1; id <= g_iMax && c < maxCount; id++)
    {
        if (!is_user_connected(id) || is_user_alive(id))
            continue;
        new TeamName:t = get_member(id, m_iTeam);
        if (t != TEAM_CT && t != TEAM_TERRORIST)
            continue;

        g_bForceZombie[id] = 1;
        g_bMinion[id] = 1;
        rg_set_user_team(id, TEAM_TERRORIST, MODEL_UNASSIGNED, true, false);
        rg_round_respawn(id);
        c++;
    }
    return c;
}

// 3 INFERNO: Ates dalgasi
BossInferno(const Float:bo[3])
{
    PlayKey(0, "BOSS_SLAM");
    FxLava(bo);
    FxRing(bo, 255, 120, 0, 560);
    FxRing(bo, 255, 40, 0, 360);
    FxExplosion(bo);
    FxLight(bo, 255, 120, 0, 50, 12, 25);

    new Float:po[3];
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || g_bZombie[id])
            continue;
        get_entvar(id, var_origin, po);
        if (get_distance_f(bo, po) > 560.0)
            continue;

        g_iBurn[id] = 6;
        g_iBurnBy[id] = g_iBoss;
        ShakeOne(id);
        FadeOne(id, 255, 120, 0, 120, 1.0);
        BossHurt(id, 20.0, DMG_BURN);
    }
}

// 4 REAPER: Kurbana isinlanma
BossReaper(const Float:bo[3])
{
    new alive[32], n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_alive(id) && !g_bZombie[id])
            alive[n++] = id;
    }
    if (!n)
        return;

    new target = alive[random(n)];
    new Float:dest[3], Float:test[3];
    get_entvar(target, var_origin, dest);

    FxTeleport(bo);
    FxRing(bo, 120, 0, 200, 300);

    test = dest;
    test[0] += 70.0;
    test[2] += 20.0;
    if (IsHullFree(g_iBoss, test))
        engfunc(EngFunc_SetOrigin, g_iBoss, test);
    else
    {
        test[0] -= 140.0;
        if (IsHullFree(g_iBoss, test))
            engfunc(EngFunc_SetOrigin, g_iBoss, test);
    }

    EmitBossSound("SCREAM");
    FxTeleport(dest);
    FxRing(dest, 120, 0, 200, 350);
    FxLight(dest, 150, 0, 200, 45, 12, 25);
    BossAoE(dest, 300.0, 45.0, 120, 0, 200);

    new Float:now = get_gametime(), Float:po[3];
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || g_bZombie[id])
            continue;
        get_entvar(id, var_origin, po);
        if (get_distance_f(dest, po) <= 300.0)
        {
            g_fSlow[id] = now + 2.0;
            rg_reset_maxspeed(id);
        }
    }
}

// 5 FROSTLORD: Buz patlamasi - yakindaki herkes donar
BossFrostNova(const Float:bo[3])
{
    PlayKey(0, "FROST_NOVA");
    FxRingEx(bo, 0, 190, 255, 520, 40, 7);
    FxRingEx(bo, 220, 240, 255, 340, 20, 6);
    FxDisk(bo, 0, 150, 255, 460, 6);
    FxStreak(bo, 7, 150, 450);
    FxLight(bo, 0, 190, 255, 55, 12, 20);

    new Float:po[3], Float:now = get_gametime();
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || g_bZombie[id])
            continue;
        get_entvar(id, var_origin, po);
        if (get_distance_f(bo, po) > 460.0)
            continue;

        g_fFrozen[id] = now + 1.8;
        set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
        rg_reset_maxspeed(id);
        ApplyRender(id);
        FadeOne(id, 0, 150, 255, 150, 1.8);
        FxStreak(po, 7, 40, 200);
        BossHurt(id, 18.0, DMG_FREEZE);
    }
}

// 5 FROSTLORD: Kar firtinasi - 6 sn tum harita yavaslar ve donar
BossBlizzard()
{
    g_fBlizzardEnd = get_gametime() + 6.0;
    PlayKey(0, "FROST_NOVA");
    PlayKey(0, "THUNDER");

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
            continue;
        if (!is_user_bot(id) && !(g_iSet[id] & SET_NO_FOG))
            SendFog(id, 210, 225, 255, true);
        if (is_user_alive(id) && !g_bZombie[id])
        {
            rg_reset_maxspeed(id);
            FadeOne(id, 200, 230, 255, 120, 2.0);
            ShakeOne(id);
        }
    }
}

EndBlizzard()
{
    g_fBlizzardEnd = 0.0;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
            continue;
        SendFogForEvent(id);
        if (is_user_alive(id))
            rg_reset_maxspeed(id);
    }
}

// 6 STORMCALLER: Yildirim yagmuru - insanlarin oldugu yere isaretli simsekler
BossThunder()
{
    new alive[32], n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_alive(id) && !g_bZombie[id])
            alive[n++] = id;
    }

    for (new i = 0; i < 4 && n > 0; i++)
    {
        new pick = random(n);
        new Float:o[3];
        get_entvar(alive[pick], var_origin, o);
        alive[pick] = alive[n - 1];
        n--;

        ZoneSpawn(o, 170.0, 255, 240, 80, 1.2 + 0.25 * float(i), 0, i == 0);
        o[2] -= 30.0;

        new params[3];
        params[0] = _:o[0];
        params[1] = _:o[1];
        params[2] = _:o[2];
        set_task(1.2 + 0.25 * float(i), "task_ThunderHit", TASK_BOSSHIT + 10 + i, params, 3);
    }
}

public task_ThunderHit(params[])
{
    if (!g_bRoundActive)
        return;

    new Float:o[3];
    o[0] = Float:params[0];
    o[1] = Float:params[1];
    o[2] = Float:params[2];

    FxSkyStrike(o, 255, 255, 120);
    FxSkyStrike(o, 255, 255, 255);
    FxRingEx(o, 255, 240, 80, 260, 20, 5);
    FxStreak(o, 5, 60, 300);
    PlayKey(0, "THUNDER");

    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !(g_iSet[p] & SET_NO_FX))
            FadeOne(p, 255, 255, 255, 60, 0.2);
    }

    new Float:po[3], Float:now = get_gametime();
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || g_bZombie[id])
            continue;
        get_entvar(id, var_origin, po);
        if (get_distance_f(o, po) > 180.0)
            continue;
        ShakeEx(id, 12, 1.0, 6);
        g_fSlow[id] = now + 1.0;
        rg_reset_maxspeed(id);
        BossHurt(id, 40.0, DMG_SHOCK);
    }
}

// 6 STORMCALLER: Zincir simsek - yakindaki herkese ayni anda
BossChain(const Float:bo[3])
{
    new Float:po[3], Float:now = get_gametime();
    PlayKey(0, "THUNDER");

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || g_bZombie[id])
            continue;
        get_entvar(id, var_origin, po);
        if (get_distance_f(bo, po) > 700.0)
            continue;

        // Duvar arkasindakilere gecmez
        engfunc(EngFunc_TraceLine, bo, po, IGNORE_MONSTERS, g_iBoss, 0);
        new Float:frac;
        get_tr2(0, TR_flFraction, frac);
        if (frac < 1.0)
            continue;

        FxBeamEntPoint(g_iBoss, po, g_sprLightning, 255, 240, 80, 45, 70, 6);
        FxSparks(po);
        FadeOne(id, 255, 250, 150, 120, 0.6);
        g_fSlow[id] = now + 1.3;
        rg_reset_maxspeed(id);
        BossHurt(id, 18.0, DMG_SHOCK);
        EmitKey(id, "ZAP");
    }
    FxRingEx(bo, 255, 240, 80, 700, 20, 5);
}

// 7 HIVE QUEEN: Asit havuzlari - 7 sn yerde kalir, icindekiler erir
BossAcidPools()
{
    new alive[32], n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_alive(id) && !g_bZombie[id])
            alive[n++] = id;
    }

    new Float:now = get_gametime();
    for (new i = 0; i < 3 && n > 0; i++)
    {
        new pick = random(n);
        new Float:o[3];
        get_entvar(alive[pick], var_origin, o);
        alive[pick] = alive[n - 1];
        n--;

        AddPool(o, 0, 8.0, 150.0);
        FxSprite(o, g_sprSmoke, 20, 180);
    }
    PlayKey(0, "ACID_POOL");
    #pragma unused now
}

// Havuzlar: her saniye; icindeki insan hasar alir. Asitte zombi iyilesir, yanan zeminde insan tutusur.
// (Gorunum: ZoneSpawn varligi - herkes gorur)
TickPools()
{
    new Float:now = get_gametime(), Float:po[3];
    for (new s = 0; s < sizeof g_fPoolEnd; s++)
    {
        if (g_fPoolEnd[s] < now)
            continue;

        new Float:rad = (g_fPoolRad[s] > 0.0) ? g_fPoolRad[s] : 150.0;
        new bool:fire = (g_iPoolType[s] == 1 || g_iPoolType[s] == 2) ? true : false;
        if (g_iFrame % 2 == 0)
        {
            if (fire)
                FxSprite(g_fPoolPos[s], g_sprFire ? g_sprFire : g_sprExplode, (g_iPoolType[s] == 2) ? 4 : 6, 180);
            else
                FxSprite(g_fPoolPos[s], g_sprSmoke, 12, 140);
        }
        // Magma lav havuzu: hasar LavaDamage'da (0.5 sn, sahibi magma zombisi)
        if (g_iPoolType[s] == 2)
            continue;

        for (new id = 1; id <= g_iMax; id++)
        {
            if (!is_user_alive(id))
                continue;
            get_entvar(id, var_origin, po);
            if (get_distance_f(g_fPoolPos[s], po) > rad + 10.0)
                continue;
            if (g_bZombie[id])
            {
                if (!fire)
                    HealTo(id, 60, g_iMaxHP[id]);
            }
            else if (fire)
            {
                BurnHuman(id, 2);
                FadeOne(id, 255, 90, 0, 90, 0.8);
                BossHurt(id, 8.0, DMG_BURN);
            }
            else
            {
                g_fSlow[id] = now + 1.1;
                rg_reset_maxspeed(id);
                FadeOne(id, 110, 255, 0, 90, 0.8);
                BossHurt(id, 10.0, DMG_ACID);
            }
        }
    }
}

// 7 HIVE QUEEN: Kulucka - yardimcilar + zehirli bulut, kendini iyilestirir
BossBrood(const Float:bo[3])
{
    EmitBossSound("SCREAM");
    FxSprite(bo, g_sprSmoke, 40, 200);
    FxRingEx(bo, 110, 255, 0, 500, 30, 6);
    FxImplosion(bo, 250, 60, 8);

    SummonMinions(2);
    HealTo(g_iBoss, g_iBossMaxHP / 25, g_iBossMaxHP);

    new Float:po[3];
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || g_bZombie[id])
            continue;
        get_entvar(id, var_origin, po);
        if (get_distance_f(bo, po) > 500.0)
            continue;
        g_iPoison[id] = max(g_iPoison[id], 5);
        g_iPoisonBy[id] = g_iBoss;
        FadeOne(id, 110, 255, 0, 120, 1.0);
    }
}

// 8 VOID: Yercekimi kuyusu - herkesi kendine ceker, sonra patlar
BossGravityWell(const Float:bo[3])
{
    g_fBossFxPos = bo;
    g_iBossFxStep = 0;
    PlayKey(0, "GRAVITY_WELL");
    FxFunnel(bo, g_sprFlare, false);
    FxDisk(bo, 220, 0, 140, 260, 18);
    set_task(0.1, "task_GravityPull", TASK_BOSSFX, _, _, "a", 16);
}

public task_GravityPull()
{
    if (!g_iBoss || !is_user_alive(g_iBoss) || !g_bRoundActive)
    {
        remove_task(TASK_BOSSFX);
        return;
    }

    new Float:c[3], Float:po[3], Float:vel[3];
    c = g_fBossFxPos;
    g_iBossFxStep++;

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || g_bZombie[id])
            continue;
        get_entvar(id, var_origin, po);
        new Float:d = get_distance_f(c, po);
        if (d > 750.0 || d < 30.0)
            continue;

        vel[0] = (c[0] - po[0]) / d * 360.0;
        vel[1] = (c[1] - po[1]) / d * 360.0;
        vel[2] = 40.0;
        set_entvar(id, var_velocity, vel);

        if (g_iBossFxStep % 4 == 0)
            FxBeamEx(po, c, g_sprLightning, 220, 0, 140, 20, 40, 4);
    }

    if (g_iBossFxStep % 5 == 0)
        FxImplosion(c, 255, 60, 6);

    if (g_iBossFxStep >= 16)
    {
        FxExplosion(c);
        FxRingEx(c, 220, 0, 140, 420, 50, 6);
        FxRingEx(c, 255, 255, 255, 260, 20, 5);
        FxLava(c);
        ShakeAll(12, 1.5, 6);
        BossAoE(c, 280.0, 40.0, 220, 0, 140, 380.0);
    }
}

// 8 VOID: Tutulma - isiklar soner, boss yari gorunmez ve hizlanir
BossEclipse(const Float:bo[3])
{
    g_fEclipseEnd = get_gametime() + 7.0;
    PlayKey(0, "ECLIPSE");
    FxFunnel(bo, g_sprFlare, true);

    engfunc(EngFunc_LightStyle, 0, "a");
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
            continue;
        if (!is_user_bot(id) && !(g_iSet[id] & SET_NO_FOG))
            SendFog(id, 0, 0, 0, true);
        FadeOne(id, 0, 0, 0, 220, 1.5);
    }
    ApplyRender(g_iBoss);
    rg_reset_maxspeed(g_iBoss);
}

EndEclipse()
{
    g_fEclipseEnd = 0.0;
    engfunc(EngFunc_LightStyle, 0, g_szLight);
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id))
            SendFogForEvent(id);
    }
    if (g_iBoss && is_user_alive(g_iBoss))
    {
        ApplyRender(g_iBoss);
        rg_reset_maxspeed(g_iBoss);
    }
}

/* ---------------- Ikinci yetenekler (faz 2+) ---------------- */

// BRUTE: Hucum - ileri atilir, vardigi yerde carpar
BossCharge()
{
    LeapForward(g_iBoss, 1100.0, 180.0);
    FxFollow(g_iBoss, 255, 160, 0, 10, 20);
    EmitBossSound("ATTACK");
    set_task(0.5, "task_BruteImpact", TASK_BOSSHIT);
}

public task_BruteImpact()
{
    if (!g_iBoss || !is_user_alive(g_iBoss))
        return;

    new Float:o[3];
    get_entvar(g_iBoss, var_origin, o);
    FxLava(o);
    FxRing(o, 255, 160, 0, 260);
    FxExplosion(o);
    ShakeAll(8, 1.0, 5);
    BossAoE(o, 260.0, 40.0, 255, 160, 0, 300.0);
}

// BANSHEE: Feryat - haritadaki herkes etkilenir
BossWail()
{
    new Float:now = get_gametime();
    EmitBossSound("SCREAM");

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || g_bZombie[id])
            continue;

        FadeOne(id, 230, 230, 255, 220, 1.5);
        ShakeOne(id);
        g_fSlow[id] = now + 2.0;
        rg_reset_maxspeed(id);
        BossHurt(id, 8.0, DMG_SONIC);
    }
}

// OVERLORD: Karanlik kalkan - %8 can + 4 sn %60 hasar azaltma
BossDarkShield(const Float:bo[3])
{
    HealTo(g_iBoss, g_iBossMaxHP * 8 / 100, g_iBossMaxHP);
    g_fShield[g_iBoss] = get_gametime() + 4.0;
    set_user_rendering(g_iBoss, kRenderFxGlowShell, 150, 0, 255, kRenderNormal, 40);

    FxTeleport(bo);
    FxRing(bo, 150, 0, 255, 300);
    FxRing(bo, 200, 100, 255, 180);
    FxImplosion(bo, 180, 50, 10);
    PlayKey(0, "BOSS_SUMMON");
}

// INFERNO: Meteor yagmuru - 3 insanin uzerine
BossMeteorRain()
{
    new alive[32], n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_alive(id) && !g_bZombie[id])
            alive[n++] = id;
    }

    for (new i = 0; i < 3 && n > 0; i++)
    {
        new pick = random(n);
        new Float:o[3];
        get_entvar(alive[pick], var_origin, o);
        alive[pick] = alive[n - 1];
        n--;

        ZoneSpawn(o, 200.0, 255, 80, 0, 1.2 + 0.2 * float(i), 0, i == 0);
        FxLight(o, 255, 60, 0, 30, 15, 5);

        new params[4];
        params[0] = _:o[0];
        params[1] = _:o[1];
        params[2] = _:o[2];
        params[3] = 1;
        set_task(1.2 + 0.2 * float(i), "task_MeteorHit", TASK_METEOR + 50 + i, params, 4);
    }
}

// REAPER: Ruh hasadi - yakindaki insanlardan can emer
BossHarvest(const Float:bo[3])
{
    new Float:po[3], total;
    EmitBossSound("SCREAM");
    FxImplosion(bo, 255, 80, 12);

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id) || g_bZombie[id])
            continue;
        get_entvar(id, var_origin, po);
        if (get_distance_f(bo, po) > 520.0)
            continue;

        FxBeam(po, bo, g_sprLightning, 120, 0, 200, 25);
        FadeOne(id, 120, 0, 200, 120, 1.0);
        BossHurt(id, 15.0, DMG_GENERIC);
        total += 15;
    }

    if (total)
        HealTo(g_iBoss, total * 12, g_iBossMaxHP);
}

/* ---------------- Boss olumu ---------------- */

BossDeath(victim, const Float:o[3], const killer[])
{
    new type = g_iBossType;
    new r = BOSS_RGB[type][0], g = BOSS_RGB[type][1], b = BOSS_RGB[type][2];

    BossCleanup();
    g_iBoss = 0;
    g_fBossIntro = 0.0;
    remove_task(TASK_BOSSCAST);
    remove_task(TASK_BOSSHIT);
    remove_task(TASK_BOSSFX);
    remove_task(TASK_INTRO);
    remove_task(TASK_INTRO + 1);
    for (new i = 0; i < 4; i++)
        remove_task(TASK_BOSSHIT + 10 + i);
    for (new s = 0; s < sizeof g_fPoolEnd; s++)
        g_fPoolEnd[s] = 0.0;

    if (g_fEclipseEnd > 0.0)
        EndEclipse();
    if (g_fBlizzardEnd > 0.0)
        EndBlizzard();

    ChatAllS("BOSS_DOWN", killer);
    HudAll(SL_ANN, CLR_GOOD, 4.0, "BOSS_DOWN_HUD");
    PlayBossSound("DEATH");
    PlayVoxAll("VOX_BOSSDOWN");

    // Olum sahnesi: arka arkaya patlamalar
    FxLava(o);
    FxTeleport(o);
    FxSkyStrike(o, r, g, b);
    FxSkyStrike(o, 255, 255, 255);
    FxFunnel(o, g_sprFlare, true);
    FxRingEx(o, r, g, b, 900, 60, 8);
    FxBlood(o, 25);
    FadeAll(r, g, b, 110, 1.5);
    ShakeAll(15, 3.0, 8);

    new params[3];
    params[0] = _:o[0];
    params[1] = _:o[1];
    params[2] = _:o[2];
    set_task(0.4, "task_BossBoom", TASK_BOSSHIT + 20, params, 3);
    set_task(0.8, "task_BossBoom", TASK_BOSSHIT + 21, params, 3);
    set_task(1.3, "task_BossBoom", TASK_BOSSHIT + 22, params, 3);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p))
            SendFogForEvent(p);
    }

    BossDamageBoard();

    // Boss olunce yardimcilari da olur
    for (new p = 1; p <= g_iMax; p++)
    {
        if (p != victim && g_bMinion[p] && is_user_alive(p))
            user_kill(p, 1);
    }
}

public task_BossBoom(params[])
{
    new Float:o[3];
    o[0] = Float:params[0] + random_float(-80.0, 80.0);
    o[1] = Float:params[1] + random_float(-80.0, 80.0);
    o[2] = Float:params[2];
    FxExplosion(o);
    FxSparks(o);
    FxRing(o, 255, 255, 255, 220);
}

/* ---------------- Boss olunce: hasar tablosu ---------------- */

BossDamageBoard()
{
    new ids[3], dmg[3];
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || g_iBossDmg[p] <= 0)
            continue;
        for (new r = 0; r < 3; r++)
        {
            if (g_iBossDmg[p] > dmg[r])
            {
                for (new s = 2; s > r; s--)
                {
                    ids[s] = ids[s - 1];
                    dmg[s] = dmg[s - 1];
                }
                ids[r] = p;
                dmg[r] = g_iBossDmg[p];
                break;
            }
        }
    }

    if (!ids[0])
        return;

    new PRIZE[3] = { 40, 25, 15 }, pz[32], a1[8], a2[8], a3[8];
    get_pcvar_string(g_pBossBoard, pz, charsmax(pz));
    if (parse(pz, a1, charsmax(a1), a2, charsmax(a2), a3, charsmax(a3)) >= 3)
    {
        PRIZE[0] = str_to_num(a1);
        PRIZE[1] = str_to_num(a2);
        PRIZE[2] = str_to_num(a3);
    }
    ChatAll("BOSS_BOARD_TITLE");

    new name[32], names[3][32];
    for (new r = 0; r < 3; r++)
    {
        if (!ids[r])
            break;
        get_user_name(ids[r], name, charsmax(name));
        copy(names[r], 18, name);
        AddAP(ids[r], PRIZE[r], false, false);
        if (r == 0)
            g_iVC[ids[r]] += 2;

        for (new p = 1; p <= g_iMax; p++)
        {
            if (is_user_connected(p) && !is_user_bot(p))
                client_print_color(p, ids[r], "%s %L", ChatTag("BOSS_BOARD_LINE"), p, "BOSS_BOARD_LINE", r + 1, name, dmg[r], PRIZE[r]);
        }
    }

    // Ekranda buyuk hasar tablosu
    new txt[128];
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        formatex(txt, charsmax(txt), "%L", p, "BOSS_BOARD_HUD");
        for (new r = 0; r < 3 && ids[r]; r++)
            format(txt, charsmax(txt), "%s^n#%d  %s  -  %d", txt, r + 1, names[r], dmg[r]);
        HudText(p, SL_ALERT, CLR_REWARD, 4.5, txt);
    }
}

// Bilgi: /boss
public cmd_bossinfo(id)
{
    new key[20];
    Chat(id, "BOSSINFO_TITLE");
    // v3.0: sadece bu haritada gelebilecek (yuklenen) bosslar
    for (new b = 0; b < NUM_BOSSES; b++)
    {
        if (g_iBossLoadN > 0 && !BossIsLoaded(b))
            continue;
        formatex(key, charsmax(key), "BOSS_INFO_%d", b);
        Chat(id, key);
    }
    new left = RoundsToBoss();
    if (left > 0)
        Chat(id, "BOSS_NEXT_IN", left);
    return PLUGIN_HANDLED;
}


/* ================================================================== */
/*  v2.0  BOSS [R] YETENEKLERI - FAZA GORE DEGISIR                      */
/*                                                                      */
/*  Her bossun 3 R yetenegi vardir (toplam 27):                         */
/*    Faz 1 (%100-60)  : R = 1. yetenek                                 */
/*    Faz 2 (%60-30)   : R = 2. yetenek  (1. yetenek otomatik saldiri)  */
/*    Faz 3 (DELILIK)  : R = 3. yetenek (ULTI) (1 ve 2 otomatik)        */
/*  [F] (fener tusu) = atilma. Boss R'ye uzun sure basmazsa (veya bot   */
/*  ise) yetenek kendiliginden kullanilir (vex_boss_r_auto).            */
/*  Her yetenek: renkli alan uyarisi (herkes gorur) + ozel ses + efekt  */
/*  vexmira.cfg: vex_boss_skill <boss> <faz> <bekleme> <hasar> <yaricap>*/
/* ================================================================== */

/* ---------------- Yardimcilar ---------------- */

Float:BskDmg(ph)
{
    return BSK_DMG[g_iBossType][clamp(ph, 1, 3) - 1] * floatmax(0.0, get_pcvar_float(g_pBossRDmgMult));
}

Float:BskRad(ph)
{
    return float(BSK_RAD[g_iBossType][clamp(ph, 1, 3) - 1]);
}

BossEye(Float:eye[3])
{
    new Float:ofs[3];
    get_entvar(g_iBoss, var_origin, eye);
    get_entvar(g_iBoss, var_view_ofs, ofs);
    eye[0] += ofs[0];
    eye[1] += ofs[1];
    eye[2] += ofs[2];
}

BossFwd(Float:fwd[3], bool:flat)
{
    new Float:ang[3];
    get_entvar(g_iBoss, var_v_angle, ang);
    if (flat)
        ang[0] = 0.0;
    engfunc(EngFunc_MakeVectors, ang);
    global_get(glb_v_forward, fwd);
}

// Bossun baktigi nokta (duvar / zemin)
BossAimPoint(Float:range, Float:out[3])
{
    new Float:eye[3], Float:fwd[3], Float:end[3];
    BossEye(eye);
    BossFwd(fwd, false);
    for (new i = 0; i < 3; i++)
        end[i] = eye[i] + fwd[i] * range;
    engfunc(EngFunc_TraceLine, eye, end, IGNORE_MONSTERS, g_iBoss, 0);
    get_tr2(0, TR_vecEndPos, out);
}

bool:BossSees(const Float:a[3], p)
{
    new Float:po[3];
    get_entvar(p, var_origin, po);
    engfunc(EngFunc_TraceLine, a, po, IGNORE_MONSTERS, g_iBoss, 0);
    new Float:frac;
    get_tr2(0, TR_flFraction, frac);
    return (frac >= 0.98) ? true : false;
}

// Nisan alinan insan (koni icinde, gorus hattinda); yoksa menzildeki en yakin
BossPickHuman(Float:range, Float:minDot)
{
    new Float:eye[3], Float:fwd[3], Float:po[3];
    BossEye(eye);
    BossFwd(fwd, false);

    new best, Float:bestDot = minDot, nearest, Float:nd = range;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        new Float:d = get_distance_f(eye, po);
        if (d > range || d < 1.0 || !BossSees(eye, p))
            continue;
        new Float:dot = ((po[0] - eye[0]) * fwd[0] + (po[1] - eye[1]) * fwd[1] + (po[2] - eye[2]) * fwd[2]) / d;
        if (dot > bestDot)
        {
            bestDot = dot;
            best = p;
        }
        if (d < nd)
        {
            nd = d;
            nearest = p;
        }
    }
    return best ? best : nearest;
}

bool:HumanInRange(Float:range)
{
    new Float:bo[3], Float:po[3];
    get_entvar(g_iBoss, var_origin, bo);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(bo, po) <= range)
            return true;
    }
    return false;
}

// Gecikmeli vurus: params = { boss seri no, x, y, z, ek }
BskTask(Float:delay, const func[], const Float:o[3], extra = 0)
{
    new params[5];
    params[0] = g_iBossSerial;
    params[1] = _:o[0];
    params[2] = _:o[1];
    params[3] = _:o[2];
    params[4] = extra;
    g_iBskSlot = (g_iBskSlot + 1) % 250;
    set_task(delay, func, TASK_BSK + g_iBskSlot, params, sizeof params);
}

bool:BskValid(const params[])
{
    return (params[0] == g_iBossSerial && g_iBoss && is_user_alive(g_iBoss) && g_bRoundActive && !g_bRoundEnded) ? true : false;
}

BskPos(const params[], Float:o[3])
{
    o[0] = Float:params[1];
    o[1] = Float:params[2];
    o[2] = Float:params[3];
}

// Insani bir noktadan uzaga savur
PushFrom(p, const Float:c[3], Float:force, Float:up)
{
    new Float:po[3], Float:vel[3];
    get_entvar(p, var_origin, po);
    new Float:dx = po[0] - c[0], Float:dy = po[1] - c[1];
    new Float:len = floatsqroot(dx * dx + dy * dy);
    if (len < 1.0)
    {
        dx = 1.0;
        dy = 0.0;
        len = 1.0;
    }
    get_entvar(p, var_velocity, vel);
    vel[0] = dx / len * force;
    vel[1] = dy / len * force;
    vel[2] = up;
    set_entvar(p, var_velocity, vel);
    if (g_iDirLogN[DIR_PUSH] < DIR_LOG_MAX && get_pcvar_num(g_pDbgDirs))
    {
        new Float:hv[3], Float:away[3];
        hv[0] = vel[0]; hv[1] = vel[1];
        away[0] = dx; away[1] = dy;
        DirCheck(DIR_PUSH, force >= 0.0 ? "boss_push" : "boss_pushin", hv, away);
    }
}

// Insani bir noktaya dogru cek (hiz ekler)
PullTo(p, const Float:c[3], Float:force)
{
    new Float:po[3], Float:vel[3];
    get_entvar(p, var_origin, po);
    new Float:d = get_distance_f(c, po);
    if (d < 24.0)
        return;
    get_entvar(p, var_velocity, vel);
    if (g_iDirLogN[DIR_DRAW] < DIR_LOG_MAX && get_pcvar_num(g_pDbgDirs))
    {
        new Float:add[3], Float:to[3];
        add[0] = (c[0] - po[0]) / d * force; add[1] = (c[1] - po[1]) / d * force;
        to[0] = c[0] - po[0]; to[1] = c[1] - po[1];
        DirCheck(DIR_DRAW, "boss_pull", add, to);
    }
    vel[0] += (c[0] - po[0]) / d * force;
    vel[1] += (c[1] - po[1]) / d * force;
    new Float:sp = floatsqroot(vel[0] * vel[0] + vel[1] * vel[1]);
    if (sp > 520.0)
    {
        vel[0] = vel[0] / sp * 520.0;
        vel[1] = vel[1] / sp * 520.0;
    }
    set_entvar(p, var_velocity, vel);
}

SlowHuman(p, Float:dur)
{
    new Float:t = get_gametime() + dur;
    if (g_fSlow[p] < t)
        g_fSlow[p] = t;
    rg_reset_maxspeed(p);
}

RootHuman(p, Float:dur)
{
    g_fFrozen[p] = get_gametime() + dur;
    set_entvar(p, var_velocity, Float:{0.0, 0.0, 0.0});
    rg_reset_maxspeed(p);
    ApplyRender(p);
}

// Insana yanma (saniyede vex_burn_damage_human)
BurnHuman(p, ticks)
{
    g_iBurn[p] = max(g_iBurn[p], ticks);
    g_iBurnBy[p] = g_iBoss;
}

// Herkese: "<BOSS> -> <YETENEK>" + kisa ipucu, bossun rengiyle
BskAnnounce(ph)
{
    new key[16], tkey[16], nm[48], tip[64], txt[128];
    formatex(key, charsmax(key), "BSK_%d_%d", g_iBossType, ph);
    formatex(tkey, charsmax(tkey), "BSKT_%d_%d", g_iBossType, ph);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        formatex(nm, charsmax(nm), "%L", p, key);
        formatex(tip, charsmax(tip), "%L", p, tkey);
        formatex(txt, charsmax(txt), "-=[  %s  ]=-^n%s", nm, tip);
        HudText(p, SL_ALERT, BOSS_RGB[g_iBossType][0], BOSS_RGB[g_iBossType][1], BOSS_RGB[g_iBossType][2], 2.2, txt);
    }

    // Yetenek sesi (B<n>_R<faz>): bossun uzerinden, herkes duyar
    formatex(key, charsmax(key), "B%d_R%d", g_iBossType, ph);
    EmitKey(g_iBoss, key, CHAN_STATIC, ATTN_NONE);

    // v3.0 (C): yetenek baslangici: bossun elementine gore sprite (faz arttikca buyur)
    if (g_iBoss && is_user_alive(g_iBoss) && 0 <= g_iBossType < NUM_BOSSES)
    {
        new Float:bo[3];
        get_entvar(g_iBoss, var_origin, bo);
        FxElSmall(bo, BOSS_ELEM[g_iBossType], 8 + clamp(ph, 1, 3) * 3);
    }
}

/* ---------------- R tusu / yapay zeka ---------------- */

public BossUseR(id)
{
    if (id != g_iBoss || !is_user_alive(id))
        return;

    new Float:now = get_gametime();
    if (g_fBossIntro > now)
    {
        SkillDeny(id, "SKILL_BOSS_INTRO", floatround(g_fBossIntro - now, floatround_ceil));
        return;
    }
    if (now < g_fBossRCool)
    {
        SkillDeny(id, "ABILITY_COOL", floatround(g_fBossRCool - now, floatround_ceil));
        return;
    }
    if (g_iBossChannel != CH_NONE)
    {
        SkillDeny(id, "BSK_BUSY");
        return;
    }
    BossCastR(clamp(g_iBossPhase, 1, 3));
}

bool:BossCastR(ph, bool:setCool = true)
{
    new bool:ok;
    switch (g_iBossType * 10 + ph)
    {
        case 1:  ok = Bsk_BruteStomp();
        case 2:  ok = Bsk_BruteShatter();
        case 3:  ok = Bsk_BruteWrath();
        case 11: ok = Bsk_BansheeLance();
        case 12: ok = Bsk_BansheeShriek();
        case 13: ok = Bsk_BansheeRequiem();
        case 21: ok = Bsk_OverlordPrison();
        case 22: ok = Bsk_OverlordLegion();
        case 23: ok = Bsk_OverlordNova();
        case 31: ok = Bsk_InfernoBreath();
        case 32: ok = Bsk_InfernoPillars();
        case 33: ok = Bsk_InfernoNova();
        case 41: ok = Bsk_ReaperStep();
        case 42: ok = Bsk_ReaperChains();
        case 43: ok = Bsk_ReaperMark();
        case 51: ok = Bsk_FrostShards();
        case 52: ok = Bsk_FrostTomb();
        case 53: ok = Bsk_FrostZero();
        case 61: ok = Bsk_StormOrb();
        case 62: ok = Bsk_StormDash();
        case 63: ok = Bsk_StormTempest();
        case 71: ok = Bsk_HiveSpit();
        case 72: ok = Bsk_HiveCloud();
        case 73: ok = Bsk_HiveEggs();
        case 81: ok = Bsk_VoidBolt();
        case 82: ok = Bsk_VoidSingularity();
        case 83: ok = Bsk_VoidHorizon();
    }

    if (!ok)
    {
        if (is_user_connected(g_iBoss) && !is_user_bot(g_iBoss))
        {
            set_hudmessage(CLR_WARN, -1.0, 0.56, 0, 0.0, 1.2, 0.0, 0.0, 4);
            show_hudmessage(g_iBoss, "%L", g_iBoss, "BSK_NO_TARGET");
        }
        return false;
    }

    new Float:now = get_gametime();
    BskAnnounce(ph);
    if (setCool)
    {
        g_fBossRCool = now + BSK_COOL[g_iBossType][ph - 1] * floatmax(0.1, get_pcvar_float(g_pBossRCdMult));
        g_fBossRLast = now;
    }
    return true;
}

// Boss bir sure R kullanmazsa (bot / AFK) ve yakinda insan varsa kendiliginden kullanilir
BossAutoR()
{
    new idle = get_pcvar_num(g_pBossRAuto);
    if (idle <= 0 || g_iBossChannel != CH_NONE)
        return;

    new Float:now = get_gametime();
    if (g_fBossIntro > now || now < g_fBossRCool)
        return;
    if (!is_user_bot(g_iBoss) && now - g_fBossRLast < float(idle))
        return;
    if (!HumanInRange(900.0))
        return;
    BossCastR(clamp(g_iBossPhase, 1, 3));
}

// Faz 2+: onceki fazlarin R yetenekleri de bossun otomatik saldirilarina katilir
bool:BossAutoOldSkill()
{
    if (g_iBossPhase < 2 || g_iBossChannel != CH_NONE || random_num(1, 100) > 40)
        return false;
    new ph = random_num(1, g_iBossPhase - 1);
    // Hedef gerektiren yetenek icin bossu en yakin insana dondur
    new t = BossPickHuman(1200.0, -1.0);
    if (t)
        BossFace(t);
    return BossCastR(ph, false) ? true : false;
}

// Bossun bakis yonunu hedefe cevir (otomatik yetenekler icin)
BossFace(t)
{
    new Float:bo[3], Float:po[3], Float:dir[3], Float:ang[3];
    get_entvar(g_iBoss, var_origin, bo);
    get_entvar(t, var_origin, po);
    for (new i = 0; i < 3; i++)
        dir[i] = po[i] - bo[i];
    engfunc(EngFunc_VecToAngles, dir, ang);
    ang[0] = -ang[0];
    set_entvar(g_iBoss, var_v_angle, ang);
    // Model acisi: yalniz yon (bakis egimi modele verilirse govde one / arkaya yatar)
    ang[0] = 0.0;
    set_entvar(g_iBoss, var_angles, ang);
}

/* ---------------- Kanal (sureli) yetenekler ---------------- */

StartChannel(type, Float:dur)
{
    g_iBossChannel = type;
    g_fBossChannelEnd = get_gametime() + dur;
    g_iBossChannelTick = 0;
    remove_task(TASK_BCHAN);
    set_task(0.1, "task_BossChannel", TASK_BCHAN, _, _, "b");
}

EndChannel(bool:bossAlive)
{
    new type = g_iBossChannel;
    g_iBossChannel = CH_NONE;
    remove_task(TASK_BCHAN);

    switch (type)
    {
        case CH_TITAN:
        {
            g_fBossBuffEnd = 0.0;
            if (bossAlive)
            {
                ApplyRender(g_iBoss);
                rg_reset_maxspeed(g_iBoss);
            }
        }
        case CH_CHAINS:
        {
            for (new i = 0; i < 3; i++)
                g_iBossTethers[i] = 0;
        }
        case CH_ZERO, CH_TEMPEST:
            ApplyEnvAll();
        case CH_SINGULARITY:
        {
            if (bossAlive)
                SingularityCollapse();
        }
        case CH_HORIZON:
        {
            if (bossAlive)
            {
                new Float:bo[3];
                get_entvar(g_iBoss, var_origin, bo);
                FxRingEx(bo, 220, 0, 140, floatround(BskRad(3)), 50, 6);
                FxRingEx(bo, 255, 255, 255, floatround(BskRad(3) * 0.6), 20, 5);
                new Float:po[3];
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p) || g_bZombie[p])
                        continue;
                    get_entvar(p, var_origin, po);
                    if (get_distance_f(bo, po) <= BskRad(3))
                        PushFrom(p, bo, 650.0, 260.0);
                }
                ShakeAll(10, 1.0, 5);
            }
        }
    }
}

public task_BossChannel()
{
    new Float:now = get_gametime();
    new bool:alive = (g_iBoss && is_user_alive(g_iBoss) && g_bRoundActive) ? true : false;
    if (!alive || now >= g_fBossChannelEnd)
    {
        EndChannel(alive);
        return;
    }

    g_iBossChannelTick++;
    new tick = g_iBossChannelTick;
    new Float:bo[3], Float:po[3];
    get_entvar(g_iBoss, var_origin, bo);

    switch (g_iBossChannel)
    {
        case CH_TITAN: // Brute: her saniye sok dalgasi
        {
            if (tick % 10 == 0)
            {
                new Float:rad = BskRad(3);
                new Float:feet[3];
                feet = bo;
                feet[2] -= 30.0;
                FxRingEx(feet, 255, 90, 0, floatround(rad), 24, 4);
                FxLava(bo);
                ShakeAll(4, 0.6, 4);
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p) || g_bZombie[p])
                        continue;
                    get_entvar(p, var_origin, po);
                    if (get_distance_f(bo, po) > rad)
                        continue;
                    PushFrom(p, bo, 520.0, 220.0);
                    BossHurt(p, BskDmg(3), DMG_CRUSH);
                }
            }
            if (tick % 2 == 0)
                FxLight(bo, 255, 80, 0, 40, 3, 30);
        }
        case CH_REQUIEM: // Banshee: her saniye haritaya yayilan feryat
        {
            if (tick % 10 == 0)
            {
                new Float:rad = BskRad(3), hits;
                FxRingEx(bo, 200, 210, 255, floatround(rad * 0.5), 30, 5);
                FxRingEx(bo, 255, 255, 255, floatround(rad * 0.25), 14, 4);
                FxImplosion(bo, 255, 50, 6);
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p) || g_bZombie[p])
                        continue;
                    get_entvar(p, var_origin, po);
                    if (get_distance_f(bo, po) > rad)
                        continue;
                    FadeOne(p, 200, 210, 255, 150, 0.7);
                    ShakeEx(p, 5, 0.6, 6);
                    SlowHuman(p, 1.2);
                    BossHurt(p, BskDmg(3), DMG_SONIC);
                    hits++;
                }
                if (hits)
                    HealTo(g_iBoss, g_iBossMaxHP * hits / 100, g_iBossMaxHP);
            }
        }
        case CH_CHAINS: // Reaper: ruh zincirleri
        {
            if (tick % 5 == 0)
            {
                new Float:rad = BskRad(2) * 1.4, any;
                for (new i = 0; i < 3; i++)
                {
                    new t = g_iBossTethers[i];
                    if (!t)
                        continue;
                    if (!is_user_alive(t) || g_bZombie[t])
                    {
                        g_iBossTethers[i] = 0;
                        continue;
                    }
                    get_entvar(t, var_origin, po);
                    if (get_distance_f(bo, po) > rad)
                    {
                        // Zincir koptu
                        g_iBossTethers[i] = 0;
                        FxSparks(po);
                        Chat(t, "BSK_CHAIN_BROKEN");
                        continue;
                    }
                    any++;
                    BeamEnts(g_iBoss, t, g_sprLightning, 150, 0, 220, 30, 25, 6);
                    SlowHuman(t, 0.7);
                    FadeOne(t, 120, 0, 200, 70, 0.5);
                    BossHurt(t, BskDmg(2), DMG_GENERIC);
                    HealTo(g_iBoss, floatround(BskDmg(2) * 6.0), g_iBossMaxHP);
                }
                if (!any)
                    g_fBossChannelEnd = now;
            }
        }
        case CH_ZERO: // Frostlord: mutlak sifir - duran donar
        {
            if (tick % 20 == 0)
            {
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p) || g_bZombie[p])
                        continue;
                    get_entvar(p, var_origin, po);
                    new Float:vel[3];
                    get_entvar(p, var_velocity, vel);
                    FxStreak(po, 7, 25, 160);
                    if (vel[0] * vel[0] + vel[1] * vel[1] < 1600.0)
                    {
                        RootHuman(p, 1.0);
                        FadeOne(p, 150, 210, 255, 160, 1.0);
                        BossHurt(p, BskDmg(3) * 1.5, DMG_FREEZE);
                    }
                    else
                        BossHurt(p, BskDmg(3) * 0.5, DMG_FREEZE);
                }
            }
        }
        case CH_DASH: // Stormcaller: yildirim atilmasi
        {
            static Float:last[3];
            if (tick == 1)
                last = bo;
            FxBeamEx(last, bo, g_sprLightning, 255, 240, 80, 40, 40, 8);
            last = bo;
            new Float:rad = BskRad(2);
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_alive(p) || g_bZombie[p] || (g_iDashHit & (1 << (p - 1))))
                    continue;
                get_entvar(p, var_origin, po);
                if (get_distance_f(bo, po) > rad)
                    continue;
                g_iDashHit |= (1 << (p - 1));
                FxBeamEntPoint(g_iBoss, po, g_sprLightning, 255, 255, 120, 30, 60, 3);
                ShakeEx(p, 10, 0.8, 6);
                FadeOne(p, 255, 250, 150, 120, 0.4);
                SlowHuman(p, 1.2);
                BossHurt(p, BskDmg(2), DMG_SHOCK);
                EmitKey(p, "ZAP");
            }
        }
        case CH_TEMPEST: // Stormcaller: firtina - rastgele insanlara isaretli yildirim
        {
            if (tick % 7 == 1)
            {
                new list[32], n;
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (is_user_alive(p) && !g_bZombie[p])
                        list[n++] = p;
                }
                if (n)
                {
                    new t = list[random(n)];
                    get_entvar(t, var_origin, po);
                    po[0] += random_float(-40.0, 40.0);
                    po[1] += random_float(-40.0, 40.0);
                    ZoneSpawn(po, BskRad(3), 255, 240, 80, 0.65, 0, false);
                    if (g_sprTarget)
                        FxSprite(po, g_sprTarget, 4, 220);
                    BskTask(0.65, "task_TempestHit", po);
                }
            }
            if (tick % 25 == 0)
            {
                FadeAll(255, 255, 255, 80, 0.25);
                PlayKey(0, "LIGHTNING");
            }
        }
        case CH_CLOUD: // Hive Queen: zehir bulutu
        {
            if (tick % 5 == 0)
            {
                new Float:rad = BskRad(2), Float:puff[3];
                for (new k = 0; k < 2; k++)
                {
                    puff = bo;
                    puff[0] += random_float(-rad * 0.6, rad * 0.6);
                    puff[1] += random_float(-rad * 0.6, rad * 0.6);
                    FxSprite(puff, g_sprSmoke, 18, 140);
                }
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p))
                        continue;
                    get_entvar(p, var_origin, po);
                    if (get_distance_f(bo, po) > rad)
                        continue;
                    if (g_bZombie[p])
                        HealTo(p, 50, g_iMaxHP[p]);
                    else
                    {
                        g_iPoison[p] = max(g_iPoison[p], 3);
                        g_iPoisonBy[p] = g_iBoss;
                        SlowHuman(p, 0.6);
                        FadeOne(p, 110, 255, 0, 80, 0.6);
                    }
                }
            }
        }
        case CH_SINGULARITY: // Void: kara delik - cek
        {
            new Float:c[3];
            c = g_fBossChannelPos;
            new Float:rad = BskRad(2);
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_alive(p) || g_bZombie[p])
                    continue;
                get_entvar(p, var_origin, po);
                if (get_distance_f(c, po) > rad)
                    continue;
                PullTo(p, c, 60.0);
                if (tick % 5 == 0)
                    FxBeamEx(po, c, g_sprLightning, 220, 0, 140, 18, 40, 4);
            }
            if (tick % 5 == 0)
            {
                FxImplosion(c, 255, 50, 5);
                FxLight(c, 200, 0, 160, 30, 6, 10);
            }
        }
        case CH_HORIZON: // Void: olay ufku
        {
            new Float:rad = BskRad(3);
            if (tick % 2 == 0)
            {
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p) || g_bZombie[p])
                        continue;
                    get_entvar(p, var_origin, po);
                    if (get_distance_f(bo, po) > rad)
                        continue;
                    PullTo(p, bo, 45.0);
                }
            }
            if (tick % 10 == 0)
            {
                FxImplosion(bo, 255, 60, 8);
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p) || g_bZombie[p])
                        continue;
                    get_entvar(p, var_origin, po);
                    if (get_distance_f(bo, po) > rad * 0.55)
                        continue;
                    FadeOne(p, 60, 0, 60, 160, 0.8);
                    BossHurt(p, BskDmg(3), DMG_GENERIC);
                }
            }
        }
    }
}

/* ==================== 0 BRUTE ==================== */

// Faz 1 - SISMIK EZME: cevredeki herkesi havaya firlatir
bool:Bsk_BruteStomp()
{
    new Float:bo[3], Float:feet[3];
    get_entvar(g_iBoss, var_origin, bo);
    feet = bo;
    feet[2] -= 30.0;
    new Float:rad = BskRad(1);

    FxLava(bo);
    FxExplosion(bo);
    FxRingEx(feet, 255, 120, 0, floatround(rad), 30, 5);
    FxRingEx(feet, 255, 220, 80, floatround(rad * 0.6), 18, 4);
    FxStreak(bo, 5, 60, 400);
    FxLight(bo, 255, 120, 0, 45, 8, 30);
    ShakeAll(10, 1.2, 6);
    EmitKey(g_iBoss, "BOSS_SLAM", CHAN_ITEM);
    BossAoE(bo, rad, BskDmg(1), 255, 120, 0, 480.0);
    return true;
}

// Faz 2 - YER YARIGI: baktigi yone dogru ilerleyen patlamalar
bool:Bsk_BruteShatter()
{
    new Float:bo[3], Float:fwd[3], Float:prev[3], Float:pt[3];
    get_entvar(g_iBoss, var_origin, bo);
    BossFwd(fwd, true);
    prev = bo;

    for (new i = 1; i <= 7; i++)
    {
        for (new k = 0; k < 3; k++)
            pt[k] = bo[k] + fwd[k] * 95.0 * float(i);
        engfunc(EngFunc_TraceLine, prev, pt, IGNORE_MONSTERS, g_iBoss, 0);
        new Float:frac;
        get_tr2(0, TR_flFraction, frac);
        if (frac < 1.0)
            break;
        prev = pt;
        new Float:delay = 0.35 + 0.12 * float(i);
        ZoneSpawn(pt, BskRad(2), 255, 140, 0, delay, 0, i == 1);
        BskTask(delay, "task_BruteEruption", pt);
    }
    ShakeAll(6, 1.0, 5);
    return true;
}

public task_BruteEruption(params[])
{
    if (!BskValid(params))
        return;
    new Float:o[3];
    BskPos(params, o);
    FxLava(o);
    FxExplosion(o);
    FxSprite(o, g_sprFire ? g_sprFire : g_sprExplode, 12, 230);
    FxLight(o, 255, 120, 0, 30, 5, 30);
    EmitKeyPos(o, "BOSS_STEP");
    BossAoE(o, BskRad(2), BskDmg(2), 255, 120, 0, 380.0);
}

// Faz 3 - TITAN OFKESI (ulti): 6 sn hizli, dayanikli, her saniye sok dalgasi
bool:Bsk_BruteWrath()
{
    new Float:bo[3];
    get_entvar(g_iBoss, var_origin, bo);
    g_fBossBuffEnd = get_gametime() + 6.0;
    StartChannel(CH_TITAN, 6.0);
    ApplyRender(g_iBoss);
    rg_reset_maxspeed(g_iBoss);
    ZoneSpawn(bo, BskRad(3), 255, 80, 0, 6.0, g_iBoss, false);
    FxFunnel(bo, g_sprFlare, true);
    FadeAll(255, 80, 0, 80, 1.2);
    ShakeAll(12, 1.5, 6);
    return true;
}

/* ==================== 1 BANSHEE ==================== */

// Faz 1 - SES MIZRAGI: onundeki koniye sok dalgasi, geri savurur
bool:Bsk_BansheeLance()
{
    new Float:eye[3], Float:fwd[3], Float:po[3], Float:pt[3];
    BossEye(eye);
    BossFwd(fwd, false);
    new Float:rad = BskRad(1);

    for (new i = 1; i <= 6; i++)
    {
        for (new k = 0; k < 3; k++)
            pt[k] = eye[k] + fwd[k] * rad * float(i) / 6.0;
        FxRingEx(pt, 210, 220, 255, 30 + i * 22, 10, 3, 200);
    }
    for (new k = 0; k < 3; k++)
        pt[k] = eye[k] + fwd[k] * rad;
    FxBeamEx(eye, pt, g_sprBeam, 210, 220, 255, 60, 20, 4);
    FxImplosion(eye, 120, 30, 4);

    new hits;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        new Float:d = get_distance_f(eye, po);
        if (d > rad || d < 1.0)
            continue;
        new Float:dir[3];
        for (new k = 0; k < 3; k++)
            dir[k] = (po[k] - eye[k]) / d;
        if (dir[0] * fwd[0] + dir[1] * fwd[1] + dir[2] * fwd[2] < 0.82 || !BossSees(eye, p))
            continue;

        new Float:vel[3];
        vel[0] = dir[0] * 650.0;
        vel[1] = dir[1] * 650.0;
        vel[2] = 230.0;
        set_entvar(p, var_velocity, vel);
        ShakeEx(p, 10, 1.0, 8);
        FadeOne(p, 230, 235, 255, 170, 1.0);
        SlowHuman(p, 2.0);
        BossHurt(p, BskDmg(1), DMG_SONIC);
        hits++;
    }
    return true;
}

// Faz 2 - HAYALET CIGLIGI: kurbanin arkasina isinlanir, kor eden ciglik
bool:Bsk_BansheeShriek()
{
    new t = BossPickHuman(1300.0, 0.3);
    if (!t)
        return false;

    new Float:to[3], Float:tang[3], Float:fwd[3], Float:dest[3];
    get_entvar(t, var_origin, to);
    get_entvar(t, var_v_angle, tang);
    tang[0] = 0.0;
    engfunc(EngFunc_MakeVectors, tang);
    global_get(glb_v_forward, fwd);

    new bool:found;
    static const Float:OFF[][2] = { {-75.0, 0.0}, {0.0, 75.0}, {0.0, -75.0}, {75.0, 0.0}, {-110.0, 0.0} };
    new Float:right[3];
    global_get(glb_v_right, right);
    for (new i = 0; i < sizeof OFF && !found; i++)
    {
        for (new k = 0; k < 3; k++)
            dest[k] = to[k] + fwd[k] * OFF[i][0] + right[k] * OFF[i][1];
        dest[2] = to[2] + 8.0;
        if (IsHullFree(g_iBoss, dest))
            found = true;
    }
    if (!found)
        return false;

    new Float:bo[3];
    get_entvar(g_iBoss, var_origin, bo);
    FxTeleport(bo);
    FxBeamEx(bo, dest, g_sprBeam, 200, 210, 255, 30, 30, 6);
    engfunc(EngFunc_SetOrigin, g_iBoss, dest);
    set_entvar(g_iBoss, var_velocity, Float:{0.0, 0.0, 0.0});
    BossFace(t);
    set_entvar(g_iBoss, var_fixangle, 1);
    FxTeleport(dest);

    new Float:rad = BskRad(2), Float:po[3];
    FxRingEx(dest, 220, 230, 255, floatround(rad), 30, 5);
    FxRingEx(dest, 255, 255, 255, floatround(rad * 0.5), 14, 4);
    FxImplosion(dest, 200, 50, 6);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(dest, po) > rad)
            continue;
        FadeOne(p, 255, 255, 255, 255, 2.5);
        ShakeEx(p, 12, 1.5, 8);
        SlowHuman(p, 2.0);
        BossHurt(p, BskDmg(2), DMG_SONIC);
    }
    return true;
}

// Faz 3 - AGIT (ulti): 5 saniye, saniyede bir tum haritaya feryat, can calar
bool:Bsk_BansheeRequiem()
{
    new Float:bo[3];
    get_entvar(g_iBoss, var_origin, bo);
    StartChannel(CH_REQUIEM, 5.2);
    g_iBossChannelTick = 9;
    FxFunnel(bo, g_sprFlare, false);
    FadeAll(200, 210, 255, 90, 1.5);
    return true;
}

/* ==================== 2 OVERLORD ==================== */

// Faz 1 - KEMIK HAPSI: hedefi kemik kafese hapseder
bool:Bsk_OverlordPrison()
{
    new t = BossPickHuman(BskRad(1), 0.6);
    if (!t)
        return false;

    new Float:to[3], Float:a[3], Float:b[3];
    get_entvar(t, var_origin, to);
    RootHuman(t, 2.5);
    set_user_rendering(t, kRenderFxGlowShell, 150, 0, 220, kRenderNormal, 30);

    for (new i = 0; i < 8; i++)
    {
        new Float:ang = float(i) * 45.0;
        a[0] = to[0] + floatcos(ang, degrees) * 34.0;
        a[1] = to[1] + floatsin(ang, degrees) * 34.0;
        a[2] = to[2] - 36.0;
        b = a;
        b[2] = to[2] + 44.0;
        FxBeamEx(a, b, g_sprBeam, 170, 60, 255, 18, 0, 25, 230);
    }
    ZoneSpawn(to, 60.0, 150, 0, 220, 2.5, t, false);
    FxImplosion(to, 120, 30, 6);
    FadeOne(t, 120, 0, 180, 140, 1.0);
    BossHurt(t, BskDmg(1), DMG_GENERIC);

    FxBeamEntPoint(g_iBoss, to, g_sprLightning, 150, 0, 220, 30, 30, 5);
    client_print(t, print_center, "%L", t, "BSK_PRISON_YOU");
    return true;
}

// Faz 2 - LEJYON: dusenleri dirilt + yakindaki insanlarin canini emer
bool:Bsk_OverlordLegion()
{
    new Float:bo[3], Float:po[3];
    get_entvar(g_iBoss, var_origin, bo);
    SummonMinions(4);
    FxFunnel(bo, g_sprFlare, true);
    FxRingEx(bo, 150, 0, 200, floatround(BskRad(2)), 30, 6);
    FxTeleport(bo);

    new Float:rad = BskRad(2), total;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(bo, po) > rad || !BossSees(bo, p))
            continue;
        FxBeamEx(po, bo, g_sprLightning, 150, 0, 200, 25, 30, 6);
        FadeOne(p, 120, 0, 180, 110, 0.8);
        BossHurt(p, BskDmg(2), DMG_GENERIC);
        total += floatround(BskDmg(2));
    }
    HealTo(g_iBoss, g_iBossMaxHP / 25 + total * 4, g_iBossMaxHP);
    return true;
}

// Faz 3 - OLUM NOVASI (ulti): ic -> dis yayilan 3 olum halkasi
bool:Bsk_OverlordNova()
{
    new Float:bo[3];
    get_entvar(g_iBoss, var_origin, bo);
    new Float:w = BskRad(3);
    ZoneSpawn(bo, w * 3.0, 150, 0, 220, 2.4, 0, true);
    FxFunnel(bo, g_sprFlare, false);
    for (new k = 0; k < 3; k++)
        BskTask(0.6 + 0.6 * float(k), "task_NovaBand", bo, k);
    return true;
}

public task_NovaBand(params[])
{
    if (!BskValid(params))
        return;
    new Float:o[3], Float:po[3];
    BskPos(params, o);
    new k = params[4];
    new Float:w = BskRad(3);
    new Float:inner = w * float(k), Float:outer = w * float(k + 1);

    new Float:feet[3];
    feet = o;
    feet[2] -= 30.0;
    FxRingEx(feet, 170, 0, 255, floatround(outer), 40, 4);
    FxRingEx(feet, 255, 255, 255, floatround(outer * 0.92), 12, 3);
    FxImplosion(o, 200, 40, 4);
    FxElSmall(o, EL_VOID, 12);
    EmitKeyPos(o, "BOSS_SUMMON");

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        new Float:d = get_distance_f(o, po);
        if (d < inner || d > outer)
            continue;
        FadeOne(p, 150, 0, 220, 150, 0.8);
        ShakeOne(p);
        PushFrom(p, o, 300.0, 160.0);
        BossHurt(p, BskDmg(3), DMG_GENERIC);
    }
}

/* ==================== 3 INFERNO ==================== */

// Faz 1 - ALEV NEFESI: onundeki koniye ates puskurtur, tutusturur
bool:Bsk_InfernoBreath()
{
    new Float:eye[3], Float:fwd[3], Float:po[3], Float:pt[3];
    BossEye(eye);
    BossFwd(fwd, false);
    new Float:rad = BskRad(1);
    new spr = g_sprFire ? g_sprFire : g_sprExplode;

    for (new i = 1; i <= 6; i++)
    {
        for (new k = 0; k < 3; k++)
            pt[k] = eye[k] + fwd[k] * rad * float(i) / 6.0;
        pt[2] -= 20.0;
        FxSprite(pt, spr, 4 + i * 2, 220);
        if (i % 2 == 0)
            FxLight(pt, 255, 110, 0, 20, 5, 30);
    }

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        new Float:d = get_distance_f(eye, po);
        if (d > rad || d < 1.0)
            continue;
        new Float:dot = ((po[0] - eye[0]) * fwd[0] + (po[1] - eye[1]) * fwd[1] + (po[2] - eye[2]) * fwd[2]) / d;
        if (dot < 0.75 || !BossSees(eye, p))
            continue;
        BurnHuman(p, 5);
        FadeOne(p, 255, 110, 0, 130, 0.8);
        BossHurt(p, BskDmg(1), DMG_BURN);
    }
    return true;
}

// Faz 2 - ATES SUTUNLARI: insanlarin altindan alev sutunlari fiskirir
bool:Bsk_InfernoPillars()
{
    new list[32], n, Float:po[3];
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_alive(p) && !g_bZombie[p])
            list[n++] = p;
    }
    if (!n)
        return false;

    for (new i = 0; i < 5 && n > 0; i++)
    {
        new pick = random(n);
        get_entvar(list[pick], var_origin, po);
        list[pick] = list[n - 1];
        n--;
        ZoneSpawn(po, BskRad(2), 255, 90, 0, 1.2 + 0.15 * float(i), 0, i == 0);
        BskTask(1.2 + 0.15 * float(i), "task_FirePillar", po);
    }
    return true;
}

public task_FirePillar(params[])
{
    if (!BskValid(params))
        return;
    new Float:o[3], Float:po[3], Float:h[3];
    BskPos(params, o);
    new spr = g_sprFire ? g_sprFire : g_sprExplode;
    h = o;
    for (new i = 0; i < 4; i++)
    {
        h[2] = o[2] - 20.0 + 60.0 * float(i);
        FxSprite(h, spr, 10, 240);
    }
    FxLava(o);
    if (!FxExploEl(o, EL_FIRE, 20, 15))
        FxExplosion(o);
    FxLight(o, 255, 100, 0, 35, 6, 30);
    EmitKeyPos(o, "NADE_FIRE");

    new Float:rad = BskRad(2);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > rad)
            continue;
        new Float:vel[3];
        get_entvar(p, var_velocity, vel);
        vel[2] = 360.0;
        set_entvar(p, var_velocity, vel);
        BurnHuman(p, 4);
        FadeOne(p, 255, 90, 0, 140, 0.8);
        BossHurt(p, BskDmg(2), DMG_BURN);
    }
}

// Faz 3 - SUPERNOVA (ulti): 2 sn sarj (boss kipirdayamaz), sonra dev patlama + yanan zemin
bool:Bsk_InfernoNova()
{
    new Float:bo[3];
    get_entvar(g_iBoss, var_origin, bo);
    g_fBossIntro = get_gametime() + 2.0;
    set_entvar(g_iBoss, var_velocity, Float:{0.0, 0.0, 0.0});
    rg_reset_maxspeed(g_iBoss);
    set_user_rendering(g_iBoss, kRenderFxGlowShell, 255, 200, 0, kRenderNormal, 80);
    ZoneSpawn(bo, BskRad(3), 255, 60, 0, 2.0, g_iBoss, true);
    FxFunnel(bo, g_sprFlare, false);
    FxLight(bo, 255, 120, 0, 60, 20, 5);
    BskTask(2.0, "task_Supernova", bo);
    return true;
}

public task_Supernova(params[])
{
    if (!BskValid(params))
        return;
    new Float:o[3], Float:po[3];
    get_entvar(g_iBoss, var_origin, o);
    g_fBossIntro = 0.0;
    rg_reset_maxspeed(g_iBoss);
    ApplyRender(g_iBoss);

    new Float:rad = BskRad(3);
    if (!FxExploEl(o, EL_FIRE, 36, 15))
        FxExplosion(o);
    FxLava(o);
    FxRingEx(o, 255, 90, 0, floatround(rad), 60, 7);
    FxRingEx(o, 255, 240, 120, floatround(rad * 0.6), 30, 6);
    FxLight(o, 255, 140, 0, 80, 10, 20);
    FxSkyStrike(o, 255, 140, 0);
    ShakeAll(16, 2.5, 8);
    PlayKey(0, "BOSS_SLAM");

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p))
            continue;
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        new Float:d = get_distance_f(o, po);
        if (d > rad)
            continue;
        new Float:k = floatmax(0.15, 1.0 - d / rad);
        FadeOne(p, 255, 120, 0, 200, 1.2);
        PushFrom(p, o, 600.0, 260.0);
        BurnHuman(p, 4);
        BossHurt(p, BskDmg(3) * k, DMG_BURN | DMG_BLAST);
    }

    // Etrafta 4 yanan zemin
    new Float:pt[3];
    for (new i = 0; i < 4; i++)
    {
        new Float:a = float(i) * 90.0 + random_float(-25.0, 25.0);
        pt[0] = o[0] + floatcos(a, degrees) * rad * 0.45;
        pt[1] = o[1] + floatsin(a, degrees) * rad * 0.45;
        pt[2] = o[2];
        AddPool(pt, 1, 5.0, 130.0);
    }
}

/* ==================== 4 REAPER ==================== */

// Faz 1 - GOLGE ADIMI: baktigi yere isinlanir, sonraki vurusu x2
bool:Bsk_ReaperStep()
{
    new Float:aim[3], Float:fwd[3], Float:dest[3], Float:bo[3];
    BossAimPoint(BskRad(1), aim);
    BossFwd(fwd, true);
    get_entvar(g_iBoss, var_origin, bo);

    new bool:found;
    for (new k = 1; k <= 10 && !found; k++)
    {
        for (new i = 0; i < 3; i++)
            dest[i] = aim[i] - fwd[i] * 40.0 * float(k);
        dest[2] = aim[2] + 36.0;
        if (IsHullFree(g_iBoss, dest))
            found = true;
    }
    if (!found)
        return false;

    FxTeleport(bo);
    FxBeamEx(bo, dest, g_sprBeam, 90, 0, 150, 40, 10, 8);
    engfunc(EngFunc_SetOrigin, g_iBoss, dest);
    set_entvar(g_iBoss, var_velocity, Float:{0.0, 0.0, 0.0});
    FxTeleport(dest);
    FxImplosion(dest, 150, 40, 5);
    g_fBossEmpower = get_gametime() + 3.0;
    set_user_rendering(g_iBoss, kRenderFxGlowShell, 120, 0, 200, kRenderNormal, 60);
    if (!is_user_bot(g_iBoss))
        client_print(g_iBoss, print_center, "%L", g_iBoss, "BSK_EMPOWER");
    return true;
}

// Faz 2 - RUH ZINCIRLERI: en yakin 3 insani zincirler; can emer, yavaslatir
bool:Bsk_ReaperChains()
{
    new Float:bo[3], Float:po[3];
    get_entvar(g_iBoss, var_origin, bo);
    new Float:rad = BskRad(2);

    for (new i = 0; i < 3; i++)
        g_iBossTethers[i] = 0;

    new found;
    for (new pass = 0; pass < 3; pass++)
    {
        new best, Float:bd = rad;
        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_alive(p) || g_bZombie[p])
                continue;
            if (p == g_iBossTethers[0] || p == g_iBossTethers[1] || p == g_iBossTethers[2])
                continue;
            get_entvar(p, var_origin, po);
            new Float:d = get_distance_f(bo, po);
            if (d < bd && BossSees(bo, p))
            {
                bd = d;
                best = p;
            }
        }
        if (!best)
            break;
        g_iBossTethers[found++] = best;
        client_print(best, print_center, "%L", best, "BSK_CHAINED");
    }
    if (!found)
        return false;

    StartChannel(CH_CHAINS, 4.0);
    g_iBossChannelTick = 4;
    FxImplosion(bo, 200, 40, 6);
    return true;
}

// Faz 3 - OLUM ISARETI (ulti): herkes isaretlenir; 3 sn icinde yerinden kacmayan patlar
bool:Bsk_ReaperMark()
{
    new Float:po[3], n;
    new Float:rad = BskRad(3);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        ZoneSpawn(po, rad, 160, 0, 255, 3.0, 0, n == 0);
        if (g_sprTarget)
            FxSprite(po, g_sprTarget, 5, 230);
        BskTask(3.0, "task_DeathMark", po);
        if (g_sprMark && !is_user_bot(p))
            FxHeadMark(p, g_sprMark, 30, g_bMarkAt);
        client_print(p, print_center, "%L", p, "BSK_MARKED");
        n++;
    }
    return n > 0;
}

public task_DeathMark(params[])
{
    if (!BskValid(params))
        return;
    new Float:o[3], Float:po[3], Float:top[3];
    BskPos(params, o);
    top = o;
    top[2] += 600.0;
    FxBeamEx(top, o, g_sprLightning, 130, 0, 220, 50, 30, 4);
    FxImplosion(o, 160, 50, 4);
    FxSprite(o, g_sprExplode, 8, 180);
    FxLight(o, 130, 0, 220, 30, 5, 30);
    EmitKeyPos(o, "ZAP");

    new Float:rad = BskRad(3);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > rad)
            continue;
        FadeOne(p, 100, 0, 180, 180, 1.0);
        ShakeOne(p);
        BossHurt(p, BskDmg(3), DMG_GENERIC);
    }
}

/* ==================== 5 FROSTLORD ==================== */

// Faz 1 - BUZ PARCALARI: yelpaze seklinde 5 buz mizragi
bool:Bsk_FrostShards()
{
    new Float:eye[3], Float:ang[3], Float:fwd[3], Float:end[3], Float:hitp[3];
    BossEye(eye);
    new Float:rad = BskRad(1);

    for (new k = -2; k <= 2; k++)
    {
        get_entvar(g_iBoss, var_v_angle, ang);
        ang[1] += float(k) * 10.0;
        engfunc(EngFunc_MakeVectors, ang);
        global_get(glb_v_forward, fwd);
        for (new i = 0; i < 3; i++)
            end[i] = eye[i] + fwd[i] * rad;

        engfunc(EngFunc_TraceLine, eye, end, DONT_IGNORE_MONSTERS, g_iBoss, 0);
        get_tr2(0, TR_vecEndPos, hitp);
        new hit = get_tr2(0, TR_pHit);

        FxBeamEx(eye, hitp, g_sprBeam, 150, 220, 255, 22, 0, 4, 230);
        FxSparks(hitp);
        FxStreak(hitp, 7, 20, 160);

        if (1 <= hit <= g_iMax && is_user_alive(hit) && !g_bZombie[hit])
        {
            SlowHuman(hit, 2.5);
            FadeOne(hit, 150, 210, 255, 140, 1.0);
            BossHurt(hit, BskDmg(1), DMG_FREEZE);
        }
    }
    EmitKey(g_iBoss, "FROST_NOVA", CHAN_ITEM);
    return true;
}

// Faz 2 - BUZ MEZARI: hedefi buza hapseder, cevresini yavaslatir
bool:Bsk_FrostTomb()
{
    new t = BossPickHuman(BskRad(2), 0.6);
    if (!t)
        return false;

    new Float:to[3], Float:po[3];
    get_entvar(t, var_origin, to);
    RootHuman(t, 3.0);
    FxExploEl(to, EL_ICE, 14, 12);
    FxRingEx(to, 150, 220, 255, 160, 30, 5);
    FxDisk(to, 120, 200, 255, 120, 8);
    FxStreak(to, 7, 80, 300);
    FxLight(to, 120, 200, 255, 30, 10, 20);
    ZoneSpawn(to, 160.0, 120, 200, 255, 3.0, t, false);
    FadeOne(t, 150, 210, 255, 200, 3.0);
    BossHurt(t, BskDmg(2), DMG_FREEZE);
    FxBeamEntPoint(g_iBoss, to, g_sprBeam, 150, 220, 255, 30, 10, 5);
    client_print(t, print_center, "%L", t, "BSK_TOMB_YOU");

    for (new p = 1; p <= g_iMax; p++)
    {
        if (p == t || !is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(to, po) <= 160.0)
            SlowHuman(p, 2.0);
    }
    return true;
}

// Faz 3 - MUTLAK SIFIR (ulti): 8 sn kar firtinasi; DURAN donar, hareket eden az hasar alir
bool:Bsk_FrostZero()
{
    g_fBlizzardEnd = get_gametime() + 8.0;
    StartChannel(CH_ZERO, 8.0);
    g_iBossChannelTick = 10;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
            continue;
        if (!is_user_bot(id))
        {
            if (!(g_iSet[id] & SET_NO_FOG))
                SendFogEx(id, 200, 220, 255, 40);
            SendWeather(id, 2);
        }
        if (is_user_alive(id) && !g_bZombie[id])
        {
            rg_reset_maxspeed(id);
            FadeOne(id, 200, 230, 255, 140, 2.0);
            ShakeOne(id);
        }
    }
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p))
            client_print(p, print_center, "%L", p, "BSK_ZERO_TIP");
    }
    return true;
}

/* ==================== 6 STORMCALLER ==================== */

// Faz 1 - TOP YILDIRIM: yavas ilerleyen, yakindakileri carpan enerji kuresi
bool:Bsk_StormOrb()
{
    new Float:eye[3], Float:fwd[3], Float:o[3], Float:vel[3];
    BossEye(eye);
    BossFwd(fwd, false);
    for (new i = 0; i < 3; i++)
    {
        o[i] = eye[i] + fwd[i] * 40.0;
        vel[i] = fwd[i] * 280.0;
    }
    vel[2] *= 0.3;
    return ProjSpawn(PJ_ORB, o, vel, 255, 240, 80, 1.1, 5.0, MOVETYPE_FLY, 0.0) > 0;
}

// Faz 2 - YILDIRIM ATILMASI: ileri atilir, yolundakileri carpar
bool:Bsk_StormDash()
{
    g_iDashHit = 0;
    LeapForward(g_iBoss, 1300.0, 160.0);
    StartChannel(CH_DASH, 0.7);
    FxFollow(g_iBoss, 255, 240, 80, 8, 20);
    return true;
}

// Faz 3 - KASIRGA (ulti): 8 sn yagmur + karanlik; rastgele insanlara isaretli yildirim
bool:Bsk_StormTempest()
{
    StartChannel(CH_TEMPEST, 8.0);
    engfunc(EngFunc_LightStyle, 0, "c");
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_bot(id))
            continue;
        SendWeather(id, 1);
        if (!(g_iSet[id] & SET_NO_FOG))
            SendFogEx(id, 60, 70, 90, 35);
    }
    FadeAll(255, 255, 255, 90, 0.3);
    PlayKey(0, "THUNDER");
    return true;
}

public task_TempestHit(params[])
{
    if (!BskValid(params))
        return;
    new Float:o[3], Float:po[3];
    BskPos(params, o);
    FxSkyStrike(o, 255, 255, 140);
    FxSkyStrike(o, 255, 255, 255);
    FxRingEx(o, 255, 240, 80, floatround(BskRad(3)) + 60, 20, 5);
    FxStreak(o, 5, 50, 260);
    EmitKeyPos(o, "THUNDER");

    new Float:rad = BskRad(3);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        new Float:d = get_distance_f(o, po);
        if (d < 600.0)
            FadeOne(p, 255, 255, 255, 50, 0.2);
        if (d > rad)
            continue;
        ShakeEx(p, 12, 1.0, 6);
        SlowHuman(p, 1.0);
        BossHurt(p, BskDmg(3), DMG_SHOCK);
    }
}

/* ==================== 7 HIVE QUEEN ==================== */

// Faz 1 - ASIT TUKURUGU: baktigi yere asit firlatir, dustugu yerde asit havuzu
bool:Bsk_HiveSpit()
{
    new Float:eye[3], Float:fwd[3], Float:o[3], Float:vel[3];
    BossEye(eye);
    BossFwd(fwd, false);
    for (new i = 0; i < 3; i++)
    {
        o[i] = eye[i] + fwd[i] * 30.0;
        vel[i] = fwd[i] * 950.0;
    }
    vel[2] += 140.0;
    return ProjSpawn(PJ_ACID, o, vel, 110, 255, 0, 0.7, 4.0, MOVETYPE_TOSS, 0.7) > 0;
}

// Faz 2 - ZEHIR BULUTU: 6 sn kralicenin etrafinda zehir; zombileri iyilestirir
bool:Bsk_HiveCloud()
{
    new Float:bo[3];
    get_entvar(g_iBoss, var_origin, bo);
    StartChannel(CH_CLOUD, 6.0);
    ZoneSpawn(bo, BskRad(2), 110, 255, 0, 6.0, g_iBoss, false);
    FxSprite(bo, g_sprSmoke, 40, 200);
    return true;
}

// Faz 3 - KULUCKA (ulti): 4 yumurta birakir; 5 sn icinde kirilmayan yumurta patlar
bool:Bsk_HiveEggs()
{
    new Float:bo[3], Float:pt[3];
    get_entvar(g_iBoss, var_origin, bo);
    new made;
    for (new i = 0; i < 4; i++)
    {
        new Float:a = float(i) * 90.0 + random_float(-20.0, 20.0);
        pt[0] = bo[0] + floatcos(a, degrees) * 130.0;
        pt[1] = bo[1] + floatsin(a, degrees) * 130.0;
        pt[2] = bo[2];
        engfunc(EngFunc_TraceLine, bo, pt, IGNORE_MONSTERS, g_iBoss, 0);
        get_tr2(0, TR_vecEndPos, pt);
        if (EggSpawn(pt))
            made++;
    }
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_alive(p) && !g_bZombie[p] && !is_user_bot(p))
            client_print(p, print_center, "%L", p, "BSK_EGGS_TIP");
    }
    return made > 0;
}

EggSpawn(const Float:o[3])
{
    new ent = rg_create_entity("info_target");
    if (is_nullent(ent))
        return 0;
    new Float:pos[3];
    FloorAt(o, pos);

    set_entvar(ent, var_classname, EGG_CLASS);
    if (g_szEggModel[0])
    {
        // v3.0: kovan yumurtasi modeli (nabiz animasyonu) + yesil parilti
        engfunc(EngFunc_SetModel, ent, g_szEggModel);
        if (AnimByName(ent, "pulse", -1, 1.0) < 0)
            AnimByName(ent, "idle", 0, 1.0);
        set_entvar(ent, var_renderfx, kRenderFxGlowShell);
        set_entvar(ent, var_rendercolor, Float:{110.0, 255.0, 0.0});
        set_entvar(ent, var_renderamt, 12.0);
    }
    else if (g_szSprOrb[0])
    {
        engfunc(EngFunc_SetModel, ent, g_szSprOrb);
        set_entvar(ent, var_rendermode, kRenderTransAdd);
        set_entvar(ent, var_renderamt, 230.0);
        set_entvar(ent, var_rendercolor, Float:{110.0, 255.0, 0.0});
        set_entvar(ent, var_scale, 0.55);
    }
    set_entvar(ent, var_movetype, MOVETYPE_NONE);
    set_entvar(ent, var_solid, SOLID_BBOX);
    if (g_szEggModel[0])
    {
        // hive_egg.mdl: taban z = 0 -> zemine oturur (eskiden 14 birim havada duruyordu)
        pos[2] -= 1.0;
        engfunc(EngFunc_SetSize, ent, Float:{-12.0, -12.0, 0.0}, Float:{12.0, 12.0, 24.0});
    }
    else
    {
        pos[2] += 14.0;   // sprite merkezi
        engfunc(EngFunc_SetSize, ent, Float:{-14.0, -14.0, -14.0}, Float:{14.0, 14.0, 14.0});
    }
    engfunc(EngFunc_SetOrigin, ent, pos);

    new Float:hp = 150.0 + 40.0 * float(CountHumans(true));
    set_entvar(ent, var_takedamage, DAMAGE_YES);
    set_entvar(ent, var_health, hp);
    set_entvar(ent, var_max_health, hp);
    set_entvar(ent, var_iuser3, g_iBossSerial);
    set_entvar(ent, var_fuser1, get_gametime() + 5.0);
    set_entvar(ent, var_effects, EF_DIMLIGHT);

    SetThink(ent, "fw_EggThink");
    set_entvar(ent, var_nextthink, get_gametime() + 0.5);
    ZoneSpawn(pos, BskRad(3), 110, 255, 0, 5.0, 0, false);
    FxSprite(pos, g_sprSmoke, 10, 160);
    return ent;
}

public fw_EggThink(ent)
{
    if (is_nullent(ent))
        return;
    if (get_entvar(ent, var_iuser3) != g_iBossSerial || !g_bRoundActive)
    {
        set_entvar(ent, var_flags, FL_KILLME);
        return;
    }

    new Float:o[3], Float:now = get_gametime();
    get_entvar(ent, var_origin, o);
    if (g_szEggModel[0])
        o[2] += 12.0;   // efektler yumurtanin ortasindan (model tabani zeminde)
    if (now >= Float:get_entvar(ent, var_fuser1))
    {
        // Catladi: asit patlamasi + (varsa) yardimci zombi
        if (g_iBoss && is_user_alive(g_iBoss))
        {
            AcidSplash(o, BskRad(3), BskDmg(3));
            SummonMinions(1);
        }
        set_entvar(ent, var_flags, FL_KILLME);
        return;
    }
    FxLight(o, 110, 255, 0, 10, 6, 5);
    set_entvar(ent, var_nextthink, now + 0.5);
}

EggTakeDamage(ent, attacker, Float:damage)
{
    if (!(1 <= attacker <= g_iMax) || !is_user_connected(attacker) || g_bZombie[attacker])
        return HAM_SUPERCEDE;

    new Float:hp = Float:get_entvar(ent, var_health) - damage;
    new Float:o[3];
    get_entvar(ent, var_origin, o);
    if (g_szEggModel[0])
        o[2] += 12.0;
    if (hp <= 0.0)
    {
        FxSprite(o, g_sprSmoke, 15, 180);
        FxStreak(o, 2, 40, 200);
        EmitKeyPos(o, "NADE_INFECT");
        Reward(attacker, 15, 3);
        set_entvar(ent, var_takedamage, DAMAGE_NO);
        set_entvar(ent, var_flags, FL_KILLME);
        return HAM_SUPERCEDE;
    }
    set_entvar(ent, var_health, hp);
    if (random_num(1, 3) == 1)
        FxSparks(o);
    return HAM_SUPERCEDE;
}

// Asit sicramasi: hasar + zehir + asit havuzu
AcidSplash(const Float:o[3], Float:rad, Float:dmg)
{
    new Float:po[3];
    if (!FxExploEl(o, EL_TOXIC, clamp(floatround(rad / 14.0), 10, 30), 14))
        FxSprite(o, g_sprSmoke, 20, 180);
    FxStreak(o, 2, 40, 220);
    EmitKeyPos(o, "ACID_POOL");
    AddPool(o, 0, 6.0, rad);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > rad)
            continue;
        g_iPoison[p] = max(g_iPoison[p], 3);
        g_iPoisonBy[p] = g_iBoss;
        FadeOne(p, 110, 255, 0, 120, 0.8);
        BossHurt(p, dmg, DMG_ACID);
    }
}

/* ==================== 8 VOID ==================== */

// Faz 1 - BOSLUK OKU: hizli ok; carptigi insani bossa dogru ceker
bool:Bsk_VoidBolt()
{
    new Float:eye[3], Float:fwd[3], Float:o[3], Float:vel[3];
    BossEye(eye);
    BossFwd(fwd, false);
    for (new i = 0; i < 3; i++)
    {
        o[i] = eye[i] + fwd[i] * 40.0;
        vel[i] = fwd[i] * 1100.0;
    }
    new Float:life = floatmax(0.3, BskRad(1) / 1100.0);
    return ProjSpawn(PJ_VOID, o, vel, 220, 0, 140, 0.8, life, MOVETYPE_FLY, 0.0) > 0;
}

// Faz 2 - TEKILLIK: baktigi noktada 4 sn kara delik; sonunda cokme patlamasi
bool:Bsk_VoidSingularity()
{
    new Float:c[3];
    BossAimPoint(700.0, c);
    new Float:fwd[3];
    BossFwd(fwd, false);
    for (new i = 0; i < 3; i++)
        c[i] -= fwd[i] * 24.0;
    g_fBossChannelPos = c;
    StartChannel(CH_SINGULARITY, 4.0);
    ZoneSpawn(c, BskRad(2), 220, 0, 140, 4.0, 0, true);
    FxFunnel(c, g_sprFlare, false);
    return true;
}

SingularityCollapse()
{
    new Float:c[3], Float:po[3];
    c = g_fBossChannelPos;
    if (!FxExploEl(c, EL_VOID, 30, 12))
        FxExplosion(c);
    FxRingEx(c, 220, 0, 140, 300, 50, 6);
    FxRingEx(c, 255, 255, 255, 200, 20, 5);
    FxLava(c);
    ShakeAll(10, 1.2, 6);
    EmitKeyPos(c, "GRAVITY_WELL");
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(c, po) > 230.0)
            continue;
        PushFrom(p, c, 420.0, 300.0);
        FadeOne(p, 220, 0, 140, 160, 0.8);
        BossHurt(p, BskDmg(2), DMG_BLAST);
    }
}

// Faz 3 - OLAY UFKU (ulti): 6 sn tutulma; boss gorunmez olur, herkesi ceker
bool:Bsk_VoidHorizon()
{
    new Float:bo[3];
    get_entvar(g_iBoss, var_origin, bo);
    BossEclipse(bo);
    g_fEclipseEnd = get_gametime() + 6.0;
    StartChannel(CH_HORIZON, 6.0);
    ZoneSpawn(bo, BskRad(3), 220, 0, 140, 6.0, g_iBoss, false);
    return true;
}

/* ---------------- Mermiler (enerji kuresi, asit, bosluk oku) ---------------- */

ProjSpawn(type, const Float:o[3], const Float:vel[3], r, g, b, Float:scale, Float:life, movetype, Float:gravity)
{
    new ent = rg_create_entity("info_target");
    if (is_nullent(ent))
        return 0;

    set_entvar(ent, var_classname, PROJ_CLASS);
    if (g_szSprOrb[0])
    {
        engfunc(EngFunc_SetModel, ent, g_szSprOrb);
        set_entvar(ent, var_rendermode, kRenderTransAdd);
        set_entvar(ent, var_renderamt, 255.0);
        new Float:c[3];
        c[0] = float(r);
        c[1] = float(g);
        c[2] = float(b);
        set_entvar(ent, var_rendercolor, c);
        set_entvar(ent, var_scale, scale);
    }
    set_entvar(ent, var_movetype, movetype);
    set_entvar(ent, var_solid, SOLID_TRIGGER);
    engfunc(EngFunc_SetSize, ent, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0});
    engfunc(EngFunc_SetOrigin, ent, o);
    set_entvar(ent, var_velocity, vel);
    if (gravity > 0.0)
        set_entvar(ent, var_gravity, gravity);
    set_entvar(ent, var_owner, g_iBoss);
    set_entvar(ent, var_iuser1, type);
    set_entvar(ent, var_iuser2, 0);
    set_entvar(ent, var_iuser3, g_iBossSerial);
    set_entvar(ent, var_fuser1, get_gametime() + life);
    set_entvar(ent, var_effects, EF_DIMLIGHT);

    SetTouch(ent, "fw_ProjTouch");
    SetThink(ent, "fw_ProjThink");
    set_entvar(ent, var_nextthink, get_gametime() + 0.05);
    FxTrail(ent, r, g, b);
    return ent;
}

ProjKill(ent)
{
    SetTouch(ent, "");
    SetThink(ent, "");
    set_entvar(ent, var_classname, "vex_removed");
    set_entvar(ent, var_flags, FL_KILLME);
}

public fw_ProjThink(ent)
{
    if (is_nullent(ent))
        return;
    new Float:now = get_gametime();
    new type = get_entvar(ent, var_iuser1);
    if (get_entvar(ent, var_iuser3) != g_iBossSerial || !g_iBoss || !is_user_alive(g_iBoss) || !g_bRoundActive)
    {
        ProjKill(ent);
        return;
    }

    new Float:o[3], Float:po[3];
    get_entvar(ent, var_origin, o);

    if (now >= Float:get_entvar(ent, var_fuser1))
    {
        if (type == PJ_ACID)
            AcidSplash(o, BskRad(1), BskDmg(1));
        else if (type == PJ_VOID)
            FxImplosion(o, 120, 30, 4);
        else
        {
            FxSparks(o);
            FxRingEx(o, 255, 240, 80, 160, 12, 4);
        }
        ProjKill(ent);
        return;
    }

    switch (type)
    {
        case PJ_ORB:
        {
            new tick = get_entvar(ent, var_iuser2) + 1;
            set_entvar(ent, var_iuser2, tick);
            FxLight(o, 255, 240, 80, 18, 2, 10);
            if (tick % 3 == 0)
            {
                new Float:rad = BskRad(1);
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p) || g_bZombie[p])
                        continue;
                    get_entvar(p, var_origin, po);
                    if (get_distance_f(o, po) > rad)
                        continue;
                    FxBeamEx(o, po, g_sprLightning, 255, 240, 80, 22, 50, 2);
                    SlowHuman(p, 0.5);
                    BossHurt(p, BskDmg(1), DMG_SHOCK);
                    if (random_num(1, 3) == 1)
                        EmitKey(p, "ZAP");
                }
            }
            set_entvar(ent, var_nextthink, now + 0.1);
        }
        case PJ_VOID:
        {
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_alive(p) || g_bZombie[p])
                    continue;
                get_entvar(p, var_origin, po);
                if (get_distance_f(o, po) > 52.0)
                    continue;
                VoidBoltHit(ent, p);
                return;
            }
            set_entvar(ent, var_nextthink, now + 0.05);
        }
        default:
            set_entvar(ent, var_nextthink, now + 0.05);
    }
}

VoidBoltHit(ent, p)
{
    new Float:bo[3], Float:po[3], Float:vel[3];
    get_entvar(g_iBoss, var_origin, bo);
    get_entvar(p, var_origin, po);
    new Float:d = floatmax(1.0, get_distance_f(bo, po));
    vel[0] = (bo[0] - po[0]) / d * 750.0;
    vel[1] = (bo[1] - po[1]) / d * 750.0;
    vel[2] = 180.0;
    set_entvar(p, var_velocity, vel);
    FxImplosion(po, 150, 40, 5);
    FxElSmall(po, EL_VOID, 9);
    FxBeamEntPoint(g_iBoss, po, g_sprLightning, 220, 0, 140, 30, 40, 5);
    FadeOne(p, 90, 0, 90, 170, 0.8);
    BossHurt(p, BskDmg(1), DMG_GENERIC);
    client_print(p, print_center, "%L", p, "BSK_PULLED");
    ProjKill(ent);
}

public fw_ProjTouch(ent, other)
{
    if (is_nullent(ent) || other == g_iBoss)
        return;
    new type = get_entvar(ent, var_iuser1);
    new Float:o[3];
    get_entvar(ent, var_origin, o);

    // Oyuncuya / zombiye degmesi: sadece asit ve bosluk oku tepki verir
    if (1 <= other <= g_iMax)
    {
        if (!is_user_alive(other) || g_bZombie[other])
            return;
        if (type == PJ_ACID)
        {
            AcidSplash(o, BskRad(1), BskDmg(1));
            ProjKill(ent);
        }
        else if (type == PJ_VOID)
            VoidBoltHit(ent, other);
        return;
    }

    if (other > 0 && get_entvar(other, var_solid) != SOLID_BSP)
        return;

    switch (type)
    {
        case PJ_ACID:
        {
            AcidSplash(o, BskRad(1), BskDmg(1));
            ProjKill(ent);
        }
        case PJ_VOID:
        {
            FxImplosion(o, 120, 30, 4);
            FxSparks(o);
            ProjKill(ent);
        }
        case PJ_ORB:
        {
            // Duvara carpinca durur, yerinde vizildamaya devam eder
            set_entvar(ent, var_velocity, Float:{0.0, 0.0, 0.0});
            set_entvar(ent, var_movetype, MOVETYPE_NONE);
        }
    }
}

// Iki varlik arasinda takip eden isin (zincirler)
stock BeamEnts(a, b, spr, r, g, bl, width, noise, life)
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMENTS);
    write_short(BeamEntHand(a));
    write_short(b);
    write_short(spr);
    write_byte(0);
    write_byte(0);
    write_byte(life);
    write_byte(width);
    write_byte(noise);
    write_byte(r);
    write_byte(g);
    write_byte(bl);
    write_byte(220);
    write_byte(0);
    message_end();
}

/* ---------------- Havuzlar (asit / yanan zemin) ---------------- */

// tur: 0 = asit (insan erir, zombi iyilesir), 1 = yanan zemin
// tur 2 = magma lav havuzu (sahibi: owner, hasari LavaDamage verir)
AddPool(const Float:o[3], type, Float:life, Float:radius, owner = 0)
{
    new Float:now = get_gametime(), slot = -1, Float:oldest = 999999.0, oldi;
    for (new s = 0; s < sizeof g_fPoolEnd; s++)
    {
        if (g_fPoolEnd[s] < now)
        {
            slot = s;
            break;
        }
        if (g_fPoolEnd[s] < oldest)
        {
            oldest = g_fPoolEnd[s];
            oldi = s;
        }
    }
    if (slot < 0)
        slot = oldi;

    new Float:pos[3];
    FloorAt(o, pos);
    g_fPoolPos[slot] = pos;
    g_fPoolEnd[slot] = now + life;
    g_iPoolType[slot] = type;
    g_fPoolRad[slot] = radius;
    g_iPoolOwner[slot] = owner;

    if (type == 2)
        ZoneSpawn(pos, radius, 255, 90, 0, life, 0, false);
    else if (type == 1)
        ZoneSpawn(pos, radius, 255, 80, 0, life, 0, false);
    else
        ZoneSpawn(pos, radius, 110, 255, 0, life, 0, false);
}

/* ---------------- Boss temizligi ---------------- */

// Boss olunce / round bitince: kanal, mermi, yumurta, alan, gecikmeli vuruslar temizlenir
BossCleanup()
{
    g_iBossSerial++;
    if (g_iBossChannel != CH_NONE)
        EndChannel(false);
    remove_task(TASK_BCHAN);
    g_fBossBuffEnd = 0.0;
    g_fBossEmpower = 0.0;
    for (new i = 0; i < 3; i++)
        g_iBossTethers[i] = 0;

    new ent;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", PROJ_CLASS)) > 0)
        ProjKill(ent);
    ent = 0;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", EGG_CLASS)) > 0)
    {
        SetThink(ent, "");
        set_entvar(ent, var_takedamage, DAMAGE_NO);
        set_entvar(ent, var_classname, "vex_removed");
        set_entvar(ent, var_flags, FL_KILLME);
    }
    RemoveAllZones();
}

// Faz degisince: herkese "boss yeni yetenek ogrendi", bossa "yeni [R] yetenegin"
BossSkillUnlock()
{
    if (!g_iBoss || !is_user_connected(g_iBoss))
        return;

    new key[16], nm[48], name[32];
    formatex(key, charsmax(key), "BSK_%d_%d", g_iBossType, clamp(g_iBossPhase, 1, 3));
    get_user_name(g_iBoss, name, charsmax(name));

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        formatex(nm, charsmax(nm), "%L", p, key);
        client_print_color(p, print_team_red, "%s %L", ChatTag("BSK_UNLOCK_ALL"), p, "BSK_UNLOCK_ALL", name, nm, g_iBossPhase);
    }

    if (!is_user_bot(g_iBoss))
    {
        formatex(nm, charsmax(nm), "%L", g_iBoss, key);
        HudToS(g_iBoss, SL_PERS, CLR_WARN, 3.5, "BSK_UNLOCK_YOU", nm);
        PlayKey(g_iBoss, "SKILL_UNLOCK");
    }
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

// Eski olay adi -> yeni olay adi
stock BossEvMap(const ev[], out[], len)
{
    if (equal(ev, "SPAWN"))        copy(out, len, "INTRO");
    else if (equal(ev, "ROAR"))    copy(out, len, "IDLE");
    else if (equal(ev, "SCREAM"))  copy(out, len, "ATTACK");
    else if (equal(ev, "ABILITY")) copy(out, len, "ATTACK");
    else                           copy(out, len, ev);
}

// B<tip>_<olay> -> B<tip>_<eski olay> -> BOSS_<olay>. Bulunan anahtar 'key'e yazilir.
bool:BossSndKey(const ev[], key[], len)
{
    new path[128], nev[16];
    BossEvMap(ev, nev, charsmax(nev));
    formatex(key, len, "B%d_%s", g_iBossType, nev);
    if (TrieGetString(g_tRes, key, path, charsmax(path)) && path[0])
        return true;
    formatex(key, len, "B%d_%s", g_iBossType, ev);
    if (TrieGetString(g_tRes, key, path, charsmax(path)) && path[0])
        return true;
    formatex(key, len, "BOSS_%s", ev);
    if (TrieGetString(g_tRes, key, path, charsmax(path)) && path[0])
        return true;
    formatex(key, len, "BOSS_%s", nev);
    if (TrieGetString(g_tRes, key, path, charsmax(path)) && path[0])
        return true;
    key[0] = 0;
    return false;
}

// Bossun olay sesi: herkese (2D). Bossa ozel ses calindiysa true.
bool:PlayBossSound(const ev[])
{
    new key[24];
    if (!BossSndKey(ev, key, charsmax(key)))
        return false;
    PlayKey(0, key);
    return (key[0] == 'B' && key[1] != 'O') ? true : false;
}

// Bossun uzerinden (konumlu, varsayilan: herkes duyar)
EmitBossSound(const ev[], Float:attn = ATTN_NONE, Float:vol = VOL_NORM)
{
    if (!g_iBoss || !is_user_connected(g_iBoss))
        return;
    new key[24], path[128];
    if (!BossSndKey(ev, key, charsmax(key)) || !TrieGetString(g_tRes, key, path, charsmax(path)) || containi(path, ".mp3") != -1)
        return;
    EmitSafe(g_iBoss, CHAN_STATIC, path, vol, attn, 0, PITCH_NORM);
}

// Nemesis / Assassin sesi (NEMESIS_<olay> / ASSASSIN_<olay>)
bool:EmitSpecialSound(id, const ev[], chan = CHAN_VOICE, Float:attn = ATTN_NORM, Float:vol = VOL_NORM)
{
    if (!(g_bNemesis[id] || g_bAssassin[id]))
        return false;
    new key[24], path[128];
    formatex(key, charsmax(key), "%s_%s", g_bNemesis[id] ? "NEMESIS" : "ASSASSIN", ev);
    if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0] || containi(path, ".mp3") != -1)
        return false;
    EmitSafe(id, chan, path, vol, attn, 0, PITCH_NORM);
    return true;
}

// Ozel giris sesi (2D, herkese); yoksa genel BOSS_SPAWN
PlaySpecialIntro(bool:assassin)
{
    new path[128];
    new const key[] = "NEMESIS_INTRO";
    new const key2[] = "ASSASSIN_INTRO";
    if (TrieGetString(g_tRes, assassin ? key2 : key, path, charsmax(path)) && path[0])
        PlayKey(0, assassin ? key2 : key);
    else
        PlayKey(0, "BOSS_SPAWN");
}

// Her 0.05 sn: boss adimlari (hiza gore) + boss / nemesis / assassin ara sira hirlama
VoiceTick(id, Float:now)
{
    if (!is_user_alive(id) || !g_bZombie[id] || !(g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id]))
    {
        g_fStepDist[id] = 0.0;
        return;
    }

    // Hirlama (bekleme suresi rastgele)
    if (g_fSndIdle[id] <= 0.0)
        g_fSndIdle[id] = now + random_float(3.0, 6.0);
    else if (now >= g_fSndIdle[id] && g_fBossIntro <= now)
    {
        new Float:lo = floatmax(2.0, get_pcvar_float(g_pBossIdleMin));
        new Float:hi = floatmax(lo, get_pcvar_float(g_pBossIdleMax));
        g_fSndIdle[id] = now + random_float(lo, hi);
        if (g_bBoss[id] && id == g_iBoss)
            EmitBossSound("IDLE", ATTN_NORM, 0.9);
        else
            EmitSpecialSound(id, "IDLE", CHAN_VOICE, ATTN_NORM, 0.9);
    }

    // Adimlar: sadece boss (oyunun kendi ayak sesi kapali)
    if (!g_bBoss[id] || id != g_iBoss)
        return;
    if (!(get_entvar(id, var_flags) & FL_ONGROUND))
        return;
    new Float:v[3];
    get_entvar(id, var_velocity, v);
    new Float:sp = floatsqroot(v[0] * v[0] + v[1] * v[1]);
    if (sp < 50.0)
        return;
    g_fStepDist[id] += sp * 0.05;
    if (g_fStepDist[id] < floatclamp(get_pcvar_float(g_pBossStepDist), 40.0, 400.0))
        return;
    g_fStepDist[id] = 0.0;
    new key[24], path[128];
    if (!BossSndKey("STEP", key, charsmax(key)) || !TrieGetString(g_tRes, key, path, charsmax(path)))
        return;
    new Float:vol = floatclamp(0.55 + sp / 600.0, 0.55, 1.0);
    EmitSafe(id, CHAN_BODY, path, vol, ATTN_NORM, 0, PITCH_NORM - 4 + random(9));
}

// fw_EmitSound: boss / nemesis / assassin icin aci, olum ve saldiri sesleri.
// Donus: -1 = normal isleme devam, digerleri FMRES_*
SpecialVoice(ent, const ev[])
{
    new Float:now = get_gametime();
    new bool:boss = (g_bBoss[ent] && ent == g_iBoss) ? true : false;

    if (equal(ev, "PAIN"))
    {
        if (now >= g_fSndPain[ent])
        {
            g_fSndPain[ent] = now + floatmax(0.2, get_pcvar_float(g_pBossPainCd));
            if (boss)
            {
                g_iPainAlt[ent] = !g_iPainAlt[ent];
                new key[24], path[128];
                if (BossSndKey(g_iPainAlt[ent] ? "PAIN2" : "PAIN", key, charsmax(key)) && TrieGetString(g_tRes, key, path, charsmax(path)))
                    EmitSafe(ent, CHAN_VOICE, path, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
                else if (BossSndKey("PAIN", key, charsmax(key)) && TrieGetString(g_tRes, key, path, charsmax(path)))
                    EmitSafe(ent, CHAN_VOICE, path, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
            }
            else
                EmitSpecialSound(ent, "PAIN");
        }
        return -1;
    }
    if (equal(ev, "DIE"))
    {
        // Boss olumu BossDeath'te (herkese) calinir; ozel karakterin olum sesi rg_PlayerKilled'da
        return FMRES_SUPERCEDE;
    }
    // Pence savurma: saldiri kukremesi (bekleme sureli), pence sesi normal calar
    if (now >= g_fSndAtk[ent])
    {
        g_fSndAtk[ent] = now + floatmax(0.3, get_pcvar_float(g_pBossAtkCd));
        if (boss)
        {
            new key[24], path[128];
            if (BossSndKey("ATTACK", key, charsmax(key)) && TrieGetString(g_tRes, key, path, charsmax(path)))
                EmitSafe(ent, CHAN_VOICE, path, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        }
        else
            EmitSpecialSound(ent, "ATTACK");
    }
    return -1;
}

// Boss bir insani oldurdu: alay (herkes duyar, 4 sn bekleme)
BossKillTaunt(attacker)
{
    if (!g_bBoss[attacker] || attacker != g_iBoss)
        return;
    new Float:now = get_gametime();
    if (now < g_fSndKill)
        return;
    g_fSndKill = now + 4.0;
    EmitBossSound("KILL");
}

VoiceReset(id)
{
    g_fSndIdle[id] = 0.0;
    g_fSndPain[id] = 0.0;
    g_fSndAtk[id] = 0.0;
    g_fStepDist[id] = 0.0;
    g_iPainAlt[id] = 0;
}
