/*
    =====================================================================
      ===  V E X M I R A  ===

      VEXMIRA ZOMBIE CORE  v1.5.0   (ReHLDS + ReGameDLL + ReAPI)
      Kurucular: SmurfSexy & Capital
    ---------------------------------------------------------------------
      Tek plugin, tam zombi modu:

      ROUND / MOD SISTEMI (otomatik rotasyon)
        Infection, Multi Infection, Nemesis, Assassin, Survivor, Sniper,
        Swarm, Plague, Armageddon, BOSS (9 boss). 30 roundluk harita
        plani, normal roundlarda 18 farkli event. Round kazanma kosullari tamamen plugin kontrolunde
        (ReAPI CheckWinConditions), round "hemen bitme" sorunu yok.

      OYUNCU SISTEMLERI
        8 zombi sinifi ([R] yetenegi), 16 insan meslegi, level 1-60, 8 rutbe,
        Ammo Pack (AP) + Vex Coin (VC) ekonomisi, 18 esyali market,
        8 ozel silah (efektli, yuksek hasarli), 3 ozel bomba
        (ates / buz / isaret fisegi) + zombi enfeksiyon bombasi,
        6 kalici yetenek (perk), gunluk odul + seri, 14 basarim, 10 unvan,
        VIP / ELITE sistemi (sureli VIP, cift-uclu ziplama, bedava paket,
        aura, iz efekti), eglence komutlari (zar, slot, piyango, hediye,
        odul avi, espri...), canli konusan sunucu (karsilama, cevaplar),
        oldurme serisi / headshot / multi-kill anonsu, MVP sistemi,
        knockback, hasar gostergesi, VIP bonuslari, /unstuck.

      KISIYE OZEL
        Ayarlar menusu (HUD, hasar sayilari, efektler, sesler, sis,
        tema rengi), FPS / performans profilleri, aninda EN/TR dil
        degisimi (GeoIP ile otomatik dil secimi).

      Gerekli: ReHLDS, ReGameDLL_CS, ReAPI modulu, AMX Mod X 1.9 / 1.10
      Moduller: reapi, fakemeta, hamsandwich, fun, nvault (geoip istege bagli)
    ---------------------------------------------------------------------
      DOSYA DUZENI (v3.1): kaynak 13 modul dosyasina bolundu, derleme
      sonucu yine TEK eklenti (vexmira_zombie.amxx). Bu dosyada sadece
      giris noktalari var (plugin_natives / plugin_precache / plugin_init
      / plugin_cfg / plugin_end); geri kalan her sey scripting/vex/ altinda.
      Derleme: vex/ klasoru bu .sma ile ayni klasorde olmali.
      Modul haritasi ve duzenleme kurallari: devtools/plugin/MODULES.md
    =====================================================================
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <nvault>
#include <reapi>
#include <geoip>

#pragma dynamic 32768

#define PLUGIN   "Vexmira Zombie Core"
#define VERSION  "3.0.1-ara"
#define AUTHOR   "SmurfSexy & Capital"

/* ------------------------------------------------------------------ */
/*  Moduller (vex/<modul>.inc) - sira onemli: core once (globaller)   */
/*  Ayrinti: devtools/plugin/MODULES.md                               */
/* ------------------------------------------------------------------ */

#include "vex/core.inc"
#include "vex/fx.inc"
#include "vex/hud.inc"
#include "vex/resources.inc"
#include "vex/stats.inc"
#include "vex/economy.inc"
#include "vex/weapons.inc"
#include "vex/zombies.inc"
#include "vex/bosses.inc"
#include "vex/modes.inc"
#include "vex/players.inc"
#include "vex/admin.inc"
#include "vex/maps.inc"

/* ================================================================== */
/*  GIRIS NOKTALARI                                                    */
/*  Yeni cvar / komut / menu / hook kaydi -> plugin_init (asagida),    */
/*  yeni kaynak -> plugin_precache / vex/resources.inc.                */
/* ================================================================== */

/* ================================================================== */
/*  MODUL FILTRESI (GeoIP istege bagli)                                */
/* ================================================================== */

public plugin_natives()
{
    set_module_filter("fw_ModuleFilter");
    set_native_filter("fw_NativeFilter");
}

public fw_ModuleFilter(const module[])
{
    if (equali(module, "geoip"))
        return PLUGIN_HANDLED;
    return PLUGIN_CONTINUE;
}

public fw_NativeFilter(const name[], index, trap)
{
    if (!trap)
        return PLUGIN_HANDLED;
    return PLUGIN_CONTINUE;
}


/* ================================================================== */
/*  PRECACHE / KAYNAKLAR                                               */
/* ================================================================== */

public plugin_precache()
{
    g_tRes = TrieCreate();
    g_tMdlTop = TrieCreate();
    g_tSndInfo = TrieCreate();
    g_tSnd2D = TrieCreate();
    g_tSnd3D = TrieCreate();
    g_tMdlDone = TrieCreate();
    SetDefaultResources();
    // Eski surum uyumlulugu: vexmira_resources.ini varsa once o okunur,
    // sonra TEK AYAR DOSYASI vexmira.cfg icindeki "vex_res" satirlari ustune yazar.
    LoadResourceIni();
    LoadMainConfig(true);

    // Toplam precache sayaci (oyun + harita + diger eklentiler): plugin_init'te loglanir
    g_iFwPcSnd = register_forward(FM_PrecacheSound, "fw_PcSoundPost", 1);
    g_iFwPcMdl = register_forward(FM_PrecacheModel, "fw_PcModelPost", 1);
    g_iFwPcGen = register_forward(FM_PrecacheGeneric, "fw_PcGenericPost", 1);
    // v3.0 (C): harita ortam seslerinin durumu (round basinda yeniden baslatmak icin)
    register_forward(FM_EmitAmbientSound, "fw_AmbientPost", 1);

    g_iSndBudget = clamp(str_to_num(GetResString("SOUND_BUDGET", "200")), 40, 480);
    // v3.0 (C): kullanilmayan stok sesleri engelle (oyun DLL'i precache'i bu fonksiyondan SONRA yapar)
    SetupStockSoundBlock();
    g_iMdlBudget = clamp(str_to_num(GetResString("MODEL_BUDGET", "250")), 40, 480);

    // Bu haritanin boss plani: sadece bu bosslarin modeli / pencesi / sesleri yuklenir
    PlanBossLoad();

    new path[128], key[24];

    // ---------------- SESLER (oncelik sirasiyla; butce dolarsa sonrakiler genel sese duser) ----------------
    // 2D sesler (anons / arayuz / muzik) precache_generic ile indirilir ve "spk" ile calinir:
    // ses yuvasi harcamaz. Sadece konumlu (3D) sesler precache_sound kullanir.
    for (new i = 0; i < sizeof SOUND_KEYS; i++)
    {
        // Sadece yedek olan anahtarlar sonra (gerekirse) yuklenir
        if (!IsFallbackOnly(SOUND_KEYS[i]))
            PrecacheSoundKey(SOUND_KEYS[i]);
    }
    // Geri sayim (VOX): oyuncunun oyununda zaten var (valve/sound/vox), precache gerekmez

    // Bosslar (sadece yuklenenler). v3.0 (C): olum / faz / alay / R yetenek sesleri her zaman
    // herkese (ATTN_NONE) calinir -> konumsuz: generic + spk (ses yuvasi harcamaz)
    static const BEV3D[][] = { "IDLE", "PAIN", "PAIN2", "STEP", "ATTACK" };
    static const BEV2D[][] = { "DEATH", "PHASE", "KILL", "R1", "R2", "R3" };
    for (new b = 0; b < NUM_BOSSES; b++)
    {
        if (!g_bBossLoaded[b])
        {
            BossClearKeys(b);
            continue;
        }
        formatex(key, charsmax(key), "B%d_INTRO", b);
        PrecacheSoundKeyEx(key, true);
        for (new e = 0; e < sizeof BEV3D; e++)
        {
            formatex(key, charsmax(key), "B%d_%s", b, BEV3D[e]);
            PrecacheSoundKeyEx(key, false);
        }
        for (new e = 0; e < sizeof BEV2D; e++)
        {
            formatex(key, charsmax(key), "B%d_%s", b, BEV2D[e]);
            PrecacheSoundKeyEx(key, true);
        }
        formatex(key, charsmax(key), "B%d_MUSIC", b);
        PrecacheSoundKeyEx(key, true);
    }

    // Nemesis / Assassin (olum sesi herkese: 2D)
    static const SEV3D[][] = { "IDLE", "PAIN", "ATTACK" };
    PrecacheSoundKeyEx("NEMESIS_INTRO", true);
    PrecacheSoundKeyEx("ASSASSIN_INTRO", true);
    PrecacheSoundKeyEx("NEMESIS_DEATH", true);
    PrecacheSoundKeyEx("ASSASSIN_DEATH", true);
    for (new e = 0; e < sizeof SEV3D; e++)
    {
        formatex(key, charsmax(key), "NEMESIS_%s", SEV3D[e]);
        PrecacheSoundKeyEx(key, false);
        formatex(key, charsmax(key), "ASSASSIN_%s", SEV3D[e]);
        PrecacheSoundKeyEx(key, false);
    }

    // Arayuz (2D)
    PrecacheSoundKeyEx("UI_VOTE_START", true);
    PrecacheSoundKeyEx("UI_VOTE_END", true);
    PrecacheSoundKeyEx("UI_BOSS_BAR", true);
    PrecacheSoundKeyEx("UI_MENU_SELECT", true);
    PrecacheSoundKeyEx("UI_CLASS_SELECT", true);

    // Kanca / yeni sinif carpma sesleri
    for (new i = 0; i < sizeof SOUND_KEYS_V3; i++)
        PrecacheSoundKey(SOUND_KEYS_V3[i]);

    // Sinif sesleri: once yetenek / aci / olum, sonra bekleme (idle), en son ozel pence sesleri
    static const ZEV1[][] = { "ABILITY", "PAIN", "DIE" };
    static const ZEV2[][] = { "SLASH", "HIT", "STAB", "HITWALL", "INFECT" };
    for (new e = 0; e < sizeof ZEV1; e++)
    {
        for (new i = 0; i < NUM_CLASSES; i++)
        {
            formatex(key, charsmax(key), "Z%d_%s", i, ZEV1[e]);
            PrecacheSoundKeyEx(key, false);
        }
    }
    for (new i = 0; i < NUM_CLASSES; i++)
    {
        formatex(key, charsmax(key), "Z%d_IDLE", i);
        PrecacheSoundKeyEx(key, false);
    }
    for (new e = 0; e < sizeof ZEV2; e++)
    {
        for (new i = 0; i < NUM_CLASSES; i++)
        {
            formatex(key, charsmax(key), "Z%d_%s", i, ZEV2[e]);
            PrecacheSoundKeyEx(key, false);
        }
    }
    for (new m = 0; m < MODE_TOTAL; m++)
    {
        formatex(key, charsmax(key), "MODE%d_MUSIC", m);
        PrecacheSoundKeyEx(key, true);
    }

    // Yedek sesler: sadece bir sinifin / bossun kendi sesi yoksa gerekir (yoksa ses yuvasi harcamaz)
    new bool:needZ, bool:needB, tmp[8];
    for (new i = 0; i < NUM_CLASSES && !needZ; i++)
    {
        formatex(key, charsmax(key), "Z%d_ABILITY", i);
        if (!TrieGetString(g_tRes, key, tmp, charsmax(tmp)) || !tmp[0])
            needZ = true;
    }
    for (new b = 0; b < NUM_BOSSES && !needB; b++)
    {
        if (!g_bBossLoaded[b])
            continue;
        formatex(key, charsmax(key), "B%d_IDLE", b);
        if (!TrieGetString(g_tRes, key, tmp, charsmax(tmp)) || !tmp[0])
            needB = true;
        formatex(key, charsmax(key), "B%d_ATTACK", b);
        if (!TrieGetString(g_tRes, key, tmp, charsmax(tmp)) || !tmp[0])
            needB = true;
    }
    for (new i = 0; i < sizeof SOUND_KEYS; i++)
    {
        if (!IsFallbackOnly(SOUND_KEYS[i]))
            continue;
        // v3.0 (C): genel zombi aci / olum / bekleme sesi sadece kendi sesi olmayan sinif varsa
        if (equal(SOUND_KEYS[i], "ZOMBIE_PAIN") || equal(SOUND_KEYS[i], "ZOMBIE_DIE") || equal(SOUND_KEYS[i], "ZOMBIE_IDLE"))
        {
            if (AnyClassLacks(SOUND_KEYS[i][7]))
                PrecacheSoundKeyEx(SOUND_KEYS[i], false);
            else
                TrieSetString(g_tRes, SOUND_KEYS[i], "");
            continue;
        }
        if (equal(SOUND_KEYS[i], "BOSS_", 5))
        {
            // BOSS_SCREAM ayrica herkese (2D) calinir: gerekmiyorsa sadece indirilir
            if (needB)
                PrecacheSoundKeyEx(SOUND_KEYS[i], false);
            else if (equal(SOUND_KEYS[i], "BOSS_SCREAM"))
                PrecacheSoundKeyEx(SOUND_KEYS[i], true);
            else
                TrieSetString(g_tRes, SOUND_KEYS[i], "");
        }
        else if (needZ)
            PrecacheSoundKeyEx(SOUND_KEYS[i], false);
        else
            TrieSetString(g_tRes, SOUND_KEYS[i], "");
    }

    // ---------------- SPRITE'LAR ----------------
    // Orijinal oyun sprite'lari (her sunucuda var)
    g_sprRing      = PcModel("sprites/shockwave.spr", false);
    g_sprBeam      = PcModel("sprites/laserbeam.spr", false);
    g_sprLightning = PcModel("sprites/lgtning.spr", false);
    g_sprExplode   = PcModel("sprites/zerogxplode.spr", false);
    g_sprSmoke     = PcModel("sprites/steam1.spr", false);

    // Istege bagli sprite'lar: dosya yoksa sunucu cokmesin diye kontrol edilir
    g_sprBlood      = PrecacheSafe("sprites/blood.spr");
    g_sprBloodSpray = PrecacheSafe("sprites/bloodspray.spr");
    g_sprHeadMark   = PrecacheSafe(GetResString("BOSS_MARK_SPRITE", "sprites/glow01.spr"));
    // TE_PLAYERATTACHMENT istemcide her zaman kRenderNormal cizilir: additive (glow01 gibi)
    // sprite'lar siyah zeminli beyaz kare gorunur. Yalniz alphatest sprite'lar bu yolla cizilir.
    g_bHeadMarkAt   = (g_sprHeadMark && SprFileFormat(GetResString("BOSS_MARK_SPRITE", "sprites/glow01.spr")) == SPR_FMT_ALPHATEST) ? true : false;
    g_sprLaser      = g_sprBeam;
    g_sprFlare      = PrecacheSafe("sprites/flare6.spr");
    if (!g_sprFlare)
        g_sprFlare  = g_sprHeadMark;

    // v2.0 ozel sprite'lar (vexmira.cfg: vex_res SPR_...). Dosya yoksa 0 kalir ve
    // efekt orijinal oyun sprite'lariyla cizilir.
    g_sprZone   = PrecacheResSprite("SPR_ZONE", g_szSprZone, charsmax(g_szSprZone));
    g_sprTarget = PrecacheResSprite("SPR_TARGET", g_szSprTarget, charsmax(g_szSprTarget));
    g_sprBeacon = PrecacheResSprite("SPR_BEACON", g_szSprBeacon, charsmax(g_szSprBeacon));
    g_sprOrb    = PrecacheResSprite("SPR_ORB", g_szSprOrb, charsmax(g_szSprOrb));
    g_sprMark   = PrecacheResSprite("SPR_MARK", g_szSprMark, charsmax(g_szSprMark));
    g_sprFire   = PrecacheResSprite("SPR_FIRE", g_szSprFire, charsmax(g_szSprFire));
    g_sprLmBeam = PrecacheResSprite("SPR_LASER", g_szSprLaser, charsmax(g_szSprLaser));
    if (!g_sprBeacon && g_sprHeadMark)
    {
        g_sprBeacon = g_sprHeadMark;
        copy(g_szSprBeacon, charsmax(g_szSprBeacon), GetResString("BOSS_MARK_SPRITE", "sprites/glow01.spr"));
    }
    if (!g_sprOrb)
    {
        // Yedek: oyunun flare6 sprite'i (precache edildiyse) ya da isaret sprite'i
        if (g_sprFlare && file_exists("sprites/flare6.spr", true))
        {
            g_sprOrb = g_sprFlare;
            copy(g_szSprOrb, charsmax(g_szSprOrb), "sprites/flare6.spr");
        }
        else if (g_sprBeacon)
        {
            g_sprOrb = g_sprBeacon;
            copy(g_szSprOrb, charsmax(g_szSprOrb), g_szSprBeacon);
        }
    }
    if (g_sprMark)
        g_bMarkAt = (SprFileFormat(g_szSprMark) == SPR_FMT_ALPHATEST) ? true : false;
    else
    {
        g_sprMark = g_sprHeadMark;
        g_bMarkAt = g_bHeadMarkAt;
    }
    if (g_sprLmBeam)
        g_sprLaser = g_sprLmBeam;
    else
        copy(g_szSprLaser, charsmax(g_szSprLaser), "sprites/laserbeam.spr");

    // v3.0 sinif yetenek sprite'lari
    g_sprChain = PrecacheResSprite("SPR_CHAIN", g_szSprChain, charsmax(g_szSprChain));
    g_sprWeb   = PrecacheResSprite("SPR_WEB", g_szSprWeb, charsmax(g_szSprWeb));
    g_sprSpore = PrecacheResSprite("SPR_SPORE", g_szSprSpore, charsmax(g_szSprSpore));
    g_sprEmp   = PrecacheResSprite("SPR_EMP", g_szSprEmp, charsmax(g_szSprEmp));

    // v3.0 (C): efekt sprite'lari (patlamalar, iyilesme, level, enfeksiyon, pence, sok, buz, bosluk, zehir)
    new fxbuf[64];
    g_iFxSprN = 0;
    for (new i = 0; i < FXS_TOTAL; i++)
    {
        g_sprFx[i] = PrecacheResSprite(FXS_KEY[i], fxbuf, charsmax(fxbuf));
        if (g_sprFx[i])
            g_iFxSprN++;
    }

    // Kafa ustu gostergeler (boss bari once: en onemlisi)
    static const OVKEY[OVS_TOTAL][] = { "SPR_BOSSBAR", "SPR_BOSSICON", "SPR_HPBAR", "SPR_ICON_VIP", "SPR_ICON_ADMIN", "SPR_ICON_MVP", "SPR_ICON_LAST", "SPR_ICON_ALPHA" };
    for (new i = 0; i < OVS_TOTAL; i++)
    {
        if (PrecacheResSprite(OVKEY[i], g_szOvhSpr[i], charsmax(g_szOvhSpr[])))
            ReadSprInfo(i);
        else
            g_szOvhSpr[i][0] = 0;
    }

    // ---------------- OYUNCU MODELLERI ----------------
    // Insanlar (rastgele liste) + VIP / admin / survivor / sniper
    LoadHumanModels();
    GetPlayerModel("VIP_MODEL",      g_szVipModel,   charsmax(g_szVipModel));
    GetPlayerModel("ADMIN_MODEL",    g_szAdminModel, charsmax(g_szAdminModel));
    GetPlayerModel("SURVIVOR_MODEL", g_szSurvModel,  charsmax(g_szSurvModel));
    if (!g_szSurvModel[0])
        PlayerModelFallback("gign", g_szSurvModel, charsmax(g_szSurvModel));
    GetPlayerModel("SNIPER_MODEL",   g_szSnipModel,  charsmax(g_szSnipModel));
    if (!g_szSnipModel[0])
        PlayerModelFallback("sas", g_szSnipModel, charsmax(g_szSnipModel));

    // Ozel zombiler + yuklenen bosslar
    GetPlayerModel("NEMESIS_MODEL",  g_szNemModel,   charsmax(g_szNemModel));
    if (!g_szNemModel[0])
        PlayerModelFallback("terror", g_szNemModel, charsmax(g_szNemModel));
    GetPlayerModel("ASSASSIN_MODEL", g_szAsnModel,   charsmax(g_szAsnModel));
    if (!g_szAsnModel[0])
        PlayerModelFallback("leet", g_szAsnModel, charsmax(g_szAsnModel));
    for (new i = 0; i < NUM_BOSSES; i++)
    {
        g_szBModel[i][0] = 0;
        g_szBClaw[i][0] = 0;
        if (!g_bBossLoaded[i])
            continue;
        formatex(key, charsmax(key), "B%d_MODEL", i);
        GetPlayerModel(key, g_szBModel[i], charsmax(g_szBModel[]));
        if (!g_szBModel[i][0])
            PlayerModelFallback(BOSS_OLDMODEL[i], g_szBModel[i], charsmax(g_szBModel[]));
    }

    // Zombi siniflari
    for (new i = 0; i < NUM_CLASSES; i++)
    {
        formatex(key, charsmax(key), "Z%d_MODEL", i);
        GetPlayerModel(key, g_szZModel[i], charsmax(g_szZModel[]));
        // v3.0: ozel sinif modeli yoksa eski (orijinal CS) modele duser
        if (!g_szZModel[i][0])
            PlayerModelFallback(CLASS_OLDMODEL[i], g_szZModel[i], charsmax(g_szZModel[]));
    }

    // ---------------- EL (v_) MODELLERI ----------------
    // Pence modelleri (genel + boss / ozel karakter / sinif bazinda)
    GetFileModel("CLAW_MODEL", g_szClawModel, charsmax(g_szClawModel));
    for (new i = 0; i < NUM_BOSSES; i++)
    {
        if (!g_bBossLoaded[i])
            continue;
        formatex(key, charsmax(key), "B%d_CLAW", i);
        GetFileModel(key, g_szBClaw[i], charsmax(g_szBClaw[]));
    }
    GetFileModel("NEMESIS_CLAW", g_szNemClaw, charsmax(g_szNemClaw));
    GetFileModel("ASSASSIN_CLAW", g_szAsnClaw, charsmax(g_szAsnClaw));
    for (new i = 0; i < NUM_CLASSES; i++)
    {
        formatex(key, charsmax(key), "Z%d_CLAW", i);
        GetFileModel(key, g_szZClaw[i], charsmax(g_szZClaw[]));
    }

    // Insan el modelleri: V_AK47 / V_KNIFE ...
    for (new w = 1; w < 31; w++)
    {
        formatex(key, charsmax(key), "V_%s", WEAPON_KEYNAME[w]);
        GetFileModel(key, g_szWepV[w], charsmax(g_szWepV[]));
    }
    // Ozel silah modelleri
    for (new i = 0; i < NUM_SPECIAL; i++)
    {
        formatex(key, charsmax(key), "SW%d_VMODEL", i);
        GetFileModel(key, g_szSWView[i], charsmax(g_szSWView[]));
        formatex(key, charsmax(key), "SW%d_PMODEL", i);
        GetFileModel(key, g_szSWPlayer[i], charsmax(g_szSWPlayer[]));
    }

    // ---------------- DUNYA MODELLERI ----------------
    LoadWorldModels();

    // En dusuk oncelik: elde gorunen (p_) silah modelleri (butce dolarsa oyunun kendi modeli)
    for (new w = 1; w < 31; w++)
    {
        formatex(key, charsmax(key), "P_%s", WEAPON_KEYNAME[w]);
        GetFileModel(key, g_szWepP[w], charsmax(g_szWepP[]));
    }

    PickSky();

    // Ozet (precache_* donus indekslerinden). Bu noktada oyun / harita henuz kendi
    // dosyalarini eklemedi: toplam (harita + oyun dahil) plugin_init'te ayrica loglanir.
    log_amx("[Vexmira] precache: sound=%d model=%d generic=%d", g_iPcSnd, g_iPcMdl, g_iPcGen);
    log_amx("[Vexmira] precache detay: eklenti 3D ses %d/%d, model+sprite %d/%d, generic %d, butceden atlanan ses %d / model %d, yuklenen boss %d",
        g_iMySnd, g_iSndBudget, g_iMyMdl, g_iMdlBudget, g_iMyGen, g_iSndSkipped, g_iMdlSkipped, g_iBossLoadN);
    log_amx("[Vexmira] efekt sprite'lari: %d/%d yuklendi (model+sprite butcesi %d/%d)", g_iFxSprN, FXS_TOTAL, g_iMyMdl, g_iMdlBudget);
    copy(path, charsmax(path), "");
}


/* ================================================================== */
/*  INIT                                                               */
/* ================================================================== */

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_dictionary("vexmira_zombie.txt");

    if (!is_regamedll())
    {
        set_fail_state("[Vexmira] ReGameDLL_CS + ReAPI gerekli! (ReGameDLL_CS and ReAPI are required)");
        return;
    }

    g_iMax     = get_maxplayers();
    g_msgFog   = get_user_msgid("Fog");
    g_msgFade  = get_user_msgid("ScreenFade");
    g_msgShake = get_user_msgid("ScreenShake");
    g_msgDeath = get_user_msgid("DeathMsg");
    g_msgScore = get_user_msgid("ScoreInfo");
    g_bGeoIP   = LibraryExists("geoip", LibType_Library) ? true : false;

    g_hVault = nvault_open("vexmira_v1");
    g_hVipVault = nvault_open("vexmira_vip");
    if (g_hVault == INVALID_HANDLE)
        log_amx("[Vexmira] nvault acilamadi, ilerleme kaydedilmeyecek.");

    // Cvar'lar
    g_pCountdown    = register_cvar("vex_countdown", "15");
    g_pFirstHP      = register_cvar("vex_first_zombie_hp", "4500");
    g_pZombieHP     = register_cvar("vex_zombie_hp", "1800");
    g_pBossEvery    = register_cvar("vex_boss_every", "6");
    g_pBossHP       = register_cvar("vex_boss_hp", "7000");
    g_pEventChance  = register_cvar("vex_event_chance", "85");
    g_pNemHP        = register_cvar("vex_nemesis_hp", "9000");
    g_pAsnHP        = register_cvar("vex_assassin_hp", "6000");
    g_pSurvHP       = register_cvar("vex_survivor_hp", "1200");
    g_pSnipHP       = register_cvar("vex_sniper_hp", "900");
    g_pRespawn      = register_cvar("vex_zombie_respawn", "4.0");
    g_pDmgPerAP     = register_cvar("vex_damage_per_ap", "500");
    g_pKnockback    = register_cvar("vex_knockback", "1");
    g_pStartAP      = register_cvar("vex_start_ap", "20");
    g_pArmorProtect = register_cvar("vex_armor_protect", "1");
    g_pVipContact   = register_cvar("vex_vip_contact", "discord.gg/vexmira");
    g_pVoteEvery    = register_cvar("vex_vote_every", "4");

    // v1.4: 30 round plani, boss, hasar/can/hiz, lazer, bomba modlari, ikmal
    g_pRoundsTotal  = register_cvar("vex_rounds_total", "30");
    g_pBossRounds   = register_cvar("vex_boss_rounds", "7 15 23 30");
    g_pSpecialRounds= register_cvar("vex_special_rounds", "4 11 19 26");
    g_pMultiChance  = register_cvar("vex_multi_chance", "15");
    g_pBossHPPer    = register_cvar("vex_boss_hp_per_player", "1500");
    g_pBossFinal    = register_cvar("vex_boss_final_mult", "1.5");
    g_pBossDmg      = register_cvar("vex_boss_damage", "75");
    g_pBossAbil     = register_cvar("vex_boss_ability_mult", "1.0");
    g_pNemDmg       = register_cvar("vex_nemesis_damage", "250");
    g_pAsnDmg       = register_cvar("vex_assassin_damage", "200");
    g_pMinionDmg    = register_cvar("vex_minion_damage", "35");
    g_pZombieDmg    = register_cvar("vex_zombie_damage", "60");
    g_pHumanHP      = register_cvar("vex_human_hp", "100");
    g_pLastHumanHP  = register_cvar("vex_last_human_bonus", "150");
    g_pZSpeed       = register_cvar("vex_zombie_speed_mult", "1.0");
    g_pHSpeed       = register_cvar("vex_human_speed_mult", "1.0");
    g_pSpeedHuman   = register_cvar("vex_speedrush_human", "1.55");
    g_pSpeedZombie  = register_cvar("vex_speedrush_zombie", "1.45");
    g_pSpeedFov     = register_cvar("vex_speedrush_fov", "105");
    g_pMvpAP        = register_cvar("vex_mvp_ap", "10");
    g_pMvpVC        = register_cvar("vex_mvp_vc", "1");
    g_pKillAP       = register_cvar("vex_kill_ap", "2");
    g_pInfectAP     = register_cvar("vex_infect_ap", "3");
    g_pGiveNades    = register_cvar("vex_give_nades", "abc");
    g_pLmEnable     = register_cvar("vex_lm_enable", "1");
    g_pLmMax        = register_cvar("vex_lm_max", "3");
    g_pLmMaxVip     = register_cvar("vex_lm_max_vip", "3");
    g_pLmTeamMax    = register_cvar("vex_lm_team_max", "40");
    g_pLmHealth     = register_cvar("vex_lm_health", "600");
    g_pLmDamage     = register_cvar("vex_lm_damage", "150");
    g_pLmZMult      = register_cvar("vex_lm_zombie_mult", "3.0");
    g_pLmWear       = register_cvar("vex_lm_beam_wear", "18");
    g_pLmBoss       = register_cvar("vex_lm_boss", "0");
    g_pNadeModes    = register_cvar("vex_nade_modes", "1");
    g_pNadeProx     = register_cvar("vex_nade_sensor_radius", "150");
    g_pNadeLaser    = register_cvar("vex_nade_laser_length", "700");
    g_pNadeHoming   = register_cvar("vex_nade_homing_radius", "750");
    g_pCluster      = register_cvar("vex_nade_cluster", "4");
    g_pAirdrop      = register_cvar("vex_airdrop", "1");
    g_pAirdropEvery = register_cvar("vex_airdrop_every", "70");
    g_pMotd         = register_cvar("vex_motd", "1");
    g_pQuests       = register_cvar("vex_quests", "1");
    g_pEvolve       = register_cvar("vex_evolve", "3");
    g_pJoinMsg      = register_cvar("vex_join_messages", "1");

    // v2.0
    g_pPrefix        = register_cvar("vex_chat_prefix", "^4[VEX]^1");
    g_pHostname      = register_cvar("vex_hostname", "EN/TR ZOMBIE | VEXMIRA | BOSS + EVENTS + ADV. MENU");
    g_pHostDyn       = register_cvar("vex_hostname_dynamic", "1");
    g_pEnv           = register_cvar("vex_env", "1");
    g_pEnvCalm       = register_cvar("vex_env_calm_random", "1");
    g_pWeather       = register_cvar("vex_weather", "1");
    g_pNemOneShot    = register_cvar("vex_nemesis_oneshot", "1");
    g_pAsnOneShot    = register_cvar("vex_assassin_oneshot", "1");
    g_pNemVsSurv     = register_cvar("vex_nemesis_vs_survivor", "250");
    g_pNemSpeed      = register_cvar("vex_nemesis_speed", "265");
    g_pAsnSpeed      = register_cvar("vex_assassin_speed", "340");
    g_pNemGrav       = register_cvar("vex_nemesis_gravity", "0.5");
    g_pAsnGrav       = register_cvar("vex_assassin_gravity", "0.45");
    g_pMinionHP      = register_cvar("vex_minion_hp", "400");
    g_pNemRageTime   = register_cvar("vex_nemesis_rage_time", "5");
    g_pNemRageCd     = register_cvar("vex_nemesis_rage_cooldown", "25");
    g_pAsnVeilTime   = register_cvar("vex_assassin_veil_time", "4");
    g_pAsnVeilCd     = register_cvar("vex_assassin_veil_cooldown", "25");
    g_pSpecialLeapCd = register_cvar("vex_special_leap_cooldown", "6");
    g_pLmPerRound    = register_cvar("vex_lm_per_round", "3");
    g_pLmPerRoundVip = register_cvar("vex_lm_per_round_vip", "3");
    g_pLmOneShot     = register_cvar("vex_lm_oneshot", "1");
    g_pLmSpecialDmg  = register_cvar("vex_lm_special_damage", "600");
    g_pLmKillWear    = register_cvar("vex_lm_kill_wear", "100");
    g_pLmPlantTime   = register_cvar("vex_lm_plant_time", "1.0");
    g_pLmTakeTime    = register_cvar("vex_lm_take_time", "0");
    g_pLmArmTime     = register_cvar("vex_lm_arm_time", "1.5");
    g_pLmBeamWidth   = register_cvar("vex_lm_beam_width", "8");
    g_pLmColorMode   = register_cvar("vex_lm_color_mode", "0");
    g_pLmColor       = register_cvar("vex_lm_color", "0 200 255");
    g_pLmRange       = register_cvar("vex_lm_plant_range", "128");
    g_pLmTakeRange   = register_cvar("vex_lm_take_range", "170");
    g_pLmMaxRange    = register_cvar("vex_lm_max_range", "600");
    g_pLmBlockModes  = register_cvar("vex_lm_block_modes", "nemesis assassin");
    g_pDbgDirs       = register_cvar("vex_debug_dirs", "0");
    g_pAirdropLaser  = register_cvar("vex_airdrop_laser", "1");
    g_pNadeSensorArm = register_cvar("vex_nade_sensor_arm", "1.5");
    g_pNadeSensorLife= register_cvar("vex_nade_sensor_life", "60");
    g_pNadeLaserArm  = register_cvar("vex_nade_laser_arm", "1.0");
    g_pNadeFireDmg   = register_cvar("vex_nade_fire_damage", "80");
    g_pNadeFireRad   = register_cvar("vex_nade_fire_radius", "260");
    g_pNadeFireBurn  = register_cvar("vex_nade_fire_burn", "6");
    g_pNadeFrostRad  = register_cvar("vex_nade_frost_radius", "260");
    g_pNadeFrostTime = register_cvar("vex_nade_frost_time", "3.0");
    g_pNadeInfectRad = register_cvar("vex_nade_infect_radius", "240");
    g_pNadeFlareTime = register_cvar("vex_nade_flare_time", "25");
    g_pNadeClusterDmg= register_cvar("vex_nade_cluster_damage", "45");
    g_pBossPhase2    = register_cvar("vex_boss_phase2", "60");
    g_pBossPhase3    = register_cvar("vex_boss_phase3", "30");
    g_pBossRAuto     = register_cvar("vex_boss_r_auto", "12");
    g_pBossRCdMult   = register_cvar("vex_boss_r_cooldown_mult", "1.0");
    g_pBossRDmgMult  = register_cvar("vex_boss_r_damage_mult", "1.0");
    g_pBossAutoAbil  = register_cvar("vex_boss_auto_abilities", "1");
    g_pAfkTime       = register_cvar("vex_afk_time", "120");
    g_pAfkAction     = register_cvar("vex_afk_action", "1");
    g_pDropBeacon    = register_cvar("vex_airdrop_beacon", "1");
    g_pDropCompass   = register_cvar("vex_airdrop_compass", "1");
    g_pAirdropHP     = register_cvar("vex_airdrop_zombie_heal", "300");
    g_pLoopGuard     = register_cvar("vex_sound_loopguard", "1");
    g_pLoopMax       = register_cvar("vex_sound_loop_max", "3.0");
    g_pRoundStopSnd  = register_cvar("vex_round_stopsound", "1");
    g_pKillXP        = register_cvar("vex_kill_xp", "8");
    g_pInfectXP      = register_cvar("vex_infect_xp", "10");
    g_pWinHXP        = register_cvar("vex_win_human_xp", "25");
    g_pWinHAP        = register_cvar("vex_win_human_ap", "6");
    g_pWinZXP        = register_cvar("vex_win_zombie_xp", "15");
    g_pWinZAP        = register_cvar("vex_win_zombie_ap", "4");
    g_pBossKillXP    = register_cvar("vex_boss_kill_xp", "120");
    g_pBossKillAP    = register_cvar("vex_boss_kill_ap", "25");
    g_pBossKillVC    = register_cvar("vex_boss_kill_vc", "3");
    g_pSpecKillXP    = register_cvar("vex_special_kill_xp", "80");
    g_pSpecKillAP    = register_cvar("vex_special_kill_ap", "15");
    g_pBossBoard     = register_cvar("vex_boss_board_ap", "40 25 15");
    g_pHsAP          = register_cvar("vex_headshot_ap", "1");
    g_pExchange      = register_cvar("vex_exchange_cost", "60");
    g_pPerkStep      = register_cvar("vex_perk_cost_step", "4");
    g_pDailyAP       = register_cvar("vex_daily_ap", "20");
    g_pAchAP         = register_cvar("vex_achievement_ap", "25");
    g_pAchVC         = register_cvar("vex_achievement_vc", "3");
    g_pBurnDmg       = register_cvar("vex_burn_damage_human", "6");
    g_pZombieBurnDmg = register_cvar("vex_burn_damage_zombie", "35");

    // v3.0: yeni zombi siniflari (12-23) yetenek ayarlari
    g_pZc[ZCV_HOOK_SPEED]  = register_cvar("vex_butcher_hook_speed", "1400");
    g_pZc[ZCV_HOOK_RANGE]  = register_cvar("vex_butcher_hook_range", "900");
    g_pZc[ZCV_HOOK_PULL]   = register_cvar("vex_butcher_pull_speed", "600");
    g_pZc[ZCV_HOOK_TIME]   = register_cvar("vex_butcher_pull_time", "1.2");
    g_pZc[ZCV_HOOK_DMG]    = register_cvar("vex_butcher_hook_damage", "10");
    g_pZc[ZCV_HUNT_POWER]  = register_cvar("vex_hunter_pounce_power", "860");
    g_pZc[ZCV_HUNT_UP]     = register_cvar("vex_hunter_pounce_up", "330");
    g_pZc[ZCV_HUNT_RAD]    = register_cvar("vex_hunter_radius", "70");
    g_pZc[ZCV_HUNT_STUN]   = register_cvar("vex_hunter_stun", "1.0");
    g_pZc[ZCV_HUNT_DMG]    = register_cvar("vex_hunter_damage", "15");
    g_pZc[ZCV_CHG_TIME]    = register_cvar("vex_charger_time", "1.5");
    g_pZc[ZCV_CHG_SPEED]   = register_cvar("vex_charger_speed", "650");
    g_pZc[ZCV_CHG_DMG]     = register_cvar("vex_charger_damage", "20");
    g_pZc[ZCV_CHG_PUSH]    = register_cvar("vex_charger_push", "550");
    g_pZc[ZCV_CHG_STUN]    = register_cvar("vex_charger_self_stun", "0.5");
    g_pZc[ZCV_WEB_SPEED]   = register_cvar("vex_arachne_web_speed", "1100");
    g_pZc[ZCV_WEB_RANGE]   = register_cvar("vex_arachne_web_range", "1000");
    g_pZc[ZCV_WEB_ROOT]    = register_cvar("vex_arachne_root", "1.5");
    g_pZc[ZCV_WEB_SLOW]    = register_cvar("vex_arachne_slow", "3.0");
    g_pZc[ZCV_WEB_DMG]     = register_cvar("vex_arachne_damage", "5");
    g_pZc[ZCV_MAG_TIME]    = register_cvar("vex_magma_trail_time", "5");
    g_pZc[ZCV_MAG_LIFE]    = register_cvar("vex_magma_pool_life", "4");
    g_pZc[ZCV_MAG_RAD]     = register_cvar("vex_magma_pool_radius", "60");
    g_pZc[ZCV_MAG_DMG]     = register_cvar("vex_magma_pool_damage", "6");
    g_pZc[ZCV_MAG_IMMUNE]  = register_cvar("vex_magma_fire_immune", "1");
    g_pZc[ZCV_VOLT_RAD]    = register_cvar("vex_volt_radius", "350");
    g_pZc[ZCV_VOLT_MINE]   = register_cvar("vex_volt_mine_off", "6");
    g_pZc[ZCV_VOLT_LIGHT]  = register_cvar("vex_volt_light_off", "6");
    g_pZc[ZCV_VOLT_DMG]    = register_cvar("vex_volt_damage", "8");
    g_pZc[ZCV_VOLT_SLOW]   = register_cvar("vex_volt_slow", "1.5");
    g_pZc[ZCV_MIM_TIME]    = register_cvar("vex_mimic_time", "10");
    g_pZc[ZCV_MIM_MULT]    = register_cvar("vex_mimic_damage_mult", "2.0");
    g_pZc[ZCV_BUR_TIME]    = register_cvar("vex_burrower_time", "3");
    g_pZc[ZCV_BUR_SPEED]   = register_cvar("vex_burrower_speed", "1.5");
    g_pZc[ZCV_BUR_RAD]     = register_cvar("vex_burrower_radius", "220");
    g_pZc[ZCV_BUR_UP]      = register_cvar("vex_burrower_knockup", "450");
    g_pZc[ZCV_BUR_DMG]     = register_cvar("vex_burrower_damage", "15");
    g_pZc[ZCV_SIR_RAD]     = register_cvar("vex_siren_radius", "400");
    g_pZc[ZCV_SIR_TIME]    = register_cvar("vex_siren_time", "2.5");
    g_pZc[ZCV_SIR_PULL]    = register_cvar("vex_siren_pull", "170");
    g_pZc[ZCV_BUL_TIME]    = register_cvar("vex_bulwark_time", "5");
    g_pZc[ZCV_BUL_REDUCE]  = register_cvar("vex_bulwark_reduce", "50");
    g_pZc[ZCV_BUL_REFLECT] = register_cvar("vex_bulwark_reflect", "25");
    g_pZc[ZCV_SPO_MAX]     = register_cvar("vex_sporemother_max", "2");
    g_pZc[ZCV_SPO_RAD]     = register_cvar("vex_sporemother_radius", "120");
    g_pZc[ZCV_SPO_HP]      = register_cvar("vex_sporemother_hp", "120");
    g_pZc[ZCV_SPO_POISON]  = register_cvar("vex_sporemother_poison", "6");
    g_pZc[ZCV_SPO_LIFE]    = register_cvar("vex_sporemother_life", "60");
    g_pZc[ZCV_SPO_SLOW]    = register_cvar("vex_sporemother_slow", "3.0");
    g_pZc[ZCV_NM_RAD]      = register_cvar("vex_nightmare_radius", "450");
    g_pZc[ZCV_NM_BLIND]    = register_cvar("vex_nightmare_blind", "2.5");
    g_pZc[ZCV_NM_BOOST]    = register_cvar("vex_nightmare_boost", "3");
    g_pZc[ZCV_NM_SPEED]    = register_cvar("vex_nightmare_speed", "1.35");
    g_pZc[ZCV_BOT]         = register_cvar("vex_bot_abilities", "1");
    g_pZc[ZCV_ALTKEYS]     = register_cvar("vex_skill_alt_keys", "1");

    // v3.0 (B): kafa ustu gostergeler, boss / ozel karakter sesleri, sohbet etiketleri
    g_pOvhEnable     = register_cvar("vex_overhead", "1");
    g_pBossBarW      = register_cvar("vex_bossbar_width", "110");
    g_pSmallBarW     = register_cvar("vex_hpbar_width", "44");
    g_pIconSize      = register_cvar("vex_head_icon_size", "18");
    g_pIcons         = register_cvar("vex_head_icons", "31");
    g_pOvhSelf       = register_cvar("vex_overhead_self", "0");
    g_pOvhMargin     = register_cvar("vex_overhead_margin", "5");
    g_pOvhGap        = register_cvar("vex_overhead_gap", "2");
    g_pBossIdleMin   = register_cvar("vex_boss_idle_min", "9");
    g_pBossIdleMax   = register_cvar("vex_boss_idle_max", "16");
    g_pBossPainCd    = register_cvar("vex_boss_pain_cd", "0.9");
    g_pBossAtkCd     = register_cvar("vex_boss_attack_cd", "1.1");
    g_pBossStepDist  = register_cvar("vex_boss_step_dist", "120");
    g_pPrefixBoss    = register_cvar("vex_chat_prefix_boss", "^3[BOSS]^1");
    g_pPrefixEvent   = register_cvar("vex_chat_prefix_event", "^4[^1EVENT^4]^1");
    g_pPrefixVip     = register_cvar("vex_chat_prefix_vip", "^4[^3VIP^4]^1");
    g_pPrefixAdmin   = register_cvar("vex_chat_prefix_admin", "^3[ADMIN]^1");
    register_srvcmd("vex_precache_stats", "srv_PrecacheStats");
    register_srvcmd("vex_debug_lmtest", "srv_DbgLmTest");
    register_srvcmd("vex_debug_gravtest", "srv_DbgGravTest");
    register_srvcmd("vex_debug_hooktest", "srv_DbgHookTest");
    register_forward(FM_SetModel, "fw_SetModelPost", 1);
    register_forward(FM_AddToFullPack, "fw_AddToFullPackPost", 1);
    PrecacheReportTotals();
    OvhInit();

    g_msgWeather = get_user_msgid("ReceiveW");

    // Tek ayar dosyasi tablolari (konsoldan da calisir)
    static const TABLE_CMDS[][] =
    {
        "vex_item", "vex_class", "vex_sw", "vex_gun", "vex_job", "vex_boss_stat", "vex_boss_skill",
        "vex_mode_rule", "vex_env_event", "vex_env_mode", "vex_env_boss", "vex_env_calm", "vex_cosmetic", "vex_quest"
    };
    for (new i = 0; i < sizeof TABLE_CMDS; i++)
        register_srvcmd(TABLE_CMDS[i], "srv_TableCmd");
    register_srvcmd("vex_res", "srv_ResCmd");
    register_concmd("vex_reload", "cmd_reload_cfg", ADMIN_RCON, "- vexmira.cfg dosyasini yeniden yukler");

    // ReAPI hook'lari
    RegisterHookChain(RG_CSGameRules_CheckWinConditions, "rg_CheckWinConditions", false);
    RegisterHookChain(RG_CSGameRules_RestartRound,       "rg_RestartRound", false);
    RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd,   "rg_FreezeEnd", true);
    RegisterHookChain(RG_RoundEnd,                       "rg_RoundEnd", true);
    RegisterHookChain(RG_CBasePlayer_Spawn,              "rg_PlayerSpawn", true);
    RegisterHookChain(RG_CBasePlayer_TakeDamage,         "rg_TakeDamage", false);
    RegisterHookChain(RG_CBasePlayer_TakeDamage,         "rg_TakeDamagePost", true);
    RegisterHookChain(RG_CBasePlayer_Killed,             "rg_PlayerKilledPre", false);
    RegisterHookChain(RG_CBasePlayer_Killed,             "rg_PlayerKilled", true);
    RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed,      "rg_ResetMaxSpeed", true);
    RegisterHookChain(RG_CBasePlayer_HasRestrictItem,    "rg_HasRestrictItem", false);
    RegisterHookChain(RG_CBasePlayer_MakeBomber,         "rg_MakeBomber", false);
    RegisterHookChain(RG_CSGameRules_FlPlayerFallDamage, "rg_FallDamage", false);
    RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "rg_DefaultDeploy", false);
    RegisterHookChain(RG_ThrowHeGrenade,                 "rg_ThrowHe", true);
    RegisterHookChain(RG_ThrowSmokeGrenade,              "rg_ThrowSmoke", true);
    RegisterHookChain(RG_ThrowFlashbang,                 "rg_ThrowFlash", true);
    RegisterHookChain(RG_CGrenade_ExplodeHeGrenade,      "rg_ExplodeHe", false);
    RegisterHookChain(RG_CGrenade_ExplodeSmokeGrenade,   "rg_ExplodeSmoke", false);
    RegisterHookChain(RG_CGrenade_ExplodeFlashbang,      "rg_ExplodeFlash", false);
    RegisterHookChain(RG_CBasePlayer_Jump,               "rg_PlayerJump", false);
    // v3.0: [F] yedegi - baska bir plugin CmdStart'ta impulse 100'u yutsa bile yakalanir
    RegisterHookChain(RG_CBasePlayer_ImpulseCommands,    "rg_ImpulseCommands", false);

    // Lazer mayini hasari, bomba temasi, bomba modu degistirme (sag tik)
    RegisterHam(Ham_TakeDamage, "info_target", "fw_EntTakeDamage", 0);
    RegisterHam(Ham_Touch, "grenade", "fw_GrenadeTouch", 0);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_hegrenade", "fw_NadeAttack2", 0);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_smokegrenade", "fw_NadeAttack2", 0);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_flashbang", "fw_NadeAttack2", 0);
    RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "fw_NadeDeploy", 1);
    RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "fw_NadeDeploy", 1);
    RegisterHam(Ham_Item_Deploy, "weapon_flashbang", "fw_NadeDeploy", 1);

    // Sunucunun kendi MOTD'si yerine Vexmira karsilama penceresi
    register_message(get_user_msgid("MOTD"), "msg_Motd");

    for (new i = 0; i < sizeof GUN_CLASSES; i++)
        RegisterHam(Ham_Weapon_PrimaryAttack, GUN_CLASSES[i], "fw_PrimaryAttackPost", 1);

    register_forward(FM_CmdStart, "fw_CmdStart");
    register_forward(FM_PlayerPreThink, "fw_PreThink");
    register_forward(FM_EmitSound, "fw_EmitSound");
    register_forward(FM_ClientKill, "fw_ClientKill");

    // Chat
    // Chat ve /komutlar client_command() icinde yakalanir: plugins.ini'deki
    // baska bir chat plugin'i "say"i engellese bile Vexmira calismaya devam eder.
    g_tCmds = TrieCreate();
    g_tRoundBuys = TrieCreate();
    register_clcmd("chooseteam", "cmd_menu");
    register_clcmd("vexmenu", "cmd_menu");
    register_clcmd("nightvision", "cmd_nvg");
    // v3.0: yetenek tuslari icin yedek yollar (G = drop, konsol: vex_skill / vex_skill2)
    register_clcmd("drop", "cmd_drop");
    register_clcmd("vex_skill", "cmd_skill");
    register_clcmd("vex_skill2", "cmd_skill2");
    register_clcmd("+vex_skill", "cmd_skill");
    register_clcmd("-vex_skill", "cmd_skill_release");
    register_clcmd("+vex_skill2", "cmd_skill2");
    register_clcmd("-vex_skill2", "cmd_skill_release");

    RegisterSay("menu",     "",          "cmd_menu");
    RegisterSay("shop",     "market",    "cmd_shop");
    RegisterSay("items",    "esya",      "cmd_shop");
    RegisterSay("guns",     "silah",     "cmd_guns");
    RegisterSay("special",  "ozel",      "cmd_special");
    RegisterSay("class",    "sinif",     "cmd_class");
    RegisterSay("job",      "meslek",    "cmd_job");
    RegisterSay("perks",    "yetenek",   "cmd_perks");
    RegisterSay("daily",    "gunluk",    "cmd_daily");
    RegisterSay("title",    "unvan",     "cmd_title");
    RegisterSay("ach",      "basari",    "cmd_ach");
    RegisterSay("stats",    "istatistik","cmd_stats");
    RegisterSay("rank",     "rutbe",     "cmd_stats");
    RegisterSay("top",      "",          "cmd_top");
    RegisterSay("style",    "stil",      "cmd_style");
    RegisterSay("settings", "ayarlar",   "cmd_settings");
    RegisterSay("fps",      "performans","cmd_fps");
    RegisterSay("lang",     "dil",       "cmd_lang");
    RegisterSay("unstuck",  "takildim",  "cmd_unstuck");
    RegisterSay("help",     "yardim",    "cmd_help");
    RegisterSay("modes",    "modlar",    "cmd_modes");
    RegisterSay("vip",      "vipmenu",   "cmd_vip");
    RegisterSay("vipinfo",  "vipbilgi",  "cmd_vipinfo");
    RegisterSay("fun",      "eglence",   "cmd_fun");
    RegisterSay("dice",     "zar",       "cmd_dice");
    RegisterSay("coin",     "yazitura",  "cmd_coin");
    RegisterSay("joke",     "espri",     "cmd_joke");
    RegisterSay("dance",    "dans",      "cmd_dance");
    RegisterSay("rs",       "skorsifirla","cmd_resetscore");
    RegisterSay("time",     "saat",      "cmd_time");
    RegisterSay("ping",     "",          "cmd_ping");
    RegisterSay("who",      "kim",       "cmd_who");
    RegisterSay("owners",   "kurucular", "cmd_founders");
    RegisterSay("discord",  "iletisim",  "cmd_contact");
    RegisterSay("rules",    "kurallar",  "cmd_rules");
    RegisterSay("vote",     "oylama",    "cmd_vote");
    RegisterSay("admin",    "yonetim",   "cmd_adminmenu");
    RegisterSay("lm",       "lazer",     "cmd_lm_menu");
    RegisterSay("laser",    "mayin",     "cmd_lm_menu");
    RegisterSay("plant",    "lazerkur",  "cmd_lm_plant");
    RegisterSay("take",     "lazersok",  "cmd_lm_take");
    RegisterSay("nades",    "bomba",     "cmd_nade_menu");
    RegisterSay("quest",    "gorev",     "cmd_quest");
    RegisterSay("boss",     "bosslar",   "cmd_bossinfo");
    RegisterSay("round",    "harita",    "cmd_roundplan");
    RegisterSay("top10",    "siralama",  "cmd_top10");
    RegisterSay("hof",      "liderler",  "cmd_top10");
    RegisterSay("card",     "kart",      "cmd_card");
    RegisterSay("cosmetic", "kozmetik",  "cmd_cosmetic");
    RegisterSay("trail",    "iz",        "cmd_cosmetic");
    RegisterSay("skill",    "beceri",    "cmd_skill");
    RegisterSay("skill2",   "beceri2",   "cmd_skill2");
    // v3.0 (C): harita oylamasi (/nextmap /maps /rtv, vex_mapvote, cvar'lar)
    MapVoteInit();

    // Lazer: V = +setlaser, C = +dellaser (C varsayilan olarak radio3: hedef mayinsa sokulur)
    register_clcmd("+setlaser", "cmd_lm_plant");
    register_clcmd("-setlaser", "cmd_lm_release");
    register_clcmd("+dellaser", "cmd_lm_take");
    register_clcmd("-dellaser", "cmd_lm_release_take");
    register_clcmd("setlaser",  "cmd_lm_plant");
    register_clcmd("dellaser",  "cmd_lm_take");
    register_clcmd("vex_lm_plant", "cmd_lm_plant");
    register_clcmd("vex_lm_take",  "cmd_lm_take");
    register_clcmd("radio3", "cmd_radio3");

    // Admin
    register_concmd("vex_mode",    "cmd_adm_mode",  ADMIN_BAN,  "<0-9> - sonraki round modu");
    register_concmd("vex_event",   "cmd_adm_event", ADMIN_BAN,  "<0-16> - sonraki round eventi");
    register_concmd("vex_give_ap", "cmd_adm_ap",    ADMIN_RCON, "<isim> <miktar>");
    register_concmd("vex_give_vc", "cmd_adm_vc",    ADMIN_RCON, "<isim> <miktar>");
    register_concmd("vex_give_xp", "cmd_adm_xp",    ADMIN_RCON, "<isim> <miktar>");
    register_concmd("vex_vip_add",    "cmd_vip_add",    ADMIN_RCON, "<isim|#userid|STEAM_ID> <gun> <1=VIP 2=ELITE>");
    register_concmd("vex_vip_remove", "cmd_vip_remove", ADMIN_RCON, "<isim|#userid|STEAM_ID>");
    register_concmd("vex_vip_list",   "cmd_vip_list",   ADMIN_BAN,  "- online VIP listesi");
    register_concmd("vex_boss",       "cmd_adm_boss",   ADMIN_BAN,  "<0-8 | -1 rastgele> - siradaki boss");

    set_task(1.0, "task_Tick", TASK_TICK, _, _, "b");
    set_task(0.25, "task_ZombieVision", TASK_ZVISION, _, _, "b");
    set_task(0.2, "task_HudQueue", TASK_HUDQ, _, _, "b");
    set_task(0.1, "task_NadeTick", TASK_NADES, _, _, "b");
    set_task(0.1, "task_ZcTick", TASK_ZCTICK, _, _, "b");

    g_msgFlashlight = get_user_msgid("Flashlight");
    g_msgNVGToggle  = get_user_msgid("NVGToggle");

    g_fMapStart = get_gametime();
    g_iRound = 1;
    ShuffleBosses();
}

// configs/vexmira.cfg: TEK ayar dosyasi. Plugin satir satir okur ve uygular.
// Panel / server.cfg sonradan hostname vb. ezerse diye birkac saniye sonra tekrar uygulanir.
public plugin_cfg()
{
    new n = LoadMainConfig(false);
    log_amx("[Vexmira] vexmira.cfg yuklendi (%d satir).", n);

    LoadTop();
    set_task(1.5, "task_EnforceRoundInfinite", TASK_ROUNDINF);
    set_task(6.0, "task_LoadConfig", TASK_CFGLOAD);
    set_task(30.0, "task_Hostname", TASK_HOSTNAME, _, _, "b");
}

public plugin_end()
{
    if (g_hVault != INVALID_HANDLE)
    {
        for (new id = 1; id <= g_iMax; id++)
        {
            if (is_user_connected(id))
                SaveData(id);
        }
        nvault_close(g_hVault);
    }
    SaveTop();
    if (g_hVipVault != INVALID_HANDLE)
        nvault_close(g_hVipVault);
    if (g_tRes != Invalid_Trie)
        TrieDestroy(g_tRes);
}
