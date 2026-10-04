/* ================================================================== */
/*  Vexmira Zombie - modul: vex/core.inc  (CORE)                      */
/*  Sabitler, enum'lar, veri tablolari, tum global degiskenler,       */
/*  kucuk ortak yardimcilar (menu, chat etiketi).                     */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
/* ================================================================== */

/* ------------------------------------------------------------------ */
/*  Sabitler                                                           */
/* ------------------------------------------------------------------ */

#define MAX_LEVEL     60
#define NUM_CLASSES   24
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
#define NUM_ADS       26
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
#define TASK_HOSTNAME 9500
#define HOSTNAME_MAX  63
#define TASK_CFGLOAD  9600
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
    "FROST_NOVA", "THUNDER", "ACID_POOL", "GRAVITY_WELL", "ECLIPSE",
    // v2.0
    "ZONE_WARN", "SKILL_UNLOCK", "NEM_RAGE", "ASN_VEIL", "LM_KILL", "NADE_TRIGGER", "UI_OPEN", "LM_DENY"
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
new ITEM_COST[NUM_ITEMS]  = { 12, 10, 12, 12, 5, 15, 10, 12, 25, 30, 40, 30, 20, 35, 15, 12, 10, 18, 15, 25, 8, 30, 10, 15, 20, 12, 25, 18 };
new const ITEM_TEAM[NUM_ITEMS]  = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1 };
new ITEM_LIMIT[NUM_ITEMS] = { 3, 2, 2, 2, 3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 3, 1, 2, 1, 1, 1, 2, 2, 1, 1, 1, 1 };
// v2.0: esya level kilidi ve ana deger (can / zirh / sure / yuzde ...) - vexmira.cfg: vex_item
new ITEM_LVL[NUM_ITEMS]   = { 1, 1, 1, 1, 1, 2, 1, 1, 3, 4, 2, 1, 1, 3, 1, 2, 1, 3, 2, 3, 1, 4, 1, 1, 2, 1, 3, 2 };
new ITEM_VAL[NUM_ITEMS]   = { 100, 200, 1, 1, 1, 1, 55, 12, 0, 30, 0, 0, 5, 3, 1000, 20, 0, 20, 6, 8, 0, 2, 0, 6, 6, 60, 60, 0 };
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
new Float:SW_MULT[NUM_SPECIAL] = { 1.8, 1.5, 3.0, 1.6, 2.2, 1.6, 1.9, 2.4 };
new SW_COST[NUM_SPECIAL]       = { 40, 60, 70, 45, 30, 50, 55, 80 };
new SW_LVL[NUM_SPECIAL]        = { 3, 8, 12, 5, 4, 10, 15, 20 };
new SW_BPAMMO[NUM_SPECIAL]     = { 180, 300, 60, 64, 70, 200, 180, 180 };
new const SW_RGB[NUM_SPECIAL][3]     =
{
    {0, 220, 255}, {255, 110, 0}, {200, 220, 255}, {120, 220, 255},
    {255, 210, 0}, {255, 60, 0}, {170, 0, 255}, {90, 0, 160}
};

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
new g_pStartAP, g_pArmorProtect, g_pVipContact;
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
new g_pNemOneShot, g_pAsnOneShot, g_pNemVsSurv, g_pNemSpeed, g_pAsnSpeed, g_pNemGrav, g_pAsnGrav, g_pMinionHP;
new g_pNemRageTime, g_pNemRageCd, g_pAsnVeilTime, g_pAsnVeilCd, g_pSpecialLeapCd;
new g_pLmPerRound, g_pLmPerRoundVip, g_pLmOneShot, g_pLmSpecialDmg, g_pLmKillWear, g_pLmPlantTime, g_pLmTakeTime;
new g_pLmArmTime, g_pLmBeamWidth, g_pLmColorMode, g_pLmColor, g_pLmRange, g_pLmTakeRange, g_pAirdropLaser;
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
new g_iAmbPitch[MAX_AMB], bool:g_bAmbOn[MAX_AMB], g_iAmbN, g_iAmbRestored, bool:g_bAmbReplay;

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
// v3.0 hizalama: gostergeler MOVETYPE_FOLLOW kullanmaz (istemci FOLLOW sprite'ini govde merkezine
// cizer, v_angle ofsetini yok sayar). Konum her pakette AddToFullPack'te oyuncunun o anki
// konumu + modelin kafa ustu yuksekligi + yigin ofseti olarak yazilir.
#define OVH_MAXENT 4096
new g_iOvhOwn[OVH_MAXENT], Float:g_fOvhDz[OVH_MAXENT];       // varlik -> sahibi / kafa ustunden yukseklik
new Float:g_fOvhStand[33], Float:g_fOvhDuck[33], Float:g_fOvhStackTop[33], g_szOvhMdl[33][32];
new bool:g_bOvhSelf, Trie:g_tMdlTop;
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
