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
#define VERSION  "1.5.0"
#define AUTHOR   "SmurfSexy & Capital"

/* ------------------------------------------------------------------ */
/*  Sabitler                                                           */
/* ------------------------------------------------------------------ */

#define MAX_LEVEL     60
#define NUM_CLASSES   12
#define NUM_BOSSES    9
#define NUM_JOBS      26
#define NUM_ITEMS     28
#define NUM_SPECIAL   8
#define NUM_PERKS     6
#define PERK_MAX      5
#define NUM_ACH       14
#define NUM_TITLES    10
#define NUM_STYLES    3
#define NUM_THEMES    6
#define NUM_RANKS     8
#define NUM_ADS       22
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
#define TASK_MOTD     8600
#define TASK_BOSSFX   8700
#define TASK_NADES    8800
#define TASK_INTRO    8900
#define TASK_CLUSTER  20000
#define TASK_WELCOME2 9100
#define TASK_MINEFX   9200
#define TASK_LOADWAIT 9300
#define TASK_ROUNDINF 9400

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

#define CHAT_PREFIX   "^4[^3Vex^4mira^4]^1"
#define MENU_TAG      "\r[\wVexmira\r] \d||"

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
    "SW_FIRE", "ZAP", "MVP", "VIP_JOIN", "BOSS_WARN", "BOSS_ROAR", "BOSS_ABILITY",
    "ZOMBIE_IDLE", "ZOMBIE_SLASH", "ZOMBIE_HITWALL", "ZOMBIE_HIT", "ZOMBIE_STAB", "ZOMBIE_ACID", "ZOMBIE_HEAL", "ZOMBIE_BLINK", "ZOMBIE_SHOCK",
    "WELCOME", "PLAYER_JOIN", "PLAYER_LEAVE", "BOSS_SOON", "BOSS_INTRO", "BOSS_STEP", "BOSS_PHASE", "BOSS_ENRAGE",
    "LM_DEPLOY", "LM_CHARGE", "LM_ACTIVATE", "LM_HIT", "LM_BREAK", "LM_PICKUP",
    "NADE_MODE", "NADE_BEEP", "NADE_ARM", "NADE_CLUSTER",
    "AIRDROP_INCOMING", "AIRDROP_LAND", "AIRDROP_LOOT", "QUEST_DONE", "EVOLVE",
    "SPEED_START", "SPEED_WIND", "STORM_STRIKE", "BLACKOUT", "FINAL_ROUND", "MAP_END",
    "FROST_NOVA", "THUNDER", "ACID_POOL", "GRAVITY_WELL", "ECLIPSE"
};

// Zombi siniflari: Walker, Runner, Tank, Banshee, Leech, Stalker, Bomber, Frost
new const Float:CLASS_HP[NUM_CLASSES]   = { 1.0, 0.70, 1.80, 0.90, 1.10, 0.80, 1.00, 1.05, 0.90, 1.60, 0.95, 0.75 };
new const CLASS_SPD[NUM_CLASSES]        = { 270,  310,  235,  285,  265,  295,  260,  270,  280,  245,  275,  300 };
new const Float:CLASS_GRAV[NUM_CLASSES] = { 0.80, 0.70, 1.00, 0.80, 0.85, 0.75, 0.90, 0.80, 0.80, 1.00, 0.80, 0.70 };
new const Float:CLASS_KB[NUM_CLASSES]   = { 1.00, 1.30, 0.40, 1.00, 0.90, 1.10, 0.90, 0.90, 1.00, 0.50, 1.00, 1.20 };
new const Float:CLASS_COOL[NUM_CLASSES] = { 15.0, 8.0, 14.0, 12.0, 20.0, 18.0, 16.0, 18.0, 12.0, 16.0, 18.0, 9.0 };
new const CLASS_LVL[NUM_CLASSES]        = { 1, 1, 1, 1, 5, 8, 12, 16, 18, 20, 22, 25 };
new const CLASS_RGB[NUM_CLASSES][3]     =
{
    {0, 140, 0}, {255, 140, 0}, {40, 90, 255}, {200, 200, 255},
    {200, 0, 0}, {0, 110, 110}, {120, 255, 0}, {0, 200, 255},
    {150, 255, 0}, {255, 80, 0}, {255, 0, 180}, {120, 120, 255}
};

// Silah adlari (WeaponIdType sirasiyla) - V_<AD> / P_<AD> ayarlari icin
new const WEAPON_KEYNAME[31][] =
{
    "", "P228", "GLOCK", "SCOUT", "HEGRENADE", "XM1014", "C4", "MAC10", "AUG", "SMOKEGRENADE",
    "ELITE", "FIVESEVEN", "UMP45", "SG550", "GALIL", "FAMAS", "USP", "GLOCK18", "AWP", "MP5NAVY",
    "M249", "M3", "M4A1", "TMP", "G3SG1", "FLASHBANG", "DEAGLE", "SG552", "AK47", "KNIFE", "P90"
};

// Bosslar: Brute, Banshee, Overlord, Inferno, Reaper, Frostlord, Stormcaller, Hive Queen, Void
new const Float:BOSS_HP_MULT[NUM_BOSSES] = { 1.00, 0.80, 1.15, 1.00, 0.90, 1.05, 0.95, 1.10, 1.20 };
new const BOSS_SPD[NUM_BOSSES]           = { 255,  290,  260,  270,  300,  265,  285,  275,  280 };
new const Float:BOSS_GRAV[NUM_BOSSES]    = { 0.85, 0.65, 0.85, 0.80, 0.60, 0.85, 0.75, 0.80, 0.55 };
new const BOSS_RGB[NUM_BOSSES][3] =
{
    {255, 120, 0}, {190, 210, 255}, {160, 0, 255}, {255, 50, 0}, {120, 0, 190},
    {0, 190, 255}, {255, 240, 80}, {110, 255, 0}, {220, 0, 140}
};

// Mod rotasyonu: sans (%), minimum oyuncu
new const MODE_CHANCE[MODE_TOTAL] = { 0, 15, 5, 4, 5, 4, 5, 3, 2, 0 };
new const MODE_MINPL[MODE_TOTAL]  = { 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 };

// Meslek level kilitleri
new const JOB_LVL[NUM_JOBS] = { 1, 1, 2, 3, 4, 5, 6, 8, 10, 12, 14, 16, 18, 21, 24, 28, 7, 9, 11, 13, 15, 17, 20, 23, 26, 32 };

// Market: fiyat (AP), takim (0 insan / 1 zombi), round limiti (0 = sinirsiz)
new const ITEM_COST[NUM_ITEMS]  = { 12, 10, 12, 12, 5, 15, 10, 12, 25, 30, 40, 30, 20, 35, 15, 12, 10, 18, 15, 25, 8, 30, 10, 15, 20, 12, 25, 18 };
new const ITEM_TEAM[NUM_ITEMS]  = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1 };
new const ITEM_LIMIT[NUM_ITEMS] = { 3, 2, 2, 2, 3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 3, 1, 2, 1, 1, 1, 2, 2, 1, 1, 1, 1 };
// Satin alininca herkese duyurulan esyalar
new const ITEM_ANNOUNCE[NUM_ITEMS] = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1 };

// Ozel silahlar
new const SW_BASE_ENT[NUM_SPECIAL][] =
{
    "weapon_m4a1", "weapon_m249", "weapon_awp", "weapon_xm1014",
    "weapon_deagle", "weapon_p90", "weapon_ak47", "weapon_sg550"
};
new const WeaponIdType:SW_BASE_ID[NUM_SPECIAL] =
{
    WEAPON_M4A1, WEAPON_M249, WEAPON_AWP, WEAPON_XM1014,
    WEAPON_DEAGLE, WEAPON_P90, WEAPON_AK47, WEAPON_SG550
};
new const Float:SW_MULT[NUM_SPECIAL] = { 1.8, 1.5, 3.0, 1.6, 2.2, 1.6, 1.9, 2.4 };
new const SW_COST[NUM_SPECIAL]       = { 40, 60, 70, 45, 30, 50, 55, 80 };
new const SW_LVL[NUM_SPECIAL]        = { 3, 8, 12, 5, 4, 10, 15, 20 };
new const SW_BPAMMO[NUM_SPECIAL]     = { 180, 300, 60, 64, 70, 200, 180, 180 };
new const SW_RGB[NUM_SPECIAL][3]     =
{
    {0, 220, 255}, {255, 110, 0}, {200, 220, 255}, {120, 220, 255},
    {255, 210, 0}, {255, 60, 0}, {170, 0, 255}, {90, 0, 160}
};

// Perk maliyeti: (seviye + 1) * PERK_COST_STEP VC
#define PERK_COST_STEP 4

// Basarim -> unvan eslesmesi (-1 = herkese acik)
new const TITLE_ACH[NUM_TITLES] = { -1, 3, 2, 5, 7, 8, 10, 13, 12, 11 };

// Rutbe esikleri
new const RANK_LVL[NUM_RANKS] = { 1, 5, 10, 18, 26, 35, 45, 55 };

// Tema renkleri: A = ana (marka satiri, panel basligi), B = vurgu (sayilar), C = panel govdesi
new const THEME_A[NUM_THEMES][3] =
{
    {0, 200, 255}, {70, 255, 110}, {255, 55, 55}, {175, 95, 255}, {40, 150, 255}, {255, 130, 40}
};
new const THEME_B[NUM_THEMES][3] =
{
    {255, 70, 110}, {255, 90, 60}, {255, 170, 60}, {255, 90, 190}, {0, 230, 200}, {255, 60, 120}
};
new const THEME_C[NUM_THEMES][3] =
{
    {120, 220, 255}, {160, 255, 180}, {255, 150, 140}, {210, 170, 255}, {140, 200, 255}, {255, 195, 140}
};

// Silah menusu
new const PRIM_NAME[][] = { "AK-47", "M4A1 Carbine", "FAMAS", "Galil", "MP5 Navy", "UMP45", "P90", "M3 Super 90", "XM1014", "AUG", "SG552", "M249 SAW", "AWP", "G3SG1" };
new const PRIM_ENT[][]  = { "weapon_ak47", "weapon_m4a1", "weapon_famas", "weapon_galil", "weapon_mp5navy", "weapon_ump45", "weapon_p90", "weapon_m3", "weapon_xm1014", "weapon_aug", "weapon_sg552", "weapon_m249", "weapon_awp", "weapon_g3sg1" };
new const PRIM_AMMO[]   = { 180, 180, 180, 180, 240, 200, 200, 64, 64, 180, 180, 300, 60, 120 };
new const PRIM_LVL[]    = { 1, 1, 1, 1, 1, 2, 3, 2, 4, 6, 7, 9, 12, 14 };

new const SEC_NAME[][]  = { "USP", "Glock-18", "P228", "Desert Eagle", "Dual Elites", "Five-seveN" };
new const SEC_ENT[][]   = { "weapon_usp", "weapon_glock18", "weapon_p228", "weapon_deagle", "weapon_elite", "weapon_fiveseven" };
new const SEC_AMMO[]    = { 100, 120, 52, 70, 120, 100 };
new const SEC_LVL[]     = { 1, 1, 1, 2, 3, 5 };

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
new g_szZClaw[NUM_CLASSES][96], g_szBClaw[NUM_BOSSES][96], g_szNemClaw[96], g_szAsnClaw[96];
new g_szWepV[31][96], g_szWepP[31][96], bool:g_bEmitting;
new bool:g_bVoxCountdown = true;

// v1.4: HUD sirasi, karsilama, gorev, evrim, lazer, bomba modlari, ikmal
new Float:g_fSlotEnd[33][NUM_SLOTS], g_szSlotQ[33][NUM_SLOTS][128], g_iSlotQC[33][NUM_SLOTS], Float:g_fSlotQH[33][NUM_SLOTS], Float:g_fSlotQT[33][NUM_SLOTS];
new bool:g_bWelcomed[33], bool:g_bMotdShown[33], Float:g_fMapStart;
new g_iRoundKills[33], g_iRoundHS[33], g_iQuest[33], bool:g_bQuestDone[33], bool:g_bAlpha[33];
new g_iMapInf[33], g_iMapBossDmg[33];
new g_iMines[33], g_iPlantAction[33], bool:g_bMineHint[33];
new g_iNadeMode[33][3], Float:g_fNadeHud[33];
new g_iAirdropClock, g_iBossFxStep, Float:g_fBossFxPos[3];
new Float:g_fPoolPos[6][3], Float:g_fPoolEnd[6], Float:g_fEclipseEnd, Float:g_fBlizzardEnd;
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
new g_pStartAP, g_pArmorProtect, g_pVipContact;
new g_pBossRounds, g_pBossHPPer, g_pBossFinal, g_pBossDmg, g_pBossAbil, g_pSpecialRounds, g_pMultiChance, g_pRoundsTotal;
new g_pSpeedHuman, g_pSpeedZombie, g_pSpeedFov, g_pNemDmg, g_pAsnDmg, g_pMinionDmg, g_pZombieDmg, g_pHumanHP;
new g_pZSpeed, g_pHSpeed, g_pMvpAP, g_pMvpVC, g_pGiveNades, g_pLastHumanHP, g_pInfectAP, g_pKillAP;
new g_pLmEnable, g_pLmCost, g_pLmMax, g_pLmMaxVip, g_pLmTeamMax, g_pLmHealth, g_pLmDamage, g_pLmZMult, g_pLmWear, g_pLmFree, g_pLmBoss;
new g_pNadeModes, g_pNadeProx, g_pNadeLaser, g_pNadeHoming, g_pCluster;
new g_pAirdrop, g_pAirdropEvery, g_pMotd, g_pQuests, g_pEvolve, g_pJoinMsg;

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

SetDefaultResources()
{
    // Sesler: hepsi orijinal CS 1.6 / Half-Life dosyalari.
    // DefSound(anahtar, birinci tercih, yedek): dosya sunucuda yoksa yedege gecer.
    DefSound("ZOMBIE_INFECT",  "zombie/zo_alert20.wav",      "player/bhit_flesh-1.wav");
    DefSound("ZOMBIE_PAIN",    "zombie/zo_pain1.wav",        "player/pl_pain2.wav");
    DefSound("ZOMBIE_DIE",     "zombie/zo_pain2.wav",        "player/die3.wav");
    DefSound("ROUND_START",    "ambience/the_horror2.wav",   "");
    DefSound("EVENT_START",    "ambience/thunder_clap.wav",  "");
    DefSound("MODE_START",     "ambience/the_horror4.wav",   "");
    DefSound("BOSS_SPAWN",     "ambience/the_horror4.wav",   "");
    DefSound("BOSS_SLAM",      "weapons/c4_explode1.wav",    "");
    DefSound("BOSS_SCREAM",    "ambience/the_horror1.wav",   "");
    DefSound("BOSS_SUMMON",    "ambience/the_horror3.wav",   "");
    DefSound("BOSS_DEATH",     "weapons/c4_explode1.wav",    "");
    DefSound("COUNTDOWN_BEEP", "buttons/blip1.wav",          "");
    DefSound("LEVEL_UP",       "plats/elevbell1.wav",        "");
    DefSound("LAST_HUMAN",     "ambience/the_horror3.wav",   "");
    DefSound("LIGHTNING",      "ambience/thunder_clap.wav",  "");
    DefSound("AMBIENT",        "ambience/the_horror3.wav",   "");
    DefSound("HEARTBEAT",      "player/heartbeat1.wav",      "");
    DefSound("METEOR",         "weapons/c4_explode1.wav",    "");
    DefSound("ABILITY_BURST",  "zombie/zo_alert30.wav",      "player/pl_pain5.wav");
    DefSound("ABILITY_LEAP",   "zombie/zo_attack1.wav",      "player/pl_pain7.wav");
    DefSound("ABILITY_SHIELD", "items/suitchargeok1.wav",    "");
    DefSound("ABILITY_SCREAM", "ambience/the_horror2.wav",   "");
    DefSound("ABILITY_DRAIN",  "zombie/zo_attack2.wav",      "player/pl_pain6.wav");
    DefSound("ABILITY_CLOAK",  "buttons/blip1.wav",          "");
    DefSound("ABILITY_TOXIC",  "bullchicken/bc_acid1.wav",   "weapons/sg_explode.wav");
    DefSound("ABILITY_FROST",  "debris/glass1.wav",          "");
    DefSound("HUMAN_WIN",      "radio/ctwin.wav",            "");
    DefSound("ZOMBIE_WIN",     "radio/terwin.wav",           "");
    DefSound("ACH_UNLOCK",     "plats/elevbell1.wav",        "");
    DefSound("SHOP_BUY",       "items/gunpickup2.wav",       "");
    DefSound("DAILY",          "items/suitchargeok1.wav",    "");
    DefSound("HEADSHOT",       "player/headshot1.wav",       "");
    DefSound("KILL_DOUBLE",    "buttons/bell1.wav",          "");
    DefSound("KILL_TRIPLE",    "buttons/bell1.wav",          "");
    DefSound("KILL_MULTI",     "buttons/bell1.wav",          "");
    DefSound("KILL_MEGA",      "buttons/bell1.wav",          "");
    DefSound("KILL_MONSTER",   "buttons/bell1.wav",          "");
    DefSound("STREAK_5",       "ambience/thunder_clap.wav",  "");
    DefSound("STREAK_10",      "ambience/thunder_clap.wav",  "");
    DefSound("STREAK_15",      "ambience/thunder_clap.wav",  "");
    DefSound("NADE_FIRE",      "ambience/flameburst1.wav",   "weapons/c4_explode1.wav");
    DefSound("NADE_FROST",     "debris/glass2.wav",          "weapons/sg_explode.wav");
    DefSound("NADE_INFECT",    "bullchicken/bc_spithit1.wav", "weapons/sg_explode.wav");
    DefSound("FREEZE",         "debris/glass1.wav",          "");
    DefSound("BURN",           "ambience/burning1.wav",      "");
    DefSound("ANTIDOTE",       "items/smallmedkit1.wav",     "");
    DefSound("MADNESS",        "ambience/the_horror1.wav",   "");
    DefSound("SW_FIRE",        "weapons/electro5.wav",       "");
    DefSound("ZAP",            "weapons/electro4.wav",       "");
    DefSound("MVP",            "events/task_complete.wav",   "plats/elevbell1.wav");
    DefSound("VIP_JOIN",       "buttons/bell1.wav",          "");
    DefSound("BOSS_WARN",      "buttons/blip2.wav",          "");
    DefSound("BOSS_ROAR",      "garg/gar_alert1.wav",        "ambience/the_horror1.wav");
    DefSound("BOSS_ABILITY",   "",                           "");
    DefSound("ZOMBIE_IDLE",    "zombie/zo_idle1.wav",        "");
    DefSound("ZOMBIE_SLASH",   "zombie/claw_miss1.wav",      "");
    DefSound("ZOMBIE_HITWALL", "zombie/claw_miss2.wav",      "");
    DefSound("ZOMBIE_HIT",     "zombie/claw_strike1.wav",    "");
    DefSound("ZOMBIE_STAB",    "zombie/claw_strike2.wav",    "");
    DefSound("ZOMBIE_ACID",    "bullchicken/bc_acid2.wav",   "weapons/sg_explode.wav");
    DefSound("ZOMBIE_HEAL",    "items/smallmedkit1.wav",     "");
    DefSound("ZOMBIE_BLINK",   "weapons/electro4.wav",       "");
    DefSound("ZOMBIE_SHOCK",   "garg/gar_stomp1.wav",        "weapons/c4_explode1.wav");

    // v1.4
    DefSound("WELCOME",          "events/tutor_msg.wav",       "plats/elevbell1.wav");
    DefSound("PLAYER_JOIN",      "buttons/bell1.wav",          "");
    DefSound("PLAYER_LEAVE",     "buttons/blip2.wav",          "");
    DefSound("BOSS_SOON",        "ambience/the_horror2.wav",   "");
    DefSound("BOSS_INTRO",       "ambience/the_horror4.wav",   "");
    DefSound("BOSS_STEP",        "garg/gar_step1.wav",         "");
    DefSound("BOSS_PHASE",       "ambience/thunder_clap.wav",  "");
    DefSound("BOSS_ENRAGE",      "garg/gar_alert3.wav",        "ambience/the_horror1.wav");
    DefSound("LM_DEPLOY",        "weapons/mine_deploy.wav",    "weapons/c4_plant.wav");
    DefSound("LM_CHARGE",        "weapons/mine_charge.wav",    "weapons/c4_click.wav");
    DefSound("LM_ACTIVATE",      "weapons/mine_activate.wav",  "buttons/blip2.wav");
    DefSound("LM_HIT",           "weapons/electro4.wav",       "");
    DefSound("LM_BREAK",         "weapons/explode3.wav",       "weapons/c4_explode1.wav");
    DefSound("LM_PICKUP",        "items/gunpickup2.wav",       "");
    DefSound("NADE_MODE",        "buttons/lightswitch2.wav",   "weapons/zoom.wav");
    DefSound("NADE_BEEP",        "weapons/c4_beep1.wav",       "buttons/blip1.wav");
    DefSound("NADE_ARM",         "weapons/c4_click.wav",       "buttons/blip1.wav");
    DefSound("NADE_CLUSTER",     "weapons/explode4.wav",       "weapons/c4_explode1.wav");
    DefSound("AIRDROP_INCOMING", "items/suitchargeok1.wav",    "buttons/bell1.wav");
    DefSound("AIRDROP_LAND",     "debris/metal2.wav",          "weapons/c4_click.wav");
    DefSound("AIRDROP_LOOT",     "items/ammopickup2.wav",      "items/gunpickup2.wav");
    DefSound("QUEST_DONE",       "events/task_complete.wav",   "plats/elevbell1.wav");
    DefSound("EVOLVE",           "zombie/zo_alert30.wav",      "ambience/the_horror2.wav");
    DefSound("SPEED_START",      "weapons/rocketfire1.wav",    "ambience/thunder_clap.wav");
    DefSound("SPEED_WIND",       "ambience/wind1.wav",         "");
    DefSound("STORM_STRIKE",     "ambience/thunder_clap.wav",  "");
    DefSound("BLACKOUT",         "buttons/lightswitch2.wav",   "buttons/blip2.wav");
    DefSound("FINAL_ROUND",      "ambience/the_horror4.wav",   "");
    DefSound("MAP_END",          "events/task_complete.wav",   "plats/elevbell1.wav");
    DefSound("FROST_NOVA",       "debris/glass2.wav",          "debris/glass1.wav");
    DefSound("THUNDER",          "ambience/thunder_clap.wav",  "");
    DefSound("ACID_POOL",        "bullchicken/bc_acid1.wav",   "weapons/sg_explode.wav");
    DefSound("GRAVITY_WELL",     "x/x_teleattack1.wav",        "ambience/the_horror2.wav");
    DefSound("ECLIPSE",          "x/x_laugh1.wav",             "ambience/the_horror1.wav");

    // Boss'lara ozel sesler (B<no>_<olay>): yoksa genel BOSS_<olay> kullanilir
    static const BEV[][] = { "SPAWN", "ROAR", "SCREAM", "ABILITY", "DEATH" };
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
    new key[24];
    for (new b = 0; b < NUM_BOSSES; b++)
    {
        for (new e = 0; e < 5; e++)
        {
            formatex(key, charsmax(key), "B%d_%s", b, BEV[e]);
            DefSound(key, BSND[b][e], "");
        }
    }

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
    TrieSetString(g_tRes, "Z0_MODEL", "terror");
    TrieSetString(g_tRes, "Z1_MODEL", "leet");
    TrieSetString(g_tRes, "Z2_MODEL", "arctic");
    TrieSetString(g_tRes, "Z3_MODEL", "guerilla");
    TrieSetString(g_tRes, "Z4_MODEL", "terror");
    TrieSetString(g_tRes, "Z5_MODEL", "leet");
    TrieSetString(g_tRes, "Z6_MODEL", "arctic");
    TrieSetString(g_tRes, "Z7_MODEL", "guerilla");
    TrieSetString(g_tRes, "Z8_MODEL", "terror");
    TrieSetString(g_tRes, "Z9_MODEL", "arctic");
    TrieSetString(g_tRes, "Z10_MODEL", "guerilla");
    TrieSetString(g_tRes, "Z11_MODEL", "leet");
    TrieSetString(g_tRes, "B0_MODEL", "terror");
    TrieSetString(g_tRes, "B1_MODEL", "vip");
    TrieSetString(g_tRes, "B2_MODEL", "leet");
    TrieSetString(g_tRes, "B3_MODEL", "arctic");
    TrieSetString(g_tRes, "B4_MODEL", "gsg9");
    TrieSetString(g_tRes, "B5_MODEL", "sas");
    TrieSetString(g_tRes, "B6_MODEL", "gign");
    TrieSetString(g_tRes, "B7_MODEL", "guerilla");
    TrieSetString(g_tRes, "B8_MODEL", "urban");
    TrieSetString(g_tRes, "NEMESIS_MODEL",  "terror");
    TrieSetString(g_tRes, "ASSASSIN_MODEL", "leet");
    TrieSetString(g_tRes, "SURVIVOR_MODEL", "gign");
    TrieSetString(g_tRes, "SNIPER_MODEL",   "sas");

    TrieSetString(g_tRes, "LASERMINE_MODEL", "models/v_tripmine.mdl");
    TrieSetString(g_tRes, "AIRDROP_MODEL",   "models/w_weaponbox.mdl");
    TrieSetString(g_tRes, "SKY_MODE", "1");
    TrieSetString(g_tRes, "SKY_LIST", "night de_storm tornsky black space hav office cx backalley city");
}

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

public plugin_precache()
{
    g_tRes = TrieCreate();
    SetDefaultResources();
    LoadResourceIni();

    new path[128], key[24];

    // Sesler
    for (new i = 0; i < sizeof SOUND_KEYS; i++)
    {
        if (TrieGetString(g_tRes, SOUND_KEYS[i], path, charsmax(path)) && path[0])
        {
            if (containi(path, ".mp3") != -1)
                precache_generic(path);
            else
                precache_sound(path);
        }
    }

    // Geri sayim sesi (VOX)
    if (g_bVoxCountdown)
    {
        for (new i = 1; i <= 10; i++)
        {
            formatex(path, charsmax(path), "vox/%s.wav", VOX_NUM[i]);
            precache_sound(path);
        }
    }

    // Zombi / boss / ozel karakter modelleri
    for (new i = 0; i < NUM_CLASSES; i++)
    {
        formatex(key, charsmax(key), "Z%d_MODEL", i);
        GetPlayerModel(key, g_szZModel[i], charsmax(g_szZModel[]));
    }
    for (new i = 0; i < NUM_BOSSES; i++)
    {
        formatex(key, charsmax(key), "B%d_MODEL", i);
        GetPlayerModel(key, g_szBModel[i], charsmax(g_szBModel[]));
    }
    GetPlayerModel("NEMESIS_MODEL",  g_szNemModel,   charsmax(g_szNemModel));
    GetPlayerModel("ASSASSIN_MODEL", g_szAsnModel,   charsmax(g_szAsnModel));
    GetPlayerModel("SURVIVOR_MODEL", g_szSurvModel,  charsmax(g_szSurvModel));
    GetPlayerModel("SNIPER_MODEL",   g_szSnipModel,  charsmax(g_szSnipModel));
    GetPlayerModel("HUMAN_MODEL",    g_szHumanModel, charsmax(g_szHumanModel));
    GetPlayerModel("VIP_MODEL",      g_szVipModel,   charsmax(g_szVipModel));
    GetPlayerModel("ADMIN_MODEL",    g_szAdminModel, charsmax(g_szAdminModel));

    // Pence modelleri (genel + sinif / boss / ozel karakter bazinda)
    GetFileModel("CLAW_MODEL", g_szClawModel, charsmax(g_szClawModel));
    for (new i = 0; i < NUM_CLASSES; i++)
    {
        formatex(key, charsmax(key), "Z%d_CLAW", i);
        GetFileModel(key, g_szZClaw[i], charsmax(g_szZClaw[]));
    }
    for (new i = 0; i < NUM_BOSSES; i++)
    {
        formatex(key, charsmax(key), "B%d_CLAW", i);
        GetFileModel(key, g_szBClaw[i], charsmax(g_szBClaw[]));
    }
    GetFileModel("NEMESIS_CLAW", g_szNemClaw, charsmax(g_szNemClaw));
    GetFileModel("ASSASSIN_CLAW", g_szAsnClaw, charsmax(g_szAsnClaw));

    // Ozel silah modelleri
    for (new i = 0; i < NUM_SPECIAL; i++)
    {
        formatex(key, charsmax(key), "SW%d_VMODEL", i);
        GetFileModel(key, g_szSWView[i], charsmax(g_szSWView[]));
        formatex(key, charsmax(key), "SW%d_PMODEL", i);
        GetFileModel(key, g_szSWPlayer[i], charsmax(g_szSWPlayer[]));
    }

    // Normal silah modelleri: V_AK47 / P_AK47 ...
    for (new w = 1; w < 31; w++)
    {
        formatex(key, charsmax(key), "V_%s", WEAPON_KEYNAME[w]);
        GetFileModel(key, g_szWepV[w], charsmax(g_szWepV[]));
        formatex(key, charsmax(key), "P_%s", WEAPON_KEYNAME[w]);
        GetFileModel(key, g_szWepP[w], charsmax(g_szWepP[]));
    }

    // Sinif ve boss'a ozel sesler (sadece ini'de tanimlanmissa)
    static const ZEV[][] = { "PAIN", "DIE", "IDLE", "SLASH", "HIT", "STAB", "HITWALL", "INFECT", "ABILITY" };
    static const BEV[][] = { "SPAWN", "ROAR", "SCREAM", "ABILITY", "DEATH", "MUSIC" };
    for (new i = 0; i < NUM_CLASSES; i++)
    {
        for (new e = 0; e < sizeof ZEV; e++)
        {
            formatex(key, charsmax(key), "Z%d_%s", i, ZEV[e]);
            PrecacheSoundKey(key);
        }
    }
    for (new i = 0; i < NUM_BOSSES; i++)
    {
        for (new e = 0; e < sizeof BEV; e++)
        {
            formatex(key, charsmax(key), "B%d_%s", i, BEV[e]);
            PrecacheSoundKey(key);
        }
    }
    for (new m = 0; m < MODE_TOTAL; m++)
    {
        formatex(key, charsmax(key), "MODE%d_MUSIC", m);
        PrecacheSoundKey(key);
    }

    // Sprite'lar (orijinal dosyalar)
    g_sprRing      = precache_model("sprites/shockwave.spr");
    g_sprBeam      = precache_model("sprites/laserbeam.spr");
    g_sprLightning = precache_model("sprites/lgtning.spr");
    g_sprExplode   = precache_model("sprites/zerogxplode.spr");
    g_sprSmoke     = precache_model("sprites/steam1.spr");

    // Istege bagli sprite'lar: dosya yoksa sunucu cokmesin diye kontrol edilir
    g_sprBlood      = PrecacheSafe("sprites/blood.spr");
    g_sprBloodSpray = PrecacheSafe("sprites/bloodspray.spr");
    g_sprHeadMark   = PrecacheSafe(GetResString("BOSS_MARK_SPRITE", "sprites/glow01.spr"));
    g_sprLaser      = g_sprBeam;
    g_sprFlare      = PrecacheSafe("sprites/flare6.spr");
    if (!g_sprFlare)
        g_sprFlare  = g_sprHeadMark;

    // Lazer mayini + hava ikmali modelleri
    GetFileModel("LASERMINE_MODEL", g_szMineModel, charsmax(g_szMineModel));
    if (!g_szMineModel[0] && file_exists("models/w_c4.mdl", true))
    {
        copy(g_szMineModel, charsmax(g_szMineModel), "models/w_c4.mdl");
        precache_model(g_szMineModel);
    }
    GetFileModel("AIRDROP_MODEL", g_szDropModel, charsmax(g_szDropModel));
    if (!g_szDropModel[0] && file_exists("models/w_weaponbox.mdl", true))
    {
        copy(g_szDropModel, charsmax(g_szDropModel), "models/w_weaponbox.mdl");
        precache_model(g_szDropModel);
    }

    PickSky();
}

// Gokyuzu: listeden (orijinal CS gokyuzleri) her haritada rastgele biri
PickSky()
{
    new mode = str_to_num(GetResString("SKY_MODE", "1"));
    if (mode <= 0)
        return;

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
        precache_generic(path);
    }
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

PrecacheSoundKey(const key[])
{
    new path[128];
    if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
        return;
    if (containi(path, ".mp3") != -1)
        precache_generic(path);
    else
        precache_sound(path);
}

PrecacheSafe(const path[])
{
    if (!path[0] || !file_exists(path, true))
    {
        if (path[0])
            log_amx("[Vexmira] Dosya bulunamadi, atlandi: %s", path);
        return 0;
    }
    return precache_model(path);
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
    precache_model(model);
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
    precache_model(out);
}

LoadResourceIni()
{
    new file[96], line[256], key[32], value[192], stock_path[192];
    get_configsdir(file, charsmax(file));
    add(file, charsmax(file), "/vexmira_resources.ini");

    new fp = fopen(file, "rt");
    if (!fp)
    {
        log_amx("[Vexmira] vexmira_resources.ini bulunamadi, varsayilanlar kullaniliyor.");
        return;
    }

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

        if (!key[0])
            continue;

        if (equali(key, "VOX_COUNTDOWN"))
        {
            g_bVoxCountdown = (str_to_num(value) != 0);
            continue;
        }

        // Ses dosyasi: ozel dosya yoksa varsayilani koru
        if (value[0] && (containi(value, ".wav") != -1 || containi(value, ".mp3") != -1))
        {
            if (containi(value, ".mp3") != -1)
                copy(stock_path, charsmax(stock_path), value);
            else
                formatex(stock_path, charsmax(stock_path), "sound/%s", value);

            // Sunucuda olmayan ses oyunculari "server failed to transmit file" ile atar: kontrol et
            if (!file_exists(stock_path, true))
            {
                log_amx("[Vexmira] Ses bulunamadi: %s (%s) - varsayilan kullanilacak", stock_path, key);
                continue;
            }
        }

        TrieSetString(g_tRes, key, value);
    }
    fclose(fp);
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
    g_pGiveNades    = register_cvar("vex_give_nades", "ab");
    g_pLmEnable     = register_cvar("vex_lm_enable", "1");
    g_pLmCost       = register_cvar("vex_lm_cost", "12");
    g_pLmFree       = register_cvar("vex_lm_free", "1");
    g_pLmMax        = register_cvar("vex_lm_max", "2");
    g_pLmMaxVip     = register_cvar("vex_lm_max_vip", "3");
    g_pLmTeamMax    = register_cvar("vex_lm_team_max", "16");
    g_pLmHealth     = register_cvar("vex_lm_health", "450");
    g_pLmDamage     = register_cvar("vex_lm_damage", "55");
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

    // ReAPI hook'lari
    RegisterHookChain(RG_CSGameRules_CheckWinConditions, "rg_CheckWinConditions", false);
    RegisterHookChain(RG_CSGameRules_RestartRound,       "rg_RestartRound", false);
    RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd,   "rg_FreezeEnd", true);
    RegisterHookChain(RG_RoundEnd,                       "rg_RoundEnd", true);
    RegisterHookChain(RG_CBasePlayer_Spawn,              "rg_PlayerSpawn", true);
    RegisterHookChain(RG_CBasePlayer_TakeDamage,         "rg_TakeDamage", false);
    RegisterHookChain(RG_CBasePlayer_TakeDamage,         "rg_TakeDamagePost", true);
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

    // Lazer: V = +setlaser, C = +dellaser (C varsayilan olarak radio3: hedef mayinsa sokulur)
    register_clcmd("+setlaser", "cmd_lm_plant");
    register_clcmd("-setlaser", "cmd_lm_release");
    register_clcmd("+dellaser", "cmd_lm_take");
    register_clcmd("-dellaser", "cmd_lm_release");
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

    g_fMapStart = get_gametime();
    g_iRound = 1;
    ShuffleBosses();
}

// configs/vexmira.cfg dosyasindaki ayarlari yukle
public plugin_cfg()
{
    new file[128];
    get_configsdir(file, charsmax(file));
    add(file, charsmax(file), "/vexmira.cfg");

    if (file_exists(file))
        server_cmd("exec %s", file);
    else
        log_amx("[Vexmira] %s bulunamadi, varsayilan cvar degerleri kullaniliyor.", file);

    LoadTop();
    set_task(1.5, "task_EnforceRoundInfinite", TASK_ROUNDINF);
}

// Round suresi dolunca oyun kendi bitirmesin (CheckWin bitirir); cfg unutulsa bile
public task_EnforceRoundInfinite()
{
    new v[32];
    get_cvar_string("mp_round_infinite", v, charsmax(v));
    if (!equal(v, "1") && contain(v, "a") == -1)
        set_cvar_string("mp_round_infinite", "abcdefghijk");
}

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

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p) || p == id)
            continue;
        if (country[0])
            client_print_color(p, print_team_default, "%s %L", CHAT_PREFIX, p, "JOIN_CONNECTING_C", name, country);
        else
            client_print_color(p, print_team_default, "%s %L", CHAT_PREFIX, p, "JOIN_CONNECTING", name);
    }
}

public client_putinserver(id)
{
    ResetPlayer(id);
    HudReset(id);

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
        g_iClass[id] = random(4);
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

    ResetPlayer(id);

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
    g_szKey[id][0] = 0; g_bLoaded[id] = false; g_iClassNext[id] = -1; g_iJobNext[id] = -1;
    g_bTrailOn[id] = false;
    for (new i = 0; i < NUM_PERKS; i++)
        g_iPerk[id][i] = 0;

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
    HudTo(id, SL_PERS, THEME_C[t][0], THEME_C[t][1], THEME_C[t][2], 6.0, "WELCOME_HUD2");
    PlayKey(id, "WELCOME");
    FadeOne(id, THEME_A[t][0], THEME_A[t][1], THEME_A[t][2], 60, 1.2);

    Chat(id, "WELCOME", name);
    Chat(id, "WELCOME_2");
    Chat(id, "WELCOME_3");
    Chat(id, "WELCOME_4");
    if (get_pcvar_num(g_pLmEnable))
        Chat(id, "LM_BIND_HINT");
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
            client_print_color(p, print_team_default, "%s %L", CHAT_PREFIX, p, key, name, val);
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

    // Diger plugin'lerin bilinen kelime komutlari (oylama vb.) dokunulmadan gecsin
    static const PASS[][] = { "rtv", "rockthevote", "nominate", "nextmap", "timeleft", "thetime", "currentmap", "ff", "motd" };
    for (new i = 0; i < sizeof PASS; i++)
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
        set_hudmessage(255, 215, 0, 0.535, 0.47, 0, 0.0, 0.9, 0.05, 0.25, 4);
        show_hudmessage(id, "+%d AP", amount);
    }
}

// AP'yi CS para gostergesinde goster
SyncMoney(id)
{
    if (!is_user_connected(id) || is_user_hltv(id))
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
        HudText(id, SL_REWARD, 0, 255, 160, 1.0, txt);
    }

    if (g_iLevel[id] > old)
        LevelUp(id, old);

    CheckAch(id);
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
    FadeOne(id, 0, 255, 140, 90, 0.6);
    PlayKey(id, "LEVEL_UP");
    HudTo(id, SL_PERS, 0, 255, 140, 3.5, "LEVEL_UP_HUD", g_iLevel[id]);
    Chat(id, "LEVELUP_VC", vc);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && p != id)
            client_print_color(p, id, "%s %L", CHAT_PREFIX, p, "LEVELUP_CHAT", name, g_iLevel[id]);
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
            client_print_color(p, id, "%s %L", CHAT_PREFIX, p, "RANKUP_CHAT", name, rn);
        }
    }

    SaveData(id);
}

ChatKeyName(id, const msgKey[], const prefix[], idx)
{
    new key[16], nm[48];
    formatex(key, charsmax(key), "%s%d", prefix, idx);
    formatex(nm, charsmax(nm), "%L", id, key);
    Chat(id, msgKey, nm);
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
    g_iVC[id] += 3;
    AddAP(id, 25, false, false);

    new key[16], name[32], Float:o[3];
    formatex(key, charsmax(key), "ACH_NAME_%d", bit);
    get_user_name(id, name, charsmax(name));
    get_entvar(id, var_origin, o);

    new txt[128];
    formatex(txt, charsmax(txt), "%L^n%L  (+3 VC  +25 AP)", id, "ACH_POPUP", id, key);
    HudText(id, SL_PERS, 255, 200, 40, 4.0, txt);

    PlayKey(id, "ACH_UNLOCK");
    FxRing(o, 255, 215, 0, 260);
    FadeOne(id, 255, 215, 0, 70, 0.7);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p))
            continue;
        new an[48];
        formatex(an, charsmax(an), "%L", p, key);
        client_print_color(p, id, "%s %L", CHAT_PREFIX, p, "ACH_CHAT", name, an);
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
    new ap = 20 + 10 * s;
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
    HudText(id, SL_PERS, 255, 200, 40, 4.0, txt);
    Chat(id, "DAILY_CHAT", g_iDailyStreak[id], ap, vc, xp);

    if (g_iDailyStreak[id] < 7)
        Chat(id, "DAILY_NEXT");

    CheckAch(id);
    SaveData(id);
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
    remove_task(TASK_ANNOUNCE);
    remove_task(TASK_BOSSCAST);
    remove_task(TASK_BOSSHIT);
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
    ApplyWorldEvent();

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

// Bosslar karisik sirayla gelir, ayni boss arka arkaya gelmez
ShuffleBosses()
{
    new last = (g_iBossBagPos > 0 && g_iBossBagPos <= NUM_BOSSES) ? g_iBossBag[NUM_BOSSES - 1] : -1;
    for (new i = 0; i < NUM_BOSSES; i++)
        g_iBossBag[i] = i;
    for (new i = NUM_BOSSES - 1; i > 0; i--)
    {
        new j = random(i + 1), t = g_iBossBag[i];
        g_iBossBag[i] = g_iBossBag[j];
        g_iBossBag[j] = t;
    }
    if (g_iBossBag[0] == last)
    {
        new t = g_iBossBag[0];
        g_iBossBag[0] = g_iBossBag[NUM_BOSSES - 1];
        g_iBossBag[NUM_BOSSES - 1] = t;
    }
    g_iBossBagPos = 0;
}

NextBoss()
{
    if (g_iBossBagPos >= NUM_BOSSES)
        ShuffleBosses();
    return g_iBossBag[g_iBossBagPos++];
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
        if (g_iForceBoss >= 0 && g_iForceBoss < NUM_BOSSES)
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
            client_print_color(p, print_team_default, "%s %L", CHAT_PREFIX, p, "ROUND_CHAT2", g_iRound, total);
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
        if (g_bFinalBoss)
            HudAll(SL_ALERT, 255, 40, 40, 3.0, "FINAL_BOSS_HUD");
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
        HudAll(SL_ANN, 255, 110, 30, 4.0, key);
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
        HudAll(SL_ANN, 0, 200, 255, 3.5, "ROUND_CALM", g_iRound);

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

stock PlayVoxAll(const key[])
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_AMB))
            PlayKey(p, key);
    }
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

    new bool:wasActive = g_bRoundActive;
    g_bRoundActive = false;

    if (!wasActive)
        return;

    if (status == WINSTATUS_CTS)
    {
        g_iHumanStreak++;
        g_iZombieStreak = 0;
        if (g_iHumanStreak >= 3)
            LiveAll(0, "LIVE_HSTREAK", 2, g_iHumanStreak);

        HudAll(SL_ANN, 0, 255, 140, 4.0, "HUMANS_WIN");
        PlayKey(0, "HUMAN_WIN");

        new xp = 25, ap = 6;
        switch (g_iMode)
        {
            case MODE_BOSS:                     { xp = 70; ap = 15; }
            case MODE_SURVIVOR, MODE_SNIPER:    { xp = 40; ap = 10; }
            case MODE_NEMESIS, MODE_ASSASSIN:   { xp = 60; ap = 12; }
            case MODE_ARMAGEDDON, MODE_PLAGUE:  { xp = 50; ap = 10; }
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

        HudAll(SL_ANN, 255, 50, 50, 4.0, "ZOMBIES_WIN");
        PlayKey(0, "ZOMBIE_WIN");

        for (new id = 1; id <= g_iMax; id++)
        {
            if (is_user_connected(id) && g_bZombie[id] && !g_bMinion[id])
                Reward(id, 15, 4);
        }
    }

    if (status == WINSTATUS_CTS || status == WINSTATUS_TERRORISTS)
        RoundSummary();

    if (g_iRound >= RoundsTotal())
        set_task(1.5, "task_MapEndAwards");

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
            HudText(p, SL_ALERT, 255, 200, 40, 4.0, txt);
            client_print_color(p, mvp, "%s %L", CHAT_PREFIX, p, "MVP_CHAT2", name, g_iRoundDmg[mvp], g_iRoundKills[mvp], g_iRoundInf[mvp], ap, vc);
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
    new topK, topI, topB, vK, vI, vB;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_bot(id))
            continue;
        if (g_iMapKills[id] > vK)    { vK = g_iMapKills[id];    topK = id; }
        if (g_iMapInf[id] > vI)      { vI = g_iMapInf[id];      topI = id; }
        if (g_iMapBossDmg[id] > vB)  { vB = g_iMapBossDmg[id];  topB = id; }
    }

    HudAll(SL_ANN, 255, 200, 40, 5.0, "MAPEND_HUD");
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
            client_print_color(p, who, "%s %L", CHAT_PREFIX, p, key, name, val);
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
                    set_dhudmessage(255, 60, 60, -1.0, Y_COUNT, 0, 0.0, 1.0, 0.0, 0.0);
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
    TickLotto();
    TickVip();
    TickCosmetics();
    TickMineHints();

    // Canli sunucu yorumlari (~2 dakikada bir)
    if (g_iFrame % 130 == 65)
        LiveChatter();
    TickFlares();

    // Bilgilendirme mesajlari
    if (g_iFrame % 80 == 0)
    {
        new k[10];
        formatex(k, charsmax(k), "ADV_%d", random_num(1, NUM_ADS));
        for (new p = 1; p <= g_iMax; p++)
        {
            if (is_user_connected(p) && !(g_iSet[p] & SET_NO_ADS))
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

    // Son saniye uyarilari
    new tl = RoundTimeLeft();
    if (tl == 30)
        LiveAll(0, "LIVE_30S", 3);
    else if (tl == 10)
        HudAll(SL_ALERT, 255, 200, 40, 2.0, "HUD_10S");

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
        set_dhudmessage(255, 170, 40, -1.0, Y_COUNT, 0, 0.0, 3.0, 0.0, 0.0);
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
            set_hudmessage(255, 90, 90, -1.0, Y_COUNT + 0.05, 0, 0.0, 1.1, 0.0, 0.0, 4);
            show_hudmessage(id, "%L", id, "RESPAWN_IN", floatround(g_fRespawnAt[id] - now, floatround_ceil));
        }
    }
}

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
        FixGravity(id);

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
            ExecuteHamB(Ham_TakeDamage, id, 0, attacker, g_bZombie[id] ? 35.0 : 6.0, DMG_BURN);
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
            // Ara sira hirlama sesi
            if (!g_bBoss[id] && random_num(1, 15) == 1)
                EmitZombieSound(id, "IDLE", "ZOMBIE_IDLE");

            if (g_bZRegen[id])
                HealTo(id, 60, g_iMaxHP[id]);
            if (g_iEvent == EV_BERSERK && !g_bBoss[id])
                HealTo(id, 40, g_iMaxHP[id]);

            if (g_bBoss[id] || g_bNemesis[id])
                FxLight(o, 255, 20, 20, 30, 11, 5);
            else if (g_bAssassin[id])
                FxLight(o, 90, 0, 140, 18, 11, 5);
            else if (g_fCloak[id] <= 0.0)
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
                PlayKey(id, "HEARTBEAT");
                if (!(g_iSet[id] & SET_NO_FX))
                    FadeOne(id, 255, 0, 0, 45, 0.9);
            }
        }
    }

    if (humans == 1 && !g_bLastAnn && AllowsInfection())
    {
        g_bLastAnn = true;
        new name[32];
        get_user_name(last, name, charsmax(name));
        HudAll(SL_ALERT, 255, 200, 40, 3.0, "LAST_HUMAN");
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
        set_entvar(id, var_health, floatmin(float(maxhp), hp + float(amount)));
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

/* ---------------- Meteor ---------------- */

TickMeteor()
{
    if (g_iEvent != EV_METEOR)
        return;

    if (++g_iMeteorTick < 4)
        return;
    g_iMeteorTick = 0;

    new alive[32], n;
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_alive(id))
            alive[n++] = id;
    }
    if (!n)
        return;

    new Float:o[3];
    get_entvar(alive[random(n)], var_origin, o);
    o[0] += random_float(-120.0, 120.0);
    o[1] += random_float(-120.0, 120.0);

    FxRing(o, 255, 60, 0, 220);
    FxLight(o, 255, 60, 0, 30, 15, 5);

    new params[4];
    params[0] = _:o[0];
    params[1] = _:o[1];
    params[2] = _:o[2];
    params[3] = 0;
    set_task(1.5, "task_MeteorHit", TASK_METEOR + (g_iFrame % 40), params, 4);
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
        if (get_distance_f(o, po) > 220.0)
            continue;

        ShakeOne(id);
        FadeOne(id, 255, 140, 0, 100, 0.8);
        if (bossMeteor)
            ExecuteHamB(Ham_TakeDamage, id, 0, (g_iBoss && is_user_connected(g_iBoss)) ? g_iBoss : 0, 35.0, DMG_BLAST);
        else
            ExecuteHamB(Ham_TakeDamage, id, 0, 0, g_bZombie[id] ? 150.0 : 25.0, DMG_BLAST);
    }
}

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
    g_fFlareEnd[best] = get_gametime() + 25.0;
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

        formatex(l2, charsmax(l2), "%L", id, "HUD_P2", g_iXP[id], need, xpPct);
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
                if (cd > 0.0)
                    formatex(l4, charsmax(l4), "%L", id, "HUD_CLASS_CD", cn, floatround(cd, floatround_ceil));
                else
                    formatex(l4, charsmax(l4), "%L", id, "HUD_CLASS_READY", cn);
            }
            else if (g_bNemesis[id] || g_bAssassin[id] || g_bBoss[id])
            {
                new Float:cd = g_fCool[id] - get_gametime();
                if (cd > 0.0)
                    formatex(l4, charsmax(l4), "%L", id, "HUD_LEAP_CD", floatround(cd, floatround_ceil));
                else
                    formatex(l4, charsmax(l4), "%L", id, "HUD_LEAP_READY");
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

        new pos = g_iHudPos[id];
        new bool:zm = (is_user_alive(id) && g_bZombie[id]) ? true : false;

        if (zm)
            set_hudmessage(255, 70, 70, HUDPOS_X[pos], HUDPOS_Y[pos], 0, 0.0, 1.1, 0.0, 0.0, 1);
        else
            set_hudmessage(THEME_A[t][0], THEME_A[t][1], THEME_A[t][2], HUDPOS_X[pos], HUDPOS_Y[pos], 0, 0.0, 1.1, 0.0, 0.0, 1);
        show_hudmessage(id, "%s", head);

        if (zm)
            set_hudmessage(255, 150, 130, HUDPOS_X[pos], HUDPOS_Y[pos], 0, 0.0, 1.1, 0.0, 0.0, 2);
        else
            set_hudmessage(THEME_C[t][0], THEME_C[t][1], THEME_C[t][2], HUDPOS_X[pos], HUDPOS_Y[pos], 0, 0.0, 1.1, 0.0, 0.0, 2);
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

    new name[32], role[32], key[16];
    get_user_name(target, name, charsmax(name));
    new hp = floatround(Float:get_entvar(target, var_health));

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
    else if (g_bZombie[target])
        set_hudmessage(255, 70, 70, -1.0, Y_AIM, 0, 0.0, 0.9, 0.0, 0.1, 3);
    else
        set_hudmessage(80, 210, 255, -1.0, Y_AIM, 0, 0.0, 0.9, 0.0, 0.1, 3);

    show_hudmessage(id, "%L", id, "HUD_AIM", name, role, hp, rg_get_user_armor(target), g_iLevel[target]);
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
        ApplyWorldEvent();
        task_Announce();
    }

    // Yeterli oyuncu yoksa normal infection'a dus
    if (n < MODE_MINPL[g_iMode])
        g_iMode = MODE_INFECTION;

    g_bRoundActive = true;

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
        HudTo(id, SL_PERS, 255, 60, 60, 3.5, "YOU_FIRST_ZOMBIE_HUD");
    }

    new key[20];
    formatex(key, charsmax(key), "MODE_START_%d", g_iMode);
    HudAll(SL_ALERT, 255, 70, 70, 3.0, key);
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
    HudAll(SL_ALERT, 255, 40, 40, 3.5, key);
    PlayKey(0, "BOSS_SPAWN");
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
    HudAll(SL_ALERT, 0, 170, 255, 3.5, key);
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

    HudAll(SL_ALERT, 255, 110, 30, 3.0, "MODE_START_6");
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

    HudAll(SL_ALERT, 200, 80, 255, 3.5, "MODE_START_7");
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

    HudAll(SL_ALERT, 255, 40, 40, 4.0, "MODE_START_8");
    PlayKey(0, "BOSS_SPAWN");
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
    HudTo(id, SL_PERS, 255, 200, 40, 3.5, pkey);
}

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

    g_bZombie[id] = 1;
    g_bAlpha[id] = false;
    g_iMines[id] = 0;
    g_fInfectTime[id] = get_gametime();
    g_fCool[id] = 0.0;
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
        grav = 0.5;
        copy(model, charsmax(model), g_szNemModel);
    }
    else if (g_bAssassin[id])
    {
        hp = float(get_pcvar_num(g_pAsnHP) + 300 * CountPlaying());
        grav = 0.45;
        copy(model, charsmax(model), g_szAsnModel);
    }
    else if (g_bMinion[id])
    {
        hp = 400.0;
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

    if (g_iPrim[id] >= 0 && g_iSec[id] >= 0)
        GiveLoadout(id);
    else
        ShowPrimaryMenu(id);

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
    else if ((flags & ADMIN_LEVEL_H) && g_szVipModel[0])
        rg_set_user_model(id, g_szVipModel);
    else if (g_szHumanModel[0])
        rg_set_user_model(id, g_szHumanModel);
    else
        rg_reset_user_model(id);
}

// Yercekimini kaydet: baska bir plugin (or. parasut) bozarsa yere inince geri yuklenir
SetGravity(id, Float:grav)
{
    g_fGrav[id] = grav;
    set_entvar(id, var_gravity, grav);
}

// Her saniye: yerdeki oyuncunun yercekimi bozulduysa duzelt
FixGravity(id)
{
    if (g_fGrav[id] <= 0.0 || !(get_entvar(id, var_flags) & FL_ONGROUND))
        return;

    new Float:cur = Float:get_entvar(id, var_gravity);
    if (floatabs(cur - g_fGrav[id]) > 0.01)
        set_entvar(id, var_gravity, g_fGrav[id]);
}

ApplyHumanGravity(id)
{
    if (g_bZombie[id])
        return;

    new Float:gr = 1.0;
    if (g_iJob[id] == JOB_PARA)
        gr = 0.75;
    if (g_bBoots[id])
        gr = floatmin(gr, 0.55);
    if (g_iEvent == EV_LOWGRAV)
        gr *= 0.5;
    SetGravity(id, gr);
}

ApplyRender(id)
{
    if (!is_user_alive(id))
        return;

    if (g_fFrozen[id] > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 0, 120, 255, kRenderNormal, 25);
    else if (g_fMadness[id] > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 40);
    else if (g_fCloak[id] > get_gametime())
        set_user_rendering(id, kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 20);
    else if (g_fShield[id] > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 40, 120, 255, kRenderNormal, 28);
    else if (g_bBoss[id] && g_fEclipseEnd > get_gametime())
        set_user_rendering(id, kRenderFxGlowShell, 40, 0, 30, kRenderTransAlpha, 70);
    else if (g_bBoss[id])
    {
        if (g_bEnraged)
            set_user_rendering(id, kRenderFxGlowShell, 255, 20, 20, kRenderNormal, 40);
        else
            set_user_rendering(id, kRenderFxGlowShell, BOSS_RGB[g_iBossType][0], BOSS_RGB[g_iBossType][1], BOSS_RGB[g_iBossType][2], kRenderNormal, 32);
    }
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

    Reward(attacker, 10, get_pcvar_num(g_pInfectAP));
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
            client_print_color(p, victim, "%s %L", CHAT_PREFIX, p, "INFECTED_BY", vname, aname);
    }

    CheckWin();
}

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
/*  ZOMBI YETENEKLERI ([R])                                            */
/* ================================================================== */

public fw_CmdStart(id, uc_handle, seed)
{
    if (!g_bRoundActive || !is_user_alive(id) || !g_bZombie[id] || g_bMinion[id])
        return FMRES_IGNORED;

    if (!(get_uc(uc_handle, UC_Buttons) & IN_RELOAD))
        return FMRES_IGNORED;
    if (get_entvar(id, var_oldbuttons) & IN_RELOAD)
        return FMRES_IGNORED;
    if (g_fFrozen[id] > get_gametime())
        return FMRES_IGNORED;

    if (g_bNemesis[id] || g_bAssassin[id] || g_bBoss[id])
        SpecialLeap(id);
    else
        UseAbility(id);

    return FMRES_IGNORED;
}

SpecialLeap(id)
{
    new Float:now = get_gametime();
    if (now < g_fCool[id] || !(get_entvar(id, var_flags) & FL_ONGROUND))
        return;

    LeapForward(id, g_bAssassin[id] ? 850.0 : 650.0, 320.0);
    g_fCool[id] = now + (g_bAssassin[id] ? 4.0 : 6.0);

    new Float:o[3];
    get_entvar(id, var_origin, o);
    FxRing(o, 255, 0, 0, 200);
    EmitKey(id, "ABILITY_LEAP");
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
}

UseAbility(id)
{
    new Float:now = get_gametime();

    if (now < g_fCool[id])
    {
        set_hudmessage(255, 90, 90, -1.0, 0.56, 0, 0.0, 1.0, 0.0, 0.0, 4);
        show_hudmessage(id, "%L", id, "ABILITY_COOL", floatround(g_fCool[id] - now, floatround_ceil));
        return;
    }

    new cls = g_iClass[id];
    new Float:o[3], Float:po[3];
    get_entvar(id, var_origin, o);

    switch (cls)
    {
        case 0: // Walker: hiz patlamasi
        {
            g_fBurst[id] = now + 4.0;
            rg_reset_maxspeed(id);
            FxRing(o, 255, 160, 0, 220);
            EmitKey(id, "ABILITY_BURST");
        }
        case 1: // Runner: uzun ziplama
        {
            if (!(get_entvar(id, var_flags) & FL_ONGROUND))
                return;
            LeapForward(id, 700.0, 320.0);
            FxRing(o, 255, 140, 0, 200);
            EmitKey(id, "ABILITY_LEAP");
        }
        case 2: // Tank: hasar kalkani
        {
            g_fShield[id] = now + 4.0;
            ApplyRender(id);
            FxRing(o, 40, 120, 255, 260);
            EmitKey(id, "ABILITY_SHIELD");
        }
        case 3: // Banshee: kor eden ciglik
        {
            FxRing(o, 220, 220, 255, 450);
            EmitKey(id, "ABILITY_SCREAM");
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
            EmitKey(id, "ABILITY_DRAIN");
        }
        case 5: // Stalker: gorunmezlik
        {
            g_fCloak[id] = now + 6.0;
            ApplyRender(id);
            FxRing(o, 0, 120, 120, 200);
            EmitKey(id, "ABILITY_CLOAK");
        }
        case 6: // Bomber: zehir patlamasi
        {
            FxRing(o, 120, 255, 0, 280);
            FxSprite(o, g_sprSmoke, 25, 200);
            EmitKey(id, "ABILITY_TOXIC");
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
            EmitKey(id, "ABILITY_FROST");
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
                return;

            FxTeleport(o);
            engfunc(EngFunc_SetOrigin, id, best);
            FxTeleport(best);
            FxRing(best, 120, 120, 255, 200);
            EmitZombieSound(id, "ABILITY", "ZOMBIE_BLINK");
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

    g_bEmitting = true;
    emit_sound(id, CHAN_VOICE, path, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    g_bEmitting = false;
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
            g_fMadness[id] = get_gametime() + 2.0;
            ApplyRender(id);
        }
        return;
    }

    g_bZombie[id] = 0; g_bNemesis[id] = 0; g_bAssassin[id] = 0; g_bSurvivor[id] = 0; g_bSniper[id] = 0;
    g_bBoss[id] = 0; g_bMinion[id] = 0; g_bFirst[id] = 0;
    g_bGunsGiven[id] = false;
    g_bNadesGiven[id] = false;

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
    if (IsElite(id)) armor += 100;
    else if (IsVip(id)) armor += 50;
    if (armor > 0)
        rg_set_user_armor(id, min(armor, 250), ARMOR_VESTHELM);

    // VIP: aura + hosgeldin ipucu
    if (IsVip(id))
        ApplyRender(id);

    SyncMoney(id);

    // Bedava lazer mayini (boss roundunda yok)
    if (LasersAllowed())
        g_iMines[id] = max(g_iMines[id], get_pcvar_num(g_pLmFree));

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

    // Madness / respawn korumasi
    if (g_bZombie[victim] && g_fMadness[victim] > now)
    {
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

            if (g_bBoss[attacker])
            {
                dmg = get_pcvar_float(g_pBossDmg);
                if (g_bEnraged)
                    dmg *= 1.25;
                if (g_bFinalBoss)
                    dmg *= 1.15;
            }
            else if (g_bNemesis[attacker])
                dmg = get_pcvar_float(g_pNemDmg) * ((g_bSurvivor[victim] || g_bSniper[victim]) ? 0.5 : 1.0);
            else if (g_bAssassin[attacker])
                dmg = get_pcvar_float(g_pAsnDmg);
            else if (g_bMinion[attacker])
                dmg = get_pcvar_float(g_pMinionDmg);
            else if (g_bSurvivor[victim] || g_bSniper[victim])
                dmg = 30.0;
            else if (AllowsInfection())
            {
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
                    rg_set_user_armor(victim, max(0, armor - floatround(dmg)), atype);
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
                dmg = get_pcvar_float(g_pZombieDmg);

            if (g_bRage[attacker])
                dmg *= 1.2;
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

            if (g_bSniper[attacker] && wid == WEAPON_AWP && bulletHit)
                dmg = 5000.0;
            if (g_bSurvivor[attacker])
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
                m *= 1.3;

            new sw = SpecialIndex(attacker, wid);
            if (sw >= 0 && inflictor == attacker)
                m *= SW_MULT[sw];

            dmg *= m;

            if (g_bBoss[victim] || g_bNemesis[victim] || g_bAssassin[victim])
                dmg = floatmin(dmg, 3000.0);
        }
    }

    // Savunma
    if (g_bZombie[victim])
    {
        if (g_fShield[victim] > now)
            dmg *= 0.4;
        if (g_bZArmor[victim])
            dmg *= 0.8;
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

    // Knockback
    if (bullet && get_pcvar_num(g_pKnockback))
        ApplyKnockback(victim, attacker, wid, damage);

    // Can calma (Vampire meslegi / Vampir Gecesi eventi / Vex Reaper)
    new sw = SpecialIndex(attacker, wid);
    new Float:steal = 0.0;
    if (g_iJob[attacker] == JOB_VAMPIRE)
        steal += 0.05;
    if (g_iEvent == EV_VAMPIRE)
        steal += 0.05;
    if (sw == 6)
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
    switch (sw)
    {
        case 1, 5: if (random_num(1, 100) <= 20) Ignite(victim, attacker, 3);
        case 2: ChainLightning(victim, attacker);
        case 3: if (random_num(1, 100) <= 25) Freeze(victim, 1.5);
    }
}

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

    new w = _:wid;
    if (w < 0 || w > 30 || KB_POWER[w] <= 0.0)
        return;

    new Float:power = KB_POWER[w];
    if (g_bNemesis[victim] || g_bAssassin[victim])
        power *= 0.25;
    else if (!g_bMinion[victim])
        power *= CLASS_KB[g_iClass[victim]];

    if (g_iJob[attacker] == JOB_TACTICIAN)
        power *= 1.3;

    if (SpecialIndex(attacker, wid) == 7)
        power *= 2.0;

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
}

Ignite(victim, attacker, ticks)
{
    if (!g_bZombie[victim] || g_bBoss[victim])
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

public rg_PlayerKilled(victim, attacker, gib)
{
    new bool:valid = (1 <= attacker <= g_iMax && attacker != victim && is_user_connected(attacker)) ? true : false;
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
            PlayKey(0, "BOSS_DEATH");
        }

        if (valid && !g_bZombie[attacker])
        {
            g_iBossK[attacker]++;
            g_iVC[attacker] += g_bBoss[victim] ? 3 : 2;
            Reward(attacker, g_bBoss[victim] ? 120 : 80, g_bBoss[victim] ? 25 : 15);
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
            Reward(attacker, g_bAlpha[victim] ? 20 : 8, get_pcvar_num(g_pKillAP) + (g_bAlpha[victim] ? 4 : 0));
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

/* ---------------- Oldurme serisi / headshot / multi-kill ---------------- */

KillStreak(attacker, victim)
{
    if (is_user_bot(attacker))
        return;

    new Float:now = get_gametime();
    new bool:hs = (get_member(victim, m_LastHitGroup) == HIT_HEAD) ? true : false;

    g_iStreak[attacker]++;

    if (now - g_fLastKill[attacker] <= 4.0)
        g_iMulti[attacker]++;
    else
        g_iMulti[attacker] = 1;
    g_fLastKill[attacker] = now;

    new ktxt[96];
    if (hs)
    {
        g_iHS[attacker]++;
        g_iRoundHS[attacker]++;
        QuestEvent(attacker, 2, 1);
        AddAP(attacker, g_iEvent == EV_HEADHUNTER ? 3 : 1, true, false);
        formatex(ktxt, charsmax(ktxt), "%L", attacker, "HUD_HEADSHOT");
        if (!(g_iSet[attacker] & SET_NO_STREAK))
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

        if (!(g_iSet[attacker] & SET_NO_STREAK))
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

    if (ktxt[0])
        HudText(attacker, SL_KILL, 255, 170, 30, 1.2, ktxt);

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
            client_print_color(p, attacker, "%s %L", CHAT_PREFIX, p, key, name, s);
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
    }
    else if (g_bNemesis[id])
        spd = 260.0;
    else if (g_bAssassin[id])
        spd = 340.0;
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
    }
    else
    {
        new Float:m = get_pcvar_float(g_pHSpeed);
        if (g_iEvent == EV_SPEED)       m *= get_pcvar_float(g_pSpeedHuman);
        if (g_fBlizzardEnd > now)       m *= 0.6;
        if (g_iEvent == EV_ADRENALINE)  m *= 1.08;
        if (g_bSerum[id])               m *= 1.12;
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

public rg_FallDamage(id)
{
    if (g_bZombie[id] || g_iJob[id] == JOB_PARA || g_bBoots[id])
    {
        SetHookChainReturn(ATYPE_FLOAT, 0.0);
        return HC_SUPERCEDE;
    }
    return HC_CONTINUE;
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

/* ---------------- Zombi sesleri (bicak / aci / olum) ---------------- */

public fw_EmitSound(ent, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
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

    // Bossun kendi sesleri
    new key[24], path[128];
    if (g_bBoss[ent] && equal(ev, "PAIN"))
        return FMRES_IGNORED;

    formatex(key, charsmax(key), "Z%d_%s", g_iClass[ent], ev);
    if ((!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
        && (!TrieGetString(g_tRes, fallback, path, charsmax(path)) || !path[0]))
        return FMRES_IGNORED;

    if (containi(path, ".mp3") != -1 || equal(path, sample))
        return FMRES_IGNORED;

    g_bEmitting = true;
    emit_sound(ent, channel, path, volume, attn, flags, pitch);
    g_bEmitting = false;
    return FMRES_SUPERCEDE;
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

/* ---------------- VIP cift / uclu ziplama ---------------- */

public fw_PreThink(id)
{
    if (!is_user_alive(id))
        return FMRES_IGNORED;

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
        FxExplosion(o);
        FxRing(o, 255, 80, 0, 300);
        FxLava(o);
        FxLight(o, 255, 80, 0, 40, 15, 20);
        PlayKey(0, "NADE_FIRE");

        for (new p = 1; p <= g_iMax; p++)
        {
            if (!is_user_alive(p) || !g_bZombie[p])
                continue;
            get_entvar(p, var_origin, po);
            if (get_distance_f(o, po) > 260.0)
                continue;
            Ignite(p, owner, 6);
            if (is_user_connected(owner))
                ExecuteHamB(Ham_TakeDamage, p, ent, owner, 80.0, DMG_BURN | DMG_GRENADE);
        }
    }
    else
    {
        FxRing(o, 0, 255, 0, 300);
        FxLight(o, 0, 255, 0, 40, 15, 20);
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
                if (get_distance_f(o, po) > 240.0)
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
    FxDisk(o, 0, 120, 255, 260, 5);
    FxStreak(o, 7, 60, 300);
    FxLight(o, 0, 150, 255, 40, 15, 20);
    PlayKey(0, "NADE_FROST");

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || !g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > 260.0)
            continue;
        Freeze(p, 3.0);
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

stock MenuInfo(menu, item)
{
    new data[8], name[8], access, cb;
    menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), cb);
    return str_to_num(data);
}

stock MenuAdd(menu, const text[], value)
{
    new info[8];
    num_to_str(value, info, charsmax(info));
    menu_additem(menu, text, info);
}

stock MenuFinish(id, menu)
{
    new t[32];
    formatex(t, charsmax(t), "\y%L", id, "MENU_BACK");  menu_setprop(menu, MPROP_BACKNAME, t);
    formatex(t, charsmax(t), "\y%L", id, "MENU_NEXT");  menu_setprop(menu, MPROP_NEXTNAME, t);
    formatex(t, charsmax(t), "\r%L", id, "MENU_EXIT");  menu_setprop(menu, MPROP_EXITNAME, t);
    menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
    menu_display(id, menu, 0);
}

/* ---------------- Ana menu ---------------- */

// Ana menu sirasi (anahtar MAIN_<no>): market, ozel silah, lazer, bomba modu, silah, sinif...
new const MAIN_ORDER[] = { 1, 2, 18, 19, 3, 4, 5, 6, 20, 8, 21, 9, 7, 10, 22, 11, 12, 13, 14, 15, 16, 17 };

ShowMainMenu(id)
{
    new title[192], item[96], key[12];

    formatex(title, charsmax(title), "\r[\wV E X M I R A\r] \d|| \y%L^n\d%L^n", id, "MENU_MAIN_SUB", id, "MENU_WALLET", g_iAP[id], g_iVC[id], g_iLevel[id]);
    new menu = menu_create(title, "menu_main_handler");

    new bool:adm = (get_user_flags(id) & ADMIN_BAN) ? true : false;
    for (new k = 0; k < sizeof MAIN_ORDER; k++)
    {
        new i = MAIN_ORDER[k];
        if (i == 17 && !adm)
            continue;

        formatex(key, charsmax(key), "MAIN_%d", i);
        formatex(item, charsmax(item), "\y%L", id, key);

        if (i == 6 && g_iDailyDay[id] < get_systime() / 86400)
            add(item, charsmax(item), " \y(!)");
        if (i == 8)
            add(item, charsmax(item), IsVip(id) ? " \y[*]" : " \r[?]");
        if (i == 18)
        {
            new extra[32];
            formatex(extra, charsmax(extra), LasersAllowed() ? " \r[\w%d\r]" : " \d[-]", g_iMines[id]);
            add(item, charsmax(item), extra);
        }
        if (i == 20 && g_iQuest[id] >= 0 && g_bQuestDone[id])
            add(item, charsmax(item), " \r[\wOK\r]");

        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_main_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

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
        case 17: ShowAdminMenu(id);
        case 18: ShowMineMenu(id);
        case 19: ShowNadeMenu(id);
        case 20: cmd_quest(id);
        case 21: ShowCosmeticMenu(id);
        case 22: ShowTop10(id);
    }
    return PLUGIN_HANDLED;
}

/* ---------------- Profil alt menusu ---------------- */

ShowProfileMenu(id)
{
    new title[96], item[64];
    formatex(title, charsmax(title), "%s \y%L^n", MENU_TAG, id, "MENU_PROFILE");
    new menu = menu_create(title, "menu_profile_handler");

    formatex(item, charsmax(item), "\y%L", id, "PROF_1"); MenuAdd(menu, item, 1);
    formatex(item, charsmax(item), "\y%L", id, "PROF_2"); MenuAdd(menu, item, 2);
    formatex(item, charsmax(item), "\y%L", id, "PROF_3"); MenuAdd(menu, item, 3);
    formatex(item, charsmax(item), "\y%L", id, "PROF_4"); MenuAdd(menu, item, 4);

    MenuFinish(id, menu);
}

public menu_profile_handler(id, menu, item)
{
    if (item == MENU_EXIT)
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

        if (ITEM_LIMIT[i] && g_iBought[id][i] >= ITEM_LIMIT[i])
            formatex(item, charsmax(item), "\d%s \r[\w%L\r]", n1, id, "SHOP_SOLDOUT");
        else if (g_iAP[id] >= cost)
            formatex(item, charsmax(item), "\y%s \r[\w%d AP\r] \d%s", n1, cost, n2);
        else
            formatex(item, charsmax(item), "\d%s \r[\d%d AP\r] \d%s", n1, cost, n2);

        MenuAdd(menu, item, i);
    }

    if (!isZ)
    {
        formatex(item, charsmax(item), "\r%L", id, "SHOP_EXCHANGE");
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
    if (item == MENU_EXIT)
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
    if (g_iAP[id] < 60)
    {
        Chat(id, "SHOP_NOAP");
        return;
    }
    AddAP(id, -60, false, false);
    g_iVC[id] += 1;
    PlayKey(id, "SHOP_BUY");
    Chat(id, "SHOP_EXCHANGED");
}

// Ayni bombadan zaten varsa ustune ekle (oyun ikinciyi atmasin)
GiveNadeStack(id, const ent[], WeaponIdType:wid)
{
    new cur = rg_get_user_bpammo(id, wid);
    if (cur <= 0)
        rg_give_item(id, ent);
    else
        rg_set_user_bpammo(id, wid, cur + 1);
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

    if (ITEM_LIMIT[i] && g_iBought[id][i] >= ITEM_LIMIT[i])
    {
        Chat(id, "SHOP_LIMIT");
        return;
    }

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
            new mx = MaxHumanHP(id) + 100;
            if (Float:get_entvar(id, var_health) >= float(mx))
            {
                Chat(id, "SHOP_ALREADY");
                return;
            }
            HealTo(id, 100, mx);
        }
        case IT_ARMOR:    rg_set_user_armor(id, 200, ARMOR_VESTHELM);
        case IT_FIRENADE:
        {
            g_iFireNades[id]++;
            GiveNadeStack(id, "weapon_hegrenade", WEAPON_HEGRENADE);
        }
        case IT_FROSTNADE:
        {
            g_iFrostNades[id]++;
            GiveNadeStack(id, "weapon_smokegrenade", WEAPON_SMOKEGRENADE);
        }
        case IT_FLARE:
        {
            g_iFlares[id]++;
            GiveNadeStack(id, "weapon_flashbang", WEAPON_FLASHBANG);
        }
        case IT_DJUMP:
        {
            // Ekstra ziplama sadece VIP'lere ozel
            if (!IsVip(id)) { Chat(id, "VIP_ONLY"); return; }
            g_iExtraJumps[id]++;
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
            g_fMadness[id] = now + 5.0;
            ApplyRender(id);
            EmitKey(id, "MADNESS");
        }
        case IT_INFBOMB:
        {
            if (!AllowsInfection() || g_iGlobalInfBombs >= 3)
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
            g_iMaxHP[id] += 1000;
            set_entvar(id, var_health, Float:get_entvar(id, var_health) + 1000.0);
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
            g_fHBoost[id] = now + 6.0;
            rg_reset_maxspeed(id);
            FadeOne(id, 255, 255, 0, 60, 0.6);
        }
        case IT_HCLOAK:
        {
            g_fCloak[id] = now + 8.0;
            ApplyRender(id);
        }
        case IT_NVG:
        {
            if (get_member(id, m_bHasNightVision)) { Chat(id, "SHOP_ALREADY"); return; }
            set_member(id, m_bHasNightVision, true);
        }
        case IT_ESHIELD:
        {
            g_iEShield[id] = 2;
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
            g_fBurst[id] = now + 6.0;
            rg_reset_maxspeed(id);
        }
        case IT_ZCLOAK:
        {
            g_fCloak[id] = now + 6.0;
            ApplyRender(id);
        }
        case IT_ZJUMP:   SetGravity(id, Float:get_entvar(id, var_gravity) * 0.6);
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
    if (item == MENU_EXIT)
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
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new cls = MenuInfo(menu, item);
    menu_destroy(menu);

    if (g_iLevel[id] < CLASS_LVL[cls])
    {
        Chat(id, "NEED_LEVEL", CLASS_LVL[cls]);
        ShowClassMenu(id);
        return PLUGIN_HANDLED;
    }

    g_iClassPicked[id] = 1;
    ChatKeyName(id, "CLASS_CHOSEN", "CLASS_", cls);

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

/* ---------------- Meslek ---------------- */

ShowJobMenu(id)
{
    new title[96], item[160], k1[12], k2[16], n1[32], n2[72];

    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MENU_JOB", id, "MENU_JOB_SUB");
    new menu = menu_create(title, "menu_job_handler");

    for (new i = 0; i < NUM_JOBS; i++)
    {
        formatex(k1, charsmax(k1), "JOB_%d", i);
        formatex(k2, charsmax(k2), "JOB_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        if (g_iLevel[id] < JOB_LVL[i])
            formatex(item, charsmax(item), "\d%s \r[\wLv.%d\r]", n1, JOB_LVL[i]);
        else if (g_iJob[id] == i)
            formatex(item, charsmax(item), "\y%s \r[\w*\r] \d%s", n1, n2);
        else
            formatex(item, charsmax(item), "\y%s \d%s", n1, n2);

        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_job_handler(id, menu, item)
{
    if (item == MENU_EXIT)
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
    if (item == MENU_EXIT)
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
    if (item == MENU_EXIT)
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

/* ---------------- Chat stili ---------------- */

ShowStyleMenu(id)
{
    new title[64], item[160], k1[12], k2[16], n1[32], n2[64];

    formatex(title, charsmax(title), "%s \y%L^n", MENU_TAG, id, "MENU_STYLE");
    new menu = menu_create(title, "menu_style_handler");

    for (new i = 0; i < NUM_STYLES; i++)
    {
        formatex(k1, charsmax(k1), "STYLE_%d", i);
        formatex(k2, charsmax(k2), "STYLE_DESC_%d", i);
        formatex(n1, charsmax(n1), "%L", id, k1);
        formatex(n2, charsmax(n2), "%L", id, k2);

        if (g_iStyle[id] == i)
            formatex(item, charsmax(item), "\y%s \r[\w*\r] \d%s", n1, n2);
        else
            formatex(item, charsmax(item), "\y%s \d%s", n1, n2);

        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_style_handler(id, menu, item)
{
    if (item == MENU_EXIT)
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
    new title[96], item[96], key[12], onoff[16], tn[24];

    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MENU_SETTINGS", id, "MENU_SETTINGS_SUB");
    new menu = menu_create(title, "menu_settings_handler");

    for (new i = 0; i < 10; i++)
    {
        formatex(key, charsmax(key), "SET_%d", i);
        formatex(onoff, charsmax(onoff), "%L", id, (g_iSet[id] & (1 << i)) ? "OFF" : "ON");
        formatex(item, charsmax(item), "\y%L \r[%s%s\r]", id, key, (g_iSet[id] & (1 << i)) ? "\d" : "\w", onoff);
        MenuAdd(menu, item, i);
    }

    formatex(key, charsmax(key), "THEME_%d", g_iTheme[id]);
    formatex(tn, charsmax(tn), "%L", id, key);
    formatex(item, charsmax(item), "\y%L \r[\w%s\r]", id, "SET_THEME", tn);
    MenuAdd(menu, item, 20);

    formatex(key, charsmax(key), "HUDPOS_%d", g_iHudPos[id]);
    formatex(tn, charsmax(tn), "%L", id, key);
    formatex(item, charsmax(item), "\y%L \r[\w%s\r]", id, "SET_HUDPOS", tn);
    MenuAdd(menu, item, 23);

    formatex(item, charsmax(item), "\y%L \r[\w%s\r]", id, "SET_LANG", g_iLang[id] == 2 ? "Turkce" : "English");
    MenuAdd(menu, item, 21);

    formatex(item, charsmax(item), "\y%L", id, "SET_FPS");
    MenuAdd(menu, item, 22);

    MenuFinish(id, menu);
}

public menu_settings_handler(id, menu, item)
{
    if (item == MENU_EXIT)
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
    new title[64];
    formatex(title, charsmax(title), "%s \y%L^n", MENU_TAG, id, "MENU_LANG");
    new menu = menu_create(title, "menu_lang_handler");

    MenuAdd(menu, g_iLang[id] == 1 ? "\yEnglish \r[\w*\r]" : "\yEnglish", 1);
    MenuAdd(menu, g_iLang[id] == 2 ? "\yTurkce \r[\w*\r]" : "\yTurkce", 2);

    MenuFinish(id, menu);
}

public menu_lang_handler(id, menu, item)
{
    if (item == MENU_EXIT)
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
    new title[192], item[96];
    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MENU_FPS", id, "MENU_FPS_SUB");
    new menu = menu_create(title, "menu_fps_handler");

    formatex(item, charsmax(item), "\y%L", id, "FPS_1"); MenuAdd(menu, item, 1);
    formatex(item, charsmax(item), "\y%L", id, "FPS_2"); MenuAdd(menu, item, 2);
    formatex(item, charsmax(item), "\y%L", id, "FPS_3"); MenuAdd(menu, item, 3);
    formatex(item, charsmax(item), "\y%L", id, "FPS_4"); MenuAdd(menu, item, 4);
    formatex(item, charsmax(item), "\y%L", id, "FPS_5"); MenuAdd(menu, item, 5);

    MenuFinish(id, menu);
}

public menu_fps_handler(id, menu, item)
{
    if (item == MENU_EXIT)
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
    if (item == MENU_EXIT)
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
    if (item == MENU_EXIT)
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

    // Bombalar her hayatta bir kez
    if (g_bNadesGiven[id])
    {
        engclient_cmd(id, PRIM_ENT[p]);
        return;
    }
    g_bNadesGiven[id] = true;

    // Herkese baslangic bombalari (vex_give_nades: a = ates, b = buz, c = isaret fisegi)
    new gn[8];
    get_pcvar_string(g_pGiveNades, gn, charsmax(gn));
    if (containi(gn, "a") != -1)
    {
        g_iFireNades[id] = max(1, g_iFireNades[id]);
        rg_give_item(id, "weapon_hegrenade");
    }
    if (containi(gn, "b") != -1)
    {
        g_iFrostNades[id] = max(1, g_iFrostNades[id]);
        rg_give_item(id, "weapon_smokegrenade");
    }
    if (containi(gn, "c") != -1)
    {
        g_iFlares[id] = max(1, g_iFlares[id]);
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

    engclient_cmd(id, PRIM_ENT[p]);
}

/* ================================================================== */
/*  DUNYA EVENT'LERI (isik / sis)                                      */
/* ================================================================== */

ApplyWorldEvent()
{
    switch (g_iEvent)
    {
        case EV_BLOODMOON, EV_VAMPIRE: copy(g_szLight, charsmax(g_szLight), "c");
        case EV_NIGHT:                 copy(g_szLight, charsmax(g_szLight), "b");
        case EV_FOG:                   copy(g_szLight, charsmax(g_szLight), "g");
        case EV_BLACKOUT:              copy(g_szLight, charsmax(g_szLight), "a");
        case EV_STORM:                 copy(g_szLight, charsmax(g_szLight), "f");
        default:                       copy(g_szLight, charsmax(g_szLight), "m");
    }

    if (g_iMode == MODE_BOSS || g_iMode == MODE_NEMESIS || g_iMode == MODE_ARMAGEDDON)
        copy(g_szLight, charsmax(g_szLight), "d");

    engfunc(EngFunc_LightStyle, 0, g_szLight);

    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id))
            SendFogForEvent(id);
    }
}

SendFogForEvent(id)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    if (g_iSet[id] & SET_NO_FOG)
    {
        SendFog(id, 0, 0, 0, false);
        return;
    }

    if (g_iMode == MODE_BOSS || g_iMode == MODE_NEMESIS)
        SendFog(id, 60, 0, 0, true);
    else if (g_iEvent == EV_BLOODMOON || g_iEvent == EV_VAMPIRE)
        SendFog(id, 90, 0, 10, true);
    else if (g_iEvent == EV_FOG)
        SendFog(id, 150, 150, 150, true);
    else if (g_iEvent == EV_GOLDRUSH)
        SendFog(id, 120, 100, 20, true);
    else if (g_iEvent == EV_STORM)
        SendFog(id, 90, 100, 120, true);
    else if (g_iEvent == EV_BLACKOUT)
        SendFog(id, 0, 0, 0, true);
    else if (g_iEvent == EV_SPEED)
        SendFog(id, 0, 60, 90, true);
    else
        SendFog(id, 0, 0, 0, false);
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

// Efekt mesajlari "dusuk efekt" ayarini acmis oyunculara gonderilmez
stock FxBegin(const Float:o[3], p)
{
    engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, o, p);
}

stock bool:FxWants(p, const Float:o[3])
{
    if (!is_user_connected(p) || is_user_bot(p) || (g_iSet[p] & SET_NO_FX))
        return false;

    new Float:po[3];
    get_entvar(p, var_origin, po);
    return (get_distance_f(o, po) < 2500.0) ? true : false;
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

// Oyuncunun basinin ustunde parlayan isaret (boss, nemesis...)
stock FxHeadMark(ent, spr, life)
{
    if (!spr)
        return;

    new Float:o[3];
    get_entvar(ent, var_origin, o);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, o) || p == ent) continue;
        message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, p);
        write_byte(TE_PLAYERATTACHMENT);
        write_byte(ent);
        write_coord(45);
        write_short(spr);
        write_short(life);
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

stock Chat(id, const key[], any:...)
{
    if (!is_user_connected(id) || is_user_bot(id))
        return;

    new fmt[191], msg[191];
    Translate(fmt, charsmax(fmt), key, id);
    vformat(msg, charsmax(msg), fmt, 3);
    client_print_color(id, print_team_default, "%s %s", CHAT_PREFIX, msg);
}

stock ChatAll(const key[], iVal = 0)
{
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id) && !is_user_bot(id))
            client_print_color(id, print_team_default, "%s %L", CHAT_PREFIX, id, key, iVal);
    }
}

stock ChatAllS(const key[], const sVal[])
{
    for (new id = 1; id <= g_iMax; id++)
    {
        if (is_user_connected(id) && !is_user_bot(id))
            client_print_color(id, print_team_default, "%s %L", CHAT_PREFIX, id, key, sVal);
    }
}

stock PlayKey(id, const key[])
{
    new path[128];
    if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
        return;

    if (containi(path, ".mp3") != -1)
        client_cmd(id, "mp3 play ^"%s^"", path);
    else
        client_cmd(id, "spk ^"%s^"", path);
}

stock EmitKey(ent, const key[])
{
    new path[128];
    if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
        return;
    if (containi(path, ".mp3") != -1)
        return;

    emit_sound(ent, CHAN_VOICE, path, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
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

// Varliktan noktaya isin (zincir simsek)
stock FxBeamEntPoint(ent, const Float:b[3], spr, r, g, bl, width, noise, life = 3)
{
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!FxWants(p, b))
            continue;
        FxBegin(b, p);
        write_byte(TE_BEAMENTPOINT);
        write_short(ent);
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
    set_entvar(beam, var_model, "sprites/laserbeam.spr");
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
        client_print_color(p, id, "%s %L", CHAT_PREFIX, p, "VIP_JOIN", tn, name);

        new txt[128];
        formatex(txt, charsmax(txt), "%L", p, "VIP_JOIN_HUD", tn, name);
        HudText(p, SL_ALERT, 255, 200, 40, 3.0, txt);
    }
    PlayKey(0, "VIP_JOIN");

    // VIP'in kendisine ozel karsilama
    new tn2[16];
    formatex(tn2, charsmax(tn2), "%L", id, tier);
    Chat(id, "VIP_WELCOME_SELF", tn2, name);
    HudToS(id, SL_PERS, 255, 200, 40, 4.0, "VIP_WELCOME_HUD", tn2);

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
    if (item == MENU_EXIT || !IsVip(id))
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
        client_print_color(p, id, "%s %L", CHAT_PREFIX, p, "FUN_BALL_Q", name, question);
        client_print_color(p, id, "%s %L", CHAT_PREFIX, p, key);
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
            client_print_color(p, print_team_default, "%s %L", CHAT_PREFIX, p, key);
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
    new title[96], item[96], key[12];
    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, "MENU_FUN", id, "MENU_FUN_SUB");
    new menu = menu_create(title, "menu_fun_handler");

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
    if (item == MENU_EXIT)
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

    for (new i = 1; i <= 9; i++)
    {
        new key[12];
        formatex(key, charsmax(key), "ADMM_%d", i);
        formatex(item, charsmax(item), "\y%L", id, key);
        MenuAdd(menu, item, i);
    }

    MenuFinish(id, menu);
}

public menu_admin_handler(id, menu, item)
{
    if (item == MENU_EXIT || !(get_user_flags(id) & ADMIN_BAN))
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    switch (sel)
    {
        case 1: ShowAdminModeMenu(id, false);
        case 2: ShowAdminModeMenu(id, true);
        case 3: ShowAdminEventMenu(id);
        case 4: ShowAdminPlayers(id);
        case 5: StartVote(id, 1);
        case 6: StartVote(id, 2);
        case 7:
        {
            AdminNotify(id, "ADM_RESTART", 0);
            rg_round_end(2.0, WINSTATUS_DRAW, ROUND_END_DRAW, "", "", false);
        }
        case 8:
        {
            for (new p = 1; p <= g_iMax; p++)
            {
                if (is_user_connected(p) && !is_user_bot(p))
                    AddAP(p, 50, false, true);
            }
            new name[32];
            get_user_name(id, name, charsmax(name));
            FunAll(id, "ADM_GIFT_ALL", name, 50);
            PlayKey(0, "DAILY");
        }
        case 9:
        {
            g_bRespawnOff = !g_bRespawnOff;
            AdminNotify(id, g_bRespawnOff ? "ADM_RESPAWN_OFF" : "ADM_RESPAWN_ON", 0);
        }
    }
    return PLUGIN_HANDLED;
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
    if (item == MENU_EXIT) { menu_destroy(menu); return PLUGIN_HANDLED; }
    g_iForceMode = MenuInfo(menu, item);
    menu_destroy(menu);
    AdminNotify(id, "ADM_NEXT_MODE", g_iForceMode);
    if (g_iForceMode == MODE_BOSS)
        ShowAdminBossMenu(id, false);
    return PLUGIN_HANDLED;
}

public menu_admmode_now(id, menu, item)
{
    if (item == MENU_EXIT) { menu_destroy(menu); return PLUGIN_HANDLED; }
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
    for (new b = 0; b < NUM_BOSSES; b++)
    {
        formatex(key, charsmax(key), "BOSS_NAME_%d", b);
        formatex(item, charsmax(item), "\y%L", id, key);
        MenuAdd(menu, item, b);
    }
    MenuFinish(id, menu);
}

public menu_admboss_next(id, menu, item)
{
    if (item == MENU_EXIT) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new b = MenuInfo(menu, item);
    menu_destroy(menu);
    g_iForceBoss = (b == 99) ? -1 : b;
    return PLUGIN_HANDLED;
}

public menu_admboss_now(id, menu, item)
{
    if (item == MENU_EXIT) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new b = MenuInfo(menu, item);
    menu_destroy(menu);
    g_iForceBoss = (b == 99) ? -1 : b;
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
    g_iForceBoss = b;
    g_iForceMode = MODE_BOSS;
    AdminNotify(id, "ADM_NEXT_MODE", MODE_BOSS);
    return PLUGIN_HANDLED;
}

ShowAdminEventMenu(id)
{
    new title[192], item[96], key[16];
    formatex(title, charsmax(title), "%s \r%L^n", MENU_TAG, id, "ADMM_3");
    new menu = menu_create(title, "menu_admevent");

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
    if (item == MENU_EXIT) { menu_destroy(menu); return PLUGIN_HANDLED; }
    g_iForceEvent = MenuInfo(menu, item);
    menu_destroy(menu);
    AdminNotify(id, "ADM_NEXT_EVENT", g_iForceEvent);
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
    if (item == MENU_EXIT) { menu_destroy(menu); return PLUGIN_HANDLED; }
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

    for (new i = 1; i <= 12; i++)
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
    if (item == MENU_EXIT) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new sel = MenuInfo(menu, item);
    menu_destroy(menu);

    new target = find_player_ex(FindPlayer_MatchUserId, g_iAdmTarget[id]);
    if (!target || !is_user_connected(target) || !(get_user_flags(id) & ADMIN_BAN))
    {
        Chat(id, "ADM_GONE");
        return PLUGIN_HANDLED;
    }

    // VC / XP / VIP verme RCON (owner) yetkisi ister
    if ((sel == 2 || sel == 3 || sel >= 10) && !(get_user_flags(id) & ADMIN_RCON))
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
    }

    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && (get_user_flags(p) & ADMIN_BAN))
        {
            new act[48];
            formatex(act, charsmax(act), "%L", p, key);
            client_print_color(p, id, "%s %L", CHAT_PREFIX, p, "ADM_ACTION", aname, tname, act);
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
    if (g_iVoteType)
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
    PlayKey(0, "EVENT_START");

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
    new title[192], item[96], key[16], nm[40];
    formatex(title, charsmax(title), "%s \y%L^n\d%L^n", MENU_TAG, id, g_iVoteType == 1 ? "VOTE_TITLE_MODE" : "VOTE_TITLE_EVENT", id, "VOTE_LEFT", g_iVoteLeft);
    new menu = menu_create(title, "menu_vote_handler");

    for (new i = 0; i < VOTE_OPTS; i++)
    {
        formatex(key, charsmax(key), g_iVoteType == 1 ? "MODE_NAME_%d" : "EV_NAME_%d", g_iVoteOpt[i]);
        formatex(nm, charsmax(nm), "%L", id, key);

        if (g_iVoted[id] == i)
            formatex(item, charsmax(item), "\w%s \r[ \w%d %L\r ] \y<", nm, g_iVoteCount[i], id, "VOTE_VOTES");
        else
            formatex(item, charsmax(item), "%s%s \r[ \w%d %L\r ]", g_iVoted[id] >= 0 ? "\d" : "\y", nm, g_iVoteCount[i], id, "VOTE_VOTES");
        MenuAdd(menu, item, i);
    }

    new note[96];
    formatex(note, charsmax(note), "^n\d%L", id, "VOTE_TIE");
    menu_addtext(menu, note, 0);
    menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
    menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
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
    g_iVoteCount[opt]++;

    new name[32], key[16];
    get_user_name(id, name, charsmax(name));
    formatex(key, charsmax(key), g_iVoteType == 1 ? "MODE_NAME_%d" : "EV_NAME_%d", g_iVoteOpt[opt]);

    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_connected(p) || is_user_bot(p))
            continue;
        new nm[40];
        formatex(nm, charsmax(nm), "%L", p, key);
        client_print_color(p, id, "%s %L", CHAT_PREFIX, p, "VOTE_CAST", name, nm);
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
        client_print_color(p, print_team_default, "%s %L", CHAT_PREFIX, p, "VOTE_RESULT", nm, bestc);

        HudToS(p, SL_ALERT, 255, 200, 40, 3.5, "VOTE_RESULT_HUD", nm);
        if (VoteMenuOpen(p))
            show_menu(p, 0, "^n", 1);
    }
    PlayKey(0, "MVP");

    g_iVoteType = 0;
    remove_task(TASK_VOTE);
}

// Otomatik oylama: her N roundda bir, roundun ortasinda
TickAutoVote()
{
    new every = get_pcvar_num(g_pVoteEvery);
    if (every <= 0 || g_iVoteType || g_iForceMode >= 0 || g_iRound % every != 0)
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

StartBoss(players[32], n)
{
    new boss = players[random(n)];
    new humans = max(1, n - 1);

    g_iBoss = boss;
    g_iBossTick = 0;
    g_iBossPhase = 1;
    g_bEnraged = false;
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
    rg_set_user_footsteps(boss, false);
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
    HudAll(SL_ALERT, 255, 60, 60, 3.0, key);
    PlayBossSound("SPAWN");
    PlayKey(0, "BOSS_INTRO");

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
    EmitBossSound("ROAR");
    ShakeAll(10, 1.5, 5);
}

// Boss'a ozel ses: B<tip>_<olay> anahtari, yoksa genel BOSS_<olay> (herkese)
PlayBossSound(const ev[])
{
    new key[24], path[128];
    formatex(key, charsmax(key), "B%d_%s", g_iBossType, ev);
    if (TrieGetString(g_tRes, key, path, charsmax(path)) && path[0])
    {
        PlayKey(0, key);
        return;
    }
    formatex(key, charsmax(key), "BOSS_%s", ev);
    PlayKey(0, key);
}

// Bossun uzerinden (konumlu) ses
EmitBossSound(const ev[])
{
    if (!g_iBoss || !is_user_connected(g_iBoss))
        return;

    new key[24], path[128];
    formatex(key, charsmax(key), "B%d_%s", g_iBossType, ev);
    if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
    {
        formatex(key, charsmax(key), "BOSS_%s", ev);
        if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
            return;
    }
    if (containi(path, ".mp3") != -1)
        return;

    g_bEmitting = true;
    emit_sound(g_iBoss, CHAN_STATIC, path, VOL_NORM, ATTN_NONE, 0, PITCH_NORM);
    g_bEmitting = false;
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
    new phase = (pct > 60) ? 1 : (pct > 30) ? 2 : 3;

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
        FxHeadMark(boss, g_sprHeadMark, 21);

        new Float:feet[3];
        feet = o;
        feet[2] -= 30.0;
        FxRingEx(feet, r, g, b, 160, 10, 4, 160);
        EmitKey(boss, "BOSS_STEP");
    }

    // Ara sira kukreme
    if (g_iFrame % 13 == 0)
        EmitBossSound("ROAR");

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

    // Yetenek zamanlayicisi
    new interval = (g_iBossPhase == 1) ? 9 : (g_iBossPhase == 2) ? 7 : 5;
    if (g_fBossIntro <= now && ++g_iBossTick >= interval && !task_exists(TASK_BOSSCAST))
    {
        g_iBossTick = 0;

        new ability = 0;
        if (g_iBossPhase >= 2 && random_num(0, 1))
            ability = 1;
        BossTelegraph(ability);
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
                EmitBossSound("SCREAM");
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
        HudAll(SL_ALERT, 255, 40, 40, 3.0, "BOSS_ENRAGE");
        FadeAll(255, 0, 0, 120, 1.5);
        ShakeAll(15, 2.5, 7);
        PlayKey(0, "BOSS_ENRAGE");
        EmitBossSound("SCREAM");
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
        EmitBossSound("ROAR");
        FadeAll(r / 2, g / 2, b / 2, 70, 1.0);
        ShakeAll(10, 1.5, 5);
    }
}

// Ust kisimda buyuk, renkli boss can gostergesi
BossHud(hp, pct)
{
    new key[16], nm[32], spaced[64], ph[32];
    new hr, hg, hb;
    HpColor(pct, hr, hg, hb);
    formatex(key, charsmax(key), "BOSS_NAME_%d", g_iBossType);

    new bool:nameLine = (g_iFrame % 2 == 0) ? true : false;

    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_bot(id))
            continue;

        // Isim + faz satiri: 2 sn'de bir (bossun kendi renginde)
        if (nameLine)
        {
            formatex(nm, charsmax(nm), "%L", id, key);
            SpaceOut(nm, spaced, charsmax(spaced));
            formatex(ph, charsmax(ph), "%L", id, g_bEnraged ? "BOSS_PH_RAGE" : (g_iBossPhase == 2 ? "BOSS_PH_2" : "BOSS_PH_1"));

            if (g_bEnraged)
                set_dhudmessage(255, 40, 40, -1.0, Y_BOSS, 0, 0.0, 2.0, 0.0, 0.0);
            else
                set_dhudmessage(BOSS_RGB[g_iBossType][0], BOSS_RGB[g_iBossType][1], BOSS_RGB[g_iBossType][2], -1.0, Y_BOSS, 0, 0.0, 2.0, 0.0, 0.0);

            if (g_bFinalBoss)
                show_dhudmessage(id, "%L  <<  %s  >>  %s", id, "FINAL_BOSS_TAG", spaced, ph);
            else
                show_dhudmessage(id, "<<  %s  >>   %s", spaced, ph);
        }

        // Can satiri: her saniye, can durumuna gore renk
        set_dhudmessage(hr, hg, hb, -1.0, Y_BOSS, 0, 0.0, 1.0, 0.0, 0.0);
        show_dhudmessage(id, "^n%L", id, "BOSS_HPLINE", hp, g_iBossMaxHP, pct);
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
    HudAll(SL_ALERT, 255, 90, 30, 1.5, key);

    new radius = BossAbilityRadius(ability);
    if (radius > 0)
    {
        new Float:feet[3];
        feet = o;
        feet[2] -= 30.0;
        FxDisk(feet, r, g, b, radius, 15);
        FxRingEx(feet, 255, 30, 30, radius, 8, 15);
    }
    FxRing(o, 255, 0, 0, 150);
    FxImplosion(o, 200, 40, 10);
    PlayKey(0, "BOSS_WARN");
    EmitBossSound("ROAR");

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

        o[2] -= 30.0;
        FxDisk(o, 255, 240, 80, 170, 12);
        FxRingEx(o, 255, 255, 255, 170, 6, 12);

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

        o[2] -= 30.0;
        new slot = i;
        for (new s = 0; s < sizeof g_fPoolEnd; s++)
        {
            if (g_fPoolEnd[s] < now)
            {
                slot = s;
                break;
            }
        }
        g_fPoolPos[slot] = o;
        g_fPoolEnd[slot] = now + 8.0;

        FxDisk(o, 110, 255, 0, 150, 10);
        FxSprite(o, g_sprSmoke, 20, 180);
    }
    PlayKey(0, "ACID_POOL");
}

// Havuzlar: her saniye cizilir, icindeki insan hasar alir (zombi iyilesir)
TickPools()
{
    new Float:now = get_gametime(), Float:po[3];
    for (new s = 0; s < sizeof g_fPoolEnd; s++)
    {
        if (g_fPoolEnd[s] < now)
            continue;

        FxDisk(g_fPoolPos[s], 110, 255, 0, 150, 10);
        FxRingEx(g_fPoolPos[s], 160, 255, 60, 150, 6, 10, 150);
        if (g_iFrame % 2 == 0)
            FxSprite(g_fPoolPos[s], g_sprSmoke, 12, 140);

        for (new id = 1; id <= g_iMax; id++)
        {
            if (!is_user_alive(id))
                continue;
            get_entvar(id, var_origin, po);
            if (get_distance_f(g_fPoolPos[s], po) > 160.0)
                continue;
            if (g_bZombie[id])
                HealTo(id, 60, g_iMaxHP[id]);
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
    EmitBossSound("ROAR");
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
    PlayBossSound("SCREAM");

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

        FxRing(o, 255, 60, 0, 200);
        FxDisk(o, 255, 80, 0, 200, 12);
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
    HudAll(SL_ANN, 80, 255, 140, 4.0, "BOSS_DOWN_HUD");
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

    static const PRIZE[3] = { 40, 25, 15 };
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
                client_print_color(p, ids[r], "%s %L", CHAT_PREFIX, p, "BOSS_BOARD_LINE", r + 1, name, dmg[r], PRIZE[r]);
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
        HudText(p, SL_ALERT, 255, 200, 40, 4.5, txt);
    }
}

// Bilgi: /boss
public cmd_bossinfo(id)
{
    new key[20];
    Chat(id, "BOSSINFO_TITLE");
    for (new b = 0; b < NUM_BOSSES; b++)
    {
        formatex(key, charsmax(key), "BOSS_INFO_%d", b);
        Chat(id, key);
    }
    new left = RoundsToBoss();
    if (left > 0)
        Chat(id, "BOSS_NEXT_IN", left);
    return PLUGIN_HANDLED;
}

// Bilgi: /round - harita plani
public cmd_roundplan(id)
{
    new list[128];
    get_pcvar_string(g_pBossRounds, list, charsmax(list));
    Chat(id, "PLAN_1", g_iRound, RoundsTotal());
    client_print_color(id, print_team_default, "%s %L", CHAT_PREFIX, id, "PLAN_2", list);
    get_pcvar_string(g_pSpecialRounds, list, charsmax(list));
    client_print_color(id, print_team_default, "%s %L", CHAT_PREFIX, id, "PLAN_3", list);
    Chat(id, "PLAN_4");
    return PLUGIN_HANDLED;
}

/* ================================================================== */
/*  LAZER MAYINLARI                                                    */
/*  V (+setlaser) basili tut: duvara / zemine lazer kurar (1 sn)       */
/*  C (+dellaser veya varsayilan radio3): kendi lazerini geri sokur    */
/*  - Isin zombilere hasar verir ve onlari geri iter                   */
/*  - Her temasta isin asinir; zombiler pencesiyle mayini kirabilir    */
/*  - Can azaldikca isin rengi degisir (mavi -> sari -> kirmizi)       */
/*  - Boss roundlarinda kurulamaz (vex_lm_boss 0)                      */
/* ================================================================== */

#define LM_CLASS     "vex_lasermine"
#define BEAM_MARK_LM 7776
#define BEAM_MARK_NADE 7777

new Float:g_fLmCd[33], Float:g_fPlantPos[33][3], Float:g_fLmMsg[33];

bool:LasersAllowed()
{
    if (!get_pcvar_num(g_pLmEnable))
        return false;
    if (g_iMode == MODE_BOSS && !get_pcvar_num(g_pLmBoss))
        return false;
    return true;
}

MaxMines(id)
{
    new m = IsVip(id) ? get_pcvar_num(g_pLmMaxVip) : get_pcvar_num(g_pLmMax);
    if (g_iJob[id] == JOB_ENGINEER)
        m++;
    return max(0, m);
}

MineCost(id)
{
    new c = get_pcvar_num(g_pLmCost);
    if (g_iJob[id] == JOB_ENGINEER)
        c /= 2;
    return max(0, c);
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

// C tusu (radio3): insan kendi lazerine bakiyorsa sokulur
public cmd_radio3(id)
{
    if (!get_pcvar_num(g_pLmEnable) || !is_user_alive(id) || g_bZombie[id])
        return PLUGIN_CONTINUE;
    if (!AimedMine(id, 110.0))
        return PLUGIN_CONTINUE;

    cmd_lm_take(id);
    return PLUGIN_HANDLED;
}

public cmd_lm_release(id)
{
    if (g_iPlantAction[id])
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
}

public cmd_lm_plant(id)
{
    if (!is_user_alive(id) || g_bZombie[id] || g_iPlantAction[id])
        return PLUGIN_HANDLED;

    if (!LasersAllowed())
    {
        LmMessage(id, g_iMode == MODE_BOSS ? "LM_NO_BOSS" : "LM_DISABLED");
        return PLUGIN_HANDLED;
    }
    if (!g_bRoundActive && !g_bCounting && !get_member_game(m_bFreezePeriod))
        return PLUGIN_HANDLED;

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

    // Envanterde yoksa AP ile otomatik satin al
    if (g_iMines[id] <= 0)
    {
        new cost = MineCost(id);
        if (g_iAP[id] < cost)
        {
            LmMessage(id, "LM_NO_MINE", cost);
            return PLUGIN_HANDLED;
        }
        AddAP(id, -cost, false, false);
        g_iMines[id]++;
        Chat(id, "LM_BOUGHT", cost);
    }

    new Float:pos[3], Float:normal[3];
    if (!FindPlantSpot(id, pos, normal))
    {
        LmMessage(id, "LM_NO_WALL");
        return PLUGIN_HANDLED;
    }

    get_entvar(id, var_origin, g_fPlantPos[id]);
    g_iPlantAction[id] = 1;
    rg_send_bartime(id, 1, false);
    set_task(1.0, "task_PlantDone", id + TASK_PLANT);
    EmitKey(id, "LM_CHARGE");
    return PLUGIN_HANDLED;
}

public cmd_lm_take(id)
{
    if (!is_user_alive(id) || g_bZombie[id] || g_iPlantAction[id])
        return PLUGIN_HANDLED;

    new mine = AimedMine(id, 110.0);
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
    rg_send_bartime(id, 1, false);
    set_task(1.0, "task_PlantDone", id + TASK_PLANT);
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
        new mine = AimedMine(id, 120.0);
        if (!mine)
            return;
        new owner = get_entvar(mine, var_iuser1);
        if (owner != id && !(get_user_flags(id) & ADMIN_BAN))
            return;

        MineRemove(mine);
        if (owner == id)
            g_iMines[id]++;
        EmitKey(id, "LM_PICKUP");
        Chat(id, "LM_TAKEN", g_iMines[id]);
    }
}

// Nisan alinan yuzey: duvar / zemin (sadece sabit dunya)
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

    end[0] = start[0] + fwd[0] * 128.0;
    end[1] = start[1] + fwd[1] * 128.0;
    end[2] = start[2] + fwd[2] * 128.0;

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

    pos[0] += normal[0] * 8.0;
    pos[1] += normal[1] * 8.0;
    pos[2] += normal[2] * 8.0;
    return true;
}

AimedMine(id, Float:range)
{
    new target, body;
    get_user_aiming(id, target, body, floatround(range));
    if (target > g_iMax && IsMine(target))
        return target;

    // Kucuk kutu: nisan tam tutmazsa en yakin mayini bul
    new Float:eye[3], Float:ofs[3], Float:ang[3], Float:fwd[3], Float:mo[3];
    get_entvar(id, var_origin, eye);
    get_entvar(id, var_view_ofs, ofs);
    eye[0] += ofs[0];
    eye[1] += ofs[1];
    eye[2] += ofs[2];
    get_entvar(id, var_v_angle, ang);
    engfunc(EngFunc_MakeVectors, ang);
    global_get(glb_v_forward, fwd);

    new ent, best, Float:bestDot = 0.93;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", LM_CLASS)) > 0)
    {
        get_entvar(ent, var_origin, mo);
        new Float:d = get_distance_f(eye, mo);
        if (d > range || d < 1.0)
            continue;
        new Float:dot = ((mo[0] - eye[0]) * fwd[0] + (mo[1] - eye[1]) * fwd[1] + (mo[2] - eye[2]) * fwd[2]) / d;
        if (dot > bestDot)
        {
            bestDot = dot;
            best = ent;
        }
    }
    return best;
}

/* ---------------- Mayin varligi ---------------- */

CreateMine(id, const Float:pos[3], const Float:normal[3])
{
    if (!g_szMineModel[0])
        return 0;

    new ent = rg_create_entity("info_target");
    if (is_nullent(ent))
        return 0;

    set_entvar(ent, var_classname, LM_CLASS);
    engfunc(EngFunc_SetModel, ent, g_szMineModel);
    if (containi(g_szMineModel, "tripmine") != -1)
    {
        set_entvar(ent, var_body, 3);
        set_entvar(ent, var_sequence, 7);
    }
    set_entvar(ent, var_framerate, 0.0);
    set_entvar(ent, var_movetype, MOVETYPE_FLY);
    // Kurarken kati degil (oyuncu icinde kalmasin); aktif olunca kati olur ki pence ile kirilabilsin
    set_entvar(ent, var_solid, SOLID_NOT);
    engfunc(EngFunc_SetSize, ent, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0});
    engfunc(EngFunc_SetOrigin, ent, pos);

    new Float:ang[3];
    engfunc(EngFunc_VecToAngles, normal, ang);
    set_entvar(ent, var_angles, ang);

    new Float:hp = float(max(50, get_pcvar_num(g_pLmHealth)));
    set_entvar(ent, var_takedamage, DAMAGE_YES);
    set_entvar(ent, var_health, hp);
    set_entvar(ent, var_max_health, hp);
    set_entvar(ent, var_iuser1, id);
    set_entvar(ent, var_iuser2, 0);
    set_entvar(ent, var_iuser3, 0);
    set_entvar(ent, var_fuser1, get_gametime() + 2.0);
    set_entvar(ent, var_vuser1, normal);

    set_entvar(ent, var_renderfx, kRenderFxGlowShell);
    set_entvar(ent, var_rendercolor, Float:{0.0, 160.0, 255.0});
    set_entvar(ent, var_rendermode, kRenderNormal);
    set_entvar(ent, var_renderamt, 8.0);

    SetThink(ent, "fw_MineThink");
    set_entvar(ent, var_nextthink, get_gametime() + 0.1);

    EmitKey(ent, "LM_DEPLOY");
    FxRingSmall(pos, 0, 160, 255);
    return ent;
}

MineColor(ent, &r, &g, &b)
{
    new Float:hp = Float:get_entvar(ent, var_health);
    new Float:mx = floatmax(1.0, Float:get_entvar(ent, var_max_health));
    new pct = floatround(hp * 100.0 / mx);
    if (pct > 60)      { r = 0;   g = 200; b = 255; }
    else if (pct > 30) { r = 255; g = 190; b = 0; }
    else               { r = 255; g = 40;  b = 40; }
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

    // Kurulum: 2 sn sarj, sonra isin acilir
    if (get_entvar(ent, var_iuser2) == 0)
    {
        if (now >= Float:get_entvar(ent, var_fuser1))
        {
            new Float:start[3], Float:end[3];
            start[0] = o[0] + normal[0] * 2.0;
            start[1] = o[1] + normal[1] * 2.0;
            start[2] = o[2] + normal[2] * 2.0;
            end[0] = start[0] + normal[0] * 4096.0;
            end[1] = start[1] + normal[1] * 4096.0;
            end[2] = start[2] + normal[2] * 4096.0;

            engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ent, 0);
            get_tr2(0, TR_vecEndPos, end);
            set_entvar(ent, var_vuser2, end);

            new r, g, b;
            MineColor(ent, r, g, b);
            new beam = BeamCreate(start, end, r, g, b, 7, 190);
            if (beam)
                set_entvar(beam, var_iuser1, BEAM_MARK_LM);
            set_entvar(ent, var_iuser3, beam);
            set_entvar(ent, var_iuser2, 1);

            EmitKey(ent, "LM_ACTIVATE");
            FxLight(o, 0, 200, 255, 12, 8, 20);
        }
        set_entvar(ent, var_nextthink, now + 0.1);
        return;
    }

    // Kimse ustunde degilse kati yap (zombi pencesi carpabilsin)
    if (get_entvar(ent, var_solid) == SOLID_NOT && !PlayerNear(o, 30.0))
    {
        set_entvar(ent, var_solid, SOLID_BBOX);
        engfunc(EngFunc_SetOrigin, ent, o);
    }

    // Aktif: isinda zombi var mi?
    new Float:start[3], Float:end[3];
    start[0] = o[0] + normal[0] * 2.0;
    start[1] = o[1] + normal[1] * 2.0;
    start[2] = o[2] + normal[2] * 2.0;
    get_entvar(ent, var_vuser2, end);

    engfunc(EngFunc_TraceLine, start, end, DONT_IGNORE_MONSTERS, ent, 0);
    new hit = get_tr2(0, TR_pHit);
    if (1 <= hit <= g_iMax && is_user_alive(hit) && g_bZombie[hit])
    {
        new Float:hp[3];
        get_tr2(0, TR_vecEndPos, hp);
        MineHit(ent, owner, hit, hp);
        if (is_nullent(ent) || get_entvar(ent, var_flags) & FL_KILLME)
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
    g_fLmCd[zombie] = now + 0.4;

    new Float:dmg = get_pcvar_float(g_pLmDamage);
    if (g_bBoss[zombie] || g_bNemesis[zombie] || g_bAssassin[zombie])
        dmg *= 0.5;

    new r, g, b;
    MineColor(ent, r, g, b);

    FxSparks(point);
    FxLight(point, r, g, b, 14, 4, 30);
    FadeOne(zombie, r, g, b, 90, 0.35);
    EmitKey(ent, "LM_HIT");

    // Geri itme: zombiyi isindan geri savur
    new Float:vel[3];
    get_entvar(zombie, var_velocity, vel);
    vel[0] = -vel[0] * 0.9;
    vel[1] = -vel[1] * 0.9;
    vel[2] = 180.0;
    set_entvar(zombie, var_velocity, vel);

    ExecuteHamB(Ham_TakeDamage, zombie, ent, owner, dmg, DMG_ENERGYBEAM);

    // Isin her temasta asinir: zombiler kalabalik gelirse lazeri yakar
    if (!is_nullent(ent))
        MineDamage(ent, get_pcvar_float(g_pLmWear), zombie);
}

MineDamage(ent, Float:amount, attacker)
{
    new Float:hp = Float:get_entvar(ent, var_health) - amount;
    if (hp <= 0.0)
    {
        new owner = get_entvar(ent, var_iuser1);
        if (is_user_connected(owner) && attacker && is_user_connected(attacker))
        {
            new name[32];
            get_user_name(attacker, name, charsmax(name));
            Chat(owner, "LM_DESTROYED", name);
        }
        MineDestroy(ent, true);
        return;
    }
    set_entvar(ent, var_health, hp);

    new beam = get_entvar(ent, var_iuser3);
    if (beam > 0 && !is_nullent(beam))
    {
        new r, g, b;
        MineColor(ent, r, g, b);
        BeamColor(beam, r, g, b, 190);
        new Float:c[3];
        c[0] = float(r);
        c[1] = float(g);
        c[2] = float(b);
        set_entvar(ent, var_rendercolor, c);
    }
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
    set_entvar(ent, var_takedamage, DAMAGE_NO);
    set_entvar(ent, var_solid, SOLID_NOT);
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
        if (mark == BEAM_MARK_LM || mark == BEAM_MARK_NADE)
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
    show_hudmessage(id, "%L", id, "LM_AIM_INFO", name, floatround(Float:get_entvar(target, var_health)), floatround(Float:get_entvar(target, var_max_health)));
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
        set_hudmessage(0, 200, 255, -1.0, Y_AIM + 0.08, 0, 0.0, 5.0, 0.2, 0.5, 3);
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
    formatex(item, charsmax(item), ok ? "\y%L \r[\w%d AP\r]" : "\d%L \r[\w%d AP\r]", id, "LM_M_BUY", MineCost(id)); MenuAdd(menu, item, 3);
    formatex(item, charsmax(item), "\y%L", id, "LM_M_BIND"); MenuAdd(menu, item, 4);

    if (!ok)
    {
        formatex(item, charsmax(item), "\d%L", id, g_iMode == MODE_BOSS ? "LM_NO_BOSS_SHORT" : "LM_DISABLED_SHORT");
        menu_addtext(menu, item, 0);
    }
    MenuFinish(id, menu);
}

public menu_mine_handler(id, menu, item)
{
    if (item == MENU_EXIT)
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
            if (!LasersAllowed() || !is_user_alive(id) || g_bZombie[id])
                Chat(id, "LM_DISABLED");
            else if (g_iMines[id] >= 5)
                Chat(id, "LM_INV_FULL");
            else if (g_iAP[id] < MineCost(id))
                Chat(id, "SHOP_NOAP");
            else
            {
                AddAP(id, -MineCost(id), false, false);
                g_iMines[id]++;
                PlayKey(id, "SHOP_BUY");
                Chat(id, "LM_BOUGHT", MineCost(id));
            }
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

    set_hudmessage(255, 170, 40, -1.0, 0.62, 0, 0.0, 2.0, 0.0, 0.3, 4);
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
    set_entvar(ent, var_fuser4, now);

    // Lazer yonu: atis yonu (yatay)
    new Float:ang[3], Float:fwd[3];
    get_entvar(id, var_v_angle, ang);
    ang[0] = 0.0;
    engfunc(EngFunc_MakeVectors, ang);
    global_get(glb_v_forward, fwd);
    set_entvar(ent, var_vuser4, fwd);

    switch (mode)
    {
        case NM_SENSOR, NM_LASER:
            set_entvar(ent, var_dmgtime, now + 60.0);
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

// Patlama: hemen (duman bombasi yere oturmus olmali)
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
    if (mode != NM_IMPACT && mode != NM_HOMING)
        return HAM_IGNORED;
    if (other == get_entvar(ent, var_owner))
        return HAM_IGNORED;
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
        return true;

    // Havada tepe noktasinda da hiz dusuk olur: altinda zemin olmali
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

NadePlant(ent, Float:now)
{
    set_entvar(ent, var_velocity, Float:{0.0, 0.0, 0.0});
    set_entvar(ent, var_movetype, MOVETYPE_NONE);
    set_entvar(ent, var_flags, get_entvar(ent, var_flags) | FL_ONGROUND);
    set_entvar(ent, var_fuser4, now + 1.0);
    set_entvar(ent, var_fuser3, now + 1.0);
    set_entvar(ent, var_dmgtime, now + 35.0);
    EmitKey(ent, "NADE_ARM");
}

NadeSensor(ent, Float:now)
{
    if (!get_entvar(ent, var_iuser3))
    {
        if (!NadeLanded(ent))
            return;
        NadePlant(ent, now);
        set_entvar(ent, var_iuser3, 1);
        return;
    }
    if (now < Float:get_entvar(ent, var_fuser4))
        return;

    new Float:o[3], Float:po[3];
    get_entvar(ent, var_origin, o);

    // Bip + kirmizi halka (saniyede bir)
    if (now >= Float:get_entvar(ent, var_fuser3))
    {
        set_entvar(ent, var_fuser3, now + 1.0);
        FxRingEx(o, 255, 30, 30, get_pcvar_num(g_pNadeProx), 4, 6, 120);
        FxLight(o, 255, 0, 0, 6, 5, 10);
        EmitKey(ent, "NADE_BEEP");
    }

    new Float:radius = get_pcvar_float(g_pNadeProx);
    for (new p = 1; p <= g_iMax; p++)
    {
        if (!is_user_alive(p) || !g_bZombie[p])
            continue;
        get_entvar(p, var_origin, po);
        if (get_distance_f(o, po) > radius)
            continue;
        NadeDetonateNow(ent);
        return;
    }
}

NadeLaser(ent, Float:now)
{
    new Float:o[3], Float:start[3], Float:end[3], Float:dir[3];
    get_entvar(ent, var_origin, o);
    start = o;
    start[2] += 8.0;

    if (!get_entvar(ent, var_iuser3))
    {
        if (!NadeLanded(ent))
            return;
        NadePlant(ent, now);

        get_entvar(ent, var_vuser4, dir);
        new Float:len = get_pcvar_float(g_pNadeLaser);
        end[0] = start[0] + dir[0] * len;
        end[1] = start[1] + dir[1] * len;
        end[2] = start[2];
        engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ent, 0);
        get_tr2(0, TR_vecEndPos, end);
        set_entvar(ent, var_vuser3, end);

        new beam = BeamCreate(start, end, 255, 30, 30, 5, 200);
        if (beam)
        {
            set_entvar(beam, var_iuser1, BEAM_MARK_NADE);
            set_entvar(ent, var_iuser3, beam);
        }
        else
            set_entvar(ent, var_iuser3, -1);
        return;
    }
    if (now < Float:get_entvar(ent, var_fuser4))
        return;

    get_entvar(ent, var_vuser3, end);
    engfunc(EngFunc_TraceLine, start, end, DONT_IGNORE_MONSTERS, ent, 0);
    new hit = get_tr2(0, TR_pHit);
    if (1 <= hit <= g_iMax && is_user_alive(hit) && g_bZombie[hit])
    {
        new Float:hp[3];
        get_tr2(0, TR_vecEndPos, hp);
        FxSparks(hp);
        NadeCleanup(ent);
        NadeDetonateNow(ent);
        return;
    }

    if (now >= Float:get_entvar(ent, var_fuser3))
    {
        set_entvar(ent, var_fuser3, now + 1.5);
        FxLight(o, 255, 0, 0, 5, 5, 10);
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
    new beam = get_entvar(ent, var_iuser3);
    if (beam > 0 && !is_nullent(beam))
        set_entvar(beam, var_flags, FL_KILLME);
    set_entvar(ent, var_iuser3, -1);
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
        ExecuteHamB(Ham_TakeDamage, p, 0, owner, 45.0, DMG_GRENADE);
    }
}

// Konumdan ses (bomba / kutu gibi varligi olmayan noktalar icin)
stock EmitKeyPos(const Float:o[3], const key[])
{
    new path[128];
    if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0] || containi(path, ".mp3") != -1)
        return;
    engfunc(EngFunc_EmitAmbientSound, 0, o, path, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
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
    if (item == MENU_EXIT)
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
    set_entvar(ent, var_nextthink, get_gametime() + 0.2);

    FxTrail(ent, 255, 200, 40);
    HudAll(SL_ALERT, 255, 200, 40, 2.5, "AIRDROP_HUD");
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
        set_entvar(ent, var_flags, FL_KILLME);
        return;
    }

    new Float:o[3], Float:sky[3];
    get_entvar(ent, var_origin, o);

    // Yere indi: toz + ses
    if (!get_entvar(ent, var_iuser1) && (get_entvar(ent, var_flags) & FL_ONGROUND))
    {
        set_entvar(ent, var_iuser1, 1);
        FxRingEx(o, 255, 200, 40, 220, 12, 6);
        FxSprite(o, g_sprSmoke, 15, 150);
        EmitKey(ent, "AIRDROP_LAND");
    }

    // Isik sutunu: uzaktan gorunur
    sky = o;
    sky[2] += 520.0;
    FxBeamEx(o, sky, g_sprBeam, 255, 200, 40, 14, 0, 11, 150);
    FxLight(o, 255, 200, 40, 14, 11, 5);

    set_entvar(ent, var_nextthink, now + 1.0);
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
    SetTouch(ent, "");
    SetThink(ent, "");
    set_entvar(ent, var_flags, FL_KILLME);

    if (g_bZombie[other])
    {
        FxSprite(o, g_sprSmoke, 20, 180);
        FxRingSmall(o, 0, 255, 0);
        ChatAllS("AIRDROP_ZOMBIE", name);
        HealTo(other, 300, g_iMaxHP[other]);
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
    else if (roll <= 76 && LasersAllowed())
    {
        g_iMines[id] = min(5, g_iMines[id] + 1);
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

        client_print_color(p, id, "%s %L", CHAT_PREFIX, p, "AIRDROP_GOT", name, loot);
        if (p == id)
        {
            formatex(txt, charsmax(txt), "%L^n%s", p, "AIRDROP_YOU", loot);
            HudText(p, SL_PERS, 255, 200, 40, 3.0, txt);
        }
    }
    SaveData(id);
}

RemoveAllDrops()
{
    new ent;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", DROP_CLASS)) > 0)
    {
        SetTouch(ent, "");
        SetThink(ent, "");
        set_entvar(ent, var_flags, FL_KILLME);
    }
}

/* ---------------- Round gorevleri ----------------
   Her round herkese kucuk bir gorev: tamamlayan XP + AP kazanir. */

// tur: 0 zombi oldur, 1 hasar ver, 2 headshot, 4 enfekte et, 7 roundu insan olarak kazan
new const QUEST_TYPE[NUM_QUESTS] = { 0, 0, 1, 1, 2, 4, 4, 7 };
new const QUEST_NEED[NUM_QUESTS] = { 3, 6, 2500, 6000, 2, 1, 3, 1 };
new const QUEST_XP[NUM_QUESTS]   = { 40, 80, 40, 80, 50, 30, 80, 45 };
new const QUEST_AP[NUM_QUESTS]   = { 10, 20, 10, 20, 12, 8, 20, 12 };
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
        client_print_color(id, print_team_default, "%s %L", CHAT_PREFIX, id, "QUEST_NEW", desc, QUEST_XP[q], QUEST_AP[q]);
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
    HudTo(id, SL_PERS, 80, 255, 160, 3.0, "QUEST_DONE_HUD");

    new name[32];
    get_user_name(id, name, charsmax(name));
    for (new p = 1; p <= g_iMax; p++)
    {
        if (is_user_connected(p) && !is_user_bot(p))
            client_print_color(p, id, "%s %L", CHAT_PREFIX, p, "QUEST_DONE_ALL", name);
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
        client_print_color(id, print_team_default, "%s %L", CHAT_PREFIX, id, "QUEST_INFO_DONE", desc);
    else
        client_print_color(id, print_team_default, "%s %L", CHAT_PREFIX, id, "QUEST_INFO", desc, min(g_iQuestProg[id], QUEST_NEED[q]), QUEST_NEED[q], QUEST_XP[q], QUEST_AP[q]);
    return PLUGIN_HANDLED;
}

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
    HudTo(id, SL_PERS, 120, 255, 0, 3.0, "EVOLVE_HUD");
}

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

/* ================================================================== */
/*  KOZMETIK (Vex Coin ile kalici): iz, oldurme efekti, enfeksiyon     */
/*  efekti. TUM ZAMANLARIN SIRALAMASI (ilk 15) + stil kartlari.        */
/*  IZLEYICI BILGISI: olu oyuncu izledigi kisinin bilgisini gorur.     */
/* ================================================================== */

new const TRAIL_PRICE[NUM_TRAILS] = { 15, 15, 15, 20, 30, 50 };
new const KFX_PRICE[NUM_KFX]      = { 20, 25, 25, 30, 35, 50 };
new const IFX_PRICE[NUM_IFX]      = { 20, 30, 40 };

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
    if (item == MENU_EXIT)
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
    if (item == MENU_EXIT)
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
                client_print_color(p, id, "%s %L", CHAT_PREFIX, p, "COS_BOUGHT_ALL", name, pn);
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
        set_hudmessage(255, 90, 90, -1.0, 0.70, 0, 0.0, 1.1, 0.0, 0.0, 3);
    else
        set_hudmessage(90, 210, 255, -1.0, 0.70, 0, 0.0, 1.1, 0.0, 0.0, 3);
    show_hudmessage(id, "%L", id, "SPEC_INFO", name, g_iLevel[target], role, floatround(Float:get_entvar(target, var_health)), rg_get_user_armor(target), g_iAP[target]);
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
            client_print_color(p, id, "%s %L", CHAT_PREFIX, p, "TOP_JOIN", r, name);
    }
}
