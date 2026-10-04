/* ================================================================== */
/*  Vexmira Zombie - modul: vex/fx.inc  (FX)                          */
/*  Gorsel / ses efekt yardimcilari (TE mesajlari, isinlar, ekran     */
/*  solmasi / sarsinti), ses calma (PlayKey / EmitKey / EmitSafe),    */
/*  dunya ortami (isik / sis / hava), tehlike alanlari.               */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  ROUND AKISI (ReAPI)                                                */
/* ================================================================== */

stock PlayVoxAll(const key[])
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_AMB))
            PlayKey(p, key);
    }
}


/* ================================================================== */
/*  DUNYA EVENT'LERI (isik / sis)                                      */
/* ================================================================== */

/* ---------------- v2.0: ortam sistemi (isik / sis / hava durumu) ----------------
   Oncelik: BOSS (bossa ozel) > ozel mod > event > sakin round hazirlari.
   Tablolar vexmira.cfg'de: vex_env_boss / vex_env_mode / vex_env_event / vex_env_calm */

CurrentEnv(&light, fog[4], &weather)
{
    light = 'm';
    fog[0] = 0; fog[1] = 0; fog[2] = 0; fog[3] = 0;
    weather = 0;
    if (!get_pcvar_num(g_pEnv))
        return;

    if (g_iMode == MODE_BOSS && g_iBossType >= 0 && g_iBossType < NUM_BOSSES)
    {
        light = ENV_BOSS_LIGHT[g_iBossType] ? ENV_BOSS_LIGHT[g_iBossType] : 'd';
        for (new i = 0; i < 4; i++)
            fog[i] = ENV_BOSS_FOG[g_iBossType][i];
        weather = ENV_BOSS_WEATHER[g_iBossType];
        return;
    }
    if (g_iMode >= 0 && g_iMode < MODE_TOTAL && ENV_MODE_LIGHT[g_iMode])
    {
        light = ENV_MODE_LIGHT[g_iMode];
        for (new i = 0; i < 4; i++)
            fog[i] = ENV_MODE_FOG[g_iMode][i];
        weather = ENV_MODE_WEATHER[g_iMode];
        return;
    }
    if (g_iEvent > EV_NONE && g_iEvent < EV_TOTAL)
    {
        light = ENV_EV_LIGHT[g_iEvent];
        for (new i = 0; i < 4; i++)
            fog[i] = ENV_EV_FOG[g_iEvent][i];
        weather = ENV_EV_WEATHER[g_iEvent];
        return;
    }
    if (g_iCalmPreset >= 0 && g_iCalmPreset < NUM_CALM)
    {
        light = ENV_CALM_LIGHT[g_iCalmPreset];
        for (new i = 0; i < 4; i++)
            fog[i] = ENV_CALM_FOG[g_iCalmPreset][i];
        weather = ENV_CALM_WEATHER[g_iCalmPreset];
    }
}

// Sakin round: rastgele hava (gunduz %35, alacakaranlik %15, gece %15, yagmur %15, kar %10, sis %10)
PickCalmPreset()
{
    g_iCalmPreset = -1;
    if (!get_pcvar_num(g_pEnvCalm) || g_iEvent != EV_NONE || (g_iMode != MODE_INFECTION && g_iMode != MODE_MULTI))
        return;
    static const W[NUM_CALM] = { 35, 15, 15, 15, 10, 10 };
    new roll = random_num(1, 100), acc;
    for (new i = 0; i < NUM_CALM; i++)
    {
        acc += W[i];
        if (roll <= acc)
        {
            g_iCalmPreset = i;
            return;
        }
    }
    g_iCalmPreset = 0;
}

ApplyWorldEvent()
{
    new light, fog[4], weather;
    CurrentEnv(light, fog, weather);
    g_szLight[0] = light ? light : 'm';
    g_szLight[1] = 0;
    #pragma unused weather

    engfunc(EngFunc_LightStyle, 0, g_szLight);

    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id))
            SendFogForEvent(id);
    }
}

// Isik + sis + hava tekrar (yetenek / tutulma / firtina bitince)
ApplyEnvAll()
{
    ApplyWorldEvent();
}

SendFogForEvent(id)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    new light, fog[4], weather;
    CurrentEnv(light, fog, weather);

    if (get_pcvar_num(g_pWeather))
        SendWeather(id, weather);

    if ((g_iSet[id] & SET_NO_FOG) || fog[3] <= 0)
        SendFogEx(id, 0, 0, 0, 0);
    else
        SendFogEx(id, fog[0], fog[1], fog[2], fog[3]);
}

// Yogunluk x10000 (or. 25 = 0.0025). 0 = sis kapali.
stock SendFogEx(id, r, g, b, density)
{
    if (!g_msgFog)
        return;
    new Float:fd = float(max(density, 0)) / 10000.0;
    new d = (density > 0) ? (_:fd) : 0;
    message_begin(MSG_ONE, g_msgFog, _, id);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    write_byte(d & 0xFF);
    write_byte((d >> 8) & 0xFF);
    write_byte((d >> 16) & 0xFF);
    write_byte((d >> 24) & 0xFF);
    message_end();
}

// Hava: 0 acik, 1 yagmur, 2 kar (oyuncunun cl_weather ayari acik olmali)
stock SendWeather(id, w)
{
    if (!g_msgWeather || !is_user_connected(id) || is_user_bot(id))
        return;
    message_begin(MSG_ONE, g_msgWeather, _, id);
    write_byte(clamp(w, 0, 2));
    message_end();
}


/* ================================================================== */
/*  FX / YARDIMCILAR                                                   */
/* ================================================================== */

stock SendFog(id, r, g, b, bool:on)
{
    message_begin(MSG_ONE, g_msgFog, _, id);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    write_byte(on ? 10 : 0);
    write_byte(on ? 41 : 0);
    write_byte(on ? 95 : 0);
    write_byte(on ? 59 : 0);
    message_end();
}

// Efekt mesajlari "dusuk efekt" ayarini acmis oyunculara gonderilmez.
// Onemli uyarilar (boss alanlari) g_bFxReliable ile GUVENILIR kanaldan gider:
// ag kotasi dolan oyuncu (or. surekli ates eden CT) da kesin gorur.
stock FxBegin(const Float:o[3], p)
{
    engfunc(EngFunc_MessageBegin, g_bFxReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, o, p);
}

stock bool:FxWants(p, const Float:o[3])
{
    if (!is_user_connected(p) || is_user_bot(p))
        return false;
    // Guvenilir uyarilar dusuk efekt ayarinda bile gonderilir (hayati bilgi)
    if (!g_bFxReliable && (g_iSet[p] & SET_NO_FX))
        return false;

    new Float:po[3];
    get_entvar(p, var_origin, po);
    return (get_distance_f(o, po) < (g_bFxReliable ? 4000.0 : 2500.0)) ? true : false;
}

stock FxRing(const Float:o[3], r, g, b, radius)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o))
            continue;

        FxBegin(o, p);
        write_byte(TE_BEAMCYLINDER);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2]);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2] + float(radius));
        write_short(g_sprRing);
        write_byte(0);
        write_byte(0);
        write_byte(4);
        write_byte(30);
        write_byte(0);
        write_byte(r);
        write_byte(g);
        write_byte(b);
        write_byte(200);
        write_byte(0);
        message_end();
    }
}

/* ---------- Ek efektler (orijinal oyun dosyalari, ek indirme yok) ---------- */

stock FxLava(const Float:o[3])
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o)) continue;
        FxBegin(o, p);
        write_byte(TE_LAVASPLASH);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2] - 20.0);
        message_end();
    }
}

stock FxTeleport(const Float:o[3])
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o)) continue;
        FxBegin(o, p);
        write_byte(TE_TELEPORT);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2]);
        message_end();
    }
}

stock FxImplosion(const Float:o[3], radius, count, life)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o)) continue;
        FxBegin(o, p);
        write_byte(TE_IMPLOSION);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2]);
        write_byte(radius);
        write_byte(count);
        write_byte(life);
        message_end();
    }
}

stock FxParticles(const Float:o[3], radius, color, dur)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o)) continue;
        FxBegin(o, p);
        write_byte(TE_PARTICLEBURST);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2]);
        write_short(radius);
        write_byte(color);
        write_byte(dur);
        message_end();
    }
}

stock FxSparks(const Float:o[3])
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o)) continue;
        FxBegin(o, p);
        write_byte(TE_SPARKS);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2]);
        message_end();
    }
}

stock FxBlood(const Float:o[3], scale)
{
    if (!g_sprBlood || !g_sprBloodSpray)
        return;

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o)) continue;
        FxBegin(o, p);
        write_byte(TE_BLOODSPRITE);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2] + 15.0);
        write_short(g_sprBloodSpray);
        write_short(g_sprBlood);
        write_byte(70);
        write_byte(scale);
        message_end();
    }
}

// Gokten yere inen simsek
stock FxSkyStrike(const Float:o[3], r, g, b)
{
    new Float:top[3];
    top[0] = o[0] + random_float(-60.0, 60.0);
    top[1] = o[1] + random_float(-60.0, 60.0);
    top[2] = o[2] + 900.0;
    FxBeam(top, o, g_sprLightning, r, g, b, 60);
    FxLight(o, r, g, b, 40, 8, 30);
    FxSparks(o);
}

// v3.1 gelistirici yon testi (vex_debug_dirs 1): uygulanan hiz / cizilen isin ile beklenen yon
// arasindaki aci kosinusu log'a yazilir (1.000 = ayni yon, -1.000 = ters). Etiket basina 25 kayit.
enum { DIR_HOOK = 0, DIR_PULL, DIR_LEAP, DIR_KNOCK, DIR_PUSH, DIR_DRAW, DIR_GRAV, DIR_TOTAL };
#define DIR_LOG_MAX 25
new g_iDirLogN[DIR_TOTAL];

stock DirCheck(tag, const name[], const Float:a[3], const Float:b[3])
{
    new Float:la = floatsqroot(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]);
    new Float:lb = floatsqroot(b[0] * b[0] + b[1] * b[1] + b[2] * b[2]);
    if (la < 0.001 || lb < 0.001 || g_iDirLogN[tag] >= DIR_LOG_MAX)
        return;
    g_iDirLogN[tag]++;
    log_amx("[Vexmira] DIRCHK %s cos=%.3f", name, (a[0] * b[0] + a[1] * b[1] + a[2] * b[2]) / (la * lb));
}

#define SPR_FMT_NORMAL    0
#define SPR_FMT_ADDITIVE  1
#define SPR_FMT_INDEXALPHA 2
#define SPR_FMT_ALPHATEST 3

// Sprite dosyasinin doku bicimi ("IDSP" ver type texFormat ...); okunamazsa -1
stock SprFileFormat(const path[])
{
    if (!path[0])
        return -1;
    new fp = fopen(path, "rb", true);
    if (!fp)
        return -1;
    new ident, ver, type, fmt;
    fread(fp, ident, BLOCK_INT);
    fread(fp, ver, BLOCK_INT);
    fread(fp, type, BLOCK_INT);
    fread(fp, fmt, BLOCK_INT);
    fclose(fp);
    return (ident == 0x50534449) ? fmt : -1;   // "IDSP"
}

// Oyuncunun basinin ustunde isaret (boss, olum isareti...)
// v3.1: TE_PLAYERATTACHMENT istemcide HER ZAMAN kRenderNormal cizilir (render modu secilemez):
// additive sprite (glow01, mark.spr) siyah zeminli beyaz kare olur. attach = sprite alphatest
// (SprFileFormat == 3) ise oyuncuya bagli cizilir; degilse tek seferlik additive TE_SPRITE
// (kafa hizasinda, dogru karisimla) gonderilir.
stock FxHeadMark(ent, spr, life, bool:attach)
{
    if (!spr)
        return;

    new Float:o[3];
    get_entvar(ent, var_origin, o);
    // v3.0 hizalama: modelin kafa ustu (+ varsa can bari / ikon yigininin ustu) + sprite payi
    new ofs = floatround(OvhTopOf(ent) + 8.0);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o) || p == ent) continue;
        message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, p);
        if (attach)
        {
            write_byte(TE_PLAYERATTACHMENT);
            write_byte(ent);
            write_coord(ofs);
            write_short(spr);
            write_short(life);
        }
        else
        {
            write_byte(TE_SPRITE);
            engfunc(EngFunc_WriteCoord, o[0]);
            engfunc(EngFunc_WriteCoord, o[1]);
            engfunc(EngFunc_WriteCoord, o[2] + float(ofs));
            write_short(spr);
            write_byte(5);
            write_byte(200);
        }
        message_end();
    }
}

// Oyuncunun arkasinda renkli iz
stock FxFollow(ent, r, g, b, life, width)
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_KILLBEAM);
    write_short(ent);
    message_end();

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMFOLLOW);
    write_short(ent);
    write_short(g_sprBeam);
    write_byte(life);
    write_byte(width);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    write_byte(170);
    message_end();
}

stock FxRingSmall(const Float:o[3], r, g, b)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o))
            continue;

        FxBegin(o, p);
        write_byte(TE_BEAMCYLINDER);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2]);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2] + 90.0);
        write_short(g_sprRing);
        write_byte(0);
        write_byte(0);
        write_byte(3);
        write_byte(8);
        write_byte(0);
        write_byte(r);
        write_byte(g);
        write_byte(b);
        write_byte(160);
        write_byte(0);
        message_end();
    }
}

stock FxLight(const Float:o[3], r, g, b, radius, life, decay)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o))
            continue;

        FxBegin(o, p);
        write_byte(TE_DLIGHT);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2]);
        write_byte(radius);
        write_byte(r);
        write_byte(g);
        write_byte(b);
        write_byte(life);
        write_byte(decay);
        message_end();
    }
}

stock FxBeam(const Float:a[3], const Float:b[3], spr, r, g, bl, width)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, a))
            continue;

        FxBegin(a, p);
        write_byte(TE_BEAMPOINTS);
        engfunc(EngFunc_WriteCoord, a[0]);
        engfunc(EngFunc_WriteCoord, a[1]);
        engfunc(EngFunc_WriteCoord, a[2]);
        engfunc(EngFunc_WriteCoord, b[0]);
        engfunc(EngFunc_WriteCoord, b[1]);
        engfunc(EngFunc_WriteCoord, b[2]);
        write_short(spr);
        write_byte(0);
        write_byte(0);
        write_byte(2);
        write_byte(width);
        write_byte(spr == g_sprLightning ? 40 : 0);
        write_byte(r);
        write_byte(g);
        write_byte(bl);
        write_byte(200);
        write_byte(0);
        message_end();
    }
}

stock FxSprite(const Float:o[3], spr, scale, bright)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o))
            continue;

        FxBegin(o, p);
        write_byte(TE_SPRITE);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2] + 20.0);
        write_short(spr);
        write_byte(scale);
        write_byte(bright);
        message_end();
    }
}

stock FxExplosion(const Float:o[3])
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o))
            continue;

        FxBegin(o, p);
        write_byte(TE_EXPLOSION);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2] + 20.0);
        write_short(g_sprExplode);
        write_byte(30);
        write_byte(15);
        write_byte(TE_EXPLFLAG_NOSOUND);
        message_end();
    }
}

/* ---------------- v3.0 (C): efekt sprite yardimcilari ---------------- */

// Tek seferlik katkili sprite (TE_SPRITE, 10 kare/sn). Sprite yoksa false (cagiran yedegi cizer).
stock bool:FxSpr(const Float:o[3], spr, scale, bright = 200, Float:zofs = 0.0)
{
    if (!spr)
        return false;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o))
            continue;
        FxBegin(o, p);
        write_byte(TE_SPRITE);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2] + zofs);
        write_short(spr);
        write_byte(scale);
        write_byte(bright);
        message_end();
    }
    return true;
}

// Element patlamasi (TE_EXPLOSION, 12 kare). Sprite yoksa false.
stock bool:FxExploEl(const Float:o[3], el, scale = 22, rate = 16)
{
    new spr;
    switch (el)
    {
        case EL_FIRE:  spr = g_sprFx[FXS_EXFIRE];
        case EL_ICE:   spr = g_sprFx[FXS_EXICE];
        case EL_TOXIC: spr = g_sprFx[FXS_EXTOXIC];
        case EL_VOID:  spr = g_sprFx[FXS_EXVOID];
        default:       spr = g_sprFx[FXS_SHOCK];
    }
    if (!spr)
        return false;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o))
            continue;
        FxBegin(o, p);
        write_byte(TE_EXPLOSION);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2] + 16.0);
        write_short(spr);
        write_byte(scale);
        write_byte(rate);
        write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES);
        message_end();
    }
    return true;
}

// Kucuk element izi (vurulan oyuncunun ustunde): buz / bosluk / zehir / sok halkasi
stock bool:FxElSmall(const Float:o[3], el, scale = 6)
{
    switch (el)
    {
        case EL_FIRE:  return FxSpr(o, g_sprFx[FXS_EXFIRE] ? g_sprFx[FXS_EXFIRE] : g_sprFire, scale / 2 + 2, 210, 8.0);
        case EL_ICE:   return FxSpr(o, g_sprFx[FXS_ICE], scale, 200, 8.0);
        case EL_TOXIC: return FxSpr(o, g_sprFx[FXS_TOXIC], scale, 190, 8.0);
        case EL_VOID:  return FxSpr(o, g_sprFx[FXS_VOID], scale, 210, 8.0);
    }
    return FxSpr(o, g_sprFx[FXS_SHOCK], scale, 190, 0.0);
}

// Boss yetenegi: bossun elementine gore alan patlamasi (yaricapa gore olcek)
stock FxBossElement(const Float:c[3], Float:radius)
{
    if (!(0 <= g_iBossType < NUM_BOSSES))
        return;
    new scale = clamp(floatround(radius / 14.0), 10, 40);
    FxExploEl(c, BOSS_ELEM[g_iBossType], scale, 14);
}

// Pence darbesi: kurbanin gogsunde pence izi (oyuncu basina 0.3 sn'de bir)
stock FxClawHit(victim)
{
    if (!g_sprFx[FXS_SLASH])
        return;
    new Float:now = get_gametime();
    if (now < g_fFxHitT[victim])
        return;
    g_fFxHitT[victim] = now + 0.3;
    new Float:o[3];
    get_entvar(victim, var_origin, o);
    FxSpr(o, g_sprFx[FXS_SLASH], 4, 220, 12.0);
}

// Iyilesme (oyuncu basina 1 sn'de bir)
stock FxHeal(id)
{
    if (!g_sprFx[FXS_HEAL] || !is_user_alive(id))
        return;
    new Float:now = get_gametime();
    if (now < g_fFxHealT[id])
        return;
    g_fFxHealT[id] = now + 1.0;
    new Float:o[3];
    get_entvar(id, var_origin, o);
    FxSpr(o, g_sprFx[FXS_HEAL], 5, 210, 10.0);
}

stock FxTrail(ent, r, g, b)
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMFOLLOW);
    write_short(ent);
    write_short(g_sprBeam);
    write_byte(10);
    write_byte(4);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    write_byte(200);
    message_end();
}

stock FadeOne(id, r, g, b, a, Float:seconds)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    new dur = floatround(4096.0 * seconds);
    message_begin(MSG_ONE_UNRELIABLE, g_msgFade, _, id);
    write_short(dur);
    write_short(dur);
    write_short(0x0000);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    write_byte(a);
    message_end();
}

stock FadeAll(r, g, b, a, Float:seconds)
{
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id) && !(g_iSet[id] & SET_NO_FX))
            FadeOne(id, r, g, b, a, seconds);
    }
}

stock ShakeOne(id)
{
    if (!is_user_connected(id) || is_user_bot(id) || (g_iSet[id] & SET_NO_FX))
        return;

    message_begin(MSG_ONE_UNRELIABLE, g_msgShake, _, id);
    write_short(8 << 12);
    write_short(2 << 12);
    write_short(6 << 12);
    message_end();
}

stock PlayKey(id, const key[])
{
    new path[128];
    if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
        return;

    if (containi(path, ".mp3") != -1)
    {
        client_cmd(id, "mp3 play ^"%s^"", path);
        return;
    }
    // Dongulu WAV oyuncuya "spk" ile calinirsa bir daha susmaz: calma
    if (get_pcvar_num(g_pLoopGuard) && SndLooped(path))
        return;
    client_cmd(id, "spk ^"%s^"", path);
}

stock EmitKey(ent, const key[], chan = CHAN_VOICE, Float:attn = ATTN_NORM)
{
    new path[128];
    if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
        return;
    if (containi(path, ".mp3") != -1)
        return;

    EmitSafe(ent, chan, path, VOL_NORM, attn, 0, PITCH_NORM);
}

// Varliktan ses: dongulu WAV ise kisa sure sonra otomatik durdurulur
stock EmitSafe(ent, chan, const path[], Float:vol = VOL_NORM, Float:attn = ATTN_NORM, flags = 0, pitch = PITCH_NORM)
{
    if (!path[0] || (ent > 0 && is_nullent(ent)))
        return;

    // v3.0: sadece indirilen (2D) ses varliktan calinamaz -> yakindakilere "spk"
    if (SndIs2DOnly(path))
    {
        new Float:o[3];
        if (ent > 0)
            get_entvar(ent, var_origin, o);
        SpkAround(o, path, attn, (ent <= 0 || attn <= 0.0) ? true : false);
        return;
    }

    new bool:was = g_bEmitting;
    g_bEmitting = true;
    emit_sound(ent, chan, path, vol, attn, flags, pitch);
    g_bEmitting = was;

    if (!get_pcvar_num(g_pLoopGuard) || !SndLooped(path))
        return;

    new params[68];
    params[0] = ent;
    params[1] = chan;
    copy(params[2], 64, path);
    new Float:maxT = floatmax(0.5, get_pcvar_float(g_pLoopMax));
    new Float:t = SndLength(path);
    if (t <= 0.1 || t > maxT)
        t = maxT;
    g_iSndStopSlot = (g_iSndStopSlot + 1) % 64;
    remove_task(TASK_SNDSTOP + g_iSndStopSlot);
    set_task(t, "task_StopEmit", TASK_SNDSTOP + g_iSndStopSlot, params, sizeof params);
}

public task_StopEmit(params[])
{
    new ent = params[0];
    if (ent > 0 && is_nullent(ent))
        return;
    new bool:was = g_bEmitting;
    g_bEmitting = true;
    emit_sound(ent, params[1], params[2], 0.0, ATTN_NORM, SND_STOP, PITCH_NORM);
    g_bEmitting = was;
}

// Round sonu / basi: muzik ve kalan tum sesler susar (ust uste binme olmaz)
stock StopRoundMusic()
{
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id) && !is_user_bot(id))
            client_cmd(id, "mp3 stop");
    }
}

stock StopAllClientSounds()
{
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id) && !is_user_bot(id))
            client_cmd(id, "mp3 stop;stopsound");
    }
}

/* ---------------- v1.4 ek efektler ---------------- */

stock FxRingEx(const Float:o[3], r, g, b, radius, width, life, bright = 200)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o))
            continue;
        FxBegin(o, p);
        write_byte(TE_BEAMCYLINDER);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2]);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2] + float(radius));
        write_short(g_sprRing);
        write_byte(0);
        write_byte(0);
        write_byte(life);
        write_byte(width);
        write_byte(0);
        write_byte(r);
        write_byte(g);
        write_byte(b);
        write_byte(bright);
        write_byte(0);
        message_end();
    }
}

// Dolu disk: yere dusecek saldirilarin uyari alani
stock FxDisk(const Float:o[3], r, g, b, radius, life)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o))
            continue;
        FxBegin(o, p);
        write_byte(TE_BEAMDISK);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2]);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2] + float(radius));
        write_short(g_sprRing);
        write_byte(0);
        write_byte(0);
        write_byte(life);
        write_byte(0);
        write_byte(0);
        write_byte(r);
        write_byte(g);
        write_byte(b);
        write_byte(70);
        write_byte(0);
        message_end();
    }
}

// Yukari dogru kivilcim / parcacik yagmuru
stock FxSpriteTrail(const Float:a[3], const Float:b[3], spr, count, life, scale, speed, rnd)
{
    if (!spr)
        return;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, a))
            continue;
        FxBegin(a, p);
        write_byte(TE_SPRITETRAIL);
        engfunc(EngFunc_WriteCoord, a[0]);
        engfunc(EngFunc_WriteCoord, a[1]);
        engfunc(EngFunc_WriteCoord, a[2]);
        engfunc(EngFunc_WriteCoord, b[0]);
        engfunc(EngFunc_WriteCoord, b[1]);
        engfunc(EngFunc_WriteCoord, b[2]);
        write_short(spr);
        write_byte(count);
        write_byte(life);
        write_byte(scale);
        write_byte(speed);
        write_byte(rnd);
        message_end();
    }
}

// Renkli cizgi sacilmasi (palet rengi)
stock FxStreak(const Float:o[3], color, count, speed)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o))
            continue;
        FxBegin(o, p);
        write_byte(TE_STREAK_SPLASH);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2]);
        engfunc(EngFunc_WriteCoord, 0.0);
        engfunc(EngFunc_WriteCoord, 0.0);
        engfunc(EngFunc_WriteCoord, 1.0);
        write_byte(color);
        write_short(count);
        write_short(speed);
        write_short(speed);
        message_end();
    }
}

// Buyuk huni: boss girisi / kara delik
stock FxFunnel(const Float:o[3], spr, bool:reverse)
{
    if (!spr)
        return;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o))
            continue;
        FxBegin(o, p);
        write_byte(TE_LARGEFUNNEL);
        engfunc(EngFunc_WriteCoord, o[0]);
        engfunc(EngFunc_WriteCoord, o[1]);
        engfunc(EngFunc_WriteCoord, o[2]);
        write_short(spr);
        write_short(reverse ? 1 : 0);
        message_end();
    }
}

// Isin baslangic varligi. v3.1: ek noktasi (attachment) KULLANILMAZ. Istemci attachment N'yi
// varligin son cizilen pozundan alir: ek tanimsiz modelde (stok CS modelleri) ya da birinci
// sahis bakista (kendi modeli cizilmez -> ekler bayat / 0,0,0) isin haritanin baska ucundan,
// ters capraz yonden gelir. Ek 0 = varligin konumu (yerel oyuncu icin tahmin edilen konum):
// her modelde, her bakista dogru ve titremesiz.
stock BeamEntHand(ent)
{
    return ent;
}

// Varliktan noktaya isin (zincir simsek)
stock FxBeamEntPoint(ent, const Float:b[3], spr, r, g, bl, width, noise, life = 3)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, b))
            continue;
        FxBegin(b, p);
        write_byte(TE_BEAMENTPOINT);
        write_short(BeamEntHand(ent));
        engfunc(EngFunc_WriteCoord, b[0]);
        engfunc(EngFunc_WriteCoord, b[1]);
        engfunc(EngFunc_WriteCoord, b[2]);
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
}

// Ayarlanabilir isin (omur parametreli)
stock FxBeamEx(const Float:a[3], const Float:b[3], spr, r, g, bl, width, noise, life, bright = 200)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, a))
            continue;
        FxBegin(a, p);
        write_byte(TE_BEAMPOINTS);
        engfunc(EngFunc_WriteCoord, a[0]);
        engfunc(EngFunc_WriteCoord, a[1]);
        engfunc(EngFunc_WriteCoord, a[2]);
        engfunc(EngFunc_WriteCoord, b[0]);
        engfunc(EngFunc_WriteCoord, b[1]);
        engfunc(EngFunc_WriteCoord, b[2]);
        write_short(spr);
        write_byte(0);
        write_byte(0);
        write_byte(life);
        write_byte(width);
        write_byte(noise);
        write_byte(r);
        write_byte(g);
        write_byte(bl);
        write_byte(bright);
        write_byte(0);
        message_end();
    }
}

stock ShakeEx(id, amp, Float:dur, freq)
{
    if (!is_user_connected(id) || is_user_bot(id) || (g_iSet[id] & SET_NO_FX))
        return;
    message_begin(MSG_ONE_UNRELIABLE, g_msgShake, _, id);
    write_short(amp << 12);
    write_short(floatround(dur * 4096.0));
    write_short(freq << 8);
    message_end();
}

stock ShakeAll(amp, Float:dur, freq)
{
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id))
            ShakeEx(id, amp, dur, freq);
    }
}

/* ---------------- Kalici isin varligi (lazer) ---------------- */

stock BeamCreate(const Float:start[3], const Float:end[3], r, g, b, width, bright)
{
    new beam = rg_create_entity("beam");
    if (is_nullent(beam))
        return 0;

    set_entvar(beam, var_flags, get_entvar(beam, var_flags) | FL_CUSTOMENTITY);
    set_entvar(beam, var_model, g_szSprLaser[0] ? g_szSprLaser : "sprites/laserbeam.spr");
    set_entvar(beam, var_modelindex, g_sprLaser ? g_sprLaser : g_sprBeam);
    set_entvar(beam, var_body, 0);
    set_entvar(beam, var_frame, 0.0);
    set_entvar(beam, var_animtime, 0.0);
    set_entvar(beam, var_scale, float(width));
    set_entvar(beam, var_skin, 0);
    set_entvar(beam, var_sequence, 0);
    set_entvar(beam, var_rendermode, 0);
    BeamColor(beam, r, g, b, bright);
    BeamPoints(beam, start, end);
    return beam;
}

stock BeamColor(beam, r, g, b, bright)
{
    new Float:c[3];
    c[0] = float(r);
    c[1] = float(g);
    c[2] = float(b);
    set_entvar(beam, var_rendercolor, c);
    set_entvar(beam, var_renderamt, float(bright));
}

stock BeamPoints(beam, const Float:start[3], const Float:end[3])
{
    new Float:mins[3], Float:maxs[3];
    set_entvar(beam, var_origin, start);
    set_entvar(beam, var_angles, end);
    for (new i = 0; i < 3; i++)
    {
        mins[i] = floatmin(start[i], end[i]) - start[i];
        maxs[i] = floatmax(start[i], end[i]) - start[i];
    }
    engfunc(EngFunc_SetSize, beam, mins, maxs);
    engfunc(EngFunc_SetOrigin, beam, start);
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

// Konumdan ses (bomba / kutu gibi varligi olmayan noktalar icin)
stock EmitKeyPos(const Float:o[3], const key[])
{
    new path[128];
    if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0] || containi(path, ".mp3") != -1)
        return;
    // Konumdan calinan dongulu ses durdurulamaz: hic calma
    if (get_pcvar_num(g_pLoopGuard) && SndLooped(path))
        return;
    if (SndIs2DOnly(path))
    {
        SpkAround(o, path, ATTN_NORM, false);
        return;
    }
    engfunc(EngFunc_EmitAmbientSound, 0, o, path, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}


/* ================================================================== */
/*  v2.0  TEHLIKE ALANLARI (herkes gorur: T ve CT)                     */
/*  Eski surumde alanlar "kaybolabilen" gecici mesajla ciziliyordu;    */
/*  ates eden insanlarin ag kotasi dolunca alan CT'lerde gorunmuyordu. */
/*  Artik alan, yere yatik bir sprite VARLIGIDIR (oyun motoru herkese  */
/*  kesin gonderir). Sprite dosyasi yoksa guvenilir (reliable) mesajla */
/*  her saniye yeniden cizilir.                                        */
/* ================================================================== */

// Yer seviyesini bul (alan zemine yapissin)
stock FloorAt(const Float:o[3], Float:out[3])
{
    new Float:a[3], Float:b[3];
    a = o;
    a[2] += 24.0;
    b = o;
    b[2] -= 512.0;
    engfunc(EngFunc_TraceLine, a, b, IGNORE_MONSTERS, 0, 0);
    get_tr2(0, TR_vecEndPos, out);
    out[2] += 2.0;
}

// Alan olustur. follow > 0 ise alan o oyuncuyu takip eder.
stock ZoneSpawn(const Float:o[3], Float:radius, r, g, b, Float:life, follow = 0, bool:sound = true)
{
    new Float:pos[3];
    FloorAt(o, pos);

    new ent = rg_create_entity("info_target");
    if (is_nullent(ent))
        return 0;

    set_entvar(ent, var_classname, ZONE_CLASS);
    if (g_sprZone)
    {
        engfunc(EngFunc_SetModel, ent, g_szSprZone);
        set_entvar(ent, var_rendermode, kRenderTransAdd);
        set_entvar(ent, var_renderamt, 220.0);
        new Float:c[3];
        c[0] = float(max(r, 1));
        c[1] = float(max(g, 1));
        c[2] = float(max(b, 1));
        set_entvar(ent, var_rendercolor, c);
        set_entvar(ent, var_scale, floatmax(0.05, radius / 120.0));
        set_entvar(ent, var_angles, Float:{90.0, 0.0, 0.0});
        set_entvar(ent, var_frame, 0.0);
    }
    else
        set_entvar(ent, var_effects, EF_NODRAW);

    set_entvar(ent, var_movetype, MOVETYPE_NOCLIP);
    set_entvar(ent, var_solid, SOLID_NOT);
    new Float:mins[3], Float:maxs[3];
    mins[0] = -radius; mins[1] = -radius; mins[2] = -8.0;
    maxs[0] = radius;  maxs[1] = radius;  maxs[2] = 8.0;
    engfunc(EngFunc_SetSize, ent, mins, maxs);
    engfunc(EngFunc_SetOrigin, ent, pos);

    new Float:now = get_gametime();
    set_entvar(ent, var_fuser1, now + life);
    set_entvar(ent, var_fuser2, now);
    set_entvar(ent, var_fuser3, radius);
    set_entvar(ent, var_fuser4, now + 0.7);
    set_entvar(ent, var_iuser1, follow);
    set_entvar(ent, var_iuser2, (r << 16) | (g << 8) | b);
    set_entvar(ent, var_iuser3, g_iBossSerial);

    SetThink(ent, "fw_ZoneThink");
    set_entvar(ent, var_nextthink, now + 0.01);

    // Ilk an: herkese guvenilir halka (aninda gorulsun)
    g_bFxReliable = true;
    FxRingEx(pos, r, g, b, floatround(radius), 10, 6, 220);
    g_bFxReliable = false;
    if (sound)
        EmitKeyPos(pos, "ZONE_WARN");
    return ent;
}

public fw_ZoneThink(ent)
{
    if (is_nullent(ent))
        return;

    new Float:now = get_gametime();
    new Float:end = Float:get_entvar(ent, var_fuser1);
    if (now >= end)
    {
        set_entvar(ent, var_flags, FL_KILLME);
        return;
    }

    new follow = get_entvar(ent, var_iuser1);
    if (follow > 0)
    {
        new bool:gone;
        if (follow <= g_iMax)
            gone = !is_user_alive(follow);
        else if (is_nullent(follow) || (get_entvar(follow, var_flags) & FL_KILLME))
            gone = true;
        else
        {
            new cls[16];
            get_entvar(follow, var_classname, cls, charsmax(cls));
            gone = !equal(cls, "vex_airdrop");
        }
        if (gone)
        {
            set_entvar(ent, var_flags, FL_KILLME);
            return;
        }
        new Float:fo[3], Float:pos[3], Float:fv[3];
        get_entvar(follow, var_origin, fo);
        FloorAt(fo, pos);
        engfunc(EngFunc_SetOrigin, ent, pos);
        // Dusunceler arasinda da takip etsin (NOCLIP + yatay hiz; istemci yumusatir)
        get_entvar(follow, var_velocity, fv);
        fv[2] = 0.0;
        set_entvar(ent, var_velocity, fv);
    }

    new Float:radius = Float:get_entvar(ent, var_fuser3);
    new c = get_entvar(ent, var_iuser2);
    new r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255;

    if (g_sprZone)
    {
        // Nabiz gibi atan parlaklik, son 0.6 sn hizlanir
        new Float:t = now - Float:get_entvar(ent, var_fuser2);
        new Float:speed = (end - now < 0.6) ? 22.0 : 7.0;
        new Float:amt = 150.0 + 90.0 * floatabs(floatsin(t * speed, radian));
        set_entvar(ent, var_renderamt, amt);

        // Ek guvence: alanin sinirina periyodik (guvenilir) halka
        if (now >= Float:get_entvar(ent, var_fuser4))
        {
            set_entvar(ent, var_fuser4, now + 0.7);
            new Float:o[3];
            get_entvar(ent, var_origin, o);
            g_bFxReliable = true;
            FxRingEx(o, r, g, b, floatround(radius), 5, 7, 150);
            g_bFxReliable = false;
        }
        set_entvar(ent, var_nextthink, now + 0.05);
    }
    else
    {
        // Sprite yok: her 0.5 sn guvenilir disk + halka
        if (now >= Float:get_entvar(ent, var_fuser4))
        {
            set_entvar(ent, var_fuser4, now + 0.5);
            new Float:o[3];
            get_entvar(ent, var_origin, o);
            g_bFxReliable = true;
            FxDisk(o, r, g, b, floatround(radius), 6);
            FxRingEx(o, r, g, b, floatround(radius), 6, 6, 200);
            g_bFxReliable = false;
        }
        set_entvar(ent, var_nextthink, now + 0.1);
    }
}

stock RemoveAllZones()
{
    new ent;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", ZONE_CLASS)) > 0)
    {
        SetThink(ent, "");
        set_entvar(ent, var_classname, "vex_removed");
        set_entvar(ent, var_flags, FL_KILLME);
    }
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

// Ekran rengi: renk 'hold' sn tam kalir, sonra 'fade' sn'de acilir
stock FadeEx(id, r, g, b, a, Float:fade, Float:hold)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;
    message_begin(MSG_ONE_UNRELIABLE, g_msgFade, _, id);
    write_short(clamp(floatround(4096.0 * fade), 0, 0xFFFF));
    write_short(clamp(floatround(4096.0 * hold), 0, 0xFFFF));
    write_short(0x0000);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    write_byte(a);
    message_end();
}

// Aktif ekran rengini hemen kaldir
stock FadeClear(id)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;
    message_begin(MSG_ONE_UNRELIABLE, g_msgFade, _, id);
    write_short(1);
    write_short(0);
    write_short(0x0000);
    write_byte(0);
    write_byte(0);
    write_byte(0);
    write_byte(0);
    message_end();
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

/* ---------------- 2D (sadece indirilen) ses: konumdan calinmak istenirse ---------------- */

// Yol sadece precache_generic ile indirildiyse (ses tablosunda yok) true
stock bool:SndIs2DOnly(const path[])
{
    return (TrieKeyExists(g_tSnd2D, path) && !TrieKeyExists(g_tSnd3D, path)) ? true : false;
}

// Varliktan calinamayan 2D sesi yakindaki (ATTN_NONE ise tum) oyunculara "spk" ile cal
stock SpkAround(const Float:o[3], const path[], Float:attn, bool:everyone)
{
    if (get_pcvar_num(g_pLoopGuard) && SndLooped(path))
        return;
    new Float:range = 99999.0;
    if (attn > 0.0 && !everyone)
        range = 1200.0 / floatmax(0.5, attn);
    new Float:po[3];
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        if (range < 99999.0)
        {
            get_entvar(p, var_origin, po);
            if (get_distance_f(o, po) > range)
                continue;
        }
        client_cmd(p, "spk ^"%s^"", path);
    }
}

// Modeldeki animasyonu ADI ile baslat (yoksa 'fallback' numarasi; fallback < 0 ise dokunmaz)
stock AnimByName(ent, const name[], fallback, Float:rate = 1.0)
{
    new seq = fallback;
    if (name[0])
    {
        new found = lookup_sequence(ent, name);
        if (found >= 0)
            seq = found;
    }
    if (seq < 0)
        return -1;
    set_entvar(ent, var_sequence, seq);
    set_entvar(ent, var_frame, 0.0);
    set_entvar(ent, var_animtime, get_gametime());
    set_entvar(ent, var_framerate, rate);
    return seq;
}
