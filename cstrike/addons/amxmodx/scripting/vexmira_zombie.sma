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
      TEK DOSYALIK KAYNAK: Bu .sma tum Vexmira kodunu icerir.
      AMX Mod X include dosyalari (amxmodx, reapi vb.) disinda baska
      .inc klasorune bagimli degildir; .sma tek basina derlenebilir.
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
#define VERSION  "3.5"
#define AUTHOR   "SmurfSexy & Capital"

/* ================================================================== */
/*  BOLUM 1/13: CORE                                                  */
/*  Sabitler, enum'lar, veri tablolari, tum global degiskenler,       */
/*  kucuk ortak yardimcilar (menu, chat etiketi).                     */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ------------------------------------------------------------------ */
/*  Sabitler                                                           */
/* ------------------------------------------------------------------ */

#define MAX_LEVEL     60
#define NUM_CLASSES   24
#define NUM_BOSSES    9
#define NUM_JOBS      26
#define NUM_ITEMS     28
#define NUM_SPECIAL   16
enum { SWE_NONE = 0, SWE_FIRE, SWE_LIGHTNING, SWE_ICE, SWE_VAMPIRE, SWE_VOID, SWE_EXPLOSIVE };
#define NUM_PERKS     6
#define PERK_MAX      5
#define NUM_ACH       14
#define NUM_TITLES    10
#define NUM_STYLES    3
#define NUM_THEMES    6
#define NUM_RANKS     8
#define NUM_ADS       26
#define NUM_TIPS      18
#define MAX_FLARES    8

#define TASK_TICK     7001
#define TASK_ANNOUNCE 7002
#define TASK_LIGHT    7003
#define TASK_WELCOME  7100
#define TASK_LOADOUT  7200
#define TASK_METEOR   7400
#define TASK_VIPMSG   7500
#define TASK_SLOT     7600
#define TASK_REPLY    7700
#define TASK_JOIN     7800
#define TASK_VOTE     7900
#define TASK_BOSSCAST 8100
#define TASK_BOSSHIT  8200
#define TASK_ZVISION  8300
#define SET_NO_ZVISION (1<<8)

#define TASK_HUDQ     8400
#define TASK_PLANT    8500
#define TASK_LMTAKE   39700   // v3.2: lazer sokme denetimi (0.1 sn)
#define TASK_MOTD     8600
#define TASK_BOSSFX   8700
#define TASK_NADES    8800
#define TASK_INTRO    8900
#define TASK_CLUSTER  20000
#define TASK_WELCOME2 9100
#define TASK_MINEFX   9200
#define TASK_LOADWAIT 9300
#define TASK_ROUNDINF 9400
#define TASK_HOSTNAME 9500
#define HOSTNAME_MAX  63
#define TASK_CFGLOAD  9600
#define TASK_AUTOTEAM 34500   // ReGameDLL auto-join guvencesi
#define TASK_JOINCLASS 34600  // otomatik takim sonrasi sinif secimi
#define TASK_SNDSTOP  31000   // +0..63 (dongulu ses durdurma)
#define TASK_BSK      32000   // +0..255 (boss R yetenekleri, gecikmeli vuruslar)

#define HIT_HEAD      1

// Ekran yerlesimi: her mesaj turunun kendi satiri var, ayni satira
// ayni anda tek mesaj yazilir (digerleri sirada bekler) -> ic ice girme yok
#define Y_TOPBAR      0.0
#define Y_BOSS        0.115
#define Y_ANN         0.205
#define Y_COUNT       0.295
#define Y_ALERT       0.34
#define Y_AIM         0.53
#define Y_KILL        0.575
#define Y_PERS        0.655
#define Y_REWARD      0.745
#define NUM_HUDPOS    5

// Sirali buyuk yazi yuvalari (DHUD)
#define SL_ANN        0
#define SL_ALERT      1
#define SL_PERS       2
#define SL_KILL       3
#define SL_REWARD     4
#define NUM_SLOTS     5

// Chat oneki vexmira.cfg'deki vex_chat_prefix'ten gelir (^1 ^3 ^4 renk kodlari desteklenir)
#define CHAT_PREFIX   g_szPrefix

// Kisisel ayar bitleri (bit = KAPALI)
#define SET_NO_HUD     (1<<0)
#define SET_NO_DMGNUM  (1<<1)
#define SET_NO_FX      (1<<2)
#define SET_NO_AMB     (1<<3)
#define SET_NO_STREAK  (1<<4)
#define SET_NO_ADS     (1<<5)
#define SET_NO_AUTOGUN (1<<6)
#define SET_NO_FOG     (1<<7)
#define SET_NO_TIPS    (1<<9)
#define SET_NO_COS     (1<<10)   // v3.5: diger oyuncularin kanat / pet / sapkasini gizle

enum
{
    MODE_INFECTION = 0,
    MODE_MULTI,
    MODE_NEMESIS,
    MODE_ASSASSIN,
    MODE_SURVIVOR,
    MODE_SNIPER,
    MODE_SWARM,
    MODE_PLAGUE,
    MODE_ARMAGEDDON,
    MODE_BOSS,
    MODE_TOTAL
};

enum
{
    EV_NONE = 0,
    EV_BLOODMOON,
    EV_FOG,
    EV_SPEED,
    EV_LOWGRAV,
    EV_DOUBLEDMG,
    EV_NIGHT,
    EV_PLAGUE,
    EV_SUPPLY,
    EV_BERSERK,
    EV_ADRENALINE,
    EV_METEOR,
    EV_HORDE,
    EV_TITAN,
    EV_GOLDRUSH,
    EV_VAMPIRE,
    EV_HEADHUNTER,
    EV_STORM,
    EV_BLACKOUT,
    EV_TOTAL
};

// Insan meslekleri
enum
{
    JOB_MEDIC = 0, JOB_HEAVY, JOB_SCOUT, JOB_MARKSMAN, JOB_ENGINEER, JOB_LOOTER,
    JOB_GUNNER, JOB_DEMO, JOB_SNIPER, JOB_PARA, JOB_PYRO, JOB_CRYO,
    JOB_VAMPIRE, JOB_GUARDIAN, JOB_BERSERKER, JOB_COMMANDER,
    JOB_JUGGERNAUT, JOB_NINJA, JOB_GHOST, JOB_GRENADIER, JOB_HUNTER,
    JOB_DOCTOR, JOB_GAMBLER, JOB_TACTICIAN, JOB_LUCKY, JOB_ELITE
};

// Market esyalari
enum
{
    IT_MEDKIT = 0, IT_ARMOR, IT_FIRENADE, IT_FROSTNADE, IT_FLARE, IT_DJUMP,
    IT_BOOTS, IT_SERUM, IT_UNLCLIP, IT_DMGAMP, IT_RESPAWN,
    IT_ANTIDOTE, IT_MADNESS, IT_INFBOMB, IT_MUTAGEN, IT_RAGE, IT_RECHARGE, IT_ZARMOR,
    IT_ADREN, IT_HCLOAK, IT_NVG, IT_ESHIELD, IT_AMMO,
    IT_ZSPRINT, IT_ZCLOAK, IT_ZJUMP, IT_ZREGEN, IT_ZNOKB
};

// Kalici yetenekler (perk)
enum
{
    PK_VITALITY = 0, PK_PLATING, PK_FIREPOWER, PK_FORTUNE, PK_AGILITY, PK_HIDE
};

// Ozel bomba tipleri (var_impulse)
#define NADE_FIRE    7701
#define NADE_FROST   7702
#define NADE_INFECT  7703
#define NADE_FLARE   7704

// Bomba modlari (sag tik ile degisir)
#define NM_NORMAL    0
#define NM_IMPACT    1
#define NM_SENSOR    2
#define NM_LASER     3
#define NM_HOMING    4
#define NM_CLUSTER   5
#define NUM_NMODES   6

// Gorevler
#define NUM_QUESTS   8

/* ------------------------------------------------------------------ */
/*  Tablolar                                                           */
/* ------------------------------------------------------------------ */

new const SOUND_KEYS[][] =
{
    "ZOMBIE_INFECT", "ZOMBIE_PAIN", "ZOMBIE_DIE", "ROUND_START", "EVENT_START", "MODE_START",
    "BOSS_SPAWN", "BOSS_SLAM", "BOSS_SCREAM", "BOSS_SUMMON", "BOSS_DEATH",
    "COUNTDOWN_BEEP", "LEVEL_UP", "LAST_HUMAN", "LIGHTNING", "AMBIENT", "HEARTBEAT", "METEOR",
    "ABILITY_BURST", "ABILITY_LEAP", "ABILITY_SHIELD", "ABILITY_SCREAM", "ABILITY_DRAIN",
    "ABILITY_CLOAK", "ABILITY_TOXIC", "ABILITY_FROST",
    "HUMAN_WIN", "ZOMBIE_WIN", "ACH_UNLOCK", "SHOP_BUY", "DAILY",
    "HEADSHOT", "KILL_DOUBLE", "KILL_TRIPLE", "KILL_MULTI", "KILL_MEGA", "KILL_MONSTER",
    "STREAK_5", "STREAK_10", "STREAK_15",
    "NADE_FIRE", "NADE_FROST", "NADE_INFECT", "FREEZE", "BURN", "ANTIDOTE", "MADNESS",
    "SW_FIRE", "SW0_FIRE", "SW1_FIRE", "SW2_FIRE", "SW3_FIRE", "SW4_FIRE", "SW5_FIRE", "SW6_FIRE", "SW7_FIRE",
    "SW8_FIRE", "SW9_FIRE", "SW10_FIRE", "SW11_FIRE", "SW12_FIRE", "SW13_FIRE", "SW14_FIRE", "SW15_FIRE",
    "SW0_DRAW", "SW1_DRAW", "SW2_DRAW", "SW3_DRAW", "SW4_DRAW", "SW5_DRAW", "SW6_DRAW", "SW7_DRAW",
    "SW8_DRAW", "SW9_DRAW", "SW10_DRAW", "SW11_DRAW", "SW12_DRAW", "SW13_DRAW", "SW14_DRAW", "SW15_DRAW",
    "SW0_RELOAD", "SW1_RELOAD", "SW2_RELOAD", "SW3_RELOAD", "SW4_RELOAD", "SW5_RELOAD", "SW6_RELOAD", "SW7_RELOAD",
    "SW8_RELOAD", "SW9_RELOAD", "SW10_RELOAD", "SW11_RELOAD", "SW12_RELOAD", "SW13_RELOAD", "SW14_RELOAD", "SW15_RELOAD",
    "ZAP", "MVP", "VIP_JOIN", "BOSS_WARN", "BOSS_ROAR", "BOSS_ABILITY",
    "ZOMBIE_IDLE", "ZOMBIE_SLASH", "ZOMBIE_HITWALL", "ZOMBIE_HIT", "ZOMBIE_STAB", "ZOMBIE_ACID", "ZOMBIE_HEAL", "ZOMBIE_BLINK", "ZOMBIE_SHOCK",
    "WELCOME", "PLAYER_JOIN", "PLAYER_LEAVE", "BOSS_SOON", "BOSS_INTRO", "BOSS_STEP", "BOSS_PHASE", "BOSS_ENRAGE",
    "LM_DEPLOY", "LM_CHARGE", "LM_ACTIVATE", "LM_HIT", "LM_BREAK", "LM_PICKUP",
    "NADE_MODE", "NADE_BEEP", "NADE_ARM", "NADE_CLUSTER",
    "AIRDROP_INCOMING", "AIRDROP_LAND", "AIRDROP_LOOT", "QUEST_DONE", "EVOLVE",
    "SPEED_START", "SPEED_WIND", "STORM_STRIKE", "BLACKOUT", "FINAL_ROUND", "MAP_END",
    "FROST_NOVA", "THUNDER", "ACID_POOL", "GRAVITY_WELL", "ECLIPSE",
    // v2.0
    "ZONE_WARN", "SKILL_UNLOCK", "NEM_RAGE", "ASN_VEIL", "LM_KILL", "NADE_TRIGGER", "UI_OPEN", "LM_DENY",
    // v3.2 (B): CSO ekran bildirimi sesleri
    "CSO_KM", "CSO_KM_SP", "CSO_MVP", "CSO_BANNER", "CSO_WIN", "CSO_ALERT", "CSO_LEVEL",
    "CSO_FB", "CSO_BKILL", "CSO_INFD", "CSO_TEN"
};

// Zombi siniflari: 0 Walker 1 Runner 2 Tank 3 Banshee 4 Leech 5 Stalker 6 Bomber 7 Frost
// 8 Spitter 9 Hulk 10 Voodoo 11 Phantom | v3.0: 12 Butcher 13 Hunter 14 Charger 15 Arachne
// 16 Magma 17 Volt 18 Mimic 19 Burrower 20 Siren 21 Bulwark 22 Sporemother 23 Nightmare
new Float:CLASS_HP[NUM_CLASSES]   = { 1.0, 0.70, 1.80, 0.90, 1.10, 0.80, 1.00, 1.05, 0.90, 1.60, 0.95, 0.75,
                                      1.35, 0.85, 1.40, 0.85, 1.10, 0.95, 0.90, 1.00, 0.90, 1.70, 1.00, 0.90 };
new CLASS_SPD[NUM_CLASSES]        = { 270,  310,  235,  285,  265,  295,  260,  270,  280,  245,  275,  300,
                                      255,  300,  250,  290,  265,  280,  275,  270,  280,  240,  265,  290 };
new Float:CLASS_GRAV[NUM_CLASSES] = { 0.80, 0.70, 1.00, 0.80, 0.85, 0.75, 0.90, 0.80, 0.80, 1.00, 0.80, 0.70,
                                      0.90, 0.70, 1.00, 0.60, 0.80, 0.80, 0.80, 0.85, 0.80, 1.00, 0.80, 0.80 };
new Float:CLASS_KB[NUM_CLASSES]   = { 1.00, 1.30, 0.40, 1.00, 0.90, 1.10, 0.90, 0.90, 1.00, 0.50, 1.00, 1.20,
                                      0.60, 1.10, 0.50, 1.00, 0.90, 1.00, 1.00, 0.90, 1.00, 0.30, 1.00, 1.00 };
new Float:CLASS_COOL[NUM_CLASSES] = { 15.0, 8.0, 14.0, 12.0, 20.0, 18.0, 16.0, 18.0, 12.0, 16.0, 18.0, 9.0,
                                      16.0, 12.0, 15.0, 13.0, 18.0, 18.0, 22.0, 18.0, 17.0, 18.0, 15.0, 20.0 };
new CLASS_LVL[NUM_CLASSES]        = { 1, 1, 1, 1, 5, 8, 12, 16, 18, 20, 22, 25,
                                      3, 6, 9, 11, 13, 15, 17, 19, 21, 23, 26, 28 };
new CLASS_RGB[NUM_CLASSES][3]     =
{
    {0, 140, 0}, {255, 140, 0}, {40, 90, 255}, {200, 200, 255},
    {200, 0, 0}, {0, 110, 110}, {120, 255, 0}, {0, 200, 255},
    {150, 255, 0}, {255, 80, 0}, {255, 0, 180}, {120, 120, 255},
    {180, 30, 30}, {90, 90, 110}, {200, 120, 60}, {140, 0, 200},
    {255, 90, 0}, {80, 180, 255}, {160, 160, 160}, {140, 100, 50},
    {255, 90, 200}, {120, 140, 120}, {110, 200, 60}, {120, 0, 0}
};
// Sinif dosya adlari: modeller vex_z_<ad>, pence models/vexmira/claws/v_<ad>.mdl,
// sesler sound/vexmira/class/<ad>_pain/die/idle/ability.wav
new const CLASS_FILE[NUM_CLASSES][] =
{
    "walker", "runner", "tank", "banshee", "leech", "stalker", "bomber", "frost",
    "spitter", "hulk", "voodoo", "phantom", "butcher", "hunter", "charger", "arachne",
    "magma", "volt", "mimic", "burrower", "siren", "bulwark", "sporemother", "nightmare"
};
// Ozel model sunucuda yoksa kullanilan orijinal CS modeli (v2.0 varsayilanlari)
new const CLASS_OLDMODEL[NUM_CLASSES][] =
{
    "terror", "leet", "arctic", "guerilla", "terror", "leet", "arctic", "guerilla",
    "terror", "arctic", "guerilla", "leet", "terror", "leet", "arctic", "guerilla",
    "terror", "arctic", "guerilla", "leet", "guerilla", "arctic", "terror", "leet"
};

// Silah adlari (WeaponIdType sirasiyla) - V_<AD> / P_<AD> ayarlari icin
new const WEAPON_KEYNAME[31][] =
{
    "", "P228", "GLOCK", "SCOUT", "HEGRENADE", "XM1014", "C4", "MAC10", "AUG", "SMOKEGRENADE",
    "ELITE", "FIVESEVEN", "UMP45", "SG550", "GALIL", "FAMAS", "USP", "GLOCK18", "AWP", "MP5NAVY",
    "M249", "M3", "M4A1", "TMP", "G3SG1", "FLASHBANG", "DEAGLE", "SG552", "AK47", "KNIFE", "P90"
};

// Bosslar: Brute, Banshee, Overlord, Inferno, Reaper, Frostlord, Stormcaller, Hive Queen, Void
new Float:BOSS_HP_MULT[NUM_BOSSES] = { 1.00, 0.80, 1.15, 1.00, 0.90, 1.05, 0.95, 1.10, 1.20 };
new BOSS_SPD[NUM_BOSSES]           = { 255,  290,  260,  270,  300,  265,  285,  275,  280 };
new Float:BOSS_GRAV[NUM_BOSSES]    = { 0.85, 0.65, 0.85, 0.80, 0.60, 0.85, 0.75, 0.80, 0.55 };
new BOSS_RGB[NUM_BOSSES][3] =
{
    {255, 120, 0}, {190, 210, 255}, {160, 0, 255}, {255, 50, 0}, {120, 0, 190},
    {0, 190, 255}, {255, 240, 80}, {110, 255, 0}, {220, 0, 140}
};

// Mod rotasyonu: sans (%), minimum oyuncu
new MODE_CHANCE[MODE_TOTAL] = { 0, 15, 5, 4, 5, 4, 5, 3, 2, 0 };
new MODE_MINPL[MODE_TOTAL]  = { 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 };

// Meslek level kilitleri
new JOB_LVL[NUM_JOBS] = { 1, 1, 2, 3, 4, 5, 6, 8, 10, 12, 14, 16, 18, 21, 24, 28, 7, 9, 11, 13, 15, 17, 20, 23, 26, 32 };

// Market: fiyat (AP), takim (0 insan / 1 zombi), round limiti (0 = sinirsiz)
new ITEM_COST[NUM_ITEMS]  = { 12, 10, 12, 12, 5, 15, 10, 12, 35, 45, 50, 40, 20, 35, 15, 12, 10, 18, 15, 25, 8, 40, 10, 15, 20, 12, 25, 18 };
new const ITEM_TEAM[NUM_ITEMS]  = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1 };
new ITEM_LIMIT[NUM_ITEMS] = { 3, 2, 2, 2, 3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 3, 1, 2, 1, 1, 1, 2, 2, 1, 1, 1, 1 };
// v2.0: esya level kilidi ve ana deger (can / zirh / sure / yuzde ...) - vexmira.cfg: vex_item
new ITEM_LVL[NUM_ITEMS]   = { 1, 1, 1, 1, 1, 2, 1, 1, 3, 4, 2, 1, 1, 3, 1, 2, 1, 3, 2, 3, 1, 4, 1, 1, 2, 1, 3, 2 };
new ITEM_VAL[NUM_ITEMS]   = { 100, 200, 1, 1, 1, 1, 55, 12, 0, 20, 0, 0, 5, 3, 1500, 20, 0, 20, 6, 8, 0, 2, 0, 6, 6, 60, 80, 0 };
// Satin alininca herkese duyurulan esyalar
new const ITEM_ANNOUNCE[NUM_ITEMS] = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1 };

// Ozel silahlar
new const SW_BASE_ENT[NUM_SPECIAL][] =
{
    "weapon_elite", "weapon_ak47", "weapon_awp", "weapon_xm1014",
    "weapon_deagle", "weapon_p90", "weapon_ak47", "weapon_sg550",
    "weapon_m4a1", "weapon_m249", "weapon_awp", "weapon_xm1014",
    "weapon_deagle", "weapon_p90", "weapon_ak47", "weapon_sg550"
};
new const WeaponIdType:SW_BASE_ID[NUM_SPECIAL] =
{
    WEAPON_ELITE, WEAPON_AK47, WEAPON_AWP, WEAPON_XM1014,
    WEAPON_DEAGLE, WEAPON_P90, WEAPON_AK47, WEAPON_SG550,
    WEAPON_M4A1, WEAPON_M249, WEAPON_AWP, WEAPON_XM1014,
    WEAPON_DEAGLE, WEAPON_P90, WEAPON_AK47, WEAPON_SG550
};
new Float:SW_MULT[NUM_SPECIAL] = { 1.35, 1.2, 1.9, 1.3, 1.5, 1.25, 1.35, 1.6, 1.3, 1.2, 1.7, 1.25, 1.4, 1.2, 1.3, 1.45 };
new SW_COST[NUM_SPECIAL]       = { 80, 100, 120, 85, 70, 95, 105, 135, 90, 115, 140, 100, 75, 110, 120, 150 };
new SW_LVL[NUM_SPECIAL]        = { 3, 8, 12, 5, 4, 10, 15, 20, 6, 11, 16, 8, 7, 13, 19, 24 };
new SW_BPAMMO[NUM_SPECIAL]     = { 180, 300, 60, 64, 70, 200, 180, 180, 180, 300, 60, 64, 70, 200, 180, 180 };
new SW_CLIP[NUM_SPECIAL]       = { 30, 100, 10, 7, 7, 50, 30, 30, 30, 100, 10, 7, 7, 50, 30, 30 };
new SW_CHAIN_DMG[NUM_SPECIAL]  = { 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 45, 0, 0, 0, 0, 0 };
new Float:SW_RATE[NUM_SPECIAL] = { 0.10, 0.08, 1.5, 0.25, 0.23, 0.07, 0.10, 0.20, 0.10, 0.08, 1.5, 0.25, 0.23, 0.07, 0.10, 0.20 };
new Float:SW_RECOIL[NUM_SPECIAL] = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 };
new SW_EFFECT[NUM_SPECIAL] = { 0, 1, 2, 3, 0, 1, 4, 5, 0, 1, 2, 3, 0, 1, 4, 5 };
new SW_RGB[NUM_SPECIAL][3]     =
{
    {0, 220, 255}, {255, 110, 0}, {200, 220, 255}, {120, 220, 255},
    {255, 210, 0}, {255, 60, 0}, {170, 0, 255}, {90, 0, 160},
    {60, 255, 240}, {255, 80, 30}, {130, 200, 255}, {80, 190, 255},
    {255, 180, 40}, {255, 35, 20}, {180, 50, 255}, {120, 30, 200}
};
new g_szSWName[2][NUM_SPECIAL][48], g_szSWDesc[2][NUM_SPECIAL][80];

// Perk maliyeti: (seviye + 1) * vex_perk_cost_step VC
#define PERK_COST_STEP max(1, get_pcvar_num(g_pPerkStep))

// Basarim -> unvan eslesmesi (-1 = herkese acik)
new const TITLE_ACH[NUM_TITLES] = { -1, 3, 2, 5, 7, 8, 10, 13, 12, 11 };

// Rutbe esikleri
new const RANK_LVL[NUM_RANKS] = { 1, 5, 10, 18, 26, 35, 45, 55 };

// Tema renkleri: A = ana (marka satiri, panel basligi), B = vurgu (sayilar), C = panel govdesi
new const THEME_A[NUM_THEMES][3] =
{
    {160, 90, 255}, {70, 255, 110}, {255, 55, 55}, {175, 95, 255}, {40, 150, 255}, {255, 130, 40}
};
new const THEME_B[NUM_THEMES][3] =
{
    {0, 220, 255}, {255, 90, 60}, {255, 170, 60}, {255, 90, 190}, {0, 230, 200}, {255, 60, 120}
};
new const THEME_C[NUM_THEMES][3] =
{
    {0, 200, 255}, {160, 255, 180}, {255, 150, 140}, {210, 170, 255}, {140, 200, 255}, {255, 195, 140}
};

// Silah menusu
new const PRIM_NAME[][] = { "AK-47", "M4A1 Carbine", "FAMAS", "Galil", "MP5 Navy", "UMP45", "P90", "M3 Super 90", "XM1014", "AUG", "SG552", "M249 SAW", "AWP", "G3SG1" };
new const PRIM_ENT[][]  = { "weapon_ak47", "weapon_m4a1", "weapon_famas", "weapon_galil", "weapon_mp5navy", "weapon_ump45", "weapon_p90", "weapon_m3", "weapon_xm1014", "weapon_aug", "weapon_sg552", "weapon_m249", "weapon_awp", "weapon_g3sg1" };
new PRIM_AMMO[]   = { 180, 180, 180, 180, 240, 200, 200, 64, 64, 180, 180, 300, 60, 120 };
new PRIM_LVL[]    = { 1, 1, 1, 1, 1, 2, 3, 2, 4, 6, 7, 9, 12, 14 };

new const SEC_NAME[][]  = { "USP", "Glock-18", "P228", "Desert Eagle", "Dual Elites", "Five-seveN" };
new const SEC_ENT[][]   = { "weapon_usp", "weapon_glock18", "weapon_p228", "weapon_deagle", "weapon_elite", "weapon_fiveseven" };
new SEC_AMMO[]    = { 100, 120, 52, 70, 120, 100 };
new SEC_LVL[]     = { 1, 1, 1, 2, 3, 5 };

// Tum atesli silah siniflari (sinirsiz sarjor + ozel silah efektleri)
new const GUN_CLASSES[][] =
{
    "weapon_p228", "weapon_scout", "weapon_xm1014", "weapon_mac10", "weapon_aug",
    "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil",
    "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy",
    "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1",
    "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_p90"
};

// Knockback gucu (WeaponIdType sirasina gore, 0-30)
new const Float:KB_POWER[31] =
{
    0.0,  2.4, 0.0, 6.5, 0.0, 8.0, 0.0, 2.3, 5.0, 0.0,
    2.4,  2.0, 2.4, 5.3, 5.5, 5.5, 2.2, 2.0, 10.0, 2.5,
    5.2,  8.0, 5.0, 2.4, 6.5, 0.0, 5.3, 5.0, 6.0, 0.0,
    2.0
};

#define VIP_AURA_COUNT 6

new const VIP_AURA_RGB[VIP_AURA_COUNT][3] =
{
    {0, 0, 0}, {0, 200, 255}, {255, 200, 0}, {180, 0, 255}, {255, 40, 40}, {0, 255, 120}
};

new const VOX_NUM[][] = { "", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten" };

/* ---------------- v2.0: ortam (isik / sis / hava) ----------------
   vexmira.cfg: vex_env_event / vex_env_mode / vex_env_boss / vex_env_calm
   isik: a (zifiri karanlik) .. m (normal) .. z (cok parlak), 0 = dokunma
   sis: R G B yogunluk (yogunluk x10000, 0 = sis yok)
   hava: 0 = acik, 1 = yagmur, 2 = kar                                    */
new ENV_EV_LIGHT[EV_TOTAL]   = { 'm', 'c', 'g', 'm', 'k', 'l', 'b', 'h', 'm', 'i', 'n', 'g', 'f', 'e', 'n', 'c', 'j', 'f', 'a' };
new ENV_EV_FOG[EV_TOTAL][4]  =
{
    {0, 0, 0, 0},       {90, 0, 10, 25},    {150, 150, 150, 45}, {0, 60, 90, 15},   {40, 20, 80, 15},
    {90, 40, 0, 12},    {0, 0, 20, 20},     {20, 90, 0, 25},     {0, 0, 0, 0},      {100, 20, 0, 18},
    {0, 80, 40, 10},    {120, 50, 0, 25},   {30, 60, 0, 25},     {80, 0, 0, 20},    {120, 100, 20, 15},
    {60, 0, 20, 28},    {60, 30, 0, 12},    {90, 100, 120, 25},  {0, 0, 0, 35}
};
new ENV_EV_WEATHER[EV_TOTAL] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0 };

new ENV_MODE_LIGHT[MODE_TOTAL]   = { 0, 0, 'd', 'a', 'h', 'g', 'f', 'e', 'c', 0 };
new ENV_MODE_FOG[MODE_TOTAL][4]  =
{
    {0, 0, 0, 0}, {0, 0, 0, 0}, {60, 0, 0, 30}, {10, 0, 20, 40}, {0, 40, 90, 20},
    {0, 60, 30, 15}, {60, 40, 0, 20}, {60, 0, 80, 25}, {120, 30, 0, 35}, {0, 0, 0, 0}
};
new ENV_MODE_WEATHER[MODE_TOTAL] = { 0, 0, 0, 0, 1, 0, 0, 0, 1, 0 };

new ENV_BOSS_LIGHT[NUM_BOSSES]   = { 'e', 'f', 'd', 'e', 'c', 'i', 'e', 'f', 'b' };
new ENV_BOSS_FOG[NUM_BOSSES][4]  =
{
    {80, 40, 0, 20}, {60, 70, 100, 30}, {40, 0, 60, 30}, {120, 40, 0, 30}, {20, 0, 40, 35},
    {150, 180, 210, 30}, {70, 80, 100, 30}, {40, 90, 0, 30}, {40, 0, 40, 40}
};
new ENV_BOSS_WEATHER[NUM_BOSSES] = { 0, 0, 0, 0, 0, 2, 1, 0, 0 };

// Sakin roundlar icin hava durumu hazirlari: gunduz, alacakaranlik, gece, yagmur, kar, sis
#define NUM_CALM 6
new ENV_CALM_LIGHT[NUM_CALM]   = { 'm', 'h', 'd', 'i', 'k', 'j' };
new ENV_CALM_FOG[NUM_CALM][4]  = { {0, 0, 0, 0}, {90, 50, 30, 12}, {0, 0, 30, 18}, {70, 80, 90, 20}, {170, 180, 200, 20}, {120, 120, 130, 30} };
new ENV_CALM_WEATHER[NUM_CALM] = { 0, 0, 0, 1, 2, 0 };

/* ---------------- v2.0: boss R yetenekleri (faza gore) ----------------
   Her bossun 3 R yetenegi var: faz 1, faz 2, faz 3 (delilik). Yeni faza
   gecince R tusuna yeni yetenek gelir, eski yetenekler boss'un otomatik
   saldirilarina eklenir. vexmira.cfg: vex_boss_skill <boss> <faz> <bekleme> <hasar> <yaricap> */
new Float:BSK_COOL[NUM_BOSSES][3] =
{
    {9.0, 13.0, 24.0}, {9.0, 14.0, 26.0}, {10.0, 18.0, 24.0}, {8.0, 14.0, 28.0}, {8.0, 16.0, 24.0},
    {8.0, 15.0, 28.0}, {9.0, 12.0, 28.0}, {8.0, 16.0, 26.0}, {8.0, 15.0, 28.0}
};
new Float:BSK_DMG[NUM_BOSSES][3] =
{
    {35.0, 40.0, 15.0}, {25.0, 30.0, 10.0}, {20.0, 15.0, 35.0}, {20.0, 45.0, 85.0}, {0.0, 6.0, 60.0},
    {18.0, 25.0, 10.0}, {8.0, 30.0, 35.0}, {20.0, 0.0, 30.0}, {25.0, 40.0, 8.0}
};
new BSK_RAD[NUM_BOSSES][3] =
{
    {320, 110, 230}, {650, 320, 1200}, {900, 600, 250}, {450, 140, 700}, {800, 600, 150},
    {900, 800, 0}, {170, 130, 140}, {150, 260, 180}, {1000, 450, 600}
};

/* ------------------------------------------------------------------ */
/*  Globaller                                                          */
/* ------------------------------------------------------------------ */

new g_iMax, g_msgFog, g_msgFade, g_msgShake, g_msgDeath, g_msgScore, g_hVault;
new g_sprRing, g_sprBeam, g_sprLightning, g_sprExplode, g_sprSmoke, g_sprBlood, g_sprBloodSpray, g_sprHeadMark;
new bool:g_bGeoIP;

new g_iRound, g_iMode, g_iEvent, g_iCountdown, g_iFrame;
new g_iForceEvent = -1, g_iForceMode = -1, g_iForceBoss = -1;
new g_iBossBag[NUM_BOSSES], g_iBossBagPos = NUM_BOSSES, bool:g_bFinalBoss, g_iLastSpecial = -1;
new g_iBossPhase, g_iBossDmg[33];
new g_iBoss, g_iBossType, g_iBossMaxHP, g_iBossTick, g_iMeteorTick, g_iGlobalInfBombs;
new bool:g_bWaiting, bool:g_bCounting, bool:g_bRoundActive, bool:g_bRoundEnded, bool:g_bEnraged, bool:g_bLastAnn;
new bool:g_bAdminEnvOverride, g_iAdminEnvLight = 'm', g_iAdminEnvFog[4], g_iAdminEnvWeather;
new g_szLight[4] = "m";

new Float:g_fFlarePos[MAX_FLARES][3], Float:g_fFlareEnd[MAX_FLARES];

// Durum
new g_bZombie[33], g_bNemesis[33], g_bAssassin[33], g_bSurvivor[33], g_bSniper[33];
new g_bBoss[33], g_bMinion[33], g_bFirst[33], g_bForceZombie[33];
new g_iClass[33], g_iClassPicked[33], g_iMaxHP[33];

// Kalici veri
new g_iXP[33], g_iLevel[33], g_iAP[33], g_iVC[33];
new g_iKills[33], g_iInfects[33], g_iWins[33], g_iBossK[33], g_iHS[33];
new g_iAch[33], g_iTitle[33], g_iJob[33], g_iStyle[33], g_iSet[33], g_iTheme[33], g_iLang[33];
new g_iDailyDay[33], g_iDailyStreak[33], g_iPrim[33], g_iSec[33], g_iPlaySec[33];
new g_iPerk[33][NUM_PERKS], g_iHudPos[33], Float:g_fGrav[33];

// Round verisi
new g_iDmgBank[33], g_iRoundDmg[33], g_iRoundInf[33], g_iRoundAP[33], g_iRoundXP[33];
new g_iStreak[33], g_iMulti[33], Float:g_fLastKill[33];
new g_iBought[33][NUM_ITEMS], g_iPrimTmp[33];

// Esyalar / efektler
new g_iExtraJumps[33], g_iJumps[33], g_bBoots[33], g_bSerum[33], g_bRage[33], g_bUnlClip[33], g_bDmgAmp[33], g_bZArmor[33];
new g_iFireNades[33], g_iFrostNades[33], g_iFlares[33], g_iInfNades[33], g_iSpecW[33];
new g_iBurn[33], g_iBurnBy[33];
new Float:g_fFrozen[33], Float:g_fSlow[33], Float:g_fMadness[33];
new Float:g_fCool[33], Float:g_fShield[33], Float:g_fBurst[33], Float:g_fCloak[33];
new Float:g_fInfectTime[33], Float:g_fRespawnAt[33], Float:g_fUnstuck[33];
new bool:g_bChaining;

// v1.2: yeni esya durumlari, admin, oylama
new Float:g_fHBoost[33], g_iEShield[33], g_bZRegen[33], g_bNoKB[33];
new g_iAdmTarget[33], bool:g_bRespawnOff;
new g_iVoteType, g_iVoteLeft, g_iVoteOpt[4], g_iVoteCount[4], g_iVoted[33], g_pVoteEvery;

// VIP
new g_hVipVault, g_iVip[33], g_iVipExpire[33], g_iVipAura[33], g_bVipTrail[33], g_bVipFreeUsed[33];

// Eglence / canli sunucu
new Float:g_fFunCd[33], Float:g_fGiftCd[33], Float:g_fReplyCd, Float:g_fPlayerReplyCd[33];
new g_iSlotBet[33], g_bSlotting[33], g_iTickets[33], g_iLottoPot, g_iLottoClock, g_iBounty[33];
new g_iMapKills[33], g_iLastSeen[33], g_bNewPlayer[33], g_iHumanStreak, g_iZombieStreak, bool:g_bFirstInfect;
new g_szReplyBase[24];

new Trie:g_tRes, Trie:g_tCmds, Float:g_fLastSay[33];
new g_szZModel[NUM_CLASSES][32], g_szBModel[NUM_BOSSES][32];
new g_szNemModel[32], g_szAsnModel[32], g_szSurvModel[32], g_szSnipModel[32];
new g_szHumanModel[32], g_szVipModel[32], g_szAdminModel[32];
new g_szClawModel[96], g_szSWView[NUM_SPECIAL][96], g_szSWPlayer[NUM_SPECIAL][96];
// Mod silahlari (vex_modewpn): [0] survivor, [1] sniper; her biri 2 yuva.
#define MW_MODES 2
#define MW_SLOTS 2
new g_szMwV[MW_MODES][MW_SLOTS][96], g_szMwP[MW_MODES][MW_SLOTS][96];
new MW_ENT[MW_MODES][MW_SLOTS][24] = { { "weapon_m249", "weapon_deagle" }, { "weapon_awp", "" } };
new WeaponIdType:MW_ID[MW_MODES][MW_SLOTS] = { { WEAPON_M249, WEAPON_DEAGLE }, { WEAPON_AWP, WEAPON_NONE } };
new Float:MW_DMG[MW_MODES][MW_SLOTS] = { { 1.5, 1.5 }, { 5000.0, 1.0 } }; // > 50 = sabit mermi hasari
new MW_CLIP[MW_MODES][MW_SLOTS] = { { 0, 0 }, { 0, 0 } };                // 0 = silahin kendi sarjoru
new MW_BP[MW_MODES][MW_SLOTS] = { { 400, 100 }, { 100, 0 } };
new MW_FX[MW_MODES][MW_SLOTS];                                          // SWE_* (varsayilan yok)
new const MW_KEY[MW_MODES][] = { "SURVIVOR", "SNIPER" };
new g_szZClaw[NUM_CLASSES][96], g_szBClaw[NUM_BOSSES][96], g_szNemClaw[96], g_szAsnClaw[96];
new g_szWepV[31][96], g_szWepP[31][96], bool:g_bEmitting;
new g_szVipKnifeV[96], g_szVipKnifeP[96], bool:g_bVipRegun[33];
new g_pVipPriority, g_pVipAnnounce, g_pVipVoteW, g_pVipSpawnProt, g_pVipDaily, g_pEliteDaily, g_pVipKillIcon, g_pVipScore, g_pVipRegun;
new bool:g_bVoxCountdown = true;

// v1.4: HUD sirasi, karsilama, gorev, evrim, lazer, bomba modlari, ikmal
new Float:g_fSlotEnd[33][NUM_SLOTS], g_szSlotQ[33][NUM_SLOTS][128], g_iSlotQC[33][NUM_SLOTS], Float:g_fSlotQH[33][NUM_SLOTS], Float:g_fSlotQT[33][NUM_SLOTS];
new bool:g_bWelcomed[33], bool:g_bMotdShown[33], Float:g_fMapStart;
new g_iRoundKills[33], g_iRoundHS[33], g_iQuest[33], bool:g_bQuestDone[33], bool:g_bAlpha[33];
new g_iMapInf[33], g_iMapBossDmg[33];
new g_iMines[33], g_iPlantAction[33], bool:g_bMineHint[33];
new g_iNadeMode[33][3], Float:g_fNadeHud[33];
new g_iAirdropClock, g_iBossFxStep, Float:g_fBossFxPos[3];
#define MAX_POOLS 16
new Float:g_fPoolPos[MAX_POOLS][3], Float:g_fPoolEnd[MAX_POOLS], Float:g_fEclipseEnd, Float:g_fBlizzardEnd;
new g_sprLaser, g_sprFlare, g_szMineModel[96], g_szDropModel[96], g_szSky[32];
new Float:g_fBossIntro, g_iPoison[33], g_iPoisonBy[33];

// v1.5: kozmetik (Vex Coin ile kalici), tum zamanlarin siralamasi
#define NUM_TRAILS   6
#define NUM_KFX      6
#define NUM_IFX      3
#define TOP_MAX      15
new g_iCosOwned[33], g_iTrailSel[33], g_iKfxSel[33], g_iIfxSel[33], g_iTopRank[33];
new g_szKey[33][48], bool:g_bLoaded[33], g_iClassNext[33], g_iJobNext[33], bool:g_bClassSwitched[33];
new bool:g_bGunsGiven[33], bool:g_bNadesGiven[33], bool:g_bTrailOn[33], Trie:g_tRoundBuys, g_iStartTries, bool:g_bAnnounced;
new g_szTopKey[TOP_MAX][48], g_szTopName[TOP_MAX][32], g_iTopXP[TOP_MAX], g_iTopKills[TOP_MAX], g_iTopInf[TOP_MAX], g_iTopBoss[TOP_MAX], g_iTopCount, bool:g_bTopDirty;

// Cvar'lar
new g_pCountdown, g_pFirstHP, g_pZombieHP, g_pBossEvery, g_pBossHP, g_pEventChance;
new g_pNemHP, g_pAsnHP, g_pSurvHP, g_pSnipHP, g_pRespawn, g_pDmgPerAP, g_pKnockback;
new g_pStartAP, g_pArmorProtect, g_pVipContact, g_pChatBcast, g_pChatBuyBcast;
new g_pVipBonus, g_pEliteBonus, g_pVipDisc, g_pEliteDisc, g_pVipArmor, g_pEliteArmor, g_pVipRoundVC, g_pVipAutoPack;
new g_pTipInterval, g_pLiveChatter, g_iTipIdx, g_iTipClock;
new g_pBossRounds, g_pBossHPPer, g_pBossFinal, g_pBossDmg, g_pBossAbil, g_pSpecialRounds, g_pMultiChance, g_pRoundsTotal;
new g_pSpeedHuman, g_pSpeedZombie, g_pSpeedFov, g_pNemDmg, g_pAsnDmg, g_pMinionDmg, g_pZombieDmg, g_pHumanHP;
new g_pZSpeed, g_pHSpeed, g_pMvpAP, g_pMvpVC, g_pGiveNades, g_pLastHumanHP, g_pInfectAP, g_pKillAP;
new g_pLmEnable, g_pLmMax, g_pLmMaxVip, g_pLmTeamMax, g_pLmHealth, g_pLmDamage, g_pLmZMult, g_pLmWear, g_pLmBoss;
new g_pNadeModes, g_pNadeProx, g_pNadeLaser, g_pNadeHoming, g_pCluster;
new g_pAirdrop, g_pAirdropEvery, g_pMotd, g_pQuests, g_pEvolve, g_pJoinMsg;

/* ---------------- v2.0 globaller ---------------- */
new g_szPrefix[64] = "^4[VEX]^1";

// v2.0 kaynaklar
new g_szSprZone[64], g_szSprTarget[64], g_szSprBeacon[64], g_szSprOrb[64], g_szSprMark[64], g_szSprFire[64], g_szSprLaser[64];
new g_iMineBody, g_iMineSeq, g_iMineSkin;
// Mayin yonu (v3.0 hizalama): yuzeyden uzaklik, model uzayinda isin cikis noktasi, isin ekseni (E),
// modelin "ust" ekseni (U) ve cfg aci ofseti (LASERMINE_ANGLES "pitch yaw roll")
new Float:g_fMineOff, Float:g_fMineEmit[3], Float:g_fMineAxE[3], Float:g_fMineAxU[3], Float:g_fMineAngOfs[3];

// v2.0 cvar'lar
new g_pPrefix, g_pHostname, g_pHostDyn, g_pEnv, g_pEnvCalm, g_pWeather;
new g_pZHPPer, g_pNemHPPer, g_pAsnHPPer, g_pKBMult, g_pSpecCap;
new g_pNemOneShot, g_pAsnOneShot, g_pNemVsSurv, g_pNemSpeed, g_pAsnSpeed, g_pNemGrav, g_pAsnGrav, g_pMinionHP;
new g_pNemRageTime, g_pNemRageCd, g_pAsnVeilTime, g_pAsnVeilCd, g_pSpecialLeapCd;
new g_iLmTakeEnt[33];
new g_pMeteorEvery, g_pMeteorCount;
new g_pLmPerRound, g_pLmPerRoundVip, g_pLmOneShot, g_pLmSpecialDmg, g_pLmKillWear, g_pLmPlantTime, g_pLmTakeTime;
new g_pLmArmTime, g_pLmBeamWidth, g_pLmColorMode, g_pLmColor, g_pLmRange, g_pLmTakeRange, g_pAirdropLaser;
// v3.1: lazer isini azami boyu, lazerin kapali oldugu modlar, yon testi kaydi (gelistirici)
new g_pLmMaxRange, g_pLmBlockModes, g_pDbgDirs;
new g_pAutoJoinHumans;
new g_szLmBlockCache[64], g_iLmBlockMask = -1;
// v3.1: kafa ustu isaret sprite'lari TE_PLAYERATTACHMENT ile cizilebilir mi (yalniz alphatest)
new bool:g_bHeadMarkAt, bool:g_bMarkAt;
new g_pNadeSensorArm, g_pNadeSensorLife, g_pNadeLaserArm, g_pNadeFireDmg, g_pNadeFireRad, g_pNadeFireBurn;
new g_pNadeFrostRad, g_pNadeFrostTime, g_pNadeInfectRad, g_pNadeFlareTime, g_pNadeClusterDmg;
new g_pBossPhase2, g_pBossPhase3, g_pBossRAuto, g_pBossRCdMult, g_pBossRDmgMult, g_pBossAutoAbil;
new g_pAfkTime, g_pAfkAction, g_pDropBeacon, g_pDropCompass, g_pLoopGuard, g_pLoopMax, g_pRoundStopSnd;
new g_pKillXP, g_pInfectXP, g_pWinHXP, g_pWinHAP, g_pWinZXP, g_pWinZAP, g_pBossKillXP, g_pBossKillAP, g_pBossKillVC;
new g_pSpecKillXP, g_pSpecKillAP, g_pBossBoard, g_pHsAP, g_pExchange, g_pPerkStep, g_pDailyAP, g_pAchAP, g_pAchVC;
new g_pBurnDmg, g_pZombieBurnDmg, g_pAirdropHP;

// Ortam durumu
new g_msgWeather, g_iCalmPreset = -1;

// Ses: dongulu wav tespiti (yol -> bilgi). Bilgi = (dongulu ? 1 : 0) | (sure_ms << 1)
new Trie:g_tSndInfo, g_iSndStopSlot;

// Lazer: round basi hak verildi mi
new bool:g_bLmGiven[33];
new Float:g_fNextBeat[33];

// Ozel sprite'lar (yoksa orijinal oyun dosyalarina duser)
new g_sprZone, g_sprTarget, g_sprBeacon, g_sprOrb, g_sprMark, g_sprFire, g_sprLmBeam;

// Boss R yetenekleri
new Float:g_fBossRCool, Float:g_fBossRLast, g_iBossSerial, g_iBskSlot;
new Float:g_fBossBuffEnd, Float:g_fBossEmpower, Float:g_fBossChannelEnd, g_iBossChannel, g_iBossChannelTick;
new Float:g_fBossChannelPos[3], g_iBossTethers[3];

// Nemesis / Assassin [F] yetenegi
new Float:g_fFCool[33], Float:g_fRage[33];

// AFK
new Float:g_fAfkPos[33][3], Float:g_fAfkAng[33][3], g_iAfkSec[33];

// Tehlike alanlari / boss mermileri / yumurtalar
#define ZONE_CLASS "vex_zone"
#define PROJ_CLASS "vex_bproj"
#define EGG_CLASS  "vex_egg"
#define TASK_BCHAN (TASK_BSK + 255)
new bool:g_bFxReliable;

enum
{
    PJ_NONE = 0,
    PJ_ORB,
    PJ_ACID,
    PJ_VOID
};

// Boss kanal (sureli) yetenekleri
enum
{
    CH_NONE = 0,
    CH_TITAN,
    CH_REQUIEM,
    CH_CHAINS,
    CH_ZERO,
    CH_DASH,
    CH_TEMPEST,
    CH_CLOUD,
    CH_SINGULARITY,
    CH_HORIZON
};

new g_iDashHit;
new g_iPoolType[MAX_POOLS], Float:g_fPoolRad[MAX_POOLS], g_iPoolOwner[MAX_POOLS];

/* ---------------- v3.0: yeni zombi siniflari (12-23) + [F] tusu duzeltmesi ---------------- */
enum
{
    ZC_WALKER = 0, ZC_RUNNER, ZC_TANK, ZC_BANSHEE, ZC_LEECH, ZC_STALKER, ZC_BOMBER, ZC_FROST,
    ZC_SPITTER, ZC_HULK, ZC_VOODOO, ZC_PHANTOM,
    ZC_BUTCHER, ZC_HUNTER, ZC_CHARGER, ZC_ARACHNE, ZC_MAGMA, ZC_VOLT, ZC_MIMIC, ZC_BURROWER,
    ZC_SIREN, ZC_BULWARK, ZC_SPOREMOTHER, ZC_NIGHTMARE
};

// Sinif yetenek ayarlari (vexmira.cfg: vex_<sinif>_<ayar>)
enum
{
    ZCV_HOOK_SPEED = 0, ZCV_HOOK_RANGE, ZCV_HOOK_PULL, ZCV_HOOK_TIME, ZCV_HOOK_DMG,
    ZCV_HUNT_POWER, ZCV_HUNT_UP, ZCV_HUNT_RAD, ZCV_HUNT_STUN, ZCV_HUNT_DMG,
    ZCV_CHG_TIME, ZCV_CHG_SPEED, ZCV_CHG_DMG, ZCV_CHG_PUSH, ZCV_CHG_STUN,
    ZCV_WEB_SPEED, ZCV_WEB_RANGE, ZCV_WEB_ROOT, ZCV_WEB_SLOW, ZCV_WEB_DMG,
    ZCV_MAG_TIME, ZCV_MAG_LIFE, ZCV_MAG_RAD, ZCV_MAG_DMG, ZCV_MAG_IMMUNE,
    ZCV_VOLT_RAD, ZCV_VOLT_MINE, ZCV_VOLT_LIGHT, ZCV_VOLT_DMG, ZCV_VOLT_SLOW,
    ZCV_MIM_TIME, ZCV_MIM_MULT,
    ZCV_BUR_TIME, ZCV_BUR_SPEED, ZCV_BUR_RAD, ZCV_BUR_UP, ZCV_BUR_DMG,
    ZCV_SIR_RAD, ZCV_SIR_TIME, ZCV_SIR_PULL,
    ZCV_BUL_TIME, ZCV_BUL_REDUCE, ZCV_BUL_REFLECT,
    ZCV_SPO_MAX, ZCV_SPO_RAD, ZCV_SPO_HP, ZCV_SPO_POISON, ZCV_SPO_LIFE, ZCV_SPO_SLOW,
    ZCV_NM_RAD, ZCV_NM_BLIND, ZCV_NM_BOOST, ZCV_NM_SPEED,
    ZCV_BOT, ZCV_ALTKEYS,
    ZCV_TOTAL
};
new g_pZc[ZCV_TOTAL];

#define ZPROJ_CLASS   "vex_zproj"     // kasap kancasi / orumcek agi mermisi
#define SPORE_CLASS   "vex_spore"     // spor kesesi tuzagi
#define ZP_HOOK       1
#define ZP_WEB        2
#define BEAM_MARK_HOOK 7779
#define BEAM_POINTS   0     // beam varligi turu (rendermode & 0x0F): iki nokta
#define BEAM_ENTPOINT 1     // varlik (+ ek noktasi, sequence) -> nokta (angles)
#define TASK_ZCTICK   33500
// v3.0 (C)
#define TASK_AMBREST  34000   // ortam sesleri (ambient_generic) yeniden baslatma
#define TASK_MAPVOTE  34100   // harita oylamasi sayaci
#define TASK_MAPCHG   34200   // harita degisimi (ara ekran + changelevel)
#define TASK_MAPHOLD  34300   // son round: yeni round baslamasin
#define TASK_MAPWARN  34400   // mapchooser.amxx kontrolu

// [R] / [F] tetikleme (tus / komut / chat) - ayni tetik 0.2 sn icinde tekrar islenmez
new Float:g_fSkillTrig[33][3], Float:g_fLeapCool[33];
// Kasap kancasi
new g_iHookEnt[33], g_iHookedBy[33];
// Avci / Boga
new Float:g_fPounce[33], Float:g_fCharge[33], Float:g_fChargeT0[33], Float:g_fChargeDir[33][3], g_iChargeHit[33];
// Magma lav izi
new Float:g_fLava[33], Float:g_fLavaPos[33][3];
// Insan: fener / gece gorusu kilidi (Volt EMP, Kabus), Kabus karartmasi, Siren ninnisi
new Float:g_fNoLight[33], Float:g_fBlind[33], Float:g_fLure[33], g_iLureBy[33];
new Float:g_fWebbed[33];
// Taklitci / Kostebek / Kale / Kabus
new Float:g_fDisguise[33], Float:g_fBurrow[33], Float:g_fFortify[33], Float:g_fTerror[33];
new bool:g_bReflecting, g_iZcTick, g_iReflVictim, g_iReflAttacker, Float:g_fReflAmount;
new g_msgFlashlight, g_msgNVGToggle;
// v3.0 kaynaklar (yoksa orijinal efektlere duser)
new g_szSprChain[64], g_sprChain, g_szSprWeb[64], g_sprWeb, g_szSprSpore[64], g_sprSpore, g_szSprEmp[64], g_sprEmp;
new g_szHookModel[96], g_szSporeModel[96];

/* ---------------- v3.0 (C): efekt sprite'lari ---------------- */
// Element: 0 ates, 1 buz, 2 zehir, 3 bosluk, 4 sok (kinetik / elektrik / ses)
enum { EL_FIRE = 0, EL_ICE, EL_TOXIC, EL_VOID, EL_SHOCK, EL_TOTAL };
enum { FXS_EXFIRE = 0, FXS_EXICE, FXS_EXTOXIC, FXS_EXVOID, FXS_HEAL, FXS_LEVELUP, FXS_INFECT, FXS_SHOCK, FXS_SLASH, FXS_ICE, FXS_VOID, FXS_TOXIC, FXS_TOTAL };
new const FXS_KEY[FXS_TOTAL][] = { "SPR_EXPLO_FIRE", "SPR_EXPLO_ICE", "SPR_EXPLO_TOXIC", "SPR_EXPLO_VOID", "SPR_HEAL", "SPR_LEVELUP",
    "SPR_INFECT", "SPR_SHOCK", "SPR_SLASH", "SPR_ICE", "SPR_VOID", "SPR_TOXIC" };
new g_sprFx[FXS_TOTAL], g_iFxSprN;
// Boss elementleri (boss no -> element): Brute sok, Banshee sok (ses), Overlord bosluk, Inferno ates,
// Reaper bosluk, Frostlord buz, Stormcaller sok (elektrik), Hive Queen zehir, Void bosluk
new const BOSS_ELEM[NUM_BOSSES] = { EL_SHOCK, EL_SHOCK, EL_VOID, EL_FIRE, EL_VOID, EL_ICE, EL_SHOCK, EL_TOXIC, EL_VOID };
new Float:g_fFxHitT[33], Float:g_fFxHealT[33];

/* ---------------- v3.0 (C): harita oylamasi / RTV ---------------- */
new g_pMapVote, g_pMapPool, g_pMapVoteRound, g_pMapVoteTime, g_pMapVoteExtend, g_pMapExtendRounds, g_pMapChangeDelay;
new g_pMapChooserGuard, g_pRtvRatio, g_pRtvMinPlayers, g_pRtvMinRound, g_pAmxNextmap;
new g_szCurMap[32], g_szNextMap[32], g_szMapOpt[8][32], g_iMapOptN, g_iMapExtOpt = -1, g_iMapVotes[8];
new g_iMapVoted[MAX_PLAYERS + 1], g_iMapVoteMenu[MAX_PLAYERS + 1] = { -1, ... }, g_iMapVoteLeft, g_iMapVoteWait;
new bool:g_bMapVoting, bool:g_bMapDecided, bool:g_bMapChangeNow, bool:g_bMapChanging, bool:g_bMapAwards;
new g_iMapExtends, g_iMapExtendTo, bool:g_bRtv[MAX_PLAYERS + 1], g_iRtvCount;

/* ---------------- v3.0 (B): gorsel kimlik, kaynaklar, precache butcesi ---------------- */
// HUD renk paleti (DESIGN bolum 9). Kullanim: HudAll(SL_ALERT, CLR_DANGER, 3.0, "KEY")
#define CLR_BRAND   160, 90, 255     // Vexmira moru (marka / sistem basliklari)
#define CLR_CYAN    0, 220, 255      // marka ikinci rengi
#define CLR_HUMAN   0, 200, 255      // insan bilgisi / insan uyarilari
#define CLR_ZOMBIE  120, 255, 40     // zombi bilgisi
#define CLR_DANGER  255, 40, 40      // tehlike / boss
#define CLR_WARN    255, 170, 0      // uyari (tehlikenin acik tonu)
#define CLR_EVENT   255, 190, 0      // event duyurulari
#define CLR_REWARD  255, 215, 0      // AP / XP / VC kazanimi
#define CLR_COOL    180, 180, 180    // bekleme suresi / pasif bilgi
#define CLR_GOOD    0, 255, 140      // basari / insan zaferi

// Boss dosya adlari (model vex_b_<ad>, pence v_<ad>.mdl, sesler boss/<ad>_*.wav)
new const BOSS_FILE[NUM_BOSSES][] = { "brute", "banshee", "overlord", "inferno", "reaper", "frostlord", "stormcaller", "hivequeen", "void" };
// v3.2: depoda ozel modeli olmayan sinif / boss icin varsayilan yedek dosya adlari
// (models/player/vex_z_<ad> ve models/vexmira/claws/v_<ad>.mdl). Kendi dosyani koyunca vexmira.cfg'de degistir.
new const CLASS_MDL_DEF[NUM_CLASSES][] = { "walker", "runner", "tank", "banshee", "leech", "stalker", "bomber", "frost", "spitter", "hulk", "voodoo", "phantom", "butcher", "runner", "tank", "stalker", "bomber", "frost", "walker", "hulk", "banshee", "tank", "spitter", "phantom" };
new const CLASS_CLAW_DEF[NUM_CLASSES][] = { "walker", "runner", "hulk", "banshee", "leech", "stalker", "bomber", "frost", "spitter", "hulk", "voodoo", "phantom", "butcher", "runner", "hulk", "stalker", "bomber", "frost", "walker", "hulk", "banshee", "hulk", "spitter", "phantom" };
new const BOSS_MDL_DEF[NUM_BOSSES][] = { "tank", "banshee", "hulk", "bomber", "phantom", "frost", "voodoo", "spitter", "stalker" };
// Ozel model yoksa kullanilan orijinal CS modelleri
new const BOSS_OLDMODEL[NUM_BOSSES][] = { "terror", "vip", "leet", "arctic", "gsg9", "sas", "gign", "guerilla", "urban" };

// Bu haritada yuklenen bosslar (precache butcesi: en fazla BOSS_PRELOAD tanesi)
new bool:g_bBossLoaded[NUM_BOSSES], g_iBossLoadN, g_iBossLoadList[NUM_BOSSES];
new g_szPreBossRounds[128], g_iPreBossEvery, g_iPreRoundsTotal;
// Insan modelleri (rastgele; oyuncu basina sabit)
#define MAX_HMODELS 6
new g_szHumanModels[MAX_HMODELS][32], g_iHumanModelN, g_iHumanSkin[33];
// Firlatilan bombalarin dunya (w_) modelleri: 0 ates (HE) 1 buz (duman) 2 isaret fisegi (flash)
new g_szWNade[3][96], g_szEggModel[96];
new g_iDropBodyChute, g_iDropBodyLanded, g_szDropSeqFall[24], g_szDropSeqIdle[24], g_szMineSeqName[24], g_szMineDeploySeq[24];
// Precache sayaclari: Trie g_tSnd3D = precache_sound edilenler, g_tSnd2D = sadece indirilen (spk ile)
new Trie:g_tSnd2D, Trie:g_tSnd3D, Trie:g_tMdlDone;
new g_iPcSnd, g_iPcMdl, g_iPcGen, g_iMySnd, g_iMyMdl, g_iMyGen, g_iSndBudget, g_iMdlBudget, g_iSndSkipped, g_iMdlSkipped;
new g_iFwPcSnd, g_iFwPcMdl, g_iFwPcGen, g_iTotSnd, g_iTotMdl, g_iTotGen;
// v3.0 (C): haritanin dongulu ortam sesleri (ambient_generic). Round basindaki "stopsound"
// istemcide bunlari da susturur; round basladiktan kisa sure sonra yeniden calinirlar.
#define MAX_AMB 64
new g_iAmbEnt[MAX_AMB], g_szAmbSnd[MAX_AMB][64], Float:g_fAmbVol[MAX_AMB], Float:g_fAmbAttn[MAX_AMB];
new g_iAmbPitch[MAX_AMB], bool:g_bAmbOn[MAX_AMB], g_iAmbN, g_iAmbRestored, bool:g_bAmbReplay, bool:g_bAmbMuted;

// Kafa ustu gostergeler: boss can bari + amblem, kucuk can bari, ikonlar
#define OVH_CLASS     "vex_ovh"
#define OVH_CTL_CLASS "vex_ovhctl"
enum { OVS_BOSSBAR = 0, OVS_BOSSICON, OVS_SMALLBAR, OVS_VIP, OVS_ADMIN, OVS_MVP, OVS_LAST, OVS_ALPHA, OVS_TOTAL };
new g_szOvhSpr[OVS_TOTAL][64], g_iOvhFrames[OVS_TOTAL], g_iOvhWidth[OVS_TOTAL], g_iOvhHeight[OVS_TOTAL], g_iOvhMode[OVS_TOTAL];
new g_iOvhBar[33], g_iOvhEmb[33], g_iOvhIcon[33], g_iOvhIconType[33], g_iOvhBarType[33], g_iOvhCtl;
new g_iRoundMvp, Float:g_fStepDist[33];
new g_iOvhTick, g_iOvhCount, g_iOvhHumans;
// Son gonderilen durum (degismeyen deger tekrar yazilmaz: ag / islemci tasarrufu)
new g_iOvhSent[33];
new g_pOvhEnable, g_pBossBarW, g_pSmallBarW, g_pIconSize, g_pIcons, g_pOvhSelf, g_pOvhMargin, g_pOvhGap;
new g_pHudStyle, g_pHudTop, g_pHudRight, g_pHudMvp, g_pHudXp, g_pHudOvh, g_pHudObjective;
// v3.2 (B): CSO tarzi ekran bildirimi (killmark yontemi) - BOLUM 3 "CSO EKRAN BILDIRIMI"
enum { CN_KM1 = 0, CN_KM2, CN_KM3, CN_KM4, CN_KM5, CN_HS, CN_KNIFE, CN_NADE, CN_MVP, CN_HWIN, CN_ZWIN, CN_BOSS,
       CN_INFECT, CN_NEMESIS, CN_ASSASSIN, CN_SURVIVOR, CN_LAST, CN_LEVEL, CN_ROUND,
       CN_FIRST, CN_BKILL, CN_INFD, CN_TEN, CN_TOTAL };  // v3.3: ilk kan / boss oldu / enfekte oldun / son 10 sn
#define CSO_ROUNDS  30
#define CSO_QMAX    4
#define TASK_CSO    41500   // CSO ekran bildirimi zamanlayicisi (tek, tekrarli)
new g_pCso, g_pCsoNotes, g_pCsoTime, g_pCsoKmTime, g_pCsoFov, g_pCsoSnd, g_pCsoBots, g_pCsoLog, g_pCsoIcons, g_pCsoAnim;
new g_iPreCso = 1, bool:g_bCsoFile[CN_TOTAL], g_iCsoRounds;
new g_pComboTime, bool:g_bFirstBlood;  // v3.3: combo penceresi / roundun ilk oldurmesi
// v3.3 CSO sag panel: son gonderilen icerik (degismediyse tekrar gonderilmez) + XP cubugu
new g_szHudSig[33][400], Float:g_fHudNext[33], g_iHudXpSeen[33] = { -1, ... }, Float:g_fXpBarEnd[33];
new g_msgWL, g_msgCurW, g_msgFOV, g_msgSIcon;
new g_szWL[31][24], g_iWL[31][8], bool:g_bWL[31];
new g_iCsoCur[33] = { -1, ... }, g_iCsoArg[33], g_iCsoWpn[33], Float:g_fCsoEnd[33];
// v3.4: animasyon (kare: 0 a giris cizgisi, 1 b parlama, 2 g kayan isik, 3 m ana, 4 c cikis)
new Float:g_fCsoStart[33], g_iCsoFrm[33];
enum { CF_A = 0, CF_B, CF_G, CF_M, CF_C };
new g_iCsoQ[33][CSO_QMAX], g_iCsoQA[33][CSO_QMAX], Float:g_fCsoQT[33][CSO_QMAX], g_iCsoQn[33];
new g_iCsoIcon[33], g_iCsoShown, g_iCsoRestored;
// v3.0 hizalama: gostergeler MOVETYPE_FOLLOW kullanmaz (istemci FOLLOW sprite'ini govde merkezine
// cizer, v_angle ofsetini yok sayar). Konum her pakette AddToFullPack'te oyuncunun o anki
// konumu + modelin kafa ustu yuksekligi + yigin ofseti olarak yazilir.
#define OVH_MAXENT 4096
new g_iOvhOwn[OVH_MAXENT], Float:g_fOvhDz[OVH_MAXENT];       // varlik -> sahibi / kafa ustunden yukseklik
new Float:g_fOvhStand[33], Float:g_fOvhDuck[33], Float:g_fOvhStackTop[33], g_szOvhMdl[33][32];
new bool:g_bOvhSelf, Trie:g_tMdlTop;
// v3.2 kozmetik modeller (kanat / pet / sapka): tablo vex_wing / vex_pet / vex_hat (vexmira.cfg)
#define CM_CATS 3
#define CM_MAX 8
#define CM_MAGIC 0x56584353   // var_iuser2 isareti
enum { CMA_BONE = 0, CMA_HEAD, CMA_BACK, CMA_FOLLOW };
new const CM_TABLE[CM_CATS][] = { "vex_wing", "vex_pet", "vex_hat" };
new const CM_CATKEY[CM_CATS][] = { "COS_CAT_WING", "COS_CAT_PET", "COS_CAT_HAT" };
new g_szCmEn[CM_CATS][CM_MAX][32], g_szCmTr[CM_CATS][CM_MAX][32], g_szCmMdl[CM_CATS][CM_MAX][96];
new g_iCmPrice[CM_CATS][CM_MAX], g_iCmVip[CM_CATS][CM_MAX], g_iCmAtt[CM_CATS][CM_MAX], g_iCmSeq[CM_CATS][CM_MAX];
new Float:g_fCmOfs[CM_CATS][CM_MAX][3], Float:g_fCmAng[CM_CATS][CM_MAX][3], Float:g_fCmScale[CM_CATS][CM_MAX], Float:g_fCmFps[CM_CATS][CM_MAX];
new bool:g_bCmOk[CM_CATS][CM_MAX], g_iCmN[CM_CATS];
new g_iCmOwned[33], g_iCmSelPk[33], g_iCmEnt[33][CM_CATS];   // sahiplik: bit (kat*8 + no); secim: 4 bit / kat
new g_iCmOwn[OVH_MAXENT], g_iCmInfo[OVH_MAXENT];              // varlik -> sahibi / (kat*16 + no; 100+ = on izleme)
new g_iCmPrev[33], g_iCmPrevInfo[33], Float:g_fCmPrevEnd[33];  // v3.5 on izleme (vitrin) varligi / (kat*16 + no) / bitis
new g_pCosPreview, g_pCosDeal, g_pCosHide;
#define MS_MAXMK 4                                             // v3.3 harita senaryosu: en fazla yon isareti
new g_iMsMkOf[OVH_MAXENT];                                     // varlik -> harita isareti + 1 (sadece insanlara gorunur)
// v3.3 harita olaylari (BOLUM 13 MsEvent): vex_<ME_NAME> targetname'li varliklar tetiklenir
#define ME_ROUND_START 0
#define ME_FREEZE_END  1
#define ME_INFECTION   2
#define ME_BOSS        3
#define ME_BOSS_DEAD   4
#define ME_NEMESIS     5
#define ME_ASSASSIN    6
#define ME_SURVIVOR    7
#define ME_LASTHUMAN   8
#define ME_WIN_HUMANS  9
#define ME_WIN_ZOMBIES 10
#define ME_MINUTE      11
// Boss / ozel karakter sesleri: bekleme sureleri
new Float:g_fSndIdle[33], Float:g_fSndPain[33], Float:g_fSndAtk[33], Float:g_fSndKill, g_iPainAlt[33];
new g_pBossIdleMin, g_pBossIdleMax, g_pBossPainCd, g_pBossAtkCd, g_pBossStepDist;
new g_szPrefixBoss[64] = "^3[BOSS]^1", g_szPrefixEvent[64] = "^4[^1EVENT^4]^1";
new g_szPrefixVip[64] = "^4[^3VIP^4]^1", g_szPrefixAdmin[64] = "^3[ADMIN]^1";
new g_pPrefixBoss, g_pPrefixEvent, g_pPrefixVip, g_pPrefixAdmin;

// v3.0: mesaj turune gore sohbet etiketi. [VEX] sistem, [BOSS] boss / yetenek,
// [EVENT] event / hava olaylari, [VIP] VIP / ELITE, [ADMIN] admin islemleri.
stock ChatTag(const key[])
{
    if (equal(key, "BOSS", 4) || equal(key, "BSK", 3) || equal(key, "FINAL_BOSS", 10))
        return g_szPrefixBoss;
    if (equal(key, "EV_", 3) || equal(key, "EVENT", 5) || equal(key, "STORM", 5) || equal(key, "BLACKOUT", 8)
        || equal(key, "SPEED", 5) || equal(key, "METEOR", 6) || equal(key, "GOLD", 4))
        return g_szPrefixEvent;
    if (equal(key, "VIP", 3) || equal(key, "ELITE", 5))
        return g_szPrefixVip;
    if (equal(key, "ADM", 3))
        return g_szPrefixAdmin;
    return g_szPrefix;
}


/* ================================================================== */
/*  MENULER                                                            */
/* ================================================================== */

stock MenuInfo(menu, item)
{
    new data[8], name[8], access, cb;
    menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), cb);
    return str_to_num(data);
}

// CSO tarzi menu renkleri: ad / secenek \y (sari), sayi / deger / etiket \r (kirmizi),
// v3.3: aciklama / bilgi satirlari \d (yari saydam beyaz). Beyaz (\w) kalmaz: \w -> \y. Renksiz baslayan
// metin sari yapilir. Kilitli girdiler secilebilir kalir (ITEM_DISABLED yok),
// kirmizi [KILITLI] etiketi alir; secilince handler sohbette nedenini yazar.
stock VexMenuColor(const src[], dst[], len, const lead[] = "\y")
{
    if (src[0] == '\' || src[0] == '^n')
        copy(dst, len, src);
    else
        formatex(dst, len, "%s%s", lead, src);
    replace_string(dst, len, "\w", "\y");
}

new g_szMenuLast[512];   // son menu basligi (test araci vexprobe callfunc ile okur)
new g_iMenuTitleLen, g_iMenuItemBytes, g_iMenuItemCnt;   // v3.4: istemci menu siniri (~511 bayt) icin otomatik sayfalama
new bool:g_bMenuNoPage;

stock VexMenuCreate(const title[], const handler[])
{
    new t[512];
    VexMenuColor(title, t, charsmax(t), "\r");
    copy(g_szMenuLast, charsmax(g_szMenuLast), t);
    g_iMenuTitleLen = strlen(t);
    g_iMenuItemBytes = 0;
    g_iMenuItemCnt = 0;
    g_bMenuNoPage = false;
    return menu_create(t, handler);
}

// Gelistirici testi: son olusturulan menunun basligini loglar (devtools/server/vexprobe)
public VexDbgMenuTitle()
{
    new t[600];
    copy(t, charsmax(t), g_szMenuLast);
    replace_string(t, charsmax(t), "^n", " | ");
    log_amx("[menu-title] len=%d %s", strlen(g_szMenuLast), t);
}

stock VexAddText(menu, const text[], slot = 1)
{
    new t[192];
    VexMenuColor(text, t, charsmax(t), "\d");
    menu_addtext(menu, t, slot);
}

// v3.4: menu satirlarinda aciklamalar BEYAZ (\w): gri (\d) aciklamalar ve ( ... ) icindeki
// yazilar beyaz olur, parantezden sonra satirin onceki rengi geri gelir. "(!)" gibi
// kisa isaretler (<=3 karakter) dokunulmaz.
stock VexMenuItemFx(const src[], dst[], len)
{
    new tmp[192], n, i, o, j, close, lastc = 'y', depth;
    copy(tmp, charsmax(tmp), src);
    replace_string(tmp, charsmax(tmp), "\d", "\w");
    n = strlen(tmp);
    dst[0] = 0;
    for (i = 0; i < n && o < len - 8; i++)
    {
        new ch = tmp[i];
        if (ch == '\' && i + 1 < n)
        {
            if (!depth)
                lastc = tmp[i + 1];
            dst[o++] = ch;
            dst[o++] = tmp[i + 1];
            i++;
            continue;
        }
        if (ch == '(' && !depth)
        {
            close = -1;
            for (j = i + 1; j < n; j++)
            {
                if (tmp[j] == ')')
                {
                    close = j;
                    break;
                }
            }
            if (close > i && close - i - 1 > 3)
            {
                dst[o++] = '\';
                dst[o++] = 'w';
                depth = 1;
            }
            dst[o++] = ch;
            continue;
        }
        if (ch == ')' && depth)
        {
            dst[o++] = ch;
            dst[o++] = '\';
            dst[o++] = lastc;
            depth = 0;
            continue;
        }
        dst[o++] = ch;
    }
    dst[o] = 0;
}

stock MenuAdd(menu, const text[], value)
{
    new info[8], t[192], t2[192];
    num_to_str(value, info, charsmax(info));
    VexMenuColor(text, t, charsmax(t));
    VexMenuItemFx(t, t2, charsmax(t2));
    g_iMenuItemBytes += strlen(t2) + 9;   // "\r1.\w " + "^n"
    g_iMenuItemCnt++;
    menu_additem(menu, t2, info);
}

// Sayfalamasiz (tek sayfa) menu
stock MenuNoPage(menu)
{
    g_bMenuNoPage = true;
    menu_setprop(menu, MPROP_PERPAGE, 0);
}

// v3.2 menu tasarimi v2: her menude ayni baslik.
//   1. satir: "\rVEXMIRA \y<BASLIK BUYUK HARF>"
//   2. satir: oyuncunun canli degerleri [AP] [VC] [Lv] [VIP] [MOD] (koseli parantez kirmizi, deger sari)
//   3. satir (istege bagli): yari saydam beyaz (\d) kisa aciklama; ardindan bos satir.
stock VexHead(id, out[], len, const key[], const sub[] = "")
{
    new t[64], mn[32], k2[16], vip[24];
    formatex(t, charsmax(t), "%L", id, key);
    replace_string(t, charsmax(t), "\y", "");
    replace_string(t, charsmax(t), "\r", "");
    strtoupper(t);
    formatex(k2, charsmax(k2), "MODE_NAME_%d", clamp(g_iMode, 0, MODE_TOTAL - 1));
    formatex(mn, charsmax(mn), "%L", id, k2);
    strtoupper(mn);
    if (IsVip(id))
        formatex(vip, charsmax(vip), " \r[\y%s\r]", IsElite(id) ? "ELITE" : "VIP");
    formatex(out, len, "\rVEXMIRA \y%s^n\r[\yAP %d\r] [\yVC %d\r] [\yLv %d\r]%s [\y%s\r]^n", t, g_iAP[id], g_iVC[id], g_iLevel[id], vip, mn);
    if (sub[0])
    {
        add(out, len, "\d");
        add(out, len, sub);
        add(out, len, "^n");
    }
}

// Ac/kapa durumu: [ACIK] sari / [KAPALI] kirmizi (EN [ON] / [OFF])
stock VexOnOff(id, bool:on, out[], len)
{
    formatex(out, len, "\r[%s%L\r]", on ? "\y" : "\r", id, on ? "ON" : "OFF");
}

// v3.2: menude yer kaplamasin diye aciklama secilince sohbette gosterilir
stock DescChat(id, const fmtName[], const fmtDesc[], idx)
{
    new k1[24], k2[24];
    formatex(k1, charsmax(k1), fmtName, idx);
    formatex(k2, charsmax(k2), fmtDesc, idx);
    client_print_color(id, print_team_default, "^4%L^1: %L", id, k1, id, k2);
}

stock MenuProps(id, menu)
{
    new t[32];
    formatex(t, charsmax(t), "\y%L", id, "MENU_BACK");  menu_setprop(menu, MPROP_BACKNAME, t);
    formatex(t, charsmax(t), "\y%L", id, "MENU_NEXT");  menu_setprop(menu, MPROP_NEXTNAME, t);
    formatex(t, charsmax(t), "\y%L", id, "MENU_EXIT");  menu_setprop(menu, MPROP_EXITNAME, t);
    menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
}

stock MenuFinish(id, menu)
{
    MenuProps(id, menu);
    // v3.4: CS 1.6 menu metni ~511 bayti asarsa Geri/Ileri/Cikis satirlari kesilir.
    // Baslik + satirlar + alt tuslar sigmiyorsa sayfa basina satir sayisini kendimiz dusuruyoruz.
    if (!g_bMenuNoPage && g_iMenuItemCnt > 0)
    {
        new avg = max(12, g_iMenuItemBytes / g_iMenuItemCnt);
        new budget = 495 - g_iMenuTitleLen - 85;
        new per = clamp(budget / avg, 3, 7);
        if (per < 7 || g_iMenuItemCnt > 7)
            menu_setprop(menu, MPROP_PERPAGE, per);
    }
    menu_display(id, menu, 0);
}


/* ================================================================== */
/*  HAVA IKMALI, ROUND GOREVLERI, ZOMBI EVRIMI, EVENT EFEKTLERI        */
/* ================================================================== */

new QUEST_NEED[NUM_QUESTS] = { 3, 6, 2500, 6000, 2, 1, 3, 1 };
new QUEST_XP[NUM_QUESTS]   = { 40, 80, 40, 80, 50, 30, 80, 45 };
new QUEST_AP[NUM_QUESTS]   = { 10, 20, 10, 20, 12, 8, 20, 12 };


/* ================================================================== */
/*  KOZMETIK (Vex Coin ile kalici): iz, oldurme efekti, enfeksiyon     */
/*  efekti. TUM ZAMANLARIN SIRALAMASI (ilk 15) + stil kartlari.        */
/*  IZLEYICI BILGISI: olu oyuncu izledigi kisinin bilgisini gorur.     */
/* ================================================================== */

new TRAIL_PRICE[NUM_TRAILS] = { 15, 15, 15, 20, 30, 50 };
new KFX_PRICE[NUM_KFX]      = { 20, 25, 25, 30, 35, 50 };
new IFX_PRICE[NUM_IFX]      = { 20, 30, 40 };

/* ===== End module: core.inc ===== */
/* ================================================================== */
/*  BOLUM 2/13: FX                                                    */
/*  Gorsel / ses efekt yardimcilari (TE mesajlari, isinlar, ekran     */
/*  solmasi / sarsinti), ses calma (PlayKey / EmitKey / EmitSafe),    */
/*  dunya ortami (isik / sis / hava), tehlike alanlari.               */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
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

    if (g_bAdminEnvOverride)
    {
        light = g_iAdminEnvLight;
        for (new i = 0; i < 4; i++)
            fog[i] = g_iAdminEnvFog[i];
        weather = g_iAdminEnvWeather;
        return;
    }

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

stock EmitSpecialFire(id, sw)
{
    new key[24], path[96];
    formatex(key, charsmax(key), "SW%d_FIRE", sw);
    if (TrieGetString(g_tRes, key, path, charsmax(path)) && path[0])
        EmitSafe(id, CHAN_WEAPON, path, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    else if (SW_EFFECT[sw] == SWE_LIGHTNING || SW_EFFECT[sw] == SWE_VOID)
        EmitKey(id, "SW_FIRE");
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

/* ===== End module: fx.inc ===== */
/* ================================================================== */
/*  BOLUM 3/13: HUD                                                   */
/*  HUD paneli, nisan bilgisi, sirali buyuk yazi yuvalari, chat       */
/*  ciktisi (Chat / ChatAll / Translate), boss bari, kafa ustu        */
/*  barlar ve ikonlar (AddToFullPack), izleyici bilgisi.              */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
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

// Overrides: -1 follows style; 0 off; 1 text; 2 graphic when supported.
stock HudPartMode(pcvar)
{
    new mode = get_pcvar_num(pcvar);
    if (mode >= 0)
        return clamp(mode, 0, 2);
    switch (clamp(get_pcvar_num(g_pHudStyle), 0, 2))
    {
        case 0: return 1; // Classic Vexmira text HUD
        case 1: return 2; // Graphic first; parts without a graphic form fall back to compact text
    }
    return 0; // Stock Counter-Strike HUD
}

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
        // v3.2: grafik stilde (2) de yazi gosterilir: sunucu eklentisi serbest 2D resim cizemez
        if (top && HudPartMode(g_pHudTop) != 0)
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

            if (CsoOn())
            {
                // v3.2 (B) CSO tarzi ust tablo: mor cerceve + ROUND / sure, camgobegi INSAN vs ZOMBI
                new left = max(0, RoundTimeLeft());
                set_dhudmessage(160, 90, 255, -1.0, Y_TOPBAR, 0, 0.0, 2.0, 0.0, 0.0);
                show_dhudmessage(id, "%L^n^n%s", id, "CSO_TOP_A", g_iRound, total, left / 60, left % 60, lineC);
                set_dhudmessage(0, 220, 255, -1.0, Y_TOPBAR, 0, 0.0, 2.0, 0.0, 0.0);
                if (g_iMode == MODE_BOSS && g_iBoss)
                    show_dhudmessage(id, "^n%L", id, "CSO_TOP_BOSS", humans);
                else
                    show_dhudmessage(id, "^n%L", id, "CSO_TOP_B", humans, zombies);
            }
            else if (g_iMode == MODE_BOSS && g_iBoss)
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
        if (HudPartMode(g_pHudRight) != 0)
        {
            if (is_user_alive(id))
                DrawAimInfo(id);
            else
                DrawSpecInfo(id);
        }

        // v3.2 (B): rol ikonu (hud.txt StatusIcon), sadece degisince gonderilir
        CsoRoleIcon(id);

        if ((g_iSet[id] & SET_NO_HUD) || HudPartMode(g_pHudRight) == 0)
            continue;

        // ---------- Kisisel panel: baslik (tema) + govde (acik ton) ----------
        new lvl = g_iLevel[id];
        new base = XPForLevel(lvl);
        new need = XPForLevel(lvl + 1);
        new xpPct = (lvl >= MAX_LEVEL) ? 100 : clamp((g_iXP[id] - base) * 100 / max(1, need - base), 0, 100);

        TitleName(id, id, tname, charsmax(tname));
        new bool:cso = CsoOn();
        if (cso)
        {
            // v3.3 CSO sag panel: kisa baslik, ASCII cubuk / suslemeler yok
            if (g_iTopRank[id] > 0)
                formatex(head, charsmax(head), "%L", id, "CSO_P1R", lvl, tname, g_iTopRank[id]);
            else
                formatex(head, charsmax(head), "%L", id, "CSO_P1", lvl, tname);
        }
        else if (g_iTopRank[id] > 0)
            formatex(head, charsmax(head), "%L", id, "HUD_P1R", lvl, tname, g_iTopRank[id]);
        else
            formatex(head, charsmax(head), "%L", id, "HUD_P1", lvl, tname);

        if (is_user_alive(id))
            formatex(l1, charsmax(l1), "%L", id, cso ? "CSO_P_HP" : "HUD_P_HP", floatround(Float:get_entvar(id, var_health)), rg_get_user_armor(id));
        else
            formatex(l1, charsmax(l1), "%L", id, "HUD_P_DEAD");

        // XP cubugu (ASCII, 12 parca)
        new xbar[16];
        AsciiBar(xbar, 12, xpPct);
        l2[0] = 0;
        if (HudPartMode(g_pHudXp) != 0)
            formatex(l2, charsmax(l2), "%L", id, "HUD_P2", xbar, g_iXP[id], need);
        formatex(l3, charsmax(l3), "%L", id, cso ? "CSO_P3" : "HUD_P3", g_iAP[id], g_iVC[id], g_iStreak[id]);

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
        if (HudPartMode(g_pHudObjective) == 0)
            l5[0] = 0;
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

        if (cso)
        {
            // XP: yazi yerine oyunun kendi ilerleme cubugu (BarTime2), sadece XP degisince 2.5 sn
            if (HudPartMode(g_pHudXp) != 0)
                CsoXpBar(id, xpPct);
            if (l4[0])
                replace_string(l4, charsmax(l4), "   ::   ", "   ");
            if (l5[0])
                replace_string(l5, charsmax(l5), " : ", "  ");
            new body[320];
            formatex(body, charsmax(body), "^n%s^n%s%s%s%s%s", l1, l3, l4[0] ? "^n" : "", l4, l5[0] ? "^n" : "", l5);
            // Daha az paket: icerik degismediyse 3 sn'de bir yenilenir
            new Float:now = get_gametime();
            new sig[400];
            formatex(sig, charsmax(sig), "%d%s%s", pos, head, body);
            if (now < g_fHudNext[id] && equal(sig, g_szHudSig[id]))
                continue;
            copy(g_szHudSig[id], charsmax(g_szHudSig[]), sig);
            g_fHudNext[id] = now + 3.0;
            if (!is_user_alive(id) || !g_bZombie[id])
            {
                hr = 0; hg = 220; hb = 255;      // CSO camgobegi baslik
                br = 235; bg = 235; bb = 245;    // acik govde
            }
            set_hudmessage(hr, hg, hb, HUDPOS_X[pos], HUDPOS_Y[pos], 0, 0.0, 3.6, 0.0, 0.0, 1);
            show_hudmessage(id, "%s", head);
            set_hudmessage(br, bg, bb, HUDPOS_X[pos], HUDPOS_Y[pos], 0, 0.0, 3.6, 0.0, 0.0, 2);
            show_hudmessage(id, "%s", body);
            continue;
        }

        set_hudmessage(hr, hg, hb, HUDPOS_X[pos], HUDPOS_Y[pos], 0, 0.0, 1.1, 0.0, 0.0, 1);
        show_hudmessage(id, "%s", head);

        set_hudmessage(br, bg, bb, HUDPOS_X[pos], HUDPOS_Y[pos], 0, 0.0, 1.1, 0.0, 0.0, 2);
        show_hudmessage(id, "^n%s^n%s^n%s^n%s^n%s", l1, l2, l3, l4, l5);
    }
}

// v3.3: XP ilerlemesi oyunun kendi cubuguyla (BarTime2: sure, baslangic yuzdesi). Cok uzun sure
// verilir -> cubuk pratikte sabit durur; 2.5 sn sonra BarTime 0 ile kaldirilir.
CsoXpBar(id, pct)
{
    // Lazer kurma / sokme cubugu (BarTime) aktifken ona dokunulmaz
    if (!is_user_alive(id) || g_iPlantAction[id])
    {
        g_iHudXpSeen[id] = g_iXP[id];
        g_fXpBarEnd[id] = 0.0;
        return;
    }
    new Float:now = get_gametime();
    if (g_iHudXpSeen[id] != g_iXP[id])
    {
        new bool:first = (g_iHudXpSeen[id] == -1) ? true : false;
        g_iHudXpSeen[id] = g_iXP[id];
        if (first)
            return;
        rg_send_bartime2(id, 3000, float(clamp(pct, 0, 99)), false);
        g_fXpBarEnd[id] = now + 2.5;
    }
    else if (g_fXpBarEnd[id] > 0.0 && now >= g_fXpBarEnd[id])
    {
        g_fXpBarEnd[id] = 0.0;
        rg_send_bartime(id, 0, false);
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

/* ================================================================== */
/*  CSO EKRAN BILDIRIMI (v3.2 B) - "killmark" yontemi                  */
/*  Sunucu eklentisi ekrana serbest 2D resim cizemez. Istemcinin       */
/*  kendi silah HUD betigi kullanilir: elindeki silah icin WeaponList  */
/*  "vexmira/cso/<ad>" adiyla gonderilir -> istemci                    */
/*  sprites/vexmira/cso/<ad>.txt dosyasini yukler ve "crosshair /      */
/*  zoom" bolgesini ekranin ORTASINA (nisangah noktasina) cizer.       */
/*  Sira: SetFOV(vex_cso_fov) + WeaponList(ozel ad) + CurWeapon.       */
/*  v3.4 ANIMASYON: istemci nisangahi tek kare cizer; her kare ayri    */
/*  betik (.txt). 0.1 sn zamanlayici sadece kare DEGISINCE yeni        */
/*  WeaponList + CurWeapon gonderir (gosterim basina ~6-12 kucuk       */
/*  mesaj). Dizi: a giris -> b parlama -> g/m nabiz -> c cikis.        */
/*  Ardisik kareler hep farkli sayfada (make_cso_sprites.py).          */
/*  Geri yukleme: WeaponList(orijinal) + SetFOV(gercek m_iFOV) +       */
/*  CurWeapon. Silah degisimi / olum / durbun / round sonu / cikista   */
/*  hemen geri yuklenir; oyuncu basina oncelikli kuyruk (4).           */
/*  Gosterilemeyen oyuncuya (olu, izleyici, stil kapali) eski yazi.    */
/* ================================================================== */

new const CSO_FILE[CN_TOTAL][] = { "km1", "km2", "km3", "km4", "km5", "hs", "knife", "nade", "mvp", "hwin", "zwin", "boss",
    "infect", "nemesis", "assassin", "survivor", "last", "level", "rnd", "fb", "bkill", "infd", "ten" };
// 1 = _en / _tr ayri gorsel
new const CSO_LANG[CN_TOTAL] = { 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1 };
// Oncelik (buyuk once). 1-2 = killmark: yeni killmark eskisinin yerini alir, bant varken sadece ses.
// v3.3: COMBO (km2-km5) = 2, headshot / bomba = 1 -> combo her zaman headshot'in onune gecer
new const CSO_PRIO[CN_TOTAL] = { 1, 2, 2, 2, 2, 1, 2, 1, 6, 8, 8, 7, 5, 7, 7, 7, 6, 4, 9, 2, 8, 7, 5 };
// vex_cso_notes biti: 1 killmark/combo, 2 MVP, 4 round, 8 kazanan, 16 mod/boss/enfeksiyon, 32 son insan, 64 level,
// 128 ek bantlar (ilk kan / boss oldu / enfekte oldun / son 10 sn)
new const CSO_BIT[CN_TOTAL] = { 1, 1, 1, 1, 1, 1, 1, 1, 2, 8, 8, 16, 16, 16, 16, 16, 32, 64, 4, 128, 128, 128, 128 };
// v3.3: combo sesleri = seslendirme (DOUBLE / TRIPLE / MULTI / MEGA KILL); tek ses calinir (ust uste spk birbirini keser)
new const CSO_SND[CN_TOTAL][] = { "CSO_KM", "KILL_DOUBLE", "KILL_TRIPLE", "KILL_MULTI", "KILL_MEGA", "CSO_KM_SP", "CSO_KM_SP", "CSO_KM_SP",
    "CSO_MVP", "CSO_WIN", "CSO_WIN", "CSO_ALERT", "CSO_ALERT", "CSO_BANNER", "CSO_BANNER", "CSO_BANNER", "CSO_ALERT",
    "CSO_LEVEL", "CSO_BANNER", "CSO_FB", "CSO_BKILL", "CSO_INFD", "CSO_TEN" };
// v3.4: ortak giris / cikis karelerinin duzeni: k killmark, l alt bant, c orta bant, r round
new const CSO_LAY[CN_TOTAL] = { 'k', 'l', 'l', 'l', 'l', 'k', 'l', 'k', 'c', 'c', 'c', 'c', 'c', 'c', 'c', 'c', 'l', 'l', 'r', 'c', 'c', 'c', 'c' };
// Sprite sayfalari (generic precache): m1.. ana kareler, g1.. kayan isik kareleri, fx1.. ortak kareler (dosya varken)
new const CSO_SHEETS[][] = { "m", "g", "fx" };

// plugin_precache: dosyasi olan bildirimler; vex_cso_style 0 ise hicbiri indirilmez
CsoPrecache()
{
    g_iCsoRounds = 0;
    if (g_iPreCso <= 0)
        return;
    new path[96];
    for (new i = 0; i < sizeof CSO_SHEETS; i++)
    {
        for (new k = 1; k <= 16; k++)
        {
            formatex(path, charsmax(path), "sprites/vexmira/cso/%s%d.spr", CSO_SHEETS[i], k);
            if (!file_exists(path, true))
                break;
            precache_generic(path);
        }
    }
    // ortak kareler (a giris / b parlama / c cikis) x duzen
    new fxok = 1;
    static const FXK[] = { 'a', 'b', 'c' }, FXL[] = { 'c', 'l', 'k', 'r' };
    for (new i = 0; i < sizeof FXK; i++)
    {
        for (new j = 0; j < sizeof FXL; j++)
        {
            formatex(path, charsmax(path), "sprites/vexmira/cso/fx%c_%c.txt", FXK[i], FXL[j]);
            if (file_exists(path, true))
                precache_generic(path);
            else
                fxok = 0;
        }
    }
    static const LNG[][] = { "en", "tr" }, FR[] = { 'm', 'g' };
    for (new n = 0; n < CN_TOTAL; n++)
    {
        if (n == CN_ROUND)
            continue;
        new ok = fxok;
        for (new l = 0; l < (CSO_LANG[n] ? 2 : 1); l++)
        {
            for (new f = 0; f < sizeof FR; f++)
            {
                if (CSO_LANG[n])
                    formatex(path, charsmax(path), "sprites/vexmira/cso/%s_%s_%c.txt", CSO_FILE[n], LNG[l], FR[f]);
                else
                    formatex(path, charsmax(path), "sprites/vexmira/cso/%s_%c.txt", CSO_FILE[n], FR[f]);
                if (file_exists(path, true))
                    precache_generic(path);
                else
                    ok = 0;
            }
        }
        g_bCsoFile[n] = ok ? true : false;
    }
    // Round bantlari: sadece plandaki round sayisi kadar (en fazla 30)
    new total = clamp(g_iPreRoundsTotal > 0 ? g_iPreRoundsTotal : 30, 1, CSO_ROUNDS);
    for (new r = 1; r <= total; r++)
    {
        formatex(path, charsmax(path), "sprites/vexmira/cso/rnd%d.txt", r);
        if (!file_exists(path, true))
            break;
        precache_generic(path);
        g_iCsoRounds = r;
    }
    for (new s = 0; s < (g_iCsoRounds + 11) / 12; s++)
    {
        formatex(path, charsmax(path), "sprites/vexmira/cso/rnd%d.spr", s + 1);
        if (file_exists(path, true))
            precache_generic(path);
    }
    g_bCsoFile[CN_ROUND] = (g_iCsoRounds > 0 && fxok) ? true : false;
}

// Orijinal CS WeaponList degerleri (yedek). Oyunun gonderdigi gercek degerler msg_WeaponList ile
// yakalanip bunlarin ustune yazilir. { ammo1, max1, ammo2, max2, slot, pos, id, flags }
CsoInitWL()
{
    static const D[31][8] =
    {
        { 0, 0, 0, 0, 0, 0, 0, 0 },
        { 9, 52, -1, -1, 1, 3, 1, 0 },     // p228
        { 0, 0, 0, 0, 0, 0, 0, 0 },        // shield (silah degil)
        { 2, 90, -1, -1, 0, 9, 3, 0 },     // scout
        { 12, 1, -1, -1, 3, 1, 4, 24 },    // hegrenade
        { 5, 32, -1, -1, 0, 12, 5, 0 },    // xm1014
        { 14, 1, -1, -1, 4, 3, 6, 24 },    // c4
        { 6, 100, -1, -1, 0, 13, 7, 0 },   // mac10
        { 4, 90, -1, -1, 0, 14, 8, 0 },    // aug
        { 13, 1, -1, -1, 3, 3, 9, 24 },    // smokegrenade
        { 10, 120, -1, -1, 1, 5, 10, 0 },  // elite
        { 7, 100, -1, -1, 1, 6, 11, 0 },   // fiveseven
        { 6, 100, -1, -1, 0, 15, 12, 0 },  // ump45
        { 4, 90, -1, -1, 0, 16, 13, 0 },   // sg550
        { 4, 90, -1, -1, 0, 17, 14, 0 },   // galil
        { 4, 90, -1, -1, 0, 18, 15, 0 },   // famas
        { 6, 100, -1, -1, 1, 4, 16, 0 },   // usp
        { 10, 120, -1, -1, 1, 2, 17, 0 },  // glock18
        { 1, 30, -1, -1, 0, 2, 18, 0 },    // awp
        { 10, 120, -1, -1, 0, 7, 19, 0 },  // mp5navy
        { 3, 200, -1, -1, 0, 4, 20, 0 },   // m249
        { 5, 32, -1, -1, 0, 5, 21, 0 },    // m3
        { 4, 90, -1, -1, 0, 6, 22, 0 },    // m4a1
        { 10, 120, -1, -1, 0, 11, 23, 0 }, // tmp
        { 2, 90, -1, -1, 0, 3, 24, 0 },    // g3sg1
        { 11, 2, -1, -1, 3, 2, 25, 24 },   // flashbang
        { 8, 35, -1, -1, 1, 1, 26, 0 },    // deagle
        { 4, 90, -1, -1, 0, 10, 27, 0 },   // sg552
        { 2, 90, -1, -1, 0, 1, 28, 0 },    // ak47
        { -1, -1, -1, -1, 2, 1, 29, 0 },   // knife
        { 7, 100, -1, -1, 0, 8, 30, 0 }    // p90
    };
    for (new w = 1; w <= 30; w++)
    {
        if (w == 2)
            continue;
        get_weaponname(w, g_szWL[w], charsmax(g_szWL[]));
        for (new k = 0; k < 8; k++)
            g_iWL[w][k] = D[w][k];
        g_bWL[w] = g_szWL[w][0] ? true : false;
    }
}

// Oyunun gonderdigi gercek WeaponList (geri yukleme bu degerlerle yapilir)
public msg_WeaponList(msgid, dest, id)
{
    new name[24];
    get_msg_arg_string(1, name, charsmax(name));
    if (!equal(name, "weapon_", 7))
        return PLUGIN_CONTINUE;
    new w = get_msg_arg_int(8);
    if (w < 1 || w > 30)
        return PLUGIN_CONTINUE;
    copy(g_szWL[w], charsmax(g_szWL[]), name);
    for (new k = 0; k < 8; k++)
        g_iWL[w][k] = get_msg_arg_int(k + 2);
    g_bWL[w] = true;
    return PLUGIN_CONTINUE;
}

stock CsoSendWL(id, const name[], w)
{
    message_begin(MSG_ONE, g_msgWL, _, id);
    write_string(name);
    for (new k = 0; k < 8; k++)
        write_byte(g_iWL[w][k]);
    message_end();
}

stock CsoFov(id, fov)
{
    message_begin(MSG_ONE, g_msgFOV, _, id);
    write_byte(fov);
    message_end();
}

stock CsoCurW(id, w, clip)
{
    message_begin(MSG_ONE, g_msgCurW, _, id);
    write_byte(1);
    write_byte(w);
    write_byte(clip);
    message_end();
}

stock CsoName(id, note, arg, frm, out[], len)
{
    static const FRC[] = { 'a', 'b', 'g', 'm', 'c' };
    if (frm == CF_A || frm == CF_B || frm == CF_C)
        formatex(out, len, "vexmira/cso/fx%c_%c", FRC[frm], CSO_LAY[note]);
    else if (note == CN_ROUND)
        formatex(out, len, "vexmira/cso/rnd%d", arg);
    else if (CSO_LANG[note])
        formatex(out, len, "vexmira/cso/%s_%s_%c", CSO_FILE[note], g_iLang[id] == 2 ? "tr" : "en", FRC[frm]);
    else
        formatex(out, len, "vexmira/cso/%s_%c", CSO_FILE[note], FRC[frm]);
}

// v3.4: gecen sureye gore animasyon karesi. cur = ekrandaki kare (-1 yok).
// a (0-0.08 sn) -> b (-0.18) -> govde: g (kayan isik 0.2 sn) / m (0.6 sn) nabiz -> son 0.2 sn c.
// c, a / b'nin hemen ardindan gelmez (ayni sayfa olabilir): once en az bir govde karesi.
stock CsoFrameAt(note, Float:t, Float:dur, cur)
{
    if (get_pcvar_num(g_pCsoAnim) <= 0)
        return CF_M;
    if (t < 0.08)
        return CF_A;
    if (t < 0.18)
        return CF_B;
    if (dur - t < 0.2 && cur >= CF_G)
        return CF_C;
    if (note == CN_ROUND)
        return CF_M;
    new Float:p = t - 0.18;
    p -= float(floatround(p / 0.8, floatround_floor)) * 0.8;
    return p < 0.2 ? CF_G : CF_M;
}

// Ekrandaki kareyi degistir (sadece WeaponList + CurWeapon; FOV zaten ayarli)
CsoSendFrame(id, frm, w, clip)
{
    new nm[40];
    CsoName(id, g_iCsoCur[id], g_iCsoArg[id], frm, nm, charsmax(nm));
    CsoSendWL(id, nm, w);
    CsoCurW(id, w, clip);
    g_iCsoFrm[id] = frm;
    if (get_pcvar_num(g_pCsoLog) > 1)
        log_amx("[CSO] frame %s -> #%d", nm, id);
}

stock bool:CsoNoteOn(note)
{
    return (CsoOn() && g_bCsoFile[note] && (get_pcvar_num(g_pCsoNotes) & CSO_BIT[note])) ? true : false;
}

stock bool:CsoOn()
{
    return get_pcvar_num(g_pCso) > 0 && g_iPreCso > 0;
}

// Durbun / zoom (m_iFOV != 90) varken gosterilmez: gercek durbun onceliklidir
stock bool:CsoFovOk(id)
{
    new fov = get_member(id, m_iFOV);
    return (fov == 90 || fov <= 0) ? true : false;
}

CsoSound(id, note)
{
    if (!get_pcvar_num(g_pCsoSnd) || is_user_bot(id))
        return;
    if (CSO_PRIO[note] <= 2 ? (g_iSet[id] & SET_NO_STREAK) : (g_iSet[id] & SET_NO_AMB))
        return;
    PlayKey(id, CSO_SND[note]);
}

// Bildirimi elindeki silahin HUD'una uygula (elapsed: silah degisiminde animasyon kaldigi yerden)
bool:CsoApply(id, note, arg, Float:dur, bool:sound, Float:elapsed = 0.0)
{
    new clip, ammo, w = get_user_weapon(id, clip, ammo);
    if (w < 1 || w > 30 || !g_bWL[w])
        return false;
    if (g_iCsoCur[id] >= 0 && g_iCsoWpn[id] != w)
        CsoRestore(id, false);

    g_iCsoCur[id] = note;
    g_iCsoArg[id] = arg;
    g_iCsoWpn[id] = w;
    g_fCsoStart[id] = get_gametime() - elapsed;
    g_fCsoEnd[id] = g_fCsoStart[id] + dur;
    new frm = CsoFrameAt(note, elapsed, dur, elapsed > 0.0 ? CF_M : -1);
    CsoFov(id, clamp(get_pcvar_num(g_pCsoFov), 10, 90));
    CsoSendFrame(id, frm, w, clip);
    new nm[40];
    CsoName(id, note, arg, frm, nm, charsmax(nm));
    g_iCsoShown++;
    if (sound)
    {
        CsoSound(id, note);
        CsoSub(id, note, arg);
    }
    if (get_pcvar_num(g_pCsoLog))
        log_amx("[CSO] show %s -> #%d wpn=%s(%d) fov=%d %.1fs", nm, id, g_szWL[w], w, get_pcvar_num(g_pCsoFov), dur);
    return true;
}

// Gercek silah HUD'unu geri yukle (orijinal WeaponList + gercek FOV + CurWeapon)
CsoRestore(id, bool:refresh = true)
{
    new w = g_iCsoWpn[id];
    g_iCsoCur[id] = -1;
    g_iCsoWpn[id] = 0;
    if (w < 1 || w > 30 || !is_user_connected(id))
        return;

    CsoSendWL(id, g_szWL[w], w);
    new fov = is_user_alive(id) ? get_member(id, m_iFOV) : 90;
    CsoFov(id, fov > 0 ? fov : 90);
    if (refresh && is_user_alive(id))
    {
        new clip, ammo, cw = get_user_weapon(id, clip, ammo);
        if (cw >= 1 && cw <= 30)
            CsoCurW(id, cw, clip);
    }
    g_iCsoRestored++;
    if (get_pcvar_num(g_pCsoLog))
        log_amx("[CSO] restore WeaponList %s(%d) -> #%d fov=%d", g_szWL[w], w, id, fov > 0 ? fov : 90);
}

stock CsoClear(id)
{
    if (g_iCsoCur[id] >= 0)
        CsoRestore(id, false);
    g_iCsoCur[id] = -1;
    g_iCsoQn[id] = 0;
}

// Round sonu / yeniden baslama: herkesin aktif gorseli kalkar, kuyruk bosalir
CsoFlushAll()
{
    for (new id = 1; id <= g_iMax; id++)
    {
        if (g_iCsoCur[id] >= 0 || g_iCsoQn[id])
            CsoClear(id);
    }
}

stock Float:CsoDur(note)
{
    return (CSO_PRIO[note] <= 2) ? floatclamp(get_pcvar_float(g_pCsoKmTime), 0.5, 5.0) : floatclamp(get_pcvar_float(g_pCsoTime), 1.0, 6.0);
}

CsoQueue(id, note, arg)
{
    new n = g_iCsoQn[id];
    if (n >= CSO_QMAX)
    {
        if (CSO_PRIO[g_iCsoQ[id][n - 1]] >= CSO_PRIO[note])
            return;
        n--;
    }
    new pos = n;
    while (pos > 0 && CSO_PRIO[g_iCsoQ[id][pos - 1]] < CSO_PRIO[note])
    {
        g_iCsoQ[id][pos] = g_iCsoQ[id][pos - 1];
        g_iCsoQA[id][pos] = g_iCsoQA[id][pos - 1];
        g_fCsoQT[id][pos] = g_fCsoQT[id][pos - 1];
        pos--;
    }
    g_iCsoQ[id][pos] = note;
    g_iCsoQA[id][pos] = arg;
    g_fCsoQT[id][pos] = get_gametime();
    g_iCsoQn[id] = n + 1;
}

// true: ekranda sprite olarak gosterilecek (hemen ya da kuyrukta) -> cagiran yazi gostermez.
// false: bu oyuncuya sprite gidemez (stil kapali / bot / olu / izleyici / dosya yok) -> eski yazi.
bool:CsoNotify(id, note, arg = 0)
{
    if (!CsoOn() || !g_bCsoFile[note] || !(get_pcvar_num(g_pCsoNotes) & CSO_BIT[note]))
        return false;
    if (note == CN_ROUND && (arg < 1 || arg > g_iCsoRounds))
        return false;
    if (!is_user_alive(id) || (is_user_bot(id) && !get_pcvar_num(g_pCsoBots)))
        return false;
    new clip, ammo, w = get_user_weapon(id, clip, ammo);
    if (w < 1 || w > 30 || !g_bWL[w])
        return false;

    new cur = g_iCsoCur[id];
    new bool:km = CSO_PRIO[note] <= 2;
    if (cur >= 0 && CSO_PRIO[cur] > 2)
    {
        // Bant ekranda: killmark sadece ses, bant siraya girer
        if (km)
            CsoSound(id, note);
        else
            CsoQueue(id, note, arg);
        return true;
    }
    if (!CsoFovOk(id))
    {
        if (km)
        {
            CsoSound(id, note);
            return true;
        }
        CsoQueue(id, note, arg);
        return true;
    }
    // v3.3: ekranda killmark varken yenisi: daha dusuk oncelikli olan combo'nun yerini almaz;
    // once orijinal WeaponList geri gonderilir (istemci yeni betigi kesin yeniden yukler)
    if (cur >= 0)
    {
        if (CSO_PRIO[cur] > CSO_PRIO[note] && g_fCsoEnd[id] - get_gametime() > 0.3)
        {
            CsoSound(id, note);
            return true;
        }
        CsoRestore(id, false);
    }
    return CsoApply(id, note, arg, CsoDur(note), true);
}

// Herkese: sprite gidemeyen oyuncuya eski yazi (HudTo)
stock CsoHudAll(note, arg, slot, r, g, b, Float:hold, const key[], iVal = 0)
{
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
            continue;
        if (CsoNotify(id, note, arg) && !is_user_bot(id))
            continue;
        HudTo(id, slot, r, g, b, hold, key, iVal);
    }
}

// Sprite'in altina kisa DHUD satiri (MVP adi / yeni level)
CsoSub(id, note, arg)
{
    if (is_user_bot(id))
        return;
    switch (note)
    {
        case CN_MVP:
        {
            new mvp = g_iRoundMvp;
            if (mvp < 1 || mvp > g_iMax || !is_user_connected(mvp))
                return;
            new name[32];
            get_user_name(mvp, name, charsmax(name));
            set_dhudmessage(255, 200, 60, -1.0, 0.585, 0, 0.0, 2.6, 0.1, 0.4);
            show_dhudmessage(id, "%s^n%L", name, id, "CSO_MVP_SUB", g_iRoundDmg[mvp], g_iRoundKills[mvp], g_iRoundInf[mvp]);
        }
        case CN_LEVEL:
        {
            set_dhudmessage(0, 220, 255, -1.0, 0.63, 0, 0.0, 2.2, 0.1, 0.4);
            show_dhudmessage(id, "%L", id, "CSO_LEVEL_SUB", arg);
        }
        case CN_KM1, CN_KM2, CN_KM3, CN_KM4, CN_KM5, CN_HS, CN_KNIFE, CN_NADE, CN_FIRST:
        {
            // v3.2: VIP oldurme rozeti (killmark altinda; vex_vip_killicon)
            if (IsVip(id) && get_pcvar_num(g_pVipKillIcon))
            {
                set_dhudmessage(255, 190, 40, -1.0, 0.585, 0, 0.0, 0.9, 0.05, 0.3);
                show_dhudmessage(id, IsElite(id) ? "- ELITE -" : "- VIP -");
            }
        }
    }
}

// 0.1 sn: yalniz aktif / kuyrugu olan oyuncular islenir
public task_CsoTick()
{
    new Float:now = get_gametime();
    for (new id = 1; id <= g_iMax; id++)
    {
        if (g_iCsoCur[id] < 0 && !g_iCsoQn[id])
            continue;
        if (!is_user_connected(id))
        {
            g_iCsoCur[id] = -1;
            g_iCsoQn[id] = 0;
            continue;
        }
        if (!is_user_alive(id))
        {
            CsoClear(id);
            continue;
        }
        new clip, ammo, w = get_user_weapon(id, clip, ammo);
        if (g_iCsoCur[id] >= 0)
        {
            if (!CsoFovOk(id))
            {
                // durbun acildi: gercek durbun HUD'u geri gelir, kalan sure atilir
                CsoRestore(id);
                continue;
            }
            if (w != g_iCsoWpn[id])
            {
                // silah degisti: eski silahin HUD'u geri, kalan sure yeni silahta
                new note = g_iCsoCur[id], arg = g_iCsoArg[id];
                new Float:left = g_fCsoEnd[id] - now;
                new Float:el = now - g_fCsoStart[id], Float:tot = g_fCsoEnd[id] - g_fCsoStart[id];
                CsoRestore(id);
                if (left > 0.4)
                    CsoApply(id, note, arg, tot, false, el);
                continue;
            }
            if (now < g_fCsoEnd[id])
            {
                // v3.4: animasyon karesi degistiyse yeni betik
                new frm = CsoFrameAt(g_iCsoCur[id], now - g_fCsoStart[id], g_fCsoEnd[id] - g_fCsoStart[id], g_iCsoFrm[id]);
                if (frm != g_iCsoFrm[id])
                    CsoSendFrame(id, frm, w, clip);
                continue;
            }
            CsoRestore(id, g_iCsoQn[id] == 0);
        }
        // Kuyruk
        while (g_iCsoQn[id] > 0 && g_iCsoCur[id] < 0)
        {
            if (!CsoFovOk(id))
                break;
            new note = g_iCsoQ[id][0], arg = g_iCsoQA[id][0];
            new Float:qt = g_fCsoQT[id][0];
            g_iCsoQn[id]--;
            for (new k = 0; k < g_iCsoQn[id]; k++)
            {
                g_iCsoQ[id][k] = g_iCsoQ[id][k + 1];
                g_iCsoQA[id][k] = g_iCsoQA[id][k + 1];
                g_fCsoQT[id][k] = g_fCsoQT[id][k + 1];
            }
            if (now - qt > 7.0)
                continue;
            if (!CsoApply(id, note, arg, CsoDur(note), true))
            {
                // gosterilemedi: kalan kuyruk da gecersiz
                g_iCsoQn[id] = 0;
                break;
            }
        }
    }
}

// Rol ikonu (istemcinin hud.txt ikonlari, StatusIcon): sadece degisince gonderilir
new const CSO_ICON[][] = { "", "suithelmet_full", "dmg_bio", "dmg_rad", "dmg_heat" };
new const CSO_ICON_RGB[][3] = { { 0, 0, 0 }, { 0, 220, 255 }, { 120, 255, 40 }, { 255, 40, 40 }, { 255, 200, 60 } };

CsoRoleIcon(id)
{
    new want = 0;
    if (CsoOn() && get_pcvar_num(g_pCsoIcons) && HudPartMode(g_pHudRight) != 0 && is_user_alive(id))
    {
        if (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id])
            want = 3;
        else if (g_bZombie[id])
            want = 2;
        else if (g_bSurvivor[id] || g_bSniper[id] || (g_bLastAnn && !g_bZombie[id]))
            want = 4;
        else
            want = 1;
    }
    if (want == g_iCsoIcon[id])
        return;
    if (g_iCsoIcon[id] > 0)
    {
        message_begin(MSG_ONE, g_msgSIcon, _, id);
        write_byte(0);
        write_string(CSO_ICON[g_iCsoIcon[id]]);
        message_end();
    }
    if (want > 0)
    {
        message_begin(MSG_ONE, g_msgSIcon, _, id);
        write_byte(1);
        write_string(CSO_ICON[want]);
        write_byte(CSO_ICON_RGB[want][0]);
        write_byte(CSO_ICON_RGB[want][1]);
        write_byte(CSO_ICON_RGB[want][2]);
        message_end();
    }
    g_iCsoIcon[id] = want;
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
    new title[320];
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
    if (g_iOvhTick % 2 == 0)
        CmTick(now);   // kozmetik modeller: 0.1 sn

    new bool:on = (get_pcvar_num(g_pOvhEnable) && HudPartMode(g_pHudOvh) != 0) ? true : false;
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
    if ((bits & OVH_ICONBIT_MVP) && HudPartMode(g_pHudMvp) != 0 && g_szOvhSpr[OVS_MVP][0] && g_iRoundMvp == id)
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
    if (!player && ent < OVH_MAXENT && g_iMsMkOf[ent])
        return MsMkPack(es, host);
    if (!player && ent > g_iMax && ent < OVH_MAXENT && g_iCmOwn[ent])
        return CmPack(es, ent, host);
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

/* ===== End module: hud.inc ===== */
/* ================================================================== */
/*  BOLUM 4/13: KAYNAKLAR                                             */
/*  vex_res kaynak tablosu, precache + butceler (ses / model /        */
/*  generic), boss yukleme plani, oyuncu / dunya modelleri, tek       */
/*  ayar dosyasi (vexmira.cfg) yukleyici, sunucu adi.                 */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  PRECACHE / KAYNAKLAR                                               */
/* ================================================================== */

SetDefaultResources()
{
    // v2.0: once Vexmira'nin kendi (dongusuz, ozel) sesleri; sunucuda yoksa
    // orijinal CS 1.6 / Half-Life sesine duser.
    // DefSound(anahtar, birinci tercih, yedek): dosya sunucuda yoksa yedege gecer.
    // NOT: Bazi orijinal HL sesleri DONGULUdur (mine_charge, burning1, wind1,
    // heartbeat1...): bunlar yedek olarak kullanilmaz, aksi halde ses susmaz.
    DefSound("ZOMBIE_INFECT",  "vexmira/infect.wav",          "zombie/zo_alert20.wav");
    DefSound("ZOMBIE_PAIN",    "zombie/zo_pain1.wav",        "player/pl_pain2.wav");
    DefSound("ZOMBIE_DIE",     "zombie/zo_pain2.wav",        "player/die3.wav");
    DefSound("ROUND_START",    "vexmira/round_start.wav",     "ambience/the_horror2.wav");
    DefSound("EVENT_START",    "vexmira/event_start.wav",     "ambience/thunder_clap.wav");
    DefSound("MODE_START",     "vexmira/mode_start.wav",      "ambience/the_horror4.wav");
    DefSound("BOSS_SPAWN",     "vexmira/boss_spawn.wav",      "ambience/the_horror4.wav");
    DefSound("BOSS_SLAM",      "vexmira/boss_slam.wav",       "weapons/c4_explode1.wav");
    DefSound("BOSS_SCREAM",    "vexmira/boss_scream.wav",     "ambience/the_horror1.wav");
    DefSound("BOSS_SUMMON",    "vexmira/boss_summon.wav",     "ambience/the_horror3.wav");
    DefSound("BOSS_DEATH",     "vexmira/boss_death.wav",      "weapons/c4_explode1.wav");
    DefSound("COUNTDOWN_BEEP", "vexmira/tick.wav",            "buttons/blip1.wav");
    DefSound("LEVEL_UP",       "vexmira/levelup.wav",         "plats/elevbell1.wav");
    DefSound("LAST_HUMAN",     "vexmira/last_human.wav",      "ambience/the_horror3.wav");
    DefSound("LIGHTNING",      "vexmira/thunder_crack.wav",   "ambience/thunder_clap.wav");
    DefSound("AMBIENT",        "vexmira/ambient.wav",         "ambience/the_horror3.wav");
    DefSound("HEARTBEAT",      "vexmira/heartbeat.wav",       "");
    DefSound("METEOR",         "vexmira/meteor.wav",          "weapons/c4_explode1.wav");
    DefSound("ABILITY_BURST",  "vexmira/z_burst.wav",         "zombie/zo_alert30.wav");
    DefSound("ABILITY_LEAP",   "vexmira/z_leap.wav",          "zombie/zo_attack1.wav");
    DefSound("ABILITY_SHIELD", "vexmira/z_shield.wav",        "items/suitchargeok1.wav");
    DefSound("ABILITY_SCREAM", "vexmira/z_scream.wav",        "ambience/the_horror2.wav");
    DefSound("ABILITY_DRAIN",  "vexmira/z_drain.wav",         "zombie/zo_attack2.wav");
    DefSound("ABILITY_CLOAK",  "vexmira/z_cloak.wav",         "buttons/blip1.wav");
    DefSound("ABILITY_TOXIC",  "vexmira/z_toxic.wav",         "bullchicken/bc_acid1.wav");
    DefSound("ABILITY_FROST",  "vexmira/z_frost.wav",         "debris/glass1.wav");
    DefSound("HUMAN_WIN",      "vexmira/win_humans.wav",      "radio/ctwin.wav");
    DefSound("ZOMBIE_WIN",     "vexmira/win_zombies.wav",     "radio/terwin.wav");
    DefSound("ACH_UNLOCK",     "vexmira/achievement.wav",     "plats/elevbell1.wav");
    DefSound("SHOP_BUY",       "vexmira/buy.wav",             "items/gunpickup2.wav");
    DefSound("DAILY",          "vexmira/daily.wav",           "items/suitchargeok1.wav");
    DefSound("HEADSHOT",       "vexmira/vox_headshot.wav",    "player/headshot1.wav");
    DefSound("KILL_DOUBLE",    "vexmira/vox_double.wav",      "buttons/bell1.wav");
    DefSound("KILL_TRIPLE",    "vexmira/vox_triple.wav",      "buttons/bell1.wav");
    DefSound("KILL_MULTI",     "vexmira/vox_multi.wav",       "buttons/bell1.wav");
    DefSound("KILL_MEGA",      "vexmira/vox_mega.wav",        "buttons/bell1.wav");
    DefSound("KILL_MONSTER",   "vexmira/vox_monster.wav",     "buttons/bell1.wav");
    DefSound("STREAK_5",       "vexmira/vox_rampage.wav",     "ambience/thunder_clap.wav");
    DefSound("STREAK_10",      "vexmira/vox_unstoppable.wav", "ambience/thunder_clap.wav");
    DefSound("STREAK_15",      "vexmira/vox_godlike.wav",     "ambience/thunder_clap.wav");
    DefSound("NADE_FIRE",      "vexmira/nade_fire.wav",       "ambience/flameburst1.wav");
    DefSound("NADE_FROST",     "vexmira/nade_frost.wav",      "debris/glass2.wav");
    DefSound("NADE_INFECT",    "vexmira/nade_infect.wav",     "bullchicken/bc_spithit1.wav");
    DefSound("FREEZE",         "vexmira/freeze.wav",          "debris/glass1.wav");
    DefSound("BURN",           "vexmira/burn.wav",            "ambience/flameburst1.wav");
    DefSound("ANTIDOTE",       "vexmira/antidote.wav",        "items/smallmedkit1.wav");
    DefSound("MADNESS",        "vexmira/madness.wav",         "ambience/the_horror1.wav");
    DefSound("SW_FIRE",        "vexmira/sw_fire.wav",         "weapons/electro5.wav");
    for (new swi = 0; swi < NUM_SPECIAL; swi++)
    {
        new swkey[24];
        formatex(swkey, charsmax(swkey), "SW%d_FIRE", swi);
        TrieSetString(g_tRes, swkey, ""); // Optional per-weapon sound; empty falls back to SW_FIRE when applicable.
    }
    DefSound("ZAP",            "vexmira/zap.wav",             "weapons/electro4.wav");
    DefSound("MVP",            "vexmira/mvp.wav",             "events/task_complete.wav");
    // v3.2 (B): CSO ekran bildirimi sesleri (devtools/sfx/make_cso_sounds.py)
    DefSound("CSO_KM",         "vexmira/cso/km.wav",          "buttons/blip1.wav");
    DefSound("CSO_KM_SP",      "vexmira/cso/km_sp.wav",       "buttons/blip2.wav");
    DefSound("CSO_MVP",        "vexmira/cso/mvp.wav",         "events/task_complete.wav");
    DefSound("CSO_BANNER",     "vexmira/cso/banner.wav",      "ambience/the_horror2.wav");
    DefSound("CSO_WIN",        "vexmira/cso/win.wav",         "events/task_complete.wav");
    DefSound("CSO_ALERT",      "vexmira/cso/alert.wav",       "buttons/blip2.wav");
    DefSound("CSO_LEVEL",      "vexmira/cso/levelup.wav",     "plats/elevbell1.wav");
    // v3.3: ilk kan / boss oldu / enfekte oldun / son 10 saniye
    DefSound("CSO_FB",         "vexmira/cso/firstblood.wav",  "buttons/blip2.wav");
    DefSound("CSO_BKILL",      "vexmira/cso/bosskill.wav",    "events/task_complete.wav");
    DefSound("CSO_INFD",       "vexmira/cso/infected.wav",    "buttons/blip2.wav");
    DefSound("CSO_TEN",        "vexmira/cso/tensec.wav",      "buttons/blip1.wav");
    DefSound("VIP_JOIN",       "vexmira/vip_join.wav",        "buttons/bell1.wav");
    DefSound("BOSS_WARN",      "vexmira/boss_warn.wav",       "buttons/blip2.wav");
    DefSound("BOSS_ROAR",      "garg/gar_alert1.wav",         "ambience/the_horror1.wav");
    DefSound("BOSS_ABILITY",   "",                            "");
    DefSound("ZOMBIE_IDLE",    "zombie/zo_idle1.wav",         "");
    DefSound("ZOMBIE_SLASH",   "zombie/claw_miss1.wav",       "");
    DefSound("ZOMBIE_HITWALL", "zombie/claw_miss2.wav",       "");
    DefSound("ZOMBIE_HIT",     "zombie/claw_strike1.wav",     "");
    DefSound("ZOMBIE_STAB",    "zombie/claw_strike2.wav",     "");
    DefSound("ZOMBIE_ACID",    "vexmira/z_acid.wav",          "bullchicken/bc_acid2.wav");
    DefSound("ZOMBIE_HEAL",    "vexmira/z_heal.wav",          "items/smallmedkit1.wav");
    DefSound("ZOMBIE_BLINK",   "vexmira/z_blink.wav",         "weapons/electro4.wav");
    DefSound("ZOMBIE_SHOCK",   "vexmira/z_shock.wav",         "garg/gar_stomp1.wav");

    // v1.4
    DefSound("WELCOME",          "vexmira/welcome.wav",          "events/tutor_msg.wav");
    DefSound("PLAYER_JOIN",      "vexmira/join.wav",             "buttons/bell1.wav");
    DefSound("PLAYER_LEAVE",     "vexmira/leave.wav",            "buttons/blip2.wav");
    DefSound("BOSS_SOON",        "vexmira/boss_soon.wav",        "ambience/the_horror2.wav");
    DefSound("BOSS_INTRO",       "vexmira/boss_intro.wav",       "ambience/the_horror4.wav");
    DefSound("BOSS_STEP",        "vexmira/boss_step.wav",        "garg/gar_step1.wav");
    DefSound("BOSS_PHASE",       "vexmira/boss_phase.wav",       "ambience/thunder_clap.wav");
    DefSound("BOSS_ENRAGE",      "vexmira/boss_enrage.wav",      "garg/gar_alert3.wav");
    DefSound("LM_DEPLOY",        "vexmira/lm_deploy.wav",        "weapons/mine_deploy.wav");
    DefSound("LM_CHARGE",        "vexmira/lm_charge.wav",        "weapons/c4_click.wav");
    DefSound("LM_ACTIVATE",      "vexmira/lm_activate.wav",      "weapons/mine_activate.wav");
    DefSound("LM_HIT",           "vexmira/lm_hit.wav",           "weapons/electro4.wav");
    DefSound("LM_BREAK",         "vexmira/lm_break.wav",         "weapons/explode3.wav");
    DefSound("LM_PICKUP",        "vexmira/lm_pickup.wav",        "items/gunpickup2.wav");
    DefSound("NADE_MODE",        "vexmira/nade_mode.wav",        "buttons/lightswitch2.wav");
    DefSound("NADE_BEEP",        "vexmira/nade_beep.wav",        "weapons/c4_beep1.wav");
    DefSound("NADE_ARM",         "vexmira/nade_arm.wav",         "weapons/c4_click.wav");
    DefSound("NADE_CLUSTER",     "vexmira/nade_cluster.wav",     "weapons/explode4.wav");
    DefSound("AIRDROP_INCOMING", "vexmira/airdrop_incoming.wav", "items/suitchargeok1.wav");
    DefSound("AIRDROP_LAND",     "vexmira/airdrop_land.wav",     "debris/metal2.wav");
    DefSound("AIRDROP_LOOT",     "vexmira/airdrop_loot.wav",     "items/ammopickup2.wav");
    DefSound("QUEST_DONE",       "vexmira/quest_done.wav",       "events/task_complete.wav");
    DefSound("EVOLVE",           "vexmira/evolve.wav",           "zombie/zo_alert30.wav");
    DefSound("SPEED_START",      "vexmira/speed_start.wav",      "weapons/rocketfire1.wav");
    DefSound("SPEED_WIND",       "vexmira/wind.wav",             "");
    DefSound("STORM_STRIKE",     "vexmira/thunder_crack.wav",    "ambience/thunder_clap.wav");
    DefSound("BLACKOUT",         "vexmira/blackout.wav",         "buttons/lightswitch2.wav");
    DefSound("FINAL_ROUND",      "vexmira/final_round.wav",      "ambience/the_horror4.wav");
    DefSound("MAP_END",          "vexmira/map_end.wav",          "events/task_complete.wav");
    DefSound("FROST_NOVA",       "vexmira/frost_nova.wav",       "debris/glass2.wav");
    DefSound("THUNDER",          "vexmira/thunder.wav",          "ambience/thunder_clap.wav");
    DefSound("ACID_POOL",        "vexmira/acid_pool.wav",        "bullchicken/bc_acid1.wav");
    DefSound("GRAVITY_WELL",     "vexmira/gravity_well.wav",     "x/x_teleattack1.wav");
    DefSound("ECLIPSE",          "vexmira/eclipse.wav",          "x/x_laugh1.wav");

    // v2.0
    DefSound("ZONE_WARN",        "vexmira/zone_warn.wav",        "buttons/blip2.wav");
    DefSound("SKILL_UNLOCK",     "vexmira/skill_unlock.wav",     "plats/elevbell1.wav");
    DefSound("NEM_RAGE",         "vexmira/nem_rage.wav",         "garg/gar_alert3.wav");
    DefSound("ASN_VEIL",         "vexmira/asn_veil.wav",         "x/x_teleattack1.wav");
    DefSound("LM_KILL",          "vexmira/lm_kill.wav",          "weapons/electro5.wav");
    DefSound("NADE_TRIGGER",     "vexmira/nade_trigger.wav",     "weapons/c4_beep2.wav");
    DefSound("UI_OPEN",          "vexmira/ui_open.wav",          "");
    DefSound("LM_DENY",          "vexmira/deny.wav",             "buttons/button10.wav");

    // v3.0: her bossun kendi ses seti  sound/vexmira/boss/<ad>_<olay>.wav
    // B<no>_INTRO (2D giris) / IDLE (ara sira hirlama) / PAIN + PAIN2 (aci, sirayla) /
    // DEATH / STEP (adim) / ATTACK (pence) / PHASE (faz degisimi) / KILL (oldurme alayi).
    // Dosya yoksa eski Half-Life sesine (yedek) duser. Eski anahtarlar (SPAWN / ROAR /
    // SCREAM / ABILITY) yeni olaylara baglidir: BossEvKey().
    static const BSND[NUM_BOSSES][5][] =
    {
        { "garg/gar_alert1.wav", "garg/gar_attack1.wav", "garg/gar_alert2.wav", "garg/gar_stomp1.wav", "garg/gar_die1.wav" },
        { "controller/con_alert1.wav", "controller/con_attack1.wav", "controller/con_attack2.wav", "ambience/the_horror1.wav", "controller/con_die1.wav" },
        { "x/x_laugh1.wav", "x/x_attack1.wav", "x/x_pain1.wav", "x/x_teleattack1.wav", "x/x_die1.wav" },
        { "garg/gar_flameon1.wav", "garg/gar_attack2.wav", "garg/gar_alert3.wav", "ambience/flameburst1.wav", "garg/gar_die2.wav" },
        { "x/x_laugh2.wav", "agrunt/ag_alert1.wav", "x/x_pain3.wav", "x/x_teleattack1.wav", "x/x_die1.wav" },
        { "agrunt/ag_alert3.wav", "agrunt/ag_alert4.wav", "agrunt/ag_attack1.wav", "debris/glass3.wav", "agrunt/ag_die1.wav" },
        { "ambience/thunder_clap.wav", "x/x_attack2.wav", "x/x_shoot1.wav", "weapons/electro5.wav", "x/x_die1.wav" },
        { "bullchicken/bc_attackgrowl1.wav", "bullchicken/bc_attackgrowl2.wav", "bullchicken/bc_pain1.wav", "bullchicken/bc_acid1.wav", "bullchicken/bc_die1.wav" },
        { "x/x_recharge1.wav", "x/x_attack3.wav", "tentacle/te_roar1.wav", "x/x_ballattack1.wav", "x/x_die1.wav" }
    };
    // Boss R yetenek sesleri (B<no>_R1 / _R2 / _R3)
    static const BRSND[NUM_BOSSES][3][] =
    {
        { "vexmira/brute_stomp.wav",     "vexmira/brute_shatter.wav",   "vexmira/brute_wrath.wav" },
        { "vexmira/banshee_lance.wav",   "vexmira/banshee_shriek.wav",  "vexmira/banshee_requiem.wav" },
        { "vexmira/overlord_prison.wav", "vexmira/overlord_legion.wav", "vexmira/overlord_nova.wav" },
        { "vexmira/inferno_breath.wav",  "vexmira/inferno_pillar.wav",  "vexmira/inferno_nova.wav" },
        { "vexmira/reaper_step.wav",     "vexmira/reaper_chains.wav",   "vexmira/reaper_mark.wav" },
        { "vexmira/frost_shards.wav",    "vexmira/frost_tomb.wav",      "vexmira/frost_zero.wav" },
        { "vexmira/storm_orb.wav",       "vexmira/storm_dash.wav",      "vexmira/storm_tempest.wav" },
        { "vexmira/hive_spit.wav",       "vexmira/hive_cloud.wav",      "vexmira/hive_eggs.wav" },
        { "vexmira/void_bolt.wav",       "vexmira/void_singularity.wav", "vexmira/void_horizon.wav" }
    };
    // yeni olay -> dosya eki, eski yedek ses (BSND sutunu, -1 = yok)
    static const BEVN[][] = { "INTRO", "IDLE", "PAIN", "PAIN2", "DEATH", "STEP", "ATTACK", "PHASE", "KILL" };
    static const BEVF[][] = { "intro", "idle", "pain1", "pain2", "death", "step", "attack", "phase", "kill" };
    static const BEVO[]   = { 0, 1, -1, -1, 4, -1, 3, 2, -1 };
    new key[24], snd[96];
    for (new b = 0; b < NUM_BOSSES; b++)
    {
        for (new e = 0; e < sizeof BEVN; e++)
        {
            formatex(key, charsmax(key), "B%d_%s", b, BEVN[e]);
            formatex(snd, charsmax(snd), "vexmira/boss/%s_%s.wav", BOSS_FILE[b], BEVF[e]);
            DefSound(key, snd, BEVO[e] >= 0 ? BSND[b][BEVO[e]] : "");
        }
        for (new p = 0; p < 3; p++)
        {
            formatex(key, charsmax(key), "B%d_R%d", b, p + 1);
            DefSound(key, BRSND[b][p], BSND[b][3]);
        }
    }

    // Nemesis / Assassin: sound/vexmira/special/<ad>_<olay>.wav
    static const SEV[][] = { "INTRO", "IDLE", "PAIN", "DEATH", "ATTACK" };
    static const SEVF[][] = { "intro", "idle", "pain", "death", "attack" };
    for (new e = 0; e < sizeof SEV; e++)
    {
        formatex(key, charsmax(key), "NEMESIS_%s", SEV[e]);
        formatex(snd, charsmax(snd), "vexmira/special/nemesis_%s.wav", SEVF[e]);
        DefSound(key, snd, "");
        formatex(key, charsmax(key), "ASSASSIN_%s", SEV[e]);
        formatex(snd, charsmax(snd), "vexmira/special/assassin_%s.wav", SEVF[e]);
        DefSound(key, snd, "");
    }

    // Arayuz sesleri (2D, ses yuvasi harcamaz)
    DefSound("UI_VOTE_START",   "vexmira/ui/vote_start.wav",   "buttons/bell1.wav");
    DefSound("UI_VOTE_END",     "vexmira/ui/vote_end.wav",     "buttons/blip2.wav");
    DefSound("UI_BOSS_BAR",     "vexmira/ui/boss_bar.wav",     "");
    DefSound("UI_MENU_SELECT",  "vexmira/ui/menu_select.wav",  "");
    DefSound("UI_CLASS_SELECT", "vexmira/ui/class_select.wav", "");

    // Muzik (istege bagli, MP3): boss / ozel mod roundlarinda
    DefSound("MODE9_MUSIC", "sound/vexmira/boss_theme.mp3", "");
    DefSound("MODE2_MUSIC", "sound/vexmira/nemesis_theme.mp3", "");
    DefSound("MODE3_MUSIC", "sound/vexmira/nemesis_theme.mp3", "");
    DefSound("MODE8_MUSIC", "sound/vexmira/boss_theme.mp3", "");

    // Anons cumleleri (oyunun kendi VOX sesleri; dosya indirmez)
    TrieSetString(g_tRes, "VOX_BOSS",     "vox/warning _comma hostile presence detected");
    TrieSetString(g_tRes, "VOX_BOSSDOWN", "vox/target destroyed");
    TrieSetString(g_tRes, "VOX_FINAL",    "vox/final round");
    TrieSetString(g_tRes, "VOX_INFECT",   "vox/biohazard detected");
    TrieSetString(g_tRes, "VOX_LAST",     "vox/one remaining");
    TrieSetString(g_tRes, "VOX_AIRDROP",  "vox/supply deployed");
    TrieSetString(g_tRes, "VOX_BLACKOUT", "vox/power failure");
    TrieSetString(g_tRes, "VOX_STORM",    "vox/danger _comma electric field detected");
    TrieSetString(g_tRes, "VOX_SPEED",    "vox/warning _comma high speed");
    TrieSetString(g_tRes, "VOX_MAPEND",   "vox/all objective secured");

    // Modeller (bos = oyunun varsayilan modeli)
    // v3.0 zombi siniflari (24): model vex_z_<ad> (yoksa CLASS_OLDMODEL), pence
    // models/vexmira/claws/v_<ad>.mdl (yoksa CLAW_MODEL / bicak), sinif sesleri
    // vexmira/class/<ad>_pain|die|idle|ability.wav (yoksa genel ZOMBIE_* sesi)
    SetClassResources();
    SetModelResources();

    TrieSetString(g_tRes, "SKY_MODE", "1");
    TrieSetString(g_tRes, "SKY_LIST", "night de_storm tornsky black space hav office cx backalley city");

    // v2.0 ozel sprite'lar (yoksa orijinal oyun sprite'larina duser)
    TrieSetString(g_tRes, "SPR_ZONE",   "sprites/vexmira/zone.spr");
    TrieSetString(g_tRes, "SPR_TARGET", "sprites/vexmira/target.spr");
    TrieSetString(g_tRes, "SPR_BEACON", "sprites/vexmira/beacon.spr");
    TrieSetString(g_tRes, "SPR_ORB",    "sprites/vexmira/orb.spr");
    TrieSetString(g_tRes, "SPR_MARK",   "sprites/vexmira/mark.spr");
    TrieSetString(g_tRes, "SPR_FIRE",   "sprites/vexmira/fire.spr");
    TrieSetString(g_tRes, "SPR_LASER",  "sprites/vexmira/laser.spr");
}

// v3.0 (B): insan / boss / ozel karakter / silah / dunya modelleri ve kafa ustu sprite'lari.
// Dosya yoksa: oyuncu modeli -> orijinal CS modeli, el/silah modeli -> oyunun kendi modeli,
// dunya modeli -> eski model / sprite, sprite -> o ozellik sessizce kapanir.
SetModelResources()
{
    new key[24], val[96];
    for (new b = 0; b < NUM_BOSSES; b++)
    {
        formatex(key, charsmax(key), "B%d_MODEL", b);
        formatex(val, charsmax(val), "vex_z_%s", BOSS_MDL_DEF[b]);
        TrieSetString(g_tRes, key, val);
        formatex(key, charsmax(key), "B%d_CLAW", b);
        copy(val, charsmax(val), "models/vexmira/claws/v_hulk.mdl");
        TrieSetString(g_tRes, key, val);
    }
    TrieSetString(g_tRes, "NEMESIS_MODEL",  "vex_z_hulk");
    TrieSetString(g_tRes, "ASSASSIN_MODEL", "vex_z_phantom");
    TrieSetString(g_tRes, "NEMESIS_CLAW",   "models/vexmira/claws/v_hulk.mdl");
    TrieSetString(g_tRes, "ASSASSIN_CLAW",  "models/vexmira/claws/v_phantom.mdl");
    TrieSetString(g_tRes, "SURVIVOR_MODEL", "vex_survivor");
    TrieSetString(g_tRes, "SNIPER_MODEL",   "vex_sniper");
    TrieSetString(g_tRes, "VIP_MODEL",      "vex_vip");
    TrieSetString(g_tRes, "ADMIN_MODEL",    "vex_admin");
    // Insanlar: listeden rastgele (oyuncu basina sabit). HUMAN_MODEL (tek) de eklenir.
    TrieSetString(g_tRes, "HUMAN_MODELS",   "vex_operator vex_ranger vex_hazmat");

    // Insan el modelleri (Vexmira eldiveni) + elde gorunen (p_) modeller
    TrieSetString(g_tRes, "V_KNIFE",        "models/vexmira/weapons/v_vexblade.mdl");
    TrieSetString(g_tRes, "V_HEGRENADE",    "models/vexmira/weapons/v_firebomb.mdl");
    TrieSetString(g_tRes, "V_SMOKEGRENADE", "models/vexmira/weapons/v_frostbomb.mdl");
    TrieSetString(g_tRes, "V_FLASHBANG",    "models/vexmira/weapons/v_flare.mdl");
    new lower[24];
    for (new w = 1; w < sizeof WEAPON_KEYNAME; w++)
    {
        if (!WEAPON_KEYNAME[w][0] || equal(WEAPON_KEYNAME[w], "C4") || equal(WEAPON_KEYNAME[w], "GLOCK"))
            continue;
        copy(lower, charsmax(lower), WEAPON_KEYNAME[w]);
        strtolower(lower);
        formatex(key, charsmax(key), "P_%s", WEAPON_KEYNAME[w]);
        formatex(val, charsmax(val), "models/vexmira/weapons/p_%s.mdl", lower);
        if (!file_exists(val, true))
            val[0] = 0;     // v3.2: dosya yoksa bos = oyunun kendi p_ modeli (log yok)
        TrieSetString(g_tRes, key, val);
    }
    // Bombalar / bicak: ozel adli p_ modeli varsa o, yoksa silah adli olan
    DefModel("P_KNIFE",        "models/vexmira/weapons/p_vexblade.mdl",  "models/vexmira/weapons/p_knife.mdl");
    DefModel("P_HEGRENADE",    "models/vexmira/weapons/p_firebomb.mdl",  "models/vexmira/weapons/p_hegrenade.mdl");
    DefModel("P_SMOKEGRENADE", "models/vexmira/weapons/p_frostbomb.mdl", "models/vexmira/weapons/p_smokegrenade.mdl");
    DefModel("P_FLASHBANG",    "models/vexmira/weapons/p_flare.mdl",     "models/vexmira/weapons/p_flashbang.mdl");
    for (new i = 0; i < NUM_SPECIAL; i++)
    {
        formatex(key, charsmax(key), "SW%d_VMODEL", i);
        // v3.2: SW8..SW15 ayni CS silahini kullanan SW0..SW7 el modelini paylasir
        formatex(val, charsmax(val), "models/vexmira/weapons/v_sw%d.mdl", i % 8);
        TrieSetString(g_tRes, key, val);
        formatex(key, charsmax(key), "SW%d_PMODEL", i);
        formatex(val, charsmax(val), "models/vexmira/weapons/p_sw%d.mdl", i);
        if (!file_exists(val, true))
            val[0] = 0;
        TrieSetString(g_tRes, key, val);
    }

    // Dunya modelleri
    TrieSetString(g_tRes, "LASERMINE_MODEL", "models/vexmira/world/lasermine.mdl");
    // LASERMINE_BODY / LASERMINE_SEQUENCE / LASERMINE_SKIN: yazilmazsa modele gore secilir
    // (Vexmira lazeri: govde 0, animasyon "idle"; kurulurken "deploy")
    TrieSetString(g_tRes, "AIRDROP_MODEL",   "models/vexmira/world/supply_crate.mdl");
    TrieSetString(g_tRes, "EGG_MODEL",       "");   // v3.2: hive_egg.mdl depoda yok -> parlayan kure
    TrieSetString(g_tRes, "W_HEGRENADE",     "models/vexmira/world/w_firebomb.mdl");
    TrieSetString(g_tRes, "W_SMOKEGRENADE",  "models/vexmira/world/w_frostbomb.mdl");
    TrieSetString(g_tRes, "W_FLASHBANG",     "models/vexmira/world/w_flare.mdl");

    // Kafa ustu gostergeler (sprite yoksa o gosterge kapali)
    TrieSetString(g_tRes, "SPR_BOSSBAR",     "sprites/vexmira/bossbar.spr");
    TrieSetString(g_tRes, "SPR_BOSSICON",    "sprites/vexmira/bossicon.spr");
    TrieSetString(g_tRes, "SPR_HPBAR",       "sprites/vexmira/hpbar_small.spr");
    TrieSetString(g_tRes, "SPR_ICON_VIP",    "sprites/vexmira/icon_vip.spr");
    TrieSetString(g_tRes, "SPR_ICON_ADMIN",  "sprites/vexmira/icon_admin.spr");
    TrieSetString(g_tRes, "SPR_ICON_MVP",    "sprites/vexmira/icon_mvp.spr");
    TrieSetString(g_tRes, "SPR_ICON_LAST",   "sprites/vexmira/icon_lasthuman.spr");
    TrieSetString(g_tRes, "SPR_ICON_ALPHA",  "sprites/vexmira/icon_alpha.spr");

    // Precache butcesi (GoldSrc: 512 ses / 512 model / 512 generic; stok CS + harita payi)
    TrieSetString(g_tRes, "BOSS_PRELOAD",      "4");    // bir haritada en fazla kac boss yuklenir
    TrieSetString(g_tRes, "BOSS_PRELOAD_LIST", "");     // bos = otomatik (haritadan haritaya doner)
    TrieSetString(g_tRes, "SOUND_BUDGET",      "200");  // eklentinin 3D ses (precache_sound) siniri
    TrieSetString(g_tRes, "MODEL_BUDGET",      "250");  // eklentinin model + sprite siniri
    // v3.0 (C): bu modda HIC calinmayan stok sesler (C4, rehine/VIP telsizi, bot duzenleme, tutor,
    // geiger, silah HUD'u) oyunun precache listesinden cikarilir -> ~35 ses yuvasi bosalir
    TrieSetString(g_tRes, "SOUND_BLOCK_STOCK", "1");
    TrieSetString(g_tRes, "SOUND_BLOCK_EXTRA", "");     // ek engellenecek sesler (bosluklu liste)

    // v3.0 (C): efekt sprite'lari (dosya yoksa eski efekt / oyun sprite'i kullanilir)
    TrieSetString(g_tRes, "SPR_EXPLO_FIRE",  "sprites/vexmira/explo_fire.spr");
    TrieSetString(g_tRes, "SPR_EXPLO_ICE",   "sprites/vexmira/explo_ice.spr");
    TrieSetString(g_tRes, "SPR_EXPLO_TOXIC", "sprites/vexmira/explo_toxic.spr");
    TrieSetString(g_tRes, "SPR_EXPLO_VOID",  "sprites/vexmira/explo_void.spr");
    TrieSetString(g_tRes, "SPR_HEAL",        "sprites/vexmira/heal.spr");
    TrieSetString(g_tRes, "SPR_LEVELUP",     "sprites/vexmira/levelup.spr");
    TrieSetString(g_tRes, "SPR_INFECT",      "sprites/vexmira/infect.spr");
    TrieSetString(g_tRes, "SPR_SHOCK",       "sprites/vexmira/shock.spr");
    TrieSetString(g_tRes, "SPR_SLASH",       "sprites/vexmira/slash.spr");
    TrieSetString(g_tRes, "SPR_ICE",         "sprites/vexmira/ice.spr");
    TrieSetString(g_tRes, "SPR_VOID",        "sprites/vexmira/void.spr");
    TrieSetString(g_tRes, "SPR_TOXIC",       "sprites/vexmira/toxic.spr");
}

// Model anahtari: ilk dosya varsa o, yoksa ikinci (ikisi de yoksa ilk yazilir; precache'te elenir)
DefModel(const key[], const first[], const second[])
{
    if (first[0] && file_exists(first, true))
        TrieSetString(g_tRes, key, first);
    else if (second[0] && file_exists(second, true))
        TrieSetString(g_tRes, key, second);
    else
        TrieSetString(g_tRes, key, first);
}

// v3.0: sinif kaynaklari (24 sinif) + yeni yetenek sesleri / modelleri / sprite'lari
SetClassResources()
{
    new key[24], val[96], snd[96];
    static const CEV[][] = { "pain", "die", "idle", "ability" };
    static const CEVKEY[][] = { "PAIN", "DIE", "IDLE", "ABILITY" };
    for (new i = 0; i < NUM_CLASSES; i++)
    {
        formatex(key, charsmax(key), "Z%d_MODEL", i);
        formatex(val, charsmax(val), "vex_z_%s", CLASS_MDL_DEF[i]);
        TrieSetString(g_tRes, key, val);

        formatex(key, charsmax(key), "Z%d_CLAW", i);
        formatex(val, charsmax(val), "models/vexmira/claws/v_%s.mdl", CLASS_CLAW_DEF[i]);
        TrieSetString(g_tRes, key, val);

        for (new e = 0; e < sizeof CEV; e++)
        {
            formatex(key, charsmax(key), "Z%d_%s", i, CEVKEY[e]);
            formatex(snd, charsmax(snd), "vexmira/class/%s_%s.wav", CLASS_FILE[i], CEV[e]);
            DefSound(key, snd, "");
        }
    }

    // Yeni sinif yeteneklerinin carpma / ozel sesleri (yoksa orijinal HL sesleri)
    DefSound("HUNTER_IMPACT",     "vexmira/class/hunter_impact.wav",     "garg/gar_stomp1.wav");
    DefSound("CHARGER_IMPACT",    "vexmira/class/charger_impact.wav",    "garg/gar_stomp1.wav");
    DefSound("ARACHNE_WEBHIT",    "vexmira/class/arachne_webhit.wav",    "bullchicken/bc_spithit1.wav");
    DefSound("BURROWER_ERUPT",    "vexmira/class/burrower_erupt.wav",    "garg/gar_stomp1.wav");
    DefSound("SPOREMOTHER_BURST", "vexmira/class/sporemother_burst.wav", "bullchicken/bc_acid1.wav");
    DefSound("MIMIC_REVEAL",      "vexmira/class/mimic_reveal.wav",      "zombie/zo_alert30.wav");
    DefSound("VOLT_ZAP",          "vexmira/class/volt_zap.wav",          "weapons/electro4.wav");

    // Kasap kancasi
    DefSound("HOOK_THROW", "vexmira/hook/throw.wav", "zombie/claw_miss1.wav");
    DefSound("HOOK_CHAIN", "vexmira/hook/chain.wav", "");
    DefSound("HOOK_HIT",   "vexmira/hook/hit.wav",   "zombie/claw_strike1.wav");
    DefSound("HOOK_PULL",  "vexmira/hook/pull.wav",  "");
    DefSound("HOOK_MISS",  "vexmira/hook/miss.wav",  "zombie/claw_miss2.wav");

    // Modeller / sprite'lar (dosya yoksa: sprite -> orijinal efekt, model -> sprite)
    TrieSetString(g_tRes, "HOOK_MODEL",  "");   // v3.2: hook.mdl depoda yok -> parlayan sprite
    TrieSetString(g_tRes, "SPORE_MODEL", "");   // v3.2: spore_pod.mdl depoda yok -> SPR_SPORE
    TrieSetString(g_tRes, "SPR_CHAIN",   "sprites/vexmira/chain.spr");
    TrieSetString(g_tRes, "SPR_WEB",     "sprites/vexmira/web.spr");
    TrieSetString(g_tRes, "SPR_SPORE",   "sprites/vexmira/spore.spr");
    TrieSetString(g_tRes, "SPR_EMP",     "sprites/vexmira/emp.spr");
}

// v3.0 yeni ses anahtarlari (precache)
new const SOUND_KEYS_V3[][] =
{
    "HUNTER_IMPACT", "CHARGER_IMPACT", "ARACHNE_WEBHIT", "BURROWER_ERUPT", "SPOREMOTHER_BURST", "MIMIC_REVEAL", "VOLT_ZAP",
    "HOOK_THROW", "HOOK_CHAIN", "HOOK_HIT", "HOOK_PULL", "HOOK_MISS"
};

// Ses dosyasi sunucuda var mi? (yoksa oyuncular "failed to transmit" ile atilir)
bool:SoundExists(const path[])
{
    if (!path[0])
        return false;

    new full[160];
    if (containi(path, ".mp3") != -1)
        copy(full, charsmax(full), path);
    else
        formatex(full, charsmax(full), "sound/%s", path);
    return file_exists(full, true) ? true : false;
}

DefSound(const key[], const first[], const second[])
{
    if (SoundExists(first))
        TrieSetString(g_tRes, key, first);
    else if (SoundExists(second))
        TrieSetString(g_tRes, key, second);
    else
        TrieSetString(g_tRes, key, "");
}

// Ozel model yoksa yedek oyuncu modeli (orijinal CS modelleri her sunucuda vardir)
PlayerModelFallback(const name[], out[], len)
{
    out[0] = 0;
    if (!name[0])
        return;
    new model[128];
    formatex(model, charsmax(model), "models/player/%s/%s.mdl", name, name);
    if (!file_exists(model, true))
        return;
    if (PcModel(model, false))
    {
        copy(out, len, name);
        MdlHeadTops(name);
    }
}

// Gokyuzu: listeden (orijinal CS gokyuzleri) her haritada rastgele biri
PickSky()
{
    new mode = str_to_num(GetResString("SKY_MODE", "1"));
    if (mode <= 0)
        return;

    // Haritanin kendine ozel (stok olmayan) gokyuzu varsa ona dokunma: worldspawn skyname,
    // plugin_precache aninda sv_skyname'e yazilmis olur (orn. zm_vex_cordon -> vexmira_night).
    new own[32];
    get_cvar_string("sv_skyname", own, charsmax(own));
    if (own[0] && !IsStockSky(own) && SkyExists(own))
    {
        copy(g_szSky, charsmax(g_szSky), own);
        log_amx("[Vexmira] haritanin ozel gokyuzu korunuyor: %s", own);
        return;
    }

    new list[256], names[16][32], n, pos, tmp[32];
    copy(list, charsmax(list), GetResString("SKY_LIST", ""));
    while (n < sizeof names && (pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
    {
        if (tmp[0] && SkyExists(tmp))
            copy(names[n++], charsmax(names[]), tmp);
    }
    if (!n)
    {
        log_amx("[Vexmira] SKY_LIST icindeki gokyuzleri sunucuda bulunamadi, haritanin kendi gokyuzu kullaniliyor.");
        return;
    }

    copy(g_szSky, charsmax(g_szSky), names[mode == 2 ? 0 : random(n)]);
    set_cvar_string("sv_skyname", g_szSky);

    // Ozel (oyunda olmayan) gokyuzu eklenirse oyuncular indirebilsin
    static const SIDE[][] = { "up", "dn", "lf", "rt", "ft", "bk" };
    new path[96];
    for (new i = 0; i < 6; i++)
    {
        formatex(path, charsmax(path), "gfx/env/%s%s.tga", g_szSky, SIDE[i]);
        PcGeneric(path);
    }
}

// Oyunla gelen (CS 1.6 / HL) gokyuzleri; bunlarin disindakiler haritaya ozel sayilir
bool:IsStockSky(const name[])
{
    static const STOCK[][] =
    {
        "desert", "city", "night", "space", "cx", "office", "de_storm", "backalley", "morning", "green",
        "snow", "tornsky", "trainyard", "2desert", "cliff", "hav", "dusk", "neb6", "xen9", "alien1",
        "alien2", "alien3", "black", "blue", "grnplsnt"
    };
    for (new i = 0; i < sizeof STOCK; i++)
    {
        if (equali(name, STOCK[i]))
            return true;
    }
    return false;
}

// 6 yuzun hepsi sunucuda olmali (eksik dosya oyuncuyu "failed to transmit" ile atar)
bool:SkyExists(const name[])
{
    static const SIDE[][] = { "up", "dn", "lf", "rt", "ft", "bk" };
    new path[96];
    for (new i = 0; i < 6; i++)
    {
        formatex(path, charsmax(path), "gfx/env/%s%s.tga", name, SIDE[i]);
        if (!file_exists(path, true))
            return false;
    }
    return true;
}

// Ses anahtari: 2D (anons / arayuz) ise generic olarak indirilir, degilse precache_sound
PrecacheSoundKey(const key[])
{
    PrecacheSoundKeyEx(key, IsKey2D(key));
}

// Sadece oyuncuya "spk" ile (2D) calinan sesler: precache_generic yeterli (ses yuvasi harcamaz).
// Konumdan (3D) de calinan anahtarlar BURADA OLMAMALI.
new const SOUND_2D_KEYS[][] =
{
    "ACH_UNLOCK", "AIRDROP_INCOMING", "AMBIENT", "BLACKOUT", "BOSS_DEATH", "BOSS_ENRAGE", "BOSS_INTRO", "BOSS_PHASE",
    "BOSS_SOON", "BOSS_SPAWN", "BOSS_WARN", "COUNTDOWN_BEEP", "DAILY", "ECLIPSE", "EVENT_START", "FINAL_ROUND",
    "HEADSHOT", "HEARTBEAT", "HUMAN_WIN", "KILL_DOUBLE", "KILL_TRIPLE", "KILL_MULTI", "KILL_MEGA", "KILL_MONSTER",
    "LAST_HUMAN", "LEVEL_UP", "LIGHTNING", "LM_DENY", "MAP_END", "METEOR", "MODE_START", "MVP", "NADE_FROST", "NADE_MODE",
    "PLAYER_JOIN", "PLAYER_LEAVE", "QUEST_DONE", "ROUND_START", "SHOP_BUY", "SKILL_UNLOCK", "SPEED_START", "SPEED_WIND",
    "STORM_STRIKE", "STREAK_5", "STREAK_10", "STREAK_15", "VIP_JOIN", "WELCOME", "ZOMBIE_WIN", "UI_OPEN",
    // v3.0 (C): sadece ATTN_NONE (herkes duyar) ile calinanlar
    "NEM_RAGE",
    "CSO_KM", "CSO_KM_SP", "CSO_MVP", "CSO_BANNER", "CSO_WIN", "CSO_ALERT", "CSO_LEVEL",
    "CSO_FB", "CSO_BKILL", "CSO_INFD", "CSO_TEN"
};

// Sadece yedek olarak kullanilan ses anahtarlari (sinifin / bossun kendi sesi varsa gereksiz)
bool:IsFallbackOnly(const key[])
{
    static const FB[][] =
    {
        "ABILITY_BURST", "ABILITY_SHIELD", "ABILITY_SCREAM", "ABILITY_DRAIN", "ABILITY_CLOAK", "ABILITY_TOXIC", "ABILITY_FROST",
        "ZOMBIE_ACID", "ZOMBIE_HEAL", "ZOMBIE_BLINK", "ZOMBIE_SHOCK", "BOSS_ROAR", "BOSS_SCREAM",
        "ZOMBIE_PAIN", "ZOMBIE_DIE", "ZOMBIE_IDLE"
    };
    for (new i = 0; i < sizeof FB; i++)
    {
        if (equal(key, FB[i]))
            return true;
    }
    return false;
}

bool:IsKey2D(const key[])
{
    if (equal(key, "UI_", 3) || containi(key, "_MUSIC") != -1)
        return true;
    new len = strlen(key);
    if (len > 6 && equal(key[len - 6], "_INTRO"))
        return true;
    for (new i = 0; i < sizeof SOUND_2D_KEYS; i++)
    {
        if (equal(key, SOUND_2D_KEYS[i]))
            return true;
    }
    return false;
}

PrecacheSoundKeyEx(const key[], bool:twoD)
{
    new path[128], full[160];
    if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
        return;
    if (containi(path, ".mp3") != -1)
    {
        PcGeneric(path);
        return;
    }
    if (twoD)
    {
        // 2D: istemci dosyayi indirir, "spk" ile calar (sunucu ses tablosuna girmez)
        formatex(full, charsmax(full), "sound/%s", path);
        PcGeneric(full);
        TrieSetCell(g_tSnd2D, path, 1);
        ScanWav(path);
        return;
    }
    // 3D: butce doluysa anahtar kapanir ve kod genel (yedek) sese duser
    if (!PcSound(path))
        TrieSetString(g_tRes, key, "");
}

// 3D ses (precache_sound). 0 = butce dolu, atlandi.
// Ayni dosyayi isteyen anahtarlar tek yuva kullanir (motor buyuk/kucuk harf ayirmaz: anahtar kucuk harf)
PcSound(const path[])
{
    if (!path[0])
        return 0;
    new low[128];
    copy(low, charsmax(low), path);
    strtolower(low);
    if (TrieKeyExists(g_tSnd3D, path) || TrieKeyExists(g_tSnd3D, low))
        return 1;
    if (g_iMySnd >= g_iSndBudget)
    {
        if (++g_iSndSkipped <= 8)
            log_amx("[Vexmira] Ses butcesi dolu (SOUND_BUDGET %d), atlandi: %s", g_iSndBudget, path);
        return 0;
    }
    new idx = precache_sound(path);
    g_iMySnd++;
    g_iPcSnd = max(g_iPcSnd, idx);
    TrieSetCell(g_tSnd3D, path, idx);
    if (!equal(low, path))
        TrieSetCell(g_tSnd3D, low, idx);
    ScanWav(path);
    return 1;
}

// Indirilecek dosya (2D ses / mp3 / gokyuzu)
PcGeneric(const path[])
{
    if (!path[0] || TrieKeyExists(g_tMdlDone, path))
        return;
    TrieSetCell(g_tMdlDone, path, 1);
    new idx = precache_generic(path);
    g_iMyGen++;
    g_iPcGen = max(g_iPcGen, idx);
}

// Model / sprite. optional = butceye tabi (doluysa 0 doner ve ozellik eski haline duser)
PcModel(const path[], bool:optional = true)
{
    if (!path[0])
        return 0;
    new idx;
    if (TrieGetCell(g_tMdlDone, path, idx))
        return idx;
    if (optional && g_iMyMdl >= g_iMdlBudget)
    {
        if (++g_iMdlSkipped <= 8)
            log_amx("[Vexmira] Model butcesi dolu (MODEL_BUDGET %d), atlandi: %s", g_iMdlBudget, path);
        return 0;
    }
    idx = precache_model(path);
    g_iMyMdl++;
    g_iPcMdl = max(g_iPcMdl, idx);
    TrieSetCell(g_tMdlDone, path, idx);
    return idx;
}

// Bir sinifin kendi <olay> sesi yok mu? (varsa genel ZOMBIE_<olay> sesi gereksiz)
bool:AnyClassLacks(const ev[])
{
    new key[24], tmp[8];
    for (new i = 0; i < NUM_CLASSES; i++)
    {
        formatex(key, charsmax(key), "Z%d_%s", i, ev);
        if (!TrieGetString(g_tRes, key, tmp, charsmax(tmp)) || !tmp[0])
            return true;
    }
    return false;
}

/* ---------------- v3.0 (C): kullanilmayan stok sesleri engelleme ---------------- */
// Oyun DLL'i (ReGameDLL) worldspawn precache'inde bu sesleri her haritada yukler ama bu modda
// sunucu tarafinda HIC calinmazlar:
//  - C4 / bomba: bomba verilmez (rg_MakeBomber engelli), haritalarda bomba bolgesi yok
//  - telsiz (radio/*): round basi / rehine telsizi istemcide SendAudio ile calinir (sunucu yuvasi gerekmez)
//  - bot duzenleme (buttons/*): sadece bot_debug / nav duzenleme + yerel (listen) sunucu
//  - tutor / kariyer (events/*): sadece listen sunucu / kariyer modu
//  - geiger + silah HUD sesleri: istemci kendi calar
// Pencere: plugin_precache -> haritanin ilk varligi dogana kadar (sadece oyunun kendi
// precache'i). Harita varliklari (kapi / buton / ambient_generic) ayni sesi isterse yuklenir.
new const STOCK_SND_BLOCK[][] =
{
    "weapons/c4_click.wav", "weapons/c4_beep1.wav", "weapons/c4_beep2.wav", "weapons/c4_beep3.wav",
    "weapons/c4_beep4.wav", "weapons/c4_beep5.wav", "weapons/c4_explode1.wav", "weapons/c4_plant.wav",
    "weapons/c4_disarm.wav", "weapons/c4_disarmed.wav",
    "radio/locknload.wav", "radio/letsgo.wav", "radio/moveout.wav", "radio/com_go.wav", "radio/rescued.wav",
    "radio/rounddraw.wav",
    "buttons/bell1.wav", "buttons/blip1.wav", "buttons/blip2.wav", "buttons/button11.wav",
    "buttons/latchunlocked2.wav", "buttons/lightswitch2.wav",
    "events/tutor_msg.wav", "events/enemy_died.wav", "events/friend_died.wav", "events/task_complete.wav",
    "player/geiger1.wav", "player/geiger2.wav", "player/geiger3.wav", "player/geiger4.wav", "player/geiger5.wav",
    "player/geiger6.wav",
    "common/wpn_hudoff.wav", "common/wpn_hudon.wav", "common/wpn_moveselect.wav"
};
new Trie:g_tSndBlock, g_iFwSndBlock, g_iFwSpawnWin, bool:g_bSndBlockWin, g_iSndBlocked;

SetupStockSoundBlock()
{
    if (str_to_num(GetResString("SOUND_BLOCK_STOCK", "1")) <= 0)
        return;
    g_tSndBlock = TrieCreate();
    for (new i = 0; i < sizeof STOCK_SND_BLOCK; i++)
        TrieSetCell(g_tSndBlock, STOCK_SND_BLOCK[i], 1);
    new list[256], tmp[96], pos;
    copy(list, charsmax(list), GetResString("SOUND_BLOCK_EXTRA", ""));
    while ((pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
    {
        if (tmp[0])
        {
            strtolower(tmp);
            TrieSetCell(g_tSndBlock, tmp, 1);
        }
    }
    g_bSndBlockWin = true;
    g_iFwSndBlock = register_forward(FM_PrecacheSound, "fw_PcSoundBlock", 0);
    g_iFwSpawnWin = register_forward(FM_Spawn, "fw_SpawnBlockWin", 0);
}

public fw_PcSoundBlock(const sample[])
{
    if (!g_bSndBlockWin || g_tSndBlock == Invalid_Trie)
        return FMRES_IGNORED;
    new low[96];
    copy(low, charsmax(low), sample);
    strtolower(low);
    // Eklentinin kendisi yuklediyse (or. yedek ses) oyun da ayni yuvayi alsin
    if (!TrieKeyExists(g_tSndBlock, low) || TrieKeyExists(g_tSnd3D, low))
        return FMRES_IGNORED;
    g_iSndBlocked++;
    forward_return(FMV_CELL, 0);
    return FMRES_SUPERCEDE;
}

// Haritanin ilk varligi dogdu: oyunun kendi precache'i bitti -> pencere kapanir
public fw_SpawnBlockWin(ent)
{
    if (!g_bSndBlockWin || !pev_valid(ent))
        return FMRES_IGNORED;
    new cls[32];
    pev(ent, pev_classname, cls, charsmax(cls));
    if (equal(cls, "worldspawn"))
        return FMRES_IGNORED;
    StockSoundBlockEnd();
    return FMRES_IGNORED;
}

StockSoundBlockEnd()
{
    g_bSndBlockWin = false;
    if (g_iFwSndBlock) { unregister_forward(FM_PrecacheSound, g_iFwSndBlock, 0); g_iFwSndBlock = 0; }
    if (g_iFwSpawnWin) { unregister_forward(FM_Spawn, g_iFwSpawnWin, 0); g_iFwSpawnWin = 0; }
}

// Toplam sayac: oyun DLL'i / harita / diger eklentilerin precache'leri (indeks = en buyuk)
public fw_PcSoundPost(const s[])
{
    g_iTotSnd = max(g_iTotSnd, get_orig_retval());
    return FMRES_IGNORED;
}

public fw_PcModelPost(const s[])
{
    g_iTotMdl = max(g_iTotMdl, get_orig_retval());
    return FMRES_IGNORED;
}

public fw_PcGenericPost(const s[])
{
    g_iTotGen = max(g_iTotGen, get_orig_retval());
    return FMRES_IGNORED;
}

// plugin_init: harita varliklari da yuklendi -> toplam sayilar
PrecacheReportTotals()
{
    StockSoundBlockEnd();
    if (g_tSndBlock != Invalid_Trie)
        log_amx("[Vexmira] kullanilmayan stok ses engellendi: %d (C4 / telsiz / bot duzenleme / tutor / geiger)", g_iSndBlocked);
    if (g_iFwPcSnd) { unregister_forward(FM_PrecacheSound, g_iFwPcSnd, 1); g_iFwPcSnd = 0; }
    if (g_iFwPcMdl) { unregister_forward(FM_PrecacheModel, g_iFwPcMdl, 1); g_iFwPcMdl = 0; }
    if (g_iFwPcGen) { unregister_forward(FM_PrecacheGeneric, g_iFwPcGen, 1); g_iFwPcGen = 0; }
    g_iTotSnd = max(g_iTotSnd, g_iPcSnd);
    g_iTotMdl = max(g_iTotMdl, g_iPcMdl);
    g_iTotGen = max(g_iTotGen, g_iPcGen);
    log_amx("[Vexmira] precache toplam (oyun + harita dahil): sound=%d/512 model=%d/512 generic=%d/512", g_iTotSnd, g_iTotMdl, g_iTotGen);
    if (g_iTotSnd > 480 || g_iTotMdl > 480)
        log_amx("[Vexmira] UYARI: precache limitine yakin! vexmira.cfg: vex_res SOUND_BUDGET / MODEL_BUDGET / BOSS_PRELOAD dusur.");
}

// Sunucu komutu: vex_precache_stats
public srv_PrecacheStats()
{
    new list[96], nm[16];
    for (new i = 0; i < g_iBossLoadN; i++)
    {
        formatex(nm, charsmax(nm), "%s%s", i ? ", " : "", BOSS_FILE[g_iBossLoadList[i]]);
        add(list, charsmax(list), nm);
    }
    server_print("[Vexmira] precache: sound=%d model=%d generic=%d (eklenti)", g_iPcSnd, g_iPcMdl, g_iPcGen);
    server_print("[Vexmira] toplam (oyun + harita dahil): sound=%d/512 model=%d/512 generic=%d/512", g_iTotSnd, g_iTotMdl, g_iTotGen);
    server_print("[Vexmira] eklenti: 3D ses %d/%d  model+sprite %d/%d  generic %d  atlanan ses %d / model %d",
        g_iMySnd, g_iSndBudget, g_iMyMdl, g_iMdlBudget, g_iMyGen, g_iSndSkipped, g_iMdlSkipped);
    server_print("[Vexmira] yuklenen bosslar (%d): %s", g_iBossLoadN, list[0] ? list : "-");
    server_print("[Vexmira] engellenen stok ses: %d  |  ortam sesi (ambient_generic) kaydi: %d, yeniden baslatma: %d",
        g_iSndBlocked, g_iAmbN, g_iAmbRestored);
    new ovh[160];
    for (new i = 0; i < OVS_TOTAL; i++)
    {
        if (g_szOvhSpr[i][0])
        {
            formatex(nm, charsmax(nm), " %d:%dx%dx%d", i, g_iOvhWidth[i], g_iOvhHeight[i], g_iOvhFrames[i]);
            add(ovh, charsmax(ovh), nm);
        }
    }
    server_print("[Vexmira] kafa ustu sprite'lar (tur:GxYxKare):%s", ovh[0] ? ovh : " yok");
    // Canli gostergeler (test icin)
    new live, bars, icons;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (g_iOvhBar[id])
        {
            bars++;
            server_print("[Vexmira]   #%d bar tur %d kare %d", id, g_iOvhBarType[id], floatround(Float:get_entvar(g_iOvhBar[id], var_frame)));
        }
        if (g_iOvhIcon[id])
            icons++;
        if (g_iOvhEmb[id])
            live++;
    }
    server_print("[Vexmira] canli gostergeler: %d (bar %d, amblem %d, ikon %d)", g_iOvhCount, bars, live, icons);
    return PLUGIN_HANDLED;
}

/* ---------------- Boss yukleme plani (precache butcesi) ----------------
   Her haritada sadece en fazla BOSS_PRELOAD (4) boss yuklenir: model + pence + sesler.
   Secim: BOSS_PRELOAD_LIST doluysa o; degilse haritanin boss round sayisi kadar boss,
   onceki haritalarda gelmeyenler oncelikli (sunucu acik kaldikca tum bosslar doner). */
PlanBossLoad()
{
    g_iBossLoadN = 0;
    for (new b = 0; b < NUM_BOSSES; b++)
        g_bBossLoaded[b] = false;

    new maxN = clamp(str_to_num(GetResString("BOSS_PRELOAD", "4")), 1, NUM_BOSSES);
    new list[64], tmp[8], pos;
    copy(list, charsmax(list), GetResString("BOSS_PRELOAD_LIST", ""));
    while (g_iBossLoadN < maxN && (pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
    {
        if (!isdigit(tmp[0]))
            continue;
        new b = str_to_num(tmp);
        if (b < 0 || b >= NUM_BOSSES || g_bBossLoaded[b])
            continue;
        g_bBossLoaded[b] = true;
        g_iBossLoadList[g_iBossLoadN++] = b;
    }

    if (!g_iBossLoadN)
    {
        new need = clamp(PlanBossRoundCount(), 1, maxN);
        new info[16];
        get_localinfo("vex_bossrot", info, charsmax(info));
        new used = str_to_num(info) & ((1 << NUM_BOSSES) - 1);

        new cand[NUM_BOSSES], nc;
        for (new b = 0; b < NUM_BOSSES; b++)
        {
            if (!(used & (1 << b)))
                cand[nc++] = b;
        }
        // Yeterli gelmemis boss yoksa: once kalanlar, sonra digerleri
        while (g_iBossLoadN < need && nc > 0)
        {
            new r = random(nc), b = cand[r];
            cand[r] = cand[--nc];
            g_bBossLoaded[b] = true;
            g_iBossLoadList[g_iBossLoadN++] = b;
        }
        if (g_iBossLoadN < need)
        {
            used = 0;
            nc = 0;
            for (new b = 0; b < NUM_BOSSES; b++)
            {
                if (!g_bBossLoaded[b])
                    cand[nc++] = b;
            }
            while (g_iBossLoadN < need && nc > 0)
            {
                new r = random(nc), b = cand[r];
                cand[r] = cand[--nc];
                g_bBossLoaded[b] = true;
                g_iBossLoadList[g_iBossLoadN++] = b;
            }
        }
        for (new i = 0; i < g_iBossLoadN; i++)
            used |= (1 << g_iBossLoadList[i]);
        num_to_str(used, info, charsmax(info));
        set_localinfo("vex_bossrot", info);
    }
    g_iBossBagPos = NUM_BOSSES;  // torba yuklenen bosslardan yeniden olusturulur
}

// Haritanin plani kac boss roundu iceriyor? (vexmira.cfg precache sirasinda okunur)
PlanBossRoundCount()
{
    new total = g_iPreRoundsTotal > 0 ? g_iPreRoundsTotal : 30;
    new list[128], tmp[8], pos, n;
    copy(list, charsmax(list), g_szPreBossRounds);
    trim(list);
    if (list[0])
    {
        while ((pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
        {
            new r = str_to_num(tmp);
            if (r >= 1 && r <= total)
                n++;
        }
        return n;
    }
    new every = g_iPreBossEvery > 0 ? g_iPreBossEvery : 6;
    return total / every;
}

// Yuklenmeyen bossun ses anahtarlari bosaltilir (precache edilmemis ses calinmaz)
BossClearKeys(b)
{
    static const EV[][] = { "INTRO", "IDLE", "PAIN", "PAIN2", "DEATH", "STEP", "ATTACK", "PHASE", "KILL", "R1", "R2", "R3",
        "SPAWN", "ROAR", "SCREAM", "ABILITY", "MUSIC" };
    new key[24];
    for (new e = 0; e < sizeof EV; e++)
    {
        formatex(key, charsmax(key), "B%d_%s", b, EV[e]);
        TrieSetString(g_tRes, key, "");
    }
}

bool:BossIsLoaded(b)
{
    return (0 <= b < NUM_BOSSES && g_bBossLoaded[b]) ? true : false;
}

// Insan modelleri: HUMAN_MODELS listesi (+ HUMAN_MODEL). Hicbiri yoksa oyunun CT modeli.
LoadHumanModels()
{
    new list[192], tmp[32], pos, out[32];
    g_iHumanModelN = 0;
    copy(list, charsmax(list), GetResString("HUMAN_MODELS", ""));
    add(list, charsmax(list), " ");
    add(list, charsmax(list), GetResString("HUMAN_MODEL", ""));
    while (g_iHumanModelN < MAX_HMODELS && (pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
    {
        if (!tmp[0])
            continue;
        new dup;
        for (new i = 0; i < g_iHumanModelN; i++)
        {
            if (equali(g_szHumanModels[i], tmp))
                dup = 1;
        }
        if (dup)
            continue;
        PlayerModelFile(tmp, out, charsmax(out));
        if (out[0])
            copy(g_szHumanModels[g_iHumanModelN++], charsmax(g_szHumanModels[]), out);
    }
    g_szHumanModel[0] = 0;
    if (g_iHumanModelN)
        copy(g_szHumanModel, charsmax(g_szHumanModel), g_szHumanModels[0]);
}

// Oyuncu modeli adi -> dosya kontrolu + precache (yoksa out bos)
PlayerModelFile(const name[], out[], len)
{
    out[0] = 0;
    new model[128];
    formatex(model, charsmax(model), "models/player/%s/%s.mdl", name, name);
    if (!file_exists(model, true))
    {
        log_amx("[Vexmira] Model bulunamadi: %s - varsayilan kullanilacak", model);
        return;
    }
    if (PcModel(model))
    {
        copy(out, len, name);
        MdlHeadTops(name);
        PcPlayerTex(name);
    }
}

// Dunya modelleri: lazer mayini, ikmal kutusu, kovan yumurtasi, firlatilan bombalar, kanca, spor
LoadWorldModels()
{
    new cfgModel[96];
    copy(cfgModel, charsmax(cfgModel), GetResString("LASERMINE_MODEL", ""));
    GetFileModel("LASERMINE_MODEL", g_szMineModel, charsmax(g_szMineModel));
    if (!g_szMineModel[0] && file_exists("models/v_tripmine.mdl", true))
    {
        copy(g_szMineModel, charsmax(g_szMineModel), "models/v_tripmine.mdl");
        PcModel(g_szMineModel, false);
    }
    if (!g_szMineModel[0] && file_exists("models/w_c4.mdl", true))
    {
        copy(g_szMineModel, charsmax(g_szMineModel), "models/w_c4.mdl");
        PcModel(g_szMineModel, false);
    }
    // Govde / animasyon / kaplama: orijinal tripmine modelinde 3 / 7 / 0, baska modelde cfg'den.
    // Yedek modele dusulduyse cfg'deki (Vexmira modeline ait) degerler kullanilmaz.
    new bool:tripmine = (containi(g_szMineModel, "tripmine") != -1) ? true : false;
    new bool:c4 = (containi(g_szMineModel, "w_c4") != -1) ? true : false;
    new bool:fellBack = !equal(cfgModel, g_szMineModel);
    new seq[24];
    // HL v_tripmine.mdl duvar pozu: govde 3 (ellersiz mayin), animasyon "world" (TRIPMINE_WORLD = 7).
    // cfg'deki LASERMINE_BODY / SEQUENCE Vexmira modeline aittir; tripmine'a uygulanmaz
    // (govde 0 + "idle" = elle tutulan viewmodel pozu -> duvarda ters / yamuk gorunuyordu).
    g_iMineBody = (fellBack || tripmine) ? (tripmine ? 3 : 0) : str_to_num(GetResString("LASERMINE_BODY", "0"));
    copy(seq, charsmax(seq), tripmine ? "world" : (fellBack ? "0" : GetResString("LASERMINE_SEQUENCE", "idle")));
    // Sayi degilse animasyon ADI (model yuklenince aranir)
    g_szMineSeqName[0] = 0;
    if (isdigit(seq[0]))
        g_iMineSeq = str_to_num(seq);
    else
    {
        g_iMineSeq = tripmine ? 7 : 0;
        copy(g_szMineSeqName, charsmax(g_szMineSeqName), seq);
    }
    copy(g_szMineDeploySeq, charsmax(g_szMineDeploySeq), (fellBack || tripmine) ? "" : GetResString("LASERMINE_DEPLOY_SEQ", "deploy"));
    g_iMineSkin = (fellBack || tripmine) ? 0 : str_to_num(GetResString("LASERMINE_SKIN", "0"));
    MinePreset(tripmine, c4, fellBack);

    copy(cfgModel, charsmax(cfgModel), GetResString("AIRDROP_MODEL", ""));
    GetFileModel("AIRDROP_MODEL", g_szDropModel, charsmax(g_szDropModel));
    if (!g_szDropModel[0] && file_exists("models/w_weaponbox.mdl", true))
    {
        copy(g_szDropModel, charsmax(g_szDropModel), "models/w_weaponbox.mdl");
        PcModel(g_szDropModel, false);
    }
    fellBack = !equal(cfgModel, g_szDropModel);
    // Ikmal kutusu: dususte parasut govdesi + "fall" animasyonu, yerde "idle"
    g_iDropBodyChute  = fellBack ? 0 : str_to_num(GetResString("AIRDROP_BODY_CHUTE", "1"));
    g_iDropBodyLanded = fellBack ? 0 : str_to_num(GetResString("AIRDROP_BODY_LANDED", "0"));
    copy(g_szDropSeqFall, charsmax(g_szDropSeqFall), fellBack ? "" : GetResString("AIRDROP_SEQ_FALL", "fall"));
    copy(g_szDropSeqIdle, charsmax(g_szDropSeqIdle), fellBack ? "" : GetResString("AIRDROP_SEQ_IDLE", "idle"));

    GetFileModel("EGG_MODEL", g_szEggModel, charsmax(g_szEggModel));
    GetFileModel("HOOK_MODEL", g_szHookModel, charsmax(g_szHookModel));
    GetFileModel("SPORE_MODEL", g_szSporeModel, charsmax(g_szSporeModel));
    GetFileModel("W_HEGRENADE", g_szWNade[0], charsmax(g_szWNade[]));
    GetFileModel("W_SMOKEGRENADE", g_szWNade[1], charsmax(g_szWNade[]));
    GetFileModel("W_FLASHBANG", g_szWNade[2], charsmax(g_szWNade[]));
}

// Sprite dosya basligi: kare sayisi, boyut ve doku bicimi (cizim modu buna gore secilir)
// SPR: "IDSP" ver type texFormat radius width height numframes ...
ReadSprInfo(slot)
{
    g_iOvhFrames[slot] = 1;
    g_iOvhWidth[slot] = 64;
    g_iOvhHeight[slot] = 16;
    g_iOvhMode[slot] = kRenderTransAlpha;
    new fp = fopen(g_szOvhSpr[slot], "rb", true);
    if (!fp)
        return;
    new ident, ver, type, fmt, radius, w, h, frames;
    fread(fp, ident, BLOCK_INT);
    fread(fp, ver, BLOCK_INT);
    fread(fp, type, BLOCK_INT);
    fread(fp, fmt, BLOCK_INT);
    fread(fp, radius, BLOCK_INT);
    fread(fp, w, BLOCK_INT);
    fread(fp, h, BLOCK_INT);
    fread(fp, frames, BLOCK_INT);
    fclose(fp);
    if (ident != 0x50534449)   // "IDSP"
        return;
    g_iOvhFrames[slot] = clamp(frames, 1, 256);
    g_iOvhWidth[slot] = clamp(w, 1, 1024);
    g_iOvhHeight[slot] = clamp(h, 1, 1024);
    // 0 normal 1 additive 2 indexalpha 3 alphtest
    switch (fmt)
    {
        case 1: g_iOvhMode[slot] = kRenderTransAdd;
        case 2: g_iOvhMode[slot] = kRenderTransTexture;
        case 3: g_iOvhMode[slot] = kRenderTransAlpha;
        default: g_iOvhMode[slot] = kRenderNormal;
    }
}

/* ---------------- Dongulu ses korumasi ----------------
   GoldSrc, icinde "cue " bolumu olan WAV dosyalarini SONSUZ DONGUDE calar
   (or. weapons/mine_charge.wav, ambience/burning1.wav). Bu sesler
   durdurulmazsa round bitse de susmaz, ust uste biner. Precache sirasinda
   her WAV taranir: dongulu olanlar oyuncuya "spk" ile hic calinmaz, varliktan
   calinanlar kisa sure sonra otomatik durdurulur. */

#define WAV_RIFF 0x46464952
#define WAV_WAVE 0x45564157
#define WAV_FMT  0x20746D66
#define WAV_DATA 0x61746164
#define WAV_CUE  0x20657563

ScanWav(const snd[])
{
    if (TrieKeyExists(g_tSndInfo, snd))
        return;

    new full[160], info;
    formatex(full, charsmax(full), "sound/%s", snd);
    new fp = fopen(full, "rb", true);
    if (fp)
    {
        new id, size, tmp, rate, byterate, datalen, bool:loop, guard;
        fread(fp, id, BLOCK_INT);
        fread(fp, size, BLOCK_INT);
        fread(fp, tmp, BLOCK_INT);
        if (id == WAV_RIFF && tmp == WAV_WAVE)
        {
            while (!feof(fp) && guard++ < 64)
            {
                if (fread(fp, id, BLOCK_INT) != 1 || fread(fp, size, BLOCK_INT) != 1 || size < 0)
                    break;

                if (id == WAV_FMT && size >= 16)
                {
                    fread(fp, tmp, BLOCK_INT);       // format + kanal
                    fread(fp, rate, BLOCK_INT);
                    fread(fp, byterate, BLOCK_INT);
                    fseek(fp, size - 12, SEEK_CUR);
                }
                else if (id == WAV_DATA)
                {
                    datalen = size;
                    fseek(fp, size, SEEK_CUR);
                }
                else
                {
                    if (id == WAV_CUE)
                        loop = true;
                    fseek(fp, size, SEEK_CUR);
                }
                if (size & 1)
                    fseek(fp, 1, SEEK_CUR);
            }
        }
        fclose(fp);

        new ms = (byterate > 0) ? (datalen / max(1, byterate / 1000)) : 0;
        info = (loop ? 1 : 0) | (clamp(ms, 0, 600000) << 1);
        if (loop)
            log_amx("[Vexmira] DONGULU ses tespit edildi: %s (otomatik durdurulacak / spk ile calinmayacak)", snd);
    }
    TrieSetCell(g_tSndInfo, snd, info);
}

bool:SndLooped(const snd[])
{
    new info;
    if (!TrieGetCell(g_tSndInfo, snd, info))
        return false;
    return (info & 1) ? true : false;
}

Float:SndLength(const snd[])
{
    new info;
    if (!TrieGetCell(g_tSndInfo, snd, info))
        return 0.0;
    return float(info >> 1) / 1000.0;
}

PrecacheSafe(const path[])
{
    if (!path[0] || !file_exists(path, true))
    {
        if (path[0])
            log_amx("[Vexmira] Dosya bulunamadi, atlandi: %s", path);
        return 0;
    }
    return PcModel(path, false);
}

// Ayardaki sprite (vex_res SPR_...): varsa precache, yoksa 0
PrecacheResSprite(const key[], out[], len)
{
    out[0] = 0;
    new path[96];
    if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
        return 0;
    if (!file_exists(path, true))
    {
        log_amx("[Vexmira] Sprite bulunamadi: %s (%s) - orijinal efekt kullanilacak", path, key);
        return 0;
    }
    new idx = PcModel(path);
    if (idx)
        copy(out, len, path);
    return idx;
}

GetResString(const key[], const def[])
{
    static out[128];
    if (!TrieGetString(g_tRes, key, out, charsmax(out)) || !out[0])
        copy(out, charsmax(out), def);
    return out;
}

// Oyuncu modeli: ozel modelse dosya var mi kontrol et, yoksa bos birak
GetPlayerModel(const key[], out[], len)
{
    out[0] = 0;
    if (!TrieGetString(g_tRes, key, out, len) || !out[0])
        return;

    new model[128];
    formatex(model, charsmax(model), "models/player/%s/%s.mdl", out, out);

    if (!file_exists(model, true))
    {
        log_amx("[Vexmira] Model bulunamadi: %s (%s) - varsayilan kullanilacak", model, key);
        out[0] = 0;
        return;
    }
    if (!PcModel(model))
        out[0] = 0;
    else
    {
        MdlHeadTops(out);
        PcPlayerTex(out);
    }
}

// v3.1: dokulari ayri dosyada olan oyuncu modeli (<ad>T.mdl) da indirilsin; yoksa istemci
// modeli dokusuz / hatali gorur. precache_generic: model yuvasi harcamaz.
PcPlayerTex(const name[])
{
    new tex[128];
    formatex(tex, charsmax(tex), "models/player/%s/%sT.mdl", name, name);
    // g_iFwPcMdl != 0 yalniz precache asamasinda (sonra precache yapilamaz)
    if (g_iFwPcMdl && file_exists(tex, true))
        precache_generic(tex);
}

GetFileModel(const key[], out[], len)
{
    out[0] = 0;
    if (!TrieGetString(g_tRes, key, out, len) || !out[0])
        return;

    if (!file_exists(out, true))
    {
        log_amx("[Vexmira] Model bulunamadi: %s (%s) - devre disi", out, key);
        out[0] = 0;
        return;
    }
    if (!PcModel(out))
        out[0] = 0;
}

// Tek kaynak ayari: ANAHTAR -> deger. Ses dosyasi sunucuda yoksa varsayilan korunur
// (eksik dosya oyunculari "server failed to transmit file" ile atar).
ResSet(const key[], const value[])
{
    if (!key[0])
        return;

    if (equali(key, "VOX_COUNTDOWN"))
    {
        g_bVoxCountdown = (str_to_num(value) != 0);
        return;
    }

    if (value[0] && (containi(value, ".wav") != -1 || containi(value, ".mp3") != -1))
    {
        new full[192];
        if (containi(value, ".mp3") != -1)
            copy(full, charsmax(full), value);
        else
            formatex(full, charsmax(full), "sound/%s", value);

        if (!file_exists(full, true))
        {
            log_amx("[Vexmira] Ses bulunamadi: %s (%s) - varsayilan kullanilacak", full, key);
            return;
        }
    }
    TrieSetString(g_tRes, key, value);
}

// Eski surumden kalan vexmira_resources.ini (varsa). Yeni surumde her sey vexmira.cfg'de.
LoadResourceIni()
{
    new file[96], line[256], key[32], value[192];
    get_configsdir(file, charsmax(file));
    add(file, charsmax(file), "/vexmira_resources.ini");

    new fp = fopen(file, "rt");
    if (!fp)
        return;

    while (!feof(fp))
    {
        fgets(fp, line, charsmax(line));
        trim(line);

        if (!line[0] || line[0] == ';' || line[0] == '#' || line[0] == '/')
            continue;

        // ANAHTAR = deger  (ilk '=' isaretinden bol)
        new eq = contain(line, "=");
        if (eq <= 0)
            continue;

        line[eq] = 0;
        copy(key, charsmax(key), line);
        copy(value, charsmax(value), line[eq + 1]);
        trim(key);
        trim(value);

        // Satir sonu yorumlarini at:  KEY = deger   ; aciklama
        new sc = contain(value, ";");
        if (sc >= 0)
        {
            value[sc] = 0;
            trim(value);
        }
        ResSet(key, value);
    }
    fclose(fp);
}


/* ================================================================== */
/*  v2.0  TEK AYAR DOSYASI: configs/vexmira.cfg                        */
/*  - Oyun kurallari, sunucu adi, tum vex_* ayarlari                   */
/*  - Tablolar: vex_item, vex_class, vex_sw, vex_gun, vex_job,         */
/*    vex_boss_stat, vex_boss_skill, vex_mode_rule, vex_env_*,         */
/*    vex_cosmetic, vex_quest                                          */
/*  - Kaynaklar (ses / model / sprite): vex_res ANAHTAR "deger"        */
/*  Dosyayi plugin kendisi satir satir okur (exec tampon tasmasi yok). */
/*  Oyun icinde yeniden yuklemek: vex_reload (RCON)                     */
/* ================================================================== */

CfgPath(out[], len)
{
    get_configsdir(out, len);
    add(out, len, "/vexmira.cfg");
}

// Satir sonu yorumunu at (tirnak icindeki // korunur: http://...)
StripCfgComment(line[])
{
    new bool:q;
    for (new i = 0; line[i]; i++)
    {
        if (line[i] == '"')
            q = !q;
        else if (!q && line[i] == '/' && line[i + 1] == '/')
        {
            line[i] = 0;
            break;
        }
    }
    trim(line);
}

#define CFG_MAXARGS 20

// precache = true: sadece vex_res satirlari (harita yuklenirken)
LoadMainConfig(bool:precache)
{
    new file[128];
    CfgPath(file, charsmax(file));

    new fp = fopen(file, "rt");
    if (!fp)
    {
        if (!precache)
            log_amx("[Vexmira] %s bulunamadi, varsayilan ayarlar kullaniliyor.", file);
        return 0;
    }

    new line[512], args[CFG_MAXARGS][128], argc, pos, count, value[192];
    while (!feof(fp))
    {
        fgets(fp, line, charsmax(line));
        trim(line);
        if (!line[0] || line[0] == ';' || line[0] == '#' || (line[0] == '/' && line[1] == '/'))
            continue;
        StripCfgComment(line);
        if (!line[0])
            continue;

        argc = 0;
        pos = 0;
        while (argc < CFG_MAXARGS && (pos = argparse(line, pos, args[argc], charsmax(args[]))) != -1)
            argc++;
        if (!argc)
            continue;

        if (equali(args[0], "vex_res"))
        {
            if (precache && argc >= 2)
                ResSet(args[1], argc >= 3 ? args[2] : "");
            continue;
        }
        if (precache)
        {
            // Boss yukleme plani icin: harita planindaki boss round sayisi (cvar'lar henuz yok)
            if (argc >= 2)
            {
                if (equali(args[0], "vex_boss_rounds"))
                {
                    g_szPreBossRounds[0] = 0;
                    for (new i = 1; i < argc; i++)
                    {
                        add(g_szPreBossRounds, charsmax(g_szPreBossRounds), args[i]);
                        add(g_szPreBossRounds, charsmax(g_szPreBossRounds), " ");
                    }
                }
                else if (equali(args[0], "vex_boss_every"))
                    g_iPreBossEvery = str_to_num(args[1]);
                else if (equali(args[0], "vex_rounds_total"))
                    g_iPreRoundsTotal = str_to_num(args[1]);
                else if (equali(args[0], "vex_cso_style"))
                    g_iPreCso = str_to_num(args[1]);
                else if (equali(args[0], "vex_wing") || equali(args[0], "vex_pet") || equali(args[0], "vex_hat"))
                    CmParse(args, argc);
            }
            continue;
        }

        if (ApplyTableCmd(args, argc))
        {
            count++;
            continue;
        }

        if (cvar_exists(args[0]))
        {
            // Deger: tek arguman (tirnakli) veya bosluklu birden cok arguman
            value[0] = 0;
            for (new i = 1; i < argc; i++)
            {
                if (i > 1)
                    add(value, charsmax(value), " ");
                add(value, charsmax(value), args[i]);
            }
            set_cvar_string(args[0], value);
            count++;
            continue;
        }

        // Bilinmeyen satir (or. exec, sv_downloadurl...): sunucuya aynen gonder
        server_cmd("%s", line);
        count++;
    }
    fclose(fp);

    if (!precache)
        ApplyConfigNow();
    return count;
}

// Ayarlar yuklendikten / degistikten sonra hemen uygulananlar
ApplyConfigNow()
{
    new raw[64];
    get_pcvar_string(g_pPrefix, raw, charsmax(raw));
    if (raw[0])
        ColorEscape(raw, g_szPrefix, charsmax(g_szPrefix));
    // v3.0: mesaj turune gore sohbet etiketleri ([BOSS] [EVENT] [VIP] [ADMIN])
    get_pcvar_string(g_pPrefixBoss, raw, charsmax(raw));
    ColorEscape(raw, g_szPrefixBoss, charsmax(g_szPrefixBoss));
    get_pcvar_string(g_pPrefixEvent, raw, charsmax(raw));
    ColorEscape(raw, g_szPrefixEvent, charsmax(g_szPrefixEvent));
    get_pcvar_string(g_pPrefixVip, raw, charsmax(raw));
    ColorEscape(raw, g_szPrefixVip, charsmax(g_szPrefixVip));
    get_pcvar_string(g_pPrefixAdmin, raw, charsmax(raw));
    ColorEscape(raw, g_szPrefixAdmin, charsmax(g_szPrefixAdmin));
    ApplyHostname();
    // v3.0 (C): oylamayla uzatilan harita, cfg yeniden yuklenince kisalmasin
    if (g_iMapExtendTo > get_cvar_num("mp_maxrounds"))
        set_cvar_num("mp_maxrounds", g_iMapExtendTo);
}

// "^1" "^3" "^4" -> chat renk karakterleri
ColorEscape(const src[], dst[], len)
{
    new j;
    for (new i = 0; src[i] && j < len; i++)
    {
        if (src[i] == '^^' && src[i + 1] >= '1' && src[i + 1] <= '4')
        {
            dst[j++] = src[i + 1] - '0';
            i++;
        }
        else
            dst[j++] = src[i];
    }
    dst[j] = 0;
}

TblIdx(const args[][], argc, need, maxIdx)
{
    if (argc < need)
    {
        log_amx("[Vexmira] %s: eksik deger (%d gerekli)", args[0], need - 1);
        return -1;
    }
    new i = str_to_num(args[1]);
    if (i < 0 || i >= maxIdx)
    {
        log_amx("[Vexmira] %s: gecersiz numara %d (0-%d)", args[0], i, maxIdx - 1);
        return -1;
    }
    return i;
}

EnvLightArg(const a[])
{
    if (!a[0] || a[0] == '0' || a[0] == '-')
        return 0;
    new c = tolower(a[0]);
    return (c >= 'a' && c <= 'z') ? c : 0;
}

// true = tablo komutu islendi
bool:ApplyTableCmd(const args[][], argc)
{
    new i;
    // Kozmetik model tablolari yalniz harita basinda (precache) okunur
    if (equali(args[0], "vex_wing") || equali(args[0], "vex_pet") || equali(args[0], "vex_hat"))
        return true;
    if (equali(args[0], "vex_item"))
    {
        // vex_item <no> <fiyat AP> <round limiti> <level> [deger]
        if ((i = TblIdx(args, argc, 5, NUM_ITEMS)) >= 0)
        {
            ITEM_COST[i]  = max(0, str_to_num(args[2]));
            ITEM_LIMIT[i] = max(0, str_to_num(args[3]));
            ITEM_LVL[i]   = clamp(str_to_num(args[4]), 1, MAX_LEVEL);
            if (argc > 5)
                ITEM_VAL[i] = str_to_num(args[5]);
        }
        return true;
    }
    if (equali(args[0], "vex_class"))
    {
        // vex_class <no> <can carpani> <hiz> <yercekimi> <geri tepme> <yetenek bekleme> <level>
        if ((i = TblIdx(args, argc, 8, NUM_CLASSES)) >= 0)
        {
            CLASS_HP[i]   = floatmax(0.05, str_to_float(args[2]));
            CLASS_SPD[i]  = clamp(str_to_num(args[3]), 50, 900);
            CLASS_GRAV[i] = floatclamp(str_to_float(args[4]), 0.1, 2.0);
            CLASS_KB[i]   = floatmax(0.0, str_to_float(args[5]));
            CLASS_COOL[i] = floatmax(0.5, str_to_float(args[6]));
            CLASS_LVL[i]  = clamp(str_to_num(args[7]), 1, MAX_LEVEL);
        }
        return true;
    }
    if (equali(args[0], "vex_modewpn"))
    {
        // vex_modewpn <survivor|sniper> <yuva 1-2> <weapon_xxx|none> <hasar> <sarjor> <yedek> <efekt>
        if (argc < 4)
            return true;
        new mm = equali(args[1], "survivor") ? 0 : (equali(args[1], "sniper") ? 1 : -1);
        new ms = str_to_num(args[2]) - 1;
        if (mm < 0 || ms < 0 || ms >= MW_SLOTS)
        {
            log_amx("[Vexmira] vex_modewpn: gecersiz mod / yuva: %s %s", args[1], args[2]);
            return true;
        }
        if (equali(args[3], "none") || equal(args[3], "-"))
        {
            MW_ENT[mm][ms][0] = 0;
            return true;
        }
        new WeaponIdType:w = WeaponIdType:rg_get_weapon_info(args[3], WI_ID);
        if (w == WEAPON_NONE || w == WEAPON_KNIFE || w == WEAPON_HEGRENADE || w == WEAPON_SMOKEGRENADE || w == WEAPON_FLASHBANG || w == WEAPON_C4)
        {
            log_amx("[Vexmira] vex_modewpn: gecersiz silah: %s", args[3]);
            return true;
        }
        copy(MW_ENT[mm][ms], charsmax(MW_ENT[][]), args[3]);
        MW_ID[mm][ms] = w;
        if (argc >= 5) MW_DMG[mm][ms]  = floatclamp(str_to_float(args[4]), 0.1, 99999.0);
        if (argc >= 6) MW_CLIP[mm][ms] = clamp(str_to_num(args[5]), 0, 250);
        if (argc >= 7) MW_BP[mm][ms]   = clamp(str_to_num(args[6]), 0, 999);
        if (argc >= 8)
        {
            if (equali(args[7], "fire")) MW_FX[mm][ms] = SWE_FIRE;
            else if (equali(args[7], "lightning")) MW_FX[mm][ms] = SWE_LIGHTNING;
            else if (equali(args[7], "ice")) MW_FX[mm][ms] = SWE_ICE;
            else if (equali(args[7], "vampire")) MW_FX[mm][ms] = SWE_VAMPIRE;
            else if (equali(args[7], "void")) MW_FX[mm][ms] = SWE_VOID;
            else if (equali(args[7], "explosive")) MW_FX[mm][ms] = SWE_EXPLOSIVE;
            else MW_FX[mm][ms] = SWE_NONE;
        }
        return true;
    }
    if (equali(args[0], "vex_sw"))
    {
        // vex_sw <no> <fiyat AP> <level> <hasar carpani> <yedek mermi>
        if ((i = TblIdx(args, argc, 6, NUM_SPECIAL)) >= 0)
        {
            SW_COST[i]   = max(0, str_to_num(args[2]));
            SW_LVL[i]    = clamp(str_to_num(args[3]), 1, MAX_LEVEL);
            SW_MULT[i]   = floatclamp(str_to_float(args[4]), 0.1, 4.0);
            SW_BPAMMO[i] = clamp(str_to_num(args[5]), 1, 999);
            if (argc >= 7)
            {
                if (equali(args[6], "fire")) SW_EFFECT[i] = SWE_FIRE;
                else if (equali(args[6], "lightning")) SW_EFFECT[i] = SWE_LIGHTNING;
                else if (equali(args[6], "ice")) SW_EFFECT[i] = SWE_ICE;
                else if (equali(args[6], "vampire")) SW_EFFECT[i] = SWE_VAMPIRE;
                else if (equali(args[6], "void")) SW_EFFECT[i] = SWE_VOID;
                else if (equali(args[6], "explosive")) SW_EFFECT[i] = SWE_EXPLOSIVE;
                else if (equali(args[6], "none")) SW_EFFECT[i] = SWE_NONE;
            }
            if (argc >= 10)
            {
                SW_RGB[i][0] = clamp(str_to_num(args[7]), 0, 255);
                SW_RGB[i][1] = clamp(str_to_num(args[8]), 0, 255);
                SW_RGB[i][2] = clamp(str_to_num(args[9]), 0, 255);
            }
            if (argc >= 11)
                SW_CLIP[i] = clamp(str_to_num(args[10]), 1, 100);
            if (argc >= 12)
                SW_CHAIN_DMG[i] = clamp(str_to_num(args[11]), 0, 100);
            if (argc >= 13)
                SW_RATE[i] = floatclamp(str_to_float(args[12]), 0.05, 5.0);
            if (argc >= 14)
                SW_RECOIL[i] = floatclamp(str_to_float(args[13]), 0.5, 2.0);
        }
        return true;
    }
    if (equali(args[0], "vex_sw_text"))
    {
        // vex_sw_text <no> <en|tr> <name> <description>
        if ((i = TblIdx(args, argc, 5, NUM_SPECIAL)) >= 0)
        {
            new lang = equali(args[2], "tr") ? 1 : (equali(args[2], "en") ? 0 : -1);
            if (lang >= 0)
            {
                copy(g_szSWName[lang][i], charsmax(g_szSWName[][]), args[3]);
                copy(g_szSWDesc[lang][i], charsmax(g_szSWDesc[][]), args[4]);
            }
        }
        return true;
    }
    if (equali(args[0], "vex_gun"))
    {
        // vex_gun <p|s> <no> <level> <yedek mermi>
        if (argc < 5)
            return true;
        new idx = str_to_num(args[2]);
        if (args[1][0] == 'p' || args[1][0] == 'P')
        {
            if (0 <= idx < sizeof PRIM_LVL)
            {
                PRIM_LVL[idx]  = clamp(str_to_num(args[3]), 1, MAX_LEVEL);
                PRIM_AMMO[idx] = clamp(str_to_num(args[4]), 1, 999);
            }
        }
        else if (0 <= idx < sizeof SEC_LVL)
        {
            SEC_LVL[idx]  = clamp(str_to_num(args[3]), 1, MAX_LEVEL);
            SEC_AMMO[idx] = clamp(str_to_num(args[4]), 1, 999);
        }
        return true;
    }
    if (equali(args[0], "vex_job"))
    {
        // vex_job <no> <level>
        if ((i = TblIdx(args, argc, 3, NUM_JOBS)) >= 0)
            JOB_LVL[i] = clamp(str_to_num(args[2]), 1, MAX_LEVEL);
        return true;
    }
    if (equali(args[0], "vex_boss_stat"))
    {
        // vex_boss_stat <no> <can carpani> <hiz> <yercekimi> [R G B]
        if ((i = TblIdx(args, argc, 5, NUM_BOSSES)) >= 0)
        {
            BOSS_HP_MULT[i] = floatmax(0.05, str_to_float(args[2]));
            BOSS_SPD[i]     = clamp(str_to_num(args[3]), 50, 900);
            BOSS_GRAV[i]    = floatclamp(str_to_float(args[4]), 0.1, 2.0);
            if (argc >= 8)
            {
                BOSS_RGB[i][0] = clamp(str_to_num(args[5]), 0, 255);
                BOSS_RGB[i][1] = clamp(str_to_num(args[6]), 0, 255);
                BOSS_RGB[i][2] = clamp(str_to_num(args[7]), 0, 255);
            }
        }
        return true;
    }
    if (equali(args[0], "vex_boss_skill"))
    {
        // vex_boss_skill <boss> <faz 1-3> <bekleme sn> <hasar> <yaricap>
        if ((i = TblIdx(args, argc, 6, NUM_BOSSES)) >= 0)
        {
            new ph = clamp(str_to_num(args[2]), 1, 3) - 1;
            BSK_COOL[i][ph] = floatmax(1.0, str_to_float(args[3]));
            BSK_DMG[i][ph]  = floatmax(0.0, str_to_float(args[4]));
            BSK_RAD[i][ph]  = max(0, str_to_num(args[5]));
        }
        return true;
    }
    if (equali(args[0], "vex_mode_rule"))
    {
        // vex_mode_rule <mod> <sans> <en az oyuncu>
        if ((i = TblIdx(args, argc, 4, MODE_TOTAL)) >= 0)
        {
            MODE_CHANCE[i] = max(0, str_to_num(args[2]));
            MODE_MINPL[i]  = clamp(str_to_num(args[3]), 1, 32);
        }
        return true;
    }
    if (equali(args[0], "vex_env_event") || equali(args[0], "vex_env_mode") || equali(args[0], "vex_env_boss") || equali(args[0], "vex_env_calm"))
    {
        // vex_env_* <no> <isik a-z | 0> <sis R> <sis G> <sis B> <sis yogunlugu> <hava 0/1/2>
        new kind = equali(args[0], "vex_env_event") ? 0 : equali(args[0], "vex_env_mode") ? 1 : equali(args[0], "vex_env_boss") ? 2 : 3;
        static const MAXN[4] = { EV_TOTAL, MODE_TOTAL, NUM_BOSSES, NUM_CALM };
        if ((i = TblIdx(args, argc, 8, MAXN[kind])) < 0)
            return true;
        new l = EnvLightArg(args[2]), w = clamp(str_to_num(args[7]), 0, 2);
        new f0 = clamp(str_to_num(args[3]), 0, 255), f1 = clamp(str_to_num(args[4]), 0, 255);
        new f2 = clamp(str_to_num(args[5]), 0, 255), f3 = clamp(str_to_num(args[6]), 0, 200);
        switch (kind)
        {
            case 0: { ENV_EV_LIGHT[i] = l ? l : 'm'; ENV_EV_FOG[i][0] = f0; ENV_EV_FOG[i][1] = f1; ENV_EV_FOG[i][2] = f2; ENV_EV_FOG[i][3] = f3; ENV_EV_WEATHER[i] = w; }
            case 1: { ENV_MODE_LIGHT[i] = l; ENV_MODE_FOG[i][0] = f0; ENV_MODE_FOG[i][1] = f1; ENV_MODE_FOG[i][2] = f2; ENV_MODE_FOG[i][3] = f3; ENV_MODE_WEATHER[i] = w; }
            case 2: { ENV_BOSS_LIGHT[i] = l; ENV_BOSS_FOG[i][0] = f0; ENV_BOSS_FOG[i][1] = f1; ENV_BOSS_FOG[i][2] = f2; ENV_BOSS_FOG[i][3] = f3; ENV_BOSS_WEATHER[i] = w; }
            default: { ENV_CALM_LIGHT[i] = l ? l : 'm'; ENV_CALM_FOG[i][0] = f0; ENV_CALM_FOG[i][1] = f1; ENV_CALM_FOG[i][2] = f2; ENV_CALM_FOG[i][3] = f3; ENV_CALM_WEATHER[i] = w; }
        }
        return true;
    }
    if (equali(args[0], "vex_cosmetic"))
    {
        // vex_cosmetic <tur 0 iz / 1 oldurme / 2 enfeksiyon> <no> <fiyat VC>
        if (argc < 4)
            return true;
        new cat = str_to_num(args[1]), idx = str_to_num(args[2]), price = max(1, str_to_num(args[3]));
        switch (cat)
        {
            case 0: if (0 <= idx < NUM_TRAILS) TRAIL_PRICE[idx] = price;
            case 1: if (0 <= idx < NUM_KFX) KFX_PRICE[idx] = price;
            case 2: if (0 <= idx < NUM_IFX) IFX_PRICE[idx] = price;
        }
        return true;
    }
    if (equali(args[0], "vex_quest"))
    {
        // vex_quest <no> <gereken> <XP> <AP>
        if ((i = TblIdx(args, argc, 5, NUM_QUESTS)) >= 0)
        {
            QUEST_NEED[i] = max(1, str_to_num(args[2]));
            QUEST_XP[i]   = max(0, str_to_num(args[3]));
            QUEST_AP[i]   = max(0, str_to_num(args[4]));
        }
        return true;
    }
    return false;
}

// Konsoldan / RCON'dan tablo komutlari (vex_item 0 12 3 1 100 ...)
public srv_TableCmd()
{
    new args[CFG_MAXARGS][128];
    new argc = min(read_argc(), CFG_MAXARGS);
    for (new i = 0; i < argc; i++)
        read_argv(i, args[i], charsmax(args[]));
    if (ApplyTableCmd(args, argc))
        server_print("[Vexmira] %s uygulandi.", args[0]);
    return PLUGIN_HANDLED;
}

// vex_res sunucu konsolunda calistirilinca: harita degisince gecerli olur
public srv_ResCmd()
{
    server_print("[Vexmira] vex_res ayarlari harita degisince yuklenir (ses / model precache).");
    return PLUGIN_HANDLED;
}

public cmd_reload_cfg(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;
    new n = LoadMainConfig(false);
    console_print(id, "[Vexmira] vexmira.cfg yeniden yuklendi (%d satir). Ses/model degisiklikleri harita degisince gecerli.", n);
    if (id)
        AdminNotify(id, "ADM_RELOADED", n);
    return PLUGIN_HANDLED;
}

public task_LoadConfig()
{
    LoadMainConfig(false);
}


/* ================================================================== */
/*  v2.0  SUNUCU ADI (vex_hostname)                                    */
/*  vex_hostname_dynamic 1 = sona canli durum eklenir: "| R7/30 BOSS"  */
/*                       2 = basa eklenir: "[R7/30 BOSS] ..."          */
/* ================================================================== */

ApplyHostname()
{
    new base[100];
    get_pcvar_string(g_pHostname, base, charsmax(base));
    trim(base);
    if (!base[0])
        return;

    // Sunucu listesi 63 karakterden sonrasini keser: durum etiketi sigmazsa
    // once kisa etiket ("BOSS"), o da sigmazsa sadece ana isim kullanilir.
    new name[128], tag[40], dyn = get_pcvar_num(g_pHostDyn);
    copy(name, charsmax(name), base);
    if (dyn > 0 && g_iRound > 0)
    {
        for (new pass = 0; pass < 2; pass++)
        {
            HostTag(tag, charsmax(tag), pass == 1);
            if (strlen(base) + strlen(tag) + 3 > HOSTNAME_MAX)
                continue;
            if (dyn == 2)
                formatex(name, charsmax(name), "[%s] %s", tag, base);
            else
                formatex(name, charsmax(name), "%s | %s", base, tag);
            break;
        }
    }
    name[HOSTNAME_MAX] = EOS;

    new cur[128];
    get_cvar_string("hostname", cur, charsmax(cur));
    if (!equal(cur, name))
        set_cvar_string("hostname", name);
}

HostTag(out[], len, bool:compact = false)
{
    static const MODE_SHORT[MODE_TOTAL][] =
    {
        "", "MULTI", "NEMESIS", "ASSASSIN", "SURVIVOR", "SNIPER", "SWARM", "PLAGUE", "ARMAGEDDON", "BOSS"
    };
    static const EV_SHORT[EV_TOTAL][] =
    {
        "", "BLOOD MOON", "FOG", "SPEED RUSH", "LOW GRAVITY", "x2 DAMAGE", "DARK NIGHT", "OUTBREAK",
        "SUPPLY", "BERSERK", "ADRENALINE", "METEORS", "HORDE", "TITAN", "GOLD RUSH", "VAMPIRE",
        "HEADHUNTER", "STORM", "BLACKOUT"
    };
    new total = RoundsTotal();
    if (compact)
    {
        if (g_iMode != MODE_INFECTION && g_iMode < MODE_TOTAL)
            copy(out, len, MODE_SHORT[g_iMode]);
        else if (g_iEvent > EV_NONE && g_iEvent < EV_TOTAL)
            copy(out, len, EV_SHORT[g_iEvent]);
        else
            formatex(out, len, "R%d", g_iRound);
        return;
    }
    if (g_iMode != MODE_INFECTION && g_iMode < MODE_TOTAL)
        formatex(out, len, "R%d/%d %s", g_iRound, total, MODE_SHORT[g_iMode]);
    else if (g_iEvent > EV_NONE && g_iEvent < EV_TOTAL)
        formatex(out, len, "R%d/%d %s", g_iRound, total, EV_SHORT[g_iEvent]);
    else
        formatex(out, len, "R%d/%d", g_iRound, total);
}

public task_Hostname()
{
    ApplyHostname();
}

/* ===== End module: resources.inc ===== */
/* ================================================================== */
/*  BOLUM 5/13: ISTATISTIK                                            */
/*  nvault kayit / yukleme, level / rutbe / basarim / unvan /         */
/*  gunluk odul, round gorevleri, TOP 15 siralama, oyuncu karti.      */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
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

    new key[48], val[512];
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
    g_iCmOwned[id]     = (n > 33) ? f[33] : 0;
    g_iCmSelPk[id]     = (n > 34) ? f[34] : 0;

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

    new key[48], val[512];
    GetKey(id, key, charsmax(key));

    formatex(val, charsmax(val), "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
        g_iXP[id], g_iAP[id], g_iVC[id], g_iKills[id], g_iInfects[id], g_iWins[id], g_iBossK[id], g_iHS[id],
        g_iAch[id], g_iTitle[id], g_iJobNext[id] >= 0 ? g_iJobNext[id] : g_iJob[id], g_iStyle[id], g_iSet[id], g_iTheme[id], g_iLang[id],
        g_iDailyDay[id], g_iDailyStreak[id], g_iPrim[id], g_iSec[id], g_iPlaySec[id] / 60,
        g_iPerk[id][0], g_iPerk[id][1], g_iPerk[id][2], g_iPerk[id][3], g_iPerk[id][4], g_iPerk[id][5],
        g_iClassNext[id] >= 0 ? g_iClassNext[id] : g_iClass[id], get_systime(), g_iHudPos[id],
        g_iCosOwned[id], g_iTrailSel[id], g_iKfxSel[id], g_iIfxSel[id], g_iCmOwned[id], g_iCmSelPk[id]);

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
    if (!CsoNotify(id, CN_LEVEL, g_iLevel[id]))
        HudTo(id, SL_PERS, CLR_REWARD, 3.5, "LEVEL_UP_HUD", g_iLevel[id]);
    Chat(id, "LEVELUP_VC", vc);

    for (new p = 1; p <= g_iMax && get_pcvar_num(g_pChatBcast); p++)
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
        for (new p = 1; p <= g_iMax && get_pcvar_num(g_pChatBcast); p++)
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

    for (new p = 1; p <= g_iMax && get_pcvar_num(g_pChatBcast); p++)
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

    // v3.2: VIP gunluk odul bonusu cfg'den (yuzde; VC en az +1)
    new dp = VipDailyPct(id);
    if (dp > 0)
    {
        ap += ap * dp / 100;
        vc += max(1, vc * dp / 100);
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
    new title[320], item[128], key[12], tn[40];

    VexHead(id, title, charsmax(title), "MENU_TITLE");
    new menu = VexMenuCreate(title, "menu_title_handler");

    for (new i = 0; i < NUM_TITLES; i++)
    {
        formatex(key, charsmax(key), "TITLE_%d", i);
        formatex(tn, charsmax(tn), "%L", id, key);

        if (!TitleUnlocked(id, i))
        {
            new ak[16], an[40];
            formatex(ak, charsmax(ak), "ACH_NAME_%d", TITLE_ACH[i]);
            formatex(an, charsmax(an), "%L", id, ak);
            formatex(item, charsmax(item), "\y%s \r(%s) \r[%L]", tn, an, id, "MENU_LOCKED");
        }
        else if (g_iTitle[id] == i)
            formatex(item, charsmax(item), "\y%s \r[*\r]", tn);
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
    new title[320], item[160], k1[16], k2[16], n1[40], n2[64], count;

    for (new i = 0; i < NUM_ACH; i++)
    {
        if (g_iAch[id] & (1 << i))
            count++;
    }

    new hsub[32];
    formatex(hsub, charsmax(hsub), "[\y%d / %d\r]", count, NUM_ACH);
    VexHead(id, title, charsmax(title), "MENU_ACH", hsub);
    new menu = VexMenuCreate(title, "menu_ach_handler");

    for (new i = 0; i < NUM_ACH; i++)
    {
        formatex(k1, charsmax(k1), "ACH_NAME_%d", i);
        formatex(k2, charsmax(k2), "ACH_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);
        if (g_iAch[id] & (1 << i))
            formatex(item, charsmax(item), "\r[\yX\r] \y%s \r- \d%s", n1, n2);
        else
            formatex(item, charsmax(item), "\r[ ] \y%s \r- \d%s", n1, n2);

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
    for (new p = 1; p <= g_iMax && get_pcvar_num(g_pChatBcast); p++)
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
    len += formatex(html[len], charsmax(html) - len, "<h2>%s</h2><div class=t>Lv.%d • %s", name, lvl, tname);
    if (g_iTopRank[target] > 0)
        len += formatex(html[len], charsmax(html) - len, " • TOP #%d", g_iTopRank[target]);
    if (IsElite(target))
        len += formatex(html[len], charsmax(html) - len, " • ELITE");
    else if (IsVip(target))
        len += formatex(html[len], charsmax(html) - len, " • VIP");
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
    for (new p = 1; p <= g_iMax && get_pcvar_num(g_pChatBcast); p++)
    {
        if (p != id && is_user_connected(p) && !is_user_bot(p))
            client_print_color(p, id, "%s %L", ChatTag("TOP_JOIN"), p, "TOP_JOIN", r, name);
    }
}

/* ===== End module: stats.inc ===== */
/* ================================================================== */
/*  BOLUM 6/13: EKONOMI                                               */
/*  AP / VC / XP odulleri, market (esya), ozel silah satin alma,      */
/*  kalici yetenekler (perk), VIP / ELITE, kozmetikler (iz, oldurme   */
/*  / enfeksiyon efekti).                                             */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
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
    m += float(VipBonusPct(id)) / 100.0;
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

    xp = xp * (100 + VipBonusPct(id)) / 100;
    if (g_iEvent == EV_GOLDRUSH)
        xp *= 2;

    new old = g_iLevel[id];
    g_iXP[id] = max(0, g_iXP[id] + xp);
    g_iRoundXP[id] += xp;
    g_iLevel[id] = CalcLevel(g_iXP[id]);

    // A short native XP progress animation is sent only on positive XP gains.
    // Do not overwrite the active laser plant/take countdown bar.
    if (xp > 0 && HudPartMode(g_pHudXp) == 2 && !g_iPlantAction[id] && !CsoOn())
    {
        new lvl = g_iLevel[id];
        new pct = (lvl >= MAX_LEVEL) ? 100 : clamp((g_iXP[id] - XPForLevel(lvl)) * 100 / max(1, XPForLevel(lvl + 1) - XPForLevel(lvl)), 0, 100);
        rg_send_bartime2(id, 2, float(pct), false);
    }

    if (ap > 0)
        AddAP(id, ap, true, false);

    // v3.2: grafik modda da kisa yazi (bartime yalniz XP ilerlemesini gosterir, AP'yi gostermez)
    if ((xp > 0 || ap > 0) && HudPartMode(g_pHudXp) != 0)
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
    new title[320], item[160], k1[12], k2[16], n1[40], n2[64];
    new isZ = g_bZombie[id] ? 1 : 0;

    if (isZ) VexHead(id, title, charsmax(title), "MENU_SHOP_Z"); else VexHead(id, title, charsmax(title), "MENU_SHOP_H");
    new menu = VexMenuCreate(title, "menu_shop_handler");

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
            formatex(item, charsmax(item), "\y%s \r[Lv.%d] \r[%L]", n1, ITEM_LVL[i], id, "MENU_LOCKED");
        else if (ITEM_LIMIT[i] && g_iBought[id][i] >= ITEM_LIMIT[i])
            formatex(item, charsmax(item), "\y%s \r[%L] \r[%L]", n1, id, "SHOP_SOLDOUT", id, "MENU_LOCKED");
        else if (g_iAP[id] >= cost)
            formatex(item, charsmax(item), "\y%s \r[%d AP]", n1, cost);
        else
            formatex(item, charsmax(item), "\y%s \r[%d AP] \r[%L]", n1, cost, id, "MENU_LOCKED");

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
    cost = cost * (100 - VipDiscPct(id)) / 100;
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
    {
        DescChat(id, "ITEM_%d", "ITEM_DESC_%d", sel);
        BuyItem(id, sel);
    }

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

    for (new p = 1; p <= g_iMax && get_pcvar_num(g_pChatBuyBcast); p++)
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
    new title[320], item[160], k1[12], k2[16], n1[40], n2[64];

    VexHead(id, title, charsmax(title), "MENU_SPECIAL");
    new menu = VexMenuCreate(title, "menu_special_handler");

    for (new i = 0; i < NUM_SPECIAL; i++)
    {
        formatex(k1, charsmax(k1), "SW_%d", i);
        formatex(k2, charsmax(k2), "SW_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        if (g_iLevel[id] < SW_LVL[i])
            formatex(item, charsmax(item), "\y%s \r[Lv.%d] \r[%L]", n1, SW_LVL[i], id, "MENU_LOCKED");
        else if (g_iSpecW[id] & (1 << i))
            formatex(item, charsmax(item), "\y%s \r[%L\r]", n1, id, "OWNED");
        else if (g_iAP[id] >= SwPrice(id, i))
            formatex(item, charsmax(item), "\y%s \r[%d AP]", n1, SwPrice(id, i));
        else
            formatex(item, charsmax(item), "\y%s \r[%d AP] \r[%L]", n1, SwPrice(id, i), id, "MENU_LOCKED");

        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

SwPrice(id, i)
{
    new c = SW_COST[i];
    c = c * (100 - VipDiscPct(id)) / 100;
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
    DescChat(id, "SW_%d", "SW_DESC_%d", i);

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
    new weapon = rg_give_item(id, SW_BASE_ENT[i], GT_REPLACE);
    if (!is_nullent(weapon))
        set_member(weapon, m_Weapon_iClip, SW_CLIP[i]);
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
    new title[320], item[160], k1[12], k2[16], n1[32], n2[64];

    VexHead(id, title, charsmax(title), "MENU_PERKS");
    new menu = VexMenuCreate(title, "menu_perk_handler");

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

        // Kisa satir: ad + seviye + fiyat (aciklama secince sohbette; menu metni en fazla 512 karakter)
        if (lv >= PERK_MAX)
            formatex(item, charsmax(item), "\y%s \r[\y%s\r] [\yMAX\r]", n1, stars);
        else
            formatex(item, charsmax(item), "\y%s \r[\y%s\r] [%s%d VC\r]", n1, stars,
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
    DescChat(id, "PERK_%d", "PERK_DESC_%d", p);

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

// v3.2: VIP degerleri cfg'den (vex_vip_* / vex_elite_*)
VipBonusPct(id)
{
    if (IsElite(id)) return clamp(get_pcvar_num(g_pEliteBonus), 0, 300);
    if (IsVip(id))   return clamp(get_pcvar_num(g_pVipBonus), 0, 300);
    return 0;
}

VipDiscPct(id)
{
    if (IsElite(id)) return clamp(get_pcvar_num(g_pEliteDisc), 0, 90);
    if (IsVip(id))   return clamp(get_pcvar_num(g_pVipDisc), 0, 90);
    return 0;
}

VipArmor(id)
{
    if (IsElite(id)) return max(0, get_pcvar_num(g_pEliteArmor));
    if (IsVip(id))   return max(0, get_pcvar_num(g_pVipArmor));
    return 0;
}

VipRoundVC(id)
{
    if (!IsVip(id)) return 0;
    new v = max(0, get_pcvar_num(g_pVipRoundVC));
    return IsElite(id) ? v * 2 : v;
}

// v3.2: oy agirligi (mod / event / harita oylamasi; vex_vip_vote_weight)
VipVoteW(id)
{
    if (!(1 <= id <= g_iMax) || !IsVip(id))
        return 1;
    return clamp(get_pcvar_num(g_pVipVoteW), 1, 3);
}

// v3.2: dogus korumasina eklenen sure (vex_vip_spawnprot)
Float:VipSpawnProt(id)
{
    if (!IsVip(id))
        return 0.0;
    return floatclamp(get_pcvar_float(g_pVipSpawnProt), 0.0, 5.0);
}

// v3.2: gunluk odul VIP carpani (vex_vip_daily_pct / vex_elite_daily_pct)
VipDailyPct(id)
{
    if (IsElite(id)) return clamp(get_pcvar_num(g_pEliteDaily), 0, 300);
    if (IsVip(id))   return clamp(get_pcvar_num(g_pVipDaily), 0, 300);
    return 0;
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

// v3.2: skor tablosunda VIP etiketi (oyunun kendi "VIP" sutunu; vex_vip_scoreboard)
public msg_ScoreAttrib(msgid, dest, rcv)
{
    new p = get_msg_arg_int(1);
    if (1 <= p <= g_iMax && IsVip(p) && get_pcvar_num(g_pVipScore))
        set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2) | (1 << 2));
    return PLUGIN_CONTINUE;
}

// Baglaninca VIP karsilama
VipWelcome(id)
{
    if (!IsVip(id))
        return;

    new name[32], tier[16];
    get_user_name(id, name, charsmax(name));
    VipTierKey(id, tier, charsmax(tier));

    // v3.2: oncelikli giris mesaji (sunucu dolmak uzereyken; vex_vip_priority_msg)
    new pri = get_pcvar_num(g_pVipPriority);
    if (pri > 0 && get_playersnum(1) >= g_iMax - pri)
    {
        for (new p = 1; p <= g_iMax; p++)
            if (is_user_connected(p) && !is_user_bot(p))
                client_print_color(p, id, "%s %L", ChatTag("VIP_JOIN"), p, "VIP_PRIORITY", name);
    }
    // vex_vip_join_announce: 0 kapali, 1 sohbet + HUD, 2 + ses
    new ann = get_pcvar_num(g_pVipAnnounce);
    for (new p = 1; p <= g_iMax && ann > 0; p++)
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
    if (ann >= 2)
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

// v3.2: VIP ayricaliklari 2 sayfa (istemci menu metni en fazla 512 karakter); degerler cfg'den canli
ShowVipInfo(id, page = 0)
{
    new contact[64], title[640], ln[128], hsub[96];
    get_pcvar_string(g_pVipContact, contact, charsmax(contact));
    if (IsVip(id))
        formatex(hsub, charsmax(hsub), "[\y%L\r] [\y%d / 2\r]", id, IsElite(id) ? "VIP_TIER_2" : "VIP_TIER_1", page + 1);
    else
        formatex(hsub, charsmax(hsub), "%L \r[\y%d / 2\r]", id, "VIPI_BUY", contact, page + 1);
    VexHead(id, title, charsmax(title), "VIPI_TITLE", hsub);
    add(title, charsmax(title), "^n");

    if (page == 0)
    {
        // Ekonomi / oyun ici
        formatex(ln, charsmax(ln), "\r1. \d%L^n", id, "VIPI_2", get_pcvar_num(g_pVipBonus), get_pcvar_num(g_pEliteBonus)); add(title, charsmax(title), ln);
        formatex(ln, charsmax(ln), "\r2. \d%L^n", id, "VIPI_3", get_pcvar_num(g_pVipDisc), get_pcvar_num(g_pEliteDisc)); add(title, charsmax(title), ln);
        formatex(ln, charsmax(ln), "\r3. \d%L^n", id, "VIPI_6", get_pcvar_num(g_pVipRoundVC), get_pcvar_num(g_pVipRoundVC) * 2); add(title, charsmax(title), ln);
        formatex(ln, charsmax(ln), "\r4. \d%L^n", id, "VIPI_7", get_pcvar_num(g_pVipDaily), get_pcvar_num(g_pEliteDaily)); add(title, charsmax(title), ln);
        formatex(ln, charsmax(ln), "\r5. \y%L^n", id, get_pcvar_num(g_pVipAutoPack) ? "VIPI_4A" : "VIPI_4"); add(title, charsmax(title), ln);
        formatex(ln, charsmax(ln), "\r6. \d%L^n", id, "VIPI_5", get_pcvar_num(g_pVipArmor), get_pcvar_num(g_pEliteArmor), get_pcvar_num(g_pLmPerRoundVip)); add(title, charsmax(title), ln);
        formatex(ln, charsmax(ln), "\r7. \d%L^n", id, "VIPI_1"); add(title, charsmax(title), ln);
    }
    else
    {
        // Konfor / gorunum (pay-to-win degil)
        formatex(ln, charsmax(ln), "\r8. \d%L^n", id, "VIPI_9", get_pcvar_float(g_pVipSpawnProt)); add(title, charsmax(title), ln);
        formatex(ln, charsmax(ln), "\r9. \d%L^n", id, "VIPI_10", clamp(get_pcvar_num(g_pVipVoteW), 1, 3)); add(title, charsmax(title), ln);
        formatex(ln, charsmax(ln), "\r10. \d%L^n", id, "VIPI_11"); add(title, charsmax(title), ln);
        formatex(ln, charsmax(ln), "\r11. \d%L^n", id, "VIPI_12"); add(title, charsmax(title), ln);
        formatex(ln, charsmax(ln), "\r12. \d%L^n", id, "VIPI_8"); add(title, charsmax(title), ln);
        formatex(ln, charsmax(ln), "\r13. \d%L^n", id, "VIPI_13"); add(title, charsmax(title), ln);
        formatex(ln, charsmax(ln), "\r14. \d%L^n", id, "VIPI_14"); add(title, charsmax(title), ln);
    }

    new menu = VexMenuCreate(title, "menu_vipinfo_handler");
    new item[64];
    formatex(item, charsmax(item), "\y%L", id, page == 0 ? "MENU_NEXT" : "MENU_BACK");
    MenuAdd(menu, item, page == 0 ? 11 : 10);
    formatex(item, charsmax(item), "\y%L", id, "HUB_BACK");
    MenuAdd(menu, item, 1);
    MenuNoPage(menu);
    menu_setprop(menu, MPROP_EXIT, MEXIT_FORCE);
    MenuFinish(id, menu);
}

public menu_vipinfo_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new sel = MenuInfo(menu, item);
    menu_destroy(menu);
    if (sel >= 10)
        ShowVipInfo(id, sel - 10);
    else if (IsVip(id))
        ShowVipMenu(id);
    else
        ShowMainMenu(id);
    return PLUGIN_HANDLED;
}

ShowVipMenu(id)
{
    new title[320], item[128], tier[16], tn[16], left[32];
    VipTierKey(id, tier, charsmax(tier));
    formatex(tn, charsmax(tn), "%L", id, tier);

    if (g_iVipExpire[id] > 0)
        formatex(left, charsmax(left), "%L", id, "VIP_LEFT_DAYS", max(0, (g_iVipExpire[id] - get_systime()) / 86400));
    else
        formatex(left, charsmax(left), "%L", id, "VIP_PERMANENT");

    new hsub[64];
    formatex(hsub, charsmax(hsub), "[\y%s\r] [\y%s\r]", tn, left);
    VexHead(id, title, charsmax(title), "MENU_VIP", hsub);
    new menu = VexMenuCreate(title, "menu_vip_handler");

    formatex(item, charsmax(item), "\y%L%s", id, g_bZombie[id] ? "VIPM_FREE_Z" : "VIPM_FREE_H", g_bVipFreeUsed[id] ? " \r[X]" : "");
    MenuAdd(menu, item, 1);

    new ak[16];
    formatex(ak, charsmax(ak), "AURA_%d", g_iVipAura[id]);
    formatex(item, charsmax(item), "\y%L \r[%L\r]", id, "VIPM_AURA", id, ak);
    MenuAdd(menu, item, 2);

    new st[32];
    VexOnOff(id, g_bVipTrail[id] ? true : false, st, charsmax(st));
    formatex(item, charsmax(item), "\y%L %s", id, "VIPM_TRAIL", st);
    MenuAdd(menu, item, 3);

    formatex(item, charsmax(item), "\y%L", id, "VIPM_JUMPS");
    MenuAdd(menu, item, 4);

    formatex(item, charsmax(item), "\y%L", id, "VIPM_INFO");
    MenuAdd(menu, item, 5);

    formatex(item, charsmax(item), "\y%L", id, "HUB_BACK");
    MenuAdd(menu, item, 6);

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
        case 6:
        {
            ShowMainMenu(id);
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
    p = p * (100 - VipDiscPct(id)) / 100;
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
    new title[320], item[128], cur[48];
    VexHead(id, title, charsmax(title), "COS_MENU");
    new menu = VexMenuCreate(title, "menu_cos_handler");

    static const CATKEY[3][] = { "COS_CAT_TRAIL", "COS_CAT_KFX", "COS_CAT_IFX" };
    for (new c = 0; c < 3; c++)
    {
        new sel = CosSelected(id, c);
        if (sel > 0)
            CosName(id, c, sel - 1, cur, charsmax(cur));
        else
            formatex(cur, charsmax(cur), "%L", id, "COS_NONE");
        formatex(item, charsmax(item), "\y%L \r[%s\r]", id, CATKEY[c], cur);
        MenuAdd(menu, item, c);
    }
    // v3.2: kanat / pet / sapka (yalniz dosyasi olan satir varsa gorunur)
    new bool:gap = false;
    for (new c = 0; c < CM_CATS; c++)
    {
        if (!g_iCmN[c])
            continue;
        if (!gap)
        {
            menu_addblank(menu, 0);
            gap = true;
        }
        new v = CmSel(id, c);
        if (v > 0 && g_bCmOk[c][v - 1])
            CmName(id, c, v - 1, cur, charsmax(cur));
        else
            formatex(cur, charsmax(cur), "%L", id, "COS_NONE");
        formatex(item, charsmax(item), "\y%L \r[%s\r]", id, CM_CATKEY[c], cur);
        MenuAdd(menu, item, 3 + c);
    }
    if (gap && get_pcvar_num(g_pCosHide))
    {
        formatex(item, charsmax(item), "\y%L \r[%L\r]", id, "COS_HIDE_OTHERS", id, (g_iSet[id] & SET_NO_COS) ? "COS_HIDDEN" : "COS_VISIBLE");
        MenuAdd(menu, item, 9);
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
    if (cat == 9)
    {
        g_iSet[id] ^= SET_NO_COS;
        Chat(id, (g_iSet[id] & SET_NO_COS) ? "COS_HIDE_ON" : "COS_HIDE_OFF");
        SaveData(id);
        ShowCosmeticMenu(id);
    }
    else if (cat >= 3)
        ShowCmList(id, cat - 3);
    else
        ShowCosList(id, cat);
    return PLUGIN_HANDLED;
}

ShowCosList(id, cat)
{
    new title[320], item[128], nm[48];
    static const CATKEY[3][] = { "COS_CAT_TRAIL", "COS_CAT_KFX", "COS_CAT_IFX" };
    VexHead(id, title, charsmax(title), CATKEY[cat]);
    new menu = VexMenuCreate(title, "menu_coslist_handler");

    new sel = CosSelected(id, cat);
    formatex(item, charsmax(item), sel == 0 ? "\y%L \r[*\r]" : "\y%L", id, "COS_NONE");
    MenuAdd(menu, item, cat * 100);

    for (new i = 0; i < CosCount(cat); i++)
    {
        CosName(id, cat, i, nm, charsmax(nm));
        if (sel == i + 1)
            formatex(item, charsmax(item), "\y%s \r[%L\r]", nm, id, "COS_EQUIPPED");
        else if (g_iCosOwned[id] & CosBit(cat, i))
            formatex(item, charsmax(item), "\y%s \r[%L]", nm, id, "COS_OWNED");
        else
            formatex(item, charsmax(item), "\y%s \r[%d VC\r]", nm, CosPrice(id, cat, i));
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
            for (new p = 1; p <= g_iMax && get_pcvar_num(g_pChatBuyBcast); p++)
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

/* ================================================================== */
/*  v3.2 KOZMETIK MODELLER: KANAT / PET / SAPKA                        */
/*  Tablolar vexmira.cfg'de (vex_wing / vex_pet / vex_hat), harita     */
/*  basinda okunur; model dosyasi yoksa satir gizlenir, indirilmez.    */
/*  Bag tipi:                                                          */
/*   bone   = MOVETYPE_FOLLOW + aiment: CS iskeleti (Bip01 ...) ile    */
/*            yapilmis model kemiklere oturur, animasyonla oynar.      */
/*   head   = kafanin ustu: AddToFullPack her pakette oyuncu konumu +  */
/*            model kafa yuksekligi (gostergelerle ayni okuma) +       */
/*            yona gore donen ofset / aci yazar (titreme yok).         */
/*   back   = sirt (kafa yuksekliginin 18 birim alti) ayni yontem.     */
/*   follow = pet: ayri varlik, 0.1 sn'de bir hedefe yumusak hizla     */
/*            suzulur (NOCLIP + hiz; istemci enterpole eder), hafif    */
/*            yukari-asagi salinir; uzaklasirsa isinlanir.             */
/*  Olu / zombi / izleyici iken yok; cikista silinir. Sapka ve kanat   */
/*  sahibine birinci sahis gorunumde gizlidir (kamerayi kapatmasin).   */
/* ================================================================== */


// vex_wing <no 1-8> "<ad EN>" "<ad TR>" "<model>" <fiyat VC> <vip 0/1> <bone|head|back|follow>
//          <ofs x> <ofs y> <ofs z> <aci p> <aci y> <aci r> <olcek> <sequence> <framerate>
CmParse(const args[][], argc)
{
    new c = -1;
    for (new k = 0; k < CM_CATS; k++)
        if (equali(args[0], CM_TABLE[k])) c = k;
    if (c < 0 || argc < 5)
        return;
    new i = str_to_num(args[1]) - 1;
    if (i < 0 || i >= CM_MAX)
    {
        log_amx("[Vexmira] %s: gecersiz no %s (1-%d)", args[0], args[1], CM_MAX);
        return;
    }
    copy(g_szCmEn[c][i], charsmax(g_szCmEn[][]), args[2]);
    copy(g_szCmTr[c][i], charsmax(g_szCmTr[][]), args[3]);
    copy(g_szCmMdl[c][i], charsmax(g_szCmMdl[][]), args[4]);
    g_iCmPrice[c][i] = (argc > 5) ? max(0, str_to_num(args[5])) : 100;
    g_iCmVip[c][i]   = (argc > 6) ? str_to_num(args[6]) : 0;
    new a = (c == 1) ? CMA_FOLLOW : ((c == 2) ? CMA_HEAD : CMA_BACK);
    if (argc > 7)
    {
        if (equali(args[7], "bone")) a = CMA_BONE;
        else if (equali(args[7], "head")) a = CMA_HEAD;
        else if (equali(args[7], "back")) a = CMA_BACK;
        else if (equali(args[7], "follow")) a = CMA_FOLLOW;
    }
    g_iCmAtt[c][i] = a;
    for (new k = 0; k < 3; k++)
    {
        g_fCmOfs[c][i][k] = (argc > 8 + k) ? floatclamp(str_to_float(args[8 + k]), -128.0, 128.0) : 0.0;
        g_fCmAng[c][i][k] = (argc > 11 + k) ? str_to_float(args[11 + k]) : 0.0;
    }
    g_fCmScale[c][i] = (argc > 14) ? floatclamp(str_to_float(args[14]), 0.05, 5.0) : 1.0;
    if (g_fCmScale[c][i] <= 0.0) g_fCmScale[c][i] = 1.0;
    g_iCmSeq[c][i]   = (argc > 15) ? max(0, str_to_num(args[15])) : 0;
    g_fCmFps[c][i]   = (argc > 16) ? floatclamp(str_to_float(args[16]), 0.0, 10.0) : 1.0;

    // Dosya kontrolu + precache CmPrecache'te (model butcesi ayarlandiktan sonra)
    g_bCmOk[c][i] = false;
    if (!g_szCmMdl[c][i][0] || !file_exists(g_szCmMdl[c][i], true))
    {
        log_amx("[Vexmira] %s %d: model yok (%s) - menude gizli", args[0], i + 1, g_szCmMdl[c][i]);
        g_szCmMdl[c][i][0] = 0;
    }
}

// plugin_precache: dosyasi olan kozmetik modeller (butce dolarsa satir gizlenir)
CmPrecache()
{
    for (new c = 0; c < CM_CATS; c++)
    {
        g_iCmN[c] = 0;
        for (new i = 0; i < CM_MAX; i++)
        {
            g_bCmOk[c][i] = (g_szCmMdl[c][i][0] && PcModel(g_szCmMdl[c][i])) ? true : false;
            if (g_bCmOk[c][i])
                g_iCmN[c]++;
        }
    }
}

CmSel(id, c)
{
    return (g_iCmSelPk[id] >> (c * 4)) & 15;
}

CmSetSel(id, c, v)
{
    g_iCmSelPk[id] = (g_iCmSelPk[id] & ~(15 << (c * 4))) | ((v & 15) << (c * 4));
}

CmName(id, c, i, out[], len)
{
    new lg[4];
    get_user_info(id, "lang", lg, charsmax(lg));
    copy(out, len, (equali(lg, "tr") && g_szCmTr[c][i][0]) ? g_szCmTr[c][i] : g_szCmEn[c][i]);
}

CmPrice(id, c, i)
{
    new p = g_iCmPrice[c][i] * (100 - VipDiscPct(id)) / 100;
    if (CmDealIdx() == c * 16 + i)
        p = p * (100 - CmDealPct()) / 100;
    return max(0, p);
}

// v3.5 gunun firsati: her gun (sunucu saatiyle) sirayla bir kanat / pet / sapka indirimli
CmDealPct()
{
    return clamp(get_pcvar_num(g_pCosDeal), 0, 90);
}

CmDealIdx()
{
    if (CmDealPct() <= 0)
        return -1;
    new total = g_iCmN[0] + g_iCmN[1] + g_iCmN[2];
    if (total <= 0)
        return -1;
    new k = (get_systime() / 86400) % total;
    for (new c = 0; c < CM_CATS; c++)
        for (new i = 0; i < CM_MAX; i++)
            if (g_bCmOk[c][i] && g_iCmPrice[c][i] > 0 && k-- == 0)
                return c * 16 + i;
    return -1;
}

// v3.5 vitrin (on izleme): model oyuncunun onunde doner, sadece kendisi gorur, VC harcamaz
CmPrevRemove(id)
{
    new ent = g_iCmPrev[id];
    g_iCmPrev[id] = 0;
    if (ent > 0 && ent < OVH_MAXENT)
    {
        if (g_iCmOwn[ent] == id)
            g_iCmOwn[ent] = 0;
        if (CmValid(ent, id))
            set_entvar(ent, var_flags, FL_KILLME);
    }
}

CmPrevTarget(id, c, Float:t[3])
{
    new Float:o[3], Float:vo[3], Float:va[3];
    get_entvar(id, var_origin, o);
    get_entvar(id, var_view_ofs, vo);
    get_entvar(id, var_v_angle, va);
    new Float:yaw = va[1] * 3.14159265 / 180.0;
    new Float:d = (c == 0) ? 64.0 : 44.0;
    t[0] = o[0] + floatcos(yaw) * d;
    t[1] = o[1] + floatsin(yaw) * d;
    t[2] = o[2] + vo[2] + ((c == 0) ? -6.0 : ((c == 2) ? -5.0 : -2.0));
}

CmPreview(id, c, i)
{
    CmPrevRemove(id);
    new secs = get_pcvar_num(g_pCosPreview);
    if (secs <= 0 || !g_bCmOk[c][i])
        return;
    new ent = rg_create_entity("info_target");
    if (is_nullent(ent))
        return;
    if (ent >= OVH_MAXENT)
    {
        set_entvar(ent, var_flags, FL_KILLME);
        return;
    }
    set_entvar(ent, var_classname, "vex_cosmodel");
    engfunc(EngFunc_SetModel, ent, g_szCmMdl[c][i]);
    set_entvar(ent, var_solid, SOLID_NOT);
    set_entvar(ent, var_movetype, MOVETYPE_NOCLIP);
    set_entvar(ent, var_iuser1, id);
    set_entvar(ent, var_iuser2, CM_MAGIC);
    set_entvar(ent, var_scale, g_fCmScale[c][i]);
    set_entvar(ent, var_sequence, g_iCmSeq[c][i]);
    set_entvar(ent, var_framerate, g_fCmFps[c][i] > 0.0 ? g_fCmFps[c][i] : 1.0);
    set_entvar(ent, var_animtime, get_gametime());
    new Float:t[3], Float:av[3];
    CmPrevTarget(id, c, t);
    engfunc(EngFunc_SetOrigin, ent, t);
    av[1] = 90.0;
    set_entvar(ent, var_avelocity, av);
    g_iCmOwn[ent] = id;
    g_iCmInfo[ent] = 100 + c * 16 + i;
    g_iCmPrev[id] = ent;
    g_iCmPrevInfo[id] = c * 16 + i;
    g_fCmPrevEnd[id] = get_gametime() + float(clamp(secs, 3, 30));
    new nm[32];
    CmName(id, c, i, nm, charsmax(nm));
    Chat(id, "COS_PREV_START", nm, clamp(secs, 3, 30));
}

CmPrevTick(id, Float:now, bool:conn)
{
    new ent = g_iCmPrev[id];
    if (!conn || now >= g_fCmPrevEnd[id] || !CmValid(ent, id))
    {
        CmPrevRemove(id);
        return;
    }
    new Float:t[3], Float:o[3], Float:v[3];
    CmPrevTarget(id, g_iCmPrevInfo[id] / 16, t);
    get_entvar(ent, var_origin, o);
    if (get_distance_f(o, t) > 300.0)
    {
        engfunc(EngFunc_SetOrigin, ent, t);
        set_entvar(ent, var_velocity, v);
        return;
    }
    for (new k = 0; k < 3; k++)
        v[k] = (t[k] - o[k]) * 8.0;
    set_entvar(ent, var_velocity, v);
}

bool:CmValid(ent, id)
{
    return (ent > g_iMax && ent < OVH_MAXENT && !is_nullent(ent) && get_entvar(ent, var_iuser2) == CM_MAGIC && get_entvar(ent, var_iuser1) == id) ? true : false;
}

CmRemove(id, c)
{
    new ent = g_iCmEnt[id][c];
    g_iCmEnt[id][c] = 0;
    if (ent > 0 && ent < OVH_MAXENT)
    {
        if (g_iCmOwn[ent] == id)
            g_iCmOwn[ent] = 0;
        if (CmValid(ent, id))
            set_entvar(ent, var_flags, FL_KILLME);
    }
}

// Gorunmeli mi? (canli insan, secili + dosyasi var + VIP sarti)
CmWanted(id, c)
{
    if (!is_user_alive(id) || g_bZombie[id] || g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id] || g_bMinion[id])
        return 0;
    new v = CmSel(id, c);
    if (v < 1 || v > CM_MAX)
        return 0;
    new i = v - 1;
    if (!g_bCmOk[c][i] || (g_iCmVip[c][i] && !IsVip(id)))
        return 0;
    return v;
}

// Oyuncu yonune gore ofset: x ileri, y sag, z yukari (+ kafa / sirt yuksekligi)
CmTarget(id, c, i, Float:o[3])
{
    new Float:ang[3];
    get_entvar(id, var_origin, o);
    get_entvar(id, var_angles, ang);
    new Float:yaw = ang[1] * 3.14159265 / 180.0;
    new Float:cy = floatcos(yaw), Float:sy = floatsin(yaw);
    new Float:fx = g_fCmOfs[c][i][0], Float:ry = g_fCmOfs[c][i][1];
    o[0] += cy * fx + sy * ry;
    o[1] += sy * fx - cy * ry;
    new Float:top = (get_entvar(id, var_flags) & FL_DUCKING) ? g_fOvhDuck[id] : g_fOvhStand[id];
    switch (g_iCmAtt[c][i])
    {
        case CMA_HEAD:   o[2] += top + g_fCmOfs[c][i][2];
        case CMA_BACK:   o[2] += top - 18.0 + g_fCmOfs[c][i][2];
        case CMA_FOLLOW: o[2] += top * 0.6 + g_fCmOfs[c][i][2];
        default:         o[2] += g_fCmOfs[c][i][2];
    }
}

CmSpawn(id, c, i)
{
    new ent = rg_create_entity("info_target");
    if (is_nullent(ent))
        return 0;
    if (ent >= OVH_MAXENT)
    {
        set_entvar(ent, var_flags, FL_KILLME);
        return 0;
    }
    set_entvar(ent, var_classname, "vex_cosmodel");
    engfunc(EngFunc_SetModel, ent, g_szCmMdl[c][i]);
    set_entvar(ent, var_solid, SOLID_NOT);
    set_entvar(ent, var_iuser1, id);
    set_entvar(ent, var_iuser2, CM_MAGIC);
    set_entvar(ent, var_scale, g_fCmScale[c][i]);
    set_entvar(ent, var_sequence, g_iCmSeq[c][i]);
    set_entvar(ent, var_framerate, g_fCmFps[c][i]);
    set_entvar(ent, var_animtime, get_gametime());
    set_entvar(ent, var_frame, 0.0);
    new Float:o[3];
    OvhModelTops(id);
    if (g_iCmAtt[c][i] == CMA_BONE)
    {
        // Kemige bagli: istemci oyuncunun iskeletini kopyalar (ayni kemik adlari)
        get_entvar(id, var_origin, o);
        engfunc(EngFunc_SetOrigin, ent, o);
        set_entvar(ent, var_movetype, MOVETYPE_FOLLOW);
        set_entvar(ent, var_aiment, id);
    }
    else
    {
        CmTarget(id, c, i, o);
        engfunc(EngFunc_SetOrigin, ent, o);
        set_entvar(ent, var_movetype, MOVETYPE_NOCLIP);
    }
    g_iCmOwn[ent] = id;
    g_iCmInfo[ent] = c * 16 + i;
    g_iCmEnt[id][c] = ent;
    return ent;
}

// 0.1 sn (gosterge denetcisinden): olustur / sil / pet hareketi
CmTick(Float:now)
{
    if (!g_iCmN[0] && !g_iCmN[1] && !g_iCmN[2])
        return;
    for (new id = 1; id <= g_iMax; id++)
    {
        new bool:conn = is_user_connected(id) ? true : false;
        if (g_iCmPrev[id])
            CmPrevTick(id, now, conn);
        for (new c = 0; c < CM_CATS; c++)
        {
            new ent = g_iCmEnt[id][c];
            new want = conn ? CmWanted(id, c) : 0;
            if (ent && (!CmValid(ent, id) || !want || g_iCmInfo[ent] != c * 16 + want - 1))
            {
                CmRemove(id, c);
                ent = 0;
            }
            if (!want)
                continue;
            new i = want - 1;
            if (!ent)
            {
                ent = CmSpawn(id, c, i);
                if (!ent)
                    continue;
            }
            OvhModelTops(id);
            if (g_iCmAtt[c][i] == CMA_BONE)
                continue;

            new Float:t[3], Float:o[3], Float:v[3], Float:pa[3], Float:a[3];
            CmTarget(id, c, i, t);
            get_entvar(id, var_angles, pa);
            a[0] = g_fCmAng[c][i][0];
            a[1] = pa[1] + g_fCmAng[c][i][1];
            a[2] = g_fCmAng[c][i][2];
            if (g_iCmAtt[c][i] != CMA_FOLLOW)
            {
                // Sunucu konumu PVS / ses icin; cizim konumu AddToFullPack'te
                engfunc(EngFunc_SetOrigin, ent, t);
                set_entvar(ent, var_angles, a);
                continue;
            }
            // Pet: hafif salinim + yumusak takip
            t[2] += 3.0 * floatsin(now * 2.5 + float(id));
            get_entvar(ent, var_origin, o);
            new Float:dist = get_distance_f(o, t);
            if (dist > 400.0)
            {
                engfunc(EngFunc_SetOrigin, ent, t);
                v[0] = 0.0; v[1] = 0.0; v[2] = 0.0;
            }
            else
            {
                for (new k = 0; k < 3; k++)
                    v[k] = (t[k] - o[k]) * 6.0;
                new Float:sp = vector_length(v);
                if (sp > 700.0)
                    for (new k = 0; k < 3; k++) v[k] *= 700.0 / sp;
            }
            set_entvar(ent, var_velocity, v);
            set_entvar(ent, var_angles, a);
        }
    }
}

// Her pakette: sapka / kanat sahibinin gozunden gizli; head / back konumu oyuncunun o anki konumu
CmPack(es, ent, host)
{
    if (!get_orig_retval())
        return FMRES_IGNORED;
    new id = g_iCmOwn[ent];
    if (!(1 <= id <= g_iMax))
        return FMRES_IGNORED;
    if (g_iCmInfo[ent] >= 100)
    {
        // v3.5 vitrin: sadece sahibi gorur
        if (host != id)
            set_es(es, ES_Effects, get_es(es, ES_Effects) | EF_NODRAW);
        return FMRES_IGNORED;
    }
    if (host != id && (g_iSet[host] & SET_NO_COS) && get_pcvar_num(g_pCosHide))
    {
        set_es(es, ES_Effects, get_es(es, ES_Effects) | EF_NODRAW);
        return FMRES_IGNORED;
    }
    new c = g_iCmInfo[ent] / 16, i = g_iCmInfo[ent] % 16;
    if (c >= CM_CATS || i >= CM_MAX)
        return FMRES_IGNORED;
    new att = g_iCmAtt[c][i];
    if (att != CMA_FOLLOW && (host == id || (get_entvar(host, var_iuser1) == 4 && get_entvar(host, var_iuser2) == id)))
    {
        set_es(es, ES_Effects, get_es(es, ES_Effects) | EF_NODRAW);
        return FMRES_IGNORED;
    }
    if (att == CMA_HEAD || att == CMA_BACK)
    {
        new Float:o[3], Float:pa[3], Float:a[3];
        CmTarget(id, c, i, o);
        get_entvar(id, var_angles, pa);
        a[0] = g_fCmAng[c][i][0];
        a[1] = pa[1] + g_fCmAng[c][i][1];
        a[2] = g_fCmAng[c][i][2];
        set_es(es, ES_Origin, o);
        set_es(es, ES_Angles, a);
    }
    return FMRES_IGNORED;
}

/* ---------------- Kanat / pet / sapka menusu ---------------- */

ShowCmList(id, c)
{
    new title[320], item[128], nm[32], hsub[64];
    formatex(hsub, charsmax(hsub), "%L", id, "COS_SUB");
    VexHead(id, title, charsmax(title), CM_CATKEY[c], hsub);
    new menu = VexMenuCreate(title, "menu_cmlist_handler");

    new sel = CmSel(id, c);
    formatex(item, charsmax(item), sel == 0 ? "\y%L \r[\y*\r]" : "\y%L", id, "COS_NONE");
    MenuAdd(menu, item, c * 100);

    for (new i = 0; i < CM_MAX; i++)
    {
        if (!g_bCmOk[c][i])
            continue;   // dosyasi olmayan satir gizli
        CmName(id, c, i, nm, charsmax(nm));
        new vt[16];
        if (g_iCmVip[c][i])
            copy(vt, charsmax(vt), " \r[\yVIP\r]");
        if (sel == i + 1)
            formatex(item, charsmax(item), "\y%s%s \r[\y%L\r]", nm, vt, id, "COS_EQUIPPED");
        else if (g_iCmOwned[id] & (1 << (c * 8 + i)))
            formatex(item, charsmax(item), "\y%s%s \r[%L]", nm, vt, id, "COS_OWNED");
        else if (CmDealIdx() == c * 16 + i)
            formatex(item, charsmax(item), "\y%s%s \r[%d VC] \y-%d%%", nm, vt, CmPrice(id, c, i), CmDealPct());
        else
            formatex(item, charsmax(item), "\y%s%s \r[%d VC]", nm, vt, CmPrice(id, c, i));
        MenuAdd(menu, item, c * 100 + i + 1);
    }
    MenuFinish(id, menu);
}

public menu_cmlist_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new v = MenuInfo(menu, item);
    menu_destroy(menu);
    if (!is_user_connected(id))
        return PLUGIN_HANDLED;

    new c = v / 100, idx = v % 100;
    if (c < 0 || c >= CM_CATS)
        return PLUGIN_HANDLED;
    if (idx == 0)
    {
        CmSetSel(id, c, 0);
        Chat(id, "COS_OFF");
        SaveData(id);
        ShowCmList(id, c);
        return PLUGIN_HANDLED;
    }
    new i = idx - 1, nm[32];
    if (i >= CM_MAX || !g_bCmOk[c][i])
        return PLUGIN_HANDLED;
    CmName(id, c, i, nm, charsmax(nm));
    if (g_iCmVip[c][i] && !IsVip(id))
    {
        Chat(id, "VIP_ONLY");
        ShowCmList(id, c);
        return PLUGIN_HANDLED;
    }
    new bit = 1 << (c * 8 + i);
    if (!(g_iCmOwned[id] & bit))
    {
        // v3.5: satin almadan once onay + vitrin (yanlislikla VC harcanmaz)
        ShowCmBuy(id, c, i);
        return PLUGIN_HANDLED;
    }
    CmSetSel(id, c, i + 1);
    Chat(id, "COS_EQUIP", nm);
    SaveData(id);
    ShowCmList(id, c);
    return PLUGIN_HANDLED;
}

// v3.5 satin alma onayi: Satin al / Vitrinde gor / Geri
ShowCmBuy(id, c, i)
{
    new title[320], item[128], nm[32], hsub[96];
    CmName(id, c, i, nm, charsmax(nm));
    formatex(hsub, charsmax(hsub), "%s - %d VC (%L: %d VC)", nm, CmPrice(id, c, i), id, "COS_YOUR_VC", g_iVC[id]);
    VexHead(id, title, charsmax(title), CM_CATKEY[c], hsub);
    new menu = VexMenuCreate(title, "menu_cmbuy_handler");
    new base = c * 100 + i;
    formatex(item, charsmax(item), "\y%L \r[%d VC]", id, "COS_BUY_ITEM", CmPrice(id, c, i));
    MenuAdd(menu, item, 10000 + base);
    if (get_pcvar_num(g_pCosPreview) > 0)
    {
        formatex(item, charsmax(item), "\y%L \r[%d %L]", id, "COS_PREV_ITEM", clamp(get_pcvar_num(g_pCosPreview), 3, 30), id, "COS_SEC");
        MenuAdd(menu, item, 20000 + base);
    }
    formatex(item, charsmax(item), "\y%L", id, "COS_BACK");
    MenuAdd(menu, item, 30000 + base);
    MenuFinish(id, menu);
}

public menu_cmbuy_handler(id, menu, item)
{
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new v = MenuInfo(menu, item);
    menu_destroy(menu);
    if (!is_user_connected(id))
        return PLUGIN_HANDLED;
    new act = v / 10000, c = (v % 10000) / 100, i = v % 100;
    if (c < 0 || c >= CM_CATS || i < 0 || i >= CM_MAX || !g_bCmOk[c][i])
        return PLUGIN_HANDLED;
    if (act == 2)
    {
        CmPreview(id, c, i);
        ShowCmBuy(id, c, i);
        return PLUGIN_HANDLED;
    }
    if (act != 1)
    {
        ShowCmList(id, c);
        return PLUGIN_HANDLED;
    }
    new nm[32], bit = 1 << (c * 8 + i);
    CmName(id, c, i, nm, charsmax(nm));
    if (g_iCmVip[c][i] && !IsVip(id))
    {
        Chat(id, "VIP_ONLY");
        ShowCmList(id, c);
        return PLUGIN_HANDLED;
    }
    if (!(g_iCmOwned[id] & bit))
    {
        new price = CmPrice(id, c, i);
        if (g_iVC[id] < price)
        {
            Chat(id, "COS_NOVC", price);
            ShowCmList(id, c);
            return PLUGIN_HANDLED;
        }
        g_iVC[id] -= price;
        g_iCmOwned[id] |= bit;
        PlayKey(id, "SHOP_BUY");
        Chat(id, "COS_BOUGHT", nm, price);
    }
    CmPrevRemove(id);
    CmSetSel(id, c, i + 1);
    Chat(id, "COS_EQUIP", nm);
    SaveData(id);
    ShowCmList(id, c);
    return PLUGIN_HANDLED;
}

// Test / yonetici: vex_cos_give <#id|bot> <wing|pet|hat> <no> -> sahip yap + tak (VC harcamaz)
public srv_CosGive()
{
    new who[16], cat[8], no[8];
    read_argv(1, who, charsmax(who));
    read_argv(2, cat, charsmax(cat));
    read_argv(3, no, charsmax(no));
    new id = (who[0] == '#') ? str_to_num(who[1]) : 0;
    if (!id)
        for (new p = 1; p <= g_iMax; p++)
            if (is_user_connected(p) && is_user_alive(p) && !g_bZombie[p]) { id = p; break; }
    new c = equali(cat, "wing") ? 0 : (equali(cat, "pet") ? 1 : (equali(cat, "hat") ? 2 : -1));
    new i = str_to_num(no) - 1;
    if (!(1 <= id <= g_iMax) || !is_user_connected(id) || c < 0 || i < 0 || i >= CM_MAX || !g_bCmOk[c][i])
    {
        server_print("[Vexmira] vex_cos_give: gecersiz (oyuncu / kategori / no / dosya)");
        return PLUGIN_HANDLED;
    }
    g_iCmOwned[id] |= 1 << (c * 8 + i);
    CmSetSel(id, c, i + 1);
    server_print("[Vexmira] vex_cos_give #%d %s %d", id, CM_TABLE[c], i + 1);
    return PLUGIN_HANDLED;
}

// Test: vex_cos_dump -> kozmetik varliklarinin konumu (hizalama kontrolu)
public srv_CosDump()
{
    for (new id = 1; id <= g_iMax; id++)
    {
        for (new c = 0; c < CM_CATS; c++)
        {
            new ent = g_iCmEnt[id][c];
            if (!ent || !CmValid(ent, id))
                continue;
            new Float:o[3], Float:po[3];
            get_entvar(ent, var_origin, o);
            get_entvar(id, var_origin, po);
            server_print("[Vexmira] cos #%d %s ent=%d mt=%d aim=%d d=(%.0f %.0f %.0f) alive=%d z=%d", id, CM_TABLE[c], ent,
                get_entvar(ent, var_movetype), get_entvar(ent, var_aiment), o[0] - po[0], o[1] - po[1], o[2] - po[2],
                is_user_alive(id), g_bZombie[id]);
        }
    }
    new n, e = -1;
    while ((e = engfunc(EngFunc_FindEntityByString, e, "classname", "vex_cosmodel")) > 0)
        n++;
    server_print("[Vexmira] cos ents total=%d", n);
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

/* ===== End module: economy.inc ===== */
/* ================================================================== */
/*  BOLUM 7/13: SILAHLAR                                              */
/*  Silah dagitimi (birincil / ikincil menu), ozel silahlar (deploy   */
/*  / atis), ozel bombalar ve bomba modlari, lazer mayinlari, hava    */
/*  ikmali, isaret fisegi, firlatilan bomba modelleri.                */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
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

// v3.2: atilan ozel silahin biti temizlenir (yerden alinan sade silah ozel sayilmaz)
public rg_DropPlayerItemPost(id, const pszItemName[])
{
    if (!(1 <= id <= g_iMax) || !g_iSpecW[id] || !is_user_connected(id))
        return HC_CONTINUE;
    for (new s = 0; s < NUM_SPECIAL; s++)
    {
        if ((g_iSpecW[id] & (1 << s)) && !rg_has_item_by_name(id, SW_BASE_ENT[s]))
            g_iSpecW[id] &= ~(1 << s);
    }
    return HC_CONTINUE;
}

// Survivor = 0, Sniper = 1, digerleri -1
ModeOf(id)
{
    if (g_bSurvivor[id]) return 0;
    if (g_bSniper[id]) return 1;
    return -1;
}

// Bu modun hangi yuvasi bu silah (yoksa -1)
ModeSlot(mm, WeaponIdType:wid)
{
    for (new s = 0; s < MW_SLOTS; s++)
    {
        if (MW_ENT[mm][s][0] && MW_ID[mm][s] == wid)
            return s;
    }
    return -1;
}

// Survivor / Sniper mod silahlarini ver (vex_modewpn)
GiveModeWeapons(id, mm)
{
    for (new s = 0; s < MW_SLOTS; s++)
    {
        if (!MW_ENT[mm][s][0])
            continue;
        new ent = rg_give_item(id, MW_ENT[mm][s], GT_REPLACE);
        if (!is_nullent(ent) && MW_CLIP[mm][s] > 0)
        {
            rg_set_iteminfo(ent, ItemInfo_iMaxClip, MW_CLIP[mm][s]);
            set_member(ent, m_Weapon_iClip, MW_CLIP[mm][s]);
        }
        if (MW_BP[mm][s] > 0)
            rg_set_user_bpammo(id, MW_ID[mm][s], MW_BP[mm][s]);
    }
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

ChainLightning(victim, attacker, Float:chainDamage)
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
        ExecuteHamB(Ham_TakeDamage, p, attacker, attacker, chainDamage, DMG_SHOCK);
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

    // Mode loadouts may use dedicated cfg models; empty entries inherit the normal weapon model.
    new mm = ModeOf(id), ms = (mm >= 0) ? ModeSlot(mm, wid) : -1;
    if (ms >= 0)
    {
        new w = _:wid;
        if (g_szMwV[mm][ms][0]) SetHookChainArg(2, ATYPE_STRING, g_szMwV[mm][ms]);
        else if (g_szWepV[w][0]) SetHookChainArg(2, ATYPE_STRING, g_szWepV[w]);
        if (g_szMwP[mm][ms][0]) SetHookChainArg(3, ATYPE_STRING, g_szMwP[mm][ms]);
        else if (g_szWepP[w][0]) SetHookChainArg(3, ATYPE_STRING, g_szWepP[w]);
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
    // v3.2: VIP'e ozel bicak kaplamasi (vex_res VIP_V_KNIFE / VIP_P_KNIFE; dosya yoksa kapali)
    if (w == CSW_KNIFE && IsVip(id) && g_szVipKnifeV[0])
    {
        SetHookChainArg(2, ATYPE_STRING, g_szVipKnifeV);
        if (g_szVipKnifeP[0])
            SetHookChainArg(3, ATYPE_STRING, g_szVipKnifeP);
        return HC_CONTINUE;
    }
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

    new mm = ModeOf(id), ms = (mm >= 0) ? ModeSlot(mm, wid) : -1;
    if (ms >= 0)
    {
        // vex_res <MOD>_W<yuva>_SOUND: ek atis sesi (istemcinin kendi atis sesi sunucudan susturulamaz)
        new key[24];
        formatex(key, charsmax(key), "%s_W%d_SOUND", MW_KEY[mm], ms + 1);
        EmitKey(id, key, CHAN_WEAPON);
        return HAM_IGNORED;
    }

    new sw = SpecialIndex(id, wid);
    if (sw < 0)
        return HAM_IGNORED;

    // v3.2 FIX: ReGameDLL'de m_flNextPrimaryAttack GORECELI zamandir (UTIL_WeaponTimeBase = 0).
    // Eskiden get_gametime()+oran yaziliyordu -> silah dakikalarca ates edemiyor, istemci
    // tahmini bozulup diger silahlar da kilitleniyordu. Simdi sadece goreceli oran uygulanir.
    new Float:attackReady = Float:get_member(weapon, m_Weapon_flNextPrimaryAttack);
    new Float:minReady = floatclamp(SW_RATE[sw], 0.05, 5.0);
    if (attackReady < minReady)
        set_member(weapon, m_Weapon_flNextPrimaryAttack, minReady);
    if (Float:get_member(weapon, m_Weapon_flTimeWeaponIdle) < minReady)
        set_member(weapon, m_Weapon_flTimeWeaponIdle, minReady);
    if (SW_RECOIL[sw] != 1.0)
    {
        new Float:punch[3];
        get_entvar(id, var_punchangle, punch);
        punch[0] *= SW_RECOIL[sw];
        punch[1] *= SW_RECOIL[sw];
        punch[2] *= SW_RECOIL[sw];
        set_entvar(id, var_punchangle, punch);
    }

    // Hizli silahlarda her atista iz cizme (performans)
    if ((sw % 8 == 1 || sw % 8 == 5) && (g_iFrame + id) % 2)
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
    new bool:lightning = (SW_EFFECT[sw] == SWE_LIGHTNING);
    FxBeam(start, end, lightning ? g_sprLightning : g_sprBeam, SW_RGB[sw][0], SW_RGB[sw][1], SW_RGB[sw][2], lightning ? 40 : 12);
    FxLight(end, SW_RGB[sw][0], SW_RGB[sw][1], SW_RGB[sw][2], 8, 3, 30);

    EmitSpecialFire(id, sw);

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
    new title[320], item[64];

    new hsub[128];
    formatex(hsub, charsmax(hsub), "%L", id, "MENU_GUNS_SUB");
    VexHead(id, title, charsmax(title), "MENU_PRIMARY", hsub);
    new menu = VexMenuCreate(title, "menu_primary_handler");

    // v3.2: otomatik silah ac/kapa + durumu [ACIK]/[KAPALI]
    new st[32];
    VexOnOff(id, (g_iSet[id] & SET_NO_AUTOGUN) ? false : true, st, charsmax(st));
    formatex(item, charsmax(item), "\y%L %s", id, "SET_6", st);
    MenuAdd(menu, item, 900);
    menu_addblank(menu, 0);

    for (new i = 0; i < sizeof PRIM_NAME; i++)
    {
        if (g_iLevel[id] >= PRIM_LVL[i])
            formatex(item, charsmax(item), "\y%s", PRIM_NAME[i]);
        else
            formatex(item, charsmax(item), "\y%s \r[Lv.%d] \r[%L]", PRIM_NAME[i], PRIM_LVL[i], id, "MENU_LOCKED");
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

    if (sel == 900)
    {
        g_iSet[id] ^= SET_NO_AUTOGUN;
        SaveData(id);
        ShowPrimaryMenu(id);
        return PLUGIN_HANDLED;
    }
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
    new title[320], item[64];

    VexHead(id, title, charsmax(title), "MENU_SECONDARY");
    new menu = VexMenuCreate(title, "menu_secondary_handler");

    for (new i = 0; i < sizeof SEC_NAME; i++)
    {
        if (g_iLevel[id] >= SEC_LVL[i])
            formatex(item, charsmax(item), "\y%s", SEC_NAME[i]);
        else
            formatex(item, charsmax(item), "\y%s \r[Lv.%d] \r[%L]", SEC_NAME[i], SEC_LVL[i], id, "MENU_LOCKED");
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
    // v3.2: VIP her hayatta 1 kez ucretsiz silah degistirebilir (vex_vip_regun)
    new bool:regun = false;
    if (g_bRoundActive && g_bGunsGiven[id])
    {
        if (IsVip(id) && get_pcvar_num(g_pVipRegun) && !g_bVipRegun[id])
        {
            g_bVipRegun[id] = true;
            regun = true;
            Chat(id, "VIP_REGUN");
        }
        else
        {
            Chat(id, "GUNS_ONCE");
            return;
        }
    }

    // Round icinde bedava mermi suistimalini engelle: ana silahi varsa verme
    if (g_bRoundActive && !regun)
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
// v3.2: ozel silah testi - 16 slotun her birini canli bir insana verir, bir atis yaptirir
// ve klip / yedek / sonraki atis (goreceli) degerlerini loglar.
public srv_DbgSwTest()
{
    if (!get_pcvar_num(g_pDbgDirs))
        return PLUGIN_HANDLED;
    new id;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_alive(p) && !g_bZombie[p] && !g_bSurvivor[p] && !g_bSniper[p]) { id = p; break; }
    }
    if (!id)
    {
        log_amx("[Vexmira] SWTEST no living human");
        return PLUGIN_HANDLED;
    }
    new bad;
    for (new i = 0; i < NUM_SPECIAL; i++)
    {
        g_iSpecW[id] = (1 << i);
        new weapon = rg_give_item(id, SW_BASE_ENT[i], GT_REPLACE);
        if (is_nullent(weapon)) { log_amx("[Vexmira] SWTEST slot=%d give FAILED", i); bad++; continue; }
        set_member(weapon, m_Weapon_iClip, SW_CLIP[i]);
        rg_set_user_bpammo(id, SW_BASE_ID[i], SW_BPAMMO[i]);
        set_member(weapon, m_Weapon_flNextPrimaryAttack, 0.0);
        ExecuteHamB(Ham_Weapon_PrimaryAttack, weapon);
        new Float:na = Float:get_member(weapon, m_Weapon_flNextPrimaryAttack);
        new clip = get_member(weapon, m_Weapon_iClip), bp = rg_get_user_bpammo(id, SW_BASE_ID[i]);
        new si = SpecialIndex(id, SW_BASE_ID[i]);
        new bool:ok = (si == i && clip >= 0 && clip <= SW_CLIP[i] && bp > 0 && na >= 0.0 && na <= 5.0);
        if (!ok) bad++;
        log_amx("[Vexmira] SWTEST slot=%d ent=%s idx=%d clip=%d/%d bp=%d next=%.2f %s", i, SW_BASE_ENT[i], si, clip, SW_CLIP[i], bp, na, ok ? "OK" : "BAD");
    }
    g_iSpecW[id] = 0;
    log_amx("[Vexmira] SWTEST done player=%d bad=%d", id, bad);
    return PLUGIN_HANDLED;
}

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
    g_iLmTakeEnt[id] = 0;
    remove_task(id + TASK_PLANT);
    remove_task(id + TASK_LMTAKE);
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

    new Float:pos[3], Float:normal[3], Float:hitDistance;
    if (!FindPlantSpot(id, pos, normal, hitDistance))
    {
        if (hitDistance > 0.0)
            LmMessage(id, "LM_TOO_FAR", floatround(floatclamp(get_pcvar_float(g_pLmRange), 48.0, 256.0)));
        else
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

    // v3.2: sokme ANINDA degil - vex_lm_take_time sn ilerleme cubugu (varsayilan 2.0).
    // Uzaklasma (>96), nisani kacirma, olum, hasar alma veya round sonu iptal eder.
    new Float:t = get_pcvar_float(g_pLmTakeTime);
    if (t <= 0.05)
    {
        task_PlantDone(id + TASK_PLANT);
        return PLUGIN_HANDLED;
    }
    g_iLmTakeEnt[id] = mine;
    rg_send_bartime(id, floatround(t, floatround_ceil), false);
    set_task(t, "task_PlantDone", id + TASK_PLANT);
    set_task(0.1, "task_LmTakeCheck", id + TASK_LMTAKE, _, _, "b");
    Chat(id, "LM_TAKING", floatround(t, floatround_ceil));
    return PLUGIN_HANDLED;
}

// v3.2: sokme surerken her 0.1 sn kosullar denetlenir
public task_LmTakeCheck(tid)
{
    new id = tid - TASK_LMTAKE;
    if (g_iPlantAction[id] != 2)
    {
        remove_task(tid);
        return;
    }
    new mine = g_iLmTakeEnt[id];
    if (!is_user_alive(id) || g_bZombie[id] || !mine || is_nullent(mine))
    {
        LmTakeCancel(id, "LM_TAKE_CANCEL");
        return;
    }
    new Float:o[3];
    get_entvar(id, var_origin, o);
    if (get_distance_f(o, g_fPlantPos[id]) > 96.0)
    {
        LmTakeCancel(id, "LM_MOVED");
        return;
    }
    if (AimedMine(id, get_pcvar_float(g_pLmTakeRange) + 10.0) != mine)
        LmTakeCancel(id, "LM_TAKE_AIM");
}

LmTakeCancel(id, const key[] = "")
{
    if (g_iPlantAction[id] != 2)
        return;
    CancelPlant(id);
    if (key[0] && is_user_connected(id))
        Chat(id, key);
}

public task_PlantDone(tid)
{
    new id = tid - TASK_PLANT;
    new action = g_iPlantAction[id];
    g_iPlantAction[id] = 0;

    if (!is_user_alive(id) || g_bZombie[id] || !action)
        return;

    new takeEnt = g_iLmTakeEnt[id];
    g_iLmTakeEnt[id] = 0;
    remove_task(id + TASK_LMTAKE);

    // Islem sirasinda yer degistirdiyse iptal
    new Float:o[3];
    get_entvar(id, var_origin, o);
    if (get_distance_f(o, g_fPlantPos[id]) > (action == 2 ? 96.0 : 48.0))
    {
        Chat(id, "LM_MOVED");
        return;
    }

    if (action == 1)
    {
        if (!LasersAllowed() || g_iMines[id] <= 0 || CountMines(id) >= MaxMines(id))
            return;

        new Float:pos[3], Float:normal[3], Float:hitDistance;
        if (!FindPlantSpot(id, pos, normal, hitDistance))
        {
            if (hitDistance > 0.0)
                Chat(id, "LM_TOO_FAR", floatround(floatclamp(get_pcvar_float(g_pLmRange), 48.0, 256.0)));
            else
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
        if (!mine || (takeEnt && mine != takeEnt))
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
bool:FindPlantSpot(id, Float:pos[3], Float:normal[3], &Float:hitDistance)
{
    hitDistance = 0.0;
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
    // Aim farther than the allowed install distance only to return a useful warning.
    // The mine itself is still rejected whenever the hit lies past `range`.
    new Float:traceRange = floatmax(range, 8192.0), Float:endDist;
    end[0] = start[0] + fwd[0] * traceRange;
    end[1] = start[1] + fwd[1] * traceRange;
    end[2] = start[2] + fwd[2] * traceRange;

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

    endDist = get_distance_f(start, pos);
    if (endDist > range + 1.0)
    {
        hitDistance = endDist;
        return false;
    }

    // Hareketli kapi / asansor uzerine kurulmaz
    if (hit > 0)
    {
        new cls[32];
        get_entvar(hit, var_classname, cls, charsmax(cls));
        if (!equal(cls, "func_wall") && !equal(cls, "func_illusionary"))
            return false;
    }

    // pos yuzeyde kalir; modele gore ofset CreateMine'da (MineOrient) uygulanir
    hitDistance = endDist;
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
    }
}

ShowMineMenu(id)
{
    new title[320], item[96];
    new hsub[128];
    formatex(hsub, charsmax(hsub), "%L", id, "LM_MENU_SUB", g_iMines[id], CountMines(id), MaxMines(id));
    VexHead(id, title, charsmax(title), "LM_MENU", hsub);
    new menu = VexMenuCreate(title, "menu_mine_handler");

    new bool:ok = LasersAllowed();
    formatex(item, charsmax(item), ok ? "\y%L" : "\y%L \r[%L]", id, "LM_M_PLANT", id, "MENU_LOCKED"); MenuAdd(menu, item, 1);
    formatex(item, charsmax(item), "\y%L", id, "LM_M_TAKE"); MenuAdd(menu, item, 2);
    formatex(item, charsmax(item), "\y%L", id, "LM_M_INFO"); MenuAdd(menu, item, 3);
    formatex(item, charsmax(item), "\y%L", id, "LM_M_BIND"); MenuAdd(menu, item, 4);

    if (!ok)
    {
        formatex(item, charsmax(item), "\r%L", id, (g_iMode == MODE_BOSS && !get_pcvar_num(g_pLmBoss)) ? "LM_NO_BOSS_SHORT" : (get_pcvar_num(g_pLmEnable) && LmModeBlocked(g_iMode)) ? "LM_NO_MODE_SHORT" : "LM_DISABLED_SHORT");
        VexAddText(menu, item, 0);
    }
    else
    {
        formatex(item, charsmax(item), "\d%L", id, "LM_M_RULE", RoundMines(id));
        VexAddText(menu, item, 0);
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
    new title[320], item[128], key[16], nm[32];
    new hsub[128];
    formatex(hsub, charsmax(hsub), "%L", id, "NMENU_SUB");
    VexHead(id, title, charsmax(title), "NMENU_TITLE", hsub);
    new menu = VexMenuCreate(title, "menu_nade_handler");

    static const SLOTKEY[3][] = { "NMENU_HE", "NMENU_FROST", "NMENU_FLARE" };
    for (new s = 0; s < 3; s++)
    {
        formatex(key, charsmax(key), "NMODE_%d", g_iNadeMode[id][s]);
        formatex(nm, charsmax(nm), "%L", id, key);
        formatex(item, charsmax(item), "\y%L \r[%s\r]", id, SLOTKEY[s], nm);
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

/* ===== End module: weapons.inc ===== */
/* ================================================================== */
/*  BOLUM 8/13: ZOMBILER                                              */
/*  Zombi / insan donusumleri, enfeksiyon, sinif menusu, [R] / [F]    */
/*  yetenekleri (0-11 eski, 12-23 v3 siniflari), Nemesis / Assassin   */
/*  yetenekleri, bot yetenek kullanimi, evrim.                        */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
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
        hp = float(get_pcvar_num(g_pNemHP) + get_pcvar_num(g_pNemHPPer) * CountPlaying());
        if (g_iMode == MODE_ARMAGEDDON)
            hp *= 0.5;
        grav = get_pcvar_float(g_pNemGrav);
        copy(model, charsmax(model), g_szNemModel);
    }
    else if (g_bAssassin[id])
    {
        hp = float(get_pcvar_num(g_pAsnHP) + get_pcvar_num(g_pAsnHPPer) * CountPlaying());
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
        hp = float(get_pcvar_num(g_bFirst[id] ? g_pFirstHP : g_pZombieHP) + max(0, get_pcvar_num(g_pZHPPer)) * CountPlaying()) * CLASS_HP[cls];
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
    g_iSpecW[id] = 0; // Loadout weapons are mode-owned, not retained shop weapon modifiers.
    if (sniper)
        g_bSniper[id] = 1;
    else
        g_bSurvivor[id] = 1;

    rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED, true, false);
    rg_remove_all_items(id);
    rg_give_item(id, "weapon_knife");

    if (sniper)
    {
        GiveModeWeapons(id, 1);
        g_iMaxHP[id] = get_pcvar_num(g_pSnipHP);
        if (g_szSnipModel[0]) rg_set_user_model(id, g_szSnipModel);
    }
    else
    {
        GiveModeWeapons(id, 0);
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
    CsoNotify(victim, CN_INFD);
    Chat(attacker, "YOU_INFECTOR", vname);

    if (!g_bFirstInfect)
    {
        g_bFirstInfect = true;
        LiveAll(victim, "LIVE_FIRSTINF", 3, vname);
    }

    for (new p = 1; p <= g_iMax && get_pcvar_num(g_pChatBcast); p++)
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
    new title[320], item[160], k1[16], k2[20], n1[32], n2[72];

    new hsub[128];
    formatex(hsub, charsmax(hsub), "%L", id, "MENU_CLASS_SUB");
    VexHead(id, title, charsmax(title), "MENU_CLASS", hsub);
    new menu = VexMenuCreate(title, "menu_class_handler");

    for (new i = 0; i < NUM_CLASSES; i++)
    {
        formatex(k1, charsmax(k1), "CLASS_%d", i);
        formatex(k2, charsmax(k2), "CLASS_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        if (g_iLevel[id] < CLASS_LVL[i])
            formatex(item, charsmax(item), "\y%s \r[Lv.%d] \r[%L]", n1, CLASS_LVL[i], id, "MENU_LOCKED");
        else if (g_iClass[id] == i)
            formatex(item, charsmax(item), "\y%s \r[*\r] \d%s", n1, n2);
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

/* ===== End module: zombies.inc ===== */
/* ================================================================== */
/*  BOLUM 9/13: BOSSLAR                                               */
/*  Boss baslatma / faz / olum, pasif yetenekler, fazli [R]           */
/*  yetenekleri (27), boss mermileri / yumurtalar, boss / Nemesis /   */
/*  Assassin sesleri.                                                 */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
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
    MsEvent(ME_BOSS);
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
        new victim = alive[pick];
        alive[pick] = alive[n - 1];
        n--;
        // v3.2: carpma noktasi asla oyuncunun ustu degil - onunde/yaninda 96-220 birim
        if (!MeteorSpot(victim, o))
            continue;

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
    MsEvent(ME_BOSS_DEAD);
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
    CsoHudAll(CN_BKILL, 0, SL_ANN, CLR_GOOD, 4.0, "BOSS_DOWN_HUD");
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

/* ===== End module: bosses.inc ===== */
/* ================================================================== */
/*  BOLUM 10/13: MODLAR                                               */
/*  Round akisi (ReAPI round hook'lari, kazanma kosulu), 1 sn tick,   */
/*  mod secimi ve baslatma, event'ler (meteor, firtina, simsek),      */
/*  mod / event oylamasi, round plani.                                */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  INIT                                                               */
/* ================================================================== */

// Round suresi dolunca oyun kendi bitirmesin (CheckWin bitirir); cfg unutulsa bile
public task_EnforceRoundInfinite()
{
    new v[32];
    get_cvar_string("mp_round_infinite", v, charsmax(v));
    if (!equal(v, "1") && contain(v, "a") == -1)
        set_cvar_string("mp_round_infinite", "abcdefghijk");
}


/* ================================================================== */
/*  ROUND AKISI (ReAPI)                                                */
/* ================================================================== */

// Oyunun kendi kazanma kontrolunu tamamen kapat: round'u plugin bitirir.
public rg_CheckWinConditions()
{
    return HC_SUPERCEDE;
}

// Bomba verilmesin
public rg_MakeBomber(id)
{
    SetHookChainReturn(ATYPE_BOOL, false);
    return HC_SUPERCEDE;
}

public rg_RestartRound()
{
    // v3.3: harita senaryosu (vex_round_start harita geri yuklendikten sonra tetiklenir)
    MsRoundRestart();
    // v3.2 (B): CSO ekran bildirimi: aktif gorseller kalkar, kuyruk bosalir
    CsoFlushAll();
    // Onceki roundun sesleri (kalp atisi, muzik, yanma, ruzgar...) tamamen susar.
    // "stopsound" haritanin dongulu ortam seslerini de susturur: kisa sure sonra yeniden baslar.
    if (get_pcvar_num(g_pRoundStopSnd))
    {
        StopAllClientSounds();
        remove_task(TASK_AMBREST);
        set_task(0.8, "task_AmbientRestore", TASK_AMBREST);
    }

    remove_task(TASK_ANNOUNCE);
    remove_task(TASK_BOSSCAST);
    remove_task(TASK_BOSSHIT);
    g_iMapVoteWait = 0;
    remove_task(TASK_BOSSFX);
    remove_task(TASK_INTRO);
    g_iBossPhase = 0;

    g_bRoundActive = false;
    g_bRoundEnded = false;
    g_bCounting = false;
    g_bWaiting = false;
    g_bEnraged = false;
    g_bLastAnn = false;
    g_bFirstInfect = false;
    g_bFirstBlood = false;
    g_iBoss = 0;
    g_iBossTick = 0;
    g_iMeteorTick = 0;
    g_iGlobalInfBombs = 0;
    g_iAirdropClock = 0;
    g_fEclipseEnd = 0.0;
    g_fBlizzardEnd = 0.0;
    for (new i = 0; i < sizeof g_fPoolEnd; i++)
        g_fPoolEnd[i] = 0.0;

    for (new f = 0; f < MAX_FLARES; f++)
        g_fFlareEnd[f] = 0.0;

    RemoveAllMines();
    RemoveAllDrops();
    BossCleanup();
    ZcCleanupAll();
    OvhRemoveAll();
    g_fSndKill = 0.0;
    TrieClear(g_tRoundBuys);
    g_iStartTries = 0;
    g_bAnnounced = false;
    remove_task(TASK_INTRO + 1);
    for (new t = 0; t < 30; t++)
        remove_task(TASK_BOSSHIT + t);

    for (new id = 1; id <= g_iMax; id++)
    {
        g_bZombie[id] = 0; g_bNemesis[id] = 0; g_bAssassin[id] = 0; g_bSurvivor[id] = 0; g_bSniper[id] = 0;
        g_bBoss[id] = 0; g_bMinion[id] = 0; g_bFirst[id] = 0; g_bForceZombie[id] = 0;
        g_fRespawnAt[id] = 0.0;
        g_bLmGiven[id] = false;
        ResetRoundData(id);
        ResetLifeData(id);
    }

    // Round numarasi oyunun kendi sayaci ile ayni (mp_maxrounds ile uyumlu)
    if (get_member_game(m_bCompleteReset))
        g_iRound = 1;
    else
        g_iRound = get_member_game(m_iTotalRoundsPlayed) + 2;

    // mp_maxrounds kapaliysa plan basa doner; aciksa son roundan sonra harita degisir
    new total = RoundsTotal();
    if (g_iRound > total)
    {
        if (get_cvar_num("mp_maxrounds") > 0)
        {
            g_iMode = MODE_INFECTION;
            g_iEvent = EV_NONE;
            ApplyWorldEvent();
            return;
        }
        g_iRound = ((g_iRound - 1) % total) + 1;
    }

    PickMode();
    PickCalmPreset();
    ApplyWorldEvent();
    ApplyHostname();

    set_task(1.2, "task_Announce", TASK_ANNOUNCE);
}

RoundsTotal()
{
    new m = get_cvar_num("mp_maxrounds");
    return (m > 0) ? m : max(1, get_pcvar_num(g_pRoundsTotal));
}

// "7 15 23 30" gibi listede bu round var mi?
bool:RoundInList(pcvar, round)
{
    new list[128], tmp[8], pos;
    get_pcvar_string(pcvar, list, charsmax(list));
    while ((pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
    {
        if (str_to_num(tmp) == round)
            return true;
    }
    return false;
}

bool:IsBossRound(round)
{
    new list[128];
    get_pcvar_string(g_pBossRounds, list, charsmax(list));
    trim(list);
    if (list[0])
        return RoundInList(g_pBossRounds, round);

    new every = max(1, get_pcvar_num(g_pBossEvery));
    return (round > 1 && round % every == 0) ? true : false;
}

// Siradaki boss roundu kac round sonra? (0 = yok)
RoundsToBoss()
{
    new total = RoundsTotal();
    for (new r = g_iRound + 1; r <= total; r++)
    {
        if (IsBossRound(r))
            return r - g_iRound;
    }
    return 0;
}

// Bosslar karisik sirayla gelir, ayni boss arka arkaya gelmez.
// v3.0: torbada sadece bu haritada YUKLENEN bosslar var (precache butcesi).
ShuffleBosses()
{
    new n = BossBagSize();
    new last = (g_iBossBagPos > 0 && g_iBossBagPos <= n) ? g_iBossBag[n - 1] : -1;
    for (new i = 0; i < n; i++)
        g_iBossBag[i] = g_iBossLoadN > 0 ? g_iBossLoadList[i] : i;
    for (new i = n - 1; i > 0; i--)
    {
        new j = random(i + 1), t = g_iBossBag[i];
        g_iBossBag[i] = g_iBossBag[j];
        g_iBossBag[j] = t;
    }
    if (n > 1 && g_iBossBag[0] == last)
    {
        new t = g_iBossBag[0];
        g_iBossBag[0] = g_iBossBag[n - 1];
        g_iBossBag[n - 1] = t;
    }
    g_iBossBagPos = 0;
}

BossBagSize()
{
    return g_iBossLoadN > 0 ? g_iBossLoadN : NUM_BOSSES;
}

NextBoss()
{
    if (g_iBossBagPos >= BossBagSize())
        ShuffleBosses();
    return g_iBossBag[clamp(g_iBossBagPos++, 0, NUM_BOSSES - 1)];
}

PickSpecialMode(players)
{
    new total, w[MODE_TOTAL];
    for (new m = MODE_NEMESIS; m < MODE_BOSS; m++)
    {
        if (m == g_iLastSpecial || players < MODE_MINPL[m])
            continue;
        w[m] = max(1, MODE_CHANCE[m]);
        total += w[m];
    }
    if (!total)
        return MODE_INFECTION;

    new roll = random_num(1, total), acc;
    for (new m = MODE_NEMESIS; m < MODE_BOSS; m++)
    {
        acc += w[m];
        if (w[m] && roll <= acc)
            return m;
    }
    return MODE_INFECTION;
}

PickMode()
{
    new players = CountPlaying();
    g_iMode = MODE_INFECTION;
    g_bFinalBoss = false;

    if (g_iForceMode >= 0)
    {
        g_iMode = g_iForceMode;
        g_iForceMode = -1;
    }
    else if (IsBossRound(g_iRound) && players >= MODE_MINPL[MODE_BOSS])
        g_iMode = MODE_BOSS;
    else if (RoundInList(g_pSpecialRounds, g_iRound))
        g_iMode = PickSpecialMode(players);
    else if (g_iRound >= 3 && random_num(1, 100) <= get_pcvar_num(g_pMultiChance))
        g_iMode = MODE_MULTI;

    if (g_iMode == MODE_BOSS)
    {
        g_bFinalBoss = (g_iRound >= RoundsTotal()) ? true : false;
        if (g_iForceBoss >= 0 && g_iForceBoss < NUM_BOSSES && BossIsLoaded(g_iForceBoss))
        {
            g_iBossType = g_iForceBoss;
            g_iForceBoss = -1;
        }
        else
            g_iBossType = NextBoss();
    }
    else if (g_iMode >= MODE_NEMESIS)
        g_iLastSpecial = g_iMode;


    // Event'ler sadece normal (infection / multi) roundlarda; ilk round sakin
    new last = g_iEvent;
    if (g_iMode != MODE_INFECTION && g_iMode != MODE_MULTI)
        g_iEvent = EV_NONE;
    else if (g_iForceEvent >= 0)
    {
        g_iEvent = g_iForceEvent;
        g_iForceEvent = -1;
    }
    else if (g_iRound > 1 && random_num(1, 100) <= get_pcvar_num(g_pEventChance))
    {
        g_iEvent = random_num(EV_BLOODMOON, EV_TOTAL - 1);
        if (g_iEvent == last)
            g_iEvent = (g_iEvent + random_num(1, EV_TOTAL - 2)) % EV_TOTAL;
        if (g_iEvent == EV_NONE)
            g_iEvent = EV_BLOODMOON;
    }
    else
        g_iEvent = EV_NONE;
}

public task_Announce()
{
    g_bAnnounced = true;
    new key[20];
    new total = RoundsTotal();

    // v3.2 (B): CSO "ROUND N" bandi (ekran ortasi sprite)
    new bool:got[33];
    for (new p = 1; p <= g_iMax; p++)
        got[p] = (is_user_connected(p) && CsoNotify(p, CN_ROUND, g_iRound)) ? true : false;

    // Moda ozel muzik (ini: MODE<n>_MUSIC)
    new mkey[16], mpath[128];
    formatex(mkey, charsmax(mkey), "MODE%d_MUSIC", g_iMode);
    if (TrieGetString(g_tRes, mkey, mpath, charsmax(mpath)) && mpath[0])
    {
        for (new p = 1; p <= g_iMax; p++)
        {
            if (is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_AMB))
                PlayKey(p, mkey);
        }
    }

    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p))
            client_print_color(p, print_team_default, "%s %L", ChatTag("ROUND_CHAT2"), p, "ROUND_CHAT2", g_iRound, total);
    }

    AssignQuests();

    // Son round
    if (g_iRound >= total)
    {
        PlayKey(0, "FINAL_ROUND");
        PlayVoxAll("VOX_FINAL");
        ChatAll("FINAL_ROUND_CHAT");
    }
    else if (total - g_iRound == 2)
        ChatAll("ROUNDS_LEFT_2");

    if (g_iMode == MODE_BOSS)
    {
        formatex(key, charsmax(key), "BOSS_ANN_%d", g_iBossType);
        HudAll(SL_ANN, BOSS_RGB[g_iBossType][0], BOSS_RGB[g_iBossType][1], BOSS_RGB[g_iBossType][2], 4.0, key);
        for (new p = 1; p <= g_iMax; p++)
        {
            if (is_user_connected(p))
                CsoNotify(p, CN_BOSS);
        }
        if (g_bFinalBoss)
            HudAll(SL_ALERT, CLR_DANGER, 3.0, "FINAL_BOSS_HUD");
        PlayKey(0, "BOSS_SPAWN");
        PlayVoxAll("VOX_BOSS");
        FadeAll(BOSS_RGB[g_iBossType][0] / 2, BOSS_RGB[g_iBossType][1] / 2, BOSS_RGB[g_iBossType][2] / 2, 90, 2.0);
        ShakeAll(6, 2.0, 3);
        if (get_pcvar_num(g_pLmEnable) && !get_pcvar_num(g_pLmBoss))
            ChatAll("LM_BOSS_BLOCKED");
        return;
    }

    if (g_iMode != MODE_INFECTION && g_iMode != MODE_MULTI)
    {
        formatex(key, charsmax(key), "MODE_ANN_%d", g_iMode);
        HudAll(SL_ANN, CLR_WARN, 4.0, key);
        PlayKey(0, "MODE_START");
        FadeAll(255, 80, 0, 50, 1.2);
        BossTeaser();
        return;
    }

    if (g_iEvent != EV_NONE)
    {
        formatex(key, charsmax(key), "EV_ANN_%d", g_iEvent);
        new r, g, b;
        EventColor(g_iEvent, r, g, b);
        HudAll(SL_ANN, r, g, b, 4.0, key);
        PlayKey(0, "EVENT_START");
        EventStartFx();
    }
    else
    {
        for (new p = 1; p <= g_iMax; p++)
        {
            if (is_user_connected(p) && !got[p])
                HudTo(p, SL_ANN, CLR_CYAN, 3.5, "ROUND_CALM", g_iRound);
        }
    }

    BossTeaser();
}

// Boss yaklasiyor uyarisi (oyunculari heyecanlandirir)
BossTeaser()
{
    new left = RoundsToBoss();
    if (left == 1)
    {
        ChatAll("BOSS_SOON_1");
        PlayKey(0, "BOSS_SOON");
    }
    else if (left == 2)
        ChatAll("BOSS_SOON_2", left);
}

// Event renkleri (HUD + ekran)
EventColor(ev, &r, &g, &b)
{
    switch (ev)
    {
        case EV_BLOODMOON, EV_VAMPIRE: { r = 255; g = 40;  b = 40; }
        case EV_FOG:                   { r = 190; g = 200; b = 210; }
        case EV_SPEED:                 { r = 0;   g = 230; b = 255; }
        case EV_LOWGRAV:               { r = 150; g = 120; b = 255; }
        case EV_DOUBLEDMG, EV_HEADHUNTER: { r = 255; g = 130; b = 0; }
        case EV_NIGHT, EV_BLACKOUT:    { r = 120; g = 120; b = 255; }
        case EV_PLAGUE, EV_HORDE:      { r = 120; g = 255; b = 0; }
        case EV_SUPPLY, EV_GOLDRUSH:   { r = 255; g = 210; b = 0; }
        case EV_BERSERK, EV_TITAN:     { r = 255; g = 70;  b = 0; }
        case EV_ADRENALINE:            { r = 0;   g = 255; b = 140; }
        case EV_METEOR:                { r = 255; g = 100; b = 0; }
        case EV_STORM:                 { r = 230; g = 240; b = 255; }
        default:                       { r = 0;   g = 200; b = 255; }
    }
}

public rg_FreezeEnd()
{
    g_iCountdown = get_pcvar_num(g_pCountdown);
    g_bCounting = true;
    MsFreezeEnd();

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id))
            continue;

        ApplyHumanGravity(id);
        rg_reset_maxspeed(id);

        if (g_iEvent == EV_SUPPLY && !g_bZombie[id])
        {
            g_iFireNades[id]++;
            rg_give_item(id, "weapon_hegrenade");
            rg_set_user_armor(id, 200, ARMOR_VESTHELM);
            g_iFrostNades[id]++;
            rg_give_item(id, "weapon_smokegrenade");
        }
        if (g_iEvent == EV_SPEED)
            SpeedRushFx(id);
    }

    if (g_iEvent == EV_SUPPLY)
        g_iAirdropClock = 5;
}

public rg_RoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
    for (new p = 1; p <= g_iMax; p++)
        LmTakeCancel(p);
    OnRoundEnd(status);
}

// Round sonu: odul, MVP, ozet. Hem kendi bitirisimizde hem oyunun bitirisinde
// tek sefer calisir (MVP artik her durumda gorunur).
OnRoundEnd(WinStatus:status)
{
    if (g_bRoundEnded)
        return;

    g_bRoundEnded = true;
    g_bCounting = false;

    // Mod / boss muzigi round bitince susar
    StopRoundMusic();
    // v3.0: sinif yetenekleri (kanca, lav, keseler, karartma...) round bitince durur
    ZcCleanupAll();
    // v3.0 (B): can barlari round bitince kalkar (ikonlar sonraki kontrolde yeniden gelir)
    OvhRemoveAll();

    new bool:wasActive = g_bRoundActive;
    g_bRoundActive = false;
    MsRoundEnd(status, wasActive);
    // v3.2 (B): ekrandaki killmark / bantlar kalkar, gercek silah HUD'u geri gelir
    CsoFlushAll();

    if (!wasActive)
        return;

    if (status == WINSTATUS_CTS)
    {
        g_iHumanStreak++;
        g_iZombieStreak = 0;
        if (g_iHumanStreak >= 3)
            LiveAll(0, "LIVE_HSTREAK", 2, g_iHumanStreak);

        CsoHudAll(CN_HWIN, 0, SL_ANN, CLR_GOOD, 4.0, "HUMANS_WIN");
        PlayKey(0, "HUMAN_WIN");

        new xp = get_pcvar_num(g_pWinHXP), ap = get_pcvar_num(g_pWinHAP);
        switch (g_iMode)
        {
            case MODE_BOSS:                     { xp = xp * 14 / 5; ap = ap * 5 / 2; }
            case MODE_SURVIVOR, MODE_SNIPER:    { xp = xp * 8 / 5;  ap = ap * 5 / 3; }
            case MODE_NEMESIS, MODE_ASSASSIN:   { xp = xp * 12 / 5; ap = ap * 2; }
            case MODE_ARMAGEDDON, MODE_PLAGUE:  { xp = xp * 2;      ap = ap * 5 / 3; }
        }

        new players[32];
        new n = GetHumans(players);
        for (new i = 0; i < n; i++)
        {
            g_iWins[players[i]]++;
            Reward(players[i], xp, ap);
            QuestEvent(players[i], 7, 1);
        }

        if (n == 1 && g_bLastAnn && !g_bSurvivor[players[0]] && !g_bSniper[players[0]])
            GrantAch(players[0], 7);
    }
    else if (status == WINSTATUS_TERRORISTS)
    {
        g_iZombieStreak++;
        g_iHumanStreak = 0;
        if (g_iZombieStreak >= 3)
            LiveAll(0, "LIVE_ZSTREAK", 2, g_iZombieStreak);

        CsoHudAll(CN_ZWIN, 0, SL_ANN, CLR_DANGER, 4.0, "ZOMBIES_WIN");
        PlayKey(0, "ZOMBIE_WIN");

        for (new id = 1; id <= g_iMax; id++)
        {
            if (is_user_connected(id) && g_bZombie[id] && !g_bMinion[id])
                Reward(id, get_pcvar_num(g_pWinZXP), get_pcvar_num(g_pWinZAP));
        }
    }

    if (status == WINSTATUS_CTS || status == WINSTATUS_TERRORISTS)
    {
        // v3.2: VIP / ELITE round sonu Vex Coin (vex_vip_round_vc, ELITE 2 kat)
        for (new id = 1; id <= g_iMax; id++)
        {
            if (is_user_connected(id) && !is_user_bot(id) && IsVip(id) && (g_bZombie[id] || is_user_alive(id)))
                g_iVC[id] += VipRoundVC(id);
        }
        RoundSummary();
    }

    if (g_iRound >= RoundsTotal())
        set_task(1.5, "task_MapEndAwards");
    // v3.0 (C): son round / RTV: oylanan haritaya gecis (odul + MVP akisindan sonra)
    MapOnRoundEnd();

    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id))
            SaveData(id);
    }
    SaveTop();
}

// MVP + kisisel round ozeti
RoundSummary()
{
    // MVP puani: verilen hasar + enfeksiyon * 600 + oldurme * 250
    new mvp, bestScore;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
            continue;
        new score = g_iRoundDmg[id] + g_iRoundInf[id] * 600 + g_iRoundKills[id] * 250;
        if (score > bestScore)
        {
            bestScore = score;
            mvp = id;
        }
    }

    new name[32], txt[128];
    g_iRoundMvp = mvp;   // v3.0: kafa ustu MVP ikonu (sonraki round boyunca)
    if (mvp)
    {
        get_user_name(mvp, name, charsmax(name));
        new vc = get_pcvar_num(g_pMvpVC), ap = get_pcvar_num(g_pMvpAP);
        g_iVC[mvp] += vc;
        AddAP(mvp, ap, false, false);

        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_connected(p) || is_user_bot(p))
                continue;
            formatex(txt, charsmax(txt), "%L", p, "MVP_HUD", name, g_iRoundDmg[mvp], g_iRoundKills[mvp], g_iRoundInf[mvp]);
            if (HudPartMode(g_pHudMvp) != 0 && !CsoNotify(p, CN_MVP))
                HudText(p, SL_ALERT, CLR_REWARD, 4.0, txt);
            client_print_color(p, mvp, "%s %L", ChatTag("MVP_CHAT2"), p, "MVP_CHAT2", name, g_iRoundDmg[mvp], g_iRoundKills[mvp], g_iRoundInf[mvp], ap, vc);
            if (!(g_iSet[p] & SET_NO_AMB))
                PlayKey(p, "MVP");
        }

        if (is_user_alive(mvp))
        {
            new Float:o[3];
            get_entvar(mvp, var_origin, o);
            FxRingEx(o, 255, 200, 40, 300, 12, 6);
            FxLight(o, 255, 200, 40, 30, 20, 10);
            set_user_rendering(mvp, kRenderFxGlowShell, 255, 200, 40, kRenderNormal, 20);
        }
    }

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_bot(id))
            continue;
        formatex(txt, charsmax(txt), "%L", id, "ROUND_SUMMARY", g_iRoundDmg[id], g_iRoundKills[id], g_iRoundInf[id], g_iRoundXP[id], g_iRoundAP[id]);
        new t = g_iTheme[id];
        HudText(id, SL_PERS, THEME_C[t][0], THEME_C[t][1], THEME_C[t][2], 4.0, txt);
    }
}

// Harita sonu: haritanin en iyileri odullendirilir
public task_MapEndAwards()
{
    // v3.0 (C): RTV + son round ayni anda olursa oduller bir kez verilir
    if (g_bMapAwards)
        return;
    g_bMapAwards = true;
    new topK, topI, topB, vK, vI, vB;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_bot(id))
            continue;
        if (g_iMapKills[id] > vK)    { vK = g_iMapKills[id];    topK = id; }
        if (g_iMapInf[id] > vI)      { vI = g_iMapInf[id];      topI = id; }
        if (g_iMapBossDmg[id] > vB)  { vB = g_iMapBossDmg[id];  topB = id; }
    }

    HudAll(SL_ANN, CLR_REWARD, 5.0, "MAPEND_HUD");
    PlayKey(0, "MAP_END");
    PlayVoxAll("VOX_MAPEND");
    ChatAll("MAPEND_TITLE");

    new name[32];
    if (topK)
    {
        get_user_name(topK, name, charsmax(name));
        g_iVC[topK] += 5;
        MapAwardLine("MAPEND_KILLS", topK, name, vK);
    }
    if (topI)
    {
        get_user_name(topI, name, charsmax(name));
        g_iVC[topI] += 5;
        MapAwardLine("MAPEND_INF", topI, name, vI);
    }
    if (topB)
    {
        get_user_name(topB, name, charsmax(name));
        g_iVC[topB] += 5;
        MapAwardLine("MAPEND_BOSS", topB, name, vB);
    }
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id))
            SaveData(id);
    }
}

MapAwardLine(const key[], who, const name[], val)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p))
            client_print_color(p, who, "%s %L", ChatTag(key), p, key, name, val);
    }
}

/* ---------------- Kazanma kontrolu ---------------- */

CheckWin()
{
    if (!g_bRoundActive || g_bRoundEnded)
        return;

    new humans = CountHumans(true);
    new zombies = CountZombies(true);

    if (humans == 0)
    {
        EndRound(WINSTATUS_TERRORISTS);
        return;
    }

    // Ayni anda tum zombiler olduyse insanlar kazanir (geri donus bekleyen olsa bile)
    if (zombies == 0)
    {
        EndRound(WINSTATUS_CTS);
        return;
    }

    if (RoundTimeLeft() <= 0)
        EndRound(WINSTATUS_CTS);
}

EndRound(WinStatus:status)
{
    if (g_bRoundEnded)
        return;

    OnRoundEnd(status);

    // Skor tablosu takim skorlari (harita oylamasi eklentileri de bunu kullanir)
    if (status == WINSTATUS_CTS)
        rg_update_teamscores(1, 0, true);
    else if (status == WINSTATUS_TERRORISTS)
        rg_update_teamscores(0, 1, true);

    rg_round_end(5.0, status, status == WINSTATUS_CTS ? ROUND_CTS_WIN : ROUND_TERRORISTS_WIN, "", "", true);
}

RoundTimeLeft()
{
    new Float:start = Float:get_member_game(m_fRoundStartTime);
    new total = get_member_game(m_iRoundTimeSecs);
    return floatround(float(total) - (get_gametime() - start), floatround_ceil);
}

// VIP'ler daha hizli geri doner
Float:RespawnDelay(id)
{
    new Float:d = get_pcvar_float(g_pRespawn);
    if (IsElite(id))
        d -= 2.0;
    else if (IsVip(id))
        d -= 1.0;
    return floatmax(1.0, d);
}

bool:AllowsInfection()
{
    return (g_iMode == MODE_INFECTION || g_iMode == MODE_MULTI) ? true : false;
}

bool:AllowsRespawn()
{
    if (g_bRespawnOff)
        return false;
    return (g_iMode == MODE_INFECTION || g_iMode == MODE_MULTI) ? true : false;
}

CountPlaying()
{
    new n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
            continue;
        new TeamName:t = get_member(id, m_iTeam);
        if (t == TEAM_TERRORIST || t == TEAM_CT)
            n++;
    }
    return n;
}

CountHumans(bool:alive)
{
    new n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (alive ? is_user_alive(id) : is_user_connected(id))
        {
            if (!g_bZombie[id])
                n++;
        }
    }
    return n;
}

CountZombies(bool:alive)
{
    new n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (alive ? is_user_alive(id) : is_user_connected(id))
        {
            if (g_bZombie[id])
                n++;
        }
    }
    return n;
}

GetHumans(players[32])
{
    new n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_alive(id) && !g_bZombie[id])
            players[n++] = id;
    }
    return n;
}


/* ================================================================== */
/*  TICK (1 sn)                                                        */
/* ================================================================== */

public task_Tick()
{
    g_iFrame++;
    MsTick();

    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id) && !is_user_bot(id))
            g_iPlaySec[id]++;
    }

    if (g_bCounting)
    {
        if (g_iCountdown > 0)
        {
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_connected(p) || is_user_bot(p))
                    continue;
                if (g_iCountdown <= 5)
                    set_dhudmessage(CLR_DANGER, -1.0, Y_COUNT, 0, 0.0, 1.0, 0.0, 0.0);
                else
                    set_dhudmessage(THEME_A[g_iTheme[p]][0], THEME_A[g_iTheme[p]][1], THEME_A[g_iTheme[p]][2], -1.0, Y_COUNT, 0, 0.0, 1.0, 0.0, 0.0);
                show_dhudmessage(p, "%L", p, "COUNTDOWN", g_iCountdown);
            }
            if (g_iCountdown <= 10)
            {
                if (g_bVoxCountdown)
                {
                    new snd[32];
                    formatex(snd, charsmax(snd), "vox/%s.wav", VOX_NUM[g_iCountdown]);
                    for (new p = 1; p <= g_iMax; p++)
                    {
                        if (is_user_connected(p) && !(g_iSet[p] & SET_NO_AMB))
                            client_cmd(p, "spk ^"%s^"", snd);
                    }
                }
                else
                    PlayKey(0, "COUNTDOWN_BEEP");
            }
            g_iCountdown--;
        }
        else
        {
            g_bCounting = false;
            StartMode();
        }
    }

    // Oyuncu bekleme durumu: ikinci oyuncu gelince round yeniden baslar
    if (g_bWaiting)
    {
        if (CountPlaying() >= 2)
        {
            g_bWaiting = false;
            ChatAll("GAME_COMMENCING");
            // Haritanin basinda round sayaci 1'den baslasin (30 roundluk plan)
            if (g_iRound <= 1)
                set_member_game(m_bCompleteReset, true);
            rg_round_end(3.0, WINSTATUS_DRAW, ROUND_GAME_COMMENCE, "", "", false);
        }
        else if (g_iFrame % 3 == 0)
            ShowWaiting();
    }

    if ((g_bRoundActive || g_bCounting) && g_fEclipseEnd <= get_gametime()
        && (g_iEvent == EV_BLOODMOON || g_iEvent == EV_NIGHT || g_iMode == MODE_BOSS || g_iMode == MODE_ASSASSIN)
        && random_num(1, 9) == 1)
        Lightning();

    DrawHud();
    TickAfk();
    TickLotto();
    TickVip();
    TickCosmetics();
    TickMineHints();

    // Canli sunucu yorumlari (~2 dakikada bir)
    if (g_iFrame % 130 == 65 && get_pcvar_num(g_pLiveChatter))
        LiveChatter();
    TickFlares();

    // v3.2: periyodik chat ipuclari (vex_chat_tip_interval sn, 0 = kapali), sirayla doner
    new tipInt = get_pcvar_num(g_pTipInterval);
    if (tipInt > 0 && ++g_iTipClock >= max(20, tipInt))
    {
        g_iTipClock = 0;
        g_iTipIdx = (g_iTipIdx % NUM_TIPS) + 1;
        new k[10];
        formatex(k, charsmax(k), "TIP_%d", g_iTipIdx);
        for (new p = 1; p <= g_iMax; p++)
        {
            if (is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_ADS))
                Chat(p, k);
        }
    }

    if (!g_bRoundActive)
        return;

    if (g_iFrame % 25 == 0 && random_num(1, 3) == 1)
    {
        for (new p = 1; p <= g_iMax; p++)
        {
            if (is_user_connected(p) && !(g_iSet[p] & SET_NO_AMB))
                PlayKey(p, "AMBIENT");
        }
    }

    TickAutoVote();
    MapVoteTick();

    // Son saniye uyarilari
    new tl = RoundTimeLeft();
    if (tl == 30)
        LiveAll(0, "LIVE_30S", 3);
    else if (tl == 10)
        CsoHudAll(CN_TEN, 0, SL_ALERT, CLR_WARN, 2.0, "HUD_10S");

    TickPlayers();
    TickBoss();
    TickMeteor();
    TickEvents();
    TickAirdrop();
    TickPools();
    TickRespawns();
    CheckWin();
}

ShowWaiting()
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        set_dhudmessage(CLR_WARN, -1.0, Y_COUNT, 0, 0.0, 3.0, 0.0, 0.0);
        show_dhudmessage(p, "%L", p, "WAITING_PLAYERS", CountPlaying());
    }
}

Lightning()
{
    engfunc(EngFunc_LightStyle, 0, "z");
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p))
            continue;
        if (!(g_iSet[p] & SET_NO_FX))
            FadeOne(p, 255, 255, 255, 110, 0.25);
        if (!(g_iSet[p] & SET_NO_AMB))
            PlayKey(p, "LIGHTNING");
    }
    remove_task(TASK_LIGHT);
    set_task(0.2, "task_LightRestore", TASK_LIGHT);
}

public task_LightRestore()
{
    engfunc(EngFunc_LightStyle, 0, (g_fEclipseEnd > get_gametime()) ? "a" : g_szLight);
}

TickRespawns()
{
    new Float:now = get_gametime();

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_alive(id))
            continue;

        new TeamName:t = get_member(id, m_iTeam);
        if (t != TEAM_TERRORIST && t != TEAM_CT)
            continue;

        // Gec katilanlar / olen zombiler: respawn izni olan modlarda zombi olarak doner
        if (g_fRespawnAt[id] == 0.0)
        {
            if (AllowsRespawn() && RoundTimeLeft() > 20)
                g_fRespawnAt[id] = now + RespawnDelay(id);
            continue;
        }

        if (now >= g_fRespawnAt[id])
        {
            g_fRespawnAt[id] = 0.0;
            if (!AllowsRespawn())
                continue;

            g_bFirst[id] = 0;
            g_bForceZombie[id] = 1;
            rg_set_user_team(id, TEAM_TERRORIST, MODEL_UNASSIGNED, true, false);
            rg_round_respawn(id);
        }
        else if (!is_user_bot(id))
        {
            set_hudmessage(CLR_WARN, -1.0, Y_COUNT + 0.05, 0, 0.0, 1.1, 0.0, 0.0, 4);
            show_hudmessage(id, "%L", id, "RESPAWN_IN", floatround(g_fRespawnAt[id] - now, floatround_ceil));
        }
    }
}

/* ---------------- Meteor ---------------- */

TickMeteor()
{
    if (g_iEvent != EV_METEOR)
        return;

    // v3.2: eskiden 4 sn'de bir; artik vex_meteor_interval (varsayilan 9 sn) x vex_meteor_count (1)
    if (++g_iMeteorTick < clamp(get_pcvar_num(g_pMeteorEvery), 2, 60))
        return;
    g_iMeteorTick = 0;

    new alive[32], n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_alive(id) && !g_bZombie[id])
            alive[n++] = id;
    }
    if (!n)
        return;

    new cnt = clamp(get_pcvar_num(g_pMeteorCount), 1, 4);
    for (new k = 0; k < cnt && n > 0; k++)
    {
        new pick = random(n);
        new victim = alive[pick];
        alive[pick] = alive[--n];

        new Float:o[3];
        if (!MeteorSpot(victim, o))
            continue;

        ZoneSpawn(o, 220.0, 255, 80, 0, 1.5, 0, false);
        FxLight(o, 255, 60, 0, 30, 15, 5);

        new params[4];
        params[0] = _:o[0];
        params[1] = _:o[1];
        params[2] = _:o[2];
        params[3] = 0;
        set_task(1.5 + 0.4 * float(k), "task_MeteorHit", TASK_METEOR + ((g_iFrame + k) % 40), params, 4);
    }
}

// v3.2: meteor carpma noktasi - insanin 96-220 birim onunde veya yaninda, zemine izlenir;
// hicbir oyuncunun 80 birim yakinina dusmez. Bulunamazsa false (meteor atlanir).
bool:MeteorSpot(id, Float:out[3])
{
    new Float:base[3], Float:ang[3], Float:end[3], Float:frac, Float:po[3];
    get_entvar(id, var_origin, base);
    get_entvar(id, var_v_angle, ang);
    for (new tries = 0; tries < 6; tries++)
    {
        new Float:yaw = ang[1] + float(random_num(-1, 1)) * 90.0 + random_float(-25.0, 25.0);
        new Float:dist = random_float(96.0, 220.0);
        end[0] = base[0] + floatcos(yaw, degrees) * dist;
        end[1] = base[1] + floatsin(yaw, degrees) * dist;
        end[2] = base[2];
        engfunc(EngFunc_TraceLine, base, end, IGNORE_MONSTERS, id, 0);
        get_tr2(0, TR_flFraction, frac);
        get_tr2(0, TR_vecEndPos, out);
        if (get_distance_f(base, out) < 96.0)
            continue; // duvar cok yakin
        // zemine indir
        end[0] = out[0]; end[1] = out[1]; end[2] = out[2] - 512.0;
        engfunc(EngFunc_TraceLine, out, end, IGNORE_MONSTERS, id, 0);
        get_tr2(0, TR_flFraction, frac);
        if (frac >= 1.0)
            continue; // bosluk
        get_tr2(0, TR_vecEndPos, out);
        out[2] += 4.0;
        new bool:clear = true;
        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_alive(p))
                continue;
            get_entvar(p, var_origin, po);
            if (get_distance_f(out, po) < 80.0) { clear = false; break; }
        }
        if (clear)
            return true;
    }
    return false;
}

public task_MeteorHit(params[], tid)
{
    if (!g_bRoundActive)
        return;

    new Float:o[3], Float:po[3];
    o[0] = Float:params[0];
    o[1] = Float:params[1];
    o[2] = Float:params[2];

    new bool:bossMeteor = (params[3] == 1) ? true : false;

    FxSkyStrike(o, 255, 120, 0);
    FxExplosion(o);
    FxLava(o);
    FxRing(o, 255, 140, 0, 320);
    PlayKey(0, "METEOR");

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_alive(id))
            continue;
        if (bossMeteor && g_bZombie[id])
            continue;

        get_entvar(id, var_origin, po);
        new Float:d = get_distance_f(o, po);
        if (d > 220.0)
            continue;

        ShakeOne(id);
        FadeOne(id, 255, 140, 0, 100, 0.8);
        // v3.2: sadece patlama hasari, mesafeyle azalir (merkezde tam, 220'de %25)
        new Float:fall = 1.0 - 0.75 * (d / 220.0);
        if (bossMeteor)
            ExecuteHamB(Ham_TakeDamage, id, 0, (g_iBoss && is_user_connected(g_iBoss)) ? g_iBoss : 0, 30.0 * fall, DMG_BLAST);
        else
            ExecuteHamB(Ham_TakeDamage, id, 0, 0, g_bZombie[id] ? 150.0 * fall : 20.0 * fall, DMG_BLAST);
    }
}


/* ================================================================== */
/*  MOD BASLATMA                                                       */
/* ================================================================== */

StartMode()
{
    new players[32];
    new n = GetHumans(players);

    if (n < 2)
    {
        // Takimda olup olu bekleyen oyuncular varsa round'u bozmadan dogur
        if (CountPlaying() > n && g_iStartTries < 3)
        {
            g_iStartTries++;
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_connected(p) || is_user_alive(p))
                    continue;
                new TeamName:t = get_member(p, m_iTeam);
                if (t == TEAM_TERRORIST || t == TEAM_CT)
                {
                    g_bForceZombie[p] = 0;
                    rg_round_respawn(p);
                }
            }
            // Bir saniye sonra tekrar dene
            g_iCountdown = 1;
            g_bCounting = true;
            return;
        }

        // Tek basina: geri sayimi tekrar tekrar baslatma, sakin bekle
        g_bWaiting = true;
        ShowWaiting();
        return;
    }
    g_iStartTries = 0;

    // Haritanin ilk roundu (oyun round'u yeniden baslatmadan basladi): plani simdi kur
    if (!g_bAnnounced)
    {
        remove_task(TASK_ANNOUNCE);
        PickMode();
        PickCalmPreset();
        ApplyWorldEvent();
        ApplyHostname();
        task_Announce();
    }

    // Yeterli oyuncu yoksa normal infection'a dus
    if (n < MODE_MINPL[g_iMode])
        g_iMode = MODE_INFECTION;

    g_bRoundActive = true;
    // v3.1: lazerin kapali oldugu mod (vex_lm_block_modes): geri sayimda kurulanlar kaldirilir
    LmModeStart();

    switch (g_iMode)
    {
        case MODE_INFECTION, MODE_MULTI: StartInfection(players, n);
        case MODE_NEMESIS:    StartNemesis(players, n, false);
        case MODE_ASSASSIN:   StartNemesis(players, n, true);
        case MODE_SURVIVOR:   StartSurvivor(players, n, false);
        case MODE_SNIPER:     StartSurvivor(players, n, true);
        case MODE_SWARM:      StartSwarm(players, n);
        case MODE_PLAGUE:     StartPlague(players, n);
        case MODE_ARMAGEDDON: StartArmageddon(players, n);
        case MODE_BOSS:       StartBoss(players, n);
    }

    if (g_iMode == MODE_ASSASSIN)
    {
        copy(g_szLight, charsmax(g_szLight), "a");
        engfunc(EngFunc_LightStyle, 0, g_szLight);
    }
    MsModeStart();
}

PickRandom(players[32], &n)
{
    new idx = random(n);
    new id = players[idx];
    players[idx] = players[n - 1];
    n--;
    return id;
}

StartInfection(players[32], n)
{
    new count = 1;

    if (g_iMode == MODE_MULTI)
        count = max(2, n / 4);
    else if (g_iEvent == EV_HORDE)
        count = max(2, n / 3);
    else if (g_iEvent == EV_PLAGUE)
        count = max(2, n / 4);
    else if (n >= 12)
        count = 2;

    if (g_iEvent == EV_TITAN)
        count = 1;

    count = min(count, n - 1);

    for (new i = 0; i < count; i++)
    {
        new id = PickRandom(players, n);
        g_bFirst[id] = 1;
        MakeZombie(id);
        Chat(id, "YOU_FIRST_ZOMBIE");
        HudTo(id, SL_PERS, CLR_ZOMBIE, 3.5, "YOU_FIRST_ZOMBIE_HUD");
    }

    new key[20];
    formatex(key, charsmax(key), "MODE_START_%d", g_iMode);
    CsoHudAll(CN_INFECT, 0, SL_ALERT, CLR_DANGER, 3.0, key);
    PlayKey(0, "ROUND_START");
    PlayVoxAll("VOX_INFECT");
    FadeAll(0, 120, 0, 50, 1.0);
}

StartNemesis(players[32], n, bool:assassin)
{
    new id = PickRandom(players, n);

    if (assassin)
        g_bAssassin[id] = 1;
    else
        g_bNemesis[id] = 1;

    MakeZombie(id);
    AnnounceRole(id, assassin ? "ROLE_ASSASSIN" : "ROLE_NEMESIS");

    new key[20];
    formatex(key, charsmax(key), "MODE_START_%d", g_iMode);
    CsoHudAll(assassin ? CN_ASSASSIN : CN_NEMESIS, 0, SL_ALERT, CLR_DANGER, 3.5, key);
    PlaySpecialIntro(assassin);
    FadeAll(255, 0, 0, 80, 1.5);
    ShakeAll(8, 1.5, 4);
}

StartSurvivor(players[32], n, bool:sniper)
{
    new id = PickRandom(players, n);
    MakeSurvivor(id, sniper);
    AnnounceRole(id, sniper ? "ROLE_SNIPER" : "ROLE_SURVIVOR");

    for (new i = 0; i < n; i++)
    {
        g_bFirst[players[i]] = 0;
        MakeZombie(players[i]);
    }

    new key[20];
    formatex(key, charsmax(key), "MODE_START_%d", g_iMode);
    CsoHudAll(CN_SURVIVOR, 0, SL_ALERT, CLR_HUMAN, 3.5, key);
    PlayKey(0, "MODE_START");
    FadeAll(0, 100, 255, 60, 1.5);
}

StartSwarm(players[32], n)
{
    new count = n / 2;
    for (new i = 0; i < count; i++)
    {
        new id = PickRandom(players, n);
        MakeZombie(id);
    }

    HudAll(SL_ALERT, CLR_WARN, 3.0, "MODE_START_6");
    PlayKey(0, "MODE_START");
}

StartPlague(players[32], n)
{
    new surv = PickRandom(players, n);
    MakeSurvivor(surv, false);
    AnnounceRole(surv, "ROLE_SURVIVOR");

    new nem = PickRandom(players, n);
    g_bNemesis[nem] = 1;
    MakeZombie(nem);
    AnnounceRole(nem, "ROLE_NEMESIS");

    new count = n / 2;
    for (new i = 0; i < count; i++)
    {
        new id = PickRandom(players, n);
        MakeZombie(id);
    }

    HudAll(SL_ALERT, CLR_DANGER, 3.5, "MODE_START_7");
    PlayKey(0, "MODE_START");
    FadeAll(150, 0, 255, 60, 1.5);
}

StartArmageddon(players[32], n)
{
    new half = n / 2;
    for (new i = 0; i < half; i++)
    {
        new id = PickRandom(players, n);
        g_bNemesis[id] = 1;
        MakeZombie(id);
    }
    for (new i = 0; i < n; i++)
        MakeSurvivor(players[i], false);

    HudAll(SL_ALERT, CLR_DANGER, 4.0, "MODE_START_8");
    PlaySpecialIntro(false);
    FadeAll(255, 60, 0, 90, 2.0);
}

AnnounceRole(id, const key[])
{
    new name[32], pkey[24];
    get_user_name(id, name, charsmax(name));
    ChatAllS(key, name);

    // Kisiye ozel ipucu
    formatex(pkey, charsmax(pkey), "%s_YOU", key);
    Chat(id, pkey);
    // v3.0: [F] calismazsa yedek tuslar (G / komut)
    if (g_bNemesis[id] || g_bAssassin[id])
        Chat(id, "SKILL_KEYS_HINT");
    HudTo(id, SL_PERS, CLR_WARN, 3.5, pkey);
}


/* ================================================================== */
/*  OYLAMA (mod / event) - canli sayacli menu                          */
/* ================================================================== */

#define VOTE_TIME 15
#define VOTE_OPTS 4

public cmd_vote(id)
{
    if (!(get_user_flags(id) & ADMIN_BAN))
        return PLUGIN_HANDLED;
    StartVote(id, 1);
    return PLUGIN_HANDLED;
}

// type: 1 = sonraki round modu, 2 = sonraki round eventi
StartVote(starter, type)
{
    if (g_iVoteType || g_bMapVoting)
    {
        if (starter)
            Chat(starter, "VOTE_RUNNING");
        return;
    }

    g_iVoteType = type;
    g_iVoteLeft = VOTE_TIME;

    // Rastgele, birbirinden farkli secenekler
    new pool[32], n;
    if (type == 1)
    {
        // Boss sadece plandaki roundlarda gelir
        for (new m = MODE_MULTI; m < MODE_BOSS; m++)
            pool[n++] = m;
    }
    else
    {
        for (new e = 1; e < EV_TOTAL; e++)
            pool[n++] = e;
    }

    for (new i = 0; i < VOTE_OPTS; i++)
    {
        new pick = random(n);
        g_iVoteOpt[i] = pool[pick];
        pool[pick] = pool[n - 1];
        n--;
        g_iVoteCount[i] = 0;
    }

    for (new p = 1; p <= g_iMax; p++)
        g_iVoted[p] = -1;

    new name[32];
    if (starter)
        get_user_name(starter, name, charsmax(name));
    else
        copy(name, charsmax(name), "Vexmira");

    FunAll(starter, type == 1 ? "VOTE_START_MODE" : "VOTE_START_EVENT", name, VOTE_TIME);
    PlayKey(0, "UI_VOTE_START");

    remove_task(TASK_VOTE);
    set_task(1.0, "task_VoteTick", TASK_VOTE, _, _, "a", VOTE_TIME + 1);
    task_VoteTick();
}

public task_VoteTick()
{
    if (!g_iVoteType)
        return;

    if (g_iVoteLeft <= 0)
    {
        FinishVote();
        return;
    }

    // Sadece henuz oy vermemis ve baska menu acmamis oyuncularda yenilenir
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p) || g_iVoted[p] >= 0)
            continue;
        if (VoteMenuOpen(p) || !AnyMenuOpen(p))
            ShowVoteMenu(p);
    }
    g_iVoteLeft--;
}

new g_iVoteMenu[33] = { -1, ... };

// v3.0 (C): ayrilan oyuncunun mod / event oyu duser
VoteDisconnect(id)
{
    if (g_iVoteType && 0 <= g_iVoted[id] < VOTE_OPTS)
        g_iVoteCount[g_iVoted[id]] = max(0, g_iVoteCount[g_iVoted[id]] - VipVoteW(id));
    g_iVoted[id] = -1;
}

bool:VoteMenuOpen(id)
{
    new m, nm, pg;
    player_menu_info(id, m, nm, pg);
    return (nm != -1 && nm == g_iVoteMenu[id]) ? true : false;
}

bool:AnyMenuOpen(id)
{
    new m, nm, pg;
    if (!player_menu_info(id, m, nm, pg))
        return false;
    return (m > 0 || nm != -1) ? true : false;
}

ShowVoteMenu(id)
{
    new title[320], item[96], key[16], nm[40];
    new hsub[128];
    formatex(hsub, charsmax(hsub), "%L", id, "VOTE_LEFT", g_iVoteLeft);
    if (g_iVoteType == 1) VexHead(id, title, charsmax(title), "VOTE_TITLE_MODE", hsub); else VexHead(id, title, charsmax(title), "VOTE_TITLE_EVENT", hsub);
    new menu = VexMenuCreate(title, "menu_vote_handler");

    for (new i = 0; i < VOTE_OPTS; i++)
    {
        formatex(key, charsmax(key), g_iVoteType == 1 ? "MODE_NAME_%d" : "EV_NAME_%d", g_iVoteOpt[i]);
        formatex(nm, charsmax(nm), "%L", id, key);

        if (g_iVoted[id] == i)
            formatex(item, charsmax(item), "\y%s \r[ %d %L\r ] \y<", nm, g_iVoteCount[i], id, "VOTE_VOTES");
        else
            formatex(item, charsmax(item), "%s%s \r[ %d %L\r ]", g_iVoted[id] >= 0 ? "\r" : "\y", nm, g_iVoteCount[i], id, "VOTE_VOTES");
        MenuAdd(menu, item, i);
    }

    new note[96];
    formatex(note, charsmax(note), "^n\d%L", id, "VOTE_TIE");
    VexAddText(menu, note, 0);
    menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
    MenuProps(id, menu);
    g_iVoteMenu[id] = menu;
    menu_display(id, menu, 0, 1);
}

public menu_vote_handler(id, menu, item)
{
    if (item < 0 || !g_iVoteType)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new opt = MenuInfo(menu, item);
    menu_destroy(menu);

    if (g_iVoted[id] >= 0 || opt < 0 || opt >= VOTE_OPTS)
        return PLUGIN_HANDLED;

    g_iVoted[id] = opt;
    g_iVoteCount[opt] += VipVoteW(id);

    new name[32], key[16];
    get_user_name(id, name, charsmax(name));
    formatex(key, charsmax(key), g_iVoteType == 1 ? "MODE_NAME_%d" : "EV_NAME_%d", g_iVoteOpt[opt]);

    for (new p = 1; p <= g_iMax && get_pcvar_num(g_pChatBcast); p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        new nm[40];
        formatex(nm, charsmax(nm), "%L", p, key);
        client_print_color(p, id, "%s %L", ChatTag("VOTE_CAST"), p, "VOTE_CAST", name, nm);
    }

    ShowVoteMenu(id);
    return PLUGIN_HANDLED;
}

FinishVote()
{
    new best = -1, bestc = 0, ties[VOTE_OPTS], nt;
    for (new i = 0; i < VOTE_OPTS; i++)
    {
        if (g_iVoteCount[i] > bestc)
        {
            bestc = g_iVoteCount[i];
            nt = 0;
            ties[nt++] = i;
        }
        else if (g_iVoteCount[i] == bestc)
            ties[nt++] = i;
    }
    best = ties[random(nt)];

    new key[16];
    formatex(key, charsmax(key), g_iVoteType == 1 ? "MODE_NAME_%d" : "EV_NAME_%d", g_iVoteOpt[best]);

    if (g_iVoteType == 1)
        g_iForceMode = g_iVoteOpt[best];
    else
        g_iForceEvent = g_iVoteOpt[best];

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        new nm[40];
        formatex(nm, charsmax(nm), "%L", p, key);
        client_print_color(p, print_team_default, "%s %L", ChatTag("VOTE_RESULT"), p, "VOTE_RESULT", nm, bestc);

        HudToS(p, SL_ALERT, CLR_EVENT, 3.5, "VOTE_RESULT_HUD", nm);
        if (VoteMenuOpen(p))
            show_menu(p, 0, "^n", 1);
    }
    PlayKey(0, "UI_VOTE_END");

    g_iVoteType = 0;
    remove_task(TASK_VOTE);
}

// Otomatik oylama: her N roundda bir, roundun ortasinda
TickAutoVote()
{
    new every = get_pcvar_num(g_pVoteEvery);
    if (every <= 0 || g_iVoteType || g_bMapVoting || g_iForceMode >= 0 || g_iRound % every != 0)
        return;

    // Siradaki round boss veya ozel mod roundu ise oylama yapilmaz (plan bozulmasin)
    if (IsBossRound(g_iRound + 1) || RoundInList(g_pSpecialRounds, g_iRound + 1))
        return;

    if (RoundTimeLeft() == 75 && CountPlaying() >= 2)
        StartVote(0, random_num(1, 3) == 1 ? 2 : 1);
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

// Bilgi: /round - harita plani
public cmd_roundplan(id)
{
    new list[128];
    get_pcvar_string(g_pBossRounds, list, charsmax(list));
    Chat(id, "PLAN_1", g_iRound, RoundsTotal());
    client_print_color(id, print_team_default, "%s %L", ChatTag("PLAN_2"), id, "PLAN_2", list);
    get_pcvar_string(g_pSpecialRounds, list, charsmax(list));
    client_print_color(id, print_team_default, "%s %L", ChatTag("PLAN_3"), id, "PLAN_3", list);
    // v3.0: bu haritada yuklenen bosslar (precache butcesi)
    list[0] = 0;
    new nm[40], key[16];
    for (new i = 0; i < g_iBossLoadN; i++)
    {
        formatex(key, charsmax(key), "BOSS_NAME_%d", g_iBossLoadList[i]);
        formatex(nm, charsmax(nm), "%s%L", i ? ", " : "", id, key);
        add(list, charsmax(list), nm);
    }
    if (list[0])
        Chat(id, "PLAN_5", list);
    Chat(id, "PLAN_4");
    return PLUGIN_HANDLED;
}


/* ================================================================== */
/*  HAVA IKMALI, ROUND GOREVLERI, ZOMBI EVRIMI, EVENT EFEKTLERI        */
/* ================================================================== */

/* ---------------- Event efektleri ---------------- */

EventStartFx()
{
    switch (g_iEvent)
    {
        case EV_BLOODMOON:
        {
            FadeAll(180, 0, 0, 110, 3.0);
            ShakeAll(6, 2.0, 3);
            PlayKey(0, "BOSS_SCREAM");
        }
        case EV_FOG:        FadeAll(200, 200, 210, 140, 2.0);
        case EV_SPEED:
        {
            FadeAll(0, 200, 255, 90, 1.0);
            PlayKey(0, "SPEED_START");
            PlayVoxAll("VOX_SPEED");
            ChatAll("SPEED_TIP");
        }
        case EV_LOWGRAV:    FadeAll(150, 120, 255, 70, 1.5);
        case EV_DOUBLEDMG, EV_HEADHUNTER: FadeAll(255, 130, 0, 60, 1.0);
        case EV_NIGHT:      FadeAll(0, 0, 0, 200, 2.0);
        case EV_PLAGUE, EV_HORDE: FadeAll(0, 180, 0, 80, 1.5);
        case EV_SUPPLY, EV_GOLDRUSH: FadeAll(255, 215, 0, 60, 1.5);
        case EV_BERSERK, EV_TITAN: FadeAll(255, 60, 0, 70, 1.5);
        case EV_ADRENALINE: FadeAll(0, 255, 140, 60, 1.2);
        case EV_METEOR:     FadeAll(255, 90, 0, 70, 1.5);
        case EV_VAMPIRE:    FadeAll(120, 0, 30, 90, 2.0);
        case EV_STORM:
        {
            Lightning();
            PlayVoxAll("VOX_STORM");
            ChatAll("STORM_TIP");
        }
        case EV_BLACKOUT:
        {
            PlayKey(0, "BLACKOUT");
            PlayVoxAll("VOX_BLACKOUT");
            FadeAll(0, 0, 0, 255, 1.5);
            ChatAll("BLACKOUT_TIP");
        }
    }
}

SpeedRushFx(id)
{
    new Float:o[3];
    get_entvar(id, var_origin, o);
    o[2] -= 30.0;
    FxRingSmall(o, 0, 220, 255);
    FxFollow(id, g_bZombie[id] ? 255 : 0, g_bZombie[id] ? 40 : 220, g_bZombie[id] ? 40 : 255, 6, 4);
    if (!is_user_bot(id) && !(g_iSet[id] & SET_NO_FX))
        FadeOne(id, 0, 200, 255, 60, 0.6);
}

// Her saniye: event'e ozel ortam efektleri
TickEvents()
{
    new Float:o[3];
    switch (g_iEvent)
    {
        case EV_SPEED:
        {
            if (g_iFrame % 6 == 0)
            {
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_AMB))
                        PlayKey(p, "SPEED_WIND");
                }
            }
            // Ayak altinda hiz dalgasi
            if (g_iFrame % 3 == 0)
            {
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p))
                        continue;
                    get_entvar(p, var_origin, o);
                    o[2] -= 30.0;
                    if (g_bZombie[p])
                        FxRingEx(o, 255, 40, 40, 90, 4, 3, 140);
                    else
                        FxRingEx(o, 0, 220, 255, 90, 4, 3, 140);
                }
            }
        }
        case EV_STORM:
        {
            if (g_iFrame % 5 == 0)
                StormStrike();
        }
        case EV_BLACKOUT, EV_NIGHT:
        {
            // Karanlikta zombilerin gozleri parlar
            for (new p = 1; p <= g_iMax; p++)
            {
                if (!is_user_alive(p) || !g_bZombie[p] || g_bBoss[p])
                    continue;
                get_entvar(p, var_origin, o);
                o[2] += 26.0;
                FxLight(o, 255, 0, 0, 5, 11, 2);
            }
            if (g_iEvent == EV_BLACKOUT && g_iFrame % 9 == 0 && random_num(0, 1))
            {
                engfunc(EngFunc_LightStyle, 0, "f");
                remove_task(TASK_LIGHT);
                set_task(0.25, "task_LightRestore", TASK_LIGHT);
                PlayKey(0, "BLACKOUT");
            }
        }
        case EV_BLOODMOON:
        {
            if (g_iFrame % 10 == 0)
            {
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_FX))
                        FadeOne(p, 160, 0, 0, 50, 1.5);
                }
            }
        }
        case EV_LOWGRAV:
        {
            if (g_iFrame % 3 == 0)
            {
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (!is_user_alive(p) || (get_entvar(p, var_flags) & FL_ONGROUND))
                        continue;
                    get_entvar(p, var_origin, o);
                    FxImplosion(o, 60, 8, 3);
                }
            }
        }
    }
}

// Firtina: gokten simsek, cogunlukla zombilere
StormStrike()
{
    new list[32], n;
    new bool:zombie = (random_num(1, 100) <= 75) ? true : false;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_alive(p) && (g_bZombie[p] ? true : false) == zombie)
            list[n++] = p;
    }
    if (!n)
        return;

    new target = list[random(n)];
    new Float:o[3], Float:po[3];
    get_entvar(target, var_origin, o);
    o[0] += random_float(-60.0, 60.0);
    o[1] += random_float(-60.0, 60.0);

    FxSkyStrike(o, 200, 220, 255);
    FxSkyStrike(o, 255, 255, 255);
    FxRingEx(o, 200, 220, 255, 220, 16, 5);
    PlayKey(0, "STORM_STRIKE");

    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !(g_iSet[p] & SET_NO_FX))
            FadeOne(p, 255, 255, 255, 50, 0.2);
    }

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p))
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > 160.0)
            continue;
        ShakeEx(p, 10, 1.0, 6);
        if (g_bZombie[p] && !g_bBoss[p])
        {
            g_fSlow[p] = get_gametime() + 1.5;
            rg_reset_maxspeed(p);
            ExecuteHamB(Ham_TakeDamage, p, 0, 0, 120.0, DMG_SHOCK);
        }
        else if (!g_bZombie[p])
            ExecuteHamB(Ham_TakeDamage, p, 0, 0, 10.0, DMG_SHOCK);
    }
}

/* ===== End module: modes.inc ===== */
/* ================================================================== */
/*  BOLUM 11/13: OYUNCULAR                                            */
/*  Baglanti / ayrilma, dil, oyuncu komutlari ve menuleri (ana        */
/*  menu, ayarlar, FPS, meslek), chat (say) isleyici, oyuncu ReAPI    */
/*  hook'lari (dogma, hasar, olum, hiz, ziplama, PreThink), eglence   */
/*  komutlari, canli sunucu sohbeti, AFK.                             */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
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

    for (new p = 1; p <= g_iMax && get_pcvar_num(g_pChatBcast); p++)
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
    g_iCsoCur[id] = -1;
    g_iCsoQn[id] = 0;
    g_iCsoWpn[id] = 0;
    g_iCsoIcon[id] = 0;
    g_szHudSig[id][0] = 0;
    g_fHudNext[id] = 0.0;
    g_iHudXpSeen[id] = -1;
    g_fXpBarEnd[id] = 0.0;
    ResetPlayer(id);
    HudReset(id);
    MsResetPlayer(id);
    if (get_pcvar_num(g_pAutoJoinHumans) && !is_user_bot(id))
        set_task(0.25, "task_AutoJoinHuman", id + TASK_AUTOTEAM);

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

// Team-full / team-balance checks in the stock join menu can reject players
// even when this mode intentionally uses CT for humans and T for zombies.
public cmd_jointeam(id)
{
    if (!get_pcvar_num(g_pAutoJoinHumans))
        return PLUGIN_CONTINUE;

    // Zombie mode owns team assignment. Never let the stock menu try T or
    // reject CT with its player-count / balance checks; keep humans on CT.
    if (!is_user_alive(id) && get_member(id, m_iTeam) != TEAM_CT)
        ForceJoinHuman(id);
    return PLUGIN_HANDLED;
}

ForceJoinHuman(id)
{
    if (!is_user_connected(id) || is_user_alive(id))
        return;

    if (get_member(id, m_iTeam) != TEAM_CT && !rg_join_team(id, TEAM_CT))
        rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED, true, false);
    remove_task(id + TASK_JOINCLASS);
    set_task(0.2, "task_JoinClassAuto", id + TASK_JOINCLASS);
}

public task_AutoJoinHuman(tid)
{
    new id = tid - TASK_AUTOTEAM;
    if (!is_user_connected(id) || is_user_alive(id) || !get_pcvar_num(g_pAutoJoinHumans))
        return;

    if (get_member(id, m_iTeam) != TEAM_CT)
        ForceJoinHuman(id);
    else
        task_JoinClassAuto(id + TASK_JOINCLASS);
}

public task_JoinClassAuto(tid)
{
    new id = tid - TASK_JOINCLASS;
    if (!is_user_connected(id) || is_user_alive(id) || get_member(id, m_iTeam) != TEAM_CT)
        return;

    // Class 5 is ReGameDLL's automatic/random player-model selection.
    engclient_cmd(id, "joinclass", "5");
}

public task_EnforceAutoTeam()
{
    if (!get_pcvar_num(g_pAutoJoinHumans))
        return;

    set_cvar_num("mp_auto_join_team", 1);
    set_cvar_string("humans_join_team", "CT");
    set_cvar_num("mp_limitteams", 0);
    set_cvar_num("mp_autoteambalance", 0);
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
    for (new c = 0; c < CM_CATS; c++)
        CmRemove(id, c);
    CmPrevRemove(id);
    g_iCsoCur[id] = -1;
    g_iCsoQn[id] = 0;
    g_iCsoWpn[id] = 0;
    g_iCsoIcon[id] = 0;
    remove_task(id + TASK_AUTOTEAM);
    remove_task(id + TASK_JOINCLASS);
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
    g_iCmOwned[id] = 0; g_iCmSelPk[id] = 0;
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
    PlayKey(id, "WELCOME");
    FadeOne(id, THEME_A[t][0], THEME_A[t][1], THEME_A[t][2], 60, 1.2);

    // v3.2: kisa karsilama (gerisi periyodik ipuclarinda)
    Chat(id, "WELCOME", name);
    Chat(id, "WELCOME_2");
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
        MsEvent(ME_LASTHUMAN);
        new name[32];
        get_user_name(last, name, charsmax(name));
        CsoHudAll(CN_LAST, 0, SL_ALERT, CLR_WARN, 3.0, "LAST_HUMAN");
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
    MsOnSpawn(id);
    // istemci ResetHUD'da durum ikonlarini siler: rol ikonu yeniden gonderilsin
    g_iCsoIcon[id] = 0;

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
            g_fMadness[id] = get_gametime() + 2.0 + VipSpawnProt(id);
            ApplyRender(id);
        }
        return;
    }

    g_bZombie[id] = 0; g_bNemesis[id] = 0; g_bAssassin[id] = 0; g_bSurvivor[id] = 0; g_bSniper[id] = 0;
    g_bBoss[id] = 0; g_bMinion[id] = 0; g_bFirst[id] = 0;
    g_bGunsGiven[id] = false;
    g_bNadesGiven[id] = false;
    g_bVipRegun[id] = false;

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
    armor += VipArmor(id);
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

    // v3.2: VIP paketi dogusta otomatik (vex_vip_autopack 1)
    if (IsVip(id) && get_pcvar_num(g_pVipAutoPack) && !g_bVipFreeUsed[id])
        VipFreePack(id);
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
                    rg_set_user_armor(victim, max(0, armor - max(1, floatround(dmg))), atype);
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

            // vex_modewpn: mod silahi carpani (> 50 = sabit mermi hasari); survivor'un
            // diger silahlari (bicak, bomba) eskisi gibi x1.5
            new mm = ModeOf(attacker), ms = (mm >= 0) ? ModeSlot(mm, wid) : -1;
            if (ms >= 0)
            {
                if (MW_DMG[mm][ms] > 50.0)
                {
                    if (bulletHit)
                        dmg = MW_DMG[mm][ms];
                }
                else
                    m *= MW_DMG[mm][ms];
            }
            else if (mm == 0)
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
                dmg = floatmin(dmg, floatmax(100.0, get_pcvar_float(g_pSpecCap)));
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
    // v3.2: hasar alan oyuncunun lazer sokmesi iptal
    if (1 <= victim <= g_iMax && g_iPlantAction[victim] == 2 && damage > 0.0)
        LmTakeCancel(victim, "LM_TAKE_HURT");
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

    new sw = SpecialIndex(attacker, wid);
    new mm = ModeOf(attacker), ms = (mm >= 0) ? ModeSlot(mm, wid) : -1;
    new fx = (sw >= 0) ? SW_EFFECT[sw] : ((ms >= 0) ? MW_FX[mm][ms] : SWE_NONE);
    // Knockback
    if (bullet && get_pcvar_num(g_pKnockback))
    {
        new Float:kbDamage = damage;
        if (fx == SWE_VOID)
            kbDamage *= 1.35;
        ApplyKnockback(victim, attacker, wid, kbDamage);
    }

    // Can calma (Vampire meslegi / Vampir Gecesi eventi / Vex Reaper)
    new Float:steal = 0.0;
    if (g_iJob[attacker] == JOB_VAMPIRE)
        steal += 0.05;
    if (g_iEvent == EV_VAMPIRE)
        steal += 0.05;
    if (fx == SWE_VAMPIRE)
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
    switch (fx)
    {
        case SWE_FIRE: if (random_num(1, 100) <= 20) Ignite(victim, attacker, 3);
        case SWE_LIGHTNING:
        {
            new chain = (sw >= 0) ? SW_CHAIN_DMG[sw] : 25;
            if (chain > 0) ChainLightning(victim, attacker, float(chain));
        }
        case SWE_ICE: if (random_num(1, 100) <= 25) Freeze(victim, 1.5);
        case SWE_EXPLOSIVE:
        {
            if (random_num(1, 100) <= 12)
            {
                new Float:origin[3], Float:other[3];
                get_entvar(victim, var_origin, origin);
                if (sw >= 0)
                    FxRing(origin, SW_RGB[sw][0], SW_RGB[sw][1], SW_RGB[sw][2], 140);
                else
                    FxRing(origin, 255, 140, 40, 140);
                for (new p = 1; p <= g_iMax; p++)
                {
                    if (p == victim || !is_user_alive(p) || !g_bZombie[p] || g_bBoss[p])
                        continue;
                    get_entvar(p, var_origin, other);
                    if (get_distance_f(origin, other) <= 140.0)
                        ExecuteHamB(Ham_TakeDamage, p, attacker, attacker, 18.0, DMG_BLAST);
                }
            }
        }
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

    new Float:power = KB_POWER[w] * floatclamp(get_pcvar_float(g_pKBMult), 0.0, 3.0);
    if (g_bNemesis[victim] || g_bAssassin[victim])
        power *= 0.25;
    else if (!g_bMinion[victim])
        power *= CLASS_KB[g_iClass[victim]];

    if (g_iJob[attacker] == JOB_TACTICIAN)
        power *= 1.3;

    if (SpecialIndex(attacker, wid) == 7)
        power *= 1.5;

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
    g_iSpecW[victim] = 0; // v3.2: ozel silah bitleri olumde temizlenir
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
    {
        g_bFirstBlood = true;
        return;
    }

    new Float:now = get_gametime();
    new bool:hs = (get_member(victim, m_LastHitGroup) == HIT_HEAD) ? true : false;
    new bool:nade = get_member(victim, m_bKilledByGrenade) ? true : false;

    g_iStreak[attacker]++;

    // v3.3: combo penceresi (vex_combo_time); zombi canlari yuksek oldugu icin 4 sn azdi
    if (now - g_fLastKill[attacker] <= floatclamp(get_pcvar_float(g_pComboTime), 2.0, 15.0))
        g_iMulti[attacker]++;
    else
        g_iMulti[attacker] = 1;
    g_fLastKill[attacker] = now;

    // v3.3 (B): CSO bildirimi ONCE secilir; gosterilirse tek ses calinir (ust uste "spk" komutlari
    // birbirini kesiyordu: headshot sesi + combo seslendirmesi + killmark sesi -> combo hic duyulmuyordu)
    new km;
    new bool:knife = (get_user_weapon(attacker) == CSW_KNIFE) ? true : false;
    if (g_iMulti[attacker] >= 2)
        km = CN_KM1 + clamp(g_iMulti[attacker], 2, 5) - 1;
    else if (!g_bFirstBlood && CsoNoteOn(CN_FIRST))
        km = CN_FIRST;
    else if (knife)
        km = CN_KNIFE;
    else if (nade)
        km = CN_NADE;
    else if (hs)
        km = CN_HS;
    else
        km = CN_KM1;
    g_bFirstBlood = true;
    new bool:shown = CsoNotify(attacker, km);

    new ktxt[96];
    if (hs)
    {
        g_iHS[attacker]++;
        g_iRoundHS[attacker]++;
        QuestEvent(attacker, 2, 1);
        new hsap = get_pcvar_num(g_pHsAP);
        AddAP(attacker, g_iEvent == EV_HEADHUNTER ? hsap * 3 : hsap, true, false);
        formatex(ktxt, charsmax(ktxt), "%L", attacker, "HUD_HEADSHOT");
        if (!shown && !(g_iSet[attacker] & SET_NO_STREAK) && g_iMulti[attacker] < 2)
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

        // 6+ (MONSTER) her zaman seslendirilir; 2-5 sprite gosterildiyse CsoNotify zaten caldi
        if (!(g_iSet[attacker] & SET_NO_STREAK) && (!shown || m >= 6))
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

    if (ktxt[0] && !shown)
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
    // Ozel silahlar: sadece cfg'de ses tanimlanmissa motorun stok cekme/sarjor sesini degistir.
    // FM_EmitSound oyuncu ent'siyle cagrilir; aktif silah + ozel silah bit'i birlikte eslestirilir.
    if (!g_bEmitting && (1 <= ent <= g_iMax) && is_user_connected(ent) && !g_bZombie[ent])
    {
        new sw = SpecialIndex(ent, GetActiveWeaponId(ent));
        if (sw >= 0)
        {
            new key[20], path[128];
            if (containi(sample, "draw") != -1)
                formatex(key, charsmax(key), "SW%d_DRAW", sw);
            else if (containi(sample, "reload") != -1 || containi(sample, "clipin") != -1
                || containi(sample, "clipout") != -1 || containi(sample, "boltpull") != -1
                || containi(sample, "insert") != -1 || containi(sample, "slide") != -1)
                formatex(key, charsmax(key), "SW%d_RELOAD", sw);

            if (key[0] && TrieGetString(g_tRes, key, path, charsmax(path)) && path[0])
            {
                EmitSafe(ent, channel, path, volume, attn, flags, pitch);
                return FMRES_SUPERCEDE;
            }
        }
    }

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

// v3.2: ANA MENU TEK SAYFA, 8 GIRIS. Diger her sey alt menulerde (HUB_x).
// Kodlar: 1-22 = eski MAIN_<no> hedefleri, 31-34 = profil (PROF_x),
// 201-205 = alt menuler, 99 = geri (ana menu). Say komutlari aynen calisir.
#define HUB_MARKET   201
#define HUB_CLASS    202
#define HUB_CHAR     203
#define HUB_FUN      204
#define HUB_VIPADM   205
#define HUB_BACK     99

new const HUB_MARKET_ITEMS[] = { 1, 2, 18, 19 };   // market = esya + ozel silah (yetenek YOK)
new const HUB_CLASS_ITEMS[]  = { 4, 5 };
new const HUB_CHAR_ITEMS[]   = { 31, 7, 20, 32, 33, 34, 16, 22 };   // yetenekler karakter tarafinda
new const HUB_FUN_ITEMS[]    = { 6, 9, 14, 15, 13 };
new const HUB_VIPADM_ITEMS[] = { 8, 17 };

ShowMainMenu(id)
{
    new title[320], item[96];

    new hsub[96];
    formatex(hsub, charsmax(hsub), "%L", id, "MENU_MAIN_SUB");
    VexHead(id, title, charsmax(title), "MENU_MAIN", hsub);
    new menu = VexMenuCreate(title, "menu_main_handler");
    PlayKey(id, "UI_OPEN");

    new bool:adm = (get_user_flags(id) & ADMIN_BAN) ? true : false;

    formatex(item, charsmax(item), "\y%L", id, "MAINH_1"); MenuAdd(menu, item, HUB_MARKET);
    formatex(item, charsmax(item), "\y%L", id, "MAINH_2"); MenuAdd(menu, item, 3);
    formatex(item, charsmax(item), "\y%L", id, "MAINH_3"); MenuAdd(menu, item, HUB_CLASS);
    menu_addblank(menu, 0);
    formatex(item, charsmax(item), "\y%L", id, "MAINH_4");
    if (g_iQuest[id] >= 0 && g_bQuestDone[id])
        add(item, charsmax(item), " \r[OK\r]");
    MenuAdd(menu, item, HUB_CHAR);
    formatex(item, charsmax(item), "\y%L", id, "MAINH_5");
    if (g_iDailyDay[id] < get_systime() / 86400)
        add(item, charsmax(item), " \r(!)");
    MenuAdd(menu, item, HUB_FUN);
    formatex(item, charsmax(item), "\y%L", id, "MAINH_6"); MenuAdd(menu, item, 21);
    menu_addblank(menu, 0);
    formatex(item, charsmax(item), "\y%L", id, "MAINH_7"); MenuAdd(menu, item, 11);
    formatex(item, charsmax(item), "\y%L%s", id, adm ? "MAINH_8A" : "MAINH_8", IsVip(id) ? " \y[*]" : "");
    MenuAdd(menu, item, adm ? HUB_VIPADM : 8);

    // 8 giris tek sayfada: sayfalama yok, 0 = cikis
    MenuNoPage(menu);
    menu_setprop(menu, MPROP_EXIT, MEXIT_FORCE);
    MenuFinish(id, menu);
}

ShowHub(id, hub)
{
    new title[320], item[96], key[16];
    formatex(key, charsmax(key), "HUB_%d", hub - 200);
    VexHead(id, title, charsmax(title), key);
    new menu = VexMenuCreate(title, "menu_main_handler");

    new list[8], n;
    switch (hub)
    {
        case HUB_MARKET: { n = sizeof HUB_MARKET_ITEMS; for (new i = 0; i < n; i++) list[i] = HUB_MARKET_ITEMS[i]; }
        case HUB_CLASS:  { n = sizeof HUB_CLASS_ITEMS;  for (new i = 0; i < n; i++) list[i] = HUB_CLASS_ITEMS[i]; }
        case HUB_CHAR:   { n = sizeof HUB_CHAR_ITEMS;   for (new i = 0; i < n; i++) list[i] = HUB_CHAR_ITEMS[i]; }
        case HUB_FUN:    { n = sizeof HUB_FUN_ITEMS;    for (new i = 0; i < n; i++) list[i] = HUB_FUN_ITEMS[i]; }
        case HUB_VIPADM: { n = sizeof HUB_VIPADM_ITEMS; for (new i = 0; i < n; i++) list[i] = HUB_VIPADM_ITEMS[i]; }
    }

    for (new k = 0; k < n; k++)
    {
        new c = list[k];
        if (c > 30)
            formatex(key, charsmax(key), "PROF_%d", c - 30);
        else
            formatex(key, charsmax(key), "MAIN_%d", c);
        formatex(item, charsmax(item), "\y%L", id, key);
        if (c == 6 && g_iDailyDay[id] < get_systime() / 86400)
            add(item, charsmax(item), " \r(!)");
        if (c == 20 && g_iQuest[id] >= 0 && g_bQuestDone[id])
            add(item, charsmax(item), " \r[OK\r]");
        MenuAdd(menu, item, c);
    }
    menu_addblank(menu, 0);
    formatex(item, charsmax(item), "\y%L", id, "HUB_BACK");
    MenuAdd(menu, item, HUB_BACK);

    MenuNoPage(menu);
    menu_setprop(menu, MPROP_EXIT, MEXIT_FORCE);
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
    MainDispatch(id, sel);
    return PLUGIN_HANDLED;
}

MainDispatch(id, sel)
{
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
        case 17: if (get_user_flags(id) & ADMIN_BAN) ShowAdminMenu(id);
        case 18: ShowMineMenu(id);
        case 19: ShowNadeMenu(id);
        case 20: cmd_quest(id);
        case 21: ShowCosmeticMenu(id);
        case 22: ShowTop10(id);
        case 31: ShowCard(id, id);
        case 32: ShowAchMenu(id);
        case 33: ShowTitleMenu(id);
        case 34: ShowStyleMenu(id);
        case HUB_BACK: ShowMainMenu(id);
        case HUB_MARKET, HUB_CLASS, HUB_CHAR, HUB_FUN, HUB_VIPADM: ShowHub(id, sel);
    }
}

/* ---------------- Profil alt menusu ---------------- */

ShowProfileMenu(id)
{
    new title[320], item[64];
    VexHead(id, title, charsmax(title), "MENU_PROFILE");
    new menu = VexMenuCreate(title, "menu_profile_handler");

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
    new title[320], item[160], k1[12], k2[16], n1[32], n2[72];

    new hsub[128];
    formatex(hsub, charsmax(hsub), "%L", id, "MENU_JOB_SUB");
    VexHead(id, title, charsmax(title), "MENU_JOB", hsub);
    new menu = VexMenuCreate(title, "menu_job_handler");

    for (new i = 0; i < NUM_JOBS; i++)
    {
        formatex(k1, charsmax(k1), "JOB_%d", i);
        formatex(k2, charsmax(k2), "JOB_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        if (g_iLevel[id] < JOB_LVL[i])
            formatex(item, charsmax(item), "\y%s \r[Lv.%d] \r[%L]", n1, JOB_LVL[i], id, "MENU_LOCKED");
        else if (g_iJob[id] == i)
            formatex(item, charsmax(item), "\y%s \r[*\r] \d%s", n1, n2);
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
    new title[320], item[160], k1[12], k2[16], n1[32], n2[64];

    VexHead(id, title, charsmax(title), "MENU_STYLE");
    new menu = VexMenuCreate(title, "menu_style_handler");

    for (new i = 0; i < NUM_STYLES; i++)
    {
        formatex(k1, charsmax(k1), "STYLE_%d", i);
        formatex(k2, charsmax(k2), "STYLE_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        if (g_iStyle[id] == i)
            formatex(item, charsmax(item), "\y%s \r[*\r] \d%s", n1, n2);
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
    new title[320], item[96], key[12], onoff[32], tn[24];

    new hsub[128];
    formatex(hsub, charsmax(hsub), "%L", id, "MENU_SETTINGS_SUB");
    VexHead(id, title, charsmax(title), "MENU_SETTINGS", hsub);
    new menu = VexMenuCreate(title, "menu_settings_handler");

    for (new i = 0; i < 10; i++)
    {
        formatex(key, charsmax(key), "SET_%d", i);
        VexOnOff(id, (g_iSet[id] & (1 << i)) ? false : true, onoff, charsmax(onoff));
        formatex(item, charsmax(item), "\y%L %s", id, key, onoff);
        MenuAdd(menu, item, i);
    }

    formatex(key, charsmax(key), "THEME_%d", g_iTheme[id]);
    formatex(tn, charsmax(tn), "%L", id, key);
    formatex(item, charsmax(item), "\y%L \r[%s\r]", id, "SET_THEME", tn);
    MenuAdd(menu, item, 20);

    formatex(key, charsmax(key), "HUDPOS_%d", g_iHudPos[id]);
    formatex(tn, charsmax(tn), "%L", id, key);
    formatex(item, charsmax(item), "\y%L \r[%s\r]", id, "SET_HUDPOS", tn);
    MenuAdd(menu, item, 23);

    formatex(item, charsmax(item), "\y%L \r[%s\r]", id, "SET_LANG", g_iLang[id] == 2 ? "Turkce" : "English");
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
    new title[320];
    VexHead(id, title, charsmax(title), "MENU_LANG");
    new menu = VexMenuCreate(title, "menu_lang_handler");

    MenuAdd(menu, g_iLang[id] == 1 ? "\yEnglish \r[*\r]" : "\yEnglish", 1);
    MenuAdd(menu, g_iLang[id] == 2 ? "\yTurkce \r[*\r]" : "\yTurkce", 2);

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
    new title[320], item[96];
    new hsub[128];
    formatex(hsub, charsmax(hsub), "%L", id, "MENU_FPS_SUB");
    VexHead(id, title, charsmax(title), "MENU_FPS", hsub);
    new menu = VexMenuCreate(title, "menu_fps_handler");

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
    new title[320], item[96], key[12];
    new hsub[128];
    formatex(hsub, charsmax(hsub), "%L", id, "MENU_FUN_SUB");
    VexHead(id, title, charsmax(title), "MENU_FUN", hsub);
    new menu = VexMenuCreate(title, "menu_fun_handler");

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

/* ===== End module: players.inc ===== */
/* ================================================================== */
/*  BOLUM 12/13: ADMIN                                                */
/*  Admin menusu ve alt menuleri, admin konsol komutlari (mod /       */
/*  event / boss / AP / VC / XP / VIP).                               */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
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

    new title[320], item[96];
    new hsub[128];
    formatex(hsub, charsmax(hsub), "%L", id, "MENU_ADMIN_SUB");
    VexHead(id, title, charsmax(title), "MENU_ADMIN", hsub);
    new menu = VexMenuCreate(title, "menu_admin_handler");

    for (new i = 1; i <= 20; i++)
    {
        new key[12];
        formatex(key, charsmax(key), "ADMM_%d", i);
        formatex(item, charsmax(item), "\y%L", id, key);
        if (i == 17)
            add(item, charsmax(item), g_bRespawnOff ? " \r[OFF]" : " \y[ON]");
        else if (i == 18)
            add(item, charsmax(item), get_pcvar_num(g_pLmEnable) ? " \y[ON]" : " \r[OFF]");
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
    new title[320], item[96], key[16];
    VexHead(id, title, charsmax(title), "ADMM_8");
    new menu = VexMenuCreate(title, "menu_admenv");
    for (new i = 0; i <= 9; i++)
    {
        formatex(key, charsmax(key), "ADME_%d", i);
        formatex(item, charsmax(item), "\y%L", id, key);
        MenuAdd(menu, item, i);
    }
    formatex(item, charsmax(item), "\y%L", id, "ADME_CUSTOM");
    MenuAdd(menu, item, 10);
    MenuFinish(id, menu);
}

public menu_admenv(id, menu, item)
{
    if (item < 0 || !(get_user_flags(id) & ADMIN_BAN)) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new sel = MenuInfo(menu, item);
    menu_destroy(menu);
    if (sel == 10)
    {
        ShowAdminEnvDetail(id);
        return PLUGIN_HANDLED;
    }
    AdminSetEnv(sel);
    AdminNotify(id, sel == 0 ? "ADM_ENV_RESET" : "ADM_ENV_SET", sel);
    ShowAdminEnvMenu(id);
    return PLUGIN_HANDLED;
}

// 0 sifirla, 1 gunduz, 2 alacakaranlik, 3 gece, 4 yagmur, 5 kar, 6 sis, 7 firtina, 8 kan, 9 zifiri karanlik
AdminSetEnv(sel)
{
    if (sel <= 0)
    {
        g_bAdminEnvOverride = false;
        SetMapAmbienceMuted(false);
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
    g_bAdminEnvOverride = true;
    g_iAdminEnvLight = L[sel];
    for (new c = 0; c < 4; c++)
        g_iAdminEnvFog[c] = F[sel][c];
    g_iAdminEnvWeather = W[sel];
    ApplyWorldEvent();
    if (sel == 7)
        Lightning();
}

ShowAdminEnvDetail(id)
{
    if (!g_bAdminEnvOverride)
    {
        new light, fog[4], weather;
        CurrentEnv(light, fog, weather);
        g_iAdminEnvLight = light;
        for (new c = 0; c < 4; c++)
            g_iAdminEnvFog[c] = fog[c];
        g_iAdminEnvWeather = weather;
        g_bAdminEnvOverride = true;
    }

    new title[320], item[112], menu;
    new hsub[96];
    formatex(hsub, charsmax(hsub), "[\yL %c\r] [\yF %d\r] [\yRGB %d/%d/%d\r] [\yW %d\r]", g_iAdminEnvLight, g_iAdminEnvFog[3], g_iAdminEnvFog[0], g_iAdminEnvFog[1], g_iAdminEnvFog[2], g_iAdminEnvWeather);
    VexHead(id, title, charsmax(title), "ADME_DETAIL", hsub);
    menu = VexMenuCreate(title, "menu_admenv_detail");

    formatex(item, charsmax(item), "\y%L \r[%c]", id, "ADME_LIGHT", g_iAdminEnvLight); MenuAdd(menu, item, 1);
    formatex(item, charsmax(item), "\y%L \r[%d]", id, "ADME_FOG_DENSITY", g_iAdminEnvFog[3]); MenuAdd(menu, item, 2);
    formatex(item, charsmax(item), "\y%L \r[%d]", id, "ADME_FOG_RED", g_iAdminEnvFog[0]); MenuAdd(menu, item, 3);
    formatex(item, charsmax(item), "\y%L \r[%d]", id, "ADME_FOG_GREEN", g_iAdminEnvFog[1]); MenuAdd(menu, item, 4);
    formatex(item, charsmax(item), "\y%L \r[%d]", id, "ADME_FOG_BLUE", g_iAdminEnvFog[2]); MenuAdd(menu, item, 5);
    formatex(item, charsmax(item), "\y%L \r[%d]", id, "ADME_WEATHER", g_iAdminEnvWeather); MenuAdd(menu, item, 6);
    { new st[32]; VexOnOff(id, g_bAmbMuted ? false : true, st, charsmax(st)); formatex(item, charsmax(item), "\y%L %s", id, "ADME_MAP_AMBIENCE", st); MenuAdd(menu, item, 7); }
    formatex(item, charsmax(item), "\r%L", id, "ADME_ENV_RESET"); MenuAdd(menu, item, 8);
    formatex(item, charsmax(item), "\y%L", id, "MENU_BACK"); MenuAdd(menu, item, 9);
    MenuFinish(id, menu);
}

public menu_admenv_detail(id, menu, item)
{
    if (item < 0 || !(get_user_flags(id) & ADMIN_BAN)) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    if (sel == 9)
    {
        ShowAdminEnvMenu(id);
        return PLUGIN_HANDLED;
    }
    if (sel == 8)
    {
        g_bAdminEnvOverride = false;
        SetMapAmbienceMuted(false);
        ApplyWorldEvent();
        AdminNotify(id, "ADM_ENV_RESET", 0);
        ShowAdminEnvMenu(id);
        return PLUGIN_HANDLED;
    }

    switch (sel)
    {
        case 1:
        {
            g_iAdminEnvLight++;
            if (g_iAdminEnvLight > 'z') g_iAdminEnvLight = 'a';
        }
        case 2: g_iAdminEnvFog[3] = (g_iAdminEnvFog[3] >= 80) ? 0 : g_iAdminEnvFog[3] + 10;
        case 3: g_iAdminEnvFog[0] = (g_iAdminEnvFog[0] > 223) ? 0 : g_iAdminEnvFog[0] + 32;
        case 4: g_iAdminEnvFog[1] = (g_iAdminEnvFog[1] > 223) ? 0 : g_iAdminEnvFog[1] + 32;
        case 5: g_iAdminEnvFog[2] = (g_iAdminEnvFog[2] > 223) ? 0 : g_iAdminEnvFog[2] + 32;
        case 6: g_iAdminEnvWeather = (g_iAdminEnvWeather + 1) % 3;
        case 7: SetMapAmbienceMuted(!g_bAmbMuted);
    }
    ApplyWorldEvent();
    ShowAdminEnvDetail(id);
    return PLUGIN_HANDLED;
}

SetMapAmbienceMuted(bool:mute)
{
    g_bAmbMuted = mute;
    remove_task(TASK_AMBREST);
    if (mute)
    {
        for (new i = 0; i < g_iAmbN; i++)
        {
            if (!g_bAmbOn[i] || !g_szAmbSnd[i][0] || !pev_valid(g_iAmbEnt[i]))
                continue;
            emit_sound(g_iAmbEnt[i], CHAN_STATIC, g_szAmbSnd[i], 0.0, g_fAmbAttn[i], SND_STOP, g_iAmbPitch[i]);
        }
        return;
    }
    set_task(0.1, "task_AmbientRestore", TASK_AMBREST);
}

// now = true -> modu hemen baslat (round yeniden baslar)
ShowAdminModeMenu(id, bool:now)
{
    new title[320], item[96], key[16];
    if (now) VexHead(id, title, charsmax(title), "ADMM_2"); else VexHead(id, title, charsmax(title), "ADMM_1");
    new menu = VexMenuCreate(title, now ? "menu_admmode_now" : "menu_admmode_next");

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
    new title[320], item[96], key[16];
    VexHead(id, title, charsmax(title), "ADM_BOSS_PICK");
    new menu = VexMenuCreate(title, now ? "menu_admboss_now" : "menu_admboss_next");

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
    new title[320], item[96], key[16];
    if (now) VexHead(id, title, charsmax(title), "ADMM_4"); else VexHead(id, title, charsmax(title), "ADMM_3");
    new menu = VexMenuCreate(title, now ? "menu_admevent_now" : "menu_admevent");

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
    new title[320], item[96], name[32];
    VexHead(id, title, charsmax(title), "ADMM_4");
    new menu = VexMenuCreate(title, "menu_admplayers");

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p))
            continue;
        get_user_name(p, name, charsmax(name));
        formatex(item, charsmax(item), "\y%s \r[%s%s\r]", name, g_bZombie[p] ? "Z" : "H", IsVip(p) ? (IsElite(p) ? " ELITE" : " VIP") : "");
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

    new title[320], item[96], name[32];
    get_user_name(target, name, charsmax(name));
    new hsub[96];
    formatex(hsub, charsmax(hsub), "[\y%s\r] [\yLv %d\r] [\y%d AP\r] [\y%d VC\r]", name, g_iLevel[target], g_iAP[target], g_iVC[target]);
    VexHead(id, title, charsmax(title), "ADMM_4", hsub);
    new menu = VexMenuCreate(title, "menu_admactions");

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

/* ===== End module: admin.inc ===== */
/* ================================================================== */
/*  BOLUM 13/13: HARITALAR                                            */
/*  Harita oylamasi, Rock The Vote, sonraki harita, harita            */
/*  degisimi, harita ortam sesleri (ambient_generic geri yukleme).    */
/*  Bolum haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ================================================================== */
/*  FX / YARDIMCILAR                                                   */
/* ================================================================== */

/* ---------------- v3.0 (C): harita ortam sesleri (ambient_generic) ---------------- */
// Oyun (ReGameDLL) her round basinda dongulu ambient_generic seslerini yeniden calar, ama
// eklentinin "stopsound" komutu istemcide ayni karede islenince onlari da susturur. Bu yuzden
// her ambient_generic'in son durumu (ses / ses duzeyi / perde / acik-kapali) kaydedilir ve
// "stopsound"dan sonra sadece ACIK + DONGULU olanlar yeniden calinir. Eklenti sesleri
// (spk / mp3 / emit) yeniden calinmaz: round sonunda susma garantisi aynen gecerli.
public fw_AmbientPost(ent, const Float:pos[3], const sample[], Float:vol, Float:attn, flags, pitch)
{
    if (g_bAmbReplay || ent <= MaxClients || !pev_valid(ent) || !sample[0])
        return FMRES_IGNORED;
    new cls[20];
    pev(ent, pev_classname, cls, charsmax(cls));
    if (!equal(cls, "ambient_generic") || (pev(ent, pev_spawnflags) & 32))   // 32 = dongusuz (tek sefer)
        return FMRES_IGNORED;

    new slot = -1;
    for (new i = 0; i < g_iAmbN; i++)
    {
        if (g_iAmbEnt[i] == ent)
        {
            slot = i;
            break;
        }
    }
    if (slot < 0)
    {
        if (g_iAmbN >= MAX_AMB)
            return FMRES_IGNORED;
        slot = g_iAmbN++;
        g_iAmbEnt[slot] = ent;
        g_bAmbOn[slot] = false;
    }

    if (flags & SND_STOP)
    {
        g_bAmbOn[slot] = false;
        return FMRES_IGNORED;
    }
    if (flags & (SND_CHANGE_VOL | SND_CHANGE_PITCH))
    {
        // Rampa / perde degisimi: sadece calan ses guncellenir
        if (flags & SND_CHANGE_VOL)
            g_fAmbVol[slot] = vol;
        if (flags & SND_CHANGE_PITCH)
            g_iAmbPitch[slot] = pitch;
        return g_bAmbMuted ? FMRES_SUPERCEDE : FMRES_IGNORED;
    }
    copy(g_szAmbSnd[slot], charsmax(g_szAmbSnd[]), sample);
    g_fAmbVol[slot] = vol;
    g_fAmbAttn[slot] = attn;
    g_iAmbPitch[slot] = pitch;
    g_bAmbOn[slot] = true;   // ses duzeyi 0 olsa bile (spin-up rampasi) sonraki degisimler bu kanala uygulanir
    if (g_bAmbMuted)
        return FMRES_SUPERCEDE;
    return FMRES_IGNORED;
}

public task_AmbientRestore()
{
    if (g_bAmbMuted)
        return;
    new Float:o[3], n;
    g_bAmbReplay = true;
    for (new i = 0; i < g_iAmbN; i++)
    {
        new ent = g_iAmbEnt[i];
        if (!g_bAmbOn[i] || !g_szAmbSnd[i][0] || !pev_valid(ent))
            continue;
        pev(ent, pev_origin, o);
        engfunc(EngFunc_EmitAmbientSound, ent, o, g_szAmbSnd[i], g_fAmbVol[i], g_fAmbAttn[i], 0, g_iAmbPitch[i]);
        n++;
    }
    g_bAmbReplay = false;
    if (n)
        g_iAmbRestored++;
}


/* ================================================================== */
/*  v3.3: HARITA SENARYOSU (devtools/MAP_CONTRACT.md)                  */
/*  - Eklenti -> harita: vex_* targetname'li varliklari olaylarda      */
/*    tetikler (liste harita basinda bir kez kurulur, tetik = dongu).  */
/*  - Harita -> eklenti: vexcmd_* trigger_relay'leri (isimler harita   */
/*    basinda cozulur, Use'ta sadece dizi okunur).                     */
/*  - configs/vexmira_maps/<harita>.ini: hikaye, gorevler, mesajlar,   */
/*    ek olaylar, yon isaretleri. Dosya yoksa ozellik kapali.          */
/*  Kare basina tek is: isaretlerin insanlara gorunurluk filtresi      */
/*  (fw_AddToFullPackPost, sadece isaret varliklari icin).             */
/* ================================================================== */

#define ME_NUM        12
#define ME_MAXENT     256
#define MS_MAXCMD     48
#define MS_MAXMSG     32
#define MS_MAXEX      32
#define MS_LEN        112
#define MS_CHART      0.035   // daktilo: harf basina sure (sn)
#define TASK_MSSTORY  42000   // +id
#define TASK_MSEX     42100   // +0..31 (gecikmeli ek olaylar)
#define TASK_MSRS     42200   // round basi tetigi (harita varliklari geri yuklendikten sonra)

new const ME_NAME[ME_NUM][] = { "round_start", "freeze_end", "infection", "boss", "boss_dead", "nemesis",
    "assassin", "survivor", "lasthuman", "win_humans", "win_zombies", "minute" };

#define MC_MSG 1
#define MC_RH  2
#define MC_RZ  3
#define MC_OBJ 4

new g_pMsStory, g_pMsObj, g_pMsMarkers, g_pMsRewards, g_pMsEvents, g_pMsDebug;
new g_iMeEnt[ME_MAXENT], g_iMeTn[ME_MAXENT], g_iMeN, g_iMeFirst[ME_NUM], g_iMeCnt[ME_NUM];
new bool:g_bMsIni, g_szMsName[2][48];
new g_szMsStory[2][6][MS_LEN], g_iMsStoryN[2];
new g_szMsObj[2][3][MS_LEN], g_iMsObjN;
new g_szMsMsgKey[MS_MAXMSG][24], g_szMsMsg[MS_MAXMSG][2][MS_LEN], g_iMsMsgN;
new g_iMsExEv[MS_MAXEX], Float:g_fMsExDelay[MS_MAXEX], g_iMsExFirst[MS_MAXEX], g_iMsExCnt[MS_MAXEX], g_iMsExN;
new g_szMsMkName[MS_MAXMK][2][32], Float:g_fMsMkPos[MS_MAXMK][3], g_iMsMkSpr[MS_MAXMK], g_iMsMkBeam[MS_MAXMK], g_iMsMkN;
new g_iMsCmdOf[OVH_MAXENT];   // varlik -> komut + 1
new g_iMsCmdType[MS_MAXCMD], g_iMsCmdArg[MS_MAXCMD], g_iMsCmdRound[MS_MAXCMD], Float:g_fMsCmdNext[MS_MAXCMD], g_iMsCmdN;
new g_iMsRound = 1, bool:g_bMsObjDone[3], bool:g_bMsLive, g_iMsSec, Float:g_fMsMsgNext;
new bool:g_bMsSeen[33], g_iMsStep[33], g_iMsTries[33];
new g_szMsSndLine[96], g_szMsSndMsg[96], g_szMsSndObj[96];
// v3.5.1 [locks] / [hints]: func_button targetname -> gerekli gorev + mesaj (harita basinda cozulur)
#define MS_MAXLK 8
new g_szMsLkTn[MS_MAXLK][32], g_szMsLkKey[MS_MAXLK][24], g_iMsLkObj[MS_MAXLK], bool:g_bMsLkHint[MS_MAXLK];
new g_iMsLkMsg[MS_MAXLK], g_iMsLkRound[MS_MAXLK], g_iMsLkN, bool:g_bMsSeq;
new g_iMsLockOf[OVH_MAXENT];   // varlik -> kilit + 1
new Float:g_fMsLkNext[33];

stock MsLang(id)
{
    return g_iLang[id] == 2 ? 1 : 0;
}

// plugin_init: cvar'lar, komutlar, senaryo dosyasi, varlik listeleri, isaretler, relay kancasi
MsInit()
{
    g_pMsStory   = register_cvar("vex_map_story", "1");
    g_pMsObj     = register_cvar("vex_map_objectives", "1");
    g_pMsMarkers = register_cvar("vex_map_markers", "1");
    g_pMsRewards = register_cvar("vex_map_rewards", "1");
    g_pMsEvents  = register_cvar("vex_map_events", "1");
    g_pMsDebug   = register_cvar("vex_map_debug", "0");
    RegisterSay("story", "hikaye", "cmd_MsStory");
    register_srvcmd("vex_map_status", "srv_MsStatus");

    TrieGetString(g_tRes, "UI_OPEN", g_szMsSndLine, charsmax(g_szMsSndLine));
    TrieGetString(g_tRes, "ZONE_WARN", g_szMsSndMsg, charsmax(g_szMsSndMsg));
    TrieGetString(g_tRes, "QUEST_DONE", g_szMsSndObj, charsmax(g_szMsSndObj));

    MsLoadIni();

    // vex_* olay hedefleri (harita varliklari plugin_init'te hazir)
    new name[32];
    for (new e = 0; e < ME_NUM; e++)
    {
        formatex(name, charsmax(name), "vex_%s", ME_NAME[e]);
        g_iMeFirst[e] = g_iMeN;
        g_iMeCnt[e] = MsCollect(name);
    }

    // vexcmd_* trigger_relay'ler
    new ent = -1, tn[64];
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "trigger_relay")) > 0)
    {
        pev(ent, pev_targetname, tn, charsmax(tn));
        if (equal(tn, "vexcmd_", 7) && ent < OVH_MAXENT)
            MsParseCmd(ent, tn);
    }
    if (g_iMsCmdN)
        RegisterHam(Ham_Use, "trigger_relay", "fw_MsRelayUse", 0);

    for (new m = 0; m < g_iMsMkN; m++)
        MsMkCreate(m);
    MsLockInit();

    new total;
    for (new e = 0; e < ME_NUM; e++)
        total += g_iMeCnt[e];
    log_amx("[Vexmira] Harita senaryosu: ini=%d hikaye=%d/%d gorev=%d mesaj=%d ek-olay=%d isaret=%d | vex_* hedef=%d vexcmd=%d",
        g_bMsIni, g_iMsStoryN[0], g_iMsStoryN[1], g_iMsObjN, g_iMsMsgN, g_iMsExN, g_iMsMkN, total, g_iMsCmdN);
}

// [locks] / [hints]: mesaj anahtari + func_button varliklari bir kez cozulur; Use'ta sadece dizi okunur
MsLockInit()
{
    new hooked, ent, n, cls[32];
    for (new k = 0; k < g_iMsLkN; k++)
    {
        g_iMsLkMsg[k] = -1;
        for (new i = 0; i < g_iMsMsgN; i++)
        {
            if (equali(g_szMsLkKey[k], g_szMsMsgKey[i]))
            {
                g_iMsLkMsg[k] = i;
                break;
            }
        }
        n = 0;
        ent = -1;
        while ((ent = engfunc(EngFunc_FindEntityByString, ent, "targetname", g_szMsLkTn[k])) > 0)
        {
            pev(ent, pev_classname, cls, charsmax(cls));
            if (ent < OVH_MAXENT && equal(cls, "func_button"))
            {
                g_iMsLockOf[ent] = k + 1;
                n++;
            }
        }
        if (g_iMsLkMsg[k] < 0 || !n)
            log_amx("[Vexmira] map kilit '%s' yok sayildi (mesaj=%d buton=%d)", g_szMsLkTn[k], g_iMsLkMsg[k] + 1, n);
        else
            hooked++;
    }
    if (hooked)
        RegisterHam(Ham_Use, "func_button", "fw_MsButtonUse", 0);
}

public fw_MsButtonUse(ent, caller, activator, type, Float:value)
{
    if (ent <= 0 || ent >= OVH_MAXENT || !g_iMsLockOf[ent] || !(1 <= activator <= g_iMax))
        return HAM_IGNORED;
    new k = g_iMsLockOf[ent] - 1, msg = g_iMsLkMsg[k];
    if (msg < 0 || g_bMsObjDone[g_iMsLkObj[k]] || !is_user_connected(activator))
        return HAM_IGNORED;
    if (g_bMsLkHint[k])
    {
        // ipucu: bu gorev icin round basina ilk basista tum insanlara
        for (new j = 0; j < g_iMsLkN; j++)
        {
            if (g_bMsLkHint[j] && g_iMsLkObj[j] == g_iMsLkObj[k] && g_iMsLkRound[j] == g_iMsRound)
                return HAM_IGNORED;
        }
        g_iMsLkRound[k] = g_iMsRound;
        if (get_pcvar_num(g_pMsDebug))
            log_amx("[Vexmira] map ipucu '%s' #%d -> %s", g_szMsLkTn[k], activator, g_szMsMsgKey[msg]);
        for (new id = 1; id <= g_iMax; id++)
        {
            if (!is_user_connected(id) || is_user_bot(id) || (is_user_alive(id) && g_bZombie[id]))
                continue;
            HudText(id, SL_ANN, CLR_WARN, 4.0, g_szMsMsg[msg][MsLang(id)]);
            client_print(id, print_console, "%s", g_szMsMsg[msg][MsLang(id)]);
        }
        return HAM_IGNORED;
    }
    // kilit: gorev tamamlanmadi -> basan oyuncuya kisa uyari (2 sn'de bir)
    new Float:now = get_gametime();
    if (now < g_fMsLkNext[activator])
        return HAM_IGNORED;
    g_fMsLkNext[activator] = now + 2.0;
    if (get_pcvar_num(g_pMsDebug))
        log_amx("[Vexmira] map kilit '%s' #%d: gorev %d bitmedi -> %s", g_szMsLkTn[k], activator, g_iMsLkObj[k] + 1, g_szMsMsgKey[msg]);
    if (!is_user_bot(activator))
    {
        HudText(activator, SL_ALERT, CLR_WARN, 2.5, g_szMsMsg[msg][MsLang(activator)]);
        client_print(activator, print_console, "%s", g_szMsMsg[msg][MsLang(activator)]);
    }
    return HAM_IGNORED;
}

// Isaret gorunurlugu: sirali modda sadece ilk acik gorevin isareti
MsMkRefresh()
{
    new bool:mk = get_pcvar_num(g_pMsMarkers) != 0, cur = -1;
    for (new k = 0; k < g_iMsObjN; k++)
    {
        if (!g_bMsObjDone[k])
        {
            cur = k;
            break;
        }
    }
    for (new m = 0; m < g_iMsMkN; m++)
        MsMkShow(m, mk && (m >= g_iMsObjN || (!g_bMsObjDone[m] && (!g_bMsSeq || m == cur))));
}

// targetname'i 'name' olan tum varliklari duz listeye ekler, eklenen sayiyi dondurur
MsCollect(const name[])
{
    new ent = -1, n;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "targetname", name)) > 0)
    {
        if (g_iMeN >= ME_MAXENT)
        {
            log_amx("[Vexmira] Harita senaryosu: hedef listesi dolu (%d), %s atlandi", ME_MAXENT, name);
            break;
        }
        g_iMeEnt[g_iMeN] = ent;
        g_iMeTn[g_iMeN] = pev(ent, pev_targetname);   // string_t: varlik silinip yeri baskasina gecerse ayirt edilir
        g_iMeN++;
        n++;
    }
    return n;
}

MsParseCmd(ent, const tn[])
{
    if (g_iMsCmdN >= MS_MAXCMD)
    {
        log_amx("[Vexmira] Harita senaryosu: en fazla %d vexcmd, %s atlandi", MS_MAXCMD, tn);
        return;
    }
    new type, arg = -1;
    if (equal(tn[7], "msg_", 4))
    {
        for (new i = 0; i < g_iMsMsgN; i++)
        {
            if (equali(tn[11], g_szMsMsgKey[i]))
            {
                arg = i;
                break;
            }
        }
        type = MC_MSG;
    }
    else if (equal(tn[7], "reward_h_", 9) || equal(tn[7], "reward_z_", 9))
    {
        type = (tn[14] == 'h') ? MC_RH : MC_RZ;
        arg = str_to_num(tn[16]);
        if (!isdigit(tn[16]) || arg < 1 || arg > 50)
            arg = -1;
    }
    else if (equal(tn[7], "obj_", 4) && tn[11] >= '1' && tn[11] <= '3' && equal(tn[12], "_done"))
    {
        type = MC_OBJ;
        arg = tn[11] - '1';
    }
    if (!type || arg < 0)
    {
        log_amx("[Vexmira] Harita senaryosu: tanimsiz vexcmd '%s' (varlik %d) yok sayildi", tn, ent);
        return;
    }
    g_iMsCmdType[g_iMsCmdN] = type;
    g_iMsCmdArg[g_iMsCmdN] = arg;
    g_iMsCmdRound[g_iMsCmdN] = 0;
    g_iMsCmdN++;
    g_iMsCmdOf[ent] = g_iMsCmdN;
}

/* ---------------- senaryo dosyasi ---------------- */
#define MSS_NONE  0
#define MSS_INFO  1
#define MSS_STORY 2
#define MSS_OBJ   3
#define MSS_MSG   4
#define MSS_EV    5
#define MSS_MK    6
#define MSS_LOCK  7
#define MSS_HINT  8

MsLoadIni()
{
    new map[32], path[160];
    get_mapname(map, charsmax(map));
    get_configsdir(path, charsmax(path));
    format(path, charsmax(path), "%s/vexmira_maps/%s.ini", path, map);
    new fp = fopen(path, "rt");
    if (!fp)
        return;
    g_bMsIni = true;

    new line[256], sec = MSS_NONE, lang, ln, bad, objN[2];
    new key[64], val[192], a[MS_LEN], b[MS_LEN];
    while (!feof(fp))
    {
        fgets(fp, line, charsmax(line));
        ln++;
        // satir sonu yorumu (" ;") ve basta yorum
        new c = contain(line, " ;");
        if (c != -1)
            line[c] = 0;
        trim(line);
        if (!line[0] || line[0] == ';' || line[0] == '#' || (line[0] == '/' && line[1] == '/'))
            continue;

        if (line[0] == '[')
        {
            lang = 0;
            if (equali(line, "[info]"))              sec = MSS_INFO;
            else if (equali(line, "[story_en]"))     sec = MSS_STORY;
            else if (equali(line, "[story_tr]"))     { sec = MSS_STORY; lang = 1; }
            else if (equali(line, "[objective_en]")) sec = MSS_OBJ;
            else if (equali(line, "[objective_tr]")) { sec = MSS_OBJ; lang = 1; }
            else if (equali(line, "[messages]"))     sec = MSS_MSG;
            else if (equali(line, "[events]"))       sec = MSS_EV;
            else if (equali(line, "[markers]"))      sec = MSS_MK;
            else if (equali(line, "[locks]"))        { sec = MSS_LOCK; g_bMsSeq = true; }
            else if (equali(line, "[hints]"))        sec = MSS_HINT;
            else
            {
                sec = MSS_NONE;
                MsBad(path, ln, line, bad);
            }
            continue;
        }

        if (sec == MSS_EV)
        {
            if (!MsParseEvent(line))
                MsBad(path, ln, line, bad);
            continue;
        }

        // anahtar = deger
        new eq = contain(line, "=");
        if (eq < 1 || sec == MSS_NONE)
        {
            MsBad(path, ln, line, bad);
            continue;
        }
        copy(key, min(eq, charsmax(key)), line);
        copy(val, charsmax(val), line[eq + 1]);
        trim(key);
        trim(val);
        if (!val[0])
        {
            MsBad(path, ln, line, bad);
            continue;
        }

        switch (sec)
        {
            case MSS_INFO:
            {
                if (equali(key, "name_en"))      copy(g_szMsName[0], charsmax(g_szMsName[]), val);
                else if (equali(key, "name_tr")) copy(g_szMsName[1], charsmax(g_szMsName[]), val);
                else if (equali(key, "sequential")) g_bMsSeq = str_to_num(val) != 0;
                else MsBad(path, ln, line, bad);
            }
            case MSS_STORY:
            {
                if (!equali(key, "line") || g_iMsStoryN[lang] >= 6)
                    MsBad(path, ln, line, bad);
                else
                    copy(g_szMsStory[lang][g_iMsStoryN[lang]++], MS_LEN - 1, val);
            }
            case MSS_OBJ:
            {
                if (!equali(key, "line") || objN[lang] >= 3)
                    MsBad(path, ln, line, bad);
                else
                    copy(g_szMsObj[lang][objN[lang]++], MS_LEN - 1, val);
            }
            case MSS_MSG:
            {
                if (g_iMsMsgN >= MS_MAXMSG || strlen(key) > 23)
                {
                    MsBad(path, ln, line, bad);
                    continue;
                }
                MsSplitPipe(val, a, b);
                copy(g_szMsMsgKey[g_iMsMsgN], charsmax(g_szMsMsgKey[]), key);
                // SL_ANN susu burada bir kez eklenir (kullanimda bicimlendirme yok)
                formatex(g_szMsMsg[g_iMsMsgN][0], MS_LEN - 1, "-=[  %s  ]=-", a);
                formatex(g_szMsMsg[g_iMsMsgN][1], MS_LEN - 1, "-=[  %s  ]=-", b);
                g_iMsMsgN++;
            }
            case MSS_LOCK, MSS_HINT:
            {
                // <button targetname> = <gorev no 1-3> <mesaj anahtari>
                new so[8], sk[24];
                if (g_iMsLkN >= MS_MAXLK || strlen(key) > 31 || parse(val, so, charsmax(so), sk, charsmax(sk)) != 2
                    || !(1 <= str_to_num(so) <= 3))
                {
                    MsBad(path, ln, line, bad);
                    continue;
                }
                copy(g_szMsLkTn[g_iMsLkN], 31, key);
                copy(g_szMsLkKey[g_iMsLkN], 23, sk);
                g_iMsLkObj[g_iMsLkN] = str_to_num(so) - 1;
                g_bMsLkHint[g_iMsLkN] = sec == MSS_HINT;
                g_iMsLkN++;
            }
            case MSS_MK:
            {
                new Float:p[3], sx[16], sy[16], sz[16];
                if (g_iMsMkN >= MS_MAXMK || parse(val, sx, charsmax(sx), sy, charsmax(sy), sz, charsmax(sz)) != 3)
                {
                    MsBad(path, ln, line, bad);
                    continue;
                }
                p[0] = str_to_float(sx);
                p[1] = str_to_float(sy);
                p[2] = str_to_float(sz);
                if (floatabs(p[0]) > 4096.0 || floatabs(p[1]) > 4096.0 || floatabs(p[2]) > 4096.0)
                {
                    MsBad(path, ln, line, bad);
                    continue;
                }
                MsSplitPipe(key, a, b);
                copy(g_szMsMkName[g_iMsMkN][0], 31, a);
                copy(g_szMsMkName[g_iMsMkN][1], 31, b);
                g_fMsMkPos[g_iMsMkN] = p;
                g_iMsMkN++;
            }
        }
    }
    fclose(fp);

    // Eksik dil: diger dilden doldur
    for (new l = 0; l < 2; l++)
    {
        new o = 1 - l;
        if (!g_szMsName[l][0])
            copy(g_szMsName[l], charsmax(g_szMsName[]), g_szMsName[o]);
        if (!g_iMsStoryN[l])
        {
            for (new i = 0; i < g_iMsStoryN[o]; i++)
                copy(g_szMsStory[l][i], MS_LEN - 1, g_szMsStory[o][i]);
            g_iMsStoryN[l] = g_iMsStoryN[o];
        }
    }
    g_iMsObjN = max(objN[0], objN[1]);
    for (new i = 0; i < g_iMsObjN; i++)
    {
        if (!g_szMsObj[0][i][0]) copy(g_szMsObj[0][i], MS_LEN - 1, g_szMsObj[1][i]);
        if (!g_szMsObj[1][i][0]) copy(g_szMsObj[1][i], MS_LEN - 1, g_szMsObj[0][i]);
    }
    if (bad)
        log_amx("[Vexmira] %s: %d hatali satir atlandi", path, bad);
}

MsBad(const path[], ln, const line[], &bad)
{
    bad++;
    if (bad <= 8)
        log_amx("[Vexmira] %s satir %d atlandi: %s", path, ln, line);
}

// "English | Turkce" -> a / b (Turkce yoksa Ingilizce)
MsSplitPipe(const src[], a[MS_LEN], b[MS_LEN])
{
    new p = contain(src, "|");
    if (p == -1)
    {
        copy(a, MS_LEN - 1, src);
        copy(b, MS_LEN - 1, src);
    }
    else
    {
        copy(a, min(p, MS_LEN - 1), src);
        copy(b, MS_LEN - 1, src[p + 1]);
    }
    trim(a);
    trim(b);
    if (!b[0])
        copy(b, MS_LEN - 1, a);
    if (!a[0])
        copy(a, MS_LEN - 1, b);
}

// "<olay> <gecikme sn> <targetname>"
bool:MsParseEvent(const line[])
{
    new ev[24], dl[16], tn[64];
    if (g_iMsExN >= MS_MAXEX || parse(line, ev, charsmax(ev), dl, charsmax(dl), tn, charsmax(tn)) != 3)
        return false;
    new e = -1;
    for (new i = 0; i < ME_NUM; i++)
    {
        if (equali(ev, ME_NAME[i]))
        {
            e = i;
            break;
        }
    }
    new Float:d = str_to_float(dl);
    if (e < 0 || d < 0.0 || d > 600.0 || !tn[0])
        return false;
    g_iMsExEv[g_iMsExN] = e;
    g_fMsExDelay[g_iMsExN] = d;
    g_iMsExFirst[g_iMsExN] = g_iMeN;
    g_iMsExCnt[g_iMsExN] = MsCollect(tn);
    if (!g_iMsExCnt[g_iMsExN])
        log_amx("[Vexmira] Harita senaryosu: [events] '%s' hedefi haritada yok", tn);
    g_iMsExN++;
    return true;
}

/* ---------------- yon isaretleri ---------------- */
MsMkCreate(m)
{
    new Float:o[3], Float:top[3];
    o = g_fMsMkPos[m];
    if (g_szSprBeacon[0])
    {
        new spr = rg_create_entity("info_target");
        if (!is_nullent(spr) && spr < OVH_MAXENT)
        {
            set_entvar(spr, var_classname, "vex_mapmarker");
            engfunc(EngFunc_SetModel, spr, g_szSprBeacon);
            set_entvar(spr, var_rendermode, kRenderTransAdd);
            set_entvar(spr, var_renderamt, 210.0);
            set_entvar(spr, var_rendercolor, Float:{0.0, 200.0, 255.0});
            set_entvar(spr, var_renderfx, kRenderFxPulseSlow);
            set_entvar(spr, var_scale, 0.55);
            set_entvar(spr, var_movetype, MOVETYPE_NONE);
            set_entvar(spr, var_solid, SOLID_NOT);
            engfunc(EngFunc_SetOrigin, spr, o);
            g_iMsMkSpr[m] = spr;
            g_iMsMkOf[spr] = m + 1;
        }
    }
    // Isik sutunu: uzaktan gorulen hedef (ayni gorunurluk filtresi)
    top = o;
    top[2] += 360.0;
    new beam = BeamCreate(o, top, 0, 170, 255, 26, 90);
    if (beam && beam < OVH_MAXENT)
    {
        set_entvar(beam, var_classname, "vex_mapmarker");
        g_iMsMkBeam[m] = beam;
        g_iMsMkOf[beam] = m + 1;
    }
}

MsMkShow(m, bool:on)
{
    new e;
    for (new i = 0; i < 2; i++)
    {
        e = i ? g_iMsMkBeam[m] : g_iMsMkSpr[m];
        if (!e || !pev_valid(e))
            continue;
        if (on)
            set_entvar(e, var_effects, get_entvar(e, var_effects) & ~EF_NODRAW);
        else
            set_entvar(e, var_effects, get_entvar(e, var_effects) | EF_NODRAW);
    }
}

// Isaret bu oyuncuya gizli mi: sadece insanlar gorur (canli insan / olu CT izleyici)
bool:MsMkHidden(host)
{
    if (is_user_alive(host))
        return g_bZombie[host] != 0;
    new TeamName:t = get_member(host, m_iTeam);
    return t != TEAM_CT;
}

// fw_AddToFullPackPost: sadece isaret varliklari icin cagrilir
MsMkPack(es, host)
{
    if (MsMkHidden(host))
        set_es(es, ES_Effects, get_es(es, ES_Effects) | EF_NODRAW);
    return FMRES_IGNORED;
}

// Sunucu konsolu: vex_map_status (senaryo durumu + isaretlerin kime gorundugu)
public srv_MsStatus()
{
    new map[32];
    get_mapname(map, charsmax(map));
    log_amx("[Vexmira] map durum %s: ini=%d round=%d live=%d sn=%d gorev=%d done=%d%d%d isaret=%d komut=%d",
        map, g_bMsIni, g_iMsRound, g_bMsLive, g_iMsSec, g_iMsObjN, g_bMsObjDone[0], g_bMsObjDone[1], g_bMsObjDone[2], g_iMsMkN, g_iMsCmdN);
    for (new m = 0; m < g_iMsMkN; m++)
    {
        new see, hid;
        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_connected(p))
                continue;
            if (MsMkHidden(p))
                hid++;
            else
                see++;
        }
        new spr = g_iMsMkSpr[m], beam = g_iMsMkBeam[m];
        log_amx("[Vexmira] map isaret %d '%s': sprite #%d beam #%d nodraw=%d | gorebilen=%d gizli=%d",
            m + 1, g_szMsMkName[m][0], spr, beam, spr ? ((get_entvar(spr, var_effects) & EF_NODRAW) ? 1 : 0) : -1, see, hid);
    }
    return PLUGIN_HANDLED;
}

/* ---------------- olaylar: eklenti -> harita ---------------- */
MsFireRange(first, cnt)
{
    for (new i = first, end = first + cnt; i < end; i++)
    {
        new ent = g_iMeEnt[i];
        if (pev_valid(ent) && pev(ent, pev_targetname) == g_iMeTn[i])
            ExecuteHamB(Ham_Use, ent, 0, 0, 3, 0.0);   // 3 = USE_TOGGLE (trigger_relay gibi)
    }
}

MsEvent(ev)
{
    if (!get_pcvar_num(g_pMsEvents))
        return;
    if (g_iMeCnt[ev])
        MsFireRange(g_iMeFirst[ev], g_iMeCnt[ev]);
    for (new x = 0; x < g_iMsExN; x++)
    {
        if (g_iMsExEv[x] != ev || !g_iMsExCnt[x])
            continue;
        if (g_fMsExDelay[x] <= 0.0)
            MsFireRange(g_iMsExFirst[x], g_iMsExCnt[x]);
        else
            set_task(g_fMsExDelay[x], "task_MsExtra", TASK_MSEX + x);
    }
    if (get_pcvar_num(g_pMsDebug))
        log_amx("[Vexmira] map olay: vex_%s (%d hedef)", ME_NAME[ev], g_iMeCnt[ev]);
}

public task_MsExtra(tid)
{
    new x = tid - TASK_MSEX;
    if (x >= 0 && x < g_iMsExN)
    {
        MsFireRange(g_iMsExFirst[x], g_iMsExCnt[x]);
        if (get_pcvar_num(g_pMsDebug))
            log_amx("[Vexmira] map ek olay %d (%s +%.1f sn, %d hedef)", x, ME_NAME[g_iMsExEv[x]], g_fMsExDelay[x], g_iMsExCnt[x]);
    }
}

// rg_RestartRound (pre): durum sifirlanir; tetik, oyun haritayi geri yukledikten sonra
MsRoundRestart()
{
    g_iMsRound++;
    g_bMsLive = false;
    g_iMsSec = 0;
    for (new k = 0; k < 3; k++)
        g_bMsObjDone[k] = false;
    for (new x = 0; x < g_iMsExN; x++)
        remove_task(TASK_MSEX + x);
    remove_task(TASK_MSRS);
    set_task(0.2, "task_MsRoundStart", TASK_MSRS);
}

public task_MsRoundStart()
{
    MsMkRefresh();
    MsEvent(ME_ROUND_START);
}

MsFreezeEnd()
{
    g_bMsLive = true;
    g_iMsSec = 0;
    MsEvent(ME_FREEZE_END);
    if (g_iMsObjN && get_pcvar_num(g_pMsObj))
    {
        for (new id = 1; id <= g_iMax; id++)
        {
            if (is_user_connected(id) && (!is_user_bot(id) || get_pcvar_num(g_pMsDebug) >= 2))
                MsShowObjectives(id, true);
        }
    }
}

MsRoundEnd(WinStatus:status, bool:wasActive)
{
    g_bMsLive = false;
    if (!wasActive)
        return;
    if (status == WINSTATUS_CTS)
        MsEvent(ME_WIN_HUMANS);
    else if (status == WINSTATUS_TERRORISTS)
        MsEvent(ME_WIN_ZOMBIES);
}

// StartMode sonunda: mod basladi + moda ozel olaylar
MsModeStart()
{
    MsEvent(ME_INFECTION);
    switch (g_iMode)
    {
        case MODE_NEMESIS:  MsEvent(ME_NEMESIS);
        case MODE_ASSASSIN: MsEvent(ME_ASSASSIN);
        case MODE_SURVIVOR, MODE_SNIPER: MsEvent(ME_SURVIVOR);
        case MODE_PLAGUE:
        {
            MsEvent(ME_NEMESIS);
            MsEvent(ME_SURVIVOR);
        }
    }
}

// task_Tick (1 sn): round icinde her 60 sn
MsTick()
{
    if (g_bMsLive && ++g_iMsSec % 60 == 0)
        MsEvent(ME_MINUTE);
}

/* ---------------- komutlar: harita -> eklenti ---------------- */
public fw_MsRelayUse(ent, caller, activator, type, Float:value)
{
    if (ent > 0 && ent < OVH_MAXENT && g_iMsCmdOf[ent])
        MsCommand(g_iMsCmdOf[ent] - 1);
    return HAM_IGNORED;
}

MsCommand(c)
{
    new arg = g_iMsCmdArg[c];
    if (get_pcvar_num(g_pMsDebug))
        log_amx("[Vexmira] map komut %d tur=%d arg=%d round=%d", c, g_iMsCmdType[c], arg, g_iMsRound);
    switch (g_iMsCmdType[c])
    {
        case MC_MSG:
        {
            new Float:now = get_gametime();
            if (now < g_fMsCmdNext[c] || now < g_fMsMsgNext)
                return;
            g_fMsCmdNext[c] = now + 4.0;
            g_fMsMsgNext = now + 1.0;
            for (new id = 1; id <= g_iMax; id++)
            {
                if (!is_user_connected(id) || is_user_bot(id))
                    continue;
                new l = MsLang(id);
                HudText(id, SL_ANN, CLR_WARN, 4.0, g_szMsMsg[arg][l]);
                client_print(id, print_console, "%s", g_szMsMsg[arg][l]);
            }
            if (g_szMsSndMsg[0])
                client_cmd(0, "spk ^"%s^"", g_szMsSndMsg);
        }
        case MC_RH, MC_RZ:
        {
            if (!get_pcvar_num(g_pMsRewards) || g_bRoundEnded || g_iMsCmdRound[c] == g_iMsRound)
                return;
            g_iMsCmdRound[c] = g_iMsRound;
            new bool:z = g_iMsCmdType[c] == MC_RZ;
            for (new id = 1; id <= g_iMax; id++)
            {
                if (!is_user_alive(id) || (g_bZombie[id] != 0) != z)
                    continue;
                AddAP(id, arg, false, true);
                Chat(id, z ? "MAP_REWARD_Z" : "MAP_REWARD_H", arg);
            }
        }
        case MC_OBJ:
        {
            if (g_bMsObjDone[arg])
                return;
            g_bMsObjDone[arg] = true;
            if (get_pcvar_num(g_pMsDebug))
                log_amx("[Vexmira] map gorev %d tamam -> isaretler yenilendi", arg + 1);
            MsMkRefresh();
            if (arg >= g_iMsObjN || !get_pcvar_num(g_pMsObj))
                return;
            new bool:all = true;
            for (new k = 0; k < g_iMsObjN; k++)
            {
                if (!g_bMsObjDone[k])
                    all = false;
            }
            for (new id = 1; id <= g_iMax; id++)
            {
                if (!is_user_connected(id) || is_user_bot(id))
                    continue;
                if (all)
                    HudToS(id, SL_ALERT, CLR_GOOD, 3.5, "MAP_OBJ_ALL", g_szMsObj[MsLang(id)][arg]);
                else
                    HudToS(id, SL_ALERT, CLR_GOOD, 3.5, "MAP_OBJ_DONE_HUD", g_szMsObj[MsLang(id)][arg]);
                MsShowObjectives(id, !all);
            }
            if (g_szMsSndObj[0])
                client_cmd(0, "spk ^"%s^"", g_szMsSndObj);
        }
    }
}

// Gorev listesi: sohbet (durumla) + DHUD'da ilk acik gorev
MsShowObjectives(id, bool:hud)
{
    new l = MsLang(id), cur = -1, done;
    Chat(id, "MAP_OBJ_HEAD", g_szMsName[l][0] ? g_szMsName[l] : "-");
    for (new k = 0; k < g_iMsObjN; k++)
    {
        if (g_bMsObjDone[k])
        {
            done++;
            Chat(id, "MAP_OBJ_LINE_DONE", g_szMsObj[l][k]);
        }
        else
        {
            if (cur < 0)
                cur = k;
            if (g_bMsSeq && cur != k)
                Chat(id, "MAP_OBJ_LINE_LOCK", k + 1, g_iMsObjN, g_szMsObj[l][k]);
            else if (g_bMsSeq)
                Chat(id, "MAP_OBJ_LINE_CUR", k + 1, g_iMsObjN, g_szMsObj[l][k]);
            else if (k < g_iMsMkN && get_pcvar_num(g_pMsMarkers))
                Chat(id, "MAP_OBJ_LINE_MK", g_szMsObj[l][k], g_szMsMkName[k][l]);
            else
                Chat(id, "MAP_OBJ_LINE_OPEN", g_szMsObj[l][k]);
        }
    }
    if (get_pcvar_num(g_pMsDebug))
        log_amx("[Vexmira] map gorevler #%d: %d/%d tamam, acik=%d", id, done, g_iMsObjN, cur + 1);
    if (hud && cur >= 0)
    {
        new t[128];
        formatex(t, charsmax(t), "%L", id, "MAP_OBJ_CUR", cur + 1, g_iMsObjN, g_szMsObj[l][cur]);
        if (g_bMsSeq && cur < g_iMsMkN && get_pcvar_num(g_pMsMarkers))
            format(t, charsmax(t), "%s^n%L", t, id, "MAP_OBJ_CUR_MK", g_szMsMkName[cur][l]);
        HudText(id, SL_PERS, CLR_HUMAN, 6.0, t);
    }
}

/* ---------------- hikaye (daktilo) ---------------- */
MsOnSpawn(id)
{
    // vex_map_debug 2: botlar da (sunucu testi; HUD / sohbet botlara zaten gitmez)
    if (g_bMsSeen[id] || (is_user_bot(id) && get_pcvar_num(g_pMsDebug) < 2) || !g_iMsStoryN[0] || !get_pcvar_num(g_pMsStory))
        return;
    g_bMsSeen[id] = true;
    MsStoryStart(id, 2.0);
}

MsStoryStart(id, Float:delay)
{
    g_iMsStep[id] = g_szMsName[MsLang(id)][0] ? 0 : 1;
    g_iMsTries[id] = 0;
    remove_task(TASK_MSSTORY + id);
    set_task(delay, "task_MsStory", TASK_MSSTORY + id);
}

MsResetPlayer(id)
{
    g_bMsSeen[id] = false;
    remove_task(TASK_MSSTORY + id);
}

public task_MsStory(tid)
{
    new id = tid - TASK_MSSTORY;
    if (!is_user_connected(id))
        return;
    new l = MsLang(id), step = g_iMsStep[id];
    if (step > g_iMsStoryN[l])
        return;
    new slot = step ? SL_PERS : SL_ANN;
    new Float:now = get_gametime();
    // Yuva doluysa (baska bir yazi) kisa bekle: ust uste binmez
    if (now < g_fSlotEnd[id][slot] && g_iMsTries[id] < 12)
    {
        g_iMsTries[id]++;
        set_task(0.5, "task_MsStory", tid);
        return;
    }
    g_iMsTries[id] = 0;
    g_iMsStep[id]++;
    if (!step)
    {
        new t[64];
        formatex(t, charsmax(t), "-=[  %s  ]=-", g_szMsName[l]);
        HudDraw(id, SL_ANN, CLR_BRAND, 3.0, t);
        set_task(1.2, "task_MsStory", tid);
        return;
    }
    new text[MS_LEN], len;
    copy(text, charsmax(text), g_szMsStory[l][step - 1]);
    len = strlen(text);
    new Float:type = float(len) * MS_CHART;
    set_dhudmessage(230, 205, 150, -1.0, SLOT_Y[SL_PERS], 2, 0.4, 2.4, MS_CHART, 0.5);
    show_dhudmessage(id, "%s", text);
    g_fSlotEnd[id][SL_PERS] = now + type + 2.4 + 1.0;
    client_print(id, print_console, "   %s", text);
    if (get_pcvar_num(g_pMsDebug))
        log_amx("[Vexmira] map hikaye #%d satir %d/%d: %s", id, step, g_iMsStoryN[l], text);
    if (g_szMsSndLine[0])
        client_cmd(id, "spk ^"%s^"", g_szMsSndLine);
    if (step < g_iMsStoryN[l])
        set_task(type + 3.0, "task_MsStory", tid);
}

public cmd_MsStory(id)
{
    if (!g_iMsStoryN[0] || !get_pcvar_num(g_pMsStory))
    {
        Chat(id, "MAP_NO_STORY");
        return PLUGIN_HANDLED;
    }
    MsStoryStart(id, 0.1);
    if (g_iMsObjN && get_pcvar_num(g_pMsObj))
        MsShowObjectives(id, false);
    return PLUGIN_HANDLED;
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

#define MAPV_MAX 8

MapVoteInit()
{
    g_pMapVote        = register_cvar("vex_map_vote", "1");
    g_pCosPreview     = register_cvar("vex_cos_preview", "10");     // v3.5 vitrin suresi (sn), 0 = kapali
    g_pCosDeal        = register_cvar("vex_cos_daily_deal", "25");  // v3.5 gunun firsati indirimi (yuzde), 0 = kapali
    g_pCosHide        = register_cvar("vex_cos_hide", "1");         // v3.5 /kozmetik: digerlerininkini gizle secenegi
    g_pMapPool        = register_cvar("vex_map_pool", "zm_vex_cordon zm_vex_laboratory");
    g_pMapVoteRound   = register_cvar("vex_map_vote_round", "0");
    g_pMapVoteTime    = register_cvar("vex_map_vote_time", "20");
    g_pMapVoteExtend  = register_cvar("vex_map_vote_extend", "0");
    g_pMapExtendRounds = register_cvar("vex_map_extend_rounds", "10");
    g_pMapChangeDelay = register_cvar("vex_map_change_delay", "7.0");
    g_pMapChooserGuard = register_cvar("vex_map_vote_mapchooser", "1");
    g_pRtvRatio       = register_cvar("vex_rtv_ratio", "0.60");
    g_pRtvMinPlayers  = register_cvar("vex_rtv_minplayers", "2");
    g_pRtvMinRound    = register_cvar("vex_rtv_minround", "3");
    // Diger eklentiler / sunucu listesi icin (nextmap.amxx yoksa da var olsun)
    g_pAmxNextmap     = register_cvar("amx_nextmap", "", FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_SPONLY);

    get_mapname(g_szCurMap, charsmax(g_szCurMap));
    strtolower(g_szCurMap);
    for (new i = 0; i <= MAX_PLAYERS; i++)
        g_iMapVoted[i] = -1;

    RegisterSay("nextmap", "sonrakiharita", "cmd_nextmap");
    RegisterSay("maps",    "haritalar",     "cmd_maps");
    RegisterSay("rtv",     "haritadegis",   "cmd_rtv");
    RegisterSay("rockthevote", "",          "cmd_rtv");
    register_concmd("vex_mapvote", "cmd_adm_mapvote", ADMIN_VOTE, "[next | cancel] - harita oylamasi (varsayilan: kazanan harita round sonunda gelir)");
    RegisterHookChain(RG_CSGameRules_ChangeLevel, "rg_ChangeLevel", false);
    set_task(7.5, "task_MapChooserCheck", TASK_MAPWARN);
}

bool:MapVoteOn()
{
    return get_pcvar_num(g_pMapVote) > 0 ? true : false;
}

// Harita sunucuda var mi? (maps/<ad>.bsp + motorun kendi kontrolu)
bool:MapExists(const map[])
{
    if (!map[0])
        return false;
    new path[64];
    formatex(path, charsmax(path), "maps/%s.bsp", map);
    return (file_exists(path, true) && is_map_valid(map)) ? true : false;
}

// Havuzdaki gecerli haritalar (mevcut harita ve olmayanlar haric, tekrarsiz)
MapCandidates(out[][32], maxn)
{
    new list[256], tmp[32], pos, n;
    get_pcvar_string(g_pMapPool, list, charsmax(list));
    while (n < maxn && (pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
    {
        strtolower(tmp);
        if (!tmp[0] || equal(tmp, g_szCurMap) || !MapExists(tmp))
            continue;
        new bool:dup = false;
        for (new i = 0; i < n; i++)
        {
            if (equal(out[i], tmp))
            {
                dup = true;
                break;
            }
        }
        if (!dup)
            copy(out[n++], 31, tmp);
    }
    return n;
}

// Oylamanin yapilacagi round (0 = otomatik: son roundan bir onceki)
MapVoteRoundNum()
{
    new total = RoundsTotal();
    new r = get_pcvar_num(g_pMapVoteRound);
    if (r <= 0)
        r = total - 1;
    return clamp(r, 1, total);
}

bool:MapEndsByRounds()
{
    return get_cvar_num("mp_maxrounds") > 0 ? true : false;
}

SetNextMap(const map[])
{
    copy(g_szNextMap, charsmax(g_szNextMap), map);
    g_bMapDecided = true;
    if (g_pAmxNextmap)
        set_pcvar_string(g_pAmxNextmap, map);
    if (cvar_exists("nextmap"))
        set_cvar_string("nextmap", map);
    log_amx("[Vexmira] sonraki harita: %s", map);
}

// Oylama olmadiysa (oyuncu yok / oylama kapali iken RTV): havuzdan rastgele
MapPickFallback()
{
    if (g_bMapDecided && g_szNextMap[0])
        return;
    new maps[MAPV_MAX][32];
    new n = MapCandidates(maps, MAPV_MAX);
    if (n > 0)
        SetNextMap(maps[random(n)]);
}

// Her saniye (task_Tick): otomatik oylama zamani geldi mi?
MapVoteTick()
{
    if (g_bMapVoting || g_bMapChanging || !g_bRoundActive || g_bRoundEnded)
    {
        g_iMapVoteWait = 0;
        return;
    }
    if (!MapVoteOn() || !MapEndsByRounds() || g_bMapDecided || g_iVoteType)
        return;
    if (g_iRound < MapVoteRoundNum())
        return;
    // Round basindaki duyurular bitsin
    if (++g_iMapVoteWait < 8)
        return;
    StartMapVote(0, false);
}

StartMapVote(starter, bool:changeNow)
{
    if (g_bMapVoting || g_iVoteType)
    {
        if (starter)
            Chat(starter, "VOTE_RUNNING");
        return false;
    }

    new maps[MAPV_MAX][32];
    new n = MapCandidates(maps, MAPV_MAX);
    new bool:ext = (get_pcvar_num(g_pMapVoteExtend) > 0 && (changeNow || (MapEndsByRounds() && g_iMapExtends < 1))) ? true : false;

    if (n == 0)
    {
        if (starter)
            Chat(starter, "MAPV_NONE");
        log_amx("[Vexmira] harita oylamasi: havuzda (vex_map_pool) baska gecerli harita yok");
        // Bir daha denenmesin; harita sonunda oyunun kendi dongusu (mapcyclefile) gecerli
        g_bMapDecided = true;
        g_szNextMap[0] = 0;
        return false;
    }
    if (n == 1 && !ext)
    {
        SetNextMap(maps[0]);
        g_bMapChangeNow = changeNow;
        ChatAllS("MAPV_ONLY", maps[0]);
        if (changeNow)
            MapChangeAfterRound();
        return true;
    }

    // Karisik sira, en fazla MAPV_MAX secenek (uzatma dahil)
    new lim = ext ? MAPV_MAX - 1 : MAPV_MAX;
    for (new i = n - 1; i > 0; i--)
    {
        new j = random(i + 1);
        new t[32];
        copy(t, charsmax(t), maps[i]);
        copy(maps[i], 31, maps[j]);
        copy(maps[j], 31, t);
    }
    g_iMapOptN = 0;
    for (new i = 0; i < n && g_iMapOptN < lim; i++)
        copy(g_szMapOpt[g_iMapOptN++], charsmax(g_szMapOpt[]), maps[i]);
    g_iMapExtOpt = -1;
    if (ext)
    {
        g_iMapExtOpt = g_iMapOptN;
        g_szMapOpt[g_iMapOptN++][0] = 0;
    }
    for (new i = 0; i < MAPV_MAX; i++)
        g_iMapVotes[i] = 0;
    for (new p = 0; p <= MAX_PLAYERS; p++)
        g_iMapVoted[p] = -1;

    g_bMapVoting = true;
    g_bMapChangeNow = changeNow;
    g_iMapVoteLeft = clamp(get_pcvar_num(g_pMapVoteTime), 5, 60);

    new name[32];
    if (starter)
        get_user_name(starter, name, charsmax(name));
    else
        copy(name, charsmax(name), "Vexmira");
    FunAll(starter, "MAPV_START", name, g_iMapVoteLeft);
    HudAll(SL_ANN, CLR_BRAND, 3.0, "MAPV_START_HUD");
    PlayKey(0, "UI_VOTE_START");

    remove_task(TASK_MAPVOTE);
    set_task(1.0, "task_MapVoteTick", TASK_MAPVOTE, _, _, "b");
    task_MapVoteTick();
    return true;
}

public task_MapVoteTick()
{
    if (!g_bMapVoting)
    {
        remove_task(TASK_MAPVOTE);
        return;
    }
    if (g_iMapVoteLeft <= 0)
    {
        FinishMapVote();
        return;
    }
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        if (MapVoteMenuOpen(p) || !AnyMenuOpen(p))
            ShowMapVoteMenu(p);
    }
    g_iMapVoteLeft--;
}

bool:MapVoteMenuOpen(id)
{
    new m, nm, pg;
    player_menu_info(id, m, nm, pg);
    return (nm != -1 && nm == g_iMapVoteMenu[id]) ? true : false;
}

MapOptName(id, opt, out[], len)
{
    if (opt == g_iMapExtOpt)
    {
        if (g_bMapChangeNow)
            formatex(out, len, "%L", id, "MAPV_STAY");
        else
            formatex(out, len, "%L", id, "MAPV_EXTEND", get_pcvar_num(g_pMapExtendRounds));
    }
    else
        copy(out, len, g_szMapOpt[opt]);
}

ShowMapVoteMenu(id)
{
    new total;
    for (new i = 0; i < g_iMapOptN; i++)
        total += g_iMapVotes[i];

    new title[320], item[128], nm[64], desc[48], key[48];
    new hsub[128];
    formatex(hsub, charsmax(hsub), "%L", id, "MAPV_LEFT", g_iMapVoteLeft, total);
    VexHead(id, title, charsmax(title), "MAPV_TITLE", hsub);
    new menu = VexMenuCreate(title, "menu_mapvote_handler");

    for (new i = 0; i < g_iMapOptN; i++)
    {
        MapOptName(id, i, nm, charsmax(nm));
        desc[0] = 0;
        if (i != g_iMapExtOpt)
        {
            formatex(key, charsmax(key), "MAPDESC_%s", g_szMapOpt[i]);
            if (GetLangTransKey(key) != TransKey_Bad)
                formatex(desc, charsmax(desc), " \d%L", id, key);
        }
        new pct = total > 0 ? (g_iMapVotes[i] * 100 + total / 2) / total : 0;
        if (g_iMapVoted[id] == i)
            formatex(item, charsmax(item), "\y%s%s \r[%d \r- %d%%\r] \y<", nm, desc, g_iMapVotes[i], pct);
        else
            formatex(item, charsmax(item), "\y%s%s \r[%d \r- %d%%\r]", nm, desc, g_iMapVotes[i], pct);
        MenuAdd(menu, item, i);
    }

    new note[96];
    formatex(note, charsmax(note), "^n\d%L", id, "MAPV_NOTE");
    VexAddText(menu, note, 0);
    menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
    MenuNoPage(menu);
    menu_setprop(menu, MPROP_EXIT, MEXIT_FORCE);
    MenuProps(id, menu);
    g_iMapVoteMenu[id] = menu;
    menu_display(id, menu, 0, 1);
}

public menu_mapvote_handler(id, menu, item)
{
    if (item < 0 || !g_bMapVoting)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new opt = MenuInfo(menu, item);
    menu_destroy(menu);
    if (opt < 0 || opt >= g_iMapOptN || is_user_bot(id))
        return PLUGIN_HANDLED;

    // Oy degistirme serbest
    new old = g_iMapVoted[id];
    if (old == opt)
    {
        ShowMapVoteMenu(id);
        return PLUGIN_HANDLED;
    }
    if (0 <= old < g_iMapOptN)
        g_iMapVotes[old] = max(0, g_iMapVotes[old] - VipVoteW(id));
    g_iMapVoted[id] = opt;
    g_iMapVotes[opt] += VipVoteW(id);
    PlayKey(id, "UI_MENU_SELECT");

    new name[32], nm[64];
    get_user_name(id, name, charsmax(name));
    for (new p = 1; p <= g_iMax && get_pcvar_num(g_pChatBcast); p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        MapOptName(p, opt, nm, charsmax(nm));
        client_print_color(p, id, "%s %L", ChatTag(old >= 0 ? "MAPV_RECAST" : "MAPV_CAST"), p, old >= 0 ? "MAPV_RECAST" : "MAPV_CAST", name, nm);
    }
    // Herkesin menusu bir sonraki saniyede yeni sayilarla yenilenir; oy veren hemen gorur
    ShowMapVoteMenu(id);
    return PLUGIN_HANDLED;
}

FinishMapVote()
{
    if (!g_bMapVoting)
        return;
    g_bMapVoting = false;
    remove_task(TASK_MAPVOTE);

    new total, bestc = -1, ties[MAPV_MAX], nt;
    for (new i = 0; i < g_iMapOptN; i++)
        total += g_iMapVotes[i];
    for (new i = 0; i < g_iMapOptN; i++)
    {
        // Hic oy yoksa uzatma secilmez (rastgele bir harita)
        if (total == 0 && i == g_iMapExtOpt)
            continue;
        if (g_iMapVotes[i] > bestc)
        {
            bestc = g_iMapVotes[i];
            nt = 0;
            ties[nt++] = i;
        }
        else if (g_iMapVotes[i] == bestc)
            ties[nt++] = i;
    }
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p) && MapVoteMenuOpen(p))
            show_menu(p, 0, "^n", 1);
        g_iMapVoted[p] = -1;
    }
    if (nt == 0)
        return;
    new win = ties[random(nt)];
    new pct = total > 0 ? (bestc * 100 + total / 2) / total : 0;
    PlayKey(0, "UI_VOTE_END");

    if (win == g_iMapExtOpt)
    {
        RtvReset();
        if (g_bMapChangeNow)
        {
            // RTV / admin oylamasi: harita kalir
            g_bMapChangeNow = false;
            ChatAll("MAPV_STAYED", bestc);
            HudAll(SL_ALERT, CLR_EVENT, 3.5, "MAPV_STAYED_HUD");
            return;
        }
        new ext = clamp(get_pcvar_num(g_pMapExtendRounds), 1, 50);
        g_iMapExtends++;
        g_iMapExtendTo = get_cvar_num("mp_maxrounds") + ext;
        set_cvar_num("mp_maxrounds", g_iMapExtendTo);
        g_bMapDecided = false;
        g_iMapVoteWait = 0;
        ChatAll("MAPV_EXTENDED", ext);
        HudAll(SL_ALERT, CLR_EVENT, 3.5, "MAPV_EXTENDED_HUD", ext);
        return;
    }

    SetNextMap(g_szMapOpt[win]);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        if (total == 0)
            client_print_color(p, print_team_default, "%s %L", ChatTag("MAPV_NOVOTES"), p, "MAPV_NOVOTES", g_szNextMap);
        else
            client_print_color(p, print_team_default, "%s %L", ChatTag("MAPV_RESULT"), p, "MAPV_RESULT", g_szNextMap, bestc, pct);
        HudToS(p, SL_ANN, CLR_EVENT, 4.0, "MAPV_RESULT_HUD", g_szNextMap);
    }
    RtvReset();
    if (g_bMapChangeNow)
        MapChangeAfterRound();
}

// Kazanan harita: round surerken -> round sonunda, round yoksa birkac saniye sonra
MapChangeAfterRound()
{
    g_bMapChangeNow = true;
    if (g_bRoundActive && !g_bRoundEnded)
        ChatAllS("MAPV_ROUNDEND", g_szNextMap);
    else
        MapChangeBegin(false);
}

// Round sonu (OnRoundEnd): son round veya bekleyen degisim -> odul akisi + ara ekran + changelevel
MapOnRoundEnd()
{
    if (g_bMapChanging || !MapVoteOn())
        return;
    new bool:last = (MapEndsByRounds() && g_iRound >= RoundsTotal()) ? true : false;
    if (!last && !g_bMapChangeNow)
        return;
    MapChangeBegin(last);
}

MapChangeBegin(bool:lastRound)
{
    if (g_bMapChanging)
        return;
    if (g_bMapVoting)
        FinishMapVote();
    if (!g_bMapDecided || !g_szNextMap[0])
    {
        g_bMapDecided = false;
        MapPickFallback();
    }
    if (!g_szNextMap[0])
    {
        // Gidilecek harita yok: oyunun kendi akisi (mp_maxrounds -> ara ekran -> mapcyclefile)
        g_bMapChangeNow = false;
        return;
    }
    g_bMapChanging = true;
    // Son round degilse (RTV / admin) harita sonu odulleri burada verilir
    if (!lastRound && !g_bMapAwards)
        set_task(1.5, "task_MapEndAwards");
    // Yeni round baslamasin (ara ekrana kadar)
    set_task(0.2, "task_MapHold", TASK_MAPHOLD);
    remove_task(TASK_MAPCHG);
    set_task(floatclamp(get_pcvar_float(g_pMapChangeDelay), 3.0, 30.0), "task_MapIntermission", TASK_MAPCHG);
}

public task_MapHold()
{
    if (g_bMapChanging)
        set_member_game(m_flRestartRoundTime, get_gametime() + 60.0);
}

public task_MapIntermission()
{
    if (!MapExists(g_szNextMap))
    {
        // Oylamadan sonra dosya silindiyse: baska bir harita
        g_bMapDecided = false;
        g_szNextMap[0] = 0;
        MapPickFallback();
        if (!g_szNextMap[0])
        {
            g_bMapChanging = false;
            set_member_game(m_flRestartRoundTime, get_gametime() + 1.0);
            return;
        }
    }
    ChatAllS("MAPV_CHANGING", g_szNextMap);
    HudAllS(SL_ANN, CLR_BRAND, 4.0, "MAPV_CHANGING_HUD", g_szNextMap);
    PlayKey(0, "UI_VOTE_END");
    // Skor tablosu (ara ekran), sonra harita degisir
    message_begin(MSG_ALL, SVC_INTERMISSION);
    message_end();
    set_task(3.5, "task_DoChangeLevel", TASK_MAPCHG + 1);
}

public task_DoChangeLevel()
{
    if (!g_szNextMap[0])
        return;
    log_amx("[Vexmira] harita degisiyor: %s -> %s", g_szCurMap, g_szNextMap);
    server_cmd("changelevel %s", g_szNextMap);
}

// Oyunun kendi harita degisimi (mp_timelimit / mp_maxrounds ara ekrani): oylanan haritaya git
public rg_ChangeLevel()
{
    if (!MapVoteOn())
        return HC_CONTINUE;
    if (!g_bMapDecided || !MapExists(g_szNextMap))
    {
        g_bMapDecided = false;
        g_szNextMap[0] = 0;
        MapPickFallback();
    }
    if (!g_szNextMap[0])
        return HC_CONTINUE;
    log_amx("[Vexmira] harita degisiyor (oyun): %s -> %s", g_szCurMap, g_szNextMap);
    server_cmd("changelevel %s", g_szNextMap);
    return HC_SUPERCEDE;
}

/* ---------------- Rock The Vote ---------------- */

RtvReset()
{
    g_iRtvCount = 0;
    for (new p = 0; p <= MAX_PLAYERS; p++)
        g_bRtv[p] = false;
}

// ignore: ayrilmakta olan oyuncu (client_disconnected'da hala bagli gorunur)
RtvNeeded(ignore = 0)
{
    new humans = RtvHumans(ignore);
    new Float:ratio = floatclamp(get_pcvar_float(g_pRtvRatio), 0.01, 1.0);
    return max(1, floatround(float(humans) * ratio, floatround_ceil));
}

RtvHumans(ignore = 0)
{
    new humans;
    for (new p = 1; p <= g_iMax; p++)
    {
        if (p != ignore && is_user_connected(p) && !is_user_bot(p) && !is_user_hltv(p))
            humans++;
    }
    return humans;
}

public cmd_rtv(id)
{
    if (is_user_bot(id))
        return PLUGIN_HANDLED;
    if (!MapVoteOn() || get_pcvar_float(g_pRtvRatio) <= 0.0)
    {
        Chat(id, "RTV_OFF");
        return PLUGIN_HANDLED;
    }
    if (g_bMapChanging || (g_bMapDecided && g_bMapChangeNow && g_szNextMap[0]))
    {
        Chat(id, "RTV_CHANGING", g_szNextMap);
        return PLUGIN_HANDLED;
    }
    if (g_bMapVoting || g_iVoteType)
    {
        Chat(id, "VOTE_RUNNING");
        return PLUGIN_HANDLED;
    }
    if (g_bMapDecided && g_szNextMap[0])
    {
        Chat(id, "RTV_DECIDED", g_szNextMap);
        return PLUGIN_HANDLED;
    }
    new cand[MAPV_MAX][32];
    if (!MapCandidates(cand, MAPV_MAX))
    {
        Chat(id, "MAPV_NONE");
        return PLUGIN_HANDLED;
    }
    new minr = get_pcvar_num(g_pRtvMinRound);
    if (g_iRound < minr)
    {
        Chat(id, "RTV_TOO_EARLY", minr);
        return PLUGIN_HANDLED;
    }
    new minp = get_pcvar_num(g_pRtvMinPlayers);
    if (RtvHumans() < minp)
    {
        Chat(id, "RTV_MINPL", minp);
        return PLUGIN_HANDLED;
    }
    new need = RtvNeeded();
    if (g_bRtv[id])
    {
        Chat(id, "RTV_ALREADY", g_iRtvCount, need);
        return PLUGIN_HANDLED;
    }
    g_bRtv[id] = true;
    g_iRtvCount++;

    new name[32];
    get_user_name(id, name, charsmax(name));
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p))
            client_print_color(p, id, "%s %L", ChatTag("RTV_ROCKED"), p, "RTV_ROCKED", name, g_iRtvCount, need);
    }
    RtvCheck();
    return PLUGIN_HANDLED;
}

RtvCheck(ignore = 0)
{
    if (g_iRtvCount <= 0 || g_bMapVoting || g_bMapChanging || g_bMapDecided)
        return;
    if (g_iRtvCount < RtvNeeded(ignore))
        return;
    ChatAll("RTV_START");
    if (!StartMapVote(0, true))
        RtvReset();
}

// Ayrilan oyuncunun oyu / RTV'si duser
MapVoteDisconnect(id)
{
    if (g_bMapVoting && 0 <= g_iMapVoted[id] < g_iMapOptN)
        g_iMapVotes[g_iMapVoted[id]] = max(0, g_iMapVotes[g_iMapVoted[id]] - VipVoteW(id));
    g_iMapVoted[id] = -1;
    g_iMapVoteMenu[id] = -1;
    if (g_bRtv[id])
    {
        g_bRtv[id] = false;
        g_iRtvCount = max(0, g_iRtvCount - 1);
    }
}

/* ---------------- /nextmap /maps ---------------- */

public cmd_nextmap(id)
{
    if (g_bMapDecided && g_szNextMap[0])
        Chat(id, g_bMapChangeNow || g_bMapChanging ? "MAPV_NEXT_NOW" : "MAPV_NEXT_IS", g_szNextMap);
    else if (MapVoteOn() && MapEndsByRounds())
        Chat(id, "MAPV_NEXT_VOTE", MapVoteRoundNum(), RoundsTotal());
    else
    {
        new nm[32];
        if (g_pAmxNextmap)
            get_pcvar_string(g_pAmxNextmap, nm, charsmax(nm));
        Chat(id, "MAPV_NEXT_CYCLE", nm[0] ? nm : "-");
    }
    return PLUGIN_HANDLED;
}

public cmd_maps(id)
{
    new list[256], tmp[32], pos, line[180], n;
    get_pcvar_string(g_pMapPool, list, charsmax(list));
    while ((pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
    {
        strtolower(tmp);
        if (!tmp[0])
            continue;
        if (n++)
            add(line, charsmax(line), "^1, ");
        if (equal(tmp, g_szCurMap))
            format(line, charsmax(line), "%s^3%s*", line, tmp);
        else if (!MapExists(tmp))
            format(line, charsmax(line), "%s^1%s(-)", line, tmp);
        else if (g_bMapDecided && equal(tmp, g_szNextMap))
            format(line, charsmax(line), "%s^4%s>", line, tmp);
        else
            format(line, charsmax(line), "%s^4%s", line, tmp);
    }
    Chat(id, "MAPV_LIST_HDR", RoundsTotal() - g_iRound > 0 ? RoundsTotal() - g_iRound : 0);
    if (line[0])
        client_print_color(id, print_team_default, "^1%s", line);
    Chat(id, "MAPV_LIST_KEY");
    return PLUGIN_HANDLED;
}

/* ---------------- Admin ---------------- */

public cmd_adm_mapvote(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED;
    new arg[16];
    read_argv(1, arg, charsmax(arg));
    if (equali(arg, "cancel"))
    {
        if (g_bMapVoting)
        {
            g_bMapVoting = false;
            remove_task(TASK_MAPVOTE);
            for (new p = 1; p <= g_iMax; p++)
            {
                if (is_user_connected(p) && !is_user_bot(p) && MapVoteMenuOpen(p))
                    show_menu(p, 0, "^n", 1);
            }
            g_bMapChangeNow = false;
            RtvReset();
            AdminNotify(id, "ADM_MAPVOTE_CANCEL", 0);
        }
        else
            console_print(id, "[Vexmira] -");
        return PLUGIN_HANDLED;
    }
    AdminStartMapVote(id, equali(arg, "next") ? false : true);
    return PLUGIN_HANDLED;
}

AdminStartMapVote(id, bool:changeNow)
{
    if (g_bMapChanging)
    {
        if (id)
            Chat(id, "RTV_CHANGING", g_szNextMap);
        console_print(id, "[Vexmira] harita zaten degisiyor: %s", g_szNextMap);
        return;
    }
    // Admin yeniden oylatabilir (onceki sonuc iptal)
    g_bMapDecided = false;
    g_szNextMap[0] = 0;
    if (StartMapVote(id, changeNow))
        AdminNotify(id, "ADM_MAPVOTE", g_iMapOptN);
    else
        console_print(id, "[Vexmira] oylama baslatilamadi (havuzda gecerli harita yok veya baska oylama suruyor)");
}

// mapchooser.amxx ayni anda kendi oylamasini yapmasin (cift oylama)
public task_MapChooserCheck()
{
    if (!MapVoteOn() || is_plugin_loaded("mapchooser.amxx", true) == -1)
        return;
    if (get_pcvar_num(g_pMapChooserGuard) > 0)
    {
        pause("ac", "mapchooser.amxx");
        log_amx("[Vexmira] mapchooser.amxx yuklu: cift harita oylamasi olmasin diye DURAKLATILDI. plugins.ini'den kaldirin (veya vex_map_vote 0).");
    }
    else
        log_amx("[Vexmira] UYARI: mapchooser.amxx yuklu ve vex_map_vote 1: iki ayri harita oylamasi olabilir. plugins.ini'den kaldirin.");
}

/* ===== End module: maps.inc ===== */
/* ================================================================== */
/*  GIRIS NOKTALARI                                                    */
/*  Yeni cvar / komut / menu / hook kaydi -> plugin_init (asagida),    */
/*  yeni kaynak -> plugin_precache ve ilgili kaynak tanimlari.                */
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
    // v3.2 (B): CSO ekran bildirimi dosyalari (vex_cso_style 0 ise hic indirilmez)
    CsoPrecache();

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

    // v3.2: VIP bicak kaplamasi (bos / dosya yok = kapali)
    GetFileModel("VIP_V_KNIFE", g_szVipKnifeV, charsmax(g_szVipKnifeV));
    GetFileModel("VIP_P_KNIFE", g_szVipKnifeP, charsmax(g_szVipKnifeP));

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

    // v3.2: kanat / pet / sapka modelleri (vex_wing / vex_pet / vex_hat)
    CmPrecache();

    // En dusuk oncelik: elde gorunen (p_) silah modelleri (butce dolarsa oyunun kendi modeli)
    for (new w = 1; w < 31; w++)
    {
        formatex(key, charsmax(key), "P_%s", WEAPON_KEYNAME[w]);
        GetFileModel(key, g_szWepP[w], charsmax(g_szWepP[]));
    }

    // Mod silahi modelleri: <MOD>_W<yuva>_VMODEL / _PMODEL / _SOUND (vex_res). Eski anahtarlar
    // (SURVIVOR_M249_* = W1, SURVIVOR_DEAGLE_* = W2, SNIPER_AWP_* = W1) da calisir.
    // Bos ise silahin genel V_<SILAH> / P_<SILAH> modeli kullanilir.
    static const OLDK[MW_MODES][MW_SLOTS][] = { { "SURVIVOR_M249", "SURVIVOR_DEAGLE" }, { "SNIPER_AWP", "" } };
    for (new mm = 0; mm < MW_MODES; mm++)
    {
        for (new ms = 0; ms < MW_SLOTS; ms++)
        {
            formatex(key, charsmax(key), "%s_W%d_VMODEL", MW_KEY[mm], ms + 1);
            GetFileModel(key, g_szMwV[mm][ms], charsmax(g_szMwV[][]));
            if (!g_szMwV[mm][ms][0] && OLDK[mm][ms][0])
            {
                formatex(key, charsmax(key), "%s_VMODEL", OLDK[mm][ms]);
                GetFileModel(key, g_szMwV[mm][ms], charsmax(g_szMwV[][]));
            }
            formatex(key, charsmax(key), "%s_W%d_PMODEL", MW_KEY[mm], ms + 1);
            GetFileModel(key, g_szMwP[mm][ms], charsmax(g_szMwP[][]));
            if (!g_szMwP[mm][ms][0] && OLDK[mm][ms][0])
            {
                formatex(key, charsmax(key), "%s_PMODEL", OLDK[mm][ms]);
                GetFileModel(key, g_szMwP[mm][ms], charsmax(g_szMwP[][]));
            }
            formatex(key, charsmax(key), "%s_W%d_SOUND", MW_KEY[mm], ms + 1);
            PrecacheSoundKeyEx(key, false);
        }
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
    g_pFirstHP      = register_cvar("vex_first_zombie_hp", "6000");
    g_pZombieHP     = register_cvar("vex_zombie_hp", "2400");
    g_pBossEvery    = register_cvar("vex_boss_every", "6");
    g_pBossHP       = register_cvar("vex_boss_hp", "9000");
    g_pEventChance  = register_cvar("vex_event_chance", "85");
    g_pNemHP        = register_cvar("vex_nemesis_hp", "15000");
    g_pAsnHP        = register_cvar("vex_assassin_hp", "10000");
    g_pSurvHP       = register_cvar("vex_survivor_hp", "1000");
    g_pSnipHP       = register_cvar("vex_sniper_hp", "900");
    g_pRespawn      = register_cvar("vex_zombie_respawn", "4.0");
    g_pDmgPerAP     = register_cvar("vex_damage_per_ap", "800");
    g_pKnockback    = register_cvar("vex_knockback", "1");
    g_pStartAP      = register_cvar("vex_start_ap", "20");
    g_pArmorProtect = register_cvar("vex_armor_protect", "1");
    g_pChatBcast    = register_cvar("vex_chat_broadcast", "1");   // v3.4: 1 = level/rutbe/basarim/gorev/liderlik/enfeksiyon/oy/baglanma mesajlari herkese gider
    g_pChatBuyBcast = register_cvar("vex_chat_buy_broadcast", "0"); // v3.4: 1 = "X sunu satin aldi" mesajlari herkese gider (varsayilan kapali)
    g_pVipContact   = register_cvar("vex_vip_contact", "discord.gg/vexmira");
    g_pVipBonus     = register_cvar("vex_vip_bonus", "25");
    g_pEliteBonus   = register_cvar("vex_elite_bonus", "50");
    g_pVipDisc      = register_cvar("vex_vip_discount", "10");
    g_pEliteDisc    = register_cvar("vex_elite_discount", "20");
    g_pVipArmor     = register_cvar("vex_vip_armor", "50");
    g_pEliteArmor   = register_cvar("vex_elite_armor", "100");
    g_pVipRoundVC   = register_cvar("vex_vip_round_vc", "1");
    g_pVipAutoPack  = register_cvar("vex_vip_autopack", "1");
    g_pVipPriority  = register_cvar("vex_vip_priority_msg", "2");
    g_pVipAnnounce  = register_cvar("vex_vip_join_announce", "2");
    g_pVipVoteW     = register_cvar("vex_vip_vote_weight", "2");
    g_pVipSpawnProt = register_cvar("vex_vip_spawnprot", "1.0");
    g_pVipDaily     = register_cvar("vex_vip_daily_pct", "50");
    g_pEliteDaily   = register_cvar("vex_elite_daily_pct", "100");
    g_pVipKillIcon  = register_cvar("vex_vip_killicon", "1");
    g_pVipScore     = register_cvar("vex_vip_scoreboard", "1");
    g_pVipRegun     = register_cvar("vex_vip_regun", "1");
    register_message(get_user_msgid("ScoreAttrib"), "msg_ScoreAttrib");
    register_srvcmd("vex_cos_give", "srv_CosGive");
    register_srvcmd("vex_cos_dump", "srv_CosDump");
    g_pTipInterval  = register_cvar("vex_chat_tip_interval", "90");
    g_pLiveChatter  = register_cvar("vex_live_chatter", "0");
    g_pVoteEvery    = register_cvar("vex_vote_every", "4");

    // v1.4: 30 round plani, boss, hasar/can/hiz, lazer, bomba modlari, ikmal
    g_pRoundsTotal  = register_cvar("vex_rounds_total", "30");
    g_pBossRounds   = register_cvar("vex_boss_rounds", "7 15 23 30");
    g_pSpecialRounds= register_cvar("vex_special_rounds", "4 11 19 26");
    g_pMultiChance  = register_cvar("vex_multi_chance", "15");
    g_pBossHPPer    = register_cvar("vex_boss_hp_per_player", "2500");
    g_pBossFinal    = register_cvar("vex_boss_final_mult", "1.5");
    g_pBossDmg      = register_cvar("vex_boss_damage", "90");
    g_pBossAbil     = register_cvar("vex_boss_ability_mult", "1.0");
    g_pNemDmg       = register_cvar("vex_nemesis_damage", "400");
    g_pAsnDmg       = register_cvar("vex_assassin_damage", "300");
    g_pMinionDmg    = register_cvar("vex_minion_damage", "35");
    g_pZombieDmg    = register_cvar("vex_zombie_damage", "75");
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
    g_pLmMaxVip     = register_cvar("vex_lm_max_vip", "4");
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
    g_pHostname      = register_cvar("vex_hostname", "VEXMIRA ZOMBIE [TR/EN] | STORY MAP + CSO BOSS + EVENTS");
    g_pHostDyn       = register_cvar("vex_hostname_dynamic", "1");
    g_pEnv           = register_cvar("vex_env", "1");
    g_pEnvCalm       = register_cvar("vex_env_calm_random", "1");
    g_pWeather       = register_cvar("vex_weather", "1");
    g_pZHPPer = register_cvar("vex_zombie_hp_per_player", "40");
    g_pNemHPPer = register_cvar("vex_nemesis_hp_per_player", "1200");
    g_pAsnHPPer = register_cvar("vex_assassin_hp_per_player", "800");
    g_pKBMult = register_cvar("vex_knockback_mult", "0.75");
    g_pSpecCap = register_cvar("vex_special_dmg_cap", "1500");
    g_pNemOneShot    = register_cvar("vex_nemesis_oneshot", "1");
    g_pAsnOneShot    = register_cvar("vex_assassin_oneshot", "1");
    g_pNemVsSurv     = register_cvar("vex_nemesis_vs_survivor", "350");
    g_pNemSpeed      = register_cvar("vex_nemesis_speed", "265");
    g_pAsnSpeed      = register_cvar("vex_assassin_speed", "340");
    g_pNemGrav       = register_cvar("vex_nemesis_gravity", "0.5");
    g_pAsnGrav       = register_cvar("vex_assassin_gravity", "0.45");
    g_pMinionHP      = register_cvar("vex_minion_hp", "600");
    g_pNemRageTime   = register_cvar("vex_nemesis_rage_time", "5");
    g_pNemRageCd     = register_cvar("vex_nemesis_rage_cooldown", "25");
    g_pAsnVeilTime   = register_cvar("vex_assassin_veil_time", "4");
    g_pAsnVeilCd     = register_cvar("vex_assassin_veil_cooldown", "25");
    g_pSpecialLeapCd = register_cvar("vex_special_leap_cooldown", "6");
    g_pLmPerRound    = register_cvar("vex_lm_per_round", "3");
    g_pLmPerRoundVip = register_cvar("vex_lm_per_round_vip", "4");
    g_pLmOneShot     = register_cvar("vex_lm_oneshot", "1");
    g_pLmSpecialDmg  = register_cvar("vex_lm_special_damage", "600");
    g_pLmKillWear    = register_cvar("vex_lm_kill_wear", "100");
    g_pLmPlantTime   = register_cvar("vex_lm_plant_time", "1.0");
    g_pLmTakeTime    = register_cvar("vex_lm_take_time", "2.0");
    g_pMeteorEvery   = register_cvar("vex_meteor_interval", "9");
    g_pMeteorCount   = register_cvar("vex_meteor_count", "1");
    g_pLmArmTime     = register_cvar("vex_lm_arm_time", "1.5");
    g_pLmBeamWidth   = register_cvar("vex_lm_beam_width", "8");
    g_pLmColorMode   = register_cvar("vex_lm_color_mode", "0");
    g_pLmColor       = register_cvar("vex_lm_color", "0 200 255");
    g_pLmRange       = register_cvar("vex_lm_plant_range", "128");
    g_pLmTakeRange   = register_cvar("vex_lm_take_range", "170");
    g_pLmMaxRange    = register_cvar("vex_lm_max_range", "600");
    g_pLmBlockModes  = register_cvar("vex_lm_block_modes", "nemesis assassin");
    g_pDbgDirs       = register_cvar("vex_debug_dirs", "0");
    g_pAutoJoinHumans= register_cvar("vex_auto_join_humans", "1");
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
    g_pWinHAP        = register_cvar("vex_win_human_ap", "5");
    g_pWinZXP        = register_cvar("vex_win_zombie_xp", "15");
    g_pWinZAP        = register_cvar("vex_win_zombie_ap", "4");
    g_pBossKillXP    = register_cvar("vex_boss_kill_xp", "120");
    g_pBossKillAP    = register_cvar("vex_boss_kill_ap", "25");
    g_pBossKillVC    = register_cvar("vex_boss_kill_vc", "2");
    g_pSpecKillXP    = register_cvar("vex_special_kill_xp", "80");
    g_pSpecKillAP    = register_cvar("vex_special_kill_ap", "15");
    g_pBossBoard     = register_cvar("vex_boss_board_ap", "40 25 15");
    g_pHsAP          = register_cvar("vex_headshot_ap", "1");
    g_pExchange      = register_cvar("vex_exchange_cost", "100");
    g_pPerkStep      = register_cvar("vex_perk_cost_step", "5");
    g_pDailyAP       = register_cvar("vex_daily_ap", "20");
    g_pAchAP         = register_cvar("vex_achievement_ap", "25");
    g_pAchVC         = register_cvar("vex_achievement_vc", "2");
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
    g_pHudStyle      = register_cvar("vex_hud_style", "1");
    g_pHudTop        = register_cvar("vex_hud_top", "-1");
    g_pHudRight      = register_cvar("vex_hud_right", "-1");
    g_pHudMvp        = register_cvar("vex_hud_mvp", "-1");
    g_pHudXp         = register_cvar("vex_hud_xp", "-1");
    g_pHudOvh        = register_cvar("vex_hud_overhead", "-1");
    g_pHudObjective  = register_cvar("vex_hud_objective", "-1");
    // v3.2 (B): CSO tarzi ekran bildirimi
    g_pCso           = register_cvar("vex_cso_style", "1");
    g_pCsoNotes      = register_cvar("vex_cso_notes", "255");
    g_pComboTime     = register_cvar("vex_combo_time", "6.0");
    g_pCsoTime       = register_cvar("vex_cso_time", "2.5");
    g_pCsoKmTime     = register_cvar("vex_cso_km_time", "1.5");
    g_pCsoFov        = register_cvar("vex_cso_fov", "89");
    g_pCsoSnd        = register_cvar("vex_cso_sound", "1");
    g_pCsoIcons      = register_cvar("vex_cso_icons", "1");
    g_pCsoBots       = register_cvar("vex_cso_bots", "0");
    g_pCsoLog        = register_cvar("vex_cso_log", "0");
    g_pCsoAnim       = register_cvar("vex_cso_anim", "1");
    g_msgWL    = get_user_msgid("WeaponList");
    g_msgCurW  = get_user_msgid("CurWeapon");
    g_msgFOV   = get_user_msgid("SetFOV");
    g_msgSIcon = get_user_msgid("StatusIcon");
    CsoInitWL();
    register_message(g_msgWL, "msg_WeaponList");
    set_task(0.1, "task_CsoTick", TASK_CSO, _, _, "b");
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
    register_srvcmd("vex_debug_swtest", "srv_DbgSwTest");
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
        "vex_mode_rule", "vex_env_event", "vex_env_mode", "vex_env_boss", "vex_env_calm", "vex_cosmetic", "vex_quest", "vex_sw_text"
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
    RegisterHookChain(RG_CBasePlayer_DropPlayerItem,     "rg_DropPlayerItemPost", true);
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
    register_clcmd("jointeam", "cmd_jointeam");
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
    RegisterSay("wings",    "kanat",     "cmd_cosmetic");
    RegisterSay("hat",      "sapka",     "cmd_cosmetic");
    RegisterSay("pet",      "",          "cmd_cosmetic");
    RegisterSay("trail",    "iz",        "cmd_cosmetic");
    RegisterSay("skill",    "beceri",    "cmd_skill");
    RegisterSay("skill2",   "beceri2",   "cmd_skill2");
    // v3.0 (C): harita oylamasi (/nextmap /maps /rtv, vex_mapvote, cvar'lar)
    MapVoteInit();
    // v3.3: harita senaryosu (MAP_CONTRACT.md: vex_* olaylar, vexcmd_* relay'ler, vexmira_maps/<harita>.ini)
    MsInit();

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
    task_EnforceAutoTeam();
    remove_task(TASK_AUTOTEAM);
    set_task(15.0, "task_EnforceAutoTeam", TASK_AUTOTEAM, _, _, "b");
    set_task(1.5, "task_EnforceRoundInfinite", TASK_ROUNDINF);
    set_task(6.0, "task_LoadConfig", TASK_CFGLOAD);
    set_task(30.0, "task_Hostname", TASK_HOSTNAME, _, _, "b");
    // Haritanin ilk roundu RestartRound'dan gecmeyebilir: round basi olayi bir kez
    set_task(1.0, "task_MsRoundStart", TASK_MSRS);
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
