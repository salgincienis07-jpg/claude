/* Vexmira Zombie - EXTRA module (5.3.8). Third main plugin: keeps vexmira_core.sma under the panel's 1 MB
   source limit. Holds: resource defaults, event precache lists, and the
   5.3.8 systems (kill feel, unprecacher, zombie class upgrades, special knife/gun slots).
   Load order (plugins-vexmira.ini): vexmira_core.amxx, vexmira_gear.amxx, vexmira_extra.amxx */
#include <amxmodx>
new g_hPlus622=INVALID_HANDLE,g_acMask622[33],bool:g_acReady622[33];
#define MARKET622_MAX 64
new g_mSerial622,g_mId622[MARKET622_MAX],g_mOwner622[MARKET622_MAX],g_mUid622[MARKET622_MAX],g_mCat622[MARKET622_MAX],g_mItem622[MARKET622_MAX],g_mPrice622[MARKET622_MAX];

#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <xs>
#include <nvault>
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

#pragma dynamic 32768
#pragma tabsize 0
#define VXE_VERSION 564
native vxc_res_set(const key[], const value[]);
native vxc_pc_generic(const path[]);
native vxc_area_hit(victim,owner,inflictor,Float:damage);
#define NUM_CLASSES   24
#define NUM_BOSSES    9
#define NUM_SPECIAL   8
new const CLASS_FILE[NUM_CLASSES][] =
{
"walker", "runner", "tank", "banshee", "leech", "stalker", "bomber", "frost",
"spitter", "hulk", "voodoo", "phantom", "butcher", "hunter", "charger", "arachne",
"magma", "volt", "mimic", "burrower", "siren", "bulwark", "sporemother", "nightmare"
};
new const WEAPON_KEYNAME[31][] =
{
"", "P228", "GLOCK", "SCOUT", "HEGRENADE", "XM1014", "C4", "MAC10", "AUG", "SMOKEGRENADE",
"ELITE", "FIVESEVEN", "UMP45", "SG550", "GALIL", "FAMAS", "USP", "GLOCK18", "AWP", "MP5NAVY",
"M249", "M3", "M4A1", "TMP", "G3SG1", "FLASHBANG", "DEAGLE", "SG552", "AK47", "KNIFE", "P90"
};
new const BOSS_FILE[NUM_BOSSES][] = { "brute", "banshee", "overlord", "inferno", "reaper", "frostlord", "stormcaller", "hivequeen", "void" };
new const CLASS_MDL_DEF[NUM_CLASSES][] = { "walker", "runner", "tank", "banshee", "leech", "stalker", "bomber", "frost", "spitter", "hulk", "voodoo", "phantom", "butcher", "runner", "tank", "stalker", "bomber", "frost", "walker", "hulk", "banshee", "tank", "spitter", "phantom" };
new const CLASS_CLAW_DEF[NUM_CLASSES][] = { "walker", "runner", "hulk", "banshee", "leech", "stalker", "bomber", "frost", "spitter", "hulk", "voodoo", "phantom", "butcher", "runner", "hulk", "stalker", "bomber", "frost", "walker", "hulk", "banshee", "hulk", "spitter", "phantom" };
new const BOSS_MDL_DEF[NUM_BOSSES][] = { "tank", "banshee", "hulk", "bomber", "phantom", "frost", "voodoo", "spitter", "stalker" };

#define VM_MODELS563 32
#define VM_SEQS563 256
#define VM_EVENTS563 1024
#define VM_SOUNDS563 256
new Trie:g_tVm563=Invalid_Trie,g_iVmCount563,g_iVmEventCount563,g_iVmSoundCount563;
new g_szVmPath563[VM_MODELS563][96],g_szVmSound563[VM_SOUNDS563][96],bool:g_bVmSoundReady563[VM_SOUNDS563];
new g_iVmStart563[VM_MODELS563][VM_SEQS563],g_iVmNum563[VM_MODELS563][VM_SEQS563];
new Float:g_fVmLength563[VM_MODELS563][VM_SEQS563],bool:g_bVmLoop563[VM_MODELS563][VM_SEQS563];
new g_iVmEventSound563[VM_EVENTS563],Float:g_fVmEventTime563[VM_EVENTS563];
new g_iVmModel563[33],g_iVmString563[33],g_iVmSeq563[33],g_iVmCursor563[33];
new Float:g_fVmClock563[33],bool:g_bVmRestart563[33];
new g_iVmMessagePlayer563,g_iVmMessageByte563,g_iVmMessageSeq563;
new bool:g_bVmPrecacheLive563;



new Float:g_fLaunch563[33][3],g_iLaunchUser563[33],g_iLaunchPass563[33];
new Float:g_fLegacyAlt563[33];
new g_szWeaponSound563[33][16][96],g_iSoundChannel563[33][16],g_iSoundCursor563[33];
new g_iSoundWeapon563[33],bool:g_bStopping563[33];
public plugin_natives()
{
register_library("vexmira_extra");
register_native("vxe_boss_giant","N_BossGiant");
register_native("vxe_giant_new","N_GiantNew542");
register_native("vxe_late_precache","N_LatePrecache542");
register_native("vxe_gs_slim","N_GsSlim");
register_native("vxe_default_resources","N_DefRes");
register_native("vxe_modern_events","N_Modern");
register_native("vxe_native_precache","N_NatPre");
register_native("vxe_version","N_Version");
register_native("vxe_sw_hit","N_SwHit");
register_native("vxe_unprecache_count","N_Unpc");
register_native("vxe_zup_level","N_ZupLevel");
register_native("vxe_zup_snapshot","N_ZupSnapshot621");
register_native("vxe_ac_load","N_AcLoad622");
register_native("vxe_ac_mask","N_AcMask622");
register_native("vxe_ac_claim","N_AcClaim622");
register_native("vxe_market_action","N_MarketAction622");
register_native("vxe_market_write","N_MarketWrite622");register_native("vxe_market_str","N_MarketStr64");
register_native("vxe_market_prepare","N_MarketPrepare622");
register_native("vxe_market_finish","N_MarketFinish622");
register_native("vxe_zup_spend","N_ZupSpend621");
register_native("vxe_zup_stat","N_ZupStat");
register_native("vxe_zup_add","N_ZupAdd");
register_native("vxe_zup_used","N_ZupUsed");
register_native("vxe_mask_block","N_MaskBlock");
register_native("vxe_zarmor_hit","N_ZArmorHit");
register_native("vxe_item_count","N_ItemCount");
register_native("vxe_item_info","N_ItemInfo");
register_native("vxe_item_buy","N_ItemBuy");
register_native("vxe_sw_count","N_SwCount");
register_native("vxe_sw_info","N_SwInfo");
register_native("vxe_sw_give","N_SwGive");
register_native("vxe_sw_active","N_SwActive");
register_native("vxe_sw_rgb","N_SwRgb");
register_native("vxe_weapon_stop","N_WeaponStop563");
register_native("vxe_blast","N_Blast563");
register_native("vxe_legacy_melee","N_LegacyMelee563");
register_native("vxe_audio_model","N_AudioModel563");
register_native("vxe_prepare_audio_cfg","N_AudioConfig563");
}
public N_Version(plugin, params) return VXE_VERSION;
new g_iGiantNew542;
new bool:g_bBuildAllowed565;
public N_GiantNew542(plugin, params) return g_iGiantNew542;
public N_BossGiant(plugin, params)
{
new name[128], out[64];
g_bBuildAllowed565 = params >= 6 && get_param(6) != 0;
get_string(1, name, charsmax(name));
new ok = GmBossGiant(name, out, charsmax(out), get_param_f(4), get_param(5)) ? 1 : 0;
if (ok) set_string(2, out, get_param(3));
return ok;
}
public N_GsSlim(plugin, params)
{
new a[192], b[192];
get_string(1, a, charsmax(a)); get_string(2, b, charsmax(b));
return GsSlim(a, b, get_param(3)) ? 1 : 0;
}
public N_DefRes(plugin, params) { SetDefaultResources(); return 1; }
public N_Modern(plugin, params) { ModernEvents50(); return 1; }
public N_NatPre(plugin, params) { NativePrecache52(); return 1; }
public plugin_init()
{
PlusInit622();
register_plugin("Vexmira Extra", "5.6.4", "Vexmira");
ZupInit();
WeaponLifecycleInit563();
VmLifecycleInit563();
register_concmd("vex_538_test", "Cmd538Test", ADMIN_RCON, "[upgrade points]");
register_logevent("ItemsReset538", 2, "1=Round_Start");
RegisterHam(Ham_Spawn, "player", "ItemsSpawn538", 1);
}
bool:SoundExists(const path[])
{
if (!path[0]) return false;
new full[160];
if (containi(path, ".mp3") != -1) copy(full, charsmax(full), path);
else formatex(full, charsmax(full), "sound/%s", path);
return file_exists(full, true) ? true : false;
}
DefModel(const key[], const first[], const second[])
{
if (first[0] && file_exists(first, true)) vxc_res_set(key, first);
else if (second[0] && file_exists(second, true)) vxc_res_set(key, second);
else vxc_res_set(key, first);
}
DefSound(const key[], const first[], const second[])
{
if (SoundExists(first)) vxc_res_set(key, first);
else if (SoundExists(second)) vxc_res_set(key, second);
else vxc_res_set(key, "");
}

SetDefaultResources()
{
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
vxc_res_set(swkey, "");
}
DefSound("ZAP",            "vexmira/zap.wav",             "weapons/electro4.wav");
DefSound("MVP",            "vexmira/mvp.wav",             "events/task_complete.wav");
DefSound("CSO_KM",         "vexmira/cso/km.wav",          "buttons/blip1.wav");
DefSound("CSO_KM_SP",      "vexmira/cso/km_sp.wav",       "buttons/blip2.wav");
DefSound("CSO_MVP",        "vexmira/cso/mvp.wav",         "events/task_complete.wav");
DefSound("CSO_BANNER",     "vexmira/cso/banner.wav",      "ambience/the_horror2.wav");
DefSound("CSO_WIN",        "vexmira/cso/win.wav",         "events/task_complete.wav");
DefSound("CSO_ALERT",      "vexmira/cso/alert.wav",       "buttons/blip2.wav");
DefSound("CSO_LEVEL",      "vexmira/cso/levelup.wav",     "plats/elevbell1.wav");
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
DefSound("ZONE_WARN",        "vexmira/zone_warn.wav",        "buttons/blip2.wav");
DefSound("SKILL_UNLOCK",     "vexmira/skill_unlock.wav",     "plats/elevbell1.wav");
DefSound("NEM_RAGE",         "vexmira/nem_rage.wav",         "garg/gar_alert3.wav");
DefSound("ASN_VEIL",         "vexmira/asn_veil.wav",         "x/x_teleattack1.wav");
DefSound("LM_KILL",          "vexmira/lm_kill.wav",          "weapons/electro5.wav");
DefSound("NADE_TRIGGER",     "vexmira/nade_trigger.wav",     "weapons/c4_beep2.wav");
DefSound("UI_OPEN",          "vexmira/ui_open.wav",          "");
DefSound("LM_DENY",          "vexmira/deny.wav",             "buttons/button10.wav");
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
DefSound("UI_VOTE_START",   "vexmira/ui/vote_start.wav",   "buttons/bell1.wav");
DefSound("UI_VOTE_END",     "vexmira/ui/vote_end.wav",     "buttons/blip2.wav");
DefSound("UI_BOSS_BAR",     "vexmira/ui/boss_bar.wav",     "");
DefSound("UI_MENU_SELECT",  "vexmira/ui/menu_select.wav",  "");
DefSound("UI_CLASS_SELECT", "vexmira/ui/class_select.wav", "");
DefSound("MODE9_MUSIC", "sound/vexmira/boss_theme.mp3", "");
DefSound("MODE2_MUSIC", "sound/vexmira/nemesis_theme.mp3", "");
DefSound("MODE3_MUSIC", "sound/vexmira/nemesis_theme.mp3", "");
DefSound("MODE8_MUSIC", "sound/vexmira/boss_theme.mp3", "");
vxc_res_set("VOX_BOSS",     "vox/warning _comma hostile presence detected");
vxc_res_set("VOX_BOSSDOWN", "vox/target destroyed");
vxc_res_set("VOX_FINAL",    "vox/final round");
vxc_res_set("VOX_INFECT",   "vox/biohazard detected");
vxc_res_set("VOX_LAST",     "vox/one remaining");
vxc_res_set("VOX_AIRDROP",  "vox/supply deployed");
vxc_res_set("VOX_BLACKOUT", "vox/power failure");
vxc_res_set("VOX_STORM",    "vox/danger _comma electric field detected");
vxc_res_set("VOX_SPEED",    "vox/warning _comma high speed");
vxc_res_set("VOX_MAPEND",   "vox/all objective secured");
SetClassResources();
SetModelResources();
vxc_res_set("SKY_MODE", "1");
vxc_res_set("SKY_LIST", "night de_storm tornsky black space hav office cx backalley city");
vxc_res_set("SPR_ZONE",   "sprites/vexmira/zone.spr");
vxc_res_set("SPR_TARGET", "sprites/vexmira/target.spr");
vxc_res_set("SPR_BEACON", "sprites/vexmira/beacon.spr");
vxc_res_set("SPR_ORB",    "sprites/vexmira/orb.spr");
vxc_res_set("SPR_MARK",   "sprites/vexmira/mark.spr");
vxc_res_set("SPR_FIRE",   "sprites/vexmira/fire.spr");
vxc_res_set("SPR_LASER",  "sprites/vexmira/laser.spr");
}
SetModelResources()
{
new key[24], val[96];
for (new b = 0; b < NUM_BOSSES; b++)
{
formatex(key, charsmax(key), "B%d_MODEL", b);
formatex(val, charsmax(val), "vex_z_%s", BOSS_MDL_DEF[b]);
vxc_res_set(key, val);
formatex(key, charsmax(key), "B%d_CLAW", b);
copy(val, charsmax(val), "models/vexmira/claws/v_hulk.mdl");
vxc_res_set(key, val);
}
vxc_res_set("NEMESIS_MODEL",  "vex_z_hulk");
vxc_res_set("ASSASSIN_MODEL", "vex_z_phantom");
vxc_res_set("NEMESIS_CLAW",   "models/vexmira/claws/v_hulk.mdl");
vxc_res_set("ASSASSIN_CLAW",  "models/vexmira/claws/v_phantom.mdl");
vxc_res_set("SURVIVOR_MODEL", "sp_halo_admins");
vxc_res_set("SNIPER_MODEL",   "sp_halo_admins");
vxc_res_set("VIP_MODEL",      "sp_halo_admins");
vxc_res_set("ADMIN_MODEL",    "sp_halo_admins");
vxc_res_set("HUMAN_MODELS",   "sp_halo_admins");
vxc_res_set("V_KNIFE",        "models/vexmira/weapons/v_vexblade.mdl");
vxc_res_set("V_HEGRENADE",    "models/vexmira_ze/grenades/vexmira_v_hegrenade.mdl");
vxc_res_set("V_SMOKEGRENADE", "models/vexmira_ze/grenades/vexmira_v_smokegrenade.mdl");
vxc_res_set("V_FLASHBANG",    "models/vexmira_ze/grenades/vexmira_v_flashbang.mdl");
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
val[0] = 0;
vxc_res_set(key, val);
}
DefModel("P_KNIFE",        "models/vexmira/weapons/p_vexblade.mdl",  "models/vexmira/weapons/p_knife.mdl");
DefModel("P_HEGRENADE",    "models/vexmira_ze/grenades/vexmira_p_hegrenade.mdl",  "models/vexmira/weapons/p_hegrenade.mdl");
DefModel("P_SMOKEGRENADE", "models/vexmira_ze/grenades/vexmira_p_smokegrenade.mdl", "models/vexmira/weapons/p_smokegrenade.mdl");
DefModel("P_FLASHBANG",    "models/vexmira_ze/grenades/vexmira_p_flashbang.mdl",     "models/vexmira/weapons/p_flashbang.mdl");
for (new i = 0; i < NUM_SPECIAL; i++)
{
formatex(key, charsmax(key), "SW%d_VMODEL", i);
formatex(val, charsmax(val), "models/vexmira/weapons/v_sw%d.mdl", i % 8);
vxc_res_set(key, val);
formatex(key, charsmax(key), "SW%d_PMODEL", i);
formatex(val, charsmax(val), "models/vexmira/weapons/p_sw%d.mdl", i);
if (!file_exists(val, true))
val[0] = 0;
vxc_res_set(key, val);
}
vxc_res_set("LASERMINE_MODEL", "models/vexmira/world/lasermine.mdl");
vxc_res_set("LASERMINE_MODEL_HUMAN", "models/v_tripmine.mdl");
vxc_res_set("LASERMINE_MODEL_ZOMBIE", "models/vexmira/world/lasermine.mdl");
vxc_res_set("AIRDROP_MODEL",   "models/vexmira/world/supply_crate.mdl");
vxc_res_set("EGG_MODEL",       "");
vxc_res_set("W_HEGRENADE",     "models/vexmira_ze/grenades/vexmira_w_hegrenade.mdl");
vxc_res_set("W_SMOKEGRENADE",  "models/vexmira_ze/grenades/vexmira_w_smokegrenade.mdl");
vxc_res_set("W_FLASHBANG",     "models/vexmira_ze/grenades/vexmira_w_flashbang.mdl");
vxc_res_set("SPR_BOSSBAR",     "sprites/vexmira/bossbar.spr");
vxc_res_set("SPR_BOSSICON",    "sprites/vexmira/bossicon.spr");
vxc_res_set("SPR_HPBAR",       "sprites/vexmira/hpbar_small.spr");
vxc_res_set("SPR_ICON_VIP",    "sprites/vexmira/icon_vip.spr");
vxc_res_set("SPR_ICON_ADMIN",  "sprites/vexmira/icon_admin.spr");
vxc_res_set("SPR_ICON_MVP",    "sprites/vexmira/icon_mvp.spr");
vxc_res_set("SPR_ICON_LAST",   "sprites/vexmira/icon_lasthuman.spr");
vxc_res_set("SPR_ICON_ALPHA",  "sprites/vexmira/icon_alpha.spr");
vxc_res_set("BOSS_PRELOAD",      "4");
vxc_res_set("BOSS_PRELOAD_LIST", "");
vxc_res_set("BOSS_GIANT_TEX",    "128");
vxc_res_set("BOSS_GIANT_ALL",    "1");
vxc_res_set("SOUND_BUDGET",      "200");
vxc_res_set("MODEL_BUDGET",      "250");
vxc_res_set("SOUND_BLOCK_STOCK", "1");
vxc_res_set("SOUND_BLOCK_EXTRA", "");
vxc_res_set("SPR_EXPLO_FIRE",  "sprites/vexmira/explo_fire.spr");
vxc_res_set("SPR_EXPLO_ICE",   "sprites/vexmira/explo_ice.spr");
vxc_res_set("SPR_EXPLO_TOXIC", "sprites/vexmira/explo_toxic.spr");
vxc_res_set("SPR_EXPLO_VOID",  "sprites/vexmira/explo_void.spr");
vxc_res_set("SPR_HEAL",        "sprites/vexmira/heal.spr");
vxc_res_set("SPR_LEVELUP",     "sprites/vexmira/levelup.spr");
vxc_res_set("SPR_INFECT",      "sprites/vexmira/infect.spr");
vxc_res_set("SPR_SHOCK",       "sprites/vexmira/shock.spr");
vxc_res_set("SPR_SLASH",       "sprites/vexmira/slash.spr");
vxc_res_set("SPR_ICE",         "sprites/vexmira/ice.spr");
vxc_res_set("SPR_VOID",        "sprites/vexmira/void.spr");
vxc_res_set("SPR_TOXIC",       "sprites/vexmira/toxic.spr");
}
SetClassResources()
{
new key[24], val[96], snd[96];
static const CEV[][] = { "pain", "die", "idle", "ability" };
static const CEVKEY[][] = { "PAIN", "DIE", "IDLE", "ABILITY" };
for (new i = 0; i < NUM_CLASSES; i++)
{
formatex(key, charsmax(key), "Z%d_MODEL", i);
formatex(val, charsmax(val), "vex_z_%s", CLASS_MDL_DEF[i]);
vxc_res_set(key, val);
formatex(key, charsmax(key), "Z%d_CLAW", i);
formatex(val, charsmax(val), "models/vexmira/claws/v_%s.mdl", CLASS_CLAW_DEF[i]);
vxc_res_set(key, val);
for (new e = 0; e < sizeof CEV; e++)
{
formatex(key, charsmax(key), "Z%d_%s", i, CEVKEY[e]);
formatex(snd, charsmax(snd), "vexmira/class/%s_%s.wav", CLASS_FILE[i], CEV[e]);
DefSound(key, snd, "");
}
}
DefSound("HUNTER_IMPACT",     "vexmira/class/hunter_impact.wav",     "garg/gar_stomp1.wav");
DefSound("CHARGER_IMPACT",    "vexmira/class/charger_impact.wav",    "garg/gar_stomp1.wav");
DefSound("ARACHNE_WEBHIT",    "vexmira/class/arachne_webhit.wav",    "bullchicken/bc_spithit1.wav");
DefSound("BURROWER_ERUPT",    "vexmira/class/burrower_erupt.wav",    "garg/gar_stomp1.wav");
DefSound("SPOREMOTHER_BURST", "vexmira/class/sporemother_burst.wav", "bullchicken/bc_acid1.wav");
DefSound("MIMIC_REVEAL",      "vexmira/class/mimic_reveal.wav",      "zombie/zo_alert30.wav");
DefSound("VOLT_ZAP",          "vexmira/class/volt_zap.wav",          "weapons/electro4.wav");
DefSound("HOOK_THROW", "vexmira/hook/throw.wav", "zombie/claw_miss1.wav");
DefSound("HOOK_CHAIN", "vexmira/hook/chain.wav", "");
DefSound("HOOK_HIT",   "vexmira/hook/hit.wav",   "zombie/claw_strike1.wav");
DefSound("HOOK_PULL",  "vexmira/hook/pull.wav",  "");
DefSound("HOOK_MISS",  "vexmira/hook/miss.wav",  "zombie/claw_miss2.wav");
vxc_res_set("HOOK_MODEL",  "");
vxc_res_set("SPORE_MODEL", "");
vxc_res_set("SPR_CHAIN",   "sprites/vexmira/chain.spr");
vxc_res_set("SPR_WEB",     "sprites/vexmira/web.spr");
vxc_res_set("SPR_SPORE",   "sprites/vexmira/spore.spr");
vxc_res_set("SPR_EMP",     "sprites/vexmira/emp.spr");
}

#define GS_MAXP 4096
#define GS_MAXQ 400
#define GS_MAXS 512
#define GS_MAXT 64
new g_GsPos[GS_MAXP], g_GsVal[GS_MAXP], g_GsNP;
new g_GsSeqO[GS_MAXQ], g_GsSeqAi[GS_MAXQ], g_GsRed[GS_MAXQ], g_GsLab[GS_MAXQ][33];
new g_GsSegA[GS_MAXS], g_GsSegB[GS_MAXS], g_GsSegN[GS_MAXS], g_GsSegT[GS_MAXS], g_GsNS;
new g_GsTexF[GS_MAXT], g_GsTexW[GS_MAXT], g_GsTexH[GS_MAXT];
stock Float:GmRdF(fp, off) { new v; fseek(fp, off, SEEK_SET); fread(fp, v, BLOCK_INT); return Float:v; }
stock GmRdI(fp, off) { new v; fseek(fp, off, SEEK_SET); fread(fp, v, BLOCK_INT); return v; }
stock GmWrF(fp, off, Float:v) { fseek(fp, off, SEEK_SET); fwrite(fp, _:v, BLOCK_INT); }
stock GmScale(fp, off, Float:k, Float:add = 0.0) { GmWrF(fp, off, GmRdF(fp, off) * k + add); }
stock GmScale3(fp, off, Float:k, Float:addz = 0.0) { GmScale(fp, off, k); GmScale(fp, off + 4, k); GmScale(fp, off + 8, k, addz); }
bool:GmCopy(const src[], const dst[])
{
new in = fopen(src, "rb", true);
if (!in) return false;
new out = fopen(dst, "wb");
if (!out) { fclose(in); return false; }
new buf[2048], n;
while ((n = fread_blocks(in, buf, sizeof buf, BLOCK_CHAR)) > 0)
fwrite_blocks(out, buf, n, BLOCK_CHAR);
fclose(in); fclose(out);
return true;
}
bool:GmPatch(const path[], Float:k)
{
new fp = fopen(path, "r+b");
if (!fp) return false;
if (GmRdI(fp, 0) != 0x54534449 || GmRdI(fp, 4) != 10) { fclose(fp); return false; }
new Float:lift = 36.0 * (k - 1.0);
GmScale3(fp, 76, k, lift);  GmScale3(fp, 88, k, lift); GmScale3(fp, 100, k, lift);
GmScale3(fp, 112, k, lift); GmScale3(fp, 124, k, lift);
new nb = GmRdI(fp, 140), bi = GmRdI(fp, 144);
if (nb < 1 || nb > 256) { fclose(fp); return false; }
for (new b = 0; b < nb; b++)
{
new o = bi + b * 112;
new parent = GmRdI(fp, o + 32);
GmScale(fp, o + 64, k); GmScale(fp, o + 68, k); GmScale(fp, o + 72, k, parent < 0 ? lift : 0.0);
GmScale(fp, o + 88, k); GmScale(fp, o + 92, k); GmScale(fp, o + 96, k);
}
new nc = GmRdI(fp, 148), ci = GmRdI(fp, 152);
for (new c = 0; c < nc && c < 64; c++)
{
new o = ci + c * 24;
if (GmRdI(fp, o + 4) & 7) { GmScale(fp, o + 8, k); GmScale(fp, o + 12, k); }
}
new nh = GmRdI(fp, 156), hi = GmRdI(fp, 160);
for (new h = 0; h < nh && h < 256; h++) { new o = hi + h * 32; GmScale3(fp, o + 8, k); GmScale3(fp, o + 20, k); }
new ns = GmRdI(fp, 164), si = GmRdI(fp, 168);
for (new q = 0; q < ns && q < 1024; q++) { new o = si + q * 176; GmScale3(fp, o + 76, k); GmScale3(fp, o + 96, k, lift); GmScale3(fp, o + 108, k, lift); }
new na = GmRdI(fp, 212), ai = GmRdI(fp, 216);
for (new a = 0; a < na && a < 16; a++) GmScale3(fp, ai + a * 88 + 40, k);
new nbp = GmRdI(fp, 204), bpi = GmRdI(fp, 208);
for (new p = 0; p < nbp && p < 32; p++)
{
new o = bpi + p * 76, nm = GmRdI(fp, o + 64), mi = GmRdI(fp, o + 72);
for (new m = 0; m < nm && m < 64; m++)
{
new mo = mi + m * 112;
GmScale(fp, mo + 68, k);
new nv = GmRdI(fp, mo + 80), vi = GmRdI(fp, mo + 88);
for (new v = 0; v < nv && v < 32768; v++) GmScale3(fp, vi + v * 12, k);
}
}
fclose(fp);
return true;
}
stock bool:GsMarked(const path[], const mark[])
{
new fp = fopen(path, "rb");
if (!fp) return false;
new buf[33]; fseek(fp, 8, SEEK_SET); fread_blocks(fp, buf, 32, BLOCK_CHAR); fclose(fp); buf[32] = 0;
return equal(buf, mark) ? true : false;
}
stock GsMark(const path[], const mark[])
{
new fp = fopen(path, "r+b");
if (!fp) return;
new buf[64], n = strlen(mark);
for (new i = 0; i < 64; i++) buf[i] = i < n ? mark[i] : 0;
fseek(fp, 8, SEEK_SET); fwrite_blocks(fp, buf, 64, BLOCK_CHAR); fclose(fp);
}
stock GsRdS(fp, off) { new v; fseek(fp, off, SEEK_SET); fread(fp, v, BLOCK_SHORT); v &= 0xFFFF; if (v & 0x8000) v |= 0xFFFF0000; return v; }
stock GsWrI(fp, off, v) { fseek(fp, off, SEEK_SET); fwrite(fp, v, BLOCK_INT); }
stock GsP(fp, pos, len)
{
if (pos <= 0 || pos + 4 > len || g_GsNP >= GS_MAXP) return;
new v = GmRdI(fp, pos);
if (v > 0 && v <= len) { g_GsPos[g_GsNP] = pos; g_GsVal[g_GsNP++] = v; }
}
stock GsEnd(a, len, nq)
{
new e = len;
for (new i = 0; i < g_GsNP; i++) if (g_GsVal[i] > a && g_GsVal[i] < e) e = g_GsVal[i];
for (new q = 0; q < nq; q++) if (g_GsSeqAi[q] > a && g_GsSeqAi[q] < e) e = g_GsSeqAi[q];
return e;
}
stock GsRemap(off)
{
new r = off;
for (new s = 0; s < g_GsNS; s++)
{
if (g_GsSegB[s] <= off) r -= (g_GsSegB[s] - g_GsSegA[s]) - g_GsSegN[s];
else break;
}
return r;
}
stock GsCopyRange(in, out, a, b)
{
static buf[2048];
fseek(in, a, SEEK_SET);
while (a < b)
{
new n = min(b - a, sizeof buf);
n = fread_blocks(in, buf, n, BLOCK_CHAR);
if (n <= 0) return;
fwrite_blocks(out, buf, n, BLOCK_CHAR);
a += n;
}
}
stock GsFindSeq(const lab[], nq) { for (new q = 0; q < nq; q++) if (equal(g_GsLab[q], lab)) return q; return -1; }
new bool:g_bGsBoss539;
// 5.3.9c: a giant boss never crouches, swims, flinches or plays 5 different deaths - those sequences now reuse
// the animation data of the basic ones (idle1 / walk / run / knife aim+shoot / death1 / jump) -> much smaller file
stock GsBossRed539(q, nq)
{
new l[33]; copy(l, charsmax(l), g_GsLab[q]);
new t[24]; t[0] = 0;
if (equal(l, "idle1") || equal(l, "walk") || equal(l, "run") || equal(l, "jump") || equal(l, "death1") || equal(l, "ref_aim_knife") || equal(l, "ref_shoot_knife")) return -1;
if (equal(l, "crouch_idle") || equal(l, "swim") || equal(l, "treadwater") || containi(l, "flinch") != -1 || containi(l, "gesture") != -1) copy(t, charsmax(t), "idle1");
else if (equal(l, "crouchrun") || equal(l, "crouch_walk") || equal(l, "crouchwalk")) copy(t, charsmax(t), "walk");
else if (equal(l, "longjump") || equal(l, "superjump")) copy(t, charsmax(t), "jump");
else if (equal(l, "crouch_aim_", 11) || (equal(l, "ref_aim_", 8) && !equal(l, "ref_aim_knife"))) copy(t, charsmax(t), "ref_aim_knife");
else if (equal(l, "crouch_shoot", 12) || equal(l, "ref_shoot", 9) || containi(l, "reload") != -1) copy(t, charsmax(t), "ref_shoot_knife");
else if (containi(l, "death") != -1 || containi(l, "die") != -1) copy(t, charsmax(t), "death1");
if (!t[0]) return -1;
new k = GsFindSeq(t, nq);
return (k >= 0 && k != q && g_GsSeqAi[k] != g_GsSeqAi[q]) ? k : -1;
}
stock GsKnifeOf(q, nq)
{
if (g_bGsBoss539) { new r = GsBossRed539(q, nq); if (r >= 0) return r; }
new l[33]; copy(l, charsmax(l), g_GsLab[q]);
new pre[8], p;
if (equal(l, "ref_", 4)) { copy(pre, charsmax(pre), "ref"); p = 4; }
else if (equal(l, "crouch_", 7)) { copy(pre, charsmax(pre), "crouch"); p = 7; }
else return -1;
new kind[8];
if (equal(l[p], "aim_", 4)) { copy(kind, charsmax(kind), "aim"); p += 4; }
else if (equal(l[p], "shoot2_", 7)) { copy(kind, charsmax(kind), "shoot"); p += 7; }
else if (equal(l[p], "shoot_", 6)) { copy(kind, charsmax(kind), "shoot"); p += 6; }
else if (equal(l[p], "reload_", 7)) { copy(kind, charsmax(kind), "aim"); p += 7; }
else return -1;
new wl = strlen(l[p]);
if (!wl || (wl >= 5 && equal(l[p + wl - 5], "knife"))) return -1;
new t[40]; formatex(t, charsmax(t), "%s_%s_knife", pre, kind);
new k = GsFindSeq(t, nq);
return (k >= 0 && g_GsSeqAi[k] != g_GsSeqAi[q]) ? k : -1;
}
// 5.3.9b: shrunk texture sides are multiples of 4 (odd sizes crash clients: GL_Upload16 s&3)
stock GsDim539(v, f) { new d = v / f; if (f > 1 && d >= 8) d &= ~3; return d; }
bool:GsSlim(const inPath[], const outPath[], maxTex)
{
new in = fopen(inPath, "rb");
if (!in) return false;
new len = GmRdI(in, 72);
if (GmRdI(in, 0) != 0x54534449 || GmRdI(in, 4) != 10 || len != file_size(inPath, 0)) { fclose(in); return false; }
g_GsNP = 0; g_GsNS = 0;
new nq = GmRdI(in, 164), si = GmRdI(in, 168), nsg = GmRdI(in, 172), sgi = GmRdI(in, 176);
new nt = GmRdI(in, 180), ti = GmRdI(in, 184), nsr = GmRdI(in, 192), nsf = GmRdI(in, 196);
new nbp = GmRdI(in, 204), bpi = GmRdI(in, 208);
if (nq < 1 || nq > GS_MAXQ || nt < 0 || nt > GS_MAXT || nbp < 0 || nbp > 32) { fclose(in); return false; }
if (nsg >= 1 && GmRdI(in, sgi + 100) != 0) { fclose(in); return false; }
static const HDRP[] = { 144, 152, 160, 168, 176, 184, 188, 200, 208, 216, 224, 232, 240 };
for (new i = 0; i < sizeof HDRP; i++) GsP(in, HDRP[i], len);
for (new q = 0; q < nq; q++)
{
new o = si + q * 176;
if (GmRdI(in, o + 156) != 0) { fclose(in); return false; }
g_GsSeqO[q] = o; g_GsSeqAi[q] = GmRdI(in, o + 124); g_GsRed[q] = -1;
fseek(in, o, SEEK_SET); fread_blocks(in, g_GsLab[q], 32, BLOCK_CHAR); g_GsLab[q][32] = 0; strtolower(g_GsLab[q]);
if (GmRdI(in, o + 48) > 0) GsP(in, o + 52, len);
if (GmRdI(in, o + 60) > 0) GsP(in, o + 64, len);
GsP(in, o + 88, len); GsP(in, o + 92, len);
}
for (new b = 0; b < nbp; b++)
{
new o = bpi + b * 76, nm = GmRdI(in, o + 64), mi = GmRdI(in, o + 72);
GsP(in, o + 72, len);
for (new m = 0; m < nm && m < 64; m++)
{
new mo = mi + m * 112;
GsP(in, mo + 76, len); GsP(in, mo + 84, len); GsP(in, mo + 88, len); GsP(in, mo + 96, len); GsP(in, mo + 100, len); GsP(in, mo + 108, len);
new nme = GmRdI(in, mo + 72), mei = GmRdI(in, mo + 76);
for (new k = 0; k < nme && k < 256; k++) { GsP(in, mei + k * 20 + 4, len); GsP(in, mei + k * 20 + 16, len); }
}
}
for (new t = 0; t < nt; t++) GsP(in, ti + t * 80 + 76, len);
if (g_GsNP >= GS_MAXP) { fclose(in); return false; }
for (new q = 0; q < nq; q++) g_GsRed[q] = GsKnifeOf(q, nq);
for (new q = 0; q < nq; q++)
{
if (g_GsRed[q] < 0) continue;
new a = g_GsSeqAi[q], bool:used = false, bool:dup = false;
for (new r = 0; r < nq && !used; r++) if (g_GsRed[r] < 0 && g_GsSeqAi[r] == a) used = true;
for (new s = 0; s < g_GsNS && !dup; s++) if (g_GsSegA[s] == a) dup = true;
if (used || dup || a <= 0 || a >= len || g_GsNS >= GS_MAXS) continue;
g_GsSegA[g_GsNS] = a; g_GsSegB[g_GsNS] = GsEnd(a, len, nq); g_GsSegN[g_GsNS] = 0; g_GsSegT[g_GsNS++] = -1;
}
new fmin = 1 << 20;
for (new t = 0; t < nt; t++)
{
new o = ti + t * 80, fl = GmRdI(in, o + 64), w = GmRdI(in, o + 68), h = GmRdI(in, o + 72), ix = GmRdI(in, o + 76), f = 1;
g_GsTexW[t] = w; g_GsTexH[t] = h;
if (maxTex >= 16 && !(fl & 2) && w > 0 && h > 0 && w <= 2048)
while (max(w, h) / f > maxTex && w / (f * 2) >= 16 && h / (f * 2) >= 16) f *= 2;
if (ix <= 0 || ix + w * h + 768 > GsEnd(ix, len, nq)) f = 1;
g_GsTexF[t] = f;
if (f < fmin) fmin = f;
}
for (new t = 0; t < nt; t++)
{
if (nsf > 1) g_GsTexF[t] = fmin;
new f = g_GsTexF[t];
if (f <= 1 || g_GsNS >= GS_MAXS) { g_GsTexF[t] = 1; continue; }
new ix = GmRdI(in, ti + t * 80 + 76), w = g_GsTexW[t], h = g_GsTexH[t];
g_GsSegA[g_GsNS] = ix; g_GsSegB[g_GsNS] = ix + w * h + 768; g_GsSegN[g_GsNS] = GsDim539(w, f) * GsDim539(h, f) + 768; g_GsSegT[g_GsNS++] = t;
}
if (!g_GsNS) { fclose(in); return false; }
for (new i = 1; i < g_GsNS; i++)
for (new j = i; j > 0 && g_GsSegA[j - 1] > g_GsSegA[j]; j--)
{
new x;
x = g_GsSegA[j]; g_GsSegA[j] = g_GsSegA[j - 1]; g_GsSegA[j - 1] = x;
x = g_GsSegB[j]; g_GsSegB[j] = g_GsSegB[j - 1]; g_GsSegB[j - 1] = x;
x = g_GsSegN[j]; g_GsSegN[j] = g_GsSegN[j - 1]; g_GsSegN[j - 1] = x;
x = g_GsSegT[j]; g_GsSegT[j] = g_GsSegT[j - 1]; g_GsSegT[j - 1] = x;
}
for (new i = 1; i < g_GsNS; i++) if (g_GsSegB[i - 1] > g_GsSegA[i]) { fclose(in); return false; }
new out = fopen(outPath, "wb");
if (!out) { fclose(in); return false; }
static row[2048], dst[2048];
new pos = 0;
for (new s = 0; s < g_GsNS; s++)
{
GsCopyRange(in, out, pos, g_GsSegA[s]);
new t = g_GsSegT[s];
if (t >= 0)
{
new f = g_GsTexF[t], w = g_GsTexW[t], h = g_GsTexH[t], nw = GsDim539(w, f), nh = GsDim539(h, f), ix = g_GsSegA[s];
for (new y = 0; y < nh; y++)
{
fseek(in, ix + y * f * w, SEEK_SET);
fread_blocks(in, row, w, BLOCK_CHAR);
for (new x = 0; x < nw; x++) dst[x] = row[x * f];
fwrite_blocks(out, dst, nw, BLOCK_CHAR);
}
GsCopyRange(in, out, ix + w * h, ix + w * h + 768);
}
pos = g_GsSegB[s];
}
GsCopyRange(in, out, pos, len);
fclose(out);
out = fopen(outPath, "r+b");
if (!out) { fclose(in); return false; }
new nlen = GsRemap(len);
for (new i = 0; i < g_GsNP; i++) GsWrI(out, GsRemap(g_GsPos[i]), GsRemap(g_GsVal[i]));
static blk[40];
for (new q = 0; q < nq; q++)
{
new no = GsRemap(g_GsSeqO[q]), r = g_GsRed[q];
if (r >= 0)
{
new to = g_GsSeqO[r];
fseek(in, to + 32, SEEK_SET); fread_blocks(in, blk, 4, BLOCK_CHAR); fseek(out, no + 32, SEEK_SET); fwrite_blocks(out, blk, 4, BLOCK_CHAR);
fseek(in, to + 56, SEEK_SET); fread_blocks(in, blk, 4, BLOCK_CHAR); fseek(out, no + 56, SEEK_SET); fwrite_blocks(out, blk, 4, BLOCK_CHAR);
fseek(in, to + 120, SEEK_SET); fread_blocks(in, blk, 36, BLOCK_CHAR); fseek(out, no + 120, SEEK_SET); fwrite_blocks(out, blk, 36, BLOCK_CHAR);
}
GsWrI(out, no + 124, GsRemap(g_GsSeqAi[r >= 0 ? r : q]));
}
new bool:anyTex = false;
for (new t = 0; t < nt; t++)
{
if (g_GsTexF[t] <= 1) continue;
anyTex = true;
new no = GsRemap(ti + t * 80);
GsWrI(out, no + 68, GsDim539(g_GsTexW[t], g_GsTexF[t])); GsWrI(out, no + 72, GsDim539(g_GsTexH[t], g_GsTexF[t]));
}
GsWrI(out, 72, nlen);
fclose(in);
if (anyTex)
{
new nbpi = GmRdI(out, 208), nski = GmRdI(out, 200), done[256], nd;
for (new b = 0; b < nbp; b++)
{
new o = nbpi + b * 76, nm = GmRdI(out, o + 64), mi = GmRdI(out, o + 72);
for (new m = 0; m < nm && m < 64; m++)
{
new mo = mi + m * 112, nme = GmRdI(out, mo + 72), mei = GmRdI(out, mo + 76);
for (new k = 0; k < nme && k < 256; k++)
{
new tri = GmRdI(out, mei + k * 20 + 4), sref = GmRdI(out, mei + k * 20 + 8), bool:seen = false;
if (sref < 0 || sref >= nsr) continue;
new tx = GsRdS(out, nski + sref * 2);
if (tx < 0 || tx >= nt || g_GsTexF[tx] <= 1) continue;
for (new z = 0; z < nd && !seen; z++) if (done[z] == tri) seen = true;
if (seen) continue;
if (nd < sizeof done) done[nd++] = tri;
new Float:rs = float(GsDim539(g_GsTexW[tx], g_GsTexF[tx])) / float(g_GsTexW[tx]);
new Float:rt = float(GsDim539(g_GsTexH[tx], g_GsTexF[tx])) / float(g_GsTexH[tx]);
new p = tri, guard = 0;
while (p > 0 && p + 2 <= nlen && guard++ < 65536)
{
new n = GsRdS(out, p); p += 2;
if (!n) break;
n = abs(n);
for (new v = 0; v < n; v++, p += 8)
{
new s0 = GsRdS(out, p + 4), t0 = GsRdS(out, p + 6);
fseek(out, p + 4, SEEK_SET);
fwrite(out, floatround(float(s0) * rs, floatround_tozero), BLOCK_SHORT);
fwrite(out, floatround(float(t0) * rt, floatround_tozero), BLOCK_SHORT);
}
}
}
}
}
}
fclose(out);
return true;
}
bool:GmBossGiant(const name[], out[], len, Float:k, tex)
{
if (k < 1.05) return false;
new gname[48], src[160], dst[160], dir[96], t1[160], t2[160], bn[32];
// 5.4.0: the boss model may be a folder name ("vexbos1") or a full path ("models/player/vexmira/boss1.mdl")
if (contain(name, "/") != -1 || containi(name, ".mdl") != -1)
{
if (equali(name, "models/", 7)) copy(src, charsmax(src), name); else formatex(src, charsmax(src), "models/%s", name);
if (containi(src, ".mdl") == -1) add(src, charsmax(src), ".mdl");
new st = 0, n = 0; for (new i = 0; src[i]; i++) if (src[i] == '/') st = i + 1;
for (new i = st; src[i] && src[i] != '.' && n < 13; i++) if (isalnum(src[i]) || src[i] == '_') bn[n++] = src[i];
bn[n] = 0;
copy(t1, charsmax(t1), src); t1[strlen(t1) - 4] = 0; add(t1, charsmax(t1), "T.mdl");
}
else
{
copy(bn, charsmax(bn), name);
formatex(src, charsmax(src), "models/player/%s/%s.mdl", name, name);
formatex(t1, charsmax(t1), "models/player/%s/%sT.mdl", name, name);
}
formatex(gname, charsmax(gname), "%.13s_g%d", bn, (floatround(k * 10.0) * 131 + tex * 7 + file_size(src, 0)) % 10000); // 5.3.9c: short name (engine path limit 63 chars: models/player/N/N.mdl) + tag from scale/texture/source size -> changed model = new file
formatex(dir, charsmax(dir), "models/player/%s", gname);
formatex(dst, charsmax(dst), "%s/%s.mdl", dir, gname);
new mark[32];
formatex(mark, charsmax(mark), "vexgiant534 t%d", tex);
// 5.4.2 PROTECTION: a giant file that already exists and is valid is NEVER rebuilt or rewritten
// (same name + same bytes -> players never download it again). Only a missing / broken file is built.
if (!g_bBuildAllowed565) { if (!CommunityLegacyFileOk(dst)) return false; copy(out,len,gname); return true; }
if (file_exists(dst, true) && !CommunityLegacyFileOk(dst)) { log_amx("[GiantBoss] bozuk dev model siliniyor, yeniden uretilecek: %s", dst); delete_file(dst); }
new bool:built565 = false;
if (!file_exists(dst, true))
{
built565 = true;
if (!file_exists(src, true)) return false;

if (!dir_exists(dir)) mkdir(dir);
if (!GmCopy(src, dst) || !GmPatch(dst, k)) { delete_file(dst); log_amx("[GiantBoss] %s olusturulamadi (dosya/klasor izni?) - normal boyut", dst); return false; }
new tmp[168], s0 = file_size(dst, 0), bool:slim;
formatex(tmp, charsmax(tmp), "%s.tmp", dst);
g_bGsBoss539 = true;
if (GsSlim(dst, tmp, tex) && GmCopy(tmp, dst)) slim = true;
g_bGsBoss539 = false;
delete_file(tmp);
GsMark(dst, mark);
formatex(t2, charsmax(t2), "%s/%sT.mdl", dir, gname);
if (file_exists(t1, true) && !file_exists(t2, true)) GmCopy(t1, t2);
log_amx("[GiantBoss] dev model uretildi: %s (x%.1f) %d KB%s", dst, k, file_size(dst, 0) / 1024, slim ? "" : " (inceltilemedi, tam kopya)");
if (slim) log_amx("[GiantBoss] inceltildi: %d KB -> %d KB (kullanilmayan silah animasyonlari + doku %d px)", s0 / 1024, file_size(dst, 0) / 1024, tex);
}
if (!CommunityLegacyFileOk(dst)) return false;
if (built565) g_iGiantNew542++;
copy(out, len, gname);
return true;
}
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

ModernEvents50() {}
NativePrecache52() {}

NativePrecacheSpecial563() { g_bVmPrecacheLive563=true;VmCuePrecache563(); }
// ============================================================================================
// 5.3.8 ARSENAL-538: special guns on stock bases (m249 / xm1014 / mp5navy / usp / elite).
// Same flow as the Arsenal-8 guns: bought from the core special weapon menu with AP, damage goes
// through the core damage pipeline (core asks vxe_sw_hit for the multiplier), precache through the
// core registry (vxc_pc_*), all stats from vexmira.cfg (vex_res SG<n>_*). A slot without its v_ file
// is hidden.
// ============================================================================================
#define SG_MAX 7
#define SG_TAG 5380
native vxc_res_get(const key[], out[], len);
native vxc_pc_model(const path[]);
native vxc_pc_sound(const path[]);
native vx45_corezombie(id);
new g_szSgName[SG_MAX][48], g_szSgBase[SG_MAX][24], g_szSgV[SG_MAX][96], g_szSgP[SG_MAX][96], g_szSgW[SG_MAX][96];
new g_szSgFire[SG_MAX][200], g_szSgFire2[SG_MAX][96], g_iSgAnim[SG_MAX][6], g_iSgClip[SG_MAX], g_iSgAmmo[SG_MAX], g_iSgCost[SG_MAX], g_iSgFx[SG_MAX];
new Float:g_fSgDmg[SG_MAX], Float:g_fSgRate[SG_MAX], Float:g_fSgKb[SG_MAX], g_iSgRgb[SG_MAX][3], bool:g_bSgOk[SG_MAX], WeaponIdType:g_iSgWid[SG_MAX];
new g_iSgClipPre[33], Float:g_fSgAltAt[33];
new g_iSgEv[31][2];
new g_sprBeam538, g_sprExplo538, g_sprTrail538, g_iSgN, g_iMaxPl538, bool:g_bSgHooked[31];
new const SG_DEF[SG_MAX][][] = {
{"Guitar Summer", "weapon_mp5navy", "1.48", "0.098", "35", "210", "1.7", "0", "45", "255 140 210"},
{"", "", "1", "1", "1", "0", "0", "0", "0", "0 0 0"},
{"CSO RPG-7", "weapon_ak47", "1.0", "1.25", "1", "20", "2.4", "9", "65", "255 100 45"},
{"M3 Shark", "weapon_m3", "1.22", "0.78", "8", "48", "2.3", "12", "60", "110 200 255"},
{"Charger-7", "weapon_m249", "1.25", "0.08", "100", "300", "1.2", "5", "50", "120 200 255"},
{"", "", "1", "1", "1", "0", "0", "0", "0", "0 0 0"},
{"", "", "1", "1", "1", "0", "0", "0", "0", "0 0 0"} };
new g_iSgProjectileModel[4], g_sprSharkExplo;
new g_iSgReloadEnt[33]; new Float:g_fSgReloadAt[33];
// weapon id by entity name (get_weaponid is empty during precache)
WeaponIdType:SgWid(const name[])
{
if (!equal(name, "weapon_", 7)) return WEAPON_NONE;
for (new w = 1; w < 31; w++) if (equali(name[7], WEAPON_KEYNAME[w])) return WeaponIdType:w;
if (equali(name[7], "mp5navy")) return WEAPON_MP5N;
return WEAPON_NONE;
}
SgRes(const key[], const def[], out[], len)
{
out[0] = 0; vxc_res_get(key, out, len);
if (!out[0]) copy(out, len, def);
}
SgList(const list[])
{
new rest[512], one[96]; copy(rest, charsmax(rest), list);
while (rest[0]) { strtok(rest, one, charsmax(one), rest, charsmax(rest), '|'); trim(one); if (one[0]) vxc_pc_sound(one); }
}
SgPick(const list[], out[], len)
{
new n = 1; for (new k = 0; list[k]; k++) if (list[k] == '|') n++;
new want = random(n), rest[200], c; copy(rest, charsmax(rest), list); out[0] = 0;
while (rest[0]) { strtok(rest, out, len, rest, charsmax(rest), '|'); trim(out); if (c++ == want) break; }
}
// 5.4.2 LOAD ORDER FIX: if this plugin is listed before vexmira_core (panel order), core is not ready yet
// (no config, no precache cache) and every file here was skipped ("0 / 5 ozel silah hazir").
// Then core calls vxe_late_precache() at the end of its own precache and everything is loaded there.
native vxc_pc_ready();
new bool:g_bPcDone542;
public plugin_precache()
{
if (!vxc_pc_ready()) { return; }
ExtraPrecache542();
}
public N_LatePrecache542(plugin, params) { ExtraPrecache542(); return 1; }
ExtraPrecache542()
{
if (g_bPcDone542) return;
g_bPcDone542 = true;
UnpcSetup();
ItemsPrecache538();
new key[24], val[512], a[6][8];
for (new i = 0; i < SG_MAX; i++)
{
g_bSgOk[i] = false;
if(i==1 || i==5 || i==6) continue;
formatex(key, charsmax(key), "SG%d_NAME", i + 1); SgRes(key, SG_DEF[i][0], g_szSgName[i], charsmax(g_szSgName[]));
formatex(key, charsmax(key), "SG%d_BASE", i + 1); SgRes(key, SG_DEF[i][1], g_szSgBase[i], charsmax(g_szSgBase[]));
formatex(key, charsmax(key), "SG%d_V", i + 1); SgRes(key, "", g_szSgV[i], charsmax(g_szSgV[]));
formatex(key, charsmax(key), "SG%d_P", i + 1); SgRes(key, "", g_szSgP[i], charsmax(g_szSgP[]));
formatex(key, charsmax(key), "SG%d_W", i + 1); SgRes(key, "", g_szSgW[i], charsmax(g_szSgW[]));
formatex(key, charsmax(key), "SG%d_FIRE", i + 1); SgRes(key, "", g_szSgFire[i], charsmax(g_szSgFire[]));
formatex(key, charsmax(key), "SG%d_FIRE2", i + 1); SgRes(key, "", g_szSgFire2[i], charsmax(g_szSgFire2[]));
formatex(key, charsmax(key), "SG%d_ANIM", i + 1); SgRes(key, "0 4 1 2 1 3", val, charsmax(val));
parse(val, a[0], 7, a[1], 7, a[2], 7, a[3], 7, a[4], 7, a[5], 7);
for (new k = 0; k < 6; k++) g_iSgAnim[i][k] = str_to_num(a[k]);
formatex(key, charsmax(key), "SG%d_DMG", i + 1); SgRes(key, SG_DEF[i][2], val, charsmax(val)); g_fSgDmg[i] = floatclamp(str_to_float(val), 0.1, 20.0);
formatex(key, charsmax(key), "SG%d_RATE", i + 1); SgRes(key, SG_DEF[i][3], val, charsmax(val)); g_fSgRate[i] = floatclamp(str_to_float(val), 0.03, 3.0);
formatex(key, charsmax(key), "SG%d_CLIP", i + 1); SgRes(key, SG_DEF[i][4], val, charsmax(val)); g_iSgClip[i] = clamp(str_to_num(val), 1, 250);
formatex(key, charsmax(key), "SG%d_BPAMMO", i + 1); SgRes(key, SG_DEF[i][5], val, charsmax(val)); g_iSgAmmo[i] = clamp(str_to_num(val), 0, 900);
formatex(key, charsmax(key), "SG%d_KB", i + 1); SgRes(key, SG_DEF[i][6], val, charsmax(val)); g_fSgKb[i] = floatclamp(str_to_float(val), 0.0, 20.0);
formatex(key, charsmax(key), "SG%d_FX", i + 1); SgRes(key, SG_DEF[i][7], val, charsmax(val)); g_iSgFx[i] = clamp(str_to_num(val), 0, 13);
formatex(key, charsmax(key), "SG%d_COST", i + 1); SgRes(key, SG_DEF[i][8], val, charsmax(val)); g_iSgCost[i] = clamp(str_to_num(val), 0, 100000);
formatex(key, charsmax(key), "SG%d_RGB", i + 1); SgRes(key, SG_DEF[i][9], val, charsmax(val));
parse(val, a[0], 7, a[1], 7, a[2], 7); for (new k = 0; k < 3; k++) g_iSgRgb[i][k] = clamp(str_to_num(a[k]), 0, 255);
g_iSgWid[i] = SgWid(g_szSgBase[i]);
if (!g_szSgName[i][0] || !g_szSgV[i][0] || g_iSgWid[i] == WEAPON_NONE || !file_exists(g_szSgV[i], true)) continue;
if (!vxc_pc_model(g_szSgV[i])) continue;
if (g_szSgP[i][0] && (!file_exists(g_szSgP[i], true) || !vxc_pc_model(g_szSgP[i]))) g_szSgP[i][0] = 0;
if (g_szSgW[i][0] && (!file_exists(g_szSgW[i], true) || !vxc_pc_model(g_szSgW[i]))) g_szSgW[i][0] = 0;
SgList(g_szSgFire[i]); SgList(g_szSgFire2[i]);
formatex(key, charsmax(key), "SG%d_SOUNDS", i + 1); SgRes(key, "", val, charsmax(val)); SgList(val);
g_bSgOk[i] = true; g_iSgN++;
}
if (g_iSgN)
{
if (g_bSgOk[2]) {g_iSgProjectileModel[1] = vxc_pc_model("models/vexmira/v550/rpg7/s_rpg7.mdl");vxc_pc_sound("weapons/canon_firebal_exp.wav");}
if (g_bSgOk[3]) { g_iSgProjectileModel[2] = vxc_pc_model("models/vexmira/new/shark/m3dragonm_effect.mdl"); g_sprSharkExplo = vxc_pc_model("sprites/vexmira/new/ef_m3waterbomb.spr"); }
if (g_bSgOk[2]) g_sprTrail538 = vxc_pc_model("sprites/smoke.spr");
g_sprBeam538 = vxc_pc_model("sprites/laserbeam.spr");
g_sprExplo538 = vxc_pc_model("sprites/vexmira/fx563/rpg_blast.spr");
static const EVF[][] = {"m249", "m3", "mp5n", "ak47"};
static const WeaponIdType:EVW[] = {WEAPON_M249, WEAPON_M3, WEAPON_MP5N, WEAPON_AK47};
new ev[48];
for (new k = 0; k < sizeof EVF; k++) { formatex(ev, charsmax(ev), "events/%s.sc", EVF[k]); g_iSgEv[_:EVW[k]][0] = engfunc(EngFunc_PrecacheEvent, 1, ev); }
}
NativePrecacheSpecial563();
log_amx("[Arsenal538] %d / %d ozel silah hazir", g_iSgN, 4);
}
public plugin_cfg()
{
g_iMaxPl538 = get_maxplayers();
for (new i = 0; i < SG_MAX; i++)
{
if (!g_bSgOk[i] || g_bSgHooked[_:g_iSgWid[i]]) continue;
g_bSgHooked[_:g_iSgWid[i]] = true;
RegisterHam(Ham_Item_Deploy, g_szSgBase[i], "SgDeploy", 1);
RegisterHam(Ham_Weapon_PrimaryAttack, g_szSgBase[i], "SgAttackPre", 0);
RegisterHam(Ham_Weapon_PrimaryAttack, g_szSgBase[i], "SgAttackPost", 1);
RegisterHam(Ham_Weapon_Reload, g_szSgBase[i], "SgReloadPre", 0);
RegisterHam(Ham_Item_PostFrame, g_szSgBase[i], "SgPostFrame", 0);
}
if (g_iSgN)
{
register_forward(FM_CmdStart, "SgCmdStart");
register_forward(FM_SetModel, "SgSetModel");
register_forward(FM_PlaybackEvent, "SgEvent");
register_concmd("vex_sg_give", "SgCmdGive", ADMIN_RCON, "<name or #userid> <1..7>");
RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "SgDefaultDeploy", false);
register_touch("vex_sg_projectile", "*", "SgProjectileTouch");
register_think("vex_sg_projectile", "SgProjectileThink");
}
}
SgIndex(weapon)
{
if (!pev_valid(weapon)) return -1;
new i = pev(weapon, pev_impulse) - SG_TAG;
return (0 <= i < SG_MAX && g_bSgOk[i] && get_member(weapon, m_iId) == g_iSgWid[i]) ? i : -1;
}
SgActive(id)
{
if (id < 1 || id > g_iMaxPl538 || !is_user_alive(id) || vx45_corezombie(id)) return -1;
return SgIndex(get_member(id, m_pActiveItem));
}
SgAnim(id, anim)
{
set_pev(id, pev_weaponanim, anim);
if (is_user_bot(id)) return;
message_begin(MSG_ONE, SVC_WEAPONANIM, _, id); write_byte(anim); write_byte(0); message_end();
}
SgGive(id, i)
{
if (i < 0 || i >= SG_MAX || !g_bSgOk[i] || !is_user_alive(id) || vx45_corezombie(id)) return 0;
new slot = (g_iSgWid[i] == WEAPON_USP || g_iSgWid[i] == WEAPON_ELITE) ? 2 : 1;
rg_drop_items_by_slot(id, InventorySlotType:slot);
new w = rg_give_item(id, g_szSgBase[i], GT_REPLACE);
if (w <= 0 || !pev_valid(w)) return 0;
set_pev(w, pev_impulse, SG_TAG + i);
set_member(w, m_Weapon_iClip, g_iSgClip[i]);
rg_set_user_bpammo(id, g_iSgWid[i], g_iSgAmmo[i]);
engclient_cmd(id, g_szSgBase[i]);
SgApplyModels(id, i);
return w;
}
SgApplyModels(id, i)
{
set_pev(id, pev_viewmodel2, g_szSgV[i]);
if (g_szSgP[i][0]) set_pev(id, pev_weaponmodel2, g_szSgP[i]);
SgAnim(id, g_iSgAnim[i][1]);
}
public SgDeploy(weapon)
{
new i = SgIndex(weapon); if (i < 0) return HAM_IGNORED;
new id = get_member(weapon, m_pPlayer); if (id < 1 || id > g_iMaxPl538 || vx45_corezombie(id)) return HAM_IGNORED;
SgApplyModels(id, i);
return HAM_IGNORED;
}
public SgDefaultDeploy(weapon, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal)
{
new i=SgIndex(weapon); if(i<0) return HC_CONTINUE;
new id=get_member(weapon,m_pPlayer);
if(!is_user_alive(id) || vx45_corezombie(id)) return HC_CONTINUE;
SetHookChainArg(2,ATYPE_STRING,g_szSgV[i]);
if(g_szSgP[i][0]) SetHookChainArg(3,ATYPE_STRING,g_szSgP[i]);
SetHookChainArg(4,ATYPE_INTEGER,g_iSgAnim[i][1]);
return HC_CONTINUE;
}
public SgAttackPre(weapon)
{
new i = SgIndex(weapon); if (i < 0) return HAM_IGNORED;
new id = get_member(weapon, m_pPlayer);
if (id < 1 || id > g_iMaxPl538 || !is_user_alive(id)) return HAM_IGNORED;
new clip = get_member(weapon, m_Weapon_iClip);
g_iSgClipPre[id] = clip;
if (g_iSgFx[i] == 9)
{
if (clip > 0 && Float:get_member(weapon, m_Weapon_flNextPrimaryAttack) <= 0.0 && SgProjectileShoot(id, i))
{
set_member(weapon, m_Weapon_iClip, clip - 1);
set_member(weapon, m_Weapon_flNextPrimaryAttack, g_fSgRate[i]);
set_member(weapon, m_Weapon_flNextSecondaryAttack, g_fSgRate[i]);
set_member(weapon, m_Weapon_flTimeWeaponIdle, g_fSgRate[i] + 0.4);
g_iSgClipPre[id] = clip - 1; // the stock bullet attack is suppressed
}
return HAM_SUPERCEDE;
}
return HAM_IGNORED;
}
public SgAttackPost(weapon)
{
new i = SgIndex(weapon); if (i < 0) return HAM_IGNORED;
new id = get_member(weapon, m_pPlayer);
if (id < 1 || id > g_iMaxPl538 || get_member(weapon, m_Weapon_iClip) >= g_iSgClipPre[id]) return HAM_IGNORED;
set_member(weapon, m_Weapon_flNextPrimaryAttack, g_fSgRate[i]);
new snd[96]; SgPick(g_szSgFire[i], snd, charsmax(snd));
if (snd[0]) emit_sound(id, CHAN_WEAPON, snd, 0.85, ATTN_NORM, 0, PITCH_NORM);
if (g_iSgFx[i] == 0 || g_iSgFx[i] == 10) SgFlash(id, i);
new seq = g_iSgAnim[i][2 + random(3)];
SgAnim(id, seq);
return HAM_IGNORED;
}
public SgReloadPre(weapon)
{
new i = SgIndex(weapon); if (i < 0) return HAM_IGNORED;
new id = get_member(weapon, m_pPlayer);
if(id<1 || id>g_iMaxPl538 || !is_user_alive(id)) return HAM_SUPERCEDE;
new clip = get_member(weapon, m_Weapon_iClip);
if (clip >= g_iSgClip[i] || rg_get_user_bpammo(id, g_iSgWid[i]) <= 0) return HAM_SUPERCEDE;
if(g_iSgReloadEnt[id]==weapon && g_fSgReloadAt[id]>get_gametime()) return HAM_SUPERCEDE;
new Float:duration=(i==3 ? 2.4 : i==2 ? 2.2 : i==6 ? 2.7 : 2.8);
g_iSgReloadEnt[id]=weapon;g_fSgReloadAt[id]=get_gametime()+duration;
set_member(id,m_flNextAttack,duration);
set_member(weapon,m_Weapon_flNextPrimaryAttack,duration);
set_member(weapon,m_Weapon_flNextSecondaryAttack,duration);
set_member(weapon,m_Weapon_fInReload,0);
SgAnim(id,g_iSgAnim[i][5]);
return HAM_SUPERCEDE;
}
public SgPostFrame(weapon)
{
new i = SgIndex(weapon); if (i < 0) return HAM_IGNORED;
new id = get_member(weapon, m_pPlayer);
if(id<1 || id>g_iMaxPl538 || g_iSgReloadEnt[id]!=weapon) return HAM_IGNORED;
if(g_fSgReloadAt[id]>get_gametime()) return HAM_SUPERCEDE;
g_iSgReloadEnt[id]=0;
{
new clip = get_member(weapon, m_Weapon_iClip), bp = rg_get_user_bpammo(id, g_iSgWid[i]);
new j = min(g_iSgClip[i] - clip, bp);
if (j > 0) { set_member(weapon, m_Weapon_iClip, clip + j); rg_set_user_bpammo(id, g_iSgWid[i], bp - j); }
}
set_member(weapon, m_Weapon_flNextPrimaryAttack, 0.0);
set_member(weapon, m_Weapon_flNextSecondaryAttack, 0.0);
set_member(id, m_flNextAttack, 0.0);
return HAM_SUPERCEDE;
}
public SgSetModel(ent, const model[])
{
if (!pev_valid(ent) || model[0] != 'm' || model[7] != 'w' || model[8] != '_') return FMRES_IGNORED;
new cls[16]; pev(ent, pev_classname, cls, charsmax(cls));
if (!equal(cls, "weaponbox")) return FMRES_IGNORED;
for (new k = 0; k < 6; k++)
{
new w = get_member(ent, m_WeaponBox_rgpPlayerItems, k);
if (w <= 0 || !pev_valid(w)) continue;
new i = SgIndex(w);
if (i >= 0 && g_szSgW[i][0]) { engfunc(EngFunc_SetModel, ent, g_szSgW[i]); return FMRES_SUPERCEDE; }
}
return FMRES_IGNORED;
}
// the stock fire event (stock sound) is not sent to other players while an Arsenal-538 gun fires; our sound is emitted instead
public SgEvent(flags, invoker, ev)
{
if (invoker < 1 || invoker > g_iMaxPl538) return FMRES_IGNORED;
new i = SgActive(invoker); if (i < 0) return FMRES_IGNORED;
new w = _:g_iSgWid[i];
return (ev == g_iSgEv[w][0] || ev == g_iSgEv[w][1]) ? FMRES_SUPERCEDE : FMRES_IGNORED;
}
// Charger laser and Rail Cannon charged piercing beam.
public SgCmdStart(id,uc)
{
if(!(get_uc(uc,UC_Buttons)&IN_ATTACK2)) return FMRES_IGNORED;
new i=SgActive(id);if(i<0) return FMRES_IGNORED;
if(i!=6) set_uc(uc,UC_Buttons,get_uc(uc,UC_Buttons)&~IN_ATTACK2);
new Float:now=get_gametime();if(now<g_fSgAltAt[id] || g_iSgReloadEnt[id]) return FMRES_IGNORED;
new weapon=get_member(id,m_pActiveItem);
if(weapon<=0 || !pev_valid(weapon) || Float:get_member(id,m_flNextAttack)>0.0 || Float:get_member(weapon,m_Weapon_flNextPrimaryAttack)>0.0) return FMRES_IGNORED;
new fx=g_iSgFx[i],cost=i==2?1:fx==11?8:fx==12?2:fx==13?6:5;
if(get_member(weapon,m_Weapon_iClip)<cost) return FMRES_IGNORED;
if(i==1 || i==2 || i==3 || i==5) {
    if(!SgProjectileShoot(id,i,1)) return FMRES_IGNORED;
} else SgBeamShot(id,i,800.0);
set_member(weapon,m_Weapon_iClip,get_member(weapon,m_Weapon_iClip)-cost);
g_fSgAltAt[id]=now+(i==2?2.5:5.0);
set_member(weapon,m_Weapon_flNextPrimaryAttack,1.0);
set_member(weapon,m_Weapon_flNextSecondaryAttack,1.0);
SgAnim(id,fx==13?6:g_iSgAnim[i][4]);
return FMRES_IGNORED;
}
// Dedicated projectile entities: stock bullets are suppressed for launcher primary fire.
SgProjectileShoot(id, i, alt=0)
{
new ptype = i==2?1:i==3?2:-1;
if (ptype < 0 || !g_iSgProjectileModel[ptype]) return 0;
if(engfunc(EngFunc_NumberOfEntities)>=global_get(glb_maxEntities)-32) return 0;
new ent = create_entity("info_target"); if (!is_valid_ent(ent)) return 0;
entity_set_string(ent, EV_SZ_classname, "vex_sg_projectile");
new Float:o[3], Float:f[3], Float:vel[3]; SgEye(id, o, f);
for (new k = 0; k < 3; k++) o[k] += f[k] * 38.0;
static const mdl[][]={"","models/vexmira/v550/rpg7/s_rpg7.mdl","models/vexmira/new/shark/m3dragonm_effect.mdl",""};
entity_set_model(ent,mdl[ptype]);
entity_set_origin(ent, o);
entity_set_size(ent, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});
entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
entity_set_int(ent, EV_INT_movetype, ptype==1 || ptype==3 ? MOVETYPE_FLY : MOVETYPE_TOSS);
entity_set_edict(ent, EV_ENT_owner, id);
entity_set_int(ent, EV_INT_iuser1, i);
entity_set_int(ent, EV_INT_iuser2, alt);
entity_set_int(ent, EV_INT_iuser3, get_user_userid(id));
entity_set_float(ent, EV_FL_fuser1, get_gametime() + 4.0);
for (new k = 0; k < 3; k++) vel[k] = f[k] * (ptype==1 || ptype==3 ? 1250.0 : 900.0);
vel[2] += ptype==1 || ptype==3 ? 0.0 : 125.0;
entity_set_vector(ent, EV_VEC_velocity, vel);
entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1);
if ((ptype==1 || ptype==3) && g_sprTrail538)
{
message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
write_byte(TE_BEAMFOLLOW); write_short(ent); write_short(g_sprTrail538);
write_byte(8); write_byte(3); write_byte(g_iSgRgb[i][0]); write_byte(g_iSgRgb[i][1]);
write_byte(g_iSgRgb[i][2]); write_byte(170); message_end();
}
SgAnim(id, g_iSgAnim[i][2]);
new snd[96];SgPick(alt?g_szSgFire2[i]:g_szSgFire[i],snd,charsmax(snd));
if(snd[0]) emit_sound(id,CHAN_WEAPON,snd,0.9,ATTN_NORM,0,PITCH_NORM);
return 1;
}
public SgProjectileThink(ent)
{
if (!is_valid_ent(ent)) return;
if (get_gametime() >= entity_get_float(ent, EV_FL_fuser1)) { SgProjectileTouch(ent,0); return; }
entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1);
}
public SgProjectileTouch(ent,touched)
{
if(!is_valid_ent(ent)) return;
new id=entity_get_edict(ent,EV_ENT_owner),i=entity_get_int(ent,EV_INT_iuser1);
if(touched==id && id>=1 && id<=32) return;
if(i<0 || i>=SG_MAX) {remove_entity(ent);return;}
entity_set_int(ent,EV_INT_solid,SOLID_NOT);
new Float:o[3];entity_get_vector(ent,EV_VEC_origin,o);
new spr=i==3?g_sprSharkExplo:g_sprExplo538;
SgExplo(o,spr?spr:g_sprExplo538,i==2?32:26);
new const explosion[][]={"weapons/canon_firebal_exp.wav","weapons/m3dragonm_shark_fx.wav"};
emit_sound(ent,CHAN_ITEM,explosion[i==3?1:0],0.95,ATTN_NORM,0,PITCH_NORM);
if(id>=1 && id<=32 && is_user_connected(id) && get_user_userid(id)==entity_get_int(ent,EV_INT_iuser3) && !vx45_corezombie(id)) {
    new alt=entity_get_int(ent,EV_INT_iuser2);
    new Float:damage=i==2?(alt?1250.0:1050.0):i==5?900.0:i==3?850.0:880.0;
    if(i==2) Blast563(id,ent,o,350.0,damage,1300.0,660.0,0,true);
    else if(touched>=1 && touched<=32 && is_user_alive(touched) && vx45_corezombie(touched)) vxc_area_hit(touched,id,ent,damage);
}
remove_entity(ent);
}
SgEye(id, Float:o[3], Float:f[3])
{
new Float:ofs[3], Float:a[3]; pev(id, pev_origin, o); pev(id, pev_view_ofs, ofs); xs_vec_add(o, ofs, o);
pev(id, pev_v_angle, a); engfunc(EngFunc_MakeVectors, a); global_get(glb_v_forward, f);
}
SgFlash(id, i)
{
new Float:o[3], Float:f[3]; SgEye(id, o, f);
for (new k = 0; k < 3; k++) o[k] += f[k] * 36.0;
engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, o, 0);
write_byte(TE_DLIGHT); engfunc(EngFunc_WriteCoord, o[0]); engfunc(EngFunc_WriteCoord, o[1]);
engfunc(EngFunc_WriteCoord, o[2]); write_byte(11);
write_byte(g_iSgRgb[i][0]); write_byte(g_iSgRgb[i][1]); write_byte(g_iSgRgb[i][2]);
write_byte(2); write_byte(3); message_end();
}
SgBeam(const Float:a[3], const Float:b[3], i, width)
{
if (!g_sprBeam538) return;
engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, a, 0); write_byte(TE_BEAMPOINTS);
engfunc(EngFunc_WriteCoord, a[0]); engfunc(EngFunc_WriteCoord, a[1]); engfunc(EngFunc_WriteCoord, a[2]);
engfunc(EngFunc_WriteCoord, b[0]); engfunc(EngFunc_WriteCoord, b[1]); engfunc(EngFunc_WriteCoord, b[2]);
write_short(g_sprBeam538); write_byte(0); write_byte(0); write_byte(4); write_byte(width); write_byte(2);
write_byte(g_iSgRgb[i][0]); write_byte(g_iSgRgb[i][1]); write_byte(g_iSgRgb[i][2]); write_byte(220); write_byte(30); message_end();
}
SgExplo(const Float:o[3], spr, scale)
{
engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,o,0);write_byte(TE_DLIGHT);
engfunc(EngFunc_WriteCoord,o[0]);engfunc(EngFunc_WriteCoord,o[1]);engfunc(EngFunc_WriteCoord,o[2]+16.0);
write_byte(36);write_byte(255);write_byte(130);write_byte(40);write_byte(4);write_byte(25);message_end();
if (!spr) return;
engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, o, 0); write_byte(TE_EXPLOSION);
engfunc(EngFunc_WriteCoord, o[0]); engfunc(EngFunc_WriteCoord, o[1]); engfunc(EngFunc_WriteCoord, o[2] + 10.0);
write_short(spr); write_byte(scale); write_byte(20); write_byte(TE_EXPLFLAG_NOSOUND); message_end();
}
// Alternate beam detonates at the first entity/world impact.
SgBeamShot(id, i, Float:dmg)
{
new Float:o[3], Float:f[3], Float:e[3]; SgEye(id, o, f);
for (new k = 0; k < 3; k++) e[k] = o[k] + f[k] * 4096.0;
engfunc(EngFunc_TraceLine, o, e, DONT_IGNORE_MONSTERS, id, 0); get_tr2(0, TR_vecEndPos, e);
for(new k=0;k<3;k++) e[k]-=f[k]*6.0;
SgBeam(o, e, i, g_iSgFx[i] == 5 ? 60 : 30);
SgExplo(e,g_sprExplo538,22);
new target=get_tr2(0,TR_pHit);
if(target>=1 && target<=32 && is_user_alive(target) && vx45_corezombie(target)) vxc_area_hit(target,id,get_member(id,m_pActiveItem),dmg);
if (g_szSgFire2[i][0]) emit_sound(id, CHAN_ITEM, g_szSgFire2[i], 0.9, ATTN_NORM, 0, PITCH_NORM);
}

public SgCmdGive(id, level, cid)
{
if (!cmd_access(id, level, cid, 3)) return PLUGIN_HANDLED;
new who[32], n[8]; read_argv(1, who, charsmax(who)); read_argv(2, n, charsmax(n));
if (equal(who, "@all"))
{
new ok, k = str_to_num(n) - 1;
for (new p = 1; p <= g_iMaxPl538; p++) if (is_user_alive(p) && !vx45_corezombie(p) && SgGive(p, k < 0 ? random(SG_MAX) : k)) ok++;
console_print(id, "[Arsenal538] @all slot=%d given=%d", k + 1, ok);
return PLUGIN_HANDLED;
}
new t = cmd_target(id, who, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
if (!t) return PLUGIN_HANDLED;
new i = str_to_num(n) - 1;
console_print(id, "[Arsenal538] slot=%d %s give=%s", i + 1, (0 <= i < SG_MAX) ? g_szSgName[i] : "?", SgGive(t, i) ? "OK" : "FAILED");
return PLUGIN_HANDLED;
}
// called by the core damage pipeline for a bullet hit; returns the damage multiplier (0 = not an Arsenal-538 gun)
public Float:N_SwHit(plugin, params)
{
new att = get_param(1), vic = get_param(2), WeaponIdType:wid = WeaponIdType:get_param(3), head = get_param(4);
new i = SgActive(att); if (i < 0 || g_iSgWid[i] != wid) return 0.0;
new Float:m = g_fSgDmg[i];
new Float:p[3]; pev(vic, pev_origin, p);

if (g_iSgFx[i] == 10 && head) SgExplo(p,g_sprExplo538,4);
return m;
}
public client_disconnected(id) { Disc538(id); }
public N_SwCount(plugin, params) return SG_MAX;
public N_SwInfo(plugin, params)
{
new i = get_param(1); if (i < 0 || i >= SG_MAX || !g_bSgOk[i]) return -1;
set_string(2, g_szSgName[i], get_param(3));
return g_iSgCost[i];
}
public N_SwGive(plugin, params) return SgGive(get_param(1), get_param(2)) ? 1 : 0;
public N_SwActive(plugin, params) return SgActive(get_param(1));
public N_SwRgb(plugin, params) { new i = get_param(1); if (i < 0 || i >= SG_MAX) return 0; return (g_iSgRgb[i][0] << 16) | (g_iSgRgb[i][1] << 8) | g_iSgRgb[i][2]; }
// ============================================================================================
// 5.3.8 UNPRECACHER: the game DLL precaches every stock resource at worldspawn. Resources that can
// never be used in Vexmira (C4 / bomb, hostage, tutor, geiger, bot radio, spray) are refused while
// the worldspawn precache window is open, which frees precache slots (512 limit) and join time.
// Our own resources (registered earlier through the core) are never refused: the engine returns
// their existing index. Sounds only: the game DLL re-precaches some stock MODELS at runtime (shield models on
// knife deploy), so refusing a model would be a Host_Error. vex_res UNPRECACHE "0" turns it off,
// UNPRECACHE_EXTRA adds sound paths.
// ============================================================================================
new const UNPC_SND[][] = {
"weapons/c4_click.wav", "weapons/c4_beep1.wav", "weapons/c4_beep2.wav", "weapons/c4_beep3.wav", "weapons/c4_beep4.wav",
"weapons/c4_beep5.wav", "weapons/c4_explode1.wav", "weapons/c4_plant.wav", "weapons/c4_disarm.wav", "weapons/c4_disarmed.wav",
"radio/locknload.wav", "radio/letsgo.wav", "radio/moveout.wav", "radio/com_go.wav", "radio/rescued.wav", "radio/rounddraw.wav",
"buttons/bell1.wav", "buttons/blip1.wav", "buttons/blip2.wav", "buttons/button11.wav", "buttons/latchunlocked2.wav",
"buttons/lightswitch2.wav", "events/tutor_msg.wav", "events/enemy_died.wav", "events/friend_died.wav", "events/task_complete.wav",
"player/geiger1.wav", "player/geiger2.wav", "player/geiger3.wav", "player/geiger4.wav", "player/geiger5.wav", "player/geiger6.wav",
"common/wpn_hudoff.wav", "common/wpn_hudon.wav", "common/wpn_moveselect.wav", "player/sprayer.wav",
"hostage/hos1.wav", "hostage/hos2.wav", "hostage/hos3.wav", "hostage/hos4.wav", "hostage/hos5.wav" };
new Trie:g_tUnpc, g_iFwUnS, g_iFwUnSpawn, g_iUnpc[2], bool:g_bUnpcWin;
UnpcSetup()
{
new v[200]; vxc_res_get("UNPRECACHE", v, charsmax(v));
if (v[0] && str_to_num(v) <= 0) return;
g_tUnpc = TrieCreate();
for (new i = 0; i < sizeof UNPC_SND; i++) TrieSetCell(g_tUnpc, UNPC_SND[i], 1);
v[0] = 0; vxc_res_get("UNPRECACHE_EXTRA", v, charsmax(v));
new rest[200], one[96]; copy(rest, charsmax(rest), v);
while (rest[0]) { strtok(rest, one, charsmax(one), rest, charsmax(rest), ' '); trim(one); strtolower(one); if (one[0]) TrieSetCell(g_tUnpc, one, 1); }
g_bUnpcWin = true;
g_iFwUnS = register_forward(FM_PrecacheSound, "UnpcSound", 0);
g_iFwUnSpawn = register_forward(FM_Spawn, "UnpcSpawn", 0);
}
public UnpcSound(const s[])
{
if (!g_bUnpcWin) return FMRES_IGNORED;
new low[96]; copy(low, charsmax(low), s); strtolower(low);
if (!TrieKeyExists(g_tUnpc, low)) return FMRES_IGNORED;
g_iUnpc[0]++; forward_return(FMV_CELL, 0); return FMRES_SUPERCEDE;
}
public UnpcSpawn(ent)
{
if (!g_bUnpcWin || !pev_valid(ent)) return FMRES_IGNORED;
new cls[16]; pev(ent, pev_classname, cls, charsmax(cls));
if (equal(cls, "worldspawn")) return FMRES_IGNORED;
UnpcEnd();
return FMRES_IGNORED;
}
UnpcEnd()
{
g_bUnpcWin = false;
if (g_iFwUnS) { unregister_forward(FM_PrecacheSound, g_iFwUnS, 0); g_iFwUnS = 0; }
if (g_iFwUnSpawn) { unregister_forward(FM_Spawn, g_iFwUnSpawn, 0); g_iFwUnSpawn = 0; }
}
public N_Unpc(plugin, params) { UnpcEnd(); new k = get_param(1); return (k == 0 || k == 1) ? g_iUnpc[k] : 0; }
// ============================================================================================
// 5.3.8 ZOMBIE CLASS UPGRADES: every class levels up separately (0..5), points only from
// infections (+1) and zombie kills on humans (+2); bosses / nemesis / assassin earn nothing.
// Thresholds vex_res ZUP_STEPS (hard by default). Per level the core gives the ability
// -6 % cooldown, +6 % range, +8 % damage; level 3+ adds a coloured shock ring on every use.
// Saved per SteamID in nvault "vexmira_zup". Menu: say /upgrade, /yukselt (or console vex_zup).
// ============================================================================================
native vxc_class(id);
native vxc_card(id, arg);
new const ZUP_NAME[24][] = { "Walker", "Runner", "Tank", "Banshee", "Leech", "Stalker", "Bomber", "Frost", "Spitter", "Hulk",
"Voodoo", "Phantom", "Kasap", "Avci", "Boga", "Orumcek", "Magma", "Volt", "Taklitci", "Kostebek", "Siren", "Kale", "Spor Ana", "Kabus" };
#define ZUP_MAX 5
new g_iZupVault = INVALID_HANDLE, g_iZupPts[33][24], g_iZupLvl[33][24], g_iZupStat[33][24][3], g_iZupSelected[33], g_iZupStep[ZUP_MAX], bool:g_bZupLoaded[33];
new g_sprZupRing,g_hZupHud563;
new g_szZupKey563[33][64];
// 6.0: chat language of a player (core keeps the "lang" userinfo in sync: tr / en)
bool:XTr60(id) { new l[4]; get_user_info(id, "lang", l, charsmax(l)); return !equali(l, "en"); }
ZupInit()
{
new v[64];vxc_res_get("ZUP_STEPS",v,charsmax(v));if(!v[0]) copy(v,charsmax(v),"4 8 12 16 20");
new a[ZUP_MAX][8];parse(v,a[0],7,a[1],7,a[2],7,a[3],7,a[4],7);
for(new i=0;i<ZUP_MAX;i++) g_iZupStep[i]=max(i?g_iZupStep[i-1]+1:1,str_to_num(a[i]));
g_iZupVault=nvault_open("vexmira_zup");
if(g_iZupVault==INVALID_HANDLE) log_amx("[ZUP] nVault acilamadi; data/vault klasorunu kontrol edin.");
g_hZupHud563=CreateHudSyncObj();
register_clcmd("say /gelisim","ZupMenu");register_clcmd("say_team /gelisim","ZupMenu");register_clcmd("say /upgrade","ZupMenu");register_clcmd("say /yukselt","ZupMenu");
register_clcmd("say_team /upgrade","ZupMenu");register_clcmd("say_team /yukselt","ZupMenu");
register_clcmd("vex_zup","ZupMenu");
register_concmd("vex_zup_status","ZupStatus563",ADMIN_RCON,"[name or #userid]");
set_task(12.0,"ZupRemind563",563912,_,_,"b");
}
bool:ZupAuthReady565(id) {
if(!is_user_connected(id) || is_user_bot(id)) return false;
new auth[36];get_user_authid(id,auth,charsmax(auth));
return auth[0] && containi(auth,"PENDING")==-1 && containi(auth,"UNKNOWN")==-1 && !equal(auth,"BOT");
}
ZupKey(id,out[],len)
{
if(g_szZupKey563[id][0]) {copy(out,len,g_szZupKey563[id]);return;}
new a[36];get_user_authid(id,a,charsmax(a));
if(!ZupAuthReady565(id)) return;
if(equal(a,"STEAM_ID_LAN") || equal(a,"VALVE_ID_LAN")) get_user_name(id,a,charsmax(a));
formatex(out,len,"zup_%s",a);copy(g_szZupKey563[id],charsmax(g_szZupKey563[]),out);
}
ZupLoad(id)
{
if(!ZupAuthReady565(id)) return;
g_bZupLoaded[id] = true;
for (new c = 0; c < 24; c++) { g_iZupPts[id][c] = 0; g_iZupLvl[id][c] = 0; for(new k=0;k<3;k++) g_iZupStat[id][c][k]=0; }
if (g_iZupVault == INVALID_HANDLE || is_user_bot(id)) return;
new key[64], data[512]; ZupKey(id, key, charsmax(key));
if (!nvault_get(g_iZupVault, key, data, charsmax(data))) return;
new tok[12], c, pos;
while (c < 24 && (pos = argparse(data, pos, tok, charsmax(tok))) != -1) { g_iZupPts[id][c] = clamp(str_to_num(tok),0,100000); g_iZupLvl[id][c] = ZupLevelOf(g_iZupPts[id][c]); c++; }
new perkKey[80];formatex(perkKey,charsmax(perkKey),"zup_perk_%s",key[4]);
if(nvault_get(g_iZupVault,perkKey,data,charsmax(data))) {
pos=0;
for(c=0;c<24;c++) for(new k=0;k<3;k++) {
if((pos=argparse(data,pos,tok,charsmax(tok)))==-1) return;
new spent=g_iZupStat[id][c][0]+g_iZupStat[id][c][1]+g_iZupStat[id][c][2];
g_iZupStat[id][c][k]=clamp(str_to_num(tok),0,max(0,g_iZupLvl[id][c]-spent));
}
}
}
ZupSave(id)
{
if (g_iZupVault == INVALID_HANDLE || !g_bZupLoaded[id] || !g_szZupKey563[id][0]) return;
new key[64], data[512], n[12]; ZupKey(id, key, charsmax(key));
for (new c = 0; c < 24; c++) { formatex(n, charsmax(n), c ? " %d" : "%d", g_iZupPts[id][c]); add(data, charsmax(data), n); }
nvault_set(g_iZupVault, key, data);
data[0]=0;
for(new c=0;c<24;c++) for(new k=0;k<3;k++) {
formatex(n,charsmax(n),(c||k)?" %d":"%d",g_iZupStat[id][c][k]);
add(data,charsmax(data),n);
}
new perkKey[80];formatex(perkKey,charsmax(perkKey),"zup_perk_%s",key[4]);
nvault_set(g_iZupVault,perkKey,data);
}
ZupLevelOf(pts) { new l; while (l < ZUP_MAX && pts >= g_iZupStep[l]) l++; return l; }
public client_putinserver(id) {
g_iZupSelected[id]=0;
g_szZupKey563[id][0]=0;g_bZupLoaded[id]=false;
}
public client_authorized(id) { if(is_user_connected(id) && !g_bZupLoaded[id]) ZupLoad(id); }
public N_ZupLevel(plugin, params) { new id = get_param(1), c = get_param(2); if (id < 1 || id > 32 || c < 0 || c >= 24) return 0; if (!g_bZupLoaded[id] && ZupAuthReady565(id)) ZupLoad(id); return g_iZupLvl[id][c]; }
public N_ZupStat(plugin, params) { new id=get_param(1),c=get_param(2),k=get_param(3);if(id<1||id>32||c<0||c>=24||k<0||k>=3)return 0;if(!g_bZupLoaded[id] && ZupAuthReady565(id))ZupLoad(id);return g_iZupStat[id][c][k]; }
public N_ZupAdd(plugin,params)
{
new id=get_param(1),pts=get_param(2);
if(id<1 || id>32 || pts<=0 || !is_user_connected(id)) return 0;
new c=params>=3?get_param(3):-1;if(c<0) c=vxc_class(id);
if(c<0 || c>=24) return 0;
if(!g_bZupLoaded[id] && ZupAuthReady565(id)) ZupLoad(id);
if(!g_bZupLoaded[id]) return 0;
new old=g_iZupLvl[id][c];
g_iZupPts[id][c]=min(g_iZupPts[id][c]+pts,100000);
g_iZupLvl[id][c]=ZupLevelOf(g_iZupPts[id][c]);
g_iZupSelected[id]=c;
new next=g_iZupLvl[id][c]<ZUP_MAX?g_iZupStep[g_iZupLvl[id][c]]:g_iZupStep[ZUP_MAX-1];
if(!is_user_bot(id)) client_print_color(id,print_team_default,XTr60(id)?"^4[Vexmira]^1 %s: ^4+%d^1 gelisim (%d/%d). Menu: ^3/yukselt":"^4[Vexmira]^1 %s: ^4+%d^1 upgrade points (%d/%d). Menu: ^3/upgrade",ZUP_NAME[c],pts,g_iZupPts[id][c],next);
if(g_iZupLvl[id][c]>old) ZupLevelUp(id,c);
ZupSave(id);return g_iZupLvl[id][c];
}
ZupLevelUp(id,c)
{
new lv=g_iZupLvl[id][c];
client_print_color(id,print_team_default,XTr60(id)?"^4[Vexmira]^1 %s seviye ^4%d^1! Gelistirme puanin var: ^3/yukselt^1 yaz, sinifini ve gelistirecegin skilli sec.":"^4[Vexmira]^1 %s level ^4%d^1! You have an upgrade point: type ^3/upgrade^1 and pick the skill to improve.",ZUP_NAME[c],lv);
if(!is_user_bot(id)) client_cmd(id,"spk ^"items/suitchargeok1.wav^"");
new Float:o[3];pev(id,pev_origin,o);ZupRing(o,lv,280);
message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("ScreenFade"),_,id);
write_short(1<<10);write_short(1<<10);write_short(0);write_byte(255);write_byte(195);write_byte(45);write_byte(65);message_end();
g_iZupSelected[id]=c;ZupHint563(id,c);
}
ZupRing(const Float:o[3], lv, radius)
{
if (!g_sprZupRing) return;
static const RGB[6][3] = { {120, 255, 40}, {120, 255, 40}, {80, 220, 255}, {255, 210, 60}, {255, 120, 40}, {220, 60, 255} };
new k = clamp(lv, 0, 5);
engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, o, 0); write_byte(TE_BEAMCYLINDER);
engfunc(EngFunc_WriteCoord, o[0]); engfunc(EngFunc_WriteCoord, o[1]); engfunc(EngFunc_WriteCoord, o[2] - 16.0);
engfunc(EngFunc_WriteCoord, o[0]); engfunc(EngFunc_WriteCoord, o[1]); engfunc(EngFunc_WriteCoord, o[2] - 16.0 + float(radius));
write_short(g_sprZupRing); write_byte(0); write_byte(0); write_byte(6); write_byte(12 + 4 * k); write_byte(0);
write_byte(RGB[k][0]); write_byte(RGB[k][1]); write_byte(RGB[k][2]); write_byte(200); write_byte(0); message_end();
}
public N_ZupUsed(plugin, params)
{
new id = get_param(1), lv = get_param(2);
if (lv < 3 || !is_user_alive(id)) return 0;
new Float:o[3]; pev(id, pev_origin, o); ZupRing(o, lv, 180 + 40 * (lv - 3));
return 1;
}
public ZupMenu(id)
{
if (!g_bZupLoaded[id] && ZupAuthReady565(id)) ZupLoad(id);
new title[160], line[96], cur = vxc_class(id);
formatex(title, charsmax(title), "\wZombi Sinif Yukseltme  \d(enfekte +1, insan oldur +2)");
new m = menu_create(title, "ZupMenuH");
for (new c = 0; c < 24; c++)
{
new lv = g_iZupLvl[id][c], need = lv < ZUP_MAX ? g_iZupStep[lv] : 0;
if (lv < ZUP_MAX) formatex(line, charsmax(line), "\w%s %s\d Sv %d  %d/%d", ZUP_NAME[c], c == cur ? "\w*" : "", lv, g_iZupPts[id][c], need);
else formatex(line, charsmax(line), "\w%s %s\d Sv %d  MAKS", ZUP_NAME[c], c == cur ? "\w*" : "", lv);
new available[24];formatex(available,charsmax(available)," | Bos: %d",ZupFree563(id,c));add(line,charsmax(line),available);
menu_additem(m, line);
}
menu_setprop(m, MPROP_NUMBER_COLOR, "\r");
menu_display(id, m, 0);
return PLUGIN_HANDLED;
}
public ZupMenuH(id, m, item)
{
menu_destroy(m);
if(item>=0 && item<24){g_iZupSelected[id]=item;ClearSyncHud(id,g_hZupHud563);ZupOpenSelected(id);}
return PLUGIN_HANDLED;
}
public ZupOpenSelected(id)
{
if(!is_user_connected(id)||!g_bZupLoaded[id])return PLUGIN_HANDLED;
new c=g_iZupSelected[id];if(c<0||c>=24)return PLUGIN_HANDLED;
new used=g_iZupStat[id][c][0]+g_iZupStat[id][c][1]+g_iZupStat[id][c][2];
new title[128],line[96];
formatex(title,charsmax(title),"%s Seviye %d | %d bos puan",ZUP_NAME[c],g_iZupLvl[id][c],max(0,g_iZupLvl[id][c]-used));
new m=menu_create(title,"ZupPerkSelect");
formatex(line,charsmax(line),"Bekleme: -%d%% -> -%d%%",g_iZupStat[id][c][0]*6,(g_iZupStat[id][c][0]+1)*6);menu_additem(m,line);
formatex(line,charsmax(line),"Menzil: +%d%% -> +%d%%",g_iZupStat[id][c][1]*6,(g_iZupStat[id][c][1]+1)*6);menu_additem(m,line);
formatex(line,charsmax(line),"Hasar: +%d%% -> +%d%%",g_iZupStat[id][c][2]*8,(g_iZupStat[id][c][2]+1)*8);menu_additem(m,line);
menu_display(id,m);return PLUGIN_HANDLED;
}
public ZupPerkSelect(id,m,item)
{
menu_destroy(m);
if(item<0||item>=3||!is_user_connected(id))return PLUGIN_HANDLED;
new c=g_iZupSelected[id];if(c<0||c>=24)return PLUGIN_HANDLED;
new used=g_iZupStat[id][c][0]+g_iZupStat[id][c][1]+g_iZupStat[id][c][2];
if(used>=g_iZupLvl[id][c]){ClearSyncHud(id,g_hZupHud563);client_print_color(id,print_team_default,XTr60(id)?"^4[VEXMIRA]^1 Bosta gelistirme puanin yok.":"^4[VEXMIRA]^1 You have no free upgrade points.");return PLUGIN_HANDLED;}
g_iZupStat[id][c][item]++;ZupSave(id);ClearSyncHud(id,g_hZupHud563);ZupHint563(id,c);
client_print_color(id,print_team_default,XTr60(id)?"^4[VEXMIRA]^1 %s gelistirildi. Kalan puan: %d":"^4[VEXMIRA]^1 %s upgraded. Points left: %d",ZUP_NAME[c],g_iZupLvl[id][c]-used-1);
ZupOpenSelected(id);return PLUGIN_HANDLED;
}
// ============================================================================================
// 5.3.8 SHOP ITEMS (core shop menu, AP): 0 = infection mask (human: blocks one infection hit,
// worn model vex_res ITEM_MASK_MODEL), 1 = zombie armor (zombie: -40 % damage until the armor
// pool is gone, worn model vex_res ITEM_ZARMOR_MODEL). Prices / values in vexmira.cfg.
// ============================================================================================
native vxc_set_model(id, const model[]);
native vxc_restore_model(id);
new g_szItMask[32], g_szItArmor[32], g_iItCost[2], g_iItArmorHp, Float:g_fItArmorCut, bool:g_bItOk[2], bool:g_bItMdl[2];
new bool:g_bMask[33], Float:g_fZArmor[33];
ItemsPrecache538()
{
new v[96], mdl[128];
vxc_res_get("ITEM_MASK_MODEL", g_szItMask, charsmax(g_szItMask)); 
vxc_res_get("ITEM_ZARMOR_MODEL", g_szItArmor, charsmax(g_szItArmor)); 
v[0] = 0; vxc_res_get("ITEM_MASK_COST", v, charsmax(v)); g_iItCost[0] = v[0] ? str_to_num(v) : 30;
v[0] = 0; vxc_res_get("ITEM_ZARMOR_COST", v, charsmax(v)); g_iItCost[1] = v[0] ? str_to_num(v) : 25;
v[0] = 0; vxc_res_get("ITEM_ZARMOR_HP", v, charsmax(v)); g_iItArmorHp = v[0] ? clamp(str_to_num(v), 50, 50000) : 1500;
v[0] = 0; vxc_res_get("ITEM_ZARMOR_CUT", v, charsmax(v)); g_fItArmorCut = v[0] ? floatclamp(str_to_float(v), 0.05, 0.9) : 0.4;
for (new k = 0; k < 2; k++)
{
new nm[32]; copy(nm, charsmax(nm), k ? g_szItArmor : g_szItMask);
// 5.3.9a: the item is sold even without a model (model = optional look only)
g_bItOk[k] = g_iItCost[k] > 0;
g_bItMdl[k] = false;
if (!nm[0]) continue;
formatex(mdl, charsmax(mdl), "models/player/%s/%s.mdl", nm, nm);
if (file_exists(mdl, true) && vxc_pc_model(mdl)) g_bItMdl[k] = true;
}
g_sprZupRing = vxc_pc_model("sprites/shockwave.spr");
}
public N_ItemCount(plugin, params) return 2;
public N_ItemInfo(plugin, params)
{
new k = get_param(1), team = get_param(2);
if (k < 0 || k > 1 || !g_bItOk[k] || team != k) return -1;
set_string(3, k ? "Zombi Zirhi / Zombie Armor" : "Enfeksiyon Maskesi / Infection Mask", get_param(4));
return g_iItCost[k];
}
public N_ItemBuy(plugin, params)
{
new id = get_param(1), k = get_param(2);
if (id < 1 || id > 32 || !is_user_alive(id) || k < 0 || k > 1 || !g_bItOk[k]) return 0;
new z = vx45_corezombie(id);
if (k == 0) { if (z || g_bMask[id]) return 0; g_bMask[id] = true; if (g_bItMdl[0]) vxc_set_model(id, g_szItMask); client_print_color(id, print_team_default, XTr60(id) ? "^4[VEXMIRA]^1 Maske takildi: ^4bir sonraki enfeksiyonu engeller^1." : "^4[VEXMIRA]^1 Mask on: ^4it blocks the next infection^1."); }
else { if (!z || g_fZArmor[id] > 0.0) return 0; g_fZArmor[id] = float(g_iItArmorHp); if (g_bItMdl[1]) vxc_set_model(id, g_szItArmor); client_print_color(id, print_team_default, XTr60(id) ? "^4[VEXMIRA]^1 Zirh giyildi: ^4%d^1 hasar boyunca %%%d daha az hasar." : "^4[VEXMIRA]^1 Armor on: %%%d less damage for the next ^4%d^1 damage.", XTr60(id) ? g_iItArmorHp : floatround(g_fItArmorCut * 100.0), XTr60(id) ? floatround(g_fItArmorCut * 100.0) : g_iItArmorHp); }
emit_sound(id, CHAN_ITEM, "items/ammopickup2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM);
return 1;
}
public N_MaskBlock(plugin, params)
{
new v = get_param(1);
if (v < 1 || v > 32 || !g_bMask[v]) return 0;
g_bMask[v] = false;
emit_sound(v, CHAN_BODY, "player/bhit_helmet-1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, v);
write_short(1 << 11); write_short(1 << 9); write_short(0); write_byte(60); write_byte(255); write_byte(90); write_byte(90); message_end();
client_print_color(v, print_team_default, XTr60(v) ? "^4[VEXMIRA]^1 Maske enfeksiyonu ^4engelledi^1 ve kirildi!" : "^4[VEXMIRA]^1 Your mask ^4blocked^1 the infection and broke!");
if (g_bItMdl[0]) vxc_restore_model(v);
return 1;
}
public Float:N_ZArmorHit(plugin, params)
{
new v = get_param(1); new Float:d = get_param_f(2);
if (v < 1 || v > 32 || g_fZArmor[v] <= 0.0) return d;
new Float:cut = d * g_fItArmorCut;
g_fZArmor[v] -= cut;
if (g_fZArmor[v] <= 0.0) { g_fZArmor[v] = 0.0; emit_sound(v, CHAN_BODY, "debris/metal2.wav", 0.9, ATTN_NORM, 0, PITCH_NORM); client_print(v, print_center, "ZIRH KIRILDI"); if (g_bItMdl[1]) vxc_restore_model(v); }
return d - cut;
}
public ItemsReset538() {
new ent;while((ent=find_ent_by_class(ent,"vex_sg_projectile"))>0) remove_entity(ent);
for(new i=1;i<=32;i++) {g_bMask[i]=false;g_fZArmor[i]=0.0;g_iSgReloadEnt[i]=0;g_fSgReloadAt[i]=0.0;g_fSgAltAt[i]=0.0;g_iLaunchPass563[i]=0;g_fLegacyAlt563[i]=0.0;}
}
public ItemsSpawn538(id) { if (is_user_alive(id)) { g_bMask[id] = false; g_fZArmor[id] = 0.0; g_iSgReloadEnt[id]=0;g_fSgReloadAt[id]=0.0;g_fSgAltAt[id]=0.0;g_fLegacyAlt563[id]=0.0; } }
Disc538(id)
{
ZupSave(id);
g_bZupLoaded[id]=false;g_szZupKey563[id][0]=0;g_bMask[id]=false;g_fZArmor[id]=0.0;
g_iSgReloadEnt[id]=0;g_fSgReloadAt[id]=0.0;g_fSgAltAt[id]=0.0;
g_iSoundWeapon563[id]=0;g_iSoundCursor563[id]=0;
g_iLaunchPass563[id]=0;g_fLegacyAlt563[id]=0.0;
for(new k=0;k<16;k++) g_szWeaponSound563[id][k][0]=0;
}
// test helper (rcon): humans get the mask, zombies the armor and +N upgrade points on their class
public Cmd538Test(id, level, cid)
{
if (!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED;
new a[8]; read_argv(1, a, charsmax(a)); new pts = max(0, str_to_num(a)), m, z, up;
for (new p = 1; p <= 32; p++)
{
if (!is_user_alive(p)) continue;
new z0 = vx45_corezombie(p);
if (!z0 && g_bItOk[0] && !g_bMask[p]) { g_bMask[p] = true; if (g_bItMdl[0]) vxc_set_model(p, g_szItMask); m++; }
if (z0 && g_bItOk[1] && g_fZArmor[p] <= 0.0) { g_fZArmor[p] = float(g_iItArmorHp); if (g_bItMdl[1]) vxc_set_model(p, g_szItArmor); z++; }
new c = z0 ? vxc_class(p) : -1;
if (pts && c >= 0)
{
if (!g_bZupLoaded[p]) ZupLoad(p);
new old = g_iZupLvl[p][c]; g_iZupPts[p][c] += pts; g_iZupLvl[p][c] = ZupLevelOf(g_iZupPts[p][c]);
if (g_iZupLvl[p][c] > old) { ZupLevelUp(p, c); up++; }
}
}
console_print(id, "[538test] mask=%d armor=%d levelups=%d", m, z, up);
log_amx("[538test] mask=%d armor=%d levelups=%d", m, z, up);
return PLUGIN_HANDLED;
}

// 5.6.3: one blast/launch path for all alternate attacks.
native vx563_cancel_weapon_tasks(id);
public N_Blast563(plugin,params) {
#pragma unused plugin,params
return 0;
}
Blast563(owner,inflictor,const Float:origin[3],Float:radius,Float:damage,Float:force,Float:lift,skip=0,bool:selfLaunch=false)
{
if(owner<1 || owner>32 || !is_user_connected(owner)) return 0;
radius=floatclamp(radius*BlastScale563("BLAST_RADIUS_SCALE"),64.0,450.0);
damage*=BlastScale563("BLAST_DAMAGE_SCALE");force*=BlastScale563("BLAST_FORCE_SCALE");lift*=BlastScale563("BLAST_LIFT_SCALE");
new Float:o[3];xs_vec_copy(origin,o);o[2]+=16.0;
new hits,tr=create_tr2();
for(new v=1;v<=g_iMaxPl538;v++) {
    if((v==owner && !selfLaunch) || !is_user_alive(v)) continue;
    new Float:p[3];pev(v,pev_origin,p);p[2]+=20.0;
    new Float:dist=get_distance_f(o,p);if(dist>radius) continue;
    engfunc(EngFunc_TraceLine,o,p,IGNORE_MONSTERS,inflictor>0?inflictor:owner,tr);
    new Float:frac;get_tr2(tr,TR_flFraction,frac);
    if(frac<0.98 || get_tr2(tr,TR_StartSolid)) continue;
    if(v!=owner && v!=skip && damage>0.0) vxc_area_hit(v,owner,inflictor,damage*(1.0-0.35*dist/radius));
    if(!is_user_alive(v)) continue;
    new Float:dx=p[0]-o[0],Float:dy=p[1]-o[1],Float:len=floatsqroot(dx*dx+dy*dy);
    if(len<1.0) {dx=1.0;dy=0.0;len=1.0;}
    new Float:k=1.0-0.25*dist/radius;
    g_fLaunch563[v][0]=dx/len*floatclamp(force*k,400.0,1600.0);
    g_fLaunch563[v][1]=dy/len*floatclamp(force*k,400.0,1600.0);
    g_fLaunch563[v][2]=floatclamp(lift*k,400.0,800.0);
    g_iLaunchUser563[v]=get_user_userid(v);g_iLaunchPass563[v]=2;
    RequestFrame("LaunchFrame563",v);hits++;
}
free_tr2(tr);
return hits;
}
public LaunchFrame563(v)
{
if(v<1 || v>32 || !g_iLaunchPass563[v] || !is_user_alive(v) || get_user_userid(v)!=g_iLaunchUser563[v]) return;
set_pev(v,pev_flags,pev(v,pev_flags)&~FL_ONGROUND);
set_pev(v,pev_groundentity,0);
set_pev(v,pev_velocity,g_fLaunch563[v]);
if(--g_iLaunchPass563[v]>0) RequestFrame("LaunchFrame563",v);
}
public N_LegacyMelee563(plugin,params) {
#pragma unused plugin,params
return 0;
}

// All special model cues are server-controlled and stop selectively via SND_STOP.
WeaponLifecycleInit563()
{
static const classes[][]={"weapon_knife","weapon_p228","weapon_scout","weapon_xm1014","weapon_mac10","weapon_aug","weapon_elite","weapon_fiveseven","weapon_ump45","weapon_sg550","weapon_galil","weapon_famas","weapon_usp","weapon_glock18","weapon_awp","weapon_mp5navy","weapon_m249","weapon_m3","weapon_m4a1","weapon_tmp","weapon_g3sg1","weapon_deagle","weapon_sg552","weapon_ak47","weapon_p90"};
for(new k=0;k<sizeof classes;k++) RegisterHam(Ham_Item_Holster,classes[k],"WeaponHolster563",0);
register_forward(FM_EmitSound,"WeaponEmit563",1);
register_forward(FM_PlayerPreThink,"WeaponObserve563",0);
RegisterHam(Ham_Killed,"player","WeaponDeath563",0);
register_clcmd("drop","WeaponDrop563");
}
bool:WeaponSoundPath563(const path[])
{
return equal(path,"weapons/",8) || equal(path,"YouTuber/",9) || containi(path,"/arsenal/")!=-1 || containi(path,"/melee/")!=-1 || containi(path,"/native/")!=-1;
}
public WeaponObserve563(id)
{
if(!is_user_alive(id)) return FMRES_IGNORED;
new w=get_member(id,m_pActiveItem);
if(w!=g_iSoundWeapon563[id]) {
    if(g_iSoundWeapon563[id]) WeaponStop563(id);
    g_iSoundWeapon563[id]=w;
}
VmObserve563(id);
return FMRES_IGNORED;
}
public WeaponEmit563(id,channel,const sample[],Float:vol,Float:att,flags,pitch)
{
#pragma unused vol,att,pitch
if(id<1 || id>32 || g_bStopping563[id] || (flags&SND_STOP) || !WeaponSoundPath563(sample)) return FMRES_IGNORED;
for(new k=0;k<16;k++) if(g_iSoundChannel563[id][k]==channel && equal(g_szWeaponSound563[id][k],sample)) return FMRES_IGNORED;
new k=g_iSoundCursor563[id]++%16;
copy(g_szWeaponSound563[id][k],charsmax(g_szWeaponSound563[][]),sample);
g_iSoundChannel563[id][k]=channel;
return FMRES_IGNORED;
}
WeaponStop563(id)
{
if(id<1 || id>32 || g_bStopping563[id]) return;
g_bStopping563[id]=true;
vx563_cancel_weapon_tasks(id);
for(new k=0;k<16;k++) {
    if(g_szWeaponSound563[id][k][0]) emit_sound(id,g_iSoundChannel563[id][k],g_szWeaponSound563[id][k],0.0,ATTN_NORM,SND_STOP,PITCH_NORM);
    g_szWeaponSound563[id][k][0]=0;
}
g_iVmModel563[id]=-1;g_iVmString563[id]=0;g_iVmSeq563[id]=-1;g_iVmCursor563[id]=0;g_bVmRestart563[id]=false;
g_iSoundCursor563[id]=0;g_iSoundWeapon563[id]=0;
g_iSgReloadEnt[id]=0;g_fSgReloadAt[id]=0.0;
g_bStopping563[id]=false;
}
public N_WeaponStop563(plugin,params) {WeaponStop563(get_param(1));return 1;}
public WeaponHolster563(w) {new id=get_member(w,m_pPlayer);WeaponStop563(id);return HAM_IGNORED;}
public WeaponDeath563(id,attacker,gib) {
#pragma unused attacker,gib
WeaponStop563(id);return HAM_IGNORED;
}
public WeaponDrop563(id) {WeaponStop563(id);return PLUGIN_CONTINUE;}

ZupFree563(id,c) {return max(0,g_iZupLvl[id][c]-g_iZupStat[id][c][0]-g_iZupStat[id][c][1]-g_iZupStat[id][c][2]);}
ZupHint563(id,c)
{
if(!is_user_connected(id) || is_user_bot(id)) return;
if(c<0 || c>=24 || !ZupFree563(id,c)) {ClearSyncHud(id,g_hZupHud563);return;}
set_hudmessage(255,200,55,-1.0,0.81,0,0.0,8.0,0.2,0.3,-1);
ShowSyncHudMsg(id,g_hZupHud563,"GELISTIRME PUANIN VAR! %s: %d bos puan^nSohbete /yukselt yaz > Sinifini sec > Skilli gelistir",ZUP_NAME[c],ZupFree563(id,c));
}
public ZupRemind563()
{
for(new id=1;id<=32;id++) {
    if(!is_user_connected(id) || is_user_bot(id) || !g_bZupLoaded[id]) continue;
    ZupHint563(id,g_iZupSelected[id]);
}
}
public ZupStatus563(id,level,cid)
{
if(!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED;
new who[32];read_argv(1,who,charsmax(who));
new target=who[0]?cmd_target(id,who,CMDTARGET_ALLOW_SELF):id;
if(target<1 || target>32 || !is_user_connected(target)) return PLUGIN_HANDLED;
if(!g_bZupLoaded[target]) ZupLoad(target);
new key[64];ZupKey(target,key,charsmax(key));
console_print(id,"[ZUP] loaded=%d vault=%d key=%s steps=%d/%d/%d/%d/%d",g_bZupLoaded[target],g_iZupVault,key,g_iZupStep[0],g_iZupStep[1],g_iZupStep[2],g_iZupStep[3],g_iZupStep[4]);
for(new c=0;c<24;c++) if(g_iZupPts[target][c] || g_iZupLvl[target][c]) console_print(id,"%s xp=%d level=%d free=%d perks=%d/%d/%d",ZUP_NAME[c],g_iZupPts[target][c],g_iZupLvl[target][c],ZupFree563(target,c),g_iZupStat[target][c][0],g_iZupStat[target][c][1],g_iZupStat[target][c][2]);
return PLUGIN_HANDLED;
}
public plugin_end()
{
if(g_hPlus622!=INVALID_HANDLE)nvault_close(g_hPlus622);
for(new id=1;id<=32;id++) if(is_user_connected(id)) ZupSave(id);
if(g_iZupVault!=INVALID_HANDLE) nvault_close(g_iZupVault);
if(g_tUnpc!=Invalid_Trie) TrieDestroy(g_tUnpc);
if(g_tVm563!=Invalid_Trie) TrieDestroy(g_tVm563);
}

Float:BlastScale563(const key[])
{
new v[24];vxc_res_get(key,v,charsmax(v));return v[0]?floatclamp(str_to_float(v),0.5,2.0):1.0;
}

public N_AudioModel563(plugin,params)
{
new src[128],tag[16],out[96];get_string(1,src,charsmax(src));get_string(2,tag,charsmax(tag));
new ok=AudioModel563(src,tag,out,charsmax(out));set_string(3,out,get_param(4));return ok;
}
public N_AudioConfig563(plugin,params)
{
new key[32],tag[16],src[128],out[96];
for(new group=0;group<3;group++) {
    new count=group==0?8:group==1?6:7;
    for(new i=0;i<count;i++) {
        if((group==1 && i==3) || (group==2 && (i==1 || i==5 || i==6))) continue;
        if(group==0) {formatex(key,charsmax(key),"SW%d_VMODEL",i);formatex(tag,charsmax(tag),"sw%d",i);}
        else {formatex(key,charsmax(key),"%s%d_V",group==1?"MK":"SG",i+1);formatex(tag,charsmax(tag),"%s%d",group==1?"mk":"sg",i+1);}
        src[0]=0;vxc_res_get(key,src,charsmax(src));
        if(src[0] && AudioModel563(src,tag,out,charsmax(out))) vxc_res_set(key,out);
    }
}
return g_iVmCount563;
}
AudioModel563(const src[],const tag[],out[],len)
{
copy(out,len,src);
if(!file_exists(src,true) || g_iVmCount563>=VM_MODELS563) return 0;
new fp=fopen(src,"rb",true);if(!fp) return 0;
new bytes=GmRdI(fp,72),num=GmRdI(fp,164),seq=GmRdI(fp,168),groups=GmRdI(fp,172);
if(GmRdI(fp,0)!=0x54534449 || GmRdI(fp,4)!=10 || bytes<244 || bytes!=file_size(src) || num<1 || num>VM_SEQS563 || seq<244 || seq+num*176>bytes || groups<1 || groups>32) {fclose(fp);return 0;}
new total;
for(new i=0;i<num;i++) {
    new n=GmRdI(fp,seq+i*176+48),o=GmRdI(fp,seq+i*176+52);
    if(n<0 || n>256 || (n && (o<244 || o+n*76>bytes))) {fclose(fp);return 0;}
    total+=n;
}
if(total+g_iVmEventCount563>VM_EVENTS563) {fclose(fp);return 0;}
new crc[16];if(!hash_file(src,Hash_Crc32,crc,charsmax(crc))) {fclose(fp);return 0;}
strtolower(crc);
formatex(out,len,"models/vexmira/a563/%s_%s.mdl",tag,crc);
if(GmRdI(fp,180)==0) {
    new texture[128];copy(texture,charsmax(texture),out);texture[strlen(texture)-4]=0;add(texture,charsmax(texture),"T.mdl");
    if(!file_exists(texture,true)) {fclose(fp);copy(out,len,src);return 0;}
}
if(g_tVm563==Invalid_Trie) g_tVm563=TrieCreate();
new existing;if(TrieGetCell(g_tVm563,out,existing)) {fclose(fp);return 1;}
if(!dir_exists("models/vexmira/a563")) mkdir("models/vexmira/a563");
new bool:fresh=!file_exists(out,true) || file_size(out)!=bytes;
if(fresh && !GmCopy(src,out)) {fclose(fp);copy(out,len,src);return 0;}
new dst=fopen(out,"r+b");if(!dst) {fclose(fp);copy(out,len,src);return 0;}
new m=g_iVmCount563++;
copy(g_szVmPath563[m],charsmax(g_szVmPath563[]),out);TrieSetCell(g_tVm563,out,m+1);
for(new i=0;i<num;i++) {
    new q=seq+i*176,n=GmRdI(fp,q+48),o=GmRdI(fp,q+52);
    new Float:fps=GmRdF(fp,q+32);g_fVmLength563[m][i]=floatmax(0.05,float(GmRdI(fp,q+56))/floatmax(1.0,fps));
    g_bVmLoop563[m][i]=(GmRdI(fp,q+36)&1)!=0;
    g_iVmStart563[m][i]=g_iVmEventCount563;
    for(new j=0;j<n;j++) {
        new ev=o+j*76;if(GmRdI(fp,ev+4)!=5004) continue;
        new sample[96];fseek(fp,ev+12,SEEK_SET);fread_blocks(fp,sample,64,BLOCK_CHAR);sample[63]=0;
        if(!sample[0] || containi(sample,".wav")==-1) continue;
        new snd=-1;for(new k=0;k<g_iVmSoundCount563;k++) if(equal(sample,g_szVmSound563[k])) {snd=k;break;}
        if(snd<0 && g_iVmSoundCount563<VM_SOUNDS563) {snd=g_iVmSoundCount563++;copy(g_szVmSound563[snd],charsmax(g_szVmSound563[]),sample);}
        if(snd<0) continue;
        new e=g_iVmEventCount563++;g_iVmEventSound563[e]=snd;
        g_fVmEventTime563[e]=float(max(0,GmRdI(fp,ev)))/floatmax(1.0,fps);
        g_iVmNum563[m][i]++;
        fseek(dst,ev+4,SEEK_SET);fwrite(dst,0,BLOCK_INT);
    }
    new first=g_iVmStart563[m][i],last=first+g_iVmNum563[m][i];
    for(new e=first+1;e<last;e++) for(new k=e;k>first && g_fVmEventTime563[k]<g_fVmEventTime563[k-1];k--) {
        new snd=g_iVmEventSound563[k];g_iVmEventSound563[k]=g_iVmEventSound563[k-1];g_iVmEventSound563[k-1]=snd;
        new Float:t=g_fVmEventTime563[k];g_fVmEventTime563[k]=g_fVmEventTime563[k-1];g_fVmEventTime563[k-1]=t;
    }
}
fclose(dst);fclose(fp);
// Studio split texture/sequence files follow the renamed viewmodel.
new a[160],b[160],stem[128],base[96];copy(stem,charsmax(stem),src);stem[strlen(stem)-4]=0;
copy(base,charsmax(base),out);base[strlen(base)-4]=0;
/* Texture companions must be installed manually. */
for(new n=1;n<groups;n++) {
    formatex(a,charsmax(a),"%s%02d.mdl",stem,n);formatex(b,charsmax(b),"%s%02d.mdl",base,n);
    if(file_exists(a,true) && !file_exists(b,true)) GmCopy(a,b);
}
if(g_bVmPrecacheLive563) VmCuePrecache563();
return 1;
}
VmCuePrecache563()
{
for(new i=0;i<g_iVmSoundCount563;i++) {
    if(g_bVmSoundReady563[i]) continue;
    new full[128];formatex(full,charsmax(full),"sound/%s",g_szVmSound563[i]);
    if(file_exists(full,true)) g_bVmSoundReady563[i]=vxc_pc_sound(g_szVmSound563[i])!=0;
}
log_amx("[Audio563] %d ozel model, %d indeksli animasyon sesi; silah birakilinca yalniz silah kanali durur.",g_iVmCount563,g_iVmSoundCount563);
}
VmLifecycleInit563()
{
register_forward(FM_MessageBegin,"VmMessageBegin563",0);
register_forward(FM_WriteByte,"VmWriteByte563",0);
register_forward(FM_MessageEnd,"VmMessageEnd563",0);
for(new id=1;id<=32;id++) {g_iVmModel563[id]=-1;g_iVmSeq563[id]=-1;}
}
public VmMessageBegin563(dest,type,const Float:origin[3],id)
{
#pragma unused dest,origin
g_iVmMessagePlayer563=type==SVC_WEAPONANIM && id>=1 && id<=32?id:0;
g_iVmMessageByte563=0;return FMRES_IGNORED;
}
public VmWriteByte563(value)
{
if(g_iVmMessagePlayer563 && !g_iVmMessageByte563++) g_iVmMessageSeq563=value;
return FMRES_IGNORED;
}
public VmMessageEnd563()
{
new id=g_iVmMessagePlayer563;
if(id && g_iVmMessageByte563) {g_bVmRestart563[id]=true;g_iVmSeq563[id]=g_iVmMessageSeq563;}
g_iVmMessagePlayer563=0;return FMRES_IGNORED;
}
VmObserve563(id)
{
new modelString=pev(id,pev_viewmodel),seq=pev(id,pev_weaponanim);
if(modelString!=g_iVmString563[id]) {
    g_iVmString563[id]=modelString;g_iVmModel563[id]=-1;
    new path[128],m;pev(id,pev_viewmodel2,path,charsmax(path));
    if(g_tVm563!=Invalid_Trie && TrieGetCell(g_tVm563,path,m)) g_iVmModel563[id]=m-1;
    g_bVmRestart563[id]=true;
}
new m=g_iVmModel563[id];if(m<0 || seq<0 || seq>=VM_SEQS563) return;
new Float:now=get_gametime();
if(g_bVmRestart563[id] || seq!=g_iVmSeq563[id]) {
    g_bVmRestart563[id]=false;g_iVmSeq563[id]=seq;g_fVmClock563[id]=now;g_iVmCursor563[id]=0;
}
new count=g_iVmNum563[m][seq];if(!count) return;
new Float:elapsed=now-g_fVmClock563[id],Float:duration=g_fVmLength563[m][seq];
if(g_bVmLoop563[m][seq] && elapsed>=duration) {
    g_fVmClock563[id]=now;g_iVmCursor563[id]=0;elapsed=0.0;
}
while(g_iVmCursor563[id]<count) {
    new e=g_iVmStart563[m][seq]+g_iVmCursor563[id];if(elapsed+0.001<g_fVmEventTime563[e]) break;
    g_iVmCursor563[id]++;
    new snd=g_iVmEventSound563[e];if(!g_bVmSoundReady563[snd]) continue;
    new sample[96];copy(sample,charsmax(sample),g_szVmSound563[snd]);
    new k=g_iSoundCursor563[id]++%16;copy(g_szWeaponSound563[id][k],charsmax(g_szWeaponSound563[][]),sample);g_iSoundChannel563[id][k]=CHAN_ITEM;
    rh_emit_sound2(id,id,CHAN_ITEM,sample,0.8,ATTN_NORM,0,PITCH_NORM);
}
}

public N_ZupSnapshot621(plugin,params){new id=get_param(1),c=get_param(2),f=get_param(3);if(id<1||id>32||c<0||c>=24||!is_user_connected(id))return 0;if(!g_bZupLoaded[id]&&ZupAuthReady565(id))ZupLoad(id);if(!g_bZupLoaded[id])return 0;switch(f){case 0:return g_iZupLvl[id][c];case 1:return g_iZupPts[id][c];case 2,3,4:return g_iZupStat[id][c][f-2];case 5:return g_iZupLvl[id][c]<ZUP_MAX?g_iZupStep[g_iZupLvl[id][c]]:0;}return 0;}
public N_ZupSpend621(plugin,params){new id=get_param(1),c=get_param(2),k=get_param(3);if(id<1||id>32||c<0||c>=24||k<0||k>=3||!is_user_connected(id))return 0;if(!g_bZupLoaded[id]&&ZupAuthReady565(id))ZupLoad(id);if(!g_bZupLoaded[id]||g_iZupVault==INVALID_HANDLE||ZupFree563(id,c)<=0)return 0;g_iZupStat[id][c][k]++;g_iZupSelected[id]=c;ZupSave(id);ClearSyncHud(id,g_hZupHud563);return 1;}

native vxc_tab_value(id,field,cat=0,ix=0);
native vxc_tab_credit(id,vc,ap);
native vxc_tab_purchase(buyer,seller,cat,ix,price);
native vxc_tab_key(id,out[],len);
PlusInit622(){g_hPlus622=nvault_open("vexmira_tablet_plus622");if(g_hPlus622==INVALID_HANDLE)log_amx("[Tablet622] Claim vault unavailable");}
AcKey622(id,key[],len,const prefix[]){new account[48];vxc_tab_key(id,account,47);formatex(key,len,"%s%s",prefix,account);}
public N_AcLoad622(plugin,params){new id=get_param(1);if(id<1||id>32)return 0;g_acReady622[id]=false;g_acMask622[id]=0;if(g_hPlus622==INVALID_HANDLE||vxc_tab_value(id,0)<0)return 0;
if(!MarketRecover622(id))return 0;new key[64],val[128];AcKey622(id,key,63,"a_");if(nvault_get(g_hPlus622,key,val,127))g_acMask622[id]=str_to_num(val);else{g_acMask622[id]=vxc_tab_value(id,2);num_to_str(g_acMask622[id],val,127);nvault_set(g_hPlus622,key,val);}
new journal[64];AcKey622(id,journal,63,"j_");if(nvault_get(g_hPlus622,journal,val,127)){new a[16],b[16],c[16],d[16],e[16];if(parse(val,a,15,b,15,c,15,d,15,e,15)!=5)return 0;new bit=str_to_num(a),vc=str_to_num(b),ap=str_to_num(c),rv=str_to_num(d),ra=str_to_num(e);if(bit<0||bit>=30||vc<0||ap<0||rv<0||ra<0||rv>100000000||ra>100000000||vc>2000000000-rv||ap>2000000000-ra)return 0;
if(!(g_acMask622[id]&(1<<bit))){new cv=vxc_tab_value(id,0),ca=vxc_tab_value(id,1);if(cv==vc&&ca==ap){if(!vxc_tab_credit(id,rv,ra))return 0;}else if(cv!=vc+rv||ca!=ap+ra){log_amx("[Tablet622] Claim recovery needs review id=%d",id);return 0;}g_acMask622[id]|=(1<<bit);num_to_str(g_acMask622[id],val,127);nvault_set(g_hPlus622,key,val);}nvault_remove(g_hPlus622,journal);}
g_acReady622[id]=true;return 1;}
public N_AcMask622(plugin,params){return g_acMask622[get_param(1)];}
public N_AcClaim622(plugin,params){new id=get_param(1),bit=get_param(2);if(id<1||id>32||!g_acReady622[id]||bit<0||bit>=30||!(vxc_tab_value(id,2)&(1<<bit))||(g_acMask622[id]&(1<<bit)))return 0;
new vc=vxc_tab_value(id,0),ap=vxc_tab_value(id,1),rv=vxc_tab_value(id,3),ra=vxc_tab_value(id,4);if(vc<0||ap<0||rv<0||ra<0||rv>100000000||ra>100000000||vc>2000000000-rv||ap>2000000000-ra)return 0;
if(!vxc_tab_credit(id,0,0))return 0;new key[64],journal[64],val[128];AcKey622(id,key,63,"a_");AcKey622(id,journal,63,"j_");formatex(val,127,"%d %d %d %d %d",bit,vc,ap,rv,ra);nvault_set(g_hPlus622,journal,val);
if(!vxc_tab_credit(id,rv,ra))return 0;g_acMask622[id]|=(1<<bit);num_to_str(g_acMask622[id],val,127);nvault_set(g_hPlus622,key,val);nvault_remove(g_hPlus622,journal);return 1;}
bool:MarketValid622(k){new id=g_mOwner622[k];if(!g_mId622[k]||id<1||id>32||!is_user_connected(id)||get_user_userid(id)!=g_mUid622[k]||vxc_tab_value(id,0)<0)return false;return vxc_tab_value(id,5,g_mCat622[k],g_mItem622[k])==1;}
public N_MarketAction622(plugin,params){new id=get_param(1),op=get_param(2),a[48],b[16];get_string(3,a,47);get_string(4,b,15);if(vxc_tab_value(id,0)<0||is_user_bot(id)||g_hPlus622==INVALID_HANDLE||!g_acReady622[id])return 0;
if(op==0){if(!b[0]||strlen(b)>9)return 0;for(new digit=0;b[digit];digit++)if(b[digit]<'0'||b[digit]>'9')return 0;new cat=a[0],item=str_to_num(a[1])-1,price=str_to_num(b),slot=-1,count;if(contain("kcwpftz",fmt("%c",cat))<0||item<0||price<1||price>100000000||vxc_tab_value(id,5,cat,item)!=1)return 0;
for(new k=0;k<MARKET622_MAX;k++){if(!MarketValid622(k)){g_mId622[k]=0;if(slot<0)slot=k;continue;}if(g_mOwner622[k]==id){count++;if(g_mCat622[k]==cat&&g_mItem622[k]==item)return 0;}}
if(slot<0||count>=8)return 0;g_mId622[slot]=++g_mSerial622;g_mOwner622[slot]=id;g_mUid622[slot]=get_user_userid(id);g_mCat622[slot]=cat;g_mItem622[slot]=item;g_mPrice622[slot]=price;return 1;}
new listing=str_to_num(a);for(new k=0;k<MARKET622_MAX;k++){if(g_mId622[k]!=listing)continue;if(!MarketValid622(k)){g_mId622[k]=0;return 0;}if(op==2){if(g_mOwner622[k]!=id)return 0;g_mId622[k]=0;return 1;}if(op==1){new seller=g_mOwner622[k];if(seller==id)return 0;g_mId622[k]=0;if(!vxc_tab_purchase(id,seller,g_mCat622[k],g_mItem622[k],g_mPrice622[k])){g_mId622[k]=listing;return 0;}return 1;}}return 0;}
// 6.4: market rows for the tablet address: id~uid~name~code~price;...
public N_MarketStr64(plugin,params){new len=get_param(3);static out[700];new n,name[32],enc[100],row[160];out[0]=0;for(new k=0;k<MARKET622_MAX;k++){if(!MarketValid622(k)){g_mId622[k]=0;continue;}get_user_name(g_mOwner622[k],name,31);new o;for(new i=0;name[i]&&o<96;i++){new c=name[i]&0xFF;if((c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9'))enc[o++]=c;else o+=formatex(enc[o],99-o,"%%%02X",c);}enc[o]=0;formatex(row,159,"%s%d~%d~%s~%c%d~%d",n?";":"",g_mId622[k],g_mUid622[k],enc,g_mCat622[k],g_mItem622[k]+1,g_mPrice622[k]);if(n+strlen(row)>=min(len,charsmax(out)))break;n+=copy(out[n],charsmax(out)-n,row);}
set_string(2,out,len);return n;}
public N_MarketWrite622(plugin,params){new fp=get_param(1);fputs(fp,"market:[");new first=1,name[32],safe[96];for(new k=0;k<MARKET622_MAX;k++){if(!MarketValid622(k)){g_mId622[k]=0;continue;}get_user_name(g_mOwner622[k],name,31);new n;for(new i=0;name[i]&&n<93;i++){if(name[i]=='"'||name[i]=='\')safe[n++]='\';if(name[i]>=32)safe[n++]=name[i];}safe[n]=0;fprintf(fp,"%s[%d,%d,^"%s^",^"%c%d^",%d]",first?"":",",g_mId622[k],g_mUid622[k],safe,g_mCat622[k],g_mItem622[k]+1,g_mPrice622[k]);first=0;}fputs(fp,"],");return 1;}

native vxc_tab_recover(id,beforeVC,afterVC,cat,ix,beforeOwned,afterOwned);
MarketKey622(id,key[],len){AcKey622(id,key,len,"m_");}
MarketRecover622(id){new key[64],val[160];MarketKey622(id,key,63);if(!nvault_get(g_hPlus622,key,val,159))return 1;new a[16],b[16],c[16],d[16],e[16],f[16],g[16];if(parse(val,a,15,b,15,c,15,d,15,e,15,f,15,g,15)!=7)return 0;
new tx=str_to_num(a),marker[32];formatex(marker,31,"t_%d",tx);if(nvault_get(g_hPlus622,marker)!=1){nvault_remove(g_hPlus622,key);return 1;}if(!vxc_tab_recover(id,str_to_num(b),str_to_num(c),str_to_num(d),str_to_num(e),str_to_num(f),str_to_num(g))){log_amx("[Tablet622] Market recovery needs review id=%d tx=%d",id,tx);return 0;}nvault_remove(g_hPlus622,key);return 1;}
public N_MarketPrepare622(plugin,params){new buyer=get_param(1),seller=get_param(2),cat=get_param(3),ix=get_param(4),price=get_param(5);if(g_hPlus622==INVALID_HANDLE||buyer<1||buyer>32||seller<1||seller>32||!g_acReady622[buyer]||!g_acReady622[seller])return 0;
new bk[64],sk[64],tmp[160];MarketKey622(buyer,bk,63);MarketKey622(seller,sk,63);if(nvault_get(g_hPlus622,bk,tmp,159)||nvault_get(g_hPlus622,sk,tmp,159))return 0;
new bv=vxc_tab_value(buyer,0),sv=vxc_tab_value(seller,0);if(price<1||price>100000000||bv<price||sv<0||sv>2000000000-price)return 0;new tx=nvault_get(g_hPlus622,"marketseq");if(tx>=2000000000)return 0;tx++;num_to_str(tx,tmp,159);nvault_set(g_hPlus622,"marketseq",tmp);new marker[32];formatex(marker,31,"t_%d",tx);nvault_set(g_hPlus622,marker,"0");formatex(tmp,159,"%d %d %d %d %d 0 1",tx,bv,bv-price,cat,ix);nvault_set(g_hPlus622,bk,tmp);formatex(tmp,159,"%d %d %d %d %d 1 0",tx,sv,sv+price,cat,ix);nvault_set(g_hPlus622,sk,tmp);nvault_set(g_hPlus622,marker,"1");return 1;}
public N_MarketFinish622(plugin,params){new buyer=get_param(1),seller=get_param(2),bk[64],sk[64],val[160],tx[16],marker[32];MarketKey622(buyer,bk,63);MarketKey622(seller,sk,63);if(nvault_get(g_hPlus622,bk,val,159)){parse(val,tx,15);formatex(marker,31,"t_%d",str_to_num(tx));}nvault_remove(g_hPlus622,bk);nvault_remove(g_hPlus622,sk);if(marker[0])nvault_remove(g_hPlus622,marker);return 1;}
