/* ================================================================== */
/*  Vexmira Zombie - modul: vex/hud.inc  (HUD)                        */
/*  HUD paneli, nisan bilgisi, sirali buyuk yazi yuvalari, chat       */
/*  ciktisi (Chat / ChatAll / Translate), boss bari, kafa ustu        */
/*  barlar ve ikonlar (AddToFullPack), izleyici bilgisi.              */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  EKONOMI: XP / LEVEL / AP / VC / BASARIM                            */
/* ================================================================== */

ChatKeyName(id, const msgKey[], const prefix[], idx)
{
    new key[16], nm[48];
    formatex(key, charsmax(key), "%s%d", prefix, idx);
    formatex(nm, charsmax(nm), "%L", id, key);
    Chat(id, msgKey, nm);
}


/* ================================================================== */
/*  HUD                                                                */
/* ================================================================== */

// Panel konumlari (ayarlardan secilir): sag-orta, sol-orta, sol-ust, sag-ust, alt-orta
new const Float:HUDPOS_X[NUM_HUDPOS] = { 0.76, 0.015, 0.015, 0.76, -1.0 };
new const Float:HUDPOS_Y[NUM_HUDPOS] = { 0.40, 0.33,  0.20,  0.12,  0.80 };

DrawHud()
{
    new humans = CountHumans(true), zombies = CountZombies(true);
    new total = RoundsTotal();
    new bool:top = (g_iFrame % 2 == 0) ? true : false;
    new toBoss = RoundsToBoss();

    new l1[96], l2[96], l3[96], l4[96], l5[96], head[96];
    new tname[32], key[16], ev[32], mn[32], cn[32], lineC[96];

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_bot(id))
            continue;

        new t = g_iTheme[id];

        // ---------- Ust bilgi: 3 satir, 2 renk, 2 saniyede bir ----------
        if (top)
        {
            formatex(key, charsmax(key), "MODE_NAME_%d", g_iMode);
            formatex(mn, charsmax(mn), "%L", id, key);
            if (g_iMode == MODE_BOSS)
            {
                formatex(key, charsmax(key), "BOSS_NAME_%d", g_iBossType);
                formatex(ev, charsmax(ev), "%L", id, key);
            }
            else
            {
                formatex(key, charsmax(key), "EV_NAME_%d", g_iEvent);
                formatex(ev, charsmax(ev), "%L", id, key);
            }

            if (g_iRound >= total)
                formatex(lineC, charsmax(lineC), "%L", id, "TOP_C_FINAL", mn, ev);
            else if (toBoss > 0 && toBoss <= 3 && g_iMode != MODE_BOSS)
                formatex(lineC, charsmax(lineC), "%L", id, "TOP_C_BOSSIN", mn, ev, toBoss);
            else
                formatex(lineC, charsmax(lineC), "%L", id, "TOP_C", mn, ev);

            if (g_iMode == MODE_BOSS && g_iBoss)
            {
                // Boss roundunda tek yazi (boss gostergesi de buyuk yazi kullaniyor)
                set_dhudmessage(THEME_A[t][0], THEME_A[t][1], THEME_A[t][2], -1.0, Y_TOPBAR, 0, 0.0, 2.0, 0.0, 0.0);
                show_dhudmessage(id, "%L^n%L^n%s", id, "TOP_A", g_iRound, total, id, "TOP_B_BOSS", humans, lineC);
            }
            else
            {
                set_dhudmessage(THEME_A[t][0], THEME_A[t][1], THEME_A[t][2], -1.0, Y_TOPBAR, 0, 0.0, 2.0, 0.0, 0.0);
                show_dhudmessage(id, "%L^n^n%s", id, "TOP_A", g_iRound, total, lineC);

                set_dhudmessage(THEME_B[t][0], THEME_B[t][1], THEME_B[t][2], -1.0, Y_TOPBAR, 0, 0.0, 2.0, 0.0, 0.0);
                show_dhudmessage(id, "^n%L", id, "TOP_B", zombies, humans);
            }
        }

        // ---------- Nisan alinan / izlenen oyuncu ----------
        if (is_user_alive(id))
            DrawAimInfo(id);
        else
            DrawSpecInfo(id);

        if (g_iSet[id] & SET_NO_HUD)
            continue;

        // ---------- Kisisel panel: baslik (tema) + govde (acik ton) ----------
        new lvl = g_iLevel[id];
        new base = XPForLevel(lvl);
        new need = XPForLevel(lvl + 1);
        new xpPct = (lvl >= MAX_LEVEL) ? 100 : clamp((g_iXP[id] - base) * 100 / max(1, need - base), 0, 100);

        TitleName(id, id, tname, charsmax(tname));
        if (g_iTopRank[id] > 0)
            formatex(head, charsmax(head), "%L", id, "HUD_P1R", lvl, tname, g_iTopRank[id]);
        else
            formatex(head, charsmax(head), "%L", id, "HUD_P1", lvl, tname);

        if (is_user_alive(id))
            formatex(l1, charsmax(l1), "%L", id, "HUD_P_HP", floatround(Float:get_entvar(id, var_health)), rg_get_user_armor(id));
        else
            formatex(l1, charsmax(l1), "%L", id, "HUD_P_DEAD");

        // XP cubugu (ASCII, 12 parca)
        new xbar[16];
        AsciiBar(xbar, 12, xpPct);
        formatex(l2, charsmax(l2), "%L", id, "HUD_P2", xbar, g_iXP[id], need);
        formatex(l3, charsmax(l3), "%L", id, "HUD_P3", g_iAP[id], g_iVC[id], g_iStreak[id]);

        l4[0] = 0;
        if (is_user_alive(id))
        {
            if (g_bZombie[id] && !g_bBoss[id] && !g_bMinion[id] && !g_bNemesis[id] && !g_bAssassin[id])
            {
                formatex(key, charsmax(key), "CLASS_%d", g_iClass[id]);
                formatex(cn, charsmax(cn), "%L", id, key);
                if (g_bAlpha[id])
                    add(cn, charsmax(cn), " [ALFA]");
                new Float:cd = g_fCool[id] - get_gametime();
                new Float:act = ZcActiveLeft(id);
                if (act > 0.0)
                    formatex(l4, charsmax(l4), "%L", id, "HUD_CLASS_ACT", cn, floatround(act, floatround_ceil));
                else if (cd > 0.0)
                    formatex(l4, charsmax(l4), "%L", id, "HUD_CLASS_CD", cn, floatround(cd, floatround_ceil));
                else
                    formatex(l4, charsmax(l4), "%L", id, "HUD_CLASS_READY", cn);
            }
            else if (g_bBoss[id])
            {
                // [R] faz yetenegi + [F] atilma
                new sk[16], skn[40], rs[24], fs[24];
                formatex(sk, charsmax(sk), "BSK_%d_%d", g_iBossType, clamp(g_iBossPhase, 1, 3));
                formatex(skn, charsmax(skn), "%L", id, sk);
                CdText(id, g_iBossChannel != CH_NONE ? -1.0 : g_fBossRCool - get_gametime(), rs, charsmax(rs));
                CdText(id, g_fLeapCool[id] - get_gametime(), fs, charsmax(fs));
                formatex(l4, charsmax(l4), "%L", id, "HUD_BOSS_R", skn, rs, fs);
            }
            else if (g_bNemesis[id] || g_bAssassin[id])
            {
                new rs[24], fs[24];
                CdText(id, g_fLeapCool[id] - get_gametime(), rs, charsmax(rs));
                CdText(id, g_fFCool[id] - get_gametime(), fs, charsmax(fs));
                formatex(l4, charsmax(l4), "%L", id, g_bNemesis[id] ? "HUD_NEM_RF" : "HUD_ASN_RF", rs, fs);
            }
            else if (!g_bZombie[id])
            {
                formatex(key, charsmax(key), "JOB_%d", g_iJob[id]);
                formatex(cn, charsmax(cn), "%L", id, key);
                if (LasersAllowed())
                    formatex(l4, charsmax(l4), "%L", id, "HUD_JOB_LM", cn, g_iMines[id], CountMines(id));
                else
                    formatex(l4, charsmax(l4), "%L", id, "HUD_JOB", cn);
            }
        }

        QuestLine(id, l5, charsmax(l5));
        if (is_user_alive(id) && !g_bZombie[id])
        {
            new cmp[64];
            if (DropCompass(id, cmp, charsmax(cmp)))
            {
                if (l5[0])
                    format(l5, charsmax(l5), "%s^n%s", l5, cmp);
                else
                    copy(l5, charsmax(l5), cmp);
            }
        }

        new pos = g_iHudPos[id];

        // v3.0 renkler: insan = tema, zombi = zombi yesili, boss = boss rengi, nemesis/assassin = tehlike
        new hr = THEME_A[t][0], hg = THEME_A[t][1], hb = THEME_A[t][2];
        new br = THEME_C[t][0], bg = THEME_C[t][1], bb = THEME_C[t][2];
        if (is_user_alive(id) && g_bZombie[id])
        {
            if (g_bBoss[id])
            {
                hr = BOSS_RGB[g_iBossType][0]; hg = BOSS_RGB[g_iBossType][1]; hb = BOSS_RGB[g_iBossType][2];
                br = 255; bg = 200; bb = 170;
            }
            else if (g_bNemesis[id] || g_bAssassin[id])
            {
                hr = 255; hg = 40; hb = 40;
                br = 255; bg = 170; bb = 150;
            }
            else
            {
                hr = 120; hg = 255; hb = 40;
                br = 195; bg = 255; bb = 160;
            }
        }

        set_hudmessage(hr, hg, hb, HUDPOS_X[pos], HUDPOS_Y[pos], 0, 0.0, 1.1, 0.0, 0.0, 1);
        show_hudmessage(id, "%s", head);

        set_hudmessage(br, bg, bb, HUDPOS_X[pos], HUDPOS_Y[pos], 0, 0.0, 1.1, 0.0, 0.0, 2);
        show_hudmessage(id, "^n%s^n%s^n%s^n%s^n%s", l1, l2, l3, l4, l5);
    }
}

// Nisan alinan oyuncunun adi, cani, sinifi / meslegi
DrawAimInfo(id)
{
    if (MineAimInfo(id))
        return;

    new target, body;
    get_user_aiming(id, target, body, 3000);

    if (!(1 <= target <= g_iMax) || !is_user_alive(target))
        return;
    // v3.0: yeraltindaki Kostebek gorunmez
    if (g_bZombie[target] && g_fBurrow[target] > get_gametime())
        return;

    new name[32], role[32], key[16];
    get_user_name(target, name, charsmax(name));
    new hp = floatround(Float:get_entvar(target, var_health));

    // v3.0: kiliktaki Taklitci insan gibi gorunur
    if (g_bZombie[target] && g_fDisguise[target] > get_gametime() && !g_bZombie[id])
    {
        formatex(role, charsmax(role), "%L", id, "JOB_0");
        set_hudmessage(CLR_HUMAN, -1.0, Y_AIM, 0, 0.0, 0.9, 0.0, 0.1, 3);
        show_hudmessage(id, "%L", id, "HUD_AIM", name, role, 100, 0, g_iLevel[target]);
        return;
    }

    if (g_bBoss[target])           copy(role, charsmax(role), "BOSS");
    else if (g_bNemesis[target])   copy(role, charsmax(role), "NEMESIS");
    else if (g_bAssassin[target])  copy(role, charsmax(role), "ASSASSIN");
    else if (g_bSurvivor[target])  copy(role, charsmax(role), "SURVIVOR");
    else if (g_bSniper[target])    copy(role, charsmax(role), "SNIPER");
    else if (g_bZombie[target])
    {
        formatex(key, charsmax(key), "CLASS_%d", g_bMinion[target] ? 0 : g_iClass[target]);
        formatex(role, charsmax(role), "%L", id, key);
    }
    else
    {
        formatex(key, charsmax(key), "JOB_%d", g_iJob[target]);
        formatex(role, charsmax(role), "%L", id, key);
    }

    if (g_bBoss[target])
        set_hudmessage(BOSS_RGB[g_iBossType][0], BOSS_RGB[g_iBossType][1], BOSS_RGB[g_iBossType][2], -1.0, Y_AIM, 0, 0.0, 0.9, 0.0, 0.1, 3);
    else if (g_bNemesis[target] || g_bAssassin[target])
        set_hudmessage(CLR_DANGER, -1.0, Y_AIM, 0, 0.0, 0.9, 0.0, 0.1, 3);
    else if (g_bZombie[target])
        set_hudmessage(CLR_ZOMBIE, -1.0, Y_AIM, 0, 0.0, 0.9, 0.0, 0.1, 3);
    else
        set_hudmessage(CLR_HUMAN, -1.0, Y_AIM, 0, 0.0, 0.9, 0.0, 0.1, 3);

    show_hudmessage(id, "%L", id, "HUD_AIM", name, role, hp, rg_get_user_armor(target), g_iLevel[target]);
}


/* ================================================================== */
/*  FX / YARDIMCILAR                                                   */
/* ================================================================== */

/* ---------------- Buyuk yazi yuvalari (DHUD sirasi) ----------------
   Oyun istemcisi ayni anda en fazla 8 buyuk yazi tutabiliyor ve ayni yere
   gelen iki yazi ic ice giriyor. Bu yuzden her yazi turunun sabit bir satiri
   (yuva) var; yuva doluysa yeni yazi sirada bekler ve bosalinca gosterilir. */

new const Float:SLOT_Y[NUM_SLOTS] = { Y_ANN, Y_ALERT, Y_PERS, Y_KILL, Y_REWARD };

stock HudDraw(id, slot, r, g, b, Float:hold, const text[])
{
    set_dhudmessage(r, g, b, -1.0, SLOT_Y[slot], 0, 0.0, hold, 0.08, 0.35);
    show_dhudmessage(id, "%s", text);
    g_fSlotEnd[id][slot] = get_gametime() + hold + 0.5;
}

stock HudText(id, slot, r, g, b, Float:hold, const text[])
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    if (get_gametime() >= g_fSlotEnd[id][slot])
    {
        g_szSlotQ[id][slot][0] = 0;
        HudDraw(id, slot, r, g, b, hold, text);
        return;
    }

    // Yuva dolu: en yeni mesaj sirada bekler (bayatlarsa atilir)
    copy(g_szSlotQ[id][slot], charsmax(g_szSlotQ[][]), text);
    g_iSlotQC[id][slot] = (r << 16) | (g << 8) | b;
    g_fSlotQH[id][slot] = hold;
    g_fSlotQT[id][slot] = get_gametime();
}

// Sirada en fazla ne kadar bekleyebilir (sn): uyari/odul anlik, duyuru daha uzun
stock Float:SlotMaxWait(slot)
{
    switch (slot)
    {
        case SL_ANN:  return 5.0;
        case SL_PERS: return 4.0;
        case SL_ALERT: return 1.5;
    }
    return 1.0;
}

public task_HudQueue()
{
    new Float:now = get_gametime();
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
            continue;
        for (new s = 0; s < NUM_SLOTS; s++)
        {
            if (!g_szSlotQ[id][s][0] || now < g_fSlotEnd[id][s])
                continue;
            if (now - g_fSlotQT[id][s] > SlotMaxWait(s))
            {
                g_szSlotQ[id][s][0] = 0;
                continue;
            }
            new c = g_iSlotQC[id][s];
            HudDraw(id, s, (c >> 16) & 255, (c >> 8) & 255, c & 255, g_fSlotQH[id][s], g_szSlotQ[id][s]);
            g_szSlotQ[id][s][0] = 0;
        }
    }
}

stock HudReset(id)
{
    for (new s = 0; s < NUM_SLOTS; s++)
    {
        g_fSlotEnd[id][s] = 0.0;
        g_szSlotQ[id][s][0] = 0;
    }
}

// Ceviri anahtari -> yuva. Baslik satiri buyuk duyurularda susle cevrilir.
stock HudTo(id, slot, r, g, b, Float:hold, const key[], iVal = 0)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    new text[160], out[160];
    formatex(text, charsmax(text), "%L", id, key, iVal);
    HudDecorate(slot, text, out, charsmax(out));
    HudText(id, slot, r, g, b, hold, out);
}

stock HudToS(id, slot, r, g, b, Float:hold, const key[], const sVal[])
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    new text[160], out[160];
    formatex(text, charsmax(text), "%L", id, key, sVal);
    HudDecorate(slot, text, out, charsmax(out));
    HudText(id, slot, r, g, b, hold, out);
}

stock HudAll(slot, r, g, b, Float:hold, const key[], iVal = 0)
{
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id) && !is_user_bot(id))
            HudTo(id, slot, r, g, b, hold, key, iVal);
    }
}

stock HudAllS(slot, r, g, b, Float:hold, const key[], const sVal[])
{
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id) && !is_user_bot(id))
            HudToS(id, slot, r, g, b, hold, key, sVal);
    }
}

stock HudDecorate(slot, const text[], out[], len)
{
    new nl = contain(text, "^n");
    if (slot != SL_ANN && slot != SL_ALERT)
    {
        copy(out, len, text);
        return;
    }
    if (nl == -1)
    {
        formatex(out, len, "-=[  %s  ]=-", text);
        return;
    }
    new title[96];
    copy(title, min(nl, charsmax(title)), text);
    formatex(out, len, "-=[  %s  ]=-^n%s", title, text[nl + 1]);
}

// "BRUTE" -> "B R U T E"
stock SpaceOut(const src[], dst[], len)
{
    new j;
    for (new i = 0; src[i] && j < len - 2; i++)
    {
        if (i)
            dst[j++] = ' ';
        dst[j++] = src[i];
    }
    dst[j] = 0;
}

// Can yuzdesine gore renk: yesil -> sari -> turuncu -> kirmizi
stock HpColor(pct, &r, &g, &b)
{
    if (pct > 66)      { r = 80;  g = 255; b = 120; }
    else if (pct > 40) { r = 230; g = 230; b = 60; }
    else if (pct > 20) { r = 255; g = 140; b = 30; }
    else               { r = 255; g = 40;  b = 40; }
}

// Ham ceviri (bicimlendirme yapmadan). "%L" + vformat kullanmak hataya
// yol aciyordu: %L, ceviri icindeki %s/%d'leri de doldurmaya calisiyor.
stock Translate(out[], len, const key[], id)
{
    new target = id;
    if (!LookupLangKey(out, len, key, target))
        copy(out, len, key);
}

// v2.0: mesaj turune gore ozel vurgu rengi (^3): boss / zombi = KIRMIZI,
// lazer / ikmal / insan = MAVI, bilgi / ipucu = GRI, diger = takim rengi
stock ChatColorFor(const key[])
{
    if (equal(key, "BOSS", 4) || equal(key, "BSK", 3) || equal(key, "NEM", 3) || equal(key, "ROLE", 4)
        || equal(key, "ZOMBIE", 6) || equal(key, "YOU_INFECTED", 12) || equal(key, "LIVE_Z", 6)
        || equal(key, "FINAL", 5) || equal(key, "ASSASSIN", 8) || equal(key, "NEMESIS", 7) || equal(key, "LAST_HUMAN", 10)
        || equal(key, "ADM", 3))
        return print_team_red;
    if (equal(key, "LM_", 3) || equal(key, "AIRDROP", 7) || equal(key, "LOOT", 4) || equal(key, "ANTIDOTE", 8)
        || equal(key, "QUEST", 5) || equal(key, "LIVE_H", 6) || equal(key, "SPEED", 5) || equal(key, "VIP", 3))
        return print_team_blue;
    if (equal(key, "ADV_", 4) || equal(key, "HELP", 4) || equal(key, "PLAN", 4) || equal(key, "MODE_DESC", 9)
        || equal(key, "NMODE", 5) || equal(key, "AFK", 3) || equal(key, "STORM", 5) || equal(key, "BLACKOUT", 8))
        return print_team_grey;
    return print_team_default;
}

stock Chat(id, const key[], any:...)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    new fmt[191], msg[191];
    Translate(fmt, charsmax(fmt), key, id);
    vformat(msg, charsmax(msg), fmt, 3);
    client_print_color(id, ChatColorFor(key), "%s %s", ChatTag(key), msg);
}

stock ChatAll(const key[], iVal = 0)
{
    new c = ChatColorFor(key);
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id) && !is_user_bot(id))
            client_print_color(id, c, "%s %L", ChatTag(key), id, key, iVal);
    }
}

stock ChatAllS(const key[], const sVal[])
{
    new c = ChatColorFor(key);
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id) && !is_user_bot(id))
            client_print_color(id, c, "%s %L", ChatTag(key), id, key, sVal);
    }
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

// Ust kisimda buyuk, renkli boss can gostergesi (v3.0 tasarim, TEK buyuk yazi):
//   B R U T E   ::   PHASE  [ I ]  II  III
//   [||||||||||||||||||||||||||||..........]   64%
//   HP  12840 / 20000
// Renk: can azaldikca turuncudan kirmiziya; ofke modunda kirmizi / beyaz yanip soner.
// Istemci en fazla 8 buyuk yazi tutabildigi icin isim + faz + bar + can tek mesajdadir.
BossHud(hp, pct)
{
    new key[16], nm[32], spaced[64], ph[48], bar[48], hl[48], tag[32];
    pct = clamp(pct, 0, 100);
    new hr = 255, hg = 40 + 130 * pct / 100, hb = 0;
    if (g_bEnraged && g_iFrame % 2)
    {
        hr = 255; hg = 210; hb = 210;
    }
    else if (g_bEnraged)
    {
        hr = 255; hg = 40; hb = 40;
    }
    formatex(key, charsmax(key), "BOSS_NAME_%d", g_iBossType);
    AsciiBar(bar, 40, pct);

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_bot(id))
            continue;

        formatex(nm, charsmax(nm), "%L", id, key);
        SpaceOut(nm, spaced, charsmax(spaced));
        formatex(ph, charsmax(ph), "%L", id, g_bEnraged ? "BOSS_PH_RAGE" : (g_iBossPhase >= 3 ? "BOSS_PH_3" : (g_iBossPhase == 2 ? "BOSS_PH_2" : "BOSS_PH_1")));
        formatex(hl, charsmax(hl), "%L", id, "BOSS_HPLINE", hp, g_iBossMaxHP);
        tag[0] = 0;
        if (g_bFinalBoss)
            formatex(tag, charsmax(tag), "%L  ::  ", id, "FINAL_BOSS_TAG");

        set_dhudmessage(hr, hg, hb, -1.0, Y_BOSS, 0, 0.0, 1.05, 0.0, 0.0);
        show_dhudmessage(id, "%s%s   ::   %s^n[%s]   %d%%^n%s", tag, spaced, ph, bar, pct, hl);
    }
}

// ASCII ilerleme cubugu: dolu '|' / bos '.' (HUD'da UTF-8 yok)
stock AsciiBar(out[], segs, pct)
{
    segs = clamp(segs, 1, 46);
    new full = clamp((pct * segs + 50) / 100, 0, segs);
    if (pct > 0 && full == 0)
        full = 1;
    for (new i = 0; i < segs; i++)
        out[i] = (i < full) ? '|' : '.';
    out[segs] = 0;
}

// Bekleme suresi yazisi: "HAZIR" / "5 sn" / "AKTIF"
CdText(id, Float:cd, out[], len)
{
    if (cd < -0.5)
        formatex(out, len, "%L", id, "HUD_ACTIVE");
    else if (cd > 0.0)
        formatex(out, len, "%L", id, "HUD_SECONDS", floatround(cd, floatround_ceil));
    else
        formatex(out, len, "%L", id, "HUD_READY");
}


/* ================================================================== */
/*  KOZMETIK (Vex Coin ile kalici): iz, oldurme efekti, enfeksiyon     */
/*  efekti. TUM ZAMANLARIN SIRALAMASI (ilk 15) + stil kartlari.        */
/*  IZLEYICI BILGISI: olu oyuncu izledigi kisinin bilgisini gorur.     */
/* ================================================================== */

/* ---------------- Izleyici bilgisi ---------------- */

DrawSpecInfo(id)
{
    new target = get_entvar(id, var_iuser2);
    if (!(1 <= target <= g_iMax) || target == id || !is_user_alive(target))
        return;

    new name[32], role[32], key[16];
    get_user_name(target, name, charsmax(name));

    if (g_bBoss[target])
    {
        formatex(key, charsmax(key), "BOSS_NAME_%d", g_iBossType);
        formatex(role, charsmax(role), "%L", id, key);
    }
    else if (g_bNemesis[target])   copy(role, charsmax(role), "NEMESIS");
    else if (g_bAssassin[target])  copy(role, charsmax(role), "ASSASSIN");
    else if (g_bSurvivor[target])  copy(role, charsmax(role), "SURVIVOR");
    else if (g_bSniper[target])    copy(role, charsmax(role), "SNIPER");
    else if (g_bZombie[target])
    {
        formatex(key, charsmax(key), "CLASS_%d", g_bMinion[target] ? 0 : g_iClass[target]);
        formatex(role, charsmax(role), "%L", id, key);
    }
    else
    {
        formatex(key, charsmax(key), "JOB_%d", g_iJob[target]);
        formatex(role, charsmax(role), "%L", id, key);
    }

    if (g_bZombie[target])
        set_hudmessage(CLR_ZOMBIE, -1.0, 0.70, 0, 0.0, 1.1, 0.0, 0.0, 3);
    else
        set_hudmessage(CLR_HUMAN, -1.0, 0.70, 0, 0.0, 1.1, 0.0, 0.0, 3);
    show_hudmessage(id, "%L", id, "SPEC_INFO", name, g_iLevel[target], role, floatround(Float:get_entvar(target, var_health)), rg_get_user_armor(target), g_iAP[target]);
}


/* ================================================================== */
/*  v3.0 (B)  KAFA USTU GOSTERGELER                                    */
/*  - Boss: oyunlardaki gibi buyuk can bari (bossbar.spr, 51 kare) +   */
/*    ustunde boss amblemi (bossicon.spr, kare = boss no). Herkes      */
/*    gorur; bossun kendisi gormez (vex_overhead_self 0).              */
/*  - Nemesis / Assassin / Alfa zombi: kucuk can bari (hpbar_small).   */
/*  - Ikonlar: VIP / admin / round MVP'si / son insan / alfa zombi     */
/*    (vex_head_icons bit maskesi: 1 VIP 2 admin 4 MVP 8 son insan     */
/*    16 alfa).                                                        */
/*  Konum: FOLLOW YOK (istemci FOLLOW sprite'ini govde merkezine        */
/*  cizer). AddToFullPack her pakette konumu oyuncunun o anki konumu + */
/*  modelin kafa ustu yuksekligi (studio basligi / idle1, comelince    */
/*  crouch_idle) + yigin ofseti (bar -> amblem -> ikon) yapar; varlik  */
/*  MOVETYPE_NOCLIP oldugu icin istemci onu oyuncuyla ayni gecikmeyle  */
/*  yumusatir. Kare / gorunurluk 0.05 sn'de bir guncellenir. Olum,     */
/*  rol degisimi, round sonu, cikis ve harita degisiminde silinir.     */
/*  Sprite dosyasi yoksa o gosterge sessizce kapali kalir.             */
/* ================================================================== */

#define OVH_ICONBIT_VIP   1
#define OVH_ICONBIT_ADMIN 2
#define OVH_ICONBIT_MVP   4
#define OVH_ICONBIT_LAST  8
#define OVH_ICONBIT_ALPHA 16

#define OVH_MAGIC 0x56584F48   // var_iuser2 isareti: varlik gercekten bizim gostergemiz mi?


// Kayitli gosterge hala bizim mi? (silinip indeksi baska varliga gecmis olabilir)
bool:OvhValid(ent, id)
{
    return (ent > g_iMax && !is_nullent(ent) && get_entvar(ent, var_iuser2) == OVH_MAGIC && get_entvar(ent, var_iuser1) == id) ? true : false;
}

OvhInit()
{
    for (new id = 0; id <= 32; id++)
    {
        g_iOvhBar[id] = 0; g_iOvhEmb[id] = 0; g_iOvhIcon[id] = 0;
        g_iOvhBarType[id] = -1; g_iOvhIconType[id] = -1;
    }
    g_iOvhCount = 0;
    new ent = rg_create_entity("info_target");
    if (is_nullent(ent))
    {
        g_iOvhCtl = 0;
        return;
    }
    set_entvar(ent, var_classname, OVH_CTL_CLASS);
    set_entvar(ent, var_solid, SOLID_NOT);
    set_entvar(ent, var_movetype, MOVETYPE_NONE);
    set_entvar(ent, var_effects, EF_NODRAW);
    SetThink(ent, "fw_OvhThink");
    set_entvar(ent, var_nextthink, get_gametime() + 1.0);
    g_iOvhCtl = ent;
}

public fw_OvhThink(ent)
{
    if (ent != g_iOvhCtl || is_nullent(ent))
        return;

    new Float:now = get_gametime();
    set_entvar(ent, var_nextthink, now + 0.05);
    g_iOvhTick++;

    new bool:on = get_pcvar_num(g_pOvhEnable) ? true : false;
    g_bOvhSelf = get_pcvar_num(g_pOvhSelf) ? true : false;
    if (g_iOvhTick % 5 == 0)
        g_iOvhHumans = (g_bRoundActive && !g_bRoundEnded) ? CountHumans(true) : 0;

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
        {
            if (g_iOvhBar[id] || g_iOvhEmb[id] || g_iOvhIcon[id])
                OvhRemove(id);
            continue;
        }
        // Rol / ikon secimi 0.25 sn'de bir (oyuncular arasi dagitilmis)
        if ((g_iOvhTick + id) % 5 == 0)
            OvhRefresh(id, on);
        // Kare / yigin / sunucu konumu: oyuncu basina 0.1 sn (cizim konumu her pakette AddToFullPack'te)
        if ((g_iOvhTick + id) % 2 == 0 && (g_iOvhBar[id] || g_iOvhEmb[id] || g_iOvhIcon[id]))
            OvhUpdate(id);
        if (g_bZombie[id] && (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id]))
            VoiceTick(id, now);
        else
            g_fStepDist[id] = 0.0;
    }
}

// Gerekli gostergeleri olustur / gereksizleri sil
OvhRefresh(id, bool:on)
{
    new barType = -1, icon = -1;
    new bool:alive = is_user_alive(id) ? true : false;
    if (on && alive && !OvhHidden(id))
    {
        if (!g_bRoundEnded)
        {
            if (g_bBoss[id] && g_iBoss == id && g_szOvhSpr[OVS_BOSSBAR][0])
                barType = OVS_BOSSBAR;
            else if ((g_bNemesis[id] || g_bAssassin[id] || (g_bZombie[id] && g_bAlpha[id])) && g_szOvhSpr[OVS_SMALLBAR][0])
                barType = OVS_SMALLBAR;
        }
        if (!g_bBoss[id])
            icon = OvhIconFor(id);
    }

    // Can bari
    if (barType != g_iOvhBarType[id] || (g_iOvhBar[id] && !OvhValid(g_iOvhBar[id], id)))
    {
        OvhKill(g_iOvhBar[id]);
        g_iOvhSent[id] = -1;
        g_iOvhBar[id] = 0;
        g_iOvhBarType[id] = -1;
        if (barType >= 0)
        {
            new Float:w = get_pcvar_float(barType == OVS_BOSSBAR ? g_pBossBarW : g_pSmallBarW);
            g_iOvhBar[id] = OvhSpawn(id, barType, floatclamp(w, 8.0, 400.0) / float(g_iOvhWidth[barType]));
            if (g_iOvhBar[id])
                g_iOvhBarType[id] = barType;
        }
    }

    // Boss amblemi (barin ustunde)
    new bool:wantEmb = (barType == OVS_BOSSBAR && g_szOvhSpr[OVS_BOSSICON][0]) ? true : false;
    if (g_iOvhEmb[id] && (!wantEmb || !OvhValid(g_iOvhEmb[id], id)))
    {
        OvhKill(g_iOvhEmb[id]);
        g_iOvhSent[id] = -1;
        g_iOvhEmb[id] = 0;
    }
    if (wantEmb && !g_iOvhEmb[id])
    {
        new sz = max(g_iOvhWidth[OVS_BOSSICON], g_iOvhHeight[OVS_BOSSICON]);
        g_iOvhEmb[id] = OvhSpawn(id, OVS_BOSSICON, 28.0 / float(max(1, sz)));
        if (g_iOvhEmb[id])
            set_entvar(g_iOvhEmb[id], var_frame, float(clamp(g_iBossType, 0, g_iOvhFrames[OVS_BOSSICON] - 1)));
    }

    // Ikon
    if (icon != g_iOvhIconType[id] || (g_iOvhIcon[id] && !OvhValid(g_iOvhIcon[id], id)))
    {
        OvhKill(g_iOvhIcon[id]);
        g_iOvhSent[id] = -1;
        g_iOvhIcon[id] = 0;
        g_iOvhIconType[id] = -1;
        if (icon >= 0)
        {
            new sz = max(g_iOvhWidth[icon], g_iOvhHeight[icon]);
            g_iOvhIcon[id] = OvhSpawn(id, icon, floatclamp(get_pcvar_float(g_pIconSize), 6.0, 64.0) / float(max(1, sz)));
            if (g_iOvhIcon[id])
                g_iOvhIconType[id] = icon;
        }
    }
}

// Oncelik: son insan > MVP > alfa > admin > VIP
OvhIconFor(id)
{
    new bits = get_pcvar_num(g_pIcons);
    if (!bits)
        return -1;
    if ((bits & OVH_ICONBIT_LAST) && g_szOvhSpr[OVS_LAST][0] && !g_bZombie[id] && g_iOvhHumans == 1)
        return OVS_LAST;
    if ((bits & OVH_ICONBIT_MVP) && g_szOvhSpr[OVS_MVP][0] && g_iRoundMvp == id)
        return OVS_MVP;
    if ((bits & OVH_ICONBIT_ALPHA) && g_szOvhSpr[OVS_ALPHA][0] && g_bZombie[id] && g_bAlpha[id])
        return OVS_ALPHA;
    if (g_bNemesis[id] || g_bAssassin[id] || g_bMinion[id])
        return -1;
    new flags = get_user_flags(id);
    if ((bits & OVH_ICONBIT_ADMIN) && g_szOvhSpr[OVS_ADMIN][0] && (flags & ADMIN_BAN))
        return OVS_ADMIN;
    if ((bits & OVH_ICONBIT_VIP) && g_szOvhSpr[OVS_VIP][0] && IsVip(id))
        return OVS_VIP;
    return -1;
}

// Gorunmez / gizli oyuncunun ustunde gosterge olmaz (kilik, yeralti, gorunmezlik)
bool:OvhHidden(id)
{
    new Float:now = get_gametime();
    if (g_bZombie[id] && (g_fBurrow[id] > now || g_fDisguise[id] > now))
        return true;
    if (get_entvar(id, var_effects) & EF_NODRAW)
        return true;
    new mode = get_entvar(id, var_rendermode);
    if (mode != kRenderNormal && Float:get_entvar(id, var_renderamt) < 100.0)
        return true;
    return false;
}

// Studio modelinin kafa ustu yuksekligi (oyuncu merkezine gore, birim): ayakta / comelmis.
// Kaynak (models/player/<ad>/<ad>.mdl): $bbox gercek gorsel sinira ayarlanmissa (+-36 hull degil)
// basliktaki max z; degilse "idle1" animasyonunun sinir kutusu (studiomdl her animasyon icin
// gercek kose noktalarindan hesaplar - orijinal CS modelleri de dahil). Comelme: "crouch_idle".
// Sonuclar model adina gore onbellekte (dosya harita basina bir kez okunur).
MdlHeadTops(const name[], &Float:stand = 0.0, &Float:duck = 0.0)
{
    new Float:v[2];
    if (name[0] && TrieGetArray(g_tMdlTop, name, v, 2))
    {
        stand = v[0];
        duck = v[1];
        return;
    }
    stand = 36.0;
    duck = -1.0;
    new path[128], fp;
    formatex(path, charsmax(path), "models/player/%s/%s.mdl", name, name);
    if (name[0] && (fp = fopen(path, "rb", true)))
    {
        new id, raw, Float:hdrTop, numseq, seqidx, Float:idle = -1.0, lab[32], Float:z;
        fread(fp, id, BLOCK_INT);
        if (id == 0x54534449)   // "IDST"
        {
            fseek(fp, 108, SEEK_SET);           // studiohdr_t.max[2] ($bbox)
            fread(fp, raw, BLOCK_INT);
            hdrTop = Float:raw;
            fseek(fp, 164, SEEK_SET);           // numseq, seqindex
            fread(fp, numseq, BLOCK_INT);
            fread(fp, seqidx, BLOCK_INT);
            numseq = clamp(numseq, 0, 512);
            for (new i = 0; i < numseq && (idle < 0.0 || duck < 0.0); i++)
            {
                fseek(fp, seqidx + i * 176, SEEK_SET);   // mstudioseqdesc_t: label[32] ... bbmax @ +108
                fread_blocks(fp, lab, 32, BLOCK_CHAR);
                lab[31] = 0;
                new bool:isIdle = equali(lab, "idle1") ? true : false;
                if (!isIdle && !equali(lab, "crouch_idle"))
                    continue;
                fseek(fp, seqidx + i * 176 + 116, SEEK_SET);
                fread(fp, raw, BLOCK_INT);
                z = Float:raw;
                if (z < 4.0 || z > 400.0)
                    continue;
                if (isIdle)
                    idle = z;
                else
                    duck = z;
            }
            if (hdrTop > 8.0 && hdrTop < 400.0 && floatabs(hdrTop - 36.0) > 0.5)
                stand = hdrTop;
            else if (idle > 0.0)
                stand = idle;
        }
        fclose(fp);
    }
    if (duck <= 0.0)
        duck = floatmax(8.0, stand - 10.0);
    duck = floatmin(duck, stand);
    if (name[0])
    {
        v[0] = stand;
        v[1] = duck;
        TrieSetArray(g_tMdlTop, name, v, 2);
    }
}

// Oyuncunun su anki modeline gore kafa ustu (model degisince yenilenir; olcek uygulanir)
OvhModelTops(id)
{
    new mdl[32];
    get_user_info(id, "model", mdl, charsmax(mdl));
    new Float:sc = Float:get_entvar(id, var_scale);
    if (!equal(mdl, g_szOvhMdl[id]) || g_fOvhStand[id] <= 0.0)
    {
        copy(g_szOvhMdl[id], charsmax(g_szOvhMdl[]), mdl);
        MdlHeadTops(mdl, g_fOvhStand[id], g_fOvhDuck[id]);
        if (sc > 0.05 && floatabs(sc - 1.0) > 0.01)
        {
            g_fOvhStand[id] *= sc;
            g_fOvhDuck[id] *= sc;
        }
    }
}

// Oyuncunun kafasi + gosterge yigininin en ustu (merkeze gore; baska isaretler bunun ustune konur)
Float:OvhTopOf(id)
{
    if (!(1 <= id <= g_iMax))
        return 40.0;
    OvhModelTops(id);
    new Float:head = (get_entvar(id, var_flags) & FL_DUCKING) ? g_fOvhDuck[id] : g_fOvhStand[id];
    if (g_iOvhBar[id] || g_iOvhEmb[id] || g_iOvhIcon[id])
        return head + g_fOvhStackTop[id];
    return head + floatclamp(get_pcvar_float(g_pOvhMargin), 0.0, 64.0);
}

OvhSpawn(id, slot, Float:scale)
{
    if (!g_szOvhSpr[slot][0])
        return 0;
    new ent = rg_create_entity("info_target");
    if (is_nullent(ent))
        return 0;
    if (ent >= OVH_MAXENT)
    {
        set_entvar(ent, var_flags, FL_KILLME);
        return 0;
    }
    set_entvar(ent, var_classname, OVH_CLASS);
    engfunc(EngFunc_SetModel, ent, g_szOvhSpr[slot]);
    set_entvar(ent, var_solid, SOLID_NOT);
    // NOCLIP (hiz 0): sunucuda yerinde durur; istemci bunu oyuncular gibi enterpole eder
    set_entvar(ent, var_movetype, MOVETYPE_NOCLIP);
    set_entvar(ent, var_iuser1, id);
    set_entvar(ent, var_iuser2, OVH_MAGIC);
    g_iOvhSent[id] = -1;   // yeni varlik: bir sonraki guncellemede konum / kare yazilir
    set_entvar(ent, var_rendermode, g_iOvhMode[slot]);
    set_entvar(ent, var_renderamt, 255.0);
    set_entvar(ent, var_rendercolor, Float:{255.0, 255.0, 255.0});
    set_entvar(ent, var_scale, floatclamp(scale, 0.02, 4.0));
    set_entvar(ent, var_frame, 0.0);
    set_entvar(ent, var_framerate, 0.0);
    OvhModelTops(id);
    new Float:o[3];
    get_entvar(id, var_origin, o);
    o[2] += g_fOvhStand[id] + 8.0;
    engfunc(EngFunc_SetOrigin, ent, o);
    g_fOvhDz[ent] = 8.0;
    g_iOvhOwn[ent] = id;
    g_iOvhCount++;
    return ent;
}

OvhKill(ent)
{
    if (ent > g_iMax && !is_nullent(ent))
    {
        if (get_entvar(ent, var_iuser2) == OVH_MAGIC)
        {
            set_entvar(ent, var_iuser2, 0);
            set_entvar(ent, var_movetype, MOVETYPE_NONE);
            set_entvar(ent, var_effects, EF_NODRAW);
            set_entvar(ent, var_flags, FL_KILLME);
            g_iOvhCount = max(0, g_iOvhCount - 1);
        }
    }
    if (0 < ent < OVH_MAXENT)
        g_iOvhOwn[ent] = 0;
}

OvhRemove(id)
{
    if (!(0 < id <= 32))
        return;
    OvhKill(g_iOvhBar[id]);
    OvhKill(g_iOvhEmb[id]);
    OvhKill(g_iOvhIcon[id]);
    g_iOvhSent[id] = -1;
    g_iOvhBar[id] = 0; g_iOvhEmb[id] = 0; g_iOvhIcon[id] = 0;
    g_iOvhBarType[id] = -1; g_iOvhIconType[id] = -1;
}

OvhRemoveAll()
{
    for (new id = 1; id <= 32; id++)
        OvhRemove(id);
    // Kayip kalan (or. sahibi gecersiz) gostergeler
    new ent;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", OVH_CLASS)) > 0)
    {
        set_entvar(ent, var_iuser2, 0);
        set_entvar(ent, var_movetype, MOVETYPE_NONE);
        set_entvar(ent, var_classname, "vex_removed");
        set_entvar(ent, var_flags, FL_KILLME);
        if (ent < OVH_MAXENT)
            g_iOvhOwn[ent] = 0;
    }
    arrayset(g_iOvhOwn, 0, sizeof g_iOvhOwn);
    g_iOvhCount = 0;
}

// Yigin: kafa ustu + bosluk -> can bari -> boss amblemi -> ikon (her biri kendi yuksekliginin
// yarisi kadar ortalanir). g_fOvhDz = kafa ustunden merkez yuksekligi; AddToFullPack bunu
// oyuncunun o anki konumuna ve comelme durumuna ekler.
OvhUpdate(id)
{
    if (!is_user_alive(id))
    {
        OvhRemove(id);
        return;
    }
    new bool:hidden = OvhHidden(id);
    OvhModelTops(id);

    new frameNow = -1;
    if (g_iOvhBar[id] && g_iOvhBarType[id] >= 0)
    {
        new slot0 = g_iOvhBarType[id];
        new Float:hp0 = Float:get_entvar(id, var_health), Float:mx0;
        if (slot0 == OVS_BOSSBAR)
            mx0 = float(max(1, g_iBossMaxHP));
        else
            mx0 = floatmax(floatmax(Float:get_entvar(id, var_max_health), float(g_iMaxHP[id])), hp0);
        new last0 = max(0, g_iOvhFrames[slot0] - 1);
        frameNow = clamp(floatround(hp0 / floatmax(1.0, mx0) * float(last0)), 0, last0);
        if (hp0 > 0.0 && frameNow < 1 && last0 > 0)
            frameNow = 1;
    }

    new Float:gap = floatclamp(get_pcvar_float(g_pOvhGap), 0.0, 32.0);
    new Float:z = floatclamp(get_pcvar_float(g_pOvhMargin), 0.0, 64.0);
    new ents[3], n;

    new bar = g_iOvhBar[id];
    if (bar && !OvhValid(bar, id))
    {
        g_iOvhBar[id] = 0;
        bar = 0;
    }
    if (bar)
    {
        new Float:h = float(g_iOvhHeight[g_iOvhBarType[id]]) * Float:get_entvar(bar, var_scale);
        g_fOvhDz[bar] = z + h * 0.5;
        z += h + gap;
        ents[n++] = bar;
    }

    new emb = g_iOvhEmb[id];
    if (emb && !OvhValid(emb, id))
    {
        g_iOvhEmb[id] = 0;
        emb = 0;
    }
    if (emb)
    {
        new Float:h = float(g_iOvhHeight[OVS_BOSSICON]) * Float:get_entvar(emb, var_scale);
        g_fOvhDz[emb] = z + h * 0.5;
        z += h + gap;
        ents[n++] = emb;
    }

    new icon = g_iOvhIcon[id];
    if (icon && !OvhValid(icon, id))
    {
        g_iOvhIcon[id] = 0;
        icon = 0;
    }
    if (icon)
    {
        new slot = g_iOvhIconType[id];
        new Float:h = 16.0;
        if (slot >= 0)
            h = float(g_iOvhHeight[slot]) * Float:get_entvar(icon, var_scale);
        g_fOvhDz[icon] = z + h * 0.5;
        z += h + gap;
        ents[n++] = icon;
    }
    g_fOvhStackTop[id] = z;

    // Sunucu konumu: oyuncunun kafasinin ustunde tutulur (PVS / ses icin; cizim konumu AddToFullPack'te)
    new Float:o[3], Float:p[3];
    get_entvar(id, var_origin, o);
    new Float:head = (get_entvar(id, var_flags) & FL_DUCKING) ? g_fOvhDuck[id] : g_fOvhStand[id];
    for (new i = 0; i < n; i++)
    {
        p[0] = o[0];
        p[1] = o[1];
        p[2] = o[2] + head + g_fOvhDz[ents[i]];
        engfunc(EngFunc_SetOrigin, ents[i], p);
    }

    // Kare / gizlilik degismediyse yazma
    new sig = (frameNow + 1) | (hidden ? 0x1000 : 0) | (bar << 13);
    if (sig == g_iOvhSent[id])
        return;
    g_iOvhSent[id] = sig;
    if (bar)
        set_entvar(bar, var_frame, float(max(0, frameNow)));
    for (new i = 0; i < n; i++)
        set_entvar(ents[i], var_effects, hidden ? EF_NODRAW : 0);
}

// Gosterge konumu her pakette: oyuncunun AYNI paketteki konumu + kafa ustu + yigin ofseti.
// Kendi gostergeni gormezsin (vex_overhead_self 0); gozunden izleyen seyirci de gormez.
public fw_AddToFullPackPost(es, e, ent, host, hostflags, player, pSet)
{
    if (player || !g_iOvhCount || ent >= OVH_MAXENT || ent <= g_iMax)
        return FMRES_IGNORED;
    new id = g_iOvhOwn[ent];
    if (!id || !get_orig_retval())
        return FMRES_IGNORED;
    if (!g_bOvhSelf && (host == id || (get_entvar(host, var_iuser1) == 4 && get_entvar(host, var_iuser2) == id)))
    {
        set_es(es, ES_Effects, get_es(es, ES_Effects) | EF_NODRAW);
        return FMRES_IGNORED;
    }
    new Float:o[3];
    get_entvar(id, var_origin, o);
    o[2] += ((get_entvar(id, var_flags) & FL_DUCKING) ? g_fOvhDuck[id] : g_fOvhStand[id]) + g_fOvhDz[ent];
    set_es(es, ES_Origin, o);
    return FMRES_IGNORED;
}
