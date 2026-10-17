/* VEXMIRA 5.3.1-Stable | vexgear
Derived from Vexmira 4.4.0-Full. Core: SmurfSexy & Capital.
ReAPI SDK: s1lent / rehlds contributors (original API declarations embedded).
CSO item authors preserved in component AUTHOR constants; see existing package KAYNAKLAR.md.
Both vexmira_core and vexmira_gear are required. AMXX 1.10 / ReAPI >=5.24. */
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <xs>
#include <nvault>
#include <geoip>
#pragma dynamic 32768
new g_iIsolation526;
new bool:g_bRun526;
#pragma tabsize 0
new g_iPcM51,g_iPcS51,g_iPcG51;
new Trie:g_tTrackedWeaponSounds = Invalid_Trie;
new g_szTrackedWeaponSound[33][8][96];
new bool:g_bStoppingTrackedSound[33];
new g_iTrackedWeaponId[33];
#if AMXX_VERSION_NUM >= 175
#pragma reqlib reapi
#if !defined AMXMODX_NOAUTOLOAD
#pragma loadlib reapi
#endif
#else
#pragma library reapi
#endif
enum hooks_tables_e
{
ht_engine,
ht_gamedll,
ht_animating,
ht_player,
ht_gamerules,
ht_rechecker,
ht_grenade,
ht_weaponbox,
ht_weapon,
ht_gib,
ht_cbaseentity,
ht_botmanager
};
enum members_tables_e
{
mt_gamerules,
mt_base,
mt_animating,
mt_basemonster,
mt_player,
mt_entvars,
mt_playermove,
mt_movevars,
mt_usercmd,
mt_pmtrace,
mt_csplayer,
mt_baseitem,
mt_baseweapon,
mt_weaponbox,
mt_armoury,
mt_grenade,
mt_p228,
mt_scout,
mt_hegrenade,
mt_xm1014,
mt_c4,
mt_mac10,
mt_aug,
mt_smokegrenade,
mt_elite,
mt_fiveseven,
mt_ump45,
mt_sg550,
mt_galil,
mt_famas,
mt_usp,
mt_glock18,
mt_awp,
mt_mp5n,
mt_m249,
mt_m3,
mt_m4a1,
mt_tmp,
mt_g3sg1,
mt_deagle,
mt_sg552,
mt_ak47,
mt_knife,
mt_p90,
mt_shield,
mt_rebuystruct,
mt_mapinfo,
mt_csplayerweapon,
mt_gib,
mt_netadr,
mt_csentity
};
#define ReAPIFunc 				{EngineFunc, GamedllFunc, GamedllFunc_CBaseAnimating, GamedllFunc_CBasePlayer, GamedllFunc_CSGameRules, GamedllFunc_CGrenade, GamedllFunc_CWeaponBox, ReCheckerFunc, GamedllFunc_CBasePlayerWeapon, GamedllFunc_CGib, GamedllFunc_CBaseEntity, GamedllFunc_CBotManager}
#define is_nullent(%0)          (%0 == 0 || is_entity(%0) == false)
#define MAX_REGION_RANGE        1024
#define BEGIN_FUNC_REGION(%0)   (any:MAX_REGION_RANGE * hooks_tables_e:ht_%0)
#define BEGIN_MEMBER_REGION(%0) (any:MAX_REGION_RANGE * members_tables_e:mt_%0)
#define BIT(%0)                         (1<<(%0))
#define NULLENT                         -1
#define MAX_WEAPONS                     32
#define MAX_CLIENTS                     32
#define MAX_ITEM_TYPES                  6
#define MAX_EDICT_BITS                  11
#define MAX_EDICTS                      (1<<MAX_EDICT_BITS)
#define IN_ATTACK                       (1<<0)
#define IN_JUMP                         (1<<1)
#define IN_DUCK                         (1<<2)
#define IN_FORWARD                      (1<<3)
#define IN_BACK                         (1<<4)
#define IN_USE                          (1<<5)
#define IN_CANCEL                       (1<<6)
#define IN_LEFT                         (1<<7)
#define IN_RIGHT                        (1<<8)
#define IN_MOVELEFT                     (1<<9)
#define IN_MOVERIGHT                    (1<<10)
#define IN_ATTACK2                      (1<<11)
#define IN_RUN                          (1<<12)
#define IN_RELOAD                       (1<<13)
#define IN_ALT1                         (1<<14)
#define IN_SCORE                        (1<<15)
#define FL_FLY                          (1<<0)
#define FL_SWIM                         (1<<1)
#define FL_CONVEYOR                     (1<<2)
#define FL_CLIENT                       (1<<3)
#define FL_INWATER                      (1<<4)
#define FL_MONSTER                      (1<<5)
#define FL_GODMODE                      (1<<6)
#define FL_NOTARGET                     (1<<7)
#define FL_SKIPLOCALHOST                (1<<8)
#define FL_ONGROUND                     (1<<9)
#define FL_PARTIALGROUND                (1<<10)
#define FL_WATERJUMP                    (1<<11)
#define FL_FROZEN                       (1<<12)
#define FL_FAKECLIENT                   (1<<13)
#define FL_DUCKING                      (1<<14)
#define FL_FLOAT                        (1<<15)
#define FL_GRAPHED                      (1<<16)
#define FL_IMMUNE_WATER                 (1<<17)
#define FL_IMMUNE_SLIME                 (1<<18)
#define FL_IMMUNE_LAVA                  (1<<19)
#define FL_PROXY                        (1<<20)
#define FL_ALWAYSTHINK                  (1<<21)
#define FL_BASEVELOCITY                 (1<<22)
#define FL_MONSTERCLIP                  (1<<23)
#define FL_ONTRAIN                      (1<<24)
#define FL_WORLDBRUSH                   (1<<25)
#define FL_SPECTATOR                    (1<<26)
#define FL_CUSTOMENTITY                 (1<<29)
#define FL_KILLME                       (1<<30)
#define FL_DORMANT                      (1<<31)
#define FTRACE_BULLET                   (1<<16)
#define FTRACE_FLASH                    (1<<17)
#define FTRACE_KNIFE                    (1<<18)
#define MOVETYPE_NONE                   0
#define MOVETYPE_WALK                   3
#define MOVETYPE_STEP                   4
#define MOVETYPE_FLY                    5
#define MOVETYPE_TOSS                   6
#define MOVETYPE_PUSH                   7
#define MOVETYPE_NOCLIP                 8
#define MOVETYPE_FLYMISSILE             9
#define MOVETYPE_BOUNCE                 10
#define MOVETYPE_BOUNCEMISSILE          11
#define MOVETYPE_FOLLOW                 12
#define MOVETYPE_PUSHSTEP               13
#define SOLID_NOT                       0
#define SOLID_TRIGGER                   1
#define SOLID_BBOX                      2
#define SOLID_SLIDEBOX                  3
#define SOLID_BSP                       4
#define DEAD_NO                         0
#define DEAD_DYING                      1
#define DEAD_DEAD                       2
#define DEAD_RESPAWNABLE                3
#define DEAD_DISCARDBODY                4
#define DAMAGE_NO                       0.0
#define DAMAGE_YES                      1.0
#define DAMAGE_AIM                      2.0
#define EF_BRIGHTFIELD                  1
#define EF_MUZZLEFLASH                  2
#define EF_BRIGHTLIGHT                  4
#define EF_DIMLIGHT                     8
#define EF_INVLIGHT                     16
#define EF_NOINTERP                     32
#define EF_LIGHT                        64
#define EF_NODRAW                       128
#define EF_FORCEVISIBILITY              2048
#define EF_OWNER_VISIBILITY             4096
#define EF_OWNER_NO_VISIBILITY          8192
#define BREAK_TYPEMASK                  0x4F
#define BREAK_GLASS                     0x01
#define BREAK_METAL                     0x02
#define BREAK_FLESH                     0x04
#define BREAK_WOOD                      0x08
#define BREAK_SMOKE                     0x10
#define BREAK_TRANS                     0x20
#define BREAK_CONCRETE                  0x40
#define BREAK_2                         0x80
#define BOUNCE_GLASS                    BREAK_GLASS
#define BOUNCE_METAL                    BREAK_METAL
#define BOUNCE_FLESH                    BREAK_FLESH
#define BOUNCE_WOOD                     BREAK_WOOD
#define BOUNCE_SHRAP                    0x10
#define BOUNCE_SHELL                    0x20
#define BOUNCE_CONCRETE                 BREAK_CONCRETE
#define BOUNCE_SHOTSHELL                0x80
#define TE_BOUNCE_NULL                  0
#define TE_BOUNCE_SHELL                 1
#define TE_BOUNCE_SHOTSHELL             2
#define OBS_NONE                        0
#define OBS_CHASE_LOCKED                1
#define OBS_CHASE_FREE                  2
#define OBS_ROAMING                     3
#define OBS_IN_EYE                      4
#define OBS_MAP_FREE                    5
#define OBS_MAP_CHASE                   6
#define PLAYER_CAN_SHOOT                (1<<0)
#define PLAYER_FREEZE_TIME_OVER         (1<<1)
#define PLAYER_IN_BOMB_ZONE             (1<<2)
#define PLAYER_HOLDING_SHIELD           (1<<3)
#define PLAYER_PREVENT_DUCK             (1<<4)
#define PLAYER_PREVENT_CLIMB            (1<<5)
#define PLAYER_PREVENT_JUMP             (1<<6)
#define DMG_GENERIC                     0
#define DMG_CRUSH                       (1<<0)
#define DMG_BULLET                      (1<<1)
#define DMG_SLASH                       (1<<2)
#define DMG_BURN                        (1<<3)
#define DMG_FREEZE                      (1<<4)
#define DMG_FALL                        (1<<5)
#define DMG_BLAST                       (1<<6)
#define DMG_CLUB                        (1<<7)
#define DMG_SHOCK                       (1<<8)
#define DMG_SONIC                       (1<<9)
#define DMG_ENERGYBEAM                  (1<<10)
#define DMG_NEVERGIB                    (1<<12)
#define DMG_ALWAYSGIB                   (1<<13)
#define DMG_DROWN                       (1<<14)
#define DMG_PARALYZE                    (1<<15)
#define DMG_NERVEGAS                    (1<<16)
#define DMG_POISON                      (1<<17)
#define DMG_RADIATION                   (1<<18)
#define DMG_DROWNRECOVER                (1<<19)
#define DMG_ACID                        (1<<20)
#define DMG_SLOWBURN                    (1<<21)
#define DMG_SLOWFREEZE                  (1<<22)
#define DMG_MORTAR                      (1<<23)
#define DMG_GRENADE                     (1<<24)
#define DMG_TIMEBASED                   (~(0x3fff))
#define DMG_GIB_CORPSE                  (DMG_CRUSH | DMG_FALL | DMG_BLAST | DMG_SONIC | DMG_CLUB)
#define DMG_SHOWNHUD                    (DMG_POISON | DMG_ACID | DMG_FREEZE | DMG_SLOWFREEZE | DMG_DROWN | DMG_BURN | DMG_SLOWBURN | DMG_NERVEGAS | DMG_RADIATION | DMG_SHOCK)
#define GIB_NORMAL                      0
#define GIB_NEVER                       1
#define GIB_ALWAYS                      2
#define PFLAG_ONLADDER                  (1<<0)
#define PFLAG_ONSWING                   (1<<0)
#define PFLAG_ONTRAIN                   (1<<1)
#define PFLAG_ONBARNACLE                (1<<2)
#define PFLAG_DUCKING                   (1<<3)
#define PFLAG_USING                     (1<<4)
#define PFLAG_OBSERVER                  (1<<5)
#define HIDEHUD_WEAPONS                 (1<<0)
#define HIDEHUD_FLASHLIGHT              (1<<1)
#define HIDEHUD_ALL                     (1<<2)
#define HIDEHUD_HEALTH                  (1<<3)
#define HIDEHUD_TIMER                   (1<<4)
#define HIDEHUD_MONEY                   (1<<5)
#define HIDEHUD_CROSSHAIR               (1<<6)
#define HIDEHUD_OBSERVER_CROSSHAIR      (1<<7)
#define ITEM_FLAG_SELECTONEMPTY         (1<<0)
#define ITEM_FLAG_NOAUTORELOAD          (1<<1)
#define ITEM_FLAG_NOAUTOSWITCHEMPTY     (1<<2)
#define ITEM_FLAG_LIMITINWORLD          (1<<3)
#define ITEM_FLAG_EXHAUSTIBLE           (1<<4)
#define ITEM_FLAG_NOFIREUNDERWATER      (1<<5)
#define SF_TRAIN_WAIT_RETRIGGER         1
#define SF_TRAIN_START_ON               4
#define SF_TRAIN_PASSABLE               8
#define SF_WALL_TOOGLE_START_OFF        0x0001
#define SF_WALL_TOOGLE_NOTSOLID         0x0008
#define SF_CONVEYOR_VISUAL              0x0001
#define SF_CONVEYOR_NOTSOLID            0x0002
#define SF_BUTTON_DONTMOVE              1
#define SF_BUTTON_TOGGLE                32
#define SF_BUTTON_SPARK_IF_OFF          64
#define SF_BUTTON_TOUCH_ONLY            256
#define SF_ROTBUTTON_NOTSOLID           1
#define SF_ROTBUTTON_BACKWARDS          2
#define SF_GLOBAL_SET                   1
#define MAX_MS_TARGETS                  32
#define SF_MULTI_INIT                   1
#define SF_MOMENTARY_DOOR               0x0001
#define SF_BTARGET_USE                  0x0001
#define SF_BTARGET_ON                   0x0002
#define SF_DOOR_START_OPEN              1
#define SF_DOOR_PASSABLE                8
#define SF_DOOR_NO_AUTO_RETURN          32
#define SF_DOOR_USE_ONLY                256
#define SF_DOOR_TOUCH_ONLY_CLIENTS      1024
#define SF_DOOR_ACTUALLY_WATER          0x80000000
#define SF_GIBSHOOTER_REPEATABLE        1
#define SF_FUNNEL_REVERSE               1
#define SF_BUBBLES_STARTOFF             0x0001
#define SF_BLOOD_RANDOM                 0x0001
#define SF_BLOOD_STREAM                 0x0002
#define SF_BLOOD_PLAYER                 0x0004
#define SF_BLOOD_DECAL                  0x0008
#define SF_SHAKE_EVERYONE               0x0001
#define SF_SHAKE_DISRUPT                0x0002
#define SF_SHAKE_INAIR                  0x0004
#define SF_FADE_IN                      0x0001
#define SF_FADE_MODULATE                0x0002
#define SF_FADE_ONLYONE                 0x0004
#define SF_BEAM_STARTON                 0x0001
#define SF_BEAM_TOGGLE                  0x0002
#define SF_BEAM_RANDOM                  0x0004
#define SF_BEAM_RING                    0x0008
#define SF_BEAM_SPARKSTART              0x0010
#define SF_BEAM_SPARKEND                0x0020
#define SF_BEAM_DECALS                  0x0040
#define SF_BEAM_SHADEIN                 0x0080
#define SF_BEAM_SHADEOUT                0x0100
#define SF_BEAM_TEMPORARY               0x8000
#define SF_SPRITE_STARTON               0x0001
#define SF_SPRITE_ONCE                  0x0002
#define SF_SPRITE_TEMPORARY             0x8000
#define SF_MESSAGE_ONCE                 0x0001
#define SF_MESSAGE_ALL                  0x0002
#define SF_ENVEXPLOSION_NODAMAGE        (1<<0)
#define SF_ENVEXPLOSION_REPEATABLE      (1<<1)
#define SF_ENVEXPLOSION_NOFIREBALL      (1<<2)
#define SF_ENVEXPLOSION_NOSMOKE         (1<<3)
#define SF_ENVEXPLOSION_NODECAL         (1<<4)
#define SF_ENVEXPLOSION_NOSPARKS        (1<<5)
#define SF_TANK_ACTIVE                  0x0001
#define SF_TANK_PLAYER                  0x0002
#define SF_TANK_HUMANS                  0x0004
#define SF_TANK_ALIENS                  0x0008
#define SF_TANK_LINEOFSIGHT             0x0010
#define SF_TANK_CANCONTROL              0x0020
#define SF_TANK_SOUNDON                 0x8000
#define SF_DETONATE                     0x0001
#define SF_SCORE_NEGATIVE               0x0001
#define SF_SCORE_TEAM                   0x0002
#define SF_ENVTEXT_ALLPLAYERS           0x0001
#define SF_TEAMMASTER_FIREONCE          0x0001
#define SF_TEAMMASTER_ANYTEAM           0x0002
#define SF_TEAMSET_FIREONCE             0x0001
#define SF_TEAMSET_CLEARTEAM            0x0002
#define SF_PKILL_FIREONCE               0x0001
#define SF_GAMECOUNT_FIREONCE           0x0001
#define SF_GAMECOUNT_RESET              0x0002
#define SF_GAMECOUNT_OVER_LIMIT         0x0004
#define MAX_EQUIP                       32
#define SF_PLAYEREQUIP_USEONLY          0x0001
#define SF_PTEAM_FIREONCE               0x0001
#define SF_PTEAM_KILL                   0x0002
#define SF_PTEAM_GIB                    0x0004
#define SF_PLAT_TOGGLE                  0x0001
#define SF_TRACK_ACTIVATETRAIN          0x00000001
#define SF_TRACK_RELINK                 0x00000002
#define SF_TRACK_ROTMOVE                0x00000004
#define SF_TRACK_STARTBOTTOM            0x00000008
#define SF_TRACK_DONT_MOVE              0x00000010
#define SF_TRACKTRAIN_NOPITCH           0x0001
#define SF_TRACKTRAIN_NOCONTROL         0x0002
#define SF_TRACKTRAIN_FORWARDONLY       0x0004
#define SF_TRACKTRAIN_PASSABLE          0x0008
#define SF_PATH_DISABLED                0x00000001
#define SF_PATH_FIREONCE                0x00000002
#define SF_PATH_ALTREVERSE              0x00000004
#define SF_PATH_DISABLE_TRAIN           0x00000008
#define SF_PATH_ALTERNATE               0x00008000
#define SF_CORNER_WAITFORTRIG           0x001
#define SF_CORNER_TELEPORT              0x002
#define SF_CORNER_FIREONCE              0x004
#define SF_TRIGGER_PUSH_ONCE            1
#define SF_TRIGGER_PUSH_START_OFF       2
#define SF_TRIGGER_HURT_TARGETONCE      1
#define SF_TRIGGER_HURT_START_OFF       2
#define SF_TRIGGER_HURT_NO_CLIENTS      8
#define SF_TRIGGER_HURT_CLIENTONLYFIRE  16
#define SF_TRIGGER_HURT_CLIENTONLYTOUCH 32
#define SF_AUTO_FIREONCE                0x0001
#define SF_AUTO_NORESET                 0x0002
#define SF_RELAY_FIREONCE               0x0001
#define SF_MULTIMAN_THREAD              0x00000001
#define SF_MULTIMAN_CLONE               0x80000000
#define SF_RENDER_MASKFX                (1<<0)
#define SF_RENDER_MASKAMT               (1<<1)
#define SF_RENDER_MASKMODE              (1<<2)
#define SF_RENDER_MASKCOLOR             (1<<3)
#define SF_CHANGELEVEL_USEONLY          0x0002
#define SF_ENDSECTION_USEONLY           0x0001
#define SF_CAMERA_PLAYER_POSITION       1
#define SF_CAMERA_PLAYER_TARGET         2
#define SF_CAMERA_PLAYER_TAKECONTROL    4
#define SF_BRUSH_ROTATE_START_ON        1
#define SF_BRUSH_ROTATE_BACKWARDS       2
#define SF_BRUSH_ROTATE_Z_AXIS          4
#define SF_BRUSH_ROTATE_X_AXIS          8
#define SF_BRUSH_ACCDCC                 16
#define SF_BRUSH_HURT                   32
#define SF_BRUSH_ROTATE_NOT_SOLID       64
#define SF_BRUSH_ROTATE_SMALLRADIUS     128
#define SF_BRUSH_ROTATE_MEDIUMRADIUS    256
#define SF_BRUSH_ROTATE_LARGERADIUS     512
#define SF_TRIGGER_ALLOWMONSTERS        1
#define SF_TRIGGER_NOCLIENTS            2
#define SF_TRIGGER_PUSHABLES            4
#define SF_TRIGGER_NORESET              64
#define SF_TRIGGER_MULTIPLE_NOTOUCH     0x0001
#define SF_TRIGGER_COUNTER_NOMESSAGE    0x0001
#define SF_BREAK_TRIGGER_ONLY           1
#define SF_BREAK_TOUCH                  2
#define SF_BREAK_PRESSURE               4
#define SF_BREAK_CROWBAR                256
#define SF_PUSH_BREAKABLE               128
#define SF_LIGHT_START_OFF              1
#define SF_DECAL_NOTINDEATHMATCH        2048
#define SF_WORLD_DARK                   0x0001
#define SF_WORLD_TITLE                  0x0002
#define SF_WORLD_FORCETEAM              0x0004
#define SF_NORESPAWN                    (1<<30)
#define TRAIN_ACTIVE                    0x80
#define TRAIN_NEW                       0xc0
#define TRAIN_OFF                       0x00
#define TRAIN_NEUTRAL                   0x01
#define TRAIN_SLOW                      0x02
#define TRAIN_MEDIUM                    0x03
#define TRAIN_FAST                      0x04
#define TRAIN_BACK                      0x05
#define FEV_NOTHOST                     (1<<0)
#define FEV_RELIABLE                    (1<<1)
#define FEV_GLOBAL                      (1<<2)
#define FEV_UPDATE                      (1<<3)
#define FEV_HOSTONLY                    (1<<4)
#define FEV_SERVER                      (1<<5)
#define FEV_CLIENT                      (1<<6)
#define FCAP_CUSTOMSAVE                 0x00000001
#define FCAP_ACROSS_TRANSITION          0x00000002
#define FCAP_MUST_SPAWN                 0x00000004
#define FCAP_IMPULSE_USE                0x00000008
#define FCAP_CONTINUOUS_USE             0x00000010
#define FCAP_ONOFF_USE                  0x00000020
#define FCAP_DIRECTIONAL_USE            0x00000040
#define FCAP_MASTER                     0x00000080
#define FCAP_MUST_RESET                 0x00000100
#define FCAP_MUST_RELEASE               0x00000200
#define FCAP_DONT_SAVE                  0x80000000
#define FCAP_FORCE_TRANSITION           0x00000080
#define DONT_BLEED                      -1
#define BLOOD_COLOR_RED                 247
#define BLOOD_COLOR_YELLOW              195
#define BLOOD_COLOR_GREEN               BLOOD_COLOR_YELLOW
enum
{
IGNOREMSG_NONE,
IGNOREMSG_ENEMY,
IGNOREMSG_TEAM
}
enum HitBoxGroup
{
HITGROUP_GENERIC = 0,
HITGROUP_HEAD,
HITGROUP_CHEST,
HITGROUP_STOMACH,
HITGROUP_LEFTARM,
HITGROUP_RIGHTARM,
HITGROUP_LEFTLEG,
HITGROUP_RIGHTLEG,
HITGROUP_SHIELD
};
enum ArmorType
{
ARMOR_NONE,
ARMOR_KEVLAR,
ARMOR_VESTHELM,
};
enum ArmouryItemPack
{
ARMOURY_MP5NAVY,
ARMOURY_TMP,
ARMOURY_P90,
ARMOURY_MAC10,
ARMOURY_AK47,
ARMOURY_SG552,
ARMOURY_M4A1,
ARMOURY_AUG,
ARMOURY_SCOUT,
ARMOURY_G3SG1,
ARMOURY_AWP,
ARMOURY_M3,
ARMOURY_XM1014,
ARMOURY_M249,
ARMOURY_FLASHBANG,
ARMOURY_HEGRENADE,
ARMOURY_KEVLAR,
ARMOURY_ASSAULT,
ARMOURY_SMOKEGRENADE,
ARMOURY_SHIELD,
ARMOURY_FAMAS,
ARMOURY_SG550,
ARMOURY_GALIL,
ARMOURY_UMP45,
ARMOURY_GLOCK18,
ARMOURY_USP,
ARMOURY_ELITE,
ARMOURY_FIVESEVEN,
ARMOURY_P228,
ARMOURY_DEAGLE,
};
enum RewardType
{
RT_NONE,
RT_ROUND_BONUS,
RT_PLAYER_RESET,
RT_PLAYER_JOIN,
RT_PLAYER_SPEC_JOIN,
RT_PLAYER_BOUGHT_SOMETHING,
RT_HOSTAGE_TOOK,
RT_HOSTAGE_RESCUED,
RT_HOSTAGE_DAMAGED,
RT_HOSTAGE_KILLED,
RT_TEAMMATES_KILLED,
RT_ENEMY_KILLED,
RT_INTO_GAME,
RT_VIP_KILLED,
RT_VIP_RESCUED_MYSELF
};
enum TeamName
{
TEAM_UNASSIGNED,
TEAM_TERRORIST,
TEAM_CT,
TEAM_SPECTATOR
};
enum ModelName
{
MODEL_UNASSIGNED,
MODEL_CT_URBAN,
MODEL_T_TERROR,
MODEL_T_LEET,
MODEL_T_ARCTIC,
MODEL_CT_GSG9,
MODEL_CT_GIGN,
MODEL_CT_SAS,
MODEL_T_GUERILLA,
MODEL_CT_VIP,
MODEL_T_MILITIA,
MODEL_CT_SPETSNAZ,
MODEL_AUTO
};
enum
{
GR_NONE = 0,
GR_WEAPON_RESPAWN_YES,
GR_WEAPON_RESPAWN_NO,
GR_AMMO_RESPAWN_YES,
GR_AMMO_RESPAWN_NO,
GR_ITEM_RESPAWN_YES,
GR_ITEM_RESPAWN_NO,
GR_PLR_DROP_GUN_ALL,
GR_PLR_DROP_GUN_ACTIVE,
GR_PLR_DROP_GUN_NO,
GR_PLR_DROP_AMMO_ALL,
GR_PLR_DROP_AMMO_ACTIVE,
GR_PLR_DROP_AMMO_NO
};
enum WeaponIdType
{
WEAPON_NONE,
WEAPON_P228,
WEAPON_GLOCK,
WEAPON_SCOUT,
WEAPON_HEGRENADE,
WEAPON_XM1014,
WEAPON_C4,
WEAPON_MAC10,
WEAPON_AUG,
WEAPON_SMOKEGRENADE,
WEAPON_ELITE,
WEAPON_FIVESEVEN,
WEAPON_UMP45,
WEAPON_SG550,
WEAPON_GALIL,
WEAPON_FAMAS,
WEAPON_USP,
WEAPON_GLOCK18,
WEAPON_AWP,
WEAPON_MP5N,
WEAPON_M249,
WEAPON_M3,
WEAPON_M4A1,
WEAPON_TMP,
WEAPON_G3SG1,
WEAPON_FLASHBANG,
WEAPON_DEAGLE,
WEAPON_SG552,
WEAPON_AK47,
WEAPON_KNIFE,
WEAPON_P90,
WEAPON_SHIELDGUN = 99
};
enum TimeBasedDamage
{
ITDB_PARALYZE,
ITDB_NERVEGAS,
ITDB_POISON,
ITDB_RADIATION,
ITDB_DROWNRECOVER,
ITDB_ACID,
ITDB_SLOWBURN,
ITDB_SLOWFREEZE
};
enum Activity
{
ACT_INVALID = -1,
ACT_RESET,
ACT_IDLE,
ACT_GUARD,
ACT_WALK,
ACT_RUN,
ACT_FLY,
ACT_SWIM,
ACT_HOP,
ACT_LEAP,
ACT_FALL,
ACT_LAND,
ACT_STRAFE_LEFT,
ACT_STRAFE_RIGHT,
ACT_ROLL_LEFT,
ACT_ROLL_RIGHT,
ACT_TURN_LEFT,
ACT_TURN_RIGHT,
ACT_CROUCH,
ACT_CROUCHIDLE,
ACT_STAND,
ACT_USE,
ACT_SIGNAL1,
ACT_SIGNAL2,
ACT_SIGNAL3,
ACT_TWITCH,
ACT_COWER,
ACT_SMALL_FLINCH,
ACT_BIG_FLINCH,
ACT_RANGE_ATTACK1,
ACT_RANGE_ATTACK2,
ACT_MELEE_ATTACK1,
ACT_MELEE_ATTACK2,
ACT_RELOAD,
ACT_ARM,
ACT_DISARM,
ACT_EAT,
ACT_DIESIMPLE,
ACT_DIEBACKWARD,
ACT_DIEFORWARD,
ACT_DIEVIOLENT,
ACT_BARNACLE_HIT,
ACT_BARNACLE_PULL,
ACT_BARNACLE_CHOMP,
ACT_BARNACLE_CHEW,
ACT_SLEEP,
ACT_INSPECT_FLOOR,
ACT_INSPECT_WALL,
ACT_IDLE_ANGRY,
ACT_WALK_HURT,
ACT_RUN_HURT,
ACT_HOVER,
ACT_GLIDE,
ACT_FLY_LEFT,
ACT_FLY_RIGHT,
ACT_DETECT_SCENT,
ACT_SNIFF,
ACT_BITE,
ACT_THREAT_DISPLAY,
ACT_FEAR_DISPLAY,
ACT_EXCITED,
ACT_SPECIAL_ATTACK1,
ACT_SPECIAL_ATTACK2,
ACT_COMBAT_IDLE,
ACT_WALK_SCARED,
ACT_RUN_SCARED,
ACT_VICTORY_DANCE,
ACT_DIE_HEADSHOT,
ACT_DIE_CHESTSHOT,
ACT_DIE_GUTSHOT,
ACT_DIE_BACKSHOT,
ACT_FLINCH_HEAD,
ACT_FLINCH_CHEST,
ACT_FLINCH_STOMACH,
ACT_FLINCH_LEFTARM,
ACT_FLINCH_RIGHTARM,
ACT_FLINCH_LEFTLEG,
ACT_FLINCH_RIGHTLEG,
ACT_FLINCH,
ACT_LARGE_FLINCH,
ACT_HOLDBOMB,
ACT_IDLE_FIDGET,
ACT_IDLE_SCARED,
ACT_IDLE_SCARED_FIDGET,
ACT_FOLLOW_IDLE,
ACT_FOLLOW_IDLE_FIDGET,
ACT_FOLLOW_IDLE_SCARED,
ACT_FOLLOW_IDLE_SCARED_FIDGET,
ACT_CROUCH_IDLE,
ACT_CROUCH_IDLE_FIDGET,
ACT_CROUCH_IDLE_SCARED,
ACT_CROUCH_IDLE_SCARED_FIDGET,
ACT_CROUCH_WALK,
ACT_CROUCH_WALK_SCARED,
ACT_CROUCH_DIE,
ACT_WALK_BACK,
ACT_IDLE_SNEAKY,
ACT_IDLE_SNEAKY_FIDGET,
ACT_WALK_SNEAKY,
ACT_WAVE,
ACT_YES,
ACT_NO
};
enum WinStatus
{
WINSTATUS_NONE = 0,
WINSTATUS_CTS,
WINSTATUS_TERRORISTS,
WINSTATUS_DRAW,
};
#if AMXX_VERSION_NUM < 183
#define ROUND_ESCAPING_TERRORISTS_NEUTRALIZED ROUND_ESCAPING_TERRORISTS_NEUTR
#define RR_ESCAPING_TERRORISTS_NEUTRALIZED RR_ESCAPING_TERRORISTS_NEUTR
#endif
enum ScenarioEventEndRound
{
ROUND_NONE,
ROUND_TARGET_BOMB,
ROUND_VIP_ESCAPED,
ROUND_VIP_ASSASSINATED,
ROUND_TERRORISTS_ESCAPED,
ROUND_CTS_PREVENT_ESCAPE,
ROUND_ESCAPING_TERRORISTS_NEUTRALIZED,
ROUND_BOMB_DEFUSED,
ROUND_CTS_WIN,
ROUND_TERRORISTS_WIN,
ROUND_END_DRAW,
ROUND_ALL_HOSTAGES_RESCUED,
ROUND_TARGET_SAVED,
ROUND_HOSTAGE_NOT_RESCUED,
ROUND_TERRORISTS_NOT_ESCAPED,
ROUND_VIP_NOT_ESCAPED,
ROUND_GAME_COMMENCE,
ROUND_GAME_RESTART,
ROUND_GAME_OVER
};
enum PLAYER_ANIM
{
PLAYER_IDLE,
PLAYER_WALK,
PLAYER_JUMP,
PLAYER_SUPERJUMP,
PLAYER_DIE,
PLAYER_ATTACK1,
PLAYER_ATTACK2,
PLAYER_FLINCH,
PLAYER_LARGE_FLINCH,
PLAYER_RELOAD,
PLAYER_HOLDBOMB
};
enum JoinState
{
JOINED,
SHOWLTEXT,
READINGLTEXT,
SHOWTEAMSELECT,
PICKINGTEAM,
GETINTOGAME
};
enum _Menu
{
Menu_OFF,
Menu_ChooseTeam,
Menu_IGChooseTeam,
Menu_ChooseAppearance,
Menu_Buy,
Menu_BuyPistol,
Menu_BuyRifle,
Menu_BuyMachineGun,
Menu_BuyShotgun,
Menu_BuySubMachineGun,
Menu_BuyItem,
Menu_Radio1,
Menu_Radio2,
Menu_Radio3,
Menu_ClientBuy
};
enum TrackCommands
{
CMD_SAY,
CMD_SAYTEAM,
CMD_FULLUPDATE,
CMD_VOTE,
CMD_VOTEMAP,
CMD_LISTMAPS,
CMD_LISTPLAYERS,
CMD_NIGHTVISION,
COMMANDS_TO_TRACK,
};
enum InventorySlotType
{
NONE_SLOT,
PRIMARY_WEAPON_SLOT,
PISTOL_SLOT,
KNIFE_SLOT,
GRENADE_SLOT,
C4_SLOT,
};
enum shieldgren_e
{
SHIELDREN_IDLE = 4,
SHIELDREN_UP,
SHIELDREN_DOWN
};
enum shieldgun_e
{
SHIELDGUN_IDLE,
SHIELDGUN_SHOOT1,
SHIELDGUN_SHOOT2,
SHIELDGUN_SHOOT_EMPTY,
SHIELDGUN_RELOAD,
SHIELDGUN_DRAW,
SHIELDGUN_DRAWN_IDLE,
SHIELDGUN_UP,
SHIELDGUN_DOWN,
};
enum SignalState
{
SIGNAL_BUY       = BIT(0),
SIGNAL_BOMB      = BIT(1),
SIGNAL_RESCUE    = BIT(2),
SIGNAL_ESCAPE    = BIT(3),
SIGNAL_VIPSAFETY = BIT(4),
};
enum WeaponState
{
WPNSTATE_USP_SILENCED       = BIT(0),
WPNSTATE_GLOCK18_BURST_MODE = BIT(1),
WPNSTATE_M4A1_SILENCED      = BIT(2),
WPNSTATE_ELITE_LEFT         = BIT(3),
WPNSTATE_FAMAS_BURST_MODE   = BIT(4),
WPNSTATE_SHIELD_DRAWN       = BIT(5),
};
enum Bullet
{
BULLET_NONE,
BULLET_PLAYER_9MM,
BULLET_PLAYER_MP5,
BULLET_PLAYER_357,
BULLET_PLAYER_BUCKSHOT,
BULLET_PLAYER_CROWBAR,
BULLET_MONSTER_9MM,
BULLET_MONSTER_MP5,
BULLET_MONSTER_12MM,
BULLET_PLAYER_45ACP,
BULLET_PLAYER_338MAG,
BULLET_PLAYER_762MM,
BULLET_PLAYER_556MM,
BULLET_PLAYER_50AE,
BULLET_PLAYER_57MM,
BULLET_PLAYER_357SIG,
};
enum RewardRules
{
RR_CTS_WIN,
RR_TERRORISTS_WIN,
RR_TARGET_BOMB,
RR_VIP_ESCAPED,
RR_VIP_ASSASSINATED,
RR_TERRORISTS_ESCAPED,
RR_CTS_PREVENT_ESCAPE,
RR_ESCAPING_TERRORISTS_NEUTRALIZED,
RR_BOMB_DEFUSED,
RR_BOMB_PLANTED,
RR_BOMB_EXPLODED,
RR_ALL_HOSTAGES_RESCUED,
RR_TARGET_BOMB_SAVED,
RR_HOSTAGE_NOT_RESCUED,
RR_VIP_NOT_ESCAPED,
RR_LOSER_BONUS_DEFAULT,
RR_LOSER_BONUS_MIN,
RR_LOSER_BONUS_MAX,
RR_LOSER_BONUS_ADD,
RR_RESCUED_HOSTAGE,
RR_TOOK_HOSTAGE_ACC,
RR_TOOK_HOSTAGE,
RR_END
};
enum ItemRestType
{
ITEM_TYPE_BUYING,
ITEM_TYPE_TOUCHED,
ITEM_TYPE_EQUIPPED
};
enum ItemID
{
ITEM_NONE = -1,
ITEM_SHIELDGUN,
ITEM_P228,
ITEM_GLOCK,
ITEM_SCOUT,
ITEM_HEGRENADE,
ITEM_XM1014,
ITEM_C4,
ITEM_MAC10,
ITEM_AUG,
ITEM_SMOKEGRENADE,
ITEM_ELITE,
ITEM_FIVESEVEN,
ITEM_UMP45,
ITEM_SG550,
ITEM_GALIL,
ITEM_FAMAS,
ITEM_USP,
ITEM_GLOCK18,
ITEM_AWP,
ITEM_MP5N,
ITEM_M249,
ITEM_M3,
ITEM_M4A1,
ITEM_TMP,
ITEM_G3SG1,
ITEM_FLASHBANG,
ITEM_DEAGLE,
ITEM_SG552,
ITEM_AK47,
ITEM_KNIFE,
ITEM_P90,
ITEM_NVG,
ITEM_DEFUSEKIT,
ITEM_KEVLAR,
ITEM_ASSAULT,
ITEM_LONGJUMP,
ITEM_SODACAN,
ITEM_HEALTHKIT,
ITEM_ANTIDOTE,
ITEM_BATTERY
};
enum InfoMapBuyParam
{
BUYING_EVERYONE = 0,
BUYING_ONLY_CTS,
BUYING_ONLY_TERRORISTS,
BUYING_NO_ONE,
};
#define USE_OFF                         0
#define USE_ON                          1
#define USE_SET                         2
#define USE_TOGGLE                      3
#define LOUD_GUN_VOLUME                 1000
#define NORMAL_GUN_VOLUME               600
#define QUIET_GUN_VOLUME                200
#define BIG_EXPLOSION_VOLUME            2048
#define NORMAL_EXPLOSION_VOLUME         1024
#define SMALL_EXPLOSION_VOLUME          512
#define BRIGHT_GUN_FLASH                512
#define NORMAL_GUN_FLASH                256
#define DIM_GUN_FLASH                   128
#define DEFAULT_LARGE_AWP_ZOOM            10
#define DEFAULT_LARGE_OTHER_SNIPERS_ZOOM  15
#define DEFAULT_SMALL_SNIPERS_ZOOM        40
#define DEFAULT_AUG_SG552_ZOOM            55
#define DEFAULT_NO_ZOOM                   90
#define SCORE_STATUS_NONE                 0
#define SCORE_STATUS_DEAD                 (1<<0)
#define SCORE_STATUS_BOMB                 (1<<1)
#define SCORE_STATUS_VIP                  (1<<2)
#define SCORE_STATUS_DEFKIT               (1<<3)
enum GameEventType
{
EVENT_INVALID = 0,
EVENT_WEAPON_FIRED,
EVENT_WEAPON_FIRED_ON_EMPTY,
EVENT_WEAPON_RELOADED,
EVENT_HE_GRENADE_EXPLODED,
EVENT_FLASHBANG_GRENADE_EXPLODED,
EVENT_SMOKE_GRENADE_EXPLODED,
EVENT_GRENADE_BOUNCED,
EVENT_BEING_SHOT_AT,
EVENT_PLAYER_BLINDED_BY_FLASHBANG,
EVENT_PLAYER_FOOTSTEP,
EVENT_PLAYER_JUMPED,
EVENT_PLAYER_DIED,
EVENT_PLAYER_LANDED_FROM_HEIGHT,
EVENT_PLAYER_TOOK_DAMAGE,
EVENT_HOSTAGE_DAMAGED,
EVENT_HOSTAGE_KILLED,
EVENT_DOOR,
EVENT_BREAK_GLASS,
EVENT_BREAK_WOOD,
EVENT_BREAK_METAL,
EVENT_BREAK_FLESH,
EVENT_BREAK_CONCRETE,
EVENT_BOMB_PLANTED,
EVENT_BOMB_DROPPED,
EVENT_BOMB_PICKED_UP,
EVENT_BOMB_BEEP,
EVENT_BOMB_DEFUSING,
EVENT_BOMB_DEFUSE_ABORTED,
EVENT_BOMB_DEFUSED,
EVENT_BOMB_EXPLODED,
EVENT_HOSTAGE_USED,
EVENT_HOSTAGE_RESCUED,
EVENT_ALL_HOSTAGES_RESCUED,
EVENT_VIP_ESCAPED,
EVENT_VIP_ASSASSINATED,
EVENT_TERRORISTS_WIN,
EVENT_CTS_WIN,
EVENT_ROUND_DRAW,
EVENT_ROUND_WIN,
EVENT_ROUND_LOSS,
EVENT_ROUND_START,
EVENT_PLAYER_SPAWNED,
EVENT_CLIENT_CORPSE_SPAWNED,
EVENT_BUY_TIME_START,
EVENT_PLAYER_LEFT_BUY_ZONE,
EVENT_DEATH_CAMERA_START,
EVENT_KILL_ALL,
EVENT_ROUND_TIME,
EVENT_DIE,
EVENT_KILL,
EVENT_HEADSHOT,
EVENT_KILL_FLASHBANGED,
EVENT_TUTOR_BUY_MENU_OPENNED,
EVENT_TUTOR_AUTOBUY,
EVENT_PLAYER_BOUGHT_SOMETHING,
EVENT_TUTOR_NOT_BUYING_ANYTHING,
EVENT_TUTOR_NEED_TO_BUY_PRIMARY_WEAPON,
EVENT_TUTOR_NEED_TO_BUY_PRIMARY_AMMO,
EVENT_TUTOR_NEED_TO_BUY_SECONDARY_AMMO,
EVENT_TUTOR_NEED_TO_BUY_ARMOR,
EVENT_TUTOR_NEED_TO_BUY_DEFUSE_KIT,
EVENT_TUTOR_NEED_TO_BUY_GRENADE,
EVENT_CAREER_TASK_DONE,
EVENT_START_RADIO_1,
EVENT_RADIO_COVER_ME,
EVENT_RADIO_YOU_TAKE_THE_POINT,
EVENT_RADIO_HOLD_THIS_POSITION,
EVENT_RADIO_REGROUP_TEAM,
EVENT_RADIO_FOLLOW_ME,
EVENT_RADIO_TAKING_FIRE,
EVENT_START_RADIO_2,
EVENT_RADIO_GO_GO_GO,
EVENT_RADIO_TEAM_FALL_BACK,
EVENT_RADIO_STICK_TOGETHER_TEAM,
EVENT_RADIO_GET_IN_POSITION_AND_WAIT,
EVENT_RADIO_STORM_THE_FRONT,
EVENT_RADIO_REPORT_IN_TEAM,
EVENT_START_RADIO_3,
EVENT_RADIO_AFFIRMATIVE,
EVENT_RADIO_ENEMY_SPOTTED,
EVENT_RADIO_NEED_BACKUP,
EVENT_RADIO_SECTOR_CLEAR,
EVENT_RADIO_IN_POSITION,
EVENT_RADIO_REPORTING_IN,
EVENT_RADIO_GET_OUT_OF_THERE,
EVENT_RADIO_NEGATIVE,
EVENT_RADIO_ENEMY_DOWN,
EVENT_END_RADIO,
EVENT_NEW_MATCH,
EVENT_PLAYER_CHANGED_TEAM,
EVENT_BULLET_IMPACT,
EVENT_GAME_COMMENCE,
EVENT_WEAPON_ZOOMED,
EVENT_HOSTAGE_CALLED_FOR_HELP,
NUM_GAME_EVENTS,
};
enum SecondaryAtkState
{
WEAPON_SECONDARY_ATTACK_NONE = 0,
WEAPON_SECONDARY_ATTACK_SET,
WEAPON_SECONDARY_ATTACK_BLOCK
};
enum Decal
{
DECAL_GUNSHOT1 = 0,
DECAL_GUNSHOT2,
DECAL_GUNSHOT3,
DECAL_GUNSHOT4,
DECAL_GUNSHOT5,
DECAL_LAMBDA1,
DECAL_LAMBDA2,
DECAL_LAMBDA3,
DECAL_LAMBDA4,
DECAL_LAMBDA5,
DECAL_LAMBDA6,
DECAL_SCORCH1,
DECAL_SCORCH2,
DECAL_BLOOD1,
DECAL_BLOOD2,
DECAL_BLOOD3,
DECAL_BLOOD4,
DECAL_BLOOD5,
DECAL_BLOOD6,
DECAL_YBLOOD1,
DECAL_YBLOOD2,
DECAL_YBLOOD3,
DECAL_YBLOOD4,
DECAL_YBLOOD5,
DECAL_YBLOOD6,
DECAL_GLASSBREAK1,
DECAL_GLASSBREAK2,
DECAL_GLASSBREAK3,
DECAL_BIGSHOT1,
DECAL_BIGSHOT2,
DECAL_BIGSHOT3,
DECAL_BIGSHOT4,
DECAL_BIGSHOT5,
DECAL_SPIT1,
DECAL_SPIT2,
DECAL_BPROOF1,
DECAL_GARGSTOMP1,
DECAL_SMALLSCORCH1,
DECAL_SMALLSCORCH2,
DECAL_SMALLSCORCH3,
DECAL_MOMMABIRTH,
DECAL_MOMMASPLAT,
};
#define REAPI_VERSION 524300
#define REAPI_VERSION_MAJOR 5
#define REAPI_VERSION_MINOR 24
enum MapNameType
{
MNT_TRUE,
MNT_SET
};
enum ResourceType_t
{
t_sound = 0,
t_skin,
t_model,
t_decal,
t_generic,
t_eventscript,
t_world,
rt_unk,
rt_max
};
#define SND_EMIT2_NOPAS   BIT(0)
#define SND_EMIT2_INVOKER BIT(1)
enum EngineFunc
{
RH_SV_StartSound = BEGIN_FUNC_REGION(engine),
RH_SV_DropClient,
RH_SV_ActivateServer,
RH_Cvar_DirectSet,
RH_SV_WriteFullClientUpdate,
RH_GetEntityInit,
RH_ClientConnected,
RH_SV_ConnectClient,
RH_SV_EmitPings,
RH_ED_Alloc,
RH_ED_Free,
RH_Con_Printf,
RH_SV_CheckUserInfo,
RH_PF_precache_generic_I,
RH_PF_precache_model_I,
RH_PF_precache_sound_I,
RH_EV_Precache,
RH_SV_AddResource,
RH_SV_ClientPrintf,
RH_ExecuteServerStringCmd,
RH_SV_AllowPhysent,
};
enum EntVars
{
var_classname = BEGIN_MEMBER_REGION(entvars),
var_globalname,
var_origin,
var_oldorigin,
var_velocity,
var_basevelocity,
var_clbasevelocity,
var_movedir,
var_angles,
var_avelocity,
var_punchangle,
var_v_angle,
var_endpos,
var_startpos,
var_impacttime,
var_starttime,
var_fixangle,
var_idealpitch,
var_pitch_speed,
var_ideal_yaw,
var_yaw_speed,
var_modelindex,
var_model,
var_viewmodel,
var_weaponmodel,
var_absmin,
var_absmax,
var_mins,
var_maxs,
var_size,
var_ltime,
var_nextthink,
var_movetype,
var_solid,
var_skin,
var_body,
var_effects,
var_gravity,
var_friction,
var_light_level,
var_sequence,
var_gaitsequence,
var_frame,
var_animtime,
var_framerate,
var_controller,
var_blending,
var_scale,
var_rendermode,
var_renderamt,
var_rendercolor,
var_renderfx,
var_health,
var_frags,
var_weapons,
var_takedamage,
var_deadflag,
var_view_ofs,
var_button,
var_impulse,
var_chain,
var_dmg_inflictor,
var_enemy,
var_aiment,
var_owner,
var_groundentity,
var_spawnflags,
var_flags,
var_colormap,
var_team,
var_max_health,
var_teleport_time,
var_armortype,
var_armorvalue,
var_waterlevel,
var_watertype,
var_target,
var_targetname,
var_netname,
var_message,
var_dmg_take,
var_dmg_save,
var_dmg,
var_dmgtime,
var_noise,
var_noise1,
var_noise2,
var_noise3,
var_speed,
var_air_finished,
var_pain_finished,
var_radsuit_finished,
var_pContainingEntity,
var_playerclass,
var_maxspeed,
var_fov,
var_weaponanim,
var_pushmsec,
var_bInDuck,
var_flTimeStepSound,
var_flSwimTime,
var_flDuckTime,
var_iStepLeft,
var_flFallVelocity,
var_gamestate,
var_oldbuttons,
var_groupinfo,
var_iuser1,
var_iuser2,
var_iuser3,
var_iuser4,
var_fuser1,
var_fuser2,
var_fuser3,
var_fuser4,
var_vuser1,
var_vuser2,
var_vuser3,
var_vuser4,
var_euser1,
var_euser2,
var_euser3,
var_euser4
};
enum UCmd
{
ucmd_lerp_msec = BEGIN_MEMBER_REGION(usercmd),
ucmd_msec,
ucmd_viewangles,
ucmd_forwardmove,
ucmd_sidemove,
ucmd_upmove,
ucmd_lightlevel,
ucmd_buttons,
ucmd_impulse,
ucmd_weaponselect,
ucmd_impact_index,
ucmd_impact_position
};
enum NetAdrType
{
NA_NULL = 0,
NA_LOOPBACK,
NA_BROADCAST,
NA_IP,
NA_IPX,
NA_BROADCAST_IPX,
};
enum NetAdrVars
{
netadr_type = BEGIN_MEMBER_REGION(netadr),
netadr_ip,
netadr_port
};
native set_entvar(const index, const EntVars:var, any:...);
native any:get_entvar(const index, const EntVars:var, any:...);
native set_ucmd(const ucmd, const UCmd:var, any:...);
native any:get_ucmd(const ucmd, const UCmd:var, any:...);
native set_netadr(const adr, const NetAdrVars:var, any:...);
native any:get_netadr(const adr, const NetAdrVars:var, any:...);
native get_key_value(const pbuffer, const key[], const value[], const maxlen);
native set_key_value(const pbuffer, const key[], const value[]);
native get_key_value_buffer(const pbuffer, const output[], const maxlen);
native set_key_value_buffer(const pbuffer, const value[], const maxlen = -1);
native GetBonePosition(const entity, const bone, Float:vecOrigin[3], Float:vecAngles[3] = {0.0, 0.0, 0.0});
native GetAttachment(const entity, const attachment, Float:vecOrigin[3], Float:vecAngles[3] = {0.0, 0.0, 0.0});
native SetBodygroup(const entity, const group, const value);
native GetBodygroup(const entity, const group);
native bool:GetSequenceInfo(const entity, &piFlags, &Float:pflFrameRate, &Float:pflGroundSpeed);
native rh_set_mapname(const mapname[]);
native rh_get_mapname(output[], len, MapNameType:type = MNT_SET);
native rh_reset_mapname();
native bool:rh_emit_sound2(const entity, const recipient, const channel, const sample[], Float:vol = VOL_NORM, Float:attn = ATTN_NORM, const flags = 0, const pitch = PITCH_NORM, emitFlags = 0, const Float:origin[3] = {0.0,0.0,0.0});
native rh_update_user_info(playerEntIndex);
native rh_drop_client(const index, const message[] = "");
native rh_get_net_from(output[], len);
native rh_get_client_connect_time(const index);
#define IsRoundExpireEvent(%0) (((1 << _:(%0) + _:ScenarioEventEndRound:0) & ((1 << _:ROUND_TARGET_SAVED) | (1 << _:ROUND_HOSTAGE_NOT_RESCUED) | (1 << _:ROUND_TERRORISTS_NOT_ESCAPED) | (1 << _:ROUND_VIP_NOT_ESCAPED) | (1 << _:ROUND_GAME_OVER))) != 0)
#if AMXX_VERSION_NUM < 183
#define RG_CBaseAnimating_ResetSequenceInfo RG_CBaseAnimating_ResetSequence
#define RG_CBasePlayer_Observer_IsValidTarget RG_CBasePlayer_Observer_IsValid
#define RG_CSGameRules_FShouldSwitchWeapon RG_CSGameRules_ShouldSwitchWpn
#define RG_CSGameRules_GetNextBestWeapon RG_CSGameRules_GetNextBestWpn
#define RG_CSGameRules_FlPlayerFallDamage RG_CSGameRules_PlayerFallDmg
#define RG_CSGameRules_FPlayerCanTakeDamage RG_CSGameRules_PlayerCanTakeDmg
#define RG_CSGameRules_FPlayerCanRespawn RG_CSGameRules_PlayerCanRespawn
#define RG_CSGameRules_GetPlayerSpawnSpot RG_CSGameRules_PlayerSpawnSpot
#define RG_CSGameRules_ClientUserInfoChanged RG_CSGameRules_UserInfoChanged
#define RG_CSGameRules_CanHavePlayerItem RG_CSGameRules_CanPlayerItem
#define RG_CSGameRules_DeadPlayerWeapons RG_CSGameRules_DeadPlayerWpn
#define RG_CSGameRules_CheckMapConditions RG_CSGameRules_CheckMapCond
#define RG_CSGameRules_CheckWinConditions RG_CSGameRules_CheckWinCond
#define RG_CSGameRules_CanPlayerHearPlayer RG_CSGameRules_CanPlrHearPlr
#define RG_CBasePlayer_SetClientUserInfoModel RG_CBasePlayer_SetUserInfoModel
#define RG_CBasePlayer_SetClientUserInfoName RG_CBasePlayer_SetUserInfoName
#define m_Shield_hEntToIgnoreTouchesFrom m_Shield_EntToIgnoreTouchesFrom
#define RG_CBasePlayer_RemoveSpawnProtection RG_CBasePlayer_RemoveProtection
#define RG_CBasePlayer_SetSpawnProtection RG_CBasePlayer_SetProtection
#define RG_CBasePlayerWeapon_DefaultDeploy RG_CBaseWeapon_DefDeploy
#define RG_CBasePlayerWeapon_DefaultReload RG_CBaseWeapon_DefReload
#define RG_CBasePlayerWeapon_DefaultShotgunReload RG_CBaseWeapon_DefShotgunReload
#define RG_CBasePlayer_Observer_SetMode RG_CBasePlayer_Observer_SetMod
#define RG_CBasePlayer_Observer_FindNextPlayer RG_CBasePlayer_Observer_FindNxt
#endif
enum UnifiedSignals
{
US_Signal,
US_State
};
enum AccountSet
{
AS_SET,
AS_ADD
};
enum WpnInfo
{
WI_ID,
WI_COST,
WI_CLIP_COST,
WI_BUY_CLIP_SIZE,
WI_GUN_CLIP_SIZE,
WI_MAX_ROUNDS,
WI_AMMO_TYPE,
WI_AMMO_NAME,
WI_NAME
};
enum ItemInfo
{
ItemInfo_iSlot,
ItemInfo_iPosition,
ItemInfo_pszAmmo1,
ItemInfo_iMaxAmmo1,
ItemInfo_pszAmmo2,
ItemInfo_iMaxAmmo2,
ItemInfo_pszName,
ItemInfo_iMaxClip,
ItemInfo_iId,
ItemInfo_iFlags,
ItemInfo_iWeight
};
enum GiveType
{
GT_APPEND,
GT_REPLACE,
GT_DROP_AND_REPLACE
};
enum MenuChooseTeam
{
MenuChoose_T = 1,
MenuChoose_CT,
MenuChoose_VIP,
MenuChoose_AutoSelect = 5,
MenuChoose_Spec,
};
enum VGUIMenu
{
VGUI_Menu_Team = 2,
VGUI_Menu_MapBriefing = 4,
VGUI_Menu_Class_T = 26,
VGUI_Menu_Class_CT,
VGUI_Menu_Buy,
VGUI_Menu_Buy_Pistol,
VGUI_Menu_Buy_ShotGun,
VGUI_Menu_Buy_Rifle,
VGUI_Menu_Buy_SubMachineGun,
VGUI_Menu_Buy_MachineGun,
VGUI_Menu_Buy_Item,
};
enum GamedllFunc
{
RG_GetForceCamera = BEGIN_FUNC_REGION(gamedll),
RG_PlayerBlind,
RG_RadiusFlash_TraceLine,
RG_RoundEnd,
RG_PM_Move,
RG_PM_AirMove,
RG_HandleMenu_ChooseAppearance,
RG_HandleMenu_ChooseTeam,
RG_ShowMenu,
RG_ShowVGUIMenu,
RG_BuyGunAmmo,
RG_BuyWeaponByWeaponID,
RG_ThrowHeGrenade,
RG_ThrowFlashbang,
RG_ThrowSmokeGrenade,
RG_PlantBomb,
RG_IsPenetrableEntity,
RG_SpawnHeadGib,
RG_SpawnRandomGibs,
RG_CreateWeaponBox,
RG_PM_LadderMove,
RG_PM_WaterJump,
RG_PM_CheckWaterJump,
RG_PM_Jump,
RG_PM_Duck,
RG_PM_UnDuck,
RG_PM_PlayStepSound,
RG_PM_AirAccelerate,
RG_ClearMultiDamage,
RG_AddMultiDamage,
RG_ApplyMultiDamage,
RG_BuyItem,
};
enum GamedllFunc_CBaseAnimating
{
RG_CBaseAnimating_ResetSequenceInfo = BEGIN_FUNC_REGION(animating)
};
enum GamedllFunc_CGrenade
{
RG_CGrenade_DefuseBombStart = BEGIN_FUNC_REGION(grenade),
RG_CGrenade_DefuseBombEnd,
RG_CGrenade_ExplodeHeGrenade,
RG_CGrenade_ExplodeFlashbang,
RG_CGrenade_ExplodeSmokeGrenade,
RG_CGrenade_ExplodeBomb,
};
enum GamedllFunc_CWeaponBox
{
RG_CWeaponBox_SetModel = BEGIN_FUNC_REGION(weaponbox),
};
enum GamedllFunc_CBasePlayer
{
RG_CBasePlayer_Spawn = BEGIN_FUNC_REGION(player),
RG_CBasePlayer_Precache,
RG_CBasePlayer_ObjectCaps,
RG_CBasePlayer_Classify,
RG_CBasePlayer_TraceAttack,
RG_CBasePlayer_TakeDamage,
RG_CBasePlayer_TakeHealth,
RG_CBasePlayer_Killed,
RG_CBasePlayer_AddPoints,
RG_CBasePlayer_AddPointsToTeam,
RG_CBasePlayer_AddPlayerItem,
RG_CBasePlayer_RemovePlayerItem,
RG_CBasePlayer_GiveAmmo,
RG_CBasePlayer_ResetMaxSpeed,
RG_CBasePlayer_Jump,
RG_CBasePlayer_Duck,
RG_CBasePlayer_PreThink,
RG_CBasePlayer_PostThink,
RG_CBasePlayer_UpdateClientData,
RG_CBasePlayer_ImpulseCommands,
RG_CBasePlayer_RoundRespawn,
RG_CBasePlayer_Blind,
RG_CBasePlayer_SetClientUserInfoModel,
RG_CBasePlayer_SetClientUserInfoName,
RG_CBasePlayer_Observer_IsValidTarget,
RG_CBasePlayer_SetAnimation,
RG_CBasePlayer_GiveDefaultItems,
RG_CBasePlayer_GiveNamedItem,
RG_CBasePlayer_AddAccount,
RG_CBasePlayer_GiveShield,
RG_CBasePlayer_DropPlayerItem,
RG_CBasePlayer_HasRestrictItem,
RG_CBasePlayer_DropShield,
RG_CBasePlayer_OnSpawnEquip,
RG_CBasePlayer_Radio,
RG_CBasePlayer_Disappear,
RG_CBasePlayer_MakeVIP,
RG_CBasePlayer_MakeBomber,
RG_CBasePlayer_StartObserver,
RG_CBasePlayer_GetIntoGame,
RG_CBasePlayer_StartDeathCam,
RG_CBasePlayer_SwitchTeam,
RG_CBasePlayer_CanSwitchTeam,
RG_CBasePlayer_ThrowGrenade,
RG_CBasePlayer_SetSpawnProtection,
RG_CBasePlayer_RemoveSpawnProtection,
RG_CBasePlayer_HintMessageEx,
RG_CBasePlayer_UseEmpty,
RG_CBasePlayer_DropIdlePlayer,
RG_CBasePlayer_Observer_SetMode,
RG_CBasePlayer_Observer_FindNextPlayer,
RG_CBasePlayer_Pain,
RG_CBasePlayer_DeathSound,
RG_CBasePlayer_JoiningThink,
RG_CBasePlayer_CheckTimeBasedDamage,
RG_CBasePlayer_EntSelectSpawnPoint,
};
enum GamedllFunc_CBasePlayerWeapon
{
RG_CBasePlayerWeapon_CanDeploy = BEGIN_FUNC_REGION(weapon),
RG_CBasePlayerWeapon_DefaultDeploy,
RG_CBasePlayerWeapon_DefaultReload,
RG_CBasePlayerWeapon_DefaultShotgunReload,
RG_CBasePlayerWeapon_ItemPostFrame,
RG_CBasePlayerWeapon_KickBack,
RG_CBasePlayerWeapon_SendWeaponAnim,
};
enum GamedllFunc_CGib
{
RG_CGib_Spawn = BEGIN_FUNC_REGION(gib),
RG_CGib_BounceGibTouch,
RG_CGib_WaitTillLand,
};
enum GamedllFunc_CBaseEntity
{
RG_CBaseEntity_FireBullets = BEGIN_FUNC_REGION(cbaseentity),
RG_CBaseEntity_FireBuckshots,
RG_CBaseEntity_FireBullets3,
};
enum GamedllFunc_CBotManager
{
RG_CBotManager_OnEvent = BEGIN_FUNC_REGION(botmanager),
}
enum GamedllFunc_CSGameRules
{
RG_CSGameRules_FShouldSwitchWeapon = BEGIN_FUNC_REGION(gamerules),
RG_CSGameRules_GetNextBestWeapon,
RG_CSGameRules_FlPlayerFallDamage,
RG_CSGameRules_FPlayerCanTakeDamage,
RG_CSGameRules_PlayerSpawn,
RG_CSGameRules_FPlayerCanRespawn,
RG_CSGameRules_GetPlayerSpawnSpot,
RG_CSGameRules_ClientUserInfoChanged,
RG_CSGameRules_PlayerKilled,
RG_CSGameRules_DeathNotice,
RG_CSGameRules_CanHavePlayerItem,
RG_CSGameRules_DeadPlayerWeapons,
RG_CSGameRules_ServerDeactivate,
RG_CSGameRules_CheckMapConditions,
RG_CSGameRules_CleanUpMap,
RG_CSGameRules_RestartRound,
RG_CSGameRules_CheckWinConditions,
RG_CSGameRules_RemoveGuns,
RG_CSGameRules_GiveC4,
RG_CSGameRules_ChangeLevel,
RG_CSGameRules_GoToIntermission,
RG_CSGameRules_BalanceTeams,
RG_CSGameRules_OnRoundFreezeEnd,
RG_CSGameRules_CanPlayerHearPlayer,
RG_CSGameRules_Think,
RG_CSGameRules_TeamFull,
RG_CSGameRules_TeamStacked,
RG_CSGameRules_PlayerGotWeapon,
};
enum CSGameRules_Members
{
m_bFreezePeriod = BEGIN_MEMBER_REGION(gamerules),
m_bBombDropped,
m_GameDesc,
m_msgPlayerVoiceMask,
m_msgRequestState,
m_nMaxPlayers,
m_UpdateInterval,
m_flRestartRoundTime,
m_flCheckWinConditions,
m_fRoundStartTime,
m_iRoundTime,
m_iRoundTimeSecs,
m_iIntroRoundTime,
m_fRoundStartTimeReal,
m_iAccountTerrorist,
m_iAccountCT,
m_iNumTerrorist,
m_iNumCT,
m_iNumSpawnableTerrorist,
m_iNumSpawnableCT,
m_iSpawnPointCount_Terrorist,
m_iSpawnPointCount_CT,
m_iHostagesRescued,
m_iHostagesTouched,
m_iRoundWinStatus,
m_iNumCTWins,
m_iNumTerroristWins,
m_bTargetBombed,
m_bBombDefused,
m_bMapHasBombTarget,
m_bMapHasBombZone,
m_bMapHasBuyZone,
m_bMapHasRescueZone,
m_bMapHasEscapeZone,
m_bMapHasVIPSafetyZone,
m_bMapHasCameras,
m_iC4Timer,
m_iC4Guy,
m_iLoserBonus,
m_iNumConsecutiveCTLoses,
m_iNumConsecutiveTerroristLoses,
m_fMaxIdlePeriod,
m_iLimitTeams,
m_bLevelInitialized,
m_bRoundTerminating,
m_bCompleteReset,
m_flRequiredEscapeRatio,
m_iNumEscapers,
m_iHaveEscaped,
m_bCTCantBuy,
m_bTCantBuy,
m_flBombRadius,
m_iConsecutiveVIP,
m_iTotalGunCount,
m_iTotalGrenadeCount,
m_iTotalArmourCount,
m_iUnBalancedRounds,
m_iNumEscapeRounds,
m_iMapVotes,
m_iLastPick,
m_iMaxMapTime,
m_iMaxRounds,
m_iTotalRoundsPlayed,
m_iMaxRoundsWon,
m_iStoredSpectValue,
m_flForceCameraValue,
m_flForceChaseCamValue,
m_flFadeToBlackValue,
m_pVIP,
m_pVIPQueue,
m_flIntermissionEndTime,
m_flIntermissionStartTime,
m_iEndIntermissionButtonHit,
m_tmNextPeriodicThink,
m_bGameStarted,
m_bInCareerGame,
m_fCareerRoundMenuTime,
m_iCareerMatchWins,
m_iRoundWinDifference,
m_fCareerMatchMenuTime,
m_bSkipSpawn,
m_bSkipShowMenu,
m_bNeededPlayers,
m_flEscapeRatio,
m_flTimeLimit,
m_flGameStartTime,
m_bTeamBalanced,
};
enum CBaseEntity_Members
{
currentammo = BEGIN_MEMBER_REGION(base),
maxammo_buckshot,
ammo_buckshot,
maxammo_9mm,
ammo_9mm,
maxammo_556nato,
ammo_556nato,
maxammo_556natobox,
ammo_556natobox,
maxammo_762nato,
ammo_762nato,
maxammo_45acp,
ammo_45acp,
maxammo_50ae,
ammo_50ae,
maxammo_338mag,
ammo_338mag,
maxammo_57mm,
ammo_57mm,
maxammo_357sig,
ammo_357sig,
m_flStartThrow,
m_flReleaseThrow,
m_iSwing,
has_disconnected,
};
enum CBaseAnimating_Members
{
m_flFrameRate = BEGIN_MEMBER_REGION(animating),
m_flGroundSpeed,
m_flLastEventCheck,
m_fSequenceFinished,
m_fSequenceLoops,
};
enum CBaseMonster_Members
{
m_Activity = BEGIN_MEMBER_REGION(basemonster),
m_IdealActivity,
m_LastHitGroup,
m_bitsDamageType,
m_rgbTimeBasedDamage,
m_MonsterState,
m_IdealMonsterState,
m_afConditions,
m_afMemory,
m_flNextAttack,
m_hEnemy,
m_hTargetEnt,
m_flFieldOfView,
m_bloodColor,
m_HackedGunPos,
m_vecEnemyLKP,
};
enum CBasePlayer_Members
{
random_seed = BEGIN_MEMBER_REGION(player),
m_usPlayerBleed,
m_hObserverTarget,
m_flNextObserverInput,
m_iObserverWeapon,
m_iObserverC4State,
m_bObserverHasDefuser,
m_iObserverLastMode,
m_flFlinchTime,
m_flAnimTime,
m_bHighDamage,
m_flVelocityModifier,
m_iLastZoom,
m_bResumeZoom,
m_flEjectBrass,
m_iKevlar,
m_bNotKilled,
m_iTeam,
m_iAccount,
m_bHasPrimary,
m_flDeathThrowTime,
m_iThrowDirection,
m_flLastTalk,
m_bJustConnected,
m_bContextHelp,
m_iJoiningState,
m_pIntroCamera,
m_fIntroCamTime,
m_fLastMovement,
m_bMissionBriefing,
m_bTeamChanged,
m_iModelName,
m_iTeamKills,
m_iIgnoreGlobalChat,
m_bHasNightVision,
m_bNightVisionOn,
m_vRecentPath,
m_flIdleCheckTime,
m_flRadioTime,
m_iRadioMessages,
m_bIgnoreRadio,
m_bHasC4,
m_bHasDefuser,
m_bKilledByBomb,
m_vBlastVector,
m_bKilledByGrenade,
m_flDisplayHistory,
m_iMenu,
m_iChaseTarget,
m_pChaseTarget,
m_fCamSwitch,
m_bEscaped,
m_bIsVIP,
m_tmNextRadarUpdate,
m_vLastOrigin,
m_iCurrentKickVote,
m_flNextVoteTime,
m_bJustKilledTeammate,
m_iHostagesKilled,
m_iMapVote,
m_bCanShoot,
m_flLastFired,
m_flLastAttackedTeammate,
m_bHeadshotKilled,
m_bPunishedForTK,
m_bReceivesNoMoneyNextRound,
m_iTimeCheckAllowed,
m_bHasChangedName,
m_szNewName,
m_bIsDefusing,
m_tmHandleSignals,
m_signals,
m_pentCurBombTarget,
m_iPlayerSound,
m_iTargetVolume,
m_iWeaponVolume,
m_iExtraSoundTypes,
m_iWeaponFlash,
m_flStopExtraSoundTime,
m_flFlashLightTime,
m_iFlashBattery,
m_afButtonLast,
m_afButtonPressed,
m_afButtonReleased,
m_pentSndLast,
m_flSndRoomtype,
m_flSndRange,
m_flFallVelocity,
m_rgItems,
m_fNewAmmo,
m_afPhysicsFlags,
m_fNextSuicideTime,
m_flTimeStepSound,
m_flTimeWeaponIdle,
m_flSwimTime,
m_flDuckTime,
m_flWallJumpTime,
m_flSuitUpdate,
m_rgSuitPlayList,
m_iSuitPlayNext,
m_rgiSuitNoRepeat,
m_rgflSuitNoRepeatTime,
m_lastDamageAmount,
m_tbdPrev,
m_flgeigerRange,
m_flgeigerDelay,
m_igeigerRangePrev,
m_iStepLeft,
m_szTextureName,
m_chTextureType,
m_idrowndmg,
m_idrownrestored,
m_bitsHUDDamage,
m_fInitHUD,
m_fGameHUDInitialized,
m_iTrain,
m_fWeapon,
m_pTank,
m_fDeadTime,
m_fNoPlayerSound,
m_fLongJump,
m_tSneaking,
m_iUpdateTime,
m_iClientHealth,
m_iClientBattery,
m_iHideHUD,
m_iClientHideHUD,
m_iFOV,
m_iClientFOV,
m_iNumSpawns,
m_pObserver,
m_rgpPlayerItems,
m_pActiveItem,
m_pClientActiveItem,
m_pLastItem,
m_rgAmmo,
m_rgAmmoLast,
m_vecAutoAim,
m_fOnTarget,
m_iDeaths,
m_izSBarState,
m_flNextSBarUpdateTime,
m_flStatusBarDisappearDelay,
m_SbarString0,
m_lastx,
m_lasty,
m_nCustomSprayFrames,
m_flNextDecalTime,
m_szTeamName,
m_modelIndexPlayer,
m_szAnimExtention,
m_iGaitsequence,
m_flGaitframe,
m_flGaityaw,
m_prevgaitorigin,
m_flPitch,
m_flYaw,
m_flGaitMovement,
m_iAutoWepSwitch,
m_bVGUIMenus,
m_bShowHints,
m_bShieldDrawn,
m_bOwnsShield,
m_bWasFollowing,
m_flNextFollowTime,
m_flYawModifier,
m_blindUntilTime,
m_blindStartTime,
m_blindHoldTime,
m_blindFadeTime,
m_blindAlpha,
m_allowAutoFollowTime,
m_autoBuyString,
m_rebuyString,
m_rebuyStruct,
m_bIsInRebuy,
m_flLastUpdateTime,
m_lastLocation,
m_progressStart,
m_progressEnd,
m_bObserverAutoDirector,
m_canSwitchObserverModes,
m_heartBeatTime,
m_intenseTimestamp,
m_silentTimestamp,
m_musicState,
m_flLastCommandTime,
m_iLastAccount,
m_iLastClientHealth,
m_tmNextAccountHealthUpdate,
};
enum RebuyStruct
{
m_primaryWeapon = BEGIN_MEMBER_REGION(rebuystruct),
m_primaryAmmo,
m_secondaryWeapon,
m_secondaryAmmo,
m_heGrenade,
m_flashbang,
m_smokeGrenade,
m_defuser,
m_nightVision,
m_armor,
};
enum PlayerMove
{
pm_player_index = BEGIN_MEMBER_REGION(playermove),
pm_server,
pm_multiplayer,
pm_time,
pm_frametime,
pm_forward,
pm_right,
pm_up,
pm_origin,
pm_angles,
pm_oldangles,
pm_velocity,
pm_movedir,
pm_basevelocity,
pm_view_ofs,
pm_flDuckTime,
pm_bInDuck,
pm_flTimeStepSound,
pm_iStepLeft,
pm_flFallVelocity,
pm_punchangle,
pm_flSwimTime,
pm_flNextPrimaryAttack,
pm_effects,
pm_flags,
pm_usehull,
pm_gravity,
pm_friction,
pm_oldbuttons,
pm_waterjumptime,
pm_dead,
pm_deadflag,
pm_spectator,
pm_movetype,
pm_onground,
pm_waterlevel,
pm_watertype,
pm_oldwaterlevel,
pm_sztexturename,
pm_chtexturetype,
pm_maxspeed,
pm_clientmaxspeed,
pm_iuser1,
pm_iuser2,
pm_iuser3,
pm_iuser4,
pm_fuser1,
pm_fuser2,
pm_fuser3,
pm_fuser4,
pm_vuser1,
pm_vuser2,
pm_vuser3,
pm_vuser4,
pm_numphysent,
pm_cmd,
pm_numtouch,
pm_physinfo,
pm_player_mins,
pm_player_maxs,
};
enum MoveVars
{
mv_gravity = BEGIN_MEMBER_REGION(movevars),
mv_stopspeed,
mv_maxspeed,
mv_spectatormaxspeed,
mv_accelerate,
mv_airaccelerate,
mv_wateraccelerate,
mv_friction,
mv_edgefriction,
mv_waterfriction,
mv_entgravity,
mv_bounce,
mv_stepsize,
mv_maxvelocity,
mv_zmax,
mv_waveHeight,
mv_footsteps,
mv_skyName,
mv_rollangle,
mv_rollspeed,
mv_skycolor_r,
mv_skycolor_g,
mv_skycolor_b,
mv_skyvec_x,
mv_skyvec_y,
mv_skyvec_z,
};
enum PMTrace
{
pmt_allsolid = BEGIN_MEMBER_REGION(pmtrace),
pmt_startsolid,
pmt_inopen,
pmt_inwater,
pmt_fraction,
pmt_endpos,
pmt_ent,
pmt_deltavelocity,
pmt_hitgroup
};
enum CCSPlayer_Members
{
m_szModel = BEGIN_MEMBER_REGION(csplayer),
m_bForceShowMenu,
m_flRespawnPending,
m_flSpawnProtectionEndTime,
m_vecOldvAngle,
m_iWeaponInfiniteAmmo,
m_iWeaponInfiniteIds,
m_bCanShootOverride,
m_bGameForcingRespawn,
m_bAutoBunnyHopping,
m_bMegaBunnyJumping,
m_bPlantC4Anywhere,
m_bSpawnProtectionEffects,
m_flJumpHeight,
m_flLongJumpHeight,
m_flLongJumpForce,
m_flDuckSpeedMultiplier,
m_iNumKilledByUnanswered,
m_bPlayerDominated,
};
enum CBasePlayerItem_Members
{
m_pPlayer = BEGIN_MEMBER_REGION(baseitem),
m_pNext,
m_iId,
};
enum CBasePlayerWeapon_Members
{
m_Weapon_iPlayEmptySound = BEGIN_MEMBER_REGION(baseweapon),
m_Weapon_fFireOnEmpty,
m_Weapon_flNextPrimaryAttack,
m_Weapon_flNextSecondaryAttack,
m_Weapon_flTimeWeaponIdle,
m_Weapon_iPrimaryAmmoType,
m_Weapon_iSecondaryAmmoType,
m_Weapon_iClip,
m_Weapon_iClientClip,
m_Weapon_iClientWeaponState,
m_Weapon_fInReload,
m_Weapon_fInSpecialReload,
m_Weapon_iDefaultAmmo,
m_Weapon_iShellId,
m_Weapon_fMaxSpeed,
m_Weapon_bDelayFire,
m_Weapon_iDirection,
m_Weapon_bSecondarySilencerOn,
m_Weapon_flAccuracy,
m_Weapon_flLastFire,
m_Weapon_iShotsFired,
m_Weapon_flGlock18Shoot,
m_Weapon_iGlock18ShotsFired,
m_Weapon_flFamasShoot,
m_Weapon_iFamasShotsFired,
m_Weapon_fBurstSpread,
m_Weapon_iWeaponState,
m_Weapon_flNextReload,
m_Weapon_flDecreaseShotsFired,
m_Weapon_usFireGlock18,
m_Weapon_usFireFamas,
m_Weapon_flPrevPrimaryAttack,
m_Weapon_flLastFireTime,
};
enum CWeaponBox_Members
{
m_WeaponBox_rgpPlayerItems = BEGIN_MEMBER_REGION(weaponbox),
m_WeaponBox_rgiszAmmo,
m_WeaponBox_rgAmmo,
m_WeaponBox_cAmmoTypes,
m_WeaponBox_bIsBomb,
};
enum CArmoury_Members
{
m_Armoury_iItem = BEGIN_MEMBER_REGION(armoury),
m_Armoury_iCount,
m_Armoury_iInitialCount,
m_Armoury_bAlreadyCounted,
};
enum CGrenade_Members
{
m_Grenade_bStartDefuse = BEGIN_MEMBER_REGION(grenade),
m_Grenade_bIsC4,
m_Grenade_pBombDefuser,
m_Grenade_flDefuseCountDown,
m_Grenade_flC4Blow,
m_Grenade_flNextFreqInterval,
m_Grenade_flNextBeep,
m_Grenade_flNextFreq,
m_Grenade_sBeepName,
m_Grenade_fAttenu,
m_Grenade_flNextBlink,
m_Grenade_fNextDefuse,
m_Grenade_bJustBlew,
m_Grenade_iTeam,
m_Grenade_iCurWave,
m_Grenade_pentCurBombTarget,
m_Grenade_SGSmoke,
m_Grenade_angle,
m_Grenade_usEvent,
m_Grenade_bLightSmoke,
m_Grenade_bDetonated,
m_Grenade_vSmokeDetonate,
m_Grenade_iBounceCount,
m_Grenade_fRegisteredSound,
};
enum CP228_Members
{
m_P228_iShell = BEGIN_MEMBER_REGION(p228),
m_P228_usFire,
};
enum CSCOUT_Members
{
m_SCOUT_iShell = BEGIN_MEMBER_REGION(scout),
m_SCOUT_usFire,
};
enum CHEGrenade_Members
{
m_HEGrenade_usCreate = BEGIN_MEMBER_REGION(hegrenade),
};
enum CXM1014_Members
{
m_XM1014_iShell = BEGIN_MEMBER_REGION(xm1014),
m_XM1014_flPumpTime,
m_XM1014_usFire,
};
enum CC4_Members
{
m_C4_bStartedArming = BEGIN_MEMBER_REGION(c4),
m_C4_bBombPlacedAnimation,
m_C4_fArmedTime,
m_C4_bHasShield,
};
enum CMAC10_Members
{
m_MAC10_iShell = BEGIN_MEMBER_REGION(mac10),
m_MAC10_iShellOn,
m_MAC10_usFire,
};
enum CAUG_Members
{
m_AUG_iShell = BEGIN_MEMBER_REGION(aug),
m_AUG_iShellOn,
m_AUG_usFire,
};
enum CSmokeGrenade_Members
{
m_SmokeGrenade_usCreate = BEGIN_MEMBER_REGION(smokegrenade),
};
enum CELITE_Members
{
m_ELITE_iShell = BEGIN_MEMBER_REGION(elite),
m_ELITE_usFire_LEFT,
m_ELITE_usFire_RIGHT,
};
enum CFiveSeven_Members
{
m_FiveSeven_iShell = BEGIN_MEMBER_REGION(fiveseven),
m_FiveSeven_usFire,
};
enum CUMP45_Members
{
m_UMP45_iShell = BEGIN_MEMBER_REGION(ump45),
m_UMP45_iShellOn,
m_UMP45_usFire,
};
enum CSG550_Members
{
m_SG550_iShell = BEGIN_MEMBER_REGION(sg550),
m_SG550_usFire,
};
enum CGalil_Members
{
m_Galil_iShell = BEGIN_MEMBER_REGION(galil),
m_Galil_iShellOn,
m_Galil_usFire,
};
enum CFamas_Members
{
m_Famas_iShell = BEGIN_MEMBER_REGION(famas),
m_Famas_iShellOn,
m_Famas_flBaseDamageBurst,
};
enum CUSP_Members
{
m_USP_iShell = BEGIN_MEMBER_REGION(usp),
m_USP_usFire,
m_USP_flBaseDamageSil,
};
enum CGLOCK18_Members
{
m_GLOCK18_iShell = BEGIN_MEMBER_REGION(glock18),
m_GLOCK18_bBurstFire,
};
enum CAWP_Members
{
m_AWP_iShell = BEGIN_MEMBER_REGION(awp),
m_AWP_usFire,
};
enum CMP5N_Members
{
m_MP5N_iShell = BEGIN_MEMBER_REGION(mp5n),
m_MP5N_iShellOn,
m_MP5N_usFire,
};
enum CM249_Members
{
m_M249_iShell = BEGIN_MEMBER_REGION(m249),
m_M249_iShellOn,
m_M249_usFire,
};
enum CM3_Members
{
m_M3_iShell = BEGIN_MEMBER_REGION(m3),
m_M3_flPumpTime,
m_M3_usFire,
};
enum CM4A1_Members
{
m_M4A1_iShell = BEGIN_MEMBER_REGION(m4a1),
m_M4A1_iShellOn,
m_M4A1_usFire,
m_M4A1_flBaseDamageSil,
};
enum CTMP_Members
{
m_TMP_iShell = BEGIN_MEMBER_REGION(tmp),
m_TMP_iShellOn,
m_TMP_usFire,
};
enum CG3SG1_Members
{
m_G3SG1_iShell = BEGIN_MEMBER_REGION(g3sg1),
m_G3SG1_usFire,
};
enum CDEAGLE_Members
{
m_DEAGLE_iShell = BEGIN_MEMBER_REGION(deagle),
m_DEAGLE_usFire,
};
enum CSG552_Members
{
m_SG552_iShell = BEGIN_MEMBER_REGION(sg552),
m_SG552_iShellOn,
m_SG552_usFire,
};
enum CAK47_Members
{
m_AK47_iShell = BEGIN_MEMBER_REGION(ak47),
m_AK47_iShellOn,
m_AK47_usFire,
};
enum CKnife_Members
{
m_Knife_trHit = BEGIN_MEMBER_REGION(knife),
m_Knife_usKnife,
m_Knife_flStabBaseDamage,
m_Knife_flSwingBaseDamage,
m_Knife_flSwingBaseDamage_Fast,
m_Knife_flStabDistance,
m_Knife_flSwingDistance,
m_Knife_flBackStabMultiplier,
};
enum CP90_Members
{
m_P90_iShell = BEGIN_MEMBER_REGION(p90),
m_P90_iShellOn,
m_P90_usFire,
};
enum CShield_Members
{
m_Shield_hEntToIgnoreTouchesFrom = BEGIN_MEMBER_REGION(shield),
m_Shield_flTimeToIgnoreTouches,
};
enum CMapInfo_Members
{
m_MapInfo_iBuyingStatus = BEGIN_MEMBER_REGION(mapinfo),
m_MapInfo_flBombRadius,
};
enum CCSPlayerWeapon_Members
{
m_Weapon_iStateSecondaryAttack = BEGIN_MEMBER_REGION(csplayerweapon),
m_Weapon_flBaseDamage,
};
#define m_Weapon_bHasSecondaryAttack m_Weapon_iStateSecondaryAttack
enum CGib_Members
{
m_Gib_bloodColor = BEGIN_MEMBER_REGION(gib),
m_Gib_cBloodDecals,
m_Gib_material,
m_Gib_lifeTime,
};
enum CCSEntity_Members
{
m_ucDmgPenetrationLevel = BEGIN_MEMBER_REGION(csentity),
m_pevLastInflictor,
};
native SetThink(const ent, const callback[], const params[] = "", const len = 0);
native SetTouch(const ent, const callback[], const params[] = "", const len = 0);
native SetUse(const ent, const callback[], const params[] = "", const len = 0);
native SetBlocked(const ent, const callback[], const params[] = "", const len = 0);
native SetMoveDone(const ent, const callback[], const params[] = "", const len = 0);
native set_member_game(CSGameRules_Members:member, any:...);
native any:get_member_game(CSGameRules_Members:member, any:...);
native set_member(const index, any:member, any:...);
native any:get_member(const index, any:member, any:...);
native set_member_s(const index, any:member, any:...);
native any:get_member_s(const index, any:member, any:...);
native set_pmove(const PlayerMove:var, any:...);
native any:get_pmove(const PlayerMove:var, any:...);
native set_movevar(const MoveVars:var, any:...);
native any:get_movevar(const MoveVars:var, any:...);
native set_pmtrace(const tracehandle, const PMTrace:var, any:...);
native any:get_pmtrace(const tracehandle, const PMTrace:var, any:...);
native set_rebuy(const RebuyHandle:rebuyhandle, const RebuyStruct:member, any:value);
native any:get_rebuy(const RebuyHandle:rebuyhandle, RebuyStruct:member);
native rg_set_animation(const index, PLAYER_ANIM:playerAnim);
native rg_add_account(const index, amount, AccountSet:typeSet = AS_ADD, const bool:bTrackChange = true);
native rg_give_item(const index, const pszName[], GiveType:type = GT_APPEND);
native rg_give_custom_item(const index, const pszName[], GiveType:type = GT_APPEND, const uid = 0);
native rg_give_default_items(const index);
native rg_give_shield(const index, const bool:bDeploy = true);
native rg_dmg_radius(Float:vecSrc[3], const inflictor, const attacker, const Float:flDamage, const Float:flRadius, const iClassIgnore, const bitsDamageType);
native rg_multidmg_clear();
native rg_multidmg_apply(const inflictor, const attacker);
native rg_multidmg_add(const inflictor, const victim, const Float:flDamage, const bitsDamageType);
native rg_fire_bullets(const inflictor, const attacker, const shots, Float:vecSrc[3], Float:vecDirShooting[3], Float:vecSpread[3], const Float:flDistance, const Bullet:iBulletType, const iTracerFreq, const iDamage);
native rg_fire_buckshots(const inflictor, const attacker, const shots, Float:vecSrc[3], Float:vecDirShooting[3], Float:vecSpread[3], const Float:flDistance, const iTracerFreq, const iDamage);
native Float:[3] rg_fire_bullets3(const inflictor, const attacker, Float:vecSrc[3], Float:vecDirShooting[3], const Float:vecSpread, const Float:flDistance, const iPenetration, const Bullet:iBulletType, const iDamage, const Float:flRangeModifier, const bool:bPistol, const shared_rand);
native rg_round_end(const Float:tmDelay, const WinStatus:st, const ScenarioEventEndRound:event = ROUND_NONE, const message[] = "default", const sentence[] = "default", const bool:trigger = false);
native rg_update_teamscores(const iCtsWins = 0, const iTsWins = 0, const bool:bAdd = true);
native rg_create_entity(const classname[], const bool:useHashTable = false);
native rg_find_ent_by_class(start_index, const classname[], const bool:useHashTable = false);
native rg_find_ent_by_owner(&start_index, const classname[], owner);
native rg_find_weapon_bpack_by_name(const index, const weapon[]);
native bool:rg_has_item_by_name(const index, const item[]);
native any:rg_get_weapon_info(any:...);
native rg_set_weapon_info(const {WeaponIdType,_}:weapon_id, WpnInfo:type, any:...);
native rg_remove_items_by_slot(const index, const InventorySlotType:slot, const bool:removeAmmo = true);
native rg_drop_items_by_slot(const index, const InventorySlotType:slot);
native rg_remove_all_items(const index, const bool:removeSuit = false);
native rg_drop_item(const index, const item_name[]);
native rg_internal_cmd(const index, const cmd[], const arg[] = "");
native rg_remove_item(const index, const item_name[], const bool:removeAmmo = false);
native rg_set_user_bpammo(const index, WeaponIdType:weapon, amount);
native rg_get_user_bpammo(const index, WeaponIdType:weapon);
native rg_set_user_ammo(const index, WeaponIdType:weapon, amount);
native rg_get_user_ammo(const index, WeaponIdType:weapon);
native rg_give_defusekit(const index, const bool:bDefusekit = true, const Float:color[] = {0.0, 160.0, 0.0}, const icon[] = "defuser", const bool:bFlash = false);
native rg_get_user_armor(const index, &ArmorType:armortype = ARMOR_NONE);
native rg_set_user_armor(const index, armorvalue, ArmorType:armortype);
native rg_set_user_team(const index, {TeamName,_}:team, {ModelName,_}:model = MODEL_AUTO, const bool:send_teaminfo = true, const bool:check_win_conditions = false);
native rg_set_user_model(const index, const model[], const bool:update_index = false);
native rg_reset_user_model(const index, const bool:update_index = false);
native rg_set_user_footsteps(const index, bool:silent = false);
native rg_get_user_footsteps(const index);
native rg_transfer_c4(const index, const receiver = 0);
native rg_instant_reload_weapons(const index, const weapon = 0);
native rg_plant_bomb(const index, Float:vecOrigin[3], Float:vecAngles[3] = {0.0,0.0,0.0});
native rg_set_account_rules(const RewardRules:rules_index, const amount);
native rg_get_account_rules(const RewardRules:rules_index);
native bool:rg_is_bomb_planted();
native rg_join_team(const index, const TeamName:team);
native rg_balance_teams();
native rg_swap_all_players();
native rg_switch_team(const index);
native rg_switch_weapon(const index, const weapon);
native TeamName:rg_get_join_team_priority();
native bool:rg_is_player_can_takedamage(const index, const attacker);
native bool:rg_is_player_can_respawn(const index);
native WeaponIdType:rg_get_weaponbox_id(const entity);
native rg_round_respawn(const index);
native rg_reset_maxspeed(const index);
native rg_send_bartime(const index, const duration, const bool:observer = true);
native rg_send_bartime2(const index, const duration, const Float:startPercent, const bool:observer = true);
native rg_send_audio(const index, const sample[], const pitch = PITCH_NORM);
native rg_set_iteminfo(const entity, ItemInfo:type, any:...);
native rg_get_iteminfo(const ent, ItemInfo:type, any:...);
native rg_set_global_iteminfo(const {WeaponIdType,_}:weapon_id, ItemInfo:type, any:...);
native rg_get_global_iteminfo(const {WeaponIdType,_}:weapon_id, ItemInfo:type, any:...);
native bool:rg_hint_message(const index, const message[], Float:duration = 6.0, bool:bDisplayIfPlayerDead = false, bool:bOverride = false);
native rg_restart_round();
native rg_check_win_conditions();
native rg_initialize_player_counts(&num_alive_terrorist = 0, &num_alive_ct = 0, &num_dead_terrorist = 0, &num_dead_ct = 0);
native rg_reset_can_hear_player(const index);
native rg_set_can_hear_player(const listener, const sender, const bool:can_hear);
native bool:rg_get_can_hear_player(const listener, const sender);
native rg_spawn_head_gib(const index);
native rg_spawn_random_gibs(const index, const cGibs, const bool:bHuman = true);
native rg_spawn_grenade(WeaponIdType:weaponId, pevOwner, Float:vecSrc[3], Float:vecThrow[3], Float:time, TeamName:iTeam, usEvent = 0);
native rg_create_weaponbox(const pItem, const pPlayerOwner, const modelName[], Float:origin[3], Float:angles[3], Float:velocity[3], Float:lifeTime, bool:packAmmo);
native rg_remove_entity(const pEntity);
native rg_decal_trace(const ptr, Decal:decalNumber);
native rg_emit_texture_sound(const ptr, Float:vecSrc[3], Float:vecEnd[3], Bullet:iBulletType);
native rg_add_ammo_registry(const szAmmoname[]);
native rg_weapon_deploy(const entity, const szViewModel[], const szWeaponModel[], iAnim, const szAnimExt[], skiplocal = 0);
native rg_weapon_reload(const entity, iClipSize, iAnim, Float:fDelay);
native rg_weapon_shotgun_reload(const entity, iAnim, iStartAnim, Float:fDelay, Float:fStartDelay, const pszReloadSound1[] = "", const pszReloadSound2[] = "");
native rg_weapon_send_animation(const entity, iAnim, skiplocal = 0);
native rg_weapon_kickback(const entity, Float:up_base, Float:lateral_base, Float:up_modifier, Float:lateral_modifier, Float:up_max, Float:lateral_max, direction_change);
native rg_switch_best_weapon(const player, const currentWeapon = 0);
native rg_disappear(const player);
native rg_set_observer_mode(const player, const mode);
native rg_death_notice(const pVictim, const pKiller, const pevInflictor);
#if !defined(MEMBER_UNSAFE)
#define set_member set_member_s
#define get_member get_member_s
#endif
native bool:VTC_IsClientSpeaking(const index);
native VTC_MuteClient(const index);
native VTC_UnmuteClient(const index);
native bool:VTC_IsClientMuted(const index);
native VTC_PlaySound(const receiver, const soundFilePath[]);
forward VTC_OnClientStartSpeak(const index);
forward VTC_OnClientStopSpeak(const index);
enum client_auth_type
{
CA_TYPE_NONE = 0,
CA_TYPE_DPROTO,
CA_TYPE_STEAM,
CA_TYPE_STEAMEMU,
CA_TYPE_REVEMU,
CA_TYPE_OLDREVEMU,
CA_TYPE_HLTV,
CA_TYPE_SC2009,
CA_TYPE_AVSMP,
CA_TYPE_SXEI,
CA_TYPE_REVEMU2013,
CA_TYPE_SSE3,
};
#define is_user_steam(%0) (REU_GetAuthtype(%0) == CA_TYPE_STEAM)
native REU_GetProtocol(const index);
native client_auth_type:REU_GetAuthtype(const index);
native REU_GetAuthKey(const index, dest[], maxlen);
native bool:REU_IsRevemuWithoutAdminRights(const index);
enum ResourceType
{
RES_TYPE_NONE = 0,
RES_TYPE_EXISTS,
RES_TYPE_MISSING,
RES_TYPE_IGNORE,
RES_TYPE_HASH_ANY,
};
enum ReCheckerFunc
{
RC_FileConsistencyProcess = BEGIN_FUNC_REGION(rechecker),
RC_FileConsistencyFinal,
RC_CmdExec,
};
native QueryFileHook:RegisterQueryFile(const file[], const function[], const ResourceType:type, const hash = -1);
native bool:UnRegisterQueryFile(QueryFileHook:hook);
enum
{
HC_CONTINUE = 0,
HC_SUPERCEDE,
HC_BREAK
};
enum AType
{
ATYPE_INTEGER = 0,
ATYPE_FLOAT,
ATYPE_STRING,
ATYPE_CLASSPTR,
ATYPE_EDICT,
ATYPE_EVARS,
ATYPE_BOOL,
ATYPE_VECTOR,
ATYPE_TRACE
};
enum HookChain
{
INVALID_HOOKCHAIN = 0
};
native HookChain:RegisterHookChain(ReAPIFunc:function_id, const callback[], post = 0);
native bool:DisableHookChain(HookChain:hook);
native bool:EnableHookChain(HookChain:hook);
native SetHookChainReturn(AType:type, any:...);
native any:GetHookChainReturn(AType:type, any:...);
native SetHookChainArg(number, AType:type, any:...);
native bool:IsReapiHookOriginalWasCalled(ReAPIFunc:function_id);
native HookChain:GetCurrentHookChainHandle();
native bool:FClassnameIs(const entityIndex, const className[]);
native WeaponIdType:GetGrenadeType(const entityIndex);
native engset_view(const index, const viewEntity);
native get_viewent(const index);
native bool:is_entity(const entityIndex);
native bool:is_rehlds();
native bool:is_regamedll();
native bool:has_reunion();
native bool:has_vtc();
native bool:has_rechecker();
public __reapi_version_check(const majorVersion, const minorVersion)
{
if (majorVersion != REAPI_VERSION_MAJOR)
{
new temp[512];
formatex(temp, sizeof temp - 1, "[ReAPI]: Api major version mismatch; expected %d, real %d", REAPI_VERSION_MAJOR, majorVersion);
set_fail_state(temp);
return;
}
if (minorVersion < REAPI_VERSION_MINOR)
{
new temp[512];
formatex(temp, sizeof temp - 1, "[ReAPI]: Api minor version mismatch; expected at least %d, real %d", REAPI_VERSION_MINOR, minorVersion);
set_fail_state(temp);
return;
}
}
#define ZC_JANUS7      1
#define ZC_PLASMA      2
#define ZC_THUNDERBOLT 3
#define ZC_ETHEREAL    4
#define ZC_SALAMANDER  5
#define ZC_BOW         6
#define ZC_DRAGONSWORD 7
#define ZC_KATANA      8
#define ZC_LIGHTSABER  9
#define ZC_HORSEAXE    10
#define ZC_HEV         11
#define ZC_JETPACK     12
#define ZC_MINIGUN     13
enum { ZCOP_give = 0, ZCOP_has, ZCOP_remove, ZCOP_infected };
#define ZC_MODS 14
new bool:g_bZcOn[ZC_MODS];
new bool:g_zcGuardFail;
new Trie:g_tZcModelsReady = Invalid_Trie;
new g_zcCurMod = -1;
new g_pZcRewrite;
#define ZC_TOFF_JAN 0x1000000
#define ZC_TOFF_PLA 0x2000000
#define ZC_TOFF_THB 0x3000000
#define ZC_TOFF_ETH 0x4000000
#define ZC_TOFF_SAL 0x5000000
#define ZC_TOFF_BOW 0x6000000
#define ZC_TOFF_DRS 0x7000000
#define ZC_TOFF_KAT 0x8000000
#define ZC_TOFF_LSB 0x9000000
#define ZC_TOFF_HAX 0xA000000
#define ZC_TOFF_HEV 0xB000000
#define ZC_TOFF_JET 0xC000000
#define ZC_TOFF_MGN 0xD000000
#define ZC_TOFF_DIAG 0xE000000
enum { ZCFM_CmdStart, ZCFM_EmitSound, ZCFM_PlaybackEvent, ZCFM_PlayerPreThink, ZCFM_SetModel, ZCFM_TraceHull, ZCFM_TraceLine, ZCFM_UpdateClientData_P, ZCFM_COUNT };
new g_zcFm[ZCFM_COUNT], g_zcEvCurWeapon;
stock bool:VexGuardFatal(const scope[], const path[])
{
if(equal(scope,"vexmira_core")) return false;
return containi(path,".mdl")!=-1 || containi(path,".spr")!=-1;
}
stock bool:VexAssetGuard(const scope[])
{
new required[192],sample[4];
if(equal(scope,"vx42_salamander")) {
static const paths[][]={
"models/p_salamander.mdl",
"models/v_salamander.mdl",
"models/w_salamander.mdl",
"sound/weapons/flamegun-1.wav",
"sound/weapons/flamegun_clipin1.wav",
"sound/weapons/flamegun_clipin2.wav",
"sound/weapons/flamegun_clipout1.wav",
"sound/weapons/flamegun_clipout2.wav",
"sound/weapons/flamegun_draw.wav",
"sprites/vex_community/salamander/640hud59_2.spr",
"sprites/vex_community/salamander/640hud60_2.spr",
"sprites/vex_community/salamander/640hud7_2.spr",
"sprites/vex_community/salamander/flame_burn01.spr",
"sprites/vex_community/salamander/flame_puff01.spr",
"sprites/weapon_flamethrower.txt"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vx42_janus7")) {
static const paths[][]={
"models/p_janus7.mdl",
"models/v_janus7.mdl",
"models/w_janus7.mdl",
"sound/weapons/change1_ready.wav",
"sound/weapons/janus7_change1.wav",
"sound/weapons/janus7_change2.wav",
"sound/weapons/janus7_shoot.wav",
"sound/weapons/janus7_shoot2.wav",
"sound/weapons/mg3_clipin.wav",
"sound/weapons/mg3_clipout.wav",
"sound/weapons/mg3_close.wav",
"sound/weapons/mg3_open.wav",
"sprites/vex_community/janus7/640hud12_2.spr",
"sprites/vex_community/janus7/640hud7_2.spr",
"sprites/vex_community/janus7/640hud99_2.spr",
"sprites/weapon_janus7.txt"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vx42_hev")) {
static const paths[][]={
"models/hev_weapons/p_wrench.mdl",
"models/hev_weapons/v_ak47.mdl",
"models/hev_weapons/v_aug.mdl",
"models/hev_weapons/v_awp.mdl",
"models/hev_weapons/v_deagle.mdl",
"models/hev_weapons/v_famas.mdl",
"models/hev_weapons/v_g3sg1.mdl",
"models/hev_weapons/v_galil.mdl",
"models/hev_weapons/v_glock18.mdl",
"models/hev_weapons/v_m249.mdl",
"models/hev_weapons/v_m3.mdl",
"models/hev_weapons/v_m4a1.mdl",
"models/hev_weapons/v_mp5.mdl",
"models/hev_weapons/v_p228.mdl",
"models/hev_weapons/v_p90.mdl",
"models/hev_weapons/v_sg550.mdl",
"models/hev_weapons/v_tmp.mdl",
"models/hev_weapons/v_ump45.mdl",
"models/hev_weapons/v_usp.mdl",
"models/hev_weapons/v_wrench.mdl",
"models/hev_weapons/v_xm1014.mdl",
"models/player/hev_zombie/hev_zombie.mdl",
"models/v_hev.mdl",
"models/v_hev_adrenaline_injector.mdl",
"models/v_hev_zombie.mdl",
"sound/Zombi/Zombi_Female_Headdown.wav",
"sound/Zombi/Zombi_Female_Headup.wav",
"sound/Zombi/Zombi_Female_Laugh.wav",
"sound/fvox/flatline.wav",
"sound/fvox/health_critical.wav",
"sound/fvox/hevSuit_get_infected_alert2.wav",
"sound/fvox/hev_logon.wav",
"sound/fvox/morphine_shot.wav",
"sound/fvox/power_restored.wav",
"sound/items/cliprelease1.wav",
"sound/jb_engine_b1/shop/syringe_hit.wav",
"sound/jb_engine_b1/shop/syringe_use.wav",
"sound/player/pl_long_jump_1.wav",
"sound/weapons/G_MZC_MP7_CLIPIN.wav",
"sound/weapons/G_MZC_MP7_CLIPOUT.wav",
"sound/weapons/G_RELOAD_MP7.wav",
"sound/weapons/boltpull1.wav",
"sound/weapons/clipin1.wav",
"sound/weapons/clipout1.wav",
"sound/weapons/de_deploy.wav",
"sound/weapons/g36_boltback.wav",
"sound/weapons/g36_boltforward.wav",
"sound/weapons/g36_draw.wav",
"sound/weapons/g36_magin.wav",
"sound/weapons/g36_magout.wav",
"sound/weapons/movement1.wav",
"sound/weapons/movement2.wav",
"sound/weapons/movement3.wav",
"sound/weapons/null.wav",
"sound/weapons/p345/p345_magin.wav",
"sound/weapons/p345/p345_magout.wav",
"sound/weapons/p345/p345_magplace.wav",
"sound/weapons/p345/p345_slide.wav",
"sound/weapons/slideback1.wav",
"sound/weapons/wrench_deploy.wav",
"sound/weapons/wrench_hit.wav",
"sound/weapons/wrench_hitwall.wav",
"sound/weapons/wrench_slash.wav",
"sound/weapons/wrench_stab.wav"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vx42_ethereal")) {
static const paths[][]={
"models/p_ethereal.mdl",
"models/v_ethereal2.mdl",
"models/w_ethereal.mdl",
"sound/weapons/ethereal-1.wav",
"sound/weapons/ethereal_draw.wav",
"sound/weapons/ethereal_idle1.wav",
"sound/weapons/ethereal_reload.wav",
"sprites/vex_community/ethereal/640hud74_2.spr",
"sprites/vex_community/ethereal/640hud7_2.spr",
"sprites/vex_community/ethereal/muzzleflash7.spr",
"sprites/weapon_ethereal.txt"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vx42_plasma")) {
static const paths[][]={
"models/p_plasmagun.mdl",
"models/v_plasmagun2.mdl",
"models/w_plasmagun.mdl",
"sound/weapons/plasmagun-1.wav",
"sound/weapons/plasmagun_clipin1.wav",
"sound/weapons/plasmagun_clipin2.wav",
"sound/weapons/plasmagun_clipout.wav",
"sound/weapons/plasmagun_draw.wav",
"sound/weapons/plasmagun_exp.wav",
"sound/weapons/plasmagun_idle.wav",
"sprites/vex_community/plasma/640hud3_2.spr",
"sprites/vex_community/plasma/640hud91_2.spr",
"sprites/vex_community/plasma/muzzleflash27.spr",
"sprites/vex_community/plasma/plasmaball.spr",
"sprites/vex_community/plasma/plasmabomb.spr",
"sprites/weapon_plasmagun.txt"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vx42_katana")) {
static const paths[][]={
"models/p_katanad.mdl",
"models/v_katanad.mdl",
"sound/weapons/katanad_draw.wav",
"sound/weapons/katanad_hit1.wav",
"sound/weapons/katanad_hit2.wav",
"sound/weapons/katanad_hitwall.wav",
"sound/weapons/katanad_slash1.wav",
"sound/weapons/katanad_slash2.wav",
"sound/weapons/katanad_slash3.wav",
"sound/weapons/katanad_stab.wav",
"sound/weapons/katanad_stab_miss.wav"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vx42_bow")) {
static const paths[][]={
"models/arrow.mdl",
"models/p_bow.mdl",
"models/p_bow_empty.mdl",
"models/v_bow.mdl",
"models/w_bow.mdl",
"sound/weapons/bow_charge_finish1.wav",
"sound/weapons/bow_charge_shoot1_empty.wav",
"sound/weapons/bow_charge_shoot2.wav",
"sound/weapons/bow_charge_start1.wav",
"sound/weapons/bow_charge_start2.wav",
"sound/weapons/bow_draw.wav",
"sound/weapons/bow_shoot1.wav",
"sprites/vex_community/bow/640hud12_2.spr",
"sprites/vex_community/bow/640hud98_2.spr",
"sprites/weapon_bow.txt"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vx42_lightsaber")) {
static const paths[][]={
"models/p_sfsword_off.mdl",
"models/p_sfsword_on.mdl",
"models/v_sfsword.mdl",
"sound/weapons/sfsword_draw.wav",
"sound/weapons/sfsword_hit1.wav",
"sound/weapons/sfsword_hit2.wav",
"sound/weapons/sfsword_idle.wav",
"sound/weapons/sfsword_midslash1.wav",
"sound/weapons/sfsword_midslash2.wav",
"sound/weapons/sfsword_midslash3.wav",
"sound/weapons/sfsword_off.wav",
"sound/weapons/sfsword_off_hit.wav",
"sound/weapons/sfsword_off_slash1.wav",
"sound/weapons/sfsword_on.wav",
"sound/weapons/sfsword_stab.wav",
"sound/weapons/sfsword_wall1.wav",
"sound/weapons/sfsword_wall2.wav"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vx42_minigun")) {
static const paths[][]={
"models/p_m134x.mdl",
"models/shell2x.mdl",
"models/shellx.mdl",
"models/v_m134x.mdl",
"models/w_m134x.mdl",
"sound/weapons/m134-1.wav",
"sound/weapons/m134_clipoff.wav",
"sound/weapons/m134_clipon.wav",
"sound/weapons/m134_pinpull.wav",
"sound/weapons/m134_spindown.wav",
"sound/weapons/m134_spinup.wav",
"sprites/640hud26_2.spr",
"sprites/640hud35_2.spr"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vx42_jetpack")) {
static const paths[][]={
"models/vexmira/community/jetpack/p_jetpack.mdl",
"models/vexmira/community/jetpack/rpgrocket.mdl",
"models/vexmira/community/jetpack/v_jetpack.mdl",
"models/vexmira/community/jetpack/w_jetpack.mdl",
"sound/vexmira/community/jetpack/blow.wav",
"sound/vexmira/community/jetpack/fly47.wav",
"sound/vexmira/community/jetpack/rocket.wav",
"sound/vexmira/community/jetpack/travel.wav",
"sound/vexmira/meme/discord.wav"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vexmira_core")) {
static const paths[][]={
"models/player/vex_gign/vex_gign.mdl",
"models/player/vex_gsg9/vex_gsg9.mdl",
"models/player/vex_halo/vex_halo.mdl",
"models/player/vex_halo/vex_haloT.mdl",
"models/player/vex_soldier/vex_soldier.mdl",
"models/player/vex_spetsnaz/vex_spetsnaz.mdl",
"models/vexmira/community/knives/v_butterfly.mdl",
"models/vexmira_ze/skins/vexmira_p_ak47.mdl",
"models/vexmira_ze/skins/vexmira_p_aug.mdl",
"models/vexmira_ze/skins/vexmira_p_awp.mdl",
"models/vexmira/community/normal/p_c4.mdl",
"models/vexmira_ze/skins/vexmira_p_deagle.mdl",
"models/vexmira_ze/skins/vexmira_p_elite.mdl",
"models/vexmira_ze/skins/vexmira_p_famas.mdl",
"models/vexmira_ze/skins/vexmira_p_fiveseven.mdl",
"models/vexmira/community/normal/p_flashbang.mdl",
"models/vexmira_ze/skins/vexmira_p_g3sg1.mdl",
"models/vexmira/community/normal/p_galil.mdl",
"models/vexmira_ze/skins/vexmira_p_glock18.mdl",
"models/vexmira/community/normal/p_hegrenade.mdl",
"models/vexmira/community/normal/p_knife.mdl",
"models/vexmira_ze/skins/vexmira_p_m249.mdl",
"models/vexmira_ze/skins/vexmira_p_m3.mdl",
"models/vexmira_ze/skins/vexmira_p_m4a1.mdl",
"models/vexmira_ze/skins/vexmira_p_mac10.mdl",
"models/vexmira_ze/skins/vexmira_p_mp5.mdl",
"models/vexmira_ze/skins/vexmira_p_p228.mdl",
"models/vexmira_ze/skins/vexmira_p_p90.mdl",
"models/vexmira_ze/skins/vexmira_p_scout.mdl",
"models/vexmira_ze/skins/vexmira_p_sg550.mdl",
"models/vexmira_ze/skins/vexmira_p_sg552.mdl",
"models/vexmira/community/normal/p_smokegrenade.mdl",
"models/vexmira_ze/skins/vexmira_p_tmp.mdl",
"models/vexmira_ze/skins/vexmira_p_ump45.mdl",
"models/vexmira_ze/skins/vexmira_p_usp.mdl",
"models/vexmira_ze/skins/vexmira_p_xm1014.mdl",
"models/vexmira_ze/skins/vexmira_v_ak47.mdl",
"models/vexmira_ze/skins/vexmira_v_aug.mdl",
"models/vexmira_ze/skins/vexmira_v_awp.mdl",
"models/vexmira_ze/skins/vexmira_v_deagle.mdl",
"models/vexmira/community/normal/v_galil.mdl",
"models/vexmira/community/normal/v_knife.mdl",
"models/vexmira_ze/skins/vexmira_v_m249.mdl",
"models/vexmira_ze/skins/vexmira_v_m4a1.mdl",
"models/vexmira_ze/skins/vexmira_v_mp5.mdl",
"models/vexmira_ze/skins/vexmira_v_sg550.mdl",
"models/vexmira_ze/skins/vexmira_v_sg552.mdl",
"models/vexmira_ze/skins/vexmira_v_xm1014.mdl",
"models/vexmira_ze/skins/vexmira_w_ak47.mdl",
"models/vexmira_ze/skins/vexmira_w_aug.mdl",
"models/vexmira_ze/skins/vexmira_w_awp.mdl",
"models/vexmira/community/normal/w_backpack.mdl",
"models/vexmira/community/normal/w_c4.mdl",
"models/vexmira_ze/skins/vexmira_w_deagle.mdl",
"models/vexmira_ze/skins/vexmira_w_elite.mdl",
"models/vexmira_ze/skins/vexmira_w_famas.mdl",
"models/vexmira_ze/skins/vexmira_w_fiveseven.mdl",
"models/vexmira/community/normal/w_flashbang.mdl",
"models/vexmira_ze/skins/vexmira_w_g3sg1.mdl",
"models/vexmira/community/normal/w_galil.mdl",
"models/vexmira_ze/skins/vexmira_w_glock18.mdl",
"models/vexmira/community/normal/w_hegrenade.mdl",
"models/vexmira/community/normal/w_knife.mdl",
"models/vexmira_ze/skins/vexmira_w_m249.mdl",
"models/vexmira_ze/skins/vexmira_w_m3.mdl",
"models/vexmira_ze/skins/vexmira_w_m4a1.mdl",
"models/vexmira_ze/skins/vexmira_w_mac10.mdl",
"models/vexmira_ze/skins/vexmira_w_mp5.mdl",
"models/vexmira_ze/skins/vexmira_w_p228.mdl",
"models/vexmira_ze/skins/vexmira_w_p90.mdl",
"models/vexmira_ze/skins/vexmira_w_scout.mdl",
"models/vexmira_ze/skins/vexmira_w_sg550.mdl",
"models/vexmira_ze/skins/vexmira_w_sg552.mdl",
"models/vexmira/community/normal/w_shield.mdl",
"models/vexmira/community/normal/w_smokegrenade.mdl",
"models/vexmira_ze/skins/vexmira_w_tmp.mdl",
"models/vexmira_ze/skins/vexmira_w_ump45.mdl",
"models/vexmira_ze/skins/vexmira_w_usp.mdl",
"models/vexmira_ze/skins/vexmira_w_xm1014.mdl",
"models/zombie_plague/v_grenade_infect.mdl"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vx42_dragonsword")) {
static const paths[][]={
"models/p_dragonsword.mdl",
"models/v_dragonsword2.mdl",
"sound/weapons/dragonsword_draw.wav",
"sound/weapons/dragonsword_hit1.wav",
"sound/weapons/dragonsword_hit2.wav",
"sound/weapons/dragonsword_idle.wav",
"sound/weapons/dragonsword_slash1.wav",
"sound/weapons/dragonsword_slash2.wav",
"sound/weapons/dragonsword_stab.wav",
"sound/weapons/dragonsword_stab_hit.wav",
"sound/weapons/dragonsword_wall.wav"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vx42_thunderbolt")) {
static const paths[][]={
"models/p_sfsniper.mdl",
"models/v_sfsightB.mdl",
"models/v_sfsightR.mdl",
"models/v_sfsniperF.mdl",
"models/w_sfsniper.mdl",
"sound/weapons/sfsniper-1.wav",
"sound/weapons/sfsniper_draw.wav",
"sound/weapons/sfsniper_idle.wav",
"sound/weapons/sfsniper_insight1.wav",
"sound/weapons/sfsniper_zoom.wav",
"sprites/vex_community/thunderbolt/640hud10_2.spr",
"sprites/vex_community/thunderbolt/640hud2_2.spr",
"sprites/vex_community/thunderbolt/640hud81_2.spr",
"sprites/weapon_sfsniperF.txt"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
if(equal(scope,"vx42_horseaxe")) {
static const paths[][]={
"models/p_horseaxe.mdl",
"models/v_horseaxe.mdl",
"sound/weapons/tomahawk_draw.wav",
"sound/weapons/tomahawk_slash1.wav",
"sound/weapons/tomahawk_slash1_hit.wav",
"sound/weapons/tomahawk_slash2.wav",
"sound/weapons/tomahawk_slash2_hit.wav",
"sound/weapons/tomahawk_stab_hit.wav",
"sound/weapons/tomahawk_stab_miss.wav",
"sound/weapons/tomahawk_wall.wav"
};
for(new i=0;i<sizeof paths;i++) {
if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
}
if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
new fp=fopen(paths[i],"rb"); if(!fp) continue;
fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
(containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
(sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",required,scope); g_zcGuardFail=true; return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
}
}
}
return true;
}
stock VexPcSnd(const s[], bool:emitted)
{
if (emitted) { ZcPcSound(s); return; }
new f[128]; formatex(f, charsmax(f), "sound/%s", s);
if (file_exists(f, true)) (!VxPcOk531()) ? 0 : precache_generic(f);
}
#define VERSION "5.3.1-Stable"
native vx47_jetgauge(id,percent,fuel);
native vx45_corezombie(id);
native vx45_coreweapon(id);
native vx45_corerestore(id);
native vx45_corepreparejet(id);
native vx45_coresurvivor(id);
native vx45_corejetpack(id);
bool:CommunityLegacyFileOk(const path[])
{
new fp=fopen(path,"rb",true); if(!fp) return false;
new magic,version,bytes,stored,textures,groups;
fread(fp,magic,BLOCK_INT); fread(fp,version,BLOCK_INT);
fseek(fp,0,SEEK_END); bytes=ftell(fp);
if(containi(path,".mdl")!=-1) {
if(magic!=0x54534449 || version!=10 || bytes<244) { fclose(fp); return false; }
fseek(fp,72,SEEK_SET); fread(fp,stored,BLOCK_INT);
fseek(fp,172,SEEK_SET); fread(fp,groups,BLOCK_INT);
fseek(fp,180,SEEK_SET); fread(fp,textures,BLOCK_INT); fclose(fp);
if(stored>bytes || stored<244 || groups<1 || groups>32) return false;
new sibling[192],base[160]; copy(base,charsmax(base),path); base[strlen(base)-4]=0;
if(!textures) { formatex(sibling,charsmax(sibling),"%sT.mdl",base); if(!file_exists(sibling,true)) return false; }
for(new n=1;n<groups;n++) { formatex(sibling,charsmax(sibling),"%s%02d.mdl",base,n); if(!file_exists(sibling,true)) return false; }
return true;
}
fclose(fp);
if(containi(path,".spr")!=-1) return magic==0x50534449 && version==2 && bytes>42;
if(containi(path,".wav")!=-1) return magic==0x46464952 && bytes>44;
return bytes>0;
}
#define jan_PLUGIN "[CSO] Weapon: JANUS-VII"
#define jan_VERSION "1.0"
#define jan_AUTHOR "Dias Pendragon"
#define jan_DAMAGE_A 40
#define jan_DAMAGE_B 80
#define jan_CHARGE_AMMO 57
#define jan_CHARGE_LIMITTIME 7
#define jan_CHARGE_TIME 15
#define jan_CLIP 100
#define jan_CHANGE_TIME 2.0
#define jan_LIGHTNING_RANGE 500.0
#define jan_LIGHTNING_HEADSHOTABLE 1
#define jan_CSW_JANUS7 CSW_M249
#define jan_weapon_janus7 "weapon_m249"
#define jan_PLAYER_ANIMEXT "m249"
#define jan_Janus7_OLDMODEL "models/vexmira_ze/skins/vexmira_w_m249.mdl"
#define jan_V_MODEL "models/v_janus7.mdl"
#define jan_P_MODEL "models/p_janus7.mdl"
#define jan_W_MODEL "models/w_janus7.mdl"
#define jan_TASK_CHANGE 42343
#define jan_TASK_CHANGELIMITTIME 54364
#define jan_TASK_USETIME 34647
new const jan_Janus7_Sounds[9][] =
{
"weapons/janus7_shoot.wav",
"weapons/janus7_shoot2.wav",
"weapons/change1_ready.wav",
"weapons/mg3_open.wav",
"weapons/mg3_clipin.wav",
"weapons/mg3_clipout.wav",
"weapons/mg3_close.wav",
"weapons/janus7_change1.wav",
"weapons/janus7_change2.wav"
}
new const jan_Janus7_Resources[4][] =
{
"sprites/weapon_janus7.txt",
"sprites/vex_community/janus7/640hud7_2.spr",
"sprites/vex_community/janus7/640hud12_2.spr",
"sprites/vex_community/janus7/640hud99_2.spr"
}
enum
{
jan_J7_ANIM_IDLE = 0,
jan_J7_ANIM_RELOAD,
jan_J7_ANIM_DRAW,
jan_J7_ANIM_SHOOT1,
jan_J7_ANIM_SHOOT1_2,
jan_J7_ANIM_SHOOT1_ACTIVE,
jan_J7_ANIM_CHANGE_TO_JANUS,
jan_J7_ANIM_IDLE_JANUS,
jan_J7_ANIM_DRAW_JANUS,
jan_J7_ANIM_SHOOT1_JANUS,
jan_J7_ANIM_SHOOT2_JANUS,
jan_J7_ANIM_CHANGE_TO_BACK,
jan_J7_ANIM_IDLE_ACTIVE,
jan_J7_ANIM_RELOAD_ACTIVE,
jan_J7_ANIM_DRAW_ACTIVE
}
enum
{
jan_Janus7_NORMAL = 0,
jan_Janus7_ACTIVE,
jan_Janus7_JANUS
}
#define jan_Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define jan_Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define jan_UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
const jan_PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const jan_SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
new jan_g_Had_Janus7, jan_g_Janus7_Mode[33], jan_g_Janus7_Clip[33], jan_g_BulletCount[33], jan_g_ChangingMode, Float:jan_EmitSoundTime[33]
new jan_g_Event_Janus7, jan_g_Msg_WeaponList, jan_g_SmokePuff_SprId, jan_g_RifleShell_Id, jan_g_ham_bot, jan_g_SprId, jan_g_MaxPlayers
new bool:jan_g_VexGiving[33];
public jan_plugin_init()
{
g_zcFm[ZCFM_UpdateClientData_P] |= (1<<0)
g_zcFm[ZCFM_PlaybackEvent] |= (1<<0)
g_zcFm[ZCFM_SetModel] |= (1<<0)
g_zcFm[ZCFM_CmdStart] |= (1<<0)
VxRegisterHam524(Ham_Weapon_WeaponIdle, jan_weapon_janus7, "jan_fw_Weapon_WeaponIdle_Post", 1)
VxRegisterHam524(Ham_Item_Deploy, jan_weapon_janus7, "jan_fw_Item_Deploy_Post", 1)
VxRegisterHam524(Ham_Item_AddToPlayer, jan_weapon_janus7, "jan_fw_Item_AddToPlayer_Post", 1)
VxRegisterHam524(Ham_Item_PostFrame, jan_weapon_janus7, "jan_fw_Item_PostFrame")
VxRegisterHam524(Ham_Weapon_Reload, jan_weapon_janus7, "jan_fw_Weapon_Reload")
VxRegisterHam524(Ham_Weapon_Reload, jan_weapon_janus7, "jan_fw_Weapon_Reload_Post", 1)
VxRegisterHam524(Ham_TraceAttack, "worldspawn", "jan_fw_TraceAttack_World")
VxRegisterHam524(Ham_TraceAttack, "player", "jan_fw_TraceAttack_Player")
jan_g_Msg_WeaponList = get_user_msgid("WeaponList")
jan_g_MaxPlayers = get_maxplayers()
register_clcmd("weapon_janus7", "jan_Hook_Weapon")
}
public jan_plugin_precache()
{
if (!VexAssetGuard("vx42_janus7")) return;
ZcPcModel(jan_V_MODEL)
ZcPcModel(jan_P_MODEL)
ZcPcModel(jan_W_MODEL)
new i
for(i = 0; i < sizeof(jan_Janus7_Sounds); i++)
VexPcSnd(jan_Janus7_Sounds[i], (i==0||i==1||i==2||i==8) ? true : false)
for(i = 0; i < sizeof(jan_Janus7_Resources); i++)
{
if(i == 0) ZcPcGeneric(jan_Janus7_Resources[i])
else ZcPcModel(jan_Janus7_Resources[i])
}
jan_g_RifleShell_Id = ZcPcModel("models/rshell.mdl")
jan_g_SmokePuff_SprId = ZcPcModel("sprites/wall_puff1.spr")
jan_g_SprId = ZcPcModel( "sprites/lgtning.spr" )
register_forward(FM_PrecacheEvent, "jan_fw_PrecacheEvent_Post", 1)
}
public jan_fw_PrecacheEvent_Post(type, const name[])
{
if(equal("events/m249.sc", name)) jan_g_Event_Janus7 = get_orig_retval()
}
public jan_client_putinserver(id)
{
if(!jan_g_ham_bot && is_user_bot(id))
{
jan_g_ham_bot = 1
set_task(0.1, "jan_Do_Register_HamBot", (id) + ZC_TOFF_JAN)
}
}
public jan_Do_Register_HamBot(id)
{ if (id >= ZC_TOFF_JAN && id < ZC_TOFF_JAN + 0x1000000) id -= ZC_TOFF_JAN;
RegisterHamFromEntity(Ham_TraceAttack, id, "jan_fw_TraceAttack_Player")
}
public jan_Get_Janus7(id)
{
if(!is_user_alive(id))
return
jan_drop_weapons(id, 1)
jan_g_Janus7_Mode[id] = jan_Janus7_NORMAL
jan_g_BulletCount[id] = 0
jan_Set_BitVar(jan_g_Had_Janus7, id)
jan_UnSet_BitVar(jan_g_ChangingMode, id)
fm_give_item(id, jan_weapon_janus7)
jan_Give_RealAmmo(id, jan_CSW_JANUS7)
engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
write_byte(1)
write_byte(jan_CSW_JANUS7)
write_byte(jan_CLIP)
message_end()
}
public jan_Remove_Janus7(id)
{
jan_g_Janus7_Mode[id] = jan_Janus7_NORMAL
jan_g_BulletCount[id] = 0
jan_UnSet_BitVar(jan_g_Had_Janus7, id)
jan_UnSet_BitVar(jan_g_ChangingMode, id)
remove_task( (id+jan_TASK_CHANGE) + ZC_TOFF_JAN)
remove_task( (id+jan_TASK_CHANGELIMITTIME) + ZC_TOFF_JAN)
remove_task( (id+jan_TASK_USETIME) + ZC_TOFF_JAN)
}
public jan_Hook_Weapon(id)
{
engclient_cmd(id, jan_weapon_janus7)
return PLUGIN_HANDLED
}
public jan_fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
if(!is_user_alive(id) || !is_user_connected(id))
return FMRES_IGNORED
if(get_user_weapon(id) == jan_CSW_JANUS7 && jan_Get_BitVar(jan_g_Had_Janus7, id))
set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001)
return FMRES_HANDLED
}
public jan_fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, jan_iParam1, jan_iParam2, jan_bParam1, jan_bParam2)
{
if (!is_user_connected(invoker))
return FMRES_IGNORED
if(get_user_weapon(invoker) != jan_CSW_JANUS7 || !jan_Get_BitVar(jan_g_Had_Janus7, invoker))
return FMRES_IGNORED
if(eventid != jan_g_Event_Janus7)
return FMRES_IGNORED
engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, jan_iParam1, jan_iParam2, jan_bParam1, jan_bParam2)
if(jan_g_Janus7_Mode[invoker] == jan_Janus7_NORMAL) jan_set_weapon_anim(invoker, jan_J7_ANIM_SHOOT1)
else if(jan_g_Janus7_Mode[invoker] == jan_Janus7_ACTIVE) jan_set_weapon_anim(invoker, jan_J7_ANIM_SHOOT1_ACTIVE)
else if(jan_g_Janus7_Mode[invoker] == jan_Janus7_JANUS) jan_set_weapon_anim(invoker, random_num(jan_J7_ANIM_SHOOT1_JANUS, jan_J7_ANIM_SHOOT2_JANUS))
emit_sound(invoker, CHAN_WEAPON, jan_g_Janus7_Mode[invoker] == jan_Janus7_JANUS ? jan_Janus7_Sounds[1] : jan_Janus7_Sounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
jan_Eject_Shell(invoker, jan_g_RifleShell_Id, 0.01)
static jan_Ent; jan_Ent = fm_find_ent_by_owner(-1, jan_weapon_janus7, invoker)
if(pev_valid(jan_Ent) && jan_g_Janus7_Mode[invoker] == jan_Janus7_JANUS) cs_set_weapon_ammo(jan_Ent, cs_get_weapon_ammo(jan_Ent) + 1)
return FMRES_IGNORED
}
public jan_fw_SetModel(entity, model[])
{
if(!pev_valid(entity))
return FMRES_IGNORED
static Classname[32]
pev(entity, pev_classname, Classname, sizeof(Classname))
if(!equal(Classname, "weaponbox"))
return FMRES_IGNORED
static iOwner
iOwner = pev(entity, pev_owner)
if(equal(model, jan_Janus7_OLDMODEL))
{
static weapon; weapon = fm_find_ent_by_owner(-1, jan_weapon_janus7, entity)
if(!pev_valid(weapon))
return FMRES_IGNORED;
if(jan_Get_BitVar(jan_g_Had_Janus7, iOwner))
{
jan_Remove_Janus7(iOwner)
set_pev(weapon, pev_impulse, 11012014)
VxSM(entity, jan_W_MODEL)
return FMRES_SUPERCEDE
}
}
return FMRES_IGNORED;
}
public jan_fw_CmdStart(id, uc_handle, seed)
{
if(!is_user_alive(id))
return FMRES_IGNORED
if(!jan_Get_BitVar(jan_g_Had_Janus7, id) || get_user_weapon(id) != jan_CSW_JANUS7)
return FMRES_IGNORED
static jan_PressButton; jan_PressButton = get_uc(uc_handle, UC_Buttons)
if((jan_PressButton & IN_ATTACK) && jan_g_Janus7_Mode[id] == jan_Janus7_JANUS && !jan_Get_BitVar(jan_g_ChangingMode, id))
{
jan_PressButton &= ~IN_ATTACK
set_uc(uc_handle, UC_Buttons, jan_PressButton)
if(get_gametime() - 3.0 > jan_EmitSoundTime[id])
{
emit_sound(id, CHAN_WEAPON, jan_Janus7_Sounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
jan_EmitSoundTime[id] = get_gametime()
}
if(get_pdata_float(id, 83, 5) > 0.0)
return FMRES_IGNORED
jan_set_weapon_anim(id, jan_J7_ANIM_SHOOT1_JANUS)
jan_Make_ShootEffect(id)
jan_Janus7_Lighting(id)
set_pdata_float(id, 83, 0.075, 5)
return FMRES_IGNORED
}
if((jan_PressButton & IN_RELOAD) && jan_g_Janus7_Mode[id] == jan_Janus7_JANUS)
return FMRES_SUPERCEDE
if((jan_PressButton & IN_ATTACK2))
{
jan_PressButton &= ~IN_ATTACK2
set_uc(uc_handle, UC_Buttons, jan_PressButton)
if((pev(id, pev_oldbuttons) & IN_ATTACK2))
return FMRES_IGNORED
if(jan_g_Janus7_Mode[id] != jan_Janus7_ACTIVE)
return FMRES_IGNORED
if(get_pdata_float(id, 83, 5) > 0.0)
return FMRES_IGNORED
remove_task( (id+jan_TASK_CHANGELIMITTIME) + ZC_TOFF_JAN)
jan_Set_BitVar(jan_g_ChangingMode, id)
jan_Set_Player_NextAttack(id, jan_CSW_JANUS7, jan_CHANGE_TIME)
jan_set_weapon_anim(id, jan_J7_ANIM_CHANGE_TO_JANUS)
set_task(jan_CHANGE_TIME, "jan_ChangeTo_JanusTransform", (id+jan_TASK_CHANGE) + ZC_TOFF_JAN)
}
return FMRES_IGNORED
}
public jan_Make_ShootEffect(id)
{
static Float:Angles[3]
pev(id, pev_punchangle, Angles)
Angles[0] += random_float(-1.5, 0.0)
Angles[1] += random_float(-0.75, 0.75)
set_pev(id, pev_punchangle, Angles)
}
public jan_Janus7_Lighting(id)
{
static Float:jan_TargetOrigin[3], Float:Origin[3], jan_NearestId, Float:jan_Range, Float:jan_MyOrigin[3]
fm_get_aim_origin(id, jan_TargetOrigin)
jan_Range = 4096.0
jan_NearestId = 0
pev(id, pev_origin, jan_MyOrigin)
for(new i = 1; i <= jan_g_MaxPlayers; i++)
{
if(!is_user_alive(i))
continue
if(cs_get_user_team(id) == cs_get_user_team(i))
continue
if(entity_range(id, i) > jan_LIGHTNING_RANGE)
continue
pev(i, pev_origin, Origin)
if(jan_is_wall_between_points(jan_MyOrigin, Origin, id))
continue
if(!is_in_viewcone(id, Origin))
continue
if(entity_range(id, i) <= jan_Range)
{
jan_NearestId = i
jan_Range = entity_range(id, i)
}
}
if(is_user_alive(jan_NearestId))
{
pev(jan_NearestId, pev_origin, jan_TargetOrigin)
static jan_TakeDamage; jan_TakeDamage = jan_LIGHTNING_HEADSHOTABLE
if(!jan_TakeDamage) ExecuteHamB(Ham_TakeDamage, jan_NearestId, 0, id, float(jan_DAMAGE_B), DMG_BLAST)
else jan_do_attack(id, jan_NearestId, 0, float(jan_DAMAGE_B))
}
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_BEAMENTPOINT)
write_short(id | 0x1000)
engfunc(EngFunc_WriteCoord, jan_TargetOrigin[0])
engfunc(EngFunc_WriteCoord, jan_TargetOrigin[1])
engfunc(EngFunc_WriteCoord, jan_TargetOrigin[2])
write_short(jan_g_SprId)
write_byte(0)
write_byte(0)
write_byte(1)
write_byte(30)
write_byte(15)
write_byte(255)
write_byte(170)
write_byte(0)
write_byte(255)
write_byte(25)
message_end()
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_BEAMENTPOINT)
write_short(id | 0x1000)
engfunc(EngFunc_WriteCoord, jan_TargetOrigin[0])
engfunc(EngFunc_WriteCoord, jan_TargetOrigin[1])
engfunc(EngFunc_WriteCoord, jan_TargetOrigin[2])
write_short(jan_g_SprId)
write_byte(0)
write_byte(0)
write_byte(1)
write_byte(20)
write_byte(50)
write_byte(250)
write_byte(250)
write_byte(0)
write_byte(255)
write_byte(25)
message_end()
}
public jan_ChangeTo_JanusTransform(id)
{ if (id >= ZC_TOFF_JAN && id < ZC_TOFF_JAN + 0x1000000) id -= ZC_TOFF_JAN;
id -= jan_TASK_CHANGE
if(!is_user_alive(id))
return
if(get_user_weapon(id) != jan_CSW_JANUS7 || !jan_Get_BitVar(jan_g_Had_Janus7, id))
return
if(!jan_Get_BitVar(jan_g_ChangingMode, id))
return
jan_UnSet_BitVar(jan_g_ChangingMode, id)
jan_g_Janus7_Mode[id] = jan_Janus7_JANUS
jan_set_weapon_anim(id, jan_J7_ANIM_IDLE_JANUS)
remove_task( (id+jan_TASK_USETIME) + ZC_TOFF_JAN)
set_task(float(jan_CHARGE_TIME), "jan_TurnOff_JTS2", (id+jan_TASK_USETIME) + ZC_TOFF_JAN)
}
public jan_TurnOff_JTS2(id)
{ if (id >= ZC_TOFF_JAN && id < ZC_TOFF_JAN + 0x1000000) id -= ZC_TOFF_JAN;
id -= jan_TASK_USETIME
if(!is_user_alive(id))
return
jan_g_Janus7_Mode[id] = jan_Janus7_NORMAL
if(get_user_weapon(id) != jan_CSW_JANUS7 || !jan_Get_BitVar(jan_g_Had_Janus7, id))
return
if(jan_g_Janus7_Mode[id] != jan_Janus7_JANUS)
return
jan_Set_BitVar(jan_g_ChangingMode, id)
jan_Set_Player_NextAttack(id, jan_CSW_JANUS7, jan_CHANGE_TIME - 1.0)
jan_set_weapon_anim(id, jan_J7_ANIM_CHANGE_TO_BACK)
emit_sound(id, CHAN_WEAPON, jan_Janus7_Sounds[8], 1.0, ATTN_NORM, 0, PITCH_NORM)
set_task(jan_CHANGE_TIME - 1.0, "jan_ChangeTo_Back", (id+jan_TASK_CHANGE) + ZC_TOFF_JAN)
}
public jan_ChangeTo_Back(id)
{ if (id >= ZC_TOFF_JAN && id < ZC_TOFF_JAN + 0x1000000) id -= ZC_TOFF_JAN;
id -= jan_TASK_CHANGE
if(!is_user_alive(id))
return
jan_g_Janus7_Mode[id] = jan_Janus7_NORMAL
if(get_user_weapon(id) != jan_CSW_JANUS7 || !jan_Get_BitVar(jan_g_Had_Janus7, id))
return
if(jan_g_Janus7_Mode[id] != jan_Janus7_JANUS)
return
jan_g_Janus7_Mode[id] = jan_Janus7_NORMAL
}
public jan_fw_Weapon_WeaponIdle_Post(jan_Ent)
{
if(pev_valid(jan_Ent) != 2)
return HAM_IGNORED
static jan_Id; jan_Id = get_pdata_cbase(jan_Ent, 41, 4)
if(get_pdata_cbase(jan_Id, 373) != jan_Ent)
return HAM_IGNORED
if(!jan_Get_BitVar(jan_g_Had_Janus7, jan_Id))
return HAM_IGNORED
if(get_pdata_float(jan_Ent, 48, 4) <= 0.1)
{
if(jan_g_Janus7_Mode[jan_Id] == jan_Janus7_NORMAL) jan_set_weapon_anim(jan_Id, jan_J7_ANIM_IDLE)
else if(jan_g_Janus7_Mode[jan_Id] == jan_Janus7_ACTIVE) jan_set_weapon_anim(jan_Id, jan_J7_ANIM_IDLE_ACTIVE)
else if(jan_g_Janus7_Mode[jan_Id] == jan_Janus7_JANUS) jan_set_weapon_anim(jan_Id, jan_J7_ANIM_IDLE_JANUS)
set_pdata_float(jan_Ent, 48, 20.0, 4)
set_pdata_string(jan_Id, (492) * 4, jan_PLAYER_ANIMEXT, -1 , 20)
}
return HAM_IGNORED
}
public jan_fw_Item_Deploy_Post(jan_Ent)
{
if(pev_valid(jan_Ent) != 2)
return
static jan_Id; jan_Id = get_pdata_cbase(jan_Ent, 41, 4)
if(get_pdata_cbase(jan_Id, 373) != jan_Ent)
return
if(!jan_Get_BitVar(jan_g_Had_Janus7, jan_Id))
return
set_pev(jan_Id, pev_viewmodel2, jan_V_MODEL)
set_pev(jan_Id, pev_weaponmodel2, jan_P_MODEL)
if(jan_g_Janus7_Mode[jan_Id] == jan_Janus7_NORMAL) jan_set_weapon_anim(jan_Id, jan_J7_ANIM_DRAW)
else if(jan_g_Janus7_Mode[jan_Id] == jan_Janus7_ACTIVE) jan_set_weapon_anim(jan_Id, jan_J7_ANIM_DRAW_ACTIVE)
else if(jan_g_Janus7_Mode[jan_Id] == jan_Janus7_JANUS) jan_set_weapon_anim(jan_Id, jan_J7_ANIM_DRAW_JANUS)
}
public jan_fw_Item_AddToPlayer_Post(jan_Ent, id)
{
if(id>=1 && id<=32 && !jan_g_VexGiving[id]) jan_UnSet_BitVar(jan_g_Had_Janus7, id);
if(id<1 || id>32 || !is_user_connected(id)) return HAM_IGNORED;
if(!pev_valid(jan_Ent))
return HAM_IGNORED
if(pev(jan_Ent, pev_impulse) == 11012014)
{
jan_Set_BitVar(jan_g_Had_Janus7, id)
set_pev(jan_Ent, pev_impulse, 0)
}
message_begin(MSG_ONE_UNRELIABLE, jan_g_Msg_WeaponList, .player = id)
write_string(jan_Get_BitVar(jan_g_Had_Janus7, id) ? "weapon_janus7" : "weapon_m249")
write_byte(3)
write_byte(200)
write_byte(-1)
write_byte(-1)
write_byte(0)
write_byte(4)
write_byte(jan_Get_BitVar(jan_g_Had_Janus7, id) ? jan_CSW_JANUS7 : CSW_M249)
write_byte(0)
message_end()
return HAM_HANDLED
}
public jan_fw_Item_PostFrame(ent)
{
static id; id = pev(ent, pev_owner)
if(!is_user_alive(id))
return HAM_IGNORED
if(!jan_Get_BitVar(jan_g_Had_Janus7, id))
return HAM_IGNORED
static Float:jan_flNextAttack; jan_flNextAttack = get_pdata_float(id, 83, 5)
static jan_bpammo; jan_bpammo = cs_get_user_bpammo(id, jan_CSW_JANUS7)
static jan_iClip; jan_iClip = get_pdata_int(ent, 51, 4)
static jan_fInReload; jan_fInReload = get_pdata_int(ent, 54, 4)
if(jan_fInReload && jan_flNextAttack <= 0.0)
{
static jan_temp1
jan_temp1 = min(jan_CLIP - jan_iClip, jan_bpammo)
set_pdata_int(ent, 51, jan_iClip + jan_temp1, 4)
cs_set_user_bpammo(id, jan_CSW_JANUS7, jan_bpammo - jan_temp1)
set_pdata_int(ent, 54, 0, 4)
jan_fInReload = 0
}
return HAM_IGNORED
}
public jan_fw_Weapon_Reload(ent)
{
static id; id = pev(ent, pev_owner)
if(!is_user_alive(id))
return HAM_IGNORED
if(!jan_Get_BitVar(jan_g_Had_Janus7, id))
return HAM_IGNORED
if(jan_g_Janus7_Mode[id] == jan_Janus7_JANUS)
{
set_pdata_int(ent, 54, 0, 4)
return HAM_SUPERCEDE
}
jan_g_Janus7_Clip[id] = -1
static jan_BPAmmo; jan_BPAmmo = cs_get_user_bpammo(id, jan_CSW_JANUS7)
static jan_iClip; jan_iClip = get_pdata_int(ent, 51, 4)
if(jan_BPAmmo <= 0)
return HAM_SUPERCEDE
if(jan_iClip >= jan_CLIP)
return HAM_SUPERCEDE
jan_g_Janus7_Clip[id] = jan_iClip
return HAM_HANDLED
}
public jan_fw_Weapon_Reload_Post(ent)
{
static id; id = pev(ent, pev_owner)
if(!is_user_alive(id))
return HAM_IGNORED
if(!jan_Get_BitVar(jan_g_Had_Janus7, id))
return HAM_IGNORED
if(jan_g_Janus7_Mode[id] == jan_Janus7_JANUS)
{
set_pdata_int(ent, 54, 0, 4)
return HAM_SUPERCEDE
}
if((get_pdata_int(ent, 54, 4) == 1))
{
if(jan_g_Janus7_Clip[id] == -1)
return HAM_IGNORED
set_pdata_int(ent, 51, jan_g_Janus7_Clip[id], 4)
if(jan_g_Janus7_Mode[id] == jan_Janus7_NORMAL) jan_set_weapon_anim(id, jan_J7_ANIM_RELOAD)
else if(jan_g_Janus7_Mode[id] == jan_Janus7_ACTIVE) jan_set_weapon_anim(id, jan_J7_ANIM_RELOAD_ACTIVE)
}
return HAM_HANDLED
}
public jan_fw_TraceAttack_World(jan_Victim, jan_Attacker, Float:Damage, Float:jan_Direction[3], jan_Ptr, jan_DamageBits)
{
if(!is_user_connected(jan_Attacker))
return HAM_IGNORED
if(get_user_weapon(jan_Attacker) != jan_CSW_JANUS7 || !jan_Get_BitVar(jan_g_Had_Janus7, jan_Attacker))
return HAM_IGNORED
static Float:jan_flEnd[3], Float:jan_vecPlane[3]
get_tr2(jan_Ptr, TR_vecEndPos, jan_flEnd)
get_tr2(jan_Ptr, TR_vecPlaneNormal, jan_vecPlane)
jan_Make_BulletHole(jan_Attacker, jan_flEnd, Damage)
jan_Make_BulletSmoke(jan_Attacker, jan_Ptr)
SetHamParamFloat(3, jan_g_Janus7_Mode[jan_Attacker] == jan_Janus7_JANUS ? float(jan_DAMAGE_B) : float(jan_DAMAGE_A))
if(jan_g_Janus7_Mode[jan_Attacker] == jan_Janus7_NORMAL)
{
jan_g_BulletCount[jan_Attacker]++
jan_CheckCharge(jan_Attacker)
}
return HAM_IGNORED
}
public jan_fw_TraceAttack_Player(jan_Victim, jan_Attacker, Float:Damage, Float:jan_Direction[3], jan_Ptr, jan_DamageBits)
{
if(!is_user_connected(jan_Attacker))
return HAM_IGNORED
if(get_user_weapon(jan_Attacker) != jan_CSW_JANUS7 || !jan_Get_BitVar(jan_g_Had_Janus7, jan_Attacker))
return HAM_IGNORED
SetHamParamFloat(3, jan_g_Janus7_Mode[jan_Attacker] == jan_Janus7_JANUS ? float(jan_DAMAGE_B) : float(jan_DAMAGE_A))
if(cs_get_user_team(jan_Attacker) != cs_get_user_team(jan_Victim) && jan_g_Janus7_Mode[jan_Attacker] == jan_Janus7_NORMAL)
{
jan_g_BulletCount[jan_Attacker]++
jan_CheckCharge(jan_Attacker)
}
return HAM_IGNORED
}
public jan_CheckCharge(id)
{
if(jan_g_BulletCount[id] >= jan_CHARGE_AMMO)
{
jan_g_Janus7_Mode[id] = jan_Janus7_ACTIVE
jan_set_weapon_anim(id, jan_J7_ANIM_IDLE_ACTIVE)
emit_sound(id, CHAN_VOICE, jan_Janus7_Sounds[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
jan_g_BulletCount[id] = 0
remove_task( (id+jan_TASK_CHANGELIMITTIME) + ZC_TOFF_JAN)
set_task(float(jan_CHARGE_LIMITTIME), "jan_TurnOff_JTS", (id+jan_TASK_CHANGELIMITTIME) + ZC_TOFF_JAN)
}
}
public jan_TurnOff_JTS(id)
{ if (id >= ZC_TOFF_JAN && id < ZC_TOFF_JAN + 0x1000000) id -= ZC_TOFF_JAN;
id -= jan_TASK_CHANGELIMITTIME
if(!is_user_alive(id))
return
jan_g_Janus7_Mode[id] = jan_Janus7_NORMAL
jan_g_BulletCount[id] = 0
jan_set_weapon_anim(id, jan_J7_ANIM_IDLE)
}
public jan_Give_RealAmmo(id, jan_CSWID)
{
static jan_Amount, Max
switch(jan_CSWID)
{
case CSW_P228: {jan_Amount = 10; Max = 104;}
case CSW_SCOUT: {jan_Amount = 6; Max = 180;}
case CSW_XM1014: {jan_Amount = 8; Max = 64;}
case CSW_MAC10: {jan_Amount = 16; Max = 200;}
case CSW_AUG: {jan_Amount = 6; Max = 180;}
case CSW_ELITE: {jan_Amount = 16; Max = 200;}
case CSW_FIVESEVEN: {jan_Amount = 4; Max = 200;}
case CSW_UMP45: {jan_Amount = 16; Max = 200;}
case CSW_SG550: {jan_Amount = 6; Max = 180;}
case CSW_GALIL: {jan_Amount = 6; Max = 180;}
case CSW_FAMAS: {jan_Amount = 6; Max = 180;}
case CSW_USP: {jan_Amount = 18; Max = 200;}
case CSW_GLOCK18: {jan_Amount = 16; Max = 200;}
case CSW_AWP: {jan_Amount = 6; Max = 60;}
case CSW_MP5NAVY: {jan_Amount = 16; Max = 200;}
case CSW_M249: {jan_Amount = 4; Max = 200;}
case CSW_M3: {jan_Amount = 8; Max = 64;}
case CSW_M4A1: {jan_Amount = 7; Max = 180;}
case CSW_TMP: {jan_Amount = 7; Max = 200;}
case CSW_G3SG1: {jan_Amount = 7; Max = 180;}
case CSW_DEAGLE: {jan_Amount = 10; Max = 70;}
case CSW_SG552: {jan_Amount = 7; Max = 180;}
case CSW_AK47: {jan_Amount = 7; Max = 180;}
case CSW_P90: {jan_Amount = 4; Max = 200;}
default: {jan_Amount = 3; Max = 200;}
}
for(new i = 0; i < jan_Amount; i++) jan_give_ammo(id, 0, jan_CSWID, Max)
}
public jan_give_ammo(id, jan_silent, jan_CSWID, Max)
{
static jan_Amount, Name[32]
switch(jan_CSWID)
{
case CSW_P228: {jan_Amount = 13; formatex(Name, sizeof(Name), "357sig");}
case CSW_SCOUT: {jan_Amount = 30; formatex(Name, sizeof(Name), "762nato");}
case CSW_XM1014: {jan_Amount = 8; formatex(Name, sizeof(Name), "buckshot");}
case CSW_MAC10: {jan_Amount = 12; formatex(Name, sizeof(Name), "45acp");}
case CSW_AUG: {jan_Amount = 30; formatex(Name, sizeof(Name), "556nato");}
case CSW_ELITE: {jan_Amount = 30; formatex(Name, sizeof(Name), "9mm");}
case CSW_FIVESEVEN: {jan_Amount = 50; formatex(Name, sizeof(Name), "57mm");}
case CSW_UMP45: {jan_Amount = 12; formatex(Name, sizeof(Name), "45acp");}
case CSW_SG550: {jan_Amount = 30; formatex(Name, sizeof(Name), "556nato");}
case CSW_GALIL: {jan_Amount = 30; formatex(Name, sizeof(Name), "556nato");}
case CSW_FAMAS: {jan_Amount = 30; formatex(Name, sizeof(Name), "556nato");}
case CSW_USP: {jan_Amount = 12; formatex(Name, sizeof(Name), "45acp");}
case CSW_GLOCK18: {jan_Amount = 30; formatex(Name, sizeof(Name), "9mm");}
case CSW_AWP: {jan_Amount = 10; formatex(Name, sizeof(Name), "338magnum");}
case CSW_MP5NAVY: {jan_Amount = 30; formatex(Name, sizeof(Name), "9mm");}
case CSW_M249: {jan_Amount = 30; formatex(Name, sizeof(Name), "556natobox");}
case CSW_M3: {jan_Amount = 8; formatex(Name, sizeof(Name), "buckshot");}
case CSW_M4A1: {jan_Amount = 30; formatex(Name, sizeof(Name), "556nato");}
case CSW_TMP: {jan_Amount = 30; formatex(Name, sizeof(Name), "9mm");}
case CSW_G3SG1: {jan_Amount = 30; formatex(Name, sizeof(Name), "762nato");}
case CSW_DEAGLE: {jan_Amount = 7; formatex(Name, sizeof(Name), "50ae");}
case CSW_SG552: {jan_Amount = 30; formatex(Name, sizeof(Name), "556nato");}
case CSW_AK47: {jan_Amount = 30; formatex(Name, sizeof(Name), "762nato");}
case CSW_P90: {jan_Amount = 50; formatex(Name, sizeof(Name), "57mm");}
}
if(!jan_silent) emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
ExecuteHamB(Ham_GiveAmmo, id, jan_Amount, Name, Max)
}
stock jan_Eject_Shell(id, jan_Shell_ModelIndex, Float:jan_Time)
{
static jan_Ent; jan_Ent = get_pdata_cbase(id, 373, 5)
if(!pev_valid(jan_Ent))
return
set_pdata_int(jan_Ent, 57, jan_Shell_ModelIndex, 4)
set_pdata_float(id, 111, get_gametime() + jan_Time)
}
stock jan_drop_weapons(id, jan_dropwhat)
{
static weapons[32], num, i, weaponid
num = 0
get_user_weapons(id, weapons, num)
for (i = 0; i < num; i++)
{
weaponid = weapons[i]
if ((jan_dropwhat == 1 && ((1<<weaponid) & jan_PRIMARY_WEAPONS_BIT_SUM)) || (jan_dropwhat == 2 && ((1<<weaponid) & jan_SECONDARY_WEAPONS_BIT_SUM)))
{
static wname[32]; get_weaponname(weaponid, wname, charsmax(wname))
engclient_cmd(id, "drop", wname)
}
}
}
stock jan_set_weapon_anim(id, jan_anim)
{
set_pev(id, pev_weaponanim, jan_anim)
message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
write_byte(jan_anim)
write_byte(pev(id, pev_body))
message_end()
}
stock jan_Make_BulletHole(id, Float:Origin[3], Float:Damage)
{
static jan_Decal; jan_Decal = random_num(41, 45)
static jan_LoopTime;
if(Damage > 100.0) jan_LoopTime = 2
else jan_LoopTime = 1
for(new i = 0; i < jan_LoopTime; i++)
{
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_WORLDDECAL)
engfunc(EngFunc_WriteCoord, Origin[0])
engfunc(EngFunc_WriteCoord, Origin[1])
engfunc(EngFunc_WriteCoord, Origin[2])
write_byte(jan_Decal)
message_end()
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_GUNSHOTDECAL)
engfunc(EngFunc_WriteCoord, Origin[0])
engfunc(EngFunc_WriteCoord, Origin[1])
engfunc(EngFunc_WriteCoord, Origin[2])
write_short(id)
write_byte(jan_Decal)
message_end()
}
}
stock jan_Make_BulletSmoke(id, jan_TrResult)
{
static Float:jan_vecSrc[3], Float:jan_vecEnd[3], jan_TE_FLAG
jan_get_weapon_attachment(id, jan_vecSrc)
global_get(glb_v_forward, jan_vecEnd)
xs_vec_mul_scalar(jan_vecEnd, 8192.0, jan_vecEnd)
xs_vec_add(jan_vecSrc, jan_vecEnd, jan_vecEnd)
get_tr2(jan_TrResult, TR_vecEndPos, jan_vecSrc)
get_tr2(jan_TrResult, TR_vecPlaneNormal, jan_vecEnd)
xs_vec_mul_scalar(jan_vecEnd, 2.5, jan_vecEnd)
xs_vec_add(jan_vecSrc, jan_vecEnd, jan_vecEnd)
jan_TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
jan_TE_FLAG |= TE_EXPLFLAG_NOSOUND
jan_TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, jan_vecEnd, 0)
write_byte(TE_EXPLOSION)
engfunc(EngFunc_WriteCoord, jan_vecEnd[0])
engfunc(EngFunc_WriteCoord, jan_vecEnd[1])
engfunc(EngFunc_WriteCoord, jan_vecEnd[2] - 10.0)
write_short(jan_g_SmokePuff_SprId)
write_byte(2)
write_byte(50)
write_byte(jan_TE_FLAG)
message_end()
}
stock jan_get_weapon_attachment(id, Float:output[3], Float:jan_fDis = 40.0)
{
static Float:jan_vfEnd[3], jan_viEnd[3]
get_user_origin(id, jan_viEnd, 3)
IVecFVec(jan_viEnd, jan_vfEnd)
static Float:jan_fOrigin[3], Float:jan_fAngle[3]
pev(id, pev_origin, jan_fOrigin)
pev(id, pev_view_ofs, jan_fAngle)
xs_vec_add(jan_fOrigin, jan_fAngle, jan_fOrigin)
static Float:jan_fAttack[3]
xs_vec_sub(jan_vfEnd, jan_fOrigin, jan_fAttack)
xs_vec_sub(jan_vfEnd, jan_fOrigin, jan_fAttack)
static Float:jan_fRate
jan_fRate = jan_fDis / vector_length(jan_fAttack)
xs_vec_mul_scalar(jan_fAttack, jan_fRate, jan_fAttack)
xs_vec_add(jan_fOrigin, jan_fAttack, output)
}
stock jan_Set_Player_NextAttack(id, jan_CSWID, Float:jan_NextTime)
{
static jan_Ent; jan_Ent = fm_get_user_weapon_entity(id, jan_CSWID)
if(!pev_valid(jan_Ent)) return
set_pdata_float(id, 83, jan_NextTime, 5)
set_pdata_float(jan_Ent, 46 , jan_NextTime, 4)
set_pdata_float(jan_Ent, 47, jan_NextTime, 4)
set_pdata_float(jan_Ent, 48, jan_NextTime, 4)
}
jan_do_attack(jan_Attacker, jan_Victim, jan_Inflictor, Float:jan_fDamage)
{
jan_fake_player_trace_attack(jan_Attacker, jan_Victim, jan_fDamage)
jan_fake_take_damage(jan_Attacker, jan_Victim, jan_fDamage, jan_Inflictor)
}
jan_fake_player_trace_attack(jan_iAttacker, jan_iVictim, &Float:jan_fDamage)
{
static Float:jan_fAngles[3], Float:jan_fDirection[3]
pev(jan_iAttacker, pev_angles, jan_fAngles)
angle_vector(jan_fAngles, ANGLEVECTOR_FORWARD, jan_fDirection)
static Float:fStart[3], Float:jan_fViewOfs[3]
pev(jan_iAttacker, pev_origin, fStart)
pev(jan_iAttacker, pev_view_ofs, jan_fViewOfs)
xs_vec_add(jan_fViewOfs, fStart, fStart)
static jan_iAimOrigin[3], Float:jan_fAimOrigin[3]
get_user_origin(jan_iAttacker, jan_iAimOrigin, 3)
IVecFVec(jan_iAimOrigin, jan_fAimOrigin)
static ptr; ptr = create_tr2()
engfunc(EngFunc_TraceLine, fStart, jan_fAimOrigin, DONT_IGNORE_MONSTERS, jan_iAttacker, ptr)
static jan_pHit; jan_pHit = get_tr2(ptr, TR_pHit)
static jan_iHitgroup; jan_iHitgroup = get_tr2(ptr, TR_iHitgroup)
static Float:jan_fEndPos[3]
get_tr2(ptr, TR_vecEndPos, jan_fEndPos)
static jan_iTarget, jan_iBody
get_user_aiming(jan_iAttacker, jan_iTarget, jan_iBody)
if (jan_iTarget == jan_iVictim)
{
jan_iHitgroup = jan_iBody
}
else if (jan_pHit != jan_iVictim)
{
static Float:jan_fVicOrigin[3], Float:jan_fVicViewOfs[3], Float:jan_fAimInVictim[3]
pev(jan_iVictim, pev_origin, jan_fVicOrigin)
pev(jan_iVictim, pev_view_ofs, jan_fVicViewOfs)
xs_vec_add(jan_fVicViewOfs, jan_fVicOrigin, jan_fAimInVictim)
jan_fAimInVictim[2] = fStart[2]
jan_fAimInVictim[2] += get_distance_f(fStart, jan_fAimInVictim) * floattan( jan_fAngles[0] * 2.0, degrees )
static jan_iAngleToVictim; jan_iAngleToVictim = jan_get_angle_to_target(jan_iAttacker, jan_fVicOrigin)
jan_iAngleToVictim = abs(jan_iAngleToVictim)
static Float:jan_fDis; jan_fDis = 2.0 * get_distance_f(fStart, jan_fAimInVictim) * floatsin( float(jan_iAngleToVictim) * 0.5, degrees )
static Float:jan_fVicSize[3]
pev(jan_iVictim, pev_size , jan_fVicSize)
if ( jan_fDis <= jan_fVicSize[0] * 0.5 )
{
static jan_ptr2; jan_ptr2 = create_tr2()
engfunc(EngFunc_TraceLine, fStart, jan_fAimInVictim, DONT_IGNORE_MONSTERS, jan_iAttacker, jan_ptr2)
static jan_pHit2; jan_pHit2 = get_tr2(jan_ptr2, TR_pHit)
static jan_iHitgroup2; jan_iHitgroup2 = get_tr2(jan_ptr2, TR_iHitgroup)
if ( jan_pHit2 == jan_iVictim && (jan_iHitgroup2 != HIT_HEAD || jan_fDis <= jan_fVicSize[0] * 0.25) )
{
jan_pHit = jan_iVictim
jan_iHitgroup = jan_iHitgroup2
get_tr2(jan_ptr2, TR_vecEndPos, jan_fEndPos)
}
free_tr2(jan_ptr2)
}
if (jan_pHit != jan_iVictim)
{
jan_iHitgroup = HIT_GENERIC
static jan_ptr3; jan_ptr3 = create_tr2()
engfunc(EngFunc_TraceLine, fStart, jan_fVicOrigin, DONT_IGNORE_MONSTERS, jan_iAttacker, jan_ptr3)
get_tr2(jan_ptr3, TR_vecEndPos, jan_fEndPos)
free_tr2(jan_ptr3)
}
}
set_tr2(ptr, TR_pHit, jan_iVictim)
set_tr2(ptr, TR_iHitgroup, jan_iHitgroup)
set_tr2(ptr, TR_vecEndPos, jan_fEndPos)
jan_fake_trake_attack(jan_iAttacker, jan_iVictim, jan_fDamage, jan_fDirection, ptr)
free_tr2(ptr)
}
stock jan_fake_trake_attack(jan_iAttacker, jan_iVictim, Float:jan_fDamage, Float:jan_fDirection[3], jan_iTraceHandle, jan_iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
ExecuteHamB(Ham_TraceAttack, jan_iVictim, jan_iAttacker, jan_fDamage, jan_fDirection, jan_iTraceHandle, jan_iDamageBit)
}
stock jan_fake_take_damage(jan_iAttacker, jan_iVictim, Float:jan_fDamage, jan_iInflictor, jan_iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
ExecuteHamB(Ham_TakeDamage, jan_iVictim, jan_iInflictor, jan_iAttacker, jan_fDamage, jan_iDamageBit)
}
stock jan_get_angle_to_target(id, const Float:jan_fTarget[3], Float:jan_TargetSize = 0.0)
{
static Float:jan_fOrigin[3], jan_iAimOrigin[3], Float:jan_fAimOrigin[3], Float:jan_fV1[3]
pev(id, pev_origin, jan_fOrigin)
get_user_origin(id, jan_iAimOrigin, 3)
IVecFVec(jan_iAimOrigin, jan_fAimOrigin)
xs_vec_sub(jan_fAimOrigin, jan_fOrigin, jan_fV1)
static Float:jan_fV2[3]
xs_vec_sub(jan_fTarget, jan_fOrigin, jan_fV2)
static jan_iResult; jan_iResult = jan_get_angle_between_vectors(jan_fV1, jan_fV2)
if (jan_TargetSize > 0.0)
{
static Float:jan_fTan; jan_fTan = jan_TargetSize / get_distance_f(jan_fOrigin, jan_fTarget)
static jan_fAngleToTargetSize; jan_fAngleToTargetSize = floatround( floatatan(jan_fTan, degrees) )
jan_iResult -= (jan_iResult > 0) ? jan_fAngleToTargetSize : -jan_fAngleToTargetSize
}
return jan_iResult
}
stock jan_get_angle_between_vectors(const Float:jan_fV1[3], const Float:jan_fV2[3])
{
static Float:jan_fA1[3], Float:jan_fA2[3]
engfunc(EngFunc_VecToAngles, jan_fV1, jan_fA1)
engfunc(EngFunc_VecToAngles, jan_fV2, jan_fA2)
static jan_iResult; jan_iResult = floatround(jan_fA1[1] - jan_fA2[1])
jan_iResult = jan_iResult % 360
jan_iResult = (jan_iResult > 180) ? (jan_iResult - 360) : jan_iResult
return jan_iResult
}
stock jan_is_wall_between_points(Float:start[3], Float:end[3], jan_ignore_ent)
{
static ptr
ptr = create_tr2()
engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, jan_ignore_ent, ptr)
static Float:jan_EndPos[3]
get_tr2(ptr, TR_vecEndPos, jan_EndPos)
free_tr2(ptr)
return floatround(get_distance_f(end, jan_EndPos))
}
public jan_vex_give(id) { if (!is_user_alive(id) || vx45_corezombie(id)) return 0; jan_g_VexGiving[id]=true; jan_Get_Janus7(id); jan_g_VexGiving[id]=false; return jan_vex_has(id) && user_has_weapon(id,CSW_M249); }
public jan_vex_remove(id) { jan_Remove_Janus7(id); return 1; }
public jan_vex_has(id) { return jan_Get_BitVar(jan_g_Had_Janus7, id) ? 1 : 0; }
#define pla_PLUGIN "[CSO] PlasmaGun"
#define pla_VERSION "1.0"
#define pla_AUTHOR "Dias Leon"
#define pla_V_MODEL "models/v_plasmagun2.mdl"
#define pla_P_MODEL "models/p_plasmagun.mdl"
#define pla_W_MODEL "models/w_plasmagun.mdl"
new const pla_WeaponSounds[7][] =
{
"weapons/plasmagun-1.wav",
"weapons/plasmagun_exp.wav",
"weapons/plasmagun_idle.wav",
"weapons/plasmagun_draw.wav",
"weapons/plasmagun_clipin1.wav",
"weapons/plasmagun_clipin2.wav",
"weapons/plasmagun_clipout.wav"
}
new const pla_WeaponResources[3][] =
{
"sprites/weapon_plasmagun.txt",
"sprites/vex_community/plasma/640hud3_2.spr",
"sprites/vex_community/plasma/640hud91_2.spr"
}
new const pla_WeaponFiles[2][] =
{
"sprites/vex_community/plasma/plasmaball.spr",
"sprites/vex_community/plasma/plasmabomb.spr"
}
new const pla_MuzzleFlash[] = "sprites/vex_community/plasma/muzzleflash27.spr"
#define pla_DAMAGE 43
#define pla_CLIP 45
#define pla_BPAMMO 200
#define pla_SPEED 1.5
#define pla_RECOIL 0.75
#define pla_PLASMA_SPEED 1000.0
#define pla_PLASMA_RADIUS 88.0
#define pla_CSW_PLASMA CSW_AK47
#define pla_weapon_plasma "weapon_ak47"
#define pla_WEAPON_EVENT "events/ak47.sc"
#define pla_WEAPON_ANIMEXT "carbine"
#define pla_WEAPON_OLD_WMODEL "models/vexmira_ze/skins/vexmira_w_ak47.mdl"
#define pla_WEAPON_SECRETCODE 1946
#define pla_WEAPONANIM_SHOOT random_num(3, 5)
#define pla_WEAPONANIM_RELOAD 1
#define pla_WEAPONTIME_DRAW 0.75
#define pla_WEAPONTIME_RELOAD 3.5
#define pla_PLASMABALL_CLASSNAME "vex_plasma_ball"
#define pla_Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define pla_Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define pla_UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
enum
{
pla_TEAM_T = 1,
pla_TEAM_CT
}
new pla_g_Had_Plasma, pla_g_WeaponClip[33], Float:pla_g_WeaponRecoil[33][3]
new pla_g_Msg_WeaponList, pla_g_Msg_CurWeapon, pla_g_Msg_AmmoX
new pla_g_MuzzleFlash_SprId, pla_g_PlasmaExp_SprId, pla_g_weapon_event, pla_g_HamBot, pla_g_MaxPlayers
new bool:pla_g_VexGiving[33];
public pla_plugin_init()
{
register_event("HLTV", "pla_Event_NewRound", "a", "1=0", "2=0")
g_zcFm[ZCFM_UpdateClientData_P] |= (1<<1)
g_zcFm[ZCFM_PlaybackEvent] |= (1<<1)
g_zcFm[ZCFM_SetModel] |= (1<<1)
register_think(pla_PLASMABALL_CLASSNAME, "pla_fw_Think_Plasma")
register_touch(pla_PLASMABALL_CLASSNAME, "*", "pla_fw_Touch_Plasma")
VxRegisterHam524(Ham_TraceAttack, "worldspawn", "pla_fw_TraceAttack_World")
VxRegisterHam524(Ham_TraceAttack, "player", "pla_fw_TraceAttack_Player")
VxRegisterHam524(Ham_Weapon_PrimaryAttack, pla_weapon_plasma, "pla_fw_Weapon_PrimaryAttack")
VxRegisterHam524(Ham_Weapon_PrimaryAttack, pla_weapon_plasma, "pla_fw_Weapon_PrimaryAttack_49b", 1)
VxRegisterHam524(Ham_Item_Deploy, pla_weapon_plasma, "pla_fw_Item_Deploy_Post", 1)
VxRegisterHam524(Ham_Item_PostFrame, pla_weapon_plasma, "pla_fw_Item_PostFrame")
VxRegisterHam524(Ham_Weapon_Reload, pla_weapon_plasma, "pla_fw_Weapon_Reload")
VxRegisterHam524(Ham_Weapon_Reload, pla_weapon_plasma, "pla_fw_Weapon_Reload_Post", 1)
VxRegisterHam524(Ham_Item_AddToPlayer, pla_weapon_plasma, "pla_fw_Item_AddToPlayer_Post", 1)
pla_g_Msg_WeaponList = get_user_msgid("WeaponList")
pla_g_Msg_CurWeapon = get_user_msgid("CurWeapon")
pla_g_Msg_AmmoX = get_user_msgid("AmmoX")
pla_g_MaxPlayers = get_maxplayers()
register_clcmd("weapon_plasmagun", "pla_Hook_WeaponHud")
}
public pla_plugin_precache()
{
if (!VexAssetGuard("vx42_plasma")) return;
ZcPcModel(pla_V_MODEL)
ZcPcModel(pla_P_MODEL)
ZcPcModel(pla_W_MODEL)
new i
for(i = 0; i < sizeof(pla_WeaponSounds); i++)
VexPcSnd(pla_WeaponSounds[i], (i==0||i==1) ? true : false)
for(i = 0; i < sizeof(pla_WeaponResources); i++)
{
if(i == 0) ZcPcGeneric(pla_WeaponResources[i])
else ZcPcModel(pla_WeaponResources[i])
}
for(i = 0; i < sizeof(pla_WeaponFiles); i++)
{
if(i == 1) pla_g_PlasmaExp_SprId = ZcPcModel(pla_WeaponFiles[i])
else ZcPcModel(pla_WeaponFiles[i])
}
pla_g_MuzzleFlash_SprId = ZcPcModel(pla_MuzzleFlash)
register_forward(FM_PrecacheEvent, "pla_fw_PrecacheEvent_Post", 1)
}
public pla_fw_PrecacheEvent_Post(type, const name[])
{
if(equal(pla_WEAPON_EVENT, name)) pla_g_weapon_event = get_orig_retval()
}
public pla_client_putinserver(id)
{
if(!pla_g_HamBot && is_user_bot(id))
{
pla_g_HamBot = 1
set_task(0.1, "pla_Do_RegisterHam", (id) + ZC_TOFF_PLA)
}
}
public pla_Do_VxRegisterHam524(id)
{ if (id >= ZC_TOFF_PLA && id < ZC_TOFF_PLA + 0x1000000) id -= ZC_TOFF_PLA;
RegisterHamFromEntity(Ham_TraceAttack, id, "pla_fw_TraceAttack_Player")
}
public pla_Get_Plasma(id)
{
if(!is_user_alive(id))
return
pla_Set_BitVar(pla_g_Had_Plasma, id)
fm_give_item(id, pla_weapon_plasma)
engclient_cmd(id, pla_weapon_plasma)
set_pev(id, pev_viewmodel2, pla_V_MODEL)
set_pev(id, pev_weaponmodel2, pla_P_MODEL)
set_pdata_string(id, (492) * 4, pla_WEAPON_ANIMEXT, -1 , 20)
static pla_Ent; pla_Ent = fm_get_user_weapon_entity(id, pla_CSW_PLASMA)
if(!pev_valid(pla_Ent)) return
cs_set_weapon_ammo(pla_Ent, pla_CLIP)
cs_set_user_bpammo(id, pla_CSW_PLASMA, pla_BPAMMO)
pla_Update_AmmoHud(id, pla_CSW_PLASMA, pla_CLIP, pla_BPAMMO)
}
public pla_Remove_Plasma(id)
{
pla_UnSet_BitVar(pla_g_Had_Plasma, id)
}
public pla_Hook_WeaponHud(id)
{
engclient_cmd(id, pla_weapon_plasma)
return PLUGIN_HANDLED
}
public pla_Event_NewRound() remove_entity_name(pla_PLASMABALL_CLASSNAME)
public pla_fw_Think_Plasma(pla_Ent)
{
if(!pev_valid(pla_Ent))
return
static Float:pla_RenderAmt; pev(pla_Ent, pev_renderamt, pla_RenderAmt)
pla_RenderAmt += 50.0
pla_RenderAmt = float(clamp(floatround(pla_RenderAmt), 0, 255))
set_pev(pla_Ent, pev_renderamt, pla_RenderAmt)
set_pev(pla_Ent, pev_nextthink, halflife_time() + 0.1)
}
public pla_fw_Touch_Plasma(pla_Ent, pla_Id)
{
if(!pev_valid(pla_Ent))
return
if(pev(pla_Ent, pev_movetype) == MOVETYPE_NONE)
return
static Float:Origin[3], pla_TE_FLAG
pev(pla_Ent, pev_origin, Origin)
pla_TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
pla_TE_FLAG |= TE_EXPLFLAG_NOSOUND
pla_TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_EXPLOSION)
engfunc(EngFunc_WriteCoord, Origin[0])
engfunc(EngFunc_WriteCoord, Origin[1])
engfunc(EngFunc_WriteCoord, Origin[2])
write_short(pla_g_PlasmaExp_SprId)
write_byte(7)
write_byte(30)
write_byte(pla_TE_FLAG)
message_end()
emit_sound(pla_Ent, CHAN_BODY, pla_WeaponSounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
pla_Damage_Plasma(pla_Ent, pla_Id)
set_pev(pla_Ent, pev_movetype, MOVETYPE_NONE)
set_task(0.1, "pla_Remove_PlasmaBall", (pla_Ent) + ZC_TOFF_PLA)
}
public pla_Damage_Plasma(pla_Ent, pla_Id)
{
static pla_Owner; pla_Owner = pev(pla_Ent, pev_iuser1)
static pla_Attacker;
if(pla_Owner < 1 || pla_Owner > 32 || !is_user_alive(pla_Owner) || vx45_corezombie(pla_Owner) || pev(pla_Ent, pev_iuser4) != get_user_userid(pla_Owner))
{
pla_Attacker = 0
return
} else pla_Attacker = pla_Owner
if(is_user_alive(pla_Id) && cs_get_user_team(pla_Id) != pla_Get_PlasmaTeam(pla_Ent))
ExecuteHamB(Ham_TakeDamage, pla_Id, 0, pla_Attacker, float(pla_DAMAGE), DMG_ACID)
for(new i = 1; i <= pla_g_MaxPlayers; i++)
{
if(!is_user_alive(i))
continue
if(entity_range(i, pla_Ent) > pla_PLASMA_RADIUS)
continue
if(cs_get_user_team(i) == pla_Get_PlasmaTeam(pla_Ent))
continue
ExecuteHamB(Ham_TakeDamage, i, 0, pla_Attacker, float(pla_DAMAGE) / random_float(1.25, 1.5), DMG_ACID)
}
}
public pla_Remove_PlasmaBall(pla_Ent)
{ if (pla_Ent >= ZC_TOFF_PLA && pla_Ent < ZC_TOFF_PLA + 0x1000000) pla_Ent -= ZC_TOFF_PLA;
if(!pev_valid(pla_Ent)) return
new classname[32]; pev(pla_Ent,pev_classname,classname,charsmax(classname));
if(!equal(classname,"vex_plasma_ball")) return
engfunc(EngFunc_RemoveEntity, pla_Ent)
}
public pla_fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
if(!is_user_alive(id))
return FMRES_IGNORED
if(get_user_weapon(id) == pla_CSW_PLASMA && pla_Get_BitVar(pla_g_Had_Plasma, id))
set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001)
return FMRES_HANDLED
}
public pla_fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, pla_iParam1, pla_iParam2, pla_bParam1, pla_bParam2)
{
if (!is_user_connected(invoker))
return FMRES_IGNORED
if(get_user_weapon(invoker) != pla_CSW_PLASMA || !pla_Get_BitVar(pla_g_Had_Plasma, invoker))
return FMRES_IGNORED
if(eventid != pla_g_weapon_event)
return FMRES_IGNORED
engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, pla_iParam1, pla_iParam2, pla_bParam1, pla_bParam2)
return FMRES_SUPERCEDE
}
public pla_fw_SetModel(entity, model[])
{
if(!pev_valid(entity))
return FMRES_IGNORED
static Classname[32]
pev(entity, pev_classname, Classname, sizeof(Classname))
if(!equal(Classname, "weaponbox"))
return FMRES_IGNORED
static iOwner
iOwner = pev(entity, pev_owner)
if(equal(model, pla_WEAPON_OLD_WMODEL))
{
static weapon; weapon = fm_find_ent_by_owner(-1, pla_weapon_plasma, entity)
if(!pev_valid(weapon))
return FMRES_IGNORED;
if(pla_Get_BitVar(pla_g_Had_Plasma, iOwner))
{
pla_Remove_Plasma(iOwner)
set_pev(weapon, pev_impulse, pla_WEAPON_SECRETCODE)
VxSM(entity, pla_W_MODEL)
return FMRES_SUPERCEDE
}
}
return FMRES_IGNORED;
}
public pla_fw_TraceAttack_World(pla_Victim, pla_Attacker, Float:Damage, Float:pla_Direction[3], pla_Ptr, pla_DamageBits)
{
if(!is_user_connected(pla_Attacker))
return HAM_IGNORED
if(get_user_weapon(pla_Attacker) != pla_CSW_PLASMA || !pla_Get_BitVar(pla_g_Had_Plasma, pla_Attacker))
return HAM_IGNORED
return HAM_SUPERCEDE
}
public pla_fw_TraceAttack_Player(pla_Victim, pla_Attacker, Float:Damage, Float:pla_Direction[3], pla_Ptr, pla_DamageBits)
{
if(!is_user_connected(pla_Attacker))
return HAM_IGNORED
if(get_user_weapon(pla_Attacker) != pla_CSW_PLASMA || !pla_Get_BitVar(pla_g_Had_Plasma, pla_Attacker))
return HAM_IGNORED
return HAM_SUPERCEDE
}
public pla_fw_Weapon_PrimaryAttack(pla_Ent)
{
if(!pev_valid(pla_Ent))
return
static pla_Id; pla_Id = pev(pla_Ent, pev_owner)
if(!pla_Get_BitVar(pla_g_Had_Plasma, pla_Id))
return
static pla_Ammo; pla_Ammo = cs_get_weapon_ammo(pla_Ent)
if(pla_Ammo <= 0) return
pla_Set_Weapon_Anim(pla_Id, pla_WEAPONANIM_SHOOT)
emit_sound(pla_Id, CHAN_WEAPON, pla_WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
pla_Make_Muzzleflash(pla_Id)
pla_Create_PlasmaBall(pla_Id)
pev(pla_Ent, pev_punchangle, pla_g_WeaponRecoil[pla_Id])
}
public pla_fw_Weapon_PrimaryAttack_49b(pla_Ent)
{
if(!pev_valid(pla_Ent))
return
static pla_Id; pla_Id = pev(pla_Ent, pev_owner)
if(!pla_Get_BitVar(pla_g_Had_Plasma, pla_Id))
return
static pla_Ammo; pla_Ammo = cs_get_weapon_ammo(pla_Ent)
if(pla_Ammo <= 0) return
set_pdata_float(pla_Ent, 46, get_pdata_float(pla_Ent, 46, 4) * pla_SPEED, 4)
static Float:pla_Push[3]; pev(pla_Id, pev_punchangle, pla_Push)
xs_vec_sub(pla_Push, pla_g_WeaponRecoil[pla_Id], pla_Push)
xs_vec_mul_scalar(pla_Push, pla_RECOIL, pla_Push)
xs_vec_add(pla_Push,  pla_g_WeaponRecoil[pla_Id], pla_Push)
set_pev(pla_Id, pev_punchangle, pla_Push)
}
public pla_fw_Item_Deploy_Post(pla_Ent)
{
if(!pev_valid(pla_Ent))
return
static pla_Id; pla_Id = pev(pla_Ent, pev_owner)
if(!pla_Get_BitVar(pla_g_Had_Plasma, pla_Id))
return
set_pev(pla_Id, pev_viewmodel2, pla_V_MODEL)
set_pev(pla_Id, pev_weaponmodel2, pla_P_MODEL)
set_pdata_string(pla_Id, (492) * 4, pla_WEAPON_ANIMEXT, -1 , 20)
pla_Set_Player_NextAttack(pla_Id, pla_WEAPONTIME_DRAW)
pla_Set_Weapon_TimeIdle(pla_Id, pla_CSW_PLASMA, pla_WEAPONTIME_DRAW)
}
public pla_fw_Item_PostFrame(pla_Ent)
{
if(!pev_valid(pla_Ent))
return
static pla_Id; pla_Id = pev(pla_Ent, pev_owner)
if(!pla_Get_BitVar(pla_g_Had_Plasma, pla_Id))
return
static Float:pla_flNextAttack; pla_flNextAttack = get_pdata_float(pla_Id, 83, 5)
static pla_bpammo; pla_bpammo = cs_get_user_bpammo(pla_Id, pla_CSW_PLASMA)
static pla_iClip; pla_iClip = get_pdata_int(pla_Ent, 51, 4)
if(get_pdata_int(pla_Ent, 54, 4) && pla_flNextAttack <= 0.0)
{
static pla_temp1; pla_temp1 = min(pla_CLIP - pla_iClip, pla_bpammo)
set_pdata_int(pla_Ent, 51, pla_iClip + pla_temp1, 4)
cs_set_user_bpammo(pla_Id, pla_CSW_PLASMA, pla_bpammo - pla_temp1)
set_pdata_int(pla_Ent, 54, 0, 4)
}
}
public pla_fw_Weapon_Reload(pla_Ent)
{
if(!pev_valid(pla_Ent))
return HAM_IGNORED
static pla_Id; pla_Id = pev(pla_Ent, pev_owner)
if(!pla_Get_BitVar(pla_g_Had_Plasma, pla_Id))
return HAM_IGNORED
pla_g_WeaponClip[pla_Id] = -1
static pla_bpammo; pla_bpammo = cs_get_user_bpammo(pla_Id, pla_CSW_PLASMA)
static pla_iClip; pla_iClip = get_pdata_int(pla_Ent, 51, 4)
if(pla_bpammo <= 0) return HAM_SUPERCEDE
if(pla_iClip >= pla_CLIP) return HAM_SUPERCEDE
pla_g_WeaponClip[pla_Id] = pla_iClip
return HAM_IGNORED
}
public pla_fw_Weapon_Reload_Post(pla_Ent)
{
if(!pev_valid(pla_Ent))
return
static pla_Id; pla_Id = pev(pla_Ent, pev_owner)
if(!pla_Get_BitVar(pla_g_Had_Plasma, pla_Id))
return
if(pla_g_WeaponClip[pla_Id] == -1)
return
set_pdata_int(pla_Ent, 51, pla_g_WeaponClip[pla_Id], 4)
set_pdata_int(pla_Ent, 54, 1, 4)
pla_Set_Weapon_Anim(pla_Id, pla_WEAPONANIM_RELOAD)
set_pdata_float(pla_Id, 83, pla_WEAPONTIME_RELOAD, 5)
}
public pla_fw_Item_AddToPlayer_Post(pla_Ent, pla_Id)
{
if(pla_Id>=1 && pla_Id<=32 && !pla_g_VexGiving[pla_Id]) pla_UnSet_BitVar(pla_g_Had_Plasma, pla_Id);
if(pla_Id<1 || pla_Id>32 || !is_user_connected(pla_Id)) return HAM_IGNORED;
if(!pev_valid(pla_Ent))
return HAM_IGNORED
if(pev(pla_Ent, pev_impulse) == pla_WEAPON_SECRETCODE)
{
pla_Set_BitVar(pla_g_Had_Plasma, pla_Id)
set_pev(pla_Ent, pev_impulse, 0)
set_task(0.01, "pla_AddToPlayer_Delay", (pla_Id) + ZC_TOFF_PLA)
}
message_begin(MSG_ONE_UNRELIABLE, pla_g_Msg_WeaponList, _, pla_Id)
write_string(pla_Get_BitVar(pla_g_Had_Plasma, pla_Id) ? "weapon_plasmagun" : "weapon_ak47")
write_byte(2)
write_byte(pla_Get_BitVar(pla_g_Had_Plasma, pla_Id) ? 200 : 90)
write_byte(-1)
write_byte(-1)
write_byte(0)
write_byte(1)
write_byte(pla_Get_BitVar(pla_g_Had_Plasma, pla_Id) ? pla_CSW_PLASMA : CSW_AK47)
write_byte(0)
message_end()
return HAM_IGNORED;
}
public pla_AddToPlayer_Delay(pla_Id)
{ if (pla_Id >= ZC_TOFF_PLA && pla_Id < ZC_TOFF_PLA + 0x1000000) pla_Id -= ZC_TOFF_PLA;
set_pev(pla_Id, pev_viewmodel2, pla_V_MODEL)
set_pev(pla_Id, pev_weaponmodel2, pla_P_MODEL)
set_pdata_string(pla_Id, (492) * 4, pla_WEAPON_ANIMEXT, -1 , 20)
}
public pla_Create_PlasmaBall(id)
{
static Float:pla_StartOrigin[3], Float:pla_TargetOrigin[3], Float:pla_MyVelocity[3], Float:pla_VecLength
pla_get_position(id, 48.0, 10.0, -5.0, pla_StartOrigin)
pla_get_position(id, 1024.0, 0.0, 0.0, pla_TargetOrigin)
pev(id, pev_velocity, pla_MyVelocity)
pla_VecLength = vector_length(pla_MyVelocity)
if(pla_VecLength)
{
pla_TargetOrigin[0] += random_float(-16.0, 16.0); pla_TargetOrigin[1] += random_float(-16.0, 16.0); pla_TargetOrigin[2] += random_float(-16.0, 16.0)
} else {
pla_TargetOrigin[0] += random_float(-8.0, 8.0); pla_TargetOrigin[1] += random_float(-8.0, 8.0); pla_TargetOrigin[2] += random_float(-8.0, 8.0)
}
static pla_Ent; pla_Ent = GearCreate51("env_sprite")
if(!pev_valid(pla_Ent)) return
set_pev(pla_Ent, pev_movetype, MOVETYPE_FLY)
set_pev(pla_Ent, pev_rendermode, kRenderTransAdd)
set_pev(pla_Ent, pev_renderamt, 10.0)
set_pev(pla_Ent, pev_iuser1, id)
set_pev(pla_Ent, pev_iuser4, get_user_userid(id));
set_pev(pla_Ent, pev_iuser2, pla_Get_SpecialTeam(id, cs_get_user_team(id)))
set_pev(pla_Ent, pev_fuser1, get_gametime() + 3.0)
set_pev(pla_Ent, pev_scale, random_float(0.1, 0.25))
set_pev(pla_Ent, pev_nextthink, halflife_time() + 0.1)
entity_set_string(pla_Ent, EV_SZ_classname, pla_PLASMABALL_CLASSNAME)
VxSM(pla_Ent, pla_WeaponFiles[0])
set_pev(pla_Ent, pev_mins, Float:{-1.0, -1.0, -1.0})
set_pev(pla_Ent, pev_maxs, Float:{1.0, 1.0, 1.0})
set_pev(pla_Ent, pev_origin, pla_StartOrigin)
set_pev(pla_Ent, pev_gravity, 0.01)
set_pev(pla_Ent, pev_solid, SOLID_TRIGGER)
set_pev(pla_Ent, pev_frame, 0.0)
static Float:pla_Velocity[3]
pla_get_speed_vector(pla_StartOrigin, pla_TargetOrigin, pla_PLASMA_SPEED, pla_Velocity)
set_pev(pla_Ent, pev_velocity, pla_Velocity)
}
public pla_Make_Muzzleflash(id)
{
static Float:Origin[3], pla_TE_FLAG
pla_get_position(id, 32.0, 6.0, -15.0, Origin)
pla_TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
pla_TE_FLAG |= TE_EXPLFLAG_NOSOUND
pla_TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, Origin, id)
write_byte(TE_EXPLOSION)
engfunc(EngFunc_WriteCoord, Origin[0])
engfunc(EngFunc_WriteCoord, Origin[1])
engfunc(EngFunc_WriteCoord, Origin[2])
write_short(pla_g_MuzzleFlash_SprId)
write_byte(2)
write_byte(30)
write_byte(pla_TE_FLAG)
message_end()
}
public pla_Update_AmmoHud(id, pla_CSWID, pla_Ammo, pla_BpAmmo)
{
message_begin(MSG_ONE_UNRELIABLE, pla_g_Msg_CurWeapon, _, id)
write_byte(1)
write_byte(pla_CSWID)
write_byte(pla_Ammo)
message_end()
message_begin(MSG_ONE_UNRELIABLE, pla_g_Msg_AmmoX, _, id)
write_byte(10)
write_byte(pla_BpAmmo)
message_end()
}
public pla_Get_SpecialTeam(pla_Ent, CsTeams:Team)
{
if(Team == CS_TEAM_T) return pla_TEAM_T
else if(Team == CS_TEAM_CT) return pla_TEAM_CT
return 0
}
public CsTeams:pla_Get_PlasmaTeam(pla_Ent)
{
if(pev(pla_Ent, pev_iuser2) == pla_TEAM_T) return CS_TEAM_T
else if(pev(pla_Ent, pev_iuser2) == pla_TEAM_CT) return CS_TEAM_CT
return CS_TEAM_UNASSIGNED
}
stock pla_get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:pla_new_velocity[3])
{
pla_new_velocity[0] = origin2[0] - origin1[0]
pla_new_velocity[1] = origin2[1] - origin1[1]
pla_new_velocity[2] = origin2[2] - origin1[2]
static Float:num; num = floatsqroot(speed*speed / (pla_new_velocity[0]*pla_new_velocity[0] + pla_new_velocity[1]*pla_new_velocity[1] + pla_new_velocity[2]*pla_new_velocity[2]))
pla_new_velocity[0] *= num
pla_new_velocity[1] *= num
pla_new_velocity[2] *= num
return 1;
}
stock pla_Set_Weapon_TimeIdle(id, pla_WeaponId, Float:pla_TimeIdle)
{
static pla_Ent; pla_Ent = fm_get_user_weapon_entity(id, pla_WeaponId)
if(!pev_valid(pla_Ent)) return
set_pdata_float(pla_Ent, 46, pla_TimeIdle, 4)
set_pdata_float(pla_Ent, 47, pla_TimeIdle, 4)
set_pdata_float(pla_Ent, 48, pla_TimeIdle + 0.5, 4)
}
stock pla_Set_Player_NextAttack(id, Float:pla_nexttime)
{
set_pdata_float(id, 83, pla_nexttime, 5)
}
stock pla_Set_Weapon_Anim(id, pla_WeaponAnim)
{
set_pev(id, pev_weaponanim, pla_WeaponAnim)
message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
write_byte(pla_WeaponAnim)
write_byte(pev(id, pev_body))
message_end()
}
stock pla_get_position(id,Float:pla_forw, Float:right, Float:up, Float:pla_vStart[])
{
static Float:pla_vOrigin[3], Float:pla_vAngle[3], Float:pla_vForward[3], Float:pla_vRight[3], Float:pla_vUp[3]
pev(id, pev_origin, pla_vOrigin)
pev(id, pev_view_ofs, pla_vUp)
xs_vec_add(pla_vOrigin, pla_vUp, pla_vOrigin)
pev(id, pev_v_angle, pla_vAngle)
angle_vector(pla_vAngle, ANGLEVECTOR_FORWARD, pla_vForward)
angle_vector(pla_vAngle, ANGLEVECTOR_RIGHT, pla_vRight)
angle_vector(pla_vAngle, ANGLEVECTOR_UP, pla_vUp)
pla_vStart[0] = pla_vOrigin[0] + pla_vForward[0] * pla_forw + pla_vRight[0] * right + pla_vUp[0] * up
pla_vStart[1] = pla_vOrigin[1] + pla_vForward[1] * pla_forw + pla_vRight[1] * right + pla_vUp[1] * up
pla_vStart[2] = pla_vOrigin[2] + pla_vForward[2] * pla_forw + pla_vRight[2] * right + pla_vUp[2] * up
}
public pla_vex_give(id) { if (!is_user_alive(id) || vx45_corezombie(id)) return 0; pla_g_VexGiving[id]=true; pla_Get_Plasma(id); pla_g_VexGiving[id]=false; return pla_vex_has(id) && user_has_weapon(id,CSW_AK47); }
public pla_vex_remove(id) { pla_Remove_Plasma(id); return 1; }
public pla_vex_has(id) { return pla_Get_BitVar(pla_g_Had_Plasma, id) ? 1 : 0; }
#define thb_PLUGIN "Thunderbolt"
#define thb_VERSION "2014"
#define thb_AUTHOR "Dias"
#define thb_DAMAGE 550
#define thb_DEFAULT_AMMO 20
#define thb_RELOAD_TIME 2.67
#define thb_CSW_THUNDERBOLT CSW_AWP
#define thb_weapon_thunderbolt "weapon_awp"
#define thb_old_event "events/awp.sc"
#define thb_old_w_model "models/vexmira_ze/skins/vexmira_w_awp.mdl"
#define thb_WEAPON_SECRETCODE 4234234
#define thb_V_MODEL "models/v_sfsniperF.mdl"
#define thb_P_MODEL "models/p_sfsniper.mdl"
#define thb_W_MODEL "models/w_sfsniper.mdl"
#define thb_SNIP_MODEL_R "models/v_sfsightR.mdl"
#define thb_SNIP_MODEL_B "models/v_sfsightB.mdl"
new const thb_WeaponSounds[5][] =
{
"weapons/sfsniper-1.wav",
"weapons/sfsniper_insight1.wav",
"weapons/sfsniper_zoom.wav",
"weapons/sfsniper_idle.wav",
"weapons/sfsniper_draw.wav"
}
new const thb_WeaponResources[4][] =
{
"sprites/weapon_sfsniperF.txt",
"sprites/vex_community/thunderbolt/640hud2_2.spr",
"sprites/vex_community/thunderbolt/640hud10_2.spr",
"sprites/vex_community/thunderbolt/640hud81_2.spr"
}
enum
{
thb_TB_ANIM_IDLE = 0,
thb_TB_ANIM_SHOOT,
thb_TB_ANIM_DRAW
}
enum
{
thb_ZOOM_NONE = 0,
thb_ZOOM_ACT
}
#define thb_Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define thb_Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define thb_UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new thb_g_Had_Thunderbolt, thb_g_Zoom[33]
new thb_g_IsAlive
new Float:thb_CheckDelay[33], Float:thb_CheckDelay2[33], Float:thb_CheckDelay3[33], thb_g_TempAttack
new thb_g_Msg_CurWeapon, thb_g_Msg_AmmoX, thb_g_Msg_WeaponList
new thb_g_Beam_SprId, thb_g_HamBot_Register, thb_g_Event_Thunderbolt
new bool:thb_g_VexGiving[33];
public thb_plugin_init()
{
g_zcEvCurWeapon |= (1<<2)
register_event("DeathMsg", "thb_Event_Death", "a")
g_zcFm[ZCFM_UpdateClientData_P] |= (1<<2)
g_zcFm[ZCFM_PlaybackEvent] |= (1<<2)
g_zcFm[ZCFM_SetModel] |= (1<<2)
g_zcFm[ZCFM_CmdStart] |= (1<<2)
g_zcFm[ZCFM_EmitSound] |= (1<<2)
g_zcFm[ZCFM_TraceLine] |= (1<<2)
g_zcFm[ZCFM_TraceHull] |= (1<<2)
VxRegisterHam524(Ham_Spawn, "player", "thb_fw_PlayerSpawn_Post", 1)
VxRegisterHam524(Ham_Item_AddToPlayer, thb_weapon_thunderbolt, "thb_fw_AddToPlayer_Post", 1)
VxRegisterHam524(Ham_Item_Deploy, thb_weapon_thunderbolt, "thb_fw_Item_Deploy_Post", 1)
VxRegisterHam524(Ham_Weapon_WeaponIdle, thb_weapon_thunderbolt, "thb_fw_Weapon_WeaponIdle_Post", 1)
VxRegisterHam524(Ham_Weapon_SecondaryAttack, "weapon_awp", "thb_fw_Weapon_SecondaryAttack")
thb_g_Msg_CurWeapon = get_user_msgid("CurWeapon")
thb_g_Msg_AmmoX = get_user_msgid("AmmoX")
thb_g_Msg_WeaponList = get_user_msgid("WeaponList")
register_clcmd("weapon_sfsniperF", "thb_CLCMD_HookWeapon")
}
public thb_plugin_precache()
{
if (!VexAssetGuard("vx42_thunderbolt")) return;
ZcPcModel(thb_V_MODEL)
ZcPcModel(thb_P_MODEL)
ZcPcModel(thb_W_MODEL)
ZcPcModel(thb_SNIP_MODEL_R)
ZcPcModel(thb_SNIP_MODEL_B)
for(new i = 0; i < sizeof(thb_WeaponSounds); i++)
VexPcSnd(thb_WeaponSounds[i], (i==0||i==1||i==2) ? true : false)
for(new i = 0; i < sizeof(thb_WeaponResources); i++)
{
if(i == 0) ZcPcGeneric(thb_WeaponResources[0])
else ZcPcModel(thb_WeaponResources[i])
}
thb_g_Beam_SprId =  ZcPcModel("sprites/laserbeam.spr")
}
public thb_client_putinserver(id)
{
if(is_user_bot(id) && !thb_g_HamBot_Register)
{
thb_g_HamBot_Register = 1
set_task(0.1, "thb_Do_RegisterHamBot", (id) + ZC_TOFF_THB)
}
thb_UnSet_BitVar(thb_g_TempAttack, id)
thb_UnSet_BitVar(thb_g_IsAlive, id)
}
public thb_Do_RegisterHamBot(id)
{ if (id >= ZC_TOFF_THB && id < ZC_TOFF_THB + 0x1000000) id -= ZC_TOFF_THB;
RegisterHamFromEntity(Ham_Spawn, id, "thb_fw_PlayerSpawn_Post", 1)
}
public thb_fw_PrecacheEvent_Post(type, const name[])
{
if(equal(thb_old_event, name)) thb_g_Event_Thunderbolt = get_orig_retval()
}
public thb_Get_Thunderbolt(id)
{
thb_g_Zoom[id] = thb_ZOOM_NONE
thb_Set_BitVar(thb_g_Had_Thunderbolt, id)
give_item(id, thb_weapon_thunderbolt)
static thb_weapon_ent; thb_weapon_ent = fm_find_ent_by_owner(-1, thb_weapon_thunderbolt, id)
if(pev_valid(thb_weapon_ent)) cs_set_weapon_ammo(thb_weapon_ent, 10)
cs_set_user_bpammo(id, thb_CSW_THUNDERBOLT, thb_DEFAULT_AMMO)
}
public thb_Remove_Thunderbolt(id)
{
thb_g_Zoom[id] = thb_ZOOM_NONE
thb_UnSet_BitVar(thb_g_Had_Thunderbolt, id)
}
public thb_Event_CurWeapon(id)
{
static thb_CSWID; thb_CSWID = read_data(2)
if(thb_CSWID != thb_CSW_THUNDERBOLT || !thb_Get_BitVar(thb_g_Had_Thunderbolt, id))
return
thb_UpdateAmmo(id, -1, cs_get_user_bpammo(id, thb_CSW_THUNDERBOLT))
}
public thb_Event_Death()
{
static thb_Victim; thb_Victim = read_data(2)
thb_UnSet_BitVar(thb_g_IsAlive, thb_Victim)
}
public thb_CLCMD_HookWeapon(id)
{
engclient_cmd(id, thb_weapon_thunderbolt)
return
}
public thb_fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
if(!thb_Get_BitVar(thb_g_IsAlive, id))
return FMRES_IGNORED
if(get_user_weapon(id) == thb_CSW_THUNDERBOLT && thb_Get_BitVar(thb_g_Had_Thunderbolt, id))
set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001)
return FMRES_HANDLED
}
public thb_fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, thb_iParam1, thb_iParam2, thb_bParam1, thb_bParam2)
{
if(eventid != thb_g_Event_Thunderbolt)
return FMRES_IGNORED
if(!thb_Get_BitVar(thb_g_IsAlive, invoker))
return FMRES_IGNORED
if(get_user_weapon(invoker) != thb_CSW_THUNDERBOLT || !thb_Get_BitVar(thb_g_Had_Thunderbolt, invoker))
return FMRES_IGNORED
engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, thb_iParam1, thb_iParam2, thb_bParam1, thb_bParam2)
return FMRES_SUPERCEDE
}
public thb_fw_SetModel(entity, model[])
{
if(!pev_valid(entity))
return FMRES_IGNORED
static Classname[64]
pev(entity, pev_classname, Classname, sizeof(Classname))
if(!equal(Classname, "weaponbox"))
return FMRES_IGNORED
static id
id = pev(entity, pev_owner)
if(equal(model, thb_old_w_model))
{
static weapon
weapon = fm_get_user_weapon_entity(entity, thb_CSW_THUNDERBOLT)
if(!pev_valid(weapon))
return FMRES_IGNORED
if(thb_Get_BitVar(thb_g_Had_Thunderbolt, id))
{
thb_UnSet_BitVar(thb_g_Had_Thunderbolt, id)
set_pev(weapon, pev_impulse, thb_WEAPON_SECRETCODE)
set_pev(weapon, pev_iuser4, cs_get_user_bpammo(id, thb_CSW_THUNDERBOLT))
VxSM(entity, thb_W_MODEL)
return FMRES_SUPERCEDE
}
}
return FMRES_IGNORED;
}
public thb_fw_CmdStart(id, thb_UcHandle, thb_Seed)
{
if(!thb_Get_BitVar(thb_g_IsAlive, id))
return FMRES_IGNORED
if(get_user_weapon(id) != thb_CSW_THUNDERBOLT || !thb_Get_BitVar(thb_g_Had_Thunderbolt, id))
return FMRES_IGNORED
if(get_pdata_float(id, 83, 5) > 0.0)
return FMRES_IGNORED
static thb_CurButton; thb_CurButton = get_uc(thb_UcHandle, UC_Buttons)
if(thb_CurButton & IN_ATTACK)
{
thb_CurButton &= ~IN_ATTACK
set_uc(thb_UcHandle, UC_Buttons, thb_CurButton)
if(get_gametime() - thb_RELOAD_TIME > thb_CheckDelay[id])
{
thb_Thunderbolt_Shooting(id)
thb_CheckDelay[id] = get_gametime()
}
}
if(thb_CurButton & IN_ATTACK2)
{
if(get_gametime() - 0.5 > thb_CheckDelay3[id])
{
switch(thb_g_Zoom[id])
{
case thb_ZOOM_NONE: thb_Activate_Zoom(id, thb_ZOOM_ACT)
case thb_ZOOM_ACT: thb_Activate_Zoom(id, thb_ZOOM_NONE)
default: thb_Activate_Zoom(id, thb_ZOOM_NONE)
}
thb_CheckDelay3[id] = get_gametime()
}
}
if(get_gametime() - 0.25 > thb_CheckDelay2[id])
{
static thb_Body, thb_Target; get_user_aiming(id, thb_Target, thb_Body, 99999)
if(thb_g_Zoom[id] == thb_ZOOM_ACT)
{
if(thb_Get_BitVar(thb_g_IsAlive, thb_Target))
{
emit_sound(id, CHAN_WEAPON, thb_WeaponSounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
set_pev(id, pev_viewmodel2, thb_SNIP_MODEL_R)
} else {
set_pev(id, pev_viewmodel2, thb_SNIP_MODEL_B)
}
}
thb_CheckDelay2[id] = get_gametime()
}
return FMRES_IGNORED;
}
public thb_Activate_Zoom(id, thb_Level)
{
switch(thb_Level)
{
case thb_ZOOM_NONE:
{
thb_g_Zoom[id] = thb_Level
set_pev(id, pev_viewmodel2, thb_V_MODEL)
}
case thb_ZOOM_ACT:
{
thb_g_Zoom[id] = thb_Level
set_pev(id, pev_viewmodel2, thb_SNIP_MODEL_B)
emit_sound(id, CHAN_WEAPON, thb_WeaponSounds[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
default:
{
thb_g_Zoom[id] = thb_ZOOM_NONE
thb_Set_UserFov(id, 90)
set_pev(id, pev_viewmodel2, thb_V_MODEL)
}
}
}
public thb_fw_EmitSound(id, channel, const sample[], Float:volume, Float:thb_attn, flags, pitch)
{
if(!thb_Get_BitVar(thb_g_IsAlive, id))
return FMRES_IGNORED
if(!thb_Get_BitVar(thb_g_TempAttack, id))
return FMRES_IGNORED
if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
{
if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
return FMRES_SUPERCEDE
if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
{
if (sample[17] == 'w')  return FMRES_SUPERCEDE
else  return FMRES_SUPERCEDE
}
if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
return FMRES_SUPERCEDE;
}
return FMRES_IGNORED
}
public thb_fw_TraceLine(Float:thb_vector_start[3], Float:thb_vector_end[3], thb_ignored_monster, id, handle)
{
if(!thb_Get_BitVar(thb_g_IsAlive, id))
return FMRES_IGNORED
if(!thb_Get_BitVar(thb_g_TempAttack, id))
return FMRES_IGNORED
static Float:thb_vecStart[3], Float:thb_vecEnd[3], Float:thb_v_angle[3], Float:thb_v_forward[3], Float:view_ofs[3], Float:thb_fOrigin[3]
pev(id, pev_origin, thb_fOrigin)
pev(id, pev_view_ofs, view_ofs)
xs_vec_add(thb_fOrigin, view_ofs, thb_vecStart)
pev(id, pev_v_angle, thb_v_angle)
engfunc(EngFunc_MakeVectors, thb_v_angle)
get_global_vector(GL_v_forward, thb_v_forward)
xs_vec_mul_scalar(thb_v_forward, 0.0, thb_v_forward)
xs_vec_add(thb_vecStart, thb_v_forward, thb_vecEnd)
engfunc(EngFunc_TraceLine, thb_vecStart, thb_vecEnd, thb_ignored_monster, id, handle)
return FMRES_SUPERCEDE
}
public thb_fw_TraceHull(Float:thb_vector_start[3], Float:thb_vector_end[3], thb_ignored_monster, hull, id, handle)
{
if(!thb_Get_BitVar(thb_g_IsAlive, id))
return FMRES_IGNORED
if(!thb_Get_BitVar(thb_g_TempAttack, id))
return FMRES_IGNORED
static Float:thb_vecStart[3], Float:thb_vecEnd[3], Float:thb_v_angle[3], Float:thb_v_forward[3], Float:view_ofs[3], Float:thb_fOrigin[3]
pev(id, pev_origin, thb_fOrigin)
pev(id, pev_view_ofs, view_ofs)
xs_vec_add(thb_fOrigin, view_ofs, thb_vecStart)
pev(id, pev_v_angle, thb_v_angle)
engfunc(EngFunc_MakeVectors, thb_v_angle)
get_global_vector(GL_v_forward, thb_v_forward)
xs_vec_mul_scalar(thb_v_forward, 0.0, thb_v_forward)
xs_vec_add(thb_vecStart, thb_v_forward, thb_vecEnd)
engfunc(EngFunc_TraceHull, thb_vecStart, thb_vecEnd, thb_ignored_monster, hull, id, handle)
return FMRES_SUPERCEDE
}
public thb_fw_PlayerSpawn_Post(id) thb_Set_BitVar(thb_g_IsAlive, id)
public thb_fw_AddToPlayer_Post(ent, id)
{
if(id>=1 && id<=32 && !thb_g_VexGiving[id]) thb_UnSet_BitVar(thb_g_Had_Thunderbolt, id);
if(id<1 || id>32 || !is_user_connected(id)) return HAM_IGNORED;
if(pev(ent, pev_impulse) == thb_WEAPON_SECRETCODE)
{
thb_Set_BitVar(thb_g_Had_Thunderbolt, id)
cs_set_user_bpammo(id, thb_CSW_THUNDERBOLT, pev(ent, pev_iuser4))
set_pev(ent, pev_impulse, 0)
}
message_begin(MSG_ONE_UNRELIABLE, thb_g_Msg_WeaponList, _, id)
write_string((thb_Get_BitVar(thb_g_Had_Thunderbolt, id) ? "weapon_sfsniperF" : "weapon_awp"))
write_byte(1)
write_byte(30)
write_byte(-1)
write_byte(-1)
write_byte(0)
write_byte(2)
write_byte(thb_CSW_THUNDERBOLT)
write_byte(0)
message_end()
return HAM_IGNORED;
}
public thb_fw_Item_Deploy_Post(thb_Ent)
{
if(pev_valid(thb_Ent) != 2)
return
static thb_Id; thb_Id = get_pdata_cbase(thb_Ent, 41, 4)
if(get_pdata_cbase(thb_Id, 373) != thb_Ent)
return
if(!thb_Get_BitVar(thb_g_Had_Thunderbolt, thb_Id))
return
set_pev(thb_Id, pev_viewmodel2, thb_V_MODEL)
set_pev(thb_Id, pev_weaponmodel2, thb_P_MODEL)
thb_Set_WeaponAnim(thb_Id, thb_TB_ANIM_DRAW)
remove_task( (thb_Id+111) + ZC_TOFF_THB)
}
public thb_fw_Weapon_WeaponIdle_Post(thb_Ent)
{
if(pev_valid(thb_Ent) != 2)
return HAM_IGNORED
static thb_Id; thb_Id = get_pdata_cbase(thb_Ent, 41, 4)
if(get_pdata_cbase(thb_Id, 373) != thb_Ent)
return HAM_IGNORED
if(!thb_Get_BitVar(thb_g_Had_Thunderbolt, thb_Id))
return HAM_IGNORED
if(get_pdata_float(thb_Ent, 48, 4) <= 0.1)
{
thb_Set_WeaponAnim(thb_Id, thb_TB_ANIM_IDLE)
set_pdata_float(thb_Ent, 48, 20.0, 4)
}
return HAM_IGNORED
}
public thb_fw_Weapon_SecondaryAttack(thb_Ent)
{
static thb_Id; thb_Id = get_pdata_cbase(thb_Ent, 41, 4)
if(!thb_Get_BitVar(thb_g_Had_Thunderbolt, thb_Id))
return HAM_IGNORED
return HAM_SUPERCEDE
}
public thb_Thunderbolt_Shooting(id)
{
if(cs_get_user_bpammo(id, thb_CSW_THUNDERBOLT) <= 0)
return
thb_Set_BitVar(thb_g_TempAttack, id)
static thb_Ent; thb_Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
if(pev_valid(thb_Ent)) ExecuteHamB(Ham_Weapon_PrimaryAttack, thb_Ent)
thb_UnSet_BitVar(thb_g_TempAttack, id)
cs_set_user_bpammo(id, thb_CSW_THUNDERBOLT, cs_get_user_bpammo(id, thb_CSW_THUNDERBOLT) - 1)
set_pev(id, pev_viewmodel2, thb_V_MODEL)
set_task(thb_RELOAD_TIME - 0.15, "thb_Set_SniperModel", (id+111) + ZC_TOFF_THB)
thb_Set_WeaponAnim(id, thb_TB_ANIM_SHOOT)
emit_sound(id, CHAN_WEAPON, thb_WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
thb_Make_FakePunch(id)
thb_Ent = fm_get_user_weapon_entity(id, thb_CSW_THUNDERBOLT)
if(pev_valid(thb_Ent))
{
set_pdata_float(id, 83, thb_RELOAD_TIME, 5)
set_pdata_float(thb_Ent, 46, thb_RELOAD_TIME, 4)
set_pdata_float(thb_Ent, 47, thb_RELOAD_TIME, 4)
set_pdata_float(thb_Ent, 48, thb_RELOAD_TIME + 0.25, 4)
}
thb_Check_Damage(id)
set_pdata_float(id, 111, 0.0)
}
public thb_Set_SniperModel(id)
{ if (id >= ZC_TOFF_THB && id < ZC_TOFF_THB + 0x1000000) id -= ZC_TOFF_THB;
id -= 111
if(!is_user_alive(id))
return
if(!thb_Get_BitVar(thb_g_Had_Thunderbolt, id))
return
if(thb_g_Zoom[id] != thb_ZOOM_ACT)
return
thb_g_Zoom[id] = thb_ZOOM_ACT
set_pev(id, pev_viewmodel2, thb_SNIP_MODEL_B)
}
public thb_Make_FakePunch(id)
{
static Float:thb_PunchAngles[3]
thb_PunchAngles[0] = random_float(-3.5, -7.0)
set_pev(id, pev_punchangle, thb_PunchAngles)
}
public thb_Check_Damage(id)
{
static Float:thb_StartOrigin[3], Float:thb_EndOrigin[3], Float:thb_EndOrigin2[3]
thb_Stock_Get_Postion(id, 40.0, 7.5, -5.0, thb_StartOrigin)
thb_Stock_Get_Postion(id, 4096.0, 0.0, 0.0, thb_EndOrigin)
static thb_TrResult; thb_TrResult = create_tr2()
engfunc(EngFunc_TraceLine, thb_StartOrigin, thb_EndOrigin, IGNORE_MONSTERS, id, thb_TrResult)
get_tr2(thb_TrResult, TR_vecEndPos, thb_EndOrigin2)
free_tr2(thb_TrResult)
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_BEAMPOINTS)
engfunc(EngFunc_WriteCoord, thb_StartOrigin[0])
engfunc(EngFunc_WriteCoord, thb_StartOrigin[1])
engfunc(EngFunc_WriteCoord, thb_StartOrigin[2])
engfunc(EngFunc_WriteCoord, thb_EndOrigin2[0])
engfunc(EngFunc_WriteCoord, thb_EndOrigin2[1])
engfunc(EngFunc_WriteCoord, thb_EndOrigin2[2])
write_short(thb_g_Beam_SprId)
write_byte(0)
write_byte(0)
write_byte(10)
write_byte(25)
write_byte(0)
write_byte(0)
write_byte(0)
write_byte(200)
write_byte(200)
write_byte(0)
message_end()
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_SPARKS)
engfunc(EngFunc_WriteCoord, thb_EndOrigin2[0])
engfunc(EngFunc_WriteCoord, thb_EndOrigin2[1])
engfunc(EngFunc_WriteCoord, thb_EndOrigin2[2])
message_end()
thb_DealDamage(id, thb_StartOrigin, thb_EndOrigin2)
}
public thb_DealDamage(id, Float:thb_Start[3], Float:thb_End[3])
{
static thb_TrResult; thb_TrResult = create_tr2()
engfunc(EngFunc_TraceLine, thb_Start, thb_End, DONT_IGNORE_MONSTERS, id, thb_TrResult)
new thb_pHit1; thb_pHit1 = get_tr2(thb_TrResult, TR_pHit)
static Float:thb_End1[3]; get_tr2(thb_TrResult, TR_vecEndPos, thb_End1)
if(is_user_alive(thb_pHit1))
{
thb_do_attack(id, thb_pHit1, 0, float(thb_DAMAGE) * 1.5)
engfunc(EngFunc_TraceLine, thb_End1, thb_End, DONT_IGNORE_MONSTERS, thb_pHit1, thb_TrResult)
} else engfunc(EngFunc_TraceLine, thb_End1, thb_End, DONT_IGNORE_MONSTERS, -1, thb_TrResult)
new thb_pHit2; thb_pHit2 = get_tr2(thb_TrResult, TR_pHit)
static Float:thb_End2[3]; get_tr2(thb_TrResult, TR_vecEndPos, thb_End2)
if(is_user_alive(thb_pHit2))
{
thb_do_attack(id, thb_pHit2, 0, float(thb_DAMAGE) * 1.5)
engfunc(EngFunc_TraceLine, thb_End2, thb_End, DONT_IGNORE_MONSTERS, thb_pHit2, thb_TrResult)
} else engfunc(EngFunc_TraceLine, thb_End2, thb_End, DONT_IGNORE_MONSTERS, -1, thb_TrResult)
new thb_pHit3; thb_pHit3 = get_tr2(thb_TrResult, TR_pHit)
static Float:thb_End3[3]; get_tr2(thb_TrResult, TR_vecEndPos, thb_End3)
if(is_user_alive(thb_pHit3))
{
thb_do_attack(id, thb_pHit3, 0, float(thb_DAMAGE) * 1.5)
engfunc(EngFunc_TraceLine, thb_End3, thb_End, DONT_IGNORE_MONSTERS, thb_pHit3, thb_TrResult)
} else engfunc(EngFunc_TraceLine, thb_End3, thb_End, DONT_IGNORE_MONSTERS, -1, thb_TrResult)
new thb_pHit4; thb_pHit4 = get_tr2(thb_TrResult, TR_pHit)
if(is_user_alive(thb_pHit4)) thb_do_attack(id, thb_pHit4, 0, float(thb_DAMAGE) * 1.5)
free_tr2(thb_TrResult)
}
public thb_UpdateAmmo(thb_Id, thb_Ammo, thb_BpAmmo)
{
static thb_weapon_ent; thb_weapon_ent = fm_get_user_weapon_entity(thb_Id, thb_CSW_THUNDERBOLT)
if(pev_valid(thb_weapon_ent))
{
if(thb_BpAmmo > 0) cs_set_weapon_ammo(thb_weapon_ent, 1)
else cs_set_weapon_ammo(thb_weapon_ent, 0)
}
engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, thb_g_Msg_CurWeapon, {0, 0, 0}, thb_Id)
write_byte(1)
write_byte(thb_CSW_THUNDERBOLT)
write_byte(-1)
message_end()
message_begin(MSG_ONE_UNRELIABLE, thb_g_Msg_AmmoX, _, thb_Id)
write_byte(1)
write_byte(thb_BpAmmo)
message_end()
cs_set_user_bpammo(thb_Id, thb_CSW_THUNDERBOLT, thb_BpAmmo)
}
stock thb_Set_WeaponAnim(id, thb_anim)
{
set_pev(id, pev_weaponanim, thb_anim)
message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
write_byte(thb_anim)
write_byte(pev(id, pev_body))
message_end()
}
stock thb_Stock_Get_Postion(id,Float:thb_forw,Float:right, Float:up,Float:thb_vStart[])
{
static Float:thb_vOrigin[3], Float:thb_vAngle[3], Float:thb_vForward[3], Float:thb_vRight[3], Float:thb_vUp[3]
pev(id, pev_origin, thb_vOrigin)
pev(id, pev_view_ofs,thb_vUp)
xs_vec_add(thb_vOrigin,thb_vUp,thb_vOrigin)
pev(id, pev_v_angle, thb_vAngle)
angle_vector(thb_vAngle,ANGLEVECTOR_FORWARD,thb_vForward)
angle_vector(thb_vAngle,ANGLEVECTOR_RIGHT,thb_vRight)
angle_vector(thb_vAngle,ANGLEVECTOR_UP,thb_vUp)
thb_vStart[0] = thb_vOrigin[0] + thb_vForward[0] * thb_forw + thb_vRight[0] * right + thb_vUp[0] * up
thb_vStart[1] = thb_vOrigin[1] + thb_vForward[1] * thb_forw + thb_vRight[1] * right + thb_vUp[1] * up
thb_vStart[2] = thb_vOrigin[2] + thb_vForward[2] * thb_forw + thb_vRight[2] * right + thb_vUp[2] * up
}
thb_do_attack(thb_Attacker, thb_Victim, thb_Inflictor, Float:thb_fDamage)
{
thb_fake_player_trace_attack(thb_Attacker, thb_Victim, thb_fDamage)
thb_fake_take_damage(thb_Attacker, thb_Victim, thb_fDamage, thb_Inflictor)
}
thb_fake_player_trace_attack(thb_iAttacker, thb_iVictim, &Float:thb_fDamage)
{
new Float:thb_fAngles[3], Float:thb_fDirection[3]
pev(thb_iAttacker, pev_angles, thb_fAngles)
angle_vector(thb_fAngles, ANGLEVECTOR_FORWARD, thb_fDirection)
new Float:fStart[3], Float:thb_fViewOfs[3]
pev(thb_iAttacker, pev_origin, fStart)
pev(thb_iAttacker, pev_view_ofs, thb_fViewOfs)
xs_vec_add(thb_fViewOfs, fStart, fStart)
new thb_iAimOrigin[3], Float:thb_fAimOrigin[3]
get_user_origin(thb_iAttacker, thb_iAimOrigin, 3)
IVecFVec(thb_iAimOrigin, thb_fAimOrigin)
new ptr; ptr = create_tr2()
engfunc(EngFunc_TraceLine, fStart, thb_fAimOrigin, DONT_IGNORE_MONSTERS, thb_iAttacker, ptr)
new thb_pHit; thb_pHit = get_tr2(ptr, TR_pHit)
new thb_iHitgroup; thb_iHitgroup = get_tr2(ptr, TR_iHitgroup)
new Float:thb_fEndPos[3]
get_tr2(ptr, TR_vecEndPos, thb_fEndPos)
new thb_iTarget, thb_iBody
get_user_aiming(thb_iAttacker, thb_iTarget, thb_iBody)
if (thb_iTarget == thb_iVictim)
{
thb_iHitgroup = thb_iBody
}
else if (thb_pHit != thb_iVictim)
{
new Float:thb_fVicOrigin[3], Float:thb_fVicViewOfs[3], Float:thb_fAimInVictim[3]
pev(thb_iVictim, pev_origin, thb_fVicOrigin)
pev(thb_iVictim, pev_view_ofs, thb_fVicViewOfs)
xs_vec_add(thb_fVicViewOfs, thb_fVicOrigin, thb_fAimInVictim)
thb_fAimInVictim[2] = fStart[2]
thb_fAimInVictim[2] += get_distance_f(fStart, thb_fAimInVictim) * floattan( thb_fAngles[0] * 2.0, degrees )
new thb_iAngleToVictim; thb_iAngleToVictim = thb_get_angle_to_target(thb_iAttacker, thb_fVicOrigin)
thb_iAngleToVictim = abs(thb_iAngleToVictim)
new Float:thb_fDis; thb_fDis = 2.0 * get_distance_f(fStart, thb_fAimInVictim) * floatsin( float(thb_iAngleToVictim) * 0.5, degrees )
new Float:thb_fVicSize[3]
pev(thb_iVictim, pev_size , thb_fVicSize)
if ( thb_fDis <= thb_fVicSize[0] * 0.5 )
{
new thb_ptr2; thb_ptr2 = create_tr2()
engfunc(EngFunc_TraceLine, fStart, thb_fAimInVictim, DONT_IGNORE_MONSTERS, thb_iAttacker, thb_ptr2)
new thb_pHit2; thb_pHit2 = get_tr2(thb_ptr2, TR_pHit)
new thb_iHitgroup2; thb_iHitgroup2 = get_tr2(thb_ptr2, TR_iHitgroup)
if ( thb_pHit2 == thb_iVictim && (thb_iHitgroup2 != HIT_HEAD || thb_fDis <= thb_fVicSize[0] * 0.25) )
{
thb_pHit = thb_iVictim
thb_iHitgroup = thb_iHitgroup2
get_tr2(thb_ptr2, TR_vecEndPos, thb_fEndPos)
}
free_tr2(thb_ptr2)
}
if (thb_pHit != thb_iVictim)
{
thb_iHitgroup = HIT_GENERIC
new thb_ptr3; thb_ptr3 = create_tr2()
engfunc(EngFunc_TraceLine, fStart, thb_fVicOrigin, DONT_IGNORE_MONSTERS, thb_iAttacker, thb_ptr3)
get_tr2(thb_ptr3, TR_vecEndPos, thb_fEndPos)
free_tr2(thb_ptr3)
}
}
set_tr2(ptr, TR_pHit, thb_iVictim)
set_tr2(ptr, TR_iHitgroup, thb_iHitgroup)
set_tr2(ptr, TR_vecEndPos, thb_fEndPos)
thb_fake_trake_attack(thb_iAttacker, thb_iVictim, thb_fDamage, thb_fDirection, ptr)
free_tr2(ptr)
}
stock thb_fake_trake_attack(thb_iAttacker, thb_iVictim, Float:thb_fDamage, Float:thb_fDirection[3], thb_iTraceHandle, thb_iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
ExecuteHamB(Ham_TraceAttack, thb_iVictim, thb_iAttacker, thb_fDamage, thb_fDirection, thb_iTraceHandle, thb_iDamageBit)
}
stock thb_fake_take_damage(thb_iAttacker, thb_iVictim, Float:thb_fDamage, thb_iInflictor, thb_iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
ExecuteHamB(Ham_TakeDamage, thb_iVictim, thb_iInflictor, thb_iAttacker, thb_fDamage, thb_iDamageBit)
}
stock thb_get_angle_to_target(id, const Float:thb_fTarget[3], Float:thb_TargetSize = 0.0)
{
new Float:thb_fOrigin[3], thb_iAimOrigin[3], Float:thb_fAimOrigin[3], Float:thb_fV1[3]
pev(id, pev_origin, thb_fOrigin)
get_user_origin(id, thb_iAimOrigin, 3)
IVecFVec(thb_iAimOrigin, thb_fAimOrigin)
xs_vec_sub(thb_fAimOrigin, thb_fOrigin, thb_fV1)
new Float:thb_fV2[3]
xs_vec_sub(thb_fTarget, thb_fOrigin, thb_fV2)
new thb_iResult; thb_iResult = thb_get_angle_between_vectors(thb_fV1, thb_fV2)
if (thb_TargetSize > 0.0)
{
new Float:thb_fTan; thb_fTan = thb_TargetSize / get_distance_f(thb_fOrigin, thb_fTarget)
new thb_fAngleToTargetSize; thb_fAngleToTargetSize = floatround( floatatan(thb_fTan, degrees) )
thb_iResult -= (thb_iResult > 0) ? thb_fAngleToTargetSize : -thb_fAngleToTargetSize
}
return thb_iResult
}
stock thb_get_angle_between_vectors(const Float:thb_fV1[3], const Float:thb_fV2[3])
{
new Float:thb_fA1[3], Float:thb_fA2[3]
engfunc(EngFunc_VecToAngles, thb_fV1, thb_fA1)
engfunc(EngFunc_VecToAngles, thb_fV2, thb_fA2)
new thb_iResult; thb_iResult = floatround(thb_fA1[1] - thb_fA2[1])
thb_iResult = thb_iResult % 360
thb_iResult = (thb_iResult > 180) ? (thb_iResult - 360) : thb_iResult
return thb_iResult
}
stock thb_Set_UserFov(id, thb_FOV)
{
if(!is_user_connected(id))
return
set_pdata_int(id, 363, thb_FOV, 5)
set_pev(id, pev_fov, thb_FOV)
}
public thb_vex_give(id) { if (!is_user_alive(id) || vx45_corezombie(id)) return 0; thb_g_VexGiving[id]=true; thb_Get_Thunderbolt(id); thb_g_VexGiving[id]=false; return thb_vex_has(id) && user_has_weapon(id,CSW_AWP); }
public thb_vex_remove(id) { thb_Remove_Thunderbolt(id); return 1; }
public thb_vex_has(id) { return thb_Get_BitVar(thb_g_Had_Thunderbolt, id) ? 1 : 0; }
#define eth_PLUGIN "[CSO] Ethereal"
#define eth_VERSION "1.0"
#define eth_AUTHOR "Dias Pendragon"
#define eth_DAMAGE 26
#define eth_CLIP 30
#define eth_SPEED 1.0
#define eth_RECOIL 0.75
#define eth_CSW_ETHEREAL CSW_M4A1
#define eth_weapon_ethereal "weapon_m4a1"
#define eth_PLAYER_ANIMEXT "carbine"
#define eth_ETHEREAL_OLDMODEL "models/vexmira_ze/skins/vexmira_w_m4a1.mdl"
#define eth_V_MODEL "models/v_ethereal2.mdl"
#define eth_P_MODEL "models/p_ethereal.mdl"
#define eth_W_MODEL "models/w_ethereal.mdl"
new const eth_Ethereal_Sounds[4][] =
{
"weapons/ethereal-1.wav",
"weapons/ethereal_draw.wav",
"weapons/ethereal_idle1.wav",
"weapons/ethereal_reload.wav"
}
new const eth_Ethereal_Resources[3][] =
{
"sprites/weapon_ethereal.txt",
"sprites/vex_community/ethereal/640hud7_2.spr",
"sprites/vex_community/ethereal/640hud74_2.spr"
}
#define eth_MUZZLE_FLASH "sprites/vex_community/ethereal/muzzleflash7.spr"
enum
{
eth_E_ANIM_IDLE = 0,
eth_E_ANIM_RELOAD,
eth_E_ANIM_DRAW,
eth_E_ANIM_SHOOT1,
eth_E_ANIM_SHOOT2,
eth_E_ANIM_SHOOT3
}
#define eth_Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define eth_Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define eth_UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
const eth_PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const eth_SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
new eth_g_Had_Ethereal, eth_g_Ethereal_Clip[33], Float:eth_g_Recoil[33][3]
new eth_g_Event_Ethereal, eth_g_Msg_WeaponList, eth_g_SmokePuff_SprId, eth_g_ham_bot, eth_g_Beam_SprID
new eth_g_Muzzleflash_Ent, eth_g_Muzzleflash
new bool:eth_g_VexGiving[33];
public eth_plugin_init()
{
g_zcEvCurWeapon |= (1<<3)
g_zcFm[ZCFM_UpdateClientData_P] |= (1<<3)
g_zcFm[ZCFM_PlaybackEvent] |= (1<<3)
g_zcFm[ZCFM_SetModel] |= (1<<3)
g_zcFm[ZCFM_CmdStart] |= (1<<3)
register_forward(FM_AddToFullPack, "eth_fw_AddToFullPack_post", 1)
register_forward(FM_CheckVisibility, "eth_fw_CheckVisibility")
VxRegisterHam524(Ham_Weapon_WeaponIdle, eth_weapon_ethereal, "eth_fw_Weapon_WeaponIdle_Post", 1)
VxRegisterHam524(Ham_Weapon_PrimaryAttack, eth_weapon_ethereal, "eth_fw_Weapon_PrimaryAttack")
VxRegisterHam524(Ham_Weapon_PrimaryAttack, eth_weapon_ethereal, "eth_fw_Weapon_PrimaryAttack_49b", 1)
VxRegisterHam524(Ham_Item_Deploy, eth_weapon_ethereal, "eth_fw_Item_Deploy_Post", 1)
VxRegisterHam524(Ham_Item_AddToPlayer, eth_weapon_ethereal, "eth_fw_Item_AddToPlayer_Post", 1)
VxRegisterHam524(Ham_Item_PostFrame, eth_weapon_ethereal, "eth_fw_Item_PostFrame")
VxRegisterHam524(Ham_Weapon_Reload, eth_weapon_ethereal, "eth_fw_Weapon_Reload")
VxRegisterHam524(Ham_Weapon_Reload, eth_weapon_ethereal, "eth_fw_Weapon_Reload_Post", 1)
VxRegisterHam524(Ham_TraceAttack, "worldspawn", "eth_fw_TraceAttack_World")
VxRegisterHam524(Ham_TraceAttack, "player", "eth_fw_TraceAttack_Player")
eth_g_Msg_WeaponList = get_user_msgid("WeaponList")
register_clcmd("weapon_ethereal", "eth_Hook_Weapon")
}
public eth_plugin_precache()
{
if (!VexAssetGuard("vx42_ethereal")) return;
ZcPcModel(eth_V_MODEL)
ZcPcModel(eth_P_MODEL)
ZcPcModel(eth_W_MODEL)
new i
for(i = 0; i < sizeof(eth_Ethereal_Sounds); i++)
VexPcSnd(eth_Ethereal_Sounds[i], (i==0) ? true : false)
for(i = 0; i < sizeof(eth_Ethereal_Resources); i++)
{
if(i == 0) ZcPcGeneric(eth_Ethereal_Resources[i])
else ZcPcModel(eth_Ethereal_Resources[i])
}
eth_g_SmokePuff_SprId = ZcPcModel("sprites/wall_puff1.spr")
eth_g_Beam_SprID = ZcPcModel("sprites/laserbeam.spr")
register_forward(FM_PrecacheEvent, "eth_fw_PrecacheEvent_Post", 1)
eth_g_Muzzleflash_Ent = GearCreate51("info_target")
ZcPcModel(eth_MUZZLE_FLASH)
VxSM(eth_g_Muzzleflash_Ent, eth_MUZZLE_FLASH)
set_pev(eth_g_Muzzleflash_Ent, pev_scale, 0.2)
set_pev(eth_g_Muzzleflash_Ent, pev_rendermode, kRenderTransTexture)
set_pev(eth_g_Muzzleflash_Ent, pev_renderamt, 0.0)
}
public eth_fw_PrecacheEvent_Post(type, const name[])
{
if(equal("events/m4a1.sc", name)) eth_g_Event_Ethereal = get_orig_retval()
}
public eth_client_putinserver(id)
{
if(!eth_g_ham_bot && is_user_bot(id))
{
eth_g_ham_bot = 1
set_task(0.1, "eth_Do_Register_HamBot", (id) + ZC_TOFF_ETH)
}
}
public eth_Do_Register_HamBot(id)
{ if (id >= ZC_TOFF_ETH && id < ZC_TOFF_ETH + 0x1000000) id -= ZC_TOFF_ETH;
RegisterHamFromEntity(Ham_TraceAttack, id, "eth_fw_TraceAttack_Player")
}
public eth_Get_Ethereal(id)
{
eth_Set_BitVar(eth_g_Had_Ethereal, id)
fm_give_item(id, eth_weapon_ethereal)
eth_Give_RealAmmo(id, eth_CSW_ETHEREAL)
engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
write_byte(1)
write_byte(CSW_M4A1)
write_byte(30)
message_end()
}
public eth_Remove_Ethereal(id)
{
eth_UnSet_BitVar(eth_g_Had_Ethereal, id)
}
public eth_Hook_Weapon(id)
{
engclient_cmd(id, eth_weapon_ethereal)
return PLUGIN_HANDLED
}
public eth_Event_CurWeapon(id)
{
if(!eth_Get_BitVar(eth_g_Had_Ethereal, id))
return
static Float:eth_Delay, Float:eth_Delay2
static eth_Ent; eth_Ent = fm_get_user_weapon_entity(id, eth_CSW_ETHEREAL)
if(!pev_valid(eth_Ent)) return
eth_Delay = get_pdata_float(eth_Ent, 46, 4) * eth_SPEED
eth_Delay2 = get_pdata_float(eth_Ent, 47, 4) * eth_SPEED
if(eth_Delay > 0.0)
{
set_pdata_float(eth_Ent, 46, eth_Delay, 4)
set_pdata_float(eth_Ent, 47, eth_Delay2, 4)
}
}
public eth_fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
if(!is_user_alive(id) || !is_user_connected(id))
return FMRES_IGNORED
if(get_user_weapon(id) == eth_CSW_ETHEREAL && eth_Get_BitVar(eth_g_Had_Ethereal, id))
set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001)
return FMRES_HANDLED
}
public eth_fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, eth_iParam1, eth_iParam2, eth_bParam1, eth_bParam2)
{
if (!is_user_connected(invoker))
return FMRES_IGNORED
if(get_user_weapon(invoker) != eth_CSW_ETHEREAL || !eth_Get_BitVar(eth_g_Had_Ethereal, invoker))
return FMRES_IGNORED
if(eventid != eth_g_Event_Ethereal)
return FMRES_IGNORED
engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, eth_iParam1, eth_iParam2, eth_bParam1, eth_bParam2)
eth_set_weapon_anim(invoker, eth_E_ANIM_SHOOT1)
emit_sound(invoker, CHAN_WEAPON, eth_Ethereal_Sounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
return FMRES_IGNORED
}
public eth_fw_SetModel(entity, model[])
{
if(!pev_valid(entity))
return FMRES_IGNORED
static Classname[32]
pev(entity, pev_classname, Classname, sizeof(Classname))
if(!equal(Classname, "weaponbox"))
return FMRES_IGNORED
static iOwner
iOwner = pev(entity, pev_owner)
if(equal(model, eth_ETHEREAL_OLDMODEL))
{
static weapon; weapon = fm_find_ent_by_owner(-1, eth_weapon_ethereal, entity)
if(!pev_valid(weapon))
return FMRES_IGNORED;
if(eth_Get_BitVar(eth_g_Had_Ethereal, iOwner))
{
eth_Remove_Ethereal(iOwner)
set_pev(weapon, pev_impulse, 1712015)
VxSM(entity, eth_W_MODEL)
return FMRES_SUPERCEDE
}
}
return FMRES_IGNORED;
}
public eth_fw_CmdStart(id, uc_handle, seed)
{
if(!is_user_alive(id))
return FMRES_IGNORED
if(!eth_Get_BitVar(eth_g_Had_Ethereal, id) || get_user_weapon(id) != eth_CSW_ETHEREAL)
return FMRES_IGNORED
static eth_PressButton; eth_PressButton = get_uc(uc_handle, UC_Buttons)
if((eth_PressButton & IN_ATTACK2))
{
eth_PressButton &= ~IN_ATTACK2
set_uc(uc_handle, UC_Buttons, eth_PressButton)
}
return FMRES_IGNORED
}
public eth_fw_AddToFullPack_post(eth_esState, eth_iE, eth_iEnt, eth_iHost, eth_iHostFlags, eth_iPlayer, eth_pSet)
{
if(eth_iEnt != eth_g_Muzzleflash_Ent)
return
if(eth_Get_BitVar(eth_g_Muzzleflash, eth_iHost))
{
set_es(eth_esState, ES_Frame, float(random_num(0, 2)))
set_es(eth_esState, ES_RenderMode, kRenderTransAdd)
set_es(eth_esState, ES_RenderAmt, 255.0)
eth_UnSet_BitVar(eth_g_Muzzleflash, eth_iHost)
}
set_es(eth_esState, ES_Skin, eth_iHost)
set_es(eth_esState, ES_Body, 1)
set_es(eth_esState, ES_AimEnt, eth_iHost)
set_es(eth_esState, ES_MoveType, MOVETYPE_FOLLOW)
}
public eth_fw_CheckVisibility(iEntity, eth_pSet)
{
if (iEntity != eth_g_Muzzleflash_Ent)
return FMRES_IGNORED
forward_return(FMV_CELL, 1)
return FMRES_SUPERCEDE
}
public eth_fw_Weapon_PrimaryAttack(eth_Ent)
{
static id; id = pev(eth_Ent, pev_owner)
pev(id, pev_punchangle, eth_g_Recoil[id])
return HAM_IGNORED
}
public eth_fw_Weapon_PrimaryAttack_49b(eth_Ent)
{
static id; id = pev(eth_Ent, pev_owner)
if(eth_Get_BitVar(eth_g_Had_Ethereal, id))
{
static Float:eth_Push[3]
pev(id, pev_punchangle, eth_Push)
xs_vec_sub(eth_Push, eth_g_Recoil[id], eth_Push)
xs_vec_mul_scalar(eth_Push, eth_RECOIL, eth_Push)
xs_vec_add(eth_Push, eth_g_Recoil[id], eth_Push)
set_pev(id, pev_punchangle, eth_Push)
eth_Event_CurWeapon(id)
eth_Set_BitVar(eth_g_Muzzleflash, id)
}
}
public eth_fw_Weapon_WeaponIdle_Post(eth_Ent)
{
if(pev_valid(eth_Ent) != 2)
return HAM_IGNORED
static eth_Id; eth_Id = get_pdata_cbase(eth_Ent, 41, 4)
if(get_pdata_cbase(eth_Id, 373) != eth_Ent)
return HAM_IGNORED
if(!eth_Get_BitVar(eth_g_Had_Ethereal, eth_Id))
return HAM_IGNORED
if(get_pdata_float(eth_Ent, 48, 4) <= 0.1)
{
eth_set_weapon_anim(eth_Id, eth_E_ANIM_IDLE)
set_pdata_float(eth_Ent, 48, 20.0, 4)
set_pdata_string(eth_Id, (492) * 4, eth_PLAYER_ANIMEXT, -1 , 20)
}
return HAM_IGNORED
}
public eth_fw_Item_Deploy_Post(eth_Ent)
{
if(pev_valid(eth_Ent) != 2)
return
static eth_Id; eth_Id = get_pdata_cbase(eth_Ent, 41, 4)
if(get_pdata_cbase(eth_Id, 373) != eth_Ent)
return
if(!eth_Get_BitVar(eth_g_Had_Ethereal, eth_Id))
return
set_pev(eth_Id, pev_viewmodel2, eth_V_MODEL)
set_pev(eth_Id, pev_weaponmodel2, eth_P_MODEL)
eth_set_weapon_anim(eth_Id, eth_E_ANIM_DRAW)
}
public eth_fw_Item_AddToPlayer_Post(eth_Ent, id)
{
if(id>=1 && id<=32 && !eth_g_VexGiving[id]) eth_UnSet_BitVar(eth_g_Had_Ethereal, id);
if(id<1 || id>32 || !is_user_connected(id)) return HAM_IGNORED;
if(!pev_valid(eth_Ent))
return HAM_IGNORED
if(pev(eth_Ent, pev_impulse) == 1712015)
{
eth_Set_BitVar(eth_g_Had_Ethereal, id)
set_pev(eth_Ent, pev_impulse, 0)
}
message_begin(MSG_ONE_UNRELIABLE, eth_g_Msg_WeaponList, .player = id)
write_string(eth_Get_BitVar(eth_g_Had_Ethereal, id) ? "weapon_ethereal" : "weapon_m4a1")
write_byte(4)
write_byte(90)
write_byte(-1)
write_byte(-1)
write_byte(0)
write_byte(6)
write_byte(eth_Get_BitVar(eth_g_Had_Ethereal, id) ? eth_CSW_ETHEREAL : CSW_M4A1)
write_byte(0)
message_end()
return HAM_HANDLED
}
public eth_fw_Item_PostFrame(ent)
{
static id; id = pev(ent, pev_owner)
if(!is_user_alive(id))
return HAM_IGNORED
if(!eth_Get_BitVar(eth_g_Had_Ethereal, id))
return HAM_IGNORED
static Float:eth_flNextAttack; eth_flNextAttack = get_pdata_float(id, 83, 5)
static eth_bpammo; eth_bpammo = cs_get_user_bpammo(id, eth_CSW_ETHEREAL)
static eth_iClip; eth_iClip = get_pdata_int(ent, 51, 4)
static eth_fInReload; eth_fInReload = get_pdata_int(ent, 54, 4)
if(eth_fInReload && eth_flNextAttack <= 0.0)
{
static eth_temp1
eth_temp1 = min(eth_CLIP - eth_iClip, eth_bpammo)
set_pdata_int(ent, 51, eth_iClip + eth_temp1, 4)
cs_set_user_bpammo(id, eth_CSW_ETHEREAL, eth_bpammo - eth_temp1)
set_pdata_int(ent, 54, 0, 4)
eth_fInReload = 0
}
return HAM_IGNORED
}
public eth_fw_Weapon_Reload(ent)
{
static id; id = pev(ent, pev_owner)
if(!is_user_alive(id))
return HAM_IGNORED
if(!eth_Get_BitVar(eth_g_Had_Ethereal, id))
return HAM_IGNORED
eth_g_Ethereal_Clip[id] = -1
static eth_BPAmmo; eth_BPAmmo = cs_get_user_bpammo(id, eth_CSW_ETHEREAL)
static eth_iClip; eth_iClip = get_pdata_int(ent, 51, 4)
if(eth_BPAmmo <= 0)
return HAM_SUPERCEDE
if(eth_iClip >= eth_CLIP)
return HAM_SUPERCEDE
eth_g_Ethereal_Clip[id] = eth_iClip
return HAM_HANDLED
}
public eth_fw_Weapon_Reload_Post(ent)
{
static id; id = pev(ent, pev_owner)
if(!is_user_alive(id))
return HAM_IGNORED
if(!eth_Get_BitVar(eth_g_Had_Ethereal, id))
return HAM_IGNORED
if((get_pdata_int(ent, 54, 4) == 1))
{
if(eth_g_Ethereal_Clip[id] == -1)
return HAM_IGNORED
set_pdata_int(ent, 51, eth_g_Ethereal_Clip[id], 4)
eth_set_weapon_anim(id, eth_E_ANIM_RELOAD)
}
return HAM_HANDLED
}
public eth_fw_TraceAttack_World(eth_Victim, eth_Attacker, Float:Damage, Float:eth_Direction[3], eth_Ptr, eth_DamageBits)
{
if(!is_user_connected(eth_Attacker))
return HAM_IGNORED
if(get_user_weapon(eth_Attacker) != eth_CSW_ETHEREAL || !eth_Get_BitVar(eth_g_Had_Ethereal, eth_Attacker))
return HAM_IGNORED
static Float:eth_flEnd[3], Float:eth_vecPlane[3]
get_tr2(eth_Ptr, TR_vecEndPos, eth_flEnd)
get_tr2(eth_Ptr, TR_vecPlaneNormal, eth_vecPlane)
eth_Make_LaserLine(eth_Attacker, eth_flEnd)
eth_Make_BulletSmoke(eth_Attacker, eth_Ptr)
SetHamParamFloat(3, float(eth_DAMAGE))
return HAM_IGNORED
}
public eth_fw_TraceAttack_Player(eth_Victim, eth_Attacker, Float:Damage, Float:eth_Direction[3], eth_Ptr, eth_DamageBits)
{
if(!is_user_connected(eth_Attacker))
return HAM_IGNORED
if(get_user_weapon(eth_Attacker) != eth_CSW_ETHEREAL || !eth_Get_BitVar(eth_g_Had_Ethereal, eth_Attacker))
return HAM_IGNORED
SetHamParamFloat(3, float(eth_DAMAGE))
return HAM_IGNORED
}
public eth_Make_LaserLine(id, Float:Origin[3])
{
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte (TE_BEAMENTPOINT)
write_short(id | 0x1000)
engfunc(EngFunc_WriteCoord, Origin[0])
engfunc(EngFunc_WriteCoord, Origin[1])
engfunc(EngFunc_WriteCoord, Origin[2])
write_short(eth_g_Beam_SprID)
write_byte(1)
write_byte(5)
write_byte(1)
write_byte(2)
write_byte(0)
write_byte(0)
write_byte(125)
write_byte(255)
write_byte(200)
write_byte(200)
message_end()
}
public eth_Give_RealAmmo(id, eth_CSWID)
{
static eth_Amount, Max
switch(eth_CSWID)
{
case CSW_P228: {eth_Amount = 10; Max = 104;}
case CSW_SCOUT: {eth_Amount = 6; Max = 180;}
case CSW_XM1014: {eth_Amount = 8; Max = 64;}
case CSW_MAC10: {eth_Amount = 16; Max = 200;}
case CSW_AUG: {eth_Amount = 6; Max = 180;}
case CSW_ELITE: {eth_Amount = 16; Max = 200;}
case CSW_FIVESEVEN: {eth_Amount = 4; Max = 200;}
case CSW_UMP45: {eth_Amount = 16; Max = 200;}
case CSW_SG550: {eth_Amount = 6; Max = 180;}
case CSW_GALIL: {eth_Amount = 6; Max = 180;}
case CSW_FAMAS: {eth_Amount = 6; Max = 180;}
case CSW_USP: {eth_Amount = 18; Max = 200;}
case CSW_GLOCK18: {eth_Amount = 16; Max = 200;}
case CSW_AWP: {eth_Amount = 6; Max = 60;}
case CSW_MP5NAVY: {eth_Amount = 16; Max = 200;}
case CSW_M249: {eth_Amount = 4; Max = 200;}
case CSW_M3: {eth_Amount = 8; Max = 64;}
case CSW_M4A1: {eth_Amount = 7; Max = 180;}
case CSW_TMP: {eth_Amount = 7; Max = 200;}
case CSW_G3SG1: {eth_Amount = 7; Max = 180;}
case CSW_DEAGLE: {eth_Amount = 10; Max = 70;}
case CSW_SG552: {eth_Amount = 7; Max = 180;}
case CSW_AK47: {eth_Amount = 7; Max = 180;}
case CSW_P90: {eth_Amount = 4; Max = 200;}
default: {eth_Amount = 3; Max = 200;}
}
for(new i = 0; i < eth_Amount; i++) eth_give_ammo(id, 0, eth_CSWID, Max)
}
public eth_give_ammo(id, eth_silent, eth_CSWID, Max)
{
static eth_Amount, Name[32]
switch(eth_CSWID)
{
case CSW_P228: {eth_Amount = 13; formatex(Name, sizeof(Name), "357sig");}
case CSW_SCOUT: {eth_Amount = 30; formatex(Name, sizeof(Name), "762nato");}
case CSW_XM1014: {eth_Amount = 8; formatex(Name, sizeof(Name), "buckshot");}
case CSW_MAC10: {eth_Amount = 12; formatex(Name, sizeof(Name), "45acp");}
case CSW_AUG: {eth_Amount = 30; formatex(Name, sizeof(Name), "556nato");}
case CSW_ELITE: {eth_Amount = 30; formatex(Name, sizeof(Name), "9mm");}
case CSW_FIVESEVEN: {eth_Amount = 50; formatex(Name, sizeof(Name), "57mm");}
case CSW_UMP45: {eth_Amount = 12; formatex(Name, sizeof(Name), "45acp");}
case CSW_SG550: {eth_Amount = 30; formatex(Name, sizeof(Name), "556nato");}
case CSW_GALIL: {eth_Amount = 30; formatex(Name, sizeof(Name), "556nato");}
case CSW_FAMAS: {eth_Amount = 30; formatex(Name, sizeof(Name), "556nato");}
case CSW_USP: {eth_Amount = 12; formatex(Name, sizeof(Name), "45acp");}
case CSW_GLOCK18: {eth_Amount = 30; formatex(Name, sizeof(Name), "9mm");}
case CSW_AWP: {eth_Amount = 10; formatex(Name, sizeof(Name), "338magnum");}
case CSW_MP5NAVY: {eth_Amount = 30; formatex(Name, sizeof(Name), "9mm");}
case CSW_M249: {eth_Amount = 30; formatex(Name, sizeof(Name), "556natobox");}
case CSW_M3: {eth_Amount = 8; formatex(Name, sizeof(Name), "buckshot");}
case CSW_M4A1: {eth_Amount = 30; formatex(Name, sizeof(Name), "556nato");}
case CSW_TMP: {eth_Amount = 30; formatex(Name, sizeof(Name), "9mm");}
case CSW_G3SG1: {eth_Amount = 30; formatex(Name, sizeof(Name), "762nato");}
case CSW_DEAGLE: {eth_Amount = 7; formatex(Name, sizeof(Name), "50ae");}
case CSW_SG552: {eth_Amount = 30; formatex(Name, sizeof(Name), "556nato");}
case CSW_AK47: {eth_Amount = 30; formatex(Name, sizeof(Name), "762nato");}
case CSW_P90: {eth_Amount = 50; formatex(Name, sizeof(Name), "57mm");}
}
if(!eth_silent) emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
ExecuteHamB(Ham_GiveAmmo, id, eth_Amount, Name, Max)
}
stock eth_Eject_Shell(id, eth_Shell_ModelIndex, Float:eth_Time)
{
static eth_Ent; eth_Ent = get_pdata_cbase(id, 373, 5)
if(!pev_valid(eth_Ent))
return
set_pdata_int(eth_Ent, 57, eth_Shell_ModelIndex, 4)
set_pdata_float(id, 111, get_gametime() + eth_Time)
}
stock eth_drop_weapons(id, eth_dropwhat)
{
static weapons[32], num, i, weaponid
num = 0
get_user_weapons(id, weapons, num)
for (i = 0; i < num; i++)
{
weaponid = weapons[i]
if ((eth_dropwhat == 1 && ((1<<weaponid) & eth_PRIMARY_WEAPONS_BIT_SUM)) || (eth_dropwhat == 2 && ((1<<weaponid) & eth_SECONDARY_WEAPONS_BIT_SUM)))
{
static wname[32]; get_weaponname(weaponid, wname, charsmax(wname))
engclient_cmd(id, "drop", wname)
}
}
}
stock eth_set_weapon_anim(id, eth_anim)
{
set_pev(id, pev_weaponanim, eth_anim)
message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
write_byte(eth_anim)
write_byte(pev(id, pev_body))
message_end()
}
stock eth_Make_BulletHole(id, Float:Origin[3], Float:Damage)
{
static eth_Decal; eth_Decal = random_num(41, 45)
static eth_LoopTime;
if(Damage > 100.0) eth_LoopTime = 2
else eth_LoopTime = 1
for(new i = 0; i < eth_LoopTime; i++)
{
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_WORLDDECAL)
engfunc(EngFunc_WriteCoord, Origin[0])
engfunc(EngFunc_WriteCoord, Origin[1])
engfunc(EngFunc_WriteCoord, Origin[2])
write_byte(eth_Decal)
message_end()
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_GUNSHOTDECAL)
engfunc(EngFunc_WriteCoord, Origin[0])
engfunc(EngFunc_WriteCoord, Origin[1])
engfunc(EngFunc_WriteCoord, Origin[2])
write_short(id)
write_byte(eth_Decal)
message_end()
}
}
stock eth_Make_BulletSmoke(id, eth_TrResult)
{
static Float:eth_vecSrc[3], Float:eth_vecEnd[3], eth_TE_FLAG
eth_get_weapon_attachment(id, eth_vecSrc)
global_get(glb_v_forward, eth_vecEnd)
xs_vec_mul_scalar(eth_vecEnd, 8192.0, eth_vecEnd)
xs_vec_add(eth_vecSrc, eth_vecEnd, eth_vecEnd)
get_tr2(eth_TrResult, TR_vecEndPos, eth_vecSrc)
get_tr2(eth_TrResult, TR_vecPlaneNormal, eth_vecEnd)
xs_vec_mul_scalar(eth_vecEnd, 2.5, eth_vecEnd)
xs_vec_add(eth_vecSrc, eth_vecEnd, eth_vecEnd)
eth_TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
eth_TE_FLAG |= TE_EXPLFLAG_NOSOUND
eth_TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, eth_vecEnd, 0)
write_byte(TE_EXPLOSION)
engfunc(EngFunc_WriteCoord, eth_vecEnd[0])
engfunc(EngFunc_WriteCoord, eth_vecEnd[1])
engfunc(EngFunc_WriteCoord, eth_vecEnd[2] - 10.0)
write_short(eth_g_SmokePuff_SprId)
write_byte(2)
write_byte(50)
write_byte(eth_TE_FLAG)
message_end()
}
stock eth_get_weapon_attachment(id, Float:output[3], Float:eth_fDis = 40.0)
{
static Float:eth_vfEnd[3], eth_viEnd[3]
get_user_origin(id, eth_viEnd, 3)
IVecFVec(eth_viEnd, eth_vfEnd)
static Float:eth_fOrigin[3], Float:eth_fAngle[3]
pev(id, pev_origin, eth_fOrigin)
pev(id, pev_view_ofs, eth_fAngle)
xs_vec_add(eth_fOrigin, eth_fAngle, eth_fOrigin)
static Float:eth_fAttack[3]
xs_vec_sub(eth_vfEnd, eth_fOrigin, eth_fAttack)
xs_vec_sub(eth_vfEnd, eth_fOrigin, eth_fAttack)
static Float:eth_fRate
eth_fRate = eth_fDis / vector_length(eth_fAttack)
xs_vec_mul_scalar(eth_fAttack, eth_fRate, eth_fAttack)
xs_vec_add(eth_fOrigin, eth_fAttack, output)
}
stock eth_Set_Player_NextAttack(id, eth_CSWID, Float:eth_NextTime)
{
static eth_Ent; eth_Ent = fm_get_user_weapon_entity(id, eth_CSWID)
if(!pev_valid(eth_Ent)) return
set_pdata_float(id, 83, eth_NextTime, 5)
set_pdata_float(eth_Ent, 46 , eth_NextTime, 4)
set_pdata_float(eth_Ent, 47, eth_NextTime, 4)
set_pdata_float(eth_Ent, 48, eth_NextTime, 4)
}
public eth_vex_give(id) { if (!is_user_alive(id) || vx45_corezombie(id)) return 0; eth_g_VexGiving[id]=true; eth_Get_Ethereal(id); eth_g_VexGiving[id]=false; return eth_vex_has(id) && user_has_weapon(id,CSW_M4A1); }
public eth_vex_remove(id) { eth_Remove_Ethereal(id); return 1; }
public eth_vex_has(id) { return eth_Get_BitVar(eth_g_Had_Ethereal, id) ? 1 : 0; }
#define sal_PLUGIN "[CSO] Salamander"
#define sal_VERSION "2015"
#define sal_AUTHOR "Dias Pendragon Leon"
#define sal_CSW_SAL CSW_M249
#define sal_weapon_sal "weapon_m249"
#define sal_DAMAGE 38
#define sal_FIRE_SPEED 640.0
#define sal_RECOIL 0.0
#define sal_MODEL_V "models/v_salamander.mdl"
#define sal_MODEL_P "models/p_salamander.mdl"
#define sal_MODEL_W "models/w_salamander.mdl"
#define sal_DEFAULT_W_MODEL "models/vexmira_ze/skins/vexmira_w_m249.mdl"
new const sal_WeaponSounds[6][] =
{
"weapons/flamegun-1.wav",
"weapons/flamegun_draw.wav",
"weapons/flamegun_clipin1.wav",
"weapons/flamegun_clipin2.wav",
"weapons/flamegun_clipout1.wav",
"weapons/flamegun_clipout2.wav"
}
new const sal_WeaponResources[7][] =
{
"sprites/vex_community/salamander/flame_puff01.spr",
"sprites/vex_community/salamander/flame_burn01.spr",
"sprites/weapon_flamethrower.txt",
"sprites/vex_community/salamander/640hud7_2.spr",
"sprites/vex_community/salamander/640hud59_2.spr",
"sprites/vex_community/salamander/640hud60_2.spr",
"sprites/smokepuff.spr"
}
enum
{
sal_ANIM_IDLE = 0,
sal_ANIM_SHOOT,
sal_ANIM_SHOOT_END,
sal_ANIM_RELOAD,
sal_ANIM_DRAW
}
#define sal_Get_BitVar(%1,%2)		(%1 & (1 << (%2 & 31)))
#define sal_Set_BitVar(%1,%2)		(%1 |= (1 << (%2 & 31)));
#define sal_UnSet_BitVar(%1,%2)		(%1 &= ~(1 << (%2 & 31)));
new sal_g_Had_Salamander, sal_g_WeaponEnt, sal_g_SmokePuff_SprID, Float:sal_g_PunchAngles[33]
new sal_g_MsgCurWeapon, sal_g_MsgWeaponList
new sal_g_HamBot
new sal_g_IsConnected, sal_g_IsAlive, sal_g_PlayerWeapon[33]
new bool:sal_g_VexGiving[33];
public sal_plugin_init()
{
sal_Register_SafetyFunc()
g_zcFm[ZCFM_UpdateClientData_P] |= (1<<4)
g_zcFm[ZCFM_SetModel] |= (1<<4)
g_zcFm[ZCFM_PlaybackEvent] |= (1<<4)
g_zcFm[ZCFM_CmdStart] |= (1<<4)
register_forward(FM_PrecacheEvent, "sal_fw_PrecacheEvent_Post", 1)
register_think("vex_sal_flame", "sal_fw_Fire_Think")
register_touch("vex_sal_flame", "*", "sal_fw_Fire_Touch")
VxRegisterHam524(Ham_Item_Deploy, sal_weapon_sal, "sal_fw_Item_Deploy_Post", 1)
VxRegisterHam524(Ham_Item_AddToPlayer, sal_weapon_sal, "sal_fw_Item_AddToPlayer_Post", 1)
VxRegisterHam524(Ham_TraceAttack, "player", "sal_fw_TraceAttack")
VxRegisterHam524(Ham_TraceAttack, "worldspawn", "sal_fw_TraceAttack")
VxRegisterHam524(Ham_Weapon_PrimaryAttack, sal_weapon_sal, "sal_fw_Weapon_PrimaryAttack")
VxRegisterHam524(Ham_Weapon_PrimaryAttack, sal_weapon_sal, "sal_fw_Weapon_PrimaryAttack_49b", 1)
sal_g_MsgCurWeapon = get_user_msgid("CurWeapon")
sal_g_MsgWeaponList = get_user_msgid("WeaponList")
register_clcmd("weapon_flamethrower", "sal_Hook_Weapon")
}
public sal_plugin_precache()
{
if (!VexAssetGuard("vx42_salamander")) return;
ZcPcModel(sal_MODEL_V)
ZcPcModel(sal_MODEL_P)
ZcPcModel(sal_MODEL_W)
for(new i = 0; i < sizeof(sal_WeaponSounds); i++)
VexPcSnd(sal_WeaponSounds[i], (i==0) ? true : false)
for(new i = 0; i < sizeof(sal_WeaponResources); i++)
{
if(i == 2) ZcPcGeneric(sal_WeaponResources[i])
else if(i == 6) sal_g_SmokePuff_SprID = ZcPcModel(sal_WeaponResources[i])
else ZcPcModel(sal_WeaponResources[i])
}
}
public sal_fw_PrecacheEvent_Post(type, const name[])
{
if(equal("events/m249.sc", name))
sal_g_WeaponEnt = get_orig_retval()
}
public sal_client_putinserver(id)
{
sal_Safety_Connected(id)
if(!sal_g_HamBot && is_user_bot(id))
{
sal_g_HamBot = 1
set_task(0.1, "sal_Register_HamBot", (id) + ZC_TOFF_SAL)
}
}
public sal_Register_HamBot(id)
{ if (id >= ZC_TOFF_SAL && id < ZC_TOFF_SAL + 0x1000000) id -= ZC_TOFF_SAL;
sal_Register_SafetyFuncBot(id)
RegisterHamFromEntity(Ham_TraceAttack, id, "sal_fw_TraceAttack")
}
public sal_client_disconnect(id)
{
sal_Safety_Disconnected(id)
}
public sal_Hook_Weapon(id)
{
engclient_cmd(id, sal_weapon_sal)
return PLUGIN_HANDLED
}
public sal_Get_Salamander(id)
{
sal_Set_BitVar(sal_g_Had_Salamander, id)
give_item(id, sal_weapon_sal)
message_begin(MSG_ONE_UNRELIABLE, sal_g_MsgCurWeapon, _, id)
write_byte(1)
write_byte(sal_CSW_SAL)
write_byte(100)
message_end()
cs_set_user_bpammo(id, sal_CSW_SAL, 200)
}
public sal_Remove_Salamander(id)
{
sal_UnSet_BitVar(sal_g_Had_Salamander, id)
}
public sal_fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
if(!sal_is_alive(id))
return FMRES_IGNORED
if(sal_get_player_weapon(id) != sal_CSW_SAL || !sal_Get_BitVar(sal_g_Had_Salamander, id))
return FMRES_IGNORED
set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001)
return FMRES_HANDLED
}
public sal_fw_SetModel(entity, model[])
{
if(!pev_valid(entity))
return FMRES_IGNORED
static szClassName[33]
pev(entity, pev_classname, szClassName, charsmax(szClassName))
if(!equal(szClassName, "weaponbox"))
return FMRES_IGNORED
static id
id = pev(entity, pev_owner)
if(equal(model, sal_DEFAULT_W_MODEL))
{
static weapon; weapon = fm_find_ent_by_owner(-1, sal_weapon_sal, entity)
if(!pev_valid(weapon))
return FMRES_IGNORED
if(sal_Get_BitVar(sal_g_Had_Salamander, id))
{
set_pev(weapon, pev_impulse, 442015)
VxSM(entity, sal_MODEL_W)
sal_UnSet_BitVar(sal_g_Had_Salamander, id)
return FMRES_SUPERCEDE
}
}
return FMRES_IGNORED
}
public sal_fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, sal_iParam1, sal_iParam2, sal_bParam1, sal_bParam2)
{
if(!sal_is_alive(invoker))
return FMRES_IGNORED
if(sal_get_player_weapon(invoker) != sal_CSW_SAL || !sal_Get_BitVar(sal_g_Had_Salamander, invoker))
return FMRES_IGNORED
if(eventid == sal_g_WeaponEnt)
{
playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, sal_iParam1, sal_iParam2, sal_bParam1, sal_bParam2)
if(pev(invoker, pev_weaponanim) != sal_ANIM_SHOOT) sal_Set_WeaponAnim(invoker, sal_ANIM_SHOOT)
return FMRES_SUPERCEDE
}
return FMRES_HANDLED
}
public sal_fw_CmdStart(id, uc_handle, seed)
{
if(!sal_is_alive(id))
return FMRES_IGNORED
if(sal_get_player_weapon(id) != sal_CSW_SAL || !sal_Get_BitVar(sal_g_Had_Salamander, id))
return FMRES_IGNORED
static sal_PressedButton
sal_PressedButton = get_uc(uc_handle, UC_Buttons)
if(!(sal_PressedButton & IN_ATTACK))
{
if((pev(id, pev_oldbuttons) & IN_ATTACK) && pev(id, pev_weaponanim) == sal_ANIM_SHOOT)
{
static weapon; weapon = fm_get_user_weapon_entity(id, sal_CSW_SAL)
if(pev_valid(weapon)) set_pdata_float(weapon, 48, 2.0, 4)
sal_Set_WeaponAnim(id, sal_ANIM_SHOOT_END)
sal_Make_FireSmoke(id)
}
}
return FMRES_HANDLED
}
public sal_Make_FireSmoke(id)
{
static Float:Origin[3]
sal_get_position(id, 40.0, 5.0, -15.0, Origin)
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_EXPLOSION)
engfunc(EngFunc_WriteCoord, Origin[0])
engfunc(EngFunc_WriteCoord, Origin[1])
engfunc(EngFunc_WriteCoord, Origin[2])
write_short(sal_g_SmokePuff_SprID)
write_byte(5)
write_byte(30)
write_byte(14)
message_end()
}
public sal_fw_Item_Deploy_Post(sal_Ent)
{
if(pev_valid(sal_Ent) != 2)
return
static sal_Id; sal_Id = get_pdata_cbase(sal_Ent, 41, 4)
if(get_pdata_cbase(sal_Id, 373) != sal_Ent)
return
if(!sal_Get_BitVar(sal_g_Had_Salamander, sal_Id))
return
set_pev(sal_Id, pev_viewmodel2, sal_MODEL_V)
set_pev(sal_Id, pev_weaponmodel2, sal_MODEL_P)
}
public sal_fw_Item_AddToPlayer_Post(sal_Ent, id)
{
if(id>=1 && id<=32 && !sal_g_VexGiving[id]) sal_UnSet_BitVar(sal_g_Had_Salamander, id)
if(id<1 || id>32 || !is_user_connected(id)) return HAM_IGNORED;
if(!pev_valid(sal_Ent))
return HAM_IGNORED
if(pev(sal_Ent, pev_impulse) == 442015)
{
sal_Set_BitVar(sal_g_Had_Salamander, id)
set_pev(sal_Ent, pev_impulse, 0)
}
if(sal_Get_BitVar(sal_g_Had_Salamander, id))
{
message_begin(MSG_ONE_UNRELIABLE, sal_g_MsgWeaponList, _, id)
write_string("weapon_flamethrower")
write_byte(3)
write_byte(200)
write_byte(-1)
write_byte(-1)
write_byte(0)
write_byte(4)
write_byte(sal_CSW_SAL)
write_byte(0)
message_end()
}
return HAM_HANDLED
}
public sal_fw_TraceAttack(sal_Ent, sal_Attacker, Float:Damage, Float:sal_Dir[3], ptr, DamageType)
{
if(!sal_is_alive(sal_Attacker))
return HAM_IGNORED
if(sal_get_player_weapon(sal_Attacker) != sal_CSW_SAL || !sal_Get_BitVar(sal_g_Had_Salamander, sal_Attacker))
return HAM_IGNORED
return HAM_SUPERCEDE
}
public sal_CreateFire(id, Float:Speed)
{
new sal_iEnt = GearCreate51("env_sprite")
if(!pev_valid(sal_iEnt)) return
static Float:sal_vfAngle[3], Float:sal_MyOrigin[3]
static Float:Origin[3], Float:sal_TargetOrigin[3], Float:sal_Velocity[3]
sal_get_position(id, 40.0, 5.0, -5.0, Origin)
sal_get_position(id, 1024.0, 0.0, 0.0, sal_TargetOrigin)
pev(id, pev_angles, sal_vfAngle)
pev(id, pev_origin, sal_MyOrigin)
sal_vfAngle[2] = float(random(18) * 20)
set_pev(sal_iEnt, pev_movetype, MOVETYPE_FLY)
set_pev(sal_iEnt, pev_rendermode, kRenderTransAdd)
set_pev(sal_iEnt, pev_renderamt, 160.0)
set_pev(sal_iEnt, pev_fuser1, get_gametime() + 1.0)
set_pev(sal_iEnt, pev_scale, 0.25)
set_pev(sal_iEnt, pev_nextthink, get_gametime() + 0.05)
entity_set_string(sal_iEnt, EV_SZ_classname, "vex_sal_flame")
VxSM(sal_iEnt, sal_WeaponResources[0])
set_pev(sal_iEnt, pev_mins, Float:{-1.0, -1.0, -1.0})
set_pev(sal_iEnt, pev_maxs, Float:{1.0, 1.0, 1.0})
set_pev(sal_iEnt, pev_origin, Origin)
set_pev(sal_iEnt, pev_gravity, 0.01)
set_pev(sal_iEnt, pev_angles, sal_vfAngle)
set_pev(sal_iEnt, pev_solid, SOLID_TRIGGER)
set_pev(sal_iEnt, pev_owner, id)
set_pev(sal_iEnt, pev_iuser4, get_user_userid(id));
set_pev(sal_iEnt, pev_frame, 0.0)
set_pev(sal_iEnt, pev_iuser2, get_user_team(id))
sal_get_speed_vector(Origin, sal_TargetOrigin, Speed, sal_Velocity)
set_pev(sal_iEnt, pev_velocity, sal_Velocity)
emit_sound(sal_iEnt, CHAN_BODY, sal_WeaponSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
public sal_fw_Fire_Think(sal_iEnt)
{
if(!pev_valid(sal_iEnt))
return
static Float:sal_fFrame, Float:sal_fScale
pev(sal_iEnt, pev_frame, sal_fFrame)
pev(sal_iEnt, pev_scale, sal_fScale)
if(pev(sal_iEnt, pev_movetype) == MOVETYPE_NONE)
{
sal_fFrame += 1.0
sal_fScale += 0.1
sal_fScale = floatmin(sal_fScale, 1.75)
if(sal_fFrame > 21.0)
{
engfunc(EngFunc_RemoveEntity, sal_iEnt)
return
}
set_pev(sal_iEnt, pev_nextthink, get_gametime() + 0.025)
} else {
sal_fFrame += 1.25
sal_fFrame = floatmin(21.0, sal_fFrame)
sal_fScale += 0.15
sal_fScale = floatmin(sal_fScale, 1.75)
set_pev(sal_iEnt, pev_nextthink, get_gametime() + 0.05)
}
set_pev(sal_iEnt, pev_frame, sal_fFrame)
set_pev(sal_iEnt, pev_scale, sal_fScale)
static Float:sal_fTimeRemove
pev(sal_iEnt, pev_fuser1, sal_fTimeRemove)
if (get_gametime() >= sal_fTimeRemove)
{
engfunc(EngFunc_RemoveEntity, sal_iEnt)
return;
}
}
public sal_fw_Fire_Touch(ent, id)
{
if(!pev_valid(ent))
return
if(pev_valid(id))
{
static Classname[32]
pev(id, pev_classname, Classname, sizeof(Classname))
if(equal(Classname, "vex_sal_flame")) return
else if(sal_is_alive(id))
{
static sal_EntTeam; sal_EntTeam = pev(ent, pev_iuser2)
if(get_user_team(id) != sal_EntTeam)
{
static sal_Attacker; sal_Attacker = pev(ent, pev_owner)
if(sal_Attacker >= 1 && sal_Attacker <= 32 && is_user_alive(sal_Attacker) && !vx45_corezombie(sal_Attacker) && pev(ent, pev_iuser4) == get_user_userid(sal_Attacker))
{
ExecuteHamB(Ham_TakeDamage, id, 0, sal_Attacker, float(sal_DAMAGE), DMG_BULLET)
}
}
}
}
set_pev(ent, pev_movetype, MOVETYPE_NONE)
set_pev(ent, pev_solid, SOLID_NOT)
}
public sal_fw_Weapon_PrimaryAttack(ent)
{
static id; id = pev(ent, pev_owner)
pev(id, pev_punchangle, sal_g_PunchAngles[id])
return HAM_IGNORED
}
public sal_fw_Weapon_PrimaryAttack_49b(ent)
{
static id; id = pev(ent, pev_owner)
if(sal_get_player_weapon(id) == sal_CSW_SAL && sal_Get_BitVar(sal_g_Had_Salamander, id) && cs_get_weapon_ammo(ent) > 0)
{
static Float:sal_push[3]
pev(id, pev_punchangle, sal_push)
xs_vec_sub(sal_push, sal_g_PunchAngles[id], sal_push)
xs_vec_mul_scalar(sal_push, sal_RECOIL, sal_push)
xs_vec_add(sal_push, sal_g_PunchAngles[id], sal_push)
set_pev(id, pev_punchangle, sal_push)
sal_CreateFire(id, sal_FIRE_SPEED)
} else {
static Float:sal_push[3]
pev(id, pev_punchangle, sal_push)
xs_vec_sub(sal_push, sal_g_PunchAngles[id], sal_push)
xs_vec_mul_scalar(sal_push, 0.0, sal_push)
xs_vec_add(sal_push, sal_g_PunchAngles[id], sal_push)
set_pev(id, pev_punchangle, sal_push)
}
return HAM_IGNORED
}
stock sal_Set_WeaponIdleTime(id, sal_WeaponId ,Float:sal_TimeIdle)
{
static sal_entwpn; sal_entwpn = fm_get_user_weapon_entity(id, sal_WeaponId)
if(!pev_valid(sal_entwpn))
return
set_pdata_float(sal_entwpn, 46, sal_TimeIdle, 4)
set_pdata_float(sal_entwpn, 47, sal_TimeIdle, 4)
set_pdata_float(sal_entwpn, 48, sal_TimeIdle + 0.5, 4)
}
stock sal_Set_PlayerNextAttack(id, Float:sal_nexttime)
{
set_pdata_float(id, 83, sal_nexttime, 5)
}
stock sal_Set_WeaponAnim(id, sal_anim)
{
set_pev(id, pev_weaponanim, sal_anim)
message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
write_byte(sal_anim)
write_byte(pev(id, pev_body))
message_end()
}
stock sal_get_position(id,Float:sal_forw, Float:right, Float:up, Float:sal_vStart[])
{
new Float:sal_vOrigin[3], Float:sal_vAngle[3], Float:sal_vForward[3], Float:sal_vRight[3], Float:sal_vUp[3]
pev(id, pev_origin, sal_vOrigin)
pev(id, pev_view_ofs,sal_vUp)
xs_vec_add(sal_vOrigin,sal_vUp,sal_vOrigin)
pev(id, pev_v_angle, sal_vAngle)
angle_vector(sal_vAngle,ANGLEVECTOR_FORWARD,sal_vForward)
angle_vector(sal_vAngle,ANGLEVECTOR_RIGHT,sal_vRight)
angle_vector(sal_vAngle,ANGLEVECTOR_UP,sal_vUp)
sal_vStart[0] = sal_vOrigin[0] + sal_vForward[0] * sal_forw + sal_vRight[0] * right + sal_vUp[0] * up
sal_vStart[1] = sal_vOrigin[1] + sal_vForward[1] * sal_forw + sal_vRight[1] * right + sal_vUp[1] * up
sal_vStart[2] = sal_vOrigin[2] + sal_vForward[2] * sal_forw + sal_vRight[2] * right + sal_vUp[2] * up
}
stock sal_get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:sal_new_velocity[3])
{
sal_new_velocity[0] = origin2[0] - origin1[0]
sal_new_velocity[1] = origin2[1] - origin1[1]
sal_new_velocity[2] = origin2[2] - origin1[2]
new Float:num = floatsqroot(speed*speed / (sal_new_velocity[0]*sal_new_velocity[0] + sal_new_velocity[1]*sal_new_velocity[1] + sal_new_velocity[2]*sal_new_velocity[2]))
sal_new_velocity[0] *= num
sal_new_velocity[1] *= num
sal_new_velocity[2] *= num
return 1;
}
stock sal_get_weapon_attachment(id, Float:output[3], Float:sal_fDis = 40.0)
{
static Float:sal_vfEnd[3], sal_viEnd[3]
get_user_origin(id, sal_viEnd, 3)
IVecFVec(sal_viEnd, sal_vfEnd)
static Float:sal_fOrigin[3], Float:sal_fAngle[3]
pev(id, pev_origin, sal_fOrigin)
pev(id, pev_view_ofs, sal_fAngle)
xs_vec_add(sal_fOrigin, sal_fAngle, sal_fOrigin)
static Float:sal_fAttack[3]
xs_vec_sub(sal_vfEnd, sal_fOrigin, sal_fAttack)
xs_vec_sub(sal_vfEnd, sal_fOrigin, sal_fAttack)
static Float:sal_fRate
sal_fRate = sal_fDis / vector_length(sal_fAttack)
xs_vec_mul_scalar(sal_fAttack, sal_fRate, sal_fAttack)
xs_vec_add(sal_fOrigin, sal_fAttack, output)
}
public sal_Register_SafetyFunc()
{
g_zcEvCurWeapon |= (1<<4)
VxRegisterHam524(Ham_Spawn, "player", "sal_fw_Safety_Spawn_Post", 1)
VxRegisterHam524(Ham_Killed, "player", "sal_fw_Safety_Killed_Post", 1)
}
public sal_Register_SafetyFuncBot(id)
{
RegisterHamFromEntity(Ham_Spawn, id, "sal_fw_Safety_Spawn_Post", 1)
RegisterHamFromEntity(Ham_Killed, id, "sal_fw_Safety_Killed_Post", 1)
}
public sal_Safety_Connected(id)
{
sal_Set_BitVar(sal_g_IsConnected, id)
sal_UnSet_BitVar(sal_g_IsAlive, id)
sal_g_PlayerWeapon[id] = 0
}
public sal_Safety_Disconnected(id)
{
sal_UnSet_BitVar(sal_g_IsConnected, id)
sal_UnSet_BitVar(sal_g_IsAlive, id)
sal_g_PlayerWeapon[id] = 0
}
public sal_Safety_CurWeapon(id)
{
if(!sal_is_alive(id))
return
static sal_CSW; sal_CSW = read_data(2)
if(sal_g_PlayerWeapon[id] != sal_CSW) sal_g_PlayerWeapon[id] = sal_CSW
}
public sal_fw_Safety_Spawn_Post(id)
{
if(!is_user_alive(id))
return
sal_Set_BitVar(sal_g_IsAlive, id)
}
public sal_fw_Safety_Killed_Post(id)
{
sal_UnSet_BitVar(sal_g_IsAlive, id)
}
public sal_is_connected(id)
{
if(!(1 <= id <= 32))
return 0
if(!sal_Get_BitVar(sal_g_IsConnected, id))
return 0
return 1
}
public sal_is_alive(id)
{
if(!sal_is_connected(id))
return 0
if(!sal_Get_BitVar(sal_g_IsAlive, id))
return 0
return 1
}
public sal_get_player_weapon(id)
{
if(!sal_is_alive(id))
return 0
return sal_g_PlayerWeapon[id]
}
public sal_vex_give(id) { if (!is_user_alive(id) || vx45_corezombie(id)) return 0; sal_g_VexGiving[id]=true; sal_Get_Salamander(id); sal_g_VexGiving[id]=false; return sal_vex_has(id) && user_has_weapon(id,CSW_M249); }
public sal_vex_remove(id) { sal_Remove_Salamander(id); return 1; }
public sal_vex_has(id) { return sal_Get_BitVar(sal_g_Had_Salamander, id) ? 1 : 0; }
#define bow_PLUGIN "[CSO] Weapon: Compound Bow"
#define bow_VERSION "1.0"
#define bow_AUTHOR "Dias Leon"
#define bow_V_MODEL "models/v_bow.mdl"
#define bow_P_MODEL "models/p_bow.mdl"
#define bow_P_MODEL_EMPTY "models/p_bow_empty.mdl"
#define bow_W_MODEL "models/w_bow.mdl"
#define bow_ARROW_MODEl "models/arrow.mdl"
new const bow_WeaponSounds[7][] =
{
"weapons/bow_shoot1.wav",
"weapons/bow_charge_shoot1_empty.wav",
"weapons/bow_charge_shoot2.wav",
"weapons/bow_draw.wav",
"weapons/bow_charge_start1.wav",
"weapons/bow_charge_start2.wav",
"weapons/bow_charge_finish1.wav"
}
new const bow_WeaponResources[3][] =
{
"sprites/weapon_bow.txt",
"sprites/vex_community/bow/640hud12_2.spr",
"sprites/vex_community/bow/640hud98_2.spr"
}
enum
{
bow_BOW_ANIM_IDLE = 0,
bow_BOW_ANIM_IDLE_EMPTY,
bow_BOW_ANIM_SHOOT1,
bow_BOW_ANIM_SHOOT1_EMPTY,
bow_BOW_ANIM_DRAW,
bow_BOW_ANIM_DRAW_EMPTY,
bow_BOW_ANIM_CHARGE_START,
bow_BOW_ANIM_CHARGE_FINISH,
bow_BOW_ANIM_CHARGE_IDLE1,
bow_BOW_ANIM_CHARGE_IDLE2,
bow_BOW_ANIM_CHARGE_SHOOT1,
bow_BOW_ANIM_CHARGE_SHOOT1__0e4,
bow_BOW_ANIM_CHARGE_SHOOT2,
bow_BOW_ANIM_CHARGE_SHOOT2__858
}
#define bow_CSW_BOW CSW_M4A1
#define bow_weapon_bow "weapon_m4a1"
#define bow_BOW_AMMOID 4
#define bow_ARROW_DEFAULT 60
#define bow_ARROW_CLASSNAME "vex_bow_arrow"
#define bow_ARROW_SPEED 2000.0
#define bow_TIME_DRAW 0.75
#define bow_TIME_RELOADA 0.45
#define bow_TIME_RELOADB 1.25
#define bow_TIME_CHARGE 0.5
#define bow_DAMAGE_A 70
#define bow_DAMAGE_B 140
#define bow_WEAPON_SECRETCODE 3102013
#define bow_WEAPON_ANIMEXT "carbine"
#define bow_WEAPON_OLDWMODEL "models/vexmira_ze/skins/vexmira_w_m4a1.mdl"
#define bow_WL_NAME "weapon_bow"
#define bow_WL_PRIAMMOID 4
#define bow_WL_PRIAMMOMAX 60
#define bow_WL_SECAMMOID -1
#define bow_WL_SECAMMOIDMAX -1
#define bow_WL_SLOTID 0
#define bow_WL_NUMINSLOT 6
#define bow_WL_FLAG 0
#define bow_Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define bow_Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define bow_UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
enum
{
bow_TEAM_T = 1,
bow_TEAM_CT
}
enum
{
bow_WEAPON_NONE = 0,
bow_WEAPON_STARTCHARGING,
bow_WEAPON_WAITCHARGING,
bow_WEAPON_CHARGING,
bow_WEAPON_FINISHCHARGING
}
new bow_g_Had_CompoundBow, bow_g_InTempingAttack, bow_g_BowArrow[33], bow_g_WeaponState[33], Float:bow_g_TimeCharge[33]
new bow_g_MsgCurWeapon, bow_g_MsgAmmoX, bow_g_MsgWeaponList
new bow_g_SprId_LaserBeam
new bool:bow_g_VexGiving[33];
public bow_plugin_init()
{
g_zcEvCurWeapon |= (1<<5)
register_think(bow_ARROW_CLASSNAME, "bow_fw_Think_Arrow")
register_touch(bow_ARROW_CLASSNAME, "*", "bow_fw_Touch_Arrow")
g_zcFm[ZCFM_UpdateClientData_P] |= (1<<5)
g_zcFm[ZCFM_CmdStart] |= (1<<5)
g_zcFm[ZCFM_SetModel] |= (1<<5)
g_zcFm[ZCFM_EmitSound] |= (1<<5)
g_zcFm[ZCFM_TraceLine] |= (1<<5)
g_zcFm[ZCFM_TraceHull] |= (1<<5)
VxRegisterHam524(Ham_Item_AddToPlayer, bow_weapon_bow, "bow_fw_Item_AddToPlayer_Post", 1)
VxRegisterHam524(Ham_Item_Deploy, bow_weapon_bow, "bow_fw_Item_Deploy_Post", 1)
VxRegisterHam524(Ham_Weapon_WeaponIdle, bow_weapon_bow, "bow_fw_Weapon_WeaponIdle_Post", 1)
bow_g_MsgCurWeapon = get_user_msgid("CurWeapon")
bow_g_MsgAmmoX = get_user_msgid("AmmoX")
bow_g_MsgWeaponList = get_user_msgid("WeaponList")
register_clcmd(bow_WL_NAME, "bow_WeaponList_Hook")
}
public bow_plugin_precache()
{
if (!VexAssetGuard("vx42_bow")) return;
ZcPcModel(bow_V_MODEL)
ZcPcModel(bow_P_MODEL)
ZcPcModel(bow_P_MODEL_EMPTY)
ZcPcModel(bow_W_MODEL)
ZcPcModel(bow_ARROW_MODEl)
new i
for(i = 0; i < sizeof(bow_WeaponSounds); i++)
VexPcSnd(bow_WeaponSounds[i], (i==0||i==1||i==2) ? true : false)
for(i = 0; i < sizeof(bow_WeaponResources); i++)
{
if(i == 0) ZcPcGeneric(bow_WeaponResources[i])
else ZcPcModel(bow_WeaponResources[i])
}
bow_g_SprId_LaserBeam = ZcPcModel("sprites/laserbeam.spr")
}
public bow_Get_CompoundBow(id)
{
if(!is_user_alive(id))
return
bow_Set_BitVar(bow_g_Had_CompoundBow, id)
bow_g_BowArrow[id] = bow_ARROW_DEFAULT
bow_g_WeaponState[id] = bow_WEAPON_NONE
fm_give_item(id, bow_weapon_bow)
bow_UpdateAmmo(id, bow_CSW_BOW, bow_BOW_AMMOID, -1, bow_g_BowArrow[id])
}
public bow_Remove_CompoundBow(id)
{
bow_UnSet_BitVar(bow_g_Had_CompoundBow, id)
bow_g_BowArrow[id] = 0
}
public bow_WeaponList_Hook(id)
{
engclient_cmd(id, bow_weapon_bow)
return PLUGIN_HANDLED
}
public bow_UpdateAmmo(id, bow_CSWID, bow_AmmoID, bow_Ammo, bow_BpAmmo)
{
message_begin(MSG_ONE_UNRELIABLE, bow_g_MsgCurWeapon, _, id)
write_byte(1)
write_byte(bow_CSWID)
write_byte(bow_Ammo)
message_end()
message_begin(MSG_ONE_UNRELIABLE, bow_g_MsgAmmoX, _, id)
write_byte(bow_AmmoID)
write_byte(bow_BpAmmo)
message_end()
cs_set_user_bpammo(id, bow_CSWID, bow_BpAmmo)
}
public bow_Event_CurWeapon(id)
{
static bow_CSWID; bow_CSWID = read_data(2)
if(bow_CSWID != bow_CSW_BOW) return
if(!bow_Get_BitVar(bow_g_Had_CompoundBow, id)) return
bow_UpdateAmmo(id, bow_CSW_BOW, bow_BOW_AMMOID, -1, bow_g_BowArrow[id])
}
public bow_fw_Think_Arrow(bow_Ent)
{
if(!pev_valid(bow_Ent))
return
if(pev(bow_Ent, pev_iuser4))
{
engfunc(EngFunc_RemoveEntity, bow_Ent)
return
}
static bow_Id; bow_Id = pev(bow_Ent, pev_iuser1)
if(!is_user_connected(bow_Id))
return
if(!pev(bow_Ent, pev_iuser3))
{
if(entity_range(bow_Ent, bow_Id) < 250.0)
{
set_pev(bow_Ent, pev_nextthink, get_gametime() + 0.1)
return
}
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_BEAMFOLLOW)
write_short(bow_Ent)
write_short(bow_g_SprId_LaserBeam)
write_byte(10)
write_byte(2)
write_byte(255)
write_byte(127)
write_byte(127)
write_byte(127)
message_end()
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_BEAMFOLLOW)
write_short(bow_Ent)
write_short(bow_g_SprId_LaserBeam)
write_byte(10)
write_byte(2)
write_byte(255)
write_byte(255)
write_byte(255)
write_byte(127)
message_end()
set_pev(bow_Ent, pev_iuser3, 1)
}
set_pev(bow_Ent, pev_nextthink, get_gametime() + 0.1)
}
public bow_fw_Touch_Arrow(bow_Ent, bow_Id)
{
if(!pev_valid(bow_Ent))
return
if(pev(bow_Ent, pev_movetype) == MOVETYPE_NONE)
return
set_pev(bow_Ent, pev_movetype, MOVETYPE_NONE)
set_pev(bow_Ent, pev_solid, SOLID_NOT)
if(!is_user_alive(bow_Id))
{
set_pev(bow_Ent, pev_iuser4, 1)
set_pev(bow_Ent, pev_nextthink, get_gametime() + 3.0)
static Float:Origin[3]; pev(bow_Ent, pev_origin, Origin)
bow_MakeBulletDecal(Origin)
} else {
static bow_Attacker; bow_Attacker = pev(bow_Ent, pev_iuser1)
if(bow_Attacker < 1 || bow_Attacker > 32 || !is_user_alive(bow_Attacker) || vx45_corezombie(bow_Attacker) || pev(bow_Ent, pev_weapons) != get_user_userid(bow_Attacker) || bow_Attacker == bow_Id || !vx45_corezombie(bow_Id))
{
engfunc(EngFunc_RemoveEntity, bow_Ent)
return
}
bow_do_attack(bow_Attacker, bow_Id, 0, float(bow_DAMAGE_A) * 1.5)
engfunc(EngFunc_RemoveEntity, bow_Ent)
}
}
public bow_fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
if(get_user_weapon(id) != bow_CSW_BOW || !bow_Get_BitVar(bow_g_Had_CompoundBow, id))
return FMRES_IGNORED
set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001)
return FMRES_HANDLED
}
public bow_fw_CmdStart(id, uc_handle, seed)
{
if(get_user_weapon(id) != bow_CSW_BOW || !bow_Get_BitVar(bow_g_Had_CompoundBow, id))
return FMRES_IGNORED
static bow_CurButton; bow_CurButton = get_uc(uc_handle, UC_Buttons)
if(bow_CurButton & IN_ATTACK)
{
bow_CurButton &= ~IN_ATTACK
set_uc(uc_handle, UC_Buttons, bow_CurButton)
bow_Bow_NormalAttackHandle(id, 0)
}
static bow_Ent; bow_Ent = fm_get_user_weapon_entity(id, bow_CSW_BOW)
if(!pev_valid(bow_Ent)) return FMRES_IGNORED
if(bow_CurButton & IN_ATTACK2)
{
bow_CurButton &= ~IN_ATTACK2
set_uc(uc_handle, UC_Buttons, bow_CurButton)
if(get_pdata_float(bow_Ent, 46, 4) > 0.0 || get_pdata_float(bow_Ent, 47, 4) > 0.0)
return FMRES_IGNORED
if(!bow_g_BowArrow[id])
return FMRES_IGNORED
switch(bow_g_WeaponState[id])
{
case bow_WEAPON_NONE:
{
bow_Set_Weapon_Anim(id, bow_BOW_ANIM_CHARGE_START)
bow_Set_Weapon_TimeIdle(id, bow_CSW_BOW, 0.5)
bow_Set_Player_NextAttack(id, 0.5)
bow_g_WeaponState[id] = bow_WEAPON_STARTCHARGING
}
case bow_WEAPON_STARTCHARGING:
{
bow_Set_Weapon_Anim(id, bow_BOW_ANIM_CHARGE_IDLE1)
bow_Set_Weapon_TimeIdle(id, bow_CSW_BOW, 0.35)
bow_Set_Player_NextAttack(id, 0.35)
bow_g_TimeCharge[id] = get_gametime()
bow_g_WeaponState[id] = bow_WEAPON_WAITCHARGING
}
case bow_WEAPON_WAITCHARGING:
{
bow_Set_Weapon_Anim(id, bow_BOW_ANIM_CHARGE_IDLE1)
bow_Set_Weapon_TimeIdle(id, bow_CSW_BOW, 0.35)
bow_Set_Player_NextAttack(id, 0.35)
bow_g_WeaponState[id] = bow_WEAPON_WAITCHARGING
if(get_gametime() >= (bow_g_TimeCharge[id] + bow_TIME_CHARGE))
{
bow_Set_Weapon_Anim(id, bow_BOW_ANIM_CHARGE_FINISH)
bow_Set_Weapon_TimeIdle(id, bow_CSW_BOW, 0.35)
bow_Set_Player_NextAttack(id, 0.35)
bow_g_WeaponState[id] = bow_WEAPON_FINISHCHARGING
}
}
case bow_WEAPON_FINISHCHARGING:
{
bow_Set_Weapon_Anim(id, bow_BOW_ANIM_CHARGE_IDLE2)
bow_Set_Weapon_TimeIdle(id, bow_CSW_BOW, 0.35)
bow_Set_Player_NextAttack(id, 0.35)
bow_g_WeaponState[id] = bow_WEAPON_FINISHCHARGING
}
}
} else {
static bow_OldButton; bow_OldButton = pev(id, pev_oldbuttons)
if(bow_OldButton & IN_ATTACK2)
{
if(bow_g_WeaponState[id] == bow_WEAPON_WAITCHARGING)
{
set_pdata_float(id, 83, 0.0, 5)
bow_Bow_NormalAttackHandle(id, 1)
} else if(bow_g_WeaponState[id] == bow_WEAPON_FINISHCHARGING) {
bow_Bow_ChargeAttackHandle(id)
}
} else {
if(get_pdata_float(bow_Ent, 46, 4) > 0.0 || get_pdata_float(bow_Ent, 47, 4) > 0.0)
return FMRES_IGNORED
if(bow_g_WeaponState[id] == bow_WEAPON_STARTCHARGING)
{
set_pdata_float(id, 83, 0.0, 5)
bow_Bow_NormalAttackHandle(id, 1)
}
bow_g_WeaponState[id] = bow_WEAPON_NONE
}
}
return FMRES_IGNORED;
}
public bow_fw_SetModel(entity, model[])
{
if(!pev_valid(entity))
return FMRES_IGNORED
static szClassName[33]
pev(entity, pev_classname, szClassName, charsmax(szClassName))
if(!equal(szClassName, "weaponbox"))
return FMRES_IGNORED
static id; id = pev(entity, pev_owner)
if(equal(model, bow_WEAPON_OLDWMODEL))
{
static weapon
weapon = fm_find_ent_by_owner(-1, bow_weapon_bow, entity)
if(!pev_valid(weapon))
return FMRES_IGNORED
if(bow_Get_BitVar(bow_g_Had_CompoundBow, id))
{
set_pev(weapon, pev_impulse, bow_WEAPON_SECRETCODE)
set_pev(weapon, pev_iuser1, bow_g_BowArrow[id])
VxSM(entity, bow_W_MODEL)
bow_Remove_CompoundBow(id)
return FMRES_SUPERCEDE
}
}
return FMRES_IGNORED
}
public bow_fw_EmitSound(id, channel, const sample[], Float:volume, Float:bow_attn, flags, pitch)
{
if(!is_user_connected(id))
return FMRES_IGNORED
if(!bow_Get_BitVar(bow_g_InTempingAttack, id))
return FMRES_IGNORED
if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
{
if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
return FMRES_SUPERCEDE
if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
{
if (sample[17] == 'w')  return FMRES_SUPERCEDE
else  return FMRES_SUPERCEDE
}
if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
return FMRES_SUPERCEDE;
}
return FMRES_IGNORED
}
public bow_fw_TraceLine(Float:bow_vector_start[3], Float:bow_vector_end[3], bow_ignored_monster, id, handle)
{
if(!is_user_alive(id))
return FMRES_IGNORED
if(!bow_Get_BitVar(bow_g_InTempingAttack, id))
return FMRES_IGNORED
static Float:bow_vecStart[3], Float:bow_vecEnd[3], Float:bow_v_angle[3], Float:bow_v_forward[3], Float:view_ofs[3], Float:bow_fOrigin[3]
pev(id, pev_origin, bow_fOrigin)
pev(id, pev_view_ofs, view_ofs)
xs_vec_add(bow_fOrigin, view_ofs, bow_vecStart)
pev(id, pev_v_angle, bow_v_angle)
engfunc(EngFunc_MakeVectors, bow_v_angle)
get_global_vector(GL_v_forward, bow_v_forward)
xs_vec_mul_scalar(bow_v_forward, 0.0, bow_v_forward)
xs_vec_add(bow_vecStart, bow_v_forward, bow_vecEnd)
engfunc(EngFunc_TraceLine, bow_vecStart, bow_vecEnd, bow_ignored_monster, id, handle)
return FMRES_SUPERCEDE
}
public bow_fw_TraceHull(Float:bow_vector_start[3], Float:bow_vector_end[3], bow_ignored_monster, hull, id, handle)
{
if(!is_user_alive(id))
return FMRES_IGNORED
if(!bow_Get_BitVar(bow_g_InTempingAttack, id))
return FMRES_IGNORED
static Float:bow_vecStart[3], Float:bow_vecEnd[3], Float:bow_v_angle[3], Float:bow_v_forward[3], Float:view_ofs[3], Float:bow_fOrigin[3]
pev(id, pev_origin, bow_fOrigin)
pev(id, pev_view_ofs, view_ofs)
xs_vec_add(bow_fOrigin, view_ofs, bow_vecStart)
pev(id, pev_v_angle, bow_v_angle)
engfunc(EngFunc_MakeVectors, bow_v_angle)
get_global_vector(GL_v_forward, bow_v_forward)
xs_vec_mul_scalar(bow_v_forward, 0.0, bow_v_forward)
xs_vec_add(bow_vecStart, bow_v_forward, bow_vecEnd)
engfunc(EngFunc_TraceHull, bow_vecStart, bow_vecEnd, bow_ignored_monster, hull, id, handle)
return FMRES_SUPERCEDE
}
public bow_Bow_NormalAttackHandle(id, bow_UnCharge)
{
if(get_pdata_float(id, 83, 5) > 0.0)
return
if(!bow_g_BowArrow[id])
{
set_pdata_float(id, 83, 1.0, 5)
bow_Set_Weapon_Anim(id, bow_BOW_ANIM_IDLE_EMPTY)
return
}
bow_g_BowArrow[id]--
bow_UpdateAmmo(id, bow_CSW_BOW, bow_BOW_AMMOID, -1, bow_g_BowArrow[id])
bow_Create_FakeAttack(id)
bow_Set_Weapon_Anim(id, bow_UnCharge ? bow_BOW_ANIM_CHARGE_SHOOT1 : bow_BOW_ANIM_SHOOT1)
emit_sound(id, CHAN_WEAPON, bow_WeaponSounds[bow_UnCharge ? 1 : 0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
bow_Create_ArrowA(id)
bow_Make_Push(id)
bow_Set_Player_NextAttack(id, bow_UnCharge ? bow_TIME_RELOADB : bow_TIME_RELOADA)
bow_Set_Weapon_TimeIdle(id, bow_CSW_BOW, bow_UnCharge ? bow_TIME_RELOADB : bow_TIME_RELOADA)
bow_g_WeaponState[id] = bow_WEAPON_NONE
}
public bow_Bow_ChargeAttackHandle(id)
{
if(!bow_g_BowArrow[id])
{
set_pdata_float(id, 83, 1.0, 5)
bow_Set_Weapon_Anim(id, bow_BOW_ANIM_IDLE_EMPTY)
return
}
bow_g_BowArrow[id]--
bow_UpdateAmmo(id, bow_CSW_BOW, bow_BOW_AMMOID, -1, bow_g_BowArrow[id])
bow_Create_FakeAttack(id)
bow_Set_Weapon_Anim(id, bow_BOW_ANIM_CHARGE_SHOOT2)
emit_sound(id, CHAN_WEAPON, bow_WeaponSounds[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
bow_ChargedShoot(id)
bow_Make_Push(id)
bow_Set_Player_NextAttack(id, bow_TIME_RELOADB)
bow_Set_Weapon_TimeIdle(id, bow_CSW_BOW, bow_TIME_RELOADB)
bow_g_WeaponState[id] = bow_WEAPON_NONE
}
public bow_ChargedShoot(id)
{
static Float:bow_StartOrigin[3], Float:bow_EndOrigin[3], Float:bow_EndOrigin2[3]
bow_Get_Position(id, 40.0, 0.0, 0.0, bow_StartOrigin)
bow_Get_Position(id, 4096.0, 0.0, 0.0, bow_EndOrigin)
static bow_TrResult; bow_TrResult = create_tr2()
engfunc(EngFunc_TraceLine, bow_StartOrigin, bow_EndOrigin, IGNORE_MONSTERS, id, bow_TrResult)
get_tr2(bow_TrResult, TR_vecEndPos, bow_EndOrigin2)
free_tr2(bow_TrResult)
message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
write_byte(TE_BEAMPOINTS)
engfunc(EngFunc_WriteCoord, bow_StartOrigin[0])
engfunc(EngFunc_WriteCoord, bow_StartOrigin[1])
engfunc(EngFunc_WriteCoord, bow_StartOrigin[2])
engfunc(EngFunc_WriteCoord, bow_EndOrigin2[0])
engfunc(EngFunc_WriteCoord, bow_EndOrigin2[1])
engfunc(EngFunc_WriteCoord, bow_EndOrigin2[2])
write_short(bow_g_SprId_LaserBeam)
write_byte(0)
write_byte(0)
write_byte(20)
write_byte(10)
write_byte(0)
write_byte(255)
write_byte(127)
write_byte(127)
write_byte(127)
write_byte(0)
message_end()
message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
write_byte(TE_BEAMPOINTS)
engfunc(EngFunc_WriteCoord, bow_StartOrigin[0])
engfunc(EngFunc_WriteCoord, bow_StartOrigin[1])
engfunc(EngFunc_WriteCoord, bow_StartOrigin[2])
engfunc(EngFunc_WriteCoord, bow_EndOrigin2[0])
engfunc(EngFunc_WriteCoord, bow_EndOrigin2[1])
engfunc(EngFunc_WriteCoord, bow_EndOrigin2[2])
write_short(bow_g_SprId_LaserBeam)
write_byte(0)
write_byte(0)
write_byte(20)
write_byte(10)
write_byte(0)
write_byte(255)
write_byte(255)
write_byte(255)
write_byte(127)
write_byte(0)
message_end()
bow_ChargedDamage(id, bow_StartOrigin, bow_EndOrigin2)
}
public bow_ChargedDamage(id, Float:bow_Start[3], Float:bow_End[3])
{
static bow_TrResult; bow_TrResult = create_tr2()
engfunc(EngFunc_TraceLine, bow_Start, bow_End, DONT_IGNORE_MONSTERS, id, bow_TrResult)
static bow_pHit1; bow_pHit1 = get_tr2(bow_TrResult, TR_pHit)
static Float:bow_End1[3]; get_tr2(bow_TrResult, TR_vecEndPos, bow_End1)
if(is_user_alive(bow_pHit1))
{
bow_do_attack(id, bow_pHit1, 0, float(bow_DAMAGE_B) * 1.5)
engfunc(EngFunc_TraceLine, bow_End1, bow_End, DONT_IGNORE_MONSTERS, bow_pHit1, bow_TrResult)
} else engfunc(EngFunc_TraceLine, bow_End1, bow_End, DONT_IGNORE_MONSTERS, -1, bow_TrResult)
static bow_pHit2; bow_pHit2 = get_tr2(bow_TrResult, TR_pHit)
static Float:bow_End2[3]; get_tr2(bow_TrResult, TR_vecEndPos, bow_End2)
if(is_user_alive(bow_pHit2))
{
bow_do_attack(id, bow_pHit2, 0, float(bow_DAMAGE_B) * 1.5)
engfunc(EngFunc_TraceLine, bow_End2, bow_End, DONT_IGNORE_MONSTERS, bow_pHit2, bow_TrResult)
} else engfunc(EngFunc_TraceLine, bow_End2, bow_End, DONT_IGNORE_MONSTERS, -1, bow_TrResult)
static bow_pHit3; bow_pHit3 = get_tr2(bow_TrResult, TR_pHit)
static Float:bow_End3[3]; get_tr2(bow_TrResult, TR_vecEndPos, bow_End3)
if(is_user_alive(bow_pHit3))
{
bow_do_attack(id, bow_pHit3, 0, float(bow_DAMAGE_B) * 1.5)
engfunc(EngFunc_TraceLine, bow_End3, bow_End, DONT_IGNORE_MONSTERS, bow_pHit3, bow_TrResult)
} else engfunc(EngFunc_TraceLine, bow_End3, bow_End, DONT_IGNORE_MONSTERS, -1, bow_TrResult)
static bow_pHit4; bow_pHit4 = get_tr2(bow_TrResult, TR_pHit)
if(is_user_alive(bow_pHit4)) bow_do_attack(id, bow_pHit4, 0, float(bow_DAMAGE_B) * 1.5)
free_tr2(bow_TrResult)
}
public bow_Create_ArrowA(id)
{
static Float:bow_StartOrigin[3], Float:bow_EndOrigin[3], Float:Angles[3]
bow_Get_Position(id, 40.0, 0.0, 0.0, bow_StartOrigin)
bow_Get_Position(id, 4096.0, 0.0, 0.0, bow_EndOrigin)
pev(id, pev_v_angle, Angles)
Angles[0] *= -1
static bow_Arrow; bow_Arrow = GearCreate51("env_sprite")
if(!pev_valid(bow_Arrow)) return
set_pev(bow_Arrow, pev_movetype, MOVETYPE_FLY)
set_pev(bow_Arrow, pev_iuser1, id)
set_pev(bow_Arrow, pev_weapons, get_user_userid(id));
set_pev(bow_Arrow, pev_iuser2, bow_Get_SpecialTeam(id, cs_get_user_team(id)))
set_pev(bow_Arrow, pev_iuser3, 0)
set_pev(bow_Arrow, pev_iuser4, 0)
entity_set_string(bow_Arrow, EV_SZ_classname, bow_ARROW_CLASSNAME)
VxSM(bow_Arrow, bow_ARROW_MODEl)
set_pev(bow_Arrow, pev_mins, Float:{-1.0, -1.0, -1.0})
set_pev(bow_Arrow, pev_maxs, Float:{1.0, 1.0, 1.0})
set_pev(bow_Arrow, pev_origin, bow_StartOrigin)
set_pev(bow_Arrow, pev_angles, Angles)
set_pev(bow_Arrow, pev_gravity, 0.01)
set_pev(bow_Arrow, pev_solid, SOLID_BBOX)
set_pev(bow_Arrow, pev_nextthink, get_gametime() + 0.1)
static Float:bow_Velocity[3]
bow_get_speed_vector(bow_StartOrigin, bow_EndOrigin, bow_ARROW_SPEED, bow_Velocity)
set_pev(bow_Arrow, pev_velocity, bow_Velocity)
}
public bow_Create_FakeAttack(id)
{
static bow_Ent; bow_Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
if(!pev_valid(bow_Ent)) return
bow_Set_BitVar(bow_g_InTempingAttack, id)
ExecuteHamB(Ham_Weapon_PrimaryAttack, bow_Ent)
static bow_iAnimDesired,  bow_szAnimation[64]
formatex(bow_szAnimation, charsmax(bow_szAnimation), (pev(id, pev_flags) & FL_DUCKING) ? "crouch_shoot_%s" : "ref_shoot_%s", bow_WEAPON_ANIMEXT)
if((bow_iAnimDesired = lookup_sequence(id, bow_szAnimation)) == -1)
bow_iAnimDesired = 0
set_pev(id, pev_sequence, bow_iAnimDesired)
bow_UnSet_BitVar(bow_g_InTempingAttack, id)
}
public bow_Make_Push(id)
{
static Float:bow_VirtualVec[3]
bow_VirtualVec[0] = random_float(-1.0, -2.0)
bow_VirtualVec[1] = random_float(1.0, -1.0)
bow_VirtualVec[2] = 0.0
set_pev(id, pev_punchangle, bow_VirtualVec)
}
public bow_fw_Item_AddToPlayer_Post(bow_Ent, bow_Id)
{
if(bow_Id>=1 && bow_Id<=32 && !bow_g_VexGiving[bow_Id]) bow_UnSet_BitVar(bow_g_Had_CompoundBow, bow_Id);
if(bow_Id<1 || bow_Id>32 || !is_user_connected(bow_Id)) return HAM_IGNORED;
if(pev(bow_Ent, pev_impulse) == bow_WEAPON_SECRETCODE)
{
bow_Set_BitVar(bow_g_Had_CompoundBow, bow_Id)
bow_g_BowArrow[bow_Id] = pev(bow_Ent, pev_iuser1)
bow_UpdateAmmo(bow_Id, bow_CSW_BOW, bow_BOW_AMMOID, -1, bow_g_BowArrow[bow_Id])
set_pev(bow_Ent, pev_impulse, 0)
}
bow_g_WeaponState[bow_Id] = bow_WEAPON_NONE
message_begin(MSG_ONE_UNRELIABLE, bow_g_MsgWeaponList, _, bow_Id)
write_string((bow_Get_BitVar(bow_g_Had_CompoundBow, bow_Id) ? bow_WL_NAME : bow_weapon_bow))
write_byte(bow_WL_PRIAMMOID)
write_byte(bow_WL_PRIAMMOMAX)
write_byte(bow_WL_SECAMMOID)
write_byte(bow_WL_SECAMMOIDMAX)
write_byte(bow_WL_SLOTID)
write_byte(bow_WL_NUMINSLOT)
write_byte(bow_CSW_BOW)
write_byte(bow_WL_FLAG)
message_end()
return HAM_IGNORED;
}
public bow_fw_Item_Deploy_Post(bow_Ent)
{
if(!pev_valid(bow_Ent))
return
static bow_Id; bow_Id = get_pdata_cbase(bow_Ent, 41, 4)
if(!bow_Get_BitVar(bow_g_Had_CompoundBow, bow_Id))
return
set_pev(bow_Id, pev_viewmodel2, bow_V_MODEL)
set_pev(bow_Id, pev_weaponmodel2, bow_g_BowArrow[bow_Id] ? bow_P_MODEL : bow_P_MODEL_EMPTY)
set_pdata_string(bow_Id, (492) * 4, bow_WEAPON_ANIMEXT, -1 , 20)
bow_Set_Weapon_TimeIdle(bow_Id, bow_CSW_BOW, bow_TIME_DRAW)
bow_Set_Player_NextAttack(bow_Id, bow_TIME_DRAW)
bow_Set_Weapon_Anim(bow_Id, bow_g_BowArrow[bow_Id] ? bow_BOW_ANIM_DRAW : bow_BOW_ANIM_DRAW_EMPTY)
}
public bow_fw_Weapon_WeaponIdle_Post(bow_Ent)
{
if(!pev_valid(bow_Ent))
return
static bow_Id; bow_Id = get_pdata_cbase(bow_Ent, 41, 4)
if(!bow_Get_BitVar(bow_g_Had_CompoundBow, bow_Id))
return
if(get_pdata_float(bow_Ent, 48, 4) <= 0.1)
{
bow_Set_Weapon_Anim(bow_Id, bow_g_BowArrow[bow_Id] ? bow_BOW_ANIM_IDLE : bow_BOW_ANIM_IDLE_EMPTY)
set_pdata_float(bow_Ent, 48, 20.0, 4)
}
return
}
public bow_Get_SpecialTeam(bow_Ent, CsTeams:Team)
{
if(Team == CS_TEAM_T) return bow_TEAM_T
else if(Team == CS_TEAM_CT) return bow_TEAM_CT
return 0
}
public CsTeams:bow_Get_ArrowTeam(bow_Ent)
{
if(pev(bow_Ent, pev_iuser2) == bow_TEAM_T) return CS_TEAM_T
else if(pev(bow_Ent, pev_iuser2) == bow_TEAM_CT) return CS_TEAM_CT
return CS_TEAM_UNASSIGNED
}
stock bow_MakeBulletDecal(Float:Origin[3])
{
static bow_decal; bow_decal = random_num(41, 45)
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_WORLDDECAL)
engfunc(EngFunc_WriteCoord, Origin[0])
engfunc(EngFunc_WriteCoord, Origin[1])
engfunc(EngFunc_WriteCoord, Origin[2])
write_byte(bow_decal)
message_end()
}
stock bow_Set_Weapon_Anim(id, bow_WeaponAnim)
{
set_pev(id, pev_weaponanim, bow_WeaponAnim)
message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
write_byte(bow_WeaponAnim)
write_byte(pev(id, pev_body))
message_end()
}
stock bow_Set_Weapon_TimeIdle(id, bow_WeaponId ,Float:bow_TimeIdle)
{
static bow_entwpn; bow_entwpn = fm_get_user_weapon_entity(id, bow_WeaponId)
if(!pev_valid(bow_entwpn))
return
set_pdata_float(bow_entwpn, 46, bow_TimeIdle, 4)
set_pdata_float(bow_entwpn, 47, bow_TimeIdle, 4)
set_pdata_float(bow_entwpn, 48, bow_TimeIdle + 0.5, 4)
}
stock bow_Set_Player_NextAttack(id, Float:bow_nexttime)
{
set_pdata_float(id, 83, bow_nexttime, 5)
}
stock bow_Get_Position(id,Float:bow_forw, Float:right, Float:up, Float:bow_vStart[])
{
static Float:bow_vOrigin[3], Float:bow_vAngle[3], Float:bow_vForward[3], Float:bow_vRight[3], Float:bow_vUp[3]
pev(id, pev_origin, bow_vOrigin)
pev(id, pev_view_ofs,bow_vUp)
xs_vec_add(bow_vOrigin,bow_vUp,bow_vOrigin)
pev(id, pev_v_angle, bow_vAngle)
angle_vector(bow_vAngle,ANGLEVECTOR_FORWARD,bow_vForward)
angle_vector(bow_vAngle,ANGLEVECTOR_RIGHT,bow_vRight)
angle_vector(bow_vAngle,ANGLEVECTOR_UP,bow_vUp)
bow_vStart[0] = bow_vOrigin[0] + bow_vForward[0] * bow_forw + bow_vRight[0] * right + bow_vUp[0] * up
bow_vStart[1] = bow_vOrigin[1] + bow_vForward[1] * bow_forw + bow_vRight[1] * right + bow_vUp[1] * up
bow_vStart[2] = bow_vOrigin[2] + bow_vForward[2] * bow_forw + bow_vRight[2] * right + bow_vUp[2] * up
}
stock bow_get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:bow_new_velocity[3])
{
bow_new_velocity[0] = origin2[0] - origin1[0]
bow_new_velocity[1] = origin2[1] - origin1[1]
bow_new_velocity[2] = origin2[2] - origin1[2]
static Float:num; num = floatsqroot(speed*speed / (bow_new_velocity[0]*bow_new_velocity[0] + bow_new_velocity[1]*bow_new_velocity[1] + bow_new_velocity[2]*bow_new_velocity[2]))
bow_new_velocity[0] *= num
bow_new_velocity[1] *= num
bow_new_velocity[2] *= num
return 1;
}
bow_do_attack(bow_Attacker, bow_Victim, bow_Inflictor, Float:bow_fDamage)
{
bow_fake_player_trace_attack(bow_Attacker, bow_Victim, bow_fDamage)
bow_fake_take_damage(bow_Attacker, bow_Victim, bow_fDamage, bow_Inflictor)
}
bow_fake_player_trace_attack(bow_iAttacker, bow_iVictim, &Float:bow_fDamage)
{
static Float:bow_fAngles[3], Float:bow_fDirection[3]
pev(bow_iAttacker, pev_angles, bow_fAngles)
angle_vector(bow_fAngles, ANGLEVECTOR_FORWARD, bow_fDirection)
static Float:fStart[3], Float:bow_fViewOfs[3]
pev(bow_iAttacker, pev_origin, fStart)
pev(bow_iAttacker, pev_view_ofs, bow_fViewOfs)
xs_vec_add(bow_fViewOfs, fStart, fStart)
static bow_iAimOrigin[3], Float:bow_fAimOrigin[3]
get_user_origin(bow_iAttacker, bow_iAimOrigin, 3)
IVecFVec(bow_iAimOrigin, bow_fAimOrigin)
static ptr; ptr = create_tr2()
engfunc(EngFunc_TraceLine, fStart, bow_fAimOrigin, DONT_IGNORE_MONSTERS, bow_iAttacker, ptr)
static bow_pHit; bow_pHit = get_tr2(ptr, TR_pHit)
static bow_iHitgroup; bow_iHitgroup = get_tr2(ptr, TR_iHitgroup)
static Float:bow_fEndPos[3]
get_tr2(ptr, TR_vecEndPos, bow_fEndPos)
static bow_iTarget, bow_iBody
get_user_aiming(bow_iAttacker, bow_iTarget, bow_iBody)
if (bow_iTarget == bow_iVictim)
{
bow_iHitgroup = bow_iBody
}
else if (bow_pHit != bow_iVictim)
{
static Float:bow_fVicOrigin[3], Float:bow_fVicViewOfs[3], Float:bow_fAimInVictim[3]
pev(bow_iVictim, pev_origin, bow_fVicOrigin)
pev(bow_iVictim, pev_view_ofs, bow_fVicViewOfs)
xs_vec_add(bow_fVicViewOfs, bow_fVicOrigin, bow_fAimInVictim)
bow_fAimInVictim[2] = fStart[2]
bow_fAimInVictim[2] += get_distance_f(fStart, bow_fAimInVictim) * floattan( bow_fAngles[0] * 2.0, degrees )
static bow_iAngleToVictim; bow_iAngleToVictim = bow_get_angle_to_target(bow_iAttacker, bow_fVicOrigin)
bow_iAngleToVictim = abs(bow_iAngleToVictim)
static Float:bow_fDis; bow_fDis = 2.0 * get_distance_f(fStart, bow_fAimInVictim) * floatsin( float(bow_iAngleToVictim) * 0.5, degrees )
static Float:bow_fVicSize[3]
pev(bow_iVictim, pev_size , bow_fVicSize)
if ( bow_fDis <= bow_fVicSize[0] * 0.5 )
{
static bow_ptr2; bow_ptr2 = create_tr2()
engfunc(EngFunc_TraceLine, fStart, bow_fAimInVictim, DONT_IGNORE_MONSTERS, bow_iAttacker, bow_ptr2)
static bow_pHit2; bow_pHit2 = get_tr2(bow_ptr2, TR_pHit)
static bow_iHitgroup2; bow_iHitgroup2 = get_tr2(bow_ptr2, TR_iHitgroup)
if ( bow_pHit2 == bow_iVictim && (bow_iHitgroup2 != HIT_HEAD || bow_fDis <= bow_fVicSize[0] * 0.25) )
{
bow_pHit = bow_iVictim
bow_iHitgroup = bow_iHitgroup2
get_tr2(bow_ptr2, TR_vecEndPos, bow_fEndPos)
}
free_tr2(bow_ptr2)
}
if (bow_pHit != bow_iVictim)
{
bow_iHitgroup = HIT_GENERIC
static bow_ptr3; bow_ptr3 = create_tr2()
engfunc(EngFunc_TraceLine, fStart, bow_fVicOrigin, DONT_IGNORE_MONSTERS, bow_iAttacker, bow_ptr3)
get_tr2(bow_ptr3, TR_vecEndPos, bow_fEndPos)
free_tr2(bow_ptr3)
}
}
set_tr2(ptr, TR_pHit, bow_iVictim)
set_tr2(ptr, TR_iHitgroup, bow_iHitgroup)
set_tr2(ptr, TR_vecEndPos, bow_fEndPos)
bow_fake_trake_attack(bow_iAttacker, bow_iVictim, bow_fDamage, bow_fDirection, ptr)
free_tr2(ptr)
}
stock bow_fake_trake_attack(bow_iAttacker, bow_iVictim, Float:bow_fDamage, Float:bow_fDirection[3], bow_iTraceHandle, bow_iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
ExecuteHamB(Ham_TraceAttack, bow_iVictim, bow_iAttacker, bow_fDamage, bow_fDirection, bow_iTraceHandle, bow_iDamageBit)
}
stock bow_fake_take_damage(bow_iAttacker, bow_iVictim, Float:bow_fDamage, bow_iInflictor, bow_iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
ExecuteHamB(Ham_TakeDamage, bow_iVictim, bow_iInflictor, bow_iAttacker, bow_fDamage, bow_iDamageBit)
}
stock bow_get_angle_to_target(id, const Float:bow_fTarget[3], Float:bow_TargetSize = 0.0)
{
static Float:bow_fOrigin[3], bow_iAimOrigin[3], Float:bow_fAimOrigin[3], Float:bow_fV1[3]
pev(id, pev_origin, bow_fOrigin)
get_user_origin(id, bow_iAimOrigin, 3)
IVecFVec(bow_iAimOrigin, bow_fAimOrigin)
xs_vec_sub(bow_fAimOrigin, bow_fOrigin, bow_fV1)
static Float:bow_fV2[3]
xs_vec_sub(bow_fTarget, bow_fOrigin, bow_fV2)
static bow_iResult; bow_iResult = bow_get_angle_between_vectors(bow_fV1, bow_fV2)
if (bow_TargetSize > 0.0)
{
static Float:bow_fTan; bow_fTan = bow_TargetSize / get_distance_f(bow_fOrigin, bow_fTarget)
static bow_fAngleToTargetSize; bow_fAngleToTargetSize = floatround( floatatan(bow_fTan, degrees) )
bow_iResult -= (bow_iResult > 0) ? bow_fAngleToTargetSize : -bow_fAngleToTargetSize
}
return bow_iResult
}
stock bow_get_angle_between_vectors(const Float:bow_fV1[3], const Float:bow_fV2[3])
{
static Float:bow_fA1[3], Float:bow_fA2[3]
engfunc(EngFunc_VecToAngles, bow_fV1, bow_fA1)
engfunc(EngFunc_VecToAngles, bow_fV2, bow_fA2)
static bow_iResult; bow_iResult = floatround(bow_fA1[1] - bow_fA2[1])
bow_iResult = bow_iResult % 360
bow_iResult = (bow_iResult > 180) ? (bow_iResult - 360) : bow_iResult
return bow_iResult
}
public bow_vex_give(id) { if (!is_user_alive(id) || vx45_corezombie(id)) return 0; bow_g_VexGiving[id]=true; bow_Get_CompoundBow(id); bow_g_VexGiving[id]=false; return bow_vex_has(id) && user_has_weapon(id,CSW_M4A1); }
public bow_vex_remove(id) { bow_Remove_CompoundBow(id); return 1; }
public bow_vex_has(id) { return bow_Get_BitVar(bow_g_Had_CompoundBow, id) ? 1 : 0; }
#define drs_PLUGIN "Dragon Sword"
#define drs_VERSION "2.0"
#define drs_AUTHOR "Dias Leon"
#define drs_V_MODEL "models/v_dragonsword2.mdl"
#define drs_P_MODEL "models/p_dragonsword.mdl"
#define drs_CSW_DRAGONSWORD CSW_KNIFE
#define drs_weapon_dragonsword "weapon_knife"
#define drs_WEAPON_ANIMEXT "knife"
#define drs_DRAW_TIME 1.0
#define drs_SLASH_ROTATE_DAMAGE 75.0
#define drs_SLASH_ROTATE_RADIUS 110.0
#define drs_SLASH_ROTATE_POINT_DIS 60.0
#define drs_SLASH_ROTATE_DELAY_TIME 0.7
#define drs_SLASH_ROTATE_RESET_TIME 1.0
#define drs_SLASH_AHEAD_DAMAGE 90.0
#define drs_SLASH_AHEAD_RADIUS 90.0
#define drs_SLASH_AHEAD_POINT_DIS 30.0
#define drs_SLASH_AHEAD_DELAY_TIME 0.3
#define drs_SLASH_AHEAD_RESET_TIME 0.9
#define drs_STAB_DAMAGE 110.0
#define drs_STAB_RADIUS 100.0
#define drs_STAB_POINT_DIS 80.0
#define drs_STAB_TIME 0.657
#define drs_STAB_RESET_TIME 0.75
#define drs_TASK_SLASHING 2033+20
#define drs_TASK_STABING 2033+10
const drs_PDATA_SAFE = 2
const drs_OFFSET_LINUX_WEAPONS = 4
const drs_OFFSET_WEAPONOWNER = 41
const drs_m_flNextAttack = 83
const drs_m_szAnimExtention = 492
new const drs_DragonSword_Sound[8][] =
{
"weapons/dragonsword_draw.wav",
"weapons/dragonsword_hit1.wav",
"weapons/dragonsword_hit2.wav",
"weapons/dragonsword_idle.wav",
"weapons/dragonsword_slash1.wav",
"weapons/dragonsword_slash2.wav",
"weapons/dragonsword_stab_hit.wav",
"weapons/dragonsword_wall.wav"
}
enum
{
drs_ATTACK_SLASH_ROTATE = 1,
drs_ATTACK_SLASH_AHEAD,
drs_ATTACK_STAB
}
enum
{
drs_DS_ANIM_IDLE = 0,
drs_DS_ANIM_SLASH_ROTATE,
drs_DS_ANIM_SLASH_AHEAD,
drs_DS_ANIM_DRAW,
drs_DS_ANIM_STAB_BEGIN,
drs_DS_ANIM_STAB_END
}
enum
{
drs_HIT_NOTHING = 0,
drs_HIT_ENEMY,
drs_HIT_WALL
}
new drs_g_Had_DragonSword[33], drs_g_Slashing_Mode[33], drs_g_Attack_Mode[33], drs_g_Checking_Mode[33], drs_g_Hit_Ing[33]
new drs_g_Old_Weapon[33], drs_g_Ham_Bot, drs_g_MaxPlayers
public drs_plugin_init()
{
register_event("HLTV", "drs_Event_NewRound", "a", "1=0", "2=0")
g_zcEvCurWeapon |= (1<<6)
g_zcFm[ZCFM_EmitSound] |= (1<<6)
g_zcFm[ZCFM_CmdStart] |= (1<<6)
g_zcFm[ZCFM_TraceLine] |= (1<<6)
g_zcFm[ZCFM_TraceHull] |= (1<<6)
VxRegisterHam524(Ham_TraceAttack, "player", "drs_fw_PlayerTraceAttack")
drs_g_MaxPlayers = get_maxplayers()
}
public drs_plugin_precache()
{
if (!VexAssetGuard("vx42_dragonsword")) return;
ZcPcModel(drs_V_MODEL)
ZcPcModel(drs_P_MODEL)
for(new i = 0; i < sizeof(drs_DragonSword_Sound); i++)
VexPcSnd(drs_DragonSword_Sound[i], (i==1||i==2||i==4||i==5||i==6||i==7) ? true : false)
}
public drs_get_dragonsword(id)
{
if(!is_user_alive(id))
return
remove_task( (id+drs_TASK_SLASHING) + ZC_TOFF_DRS)
remove_task( (id+drs_TASK_STABING) + ZC_TOFF_DRS)
drs_g_Had_DragonSword[id] = 1
drs_g_Slashing_Mode[id] = 0
drs_g_Attack_Mode[id] = 0
drs_g_Checking_Mode[id] = 0
drs_g_Hit_Ing[id] = 0
if(get_user_weapon(id) == CSW_KNIFE)
{
set_pev(id, pev_viewmodel2, drs_V_MODEL)
set_pev(id, pev_weaponmodel2, drs_P_MODEL)
drs_set_weapon_anim(id, drs_DS_ANIM_DRAW)
drs_set_player_nextattack(id, drs_DRAW_TIME)
} else {
engclient_cmd(id, drs_weapon_dragonsword)
}
}
public drs_remove_dragonsword(id)
{
remove_task( (id+drs_TASK_SLASHING) + ZC_TOFF_DRS)
remove_task( (id+drs_TASK_STABING) + ZC_TOFF_DRS)
drs_g_Had_DragonSword[id] = 0
drs_g_Slashing_Mode[id] = 0
drs_g_Attack_Mode[id] = 0
drs_g_Checking_Mode[id] = 0
drs_g_Hit_Ing[id] = 0
}
public drs_client_putinserver(id)
{
if(!drs_g_Ham_Bot && is_user_bot(id))
{
drs_g_Ham_Bot = 1
set_task(0.1, "drs_Do_RegisterHam_Bot", (id) + ZC_TOFF_DRS)
}
}
public drs_Do_RegisterHam_Bot(id)
{ if (id >= ZC_TOFF_DRS && id < ZC_TOFF_DRS + 0x1000000) id -= ZC_TOFF_DRS;
RegisterHamFromEntity(Ham_TraceAttack, id, "drs_fw_PlayerTraceAttack")
}
public drs_Event_NewRound()
{
for(new i = 1; i <= drs_g_MaxPlayers; i++)
drs_remove_dragonsword(i)
}
public drs_Event_CurWeapon(id)
{
if(!is_user_alive(id))
return
if((read_data(2) == drs_CSW_DRAGONSWORD && drs_g_Old_Weapon[id] != drs_CSW_DRAGONSWORD) && drs_g_Had_DragonSword[id])
{
set_pev(id, pev_viewmodel2, drs_V_MODEL)
set_pev(id, pev_weaponmodel2, drs_P_MODEL)
drs_set_weapon_anim(id, drs_DS_ANIM_DRAW)
drs_set_player_nextattack(id, drs_DRAW_TIME)
set_pdata_string(id, drs_m_szAnimExtention * 4, drs_WEAPON_ANIMEXT, -1 , 20)
}
drs_g_Old_Weapon[id] = read_data(2)
}
public drs_fw_EmitSound(id, channel, const sample[], Float:volume, Float:drs_attn, flags, pitch)
{
if(!is_user_connected(id))
return FMRES_IGNORED
if( !drs_g_Had_DragonSword[id])
return FMRES_IGNORED
if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
{
if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
return FMRES_SUPERCEDE
if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
{
if (sample[17] == 'w')
{
drs_g_Hit_Ing[id] = drs_HIT_WALL
return FMRES_SUPERCEDE
} else {
drs_g_Hit_Ing[id] = drs_HIT_ENEMY
return FMRES_SUPERCEDE
}
}
if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
return FMRES_SUPERCEDE;
}
return FMRES_IGNORED
}
public drs_fw_CmdStart(id, uc_handle, seed)
{
if (!is_user_alive(id))
return FMRES_IGNORED
if(get_user_weapon(id) != drs_CSW_DRAGONSWORD || !drs_g_Had_DragonSword[id])
return FMRES_IGNORED
static ent; ent = fm_get_user_weapon_entity(id, drs_CSW_DRAGONSWORD)
if(!pev_valid(ent))
return FMRES_IGNORED
if(get_pdata_float(ent, 46, drs_OFFSET_LINUX_WEAPONS) > 0.0 || get_pdata_float(ent, 47, drs_OFFSET_LINUX_WEAPONS) > 0.0)
return FMRES_IGNORED
static drs_CurButton
drs_CurButton = get_uc(uc_handle, UC_Buttons)
if (drs_CurButton & IN_ATTACK)
{
set_uc(uc_handle, UC_Buttons, drs_CurButton & ~IN_ATTACK)
if(!drs_g_Slashing_Mode[id])
{
drs_g_Attack_Mode[id] = drs_ATTACK_SLASH_ROTATE
drs_g_Checking_Mode[id] = 1
ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
drs_g_Checking_Mode[id] = 0
set_pev(id, pev_framerate, 1.5)
drs_set_weapons_timeidle(id, drs_CSW_DRAGONSWORD, drs_SLASH_ROTATE_RESET_TIME)
drs_set_player_nextattack(id, drs_SLASH_ROTATE_RESET_TIME)
drs_set_weapon_anim(id, drs_DS_ANIM_SLASH_ROTATE)
set_task(drs_SLASH_ROTATE_DELAY_TIME, "drs_Do_Slashing_Rotate", (id+drs_TASK_SLASHING) + ZC_TOFF_DRS)
} else {
drs_g_Attack_Mode[id] = drs_ATTACK_SLASH_AHEAD
drs_g_Checking_Mode[id] = 1
ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
drs_g_Checking_Mode[id] = 0
set_pev(id, pev_framerate, 2.0)
drs_set_weapons_timeidle(id, drs_CSW_DRAGONSWORD, drs_SLASH_AHEAD_RESET_TIME)
drs_set_player_nextattack(id, drs_SLASH_AHEAD_RESET_TIME)
drs_set_weapon_anim(id, drs_DS_ANIM_SLASH_AHEAD)
set_task(drs_SLASH_AHEAD_DELAY_TIME, "drs_Do_Slashing_Ahead", (id+drs_TASK_SLASHING) + ZC_TOFF_DRS)
}
drs_g_Slashing_Mode[id] = !drs_g_Slashing_Mode[id]
} else if (drs_CurButton & IN_ATTACK2) {
set_uc(uc_handle, UC_Buttons, drs_CurButton & ~IN_ATTACK2)
drs_g_Attack_Mode[id] = drs_ATTACK_STAB
drs_g_Checking_Mode[id] = 1
ExecuteHamB(Ham_Weapon_SecondaryAttack, ent)
drs_g_Checking_Mode[id] = 0
set_pev(id, pev_framerate, 1.5)
drs_set_weapons_timeidle(id, drs_CSW_DRAGONSWORD, drs_STAB_TIME + 0.1)
drs_set_player_nextattack(id, drs_STAB_TIME + 0.1)
drs_set_weapon_anim(id, drs_DS_ANIM_STAB_BEGIN)
remove_task( (id+drs_TASK_STABING) + ZC_TOFF_DRS)
set_task(drs_STAB_TIME, "drs_Do_StabNow", (id+drs_TASK_STABING) + ZC_TOFF_DRS)
}
return FMRES_IGNORED;
}
public drs_Do_Slashing_Rotate(id)
{ if (id >= ZC_TOFF_DRS && id < ZC_TOFF_DRS + 0x1000000) id -= ZC_TOFF_DRS;
id -= drs_TASK_SLASHING
if(!is_user_alive(id))
return
if(get_user_weapon(id) != drs_CSW_DRAGONSWORD || !drs_g_Had_DragonSword[id])
return
if(drs_Check_Attack(id, drs_ATTACK_SLASH_ROTATE))
{
emit_sound(id, CHAN_WEAPON, drs_DragonSword_Sound[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
} else {
if(drs_g_Hit_Ing[id] == drs_HIT_WALL) emit_sound(id, CHAN_WEAPON, drs_DragonSword_Sound[7], 1.0, ATTN_NORM, 0, PITCH_NORM)
else if(drs_g_Hit_Ing[id] == drs_HIT_NOTHING) emit_sound(id, CHAN_WEAPON, drs_DragonSword_Sound[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
drs_g_Attack_Mode[id] = 0
drs_g_Hit_Ing[id] = 0
}
public drs_Do_Slashing_Ahead(id)
{ if (id >= ZC_TOFF_DRS && id < ZC_TOFF_DRS + 0x1000000) id -= ZC_TOFF_DRS;
id -= drs_TASK_SLASHING
if(!is_user_alive(id))
return
if(get_user_weapon(id) != drs_CSW_DRAGONSWORD || !drs_g_Had_DragonSword[id])
return
if(drs_Check_Attack(id, drs_ATTACK_SLASH_AHEAD))
{
emit_sound(id, CHAN_WEAPON, drs_DragonSword_Sound[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
} else {
if(drs_g_Hit_Ing[id] == drs_HIT_WALL) emit_sound(id, CHAN_WEAPON, drs_DragonSword_Sound[7], 1.0, ATTN_NORM, 0, PITCH_NORM)
else if(drs_g_Hit_Ing[id] == drs_HIT_NOTHING) emit_sound(id, CHAN_WEAPON, drs_DragonSword_Sound[5], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
drs_g_Attack_Mode[id] = 0
drs_g_Hit_Ing[id] = 0
}
public drs_Do_StabNow(id)
{ if (id >= ZC_TOFF_DRS && id < ZC_TOFF_DRS + 0x1000000) id -= ZC_TOFF_DRS;
id -= drs_TASK_STABING
if (!is_user_alive(id))
return
if(!drs_g_Had_DragonSword[id])
return
drs_set_weapon_anim(id, drs_DS_ANIM_STAB_END)
if(get_user_weapon(id) != drs_CSW_DRAGONSWORD)
{
drs_set_weapons_timeidle(id, drs_CSW_DRAGONSWORD, 0.0)
drs_set_player_nextattack(id, 0.0)
} else {
drs_set_weapons_timeidle(id, drs_CSW_DRAGONSWORD, drs_STAB_RESET_TIME)
drs_set_player_nextattack(id, drs_STAB_RESET_TIME)
}
if(drs_Check_Attack(id, drs_ATTACK_STAB))
{
emit_sound(id, CHAN_WEAPON, drs_DragonSword_Sound[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
} else {
if(drs_g_Hit_Ing[id] == drs_HIT_WALL) emit_sound(id, CHAN_WEAPON, drs_DragonSword_Sound[7], 1.0, ATTN_NORM, 0, PITCH_NORM)
else if(drs_g_Hit_Ing[id] == drs_HIT_NOTHING) emit_sound(id, CHAN_WEAPON, drs_DragonSword_Sound[6], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
drs_g_Attack_Mode[id] = 0
drs_g_Hit_Ing[id] = 0
}
public drs_Check_Attack(id, drs_Mode)
{
static Float:drs_Max_Distance, Float:drs_Point[4][3], Float:drs_TB_Distance, Float:drs_Point_Dis
if(drs_Mode == drs_ATTACK_SLASH_ROTATE)
{
drs_Point_Dis = drs_SLASH_ROTATE_POINT_DIS
drs_Max_Distance = drs_SLASH_ROTATE_RADIUS
drs_TB_Distance = drs_Max_Distance / 4.0
} else if(drs_Mode == drs_ATTACK_SLASH_AHEAD) {
drs_Point_Dis = drs_SLASH_AHEAD_POINT_DIS
drs_Max_Distance = drs_SLASH_AHEAD_RADIUS
drs_TB_Distance = drs_Max_Distance / 4.0
} else if(drs_Mode == drs_ATTACK_STAB) {
drs_Point_Dis = drs_STAB_POINT_DIS
drs_Max_Distance = drs_STAB_RADIUS
drs_TB_Distance = drs_Max_Distance / 4.0
}
static Float:drs_VicOrigin[3], Float:drs_MyOrigin[3]
pev(id, pev_origin, drs_MyOrigin)
for(new i = 0; i < 4; i++)
drs_get_position(id, drs_TB_Distance * (i + 1), 0.0, 0.0, drs_Point[i])
static drs_Have_Victim; drs_Have_Victim = 0
static ent
ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
if(!pev_valid(ent))
return 0
for(new i = 0; i < get_maxplayers(); i++)
{
if(!is_user_alive(i))
continue
if(id == i)
continue
if(entity_range(id, i) > drs_Max_Distance)
continue
pev(i, pev_origin, drs_VicOrigin)
if(drs_is_wall_between_points(drs_MyOrigin, drs_VicOrigin, id))
continue
if(get_distance_f(drs_VicOrigin, drs_Point[0]) <= drs_Point_Dis
|| get_distance_f(drs_VicOrigin, drs_Point[1]) <= drs_Point_Dis
|| get_distance_f(drs_VicOrigin, drs_Point[2]) <= drs_Point_Dis
|| get_distance_f(drs_VicOrigin, drs_Point[3]) <= drs_Point_Dis)
{
if(!drs_Have_Victim) drs_Have_Victim = 1
if(drs_Mode == drs_ATTACK_SLASH_ROTATE)
drs_do_attack(id, i, ent, drs_SLASH_ROTATE_DAMAGE)
else if(drs_Mode == drs_ATTACK_SLASH_AHEAD)
drs_do_attack(id, i, ent, drs_SLASH_AHEAD_DAMAGE)
else if(drs_Mode == drs_ATTACK_STAB)
drs_do_attack(id, i, ent, drs_STAB_DAMAGE)
}
}
if(drs_Have_Victim)
return 1
else
return 0
}
public drs_fw_TraceLine(Float:drs_vector_start[3], Float:drs_vector_end[3], drs_ignored_monster, id, handle)
{
if (!is_user_alive(id))
return FMRES_IGNORED
if (get_user_weapon(id) != drs_CSW_DRAGONSWORD || !drs_g_Had_DragonSword[id])
return FMRES_IGNORED
static Float:drs_vecStart[3], Float:drs_vecEnd[3], Float:drs_v_angle[3], Float:drs_v_forward[3], Float:view_ofs[3], Float:drs_fOrigin[3]
pev(id, pev_origin, drs_fOrigin)
pev(id, pev_view_ofs, view_ofs)
xs_vec_add(drs_fOrigin, view_ofs, drs_vecStart)
pev(id, pev_v_angle, drs_v_angle)
engfunc(EngFunc_MakeVectors, drs_v_angle)
get_global_vector(GL_v_forward, drs_v_forward)
if(drs_g_Attack_Mode[id] == drs_ATTACK_SLASH_ROTATE) xs_vec_mul_scalar(drs_v_forward, drs_SLASH_ROTATE_RADIUS, drs_v_forward)
else if(drs_g_Attack_Mode[id] == drs_ATTACK_SLASH_AHEAD) xs_vec_mul_scalar(drs_v_forward, drs_SLASH_AHEAD_RADIUS, drs_v_forward)
else if(drs_g_Attack_Mode[id] == drs_ATTACK_STAB) xs_vec_mul_scalar(drs_v_forward, drs_STAB_RADIUS, drs_v_forward)
else xs_vec_mul_scalar(drs_v_forward, 0.0, drs_v_forward)
xs_vec_add(drs_vecStart, drs_v_forward, drs_vecEnd)
engfunc(EngFunc_TraceLine, drs_vecStart, drs_vecEnd, drs_ignored_monster, id, handle)
return FMRES_SUPERCEDE
}
public drs_fw_TraceHull(Float:drs_vector_start[3], Float:drs_vector_end[3], drs_ignored_monster, hull, id, handle)
{
if (!is_user_alive(id))
return FMRES_IGNORED
if (get_user_weapon(id) != drs_CSW_DRAGONSWORD || !drs_g_Had_DragonSword[id])
return FMRES_IGNORED
static Float:drs_vecStart[3], Float:drs_vecEnd[3], Float:drs_v_angle[3], Float:drs_v_forward[3], Float:view_ofs[3], Float:drs_fOrigin[3]
pev(id, pev_origin, drs_fOrigin)
pev(id, pev_view_ofs, view_ofs)
xs_vec_add(drs_fOrigin, view_ofs, drs_vecStart)
pev(id, pev_v_angle, drs_v_angle)
engfunc(EngFunc_MakeVectors, drs_v_angle)
get_global_vector(GL_v_forward, drs_v_forward)
if(drs_g_Attack_Mode[id] == drs_ATTACK_SLASH_ROTATE) xs_vec_mul_scalar(drs_v_forward, drs_SLASH_ROTATE_RADIUS, drs_v_forward)
else if(drs_g_Attack_Mode[id] == drs_ATTACK_SLASH_AHEAD) xs_vec_mul_scalar(drs_v_forward, drs_SLASH_AHEAD_RADIUS, drs_v_forward)
else if(drs_g_Attack_Mode[id] == drs_ATTACK_STAB) xs_vec_mul_scalar(drs_v_forward, drs_STAB_RADIUS, drs_v_forward)
else xs_vec_mul_scalar(drs_v_forward, 0.0, drs_v_forward)
xs_vec_add(drs_vecStart, drs_v_forward, drs_vecEnd)
engfunc(EngFunc_TraceHull, drs_vecStart, drs_vecEnd, drs_ignored_monster, hull, id, handle)
return FMRES_SUPERCEDE
}
public drs_fw_PlayerTraceAttack(drs_Victim, drs_Attacker, Float:Damage, Float:drs_Direction[3], TraceResult, drs_DamageBits)
{
if(!is_user_alive(drs_Attacker))
return HAM_IGNORED
if(!drs_g_Had_DragonSword[drs_Attacker] || !drs_g_Checking_Mode[drs_Attacker])
return HAM_IGNORED
return HAM_SUPERCEDE
}
drs_do_attack(drs_Attacker, drs_Victim, drs_Inflictor, Float:drs_fDamage)
{
drs_fake_player_trace_attack(drs_Attacker, drs_Victim, drs_fDamage)
drs_fake_take_damage(drs_Attacker, drs_Victim, drs_fDamage, drs_Inflictor)
}
drs_fake_player_trace_attack(drs_iAttacker, drs_iVictim, &Float:drs_fDamage)
{
new Float:drs_fAngles[3], Float:drs_fDirection[3]
pev(drs_iAttacker, pev_angles, drs_fAngles)
angle_vector(drs_fAngles, ANGLEVECTOR_FORWARD, drs_fDirection)
new Float:fStart[3], Float:drs_fViewOfs[3]
pev(drs_iAttacker, pev_origin, fStart)
pev(drs_iAttacker, pev_view_ofs, drs_fViewOfs)
xs_vec_add(drs_fViewOfs, fStart, fStart)
new drs_iAimOrigin[3], Float:drs_fAimOrigin[3]
get_user_origin(drs_iAttacker, drs_iAimOrigin, 3)
IVecFVec(drs_iAimOrigin, drs_fAimOrigin)
new ptr = create_tr2()
engfunc(EngFunc_TraceLine, fStart, drs_fAimOrigin, DONT_IGNORE_MONSTERS, drs_iAttacker, ptr)
new drs_pHit = get_tr2(ptr, TR_pHit)
new drs_iHitgroup = get_tr2(ptr, TR_iHitgroup)
new Float:drs_fEndPos[3]
get_tr2(ptr, TR_vecEndPos, drs_fEndPos)
new drs_iTarget, drs_iBody
get_user_aiming(drs_iAttacker, drs_iTarget, drs_iBody)
if (drs_iTarget == drs_iVictim)
{
drs_iHitgroup = drs_iBody
}
else if (drs_pHit != drs_iVictim)
{
new Float:drs_fVicOrigin[3], Float:drs_fVicViewOfs[3], Float:drs_fAimInVictim[3]
pev(drs_iVictim, pev_origin, drs_fVicOrigin)
pev(drs_iVictim, pev_view_ofs, drs_fVicViewOfs)
xs_vec_add(drs_fVicViewOfs, drs_fVicOrigin, drs_fAimInVictim)
drs_fAimInVictim[2] = fStart[2]
drs_fAimInVictim[2] += get_distance_f(fStart, drs_fAimInVictim) * floattan( drs_fAngles[0] * 2.0, degrees )
new drs_iAngleToVictim = drs_get_angle_to_target(drs_iAttacker, drs_fVicOrigin)
drs_iAngleToVictim = abs(drs_iAngleToVictim)
new Float:drs_fDis = 2.0 * get_distance_f(fStart, drs_fAimInVictim) * floatsin( float(drs_iAngleToVictim) * 0.5, degrees )
new Float:drs_fVicSize[3]
pev(drs_iVictim, pev_size , drs_fVicSize)
if ( drs_fDis <= drs_fVicSize[0] * 0.5 )
{
new drs_ptr2 = create_tr2()
engfunc(EngFunc_TraceLine, fStart, drs_fAimInVictim, DONT_IGNORE_MONSTERS, drs_iAttacker, drs_ptr2)
new drs_pHit2 = get_tr2(drs_ptr2, TR_pHit)
new drs_iHitgroup2 = get_tr2(drs_ptr2, TR_iHitgroup)
if ( drs_pHit2 == drs_iVictim && (drs_iHitgroup2 != HIT_HEAD || drs_fDis <= drs_fVicSize[0] * 0.25) )
{
drs_pHit = drs_iVictim
drs_iHitgroup = drs_iHitgroup2
get_tr2(drs_ptr2, TR_vecEndPos, drs_fEndPos)
}
free_tr2(drs_ptr2)
}
if (drs_pHit != drs_iVictim)
{
drs_iHitgroup = HIT_GENERIC
new drs_ptr3 = create_tr2()
engfunc(EngFunc_TraceLine, fStart, drs_fVicOrigin, DONT_IGNORE_MONSTERS, drs_iAttacker, drs_ptr3)
get_tr2(drs_ptr3, TR_vecEndPos, drs_fEndPos)
free_tr2(drs_ptr3)
}
}
set_tr2(ptr, TR_pHit, drs_iVictim)
set_tr2(ptr, TR_iHitgroup, drs_iHitgroup)
set_tr2(ptr, TR_vecEndPos, drs_fEndPos)
new Float:drs_fMultifDamage
switch(drs_iHitgroup)
{
case HIT_HEAD: drs_fMultifDamage  = 4.0
case HIT_STOMACH: drs_fMultifDamage  = 1.25
case HIT_LEFTLEG: drs_fMultifDamage  = 0.75
case HIT_RIGHTLEG: drs_fMultifDamage  = 0.75
default: drs_fMultifDamage  = 1.0
}
drs_fDamage *= drs_fMultifDamage
drs_fake_trake_attack(drs_iAttacker, drs_iVictim, drs_fDamage, drs_fDirection, ptr)
free_tr2(ptr)
}
stock drs_fake_trake_attack(drs_iAttacker, drs_iVictim, Float:drs_fDamage, Float:drs_fDirection[3], drs_iTraceHandle, drs_iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
ExecuteHamB(Ham_TraceAttack, drs_iVictim, drs_iAttacker, drs_fDamage, drs_fDirection, drs_iTraceHandle, drs_iDamageBit)
}
stock drs_fake_take_damage(drs_iAttacker, drs_iVictim, Float:drs_fDamage, drs_iInflictor = 0, drs_iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
drs_iInflictor = (!drs_iInflictor) ? drs_iAttacker : drs_iInflictor
ExecuteHamB(Ham_TakeDamage, drs_iVictim, drs_iInflictor, drs_iAttacker, drs_fDamage, drs_iDamageBit)
}
stock drs_get_angle_to_target(id, const Float:drs_fTarget[3], Float:drs_TargetSize = 0.0)
{
new Float:drs_fOrigin[3], drs_iAimOrigin[3], Float:drs_fAimOrigin[3], Float:drs_fV1[3]
pev(id, pev_origin, drs_fOrigin)
get_user_origin(id, drs_iAimOrigin, 3)
IVecFVec(drs_iAimOrigin, drs_fAimOrigin)
xs_vec_sub(drs_fAimOrigin, drs_fOrigin, drs_fV1)
new Float:drs_fV2[3]
xs_vec_sub(drs_fTarget, drs_fOrigin, drs_fV2)
new drs_iResult = drs_get_angle_between_vectors(drs_fV1, drs_fV2)
if (drs_TargetSize > 0.0)
{
new Float:drs_fTan = drs_TargetSize / get_distance_f(drs_fOrigin, drs_fTarget)
new drs_fAngleToTargetSize = floatround( floatatan(drs_fTan, degrees) )
drs_iResult -= (drs_iResult > 0) ? drs_fAngleToTargetSize : -drs_fAngleToTargetSize
}
return drs_iResult
}
stock drs_get_angle_between_vectors(const Float:drs_fV1[3], const Float:drs_fV2[3])
{
new Float:drs_fA1[3], Float:drs_fA2[3]
engfunc(EngFunc_VecToAngles, drs_fV1, drs_fA1)
engfunc(EngFunc_VecToAngles, drs_fV2, drs_fA2)
new drs_iResult = floatround(drs_fA1[1] - drs_fA2[1])
drs_iResult = drs_iResult % 360
drs_iResult = (drs_iResult > 180) ? (drs_iResult - 360) : drs_iResult
return drs_iResult
}
stock drs_fm_cs_get_weapon_ent_owner(ent)
{
if (pev_valid(ent) != drs_PDATA_SAFE)
return -1
return get_pdata_cbase(ent, drs_OFFSET_WEAPONOWNER, drs_OFFSET_LINUX_WEAPONS)
}
stock drs_set_weapon_anim(id, drs_anim)
{
if(!is_user_alive(id))
return
set_pev(id, pev_weaponanim, drs_anim)
message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
write_byte(drs_anim)
write_byte(0)
message_end()
}
stock drs_set_weapons_timeidle(id, drs_WeaponId ,Float:drs_TimeIdle)
{
if(!is_user_alive(id))
return
static drs_entwpn; drs_entwpn = fm_get_user_weapon_entity(id, drs_WeaponId)
if(!pev_valid(drs_entwpn))
return
set_pdata_float(drs_entwpn, 46, drs_TimeIdle, drs_OFFSET_LINUX_WEAPONS)
set_pdata_float(drs_entwpn, 47, drs_TimeIdle, drs_OFFSET_LINUX_WEAPONS)
set_pdata_float(drs_entwpn, 48, drs_TimeIdle + 0.5, drs_OFFSET_LINUX_WEAPONS)
}
stock drs_set_player_nextattack(id, Float:drs_nexttime)
{
if(!is_user_alive(id))
return
set_pdata_float(id, drs_m_flNextAttack, drs_nexttime, 5)
}
stock drs_is_valid_entity(ent)
{
if(pev_valid(ent) != drs_PDATA_SAFE)
return 0
return 1
}
stock drs_get_position(ent, Float:drs_forw, Float:right, Float:up, Float:drs_vStart[])
{
static Float:drs_vOrigin[3], Float:drs_vAngle[3], Float:drs_vForward[3], Float:drs_vRight[3], Float:drs_vUp[3]
pev(ent, pev_origin, drs_vOrigin)
pev(ent, pev_view_ofs,drs_vUp)
xs_vec_add(drs_vOrigin,drs_vUp,drs_vOrigin)
pev(ent, pev_v_angle, drs_vAngle)
angle_vector(drs_vAngle,ANGLEVECTOR_FORWARD,drs_vForward)
angle_vector(drs_vAngle,ANGLEVECTOR_RIGHT,drs_vRight)
angle_vector(drs_vAngle,ANGLEVECTOR_UP,drs_vUp)
drs_vStart[0] = drs_vOrigin[0] + drs_vForward[0] * drs_forw + drs_vRight[0] * right + drs_vUp[0] * up
drs_vStart[1] = drs_vOrigin[1] + drs_vForward[1] * drs_forw + drs_vRight[1] * right + drs_vUp[1] * up
drs_vStart[2] = drs_vOrigin[2] + drs_vForward[2] * drs_forw + drs_vRight[2] * right + drs_vUp[2] * up
}
stock drs_is_wall_between_points(Float:start[3], Float:end[3], drs_ignore_ent)
{
static ptr
ptr = create_tr2()
engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, drs_ignore_ent, ptr)
static Float:drs_EndPos[3]
get_tr2(ptr, TR_vecEndPos, drs_EndPos)
free_tr2(ptr)
return floatround(get_distance_f(end, drs_EndPos))
}
public drs_vex_give(id) { if (!is_user_alive(id) || vx45_corezombie(id)) return 0; drs_get_dragonsword(id); return drs_vex_has(id); }
public drs_vex_remove(id) { drs_remove_dragonsword(id); return 1; }
public drs_vex_has(id) { return drs_g_Had_DragonSword[id]; }
#define kat_PLUGIN "[CSO] Dual Katana"
#define kat_VERSION "1.0"
#define kat_AUTHOR "Dias"
#define kat_V_MODEL "models/v_katanad.mdl"
#define kat_P_MODEL "models/p_katanad.mdl"
#define kat_CSW_DUALKATANA CSW_KNIFE
#define kat_weapon_dualkatana "weapon_knife"
#define kat_WEAPON_ANIMEXT "dualpistols_1"
#define kat_WEAPON_ANIMEXT2 "knife"
#define kat_DRAW_TIME 1.0
#define kat_SLASH_DAMAGE 40
#define kat_SLASH_RADIUS 100
#define kat_SLASH_RESET_TIME 1.0
#define kat_SLASH1_TIME 0.25
#define kat_SLASH2_TIME1 0.25
#define kat_SLASH2_TIME2 0.5
#define kat_SLASH_RESET_TIME 1.0
#define kat_STAB_DAMAGE 160
#define kat_STAB_RADIUS 90
#define kat_STAB_POINT_DIS 48
#define kat_STAB_TIME 0.5
#define kat_STAB_RESET_TIME 1.0
#define kat_TASK_SET_DAMAGE 1955+10
#define kat_TASK_RESET_DAMAGE 1955+20
const kat_PDATA_SAFE = 2
const kat_OFFSET_LINUX_WEAPONS = 4
const kat_OFFSET_WEAPONOWNER = 41
const kat_m_flNextAttack = 83
const kat_m_szAnimExtention = 492
new const kat_DualKatana_Sound[9][] =
{
"weapons/katanad_draw.wav",
"weapons/katanad_hit1.wav",
"weapons/katanad_hit2.wav",
"weapons/katanad_hitwall.wav",
"weapons/katanad_slash1.wav",
"weapons/katanad_slash2.wav",
"weapons/katanad_slash3.wav",
"weapons/katanad_stab.wav",
"weapons/katanad_stab_miss.wav"
}
enum
{
kat_ATTACK_SLASH1 = 1,
kat_ATTACK_SLASH2,
kat_ATTACK_SLASH3,
kat_ATTACK_STAB
}
enum
{
kat_DK_ANIM_IDLE = 0,
kat_DK_ANIM_FSLASH1,
kat_DK_ANIM_FSLASH2,
kat_DK_ANIM_DRAW,
kat_DK_ANIM_STAB,
kat_DK_ANIM_STAB_MISS,
kat_DK_ANIM_SLASH1,
kat_DK_ANIM_SLASH2,
kat_DK_ANIM_SLASH3
}
enum
{
kat_HIT_NOTHING = 0,
kat_HIT_ENEMY,
kat_HIT_WALL
}
new kat_g_Had_DualKatana[33], kat_g_Slashing_Mode[33], kat_g_Attack_Mode[33], kat_g_Checking_Mode[33], kat_g_Hit_Ing[33]
new kat_g_Old_Weapon[33], kat_g_Ham_Bot
public kat_plugin_init()
{
register_event("DeathMsg", "kat_Event_Death", "a")
g_zcEvCurWeapon |= (1<<7)
g_zcFm[ZCFM_EmitSound] |= (1<<7)
g_zcFm[ZCFM_CmdStart] |= (1<<7)
g_zcFm[ZCFM_TraceLine] |= (1<<7)
g_zcFm[ZCFM_TraceHull] |= (1<<7)
VxRegisterHam524(Ham_TraceAttack, "player", "kat_fw_PlayerTraceAttack")
VxRegisterHam524(Ham_Item_Deploy, kat_weapon_dualkatana, "kat_fw_Item_Deploy_Post", 1)
}
public kat_plugin_precache()
{
if (!VexAssetGuard("vx42_katana")) return;
ZcPcModel(kat_V_MODEL)
ZcPcModel(kat_P_MODEL)
for(new i = 0; i < sizeof(kat_DualKatana_Sound); i++)
VexPcSnd(kat_DualKatana_Sound[i], (i==1||i==2||i==3||i==4||i==5||i==6||i==7||i==8) ? true : false)
}
public kat_get_dualkatana(id)
{
if(!is_user_alive(id))
return
kat_g_Had_DualKatana[id] = 1
kat_g_Slashing_Mode[id] = 0
kat_g_Attack_Mode[id] = 0
kat_g_Checking_Mode[id] = 0
kat_g_Hit_Ing[id] = 0
kat_g_Had_DualKatana[id] = 1
fm_give_item(id, kat_weapon_dualkatana)
if(get_user_weapon(id) == CSW_KNIFE)
{
set_pev(id, pev_viewmodel2, kat_V_MODEL)
set_pev(id, pev_weaponmodel2, kat_P_MODEL)
kat_set_weapon_anim(id, kat_DK_ANIM_DRAW)
kat_set_player_nextattack(id, kat_DRAW_TIME)
} else {
engclient_cmd(id, kat_weapon_dualkatana)
}
}
public kat_remove_dualkatana(id)
{
kat_g_Had_DualKatana[id] = 0
kat_g_Slashing_Mode[id] = 0
kat_g_Attack_Mode[id] = 0
kat_g_Checking_Mode[id] = 0
kat_g_Hit_Ing[id] = 0
}
public kat_client_putinserver(id)
{
if(!kat_g_Ham_Bot && is_user_bot(id))
{
kat_g_Ham_Bot = 1
set_task(0.1, "kat_Do_RegisterHam_Bot", (id) + ZC_TOFF_KAT)
}
}
public kat_Do_RegisterHam_Bot(id)
{ if (id >= ZC_TOFF_KAT && id < ZC_TOFF_KAT + 0x1000000) id -= ZC_TOFF_KAT;
RegisterHamFromEntity(Ham_TraceAttack, id, "kat_fw_PlayerTraceAttack")
}
public kat_Event_Death()
{
static kat_Victim; kat_Victim = read_data(2)
kat_remove_dualkatana(kat_Victim)
}
public kat_Event_CurWeapon(id)
{
if(!is_user_alive(id))
return
if(!kat_g_Had_DualKatana[id])
return
if(get_user_weapon(id) == kat_CSW_DUALKATANA && kat_g_Old_Weapon[id] != kat_CSW_DUALKATANA)
{
kat_set_weapon_anim(id, kat_DK_ANIM_DRAW)
kat_set_player_nextattack(id, kat_DRAW_TIME)
set_pdata_string(id, kat_m_szAnimExtention * 4, kat_WEAPON_ANIMEXT, -1 , 20)
}
kat_g_Old_Weapon[id] = get_user_weapon(id)
}
public kat_fw_CmdStart(id, uc_handle, seed)
{
if (!is_user_alive(id))
return FMRES_IGNORED
if(get_user_weapon(id) != kat_CSW_DUALKATANA || !kat_g_Had_DualKatana[id])
return FMRES_IGNORED
static ent; ent = fm_get_user_weapon_entity(id, kat_CSW_DUALKATANA)
if(!pev_valid(ent))
return FMRES_IGNORED
if(get_pdata_float(ent, 46, kat_OFFSET_LINUX_WEAPONS) > 0.0 || get_pdata_float(ent, 47, kat_OFFSET_LINUX_WEAPONS) > 0.0)
return FMRES_IGNORED
static kat_CurButton
kat_CurButton = get_uc(uc_handle, UC_Buttons)
if (kat_CurButton & IN_ATTACK)
{
set_uc(uc_handle, UC_Buttons, kat_CurButton & ~IN_ATTACK)
if(kat_g_Slashing_Mode[id] == 0) kat_g_Slashing_Mode[id] = 1
kat_g_Slashing_Mode[id]++
if(kat_g_Slashing_Mode[id] > kat_ATTACK_SLASH3) kat_g_Slashing_Mode[id] = 1
if(kat_g_Slashing_Mode[id] == 1)
{
kat_g_Attack_Mode[id] = kat_ATTACK_SLASH1
set_pdata_string(id, kat_m_szAnimExtention * 4, kat_WEAPON_ANIMEXT2, -1 , 20)
kat_g_Checking_Mode[id] = 1
ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
kat_g_Checking_Mode[id] = 0
set_pev(id, pev_framerate, 0.75)
kat_set_weapons_timeidle(id, kat_CSW_DUALKATANA, kat_SLASH_RESET_TIME)
kat_set_player_nextattack(id, kat_SLASH_RESET_TIME)
kat_set_weapon_anim(id, kat_DK_ANIM_SLASH1)
set_task(kat_SLASH1_TIME, "kat_Do_Slashing", (id+kat_TASK_SET_DAMAGE) + ZC_TOFF_KAT)
} else if(kat_g_Slashing_Mode[id] == 2) {
kat_g_Attack_Mode[id] = kat_ATTACK_SLASH2
set_pdata_string(id, kat_m_szAnimExtention * 4, kat_WEAPON_ANIMEXT2, -1 , 20)
kat_g_Checking_Mode[id] = 1
ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
kat_g_Checking_Mode[id] = 0
set_pev(id, pev_framerate, 1.0)
kat_set_weapons_timeidle(id, kat_CSW_DUALKATANA, kat_SLASH_RESET_TIME)
kat_set_player_nextattack(id, kat_SLASH_RESET_TIME)
kat_set_weapon_anim(id, kat_DK_ANIM_SLASH2)
set_task(kat_SLASH2_TIME1, "kat_Do_Slashing", (id+kat_TASK_SET_DAMAGE) + ZC_TOFF_KAT)
set_task(kat_SLASH2_TIME2, "kat_Do_Slashing", (id+kat_TASK_SET_DAMAGE) + ZC_TOFF_KAT)
} else if(kat_g_Slashing_Mode[id] == 3) {
kat_g_Attack_Mode[id] = kat_ATTACK_SLASH3
set_pdata_string(id, kat_m_szAnimExtention * 4, kat_WEAPON_ANIMEXT2, -1 , 20)
kat_g_Checking_Mode[id] = 1
ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
kat_g_Checking_Mode[id] = 0
set_pev(id, pev_framerate, 1.0)
kat_set_weapons_timeidle(id, kat_CSW_DUALKATANA, kat_SLASH_RESET_TIME)
kat_set_player_nextattack(id, kat_SLASH_RESET_TIME)
kat_set_weapon_anim(id, kat_DK_ANIM_SLASH3)
set_task(kat_SLASH2_TIME1, "kat_Do_Slashing", (id+kat_TASK_SET_DAMAGE) + ZC_TOFF_KAT)
set_task(kat_SLASH2_TIME2, "kat_Do_Slashing", (id+kat_TASK_SET_DAMAGE) + ZC_TOFF_KAT)
}
} else if (kat_CurButton & IN_ATTACK2) {
set_uc(uc_handle, UC_Buttons, kat_CurButton & ~IN_ATTACK2)
set_pdata_string(id, kat_m_szAnimExtention * 4, kat_WEAPON_ANIMEXT2, -1 , 20)
kat_g_Attack_Mode[id] = kat_ATTACK_STAB
kat_g_Checking_Mode[id] = 1
ExecuteHamB(Ham_Weapon_SecondaryAttack, ent)
kat_g_Checking_Mode[id] = 0
kat_set_weapons_timeidle(id, kat_CSW_DUALKATANA, kat_STAB_TIME + 0.1)
kat_set_player_nextattack(id, kat_STAB_TIME + 0.1)
kat_set_weapon_anim(id, kat_DK_ANIM_STAB)
remove_task( (id+kat_TASK_SET_DAMAGE) + ZC_TOFF_KAT)
set_task(kat_STAB_TIME, "kat_Do_StabNow", (id+kat_TASK_SET_DAMAGE) + ZC_TOFF_KAT)
}
return FMRES_IGNORED;
}
public kat_Do_Slashing(id)
{ if (id >= ZC_TOFF_KAT && id < ZC_TOFF_KAT + 0x1000000) id -= ZC_TOFF_KAT;
id -= kat_TASK_SET_DAMAGE
if (!is_user_alive(id))
return
if(get_user_weapon(id) != kat_CSW_DUALKATANA)
return
if(!kat_g_Had_DualKatana[id])
return
static kat_Body, kat_Target
get_user_aiming(id, kat_Target, kat_Body, kat_SLASH_RADIUS)
static kat_Ent; kat_Ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
if(!pev_valid(kat_Ent)) kat_Ent = 0
if(is_user_alive(kat_Target))
{
emit_sound(id, CHAN_WEAPON, kat_DualKatana_Sound[random_num(1, 2)], 1.0, ATTN_NORM, 0, PITCH_NORM)
kat_do_attack(id, kat_Target, kat_Ent, float(kat_SLASH_DAMAGE))
} else {
if(kat_g_Hit_Ing[id] == kat_HIT_WALL) emit_sound(id, CHAN_WEAPON, kat_DualKatana_Sound[3], 1.0, ATTN_NORM, 0, PITCH_NORM)
else if(kat_g_Hit_Ing[id] == kat_HIT_NOTHING) emit_sound(id, CHAN_WEAPON, kat_DualKatana_Sound[random_num(4, 6)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
set_pdata_string(id, kat_m_szAnimExtention * 4, kat_WEAPON_ANIMEXT, -1 , 20)
}
public kat_Do_StabNow(id)
{ if (id >= ZC_TOFF_KAT && id < ZC_TOFF_KAT + 0x1000000) id -= ZC_TOFF_KAT;
id -= kat_TASK_SET_DAMAGE
if (!is_user_alive(id))
return
if(get_user_weapon(id) != kat_CSW_DUALKATANA)
return
if(!kat_g_Had_DualKatana[id])
return
kat_set_weapons_timeidle(id, kat_CSW_DUALKATANA, kat_STAB_RESET_TIME)
kat_set_player_nextattack(id, kat_STAB_RESET_TIME)
if(kat_Check_StabAttack(id))
{
emit_sound(id, CHAN_WEAPON, kat_DualKatana_Sound[7], 1.0, ATTN_NORM, 0, PITCH_NORM)
} else {
if(kat_g_Hit_Ing[id] == kat_HIT_WALL) emit_sound(id, CHAN_WEAPON, kat_DualKatana_Sound[3], 1.0, ATTN_NORM, 0, PITCH_NORM)
else if(kat_g_Hit_Ing[id] == kat_HIT_NOTHING) emit_sound(id, CHAN_WEAPON, kat_DualKatana_Sound[8], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
set_pdata_string(id, kat_m_szAnimExtention * 4, kat_WEAPON_ANIMEXT, -1 , 20)
kat_g_Attack_Mode[id] = 0
kat_g_Hit_Ing[id] = 0
}
public kat_Check_StabAttack(id)
{
static Float:kat_Max_Distance, Float:kat_Point[4][3], Float:kat_TB_Distance, Float:kat_Point_Dis
kat_Point_Dis = float(kat_STAB_POINT_DIS)
kat_Max_Distance = float(kat_STAB_RADIUS)
kat_TB_Distance = kat_Max_Distance / 4.0
static Float:kat_VicOrigin[3], Float:kat_MyOrigin[3]
pev(id, pev_origin, kat_MyOrigin)
for(new i = 0; i < 4; i++)
kat_get_position(id, kat_TB_Distance * (i + 1), 0.0, 0.0, kat_Point[i])
static kat_Have_Victim; kat_Have_Victim = 0
static ent
ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
if(!pev_valid(ent))
return 0
for(new i = 0; i < get_maxplayers(); i++)
{
if(!is_user_alive(i))
continue
if(id == i)
continue
if(entity_range(id, i) > kat_Max_Distance)
continue
pev(i, pev_origin, kat_VicOrigin)
if(kat_is_wall_between_points(kat_MyOrigin, kat_VicOrigin, id))
continue
if(get_distance_f(kat_VicOrigin, kat_Point[0]) <= kat_Point_Dis
|| get_distance_f(kat_VicOrigin, kat_Point[1]) <= kat_Point_Dis
|| get_distance_f(kat_VicOrigin, kat_Point[2]) <= kat_Point_Dis
|| get_distance_f(kat_VicOrigin, kat_Point[3]) <= kat_Point_Dis)
{
if(!kat_Have_Victim) kat_Have_Victim = 1
kat_do_attack(id, i, ent, float(kat_STAB_DAMAGE))
}
}
return kat_Have_Victim ? 1 : 0
}
public kat_fw_EmitSound(id, channel, const sample[], Float:volume, Float:kat_attn, flags, pitch)
{
if(!is_user_connected(id))
return FMRES_IGNORED
if(get_user_weapon(id) != kat_CSW_DUALKATANA || !kat_g_Had_DualKatana[id])
return FMRES_IGNORED
if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
{
if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
{
kat_g_Hit_Ing[id] = kat_HIT_NOTHING
return FMRES_SUPERCEDE
}
if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
{
if (sample[17] == 'w')
{
kat_g_Hit_Ing[id] = kat_HIT_WALL
return FMRES_SUPERCEDE
} else {
kat_g_Hit_Ing[id] = kat_HIT_ENEMY
return FMRES_SUPERCEDE
}
}
if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
return FMRES_SUPERCEDE;
}
return FMRES_IGNORED
}
public kat_fw_TraceLine(Float:kat_vector_start[3], Float:kat_vector_end[3], kat_ignored_monster, id, handle)
{
if (!is_user_alive(id))
return FMRES_IGNORED
if (get_user_weapon(id) != kat_CSW_DUALKATANA || !kat_g_Had_DualKatana[id])
return FMRES_IGNORED
static Float:kat_vecStart[3], Float:kat_vecEnd[3], Float:kat_v_angle[3], Float:kat_v_forward[3], Float:view_ofs[3], Float:kat_fOrigin[3]
pev(id, pev_origin, kat_fOrigin)
pev(id, pev_view_ofs, view_ofs)
xs_vec_add(kat_fOrigin, view_ofs, kat_vecStart)
pev(id, pev_v_angle, kat_v_angle)
engfunc(EngFunc_MakeVectors, kat_v_angle)
get_global_vector(GL_v_forward, kat_v_forward)
if(kat_g_Attack_Mode[id] == kat_ATTACK_SLASH1 || kat_g_Attack_Mode[id] == kat_ATTACK_SLASH2 || kat_g_Attack_Mode[id] == kat_ATTACK_SLASH3)
xs_vec_mul_scalar(kat_v_forward, float(kat_SLASH_RADIUS), kat_v_forward)
else if(kat_g_Attack_Mode[id] == kat_ATTACK_STAB) xs_vec_mul_scalar(kat_v_forward, float(kat_STAB_RADIUS), kat_v_forward)
else xs_vec_mul_scalar(kat_v_forward, 0.0, kat_v_forward)
xs_vec_add(kat_vecStart, kat_v_forward, kat_vecEnd)
engfunc(EngFunc_TraceLine, kat_vecStart, kat_vecEnd, kat_ignored_monster, id, handle)
return FMRES_SUPERCEDE
}
public kat_fw_TraceHull(Float:kat_vector_start[3], Float:kat_vector_end[3], kat_ignored_monster, hull, id, handle)
{
if (!is_user_alive(id))
return FMRES_IGNORED
if (get_user_weapon(id) != kat_CSW_DUALKATANA || !kat_g_Had_DualKatana[id])
return FMRES_IGNORED
static Float:kat_vecStart[3], Float:kat_vecEnd[3], Float:kat_v_angle[3], Float:kat_v_forward[3], Float:view_ofs[3], Float:kat_fOrigin[3]
pev(id, pev_origin, kat_fOrigin)
pev(id, pev_view_ofs, view_ofs)
xs_vec_add(kat_fOrigin, view_ofs, kat_vecStart)
pev(id, pev_v_angle, kat_v_angle)
engfunc(EngFunc_MakeVectors, kat_v_angle)
get_global_vector(GL_v_forward, kat_v_forward)
if(kat_g_Attack_Mode[id] == kat_ATTACK_SLASH1 || kat_g_Attack_Mode[id] == kat_ATTACK_SLASH2 || kat_g_Attack_Mode[id] == kat_ATTACK_SLASH3)
xs_vec_mul_scalar(kat_v_forward, float(kat_SLASH_RADIUS), kat_v_forward)
else if(kat_g_Attack_Mode[id] == kat_ATTACK_STAB) xs_vec_mul_scalar(kat_v_forward, float(kat_STAB_RADIUS), kat_v_forward)
else xs_vec_mul_scalar(kat_v_forward, 0.0, kat_v_forward)
xs_vec_add(kat_vecStart, kat_v_forward, kat_vecEnd)
engfunc(EngFunc_TraceHull, kat_vecStart, kat_vecEnd, kat_ignored_monster, hull, id, handle)
return FMRES_SUPERCEDE
}
public kat_fw_PlayerTraceAttack(kat_Victim, kat_Attacker, Float:Damage, Float:kat_Direction[3], TraceResult, kat_DamageBits)
{
if(!is_user_alive(kat_Attacker))
return HAM_IGNORED
if(!kat_g_Had_DualKatana[kat_Attacker] || !kat_g_Checking_Mode[kat_Attacker])
return HAM_IGNORED
return HAM_SUPERCEDE
}
public kat_fw_Item_Deploy_Post(ent)
{
static id; id = kat_fm_cs_get_weapon_ent_owner(ent)
if (!pev_valid(id))
return
if(!kat_g_Had_DualKatana[id])
return
set_pev(id, pev_viewmodel2, kat_V_MODEL)
set_pev(id, pev_weaponmodel2, kat_P_MODEL)
}
kat_do_attack(kat_Attacker, kat_Victim, kat_Inflictor, Float:kat_fDamage)
{
kat_fake_player_trace_attack(kat_Attacker, kat_Victim, kat_fDamage)
kat_fake_take_damage(kat_Attacker, kat_Victim, kat_fDamage, kat_Inflictor)
}
kat_fake_player_trace_attack(kat_iAttacker, kat_iVictim, &Float:kat_fDamage)
{
new Float:kat_fAngles[3], Float:kat_fDirection[3]
pev(kat_iAttacker, pev_angles, kat_fAngles)
angle_vector(kat_fAngles, ANGLEVECTOR_FORWARD, kat_fDirection)
new Float:fStart[3], Float:kat_fViewOfs[3]
pev(kat_iAttacker, pev_origin, fStart)
pev(kat_iAttacker, pev_view_ofs, kat_fViewOfs)
xs_vec_add(kat_fViewOfs, fStart, fStart)
new kat_iAimOrigin[3], Float:kat_fAimOrigin[3]
get_user_origin(kat_iAttacker, kat_iAimOrigin, 3)
IVecFVec(kat_iAimOrigin, kat_fAimOrigin)
new ptr = create_tr2()
engfunc(EngFunc_TraceLine, fStart, kat_fAimOrigin, DONT_IGNORE_MONSTERS, kat_iAttacker, ptr)
new kat_pHit = get_tr2(ptr, TR_pHit)
new kat_iHitgroup = get_tr2(ptr, TR_iHitgroup)
new Float:kat_fEndPos[3]
get_tr2(ptr, TR_vecEndPos, kat_fEndPos)
new kat_iTarget, kat_iBody
get_user_aiming(kat_iAttacker, kat_iTarget, kat_iBody)
if (kat_iTarget == kat_iVictim)
{
kat_iHitgroup = kat_iBody
}
else if (kat_pHit != kat_iVictim)
{
new Float:kat_fVicOrigin[3], Float:kat_fVicViewOfs[3], Float:kat_fAimInVictim[3]
pev(kat_iVictim, pev_origin, kat_fVicOrigin)
pev(kat_iVictim, pev_view_ofs, kat_fVicViewOfs)
xs_vec_add(kat_fVicViewOfs, kat_fVicOrigin, kat_fAimInVictim)
kat_fAimInVictim[2] = fStart[2]
kat_fAimInVictim[2] += get_distance_f(fStart, kat_fAimInVictim) * floattan( kat_fAngles[0] * 2.0, degrees )
new kat_iAngleToVictim = kat_get_angle_to_target(kat_iAttacker, kat_fVicOrigin)
kat_iAngleToVictim = abs(kat_iAngleToVictim)
new Float:kat_fDis = 2.0 * get_distance_f(fStart, kat_fAimInVictim) * floatsin( float(kat_iAngleToVictim) * 0.5, degrees )
new Float:kat_fVicSize[3]
pev(kat_iVictim, pev_size , kat_fVicSize)
if ( kat_fDis <= kat_fVicSize[0] * 0.5 )
{
new kat_ptr2 = create_tr2()
engfunc(EngFunc_TraceLine, fStart, kat_fAimInVictim, DONT_IGNORE_MONSTERS, kat_iAttacker, kat_ptr2)
new kat_pHit2 = get_tr2(kat_ptr2, TR_pHit)
new kat_iHitgroup2 = get_tr2(kat_ptr2, TR_iHitgroup)
if ( kat_pHit2 == kat_iVictim && (kat_iHitgroup2 != HIT_HEAD || kat_fDis <= kat_fVicSize[0] * 0.25) )
{
kat_pHit = kat_iVictim
kat_iHitgroup = kat_iHitgroup2
get_tr2(kat_ptr2, TR_vecEndPos, kat_fEndPos)
}
free_tr2(kat_ptr2)
}
if (kat_pHit != kat_iVictim)
{
kat_iHitgroup = HIT_GENERIC
new kat_ptr3 = create_tr2()
engfunc(EngFunc_TraceLine, fStart, kat_fVicOrigin, DONT_IGNORE_MONSTERS, kat_iAttacker, kat_ptr3)
get_tr2(kat_ptr3, TR_vecEndPos, kat_fEndPos)
free_tr2(kat_ptr3)
}
}
set_tr2(ptr, TR_pHit, kat_iVictim)
set_tr2(ptr, TR_iHitgroup, kat_iHitgroup)
set_tr2(ptr, TR_vecEndPos, kat_fEndPos)
new Float:kat_fMultifDamage
switch(kat_iHitgroup)
{
case HIT_HEAD: kat_fMultifDamage  = 4.0
case HIT_STOMACH: kat_fMultifDamage  = 1.25
case HIT_LEFTLEG: kat_fMultifDamage  = 0.75
case HIT_RIGHTLEG: kat_fMultifDamage  = 0.75
default: kat_fMultifDamage  = 1.0
}
kat_fDamage *= kat_fMultifDamage
kat_fake_trake_attack(kat_iAttacker, kat_iVictim, kat_fDamage, kat_fDirection, ptr)
free_tr2(ptr)
}
stock kat_fake_trake_attack(kat_iAttacker, kat_iVictim, Float:kat_fDamage, Float:kat_fDirection[3], kat_iTraceHandle, kat_iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
ExecuteHamB(Ham_TraceAttack, kat_iVictim, kat_iAttacker, kat_fDamage, kat_fDirection, kat_iTraceHandle, kat_iDamageBit)
}
stock kat_fake_take_damage(kat_iAttacker, kat_iVictim, Float:kat_fDamage, kat_iInflictor = 0, kat_iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
kat_iInflictor = (!kat_iInflictor) ? kat_iAttacker : kat_iInflictor
ExecuteHamB(Ham_TakeDamage, kat_iVictim, kat_iInflictor, kat_iAttacker, kat_fDamage, kat_iDamageBit)
}
stock kat_get_angle_to_target(id, const Float:kat_fTarget[3], Float:kat_TargetSize = 0.0)
{
new Float:kat_fOrigin[3], kat_iAimOrigin[3], Float:kat_fAimOrigin[3], Float:kat_fV1[3]
pev(id, pev_origin, kat_fOrigin)
get_user_origin(id, kat_iAimOrigin, 3)
IVecFVec(kat_iAimOrigin, kat_fAimOrigin)
xs_vec_sub(kat_fAimOrigin, kat_fOrigin, kat_fV1)
new Float:kat_fV2[3]
xs_vec_sub(kat_fTarget, kat_fOrigin, kat_fV2)
new kat_iResult = kat_get_angle_between_vectors(kat_fV1, kat_fV2)
if (kat_TargetSize > 0.0)
{
new Float:kat_fTan = kat_TargetSize / get_distance_f(kat_fOrigin, kat_fTarget)
new kat_fAngleToTargetSize = floatround( floatatan(kat_fTan, degrees) )
kat_iResult -= (kat_iResult > 0) ? kat_fAngleToTargetSize : -kat_fAngleToTargetSize
}
return kat_iResult
}
stock kat_get_angle_between_vectors(const Float:kat_fV1[3], const Float:kat_fV2[3])
{
new Float:kat_fA1[3], Float:kat_fA2[3]
engfunc(EngFunc_VecToAngles, kat_fV1, kat_fA1)
engfunc(EngFunc_VecToAngles, kat_fV2, kat_fA2)
new kat_iResult = floatround(kat_fA1[1] - kat_fA2[1])
kat_iResult = kat_iResult % 360
kat_iResult = (kat_iResult > 180) ? (kat_iResult - 360) : kat_iResult
return kat_iResult
}
stock kat_fm_cs_get_weapon_ent_owner(ent)
{
if (pev_valid(ent) != kat_PDATA_SAFE)
return -1
return get_pdata_cbase(ent, kat_OFFSET_WEAPONOWNER, kat_OFFSET_LINUX_WEAPONS)
}
stock kat_set_weapons_timeidle(id, kat_WeaponId ,Float:kat_TimeIdle)
{
if(!is_user_alive(id))
return
static kat_entwpn; kat_entwpn = fm_get_user_weapon_entity(id, kat_WeaponId)
if(!pev_valid(kat_entwpn))
return
set_pdata_float(kat_entwpn, 46, kat_TimeIdle, kat_OFFSET_LINUX_WEAPONS)
set_pdata_float(kat_entwpn, 47, kat_TimeIdle, kat_OFFSET_LINUX_WEAPONS)
set_pdata_float(kat_entwpn, 48, kat_TimeIdle + 0.5, kat_OFFSET_LINUX_WEAPONS)
}
stock kat_set_weapon_anim(id, kat_anim)
{
if(!is_user_alive(id))
return
set_pev(id, pev_weaponanim, kat_anim)
message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
write_byte(kat_anim)
write_byte(0)
message_end()
}
stock kat_get_position(ent, Float:kat_forw, Float:right, Float:up, Float:kat_vStart[])
{
static Float:kat_vOrigin[3], Float:kat_vAngle[3], Float:kat_vForward[3], Float:kat_vRight[3], Float:kat_vUp[3]
pev(ent, pev_origin, kat_vOrigin)
pev(ent, pev_view_ofs,kat_vUp)
xs_vec_add(kat_vOrigin,kat_vUp,kat_vOrigin)
pev(ent, pev_v_angle, kat_vAngle)
angle_vector(kat_vAngle,ANGLEVECTOR_FORWARD,kat_vForward)
angle_vector(kat_vAngle,ANGLEVECTOR_RIGHT,kat_vRight)
angle_vector(kat_vAngle,ANGLEVECTOR_UP,kat_vUp)
kat_vStart[0] = kat_vOrigin[0] + kat_vForward[0] * kat_forw + kat_vRight[0] * right + kat_vUp[0] * up
kat_vStart[1] = kat_vOrigin[1] + kat_vForward[1] * kat_forw + kat_vRight[1] * right + kat_vUp[1] * up
kat_vStart[2] = kat_vOrigin[2] + kat_vForward[2] * kat_forw + kat_vRight[2] * right + kat_vUp[2] * up
}
stock kat_set_player_nextattack(id, Float:kat_nexttime)
{
if(!is_user_alive(id))
return
set_pdata_float(id, kat_m_flNextAttack, kat_nexttime, 5)
}
stock kat_is_wall_between_points(Float:start[3], Float:end[3], kat_ignore_ent)
{
static ptr
ptr = create_tr2()
engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, kat_ignore_ent, ptr)
static Float:kat_EndPos[3]
get_tr2(ptr, TR_vecEndPos, kat_EndPos)
free_tr2(ptr)
return floatround(get_distance_f(end, kat_EndPos))
}
public kat_vex_give(id) { if (!is_user_alive(id) || vx45_corezombie(id)) return 0; kat_get_dualkatana(id); return kat_vex_has(id); }
public kat_vex_remove(id) { kat_remove_dualkatana(id); return 1; }
public kat_vex_has(id) { return kat_g_Had_DualKatana[id]; }
#define lsb_PLUGIN "[CSO] LightSaber"
#define lsb_VERSION "1.0"
#define lsb_AUTHOR "Dias Leon"
#define lsb_DAMAGE_LIGHTSABER 62
#define lsb_DAMAGE_ATTACK 31
#define lsb_RADIUS_ON 96
#define lsb_RADIUS_OFF 72
#define lsb_DRAW_TIME 0.75
#define lsb_TURN_TIME 0.5
#define lsb_RESET_TIME 1.5
#define lsb_ANIMEXT1 "onehanded"
#define lsb_ANIMEXT2 "knife"
#define lsb_V_MODEL "models/v_sfsword.mdl"
#define lsb_P_MODEL_ON "models/p_sfsword_on.mdl"
#define lsb_P_MODEL_OFF "models/p_sfsword_off.mdl"
new const lsb_LightSaber_Sounds[14][] =
{
"weapons/sfsword_draw.wav",
"weapons/sfsword_hit1.wav",
"weapons/sfsword_hit2.wav",
"weapons/sfsword_idle.wav",
"weapons/sfsword_midslash1.wav",
"weapons/sfsword_midslash2.wav",
"weapons/sfsword_midslash3.wav",
"weapons/sfsword_off.wav",
"weapons/sfsword_off_hit.wav",
"weapons/sfsword_off_slash1.wav",
"weapons/sfsword_on.wav",
"weapons/sfsword_stab.wav",
"weapons/sfsword_wall1.wav",
"weapons/sfsword_wall2.wav"
}
enum
{
lsb_LS_ANIM_IDLE_ON = 0,
lsb_LS_ANIM_ON,
lsb_LS_ANIM_OFF,
lsb_LS_ANIM_DRAW,
lsb_LS_ANIM_STAB,
lsb_LS_ANIM_STAB_MISS,
lsb_LS_ANIM_MIDSLASH1,
lsb_LS_ANIM_MIDSLASH2,
lsb_LS_ANIM_MIDSLASH3,
lsb_LS_ANIM_IDLE_OFF,
lsb_LS_ANIM_SLASH_OFF
}
#define lsb_CSW_LIGHTSABER CSW_KNIFE
#define lsb_weapon_lightsaber "weapon_knife"
#define lsb_TASK_TURN 4234234
#define lsb_TASK_SLASH 6948638
#define lsb_TASK_RESET 54893534
#define lsb_Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define lsb_Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define lsb_UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
enum
{
lsb_HIT_NOTHING = 0,
lsb_HIT_ENEMY,
lsb_HIT_WALL
}
enum
{
lsb_ATTACK_SLASH1 = 0,
lsb_ATTACK_SLASH2,
lsb_ATTACK_SLASH3
}
new lsb_g_Had_LightSaber, lsb_g_IsOnMode, lsb_g_TempingAttack, lsb_g_InSpecialAttack
new lsb_g_OldWeapon[33], lsb_g_WillBeHit[33], lsb_g_AttackingMode[33]
new lsb_g_MaxPlayers, lsb_g_Ham_Bot
public lsb_plugin_init()
{
g_zcEvCurWeapon |= (1<<8)
g_zcFm[ZCFM_CmdStart] |= (1<<8)
g_zcFm[ZCFM_EmitSound] |= (1<<8)
g_zcFm[ZCFM_TraceLine] |= (1<<8)
g_zcFm[ZCFM_TraceHull] |= (1<<8)
VxRegisterHam524(Ham_TraceAttack, "player", "lsb_fw_TraceAttack")
VxRegisterHam524(Ham_Weapon_WeaponIdle, lsb_weapon_lightsaber, "lsb_fw_Weapon_WeaponIdle_Post", 1)
lsb_g_MaxPlayers = get_maxplayers()
}
public lsb_plugin_precache()
{
if (!VexAssetGuard("vx42_lightsaber")) return;
ZcPcModel(lsb_V_MODEL)
ZcPcModel(lsb_P_MODEL_ON)
ZcPcModel(lsb_P_MODEL_OFF)
for(new i = 0; i < sizeof(lsb_LightSaber_Sounds); i++)
VexPcSnd(lsb_LightSaber_Sounds[i], (i==1||i==2||i==8||i==12||i==13) ? true : false)
}
public lsb_client_putinserver(id)
{
lsb_Remove_LightSaber(id)
if(!lsb_g_Ham_Bot && is_user_bot(id))
{
lsb_g_Ham_Bot = 1
set_task(0.1, "lsb_Do_RegisterHam_Bot", (id) + ZC_TOFF_LSB)
}
}
public lsb_Do_RegisterHam_Bot(id)
{ if (id >= ZC_TOFF_LSB && id < ZC_TOFF_LSB + 0x1000000) id -= ZC_TOFF_LSB;
RegisterHamFromEntity(Ham_TraceAttack, id, "lsb_fw_TraceAttack")
}
public lsb_Get_LightSaber(id)
{
if(!is_user_alive(id))
return
lsb_Set_BitVar(lsb_g_Had_LightSaber, id)
lsb_Set_BitVar(lsb_g_IsOnMode, id)
lsb_UnSet_BitVar(lsb_g_TempingAttack, id)
lsb_UnSet_BitVar(lsb_g_InSpecialAttack, id)
lsb_g_WillBeHit[id] = lsb_HIT_NOTHING
lsb_g_AttackingMode[id] = 0
remove_task( (id+lsb_TASK_TURN) + ZC_TOFF_LSB)
remove_task( (id+lsb_TASK_SLASH) + ZC_TOFF_LSB)
remove_task( (id+lsb_TASK_RESET) + ZC_TOFF_LSB)
fm_give_item(id, lsb_weapon_lightsaber)
if(get_user_weapon(id) == lsb_CSW_LIGHTSABER)
{
set_pev(id, pev_viewmodel2, lsb_V_MODEL)
set_pev(id, pev_weaponmodel2, lsb_Get_BitVar(lsb_g_IsOnMode, id) ? lsb_P_MODEL_ON : lsb_P_MODEL_OFF)
lsb_set_player_nextattack(id, lsb_DRAW_TIME)
lsb_set_weapons_timeidle(id, lsb_CSW_LIGHTSABER, lsb_DRAW_TIME + 0.5)
lsb_set_weapon_anim(id, lsb_LS_ANIM_DRAW)
} else {
engclient_cmd(id, lsb_weapon_lightsaber)
}
}
public lsb_Remove_LightSaber(id)
{
lsb_UnSet_BitVar(lsb_g_Had_LightSaber, id)
lsb_UnSet_BitVar(lsb_g_IsOnMode, id)
lsb_UnSet_BitVar(lsb_g_TempingAttack, id)
lsb_UnSet_BitVar(lsb_g_InSpecialAttack, id)
lsb_g_WillBeHit[id] = lsb_HIT_NOTHING
lsb_g_AttackingMode[id] = 0
remove_task( (id+lsb_TASK_TURN) + ZC_TOFF_LSB)
remove_task( (id+lsb_TASK_SLASH) + ZC_TOFF_LSB)
remove_task( (id+lsb_TASK_RESET) + ZC_TOFF_LSB)
}
public lsb_Event_CurWeapon(id)
{
if(!is_user_alive(id))
return
static lsb_CSWID; lsb_CSWID = read_data(2)
if((lsb_CSWID == lsb_CSW_LIGHTSABER && lsb_g_OldWeapon[id] != lsb_CSW_LIGHTSABER) && lsb_Get_BitVar(lsb_g_Had_LightSaber, id))
{
set_pev(id, pev_viewmodel2, lsb_V_MODEL)
set_pev(id, pev_weaponmodel2, lsb_Get_BitVar(lsb_g_IsOnMode, id) ? lsb_P_MODEL_ON : lsb_P_MODEL_OFF)
lsb_set_player_nextattack(id, lsb_DRAW_TIME)
lsb_set_weapons_timeidle(id, lsb_CSW_LIGHTSABER, lsb_DRAW_TIME + 0.5)
lsb_set_weapon_anim(id, lsb_LS_ANIM_DRAW)
set_pdata_string(id, (492) * 4, lsb_ANIMEXT1, -1 , 20)
} else if(lsb_CSWID != lsb_CSW_LIGHTSABER && lsb_g_OldWeapon[id] == lsb_CSW_LIGHTSABER) {
lsb_g_AttackingMode[id] = 0
lsb_Set_BitVar(lsb_g_IsOnMode, id)
lsb_UnSet_BitVar(lsb_g_InSpecialAttack, id)
remove_task( (id+lsb_TASK_TURN) + ZC_TOFF_LSB)
}
lsb_g_OldWeapon[id] = lsb_CSWID
}
public lsb_fw_EmitSound(id, channel, const sample[], Float:volume, Float:lsb_attn, flags, pitch)
{
if(!is_user_connected(id))
return FMRES_IGNORED
if(get_user_weapon(id) != lsb_CSW_LIGHTSABER || !lsb_Get_BitVar(lsb_g_Had_LightSaber, id))
return FMRES_IGNORED
if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
{
if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
{
lsb_g_WillBeHit[id] = lsb_HIT_NOTHING
return FMRES_SUPERCEDE
}
if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
{
if (sample[17] == 'w')
{
lsb_g_WillBeHit[id] = lsb_HIT_WALL
return FMRES_SUPERCEDE
} else {
lsb_g_WillBeHit[id] = lsb_HIT_ENEMY
return FMRES_SUPERCEDE
}
}
if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
return FMRES_SUPERCEDE;
}
return FMRES_IGNORED
}
public lsb_fw_CmdStart(id, uc_handle, seed)
{
if(!is_user_alive(id))
return FMRES_IGNORED
if(get_user_weapon(id) != lsb_CSW_LIGHTSABER || !lsb_Get_BitVar(lsb_g_Had_LightSaber, id))
return FMRES_IGNORED
static ent; ent = fm_get_user_weapon_entity(id, lsb_CSW_LIGHTSABER)
if(!pev_valid(ent))
return FMRES_IGNORED
if(get_pdata_float(id, 83, 5) > 0.0)
return FMRES_IGNORED
static lsb_CurButton; lsb_CurButton = get_uc(uc_handle, UC_Buttons)
if(lsb_CurButton & IN_ATTACK)
{
lsb_CurButton &= ~IN_ATTACK
set_uc(uc_handle, UC_Buttons, lsb_CurButton)
if(lsb_Get_BitVar(lsb_g_IsOnMode, id))
{
if(!lsb_Get_BitVar(lsb_g_InSpecialAttack, id))
{
if(lsb_g_AttackingMode[id] == 0) lsb_g_AttackingMode[id] = 1
lsb_g_AttackingMode[id]++
if(lsb_g_AttackingMode[id] > lsb_ATTACK_SLASH3) lsb_g_AttackingMode[id] = 1
set_pdata_string(id, (492) * 4, lsb_ANIMEXT2, -1 , 20)
lsb_Set_BitVar(lsb_g_TempingAttack, id)
ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
lsb_UnSet_BitVar(lsb_g_TempingAttack, id)
lsb_set_weapons_timeidle(id, lsb_CSW_LIGHTSABER, 1.0)
lsb_set_player_nextattack(id, 1.0)
if(lsb_g_AttackingMode[id] == 1) lsb_set_weapon_anim(id, lsb_LS_ANIM_MIDSLASH1)
else if(lsb_g_AttackingMode[id] == 2) lsb_set_weapon_anim(id, lsb_LS_ANIM_MIDSLASH2)
else if(lsb_g_AttackingMode[id] == 3) lsb_set_weapon_anim(id, lsb_LS_ANIM_MIDSLASH3)
set_task(0.25, "lsb_Damage_Slash", (id+lsb_TASK_SLASH) + ZC_TOFF_LSB)
set_task(lsb_RESET_TIME, "lsb_Reset_Anim", (id+lsb_TASK_RESET) + ZC_TOFF_LSB)
lsb_Set_BitVar(lsb_g_InSpecialAttack, id)
} else {
set_pdata_string(id, (492) * 4, lsb_ANIMEXT2, -1 , 20)
lsb_Set_BitVar(lsb_g_TempingAttack, id)
ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
lsb_UnSet_BitVar(lsb_g_TempingAttack, id)
lsb_set_weapons_timeidle(id, lsb_CSW_LIGHTSABER, 1.0)
lsb_set_player_nextattack(id, 1.0)
lsb_set_weapon_anim(id, lsb_LS_ANIM_STAB)
set_task(0.25, "lsb_Damage_Stab", (id+lsb_TASK_SLASH) + ZC_TOFF_LSB)
set_task(0.5, "lsb_Damage_Stab", (id+lsb_TASK_SLASH) + ZC_TOFF_LSB)
set_task(lsb_RESET_TIME, "lsb_Reset_Anim", (id+lsb_TASK_RESET) + ZC_TOFF_LSB)
lsb_UnSet_BitVar(lsb_g_InSpecialAttack, id)
}
} else {
set_pdata_string(id, (492) * 4, lsb_ANIMEXT2, -1 , 20)
lsb_Set_BitVar(lsb_g_TempingAttack, id)
ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
lsb_UnSet_BitVar(lsb_g_TempingAttack, id)
lsb_set_weapons_timeidle(id, lsb_CSW_LIGHTSABER, 1.0)
lsb_set_player_nextattack(id, 1.0)
lsb_set_weapon_anim(id, lsb_LS_ANIM_SLASH_OFF)
set_task(0.25, "lsb_Damage_OffStab", (id+lsb_TASK_SLASH) + ZC_TOFF_LSB)
set_task(lsb_RESET_TIME, "lsb_Reset_Anim", (id+lsb_TASK_RESET) + ZC_TOFF_LSB)
lsb_UnSet_BitVar(lsb_g_InSpecialAttack, id)
}
} else if(lsb_CurButton & IN_ATTACK2) {
lsb_CurButton &= ~IN_ATTACK2
set_uc(uc_handle, UC_Buttons, lsb_CurButton)
lsb_set_weapon_anim(id, !lsb_Get_BitVar(lsb_g_IsOnMode, id) ? lsb_LS_ANIM_ON : lsb_LS_ANIM_OFF)
lsb_set_player_nextattack(id, lsb_TURN_TIME)
lsb_set_weapons_timeidle(id, lsb_CSW_LIGHTSABER, lsb_TURN_TIME)
set_task(lsb_TURN_TIME - 0.1, "lsb_Turn_Complete", (id+lsb_TASK_TURN) + ZC_TOFF_LSB)
}
return FMRES_IGNORED;
}
public lsb_Turn_Complete(id)
{ if (id >= ZC_TOFF_LSB && id < ZC_TOFF_LSB + 0x1000000) id -= ZC_TOFF_LSB;
id -= lsb_TASK_TURN
if(!is_user_alive(id))
return
if(get_user_weapon(id) != lsb_CSW_LIGHTSABER || !lsb_Get_BitVar(lsb_g_Had_LightSaber, id))
return
if(lsb_Get_BitVar(lsb_g_IsOnMode, id)) lsb_UnSet_BitVar(lsb_g_IsOnMode, id)
else lsb_Set_BitVar(lsb_g_IsOnMode, id)
set_pev(id, pev_weaponmodel2, lsb_Get_BitVar(lsb_g_IsOnMode, id) ? lsb_P_MODEL_ON : lsb_P_MODEL_OFF)
set_pdata_string(id, (492) * 4, lsb_Get_BitVar(lsb_g_IsOnMode, id) ? lsb_ANIMEXT1 : lsb_ANIMEXT2, -1 , 20)
}
public lsb_Reset_Anim(id)
{ if (id >= ZC_TOFF_LSB && id < ZC_TOFF_LSB + 0x1000000) id -= ZC_TOFF_LSB;
id -= lsb_TASK_RESET
if(!is_user_alive(id))
return
if(get_user_weapon(id) != lsb_CSW_LIGHTSABER || !lsb_Get_BitVar(lsb_g_Had_LightSaber, id))
return
set_pdata_string(id, (492) * 4, lsb_Get_BitVar(lsb_g_IsOnMode, id) ? lsb_ANIMEXT1 : lsb_ANIMEXT2, -1 , 20)
}
public lsb_Damage_Slash(id)
{ if (id >= ZC_TOFF_LSB && id < ZC_TOFF_LSB + 0x1000000) id -= ZC_TOFF_LSB;
id -= lsb_TASK_SLASH
if(!is_user_alive(id))
return
if(get_user_weapon(id) != lsb_CSW_LIGHTSABER || !lsb_Get_BitVar(lsb_g_Had_LightSaber, id))
return
static lsb_Target; lsb_Target = lsb_CheckAttack(id, float(lsb_RADIUS_ON), 48.0, float(lsb_DAMAGE_LIGHTSABER))
if(lsb_Target) emit_sound(id, CHAN_WEAPON, lsb_LightSaber_Sounds[random_num(1, 2)], 1.0, ATTN_NORM, 0, PITCH_NORM)
else if(lsb_g_WillBeHit[id] == lsb_HIT_WALL) emit_sound(id, CHAN_WEAPON, lsb_LightSaber_Sounds[random_num(12, 13)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
public lsb_Damage_Stab(id)
{ if (id >= ZC_TOFF_LSB && id < ZC_TOFF_LSB + 0x1000000) id -= ZC_TOFF_LSB;
id -= lsb_TASK_SLASH
if(!is_user_alive(id))
return
if(get_user_weapon(id) != lsb_CSW_LIGHTSABER || !lsb_Get_BitVar(lsb_g_Had_LightSaber, id))
return
static lsb_Target; lsb_Target = lsb_CheckAttack(id, float(lsb_RADIUS_ON), 48.0, float(lsb_DAMAGE_LIGHTSABER))
if(lsb_Target) emit_sound(id, CHAN_WEAPON, lsb_LightSaber_Sounds[random_num(1, 2)], 1.0, ATTN_NORM, 0, PITCH_NORM)
else if(lsb_g_WillBeHit[id] == lsb_HIT_WALL) emit_sound(id, CHAN_WEAPON, lsb_LightSaber_Sounds[random_num(12, 13)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
public lsb_Damage_OffStab(id)
{ if (id >= ZC_TOFF_LSB && id < ZC_TOFF_LSB + 0x1000000) id -= ZC_TOFF_LSB;
id -= lsb_TASK_SLASH
if(!is_user_alive(id))
return
if(get_user_weapon(id) != lsb_CSW_LIGHTSABER || !lsb_Get_BitVar(lsb_g_Had_LightSaber, id))
return
static lsb_Ent; lsb_Ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
if(!pev_valid(lsb_Ent)) lsb_Ent = 0
static lsb_Target; lsb_Target = lsb_CheckAttack(id, float(lsb_RADIUS_OFF), 24.0, float(lsb_DAMAGE_ATTACK))
if(lsb_Target) emit_sound(id, CHAN_WEAPON, lsb_LightSaber_Sounds[8], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
public lsb_CheckAttack(id, Float:lsb_Radius, Float:lsb_PointDis, Float:Damage)
{
static Float:lsb_Max_Distance, Float:lsb_Point[4][3], Float:lsb_TB_Distance, Float:lsb_Point_Dis
lsb_Point_Dis = lsb_PointDis
lsb_Max_Distance = lsb_Radius
lsb_TB_Distance = lsb_Max_Distance / 4.0
static Float:lsb_VicOrigin[3], Float:lsb_MyOrigin[3]
pev(id, pev_origin, lsb_MyOrigin)
for(new i = 0; i < 4; i++) lsb_get_position(id, lsb_TB_Distance * (i + 1), 0.0, 0.0, lsb_Point[i])
static lsb_Have_Victim; lsb_Have_Victim = 0
static ent; ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
if(!pev_valid(ent))
return 0
for(new i = 1; i <= lsb_g_MaxPlayers; i++)
{
if(!is_user_alive(i))
continue
if(id == i)
continue
if(entity_range(id, i) > lsb_Max_Distance)
continue
pev(i, pev_origin, lsb_VicOrigin)
if(lsb_is_wall_between_points(lsb_MyOrigin, lsb_VicOrigin, id))
continue
if(get_distance_f(lsb_VicOrigin, lsb_Point[0]) <= lsb_Point_Dis
|| get_distance_f(lsb_VicOrigin, lsb_Point[1]) <= lsb_Point_Dis
|| get_distance_f(lsb_VicOrigin, lsb_Point[2]) <= lsb_Point_Dis
|| get_distance_f(lsb_VicOrigin, lsb_Point[3]) <= lsb_Point_Dis)
{
if(!lsb_Have_Victim) lsb_Have_Victim = 1
lsb_do_attack(id, i, ent, Damage)
}
}
if(lsb_Have_Victim) return 1
return 0
}
public lsb_fw_TraceLine(Float:lsb_vector_start[3], Float:lsb_vector_end[3], lsb_ignored_monster, id, handle)
{
if(!is_user_alive(id))
return FMRES_IGNORED
if(get_user_weapon(id) != lsb_CSW_LIGHTSABER || !lsb_Get_BitVar(lsb_g_Had_LightSaber, id))
return FMRES_IGNORED
static Float:lsb_vecStart[3], Float:lsb_vecEnd[3], Float:lsb_v_angle[3], Float:lsb_v_forward[3], Float:view_ofs[3], Float:lsb_fOrigin[3]
pev(id, pev_origin, lsb_fOrigin)
pev(id, pev_view_ofs, view_ofs)
xs_vec_add(lsb_fOrigin, view_ofs, lsb_vecStart)
pev(id, pev_v_angle, lsb_v_angle)
engfunc(EngFunc_MakeVectors, lsb_v_angle)
get_global_vector(GL_v_forward, lsb_v_forward)
if(lsb_Get_BitVar(lsb_g_TempingAttack, id)) xs_vec_mul_scalar(lsb_v_forward, (lsb_Get_BitVar(lsb_g_IsOnMode, id) ? float(lsb_RADIUS_ON) : float(lsb_RADIUS_OFF)), lsb_v_forward)
else xs_vec_mul_scalar(lsb_v_forward, 0.0, lsb_v_forward)
xs_vec_add(lsb_vecStart, lsb_v_forward, lsb_vecEnd)
engfunc(EngFunc_TraceLine, lsb_vecStart, lsb_vecEnd, lsb_ignored_monster, id, handle)
return FMRES_SUPERCEDE
}
public lsb_fw_TraceHull(Float:lsb_vector_start[3], Float:lsb_vector_end[3], lsb_ignored_monster, hull, id, handle)
{
if(!is_user_alive(id))
return FMRES_IGNORED
if(get_user_weapon(id) != lsb_CSW_LIGHTSABER || !lsb_Get_BitVar(lsb_g_Had_LightSaber, id))
return FMRES_IGNORED
static Float:lsb_vecStart[3], Float:lsb_vecEnd[3], Float:lsb_v_angle[3], Float:lsb_v_forward[3], Float:view_ofs[3], Float:lsb_fOrigin[3]
pev(id, pev_origin, lsb_fOrigin)
pev(id, pev_view_ofs, view_ofs)
xs_vec_add(lsb_fOrigin, view_ofs, lsb_vecStart)
pev(id, pev_v_angle, lsb_v_angle)
engfunc(EngFunc_MakeVectors, lsb_v_angle)
get_global_vector(GL_v_forward, lsb_v_forward)
if(lsb_Get_BitVar(lsb_g_TempingAttack, id)) xs_vec_mul_scalar(lsb_v_forward, (lsb_Get_BitVar(lsb_g_IsOnMode, id) ? float(lsb_RADIUS_ON) : float(lsb_RADIUS_OFF)), lsb_v_forward)
else xs_vec_mul_scalar(lsb_v_forward, 0.0, lsb_v_forward)
xs_vec_add(lsb_vecStart, lsb_v_forward, lsb_vecEnd)
engfunc(EngFunc_TraceHull, lsb_vecStart, lsb_vecEnd, lsb_ignored_monster, hull, id, handle)
return FMRES_SUPERCEDE
}
public lsb_fw_TraceAttack(lsb_Victim, lsb_Attacker, Float:Damage, Float:lsb_Direction[3], TraceResult, lsb_DamageBits)
{
if(!is_user_alive(lsb_Attacker))
return HAM_IGNORED
if(!lsb_Get_BitVar(lsb_g_Had_LightSaber, lsb_Attacker) || !lsb_Get_BitVar(lsb_g_TempingAttack, lsb_Attacker))
return HAM_IGNORED
return HAM_SUPERCEDE
}
public lsb_fw_Weapon_WeaponIdle_Post(ent)
{
static id; id = pev(ent, pev_owner)
if(!is_user_alive(id))
return HAM_IGNORED
if(!lsb_Get_BitVar(lsb_g_Had_LightSaber, id))
return HAM_IGNORED
if(get_pdata_float(ent, 48, 4) <= 0.25)
{
lsb_set_weapon_anim(id, lsb_Get_BitVar(lsb_g_IsOnMode, id) ? lsb_LS_ANIM_IDLE_ON : lsb_LS_ANIM_IDLE_OFF)
set_pdata_float(ent, 48, 20.0, 4)
}
return HAM_IGNORED
}
stock lsb_is_wall_between_points(Float:start[3], Float:end[3], lsb_ignore_ent)
{
static ptr
ptr = create_tr2()
engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, lsb_ignore_ent, ptr)
static Float:lsb_EndPos[3]
get_tr2(ptr, TR_vecEndPos, lsb_EndPos)
free_tr2(ptr)
return floatround(get_distance_f(end, lsb_EndPos))
}
lsb_do_attack(lsb_Attacker, lsb_Victim, lsb_Inflictor, Float:lsb_fDamage)
{
lsb_fake_player_trace_attack(lsb_Attacker, lsb_Victim, lsb_fDamage)
lsb_fake_take_damage(lsb_Attacker, lsb_Victim, lsb_fDamage, lsb_Inflictor)
}
lsb_fake_player_trace_attack(lsb_iAttacker, lsb_iVictim, &Float:lsb_fDamage)
{
static Float:lsb_fAngles[3], Float:lsb_fDirection[3]
pev(lsb_iAttacker, pev_angles, lsb_fAngles)
angle_vector(lsb_fAngles, ANGLEVECTOR_FORWARD, lsb_fDirection)
static Float:fStart[3], Float:lsb_fViewOfs[3]
pev(lsb_iAttacker, pev_origin, fStart)
pev(lsb_iAttacker, pev_view_ofs, lsb_fViewOfs)
xs_vec_add(lsb_fViewOfs, fStart, fStart)
static lsb_iAimOrigin[3], Float:lsb_fAimOrigin[3]
get_user_origin(lsb_iAttacker, lsb_iAimOrigin, 3)
IVecFVec(lsb_iAimOrigin, lsb_fAimOrigin)
static ptr; ptr = create_tr2()
engfunc(EngFunc_TraceLine, fStart, lsb_fAimOrigin, DONT_IGNORE_MONSTERS, lsb_iAttacker, ptr)
static lsb_pHit; lsb_pHit = get_tr2(ptr, TR_pHit)
static lsb_iHitgroup; lsb_iHitgroup = get_tr2(ptr, TR_iHitgroup)
static Float:lsb_fEndPos[3]; get_tr2(ptr, TR_vecEndPos, lsb_fEndPos)
static lsb_iTarget, lsb_iBody
get_user_aiming(lsb_iAttacker, lsb_iTarget, lsb_iBody)
if (lsb_iTarget == lsb_iVictim)
{
lsb_iHitgroup = lsb_iBody
}
else if (lsb_pHit != lsb_iVictim)
{
static Float:lsb_fVicOrigin[3], Float:lsb_fVicViewOfs[3], Float:lsb_fAimInVictim[3]
pev(lsb_iVictim, pev_origin, lsb_fVicOrigin)
pev(lsb_iVictim, pev_view_ofs, lsb_fVicViewOfs)
xs_vec_add(lsb_fVicViewOfs, lsb_fVicOrigin, lsb_fAimInVictim)
lsb_fAimInVictim[2] = fStart[2]
lsb_fAimInVictim[2] += get_distance_f(fStart, lsb_fAimInVictim) * floattan( lsb_fAngles[0] * 2.0, degrees )
static lsb_iAngleToVictim; lsb_iAngleToVictim = lsb_get_angle_to_target(lsb_iAttacker, lsb_fVicOrigin)
lsb_iAngleToVictim = abs(lsb_iAngleToVictim)
static Float:lsb_fDis; lsb_fDis = 2.0 * get_distance_f(fStart, lsb_fAimInVictim) * floatsin( float(lsb_iAngleToVictim) * 0.5, degrees )
static Float:lsb_fVicSize[3]
pev(lsb_iVictim, pev_size , lsb_fVicSize)
if ( lsb_fDis <= lsb_fVicSize[0] * 0.5 )
{
static lsb_ptr2; lsb_ptr2 = create_tr2()
engfunc(EngFunc_TraceLine, fStart, lsb_fAimInVictim, DONT_IGNORE_MONSTERS, lsb_iAttacker, lsb_ptr2)
static lsb_pHit2; lsb_pHit2 = get_tr2(lsb_ptr2, TR_pHit)
static lsb_iHitgroup2; lsb_iHitgroup2 = get_tr2(lsb_ptr2, TR_iHitgroup)
if ( lsb_pHit2 == lsb_iVictim && (lsb_iHitgroup2 != HIT_HEAD || lsb_fDis <= lsb_fVicSize[0] * 0.25) )
{
lsb_pHit = lsb_iVictim
lsb_iHitgroup = lsb_iHitgroup2
get_tr2(lsb_ptr2, TR_vecEndPos, lsb_fEndPos)
}
free_tr2(lsb_ptr2)
}
if (lsb_pHit != lsb_iVictim)
{
lsb_iHitgroup = HIT_GENERIC
static lsb_ptr3; lsb_ptr3 = create_tr2()
engfunc(EngFunc_TraceLine, fStart, lsb_fVicOrigin, DONT_IGNORE_MONSTERS, lsb_iAttacker, lsb_ptr3)
get_tr2(lsb_ptr3, TR_vecEndPos, lsb_fEndPos)
free_tr2(lsb_ptr3)
}
}
set_tr2(ptr, TR_pHit, lsb_iVictim)
set_tr2(ptr, TR_iHitgroup, lsb_iHitgroup)
set_tr2(ptr, TR_vecEndPos, lsb_fEndPos)
static Float:lsb_fMultifDamage
switch(lsb_iHitgroup)
{
case HIT_HEAD: lsb_fMultifDamage  = 4.0
case HIT_STOMACH: lsb_fMultifDamage  = 1.25
case HIT_LEFTLEG: lsb_fMultifDamage  = 0.75
case HIT_RIGHTLEG: lsb_fMultifDamage  = 0.75
default: lsb_fMultifDamage  = 1.0
}
lsb_fDamage *= lsb_fMultifDamage
lsb_fake_trake_attack(lsb_iAttacker, lsb_iVictim, lsb_fDamage, lsb_fDirection, ptr)
free_tr2(ptr)
}
stock lsb_fake_trake_attack(lsb_iAttacker, lsb_iVictim, Float:lsb_fDamage, Float:lsb_fDirection[3], lsb_iTraceHandle, lsb_iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
ExecuteHamB(Ham_TraceAttack, lsb_iVictim, lsb_iAttacker, lsb_fDamage, lsb_fDirection, lsb_iTraceHandle, lsb_iDamageBit)
}
stock lsb_fake_take_damage(lsb_iAttacker, lsb_iVictim, Float:lsb_fDamage, lsb_iInflictor = 0, lsb_iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
ExecuteHamB(Ham_TakeDamage, lsb_iVictim, lsb_iInflictor, lsb_iAttacker, lsb_fDamage, lsb_iDamageBit)
}
stock lsb_get_angle_to_target(id, const Float:lsb_fTarget[3], Float:lsb_TargetSize = 0.0)
{
static Float:lsb_fOrigin[3], lsb_iAimOrigin[3], Float:lsb_fAimOrigin[3], Float:lsb_fV1[3]
pev(id, pev_origin, lsb_fOrigin)
get_user_origin(id, lsb_iAimOrigin, 3)
IVecFVec(lsb_iAimOrigin, lsb_fAimOrigin)
xs_vec_sub(lsb_fAimOrigin, lsb_fOrigin, lsb_fV1)
static Float:lsb_fV2[3]
xs_vec_sub(lsb_fTarget, lsb_fOrigin, lsb_fV2)
static lsb_iResult; lsb_iResult = lsb_get_angle_between_vectors(lsb_fV1, lsb_fV2)
if (lsb_TargetSize > 0.0)
{
static Float:lsb_fTan; lsb_fTan = lsb_TargetSize / get_distance_f(lsb_fOrigin, lsb_fTarget)
static lsb_fAngleToTargetSize; lsb_fAngleToTargetSize = floatround( floatatan(lsb_fTan, degrees) )
lsb_iResult -= (lsb_iResult > 0) ? lsb_fAngleToTargetSize : -lsb_fAngleToTargetSize
}
return lsb_iResult
}
stock lsb_get_angle_between_vectors(const Float:lsb_fV1[3], const Float:lsb_fV2[3])
{
static Float:lsb_fA1[3], Float:lsb_fA2[3]
engfunc(EngFunc_VecToAngles, lsb_fV1, lsb_fA1)
engfunc(EngFunc_VecToAngles, lsb_fV2, lsb_fA2)
static lsb_iResult; lsb_iResult = floatround(lsb_fA1[1] - lsb_fA2[1])
lsb_iResult = lsb_iResult % 360
lsb_iResult = (lsb_iResult > 180) ? (lsb_iResult - 360) : lsb_iResult
return lsb_iResult
}
stock lsb_get_position(ent, Float:lsb_forw, Float:right, Float:up, Float:lsb_vStart[])
{
static Float:lsb_vOrigin[3], Float:lsb_vAngle[3], Float:lsb_vForward[3], Float:lsb_vRight[3], Float:lsb_vUp[3]
pev(ent, pev_origin, lsb_vOrigin)
pev(ent, pev_view_ofs,lsb_vUp)
xs_vec_add(lsb_vOrigin,lsb_vUp,lsb_vOrigin)
pev(ent, pev_v_angle, lsb_vAngle)
angle_vector(lsb_vAngle,ANGLEVECTOR_FORWARD,lsb_vForward)
angle_vector(lsb_vAngle,ANGLEVECTOR_RIGHT,lsb_vRight)
angle_vector(lsb_vAngle,ANGLEVECTOR_UP,lsb_vUp)
lsb_vStart[0] = lsb_vOrigin[0] + lsb_vForward[0] * lsb_forw + lsb_vRight[0] * right + lsb_vUp[0] * up
lsb_vStart[1] = lsb_vOrigin[1] + lsb_vForward[1] * lsb_forw + lsb_vRight[1] * right + lsb_vUp[1] * up
lsb_vStart[2] = lsb_vOrigin[2] + lsb_vForward[2] * lsb_forw + lsb_vRight[2] * right + lsb_vUp[2] * up
}
stock lsb_set_weapons_timeidle(id, lsb_WeaponId ,Float:lsb_TimeIdle)
{
static lsb_entwpn; lsb_entwpn = fm_get_user_weapon_entity(id, lsb_WeaponId)
if(!pev_valid(lsb_entwpn))
return
set_pdata_float(lsb_entwpn, 46, lsb_TimeIdle, 4)
set_pdata_float(lsb_entwpn, 47, lsb_TimeIdle, 4)
set_pdata_float(lsb_entwpn, 48, lsb_TimeIdle + 0.5, 4)
}
stock lsb_set_weapon_anim(id, lsb_anim)
{
set_pev(id, pev_weaponanim, lsb_anim)
message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
write_byte(lsb_anim)
write_byte(0)
message_end()
}
stock lsb_set_player_nextattack(id, Float:lsb_NextTime) set_pdata_float(id, 83, lsb_NextTime, 5)
public lsb_vex_give(id) { if (!is_user_alive(id) || vx45_corezombie(id)) return 0; lsb_Get_LightSaber(id); return lsb_vex_has(id); }
public lsb_vex_remove(id) { lsb_Remove_LightSaber(id); return 1; }
public lsb_vex_has(id) { return lsb_Get_BitVar(lsb_g_Had_LightSaber, id) ? 1 : 0; }
#define hax_PLUGIN "[CSO] Horse Axe"
#define hax_VERSION "1.0"
#define hax_AUTHOR "2015"
#define hax_DAMAGE_A 120
#define hax_DAMAGE_B 240
#define hax_RADIUS 72.0
#define hax_KNOCKBACK_POWER 350.0
#define hax_MODEL_V "models/v_horseaxe.mdl"
#define hax_MODEL_P "models/p_horseaxe.mdl"
new const hax_HorseAxe_Sounds[8][] =
{
"weapons/tomahawk_draw.wav",
"weapons/tomahawk_slash1.wav",
"weapons/tomahawk_slash1_hit.wav",
"weapons/tomahawk_slash2.wav",
"weapons/tomahawk_slash2_hit.wav",
"weapons/tomahawk_stab_hit.wav",
"weapons/tomahawk_stab_miss.wav",
"weapons/tomahawk_wall.wav"
}
enum
{
hax_ANIM_IDLE = 0,
hax_ANIM_SLASH1,
hax_ANIM_SLASH2,
hax_ANIM_DRAW,
hax_ANIM_STAB,
hax_ANIM_STAB_MISS,
hax_ANIM_MIDSLASH1,
hax_ANIM_MIDSLASH2
}
enum
{
hax_HIT_NOTHING = 0,
hax_HIT_ENEMY,
hax_HIT_WALL
}
#define hax_TASK_CHANGE 2512015
#define hax_TASK_ATTACK 25120152
#define hax_CSW_HORSEAXE CSW_KNIFE
#define hax_weapon_horseaxe "weapon_knife"
#define hax_Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define hax_Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define hax_UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new hax_g_Had_HorseAxe, hax_g_TempingAttack, hax_g_Stab
new hax_g_WillBeHit[33]
new hax_g_IsConnected, hax_g_IsAlive, hax_g_PlayerWeapon[33], hax_g_HamBot
public hax_plugin_init()
{
hax_Register_SafetyFunc()
g_zcFm[ZCFM_EmitSound] |= (1<<9)
g_zcFm[ZCFM_TraceLine] |= (1<<9)
g_zcFm[ZCFM_TraceHull] |= (1<<9)
VxRegisterHam524(Ham_Item_Deploy, hax_weapon_horseaxe, "hax_fw_Item_Deploy_Post", 1)
VxRegisterHam524(Ham_TakeDamage, "player", "hax_fw_TakeDamage")
VxRegisterHam524(Ham_TakeDamage, "player", "hax_fw_TakeDamage_Post", 1)
}
public hax_plugin_precache()
{
if (!VexAssetGuard("vx42_horseaxe")) return;
ZcPcModel(hax_MODEL_V)
ZcPcModel(hax_MODEL_P)
for(new i = 0; i < sizeof(hax_HorseAxe_Sounds); i++)
VexPcSnd(hax_HorseAxe_Sounds[i], (i==1||i==2||i==3||i==4||i==5||i==7) ? true : false)
}
public hax_client_putinserver(id)
{
hax_Safety_Connected(id)
if(!hax_g_HamBot && is_user_bot(id))
{
hax_g_HamBot = 1
set_task(0.1, "hax_Do_Register_HamBot", (id) + ZC_TOFF_HAX)
}
}
public hax_Do_Register_HamBot(id)
{ if (id >= ZC_TOFF_HAX && id < ZC_TOFF_HAX + 0x1000000) id -= ZC_TOFF_HAX;
hax_Register_SafetyFuncBot(id)
RegisterHamFromEntity(Ham_TakeDamage, id, "hax_fw_TakeDamage")
RegisterHamFromEntity(Ham_TakeDamage, id, "hax_fw_TakeDamage_Post", 1)
}
public hax_client_disconnect(id)
{
hax_Safety_Disconnected(id)
}
public hax_Get_HorseAxe(id)
{
hax_Set_BitVar(hax_g_Had_HorseAxe, id)
hax_UnSet_BitVar(hax_g_TempingAttack, id)
hax_g_WillBeHit[id] = hax_HIT_NOTHING
if(get_user_weapon(id) == CSW_KNIFE)
{
set_pev(id, pev_viewmodel2, hax_MODEL_V)
set_pev(id, pev_weaponmodel2, hax_MODEL_P)
hax_Set_WeaponAnim(id, hax_ANIM_DRAW)
} else {
engclient_cmd(id, hax_weapon_horseaxe)
}
}
public hax_Remove_Papin(id)
{
hax_UnSet_BitVar(hax_g_Had_HorseAxe, id)
}
public hax_fw_EmitSound(id, channel, const sample[], Float:volume, Float:hax_attn, flags, pitch)
{
if(!hax_is_connected(id))
return FMRES_IGNORED
if(hax_get_player_weapon(id) != hax_CSW_HORSEAXE || !hax_Get_BitVar(hax_g_Had_HorseAxe, id))
return FMRES_IGNORED
if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
{
if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
{
emit_sound(id, channel, random_num(0, 1) ? hax_HorseAxe_Sounds[1] : hax_HorseAxe_Sounds[3], volume, hax_attn, flags, pitch)
set_task(0.1, "hax_Set_Speed", (id) + ZC_TOFF_HAX)
hax_UnSet_BitVar(hax_g_Stab, id)
return FMRES_SUPERCEDE
}
if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
{
set_task(0.1, "hax_Set_Speed", (id) + ZC_TOFF_HAX)
if (sample[17] == 'w')
{
hax_UnSet_BitVar(hax_g_Stab, id)
emit_sound(id, channel, hax_HorseAxe_Sounds[7], volume, hax_attn, flags, pitch)
return FMRES_SUPERCEDE
} else {
hax_UnSet_BitVar(hax_g_Stab, id)
emit_sound(id, channel, random_num(0, 1) ? hax_HorseAxe_Sounds[2] : hax_HorseAxe_Sounds[4], volume, hax_attn, flags, pitch)
return FMRES_SUPERCEDE
}
}
if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
{
hax_Set_BitVar(hax_g_Stab, id)
emit_sound(id, channel, hax_HorseAxe_Sounds[5], volume, hax_attn, flags, pitch)
set_task(0.1, "hax_Set_Speed2", (id) + ZC_TOFF_HAX)
return FMRES_SUPERCEDE;
}
}
return FMRES_IGNORED
}
public hax_Set_Speed(id)
{ if (id >= ZC_TOFF_HAX && id < ZC_TOFF_HAX + 0x1000000) id -= ZC_TOFF_HAX;
hax_Set_Weapon_Idle(id, hax_CSW_HORSEAXE, 0.25 + 0.3)
hax_Set_Player_NextAttack(id, 0.25)
}
public hax_Set_Speed2(id)
{ if (id >= ZC_TOFF_HAX && id < ZC_TOFF_HAX + 0x1000000) id -= ZC_TOFF_HAX;
hax_Set_Weapon_Idle(id, hax_CSW_HORSEAXE, 0.5 + 0.3)
hax_Set_Player_NextAttack(id, 0.5)
}
public hax_fw_TraceLine(Float:hax_vector_start[3], Float:hax_vector_end[3], hax_ignored_monster, id, handle)
{
if(!hax_is_alive(id))
return FMRES_IGNORED
if(hax_get_player_weapon(id) != hax_CSW_HORSEAXE || !hax_Get_BitVar(hax_g_Had_HorseAxe, id))
return FMRES_IGNORED
static Float:hax_vecStart[3], Float:hax_vecEnd[3], Float:hax_v_angle[3], Float:hax_v_forward[3], Float:view_ofs[3], Float:hax_fOrigin[3]
pev(id, pev_origin, hax_fOrigin)
pev(id, pev_view_ofs, view_ofs)
xs_vec_add(hax_fOrigin, view_ofs, hax_vecStart)
pev(id, pev_v_angle, hax_v_angle)
engfunc(EngFunc_MakeVectors, hax_v_angle)
get_global_vector(GL_v_forward, hax_v_forward)
if(!hax_Get_BitVar(hax_g_TempingAttack, id)) xs_vec_mul_scalar(hax_v_forward, hax_RADIUS, hax_v_forward)
else xs_vec_mul_scalar(hax_v_forward, 0.0, hax_v_forward)
xs_vec_add(hax_vecStart, hax_v_forward, hax_vecEnd)
engfunc(EngFunc_TraceLine, hax_vecStart, hax_vecEnd, hax_ignored_monster, id, handle)
return FMRES_SUPERCEDE
}
public hax_fw_TraceHull(Float:hax_vector_start[3], Float:hax_vector_end[3], hax_ignored_monster, hull, id, handle)
{
if(!hax_is_alive(id))
return FMRES_IGNORED
if(hax_get_player_weapon(id) != hax_CSW_HORSEAXE || !hax_Get_BitVar(hax_g_Had_HorseAxe, id))
return FMRES_IGNORED
static Float:hax_vecStart[3], Float:hax_vecEnd[3], Float:hax_v_angle[3], Float:hax_v_forward[3], Float:view_ofs[3], Float:hax_fOrigin[3]
pev(id, pev_origin, hax_fOrigin)
pev(id, pev_view_ofs, view_ofs)
xs_vec_add(hax_fOrigin, view_ofs, hax_vecStart)
pev(id, pev_v_angle, hax_v_angle)
engfunc(EngFunc_MakeVectors, hax_v_angle)
get_global_vector(GL_v_forward, hax_v_forward)
if(!hax_Get_BitVar(hax_g_TempingAttack, id)) xs_vec_mul_scalar(hax_v_forward, hax_RADIUS, hax_v_forward)
else xs_vec_mul_scalar(hax_v_forward, 0.0, hax_v_forward)
xs_vec_add(hax_vecStart, hax_v_forward, hax_vecEnd)
engfunc(EngFunc_TraceHull, hax_vecStart, hax_vecEnd, hax_ignored_monster, hull, id, handle)
return FMRES_SUPERCEDE
}
public hax_fw_TakeDamage(hax_Victim, hax_Inflictor, hax_Attacker, Float:Damage, hax_DamageBits)
{
if(!hax_is_alive(hax_Attacker))
return HAM_IGNORED
if(hax_get_player_weapon(hax_Attacker) != hax_CSW_HORSEAXE || !hax_Get_BitVar(hax_g_Had_HorseAxe, hax_Attacker))
return HAM_IGNORED
if(hax_Get_BitVar(hax_g_Stab, hax_Attacker))
{
SetHamParamFloat(4, float(hax_DAMAGE_B))
} else {
SetHamParamFloat(4, float(hax_DAMAGE_A))
}
return HAM_HANDLED
}
public hax_fw_TakeDamage_Post(hax_Victim, hax_Inflictor, hax_Attacker, Float:Damage, hax_DamageBits)
{
if(!hax_is_alive(hax_Attacker))
return HAM_IGNORED
if(hax_get_player_weapon(hax_Attacker) != hax_CSW_HORSEAXE || !hax_Get_BitVar(hax_g_Had_HorseAxe, hax_Attacker))
return HAM_IGNORED
if(hax_Get_BitVar(hax_g_Stab, hax_Attacker))
{
static Float:Origin[3]; pev(hax_Attacker, pev_origin, Origin)
if(is_user_alive(hax_Victim)) hax_HookEnt(hax_Victim, Origin, hax_KNOCKBACK_POWER)
}
return HAM_HANDLED
}
public hax_fw_Item_Deploy_Post(hax_Ent)
{
if(pev_valid(hax_Ent) != 2)
return
static hax_Id; hax_Id = get_pdata_cbase(hax_Ent, 41, 4)
if(get_pdata_cbase(hax_Id, 373) != hax_Ent)
return
if(!hax_Get_BitVar(hax_g_Had_HorseAxe, hax_Id))
return
set_pev(hax_Id, pev_viewmodel2, hax_MODEL_V)
set_pev(hax_Id, pev_weaponmodel2, hax_MODEL_P)
hax_PlaySound(hax_Id, hax_HorseAxe_Sounds[0])
hax_Set_WeaponAnim(hax_Id, hax_ANIM_DRAW)
}
stock hax_HookEnt(ent, Float:hax_VicOrigin[3], Float:speed)
{
static Float:hax_fl_Velocity[3]
static Float:hax_EntOrigin[3]
pev(ent, pev_origin, hax_EntOrigin)
static Float:hax_distance_f
hax_distance_f = get_distance_f(hax_EntOrigin, hax_VicOrigin)
static Float:hax_fl_Time; hax_fl_Time = hax_distance_f / speed
hax_fl_Velocity[0] = ((hax_EntOrigin[0] - hax_VicOrigin[0]) / hax_fl_Time) * 1.5
hax_fl_Velocity[1] = ((hax_EntOrigin[1] - hax_VicOrigin[1]) / hax_fl_Time) * 1.5
hax_fl_Velocity[2] = ((hax_EntOrigin[2] - hax_VicOrigin[2]) / hax_fl_Time) + 500.0
set_pev(ent, pev_velocity, hax_fl_Velocity)
}
stock hax_is_wall_between_points(Float:start[3], Float:end[3], hax_ignore_ent)
{
static ptr
ptr = create_tr2()
engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, hax_ignore_ent, ptr)
static Float:hax_EndPos[3]
get_tr2(ptr, TR_vecEndPos, hax_EndPos)
free_tr2(ptr)
return floatround(get_distance_f(end, hax_EndPos))
}
stock hax_Set_WeaponAnim(id, hax_anim)
{
set_pev(id, pev_weaponanim, hax_anim)
message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
write_byte(hax_anim)
write_byte(pev(id, pev_body))
message_end()
}
stock hax_Set_Weapon_Idle(id, hax_WeaponId ,Float:hax_TimeIdle)
{
static hax_entwpn; hax_entwpn = fm_get_user_weapon_entity(id, hax_WeaponId)
if(!pev_valid(hax_entwpn))
return
set_pdata_float(hax_entwpn, 46, hax_TimeIdle, 4)
set_pdata_float(hax_entwpn, 47, hax_TimeIdle, 4)
set_pdata_float(hax_entwpn, 48, hax_TimeIdle + 0.5, 4)
}
stock hax_Set_Player_NextAttack(id, Float:hax_NextTime) set_pdata_float(id, 83, hax_NextTime, 5)
stock hax_PlaySound(id, const sound[])
{
if(equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
else client_cmd(id, "spk ^"%s^"", sound)
}
stock hax_get_position(ent, Float:hax_forw, Float:right, Float:up, Float:hax_vStart[])
{
static Float:hax_vOrigin[3], Float:hax_vAngle[3], Float:hax_vForward[3], Float:hax_vRight[3], Float:hax_vUp[3]
pev(ent, pev_origin, hax_vOrigin)
pev(ent, pev_view_ofs,hax_vUp)
xs_vec_add(hax_vOrigin,hax_vUp,hax_vOrigin)
pev(ent, pev_v_angle, hax_vAngle)
angle_vector(hax_vAngle,ANGLEVECTOR_FORWARD,hax_vForward)
angle_vector(hax_vAngle,ANGLEVECTOR_RIGHT,hax_vRight)
angle_vector(hax_vAngle,ANGLEVECTOR_UP,hax_vUp)
hax_vStart[0] = hax_vOrigin[0] + hax_vForward[0] * hax_forw + hax_vRight[0] * right + hax_vUp[0] * up
hax_vStart[1] = hax_vOrigin[1] + hax_vForward[1] * hax_forw + hax_vRight[1] * right + hax_vUp[1] * up
hax_vStart[2] = hax_vOrigin[2] + hax_vForward[2] * hax_forw + hax_vRight[2] * right + hax_vUp[2] * up
}
public hax_Register_SafetyFunc()
{
g_zcEvCurWeapon |= (1<<9)
VxRegisterHam524(Ham_Spawn, "player", "hax_fw_Safety_Spawn_Post", 1)
VxRegisterHam524(Ham_Killed, "player", "hax_fw_Safety_Killed_Post", 1)
}
public hax_Register_SafetyFuncBot(id)
{
RegisterHamFromEntity(Ham_Spawn, id, "hax_fw_Safety_Spawn_Post", 1)
RegisterHamFromEntity(Ham_Killed, id, "hax_fw_Safety_Killed_Post", 1)
}
public hax_Safety_Connected(id)
{
hax_Set_BitVar(hax_g_IsConnected, id)
hax_UnSet_BitVar(hax_g_IsAlive, id)
hax_g_PlayerWeapon[id] = 0
}
public hax_Safety_Disconnected(id)
{
hax_UnSet_BitVar(hax_g_IsConnected, id)
hax_UnSet_BitVar(hax_g_IsAlive, id)
hax_g_PlayerWeapon[id] = 0
}
public hax_Safety_CurWeapon(id)
{
if(!hax_is_alive(id))
return
static hax_CSW; hax_CSW = read_data(2)
if(hax_g_PlayerWeapon[id] != hax_CSW) hax_g_PlayerWeapon[id] = hax_CSW
}
public hax_fw_Safety_Spawn_Post(id)
{
if(!is_user_alive(id))
return
hax_Set_BitVar(hax_g_IsAlive, id)
}
public hax_fw_Safety_Killed_Post(id)
{
hax_UnSet_BitVar(hax_g_IsAlive, id)
}
public hax_is_connected(id)
{
if(!(1 <= id <= 32))
return 0
if(!hax_Get_BitVar(hax_g_IsConnected, id))
return 0
return 1
}
public hax_is_alive(id)
{
if(!(1 <= id <= 32))
return 0
if(!hax_Get_BitVar(hax_g_IsConnected, id))
return 0
if(hax_Get_BitVar(hax_g_IsAlive, id)) return 1
else return 0
}
public hax_get_player_weapon(id)
{
if(!hax_is_alive(id))
return 0
return hax_g_PlayerWeapon[id]
}
public hax_vex_give(id) { if (!is_user_alive(id) || vx45_corezombie(id)) return 0; hax_Get_HorseAxe(id); return hax_vex_has(id); }
public hax_vex_remove(id) { hax_Remove_Papin(id); return 1; }
public hax_vex_has(id) { return hax_Get_BitVar(hax_g_Had_HorseAxe, id) ? 1 : 0; }
#define hev_zp_get_user_zombie vx45_corezombie
new const hev_HEV_MODEL_SHORT[] = "player_hev";
new const hev_HEV_ZOMBIE_FULL[]  = "models/player/hev_zombie/hev_zombie.mdl";
new const hev_HEV_ZOMBIE_SHORT[] = "hev_zombie";
new const hev_V_HEV_ZOMBIE_KNIFE[] = "models/v_hev_zombie.mdl";
new const hev_V_HEV_MODEL[] = "models/v_hev.mdl"
#define hev_HEV_ANIM_TIME 3.0
#define hev_HEV_ANIM_SEQUENCE 0
new const hev_V_HEV_ADRENALINE[] = "models/v_hev_adrenaline_injector.mdl";
#define hev_ADRENALINE_TIME 3.0
#define hev_ADRENALINE_ANIM_SEQ 0
new const hev_V_HEV_AK47[]      = "models/hev_weapons/v_ak47.mdl";
new const hev_V_HEV_M4A1[]      = "models/hev_weapons/v_m4a1.mdl";
new const hev_V_HEV_MP5NAVY[]   = "models/hev_weapons/v_mp5.mdl";
new const hev_V_HEV_AWP[]       = "models/hev_weapons/v_awp.mdl";
new const hev_V_HEV_DEAGLE[]    = "models/hev_weapons/v_deagle.mdl";
new const hev_V_HEV_GLOCK18[]   = "models/hev_weapons/v_glock18.mdl";
new const hev_V_HEV_AUG[]       = "models/hev_weapons/v_aug.mdl";
new const hev_V_HEV_FAMAS[]     = "models/hev_weapons/v_famas.mdl";
new const hev_V_HEV_M249[]      = "models/hev_weapons/v_m249.mdl";
new const hev_V_HEV_M3[]        = "models/hev_weapons/v_m3.mdl";
new const hev_V_HEV_XM1014[]    = "models/hev_weapons/v_xm1014.mdl";
new const hev_V_HEV_USP[]       = "models/hev_weapons/v_usp.mdl";
new const hev_V_HEV_P228[]      = "models/hev_weapons/v_p228.mdl";
new const hev_V_HEV_P90[]       = "models/hev_weapons/v_p90.mdl";
new const hev_V_HEV_GALIL[]     = "models/hev_weapons/v_galil.mdl";
new const hev_V_HEV_UMP45[]     = "models/hev_weapons/v_ump45.mdl";
new const hev_V_HEV_TMP[]       = "models/hev_weapons/v_tmp.mdl";
new const hev_V_HEV_SG550[]     = "models/hev_weapons/v_sg550.mdl";
new const hev_V_HEV_G3SG1[]     = "models/hev_weapons/v_g3sg1.mdl";
new const hev_V_HEV_WRENCH[]    = "models/hev_weapons/v_wrench.mdl";
new const hev_P_HEV_WRENCH[]    = "models/hev_weapons/p_wrench.mdl";
new const hev_SND_WRENCH_DEPLOY[]    = "weapons/wrench_deploy.wav"
new const hev_SND_WRENCH_HIT[]       = "weapons/wrench_hit.wav"
new const hev_SND_WRENCH_HITWALL[]   = "weapons/wrench_hitwall.wav"
new const hev_SND_WRENCH_SLASH[]     = "weapons/wrench_slash.wav"
new const hev_SND_WRENCH_STAB[]      = "weapons/wrench_stab.wav"
const hev_ITEM_COST = 80
#define hev_MAX_POWER 100
#define hev_JUMP_COST 30
#define hev_REGEN_TICK 2
#define hev_BOOST_THRES 40
#define hev_BOOST_VALUE 250
new hev_g_iItemId, hev_g_maxPlayers, hev_g_MsgSync;
new bool:hev_g_bHasHEV[33], bool:hev_g_bBoughtThisRound[33], bool:hev_g_bMorphineUsed[33], bool:hev_g_bArmorBoostUsed[33], bool:hev_g_bIsHEVZombie[33];
new hev_g_iSuitPower[33], hev_g_ent_playermodel[33];
new hev_g_cvArmor, hev_g_cvHealthBonus, hev_g_cvDamageReduction, hev_g_cvLongJump;
new bool:hev_g_bCriticalPlayed[33];
public hev_plugin_precache()
{
if (!VexAssetGuard("vx42_hev")) return;
static hev_model_path[128];
formatex(hev_model_path, charsmax(hev_model_path), "models/player/%s/%s.mdl", hev_HEV_MODEL_SHORT, hev_HEV_MODEL_SHORT);
ZcPcModel(hev_model_path);
ZcPcModel(hev_HEV_ZOMBIE_FULL);
ZcPcModel(hev_V_HEV_ZOMBIE_KNIFE);
ZcPcModel(hev_V_HEV_MODEL);
ZcPcModel(hev_V_HEV_ADRENALINE);
ZcPcModel(hev_V_HEV_AK47);
ZcPcModel(hev_V_HEV_M4A1);
ZcPcModel(hev_V_HEV_MP5NAVY);
ZcPcModel(hev_V_HEV_AWP);
ZcPcModel(hev_V_HEV_DEAGLE);
ZcPcModel(hev_V_HEV_GLOCK18);
ZcPcModel(hev_V_HEV_AUG);
ZcPcModel(hev_V_HEV_FAMAS);
ZcPcModel(hev_V_HEV_M249);
ZcPcModel(hev_V_HEV_M3);
ZcPcModel(hev_V_HEV_XM1014);
ZcPcModel(hev_V_HEV_USP);
ZcPcModel(hev_V_HEV_P228);
ZcPcModel(hev_V_HEV_P90);
ZcPcModel(hev_V_HEV_GALIL);
ZcPcModel(hev_V_HEV_UMP45);
ZcPcModel(hev_V_HEV_TMP);
ZcPcModel(hev_V_HEV_SG550);
ZcPcModel(hev_V_HEV_G3SG1);
ZcPcModel(hev_V_HEV_WRENCH);
ZcPcModel(hev_P_HEV_WRENCH);
VexPcSnd("fvox/morphine_shot.wav", false);
VexPcSnd("fvox/health_critical.wav", false);
VexPcSnd("fvox/hevSuit_get_infected_alert2.wav", false);
VexPcSnd("fvox/power_restored.wav", false);
VexPcSnd("fvox/hev_logon.wav", false);
VexPcSnd("fvox/flatline.wav", false);
VexPcSnd("player/pl_long_jump_1.wav", false);
ZcPcSound(hev_SND_WRENCH_DEPLOY);
ZcPcSound(hev_SND_WRENCH_HIT);
ZcPcSound(hev_SND_WRENCH_HITWALL);
ZcPcSound(hev_SND_WRENCH_SLASH);
ZcPcSound(hev_SND_WRENCH_STAB);
}
public hev_plugin_init()
{
hev_g_iItemId = -1;
hev_g_cvArmor = register_cvar("zp_hev_armor", "250");
hev_g_cvHealthBonus = register_cvar("zp_hev_health_bonus", "50");
hev_g_cvDamageReduction = register_cvar("zp_hev_damage_reduction", "20");
hev_g_cvLongJump = register_cvar("zp_hev_longjump", "1");
VxRegisterHam524(Ham_Spawn, "player", "hev_fw_PlayerSpawn_Post", 1);
VxRegisterHam524(Ham_Killed, "player", "hev_fw_PlayerKilled");
g_zcFm[ZCFM_PlayerPreThink] |= (1<<10);
g_zcEvCurWeapon |= (1<<10);
g_zcFm[ZCFM_EmitSound] |= (1<<10);
new const hev_weapon_list[][] = {
"weapon_ak47", "weapon_m4a1", "weapon_mp5navy", "weapon_awp",
"weapon_deagle", "weapon_glock18", "weapon_aug", "weapon_famas",
"weapon_m249", "weapon_m3", "weapon_xm1014", "weapon_usp",
"weapon_p228", "weapon_p90", "weapon_sg550", "weapon_g3sg1",
"weapon_galil", "weapon_ump45", "weapon_tmp", "weapon_knife"
};
for(new i = 0; i < sizeof hev_weapon_list; i++)
VxRegisterHam524(Ham_Item_Deploy, hev_weapon_list[i], "hev_fw_Weapon_Deploy_Post", 1);
register_event("HLTV", "hev_event_NewRound", "a", "1=0", "2=0");
hev_g_maxPlayers = get_maxplayers();
hev_g_MsgSync = CreateHudSyncObj();
set_task(1.0, "hev_HEV_MainLoop", ZC_TOFF_HEV, _, _, "b");
}
public hev_Event_CurWeapon(id)
{
if (!is_user_alive(id)) return;
if (hev_g_bHasHEV[id] && !hev_zp_get_user_zombie(id))
{
hev_set_hev_weapon_model(id);
}
else if (hev_zp_get_user_zombie(id) && hev_g_bIsHEVZombie[id])
{
if (get_user_weapon(id) == CSW_KNIFE)
set_pev(id, pev_viewmodel2, hev_V_HEV_ZOMBIE_KNIFE);
}
}
public hev_fw_Weapon_Deploy_Post(ent)
{
if (!pev_valid(ent)) return HAM_IGNORED;
static id;
id = get_pdata_cbase(ent, 41, 4);
if (!is_user_alive(id)) return HAM_IGNORED;
if (hev_g_bHasHEV[id] && !hev_zp_get_user_zombie(id))
{
hev_set_hev_weapon_model(id);
}
return HAM_IGNORED;
}
stock hev_set_hev_weapon_model(id)
{
if (!is_user_alive(id) || !hev_g_bHasHEV[id] || hev_zp_get_user_zombie(id))
return;
static hev_current_model[64];
pev(id, pev_viewmodel2, hev_current_model, charsmax(hev_current_model));
if (equal(hev_current_model, hev_V_HEV_ADRENALINE) || equal(hev_current_model, hev_V_HEV_MODEL))
return;
if (vx45_coreweapon(id)) return;
new hev_iWpn = get_user_weapon(id);
switch(hev_iWpn)
{
case CSW_AK47:      set_pev(id, pev_viewmodel2, hev_V_HEV_AK47);
case CSW_M4A1:      set_pev(id, pev_viewmodel2, hev_V_HEV_M4A1);
case CSW_MP5NAVY:   set_pev(id, pev_viewmodel2, hev_V_HEV_MP5NAVY);
case CSW_AWP:       set_pev(id, pev_viewmodel2, hev_V_HEV_AWP);
case CSW_DEAGLE:    set_pev(id, pev_viewmodel2, hev_V_HEV_DEAGLE);
case CSW_GLOCK18:   set_pev(id, pev_viewmodel2, hev_V_HEV_GLOCK18);
case CSW_AUG:       set_pev(id, pev_viewmodel2, hev_V_HEV_AUG);
case CSW_FAMAS:     set_pev(id, pev_viewmodel2, hev_V_HEV_FAMAS);
case CSW_M3:        set_pev(id, pev_viewmodel2, hev_V_HEV_M3);
case CSW_XM1014:    set_pev(id, pev_viewmodel2, hev_V_HEV_XM1014);
case CSW_USP:       set_pev(id, pev_viewmodel2, hev_V_HEV_USP);
case CSW_G3SG1:     set_pev(id, pev_viewmodel2, hev_V_HEV_G3SG1);
case CSW_P228:      set_pev(id, pev_viewmodel2, hev_V_HEV_P228);
case CSW_P90:       set_pev(id, pev_viewmodel2, hev_V_HEV_P90);
case CSW_GALIL:     set_pev(id, pev_viewmodel2, hev_V_HEV_GALIL);
case CSW_UMP45:     set_pev(id, pev_viewmodel2, hev_V_HEV_UMP45);
case CSW_TMP:       set_pev(id, pev_viewmodel2, hev_V_HEV_TMP);
case CSW_M249:      set_pev(id, pev_viewmodel2, hev_V_HEV_M249);
case CSW_SG550:     set_pev(id, pev_viewmodel2, hev_V_HEV_SG550);
case CSW_KNIFE:
{
if (vx45_corejetpack(id)) return;
set_pev(id, pev_viewmodel2, hev_V_HEV_WRENCH);
set_pev(id, pev_weaponmodel2, hev_P_HEV_WRENCH);
}
}
}
public hev_HEV_MainLoop()
{
for(new i = 1; i <= hev_g_maxPlayers; i++)
{
if(!is_user_alive(i) || !hev_g_bHasHEV[i] || hev_zp_get_user_zombie(i)) continue;
new hev_hp = get_user_health(i);
if (hev_hp <= hev_BOOST_THRES && !hev_g_bMorphineUsed[i]) { hev_g_bMorphineUsed[i] = true; set_user_health(i, hev_BOOST_VALUE); client_cmd(i, "spk fvox/morphine_shot"); }
if (get_user_armor(i) <= hev_BOOST_THRES && !hev_g_bArmorBoostUsed[i]) { hev_g_bArmorBoostUsed[i] = true; cs_set_user_armor(i, hev_BOOST_VALUE, CS_ARMOR_VESTHELM); client_cmd(i, "spk fvox/power_restored"); }
if(hev_hp <= 90 && !hev_g_bCriticalPlayed[i])
{
client_cmd(i, "spk fvox/health_critical");
hev_g_bCriticalPlayed[i] = true;
}
else if(hev_hp > 90 && hev_g_bCriticalPlayed[i])
{
hev_g_bCriticalPlayed[i] = false;
}
if(hev_g_iSuitPower[i] < hev_MAX_POWER) hev_g_iSuitPower[i] = min(hev_MAX_POWER, hev_g_iSuitPower[i] + hev_REGEN_TICK);
if(vx45_corejetpack(i)) continue; // Keep passive HEV bonuses; jetpack owns equipment HUD.
set_hudmessage(255,140,0,0.02,0.84,0,0.0,1.6,0.0,0.0,2);
show_hudmessage(i, "[ HEV Mark V ]^nGuc: %d%% | Can: %d | Zirh: %d",
hev_g_iSuitPower[i], hev_hp, get_user_armor(i));
}
}
public hev_zp_extra_item_selected(id, itemid)
{
if(itemid != hev_g_iItemId) return;
if(hev_g_bHasHEV[id] || hev_g_bBoughtThisRound[id]) {
client_print(id, print_chat, "[HEV] Suit already active.");
return;
}
hev_ActivateHEV(id);
}
hev_ActivateHEV(id)
{
hev_g_bHasHEV[id] = true;
hev_g_bBoughtThisRound[id] = true;
hev_g_bMorphineUsed[id] = false;
hev_g_bArmorBoostUsed[id] = false;
hev_g_bIsHEVZombie[id] = false;
hev_g_iSuitPower[id] = hev_MAX_POWER;
hev_fm_remove_model_ent(id);
if (is_user_connected(id))
{
VxCsSetModel(id, hev_HEV_MODEL_SHORT);
set_pev(id, pev_viewmodel2, hev_V_HEV_MODEL)
hev_util_play_weapon_animation(id, hev_HEV_ANIM_SEQUENCE);
remove_task( (id) + ZC_TOFF_HEV)
set_task(hev_HEV_ANIM_TIME, "hev_restore_weapon_model", (id) + ZC_TOFF_HEV)
}
set_user_health(id, get_user_health(id) + get_pcvar_num(hev_g_cvHealthBonus));
cs_set_user_armor(id, get_pcvar_num(hev_g_cvArmor), CS_ARMOR_VESTHELM);
client_cmd(id, "spk fvox/hev_logon");
hev_ScreenFade(id, {255, 150, 0}, 1.0, 0.5);
}
public hev_restore_weapon_model(id)
{ if (id >= ZC_TOFF_HEV && id < ZC_TOFF_HEV + 0x1000000) id -= ZC_TOFF_HEV;
if (!is_user_alive(id) || hev_zp_get_user_zombie(id)) return;
set_pev(id, pev_viewmodel2, "");
new ent = get_pdata_cbase(id, 373, 5);
if (pev_valid(ent)) ExecuteHamB(Ham_Item_Deploy, ent);
hev_set_hev_weapon_model(id);
}
public hev_zp_user_infected_post(id)
{
if(hev_g_bHasHEV[id])
{
client_cmd(id, "spk fvox/hevSuit_get_infected_alert2");
hev_zp_remove_hev(id);
hev_g_bIsHEVZombie[id] = true;
if (is_user_connected(id))
{
VxCsSetModel(id, hev_HEV_ZOMBIE_SHORT);
if(get_user_weapon(id) == CSW_KNIFE) set_pev(id, pev_viewmodel2, hev_V_HEV_ZOMBIE_KNIFE);
}
}
else hev_zp_remove_hev(id);
}
public hev_zp_user_humanized_post(id)
{
if (hev_g_bIsHEVZombie[id])
{
cs_reset_user_model(id);
hev_g_bIsHEVZombie[id] = false;
}
}
public hev_fw_TakeDamage(victim, hev_inflictor, attacker, Float:damage, hev_damageBits)
{
if(!is_user_alive(victim) || !hev_g_bHasHEV[victim] || hev_zp_get_user_zombie(victim))
return HAM_IGNORED;
new Float:hev_reduction = float(get_pcvar_num(hev_g_cvDamageReduction)) / 100.0;
damage = damage * (1.0 - hev_reduction);
new Float:armor = float(get_user_armor(victim));
if (armor > 0.0)
{
new Float:hev_armor_damage = damage * 0.5;
new Float:hev_health_damage = damage - hev_armor_damage;
if (hev_armor_damage > armor)
{
hev_health_damage = damage - armor;
hev_armor_damage = armor;
}
set_user_armor(victim, floatround(armor - hev_armor_damage));
damage = hev_health_damage;
}
SetHamParamFloat(4, damage);
if(!hev_g_bMorphineUsed[victim] && (float(get_user_health(victim)) - damage <= float(hev_BOOST_THRES)))
{
hev_g_bMorphineUsed[victim] = true;
set_user_health(victim, hev_BOOST_VALUE);
client_cmd(victim, "spk fvox/morphine_shot");
hev_ScreenFade(victim, {0, 0, 255}, 0.5, 0.3);
return HAM_SUPERCEDE;
}
if(!hev_g_bArmorBoostUsed[victim] && (get_user_armor(victim) <= hev_BOOST_THRES))
{
hev_g_bArmorBoostUsed[victim] = true;
cs_set_user_armor(victim, hev_BOOST_VALUE, CS_ARMOR_VESTHELM);
client_cmd(victim, "spk fvox/power_restored");
hev_ScreenFade(victim, {255, 255, 0}, 0.5, 0.3);
}
return HAM_HANDLED;
}
public hev_fw_PlayerPreThink(id)
{
if(!is_user_alive(id) || !hev_g_bHasHEV[id] || !get_pcvar_num(hev_g_cvLongJump) || hev_zp_get_user_zombie(id) || vx45_corejetpack(id))
return FMRES_IGNORED;
static hev_button, hev_oldbutton, flags;
hev_button = pev(id, pev_button);
hev_oldbutton = pev(id, pev_oldbuttons);
flags = pev(id, pev_flags);
if((hev_button & IN_JUMP) && !(hev_oldbutton & IN_JUMP) && (hev_button & IN_DUCK) && (flags & FL_ONGROUND))
{
if(hev_g_iSuitPower[id] >= hev_JUMP_COST)
{
hev_g_iSuitPower[id] -= hev_JUMP_COST;
static Float:hev_vel[3];
velocity_by_aim(id, 500, hev_vel);
hev_vel[2] = 250.0;
set_pev(id, pev_velocity, hev_vel);
client_cmd(id, "spk player/pl_long_jump_1");
}
}
return FMRES_IGNORED;
}
public hev_fw_EmitSound(id, channel, const sample[], Float:volume, Float:hev_attn, flags, pitch)
{
if (!is_user_connected(id) || !hev_g_bHasHEV[id] || hev_zp_get_user_zombie(id) || vx45_corejetpack(id))
return FMRES_IGNORED;
if (containi(sample, "weapons/knife_") == 0)
{
if (equal(sample, "weapons/knife_deploy1.wav"))
{
emit_sound(id, channel, hev_SND_WRENCH_DEPLOY, volume, hev_attn, flags, pitch);
return FMRES_SUPERCEDE;
}
if (containi(sample, "hit") != -1 && containi(sample, "wall") == -1)
{
emit_sound(id, channel, hev_SND_WRENCH_HIT, volume, hev_attn, flags, pitch);
return FMRES_SUPERCEDE;
}
if (containi(sample, "hitwall") != -1)
{
emit_sound(id, channel, hev_SND_WRENCH_HITWALL, volume, hev_attn, flags, pitch);
return FMRES_SUPERCEDE;
}
if (containi(sample, "slash") != -1)
{
emit_sound(id, channel, hev_SND_WRENCH_SLASH, volume, hev_attn, flags, pitch);
return FMRES_SUPERCEDE;
}
if (equal(sample, "weapons/knife_stab.wav"))
{
emit_sound(id, channel, hev_SND_WRENCH_STAB, volume, hev_attn, flags, pitch);
return FMRES_SUPERCEDE;
}
}
return FMRES_IGNORED;
}
public hev_event_NewRound() { for (new i = 1; i <= hev_g_maxPlayers; i++) { hev_zp_remove_hev(i); hev_g_bBoughtThisRound[i] = false; } }
public hev_fw_PlayerSpawn_Post(id) { hev_zp_remove_hev(id); }
public hev_fw_PlayerKilled(victim) { if(hev_g_bHasHEV[victim]) client_cmd(victim, "spk fvox/flatline"); hev_zp_remove_hev(victim); }
public hev_client_disconnect(id) { hev_zp_remove_hev(id); hev_g_bBoughtThisRound[id] = false; }
stock hev_zp_remove_hev(id)
{
if(!hev_g_bHasHEV[id]) return;
hev_g_bHasHEV[id] = false;
hev_g_bCriticalPlayed[id] = false;
if (is_user_connected(id)) { cs_reset_user_model(id); vx45_corerestore(id); }
hev_fm_remove_model_ent(id);
remove_task( (id) + ZC_TOFF_HEV);
}
stock hev_restore_default_weapon__855(id)
{
if (!is_user_alive(id)) return;
new hev_iWpn = get_user_weapon(id);
new szModel[64];
switch(hev_iWpn)
{
case CSW_AK47: formatex(szModel, charsmax(szModel), "models/vexmira_ze/skins/vexmira_v_ak47.mdl");
case CSW_KNIFE: formatex(szModel, charsmax(szModel), "models/v_knife.mdl");
default: return;
}
set_pev(id, pev_viewmodel2, szModel);
}
stock hev_fm_remove_model_ent(id) { if (pev_valid(hev_g_ent_playermodel[id])) { engfunc(EngFunc_RemoveEntity, hev_g_ent_playermodel[id]); hev_g_ent_playermodel[id] = 0; } }
stock hev_ScreenFade(id, color[3], Float:duration, Float:hev_hold)
{
message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id);
write_short(floatround(duration * (1<<12)));
write_short(floatround(hev_hold * (1<<12)));
write_short(0x0000);
write_byte(color[0]); write_byte(color[1]); write_byte(color[2]); write_byte(100);
message_end();
}
stock hev_util_play_weapon_animation(const hev_Player, const hev_Sequence)
{
set_pev(hev_Player, pev_weaponanim, hev_Sequence)
message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = hev_Player)
write_byte(hev_Sequence); write_byte(pev(hev_Player, pev_body));
message_end()
}
ZcHevRoundLocked(id) { return hev_g_bBoughtThisRound[id] ? 1 : 0; }
public hev_vex_has(id) { return hev_g_bHasHEV[id]; }
public hev_vex_give(id) { if (!is_user_alive(id) || vx45_corezombie(id) || hev_g_bHasHEV[id] || hev_g_bBoughtThisRound[id]) return 0; hev_ActivateHEV(id); return 1; }
public hev_vex_remove(id) { hev_zp_remove_hev(id); return 1; }
new Float:jet_fFuelClock[33], Float:jet_fFuelRemainder[33];
new Float:jet_fEngineAt47[33], Float:jet_fHudAt47[33];
#define jet_SoundFire "vexmira/community/jetpack/rocket.wav"
#define jet_SoundTravel "vexmira/community/jetpack/travel.wav"
#define jet_SoundFly "vexmira/community/jetpack/fly47.wav"
#define jet_SoundBlow "vexmira/community/jetpack/blow.wav"
#define jet_SoundPickup "vexmira/meme/discord.wav"
#define jet_ModelRocket "models/vexmira/community/jetpack/rpgrocket.mdl"
#define jet_ModelJetpack_P "models/vexmira/community/jetpack/p_jetpack.mdl"
#define jet_ModelJetpack_W "models/vexmira/community/jetpack/w_jetpack.mdl"
#define jet_ModelJetpack_V "models/vexmira/community/jetpack/v_jetpack.mdl"
#define jet_ClassJetpack "gg_jetpack"
#define jet_ClassJetpack_P "gg_jetpack_p"
#define jet_ClassRocket "gg_bazooka"
#define jet_ItemName "Jetpack+Bazooka"
#define jet_ItemCost 2500
#define jet_RocketSpeed 3000
#define jet_RocketRadius 200.0
#define jet_RocketDamage 300.0
#define jet_JpFwdSpeed 400
#define jet_JpUpVelocity 200.0
#define jet_MaxGas 3000
#define jet_IconGreenGas 299
#define jet_IconYellowGas 200
#define jet_IconRedGas 100
#define jet_FlameAndSoundRate 6
#define jet_ALLOW_DROP_JETPACK
new jet_iGas[33], Float:jet_fLastShot[33], bool:jet_bHasJetpack[33], jet_SprTrail, jet_SprExplode, jet_SprRing, jet_SprFlame, jet_iMsgScreenShake
#if defined jet_MAKE_DEATH_EFFECT
new bool:jet_bKilledByRocket[33]
#endif
#if defined jet_MAKE_STATUS_ICON
new jet_iMsgStatusIcon
#endif
const jet_PDATA_SAFE = 2
const jet_OFFSET_WEAPONOWNER = 41
const jet_OFFSET_LINUX_WEAPONS = 4
public jet_plugin_precache()
{
if (!VexAssetGuard("vx42_jetpack")) return;
jet_SprTrail = ZcPcModel("sprites/vexmira/epic/jet_smoke.spr")
jet_SprExplode = ZcPcModel("sprites/vexmira/epic/jet_blast47.spr")
jet_SprRing = ZcPcModel("sprites/vexmira/epic/jet_ring.spr")
jet_SprFlame = ZcPcModel("sprites/vexmira/epic/jet_flame.spr")
ZcPcModel(jet_ModelRocket)
ZcPcModel(jet_ModelJetpack_P)
ZcPcModel(jet_ModelJetpack_W)
ZcPcModel(jet_ModelJetpack_V)
ZcPcSound(jet_SoundFire)
ZcPcSound(jet_SoundTravel)
// 5.1 flight sound intentionally disabled
ZcPcSound(jet_SoundBlow)
ZcPcSound(jet_SoundPickup)
}
public jet_plugin_init()
{
register_event("HLTV", "jet_OnNewRound", "a", "1=0", "2=0")
VxRegisterHam524(Ham_Killed, "player", "jet_OnKilled")
VxRegisterHam524(Ham_Item_Deploy, "weapon_knife", "jet_OnDeployKnifePost", 1)
register_touch(jet_ClassJetpack, "player", "jet_OnTouchJetPack")
register_touch(jet_ClassRocket, "*", "jet_OnTouchRocket")
register_forward(FM_ClientDisconnect, "jet_OnClientDisconnect")
g_zcFm[ZCFM_CmdStart] |= (1<<11)
jet_iMsgScreenShake = get_user_msgid("ScreenShake")
#if defined jet_MAKE_STATUS_ICON
jet_iMsgStatusIcon = get_user_msgid("StatusIcon")
#endif
#if defined jet_ALLOW_DROP_JETPACK
register_clcmd("drop_jp", "jet_CmdDropJetPack")
register_clcmd("drop", "jet_CommunityDrop")
#endif
}
#if defined jet_ALLOW_DROP_JETPACK
public jet_CmdDropJetPack(id)
{
if(!is_user_alive(id) || !jet_bHasJetpack[id]) return PLUGIN_HANDLED;
jet_CreateWorldJetPack(id)
jet_RemovePlayerJetPack(id)
jet_bHasJetpack[id] = false
#if defined jet_MAKE_STATUS_ICON
jet_DrawColoredIcon(id)
#endif
vx45_corerestore(id);
return PLUGIN_HANDLED;
}
#endif
public jet_CmdBuyJetPack(id)
{
if(!is_user_alive(id)) return PLUGIN_HANDLED;
if(jet_bHasJetpack[id])
{
client_print(id, print_chat, "[JETPACK] You already have this item.")
return PLUGIN_HANDLED;
}
new money = cs_get_user_money(id)
if(money < jet_ItemCost)
{
client_print(id, print_chat, "[JETPACK] Not enough CASH to purchase this item.")
return PLUGIN_HANDLED;
}
jet_CreateJetPack(id, 1)
client_print(id, print_chat, "[JETPACK] Jetpack satın aldın. Uçmak için '4Ctrl+Space' tuşlarına bas.")
client_print(id, print_chat, "[JETPACK] Roket atmak için farenin '4Sağ Tuşuna' bas.")
emit_sound(id, CHAN_STATIC, jet_SoundPickup, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
cs_set_user_money(id, money-jet_ItemCost)
return PLUGIN_CONTINUE;
}
public jet_OnNewRound()
{
remove_entity_name(jet_ClassJetpack)
remove_entity_name(jet_ClassRocket)
for(new id=1;id<=32;id++) { jet_RemovePlayerJetPack(id); jet_ResetPlayerData(id); }
}
public jet_client_putinserver(id)
{
jet_ResetPlayerData(id)
}
public jet_OnClientDisconnect(id)
{
if(jet_bHasJetpack[id])
{
jet_RemovePlayerJetPack(id)
jet_ResetPlayerData(id)
}
}
public jet_OnKilled(id, jet_atk, jet_gibs)
{
if(jet_bHasJetpack[id])
{
jet_CreateWorldJetPack(id)
jet_ResetPlayerData(id)
jet_RemovePlayerJetPack(id)
#if defined jet_MAKE_STATUS_ICON
jet_DrawColoredIcon(id)
#endif
}
#if defined jet_MAKE_DEATH_EFFECT
if(jet_bKilledByRocket[id])
{
SetHamParamInteger(3, 2)
new Float:jet_fOrigin[3]; pev(id, pev_origin, jet_fOrigin);
engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, jet_fOrigin, 0)
write_byte(TE_LAVASPLASH)
engfunc(EngFunc_WriteCoord, jet_fOrigin[0])
engfunc(EngFunc_WriteCoord, jet_fOrigin[1])
engfunc(EngFunc_WriteCoord, jet_fOrigin[2])
message_end()
jet_bKilledByRocket[id] = false
}
#endif
}
public jet_OnCmdStart(id, uc_handle, jet_random_seed)
{
if(!is_user_alive(id) || vx45_corezombie(id) || !jet_bHasJetpack[id]) return;
new Float:now = get_gametime();
// 5.3.1: the jetpack flies with ANY weapon in hand (CTRL+SPACE); the rocket (right click) stays on the jetpack slot
new bool:jet_inHand531 = (get_user_weapon(id) == CSW_KNIFE);
new Float:jet_dt = floatclamp(now - jet_fFuelClock[id], 0.0, 0.1);
jet_fFuelClock[id] = now;
static jet_button; jet_button = get_uc(uc_handle, UC_Buttons);
if((jet_iGas[id] > 0) && (jet_button & IN_DUCK) && (jet_button & IN_JUMP))
{
static Float:jet_Velocity[3]
velocity_by_aim(id, jet_JpFwdSpeed, jet_Velocity)
jet_Velocity[2] = jet_JpUpVelocity
entity_set_vector(id, EV_VEC_velocity, jet_Velocity)
jet_fFuelRemainder[id] += jet_dt * 250.0;
new use = floatround(jet_fFuelRemainder[id], floatround_floor);
jet_fFuelRemainder[id] -= float(use);
jet_iGas[id] = max(0, jet_iGas[id] - use);
if(random(jet_FlameAndSoundRate) == 2)
{
if (now >= jet_fEngineAt47[id])
{
jet_fEngineAt47[id] = now + 0.65;
// 5.1 silent jet propulsion; rocket sounds remain.
}
static Float:Origin[3]
entity_get_vector(id, EV_VEC_origin, Origin)
engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
write_byte(TE_SPRITE)
engfunc(EngFunc_WriteCoord, Origin[0])
engfunc(EngFunc_WriteCoord, Origin[1])
engfunc(EngFunc_WriteCoord, Origin[2])
write_short(jet_SprFlame)
write_byte(8)
write_byte(200)
message_end()
}
}
if(jet_inHand531 && (jet_button & IN_ATTACK2))
{
static Float:jet_ctime; jet_ctime = get_gametime();
if(jet_fLastShot[id] < jet_ctime)
{
jet_fLastShot[id] = jet_ctime+10.0
jet_CmdRocket(id)
}
}
else if(jet_button & IN_USE)
{
static Float:jet_fVelocity[3]; entity_get_vector(id, EV_VEC_velocity, jet_fVelocity);
if(jet_fVelocity[2] < 0.0)
{
jet_fVelocity[2] = -60.0
entity_set_vector(id, EV_VEC_velocity, jet_fVelocity)
}
}
else if((jet_iGas[id] < jet_MaxGas) && !(jet_button & IN_DUCK) && !(jet_button & IN_JUMP))
{
jet_fFuelRemainder[id] += jet_dt * 125.0;
new jet_gain = floatround(jet_fFuelRemainder[id], floatround_floor);
jet_fFuelRemainder[id] -= float(jet_gain);
jet_iGas[id] = min(jet_MaxGas, jet_iGas[id] + jet_gain);
}
JetGaugeUpdate48(id,now);
#if defined jet_MAKE_STATUS_ICON
if(jet_iGas[id] == jet_IconGreenGas) jet_DrawColoredIcon(id, 1, 0, 255, 0);
else if(jet_iGas[id] == jet_IconYellowGas) jet_DrawColoredIcon(id, 1, 255, 255, 0);
else if(jet_iGas[id] == jet_IconRedGas) jet_DrawColoredIcon(id, 1, 255, 0, 0);
#endif
}
#if defined jet_MAKE_STATUS_ICON
jet_DrawColoredIcon(id, mode=0, r=0, g=0, b=0)
{
if(!mode)
{
message_begin(MSG_ONE, jet_iMsgStatusIcon, _, id)
write_byte(0)
write_string("item_longjump")
message_end()
}
else
{
message_begin(MSG_ONE, jet_iMsgStatusIcon, _, id)
write_byte(1)
write_string("item_longjump")
write_byte(r)
write_byte(g)
write_byte(b)
message_end()
}
}
#endif
public jet_OnDeployKnifePost(ent)
{
if(pev_valid(ent) == jet_PDATA_SAFE)
{
new id = get_pdata_cbase(ent, jet_OFFSET_WEAPONOWNER, jet_OFFSET_LINUX_WEAPONS)
if(pev_valid(id) && jet_bHasJetpack[id]) set_pev(id, pev_viewmodel2, jet_ModelJetpack_V);
}
}
public jet_OnTouchJetPack(ent, id)
{
if(is_valid_ent(ent) && is_user_connected(id))
{
if(!is_user_alive(id) || vx45_corezombie(id) || jet_bHasJetpack[id]) return PLUGIN_HANDLED;
new fuel = entity_get_int(ent, EV_INT_iuser4);
new Float:ready47 = entity_get_float(ent, EV_FL_fuser3);
entity_set_int(ent, EV_INT_solid, SOLID_NOT)
remove_entity(ent)
vx45_corepreparejet(id);
jet_CreateJetPack(id, 0)
jet_iGas[id] = clamp(fuel, 0, jet_MaxGas);
jet_fLastShot[id] = ready47;
engclient_cmd(id, "weapon_knife");
set_pev(id, pev_viewmodel2, jet_ModelJetpack_V);
client_print(id, print_chat, "[VEXMIRA] Jetpack: bicagi sec, CTRL + SPACE ile uc.")
client_print(id, print_chat, "[VEXMIRA] Sag tik: alan hasarli fuze. Yeniden dolum: 10 saniye.")
emit_sound(id, CHAN_STATIC, jet_SoundPickup, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
return PLUGIN_CONTINUE;
}
public jet_OnTouchRocket(ent, id)
{
if(!is_valid_ent(ent)) return;
entity_set_int(ent, EV_INT_solid, SOLID_NOT)
emit_sound(ent, CHAN_VOICE, jet_SoundTravel, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
new Float:jet_atkOrigin[3]
entity_get_vector(ent, EV_VEC_origin, jet_atkOrigin)
engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, jet_atkOrigin, 0)
write_byte(TE_EXPLOSION)
engfunc(EngFunc_WriteCoord, jet_atkOrigin[0])
engfunc(EngFunc_WriteCoord, jet_atkOrigin[1])
engfunc(EngFunc_WriteCoord, jet_atkOrigin[2])
write_short(jet_SprExplode)
write_byte(24)
write_byte(18)
write_byte(TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NODLIGHTS)
message_end()
engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, jet_atkOrigin, 0)
write_byte(TE_BEAMCYLINDER)
engfunc(EngFunc_WriteCoord, jet_atkOrigin[0])
engfunc(EngFunc_WriteCoord, jet_atkOrigin[1])
engfunc(EngFunc_WriteCoord, jet_atkOrigin[2])
engfunc(EngFunc_WriteCoord, jet_atkOrigin[0])
engfunc(EngFunc_WriteCoord, jet_atkOrigin[1])
engfunc(EngFunc_WriteCoord, jet_atkOrigin[2]+500.0)
write_short(jet_SprRing)
write_byte(0)
write_byte(0)
write_byte(5)
write_byte(30)
write_byte(0)
write_byte(224)
write_byte(224)
write_byte(224)
write_byte(255)
write_byte(0)
message_end()
new attacker = entity_get_edict(ent, EV_ENT_owner)
if(attacker < 1 || attacker > 32 || !is_user_alive(attacker) || vx45_corezombie(attacker) || entity_get_int(ent, EV_INT_iuser3) != get_user_userid(attacker))
{
remove_entity(ent)
return;
}
new victim = -1
while((victim = engfunc(EngFunc_FindEntityInSphere, victim, jet_atkOrigin, jet_RocketRadius)) != 0)
{
if(victim < 1 || victim > 32 || !is_user_alive(victim) || !vx45_corezombie(victim)) continue;
if(cs_get_user_team(attacker) == cs_get_user_team(victim)) continue;
new Float:jet_fOrigin[3], Float:jet_fDistance, Float:jet_fDamage
pev(victim, pev_origin, jet_fOrigin)
new tr47 = create_tr2();
engfunc(EngFunc_TraceLine, jet_atkOrigin, jet_fOrigin, IGNORE_MONSTERS, ent, tr47);
new Float:clear47; get_tr2(tr47, TR_flFraction, clear47); free_tr2(tr47);
if (clear47 < 0.98) continue;
jet_fDistance = get_distance_f(jet_fOrigin, jet_atkOrigin)
jet_fDamage = jet_RocketDamage - floatmul(jet_RocketDamage, floatdiv(jet_fDistance, jet_RocketRadius))
jet_fDamage *= 1.0
if(jet_fDamage < 1.0) continue;
message_begin(MSG_ONE_UNRELIABLE, jet_iMsgScreenShake, _, victim)
write_short((1<<12)*2)
write_short((1<<12)*1)
write_short((1<<12)*8)
message_end()
#if !defined jet_DISABLE_ALL_KNOCKBACK
xs_vec_sub(jet_fOrigin, jet_atkOrigin, jet_fOrigin)
xs_vec_mul_scalar(jet_fOrigin, jet_fDamage * 0.7, jet_fOrigin)
if(xs_vec_len(jet_fOrigin) > 0.01) xs_vec_mul_scalar(jet_fOrigin, jet_RocketDamage / xs_vec_len(jet_fOrigin), jet_fOrigin)
set_pev(victim, pev_velocity, jet_fOrigin)
#endif
#if defined jet_MAKE_DEATH_EFFECT
new Float:jet_fHealth; pev(victim, pev_health, jet_fHealth);
jet_fHealth = jet_fHealth - jet_fDamage
if(jet_fHealth <= 0.0)
{
jet_bKilledByRocket[victim] = true
}
#endif
ExecuteHamB(Ham_TakeDamage, victim, ent, attacker, jet_fDamage, DMG_BLAST)
}
remove_entity(ent)
}
jet_CreateJetPack(id, jet_fullgas)
{
new ent = GearCreate51("info_target")
if(!is_valid_ent(ent)) return;
jet_bHasJetpack[id] = true
if(jet_fullgas) jet_iGas[id] = jet_MaxGas;
new Float:Origin[3]
entity_get_vector(id, EV_VEC_origin, Origin)
entity_set_string(ent, EV_SZ_classname, jet_ClassJetpack_P)
VxSM(ent, jet_ModelJetpack_P)
entity_set_origin(ent, Origin)
entity_set_int(ent, EV_INT_movetype, MOVETYPE_FOLLOW)
entity_set_edict(ent, EV_ENT_aiment, id)
entity_set_int(ent, EV_INT_solid, SOLID_NOT)
entity_set_size(ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0})
entity_set_edict(ent, EV_ENT_owner, id)
}
jet_CreateWorldJetPack(id)
{
new ent = GearCreate51("info_target")
if(!is_valid_ent(ent)) return;
new Float:jet_Aim[3], Float:Origin[3], jet_iColor[3]
velocity_by_aim(id, 32, jet_Aim)
entity_get_vector(id, EV_VEC_origin, Origin)
Origin[0] += 2*jet_Aim[0]
Origin[1] += 2*jet_Aim[1]
entity_set_string(ent, EV_SZ_classname, jet_ClassJetpack)
entity_set_int(ent, EV_INT_iuser4, jet_iGas[id]);
entity_set_float(ent, EV_FL_fuser3, jet_fLastShot[id]);
VxSM(ent, jet_ModelJetpack_W)
#if defined jet_MAKE_JETPACK_BOUNCING
entity_set_int(ent, EV_INT_movetype, MOVETYPE_BOUNCE)
#else
entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS)
#endif
entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER)
entity_set_size(ent, Float:{-8.0, -8.0, -8.0}, Float:{8.0, 8.0, 8.0})
entity_set_float(ent, EV_FL_gravity, 1.25)
entity_set_vector(ent, EV_VEC_origin, Origin)
velocity_by_aim(id, 400, jet_Aim)
entity_set_vector(ent, EV_VEC_velocity, jet_Aim)
jet_iColor[0] = random_num(16,255)
jet_iColor[1] = random(255)
jet_iColor[2] = random(255)
set_rendering(ent, kRenderFxGlowShell, jet_iColor[0], jet_iColor[1], jet_iColor[2], kRenderNormal, 0)
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_BEAMFOLLOW)
write_short(ent)
write_short(jet_SprTrail)
write_byte(10)
write_byte(5)
write_byte(jet_iColor[0])
write_byte(jet_iColor[1])
write_byte(jet_iColor[2])
write_byte(192)
message_end()
}
jet_CmdRocket(id)
{
new ent = GearCreate51("info_target")
if(!is_valid_ent(ent)) return;
new Float:origin[3], Float:velocity[3]
entity_get_vector(id, EV_VEC_origin, origin)
origin[2] += 16.0
entity_set_string(ent, EV_SZ_classname, jet_ClassRocket)
VxSM(ent, jet_ModelRocket)
entity_set_origin(ent, origin)
entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
entity_set_size(ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0})
entity_set_edict(ent, EV_ENT_owner, id)
entity_set_int(ent, EV_INT_iuser3, get_user_userid(id));
velocity_by_aim(id, jet_RocketSpeed, velocity)
entity_set_vector(ent, EV_VEC_velocity,    velocity)
vector_to_angle(velocity, origin)
entity_set_vector(ent, EV_VEC_angles, origin)
entity_set_int(ent, EV_INT_effects, EF_LIGHT)
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(TE_BEAMFOLLOW)
write_short(ent)
write_short(jet_SprTrail)
write_byte(30)
write_byte(5)
write_byte(224)
write_byte(224)
write_byte(224)
write_byte(192)
message_end()
emit_sound(id, CHAN_STATIC, jet_SoundFire, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
emit_sound(ent, CHAN_VOICE, jet_SoundTravel, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
jet_RemovePlayerJetPack(id)
{
new ent = -1
while((ent = find_ent_by_class(ent, jet_ClassJetpack_P)))
{
if(!is_valid_ent(ent)) continue;
if(entity_get_edict(ent, EV_ENT_owner) != id) continue;
remove_entity(ent)
}
}
jet_ResetPlayerData(id)
{
if(id>=1 && id<=32) vx47_jetgauge(id,-1,0);
jet_bHasJetpack[id] = false
jet_fLastShot[id] = 0.0
jet_iGas[id] = jet_MaxGas
jet_fFuelClock[id] = get_gametime(); jet_fFuelRemainder[id] = 0.0;
jet_fEngineAt47[id] = 0.0; jet_fHudAt47[id] = 0.0;
}
public jet_vex_has(id) { return jet_bHasJetpack[id]; }
public jet_vex_give(id) {
if (!is_user_alive(id) || vx45_corezombie(id) || jet_bHasJetpack[id]) return 0;
vx45_corepreparejet(id);
jet_CreateJetPack(id, 1); jet_fFuelClock[id] = get_gametime(); jet_fFuelRemainder[id] = 0.0;
if (!jet_bHasJetpack[id]) return 0;
engclient_cmd(id, "weapon_knife"); set_pev(id, pev_viewmodel2, jet_ModelJetpack_V);
return 1;
}
public jet_vex_remove(id) { jet_RemovePlayerJetPack(id); jet_ResetPlayerData(id); return 1; }
public jet_vex_infected(id) { if (jet_bHasJetpack[id]) jet_CreateWorldJetPack(id); jet_vex_remove(id); return 1; }
public jet_CommunityDrop(id) {
if (!jet_bHasJetpack[id] || get_user_weapon(id) != CSW_KNIFE) return PLUGIN_CONTINUE;
jet_CmdDropJetPack(id); vx45_corerestore(id); return PLUGIN_HANDLED;
}
#define mgn_HoldCBaseWeapon(%0)	(get_user_weapon(%0) == mgn_g_iWeaponID  && mgn_g_pWeaponA[ %0 ])
#define mgn_IsValidPrivateData(%0)	(pev_valid(%0) == 2)
#define mgn_VectorAdd(%1,%2,%3)      (%3[ 0 ] = %1[ 0 ] + %2[ 0 ], %3[ 1 ] = %1[ 1 ] + %2[ 1 ], %3[ 2 ] = %1[ 2 ] + %2[ 2 ])
new const mgn_WEAPON_SOUND_FIRE[] = "weapons/m134-1.wav"
new const mgn_WEAPON_SOUND_SPINDOWN[] = "weapons/m134_spindown.wav"
new const mgn_WEAPON_SOUND_SPINUP[] = "weapons/m134_spinup.wav"
new const mgn_SHELL_MODEL[] = "models/shellx.mdl"
new const mgn_SHELL2_MODEL[] = "models/shell2x.mdl"
new const mgn_WEAPON_LIST[] = "weapon_m134"
new const mgn_WEAPON_BASE_NAME[] = "weapon_m249"
const Float: mgn_RELOAD_TIME = 5.0
const mgn_AMMO_WEAPON = 200
const mgn_CLIP_WEAPON = 100
const Float:mgn_WEAPON_DAMAGE = 2.0
const Float:mgn_WEAPON_SPEED = 0.075
new const mgn_V_MODEL[] = "models/v_m134x.mdl"
new const mgn_P_MODEL[] = "models/p_m134x.mdl"
new const mgn_W_MODEL[] = "models/w_m134x.mdl"
new const mgn_HUD_SPRITES[][] =
{
"sprites/640hud26_2.spr",
"sprites/640hud35_2.spr"
}
new const mgn_TRACE_ATTACK[][] =
{
"func_breakable",
"func_wall",
"func_door",
"func_plat",
"func_rotating",
"worldspawn"
}
const mgn_OFFSET_WEAPONOWNER = 41
const mgn_OFFSET_LINUX = 5
const mgn_OFFSET_LINUX_WEAPONS = 4
const mgn_WEAP_KEY = 545464464
const mgn_m_flNextPrimaryAttack = 46
const mgn_m_iClip =	51
const mgn_m_flNextAttack = 83
const mgn_m_flTimeWeaponIdle = 48
const mgn_m_flStartThrow = 30
enum (<<=1)
{
mgn_DROP_PRIMARY = 1,
mgn_DROP_SECONDARY
}
enum (<<=1)
{
mgn_v_angle = 1,
mgn_punchangle,
mgn_angles
};
enum _:mgn_eDataShell
{
mgn_SHELL_1 ,
mgn_SHELL_2
}
new Float:mgn_g_Time[33], mgn_g_M134
const mgn_IDLE = 0
const mgn_RELOAD = 1
const mgn_DRAW = 2
const mgn_SHOOT_1 = 3
const mgn_SHOOT_END = 6
const mgn_SHOOT_START = 5
new const mgn_GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }
new mgn_g_pWeaponA[MAX_PLAYERS + 1], mgn_g_iWeaponID = 0, mgn_g_iShell[mgn_eDataShell], bool:mgn_g_iRun[MAX_PLAYERS + 1]
const mgn_WEAPONS_PRIMARY_BITSUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);
const mgn_WEAPONS_SECONDARY_BITSUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);
new bool:mgn_g_VexGiving[33];
public mgn_plugin_init()
{
g_zcFm[ZCFM_PlaybackEvent] |= (1<<12);
register_clcmd("drop","mgn_MinigunDrop");
g_zcFm[ZCFM_CmdStart] |= (1<<12)
g_zcFm[ZCFM_SetModel] |= (1<<12)
g_zcFm[ZCFM_UpdateClientData_P] |= (1<<12)
g_zcFm[ZCFM_PlayerPreThink] |= (1<<12)
VxRegisterHam524(Ham_Item_AddToPlayer, mgn_WEAPON_BASE_NAME, "mgn_fw_AddToPlayer_Post" , true);
VxRegisterHam524(Ham_Item_Deploy, mgn_WEAPON_BASE_NAME , "mgn_fw_Deploy_Post",  true);
VxRegisterHam524(Ham_Weapon_PrimaryAttack, mgn_WEAPON_BASE_NAME, "mgn_fw_PrimaryAttack_Pre" , false)
VxRegisterHam524(Ham_Item_PostFrame, mgn_WEAPON_BASE_NAME, "mgn_fw_PostFrame_Pre" , false);
VxRegisterHam524(Ham_Weapon_Reload, mgn_WEAPON_BASE_NAME, "mgn_fw_Reload_Pre" , false);
VxRegisterHam524(Ham_Weapon_WeaponIdle, mgn_WEAPON_BASE_NAME,  "mgn_fw_Idle_Pre",	false);
VxRegisterHam524(Ham_TraceAttack, "player", "mgn_fw_TraceAttack_Pre", false);
for(new i = 0 ; i < sizeof mgn_TRACE_ATTACK; i++)
VxRegisterHam524(Ham_TraceAttack, mgn_TRACE_ATTACK[i], "mgn_fw_TraceAttack_Post", 1)
mgn_g_iWeaponID = get_weaponid(mgn_WEAPON_BASE_NAME)
register_clcmd(mgn_WEAPON_LIST, "mgn_Weapon_Hook")
}
public mgn_plugin_precache()
{
if(!VexAssetGuard("vx42_minigun")) return;
ZcPcModel(mgn_V_MODEL)
ZcPcModel(mgn_P_MODEL)
ZcPcModel(mgn_W_MODEL)
mgn_PRECACHE_SOUNDS_FROM_MODEL(mgn_V_MODEL)
mgn_g_iShell[mgn_SHELL_1] = ZcPcModel(mgn_SHELL_MODEL)
mgn_g_iShell[mgn_SHELL_2] = ZcPcModel(mgn_SHELL2_MODEL)
ZcPcSound(mgn_WEAPON_SOUND_SPINDOWN)
ZcPcSound(mgn_WEAPON_SOUND_FIRE)
ZcPcSound(mgn_WEAPON_SOUND_SPINUP)
for(new mgn_iFile = 0 ; mgn_iFile < sizeof mgn_HUD_SPRITES; mgn_iFile++)
ZcPcGeneric(mgn_HUD_SPRITES[mgn_iFile])
static szFile [128]; formatex(szFile, charsmax(szFile) , "sprites/%s.txt" , mgn_WEAPON_LIST)
ZcPcGeneric(szFile)
}
public mgn_Get_What(id)
{
mgn_DropWeapons(id, mgn_DROP_PRIMARY)
mgn_g_pWeaponA[id]  = true
static mgn_Ent; mgn_Ent = fm_give_item(id , mgn_WEAPON_BASE_NAME)
if(mgn_Ent > 0) cs_set_weapon_ammo(mgn_Ent, mgn_CLIP_WEAPON)
cs_set_user_bpammo(id, mgn_g_iWeaponID, mgn_AMMO_WEAPON)
mgn_WeaponList(id, mgn_WEAPON_LIST, 3, mgn_AMMO_WEAPON, -1, -1, 0, 4, mgn_g_iWeaponID, 0)
}
public mgn_Weapon_Hook(id)
{
engclient_cmd(id, mgn_WEAPON_BASE_NAME)
return PLUGIN_HANDLED
}
public mgn_zeli_user_infected(id, mgn_ClassID) mgn_g_pWeaponA[id] = false
public mgn_zeli_user_spawned(id, mgn_ClassID) mgn_g_pWeaponA[id] = false
public mgn_client_disconnect(id) mgn_g_pWeaponA[id]  = false;
public mgn_zeli_weapon_selected(id, mgn_ItemID, mgn_ClassID)
{
if(mgn_ItemID == mgn_g_M134) mgn_Get_What(id)
}
public mgn_zeli_weapon_removed(id, mgn_ItemID)
{
if(mgn_ItemID == mgn_g_M134)  mgn_g_pWeaponA[id]  = false
}
public mgn_Forward_SetModel(mgn_Ent, const mgn_pModel[])
{
if(!pev_valid(mgn_Ent))
return FMRES_IGNORED
static szClassName[33]
pev(mgn_Ent, pev_classname, szClassName, charsmax(szClassName))
if(!equal(szClassName, "weaponbox"))
return FMRES_IGNORED;
static mgn_pOwner, mgn_pModel
mgn_pModel = fm_find_ent_by_owner(-1, mgn_WEAPON_BASE_NAME, mgn_Ent)
mgn_pOwner = pev(mgn_Ent, pev_owner)
if(mgn_pOwner>=1 && mgn_pOwner<=32 && mgn_g_pWeaponA[mgn_pOwner] && pev_valid(mgn_pModel))
{
set_pev(mgn_pModel, pev_impulse, mgn_WEAP_KEY)
VxSM(mgn_Ent, mgn_W_MODEL)
mgn_g_pWeaponA[mgn_pOwner] = false
return FMRES_SUPERCEDE
}
return FMRES_IGNORED
}
public mgn_Forward_UpdateClientData(id , mgn_SendWeapons, mgn_CD_Handle)
{
if (!mgn_HoldCBaseWeapon(id))
return HAM_IGNORED
static Float:mgn_fGametime; mgn_fGametime = get_gametime()
set_cd(mgn_CD_Handle, CD_flNextAttack, mgn_fGametime + 0.001)
return FMRES_HANDLED
}
public mgn_Forward_PlayBackEvent(flags, invoker, eventindex, Float:delay, Float:origin[3], Float:mgn_fvangles[3], Float:fparam1, Float:fparam2, mgn_iParam1, mgn_iParam2, mgn_bParam1, mgn_bParam2)
{
return invoker>=1 && invoker<=32 && mgn_HoldCBaseWeapon(invoker) ? FMRES_SUPERCEDE : FMRES_IGNORED
}
public mgn_Forward_PlayerPreThink(mgn_pId)
{
if(!is_user_alive(mgn_pId) || mgn_zp_get_user_zombie(mgn_pId) || !mgn_HoldCBaseWeapon(mgn_pId))
return FMRES_IGNORED
return FMRES_IGNORED
}
public mgn_fw_AddToPlayer_Post(mgn_Ent , id)
{
if(!pev_valid(mgn_Ent) || id<1 || id>32 || !is_user_connected(id))
return HAM_IGNORED
if(vx45_coresurvivor(id) && (pev(mgn_Ent, pev_impulse) == mgn_WEAP_KEY || mgn_g_VexGiving[id]))
{
mgn_g_pWeaponA[id] = true
mgn_WeaponList(id, mgn_WEAPON_LIST, 3 , mgn_AMMO_WEAPON , -1 , -1 , 0 , 4  , mgn_g_iWeaponID , 0)
return HAM_IGNORED  ;
} else {
mgn_g_pWeaponA[id]=false;
mgn_WeaponList(id, mgn_WEAPON_BASE_NAME , 3 , mgn_AMMO_WEAPON , -1 , -1 , 0 , 4  , mgn_g_iWeaponID , 0)
}
return HAM_IGNORED
}
public mgn_fw_Deploy_Post(mgn_Ent)
{
if(!mgn_IsValidPrivateData(mgn_Ent))
{
return HAM_IGNORED;
}
static mgn_pId ;
mgn_pId = get_pdata_cbase(mgn_Ent , mgn_OFFSET_WEAPONOWNER , mgn_OFFSET_LINUX_WEAPONS);
if (mgn_pId<1 || mgn_pId>32 || !mgn_g_pWeaponA[ mgn_pId ])
{
return HAM_IGNORED;
}
set_pev(mgn_pId, pev_viewmodel2, mgn_V_MODEL);
set_pev(mgn_pId, pev_weaponmodel2, mgn_P_MODEL);
set_pdata_float(mgn_pId, mgn_m_flNextAttack, 1.0, mgn_OFFSET_LINUX);
set_pdata_float(mgn_Ent, mgn_m_flTimeWeaponIdle, 1.0 , mgn_OFFSET_LINUX_WEAPONS);
set_pdata_float(mgn_Ent , mgn_m_flStartThrow , 0.0 , mgn_OFFSET_LINUX_WEAPONS);
mgn_SendWeaponAnim(mgn_pId, mgn_DRAW);
return HAM_IGNORED ;
}
public mgn_fw_CmdStart(id, uc_handle, seed)
{
if(!is_user_alive(id) || !mgn_HoldCBaseWeapon(id) || vx45_corezombie(id)) return FMRES_IGNORED;
static mgn_CurButton; mgn_CurButton = get_uc(uc_handle, UC_Buttons)
if((mgn_CurButton & IN_ATTACK))
return FMRES_IGNORED
if(!(mgn_CurButton & IN_ATTACK2))
return FMRES_IGNORED
if(get_gametime() - 0.05 <= mgn_g_Time[id])
return FMRES_IGNORED
mgn_g_Time[id] = get_gametime()
static mgn_Ent; mgn_Ent = fm_get_user_weapon_entity(id, CSW_M249)
if(!mgn_IsValidPrivateData(mgn_Ent))
return FMRES_IGNORED
static 	mgn_pId  ; mgn_pId = get_pdata_cbase(mgn_Ent , mgn_OFFSET_WEAPONOWNER , mgn_OFFSET_LINUX_WEAPONS);
static mgn_iClip ; mgn_iClip = get_pdata_int(mgn_Ent, mgn_m_iClip, mgn_OFFSET_LINUX_WEAPONS);
static Float:mgn_i_mSpinTime ;mgn_i_mSpinTime  = get_pdata_float(mgn_Ent ,mgn_m_flStartThrow , mgn_OFFSET_LINUX_WEAPONS);
if (!mgn_HoldCBaseWeapon(mgn_pId))
return FMRES_IGNORED
if(mgn_iClip <= 0)
{
if(mgn_i_mSpinTime)
{
emit_sound(mgn_pId , CHAN_WEAPON , mgn_WEAPON_SOUND_SPINDOWN , 1.0 , ATTN_NORM , 0 , PITCH_NORM) ;
mgn_SendWeaponAnim(mgn_pId , mgn_SHOOT_END);
set_pdata_float(mgn_Ent ,mgn_m_flStartThrow , 0.0 , mgn_OFFSET_LINUX_WEAPONS);
mgn_g_iRun[ mgn_pId ]	=	false ;
}
return FMRES_IGNORED
}
if(mgn_i_mSpinTime <= 0.0)
{
emit_sound(mgn_pId , CHAN_WEAPON , mgn_WEAPON_SOUND_SPINUP , 1.0 , ATTN_NORM , 0 , PITCH_NORM) ;
mgn_SendWeaponAnim(mgn_pId ,mgn_SHOOT_START);
mgn_i_mSpinTime += 0.1;
}
else if(mgn_i_mSpinTime <= 1.1)
{
mgn_i_mSpinTime += 0.1;
}
else if(mgn_i_mSpinTime > 1.1)
{
mgn_SendWeaponAnim(mgn_pId, 6);
emit_sound(mgn_pId , CHAN_WEAPON , mgn_WEAPON_SOUND_SPINUP , 1.0 , ATTN_NORM , 0 , PITCH_NORM) ;
mgn_g_iRun[ mgn_pId ]	=	true
}
set_pdata_float(mgn_Ent , mgn_m_flStartThrow , mgn_i_mSpinTime , mgn_OFFSET_LINUX_WEAPONS);
set_pdata_float(mgn_Ent, mgn_m_flNextPrimaryAttack , mgn_WEAPON_SPEED , mgn_OFFSET_LINUX_WEAPONS);
set_pdata_float(mgn_Ent, mgn_m_flTimeWeaponIdle, mgn_WEAPON_SPEED   , mgn_OFFSET_LINUX_WEAPONS);
return FMRES_IGNORED;
}
public mgn_fw_PrimaryAttack_Pre(mgn_Ent)
{
if(!mgn_IsValidPrivateData(mgn_Ent))
{
return HAM_IGNORED;
}
static 	mgn_pId  ; mgn_pId = get_pdata_cbase(mgn_Ent , mgn_OFFSET_WEAPONOWNER , mgn_OFFSET_LINUX_WEAPONS);
static mgn_iClip ; mgn_iClip = get_pdata_int(mgn_Ent, mgn_m_iClip, mgn_OFFSET_LINUX_WEAPONS);
static Float:mgn_i_mSpinTime ;mgn_i_mSpinTime  = get_pdata_float(mgn_Ent ,mgn_m_flStartThrow , mgn_OFFSET_LINUX_WEAPONS);
if (!mgn_HoldCBaseWeapon(mgn_pId))
{
return HAM_IGNORED;
}
if(mgn_iClip <= 0)
{
if(mgn_i_mSpinTime)
{
emit_sound(mgn_pId , CHAN_WEAPON , mgn_WEAPON_SOUND_SPINDOWN , 1.0 , ATTN_NORM , 0 , PITCH_NORM) ;
mgn_SendWeaponAnim(mgn_pId , mgn_SHOOT_END);
set_pdata_float(mgn_Ent ,mgn_m_flStartThrow , 0.0 , mgn_OFFSET_LINUX_WEAPONS);
mgn_g_iRun[ mgn_pId ]	=	false ;
}
return HAM_IGNORED;
}
if(mgn_i_mSpinTime <= 0.0)
{
emit_sound(mgn_pId , CHAN_WEAPON , mgn_WEAPON_SOUND_SPINUP , 1.0 , ATTN_NORM , 0 , PITCH_NORM) ;
mgn_SendWeaponAnim(mgn_pId ,mgn_SHOOT_START);
mgn_i_mSpinTime += 0.1;
}
else if(mgn_i_mSpinTime <= 1.1)
{
mgn_i_mSpinTime += 0.1;
}
else if(mgn_i_mSpinTime > 1.1)
{
ExecuteHam(Ham_Weapon_PrimaryAttack, mgn_Ent);
emit_sound(mgn_pId, CHAN_WEAPON, mgn_WEAPON_SOUND_FIRE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
mgn_SendWeaponAnim(mgn_pId, mgn_SHOOT_1);
mgn_EjectBrass(mgn_pId, mgn_g_iShell[ mgn_SHELL_1 ] , -9.0, 17.0, -3.0 , -10.0 , -50.0);
mgn_EjectBrass(mgn_pId, mgn_g_iShell[ mgn_SHELL_2 ] , -9.0, 17.0, 8.0 , 10.0 , 50.0);
mgn_UTIL_ScreenShake(mgn_pId, (1 << 12) * 1, (1 << 12) * 1, (1 << 12) * 1);
mgn_g_iRun[ mgn_pId ]	=	true ;
}
set_pdata_float(mgn_Ent , mgn_m_flStartThrow , mgn_i_mSpinTime , mgn_OFFSET_LINUX_WEAPONS);
set_pdata_float(mgn_Ent, mgn_m_flNextPrimaryAttack , mgn_WEAPON_SPEED , mgn_OFFSET_LINUX_WEAPONS);
set_pdata_float(mgn_Ent, mgn_m_flTimeWeaponIdle, mgn_WEAPON_SPEED   , mgn_OFFSET_LINUX_WEAPONS);
return HAM_SUPERCEDE ;
}
public mgn_fw_SecondaryAttack_Pre(mgn_Ent)
{
if(!mgn_IsValidPrivateData(mgn_Ent))
{
return HAM_IGNORED;
}
static 	mgn_pId  ; mgn_pId = get_pdata_cbase(mgn_Ent , mgn_OFFSET_WEAPONOWNER , mgn_OFFSET_LINUX_WEAPONS);
static mgn_iClip ; mgn_iClip = get_pdata_int(mgn_Ent, mgn_m_iClip, mgn_OFFSET_LINUX_WEAPONS);
static Float:mgn_i_mSpinTime ;mgn_i_mSpinTime  = get_pdata_float(mgn_Ent ,mgn_m_flStartThrow , mgn_OFFSET_LINUX_WEAPONS);
if (!mgn_HoldCBaseWeapon(mgn_pId))
{
return HAM_IGNORED;
}
if(mgn_iClip <= 0)
{
if(mgn_i_mSpinTime)
{
emit_sound(mgn_pId , CHAN_WEAPON , mgn_WEAPON_SOUND_SPINDOWN , 1.0 , ATTN_NORM , 0 , PITCH_NORM) ;
mgn_SendWeaponAnim(mgn_pId , mgn_SHOOT_END);
set_pdata_float(mgn_Ent ,mgn_m_flStartThrow , 0.0 , mgn_OFFSET_LINUX_WEAPONS);
mgn_g_iRun[ mgn_pId ]	=	false ;
}
return HAM_IGNORED;
}
if(mgn_i_mSpinTime <= 0.0)
{
emit_sound(mgn_pId , CHAN_WEAPON , mgn_WEAPON_SOUND_SPINUP , 1.0 , ATTN_NORM , 0 , PITCH_NORM) ;
mgn_SendWeaponAnim(mgn_pId ,mgn_SHOOT_START);
mgn_i_mSpinTime += 0.1;
}
else if(mgn_i_mSpinTime <= 1.1)
{
mgn_i_mSpinTime += 0.1;
}
else if(mgn_i_mSpinTime > 1.1)
{
ExecuteHam(Ham_Weapon_PrimaryAttack, mgn_Ent);
emit_sound(mgn_pId, CHAN_WEAPON, mgn_WEAPON_SOUND_FIRE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
mgn_SendWeaponAnim(mgn_pId, mgn_SHOOT_1);
mgn_EjectBrass(mgn_pId, mgn_g_iShell[ mgn_SHELL_1 ] , -9.0, 17.0, -3.0 , -10.0 , -50.0);
mgn_EjectBrass(mgn_pId, mgn_g_iShell[ mgn_SHELL_2 ] , -9.0, 17.0, 8.0 , 10.0 , 50.0);
mgn_UTIL_ScreenShake(mgn_pId, (1 << 12) * 1, (1 << 12) * 1, (1 << 12) * 1);
mgn_g_iRun[ mgn_pId ]	=	true ;
}
set_pdata_float(mgn_Ent , mgn_m_flStartThrow , mgn_i_mSpinTime , mgn_OFFSET_LINUX_WEAPONS);
set_pdata_float(mgn_Ent, mgn_m_flNextPrimaryAttack , mgn_WEAPON_SPEED , mgn_OFFSET_LINUX_WEAPONS);
set_pdata_float(mgn_Ent, mgn_m_flTimeWeaponIdle, mgn_WEAPON_SPEED   , mgn_OFFSET_LINUX_WEAPONS);
return HAM_SUPERCEDE ;
}
public mgn_fw_PostFrame_Pre(mgn_Ent)
{
if(!mgn_IsValidPrivateData(mgn_Ent))
{
return HAM_IGNORED;
}
static mgn_pId;
mgn_pId = get_pdata_cbase(mgn_Ent , mgn_OFFSET_WEAPONOWNER , mgn_OFFSET_LINUX_WEAPONS);
if (mgn_pId<1 || mgn_pId>32 || !is_user_connected(mgn_pId) || !mgn_HoldCBaseWeapon(mgn_pId))
{
return HAM_IGNORED;
}
if(vx45_coresurvivor(mgn_pId)) set_pdata_int(mgn_Ent,mgn_m_iClip,mgn_CLIP_WEAPON,mgn_OFFSET_LINUX_WEAPONS);
static mgn_fInReload ; mgn_fInReload = get_pdata_int(mgn_Ent, 54, mgn_OFFSET_LINUX_WEAPONS);
static Float:mgn_flNextAttack ; mgn_flNextAttack = get_pdata_float(mgn_pId, mgn_m_flNextAttack, mgn_OFFSET_LINUX);
static mgn_iClip ; mgn_iClip = get_pdata_int(mgn_Ent, mgn_m_iClip, mgn_OFFSET_LINUX_WEAPONS);
static mgn_iAmmoType ; mgn_iAmmoType = 376 + get_pdata_int(mgn_Ent, 49, mgn_OFFSET_LINUX_WEAPONS);
static mgn_iBpAmmo ; mgn_iBpAmmo  = get_pdata_int(mgn_pId, mgn_iAmmoType, mgn_OFFSET_LINUX);
if (mgn_fInReload && mgn_flNextAttack <= mgn_RELOAD_TIME)
{
static  j ; j = min(mgn_CLIP_WEAPON  - mgn_iClip, mgn_iBpAmmo);
set_pdata_int(mgn_Ent, mgn_m_iClip, mgn_iClip + j, mgn_OFFSET_LINUX_WEAPONS);
set_pdata_int(mgn_pId, mgn_iAmmoType, mgn_iBpAmmo-j, mgn_OFFSET_LINUX);
set_pdata_int(mgn_Ent, 54, 0, mgn_OFFSET_LINUX_WEAPONS);
}
return HAM_IGNORED;
}
public mgn_fw_Reload_Pre(mgn_Ent)
{
if(!mgn_IsValidPrivateData(mgn_Ent))
{
return HAM_IGNORED;
}
static mgn_pId;
mgn_pId = get_pdata_cbase(mgn_Ent , mgn_OFFSET_WEAPONOWNER , mgn_OFFSET_LINUX_WEAPONS);
if(mgn_pId<1 || mgn_pId>32 || !is_user_connected(mgn_pId) || !mgn_HoldCBaseWeapon(mgn_pId)) return HAM_IGNORED;
static mgn_iAmmoType ; mgn_iAmmoType = 376 + get_pdata_int(mgn_Ent, 49, mgn_OFFSET_LINUX_WEAPONS);
static mgn_iBpAmmo ; mgn_iBpAmmo = get_pdata_int(mgn_pId, mgn_iAmmoType, mgn_OFFSET_LINUX);
static mgn_iClip ; mgn_iClip = get_pdata_int(mgn_Ent, mgn_m_iClip, mgn_OFFSET_LINUX_WEAPONS);
if (mgn_iBpAmmo <= 0 || mgn_iClip >= mgn_CLIP_WEAPON)
{
return HAM_SUPERCEDE;
}
set_pdata_int(mgn_Ent, mgn_m_iClip, 0, mgn_OFFSET_LINUX_WEAPONS);
ExecuteHam(Ham_Weapon_Reload, mgn_Ent	);
set_pdata_int(mgn_Ent, mgn_m_iClip, mgn_iClip, mgn_OFFSET_LINUX_WEAPONS);
if (!is_user_connected(mgn_pId) || !mgn_HoldCBaseWeapon(mgn_pId))
{
return HAM_IGNORED;
}
set_pdata_float(mgn_pId, mgn_m_flNextAttack, mgn_RELOAD_TIME , mgn_OFFSET_LINUX);
set_pdata_float(mgn_Ent, mgn_m_flTimeWeaponIdle, mgn_RELOAD_TIME , mgn_OFFSET_LINUX_WEAPONS);
set_pdata_float(mgn_Ent , mgn_m_flStartThrow , 0.0 , mgn_OFFSET_LINUX_WEAPONS);
mgn_SendWeaponAnim(mgn_pId, mgn_RELOAD);
return HAM_SUPERCEDE;
}
public mgn_fw_Idle_Pre(mgn_Ent)
{
if(!mgn_IsValidPrivateData(mgn_Ent))
{
return HAM_IGNORED;
}
static mgn_pId;
mgn_pId = get_pdata_cbase(mgn_Ent , mgn_OFFSET_WEAPONOWNER , mgn_OFFSET_LINUX_WEAPONS);
if (get_pdata_float(mgn_Ent, mgn_m_flTimeWeaponIdle, mgn_OFFSET_LINUX_WEAPONS) > 0.0)
{
return HAM_IGNORED;
}
if (!mgn_HoldCBaseWeapon(mgn_pId))
{
return HAM_IGNORED;
}
if(get_pdata_float(mgn_Ent , mgn_m_flStartThrow, mgn_OFFSET_LINUX_WEAPONS))
{
emit_sound(mgn_pId , CHAN_WEAPON , mgn_WEAPON_SOUND_SPINDOWN , 1.0 , ATTN_NORM , 0 , PITCH_NORM) ;
mgn_SendWeaponAnim (mgn_pId, mgn_SHOOT_END);
set_pdata_float(mgn_Ent ,mgn_m_flStartThrow , 0.0 , mgn_OFFSET_LINUX_WEAPONS);
set_pdata_float(mgn_Ent, mgn_m_flTimeWeaponIdle, 0.6 , mgn_OFFSET_LINUX_WEAPONS);
set_pdata_float(mgn_pId , mgn_m_flNextAttack , 0.6 , mgn_OFFSET_LINUX) ;
mgn_g_iRun[ mgn_pId ]	=	false ;
return HAM_IGNORED ;
}
mgn_SendWeaponAnim (mgn_pId, mgn_IDLE);
set_pdata_float(mgn_Ent, mgn_m_flTimeWeaponIdle, random_float(5.0 , 10.0) , mgn_OFFSET_LINUX_WEAPONS);
return HAM_SUPERCEDE  ;
}
public mgn_fw_TraceAttack_Pre(iEntity,  mgn_iAttacker,  Float: mgn_flDamage)
{
if (is_user_connected(mgn_iAttacker) && mgn_HoldCBaseWeapon(mgn_iAttacker))
{
SetHamParamFloat(3 , mgn_flDamage * mgn_WEAPON_DAMAGE);
return HAM_IGNORED ;
}
return HAM_IGNORED;
}
public mgn_fw_TraceAttack_Post(mgn_Ent, mgn_iAttacker, Float:mgn_flDamage, Float:mgn_fDir[3], ptr, mgn_iDamageType)
{
if (!is_user_connected(mgn_iAttacker) || !mgn_HoldCBaseWeapon(mgn_iAttacker) || !mgn_iAttacker)
{
return HAM_HANDLED;
}
new mgn_iDecal = mgn_GUNSHOT_DECALS[ random_num(0 , sizeof(mgn_GUNSHOT_DECALS) - 1) ];
new Float:mgn_vecEnd[3];
get_tr2(ptr, TR_vecEndPos, mgn_vecEnd);
message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
write_byte(TE_GUNSHOTDECAL);
engfunc(EngFunc_WriteCoord, mgn_vecEnd[0]);
engfunc(EngFunc_WriteCoord, mgn_vecEnd[1]);
engfunc(EngFunc_WriteCoord, mgn_vecEnd[2] - 10.0);
write_short(mgn_Ent);
write_byte(mgn_iDecal);
message_end();
return HAM_IGNORED;
}
stock mgn_DropWeapons(id, mgn_bitsDropType)
{
static weapons[32], num, i, weaponid;
num = 0 ;
get_user_weapons(id, weapons, num);
for (i = 0; i < num; i++)
{
weaponid = weapons[i];
if ((mgn_bitsDropType == mgn_DROP_PRIMARY && ((1<<weaponid) & mgn_WEAPONS_PRIMARY_BITSUM)) || (mgn_bitsDropType == mgn_DROP_SECONDARY && ((1<<weaponid) & mgn_WEAPONS_SECONDARY_BITSUM)))
{
static wname[32];
get_weaponname(weaponid, wname, charsmax(wname));
engclient_cmd(id, "drop", wname);
}
}
}
stock mgn_SendWeaponAnim(const id, const mgn_Sequence)
{
set_pev(id, pev_weaponanim, mgn_Sequence);
message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id);
write_byte(mgn_Sequence);
write_byte(pev(id, pev_body));
message_end();
}
stock mgn_WeaponList(id, const mgn_szWeapon[ ], mgn_int, mgn_int2, int3, mgn_int4, mgn_int5, mgn_int6, mgn_int7, mgn_int8)
{
message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList") , _, id);
write_string(mgn_szWeapon);
write_byte(mgn_int);
write_byte(mgn_int2);
write_byte(int3);
write_byte(mgn_int4);
write_byte(mgn_int5);
write_byte(mgn_int6);
write_byte(mgn_int7);
write_byte(mgn_int8);
message_end();
}
mgn_PRECACHE_SOUNDS_FROM_MODEL(const mgn_szModelPath[])
{
new mgn_iFile;
if ((mgn_iFile = fopen(mgn_szModelPath, "rt")))
{
new mgn_szSoundPath[64];
new mgn_iNumSeq, mgn_iSeqIndex;
new mgn_iEvent, mgn_iNumEvents, mgn_iEventIndex;
fseek(mgn_iFile, 164, SEEK_SET);
fread(mgn_iFile, mgn_iNumSeq, BLOCK_INT);
fread(mgn_iFile, mgn_iSeqIndex, BLOCK_INT);
for (new mgn_k, i = 0; i < mgn_iNumSeq; i++)
{
fseek(mgn_iFile, mgn_iSeqIndex + 48 + 176 * i, SEEK_SET);
fread(mgn_iFile, mgn_iNumEvents, BLOCK_INT);
fread(mgn_iFile, mgn_iEventIndex, BLOCK_INT);
fseek(mgn_iFile, mgn_iEventIndex + 176 * i, SEEK_SET);
for (mgn_k = 0; mgn_k < mgn_iNumEvents; mgn_k++)
{
fseek(mgn_iFile, mgn_iEventIndex + 4 + 76 * mgn_k, SEEK_SET);
fread(mgn_iFile, mgn_iEvent, BLOCK_INT);
fseek(mgn_iFile, 4, SEEK_CUR);
if (mgn_iEvent != 5004)
{
continue;
}
fread_blocks(mgn_iFile, mgn_szSoundPath, 64, BLOCK_CHAR);
if (strlen(mgn_szSoundPath))
{
strtolower(mgn_szSoundPath);
VexPcSnd(mgn_szSoundPath, false);
}
}
}
}
fclose(mgn_iFile);
}
stock mgn_UTIL_ScreenShake(id, mgn_sAmplitude = 0, mgn_sDuration = 0, mgn_sFrequency = 0)
{
message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), .player = id);
write_short(mgn_sAmplitude);
write_short(mgn_sDuration);
write_short(mgn_sFrequency);
message_end();
}
public mgn_EjectBrass(mgn_Player, mgn_iShellModelIndex, Float:mgn_upScale, Float:mgn_fwScale, Float:mgn_rgScale , Float:mgn_rgKoord1 , Float:mgn_rgKoord2)
{
mgn_UTIL_MakeVectors(mgn_Player, mgn_v_angle + mgn_punchangle);
static Float:mgn_vVel[ 3 ], Float:mgn_vAngle[ 3 ], Float:mgn_vOrigin[ 3 ], Float:mgn_vViewOfs[ 3 ],
i, Float:mgn_vShellOrigin[ 3 ],  Float:mgn_vShellVelocity[ 3 ], Float:mgn_vRight[ 3 ],
Float:mgn_vUp[ 3 ], Float:mgn_vForward[ 3 ];
pev(mgn_Player, pev_velocity, mgn_vVel);
pev(mgn_Player, pev_view_ofs, mgn_vViewOfs);
pev(mgn_Player, pev_angles, mgn_vAngle);
pev(mgn_Player, pev_origin, mgn_vOrigin);
global_get(glb_v_right, mgn_vRight);
global_get(glb_v_up, mgn_vUp);
global_get(glb_v_forward, mgn_vForward);
for(i = 0; i < 3; i++)
{
mgn_vShellOrigin[ i ] = mgn_vOrigin[ i ] + mgn_vViewOfs[ i ] + mgn_vUp[ i ] * mgn_upScale + mgn_vForward[ i ] * mgn_fwScale + mgn_vRight[ i ] * mgn_rgScale;
mgn_vShellVelocity[ i ] = mgn_vVel[ i ] + mgn_vRight[ i ] * random_float(mgn_rgKoord1, mgn_rgKoord2) + mgn_vUp[ i ] * random_float(100.0, 150.0) + mgn_vForward[ i ] * 25.0;
}
engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, mgn_vShellOrigin, 0);
write_byte(TE_MODEL);
engfunc(EngFunc_WriteCoord, mgn_vShellOrigin[ 0 ]);
engfunc(EngFunc_WriteCoord, mgn_vShellOrigin[ 1 ]);
engfunc(EngFunc_WriteCoord, mgn_vShellOrigin[ 2 ]);
engfunc(EngFunc_WriteCoord, mgn_vShellVelocity[ 0 ]);
engfunc(EngFunc_WriteCoord,  mgn_vShellVelocity[ 1 ]);
engfunc(EngFunc_WriteCoord,  mgn_vShellVelocity[ 2 ]);
engfunc(EngFunc_WriteAngle, mgn_vAngle[ 1 ]);
write_short(mgn_iShellModelIndex);
write_byte(1);
write_byte(15);
message_end();
}
stock mgn_UTIL_MakeVectors(id, mgn_bitsAngleType)
{
static Float:mgn_vPunchAngle[ 3 ], Float:mgn_vAngle[ 3 ];
if(mgn_bitsAngleType & mgn_v_angle)
pev(id, pev_v_angle, mgn_vAngle);
if(mgn_bitsAngleType & mgn_punchangle)
pev(id, pev_punchangle, mgn_vPunchAngle);
mgn_VectorAdd(mgn_vAngle, mgn_vPunchAngle, mgn_vAngle);
engfunc(EngFunc_MakeVectors, mgn_vAngle);
}
public mgn_zp_get_user_zombie(id)
{
return vx45_corezombie(id)
}
public mgn_vex_give(id) {
if(!is_user_alive(id) || !vx45_coresurvivor(id)) return 0;
mgn_g_pWeaponA[id]=false;
mgn_g_VexGiving[id]=true; mgn_Get_What(id); mgn_g_VexGiving[id]=false;
return mgn_g_pWeaponA[id]?1:0;
}
public mgn_vex_has(id) { return id>=1 && id<=32 && mgn_g_pWeaponA[id]?1:0; }
public mgn_vex_remove(id) { if(id>=1 && id<=32) { mgn_g_pWeaponA[id]=false; mgn_g_iRun[id]=false; } return 1; }
public mgn_MinigunDrop(id) { return is_user_alive(id) && vx45_coresurvivor(id) && mgn_HoldCBaseWeapon(id)?PLUGIN_HANDLED:PLUGIN_CONTINUE; }
new const diag_ASSETS[][] = {
"models/arrow.mdl",
"models/hev_weapons/p_wrench.mdl",
"models/hev_weapons/v_ak47.mdl",
"models/hev_weapons/v_aug.mdl",
"models/hev_weapons/v_awp.mdl",
"models/hev_weapons/v_deagle.mdl",
"models/hev_weapons/v_famas.mdl",
"models/hev_weapons/v_g3sg1.mdl",
"models/hev_weapons/v_galil.mdl",
"models/hev_weapons/v_glock18.mdl",
"models/hev_weapons/v_m249.mdl",
"models/hev_weapons/v_m3.mdl",
"models/hev_weapons/v_m4a1.mdl",
"models/hev_weapons/v_mp5.mdl",
"models/hev_weapons/v_p228.mdl",
"models/hev_weapons/v_p90.mdl",
"models/hev_weapons/v_sg550.mdl",
"models/hev_weapons/v_tmp.mdl",
"models/hev_weapons/v_ump45.mdl",
"models/hev_weapons/v_usp.mdl",
"models/hev_weapons/v_wrench.mdl",
"models/hev_weapons/v_xm1014.mdl",
"models/p_bow.mdl",
"models/p_bow_empty.mdl",
"models/p_dragonsword.mdl",
"models/p_ethereal.mdl",
"models/p_fgrenade.mdl",
"models/p_horseaxe.mdl",
"models/p_janus7.mdl",
"models/p_katanad.mdl",
"models/p_m134x.mdl",
"models/p_plasmagun.mdl",
"models/p_salamander.mdl",
"models/p_sfsniper.mdl",
"models/p_sfsword_off.mdl",
"models/p_sfsword_on.mdl",
"models/player/cso_heavy/cso_heavy.mdl",
"models/player/deimos_zombi_host/deimos_zombi_host.mdl",
"models/player/heal_zombi_origin/heal_zombi_origin.mdl",
"models/player/hev_zombie/hev_zombie.mdl",
"models/player/l4d_tank/l4d_tank.mdl",
"models/player/nemesis/nemesis.mdl",
"models/player/nemesis/nemesisT.mdl",
"models/player/player_hev/player_hev.mdl",
"models/player/vex_batman47/vex_batman47.mdl",
"models/player/vex_boss048/vex_boss048.mdl",
"models/player/vex_boss148/vex_boss148.mdl",
"models/player/vex_boss248/vex_boss248.mdl",
"models/player/vex_boss348/vex_boss348.mdl",
"models/player/vex_boss448/vex_boss448.mdl",
"models/player/vex_boss548/vex_boss548.mdl",
"models/player/vex_boss648/vex_boss648.mdl",
"models/player/vex_boss748/vex_boss748.mdl",
"models/player/vex_boss848/vex_boss848.mdl",
"models/player/vex_gign/vex_gign.mdl",
"models/player/vex_gsg9/vex_gsg9.mdl",
"models/player/vex_halo/vex_halo.mdl",
"models/player/vex_halo/vex_haloT.mdl",
"models/player/vex_ironman47/vex_ironman47.mdl",
"models/player/vex_masterchief47/vex_masterchief47.mdl",
"models/player/vex_pyramid/vex_pyramid.mdl",
"models/player/vex_scary/vex_scary.mdl",
"models/player/vex_soldier/vex_soldier.mdl",
"models/player/vex_spetsnaz/vex_spetsnaz.mdl",
"models/player/vex_spiderman47/vex_spiderman47.mdl",
"models/player/vex_titan47/vex_titan47.mdl",
"models/player/vex_titan48/vex_titan48.mdl",
"models/player/vex_urban/vex_urban.mdl",
"models/player/vex_wolverine47/vex_wolverine47.mdl",
"models/player/zombie_source/zombie_source.mdl",
"models/player/zombie_witch2/zombie_witch2.mdl",
"models/shell2x.mdl",
"models/shellx.mdl",
"models/v_bow.mdl",
"models/v_dragonsword2.mdl",
"models/v_ethereal2.mdl",
"models/v_hev.mdl",
"models/v_hev_adrenaline_injector.mdl",
"models/v_hev_zombie.mdl",
"models/v_horseaxe.mdl",
"models/v_janus7.mdl",
"models/v_katanad.mdl",
"models/v_m134x.mdl",
"models/v_plasmagun2.mdl",
"models/v_salamander.mdl",
"models/v_sfsightB.mdl",
"models/v_sfsightR.mdl",
"models/v_sfsniperF.mdl",
"models/v_sfsword.mdl",
"models/vexmira/arena48/p_balrog.mdl",
"models/vexmira/arena48/p_janus.mdl",
"models/vexmira/arena48/p_skull.mdl",
"models/vexmira/arena48/p_thanatos.mdl",
"models/vexmira/arena48/v_balrog.mdl",
"models/vexmira/arena48/v_janus.mdl",
"models/vexmira/arena48/v_skull.mdl",
"models/vexmira/arena48/v_thanatos.mdl",
"models/vexmira/arena50/arsenal/0/p.mdl",
"models/vexmira/arena50/arsenal/0/v.mdl",
"models/vexmira/arena50/arsenal/0/w.mdl",
"models/vexmira/arena50/arsenal/1/p.mdl",
"models/vexmira/arena50/arsenal/1/v.mdl",
"models/vexmira/arena50/arsenal/1/w.mdl",
"models/vexmira/arena50/arsenal/2/p.mdl",
"models/vexmira/arena50/arsenal/2/v.mdl",
"models/vexmira/arena50/arsenal/2/w.mdl",
"models/vexmira/arena50/arsenal/3/p.mdl",
"models/vexmira/arena50/arsenal/3/v.mdl",
"models/vexmira/arena50/arsenal/3/w.mdl",
"models/vexmira/arena50/arsenal/4/p.mdl",
"models/vexmira/arena50/arsenal/4/v.mdl",
"models/vexmira/arena50/arsenal/4/w.mdl",
"models/vexmira/arena50/arsenal/5/p.mdl",
"models/vexmira/arena50/arsenal/5/v.mdl",
"models/vexmira/arena50/arsenal/5/w.mdl",
"models/vexmira/arena50/arsenal/6/p.mdl",
"models/vexmira/arena50/arsenal/6/v.mdl",
"models/vexmira/arena50/arsenal/6/w.mdl",
"models/vexmira/arena50/arsenal/7/v.mdl",
"models/vexmira/arena50/arsenal/7/w.mdl",
"models/vexmira/arena50/cosmetics/angel_wings48.mdl",
"models/vexmira/arena50/cosmetics/cat48.mdl",
"models/vexmira/arena50/cosmetics/cosmic_wings48.mdl",
"models/vexmira/arena50/cosmetics/devil_wings48.mdl",
"models/vexmira/arena50/cosmetics/doctor_hat48.mdl",
"models/vexmira/arena50/cosmetics/dragon_wings4748.mdl",
"models/vexmira/arena50/cosmetics/dragonfly48.mdl",
"models/vexmira/arena50/cosmetics/eagle_wings48.mdl",
"models/vexmira/arena50/cosmetics/earth_hat48.mdl",
"models/vexmira/arena50/cosmetics/frost_angel4748.mdl",
"models/vexmira/arena50/cosmetics/hat_armor4748.mdl",
"models/vexmira/arena50/cosmetics/hat_jester4748.mdl",
"models/vexmira/arena50/cosmetics/hat_sims4748.mdl",
"models/vexmira/arena50/cosmetics/headphones48.mdl",
"models/vexmira/arena50/cosmetics/mech_wings48.mdl",
"models/vexmira/arena50/cosmetics/pet_amongus4748.mdl",
"models/vexmira/arena50/cosmetics/pet_bat48.mdl",
"models/vexmira/arena50/cosmetics/pet_cat248.mdl",
"models/vexmira/arena50/cosmetics/pet_guardian48.mdl",
"models/vexmira/arena50/cosmetics/pet_headcrab4748.mdl",
"models/vexmira/arena50/cosmetics/pet_headcrab4748T.mdl",
"models/vexmira/arena50/cosmetics/pet_mummy48.mdl",
"models/vexmira/arena50/cosmetics/santa_hat48.mdl",
"models/vexmira/arena50/cosmetics/shoop_hat48.mdl",
"models/vexmira/arena50/cosmetics/solar_angel4748.mdl",
"models/vexmira_ze/skins/vexmira_v_ak47.mdl",
"models/vexmira_ze/skins/vexmira_v_aug.mdl",
"models/vexmira_ze/skins/vexmira_v_awp.mdl",
"models/vexmira/arena50/default/v_c4.mdl",
"models/vexmira_ze/skins/vexmira_v_deagle.mdl",
"models/vexmira_ze/skins/vexmira_v_elite.mdl",
"models/vexmira_ze/skins/vexmira_v_famas.mdl",
"models/vexmira_ze/skins/vexmira_v_fiveseven.mdl",
"models/vexmira/arena50/default/v_flashbang.mdl",
"models/vexmira_ze/skins/vexmira_v_g3sg1.mdl",
"models/vexmira/arena50/default/v_galil.mdl",
"models/vexmira_ze/skins/vexmira_v_glock18.mdl",
"models/vexmira/arena50/default/v_hegrenade.mdl",
"models/vexmira/arena50/default/v_knife.mdl",
"models/vexmira_ze/skins/vexmira_v_m249.mdl",
"models/vexmira_ze/skins/vexmira_v_m3.mdl",
"models/vexmira_ze/skins/vexmira_v_m4a1.mdl",
"models/vexmira_ze/skins/vexmira_v_mac10.mdl",
"models/vexmira_ze/skins/vexmira_v_mp5.mdl",
"models/vexmira_ze/skins/vexmira_v_p228.mdl",
"models/vexmira_ze/skins/vexmira_v_p90.mdl",
"models/vexmira_ze/skins/vexmira_v_scout.mdl",
"models/vexmira_ze/skins/vexmira_v_sg550.mdl",
"models/vexmira_ze/skins/vexmira_v_sg552.mdl",
"models/vexmira/arena50/default/v_smokegrenade.mdl",
"models/vexmira_ze/skins/vexmira_v_tmp.mdl",
"models/vexmira_ze/skins/vexmira_v_ump45.mdl",
"models/vexmira_ze/skins/vexmira_v_usp.mdl",
"models/vexmira_ze/skins/vexmira_v_xm1014.mdl",
"models/vexmira/arena51/arsenal/0/v.mdl",
"models/vexmira/arena51/arsenal/1/v.mdl",
"models/vexmira/arena51/arsenal/2/v.mdl",
"models/vexmira/arena51/arsenal/3/v.mdl",
"models/vexmira/arena51/arsenal/4/v.mdl",
"models/vexmira/arena51/arsenal/5/v.mdl",
"models/vexmira/arena51/arsenal/6/v.mdl",
"models/vexmira/arena51/arsenal/7/v.mdl",
"models/vexmira/arena51/default/v_ak47.mdl",
"models/vexmira/arena51/default/v_aug.mdl",
"models/vexmira/arena51/default/v_awp.mdl",
"models/vexmira/arena51/default/v_c4.mdl",
"models/vexmira/arena51/default/v_deagle.mdl",
"models/vexmira/arena51/default/v_elite.mdl",
"models/vexmira/arena51/default/v_famas.mdl",
"models/vexmira/arena51/default/v_fiveseven.mdl",
"models/vexmira/arena51/default/v_g3sg1.mdl",
"models/vexmira/arena51/default/v_galil.mdl",
"models/vexmira/arena51/default/v_glock18.mdl",
"models/vexmira/arena51/default/v_knife.mdl",
"models/vexmira/arena51/default/v_m249.mdl",
"models/vexmira/arena51/default/v_m3.mdl",
"models/vexmira/arena51/default/v_m4a1.mdl",
"models/vexmira/arena51/default/v_mac10.mdl",
"models/vexmira/arena51/default/v_mp5.mdl",
"models/vexmira/arena51/default/v_p228.mdl",
"models/vexmira/arena51/default/v_p90.mdl",
"models/vexmira/arena51/default/v_scout.mdl",
"models/vexmira/arena51/default/v_sg550.mdl",
"models/vexmira/arena51/default/v_sg552.mdl",
"models/vexmira/arena51/default/v_tmp.mdl",
"models/vexmira/arena51/default/v_ump45.mdl",
"models/vexmira/arena51/default/v_usp.mdl",
"models/vexmira/arena51/default/v_xm1014.mdl",
"models/vexmira/arena51/grenades/p_flashbang.mdl",
"models/vexmira/arena51/grenades/p_hegrenade.mdl",
"models/vexmira/arena51/grenades/p_smokegrenade.mdl",
"models/vexmira/arena51/grenades/v_flashbang.mdl",
"models/vexmira/arena51/grenades/v_hegrenade.mdl",
"models/vexmira/arena51/grenades/v_smokegrenade.mdl",
"models/vexmira/arena51/grenades/w_flashbang.mdl",
"models/vexmira/arena51/grenades/w_hegrenade.mdl",
"models/vexmira/arena51/grenades/w_smokegrenade.mdl",
"models/vexmira_ze/skins/vexmira_v_ak47.mdl",
"models/vexmira_ze/skins/vexmira_v_aug.mdl",
"models/vexmira_ze/skins/vexmira_v_awp.mdl",
"models/vexmira/arena52/default/v_c4.mdl",
"models/vexmira_ze/skins/vexmira_v_deagle.mdl",
"models/vexmira_ze/skins/vexmira_v_elite.mdl",
"models/vexmira_ze/skins/vexmira_v_famas.mdl",
"models/vexmira_ze/skins/vexmira_v_fiveseven.mdl",
"models/vexmira_ze/skins/vexmira_v_g3sg1.mdl",
"models/vexmira/arena52/default/v_galil.mdl",
"models/vexmira_ze/skins/vexmira_v_glock18.mdl",
"models/vexmira/arena52/default/v_knife.mdl",
"models/vexmira_ze/skins/vexmira_v_m249.mdl",
"models/vexmira_ze/skins/vexmira_v_m3.mdl",
"models/vexmira_ze/skins/vexmira_v_m4a1.mdl",
"models/vexmira_ze/skins/vexmira_v_mac10.mdl",
"models/vexmira_ze/skins/vexmira_v_mp5.mdl",
"models/vexmira_ze/skins/vexmira_v_p228.mdl",
"models/vexmira_ze/skins/vexmira_v_p90.mdl",
"models/vexmira_ze/skins/vexmira_v_scout.mdl",
"models/vexmira_ze/skins/vexmira_v_sg550.mdl",
"models/vexmira_ze/skins/vexmira_v_sg552.mdl",
"models/vexmira_ze/skins/vexmira_v_tmp.mdl",
"models/vexmira_ze/skins/vexmira_v_ump45.mdl",
"models/vexmira_ze/skins/vexmira_v_usp.mdl",
"models/vexmira_ze/skins/vexmira_v_xm1014.mdl",
"models/vexmira/arena52/grenades/v_flashbang.mdl",
"models/vexmira/arena52/grenades/v_hegrenade.mdl",
"models/vexmira/arena52/grenades/v_smokegrenade.mdl",
"models/vexmira/arena52/hats/doctor_hat48.mdl",
"models/vexmira/arena52/hats/earth_hat48.mdl",
"models/vexmira/arena52/hats/hat_armor4748.mdl",
"models/vexmira/arena52/hats/hat_jester4748.mdl",
"models/vexmira/arena52/hats/hat_sims4748.mdl",
"models/vexmira/arena52/hats/headphones48.mdl",
"models/vexmira/arena52/hats/santa_hat48.mdl",
"models/vexmira/arena52/hats/shoop_hat48.mdl",
"models/vexmira/community/claws/classic.mdl",
"models/vexmira/community/claws/heavy.mdl",
"models/vexmira/community/claws/scary.mdl",
"models/vexmira/community/cosmetics/angel_wings.mdl",
"models/vexmira/community/cosmetics/angel_wings48.mdl",
"models/vexmira/community/cosmetics/angel_wings48b49.mdl",
"models/vexmira/community/cosmetics/cat.mdl",
"models/vexmira/community/cosmetics/cat48.mdl",
"models/vexmira/community/cosmetics/cosmic_wings.mdl",
"models/vexmira/community/cosmetics/cosmic_wings48.mdl",
"models/vexmira/community/cosmetics/cosmic_wings48b49.mdl",
"models/vexmira/community/cosmetics/devil_wings.mdl",
"models/vexmira/community/cosmetics/devil_wings48.mdl",
"models/vexmira/community/cosmetics/devil_wings48b49.mdl",
"models/vexmira/community/cosmetics/doctor_hat.mdl",
"models/vexmira/community/cosmetics/doctor_hat48.mdl",
"models/vexmira/community/cosmetics/doctor_hat48b49.mdl",
"models/vexmira/community/cosmetics/dragon_wings47.mdl",
"models/vexmira/community/cosmetics/dragon_wings4748.mdl",
"models/vexmira/community/cosmetics/dragon_wings4748b49.mdl",
"models/vexmira/community/cosmetics/dragonfly.mdl",
"models/vexmira/community/cosmetics/dragonfly48.mdl",
"models/vexmira/community/cosmetics/eagle_wings.mdl",
"models/vexmira/community/cosmetics/eagle_wings48.mdl",
"models/vexmira/community/cosmetics/eagle_wings48b49.mdl",
"models/vexmira/community/cosmetics/earth_hat.mdl",
"models/vexmira/community/cosmetics/earth_hat48.mdl",
"models/vexmira/community/cosmetics/earth_hat48b49.mdl",
"models/vexmira/community/cosmetics/frost_angel47.mdl",
"models/vexmira/community/cosmetics/frost_angel4748.mdl",
"models/vexmira/community/cosmetics/frost_angel4748b49.mdl",
"models/vexmira/community/cosmetics/hat_armor47.mdl",
"models/vexmira/community/cosmetics/hat_armor4748.mdl",
"models/vexmira/community/cosmetics/hat_armor4748b49.mdl",
"models/vexmira/community/cosmetics/hat_jester47.mdl",
"models/vexmira/community/cosmetics/hat_jester4748.mdl",
"models/vexmira/community/cosmetics/hat_jester4748b49.mdl",
"models/vexmira/community/cosmetics/hat_sims47.mdl",
"models/vexmira/community/cosmetics/hat_sims4748.mdl",
"models/vexmira/community/cosmetics/hat_sims4748b49.mdl",
"models/vexmira/community/cosmetics/headphones.mdl",
"models/vexmira/community/cosmetics/headphones48.mdl",
"models/vexmira/community/cosmetics/headphones48b49.mdl",
"models/vexmira/community/cosmetics/mech_wings.mdl",
"models/vexmira/community/cosmetics/mech_wings48.mdl",
"models/vexmira/community/cosmetics/mech_wings48b49.mdl",
"models/vexmira/community/cosmetics/pet_amongus47.mdl",
"models/vexmira/community/cosmetics/pet_amongus4748.mdl",
"models/vexmira/community/cosmetics/pet_bat.mdl",
"models/vexmira/community/cosmetics/pet_bat48.mdl",
"models/vexmira/community/cosmetics/pet_cat2.mdl",
"models/vexmira/community/cosmetics/pet_cat248.mdl",
"models/vexmira/community/cosmetics/pet_guardian48.mdl",
"models/vexmira/community/cosmetics/pet_halo47.mdl",
"models/vexmira/community/cosmetics/pet_halo47T.mdl",
"models/vexmira/community/cosmetics/pet_headcrab47.mdl",
"models/vexmira/community/cosmetics/pet_headcrab4748.mdl",
"models/vexmira/community/cosmetics/pet_headcrab4748T.mdl",
"models/vexmira/community/cosmetics/pet_headcrab47T.mdl",
"models/vexmira/community/cosmetics/pet_mummy.mdl",
"models/vexmira/community/cosmetics/pet_mummy48.mdl",
"models/vexmira/community/cosmetics/santa_hat.mdl",
"models/vexmira/community/cosmetics/santa_hat48.mdl",
"models/vexmira/community/cosmetics/santa_hat48b49.mdl",
"models/vexmira/community/cosmetics/shoop_hat.mdl",
"models/vexmira/community/cosmetics/shoop_hat48.mdl",
"models/vexmira/community/cosmetics/shoop_hat48b49.mdl",
"models/vexmira/community/cosmetics/solar_angel47.mdl",
"models/vexmira/community/cosmetics/solar_angel4748.mdl",
"models/vexmira/community/cosmetics/solar_angel4748b49.mdl",
"models/vexmira/community/jetpack/p_jetpack.mdl",
"models/vexmira/community/jetpack/rpgrocket.mdl",
"models/vexmira/community/jetpack/v_jetpack.mdl",
"models/vexmira/community/jetpack/w_jetpack.mdl",
"models/vexmira/community/knives/v_bayonet47.mdl",
"models/vexmira/community/knives/v_butterfly.mdl",
"models/vexmira/community/knives/v_karambit47.mdl",
"models/vexmira/community/knives/v_talon47.mdl",
"models/vexmira_ze/skins/vexmira_p_ak47.mdl",
"models/vexmira_ze/skins/vexmira_p_aug.mdl",
"models/vexmira_ze/skins/vexmira_p_awp.mdl",
"models/vexmira/community/normal/p_c4.mdl",
"models/vexmira_ze/skins/vexmira_p_deagle.mdl",
"models/vexmira_ze/skins/vexmira_p_elite.mdl",
"models/vexmira_ze/skins/vexmira_p_famas.mdl",
"models/vexmira_ze/skins/vexmira_p_fiveseven.mdl",
"models/vexmira/community/normal/p_flashbang.mdl",
"models/vexmira_ze/skins/vexmira_p_g3sg1.mdl",
"models/vexmira/community/normal/p_galil.mdl",
"models/vexmira_ze/skins/vexmira_p_glock18.mdl",
"models/vexmira/community/normal/p_hegrenade.mdl",
"models/vexmira/community/normal/p_knife.mdl",
"models/vexmira_ze/skins/vexmira_p_m249.mdl",
"models/vexmira_ze/skins/vexmira_p_m3.mdl",
"models/vexmira_ze/skins/vexmira_p_m4a1.mdl",
"models/vexmira_ze/skins/vexmira_p_mac10.mdl",
"models/vexmira_ze/skins/vexmira_p_mp5.mdl",
"models/vexmira_ze/skins/vexmira_p_p228.mdl",
"models/vexmira_ze/skins/vexmira_p_p90.mdl",
"models/vexmira_ze/skins/vexmira_p_scout.mdl",
"models/vexmira_ze/skins/vexmira_p_sg550.mdl",
"models/vexmira_ze/skins/vexmira_p_sg552.mdl",
"models/vexmira/community/normal/p_smokegrenade.mdl",
"models/vexmira_ze/skins/vexmira_p_tmp.mdl",
"models/vexmira_ze/skins/vexmira_p_ump45.mdl",
"models/vexmira_ze/skins/vexmira_p_usp.mdl",
"models/vexmira_ze/skins/vexmira_p_xm1014.mdl",
"models/vexmira_ze/skins/vexmira_v_ak47.mdl",
"models/vexmira_ze/skins/vexmira_v_aug.mdl",
"models/vexmira_ze/skins/vexmira_v_awp.mdl",
"models/vexmira_ze/skins/vexmira_v_deagle.mdl",
"models/vexmira/community/normal/v_galil.mdl",
"models/vexmira/community/normal/v_knife.mdl",
"models/vexmira_ze/skins/vexmira_v_m249.mdl",
"models/vexmira_ze/skins/vexmira_v_m4a1.mdl",
"models/vexmira_ze/skins/vexmira_v_mp5.mdl",
"models/vexmira_ze/skins/vexmira_v_sg550.mdl",
"models/vexmira_ze/skins/vexmira_v_sg552.mdl",
"models/vexmira_ze/skins/vexmira_v_xm1014.mdl",
"models/vexmira_ze/skins/vexmira_w_ak47.mdl",
"models/vexmira_ze/skins/vexmira_w_aug.mdl",
"models/vexmira_ze/skins/vexmira_w_awp.mdl",
"models/vexmira/community/normal/w_backpack.mdl",
"models/vexmira/community/normal/w_c4.mdl",
"models/vexmira_ze/skins/vexmira_w_deagle.mdl",
"models/vexmira_ze/skins/vexmira_w_elite.mdl",
"models/vexmira_ze/skins/vexmira_w_famas.mdl",
"models/vexmira_ze/skins/vexmira_w_fiveseven.mdl",
"models/vexmira/community/normal/w_flashbang.mdl",
"models/vexmira_ze/skins/vexmira_w_g3sg1.mdl",
"models/vexmira/community/normal/w_galil.mdl",
"models/vexmira_ze/skins/vexmira_w_glock18.mdl",
"models/vexmira/community/normal/w_hegrenade.mdl",
"models/vexmira/community/normal/w_knife.mdl",
"models/vexmira_ze/skins/vexmira_w_m249.mdl",
"models/vexmira_ze/skins/vexmira_w_m3.mdl",
"models/vexmira_ze/skins/vexmira_w_m4a1.mdl",
"models/vexmira_ze/skins/vexmira_w_mac10.mdl",
"models/vexmira_ze/skins/vexmira_w_mp5.mdl",
"models/vexmira_ze/skins/vexmira_w_p228.mdl",
"models/vexmira_ze/skins/vexmira_w_p90.mdl",
"models/vexmira_ze/skins/vexmira_w_scout.mdl",
"models/vexmira_ze/skins/vexmira_w_sg550.mdl",
"models/vexmira_ze/skins/vexmira_w_sg552.mdl",
"models/vexmira/community/normal/w_shield.mdl",
"models/vexmira/community/normal/w_smokegrenade.mdl",
"models/vexmira_ze/skins/vexmira_w_tmp.mdl",
"models/vexmira_ze/skins/vexmira_w_ump45.mdl",
"models/vexmira_ze/skins/vexmira_w_usp.mdl",
"models/vexmira_ze/skins/vexmira_w_xm1014.mdl",
"models/vexmira/community/props/half_life_tripmine.mdl",
"models/vexmira/community/props/lasermine.mdl",
"models/vexmira/community/props/supplybox_fixed.mdl",
"models/vexmira/community/props/w_goldenEgg.mdl",
"models/vexmira/epic/human_sigil47.mdl",
"models/vexmira/epic/nades/p_fire.mdl",
"models/vexmira/epic/nades/p_flare.mdl",
"models/vexmira/epic/nades/p_frost.mdl",
"models/vexmira/epic/nades/v_fire.mdl",
"models/vexmira/epic/nades/v_flare.mdl",
"models/vexmira/epic/nades/v_frost.mdl",
"models/vexmira/epic/nades/w_fire.mdl",
"models/vexmira/epic/nades/w_flare.mdl",
"models/vexmira/epic/nades/w_frost.mdl",
"models/vexmira/epic/supply_sigil47.mdl",
"models/vexmira/epic/zombie_sigil47.mdl",
"models/w_bow.mdl",
"models/w_ethereal.mdl",
"models/w_fgrenade.mdl",
"models/w_janus7.mdl",
"models/w_m134x.mdl",
"models/w_plasmagun.mdl",
"models/w_salamander.mdl",
"models/w_sfsniper.mdl",
"models/vexmira_ze/grenades/vexmira_v_hegrenade.mdl",
"models/vexmira_ze/grenades/vexmira_v_smokegrenade.mdl",
"models/vexmira_ze/grenades/vexmira_v_flashbang.mdl",
"models/zombie_plague/v_grenade_infect.mdl",
"models/zombie_plague/v_knife_zombie.mdl",
"sound/Zombi/Zombi_Female_Headdown.wav",
"sound/Zombi/Zombi_Female_Headup.wav",
"sound/Zombi/Zombi_Female_Laugh.wav",
"sound/avfrost/frostnova.wav",
"sound/avfrost/impalehit.wav",
"sound/avfrost/impalelaunch1.wav",
"sound/fvox/flatline.wav",
"sound/fvox/health_critical.wav",
"sound/fvox/hevSuit_get_infected_alert2.wav",
"sound/fvox/hev_logon.wav",
"sound/fvox/morphine_shot.wav",
"sound/fvox/power_restored.wav",
"sound/items/cliprelease1.wav",
"sound/jb_engine_b1/shop/syringe_hit.wav",
"sound/jb_engine_b1/shop/syringe_use.wav",
"sound/nst_zombie/Zombi_Female_Breath.wav",
"sound/nst_zombie/Zombi_Female_Headdown.wav",
"sound/nst_zombie/Zombi_Female_Headup.wav",
"sound/nst_zombie/Zombi_Female_Laugh.wav",
"sound/nst_zombie/Zombi_Female_Scream.wav",
"sound/player/pl_long_jump_1.wav",
"sound/vexmira/arena48/b0_attack.wav",
"sound/vexmira/arena48/b0_death.wav",
"sound/vexmira/arena48/b0_intro.wav",
"sound/vexmira/arena48/b0_pain.wav",
"sound/vexmira/arena48/b0_phase.wav",
"sound/vexmira/arena48/b0_r1.wav",
"sound/vexmira/arena48/b0_r2.wav",
"sound/vexmira/arena48/b0_r3.wav",
"sound/vexmira/arena48/b0_step.wav",
"sound/vexmira/arena48/b1_attack.wav",
"sound/vexmira/arena48/b1_death.wav",
"sound/vexmira/arena48/b1_intro.wav",
"sound/vexmira/arena48/b1_pain.wav",
"sound/vexmira/arena48/b1_phase.wav",
"sound/vexmira/arena48/b1_r1.wav",
"sound/vexmira/arena48/b1_r2.wav",
"sound/vexmira/arena48/b1_r3.wav",
"sound/vexmira/arena48/b1_step.wav",
"sound/vexmira/arena48/b2_attack.wav",
"sound/vexmira/arena48/b2_death.wav",
"sound/vexmira/arena48/b2_intro.wav",
"sound/vexmira/arena48/b2_pain.wav",
"sound/vexmira/arena48/b2_phase.wav",
"sound/vexmira/arena48/b2_r1.wav",
"sound/vexmira/arena48/b2_r2.wav",
"sound/vexmira/arena48/b2_r3.wav",
"sound/vexmira/arena48/b2_step.wav",
"sound/vexmira/arena48/b3_attack.wav",
"sound/vexmira/arena48/b3_death.wav",
"sound/vexmira/arena48/b3_intro.wav",
"sound/vexmira/arena48/b3_pain.wav",
"sound/vexmira/arena48/b3_phase.wav",
"sound/vexmira/arena48/b3_r1.wav",
"sound/vexmira/arena48/b3_r2.wav",
"sound/vexmira/arena48/b3_r3.wav",
"sound/vexmira/arena48/b3_step.wav",
"sound/vexmira/arena48/b4_attack.wav",
"sound/vexmira/arena48/b4_death.wav",
"sound/vexmira/arena48/b4_intro.wav",
"sound/vexmira/arena48/b4_pain.wav",
"sound/vexmira/arena48/b4_phase.wav",
"sound/vexmira/arena48/b4_r1.wav",
"sound/vexmira/arena48/b4_r2.wav",
"sound/vexmira/arena48/b4_r3.wav",
"sound/vexmira/arena48/b4_step.wav",
"sound/vexmira/arena48/b5_attack.wav",
"sound/vexmira/arena48/b5_death.wav",
"sound/vexmira/arena48/b5_intro.wav",
"sound/vexmira/arena48/b5_pain.wav",
"sound/vexmira/arena48/b5_phase.wav",
"sound/vexmira/arena48/b5_r1.wav",
"sound/vexmira/arena48/b5_r2.wav",
"sound/vexmira/arena48/b5_r3.wav",
"sound/vexmira/arena48/b5_step.wav",
"sound/vexmira/arena48/b6_attack.wav",
"sound/vexmira/arena48/b6_death.wav",
"sound/vexmira/arena48/b6_intro.wav",
"sound/vexmira/arena48/b6_pain.wav",
"sound/vexmira/arena48/b6_phase.wav",
"sound/vexmira/arena48/b6_r1.wav",
"sound/vexmira/arena48/b6_r2.wav",
"sound/vexmira/arena48/b6_r3.wav",
"sound/vexmira/arena48/b6_step.wav",
"sound/vexmira/arena48/b7_attack.wav",
"sound/vexmira/arena48/b7_death.wav",
"sound/vexmira/arena48/b7_intro.wav",
"sound/vexmira/arena48/b7_pain.wav",
"sound/vexmira/arena48/b7_phase.wav",
"sound/vexmira/arena48/b7_r1.wav",
"sound/vexmira/arena48/b7_r2.wav",
"sound/vexmira/arena48/b7_r3.wav",
"sound/vexmira/arena48/b7_step.wav",
"sound/vexmira/arena48/b8_attack.wav",
"sound/vexmira/arena48/b8_death.wav",
"sound/vexmira/arena48/b8_intro.wav",
"sound/vexmira/arena48/b8_pain.wav",
"sound/vexmira/arena48/b8_phase.wav",
"sound/vexmira/arena48/b8_r1.wav",
"sound/vexmira/arena48/b8_r2.wav",
"sound/vexmira/arena48/b8_r3.wav",
"sound/vexmira/arena48/b8_step.wav",
"sound/vexmira/arena48/event0.wav",
"sound/vexmira/arena48/event1.wav",
"sound/vexmira/arena48/event10.wav",
"sound/vexmira/arena48/event11.wav",
"sound/vexmira/arena48/event12.wav",
"sound/vexmira/arena48/event13.wav",
"sound/vexmira/arena48/event14.wav",
"sound/vexmira/arena48/event15.wav",
"sound/vexmira/arena48/event16.wav",
"sound/vexmira/arena48/event17.wav",
"sound/vexmira/arena48/event18.wav",
"sound/vexmira/arena48/event2.wav",
"sound/vexmira/arena48/event3.wav",
"sound/vexmira/arena48/event4.wav",
"sound/vexmira/arena48/event5.wav",
"sound/vexmira/arena48/event6.wav",
"sound/vexmira/arena48/event7.wav",
"sound/vexmira/arena48/event8.wav",
"sound/vexmira/arena48/event9.wav",
"sound/vexmira/arena48/melee/balrog_balrog9_charge_finish1.wav",
"sound/vexmira/arena48/melee/balrog_balrog9_charge_start1.wav",
"sound/vexmira/arena48/melee/balrog_balrog9_draw.wav",
"sound/vexmira/arena48/melee/balrog_hit.wav",
"sound/vexmira/arena48/melee/balrog_swing.wav",
"sound/vexmira/arena48/melee/janus_hit.wav",
"sound/vexmira/arena48/melee/janus_janus9_stab1.wav",
"sound/vexmira/arena48/melee/janus_janus9_stab2.wav",
"sound/vexmira/arena48/melee/janus_swing.wav",
"sound/vexmira/arena48/melee/skull_hit.wav",
"sound/vexmira/arena48/melee/skull_skullaxe_draw.wav",
"sound/vexmira/arena48/melee/skull_skullaxe_slash1.wav",
"sound/vexmira/arena48/melee/skull_skullaxe_slash_hit.wav",
"sound/vexmira/arena48/melee/skull_skullaxe_slash_miss.wav",
"sound/vexmira/arena48/melee/skull_swing.wav",
"sound/vexmira/arena48/melee/thanatos_hit.wav",
"sound/vexmira/arena48/melee/thanatos_swing.wav",
"sound/vexmira/arena48/melee/thanatos_thanatos9_changea_1.wav",
"sound/vexmira/arena48/melee/thanatos_thanatos9_changea_2.wav",
"sound/vexmira/arena48/melee/thanatos_thanatos9_changea_3.wav",
"sound/vexmira/arena48/melee/thanatos_thanatos9_changea_4.wav",
"sound/vexmira/arena48/melee/thanatos_thanatos9_changeb_1.wav",
"sound/vexmira/arena48/melee/thanatos_thanatos9_changeb_2.wav",
"sound/vexmira/arena48/melee/thanatos_thanatos9_drawa.wav",
"sound/vexmira/arena48/melee/thanatos_thanatos9_shootb_end.wav",
"sound/vexmira/arena48/metal.mp3",
"sound/vexmira/arena48/mode0.wav",
"sound/vexmira/arena48/mode1.wav",
"sound/vexmira/arena48/mode2.wav",
"sound/vexmira/arena48/mode3.wav",
"sound/vexmira/arena48/mode4.wav",
"sound/vexmira/arena48/mode5.wav",
"sound/vexmira/arena48/mode6.wav",
"sound/vexmira/arena48/mode7.wav",
"sound/vexmira/arena48/mode8.wav",
"sound/vexmira/arena48/mode9.wav",
"sound/vexmira/arena48/siege.mp3",
"sound/vexmira/arena48/spectral.mp3",
"sound/vexmira/arena48/supply_in.wav",
"sound/vexmira/arena48/supply_land.wav",
"sound/vexmira/arena48/supply_loot.wav",
"sound/vexmira/arena49/biohazard.mp3",
"sound/vexmira/arena49/city.mp3",
"sound/vexmira/arena49/metal.mp3",
"sound/vexmira/arena49/siege.mp3",
"sound/vexmira/arena49/spectral.mp3",
"sound/vexmira/arena50/arsenal/0/alt.wav",
"sound/vexmira/arena50/arsenal/0/fire.wav",
"sound/vexmira/arena50/arsenal/0/impact.wav",
"sound/vexmira/arena50/arsenal/0/switch.wav",
"sound/vexmira/arena50/arsenal/1/alt.wav",
"sound/vexmira/arena50/arsenal/1/fire.wav",
"sound/vexmira/arena50/arsenal/1/impact.wav",
"sound/vexmira/arena50/arsenal/1/switch.wav",
"sound/vexmira/arena50/arsenal/2/alt.wav",
"sound/vexmira/arena50/arsenal/2/fire.wav",
"sound/vexmira/arena50/arsenal/2/impact.wav",
"sound/vexmira/arena50/arsenal/2/switch.wav",
"sound/vexmira/arena50/arsenal/3/alt.wav",
"sound/vexmira/arena50/arsenal/3/fire.wav",
"sound/vexmira/arena50/arsenal/3/impact.wav",
"sound/vexmira/arena50/arsenal/3/switch.wav",
"sound/vexmira/arena50/arsenal/4/alt.wav",
"sound/vexmira/arena50/arsenal/4/fire.wav",
"sound/vexmira/arena50/arsenal/4/impact.wav",
"sound/vexmira/arena50/arsenal/4/switch.wav",
"sound/vexmira/arena50/arsenal/5/alt.wav",
"sound/vexmira/arena50/arsenal/5/fire.wav",
"sound/vexmira/arena50/arsenal/5/impact.wav",
"sound/vexmira/arena50/arsenal/5/switch.wav",
"sound/vexmira/arena50/arsenal/6/alt.wav",
"sound/vexmira/arena50/arsenal/6/fire.wav",
"sound/vexmira/arena50/arsenal/6/impact.wav",
"sound/vexmira/arena50/arsenal/6/switch.wav",
"sound/vexmira/arena50/arsenal/7/alt.wav",
"sound/vexmira/arena50/arsenal/7/fire.wav",
"sound/vexmira/arena50/arsenal/7/impact.wav",
"sound/vexmira/arena50/arsenal/7/switch.wav",
"sound/vexmira/arena51/ambience/boss0.mp3",
"sound/vexmira/arena51/ambience/boss1.mp3",
"sound/vexmira/arena51/ambience/boss2.mp3",
"sound/vexmira/arena51/ambience/boss3.mp3",
"sound/vexmira/arena51/ambience/boss4.mp3",
"sound/vexmira/arena51/ambience/boss5.mp3",
"sound/vexmira/arena51/ambience/boss6.mp3",
"sound/vexmira/arena51/ambience/boss7.mp3",
"sound/vexmira/arena51/ambience/boss8.mp3",
"sound/vexmira/arena51/ambience/event0.mp3",
"sound/vexmira/arena51/ambience/event1.mp3",
"sound/vexmira/arena51/ambience/event10.mp3",
"sound/vexmira/arena51/ambience/event11.mp3",
"sound/vexmira/arena51/ambience/event12.mp3",
"sound/vexmira/arena51/ambience/event13.mp3",
"sound/vexmira/arena51/ambience/event14.mp3",
"sound/vexmira/arena51/ambience/event15.mp3",
"sound/vexmira/arena51/ambience/event16.mp3",
"sound/vexmira/arena51/ambience/event17.mp3",
"sound/vexmira/arena51/ambience/event18.mp3",
"sound/vexmira/arena51/ambience/event2.mp3",
"sound/vexmira/arena51/ambience/event3.mp3",
"sound/vexmira/arena51/ambience/event4.mp3",
"sound/vexmira/arena51/ambience/event5.mp3",
"sound/vexmira/arena51/ambience/event6.mp3",
"sound/vexmira/arena51/ambience/event7.mp3",
"sound/vexmira/arena51/ambience/event8.mp3",
"sound/vexmira/arena51/ambience/event9.mp3",
"sound/vexmira/arena51/ambience/mode0.mp3",
"sound/vexmira/arena51/ambience/mode1.mp3",
"sound/vexmira/arena51/ambience/mode2.mp3",
"sound/vexmira/arena51/ambience/mode3.mp3",
"sound/vexmira/arena51/ambience/mode4.mp3",
"sound/vexmira/arena51/ambience/mode5.mp3",
"sound/vexmira/arena51/ambience/mode6.mp3",
"sound/vexmira/arena51/ambience/mode7.mp3",
"sound/vexmira/arena51/ambience/mode8.mp3",
"sound/vexmira/arena51/ambience/mode9.mp3",
"sound/vexmira/arena51/arsenal/0/alt.wav",
"sound/vexmira/arena51/arsenal/0/fire.wav",
"sound/vexmira/arena51/arsenal/0/impact.wav",
"sound/vexmira/arena51/arsenal/0/switch.wav",
"sound/vexmira/arena51/arsenal/1/alt.wav",
"sound/vexmira/arena51/arsenal/1/fire.wav",
"sound/vexmira/arena51/arsenal/1/impact.wav",
"sound/vexmira/arena51/arsenal/1/switch.wav",
"sound/vexmira/arena51/arsenal/2/alt.wav",
"sound/vexmira/arena51/arsenal/2/fire.wav",
"sound/vexmira/arena51/arsenal/2/impact.wav",
"sound/vexmira/arena51/arsenal/2/switch.wav",
"sound/vexmira/arena51/arsenal/3/alt.wav",
"sound/vexmira/arena51/arsenal/3/fire.wav",
"sound/vexmira/arena51/arsenal/3/impact.wav",
"sound/vexmira/arena51/arsenal/3/switch.wav",
"sound/vexmira/arena51/arsenal/4/alt.wav",
"sound/vexmira/arena51/arsenal/4/fire.wav",
"sound/vexmira/arena51/arsenal/4/impact.wav",
"sound/vexmira/arena51/arsenal/4/switch.wav",
"sound/vexmira/arena51/arsenal/5/alt.wav",
"sound/vexmira/arena51/arsenal/5/fire.wav",
"sound/vexmira/arena51/arsenal/5/impact.wav",
"sound/vexmira/arena51/arsenal/5/switch.wav",
"sound/vexmira/arena51/arsenal/6/alt.wav",
"sound/vexmira/arena51/arsenal/6/fire.wav",
"sound/vexmira/arena51/arsenal/6/impact.wav",
"sound/vexmira/arena51/arsenal/6/switch.wav",
"sound/vexmira/arena51/arsenal/7/alt.wav",
"sound/vexmira/arena51/arsenal/7/fire.wav",
"sound/vexmira/arena51/arsenal/7/impact.wav",
"sound/vexmira/arena51/arsenal/7/switch.wav",
"sound/vexmira/arena51/boss/0/attack.wav",
"sound/vexmira/arena51/boss/0/death.wav",
"sound/vexmira/arena51/boss/0/intro.wav",
"sound/vexmira/arena51/boss/0/pain.wav",
"sound/vexmira/arena51/boss/0/phase.wav",
"sound/vexmira/arena51/boss/0/r1.wav",
"sound/vexmira/arena51/boss/0/r2.wav",
"sound/vexmira/arena51/boss/0/r3.wav",
"sound/vexmira/arena51/boss/1/attack.wav",
"sound/vexmira/arena51/boss/1/death.wav",
"sound/vexmira/arena51/boss/1/intro.wav",
"sound/vexmira/arena51/boss/1/pain.wav",
"sound/vexmira/arena51/boss/1/phase.wav",
"sound/vexmira/arena51/boss/1/r1.wav",
"sound/vexmira/arena51/boss/1/r2.wav",
"sound/vexmira/arena51/boss/1/r3.wav",
"sound/vexmira/arena51/boss/2/attack.wav",
"sound/vexmira/arena51/boss/2/death.wav",
"sound/vexmira/arena51/boss/2/intro.wav",
"sound/vexmira/arena51/boss/2/pain.wav",
"sound/vexmira/arena51/boss/2/phase.wav",
"sound/vexmira/arena51/boss/2/r1.wav",
"sound/vexmira/arena51/boss/2/r2.wav",
"sound/vexmira/arena51/boss/2/r3.wav",
"sound/vexmira/arena51/boss/3/attack.wav",
"sound/vexmira/arena51/boss/3/death.wav",
"sound/vexmira/arena51/boss/3/intro.wav",
"sound/vexmira/arena51/boss/3/pain.wav",
"sound/vexmira/arena51/boss/3/phase.wav",
"sound/vexmira/arena51/boss/3/r1.wav",
"sound/vexmira/arena51/boss/3/r2.wav",
"sound/vexmira/arena51/boss/3/r3.wav",
"sound/vexmira/arena51/boss/4/attack.wav",
"sound/vexmira/arena51/boss/4/death.wav",
"sound/vexmira/arena51/boss/4/intro.wav",
"sound/vexmira/arena51/boss/4/pain.wav",
"sound/vexmira/arena51/boss/4/phase.wav",
"sound/vexmira/arena51/boss/4/r1.wav",
"sound/vexmira/arena51/boss/4/r2.wav",
"sound/vexmira/arena51/boss/4/r3.wav",
"sound/vexmira/arena51/boss/5/attack.wav",
"sound/vexmira/arena51/boss/5/death.wav",
"sound/vexmira/arena51/boss/5/intro.wav",
"sound/vexmira/arena51/boss/5/pain.wav",
"sound/vexmira/arena51/boss/5/phase.wav",
"sound/vexmira/arena51/boss/5/r1.wav",
"sound/vexmira/arena51/boss/5/r2.wav",
"sound/vexmira/arena51/boss/5/r3.wav",
"sound/vexmira/arena51/boss/6/attack.wav",
"sound/vexmira/arena51/boss/6/death.wav",
"sound/vexmira/arena51/boss/6/intro.wav",
"sound/vexmira/arena51/boss/6/pain.wav",
"sound/vexmira/arena51/boss/6/phase.wav",
"sound/vexmira/arena51/boss/6/r1.wav",
"sound/vexmira/arena51/boss/6/r2.wav",
"sound/vexmira/arena51/boss/6/r3.wav",
"sound/vexmira/arena51/boss/7/attack.wav",
"sound/vexmira/arena51/boss/7/death.wav",
"sound/vexmira/arena51/boss/7/intro.wav",
"sound/vexmira/arena51/boss/7/pain.wav",
"sound/vexmira/arena51/boss/7/phase.wav",
"sound/vexmira/arena51/boss/7/r1.wav",
"sound/vexmira/arena51/boss/7/r2.wav",
"sound/vexmira/arena51/boss/7/r3.wav",
"sound/vexmira/arena51/boss/8/attack.wav",
"sound/vexmira/arena51/boss/8/death.wav",
"sound/vexmira/arena51/boss/8/intro.wav",
"sound/vexmira/arena51/boss/8/pain.wav",
"sound/vexmira/arena51/boss/8/phase.wav",
"sound/vexmira/arena51/boss/8/r1.wav",
"sound/vexmira/arena51/boss/8/r2.wav",
"sound/vexmira/arena51/boss/8/r3.wav",
"sound/vexmira/arena51/classes/0.wav",
"sound/vexmira/arena51/classes/1.wav",
"sound/vexmira/arena51/classes/10.wav",
"sound/vexmira/arena51/classes/11.wav",
"sound/vexmira/arena51/classes/12.wav",
"sound/vexmira/arena51/classes/13.wav",
"sound/vexmira/arena51/classes/14.wav",
"sound/vexmira/arena51/classes/15.wav",
"sound/vexmira/arena51/classes/16.wav",
"sound/vexmira/arena51/classes/17.wav",
"sound/vexmira/arena51/classes/18.wav",
"sound/vexmira/arena51/classes/19.wav",
"sound/vexmira/arena51/classes/2.wav",
"sound/vexmira/arena51/classes/20.wav",
"sound/vexmira/arena51/classes/21.wav",
"sound/vexmira/arena51/classes/22.wav",
"sound/vexmira/arena51/classes/23.wav",
"sound/vexmira/arena51/classes/3.wav",
"sound/vexmira/arena51/classes/4.wav",
"sound/vexmira/arena51/classes/5.wav",
"sound/vexmira/arena51/classes/6.wav",
"sound/vexmira/arena51/classes/7.wav",
"sound/vexmira/arena51/classes/8.wav",
"sound/vexmira/arena51/classes/9.wav",
"sound/vexmira/arena51/context/airdrop_incoming.wav",
"sound/vexmira/arena51/context/airdrop_land.wav",
"sound/vexmira/arena51/context/airdrop_loot.wav",
"sound/vexmira/arena51/context/lm_activate.wav",
"sound/vexmira/arena51/context/lm_break.wav",
"sound/vexmira/arena51/context/lm_charge.wav",
"sound/vexmira/arena51/context/lm_deploy.wav",
"sound/vexmira/arena51/context/lm_hit.wav",
"sound/vexmira/arena51/context/lm_pickup.wav",
"sound/vexmira/arena51/context/nade_arm.wav",
"sound/vexmira/arena51/context/nade_beep.wav",
"sound/vexmira/arena51/context/nade_mode.wav",
"sound/vexmira/arena51/context/skill_unlock.wav",
"sound/vexmira/arena51/context/ui_boss_bar.wav",
"sound/vexmira/arena51/context/ui_class_select.wav",
"sound/vexmira/arena51/context/ui_menu_select.wav",
"sound/vexmira/arena51/context/ui_open.wav",
"sound/vexmira/arena51/context/ui_vote_end.wav",
"sound/vexmira/arena51/context/ui_vote_start.wav",
"sound/vexmira/arena51/cues/event0.wav",
"sound/vexmira/arena51/cues/event1.wav",
"sound/vexmira/arena51/cues/event10.wav",
"sound/vexmira/arena51/cues/event11.wav",
"sound/vexmira/arena51/cues/event12.wav",
"sound/vexmira/arena51/cues/event13.wav",
"sound/vexmira/arena51/cues/event14.wav",
"sound/vexmira/arena51/cues/event15.wav",
"sound/vexmira/arena51/cues/event16.wav",
"sound/vexmira/arena51/cues/event17.wav",
"sound/vexmira/arena51/cues/event18.wav",
"sound/vexmira/arena51/cues/event2.wav",
"sound/vexmira/arena51/cues/event3.wav",
"sound/vexmira/arena51/cues/event4.wav",
"sound/vexmira/arena51/cues/event5.wav",
"sound/vexmira/arena51/cues/event6.wav",
"sound/vexmira/arena51/cues/event7.wav",
"sound/vexmira/arena51/cues/event8.wav",
"sound/vexmira/arena51/cues/event9.wav",
"sound/vexmira/arena51/cues/mode0.wav",
"sound/vexmira/arena51/cues/mode1.wav",
"sound/vexmira/arena51/cues/mode2.wav",
"sound/vexmira/arena51/cues/mode3.wav",
"sound/vexmira/arena51/cues/mode4.wav",
"sound/vexmira/arena51/cues/mode5.wav",
"sound/vexmira/arena51/cues/mode6.wav",
"sound/vexmira/arena51/cues/mode7.wav",
"sound/vexmira/arena51/cues/mode8.wav",
"sound/vexmira/arena51/cues/mode9.wav",
"sound/vexmira/arena51/native/arsenal/0/0.wav",
"sound/vexmira/arena51/native/arsenal/0/1.wav",
"sound/vexmira/arena51/native/arsenal/1/0.wav",
"sound/vexmira/arena51/native/arsenal/1/1.wav",
"sound/vexmira/arena51/native/arsenal/1/2.wav",
"sound/vexmira/arena51/native/arsenal/2/0.wav",
"sound/vexmira/arena51/native/arsenal/2/1.wav",
"sound/vexmira/arena51/native/arsenal/2/2.wav",
"sound/vexmira/arena51/native/arsenal/3/0.wav",
"sound/vexmira/arena51/native/arsenal/3/1.wav",
"sound/vexmira/arena51/native/arsenal/3/2.wav",
"sound/vexmira/arena51/native/arsenal/3/3.wav",
"sound/vexmira/arena51/native/arsenal/4/0.wav",
"sound/vexmira/arena51/native/arsenal/4/1.wav",
"sound/vexmira/arena51/native/arsenal/4/2.wav",
"sound/vexmira/arena51/native/arsenal/4/3.wav",
"sound/vexmira/arena51/native/arsenal/5/0.wav",
"sound/vexmira/arena51/native/arsenal/5/1.wav",
"sound/vexmira/arena51/native/arsenal/5/2.wav",
"sound/vexmira/arena51/native/arsenal/5/3.wav",
"sound/vexmira/arena51/native/arsenal/5/4.wav",
"sound/vexmira/arena51/native/arsenal/5/5.wav",
"sound/vexmira/arena51/native/arsenal/5/6.wav",
"sound/vexmira/arena51/native/arsenal/5/7.wav",
"sound/vexmira/arena51/native/arsenal/5/8.wav",
"sound/vexmira/arena51/native/arsenal/5/9.wav",
"sound/vexmira/arena51/native/arsenal/6/0.wav",
"sound/vexmira/arena51/native/arsenal/6/1.wav",
"sound/vexmira/arena51/native/arsenal/6/2.wav",
"sound/vexmira/arena51/native/arsenal/6/3.wav",
"sound/vexmira/arena51/native/arsenal/6/4.wav",
"sound/vexmira/arena51/native/arsenal/6/5.wav",
"sound/vexmira/arena51/native/arsenal/6/6.wav",
"sound/vexmira/arena51/native/arsenal/6/7.wav",
"sound/vexmira/arena51/native/arsenal/6/8.wav",
"sound/vexmira/arena51/native/arsenal/7/0.wav",
"sound/vexmira/arena51/native/arsenal/7/1.wav",
"sound/vexmira/arena51/native/arsenal/7/2.wav",
"sound/vexmira/arena51/native/arsenal/7/3.wav",
"sound/vexmira/arena51/native/arsenal/7/4.wav",
"sound/vexmira/arena51/native/arsenal/7/5.wav",
"sound/vexmira/arena51/native/arsenal/7/6.wav",
"sound/vexmira/arena51/native/default/ak47/0.wav",
"sound/vexmira/arena51/native/default/ak47/1.wav",
"sound/vexmira/arena51/native/default/ak47/2.wav",
"sound/vexmira/arena51/native/default/aug/0.wav",
"sound/vexmira/arena51/native/default/aug/1.wav",
"sound/vexmira/arena51/native/default/aug/2.wav",
"sound/vexmira/arena51/native/default/aug/3.wav",
"sound/vexmira/arena51/native/default/aug/4.wav",
"sound/vexmira/arena51/native/default/awp/0.wav",
"sound/vexmira/arena51/native/default/awp/1.wav",
"sound/vexmira/arena51/native/default/awp/2.wav",
"sound/vexmira/arena51/native/default/awp/3.wav",
"sound/vexmira/arena51/native/default/awp/4.wav",
"sound/vexmira/arena51/native/default/c4/0.wav",
"sound/vexmira/arena51/native/default/deagle/0.wav",
"sound/vexmira/arena51/native/default/deagle/1.wav",
"sound/vexmira/arena51/native/default/deagle/2.wav",
"sound/vexmira/arena51/native/default/elite/0.wav",
"sound/vexmira/arena51/native/default/elite/1.wav",
"sound/vexmira/arena51/native/default/elite/2.wav",
"sound/vexmira/arena51/native/default/elite/3.wav",
"sound/vexmira/arena51/native/default/elite/4.wav",
"sound/vexmira/arena51/native/default/elite/5.wav",
"sound/vexmira/arena51/native/default/famas/0.wav",
"sound/vexmira/arena51/native/default/famas/1.wav",
"sound/vexmira/arena51/native/default/famas/2.wav",
"sound/vexmira/arena51/native/default/fiveseven/0.wav",
"sound/vexmira/arena51/native/default/fiveseven/1.wav",
"sound/vexmira/arena51/native/default/fiveseven/2.wav",
"sound/vexmira/arena51/native/default/fiveseven/3.wav",
"sound/vexmira/arena51/native/default/g3sg1/0.wav",
"sound/vexmira/arena51/native/default/g3sg1/1.wav",
"sound/vexmira/arena51/native/default/g3sg1/2.wav",
"sound/vexmira/arena51/native/default/galil/0.wav",
"sound/vexmira/arena51/native/default/galil/1.wav",
"sound/vexmira/arena51/native/default/galil/2.wav",
"sound/vexmira/arena51/native/default/glock18/0.wav",
"sound/vexmira/arena51/native/default/glock18/1.wav",
"sound/vexmira/arena51/native/default/glock18/2.wav",
"sound/vexmira/arena51/native/default/glock18/3.wav",
"sound/vexmira/arena51/native/default/knife/0.wav",
"sound/vexmira/arena51/native/default/m249/0.wav",
"sound/vexmira/arena51/native/default/m249/1.wav",
"sound/vexmira/arena51/native/default/m249/2.wav",
"sound/vexmira/arena51/native/default/m249/3.wav",
"sound/vexmira/arena51/native/default/m249/4.wav",
"sound/vexmira/arena51/native/default/m249/5.wav",
"sound/vexmira/arena51/native/default/m3/0.wav",
"sound/vexmira/arena51/native/default/m3/1.wav",
"sound/vexmira/arena51/native/default/m4a1/0.wav",
"sound/vexmira/arena51/native/default/m4a1/1.wav",
"sound/vexmira/arena51/native/default/m4a1/2.wav",
"sound/vexmira/arena51/native/default/m4a1/3.wav",
"sound/vexmira/arena51/native/default/m4a1/4.wav",
"sound/vexmira/arena51/native/default/m4a1/5.wav",
"sound/vexmira/arena51/native/default/mac10/0.wav",
"sound/vexmira/arena51/native/default/mac10/1.wav",
"sound/vexmira/arena51/native/default/mac10/2.wav",
"sound/vexmira/arena51/native/default/mac10/3.wav",
"sound/vexmira/arena51/native/default/mp5/0.wav",
"sound/vexmira/arena51/native/default/mp5/1.wav",
"sound/vexmira/arena51/native/default/mp5/2.wav",
"sound/vexmira/arena51/native/default/p228/0.wav",
"sound/vexmira/arena51/native/default/p228/1.wav",
"sound/vexmira/arena51/native/default/p228/2.wav",
"sound/vexmira/arena51/native/default/p228/3.wav",
"sound/vexmira/arena51/native/default/p228/4.wav",
"sound/vexmira/arena51/native/default/p90/0.wav",
"sound/vexmira/arena51/native/default/p90/1.wav",
"sound/vexmira/arena51/native/default/p90/2.wav",
"sound/vexmira/arena51/native/default/p90/3.wav",
"sound/vexmira/arena51/native/default/scout/0.wav",
"sound/vexmira/arena51/native/default/scout/1.wav",
"sound/vexmira/arena51/native/default/scout/2.wav",
"sound/vexmira/arena51/native/default/sg550/0.wav",
"sound/vexmira/arena51/native/default/sg550/1.wav",
"sound/vexmira/arena51/native/default/sg550/2.wav",
"sound/vexmira/arena51/native/default/sg552/0.wav",
"sound/vexmira/arena51/native/default/sg552/1.wav",
"sound/vexmira/arena51/native/default/sg552/2.wav",
"sound/vexmira/arena51/native/default/tmp/0.wav",
"sound/vexmira/arena51/native/default/tmp/1.wav",
"sound/vexmira/arena51/native/default/tmp/2.wav",
"sound/vexmira/arena51/native/default/ump45/0.wav",
"sound/vexmira/arena51/native/default/ump45/1.wav",
"sound/vexmira/arena51/native/default/ump45/2.wav",
"sound/vexmira/arena51/native/default/usp/0.wav",
"sound/vexmira/arena51/native/default/usp/1.wav",
"sound/vexmira/arena51/native/default/usp/2.wav",
"sound/vexmira/arena51/native/default/usp/3.wav",
"sound/vexmira/arena51/native/default/usp/4.wav",
"sound/vexmira/arena51/native/default/usp/5.wav",
"sound/vexmira/arena51/native/default/usp/6.wav",
"sound/vexmira/arena51/native/default/xm1014/0.wav",
"sound/vexmira/arena51/native/default/xm1014/1.wav",
"sound/vexmira/arena51/native/grenade_pin.wav",
"sound/vexmira/arena51/world/ability.wav",
"sound/vexmira/arena51/world/assassin_attack.wav",
"sound/vexmira/arena51/world/assassin_death.wav",
"sound/vexmira/arena51/world/assassin_intro.wav",
"sound/vexmira/arena51/world/assassin_pain.wav",
"sound/vexmira/arena51/world/burn.wav",
"sound/vexmira/arena51/world/fire.wav",
"sound/vexmira/arena51/world/freeze.wav",
"sound/vexmira/arena51/world/human_win.wav",
"sound/vexmira/arena51/world/ice.wav",
"sound/vexmira/arena51/world/lightning.wav",
"sound/vexmira/arena51/world/nemesis.wav",
"sound/vexmira/arena51/world/round_start.wav",
"sound/vexmira/arena51/world/zap.wav",
"sound/vexmira/arena51/world/zombie_win.wav",
"sound/vexmira/arena52/ambience/boss0.wav",
"sound/vexmira/arena52/ambience/boss1.wav",
"sound/vexmira/arena52/ambience/boss2.wav",
"sound/vexmira/arena52/ambience/boss3.wav",
"sound/vexmira/arena52/ambience/boss4.wav",
"sound/vexmira/arena52/ambience/boss5.wav",
"sound/vexmira/arena52/ambience/boss6.wav",
"sound/vexmira/arena52/ambience/boss7.wav",
"sound/vexmira/arena52/ambience/boss8.wav",
"sound/vexmira/arena52/ambience/event0.wav",
"sound/vexmira/arena52/ambience/event1.wav",
"sound/vexmira/arena52/ambience/event10.wav",
"sound/vexmira/arena52/ambience/event11.wav",
"sound/vexmira/arena52/ambience/event12.wav",
"sound/vexmira/arena52/ambience/event13.wav",
"sound/vexmira/arena52/ambience/event14.wav",
"sound/vexmira/arena52/ambience/event15.wav",
"sound/vexmira/arena52/ambience/event16.wav",
"sound/vexmira/arena52/ambience/event17.wav",
"sound/vexmira/arena52/ambience/event18.wav",
"sound/vexmira/arena52/ambience/event2.wav",
"sound/vexmira/arena52/ambience/event3.wav",
"sound/vexmira/arena52/ambience/event4.wav",
"sound/vexmira/arena52/ambience/event5.wav",
"sound/vexmira/arena52/ambience/event6.wav",
"sound/vexmira/arena52/ambience/event7.wav",
"sound/vexmira/arena52/ambience/event8.wav",
"sound/vexmira/arena52/ambience/event9.wav",
"sound/vexmira/arena52/ambience/mode0.wav",
"sound/vexmira/arena52/ambience/mode1.wav",
"sound/vexmira/arena52/ambience/mode2.wav",
"sound/vexmira/arena52/ambience/mode3.wav",
"sound/vexmira/arena52/ambience/mode4.wav",
"sound/vexmira/arena52/ambience/mode5.wav",
"sound/vexmira/arena52/ambience/mode6.wav",
"sound/vexmira/arena52/ambience/mode7.wav",
"sound/vexmira/arena52/ambience/mode8.wav",
"sound/vexmira/arena52/ambience/mode9.wav",
"sound/vexmira/arena52/foley/bolt.wav",
"sound/vexmira/arena52/foley/draw.wav",
"sound/vexmira/arena52/foley/magin.wav",
"sound/vexmira/arena52/foley/magout.wav",
"sound/vexmira/arena52/foley/pin.wav",
"sound/vexmira/arena52/foley/scope.wav",
"sound/vexmira/arena52/foley/shell.wav",
"sound/vexmira/arena52/foley/throw.wav",
"sound/vexmira/arena52/native/default/ak47/0.wav",
"sound/vexmira/arena52/native/default/ak47/1.wav",
"sound/vexmira/arena52/native/default/ak47/2.wav",
"sound/vexmira/arena52/native/default/aug/0.wav",
"sound/vexmira/arena52/native/default/aug/1.wav",
"sound/vexmira/arena52/native/default/aug/2.wav",
"sound/vexmira/arena52/native/default/aug/3.wav",
"sound/vexmira/arena52/native/default/aug/4.wav",
"sound/vexmira/arena52/native/default/awp/0.wav",
"sound/vexmira/arena52/native/default/awp/1.wav",
"sound/vexmira/arena52/native/default/awp/2.wav",
"sound/vexmira/arena52/native/default/awp/3.wav",
"sound/vexmira/arena52/native/default/awp/4.wav",
"sound/vexmira/arena52/native/default/c4/0.wav",
"sound/vexmira/arena52/native/default/deagle/0.wav",
"sound/vexmira/arena52/native/default/deagle/1.wav",
"sound/vexmira/arena52/native/default/deagle/2.wav",
"sound/vexmira/arena52/native/default/elite/0.wav",
"sound/vexmira/arena52/native/default/elite/1.wav",
"sound/vexmira/arena52/native/default/elite/2.wav",
"sound/vexmira/arena52/native/default/elite/3.wav",
"sound/vexmira/arena52/native/default/elite/4.wav",
"sound/vexmira/arena52/native/default/elite/5.wav",
"sound/vexmira/arena52/native/default/famas/0.wav",
"sound/vexmira/arena52/native/default/famas/1.wav",
"sound/vexmira/arena52/native/default/famas/2.wav",
"sound/vexmira/arena52/native/default/fiveseven/0.wav",
"sound/vexmira/arena52/native/default/fiveseven/1.wav",
"sound/vexmira/arena52/native/default/fiveseven/2.wav",
"sound/vexmira/arena52/native/default/fiveseven/3.wav",
"sound/vexmira/arena52/native/default/g3sg1/0.wav",
"sound/vexmira/arena52/native/default/g3sg1/1.wav",
"sound/vexmira/arena52/native/default/g3sg1/2.wav",
"sound/vexmira/arena52/native/default/galil/0.wav",
"sound/vexmira/arena52/native/default/galil/1.wav",
"sound/vexmira/arena52/native/default/galil/2.wav",
"sound/vexmira/arena52/native/default/glock18/0.wav",
"sound/vexmira/arena52/native/default/glock18/1.wav",
"sound/vexmira/arena52/native/default/glock18/2.wav",
"sound/vexmira/arena52/native/default/glock18/3.wav",
"sound/vexmira/arena52/native/default/knife/0.wav",
"sound/vexmira/arena52/native/default/m249/0.wav",
"sound/vexmira/arena52/native/default/m249/1.wav",
"sound/vexmira/arena52/native/default/m249/2.wav",
"sound/vexmira/arena52/native/default/m249/3.wav",
"sound/vexmira/arena52/native/default/m249/4.wav",
"sound/vexmira/arena52/native/default/m249/5.wav",
"sound/vexmira/arena52/native/default/m3/0.wav",
"sound/vexmira/arena52/native/default/m3/1.wav",
"sound/vexmira/arena52/native/default/m4a1/0.wav",
"sound/vexmira/arena52/native/default/m4a1/1.wav",
"sound/vexmira/arena52/native/default/m4a1/2.wav",
"sound/vexmira/arena52/native/default/m4a1/3.wav",
"sound/vexmira/arena52/native/default/m4a1/4.wav",
"sound/vexmira/arena52/native/default/m4a1/5.wav",
"sound/vexmira/arena52/native/default/mac10/0.wav",
"sound/vexmira/arena52/native/default/mac10/1.wav",
"sound/vexmira/arena52/native/default/mac10/2.wav",
"sound/vexmira/arena52/native/default/mac10/3.wav",
"sound/vexmira/arena52/native/default/mp5/0.wav",
"sound/vexmira/arena52/native/default/mp5/1.wav",
"sound/vexmira/arena52/native/default/mp5/2.wav",
"sound/vexmira/arena52/native/default/p228/0.wav",
"sound/vexmira/arena52/native/default/p228/1.wav",
"sound/vexmira/arena52/native/default/p228/2.wav",
"sound/vexmira/arena52/native/default/p228/3.wav",
"sound/vexmira/arena52/native/default/p228/4.wav",
"sound/vexmira/arena52/native/default/p90/0.wav",
"sound/vexmira/arena52/native/default/p90/1.wav",
"sound/vexmira/arena52/native/default/p90/2.wav",
"sound/vexmira/arena52/native/default/p90/3.wav",
"sound/vexmira/arena52/native/default/scout/0.wav",
"sound/vexmira/arena52/native/default/scout/1.wav",
"sound/vexmira/arena52/native/default/scout/2.wav",
"sound/vexmira/arena52/native/default/sg550/0.wav",
"sound/vexmira/arena52/native/default/sg550/1.wav",
"sound/vexmira/arena52/native/default/sg550/2.wav",
"sound/vexmira/arena52/native/default/sg552/0.wav",
"sound/vexmira/arena52/native/default/sg552/1.wav",
"sound/vexmira/arena52/native/default/sg552/2.wav",
"sound/vexmira/arena52/native/default/tmp/0.wav",
"sound/vexmira/arena52/native/default/tmp/1.wav",
"sound/vexmira/arena52/native/default/tmp/2.wav",
"sound/vexmira/arena52/native/default/ump45/0.wav",
"sound/vexmira/arena52/native/default/ump45/1.wav",
"sound/vexmira/arena52/native/default/ump45/2.wav",
"sound/vexmira/arena52/native/default/usp/0.wav",
"sound/vexmira/arena52/native/default/usp/1.wav",
"sound/vexmira/arena52/native/default/usp/2.wav",
"sound/vexmira/arena52/native/default/usp/3.wav",
"sound/vexmira/arena52/native/default/usp/4.wav",
"sound/vexmira/arena52/native/default/usp/5.wav",
"sound/vexmira/arena52/native/default/usp/6.wav",
"sound/vexmira/arena52/native/default/xm1014/0.wav",
"sound/vexmira/arena52/native/default/xm1014/1.wav",
"sound/vexmira/arena52/radio/boss.wav",
"sound/vexmira/arena52/radio/chatter1.wav",
"sound/vexmira/arena52/radio/chatter2.wav",
"sound/vexmira/arena52/radio/chatter3.wav",
"sound/vexmira/arena52/radio/chatter4.wav",
"sound/vexmira/arena52/radio/fire.wav",
"sound/vexmira/arena52/radio/hazard.wav",
"sound/vexmira/arena52/radio/ice.wav",
"sound/vexmira/arena52/radio/last.wav",
"sound/vexmira/arena52/radio/loss.wav",
"sound/vexmira/arena52/radio/night.wav",
"sound/vexmira/arena52/radio/start.wav",
"sound/vexmira/arena52/radio/storm.wav",
"sound/vexmira/arena52/radio/supply.wav",
"sound/vexmira/arena52/radio/win.wav",
"sound/vexmira/arena521/radio/en/boss.wav",
"sound/vexmira/arena521/radio/en/chatter.wav",
"sound/vexmira/arena521/radio/en/fire.wav",
"sound/vexmira/arena521/radio/en/hazard.wav",
"sound/vexmira/arena521/radio/en/ice.wav",
"sound/vexmira/arena521/radio/en/last.wav",
"sound/vexmira/arena521/radio/en/loss.wav",
"sound/vexmira/arena521/radio/en/start.wav",
"sound/vexmira/arena521/radio/en/supply.wav",
"sound/vexmira/arena521/radio/en/win.wav",
"sound/vexmira/community/jetpack/blow.wav",
"sound/vexmira/community/jetpack/fly.wav",
"sound/vexmira/community/jetpack/fly47.wav",
"sound/vexmira/community/jetpack/rocket.wav",
"sound/vexmira/community/jetpack/travel.wav",
"sound/vexmira/epic/boss0_intro.wav",
"sound/vexmira/epic/boss0_r1.wav",
"sound/vexmira/epic/boss0_r2.wav",
"sound/vexmira/epic/boss0_r3.wav",
"sound/vexmira/epic/boss1_intro.wav",
"sound/vexmira/epic/boss1_r1.wav",
"sound/vexmira/epic/boss1_r2.wav",
"sound/vexmira/epic/boss1_r3.wav",
"sound/vexmira/epic/boss2_intro.wav",
"sound/vexmira/epic/boss2_r1.wav",
"sound/vexmira/epic/boss2_r2.wav",
"sound/vexmira/epic/boss2_r3.wav",
"sound/vexmira/epic/boss3_intro.wav",
"sound/vexmira/epic/boss3_r1.wav",
"sound/vexmira/epic/boss3_r2.wav",
"sound/vexmira/epic/boss3_r3.wav",
"sound/vexmira/epic/boss4_intro.wav",
"sound/vexmira/epic/boss4_r1.wav",
"sound/vexmira/epic/boss4_r2.wav",
"sound/vexmira/epic/boss4_r3.wav",
"sound/vexmira/epic/boss5_intro.wav",
"sound/vexmira/epic/boss5_r1.wav",
"sound/vexmira/epic/boss5_r2.wav",
"sound/vexmira/epic/boss5_r3.wav",
"sound/vexmira/epic/boss6_intro.wav",
"sound/vexmira/epic/boss6_r1.wav",
"sound/vexmira/epic/boss6_r2.wav",
"sound/vexmira/epic/boss6_r3.wav",
"sound/vexmira/epic/boss7_intro.wav",
"sound/vexmira/epic/boss7_r1.wav",
"sound/vexmira/epic/boss7_r2.wav",
"sound/vexmira/epic/boss7_r3.wav",
"sound/vexmira/epic/boss8_intro.wav",
"sound/vexmira/epic/boss8_r1.wav",
"sound/vexmira/epic/boss8_r2.wav",
"sound/vexmira/epic/boss8_r3.wav",
"sound/vexmira/epic/count/eight.wav",
"sound/vexmira/epic/count/five.wav",
"sound/vexmira/epic/count/four.wav",
"sound/vexmira/epic/count/nine.wav",
"sound/vexmira/epic/count/one.wav",
"sound/vexmira/epic/count/seven.wav",
"sound/vexmira/epic/count/six.wav",
"sound/vexmira/epic/count/ten.wav",
"sound/vexmira/epic/count/three.wav",
"sound/vexmira/epic/count/two.wav",
"sound/vexmira/epic/flare.wav",
"sound/vexmira/epic/human_win.wav",
"sound/vexmira/epic/ice.wav",
"sound/vexmira/epic/music/boss0.mp3",
"sound/vexmira/epic/music/boss1.mp3",
"sound/vexmira/epic/music/boss2.mp3",
"sound/vexmira/epic/music/boss3.mp3",
"sound/vexmira/epic/music/boss4.mp3",
"sound/vexmira/epic/music/boss5.mp3",
"sound/vexmira/epic/music/boss6.mp3",
"sound/vexmira/epic/music/boss7.mp3",
"sound/vexmira/epic/music/boss8.mp3",
"sound/vexmira/epic/round_start.wav",
"sound/vexmira/epic/skill0.wav",
"sound/vexmira/epic/skill1.wav",
"sound/vexmira/epic/skill2.wav",
"sound/vexmira/epic/skill3.wav",
"sound/vexmira/epic/skill4.wav",
"sound/vexmira/epic/skill5.wav",
"sound/vexmira/epic/skill6.wav",
"sound/vexmira/epic/zombie_win.wav",
"sound/vexmira/meme/bruh.wav",
"sound/vexmira/meme/discord.wav",
"sound/vexmira/meme/emotional_damage.wav",
"sound/vexmira/meme/error.wav",
"sound/vexmira/meme/metal_pipe.wav",
"sound/vexmira/meme/oof.wav",
"sound/vexmira/meme/taco.wav",
"sound/vexmira/meme/vine_boom.wav",
"sound/vexmira/meme/weide.wav",
"sound/vexmira/meme/wow.wav",
"sound/weapons/AN M14/draw.wav",
"sound/weapons/AN M14/pinpull.wav",
"sound/weapons/G_MZC_MP7_CLIPIN.wav",
"sound/weapons/G_MZC_MP7_CLIPOUT.wav",
"sound/weapons/G_RELOAD_MP7.wav",
"sound/weapons/MK23_BBACK.wav",
"sound/weapons/MK23_BCBACK.wav",
"sound/weapons/MK23_BlowBack.wav",
"sound/weapons/MK23_ClipIn.wav",
"sound/weapons/MK23_ClipOut.wav",
"sound/weapons/MK23_DelBlowBack.wav",
"sound/weapons/PL82 BSAA/deploy.wav",
"sound/weapons/PL82 BSAA/draw.wav",
"sound/weapons/PL82 BSAA/pinpull.wav",
"sound/weapons/ak47_boltpull.wav",
"sound/weapons/ak47_clipin.wav",
"sound/weapons/ak47_clipout.wav",
"sound/weapons/aug_boltpull.wav",
"sound/weapons/aug_boltslap.wav",
"sound/weapons/aug_clipin.wav",
"sound/weapons/aug_clipout.wav",
"sound/weapons/aug_forearm.wav",
"sound/weapons/awp_clipin.wav",
"sound/weapons/awp_clipout.wav",
"sound/weapons/boltdown.wav",
"sound/weapons/boltpull1.wav",
"sound/weapons/boltup.wav",
"sound/weapons/bow_charge_finish1.wav",
"sound/weapons/bow_charge_shoot1_empty.wav",
"sound/weapons/bow_charge_shoot2.wav",
"sound/weapons/bow_charge_start1.wav",
"sound/weapons/bow_charge_start2.wav",
"sound/weapons/bow_draw.wav",
"sound/weapons/bow_shoot1.wav",
"sound/weapons/c4_click.wav",
"sound/weapons/change1_ready.wav",
"sound/weapons/clipin1.wav",
"sound/weapons/clipout1.wav",
"sound/weapons/csgo/bknife/bknife_backstab02.wav",
"sound/weapons/csgo/bknife/bknife_draw02.wav",
"sound/weapons/csgo/bknife/bknife_look01_a.wav",
"sound/weapons/csgo/bknife/bknife_look01_b.wav",
"sound/weapons/csgo/bknife/bknife_look02_a.wav",
"sound/weapons/csgo/bknife/bknife_look02_b.wav",
"sound/weapons/csgo/bknife/bknife_look03_a.wav",
"sound/weapons/csgo/bknife/bknife_look03_b.wav",
"sound/weapons/csgo/deagle/de_deploy.wav",
"sound/weapons/csgo/deagle/deagle_special_lookat_f009.wav",
"sound/weapons/csgo/deagle/deagle_special_lookat_f036.wav",
"sound/weapons/csgo/deagle/deagle_special_lookat_f057.wav",
"sound/weapons/csgo/deagle/deagle_special_lookat_f081.wav",
"sound/weapons/csgo/deagle/deagle_special_lookat_f111.wav",
"sound/weapons/csgo/deagle/deagle_special_lookat_f133.wav",
"sound/weapons/csgo/deagle/deagle_special_lookat_f166.wav",
"sound/weapons/csgo/deagle/deagle_special_lookat_f193.wav",
"sound/weapons/csgo/deagle/deagle_special_lookat_f228.wav",
"sound/weapons/csgo/knife/knife_deploy1.wav",
"sound/weapons/csgo/knife_widow/widow_deploy_01.wav",
"sound/weapons/csgo/knife_widow/widow_lookat2_end.wav",
"sound/weapons/csgo/knife_widow/widow_lookat2_loop_02.wav",
"sound/weapons/csgo/knife_widow/widow_lookat2_loop_03.wav",
"sound/weapons/csgo/knife_widow/widow_lookat2_loop_04.wav",
"sound/weapons/csgo/knife_widow/widow_lookat2_loop_05.wav",
"sound/weapons/csgo/knife_widow/widow_lookat2_start.wav",
"sound/weapons/csgo/movement1.wav",
"sound/weapons/csgo/movement2.wav",
"sound/weapons/csgo/movement3.wav",
"sound/weapons/de_clipin.wav",
"sound/weapons/de_clipout.wav",
"sound/weapons/de_deploy.wav",
"sound/weapons/dragonsword_draw.wav",
"sound/weapons/dragonsword_hit1.wav",
"sound/weapons/dragonsword_hit2.wav",
"sound/weapons/dragonsword_idle.wav",
"sound/weapons/dragonsword_slash1.wav",
"sound/weapons/dragonsword_slash2.wav",
"sound/weapons/dragonsword_stab.wav",
"sound/weapons/dragonsword_stab_hit.wav",
"sound/weapons/dragonsword_wall.wav",
"sound/weapons/elite_clipout.wav",
"sound/weapons/elite_deploy.wav",
"sound/weapons/elite_leftclipin.wav",
"sound/weapons/elite_reloadstart.wav",
"sound/weapons/elite_rightclipin.wav",
"sound/weapons/elite_sliderelease.wav",
"sound/weapons/elite_twirl.wav",
"sound/weapons/ethereal-1.wav",
"sound/weapons/ethereal_draw.wav",
"sound/weapons/ethereal_idle1.wav",
"sound/weapons/ethereal_reload.wav",
"sound/weapons/ethereal_shoot1.wav",
"sound/weapons/exp_nade.wav",
"sound/weapons/famas_clipin.wav",
"sound/weapons/famas_clipout.wav",
"sound/weapons/famas_forearm.wav",
"sound/weapons/fiveseven_clipin.wav",
"sound/weapons/fiveseven_clipout.wav",
"sound/weapons/fiveseven_slidepull.wav",
"sound/weapons/fiveseven_sliderelease.wav",
"sound/weapons/flamegun-1.wav",
"sound/weapons/flamegun_clipin1.wav",
"sound/weapons/flamegun_clipin2.wav",
"sound/weapons/flamegun_clipout1.wav",
"sound/weapons/flamegun_clipout2.wav",
"sound/weapons/flamegun_draw.wav",
"sound/weapons/g36_boltback.wav",
"sound/weapons/g36_boltforward.wav",
"sound/weapons/g36_draw.wav",
"sound/weapons/g36_magin.wav",
"sound/weapons/g36_magout.wav",
"sound/weapons/g3sg1_clipin.wav",
"sound/weapons/g3sg1_clipout.wav",
"sound/weapons/g3sg1_slide.wav",
"sound/weapons/galil_boltpull.wav",
"sound/weapons/galil_clipin.wav",
"sound/weapons/galil_clipout.wav",
"sound/weapons/galil_deploy.wav",
"sound/weapons/gunkata_skill_last.wav",
"sound/weapons/halogun_draw.wav",
"sound/weapons/halogun_reload.wav",
"sound/weapons/holywater_deploy.wav",
"sound/weapons/holywater_explosion.wav",
"sound/weapons/holywater_explosion2.wav",
"sound/weapons/holywater_pinpul.wav",
"sound/weapons/janus7_change1.wav",
"sound/weapons/janus7_change2.wav",
"sound/weapons/janus7_shoot.wav",
"sound/weapons/janus7_shoot2.wav",
"sound/weapons/katanad_draw.wav",
"sound/weapons/katanad_hit1.wav",
"sound/weapons/katanad_hit2.wav",
"sound/weapons/katanad_hitwall.wav",
"sound/weapons/katanad_slash1.wav",
"sound/weapons/katanad_slash2.wav",
"sound/weapons/katanad_slash3.wav",
"sound/weapons/katanad_stab.wav",
"sound/weapons/katanad_stab_miss.wav",
"sound/weapons/knife_girl_draw.wav",
"sound/weapons/laserfist_B1.wav",
"sound/weapons/laserfist_clipin1.wav",
"sound/weapons/laserfist_clipin2.wav",
"sound/weapons/laserfist_clipout.wav",
"sound/weapons/laserfist_draw1.wav",
"sound/weapons/laserfist_idle.wav",
"sound/weapons/laserfist_shootA_empty_end.wav",
"sound/weapons/laserfist_shootA_empty_loop.wav",
"sound/weapons/laserfist_shootB_loop.wav",
"sound/weapons/laserfist_shootB_ready.wav",
"sound/weapons/m134-1.wav",
"sound/weapons/m134-2.wav",
"sound/weapons/m134_boxin.wav",
"sound/weapons/m134_boxout.wav",
"sound/weapons/m134_chain.wav",
"sound/weapons/m134_clipoff.wav",
"sound/weapons/m134_clipon.wav",
"sound/weapons/m134_coverdown.wav",
"sound/weapons/m134_coverup.wav",
"sound/weapons/m134_pinpull.wav",
"sound/weapons/m134_shoot1.wav",
"sound/weapons/m134_spindown.wav",
"sound/weapons/m134_spinup.wav",
"sound/weapons/m134_upsinnn.wav",
"sound/weapons/m249_boxin.wav",
"sound/weapons/m249_boxout.wav",
"sound/weapons/m249_chain.wav",
"sound/weapons/m249_coverdown.wav",
"sound/weapons/m249_coverup.wav",
"sound/weapons/m3_insertshell.wav",
"sound/weapons/m3_pump.wav",
"sound/weapons/m4a1_boltpull.wav",
"sound/weapons/m4a1_clipin.wav",
"sound/weapons/m4a1_clipout.wav",
"sound/weapons/m4a1_deploy.wav",
"sound/weapons/m4a1_silencer_off.wav",
"sound/weapons/m4a1_silencer_on.wav",
"sound/weapons/m4a1buff_clipin1.wav",
"sound/weapons/m4a1buff_clipin2.wav",
"sound/weapons/m4a1buff_clipout.wav",
"sound/weapons/m4a1buff_idle.wav",
"sound/weapons/mac10_boltpull.wav",
"sound/weapons/mac10_clipin.wav",
"sound/weapons/mac10_clipout.wav",
"sound/weapons/mg3_clipin.wav",
"sound/weapons/mg3_clipout.wav",
"sound/weapons/mg3_close.wav",
"sound/weapons/mg3_open.wav",
"sound/weapons/movement1.wav",
"sound/weapons/movement2.wav",
"sound/weapons/movement3.wav",
"sound/weapons/mp5_clipin.wav",
"sound/weapons/mp5_clipout.wav",
"sound/weapons/mp5_slideback.wav",
"sound/weapons/null.wav",
"sound/weapons/p228_clipin.wav",
"sound/weapons/p228_clipout.wav",
"sound/weapons/p228_slidepull.wav",
"sound/weapons/p228_sliderelease.wav",
"sound/weapons/p345/p345_magin.wav",
"sound/weapons/p345/p345_magout.wav",
"sound/weapons/p345/p345_magplace.wav",
"sound/weapons/p345/p345_slide.wav",
"sound/weapons/p90_boltpull.wav",
"sound/weapons/p90_clipin.wav",
"sound/weapons/p90_clipout.wav",
"sound/weapons/p90_cliprelease.wav",
"sound/weapons/pinpull.wav",
"sound/weapons/plasmagun-1.wav",
"sound/weapons/plasmagun_clipin1.wav",
"sound/weapons/plasmagun_clipin2.wav",
"sound/weapons/plasmagun_clipout.wav",
"sound/weapons/plasmagun_draw.wav",
"sound/weapons/plasmagun_exp.wav",
"sound/weapons/plasmagun_idle.wav",
"sound/weapons/revivegun_clipin1.wav",
"sound/weapons/revivegun_clipoutA_1.wav",
"sound/weapons/revivegun_draw.wav",
"sound/weapons/saw_reload.wav",
"sound/weapons/saw_reload2.wav",
"sound/weapons/scout_bolt.wav",
"sound/weapons/scout_clipin.wav",
"sound/weapons/scout_clipout.wav",
"sound/weapons/sfsniper-1.wav",
"sound/weapons/sfsniper_draw.wav",
"sound/weapons/sfsniper_idle.wav",
"sound/weapons/sfsniper_insight1.wav",
"sound/weapons/sfsniper_zoom.wav",
"sound/weapons/sfsword_draw.wav",
"sound/weapons/sfsword_hit1.wav",
"sound/weapons/sfsword_hit2.wav",
"sound/weapons/sfsword_idle.wav",
"sound/weapons/sfsword_midslash1.wav",
"sound/weapons/sfsword_midslash2.wav",
"sound/weapons/sfsword_midslash3.wav",
"sound/weapons/sfsword_off.wav",
"sound/weapons/sfsword_off_hit.wav",
"sound/weapons/sfsword_off_slash1.wav",
"sound/weapons/sfsword_on.wav",
"sound/weapons/sfsword_stab.wav",
"sound/weapons/sfsword_wall1.wav",
"sound/weapons/sfsword_wall2.wav",
"sound/weapons/sg550_boltpull.wav",
"sound/weapons/sg550_clipin.wav",
"sound/weapons/sg550_clipout.wav",
"sound/weapons/sg552_boltpull.wav",
"sound/weapons/sg552_clipin.wav",
"sound/weapons/sg552_clipout.wav",
"sound/weapons/sgdrill_clipin.wav",
"sound/weapons/sgdrill_clipout.wav",
"sound/weapons/sgdrill_draw.wav",
"sound/weapons/sgdrill_idle.wav",
"sound/weapons/slideback1.wav",
"sound/weapons/sliderelease1.wav",
"sound/weapons/sniper_boltback.wav",
"sound/weapons/sniper_boltdown.wav",
"sound/weapons/sniper_boltforward.wav",
"sound/weapons/sniper_boltup.wav",
"sound/weapons/sniper_deploy.wav",
"sound/weapons/sniper_magin.wav",
"sound/weapons/sniper_magout.wav",
"sound/weapons/sniper_slidestop.wav",
"sound/weapons/tomahawk_draw.wav",
"sound/weapons/tomahawk_slash1.wav",
"sound/weapons/tomahawk_slash1_hit.wav",
"sound/weapons/tomahawk_slash2.wav",
"sound/weapons/tomahawk_slash2_hit.wav",
"sound/weapons/tomahawk_stab_hit.wav",
"sound/weapons/tomahawk_stab_miss.wav",
"sound/weapons/tomahawk_wall.wav",
"sound/weapons/ump45_boltslap.wav",
"sound/weapons/ump45_clipin.wav",
"sound/weapons/ump45_clipout.wav",
"sound/weapons/usp_clipin.wav",
"sound/weapons/usp_clipout.wav",
"sound/weapons/usp_silencer_off.wav",
"sound/weapons/usp_silencer_on.wav",
"sound/weapons/usp_slideback.wav",
"sound/weapons/usp_sliderelease.wav",
"sound/weapons/voidpistol_blackhole_C_idle.wav",
"sound/weapons/voidpistol_blackhole_C_idle2.wav",
"sound/weapons/voidpistol_changeAC.wav",
"sound/weapons/voidpistol_drawA.wav",
"sound/weapons/voidpistol_drawc.wav",
"sound/weapons/voidpistol_reloadA_1.wav",
"sound/weapons/voidpistol_reloadA_2.wav",
"sound/weapons/voidpistol_reloadC_2.wav",
"sound/weapons/voidpistol_shoot_blackhole.wav",
"sound/weapons/wondercannon_clipin1.wav",
"sound/weapons/wondercannon_clipout1.wav",
"sound/weapons/wondercannon_draw.wav",
"sound/weapons/wrench_deploy.wav",
"sound/weapons/wrench_hit.wav",
"sound/weapons/wrench_hitwall.wav",
"sound/weapons/wrench_slash.wav",
"sound/weapons/wrench_stab.wav",
"sound/zombie_plague/ambience.wav",
"sound/zombie_plague/grenade_explode.wav",
"sound/zombie_plague/grenade_infect.wav",
"sound/zombie_plague/nemesis1.wav",
"sound/zombie_plague/nemesis2.wav",
"sound/zombie_plague/nemesis_pain1.wav",
"sound/zombie_plague/nemesis_pain2.wav",
"sound/zombie_plague/nemesis_pain3.wav",
"sound/zombie_plague/survivor1.wav",
"sound/zombie_plague/survivor2.wav",
"sound/zombie_plague/thunder1.wav",
"sound/zombie_plague/thunder2.wav",
"sound/zombie_plague/win_humans1.wav",
"sound/zombie_plague/win_humans2.wav",
"sound/zombie_plague/zombie_brains1.wav",
"sound/zombie_plague/zombie_brains2.wav",
"sound/zombie_plague/zombie_burn3.wav",
"sound/zombie_plague/zombie_burn4.wav",
"sound/zombie_plague/zombie_burn5.wav",
"sound/zombie_plague/zombie_burn6.wav",
"sound/zombie_plague/zombie_burn7.wav",
"sound/zombie_plague/zombie_die1.wav",
"sound/zombie_plague/zombie_die2.wav",
"sound/zombie_plague/zombie_die3.wav",
"sound/zombie_plague/zombie_die4.wav",
"sound/zombie_plague/zombie_die5.wav",
"sound/zombie_plague/zombie_fall1.wav",
"sound/zombie_plague/zombie_infec1.wav",
"sound/zombie_plague/zombie_infec2.wav",
"sound/zombie_plague/zombie_infec3.wav",
"sound/zombie_plague/zombie_madness1.wav",
"sound/zombie_plague/zombie_pain1.wav",
"sound/zombie_plague/zombie_pain2.wav",
"sound/zombie_plague/zombie_pain3.wav",
"sound/zombie_plague/zombie_pain4.wav",
"sound/zombie_plague/zombie_pain5.wav",
"sprites/640hud26_2.spr",
"sprites/640hud35_2.spr",
"sprites/flame_puff01.spr",
"sprites/vex_community/bow/640hud12_2.spr",
"sprites/vex_community/bow/640hud98_2.spr",
"sprites/vex_community/ethereal/640hud74_2.spr",
"sprites/vex_community/ethereal/640hud7_2.spr",
"sprites/vex_community/ethereal/muzzleflash7.spr",
"sprites/vex_community/janus7/640hud12_2.spr",
"sprites/vex_community/janus7/640hud7_2.spr",
"sprites/vex_community/janus7/640hud99_2.spr",
"sprites/vex_community/plasma/640hud3_2.spr",
"sprites/vex_community/plasma/640hud91_2.spr",
"sprites/vex_community/plasma/muzzleflash27.spr",
"sprites/vex_community/plasma/plasmaball.spr",
"sprites/vex_community/plasma/plasmabomb.spr",
"sprites/vex_community/salamander/640hud59_2.spr",
"sprites/vex_community/salamander/640hud60_2.spr",
"sprites/vex_community/salamander/640hud7_2.spr",
"sprites/vex_community/salamander/flame_burn01.spr",
"sprites/vex_community/salamander/flame_puff01.spr",
"sprites/vex_community/thunderbolt/640hud10_2.spr",
"sprites/vex_community/thunderbolt/640hud2_2.spr",
"sprites/vex_community/thunderbolt/640hud81_2.spr",
"sprites/vexmira/arena48/boss0_cast.spr",
"sprites/vexmira/arena48/boss1_cast.spr",
"sprites/vexmira/arena48/boss2_cast.spr",
"sprites/vexmira/arena48/boss3_cast.spr",
"sprites/vexmira/arena48/boss4_cast.spr",
"sprites/vexmira/arena48/boss5_cast.spr",
"sprites/vexmira/arena48/boss6_cast.spr",
"sprites/vexmira/arena48/boss7_cast.spr",
"sprites/vexmira/arena48/boss8_cast.spr",
"sprites/vexmira/arena48/icon_admin.spr",
"sprites/vexmira/arena48/icon_alpha.spr",
"sprites/vexmira/arena48/icon_boss.spr",
"sprites/vexmira/arena48/icon_last.spr",
"sprites/vexmira/arena48/icon_mvp.spr",
"sprites/vexmira/arena48/icon_vip.spr",
"sprites/vexmira/arena49/bossbar.spr",
"sprites/vexmira/arena49/zombiebar.spr",
"sprites/vexmira/arena50/blood.spr",
"sprites/vexmira/arena50/bloodspray.spr",
"sprites/vexmira/arena50/explosion.spr",
"sprites/vexmira/arena50/flare.spr",
"sprites/vexmira/arena50/flareburst.spr",
"sprites/vexmira_ze/arena51/vexmira_gren_ice.spr",
"sprites/vexmira/arena50/orb.spr",
"sprites/vexmira/arena50/smoke.spr",
"sprites/vexmira/arena51/base_beam.spr",
"sprites/vexmira/arena51/base_lightning.spr",
"sprites/vexmira/arena51/base_ring.spr",
"sprites/vexmira/arena51/gren_fire.spr",
"sprites/vexmira/arena51/gren_flare.spr",
"sprites/vexmira_ze/arena51/vexmira_gren_ice.spr",
"sprites/vexmira/arena51/laserbeam.spr",
"sprites/vexmira/arena51/laserhit.spr",
"sprites/vexmira/arena51/skill0.spr",
"sprites/vexmira/arena51/skill1.spr",
"sprites/vexmira/arena51/skill2.spr",
"sprites/vexmira/arena51/skill3.spr",
"sprites/vexmira/arena51/skill4.spr",
"sprites/vexmira/arena51/skill5.spr",
"sprites/vexmira/arena51/skill6.spr",
"sprites/vexmira/arena51/skill7.spr",
"sprites/vexmira/arena52/hud/a00.spr",
"sprites/vexmira/arena52/hud/a01.spr",
"sprites/vexmira/arena52/hud/a02.spr",
"sprites/vexmira/arena52/hud/a03.spr",
"sprites/vexmira/arena52/hud/a04.spr",
"sprites/vexmira/arena52/hud/a05.spr",
"sprites/vexmira/arena52/hud/a06.spr",
"sprites/vexmira/arena52/hud/a07.spr",
"sprites/vexmira/arena52/hud/a08.spr",
"sprites/vexmira/arena52/hud/a09.spr",
"sprites/vexmira/arena52/hud/a10.spr",
"sprites/vexmira/arena52/hud/a11.spr",
"sprites/vexmira/arena52/hud/a12.spr",
"sprites/vexmira/arena52/hud/a13.spr",
"sprites/vexmira/arena52/hud/a14.spr",
"sprites/vexmira/arena52/hud/a15.spr",
"sprites/vexmira/arena52/hud/a16.spr",
"sprites/vexmira/arena52/hud/a17.spr",
"sprites/vexmira/arena52/hud/a18.spr",
"sprites/vexmira/arena52/hud/a19.spr",
"sprites/vexmira/arena52/hud/a20.spr",
"sprites/vexmira/arena52/hud/a21.spr",
"sprites/vexmira/arena52/hud/a22.spr",
"sprites/vexmira/arena52/hud/a23.spr",
"sprites/vexmira/arena52/hud/a24.spr",
"sprites/vexmira/arena52/hud/a25.spr",
"sprites/vexmira/arena52/hud/a26.spr",
"sprites/vexmira/arena52/hud/a27.spr",
"sprites/vexmira/arena52/hud/a28.spr",
"sprites/vexmira/arena52/hud/a29.spr",
"sprites/vexmira/arena52/hud/a30.spr",
"sprites/vexmira/arena52/hud/a31.spr",
"sprites/vexmira/arena52/hud/n000.txt",
"sprites/vexmira/arena52/hud/n001.txt",
"sprites/vexmira/arena52/hud/n010.txt",
"sprites/vexmira/arena52/hud/n011.txt",
"sprites/vexmira/arena52/hud/n020.txt",
"sprites/vexmira/arena52/hud/n021.txt",
"sprites/vexmira/arena52/hud/n030.txt",
"sprites/vexmira/arena52/hud/n031.txt",
"sprites/vexmira/arena52/hud/n040.txt",
"sprites/vexmira/arena52/hud/n041.txt",
"sprites/vexmira/arena52/hud/n050.txt",
"sprites/vexmira/arena52/hud/n051.txt",
"sprites/vexmira/arena52/hud/n060.txt",
"sprites/vexmira/arena52/hud/n061.txt",
"sprites/vexmira/arena52/hud/n070.txt",
"sprites/vexmira/arena52/hud/n071.txt",
"sprites/vexmira/arena52/hud/n080.txt",
"sprites/vexmira/arena52/hud/n081.txt",
"sprites/vexmira/arena52/hud/n090.txt",
"sprites/vexmira/arena52/hud/n091.txt",
"sprites/vexmira/arena52/hud/n100.txt",
"sprites/vexmira/arena52/hud/n101.txt",
"sprites/vexmira/arena52/hud/n110.txt",
"sprites/vexmira/arena52/hud/n111.txt",
"sprites/vexmira/arena52/hud/n120.txt",
"sprites/vexmira/arena52/hud/n121.txt",
"sprites/vexmira/arena52/hud/n130.txt",
"sprites/vexmira/arena52/hud/n131.txt",
"sprites/vexmira/arena52/hud/n140.txt",
"sprites/vexmira/arena52/hud/n141.txt",
"sprites/vexmira/arena52/hud/n150.txt",
"sprites/vexmira/arena52/hud/n151.txt",
"sprites/vexmira/arena52/hud/n160.txt",
"sprites/vexmira/arena52/hud/n161.txt",
"sprites/vexmira/arena52/hud/n170.txt",
"sprites/vexmira/arena52/hud/n171.txt",
"sprites/vexmira/arena52/hud/n180.txt",
"sprites/vexmira/arena52/hud/n181.txt",
"sprites/vexmira/arena52/hud/n190.txt",
"sprites/vexmira/arena52/hud/n191.txt",
"sprites/vexmira/arena52/hud/n200.txt",
"sprites/vexmira/arena52/hud/n201.txt",
"sprites/vexmira/arena52/hud/n210.txt",
"sprites/vexmira/arena52/hud/n211.txt",
"sprites/vexmira/arena52/hud/n220.txt",
"sprites/vexmira/arena52/hud/n221.txt",
"sprites/vexmira/arena52/hud/n230.txt",
"sprites/vexmira/arena52/hud/n231.txt",
"sprites/vexmira/arena52/hud/n240.txt",
"sprites/vexmira/arena52/hud/n241.txt",
"sprites/vexmira/arena52/hud/n250.txt",
"sprites/vexmira/arena52/hud/n251.txt",
"sprites/vexmira/arena52/hud/n260.txt",
"sprites/vexmira/arena52/hud/n261.txt",
"sprites/vexmira/arena52/hud/n270.txt",
"sprites/vexmira/arena52/hud/n271.txt",
"sprites/vexmira/arena52/hud/n280.txt",
"sprites/vexmira/arena52/hud/n281.txt",
"sprites/vexmira/arena52/hud/n290.txt",
"sprites/vexmira/arena52/hud/n291.txt",
"sprites/vexmira/arena52/hud/n300.txt",
"sprites/vexmira/arena52/hud/n301.txt",
"sprites/vexmira/arena52/hud/n310.txt",
"sprites/vexmira/arena52/hud/n311.txt",
"sprites/vexmira/arena52/hud/n320.txt",
"sprites/vexmira/arena52/hud/n321.txt",
"sprites/vexmira/arena52/hud/n330.txt",
"sprites/vexmira/arena52/hud/n331.txt",
"sprites/vexmira/arena52/hud/n340.txt",
"sprites/vexmira/arena52/hud/n341.txt",
"sprites/vexmira/arena52/hud/n350.txt",
"sprites/vexmira/arena52/hud/n351.txt",
"sprites/vexmira/arena52/hud/n360.txt",
"sprites/vexmira/arena52/hud/n361.txt",
"sprites/vexmira/arena52/hud/n370.txt",
"sprites/vexmira/arena52/hud/n371.txt",
"sprites/vexmira/arena52/hud/n380.txt",
"sprites/vexmira/arena52/hud/n381.txt",
"sprites/vexmira/arena52/hud/n390.txt",
"sprites/vexmira/arena52/hud/n391.txt",
"sprites/vexmira/arena52/hud/n400.txt",
"sprites/vexmira/arena52/hud/n401.txt",
"sprites/vexmira/arena52/hud/n410.txt",
"sprites/vexmira/arena52/hud/n411.txt",
"sprites/vexmira/arena52/hud/n420.txt",
"sprites/vexmira/arena52/hud/n421.txt",
"sprites/vexmira/arena52/hud/n430.txt",
"sprites/vexmira/arena52/hud/n431.txt",
"sprites/vexmira/arena52/hud/n440.txt",
"sprites/vexmira/arena52/hud/n441.txt",
"sprites/vexmira/arena52/hud/n450.txt",
"sprites/vexmira/arena52/hud/n451.txt",
"sprites/vexmira/arena52/hud/n460.txt",
"sprites/vexmira/arena52/hud/n461.txt",
"sprites/vexmira/arena52/hud/n470.txt",
"sprites/vexmira/arena52/hud/n471.txt",
"sprites/vexmira/arena52/hud/n480.txt",
"sprites/vexmira/arena52/hud/n481.txt",
"sprites/vexmira/arena52/hud/n490.txt",
"sprites/vexmira/arena52/hud/n491.txt",
"sprites/vexmira/arena52/hud/n500.txt",
"sprites/vexmira/arena52/hud/n501.txt",
"sprites/vexmira/arena52/hud/n510.txt",
"sprites/vexmira/arena52/hud/n511.txt",
"sprites/vexmira/arena52/hud/n520.txt",
"sprites/vexmira/arena52/hud/n521.txt",
"sprites/vexmira/arena52/hud/n530.txt",
"sprites/vexmira/arena52/hud/n531.txt",
"sprites/vexmira/arena52/hud/n540.txt",
"sprites/vexmira/arena52/hud/n541.txt",
"sprites/vexmira/arena52/hud/n550.txt",
"sprites/vexmira/arena52/hud/n551.txt",
"sprites/vexmira/arena52/hud/n560.txt",
"sprites/vexmira/arena52/hud/n561.txt",
"sprites/vexmira/arena52/hud/n570.txt",
"sprites/vexmira/arena52/hud/n571.txt",
"sprites/vexmira/arena52/hud/n580.txt",
"sprites/vexmira/arena52/hud/n581.txt",
"sprites/vexmira/arena52/hud/n590.txt",
"sprites/vexmira/arena52/hud/n591.txt",
"sprites/vexmira/arena52/hud/n600.txt",
"sprites/vexmira/arena52/hud/n601.txt",
"sprites/vexmira/arena52/hud/n610.txt",
"sprites/vexmira/arena52/hud/n611.txt",
"sprites/vexmira/arena52/hud/n620.txt",
"sprites/vexmira/arena52/hud/n621.txt",
"sprites/vexmira/arena52/hud/n630.txt",
"sprites/vexmira/arena52/hud/n631.txt",
"sprites/vexmira/arena52/notifications.spr",
"sprites/vexmira/brand/beacon.spr",
"sprites/vexmira/brand/bossbar.spr",
"sprites/vexmira/brand/bossicon.spr",
"sprites/vexmira/brand/chain.spr",
"sprites/vexmira/brand/fire.spr",
"sprites/vexmira/brand/hit.spr",
"sprites/vexmira/brand/hpbar.spr",
"sprites/vexmira_ze/arena51/vexmira_gren_ice.spr",
"sprites/vexmira/brand/icon_admin.spr",
"sprites/vexmira/brand/icon_alpha.spr",
"sprites/vexmira/brand/icon_last.spr",
"sprites/vexmira/brand/icon_mvp.spr",
"sprites/vexmira/brand/icon_vip.spr",
"sprites/vexmira_ze/arena51/vexmira_base_beam.spr",
"sprites/vexmira/brand/mark.spr",
"sprites/vexmira/brand/orb.spr",
"sprites/vexmira/brand/pulse.spr",
"sprites/vexmira/brand/slash.spr",
"sprites/vexmira/brand/target.spr",
"sprites/vexmira/brand/toxic.spr",
"sprites/vexmira/brand/void.spr",
"sprites/vexmira_ze/arena51/vexmira_base_ring.spr",
"sprites/vexmira/community/ui/bossbar.spr",
"sprites/vexmira/community/ui/bossicon.spr",
"sprites/vexmira/community/ui/hpbar_small.spr",
"sprites/vexmira/community/ui/icon_admin.spr",
"sprites/vexmira/community/ui/icon_alpha.spr",
"sprites/vexmira/community/ui/icon_lasthuman.spr",
"sprites/vexmira/community/ui/icon_mvp.spr",
"sprites/vexmira/community/ui/icon_vip.spr",
"sprites/vexmira/epic/boss0_bar.spr",
"sprites/vexmira/epic/boss0_cast.spr",
"sprites/vexmira/epic/boss1_bar.spr",
"sprites/vexmira/epic/boss1_cast.spr",
"sprites/vexmira/epic/boss2_bar.spr",
"sprites/vexmira/epic/boss2_cast.spr",
"sprites/vexmira/epic/boss3_bar.spr",
"sprites/vexmira/epic/boss3_cast.spr",
"sprites/vexmira/epic/boss4_bar.spr",
"sprites/vexmira/epic/boss4_cast.spr",
"sprites/vexmira/epic/boss5_bar.spr",
"sprites/vexmira/epic/boss5_cast.spr",
"sprites/vexmira/epic/boss6_bar.spr",
"sprites/vexmira/epic/boss6_cast.spr",
"sprites/vexmira/epic/boss7_bar.spr",
"sprites/vexmira/epic/boss7_cast.spr",
"sprites/vexmira/epic/boss8_bar.spr",
"sprites/vexmira/epic/boss8_cast.spr",
"sprites/vexmira/epic/death47.spr",
"sprites/vexmira/epic/fire.spr",
"sprites/vexmira/epic/fire47.spr",
"sprites/vexmira/epic/flare.spr",
"sprites/vexmira/epic/flare47.spr",
"sprites/vexmira/epic/humanbar.spr",
"sprites/vexmira/epic/ice.spr",
"sprites/vexmira/epic/ice47.spr",
"sprites/vexmira/epic/intro47.spr",
"sprites/vexmira/epic/jet_blast.spr",
"sprites/vexmira/epic/jet_blast47.spr",
"sprites/vexmira/epic/jet_flame.spr",
"sprites/vexmira/epic/jet_ring.spr",
"sprites/vexmira/epic/jet_smoke.spr",
"sprites/vexmira/epic/victory_ct47.spr",
"sprites/vexmira/epic/victory_t47.spr",
"sprites/vexmira/epic/zombiebar.spr",
"sprites/weapon_bow.txt",
"sprites/weapon_ethereal.txt",
"sprites/weapon_flamethrower.txt",
"sprites/weapon_janus7.txt",
"sprites/weapon_m134.txt",
"sprites/weapon_plasmagun.txt",
"sprites/weapon_sfsniperF.txt"
};
new const diag_ASSET_BYTES[] = {
31372,
33228,
696856,
1120424,
704900,
219056,
482968,
793316,
501104,
552520,
581160,
691600,
486552,
277576,
915312,
960416,
1104064,
472112,
332420,
834368,
273332,
299336,
87956,
87132,
98172,
114968,
10960,
83052,
89936,
283588,
91544,
103264,
88536,
92288,
78544,
88268,
870328,
844944,
690668,
1097760,
576732,
2153696,
209552,
2032624,
1789464,
576732,
1127540,
2153696,
844944,
837856,
1097760,
870328,
690668,
986592,
2197628,
2462152,
1291204,
794172,
1593116,
2044616,
837856,
986592,
1731588,
2695776,
1486936,
870328,
870328,
2197628,
2179564,
1444528,
1127540,
12036,
21844,
997552,
1367608,
806256,
167640,
606472,
1489620,
956760,
1215948,
1113852,
672032,
1098792,
996456,
530036,
530036,
1128944,
1128736,
80036,
80232,
80568,
88072,
991404,
857024,
944828,
1201824,
475560,
1368336,
96992,
88460,
2804388,
85872,
101444,
1355928,
95976,
186708,
1566360,
139496,
105704,
1049772,
104052,
279912,
1027784,
156628,
120552,
2899880,
114568,
1106604,
110296,
79316,
83958,
302352,
79316,
355224,
567616,
31528,
298772,
270520,
79316,
79572,
210960,
426944,
39204,
312552,
672472,
150412,
287236,
2044616,
70024,
74500,
332252,
106912,
27252,
79316,
477604,
411596,
623380,
404752,
411608,
453392,
408460,
412892,
392200,
410560,
485068,
418464,
392276,
486240,
613344,
404240,
542084,
413252,
407512,
405484,
419900,
412992,
418520,
418116,
392200,
432256,
478760,
505596,
475660,
1368336,
2804388,
1355928,
1566360,
1049772,
1027784,
2899880,
1106604,
477604,
411596,
623380,
404752,
411608,
453392,
408460,
412892,
410560,
485068,
418464,
486240,
613344,
404240,
542084,
413252,
407512,
405484,
419900,
412992,
418520,
418116,
432256,
478760,
505596,
475660,
277636,
277636,
277636,
418172,
418172,
418172,
276000,
276000,
276000,
477604,
411596,
623380,
404752,
411608,
453392,
408460,
412892,
410560,
485068,
418464,
486240,
613344,
404240,
542084,
413252,
407512,
405484,
419900,
412992,
418520,
418116,
432256,
478760,
505596,
475660,
418248,
418248,
418248,
355348,
270644,
79696,
211084,
427068,
39328,
107036,
27376,
546576,
552656,
441068,
79316,
79316,
88830,
83958,
83958,
302352,
302352,
303924,
25512,
79316,
88830,
355224,
355224,
356832,
567616,
567616,
569068,
31528,
31528,
298772,
298772,
300440,
270520,
270520,
272248,
79316,
79316,
88830,
79572,
79572,
81288,
210960,
210960,
212688,
426944,
426944,
428480,
39204,
39204,
40932,
312552,
312552,
313976,
672472,
672472,
150412,
150412,
287236,
287236,
2044616,
1291204,
794172,
70024,
70024,
74500,
74500,
332252,
332252,
106912,
106912,
108464,
27252,
27252,
28812,
79316,
79316,
88830,
87156,
17060,
268768,
85496,
500296,
701252,
662800,
569412,
342952,
645592,
346560,
422056,
307768,
378292,
339956,
297324,
132108,
335672,
340520,
326980,
98780,
290768,
349328,
314968,
449552,
336240,
398164,
303060,
355988,
630288,
348920,
351832,
107412,
342024,
322140,
332308,
340432,
962728,
722872,
970768,
779984,
1032684,
802404,
846768,
1549640,
877908,
1369936,
1300144,
565204,
340120,
643984,
345128,
423212,
423092,
306300,
395960,
338520,
295708,
130884,
337020,
338948,
325360,
97544,
291072,
347672,
313328,
447948,
329344,
396596,
301456,
354372,
628636,
347268,
350212,
553612,
106216,
340376,
320424,
330732,
339020,
114600,
114600,
261340,
17452,
3122,
697704,
273196,
756792,
1045848,
612512,
1104800,
696920,
272216,
755956,
3122,
3122,
83952,
113304,
9796,
88628,
88852,
101632,
86896,
90488,
554792,
312960,
554792,
351736,
510148,
36108,
36108,
36108,
79076,
73592,
69966,
176268,
139130,
709848,
446746,
86530,
63970,
20022,
21072,
21072,
70638,
70638,
70638,
70638,
70638,
34520,
20854,
88280,
101508,
19924,
75048,
70638,
79458,
88278,
13308,
18222,
42124,
101508,
18222,
42124,
42124,
79318,
42124,
13308,
52998,
42170,
101508,
19924,
75048,
70638,
79458,
88278,
13308,
52998,
55458,
101508,
19924,
75048,
70638,
79458,
88278,
13308,
42236,
96750,
101508,
19924,
75048,
70638,
79458,
88278,
13308,
42236,
42124,
101508,
19924,
42236,
42236,
79318,
42236,
13308,
11326,
30648,
101508,
11326,
30648,
30648,
79458,
30648,
13308,
22128,
97098,
101508,
19924,
75048,
70638,
79458,
88278,
13308,
52998,
42170,
101508,
19924,
75048,
70638,
79458,
88278,
13308,
88278,
42198,
42150,
88278,
88278,
44180,
88278,
42170,
15260,
30648,
88278,
88278,
88278,
88278,
31874,
88278,
88278,
23566,
59912,
107204,
22670,
26338,
39254,
10700,
44198,
26604,
26604,
28988,
39618,
26338,
40994,
39618,
40994,
40994,
39618,
21168,
13650,
78172,
36960,
27906,
49252,
42068,
21168,
15424,
212632,
88278,
88278,
88278,
88278,
23566,
42150,
88278,
88278,
15260,
88278,
480810,
480760,
88278,
34334,
66228,
480488,
480488,
480126,
480601,
480551,
52998,
187854,
42236,
42124,
52998,
52024,
42236,
42124,
52998,
67076,
42236,
42124,
52998,
67808,
42236,
42124,
52998,
44198,
42236,
42124,
52998,
65974,
42236,
42124,
52998,
77148,
42236,
42124,
52998,
63912,
42236,
42124,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
240345,
187854,
187854,
117090,
81476,
52024,
52024,
43412,
16428,
67076,
67076,
114298,
32874,
88556,
67808,
88556,
48392,
91044,
128770,
91044,
100904,
109018,
65974,
50254,
57150,
49694,
77148,
214302,
80608,
41574,
63912,
154138,
70482,
19924,
46384,
45854,
12426,
44620,
43668,
44050,
67514,
19924,
42198,
48588,
12426,
65354,
42150,
44506,
42198,
19924,
46384,
48496,
12426,
66228,
52998,
58280,
63044,
19924,
46062,
48554,
12426,
59912,
52998,
61818,
55458,
19924,
46384,
21628,
12426,
21628,
22480,
61818,
46252,
19904,
46384,
42150,
12426,
42150,
35614,
34926,
65354,
19924,
46384,
48588,
12426,
47550,
29918,
33462,
47196,
19924,
46384,
48588,
12426,
48062,
47174,
17614,
47726,
19924,
23070,
42170,
12426,
42170,
42198,
42236,
21836,
22128,
42236,
42124,
11314,
15794,
42236,
52998,
52998,
52998,
32870,
42150,
13756,
7344,
42198,
42170,
22128,
12366,
42170,
52998,
11326,
52998,
18998,
22128,
28700,
42150,
15794,
26538,
13196,
34364,
28744,
7344,
26538,
15514,
26538,
6694,
8016,
26538,
22128,
19924,
4846,
6252,
17718,
11314,
7344,
42124,
42198,
10500,
68584,
10464,
65354,
15260,
42170,
42236,
34364,
42170,
59912,
10460,
18998,
30648,
42124,
42198,
21628,
7344,
42124,
42170,
59912,
10460,
18998,
30648,
42124,
42198,
21628,
117090,
81476,
31176,
32824,
33194,
41846,
114298,
32874,
482958,
12002,
17862,
48392,
100904,
15162,
9564,
19882,
53070,
57318,
56878,
57150,
50254,
44214,
26166,
50154,
42578,
60734,
49282,
46558,
13316,
121128,
58114,
80608,
91338,
52776,
49694,
56916,
57758,
56916,
57758,
27980,
26110,
41574,
12426,
9564,
12426,
12426,
12426,
9564,
12426,
12426,
12426,
12426,
12426,
12426,
9564,
12426,
12426,
9564,
12426,
56916,
56916,
57758,
26110,
57758,
12426,
12426,
9564,
12426,
12426,
9564,
12426,
12426,
12426,
12426,
9564,
12426,
9564,
12426,
12426,
9564,
12426,
12426,
11142,
12426,
12426,
12426,
12426,
12426,
12426,
9564,
12426,
12426,
9564,
12426,
12426,
12426,
12426,
12426,
9564,
12426,
12426,
12426,
9564,
12426,
12426,
9564,
12426,
12426,
12426,
12426,
12426,
9564,
12426,
12426,
12426,
9564,
12426,
9564,
12426,
12426,
9564,
12426,
12426,
9564,
12426,
12426,
9564,
12426,
12426,
9564,
12426,
12426,
12426,
12426,
12426,
12426,
12426,
8898,
42198,
13196,
42170,
10464,
13308,
57408,
59912,
10588,
106006,
18998,
32870,
101508,
105918,
15260,
105918,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
661578,
33154,
32510,
32520,
33154,
33154,
8016,
33154,
13308,
28744,
28744,
19924,
28744,
28744,
28744,
28744,
19924,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
19924,
28744,
28744,
28744,
28744,
28744,
19924,
28744,
28744,
28744,
28744,
28744,
28744,
19924,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
19924,
19924,
28744,
28744,
28744,
28744,
28744,
19924,
28744,
28744,
28744,
28744,
28744,
19924,
28744,
28744,
28744,
28744,
28744,
19924,
28744,
28744,
28744,
28744,
28744,
28744,
19924,
19924,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
28744,
19924,
28744,
28744,
28744,
28744,
28744,
28744,
19924,
19924,
28744,
28744,
28744,
19924,
190590,
134142,
148254,
144726,
176478,
148254,
197646,
148254,
215286,
155310,
180006,
141198,
239982,
148254,
102390,
208230,
201174,
169422,
243510,
197646,
299958,
155310,
155310,
141198,
148254,
26604,
26604,
26604,
26604,
26650,
16544,
70638,
60934,
70638,
42434,
60934,
70638,
70638,
18950,
70638,
70638,
63506,
39886,
70638,
63506,
49046,
31696,
63506,
49046,
68014,
29644,
49046,
68014,
70638,
36648,
68014,
70638,
60934,
19706,
70638,
60934,
70638,
18482,
60934,
70638,
70638,
40414,
40642,
40272,
40282,
40744,
40186,
40304,
40680,
40336,
39802,
47226,
141422,
42236,
256956,
256740,
256740,
256906,
256883,
256461,
256881,
256461,
256903,
79458,
75048,
42124,
75048,
75048,
75048,
42236,
30648,
141286,
36108,
21072,
85384,
43854,
87110,
44178,
79458,
55488,
132378,
87378,
25936,
11426,
5604,
11708,
28020,
14788,
9576,
14788,
13362,
6458,
14788,
25936,
25936,
11426,
13308,
50154,
26166,
13308,
13308,
50154,
26166,
13308,
50154,
26166,
13308,
20022,
13308,
12774,
29250,
53476,
8272,
12698,
20506,
22950,
50154,
121818,
7170,
8436,
24318,
21364,
41590,
39886,
51940,
33594,
69564,
34962,
43756,
43756,
43756,
43756,
43756,
43756,
43756,
43756,
43756,
43756,
28118,
49220,
42076,
66194,
66194,
66194,
66194,
79036,
23468,
24876,
34604,
50154,
26166,
20022,
53466,
23138,
35790,
188032,
33050,
26258,
33050,
54996,
28426,
26166,
20022,
50154,
50154,
50154,
13308,
50154,
42888,
27414,
441122,
91488,
42888,
213730,
50154,
26166,
13308,
50154,
26166,
13308,
13308,
44304,
19496,
47634,
32406,
33638,
44742,
16644,
16646,
45236,
18458,
16642,
50154,
26166,
13308,
13308,
50154,
26166,
20022,
41574,
81476,
117090,
31228,
98152,
116358,
17570,
47226,
26152,
39822,
152514,
55546,
26308,
33646,
37210,
12092,
25066,
23598,
33666,
13544,
60734,
50254,
50154,
42578,
26166,
60734,
53070,
56878,
57318,
44214,
57150,
51748,
50524,
55576,
85804,
45822,
30182,
32816,
12102,
16302,
29748,
51748,
73690,
102304,
71502,
50154,
26166,
50154,
50154,
50154,
50154,
13308,
13308,
50154,
26166,
60734,
50154,
50154,
50154,
50154,
26166,
50154,
13308,
50154,
26166,
44968,
17736,
8834,
12670,
20022,
20022,
20022,
50154,
26166,
13308,
20022,
50154,
26166,
13308,
13308,
13362,
6458,
13362,
9576,
13308,
50154,
26166,
50154,
50154,
94258,
30074,
28046,
46788,
54214,
55854,
293910,
114298,
41846,
32874,
13026,
13026,
13308,
50154,
26166,
107478,
39010,
373192,
2912,
21718,
98304,
36824,
32808,
565118,
55468,
66216,
55486,
29072,
29060,
22324,
30376,
70930,
38192,
63040,
13308,
50154,
26166,
13308,
50154,
26166,
50154,
26166,
60734,
50154,
20022,
13308,
14788,
9576,
9576,
14788,
32576,
13362,
6458,
9576,
9774,
15020,
26146,
16862,
23556,
26398,
11672,
22838,
13308,
50154,
26166,
50154,
26166,
50154,
50154,
13308,
13308,
49282,
46558,
80608,
52776,
58114,
13316,
91338,
121128,
49694,
32824,
31176,
33194,
42902,
16154,
21954,
32180,
32434,
775832,
143654,
64080,
73628,
192630,
56992,
53412,
55050,
254024,
155748,
291942,
341094,
271074,
256530,
88278,
110328,
39070,
55514,
70830,
50294,
69742,
63926,
51988,
57432,
32696,
54856,
33766,
76874,
88418,
73266,
252794,
30240,
23736,
41566,
26894,
21086,
66366,
66366,
142050,
66366,
66366,
66366,
66366,
3134,
66366,
66366,
66366,
66366,
66366,
33618,
33618,
590814,
66366,
66366,
66366,
62550,
142050,
66366,
66366,
66366,
410730,
410730,
410730,
410730,
410730,
410730,
410730,
410730,
410730,
56266,
56266,
56266,
56266,
56266,
56266,
1174346,
435530,
17514,
17514,
66666,
17514,
66666,
66666,
17514,
17514,
1854,
4986,
1854,
99594,
99594,
99594,
1311930,
1967490,
83130,
83130,
83130,
83130,
83130,
83130,
83130,
83130,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
262974,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
100,
104,
104,
104,
12587562,
74698,
524070,
68382,
1854,
74698,
74698,
165030,
74698,
6462,
6462,
6462,
6462,
6462,
1854,
74698,
74698,
1854,
74698,
74698,
74698,
74698,
74698,
60582,
1470,
60582,
1470,
1470,
1470,
1470,
1470,
294194,
132042,
294194,
132042,
294194,
132042,
294194,
132042,
294194,
132042,
294194,
132042,
294194,
132042,
294194,
132042,
294194,
132042,
1049706,
93170,
738490,
93170,
738490,
402250,
93170,
738490,
1049706,
93170,
738490,
93170,
1854,
93170,
1049706,
1049706,
402250,
163,
174,
188,
227,
108,
173,
187
};
public diag_plugin_init()
{
register_concmd("vex_diagnose", "diag_DiagnosticCommand", ADMIN_RCON);
set_task(2.0, "diag_StartupDiagnostic", ZC_TOFF_DIAG);
}
public diag_StartupDiagnostic() { diag_Diagnose(); }
public diag_DiagnosticCommand(id)
{
if(id && !(get_user_flags(id)&ADMIN_RCON)) return PLUGIN_HANDLED;
diag_Diagnose();
return PLUGIN_HANDLED;
}
stock diag_Report(const format[], any:...)
{
new text[512]; vformat(text,charsmax(text),format,2);
server_print("[VexDiag] %s",text);
log_to_file("vex_diagnostic.log","%s",text);
}
stock diag_Diagnose()
{
new version[64], map[64]; get_amxx_verstring(version,charsmax(version)); get_mapname(map,charsmax(map));
diag_Report("BEGIN AMXX=%s MAP=%s",version,map);
if(contain(version,"1.8.")==0 || contain(version,"1.9.")==0)
diag_Report("VERSION: Full Community mod targets AMXX 1.10. This diagnostic itself supports 1.8.2.");
new name[128], author[64], diag_module_version[64], status;
for(new i;i<get_modulesnum();i++)
{
get_module(i,name,charsmax(name),author,charsmax(author),diag_module_version,charsmax(diag_module_version),status);
diag_Report("MODULE name=%s version=%s status=%d",name,diag_module_version,status);
}
new filename[128], diag_plugin_version[64], diag_plugin_status[32], path[192], data, header[4];
for(new i;i<get_pluginsnum();i++)
{
get_plugin(i,filename,charsmax(filename),name,charsmax(name),diag_plugin_version,charsmax(diag_plugin_version),author,charsmax(author),diag_plugin_status,charsmax(diag_plugin_status));
if(containi(filename,"vex")==-1 && containi(name,"Vexmira")==-1 && i!=get_plugin(-1)) continue;
formatex(path,charsmax(path),"addons/amxmodx/plugins/%s",filename);
new fp=fopen(path,"rb");
if(fp)
{
for(new j;j<4;j++) { data=0; fread(fp,data,BLOCK_BYTE); header[j]=data&255; }
fclose(fp);
diag_Report("PLUGIN file=%s status=%s bytes=%d header=%02X %02X %02X %02X",filename,diag_plugin_status,file_size(path),header[0],header[1],header[2],header[3]);
if(header[0]!=0x58 || header[1]!=0x58 || header[2]!=0x4D || header[3]!=0x41)
diag_Report("BAD HEADER: %s is not a standard compressed AMXX file. Compare the actual uploaded bytes.",filename);
}
else diag_Report("PLUGIN file=%s status=%s FILE_NOT_READABLE",filename,diag_plugin_status);
}
new diag_missing, diag_size_errors;
for(new i;i<sizeof diag_ASSETS;i++)
{
if(!file_exists(diag_ASSETS[i]))
{
diag_missing++;
diag_Report("MISSING %s",diag_ASSETS[i]);
}
else if(file_size(diag_ASSETS[i])!=diag_ASSET_BYTES[i])
{
diag_size_errors++;
diag_Report("SIZE_MISMATCH %s bytes=%d expected=%d",diag_ASSETS[i],file_size(diag_ASSETS[i]),diag_ASSET_BYTES[i]);
}
}
if(!file_exists("addons/amxmodx/configs/vexmira.cfg")) diag_Report("MISSING configs/vexmira.cfg");
if(!file_exists("addons/amxmodx/data/lang/vexmira_zombie.txt")) diag_Report("MISSING data/lang/vexmira_zombie.txt");
diag_Report("ASSETS checked=%d missing=%d size_mismatch=%d",sizeof diag_ASSETS,diag_missing,diag_size_errors);
diag_Report("END. Also capture: meta list; amxx version; amxx plugins. This checks files, not live gameplay.");
}
new const ZC_MOD_NAME[ZC_MODS][] = { "vx42_janus7", "vx42_plasma", "vx42_thunderbolt", "vx42_ethereal", "vx42_salamander", "vx42_bow", "vx42_dragonsword", "vx42_katana", "vx42_lightsaber", "vx42_horseaxe", "vx42_hev", "vx42_jetpack", "vx42_minigun", "vx42_diagnostic" };
new const ZC_MOD_COMP[ZC_MODS] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 0 };
ZcCompMod(comp)
{
for (new i = 0; i < ZC_MODS; i++) if (ZC_MOD_COMP[i] == comp) return i;
return -1;
}
bool:ZcCompOn(comp)
{
new i = ZcCompMod(comp);
return i >= 0 && g_bZcOn[i];
}
ZcModulesOn()
{
new n; for (new i = 0; i < ZC_MODS; i++) if (g_bZcOn[i]) n++;
return n;
}
ZcModuleStatus(id)
{
console_print(id,"8 yeni ozel silah core tarafindadir: vex_status | HEV kaldirildi.");
for (new i = 6; i < ZC_MODS; i++)
if(i!=10) console_print(id, "module %-18s component %2d : %s", ZC_MOD_NAME[i], ZC_MOD_COMP[i], g_bZcOn[i] ? "ON" : "OFF (missing/damaged asset, see amxx log)");
for (new i = 0; i < ZC_MODS; i++)
if (i>=6 && i!=10 && !g_bZcOn[i]) log_amx("[Community] NOT READY: module %s is off (missing/damaged asset)", ZC_MOD_NAME[i]);
}
ZcCall(comp, op, id)
{
if (!ZcCompOn(comp) || id < 1 || id > 32) return 0;
switch (comp)
{
case 1: switch (op) {
case ZCOP_give: return jan_vex_give(id);
case ZCOP_has: return jan_vex_has(id);
case ZCOP_remove: return jan_vex_remove(id);
}
case 2: switch (op) {
case ZCOP_give: return pla_vex_give(id);
case ZCOP_has: return pla_vex_has(id);
case ZCOP_remove: return pla_vex_remove(id);
}
case 3: switch (op) {
case ZCOP_give: return thb_vex_give(id);
case ZCOP_has: return thb_vex_has(id);
case ZCOP_remove: return thb_vex_remove(id);
}
case 4: switch (op) {
case ZCOP_give: return eth_vex_give(id);
case ZCOP_has: return eth_vex_has(id);
case ZCOP_remove: return eth_vex_remove(id);
}
case 5: switch (op) {
case ZCOP_give: return sal_vex_give(id);
case ZCOP_has: return sal_vex_has(id);
case ZCOP_remove: return sal_vex_remove(id);
}
case 6: switch (op) {
case ZCOP_give: return bow_vex_give(id);
case ZCOP_has: return bow_vex_has(id);
case ZCOP_remove: return bow_vex_remove(id);
}
case 7: switch (op) {
case ZCOP_give: return drs_vex_give(id);
case ZCOP_has: return drs_vex_has(id);
case ZCOP_remove: return drs_vex_remove(id);
}
case 8: switch (op) {
case ZCOP_give: return kat_vex_give(id);
case ZCOP_has: return kat_vex_has(id);
case ZCOP_remove: return kat_vex_remove(id);
}
case 9: switch (op) {
case ZCOP_give: return lsb_vex_give(id);
case ZCOP_has: return lsb_vex_has(id);
case ZCOP_remove: return lsb_vex_remove(id);
}
case 10: switch (op) {
case ZCOP_give: return hax_vex_give(id);
case ZCOP_has: return hax_vex_has(id);
case ZCOP_remove: return hax_vex_remove(id);
}
case 11: switch (op) {
case ZCOP_give: return hev_vex_give(id);
case ZCOP_has: return hev_vex_has(id);
case ZCOP_remove: return hev_vex_remove(id);
}
case 12: switch (op) {
case ZCOP_give: return jet_vex_give(id);
case ZCOP_has: return jet_vex_has(id);
case ZCOP_remove: return jet_vex_remove(id);
case ZCOP_infected: return jet_vex_infected(id);
}
case 13: switch (op) {
case ZCOP_give: return mgn_vex_give(id);
case ZCOP_has: return mgn_vex_has(id);
case ZCOP_remove: return mgn_vex_remove(id);
}
}
return 0;
}
ZcPcModel(const path[])
{
if (!file_exists(path, true) || !CommunityLegacyFileOk(path)) {
log_amx("[AssetGuard] EKSIK/BOZUK %s -> modul %s KAPALI (sunucu calismaya devam ediyor)", path, g_zcCurMod >= 0 ? ZC_MOD_NAME[g_zcCurMod] : "?");
g_zcGuardFail = true;
return 0;
}
new known51;if(g_tZcModelsReady!=Invalid_Trie && TrieGetCell(g_tZcModelsReady,path,known51))return known51;
if(g_iPcM51>=448) {g_zcGuardFail=true;log_amx("[AssetGuard] model reserve: %s",path);return 0;}
log_to_file("vexmira_startup.log","MODEL begin: %s",path);
new modelIndex = (!VxPcOk531()) ? 0 : precache_model(path);
RegisterTexture530(path);
log_to_file("vexmira_startup.log","MODEL ready: %s [%d]",path,modelIndex);
if(g_tZcModelsReady==Invalid_Trie) g_tZcModelsReady=TrieCreate();
TrieSetCell(g_tZcModelsReady,path,modelIndex);
return modelIndex;
}
ZcPcSound(const path[])
{
new f[160]; formatex(f, charsmax(f), "sound/%s", path);
if (!file_exists(f, true)) { log_amx("[AssetGuard] UYARI eksik ses %s (atlandi)", f); return 0; }
if(g_iPcS51>=448) {g_zcGuardFail=true;return 0;}
return (!VxPcOk531()) ? 0 : precache_sound(path);
}
ZcPcGeneric(const path[])
{
if (!file_exists(path, true)) { log_amx("[AssetGuard] UYARI eksik dosya %s (atlandi)", path); return 0; }
if(g_iPcG51>=448) return 0;
return (!VxPcOk531()) ? 0 : precache_generic(path);
}
public GuardM51(const path[]) { g_iPcM51=max(g_iPcM51,get_orig_retval()); }
public GuardS51(const path[]) { g_iPcS51=max(g_iPcS51,get_orig_retval()); }
public GuardG51(const path[]) { g_iPcG51=max(g_iPcG51,get_orig_retval()); }

// ===================== 5.3.1 model guard (gear) =====================
// Asks vexmira_core (VxModelOkPublic) whether a model is really precached before using it.
new g_iGuardPl531 = -2, g_iGuardFn531 = -1, g_iGuardLog531;
// 5.3.2: models this plugin precached itself are always OK (the core's engine hook can miss them when the
// panel loads vexmira_gear BEFORE vexmira_core - then the jetpack / weapon models were wrongly hidden)
public VxGearModelOkPublic(const m[])
{
new k;
if (g_tZcModelsReady != Invalid_Trie && TrieGetCell(g_tZcModelsReady, m, k) && k > 0) return 1;
return 0;
}
stock VxCoreModelOk(const m[])
{
if (!m[0]) return 1;
{ new k; if (g_tZcModelsReady != Invalid_Trie && TrieGetCell(g_tZcModelsReady, m, k) && k > 0) return 1; }
if (g_iGuardPl531 == -2)
{
g_iGuardPl531 = -1;
new n = get_pluginsnum();
for (new i = 0; i < n; i++)
{
new f = get_func_id("VxModelOkPublic", i);
if (f >= 0) { g_iGuardPl531 = i; g_iGuardFn531 = f; break; }
}
}
if (g_iGuardPl531 < 0) return 1;
new st[16], d[2];
get_plugin(g_iGuardPl531, d, 0, d, 0, d, 0, d, 0, st, charsmax(st));
if (!equal(st, "running") && !equal(st, "debug")) return 1;
if (callfunc_begin_i(g_iGuardFn531, g_iGuardPl531) != 1) return 1;
callfunc_push_str(m, false);
return callfunc_end();
}
stock VxSM(ent, const m[])
{
if (!VxCoreModelOk(m)) { if (g_iGuardLog531++ < 40) log_amx("[ModelGuard] SetModel '%s' yuklu degil -> atlandi (cokme onlendi)", m); return 0; }
engfunc(EngFunc_SetModel, ent, m);
return 1;
}
stock VxCsSetModel(id, const name[])
{
new p[128]; formatex(p, charsmax(p), "models/player/%s/%s.mdl", name, name);
if (!VxCoreModelOk(p)) { if (g_iGuardLog531++ < 40) log_amx("[ModelGuard] oyuncu modeli '%s' yuklu degil -> degistirilmedi", p); return 0; }
cs_set_user_model(id, name);
return 1;
}
// ===================== end model guard =====================
public plugin_precache()
{
g_iIsolation526=ReadIsolation526();
log_to_file("vexmira_groups.log","[530 vexgear] selected profile=%d",g_iIsolation526);g_bRun526=(g_iIsolation526==2 || g_iIsolation526==3);
log_to_file("vexmira_isolation.log","[530 vexgear] stage=%d full_module=%d precache BEGIN",g_iIsolation526,g_bRun526);
if(!g_bRun526) {log_to_file("vexmira_isolation.log","[530 vexgear] baseline precache READY: no custom resources/hooks");return;}

RegisterHookChain(RH_SV_ActivateServer,"VxActivatePre524",0);
RegisterHookChain(RH_SV_ActivateServer,"VxActivatePost524",1);
log_to_file("vexmira_startup.log","[5.2.3] equipment preload begin");
register_forward(FM_PrecacheModel,"GuardM51",1);register_forward(FM_PrecacheSound,"GuardS51",1);register_forward(FM_PrecacheGeneric,"GuardG51",1);
g_pZcRewrite = register_cvar("zc_rewrite_configs", "0");
new bool:force = get_pcvar_num(g_pZcRewrite) > 0;
ZcWriteConfigs(force);
if (force) set_pcvar_num(g_pZcRewrite, 0);
if (cvar_exists("sv_auto_precache_sounds_in_models")) set_cvar_num("sv_auto_precache_sounds_in_models", 0);
g_bZcOn[0]=false; // Replaced by core Arsenal8.
g_bZcOn[1]=false; // Replaced by core Arsenal8.
g_bZcOn[2]=false; // Replaced by core Arsenal8.
g_bZcOn[3]=false; // Replaced by core Arsenal8.
g_bZcOn[4]=false; // Replaced by core Arsenal8.
g_bZcOn[5]=false; // Replaced by core Arsenal8.
g_zcCurMod = 6; g_zcGuardFail = false; drs_plugin_precache(); g_bZcOn[6] = !g_zcGuardFail;
g_zcCurMod = 7; g_zcGuardFail = false; kat_plugin_precache(); g_bZcOn[7] = !g_zcGuardFail;
g_zcCurMod = 8; g_zcGuardFail = false; lsb_plugin_precache(); g_bZcOn[8] = !g_zcGuardFail;
g_zcCurMod = 9; g_zcGuardFail = false; hax_plugin_precache(); g_bZcOn[9] = !g_zcGuardFail;
g_bZcOn[10]=false; // HEV removed: no models/sounds/hooks are loaded.
g_zcCurMod = 11; g_zcGuardFail = false; jet_plugin_precache(); g_bZcOn[11] = !g_zcGuardFail;
g_zcCurMod = 12; g_zcGuardFail = false; mgn_plugin_precache(); g_bZcOn[12] = !g_zcGuardFail;
g_bZcOn[13] = true;
g_zcCurMod = -1;
for (new i = 0; i < ZC_MODS; i++)
if (i>=6 && i!=10 && !g_bZcOn[i]) log_amx("[Vexmira] modul %s KAPALI: eksik/bozuk dosya (yukaridaki AssetGuard satirlari). Diger her sey calisiyor.", ZC_MOD_NAME[i]);
}
// 5.3.1: precache after map load = engine Host_Error (server shutdown) -> refuse instead
new bool:g_bPcClosed531, g_iPcLate531;
stock bool:VxPcOk531()
{
if (!g_bPcClosed531) return true;
if (g_iPcLate531++ < 5) log_amx("[Guard] harita yuklendikten sonra precache denemesi engellendi (cokme onlendi)");
return false;
}
public VxPcClose531() g_bPcClosed531 = true;
public plugin_init()
{
set_task(0.1, "VxPcClose531");
log_to_file("vexmira_isolation.log","[530 vexgear] plugin_init BEGIN stage=%d full=%d",g_iIsolation526,g_bRun526);
register_clcmd("vex_test","IsolationStatus526");
if(!g_bRun526) {register_plugin("Vexmira vexgear Baseline Test","5.3.1-Stable","Vexmira");log_to_file("vexmira_isolation.log","[530 vexgear] baseline plugin_init COMPLETE");return;}

log_to_file("vexmira_startup.log","[530 vexgear] plugin_init BEGIN");
register_plugin("Vexmira Equipment", "5.3.1-Stable", "SmurfSexy & Capital / CSO authors");
ZcBuildTrackedSoundList();
if (g_bZcOn[0]) { log_to_file("vexmira_startup.log","[530 gear] jan BEGIN"); jan_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] jan READY"); }
if (g_bZcOn[1]) { log_to_file("vexmira_startup.log","[530 gear] pla BEGIN"); pla_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] pla READY"); }
if (g_bZcOn[2]) { log_to_file("vexmira_startup.log","[530 gear] thb BEGIN"); thb_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] thb READY"); }
if (g_bZcOn[3]) { log_to_file("vexmira_startup.log","[530 gear] eth BEGIN"); eth_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] eth READY"); }
if (g_bZcOn[4]) { log_to_file("vexmira_startup.log","[530 gear] sal BEGIN"); sal_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] sal READY"); }
if (g_bZcOn[5]) { log_to_file("vexmira_startup.log","[530 gear] bow BEGIN"); bow_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] bow READY"); }
if (g_bZcOn[6]) { log_to_file("vexmira_startup.log","[530 gear] drs BEGIN"); drs_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] drs READY"); }
if (g_bZcOn[7]) { log_to_file("vexmira_startup.log","[530 gear] kat BEGIN"); kat_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] kat READY"); }
if (g_bZcOn[8]) { log_to_file("vexmira_startup.log","[530 gear] lsb BEGIN"); lsb_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] lsb READY"); }
if (g_bZcOn[9]) { log_to_file("vexmira_startup.log","[530 gear] hax BEGIN"); hax_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] hax READY"); }
if (g_bZcOn[10]) { log_to_file("vexmira_startup.log","[530 gear] hev BEGIN"); hev_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] hev READY"); }
if (g_bZcOn[11]) { log_to_file("vexmira_startup.log","[530 gear] jet BEGIN"); jet_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] jet READY"); }
if (g_bZcOn[12]) { log_to_file("vexmira_startup.log","[530 gear] mgn BEGIN"); mgn_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] mgn READY"); }
if (g_bZcOn[13]) { log_to_file("vexmira_startup.log","[530 gear] diag BEGIN"); diag_plugin_init(); log_to_file("vexmira_startup.log","[530 gear] diag READY"); }
log_to_file("vexmira_startup.log","[530 gear] dispatch BEGIN");
ZcRegisterDispatchers();
log_to_file("vexmira_startup.log","[530 gear] plugin_init COMPLETE");
register_concmd("zc_writeconfigs", "ZcCmdWriteConfigs", ADMIN_RCON, "- gomulu vexmira.cfg / lang / harita ini / motd dosyalarini yeniden yazar (USTUNE YAZAR)");
register_concmd("zc_modules", "ZcCmdModules", ADMIN_RCON, "- dahili esya modullerinin durumu");
}
public client_putinserver(id)
{
if(!g_bRun526) return;
if (g_bZcOn[0]) jan_client_putinserver(id);
if (g_bZcOn[1]) pla_client_putinserver(id);
if (g_bZcOn[2]) thb_client_putinserver(id);
if (g_bZcOn[3]) eth_client_putinserver(id);
if (g_bZcOn[4]) sal_client_putinserver(id);
if (g_bZcOn[6]) drs_client_putinserver(id);
if (g_bZcOn[7]) kat_client_putinserver(id);
if (g_bZcOn[8]) lsb_client_putinserver(id);
if (g_bZcOn[9]) hax_client_putinserver(id);
if (g_bZcOn[11]) jet_client_putinserver(id);
}
public client_disconnected(id, bool:drop, message[], maxlen)
{
ZcStopTrackedSounds(id);
g_iTrackedWeaponId[id] = 0;
if(!g_bRun526) return;
if (g_bZcOn[4]) sal_client_disconnect(id);
if (g_bZcOn[9]) hax_client_disconnect(id);
if (g_bZcOn[10]) hev_client_disconnect(id);
if (g_bZcOn[12]) mgn_client_disconnect(id);
}
public ZcCmdModules(id, level, cid)
{
if (!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED;
console_print(id, "Vexmira Zombie Core %s - %d/%d modul acik", VERSION, ZcModulesOn(), ZC_MODS);
ZcModuleStatus(id);
return PLUGIN_HANDLED;
}
public ZcFmD_CmdStart(a1, a2, a3)
{
new m = g_zcFm[ZCFM_CmdStart], r = FMRES_IGNORED, t;
#pragma unused t
if (m & (1<<0)) { t = jan_fw_CmdStart(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<2)) { t = thb_fw_CmdStart(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<3)) { t = eth_fw_CmdStart(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<4)) { t = sal_fw_CmdStart(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<5)) { t = bow_fw_CmdStart(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<6)) { t = drs_fw_CmdStart(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<7)) { t = kat_fw_CmdStart(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<8)) { t = lsb_fw_CmdStart(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<11)) jet_OnCmdStart(a1, a2, a3);
if (m & (1<<12)) { t = mgn_fw_CmdStart(a1, a2, a3); if (t > r) r = t; }
return r;
}
public ZcFmD_EmitSound(a1, a2, a3[], Float:a4, Float:a5, a6, a7)
{
if (a1 >= 1 && a1 <= 32 && g_bStoppingTrackedSound[a1]) return FMRES_IGNORED;
new m = g_zcFm[ZCFM_EmitSound], r = FMRES_IGNORED, t;
#pragma unused t
if (m & (1<<2)) { t = thb_fw_EmitSound(a1, a2, a3, a4, a5, a6, a7); if (t > r) r = t; }
if (m & (1<<5)) { t = bow_fw_EmitSound(a1, a2, a3, a4, a5, a6, a7); if (t > r) r = t; }
if (m & (1<<6)) { t = drs_fw_EmitSound(a1, a2, a3, a4, a5, a6, a7); if (t > r) r = t; }
if (m & (1<<7)) { t = kat_fw_EmitSound(a1, a2, a3, a4, a5, a6, a7); if (t > r) r = t; }
if (m & (1<<8)) { t = lsb_fw_EmitSound(a1, a2, a3, a4, a5, a6, a7); if (t > r) r = t; }
if (m & (1<<9)) { t = hax_fw_EmitSound(a1, a2, a3, a4, a5, a6, a7); if (t > r) r = t; }
if (m & (1<<10)) { t = hev_fw_EmitSound(a1, a2, a3, a4, a5, a6, a7); if (t > r) r = t; }
if (r < FMRES_SUPERCEDE && a1 >= 1 && a1 <= 32 && a2 >= 0 && a2 < 8 && equal(a3, "weapons/", 8) && !(a6 & SND_STOP))
{
    new key[128];
    formatex(key, charsmax(key), "sound/%s", a3);
    if (g_tTrackedWeaponSounds != Invalid_Trie && TrieKeyExists(g_tTrackedWeaponSounds, key))
        copy(g_szTrackedWeaponSound[a1][a2], charsmax(g_szTrackedWeaponSound[][]), a3);
}
return r;
}
public ZcFmD_PlaybackEvent(a1, a2, a3, Float:a4, Float:a5[3], Float:a6[3], Float:a7, Float:a8, a9, a10, a11, a12)
{
new m = g_zcFm[ZCFM_PlaybackEvent], r = FMRES_IGNORED, t;
#pragma unused t
if (m & (1<<0)) { t = jan_fw_PlaybackEvent(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12); if (t > r) r = t; }
if (m & (1<<1)) { t = pla_fw_PlaybackEvent(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12); if (t > r) r = t; }
if (m & (1<<2)) { t = thb_fw_PlaybackEvent(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12); if (t > r) r = t; }
if (m & (1<<3)) { t = eth_fw_PlaybackEvent(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12); if (t > r) r = t; }
if (m & (1<<4)) { t = sal_fw_PlaybackEvent(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12); if (t > r) r = t; }
if (m & (1<<12)) { t = mgn_Forward_PlayBackEvent(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12); if (t > r) r = t; }
return r;
}
public ZcFmD_PlayerPreThink(a1)
{
new m = g_zcFm[ZCFM_PlayerPreThink], r = FMRES_IGNORED, t;
#pragma unused t
if (m & (1<<10)) { t = hev_fw_PlayerPreThink(a1); if (t > r) r = t; }
if (m & (1<<12)) { t = mgn_Forward_PlayerPreThink(a1); if (t > r) r = t; }
return r;
}
public ZcFmD_SetModel(a1, a2[])
{
new m = g_zcFm[ZCFM_SetModel], r = FMRES_IGNORED, t;
#pragma unused t
if (m & (1<<0)) { t = jan_fw_SetModel(a1, a2); if (t > r) r = t; }
if (m & (1<<1)) { t = pla_fw_SetModel(a1, a2); if (t > r) r = t; }
if (m & (1<<2)) { t = thb_fw_SetModel(a1, a2); if (t > r) r = t; }
if (m & (1<<3)) { t = eth_fw_SetModel(a1, a2); if (t > r) r = t; }
if (m & (1<<4)) { t = sal_fw_SetModel(a1, a2); if (t > r) r = t; }
if (m & (1<<5)) { t = bow_fw_SetModel(a1, a2); if (t > r) r = t; }
if (m & (1<<12)) { t = mgn_Forward_SetModel(a1, a2); if (t > r) r = t; }
return r;
}
public ZcFmD_TraceHull(Float:a1[3], Float:a2[3], a3, a4, a5, a6)
{
new m = g_zcFm[ZCFM_TraceHull], r = FMRES_IGNORED, t;
#pragma unused t
if (m & (1<<2)) { t = thb_fw_TraceHull(a1, a2, a3, a4, a5, a6); if (t > r) r = t; }
if (m & (1<<5)) { t = bow_fw_TraceHull(a1, a2, a3, a4, a5, a6); if (t > r) r = t; }
if (m & (1<<6)) { t = drs_fw_TraceHull(a1, a2, a3, a4, a5, a6); if (t > r) r = t; }
if (m & (1<<7)) { t = kat_fw_TraceHull(a1, a2, a3, a4, a5, a6); if (t > r) r = t; }
if (m & (1<<8)) { t = lsb_fw_TraceHull(a1, a2, a3, a4, a5, a6); if (t > r) r = t; }
if (m & (1<<9)) { t = hax_fw_TraceHull(a1, a2, a3, a4, a5, a6); if (t > r) r = t; }
return r;
}
public ZcFmD_TraceLine(Float:a1[3], Float:a2[3], a3, a4, a5)
{
new m = g_zcFm[ZCFM_TraceLine], r = FMRES_IGNORED, t;
#pragma unused t
if (m & (1<<2)) { t = thb_fw_TraceLine(a1, a2, a3, a4, a5); if (t > r) r = t; }
if (m & (1<<5)) { t = bow_fw_TraceLine(a1, a2, a3, a4, a5); if (t > r) r = t; }
if (m & (1<<6)) { t = drs_fw_TraceLine(a1, a2, a3, a4, a5); if (t > r) r = t; }
if (m & (1<<7)) { t = kat_fw_TraceLine(a1, a2, a3, a4, a5); if (t > r) r = t; }
if (m & (1<<8)) { t = lsb_fw_TraceLine(a1, a2, a3, a4, a5); if (t > r) r = t; }
if (m & (1<<9)) { t = hax_fw_TraceLine(a1, a2, a3, a4, a5); if (t > r) r = t; }
return r;
}
public ZcFmD_UpdateClientData_P(a1, a2, a3)
{
new m = g_zcFm[ZCFM_UpdateClientData_P], r = FMRES_IGNORED, t;
#pragma unused t
if (m & (1<<0)) { t = jan_fw_UpdateClientData_Post(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<1)) { t = pla_fw_UpdateClientData_Post(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<2)) { t = thb_fw_UpdateClientData_Post(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<3)) { t = eth_fw_UpdateClientData_Post(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<4)) { t = sal_fw_UpdateClientData_Post(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<5)) { t = bow_fw_UpdateClientData_Post(a1, a2, a3); if (t > r) r = t; }
if (m & (1<<12)) { t = mgn_Forward_UpdateClientData(a1, a2, a3); if (t > r) r = t; }
return r;
}
public ZcEvD_CurWeapon(id)
{
if (id < 1 || id > 32)
    return;
new weaponId = read_data(2);
if (g_iTrackedWeaponId[id] && g_iTrackedWeaponId[id] != weaponId)
    ZcStopTrackedSounds(id);
g_iTrackedWeaponId[id] = weaponId;
new m = g_zcEvCurWeapon;
if (m & (1<<2)) thb_Event_CurWeapon(id);
if (m & (1<<3)) eth_Event_CurWeapon(id);
if (m & (1<<4)) sal_Safety_CurWeapon(id);
if (m & (1<<5)) bow_Event_CurWeapon(id);
if (m & (1<<6)) drs_Event_CurWeapon(id);
if (m & (1<<7)) kat_Event_CurWeapon(id);
if (m & (1<<8)) lsb_Event_CurWeapon(id);
if (m & (1<<9)) hax_Safety_CurWeapon(id);
if (m & (1<<10)) hev_Event_CurWeapon(id);
}
ZcBuildTrackedSoundList()
{
    if (g_tTrackedWeaponSounds != Invalid_Trie)
        TrieDestroy(g_tTrackedWeaponSounds);
    g_tTrackedWeaponSounds = TrieCreate();
    if (g_tTrackedWeaponSounds == Invalid_Trie)
        return;
    for (new i = 0; i < sizeof diag_ASSETS; i++)
    {
        if (containi(diag_ASSETS[i], "sound/weapons/") != 0)
            continue;
        TrieSetCell(g_tTrackedWeaponSounds, diag_ASSETS[i], 1);
    }
}
ZcStopTrackedSounds(id)
{
    if (id < 1 || id > 32)
        return;
    g_bStoppingTrackedSound[id] = true;
    for (new channel = 0; channel < 8; channel++)
    {
        if (!g_szTrackedWeaponSound[id][channel][0])
            continue;
        emit_sound(id, channel, g_szTrackedWeaponSound[id][channel], 0.0, ATTN_NORM, SND_STOP, PITCH_NORM);
        g_szTrackedWeaponSound[id][channel][0] = 0;
    }
    g_bStoppingTrackedSound[id] = false;
}
public ZcWeaponSoundDeath()
{
    new id = read_data(2);
    ZcStopTrackedSounds(id);
    if (id >= 1 && id <= 32)
        g_iTrackedWeaponId[id] = 0;
}
ZcRegisterDispatchers()
{
register_forward(FM_CmdStart, "ZcFmD_CmdStart");
register_forward(FM_EmitSound, "ZcFmD_EmitSound");
if (g_zcFm[ZCFM_PlaybackEvent]) register_forward(FM_PlaybackEvent, "ZcFmD_PlaybackEvent");
register_forward(FM_PlayerPreThink, "ZcFmD_PlayerPreThink");
if (g_zcFm[ZCFM_SetModel]) register_forward(FM_SetModel, "ZcFmD_SetModel");
if (g_zcFm[ZCFM_TraceHull]) register_forward(FM_TraceHull, "ZcFmD_TraceHull");
if (g_zcFm[ZCFM_TraceLine]) register_forward(FM_TraceLine, "ZcFmD_TraceLine");
if (g_zcFm[ZCFM_UpdateClientData_P]) register_forward(FM_UpdateClientData, "ZcFmD_UpdateClientData_P", 1);
if (g_zcEvCurWeapon) register_event("CurWeapon", "ZcEvD_CurWeapon", "be", "1=1");
register_event("DeathMsg", "ZcWeaponSoundDeath", "a");
}
new const ZC_F_CFG[][] = {
"// VEXMIRA ZOMBIE 5.3.3 - TEK AYAR DOSYASI (vexmira_core + vexmira_gear)",
"// ------------------------------------------------------------------------------",
"// NASIL DEGISTIRILIR:",
"//  * Her satir:   ayar_adi  deger      // aciklama    (^"//^" sonrasi okunmaz, kendi notunu yazabilirsin)",
"//  * Kaydet; oyunda ^"amx_rcon vex_reload^" ya da harita degisimiyle gecerli olur.",
"//  * vex_res ... satirlari (model / ses / sprite / gokyuzu / ambiyans) SADECE harita degisiminde yuklenir.",
"//  * SES YOLU:   ^"sound/^" ile ya da onsuz yazabilirsin, ikisi de olur:  ^"vexmira/x.wav^" = ^"sound/vexmira/x.wav^"",
"//      wav dosyasi MONO olmali (8 ya da 16 bit, 11025 / 22050 Hz). Stereo / 44 kHz wav CS 1.6 da CALMAZ.",
"//      Muzik / ambiyans icin .mp3 de kullanabilirsin.",
"//  * Birden fazla ses:  ^"a.wav|b.wav|c.wav^"  -> her seferinde rastgele biri.",
"//  * MODEL YOLU: ^"models/klasor/dosya.mdl^"; oyuncu modellerinde sadece klasor adi (models/player/AD/AD.mdl -> ^"AD^").",
"//  * ^"^" (bos) = o ses / model kapali ya da varsayilan.",
"//  * Dosya sunucuda yoksa eklenti onu ATLAR (cokmez). Hangi dosyalarin eksik oldugunu gormek icin",
"//    sunucu konsoluna (ya da admin olarak oyunda) yaz:  vex_kontrol",
"// ORNEKLER:",
"//    Nemesis roundu ambiyansi    ->  vex_res AMBIENT_MODE2 ^"sound/benim/nemesis_amb.wav^"",
"//    Boss 0 (Brute) giris sesi    ->  vex_res B0_INTRO ^"benim/brute_giris.wav^"",
"//    Zombi pencesi sesleri        ->  vex_res ZOMBIE_HIT ^"zombie/claw1.wav|zombie/claw2.wav^"",
"//    Kanat modeli                 ->  vex_wing 1 ^"Ad^" ^"Ad TR^" models/benim/kanat.mdl 250 0 bone -3 0 -2 0 0 0 1 1 1.0",
"//    Market esyasi sesi           ->  vex_res ITEM_SND_madness ^"benim/cinnet.wav^"",
"//  * vexmira_epic.cfg ARTIK KULLANILMAZ: tum ayarlar bu dosyada.",
"// ------------------------------------------------------------------------------",
"",
"// ==============================================================================",
"// GENEL",
"//   Sunucu adi, sohbet etiketleri, temel ayarlar",
"// ==============================================================================",
"vex_hostname ^"Zombie Plague | Vexmira | Boss+Events+Bunny^"   // sunucu adi (oyun listesinde gorunen)",
"vex_hostname_dynamic 0                                       // 1 = adin sonuna round / mod bilgisi eklenir, 0 = sabit ad",
"vex_chat_prefix ^"^^4[^^1VEXMIRA^^4]^^1^"                          // sistem mesaji etiketi (^^1 sari ^^3 takim rengi ^^4 yesil; Turkce harf kullanma, CS 1.6 sohbeti bozuk gosterir)",
"vex_chat_prefix_boss ^"^^3[^^4BOSS^^3]^^1^"                        // boss / boss yetenekleri etiketi",
"vex_chat_prefix_event ^"^^4[^^3EVENT^^4]^^1^"                      // event / hava olayi etiketi",
"vex_chat_prefix_vip    ^"^^4[^^3VIP^^4]^^1^"                       // VIP / ELITE",
"vex_chat_prefix_admin ^"^^3[^^4ADMIN^^3]^^1^"                      // admin islemleri etiketi",
"mp_maxrounds 30                                              // harita kac round surer",
"mp_timelimit           0                                     // sure siniri yok (30 round belirler)",
"mapcyclefile ^"mapcycle_vexmira.txt^"                          // harita sirasi dosyasi (sunucudaki haritalari buraya ekle; oylama havuzu: vex_map_pool)",
"vex_chat_broadcast     1                                     // 1 = level, rutbe, basarim, gorev, liderlik, enfeksiyon, oy, baglanma mesajlari herkese gider; 0 = kapali",
"vex_chat_buy_broadcast 0                                     // 1 = ^"X sunu satin aldi^" (market / kozmetik) mesajlari herkese gider; 0 = kapali (onerilir)",
"sv_maxspeed            900                                   // hiz eventleri icin sinir yukseltildi (onemli!)",
"vex_start_ap 100                                             // yeni oyuncu baslangic AP",
"vex_skill_alt_keys        1                                  // 1 = zombilerde G (drop) tusu da yetenegi kullanir (insanlarda silah atma degismez)",
"vex_motd 0                                                   // giriste bilgi penceresi",
"vex_chat_tip_interval 240                                    // sohbet ipucu araligi (sn)",
"mp_round_infinite ^"abcdefghijk^"                              // round bitisini tamamen Vexmira yonetir (sure, rehine, bomba...)",
"mp_roundover 3                                               // round bitince bekleme davranisi (ReGameDLL)",
"mp_autoteambalance 0                                         // otomatik takim dengeleme (zombi modunda 0)",
"mp_limitteams 0                                              // takim farki siniri (0 = yok)",
"mp_auto_join_team 1                                          // 1 = haritaya / sunucuya girince takim ve karakter menusu ACILMAZ, oyuncu otomatik",
"mp_buytime 0                                                 // CS satin alma suresi (0 = kapali, market eklentide)",
"mp_buy_anywhere 0                                            // her yerde CS market (0 = kapali)",
"mp_maxmoney 999999                                           // en fazla para",
"mp_t_default_weapons_secondary ^"^"                            // T baslangic tabancasi (^"^" = yok)",
"mp_ct_default_weapons_secondary ^"^"                           // CT baslangic tabancasi",
"mp_t_default_weapons_primary ^"^"                              // T baslangic silahi",
"mp_ct_default_weapons_primary ^"^"                             // CT baslangic silahi",
"mp_t_give_player_knife 1                                     // T bicak verilir",
"mp_ct_give_player_knife 1                                    // CT bicak verilir",
"mp_free_armor 0                                              // bedava zirh",
"mp_weapons_allow_map_placed 0                                // haritadaki silahlar alinabilir",
"mp_nadedrops 0                                               // olunce bomba dusurme",
"mp_weapondrop 1                                              // olunce silah dusurme",
"mp_item_staytime 15                                          // yerdeki esya kac sn kalir",
"mp_falldamage 1                                              // dusme hasari",
"mp_respawn_immunitytime 0                                    // dogunca dokunulmazlik sn",
"mp_kill_filled_spawn 0                                       // dolu dogma noktasinda oldurme",
"mp_show_scenarioicon 0                                       // senaryo ikonu",
"mp_scoreboard_showmoney 3                                    // skor tablosunda para gorunumu",
"mp_knockback 0                                               // CS geri tepmesi (eklentininki ayri)",
"mp_freezetime 3                                              // round basi donma suresi (sn)",
"mp_roundtime 4                                               // round suresi (dakika)",
"mp_friendlyfire 0                                            // takim hasari",
"mp_footsteps 1                                               // ayak sesleri",
"mp_flashlight 1                                              // 1 OLMALI: Boss / Nemesis / Assassin [F] tusu fener tusudur",
"mp_tkpunish 0                                                // takim oldurme cezasi",
"sv_alltalk 1                                                 // 1 = herkes birbirini duyar",
"sv_allowdownload 1                                           // ozel ses / sprite indirmesi icin 1 OLMALI",
"sv_allowupload 0                                             // oyuncu spray yukleme",
"sv_auto_precache_sounds_in_models 0                          // modellerdeki sesleri otomatik yukle (0 = ses limiti icin kapali)",
"vex_ui52 1                                                   // ekran duyurulari (mod / event baslangic yazilari)",
"",
"// ==============================================================================",
"// ROUND VE MODLAR",
"//   Round sayisi, boss / ozel round sirasi, mod olasiliklari (vex_mode_rule",
"//   <mod> <sans%> <min oyuncu>)",
"// ==============================================================================",
"vex_rounds_total 30                                          // toplam round (harita oylamasi icin)",
"vex_boss_rounds ^"8 16 24 30^"                                 // hangi roundlar BOSS roundu (bosluk ile)",
"vex_special_rounds     ^"4 11 19 26^"                          // ozel mod roundlari (Nemesis, Survivor, Plague...)",
"vex_boss_every         6                                     // vex_boss_rounds bos (^"^") ise her N roundda bir boss",
"vex_multi_chance       15                                    // normal roundun Coklu Enfeksiyon olma olasiligi (%)",
"vex_event_chance 30                                          // event cikma sansi (%)",
"vex_countdown          10                                    // enfeksiyondan once geri sayim (sn) (4.3: 15 -> 10, daha hizli aksiyon)",
"vex_zombie_respawn     4.0                                   // olen zombinin geri donus suresi (sn), sadece Infection/Multi",
"vex_mode_rule 0  0    2                                      // Enfeksiyon",
"vex_mode_rule 1  15   2                                      // Coklu Enfeksiyon",
"vex_mode_rule 2  5    4                                      // Nemesis",
"vex_mode_rule 3  4    4                                      // Assassin",
"vex_mode_rule 4  5    4                                      // Survivor",
"vex_mode_rule 5  4    4                                      // Sniper",
"vex_mode_rule 6  5    6                                      // Swarm",
"vex_mode_rule 7  3    6                                      // Plague",
"vex_mode_rule 8  2    8                                      // Armageddon",
"vex_mode_rule 9  0    2                                      // BOSS (en az 2 oyuncu; dusuk oyuncu sayisinda round enfeksiyona dusmesin)",
"vex_first_zombie_hp    6000                                  // ilk zombi (sinif carpani uygulanir)",
"vex_last_human_bonus   150                                   // son insana verilen ekstra can",
"vex_round_stopsound    1                                     // 1 = yeni round basinda tum eklenti sesleri + muzik susar (haritanin dongulu ortam sesleri 0.8 sn sonra geri gelir)",
"",
"// ==============================================================================",
"// HARITA VE OYLAMA",
"//   Harita havuzu, oylama, RTV, harita hikayesi",
"// ==============================================================================",
"vex_vote_every 6                                             // kac roundda bir mod oylamasi",
"vex_map_vote           1                                     // 1 = harita oylamasi + RTV acik (0 = kapali, oyunun kendi dongusu)",
"vex_map_pool ^"zm_vexmira_icefy zm_vexmira_dust zm_vexmira_7door^" // oylamadaki haritalar",
"vex_map_vote_round 30                                        // harita oylamasi hangi roundda",
"vex_map_vote_time 20                                         // harita oylama suresi (sn)",
"vex_map_vote_extend 0                                        // 1 = ^"haritayi uzat^" secenegi",
"vex_map_extend_rounds  10                                    // uzatma kazanirsa eklenecek round sayisi (mp_maxrounds artar)",
"vex_map_change_delay   7.0                                   // son round bittikten kac sn sonra ara ekran (odul yazilari icin; +3.5 sn sonra harita degisir)",
"vex_map_vote_mapchooser 1                                    // 1 = mapchooser.amxx yukluyse duraklat (cift oylama olmasin), 0 = sadece uyar",
"vex_rtv_ratio          0.60                                  // RTV: insan oyuncularin bu orani ^"rtv^" yazinca oylama baslar (0 = RTV kapali)",
"vex_rtv_minplayers     2                                     // RTV icin en az insan oyuncu",
"vex_rtv_minround       3                                     // RTV bu rounddan once kullanilamaz",
"vex_map_story          1                                     // 1 = ilk dogusta hikaye (daktilo efekti, dil oyuncuya gore), 0 = kapali",
"vex_map_objectives     1                                     // 1 = gorevler freeze sonunda + tamamlaninca gosterilir, 0 = kapali",
"vex_map_markers        1                                     // 1 = acik gorevin yon isareti (mavi isik + sutun, SADECE insanlar gorur), 0 = kapali",
"vex_map_rewards        1                                     // 1 = haritanin vexcmd_reward_* odulleri (round basina relay basina 1 kez), 0 = kapali",
"vex_map_events         1                                     // 1 = eklenti haritanin vex_* varliklarini ve [events] ek hedeflerini tetikler, 0 = kapali",
"vex_map_debug          0                                     // 1 = her harita olayi / komutu log'a yazilir (test icin)",
"vex_map_ambience 8                                           // harita ortam sesi seviyesi / sikligi",
"",
"// ==============================================================================",
"// CAN / HASAR / DENGE",
"//   Zombi ve insan canlari, hasarlar, geri tepme",
"// ==============================================================================",
"vex_zombie_hp          2400                                  // enfekte olan zombi (sinif carpani uygulanir)",
"vex_zombie_hp_per_player 40                                  // normal zombi: her oyuncu basina eklenen can (sinif carpanindan once)",
"vex_human_hp           100                                   // insan taban cani (+ perk / meslek)",
"vex_nemesis_hp         15000                                 // nemesis taban cani (+ vex_nemesis_hp_per_player)",
"vex_nemesis_hp_per_player 1200                               // nemesis: oyuncu basina eklenen can",
"vex_assassin_hp        10000                                 // assassin taban cani (+ vex_assassin_hp_per_player)",
"vex_assassin_hp_per_player 800                               // assassin: oyuncu basina eklenen can",
"vex_survivor_hp        1000                                  // Survivor cani",
"vex_sniper_hp          900                                   // Sniper cani",
"vex_minion_hp          600                                   // boss yardimcisi (dirilen olu) cani",
"vex_zombie_damage      75                                    // enfeksiyon olmayan modlarda zombi vurusu",
"vex_minion_damage      35                                    // boss yardimcilari",
"vex_nemesis_oneshot    1                                     // 1 = Nemesis insani TEK VURUSTA oldurur",
"vex_assassin_oneshot   1                                     // 1 = Assassin insani TEK VURUSTA oldurur",
"vex_nemesis_damage     400                                   // oneshot 0 iken Nemesis vurusu",
"vex_assassin_damage    300                                   // oneshot 0 iken Assassin vurusu",
"vex_nemesis_vs_survivor 350                                  // Nemesis / Assassin'in Survivor ve Sniper'a vurusu",
"vex_special_dmg_cap    1500                                  // boss/nemesis/assassin tek mermi hasar tavani",
"vex_damage_per_ap      800                                   // zombiye verilen kac hasar = 1 AP",
"vex_knockback          1                                     // 1 = mermiler zombileri geri iter",
"vex_knockback_mult     0.75                                  // tum mermi geri tepme gucu carpani (1.0 = eski)",
"vex_armor_protect      1                                     // 1 = zirh bitmeden insan enfekte olmaz",
"vex_burn_damage_human  6                                     // yanan insanin saniyelik hasari",
"vex_burn_damage_zombie 35                                    // yanan zombinin saniyelik hasari",
"vex_zombie_speed_mult  1.0                                   // tum zombi hizlari carpani",
"vex_human_speed_mult   1.0                                   // tum insan hizlari carpani",
"vex_nemesis_speed      265                                   // Nemesis hizi",
"vex_assassin_speed     340                                   // Assassin hizi",
"vex_nemesis_gravity    0.5                                   // Nemesis yercekimi (1 = normal)",
"vex_assassin_gravity   0.45                                  // Assassin yercekimi",
"vex_speedrush_human    1.55                                  // Hiz Tutkusu: insan hiz carpani",
"vex_speedrush_zombie   1.45                                  // Hiz Tutkusu: zombi hiz carpani",
"vex_speedrush_fov      105                                   // Hiz Tutkusu: gorus acisi (90 = normal)",
"vex_special_leap_cooldown   6                                // Nemesis / Boss atilma bekleme (Assassin 2/3'u)",
"vex_nemesis_rage_time       5                                // [F] OFKE: +%25 hiz, %30 az hasar alir (sn)",
"vex_nemesis_rage_cooldown   25                               // Nemesis ofke yetenegi bekleme (sn)",
"vex_assassin_veil_time      4                                // [F] GOLGE PERDESI: neredeyse gorunmez + hizli (sn)",
"vex_assassin_veil_cooldown  25                               // Assassin gorunmezlik bekleme (sn)",
"vex_boss_hp 4500                                             // boss temel cani",
"vex_boss_hp_per_player 1500                                  // her oyuncu basina boss can artisi",
"vex_boss_damage        90                                    // boss pence hasari (delilik fazinda x1.25)",
"vex_boss_r_damage_mult 1.0                                   // [R] hasarlari carpani",
"vex_special_kill_xp    80                                    // Nemesis / Assassin indiren",
"vex_special_kill_ap    15                                    // ozel zombi oldurme odulu (AP)",
"vex_butcher_hook_damage   10                                 // kanca takilinca verilen hasar",
"vex_hunter_damage         15                                 // inis hasari",
"vex_charger_damage        20                                 // carpilan insana hasar",
"vex_arachne_damage        5                                  // ag hasari",
"vex_magma_pool_damage     6                                  // havuzdaki insana saniyede hasar (+ yanma)",
"vex_volt_damage           8                                  // elektrik hasari",
"vex_mimic_damage_mult     2.0                                // kiliktayken ilk vurus hasar carpani",
"vex_burrower_damage       15                                 // cikis hasari",
"vex_sporemother_hp        120                                // kese cani",
"vex_lm_damage          150                                   // oneshot 0 iken temas hasari (0.25 sn'de bir)",
"vex_lm_special_damage  600                                   // Nemesis / Assassin / Boss'a temas hasari (oldurmez)",
"vex_nade_fire_damage   80                                    // ates bombasi hasari",
"vex_nade_cluster_damage 45                                   // misket bombasi parca hasari",
"vex_sw_damage_mult 2.4                                       // OZEL SILAH HASARI: tum ozel silahlarin hasar carpani (vex_sw carpaninin USTUNE; 1.0 = eski, 5.3.1 = 3.0)",
"vex_boss_hpcard 1                                            // 1 = boss savasinda nisangahin ustunde resimli BOSS CAN BARI (yazili bar yerine)",
"",
"// ==============================================================================",
"// OZEL SILAHLAR VE MERMI",
"//   vex_sw <no> <AP> <seviye> <hasar carpani> <yedek mermi> <efekt> <R G B>",
"//   <sarjor> <zincir> <atis hizi> <geri tepme> | vex_gun p/s <no> <seviye>",
"//   <mermi> | vex_modewpn survivor/sniper <yuva> <silah> <hasar> <sarjor>",
"//   <yedek> <efekt>",
"// ==============================================================================",
"vex_modewpn survivor 1 weapon_m249   1.5    0  400 none      // Survivor / Sniper silahi: <mod> <yuva> <silah> <hasar> <sarjor> <yedek> <efekt>",
"vex_modewpn survivor 2 weapon_deagle 1.5    0  100 none      // Survivor / Sniper silahi: <mod> <yuva> <silah> <hasar> <sarjor> <yedek> <efekt>",
"vex_modewpn sniper   1 weapon_awp    5000   0  100 none      // Survivor / Sniper silahi: <mod> <yuva> <silah> <hasar> <sarjor> <yedek> <efekt>",
"vex_modewpn sniper   2 none                                  // Survivor / Sniper silahi: <mod> <yuva> <silah> <hasar> <sarjor> <yedek> <efekt>",
"vex_gun p 0  1   180                                         // AK-47",
"vex_gun p 1  1   180                                         // M4A1",
"vex_gun p 2  1   180                                         // FAMAS",
"vex_gun p 3  1   180                                         // Galil",
"vex_gun p 4  1   240                                         // MP5 Navy",
"vex_gun p 5  2   200                                         // UMP45",
"vex_gun p 6  3   200                                         // P90",
"vex_gun p 7  2   64                                          // M3",
"vex_gun p 8  4   64                                          // XM1014",
"vex_gun p 9  6   180                                         // AUG",
"vex_gun p 10 7   180                                         // SG552",
"vex_gun p 11 9   300                                         // M249",
"vex_gun p 12 12  60                                          // AWP",
"vex_gun p 13 14  120                                         // G3SG1",
"vex_gun s 0  1   100                                         // USP",
"vex_gun s 1  1   120                                         // Glock-18",
"vex_gun s 2  1   52                                          // P228",
"vex_gun s 3  2   70                                          // Desert Eagle",
"vex_gun s 4  3   120                                         // Dual Elites",
"vex_gun s 5  5   100                                         // Five-seveN",
"vex_sw 0 25 1 2 180 none 95 185 255 24 0 0.24 0.7            // OZEL SILAH 0 (Arbalest): <AP> <seviye> <hasar carpani> <yedek mermi> <efekt> <R G B> <sarjor> <zincir> <atis hizi> <geri tepme>",
"vex_sw 1 30 1 2.4 180 none 230 165 80 20 0 0.45 0.9          // OZEL SILAH 1 (Heaven Splitter): <AP> <seviye> <hasar carpani> <yedek mermi> <efekt> <R G B> <sarjor> <zincir> <atis hizi> <geri tepme>",
"vex_sw 2 35 1 1.7 240 none 240 185 60 40 0 0.11 0.65         // OZEL SILAH 2 (Quantum Horizon): <AP> <seviye> <hasar carpani> <yedek mermi> <efekt> <R G B> <sarjor> <zincir> <atis hizi> <geri tepme>",
"vex_sw 3 40 1 2.8 160 none 230 85 95 16 0 0.5 0.8            // OZEL SILAH 3 (Magnum Drill Chimera): <AP> <seviye> <hasar carpani> <yedek mermi> <efekt> <R G B> <sarjor> <zincir> <atis hizi> <geri tepme>",
"vex_sw 4 30 1 1.6 240 none 115 145 240 40 0 0.105 0.7        // OZEL SILAH 4 (Dark Knight): <AP> <seviye> <hasar carpani> <yedek mermi> <efekt> <R G B> <sarjor> <zincir> <atis hizi> <geri tepme>",
"vex_sw 5 35 1 1.35 300 none 85 225 250 60 0 0.075 0.5        // OZEL SILAH 5 (Infinity Laser Fist): <AP> <seviye> <hasar carpani> <yedek mermi> <efekt> <R G B> <sarjor> <zincir> <atis hizi> <geri tepme>",
"vex_sw_text 0 en ^"Arbalest^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 0 yazisi (en): ad + aciklama",
"vex_sw_text 0 tr ^"Arbalest^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 0 yazisi (tr): ad + aciklama",
"vex_sw_text 1 en ^"Heaven Splitter^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 1 yazisi (en): ad + aciklama",
"vex_sw_text 1 tr ^"Heaven Splitter^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 1 yazisi (tr): ad + aciklama",
"vex_sw_text 2 en ^"Quantum Horizon^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 2 yazisi (en): ad + aciklama",
"vex_sw_text 2 tr ^"Quantum Horizon^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 2 yazisi (tr): ad + aciklama",
"vex_sw_text 3 en ^"Magnum Drill Chimera^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 3 yazisi (en): ad + aciklama",
"vex_sw_text 3 tr ^"Magnum Drill Chimera^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 3 yazisi (tr): ad + aciklama",
"vex_sw_text 4 en ^"Dark Knight^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 4 yazisi (en): ad + aciklama",
"vex_sw_text 4 tr ^"Dark Knight^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 4 yazisi (tr): ad + aciklama",
"vex_sw_text 5 en ^"Infinity Laser Fist^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 5 yazisi (en): ad + aciklama",
"vex_sw_text 5 tr ^"Infinity Laser Fist^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 5 yazisi (tr): ad + aciklama",
"vex_sw 6 45 1 1.8 210 none 150 75 235 30 0 0.18 0.65         // OZEL SILAH 6 (Void Avenger): <AP> <seviye> <hasar carpani> <yedek mermi> <efekt> <R G B> <sarjor> <zincir> <atis hizi> <geri tepme>",
"vex_sw_text 6 en ^"Void Avenger^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 6 yazisi (en): ad + aciklama",
"vex_sw_text 6 tr ^"Void Avenger^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 6 yazisi (tr): ad + aciklama",
"vex_sw 7 40 1 1.45 300 none 220 175 90 60 0 0.11 0.65        // OZEL SILAH 7 (Dual Beretta Gunslinger): <AP> <seviye> <hasar carpani> <yedek mermi> <efekt> <R G B> <sarjor> <zincir> <atis hizi> <geri tepme>",
"vex_sw_text 7 en ^"Dual Beretta Gunslinger^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 7 yazisi (en): ad + aciklama",
"vex_sw_text 7 tr ^"Dual Beretta Gunslinger^" ^"Sag tik: mod degistir | Sol tik: ates^" // OZEL SILAH 7 yazisi (tr): ad + aciklama",
"vex_unlimited_bpammo 1                                       // 1 = herkeste sinirsiz yedek mermi (TUM mod/eventlerde), ozel silahlar haric",
"",
"// ==============================================================================",
"// MARKET ESYALARI",
"//   vex_item <no> <AP fiyat> <round limiti> <seviye> <deger>  (deger: can / sure",
"//   / miktar)",
"// ==============================================================================",
"vex_exchange_cost      100                                   // markette X AP -> 1 VC takasi",
"vex_item 0  12   3   1   100                                 // Ilk Yardim (can)",
"vex_item 1  10   2   1   200                                 // Zirh (zirh miktari)",
"vex_item 2  12   2   1   1                                   // Ates Bombasi (adet)",
"vex_item 3  12   2   1   1                                   // Buz Bombasi (adet)",
"vex_item 4  5    3   1   1                                   // Isaret Fisegi (adet)",
"vex_item 5  15   1   2   1                                   // Ekstra Ziplama - VIP (adet)",
"vex_item 6  10   1   1   55                                  // Yercekimi Botu (yercekimi %)",
"vex_item 7  12   1   1   12                                  // Hiz Serumu (+hiz %)",
"vex_item 8  35   1   3   0                                   // Sinirsiz Sarjor (-)",
"vex_item 9  45   1   4   20                                  // Hasar Guclendirici (+hasar %)",
"vex_item 10 50   1   2   0                                   // Diriltme Jetonu (-)",
"vex_item 11 40   1   1   0                                   // T-Virus Panzehiri (-) [ZOMBI]",
"vex_item 12 20   2   1   5                                   // Zombi Cinneti (sn) [ZOMBI]",
"vex_item 13 35   1   3   3                                   // Enfeksiyon Bombasi (roundda en fazla) [ZOMBI]",
"vex_item 14 15   2   1   1500                                // Mutajen (+can) [ZOMBI]",
"vex_item 15 12   1   2   20                                  // Ofke (+hasar %) [ZOMBI]",
"vex_item 16 10   3   1   0                                   // Hizli Yenilenme (-) [ZOMBI]",
"vex_item 17 18   1   3   20                                  // Kemik Zirh (hasar azaltma %) [ZOMBI]",
"vex_item 18 15   2   2   6                                   // Adrenalin Ignesi (sn)",
"vex_item 19 25   1   3   8                                   // Hayalet Pelerini (sn)",
"vex_item 20 8    1   1   0                                   // Gece Gorusu (-)",
"vex_item 21 40   1   4   2                                   // Enerji Kalkani (darbe sayisi)",
"vex_item 22 10   2   1   0                                   // Cephane Kutusu (-)",
"vex_item 23 15   2   1   6                                   // Zombi Kosusu (sn) [ZOMBI]",
"vex_item 24 20   1   2   6                                   // Golge Ortusu (sn) [ZOMBI]",
"vex_item 25 12   1   1   60                                  // Mutant Bacaklar (yercekimi %) [ZOMBI]",
"vex_item 26 25   1   3   80                                  // Yenilenme (can/sn) [ZOMBI]",
"vex_item 27 18   1   2   0                                   // Demir Durus (-) [ZOMBI]",
"",
"// ==============================================================================",
"// SINIFLAR VE MESLEKLER",
"//   vex_class <no> <can carpani> <hiz> <yercekimi> <geri tepme> <yetenek",
"//   bekleme> <seviye> | vex_job <no> <seviye>",
"// ==============================================================================",
"vex_class 0  1.0   270  0.80  1.00  15.0  1                  // Walker",
"vex_class 1  0.70  310  0.70  1.30  8.0   1                  // Runner",
"vex_class 2  1.80  235  1.00  0.40  14.0  1                  // Tank",
"vex_class 3  0.90  285  0.80  1.00  12.0  1                  // Banshee",
"vex_class 4  1.10  265  0.85  0.90  20.0  5                  // Leech",
"vex_class 5  0.80  295  0.75  1.10  18.0  8                  // Stalker",
"vex_class 6  1.00  260  0.90  0.90  16.0  12                 // Bomber",
"vex_class 7  1.05  270  0.80  0.90  18.0  16                 // Frost",
"vex_class 8  0.90  280  0.80  1.00  12.0  18                 // Spitter",
"vex_class 9  1.60  245  1.00  0.50  16.0  20                 // Hulk",
"vex_class 10 0.95  275  0.80  1.00  18.0  22                 // Voodoo",
"vex_class 11 0.75  300  0.70  1.20  9.0   25                 // Phantom",
"vex_class 12 1.35  255  0.90  0.60  16.0  3                  // Butcher / Kasap   [R] et kancasi",
"vex_class 13 0.85  300  0.70  1.10  12.0  6                  // Hunter / Avci     [R] atilma + sersemletme",
"vex_class 14 1.40  250  1.00  0.50  15.0  9                  // Charger / Boga    [R] hucum",
"vex_class 15 0.85  290  0.60  1.00  13.0  11                 // Arachne / Orumcek [R] ag atisi",
"vex_class 16 1.10  265  0.80  0.90  18.0  13                 // Magma             [R] lav izi (ates islemez)",
"vex_class 17 0.95  280  0.80  1.00  18.0  15                 // Volt              [R] EMP",
"vex_class 18 0.90  275  0.80  1.00  22.0  17                 // Mimic / Taklitci  [R] insan kiligi",
"vex_class 19 1.00  270  0.85  0.90  18.0  19                 // Burrower / Kostebek [R] yeraltina dalis",
"vex_class 20 0.90  280  0.80  1.00  17.0  21                 // Siren             [R] ninni (cekim)",
"vex_class 21 1.70  240  1.00  0.30  18.0  23                 // Bulwark / Kale    [R] tahkim",
"vex_class 22 1.00  265  0.80  1.00  15.0  26                 // Sporemother / Spor Ana [R] spor kesesi",
"vex_class 23 0.90  290  0.80  1.00  20.0  28                 // Nightmare / Kabus [R] dehset",
"vex_hunter_pounce_power   860                                // ileri atilma gucu",
"vex_hunter_pounce_up      330                                // yukari atilma gucu",
"vex_hunter_radius         70                                 // inis etki yaricapi (birim)",
"vex_hunter_stun           1.0                                // sersemletme suresi (sn)",
"vex_charger_time          1.5                                // hucum suresi (sn)",
"vex_charger_speed         650                                // hucum hizi (birim/sn)",
"vex_charger_push          550                                // savurma gucu",
"vex_charger_self_stun     0.5                                // duvara carpinca kendi sersemleme suresi (sn)",
"vex_arachne_web_speed     1100                               // ag mermisi hizi",
"vex_arachne_web_range     1000                               // ag menzili",
"vex_arachne_root          1.5                                // kok (hareketsiz) suresi (sn)",
"vex_arachne_slow          3.0                                // kokten sonra yavaslama suresi (sn)",
"vex_magma_trail_time      5                                  // lav izi suresi (sn)",
"vex_magma_pool_life       4                                  // her lav havuzunun omru (sn)",
"vex_magma_pool_radius     60                                 // lav havuzu yaricapi",
"vex_magma_fire_immune     1                                  // 1 = Magma ates hasari almaz",
"vex_volt_radius           350                                // EMP yaricapi",
"vex_volt_mine_off         6                                  // lazer mayinlarinin kapali kalma suresi (sn)",
"vex_volt_light_off        6                                  // fener / gece gorusu kilit suresi (sn)",
"vex_volt_slow             1.5                                // yavaslatma suresi (sn)",
"vex_mimic_time            10                                 // kilik suresi (sn)",
"vex_burrower_time         3                                  // yeraltinda kalma suresi (sn)",
"vex_burrower_speed        1.5                                // yeraltinda hiz carpani",
"vex_burrower_radius       220                                // cikis sok dalgasi yaricapi",
"vex_burrower_knockup      450                                // havaya firlatma gucu",
"vex_siren_radius          400                                // etki yaricapi",
"vex_siren_time            2.5                                // cekim suresi (sn)",
"vex_siren_pull            170                                // cekim hizi (birim/sn)",
"vex_sporemother_max       2                                  // ayni anda en fazla kese (fazlasi en eskiyi sondurur)",
"vex_sporemother_radius    120                                // tetiklenme yaricapi (patlama 1.4 kati)",
"vex_sporemother_poison    6                                  // zehir suresi (sn; saniyede 6 hasar)",
"vex_sporemother_life      60                                 // kesenin omru (sn)",
"vex_sporemother_slow      3.0                                // yavaslatma suresi (sn)",
"vex_job 0  1                                                 // Medic",
"vex_job 1  1                                                 // Heavy",
"vex_job 2  2                                                 // Scout",
"vex_job 3  3                                                 // Marksman",
"vex_job 4  4                                                 // Engineer",
"vex_job 5  5                                                 // Looter",
"vex_job 6  6                                                 // Gunner",
"vex_job 7  8                                                 // Demolitions",
"vex_job 8  10                                                // Sniper",
"vex_job 9  12                                                // Paratrooper",
"vex_job 10 14                                                // Pyro",
"vex_job 11 16                                                // Cryo",
"vex_job 12 18                                                // Vampire",
"vex_job 13 21                                                // Guardian",
"vex_job 14 24                                                // Berserker",
"vex_job 15 28                                                // Commander",
"vex_job 16 7                                                 // Juggernaut",
"vex_job 17 9                                                 // Ninja",
"vex_job 18 11                                                // Ghost",
"vex_job 19 13                                                // Grenadier",
"vex_job 20 15                                                // Hunter",
"vex_job 21 17                                                // Doctor",
"vex_job 22 20                                                // Gambler",
"vex_job 23 23                                                // Tactician",
"vex_job 24 26                                                // Lucky",
"vex_job 25 32                                                // Elite Soldier",
"",
"// ==============================================================================",
"// BOSSLAR",
"//   vex_boss_stat <boss> <can carpani> <hiz> <yercekimi> <R G B> |",
"//   vex_boss_skill <boss> <faz 1-3> <bekleme sn> <hasar> <yaricap>",
"// ==============================================================================",
"vex_boss_final_mult    1.5                                   // son round FINAL BOSS can carpani",
"vex_boss_ability_mult  1.0                                   // TUM boss yetenek hasarlari carpani (0.5 = yarisi)",
"vex_boss_phase2        60                                    // can % bunun altina inince FAZ 2 (yeni [R] yetenegi)",
"vex_boss_phase3        30                                    // can % bunun altina inince FAZ 3 = DELILIK (ULTI)",
"vex_boss_r_auto        12                                    // boss N sn [R] kullanmazsa (veya bot ise) yetenek kendiliginden (0 = kapali)",
"vex_boss_r_cooldown_mult 1.0                                 // [R] bekleme sureleri carpani",
"vex_boss_auto_abilities 1                                    // 1 = bossun otomatik (uyarili) saldirilari acik",
"vex_boss_stat 0  1.00  255  0.85  255 120   0                // Brute",
"vex_boss_stat 1  0.80  290  0.65  190 210 255                // Banshee",
"vex_boss_stat 2  1.15  260  0.85  160   0 255                // Overlord",
"vex_boss_stat 3  1.00  270  0.80  255  50   0                // Inferno",
"vex_boss_stat 4  0.90  300  0.60  120   0 190                // Reaper",
"vex_boss_stat 5  1.05  265  0.85    0 190 255                // Frostlord",
"vex_boss_stat 6  0.95  285  0.75  255 240  80                // Stormcaller",
"vex_boss_stat 7  1.10  275  0.80  110 255   0                // Hive Queen",
"vex_boss_stat 8  1.20  280  0.55  220   0 140                // Void",
"vex_boss_skill 0 1  9.0   35.0  320                          // Sismik Ezme (yaricap)",
"vex_boss_skill 0 2  13.0  40.0  110                          // Yer Yarigi (patlama yaricapi)",
"vex_boss_skill 0 3  24.0  15.0  230                          // Titan Ofkesi (dalga yaricapi, hasar/sn)",
"vex_boss_skill 1 1  9.0   25.0  650                          // Ses Mizragi (menzil)",
"vex_boss_skill 1 2  14.0  30.0  320                          // Hayalet Cigligi (ciglik yaricapi)",
"vex_boss_skill 1 3  26.0  10.0  1200                         // Agit (menzil, hasar/dalga)",
"vex_boss_skill 2 1  10.0  20.0  900                          // Kemik Hapsi (menzil)",
"vex_boss_skill 2 2  18.0  15.0  600                          // Lejyon (can emme yaricapi)",
"vex_boss_skill 2 3  24.0  35.0  250                          // Olum Novasi (halka genisligi)",
"vex_boss_skill 3 1  8.0   20.0  450                          // Alev Nefesi (menzil)",
"vex_boss_skill 3 2  14.0  45.0  140                          // Ates Sutunlari (sutun yaricapi)",
"vex_boss_skill 3 3  28.0  85.0  700                          // Supernova (patlama yaricapi)",
"vex_boss_skill 4 1  8.0   0.0   800                          // Golge Adimi (isinlanma menzili)",
"vex_boss_skill 4 2  16.0  6.0   600                          // Ruh Zincirleri (menzil, hasar/0.5sn)",
"vex_boss_skill 4 3  24.0  60.0  150                          // Olum Isareti (patlama yaricapi)",
"vex_boss_skill 5 1  8.0   18.0  900                          // Buz Parcalari (menzil)",
"vex_boss_skill 5 2  15.0  25.0  800                          // Buz Mezari (menzil)",
"vex_boss_skill 5 3  28.0  10.0  0                            // Mutlak Sifir (tum harita)",
"vex_boss_skill 6 1  9.0   8.0   170                          // Top Yildirim (carpma yaricapi, hasar/0.3sn)",
"vex_boss_skill 6 2  12.0  30.0  130                          // Yildirim Atilmasi (carpma yaricapi)",
"vex_boss_skill 6 3  28.0  35.0  140                          // Kasirga (yildirim yaricapi)",
"vex_boss_skill 7 1  8.0   20.0  150                          // Asit Tukurugu (havuz yaricapi)",
"vex_boss_skill 7 2  16.0  0.0   260                          // Zehir Bulutu (bulut yaricapi)",
"vex_boss_skill 7 3  26.0  30.0  180                          // Kulucka (patlama yaricapi)",
"vex_boss_skill 8 1  8.0   25.0  1000                         // Bosluk Oku (menzil)",
"vex_boss_skill 8 2  15.0  40.0  450                          // Tekillik (cekim yaricapi)",
"vex_boss_skill 8 3  28.0  8.0   600                          // Olay Ufku (cekim yaricapi, hasar/sn)",
"vex_boss_kill_xp       120                                   // boss'u indiren",
"vex_boss_kill_ap       25                                    // boss oldurme odulu (AP)",
"vex_boss_kill_vc       2                                     // boss oldurme odulu (VexCoin)",
"vex_boss_board_ap      ^"40 25 15^"                            // boss hasar tablosu 1. 2. 3. odulu",
"vex_bossbar_width 88                                         // boss can bari genisligi",
"vex_boss_idle_min         9                                  // ara sira hirlama: en az (sn)",
"vex_boss_idle_max         16                                 // ara sira hirlama: en cok (sn)",
"vex_boss_pain_cd 2.0                                         // aci sesi en az bu kadar arayla (sn) - PAIN / PAIN2 sirayla",
"vex_boss_attack_cd 1.6                                       // pence savururken saldiri kukremesi bekleme suresi (sn)",
"vex_boss_step_dist        120                                // boss adim sesi: bu kadar birim yurudukce bir adim (hiza gore)",
"",
"// ==============================================================================",
"// EVENTLER, ISIK VE HAVA",
"//   vex_env_event/mode/boss/calm <no> <isik a-z> <sis R> <G> <B> <yogunluk>",
"//   <hava 0 yok 1 yagmur 2 kar>",
"// ==============================================================================",
"vex_meteor_interval    9                                     // Meteor eventi: kac saniyede bir meteor dalgasi (2-60)",
"vex_meteor_count       1                                     // Meteor eventi: dalga basina meteor sayisi (1-4); insanin 96-220 birim onune/yanina duser",
"vex_airdrop_laser      1                                     // hava ikmalinden +1 lazer cikabilir",
"vex_airdrop            1                                     // 1 = ikmal kutusu dususu acik",
"vex_airdrop_every      70                                    // kac saniyede bir ikmal (Malzeme Dususu eventinde 20)",
"vex_airdrop_beacon     1                                     // 1 = gokyuzune uzanan ALTIN ISIK SUTUNU + parlama",
"vex_airdrop_compass    1                                     // 1 = insanlarin HUD'unda kutuya mesafe + yon",
"vex_airdrop_zombie_heal 300                                  // kutuyu kiran zombiye verilen can",
"vex_env                1                                     // 1 = ortam sistemi acik",
"vex_env_calm_random 0                                        // sakin roundlarda rastgele isik/hava",
"vex_weather 0                                                // hava durumu (0 kapali, 1 yagmur, 2 kar)",
"vex_env_event 0 m 0 0 0 0 0                                  // EVENT 0 (Normal): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 1 g 82 65 70 9 0                               // EVENT 1 (Kan Ayi): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 2 i 150 150 150 12 0                           // EVENT 2 (Yogun Sis): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 3 m 0 60 90 12 0                               // EVENT 3 (Hiz Tutkusu): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 4 k 40 20 80 12 0                              // EVENT 4 (Dusuk Yercekimi): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 5 l 90 40 0 12 0                               // EVENT 5 (Cift Hasar): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 6 f 65 70 86 10 0                              // EVENT 6 (Karanlik Gece): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 7 i 20 90 0 12 0                               // EVENT 7 (Salgin): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 8 m 0 0 0 0 0                                  // EVENT 8 (Malzeme Dususu): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 9 i 100 20 0 12 0                              // EVENT 9 (Delilik): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 10 n 0 80 40 10 0                              // EVENT 10 (Adrenalin): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 11 i 120 50 0 12 0                             // EVENT 11 (Meteor Yagmuru): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 12 i 30 60 0 12 0                              // EVENT 12 (Zombi Surusu): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 13 i 80 0 0 12 0                               // EVENT 13 (Titan Saati): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 14 n 120 100 20 12 0                           // EVENT 14 (Altin Hucumu): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 15 i 60 0 20 12 0                              // EVENT 15 (Vampir Gecesi): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 16 j 60 30 0 12 0                              // EVENT 16 (Kafa Avi): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 17 i 90 100 120 12 0                           // EVENT 17 (Firtina): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_event 18 b 0 0 0 18 0                                // Elektrik Kesintisi: tum round karanlik",
"vex_env_mode 0 d 24 34 48 14 0                               // MOD 0 (Enfeksiyon): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_mode 1 d 32 28 60 14 0                               // MOD 1 (Coklu Enfeksiyon): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_mode 2 g 68 74 79 8 0                                // MOD 2 (Nemesis): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_mode 3 f 65 65 82 12 0                               // MOD 3 (Assassin): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_mode 4 i 0 40 90 12 0                                // MOD 4 (Survivor): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_mode 5 i 0 60 30 12 0                                // MOD 5 (Sniper): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_mode 6 i 60 40 0 12 0                                // MOD 6 (Swarm): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_mode 7 i 60 0 80 12 0                                // MOD 7 (Plague): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_mode 8 i 120 30 0 12 0                               // MOD 8 (Armageddon): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_mode 9 0 0 0 0 0 0                                   // MOD 9 (Boss): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_boss 0 g 65 72 85 10 0                               // BOSS 0 (BRUTE): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_boss 1 g 65 72 85 10 0                               // BOSS 1 (BANSHEE): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_boss 2 g 65 72 85 10 0                               // BOSS 2 (OVERLORD): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_boss 3 g 65 72 85 10 0                               // BOSS 3 (INFERNO): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_boss 4 g 65 72 85 10 0                               // BOSS 4 (REAPER): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_boss 5 g 65 72 85 10 0                               // BOSS 5 (FROSTLORD): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_boss 6 g 65 72 85 10 0                               // BOSS 6 (STORMCALLER): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_boss 7 g 65 72 85 10 0                               // BOSS 7 (HIVE QUEEN): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_boss 8 g 65 72 85 10 0                               // BOSS 8 (VOID): <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_calm 0 h 70 82 88 8 0                                // sakin tur 0: <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_calm 1 i 90 50 30 12 0                               // sakin tur 1: <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_calm 2 i 0 0 30 12 0                                 // sakin tur 2: <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_calm 3 i 70 80 90 12 0                               // sakin tur 3: <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_calm 4 k 170 180 200 12 0                            // sakin tur 4: <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_env_calm 5 j 120 120 130 12 0                            // sakin tur 5: <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>",
"vex_blackout_light ^"b^"                                       // Elektrik Kesintisi roundu isik seviyesi (a = zifiri karanlik ... m = normal)",
"",
"// ==============================================================================",
"// BOMBALAR",
"//   Ates / buz / isik / enfeksiyon bombalari ve bomba modlari",
"// ==============================================================================",
"vex_nade_modes         1                                     // 1 = carpma / sensor / lazer tuzak / gudumlu / parcali aktif",
"vex_nade_fire_radius   260                                   // ates bombasi yaricapi",
"vex_nade_fire_burn     6                                     // tutusma suresi (sn)",
"vex_nade_frost_radius  260                                   // buz bombasi yaricapi",
"vex_nade_frost_time    3.0                                   // donma suresi",
"vex_nade_infect_radius 240                                   // zombi enfeksiyon bombasi yaricapi",
"vex_nade_flare_time    25                                    // isaret fisegi isik suresi",
"vex_nade_sensor_radius 170                                   // SENSOR: algilama yaricapi",
"vex_nade_sensor_arm    1.5                                   // SENSOR: yere oturduktan sonra kurulma suresi",
"vex_nade_sensor_life   60                                    // SENSOR / LAZER TUZAK: en fazla bekleme (sonra patlar)",
"vex_nade_laser_length  900                                   // LAZER TUZAK: isin uzunlugu",
"vex_nade_laser_arm     1.0                                   // LAZER TUZAK: yapistiktan sonra isin acilma suresi",
"vex_nade_homing_radius 750                                   // GUDUMLU: zombi arama yaricapi",
"vex_nade_cluster       4                                     // PARCALI: kucuk patlama sayisi",
"vex_nade_fx 1                                                // 1 = ates / buz / isik / enfeksiyon bombalarinda katmanli epik patlama efektleri",
"",
"// ==============================================================================",
"// LAZER MAYIN",
"//   Lazer mayin hasari, sayisi, menzili, isin stilleri",
"// ==============================================================================",
"vex_lm_enable          1                                     // 1 = lazer mayin acik",
"vex_lm_boss            0                                     // 0 = boss roundlarinda lazer YOK",
"vex_lm_per_round 2                                           // oyuncu basina round basi mayin",
"vex_lm_per_round_vip 2                                       // VIP round basi mayin",
"vex_lm_max 2                                                 // ayni anda en fazla mayin",
"vex_lm_max_vip 2                                             // VIP ayni anda en fazla mayin",
"vex_lm_oneshot         1                                     // 1 = isina degen zombi TEK ATISTA olur",
"vex_lm_health          600                                   // mayin cani (zombiler pence ile kirabilir)",
"vex_lm_kill_wear       100                                   // her oldurmede mayindan giden can",
"vex_lm_beam_wear       18                                    // oneshot 0 iken her temasta giden can",
"vex_lm_zombie_mult     3.0                                   // zombi pencesinin mayina carpani (nemesis / boss x2.5 daha)",
"vex_lm_plant_time      1.0                                   // kurma suresi (sn, V basili tutulur; 0 = aninda)",
"vex_lm_take_time       2.0                                   // sokme suresi sn (ilerleme cubugu; uzaklasma/nisan kacirma/hasar/olum iptal eder, 0 = aninda)",
"vex_lm_arm_time        1.5                                   // kurulduktan sonra isinin acilma suresi",
"vex_lm_plant_range     128                                   // onerilen kurma menzili; kod 256 ustunu reddeder",
"vex_lm_take_range      170                                   // C ile sokme menzili",
"vex_lm_max_range 600                                         // isinin azami boyu (birim); duvara ulasmazsa isin havada biter",
"vex_lm_block_modes     ^"nemesis assassin^"                    // lazer mayinin YASAK oldugu modlar",
"vex_lm_beam_width 14                                         // lazer isini kalinligi (5.3.2 dokusu: ince parlak cekirdek + yumusak isik hali)",
"vex_lm_color_mode 3                                          // lazer rengi: 3 = insan mavi / zombi yesil (nabizli), 2 = vex_lm_color, 1 = oyuncuya gore, 0 = mayin canina gore",
"vex_lm_color ^"65 180 235^"                                    // color_mode 2 icin R G B",
"vex_laser_prices ^"300 450 600 900^"                           // VexCoin lazer isinlari: Plazma / Kan / Toksik / Gokkusagi fiyatlari",
"",
"// ==============================================================================",
"// KOZMETIK VE VEXCOIN",
"//   vex_wing/pet/hat <no> ^"EN ad^" ^"TR ad^" <model> <VC> <vip>",
"//   <bone/head/back/follow> <x y z> <aci p y r> <olcek> <anim> <hiz> |",
"//   vex_cosmetic <kat> <no> <VC>",
"// ==============================================================================",
"vex_cosmetic 0 0 125                                         // Buz Izi",
"vex_cosmetic 0 1 150                                         // Toksik Iz",
"vex_cosmetic 0 2 175                                         // Kan Izi",
"vex_cosmetic 0 3 200                                         // Kraliyet Izi",
"vex_cosmetic 0 4 250                                         // Altin Iz",
"vex_cosmetic 0 5 350                                         // Gokkusagi Izi",
"vex_cosmetic 1 0 150                                         // Yildirim Carpmasi",
"vex_cosmetic 1 1 175                                         // Altin Patlama",
"vex_cosmetic 1 2 200                                         // Kan Cesmesi",
"vex_cosmetic 1 3 250                                         // Buz Kirilmasi",
"vex_cosmetic 1 4 300                                         // Bosluk Cokusu",
"vex_cosmetic 1 5 350                                         // Havai Fisek",
"vex_cosmetic 2 0 150                                         // Zehir Patlamasi",
"vex_cosmetic 2 1 200                                         // Golge",
"vex_cosmetic 2 2 250                                         // Kan Ayi",
"vex_cos_preview        10                                    // Vitrin: satin almadan once model oyuncunun onunde doner (sn, sadece o gorur), 0 = kapali",
"vex_cos_daily_deal     25                                    // Gunun firsati: her gun sirayla bir kanat / pet / sapka bu kadar yuzde indirimli, 0 = kapali",
"vex_cos_hide           1                                     // 1 = /kozmetik menusunde ^"digerlerininkini gizle^" secenegi (FPS icin), 0 = yok",
"vex_wing 1 ^"Ashen Angel^" ^"Kullu Melek^" models/vexmira/community/refresh/wings/angel.mdl 250 0 bone -3 0 -2 0 0 0 1 1 1.0 // KANAT 1: ^"EN ad^" ^"TR ad^" <model> <VC fiyat> <vip 0/1> <bone> <x y z> <aci p y r> <olcek> <animasyon> <hiz>",
"vex_wing 2 ^"Black Reaper^" ^"Kara Hasatci^" models/vexmira/community/refresh/wings/blackwing.mdl 250 0 bone -3 0 -2 0 0 0 1 1 1.0 // KANAT 2: ^"EN ad^" ^"TR ad^" <model> <VC fiyat> <vip 0/1> <bone> <x y z> <aci p y r> <olcek> <animasyon> <hiz>",
"vex_wing 3 ^"Butterfly Guard^" ^"Kelebek Muhafiz^" models/vexmira/community/refresh/wings/butterfly.mdl 250 0 bone -3 0 -2 0 0 0 1 1 1.0 // KANAT 3: ^"EN ad^" ^"TR ad^" <model> <VC fiyat> <vip 0/1> <bone> <x y z> <aci p y r> <olcek> <animasyon> <hiz>",
"vex_wing 4 ^"Demon Wings^" ^"Iblis Kanadi^" models/vexmira/community/refresh/wings/devil.mdl 250 0 bone -3 0 -2 0 0 0 1 1 1.0 // KANAT 4: ^"EN ad^" ^"TR ad^" <model> <VC fiyat> <vip 0/1> <bone> <x y z> <aci p y r> <olcek> <animasyon> <hiz>",
"vex_wing 5 ^"Phoenix Wings^" ^"Anka Kanadi^" models/vexmira/community/refresh/wings/phoenix.mdl 250 0 bone -3 0 -2 0 0 0 1 1 1.0 // KANAT 5: ^"EN ad^" ^"TR ad^" <model> <VC fiyat> <vip 0/1> <bone> <x y z> <aci p y r> <olcek> <animasyon> <hiz>",
"vex_wing 6 ^"Seraph Wings^" ^"Seraf Kanadi^" models/vexmira/community/refresh/wings/sfwing.mdl 250 0 bone -3 0 -2 0 0 0 1 1 1.0 // KANAT 6: ^"EN ad^" ^"TR ad^" <model> <VC fiyat> <vip 0/1> <bone> <x y z> <aci p y r> <olcek> <animasyon> <hiz>",
"vex_pet 1 ^"Cat Companion^" ^"Kedi Dost^" models/vexmira/community/refresh/pets/cat.mdl 200 0 follow -22 24 -36 0 0 0 1 0 1.0 // PET 1: ^"EN ad^" ^"TR ad^" <model> <VC fiyat> <vip 0/1> <follow> <x y z> <aci> <olcek> <anim> <hiz>",
"vex_pet 2 ^"Duckling^" ^"Ordek Yavrusu^" models/vexmira/community/refresh/pets/duck.mdl 200 0 follow -22 24 -36 0 0 0 1 0 1.0 // PET 2: ^"EN ad^" ^"TR ad^" <model> <VC fiyat> <vip 0/1> <follow> <x y z> <aci> <olcek> <anim> <hiz>",
"vex_pet 3 ^"Wolf Pup^" ^"Kurt Yavrusu^" models/vexmira/community/refresh/pets/wolf.mdl 250 0 follow -22 24 -36 0 0 0 1 0 1.0 // PET 3: ^"EN ad^" ^"TR ad^" <model> <VC fiyat> <vip 0/1> <follow> <x y z> <aci> <olcek> <anim> <hiz>",
"vex_pet 4 ^"Octo Buddy^" ^"Ahtapot Dost^" models/vexmira/community/refresh/pets/octopus.mdl 200 0 follow -22 24 -36 0 0 0 1 0 1.0 // PET 4: ^"EN ad^" ^"TR ad^" <model> <VC fiyat> <vip 0/1> <follow> <x y z> <aci> <olcek> <anim> <hiz>",
"vex_pet 5 ^"Shark Drone^" ^"Kopekbaligi^" models/vexmira/community/refresh/pets/shark.mdl 250 0 follow -22 24 -36 0 0 0 1 0 1.0 // PET 5: ^"EN ad^" ^"TR ad^" <model> <VC fiyat> <vip 0/1> <follow> <x y z> <aci> <olcek> <anim> <hiz>",
"vex_pet 6 ^"Cube Pet^" ^"Kare Dost^" models/vexmira/community/refresh/pets/cube.mdl 300 0 follow -22 24 -36 0 0 0 0.65 0 1.0 // PET 6: ^"EN ad^" ^"TR ad^" <model> <VC fiyat> <vip 0/1> <follow> <x y z> <aci> <olcek> <anim> <hiz>",
"vex_cos_follow 1                                             // 1 = kanat + sapka oyuncuya kemikle yapisik (gecikme / isinlanma yok)",
"",
"// ==============================================================================",
"// VIP",
"//   VIP / ELITE ayricaliklari",
"// ==============================================================================",
"vex_vip_contact ^"discord.gg/vexmira^"                         // VIP almak icin iletisim (menude gorunur)",
"vex_vip_bonus 10                                             // VIP ekstra odul %",
"vex_vip_discount       10                                    // VIP: market / ozel silah / kozmetik indirimi (yuzde)",
"vex_vip_armor 0                                              // VIP round basi zirh",
"vex_vip_round_vc       1                                     // Round sonu VIP'e Vex Coin (ELITE 2 kati), 0 = kapali",
"vex_vip_autopack 0                                           // VIP otomatik paket",
"vex_vip_daily_pct      50                                    // VIP: gunluk odul (AP + VC) +yuzde",
"vex_vip_spawnprot 0.0                                        // VIP dogma korumasi (sn)",
"vex_vip_vote_weight 1                                        // VIP oy agirligi",
"vex_vip_regun          1                                     // 1 = VIP her hayatta 1 kez bedava silah degistirebilir (/guns)",
"vex_vip_scoreboard     1                                     // 1 = skor tablosunda ^"VIP^" etiketi",
"vex_vip_killicon       1                                     // 1 = VIP oldurunce CSO killmark altinda ^"- VIP -^" rozeti",
"vex_vip_join_announce 1                                      // VIP girince duyuru",
"vex_vip_priority_msg   2                                     // Bos yer bu sayiya inince VIP girisinde ^"VIP onceligi^" mesaji (0 = kapali)",
"",
"// ==============================================================================",
"// HUD / CSO EKRAN / ARAYUZ",
"//   Ust skor paneli, CSO kartlari, can barlari, simgeler",
"// ==============================================================================",
"vex_hud_style 1                                              // HUD stili",
"vex_hud_top              -1                                  // -1 stile uy; 0 kapali; 1 yazi; 2 grafik (grafik karsiligi yoksa kisa yazi)",
"vex_hud_right            -1                                  // level/can/zirh/XP paneli: -1 stile uy; 0 kapali; 1 yazi; 2 grafik",
"vex_hud_mvp 1                                                // MVP bilgisi HUD da",
"vex_hud_xp               -1                                  // XP odulu/ilerleme: -1 stile uy; 0 kapali; 1 yazi; 2 grafik cubuk + kisa yazi",
"vex_hud_overhead 2                                           // kafa ustu bilgi stili",
"vex_hud_objective        -1                                  // gorev/ipuclari satiri: -1 stile uy; 0 kapali; 1 yazi; 2 grafik (grafik yoksa gizlenir)",
"vex_cso_style 1                                              // 1 = CSO resimli kart sistemi acik (0 = kapali)",
"vex_cso_notes 255                                            // hangi resimli kartlar acik (bit toplami): 1 kill 2 MVP 4 round 8 kazanma 16 boss/ozel round 32 son insan 64 seviye 128 ilk kan/boss oldu/enfekte/geri sayim. 255 = HEPSI",
"vex_cso_time 2.0                                             // kart ekranda kalma suresi (sn)",
"vex_cso_km_time           1.5                                // killmark suresi (sn, 0.5-5); yeni killmark eskisinin yerini alir",
"vex_cso_fov 89                                               // KART ICIN SART: 89 (90 olursa resimli kartlar gorunmez; kart istemcinin zoom nisangahi ile cizilir)",
"vex_cso_sound 0                                              // kart sesi",
"vex_cso_icons 1                                              // sag tarafta rol ikonu",
"vex_cso_bots              0                                  // gelistirici testi: 1 = botlara da gonder (normalde 0)",
"vex_cso_log               0                                  // gelistirici testi: 1 = her gosterim / geri yukleme amxx loguna yazilir, 2 = ayrica her animasyon karesi",
"vex_cso_anim              1                                  // 1 = animasyonlu bildirim (giris parlamasi, kayan isik / nabiz, cikista solma; kare basina kucuk mesaj), 0 = tek kare (daha az ag trafigi)",
"vex_overhead 1                                               // kafa ustu can bari / ikon",
"vex_overhead_self         0                                  // 1 = oyuncu kendi kafasinin ustundeki bari da gorur",
"vex_overhead_margin 14                                       // kafa ustu ikon yuksekligi",
"vex_overhead_gap 1.5                                         // ust uste gostergeler (bar -> boss amblemi -> ikon) arasi bosluk (birim)",
"vex_hpbar_width 38                                           // kucuk barin genisligi (Nemesis / Assassin / Alfa)",
"vex_head_icon_size 20                                        // kafa ustu ikon boyutu",
"vex_head_icons            31                                 // ikon bit maskesi: 1 VIP + 2 admin + 4 MVP + 8 son insan + 16 alfa (0 = kapali)",
"vex_radio52 1                                                // 1 = ozel telsiz sesleri acik",
"vex_radio52_interval 90                                      // rastgele telsiz konusmasi araligi (sn)",
"vex_topboard 1                                               // UST SKOR PANELI (CSO tarzi): 1 = acik  [INSAN galibiyet/canli]  TUR + sure + mod  [ZOMBI galibiyet/canli]",
"vex_topboard_pad 44                                          // panelde yan bloklarin ortadan uzakligi (bosluk sayisi). Yazilar ust uste binerse buyut, cok aciksa kucult (10-60)",
"vex_topboard_y 0.01                                          // panelin ekrandaki yuksekligi (0.0 = en ust, 0.05 = biraz asagi)",
"vex_radio_text 1                                             // 1 = ozel telsiz sesi calinca sohbete gercekci telsiz metni yazilir (TR/EN, oyuncunun diline gore)",
"",
"// ==============================================================================",
"// SES VE MUZIK",
"//   Ses dongu korumasi, meme sesleri, radyo",
"// ==============================================================================",
"vex_sound_loopguard    1                                     // 1 = DONGULU wav'lar otomatik durdurulur / spk ile calinmaz",
"vex_sound_loop_max     3.0                                   // dongulu ses en fazla kac sn calsin",
"vex_six_tracer_every 6                                       // iz mermisi sikligi",
"vex_meme_cooldown 12.0                                       // meme sesi bekleme (sn)",
"vex_ambience_volume 0.55                                     // ambiyans muzik/ses seviyesi (0.05 - 1.0)",
"vex_ambience_restart 120                                     // ambiyans kac saniyede bir tazelenir (parcalar zaten kendi kendine doner; baglanan / sesi kesilen oyuncu icin)",
"",
"// ==============================================================================",
"// GOREV / ODUL / SEVIYE",
"//   vex_quest <no> <hedef> <XP> <AP> | kazanma odulleri",
"// ==============================================================================",
"vex_kill_ap            2                                     // zombi oldurme AP",
"vex_kill_xp            8                                     // zombi oldurme XP (ALFA zombi x2.5)",
"vex_win_human_xp       25                                    // insanlar kazaninca (boss / ozel modda katlanir)",
"vex_win_human_ap       5                                     // insanlar kazaninca AP",
"vex_win_zombie_xp      15                                    // zombiler kazaninca",
"vex_win_zombie_ap      4                                     // zombiler kazaninca AP",
"vex_daily_ap           20                                    // gunluk odul taban AP (+10 / seri gunu)",
"vex_achievement_ap     25                                    // basarim odulu",
"vex_achievement_vc     2                                     // basarim odulu (VC)",
"vex_perk_cost_step 25                                        // perk maliyeti = (seviye + 1) * bu deger VC",
"vex_quests             1                                     // 1 = her round herkese kucuk bir gorev",
"vex_quest 0  3     40   10                                   // 3 zombi oldur",
"vex_quest 1  6     80   20                                   // 6 zombi oldur",
"vex_quest 2  2500  40   10                                   // 2500 hasar ver",
"vex_quest 3  6000  80   20                                   // 6000 hasar ver",
"vex_quest 4  2     50   12                                   // 2 headshot",
"vex_quest 5  1     30   8                                    // 1 insan enfekte et",
"vex_quest 6  3     80   20                                   // 3 insan enfekte et",
"vex_quest 7  1     45   12                                   // Roundu insan olarak kazan",
"",
"// ==============================================================================",
"// DIGER AYARLAR",
"//   Yukaridaki gruplara girmeyen ayarlar",
"// ==============================================================================",
"vex_infect_ap          3                                     // enfekte etme AP",
"vex_infect_xp          10                                    // enfekte etme XP",
"vex_headshot_ap        1                                     // headshot ile oldurme ek AP (Kafa Avi eventinde x3)",
"vex_mvp_ap             10                                    // round MVP odulu",
"vex_mvp_vc             1                                     // MVP odulu (VC)",
"vex_evolve             3                                     // bir roundda kac enfeksiyonla ALFA ZOMBI olunur (0 = kapali)",
"vex_combo_time            6.0                                // combo penceresi (sn, 2-15): bu sure icinde gelen oldurmeler DOUBLE / TRIPLE / MULTI / MEGA KILL sayilir",
"vex_bot_abilities         1                                  // 1 = bot zombiler yakinda gorunen insan varken yeteneklerini kendiliginden kullanir",
"vex_butcher_hook_speed    1400                               // kanca ucus hizi (birim/sn)",
"vex_butcher_hook_range    900                                // kancanin en uzak menzili (birim)",
"vex_butcher_pull_speed    600                                // insanin cekilme hizi (birim/sn)",
"vex_butcher_pull_time     1.2                                // en uzun cekme suresi (sn); gorus kesilince / 60 birime gelince biter",
"vex_bulwark_time          5                                  // tahkim suresi (sn)",
"vex_bulwark_reduce        50                                 // hasar azaltma (%)",
"vex_bulwark_reflect       25                                 // yansitilan hasar (%; vurus basina en fazla 60)",
"vex_nightmare_radius      450                                // etki yaricapi",
"vex_nightmare_blind       2.5                                // karartma suresi (sn)",
"vex_nightmare_boost       3                                  // Kabus hizlanma suresi (sn)",
"vex_nightmare_speed       1.35                               // hizlanma carpani",
"vex_debug_dirs         0                                     // gelistirici testi (0 birak)",
"vex_give_nades         ^"abc^"                                 // HER ROUND her insana: a = ates (HE), b = buz (duman), c = isaret fisegi",
"vex_join_messages      1                                     // baglaniyor / katildi / ayrildi mesajlari",
"vex_afk_time           120                                   // N sn hic kipirdamayan oyuncu (0 = kapali)",
"vex_afk_action         1                                     // 1 = izleyiciye al, 2 = sunucudan at",
"vex_elite_bonus 15                                           // ELITE ekstra odul %",
"vex_elite_discount     20                                    // ELITE indirimi (yuzde)",
"vex_elite_armor 0                                            // ELITE zirh",
"vex_elite_daily_pct    100                                   // ELITE: gunluk odul +yuzde",
"vex_live_chatter       0                                     // 1 = otomatik ^"canli yorum^" chat mesajlari",
"vex_auto_join_humans 1                                       // 1 = yeni oyuncuyu takim dolu/balance mesaji olmadan CT'ye al",
"humans_join_team ^"CT^"                                        // otomatik katilimda gidilecek takim (zombiye donusmeyi Vexmira yonetir)",
"amx_language ^"en^"                                            // varsayilan dil (en / tr)",
"amx_client_languages 1                                       // oyuncu kendi dilini secebilir",
"vex_connection_log 1                                         // baglanma / ayrilma kaydi",
"vex_auto_hitbox 1                                            // 1 = boyu uzun modellerde (CSO zombileri, dev bosslar) vurus kutusu modele gore otomatik buyur",
"",
"// ==============================================================================",
"// KAYNAKLAR (vex_res)",
"//   Model / ses / sprite yollari. Degisiklik harita degisiminde gecerli olur.",
"//   Bos deger ^"^" = varsayilan / kapali.",
"// ==============================================================================",
"",
"// ---- KAYNAK: GOKYUZU / ATMOSFER ---------------------------------------------",
"vex_res AMBIENT ^"^"                                           // ambient (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res SKY_MODE ^"3^"                                         // 0 = haritanin kendi gokyuzu, 1 = rastgele, 2 = ilk, 3 = her round sonraki (rotasyon)",
"vex_res SKY_LIST ^"vexmira_blood vexmira_toxic vexmira_void vexmira_inferno vexmira_eclipse vexmira_deadlight^" // gfx/env/<ad>up.tga ... 6 yuz; oyunculara otomatik indirilir",
"vex_res AMBIENT_BOSS0 ^"sound/vexmira/amb532/boss.wav^"        // ambiyans: boss 0 roundu",
"vex_res AMBIENT_BOSS1 ^"sound/vexmira/amb532/boss.wav^"        // ambiyans: boss 1 roundu",
"vex_res AMBIENT_BOSS2 ^"sound/vexmira/amb532/boss.wav^"        // ambiyans: boss 2 roundu",
"vex_res AMBIENT_BOSS3 ^"sound/vexmira/amb532/boss.wav^"        // ambiyans: boss 3 roundu",
"vex_res AMBIENT_BOSS4 ^"sound/vexmira/amb532/boss.wav^"        // ambiyans: boss 4 roundu",
"vex_res AMBIENT_BOSS5 ^"sound/vexmira/amb532/boss.wav^"        // ambiyans: boss 5 roundu",
"vex_res AMBIENT_BOSS6 ^"sound/vexmira/amb532/boss.wav^"        // ambiyans: boss 6 roundu",
"vex_res AMBIENT_BOSS7 ^"sound/vexmira/amb532/boss.wav^"        // ambiyans: boss 7 roundu",
"vex_res AMBIENT_BOSS8 ^"sound/vexmira/amb532/boss.wav^"        // ambiyans: boss 8 roundu",
"vex_res AMBIENT_MODE0 ^"sound/vexmira/amb532/calm.wav^"        // ambiyans: Enfeksiyon roundu (calm/tension/hunt/hope/storm/frost/boss/chaos ya da kendi wav dosyan; mono 22kHz alti; ^"^" = sessiz)",
"vex_res AMBIENT_MODE1 ^"sound/vexmira/amb532/tension.wav^"     // ambiyans: Coklu roundu (calm/tension/hunt/hope/storm/frost/boss/chaos ya da kendi wav dosyan; mono 22kHz alti; ^"^" = sessiz)",
"vex_res AMBIENT_MODE2 ^"sound/vexmira/amb532/hunt.wav^"        // ambiyans: Nemesis roundu (calm/tension/hunt/hope/storm/frost/boss/chaos ya da kendi wav dosyan; mono 22kHz alti; ^"^" = sessiz)",
"vex_res AMBIENT_MODE3 ^"sound/vexmira/amb532/hunt.wav^"        // ambiyans: Assassin roundu (calm/tension/hunt/hope/storm/frost/boss/chaos ya da kendi wav dosyan; mono 22kHz alti; ^"^" = sessiz)",
"vex_res AMBIENT_MODE4 ^"sound/vexmira/amb532/hope.wav^"        // ambiyans: Survivor roundu (calm/tension/hunt/hope/storm/frost/boss/chaos ya da kendi wav dosyan; mono 22kHz alti; ^"^" = sessiz)",
"vex_res AMBIENT_MODE5 ^"sound/vexmira/amb532/hope.wav^"        // ambiyans: Sniper roundu (calm/tension/hunt/hope/storm/frost/boss/chaos ya da kendi wav dosyan; mono 22kHz alti; ^"^" = sessiz)",
"vex_res AMBIENT_MODE6 ^"sound/vexmira/amb532/tension.wav^"     // ambiyans: Swarm roundu (calm/tension/hunt/hope/storm/frost/boss/chaos ya da kendi wav dosyan; mono 22kHz alti; ^"^" = sessiz)",
"vex_res AMBIENT_MODE7 ^"sound/vexmira/amb532/tension.wav^"     // ambiyans: Plague roundu (calm/tension/hunt/hope/storm/frost/boss/chaos ya da kendi wav dosyan; mono 22kHz alti; ^"^" = sessiz)",
"vex_res AMBIENT_MODE8 ^"sound/vexmira/amb532/chaos.wav^"       // ambiyans: Armageddon roundu (calm/tension/hunt/hope/storm/frost/boss/chaos ya da kendi wav dosyan; mono 22kHz alti; ^"^" = sessiz)",
"vex_res AMBIENT_MODE9 ^"sound/vexmira/amb532/boss.wav^"        // ambiyans: Boss roundu (calm/tension/hunt/hope/storm/frost/boss/chaos ya da kendi wav dosyan; mono 22kHz alti; ^"^" = sessiz)",
"vex_res AMBIENT_EVENT0 ^"sound/vexmira/amb532/calm.wav^"       // ambiyans: Normal eventi",
"vex_res AMBIENT_EVENT1 ^"sound/vexmira/amb532/storm.wav^"      // ambiyans: Kan Ayi eventi",
"vex_res AMBIENT_EVENT2 ^"sound/vexmira/amb532/frost.wav^"      // ambiyans: Yogun Sis eventi",
"vex_res AMBIENT_EVENT3 ^"sound/vexmira/amb532/tension.wav^"    // ambiyans: Hiz eventi",
"vex_res AMBIENT_EVENT4 ^"sound/vexmira/amb532/hope.wav^"       // ambiyans: Dusuk Yercekimi eventi",
"vex_res AMBIENT_EVENT5 ^"sound/vexmira/amb532/tension.wav^"    // ambiyans: Cift Hasar eventi",
"vex_res AMBIENT_EVENT6 ^"sound/vexmira/amb532/frost.wav^"      // ambiyans: Karanlik Gece eventi",
"vex_res AMBIENT_EVENT7 ^"sound/vexmira/amb532/tension.wav^"    // ambiyans: Salgin eventi",
"vex_res AMBIENT_EVENT8 ^"sound/vexmira/amb532/calm.wav^"       // ambiyans: Malzeme eventi",
"vex_res AMBIENT_EVENT9 ^"sound/vexmira/amb532/chaos.wav^"      // ambiyans: Delilik eventi",
"vex_res AMBIENT_EVENT10 ^"sound/vexmira/amb532/tension.wav^"   // ambiyans: Adrenalin eventi",
"vex_res AMBIENT_EVENT11 ^"sound/vexmira/amb532/chaos.wav^"     // ambiyans: Meteor eventi",
"vex_res AMBIENT_EVENT12 ^"sound/vexmira/amb532/chaos.wav^"     // ambiyans: Zombi Surusu eventi",
"vex_res AMBIENT_EVENT13 ^"sound/vexmira/amb532/chaos.wav^"     // ambiyans: Titan eventi",
"vex_res AMBIENT_EVENT14 ^"sound/vexmira/amb532/hope.wav^"      // ambiyans: Altin eventi",
"vex_res AMBIENT_EVENT15 ^"sound/vexmira/amb532/frost.wav^"     // ambiyans: Vampir Gecesi eventi",
"vex_res AMBIENT_EVENT16 ^"sound/vexmira/amb532/hunt.wav^"      // ambiyans: Kafa Avi eventi",
"vex_res AMBIENT_EVENT17 ^"sound/vexmira/amb532/storm.wav^"     // ambiyans: Firtina eventi",
"vex_res AMBIENT_EVENT18 ^"sound/vexmira/amb532/frost.wav^"     // ambiyans: Elektrik Kesintisi eventi",
"vex_res SKY_PER_MAP ^"3^"                                      // bir haritada donen gokyuzu sayisi (her harita sonraki 3 lu gruba gecer; indirme limiti icin)",
"",
"// ---- KAYNAK: ZOMBI SESLERI VE MODELLERI -------------------------------------",
"vex_res ZOMBIE_INFECT ^"zombie_plague/zombie_infec1.wav|zombie_plague/zombie_infec2.wav^" // insan zombiye donusunce",
"vex_res ZOMBIE_PAIN ^"zombie_plague/zombie_pain1.wav|zombie_plague/zombie_pain2.wav|zombie_plague/zombie_pain3.wav|zombie/zo_pain1.wav^" // zombi hasar alinca (sinifa ozel yoksa)",
"vex_res ZOMBIE_DIE ^"zombie_plague/zombie_die1.wav|zombie_plague/zombie_die2.wav|zombie_plague/zombie_die3.wav^" // zombi olunce",
"vex_res ZOMBIE_IDLE ^"^"                                       // zombie idle (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res ZOMBIE_SLASH ^"zombie/claw_miss1.wav|zombie/claw_miss2.wav^" // pence havaya",
"vex_res ZOMBIE_HIT ^"zombie/claw_strike1.wav|zombie/claw_strike2.wav|zombie/claw_strike3.wav^" // pence ile vurus (| ile birden fazla ses: her vurusta rastgele biri)",
"vex_res ZOMBIE_STAB ^"zombie/claw_strike2.wav|zombie/claw_strike3.wav^" // agir pence (sag tik) vurusu",
"vex_res ZOMBIE_HITWALL ^"zombie/claw_miss2.wav|zombie/claw_miss1.wav^" // pence duvara",
"vex_res ABILITY_BURST ^"vexmira/skill532/burst.wav^"           // zombi yetenegi sesi: patlama (5.3.2 ozel ses; eskiden hepsi ayni silah sesiydi)",
"vex_res ABILITY_LEAP ^"vexmira/skill532/leap.wav^"             // zombi yetenegi sesi: sicrama (5.3.2 ozel ses; eskiden hepsi ayni silah sesiydi)",
"vex_res ABILITY_SHIELD ^"vexmira/skill532/shield.wav^"         // zombi yetenegi sesi: kemik kalkan (5.3.2 ozel ses; eskiden hepsi ayni silah sesiydi)",
"vex_res ABILITY_SCREAM ^"vexmira/arena51/world/ability.wav^"   // ses: ability scream (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ABILITY_DRAIN ^"vexmira/skill532/drain.wav^"           // zombi yetenegi sesi: can emme (5.3.2 ozel ses; eskiden hepsi ayni silah sesiydi)",
"vex_res ABILITY_CLOAK ^"vexmira/skill532/cloak.wav^"           // zombi yetenegi sesi: gorunmezlik (5.3.2 ozel ses; eskiden hepsi ayni silah sesiydi)",
"vex_res ABILITY_TOXIC ^"vexmira/skill532/toxic.wav^"           // zombi yetenegi sesi: zehir puskurtme (5.3.2 ozel ses; eskiden hepsi ayni silah sesiydi)",
"vex_res ABILITY_FROST ^"vexmira/skill532/frost.wav^"           // zombi yetenegi sesi: buz patlamasi (5.3.2 ozel ses; eskiden hepsi ayni silah sesiydi)",
"vex_res ZOMBIE_ACID ^"weapons/janus7_change1.wav^"             // ses: zombie acid (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ZOMBIE_SHOCK ^"zombie_plague/thunder1.wav^"            // ses: zombie shock (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ZOMBIE_HEAL ^"weapons/janus7_change1.wav^"             // ses: zombie heal (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ZOMBIE_BLINK ^"weapons/janus7_change1.wav^"            // ses: zombie blink (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ZOMBIE_WIN ^"vexmira/arena51/world/zombie_win.wav^"    // ses: zombie win (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res Z0_MODEL ^"z4_heavy^"                                  // ZOMBI SINIFI 0 (Walker): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z0_CLAW ^"models/vexmira/community/claws/classic.mdl^" // ZOMBI SINIFI 0 (Walker): el / pence modeli",
"vex_res Z0_IDLE ^"^"                                           // ZOMBI SINIFI 0 (Walker): bekleme / homurtu sesi",
"vex_res Z0_ABILITY ^"vexmira/arena51/classes/0.wav^"           // ZOMBI SINIFI 0 (Walker): yetenek (R) sesi",
"vex_res Z1_MODEL ^"zombie_source^"                             // ZOMBI SINIFI 1 (Runner): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z1_CLAW ^"models/vexmira/community/claws/classic.mdl^" // ZOMBI SINIFI 1 (Runner): el / pence modeli",
"vex_res Z1_IDLE ^"^"                                           // ZOMBI SINIFI 1 (Runner): bekleme / homurtu sesi",
"vex_res Z1_ABILITY ^"vexmira/arena51/classes/1.wav^"           // ZOMBI SINIFI 1 (Runner): yetenek (R) sesi",
"vex_res Z2_MODEL ^"cso_heavy^"                                 // ZOMBI SINIFI 2 (Tank): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z2_CLAW ^"models/vexmira/community/claws/heavy.mdl^"   // ZOMBI SINIFI 2 (Tank): el / pence modeli",
"vex_res Z2_IDLE ^"^"                                           // ZOMBI SINIFI 2 (Tank): bekleme / homurtu sesi",
"vex_res Z2_ABILITY ^"vexmira/arena51/classes/2.wav^"           // ZOMBI SINIFI 2 (Tank): yetenek (R) sesi",
"vex_res Z3_MODEL ^"zombie_witch2^"                             // ZOMBI SINIFI 3 (Banshee): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z3_CLAW ^"models/vexmira/community/claws/classic.mdl^" // ZOMBI SINIFI 3 (Banshee): el / pence modeli",
"vex_res Z3_IDLE ^"^"                                           // ZOMBI SINIFI 3 (Banshee): bekleme / homurtu sesi",
"vex_res Z3_ABILITY ^"vexmira/arena51/classes/3.wav^"           // ZOMBI SINIFI 3 (Banshee): yetenek (R) sesi",
"vex_res Z4_MODEL ^"heal_zombi_origin^"                         // ZOMBI SINIFI 4 (Leech): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z4_CLAW ^"models/vexmira/community/claws/classic.mdl^" // ZOMBI SINIFI 4 (Leech): el / pence modeli",
"vex_res Z4_IDLE ^"^"                                           // ZOMBI SINIFI 4 (Leech): bekleme / homurtu sesi",
"vex_res Z4_ABILITY ^"vexmira/arena51/classes/4.wav^"           // ZOMBI SINIFI 4 (Leech): yetenek (R) sesi",
"vex_res Z5_MODEL ^"vex_scary^"                                 // ZOMBI SINIFI 5 (Stalker): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z5_CLAW ^"models/vexmira/community/claws/scary.mdl^"   // ZOMBI SINIFI 5 (Stalker): el / pence modeli",
"vex_res Z5_IDLE ^"^"                                           // ZOMBI SINIFI 5 (Stalker): bekleme / homurtu sesi",
"vex_res Z5_ABILITY ^"vexmira/arena51/classes/5.wav^"           // ZOMBI SINIFI 5 (Stalker): yetenek (R) sesi",
"vex_res Z6_MODEL ^"deimos_zombi_host^"                         // ZOMBI SINIFI 6 (Bomber): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z6_CLAW ^"models/vexmira/community/claws/heavy.mdl^"   // ZOMBI SINIFI 6 (Bomber): el / pence modeli",
"vex_res Z6_IDLE ^"^"                                           // ZOMBI SINIFI 6 (Bomber): bekleme / homurtu sesi",
"vex_res Z6_ABILITY ^"vexmira/arena51/classes/6.wav^"           // ZOMBI SINIFI 6 (Bomber): yetenek (R) sesi",
"vex_res Z7_MODEL ^"hev_zombie^"                                // ZOMBI SINIFI 7 (Frost): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z7_CLAW ^"models/vexmira/community/claws/classic.mdl^" // ZOMBI SINIFI 7 (Frost): el / pence modeli",
"vex_res Z7_IDLE ^"^"                                           // ZOMBI SINIFI 7 (Frost): bekleme / homurtu sesi",
"vex_res Z7_ABILITY ^"vexmira/arena51/classes/7.wav^"           // ZOMBI SINIFI 7 (Frost): yetenek (R) sesi",
"vex_res Z8_MODEL ^"deimos_zombi_host^"                         // ZOMBI SINIFI 8 (Spitter): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z8_CLAW ^"models/vexmira/community/claws/heavy.mdl^"   // ZOMBI SINIFI 8 (Spitter): el / pence modeli",
"vex_res Z8_IDLE ^"^"                                           // ZOMBI SINIFI 8 (Spitter): bekleme / homurtu sesi",
"vex_res Z8_ABILITY ^"vexmira/arena51/classes/8.wav^"           // ZOMBI SINIFI 8 (Spitter): yetenek (R) sesi",
"vex_res Z9_MODEL ^"l4d_tank^"                                  // ZOMBI SINIFI 9 (Hulk): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z9_CLAW ^"models/vexmira/community/claws/heavy.mdl^"   // ZOMBI SINIFI 9 (Hulk): el / pence modeli",
"vex_res Z9_IDLE ^"^"                                           // ZOMBI SINIFI 9 (Hulk): bekleme / homurtu sesi",
"vex_res Z9_ABILITY ^"vexmira/arena51/classes/9.wav^"           // ZOMBI SINIFI 9 (Hulk): yetenek (R) sesi",
"vex_res Z10_MODEL ^"heal_zombi_origin^"                        // ZOMBI SINIFI 10 (Voodoo): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z10_CLAW ^"models/vexmira/community/claws/classic.mdl^" // ZOMBI SINIFI 10 (Voodoo): el / pence modeli",
"vex_res Z10_IDLE ^"^"                                          // ZOMBI SINIFI 10 (Voodoo): bekleme / homurtu sesi",
"vex_res Z10_ABILITY ^"vexmira/arena51/classes/10.wav^"         // ZOMBI SINIFI 10 (Voodoo): yetenek (R) sesi",
"vex_res Z11_MODEL ^"vex_scary^"                                // ZOMBI SINIFI 11 (Phantom): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z11_CLAW ^"models/vexmira/community/claws/scary.mdl^"  // ZOMBI SINIFI 11 (Phantom): el / pence modeli",
"vex_res Z11_IDLE ^"^"                                          // ZOMBI SINIFI 11 (Phantom): bekleme / homurtu sesi",
"vex_res Z11_ABILITY ^"vexmira/arena51/classes/11.wav^"         // ZOMBI SINIFI 11 (Phantom): yetenek (R) sesi",
"vex_res Z12_MODEL ^"cso_heavy^"                                // ZOMBI SINIFI 12 (Kasap): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z12_CLAW ^"models/vexmira/community/claws/heavy.mdl^"  // ZOMBI SINIFI 12 (Kasap): el / pence modeli",
"vex_res Z12_IDLE ^"^"                                          // ZOMBI SINIFI 12 (Kasap): bekleme / homurtu sesi",
"vex_res Z12_ABILITY ^"vexmira/arena51/classes/12.wav^"         // ZOMBI SINIFI 12 (Kasap): yetenek (R) sesi",
"vex_res Z13_MODEL ^"vex_scary^"                                // ZOMBI SINIFI 13 (Avci): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z13_CLAW ^"models/vexmira/community/claws/scary.mdl^"  // ZOMBI SINIFI 13 (Avci): el / pence modeli",
"vex_res Z13_IDLE ^"^"                                          // ZOMBI SINIFI 13 (Avci): bekleme / homurtu sesi",
"vex_res Z13_ABILITY ^"vexmira/arena51/classes/13.wav^"         // ZOMBI SINIFI 13 (Avci): yetenek (R) sesi",
"vex_res Z14_MODEL ^"deimos_zombi_host^"                        // ZOMBI SINIFI 14 (Boga): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z14_CLAW ^"models/vexmira/community/claws/heavy.mdl^"  // ZOMBI SINIFI 14 (Boga): el / pence modeli",
"vex_res Z14_IDLE ^"^"                                          // ZOMBI SINIFI 14 (Boga): bekleme / homurtu sesi",
"vex_res Z14_ABILITY ^"vexmira/arena51/classes/14.wav^"         // ZOMBI SINIFI 14 (Boga): yetenek (R) sesi",
"vex_res Z15_MODEL ^"zombie_witch2^"                            // ZOMBI SINIFI 15 (Orumcek): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z15_CLAW ^"models/vexmira/community/claws/classic.mdl^" // ZOMBI SINIFI 15 (Orumcek): el / pence modeli",
"vex_res Z15_IDLE ^"^"                                          // ZOMBI SINIFI 15 (Orumcek): bekleme / homurtu sesi",
"vex_res Z15_ABILITY ^"vexmira/arena51/classes/15.wav^"         // ZOMBI SINIFI 15 (Orumcek): yetenek (R) sesi",
"vex_res Z16_MODEL ^"deimos_zombi_host^"                        // ZOMBI SINIFI 16 (Magma): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z16_CLAW ^"models/vexmira/community/claws/heavy.mdl^"  // ZOMBI SINIFI 16 (Magma): el / pence modeli",
"vex_res Z16_IDLE ^"^"                                          // ZOMBI SINIFI 16 (Magma): bekleme / homurtu sesi",
"vex_res Z16_ABILITY ^"vexmira/arena51/classes/16.wav^"         // ZOMBI SINIFI 16 (Magma): yetenek (R) sesi",
"vex_res Z17_MODEL ^"hev_zombie^"                               // ZOMBI SINIFI 17 (Volt): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z17_CLAW ^"models/vexmira/community/claws/classic.mdl^" // ZOMBI SINIFI 17 (Volt): el / pence modeli",
"vex_res Z17_IDLE ^"^"                                          // ZOMBI SINIFI 17 (Volt): bekleme / homurtu sesi",
"vex_res Z17_ABILITY ^"vexmira/arena51/classes/17.wav^"         // ZOMBI SINIFI 17 (Volt): yetenek (R) sesi",
"vex_res Z18_MODEL ^"zombie_source^"                            // ZOMBI SINIFI 18 (Taklitci): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z18_CLAW ^"models/vexmira/community/claws/classic.mdl^" // ZOMBI SINIFI 18 (Taklitci): el / pence modeli",
"vex_res Z18_IDLE ^"^"                                          // ZOMBI SINIFI 18 (Taklitci): bekleme / homurtu sesi",
"vex_res Z18_ABILITY ^"vexmira/arena51/classes/18.wav^"         // ZOMBI SINIFI 18 (Taklitci): yetenek (R) sesi",
"vex_res Z19_MODEL ^"vex_scary^"                                // ZOMBI SINIFI 19 (Kostebek): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z19_CLAW ^"models/vexmira/community/claws/scary.mdl^"  // ZOMBI SINIFI 19 (Kostebek): el / pence modeli",
"vex_res Z19_IDLE ^"^"                                          // ZOMBI SINIFI 19 (Kostebek): bekleme / homurtu sesi",
"vex_res Z19_ABILITY ^"vexmira/arena51/classes/19.wav^"         // ZOMBI SINIFI 19 (Kostebek): yetenek (R) sesi",
"vex_res Z20_MODEL ^"zombie_witch2^"                            // ZOMBI SINIFI 20 (Siren): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z20_CLAW ^"models/vexmira/community/claws/classic.mdl^" // ZOMBI SINIFI 20 (Siren): el / pence modeli",
"vex_res Z20_IDLE ^"^"                                          // ZOMBI SINIFI 20 (Siren): bekleme / homurtu sesi",
"vex_res Z20_ABILITY ^"vexmira/arena51/classes/20.wav^"         // ZOMBI SINIFI 20 (Siren): yetenek (R) sesi",
"vex_res Z21_MODEL ^"cso_heavy^"                                // ZOMBI SINIFI 21 (Kale): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z21_CLAW ^"models/vexmira/community/claws/heavy.mdl^"  // ZOMBI SINIFI 21 (Kale): el / pence modeli",
"vex_res Z21_IDLE ^"^"                                          // ZOMBI SINIFI 21 (Kale): bekleme / homurtu sesi",
"vex_res Z21_ABILITY ^"vexmira/arena51/classes/21.wav^"         // ZOMBI SINIFI 21 (Kale): yetenek (R) sesi",
"vex_res Z22_MODEL ^"heal_zombi_origin^"                        // ZOMBI SINIFI 22 (Spor Ana): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z22_CLAW ^"models/vexmira/community/claws/classic.mdl^" // ZOMBI SINIFI 22 (Spor Ana): el / pence modeli",
"vex_res Z22_IDLE ^"^"                                          // ZOMBI SINIFI 22 (Spor Ana): bekleme / homurtu sesi",
"vex_res Z22_ABILITY ^"vexmira/arena51/classes/22.wav^"         // ZOMBI SINIFI 22 (Spor Ana): yetenek (R) sesi",
"vex_res Z23_MODEL ^"nemesis^"                                  // ZOMBI SINIFI 23 (Kabus): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)",
"vex_res Z23_CLAW ^"models/vexmira/community/claws/scary.mdl^"  // ZOMBI SINIFI 23 (Kabus): el / pence modeli",
"vex_res Z23_IDLE ^"^"                                          // ZOMBI SINIFI 23 (Kabus): bekleme / homurtu sesi",
"vex_res Z23_ABILITY ^"vexmira/arena51/classes/23.wav^"         // ZOMBI SINIFI 23 (Kabus): yetenek (R) sesi",
"vex_res CLAW_MODEL ^"models/zombie_plague/v_knife_zombie.mdl^" // model: claw model (bos = varsayilan)",
"",
"// ---- KAYNAK: BOSSLAR --------------------------------------------------------",
"vex_res BOSS_SPAWN ^"^"                                        // boss spawn (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_ROAR ^"^"                                         // boss roar (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_SCREAM ^"^"                                       // boss scream (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_SLAM ^"^"                                         // boss slam (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_SUMMON ^"^"                                       // boss summon (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_WARN ^"vexmira/arena51/boss/0/intro.wav^"         // ses: boss warn (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res BOSS_DEATH ^"^"                                        // boss death (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_SOON ^"vexmira/arena51/cues/mode9.wav^"           // ses: boss soon (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res BOSS_INTRO ^"^"                                        // boss intro (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_STEP ^"^"                                         // boss step (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_PHASE ^"^"                                        // boss phase (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_ENRAGE ^"^"                                       // boss enrage (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_ABILITY ^"^"                                      // boss ability (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_MARK_SPRITE ^"^"                                  // boss mark sprite (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_PRELOAD ^"3^"                                     // haritada yuklenen boss sayisi (her boss ~6 ses + model; 3 = 512 ses sinirindan guvenli pay, bosslar haritadan haritaya doner)",
"vex_res BOSS_PRELOAD_LIST ^"^"                                 // bos = bosslar haritadan haritaya sirayla doner (hepsi zamanla gelir)",
"vex_res B0_MODEL ^"vex_boss048^"                               // BOSS 0 (BRUTE): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD yazilir)",
"vex_res B0_CLAW ^"models/zombie_plague/v_knife_zombie.mdl^"    // BOSS 0 (BRUTE): el / pence modeli (v_ modeli)",
"vex_res B0_INTRO ^"vexmira/arena51/boss/0/intro.wav^"          // BOSS 0 (BRUTE): giris sesi (boss dogunca)",
"vex_res B0_IDLE ^"^"                                           // BOSS 0 (BRUTE): bekleme / nefes sesi",
"vex_res B0_PAIN ^"vexmira/arena51/boss/0/pain.wav^"            // BOSS 0 (BRUTE): hasar alma sesi",
"vex_res B0_PAIN2 ^"vexmira/arena51/boss/0/pain.wav^"           // BOSS 0 (BRUTE): hasar alma sesi 2",
"vex_res B0_DEATH ^"vexmira/arena51/boss/0/death.wav^"          // BOSS 0 (BRUTE): olum sesi",
"vex_res B0_STEP ^"vexmira/arena51/boss/0/attack.wav^"          // BOSS 0 (BRUTE): adim / yurume sesi",
"vex_res B0_ATTACK ^"vexmira/arena51/boss/0/attack.wav^"        // BOSS 0 (BRUTE): pence saldiri sesi",
"vex_res B0_PHASE ^"vexmira/arena51/boss/0/phase.wav^"          // BOSS 0 (BRUTE): faz gecis (ofkelenme) sesi",
"vex_res B0_KILL ^"vexmira/arena51/boss/0/r3.wav^"              // BOSS 0 (BRUTE): oyuncu oldurunce cikan ses",
"vex_res B0_R1 ^"vexmira/arena51/boss/0/r1.wav^"                // BOSS 0 (BRUTE): 1. yetenek sesi",
"vex_res B0_R2 ^"vexmira/arena51/boss/0/r2.wav^"                // BOSS 0 (BRUTE): 2. yetenek sesi",
"vex_res B0_R3 ^"vexmira/arena51/boss/0/r3.wav^"                // BOSS 0 (BRUTE): 3. yetenek sesi",
"vex_res B1_MODEL ^"vex_boss148^"                               // BOSS 1 (BANSHEE): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD yazilir)",
"vex_res B1_CLAW ^"models/zombie_plague/v_knife_zombie.mdl^"    // BOSS 1 (BANSHEE): el / pence modeli (v_ modeli)",
"vex_res B1_INTRO ^"vexmira/arena51/boss/1/intro.wav^"          // BOSS 1 (BANSHEE): giris sesi (boss dogunca)",
"vex_res B1_IDLE ^"^"                                           // BOSS 1 (BANSHEE): bekleme / nefes sesi",
"vex_res B1_PAIN ^"vexmira/arena51/boss/1/pain.wav^"            // BOSS 1 (BANSHEE): hasar alma sesi",
"vex_res B1_PAIN2 ^"vexmira/arena51/boss/1/pain.wav^"           // BOSS 1 (BANSHEE): hasar alma sesi 2",
"vex_res B1_DEATH ^"vexmira/arena51/boss/1/death.wav^"          // BOSS 1 (BANSHEE): olum sesi",
"vex_res B1_STEP ^"vexmira/arena51/boss/1/attack.wav^"          // BOSS 1 (BANSHEE): adim / yurume sesi",
"vex_res B1_ATTACK ^"vexmira/arena51/boss/1/attack.wav^"        // BOSS 1 (BANSHEE): pence saldiri sesi",
"vex_res B1_PHASE ^"vexmira/arena51/boss/1/phase.wav^"          // BOSS 1 (BANSHEE): faz gecis (ofkelenme) sesi",
"vex_res B1_KILL ^"vexmira/arena51/boss/1/r3.wav^"              // BOSS 1 (BANSHEE): oyuncu oldurunce cikan ses",
"vex_res B1_R1 ^"vexmira/arena51/boss/1/r1.wav^"                // BOSS 1 (BANSHEE): 1. yetenek sesi",
"vex_res B1_R2 ^"vexmira/arena51/boss/1/r2.wav^"                // BOSS 1 (BANSHEE): 2. yetenek sesi",
"vex_res B1_R3 ^"vexmira/arena51/boss/1/r3.wav^"                // BOSS 1 (BANSHEE): 3. yetenek sesi",
"vex_res B2_MODEL ^"vex_boss248^"                               // BOSS 2 (OVERLORD): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD yazilir)",
"vex_res B2_CLAW ^"models/zombie_plague/v_knife_zombie.mdl^"    // BOSS 2 (OVERLORD): el / pence modeli (v_ modeli)",
"vex_res B2_INTRO ^"vexmira/arena51/boss/2/intro.wav^"          // BOSS 2 (OVERLORD): giris sesi (boss dogunca)",
"vex_res B2_IDLE ^"^"                                           // BOSS 2 (OVERLORD): bekleme / nefes sesi",
"vex_res B2_PAIN ^"vexmira/arena51/boss/2/pain.wav^"            // BOSS 2 (OVERLORD): hasar alma sesi",
"vex_res B2_PAIN2 ^"vexmira/arena51/boss/2/pain.wav^"           // BOSS 2 (OVERLORD): hasar alma sesi 2",
"vex_res B2_DEATH ^"vexmira/arena51/boss/2/death.wav^"          // BOSS 2 (OVERLORD): olum sesi",
"vex_res B2_STEP ^"vexmira/arena51/boss/2/attack.wav^"          // BOSS 2 (OVERLORD): adim / yurume sesi",
"vex_res B2_ATTACK ^"vexmira/arena51/boss/2/attack.wav^"        // BOSS 2 (OVERLORD): pence saldiri sesi",
"vex_res B2_PHASE ^"vexmira/arena51/boss/2/phase.wav^"          // BOSS 2 (OVERLORD): faz gecis (ofkelenme) sesi",
"vex_res B2_KILL ^"vexmira/arena51/boss/2/r3.wav^"              // BOSS 2 (OVERLORD): oyuncu oldurunce cikan ses",
"vex_res B2_R1 ^"vexmira/arena51/boss/2/r1.wav^"                // BOSS 2 (OVERLORD): 1. yetenek sesi",
"vex_res B2_R2 ^"vexmira/arena51/boss/2/r2.wav^"                // BOSS 2 (OVERLORD): 2. yetenek sesi",
"vex_res B2_R3 ^"vexmira/arena51/boss/2/r3.wav^"                // BOSS 2 (OVERLORD): 3. yetenek sesi",
"vex_res B3_MODEL ^"vex_boss348^"                               // BOSS 3 (INFERNO): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD yazilir)",
"vex_res B3_CLAW ^"models/zombie_plague/v_knife_zombie.mdl^"    // BOSS 3 (INFERNO): el / pence modeli (v_ modeli)",
"vex_res B3_INTRO ^"vexmira/arena51/boss/3/intro.wav^"          // BOSS 3 (INFERNO): giris sesi (boss dogunca)",
"vex_res B3_IDLE ^"^"                                           // BOSS 3 (INFERNO): bekleme / nefes sesi",
"vex_res B3_PAIN ^"vexmira/arena51/boss/3/pain.wav^"            // BOSS 3 (INFERNO): hasar alma sesi",
"vex_res B3_PAIN2 ^"vexmira/arena51/boss/3/pain.wav^"           // BOSS 3 (INFERNO): hasar alma sesi 2",
"vex_res B3_DEATH ^"vexmira/arena51/boss/3/death.wav^"          // BOSS 3 (INFERNO): olum sesi",
"vex_res B3_STEP ^"vexmira/arena51/boss/3/attack.wav^"          // BOSS 3 (INFERNO): adim / yurume sesi",
"vex_res B3_ATTACK ^"vexmira/arena51/boss/3/attack.wav^"        // BOSS 3 (INFERNO): pence saldiri sesi",
"vex_res B3_PHASE ^"vexmira/arena51/boss/3/phase.wav^"          // BOSS 3 (INFERNO): faz gecis (ofkelenme) sesi",
"vex_res B3_KILL ^"vexmira/arena51/boss/3/r3.wav^"              // BOSS 3 (INFERNO): oyuncu oldurunce cikan ses",
"vex_res B3_R1 ^"vexmira/arena51/boss/3/r1.wav^"                // BOSS 3 (INFERNO): 1. yetenek sesi",
"vex_res B3_R2 ^"vexmira/arena51/boss/3/r2.wav^"                // BOSS 3 (INFERNO): 2. yetenek sesi",
"vex_res B3_R3 ^"vexmira/arena51/boss/3/r3.wav^"                // BOSS 3 (INFERNO): 3. yetenek sesi",
"vex_res B4_MODEL ^"vex_boss448^"                               // BOSS 4 (REAPER): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD yazilir)",
"vex_res B4_CLAW ^"models/zombie_plague/v_knife_zombie.mdl^"    // BOSS 4 (REAPER): el / pence modeli (v_ modeli)",
"vex_res B4_INTRO ^"vexmira/arena51/boss/4/intro.wav^"          // BOSS 4 (REAPER): giris sesi (boss dogunca)",
"vex_res B4_IDLE ^"^"                                           // BOSS 4 (REAPER): bekleme / nefes sesi",
"vex_res B4_PAIN ^"vexmira/arena51/boss/4/pain.wav^"            // BOSS 4 (REAPER): hasar alma sesi",
"vex_res B4_PAIN2 ^"vexmira/arena51/boss/4/pain.wav^"           // BOSS 4 (REAPER): hasar alma sesi 2",
"vex_res B4_DEATH ^"vexmira/arena51/boss/4/death.wav^"          // BOSS 4 (REAPER): olum sesi",
"vex_res B4_STEP ^"vexmira/arena51/boss/4/attack.wav^"          // BOSS 4 (REAPER): adim / yurume sesi",
"vex_res B4_ATTACK ^"vexmira/arena51/boss/4/attack.wav^"        // BOSS 4 (REAPER): pence saldiri sesi",
"vex_res B4_PHASE ^"vexmira/arena51/boss/4/phase.wav^"          // BOSS 4 (REAPER): faz gecis (ofkelenme) sesi",
"vex_res B4_KILL ^"vexmira/arena51/boss/4/r3.wav^"              // BOSS 4 (REAPER): oyuncu oldurunce cikan ses",
"vex_res B4_R1 ^"vexmira/arena51/boss/4/r1.wav^"                // BOSS 4 (REAPER): 1. yetenek sesi",
"vex_res B4_R2 ^"vexmira/arena51/boss/4/r2.wav^"                // BOSS 4 (REAPER): 2. yetenek sesi",
"vex_res B4_R3 ^"vexmira/arena51/boss/4/r3.wav^"                // BOSS 4 (REAPER): 3. yetenek sesi",
"vex_res B5_MODEL ^"vex_boss548^"                               // BOSS 5 (FROSTLORD): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD yazilir)",
"vex_res B5_CLAW ^"models/zombie_plague/v_knife_zombie.mdl^"    // BOSS 5 (FROSTLORD): el / pence modeli (v_ modeli)",
"vex_res B5_INTRO ^"vexmira/arena51/boss/5/intro.wav^"          // BOSS 5 (FROSTLORD): giris sesi (boss dogunca)",
"vex_res B5_IDLE ^"^"                                           // BOSS 5 (FROSTLORD): bekleme / nefes sesi",
"vex_res B5_PAIN ^"vexmira/arena51/boss/5/pain.wav^"            // BOSS 5 (FROSTLORD): hasar alma sesi",
"vex_res B5_PAIN2 ^"vexmira/arena51/boss/5/pain.wav^"           // BOSS 5 (FROSTLORD): hasar alma sesi 2",
"vex_res B5_DEATH ^"vexmira/arena51/boss/5/death.wav^"          // BOSS 5 (FROSTLORD): olum sesi",
"vex_res B5_STEP ^"vexmira/arena51/boss/5/attack.wav^"          // BOSS 5 (FROSTLORD): adim / yurume sesi",
"vex_res B5_ATTACK ^"vexmira/arena51/boss/5/attack.wav^"        // BOSS 5 (FROSTLORD): pence saldiri sesi",
"vex_res B5_PHASE ^"vexmira/arena51/boss/5/phase.wav^"          // BOSS 5 (FROSTLORD): faz gecis (ofkelenme) sesi",
"vex_res B5_KILL ^"vexmira/arena51/boss/5/r3.wav^"              // BOSS 5 (FROSTLORD): oyuncu oldurunce cikan ses",
"vex_res B5_R1 ^"vexmira/arena51/boss/5/r1.wav^"                // BOSS 5 (FROSTLORD): 1. yetenek sesi",
"vex_res B5_R2 ^"vexmira/arena51/boss/5/r2.wav^"                // BOSS 5 (FROSTLORD): 2. yetenek sesi",
"vex_res B5_R3 ^"vexmira/arena51/boss/5/r3.wav^"                // BOSS 5 (FROSTLORD): 3. yetenek sesi",
"vex_res B6_MODEL ^"vex_boss648^"                               // BOSS 6 (STORMCALLER): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD yazilir)",
"vex_res B6_CLAW ^"models/zombie_plague/v_knife_zombie.mdl^"    // BOSS 6 (STORMCALLER): el / pence modeli (v_ modeli)",
"vex_res B6_INTRO ^"vexmira/arena51/boss/6/intro.wav^"          // BOSS 6 (STORMCALLER): giris sesi (boss dogunca)",
"vex_res B6_IDLE ^"^"                                           // BOSS 6 (STORMCALLER): bekleme / nefes sesi",
"vex_res B6_PAIN ^"vexmira/arena51/boss/6/pain.wav^"            // BOSS 6 (STORMCALLER): hasar alma sesi",
"vex_res B6_PAIN2 ^"vexmira/arena51/boss/6/pain.wav^"           // BOSS 6 (STORMCALLER): hasar alma sesi 2",
"vex_res B6_DEATH ^"vexmira/arena51/boss/6/death.wav^"          // BOSS 6 (STORMCALLER): olum sesi",
"vex_res B6_STEP ^"vexmira/arena51/boss/6/attack.wav^"          // BOSS 6 (STORMCALLER): adim / yurume sesi",
"vex_res B6_ATTACK ^"vexmira/arena51/boss/6/attack.wav^"        // BOSS 6 (STORMCALLER): pence saldiri sesi",
"vex_res B6_PHASE ^"vexmira/arena51/boss/6/phase.wav^"          // BOSS 6 (STORMCALLER): faz gecis (ofkelenme) sesi",
"vex_res B6_KILL ^"vexmira/arena51/boss/6/r3.wav^"              // BOSS 6 (STORMCALLER): oyuncu oldurunce cikan ses",
"vex_res B6_R1 ^"vexmira/arena51/boss/6/r1.wav^"                // BOSS 6 (STORMCALLER): 1. yetenek sesi",
"vex_res B6_R2 ^"vexmira/arena51/boss/6/r2.wav^"                // BOSS 6 (STORMCALLER): 2. yetenek sesi",
"vex_res B6_R3 ^"vexmira/arena51/boss/6/r3.wav^"                // BOSS 6 (STORMCALLER): 3. yetenek sesi",
"vex_res B7_MODEL ^"vex_boss748^"                               // BOSS 7 (HIVE QUEEN): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD yazilir)",
"vex_res B7_CLAW ^"models/zombie_plague/v_knife_zombie.mdl^"    // BOSS 7 (HIVE QUEEN): el / pence modeli (v_ modeli)",
"vex_res B7_INTRO ^"vexmira/arena51/boss/7/intro.wav^"          // BOSS 7 (HIVE QUEEN): giris sesi (boss dogunca)",
"vex_res B7_IDLE ^"^"                                           // BOSS 7 (HIVE QUEEN): bekleme / nefes sesi",
"vex_res B7_PAIN ^"vexmira/arena51/boss/7/pain.wav^"            // BOSS 7 (HIVE QUEEN): hasar alma sesi",
"vex_res B7_PAIN2 ^"vexmira/arena51/boss/7/pain.wav^"           // BOSS 7 (HIVE QUEEN): hasar alma sesi 2",
"vex_res B7_DEATH ^"vexmira/arena51/boss/7/death.wav^"          // BOSS 7 (HIVE QUEEN): olum sesi",
"vex_res B7_STEP ^"vexmira/arena51/boss/7/attack.wav^"          // BOSS 7 (HIVE QUEEN): adim / yurume sesi",
"vex_res B7_ATTACK ^"vexmira/arena51/boss/7/attack.wav^"        // BOSS 7 (HIVE QUEEN): pence saldiri sesi",
"vex_res B7_PHASE ^"vexmira/arena51/boss/7/phase.wav^"          // BOSS 7 (HIVE QUEEN): faz gecis (ofkelenme) sesi",
"vex_res B7_KILL ^"vexmira/arena51/boss/7/r3.wav^"              // BOSS 7 (HIVE QUEEN): oyuncu oldurunce cikan ses",
"vex_res B7_R1 ^"vexmira/arena51/boss/7/r1.wav^"                // BOSS 7 (HIVE QUEEN): 1. yetenek sesi",
"vex_res B7_R2 ^"vexmira/arena51/boss/7/r2.wav^"                // BOSS 7 (HIVE QUEEN): 2. yetenek sesi",
"vex_res B7_R3 ^"vexmira/arena51/boss/7/r3.wav^"                // BOSS 7 (HIVE QUEEN): 3. yetenek sesi",
"vex_res B8_MODEL ^"vex_boss848^"                               // BOSS 8 (VOID): oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD yazilir)",
"vex_res B8_CLAW ^"models/zombie_plague/v_knife_zombie.mdl^"    // BOSS 8 (VOID): el / pence modeli (v_ modeli)",
"vex_res B8_INTRO ^"vexmira/arena51/boss/8/intro.wav^"          // BOSS 8 (VOID): giris sesi (boss dogunca)",
"vex_res B8_IDLE ^"^"                                           // BOSS 8 (VOID): bekleme / nefes sesi",
"vex_res B8_PAIN ^"vexmira/arena51/boss/8/pain.wav^"            // BOSS 8 (VOID): hasar alma sesi",
"vex_res B8_PAIN2 ^"vexmira/arena51/boss/8/pain.wav^"           // BOSS 8 (VOID): hasar alma sesi 2",
"vex_res B8_DEATH ^"vexmira/arena51/boss/8/death.wav^"          // BOSS 8 (VOID): olum sesi",
"vex_res B8_STEP ^"vexmira/arena51/boss/8/attack.wav^"          // BOSS 8 (VOID): adim / yurume sesi",
"vex_res B8_ATTACK ^"vexmira/arena51/boss/8/attack.wav^"        // BOSS 8 (VOID): pence saldiri sesi",
"vex_res B8_PHASE ^"vexmira/arena51/boss/8/phase.wav^"          // BOSS 8 (VOID): faz gecis (ofkelenme) sesi",
"vex_res B8_KILL ^"vexmira/arena51/boss/8/r3.wav^"              // BOSS 8 (VOID): oyuncu oldurunce cikan ses",
"vex_res B8_R1 ^"vexmira/arena51/boss/8/r1.wav^"                // BOSS 8 (VOID): 1. yetenek sesi",
"vex_res B8_R2 ^"vexmira/arena51/boss/8/r2.wav^"                // BOSS 8 (VOID): 2. yetenek sesi",
"vex_res B8_R3 ^"vexmira/arena51/boss/8/r3.wav^"                // BOSS 8 (VOID): 3. yetenek sesi",
"vex_res BOSS_IDLE ^"^"                                         // boss idle (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_KILL ^"^"                                         // boss kill (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_PAIN ^"^"                                         // boss pain (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_PAIN2 ^"^"                                        // boss pain2 (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_ATTACK ^"^"                                       // boss attack (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res BOSS_SCALE ^"1.6^"                                     // BOSS BUYUKLUGU: 1.0 = normal, 1.6 = 1.6 kat dev (model + hitbox kodla buyutulur)",
"vex_res BOSS_GIANT ^"file^"                                    // DEV BOSS: file = boss modelinin buyutulmus + inceltilmis kopyasi kendiliginden uretilir (models/player/<boss>_x16, orijinalin ~3te1 i boyutunda) | off = normal boyut, hic indirme yok | clone = sadece Xash istemcisi (Steam de boss buyumez - KULLANMA)",
"vex_res BOSS_GIANT_TEX ^"256^"                                 // dev boss kopyasinda doku boyutu siniri (px). 256 = kucuk indirme (onerilen) | 512 = daha net ama daha buyuk dosya | 0 = dokulara dokunma",
"vex_res BOSS_GIANT_ALL ^"1^"                                   // 1 = 9 dev bossun hepsi her haritada yuklenir: oyuncu hepsini ILK GIRISTE bir kez indirir, sonraki haritalarda hic indirme olmaz | 0 = sadece o haritanin 3 bossu (her yeni haritada yeni indirme)",
"",
"// ---- KAYNAK: OYUNCU MODELLERI -----------------------------------------------",
"vex_res HUMAN_WIN ^"vexmira/arena51/world/human_win.wav^"      // ses: human win (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res MODEL_BUDGET ^"250^"                                   // eklentinin yukleyebilecegi en fazla model/sprite sayisi (512 sinirina karsi koruma)",
"vex_res NEMESIS_MODEL ^"nemesis^"                              // Nemesis modeli",
"vex_res NEMESIS_CLAW ^"models/zombie_plague/v_knife_zombie.mdl^" // model: nemesis claw",
"vex_res ASSASSIN_MODEL ^"vex_scary^"                           // Assassin modeli",
"vex_res ASSASSIN_CLAW ^"models/zombie_plague/v_knife_zombie.mdl^" // model: assassin claw",
"vex_res HUMAN_MODELS ^"sp_halo_admins^"                        // insan oyuncu modelleri (birden fazla: bosluk ile; models/player/AD/AD.mdl -> AD)",
"vex_res NEMESIS_INTRO ^"vexmira/arena51/world/nemesis.wav^"    // ses: nemesis intro (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res NEMESIS_IDLE ^"^"                                      // nemesis idle (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res NEMESIS_PAIN ^"vexmira/arena48/b3_pain.wav^"           // ses: nemesis pain (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res NEMESIS_DEATH ^"vexmira/arena48/b3_death.wav^"         // ses: nemesis death (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res NEMESIS_ATTACK ^"vexmira/arena48/b3_attack.wav^"       // ses: nemesis attack (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ASSASSIN_INTRO ^"vexmira/arena51/world/assassin_intro.wav^" // ses: assassin intro (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ASSASSIN_IDLE ^"^"                                     // assassin idle (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res ASSASSIN_PAIN ^"vexmira/arena51/world/assassin_pain.wav^" // ses: assassin pain (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ASSASSIN_DEATH ^"vexmira/arena51/world/assassin_death.wav^" // ses: assassin death (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ASSASSIN_ATTACK ^"vexmira/arena51/world/assassin_attack.wav^" // ses: assassin attack (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res SURVIVOR_M249_VMODEL ^"^"                              // survivor m249 vmodel (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res SURVIVOR_M249_PMODEL ^"^"                              // survivor m249 pmodel (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res SURVIVOR_DEAGLE_VMODEL ^"^"                            // survivor deagle vmodel (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res SURVIVOR_DEAGLE_PMODEL ^"^"                            // survivor deagle pmodel (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res SNIPER_AWP_VMODEL ^"^"                                 // sniper awp vmodel (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res SNIPER_AWP_PMODEL ^"^"                                 // sniper awp pmodel (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res SURVIVOR_W1_VMODEL ^"^"                                // Survivor silahi 1: el modeli",
"vex_res SURVIVOR_W1_PMODEL ^"^"                                // Survivor silahi 1: oyuncu ustu model",
"vex_res SURVIVOR_W1_SOUND ^"^"                                 // Survivor silahi 1: ates sesi",
"vex_res SURVIVOR_W2_VMODEL ^"^"                                // Survivor silahi 2: el modeli",
"vex_res SURVIVOR_W2_PMODEL ^"^"                                // Survivor silahi 2: oyuncu ustu model",
"vex_res SURVIVOR_W2_SOUND ^"^"                                 // Survivor silahi 2: ates sesi",
"vex_res SNIPER_W1_VMODEL ^"^"                                  // Sniper silahi 1: el modeli",
"vex_res SNIPER_W1_PMODEL ^"^"                                  // Sniper silahi 1: oyuncu ustu model",
"vex_res SNIPER_W1_SOUND ^"^"                                   // Sniper silahi 1: ates sesi",
"vex_res SNIPER_W2_VMODEL ^"^"                                  // Sniper silahi 2: el modeli",
"vex_res SNIPER_W2_PMODEL ^"^"                                  // Sniper silahi 2: oyuncu ustu model",
"vex_res SNIPER_W2_SOUND ^"^"                                   // Sniper silahi 2: ates sesi",
"vex_res ADMIN_MODEL ^"sp_halo_admins^"                         // admin oyuncu modeli",
"vex_res VIP_MODEL ^"sp_halo_admins^"                           // VIP oyuncu modeli",
"vex_res SURVIVOR_MODEL ^"sp_halo_admins^"                      // Survivor modeli",
"vex_res SNIPER_MODEL ^"sp_halo_admins^"                        // Sniper modeli",
"",
"// ---- KAYNAK: SILAH MODELLERI ------------------------------------------------",
"vex_res W_HEGRENADE ^"models/vexmira_ze/grenades/vexmira_w_hegrenade.mdl^" // hegrenade silahi: yere dusen model",
"vex_res W_SMOKEGRENADE ^"models/vexmira_ze/grenades/vexmira_w_smokegrenade.mdl^" // smokegrenade silahi: yere dusen model",
"vex_res W_FLASHBANG ^"models/vexmira_ze/grenades/vexmira_w_flashbang.mdl^" // flashbang silahi: yere dusen model",
"vex_res V_KNIFE ^"models/vexmira/arena52/default/v_knife.mdl^" // knife silahi: el (gorus) modeli",
"vex_res P_KNIFE ^"models/p_knife.mdl^"                         // knife silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res V_HEGRENADE ^"models/vexmira_ze/grenades/vexmira_v_hegrenade.mdl^" // hegrenade silahi: el (gorus) modeli",
"vex_res P_HEGRENADE ^"models/vexmira_ze/grenades/vexmira_p_hegrenade.mdl^" // hegrenade silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res V_SMOKEGRENADE ^"models/vexmira_ze/grenades/vexmira_v_smokegrenade.mdl^" // smokegrenade silahi: el (gorus) modeli",
"vex_res V_FLASHBANG ^"models/vexmira_ze/grenades/vexmira_v_flashbang.mdl^" // flashbang silahi: el (gorus) modeli",
"vex_res P_FLASHBANG ^"models/vexmira_ze/grenades/vexmira_p_flashbang.mdl^" // flashbang silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_P228 ^"models/vexmira_ze/skins/vexmira_p_p228.mdl^"  // p228 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_SCOUT ^"models/vexmira_ze/skins/vexmira_p_scout.mdl^" // scout silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_XM1014 ^"models/vexmira_ze/skins/vexmira_p_xm1014.mdl^" // xm1014 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res V_XM1014 ^"models/vexmira_ze/skins/vexmira_v_xm1014.mdl^" // xm1014 silahi: el (gorus) modeli",
"vex_res P_MAC10 ^"models/vexmira_ze/skins/vexmira_p_mac10.mdl^" // mac10 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_AUG ^"models/vexmira_ze/skins/vexmira_p_aug.mdl^"    // aug silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res V_AUG ^"models/vexmira_ze/skins/vexmira_v_aug.mdl^"    // aug silahi: el (gorus) modeli",
"vex_res P_ELITE ^"models/vexmira_ze/skins/vexmira_p_elite.mdl^" // elite silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_FIVESEVEN ^"models/vexmira_ze/skins/vexmira_p_fiveseven.mdl^" // fiveseven silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_UMP45 ^"models/vexmira_ze/skins/vexmira_p_ump45.mdl^" // ump45 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_SG550 ^"models/vexmira_ze/skins/vexmira_p_sg550.mdl^" // sg550 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res V_SG550 ^"models/vexmira_ze/skins/vexmira_v_sg550.mdl^" // sg550 silahi: el (gorus) modeli",
"vex_res V_GALIL ^"models/vexmira/arena52/default/v_galil.mdl^" // galil silahi: el (gorus) modeli",
"vex_res P_FAMAS ^"models/vexmira_ze/skins/vexmira_p_famas.mdl^" // famas silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_USP ^"models/vexmira_ze/skins/vexmira_p_usp.mdl^"    // usp silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_GLOCK18 ^"models/vexmira_ze/skins/vexmira_p_glock18.mdl^" // glock18 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_AWP ^"models/vexmira_ze/skins/vexmira_p_awp.mdl^"    // awp silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res V_AWP ^"models/vexmira_ze/skins/vexmira_v_awp.mdl^"    // awp silahi: el (gorus) modeli",
"vex_res P_MP5NAVY ^"models/vexmira_ze/skins/vexmira_p_mp5.mdl^" // mp5navy silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res V_MP5NAVY ^"models/vexmira_ze/skins/vexmira_v_mp5.mdl^" // mp5navy silahi: el (gorus) modeli",
"vex_res P_M249 ^"models/vexmira_ze/skins/vexmira_p_m249.mdl^"  // m249 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res V_M249 ^"models/vexmira_ze/skins/vexmira_v_m249.mdl^"  // m249 silahi: el (gorus) modeli",
"vex_res P_M3 ^"models/vexmira_ze/skins/vexmira_p_m3.mdl^"      // m3 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_M4A1 ^"models/vexmira_ze/skins/vexmira_p_m4a1.mdl^"  // m4a1 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res V_M4A1 ^"models/vexmira_ze/skins/vexmira_v_m4a1.mdl^"  // m4a1 silahi: el (gorus) modeli",
"vex_res P_TMP ^"models/vexmira_ze/skins/vexmira_p_tmp.mdl^"    // tmp silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_G3SG1 ^"models/vexmira_ze/skins/vexmira_p_g3sg1.mdl^" // g3sg1 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_DEAGLE ^"models/vexmira_ze/skins/vexmira_p_deagle.mdl^" // deagle silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res V_DEAGLE ^"models/vexmira_ze/skins/vexmira_v_deagle.mdl^" // deagle silahi: el (gorus) modeli",
"vex_res P_SG552 ^"models/vexmira_ze/skins/vexmira_p_sg552.mdl^" // sg552 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res V_SG552 ^"models/vexmira_ze/skins/vexmira_v_sg552.mdl^" // sg552 silahi: el (gorus) modeli",
"vex_res V_AK47 ^"models/vexmira_ze/skins/vexmira_v_ak47.mdl^"  // ak47 silahi: el (gorus) modeli",
"vex_res P_AK47 ^"models/vexmira_ze/skins/vexmira_p_ak47.mdl^"  // ak47 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res P_P90 ^"models/vexmira_ze/skins/vexmira_p_p90.mdl^"    // p90 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res SW0_VMODEL ^"models/vexmira/arena51/arsenal/0/v.mdl^"  // OZEL SILAH 0 (Arbalest): el modeli",
"vex_res SW0_PMODEL ^"models/vexmira/arena50/arsenal/0/p.mdl^"  // OZEL SILAH 0 (Arbalest): oyuncu ustu model",
"vex_res SW0_WMODEL ^"models/vexmira/arena50/arsenal/0/w.mdl^"  // OZEL SILAH 0 (Arbalest): yerdeki model",
"vex_res SW0_FIRE ^"vexmira/arena51/arsenal/0/fire.wav^"        // OZEL SILAH 0 (Arbalest): ates sesi",
"vex_res SW1_VMODEL ^"models/vexmira/arena51/arsenal/1/v.mdl^"  // OZEL SILAH 1 (Heaven Splitter): el modeli",
"vex_res SW1_PMODEL ^"models/vexmira/arena50/arsenal/1/p.mdl^"  // OZEL SILAH 1 (Heaven Splitter): oyuncu ustu model",
"vex_res SW1_WMODEL ^"models/vexmira/arena50/arsenal/1/w.mdl^"  // OZEL SILAH 1 (Heaven Splitter): yerdeki model",
"vex_res SW1_FIRE ^"vexmira/arena51/arsenal/1/fire.wav^"        // OZEL SILAH 1 (Heaven Splitter): ates sesi",
"vex_res SW2_VMODEL ^"models/vexmira/arena51/arsenal/2/v.mdl^"  // OZEL SILAH 2 (Quantum Horizon): el modeli",
"vex_res SW2_PMODEL ^"models/vexmira/arena50/arsenal/2/p.mdl^"  // OZEL SILAH 2 (Quantum Horizon): oyuncu ustu model",
"vex_res SW2_WMODEL ^"models/vexmira/arena50/arsenal/2/w.mdl^"  // OZEL SILAH 2 (Quantum Horizon): yerdeki model",
"vex_res SW2_FIRE ^"vexmira/arena51/arsenal/2/fire.wav^"        // OZEL SILAH 2 (Quantum Horizon): ates sesi",
"vex_res SW3_VMODEL ^"models/vexmira/arena51/arsenal/3/v.mdl^"  // OZEL SILAH 3 (Magnum Drill Chimera): el modeli",
"vex_res SW3_PMODEL ^"models/vexmira/arena50/arsenal/3/p.mdl^"  // OZEL SILAH 3 (Magnum Drill Chimera): oyuncu ustu model",
"vex_res SW3_WMODEL ^"models/vexmira/arena50/arsenal/3/w.mdl^"  // OZEL SILAH 3 (Magnum Drill Chimera): yerdeki model",
"vex_res SW3_FIRE ^"vexmira/arena51/arsenal/3/fire.wav^"        // OZEL SILAH 3 (Magnum Drill Chimera): ates sesi",
"vex_res SW5_VMODEL ^"models/vexmira/arena51/arsenal/5/v.mdl^"  // OZEL SILAH 5 (Infinity Laser Fist): el modeli",
"vex_res SW5_PMODEL ^"models/vexmira/arena50/arsenal/5/p.mdl^"  // OZEL SILAH 5 (Infinity Laser Fist): oyuncu ustu model",
"vex_res SW5_WMODEL ^"models/vexmira/arena50/arsenal/5/w.mdl^"  // OZEL SILAH 5 (Infinity Laser Fist): yerdeki model",
"vex_res SW5_FIRE ^"vexmira/arena51/arsenal/5/fire.wav^"        // OZEL SILAH 5 (Infinity Laser Fist): ates sesi",
"vex_res V_UMP45 ^"models/vexmira_ze/skins/vexmira_v_ump45.mdl^" // ump45 silahi: el (gorus) modeli",
"vex_res V_MP5 ^"models/vexmira_ze/skins/vexmira_v_mp5.mdl^"    // mp5 silahi: el (gorus) modeli",
"vex_res V_MAC10 ^"models/vexmira_ze/skins/vexmira_v_mac10.mdl^" // mac10 silahi: el (gorus) modeli",
"vex_res V_SCOUT ^"models/vexmira_ze/skins/vexmira_v_scout.mdl^" // scout silahi: el (gorus) modeli",
"vex_res V_GLOCK18 ^"models/vexmira_ze/skins/vexmira_v_glock18.mdl^" // glock18 silahi: el (gorus) modeli",
"vex_res V_M3 ^"models/vexmira_ze/skins/vexmira_v_m3.mdl^"      // m3 silahi: el (gorus) modeli",
"vex_res V_FIVESEVEN ^"models/vexmira_ze/skins/vexmira_v_fiveseven.mdl^" // fiveseven silahi: el (gorus) modeli",
"vex_res V_TMP ^"models/vexmira_ze/skins/vexmira_v_tmp.mdl^"    // tmp silahi: el (gorus) modeli",
"vex_res V_P90 ^"models/vexmira_ze/skins/vexmira_v_p90.mdl^"    // p90 silahi: el (gorus) modeli",
"vex_res V_ELITE ^"models/vexmira_ze/skins/vexmira_v_elite.mdl^" // elite silahi: el (gorus) modeli",
"vex_res V_P228 ^"models/vexmira_ze/skins/vexmira_v_p228.mdl^"  // p228 silahi: el (gorus) modeli",
"vex_res V_FAMAS ^"models/vexmira_ze/skins/vexmira_v_famas.mdl^" // famas silahi: el (gorus) modeli",
"vex_res V_USP ^"models/vexmira_ze/skins/vexmira_v_usp.mdl^"    // usp silahi: el (gorus) modeli",
"vex_res V_G3SG1 ^"models/vexmira_ze/skins/vexmira_v_g3sg1.mdl^" // g3sg1 silahi: el (gorus) modeli",
"vex_res P_MP5 ^"models/vexmira_ze/skins/vexmira_p_mp5.mdl^"    // mp5 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res W_AK47 ^"models/vexmira_ze/skins/vexmira_w_ak47.mdl^"  // ak47 silahi: yere dusen model",
"vex_res W_AUG ^"models/vexmira_ze/skins/vexmira_w_aug.mdl^"    // aug silahi: yere dusen model",
"vex_res W_AWP ^"models/vexmira_ze/skins/vexmira_w_awp.mdl^"    // awp silahi: yere dusen model",
"vex_res W_DEAGLE ^"models/vexmira_ze/skins/vexmira_w_deagle.mdl^" // deagle silahi: yere dusen model",
"vex_res W_ELITE ^"models/vexmira_ze/skins/vexmira_w_elite.mdl^" // elite silahi: yere dusen model",
"vex_res W_FAMAS ^"models/vexmira_ze/skins/vexmira_w_famas.mdl^" // famas silahi: yere dusen model",
"vex_res W_FIVESEVEN ^"models/vexmira_ze/skins/vexmira_w_fiveseven.mdl^" // fiveseven silahi: yere dusen model",
"vex_res W_G3SG1 ^"models/vexmira_ze/skins/vexmira_w_g3sg1.mdl^" // g3sg1 silahi: yere dusen model",
"vex_res W_GLOCK18 ^"models/vexmira_ze/skins/vexmira_w_glock18.mdl^" // glock18 silahi: yere dusen model",
"vex_res W_M249 ^"models/vexmira_ze/skins/vexmira_w_m249.mdl^"  // m249 silahi: yere dusen model",
"vex_res W_M3 ^"models/vexmira_ze/skins/vexmira_w_m3.mdl^"      // m3 silahi: yere dusen model",
"vex_res W_M4A1 ^"models/vexmira_ze/skins/vexmira_w_m4a1.mdl^"  // m4a1 silahi: yere dusen model",
"vex_res W_MAC10 ^"models/vexmira_ze/skins/vexmira_w_mac10.mdl^" // mac10 silahi: yere dusen model",
"vex_res W_MP5 ^"models/vexmira_ze/skins/vexmira_w_mp5.mdl^"    // mp5 silahi: yere dusen model",
"vex_res W_MP5NAVY ^"models/vexmira_ze/skins/vexmira_w_mp5.mdl^" // mp5navy silahi: yere dusen model",
"vex_res W_P228 ^"models/vexmira_ze/skins/vexmira_w_p228.mdl^"  // p228 silahi: yere dusen model",
"vex_res W_P90 ^"models/vexmira_ze/skins/vexmira_w_p90.mdl^"    // p90 silahi: yere dusen model",
"vex_res W_SCOUT ^"models/vexmira_ze/skins/vexmira_w_scout.mdl^" // scout silahi: yere dusen model",
"vex_res W_SG550 ^"models/vexmira_ze/skins/vexmira_w_sg550.mdl^" // sg550 silahi: yere dusen model",
"vex_res W_SG552 ^"models/vexmira_ze/skins/vexmira_w_sg552.mdl^" // sg552 silahi: yere dusen model",
"vex_res W_TMP ^"models/vexmira_ze/skins/vexmira_w_tmp.mdl^"    // tmp silahi: yere dusen model",
"vex_res W_UMP45 ^"models/vexmira_ze/skins/vexmira_w_ump45.mdl^" // ump45 silahi: yere dusen model",
"vex_res W_USP ^"models/vexmira_ze/skins/vexmira_w_usp.mdl^"    // usp silahi: yere dusen model",
"vex_res W_XM1014 ^"models/vexmira_ze/skins/vexmira_w_xm1014.mdl^" // xm1014 silahi: yere dusen model",
"vex_res P_SMOKEGRENADE ^"models/vexmira_ze/grenades/vexmira_p_smokegrenade.mdl^" // smokegrenade silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res V_C4 ^"models/vexmira/arena52/default/v_c4.mdl^"       // c4 silahi: el (gorus) modeli",
"vex_res P_C4 ^"models/p_c4.mdl^"                               // c4 silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res W_C4 ^"models/w_c4.mdl^"                               // c4 silahi: yere dusen model",
"vex_res P_GALIL ^"models/p_galil.mdl^"                         // galil silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res W_GALIL ^"models/w_galil.mdl^"                         // galil silahi: yere dusen model",
"vex_res W_KNIFE ^"^"                                           // knife silahi: yere dusen model",
"vex_res SW6_VMODEL ^"models/vexmira/arena51/arsenal/6/v.mdl^"  // OZEL SILAH 6 (Void Avenger): el modeli",
"vex_res SW6_PMODEL ^"models/vexmira/arena50/arsenal/6/p.mdl^"  // OZEL SILAH 6 (Void Avenger): oyuncu ustu model",
"vex_res SW6_WMODEL ^"models/vexmira/arena50/arsenal/6/w.mdl^"  // OZEL SILAH 6 (Void Avenger): yerdeki model",
"vex_res SW6_FIRE ^"vexmira/arena51/arsenal/6/fire.wav^"        // OZEL SILAH 6 (Void Avenger): ates sesi",
"vex_res SW7_VMODEL ^"models/vexmira/arena51/arsenal/7/v.mdl^"  // OZEL SILAH 7 (Dual Beretta Gunslinger): el modeli",
"vex_res SW7_PMODEL ^"models/p_elite.mdl^"                      // OZEL SILAH 7 (Dual Beretta Gunslinger): oyuncu ustu model",
"vex_res SW7_WMODEL ^"models/vexmira/arena50/arsenal/7/w.mdl^"  // OZEL SILAH 7 (Dual Beretta Gunslinger): yerdeki model",
"vex_res SW7_FIRE ^"vexmira/arena51/arsenal/7/fire.wav^"        // OZEL SILAH 7 (Dual Beretta Gunslinger): ates sesi",
"vex_res V_GLOCK ^"^"                                           // glock silahi: el (gorus) modeli",
"vex_res P_GLOCK ^"^"                                           // glock silahi: oyuncunun elindeki model (baskalari gorur)",
"vex_res W_GLOCK ^"^"                                           // glock silahi: yere dusen model",
"",
"// ---- KAYNAK: BOMBALAR VE LAZER MAYIN ----------------------------------------",
"vex_res NADE_FIRE ^"vexmira/arena51/world/fire.wav^"           // ses: nade fire (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res NADE_FROST ^"vexmira/arena51/world/ice.wav^"           // ses: nade frost (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res NADE_INFECT ^"zombie_plague/grenade_infect.wav^"       // ses: nade infect (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res NADE_MODE ^"vexmira/arena51/context/nade_mode.wav^"    // ses: nade mode (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res NADE_BEEP ^"vexmira/arena51/context/nade_beep.wav^"    // ses: nade beep (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res NADE_ARM ^"vexmira/arena51/context/nade_arm.wav^"      // ses: nade arm (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res NADE_TRIGGER ^"^"                                      // nade trigger (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res NADE_CLUSTER ^"^"                                      // nade cluster (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res LM_DEPLOY ^"vexmira/arena51/context/lm_deploy.wav^"    // ses: lm deploy (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res LM_CHARGE ^"vexmira/arena51/context/lm_charge.wav^"    // ses: lm charge (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res LM_ACTIVATE ^"vexmira/arena51/context/lm_activate.wav^" // ses: lm activate (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res LM_HIT ^"vexmira/arena51/context/lm_hit.wav^"          // ses: lm hit (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res LM_KILL ^"^"                                           // lm kill (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res LM_BREAK ^"vexmira/arena51/context/lm_break.wav^"      // ses: lm break (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res LM_PICKUP ^"vexmira/arena51/context/lm_pickup.wav^"    // ses: lm pickup (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res LM_DENY ^"vexmira/meme/error.wav^"                     // ses: lm deny (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res LASERMINE_BODY ^"0^"                                   // mayin model govde no",
"vex_res LASERMINE_SEQUENCE ^"idle^"                            // mayin bekleme animasyonu",
"vex_res LASERMINE_DEPLOY_SEQ ^"deploy^"                        // mayin acilis animasyonu",
"vex_res LASERMINE_SKIN ^"0^"                                   // mayin model skin no",
"vex_res LASERMINE_ANGLES ^"0 0 0^"                             // mayin model aci duzeltmesi (pitch yaw roll)",
"vex_res LASERMINE_OFFSET ^"0.3^"                               // mayinin duvardan uzakligi (birim)",
"vex_res LASERMINE_EMITTER ^"10.3 0 0^"                         // isinin ciktigi uc (model +X ekseni)",
"vex_res LASERMINE_MODEL ^"models/vexmira/lasermine/lm_human.mdl^" // varsayilan lazer mayin modeli",
"vex_res LASERMINE_MODEL_HUMAN ^"models/vexmira/lasermine/lm_human.mdl^" // insan lazer mayini (beyaz-mavi teknoloji)",
"vex_res LASERMINE_MODEL_ZOMBIE ^"models/vexmira/lasermine/lm_zombie.mdl^" // zombi lazer mayini (organik biyo-mayin)",
"vex_res NADE_INFECT_V ^"models/vexmira/nades/v_infect.mdl^"    // enfeksiyon bombasi el modeli (zombi pencesi)",
"vex_res NADE_INFECT_P ^"models/vexmira/nades/p_infect.mdl^"    // enfeksiyon bombasi oyuncu ustu modeli",
"vex_res NADE_INFECT_W ^"models/vexmira/nades/w_infect.mdl^"    // atilan enfeksiyon bombasi modeli",
"",
"// ---- KAYNAK: SPRITE / EFEKT -------------------------------------------------",
"vex_res SPR_LASER ^"sprites/vexmira_ze/arena51/vexmira_base_beam.spr^" // sprite / efekt: spr laser",
"vex_res SPR_ZONE ^"sprites/vexmira_ze/arena51/vexmira_base_ring.spr^" // sprite / efekt: spr zone",
"vex_res SPR_TARGET ^"sprites/vexmira/brand/target.spr^"        // sprite / efekt: spr target",
"vex_res SPR_BEACON ^"sprites/vexmira/brand/beacon.spr^"        // sprite / efekt: spr beacon",
"vex_res SPR_ORB ^"sprites/vexmira/brand/orb.spr^"              // sprite / efekt: spr orb",
"vex_res SPR_MARK ^"sprites/vexmira/brand/mark.spr^"            // sprite / efekt: spr mark",
"vex_res SPR_FIRE ^"sprites/vexmira/arena51/gren_fire.spr^"     // sprite / efekt: spr fire",
"vex_res SPR_BOSSBAR ^"sprites/vexmira/arena49/bossbar.spr^"    // sprite / efekt: spr bossbar",
"vex_res SPR_BOSSICON ^"sprites/vexmira/brand/bossicon.spr^"    // sprite / efekt: spr bossicon",
"vex_res SPR_HPBAR ^"sprites/vexmira/brand/hpbar.spr^"          // sprite / efekt: spr hpbar",
"vex_res SPR_ICON_VIP ^"sprites/vexmira/arena48/icon_vip.spr^"  // sprite / efekt: spr icon vip",
"vex_res SPR_ICON_ADMIN ^"sprites/vexmira/arena48/icon_admin.spr^" // sprite / efekt: spr icon admin",
"vex_res SPR_ICON_MVP ^"sprites/vexmira/arena48/icon_mvp.spr^"  // sprite / efekt: spr icon mvp",
"vex_res SPR_ICON_LAST ^"sprites/vexmira/arena48/icon_last.spr^" // sprite / efekt: spr icon last",
"vex_res SPR_ICON_ALPHA ^"sprites/vexmira/arena48/icon_alpha.spr^" // sprite / efekt: spr icon alpha",
"vex_res SPR_CHAIN ^"sprites/vexmira/brand/chain.spr^"          // sprite / efekt: spr chain",
"vex_res SPR_WEB ^"sprites/vexmira/brand/chain.spr^"            // sprite / efekt: spr web",
"vex_res SPR_SPORE ^"sprites/vexmira/brand/toxic.spr^"          // sprite / efekt: spr spore",
"vex_res SPR_EMP ^"sprites/vexmira/brand/pulse.spr^"            // sprite / efekt: spr emp",
"vex_res SPR_EXPLO_FIRE ^"sprites/vexmira/arena51/gren_fire.spr^" // sprite / efekt: spr explo fire",
"vex_res SPR_EXPLO_ICE ^"sprites/vexmira/arena51/gren_ice.spr^" // sprite / efekt: spr explo ice",
"vex_res SPR_EXPLO_TOXIC ^"sprites/vexmira/brand/toxic.spr^"    // sprite / efekt: spr explo toxic",
"vex_res SPR_EXPLO_VOID ^"sprites/vexmira/brand/void.spr^"      // sprite / efekt: spr explo void",
"vex_res SPR_HEAL ^"sprites/vexmira/brand/hit.spr^"             // sprite / efekt: spr heal",
"vex_res SPR_LEVELUP ^"sprites/vexmira/brand/pulse.spr^"        // sprite / efekt: spr levelup",
"vex_res SPR_INFECT ^"sprites/vexmira/brand/pulse.spr^"         // sprite / efekt: spr infect",
"vex_res SPR_SHOCK ^"sprites/vexmira/brand/laser.spr^"          // sprite / efekt: spr shock",
"vex_res SPR_SLASH ^"sprites/vexmira/brand/slash.spr^"          // sprite / efekt: spr slash",
"vex_res SPR_ICE ^"sprites/vexmira_ze/arena51/vexmira_gren_ice.spr^" // sprite / efekt: spr ice",
"vex_res SPR_VOID ^"sprites/vexmira/brand/void.spr^"            // sprite / efekt: spr void",
"vex_res SPR_TOXIC ^"sprites/vexmira/brand/toxic.spr^"          // sprite / efekt: spr toxic",
"vex_res SPR_HUMAN47 ^"^"                                       // spr human47 (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res SPR_ZOMBIE47 ^"sprites/vexmira/arena49/zombiebar.spr^" // sprite / efekt: spr zombie47",
"vex_res SPR_FROST ^"sprites/vexmira/arena51/gren_ice.spr^"     // sprite / efekt: spr frost",
"vex_res SPR_FLARE ^"sprites/vexmira/arena51/gren_flare.spr^"   // sprite / efekt: spr flare",
"",
"// ---- KAYNAK: BUTCE / DIGER --------------------------------------------------",
"vex_res VOX_COUNTDOWN ^"2^"                                    // geri sayim anonsu: 0 kapali, 1 sayilar, 2 sayilar + efekt",
"vex_res EVOLVE ^"zombie_plague/grenade_infect.wav^"            // ses: evolve (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res MADNESS ^"^"                                           // madness (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res ANTIDOTE ^"vexmira/meme/wow.wav^"                      // ses: antidote (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res NEM_RAGE ^"vexmira/arena51/world/nemesis.wav^"         // ses: nem rage (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ASN_VEIL ^"^"                                          // asn veil (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res ROUND_START ^"vexmira/arena51/world/round_start.wav^"  // ses: round start (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res MODE_START ^"vexmira/arena51/cues/mode0.wav^"          // ses: mode start (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res EVENT_START ^"vexmira/arena51/cues/event0.wav^"        // ses: event start (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res COUNTDOWN_BEEP ^"vexmira/meme/vine_boom.wav^"          // ses: countdown beep (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res LIGHTNING ^"vexmira/arena51/world/lightning.wav^"      // ses: lightning (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res METEOR ^"vexmira/arena51/world/fire.wav^"              // ses: meteor (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res LAST_HUMAN ^"vexmira/meme/vine_boom.wav^"              // ses: last human (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res HEARTBEAT ^"^"                                         // heartbeat (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res FINAL_ROUND ^"vexmira/arena51/cues/event13.wav^"       // ses: final round (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res MAP_END ^"vexmira/meme/weide.wav^"                     // ses: map end (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res SPEED_START ^"zombie_plague/survivor1.wav^"            // ses: speed start (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res SPEED_WIND ^"^"                                        // speed wind (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res STORM_STRIKE ^"vexmira/arena51/world/lightning.wav^"   // ses: storm strike (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res BLACKOUT ^"vexmira/arena51/boss/2/phase.wav^"          // ses: blackout (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res WELCOME ^"vexmira/arena51/cues/mode0.wav^"             // ses: welcome (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res PLAYER_JOIN ^"^"                                       // player join (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res PLAYER_LEAVE ^"^"                                      // player leave (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res UI_OPEN ^"vexmira/arena51/context/ui_open.wav^"        // ses: ui open (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res SKILL_UNLOCK ^"vexmira/arena51/context/skill_unlock.wav^" // ses: skill unlock (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ZONE_WARN ^"^"                                         // zone warn (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res FROST_NOVA ^"vexmira/arena51/world/ice.wav^"           // ses: frost nova (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res THUNDER ^"zombie_plague/thunder1.wav^"                 // ses: thunder (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ACID_POOL ^"^"                                         // acid pool (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res GRAVITY_WELL ^"^"                                      // gravity well (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res ECLIPSE ^"vexmira/arena51/boss/8/phase.wav^"           // ses: eclipse (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res HEADSHOT ^"^"                                          // headshot (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res KILL_DOUBLE ^"^"                                       // kill double (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res KILL_TRIPLE ^"^"                                       // kill triple (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res KILL_MULTI ^"vexmira/meme/vine_boom.wav^"              // ses: kill multi (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res KILL_MEGA ^"vexmira/meme/vine_boom.wav^"               // ses: kill mega (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res KILL_MONSTER ^"vexmira/meme/vine_boom.wav^"            // v4.2: meme vine_boom saldiri/vurus yerine 6+ coklu oldurmede",
"vex_res STREAK_5 ^"^"                                          // seri oldurme sesi (5. seviye)",
"vex_res STREAK_10 ^"^"                                         // streak 10 (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res STREAK_15 ^"^"                                         // streak 15 (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res MVP ^"vexmira/meme/wow.wav^"                           // ses: mvp (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res QUEST_DONE ^"vexmira/meme/wow.wav^"                    // ses: quest done (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res LEVEL_UP ^"vexmira/meme/wow.wav^"                      // ses: level up (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ACH_UNLOCK ^"vexmira/meme/oof.wav^"                    // ses: ach unlock (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res SHOP_BUY ^"vexmira/meme/discord.wav^"                  // ses: shop buy (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res DAILY ^"vexmira/meme/taco.wav^"                        // ses: daily (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res VIP_JOIN ^"^"                                          // vip join (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res FREEZE ^"vexmira/arena51/world/freeze.wav^"            // ses: freeze (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res BURN ^"vexmira/arena51/world/burn.wav^"                // ses: burn (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res SW_FIRE ^"zombie_plague/zombie_burn3.wav^"             // ses: sw fire (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ZAP ^"vexmira/arena51/world/zap.wav^"                  // ses: zap (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res AIRDROP_INCOMING ^"vexmira/arena51/context/airdrop_incoming.wav^" // ses: airdrop incoming (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res AIRDROP_LAND ^"vexmira/arena51/context/airdrop_land.wav^" // ses: airdrop land (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res AIRDROP_LOOT ^"vexmira/arena51/context/airdrop_loot.wav^" // ses: airdrop loot (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res MODE9_MUSIC ^"^"                                       // Boss roundu muzigi (.wav ya da .mp3)",
"vex_res MODE2_MUSIC ^"^"                                       // Nemesis roundu muzigi (.wav ya da .mp3)",
"vex_res MODE3_MUSIC ^"^"                                       // Assassin roundu muzigi (.wav ya da .mp3)",
"vex_res MODE8_MUSIC ^"^"                                       // Armageddon roundu muzigi (.wav ya da .mp3)",
"vex_res VOX_BOSS ^"vox/warning _comma hostile presence detected^" // anons (vox) sesi: boss",
"vex_res VOX_BOSSDOWN ^"vox/target destroyed^"                  // anons (vox) sesi: bossdown",
"vex_res VOX_FINAL ^"vox/final round^"                          // anons (vox) sesi: final",
"vex_res VOX_INFECT ^"vox/biohazard detected^"                  // anons (vox) sesi: infect",
"vex_res VOX_LAST ^"vox/one remaining^"                         // anons (vox) sesi: last",
"vex_res VOX_AIRDROP ^"vox/supply deployed^"                    // anons (vox) sesi: airdrop",
"vex_res VOX_BLACKOUT ^"vox/power failure^"                     // anons (vox) sesi: blackout",
"vex_res VOX_STORM ^"vox/danger _comma electric field detected^" // anons (vox) sesi: storm",
"vex_res VOX_SPEED ^"vox/warning _comma high speed^"            // anons (vox) sesi: speed",
"vex_res VOX_MAPEND ^"vox/all objective secured^"               // anons (vox) sesi: mapend",
"vex_res AIRDROP_MODEL ^"models/vexmira/community/props/supplybox_fixed.mdl^" // model: airdrop model (bos = varsayilan)",
"vex_res AIRDROP_BODY_CHUTE ^"1^"",
"vex_res AIRDROP_BODY_LANDED ^"0^"",
"vex_res AIRDROP_SEQ_FALL ^"fall^"",
"vex_res AIRDROP_SEQ_IDLE ^"idle^"",
"vex_res EGG_MODEL ^"models/vexmira/community/props/w_goldenEgg.mdl^" // model: egg model (bos = varsayilan)",
"vex_res SOUND_BUDGET ^"200^"                                   // eklentinin yukleyebilecegi en fazla 3D ses sayisi (512 sinirina karsi koruma)",
"vex_res SOUND_BLOCK_STOCK ^"0^"",
"vex_res SOUND_BLOCK_EXTRA ^"^"                                 // sound block extra (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)",
"vex_res HUNTER_IMPACT ^"weapons/janus7_change1.wav^"           // ses: hunter impact (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res CHARGER_IMPACT ^"weapons/janus7_change1.wav^"          // ses: charger impact (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res ARACHNE_WEBHIT ^"weapons/janus7_change1.wav^"          // ses: arachne webhit (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res BURROWER_ERUPT ^"zombie_plague/nemesis1.wav^"          // ses: burrower erupt (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res SPOREMOTHER_BURST ^"weapons/janus7_change1.wav^"       // ses: sporemother burst (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res MIMIC_REVEAL ^"weapons/janus7_change1.wav^"            // ses: mimic reveal (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res VOLT_ZAP ^"zombie_plague/thunder1.wav^"                // ses: volt zap (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res HOOK_THROW ^"weapons/janus7_change1.wav^"              // ses: hook throw (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res HOOK_CHAIN ^"weapons/janus7_change1.wav^"              // ses: hook chain (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res HOOK_HIT ^"weapons/janus7_change1.wav^"                // ses: hook hit (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res HOOK_PULL ^"weapons/janus7_change1.wav^"               // ses: hook pull (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res HOOK_MISS ^"weapons/janus7_change1.wav^"               // ses: hook miss (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res HOOK_MODEL ^"^"                                        // model: hook model (bos = varsayilan)",
"vex_res SPORE_MODEL ^"^"                                       // model: spore model (bos = varsayilan)",
"vex_res VIP_V_KNIFE ^"models/vexmira/arena52/default/v_knife.mdl^" // model: vip v knife",
"vex_res VIP_P_KNIFE ^"models/p_knife.mdl^"                     // model: vip p knife",
"vex_res UI_VOTE_START ^"vexmira/arena51/context/ui_vote_start.wav^" // ses: ui vote start (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res UI_VOTE_END ^"vexmira/arena51/context/ui_vote_end.wav^" // ses: ui vote end (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res UI_BOSS_BAR ^"vexmira/arena51/context/ui_boss_bar.wav^" // ses: ui boss bar (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res UI_MENU_SELECT ^"vexmira/arena51/context/ui_menu_select.wav^" // ses: ui menu select (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res UI_CLASS_SELECT ^"vexmira/arena51/context/ui_class_select.wav^" // ses: ui class select (degistirmek icin kendi dosya yolunu yaz; ^"^" = sessiz)",
"vex_res MODE0_MUSIC ^"^"                                       // Enfeksiyon roundu muzigi (.wav ya da .mp3)",
"vex_res MODE1_MUSIC ^"^"                                       // Coklu Enfeksiyon roundu muzigi (.wav ya da .mp3)",
"vex_res MODE4_MUSIC ^"^"                                       // Survivor roundu muzigi (.wav ya da .mp3)",
"vex_res MODE5_MUSIC ^"^"                                       // Sniper roundu muzigi (.wav ya da .mp3)",
"vex_res MODE6_MUSIC ^"^"                                       // Swarm roundu muzigi (.wav ya da .mp3)",
"vex_res MODE7_MUSIC ^"^"                                       // Plague roundu muzigi (.wav ya da .mp3)",
"vex_res CSO_LANG ^"tr^"                                        // kart dili: tr / en / both (both = oyuncunun diline gore, ~30 dosya daha indirilir)",
"vex_res CSO_CARDSET ^"c532^"                                   // ekran kartlari: c532 = 5.3.2 buyuk resimli kartlar (onerilen, 10 indirme), vexmira = eski animasyonlu set (~120 indirme!), off = sadece yazi kart"
};
new const ZC_F_LANG[][] = {
"[en]",
"WELCOME = ^^4Welcome to ^^3VEXMIRA^^1, ^^3%s^^1! Grab a weapon, the night is long.",
"WELCOME_2 = ^^1^^4M^^1 = menu. ^^4/ozel^^1: 7 ozel silah | ^^4/shop^^1: Jetpack | ^^4/cosmetic^^1: collections.",
"WELCOME_3 = ^^1You're playing in ^^4English^^1. Prefer Turkish? Just type ^^4/dil^^1.",
"WELCOME_HUD = WELCOME, %s^^nV E X M I R A   -   Zombie Plague",
"DAILY_READY = ^^4[$] ^^1Your ^^4daily reward^^1 is ready! Type ^^4/daily^^1.",
"LANG_CHANGED = ^^1Language set to ^^4English^^1. Everything switched instantly.",
"GUNS_RESET = ^^1Weapon choice reset. You will pick again on your next spawn.",
"TAG_ZOMBIE = ZOMBIE",
"ON = ON",
"OFF = OFF",
"OWNED = owned",
"NEED_LEVEL = ^^1This requires ^^4level %d^^1.",
"HELP_1 = ^^3HUMANS:^^1 hold out until the timer ends. Every hit on a zombie earns ^^4AP^^1.",
"HELP_2 = ^^3ZOMBIES:^^1 claw humans to infect them. ^^4[R]^^1 or ^^4[G]^^1 = class ability. Bosses: ^^4[R]^^1 skill, ^^4[F]^^1/^^4[G]^^1 leap.",
"HELP_3 = ^^4AP^^1 = round money (shop, special guns). ^^4VC^^1 = rare coins (permanent perks).",
"HELP_4 = ^^130 rounds per map: bosses, special modes, events. ^^4/round^^1 shows the plan, ^^4/boss^^1 the bosses.",
"HELP_5 = ^^1/shop /special /guns /class /job /perks /daily /vip /lm /nades /quest /cosmetic /top10 /card",
"HELP_6 = ^^1Fun: /dice /coin /joke /dance /slot 20 /lotto /gift name 10 /bounty name 20 /ask question",
"UNSTUCK_WAIT = ^^1Wait ^^4%d^^1 seconds.",
"UNSTUCK_NOT = ^^1You are not stuck.",
"UNSTUCK_OK = ^^1You are free!",
"UNSTUCK_FAIL = ^^1No free spot found nearby.",
"ADM_NEXT_MODE = ^^4%s^^1 set the next round mode: ^^4#%d",
"ADM_NEXT_EVENT = ^^4%s^^1 set the next round event: ^^4#%d",
"RANK_0 = Recruit",
"RANK_1 = Survivor",
"RANK_2 = Hunter",
"RANK_3 = Slayer",
"RANK_4 = Veteran",
"RANK_5 = Warlord",
"RANK_6 = Legend",
"RANK_7 = Vexmira Elite",
"TITLE_0 = Auto (Rank)",
"TITLE_1 = Plaguebearer",
"TITLE_2 = Zombie Slayer",
"TITLE_3 = Bossbane",
"TITLE_4 = Last Stand",
"TITLE_5 = Headhunter",
"TITLE_6 = Immortal",
"TITLE_7 = Perfectionist",
"TITLE_8 = Devoted",
"TITLE_9 = Vexmira Legend",
"LEVEL_UP_HUD = LEVEL UP!^^nYou are now level %d",
"LEVELUP_VC = ^^1Level up reward: ^^4+%d VC^^1.",
"LEVELUP_CHAT = ^^3%s^^1 reached ^^4level %d^^1!",
"RANKUP_CHAT = ^^3%s^^1 is now a ^^4%s^^1!",
"UNLOCK_JOB = ^^4[NEW] ^^1Job unlocked: ^^4%s^^1  (/job)",
"UNLOCK_CLASS = ^^4[NEW] ^^1Zombie class unlocked: ^^4%s^^1  (/class)",
"UNLOCK_SW = ^^4[NEW] ^^1Special weapon unlocked: ^^4%s^^1  (/special)",
"UNLOCK_TITLE = ^^4[NEW] ^^1Title unlocked: ^^4%s^^1  (/title)",
"ACH_POPUP = ACHIEVEMENT UNLOCKED!",
"ACH_CHAT = ^^3%s^^1 unlocked achievement ^^4%s^^1!",
"ACH_NAME_0 = First Blood",
"ACH_DESC_0 = infect a human",
"ACH_NAME_1 = Exterminator",
"ACH_DESC_1 = kill 50 zombies",
"ACH_NAME_2 = Zombie Slayer",
"ACH_DESC_2 = kill 250 zombies",
"ACH_NAME_3 = Plaguebearer",
"ACH_DESC_3 = infect 100 humans",
"ACH_NAME_4 = Boss Hunter",
"ACH_DESC_4 = kill a boss / nemesis",
"ACH_NAME_5 = Bossbane",
"ACH_DESC_5 = kill 5 bosses",
"ACH_NAME_6 = Survivor",
"ACH_DESC_6 = win 10 rounds as human",
"ACH_NAME_7 = Last Stand",
"ACH_DESC_7 = win as the last human",
"ACH_NAME_8 = Headhunter",
"ACH_DESC_8 = 200 headshots",
"ACH_NAME_9 = Veteran",
"ACH_DESC_9 = reach level 10",
"ACH_NAME_10 = Immortal",
"ACH_DESC_10 = reach level 30",
"ACH_NAME_11 = Legend",
"ACH_DESC_11 = reach level 50",
"ACH_NAME_12 = Devoted",
"ACH_DESC_12 = 7-day daily streak",
"ACH_NAME_13 = Perfectionist",
"ACH_DESC_13 = max out a perk",
"DAILY_WAIT = ^^1Already claimed. Next reward in ^^4%dh %dm^^1.",
"DAILY_HUD = DAILY REWARD  -  DAY %d^^n+%d AP   +%d VC   +%d XP",
"DAILY_CHAT = ^^4[$] ^^1Daily reward (day ^^4%d^^1): ^^4+%d AP^^1, ^^4+%d VC^^1, ^^4+%d XP^^1",
"DAILY_NEXT = ^^1Come back tomorrow, the streak bonus grows up to day 7!",
"ZOMBIE_REPLACED = ^^1The last zombie left. A new carrier has been chosen!",
"ROUND_CHAT = ^^1Round ^^4%d^^1 begins. Stay sharp.",
"ROUND_CALM = ROUND %d^^nAn uneasy calm...",
"COUNTDOWN = THE PLAGUE SPREADS IN   %d",
"NEED_PLAYERS = Waiting for more survivors...",
"GAME_COMMENCING = ^^1New players joined. ^^4Restarting the round^^1...",
"HUMANS_WIN = HUMANS SURVIVED!",
"ZOMBIES_WIN = THE PLAGUE CONSUMES ALL!",
"MVP_CHAT = ^^4[MVP] ^^3%s^^1 dealt ^^4%d^^1 damage this round! ^^4+1 VC",
"TOPINF_CHAT = ^^3%s^^1 infected ^^4%d^^1 humans this round!",
"ROUND_SUMMARY = ROUND SUMMARY^^nDamage %d  |  Kills %d  |  Infections %d  |  +%d XP  +%d AP",
"RESPAWN_IN = You rise again in %d...",
"LAST_HUMAN = LAST SURVIVOR!^^nMake it count.",
"LAST_HUMAN_CHAT = ^^3%s^^1 is the ^^4last human^^1! +150 HP, +200 armor.",
"INFECTED_BY = ^^3%s^^1 was infected by ^^3%s^^1!",
"ADV_1 = ^^1Press ^^4M^^1 anytime, the whole server lives in that menu.",
"ADV_2 = ^^4[$] ^^1Every ^^4500^^1 damage = ^^4+1 AP^^1. Headshots pay extra, aim high!",
"ADV_3 = ^^1There are ^^416 jobs^^1. New ones unlock as you level up: ^^4/job",
"ADV_4 = ^^1Special weapons burn, freeze and electrocute zombies. ^^4/special",
"ADV_5 = ^^4[$] ^^1Did you grab your ^^4daily reward^^1 today? ^^4/daily^^1, streaks pay more!",
"ADV_6 = ^^1Turn ^^4VC^^1 into permanent power: HP, damage, AP gain. ^^4/perks",
"ADV_7 = ^^1Low FPS? ^^4/fps^^1 has performance presets just for you.",
"ADV_8 = ^^1Make the server yours: HUD color, sounds, effects in ^^4/settings^^1.",
"ADV_9 = ^^1Zombies, the shop has an ^^4Antidote^^1 and an ^^4Infection Bomb^^1 waiting for you.",
"ADV_10 = ^^1Achievements unlock titles that show up next to your name. ^^4/ach",
"ADV_11 = ^^1Stuck in a wall? ^^4/unstuck^^1 has your back.",
"ADV_12 = ^^1Curious about the modes? ^^4/modes^^1 explains every one of them.",
"MODE_NAME_0 = Infection",
"MODE_DESC_0 = ^^4[Infection] ^^1One zombie, the plague spreads.",
"MODE_START_0 = THE PLAGUE HAS BEGUN!^^nRun, survivors!",
"MODE_NAME_1 = Multi Infection",
"MODE_DESC_1 = ^^4[Multi Infection] ^^1Several zombies from the start.",
"MODE_START_1 = MULTI INFECTION!^^nThey are everywhere!",
"MODE_NAME_2 = Nemesis",
"MODE_DESC_2 = ^^4[Nemesis] ^^1One huge zombie that ^^3kills in ONE hit^^1. [R] leap, [F] rage.",
"MODE_START_2 = NEMESIS!^^nIt does not infect. It kills.",
"MODE_ANN_2 = NEMESIS ROUND^^nOne huge zombie that kills instead of infecting.",
"MODE_NAME_3 = Assassin",
"MODE_DESC_3 = ^^4[Assassin] ^^1A very fast zombie that ^^3kills in ONE hit^^1, hunting in the dark.",
"MODE_START_3 = ASSASSIN!^^nThe lights die. Something fast is coming.",
"MODE_ANN_3 = ASSASSIN ROUND^^nA very fast zombie hunts in the dark.",
"MODE_NAME_4 = Survivor",
"MODE_DESC_4 = ^^4[Survivor] ^^1One armed hero against all zombies.",
"MODE_START_4 = SURVIVOR!^^nOne hero against the horde!",
"MODE_ANN_4 = SURVIVOR ROUND^^nOne armed hero against all zombies.",
"MODE_NAME_5 = Sniper",
"MODE_DESC_5 = ^^4[Sniper] ^^1One sniper with a one-shot AWP.",
"MODE_START_5 = SNIPER!^^nOne shot. One kill.",
"MODE_ANN_5 = SNIPER ROUND^^nOne sniper with a one-shot AWP.",
"MODE_NAME_6 = Swarm",
"MODE_DESC_6 = ^^4[Swarm] ^^1Half zombies, no infection, only blood.",
"MODE_START_6 = SWARM!^^nNo infection. Only blood.",
"MODE_ANN_6 = SWARM ROUND^^nHalf zombies, no infection, only blood.",
"MODE_NAME_7 = Plague",
"MODE_DESC_7 = ^^4[Plague] ^^1Survivor + Nemesis + zombies vs humans.",
"MODE_START_7 = PLAGUE!^^nSurvivor and Nemesis enter the fight!",
"MODE_ANN_7 = PLAGUE ROUND^^nSurvivor + Nemesis + zombies vs humans.",
"MODE_NAME_8 = Armageddon",
"MODE_DESC_8 = ^^4[Armageddon] ^^1Nemesis army vs Survivor army.",
"MODE_START_8 = ARMAGEDDON!^^nThe final war begins!",
"MODE_ANN_8 = ARMAGEDDON ROUND^^nNemesis army vs Survivor army.",
"MODE_ANN_9 = BOSS ROUND^^nA giant boss is coming. Everyone together!",
"MODE_NAME_9 = BOSS",
"MODE_DESC_9 = ^^4[BOSS] ^^13 phases, 5 skills: a NEW [R] skill every phase. Watch the colored circles!",
"MODE_START_9 = BOSS ROUND",
"ROLE_NEMESIS = ^^3%s^^1 has become the ^^3NEMESIS^^1!",
"ROLE_ASSASSIN = ^^3%s^^1 has become the ^^3ASSASSIN^^1!",
"ROLE_SURVIVOR = ^^3%s^^1 is the ^^4SURVIVOR^^1!",
"ROLE_SNIPER = ^^3%s^^1 is the ^^4SNIPER^^1!",
"NEMESIS_DOWN = ^^1The Nemesis was slain by ^^3%s^^1!",
"ASSASSIN_DOWN = ^^1The Assassin was slain by ^^3%s^^1!",
"EV_NAME_0 = Normal",
"EV_NAME_1 = Blood Moon",
"EV_ANN_1 = EVENT: BLOOD MOON^^nThe sky bleeds. Zombies are much tougher!",
"EV_NAME_2 = Thick Fog",
"EV_ANN_2 = EVENT: THICK FOG^^nYou can barely see ahead...",
"EV_NAME_3 = Speed Rush",
"EV_ANN_3 = EVENT: SPEED RUSH^^nEveryone 50%% faster - no slowdown, wide view!",
"EV_NAME_4 = Low Gravity",
"EV_ANN_4 = EVENT: LOW GRAVITY^^nThe air feels weightless.",
"EV_NAME_5 = Double Damage",
"EV_ANN_5 = EVENT: DOUBLE DAMAGE^^nHumans deal double damage!",
"EV_NAME_6 = Dark Night",
"EV_ANN_6 = EVENT: DARK NIGHT^^nLights out. Stay together!",
"EV_NAME_7 = Plague Outbreak",
"EV_ANN_7 = EVENT: PLAGUE OUTBREAK^^nMore zombies at the start!",
"EV_NAME_8 = Supply Drop",
"EV_ANN_8 = EVENT: SUPPLY DROP^^nArmor, HE and frost grenade for everyone!",
"EV_NAME_9 = Berserk",
"EV_ANN_9 = EVENT: BERSERK^^nZombies regenerate and run faster!",
"EV_NAME_10 = Adrenaline",
"EV_ANN_10 = EVENT: ADRENALINE^^nHumans regenerate and move faster!",
"EV_NAME_11 = Meteor Shower",
"EV_ANN_11 = EVENT: METEOR SHOWER^^nWatch the red rings. Move!",
"EV_NAME_12 = Zombie Horde",
"EV_ANN_12 = EVENT: ZOMBIE HORDE^^nWeaker zombies, but many and fast respawn!",
"EV_NAME_13 = Titan Hour",
"EV_ANN_13 = EVENT: TITAN HOUR^^nOne zombie. Enormous.",
"EV_NAME_14 = Gold Rush",
"EV_ANN_14 = EVENT: GOLD RUSH^^nDOUBLE AP and XP this round!",
"EV_NAME_15 = Vampire Night",
"EV_ANN_15 = EVENT: VAMPIRE NIGHT^^nHumans steal life with every hit!",
"EV_NAME_16 = Headhunter",
"EV_ANN_16 = EVENT: HEADHUNTER^^nHeadshots deal double damage and give bonus AP!",
"HUD_TOP = [ VEXMIRA ]   Round %d   :   %s   :   %s   :   Humans %d / Zombies %d   :   %d:%02d",
"HUD_P1 = LV.%d   //   %s",
"HUD_P2 = XP  [%s]  %d / %d",
"HUD_P3 = AP  %d      VC  %d      STREAK  %d",
"HUD_CLASS_CD = %s   ::   [R/G]  %d s",
"HUD_CLASS_READY = %s   ::   [R/G]  READY",
"HUD_LEAP_CD = [R] Leap : %d s",
"HUD_LEAP_READY = [R] Leap : READY",
"HUD_JOB = JOB  %s",
"HUD_HEADSHOT = HEADSHOT!",
"MULTI_2 = DOUBLE KILL!",
"MULTI_3 = TRIPLE KILL!",
"MULTI_4 = MULTI KILL!",
"MULTI_5 = MEGA KILL!",
"MULTI_6 = MONSTER KILL!",
"STREAK_5 = ^^3%s^^1 is on a ^^4RAMPAGE^^1! (%d kills)",
"STREAK_10 = ^^3%s^^1 is ^^4UNSTOPPABLE^^1! (%d kills)",
"STREAK_15 = ^^3%s^^1 is ^^4GODLIKE^^1! (%d kills)",
"ABILITY_COOL = Ability recharging: %d s",
"BOSS_NAME_0 = BRUTE",
"BOSS_ANN_0 = BOSS ROUND^^nThe BRUTE is coming...",
"BOSS_ABIL_0 = GROUND SLAM!^^nThe floor shatters!",
"BOSS_START_0 = THE BRUTE HAS AWAKENED!^^nBring it down together!",
"BOSS_NAME_1 = BANSHEE",
"BOSS_ANN_1 = BOSS ROUND^^nThe BANSHEE is screaming...",
"BOSS_ABIL_1 = DEAFENING SCREAM!^^nYou can't see!",
"BOSS_START_1 = THE BANSHEE HAS AWAKENED!^^nDon't let her scream...",
"BOSS_NAME_2 = OVERLORD",
"BOSS_ANN_2 = BOSS ROUND^^nThe OVERLORD rises...",
"BOSS_ABIL_2 = SUMMON!^^nThe fallen rise as minions!",
"BOSS_START_2 = THE OVERLORD HAS AWAKENED!^^nThe dead will rise!",
"BOSS_NAME_3 = INFERNO",
"BOSS_ANN_3 = BOSS ROUND^^nThe INFERNO ignites...",
"BOSS_ABIL_3 = FIRE WAVE!^^nYou are burning!",
"BOSS_START_3 = THE INFERNO HAS AWAKENED!^^nEverything burns!",
"BOSS_NAME_4 = REAPER",
"BOSS_ANN_4 = BOSS ROUND^^nThe REAPER hunts...",
"BOSS_ABIL_4 = SOUL STRIKE!^^nIt teleports to a victim!",
"BOSS_START_4 = THE REAPER HAS AWAKENED!^^nThere is no hiding!",
"BOSS_SPAWNED = ^^3%s^^1 has become the ^^3BOSS^^1! Take it down!",
"BOSS_BAR = %s^^n%s^^n%d / %d",
"BOSS_ENRAGE = RAGE MODE!^^nFaster, deadlier, abilities every 5 seconds!",
"BOSS_DOWN = ^^1The Boss was slain by ^^3%s^^1!",
"BOSS_DOWN_HUD = THE BOSS IS DEAD!^^nHumanity prevails!",
"CLASS_0 = Walker",
"CLASS_DESC_0 = Balanced. [R] speed burst",
"CLASS_1 = Runner",
"CLASS_DESC_1 = Fast, fragile. [R] long leap",
"CLASS_2 = Tank",
"CLASS_DESC_2 = Slow, huge HP. [R] damage shield",
"CLASS_3 = Banshee",
"CLASS_DESC_3 = Agile. [R] blinding scream",
"CLASS_4 = Leech",
"CLASS_DESC_4 = Heals on infect. [R] drain life",
"CLASS_5 = Stalker",
"CLASS_DESC_5 = Silent steps. [R] invisibility 6s",
"CLASS_6 = Bomber",
"CLASS_DESC_6 = Explodes on death. [R] toxic cloud",
"CLASS_7 = Frost",
"CLASS_DESC_7 = Cold aura. [R] frost nova (slows)",
"MENU_CLASS = Zombie Class",
"MENU_CLASS_SUB = Applies on your next infection",
"CLASS_CHOSEN = ^^1Zombie class selected: ^^4%s^^1. Show them what you've got!",
"CLASS_NEXT = ^^1Your new class becomes active ^^4on your next infection^^1.",
"JOB_0 = Medic",
"JOB_DESC_0 = regenerates HP, cheap medkits",
"JOB_1 = Heavy",
"JOB_DESC_1 = -15 percent damage taken, +100 armor",
"JOB_2 = Scout",
"JOB_DESC_2 = +12 percent movement speed",
"JOB_3 = Marksman",
"JOB_DESC_3 = +20 percent damage to zombies",
"JOB_4 = Engineer",
"JOB_DESC_4 = 25 percent shop discount, +1 laser slot, half-price lasers",
"JOB_5 = Looter",
"JOB_DESC_5 = +50 percent AP gain",
"JOB_6 = Gunner",
"JOB_DESC_6 = auto ammo refill every 10s",
"JOB_7 = Demolitions",
"JOB_DESC_7 = free fire grenade, +50 percent nade dmg",
"JOB_8 = Sniper",
"JOB_DESC_8 = +50 percent headshot damage",
"JOB_9 = Paratrooper",
"JOB_DESC_9 = low gravity, no fall damage",
"JOB_10 = Pyro",
"JOB_DESC_10 = 15 percent chance to ignite zombies",
"JOB_11 = Cryo",
"JOB_DESC_11 = 10 percent chance to freeze zombies",
"JOB_12 = Vampire",
"JOB_DESC_12 = steals 5 percent of damage as HP",
"JOB_13 = Guardian",
"JOB_DESC_13 = +50 max HP",
"JOB_14 = Berserker",
"JOB_DESC_14 = +40 percent damage below 40 HP",
"JOB_15 = Commander",
"JOB_DESC_15 = +10 percent damage aura for allies",
"MENU_JOB = Human Jobs",
"MENU_JOB_SUB = Passive bonus while you are human",
"JOB_CHOSEN = ^^1Job selected: ^^4%s^^1. Good choice!",
"MENU_BACK = Back",
"MENU_NEXT = Next",
"MENU_EXIT = Exit",
"MENU_LOCKED = LOCKED",
"MENU_MAIN_SUB = [/menu]  [/vip]  [/cosmetic]  [/top10]",
"MENU_WALLET = AP: %d   VC: %d   Lv.%d",
"MENU_WALLET_AP = Your AP: %d",
"MENU_WALLET_VC = Your VC: %d",
"MAIN_1 = Items (Ammo Packs)",
"MAIN_2 = Special Weapons",
"MAIN_3 = Weapons",
"MAIN_4 = Zombie Class",
"MAIN_5 = Human Job",
"MAIN_6 = Daily Reward",
"MAIN_7 = Perks (Vex Coins)",
"MAIN_8 = \yVIP Menu",
"MAIN_9 = Fun & Games",
"MAIN_10 = Profile",
"MAIN_11 = Settings",
"MAIN_12 = Language / Dil",
"MAIN_13 = Unstuck",
"MAIN_14 = Game Modes",
"MAIN_15 = Help",
"MENU_PROFILE = Profile",
"PROF_1 = My Stats",
"PROF_2 = Achievements",
"PROF_3 = Titles",
"PROF_4 = Chat Style",
"MENU_SHOP_H = Human Shop",
"MENU_SHOP_Z = Zombie Shop",
"ITEM_0 = Medkit",
"ITEM_DESC_0 = +100 HP",
"ITEM_1 = Armor",
"ITEM_DESC_1 = 200 kevlar + helmet",
"ITEM_2 = Fire Grenade",
"ITEM_DESC_2 = burns zombies",
"ITEM_3 = Frost Grenade",
"ITEM_DESC_3 = freezes zombies 3s",
"ITEM_4 = Flare",
"ITEM_DESC_4 = lights the area 25s",
"ITEM_5 = Extra Jump (VIP)",
"ITEM_DESC_5 = +1 air jump this life, VIP only",
"ITEM_6 = Gravity Boots",
"ITEM_DESC_6 = low gravity, no fall dmg",
"ITEM_7 = Speed Serum",
"ITEM_DESC_7 = +12 percent speed",
"ITEM_8 = Unlimited Clip",
"ITEM_DESC_8 = never reload this life",
"ITEM_9 = Damage Amplifier",
"ITEM_DESC_9 = +30 percent damage this life",
"ITEM_10 = Respawn Token",
"ITEM_DESC_10 = revive as human (while dead)",
"ITEM_11 = T-Virus Antidote",
"ITEM_DESC_11 = become human again",
"ITEM_12 = Zombie Madness",
"ITEM_DESC_12 = immune to damage 5s",
"ITEM_13 = Infection Bomb",
"ITEM_DESC_13 = infects humans in range",
"ITEM_14 = Mutagen",
"ITEM_DESC_14 = +1000 HP",
"ITEM_15 = Rage",
"ITEM_DESC_15 = +15 percent speed, +20 percent dmg",
"ITEM_16 = Quick Recharge",
"ITEM_DESC_16 = ability ready now",
"ITEM_17 = Bone Armor",
"ITEM_DESC_17 = -20 percent damage taken",
"SHOP_SOLDOUT = limit",
"SHOP_EXCHANGE = Exchange %d AP -> 1 VC",
"SHOP_EXCHANGED = ^^4[$] ^^1Exchanged your AP for ^^41 VC^^1.",
"SHOP_NOAP = ^^1Not enough ^^4AP^^1. Deal damage to zombies to earn more!",
"SHOP_NOVC = ^^1Not enough ^^4VC^^1. Level up, claim daily rewards, earn achievements!",
"SHOP_UNAVAIL = ^^1You can't buy that right now.",
"ZC_ITEM_OFF = ^^1is switched off on this server (a file is missing). Admin: zc_modules",
"SHOP_LIMIT = ^^1Round limit reached for this item.",
"SHOP_ALREADY = ^^1You already have that.",
"SHOP_BOUGHT = ^^4[$] ^^1You bought ^^4%s^^1 ^^3(-%d AP)^^1. Enjoy!",
"MENU_SPECIAL = Special Weapons",
"SW_BOUGHT = ^^4[$] ^^1You equipped ^^4%s^^1! Lasts until you die.",
"MENU_PERKS = Permanent Perks",
"PERK_0 = Vitality",
"PERK_DESC_0 = +10 HP per level",
"PERK_1 = Plating",
"PERK_DESC_1 = +15 armor per level",
"PERK_2 = Firepower",
"PERK_DESC_2 = +3 percent damage per level",
"PERK_3 = Fortune",
"PERK_DESC_3 = +10 percent AP per level",
"PERK_4 = Agility",
"PERK_DESC_4 = +2 percent speed per level",
"PERK_5 = Undead Hide",
"PERK_DESC_5 = +6 percent zombie HP per level",
"PERK_MAXED = ^^1This perk is already at max level.",
"PERK_UP = ^^1Perk upgraded: ^^4%s^^1. Getting stronger!",
"MENU_TITLE = Titles",
"TITLE_LOCKED = ^^1This title is locked. Unlock its achievement first.",
"TITLE_SELECTED = ^^1Title equipped: ^^4%s^^1. Looking good!",
"MENU_ACH = Achievements",
"MENU_STYLE = Chat Style",
"STYLE_0 = Classic",
"STYLE_DESC_0 = green tag, team-colored name",
"STYLE_1 = Neon",
"STYLE_DESC_1 = rank-colored, compact",
"STYLE_2 = Minimal",
"STYLE_DESC_2 = name only",
"STYLE_CHOSEN = ^^1Chat style updated. Say something!",
"MENU_SETTINGS = Personal Settings",
"MENU_SETTINGS_SUB = Saved to your profile",
"SET_0 = HUD panel",
"SET_1 = Damage numbers",
"SET_2 = Screen effects",
"SET_3 = Ambient sounds",
"SET_4 = Kill announcer",
"SET_5 = Chat tips",
"SET_6 = Auto loadout",
"SET_7 = Fog",
"SET_THEME = HUD color",
"SET_LANG = Language",
"SET_FPS = FPS / Performance >",
"THEME_0 = Vexmira",
"THEME_1 = Toxic",
"THEME_2 = Blood",
"THEME_3 = Amethyst",
"THEME_4 = Ocean",
"THEME_5 = Sunset",
"MENU_LANG = Language / Dil",
"MENU_FPS = FPS / Performance",
"MENU_FPS_SUB = Presets reduce effects sent to you",
"FPS_1 = Preset: Performance (max FPS)",
"FPS_2 = Preset: Balanced",
"FPS_3 = Preset: Cinematic (all effects)",
"FPS_4 = Print FPS boost config to console",
"FPS_5 = Print network (rate) config to console",
"FPS_PRESET_PERF = ^^1Performance mode: effects, fog and ambient sounds off.",
"FPS_PRESET_BAL = ^^1Balanced mode: effects on, fog and ambient off.",
"FPS_PRESET_CINE = ^^1Cinematic mode: everything on. Enjoy the show!",
"FPS_CONSOLE_HINT = Copy these lines into your config.cfg or type them in console",
"FPS_PRINTED = ^^1Settings printed to your ^^4console^^1 (press ~).",
"MENU_ADMIN = Admin Panel",
"ADM_SET_MODE = Mode",
"ADM_SET_EVENT = Event",
"STATS_1 = ^^1Level ^^4%d^^1 (^^4%s^^1)  XP ^^4%d^^1 / %d",
"STATS_2 = ^^1Wallet: ^^4%d AP^^1, ^^4%d VC",
"STATS_3 = ^^1Kills ^^4%d^^1  Infections ^^4%d^^1  Headshots ^^4%d",
"STATS_4 = ^^1Wins ^^4%d^^1  Boss kills ^^4%d^^1  Achievements ^^4%d/%d",
"STATS_5 = ^^1Play time ^^4%dh %dm^^1  Daily streak ^^4%d",
"TOP_TITLE = ^^1TOP PLAYERS ONLINE",
"TOP_LINE = ^^4#%d ^^3%s^^1 - Lv.^^4%d^^1 (%d XP)",
"MENU_PRIMARY = Primary Weapon",
"MENU_GUNS_SUB = Saved; given automatically every spawn",
"MENU_SECONDARY = Secondary Weapon",
"GUNS_SAVED = ^^1Loadout saved! Type ^^4/guns^^1 to change it.",
"ADV_13 = ^^4[VIP] ^^1VIPs get ^^4double jump^^1, more AP/XP, a free pack every round and more. ^^4/vipinfo",
"ADV_14 = ^^1Feeling lucky? ^^4/slot 20^^1 or buy a ticket with ^^4/lotto^^1.",
"ADV_15 = ^^1Someone annoying you? Put a bounty on them: ^^4/bounty name 50",
"ADV_16 = ^^1Join our community! ^^4/discord",
"MAIN_16 = Top Players",
"MAIN_17 = \rAdmin Menu",
"YOU_INFECTED = ^^1You got bitten by ^^3%s^^1... you're one of them now. Use ^^4[R]^^1 for your ability!",
"YOU_INFECTOR = ^^1Nice bite! ^^3%s^^1 has joined your horde.",
"YOU_FIRST_ZOMBIE = ^^1You are ^^3patient zero^^1! Extra HP, go spread the plague. ^^4[R]^^1 = ability",
"YOU_FIRST_ZOMBIE_HUD = YOU ARE PATIENT ZERO",
"YOU_DIED_ZOMBIE = ^^1Down, but not out. You rise again in ^^4%d^^1 seconds.",
"ANTIDOTE_ALL = ^^3%s^^1 drank the antidote and is ^^4human again^^1!",
"ROLE_NEMESIS_YOU = YOU ARE THE NEMESIS - ONE HIT KILLS^^n[R] leap     [F] or [G] rage",
"ROLE_ASSASSIN_YOU = YOU ARE THE ASSASSIN - ONE HIT KILLS^^n[R] leap     [F] or [G] shadow veil",
"ROLE_SURVIVOR_YOU = YOU ARE THE SURVIVOR - unlimited ammo, hold the line",
"ROLE_SNIPER_YOU = YOU ARE THE SNIPER - one shot, one kill",
"ROLE_BOSS_YOU = ^^1You are the ^^3BOSS^^1! ^^4[R]^^1 = special skill, ^^4[F]^^1 or ^^4[G]^^1 = leap.",
"HUD_10S = 10 SECONDS LEFT!",
"VIP_TIER_1 = VIP",
"VIP_TIER_2 = ELITE",
"VIP_JOIN = ^^4[%s] ^^3%s^^1 has arrived. Make some room!",
"VIP_JOIN_HUD = %s  %s  joined the server",
"VIP_ENDING = ^^1Heads up: your VIP ends in ^^4%d^^1 day(s). Renew to keep your perks!",
"VIP_DAYS_LEFT = ^^1Welcome back! ^^4%d^^1 days of VIP left. ^^4/vip^^1 for your menu.",
"VIP_EXPIRED = ^^1Your VIP has expired. We miss you already, ^^4/vipinfo^^1 to renew.",
"VIP_GRANTED = ^^1Your VIP is active for ^^4%d^^1 more days. Thank you for supporting us!",
"VIP_ONLY = ^^1That one is ^^4VIP only^^1. See ^^4/vipinfo^^1.",
"VIP_LEFT_DAYS = %d days left",
"VIP_PERMANENT = permanent",
"MENU_VIP = VIP Lounge",
"VIPM_FREE_H = Free VIP pack (once per round)",
"VIPM_FREE_Z = Free zombie pack (once per round)",
"VIPM_AURA = Aura",
"AURA_0 = off",
"AURA_1 = Cyan",
"AURA_2 = Gold",
"AURA_3 = Purple",
"AURA_4 = Red",
"AURA_5 = Green",
"VIPM_TRAIL = Light trail",
"VIPM_JUMPS = My jump perks",
"VIPM_INFO = All VIP perks",
"VIP_JUMPS_VIP = ^^1You have ^^4double jump^^1: press jump again mid-air. ^^4ELITE^^1 gets triple!",
"VIP_JUMPS_ELITE = ^^4[ELITE] ^^1You have ^^4triple jump^^1! Buy an Extra Jump in the shop for one more.",
"VIP_FREE_USED = ^^1You already took this round's pack. See you next round!",
"VIP_FREE_H_VIP = ^^1Pack delivered: ^^4200 armor^^1, ^^4fire^^1 and ^^4frost^^1 grenade. Go get them!",
"VIP_FREE_H_ELITE = ^^4[ELITE] ^^1Pack delivered: armor, 3 grenades, ^^4+100 HP^^1 and ^^4+30 percent damage^^1!",
"VIP_FREE_Z_VIP = ^^1Zombie pack: ^^4+500 HP^^1. Go hunt!",
"VIP_FREE_Z_ELITE = ^^4[ELITE] ^^1Zombie pack: ^^4+1000 HP^^1 and your ability is ready!",
"VIPINFO_1 = ^^4===== VEXMIRA VIP / ELITE =====",
"VIPINFO_2 = ^^4[1] ^^1Double jump (^^4ELITE^^1: triple jump) with a colored ring effect",
"VIPINFO_3 = ^^4[2] ^^1+25 percent AP and XP (^^4ELITE^^1: +50 percent)",
"VIPINFO_4 = ^^4[3] ^^1Free pack every round: armor + fire + frost grenade (^^4ELITE^^1: +HP, +damage)",
"VIPINFO_5 = ^^4[4] ^^1Shop and special weapons 10 percent cheaper (^^4ELITE^^1: 20 percent)",
"VIPINFO_6 = ^^4[5] ^^1Spawn armor, faster zombie respawn, bigger daily reward",
"VIPINFO_7 = ^^4[6] ^^1Colored aura, light trail, [VIP]/[ELITE] tag and a join announcement",
"VIPINFO_8 = ^^4[7] ^^1VIP-only Extra Jump item in the shop",
"VIPINFO_BUY = ^^4[$] ^^1Want VIP? Reach us at: ^^4%s",
"FUN_WAIT = ^^1Easy there! Try again in ^^4%d^^1 seconds.",
"FUN_DICE = ^^4[ZAR] ^^3%s^^1 rolled the dice: ^^4%d",
"FUN_DICE_6 = ^^4[ZAR] ^^3%s^^1 rolled a ^^4%d^^1! Lucky one!",
"FUN_COIN_HEADS = ^^4[COIN] ^^3%s^^1 flipped a coin: ^^4HEADS",
"FUN_COIN_TAILS = ^^4[COIN] ^^3%s^^1 flipped a coin: ^^4TAILS",
"FUN_ROLL = ^^4[ROLL] ^^3%s^^1 rolled ^^4%d^^1 (1-%d)",
"FUN_BALL_USAGE = ^^1Ask me anything: ^^4/ask Will we win this round?",
"FUN_BALL_Q = ^^3%s^^1 asks: ^^4%s",
"BALL_1 = ^^4Vexmira^^1 says: ^^4Absolutely, no doubt about it.",
"BALL_2 = ^^4Vexmira^^1 says: ^^4The zombies say no.",
"BALL_3 = ^^4Vexmira^^1 says: ^^4Ask me again after this round.",
"BALL_4 = ^^4Vexmira^^1 says: ^^4Signs point to yes.",
"BALL_5 = ^^4Vexmira^^1 says: ^^4Not a chance. Sorry!",
"BALL_6 = ^^4Vexmira^^1 says: ^^4Hmm... maybe. Keep your knife close.",
"BALL_7 = ^^4Vexmira^^1 says: ^^4Yes, if you stop camping.",
"BALL_8 = ^^4Vexmira^^1 says: ^^4My sources say no.",
"BALL_9 = ^^4Vexmira^^1 says: ^^4It is certain.",
"BALL_10 = ^^4Vexmira^^1 says: ^^4Better not tell you now...",
"BALL_11 = ^^4Vexmira^^1 says: ^^4Only if you buy a medkit first.",
"BALL_12 = ^^4Vexmira^^1 says: ^^4The stars and the brains align: YES.",
"JOKE_1 = ^^4[JOKE] ^^1Why don't zombies eat clowns? They taste funny.",
"JOKE_2 = ^^4[JOKE] ^^1A zombie walks into a bar and orders... BRAAAINS. And a medkit for the road.",
"JOKE_3 = ^^4[JOKE] ^^1My aim is so bad, the zombies feel safe around me.",
"JOKE_4 = ^^4[JOKE] ^^1Zombies are great at teamwork. They really put their heads together.",
"JOKE_5 = ^^4[JOKE] ^^1Why was the zombie late? It took the long way to the brain.",
"JOKE_6 = ^^4[JOKE] ^^1I'm not camping, I'm guarding this corner for the team.",
"JOKE_7 = ^^4[JOKE] ^^1Zombies never get lost. They follow their guts.",
"JOKE_8 = ^^4[JOKE] ^^1The last human always says 'I've got this'. History disagrees.",
"JOKE_9 = ^^4[JOKE] ^^1What do zombies wear in winter? Bite-proof jackets.",
"JOKE_10 = ^^4[JOKE] ^^1I bought a frost grenade. Now even my K/D is frozen.",
"JOKE_11 = ^^4[JOKE] ^^1Zombie diet tip: eat brains, they are full of smart ideas.",
"JOKE_12 = ^^4[JOKE] ^^1Nemesis walked in. Everyone suddenly remembered they had homework.",
"FUN_DANCE_1 = ^^4* ^^1^^3%s^^1 is breakdancing in the middle of the apocalypse!",
"FUN_DANCE_2 = ^^4* ^^1^^3%s^^1 does the zombie shuffle. Smooth!",
"FUN_DANCE_3 = ^^4* ^^1^^3%s^^1 dances like nobody is infected.",
"FUN_DANCE_4 = ^^4* ^^1^^3%s^^1 drops a victory dance. Is the round over already?",
"FUN_RS = ^^1Score reset. Fresh start, make it count!",
"FUN_TIME = ^^1Server time: ^^4%s",
"FUN_PING_GOOD = ^^1Ping ^^4%d^^1 ms, loss %d. Smooth as butter!",
"FUN_PING_OK = ^^1Ping ^^4%d^^1 ms, loss %d. Playable.",
"FUN_PING_BAD = ^^1Ping ^^4%d^^1 ms, loss %d. Try /fps for net settings.",
"FUN_WHO_TITLE = ^^1Online staff and VIPs:",
"FUN_WHO_NONE = ^^1   Nobody right now. Ghost town!",
"FOUNDERS_1 = ^^1VEXMIRA was founded by ^^3SmurfSexy^^1 and ^^3Capital^^1.",
"FOUNDERS_2 = ^^1Built with love for zombie fans. Thanks for playing with us!",
"FOUNDERS_3 = ^^1Ideas, bugs, VIP: ^^4/discord",
"FUN_CONTACT = ^^1Our community: ^^4%s^^1 - come say hi!",
"RULE_1 = ^^4[KURALLAR / RULES]",
"RULE_2 = ^^41. ^^1No cheats, no scripts. Instant ban.",
"RULE_3 = ^^42. ^^1Respect everyone. No insults, no hate.",
"RULE_4 = ^^43. ^^1No spamming the chat or the mic.",
"RULE_5 = ^^44. ^^1No bug abuse or map exploits.",
"RULE_6 = ^^45. ^^1Have fun and help the newcomers!",
"SLOT_USAGE = ^^4[SLOT] ^^1Usage: ^^4/slot 20^^1 (bet 5-200 AP). Three 7s pay x10!",
"SLOT_JACKPOT = ^^4[SLOT] ^^3%s^^1 hit the ^^4JACKPOT^^1 and won ^^4%d AP^^1!",
"SLOT_WIN = ^^4[SLOT] ^^1Nice! You won ^^4%d AP^^1.",
"SLOT_LOSE = ^^4[SLOT] ^^1Not this time... ^^3-%d AP^^1. One more spin?",
"LOTTO_MAX = ^^1Max ^^4%d^^1 tickets per draw. Good luck!",
"LOTTO_BOUGHT = ^^4[LOTTO] ^^1Ticket bought (you have ^^4%d^^1). Pot: ^^4%d AP^^1, draw in about ^^4%d^^1 min.",
"LOTTO_SOON = ^^4[LOTTO] ^^1Draw in ^^41 minute^^1! Pot: ^^4%d AP^^1. Last chance: ^^4/lotto",
"LOTTO_REFUND = ^^4[LOTTO] ^^1Not enough players joined the draw, your tickets were refunded.",
"LOTTO_WINNER = ^^4[LOTTO] ^^3%s^^1 won the jackpot: ^^4%d AP^^1 (with %d tickets)! Congrats!",
"GIFT_USAGE = ^^1Usage: ^^4/gift name 20^^1 (min 5 AP)",
"GIFT_DONE = ^^4[GIFT] ^^3%s^^1 sent ^^3%s^^1 a gift of ^^4%d AP^^1. What a friend!",
"BOUNTY_USAGE = ^^1Usage: ^^4/bounty name 50^^1 (min 10 AP). Whoever takes them down gets it.",
"BOUNTY_DEAD = ^^1Your target must be alive.",
"BOUNTY_SET = ^^4[BOUNTY] ^^3%s^^1 put a price on ^^3%s^^1's head! Total: ^^4%d AP",
"BOUNTY_PAID = ^^4[BOUNTY] ^^3%s^^1 collected ^^4%d AP^^1 for taking down ^^3%s^^1!",
"MENU_FUN = Fun & Games",
"MENU_FUN_SUB = Have fun, but don't forget the zombies",
"FUNM_1 = Roll the dice",
"FUNM_2 = Flip a coin",
"FUNM_3 = Tell a joke",
"FUNM_4 = Dance!",
"FUNM_5 = Slot machine (10 AP)",
"FUNM_6 = Lottery ticket (10 AP)",
"FUNM_7 = Gift / bounty / ask (how to)",
"FUNM_8 = Reset my score",
"FUNM_9 = Who is online (staff/VIP)",
"FUNM_10 = Server time",
"FUNM_11 = Rules",
"FUNM_12 = Founders",
"FUN_HINT_ARGS = ^^1Type in chat: ^^4/gift name 20^^1, ^^4/bounty name 50^^1, ^^4/ask question^^1, ^^4/roll 100^^1, ^^4/me waves",
"LIVE_JOINNEW_1 = Someone new just walked in: ^^3%s^^1! Everybody say hi!",
"LIVE_JOINNEW_2 = Fresh blood! Welcome ^^3%s^^1, you picked the right server.",
"LIVE_JOINNEW_3 = ^^3%s^^1 joined us for the first time. Go easy on them... or not!",
"LIVE_JOINBACK_1 = Look who's back! ^^3%s^^1, we haven't seen you in ^^4%d^^1 days!",
"LIVE_JOINBACK_2 = ^^3%s^^1 is back after ^^4%d^^1 days. The zombies missed you.",
"LIVE_JOINBACK_3 = Welcome back ^^3%s^^1! ^^4%d^^1 days... we kept your seat warm.",
"LIVE_JOINSOON_1 = ^^3%s^^1 couldn't stay away for long. Welcome back!",
"LIVE_JOINSOON_2 = Hey ^^3%s^^1, good to see you again!",
"LIVE_JOINSOON_3 = ^^3%s^^1 is here. Now the party can start.",
"LIVE_CROWD_1 = ^^4%d^^1 players online! This is getting serious.",
"LIVE_CROWD_2 = Wow, ^^4%d^^1 of us now. The zombies are going to be busy tonight.",
"LIVE_LEAVE_1 = ^^3%s^^1 left the server. See you soon!",
"LIVE_LEAVE_2 = ^^3%s^^1 had to go. Come back safe!",
"LIVE_LEAVE_3 = Bye ^^3%s^^1, we'll keep the lights on.",
"LIVE_HELLO_1 = Hey ^^3%s^^1! Welcome welcome!",
"LIVE_HELLO_2 = Hi ^^3%s^^1, glad you're here!",
"LIVE_HELLO_3 = Hello ^^3%s^^1! Ready for some zombies?",
"LIVE_HELLO_4 = Hey there ^^3%s^^1, grab a gun and join the fun!",
"LIVE_GG_1 = GG ^^3%s^^1! That was a good one.",
"LIVE_GG_2 = GG WP ^^3%s^^1!",
"LIVE_GG_3 = Good game ^^3%s^^1, next round is yours!",
"LIVE_BYE_1 = Good night ^^3%s^^1! Sweet dreams, no zombies.",
"LIVE_BYE_2 = Sleep well ^^3%s^^1, see you tomorrow!",
"LIVE_BYE_3 = Night ^^3%s^^1! Don't forget your daily reward tomorrow.",
"LIVE_HOW_1 = I'm great ^^3%s^^1, the server is full of zombies, so... perfect!",
"LIVE_HOW_2 = All good here ^^3%s^^1! How's your aim today?",
"LIVE_HOW_3 = Never better ^^3%s^^1. You?",
"LIVE_CALL_1 = You called, ^^3%s^^1? I'm always here.",
"LIVE_CALL_2 = Yes ^^3%s^^1? Vexmira is listening.",
"LIVE_CALL_3 = That's me! What's up ^^3%s^^1?",
"LIVE_THANKS_1 = Anytime ^^3%s^^1!",
"LIVE_THANKS_2 = You're welcome ^^3%s^^1, have fun!",
"LIVE_VIPASK_1 = ^^3%s^^1, VIP info is in ^^4/vipinfo^^1. To buy: ^^4%s",
"LIVE_LAG_1 = ^^3%s^^1, try ^^4/fps^^1, the performance preset helps a lot.",
"LIVE_LAG_2 = Lag, ^^3%s^^1? ^^4/fps^^1 can print the best net settings to your console.",
"LIVE_TOPKILL_1 = The butcher of this map is ^^3%s^^1 with ^^4%d^^1 kills. Who will stop them?",
"LIVE_TOPKILL_2 = ^^3%s^^1 has ^^4%d^^1 zombie kills on this map. Respect.",
"LIVE_TOPKILL_3 = Zombies, watch out for ^^3%s^^1. ^^4%d^^1 of you already fell.",
"LIVE_HSTREAK_1 = Humans won ^^4%d^^1 rounds in a row! Zombies, get it together.",
"LIVE_HSTREAK_2 = ^^4%d^^1 human wins in a row. Is this a fortress or what?",
"LIVE_ZSTREAK_1 = Zombies won ^^4%d^^1 rounds in a row. Humans, stick together!",
"LIVE_ZSTREAK_2 = ^^4%d^^1 zombie wins in a row... the plague is winning.",
"LIVE_TIME0_1 = Still here at this hour? You night owls are legends.",
"LIVE_TIME0_2 = It's the middle of the night... the perfect time for zombies.",
"LIVE_TIME1_1 = Good morning everyone! Coffee in one hand, rifle in the other.",
"LIVE_TIME1_2 = Morning shift is on. Don't forget your daily reward: /daily",
"LIVE_TIME2_1 = Good afternoon! Perfect time for a boss round, isn't it?",
"LIVE_TIME2_2 = Lunch break zombies? I like your style.",
"LIVE_TIME3_1 = Good evening! The server is warming up, invite your friends.",
"LIVE_TIME3_2 = Evening crowd is here. Let's make it a good night!",
"LIVE_RANDOM_1 = Pro tip: armor stops infection. Keep it topped up!",
"LIVE_RANDOM_2 = Did you know? Headshots give bonus AP. Aim high, earn more.",
"LIVE_RANDOM_3 = Zombies, your [R] ability has a cooldown. Use it wisely!",
"LIVE_RANDOM_4 = Feeling lucky? /slot is waiting for you.",
"LIVE_RANDOM_5 = Stick together, humans. Lone wolves get eaten first.",
"LIVE_RANDOM_6 = Don't forget: your perks never reset. Invest your VC!",
"LIVE_RANDOM_7 = If you like the server, add it to your favorites!",
"LIVE_RANDOM_8 = Bring your friends, more players means more chaos.",
"LIVE_RANDOM_9 = Frost grenade + Thunderbolt = zombie popsicle. Try it.",
"LIVE_RANDOM_10 = The boss gets angry below 30 percent HP. Be ready!",
"LIVE_30S_1 = 30 seconds left! Hold on, humans!",
"LIVE_30S_2 = Only 30 seconds to go... don't let them in!",
"LIVE_30S_3 = Half a minute left. Zombies, it's now or never!",
"LIVE_FIRSTINF_1 = First blood of the round: ^^3%s^^1 is infected. It begins...",
"LIVE_FIRSTINF_2 = And ^^3%s^^1 falls first. The plague has started!",
"LIVE_FIRSTINF_3 = ^^3%s^^1 got bitten first. Somebody should have bought armor.",
"HUD_P_HP = HP  %d      ARMOR  %d",
"HUD_P_DEAD = SPECTATING...",
"HUD_AIM = %s   [%s]^^nHP %d   ARMOR %d   LV.%d",
"SET_HUDPOS = Panel position",
"HUDPOS_0 = Right middle",
"HUDPOS_1 = Left middle",
"HUDPOS_2 = Top left",
"HUDPOS_3 = Top right",
"HUDPOS_4 = Bottom center",
"MENU_ADMIN_SUB = Every action is logged",
"ADMM_1 = Next round: choose MODE",
"ADMM_2 = Start a MODE now (round restarts)",
"ADMM_3 = Next round: choose EVENT",
"ADMM_4 = Start an EVENT now (round restarts)",
"ADMM_5 = Next round: choose BOSS",
"ADMM_6 = Summon a BOSS now (round restarts)",
"ADMM_7 = Player actions",
"ADMM_8 = Weather / light NOW",
"ADMM_9 = Start mode vote",
"ADMA_1 = Give 100 AP",
"ADMA_2 = Give 10 VC (owner)",
"ADMA_3 = Give 1000 XP (owner)",
"ADMA_4 = Turn into zombie",
"ADMA_5 = Turn into human",
"ADMA_6 = Make Nemesis",
"ADMA_7 = Make Survivor",
"ADMA_8 = Respawn",
"ADMA_9 = Slay",
"ADMA_10 = Give 30 days VIP (owner)",
"ADMA_11 = Give 30 days ELITE (owner)",
"ADMA_12 = Remove VIP (owner)",
"ADM_ACTION = ^^4%s^^1 -> ^^3%s^^1 : ^^4%s",
"ADM_GONE = ^^1That player is no longer on the server.",
"ADM_NEED_OWNER = ^^1Only the ^^4owner^^1 can do that.",
"ADM_RESTART = ^^4%s^^1 restarted the round.",
"ADM_NOW_MODE = ^^4%s^^1 is starting mode ^^4#%d^^1 right now!",
"ADM_GIFT_ALL = ^^4[$] ^^3%s^^1 gave everyone ^^4%d AP^^1! Say thanks!",
"ADM_RESPAWN_OFF = ^^4%s^^1 turned zombie respawn ^^3OFF^^1.",
"ADM_RESPAWN_ON = ^^4%s^^1 turned zombie respawn ^^4ON^^1.",
"VOTE_RUNNING = ^^1A vote is already running.",
"VOTE_START_MODE = ^^4[VOTE] ^^3%s^^1 started a ^^4mode vote^^1 for the next round! ^^4%d^^1 seconds, pick one!",
"VOTE_START_EVENT = ^^4[VOTE] ^^3%s^^1 started an ^^4event vote^^1! ^^4%d^^1 seconds, pick one!",
"VOTE_TITLE_MODE = Next Round Mode Vote",
"VOTE_TITLE_EVENT = Next Round Event Vote",
"VOTE_LEFT = Vote ends in \r%d seconds",
"VOTE_VOTES = votes",
"VOTE_TIE = On a tie, a random option wins.",
"VOTE_CAST = ^^4[VOTE] ^^3%s^^1 voted for ^^4%s",
"VOTE_RESULT = ^^4[VOTE] ^^1The winner is ^^4%s^^1 with ^^4%d^^1 votes! Coming up next round.",
"VOTE_RESULT_HUD = VOTE RESULT: %s",
"BUY_ALL_H = ^^4[$] ^^3%s^^1 just bought ^^4%s^^1!",
"BUY_ALL_Z = ^^3%s^^1 just bought ^^3%s^^1! Watch out, humans!",
"ESHIELD_HIT = ^^1Your energy shield blocked a hit! ^^4%d^^1 left.",
"LUCKY_DODGE = ^^1Lucky! You dodged the bite!",
"JOB_16 = Juggernaut",
"JOB_DESC_16 = +100 max HP, a bit slower",
"JOB_17 = Ninja",
"JOB_DESC_17 = silent footsteps, +6 percent speed",
"JOB_18 = Ghost",
"JOB_DESC_18 = you are half transparent",
"JOB_19 = Grenadier",
"JOB_DESC_19 = free fire + frost grenade every spawn",
"JOB_20 = Hunter",
"JOB_DESC_20 = +2 AP for every zombie kill",
"JOB_21 = Doctor",
"JOB_DESC_21 = heals nearby humans 3 HP/s",
"JOB_22 = Gambler",
"JOB_DESC_22 = 10 percent chance to double AP gains",
"JOB_23 = Tactician",
"JOB_DESC_23 = +30 percent knockback",
"JOB_24 = Lucky",
"JOB_DESC_24 = 7 percent chance to dodge a zombie bite",
"JOB_25 = Elite Soldier",
"JOB_DESC_25 = +10 percent damage, +25 armor",
"ITEM_18 = Adrenaline Shot",
"ITEM_DESC_18 = +40 percent speed for 6s",
"ITEM_19 = Ghost Cloak",
"ITEM_DESC_19 = invisible for 8s",
"ITEM_20 = Night Vision",
"ITEM_DESC_20 = see in the dark (N key)",
"ITEM_21 = Energy Shield",
"ITEM_DESC_21 = blocks the next 2 bites",
"ITEM_22 = Ammo Crate",
"ITEM_DESC_22 = refill all your ammo",
"ITEM_23 = Zombie Sprint",
"ITEM_DESC_23 = +30 percent speed for 6s",
"ITEM_24 = Shadow Veil",
"ITEM_DESC_24 = invisible for 6s",
"ITEM_25 = Mutant Legs",
"ITEM_DESC_25 = lower gravity this life",
"ITEM_26 = Regeneration",
"ITEM_DESC_26 = +60 HP every second",
"ITEM_27 = Iron Stance",
"ITEM_DESC_27 = immune to knockback",
"GUN_LOCKED = ^^1That requires level ^^4%d^^1!",
"VIP_WELCOME_SELF = ^^4[%s] ^^1Welcome back, ^^3%s^^1! Your perks are active. ^^4/vip^^1 for your lounge.",
"VIP_WELCOME_HUD = %s PERKS ACTIVE",
"WAITING_PLAYERS = WAITING FOR PLAYERS   ( %d / 2 )",
"TOP_LINE1 = -  V E X M I R A   Z O M B I E  -",
"TOP_LINE2 = - ZOMBIES : %d  |  ROUND : %d  |  HUMANS : %d -",
"TOP_LINE3 = - %s  |  %s  |  %d:%02d -",
"SET_8 = Zombie vision",
"BOSS_HPLINE = HP  %d / %d",
"BOSS_PH_1 = PHASE   [ I ]   II   III",
"BOSS_PH_2 = PHASE   I   [ II ]   III",
"BOSS_PH_RAGE = PHASE   I   II   [ III ]   RAGE",
"BOSS_PHASE_2 = PHASE II^^nThe boss grows stronger - new abilities unlocked!",
"BOSS_BOARD_TITLE = ^^1Damage leaderboard:",
"BOSS_BOARD_LINE = ^^4  #%d ^^3%s^^1 - ^^4%d^^1 damage ^^4(+%d AP)",
"BOSS_WARN_0 = GROUND SLAM INCOMING^^nGet away from the BRUTE!",
"BOSS_WARN_1 = SCREAM INCOMING^^nCover your ears, run!",
"BOSS_WARN_2 = SUMMONING THE DEAD^^nKill the boss before its army grows!",
"BOSS_WARN_3 = FIRE WAVE INCOMING^^nStay out of its reach!",
"BOSS_WARN_4 = THE REAPER IS CHOOSING^^nSomeone is about to be visited...",
"BOSS_WARN2_0 = CHARGE^^nThe BRUTE is about to dash!",
"BOSS_WARN2_1 = WAIL^^nNowhere on the map is safe!",
"BOSS_WARN2_2 = DARK SHIELD^^nHold fire or push through!",
"BOSS_WARN2_3 = METEOR RAIN^^nWatch the red rings above you!",
"BOSS_WARN2_4 = SOUL HARVEST^^nSpread out, it drains everyone near!",
"BOSS_ABIL2_0 = CHARGE!^^nThe ground cracks!",
"BOSS_ABIL2_1 = WAIL!^^nThe whole map trembles!",
"BOSS_ABIL2_2 = DARK SHIELD!^^nIt heals and hardens!",
"BOSS_ABIL2_3 = METEOR RAIN!^^nFire from the sky!",
"BOSS_ABIL2_4 = SOUL HARVEST!^^nYour life feeds the Reaper!",
"CLASS_8 = Spitter",
"CLASS_DESC_8 = [R] acid spray in front, slows",
"CLASS_9 = Hulk",
"CLASS_DESC_9 = huge HP. [R] shockwave throws humans",
"CLASS_10 = Voodoo",
"CLASS_DESC_10 = [R] heals nearby zombies",
"CLASS_11 = Phantom",
"CLASS_DESC_11 = very fast. [R] blink forward",
"JOIN_CONNECTING = ^^3%s^^1 is connecting...",
"JOIN_CONNECTING_C = ^^3%s^^1 is connecting... ^^4(%s)",
"WELCOME_4 = ^^1Every map is ^^430 rounds^^1: boss fights, special modes and a ^^3FINAL BOSS^^1. Type ^^4/round^^1 for the plan.",
"WELCOME_HUD2 = Founders: SmurfSexy & Capital^^nM = menu   |   V = laser   |   right click = grenade mode",
"LM_BIND_HINT = ^^4[LASER] ^^4V^^1 = plant, ^^4C^^1 = pick up (C works without binding). Console: ^^4bind v +setlaser",
"ROUND_CHAT2 = ^^1Round ^^4%d^^1/^^4%d^^1 begins. Stay sharp.",
"FINAL_ROUND_CHAT = ^^3FINAL ROUND^^1 of the map! Give it everything.",
"ROUNDS_LEFT_2 = ^^1Only ^^42 rounds^^1 left on this map.",
"BOSS_SOON_1 = ^^1The ^^3BOSS^^1 arrives ^^4next round^^1! Buy your gear now.",
"BOSS_SOON_2 = ^^1Boss fight in ^^4%d^^1 rounds. Save your AP!",
"FINAL_BOSS_HUD = FINAL BOSS^^nThe strongest of them all - last round!",
"FINAL_BOSS_TAG = FINAL BOSS",
"PLAN_1 = ^^4[PLAN] ^^1Round ^^4%d^^1 / ^^4%d",
"PLAN_2 = ^^4[PLAN] ^^1Boss rounds: ^^3%s",
"PLAN_3 = ^^4[PLAN] ^^1Special mode rounds: ^^4%s",
"PLAN_4 = ^^4[PLAN] ^^1All other rounds: infection with random events. Last round = ^^3FINAL BOSS^^1.",
"TOP_A = V E X M I R A   //   ROUND  %d / %d",
"TOP_B = ZOMBIES  %d    -    %d  HUMANS",
"TOP_B_BOSS = BOSS FIGHT    -    %d  HUMANS ALIVE",
"TOP_C = %s   ::   %s",
"CSO_TOP_C531 = ROUND %d / %d   %d:%02d",
"CSO_TOP_L531 = [ HUMANS  %d ]",
"CSO_TOP_R531 = [ %d  ZOMBIES ]",
"CSO_TOP_RB531 = [ BOSS  %d%% ]",
"TB532_HUM = HUMAN",
"TB532_ZOM = ZOMBIE",
"TB532_ALIVE = ALIVE",
"TB532_ROUND = ROUND %d / %d",
"CSO_TOP_A = <<=====[   ROUND  %d / %d   |   %d:%02d   ]=====>>",
"CSO_TOP_B = HUMAN  %d      VS      %d  ZOMBIE",
"CSO_TOP_BOSS = BOSS FIGHT      VS      %d  HUMAN",
"CSO_MVP_SUB = %d damage  |  %d kills  |  %d infections",
"CSO_P1 = Lv.%d   %s",
"CSO_P1R = Lv.%d   %s   #%d",
"CSO_P_HP = HP  %d     AR  %d",
"CSO_P3 = AP  %d     VC  %d     STREAK  %d",
"CSO_LEVEL_SUB = LEVEL  %d",
"TOP_C_BOSSIN = %s   ::   %s   ::   BOSS IN %d",
"TOP_C_FINAL = %s   ::   %s   ::   FINAL ROUND",
"HUD_JOB_LM = JOB  %s   ::   LASERS  %d  (%d SET)",
"MVP_HUD = MVP :  %s^^n%d damage  |  %d kills  |  %d infections",
"MVP_CHAT2 = ^^4[MVP] ^^3%s^^1 - ^^4%d^^1 damage, ^^4%d^^1 kills, ^^4%d^^1 infections ^^4(+%d AP  +%d VC)",
"MAPEND_HUD = MAP COMPLETE!^^nThe best players are rewarded",
"MAPEND_TITLE = ^^4[MAP END] ^^1Awards of this map ^^4(+5 VC each)^^1:",
"MAPEND_KILLS = ^^1  Top killer: ^^3%s ^^4(%d kills)",
"MAPEND_INF = ^^1  Top infector: ^^3%s ^^4(%d infections)",
"MAPEND_BOSS = ^^1  Boss slayer: ^^3%s ^^4(%d boss damage)",
"SET_9 = Tips & hints",
"MAIN_18 = Laser Mines",
"MAIN_19 = Grenade Modes",
"MAIN_20 = Round Quest",
"ADM_BOSS_PICK = Which boss?",
"ADM_BOSS_RANDOM = Random (shuffled order)",
"ADV_17 = ^^1Every round you get ^^43 free laser mines^^1: ^^4V^^1 = plant, ^^4C^^1 = pick up. Zombies that touch the beam die!",
"ADV_18 = ^^1Right click with a grenade in hand: ^^4impact, sensor, laser trap, homing, cluster^^1!",
"ADV_19 = ^^1A ^^4golden beam^^1 in the sky = ^^4supply drop^^1. Your HUD shows the distance and direction!",
"ADV_20 = ^^1Zombies: infect ^^43^^1 humans in one round to become an ^^3ALPHA ZOMBIE^^1.",
"EV_NAME_17 = Thunderstorm",
"EV_NAME_18 = Blackout",
"EV_ANN_17 = EVENT: THUNDERSTORM^^nLightning hunts the zombies!",
"EV_ANN_18 = EVENT: BLACKOUT^^nTotal darkness. Flashlights on (F)!",
"SPEED_TIP = ^^4[SPEED] ^^1Everyone is ^^4much faster^^1, no slowdown after jumps and a wider view!",
"STORM_TIP = ^^4[STORM] ^^1Lightning strikes at random, mostly ^^3zombies^^1. Stay out of the flashes!",
"BLACKOUT_TIP = ^^4[BLACKOUT] ^^1Power is out! Use your ^^4flashlight (F)^^1 - zombie eyes glow red.",
"BOSS_TITLE_0 = THE UNSTOPPABLE",
"BOSS_INFO_0 = ^^3BRUTE^^1 - [R]: ^^4SEISMIC STOMP^^1 > ^^4EARTHSHATTER^^1 > ^^3TITAN WRATH^^1. Keep your distance!",
"BOSS_TITLE_1 = QUEEN OF SCREAMS",
"BOSS_INFO_1 = ^^3BANSHEE^^1 - [R]: ^^4SONIC LANCE^^1 > ^^4PHANTOM SHRIEK^^1 > ^^3REQUIEM^^1. Don't stand in front of her!",
"BOSS_TITLE_2 = LORD OF THE DEAD",
"BOSS_INFO_2 = ^^3OVERLORD^^1 - [R]: ^^4BONE PRISON^^1 > ^^4RAISE LEGION^^1 > ^^3DEATH NOVA^^1. Kill it before its army grows!",
"BOSS_TITLE_3 = THE LIVING FLAME",
"BOSS_INFO_3 = ^^3INFERNO^^1 - [R]: ^^4FLAME BREATH^^1 > ^^4FIRE PILLARS^^1 > ^^3SUPERNOVA^^1. Never stand still!",
"BOSS_TITLE_4 = COLLECTOR OF SOULS",
"BOSS_INFO_4 = ^^3REAPER^^1 - [R]: ^^4SHADOW STEP^^1 > ^^4SOUL CHAINS^^1 > ^^3DEATH'S MARK^^1. It hunts the weakest!",
"BOSS_NAME_5 = FROSTLORD",
"BOSS_TITLE_5 = THE ETERNAL WINTER",
"BOSS_ANN_5 = BOSS ROUND^^nThe FROSTLORD brings winter...",
"BOSS_START_5 = THE FROSTLORD HAS AWAKENED!^^nDon't freeze!",
"BOSS_INFO_5 = ^^3FROSTLORD^^1 - [R]: ^^4ICE SHARDS^^1 > ^^4GLACIAL TOMB^^1 > ^^3ABSOLUTE ZERO^^1. Keep moving!",
"BOSS_NAME_6 = STORMCALLER",
"BOSS_TITLE_6 = VOICE OF THUNDER",
"BOSS_ANN_6 = BOSS ROUND^^nThe STORMCALLER gathers clouds...",
"BOSS_START_6 = THE STORMCALLER HAS AWAKENED!^^nThe sky is angry!",
"BOSS_INFO_6 = ^^3STORMCALLER^^1 - [R]: ^^4BALL LIGHTNING^^1 > ^^4THUNDER DASH^^1 > ^^3TEMPEST^^1. Break line of sight!",
"BOSS_NAME_7 = HIVE QUEEN",
"BOSS_TITLE_7 = MOTHER OF THE SWARM",
"BOSS_ANN_7 = BOSS ROUND^^nThe HIVE QUEEN is hatching...",
"BOSS_START_7 = THE HIVE QUEEN HAS AWAKENED!^^nBurn the nest!",
"BOSS_INFO_7 = ^^3HIVE QUEEN^^1 - [R]: ^^4ACID SPIT^^1 > ^^4TOXIC CLOUD^^1 > ^^3HATCHERY^^1. Burn the eggs!",
"BOSS_NAME_8 = VOID",
"BOSS_TITLE_8 = THE DEVOURER",
"BOSS_ANN_8 = BOSS ROUND^^nThe VOID opens...",
"BOSS_START_8 = THE VOID HAS AWAKENED!^^nDon't get pulled in!",
"BOSS_INFO_8 = ^^3VOID^^1 - [R]: ^^4VOID BOLT^^1 > ^^4SINGULARITY^^1 > ^^3EVENT HORIZON^^1. Don't get pulled in!",
"BOSS_WARN_5 = FROST NOVA INCOMING^^nGet out of the blue zone!",
"BOSS_WARN_6 = THUNDER STRIKE^^nLeave the yellow circles!",
"BOSS_WARN_7 = ACID POOLS^^nMove, the ground is melting!",
"BOSS_WARN_8 = GRAVITY WELL^^nRun away from the VOID!",
"BOSS_WARN2_5 = BLIZZARD^^nThe whole map will freeze!",
"BOSS_WARN2_6 = CHAIN LIGHTNING^^nBreak line of sight!",
"BOSS_WARN2_7 = BROOD CALL^^nShe calls her children!",
"BOSS_WARN2_8 = ECLIPSE^^nThe light is dying!",
"BOSS_ABIL_5 = FROST NOVA!^^nFrozen in place!",
"BOSS_ABIL_6 = THUNDER STRIKE!^^nThe sky answers!",
"BOSS_ABIL_7 = ACID POOLS!^^nStay out of the green!",
"BOSS_ABIL_8 = GRAVITY WELL!^^nYou are being pulled in!",
"BOSS_ABIL2_5 = BLIZZARD!^^nSlow and freezing for 6 seconds!",
"BOSS_ABIL2_6 = CHAIN LIGHTNING!^^nEveryone in sight is hit!",
"BOSS_ABIL2_7 = THE BROOD!^^nMinions and poison!",
"BOSS_ABIL2_8 = ECLIPSE!^^nIt hunts in the dark!",
"BOSS_BOARD_HUD = BOSS DAMAGE - TOP 3",
"BOSSINFO_TITLE = ^^1Bosses on this map (they come in a shuffled order):",
"BOSS_NEXT_IN = ^^1Next boss in ^^4%d^^1 rounds.",
"LM_AIM_INFO = LASER MINE  [ %s ]^^nHP %d / %d",
"LM_AIM_MINE = ^^4[LASER] ^^1Aim at your laser mine (up close) to pick it up.",
"LM_BIND_PRINTED = ^^4[LASER] ^^1Bind commands were printed to your ^^4console^^1 (~).",
"LM_BOSS_BLOCKED = ^^4[LASER] ^^1Laser mines are ^^3disabled^^1 in boss rounds.",
"LM_BOUGHT = ^^4[LASER] ^^1Bought 1 laser mine ^^4(-%d AP)^^1.",
"LM_DESTROYED = ^^3[LASER] ^^1Your laser mine was destroyed by ^^3%s^^1!",
"LM_DISABLED = ^^4[LASER] ^^1Laser mines are not available right now.",
"LM_DISABLED_SHORT = Not available right now",
"LM_HINT = ^^4[LASER] ^^1You have ^^4%d^^1 free laser mines! Aim at a wall and press ^^4V^^1. ^^4C^^1 = pick up.",
"LM_HINT_HUD = V  =  PLANT LASER      C  =  PICK UP",
"LM_INV_FULL = ^^4[LASER] ^^1Your bag is full (max 5).",
"LM_LIMIT = ^^4[LASER] ^^1You can have at most ^^4%d^^1 lasers planted.",
"LM_MENU = Laser Mines",
"LM_MENU_SUB = In bag: %d   |   Planted: %d / %d",
"LM_MOVED = ^^4[LASER] ^^1Cancelled - you moved.",
"LM_TAKING = ^^4[LASER] ^^1Taking the mine back... keep aiming at it for ^^3%d ^^1s.",
"LM_TAKE_CANCEL = ^^4[LASER] ^^1Taking cancelled.",
"LM_TAKE_AIM = ^^4[LASER] ^^1Cancelled - you stopped aiming at the mine.",
"LM_TAKE_HURT = ^^4[LASER] ^^1Cancelled - you took damage.",
"LM_M_PLANT = Plant laser  (V)",
"LM_M_TAKE = Pick up laser  (C)",
"LM_M_BUY = Buy laser mine",
"LM_M_BIND = Key setup (console)",
"LM_NOT_YOURS = ^^4[LASER] ^^1That laser belongs to someone else.",
"LM_NO_BOSS = ^^4[LASER] ^^1No lasers in ^^3boss rounds^^1!",
"LM_NO_BOSS_SHORT = Disabled in boss rounds",
"LM_NO_MODE = ^^4[LASER] ^^1No laser mines in ^^3%s^^1 rounds!",
"LM_NO_MODE_SHORT = Disabled in this round mode",
"LM_MODE_REMOVED = ^^4[LASER] ^^3%s^^1 round: your laser mines were removed (lasers are disabled in this mode).",
"LM_NO_MINE = ^^4[LASER] ^^1You used all your lasers this round (^^4%d^^1 per round). Pick one up with ^^4C^^1 to move it.",
"LM_NO_WALL = ^^4[LASER] ^^1Aim at a nearby wall or floor.",
"LM_TOO_FAR = ^^4[LASER] ^^1Too far away. Install the mine within ^^4%d units^^1; long-range placement is blocked.",
"LM_PLANTED = ^^4[LASER] ^^1Laser planted! It arms in a moment. ^^4(%d left)",
"LM_TAKEN = ^^4[LASER] ^^1Laser picked up. ^^4(%d in bag)",
"LM_TEAM_LIMIT = ^^4[LASER] ^^1The team limit (^^4%d^^1) has been reached.",
"NMODE_0 = NORMAL",
"NMODE_DESC_0 = ^^4[Normal] ^^1classic fuse timer",
"NMODE_1 = IMPACT",
"NMODE_DESC_1 = ^^4[Impact] ^^1explodes on the first thing it touches",
"NMODE_2 = SENSOR",
"NMODE_DESC_2 = ^^4[Sensor] ^^1lands and arms (beep), explodes only when a zombie comes in range AND in sight",
"NMODE_3 = LASER TRAP",
"NMODE_DESC_3 = ^^4[Laser Trap] ^^1sticks to the wall / floor it hits, draws a laser, explodes ON the zombie that crosses it",
"NMODE_4 = HOMING",
"NMODE_DESC_4 = ^^4[Homing] ^^1flies to the nearest zombie (HE / fire)",
"NMODE_5 = CLUSTER",
"NMODE_DESC_5 = ^^4[Cluster] ^^1splits into 4 small blasts (HE / fire)",
"NMODE_HUD = GRENADE MODE  ::  %s^^n(right click to change)",
"NMENU_TITLE = Grenade Modes",
"NMENU_SUB = Right click with a grenade in hand also switches",
"NMENU_HE = HE / Fire grenade",
"NMENU_FROST = Frost grenade",
"NMENU_FLARE = Flare",
"NMENU_HELP = What do the modes do?",
"AIRDROP_HUD = SUPPLY DROP INCOMING!^^nFollow the GOLDEN BEAM",
"AIRDROP_CHAT = ^^4[SUPPLY] ^^1A crate is falling! The ^^4first human^^1 to touch it gets the loot - zombies destroy it!",
"AIRDROP_GOT = ^^4[SUPPLY] ^^3%s^^1 grabbed the crate: ^^4%s",
"AIRDROP_YOU = SUPPLY CRATE!",
"AIRDROP_ZOMBIE = ^^3[SUPPLY] ^^3%s^^1 smashed the supply crate!",
"LOOT_AP = +%d AP",
"LOOT_HP = +60 HP and +100 armor",
"LOOT_NADES = grenade pack (fire + frost + flare)",
"LOOT_MINE = +1 laser mine",
"LOOT_CLIP = unlimited clip (this life)",
"LOOT_DMG = +30%% damage (this life)",
"LOOT_VC = +3 Vex Coin",
"QUEST_0 = Kill %d zombies",
"QSHORT_0 = Zombie kills",
"QUEST_1 = Kill %d zombies",
"QSHORT_1 = Zombie kills",
"QUEST_2 = Deal %d damage to zombies",
"QSHORT_2 = Damage",
"QUEST_3 = Deal %d damage to zombies",
"QSHORT_3 = Damage",
"QUEST_4 = Get %d headshot kills",
"QSHORT_4 = Headshots",
"QUEST_5 = Infect %d human",
"QSHORT_5 = Infections",
"QUEST_6 = Infect %d humans",
"QSHORT_6 = Infections",
"QUEST_7 = Survive and win the round as a human",
"QSHORT_7 = Win the round",
"QUEST_NEW = ^^4[QUEST] ^^1%s ^^4(+%d XP  +%d AP)",
"QUEST_LINE = Quest : %s  [%d / %d]",
"QUEST_LINE_DONE = Quest : COMPLETED",
"QUEST_DONE_HUD = QUEST COMPLETE!^^nReward added to your account",
"QUEST_DONE_ALL = ^^4[QUEST] ^^3%s^^1 completed the round quest!",
"QUEST_NONE = ^^4[QUEST] ^^1No quest this round.",
"QUEST_INFO = ^^4[QUEST] ^^1%s  ^^4%d / %d^^1   reward: ^^4+%d XP  +%d AP",
"QUEST_INFO_DONE = ^^4[QUEST] ^^1%s ^^4- COMPLETED",
"EVOLVE_CHAT = ^^3%s^^1 evolved into an ^^3ALPHA ZOMBIE^^1! (+50%% HP, faster, harder hits)",
"EVOLVE_HUD = YOU EVOLVED: ALPHA ZOMBIE^^n+50%% HP   |   faster   |   harder hits",
"MAIN_21 = Cosmetics (Vex Coin)",
"MAIN_22 = Hall of Fame (Top 10)",
"HUD_P1R = LV.%d   //   %s   //   TOP #%d",
"COS_MENU = Cosmetics",
"COS_SUB = Permanent looks, bought with Vex Coin",
"COS_CAT_TRAIL = Trails",
"COS_CAT_KFX = Kill effects",
"COS_CAT_IFX = Infection effects (zombie)",
"COS_NONE = None",
"COS_EQUIPPED = ON",
"COS_OWNED = owned",
"COS_OFF = ^^4[COSMETIC] ^^1Removed.",
"COS_NOVC = ^^4[COSMETIC] ^^1Not enough Vex Coin ^^4(%d VC needed)^^1. Earn VC from levels, daily rewards and MVP.",
"COS_BOUGHT = ^^4[COSMETIC] ^^1You bought ^^4%s^^1 ^^4(-%d VC)^^1. It's yours forever!",
"COS_BOUGHT_ALL = ^^4[COSMETIC] ^^3%s^^1 unlocked ^^4%s^^1!",
"COS_EQUIP = ^^4[COSMETIC] ^^4%s^^1 equipped.",
"COS_PREV_START = ^^4[COSMETIC] ^^1Preview: ^^4%s^^1 is spinning in front of you for ^^4%d^^1 seconds (only you see it).",
"COS_YOUR_VC = Your VC",
"COS_BUY_ITEM = Buy and equip",
"COS_PREV_ITEM = Preview in front of me",
"COS_SEC = sec",
"COS_BACK = Back",
"COS_HIDE_OTHERS = Other players' wings / pets / hats",
"COS_HIDDEN = hidden",
"COS_VISIBLE = visible",
"COS_HIDE_ON = ^^4[COSMETIC] ^^1Other players' wings, pets and hats are now ^^4hidden^^1 for you (more FPS).",
"COS_HIDE_OFF = ^^4[COSMETIC] ^^1Other players' wings, pets and hats are ^^4visible^^1 again.",
"COS_TRAIL_0 = Ice Trail",
"COS_TRAIL_1 = Toxic Trail",
"COS_TRAIL_2 = Blood Trail",
"COS_TRAIL_3 = Royal Trail",
"COS_TRAIL_4 = Golden Trail",
"COS_TRAIL_5 = Rainbow Trail",
"COS_KFX_0 = Lightning Strike",
"COS_KFX_1 = Golden Burst",
"COS_KFX_2 = Blood Fountain",
"COS_KFX_3 = Frost Shatter",
"COS_KFX_4 = Void Collapse",
"COS_KFX_5 = Fireworks",
"COS_IFX_0 = Toxic Burst",
"COS_IFX_1 = Shadow",
"COS_IFX_2 = Blood Moon",
"TOP10_TITLE = HALL OF FAME",
"TOP10_NAME = Player",
"TOP10_KILLS = Kills",
"TOP10_INF = Infect",
"TOP10_YOU = Your all-time rank: #%d",
"TOP10_NEED = You need %d more XP to enter the top 15.",
"TOP10_OPEN = There is still room in the top 15 - keep playing!",
"TOP_JOIN = ^^4[TOP] ^^1The server's ^^4#%d^^1 player ^^3%s^^1 has arrived!",
"CARD_JOB = Job",
"CARD_KILLS = Kills",
"CARD_INF = Infections",
"CARD_WINS = Wins",
"CARD_BOSS = Boss kills",
"CARD_ACH = Achievements",
"CARD_TIME = Play time",
"CARD_DAILY = Daily streak",
"CARD_MAPKILLS = Kills this map",
"SPEC_INFO = WATCHING  ::  %s^^nLV.%d   ::   %s   ::   HP %d   ::   ARMOR %d   ::   AP %d",
"ADV_21 = ^^1Spend your ^^4Vex Coin^^1 on permanent ^^4trails and kill effects^^1: ^^4/cosmetic",
"ADV_22 = ^^1Are you in the ^^4Hall of Fame^^1? Type ^^4/top10",
"JOB_NEXT = ^^1Your new job becomes active ^^4on your next spawn^^1.",
"GUNS_ONCE = ^^1You already received your weapons this life. Pick new ones next round.",
"NO_SUICIDE = ^^1Special characters can't use ^^3kill^^1. Fight to the end!",
"",
"BSK_0_1 = SEISMIC STOMP",
"BSKT_0_1 = Everyone around it is thrown into the air!",
"BSK_0_2 = EARTHSHATTER",
"BSKT_0_2 = Eruptions are marching toward you - step aside!",
"BSK_0_3 = TITAN WRATH",
"BSKT_0_3 = 6 seconds of fury - run, don't fight up close!",
"BSK_1_1 = SONIC LANCE",
"BSKT_1_1 = A sonic wave in front of her - get out of her sight!",
"BSK_1_2 = PHANTOM SHRIEK",
"BSKT_1_2 = She appears BEHIND someone and screams!",
"BSK_1_3 = REQUIEM",
"BSKT_1_3 = 5 waves of wailing - the whole map bleeds!",
"BSK_2_1 = BONE PRISON",
"BSKT_2_1 = Someone is locked in a bone cage!",
"BSK_2_2 = RAISE LEGION",
"BSKT_2_2 = The fallen rise and your life is drained!",
"BSK_2_3 = DEATH NOVA",
"BSKT_2_3 = 3 rings of death spread out - stay between them!",
"BSK_3_1 = FLAME BREATH",
"BSKT_3_1 = A cone of fire in front of it - flank it!",
"BSK_3_2 = FIRE PILLARS",
"BSKT_3_2 = Fire bursts from under your feet - MOVE!",
"BSK_3_3 = SUPERNOVA",
"BSKT_3_3 = It is charging a huge blast - RUN FAR AWAY!",
"BSK_4_1 = SHADOW STEP",
"BSKT_4_1 = It vanished... and its next hit is DOUBLE!",
"BSK_4_2 = SOUL CHAINS",
"BSKT_4_2 = Chained! Run away to break the chain!",
"BSK_4_3 = DEATH'S MARK",
"BSKT_4_3 = Everyone is marked - leave your spot NOW!",
"BSK_5_1 = ICE SHARDS",
"BSKT_5_1 = A fan of ice spears - take cover!",
"BSK_5_2 = GLACIAL TOMB",
"BSKT_5_2 = Someone is frozen solid!",
"BSK_5_3 = ABSOLUTE ZERO",
"BSKT_5_3 = Keep moving or you will freeze!",
"BSK_6_1 = BALL LIGHTNING",
"BSKT_6_1 = A ball of lightning drifts - stay away from it!",
"BSK_6_2 = THUNDER DASH",
"BSKT_6_2 = It dashes like a lightning bolt!",
"BSK_6_3 = TEMPEST",
"BSKT_6_3 = Lightning strikes the marked circles!",
"BSK_7_1 = ACID SPIT",
"BSKT_7_1 = Acid incoming - avoid the green pools!",
"BSK_7_2 = TOXIC CLOUD",
"BSKT_7_2 = A toxic cloud surrounds her - keep distance!",
"BSK_7_3 = HATCHERY",
"BSKT_7_3 = Shoot the eggs before they hatch!",
"BSK_8_1 = VOID BOLT",
"BSKT_8_1 = A void bolt pulls its victim in!",
"BSK_8_2 = SINGULARITY",
"BSKT_8_2 = A black hole opens - run out of the circle!",
"BSK_8_3 = EVENT HORIZON",
"BSKT_8_3 = Darkness falls and everything is pulled in!",
"ADMM_10 = Start event vote",
"ADMM_11 = Restart round",
"ADMM_12 = End round: HUMANS win",
"ADMM_13 = End round: ZOMBIES win",
"ADMM_14 = Drop a supply crate now",
"ADMM_15 = Give every human grenades + lasers",
"ADMM_16 = Give everyone 50 AP",
"ADMM_17 = Zombie respawn",
"ADMM_18 = Laser mines",
"ADMM_19 = Reload vexmira.cfg",
"ADME_0 = Reset (round default)",
"ADME_1 = Clear day",
"ADME_2 = Dusk",
"ADME_3 = Night",
"ADME_4 = Rain",
"ADME_5 = Snow",
"ADME_6 = Thick fog",
"ADME_7 = Storm",
"ADME_8 = Blood red",
"ADME_9 = Pitch black",
"ADME_CUSTOM = Detailed ambience controls",
"ADME_DETAIL = Detailed ambience controls",
"ADME_LIGHT = World brightness (a-z)",
"ADME_FOG_DENSITY = Fog density (0-80)",
"ADME_FOG_RED = Fog red",
"ADME_FOG_GREEN = Fog green",
"ADME_FOG_BLUE = Fog blue",
"ADME_WEATHER = Weather (0 clear, 1 rain, 2 snow)",
"ADME_MAP_AMBIENCE = Map ambient loops",
"ADME_ENV_RESET = Restore round ambience",
"ADM_ENV_RESET = ^^4%s^^1 restored the round's automatic ambience.",
"ADMA_13 = Make Assassin",
"ADMA_14 = Make Sniper",
"ADMA_15 = Give +3 laser mines",
"ADMA_16 = Give all grenades",
"ADMA_17 = Freeze for 5 s",
"ADM_AIRDROP = ^^4%s^^1 called in a ^^4supply drop^^1!",
"ADM_END_HUMANS = ^^4%s^^1 ended the round: ^^4HUMANS WIN^^1.",
"ADM_END_ZOMBIES = ^^4%s^^1 ended the round: ^^3ZOMBIES WIN^^1.",
"ADM_ENV_SET = ^^4%s^^1 changed the weather / light (preset ^^4#%d^^1).",
"ADM_GAVE_NADES = ^^4%s^^1 gave every human ^^4all grenades + lasers^^1!",
"ADM_LASER_ON = ^^4%s^^1 turned laser mines ^^4ON^^1.",
"ADM_LASER_OFF = ^^4%s^^1 turned laser mines ^^3OFF^^1.",
"ADM_NEXT_BOSS = ^^4%s^^1 set the next round to a ^^3BOSS^^1 (^^4#%d^^1, -1 = random).",
"ADM_NOW_BOSS = ^^4%s^^1 is summoning a ^^3BOSS^^1 right now (^^4#%d^^1)!",
"ADM_NOW_EVENT = ^^4%s^^1 is starting event ^^4#%d^^1 right now!",
"ADM_NOT_ACTIVE = ^^1There is no active round right now.",
"ADM_RELOADED = ^^4%s^^1 reloaded ^^4vexmira.cfg^^1 (^^4%d^^1 lines).",
"AFK_WARN = ^^3[AFK] ^^1Move! You will be moved to spectators in ^^4%d^^1 seconds.",
"AFK_MOVED = ^^3[AFK] ^^3%s^^1 was moved to spectators (AFK).",
"AFK_KICKED = ^^3[AFK] ^^3%s^^1 was kicked (AFK).",
"NEM_RAGE_YOU = RAGE!^^nFaster and tougher for a few seconds",
"NEM_RAGE_ALL = ^^1The ^^3NEMESIS %s^^1 is in a ^^3RAGE^^1! Keep your distance!",
"ASN_VEIL_YOU = SHADOW VEIL!^^nYou are almost invisible",
"ROLE_BOSS_KEYS = ^^4[BOSS] ^^1Keys: ^^4[R]^^1 = phase skill (a new one every phase), ^^4[F]^^1 / ^^4[G]^^1 = leap. Your attacks grow stronger every phase!",
"BSK_BUSY = A skill is already active!",
"BSK_NO_TARGET = No target in range!",
"BSK_FIRST_SKILL = ^^1Your first ^^4[R]^^1 skill: ^^3%s^^1. New skills unlock at ^^460%%^^1 and ^^430%%^^1 health!",
"BSK_UNLOCK_ALL = ^^3%s^^1 learned a new skill: ^^3%s^^1 (phase ^^4%d^^1)!",
"BSK_UNLOCK_YOU = NEW [R] SKILL!^^n%s",
"BSK_PRISON_YOU = BONE PRISON! You are trapped!",
"BSK_EMPOWER = Your next hit deals DOUBLE damage!",
"BSK_CHAINED = SOUL CHAINS! Run away to break them!",
"BSK_CHAIN_BROKEN = ^^1You broke the ^^3soul chain^^1!",
"BSK_MARKED = DEATH'S MARK! Move away from your spot!",
"BSK_TOMB_YOU = GLACIAL TOMB! You are frozen!",
"BSK_ZERO_TIP = ABSOLUTE ZERO! Keep moving or you will freeze!",
"BSK_EGGS_TIP = EGGS! Shoot them before they hatch!",
"BSK_PULLED = VOID BOLT! You are being pulled in!",
"HUD_ACTIVE = ACTIVE",
"HUD_READY = READY",
"HUD_SECONDS = %d s",
"HUD_BOSS_R = [R] %s  %s   ::   [F/G] LEAP  %s",
"HUD_NEM_RF = [R] LEAP  %s   ::   [F/G] RAGE  %s",
"HUD_ASN_RF = [R] LEAP  %s   ::   [F/G] SHADOW VEIL  %s",
"HUD_DROP_COMPASS = SUPPLY CRATE  %d m  %s",
"LM_AIM_INFO_MINE = YOUR LASER  [ %s ]^^nHP %d / %d     C = pick up",
"LM_GIFT = ^^4[LASER] ^^1You received ^^4+%d^^1 laser mines!",
"LM_INFO_1 = ^^4[LASER] ^^1Every round each human gets ^^4%d^^1 laser mines for FREE (no AP).",
"LM_INFO_2 = ^^4[LASER] ^^4V^^1 = plant on the wall you aim at.  ^^4C^^1 = pick it up instantly (back to your bag).",
"LM_INFO_3 = ^^4[LASER] ^^1Any zombie that touches the beam ^^3dies instantly^^1. Zombies can claw the mine to break it.",
"LM_M_INFO = How it works",
"LM_M_RULE = Free %d lasers every round - no AP needed",
"LM_WORN_OUT = ^^3[LASER] ^^1One of your lasers burned out after too many kills.",
"ADV_23 = ^^1Bosses learn a NEW ^^4[R]^^1 skill every phase. Always watch the colored circles on the ground!",
"ADV_24 = ^^1Every round every human gets ^^4all grenades^^1 automatically. Right click = grenade mode!",
"ADV_25 = ^^3Nemesis^^1 and ^^3Assassin^^1 kill in ONE hit. Keep your distance and use lasers!",
"ADV_26 = ^^1Every event changes the ^^4weather and light^^1: rain, snow, blood moon, fog...",
"CLASS_12 = Butcher",
"CLASS_DESC_12 = Tough. [R] meat hook pulls a human to you",
"CLASS_13 = Hunter",
"CLASS_DESC_13 = Agile. [R] pounce, stuns on landing",
"CLASS_14 = Charger",
"CLASS_DESC_14 = Heavy. [R] charge, throws humans aside",
"CLASS_15 = Arachne",
"CLASS_DESC_15 = Low gravity. [R] web shot roots + slows",
"CLASS_16 = Magma",
"CLASS_DESC_16 = Fireproof. [R] burning lava trail",
"CLASS_17 = Volt",
"CLASS_DESC_17 = [R] EMP: lasers, flashlights, NVG go dark",
"CLASS_18 = Mimic",
"CLASS_DESC_18 = [R] looks human, first hit deals x2",
"CLASS_19 = Burrower",
"CLASS_DESC_19 = [R] dives underground, erupts knocking up",
"CLASS_20 = Siren",
"CLASS_DESC_20 = [R] lullaby lures humans towards you",
"CLASS_21 = Bulwark",
"CLASS_DESC_21 = Huge HP. [R] fortify: -50%% dmg, reflects",
"CLASS_22 = Sporemother",
"CLASS_DESC_22 = [R] plants spore pods (poison traps)",
"CLASS_23 = Nightmare",
"CLASS_DESC_23 = [R] terror: blinds humans, speeds you up",
"SKILL_ONLY_ZOMBIE = Skills can only be used by living zombies",
"SKILL_ROUND_OVER = The round is over - skills are disabled",
"SKILL_MINION = Minions have no skills",
"SKILL_STUNNED = You are stunned! (%d s)",
"SKILL_NEED_GROUND = You must be on the ground!",
"SKILL_BOSS_INTRO = The boss is awakening... skills in %d s",
"SKILL_BURROWED = You are underground!",
"SKILL_NO_SPACE = No room to do that here!",
"SKILL_HOOK_BUSY = Your hook is already out!",
"SKILL_NO_TARGET = No human in range!",
"LIGHTS_BLOCKED = EMP! Your lights are dead for %d s",
"HOOK_THROW_YOU = MEAT HOOK!",
"HOOK_GOT_YOU = HOOKED: %s!^^nReel them in",
"HOOK_PULLED = HOOKED by %s!^^nYou are being dragged",
"HOOK_IMMUNE = The hook slips off - target cannot be pulled!",
"HOOK_MISS_YOU = The hook missed",
"HUNTER_POUNCE_YOU = POUNCE!",
"HUNTER_STUNNED = POUNCED by %s!^^nYou are stunned",
"HUNTER_HIT_YOU = Pinned down: %s",
"CHARGER_YOU = CHARGE!",
"CHARGER_HIT = RAMMED by %s!",
"CHARGER_CRASH = You crashed into a wall!",
"ARACHNE_YOU = WEB SHOT!",
"ARACHNE_WEBBED = WEBBED by %s!^^nYou cannot move",
"ARACHNE_HIT_YOU = Webbed: %s",
"MAGMA_YOU = LAVA TRAIL!^^nYour steps set the ground on fire",
"MAGMA_IMMUNE = Magma zombies are immune to fire!",
"VOLT_YOU = EMP BLAST!^^n%d laser mine(s) disabled",
"VOLT_EMP_HIT = EMP by %s!^^nLasers, flashlight and NVG are down",
"MIMIC_YOU = DISGUISE!^^nYou look human - your first hit deals x2",
"MIMIC_REVEALED = IT WAS A MIMIC: %s!",
"MIMIC_STRIKE_YOU = AMBUSH! Disguise dropped",
"MIMIC_END_YOU = Your disguise wore off",
"BURROW_YOU = BURROW!^^nUnseen and untouchable",
"BURROW_HIT = ERUPTION by %s!",
"SIREN_YOU = LULLABY!^^n%d human(s) entranced",
"SIREN_LURED = The song of %s...^^nYou are drawn towards it",
"BULWARK_YOU = FORTIFY!^^nNo knockback, -50%% damage, reflect",
"SPORE_YOU = SPORE POD planted (%d)",
"SPORE_HIT = SPORES of %s!^^nPoisoned and slowed",
"SPORE_BURST_YOU = Spore pod burst: %d human(s) poisoned",
"SPORE_DESTROYED = ^^3[SPORE] ^^1Your spore pod was destroyed by ^^3%s^^1.",
"NIGHTMARE_YOU = TERROR!^^n%d human(s) blinded - run!",
"NIGHTMARE_HIT = NIGHTMARE %s!^^nDarkness falls",
"SKILL_KEYS_HINT = ^^4[KEYS] ^^1If ^^4[F]^^1 does nothing, press ^^4[G]^^1, type ^^4/skill2^^1 or bind it: ^^4bind f vex_skill2^^1 (R: ^^4vex_skill^^1).",
"HUD_CLASS_ACT = %s   ::   [R/G]  ACTIVE  %d s",
"BOSS_PH_3 = PHASE   I   II   [ III ]",
"PLAN_5 = ^^1Bosses loaded on this map: ^^3%s",
"MAPV_START = ^^3%s^^1 started the ^^4next map vote^^1! You have ^^4%d^^1 seconds - press the number of your map.",
"MAPV_START_HUD = NEXT MAP VOTE^^nPick the next map from the menu",
"MAPV_TITLE = Next Map Vote",
"MAPV_LEFT = Ends in \r%d s\y  |  votes: \r%d",
"MAPV_EXTEND = Extend this map (+%d rounds)",
"MAPV_STAY = Stay on this map",
"MAPV_NOTE = You can change your vote. Tie = random. Bots do not vote.",
"MAPV_CAST = ^^3%s^^1 voted for ^^4%s",
"MAPV_RECAST = ^^3%s^^1 changed the vote to ^^4%s",
"MAPV_RESULT = ^^1Next map: ^^4%s^^1 with ^^4%d^^1 votes (^^4%d%%^^1).",
"MAPV_RESULT_HUD = NEXT MAP^^n%s",
"MAPV_NOVOTES = ^^1Nobody voted - the next map was picked at random: ^^4%s",
"MAPV_EXTENDED = ^^1The map was ^^4extended by %d rounds^^1! The next vote comes before the new last round.",
"MAPV_EXTENDED_HUD = MAP EXTENDED^^n+%d rounds",
"MAPV_STAYED = ^^1The vote decided to ^^4stay on this map^^1 (^^4%d^^1 votes).",
"MAPV_STAYED_HUD = WE STAY ON THIS MAP",
"MAPV_NONE = ^^1No other map of the pool is installed on this server, so there is nothing to vote for.",
"MAPV_ONLY = ^^1Only one map is available, so it is next: ^^4%s",
"MAPV_ROUNDEND = ^^1The map changes to ^^4%s^^1 when this round ends.",
"MAPV_CHANGING = ^^1Changing map to ^^4%s^^1 ...",
"MAPV_CHANGING_HUD = NEXT MAP: %s^^nSee you there!",
"MAPV_NEXT_IS = ^^1Next map: ^^4%s^^1 (after the last round).",
"MAPV_NEXT_NOW = ^^1Next map: ^^4%s^^1 (changes at the end of this round).",
"MAPV_NEXT_VOTE = ^^1The next map is chosen by vote in round ^^4%d^^1 of ^^4%d^^1. Type ^^4/maps^^1 for the list.",
"MAPV_NEXT_CYCLE = ^^1Next map: ^^4%s",
"MAPV_LIST_HDR = ^^1Map pool (^^4%d^^1 rounds left on this map):",
"MAPV_LIST_KEY = ^^3*^^1 = current map, ^^4>^^1 = next map, ^^1(-) = not installed. Type ^^4/rtv^^1 to rock the vote.",
"RTV_OFF = ^^1Rock the vote is disabled on this server.",
"RTV_CHANGING = ^^1The map is already changing to ^^4%s^^1.",
"RTV_DECIDED = ^^1The next map is already decided: ^^4%s^^1. It comes after the last round.",
"RTV_TOO_EARLY = ^^1Rock the vote opens in round ^^4%d^^1.",
"RTV_MINPL = ^^1Rock the vote needs at least ^^4%d^^1 players.",
"RTV_ALREADY = ^^1You already rocked the vote (^^4%d^^1/^^4%d^^1).",
"RTV_ROCKED = ^^3%s^^1 wants to change the map! ^^4%d^^1/^^4%d^^1 - type ^^4rtv^^1 to join.",
"RTV_START = ^^1Enough players rocked the vote - the ^^4map vote^^1 starts now!",
"MAP_OBJ_LINE_CUR = ^^4[>>] ^^1(%d/%d) ^^4%s",
"MAP_OBJ_LINE_LOCK = ^^3[--] ^^1(%d/%d) %s ^^3(locked)",
"MAP_OBJ_CUR_MK = Follow the blue beacon: %s",
"MAP_OBJ_HEAD = ^^4%s^^1 - objectives:",
"MAP_OBJ_LINE_OPEN = ^^3[  ]^^1 %s",
"MAP_OBJ_LINE_MK = ^^3[  ]^^1 %s ^^3- follow the blue beacon: ^^4%s",
"MAP_OBJ_LINE_DONE = ^^4[OK] %s",
"MAP_OBJ_CUR = OBJECTIVE %d/%d: %s",
"MAP_OBJ_DONE_HUD = OBJECTIVE COMPLETE^^n%s",
"MAP_OBJ_ALL = ALL OBJECTIVES COMPLETE^^n%s",
"MAP_REWARD_H = ^^1Map reward: ^^4+%d AP^^1 for every surviving human!",
"MAP_REWARD_Z = ^^1Map reward: ^^4+%d AP^^1 for every zombie on the hunt!",
"MAP_NO_STORY = ^^1This map has no story file.",
"ADMM_20 = Map vote (winner comes after this round)",
"ADM_MAPVOTE = ^^4%s^^1 started a ^^4map vote^^1 (^^4%d^^1 options).",
"ADM_MAPVOTE_CANCEL = ^^4%s^^1 cancelled the map vote.",
"MAPDESC_zm_vex_laboratory = (bio lab)",
"MAPDESC_zm_vex_harbor = (night harbor)",
"MAPDESC_zm_vex_ruins = (ruined city)",
"MAPDESC_zm_vex_frostbase = (frost base)",
"MAPDESC_zm_vex_temple = (boss temple)",
"",
"MAINH_1 = Market (Items, Special Guns)",
"MAINH_2 = Weapons / Loadout",
"MAINH_3 = Zombie Class / Human Job",
"MAINH_4 = Character (Stats, Perks, Quests, Top)",
"MAINH_5 = Rewards & Fun",
"MAINH_6 = Cosmetics",
"MAINH_7 = Settings (Language, HUD, FPS)",
"MAINH_8 = VIP",
"MAINH_8A = VIP / Admin",
"HUB_1 = Market",
"HUB_2 = Class & Job",
"HUB_3 = Character",
"HUB_4 = Rewards & Fun",
"HUB_5 = VIP / Admin",
"HUB_BACK = << Main menu",
"VIPI_TITLE = VIP / ELITE perks",
"VIPI_1 = Extra air jump: VIP double, ELITE triple",
"VIPI_2 = +%d / +%d percent AP and XP",
"VIPI_3 = %d / %d percent off items, guns, cosmetics",
"VIPI_4 = Free pack every round (/vip): armor + grenades",
"VIPI_4A = Free pack on every spawn: armor + grenades",
"VIPI_5 = +%d / +%d spawn armor, %d laser mines per round",
"VIPI_6 = +%d / +%d Vex Coin every round end",
"VIPI_7 = Daily reward +%d / +%d percent",
"VIPI_8 = Aura, light trail, VIP model, chat tag",
"VIPI_BUY = Get VIP: %s",
"TIP_1 = ^^4[TIP] ^^1Press ^^4M^^1 for the menu: market, weapons, class, settings.",
"TIP_2 = ^^4[TIP] ^^1Every ^^4800^^1 zombie damage earns ^^4+1 AP^^1. Save AP for your next weapon.",
"TIP_3 = ^^4[TIP] ^^1Laser mines: ^^4V^^1 = plant, hold ^^4C^^1 = pick up. You get new ones every round.",
"TIP_4 = ^^4[TIP] ^^1Right click with a grenade: ^^4impact, sensor, laser trap, homing, cluster^^1.",
"TIP_5 = ^^4[TIP] ^^1Your ^^4daily reward^^1 is waiting: ^^4/daily^^1. Streaks pay more.",
"TIP_6 = ^^4[TIP] ^^1Spend ^^4Vex Coin^^1 on permanent perks: ^^4/perks",
"TIP_7 = ^^4[TIP] ^^1Jobs give humans a role. New jobs unlock with level: ^^4/job",
"TIP_8 = ^^4[TIP] ^^1JANUS, Plasma, Thunderbolt, Ethereal, Salamander and Bow: ^^4/ozel",
"TIP_9 = ^^4[TIP] ^^1Zombies: infect ^^43^^1 humans in one round to become an ^^3ALPHA^^1.",
"TIP_10 = ^^4[TIP] ^^3Nemesis^^1 and ^^3Assassin^^1 kill in one hit. Keep distance, use lasers.",
"TIP_11 = ^^4[TIP] ^^1Bosses learn a new skill every phase. Watch the colored circles!",
"TIP_12 = ^^4[TIP] ^^1A ^^4golden beam^^1 in the sky = supply drop. Follow your HUD arrow.",
"TIP_13 = ^^4[TIP] ^^1Stuck in a wall? Type ^^4/unstuck",
"TIP_14 = ^^4[TIP] ^^1Low FPS? ^^4/fps^^1 has performance presets.",
"TIP_15 = ^^4[TIP] ^^1Turkce icin ^^4/dil^^1 yaz. Language: ^^4/lang",
"TIP_16 = ^^4[TIP] ^^1Each map is ^^430 rounds^^1 with boss fights and a ^^3FINAL BOSS^^1: ^^4/round",
"TIP_17 = ^^4[TIP] ^^1Every round has a quest with AP and XP: ^^4/quest",
"TIP_18 = ^^4[TIP] ^^1Cosmetics are permanent: 5 CT skins, 5 knives, wings, pets and hats. ^^4/cosmetic",
"MENU_MAIN = Zombie Plague",
"VIPI_9 = Respawn protection +%.1f s, faster respawn",
"VIPI_10 = Vote weight x%d (mode, event, map)",
"VIPI_11 = Free weapon re-pick once per life",
"VIPI_12 = VIP-only wings, pets, hats, knife skin",
"VIPI_13 = VIP in scoreboard, kill badge, join sound",
"VIPI_14 = Priority join message when server is full",
"VIP_PRIORITY = ^^4%s^^1 joined with ^^4VIP priority^^1 (server almost full).",
"VIP_REGUN = ^^4VIP:^^1 free weapon re-pick used for this life.",
"COS_CAT_WING = Wings",
"COS_CAT_PET = Pets",
"COS_CAT_HAT = Hats",
"",
"SW_0 = JANUS VII",
"SW_DESC_0 = x1.15, 30/180 | Right-click: Pulse beam",
"SW_1 = Plasma Gun",
"SW_DESC_1 = x1.22, 30/180 | Right-click: Laser beam",
"SW_2 = Thunderbolt",
"SW_DESC_2 = x1.24, 32/180 | Right-click: Planet core",
"SW_3 = Ethereal",
"SW_DESC_3 = x1.28, 30/180 | Right-click: Dragon roar",
"SW_4 = Salamander",
"SW_DESC_4 = x1.18, 28/180 | Right-click: Cryo core",
"SW_5 = Compound Bow",
"SW_DESC_5 = x1.22, 36/180 | Right-click: Chain lightning",
"VX_ALT_0 = Pulse beam",
"VX_ALT_1 = Laser beam",
"VX_ALT_2 = Planet core",
"VX_ALT_3 = Dragon roar",
"VX_ALT_4 = Cryo core",
"VX_ALT_5 = Chain lightning",
"VX_PRIMARY = Primary fire",
"VX_MODE = Weapon mode: %s | Use left click.",
"VX_NOAMMO = This ability needs %d rounds in the magazine.",
"VX_BUSY = Active ability limit reached; wait a moment.",
"SHOP_ONLY_HUMAN = ^^1Only living normal humans can buy this (not zombie / survivor / sniper / boss).",
"SHOP_NOTINST = ^^1This item is ^^3not installed^^1 on the server right now (its plugin is not running or its files are missing). Admins: ^^4vex_diagnose",
"SHOP_HEV_ROUND = ^^1HEV Suit: only once per round.",
"MENU_NA = N/A",
"",
"ZC_SPECIAL = Special Weapons",
"ZC_JETPACK = Jetpack + Bazooka",
"ZC_HEV = HEV Suit",
"ZC_CTSKINS = CT Skins",
"ZC_KNIVES = Knife Collection",
"ZC_SKINS = Human Skins",
"ZC_FX = Trail / Kill / Infection FX",
"ZC_STANDARD = Standard (default)",
"ZC_EQUIPPED = EQUIPPED",
"ZC_OWNED = OWNED",
"ZC_FREE = free",
"ZC_NEED_SURV = Survivor only",
"ZC_GUNS6 = 6 guns",
"ZC_PERM = permanent",
"",
"ZC_ALIVE_HUMAN = ^^1You need to be an ordinary living human to buy this. Survivor and Sniper use their mode loadout.",
"ZC_HEV_LIMIT = ^^1HEV can be bought once per round. You can buy it again next round.",
"ZC_MISSING_COLLECTION = ^^1This appearance is unavailable; your coins were not spent. Admin: vex_diagnose",
"[tr]",
"WELCOME = ^^3VEXMIRA^^1'ya hos geldin ^^3%s^^1! Silahini kap, gece uzun.",
"WELCOME_2 = ^^4M^^1 = menu. ^^4/ozel^^1: 7 ozel silah | ^^4/shop^^1: Jetpack | ^^4/kozmetik^^1: koleksiyonlar.",
"WELCOME_3 = ^^1Su an ^^4Turkce^^1 oynuyorsun. English mi istersin? ^^4/lang^^1 yazman yeterli.",
"WELCOME_HUD = HOS GELDIN, %s^^nV E X M I R A   -   Zombie Plague",
"DAILY_READY = ^^4[$] ^^4Gunluk odulun^^1 hazir! ^^4/gunluk^^1 yaz.",
"LANG_CHANGED = ^^1Dil ^^4Turkce^^1 olarak ayarlandi. Her sey aninda degisti.",
"GUNS_RESET = ^^1Silah secimi sifirlandi. Bir sonraki dogusta tekrar secersin.",
"TAG_ZOMBIE = ZOMBI",
"ON = ACIK",
"OFF = KAPALI",
"OWNED = sende",
"NEED_LEVEL = ^^1Bunun icin ^^4%d. level^^1 gerekli.",
"HELP_1 = ^^3INSANLAR:^^1 sure bitene kadar dayan. Zombiye her vurusun ^^4AP^^1 kazandirir.",
"HELP_2 = ^^3ZOMBILER:^^1 pencenle vur, enfekte et. ^^4[R]^^1 ya da ^^4[G]^^1 = sinif yetenegi. Boss: ^^4[R]^^1 yetenek, ^^4[F]^^1/^^4[G]^^1 atilma.",
"HELP_3 = ^^4AP^^1 = round parasi (market, ozel silah). ^^4VC^^1 = nadir coin (kalici yetenek).",
"HELP_4 = ^^1Her harita 30 round: boss, ozel mod, event. Plan: ^^4/harita^^1, bosslar: ^^4/bosslar^^1.",
"HELP_5 = ^^1/market /ozel /silah /sinif /meslek /yetenek /gunluk /vip /lazer /bomba /gorev /kozmetik /siralama /kart",
"HELP_6 = ^^1Eglence: /zar /yazitura /espri /dans /slot 20 /piyango /hediye isim 10 /odul isim 20 /soru soru",
"UNSTUCK_WAIT = ^^4%d^^1 saniye bekle.",
"UNSTUCK_NOT = ^^1Takili degilsin.",
"UNSTUCK_OK = ^^1Kurtuldun!",
"UNSTUCK_FAIL = ^^1Yakinda bos yer bulunamadi.",
"ADM_NEXT_MODE = ^^4%s^^1 sonraki round modunu ayarladi: ^^4#%d",
"ADM_NEXT_EVENT = ^^4%s^^1 sonraki round eventini ayarladi: ^^4#%d",
"RANK_0 = Acemi",
"RANK_1 = Hayatta Kalan",
"RANK_2 = Avci",
"RANK_3 = Katil",
"RANK_4 = Gazi",
"RANK_5 = Savas Lordu",
"RANK_6 = Efsane",
"RANK_7 = Vexmira Elit",
"TITLE_0 = Otomatik (Rutbe)",
"TITLE_1 = Salgin Tasiyici",
"TITLE_2 = Zombi Avcisi",
"TITLE_3 = Boss Katili",
"TITLE_4 = Son Savunma",
"TITLE_5 = Kafa Avcisi",
"TITLE_6 = Olumsuz",
"TITLE_7 = Mukemmeliyetci",
"TITLE_8 = Sadik",
"TITLE_9 = Vexmira Efsanesi",
"LEVEL_UP_HUD = LEVEL ATLADIN!^^nArtik %d. levelsin",
"LEVELUP_VC = ^^1Level odulu: ^^4+%d VC^^1.",
"LEVELUP_CHAT = ^^3%s^^1 ^^4%d. levele^^1 ulasti!",
"RANKUP_CHAT = ^^3%s^^1 artik bir ^^4%s^^1!",
"UNLOCK_JOB = ^^4[YENI] ^^1Meslek acildi: ^^4%s^^1  (/meslek)",
"UNLOCK_CLASS = ^^4[YENI] ^^1Zombi sinifi acildi: ^^4%s^^1  (/sinif)",
"UNLOCK_SW = ^^4[YENI] ^^1Ozel silah acildi: ^^4%s^^1  (/ozel)",
"UNLOCK_TITLE = ^^4[YENI] ^^1Unvan acildi: ^^4%s^^1  (/unvan)",
"ACH_POPUP = BASARIM ACILDI!",
"ACH_CHAT = ^^3%s^^1 ^^4%s^^1 basarimini acti!",
"ACH_NAME_0 = Ilk Kan",
"ACH_DESC_0 = bir insani enfekte et",
"ACH_NAME_1 = Imha Uzmani",
"ACH_DESC_1 = 50 zombi oldur",
"ACH_NAME_2 = Zombi Avcisi",
"ACH_DESC_2 = 250 zombi oldur",
"ACH_NAME_3 = Salgin Tasiyici",
"ACH_DESC_3 = 100 insani enfekte et",
"ACH_NAME_4 = Boss Avcisi",
"ACH_DESC_4 = bir boss / nemesis oldur",
"ACH_NAME_5 = Boss Katili",
"ACH_DESC_5 = 5 boss oldur",
"ACH_NAME_6 = Hayatta Kalan",
"ACH_DESC_6 = insan olarak 10 round kazan",
"ACH_NAME_7 = Son Savunma",
"ACH_DESC_7 = son insan olarak kazan",
"ACH_NAME_8 = Kafa Avcisi",
"ACH_DESC_8 = 200 headshot",
"ACH_NAME_9 = Gazi",
"ACH_DESC_9 = 10. levele ulas",
"ACH_NAME_10 = Olumsuz",
"ACH_DESC_10 = 30. levele ulas",
"ACH_NAME_11 = Efsane",
"ACH_DESC_11 = 50. levele ulas",
"ACH_NAME_12 = Sadik",
"ACH_DESC_12 = 7 gunluk giris serisi",
"ACH_NAME_13 = Mukemmeliyetci",
"ACH_DESC_13 = bir yetenegi fulle",
"DAILY_WAIT = ^^1Bugun aldin. Sonraki odul ^^4%d sa %d dk^^1 sonra.",
"DAILY_HUD = GUNLUK ODUL  -  %d. GUN^^n+%d AP   +%d VC   +%d XP",
"DAILY_CHAT = ^^4[$] ^^1Gunluk odul (^^4%d^^1. gun): ^^4+%d AP^^1, ^^4+%d VC^^1, ^^4+%d XP^^1",
"DAILY_NEXT = ^^1Yarin tekrar gel, seri bonusu 7. gune kadar buyur!",
"ZOMBIE_REPLACED = ^^1Son zombi oyundan cikti. Yeni bir tasiyici secildi!",
"ROUND_CHAT = ^^4%d^^1. round basliyor. Dikkatli ol.",
"ROUND_CALM = ROUND %d^^nTedirgin edici bir sessizlik...",
"COUNTDOWN = SALGIN   %d   SANIYE ICINDE",
"NEED_PLAYERS = Daha fazla hayatta kalan bekleniyor...",
"GAME_COMMENCING = ^^1Yeni oyuncular katildi. ^^4Round yeniden basliyor^^1...",
"HUMANS_WIN = INSANLAR HAYATTA KALDI!",
"ZOMBIES_WIN = SALGIN HER SEYI YUTTU!",
"MVP_CHAT = ^^4[MVP] ^^3%s^^1 bu round ^^4%d^^1 hasar verdi! ^^4+1 VC",
"TOPINF_CHAT = ^^3%s^^1 bu round ^^4%d^^1 insani enfekte etti!",
"ROUND_SUMMARY = ROUND OZETI^^nHasar %d  |  Oldurme %d  |  Enfeksiyon %d  |  +%d XP  +%d AP",
"RESPAWN_IN = %d saniye icinde geri donuyorsun...",
"LAST_HUMAN = SON HAYATTA KALAN!^^nBunu degerlendir.",
"LAST_HUMAN_CHAT = ^^3%s^^1 ^^4son insan^^1! +150 can, +200 zirh.",
"INFECTED_BY = ^^3%s^^1, ^^3%s^^1 tarafindan enfekte edildi!",
"ADV_1 = ^^4M^^1'ye bas, butun sunucu o menunun icinde.",
"ADV_2 = ^^4[$] ^^1Her ^^4500^^1 hasar = ^^4+1 AP^^1. Headshot fazladan oder, kafaya nisan al!",
"ADV_3 = ^^416 meslek^^1 var. Level atladikca yenileri acilir: ^^4/meslek",
"ADV_4 = ^^1Ozel silahlar zombileri yakar, dondurur, carpar. ^^4/ozel",
"ADV_5 = ^^4[$] ^^1Bugunku ^^4gunluk odulunu^^1 aldin mi? ^^4/gunluk^^1, seri yaptikca artar!",
"ADV_6 = ^^4VC^^1'ni kalici guce cevir: can, hasar, AP kazanci. ^^4/yetenek",
"ADV_7 = ^^1FPS mi dusuk? ^^4/performans^^1 menusunde sana ozel profiller var.",
"ADV_8 = ^^1Sunucuyu kendine gore ayarla: HUD rengi, sesler, efektler ^^4/ayarlar^^1.",
"ADV_9 = ^^1Zombiler, markette sizi bir ^^4Panzehir^^1 ve bir ^^4Enfeksiyon Bombasi^^1 bekliyor.",
"ADV_10 = ^^1Basarimlar, isminin yaninda gorunen unvanlari acar. ^^4/basari",
"ADV_11 = ^^1Duvara mi sikistin? ^^4/takildim^^1 seni kurtarir.",
"ADV_12 = ^^1Modlari merak mi ediyorsun? ^^4/modlar^^1 hepsini anlatiyor.",
"MODE_NAME_0 = Enfeksiyon",
"MODE_DESC_0 = ^^4[Enfeksiyon] ^^1Tek zombi, salgin yayilir.",
"MODE_START_0 = SALGIN BASLADI!^^nKacin, hayatta kalanlar!",
"MODE_NAME_1 = Coklu Enfeksiyon",
"MODE_DESC_1 = ^^4[Coklu Enfeksiyon] ^^1Basta birden fazla zombi.",
"MODE_START_1 = COKLU ENFEKSIYON!^^nHer yerdeler!",
"MODE_NAME_2 = Nemesis",
"MODE_DESC_2 = ^^4[Nemesis] ^^1TEK VURUSTA ^^3olduren^^1 dev zombi. [R] atilma, [F] ofke.",
"MODE_START_2 = NEMESIS!^^nEnfekte etmez. Oldurur.",
"MODE_ANN_2 = NEMESIS ROUND^^nEnfekte etmek yerine olduren dev bir zombi.",
"MODE_NAME_3 = Assassin",
"MODE_DESC_3 = ^^4[Assassin] ^^1Karanlikta avlanan, TEK VURUSTA ^^3olduren^^1 cok hizli zombi.",
"MODE_START_3 = ASSASSIN!^^nIsiklar soner. Hizli bir sey geliyor.",
"MODE_ANN_3 = ASSASSIN ROUND^^nKaranlikta cok hizli bir zombi avlanir.",
"MODE_NAME_4 = Survivor",
"MODE_DESC_4 = ^^4[Survivor] ^^1Tek silahli kahraman tum zombilere karsi.",
"MODE_START_4 = SURVIVOR!^^nTek kahraman suruye karsi!",
"MODE_ANN_4 = SURVIVOR ROUND^^nTek silahli kahraman tum zombilere karsi.",
"MODE_NAME_5 = Sniper",
"MODE_DESC_5 = ^^4[Sniper] ^^1Tek atista olduren AWP'li keskin nisanci.",
"MODE_START_5 = SNIPER!^^nTek atis. Tek olum.",
"MODE_ANN_5 = SNIPER ROUND^^nTek atista olduren AWP'li keskin nisanci.",
"MODE_NAME_6 = Swarm",
"MODE_DESC_6 = ^^4[Swarm] ^^1Yari zombi, enfeksiyon yok, sadece kan.",
"MODE_START_6 = SWARM!^^nEnfeksiyon yok. Sadece kan.",
"MODE_ANN_6 = SWARM ROUND^^nYari zombi, enfeksiyon yok, sadece kan.",
"MODE_NAME_7 = Plague",
"MODE_DESC_7 = ^^4[Plague] ^^1Survivor + Nemesis + zombiler insanlara karsi.",
"MODE_START_7 = PLAGUE!^^nSurvivor ve Nemesis savasa katiliyor!",
"MODE_ANN_7 = PLAGUE ROUND^^nSurvivor + Nemesis + zombiler insanlara karsi.",
"MODE_NAME_8 = Armageddon",
"MODE_DESC_8 = ^^4[Armageddon] ^^1Nemesis ordusu Survivor ordusuna karsi.",
"MODE_START_8 = ARMAGEDDON!^^nSon savas basliyor!",
"MODE_ANN_8 = ARMAGEDDON ROUND^^nNemesis ordusu Survivor ordusuna karsi.",
"MODE_ANN_9 = BOSS ROUND^^nDev bir boss geliyor. Hep birlikte!",
"MODE_NAME_9 = BOSS",
"MODE_DESC_9 = ^^4[BOSS] ^^13 faz, 5 yetenek: her fazda YENI bir [R] yetenegi. Renkli halkalara dikkat!",
"MODE_START_9 = BOSS ROUND",
"ROLE_NEMESIS = ^^3%s^^1 ^^3NEMESIS^^1 oldu!",
"ROLE_ASSASSIN = ^^3%s^^1 ^^3ASSASSIN^^1 oldu!",
"ROLE_SURVIVOR = ^^3%s^^1 artik ^^4SURVIVOR^^1!",
"ROLE_SNIPER = ^^3%s^^1 artik ^^4SNIPER^^1!",
"NEMESIS_DOWN = ^^1Nemesis, ^^3%s^^1 tarafindan olduruldu!",
"ASSASSIN_DOWN = ^^1Assassin, ^^3%s^^1 tarafindan olduruldu!",
"EV_NAME_0 = Normal",
"EV_NAME_1 = Kan Ayi",
"EV_ANN_1 = EVENT: KAN AYI^^nGokyuzu kana bulandi. Zombiler cok daha guclu!",
"EV_NAME_2 = Yogun Sis",
"EV_ANN_2 = EVENT: YOGUN SIS^^nOnunu zor goruyorsun...",
"EV_NAME_3 = Hiz Tutkusu",
"EV_ANN_3 = EVENT: HIZ TUTKUSU^^nHerkes %%50 daha hizli - yavaslama yok, genis gorus!",
"EV_NAME_4 = Dusuk Yercekimi",
"EV_ANN_4 = EVENT: DUSUK YERCEKIMI^^nHava agirliksiz gibi.",
"EV_NAME_5 = Cift Hasar",
"EV_ANN_5 = EVENT: CIFT HASAR^^nInsanlar cift hasar veriyor!",
"EV_NAME_6 = Karanlik Gece",
"EV_ANN_6 = EVENT: KARANLIK GECE^^nIsiklar sondu. Birlikte kalin!",
"EV_NAME_7 = Salgin Patlamasi",
"EV_ANN_7 = EVENT: SALGIN PATLAMASI^^nBaslangicta daha fazla zombi!",
"EV_NAME_8 = Malzeme Dususu",
"EV_ANN_8 = EVENT: MALZEME DUSUSU^^nHerkese zirh, HE ve buz bombasi!",
"EV_NAME_9 = Delilik",
"EV_ANN_9 = EVENT: DELILIK^^nZombiler yenileniyor ve daha hizli!",
"EV_NAME_10 = Adrenalin",
"EV_ANN_10 = EVENT: ADRENALIN^^nInsanlar yenileniyor ve daha hizli!",
"EV_NAME_11 = Meteor Yagmuru",
"EV_ANN_11 = EVENT: METEOR YAGMURU^^nKirmizi halkalara dikkat. Kac!",
"EV_NAME_12 = Zombi Surusu",
"EV_ANN_12 = EVENT: ZOMBI SURUSU^^nZayif ama cok sayida zombi!",
"EV_NAME_13 = Titan Saati",
"EV_ANN_13 = EVENT: TITAN SAATI^^nTek zombi. Devasa.",
"EV_NAME_14 = Altin Hucumu",
"EV_ANN_14 = EVENT: ALTIN HUCUMU^^nBu round CIFT AP ve XP!",
"EV_NAME_15 = Vampir Gecesi",
"EV_ANN_15 = EVENT: VAMPIR GECESI^^nInsanlar her vurusta can calar!",
"EV_NAME_16 = Kafa Avi",
"EV_ANN_16 = EVENT: KAFA AVI^^nHeadshot'lar cift hasar ve bonus AP verir!",
"HUD_TOP = [ VEXMIRA ]   Round %d   :   %s   :   %s   :   Insan %d / Zombi %d   :   %d:%02d",
"HUD_P1 = LV.%d   //   %s",
"HUD_P2 = XP  [%s]  %d / %d",
"HUD_P3 = AP  %d      VC  %d      SERI  %d",
"HUD_CLASS_CD = %s   ::   [R/G]  %d sn",
"HUD_CLASS_READY = %s   ::   [R/G]  HAZIR",
"HUD_LEAP_CD = [R] Atilma : %d sn",
"HUD_LEAP_READY = [R] Atilma : HAZIR",
"HUD_JOB = MESLEK  %s",
"HUD_HEADSHOT = HEADSHOT!",
"MULTI_2 = CIFT OLDURME!",
"MULTI_3 = UCLU OLDURME!",
"MULTI_4 = COKLU OLDURME!",
"MULTI_5 = MEGA OLDURME!",
"MULTI_6 = CANAVAR OLDURME!",
"STREAK_5 = ^^3%s^^1 ^^4KUDURDU^^1! (%d oldurme)",
"STREAK_10 = ^^3%s^^1 ^^4DURDURULAMAZ^^1! (%d oldurme)",
"STREAK_15 = ^^3%s^^1 ^^4TANRI GIBI^^1! (%d oldurme)",
"ABILITY_COOL = Yetenek yenileniyor: %d sn",
"BOSS_NAME_0 = BRUTE",
"BOSS_ANN_0 = BOSS ROUND^^nBRUTE geliyor...",
"BOSS_ABIL_0 = YER DARBESI!^^nZemin parcalaniyor!",
"BOSS_START_0 = BRUTE UYANDI!^^nBirlikte yok edin!",
"BOSS_NAME_1 = BANSHEE",
"BOSS_ANN_1 = BOSS ROUND^^nBANSHEE cigliklar atiyor...",
"BOSS_ABIL_1 = SAGIR EDEN CIGLIK!^^nHicbir sey goremiyorsun!",
"BOSS_START_1 = BANSHEE UYANDI!^^nCigligini attirmayin...",
"BOSS_NAME_2 = OVERLORD",
"BOSS_ANN_2 = BOSS ROUND^^nOVERLORD yukseliyor...",
"BOSS_ABIL_2 = CAGRI!^^nDusenler yardimci olarak dirildi!",
"BOSS_START_2 = OVERLORD UYANDI!^^nOluler dirilecek!",
"BOSS_NAME_3 = INFERNO",
"BOSS_ANN_3 = BOSS ROUND^^nINFERNO tutusuyor...",
"BOSS_ABIL_3 = ATES DALGASI!^^nYaniyorsun!",
"BOSS_START_3 = INFERNO UYANDI!^^nHer sey yaniyor!",
"BOSS_NAME_4 = REAPER",
"BOSS_ANN_4 = BOSS ROUND^^nREAPER avda...",
"BOSS_ABIL_4 = RUH DARBESI!^^nKurbanin yanina isinlandi!",
"BOSS_START_4 = REAPER UYANDI!^^nSaklanacak yer yok!",
"BOSS_SPAWNED = ^^3%s^^1 ^^3BOSS^^1 oldu! Onu durdurun!",
"BOSS_BAR = %s^^n%s^^n%d / %d",
"BOSS_ENRAGE = DELILIK MODU!^^nDaha hizli, daha olumcul, 5 saniyede bir yetenek!",
"BOSS_DOWN = ^^1Boss, ^^3%s^^1 tarafindan olduruldu!",
"BOSS_DOWN_HUD = BOSS OLDU!^^nInsanlik kazandi!",
"CLASS_0 = Walker",
"CLASS_DESC_0 = Dengeli. [R] hiz patlamasi",
"CLASS_1 = Runner",
"CLASS_DESC_1 = Hizli, kirilgan. [R] uzun ziplama",
"CLASS_2 = Tank",
"CLASS_DESC_2 = Yavas, devasa can. [R] hasar kalkani",
"CLASS_3 = Banshee",
"CLASS_DESC_3 = Cevik. [R] kor eden ciglik",
"CLASS_4 = Leech",
"CLASS_DESC_4 = Enfekte edince iyilesir. [R] can emme",
"CLASS_5 = Stalker",
"CLASS_DESC_5 = Sessiz adim. [R] 6 sn gorunmezlik",
"CLASS_6 = Bomber",
"CLASS_DESC_6 = Olunce patlar. [R] zehir bulutu",
"CLASS_7 = Frost",
"CLASS_DESC_7 = Soguk aura. [R] buz halkasi (yavaslatir)",
"MENU_CLASS = Zombi Sinifi",
"MENU_CLASS_SUB = Bir sonraki enfeksiyonda uygulanir",
"CLASS_CHOSEN = ^^1Zombi sinifi secildi: ^^4%s^^1. Goster kendini!",
"CLASS_NEXT = ^^1Yeni sinifin ^^4bir sonraki enfeksiyonunda^^1 aktif olur.",
"JOB_0 = Medic",
"JOB_DESC_0 = can yeniler, ucuz ilk yardim",
"JOB_1 = Heavy",
"JOB_DESC_1 = yuzde 15 az hasar, +100 zirh",
"JOB_2 = Scout",
"JOB_DESC_2 = yuzde 12 hareket hizi",
"JOB_3 = Marksman",
"JOB_DESC_3 = zombilere yuzde 20 fazla hasar",
"JOB_4 = Engineer",
"JOB_DESC_4 = markette yuzde 25 indirim, +1 lazer hakki, yari fiyat lazer",
"JOB_5 = Looter",
"JOB_DESC_5 = yuzde 50 fazla AP",
"JOB_6 = Gunner",
"JOB_DESC_6 = 10 sn'de bir mermi dolar",
"JOB_7 = Demolitions",
"JOB_DESC_7 = bedava ates bombasi, +yuzde 50 bomba",
"JOB_8 = Sniper",
"JOB_DESC_8 = +yuzde 50 kafa hasari",
"JOB_9 = Paratrooper",
"JOB_DESC_9 = dusuk yercekimi, dusme hasari yok",
"JOB_10 = Pyro",
"JOB_DESC_10 = yuzde 15 sansla zombiyi yakar",
"JOB_11 = Cryo",
"JOB_DESC_11 = yuzde 10 sansla zombiyi dondurur",
"JOB_12 = Vampire",
"JOB_DESC_12 = hasarin yuzde 5'ini can olarak calar",
"JOB_13 = Guardian",
"JOB_DESC_13 = +50 maksimum can",
"JOB_14 = Berserker",
"JOB_DESC_14 = 40 can altinda +yuzde 40 hasar",
"JOB_15 = Commander",
"JOB_DESC_15 = takima yuzde 10 hasar aurasi",
"MENU_JOB = Insan Meslekleri",
"MENU_JOB_SUB = Insanken pasif bonus",
"JOB_CHOSEN = ^^1Meslek secildi: ^^4%s^^1. Iyi secim!",
"MENU_BACK = Geri",
"MENU_NEXT = Ileri",
"MENU_EXIT = Cikis",
"MENU_LOCKED = KILITLI",
"MENU_MAIN_SUB = [/menu]  [/vip]  [/cosmetic]  [/top10]",
"MENU_WALLET = AP: %d   VC: %d   Lv.%d",
"MENU_WALLET_AP = AP'n: %d",
"MENU_WALLET_VC = VC'n: %d",
"MAIN_1 = Esyalar (Ammo Pack)",
"MAIN_2 = Ozel Silahlar",
"MAIN_3 = Silahlar",
"MAIN_4 = Zombi Sinifi",
"MAIN_5 = Insan Meslegi",
"MAIN_6 = Gunluk Odul",
"MAIN_7 = Yetenekler (Vex Coin)",
"MAIN_8 = \yVIP Menusu",
"MAIN_9 = Eglence & Oyunlar",
"MAIN_10 = Profil",
"MAIN_11 = Ayarlar",
"MAIN_12 = Dil / Language",
"MAIN_13 = Takildim",
"MAIN_14 = Oyun Modlari",
"MAIN_15 = Yardim",
"MENU_PROFILE = Profil",
"PROF_1 = Istatistiklerim",
"PROF_2 = Basarimlar",
"PROF_3 = Unvanlar",
"PROF_4 = Chat Stili",
"MENU_SHOP_H = Insan Marketi",
"MENU_SHOP_Z = Zombi Marketi",
"ITEM_0 = Ilk Yardim",
"ITEM_DESC_0 = +100 can",
"ITEM_1 = Zirh",
"ITEM_DESC_1 = 200 zirh + kask",
"ITEM_2 = Ates Bombasi",
"ITEM_DESC_2 = zombileri yakar",
"ITEM_3 = Buz Bombasi",
"ITEM_DESC_3 = zombileri 3 sn dondurur",
"ITEM_4 = Isaret Fisegi",
"ITEM_DESC_4 = bolgeyi 25 sn aydinlatir",
"ITEM_5 = Ekstra Ziplama (VIP)",
"ITEM_DESC_5 = bu hayat +1 havada ziplama, sadece VIP",
"ITEM_6 = Yercekimi Botu",
"ITEM_DESC_6 = dusuk yercekimi, dusme hasari yok",
"ITEM_7 = Hiz Serumu",
"ITEM_DESC_7 = +yuzde 12 hiz",
"ITEM_8 = Sinirsiz Sarjor",
"ITEM_DESC_8 = bu hayat boyunca sarjor bitmez",
"ITEM_9 = Hasar Guclendirici",
"ITEM_DESC_9 = bu hayat +yuzde 30 hasar",
"ITEM_10 = Diriltme Jetonu",
"ITEM_DESC_10 = insan olarak geri don (oluyken)",
"ITEM_11 = T-Virus Panzehiri",
"ITEM_DESC_11 = tekrar insan ol",
"ITEM_12 = Zombi Cinneti",
"ITEM_DESC_12 = 5 sn hasar almazsin",
"ITEM_13 = Enfeksiyon Bombasi",
"ITEM_DESC_13 = alandaki insanlari enfekte eder",
"ITEM_14 = Mutajen",
"ITEM_DESC_14 = +1000 can",
"ITEM_15 = Ofke",
"ITEM_DESC_15 = +yuzde 15 hiz, +yuzde 20 hasar",
"ITEM_16 = Hizli Yenilenme",
"ITEM_DESC_16 = yetenek hemen hazir",
"ITEM_17 = Kemik Zirh",
"ITEM_DESC_17 = yuzde 20 az hasar",
"SHOP_SOLDOUT = limit",
"SHOP_EXCHANGE = Takas: %d AP -> 1 VC",
"SHOP_EXCHANGED = ^^4[$] ^^1AP takas edildi: ^^4+1 VC^^1.",
"SHOP_NOAP = ^^1Yeterli ^^4AP^^1 yok. Zombilere hasar vererek kazan!",
"SHOP_NOVC = ^^1Yeterli ^^4VC^^1 yok. Level atla, gunluk odul al, basarim ac!",
"SHOP_UNAVAIL = ^^1Bunu su an alamazsin.",
"ZC_ITEM_OFF = ^^1bu sunucuda kapali (bir dosyasi eksik). Yonetici: zc_modules",
"SHOP_LIMIT = ^^1Bu esya icin round limitine ulastin.",
"SHOP_ALREADY = ^^1Buna zaten sahipsin.",
"SHOP_BOUGHT = ^^4[$] ^^4%s^^1 aldin ^^3(-%d AP)^^1. Afiyet olsun!",
"MENU_SPECIAL = Ozel Silahlar",
"SW_BOUGHT = ^^4[$] ^^4%s^^1 kusandin! Olene kadar sende.",
"MENU_PERKS = Kalici Yetenekler",
"PERK_0 = Canlilik",
"PERK_DESC_0 = level basina +10 can",
"PERK_1 = Zirh Kaplama",
"PERK_DESC_1 = level basina +15 zirh",
"PERK_2 = Ates Gucu",
"PERK_DESC_2 = level basina +yuzde 3 hasar",
"PERK_3 = Sans",
"PERK_DESC_3 = level basina +yuzde 10 AP",
"PERK_4 = Ceviklik",
"PERK_DESC_4 = level basina +yuzde 2 hiz",
"PERK_5 = Olumsuz Deri",
"PERK_DESC_5 = level basina +yuzde 6 zombi cani",
"PERK_MAXED = ^^1Bu yetenek zaten maksimum seviyede.",
"PERK_UP = ^^1Yetenek yukseltildi: ^^4%s^^1. Gittikce gucleniyorsun!",
"MENU_TITLE = Unvanlar",
"TITLE_LOCKED = ^^1Bu unvan kilitli. Once basarimini ac.",
"TITLE_SELECTED = ^^1Unvan takildi: ^^4%s^^1. Cok yakisti!",
"MENU_ACH = Basarimlar",
"MENU_STYLE = Chat Stili",
"STYLE_0 = Klasik",
"STYLE_DESC_0 = yesil tag, takim renkli isim",
"STYLE_1 = Neon",
"STYLE_DESC_1 = rutbe renkli, kompakt",
"STYLE_2 = Sade",
"STYLE_DESC_2 = sadece isim",
"STYLE_CHOSEN = ^^1Chat stilin guncellendi. Bir sey yaz bakalim!",
"MENU_SETTINGS = Kisisel Ayarlar",
"MENU_SETTINGS_SUB = Profiline kaydedilir",
"SET_0 = HUD paneli",
"SET_1 = Hasar sayilari",
"SET_2 = Ekran efektleri",
"SET_3 = Ortam sesleri",
"SET_4 = Oldurme anonsu",
"SET_5 = Chat ipuclari",
"SET_6 = Otomatik silah",
"SET_7 = Sis",
"SET_THEME = HUD rengi",
"SET_LANG = Dil",
"SET_FPS = FPS / Performans >",
"THEME_0 = Vexmira",
"THEME_1 = Toksik",
"THEME_2 = Kan",
"THEME_3 = Ametist",
"THEME_4 = Okyanus",
"THEME_5 = Gun Batimi",
"MENU_LANG = Dil / Language",
"MENU_FPS = FPS / Performans",
"MENU_FPS_SUB = Profiller sana gelen efektleri azaltir",
"FPS_1 = Profil: Performans (max FPS)",
"FPS_2 = Profil: Dengeli",
"FPS_3 = Profil: Sinematik (tum efektler)",
"FPS_4 = FPS boost ayarlarini konsola yaz",
"FPS_5 = Ag (rate) ayarlarini konsola yaz",
"FPS_PRESET_PERF = ^^1Performans modu: efektler, sis ve ortam sesleri kapali.",
"FPS_PRESET_BAL = ^^1Dengeli mod: efektler acik, sis ve ortam sesi kapali.",
"FPS_PRESET_CINE = ^^1Sinematik mod: her sey acik. Keyfini cikar!",
"FPS_CONSOLE_HINT = Bu satirlari config.cfg'ne kopyala veya konsola yaz",
"FPS_PRINTED = ^^1Ayarlar ^^4konsoluna^^1 yazildi (~ tusuna bas).",
"MENU_ADMIN = Yonetim Paneli",
"ADM_SET_MODE = Mod",
"ADM_SET_EVENT = Event",
"STATS_1 = ^^1Level ^^4%d^^1 (^^4%s^^1)  XP ^^4%d^^1 / %d",
"STATS_2 = ^^1Cuzdan: ^^4%d AP^^1, ^^4%d VC",
"STATS_3 = ^^1Oldurme ^^4%d^^1  Enfeksiyon ^^4%d^^1  Headshot ^^4%d",
"STATS_4 = ^^1Galibiyet ^^4%d^^1  Boss ^^4%d^^1  Basarim ^^4%d/%d",
"STATS_5 = ^^1Oyun suresi ^^4%d sa %d dk^^1  Gunluk seri ^^4%d",
"TOP_TITLE = ^^1ONLINE EN IYI OYUNCULAR",
"TOP_LINE = ^^4#%d ^^3%s^^1 - Lv.^^4%d^^1 (%d XP)",
"MENU_PRIMARY = Ana Silah",
"MENU_GUNS_SUB = Kaydedilir; her dogusta otomatik verilir",
"MENU_SECONDARY = Yan Silah",
"GUNS_SAVED = ^^1Silahlar kaydedildi! Degistirmek icin ^^4/silah^^1 yaz.",
"ADV_13 = ^^4[VIP] ^^1VIP'ler ^^4cift ziplama^^1, fazla AP/XP, her round bedava paket ve daha fazlasini alir. ^^4/vipbilgi",
"ADV_14 = ^^1Sansina guveniyor musun? ^^4/slot 20^^1 dene ya da ^^4/piyango^^1 bileti al.",
"ADV_15 = ^^1Biri canini mi sikti? Basina odul koy: ^^4/odul isim 50",
"ADV_16 = ^^1Toplulugumuza katil! ^^4/iletisim",
"MAIN_16 = En Iyiler",
"MAIN_17 = \rAdmin Menusu",
"YOU_INFECTED = ^^3%s^^1 seni isirdi... artik sen de onlardansin. Yetenegin icin ^^4[R]^^1!",
"YOU_INFECTOR = ^^1Guzel isirik! ^^3%s^^1 artik senin surunde.",
"YOU_FIRST_ZOMBIE = ^^1Ilk zombi ^^3sensin^^1! Ekstra can sende, salgini yay. ^^4[R]^^1 = yetenek",
"YOU_FIRST_ZOMBIE_HUD = ILK ZOMBI SENSIN",
"YOU_DIED_ZOMBIE = ^^1Dustun ama bitmedin. ^^4%d^^1 saniye sonra geri donuyorsun.",
"ANTIDOTE_ALL = ^^3%s^^1 panzehiri icti ve ^^4tekrar insan^^1 oldu!",
"ROLE_NEMESIS_YOU = NEMESIS SENSIN - TEK VURUSTA OLDURURSUN^^n[R] atilma     [F] ya da [G] ofke",
"ROLE_ASSASSIN_YOU = ASSASSIN SENSIN - TEK VURUSTA OLDURURSUN^^n[R] atilma     [F] ya da [G] golge perdesi",
"ROLE_SURVIVOR_YOU = SURVIVOR SENSIN - sinirsiz mermi, hatti tut",
"ROLE_SNIPER_YOU = SNIPER SENSIN - tek atis, tek olum",
"ROLE_BOSS_YOU = ^^1BOSS ^^3sensin^^1! ^^4[R]^^1 = ozel yetenek, ^^4[F]^^1 ya da ^^4[G]^^1 = atilma.",
"HUD_10S = SON 10 SANIYE!",
"VIP_TIER_1 = VIP",
"VIP_TIER_2 = ELITE",
"VIP_JOIN = ^^4[%s] ^^3%s^^1 geldi. Yer acin!",
"VIP_JOIN_HUD = %s  %s  sunucuya giris yapti",
"VIP_ENDING = ^^1Haber verelim: VIP'in ^^4%d^^1 gun icinde bitiyor. Ayricaliklarin gitmesin!",
"VIP_DAYS_LEFT = ^^1Tekrar hos geldin! ^^4%d^^1 gun VIP'in var. Menun icin ^^4/vip^^1.",
"VIP_EXPIRED = ^^1VIP suren doldu. Simdiden ozledik, yenilemek icin ^^4/vipbilgi^^1.",
"VIP_GRANTED = ^^1VIP'in ^^4%d^^1 gun daha aktif. Bizi destekledigin icin tesekkurler!",
"VIP_ONLY = ^^1Bu sadece ^^4VIP'lere ozel^^1. ^^4/vipbilgi^^1'ye goz at.",
"VIP_LEFT_DAYS = %d gun kaldi",
"VIP_PERMANENT = kalici",
"MENU_VIP = VIP Salonu",
"VIPM_FREE_H = Bedava VIP paketi (round basina 1)",
"VIPM_FREE_Z = Bedava zombi paketi (round basina 1)",
"VIPM_AURA = Aura",
"AURA_0 = kapali",
"AURA_1 = Camgobegi",
"AURA_2 = Altin",
"AURA_3 = Mor",
"AURA_4 = Kirmizi",
"AURA_5 = Yesil",
"VIPM_TRAIL = Isik izi",
"VIPM_JUMPS = Ziplama ayricaliklarim",
"VIPM_INFO = Tum VIP ayricaliklari",
"VIP_JUMPS_VIP = ^^4Cift ziplaman^^1 var: havadayken tekrar zipla. ^^4ELITE^^1'de uclu!",
"VIP_JUMPS_ELITE = ^^4[ELITE] ^^4Uclu ziplaman^^1 var! Marketten Ekstra Ziplama alip bir tane daha ekleyebilirsin.",
"VIP_FREE_USED = ^^1Bu roundun paketini aldin. Sonraki roundda gorusuruz!",
"VIP_FREE_H_VIP = ^^1Paket teslim: ^^4200 zirh^^1, ^^4ates^^1 ve ^^4buz^^1 bombasi. Haydi!",
"VIP_FREE_H_ELITE = ^^4[ELITE] ^^1Paket teslim: zirh, 3 bomba, ^^4+100 can^^1 ve ^^4+yuzde 30 hasar^^1!",
"VIP_FREE_Z_VIP = ^^1Zombi paketi: ^^4+500 can^^1. Ava cik!",
"VIP_FREE_Z_ELITE = ^^4[ELITE] ^^1Zombi paketi: ^^4+1000 can^^1 ve yetenegin hazir!",
"VIPINFO_1 = ^^4===== VEXMIRA VIP / ELITE =====",
"VIPINFO_2 = ^^4[1] ^^1Cift ziplama (^^4ELITE^^1: uclu ziplama), renkli halka efektiyle",
"VIPINFO_3 = ^^4[2] ^^1+yuzde 25 AP ve XP (^^4ELITE^^1: +yuzde 50)",
"VIPINFO_4 = ^^4[3] ^^1Her round bedava paket: zirh + ates + buz bombasi (^^4ELITE^^1: +can, +hasar)",
"VIPINFO_5 = ^^4[4] ^^1Market ve ozel silahlar yuzde 10 ucuz (^^4ELITE^^1: yuzde 20)",
"VIPINFO_6 = ^^4[5] ^^1Dogusta zirh, daha hizli zombi donusu, daha buyuk gunluk odul",
"VIPINFO_7 = ^^4[6] ^^1Renkli aura, isik izi, [VIP]/[ELITE] tag'i ve giris duyurusu",
"VIPINFO_8 = ^^4[7] ^^1Markette VIP'e ozel Ekstra Ziplama",
"VIPINFO_BUY = ^^4[$] ^^1VIP almak icin bize ulas: ^^4%s",
"FUN_WAIT = ^^1Yavas biraz! ^^4%d^^1 saniye sonra tekrar dene.",
"FUN_DICE = ^^4[ZAR] ^^3%s^^1 zar atti: ^^4%d",
"FUN_DICE_6 = ^^4[ZAR] ^^3%s^^1 ^^4%d^^1 atti! Sansli gununde!",
"FUN_COIN_HEADS = ^^4[PARA] ^^3%s^^1 yazi tura atti: ^^4YAZI",
"FUN_COIN_TAILS = ^^4[PARA] ^^3%s^^1 yazi tura atti: ^^4TURA",
"FUN_ROLL = ^^4[SAYI] ^^3%s^^1 ^^4%d^^1 tuttu (1-%d)",
"FUN_BALL_USAGE = ^^1Bana bir sey sor: ^^4/soru Bu roundu kazanir miyiz?",
"FUN_BALL_Q = ^^3%s^^1 soruyor: ^^4%s",
"BALL_1 = ^^4Vexmira^^1 diyor ki: ^^4Kesinlikle, hic suphe yok.",
"BALL_2 = ^^4Vexmira^^1 diyor ki: ^^4Zombiler hayir diyor.",
"BALL_3 = ^^4Vexmira^^1 diyor ki: ^^4Bu round bitince tekrar sor.",
"BALL_4 = ^^4Vexmira^^1 diyor ki: ^^4Isaretler evet diyor.",
"BALL_5 = ^^4Vexmira^^1 diyor ki: ^^4Hic sansi yok. Kusura bakma!",
"BALL_6 = ^^4Vexmira^^1 diyor ki: ^^4Hmm... belki. Bicagini yakin tut.",
"BALL_7 = ^^4Vexmira^^1 diyor ki: ^^4Evet, kamp yapmayi birakirsan.",
"BALL_8 = ^^4Vexmira^^1 diyor ki: ^^4Kaynaklarim hayir diyor.",
"BALL_9 = ^^4Vexmira^^1 diyor ki: ^^4Kesin oyle.",
"BALL_10 = ^^4Vexmira^^1 diyor ki: ^^4Simdi soylemesem daha iyi...",
"BALL_11 = ^^4Vexmira^^1 diyor ki: ^^4Once bir ilk yardim alirsan, evet.",
"BALL_12 = ^^4Vexmira^^1 diyor ki: ^^4Yildizlar ve beyinler ayni hizada: EVET.",
"JOKE_1 = ^^4[ESPRI] ^^1Zombiler neden palyaco yemez? Tadi komik oluyor.",
"JOKE_2 = ^^4[ESPRI] ^^1Bir zombi bara girer ve siparis verir... BEYIIIN. Yol icin de bir ilk yardim.",
"JOKE_3 = ^^4[ESPRI] ^^1Nisanim o kadar kotu ki zombiler yanimda kendini guvende hissediyor.",
"JOKE_4 = ^^4[ESPRI] ^^1Zombiler takim calismasinda harika. Hep kafa kafaya veriyorlar.",
"JOKE_5 = ^^4[ESPRI] ^^1Zombi neden gec kaldi? Beyne giden uzun yolu secti.",
"JOKE_6 = ^^4[ESPRI] ^^1Kamp yapmiyorum, takim icin bu koseyi koruyorum.",
"JOKE_7 = ^^4[ESPRI] ^^1Zombiler asla kaybolmaz. Hep iclerinden gelene uyarlar.",
"JOKE_8 = ^^4[ESPRI] ^^1Son insan hep 'hallederim' der. Tarih aksini soyluyor.",
"JOKE_9 = ^^4[ESPRI] ^^1Zombiler kisin ne giyer? Isiriga dayanikli mont.",
"JOKE_10 = ^^4[ESPRI] ^^1Buz bombasi aldim. Simdi K/D'm bile dondu.",
"JOKE_11 = ^^4[ESPRI] ^^1Zombi diyet onerisi: beyin yiyin, akilli fikirlerle dolu.",
"JOKE_12 = ^^4[ESPRI] ^^1Nemesis geldi. Herkes birden odevi oldugunu hatirladi.",
"FUN_DANCE_1 = ^^4* ^^1^^3%s^^1 kiyametin ortasinda breakdance yapiyor!",
"FUN_DANCE_2 = ^^4* ^^1^^3%s^^1 zombi dansi yapiyor. Cok akici!",
"FUN_DANCE_3 = ^^4* ^^1^^3%s^^1 kimse enfekte degilmis gibi dans ediyor.",
"FUN_DANCE_4 = ^^4* ^^1^^3%s^^1 zafer dansi yapiyor. Round bitti mi yoksa?",
"FUN_RS = ^^1Skorun sifirlandi. Temiz bir sayfa, iyi degerlendir!",
"FUN_TIME = ^^1Sunucu saati: ^^4%s",
"FUN_PING_GOOD = ^^1Ping ^^4%d^^1 ms, kayip %d. Tereyagi gibi!",
"FUN_PING_OK = ^^1Ping ^^4%d^^1 ms, kayip %d. Oynanir.",
"FUN_PING_BAD = ^^1Ping ^^4%d^^1 ms, kayip %d. Ag ayarlari icin /performans.",
"FUN_WHO_TITLE = ^^1Online yetkililer ve VIP'ler:",
"FUN_WHO_NONE = ^^1   Su an kimse yok. Hayalet sehir!",
"FOUNDERS_1 = ^^1VEXMIRA, ^^3SmurfSexy^^1 ve ^^3Capital^^1 tarafindan kuruldu.",
"FOUNDERS_2 = ^^1Zombi severler icin sevgiyle yapildi. Bizimle oynadigin icin tesekkurler!",
"FOUNDERS_3 = ^^1Fikir, hata bildirimi, VIP: ^^4/iletisim",
"FUN_CONTACT = ^^1Toplulugumuz: ^^4%s^^1 - gel bir selam ver!",
"RULE_1 = ^^4[KURALLAR / RULES]",
"RULE_2 = ^^41. ^^1Hile ve script yok. Aninda ban.",
"RULE_3 = ^^42. ^^1Herkese saygi. Kufur ve hakaret yok.",
"RULE_4 = ^^43. ^^1Chat'i ve mikrofonu spamlamak yok.",
"RULE_5 = ^^44. ^^1Bug ve harita aciklarini kullanmak yok.",
"RULE_6 = ^^45. ^^1Eglen ve yeni gelenlere yardim et!",
"SLOT_USAGE = ^^4[SLOT] ^^1Kullanim: ^^4/slot 20^^1 (5-200 AP bahis). Uc tane 7 x10 oder!",
"SLOT_JACKPOT = ^^4[SLOT] ^^3%s^^1 ^^4JACKPOT^^1 vurdu ve ^^4%d AP^^1 kazandi!",
"SLOT_WIN = ^^4[SLOT] ^^1Guzel! ^^4%d AP^^1 kazandin.",
"SLOT_LOSE = ^^4[SLOT] ^^1Bu sefer olmadi... ^^3-%d AP^^1. Bir tur daha?",
"LOTTO_MAX = ^^1Her cekilis icin en fazla ^^4%d^^1 bilet. Bol sans!",
"LOTTO_BOUGHT = ^^4[PIYANGO] ^^1Bilet alindi (^^4%d^^1 biletin var). Ikramiye: ^^4%d AP^^1, cekilis yaklasik ^^4%d^^1 dk sonra.",
"LOTTO_SOON = ^^4[PIYANGO] ^^1Cekilise ^^41 dakika^^1! Ikramiye: ^^4%d AP^^1. Son sans: ^^4/piyango",
"LOTTO_REFUND = ^^4[PIYANGO] ^^1Cekilise yeterli kisi katilmadi, biletlerin iade edildi.",
"LOTTO_WINNER = ^^4[PIYANGO] ^^3%s^^1 buyuk ikramiyeyi kazandi: ^^4%d AP^^1 (%d biletle)! Tebrikler!",
"GIFT_USAGE = ^^1Kullanim: ^^4/hediye isim 20^^1 (en az 5 AP)",
"GIFT_DONE = ^^4[HEDIYE] ^^3%s^^1, ^^3%s^^1'e ^^4%d AP^^1 hediye etti. Iste dostluk!",
"BOUNTY_USAGE = ^^1Kullanim: ^^4/odul isim 50^^1 (en az 10 AP). Onu kim indirirse odulu alir.",
"BOUNTY_DEAD = ^^1Hedefin hayatta olmali.",
"BOUNTY_SET = ^^4[ODUL] ^^3%s^^1, ^^3%s^^1'in basina odul koydu! Toplam: ^^4%d AP",
"BOUNTY_PAID = ^^4[ODUL] ^^3%s^^1 tam ^^4%d AP^^1 odulu kapti! Hedef: ^^3%s^^1",
"MENU_FUN = Eglence & Oyunlar",
"MENU_FUN_SUB = Eglen ama zombileri unutma",
"FUNM_1 = Zar at",
"FUNM_2 = Yazi tura",
"FUNM_3 = Espri yap",
"FUNM_4 = Dans et!",
"FUNM_5 = Slot makinesi (10 AP)",
"FUNM_6 = Piyango bileti (10 AP)",
"FUNM_7 = Hediye / odul / soru (nasil?)",
"FUNM_8 = Skorumu sifirla",
"FUNM_9 = Kimler online (yetkili/VIP)",
"FUNM_10 = Sunucu saati",
"FUNM_11 = Kurallar",
"FUNM_12 = Kurucular",
"FUN_HINT_ARGS = ^^1Chat'e yaz: ^^4/hediye isim 20^^1, ^^4/odul isim 50^^1, ^^4/soru sorun^^1, ^^4/sayi 100^^1, ^^4/me el sallar",
"LIVE_JOINNEW_1 = Aramiza yeni biri katildi: ^^3%s^^1! Herkes bir merhaba desin!",
"LIVE_JOINNEW_2 = Taze kan! Hos geldin ^^3%s^^1, dogru sunucuyu sectin.",
"LIVE_JOINNEW_3 = ^^3%s^^1 ilk kez aramizda. Biraz yumusak davranin... ya da davranmayin!",
"LIVE_JOINBACK_1 = Bakin kim geldi! ^^3%s^^1, seni ^^4%d^^1 gundur goremiyorduk!",
"LIVE_JOINBACK_2 = ^^3%s^^1 tam ^^4%d^^1 gun sonra dondu. Zombiler seni ozlemis.",
"LIVE_JOINBACK_3 = Tekrar hos geldin ^^3%s^^1! ^^4%d^^1 gun... yerini sicak tuttuk.",
"LIVE_JOINSOON_1 = ^^3%s^^1 uzun sure uzak duramadi. Tekrar hos geldin!",
"LIVE_JOINSOON_2 = Selam ^^3%s^^1, seni tekrar gormek guzel!",
"LIVE_JOINSOON_3 = ^^3%s^^1 geldi. Simdi parti baslayabilir.",
"LIVE_CROWD_1 = ^^4%d^^1 kisi olduk! Isler ciddilesiyor.",
"LIVE_CROWD_2 = Vay, ^^4%d^^1 kisiyiz. Zombilerin bu gece isi zor.",
"LIVE_LEAVE_1 = ^^3%s^^1 sunucudan ayrildi. Gorusmek uzere!",
"LIVE_LEAVE_2 = ^^3%s^^1 gitmek zorunda kaldi. Saglicakla kal!",
"LIVE_LEAVE_3 = Gule gule ^^3%s^^1, isiklari acik birakiyoruz.",
"LIVE_HELLO_1 = Aleykum selam ^^3%s^^1, hos geldin!",
"LIVE_HELLO_2 = Selam ^^3%s^^1, iyi ki geldin!",
"LIVE_HELLO_3 = Merhaba ^^3%s^^1! Zombilere hazir misin?",
"LIVE_HELLO_4 = Selam ^^3%s^^1, silahini kap ve eglenceye katil!",
"LIVE_GG_1 = GG ^^3%s^^1! Guzel roundtu.",
"LIVE_GG_2 = GG WP ^^3%s^^1!",
"LIVE_GG_3 = Iyi oyundu ^^3%s^^1, sonraki round senin!",
"LIVE_BYE_1 = Iyi geceler ^^3%s^^1! Zombisiz tatli ruyalar.",
"LIVE_BYE_2 = Iyi uykular ^^3%s^^1, yarin gorusuruz!",
"LIVE_BYE_3 = Iyi geceler ^^3%s^^1! Yarin gunluk odulunu almayi unutma.",
"LIVE_HOW_1 = Iyiyim ^^3%s^^1, sunucu zombi dolu yani... mukemmel!",
"LIVE_HOW_2 = Her sey yolunda ^^3%s^^1! Bugun nisanin nasil?",
"LIVE_HOW_3 = Hic olmadigi kadar iyi ^^3%s^^1. Sen nasilsin?",
"LIVE_CALL_1 = Beni mi cagirdin ^^3%s^^1? Hep buradayim.",
"LIVE_CALL_2 = Buyur ^^3%s^^1? Vexmira dinliyor.",
"LIVE_CALL_3 = Benim! Ne var ne yok ^^3%s^^1?",
"LIVE_THANKS_1 = Ne demek ^^3%s^^1!",
"LIVE_THANKS_2 = Rica ederim ^^3%s^^1, iyi eglenceler!",
"LIVE_VIPASK_1 = ^^3%s^^1, VIP bilgileri ^^4/vipbilgi^^1'de. Almak icin: ^^4%s",
"LIVE_LAG_1 = ^^3%s^^1, ^^4/performans^^1'i dene, performans profili cok fark ediyor.",
"LIVE_LAG_2 = Lag mi var ^^3%s^^1? ^^4/performans^^1 en iyi ag ayarlarini konsoluna yazar.",
"LIVE_TOPKILL_1 = Bu haritanin kasabi ^^3%s^^1, tam ^^4%d^^1 oldurme. Onu kim durduracak?",
"LIVE_TOPKILL_2 = ^^3%s^^1 bu haritada ^^4%d^^1 zombi indirdi. Saygilar.",
"LIVE_TOPKILL_3 = Zombiler, ^^3%s^^1'e dikkat. ^^4%d^^1 taneniz coktan dustu.",
"LIVE_HSTREAK_1 = Insanlar ^^4%d^^1 round ust uste kazandi! Zombiler, toparlanin.",
"LIVE_HSTREAK_2 = Ust uste ^^4%d^^1 insan galibiyeti. Burasi kale mi ne?",
"LIVE_ZSTREAK_1 = Zombiler ^^4%d^^1 round ust uste kazandi. Insanlar, birbirinize yakin durun!",
"LIVE_ZSTREAK_2 = Ust uste ^^4%d^^1 zombi galibiyeti... salgin kazaniyor.",
"LIVE_TIME0_1 = Bu saatte hala buradasiniz ha? Siz gece kuslari efsanesiniz.",
"LIVE_TIME0_2 = Gecenin bu saati... zombiler icin en guzel zaman.",
"LIVE_TIME1_1 = Gunaydin herkese! Bir elde kahve, bir elde tufek.",
"LIVE_TIME1_2 = Sabah vardiyasi basladi. Gunluk odulunu unutma: /gunluk",
"LIVE_TIME2_1 = Iyi ogleden sonralar! Boss roundu icin tam zamani, degil mi?",
"LIVE_TIME2_2 = Ogle arasi zombi mi? Tarzini sevdim.",
"LIVE_TIME3_1 = Iyi aksamlar! Sunucu isiniyor, arkadaslarini da cagir.",
"LIVE_TIME3_2 = Aksam ekibi geldi. Guzel bir gece olsun!",
"LIVE_RANDOM_1 = Ipucu: zirh enfeksiyonu durdurur. Hep dolu tut!",
"LIVE_RANDOM_2 = Biliyor muydun? Headshot bonus AP verir. Kafaya nisan al, fazla kazan.",
"LIVE_RANDOM_3 = Zombiler, [R] yeteneginin bekleme suresi var. Akilli kullanin!",
"LIVE_RANDOM_4 = Sansli hissediyor musun? /slot seni bekliyor.",
"LIVE_RANDOM_5 = Birbirinizden kopmayin insanlar. Yalniz kurtlari ilk once yerler.",
"LIVE_RANDOM_6 = Unutma: yeteneklerin asla sifirlanmaz. VC'ni yatirima donustur!",
"LIVE_RANDOM_7 = Sunucuyu sevdiysen favorilerine ekle!",
"LIVE_RANDOM_8 = Arkadaslarini getir, ne kadar kalabalik o kadar kaos.",
"LIVE_RANDOM_9 = Buz bombasi + Yildirim = zombi dondurmasi. Bir dene.",
"LIVE_RANDOM_10 = Boss yuzde 30 canin altinda delirir. Hazir olun!",
"LIVE_30S_1 = 30 saniye kaldi! Dayanin insanlar!",
"LIVE_30S_2 = Sadece 30 saniye... iceri sokmayin!",
"LIVE_30S_3 = Yarim dakika kaldi. Zombiler, ya simdi ya hic!",
"LIVE_FIRSTINF_1 = Roundun ilk kurbani: ^^3%s^^1 enfekte oldu. Basliyor...",
"LIVE_FIRSTINF_2 = Ve ilk dusen ^^3%s^^1. Salgin basladi!",
"LIVE_FIRSTINF_3 = Ilk isirilan ^^3%s^^1. Birileri zirh almaliydi.",
"HUD_P_HP = CAN  %d      ZIRH  %d",
"HUD_P_DEAD = IZLEYICI MODU...",
"HUD_AIM = %s   [%s]^^nCAN %d   ZIRH %d   LV.%d",
"SET_HUDPOS = Panel konumu",
"HUDPOS_0 = Sag orta",
"HUDPOS_1 = Sol orta",
"HUDPOS_2 = Sol ust",
"HUDPOS_3 = Sag ust",
"HUDPOS_4 = Alt orta",
"MENU_ADMIN_SUB = Tum islemler kayit altina alinir",
"ADMM_1 = Sonraki round: MOD sec",
"ADMM_2 = Bir MODU simdi baslat (round yenilenir)",
"ADMM_3 = Sonraki round: EVENT sec",
"ADMM_4 = Bir EVENTI simdi baslat (round yenilenir)",
"ADMM_5 = Sonraki round: BOSS sec",
"ADMM_6 = Simdi BOSS cagir (round yenilenir)",
"ADMM_7 = Oyuncu islemleri",
"ADMM_8 = Hava durumu / isik (hemen)",
"ADMM_9 = Mod oylamasi baslat",
"ADMA_1 = 100 AP ver",
"ADMA_2 = 10 VC ver (owner)",
"ADMA_3 = 1000 XP ver (owner)",
"ADMA_4 = Zombi yap",
"ADMA_5 = Insan yap",
"ADMA_6 = Nemesis yap",
"ADMA_7 = Survivor yap",
"ADMA_8 = Canlandir",
"ADMA_9 = Oldur",
"ADMA_10 = 30 gun VIP ver (owner)",
"ADMA_11 = 30 gun ELITE ver (owner)",
"ADMA_12 = VIP'i kaldir (owner)",
"ADM_ACTION = ^^4%s^^1 -> ^^3%s^^1 : ^^4%s",
"ADM_GONE = ^^1Bu oyuncu artik sunucuda degil.",
"ADM_NEED_OWNER = ^^1Bunu sadece ^^4owner^^1 yapabilir.",
"ADM_RESTART = ^^4%s^^1 roundu yeniden baslatti.",
"ADM_NOW_MODE = ^^4%s^^1 ^^4#%d^^1 numarali modu simdi baslatiyor!",
"ADM_GIFT_ALL = ^^4[$] ^^3%s^^1 herkese ^^4%d AP^^1 dagitti! Bir tesekkur edin!",
"ADM_RESPAWN_OFF = ^^4%s^^1 zombi geri donusunu ^^3KAPATTI^^1.",
"ADM_RESPAWN_ON = ^^4%s^^1 zombi geri donusunu ^^4ACTI^^1.",
"VOTE_RUNNING = ^^1Zaten devam eden bir oylama var.",
"VOTE_START_MODE = ^^4[OYLAMA] ^^3%s^^1 sonraki round icin ^^4mod oylamasi^^1 baslatti! ^^4%d^^1 saniye, secimini yap!",
"VOTE_START_EVENT = ^^4[OYLAMA] ^^3%s^^1 ^^4event oylamasi^^1 baslatti! ^^4%d^^1 saniye, secimini yap!",
"VOTE_TITLE_MODE = Sonraki Round Mod Oylamasi",
"VOTE_TITLE_EVENT = Sonraki Round Event Oylamasi",
"VOTE_LEFT = Oylamanin bitmesine \r%d saniye\y kaldi",
"VOTE_VOTES = oy",
"VOTE_TIE = Esitlik olursa rastgele secilir.",
"VOTE_CAST = ^^4[OYLAMA] ^^3%s^^1 oyunu ^^4%s^^1 icin kullandi",
"VOTE_RESULT = ^^4[OYLAMA] ^^1Kazanan ^^4%s^^1, tam ^^4%d^^1 oyla! Sonraki roundda geliyor.",
"VOTE_RESULT_HUD = OYLAMA SONUCU: %s",
"BUY_ALL_H = ^^4[$] ^^3%s^^1 az once ^^4%s^^1 aldi!",
"BUY_ALL_Z = ^^3%s^^1 az once ^^3%s^^1 aldi! Dikkat edin insanlar!",
"ESHIELD_HIT = ^^1Enerji kalkanin bir darbeyi engelledi! Kalan: ^^4%d",
"LUCKY_DODGE = ^^1Sansli gunundesin! Isiriktan kil payi kurtuldun!",
"JOB_16 = Juggernaut",
"JOB_DESC_16 = +100 maksimum can, biraz yavas",
"JOB_17 = Ninja",
"JOB_DESC_17 = sessiz adim, +yuzde 6 hiz",
"JOB_18 = Ghost",
"JOB_DESC_18 = yari saydam olursun",
"JOB_19 = Grenadier",
"JOB_DESC_19 = her dogusta bedava ates + buz bombasi",
"JOB_20 = Hunter",
"JOB_DESC_20 = her zombi olumunde +2 AP",
"JOB_21 = Doctor",
"JOB_DESC_21 = yakindaki insanlari saniyede 3 can iyilestirir",
"JOB_22 = Gambler",
"JOB_DESC_22 = yuzde 10 sansla AP kazanci ikiye katlanir",
"JOB_23 = Tactician",
"JOB_DESC_23 = +yuzde 30 geri itme",
"JOB_24 = Lucky",
"JOB_DESC_24 = yuzde 7 sansla zombi isirigindan kacar",
"JOB_25 = Elite Soldier",
"JOB_DESC_25 = +yuzde 10 hasar, +25 zirh",
"ITEM_18 = Adrenalin Ignesi",
"ITEM_DESC_18 = 6 sn +yuzde 40 hiz",
"ITEM_19 = Hayalet Pelerini",
"ITEM_DESC_19 = 8 sn gorunmezlik",
"ITEM_20 = Gece Gorusu",
"ITEM_DESC_20 = karanlikta gor (N tusu)",
"ITEM_21 = Enerji Kalkani",
"ITEM_DESC_21 = sonraki 2 isirigi engeller",
"ITEM_22 = Cephane Kutusu",
"ITEM_DESC_22 = tum mermilerini doldurur",
"ITEM_23 = Zombi Kosusu",
"ITEM_DESC_23 = 6 sn +yuzde 30 hiz",
"ITEM_24 = Golge Ortusu",
"ITEM_DESC_24 = 6 sn gorunmezlik",
"ITEM_25 = Mutant Bacaklar",
"ITEM_DESC_25 = bu hayat dusuk yercekimi",
"ITEM_26 = Yenilenme",
"ITEM_DESC_26 = saniyede +60 can",
"ITEM_27 = Demir Durus",
"ITEM_DESC_27 = geri itilmezsin",
"GUN_LOCKED = ^^1Bunun icin ^^4%d^^1. level gerekli!",
"VIP_WELCOME_SELF = ^^4[%s] ^^1Hos geldin ^^3%s^^1! Ayricaliklarin aktif. VIP salonun icin ^^4/vip^^1.",
"VIP_WELCOME_HUD = %s AYRICALIKLARIN AKTIF",
"WAITING_PLAYERS = OYUNCU BEKLENIYOR   ( %d / 2 )",
"TOP_LINE1 = -  V E X M I R A   Z O M B I E  -",
"TOP_LINE2 = - ZOMBI : %d  |  ROUND : %d  |  INSAN : %d -",
"TOP_LINE3 = - %s  |  %s  |  %d:%02d -",
"SET_8 = Zombi gorusu",
"BOSS_HPLINE = CAN  %d / %d",
"BOSS_PH_1 = FAZ   [ I ]   II   III",
"BOSS_PH_2 = FAZ   I   [ II ]   III",
"BOSS_PH_RAGE = FAZ   I   II   [ III ]   OFKE",
"BOSS_PHASE_2 = FAZ II^^nBoss gucleniyor - yeni yetenekler acildi!",
"BOSS_BOARD_TITLE = ^^1Hasar siralamasi:",
"BOSS_BOARD_LINE = ^^4  #%d ^^3%s^^1 - ^^4%d^^1 hasar ^^4(+%d AP)",
"BOSS_WARN_0 = YER DARBESI GELIYOR^^nBRUTE'tan uzaklas!",
"BOSS_WARN_1 = CIGLIK GELIYOR^^nKulaklarini kapat, kac!",
"BOSS_WARN_2 = OLULER CAGRILIYOR^^nOrdusu buyumeden boss'u indirin!",
"BOSS_WARN_3 = ATES DALGASI GELIYOR^^nMenzilinden cik!",
"BOSS_WARN_4 = REAPER SECIYOR^^nBirinin kapisi calinmak uzere...",
"BOSS_WARN2_0 = HUCUM^^nBRUTE atilmak uzere!",
"BOSS_WARN2_1 = FERYAT^^nHaritada guvenli yer yok!",
"BOSS_WARN2_2 = KARANLIK KALKAN^^nYa bekle ya da yuklen!",
"BOSS_WARN2_3 = METEOR YAGMURU^^nUstundeki kirmizi halkalara dikkat!",
"BOSS_WARN2_4 = RUH HASADI^^nDagilin, yakindaki herkesi emiyor!",
"BOSS_ABIL2_0 = HUCUM!^^nYer catliyor!",
"BOSS_ABIL2_1 = FERYAT!^^nTum harita titriyor!",
"BOSS_ABIL2_2 = KARANLIK KALKAN!^^nIyilesiyor ve sertlesiyor!",
"BOSS_ABIL2_3 = METEOR YAGMURU!^^nGokten ates yagiyor!",
"BOSS_ABIL2_4 = RUH HASADI!^^nCanin Reaper'i besliyor!",
"CLASS_8 = Spitter",
"CLASS_DESC_8 = [R] onune asit puskurtur, yavaslatir",
"CLASS_9 = Hulk",
"CLASS_DESC_9 = devasa can. [R] sok dalgasi insanlari savurur",
"CLASS_10 = Voodoo",
"CLASS_DESC_10 = [R] yakindaki zombileri iyilestirir",
"CLASS_11 = Phantom",
"CLASS_DESC_11 = cok hizli. [R] ileri isinlanir",
"JOIN_CONNECTING = ^^3%s^^1 baglaniyor...",
"JOIN_CONNECTING_C = ^^3%s^^1 baglaniyor... ^^4(%s)",
"WELCOME_4 = ^^1Her harita ^^430 round^^1: boss savaslari, ozel modlar ve bir ^^3FINAL BOSS^^1. Plan icin ^^4/harita^^1 yaz.",
"WELCOME_HUD2 = Kurucular: SmurfSexy & Capital^^nM = menu   |   V = lazer   |   sag tik = bomba modu",
"LM_BIND_HINT = ^^4[LASER] ^^4V^^1 = kur, ^^4C^^1 = sok (C icin bind gerekmez). Konsol: ^^4bind v +setlaser",
"ROUND_CHAT2 = ^^4%d^^1/^^4%d^^1. round basliyor. Dikkatli ol.",
"FINAL_ROUND_CHAT = ^^1Haritanin ^^3SON ROUNDU^^1! Her seyini ortaya koy.",
"ROUNDS_LEFT_2 = ^^1Bu haritada sadece ^^42 round^^1 kaldi.",
"BOSS_SOON_1 = ^^3BOSS^^1 bir ^^4sonraki round^^1 geliyor! Hazirligini simdi yap.",
"BOSS_SOON_2 = ^^4%d^^1 round sonra boss savasi var. AP'ni biriktir!",
"FINAL_BOSS_HUD = FINAL BOSS^^nHepsinden guclusu - son round!",
"FINAL_BOSS_TAG = FINAL BOSS",
"PLAN_1 = ^^4[PLAN] ^^1Round ^^4%d^^1 / ^^4%d",
"PLAN_2 = ^^4[PLAN] ^^1Boss roundlari: ^^3%s",
"PLAN_3 = ^^4[PLAN] ^^1Ozel mod roundlari: ^^4%s",
"PLAN_4 = ^^4[PLAN] ^^1Diger roundlar: rastgele event'li enfeksiyon. Son round = ^^3FINAL BOSS^^1.",
"TOP_A = V E X M I R A   //   ROUND  %d / %d",
"TOP_B = ZOMBI  %d    -    %d  INSAN",
"TOP_B_BOSS = BOSS SAVASI    -    %d  INSAN HAYATTA",
"TOP_C = %s   ::   %s",
"CSO_TOP_C531 = ROUND %d / %d   %d:%02d",
"CSO_TOP_L531 = [ INSAN  %d ]",
"CSO_TOP_R531 = [ %d  ZOMBI ]",
"CSO_TOP_RB531 = [ BOSS  %d%% ]",
"TB532_HUM = INSAN",
"TB532_ZOM = ZOMBI",
"TB532_ALIVE = CANLI",
"TB532_ROUND = TUR %d / %d",
"CSO_TOP_A = <<=====[   ROUND  %d / %d   |   %d:%02d   ]=====>>",
"CSO_TOP_B = INSAN  %d      VS      %d  ZOMBI",
"CSO_TOP_BOSS = BOSS SAVASI      VS      %d  INSAN",
"CSO_MVP_SUB = %d hasar  |  %d oldurme  |  %d enfeksiyon",
"CSO_P1 = Lv.%d   %s",
"CSO_P1R = Lv.%d   %s   #%d",
"CSO_P_HP = CAN  %d     ZIRH  %d",
"CSO_P3 = AP  %d     VC  %d     SERI  %d",
"CSO_LEVEL_SUB = SEVIYE  %d",
"TOP_C_BOSSIN = %s   ::   %s   ::   BOSS: %d ROUND SONRA",
"TOP_C_FINAL = %s   ::   %s   ::   SON ROUND",
"HUD_JOB_LM = MESLEK  %s   ::   LAZER  %d  (%d KURULU)",
"MVP_HUD = MVP :  %s^^n%d hasar  |  %d oldurme  |  %d enfeksiyon",
"MVP_CHAT2 = ^^4[MVP] ^^3%s^^1 - ^^4%d^^1 hasar, ^^4%d^^1 oldurme, ^^4%d^^1 enfeksiyon ^^4(+%d AP  +%d VC)",
"MAPEND_HUD = HARITA TAMAMLANDI!^^nEn iyiler odullendiriliyor",
"MAPEND_TITLE = ^^4[HARITA SONU] ^^1Bu haritanin odulleri ^^4(her biri +5 VC)^^1:",
"MAPEND_KILLS = ^^1  En cok olduren: ^^3%s ^^4(%d oldurme)",
"MAPEND_INF = ^^1  En cok enfekte eden: ^^3%s ^^4(%d enfeksiyon)",
"MAPEND_BOSS = ^^1  Boss avcisi: ^^3%s ^^4(%d boss hasari)",
"SET_9 = Ipuclari",
"MAIN_18 = Lazer Mayini",
"MAIN_19 = Bomba Modlari",
"MAIN_20 = Round Gorevi",
"ADM_BOSS_PICK = Hangi boss gelsin?",
"ADM_BOSS_RANDOM = Rastgele (karisik sira)",
"ADV_17 = ^^1Her round ^^43 bedava lazer^^1: ^^4V^^1 = kur, ^^4C^^1 = sok. Isina degen zombi olur!",
"ADV_18 = ^^1Bomba elindeyken sag tik: ^^4carpma, sensor, lazer tuzak, gudumlu, parcali^^1!",
"ADV_19 = ^^1Gokyuzune uzanan ^^4altin isik^^1 = ^^4hava ikmali^^1. Mesafe ve yon HUD'da yazar!",
"ADV_20 = ^^1Zombiler: bir roundda ^^43^^1 insan enfekte et, ^^3ALFA ZOMBI^^1 ol.",
"EV_NAME_17 = Firtina",
"EV_NAME_18 = Elektrik Kesintisi",
"EV_ANN_17 = EVENT: FIRTINA^^nYildirimlar zombileri avliyor!",
"EV_ANN_18 = EVENT: ELEKTRIK KESINTISI^^nZifiri karanlik. Fenerini ac (F)!",
"SPEED_TIP = ^^4[HIZ] ^^1Herkes ^^4cok daha hizli^^1, zipladiktan sonra yavaslama yok, gorus genis!",
"STORM_TIP = ^^4[FIRTINA] ^^1Yildirimlar rastgele, cogunlukla ^^3zombilere^^1 duser. Isiklardan uzak dur!",
"BLACKOUT_TIP = ^^4[KARANLIK] ^^1Elektrikler kesildi! ^^4Fenerini (F)^^1 kullan - zombilerin gozleri kirmizi parlar.",
"BOSS_TITLE_0 = DURDURULAMAZ",
"BOSS_INFO_0 = ^^3BRUTE^^1 - [R]: ^^4SISMIK EZME^^1 > ^^4YER YARIGI^^1 > ^^3TITAN OFKESI^^1. Mesafeni koru!",
"BOSS_TITLE_1 = CIGLIKLARIN KRALICESI",
"BOSS_INFO_1 = ^^3BANSHEE^^1 - [R]: ^^4SES MIZRAGI^^1 > ^^4HAYALET CIGLIGI^^1 > ^^3AGIT^^1. Onunde durma!",
"BOSS_TITLE_2 = OLULERIN EFENDISI",
"BOSS_INFO_2 = ^^3OVERLORD^^1 - [R]: ^^4KEMIK HAPSI^^1 > ^^4LEJYON^^1 > ^^3OLUM NOVASI^^1. Ordusu buyumeden indir!",
"BOSS_TITLE_3 = YASAYAN ALEV",
"BOSS_INFO_3 = ^^3INFERNO^^1 - [R]: ^^4ALEV NEFESI^^1 > ^^4ATES SUTUNLARI^^1 > ^^3SUPERNOVA^^1. Asla yerinde durma!",
"BOSS_TITLE_4 = RUH TOPLAYICI",
"BOSS_INFO_4 = ^^3REAPER^^1 - [R]: ^^4GOLGE ADIMI^^1 > ^^4RUH ZINCIRLERI^^1 > ^^3OLUM ISARETI^^1. En zayifi avlar!",
"BOSS_NAME_5 = FROSTLORD",
"BOSS_TITLE_5 = SONSUZ KIS",
"BOSS_ANN_5 = BOSS ROUND^^nFROSTLORD kisi getiriyor...",
"BOSS_START_5 = FROSTLORD UYANDI!^^nDonma!",
"BOSS_INFO_5 = ^^3FROSTLORD^^1 - [R]: ^^4BUZ PARCALARI^^1 > ^^4BUZ MEZARI^^1 > ^^3MUTLAK SIFIR^^1. Hep hareket et!",
"BOSS_NAME_6 = STORMCALLER",
"BOSS_TITLE_6 = GOK GURULTUSUNUN SESI",
"BOSS_ANN_6 = BOSS ROUND^^nSTORMCALLER bulutlari topluyor...",
"BOSS_START_6 = STORMCALLER UYANDI!^^nGokyuzu ofkeli!",
"BOSS_INFO_6 = ^^3STORMCALLER^^1 - [R]: ^^4TOP YILDIRIM^^1 > ^^4YILDIRIM ATILMASI^^1 > ^^3KASIRGA^^1. Gorus hattini kir!",
"BOSS_NAME_7 = HIVE QUEEN",
"BOSS_TITLE_7 = SURUNUN ANASI",
"BOSS_ANN_7 = BOSS ROUND^^nHIVE QUEEN kulucka yapiyor...",
"BOSS_START_7 = HIVE QUEEN UYANDI!^^nYuvayi yakin!",
"BOSS_INFO_7 = ^^3HIVE QUEEN^^1 - [R]: ^^4ASIT TUKURUGU^^1 > ^^4ZEHIR BULUTU^^1 > ^^3KULUCKA^^1. Yumurtalari yak!",
"BOSS_NAME_8 = VOID",
"BOSS_TITLE_8 = YUTUCU",
"BOSS_ANN_8 = BOSS ROUND^^nVOID aciliyor...",
"BOSS_START_8 = VOID UYANDI!^^nIceri cekilme!",
"BOSS_INFO_8 = ^^3VOID^^1 - [R]: ^^4BOSLUK OKU^^1 > ^^4TEKILLIK^^1 > ^^3OLAY UFKU^^1. Icine cekilme!",
"BOSS_WARN_5 = BUZ PATLAMASI GELIYOR^^nMavi alandan cik!",
"BOSS_WARN_6 = YILDIRIM GELIYOR^^nSari halkalardan cik!",
"BOSS_WARN_7 = ASIT HAVUZLARI^^nKac, zemin eriyor!",
"BOSS_WARN_8 = YERCEKIMI KUYUSU^^nVOID'den uzaga kos!",
"BOSS_WARN2_5 = KAR FIRTINASI^^nTum harita donacak!",
"BOSS_WARN2_6 = ZINCIR SIMSEK^^nGorus hattindan cik!",
"BOSS_WARN2_7 = KULUCKA CAGRISI^^nYavrularini cagiriyor!",
"BOSS_WARN2_8 = TUTULMA^^nIsik oluyor!",
"BOSS_ABIL_5 = BUZ PATLAMASI!^^nOldugun yerde dondun!",
"BOSS_ABIL_6 = YILDIRIM!^^nGokyuzu cevap veriyor!",
"BOSS_ABIL_7 = ASIT HAVUZLARI!^^nYesil alandan uzak dur!",
"BOSS_ABIL_8 = YERCEKIMI KUYUSU!^^nIceri cekiliyorsun!",
"BOSS_ABIL2_5 = KAR FIRTINASI!^^n6 saniye yavas ve donuyorsun!",
"BOSS_ABIL2_6 = ZINCIR SIMSEK!^^nGorunen herkes carpildi!",
"BOSS_ABIL2_7 = KULUCKA!^^nYardimcilar ve zehir!",
"BOSS_ABIL2_8 = TUTULMA!^^nKaranlikta avlaniyor!",
"BOSS_BOARD_HUD = BOSS HASARI - ILK 3",
"BOSSINFO_TITLE = ^^1Bu haritanin bosslari (karisik sirayla gelirler):",
"BOSS_NEXT_IN = ^^1Siradaki boss ^^4%d^^1 round sonra.",
"LM_AIM_INFO = LAZER MAYINI  [ %s ]^^nCan %d / %d",
"LM_AIM_MINE = ^^4[LAZER] ^^1Sokmek icin kendi lazerine yakindan nisan al.",
"LM_BIND_PRINTED = ^^4[LAZER] ^^1Tus komutlari ^^4konsoluna^^1 (~) yazildi.",
"LM_BOSS_BLOCKED = ^^4[LAZER] ^^1Boss roundlarinda lazer mayini ^^3kapali^^1.",
"LM_BOUGHT = ^^4[LAZER] ^^11 lazer mayini alindi ^^4(-%d AP)^^1.",
"LM_DESTROYED = ^^3[LAZER] ^^1Lazer mayinin ^^3%s^^1 tarafindan kirildi!",
"LM_DISABLED = ^^4[LAZER] ^^1Lazer mayini su an kullanilamaz.",
"LM_DISABLED_SHORT = Su an kullanilamaz",
"LM_HINT = ^^4[LASER] ^^4%d^^1 bedava lazer mayinin var! Duvara bak ve ^^4V^^1 tusuna bas. ^^4C^^1 = sok.",
"LM_HINT_HUD = V  =  LAZER KUR      C  =  LAZER SOK",
"LM_INV_FULL = ^^4[LAZER] ^^1Cantan dolu (en fazla 5).",
"LM_LIMIT = ^^4[LAZER] ^^1En fazla ^^4%d^^1 lazer kurabilirsin.",
"LM_MENU = Lazer Mayinlari",
"LM_MENU_SUB = Cantada: %d   |   Kurulu: %d / %d",
"LM_MOVED = ^^4[LAZER] ^^1Iptal - yerinden kipirdadin.",
"LM_TAKING = ^^4[LAZER] ^^1Mayin sokuluyor... ^^3%d ^^1sn boyunca mayina bakmaya devam et.",
"LM_TAKE_CANCEL = ^^4[LAZER] ^^1Sokme iptal edildi.",
"LM_TAKE_AIM = ^^4[LAZER] ^^1Iptal - mayina bakmayi biraktin.",
"LM_TAKE_HURT = ^^4[LAZER] ^^1Iptal - hasar aldin.",
"LM_M_PLANT = Lazer kur  (V)",
"LM_M_TAKE = Lazer sok  (C)",
"LM_M_BUY = Lazer mayini satin al",
"LM_M_BIND = Tus atamasi (konsol)",
"LM_NOT_YOURS = ^^4[LAZER] ^^1Bu lazer baskasina ait.",
"LM_NO_BOSS = ^^4[LAZER] ^^3Boss roundlarinda^^1 lazer kurulamaz!",
"LM_NO_BOSS_SHORT = Boss roundunda kapali",
"LM_NO_MODE = ^^4[LAZER] ^^3%s^^1 roundlarinda lazer mayini kurulamaz!",
"LM_NO_MODE_SHORT = Bu mod roundunda kapali",
"LM_MODE_REMOVED = ^^4[LAZER] ^^3%s^^1 roundu: lazer mayinlarin kaldirildi (bu modda lazer kapali).",
"LM_NO_MINE = ^^4[LASER] ^^1Bu roundki tum lazerlerini kullandin (round basina ^^4%d^^1). Yerini degistirmek icin ^^4C^^1 ile sok.",
"LM_NO_WALL = ^^4[LAZER] ^^1Yakindaki bir duvara veya zemine nisan al.",
"LM_TOO_FAR = ^^4[LAZER] ^^1Cok uzak. Mayini en fazla ^^4%d birim^^1 icindeki yuzeye kurabilirsin; uzaga kurulum engellendi.",
"LM_PLANTED = ^^4[LASER] ^^1Lazer kuruldu! Birazdan aktif olur. ^^4(%d kaldi)",
"LM_TAKEN = ^^4[LAZER] ^^1Lazer sokuldu. ^^4(cantada %d)",
"LM_TEAM_LIMIT = ^^4[LAZER] ^^1Takim siniri (^^4%d^^1) doldu.",
"NMODE_0 = NORMAL",
"NMODE_DESC_0 = ^^4[Normal] ^^1klasik sure ile patlar",
"NMODE_1 = CARPMA",
"NMODE_DESC_1 = ^^4[Carpma] ^^1ilk degdigi yerde patlar",
"NMODE_2 = SENSOR",
"NMODE_DESC_2 = ^^4[Sensor] ^^1yere oturur ve kurulur (bip), sadece zombi menzile VE gorus hattina girince patlar",
"NMODE_3 = LAZER TUZAK",
"NMODE_DESC_3 = ^^4[Lazer Tuzak] ^^1carptigi duvara / zemine yapisir, lazer ceker, lazeri kesen zombinin USTUNDE patlar",
"NMODE_4 = GUDUMLU",
"NMODE_DESC_4 = ^^4[Gudumlu] ^^1en yakin zombiye yonelir (HE / ates)",
"NMODE_5 = PARCALI",
"NMODE_DESC_5 = ^^4[Parcali] ^^1patlayinca 4 kucuk bombaya ayrilir (HE / ates)",
"NMODE_HUD = BOMBA MODU  ::  %s^^n(degistirmek icin sag tik)",
"NMENU_TITLE = Bomba Modlari",
"NMENU_SUB = Bomba elindeyken sag tik da degistirir",
"NMENU_HE = HE / Ates bombasi",
"NMENU_FROST = Buz bombasi",
"NMENU_FLARE = Isaret fisegi",
"NMENU_HELP = Modlar ne ise yarar?",
"AIRDROP_HUD = HAVA IKMALI GELIYOR!^^nALTIN ISIK SUTUNUNU takip et",
"AIRDROP_CHAT = ^^4[IKMAL] ^^1Bir kutu dusuyor! Ilk dokunan ^^4insan^^1 odulu kapar - zombiler kutuyu yok eder!",
"AIRDROP_GOT = ^^4[IKMAL] ^^3%s^^1 kutuyu kapti: ^^4%s",
"AIRDROP_YOU = IKMAL KUTUSU!",
"AIRDROP_ZOMBIE = ^^3[IKMAL] ^^3%s^^1 ikmal kutusunu parcaladi!",
"LOOT_AP = +%d AP",
"LOOT_HP = +60 can ve +100 zirh",
"LOOT_NADES = bomba paketi (ates + buz + fisek)",
"LOOT_MINE = +1 lazer mayini",
"LOOT_CLIP = sinirsiz sarjor (bu hayat)",
"LOOT_DMG = +%%30 hasar (bu hayat)",
"LOOT_VC = +3 Vex Coin",
"QUEST_0 = %d zombi oldur",
"QSHORT_0 = Zombi oldur",
"QUEST_1 = %d zombi oldur",
"QSHORT_1 = Zombi oldur",
"QUEST_2 = Zombilere %d hasar ver",
"QSHORT_2 = Hasar",
"QUEST_3 = Zombilere %d hasar ver",
"QSHORT_3 = Hasar",
"QUEST_4 = %d headshot ile oldur",
"QSHORT_4 = Headshot",
"QUEST_5 = %d insan enfekte et",
"QSHORT_5 = Enfeksiyon",
"QUEST_6 = %d insan enfekte et",
"QSHORT_6 = Enfeksiyon",
"QUEST_7 = Roundu insan olarak kazan",
"QSHORT_7 = Roundu kazan",
"QUEST_NEW = ^^4[GOREV] ^^1%s ^^4(+%d XP  +%d AP)",
"QUEST_LINE = Gorev : %s  [%d / %d]",
"QUEST_LINE_DONE = Gorev : TAMAMLANDI",
"QUEST_DONE_HUD = GOREV TAMAMLANDI!^^nOdul hesabina eklendi",
"QUEST_DONE_ALL = ^^4[GOREV] ^^3%s^^1 round gorevini tamamladi!",
"QUEST_NONE = ^^4[GOREV] ^^1Bu round gorevin yok.",
"QUEST_INFO = ^^4[GOREV] ^^1%s  ^^4%d / %d^^1   odul: ^^4+%d XP  +%d AP",
"QUEST_INFO_DONE = ^^4[GOREV] ^^1%s ^^4- TAMAMLANDI",
"EVOLVE_CHAT = ^^3%s^^1 evrimlesti: ^^3ALFA ZOMBI^^1! (+%%50 can, daha hizli, daha sert)",
"EVOLVE_HUD = EVRIMLESTIN: ALFA ZOMBI^^n+%%50 can   |   daha hizli   |   daha sert",
"MAIN_21 = Kozmetik (Vex Coin)",
"MAIN_22 = Liderler (Ilk 10)",
"HUD_P1R = LV.%d   //   %s   //   TOP #%d",
"COS_MENU = Kozmetik",
"COS_SUB = Vex Coin ile kalici gorunumler",
"COS_CAT_TRAIL = Izler",
"COS_CAT_KFX = Oldurme efektleri",
"COS_CAT_IFX = Enfeksiyon efektleri (zombi)",
"COS_NONE = Yok",
"COS_EQUIPPED = TAKILI",
"COS_OWNED = sende var",
"COS_OFF = ^^4[KOZMETIK] ^^1Cikarildi.",
"COS_NOVC = ^^4[KOZMETIK] ^^1Vex Coin yetmiyor ^^4(%d VC gerekli)^^1. VC: level, gunluk odul ve MVP ile kazanilir.",
"COS_BOUGHT = ^^4[KOZMETIK] ^^4%s^^1 satin alindi ^^4(-%d VC)^^1. Artik sonsuza kadar senin!",
"COS_BOUGHT_ALL = ^^4[KOZMETIK] ^^3%s^^1, ^^4%s^^1 kozmetigini acti!",
"COS_EQUIP = ^^4[KOZMETIK] ^^4%s^^1 takildi.",
"COS_PREV_START = ^^4[KOZMETIK] ^^1Vitrin: ^^4%s^^1 ^^4%d^^1 saniye onunde donuyor (sadece sen goruyorsun).",
"COS_YOUR_VC = VC'n",
"COS_BUY_ITEM = Satin al ve tak",
"COS_PREV_ITEM = Onumde goster (vitrin)",
"COS_SEC = sn",
"COS_BACK = Geri",
"COS_HIDE_OTHERS = Diger oyuncularin kanat / pet / sapkasi",
"COS_HIDDEN = gizli",
"COS_VISIBLE = acik",
"COS_HIDE_ON = ^^4[KOZMETIK] ^^1Diger oyuncularin kanat, pet ve sapkalari artik ^^4gizli^^1 (daha fazla FPS).",
"COS_HIDE_OFF = ^^4[KOZMETIK] ^^1Diger oyuncularin kanat, pet ve sapkalari tekrar ^^4gorunur^^1.",
"COS_TRAIL_0 = Buz Izi",
"COS_TRAIL_1 = Toksik Iz",
"COS_TRAIL_2 = Kan Izi",
"COS_TRAIL_3 = Kraliyet Izi",
"COS_TRAIL_4 = Altin Iz",
"COS_TRAIL_5 = Gokkusagi Izi",
"COS_KFX_0 = Yildirim Carpmasi",
"COS_KFX_1 = Altin Patlama",
"COS_KFX_2 = Kan Cesmesi",
"COS_KFX_3 = Buz Kirilmasi",
"COS_KFX_4 = Bosluk Cokusu",
"COS_KFX_5 = Havai Fisek",
"COS_IFX_0 = Zehir Patlamasi",
"COS_IFX_1 = Golge",
"COS_IFX_2 = Kan Ayi",
"TOP10_TITLE = LIDERLER",
"TOP10_NAME = Oyuncu",
"TOP10_KILLS = Oldurme",
"TOP10_INF = Enfeksiyon",
"TOP10_YOU = Tum zamanlar siran: #%d",
"TOP10_NEED = Ilk 15'e girmek icin %d XP daha lazim.",
"TOP10_OPEN = Ilk 15'te hala yer var - oynamaya devam!",
"TOP_JOIN = ^^4[TOP] ^^1Sunucunun ^^4#%d^^1 numarali oyuncusu ^^3%s^^1 aramizda!",
"CARD_JOB = Meslek",
"CARD_KILLS = Oldurme",
"CARD_INF = Enfeksiyon",
"CARD_WINS = Galibiyet",
"CARD_BOSS = Boss",
"CARD_ACH = Basarim",
"CARD_TIME = Oyun suresi",
"CARD_DAILY = Gunluk seri",
"CARD_MAPKILLS = Bu harita",
"SPEC_INFO = IZLENEN  ::  %s^^nLV.%d   ::   %s   ::   CAN %d   ::   ZIRH %d   ::   AP %d",
"ADV_21 = ^^4Vex Coin^^1'lerini kalici ^^4iz ve oldurme efektlerine^^1 harca: ^^4/kozmetik",
"ADV_22 = ^^1Sunucu ^^4liderleri^^1 arasinda misin? ^^4/siralama^^1 yaz.",
"JOB_NEXT = ^^1Yeni meslegin ^^4bir sonraki dogusunda^^1 aktif olur.",
"GUNS_ONCE = ^^1Bu hayatta silahini zaten aldin. Yeni secimin sonraki roundda gecerli.",
"NO_SUICIDE = ^^1Ozel karakterler ^^3kill^^1 kullanamaz. Sonuna kadar savas!",
"",
"BSK_0_1 = SISMIK EZME",
"BSKT_0_1 = Etrafindaki herkes havaya ucuyor!",
"BSK_0_2 = YER YARIGI",
"BSKT_0_2 = Patlamalar sana dogru ilerliyor - yana kac!",
"BSK_0_3 = TITAN OFKESI",
"BSKT_0_3 = 6 saniyelik ofke - kac, yakin dovusme!",
"BSK_1_1 = SES MIZRAGI",
"BSKT_1_1 = Onundeki herkese ses dalgasi - gorus alanindan cik!",
"BSK_1_2 = HAYALET CIGLIGI",
"BSKT_1_2 = Birinin ARKASINDA belirip ciglik atiyor!",
"BSK_1_3 = AGIT",
"BSKT_1_3 = 5 feryat dalgasi - tum harita kanar!",
"BSK_2_1 = KEMIK HAPSI",
"BSKT_2_1 = Biri kemik kafese kilitlendi!",
"BSK_2_2 = LEJYON",
"BSKT_2_2 = Dusenler diriliyor, canin emiliyor!",
"BSK_2_3 = OLUM NOVASI",
"BSKT_2_3 = 3 olum halkasi yayiliyor - aralarinda kal!",
"BSK_3_1 = ALEV NEFESI",
"BSKT_3_1 = Onune ates puskurtuyor - yanindan dolas!",
"BSK_3_2 = ATES SUTUNLARI",
"BSKT_3_2 = Ayaginin altindan ates fiskiriyor - KIPIRDA!",
"BSK_3_3 = SUPERNOVA",
"BSKT_3_3 = Dev bir patlama hazirliyor - COK UZAGA KAC!",
"BSK_4_1 = GOLGE ADIMI",
"BSKT_4_1 = Kayboldu... sonraki vurusu CIFT hasar!",
"BSK_4_2 = RUH ZINCIRLERI",
"BSKT_4_2 = Zincirlendin! Kopartmak icin uzaklas!",
"BSK_4_3 = OLUM ISARETI",
"BSKT_4_3 = Herkes isaretlendi - HEMEN yerinden ayril!",
"BSK_5_1 = BUZ PARCALARI",
"BSKT_5_1 = Yelpaze seklinde buz mizraklari - siper al!",
"BSK_5_2 = BUZ MEZARI",
"BSKT_5_2 = Biri buz kesti!",
"BSK_5_3 = MUTLAK SIFIR",
"BSKT_5_3 = Durma, durursan donarsin!",
"BSK_6_1 = TOP YILDIRIM",
"BSKT_6_1 = Bir yildirim topu suzuluyor - uzak dur!",
"BSK_6_2 = YILDIRIM ATILMASI",
"BSKT_6_2 = Yildirim gibi atiliyor!",
"BSK_6_3 = KASIRGA",
"BSKT_6_3 = Yildirim isaretli halkalara dusuyor!",
"BSK_7_1 = ASIT TUKURUGU",
"BSKT_7_1 = Asit geliyor - yesil havuzlardan uzak dur!",
"BSK_7_2 = ZEHIR BULUTU",
"BSKT_7_2 = Etrafi zehirli bulut - mesafeni koru!",
"BSK_7_3 = KULUCKA",
"BSKT_7_3 = Yumurtalari catlamadan vur!",
"BSK_8_1 = BOSLUK OKU",
"BSKT_8_1 = Bosluk oku kurbanini kendine ceker!",
"BSK_8_2 = TEKILLIK",
"BSKT_8_2 = Kara delik acildi - halkadan disari kos!",
"BSK_8_3 = OLAY UFKU",
"BSKT_8_3 = Karanlik coktu, her sey icine cekiliyor!",
"ADMM_10 = Event oylamasi baslat",
"ADMM_11 = Roundu yeniden baslat",
"ADMM_12 = Roundu bitir: INSANLAR kazansin",
"ADMM_13 = Roundu bitir: ZOMBILER kazansin",
"ADMM_14 = Hemen hava ikmali indir",
"ADMM_15 = Tum insanlara bomba + lazer ver",
"ADMM_16 = Herkese 50 AP ver",
"ADMM_17 = Zombi geri donusu",
"ADMM_18 = Lazer mayinlari",
"ADMM_19 = vexmira.cfg dosyasini yenile",
"ADME_0 = Sifirla (roundun varsayilani)",
"ADME_1 = Acik gunduz",
"ADME_2 = Alacakaranlik",
"ADME_3 = Gece",
"ADME_4 = Yagmur",
"ADME_5 = Kar",
"ADME_6 = Yogun sis",
"ADME_7 = Firtina",
"ADME_8 = Kan kirmizi",
"ADME_9 = Zifiri karanlik",
"ADME_CUSTOM = Detayli ambiyans ayarlari",
"ADME_DETAIL = Detayli ambiyans ayarlari",
"ADME_LIGHT = Dunya parlakligi (a-z)",
"ADME_FOG_DENSITY = Sis yogunlugu (0-80)",
"ADME_FOG_RED = Sis kirmizi",
"ADME_FOG_GREEN = Sis yesil",
"ADME_FOG_BLUE = Sis mavi",
"ADME_WEATHER = Hava (0 acik, 1 yagmur, 2 kar)",
"ADME_MAP_AMBIENCE = Harita ortam donguleri",
"ADME_ENV_RESET = Round ambiyansina don",
"ADM_ENV_RESET = ^^4%s^^1 roundun otomatik ambiyansini geri yukledi.",
"ADMA_13 = Assassin yap",
"ADMA_14 = Sniper yap",
"ADMA_15 = +3 lazer mayini ver",
"ADMA_16 = Tum bombalari ver",
"ADMA_17 = 5 sn dondur",
"ADM_AIRDROP = ^^4%s^^1 bir ^^4hava ikmali^^1 indirdi!",
"ADM_END_HUMANS = ^^4%s^^1 roundu bitirdi: ^^4INSANLAR KAZANDI^^1.",
"ADM_END_ZOMBIES = ^^4%s^^1 roundu bitirdi: ^^3ZOMBILER KAZANDI^^1.",
"ADM_ENV_SET = ^^4%s^^1 hava durumunu / isigi degistirdi (^^4#%d^^1).",
"ADM_GAVE_NADES = ^^4%s^^1 tum insanlara ^^4butun bombalari + lazerleri^^1 verdi!",
"ADM_LASER_ON = ^^4%s^^1 lazer mayinlarini ^^4ACTI^^1.",
"ADM_LASER_OFF = ^^4%s^^1 lazer mayinlarini ^^3KAPATTI^^1.",
"ADM_NEXT_BOSS = ^^4%s^^1 sonraki roundu ^^3BOSS^^1 yapti (^^4#%d^^1, -1 = rastgele).",
"ADM_NOW_BOSS = ^^4%s^^1 simdi bir ^^3BOSS^^1 cagiriyor (^^4#%d^^1)!",
"ADM_NOW_EVENT = ^^4%s^^1 ^^4#%d^^1 numarali eventi simdi baslatiyor!",
"ADM_NOT_ACTIVE = ^^1Su an aktif bir round yok.",
"ADM_RELOADED = ^^4%s^^1 ^^4vexmira.cfg^^1 dosyasini yeniledi (^^4%d^^1 satir).",
"AFK_WARN = ^^3[AFK] ^^1Kipirda! ^^4%d^^1 saniye icinde izleyiciye alinacaksin.",
"AFK_MOVED = ^^3[AFK] ^^3%s^^1 izleyiciye alindi (AFK).",
"AFK_KICKED = ^^3[AFK] ^^3%s^^1 sunucudan atildi (AFK).",
"NEM_RAGE_YOU = OFKE!^^nBirkac saniye daha hizli ve dayanikli",
"NEM_RAGE_ALL = ^^3NEMESIS %s^^1 ^^3OFKELENDI^^1! Uzak durun!",
"ASN_VEIL_YOU = GOLGE PERDESI!^^nNeredeyse gorunmezsin",
"ROLE_BOSS_KEYS = ^^4[BOSS] ^^1Tuslar: ^^4[R]^^1 = faz yetenegi (her fazda yenisi gelir), ^^4[F]^^1 / ^^4[G]^^1 = atilma. Her fazda saldirilarin guclenir!",
"BSK_BUSY = Zaten bir yetenek aktif!",
"BSK_NO_TARGET = Menzilde hedef yok!",
"BSK_FIRST_SKILL = ^^1Ilk ^^4[R]^^1 yetenegin: ^^3%s^^1. Can ^^4%%60^^1 ve ^^4%%30^^1 olunca yeni yetenekler acilir!",
"BSK_UNLOCK_ALL = ^^3%s^^1 yeni bir yetenek ogrendi: ^^3%s^^1 (faz ^^4%d^^1)!",
"BSK_UNLOCK_YOU = YENI [R] YETENEGI!^^n%s",
"BSK_PRISON_YOU = KEMIK HAPSI! Kafese kilitlendin!",
"BSK_EMPOWER = Sonraki vurusun CIFT hasar!",
"BSK_CHAINED = RUH ZINCIRI! Kopartmak icin uzaklas!",
"BSK_CHAIN_BROKEN = ^^3Ruh zincirini^^1 kopardin!",
"BSK_MARKED = OLUM ISARETI! Yerinden hemen ayril!",
"BSK_TOMB_YOU = BUZ MEZARI! Dondun!",
"BSK_ZERO_TIP = MUTLAK SIFIR! Durma, durursan donarsin!",
"BSK_EGGS_TIP = YUMURTALAR! Catlamadan vurun!",
"BSK_PULLED = BOSLUK OKU! Icine cekiliyorsun!",
"HUD_ACTIVE = AKTIF",
"HUD_READY = HAZIR",
"HUD_SECONDS = %d sn",
"HUD_BOSS_R = [R] %s  %s   ::   [F/G] ATILMA  %s",
"HUD_NEM_RF = [R] ATILMA  %s   ::   [F/G] OFKE  %s",
"HUD_ASN_RF = [R] ATILMA  %s   ::   [F/G] GOLGE PERDESI  %s",
"HUD_DROP_COMPASS = IKMAL KUTUSU  %d m  %s",
"LM_AIM_INFO_MINE = SENIN LAZERIN  [ %s ]^^nCAN %d / %d     C = sok",
"LM_GIFT = ^^4[LASER] ^^4+%d^^1 lazer mayini aldin!",
"LM_INFO_1 = ^^4[LASER] ^^1Her round her insana ^^4%d^^1 lazer mayini BEDAVA verilir (AP yok).",
"LM_INFO_2 = ^^4[LASER] ^^4V^^1 = baktigin duvara kur.  ^^4C^^1 = aninda sok (cantana geri doner).",
"LM_INFO_3 = ^^4[LASER] ^^1Isina degen zombi ^^3aninda olur^^1. Zombiler pencesiyle mayini kirabilir.",
"LM_M_INFO = Nasil calisir",
"LM_M_RULE = Her round %d lazer bedava - AP gerekmez",
"LM_WORN_OUT = ^^3[LASER] ^^1Lazerlerinden biri cok oldurmekten yandi.",
"ADV_23 = ^^1Bosslar her fazda YENI bir ^^4[R]^^1 yetenegi ogrenir. Yerdeki renkli halkalara hep dikkat et!",
"ADV_24 = ^^1Her round her insana ^^4tum bombalar^^1 otomatik verilir. Sag tik = bomba modu!",
"ADV_25 = ^^3Nemesis^^1 ve ^^3Assassin^^1 TEK VURUSTA oldurur. Mesafeni koru, lazer kullan!",
"ADV_26 = ^^1Her event ^^4hava durumunu ve isigi^^1 degistirir: yagmur, kar, kanli ay, sis...",
"CLASS_12 = Kasap",
"CLASS_DESC_12 = Dayanikli. [R] et kancasi insani sana ceker",
"CLASS_13 = Avci",
"CLASS_DESC_13 = Cevik. [R] atilma, inince sersemletir",
"CLASS_14 = Boga",
"CLASS_DESC_14 = Agir. [R] hucum, insanlari savurur",
"CLASS_15 = Orumcek",
"CLASS_DESC_15 = Hafif. [R] ag atisi: kok + yavaslama",
"CLASS_16 = Magma",
"CLASS_DESC_16 = Ates islemez. [R] yanan lav izi",
"CLASS_17 = Volt",
"CLASS_DESC_17 = [R] EMP: lazer, fener, gece gorusu soner",
"CLASS_18 = Taklitci",
"CLASS_DESC_18 = [R] insan kiligi, ilk vurus x2",
"CLASS_19 = Kostebek",
"CLASS_DESC_19 = [R] yeraltina dalar, cikista firlatir",
"CLASS_20 = Siren",
"CLASS_DESC_20 = [R] ninni insanlari sana ceker",
"CLASS_21 = Kale",
"CLASS_DESC_21 = Devasa can. [R] tahkim: -%%50 hasar, yansitma",
"CLASS_22 = Spor Ana",
"CLASS_DESC_22 = [R] spor kesesi diker (zehirli tuzak)",
"CLASS_23 = Kabus",
"CLASS_DESC_23 = [R] dehset: insanlari kor eder, hizlanirsin",
"SKILL_ONLY_ZOMBIE = Yetenekleri sadece canli zombiler kullanabilir",
"SKILL_ROUND_OVER = Round bitti - yetenekler kapali",
"SKILL_MINION = Yardimci zombilerin yetenegi yok",
"SKILL_STUNNED = Sersemledin! (%d sn)",
"SKILL_NEED_GROUND = Yerde olmalisin!",
"SKILL_BOSS_INTRO = Boss uyaniyor... yetenekler %d sn sonra",
"SKILL_BURROWED = Yeraltindasin!",
"SKILL_NO_SPACE = Burada buna yer yok!",
"SKILL_HOOK_BUSY = Kancan zaten havada!",
"SKILL_NO_TARGET = Menzilde insan yok!",
"LIGHTS_BLOCKED = EMP! Isiklarin %d sn kapali",
"HOOK_THROW_YOU = ET KANCASI!",
"HOOK_GOT_YOU = YAKALANDI: %s!^^nCek onu",
"HOOK_PULLED = %s seni KANCALADI!^^nSurukleniyorsun",
"HOOK_IMMUNE = Kanca kaydi - bu hedef cekilemez!",
"HOOK_MISS_YOU = Kanca iskaladi",
"HUNTER_POUNCE_YOU = ATILMA!",
"HUNTER_STUNNED = %s USTUNE ATLADI!^^nSersemledin",
"HUNTER_HIT_YOU = Yere serildi: %s",
"CHARGER_YOU = HUCUM!",
"CHARGER_HIT = %s seni EZDI!",
"CHARGER_CRASH = Duvara carptin!",
"ARACHNE_YOU = AG ATISI!",
"ARACHNE_WEBBED = %s seni AGA DUSURDU!^^nKipirdayamiyorsun",
"ARACHNE_HIT_YOU = Aga dustu: %s",
"MAGMA_YOU = LAV IZI!^^nAdimlarin zemini tutusturuyor",
"MAGMA_IMMUNE = Magma zombisine ates islemez!",
"VOLT_YOU = EMP PATLAMASI!^^n%d lazer mayini kapandi",
"VOLT_EMP_HIT = %s EMP patlatti!^^nLazer, fener ve gece gorusu kapali",
"MIMIC_YOU = KILIK!^^nInsan gibi gorunuyorsun - ilk vurusun x2",
"MIMIC_REVEALED = O BIR TAKLITCIYDI: %s!",
"MIMIC_STRIKE_YOU = PUSU! Kilik dustu",
"MIMIC_END_YOU = Kiligin bozuldu",
"BURROW_YOU = YERALTI!^^nGorunmez ve dokunulmazsin",
"BURROW_HIT = %s YERDEN FIRLADI!",
"SIREN_YOU = NINNI!^^n%d insan buyulendi",
"SIREN_LURED = %s sarki soyluyor...^^nOna dogru cekiliyorsun",
"BULWARK_YOU = TAHKIM!^^nGeri tepme yok, -%%50 hasar, yansitma",
"SPORE_YOU = SPOR KESESI dikildi (%d)",
"SPORE_HIT = %s sporlari!^^nZehirlendin ve yavasladin",
"SPORE_BURST_YOU = Spor kesesi patladi: %d insan zehirlendi",
"SPORE_DESTROYED = ^^3[SPOR] ^^1Spor keseni ^^3%s^^1 patlatti.",
"NIGHTMARE_YOU = DEHSET!^^n%d insan kor oldu - saldir!",
"NIGHTMARE_HIT = KABUS %s!^^nKaranlik cokuyor",
"SKILL_KEYS_HINT = ^^4[TUSLAR] ^^1^^4[F]^^1 calismazsa ^^4[G]^^1 tusuna bas, ^^4/beceri2^^1 yaz ya da konsola: ^^4bind f vex_skill2^^1 (R: ^^4vex_skill^^1).",
"HUD_CLASS_ACT = %s   ::   [R/G]  AKTIF  %d sn",
"BOSS_PH_3 = FAZ   I   II   [ III ]",
"PLAN_5 = ^^1Bu haritada yuklu bosslar: ^^3%s",
"MAPV_START = ^^3%s^^1 ^^4sonraki harita oylamasini^^1 baslatti! ^^4%d^^1 saniyen var - haritanin numarasina bas.",
"MAPV_START_HUD = HARITA OYLAMASI^^nMenuden sonraki haritayi sec",
"MAPV_TITLE = Sonraki Harita Oylamasi",
"MAPV_LEFT = Bitmesine \r%d sn\y  |  oy: \r%d",
"MAPV_EXTEND = Bu haritayi uzat (+%d round)",
"MAPV_STAY = Bu haritada kal",
"MAPV_NOTE = Oyunu degistirebilirsin. Esitlik = rastgele. Botlar oy vermez.",
"MAPV_CAST = ^^3%s^^1 oyunu ^^4%s^^1 icin kullandi",
"MAPV_RECAST = ^^3%s^^1 oyunu ^^4%s^^1 olarak degistirdi",
"MAPV_RESULT = ^^1Sonraki harita: ^^4%s^^1, ^^4%d^^1 oyla (^^4%%%d^^1).",
"MAPV_RESULT_HUD = SONRAKI HARITA^^n%s",
"MAPV_NOVOTES = ^^1Kimse oy vermedi - sonraki harita rastgele secildi: ^^4%s",
"MAPV_EXTENDED = ^^1Harita ^^4%d round uzatildi^^1! Yeni son roundan once tekrar oylanacak.",
"MAPV_EXTENDED_HUD = HARITA UZATILDI^^n+%d round",
"MAPV_STAYED = ^^1Oylama sonucu ^^4bu haritada kaliyoruz^^1 (^^4%d^^1 oy).",
"MAPV_STAYED_HUD = BU HARITADA KALIYORUZ",
"MAPV_NONE = ^^1Havuzdaki diger haritalar bu sunucuda yuklu degil, oylanacak harita yok.",
"MAPV_ONLY = ^^1Tek uygun harita var, sonraki harita o: ^^4%s",
"MAPV_ROUNDEND = ^^1Bu round bitince harita ^^4%s^^1 olacak.",
"MAPV_CHANGING = ^^1Harita ^^4%s^^1 olarak degisiyor ...",
"MAPV_CHANGING_HUD = SONRAKI HARITA: %s^^nOrada gorusuruz!",
"MAPV_NEXT_IS = ^^1Sonraki harita: ^^4%s^^1 (son roundan sonra).",
"MAPV_NEXT_NOW = ^^1Sonraki harita: ^^4%s^^1 (bu round bitince).",
"MAPV_NEXT_VOTE = ^^1Sonraki harita ^^4%d^^1. roundda oylamayla secilir (toplam ^^4%d^^1). Liste icin ^^4/haritalar^^1 yaz.",
"MAPV_NEXT_CYCLE = ^^1Sonraki harita: ^^4%s",
"MAPV_LIST_HDR = ^^1Harita havuzu (bu haritada ^^4%d^^1 round kaldi):",
"MAPV_LIST_KEY = ^^3*^^1 = su anki harita, ^^4>^^1 = sonraki harita, ^^1(-) = sunucuda yok. Harita degisimi icin ^^4/rtv^^1 yaz.",
"RTV_OFF = ^^1Bu sunucuda harita degistirme oylamasi (RTV) kapali.",
"RTV_CHANGING = ^^1Harita zaten ^^4%s^^1 olarak degisiyor.",
"RTV_DECIDED = ^^1Sonraki harita zaten belli: ^^4%s^^1. Son roundan sonra gelecek.",
"RTV_TOO_EARLY = ^^1RTV ^^4%d^^1. roundda acilir.",
"RTV_MINPL = ^^1RTV icin en az ^^4%d^^1 oyuncu gerekli.",
"RTV_ALREADY = ^^1Zaten RTV yazdin (^^4%d^^1/^^4%d^^1).",
"RTV_ROCKED = ^^3%s^^1 haritayi degistirmek istiyor! ^^4%d^^1/^^4%d^^1 - katilmak icin ^^4rtv^^1 yaz.",
"RTV_START = ^^1Yeterli oyuncu RTV yazdi - ^^4harita oylamasi^^1 basliyor!",
"MAP_OBJ_LINE_CUR = ^^4[>>] ^^1(%d/%d) ^^4%s",
"MAP_OBJ_LINE_LOCK = ^^3[--] ^^1(%d/%d) %s ^^3(kilitli)",
"MAP_OBJ_CUR_MK = Mavi isareti takip et: %s",
"MAP_OBJ_HEAD = ^^4%s^^1 - gorevler:",
"MAP_OBJ_LINE_OPEN = ^^3[  ]^^1 %s",
"MAP_OBJ_LINE_MK = ^^3[  ]^^1 %s ^^3- mavi isareti takip et: ^^4%s",
"MAP_OBJ_LINE_DONE = ^^4[OK] %s",
"MAP_OBJ_CUR = GOREV %d/%d: %s",
"MAP_OBJ_DONE_HUD = GOREV TAMAMLANDI^^n%s",
"MAP_OBJ_ALL = TUM GOREVLER TAMAMLANDI^^n%s",
"MAP_REWARD_H = ^^1Harita odulu: hayatta kalan her insana ^^4+%d AP^^1!",
"MAP_REWARD_Z = ^^1Harita odulu: avdaki her zombiye ^^4+%d AP^^1!",
"MAP_NO_STORY = ^^1Bu haritanin hikaye dosyasi yok.",
"ADMM_20 = Harita oylamasi (kazanan bu round sonunda gelir)",
"ADM_MAPVOTE = ^^4%s^^1 ^^4harita oylamasi^^1 baslatti (^^4%d^^1 secenek).",
"ADM_MAPVOTE_CANCEL = ^^4%s^^1 harita oylamasini iptal etti.",
"MAPDESC_zm_vex_laboratory = (biyo laboratuvar)",
"MAPDESC_zm_vex_harbor = (gece limani)",
"MAPDESC_zm_vex_ruins = (yikik sehir)",
"MAPDESC_zm_vex_frostbase = (karli us)",
"MAPDESC_zm_vex_temple = (boss tapinagi)",
"",
"MAINH_1 = Market (Esya, Ozel Silah)",
"MAINH_2 = Silahlar / Techizat",
"MAINH_3 = Zombi Sinifi / Insan Meslegi",
"MAINH_4 = Karakter (Istatistik, Yetenek, Gorev, Top)",
"MAINH_5 = Oduller & Eglence",
"MAINH_6 = Kozmetik",
"MAINH_7 = Ayarlar (Dil, HUD, FPS)",
"MAINH_8 = VIP",
"MAINH_8A = VIP / Admin",
"HUB_1 = Market",
"HUB_2 = Sinif & Meslek",
"HUB_3 = Karakter",
"HUB_4 = Oduller & Eglence",
"HUB_5 = VIP / Admin",
"HUB_BACK = << Ana menu",
"VIPI_TITLE = VIP / ELITE ayricaliklari",
"VIPI_1 = Ekstra ziplama: VIP cift, ELITE uclu",
"VIPI_2 = +yuzde %d / %d AP ve XP",
"VIPI_3 = Esya, silah, kozmetik yuzde %d / %d ucuz",
"VIPI_4 = Her round bedava paket (/vip): zirh + bombalar",
"VIPI_4A = Her dogusta bedava paket: zirh + bombalar",
"VIPI_5 = +%d / +%d dogus zirhi, round basina %d lazer",
"VIPI_6 = Her round sonu +%d / +%d Vex Coin",
"VIPI_7 = Gunluk odul +yuzde %d / %d",
"VIPI_8 = Aura, isik izi, VIP modeli, sohbet etiketi",
"VIPI_BUY = VIP almak icin: %s",
"TIP_1 = ^^4[IPUCU] ^^4M^^1 = menu: market, silah, sinif, ayarlar.",
"TIP_2 = ^^4[IPUCU] ^^1Zombiye her ^^4800^^1 hasar = ^^4+1 AP^^1. Yeni silahin icin AP biriktir.",
"TIP_3 = ^^4[IPUCU] ^^1Lazer: ^^4V^^1 = kur, ^^4C^^1 basili tut = sok. Her round yenisi verilir.",
"TIP_4 = ^^4[IPUCU] ^^1Elinde bomba varken sag tik: ^^4carpma, sensor, lazer tuzak, gudumlu, parca^^1.",
"TIP_5 = ^^4[IPUCU] ^^4Gunluk odulun^^1 hazir: ^^4/gunluk^^1. Seri yaptikca artar.",
"TIP_6 = ^^4[IPUCU] ^^4Vex Coin^^1 ile kalici yetenek al: ^^4/yetenek",
"TIP_7 = ^^4[IPUCU] ^^1Meslekler insanlara rol verir, level atladikca acilir: ^^4/meslek",
"TIP_8 = ^^4[IPUCU] ^^1JANUS, Plasma, Thunderbolt, Ethereal, Salamander ve Bow: ^^4/ozel",
"TIP_9 = ^^4[IPUCU] ^^1Zombiler: bir roundda ^^43^^1 insan enfekte et, ^^3ALFA^^1 ol.",
"TIP_10 = ^^4[IPUCU] ^^3Nemesis^^1 ve ^^3Assassin^^1 tek vurusta oldurur. Mesafe koru, lazer kullan.",
"TIP_11 = ^^4[IPUCU] ^^1Bosslar her fazda yeni yetenek ogrenir. Yerdeki renkli halkalara dikkat!",
"TIP_12 = ^^4[IPUCU] ^^1Gokte ^^4altin isin^^1 = ikmal. HUD okunu takip et.",
"TIP_13 = ^^4[IPUCU] ^^1Duvara mi takildin? ^^4/takildim",
"TIP_14 = ^^4[IPUCU] ^^1FPS dusuk mu? ^^4/fps^^1 performans ayarlari.",
"TIP_15 = ^^4[IPUCU] ^^1For English type ^^4/lang^^1. Dil: ^^4/dil",
"TIP_16 = ^^4[IPUCU] ^^1Her harita ^^430 round^^1: boss savaslari ve ^^3FINAL BOSS^^1: ^^4/round",
"TIP_17 = ^^4[IPUCU] ^^1Her roundun AP ve XP veren bir gorevi var: ^^4/gorev",
"TIP_18 = ^^4[IPUCU] ^^1Kalici koleksiyon: 5 CT modeli, 5 bicak, kanat, pet ve sapka. ^^4/kozmetik",
"MENU_MAIN = Zombi Salgini",
"VIPI_9 = Dogus korumasi +%.1f sn, hizli dogus",
"VIPI_10 = Oy agirligi x%d (mod, event, harita)",
"VIPI_11 = Her hayatta 1 bedava silah degistirme",
"VIPI_12 = VIP'e ozel kanat, pet, sapka, bicak",
"VIPI_13 = Skorda VIP, oldurme rozeti, giris sesi",
"VIPI_14 = Sunucu doluyken oncelikli giris mesaji",
"VIP_PRIORITY = ^^4%s^^1 ^^4VIP onceligi^^1 ile girdi (sunucu dolmak uzere).",
"VIP_REGUN = ^^4VIP:^^1 bu hayattaki bedava silah degistirme hakkin kullanildi.",
"COS_CAT_WING = Kanatlar",
"COS_CAT_PET = Petler",
"COS_CAT_HAT = Sapkalar",
"SW_0 = JANUS VII",
"SW_DESC_0 = x1.15, 30/180 | Sag tik: Darbe isini",
"SW_1 = Plasma Gun",
"SW_DESC_1 = x1.22, 30/180 | Sag tik: Lazer",
"SW_2 = Thunderbolt",
"SW_DESC_2 = x1.24, 32/180 | Sag tik: Gezegen cekirdegi",
"SW_3 = Ethereal",
"SW_DESC_3 = x1.28, 30/180 | Sag tik: Ejder kukremesi",
"SW_4 = Salamander",
"SW_DESC_4 = x1.18, 28/180 | Sag tik: Buz cekirdegi",
"SW_5 = Compound Bow",
"SW_DESC_5 = x1.22, 36/180 | Sag tik: Zincir elektrik",
"VX_ALT_0 = Darbe isini",
"VX_ALT_1 = Lazer",
"VX_ALT_2 = Gezegen cekirdegi",
"VX_ALT_3 = Ejder kukremesi",
"VX_ALT_4 = Buz cekirdegi",
"VX_ALT_5 = Zincir elektrik",
"VX_PRIMARY = Normal atis",
"VX_MODE = Silah modu: %s | Sol tik ile kullan.",
"VX_NOAMMO = Bu yetenek icin sarjorde %d mermi gerekiyor.",
"VX_BUSY = Aktif yetenek siniri dolu; biraz bekle.",
"SHOP_ONLY_HUMAN = ^^1Bunu sadece canli normal insanlar alabilir (zombi / survivor / sniper / boss alamaz).",
"SHOP_NOTINST = ^^1Bu esya su an sunucuda ^^3yuklu degil^^1 (eklentisi calismiyor veya dosyalari eksik). Admin: ^^4vex_diagnose",
"SHOP_HEV_ROUND = ^^1HEV Suit: round basina sadece 1 kez.",
"MENU_NA = YOK",
"ZC_SPECIAL = Ozel Silahlar",
"ZC_JETPACK = Jetpack + Bazuka",
"ZC_HEV = HEV Zirhi",
"ZC_CTSKINS = CT Gorunumleri",
"ZC_KNIVES = Bicak Koleksiyonu",
"ZC_SKINS = Insan Gorunumleri",
"ZC_FX = Iz / Oldurme / Enfeksiyon Efekti",
"ZC_STANDARD = Standart (varsayilan)",
"ZC_EQUIPPED = KUSANILDI",
"ZC_OWNED = SAHIP",
"ZC_FREE = ucretsiz",
"ZC_NEED_SURV = sadece Survivor",
"ZC_GUNS6 = 6 silah",
"ZC_PERM = kalici",
"",
"ZC_ALIVE_HUMAN = ^^1Bunu almak icin hayatta ve normal insan olmalisin. Survivor ve Sniper kendi mod silahlarini kullanir.",
"ZC_HEV_LIMIT = ^^1HEV roundda bir kez alinabilir. Sonraki round yeniden alabilirsin.",
"ZC_MISSING_COLLECTION = ^^1Bu gorunum su an yuklu degil; coin harcanmadi. Yonetici: vex_diagnose"
};
new const ZC_F_MOTD_EN[][] = {
"<html><head><meta charset=^"utf-8^"><style>body{background:#080e19;color:#dce9f8;font:13px Verdana,Arial;margin:0;padding:14px}h1{font-size:28px;color:#52e7ff;margin:0 0 4px;letter-spacing:5px}.tag{color:#b697ff;margin-bottom:12px}.box{background:#101c2d;border:1px solid #31405b;padding:8px 10px;margin:7px 0}b{color:#52e7ff}.small{font-size:11px;color:#9aadca}.gold{color:#ffcb5c}</style></head><body><h1>VEXMIRA</h1><div class=^"tag^">ZOMBIE / CSO / BOSS / TR & EN</div><p>Quarantine has begun. Survive together.</p><div class=^"box^"><b>M</b> main menu &nbsp; <b>/ozel</b> 8 ozel silah &nbsp; <b>/shop</b> Jetpack</div><div class=^"box^"><b>/cosmetic</b>: 5 CT skins, 5 knives, 5 wings, 5 hats, 5 pets. Permanent VC collection.</div><div class=^"box^"><b>F</b> inspect supported weapon &nbsp; <b>R</b> zombie skill &nbsp; <b>Ctrl + Space</b> Jetpack flight &nbsp; <b>Right click</b> rocket</div><div class=^"box^"><b>/lazer</b> mine menu &nbsp; <b>/daily</b> daily reward &nbsp; <b>/fps</b> display options &nbsp; <b>/memes</b> meme audio</div><div class=^"box^"><span class=^"gold^">9 bosses / 27 skills</span>. Avoid colored danger zones. Vote between 3 maps every 30 rounds.</div><p class=^"small^">SmurfSexy &amp; Capital | v4.4.0 | /lang - /dil</p></body></html>"
};
new const ZC_F_MOTD_TR[][] = {
"<html><head><meta charset=^"utf-8^"><style>body{background:#080e19;color:#dce9f8;font:13px Verdana,Arial;margin:0;padding:14px}h1{font-size:28px;color:#52e7ff;margin:0 0 4px;letter-spacing:5px}.tag{color:#b697ff;margin-bottom:12px}.box{background:#101c2d;border:1px solid #31405b;padding:8px 10px;margin:7px 0}b{color:#52e7ff}.small{font-size:11px;color:#9aadca}.gold{color:#ffcb5c}</style></head><body><h1>VEXMIRA</h1><div class=^"tag^">ZOMBIE / CSO / BOSS / TR & EN</div><p>Karantina basladi. Birlikte hayatta kal.</p><div class=^"box^"><b>M</b> ana menu &nbsp; <b>/ozel</b> 8 ozel silah &nbsp; <b>/shop</b> Jetpack</div><div class=^"box^"><b>/kozmetik</b>: 5 CT modeli, 5 bicak, 5 kanat, 5 sapka, 5 pet. VC ile kalici koleksiyon.</div><div class=^"box^"><b>F</b> normal silahi incele &nbsp; <b>R</b> zombi yetenegi &nbsp; <b>Ctrl + Space</b> Jetpack ucus &nbsp; <b>Sag tik</b> fuze</div><div class=^"box^"><b>/lazer</b> mayin menusu &nbsp; <b>/daily</b> gunluk odul &nbsp; <b>/fps</b> goruntu ayarlari &nbsp; <b>/memes</b> meme sesleri</div><div class=^"box^"><span class=^"gold^">9 boss / 27 yetenek</span>. Renkli tehlike halkalarindan kac. Her 30 roundda 3 harita arasinda oylama.</div><p class=^"small^">SmurfSexy &amp; Capital | v4.4.0 | /lang - /dil</p></body></html>"
};
new const ZC_F_MAP_ZM_VEXMIRA_7DOOR[][] = {
"; zm_vexmira_7door - Kordon 7 senaryo dosyasi (latin-1, Turkce harfsiz)",
"[info]",
"name_en = Cordon 7 - Vexmira Harbor Quarantine",
"name_tr = Kordon 7 - Vexmira Liman Karantinasi",
"roundtime = 6",
"",
"[story_en]",
"line = Night 3 of the outbreak. The Vexmira strain rode the last evac train into the harbor.",
"line = The army sealed Cordon 7 and welded Gate 7 shut. Nobody walks out.",
"line = The only way out is by air: a medevac helicopter, if it can find the Customs Tower roof.",
"line = Restore power at the Substation, lower the lift bridge, light the evac beacon.",
"line = The infected are already in the station. Every minute the shelling comes closer.",
"line = Stay together. Stay in the light.",
"",
"[story_tr]",
"line = Salginin 3. gecesi. Vexmira virusu son tahliye treniyle liman bolgesine ulasti.",
"line = Ordu Kordon 7'yi muhurledi ve Kapi 7'yi kaynakla kapatti. Kimse yuruyerek cikamaz.",
"line = Tek cikis hava yolu: Gumruk Kulesi'nin catisini bulabilirse bir tahliye helikopteri.",
"line = Trafo merkezinde elektrigi ver, kaldirma koprusunu indir, tahliye isaretini yak.",
"line = Enfekteliler zaten istasyonda. Bombardiman her dakika yaklasiyor.",
"line = Birlikte kalin. Isikta kalin.",
"",
"[objective_en]",
"line = Restore power: throw BOTH breakers at the Substation (switch house + gantry)",
"line = Lower the lift bridge from the harbor control cabin",
"line = Light the evac beacon on the Customs Tower roof",
"",
"[objective_tr]",
"line = Elektrigi ver: Trafo Merkezindeki IKI salteri da indir (salt binasi + iskele)",
"line = Liman kontrol kabininden kaldirma koprusunu indir",
"line = Gumruk Kulesi catisindaki tahliye isaretini yak",
"",
"[messages]",
"power = District power restored! Street lights are on, the lift bridge has power. | Bolge elektrigi geldi! Sokak lambalari yandi, kopru calisiyor.",
"bridge = Lift bridge lowered - the harbor road to the terminal is open! | Kaldirma koprusu indi - terminale giden liman yolu acik!",
"beacon = Evac beacon lit! Medevac inbound - hold the tower roof! | Tahliye isareti yandi! Helikopter geliyor - kule catisini tutun!",
"heli = Medevac landed on the roof pad - get aboard, lift-off in 15 s! | Helikopter catiya indi - binin, 15 sn sonra kalkiyor!",
"heli_go = Medevac airborne - riders hold on, zombies use the red geysers to jump aboard! | Helikopter havalandi - tutunun, zombiler kirmizi fiskiyelerle atliyor!",
"breach = The evacuation train burst open - the infected are loose in the station! | Tahliye treni patladi - enfekteliler istasyonda serbest!",
"boss = Something huge is crossing Liberation Plaza... | Kurtulus Meydanindan devasa bir sey geciyor...",
"barricade = The infected smashed the tower barricade! | Enfekteliler kule barikatini parcaladi!",
"blackout = Power failure! Emergency lights only. | Elektrik kesildi! Sadece acil durum isiklari.",
"locked_bridge = Locked: restore power at the Substation first! | Kilitli: once Trafo Merkezinde elektrigi ver!",
"locked_beacon = Locked: lower the lift bridge first! | Kilitli: once kaldirma koprusunu indir!",
"brk_half = Breaker 1/2 thrown - now throw the other one (switch house / gantry)! | Salter 1/2 indi - simdi digerini indir (salt binasi / iskele)!",
"",
"[events]",
"freeze_end 1 cd_barrier_up",
"infection 30 cd_r_siren_st_off",
"boss 4 cd_billboard_mm",
"",
"[markers]",
"Substation breakers | Trafo salterleri = -2600 400 64",
"Lift bridge cabin | Kopru kabini = 880 -1712 -64",
"Evac beacon | Tahliye isareti = 1664 -60 640",
"",
"[locks]",
"cd_bridge_btn = 1 locked_bridge",
"cd_beacon_btn = 2 locked_beacon",
"",
"[hints]",
"cd_brk_a = 1 brk_half",
"cd_brk_b = 1 brk_half",
"",
""
};
new const ZC_F_MAP_ZM_VEXMIRA_DUST[][] = {
"; zm_vexmira_dust - sunny desert town camp map, MapBy:SmurfSexy (latin-1, Turkce harfsiz)",
"[info]",
"name_en = Vexmira Dust",
"name_tr = Vexmira Dust (Col Kasabasi)",
"roundtime = 4",
"",
"[story_en]",
"line = Vexmira desert outpost. The infected broke out of the old fort - hold the town!",
"line = Camps: roof, sniper tower, balcony, cellar, arch tunnel. Red DANGER barrels explode!",
"",
"[story_tr]",
"line = Vexmira col karakolu. Enfekteliler eski kaleden kacti - kasabayi tutun!",
"line = Kamplar: cati, keskin nisanci kulesi, balkon, mahzen, tunel. Kirmizi variller patlar!",
"",
"[messages]",
"gate = The fort gate is open - the infected are coming! | Kale kapisi acildi - enfekteliler geliyor!",
"storm = Sandstorm! You can barely see a thing. | Kum firtinasi! Neredeyse hicbir sey gorunmuyor.",
"secret = Secret stash found! +3 ammo packs for every human. | Gizli zula bulundu! Her insana +3 ammo pack.",
"",
"[fx]                 ; sandstorm button: brown fog for 8 s, shake, dust waves across the town",
"sandstorm = fog 0 0 0 55 8 col:196,150,96",
"sandstorm = shake 0 0 64 9000 2 3",
"sandstorm = dust 0 -800 8 400 1.0",
"sandstorm = dust -600 -300 8 380 1.0 t:0.6",
"sandstorm = dust 300 0 8 420 1.0 t:1.2",
"sandstorm = dust -400 600 8 380 1.0 t:1.8",
"sandstorm = dust 700 400 8 380 1.0 t:2.4",
"sandstorm = dust 0 300 8 420 1.0 t:3.0 rep:4 dt:1.2",
"; dust puffs around town (played by [ambience])",
"amb_dust1 = dust 0 -200 8 220 0.6",
"amb_dust2 = dust -700 -900 8 200 0.6",
"amb_dust3 = dust 600 600 8 220 0.6",
"amb_dust4 = dust -500 200 8 200 0.6",
"ev_freeze_end = dust 0 900 8 240 0.8",
"",
"[ambience]           ; <name> = <min s> <max s> <fx key> [fx key ...]",
"dust = 15 40 amb_dust1 amb_dust2 amb_dust3 amb_dust4",
"",
"[models]             ; generated by devtools/mapkit/maps/zm_vexmira_dust.py (PROPS, DECOR, XBARRELS)",
"model = models/vexmira/dust/dust_pickup.mdl 720 -1100 0 90",
"model = models/vexmira/dust/dust_sandbag.mdl 720 -950 0 0",
"model = models/vexmira/dust/dust_wreck.mdl 200 -560 0 0",
"model = models/vexmira/dust/dust_cart.mdl 260 180 0 90",
"model = models/vexmira/dust/dust_stall.mdl -260 -240 0 90",
"model = models/vexmira/dust/dust_stall.mdl 260 -260 0 270",
"model = models/vexmira/dust/dust_stall.mdl -380 120 0 0",
"model = models/vexmira/dust/dust_stall.mdl 520 40 0 180",
"model = models/vexmira/dust/dust_palm.mdl -160 -420 0 0",
"model = models/vexmira/dust/dust_palm.mdl 440 -360 0 90",
"model = models/vexmira/dust/dust_palm.mdl -620 300 0 180",
"model = models/vexmira/dust/dust_palm.mdl 640 700 0 270",
"model = models/vexmira/dust/dust_palm.mdl -880 -1000 0 0",
"model = models/vexmira/dust/dust_palm.mdl 860 -760 0 90",
"model = models/vexmira/dust/dust_tower.mdl 900 -480 0 0",
"model = models/vexmira/dust/dust_barrel.mdl 960 -560 0 0",
"model = models/vexmira/dust/dust_barrel.mdl 992 -540 0 90",
"model = models/vexmira/dust/dust_barrel.mdl -420 -880 0 0",
"model = models/vexmira/dust/dust_barrel.mdl 120 760 0 0",
"model = models/vexmira/dust/dust_barrel.mdl 150 784 0 180",
"model = models/vexmira/dust/dust_sandbag.mdl 928 470 256 0",
"model = models/vexmira/dust/dust_sandbag.mdl -620 670 128 0",
"model = models/vexmira/dust/dust_sandbag.mdl 980 -40 192 90",
"model = models/vexmira/dust/dust_sandbag.mdl -200 -900 0 0",
"model = models/vexmira/dust/dust_sandbag.mdl 200 -900 0 0",
"model = models/vexmira/dust/dust_crate.mdl -1000 -650 0 0",
"model = models/vexmira/dust/dust_crate.mdl -1000 -594 0 0",
"model = models/vexmira/dust/dust_crate.mdl -1000 -622 56 0",
"model = models/vexmira/dust/dust_crate.mdl 560 820 0 0",
"model = models/vexmira/dust/dust_crate.mdl -130 820 0 0",
"model = models/vexmira/dust/dust_dish.mdl 1060 -150 192 180",
"model = models/vexmira/dust/dust_lantern.mdl -660 640 118 0",
"model = models/vexmira/dust/dust_lantern.mdl -560 640 118 0",
"model = models/vexmira/dust/dust_lantern.mdl -460 640 118 0",
"model = models/vexmira/dust/dust_lantern.mdl -400 640 118 0",
"model = models/vexmira/dust/dust_lantern.mdl -40 0 140 0",
"model = models/vexmira/dust/dust_lantern.mdl 40 0 140 0",
"model = models/vexmira/world/cd_flag.mdl 1080 200 192 180 fr:1",
"model = models/vexmira/world/cd_flag.mdl -480 944 296 0 fr:1",
"model = models/vexmira/world/cd_flag.mdl 480 944 296 180 fr:1",
"model = models/vexmira/world/cd_flag.mdl 940 486 256 180 fr:1",
"; explosive barrels: the model follows the func_breakable (hidden when it explodes, back every round)",
"model = models/vexmira/dust/dust_xbarrel.mdl @dust_xb1",
"model = models/vexmira/dust/dust_xbarrel.mdl @dust_xb2",
"model = models/vexmira/dust/dust_xbarrel.mdl @dust_xb3",
"model = models/vexmira/dust/dust_xbarrel.mdl @dust_xb4",
"model = models/vexmira/dust/dust_xbarrel.mdl @dust_xb5",
"model = models/vexmira/dust/dust_xbarrel.mdl @dust_xb6"
};
new const ZC_F_MAP_ZM_VEXMIRA_ICEFY[][] = {
"; zm_vexmira_icefy - classic snowy courtyard camp map, MapBy:SmurfSexy (latin-1, Turkce harfsiz)",
"[info]",
"name_en = Vexmira Icefy",
"name_tr = Vexmira Icefy (Buz)",
"roundtime = 4",
"",
"[story_en]",
"line = Vexmira Arctic Station 7. The storm cut us off - the infected are in the garage.",
"line = Pick a camp: bunker, roof, tower, vent or tunnel. Red DANGER barrels explode - use them!",
"",
"[story_tr]",
"line = Vexmira Kutup Istasyonu 7. Firtina bizi kesti - enfekteliler garajin icinde.",
"line = Kamp sec: bunker, cati, kule, havalandirma, tunel. Kirmizi DANGER variller patlar!",
"",
"[messages]",
"gate = The garage shutter is open - the infected are coming! | Garaj kepengi acildi - enfekteliler geliyor!",
"alarm = Alarm! Someone hit the station klaxon. | Alarm! Biri istasyon sirenine basti.",
"secret = Secret stash found! +3 ammo packs for every human. | Gizli zula bulundu! Her insana +3 ammo pack.",
"fireworks = Fireworks over Station 7! | Istasyon 7 uzerinde havai fisek!",
"",
"[fx]                 ; steam from the roof vent / bunker pipe, snow gusts (played by [ambience])",
"amb_steam1 = smoke 970 40 270 4 8 rep:4 dt:0.8",
"amb_steam2 = smoke -840 -234 100 3 8 rep:3 dt:0.8",
"amb_gust1 = dust 0 200 8 260 0.6",
"amb_gust2 = dust -400 -700 8 220 0.6",
"amb_gust3 = dust 500 600 8 240 0.6",
"ev_freeze_end = dust 0 1000 8 200 0.8",
"alarm = light 912 -360 120 40 6 30 col:255,40,30",
"; fireworks button (south wall): bursts over the yard",
"fireworks = flare -300 0 520 2.5 40 1.2 col:255,60,200",
"fireworks = flare 300 200 540 2.5 40 1.2 col:60,220,255 t:0.6",
"fireworks = flare 0 -300 500 2.5 40 1.2 col:255,220,60 t:1.2",
"fireworks = flare -100 400 560 2.5 40 1.2 col:120,255,90 t:1.8",
"fireworks = flare 250 -150 520 2.5 40 1.2 col:180,90,255 t:2.4",
"fireworks = sparks -300 0 520 6 t:0.1",
"fireworks = sparks 300 200 540 6 t:0.7",
"fireworks = sparks 0 -300 500 6 t:1.3",
"fireworks = sparks -100 400 560 6 t:1.9",
"fireworks = light 0 0 500 255 0.5 40 col:255,200,255 t:0.1 rep:5 dt:0.6",
"; MapBy sign: a little spark now and then",
"amb_mbspark = sparks 180 -1300 290 2",
"",
"[ambience]           ; <name> = <min s> <max s> <fx key> [fx key ...]",
"steam = 20 45 amb_steam1 amb_steam2",
"gusts = 25 60 amb_gust1 amb_gust2 amb_gust3",
"mapby = 8 20 amb_mbspark",
"",
"[models]             ; generated by devtools/mapkit/maps/zm_vexmira_icefy.py (PROPS)",
"model = models/vexmira/ice/ice_truck.mdl -420 120 0 0",
"model = models/vexmira/ice/ice_truck.mdl 600 -300 0 90",
"model = models/vexmira/ice/ice_jeep.mdl -180 700 0 180",
"model = models/vexmira/ice/ice_cratem.mdl -180 762 0 0",
"model = models/vexmira/ice/ice_sled.mdl 220 -880 0 90",
"model = models/vexmira/ice/ice_tank.mdl -620 -380 0 90",
"model = models/vexmira/ice/ice_generator.mdl -760 330 0 90",
"model = models/vexmira/ice/ice_barrel.mdl -760 400 0 0",
"model = models/vexmira/ice/ice_radar.mdl 1000 -230 192 0 fr:1",
"model = models/vexmira/ice/ice_antenna.mdl 1010 100 192 0",
"model = models/vexmira/ice/ice_logs.mdl -240 -440 0 0",
"model = models/vexmira/ice/ice_barrel.mdl 720 700 0 0",
"model = models/vexmira/ice/ice_barrel.mdl 756 724 0 90",
"model = models/vexmira/ice/ice_barrel.mdl 736 668 0 180",
"model = models/vexmira/ice/ice_barrel.mdl -700 610 0 0",
"model = models/vexmira/ice/ice_barrel.mdl 180 -400 0 270",
"model = models/vexmira/ice/ice_cratem.mdl 120 128 0 0",
"model = models/vexmira/ice/ice_crate.mdl 120 180 0 0",
"model = models/vexmira/ice/ice_crate.mdl 120 236 0 90",
"model = models/vexmira/ice/ice_crate.mdl 120 208 56 0",
"model = models/vexmira/ice/ice_cratem.mdl -60 -150 0 0",
"model = models/vexmira/ice/ice_cratem.mdl -60 -110 0 0",
"model = models/vexmira/ice/ice_cratem.mdl 800 560 0 90",
"model = models/vexmira/ice/ice_crate.mdl -880 760 0 0",
"model = models/vexmira/ice/ice_crate.mdl 880 -760 0 0",
"model = models/vexmira/ice/ice_lamp.mdl -300 -980 0 90",
"model = models/vexmira/ice/ice_lamp.mdl 300 -980 0 90",
"model = models/vexmira/ice/ice_lamp.mdl -560 900 0 270",
"model = models/vexmira/ice/ice_lamp.mdl 560 900 0 270",
"model = models/vexmira/ice/ice_lamp.mdl 0 0 0 0",
"model = models/vexmira/ice/ice_fence.mdl -640 -1000 0 0",
"model = models/vexmira/ice/ice_fence.mdl 512 -1000 0 0",
"model = models/vexmira/ice/ice_snowman.mdl -560 700 0 270",
"; explosive barrels: the model follows the func_breakable (hidden when it explodes, back every round)",
"model = models/vexmira/ice/ice_xbarrel.mdl @ice_xb1",
"model = models/vexmira/ice/ice_xbarrel.mdl @ice_xb2",
"model = models/vexmira/ice/ice_xbarrel.mdl @ice_xb3",
"model = models/vexmira/ice/ice_xbarrel.mdl @ice_xb4",
"model = models/vexmira/ice/ice_xbarrel.mdl @ice_xb5",
"model = models/vexmira/ice/ice_xbarrel.mdl @ice_xb6"
};
new const ZC_F_EPIC_CFG[][] = {
"// Vexmira 5.3.1: bu dosya artik kullanilmaz - tum ayarlar vexmira.cfg icinde"
};
new const ZC_F_EPIC_LANG[][] = {
"",
"[en]",
"E46_COIN = VexCoin Market",
"E46_VIPFX = VIP Cosmetic Effects",
"E46_STYLE = Effect theme",
"E46_STYLE0 = Disabled",
"E46_STYLE1 = Ember",
"E46_STYLE2 = Glacier",
"E46_STYLE3 = Void",
"E46_SPAWNFX = Entrance effect",
"E46_WINFX = Victory effect",
"E46_KILLFX = Kill effect",
"E46_PREVIEW = Preview theme",
"E46_BOSSKEYS = ^^1[R] Phase skill | ^^4[G] Unique skill^^1 | [F] Leap. G uses your drop key; bind g drop if needed.",
"E46_BOSSHUD = [R] %s: %s | [G] %s",
"E46_LASER = Laser rejected: the beam must reach a wall within %d units. No mine was spent.",
"E46_G0 = G: RAMPAGE CHARGE",
"E46_G1 = G: SOUL WAIL",
"E46_G2 = G: DARK AEGIS",
"E46_G3 = G: METEOR RAIN",
"E46_G4 = G: SOUL HARVEST",
"E46_G5 = G: BLIZZARD",
"E46_G6 = G: CHAIN LIGHTNING",
"E46_G7 = G: BROOD SWARM",
"E46_G8 = G: ECLIPSE",
"E46_VIPINFO0 = AP / XP rewards",
"E46_VIPINFO1 = Shop discounts",
"E46_VIPINFO2 = Round coin bonus",
"E46_VIPINFO3 = Daily rewards",
"E46_VIPINFO4 = Free round pack",
"E46_VIPINFO5 = Armor and mines",
"E46_VIPINFO6 = Extra jumps",
"E46_VIPINFO7 = Spawn protection",
"E46_VIPINFO8 = Voting bonus",
"E46_VIPINFO9 = Aura and trails",
"E46_VIPINFO10 = VIP appearance",
"E46_VIPINFO11 = VIP commands",
"E46_VIPINFO12 = Comfort features",
"E46_VIPINFO13 = Elite privileges",
"E46_VIPINFO14 = Exclusive effects",
"E46_VIPINVITE = VIP grants three selectable effect themes with entrance, kill and victory effects.",
"",
"WELCOME_2 = ^^4M^^1 = menu. ^^4/ozel^^1: 8 silah | ^^4/shop^^1: Jetpack | ^^4/kozmetik^^1: VexCoin Market.",
"VX_ALT_0 = Focused bolt",
"VX_ALT_1 = Energy burst",
"VX_ALT_2 = Quantum burst + ally healing",
"VX_ALT_3 = Chimera sweep",
"VX_ALT_4 = Piercing dark pulse",
"VX_ALT_5 = Chain lightning",
"VX_ALT_6 = Void core",
"VX_ALT_7 = Gunkata area sweep",
"",
"[tr]",
"E46_COIN = VexCoin Market",
"E46_VIPFX = VIP Ozel Efektler",
"E46_STYLE = Efekt temasi",
"E46_STYLE0 = Kapali",
"E46_STYLE1 = Kor Alev",
"E46_STYLE2 = Buzul",
"E46_STYLE3 = Bosluk",
"E46_SPAWNFX = Giris efekti",
"E46_WINFX = Zafer efekti",
"E46_KILLFX = Oldurme efekti",
"E46_PREVIEW = Temayi dene",
"E46_BOSSKEYS = ^^1[R] Faz yetenegi | ^^4[G] Ozel yetenek^^1 | [F] Atilma. G calismazsa konsola: bind g drop",
"E46_BOSSHUD = [R] %s: %s | [G] %s",
"E46_LASER = Lazer reddedildi: isin %d birim icinde duvara ulasmali. Lazer harcanmadi.",
"E46_G0 = G: EZICI HUCUM",
"E46_G1 = G: RUH FERYADI",
"E46_G2 = G: KARANLIK KALKAN",
"E46_G3 = G: METEOR YAGMURU",
"E46_G4 = G: RUH HASADI",
"E46_G5 = G: TIPI",
"E46_G6 = G: ZINCIR SIMSEK",
"E46_G7 = G: KOVAN SURUSU",
"E46_G8 = G: KARANLIK TUTULMA",
"E46_VIPINFO0 = AP / XP odulleri",
"E46_VIPINFO1 = Market indirimi",
"E46_VIPINFO2 = Round coin bonusu",
"E46_VIPINFO3 = Gunluk oduller",
"E46_VIPINFO4 = Ucretsiz round paketi",
"E46_VIPINFO5 = Zirh ve lazer",
"E46_VIPINFO6 = Ek ziplama",
"E46_VIPINFO7 = Dogma korumasi",
"E46_VIPINFO8 = Oy bonusu",
"E46_VIPINFO9 = Aura ve izler",
"E46_VIPINFO10 = VIP gorunumu",
"E46_VIPINFO11 = VIP komutlari",
"E46_VIPINFO12 = Konfor ozellikleri",
"E46_VIPINFO13 = Elite ayricaliklari",
"E46_VIPINFO14 = Ozel efektler",
"E46_VIPINVITE = VIP ile uc efekt temasi, giris, oldurme ve zafer efektleri acilir.",
"",
"WELCOME_2 = ^^4M^^1 = menu. ^^4/ozel^^1: 8 silah | ^^4/shop^^1: Jetpack | ^^4/kozmetik^^1: VexCoin Market.",
"VX_ALT_0 = Odakli ok",
"VX_ALT_1 = Enerji patlamasi",
"VX_ALT_2 = Kuantum patlamasi + takim iyilesmesi",
"VX_ALT_3 = Chimera darbesi",
"VX_ALT_4 = Delici karanlik atis",
"VX_ALT_5 = Zincir elektrik",
"VX_ALT_6 = Bosluk cekirdegi",
"VX_ALT_7 = Gunkata alan saldirisi"
};
ZcWriteLines(const path[], const lines[][], n, bool:force)
{
if (!force && file_exists(path)) return 0;
new backup[256];
if (force && file_exists(path)) {
new stamp[48], suffix;
get_time("%Y%m%d-%H%M%S", stamp, charsmax(stamp));
formatex(backup, charsmax(backup), "%s.%s.bak", path, stamp);
while (file_exists(backup)) formatex(backup, charsmax(backup), "%s.%s-%d.bak", path, stamp, ++suffix);
if (!rename_file(path, backup, 1)) { log_amx("[Vexmira] yedek alinamadi, korundu: %s", path); return -1; }
log_amx("[Vexmira] ayar yedegi: %s", backup);
}
new f = fopen(path, "wt");
if (!f) {
if (backup[0] && !file_exists(path)) rename_file(backup, path, 1);
log_amx("[Vexmira] HATA: %s yazilamadi (klasor izni?)", path); return -1;
}
for (new i = 0; i < n; i++) { fputs(f, lines[i]); fputs(f, "^n"); }
fclose(f);
log_amx("[Vexmira] varsayilan dosya yazildi: %s (%d satir)", path, n);
server_print("[Vexmira] varsayilan dosya yazildi: %s", path);
return 1;
}
ZcEnsureDir(const dir[])
{
if (!dir_exists(dir)) mkdir(dir);
}
ZcWriteConfigs(bool:force)
{
new cfg[96], data[96], path[192], n;
get_configsdir(cfg, charsmax(cfg));
get_localinfo("amxx_datadir", data, charsmax(data));
if (!data[0]) copy(data, charsmax(data), "addons/amxmodx/data");
ZcEnsureDir(cfg);
formatex(path, charsmax(path), "%s/vexmira_maps", cfg); ZcEnsureDir(path);
ZcEnsureDir(data);
formatex(path, charsmax(path), "%s/lang", data); ZcEnsureDir(path);
formatex(path, charsmax(path), "%s/vexmira.cfg", cfg); if (ZcWriteLines(path, ZC_F_CFG, sizeof ZC_F_CFG, force) > 0) n++;
formatex(path, charsmax(path), "%s/lang/vexmira_zombie.txt", data); if (ZcWriteLines(path, ZC_F_LANG, sizeof ZC_F_LANG, force) > 0) n++;
formatex(path, charsmax(path), "%s/vexmira_motd_en.html", cfg); if (ZcWriteLines(path, ZC_F_MOTD_EN, sizeof ZC_F_MOTD_EN, force) > 0) n++;
formatex(path, charsmax(path), "%s/vexmira_motd_tr.html", cfg); if (ZcWriteLines(path, ZC_F_MOTD_TR, sizeof ZC_F_MOTD_TR, force) > 0) n++;
formatex(path, charsmax(path), "%s/vexmira_maps/zm_vexmira_7door.ini", cfg); if (ZcWriteLines(path, ZC_F_MAP_ZM_VEXMIRA_7DOOR, sizeof ZC_F_MAP_ZM_VEXMIRA_7DOOR, force) > 0) n++;
formatex(path, charsmax(path), "%s/vexmira_maps/zm_vexmira_dust.ini", cfg); if (ZcWriteLines(path, ZC_F_MAP_ZM_VEXMIRA_DUST, sizeof ZC_F_MAP_ZM_VEXMIRA_DUST, force) > 0) n++;
formatex(path, charsmax(path), "%s/vexmira_maps/zm_vexmira_icefy.ini", cfg); if (ZcWriteLines(path, ZC_F_MAP_ZM_VEXMIRA_ICEFY, sizeof ZC_F_MAP_ZM_VEXMIRA_ICEFY, force) > 0) n++;
// 5.3.1: vexmira_epic.cfg is no longer written (single vexmira.cfg)
formatex(path,charsmax(path),"%s/lang/vexmira_epic.txt",data); if(ZcWriteLines(path,ZC_F_EPIC_LANG,sizeof ZC_F_EPIC_LANG,force)>0) n++;
return n;
}
public ZcCmdWriteConfigs(id, level, cid)
{
if (!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED;
new n = ZcWriteConfigs(true);
console_print(id, "[Vexmira] %d dosya varsayilan haliyle yeniden yazildi. vex_reload veya harita degisimi ile gecerli olur.", n);
return PLUGIN_HANDLED;
}
public plugin_natives()
{
register_native("vx521_pair_version","Vx521PairVersion");
register_library("vexmira_gear45");
register_native("vx45_call","VxGearCall");
register_native("vx45_ready","VxGearReady");
register_native("vx45_count","VxGearCount");
register_native("vx45_status","VxGearStatus");
register_native("vx45_hevlimit","VxGearHevLimit");
register_native("vx45_write","VxGearWrite");
}
public VxGearCall(plugin, params) { return ZcCall(get_param(1),get_param(2),get_param(3)); }
public VxGearReady(plugin, params) { return ZcCompOn(get_param(1)); }
public VxGearCount(plugin, params) { return ZcModulesOn(); }
public VxGearStatus(plugin, params) { ZcModuleStatus(get_param(1)); return 1; }
public VxGearHevLimit(plugin, params) { new id=get_param(1); return id>=1 && id<=32 ? ZcHevRoundLocked(id):0; }
public VxGearWrite(plugin, params) { return ZcWriteConfigs(bool:get_param(1)); }
public plugin_end() {
    if (g_tZcModelsReady != Invalid_Trie) TrieDestroy(g_tZcModelsReady);
    if (g_tTrackedWeaponSounds != Invalid_Trie) TrieDestroy(g_tTrackedWeaponSounds);
}

JetGaugeUpdate48(id,Float:now)
{
if(now<jet_fHudAt47[id]) return;
jet_fHudAt47[id]=now+0.5;
vx47_jetgauge(id,clamp(floatround((10.0-floatmax(0.0,jet_fLastShot[id]-now))*10.0),0,100),jet_iGas[id]*100/jet_MaxGas);
}

GearCreate51(const classname[]) {if(engfunc(EngFunc_NumberOfEntities)>=global_get(glb_maxEntities)-32) {log_to_file("vexmira_stability.log","GEAR_SPAWN_DENIED %s",classname);return 0;}return create_entity(classname);}

public Vx521PairVersion(plugin,params) { return 530; }


stock HamHook:VxRegisterHam524(Ham:fn,const cls[],const cb[],post=0,bool:specialbot=false) {
log_to_file("vexmira_startup.log","[530 vexgear] HAM begin fn=%d class=%s callback=%s",fn,cls,cb);
new HamHook:h=RegisterHam(fn,cls,cb,post,specialbot);
log_to_file("vexmira_startup.log","[530 vexgear] HAM ready callback=%s handle=%d",cb,h);
return h;
}
stock HookChain:VxRegisterChain524(ReAPIFunc:fn,const cb[],post=0) {
log_to_file("vexmira_startup.log","[530 vexgear] REAPI begin fn=%d callback=%s",fn,cb);
new HookChain:h=RegisterHookChain(fn,cb,post);
log_to_file("vexmira_startup.log","[530 vexgear] REAPI ready callback=%s handle=%d",cb,h);
return h;
}
public VxActivatePre524(runPhysics) {
log_to_file("vexmira_startup.log","[530 vexgear] ServerActivate PRE physics=%d",runPhysics);
return HC_CONTINUE;
}
public VxActivatePost524(runPhysics) {
log_to_file("vexmira_startup.log","[530 vexgear] ServerActivate POST");
return HC_CONTINUE;
}

stock ReadIsolation526() {
new p[192];get_configsdir(p,charsmax(p));add(p,charsmax(p),"/vexmira_isolation.ini");
new fp=fopen(p,"rt");if(!fp) return 0;
new line[32];fgets(fp,line,charsmax(line));fclose(fp);trim(line);
return clamp(str_to_num(line),0,10);
}
public IsolationStatus526(id) {
console_print(id,"[530 vexgear] stage=%d full_module=%d; baseline is stock CS, not zombie gameplay",g_iIsolation526,g_bRun526);
return PLUGIN_HANDLED;
}

stock RegisterTexture530(const path[]) {
new length=strlen(path);if(length<5 || !equali(path[length-4],".mdl")) return;
new tex[192];copy(tex,charsmax(tex),path);tex[length-4]=0;add(tex,charsmax(tex),"T.mdl");
if(file_exists(tex,true)) ZcPcGeneric(tex);
}
