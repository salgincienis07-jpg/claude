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
native vxe_boss_giant(const name[], out[], len, Float:k, tex);
native vxe_gs_slim(const a[], const b[], t);
native vxe_default_resources();
native vxe_modern_events();
native vxe_native_precache();
native vxe_version();
native vxe_unprecache_count(kind);
native vxe_zup_level(id, cls);
native vxe_zup_add(id, pts);
native vxe_zup_used(id, lvl);
native vxe_mask_block(victim, attacker);
native Float:vxe_zarmor_hit(victim, Float:dmg);
native vxe_item_count();
native vxe_item_info(k, team, name[], len);
native vxe_item_buy(id, k);
native Float:vxe_sw_hit(attacker, victim, wid, head, boss);
native vxe_sw_count();
native vxe_sw_info(i, name[], len);
native vxe_sw_give(id, i);
native vxe_sw_active(id);
native vxe_sw_rgb(i);
new g_iIsolation526;
new bool:g_bRun526;
new bool:g_bCameraReady529;
#pragma tabsize 0
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
new bool:g_zcGuardFail;
new Trie:g_tZcModelsReady = Invalid_Trie;
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
stock bool:VexGuardFatal(const scope[], const path[])
{
if(equal(scope,"vexmira_core")) return false;
return containi(path,".mdl")!=-1 || containi(path,".spr")!=-1;
}
stock bool:VexAssetGuard(const scope[])
{
new required[192],sample[4];
if(equal(scope,"vexmira_core")) {
static const paths[][]={
"models/player/vex_gign/vex_gign.mdl",
"models/player/vex_gsg9/vex_gsg9.mdl",
"models/player/vex_halo/vex_halo.mdl",
"models/player/vex_halo/vex_haloT.mdl",
"models/player/vex_soldier/vex_soldier.mdl",
"models/player/vex_spetsnaz/vex_spetsnaz.mdl",
"models/vexmira/arena48/v_balrog.mdl",
"models/vexmira_ze/skins/vexmira_v_ak47.mdl",
"models/vexmira_ze/skins/vexmira_v_aug.mdl",
"models/vexmira_ze/skins/vexmira_v_awp.mdl",
"models/vexmira_ze/skins/vexmira_v_deagle.mdl",
"models/vexmira/arena50/default/v_galil.mdl",
"models/vexmira/arena50/default/v_knife.mdl",
"models/vexmira_ze/skins/vexmira_v_m249.mdl",
"models/vexmira_ze/skins/vexmira_v_m4a1.mdl",
"models/vexmira_ze/skins/vexmira_v_mp5.mdl",
"models/vexmira_ze/skins/vexmira_v_sg550.mdl",
"models/vexmira_ze/skins/vexmira_v_sg552.mdl",
"models/vexmira_ze/skins/vexmira_v_xm1014.mdl",
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
return true;
}
stock VexPcSnd(const s[], bool:emitted)
{
if (emitted) { ZcPcSound(s); return; }
new f[128]; formatex(f, charsmax(f), "sound/%s", s);
if (file_exists(f, true)) ZcPcGeneric(f);
}
#define TASK_EPIC_MUSIC 970000
#define TASK_EPIC_SPAWN 971000
#define E46_VIP_STYLE_SHIFT 24
#define E46_VIP_STYLE_MASK (3<<24)
#define E46_VIP_SPAWN (1<<26)
#define E46_VIP_WIN (1<<27)
#define E46_VIP_KILL (1<<28)
new Float:g_fEpicG[33],Float:g_fEpicLaserWarn[33],Float:g_fEpicVip[33];
new g_iEpicFlare;
new g_iEpicGlyph[9],bool:g_bEpicBar[9];
new const E46_G_COOLED[9]={20,24,28,24,22,24,22,28,30};
new const E46_BOSS_GKEY[9][]={"E46_G0","E46_G1","E46_G2","E46_G3","E46_G4","E46_G5","E46_G6","E46_G7","E46_G8"};
native vx45_call(comp, op, id);
native vx45_ready(comp);
native vx45_count();
native vx45_status(id);
native vx45_hevlimit(id);
native vx45_write(bool:force);
ZcCall(comp, op, id) { return vx45_call(comp,op,id); }
bool:ZcCompOn(comp) { return bool:vx45_ready(comp); }
ZcModulesOn() { return vx45_count(); }
ZcModuleStatus(id) { return vx45_status(id); }
ZcHevRoundLocked(id) { return vx45_hevlimit(id); }
new g_pSixTracer, g_pSixMemeCD, g_pSixLog;
new Float:g_fSixConnect[33], Float:g_fSixEnter[33], Float:g_fSixMemeNext[33];
new bool:g_bSixTracked[33], bool:g_bSixEntered[33];
new g_iSixAttempts, g_iSixEntered, g_iSixAborted, g_iSixShort;
#define PLUGIN   "Vexmira Zombie Core"
new g_pUi52,g_pRadio52,g_pRadioInterval52,g_iUiPage52[33],g_iUiPriority52[33];
new Float:g_fRadioBusy52,Float:g_fRadioNext52,Float:g_fRadioAt52[15];new g_iRadioLast52=-1;
new bool:g_bRadioReady52[15];
new const RADIO_FILE52[][]={"start","hazard","boss","supply","last","win","loss","fire","ice","storm","night","chatter1","chatter2","chatter3","chatter4"};
new const RADIO_WHO52[15]={0,1,0,2,0,0,0,3,3,1,1,4,4,4,4};
new const RADIO_WHO_TR52[][]={"MERKEZ","GOZCU","LOJISTIK","ISTIHKAM","DEVRIYE"};
new const RADIO_WHO_EN52[][]={"COMMAND","SPOTTER","LOGISTICS","ENGINEER","PATROL"};
new const RADIO_TXT_TR52[15][]={
"Tum birimler dikkat! Enfeksiyon bolgesi aktif, mevzilerinizi alin.",
"Biyolojik tehlike tespit edildi! Zombi hareketliligi artiyor.",
"Buyuk sinyal tespit edildi! Atese hazir olun!",
"Ikmal kutusu indirildi! Bolgeye gidip malzemeleri alin.",
"Son hayatta kalan! Tekrarliyorum: SON INSAN, dayan!",
"Bolge temizlendi. Iyi is cikardiniz, tamam.",
"Hat koptu... bolge kaybedildi. Geri cekilin!",
"Yangin bombasi patladi! Alev hattindan uzak durun.",
"Dondurucu patlama! Hedefler yavasladi, simdi vurun!",
"Firtina yaklasiyor, gorus mesafesi dusuyor. Dikkatli olun.",
"Elektrik kesildi! Karanlikta birbirinizden ayrilmayin.",
"Kuzey koridorda hareket var, kontrol ediyorum...",
"Muhimmat durumunu bildirin. Kimse yalniz kalmasin.",
"Sesleri duyuyor musunuz? Yaklasiyorlar...",
"Hat acik, beklemedeyim. Gozunuz uzerimizde olsun."};
new const RADIO_TXT_EN52[15][]={
"All units, be advised! Infection zone is hot, take your positions.",
"Biohazard detected! Zombie activity is rising.",
"Massive signal detected! Weapons ready!",
"Supply drop is down! Move to the zone and grab the gear.",
"Last survivor! I repeat: LAST HUMAN, hold on!",
"Area secured. Good work, over.",
"Line is broken... sector lost. Fall back!",
"Fire grenade out! Stay clear of the flame line.",
"Freeze blast! Targets are slowed, hit them now!",
"Storm incoming, visibility dropping. Stay sharp.",
"Power is down! Stick together in the dark.",
"Movement in the north corridor, checking it...",
"Report your ammo. Nobody stays alone.",
"Do you hear that? They are getting closer...",
"Channel open, standing by. Eyes on us."};
new const Float:RADIO_LENGTH52[15]={3.200,4.480,4.320,3.360,4.880,2.320,3.520,3.360,3.360,5.440,4.080,3.040,3.360,3.280,4.000};
new bool:g_bUiHudFiles52[64],bool:g_bUiHudActive52[33];
new g_iUiHudWpn52[33],g_iUiHudFrame52[33],g_iUiHudUid52[33];new Float:g_fUiHudNext52[33];
new bool:g_bRadioEn521[10];
new const RADIO_EN_MAP521[15]={0,1,2,3,4,5,6,7,8,9,9,9,9,9,9};
new const RADIO_EN_FILES521[][]={"start","hazard","boss","supply","last","win","loss","fire","ice","chatter"};
new const Float:RADIO_EN_LENGTH521[10]={3.520,5.520,4.720,3.200,6.800,3.360,3.520,3.840,4.480,4.560};
native vx521_pair_version();
#define VERSION  "5.3.1-Stable"
#define AUTHOR   "SmurfSexy & Capital"
#define MAX_LEVEL     60
#define NUM_CLASSES   24
#define NUM_BOSSES    9
#define NUM_JOBS      26
#define NUM_ITEMS     28
#define NUM_SPECIAL   8
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
#define TASK_LMTAKE   39700
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
#define TASK_AUTOTEAM 34500
#define TASK_JOINCLASS 34600
#define TASK_SNDSTOP  31000
#define TASK_BSK      32000
#define HIT_HEAD      1
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
#define SL_ANN        0
#define SL_ALERT      1
#define SL_PERS       2
#define SL_KILL       3
#define SL_REWARD     4
#define NUM_SLOTS     5
#define CHAT_PREFIX   g_szPrefix
#define SET_NO_HUD     (1<<0)
#define SET_NO_DMGNUM  (1<<1)
#define SET_NO_FX      (1<<2)
#define SET_NO_AMB     (1<<3)
#define SET_NO_STREAK  (1<<4)
#define SET_NO_ADS     (1<<5)
#define SET_NO_AUTOGUN (1<<6)
#define SET_NO_FOG     (1<<7)
#define SET_NO_TIPS    (1<<9)
#define SET_NO_MEME    (1<<11)
#define SET_NO_COS     (1<<10)
#define SET_NO_RADIO52 (1<<12)
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
enum
{
JOB_MEDIC = 0, JOB_HEAVY, JOB_SCOUT, JOB_MARKSMAN, JOB_ENGINEER, JOB_LOOTER,
JOB_GUNNER, JOB_DEMO, JOB_SNIPER, JOB_PARA, JOB_PYRO, JOB_CRYO,
JOB_VAMPIRE, JOB_GUARDIAN, JOB_BERSERKER, JOB_COMMANDER,
JOB_JUGGERNAUT, JOB_NINJA, JOB_GHOST, JOB_GRENADIER, JOB_HUNTER,
JOB_DOCTOR, JOB_GAMBLER, JOB_TACTICIAN, JOB_LUCKY, JOB_ELITE
};
enum
{
IT_MEDKIT = 0, IT_ARMOR, IT_FIRENADE, IT_FROSTNADE, IT_FLARE, IT_DJUMP,
IT_BOOTS, IT_SERUM, IT_UNLCLIP, IT_DMGAMP, IT_RESPAWN,
IT_ANTIDOTE, IT_MADNESS, IT_INFBOMB, IT_MUTAGEN, IT_RAGE, IT_RECHARGE, IT_ZARMOR,
IT_ADREN, IT_HCLOAK, IT_NVG, IT_ESHIELD, IT_AMMO,
IT_ZSPRINT, IT_ZCLOAK, IT_ZJUMP, IT_ZREGEN, IT_ZNOKB
};
enum
{
PK_VITALITY = 0, PK_PLATING, PK_FIREPOWER, PK_FORTUNE, PK_AGILITY, PK_HIDE
};
#define NADE_FIRE    7701
#define NADE_FROST   7702
#define NADE_INFECT  7703
#define NADE_FLARE   7704
#define NM_NORMAL    0
#define NM_IMPACT    1
#define NM_SENSOR    2
#define NM_LASER     3
#define NM_HOMING    4
#define NM_CLUSTER   5
#define NUM_NMODES   6
#define NUM_QUESTS   8
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
"SW_FIRE", "SW0_FIRE", "SW1_FIRE", "SW2_FIRE", "SW3_FIRE", "SW4_FIRE", "SW5_FIRE",
"SW0_DRAW", "SW1_DRAW", "SW2_DRAW", "SW3_DRAW", "SW4_DRAW", "SW5_DRAW",
"SW0_RELOAD", "SW1_RELOAD", "SW2_RELOAD", "SW3_RELOAD", "SW4_RELOAD", "SW5_RELOAD",
"ZAP", "MVP", "VIP_JOIN", "BOSS_WARN", "BOSS_ROAR", "BOSS_ABILITY",
"ZOMBIE_IDLE", "ZOMBIE_SLASH", "ZOMBIE_HITWALL", "ZOMBIE_HIT", "ZOMBIE_STAB", "ZOMBIE_ACID", "ZOMBIE_HEAL", "ZOMBIE_BLINK", "ZOMBIE_SHOCK",
"WELCOME", "PLAYER_JOIN", "PLAYER_LEAVE", "BOSS_SOON", "BOSS_INTRO", "BOSS_STEP", "BOSS_PHASE", "BOSS_ENRAGE",
"LM_DEPLOY", "LM_CHARGE", "LM_ACTIVATE", "LM_HIT", "LM_BREAK", "LM_PICKUP",
"NADE_MODE", "NADE_BEEP", "NADE_ARM", "NADE_CLUSTER",
"AIRDROP_INCOMING", "AIRDROP_LAND", "AIRDROP_LOOT", "QUEST_DONE", "EVOLVE",
"SPEED_START", "SPEED_WIND", "STORM_STRIKE", "BLACKOUT", "FINAL_ROUND", "MAP_END",
"FROST_NOVA", "THUNDER", "ACID_POOL", "GRAVITY_WELL", "ECLIPSE",
"ZONE_WARN", "SKILL_UNLOCK", "NEM_RAGE", "ASN_VEIL", "LM_KILL", "NADE_TRIGGER", "UI_OPEN", "LM_DENY",
"CSO_KM", "CSO_KM_SP", "CSO_MVP", "CSO_BANNER", "CSO_WIN", "CSO_ALERT", "CSO_LEVEL",
"CSO_FB", "CSO_BKILL", "CSO_INFD", "CSO_TEN"
};
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
new const CLASS_OLDMODEL[NUM_CLASSES][] =
{
"terror", "leet", "arctic", "guerilla", "terror", "leet", "arctic", "guerilla",
"terror", "arctic", "guerilla", "leet", "terror", "leet", "arctic", "guerilla",
"terror", "arctic", "guerilla", "leet", "guerilla", "arctic", "terror", "leet"
};
new const WEAPON_KEYNAME[31][] =
{
"", "P228", "GLOCK", "SCOUT", "HEGRENADE", "XM1014", "C4", "MAC10", "AUG", "SMOKEGRENADE",
"ELITE", "FIVESEVEN", "UMP45", "SG550", "GALIL", "FAMAS", "USP", "GLOCK18", "AWP", "MP5NAVY",
"M249", "M3", "M4A1", "TMP", "G3SG1", "FLASHBANG", "DEAGLE", "SG552", "AK47", "KNIFE", "P90"
};
new Float:BOSS_HP_MULT[NUM_BOSSES] = { 1.00, 0.80, 1.15, 1.00, 0.90, 1.05, 0.95, 1.10, 1.20 };
new BOSS_SPD[NUM_BOSSES]           = { 255,  290,  260,  270,  300,  265,  285,  275,  280 };
new Float:BOSS_GRAV[NUM_BOSSES]    = { 0.85, 0.65, 0.85, 0.80, 0.60, 0.85, 0.75, 0.80, 0.55 };
new BOSS_RGB[NUM_BOSSES][3] =
{
{255, 120, 0}, {190, 210, 255}, {160, 0, 255}, {255, 50, 0}, {120, 0, 190},
{0, 190, 255}, {255, 240, 80}, {110, 255, 0}, {220, 0, 140}
};
new MODE_CHANCE[MODE_TOTAL] = { 0, 15, 5, 4, 5, 4, 5, 3, 2, 0 };
new MODE_MINPL[MODE_TOTAL]  = { 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 };
new JOB_LVL[NUM_JOBS] = { 1, 1, 2, 3, 4, 5, 6, 8, 10, 12, 14, 16, 18, 21, 24, 28, 7, 9, 11, 13, 15, 17, 20, 23, 26, 32 };
new ITEM_COST[NUM_ITEMS]  = { 12, 10, 12, 12, 5, 15, 10, 12, 35, 45, 50, 40, 20, 35, 15, 12, 10, 18, 15, 25, 8, 40, 10, 15, 20, 12, 25, 18 };
new const ITEM_TEAM[NUM_ITEMS]  = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1 };
new ITEM_LIMIT[NUM_ITEMS] = { 3, 2, 2, 2, 3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 3, 1, 2, 1, 1, 1, 2, 2, 1, 1, 1, 1 };
new ITEM_LVL[NUM_ITEMS]   = { 1, 1, 1, 1, 1, 2, 1, 1, 3, 4, 2, 1, 1, 3, 1, 2, 1, 3, 2, 3, 1, 4, 1, 1, 2, 1, 3, 2 };
new ITEM_VAL[NUM_ITEMS]   = { 100, 200, 1, 1, 1, 1, 55, 12, 0, 20, 0, 0, 5, 3, 1500, 20, 0, 20, 6, 8, 0, 2, 0, 6, 6, 60, 80, 0 };
new const ITEM_ANNOUNCE[NUM_ITEMS] = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1 };
#define VX_TAG 7800
#define VX_MAX_PROJECTILES 24
new const V50_NAMES[8][]={"Arbalest","Heaven Splitter","Quantum Horizon","Magnum Drill Chimera","Dark Knight","Infinity Laser Fist","Void Avenger","Dual Beretta Gunslinger"};
new const V50_IDLE[8]={0,0,0,0,0,0,0,0};
new const V50_DRAW[8]={2,2,2,4,2,9,6,0};
new const V50_RELOAD[8]={1,1,1,3,1,8,5,14};
new const V50_ALT[8]={3,3,3,2,3,7,15,15};
new const V50_CHANGE[8]={2,2,2,4,2,5,7,0};
new const V50_FIRE[8][3]={{3,4,5},{3,4,5},{3,4,5},{1,1,1},{3,4,5},{3,3,3},{1,2,3},{2,3,4}};
new const Float:V50_RELOAD_TIME[8]={3.050,2.905,2.955,2.700,3.222,2.700,3.267,4.800};
new const VX_FOLDER[NUM_SPECIAL][] = {"0", "1", "2", "3", "4", "5", "6", "7"};
new const VX_SOUND[7][] = {"fire", "magout", "magin", "bolt", "switch", "alt", "impact"};
new const VX_ALT_COST[NUM_SPECIAL] = {3, 5, 8, 6, 6, 10, 12, 8};
new const Float:VX_ALT_WAIT[NUM_SPECIAL] = {1.0, 1.6, 2.8, 3.0, 2.6, 2.4, 5.0, 3.5};
new bool:g_bVxReady[NUM_SPECIAL], bool:g_bVxGiving[33], bool:g_bVxAltHandled[33], bool:g_bVxRightHeld[33];
new g_iVxClip[33], g_iVxAttack[33], g_iVxShots[33], g_iVxEvent;
new g_szVxWorld[NUM_SPECIAL][96], g_iVxProjectiles[VX_MAX_PROJECTILES];
new Float:g_fVxStart[33][3], Float:g_fVxEnd[33][3];
new g_iVxOrbModel, g_iVxDragonModel;
new const VX_ORB[] = "sprites/vexmira/arena50/orb.spr";
new const VX_DRAGON[] = "models/vexmira/weapons/arsenal/dragon.mdl";
new const SW_BASE_ENT[NUM_SPECIAL][] =
{"weapon_ak47", "weapon_ak47", "weapon_ak47", "weapon_ak47", "weapon_ak47", "weapon_ak47", "weapon_ak47", "weapon_ak47"};
new const WeaponIdType:SW_BASE_ID[NUM_SPECIAL] =
{WEAPON_AK47, WEAPON_AK47, WEAPON_AK47, WEAPON_AK47, WEAPON_AK47, WEAPON_AK47, WEAPON_AK47, WEAPON_AK47};
new Float:SW_MULT[NUM_SPECIAL] = {2.0, 2.4, 1.7, 2.8, 1.6, 1.35, 1.8, 1.45};
new SW_COST[NUM_SPECIAL]       = {25, 30, 35, 40, 30, 35, 45, 40};
new SW_LVL[NUM_SPECIAL]        = {1, 1, 1, 1, 1, 1, 1, 1};
new SW_BPAMMO[NUM_SPECIAL]     = {180, 180, 240, 160, 240, 300, 210, 300};
new SW_CLIP[NUM_SPECIAL]       = {24, 20, 40, 16, 40, 60, 30, 60};
new SW_CHAIN_DMG[NUM_SPECIAL]  = {0, 0, 0, 0, 0, 0, 0, 0};
new Float:SW_RATE[NUM_SPECIAL] = {0.24, 0.45, 0.11, 0.5, 0.105, 0.075, 0.18, 0.11};
new Float:SW_RECOIL[NUM_SPECIAL] = {0.7, 0.9, 0.65, 0.8, 0.7, 0.5, 0.65, 0.65};
new SW_EFFECT[NUM_SPECIAL] = {0, 0, 0, 0, 0, 0, 0, 0};
new SW_RGB[NUM_SPECIAL][3]     =
{{95,185,255},{230,165,80},{240,185,60},{230,85,95},{115,145,240},{85,225,250},{150,75,235},{220,175,90}};
new g_szSWName[2][NUM_SPECIAL][48], g_szSWDesc[2][NUM_SPECIAL][80];
#define PERK_COST_STEP max(1, get_pcvar_num(g_pPerkStep))
new const TITLE_ACH[NUM_TITLES] = { -1, 3, 2, 5, 7, 8, 10, 13, 12, 11 };
new const RANK_LVL[NUM_RANKS] = { 1, 5, 10, 18, 26, 35, 45, 55 };
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
new const PRIM_NAME[][] = { "AK-47", "M4A1 Carbine", "FAMAS", "Galil", "MP5 Navy", "UMP45", "P90", "M3 Super 90", "XM1014", "AUG", "SG552", "M249 SAW", "AWP", "G3SG1" };
new const PRIM_ENT[][]  = { "weapon_ak47", "weapon_m4a1", "weapon_famas", "weapon_galil", "weapon_mp5navy", "weapon_ump45", "weapon_p90", "weapon_m3", "weapon_xm1014", "weapon_aug", "weapon_sg552", "weapon_m249", "weapon_awp", "weapon_g3sg1" };
new PRIM_AMMO[]   = { 180, 180, 180, 180, 240, 200, 200, 64, 64, 180, 180, 300, 60, 120 };
new PRIM_LVL[]    = { 1, 1, 1, 1, 1, 2, 3, 2, 4, 6, 7, 9, 12, 14 };
new const SEC_NAME[][]  = { "USP", "Glock-18", "P228", "Desert Eagle", "Dual Elites", "Five-seveN" };
new const SEC_ENT[][]   = { "weapon_usp", "weapon_glock18", "weapon_p228", "weapon_deagle", "weapon_elite", "weapon_fiveseven" };
new SEC_AMMO[]    = { 100, 120, 52, 70, 120, 100 };
new SEC_LVL[]     = { 1, 1, 1, 2, 3, 5 };
new const GUN_CLASSES[][] =
{
"weapon_p228", "weapon_scout", "weapon_xm1014", "weapon_mac10", "weapon_aug",
"weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil",
"weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy",
"weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1",
"weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_p90"
};
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
#define NUM_CALM 6
new ENV_CALM_LIGHT[NUM_CALM]   = { 'm', 'h', 'd', 'i', 'k', 'j' };
new ENV_CALM_FOG[NUM_CALM][4]  = { {0, 0, 0, 0}, {90, 50, 30, 12}, {0, 0, 30, 18}, {70, 80, 90, 20}, {170, 180, 200, 20}, {120, 120, 130, 30} };
new ENV_CALM_WEATHER[NUM_CALM] = { 0, 0, 0, 1, 2, 0 };
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
new g_iMax, g_msgFog, g_msgFade, g_msgShake, g_msgDeath, g_msgScore, g_hVault;
new g_sprRing, g_sprBeam, g_sprLightning, g_sprExplode, g_sprSmoke, g_sprBlood, g_sprBloodSpray, g_sprHeadMark;
new bool:g_bGeoIP;
new g_iRound, g_iMode, g_iEvent, g_iCountdown, g_iFrame;
new g_iForceEvent = -1, g_iForceMode = -1, g_iForceBoss = -1;
new bool:g_bModePicked47, bool:g_bForcedRound47;
new bool:g_bThird47[33], g_iCamera47[33];
new bool:g_bTitan47;
new g_iSupplySigil47;
new g_iGauge47[33];
new Float:g_fGaugeEnd47[33];
new g_iSigil47[2];
new const SIGIL47[2][] = {"models/vexmira/epic/human_sigil47.mdl", "models/vexmira/epic/zombie_sigil47.mdl"};
new g_iBanner47[33], g_iBannerKind47[33], g_iBannerModel47[5];
new Float:g_fBannerEnd47[33], Float:g_fBannerStart47[33];
new const BANNER47[5][] = {"sprites/vexmira/epic/victory_ct47.spr", "sprites/vexmira/epic/victory_t47.spr", "sprites/vexmira/epic/intro47.spr", "sprites/vexmira/epic/death47.spr", "sprites/vexmira/arena530/notifications.spr"};
new g_iBossBag[NUM_BOSSES], g_iBossBagPos = NUM_BOSSES, bool:g_bFinalBoss, g_iLastSpecial = -1;
new g_iBossPhase, g_iBossDmg[33];
new g_iBoss, g_iBossType, g_iBossMaxHP, g_iBossTick, g_iMeteorTick, g_iGlobalInfBombs;
new bool:g_bWaiting, bool:g_bCounting, bool:g_bRoundActive, bool:g_bRoundEnded, bool:g_bEnraged, bool:g_bLastAnn;
new bool:g_bAdminEnvOverride, g_iAdminEnvLight = 'm', g_iAdminEnvFog[4], g_iAdminEnvWeather;
new g_szLight[4] = "m";
new Float:g_fFlarePos[MAX_FLARES][3], Float:g_fFlareEnd[MAX_FLARES];
new g_bZombie[33], g_bNemesis[33], g_bAssassin[33], g_bSurvivor[33], g_bSniper[33];
new g_bBoss[33], g_bMinion[33], g_bFirst[33], g_bForceZombie[33];
new g_iClass[33], g_iClassPicked[33], g_iMaxHP[33];
new const COMMUNITY_WN[6][] = {"JANUS VII", "Plasma Gun", "Thunderbolt", "Ethereal", "Salamander", "Compound Bow"};
new bool:g_bCommunityCtOk[5], bool:g_bCommunityButterflyOk;
new const COMMUNITY_COST[6] = {35, 30, 45, 30, 35, 35};
// 5.3.8: data-driven special melee knives (vex_res MK<n>_*), Thanatos-9 + Skull-9 removed (broken models)
#define MK_MAX 6
#define KN_TOTAL (4 + MK_MAX)
new Float:g_fMelee48[33];
new const COMMUNITY_KN[4][] = {"Dragon Sword", "Dual Katana", "Light Saber", "Horse Axe"};
new g_szMkName[MK_MAX][40], g_szMkV[MK_MAX][96], g_szMkP[MK_MAX][96], g_szMkSnd[MK_MAX][72], g_iMkAnim[MK_MAX][4];
new g_iMkGib538;
new g_szMkSw[MK_MAX][200], g_szMkHit[MK_MAX][200], g_szMkStab[MK_MAX][96], Float:g_fMkRate[MK_MAX][2], g_iMkCombo[33], Float:g_fMkComboAt[33];
new Float:g_fMkDmg[MK_MAX][2], Float:g_fMkKb[MK_MAX], Float:g_fMkRange[MK_MAX], g_iMkFx[MK_MAX], g_iMkCost[MK_MAX], bool:g_bMkOk[MK_MAX];
new g_pMenuPlain538, g_pHudCalm538, g_pSkDmg538, g_pSkKb538, g_pSkBoss538, Float:g_fSkKbAt538[33];
new const COMMUNITY_CT[5][] = {"vex_masterchief47", "vex_batman47", "vex_ironman47", "vex_spiderman47", "vex_wolverine47"};
new const COMMUNITY_CN[5][] = {"Halo Master Chief", "Batman", "Iron Man", "Spider-Man", "Wolverine"};
new const COMMUNITY_COIN[2][5] = {{750,900,1000,850,900},{250,300,400,350,0}};
new g_iCommunityOwned[33][2], g_iCommunitySel[33][2];
new g_iXP[33], g_iLevel[33], g_iAP[33], g_iVC[33];
new g_iKills[33], g_iInfects[33], g_iWins[33], g_iBossK[33], g_iHS[33];
new g_iAch[33], g_iTitle[33], g_iJob[33], g_iStyle[33], g_iSet[33], g_iTheme[33], g_iLang[33];
new g_iDailyDay[33], g_iDailyStreak[33], g_iPrim[33], g_iSec[33], g_iPlaySec[33];
new g_iPerk[33][NUM_PERKS], g_iHudPos[33], Float:g_fGrav[33];
new g_iDmgBank[33], g_iRoundDmg[33], g_iRoundInf[33], g_iRoundAP[33], g_iRoundXP[33];
new g_iStreak[33], g_iMulti[33], Float:g_fLastKill[33];
new g_iBought[33][NUM_ITEMS], g_iPrimTmp[33];
new g_iExtraJumps[33], g_iJumps[33], g_bBoots[33], g_bSerum[33], g_bRage[33], g_bUnlClip[33], g_bDmgAmp[33], g_bZArmor[33];
new g_iFireNades[33], g_iFrostNades[33], g_iFlares[33], g_iInfNades[33], g_iSpecW[33];
new g_iBurn[33], g_iBurnBy[33];
new Float:g_fFrozen[33], Float:g_fSlow[33], Float:g_fMadness[33];
new Float:g_fCool[33], Float:g_fShield[33], Float:g_fBurst[33], Float:g_fCloak[33];
new Float:g_fInfectTime[33], Float:g_fRespawnAt[33], Float:g_fUnstuck[33];
new bool:g_bChaining;
new Float:g_fHBoost[33], g_iEShield[33], g_bZRegen[33], g_bNoKB[33];
new g_iAdmTarget[33], bool:g_bRespawnOff;
new g_iVoteType, g_iVoteLeft, g_iVoteOpt[4], g_iVoteCount[4], g_iVoted[33], g_pVoteEvery;
new g_hVipVault, g_iVip[33], g_iVipExpire[33], g_iVipAura[33], g_bVipTrail[33], g_bVipFreeUsed[33];
new Float:g_fFunCd[33], Float:g_fGiftCd[33], Float:g_fReplyCd, Float:g_fPlayerReplyCd[33];
new g_iSlotBet[33], g_bSlotting[33], g_iTickets[33], g_iLottoPot, g_iLottoClock, g_iBounty[33];
new g_iMapKills[33], g_iLastSeen[33], g_bNewPlayer[33], g_iHumanStreak, g_iZombieStreak, bool:g_bFirstInfect;
new g_szReplyBase[24];
new Float:g_fPetRel49[33][2],Float:g_fPetFloor49[33],Float:g_fPetWall49[33],Float:g_fPetMove49[33];
new g_szCosModel49[33][32],bool:g_bCosAnchor49[33][2],g_iCosBone50[33][2];
new Float:g_fCosAt50[33],Float:g_fCosAnchor50[33][2][3];
new g_szAmbient49[160],g_iAmbientEpoch49,g_iAmbientUser49[33];
new g_szAmbientPlaying52[33][160];
new Trie:g_tAmbientReady52;
new Float:g_fAmbientNext49[33];
new Trie:g_tRes, Trie:g_tCmds, Float:g_fLastSay[33];
new g_szZModel[NUM_CLASSES][32], g_szBModel[NUM_BOSSES][32];
new g_szNemModel[32], g_szAsnModel[32], g_szSurvModel[32], g_szSnipModel[32];
new g_szHumanModel[32], g_szVipModel[32], g_szAdminModel[32];
new g_szClawModel[96], g_szSWView[NUM_SPECIAL][96], g_szSWPlayer[NUM_SPECIAL][96];
#define MW_MODES 2
#define MW_SLOTS 2
new g_szMwV[MW_MODES][MW_SLOTS][96], g_szMwP[MW_MODES][MW_SLOTS][96];
new MW_ENT[MW_MODES][MW_SLOTS][24] = { { "weapon_m249", "weapon_deagle" }, { "weapon_awp", "" } };
new WeaponIdType:MW_ID[MW_MODES][MW_SLOTS] = { { WEAPON_M249, WEAPON_DEAGLE }, { WEAPON_AWP, WEAPON_NONE } };
new Float:MW_DMG[MW_MODES][MW_SLOTS] = { { 1.5, 1.5 }, { 5000.0, 1.0 } };
new MW_CLIP[MW_MODES][MW_SLOTS] = { { 0, 0 }, { 0, 0 } };
new MW_BP[MW_MODES][MW_SLOTS] = { { 400, 100 }, { 100, 0 } };
new MW_FX[MW_MODES][MW_SLOTS];
new const MW_KEY[MW_MODES][] = { "SURVIVOR", "SNIPER" };
new g_szZClaw[NUM_CLASSES][96], g_szBClaw[NUM_BOSSES][96], g_szNemClaw[96], g_szAsnClaw[96];
new g_szWepV[31][96], g_szWepP[31][96], bool:g_bEmitting;
new g_szVipKnifeV[96], g_szVipKnifeP[96], bool:g_bVipRegun[33];
new g_pVipPriority, g_pVipAnnounce, g_pVipVoteW, g_pVipSpawnProt, g_pVipDaily, g_pEliteDaily, g_pVipKillIcon, g_pVipScore, g_pVipRegun;
new bool:g_bVoxCountdown = true;
new g_iEpicCountdown = 2;
new Float:g_fSlotEnd[33][NUM_SLOTS], g_szSlotQ[33][NUM_SLOTS][128], g_iSlotQC[33][NUM_SLOTS], Float:g_fSlotQH[33][NUM_SLOTS], Float:g_fSlotQT[33][NUM_SLOTS];
new bool:g_bWelcomed[33], bool:g_bMotdShown[33], Float:g_fMapStart;
new g_iRoundKills[33], g_iRoundHS[33], g_iQuest[33], bool:g_bQuestDone[33], bool:g_bAlpha[33];
new g_iMapInf[33], g_iMapBossDmg[33];
new g_iMines[33], g_iPlantAction[33], bool:g_bMineHint[33];
new g_iNadeMode[33][3], Float:g_fNadeHud[33];
new g_iAirdropClock, g_iBossFxStep, Float:g_fBossFxPos[3];
#define MAX_POOLS 16
new Float:g_fPoolPos[MAX_POOLS][3], Float:g_fPoolEnd[MAX_POOLS], Float:g_fEclipseEnd, Float:g_fBlizzardEnd;
new g_sprLaser, g_sprFlare, g_szMineModel[96], g_szMineHumanModel[96], g_szMineZombieModel[96], g_szDropModel[96], g_szSky[32];
new Float:g_fBossIntro, g_iPoison[33], g_iPoisonBy[33];
#define NUM_TRAILS   6
#define NUM_KFX      6
#define NUM_IFX      3
#define TOP_MAX      15
new g_iCosOwned[33], g_iTrailSel[33], g_iKfxSel[33], g_iIfxSel[33], g_iTopRank[33];
new g_szKey[33][48], bool:g_bLoaded[33], g_iClassNext[33], g_iJobNext[33], bool:g_bClassSwitched[33];
new bool:g_bGunsGiven[33], bool:g_bNadesGiven[33], bool:g_bTrailOn[33], Trie:g_tRoundBuys, g_iStartTries, bool:g_bAnnounced;
new g_szTopKey[TOP_MAX][48], g_szTopName[TOP_MAX][32], g_iTopXP[TOP_MAX], g_iTopKills[TOP_MAX], g_iTopInf[TOP_MAX], g_iTopBoss[TOP_MAX], g_iTopCount, bool:g_bTopDirty;
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
new g_szPrefix[64] = "^4[VEX]^1";
new g_szSprZone[64], g_szSprTarget[64], g_szSprBeacon[64], g_szSprOrb[64], g_szSprMark[64], g_szSprFire[64], g_szSprLaser[64];
new g_iMineBody, g_iMineSeq, g_iMineSkin, g_iMineModelIndex;
new g_iMineHumanModelIndex, g_iMineZombieModelIndex;
new Float:g_fMineOff, Float:g_fMineEmit[3], Float:g_fMineAxE[3], Float:g_fMineAxU[3], Float:g_fMineAngOfs[3];
new g_pPrefix, g_pHostname, g_pHostDyn, g_pEnv, g_pEnvCalm, g_pWeather;
new g_pZHPPer, g_pNemHPPer, g_pAsnHPPer, g_pKBMult, g_pSpecCap;
new g_pNemOneShot, g_pAsnOneShot, g_pNemVsSurv, g_pNemSpeed, g_pAsnSpeed, g_pNemGrav, g_pAsnGrav, g_pMinionHP;
new g_pNemRageTime, g_pNemRageCd, g_pAsnVeilTime, g_pAsnVeilCd, g_pSpecialLeapCd;
new g_iLmTakeEnt[33];
new g_pMeteorEvery, g_pMeteorCount;
new g_pLmZDmg534, g_pLmKeep534, g_pLmHumanMult534;
new g_iPlanMode534[64], g_iPlanEv534[64], g_iPlanTotal534, g_pFullRot534, bool:g_bPlanR1534;
new g_pLmPerRound, g_pLmPerRoundVip, g_pLmOneShot, g_pLmSpecialDmg, g_pLmKillWear, g_pLmPlantTime, g_pLmTakeTime;
new g_pLmArmTime, g_pLmBeamWidth, g_pLmColorMode, g_pLmColor, g_pLmRange, g_pLmTakeRange, g_pAirdropLaser;
new g_pLmMaxRange, g_pLmBlockModes, g_pDbgDirs;
new g_pAutoJoinHumans;
new g_szLmBlockCache[64], g_iLmBlockMask = -1;
new bool:g_bHeadMarkAt, bool:g_bMarkAt;
new g_pNadeSensorArm, g_pNadeSensorLife, g_pNadeLaserArm, g_pNadeFireDmg, g_pNadeFireRad, g_pNadeFireBurn;
new g_pNadeFrostRad, g_pNadeFrostTime, g_pNadeInfectRad, g_pNadeFlareTime, g_pNadeClusterDmg;
new g_pBossPhase2, g_pBossPhase3, g_pBossRAuto, g_pBossRCdMult, g_pBossRDmgMult, g_pBossAutoAbil;
new g_pAfkTime, g_pAfkAction, g_pDropBeacon, g_pDropCompass, g_pLoopGuard, g_pLoopMax, g_pRoundStopSnd;
new g_pKillXP, g_pInfectXP, g_pWinHXP, g_pWinHAP, g_pWinZXP, g_pWinZAP, g_pBossKillXP, g_pBossKillAP, g_pBossKillVC;
new g_pSpecKillXP, g_pSpecKillAP, g_pBossBoard, g_pHsAP, g_pExchange, g_pPerkStep, g_pDailyAP, g_pAchAP, g_pAchVC;
new g_pBurnDmg, g_pZombieBurnDmg, g_pAirdropHP;
new g_msgWeather, g_iCalmPreset = -1;
new Trie:g_tSndInfo, g_iSndStopSlot;
new bool:g_bLmGiven[33];
new Float:g_fNextBeat[33];
new g_sprZone, g_sprTarget, g_sprBeacon, g_sprOrb, g_sprMark, g_sprFire, g_sprLmBeam;
new Float:g_fBossRCool, Float:g_fBossRLast, g_iBossSerial, g_iBskSlot;
new Float:g_fBossBuffEnd, Float:g_fBossEmpower, Float:g_fBossChannelEnd, g_iBossChannel, g_iBossChannelTick;
new Float:g_fBossChannelPos[3], g_iBossTethers[3];
new Float:g_fFCool[33], Float:g_fRage[33];
new Float:g_fAfkPos[33][3], Float:g_fAfkAng[33][3], g_iAfkSec[33];
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
enum
{
ZC_WALKER = 0, ZC_RUNNER, ZC_TANK, ZC_BANSHEE, ZC_LEECH, ZC_STALKER, ZC_BOMBER, ZC_FROST,
ZC_SPITTER, ZC_HULK, ZC_VOODOO, ZC_PHANTOM,
ZC_BUTCHER, ZC_HUNTER, ZC_CHARGER, ZC_ARACHNE, ZC_MAGMA, ZC_VOLT, ZC_MIMIC, ZC_BURROWER,
ZC_SIREN, ZC_BULWARK, ZC_SPOREMOTHER, ZC_NIGHTMARE
};
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
#define ZPROJ_CLASS   "vex_zproj"
#define SPORE_CLASS   "vex_spore"
#define ZP_HOOK       1
#define ZP_WEB        2
#define BEAM_MARK_HOOK 7779
#define BEAM_POINTS   0
#define BEAM_ENTPOINT 1
#define TASK_ZCTICK   33500
#define TASK_AMBREST  34000
#define TASK_MAPVOTE  34100
#define TASK_MAPCHG   34200
#define TASK_MAPHOLD  34300
#define TASK_MAPWARN  34400
new Float:g_fSkillTrig[33][3], Float:g_fLeapCool[33];
new g_iHookEnt[33], g_iHookedBy[33];
new Float:g_fPounce[33], Float:g_fCharge[33], Float:g_fChargeT0[33], Float:g_fChargeDir[33][3], g_iChargeHit[33];
new Float:g_fLava[33], Float:g_fLavaPos[33][3];
new Float:g_fNoLight[33], Float:g_fBlind[33], Float:g_fLure[33], g_iLureBy[33];
new Float:g_fWebbed[33];
new Float:g_fDisguise[33], Float:g_fBurrow[33], Float:g_fFortify[33], Float:g_fTerror[33];
new bool:g_bReflecting, g_iZcTick, g_iReflVictim, g_iReflAttacker, Float:g_fReflAmount;
new g_msgFlashlight, g_msgNVGToggle;
new g_szSprChain[64], g_sprChain, g_szSprWeb[64], g_sprWeb, g_szSprSpore[64], g_sprSpore, g_szSprEmp[64], g_sprEmp;
new g_szHookModel[96], g_szSporeModel[96];
enum { EL_FIRE = 0, EL_ICE, EL_TOXIC, EL_VOID, EL_SHOCK, EL_TOTAL };
enum { FXS_EXFIRE = 0, FXS_EXICE, FXS_EXTOXIC, FXS_EXVOID, FXS_HEAL, FXS_LEVELUP, FXS_INFECT, FXS_SHOCK, FXS_SLASH, FXS_ICE, FXS_VOID, FXS_TOXIC, FXS_TOTAL };
new const FXS_KEY[FXS_TOTAL][] = { "SPR_EXPLO_FIRE", "SPR_EXPLO_ICE", "SPR_EXPLO_TOXIC", "SPR_EXPLO_VOID", "SPR_HEAL", "SPR_LEVELUP",
"SPR_INFECT", "SPR_SHOCK", "SPR_SLASH", "SPR_ICE", "SPR_VOID", "SPR_TOXIC" };
new g_sprFx[FXS_TOTAL], g_iFxSprN;
new const BOSS_ELEM[NUM_BOSSES] = { EL_SHOCK, EL_SHOCK, EL_VOID, EL_FIRE, EL_VOID, EL_ICE, EL_SHOCK, EL_TOXIC, EL_VOID };
new Float:g_fFxHitT[33], Float:g_fFxHealT[33];
new g_pMapVote, g_pMapPool, g_pMapVoteRound, g_pMapVoteTime, g_pMapVoteExtend, g_pMapExtendRounds, g_pMapChangeDelay;
new g_pMapChooserGuard, g_pRtvRatio, g_pRtvMinPlayers, g_pRtvMinRound, g_pAmxNextmap;
new g_szCurMap[32], g_szNextMap[32], g_szMapOpt[8][32], g_iMapOptN, g_iMapExtOpt = -1, g_iMapVotes[8];
new g_iMapVoted[MAX_PLAYERS + 1], g_iMapVoteMenu[MAX_PLAYERS + 1] = { -1, ... }, g_iMapVoteLeft, g_iMapVoteWait;
new bool:g_bMapVoting, bool:g_bMapDecided, bool:g_bMapChangeNow, bool:g_bMapChanging, bool:g_bMapAwards;
new g_iMapExtends, g_iMapExtendTo, bool:g_bRtv[MAX_PLAYERS + 1], g_iRtvCount;
#define CLR_BRAND   160, 90, 255
#define CLR_CYAN    0, 220, 255
#define CLR_HUMAN   0, 200, 255
#define CLR_ZOMBIE  120, 255, 40
#define CLR_DANGER  255, 40, 40
#define CLR_WARN    255, 170, 0
#define CLR_EVENT   255, 190, 0
#define CLR_REWARD  255, 215, 0
#define CLR_COOL    180, 180, 180
#define CLR_GOOD    0, 255, 140
new const BOSS_FILE[NUM_BOSSES][] = { "brute", "banshee", "overlord", "inferno", "reaper", "frostlord", "stormcaller", "hivequeen", "void" };
new const BOSS_OLDMODEL[NUM_BOSSES][] = { "terror", "vip", "leet", "arctic", "gsg9", "sas", "gign", "guerilla", "gsg9" };
new bool:g_bBossLoaded[NUM_BOSSES], g_iBossLoadN, g_iBossLoadList[NUM_BOSSES];
new g_szPreBossRounds[128], g_iPreBossEvery, g_iPreRoundsTotal;
#define MAX_HMODELS 6
new g_szHumanModels[MAX_HMODELS][32], g_iHumanModelN, g_iHumanSkin[33];
new g_szWNade[3][96], g_szEggModel[96];
new g_iDropBodyChute, g_iDropBodyLanded, g_szDropSeqFall[24], g_szDropSeqIdle[24], g_szMineSeqName[24], g_szMineDeploySeq[24];
new Trie:g_tSnd2D, Trie:g_tSnd3D, Trie:g_tMdlDone;
new g_iPcSnd, g_iPcMdl, g_iPcGen, g_iMySnd, g_iMyMdl, g_iMyGen, g_iSndBudget, g_iMdlBudget, g_iSndSkipped, g_iMdlSkipped;
new g_iLzOwned531[33], g_iLzSel531[33], g_pLzPrices531;
new Trie:g_tSndSeen531, Trie:g_tGenSeen531, g_iSndTop531, g_iGenTop531, g_iSndRefused531, g_iGenRefused531, g_iMapSnd531;
new g_pAutoHit531, g_pBlackLight531, g_pCosFollow531, g_pSwDmg531, g_pInfAmmo531;
new Float:g_fArB536[4], bool:g_bArB536, Float:g_fArH536[32][4], g_iArHN536, g_pArenaTp536, g_iArTp536[33];
new g_pNoUrban536, g_pBdHp536, g_pBdBoss536, g_iBdGib536, g_pGunDmg536, g_pKBMax536, g_pHsSnd536, Float:g_fHsSnd536[33];
new g_iFwPcSnd, g_iFwPcMdl, g_iFwPcGen, g_iTotSnd, g_iTotMdl, g_iTotGen;
new g_szInfV531[96] = "models/vexmira/nades/v_infect.mdl", g_szInfP531[96] = "models/vexmira/nades/p_infect.mdl", g_szInfW531[96] = "models/vexmira/nades/w_infect.mdl";
new Trie:g_tPcAll531, bool:g_bPcReady531, bool:g_bPcHook531, Float:g_fGuardTime531, g_iGuardV531[33], g_iGuardP531[33], g_iGuardLog531;
#define MAX_AMB 64
new g_iAmbEnt[MAX_AMB], g_szAmbSnd[MAX_AMB][64], Float:g_fAmbVol[MAX_AMB], Float:g_fAmbAttn[MAX_AMB];
new g_iAmbPitch[MAX_AMB], bool:g_bAmbOn[MAX_AMB], g_iAmbN, g_iAmbRestored, bool:g_bAmbReplay, bool:g_bAmbMuted;
#define OVH_CLASS     "vex_ovh"
#define OVH_CTL_CLASS "vex_ovhctl"
enum { OVS_BOSSBAR = 0, OVS_BOSSICON, OVS_SMALLBAR, OVS_VIP, OVS_ADMIN, OVS_MVP, OVS_LAST, OVS_ALPHA, OVS_HUMAN47, OVS_ZOMBIE47, OVS_TOTAL };
new g_szOvhSpr[OVS_TOTAL][64], g_iOvhFrames[OVS_TOTAL], g_iOvhWidth[OVS_TOTAL], g_iOvhHeight[OVS_TOTAL], g_iOvhMode[OVS_TOTAL];
new g_iOvhBar[33], g_iOvhEmb[33], g_iOvhIcon[33], g_iOvhIconType[33], g_iOvhBarType[33], g_iOvhCtl;
new g_iRoundMvp, Float:g_fStepDist[33];
new g_iOvhTick, g_iOvhCount, g_iOvhHumans;
new g_iOvhSent[33];
new g_pOvhEnable, g_pBossBarW, g_pSmallBarW, g_pIconSize, g_pIcons, g_pOvhSelf, g_pOvhMargin, g_pOvhGap;
new g_pHudStyle, g_pHudTop, g_pHudRight, g_pHudMvp, g_pHudXp, g_pHudOvh, g_pHudObjective;
enum { CN_KM1 = 0, CN_KM2, CN_KM3, CN_KM4, CN_KM5, CN_HS, CN_KNIFE, CN_NADE, CN_MVP, CN_HWIN, CN_ZWIN, CN_BOSS,
CN_INFECT, CN_NEMESIS, CN_ASSASSIN, CN_SURVIVOR, CN_LAST, CN_LEVEL, CN_ROUND,
CN_FIRST, CN_BKILL, CN_INFD, CN_TEN, CN_UPGRADE, CN_ITEM, CN_ARENA, CN_TOTAL };
new const CSO_FILE[CN_TOTAL][] = { "km1", "km2", "km3", "km4", "km5", "hs", "knife", "nade", "mvp", "hwin", "zwin", "boss",
    "infect", "nemesis", "assassin", "survivor", "last", "level", "rnd", "fb", "bkill", "infd", "ten", "upgrade", "item", "ar" };
new const CSO_LANG[CN_TOTAL] = { 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1 };
new const CSO_LAY[CN_TOTAL] = { 'k', 'l', 'l', 'l', 'l', 'k', 'l', 'k', 'c', 'c', 'c', 'c', 'c', 'c', 'c', 'c', 'l', 'l', 'r', 'c', 'c', 'c', 'c', 'c', 'l', 'c' };
new const CSO_SHEETS[][] = { "m", "g", "fx", "rnd", "cdtr", "cden" };
new bool:g_bCsoVex531 = true, g_iCsoLang531, g_szCsoDir[8] = "c539";
#define UI_R 120
#define UI_G 200
#define UI_B 235
new g_pHudMin538;
#define CSO_ROUNDS  30
#define CSO_QMAX    4
#define TASK_CSO    41500
new g_pCso, g_pCsoNotes, g_pCsoTime, g_pCsoKmTime, g_pCsoFov, g_pCsoSnd, g_pCsoBots, g_pCsoLog, g_pCsoIcons, g_pCsoAnim;
#define FX532_TOTAL 17
new const FX532_NAME[FX532_TOTAL][] = { "fireball","flame","ember","frostburst","frostmist","shard","flare","spark",
"toxicburst","toxicmist","glow","ring","beam","beam_wide","smoke","voidburst","shockburst" };
enum { X_FIREBALL=0, X_FLAME, X_EMBER, X_FROSTBURST, X_FROSTMIST, X_SHARD, X_FLARE, X_SPARK, X_TOXICBURST, X_TOXICMIST,
X_GLOW, X_RING, X_BEAM, X_BEAMW, X_SMOKE, X_VOIDBURST, X_SHOCKBURST };
new g_iFx532[FX532_TOTAL];
#define TEFIRE_ADD532 32
new g_iGiantMode532 = 2, g_iGiantEnt532, g_iGiantSeq532 = -1;
new g_pAmbVol532, g_pAmbRe532, g_pCosSmooth532, g_pRadioText532, bool:g_bCsoC532, bool:g_bCapLow532[33], g_pTop532, g_pTopPad532, g_pTopY532;
new g_iPreCso = 1, bool:g_bCsoFile[CN_TOTAL], g_iCsoRounds;
new g_pComboTime, bool:g_bFirstBlood;
new g_szHudSig[33][400], Float:g_fHudNext[33], g_iHudXpSeen[33] = { -1, ... }, Float:g_fXpBarEnd[33];
new g_msgWL, g_msgCurW, g_msgFOV, g_msgSIcon;
new g_szWL[31][24], g_iWL[31][8], bool:g_bWL[31];
new g_iCsoCur[33] = { -1, ... }, g_iCsoArg[33], g_iCsoWpn[33], Float:g_fCsoEnd[33];
new Float:g_fCsoStart[33], g_iCsoFrm[33];
enum { CF_A = 0, CF_B, CF_G, CF_M, CF_C };
new g_iCsoQ[33][CSO_QMAX], g_iCsoQA[33][CSO_QMAX], Float:g_fCsoQT[33][CSO_QMAX], g_iCsoQn[33];
new g_iCsoIcon[33], g_iCsoShown, g_iCsoRestored;
new g_szCsoOverride[33][160];
#define OVH_MAXENT 4096
new g_iOvhOwn[OVH_MAXENT], Float:g_fOvhDz[OVH_MAXENT];
new Float:g_fOvhStand[33], Float:g_fOvhDuck[33], Float:g_fOvhStackTop[33], g_szOvhMdl[33][32];
new bool:g_bOvhSelf, Trie:g_tMdlTop;
#define CM_CATS 3
#define CM_MAX 6
#define CM_MAGIC 0x56584353
#define CM_CTL_X0 -32.0
#define CM_CTL_X1 32.0
#define CM_CTL_Y0 -48.0
#define CM_CTL_Y1 48.0
#define CM_CTL_Z0 -32.0
#define CM_CTL_Z1 96.0
enum { CMA_BONE = 0, CMA_HEAD, CMA_BACK, CMA_FOLLOW };
new const CM_TABLE[CM_CATS][] = { "vex_wing", "vex_pet", "vex_hat" };
new const CM_CATKEY[CM_CATS][] = { "COS_CAT_WING", "COS_CAT_PET", "COS_CAT_HAT" };
new g_szCmEn[CM_CATS][CM_MAX][32], g_szCmTr[CM_CATS][CM_MAX][32], g_szCmMdl[CM_CATS][CM_MAX][96];
new g_iCmPrice[CM_CATS][CM_MAX], g_iCmVip[CM_CATS][CM_MAX], g_iCmAtt[CM_CATS][CM_MAX], g_iCmSeq[CM_CATS][CM_MAX];
new Float:g_fCmOfs[CM_CATS][CM_MAX][3], Float:g_fCmAng[CM_CATS][CM_MAX][3], Float:g_fCmScale[CM_CATS][CM_MAX], Float:g_fCmFps[CM_CATS][CM_MAX];
new bool:g_bCmCtl[CM_CATS][CM_MAX];
new bool:g_bCmOk[CM_CATS][CM_MAX], g_iCmN[CM_CATS];
new g_iCmOwned[33], g_iCmSelPk[33], g_iCmEnt[33][CM_CATS];
new g_iCmOwn[OVH_MAXENT], g_iCmInfo[OVH_MAXENT];
new g_iCmPrev[33], g_iCmPrevInfo[33], Float:g_fCmPrevEnd[33];
new g_pCosPreview, g_pCosDeal, g_pCosHide;
#define MS_MAXMK 4
new g_iMsMkOf[OVH_MAXENT];
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
new Float:g_fSndIdle[33], Float:g_fSndPain[33], Float:g_fSndAtk[33], Float:g_fSndKill, g_iPainAlt[33];
new g_pBossIdleMin, g_pBossIdleMax, g_pBossPainCd, g_pBossAtkCd, g_pBossStepDist;
new g_szPrefixBoss[64] = "^3[BOSS]^1", g_szPrefixEvent[64] = "^4[^1EVENT^4]^1";
new g_szPrefixVip[64] = "^4[^3VIP^4]^1", g_szPrefixAdmin[64] = "^3[ADMIN]^1";
new g_pPrefixBoss, g_pPrefixEvent, g_pPrefixVip, g_pPrefixAdmin;
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
stock MenuInfo(menu, item)
{
new data[8], name[8], access, cb;
menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), cb);
return str_to_num(data);
}
new g_iMenuFor;
stock bool:ZcIsCode(c) { return c == 'w' || c == 'y' || c == 'r' || c == 'd' || c == 'R'; }
stock VexMenuColor(const src[], dst[], len, const lead[] = "\w")
{
if (src[0] == '\' || src[0] == '^n')
copy(dst, len, src);
else
formatex(dst, len, "%s%s", lead, src);
}
new g_szMenuLast[512];
new g_pMenuGap539;
new g_iMenuTitleLen, g_iMenuItemBytes, g_iMenuItemCnt;
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
new menu51=menu_create(t,handler);menu_setprop(menu51,MPROP_NUMBER_COLOR,"\r");return menu51;
}
// 5.3.8 plain menus (owner's sample): one title line, white numbers + items, grey for prices / disabled
stock bool:MenuPlain538() return (g_pMenuPlain538 && get_pcvar_num(g_pMenuPlain538)) ? true : false;
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
replace_string(t, charsmax(t), "\r", "\d");
replace_string(t, charsmax(t), "\w", "\d");
menu_addtext(menu, t, slot);
}
stock bool:ZcHasWord(const s[], const w[]) { return containi(s, w) != -1; }
stock ZcTagColor(const c[])
{
if (ZcHasWord(c, "KILIT") || ZcHasWord(c, "LOCK") || ZcHasWord(c, "YETERSIZ") || ZcHasWord(c, "NOT ENOUGH")
|| ZcHasWord(c, "GEREKLI") || ZcHasWord(c, "REQUIRED"))
return 'r';
if (ZcHasWord(c, "SAHIP") || ZcHasWord(c, "OWNED") || ZcHasWord(c, "KUSANIL") || ZcHasWord(c, "EQUIPPED")
|| ZcHasWord(c, "AKTIF") || ZcHasWord(c, "ACTIVE") || ZcHasWord(c, "SECILI") || ZcHasWord(c, "SELECTED"))
return 'd';
new t[32]; copy(t, charsmax(t), c); trim(t);
if (equali(t, "ON") || equali(t, "ACIK")) return 'y';
if (equali(t, "OFF") || equali(t, "KAPALI")) return 'd';
new num = -1, bool:ap = false, bool:vc = false;
for (new i = 0; c[i]; i++)
{
if (c[i] >= '0' && c[i] <= '9')
{
if (num < 0) num = 0;
if (num < 100000000) num = num * 10 + (c[i] - '0');
new j = i + 1; while (c[j] == ' ') j++;
if (!(c[j] >= '0' && c[j] <= '9'))
{
if (equali(c[j], "AP", 2)) ap = true;
else if (equali(c[j], "VC", 2) || equali(c[j], "COIN", 4)) vc = true;
if (ap || vc) break;
num = -1;
}
}
}
if ((ap || vc) && num >= 0)
{
new p = g_iMenuFor;
if (p >= 1 && p <= 32 && is_user_connected(p) && ((ap && g_iAP[p] < num) || (vc && g_iVC[p] < num)))
return 'r';
return 'y';
}
return 'd';
}
stock ZcStyleItem(const src[], dst[], len)
{
new plain[192], n, nameEnd = -1, bool:hadText;
for (new i = 0; src[i] && n < charsmax(plain); i++)
{
if (src[i] == '\' && ZcIsCode(src[i + 1]))
{
if (hadText && nameEnd < 0) nameEnd = n;
i++;
continue;
}
if (src[i] == '[' && nameEnd < 0 && hadText) nameEnd = n;
if (src[i] == '(' && nameEnd < 0 && hadText)
{
new j = i + 1; while (src[j] && src[j] != ')') j++;
if (src[j] == ')' && j - i - 1 > 3) nameEnd = n;
}
plain[n++] = src[i];
if (src[i] != ' ') hadText = true;
}
plain[n] = 0;
if (nameEnd < 0) nameEnd = n;
new name[96], desc[160], tags[160], dn, tn;
new k = min(nameEnd, charsmax(name));
copy(name, k, plain);
trim(name);
new bool:star;
for (new i = nameEnd; i < n; i++)
{
if (plain[i] == '[')
{
new close = -1;
for (new j = i + 1; j < n; j++) if (plain[j] == ']') { close = j; break; }
if (close > i)
{
new c[64]; copy(c, min(close - i - 1, charsmax(c)), plain[i + 1]);
new ct[64]; copy(ct, charsmax(ct), c); trim(ct);
if (equal(ct, "*")) { star = true; i = close; continue; }
if (equali(ct, "R") || equali(ct, "E") || equali(ct, "F") || equali(ct, "G"))
{
dn += formatex(desc[dn], charsmax(desc) - dn, "[%s]", ct);
i = close;
continue;
}
tn += formatex(tags[tn], charsmax(tags) - tn, "%s\%c[%s]", tn ? " " : "", ZcTagColor(ct), ct);
i = close;
continue;
}
}
if (dn < charsmax(desc)) desc[dn++] = plain[i];
}
desc[dn] = 0;
trim(desc);
new o = formatex(dst, len, "%s%s", equal(name,"VexCoin Market") ? "\r":"\y", name);
if (star) o += formatex(dst[o], len - o, " \y*");
if (equal(desc, "(!)")) o += formatex(dst[o], len - o, " \y(!)");
else if (desc[0]) o += formatex(dst[o], len - o, " \d%s", desc);
if (tags[0]) o += formatex(dst[o], len - o, " \d| %s", tags);
}
stock MenuAdd(menu, const text[], value)
{
new info[8], t[192];
num_to_str(value, info, charsmax(info));
ZcStyleItem(text, t, charsmax(t));
if (MenuPlain538()) { replace_string(t, charsmax(t), "\r", "\d"); replace_string(t, charsmax(t), "\y", "\w"); }
// 5.3.9c: amounts in [brackets] (prices, counts, AP / VC) are red
if (contain(t, "[") != -1) { new r539[192], o539; for (new c = 0; t[c] && o539 < charsmax(r539) - 4; c++) { if (t[c] == '[') { r539[o539++] = '\'; r539[o539++] = 'r'; } r539[o539++] = t[c]; if (t[c] == ']' && t[c + 1] && t[c + 1] != '\') { r539[o539++] = '\'; r539[o539++] = 'w'; } } r539[o539] = 0; copy(t, charsmax(t), r539); }
// 5.3.9b: one empty line under every option (vex_menu_gap 1) so the list is easier to read
if (g_pMenuGap539 && get_pcvar_num(g_pMenuGap539) && t[0] && t[strlen(t) - 1] != '^n') add(t, charsmax(t), "^n");
g_iMenuItemBytes += strlen(t) + 9;
g_iMenuItemCnt++;
menu_additem(menu, t, info);
}
stock MenuNoPage(menu)
{
g_bMenuNoPage = true;
menu_setprop(menu, MPROP_PERPAGE, 0);
}
stock VexHead(id, out[], len, const key[], const sub[] = "")
{
new t[64]; formatex(t,charsmax(t),"%L",id,key);
replace_string(t,charsmax(t),"\y",""); replace_string(t,charsmax(t),"\r","");
g_iMenuFor = id;
if(MenuPlain538()) formatex(out,len,"\rVEXMIRA \d| \w%s^n\dAP \w%d   \dVC \w%d   \dLV \w%d^n",t,g_iAP[id],g_iVC[id],g_iLevel[id]);
else formatex(out,len,"\rVEXMIRA  \d/ \y%s^n\d---------------------------^n\wAP \y%d  \wVC \y%d  \wLV \y%d^n",t,g_iAP[id],g_iVC[id],g_iLevel[id]);
if(sub[0]) { add(out,len,"\d"); add(out,len,sub); add(out,len,"^n"); }
}
stock VexOnOff(id, bool:on, out[], len)
{
formatex(out, len, "%s[%L]", on ? "\y" : "\d", id, on ? "ON" : "OFF");
}
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
formatex(t, charsmax(t), "\w%L", id, "MENU_BACK");  menu_setprop(menu, MPROP_BACKNAME, t);
formatex(t, charsmax(t), "\w%L", id, "MENU_NEXT");  menu_setprop(menu, MPROP_NEXTNAME, t);
formatex(t, charsmax(t), "\w%L", id, "MENU_EXIT");  menu_setprop(menu, MPROP_EXITNAME, t);
menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
}
stock MenuFinish(id, menu)
{
MenuProps(id, menu);
if (!g_bMenuNoPage && g_iMenuItemCnt > 0)
{
new avg = max(12, g_iMenuItemBytes / g_iMenuItemCnt);
new budget = 495 - g_iMenuTitleLen - 85;
new per = clamp(budget / avg, 3, 7);
if (per < 7 || g_iMenuItemCnt > 7)
menu_setprop(menu, MPROP_PERPAGE, per);
}
menu_display(id, menu, 0);
g_iMenuFor = 0;
}
new QUEST_NEED[NUM_QUESTS] = { 3, 6, 2500, 6000, 2, 1, 3, 1 };
new QUEST_XP[NUM_QUESTS]   = { 40, 80, 40, 80, 50, 30, 80, 45 };
new QUEST_AP[NUM_QUESTS]   = { 10, 20, 10, 20, 12, 8, 20, 12 };
new TRAIL_PRICE[NUM_TRAILS] = { 15, 15, 15, 20, 30, 50 };
new KFX_PRICE[NUM_KFX]      = { 20, 25, 25, 30, 35, 50 };
new IFX_PRICE[NUM_IFX]      = { 20, 30, 40 };
stock PlayVoxAll(const key[])
{
for (new p = 1; p <= g_iMax; p++)
{
if (is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_AMB))
PlayKey(p, key);
}
}
CurrentEnv(&light, fog[4], &weather)
{
light = 'h';
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
if (g_iEvent == EV_BLACKOUT)
{
new bl[4]; get_pcvar_string(g_pBlackLight531, bl, charsmax(bl));
light = (bl[0] >= 'a' && bl[0] <= 'z') ? bl[0] : 'b';
fog[0] = 0; fog[1] = 0; fog[2] = 0; fog[3] = 18;
weather = 0;
return;
}
if (g_iMode >= 0 && g_iMode < MODE_TOTAL && ENV_MODE_LIGHT[g_iMode])
{
light = ENV_MODE_LIGHT[g_iMode];
for (new i = 0; i < 4; i++)
fog[i] = ENV_MODE_FOG[g_iMode][i];
weather = ENV_MODE_WEATHER[g_iMode];
if (g_iEvent > EV_NONE && g_iEvent < EV_TOTAL && ENV_EV_LIGHT[g_iEvent])
{
if (ENV_EV_LIGHT[g_iEvent] < light) light = ENV_EV_LIGHT[g_iEvent];
if (ENV_EV_FOG[g_iEvent][3]) for (new i = 0; i < 4; i++) fog[i] = ENV_EV_FOG[g_iEvent][i];
if (ENV_EV_WEATHER[g_iEvent]) weather = ENV_EV_WEATHER[g_iEvent];
}
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
new g_szStyle531[64][16], bool:g_bStyleDark531;
public fw_LightStyle531(style, const val[])
{
if (style < 32 || style > 63) return FMRES_IGNORED;
copy(g_szStyle531[style], charsmax(g_szStyle531[]), val);
if (g_bStyleDark531)
{
engfunc(EngFunc_LightStyle, style, "a");
return FMRES_SUPERCEDE;
}
return FMRES_IGNORED;
}
StylesDark531(bool:dark)
{
if (dark == g_bStyleDark531) return;
g_bStyleDark531 = dark;
for (new st = 32; st < 64; st++)
{
if (!g_szStyle531[st][0]) continue;
engfunc(EngFunc_LightStyle, st, dark ? "a" : g_szStyle531[st]);
}
}
ApplyWorldEvent()
{
new light, fog[4], weather;
CurrentEnv(light, fog, weather);
g_szLight[0] = light ? light : 'm';
g_szLight[1] = 0;
#pragma unused weather
engfunc(EngFunc_LightStyle, 0, g_szLight);
StylesDark531(g_iEvent == EV_BLACKOUT);
for (new id = 1; id <= g_iMax; id++)
{
if (is_user_connected(id))
SendFogForEvent(id);
}
}
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
stock SendWeather(id, w)
{
if (!g_msgWeather || !is_user_connected(id) || is_user_bot(id))
return;
message_begin(MSG_ONE, g_msgWeather, _, id);
write_byte(clamp(w, 0, 2));
message_end();
}
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
stock FxBegin(const Float:o[3], p)
{
engfunc(EngFunc_MessageBegin, g_bFxReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, o, p);
}
stock bool:FxWants(p, const Float:o[3])
{
if (!is_user_connected(p) || is_user_bot(p))
return false;
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
return (ident == 0x50534449) ? fmt : -1;
}
stock FxHeadMark(ent, spr, life, bool:attach)
{
if (!spr)
return;
new Float:o[3];
get_entvar(ent, var_origin, o);
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
if(spr<=0) return;
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
if(spr<=0) return;
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
if(g_sprExplode<=0) return;
for (new p = 1; p <= g_iMax; p++)
{
if (!FxWants(p, o))
continue;
FxBegin(o, p);
write_byte(TE_EXPLOSION);
engfunc(EngFunc_WriteCoord, o[0]);
engfunc(EngFunc_WriteCoord, o[1]);
engfunc(EngFunc_WriteCoord, o[2] + 20.0);
write_short(g_iFx532[X_FIREBALL] ? g_iFx532[X_FIREBALL] : g_sprExplode);
write_byte(g_iFx532[X_FIREBALL] ? 22 : 30);
write_byte(g_iFx532[X_FIREBALL] ? 20 : 15);
write_byte(TE_EXPLFLAG_NOSOUND);
message_end();
}
}
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
new s532;
switch (el)
{
case EL_FIRE:  s532 = g_iFx532[X_FIREBALL];
case EL_ICE:   s532 = g_iFx532[X_FROSTBURST];
case EL_TOXIC: s532 = g_iFx532[X_TOXICBURST];
case EL_VOID:  s532 = g_iFx532[X_VOIDBURST];
default:       s532 = g_iFx532[X_SHOCKBURST];
}
if (s532) { spr = s532; scale = max(6, scale * 4 / 5); rate = max(rate, 18); }
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
stock FxBossElement(const Float:c[3], Float:radius)
{
if (!(0 <= g_iBossType < NUM_BOSSES))
return;
new scale = clamp(floatround(radius / 14.0), 10, 40);
FxExploEl(c, BOSS_ELEM[g_iBossType], scale, 14);
}
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
stock bool:SixMemeAllowed(id, const path[])
{
if (!equal(path, "vexmira/meme/", 13)) return true;
if (!(1 <= id <= g_iMax) || !is_user_connected(id) || is_user_bot(id)) return false;
if ((g_iSet[id] & SET_NO_MEME) || (g_iSet[id] & SET_NO_STREAK)) return false;
new Float:now = get_gametime();
if (now < g_fSixMemeNext[id]) return false;
g_fSixMemeNext[id] = now + floatmax(2.0, get_pcvar_float(g_pSixMemeCD));
return true;
}
stock SndPick531(path[], len)
{
if (contain(path, "|") == -1) return;
new parts[8][96], n, pos, tmp[96];
new src[256]; copy(src, charsmax(src), path);
for (new i = 0; src[i]; i++) if (src[i] == '|') src[i] = ' ';
while (n < sizeof parts && (pos = argparse(src, pos, tmp, charsmax(tmp))) != -1) if (tmp[0]) copy(parts[n++], charsmax(parts[]), tmp);
if (n) copy(path, len, parts[random(n)]); else path[0] = 0;
}
stock PlayKey(id, const key[])
{
if(!AllowAudio528()) return;
new path[256];
if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
return;
SndPick531(path, charsmax(path));
if (containi(path, ".mp3") != -1)
{
VxClientCmd527(id, "mp3 play ^"%s^"", path);
return;
}
if (get_pcvar_num(g_pLoopGuard) && SndLooped(path))
return;
if (equal(path, "vexmira/meme/", 13))
{
if (id == 0)
{
for (new p = 1; p <= g_iMax; p++)
if (is_user_connected(p) && !is_user_bot(p)) PlayKey(p, key);
return;
}
if (!SixMemeAllowed(id, path)) return;
}
VxClientCmd527(id, "spk ^"%s^"", path);
}
stock EmitKey(ent, const key[], chan = CHAN_VOICE, Float:attn = ATTN_NORM)
{
if(!AllowAudio528()) return;
new path[256];
if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
return;
SndPick531(path, charsmax(path));
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
stock EmitSafe(ent, chan, const path[], Float:vol = VOL_NORM, Float:attn = ATTN_NORM, flags = 0, pitch = PITCH_NORM)
{
if (!path[0] || (ent > 0 && is_nullent(ent)))
return;
if (SndIs2DOnly(path) || equal(path, "vexmira/meme/", 13))
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
stock StopRoundMusic()
{
for(new p52=1;p52<=g_iMax;p52++) AmbientStop52(p52);g_szAmbient49[0]=0;
for (new id = 1; id <= g_iMax; id++)
{
if (is_user_connected(id) && !is_user_bot(id))
VxClientCmd527(id, "mp3 stop");
}
}
stock StopAllClientSounds()
{
for (new id = 1; id <= g_iMax; id++)
{
if (is_user_connected(id) && !is_user_bot(id))
VxClientCmd527(id, "mp3 stop;stopsound");
}
}
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
stock FxSpriteTrail(const Float:a[3], const Float:b[3], spr, count, life, scale, speed, rnd)
{
if(spr<=0) return;
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
stock BeamEntHand(ent)
{
return ent;
}
stock FxBeamEntPoint(ent, const Float:b[3], spr, r, g, bl, width, noise, life = 3)
{
if(spr<=0) return;
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
stock FxBeamEx(const Float:a[3], const Float:b[3], spr, r, g, bl, width, noise, life, bright = 200)
{
if(spr<=0) return;
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
stock BeamCreate(const Float:start[3], const Float:end[3], r, g, b, width, bright)
{
new beam = CreateSafe51("beam");
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
stock EmitKeyPos(const Float:o[3], const key[])
{
new path[256];
if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0] || containi(path, ".mp3") != -1)
return;
SndPick531(path, charsmax(path));
if (get_pcvar_num(g_pLoopGuard) && SndLooped(path))
return;
if (SndIs2DOnly(path))
{
SpkAround(o, path, ATTN_NORM, false);
return;
}
engfunc(EngFunc_EmitAmbientSound, 0, o, path, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}
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
stock ZoneSpawn(const Float:o[3], Float:radius, r, g, b, Float:life, follow = 0, bool:sound = true)
{
new Float:pos[3];
FloorAt(o, pos);
new ent = CreateSafe51("info_target");
if (is_nullent(ent))
return 0;
set_entvar(ent, var_classname, ZONE_CLASS);
if (g_sprZone)
{
VxSM(ent, g_szSprZone);
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
get_entvar(follow, var_velocity, fv);
fv[2] = 0.0;
set_entvar(ent, var_velocity, fv);
}
new Float:radius = Float:get_entvar(ent, var_fuser3);
new c = get_entvar(ent, var_iuser2);
new r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255;
if (g_sprZone)
{
new Float:t = now - Float:get_entvar(ent, var_fuser2);
new Float:speed = (end - now < 0.6) ? 22.0 : 7.0;
new Float:amt = 150.0 + 90.0 * floatabs(floatsin(t * speed, radian));
set_entvar(ent, var_renderamt, amt);
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
stock bool:SndIs2DOnly(const path[])
{
return (TrieKeyExists(g_tSnd2D, path) && !TrieKeyExists(g_tSnd3D, path)) ? true : false;
}
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
if (!SixMemeAllowed(p, path)) continue;
VxClientCmd527(p, "spk ^"%s^"", path);
}
}
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
ChatKeyName(id, const msgKey[], const prefix[], idx)
{
new key[16], nm[48];
formatex(key, charsmax(key), "%s%d", prefix, idx);
formatex(nm, charsmax(nm), "%L", id, key);
Chat(id, msgKey, nm);
}
new const Float:HUDPOS_X[NUM_HUDPOS] = { 0.76, 0.015, 0.015, 0.76, -1.0 };
new const Float:HUDPOS_Y[NUM_HUDPOS] = { 0.40, 0.33,  0.20,  0.12,  0.80 };
stock HudPartMode(pcvar)
{
new mode = get_pcvar_num(pcvar);
if (mode >= 0)
return clamp(mode, 0, 2);
switch (clamp(get_pcvar_num(g_pHudStyle), 0, 2))
{
case 0: return 1;
case 1: return 2;
}
return 0;
}
TopBoard532(id, humans, zombies, total, const lineC[])
{
static const PAD[] = "                                                            ";
new pad = clamp(get_pcvar_num(g_pTopPad532), 10, 60);
new sp[64]; copy(sp, min(pad, charsmax(sp)), PAD);
new left = max(0, RoundTimeLeft());
new hw = get_member_game(m_iNumCTWins), zw = get_member_game(m_iNumTerroristWins);
new Float:y = get_pcvar_float(g_pTopY532);
new lab[24], alive[24];
formatex(alive, charsmax(alive), "%L", id, "TB532_ALIVE");
formatex(lab, charsmax(lab), "%L", id, "TB532_HUM");
set_dhudmessage(70, 195, 255, -1.0, y, 0, 0.0, 2.2, 0.0, 0.1);
show_dhudmessage(id, "%s   [ %d ]%s^n%s %d%s", lab, hw, sp, alive, humans, sp);
formatex(lab, charsmax(lab), "%L", id, "TB532_ZOM");
if (g_iMode == MODE_BOSS && g_iBoss && is_user_alive(g_iBoss))
{
new pct = clamp(floatround(Float:get_entvar(g_iBoss, var_health) * 100.0 / float(max(1, g_iBossMaxHP))), 0, 100);
set_dhudmessage(205, 90, 255, -1.0, y, 0, 0.0, 2.2, 0.0, 0.1);
show_dhudmessage(id, "%s[ %d ]   BOSS^n%s%d%%  HP", sp, zw, sp, pct);
}
else
{
set_dhudmessage(255, 70, 55, -1.0, y, 0, 0.0, 2.2, 0.0, 0.1);
show_dhudmessage(id, "%s[ %d ]   %s^n%s%d %s", sp, zw, lab, sp, zombies, alive);
}
set_dhudmessage(255, 212, 80, -1.0, y, 0, 0.0, 2.2, 0.0, 0.1);
show_dhudmessage(id, "%L^n%d:%02d^n%s", id, "TB532_ROUND", g_iRound, total, left / 60, left % 60, lineC);
}
DrawHud()
{
new humans = CountHumans(true), zombies = CountZombies(true);
new total = RoundsTotal();
new bool:top = (g_iFrame % 2 == 0) ? true : false;
// 5.3.8: boss teaser removed from the top line
new l1[96], l2[96], l3[96], l4[96], l5[96], head[96];
new tname[32], key[16], ev[32], mn[32], cn[32], lineC[96];
for (new id = 1; id <= g_iMax; id++)
{
if (!is_user_connected(id) || is_user_bot(id))
continue;
new t = g_iTheme[id];
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
else
formatex(lineC, charsmax(lineC), "%L", id, "TOP_C", mn, ev);
if (get_pcvar_num(g_pTop532))
{
TopBoard532(id, humans, zombies, total, lineC);
}
else if (g_iMode == MODE_BOSS && g_iBoss)
{
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
if (HudPartMode(g_pHudRight) != 0)
{
if (is_user_alive(id))
DrawAimInfo(id);
else
DrawSpecInfo(id);
}
CsoRoleIcon(id);
if ((g_iSet[id] & SET_NO_HUD) || HudPartMode(g_pHudRight) == 0)
continue;
new lvl = g_iLevel[id];
new base = XPForLevel(lvl);
new need = XPForLevel(lvl + 1);
new xpPct = (lvl >= MAX_LEVEL) ? 100 : clamp((g_iXP[id] - base) * 100 / max(1, need - base), 0, 100);
TitleName(id, id, tname, charsmax(tname));
new bool:cso = CsoOn();
if (cso)
{
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
new sk[16], skn[40], rs[24], fs[24];
formatex(sk, charsmax(sk), "BSK_%d_%d", g_iBossType, clamp(g_iBossPhase, 1, 3));
formatex(skn, charsmax(skn), "%L", id, sk);
CdText(id, g_iBossChannel != CH_NONE ? -1.0 : g_fBossRCool - get_gametime(), rs, charsmax(rs));
CdText(id, g_fEpicG[id] - get_gametime(), fs, charsmax(fs));
formatex(l4, charsmax(l4), "%L", id, "E46_BOSSHUD", skn, rs, fs);
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
if (HudPartMode(g_pHudXp) != 0)
CsoXpBar(id, xpPct);
if (l4[0])
replace_string(l4, charsmax(l4), "   ::   ", "   ");
if (l5[0])
replace_string(l5, charsmax(l5), " : ", "  ");
new body[320];
formatex(body, charsmax(body), "^n%s^n%s%s%s%s%s", l1, l3, l4[0] ? "^n" : "", l4, l5[0] ? "^n" : "", l5);
new Float:now = get_gametime();
new sig[400];
formatex(sig, charsmax(sig), "%d%s%s", pos, head, body);
if (now < g_fHudNext[id] && equal(sig, g_szHudSig[id]))
continue;
copy(g_szHudSig[id], charsmax(g_szHudSig[]), sig);
g_fHudNext[id] = now + 0.75;
if (!is_user_alive(id) || !g_bZombie[id])
{
hr = 0; hg = 220; hb = 255;
br = 235; bg = 235; bb = 245;
}
set_hudmessage(br,bg,bb,HUDPOS_X[pos],HUDPOS_Y[pos],0,0.0,1.6,0.0,0.0,1);
show_hudmessage(id,"%s%s",head,body);
continue;
}
set_hudmessage(br,bg,bb,HUDPOS_X[pos],HUDPOS_Y[pos],0,0.0,1.6,0.0,0.0,1);
show_hudmessage(id,"%s^n%s^n%s^n%s^n%s^n%s",head,l1,l2,l3,l4,l5);
}
}
CsoXpBar(id, pct)
{
if (!is_user_alive(id) || g_iPlantAction[id] || ZcCall(ZC_JETPACK,ZCOP_has,id))
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
rg_send_bartime2(id, 3, float(clamp(pct, 0, 99)), false);
g_fXpBarEnd[id] = now + 2.5;
}
else if (g_fXpBarEnd[id] > 0.0 && now >= g_fXpBarEnd[id])
{
g_fXpBarEnd[id] = 0.0;
rg_send_bartime(id, 0, false);
}
}
DrawAimInfo(id)
{
if (MineAimInfo(id))
return;
new target, body;
get_user_aiming(id, target, body, 3000);
if (!(1 <= target <= g_iMax) || !is_user_alive(target))
return;
if (g_bZombie[target] && g_fBurrow[target] > get_gametime())
return;
new name[32], role[32], key[16];
get_user_name(target, name, charsmax(name));
new hp = floatround(Float:get_entvar(target, var_health));
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
new const Float:SLOT_Y[NUM_SLOTS] = { Y_ANN, Y_ALERT, Y_PERS, Y_KILL, Y_REWARD };
stock HudDraw(id, slot, r, g, b, Float:hold, const text[])
{
// 5.3.8: one calm colour for every HUD line = the player's theme colour softened toward white
if (g_pHudCalm538 && get_pcvar_num(g_pHudCalm538))
{
new t = clamp(g_iTheme[id], 0, NUM_THEMES - 1);
r = (THEME_A[t][0] + 2 * 225) / 3; g = (THEME_A[t][1] + 2 * 225) / 3; b = (THEME_A[t][2] + 2 * 235) / 3;
}
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
copy(g_szSlotQ[id][slot], charsmax(g_szSlotQ[][]), text);
g_iSlotQC[id][slot] = (r << 16) | (g << 8) | b;
g_fSlotQH[id][slot] = hold;
g_fSlotQT[id][slot] = get_gametime();
}
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
new const CSO_PRIO[CN_TOTAL] = { 1, 2, 2, 2, 2, 1, 2, 1, 6, 8, 8, 7, 5, 7, 7, 7, 6, 4, 9, 2, 8, 7, 5, 6, 2, 9 };
new const CSO_BIT[CN_TOTAL] = { 1, 1, 1, 1, 1, 1, 1, 1, 2, 8, 8, 16, 16, 16, 16, 16, 32, 64, 4, 128, 128, 128, 128, 64, 1, 16 };
new const CSO_SND[CN_TOTAL][] = { "CSO_KM", "KILL_DOUBLE", "KILL_TRIPLE", "KILL_MULTI", "KILL_MEGA", "CSO_KM_SP", "CSO_KM_SP", "CSO_KM_SP",
"CSO_MVP", "CSO_WIN", "CSO_WIN", "CSO_ALERT", "CSO_ALERT", "CSO_BANNER", "CSO_BANNER", "CSO_BANNER", "CSO_ALERT",
"CSO_LEVEL", "CSO_BANNER", "CSO_FB", "CSO_BKILL", "CSO_INFD", "CSO_TEN", "LEVEL_UP", "CSO_KM", "COUNTDOWN_BEEP" };
CsoPrecacheVex531()
{
    g_iCsoRounds = 0;
    new path[96];
    for (new i = 0; i < sizeof CSO_SHEETS; i++)
    {
        for (new k = 0; k <= 16; k++)
        {
            formatex(path, charsmax(path), "sprites/vexmira/cso/%s%d.spr", CSO_SHEETS[i], k);
            if (file_exists(path, true)) PcGeneric(path);
            else if (k > 1) break;
        }
    }
    new fxok = 1;
    static const FXK[] = { 'a', 'b', 'c' }, FXL[] = { 'c', 'l', 'k', 'r' };
    for (new i = 0; i < sizeof FXK; i++)
        for (new j = 0; j < sizeof FXL; j++)
        {
            formatex(path, charsmax(path), "sprites/vexmira/cso/fx%c_%c.txt", FXK[i], FXL[j]);
            if (file_exists(path, true)) PcGeneric(path); else fxok = 0;
        }
    static const LNG[][] = { "en", "tr" }, FR[] = { 'm', 'g' };
    new lm[8]; copy(lm, charsmax(lm), GetResString("CSO_LANG", "tr"));
    g_iCsoLang531 = equali(lm, "both") ? 0 : (equali(lm, "en") ? 2 : 1);
    for (new n = 0; n < CN_TOTAL; n++)
    {
        if (n == CN_ROUND) continue;
        new ok = fxok;
        for (new l = 0; l < (CSO_LANG[n] ? 2 : 1); l++)
            for (new f = 0; f < sizeof FR; f++)
            {
                if (CSO_LANG[n] && g_iCsoLang531 && l != (g_iCsoLang531 == 1 ? 1 : 0)) continue;
                if (CSO_LANG[n]) formatex(path, charsmax(path), "sprites/vexmira/cso/%s_%s_%c.txt", CSO_FILE[n], LNG[l], FR[f]);
                else formatex(path, charsmax(path), "sprites/vexmira/cso/%s_%c.txt", CSO_FILE[n], FR[f]);
                if (file_exists(path, true)) PcGeneric(path); else ok = 0;
            }
        g_bCsoFile[n] = ok ? true : false;
    }
    new total = clamp(g_iPreRoundsTotal > 0 ? g_iPreRoundsTotal : 30, 1, CSO_ROUNDS);
    for (new r = 1; r <= total; r++)
    {
        formatex(path, charsmax(path), "sprites/vexmira/cso/rnd%d.txt", r);
        if (!file_exists(path, true)) break;
        PcGeneric(path);
        g_iCsoRounds = r;
    }
    g_bCsoFile[CN_ROUND] = (g_iCsoRounds > 0 && fxok) ? true : false;
    for (new l = 0; l < 2; l++)
        for (new c = 1; c <= 10; c++)
        {
            if (g_iCsoLang531 && l != (g_iCsoLang531 == 1 ? 1 : 0)) continue;
            formatex(path, charsmax(path), "sprites/vexmira/cso/cd_%s_%d.txt", LNG[l], c);
            if (file_exists(path, true)) PcGeneric(path);
        }
}
CsoPrecache()
{
    new set[16]; copy(set, charsmax(set), GetResString("CSO_CARDSET", "c539"));
    if (equali(set, "c538")) copy(set, charsmax(set), "c539"); // 5.3.8a: transparent card set (new folder so clients re-download)
    g_bCsoC532 = false;
    if (equali(set, "off"))
    {
        g_bCsoVex531 = false;
        for (new i = 0; i < CN_TOTAL; i++) g_bCsoFile[i] = false;
        return;
    }
    if (equali(set, "c539") || equali(set, "c533") || equali(set, "c532"))
    {
        copy(g_szCsoDir, charsmax(g_szCsoDir), equali(set, "c539") ? "c539" : "c533");
        CsoPrecache533();
        return;
    }
    g_bCsoVex531 = !equali(set, "cards");
    if (g_iPreCso > 0 && g_bCsoVex531 && file_exists("sprites/vexmira/cso/fx1.spr", true))
    {
        for (new i = 0; i < CN_TOTAL; i++) g_bCsoFile[i] = false;
        CsoPrecacheVex531();
        return;
    }
    g_bCsoVex531 = false;
    g_iCsoRounds = CSO_ROUNDS;
    for (new i = 0; i < CN_TOTAL; i++) g_bCsoFile[i] = false;
    if (g_iPreCso <= 0) return;
    new path[96], bool:ok = true;
    for (new card = 0; card < 6; card++)
    {
        for (new variant = 0; variant < 2; variant++)
        {
            formatex(path, charsmax(path), "sprites/vexmira/notify/card%d%s.spr", card, variant ? "_static" : "");
            if (!file_exists(path, true)) { ok = false; continue; }
            (!VxPcOk531()) ? 0 : precache_generic(path);
            formatex(path, charsmax(path), "sprites/vexmira/notify/card%d%s.txt", card, variant ? "_static" : "");
            if (!file_exists(path, true)) { ok = false; continue; }
            (!VxPcOk531()) ? 0 : precache_generic(path);
        }
    }
    if (ok)
        for (new i = 0; i < CN_TOTAL; i++) g_bCsoFile[i] = true;
}
new const C533_FILE[CN_TOTAL][] = { "km1", "km2", "km3", "km4", "km5", "hs", "knife", "nade", "mvp", "hwin", "zwin", "boss",
    "infect", "nemesis", "assassin", "survivor", "last", "level", "round", "fb", "bkill", "infd", "cd", "upgrade", "item", "ar" };
new bool:g_bHp533;
CsoPrecache533()
{
    g_bCsoVex531 = true;
    g_bCsoC532 = true;
    g_iCsoRounds = 30;
    new lm[8]; copy(lm, charsmax(lm), GetResString("CSO_LANG", "tr"));
    g_iCsoLang531 = equali(lm, "en") ? 2 : 1;
    new lg[3]; copy(lg, charsmax(lg), g_iCsoLang531 == 2 ? "en" : "tr");
    new path[96], sheet[96], line[160], n533, Trie:sheets = TrieCreate();
    for (new n = 0; n < CN_TOTAL; n++)
    {
        g_bCsoFile[n] = false;
        if (g_iPreCso <= 0) continue;
        new ok = 1;
        if (!equal(g_szCsoDir, "c539") && (n == CN_UPGRADE || n == CN_ITEM || n == CN_ARENA)) continue;
        for (new c = 1; c <= ((n == CN_TEN || n == CN_ARENA) ? 10 : 1); c++)
        {
            if (n == CN_TEN) formatex(path, charsmax(path), "sprites/vexmira/%s/cd%d_%s.txt", g_szCsoDir, c, lg);
            else if (n == CN_ARENA) formatex(path, charsmax(path), "sprites/vexmira/%s/ar%d_%s.txt", g_szCsoDir, c, lg);
            else formatex(path, charsmax(path), "sprites/vexmira/%s/%s_%s.txt", g_szCsoDir, C533_FILE[n], lg);
            if (!Txt533Sheet(path, sheet, charsmax(sheet))) { ok = 0; continue; }
            if (ZcPcGeneric(path) > 0) n533++; else ok = 0;
            if (!TrieKeyExists(sheets, sheet)) { TrieSetCell(sheets, sheet, 1); if (ZcPcGeneric(sheet) > 0) n533++; else ok = 0; }
        }
        g_bCsoFile[n] = ok ? true : false;
    }
    g_bHp533 = true;
    for (new l = 0; l <= 10; l++)
    {
        formatex(path, charsmax(path), "sprites/vexmira/%s/bh_%d.txt", equal(g_szCsoDir, "c539") ? "c539" : "c534", l);
        if (!Txt533Sheet(path, sheet, charsmax(sheet)) || ZcPcGeneric(path) <= 0) { g_bHp533 = false; continue; }
        n533++;
        if (!TrieKeyExists(sheets, sheet)) { TrieSetCell(sheets, sheet, 1); if (ZcPcGeneric(sheet) > 0) n533++; else g_bHp533 = false; }
    }
    TrieDestroy(sheets);
    #pragma unused line
    log_amx("[Vexmira] ekran kartlari: %d dosya (sprites/vexmira/%s, dil %s, boss can bari %s)", n533, g_szCsoDir, lg, g_bHp533 ? "var" : "YOK");
}
bool:Txt533Sheet(const txt[], out[], len)
{
    out[0] = 0;
    new fp = fopen(txt, "rt", true);
    if (!fp) return false;
    new line[192], a[24], b[8], c[96];
    while (!feof(fp))
    {
        fgets(fp, line, charsmax(line));
        if (parse(line, a, charsmax(a), b, charsmax(b), c, charsmax(c)) == 3 && equal(a, "crosshair")) { formatex(out, len, "sprites/%s.spr", c); break; }
    }
    fclose(fp);
    return out[0] ? file_exists(out, true) : false;
}
new const C532_FILE[CN_TOTAL][] = { "", "", "", "", "", "", "", "", "mvp", "hwin", "zwin", "boss",
    "", "", "", "", "last", "", "", "", "", "", "", "", "", "" };
CsoInitWL()
{
static const D[31][8] =
{
{ 0, 0, 0, 0, 0, 0, 0, 0 },
{ 9, 52, -1, -1, 1, 3, 1, 0 },
{ 0, 0, 0, 0, 0, 0, 0, 0 },
{ 2, 90, -1, -1, 0, 9, 3, 0 },
{ 12, 1, -1, -1, 3, 1, 4, 24 },
{ 5, 32, -1, -1, 0, 12, 5, 0 },
{ 14, 1, -1, -1, 4, 3, 6, 24 },
{ 6, 100, -1, -1, 0, 13, 7, 0 },
{ 4, 90, -1, -1, 0, 14, 8, 0 },
{ 13, 1, -1, -1, 3, 3, 9, 24 },
{ 10, 120, -1, -1, 1, 5, 10, 0 },
{ 7, 100, -1, -1, 1, 6, 11, 0 },
{ 6, 100, -1, -1, 0, 15, 12, 0 },
{ 4, 90, -1, -1, 0, 16, 13, 0 },
{ 4, 90, -1, -1, 0, 17, 14, 0 },
{ 4, 90, -1, -1, 0, 18, 15, 0 },
{ 6, 100, -1, -1, 1, 4, 16, 0 },
{ 10, 120, -1, -1, 1, 2, 17, 0 },
{ 1, 30, -1, -1, 0, 2, 18, 0 },
{ 10, 120, -1, -1, 0, 7, 19, 0 },
{ 3, 200, -1, -1, 0, 4, 20, 0 },
{ 5, 32, -1, -1, 0, 5, 21, 0 },
{ 4, 90, -1, -1, 0, 6, 22, 0 },
{ 10, 120, -1, -1, 0, 11, 23, 0 },
{ 2, 90, -1, -1, 0, 3, 24, 0 },
{ 11, 2, -1, -1, 3, 2, 25, 24 },
{ 8, 35, -1, -1, 1, 1, 26, 0 },
{ 4, 90, -1, -1, 0, 10, 27, 0 },
{ 2, 90, -1, -1, 0, 1, 28, 0 },
{ -1, -1, -1, -1, 2, 1, 29, 0 },
{ 7, 100, -1, -1, 0, 8, 30, 0 }
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
    if (g_bCsoC532)
    {
        new bool:tr2 = (g_iCsoLang531 != 2);
        if (note == CN_TEN) formatex(out, len, "vexmira/%s/cd%d_%s", g_szCsoDir, clamp(arg, 1, 10), tr2 ? "tr" : "en");
        else if (note == CN_ARENA) formatex(out, len, "vexmira/%s/ar%d_%s", g_szCsoDir, clamp(arg, 1, 10), tr2 ? "tr" : "en");
        else formatex(out, len, "vexmira/%s/%s_%s", g_szCsoDir, C533_FILE[note], tr2 ? "tr" : "en");
        #pragma unused id
        return;
    }
    if (g_bCsoVex531)
    {
        static const FRC[] = { 'a', 'b', 'g', 'm', 'c' };
        new bool:tr = g_iCsoLang531 ? (g_iCsoLang531 == 1) : (g_iLang[id] == 2);
        if (frm == CF_A || frm == CF_B || frm == CF_C)
            formatex(out, len, "vexmira/cso/fx%c_%c", FRC[frm], (note == CN_TEN && arg > 0) ? 'r' : CSO_LAY[note]);
        else if (note == CN_TEN && arg > 0)
            formatex(out, len, "vexmira/cso/cd_%s_%d", tr ? "tr" : "en", clamp(arg, 1, 10));
        else if (note == CN_ROUND)
            formatex(out, len, "vexmira/cso/rnd%d", arg);
        else if (CSO_LANG[note])
            formatex(out, len, "vexmira/cso/%s_%s_%c", CSO_FILE[note], tr ? "tr" : "en", FRC[frm]);
        else
            formatex(out, len, "vexmira/cso/%s_%c", CSO_FILE[note], FRC[frm]);
        return;
    }
    new card = 5;
    switch (note)
    {
        case CN_ROUND: card = 0;
        case CN_HWIN: card = 1;
        case CN_ZWIN: card = 2;
        case CN_MVP: card = 3;
        case CN_BOSS, CN_NEMESIS, CN_ASSASSIN, CN_SURVIVOR, CN_LAST: card = 4;
        case CN_TEN: card = 5;
    }
    formatex(out, len, "vexmira/notify/card%d%s", card, get_pcvar_num(g_pCsoAnim) ? "" : "_static");
}
stock CsoFrameAt(note, Float:t, Float:dur, cur)
{
    if (!g_bCsoVex531 || g_bCsoC532 || get_pcvar_num(g_pCsoAnim) <= 0)
        return CF_M;
    if (t < 0.08)
        return CF_A;
    if (t < 0.18)
        return CF_B;
    if (dur - t < 0.2 && cur >= CF_G)
        return CF_C;
    if (note == CN_ROUND || note == CN_TEN)
        return CF_M;
    new Float:p = t - 0.18;
    p -= float(floatround(p / 0.8, floatround_floor)) * 0.8;
    return p < 0.2 ? CF_G : CF_M;
}
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
return (note >= 0 && note < CN_TOTAL && (CsoNotesMask533() & CSO_BIT[note])) ? true : false;
}
stock CsoNotesMask533()
{
new v = get_pcvar_num(g_pCsoNotes);
return (v <= 0 || v >= 65536) ? 0xFFFF : v;
}
stock bool:CsoOn()
{
return get_pcvar_num(g_pCso) > 0 && g_iPreCso > 0;
}
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
VexCardText532(id, note, const title[], const detail[], r, g, b, Float:hold)
{
new bool:big = !(note <= CN_NADE || note == CN_FIRST || note == CN_INFD || note == CN_TEN || note == CN_HS);
new Float:y = big ? (g_bCapLow532[id] ? (note == CN_MVP ? 0.74 : 0.665) : (note == CN_MVP ? 0.36 : 0.25)) : 0.62;
new framed[160];
copy(framed, charsmax(framed), title);
if (get_pcvar_num(g_pHudMin538)) { r = UI_R; g = UI_G; b = UI_B; hold = floatmin(hold, 2.5); }
set_dhudmessage(r, g, b, -1.0, y, 0, 0.0, hold, 0.06, 0.35);
show_dhudmessage(id, "%s", framed);
if (detail[0])
{
set_dhudmessage(200, 205, 210, -1.0, y + (big ? 0.045 : 0.035), 0, 0.0, hold, 0.12, 0.35);
show_dhudmessage(id, "%s", detail);
}
if (big && !get_pcvar_num(g_pHudMin538) && !g_bCapLow532[id] && is_user_connected(id) && !is_user_bot(id))
{
message_begin(MSG_ONE_UNRELIABLE, g_msgFade, _, id);
write_short(1 << 10); write_short(0); write_short(0x0000);
write_byte(r); write_byte(g); write_byte(b); write_byte(28);
message_end();
}
}
stock bool:VexNotify(id, note, arg = 0)
{
if (id < 1 || id > g_iMax || note < 0 || note >= CN_TOTAL || !is_user_connected(id) || is_user_bot(id))
return false;
new title[96], detail[128], r = 55, g = 205, b = 255;
new Float:hold = 2.4;
new bool:tr = (g_iLang[id] == 2);
switch (note)
{
case CN_ROUND:
{
if (tr) formatex(title, charsmax(title), "TUR %d / %d", g_iRound, RoundsTotal());
else formatex(title, charsmax(title), "ROUND %d / %d", g_iRound, RoundsTotal());
new key[24]; formatex(key, charsmax(key), "MODE_NAME_%d", clamp(g_iMode, 0, MODE_TOTAL - 1));
formatex(detail, charsmax(detail), "%L", id, key);
hold = 2.8;
}
case CN_HWIN, CN_ZWIN:
{
new bool:human = (note == CN_HWIN);
if (human) VexCopy(title, charsmax(title), tr, "HUMANS VICTORIOUS", "INSANLAR KAZANDI");
else VexCopy(title, charsmax(title), tr, "ZOMBIES VICTORIOUS", "ZOMBILER KAZANDI");
if (tr) formatex(detail, charsmax(detail), "TUR %d TAMAMLANDI", g_iRound);
else formatex(detail, charsmax(detail), "ROUND %d COMPLETE", g_iRound);
r = human ? 65 : 90; g = human ? 190 : 235; b = human ? 255 : 85; hold = 4.0;
}
case CN_MVP:
{
new mvp = g_iRoundMvp;
if (mvp < 1 || mvp > g_iMax || !is_user_connected(mvp)) return false;
new name[32]; get_user_name(mvp, name, charsmax(name));
copy(title, charsmax(title), tr ? "TURUN YILDIZI" : "ROUND MVP");
formatex(detail, charsmax(detail), "%s | %d DMG | %d KILLS | %d INFECTS", name, g_iRoundDmg[mvp], g_iRoundKills[mvp], g_iRoundInf[mvp]);
r = 255; g = 190; b = 55; hold = 4.0;
}
case CN_BOSS:
{
new key[24]; formatex(key, charsmax(key), "BOSS_NAME_%d", clamp(g_iBossType, 0, NUM_BOSSES - 1));
copy(title, charsmax(title), tr ? "BOSS TURU" : "BOSS ROUND");
new prep[32];
if (g_bFinalBoss) VexCopy(prep, charsmax(prep), tr, "FINAL ROUND", "SON TUR");
else VexCopy(prep, charsmax(prep), tr, "PREPARE", "HAZIR OL");
formatex(detail, charsmax(detail), "%L | %s", id, key, prep);
r=BOSS_RGB[clamp(g_iBossType,0,NUM_BOSSES-1)][0]; g=BOSS_RGB[clamp(g_iBossType,0,NUM_BOSSES-1)][1]; b=BOSS_RGB[clamp(g_iBossType,0,NUM_BOSSES-1)][2]; hold=3.8;
}
case CN_INFECT: { VexCopy(title,charsmax(title),tr,"INFECTION","ENFEKSIYON"); VexCopy(detail,charsmax(detail),tr,"THE OUTBREAK HAS BEGUN","SALGIN BASLADI"); r=100; g=235; b=65; }
case CN_NEMESIS: { copy(title,charsmax(title),"NEMESIS"); VexCopy(detail,charsmax(detail),tr,"THE HUNT BEGINS","AV BASLADI"); r=255; g=70; b=70; }
case CN_ASSASSIN: { VexCopy(title,charsmax(title),tr,"ASSASSIN","SUIKASTCI"); VexCopy(detail,charsmax(detail),tr,"WATCH THE DARKNESS","KARANLIGA DIKKAT"); r=190; g=85; b=255; }
case CN_SURVIVOR: { VexCopy(title,charsmax(title),tr,"SURVIVOR","KURTULAN"); VexCopy(detail,charsmax(detail),tr,"HUMANITY'S LAST HOPE","INSANLARIN UMUDU"); r=65; g=200; b=255; }
case CN_LAST: { VexCopy(title,charsmax(title),tr,"LAST HUMAN","SON INSAN"); VexCopy(detail,charsmax(detail),tr,"SURVIVE","HAYATTA KAL"); r=255; g=195; b=55; }
case CN_LEVEL: { if (tr) formatex(title,charsmax(title),"SEVIYE %d",arg); else formatex(title,charsmax(title),"LEVEL %d",arg); VexCopy(detail,charsmax(detail),tr,"NEW REWARDS UNLOCKED","YENI ODULLER ACILDI"); r=65; g=220; b=255; }
case CN_TEN: { VexCopy(title,charsmax(title),tr,"10 SECONDS LEFT","SON 10 SANIYE"); VexCopy(detail,charsmax(detail),tr,"THE ROUND IS ENDING","TUR BITIYOR"); r=255; g=75; b=65; hold=1.8; }
case CN_BKILL: { VexCopy(title,charsmax(title),tr,"BOSS DEFEATED","BOSS YENILDI"); VexCopy(detail,charsmax(detail),tr,"THE ARENA IS SAFE","ARENA GUVENDE"); r=95; g=235; b=160; hold=3.2; }
case CN_FIRST: { VexCopy(title,charsmax(title),tr,"FIRST BLOOD","ILK KAN"); VexCopy(detail,charsmax(detail),tr,"FIRST ELIMINATION","ILK ELEME"); r=255; g=80; b=70; }
case CN_HS: { VexCopy(title,charsmax(title),tr,"HEADSHOT","KAFA VURUSU"); VexCopy(detail,charsmax(detail),tr,"PRECISE HIT","TEMIZ ISABET"); r=255; g=190; b=55; hold=1.0; }
case CN_KNIFE: { VexCopy(title,charsmax(title),tr,"KNIFE ELIMINATION","BICAK ELEMESI"); VexCopy(detail,charsmax(detail),tr,"CLOSE QUARTERS","YAKIN MESAFE"); r=255; g=110; b=70; hold=1.2; }
case CN_NADE: { VexCopy(title,charsmax(title),tr,"GRENADE ELIMINATION","BOMBA ELEMESI"); VexCopy(detail,charsmax(detail),tr,"EXPLOSIVE HIT","PATLAYICI ISABETI"); r=255; g=145; b=65; hold=1.2; }
default:
{
static const EN[CN_TOTAL][] = {"ELIMINATION","DOUBLE ELIMINATION","TRIPLE ELIMINATION","MULTI ELIMINATION","DOMINATING","HEADSHOT","KNIFE ELIMINATION","GRENADE ELIMINATION","ROUND MVP","HUMANS VICTORIOUS","ZOMBIES VICTORIOUS","BOSS ROUND","INFECTION","NEMESIS","ASSASSIN","SURVIVOR","LAST HUMAN","LEVEL UP","ROUND","FIRST BLOOD","BOSS DEFEATED","INFECTED","10 SECONDS LEFT", "CLASS UPGRADE","ITEM","BOSS ARENA" };
static const TR[CN_TOTAL][] = {"ELEME","CIFT ELEME","UC LU ELEME","COKLU ELEME","EZICI SERI","KAFA VURUSU","BICAK ELEMESI","BOMBA ELEMESI","TURUN YILDIZI","INSANLAR KAZANDI","ZOMBILER KAZANDI","BOSS TURU","ENFEKSIYON","NEMESIS","SUIKASTCI","KURTULAN","SON INSAN","SEVIYE ATLANDI","TUR","ILK KAN","BOSS YENILDI","BULASTI","SON 10 SANIYE", "SINIF GELISTI","ESYA","BOSS ARENASI" };
if (tr) copy(title,charsmax(title),TR[note]); else copy(title,charsmax(title),EN[note]);
VexCopy(detail,charsmax(detail),tr,"CONFIRMED","BASARILI"); r=255; g=190; b=55; hold=1.25;
}
}
if (g_iSet[id] & SET_NO_FX) return true;
if (g_szCsoOverride[id][0])
{
    copy(title, charsmax(title), g_szCsoOverride[id]);
    detail[0] = 0;
}
VexCardText532(id, note, title, detail, r, g, b, hold);
return true;
}
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
    CsoFov(id, clamp(get_pcvar_num(g_pCsoFov), 10, 89));
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
    if (note == CN_TEN || note == CN_ARENA)
        return 1.0;
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
bool:CsoNotify(id, note, arg = 0)
{
    if (CsoNotifyImg(id, note, arg))
        return true;
    return VexNotify(id, note, arg);
}
bool:CsoNotifyImg(id, note, arg = 0)
{
    if (id < 1 || id > g_iMax || note < 0 || note >= CN_TOTAL || !is_user_connected(id) || (g_iSet[id] & SET_NO_FX))
        return false;
    if (get_pcvar_num(g_pCsoLog)) log_amx("[CSO] istek not=%d #%d on=%d dosya=%d bit=%d canli=%d", note, id, CsoOn(), g_bCsoFile[note], (CsoNotesMask533() & CSO_BIT[note]) ? 1 : 0, is_user_alive(id));
    if (!CsoOn() || !g_bCsoFile[note] || !(CsoNotesMask533() & CSO_BIT[note]))
        return false;
    if (g_bCsoC532 && note == CN_TEN && arg <= 0)
        return false;
    if (note == CN_ROUND && (arg < 1 || arg > g_iCsoRounds))
        return false;
    if (!is_user_alive(id) || (is_user_bot(id) && !get_pcvar_num(g_pCsoBots)))
        return false;
    new clip, ammo, w = get_user_weapon(id, clip, ammo);
    if (w < 1 || w > 30 || !g_bWL[w])
        return false;
    new cur = g_iCsoCur[id];
    if ((note == CN_TEN && cur == CN_TEN) || note == CN_ARENA) // 5.3.9a: arena countdown replaces itself every second (was queued -> 2 s per card, out of sync with the voice)
    {
        CsoRestore(id, false);
        if (!CsoApply(id, note, arg, CsoDur(note), false))
            return false;
        CsoSub(id, note, arg);
        return true;
    }
    new bool:km = CSO_PRIO[note] <= 2;
    if (cur >= 0 && CSO_PRIO[cur] > 2)
    {
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
    if (cur >= 0)
    {
        if (CSO_PRIO[cur] > CSO_PRIO[note] && g_fCsoEnd[id] - get_gametime() > 0.3)
        {
            CsoSound(id, note);
            return true;
        }
        CsoRestore(id, false);
    }
    new bool:shown = CsoApply(id, note, arg, CsoDur(note), (note == CN_TEN || note == CN_ARENA) ? false : true);
    if (shown && note == CN_TEN)
        CsoSub(id, note, arg);
    return shown;
}
stock CsoHudAll(note, arg, slot, r, g, b, Float:hold, const key[], iVal = 0)
{
    #pragma unused slot, r, g, b, hold, key, iVal
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id))
            continue;
        CsoNotify(id, note, arg);
    }
}
CsoSub(id, note, arg)
{
    if (g_bCsoC532) return;
    g_bCapLow532[id] = g_bCsoC532 && C532_FILE[note][0] != 0;
    VexNotify(id, note, arg);
    g_bCapLow532[id] = false;
}
new g_iHpLvl533[33] = { -1, ... }, g_iHpWpn533[33], g_pHpCard533;
HpRestore533(id)
{
    new w = g_iHpWpn533[id];
    g_iHpLvl533[id] = -1; g_iHpWpn533[id] = 0;
    if (w < 1 || w > 30 || !is_user_connected(id) || g_iCsoCur[id] >= 0) return;
    CsoSendWL(id, g_szWL[w], w);
    new fov = is_user_alive(id) ? get_member(id, m_iFOV) : 90;
    CsoFov(id, fov > 0 ? fov : 90);
    if (is_user_alive(id)) { new clip, ammo, cw = get_user_weapon(id, clip, ammo); if (cw >= 1 && cw <= 30) CsoCurW(id, cw, clip); }
}
BossHpTick533()
{
    new boss = g_iBoss;
    new bool:fight = g_bHp533 && g_bCsoC532 && get_pcvar_num(g_pHpCard533) && g_iMode == MODE_BOSS && boss >= 1 && boss <= g_iMax && is_user_alive(boss) && !g_bRoundEnded;
    new lvl = 0;
    if (fight) { new pct = floatround(Float:get_entvar(boss, var_health) * 100.0 / float(max(1, g_iBossMaxHP)), floatround_ceil); lvl = clamp((pct + 9) / 10, 0, 10); }
    for (new id = 1; id <= g_iMax; id++)
    {
        if (!is_user_connected(id) || is_user_bot(id)) { g_iHpLvl533[id] = -1; continue; }
        if (g_iCsoCur[id] >= 0) { g_iHpLvl533[id] = -1; g_iHpWpn533[id] = 0; continue; }
        new clip, ammo, w = is_user_alive(id) ? get_user_weapon(id, clip, ammo) : 0;
        new bool:want = fight && id != boss && is_user_alive(id) && w >= 1 && w <= 30 && g_bWL[w] && CsoFovOk(id) && !(g_iSet[id] & SET_NO_FX)
            && w != CSW_AWP && w != CSW_SCOUT && w != CSW_SG550 && w != CSW_G3SG1 && w != CSW_AUG && w != CSW_SG552;
        if (!want) { if (g_iHpLvl533[id] >= 0) HpRestore533(id); continue; }
        if (lvl == g_iHpLvl533[id] && w == g_iHpWpn533[id]) continue;
        if (g_iHpWpn533[id] && g_iHpWpn533[id] != w) CsoSendWL(id, g_szWL[g_iHpWpn533[id]], g_iHpWpn533[id]);
        new nm[32]; formatex(nm, charsmax(nm), "vexmira/%s/bh_%d", equal(g_szCsoDir, "c539") ? "c539" : "c534", lvl);
        CsoFov(id, clamp(get_pcvar_num(g_pCsoFov), 10, 89));
        CsoSendWL(id, nm, w); CsoCurW(id, w, clip);
        g_iHpLvl533[id] = lvl; g_iHpWpn533[id] = w;
    }
}
public task_CsoTick()
{
    BossHpTick533();
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
                CsoRestore(id);
                continue;
            }
            if (w != g_iCsoWpn[id])
            {
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
                new frm = CsoFrameAt(g_iCsoCur[id], now - g_fCsoStart[id], g_fCsoEnd[id] - g_fCsoStart[id], g_iCsoFrm[id]);
                if (frm != g_iCsoFrm[id])
                    CsoSendFrame(id, frm, w, clip);
                continue;
            }
            CsoRestore(id, g_iCsoQn[id] == 0);
        }
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
                g_iCsoQn[id] = 0;
                break;
            }
        }
    }
}
VexLocalizedAnnounce(id, const key[], r, g, b, Float:hold)
{
    if (id < 1 || id > g_iMax || !is_user_connected(id) || is_user_bot(id) || (g_iSet[id] & SET_NO_FX)) return;
    new txt[192];
    LookupLangKey(txt, charsmax(txt), key, id);
    replace_all(txt, charsmax(txt), "%d", ""); replace_all(txt, charsmax(txt), "%s", ""); replace_all(txt, charsmax(txt), "%i", "");
    copy(g_szCsoOverride[id], charsmax(g_szCsoOverride[]), txt);
    VexNotify(id, CN_INFD, 0);
    g_szCsoOverride[id][0] = 0;
    #pragma unused r, g, b, hold
}
VexLocalizedAnnounceAll(const key[], r, g, b, Float:hold)
{
for(new id=1;id<=g_iMax;id++)
VexLocalizedAnnounce(id,key,r,g,b,hold);
}
VexCopy(out[], len, bool:tr, const en[], const tu[])
{
if (tr) copy(out, len, tu);
else copy(out, len, en);
}
VexPlainAnnounce(id,const en[],const tu[],r,g,b,Float:hold)
{
    if (id < 1 || id > g_iMax || !is_user_connected(id) || is_user_bot(id) || (g_iSet[id] & SET_NO_FX)) return;
    VexCopy(g_szCsoOverride[id], charsmax(g_szCsoOverride[]), g_iLang[id] == 2, en, tu);
    VexNotify(id, CN_INFD, 0);
    g_szCsoOverride[id][0] = 0;
    #pragma unused r, g, b, hold
}
VexCountdown(id, seconds)
{
    if (id < 1 || id > g_iMax || !is_user_connected(id) || is_user_bot(id) || (g_iSet[id] & SET_NO_FX)) return;
    if (g_iLang[id] == 2)
        formatex(g_szCsoOverride[id], charsmax(g_szCsoOverride[]), "TUR BASLAMASINA %d^nSAVASA HAZIR OL", seconds);
    else
        formatex(g_szCsoOverride[id], charsmax(g_szCsoOverride[]), "ROUND STARTS IN %d^nPREPARE FOR COMBAT", seconds);
    if (g_bCsoC532 && seconds >= 1 && seconds <= 10 && g_bModePicked47 && g_iMode == MODE_BOSS && g_bArB536 && g_iArHN536 > 0 && get_pcvar_num(g_pArenaTp536) && g_bCsoFile[CN_ARENA])
    {
        if (g_iLang[id] == 2) formatex(g_szCsoOverride[id], charsmax(g_szCsoOverride[]), "%d SANIYE SONRA BOSS ARENASINA ISINLANACAKSIN", seconds);
        else formatex(g_szCsoOverride[id], charsmax(g_szCsoOverride[]), "TELEPORT TO THE BOSS ARENA IN %d", seconds);
        CsoNotify(id, CN_ARENA, seconds);
    }
    else if (g_bCsoC532) { if (seconds >= 1 && seconds <= 10) CsoNotify(id, CN_TEN, seconds); }
    else if (seconds <= 10 || !g_bCsoVex531) CsoNotify(id, CN_TEN, seconds);
    else VexNotify(id, CN_TEN, seconds);
    g_szCsoOverride[id][0] = 0;
}
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
stock Translate(out[], len, const key[], id)
{
new target = id;
if (!LookupLangKey(out, len, key, target))
copy(out, len, key);
}
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
AsciiBar(bar, 20, pct);
for (new id = 1; id <= g_iMax; id++)
{
if (!is_user_connected(id) || is_user_bot(id) || g_iHpLvl533[id] >= 0)
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
CdText(id, Float:cd, out[], len)
{
if (cd < -0.5)
formatex(out, len, "%L", id, "HUD_ACTIVE");
else if (cd > 0.0)
formatex(out, len, "%L", id, "HUD_SECONDS", floatround(cd, floatround_ceil));
else
formatex(out, len, "%L", id, "HUD_READY");
}
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
#define OVH_ICONBIT_VIP   1
#define OVH_ICONBIT_ADMIN 2
#define OVH_ICONBIT_MVP   4
#define OVH_ICONBIT_LAST  8
#define OVH_ICONBIT_ALPHA 16
#define OVH_MAGIC 0x56584F48
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
new ent = CreateSafe51("info_target");
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
CmTick(now);
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
if ((g_iOvhTick + id) % 5 == 0)
OvhRefresh(id, on);
if ((g_iOvhTick + id) % 2 == 0 && (g_iOvhBar[id] || g_iOvhEmb[id] || g_iOvhIcon[id]))
OvhUpdate(id);
if (g_bZombie[id] && (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id]))
VoiceTick(id, now);
else
g_fStepDist[id] = 0.0;
}
}
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
else if (g_bZombie[id] && g_szOvhSpr[OVS_ZOMBIE47][0])
barType = OVS_ZOMBIE47;
else if (g_bZombie[id] && g_szOvhSpr[OVS_SMALLBAR][0])
barType = OVS_SMALLBAR;
}
if (!g_bBoss[id])
icon = OvhIconFor(id);
}
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
set_entvar(g_iOvhEmb[id], var_frame, float(clamp(Ovh538(OVS_BOSSICON) ? 12 + g_iBossType : g_iBossType, 0, g_iOvhFrames[OVS_BOSSICON] - 1)));
}
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
stock bool:Ovh538(slot) return (contain(g_szOvhSpr[slot], "538") != -1) ? true : false;
new Float:g_fOvhShown[33], Float:g_fOvhPrevHp[33], Float:g_fOvhFlash[33];
Ovh538Frame(id, slot, Float:pct)
{
new Float:now = get_gametime();
new Float:hp = Float:get_entvar(id, var_health);
if (hp < g_fOvhPrevHp[id] - 0.5) g_fOvhFlash[id] = now + 0.25;
g_fOvhPrevHp[id] = hp;
if (g_fOvhShown[id] <= 0.0 || pct > g_fOvhShown[id]) g_fOvhShown[id] = pct;
else g_fOvhShown[id] = floatmax(pct, g_fOvhShown[id] - 3.0);
new p = clamp(floatround(g_fOvhShown[id]), 0, 100);
if (pct > 0.0 && p < 1) p = 1;
if (slot == OVS_BOSSBAR) return (g_fOvhFlash[id] > now) ? 26 + p / 10 : p / 4;
return (g_fOvhFlash[id] > now) ? 51 + p / 10 : p / 2;
}
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
if (id == 0x54534449)
{
fseek(fp, 108, SEEK_SET);
fread(fp, raw, BLOCK_INT);
hdrTop = Float:raw;
fseek(fp, 164, SEEK_SET);
fread(fp, numseq, BLOCK_INT);
fread(fp, seqidx, BLOCK_INT);
numseq = clamp(numseq, 0, 512);
// 5.3.9c: the overhead bar must sit ABOVE the model: tallest standing sequence box (idle / walk / run /
// ref_aim ...; jumps, deaths, crouch ignored) + eye height, not only idle1 (many CSO zombies report a short idle1)
new Float:tallest = -1.0, Float:eyeZ;
fseek(fp, 84, SEEK_SET); fread(fp, raw, BLOCK_INT); eyeZ = Float:raw;
for (new i = 0; i < numseq; i++)
{
fseek(fp, seqidx + i * 176, SEEK_SET);
fread_blocks(fp, lab, 32, BLOCK_CHAR);
lab[31] = 0;
fseek(fp, seqidx + i * 176 + 116, SEEK_SET);
fread(fp, raw, BLOCK_INT);
z = Float:raw;
if (z < 4.0 || z > 400.0)
continue;
if (equali(lab, "idle1")) idle = z;
else if (equali(lab, "crouch_idle")) duck = z;
if (containi(lab, "crouch") != -1 || containi(lab, "jump") != -1 || containi(lab, "death") != -1 || containi(lab, "die") != -1 || containi(lab, "swim") != -1 || containi(lab, "treadwater") != -1)
continue;
if (containi(lab, "idle") != -1 || containi(lab, "walk") != -1 || containi(lab, "run") != -1 || containi(lab, "ref_") != -1 || containi(lab, "shoot") != -1)
tallest = floatmax(tallest, z);
}
if (hdrTop > 8.0 && hdrTop < 400.0 && floatabs(hdrTop - 36.0) > 0.5)
stand = hdrTop;
else if (idle > 0.0)
stand = idle;
if (tallest > 0.0) stand = floatmax(stand, floatmin(tallest, (idle > 0.0 ? idle : stand) * 1.6));
if (eyeZ > 8.0 && eyeZ < 300.0) stand = floatmax(stand, eyeZ + 8.0);
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
Float:OvhTopOf(id)
{
if (!(1 <= id <= g_iMax))
return 40.0;
OvhModelTops(id);
new Float:head = OverheadTop52(id);
if (g_iOvhBar[id] || g_iOvhEmb[id] || g_iOvhIcon[id])
return head + g_fOvhStackTop[id];
return head + floatclamp(get_pcvar_float(g_pOvhMargin), 0.0, 64.0);
}
OvhSpawn(id, slot, Float:scale)
{
if (!g_szOvhSpr[slot][0])
return 0;
new ent = CreateSafe51("info_target");
if (is_nullent(ent))
return 0;
if (ent >= OVH_MAXENT)
{
set_entvar(ent, var_flags, FL_KILLME);
return 0;
}
set_entvar(ent, var_classname, OVH_CLASS);
VxSM(ent, g_szOvhSpr[slot]);
set_entvar(ent, var_solid, SOLID_NOT);
set_entvar(ent, var_movetype, MOVETYPE_NOCLIP);
set_entvar(ent, var_iuser1, id);
set_entvar(ent, var_iuser2, OVH_MAGIC);
g_iOvhSent[id] = -1;
if (1 <= id <= 32) { g_fOvhShown[id] = 0.0; g_fOvhPrevHp[id] = Float:get_entvar(id, var_health); }
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
if (slot0 == OVS_ZOMBIE47 || (slot0 == OVS_BOSSBAR && g_iOvhFrames[slot0] == 104))
frameNow = clamp(floatround(hp0 / floatmax(1.0, mx0) * 25.0), 0, 25) * 4 + ((g_iOvhTick / 2) % 4);
if (Ovh538(slot0))
frameNow = min(Ovh538Frame(id, slot0, floatclamp(hp0 / floatmax(1.0, mx0) * 100.0, 0.0, 100.0)), g_iOvhFrames[slot0] - 1);
}
new Float:gap = floatclamp(get_pcvar_float(g_pOvhGap), 0.0, 32.0);
new Float:z = floatmax(14.0,floatclamp(get_pcvar_float(g_pOvhMargin), 0.0, 64.0));
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
new Float:o[3], Float:p[3];
get_entvar(id, var_origin, o);
new Float:head = OverheadTop52(id);
for (new i = 0; i < n; i++)
{
p[0] = o[0];
p[1] = o[1];
p[2] = o[2] + head + g_fOvhDz[ents[i]];
engfunc(EngFunc_SetOrigin, ents[i], p);
}
if(icon && g_iOvhIconType[id]>=0) { new it=g_iOvhIconType[id]; if(Ovh538(it)) { static const IF538[OVS_TOTAL]={8,8,0,1,0,3,2,4,0,0}; set_entvar(icon,var_frame,float(min(IF538[it],g_iOvhFrames[it]-1))); } else set_entvar(icon,var_frame,float((g_iOvhTick/2)%max(1,g_iOvhFrames[it]))); }
new sig = (frameNow + 1) | (hidden ? 0x1000 : 0) | (bar << 13);
if (sig == g_iOvhSent[id])
return;
g_iOvhSent[id] = sig;
if (bar)
set_entvar(bar, var_frame, float(max(0, frameNow)));
for (new i = 0; i < n; i++)
set_entvar(ents[i], var_effects, hidden ? EF_NODRAW : 0);
}
public fw_AddToFullPackPost(es, e, ent, host, hostflags, player, pSet)
{
if (g_iGiantEnt532 && get_orig_retval() && (ent == g_iGiantEnt532 || ent == g_iBoss))
GiantPack532(es, ent, host);
if (!player && ent < OVH_MAXENT && g_iMsMkOf[ent])
return MsMkPack(es, host);
if (!player && ent > g_iMax && ent < OVH_MAXENT && g_iCmOwn[ent])
return CmPack(es, ent, host);
if (player || !g_iOvhCount || ent >= OVH_MAXENT || ent <= g_iMax)
return FMRES_IGNORED;
new id = g_iOvhOwn[ent];
if (!id || !get_orig_retval())
return FMRES_IGNORED;
if (!g_bOvhSelf && ((host == id && (!g_iCamera47[id] || is_nullent(g_iCamera47[id]))) || (get_entvar(host, var_iuser1) == 4 && get_entvar(host, var_iuser2) == id)))
{
set_es(es, ES_Effects, get_es(es, ES_Effects) | EF_NODRAW);
return FMRES_IGNORED;
}
new Float:o[3];
get_entvar(id, var_origin, o);
o[2] += OverheadTop52(id) + g_fOvhDz[ent];
set_es(es, ES_Origin, o);
return FMRES_IGNORED;
}
new const SOUND_KEYS_V3[][] =
{
"HUNTER_IMPACT", "CHARGER_IMPACT", "ARACHNE_WEBHIT", "BURROWER_ERUPT", "SPOREMOTHER_BURST", "MIMIC_REVEAL", "VOLT_ZAP",
"HOOK_THROW", "HOOK_CHAIN", "HOOK_HIT", "HOOK_PULL", "HOOK_MISS"
};
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
new g_szSkyRot531[8][32], g_iSkyRotN531, g_iSkyRotPos531;
bool:VxIsSpecialWeapon531(id, weapon)
{
if (VxIndex(weapon) >= 0) return true;
new WeaponIdType:wid = get_member(weapon, m_iId);
static const GEAR_BASE[][2] = { {1, _:WEAPON_M249}, {2, _:WEAPON_AK47}, {3, _:WEAPON_AWP}, {4, _:WEAPON_M4A1}, {5, _:WEAPON_M249}, {6, _:WEAPON_M4A1} };
for (new k = 0; k < sizeof GEAR_BASE; k++)
if (_:wid == GEAR_BASE[k][1] && ZcCall(GEAR_BASE[k][0], ZCOP_has, id)) return true;
if (ZcCall(ZC_MINIGUN, ZCOP_has, id) && wid == WEAPON_M249) return true;
return false;
}
VxRefillReserve531(weapon)
{
if (!get_pcvar_num(g_pInfAmmo531) || is_nullent(weapon)) return;
new id = get_member(weapon, m_pPlayer);
if (!(1 <= id <= g_iMax) || !is_user_alive(id) || g_bZombie[id] || VxIsSpecialWeapon531(id, weapon)) return;
new WeaponIdType:wid = get_member(weapon, m_iId);
new mx = rg_get_weapon_info(wid, WI_MAX_ROUNDS);
if (mx > 0 && rg_get_user_bpammo(id, wid) < mx) rg_set_user_bpammo(id, wid, mx);
}
public VxHamReloadPre531(weapon) { VxRefillReserve531(weapon); return HAM_IGNORED; }
public VxReloadPre531(const weapon, iClipSize, iAnim, Float:fDelay) { VxRefillReserve531(weapon); return HC_CONTINUE; }
public VxShotgunReloadPre531(const weapon, iAnim, iStartAnim, Float:fDelay, Float:fStartDelay) { VxRefillReserve531(weapon); return HC_CONTINUE; }
PickSkyRotation()
{
new list[256], pos, tmp[32];
copy(list, charsmax(list), GetResString("SKY_LIST", ""));
g_iSkyRotN531 = 0;
while (g_iSkyRotN531 < sizeof g_szSkyRot531 && (pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
{
if (!tmp[0] || !SkyExists(tmp)) { if (tmp[0]) log_amx("[Vexmira] gokyuzu dosyasi eksik: gfx/env/%s*.tga (atlandi)", tmp); continue; }
copy(g_szSkyRot531[g_iSkyRotN531++], charsmax(g_szSkyRot531[]), tmp);
}
if (!g_iSkyRotN531) return;
new per = clamp(str_to_num(GetResString("SKY_PER_MAP", "3")), 1, 8);
if (per < g_iSkyRotN531)
{
new info0[8]; get_localinfo("vex_skywin", info0, charsmax(info0));
new start = (str_to_num(info0) + per) % g_iSkyRotN531;
num_to_str(start, info0, charsmax(info0)); set_localinfo("vex_skywin", info0);
new tmp531[8][32];
for (new k = 0; k < per; k++) copy(tmp531[k], charsmax(tmp531[]), g_szSkyRot531[(start + k) % g_iSkyRotN531]);
for (new k = 0; k < per; k++) copy(g_szSkyRot531[k], charsmax(g_szSkyRot531[]), tmp531[k]);
g_iSkyRotN531 = per;
}
static const SIDE[][] = { "up", "dn", "lf", "rt", "ft", "bk" };
new path[96];
for (new k = 0; k < g_iSkyRotN531; k++)
for (new i = 0; i < 6; i++)
{
formatex(path, charsmax(path), "gfx/env/%s%s.tga", g_szSkyRot531[k], SIDE[i]);
PcGeneric(path);
}
new info[8]; get_localinfo("vex_skyrot", info, charsmax(info));
g_iSkyRotPos531 = (str_to_num(info) + 1) % g_iSkyRotN531;
num_to_str(g_iSkyRotPos531, info, charsmax(info)); set_localinfo("vex_skyrot", info);
copy(g_szSky, charsmax(g_szSky), g_szSkyRot531[g_iSkyRotPos531]);
set_cvar_string("sv_skyname", g_szSky);
log_amx("[Vexmira] gokyuzu rotasyonu: %d gokyuzu, bu harita %s ile basliyor", g_iSkyRotN531, g_szSky);
}
SkyNextRound531()
{
if (g_iSkyRotN531 < 2 || str_to_num(GetResString("SKY_MODE", "1")) != 3) return;
g_iSkyRotPos531 = (g_iSkyRotPos531 + 1) % g_iSkyRotN531;
copy(g_szSky, charsmax(g_szSky), g_szSkyRot531[g_iSkyRotPos531]);
set_cvar_string("sv_skyname", g_szSky);
}
PickSky()
{
new mode = str_to_num(GetResString("SKY_MODE", "1"));
if (mode <= 0)
return;
if (mode == 3) { PickSkyRotation(); return; }
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
static const SIDE[][] = { "up", "dn", "lf", "rt", "ft", "bk" };
new path[96];
for (new i = 0; i < 6; i++)
{
formatex(path, charsmax(path), "gfx/env/%s%s.tga", g_szSky, SIDE[i]);
PcGeneric(path);
}
}
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
PrecacheSoundKeyEx(key, IsKey2D(key));
}
new const SOUND_2D_KEYS[][] =
{
"ACH_UNLOCK", "AIRDROP_INCOMING", "AMBIENT", "BLACKOUT", "BOSS_DEATH", "BOSS_ENRAGE", "BOSS_INTRO", "BOSS_PHASE",
"BOSS_SOON", "BOSS_SPAWN", "BOSS_WARN", "COUNTDOWN_BEEP", "DAILY", "ECLIPSE", "EVENT_START", "FINAL_ROUND",
"HEADSHOT", "HEARTBEAT", "HUMAN_WIN", "KILL_DOUBLE", "KILL_TRIPLE", "KILL_MULTI", "KILL_MEGA", "KILL_MONSTER",
"LAST_HUMAN", "LEVEL_UP", "LIGHTNING", "LM_DENY", "MAP_END", "METEOR", "MODE_START", "MVP", "NADE_MODE",
"PLAYER_JOIN", "PLAYER_LEAVE", "QUEST_DONE", "ROUND_START", "SHOP_BUY", "SKILL_UNLOCK", "SPEED_START", "SPEED_WIND",
"STORM_STRIKE", "STREAK_5", "STREAK_10", "STREAK_15", "VIP_JOIN", "WELCOME", "ZOMBIE_WIN", "UI_OPEN",
"NEM_RAGE",
"CSO_KM", "CSO_KM_SP", "CSO_MVP", "CSO_BANNER", "CSO_WIN", "CSO_ALERT", "CSO_LEVEL",
"CSO_FB", "CSO_BKILL", "CSO_INFD", "CSO_TEN"
};
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
new path[256], full[160];
if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
return;
if (contain(path, "|") != -1)
{
new src[256], tmp[96], pos, keep[256], one[96];
copy(src, charsmax(src), path);
for (new i = 0; src[i]; i++) if (src[i] == '|') src[i] = ' ';
while ((pos = argparse(src, pos, tmp, charsmax(tmp))) != -1)
{
if (!tmp[0]) continue;
copy(one, charsmax(one), tmp);
new bool:ok;
if (containi(one, ".mp3") != -1) { PcGeneric(one); ok = true; }
else if (twoD) { formatex(full, charsmax(full), "sound/%s", one); if (file_exists(full, true)) { PcGeneric(full); TrieSetCell(g_tSnd2D, one, 1); ok = true; } }
else ok = PcSound(one) ? true : false;
if (ok) { if (keep[0]) add(keep, charsmax(keep), "|"); add(keep, charsmax(keep), one); }
}
TrieSetString(g_tRes, key, keep);
return;
}
if (containi(path, ".mp3") != -1)
{
PcGeneric(path);
return;
}
if (twoD)
{
formatex(full, charsmax(full), "sound/%s", path);
PcGeneric(full);
TrieSetCell(g_tSnd2D, path, 1);
ScanWav(path);
return;
}
if (!PcSound(path))
TrieSetString(g_tRes, key, "");
}
PcSound(const path[])
{
if(!AllowAudio528()) return 0;
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
new full[160]; formatex(full,charsmax(full),"sound/%s",path);
if(!file_exists(full,true)) { log_amx("[VexAsset] Sound skipped (missing): %s",full); return 0; }
if(max(g_iTotSnd,g_iPcSnd)>=448) {log_amx("[AssetGuard] sound reserve: %s",path);return 0;}
new idx = (!VxPcOk531()) ? 0 : precache_sound(path);
g_iMySnd++;
g_iPcSnd = max(g_iPcSnd, idx);
TrieSetCell(g_tSnd3D, path, idx);
if (!equal(low, path))
TrieSetCell(g_tSnd3D, low, idx);
ScanWav(path);
return 1;
}
PcGeneric(const path[])
{
if(!AllowGeneric528(path)) return;
if(g_tMdlDone==Invalid_Trie) {log_amx("[VexInit] PcGeneric before cache initialization: %s",path);return;}
if (!path[0] || TrieKeyExists(g_tMdlDone, path))
return;
if(!file_exists(path,true)) { log_amx("[VexAsset] Download skipped (missing): %s",path); return; }
TrieSetCell(g_tMdlDone, path, 1);
if(max(g_iTotGen,g_iPcGen)>=448) {log_amx("[AssetGuard] download reserve: %s",path);return;}
new idx = (!VxPcOk531()) ? 0 : precache_generic(path);
g_iMyGen++;
g_iPcGen = max(g_iPcGen, idx);
}
PcModel(const path[], bool:optional = true)
{
if(!AllowModel528(path)) return 0;
if(g_tMdlDone==Invalid_Trie) {log_amx("[VexInit] PcModel before cache initialization: %s",path);return 0;}
if (!path[0])
return 0;
// 5.3.9c: the engine keeps only 63 characters of a resource path; a longer one reaches the client cut short
// ("...not found" fatal error). Such a file is never sent (the old / default model is used).
if (strlen(path) > 62) { log_to_file("vexmira_modelguard.log", "ENGELLENDI %s -> yol 62 karakterden uzun (oyun keser, 'not found' cokmesi); klasor/dosya adini kisalt", path); return 0; }
new idx;
if (TrieGetCell(g_tMdlDone, path, idx))
return idx;
if (optional && g_iMyMdl >= g_iMdlBudget)
{
if (++g_iMdlSkipped <= 8)
log_amx("[Vexmira] Model butcesi dolu (MODEL_BUDGET %d), atlandi: %s", g_iMdlBudget, path);
return 0;
}
if(!StockModel50(path) && (!file_exists(path,true) || !CommunityLegacyFileOk(path))) { log_amx("[VexAsset] Model skipped (missing/incomplete): %s",path); return 0; }
if(max(g_iTotMdl,g_iPcMdl)>=448) {log_amx("[AssetGuard] model reserve: %s",path);return 0;}
idx = (!VxPcOk531()) ? 0 : precache_model(path);
RegisterTexture530(path);
g_iMyMdl++;
g_iPcMdl = max(g_iPcMdl, idx);
TrieSetCell(g_tMdlDone, path, idx);
return idx;
}
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
new g_iSndBlocked; // 5.3.8: unprecacher lives in vexmira_extra (vxe_unprecache_count)
public fw_PcSoundPost(const s[])
{
g_iTotSnd = max(g_iTotSnd, get_orig_retval());
return FMRES_IGNORED;
}
public fw_PcModelPost(const s[])
{
g_iTotMdl = max(g_iTotMdl, get_orig_retval());
if (get_orig_retval() > 0) VxPcRemember(s);
return FMRES_IGNORED;
}
public fw_PcGenericPost(const s[])
{
g_iTotGen = max(g_iTotGen, get_orig_retval());
return FMRES_IGNORED;
}
PrecacheReportTotals()
{
g_iSndBlocked = vxe_unprecache_count(0);
log_amx("[Vexmira] unprecacher: kullanilmayan stok ses %d + model %d engellendi", g_iSndBlocked, vxe_unprecache_count(1));
if (g_iFwPcSnd) { unregister_forward(FM_PrecacheSound, g_iFwPcSnd, 1); g_iFwPcSnd = 0; }
if (g_iFwPcMdl) { unregister_forward(FM_PrecacheModel, g_iFwPcMdl, 1); g_iFwPcMdl = 0; }
if (g_iFwPcGen) { unregister_forward(FM_PrecacheGeneric, g_iFwPcGen, 1); g_iFwPcGen = 0; }
g_iTotSnd = max(g_iTotSnd, g_iPcSnd);
g_iTotMdl = max(g_iTotMdl, g_iPcMdl);
g_iTotGen = max(g_iTotGen, g_iPcGen);
log_amx("[Vexmira] precache toplam (oyun + harita dahil): sound=%d/512 model=%d/512 generic=%d (motor havuzu; 512 sayacina dahil degil)", g_iTotSnd, g_iTotMdl, g_iTotGen);
if (g_iTotSnd > 480 || g_iTotMdl > 480)
log_amx("[Vexmira] UYARI: precache limitine yakin! vexmira.cfg: vex_res SOUND_BUDGET / MODEL_BUDGET / BOSS_PRELOAD dusur.");
}
public srv_PrecacheStats()
{
server_print("[ModelGuard] hook=%d kayitli model=%d v_ak47=%d p_fgrenade=%d", g_bPcHook531, g_tPcAll531 != Invalid_Trie ? TrieGetSize(g_tPcAll531) : -1, VxModelOk("models/v_ak47.mdl"), VxModelOk("models/p_fgrenade.mdl"));
new list[96], nm[16];
for (new i = 0; i < g_iBossLoadN; i++)
{
formatex(nm, charsmax(nm), "%s%s", i ? ", " : "", BOSS_FILE[g_iBossLoadList[i]]);
add(list, charsmax(list), nm);
}
server_print("[Vexmira] precache: sound=%d model=%d generic=%d (eklenti)", g_iPcSnd, g_iPcMdl, g_iPcGen);
server_print("[Vexmira] toplam (oyun + harita dahil): sound=%d/512 model=%d/512 generic=%d (motor havuzu)", g_iTotSnd, g_iTotMdl, g_iTotGen);
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
new need = maxN;
new info[16];
get_localinfo("vex_bossrot", info, charsmax(info));
new used = str_to_num(info) & ((1 << NUM_BOSSES) - 1);
new cand[NUM_BOSSES], nc;
for (new b = 0; b < NUM_BOSSES; b++)
{
if (!(used & (1 << b)))
cand[nc++] = b;
}
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
g_iBossBagPos = NUM_BOSSES;
}
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
new u539[48]; UniqModel539(name, u539, charsmax(u539));
if (!equal(u539, name)) formatex(model, charsmax(model), "models/player/%s/%s.mdl", u539, u539);
if (PcModel(model))
{
copy(out, len, u539);
MdlHeadTops(u539);
PcPlayerTex(u539);
}
}
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
g_iMineModelIndex = g_szMineModel[0] ? (VxModelOk(g_szMineModel) ? engfunc(EngFunc_ModelIndex, g_szMineModel) : 0) : 0;
if (!g_iMineModelIndex)
{
log_amx("[Vexmira] Laser model was not precached; planting is safely disabled: %s", g_szMineModel);
g_szMineModel[0] = 0;
}
GetFileModel("LASERMINE_MODEL_HUMAN", g_szMineHumanModel, charsmax(g_szMineHumanModel));
if (!g_szMineHumanModel[0] && file_exists("models/v_tripmine.mdl", true))
{
    copy(g_szMineHumanModel, charsmax(g_szMineHumanModel), "models/v_tripmine.mdl");
    PcModel(g_szMineHumanModel, false);
}
if (!g_szMineHumanModel[0])
    copy(g_szMineHumanModel, charsmax(g_szMineHumanModel), g_szMineModel);
GetFileModel("LASERMINE_MODEL_ZOMBIE", g_szMineZombieModel, charsmax(g_szMineZombieModel));
if (!g_szMineZombieModel[0])
    copy(g_szMineZombieModel, charsmax(g_szMineZombieModel), g_szMineModel);
g_iMineHumanModelIndex = g_szMineHumanModel[0] ? (VxModelOk(g_szMineHumanModel) ? engfunc(EngFunc_ModelIndex, g_szMineHumanModel) : 0) : 0;
g_iMineZombieModelIndex = g_szMineZombieModel[0] ? (VxModelOk(g_szMineZombieModel) ? engfunc(EngFunc_ModelIndex, g_szMineZombieModel) : 0) : 0;
if (!g_iMineHumanModelIndex)
{
    log_amx("[Vexmira] Human laser model unavailable; using shared model: %s", g_szMineModel);
    copy(g_szMineHumanModel, charsmax(g_szMineHumanModel), g_szMineModel);
    g_iMineHumanModelIndex = g_iMineModelIndex;
}
if (!g_iMineZombieModelIndex)
{
    log_amx("[Vexmira] Zombie laser model unavailable; using shared model: %s", g_szMineModel);
    copy(g_szMineZombieModel, charsmax(g_szMineZombieModel), g_szMineModel);
    g_iMineZombieModelIndex = g_iMineModelIndex;
}
new bool:tripmine = (containi(g_szMineModel, "tripmine") != -1) ? true : false;
new bool:c4 = (containi(g_szMineModel, "w_c4") != -1) ? true : false;
new bool:fellBack = !equal(cfgModel, g_szMineModel);
new seq[24];
g_iMineBody = (fellBack || tripmine) ? (tripmine ? 3 : 0) : str_to_num(GetResString("LASERMINE_BODY", "0"));
copy(seq, charsmax(seq), tripmine ? "world" : (fellBack ? "0" : GetResString("LASERMINE_SEQUENCE", "idle")));
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
if (ident != 0x50534449)
return;
g_iOvhFrames[slot] = clamp(frames, 1, 256);
g_iOvhWidth[slot] = clamp(w, 1, 1024);
g_iOvhHeight[slot] = clamp(h, 1, 1024);
switch (fmt)
{
case 1: g_iOvhMode[slot] = kRenderTransAdd;
case 2: g_iOvhMode[slot] = kRenderTransTexture;
case 3: g_iOvhMode[slot] = kRenderTransAlpha;
default: g_iOvhMode[slot] = kRenderNormal;
}
}
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
fread(fp, tmp, BLOCK_INT);
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
if (g_tRes == Invalid_Trie || !TrieGetString(g_tRes, key, out, charsmax(out)) || !out[0])
copy(out, charsmax(out), def);
return out;
}
new Float:g_fBossScale531 = 1.0;
#define GM_OK(%1) (%1)
GiantRemove532()
{
if (g_iGiantEnt532 && pev_valid(g_iGiantEnt532)) engfunc(EngFunc_RemoveEntity, g_iGiantEnt532);
g_iGiantEnt532 = 0; g_iGiantSeq532 = -1;
}
public GiantFrame532()
{
if (g_iGiantMode532 != 1 || g_fBossScale531 <= 1.01) { if (g_iGiantEnt532) GiantRemove532(); return; }
new id = g_iBoss;
new bool:have = g_iGiantEnt532 && pev_valid(g_iGiantEnt532);
if (!(g_iMode == MODE_BOSS && id >= 1 && id <= g_iMax && is_user_connected(id) && g_iBossType >= 0 && g_iBossType < NUM_BOSSES && g_szBModel[g_iBossType][0]
&& ((is_user_alive(id) && g_bBoss[id]) || have)))
{
if (g_iGiantEnt532) GiantRemove532();
return;
}
new ent = g_iGiantEnt532;
if (!is_user_alive(id))
{
new dseq = get_entvar(id, var_sequence);
if (dseq != g_iGiantSeq532) { g_iGiantSeq532 = dseq; set_entvar(ent, var_sequence, dseq); set_entvar(ent, var_frame, 0.0); set_entvar(ent, var_animtime, get_gametime()); set_entvar(ent, var_framerate, 1.0); }
return;
}
if (!ent || !pev_valid(ent))
{
new mdl[128]; formatex(mdl, charsmax(mdl), "models/player/%s/%s.mdl", g_szBModel[g_iBossType], g_szBModel[g_iBossType]);
if (!VxModelOk(mdl)) return;
ent = CreateSafe51("info_target");
if (is_nullent(ent)) return;
set_entvar(ent, var_classname, "vex_giantbody");
VxSM(ent, mdl);
set_entvar(ent, var_movetype, MOVETYPE_NOCLIP);
set_entvar(ent, var_solid, SOLID_NOT);
set_entvar(ent, var_scale, g_fBossScale531);
set_entvar(ent, var_owner, id);
engfunc(EngFunc_SetSize, ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
g_iGiantEnt532 = ent; g_iGiantSeq532 = -1;
log_amx("[GiantBoss] dev govde: ent %d, boss #%d, model %s, olcek %.2f (yeni dosya yok)", ent, id, mdl, g_fBossScale531);
}
new Float:o[3], Float:a[3], Float:v[3];
get_entvar(id, var_origin, o); get_entvar(id, var_v_angle, a); get_entvar(id, var_velocity, v);
o[2] += ((get_entvar(id, var_flags) & FL_DUCKING) ? 18.0 : 36.0) * (g_fBossScale531 - 1.0);
engfunc(EngFunc_SetOrigin, ent, o);
a[0] = 0.0; a[2] = 0.0; set_entvar(ent, var_angles, a);
new seq = get_entvar(id, var_sequence), gait = get_entvar(id, var_gaitsequence);
if (floatsqroot(v[0] * v[0] + v[1] * v[1]) > 30.0 && gait > 0 && (Float:get_entvar(id, var_animtime) < get_gametime() - 0.6)) seq = gait;
if (seq != g_iGiantSeq532)
{
g_iGiantSeq532 = seq;
set_entvar(ent, var_sequence, seq); set_entvar(ent, var_frame, 0.0);
set_entvar(ent, var_animtime, get_gametime()); set_entvar(ent, var_framerate, 1.0);
}
set_entvar(ent, var_renderfx, get_entvar(id, var_renderfx));
new Float:c[3]; get_entvar(id, var_rendercolor, c); set_entvar(ent, var_rendercolor, c);
set_entvar(ent, var_rendermode, get_entvar(id, var_rendermode));
set_entvar(ent, var_renderamt, Float:get_entvar(id, var_renderamt));
set_entvar(ent, var_skin, get_entvar(id, var_skin)); set_entvar(ent, var_body, get_entvar(id, var_body));
}
GiantPack532(es, ent, host)
{
if (!g_iGiantEnt532) return FMRES_IGNORED;
if (ent == g_iBoss && ent >= 1 && ent <= g_iMax)
{
set_es(es, ES_RenderMode, kRenderTransAlpha); set_es(es, ES_RenderAmt, 0); set_es(es, ES_RenderFx, kRenderFxNone);
return FMRES_IGNORED;
}
if (ent == g_iGiantEnt532 && host == g_iBoss && !(g_iCamera47[host] && !is_nullent(g_iCamera47[host])))
set_es(es, ES_Effects, get_es(es, ES_Effects) | EF_NODRAW);
return FMRES_IGNORED;
}
// 5.3.9c UNIQUE PLAYER MODELS: common names (nemesis, zombie_source, cso_heavy ...) exist with other content
// on other ZP servers; a client that cached such a copy never downloads ours and crashes ("...T.mdl not found").
// Every custom player model is copied once to "<name>_u<size>" (+ its T / 01.. files) and that copy is used,
// so every client downloads exactly our file. vex_res MODEL_UNIQUE "0" turns it off.
stock bool:CopyFile539(const src[], const dst[])
{
new in = fopen(src, "rb", true);
if (!in) return false;
new o = fopen(dst, "wb");
if (!o) { fclose(in); return false; }
new buf[1024], n;
while ((n = fread_blocks(in, buf, sizeof buf, BLOCK_CHAR)) > 0) fwrite_blocks(o, buf, n, BLOCK_CHAR);
fclose(in); fclose(o);
return true;
}
stock UniqModel539(const name[], out[], len)
{
copy(out, len, name);
if (!name[0] || equal(GetResString("MODEL_UNIQUE", "1"), "0")) return;
static const ST[][] = { "gign", "sas", "gsg9", "urban", "terror", "leet", "arctic", "guerilla", "vip", "spetsnaz", "militia", "player" };
for (new i = 0; i < sizeof ST; i++) if (equali(name, ST[i])) return;
new l = strlen(name);
if (l > 2 && containi(name, "_u") != -1 && isdigit(name[l - 1])) return;
new src[128], base[160], dst[160], nn[48], sz;
formatex(src, charsmax(src), "models/player/%s/%s.mdl", name, name);
sz = file_size(src, FSOPT_BYTES_COUNT, true);
if (sz <= 0) return;
// 5.3.9d: models that come with their own T / 01.. files are used as they are (never copied)
formatex(base, charsmax(base), "models/player/%s/%sT.mdl", name, name);
if (file_exists(base, true)) return;
formatex(base, charsmax(base), "models/player/%s/%s01.mdl", name, name);
if (file_exists(base, true)) return;
formatex(nn, charsmax(nn), "%.14s_u%d", name, sz % 10000); // max 20 chars: the engine cuts paths over 63 chars ("not found")
if (strlen(nn) >= len) return;
formatex(dst, charsmax(dst), "models/player/%s/%s.mdl", nn, nn);
if (!file_exists(dst, true) || file_size(dst, FSOPT_BYTES_COUNT, true) != sz)
{
formatex(base, charsmax(base), "models/player/%s", nn);
if (!dir_exists(base)) mkdir(base);
if (!CopyFile539(src, dst)) { log_amx("[Vexmira] model kopyalanamadi (klasor izni?): %s - orijinal ad kullaniliyor", dst); return; }
log_amx("[Vexmira] oyuncu modeli benzersiz kopya: %s -> %s (baska sunucudan kalma ayni isimli dosya ile cakisma olmaz)", name, nn);
}
copy(out, len, nn);
}
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
{ new u539[48]; UniqModel539(out, u539, charsmax(u539)); if (!equal(u539, out) && strlen(u539) < len) { copy(out, len, u539); formatex(model, charsmax(model), "models/player/%s/%s.mdl", out, out); } }
if (!PcModel(model))
out[0] = 0;
else
{
MdlHeadTops(out);
PcPlayerTex(out);
}
}
PcPlayerTex(const name[])
{
new tex[128];
formatex(tex, charsmax(tex), "models/player/%s/%sT.mdl", name, name);
if (g_iFwPcMdl && file_exists(tex, true))
ZcPcGeneric(tex);
}
GetFileModel(const key[], out[], len)
{
out[0] = 0;
if (!TrieGetString(g_tRes, key, out, len) || !out[0])
return;
if (!StockModel50(out) && !file_exists(out, true))
{
log_amx("[Vexmira] Model bulunamadi: %s (%s) - devre disi", out, key);
out[0] = 0;
return;
}
if (!PcModel(out))
out[0] = 0;
}
new Trie:g_tResMiss533;
ResMiss533(const key[], const path[])
{
if (g_tResMiss533 == Invalid_Trie) g_tResMiss533 = TrieCreate();
TrieSetString(g_tResMiss533, key, path);
}
#define FDL_MAX 900
new g_szFdl534[FDL_MAX][96], g_iFdlSz534[FDL_MAX], g_iFdlN534;
stock FdlAdd534(const path[])
{
if (g_iFdlN534 >= FDL_MAX || !path[0]) return;
for (new i = 0; i < g_iFdlN534; i++) if (equali(g_szFdl534[i], path)) return;
new sz = file_size(path, 0);
if (sz <= 0) return;
copy(g_szFdl534[g_iFdlN534], charsmax(g_szFdl534[]), path);
g_iFdlSz534[g_iFdlN534++] = sz;
}
stock FdlTrie534(Trie:t, bool:snd)
{
if (t == Invalid_Trie) return;
new TrieIter:it = TrieIterCreate(t), k[96], full[110];
while (!TrieIterEnded(it))
{
TrieIterGetKey(it, k, charsmax(k));
if (snd && !equali(k, "sound/", 6)) { formatex(full, charsmax(full), "sound/%s", k); FdlAdd534(full); }
else FdlAdd534(k);
TrieIterNext(it);
}
TrieIterDestroy(it);
}
FdlCollect534()
{
g_iFdlN534 = 0;
new map[48], path[96], line[128];
get_mapname(map, charsmax(map));
formatex(path, charsmax(path), "maps/%s.bsp", map); FdlAdd534(path);
formatex(path, charsmax(path), "maps/%s.res", map);
new fp = fopen(path, "rt");
if (fp)
{
while (!feof(fp))
{
fgets(fp, line, charsmax(line)); trim(line);
if (line[0] && !(line[0] == '/' && line[1] == '/')) FdlAdd534(line);
}
fclose(fp);
}
FdlTrie534(g_tMdlDone, false);
FdlTrie534(g_tSnd2D, true);
FdlTrie534(g_tSnd3D, true);
for (new i = 1; i < g_iFdlN534; i++)
for (new j = i; j > 0 && g_iFdlSz534[j - 1] < g_iFdlSz534[j]; j--)
{
new t = g_iFdlSz534[j]; g_iFdlSz534[j] = g_iFdlSz534[j - 1]; g_iFdlSz534[j - 1] = t;
new tmp[96]; copy(tmp, charsmax(tmp), g_szFdl534[j]); copy(g_szFdl534[j], charsmax(g_szFdl534[]), g_szFdl534[j - 1]); copy(g_szFdl534[j - 1], charsmax(g_szFdl534[]), tmp);
}
new total;
for (new i = 0; i < g_iFdlN534; i++) total += g_iFdlSz534[i];
return total;
}
public cmd_FastDl534(id)
{
if (id && !(get_user_flags(id) & ADMIN_BAN)) return PLUGIN_HANDLED;
new total = FdlCollect534(), dir[96], out[128], url[128];
get_datadir(dir, charsmax(dir));
formatex(out, charsmax(out), "%s/vexmira_fastdl.txt", dir);
get_cvar_string("sv_downloadurl", url, charsmax(url));
FdlWrite534(total);
console_print(id, "[Vexmira] %d dosya, toplam %.1f MB -> %s", g_iFdlN534, float(total) / 1048576.0, out);
console_print(id, "[Vexmira] FastDL: %s", url[0] ? url : "YOK (sv_downloadurl bos) - oyuncular bu dosyalari oyunun yavas indirmesiyle ceker!");
for (new i = 0; i < min(12, g_iFdlN534); i++) console_print(id, "   %5d KB  %s", g_iFdlSz534[i] / 1024, g_szFdl534[i]);
return PLUGIN_HANDLED;
}
FdlWrite534(total)
{
new dir[96], out[128], all[128], map[48], l[140];
get_datadir(dir, charsmax(dir));
get_mapname(map, charsmax(map));
formatex(out, charsmax(out), "%s/vexmira_fastdl.txt", dir);
formatex(all, charsmax(all), "%s/vexmira_fastdl_hepsi.txt", dir);
// 5.3.8: one open per file instead of write_file() per line (was a ~1.2 s hitch 10 s after map start)
new fo = fopen(out, "wt");
if (fo)
{
fprintf(fo, "// Vexmira - %s: oyuncunun indirdigi %d ozel dosya, %.1f MB (buyukten kucuge). FastDL klasorune AYNI yollarla kopyala.^n", map, g_iFdlN534, float(total) / 1048576.0);
for (new i = 0; i < g_iFdlN534; i++) fprintf(fo, "%s   // %d KB^n", g_szFdl534[i], g_iFdlSz534[i] / 1024);
fclose(fo);
}
#pragma unused l
new Trie:seen = TrieCreate(), line[140];
new fp = fopen(all, "rt");
if (fp)
{
while (!feof(fp)) { fgets(fp, line, charsmax(line)); trim(line); if (line[0] && line[0] != '/') TrieSetCell(seen, line, 1); }
fclose(fp);
}
new added, fa = fopen(all, "at");
if (fa && !fp) fprintf(fa, "// Vexmira - oynanan BUTUN haritalarin indirme dosyalari (her harita acilisinda eklenir). Hepsini FastDL'e AYNI yollarla koy.^n");
for (new i = 0; i < g_iFdlN534; i++)
if (!TrieKeyExists(seen, g_szFdl534[i])) { if (fa) fprintf(fa, "%s^n", g_szFdl534[i]); TrieSetCell(seen, g_szFdl534[i], 1); added++; }
if (fa) fclose(fa);
TrieDestroy(seen);
return added;
}
public task_FastDlWarn534()
{
new url[128]; get_cvar_string("sv_downloadurl", url, charsmax(url));
new total = FdlCollect534();
new added = FdlWrite534(total);
if (added) log_amx("[Vexmira] FastDL listesi: %d yeni dosya data/vexmira_fastdl_hepsi.txt dosyasina eklendi", added);
if (!url[0])
log_amx("[Vexmira] UYARI: FastDL (sv_downloadurl) yok. Bu haritada %d ozel dosya / %.1f MB oyuncuya YAVAS indirilir. Liste: konsola vex_fastdl", g_iFdlN534, float(total) / 1048576.0);
else
log_amx("[Vexmira] FastDL: %s | bu haritada %d ozel dosya / %.1f MB (eksiksiz yuklu olmali; liste: vex_fastdl)", url, g_iFdlN534, float(total) / 1048576.0);
}
public cmd_Kontrol533(id)
{
if (id && !(get_user_flags(id) & ADMIN_BAN)) return PLUGIN_HANDLED;
console_print(id, "===== VEXMIRA AYAR KONTROLU =====");
new n;
if (g_tResMiss533 != Invalid_Trie)
{
new Snapshot:it = TrieSnapshotCreate(g_tResMiss533), key[48], path[192];
for (new i = 0; i < TrieSnapshotLength(it); i++)
{
TrieSnapshotGetKey(it, i, key, charsmax(key)); TrieGetString(g_tResMiss533, key, path, charsmax(path));
console_print(id, "  EKSIK DOSYA: vex_res %s -> %s (varsayilan kullaniliyor)", key, path); n++;
}
TrieSnapshotDestroy(it);
}
console_print(id, "  %d eksik dosya. Ses yolu ornegi: vex_res AMBIENT_MODE2 ^"sound/klasor/dosya.wav^" (wav: mono, 8/16 bit, 11-22 kHz; muzik icin .mp3 de olur)", n);
console_print(id, "  Kartlar: %s | dev boss: %s | ses %d/512, indirme ~%d, model %d/512", CsoOn() ? "acik" : "KAPALI", g_iGiantMode532 == 2 ? "dosya" : (g_iGiantMode532 == 1 ? "clone" : "kapali"), g_iTotSnd, g_iTotGen, g_iTotMdl);
return PLUGIN_HANDLED;
}
ResSet(const key[], const value[])
{
if(!key[0]) return;
if(equali(key,"VOX_COUNTDOWN")) {g_bVoxCountdown=(str_to_num(value)!=0);g_iEpicCountdown=clamp(str_to_num(value),0,2);return;}
new normalized[256];copy(normalized,charsmax(normalized),value);
if(contain(value,"|")!=-1 && containi(value,".wav")!=-1) {
new src[256],tmp[128],pos,keep[256],full2[160];copy(src,charsmax(src),value);
for(new i=0;src[i];i++) if(src[i]=='|') src[i]=' ';
while((pos=argparse(src,pos,tmp,charsmax(tmp)))!=-1) {
if(!tmp[0]||contain(tmp,"..")!=-1||tmp[0]=='/') continue;
if(equali(tmp,"sound/",6)) {new t2[128];copy(t2,charsmax(t2),tmp[6]);copy(tmp,charsmax(tmp),t2);}
formatex(full2,charsmax(full2),"sound/%s",tmp);
if(!file_exists(full2,true)) {log_amx("[Vexmira] Ses havuzu: %s yok (%s) - atlandi",full2,key);continue;}
if(keep[0]) add(keep,charsmax(keep),"|"); add(keep,charsmax(keep),tmp);
}
if(keep[0]) TrieSetString(g_tRes,key,keep);
return;
}
if(value[0] && (containi(value,".wav")!=-1 || containi(value,".mp3")!=-1)) {
while(equali(normalized,"sound/",6)) {new tmp[192];copy(tmp,charsmax(tmp),normalized[6]);copy(normalized,charsmax(normalized),tmp);}
if(contain(normalized,"..")!=-1 || normalized[0]=='/') {log_amx("[Vexmira] Gecersiz ses yolu: %s",key);return;}
new full[192];formatex(full,charsmax(full),"sound/%s",normalized);
if(!file_exists(full,true)) {log_amx("[Vexmira] Ses bulunamadi: %s (%s) - varsayilan kullanilacak",full,key);ResMiss533(key,full);return;}
if(containi(value,".mp3")!=-1 || equal(key,"AMBIENT_",8)) copy(normalized,charsmax(normalized),full);
}
TrieSetString(g_tRes,key,normalized);
}
CfgPath(out[], len)
{
get_configsdir(out, len);
add(out, len, "/vexmira.cfg");
}
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
LoadMainConfig(bool:precache)
{
new file[128]; CfgPath(file,charsmax(file));
new bool:single=false;
new fp531=fopen(file,"rt");
if(fp531) {new first[160];fgets(fp531,first,charsmax(first));fclose(fp531);single=(containi(first,"TEK AYAR DOSYASI")!=-1);}
new n=LoadConfigFile(file,precache);
new epic[128];get_configsdir(epic,charsmax(epic)); add(epic,charsmax(epic),"/vexmira_epic.cfg");
if(single)
{
if(file_exists(epic)) {new old[140];formatex(old,charsmax(old),"%s.old",epic);delete_file(old);rename_file(epic,old,1);log_amx("[Vexmira] tek config: vexmira_epic.cfg -> vexmira_epic.cfg.old (artik kullanilmiyor)");}
}
else n+=LoadConfigFile(epic,precache);
if(!precache) ApplyConfigNow();
return n;
}
LoadConfigFile(const file[], bool:precache)
{
new fp = fopen(file, "rt");
if (!fp)
{
if (!precache)
log_amx("[Vexmira] %s bulunamadi, varsayilan ayarlar kullaniliyor.", file);
return 0;
}
new line[768], args[CFG_MAXARGS][256], argc, pos, count, value[256];
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
if (equali(args[0], "vex_restore"))
{
if (precache && argc >= 3) CommunityRestoreResource(args[1],args[2]);
continue;
}
if (equali(args[0], "vex_res"))
{
if (precache && argc >= 2)
ResSet(args[1], argc >= 3 ? args[2] : "");
continue;
}
if (precache)
{
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
server_cmd("%s", line);
count++;
}
fclose(fp);
return count;
}
ApplyConfigNow()
{
new raw[64];
get_pcvar_string(g_pPrefix, raw, charsmax(raw));
if (raw[0])
ColorEscape(raw, g_szPrefix, charsmax(g_szPrefix));
get_pcvar_string(g_pPrefixBoss, raw, charsmax(raw));
ColorEscape(raw, g_szPrefixBoss, charsmax(g_szPrefixBoss));
get_pcvar_string(g_pPrefixEvent, raw, charsmax(raw));
ColorEscape(raw, g_szPrefixEvent, charsmax(g_szPrefixEvent));
get_pcvar_string(g_pPrefixVip, raw, charsmax(raw));
ColorEscape(raw, g_szPrefixVip, charsmax(g_szPrefixVip));
get_pcvar_string(g_pPrefixAdmin, raw, charsmax(raw));
ColorEscape(raw, g_szPrefixAdmin, charsmax(g_szPrefixAdmin));
ApplyHostname();
if (g_iMapExtendTo > get_cvar_num("mp_maxrounds"))
set_cvar_num("mp_maxrounds", g_iMapExtendTo);
MsApplyRoundTime();
}
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
bool:ApplyTableCmd(const args[][], argc)
{
new i;
if (equali(args[0], "vex_wing") || equali(args[0], "vex_pet") || equali(args[0], "vex_hat"))
return true;
if (equali(args[0], "vex_item"))
{
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
if ((i = TblIdx(args, argc, 6, NUM_SPECIAL)) >= 0)
{
SW_COST[i]   = max(0, str_to_num(args[2]));
SW_LVL[i]    = clamp(str_to_num(args[3]), 1, MAX_LEVEL);
SW_MULT[i]   = floatclamp(str_to_float(args[4]), 0.1, 10.0);
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
if ((i = TblIdx(args, argc, 3, NUM_JOBS)) >= 0)
JOB_LVL[i] = clamp(str_to_num(args[2]), 1, MAX_LEVEL);
return true;
}
if (equali(args[0], "vex_boss_stat"))
{
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
if ((i = TblIdx(args, argc, 4, MODE_TOTAL)) >= 0)
{
MODE_CHANCE[i] = max(0, str_to_num(args[2]));
MODE_MINPL[i]  = clamp(str_to_num(args[3]), 1, 32);
}
return true;
}
if (equali(args[0], "vex_env_event") || equali(args[0], "vex_env_mode") || equali(args[0], "vex_env_boss") || equali(args[0], "vex_env_calm"))
{
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
public srv_ResCmd()
{
server_print("[Vexmira] vex_res ayarlari harita degisince yuklenir (ses / model precache).");
return PLUGIN_HANDLED;
}
public cmd_reload_cfg(id, level, cid)
{
if (!cmd_access(id, level, cid, 1))
return PLUGIN_HANDLED;
log_to_file("vexmira_startup.log","[530 core] config reload BEGIN");
new n = LoadMainConfig(false);
log_to_file("vexmira_startup.log","[530 core] config reload READY");
console_print(id, "[Vexmira] vexmira.cfg yeniden yuklendi (%d satir). Ses/model degisiklikleri harita degisince gecerli.", n);
if (id)
AdminNotify(id, "ADM_RELOADED", n);
return PLUGIN_HANDLED;
}
public task_LoadConfig()
{
LoadMainConfig(false);
}
ApplyHostname()
{
new base[100];
get_pcvar_string(g_pHostname, base, charsmax(base));
trim(base);
if (!base[0])
return;
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
new f[48], arg[16], pos, n;
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
for (new c = 0; c < 2; c++) {
g_iCommunityOwned[id][c] = (n > 35 + c * 2) ? (f[35 + c * 2] & (c ? 255 : 31)) : 0;
g_iCommunitySel[id][c] = (n > 36 + c * 2) ? clamp(f[36 + c * 2], 0, c ? 8 : 5) : 0;
new v = g_iCommunitySel[id][c];
if (v && !(g_iCommunityOwned[id][c] & (1 << (v - 1)))) g_iCommunitySel[id][c] = 0;
}
g_iLzOwned531[id] = (n > 39) ? (f[39] & 15) : 0;
g_iLzSel531[id] = (n > 40) ? clamp(f[40], 0, 4) : 0;
if (g_iLzSel531[id] && !(g_iLzOwned531[id] & (1 << (g_iLzSel531[id] - 1)))) g_iLzSel531[id] = 0;
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
formatex(val, charsmax(val), "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
g_iXP[id], g_iAP[id], g_iVC[id], g_iKills[id], g_iInfects[id], g_iWins[id], g_iBossK[id], g_iHS[id],
g_iAch[id], g_iTitle[id], g_iJobNext[id] >= 0 ? g_iJobNext[id] : g_iJob[id], g_iStyle[id], g_iSet[id], g_iTheme[id], g_iLang[id],
g_iDailyDay[id], g_iDailyStreak[id], g_iPrim[id], g_iSec[id], g_iPlaySec[id] / 60,
g_iPerk[id][0], g_iPerk[id][1], g_iPerk[id][2], g_iPerk[id][3], g_iPerk[id][4], g_iPerk[id][5],
g_iClassNext[id] >= 0 ? g_iClassNext[id] : g_iClass[id], get_systime(), g_iHudPos[id],
g_iCosOwned[id], g_iTrailSel[id], g_iKfxSel[id], g_iIfxSel[id], g_iCmOwned[id], g_iCmSelPk[id], g_iCommunityOwned[id][0], g_iCommunitySel[id][0], g_iCommunityOwned[id][1], g_iCommunitySel[id][1], g_iLzOwned531[id], g_iLzSel531[id]);
nvault_set(g_hVault, key, val);
UpdateTop(id, key);
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
CsoNotify(id, CN_LEVEL, g_iLevel[id]);
Chat(id, "LEVELUP_VC", vc);
for (new p = 1; p <= g_iMax && get_pcvar_num(g_pChatBcast); p++)
{
if (is_user_connected(p) && p != id)
client_print_color(p, id, "%s %L", ChatTag("LEVELUP_CHAT"), p, "LEVELUP_CHAT", name, g_iLevel[id]);
}
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
for (new t = 1; t < NUM_TITLES; t++)
{
if (TITLE_ACH[t] == bit)
ChatKeyName(id, "UNLOCK_TITLE", "TITLE_", t);
}
SaveData(id);
}
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
len += formatex(html[len], charsmax(html) - len, "<h2>%s</h2><div class=t>Lv.%d â€¢ %s", name, lvl, tname);
if (g_iTopRank[target] > 0)
len += formatex(html[len], charsmax(html) - len, " â€¢ TOP #%d", g_iTopRank[target]);
if (IsElite(target))
len += formatex(html[len], charsmax(html) - len, " â€¢ ELITE");
else if (IsVip(target))
len += formatex(html[len], charsmax(html) - len, " â€¢ VIP");
len += formatex(html[len], charsmax(html) - len, "</div><div class=bar><div class=fl style=^"width:%d%%^"></div></div>XP %d / %d (%d%%)<table>", pct, g_iXP[target], need, pct);
len += formatex(html[len], charsmax(html) - len, "<tr><td>AP <b>%d</b><td>VC <b>%d</b><td>%L <b>%s</b>", g_iAP[target], g_iVC[target], id, "CARD_JOB", jn);
len += formatex(html[len], charsmax(html) - len, "<tr><td>%L <b>%d</b><td>%L <b>%d</b><td>HS <b>%d</b>", id, "CARD_KILLS", g_iKills[target], id, "CARD_INF", g_iInfects[target], g_iHS[target]);
len += formatex(html[len], charsmax(html) - len, "<tr><td>%L <b>%d</b><td>%L <b>%d</b><td>%L <b>%d/%d</b>", id, "CARD_WINS", g_iWins[target], id, "CARD_BOSS", g_iBossK[target], id, "CARD_ACH", ach, NUM_ACH);
len += formatex(html[len], charsmax(html) - len, "<tr><td>%L <b>%d:%02d</b><td>%L <b>%d</b><td>%L <b>%d</b>", id, "CARD_TIME", g_iPlaySec[target] / 3600, (g_iPlaySec[target] % 3600) / 60, id, "CARD_DAILY", g_iDailyStreak[target], id, "CARD_MAPKILLS", g_iMapKills[target]);
formatex(html[len], charsmax(html) - len, "</table></body></html>");
show_motd(id, html, "VEXMIRA | PROFILE");
}
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
SyncMoney(id)
{
if (!is_user_connected(id) || is_user_hltv(id))
return;
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
if (xp > 0 && HudPartMode(g_pHudXp) == 2 && !g_iPlantAction[id] && !CsoOn())
{
new lvl = g_iLevel[id];
new pct = (lvl >= MAX_LEVEL) ? 100 : clamp((g_iXP[id] - XPForLevel(lvl)) * 100 / max(1, XPForLevel(lvl + 1) - XPForLevel(lvl)), 0, 100);
rg_send_bartime2(id, 2, float(pct), false);
}
if (ap > 0)
AddAP(id, ap, true, false);
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
ShowShopMenu(id)
{
new title[320], item[160], k1[12], k2[16], n1[40], n2[64];
new isZ = g_bZombie[id] ? 1 : 0;
if (isZ) VexHead(id, title, charsmax(title), "MENU_SHOP_Z"); else VexHead(id, title, charsmax(title), "MENU_SHOP_H");
new menu = VexMenuCreate(title, "menu_shop_handler");
if (!isZ) {
formatex(item,charsmax(item),"%L",id,"ZC_SPECIAL"); MenuAdd(menu,item,202);
formatex(item,charsmax(item),"%L [80 AP]",id,"ZC_JETPACK"); MenuAdd(menu,item,200);
}
for (new k = 0, nk = vxe_item_count(); k < nk; k++)
{
new c538 = vxe_item_info(k, isZ, n1, charsmax(n1));
if (c538 < 0) continue;
formatex(item, charsmax(item), "\y%s \r[%d AP]", n1, c538); MenuAdd(menu, item, 300 + k);
}
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
formatex(item, charsmax(item), "%L", id, "MENU_BACK"); MenuAdd(menu,item,999);
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
if (sel == 999) { ShowMainMenu(id); return PLUGIN_HANDLED; }
if (sel == 202) { CommunityWeaponMenu(id); return PLUGIN_HANDLED; }
if (sel == 210 || sel == 211) { CommunityCoinMenu(id, sel - 210); return PLUGIN_HANDLED; }
if (sel >= 300 && sel < 340)
BuyItem538(id, sel - 300);
else if (sel == 200 || sel == 201)
CommunityBuyGear(id, sel - 200);
else if (sel == 100)
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
case IT_ZJUMP:   SetGravity(id, (g_fGrav[id] > 0.0 ? g_fGrav[id] : Float:get_entvar(id, var_gravity)) * float(clamp(val, 10, 100)) / 100.0);
case IT_ZREGEN:  g_bZRegen[id] = 1;
case IT_ZNOKB:   g_bNoKB[id] = 1;
}
g_iBought[id][i]++;
AddAP(id, -cost, false, false);
PlayKey(id, "SHOP_BUY");
VxItemFx531(id, i);
new key[12], nm[40];
formatex(key, charsmax(key), "ITEM_%d", i);
formatex(nm, charsmax(nm), "%L", id, key);
Chat(id, "SHOP_BOUGHT", nm, cost);
if (ITEM_ANNOUNCE[i])
AnnounceBuy(id, key);
}
static const ITEM_RGB531[][3] = {
{60,255,120},{80,160,255},{255,120,30},{90,200,255},{255,240,140},{200,120,255},
{160,255,255},{255,80,160},{255,200,40},{255,60,40},{255,255,255},
{120,255,200},{255,40,200},{80,255,40},{170,40,255},{255,30,30},{40,200,255},{150,150,170},
{255,230,60},{120,120,255},{60,255,60},{0,255,255},{255,170,60},
{255,90,0},{100,60,160},{120,255,120},{40,255,90},{140,90,60}
};
VxItemFx531(id, i)
{
if (!is_user_alive(id)) return;
new r = 255, g = 255, b = 255;
if (0 <= i < sizeof ITEM_RGB531) { r = ITEM_RGB531[i][0]; g = ITEM_RGB531[i][1]; b = ITEM_RGB531[i][2]; }
VxItemFxRGB531(id, r, g, b);
new Float:o[3];
get_entvar(id, var_origin, o);
if (i == IT_MEDKIT) FxHeal(id);
ItemFx533(id, i, o);
}
enum { IF_POWER = 0, IF_HEAL, IF_ARMOR, IF_MADNESS, IF_RAGE, IF_CLOAK, IF_JUMP, IF_SPEED, IF_SHIELD, IF_REGEN, IF_AMMO, IF_ANTIDOTE, IF_SERUM, IF_TOTAL };
new const IF_NAME533[IF_TOTAL][] = { "power", "heal", "armor", "madness", "rage", "cloak", "jump", "speed", "shield", "regen", "ammo", "antidote", "serum" };
new const ITEM_FAM533[] = { IF_HEAL, IF_ARMOR, IF_POWER, IF_POWER, IF_POWER, IF_JUMP, IF_SPEED, IF_REGEN, IF_AMMO, IF_RAGE,
    IF_POWER, IF_ANTIDOTE, IF_MADNESS, IF_SERUM, IF_SERUM, IF_RAGE, IF_POWER, IF_ARMOR, IF_SPEED, IF_CLOAK, IF_POWER, IF_SHIELD,
    IF_AMMO, IF_SPEED, IF_CLOAK, IF_JUMP, IF_REGEN, IF_SHIELD };
ItemSndPrecache533()
{
new key[32], path[96];
for (new f = 0; f < IF_TOTAL; f++)
{
formatex(key, charsmax(key), "ITEM_SND_%s", IF_NAME533[f]);
if (!TrieGetString(g_tRes, key, path, charsmax(path)))
{
{ static const IF_S535[][] = { "power", "heal", "shield", "roar", "roar2", "whoosh", "whoosh", "speed", "shield", "heal", "", "heal", "acid" };
if (f == IF_AMMO) copy(path, charsmax(path), "items/9mmclip1.wav"); else formatex(path, charsmax(path), "vexmira/s534/%s.wav", IF_S535[f]); }
TrieSetString(g_tRes, key, path);
}
PrecacheSoundKeyEx(key, false);
}
}
ItemFx533(id, i, const Float:o[3])
{
new f = (0 <= i < sizeof ITEM_FAM533) ? ITEM_FAM533[i] : IF_POWER;
new key[32]; formatex(key, charsmax(key), "ITEM_SND_%s", IF_NAME533[f]);
EmitKey(id, key, CHAN_ITEM, ATTN_NORM);
if (!g_iFx532[X_GLOW]) return;
new Float:c[3]; c = o; c[2] += 10.0;
new Float:feet[3]; feet = o; feet[2] -= ((get_entvar(id, var_flags) & FL_DUCKING) ? 16.0 : 34.0);
switch (f)
{
case IF_HEAL: { NxSprite(c, g_iFx532[X_GLOW], 10, 200, 10.0); NxShower(c, g_iFx532[X_TOXICMIST], 10, 10, 2, 22, 18, 60.0); NxRing(feet, g_iFx532[X_RING], 80, 255, 120, 120, 16, 5, 200, 2.0); }
case IF_ARMOR, IF_SHIELD: { NxExplo(c, g_iFx532[X_SHOCKBURST], 9, 22, 6.0); NxShower(c, g_iFx532[X_SHARD], 14, 8, 2, 30, 20, 30.0); NxRing(feet, g_iFx532[X_RING], 120, 200, 255, 150, 20, 4, 230, 2.0); }
case IF_MADNESS:
{
NxExplo(c, g_iFx532[X_FIREBALL], 12, 18, 10.0);
NxRing(feet, g_iFx532[X_RING], 255, 20, 20, 260, 34, 5, 240, 2.0); NxRing(feet, g_iFx532[X_RING], 255, 120, 80, 160, 16, 4, 255, 6.0);
NxLight(c, 255, 20, 20, 30, 12, 20); NxShakeNear(o, 300.0, 6); FadeOne(id, 255, 0, 0, 90, 0.6);
}
case IF_RAGE: { NxExplo(c, g_iFx532[X_FIREBALL], 10, 20, 6.0); NxShower(c, g_iFx532[X_EMBER], 18, 10, 2, 40, 24); NxRing(feet, g_iFx532[X_RING], 255, 90, 20, 200, 24, 4, 230, 2.0); }
case IF_CLOAK: { NxExplo(c, g_iFx532[X_VOIDBURST], 10, 16, 6.0); NxRing(feet, g_iFx532[X_RING], 170, 80, 255, 140, 20, 6, 180, 2.0); }
case IF_JUMP: { NxRing(feet, g_iFx532[X_RING], 255, 230, 120, 110, 12, 3, 240, 1.0); NxShower(feet, g_iFx532[X_SPARK], 20, 6, 1, 50, 12, 40.0); }
case IF_SPEED: { NxStreak(feet, 0x6B, 40, 260, 120); NxRing(feet, g_iFx532[X_RING], 255, 220, 60, 180, 14, 3, 240, 2.0); NxShower(c, g_iFx532[X_SPARK], 12, 6, 1, 46, 30); }
case IF_REGEN, IF_ANTIDOTE, IF_SERUM: { NxField(feet, g_iFx532[X_TOXICMIST], 50, 8, TEFIRE_ADD532 | TEFIRE_FLAG_SOMEFLOAT | TEFIRE_FLAG_LOOP, 10); NxSprite(c, g_iFx532[X_GLOW], 8, 180, 10.0); }
case IF_AMMO: { NxShower(c, g_iFx532[X_SPARK], 16, 6, 1, 34, 20, 20.0); NxRing(feet, g_iFx532[X_RING], 255, 200, 90, 100, 12, 3, 220, 2.0); }
default: { NxSprite(c, g_iFx532[X_GLOW], 12, 220, 10.0); NxExplo(c, g_iFx532[X_FLARE], 8, 14, 10.0); }
}
}
VxItemFxRGB531(id, r, g, b)
{
if (!is_user_alive(id)) return;
new Float:o[3], Float:f[3];
get_entvar(id, var_origin, o);
f = o; f[2] -= ((get_entvar(id, var_flags) & FL_DUCKING) ? 16.0 : 34.0);
FxRingEx(f, r, g, b, 140, 14, 5, 230);
FxRingEx(f, 255, 255, 255, 70, 6, 3, 160);
FxLight(o, r, g, b, 22, 6, 40);
FxImplosion(o, 70, 18, 4);
FadeOne(id, r, g, b, 55, 0.35);
}
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
ShowSpecialMenu(id)
{
CommunityWeaponMenu(id);
}
public menu_special_handler(id, menu, item)
{
if (item >= 0) { new i = MenuInfo(menu, item); if(i==999) { menu_destroy(menu); ShowShopMenu(id); return PLUGIN_HANDLED; } CommunityBuyWeapon(id, i); }
menu_destroy(menu);
return PLUGIN_HANDLED;
}
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
if (lv >= PERK_MAX)
formatex(item, charsmax(item), "\y%s \r[\y%s\r] [\yMAX\r]", n1, stars);
else
formatex(item, charsmax(item), "\y%s \r[\y%s\r] [%s%d VC\r]", n1, stars,
g_iVC[id] >= (lv + 1) * PERK_COST_STEP ? "\y" : "\r", (lv + 1) * PERK_COST_STEP);
MenuAdd(menu, item, i);
}
formatex(item,charsmax(item),"%L",id,"MENU_BACK");MenuAdd(menu,item,999);
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
if(p==999) {ShowCosmeticMenu(id);return PLUGIN_HANDLED;}
if(p<0 || p>=NUM_PERKS) return PLUGIN_HANDLED;
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
LoadVip(id)
{
g_iVip[id] = 0;
g_iVipExpire[id] = 0;
if (is_user_bot(id))
return;
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
VipVoteW(id)
{
if (!(1 <= id <= g_iMax) || !IsVip(id))
return 1;
return clamp(get_pcvar_num(g_pVipVoteW), 1, 3);
}
Float:VipSpawnProt(id)
{
if (!IsVip(id))
return 0.0;
return floatclamp(get_pcvar_float(g_pVipSpawnProt), 0.0, 5.0);
}
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
MaxAirJumps(id)
{
if (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id] || g_bMinion[id])
return 0;
new n = g_iExtraJumps[id];
if (IsVip(id))  n++;
if (IsElite(id)) n++;
return n;
}
public msg_ScoreAttrib(msgid, dest, rcv)
{
new p = get_msg_arg_int(1);
if (1 <= p <= g_iMax && IsVip(p) && get_pcvar_num(g_pVipScore))
set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2) | (1 << 2));
return PLUGIN_CONTINUE;
}
VipWelcome(id)
{
if (!IsVip(id))
return;
new name[32], tier[16];
get_user_name(id, name, charsmax(name));
VipTierKey(id, tier, charsmax(tier));
new pri = get_pcvar_num(g_pVipPriority);
if (pri > 0 && get_playersnum(1) >= g_iMax - pri)
{
for (new p = 1; p <= g_iMax; p++)
if (is_user_connected(p) && !is_user_bot(p))
client_print_color(p, id, "%s %L", ChatTag("VIP_JOIN"), p, "VIP_PRIORITY", name);
}
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
ShowVipInfo(id,page=0)
{
new contact[64],title[320],item[112],key[24];get_pcvar_string(g_pVipContact,contact,charsmax(contact));
VexHead(id,title,charsmax(title),"VIPI_TITLE",contact);
new menu=VexMenuCreate(title,"EpicVipInfoHandler");
for(new i=0;i<15;i++) {formatex(key,charsmax(key),"E46_VIPINFO%d",i);formatex(item,charsmax(item),"%L",id,key);MenuAdd(menu,item,i);}
formatex(item,charsmax(item),"%L",id,"MENU_BACK");MenuAdd(menu,item,999);
MenuProps(id,menu);menu_setprop(menu,MPROP_PERPAGE,5);menu_display(id,menu,clamp(page,0,3));g_iMenuFor=0;
}
public EpicVipInfoHandler(id,menu,item)
{
if(item<0) {menu_destroy(menu);return PLUGIN_HANDLED;}
new sel=MenuInfo(menu,item),page=item/5;menu_destroy(menu);
if(sel==999) {if(IsVip(id)) ShowVipMenu(id);else ShowMainMenu(id);return PLUGIN_HANDLED;}
switch(sel) {
case 0:Chat(id,"VIPI_2",get_pcvar_num(g_pVipBonus),get_pcvar_num(g_pEliteBonus));
case 1:Chat(id,"VIPI_3",get_pcvar_num(g_pVipDisc),get_pcvar_num(g_pEliteDisc));
case 2:Chat(id,"VIPI_6",get_pcvar_num(g_pVipRoundVC),get_pcvar_num(g_pVipRoundVC)*2);
case 3:Chat(id,"VIPI_7",get_pcvar_num(g_pVipDaily),get_pcvar_num(g_pEliteDaily));
case 4:Chat(id,get_pcvar_num(g_pVipAutoPack)?"VIPI_4A":"VIPI_4");
case 5:Chat(id,"VIPI_5",get_pcvar_num(g_pVipArmor),get_pcvar_num(g_pEliteArmor),get_pcvar_num(g_pLmPerRoundVip));
case 6:Chat(id,"VIPI_1");
case 7:Chat(id,"VIPI_9",get_pcvar_float(g_pVipSpawnProt));
case 8:Chat(id,"VIPI_10",clamp(get_pcvar_num(g_pVipVoteW),1,3));
case 9:Chat(id,"VIPI_11");
case 10:Chat(id,"VIPI_12");
case 11:Chat(id,"VIPI_8");
case 12:Chat(id,"VIPI_13");
case 13:Chat(id,"VIPI_14");
case 14: {if(IsVip(id)) {EpicVipMenu(id);return PLUGIN_HANDLED;}else Chat(id,"E46_VIPINVITE");}
}
ShowVipInfo(id,page);return PLUGIN_HANDLED;
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
formatex(item, charsmax(item), "\y%L", id, "E46_VIPFX");
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
case 4: { EpicVipMenu(id); return PLUGIN_HANDLED; }
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
TickVip()
{
}
new const TRAIL_RGB[NUM_TRAILS][3] =
{
{0, 200, 255}, {70, 255, 90}, {255, 30, 30}, {170, 70, 255}, {255, 200, 30}, {255, 255, 255}
};
new const RAINBOW_RGB[6][3] =
{
{255, 40, 40}, {255, 150, 0}, {255, 240, 40}, {40, 255, 90}, {0, 180, 255}, {190, 70, 255}
};
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
public cmd_cosmetic(id)
{
ShowCosmeticMenu(id);
return PLUGIN_HANDLED;
}
ShowCosmeticMenu(id)
{
new title[320],item[128]; VexHead(id,title,charsmax(title),"E46_COIN");
new menu=VexMenuCreate(title,"menu_cos_handler");
formatex(item,charsmax(item),"%L \d[VC]",id,"ZC_SKINS"); MenuAdd(menu,item,21);
formatex(item,charsmax(item),"%L \d[VC]",id,"ZC_KNIVES"); MenuAdd(menu,item,22);
for(new c=0;c<CM_CATS;c++) {
if(c==2) continue;
formatex(item,charsmax(item),"%L \d[VC]",id,CM_CATKEY[c]);
MenuAdd(menu,item,3+c);
}
formatex(item,charsmax(item),"%L",id,"ZC_FX"); MenuAdd(menu,item,23);
formatex(item,charsmax(item),"%s \d[VC]",LzTr531(id)?"Lazer Isinlari":"Laser Beams"); MenuAdd(menu,item,26);
formatex(item,charsmax(item),"\w%L \d[%L]",id,"COS_HIDE_OTHERS",id,(g_iSet[id]&SET_NO_COS)?"COS_HIDDEN":"COS_VISIBLE");
MenuAdd(menu,item,9);
formatex(item,charsmax(item),"%L",id,"MENU_PERKS");MenuAdd(menu,item,24);
formatex(item,charsmax(item),"%L",id,"SHOP_EXCHANGE",max(1,get_pcvar_num(g_pExchange)));MenuAdd(menu,item,25);
MenuFinish(id,menu);
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
if(cat==24) {ShowPerkMenu(id);return PLUGIN_HANDLED;}
if(cat==25) {Exchange(id);ShowCosmeticMenu(id);return PLUGIN_HANDLED;}
if(cat==26) {ShowLaserShop531(id);return PLUGIN_HANDLED;}
if (cat == 9)
{
g_iSet[id] ^= SET_NO_COS;
Chat(id, (g_iSet[id] & SET_NO_COS) ? "COS_HIDE_ON" : "COS_HIDE_OFF");
SaveData(id);
ShowCosmeticMenu(id);
}
else if (cat == 23) CommunityEffectMenu(id);
else if (cat == 21 || cat == 22)
CommunityCoinMenu(id, cat - 21);
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
CmParse(const args[][], argc)
{
new c = -1;
for (new k = 0; k < CM_CATS; k++)
if (equali(args[0], CM_TABLE[k])) c = k;
if (c < 0 || argc < 5)
return;
if (c == 2)
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
g_bCmOk[c][i] = false;
if (!g_szCmMdl[c][i][0] || !file_exists(g_szCmMdl[c][i], true))
{
log_amx("[Vexmira] %s %d: model yok (%s) - menude gizli", args[0], i + 1, g_szCmMdl[c][i]);
g_szCmMdl[c][i][0] = 0;
}
}
CmPrecache()
{
for (new c = 0; c < CM_CATS; c++)
{
g_iCmN[c] = 0;
for (new i = 0; i < CM_MAX; i++)
{
g_bCmOk[c][i] = (g_szCmMdl[c][i][0] && PcModel(g_szCmMdl[c][i])) ? true : false;
if (g_bCmOk[c][i]) {
CommunityCosMetadata(c,i);
g_iCmN[c]++;
}
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
new ent = CreateSafe51("info_target");
if (is_nullent(ent))
return;
if (ent >= OVH_MAXENT)
{
set_entvar(ent, var_flags, FL_KILLME);
return;
}
set_entvar(ent, var_classname, "vex_cosmodel");
VxSM(ent, g_szCmMdl[c][i]);
set_entvar(ent, var_solid, SOLID_NOT);
set_entvar(ent, var_movetype, MOVETYPE_NOCLIP);
set_entvar(ent, var_iuser1, id);
set_entvar(ent, var_iuser2, CM_MAGIC);
set_entvar(ent, var_scale, g_fCmScale[c][i]);
set_entvar(ent, var_sequence, g_iCmSeq[c][i]);
set_entvar(ent, var_framerate, g_fCmFps[c][i] > 0.0 ? g_fCmFps[c][i] : 1.0);
set_entvar(ent, var_animtime, get_gametime());
set_pev(ent,pev_controller_0,128);set_pev(ent,pev_controller_1,128);set_pev(ent,pev_controller_2,128);set_pev(ent,pev_controller_3,128);
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
CmCtlByte(Float:v, Float:a, Float:b)
{
return clamp(floatround((v - a) * 255.0 / (b - a)), 0, 255);
}
CmCtl(id, c, i, bool:duck, ctl[4])
{
new Float:top = duck ? g_fOvhDuck[id] : g_fOvhStand[id];
new Float:z = g_fCmOfs[c][i][2];
switch (g_iCmAtt[c][i])
{
case CMA_HEAD:   z += top;
case CMA_BACK:   z += top - 18.0;
case CMA_FOLLOW: z += top - 10.0;
}
new Float:sc = g_fCmScale[c][i] > 0.05 ? g_fCmScale[c][i] : 1.0;
ctl[0] = CmCtlByte(g_fCmOfs[c][i][0] / sc, CM_CTL_X0, CM_CTL_X1);
ctl[1] = CmCtlByte(-g_fCmOfs[c][i][1] / sc, CM_CTL_Y0, CM_CTL_Y1);
ctl[2] = CmCtlByte(z / sc, CM_CTL_Z0, CM_CTL_Z1);
ctl[3] = 0;
}
CmApplyCtl(ent, id, c, i)
{
new ctl[4];
CmCtl(id, c, i, (get_entvar(id, var_flags) & FL_DUCKING) ? true : false, ctl);
set_pev(ent, pev_controller_0, ctl[0]);
set_pev(ent, pev_controller_1, ctl[1]);
set_pev(ent, pev_controller_2, ctl[2]);
}
CmSpawn(id, c, i)
{
new ent = CreateSafe51("info_target");
if (is_nullent(ent))
return 0;
if (ent >= OVH_MAXENT)
{
set_entvar(ent, var_flags, FL_KILLME);
return 0;
}
set_entvar(ent, var_classname, "vex_cosmodel");
VxSM(ent, g_szCmMdl[c][i]);
set_entvar(ent, var_solid, SOLID_NOT);
set_entvar(ent, var_iuser1, id);
set_entvar(ent, var_iuser2, CM_MAGIC);
set_entvar(ent, var_scale, g_fCmScale[c][i]);
set_entvar(ent, var_sequence, g_iCmSeq[c][i]);
set_entvar(ent, var_framerate, g_fCmFps[c][i]);
set_entvar(ent, var_animtime, get_gametime());
set_entvar(ent, var_frame, 0.0);
set_pev(ent,pev_controller_0,128);set_pev(ent,pev_controller_1,128);set_pev(ent,pev_controller_2,128);set_pev(ent,pev_controller_3,128);
new Float:o[3];
get_entvar(id, var_origin, o);
engfunc(EngFunc_SetOrigin, ent, o);
set_entvar(ent,var_movetype,MOVETYPE_NOCLIP);
OvhModelTops(id);
CommunityCosOrigin(ent,id,c,i);
g_iCmOwn[ent] = id;
g_iCmInfo[ent] = c * 16 + i;
g_iCmEnt[id][c] = ent;
return ent;
}
CmTick(Float:now)
{
if (!g_iCmN[0] && !g_iCmN[1] && !g_iCmN[2])
return;
for (new id = 1; id <= g_iMax; id++)
{
new bool:conn = is_user_connected(id) ? true : false;
if (!g_iCmSelPk[id] && !g_iCmPrev[id] && !g_iCmEnt[id][0] && !g_iCmEnt[id][1] && !g_iCmEnt[id][2]) continue;
if (g_iCmPrev[id])
{CmPrevTick(id, now, conn);new info48=g_iCmPrevInfo[id];if(CmValid(g_iCmPrev[id],id)) CommunityCosAnimate(g_iCmPrev[id],info48/16,info48%16,now);}
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
CommunityCosOrigin(ent, id, c, i);
if(c==1 && g_fCmOfs[c][i][2]<0.0) { new Float:po49[3];get_entvar(ent,var_origin,po49);g_fPetFloor49[id]=po49[2];CommunityPetMove49(id); }
CommunityCosState48(ent,id,c,i);
if (get_entvar(ent, var_movetype) != MOVETYPE_FOLLOW) CommunityCosAnimate(ent,c,i,now);
}
}
}
CmPack(es, ent, host)
{
if (!get_orig_retval())
return FMRES_IGNORED;
new id = g_iCmOwn[ent];
if (!(1 <= id <= g_iMax))
return FMRES_IGNORED;
if (g_iCmInfo[ent] >= 100)
{
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
if(c==1 && g_fCmOfs[c][i][2]<0.0) {
new Float:po49[3];get_entvar(id,var_origin,po49);
po49[0]+=g_fPetRel49[id][0];po49[1]+=g_fPetRel49[id][1];po49[2]=g_fPetFloor49[id];
set_es(es,ES_Origin,po49);
} else if(c!=1 && get_entvar(ent,var_movetype)!=MOVETYPE_FOLLOW) {
if(get_pcvar_num(g_pCosSmooth532)) {set_es(es,ES_MoveType,MOVETYPE_STEP);set_es(es,ES_AnimTime,get_gametime());}
new Float:po49[3];get_entvar(id,var_origin,po49);
new Float:eo49[3],Float:old49[3];get_entvar(ent,var_origin,eo49);get_entvar(ent,var_vuser1,old49);
new Float:ya51[3];get_entvar(id,var_angles,ya51);
new Float:dy51=(ya51[1]-Float:get_entvar(ent,var_fuser3))*0.0174532925;
new Float:x51=eo49[0]-old49[0],Float:y51=eo49[1]-old49[1];
po49[0]+=x51*floatcos(dy51)-y51*floatsin(dy51);po49[1]+=x51*floatsin(dy51)+y51*floatcos(dy51);po49[2]+=eo49[2]-old49[2];
ya51[0]=g_fCmAng[c][i][0];ya51[1]+=g_fCmAng[c][i][1];ya51[2]=g_fCmAng[c][i][2];set_es(es,ES_Angles,ya51);
set_es(es,ES_Origin,po49);
}
if (att != CMA_FOLLOW && ((host == id && (!g_iCamera47[id] || is_nullent(g_iCamera47[id]))) || (get_entvar(host, var_iuser1) == 4 && get_entvar(host, var_iuser2) == id)))
{
set_es(es, ES_Effects, get_es(es, ES_Effects) | EF_NODRAW);
return FMRES_IGNORED;
}
return FMRES_IGNORED;
}
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
continue;
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
ShowCmBuy(id, c, i);
return PLUGIN_HANDLED;
}
CmSetSel(id, c, i + 1);
Chat(id, "COS_EQUIP", nm);
SaveData(id);
ShowCmList(id, c);
return PLUGIN_HANDLED;
}
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
CmDoBuy(id, c, i);
ShowCmList(id, c);
return PLUGIN_HANDLED;
}
CmDoBuy(id, c, i)
{
if (c < 0 || c >= CM_CATS || i < 0 || i >= CM_MAX || !g_bCmOk[c][i])
return 0;
new nm[32], bit = 1 << (c * 8 + i);
CmName(id, c, i, nm, charsmax(nm));
if (g_iCmVip[c][i] && !IsVip(id))
{
Chat(id, "VIP_ONLY");
return 0;
}
if (!(g_iCmOwned[id] & bit))
{
new price = CmPrice(id, c, i);
if (g_iVC[id] < price)
{
Chat(id, "COS_NOVC", price);
return 0;
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
return 1;
}
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
public srv_CosDump()
{
new mdl[32];
read_argv(1, mdl, charsmax(mdl));
if (mdl[0])
{
new Float:st, Float:du;
MdlHeadTops(mdl, st, du);
server_print("[Vexmira] cos model %s: top stand %.1f duck %.1f -> hat %.1f wing %.1f pet %.1f (oyuncu merkezine gore)",
mdl, st, du, st, st - 18.0, st - 10.0);
return PLUGIN_HANDLED;
}
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
new k0 = pev(ent, pev_controller_0), k1 = pev(ent, pev_controller_1), k2 = pev(ent, pev_controller_2);
server_print("[Vexmira] cos #%d %s ent=%d mt=%d aim=%d d=(%.0f %.0f %.0f) ctl=%d/%d/%d ofs=(fwd %.1f right %.1f up %.1f) top=%.1f/%.1f mdl=%s alive=%d z=%d",
id, CM_TABLE[c], ent, get_entvar(ent, var_movetype), get_entvar(ent, var_aiment), o[0] - po[0], o[1] - po[1], o[2] - po[2],
k0, k1, k2, CM_CTL_X0 + (CM_CTL_X1 - CM_CTL_X0) * float(k0) / 255.0, -(CM_CTL_Y0 + (CM_CTL_Y1 - CM_CTL_Y0) * float(k1) / 255.0),
CM_CTL_Z0 + (CM_CTL_Z1 - CM_CTL_Z0) * float(k2) / 255.0, g_fOvhStand[id], g_fOvhDuck[id], g_szOvhMdl[id], is_user_alive(id), g_bZombie[id]);
}
}
new n, e = -1;
while ((e = engfunc(EngFunc_FindEntityByString, e, "classname", "vex_cosmodel")) > 0)
n++;
server_print("[Vexmira] cos ents total=%d", n);
return PLUGIN_HANDLED;
}
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
case 0:
{
FxSkyStrike(o, 170, 210, 255);
FxSparks(o);
EmitKeyPos(o, "ZAP");
}
case 1:
{
FxRingEx(o, 255, 200, 30, 220, 14, 5);
FxLight(o, 255, 200, 30, 20, 10, 20);
FxSparks(o);
top = o;
top[2] += 120.0;
FxSpriteTrail(o, top, g_sprFlare, 14, 8, 2, 30, 20);
}
case 2:
{
FxBlood(o, 30);
FxLava(o);
FxRingEx(o, 200, 0, 0, 160, 10, 4);
}
case 3:
{
FxStreak(o, 7, 60, 300);
FxRingEx(o, 120, 220, 255, 200, 12, 5);
FxLight(o, 0, 190, 255, 18, 8, 20);
EmitKeyPos(o, "FREEZE");
}
case 4:
{
FxImplosion(o, 200, 50, 6);
FxRingEx(o, 200, 0, 160, 240, 18, 6);
FxLight(o, 200, 0, 160, 18, 8, 20);
}
case 5:
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
case 0:
{
FxRingEx(o, 90, 255, 0, 260, 16, 5);
FxSprite(o, g_sprSmoke, 18, 170);
}
case 1:
{
FxImplosion(o, 220, 60, 7);
FxRingEx(o, 60, 0, 90, 220, 20, 6);
}
case 2:
{
FxSkyStrike(o, 255, 0, 0);
FxBlood(o, 25);
FxRingEx(o, 255, 0, 0, 280, 14, 5);
}
}
}
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
WeaponIdType:GetActiveWeaponId(id)
{
new item = get_member(id, m_pActiveItem);
if (is_nullent(item))
return WEAPON_NONE;
return get_member(item, m_iId);
}
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
ModeOf(id)
{
if (g_bSurvivor[id]) return 0;
if (g_bSniper[id]) return 1;
return -1;
}
ModeSlot(mm, WeaponIdType:wid)
{
for (new s = 0; s < MW_SLOTS; s++)
{
if (MW_ENT[mm][s][0] && MW_ID[mm][s] == wid)
return s;
}
return -1;
}
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
VxLeanResources()
{
new Snapshot:it = TrieSnapshotCreate(g_tRes);
new key[64], path[192];
for (new index; index < TrieSnapshotLength(it); index++)
{
TrieSnapshotGetKey(it, index, key, charsmax(key));
if (TrieGetString(g_tRes, key, path, charsmax(path)) && containi(path, "vexmira/") != -1)
TrieSetString(g_tRes, key, "");
}
TrieSnapshotDestroy(it);
}
#define SW_REMOVED533 4
VxDisableSW533()
{
static const K[][] = { "SW4_VMODEL", "SW4_PMODEL", "SW4_WMODEL", "SW4_FIRE" };
for (new i = 0; i < sizeof K; i++) TrieSetString(g_tRes, K[i], "");
}
VxDefaults()
{
new key[24],path[128];
for(new sw;sw<NUM_SPECIAL;sw++) {
formatex(key,charsmax(key),"SW%d_VMODEL",sw);formatex(path,charsmax(path),"models/vexmira/arena51/arsenal/%d/v.mdl",sw);TrieSetString(g_tRes,key,path);
formatex(key,charsmax(key),"SW%d_PMODEL",sw);if(sw==7) copy(path,charsmax(path),"models/vexmira_ze/skins/vexmira_p_elite.mdl");else formatex(path,charsmax(path),"models/vexmira/arena50/arsenal/%d/p.mdl",sw);TrieSetString(g_tRes,key,path);
formatex(key,charsmax(key),"SW%d_WMODEL",sw);formatex(path,charsmax(path),"models/vexmira/arena50/arsenal/%d/w.mdl",sw);TrieSetString(g_tRes,key,path);
formatex(key,charsmax(key),"SW%d_FIRE",sw);formatex(path,charsmax(path),"vexmira/arena51/arsenal/%d/fire.wav",sw);TrieSetString(g_tRes,key,path);
}
}
new g_iSkillSpr51[8],g_iLaserBeam51,g_iLaserHit51,g_iVxHit51[33];
new const bool:V51_SWITCH_EVENT[8]={true,true,true,true,false,true,true,false};
new const bool:V51_ALT_EVENT[8]={false,false,false,false,false,false,true,true};
stock VxPrecache()
{
new key[24], path[128], full[160];
if(file_exists(VX_ORB)) g_iVxOrbModel=PcModel(VX_ORB);
for(new sw;sw<NUM_SPECIAL;sw++)
{
if(sw==SW_REMOVED533) {g_bVxReady[sw]=false;g_szSWView[sw][0]=0;g_szSWPlayer[sw][0]=0;g_szVxWorld[sw][0]=0;continue;}
formatex(path,charsmax(path),"sprites/vexmira/arena51/skill%d.spr",sw);g_iSkillSpr51[sw]=PcModel(path);
formatex(key,charsmax(key),"SW%d_VMODEL",sw);GetFileModel(key,g_szSWView[sw],charsmax(g_szSWView[]));
formatex(key,charsmax(key),"SW%d_PMODEL",sw);GetFileModel(key,g_szSWPlayer[sw],charsmax(g_szSWPlayer[]));
formatex(key,charsmax(key),"SW%d_WMODEL",sw);GetFileModel(key,g_szVxWorld[sw],charsmax(g_szVxWorld[]));
g_bVxReady[sw]=bool:(g_szSWView[sw][0]&&g_szSWPlayer[sw][0]&&g_szVxWorld[sw][0]);
new count=7;
for(new j;j<count;j++)
{
if (j >= 1 && j <= 3) continue;
formatex(path,charsmax(path),"vexmira/arena51/arsenal/%s/%s.wav",VX_FOLDER[sw],VX_SOUND[j]);
formatex(full,charsmax(full),"sound/%s",path);
if(!file_exists(full) || !PcSound(path))g_bVxReady[sw]=false;
}
if((sw==2||sw==6)&&!g_iVxOrbModel)g_bVxReady[sw]=false;
formatex(key,charsmax(key),"SW%d_FIRE",sw);PrecacheSoundKeyEx(key,false);
log_amx("[Arsenal8] slot=%d ready=%d",sw,g_bVxReady[sw]);
}
g_iLaserBeam51=PcModel("sprites/vexmira/arena51/laserbeam.spr");g_iLaserHit51=PcModel("sprites/vexmira/arena51/laserhit.spr");
g_iVxEvent=engfunc(EngFunc_PrecacheEvent,1,"events/ak47.sc");
}
VxIndex(weapon)
{
if(is_nullent(weapon))return -1;
new sw=get_entvar(weapon,var_impulse)-VX_TAG;
return (0<=sw<NUM_SPECIAL&&get_member(weapon,m_iId)==WEAPON_AK47)?sw:-1;
}
VxActive(id)
{
if(!(1<=id<=g_iMax)||!is_user_alive(id)||g_bZombie[id]||ModeOf(id)>=0)return -1;
new sw=VxIndex(get_member(id,m_pActiveItem));
return(sw>=0&&g_bVxReady[sw])?sw:-1;
}
VxTag(weapon,id,sw)
{
if(is_nullent(weapon))return;
set_entvar(weapon,var_impulse,VX_TAG+sw);g_iSpecW[id]=(1<<sw);
g_iVxShots[id]=0;set_entvar(weapon,var_fuser2,0.0);
}
VxGive(id,sw)
{
if(sw<0 || sw>=NUM_SPECIAL || !CommunityAlive(id) || !g_bVxReady[sw]) return 0;
rg_drop_items_by_slot(id,PRIMARY_WEAPON_SLOT);CommunityRemoveWeapons(id);
g_bVxGiving[id]=true;new w=rg_give_item(id,"weapon_ak47",GT_REPLACE);g_bVxGiving[id]=false;
if(is_nullent(w)) return 0;
VxTag(w,id,sw);set_member(w,m_Weapon_iClip,SW_CLIP[sw]);rg_set_user_bpammo(id,WEAPON_AK47,SW_BPAMMO[sw]);
rg_switch_weapon(id,w);set_entvar(id,var_viewmodel,g_szSWView[sw]);set_entvar(id,var_weaponmodel,g_szSWPlayer[sw]);VxAnim(id,w,V50_DRAW[sw]);
return w;
}
public VxAddToPlayerPost(weapon,id)
{
if(!(1<=id<=g_iMax)||!is_user_connected(id))return HAM_IGNORED;
new sw=VxIndex(weapon);
if(sw>=0&&!g_bZombie[id])VxTag(weapon,id,sw);
else if(!g_bVxGiving[id])g_iSpecW[id]=0;
return HAM_IGNORED;
}
VxAnim(id,weapon,anim)
{
set_entvar(id,var_weaponanim,anim);
if(!is_user_bot(id))
{
message_begin(MSG_ONE,SVC_WEAPONANIM,_,id);
write_byte(anim);write_byte(get_entvar(weapon,var_body));message_end();
}
}
VxSound(id,sw,sound,channel=CHAN_WEAPON)
{
new path[128];formatex(path,charsmax(path),"vexmira/arena51/arsenal/%s/%s.wav",VX_FOLDER[sw],VX_SOUND[sound]);
EmitSafe(id,channel,path,0.8,ATTN_NORM,0,PITCH_NORM);
}
VxCommand(id,uc)
{
new sw=VxActive(id),buttons=get_uc(uc,UC_Buttons);
if(sw<0){g_bVxRightHeld[id]=false;return;}
new bool:held=bool:(buttons&IN_ATTACK2);
set_uc(uc,UC_Buttons,buttons&~IN_ATTACK2);
if(held&&!g_bVxRightHeld[id])
{
new w=get_member(id,m_pActiveItem);
if(!get_member(w,m_Weapon_fInReload)&&Float:get_member(w,m_Weapon_flNextSecondaryAttack)<=0.0
&&Float:get_member(id,m_flNextAttack)<=0.0)
{
new mode=1-get_entvar(w,var_iuser2);set_entvar(w,var_iuser2,mode);set_entvar(w,var_body,0);
set_member(w,m_Weapon_flNextPrimaryAttack,floatmax(0.6,Float:get_member(w,m_Weapon_flNextPrimaryAttack)));
set_member(w,m_Weapon_flNextSecondaryAttack,0.6);set_member(w,m_Weapon_flTimeWeaponIdle,0.65);
VxAnim(id,w,V50_CHANGE[sw]);if(!V51_SWITCH_EVENT[sw]) VxSound(id,sw,4);
new key[24],modeName[64];formatex(key,charsmax(key),mode?"VX_ALT_%d":"VX_PRIMARY",sw);
formatex(modeName,charsmax(modeName),"%L",id,key);Chat(id,"VX_MODE",modeName);
}
}
g_bVxRightHeld[id]=held;
}
public VxAttackPre(weapon)
{
new id=get_member(weapon,m_pPlayer);if(!(1<=id<=g_iMax))return HAM_IGNORED;
g_iVxAttack[id]=0;g_bVxAltHandled[id]=false;new sw=VxActive(id);if(sw<0)return HAM_IGNORED;
if(get_entvar(weapon,var_iuser2))
{
g_bVxAltHandled[id]=true;VxAlt(id,weapon,sw);return HAM_SUPERCEDE;
}
g_iVxClip[id]=get_member(weapon,m_Weapon_iClip);g_iVxAttack[id]=weapon;return HAM_IGNORED;
}
public VxPlaybackEvent(flags,invoker,eventindex,Float:delay,Float:origin[3],Float:angles[3],Float:spreadX,Float:spreadY,punchX,punchY,b1,b2)
{
if(eventindex!=g_iVxEvent||VxActive(invoker)<0)return FMRES_IGNORED;
if(is_user_alive(invoker))
{
new Float:a[3],Float:ofs[3],Float:ang[3],Float:f[3],Float:r[3],Float:u[3],Float:b[3];
get_entvar(invoker,var_origin,a);get_entvar(invoker,var_view_ofs,ofs);get_entvar(invoker,var_v_angle,ang);
ang[0]+=float(punchX)/100.0;ang[1]+=float(punchY)/100.0;engfunc(EngFunc_MakeVectors,ang);
global_get(glb_v_forward,f);global_get(glb_v_right,r);global_get(glb_v_up,u);
for(new j;j<3;j++){a[j]+=ofs[j];b[j]=a[j]+(f[j]+r[j]*spreadX+u[j]*spreadY)*8192.0;g_fVxStart[invoker][j]=a[j]+f[j]*18.0;}
engfunc(EngFunc_TraceLine,a,b,DONT_IGNORE_MONSTERS,invoker,0);get_tr2(0,TR_vecEndPos,g_fVxEnd[invoker]);g_iVxHit51[invoker]=get_tr2(0,TR_pHit);g_fVxStart[invoker][2]-=4.0;
}
return FMRES_SUPERCEDE;
}
public VxSendAnim(weapon,anim,skiplocal)
{
new sw=VxIndex(weapon);if(sw<0) return HC_CONTINUE;
new mapped=V50_IDLE[sw];if(anim==1) mapped=V50_RELOAD[sw];else if(anim==2) mapped=V50_DRAW[sw];else if(anim>=3 && anim<=5) mapped=V50_FIRE[sw][anim-3];
SetHookChainArg(2,ATYPE_INTEGER,mapped);SetHookChainArg(3,ATYPE_INTEGER,0);return HC_CONTINUE;
}
public VxClientDataPost(id,sendweapons,cd)
{
if(VxActive(id)>=0)set_cd(cd,CD_flNextAttack,get_gametime()+0.001);return FMRES_IGNORED;
}
VxShot(id,sw)
{
new weapon=get_member(id,m_pActiveItem);g_iVxShots[id]++;VxAnim(id,weapon,V50_FIRE[sw][g_iVxShots[id]%3]);EmitSpecialFire(id,sw);
if(sw==0) VxPierce51(id);
if(sw==1) {FxSprite(g_fVxEnd[id],g_iSkillSpr51[1],8,140);VxRadius(g_fVxEnd[id],id,id,sw,75.0,35.0);}
if(sw==3) VxPellets51(id);
if(sw==5 && !(g_iVxShots[id]%2)) FxBeamEx(g_fVxStart[id],g_fVxEnd[id],g_iLaserBeam51,80,215,255,4,0,1,140);
if(g_iVxShots[id]%max(3,get_pcvar_num(g_pSixTracer)))return;
FxBeamEx(g_fVxStart[id],g_fVxEnd[id],g_sprBeam,SW_RGB[sw][0],SW_RGB[sw][1],SW_RGB[sw][2],3,0,1,150);
}
VxAim(id,Float:a[3],Float:f[3],Float:b[3],Float:angle[3])
{
new Float:ofs[3];get_entvar(id,var_origin,a);get_entvar(id,var_view_ofs,ofs);get_entvar(id,var_v_angle,angle);
for(new j;j<3;j++)a[j]+=ofs[j];engfunc(EngFunc_MakeVectors,angle);global_get(glb_v_forward,f);
for(new j;j<3;j++)b[j]=a[j]+f[j]*4096.0;
}
bool:VxLOS(const Float:a[3],victim,ignore)
{
new Float:b[3];get_entvar(victim,var_origin,b);b[2]+=18.0;
new tr=create_tr2();engfunc(EngFunc_TraceLine,a,b,DONT_IGNORE_MONSTERS,ignore,tr);
new Float:fr531;get_tr2(tr,TR_flFraction,fr531);new bool:ok=bool:(get_tr2(tr,TR_pHit)==victim||fr531>=0.98);free_tr2(tr);return ok;
}
VxDamage(victim,attacker,inflictor,Float:damage)
{
if(!(1<=victim<=g_iMax)||!is_user_alive(victim)||!g_bZombie[victim])return;
if(!(1<=attacker<=g_iMax)||!is_user_alive(attacker)||g_bZombie[attacker]||ModeOf(attacker)>=0)return;
ExecuteHamB(Ham_TakeDamage,victim,inflictor,attacker,damage*floatclamp(get_pcvar_float(g_pSwDmg531),0.1,20.0),DMG_ENERGYBEAM);
}
VxRadius(const Float:o[3],id,ent,sw,Float:radius,Float:damage)
{
new Float:p[3];
for(new v=1;v<=g_iMax;v++)
{
if(!is_user_alive(v)||!g_bZombie[v])continue;get_entvar(v,var_origin,p);
new Float:dist=get_distance_f(o,p);if(dist>radius||!VxLOS(o,v,ent))continue;
VxDamage(v,id,ent,damage*(1.0-0.45*dist/radius));
if(!is_user_alive(v))continue;
if(sw==4)Freeze(v,0.8);
if(sw==6&&!g_bBoss[v]&&!g_bNemesis[v]&&!g_bAssassin[v])
{
new Float:vel[3];for(new j;j<3;j++)vel[j]=(o[j]-p[j])*1.6;
vel[2]=floatclamp(vel[2],-80.0,80.0);set_entvar(v,var_velocity,vel);
g_fSlow[v]=floatmax(g_fSlow[v],get_gametime()+0.3);rg_reset_maxspeed(v);
}
}
}
VxRay(id,sw,const Float:a[3],const Float:f[3],const Float:b[3])
{
new Float:start[3],Float:end[3];start=a;
if(sw==7) {VxGunkata51(id,a);return;}
new tr=create_tr2(),ignore=id,limit=(sw==0||sw==4)?3:1;new hitFirst;
for(new n;n<limit;n++)
{
engfunc(EngFunc_TraceLine,start,b,DONT_IGNORE_MONSTERS,ignore,tr);get_tr2(tr,TR_vecEndPos,end);
new victim=get_tr2(tr,TR_pHit);if(n==0)hitFirst=victim;
if(!(1<=victim<=g_iMax)||!is_user_alive(victim)||!g_bZombie[victim])break;
VxDamage(victim,id,id,(sw==0?155.0:(sw==1?240.0:(sw==4?190.0:135.0)))*(1.0-0.2*float(n)));
ignore=victim;for(new j;j<3;j++)start[j]=end[j]+f[j]*0.5;
}
free_tr2(tr);FxSprite(end,sw==5?g_iLaserHit51:g_iSkillSpr51[sw],10,185);if(sw==1)VxRadius(end,id,id,sw,105.0,85.0);FxBeamEx(a,end,sw==5?g_iLaserBeam51:g_sprBeam,SW_RGB[sw][0],SW_RGB[sw][1],SW_RGB[sw][2],sw==7?10:7,sw==5?10:0,2,220);FxSparks(end);
if(sw==5&&1<=hitFirst<=g_iMax)
{
new Float:p[3],Float:q[3];get_entvar(hitFirst,var_origin,p);new count;
for(new v=1;v<=g_iMax&&count<2;v++)
{
if(v==hitFirst||!is_user_alive(v)||!g_bZombie[v])continue;get_entvar(v,var_origin,q);
if(get_distance_f(p,q)>230.0||!VxLOS(p,v,hitFirst))continue;
FxBeamEx(p,q,g_sprLightning,SW_RGB[sw][0],SW_RGB[sw][1],SW_RGB[sw][2],8,12,2,220);VxDamage(v,id,id,60.0);count++;
}
}
}
bool:VxOwnedEntity(ent)
{
if(is_nullent(ent))return false;
new classname[32];get_entvar(ent,var_classname,classname,charsmax(classname));
return bool:equal(classname,"vx_arsenal_projectile");
}
VxFreeSlot(id)
{
new count,slot=-1;
for(new i;i<VX_MAX_PROJECTILES;i++)
{
new e=g_iVxProjectiles[i];if(!VxOwnedEntity(e)){g_iVxProjectiles[i]=0;if(slot<0)slot=i;continue;}
if(get_entvar(e,var_owner)==id)count++;
}
return count>=2?-1:slot;
}
VxRemove(ent)
{
for(new i;i<VX_MAX_PROJECTILES;i++)if(g_iVxProjectiles[i]==ent)g_iVxProjectiles[i]=0;
if(VxOwnedEntity(ent))engfunc(EngFunc_RemoveEntity,ent);
}
VxClear(owner=0)
{
for(new i;i<VX_MAX_PROJECTILES;i++)
{
new e=g_iVxProjectiles[i];if(!VxOwnedEntity(e)){g_iVxProjectiles[i]=0;continue;}
if(!owner||get_entvar(e,var_owner)==owner)VxRemove(e);
}
}
bool:VxSpawn(id,sw,const Float:a[3],const Float:f[3],const Float:angle[3])
{
new slot=VxFreeSlot(id);if(slot<0)return false;
new ent=CreateSafe51("info_target");if(is_nullent(ent))return false;
g_iVxProjectiles[slot]=ent;set_entvar(ent,var_classname,"vx_arsenal_projectile");set_entvar(ent,var_owner,id);
set_entvar(ent,var_iuser1,sw);set_entvar(ent,var_iuser3,get_user_userid(id));set_entvar(ent,var_iuser4,slot+1);
set_entvar(ent,var_fuser1,get_gametime()+(sw==3?0.7:3.0));set_entvar(ent,var_fuser3,get_gametime());set_entvar(ent,var_angles,angle);
VxSM(ent,VX_ORB);set_entvar(ent,var_skin,0);set_entvar(ent,var_scale,0.25);set_entvar(ent,var_rendermode,kRenderTransAdd);set_entvar(ent,var_renderamt,220.0);new Float:rgb50[3];for(new k=0;k<3;k++) rgb50[k]=float(SW_RGB[sw][k]);set_entvar(ent,var_rendercolor,rgb50);
new Float:start[3],Float:vel[3];for(new j;j<3;j++){start[j]=a[j]+f[j]*32.0;vel[j]=f[j]*(sw==2?680.0:750.0);}
if(sw==3)
{
start[2]-=8.0;set_entvar(ent,var_movetype,MOVETYPE_NONE);set_entvar(ent,var_solid,SOLID_NOT);
set_entvar(ent,var_sequence,0);set_entvar(ent,var_animtime,get_gametime());set_entvar(ent,var_framerate,1.0);
}
else
{
start=a;set_entvar(ent,var_movetype,MOVETYPE_FLY);set_entvar(ent,var_solid,SOLID_BBOX);
engfunc(EngFunc_SetSize,ent,Float:{-3.0,-3.0,-3.0},Float:{3.0,3.0,3.0});
set_entvar(ent,var_velocity,vel);set_entvar(ent,var_avelocity,Float:{20.0,140.0,30.0});
}
engfunc(EngFunc_SetOrigin,ent,start);set_entvar(ent,var_nextthink,get_gametime()+0.1);return true;
}
public VxProjectileTouch(ent,other)
{
if(!VxOwnedEntity(ent))return FMRES_IGNORED;
new slot=get_entvar(ent,var_iuser4)-1;
if(!(0<=slot<VX_MAX_PROJECTILES)||g_iVxProjectiles[slot]!=ent)return FMRES_IGNORED;
new sw=get_entvar(ent,var_iuser1),owner=get_entvar(ent,var_owner);if(sw==3||other==owner)return FMRES_IGNORED;
new Float:o[3];get_entvar(ent,var_origin,o);
if(!(1<=owner<=g_iMax)||!is_user_alive(owner)||g_bZombie[owner]||ModeOf(owner)>=0||get_user_userid(owner)!=get_entvar(ent,var_iuser3)){VxRemove(ent);return FMRES_IGNORED;}
VxSound(ent,sw,6,CHAN_BODY);FxSprite(o,g_iSkillSpr51[sw],12,195);FxRingEx(o,SW_RGB[sw][0],SW_RGB[sw][1],SW_RGB[sw][2],sw==2?185:155,12,4);
if(sw==6)
{
set_entvar(ent,var_solid,SOLID_NOT);set_entvar(ent,var_movetype,MOVETYPE_NONE);set_entvar(ent,var_velocity,Float:{0.0,0.0,0.0});
set_entvar(ent,var_fuser1,get_gametime()+0.85);set_entvar(ent,var_fuser2,get_gametime());set_entvar(ent,var_nextthink,get_gametime()+0.05);
VxRadius(o,owner,ent,sw,160.0,20.0);FxImplosion(o,120,12,4);return FMRES_IGNORED;
}
if(sw==2) {new Float:hp51[3];for(new h51=1;h51<=g_iMax;h51++) if(is_user_alive(h51)&&!g_bZombie[h51]) {get_entvar(h51,var_origin,hp51);if(get_distance_f(o,hp51)<=160.0) HealTo(h51,20,MaxHumanHP(h51));}}
VxRadius(o,owner,ent,sw,sw==2?185.0:155.0,sw==2?220.0:105.0);FxParticles(o,90,sw==2?112:96,3);VxRemove(ent);return FMRES_IGNORED;
}
public VxProjectileThink(ent)
{
if(!VxOwnedEntity(ent))return FMRES_IGNORED;new slot=get_entvar(ent,var_iuser4)-1;
if(!(0<=slot<VX_MAX_PROJECTILES)||g_iVxProjectiles[slot]!=ent)return FMRES_IGNORED;
new owner=get_entvar(ent,var_owner),sw=get_entvar(ent,var_iuser1);new Float:now=get_gametime();
if(!(1<=owner<=g_iMax)||!is_user_alive(owner)||g_bZombie[owner]||ModeOf(owner)>=0||get_user_userid(owner)!=get_entvar(ent,var_iuser3)
||g_bRoundEnded||now>=Float:get_entvar(ent,var_fuser1)){VxRemove(ent);return FMRES_IGNORED;}
if(sw==6&&get_entvar(ent,var_solid)==SOLID_NOT&&now>=Float:get_entvar(ent,var_fuser2))
{
new Float:o[3];get_entvar(ent,var_origin,o);VxRadius(o,owner,ent,sw,160.0,20.0);
set_entvar(ent,var_fuser2,now+0.2);
}
set_entvar(ent,var_frame,float(floatround((now-Float:get_entvar(ent,var_fuser3))*16.0)%16));set_entvar(ent,var_animtime,now);
set_entvar(ent,var_nextthink,now+0.1);return FMRES_IGNORED;
}
VxRoar(id,const Float:a[3],const Float:f[3])
{
new Float:p[3],Float:delta[3],Float:end[3];for(new j;j<3;j++)end[j]=a[j]+f[j]*180.0;
new tr=create_tr2();engfunc(EngFunc_TraceLine,a,end,IGNORE_MONSTERS,id,tr);get_tr2(tr,TR_vecEndPos,end);free_tr2(tr);
FxBeamEx(a,end,g_sprBeam,255,100,35,25,7,3,210);FxSprite(end,g_iSkillSpr51[3],10,200);
for(new v=1;v<=g_iMax;v++)
{
if(!is_user_alive(v)||!g_bZombie[v])continue;get_entvar(v,var_origin,p);p[2]+=16.0;
new Float:dist=get_distance_f(a,p);if(dist>180.0||dist<1.0)continue;
for(new j;j<3;j++)delta[j]=(p[j]-a[j])/dist;
new Float:dot=delta[0]*f[0]+delta[1]*f[1]+delta[2]*f[2];if(dot<0.35||!VxLOS(a,v,id))continue;
VxDamage(v,id,id,250.0);
}
}
VxAlt(id,weapon,sw)
{
new clip=get_member(weapon,m_Weapon_iClip);
if(get_member(weapon,m_Weapon_fInReload)||Float:get_member(id,m_flNextAttack)>0.0)return;
if(clip<VX_ALT_COST[sw])
{
set_member(weapon,m_Weapon_flNextPrimaryAttack,0.4);Chat(id,"VX_NOAMMO",VX_ALT_COST[sw]);return;
}
new Float:a[3],Float:f[3],Float:b[3],Float:angle[3];VxAim(id,a,f,b,angle);
if(sw==2||sw==6)
if(!VxSpawn(id,sw,a,f,angle)){set_member(weapon,m_Weapon_flNextPrimaryAttack,0.4);Chat(id,"VX_BUSY");return;}
if(!g_bUnlClip[id])set_member(weapon,m_Weapon_iClip,clip-VX_ALT_COST[sw]);
set_member(weapon,m_Weapon_flNextPrimaryAttack,VX_ALT_WAIT[sw]);
set_member(weapon,m_Weapon_flNextSecondaryAttack,VX_ALT_WAIT[sw]);set_member(weapon,m_Weapon_flTimeWeaponIdle,floatmax(0.75,VX_ALT_WAIT[sw]));
VxAnim(id,weapon,V50_ALT[sw]);if(!V51_ALT_EVENT[sw]) VxSound(id,sw,5);set_entvar(id,var_effects,get_entvar(id,var_effects)|EF_MUZZLEFLASH);
if(sw==0||sw==1||sw==5||sw==7)VxRay(id,sw,a,f,b);
else if(sw==3)VxRoar(id,a,f);
}
public cmd_ArsenalGive(id,level,cid)
{
if(!cmd_access(id,level,cid,3))return PLUGIN_HANDLED;
new arg[32],idx[8];read_argv(1,arg,charsmax(arg));read_argv(2,idx,charsmax(idx));new sw=str_to_num(idx);
new target=cmd_target(id,arg,CMDTARGET_ALLOW_SELF|CMDTARGET_ONLY_ALIVE);if(!target)return PLUGIN_HANDLED;
if(!(0<=sw<NUM_SPECIAL)||g_bZombie[target]||ModeOf(target)>=0){console_print(id,"[Arsenal8] Living normal human, slot 0..7 required.");return PLUGIN_HANDLED;}
console_print(id,"[Arsenal8] slot=%d give=%s",sw,VxGive(target,sw)?"OK":"FAILED");return PLUGIN_HANDLED;
}
SpecialIndex(id, WeaponIdType:wid)
{
if(id<1 || id>g_iMax || !is_user_alive(id) || g_bZombie[id]) return -1;
new sw=VxIndex(get_member(id,m_pActiveItem));return sw>=0 && SW_BASE_ID[sw]==wid?sw:-1;
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
public rg_HasRestrictItem(id, ItemID:item, ItemRestType:type)
{
if (!g_bZombie[id])
{
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
public rg_DefaultDeploy(weapon, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal)
{
new id = get_member(weapon, m_pPlayer);
if (!(1 <= id <= g_iMax))
return HC_CONTINUE;
new WeaponIdType:wid = get_member(weapon, m_iId);
if (g_bZombie[id])
{
if (wid == WEAPON_HEGRENADE) {
if (VxModelOk(g_szInfV531)) SetHookChainArg(2, ATYPE_STRING, g_szInfV531);
if (VxModelOk(g_szInfP531)) SetHookChainArg(3, ATYPE_STRING, g_szInfP531);
return HC_CONTINUE;
}
if (wid != WEAPON_KNIFE)
return HC_CONTINUE;
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
if (CommunityExtra(id) && VxIndex(weapon)<0) return HC_CONTINUE;
if (wid == WEAPON_KNIFE && g_iCommunitySel[id][1] >= 5 && g_iCommunitySel[id][1] <= KN_TOTAL && KnifeReady47(g_iCommunitySel[id][1]-1) && CommunityAlive(id)
&& !ZcCall(ZC_HEV, ZCOP_has,id) && !ZcCall(ZC_JETPACK, ZCOP_has,id)) {
SetHookChainArg(2,ATYPE_STRING,g_szMkV[g_iCommunitySel[id][1]-5]);
SetHookChainArg(3,ATYPE_STRING,g_szMkP[g_iCommunitySel[id][1]-5]);
return HC_CONTINUE;
}
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
new sw = VxIndex(weapon);
if(sw<0) sw=SpecialIndex(id,wid);
if (sw >= 0)
{
g_iSpecW[id]=(1<<sw);SetHookChainArg(4,ATYPE_INTEGER,V50_DRAW[sw]);SetHookChainArg(6,ATYPE_INTEGER,0);
if (g_szSWView[sw][0])
SetHookChainArg(2, ATYPE_STRING, g_szSWView[sw]);
if (g_szSWPlayer[sw][0])
SetHookChainArg(3, ATYPE_STRING, g_szSWPlayer[sw]);
return HC_CONTINUE;
}
new w = _:wid;
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
public fw_PrimaryAttackPost(weapon)
{
new id = get_member(weapon, m_pPlayer);
if (!(1 <= id <= g_iMax) || !is_user_alive(id) || g_bZombie[id])
return HAM_IGNORED;
new WeaponIdType:wid = get_member(weapon, m_iId);
new bool:arsenalShot = false;
new arsenal = VxIndex(weapon);
if (arsenal >= 0)
{
if (g_bVxAltHandled[id]) { g_bVxAltHandled[id] = false; return HAM_IGNORED; }
arsenalShot = bool:(g_iVxAttack[id] == weapon && g_iVxClip[id] > 0
&& get_member(weapon, m_Weapon_iClip) < g_iVxClip[id]);
g_iVxAttack[id] = 0;
if (!arsenalShot) return HAM_IGNORED;
}
if (g_bUnlClip[id])
{
new clip = (arsenal >= 0) ? SW_CLIP[arsenal] : rg_get_weapon_info(wid, WI_GUN_CLIP_SIZE);
if (clip > 0)
set_member(weapon, m_Weapon_iClip, clip);
}
new mm = ModeOf(id), ms = (mm >= 0) ? ModeSlot(mm, wid) : -1;
if (ms >= 0)
{
new key[24];
formatex(key, charsmax(key), "%s_W%d_SOUND", MW_KEY[mm], ms + 1);
EmitKey(id, key, CHAN_WEAPON);
return HAM_IGNORED;
}
new sw = SpecialIndex(id, wid);
if (sw < 0)
return HAM_IGNORED;
new Float:minReady = floatclamp(SW_RATE[sw], 0.05, 5.0);
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
if (arsenal >= 0)
{
if (arsenalShot) VxShot(id, arsenal);
return HAM_IGNORED;
}
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
new g_sprGlow531, g_sprHot531, g_sprSteam531, g_sprShock531, g_iDecScorch531 = -1, g_pNadeFx531;
NadeFxPrecache531()
{
g_sprGlow531  = VxPcStock531("sprites/glow01.spr");
g_sprHot531   = VxPcStock531("sprites/hotglow.spr");
g_sprSteam531 = VxPcStock531("sprites/steam1.spr");
g_sprShock531 = VxPcStock531("sprites/shockwave.spr");
new path[96];
for (new i = 0; i < FX532_TOTAL; i++)
{
formatex(path, charsmax(path), "sprites/vexmira/fx532/%s.spr", FX532_NAME[i]);
g_iFx532[i] = VxPcStock531(path);
if (!g_iFx532[i]) log_amx("[Vexmira] 5.3.2 efekt sprite'i eksik: %s (sunucuya yukleyin; o efekt eski haliyle calisir)", path);
}
}
stock bool:Fx532Ok() { return g_iFx532[X_FIREBALL] && g_iFx532[X_FROSTBURST] && g_iFx532[X_FLARE] && g_iFx532[X_TOXICBURST] && g_iFx532[X_RING] && g_iFx532[X_SMOKE]; }
VxPcStock531(const path[])
{
if (!file_exists(path, true)) return 0;
if (contain(path, "/fx532/") != -1 && max(g_iTotMdl, g_iPcMdl) >= 430) { log_amx("[AssetGuard] model listesi dolu, efekt sprite'i atlandi: %s", path); return 0; }
new idx = (!VxPcOk531()) ? 0 : precache_model(path);
if (idx > g_iPcMdl) g_iPcMdl = idx;
return idx;
}
stock NxBegin(const Float:o[3]) { engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, o, 0); }
stock NxCoord(const Float:o[3], Float:dz = 0.0) { engfunc(EngFunc_WriteCoord, o[0]); engfunc(EngFunc_WriteCoord, o[1]); engfunc(EngFunc_WriteCoord, o[2] + dz); }
stock NxRing(const Float:o[3], spr, r, g, b, radius, width, life, bright, Float:dz = 0.0)
{
if (get_cvar_num("vex_dbg_nxmask") & 1) return;
if (spr <= 0) return;
NxBegin(o); write_byte(TE_BEAMCYLINDER); NxCoord(o, dz);
engfunc(EngFunc_WriteCoord, o[0]); engfunc(EngFunc_WriteCoord, o[1]); engfunc(EngFunc_WriteCoord, o[2] + dz + float(radius));
write_short(spr); write_byte(0); write_byte(0); write_byte(life); write_byte(width); write_byte(0);
write_byte(r); write_byte(g); write_byte(b); write_byte(bright); write_byte(0); message_end();
}
stock NxExplo(const Float:o[3], spr, scale, rate, Float:dz = 0.0)
{
if (get_cvar_num("vex_dbg_nxmask") & 2) return;
if (spr <= 0) return;
NxBegin(o); write_byte(TE_EXPLOSION); NxCoord(o, dz); write_short(spr); write_byte(scale); write_byte(rate);
write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES); message_end();
}
stock NxSprite(const Float:o[3], spr, scale, bright, Float:dz = 0.0)
{
if (get_cvar_num("vex_dbg_nxmask") & 4) return;
if (spr <= 0) return;
NxBegin(o); write_byte(TE_SPRITE); NxCoord(o, dz); write_short(spr); write_byte(scale); write_byte(bright); message_end();
}
stock NxLight(const Float:o[3], r, g, b, radius, life, decay)
{
if (get_cvar_num("vex_dbg_nxmask") & 8) return;
NxBegin(o); write_byte(TE_DLIGHT); NxCoord(o, 8.0); write_byte(radius); write_byte(r); write_byte(g); write_byte(b);
write_byte(life); write_byte(decay); message_end();
}
stock NxField(const Float:o[3], spr, radius, count, flags, life)
{
if (get_cvar_num("vex_dbg_nxmask") & 16) return;
if (spr <= 0) return;
NxBegin(o); write_byte(TE_FIREFIELD); NxCoord(o, 4.0); write_short(radius); write_short(spr);
write_byte(count); write_byte(flags); write_byte(life); message_end();
}
stock NxShower(const Float:o[3], spr, count, life, scale, speed, rnd, Float:up = 40.0)
{
if (get_cvar_num("vex_dbg_nxmask") & 32) return;
if (spr <= 0) return;
NxBegin(o); write_byte(TE_SPRITETRAIL); NxCoord(o, 4.0); NxCoord(o, up);
write_short(spr); write_byte(count); write_byte(life); write_byte(scale); write_byte(speed); write_byte(rnd); message_end();
}
stock NxStreak(const Float:o[3], color, count, speed, rnd)
{
if (get_cvar_num("vex_dbg_nxmask") & 64) return;
NxBegin(o); write_byte(TE_STREAK_SPLASH); NxCoord(o, 4.0);
engfunc(EngFunc_WriteCoord, 0.0); engfunc(EngFunc_WriteCoord, 0.0); engfunc(EngFunc_WriteCoord, 1.0);
write_byte(color); write_short(count); write_short(speed); write_short(rnd); message_end();
}
stock NxSmoke(const Float:o[3], spr, scale, fps, Float:dz = 0.0)
{
if (get_cvar_num("vex_dbg_nxmask") & 128) return;
if (spr <= 0) return;
NxBegin(o); write_byte(TE_SMOKE); NxCoord(o, dz); write_short(spr); write_byte(scale); write_byte(fps); message_end();
}
stock NxDecal(const Float:o[3], decal)
{
if (get_cvar_num("vex_dbg_nxmask") & 256) return;
if (decal < 0) return;
NxBegin(o); write_byte(TE_WORLDDECAL); NxCoord(o, -2.0); write_byte(decal); message_end();
}
NxShakeNear(const Float:o[3], Float:radius, amp)
{
new Float:po[3];
for (new p = 1; p <= g_iMax; p++)
{
if (!is_user_alive(p) || is_user_bot(p) || (g_iSet[p] & SET_NO_FX)) continue;
get_entvar(p, var_origin, po);
new Float:d = get_distance_f(o, po);
if (d > radius) continue;
new a = floatround(float(amp) * (1.0 - d / radius)) + 1;
message_begin(MSG_ONE_UNRELIABLE, g_msgShake, _, p);
write_short(a << 12); write_short(1 << 12); write_short(10 << 12); message_end();
}
}
NxGround(const Float:o[3], Float:out[3])
{
new Float:e[3]; out = o; e = o; e[2] -= 64.0;
new tr = create_tr2();
engfunc(EngFunc_TraceLine, o, e, IGNORE_MONSTERS, 0, tr);
new Float:fr; get_tr2(tr, TR_flFraction, fr);
if (fr < 1.0) get_tr2(tr, TR_vecEndPos, out);
free_tr2(tr);
out[2] += 2.0;
}
NxStage(const Float:o[3], kind, stage, Float:delay)
{
new data[5];
data[0] = floatround(o[0]); data[1] = floatround(o[1]); data[2] = floatround(o[2]); data[3] = kind; data[4] = stage;
set_task(delay, "task_NadeStage531", 0, data, sizeof data);
}
public task_BossAftershock531(const d[])
{
new Float:o[3]; o[0] = float(d[0]); o[1] = float(d[1]); o[2] = float(d[2]) - 30.0;
NxRing(o, g_sprShock531 ? g_sprShock531 : g_sprRing, d[3], d[4], d[5], 520, 36, 5, 230, 4.0);
NxRing(o, g_sprRing, 255, 255, 255, 260, 12, 4, 200, 2.0);
NxLight(o, d[3], d[4], d[5], 40, 8, 30);
NxStreak(o, 0x6B, 60, 260, 200);
NxShakeNear(o, 900.0, 7);
}
public task_NadeStage531(const data[])
{
new Float:o[3]; o[0] = float(data[0]); o[1] = float(data[1]); o[2] = float(data[2]);
NadeFxStage531(o, data[3], data[4]);
}
NadeFxEpic531(const Float:origin[3], kind)
{
if (!get_pcvar_num(g_pNadeFx531)) return false;
new Float:o[3]; NxGround(origin, o);
NadeFxStage531(o, kind, 0);
NxStage(o, kind, 1, 0.15);
NxStage(o, kind, 2, 0.45);
NxStage(o, kind, 3, 0.9);
NxStage(o, kind, 4, 1.4);
return true;
}
NadeFxStage531(const Float:o[3], kind, stage)
{
if (Fx532Ok()) { NadeFx532(o, kind, stage); return; }
NadeFxOld531(o, kind, stage);
}
NadeFx532(const Float:o[3], kind, stage)
{
new ring = g_iFx532[X_RING];
switch (kind)
{
case 0:
{
switch (stage)
{
case 0:
{
NxSprite(o, g_iFx532[X_GLOW], 30, 255, 30.0);
NxExplo(o, g_iFx532[X_FIREBALL], 26, 22, 34.0);
NxExplo(o, g_iFx532[X_FIREBALL], 18, 26, 12.0);
NxLight(o, 255, 130, 40, 48, 12, 30);
NxRing(o, ring, 255, 120, 30, 380, 60, 5, 210, 6.0);
NxRing(o, ring, 255, 230, 160, 230, 26, 3, 255, 3.0);
NxShower(o, g_iFx532[X_EMBER], 30, 14, 3, 40, 26);
NxStreak(o, 0x6B, 50, 220, 160);
NxShakeNear(o, 420.0, 9);
if (g_iDecScorch531 < 0) g_iDecScorch531 = engfunc(EngFunc_DecalIndex, "{scorch1");
NxDecal(o, g_iDecScorch531);
}
case 1:
{
NxExplo(o, g_iFx532[X_FIREBALL], 20, 16, 78.0);
NxField(o, g_iFx532[X_FLAME], 120, 16, TEFIRE_ADD532 | TEFIRE_FLAG_LOOP, 34);
NxRing(o, ring, 255, 80, 10, 170, 20, 6, 170, 2.0);
}
case 2: { NxSmoke(o, g_iFx532[X_SMOKE], 34, 10, 60.0); NxShower(o, g_iFx532[X_EMBER], 14, 18, 2, 22, 20, 90.0); NxLight(o, 255, 100, 25, 32, 14, 12); }
case 3: { NxField(o, g_iFx532[X_FLAME], 90, 10, TEFIRE_ADD532 | TEFIRE_FLAG_LOOP, 26); NxSmoke(o, g_iFx532[X_SMOKE], 44, 8, 100.0); }
case 4: { NxSmoke(o, g_iFx532[X_SMOKE], 52, 6, 140.0); NxLight(o, 200, 70, 20, 20, 10, 16); }
}
}
case 1:
{
switch (stage)
{
case 0:
{
NxSprite(o, g_iFx532[X_GLOW], 30, 255, 30.0);
NxExplo(o, g_iFx532[X_FROSTBURST], 28, 22, 30.0);
NxLight(o, 140, 210, 255, 52, 12, 24);
NxRing(o, ring, 110, 210, 255, 400, 64, 5, 220, 6.0);
NxRing(o, ring, 230, 250, 255, 250, 24, 3, 255, 3.0);
NxShower(o, g_iFx532[X_SHARD], 34, 14, 4, 48, 30);
NxStreak(o, 0x6F, 40, 200, 160);
NxShakeNear(o, 360.0, 5);
}
case 1:
{
NxField(o, g_iFx532[X_FROSTMIST], 150, 18, TEFIRE_ADD532 | TEFIRE_FLAG_SOMEFLOAT | TEFIRE_FLAG_LOOP, 30);
NxExplo(o, g_iFx532[X_FROSTBURST], 16, 18, 60.0);
NxRing(o, ring, 60, 160, 255, 300, 34, 7, 150, 1.0);
}
case 2: { NxShower(o, g_iFx532[X_SHARD], 16, 18, 2, 18, 24, 120.0); NxLight(o, 90, 180, 255, 34, 16, 8); }
case 3: { NxField(o, g_iFx532[X_FROSTMIST], 120, 12, TEFIRE_ADD532 | TEFIRE_FLAG_SOMEFLOAT | TEFIRE_FLAG_LOOP, 22); }
case 4: { NxSprite(o, g_iFx532[X_GLOW], 16, 120, 10.0); }
}
}
case 2:
{
switch (stage)
{
case 0:
{
NxLight(o, 255, 240, 220, 60, 8, 36);
NxExplo(o, g_iFx532[X_FLARE], 22, 14, 18.0);
NxSprite(o, g_iFx532[X_GLOW], 24, 255, 18.0);
NxRing(o, ring, 255, 120, 90, 240, 30, 4, 220, 3.0);
NxShower(o, g_iFx532[X_SPARK], 34, 10, 2, 64, 22, 30.0);
NxStreak(o, 0x6B, 70, 320, 120);
}
case 1: { NxExplo(o, g_iFx532[X_FLARE], 16, 12, 18.0); NxShower(o, g_iFx532[X_SPARK], 20, 10, 2, 50, 18, 30.0); }
case 2: { NxExplo(o, g_iFx532[X_FLARE], 14, 12, 18.0); NxStreak(o, 0x6B, 30, 240, 90); }
case 3: { NxShower(o, g_iFx532[X_SPARK], 14, 10, 2, 40, 16, 30.0); }
case 4: { NxSprite(o, g_iFx532[X_GLOW], 14, 160, 18.0); }
}
}
case 3:
{
switch (stage)
{
case 0:
{
NxExplo(o, g_iFx532[X_TOXICBURST], 26, 20, 28.0);
NxLight(o, 60, 255, 40, 46, 12, 24);
NxRing(o, ring, 40, 255, 40, 340, 56, 5, 210, 6.0);
NxShower(o, g_iFx532[X_TOXICMIST], 18, 14, 3, 36, 26);
NxShakeNear(o, 320.0, 5);
}
case 1: { NxField(o, g_iFx532[X_TOXICMIST], 140, 16, TEFIRE_ADD532 | TEFIRE_FLAG_SOMEFLOAT | TEFIRE_FLAG_LOOP, 28); }
case 2: { NxExplo(o, g_iFx532[X_TOXICBURST], 14, 16, 50.0); NxLight(o, 40, 200, 30, 30, 16, 10); }
case 3: { NxRing(o, ring, 80, 255, 60, 200, 22, 6, 140, 2.0); }
case 4: { NxField(o, g_iFx532[X_TOXICMIST], 100, 10, TEFIRE_ADD532 | TEFIRE_FLAG_SOMEFLOAT | TEFIRE_FLAG_LOOP, 18); }
}
}
}
}
NadeFxOld531(const Float:o[3], kind, stage)
{
new ring = g_sprShock531 ? g_sprShock531 : g_sprRing;
if (stage) return;
switch (kind)
{
case 0: { NxExplo(o, g_sprFx[FXS_EXFIRE] ? g_sprFx[FXS_EXFIRE] : g_sprExplode, 26, 14, 26.0); NxLight(o, 255, 120, 30, 46, 10, 30); NxRing(o, ring, 255, 110, 20, 340, 40, 4, 220, 8.0); NxStreak(o, 0x6B, 60, 220, 180); }
case 1: { NxExplo(o, g_sprFx[FXS_EXICE] ? g_sprFx[FXS_EXICE] : g_sprExplode, 26, 14, 26.0); NxLight(o, 140, 210, 255, 50, 12, 24); NxRing(o, ring, 120, 220, 255, 360, 46, 4, 230, 8.0); NxStreak(o, 0x6F, 50, 200, 160); }
case 2: { NxLight(o, 255, 240, 220, 60, 6, 40); NxRing(o, g_sprRing, 255, 70, 60, 200, 20, 4, 230, 4.0); NxStreak(o, 0x6B, 90, 320, 120); }
case 3: { NxExplo(o, g_sprFx[FXS_EXTOXIC] ? g_sprFx[FXS_EXTOXIC] : g_sprExplode, 26, 14, 24.0); NxLight(o, 60, 255, 40, 44, 12, 24); NxRing(o, ring, 40, 255, 40, 320, 40, 4, 220, 8.0); }
}
}
public rg_ExplodeHe(ent, tracehandle, bits)
{
NadeCleanup(ent);
new type = get_entvar(ent, var_impulse);
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
if (!NadeFxEpic531(o, 0))
{
if (!FxExploEl(o, EL_FIRE, 24, 16))
FxExplosion(o);
FxRing(o, 255, 80, 0, 300);
FxSprite(o,g_sprFire,18,200);
FxLight(o,255,100,40,22,6,32);
}
EmitKey(ent,"NADE_FIRE",CHAN_WEAPON,ATTN_NORM);Radio52(7);
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
if (!NadeFxEpic531(o, 3))
{
FxRing(o, 0, 255, 0, 300);
FxLight(o, 0, 255, 0, 40, 15, 20);
if (!FxExploEl(o, EL_TOXIC, 24, 14))
FxSprite(o, g_sprSmoke, 30, 200);
}
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
if (!NadeFxEpic531(o, 1))
{
FxRing(o, 0, 150, 255, 300);
FxRing(o, 200, 240, 255, 200);
FxExploEl(o, EL_ICE, 24, 14);
FxDisk(o, 0, 120, 255, 260, 5);
FxStreak(o, 7, 60, 300);
FxLight(o, 0, 150, 255, 40, 15, 20);
}
EmitKey(ent,"NADE_FROST",CHAN_WEAPON,ATTN_NORM);Radio52(8);
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
NadeFxEpic531(o, 2);
if(g_iEpicFlare) FxSpr(o,g_iEpicFlare,7,190,12.0);
EpicCue(0,"flare");
FxLight(o, 255, 60, 60, 50, 12, 2);
FxRing(o, 255, 60, 60, 120);
set_entvar(ent, var_flags, FL_KILLME);
return HC_SUPERCEDE;
}
GiveNadeStack(id, const ent[], WeaponIdType:wid)
{
new cur = rg_get_user_bpammo(id, wid);
if (cur <= 0)
rg_give_item(id, ent);
else
rg_set_user_bpammo(id, wid, cur + 1);
}
ShowPrimaryMenu(id)
{
new title[320], item[64];
new hsub[128];
formatex(hsub, charsmax(hsub), "%L", id, "MENU_GUNS_SUB");
VexHead(id, title, charsmax(title), "MENU_PRIMARY", hsub);
new menu = VexMenuCreate(title, "menu_primary_handler");
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
#define LM_CLASS     "vex_lasermine"
#define BEAM_MARK_LM 7776
new bool:g_bHm538, Float:g_fHmEnd538[33], g_iHmW538[33];
new g_iLmRepair538;
#define BEAM_MARK_NADE 7777
#define BEAM_MARK_DROP 7778
new Float:g_fLmCd[33], Float:g_fPlantPos[33][3], Float:g_fLmMsg[33];
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
// 5.3.9d vex_model_build (= vex_mode_build): finds every model in vexmira.cfg by itself and creates all
// generated files (unique player model copies + giant boss copies) at once. Restart afterwards so the
// panel FastDL picks them up before players join.
new Trie:g_tMb539;
ModelBuildOne539(const name[], &made, &same)
{
if (!name[0] || TrieKeyExists(g_tMb539, name)) return;
TrieSetCell(g_tMb539, name, 1);
new src[128]; formatex(src, charsmax(src), "models/player/%s/%s.mdl", name, name);
if (!file_exists(src, true)) { server_print("[ModelBuild] YOK: %s", src); return; }
new u[48]; UniqModel539(name, u, charsmax(u));
if (equal(u, name)) { same++; server_print("[ModelBuild] %s -> kopya yok (T dosyali / standart / kapali), orijinali kullanilir", name); }
else { made++; server_print("[ModelBuild] %s -> models/player/%s/%s.mdl", name, u, u); }
}
public srv_ModelBuild539()
{
new made, same, list[512], tmp[32], pos, key[24], nm[32];
g_tMb539 = TrieCreate();
copy(list, charsmax(list), GetResString("HUMAN_MODELS", "")); add(list, charsmax(list), " "); add(list, charsmax(list), GetResString("HUMAN_MODEL", ""));
while ((pos = argparse(list, pos, tmp, charsmax(tmp))) != -1) if (tmp[0]) ModelBuildOne539(tmp, made, same);
static const KEYS[][] = { "VIP_MODEL", "ADMIN_MODEL", "SURVIVOR_MODEL", "SNIPER_MODEL", "NEMESIS_MODEL", "ASSASSIN_MODEL" };
for (new i = 0; i < sizeof KEYS; i++) if (TrieGetString(g_tRes, KEYS[i], nm, charsmax(nm)) && nm[0]) ModelBuildOne539(nm, made, same);
for (new i = 0; i < NUM_CLASSES; i++) { formatex(key, charsmax(key), "Z%d_MODEL", i); if (TrieGetString(g_tRes, key, nm, charsmax(nm)) && nm[0]) ModelBuildOne539(nm, made, same); }
for (new i = 0; i < NUM_BOSSES; i++) { formatex(key, charsmax(key), "B%d_MODEL", i); if (TrieGetString(g_tRes, key, nm, charsmax(nm)) && nm[0]) ModelBuildOne539(nm, made, same); }
TrieDestroy(g_tMb539);
server_print("[ModelBuild] oyuncu modelleri: %d kopya hazir, %d model oldugu gibi kullaniliyor", made, same);
if (!equali(GetResString("BOSS_GIANT", "file"), "off") && !equali(GetResString("BOSS_GIANT", "file"), "clone")) srv_GiantBuild533();
server_print("[ModelBuild] BITTI. Simdi sunucuyu restart et: panel yeni dosyalari FastDL'e kopyalar.");
log_amx("[ModelBuild] %d oyuncu modeli kopyasi + dev bosslar hazirlandi", made);
return PLUGIN_HANDLED;
}
public srv_GiantBuild533()
{
new key[24], nm[32], out[48], ok, all;
for (new i = 0; i < NUM_BOSSES; i++)
{
formatex(key, charsmax(key), "B%d_MODEL", i);
if (!TrieGetString(g_tRes, key, nm, charsmax(nm)) || !nm[0]) continue;
all++;
if (GmBossGiant(nm, out, charsmax(out))) { ok++; server_print("[GiantBoss] %s -> models/player/%s/%s.mdl", nm, out, out); }
else server_print("[GiantBoss] %s: olusturulamadi (model yok / klasor izni)", nm);
}
server_print("[GiantBoss] %d / %d dev boss modeli hazir. Bu klasorleri FastDL'e de kopyala.", ok, all);
return PLUGIN_HANDLED;
}
public srv_DbgSlim534()
{
new a[160], b[160], t[8]; read_argv(1, a, charsmax(a)); read_argv(2, b, charsmax(b)); read_argv(3, t, charsmax(t));
new bool:ok = GsSlim(a, b, str_to_num(t));
server_print("[GiantBoss] slim %s -> %s : %d (%d -> %d bytes)", a, b, ok, file_size(a, 0), ok ? file_size(b, 0) : 0);
return PLUGIN_HANDLED;
}
public srv_DbgGiant()
{
new nm[32], out[48]; read_argv(1, nm, charsmax(nm));
new bool:ok = GmBossGiant(nm, out, charsmax(out));
server_print("[GiantBoss] test %s -> %d %s", nm, ok, out);
return PLUGIN_HANDLED;
}
public srv_DbgLmWall532()
{
new a[16], Float:o[3], Float:yaw, zm;
for (new k = 0; k < 3; k++) { read_argv(1 + k, a, charsmax(a)); o[k] = str_to_float(a); }
read_argv(4, a, charsmax(a)); yaw = str_to_float(a); read_argv(5, a, charsmax(a)); zm = str_to_num(a);
new owner; for (new p = 1; p <= g_iMax; p++) if (is_user_alive(p)) { owner = p; break; }
if (!owner) return PLUGIN_HANDLED;
new Float:e[3]; e[0] = o[0] + floatcos(yaw, degrees) * 800.0; e[1] = o[1] + floatsin(yaw, degrees) * 800.0; e[2] = o[2];
new tr = create_tr2(); engfunc(EngFunc_TraceLine, o, e, IGNORE_MONSTERS, 0, tr);
new Float:fr, Float:hit[3], Float:n[3]; get_tr2(tr, TR_flFraction, fr); get_tr2(tr, TR_vecEndPos, hit); get_tr2(tr, TR_vecPlaneNormal, n); free_tr2(tr);
if (fr >= 1.0) { server_print("[lmwall] duvar yok"); return PLUGIN_HANDLED; }
new old = g_bZombie[owner]; g_bZombie[owner] = zm ? true : false;
new ent = CreateMine(owner, hit, n);
g_bZombie[owner] = old;
server_print("[lmwall] mine %d at %.0f %.0f %.0f normal %.2f %.2f %.2f dist %.0f", ent, hit[0], hit[1], hit[2], n[0], n[1], n[2], fr * 800.0);
log_amx("[lmwall] mine %d at %.0f %.0f %.0f normal %.2f %.2f %.2f dist %.0f", ent, hit[0], hit[1], hit[2], n[0], n[1], n[2], fr * 800.0);
return PLUGIN_HANDLED;
}
public srv_DbgCard532()
{
new a[8]; read_argv(1, a, charsmax(a)); new note = str_to_num(a); read_argv(2, a, charsmax(a)); new arg = str_to_num(a);
for (new p = 1; p <= g_iMax; p++) if (is_user_connected(p) && !is_user_bot(p)) log_amx("[Vexmira] debug kart %d -> #%d : %d", note, p, CsoNotify(p, note, arg));
read_argv(3, a, charsmax(a));
if (equal(a, "shot")) { new d[2]; d[0] = note; d[1] = arg; set_task(0.35, "task_DbgCardShot533", 0, d, 2); }
return PLUGIN_HANDLED;
}
public task_DbgCardShot533(const d[])
{
for (new p = 1; p <= g_iMax; p++) if (is_user_connected(p) && !is_user_bot(p)) client_cmd(p, "screenshot scrshots/kart_%02d_%02d.png", d[0], d[1]);
}
public srv_DbgRadio532()
{
new a[8]; read_argv(1, a, charsmax(a)); g_fRadioBusy52 = 0.0; new i = str_to_num(a); if (i >= 0 && i < 15) g_fRadioAt52[i] = 0.0; Radio52(i);
return PLUGIN_HANDLED;
}
public srv_DbgNadeFx()
{
new a[16], Float:o[3];
read_argv(1, a, charsmax(a)); new kind = str_to_num(a);
for (new k = 0; k < 3; k++) { read_argv(2 + k, a, charsmax(a)); o[k] = str_to_float(a); }
read_argv(2, a, charsmax(a));
if (equal(a, "aim"))
{
for (new p = 1; p <= g_iMax; p++)
{
if (!is_user_alive(p) || is_user_bot(p)) continue;
new Float:st[3], Float:vo[3], Float:an[3], Float:fw[3], Float:en[3];
get_entvar(p, var_origin, st); get_entvar(p, var_view_ofs, vo); xs_vec_add(st, vo, st);
get_entvar(p, var_v_angle, an); an[0] = floatmax(an[0], 10.0); angle_vector(an, ANGLEVECTOR_FORWARD, fw);
xs_vec_mul_scalar(fw, 260.0, en); xs_vec_add(st, en, en);
new tr = create_tr2(); engfunc(EngFunc_TraceLine, st, en, IGNORE_MONSTERS, p, tr); get_tr2(tr, TR_vecEndPos, o); free_tr2(tr);
break;
}
}
new data[4]; data[0] = kind; data[1] = floatround(o[0]); data[2] = floatround(o[1]); data[3] = floatround(o[2]);
read_argv(5, a, charsmax(a)); new rep = max(1, str_to_num(a));
for (new r = 0; r < rep; r++) set_task(0.1 + float(r) * 2.5, "task_DbgNadeFx", 0, data, sizeof data);
return PLUGIN_HANDLED;
}
public task_DbgNadeFx(const d[])
{
new Float:o[3]; o[0] = float(d[1]); o[1] = float(d[2]); o[2] = float(d[3]);
NadeFxEpic531(o, d[0]);
}
public srv_DbgBuy()
{
new a[8], sw[32], who[8]; read_argv(1, a, charsmax(a)); read_argv(2, sw, charsmax(sw)); read_argv(3, who, charsmax(who));
new it = str_to_num(a), n;
if (a[0] == 'j' || a[0] == 'k' || a[0] == 's' || a[0] == 'w')
{
for (new p = 1; p <= g_iMax; p++)
{
if (!is_user_alive(p) || (equal(who, "real") && is_user_bot(p))) continue;
g_iAP[p] += 5000; g_iVC[p] += 5000;
if (a[0] == 'j') CommunityBuyGear(p, 0);
else if (a[0] == 'k') CommunityCoinSelect(p, 1, str_to_num(a[1]));
else if (a[0] == 's') CommunityCoinSelect(p, 0, str_to_num(a[1]));
else CommunityBuyWeapon(p, str_to_num(a[1]));
if (sw[0]) engclient_cmd(p, sw);
n++;
}
log_amx("[Vexmira] DBGBUY gear %s players=%d", a, n);
return PLUGIN_HANDLED;
}
if (equal(a, "z"))
{
for (new p = 1; p <= g_iMax; p++) if (is_user_alive(p) && !is_user_bot(p) && !g_bZombie[p]) { MakeZombie(p); n++; }
log_amx("[Vexmira] DBGBUY zombie humans=%d", n);
return PLUGIN_HANDLED;
}
for (new p = 1; p <= g_iMax; p++)
{
if (!is_user_alive(p) || ITEM_TEAM[it] != (g_bZombie[p] ? 1 : 0)) continue;
if (equal(who, "real") && is_user_bot(p)) continue;
g_iAP[p] += 5000; g_iLevel[p] = max(g_iLevel[p], 99);
BuyItem(p, it); n++;
if (sw[0]) engclient_cmd(p, sw);
}
log_amx("[Vexmira] DBGBUY item=%d buyers=%d", it, n);
return PLUGIN_HANDLED;
}
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
new weapon = VxGive(id, i);
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
g_bVxGiving[id] = false; g_iVxAttack[id] = 0; g_iVxClip[id] = 0; g_iVxShots[id] = 0; g_bVxRightHeld[id] = false; g_bVxAltHandled[id] = false;
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
MaxMines(id)
{
if (g_bZombie[id]) return 1;
new m = IsVip(id) ? get_pcvar_num(g_pLmMaxVip) : get_pcvar_num(g_pLmMax);
if (g_iJob[id] == JOB_ENGINEER)
m++;
return max(0, m);
}
RoundMines(id)
{
if(g_bZombie[id]) return 1;
new m = IsVip(id) ? get_pcvar_num(g_pLmPerRoundVip) : get_pcvar_num(g_pLmPerRound);
if (g_iJob[id] == JOB_ENGINEER)
m++;
return clamp(m, 0, 20);
}
GiveRoundMines(id)
{
if (g_bLmGiven[id] || !LasersAllowed())
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
public cmd_lm_menu(id)
{
ShowMineMenu(id);
return PLUGIN_HANDLED;
}
public cmd_radio3(id)
{
if (!get_pcvar_num(g_pLmEnable) || !is_user_alive(id))
return PLUGIN_CONTINUE;
new mine = AimedMine(id, get_pcvar_float(g_pLmTakeRange));
if (!mine)
return PLUGIN_CONTINUE;
if (get_entvar(mine, var_iuser1) != id || get_entvar(mine,var_impulse)!=get_user_userid(id))
return PLUGIN_CONTINUE;
cmd_lm_take(id);
return PLUGIN_HANDLED;
}
public cmd_lm_release(id)
{
if (g_iPlantAction[id] == 1)
CancelPlant(id);
return PLUGIN_HANDLED;
}
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
new Float:now = get_gametime();
if (now < g_fLmMsg[id])
return;
g_fLmMsg[id] = now + 1.0;
Chat(id, key, val);
PlayKey(id, "LM_DENY");
}
public cmd_lm_plant(id)
{
if (!is_user_alive(id) || g_iPlantAction[id])
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
if(hitDistance<0.0) return PLUGIN_HANDLED;
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
if (!is_user_alive(id) || g_iPlantAction[id])
return PLUGIN_HANDLED;
new mine = AimedMine(id, get_pcvar_float(g_pLmTakeRange));
if (!mine)
{
LmMessage(id, "LM_AIM_MINE");
return PLUGIN_HANDLED;
}
if (get_entvar(mine, var_iuser1) != id || get_entvar(mine,var_impulse)!=get_user_userid(id))
{
LmMessage(id, "LM_NOT_YOURS");
return PLUGIN_HANDLED;
}
get_entvar(id, var_origin, g_fPlantPos[id]);
g_iLmTakeEnt[id] = mine;
g_iPlantAction[id] = 2;
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
public task_LmTakeCheck(tid)
{
new id = tid - TASK_LMTAKE;
if (g_iPlantAction[id] != 2)
{
remove_task(tid);
return;
}
new mine = g_iLmTakeEnt[id];
if (!is_user_alive(id) || !mine || is_nullent(mine))
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
if (!is_user_alive(id) || !action)
return;
new takeEnt = g_iLmTakeEnt[id];
g_iLmTakeEnt[id] = 0;
remove_task(id + TASK_LMTAKE);
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
if(hitDistance<0.0) return;
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
if (owner != id || get_entvar(mine,var_impulse)!=get_user_userid(id))
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
new bool:badTrace = get_tr2(tr, TR_StartSolid) || get_tr2(tr, TR_AllSolid);
free_tr2(tr);
if (badTrace || frac >= 1.0)
return false;
new Float:nLen = floatsqroot(normal[0] * normal[0] + normal[1] * normal[1] + normal[2] * normal[2]);
if (nLen < 0.5)
{
hitDistance = -1.0;
return false;
}
for (new ni = 0; ni < 3; ni++) normal[ni] /= nLen;
endDist = get_distance_f(start, pos);
if (endDist > range + 1.0)
{
hitDistance = endDist;
return false;
}
if (hit > 0)
{
new cls[32];
get_entvar(hit, var_classname, cls, charsmax(cls));
if (!equal(cls, "func_wall") && !equal(cls, "func_illusionary"))
return false;
}
hitDistance = endDist;
if(!EpicLaserEndpoint(id,pos,normal)) { hitDistance=-1.0; return false; }
return true;
}
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
u[0] = 1.0 - n[0] * n[0]; u[1] = -n[0] * n[1]; u[2] = -n[0] * n[2];
d = floatmax(0.001, floatsqroot(u[0] * u[0] + u[1] * u[1] + u[2] * u[2]));
}
for (new i = 0; i < 3; i++)
u[i] /= d;
w[0] = n[1] * u[2] - n[2] * u[1];
w[1] = n[2] * u[0] - n[0] * u[2];
w[2] = n[0] * u[1] - n[1] * u[0];
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
engfunc(EngFunc_VecToAngles, X, ang);
new Float:a0[3], Float:r0[3], Float:u0[3];
a0[0] = -ang[0];
a0[1] = ang[1];
engfunc(EngFunc_MakeVectors, a0);
global_get(glb_v_right, r0);
global_get(glb_v_up, u0);
ang[2] = floatatan2(Z[0] * r0[0] + Z[1] * r0[1] + Z[2] * r0[2], Z[0] * u0[0] + Z[1] * u0[1] + Z[2] * u0[2], degrees);
}
CreateMine(id, const Float:surf[3], const Float:normal[3])
{
if (!(1 <= id <= g_iMax) || !is_user_connected(id))
return 0;
new bool:zombieMine = (g_bZombie[id] != 0);
new model[96];
if (zombieMine)
    copy(model, charsmax(model), g_szMineZombieModel);
else
    copy(model, charsmax(model), g_szMineHumanModel);
if (!model[0] || (zombieMine && g_iMineZombieModelIndex <= 0) || (!zombieMine && g_iMineHumanModelIndex <= 0))
return 0;
new ent = CreateSafe51("info_target");
if (is_nullent(ent))
return 0;
set_entvar(ent, var_classname, LM_CLASS);
new bool:stockTrip = containi(model, "tripmine") != -1;
MinePreset(stockTrip, false, stockTrip);
VxSM(ent, model);
set_entvar(ent, var_body, stockTrip ? 3 : g_iMineBody);
set_entvar(ent, var_sequence, stockTrip ? 7 : g_iMineSeq);
set_entvar(ent, var_skin, stockTrip ? 0 : g_iMineSkin);
set_entvar(ent, var_framerate, 0.0);
if (!stockTrip && g_szMineDeploySeq[0])
AnimByName(ent, g_szMineDeploySeq, g_iMineSeq, 1.0);
else if (!stockTrip && g_szMineSeqName[0])
AnimByName(ent, g_szMineSeqName, g_iMineSeq, 1.0);
set_entvar(ent, var_movetype, MOVETYPE_FLY);
set_entvar(ent, var_solid, SOLID_NOT);
new Float:ang[3], Float:emit[3], Float:pos[3], Float:beamStart[3], Float:mins[3], Float:maxs[3];
MineOrient(id, normal, ang, emit);
for (new i = 0; i < 3; i++)
{
pos[i] = surf[i] + normal[i] * g_fMineOff;
beamStart[i] = pos[i] + emit[i] + normal[i] * 0.5;
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
set_entvar(ent, var_iuser1, id);set_entvar(ent,var_impulse,get_user_userid(id));
set_entvar(ent, var_iuser2, 0);
set_entvar(ent, var_iuser3, 0);
set_entvar(ent, var_iuser4, zombieMine ? 1 : 0);
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
case 1:
{
new owner = get_entvar(ent, var_iuser1);
new c = (owner > 0) ? (owner % sizeof LM_PALETTE) : 0;
r = LM_PALETTE[c][0];
g = LM_PALETTE[c][1];
b = LM_PALETTE[c][2];
return;
}
case 2:
{
new txt[16], cr[4], cg[4], cb[4];
get_pcvar_string(g_pLmColor, txt, charsmax(txt));
parse(txt, cr, charsmax(cr), cg, charsmax(cg), cb, charsmax(cb));
r = clamp(str_to_num(cr), 0, 255);
g = clamp(str_to_num(cg), 0, 255);
b = clamp(str_to_num(cb), 0, 255);
return;
}
case 3:
{
    if (get_entvar(ent, var_iuser4)) { r = 85; g = 255; b = 110; }
    else { r = 35; g = 175; b = 255; }
    return;
}
}
new Float:hp = Float:get_entvar(ent, var_health);
new Float:mx = floatmax(1.0, Float:get_entvar(ent, var_max_health));
new pct = floatround(hp * 100.0 / mx);
if (pct > 60)      { r = 0;   g = 200; b = 255; }
else if (pct > 30) { r = 255; g = 190; b = 0; }
else               { r = 255; g = 40;  b = 40; }
}
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
if (!is_user_connected(owner) || (!get_pcvar_num(g_pLmKeep534) && (!is_user_alive(owner) || (g_bZombie[owner] && !get_entvar(ent, var_iuser4)))))
{
MineDestroy(ent, false);
return;
}
new bool:mz = get_entvar(ent, var_iuser4) ? true : false;
new Float:now = get_gametime();
new Float:o[3], Float:normal[3];
get_entvar(ent, var_origin, o);
get_entvar(ent, var_vuser1, normal);
new Float:start[3], Float:end[3];
get_entvar(ent, var_vuser3, start);
if (get_entvar(ent, var_iuser2) == 0)
{
if (now >= Float:get_entvar(ent, var_fuser1))
{
new Float:maxr = floatclamp(get_pcvar_float(g_pLmMaxRange), 64.0, 1024.0);
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
MineMakeBeam538(ent, start, end, r, g, b);
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
if (MineEmpCheck(ent, o, now))
{
set_entvar(ent, var_nextthink, now + 0.1);
return;
}
new beam = get_entvar(ent, var_iuser3);
// the mine kept hurting with nothing drawn. Every 0.5 s the beam is checked and rebuilt. 5.3.9a: timer moved fuser3 -> fuser4 (fuser3 is the EMP timer: sharing it blinked the beam + replayed LM_ACTIVATE every 0.5 s)
if (now >= Float:get_entvar(ent, var_fuser4))
{
set_entvar(ent, var_fuser4, now + 0.5);
// 5.3.8a: rebuild ONLY when the beam entity is really gone (no flicker from repeated rebuilds); old beam removed; max 3 per mine
new bool:lost = (beam <= 0 || is_nullent(beam) || (get_entvar(beam, var_flags) & FL_KILLME)) ? true : false;
if (!lost)
{
new cls[8]; get_entvar(beam, var_classname, cls, charsmax(cls));
if (!equal(cls, "beam") || get_entvar(beam, var_iuser1) != BEAM_MARK_LM) lost = true;
}
if (lost && get_entvar(ent, var_playerclass) < 3)
{
set_entvar(ent, var_playerclass, get_entvar(ent, var_playerclass) + 1);
new r, g, b; MineColor(ent, r, g, b); get_entvar(ent, var_vuser2, end);
beam = MineMakeBeam538(ent, start, end, r, g, b);
if (++g_iLmRepair538 <= 5) log_amx("[Vexmira] lazer isini kayboldu, yeniden kuruldu (mayin %d, toplam %d)", ent, g_iLmRepair538);
}
}
if (beam > 0 && !is_nullent(beam))
    MineBeamAnimate(ent, beam, now);
if (get_entvar(ent, var_solid) == SOLID_NOT && !PlayerNear(o, 30.0))
{
set_entvar(ent, var_solid, SOLID_BBOX);
engfunc(EngFunc_SetOrigin, ent, o);
}
new Float:flash = Float:get_entvar(ent, var_fuser2);
if (flash > 0.0 && now >= flash)
{
set_entvar(ent, var_fuser2, 0.0);
MineRefreshColor(ent);
}
get_entvar(ent, var_vuser2, end);
new Float:po[3], Float:hitp[3];
for (new z = 1; z <= g_iMax; z++)
{
if (!is_user_alive(z) || ((g_bZombie[z] ? true : false) == mz) || g_fBurrow[z] > now)
continue;
if (!BeamHitsPlayer(start, end, z))
continue;
get_entvar(z, var_origin, po);
ClosestOnSegment(start, end, po, hitp);
MineHit(ent, owner, z, hitp);
if (is_nullent(ent) || (get_entvar(ent, var_flags) & FL_KILLME))
return;
}
if (random_num(1, 15) == 1)
{
new r, g, b;
MineColor(ent, r, g, b);
FxLight(o, r, g, b, 6, 5, 10);
}
set_entvar(ent, var_nextthink, now + 0.1);
}
MineMakeBeam538(ent, const Float:start[3], const Float:end[3], r, g, b)
{
new beam = BeamCreate(start, end, r, g, b, clamp(get_pcvar_num(g_pLmBeamWidth), 1, 100), 200);
if (beam)
{
    set_entvar(beam, var_iuser1, BEAM_MARK_LM);
    set_entvar(beam, var_iuser2, get_entvar(ent, var_iuser4));
    set_entvar(beam, var_iuser3, ent);
    set_entvar(beam, var_fuser1, float(clamp(get_pcvar_num(g_pLmBeamWidth), 1, 100)));
    new bt = g_iFx532[get_entvar(ent, var_iuser4) ? X_BEAMW : X_BEAM];
    if (bt > 0)
    {
        set_entvar(beam, var_model, get_entvar(ent, var_iuser4) ? "sprites/vexmira/fx532/beam_wide.spr" : "sprites/vexmira/fx532/beam.spr");
        set_entvar(beam, var_modelindex, bt);
    }
}
set_entvar(ent, var_iuser3, beam);
return beam;
}
new const LZ_EN531[4][] = { "Plasma Stream", "Blood Pulse", "Toxic Arc", "Rainbow Prism" };
new const LZ_TR531[4][] = { "Plazma Akimi", "Kan Nabzi", "Toksik Ark", "Gokkusagi Prizmasi" };
LzPrice531(i)
{
new txt[64], p[4][12];
get_pcvar_string(g_pLzPrices531, txt, charsmax(txt));
parse(txt, p[0], charsmax(p[]), p[1], charsmax(p[]), p[2], charsmax(p[]), p[3], charsmax(p[]));
new v = str_to_num(p[clamp(i, 0, 3)]);
return v > 0 ? v : 300 + 150 * i;
}
bool:LzTr531(id)
{
new lg[4]; get_user_info(id, "lang", lg, charsmax(lg));
return (g_iLang[id] == 1 || equali(lg, "tr")) ? true : false;
}
LzStyle531(mine, beam, style, Float:now)
{
new Float:width = Float:get_entvar(beam, var_fuser1);
new r, g, b, bright = 230, noise = 0, Float:scroll = 0.0, Float:w = width;
switch (style)
{
case 1:
{
new Float:pl = 0.5 + 0.5 * floatsin(now * 9.0);
r = 40 + floatround(60.0 * pl); g = 200 + floatround(55.0 * pl); b = 255;
scroll = 60.0; w = width + 3.0 * pl; bright = 200 + floatround(55.0 * pl);
}
case 2:
{
new Float:t = now * 1.6 - float(floatround(now * 1.6, floatround_floor));
new Float:beat = (t < 0.12) ? 1.0 : ((t > 0.22 && t < 0.32) ? 0.75 : 0.25);
r = 255; g = 10 + floatround(40.0 * beat); b = 20;
bright = 120 + floatround(135.0 * beat); w = width + 4.0 * beat; noise = 2;
}
case 3:
{
r = 120 + random_num(0, 60); g = 255; b = 30 + random_num(0, 40);
noise = 10 + random_num(0, 8); scroll = 25.0; bright = 210;
}
default:
{
new Float:h = (now * 0.35 - float(floatround(now * 0.35, floatround_floor))) * 6.0;
new hi = floatround(h, floatround_floor), Float:f = h - float(hi);
new q = floatround(255.0 * (1.0 - f)), t2 = floatround(255.0 * f);
switch (hi % 6) { case 0: { r = 255; g = t2; b = 0; } case 1: { r = q; g = 255; b = 0; } case 2: { r = 0; g = 255; b = t2; }
case 3: { r = 0; g = q; b = 255; } case 4: { r = t2; g = 0; b = 255; } default: { r = 255; g = 0; b = q; } }
scroll = 30.0; bright = 240; w = width + 1.0;
}
}
set_entvar(beam, var_scale, floatclamp(w, 1.0, 100.0));
set_entvar(beam, var_body, noise);
set_entvar(beam, var_animtime, scroll);
BeamColor(beam, r, g, b, bright);
if (Float:get_entvar(beam, var_fuser2) <= now)
{
set_entvar(beam, var_fuser2, now + 0.6);
new Float:e[3]; get_entvar(mine, var_vuser2, e);
if (style == 1 || style == 3) { NxBegin(e); write_byte(TE_SPARKS); NxCoord(e); message_end(); }
NxLight(e, r, g, b, 6, 4, 10);
}
}
ShowLaserShop531(id)
{
new title[320], item[160];
new bool:tr = LzTr531(id);
formatex(title, charsmax(title), "\y%s^n\d%s^n", tr ? "Lazer Isinlari" : "Laser Beams", tr ? "Kendi lazer mayinlarinin isini (kalici)" : "Beam style of your own laser mines (permanent)");
new menu = VexMenuCreate(title, "menu_lzshop_handler531");
formatex(item, charsmax(item), "%s%s", tr ? "Takim rengi (varsayilan)" : "Team colour (default)", g_iLzSel531[id] == 0 ? " \r[*]" : "");
MenuAdd(menu, item, 0);
for (new i = 0; i < 4; i++)
{
if (g_iLzSel531[id] == i + 1) formatex(item, charsmax(item), "\y%s \r[%s]", tr ? LZ_TR531[i] : LZ_EN531[i], tr ? "TAKILI" : "EQUIPPED");
else if (g_iLzOwned531[id] & (1 << i)) formatex(item, charsmax(item), "\w%s \d[%s]", tr ? LZ_TR531[i] : LZ_EN531[i], tr ? "SAHIP" : "OWNED");
else formatex(item, charsmax(item), "\w%s \y[%d VC]", tr ? LZ_TR531[i] : LZ_EN531[i], LzPrice531(i));
MenuAdd(menu, item, i + 1);
}
formatex(item, charsmax(item), "%L", id, "MENU_BACK"); MenuAdd(menu, item, 999);
MenuFinish(id, menu);
}
public menu_lzshop_handler531(id, menu, item)
{
if (item < 0) { menu_destroy(menu); return PLUGIN_HANDLED; }
new v = MenuInfo(menu, item); menu_destroy(menu);
if (v == 999) { ShowCosmeticMenu(id); return PLUGIN_HANDLED; }
if (v < 0 || v > 4) return PLUGIN_HANDLED;
new bool:tr = LzTr531(id);
if (v > 0 && !(g_iLzOwned531[id] & (1 << (v - 1))))
{
new price = LzPrice531(v - 1);
if (g_iVC[id] < price) { Chat(id, "COS_NOVC", price); ShowLaserShop531(id); return PLUGIN_HANDLED; }
g_iVC[id] -= price; g_iLzOwned531[id] |= 1 << (v - 1);
PlayKey(id, "SHOP_BUY"); VxItemFxRGB531(id, 0, 220, 255);
client_print_color(id, print_team_default, "^4[VEXMIRA]^1 %s: ^4%s^1 (-%d VC)", tr ? "Lazer isini alindi" : "Laser beam bought", tr ? LZ_TR531[v - 1] : LZ_EN531[v - 1], price);
}
g_iLzSel531[id] = v;
SaveData(id);
ShowLaserShop531(id);
return PLUGIN_HANDLED;
}
MineBeamAnimate(mine, beam, Float:now)
{
    if (Float:get_entvar(mine, var_fuser2) > now)
    {
        BeamColor(beam, 255, 255, 255, 255);
        return;
    }
    new bool:zombieMine = get_entvar(beam, var_iuser2) ? true : false;
    new owner531 = get_entvar(mine, var_iuser1);
    if (1 <= owner531 <= g_iMax && g_iLzSel531[owner531] > 0 && (g_iLzOwned531[owner531] & (1 << (g_iLzSel531[owner531] - 1))))
    {
        LzStyle531(mine, beam, g_iLzSel531[owner531], now);
        return;
    }
    set_entvar(beam, var_body, 0);
    set_entvar(beam, var_animtime, zombieMine ? 22.0 : 45.0);
    new Float:rate = zombieMine ? 3.2 : 5.0;
    new Float:pulse = 0.5 + 0.5 * floatsin(now * rate);
    new r, g, b;
    MineTeamColor(zombieMine, r, g, b);
    new bright = 175 + floatround(pulse * 80.0);
    new baseWidth = floatround(Float:get_entvar(beam, var_fuser1));
    set_entvar(beam, var_scale, float(clamp(baseWidth + floatround(pulse * (zombieMine ? 4.0 : 3.0)), 1, 100)));
    BeamColor(beam, r, g, b, bright);
    if (Float:get_entvar(beam, var_fuser2) <= now)
    {
        set_entvar(beam, var_fuser2, now + 0.7);
        new Float:e[3]; get_entvar(mine, var_vuser2, e);
        NxLight(e, r, g, b, 5, 4, 12);
        if (!zombieMine) { NxBegin(e); write_byte(TE_SPARKS); NxCoord(e); message_end(); }
    }
}
MineTeamColor(bool:zombieMine, &r, &g, &b)
{
    if (zombieMine) { r = 85; g = 255; b = 110; }
    else { r = 35; g = 175; b = 255; }
}
// 5.3.8: skill props (spores, eggs) are created non-solid where a player stands and turn solid once the spot is free
SolidWhenFree538(ent, const Float:o[3])
{
if (get_entvar(ent, var_solid) != SOLID_NOT) return;
new Float:mn[3], Float:mx[3], Float:pmn[3], Float:pmx[3];
get_entvar(ent, var_mins, mn); get_entvar(ent, var_maxs, mx);
for (new p = 1; p <= g_iMax; p++)
{
if (!is_user_alive(p)) continue;
get_entvar(p, var_absmin, pmn); get_entvar(p, var_absmax, pmx);
if (pmn[0] < o[0] + mx[0] + 4.0 && pmx[0] > o[0] + mn[0] - 4.0 && pmn[1] < o[1] + mx[1] + 4.0 && pmx[1] > o[1] + mn[1] - 4.0
&& pmn[2] < o[2] + mx[2] + 4.0 && pmx[2] > o[2] + mn[2] - 4.0) return;
}
set_entvar(ent, var_solid, SOLID_BBOX);
engfunc(EngFunc_SetOrigin, ent, o);
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
new bool:mz = get_entvar(ent, var_iuser4) ? true : false;
new bool:oneshot = !mz && get_pcvar_num(g_pLmOneShot) ? true : false;
new Float:dmg;
if (special)
dmg = get_pcvar_float(g_pLmSpecialDmg);
else if (oneshot)
dmg = 999999.0;
else
dmg = get_pcvar_float(g_pLmDamage);
if (mz) dmg = get_pcvar_float(g_pLmZDmg534);
if (!is_user_connected(owner) || (g_bZombie[owner] ? true : false) != mz) owner = 0;
new r, g, b;
MineColor(ent, r, g, b);
FxSparks(point);
FxLight(point, r, g, b, 16, 4, 30);
FadeOne(zombie, r, g, b, 120, 0.35);
EmitKey(ent, "LM_HIT");
new beam = get_entvar(ent, var_iuser3);
if (beam > 0 && !is_nullent(beam))
BeamColor(beam, 255, 255, 255, 255);
set_entvar(ent, var_fuser2, now + 0.15);
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
new bool:mz = get_entvar(ent, var_iuser4) ? true : false;
if (!(1 <= attacker <= g_iMax) || !is_user_connected(attacker) || (g_bZombie[attacker] ? true : false) == mz)
return HAM_SUPERCEDE;
new Float:mult = g_bZombie[attacker] ? get_pcvar_float(g_pLmZMult) : get_pcvar_float(g_pLmHumanMult534);
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
new owner = get_entvar(ent, var_iuser1);
new Float:po[3];
for (new p = 1; p <= g_iMax; p++)
{
if (!is_user_alive(p) || (g_bZombie[p] ? true : false) == (get_entvar(ent, var_iuser4) ? true : false))
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
if (!is_user_alive(id) || is_user_bot(id) || g_bMineHint[id] || g_iMines[id] <= 0)
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
if (mode == NM_LASER)
{
if (get_entvar(ent, var_iuser3) != 0)
return HAM_SUPERCEDE;
if (other > 0)
{
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
bool:NadeSees(ent, const Float:o[3], z)
{
new Float:zo[3];
get_entvar(z, var_origin, zo);
engfunc(EngFunc_TraceLine, o, zo, IGNORE_MONSTERS, ent, 0);
new Float:frac;
get_tr2(0, TR_flFraction, frac);
return (frac >= 0.99) ? true : false;
}
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
case 0:
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
case 1:
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
case 2:
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
set_entvar(ent, var_iuser3, 3);
set_entvar(ent, var_fuser4, now + 0.25);
EmitKey(ent, "NADE_TRIGGER", CHAN_ITEM);
FxLight(o, 255, 0, 0, 14, 3, 30);
return;
}
}
default:
{
if (now >= Float:get_entvar(ent, var_fuser4))
NadeDetonateNow(ent);
}
}
}
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
case 0:
{
if (NadeLanded(ent))
NadeStick(ent);
}
case 1:
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
case 2:
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
NadeCleanup(ent)
{
if (get_entvar(ent, var_iuser4) - 1 != NM_LASER)
return;
new beam = get_entvar(ent, var_iuser2);
if (beam > 0 && !is_nullent(beam))
set_entvar(beam, var_flags, FL_KILLME);
set_entvar(ent, var_iuser2, 0);
}
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
#define DROP_CLASS "vex_airdrop"
#define DROP_TOP_Z  22.0
#define DROP_GLOW_Z 32.0
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
engfunc(EngFunc_TraceLine, from, base, IGNORE_MONSTERS, 0, 0);
get_tr2(0, TR_flFraction, frac);
if (frac < 1.0)
{
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
new ent = CreateSafe51("info_target");
if (is_nullent(ent))
return;
set_entvar(ent, var_classname, DROP_CLASS);
UiAll52(58,2.5,4);Radio52(3);
VxSM(ent, g_szDropModel);
if (g_szDropSeqFall[0])
{
set_entvar(ent, var_body, g_iDropBodyChute);
AnimByName(ent, g_szDropSeqFall, 0, 1.0);
}
engfunc(EngFunc_SetSize, ent, Float:{-14.0, -14.0, 0.0}, Float:{14.0, 14.0, 20.0});
set_entvar(ent, var_movetype, MOVETYPE_NONE);
set_entvar(ent, var_solid, SOLID_TRIGGER);
set_entvar(ent, var_gravity, 0.0);
set_entvar(ent,var_fuser2,get_gametime());
set_entvar(ent,var_fuser3,get_gametime());
engfunc(EngFunc_SetOrigin, ent, top);
set_entvar(ent, var_velocity, Float:{0.0, 0.0, 0.0});
set_entvar(ent, var_fuser1, get_gametime() + 75.0);
set_entvar(ent, var_iuser1, 0);
if(g_iSupplySigil47) {
new sig=CreateSafe51("info_target");
if(sig && !is_nullent(sig)) {
set_entvar(sig,var_classname,"vex_supply_sigil47");VxSM(sig,"models/vexmira/epic/supply_sigil47.mdl");
set_entvar(sig,var_solid,SOLID_NOT);set_entvar(sig,var_movetype,MOVETYPE_NOCLIP);set_entvar(sig,var_scale,0.7);
set_entvar(sig,var_iuser4,470048);set_entvar(ent,var_euser1,sig);
}
}
set_entvar(ent, var_renderfx, kRenderFxGlowShell);
set_entvar(ent, var_rendercolor, Float:{255.0, 200.0, 40.0});
set_entvar(ent, var_rendermode, kRenderNormal);
set_entvar(ent, var_renderamt, 25.0);
SetTouch(ent, "fw_DropTouch");
SetThink(ent, "fw_DropThink");
set_entvar(ent, var_nextthink, get_gametime() + 0.1);
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
new spr = CreateSafe51("info_target");
if (!is_nullent(spr))
{
set_entvar(spr, var_classname, "vex_dropglow");
VxSM(spr, g_szSprBeacon);
set_entvar(spr, var_rendermode, kRenderTransAdd);
set_entvar(spr, var_renderamt, 255.0);
set_entvar(spr, var_rendercolor, Float:{255.0, 200.0, 40.0});
set_entvar(spr, var_scale, 1.2);
set_entvar(spr, var_movetype, MOVETYPE_NOCLIP);
set_entvar(spr, var_solid, SOLID_NOT);
new Float:gp[3];
gp = top;
gp[2] += DROP_GLOW_Z;
engfunc(EngFunc_SetOrigin, spr, gp);
set_entvar(spr, var_velocity, Float:{0.0, 0.0, 0.0});
set_entvar(ent, var_iuser3, spr);
}
}
}
FxTrail(ent, 255, 200, 40);
// 5.3.8: no "supply drop" HUD filler (chat + beam stay)
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
new sig47=get_entvar(ent,var_euser1);
if(sig47>0 && !is_nullent(sig47)) {
new Float:so47[3],Float:sa47[3];so47=o;so47[2]+=42.0;sa47[1]=float(floatround(now*80.0)%360);
engfunc(EngFunc_SetOrigin,sig47,so47);set_entvar(sig47,var_angles,sa47);
}
new bool:landed = get_entvar(ent, var_iuser1) ? true : false;
if(!landed) {
new Float:dest48[3];dest48=o;dest48[2]-=80.0*floatclamp(now-Float:get_entvar(ent,var_fuser2),0.0,0.25);
new tr48=create_tr2();engfunc(EngFunc_TraceLine,o,dest48,IGNORE_MONSTERS,ent,tr48);
new Float:fr48;get_tr2(tr48,TR_flFraction,fr48);
if(get_tr2(tr48,TR_StartSolid)||get_tr2(tr48,TR_AllSolid)) {free_tr2(tr48);DropRemove(ent);return;}
if(fr48<1.0) {get_tr2(tr48,TR_vecEndPos,dest48);dest48[2]+=0.5;landed=true;}
free_tr2(tr48);engfunc(EngFunc_SetOrigin,ent,dest48);o=dest48;
set_entvar(ent,var_fuser2,now);
if(now-Float:get_entvar(ent,var_fuser3)>14.0 && !landed) {DropRemove(ent);return;}
}
if (landed && !get_entvar(ent,var_iuser1))
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
new glow = get_entvar(ent, var_iuser3);
if (glow > 0 && !is_nullent(glow))
{
new Float:gp[3];
gp = o;
gp[2] += DROP_GLOW_Z;
engfunc(EngFunc_SetOrigin, glow, gp);
vel[0] = vel[1] = vel[2] = 0.0;
set_entvar(glow, var_velocity, vel);
}
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
new sig47=get_entvar(ent,var_euser1);
if(sig47>0 && !is_nullent(sig47)) engfunc(EngFunc_RemoveEntity,sig47);
set_entvar(ent,var_euser1,0);
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
if (!get_entvar(ent, var_iuser1)) return;
new name[32];
get_user_name(other, name, charsmax(name));
new Float:o[3];
get_entvar(ent, var_origin, o);
DropRemove(ent);
if (g_bZombie[other])
{
EmitKey(other,"AIRDROP_LOOT");
FxSprite(o, g_sprSmoke, 20, 180);
FxRingSmall(o, 0, 255, 0);
ChatAllS("AIRDROP_ZOMBIE", name);
HealTo(other, max(800, get_pcvar_num(g_pAirdropHP)), g_iMaxHP[other]);
AddAP(other, 40, false, true);
g_iVC[other] += 2;
SaveData(other);
return;
}
FxRingEx(o, 255, 200, 40, 260, 16, 6);
FxStreak(o, 4, 50, 250);
EmitKey(other, "AIRDROP_LOOT");
AirdropLoot(other, name);
}
AirdropLoot(id, const name[])
{
new bonus47 = random_num(60, 100), coins47 = random_num(2, 4);
AddAP(id, bonus47, false, true);
g_iVC[id] += coins47;
client_print(id, print_chat, "[VEXMIRA] Supply bonusu: +%d AP / +%d VC ve ek odul!", bonus47, coins47);
new roll = random_num(1, 100);
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
VxGive(id, sw);
copy(key, charsmax(key), "LOOT_SW");
amount = sw;
}
else
{
g_iVC[id] += 3;
copy(key, charsmax(key), "LOOT_VC");
}
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
new bool:g_bModelSwap51;
public fw_SetModelPost(ent, const model[])
{
if(g_bModelSwap51) return FMRES_IGNORED;
if (ent <= g_iMax || model[0] != 'm' || is_nullent(ent))
return FMRES_IGNORED;
if (CommunityWorldModel(ent, model)) return FMRES_IGNORED;
if (equal(model, "models/vexmira_ze/skins/vexmira_w_ak47.mdl"))
{
new cls[16]; get_entvar(ent, var_classname, cls, charsmax(cls));
if (equal(cls, "weaponbox"))
{
new weapon = get_member(ent, m_WeaponBox_rgpPlayerItems, 1), sw = VxIndex(weapon);
if (sw >= 0 && g_bVxReady[sw])
{
new Float:mins[3], Float:maxs[3];
get_entvar(ent, var_mins, mins); get_entvar(ent, var_maxs, maxs);
if(!equal(model,g_szVxWorld[sw])) {g_bModelSwap51=true;VxSM(ent,g_szVxWorld[sw]);g_bModelSwap51=false;}
set_entvar(ent, var_body, 0);
engfunc(EngFunc_SetSize, ent, mins, maxs);
}
}
return FMRES_IGNORED;
}
if (!equal(model, "models/w_", 9))
return FMRES_IGNORED;
new slot = -1;
if (equal(model[9], "hegrenade.mdl"))           slot = 0;
else if (equal(model[9], "smokegrenade.mdl"))   slot = 1;
else if (equal(model[9], "flashbang.mdl"))      slot = 2;
if (slot < 0)
return FMRES_IGNORED;
new cls[12];
get_entvar(ent, var_classname, cls, charsmax(cls));
if (!equal(cls, "grenade"))
return FMRES_IGNORED;
new owner = get_entvar(ent, var_owner);
if (1 <= owner <= g_iMax && g_bZombie[owner])
{
if (slot == 0 && g_szInfW531[0] && !equal(model, g_szInfW531) && VxModelOk(g_szInfW531))
{
new Float:zmins[3], Float:zmaxs[3];
get_entvar(ent, var_mins, zmins); get_entvar(ent, var_maxs, zmaxs);
g_bModelSwap51=true; VxSM(ent, g_szInfW531); g_bModelSwap51=false;
engfunc(EngFunc_SetSize, ent, zmins, zmaxs);
}
return FMRES_IGNORED;
}
if (!g_szWNade[slot][0])
return FMRES_IGNORED;
new Float:mins[3], Float:maxs[3];
get_entvar(ent, var_mins, mins);
get_entvar(ent, var_maxs, maxs);
if(!equal(model,g_szWNade[slot])) {g_bModelSwap51=true;VxSM(ent,g_szWNade[slot]);g_bModelSwap51=false;}
engfunc(EngFunc_SetSize, ent, mins, maxs);
return FMRES_IGNORED;
}
MakeZombie(id)
{
CommunityRemoveWeapons(id);
CommunityRemoveKnives(id);
ZcCall(ZC_JETPACK, ZCOP_infected, id);
ZcCall(ZC_HEV, ZCOP_remove, id);
if (!g_bZombie[id] && !get_pcvar_num(g_pLmKeep534))
RemovePlayerMines(id, true);
KillTrail(id);
if (g_iClassNext[id] >= 0)
{
g_iClass[id] = g_iClassNext[id];
g_iClassNext[id] = -1;
}
g_bClassSwitched[id] = false;
ZcCleanup(id);
g_bSurvivor[id]=0; g_bSniper[id]=0;
g_bZombie[id] = 1;
g_bAlpha[id] = false;
g_iMines[id] = LasersAllowed() ? 1 : 0;
if(g_iEvent==EV_TITAN && g_bFirst[id]) client_print(id,print_chat,"[VEXMIRA] TITAN: R ile yer darbesi. Bekleme: 18 saniye.");
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
if (g_iEvent == EV_TITAN && g_bFirst[id] && g_bTitan47 && !g_bBoss[id])
VxSetUserModel(id, "vex_titan48", true);
else if (model[0])
VxSetUserModel(id, model, true);
rg_set_user_footsteps(id, g_bAssassin[id] || (cls == 5 && !g_bNemesis[id]) ? true : false);
ApplyRender(id);
rg_reset_maxspeed(id);
}
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
CommunityReset(id);
ZcCleanup(id);
ClearZombieRoles(id);
g_bZombie[id] = 0;
g_bSurvivor[id]=0; g_bSniper[id]=0;
g_iSpecW[id] = 0;
g_bVxGiving[id] = false; g_iVxAttack[id] = 0; g_iVxClip[id] = 0; g_iVxShots[id] = 0; g_bVxRightHeld[id] = false; g_bVxAltHandled[id] = false;
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
if (g_szSnipModel[0]) VxSetUserModel(id, g_szSnipModel, true);
}
else
{
GiveModeWeapons(id, 0);
ZcCall(ZC_MINIGUN, ZCOP_give,id);
g_iMaxHP[id] = get_pcvar_num(g_pSurvHP);
if (g_iMode == MODE_ARMAGEDDON)
g_iMaxHP[id] /= 2;
if (g_szSurvModel[0]) VxSetUserModel(id, g_szSurvModel, true);
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
MakeHuman(id)
{
CommunityReset(id);
set_task(0.3, "CommunityApplyKnife", id + 64000);
ZcCleanup(id);
ClearZombieRoles(id);
g_bZombie[id] = 0;
g_bSurvivor[id]=0; g_bSniper[id]=0; g_bUnlClip[id]=0;
g_iMaxHP[id]=MaxHumanHP(id);
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
new v = g_iCommunitySel[id][0];
if (v > 0 && v <= 5 && (g_iCommunityOwned[id][0] & (1 << (v-1))) && CommunityCtReady(v-1)) { VxSetUserModel(id, COMMUNITY_CT[v-1], true); return; }
new flags = get_user_flags(id);
if ((flags & ADMIN_BAN) && g_szAdminModel[0])
VxSetUserModel(id, g_szAdminModel, true);
else if (((flags & ADMIN_LEVEL_H) || IsVip(id)) && g_szVipModel[0])
VxSetUserModel(id, g_szVipModel, true);
else if (g_iHumanModelN > 0)
VxSetUserModel(id, g_szHumanModels[clamp(g_iHumanSkin[id], 0, g_iHumanModelN - 1)], true);
else
rg_reset_user_model(id,true);
}
SetGravity(id, Float:grav)
{
g_fGrav[id] = grav;
set_entvar(id, var_gravity, grav);
}
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
if (attacker != victim && 1 <= attacker <= g_iMax && g_bZombie[attacker] && !g_bBoss[attacker] && !g_bNemesis[attacker]) vxe_zup_add(attacker, 1);
new vname[32], aname[32];
get_user_name(victim, vname, charsmax(vname));
get_user_name(attacker, aname, charsmax(aname));
MakeZombie(victim);
new Float:vo[3];
get_entvar(victim, var_origin, vo);
CosInfectFx(attacker, vo);
FxSpr(vo, g_sprFx[FXS_INFECT], 7, 220, 10.0);
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
if (g_iClass[attacker] == 4 && !g_bMinion[attacker])
HealTo(attacker, 400, g_iMaxHP[attacker]);
Reward(attacker, get_pcvar_num(g_pInfectXP), get_pcvar_num(g_pInfectAP));
PayBounty(attacker, victim);
Chat(victim, "YOU_INFECTED", aname);
CsoNotify(attacker, CN_INFD);
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
public fw_CmdStart(id, uc_handle, seed)
{
if (is_user_alive(id) && !g_bZombie[id]) VxCommand(id, uc_handle);
if (!is_user_alive(id))
return FMRES_IGNORED;
new imp = get_uc(uc_handle, UC_Impulse);
if (!g_bZombie[id])
{
if (imp == 100 && CommunityInspect(id)) { set_uc(uc_handle,UC_Impulse,0); return FMRES_HANDLED; }
if (imp == 100 && g_fNoLight[id] > get_gametime())
{
set_uc(uc_handle, UC_Impulse, 0);
LightsBlockedMsg(id);
}
return FMRES_IGNORED;
}
if (imp == 100 && (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id]))
{
set_uc(uc_handle, UC_Impulse, 0);
SkillTrigger(id, 2);
}
if ((get_uc(uc_handle, UC_Buttons) & IN_RELOAD) && !(get_entvar(id, var_oldbuttons) & IN_RELOAD))
SkillTrigger(id, 1);
return FMRES_IGNORED;
}
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
public cmd_drop(id)
{
if(is_user_alive(id) && g_bBoss[id]) {SkillTriggerG(id);return PLUGIN_HANDLED;}
if (!is_user_alive(id) || !g_bZombie[id] || !get_pcvar_num(g_pZc[ZCV_ALTKEYS]))
return PLUGIN_CONTINUE;
SkillTrigger(id, (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id]) ? 2 : 1);
return PLUGIN_HANDLED;
}
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
UseAbility538(id)
{
if(g_iEvent==EV_TITAN && g_bFirst[id] && !g_bBoss[id]) {TitanStomp47(id);return;}
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
case 0:
{
g_fBurst[id] = now + 4.0;
rg_reset_maxspeed(id);
FxRing(o, 255, 160, 0, 220);
EmitZombieSound(id, "ABILITY", "ABILITY_BURST");
}
case 1:
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
case 2:
{
g_fShield[id] = now + 4.0;
ApplyRender(id);
FxRing(o, 40, 120, 255, 260);
EmitZombieSound(id, "ABILITY", "ABILITY_SHIELD");
}
case 3:
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
case 4:
{
HealTo(id, g_iMaxHP[id] / 4, g_iMaxHP[id]);
FxRing(o, 200, 0, 0, 220);
FxLight(o, 200, 0, 0, 30, 12, 20);
EmitZombieSound(id, "ABILITY", "ABILITY_DRAIN");
}
case 5:
{
g_fCloak[id] = now + 6.0;
ApplyRender(id);
FxRing(o, 0, 120, 120, 200);
EmitZombieSound(id, "ABILITY", "ABILITY_CLOAK");
}
case 6:
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
case 7:
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
case 8:
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
case 9:
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
case 10:
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
case 11:
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
if (!UseAbilityV3(id, cls))
return;
}
}
g_fCool[id] = now + CLASS_COOL[cls];
}
EmitZombieSound(id, const ev[], const fallbackKey[])
{
new key[24], path[256];
formatex(key, charsmax(key), "Z%d_%s", g_iClass[id], ev);
if (!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
{
if (!TrieGetString(g_tRes, fallbackKey, path, charsmax(path)) || !path[0])
return;
}
SndPick531(path, charsmax(path));
if (containi(path, ".mp3") != -1)
return;
EmitSafe(id, CHAN_VOICE, path, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
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
write_byte(28);
write_byte(55);
write_byte(68);
write_byte(64);
write_byte(4);
write_byte(0);
message_end();
}
}
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
new g_iZupCtx538, Float:g_fZupMul538[2], g_iZcKind538[ZCV_TOTAL];
Float:ZcF(c)
{
new Float:v = get_pcvar_float(g_pZc[c]);
if (g_iZupCtx538 && g_iZcKind538[c]) v *= g_fZupMul538[g_iZcKind538[c] - 1];
return v;
}
// 5.3.8 zombie class upgrades (levels kept by vexmira_extra): cooldown -6 % / range +6 % / damage +8 % per level
ZupMarks538()
{
static const RAD[] = { ZCV_HOOK_RANGE, ZCV_HUNT_RAD, ZCV_WEB_RANGE, ZCV_MAG_RAD, ZCV_VOLT_RAD, ZCV_BUR_RAD, ZCV_SIR_RAD, ZCV_SPO_RAD, ZCV_NM_RAD };
static const DMG[] = { ZCV_HOOK_DMG, ZCV_HUNT_DMG, ZCV_CHG_DMG, ZCV_WEB_DMG, ZCV_MAG_DMG, ZCV_VOLT_DMG, ZCV_BUR_DMG };
for (new i = 0; i < sizeof RAD; i++) g_iZcKind538[RAD[i]] = 1;
for (new i = 0; i < sizeof DMG; i++) g_iZcKind538[DMG[i]] = 2;
}
UseAbility(id)
{
new lvl = (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id]) ? 0 : clamp(vxe_zup_level(id, clamp(g_iClass[id], 0, NUM_CLASSES - 1)), 0, 10);
new Float:before = g_fCool[id];
g_fZupMul538[0] = 1.0 + 0.06 * float(lvl); g_fZupMul538[1] = 1.0 + 0.08 * float(lvl);
g_iZupCtx538 = lvl ? id : 0;
UseAbility538(id);
g_iZupCtx538 = 0;
if (g_fCool[id] > before && is_user_alive(id))
{
if (lvl) g_fCool[id] = get_gametime() + (g_fCool[id] - get_gametime()) * floatmax(0.4, 1.0 - 0.06 * float(lvl));
vxe_zup_used(id, lvl);
}
}
ZcN(c)
{
return get_pcvar_num(g_pZc[c]);
}
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
stock ZcHand(id, Float:out[3])
{
new Float:dir[3];
ZcEye(id, out);
ZcAimDir(id, dir);
out[0] += dir[0] * 12.0;
out[1] += dir[1] * 12.0;
out[2] += dir[2] * 12.0 - 10.0;
}
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
new ent = CreateSafe51("info_target");
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
engfunc(EngFunc_TraceLine, eye, start, IGNORE_MONSTERS, owner, 0);
get_tr2(0, TR_flFraction, frac);
if (frac < 1.0)
get_tr2(0, TR_vecEndPos, start);
set_entvar(ent, var_classname, ZPROJ_CLASS);
if (type == ZP_HOOK && g_szHookModel[0])
{
VxSM(ent, g_szHookModel);
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
VxSM(ent, spr);
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
set_entvar(ent, var_fuser4, 0.0);
SetThink(ent, "fw_ZProjThink");
set_entvar(ent, var_nextthink, get_gametime() + 0.02);
return ent;
}
ChainBeamCreate(const Float:a[3], const Float:b[3], owner = 0)
{
new beam = CreateSafe51("beam");
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
engfunc(EngFunc_TraceLine, last, cur, IGNORE_MONSTERS, ent, 0);
get_tr2(0, TR_flFraction, frac);
get_tr2(0, TR_vecEndPos, wall);
if (frac < 1.0)
seg = wall;
else
seg = cur;
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
set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
FxLight(o, 140, 140, 200, 18, 6, 20);
}
EmitKey(id, "HUNTER_IMPACT", CHAN_BODY);
}
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
new Float:vel[3];
get_entvar(id, var_velocity, vel);
vel[0] *= 0.4;
vel[1] *= 0.4;
set_entvar(id, var_velocity, vel);
}
rg_reset_maxspeed(id);
ApplyRender(id);
}
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
bool:MimicDisguise(id)
{
new Float:o[3], model[32];
get_entvar(id, var_origin, o);
g_fDisguise[id] = get_gametime() + floatclamp(ZcF(ZCV_MIM_TIME), 1.0, 60.0);
if (g_szHumanModel[0])
copy(model, charsmax(model), g_szHumanModel);
else
copy(model, charsmax(model), "gign");
VxSetUserModel(id, model, true);
rg_set_user_footsteps(id, true);
ApplyRender(id);
FxSprite(o, g_sprSmoke, 14, 140);
FxImplosion(o, 80, 20, 4);
EmitZombieSound(id, "ABILITY", "ABILITY_CLOAK");
HudTo(id, SL_PERS, CLR_ZOMBIE, 2.5, "MIMIC_YOU");
return true;
}
MimicReveal(id, victim = 0)
{
if (g_fDisguise[id] <= 0.0)
return;
g_fDisguise[id] = 0.0;
if (!is_user_alive(id) || !g_bZombie[id])
return;
new cls = clamp(g_iClass[id], 0, NUM_CLASSES - 1);
if (g_szZModel[cls][0])
VxSetUserModel(id, g_szZModel[cls], true);
else
rg_reset_user_model(id,true);
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
bool:SporePlant(id)
{
new Float:now = get_gametime();
new maxp = clamp(ZcN(ZCV_SPO_MAX), 1, 6);
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
ent = CreateSafe51("info_target");
if (is_nullent(ent))
return false;
set_entvar(ent, var_classname, SPORE_CLASS);
if (g_szSporeModel[0])
{
VxSM(ent, g_szSporeModel);
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
VxSM(ent, spr);
set_entvar(ent, var_rendermode, kRenderTransAdd);
set_entvar(ent, var_renderamt, 220.0);
set_entvar(ent, var_rendercolor, Float:{110.0, 220.0, 60.0});
set_entvar(ent, var_scale, 0.45);
}
pos[2] += 14.0;
}
new Float:hp = float(clamp(ZcN(ZCV_SPO_HP), 1, 5000));
set_entvar(ent, var_movetype, MOVETYPE_NONE);
set_entvar(ent, var_solid, SOLID_NOT); // 5.3.8: planted at the owner's feet -> solid only once nobody stands in it (stuck fix)
engfunc(EngFunc_SetSize, ent, Float:{-10.0, -10.0, 0.0}, Float:{10.0, 10.0, 22.0});
engfunc(EngFunc_SetOrigin, ent, pos);
set_entvar(ent, var_takedamage, DAMAGE_YES);
set_entvar(ent, var_health, hp);
set_entvar(ent, var_max_health, hp);
set_entvar(ent, var_iuser1, id);
set_entvar(ent, var_fuser1, now + 1.0);
set_entvar(ent, var_fuser2, now + floatclamp(ZcF(ZCV_SPO_LIFE), 5.0, 600.0));
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
SolidWhenFree538(ent, o);
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
ZcCleanup(id)
{
if (!(1 <= id <= 32))
return;
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
VxSetUserModel(id, g_szZModel[cls], true);
else
rg_reset_user_model(id,true);
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
for (new p = 1; p <= g_iMax; p++)
{
if (g_iLureBy[p] == id)
LureEnd(p, true);
}
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
g_fEpicG[boss]=get_gametime()+6.0;
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
VxSetUserModel(boss, g_szBModel[g_iBossType], true);
new stepKey[24];
rg_set_user_footsteps(boss, BossSndKey("STEP", stepKey, charsmax(stepKey)) ? true : false);
ApplyRender(boss);
g_fBossIntro = get_gametime() + 2.5;
rg_reset_maxspeed(boss);
set_entvar(boss, var_velocity, Float:{0.0, 0.0, 0.0});
new name[32], key[20], Float:o[3];
get_user_name(boss, name, charsmax(name));
get_entvar(boss, var_origin, o);
new r = BOSS_RGB[g_iBossType][0], g = BOSS_RGB[g_iBossType][1], b = BOSS_RGB[g_iBossType][2];
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
for (new k531 = 0; k531 < 3; k531++)
{
new d531[6]; d531[0] = floatround(o[0]); d531[1] = floatround(o[1]); d531[2] = floatround(o[2]); d531[3] = r; d531[4] = g; d531[5] = b;
set_task(0.5 + 0.65 * float(k531), "task_BossAftershock531", 0, d531, sizeof d531);
}
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
new nm[32], spaced[64], txt[128];
for (new p = 1; p <= g_iMax; p++)
{
if (!is_user_connected(p) || is_user_bot(p))
continue;
formatex(key, charsmax(key), "BOSS_NAME_%d", g_iBossType);
formatex(nm, charsmax(nm), "%L", p, key);
SpaceOut(nm, spaced, charsmax(spaced));
// 5.3.8: boss name only (no "... awakened" subtitle filler)
if (g_bFinalBoss)
formatex(txt, charsmax(txt), "%L^n%s", p, "FINAL_BOSS_TAG", spaced);
else
copy(txt, charsmax(txt), spaced);
HudText(p, SL_ANN, r, g, b, 4.0, txt);
}
if (!PlayBossSound("INTRO"))
PlayKey(0, "BOSS_INTRO");
VoiceReset(boss);
EpicBossStart(boss);
set_task(0.9, "task_BossFlash", TASK_INTRO);
set_task(2.5, "task_BossIntroEnd", TASK_INTRO + 1);
if (g_bArB536 && g_iArHN536 > 0 && get_pcvar_num(g_pArenaTp536)) set_task(0.5, "task_Arena536", TASK_INTRO + 2);
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
PlayKey(0, "UI_BOSS_BAR");
}
BossHurt(id, Float:dmg, bits)
{
if (!is_user_alive(id) || g_bZombie[id])
return;
dmg *= get_pcvar_float(g_pBossAbil);
if (g_bEnraged)
dmg *= 1.3;
if (g_bFinalBoss)
dmg *= 1.15;
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
FxLight(o, r, g, b, g_bEnraged ? 55 : 42, 11, 5);
if (g_iFrame % 2 == 0)
{
FxFollow(boss, r, g, b, 18, 10);
if (g_bHeadMarkAt && !g_iOvhBar[boss] && !g_iOvhEmb[boss])
FxHeadMark(boss, g_sprHeadMark, 21, true);
new Float:feet[3];
feet = o;
feet[2] -= 30.0;
FxRingEx(feet, r, g, b, 160, 10, 4, 160);
}
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
BossAutoR();
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
BossPassive(boss, const Float:o[3])
{
new Float:po[3], Float:now = get_gametime();
switch (g_iBossType)
{
case 1:
{
if (g_iFrame % 6 == 0)
{
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
case 3:
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
case 5:
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
case 6:
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
case 7:
{
HealTo(boss, max(10, g_iBossMaxHP / 250), g_iBossMaxHP);
if (g_iFrame % 2 == 0)
FxSprite(o, g_sprSmoke, 15, 120);
}
case 8:
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
UiAll52(59,2.5,8);
new Float:o[3], key[20];
get_entvar(g_iBoss, var_origin, o);
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
BossAbilityRadius(ability)
{
static const R1[NUM_BOSSES] = { 480, 750, 500, 560, 300, 460, 0, 0, 750 };
static const R2[NUM_BOSSES] = { 260, 0, 300, 0, 520, 0, 700, 500, 0 };
return ability ? R2[g_iBossType] : R1[g_iBossType];
}
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
BossAoE(const Float:c[3], Float:radius, Float:dmg, r, g, b, Float:up = 0.0)
{
new Float:po[3], Float:vel[3], hits;
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
remove_task(TASK_INTRO + 2);
remove_task(TASK_INTRO + 3);
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
public cmd_bossinfo(id)
{
new key[20];
Chat(id, "BOSSINFO_TITLE");
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
BurnHuman(p, ticks)
{
g_iBurn[p] = max(g_iBurn[p], ticks);
g_iBurnBy[p] = g_iBoss;
}
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
formatex(txt, charsmax(txt), "%s^n%s", nm, tip);
HudText(p, SL_ALERT, UI_R, UI_G, UI_B, 1.6, txt);
}
formatex(key, charsmax(key), "B%d_R%d", g_iBossType, ph);
EmitKey(g_iBoss, key, CHAN_STATIC, ATTN_NONE);
if (g_iBoss && is_user_alive(g_iBoss) && 0 <= g_iBossType < NUM_BOSSES)
{
new Float:bo[3];
get_entvar(g_iBoss, var_origin, bo);
FxElSmall(bo, BOSS_ELEM[g_iBossType], 8 + clamp(ph, 1, 3) * 3);
}
}
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
if (g_iBossChannel != CH_NONE || task_exists(TASK_BOSSCAST))
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
EpicBossCastFx();
rg_set_animation(g_iBoss,PLAYER_ATTACK1);
if (setCool)
{
g_fBossRCool = now + BSK_COOL[g_iBossType][ph - 1] * floatmax(0.1, get_pcvar_float(g_pBossRCdMult));
g_fBossRLast = now;
}
return true;
}
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
bool:BossAutoOldSkill()
{
if (g_iBossPhase < 2 || g_iBossChannel != CH_NONE || random_num(1, 100) > 40)
return false;
new ph = random_num(1, g_iBossPhase - 1);
new t = BossPickHuman(1200.0, -1.0);
if (t)
BossFace(t);
return BossCastR(ph, false) ? true : false;
}
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
ang[0] = 0.0;
set_entvar(g_iBoss, var_angles, ang);
}
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
case CH_TITAN:
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
case CH_REQUIEM:
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
case CH_CHAINS:
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
case CH_ZERO:
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
case CH_DASH:
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
case CH_TEMPEST:
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
case CH_CLOUD:
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
case CH_SINGULARITY:
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
case CH_HORIZON:
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
bool:Bsk_StormDash()
{
g_iDashHit = 0;
LeapForward(g_iBoss, 1300.0, 160.0);
StartChannel(CH_DASH, 0.7);
FxFollow(g_iBoss, 255, 240, 80, 8, 20);
return true;
}
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
bool:Bsk_HiveCloud()
{
new Float:bo[3];
get_entvar(g_iBoss, var_origin, bo);
StartChannel(CH_CLOUD, 6.0);
ZoneSpawn(bo, BskRad(2), 110, 255, 0, 6.0, g_iBoss, false);
FxSprite(bo, g_sprSmoke, 40, 200);
return true;
}
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
new ent = CreateSafe51("info_target");
if (is_nullent(ent))
return 0;
new Float:pos[3];
FloorAt(o, pos);
set_entvar(ent, var_classname, EGG_CLASS);
if (g_szEggModel[0])
{
VxSM(ent, g_szEggModel);
if (AnimByName(ent, "pulse", -1, 1.0) < 0)
AnimByName(ent, "idle", 0, 1.0);
set_entvar(ent, var_renderfx, kRenderFxGlowShell);
set_entvar(ent, var_rendercolor, Float:{110.0, 255.0, 0.0});
set_entvar(ent, var_renderamt, 12.0);
}
else if (g_szSprOrb[0])
{
VxSM(ent, g_szSprOrb);
set_entvar(ent, var_rendermode, kRenderTransAdd);
set_entvar(ent, var_renderamt, 230.0);
set_entvar(ent, var_rendercolor, Float:{110.0, 255.0, 0.0});
set_entvar(ent, var_scale, 0.55);
}
set_entvar(ent, var_movetype, MOVETYPE_NONE);
set_entvar(ent, var_solid, SOLID_NOT);
if (g_szEggModel[0])
{
pos[2] -= 1.0;
engfunc(EngFunc_SetSize, ent, Float:{-12.0, -12.0, 0.0}, Float:{12.0, 12.0, 24.0});
}
else
{
pos[2] += 14.0;
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
{ new Float:eo[3]; get_entvar(ent, var_origin, eo); SolidWhenFree538(ent, eo); }
if (get_entvar(ent, var_iuser3) != g_iBossSerial || !g_bRoundActive)
{
set_entvar(ent, var_flags, FL_KILLME);
return;
}
new Float:o[3], Float:now = get_gametime();
get_entvar(ent, var_origin, o);
if (g_szEggModel[0])
o[2] += 12.0;
if (now >= Float:get_entvar(ent, var_fuser1))
{
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
ProjSpawn(type, const Float:o[3], const Float:vel[3], r, g, b, Float:scale, Float:life, movetype, Float:gravity)
{
new ent = CreateSafe51("info_target");
if (is_nullent(ent))
return 0;
set_entvar(ent, var_classname, PROJ_CLASS);
if (g_szSprOrb[0])
{
VxSM(ent, g_szSprOrb);
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
set_entvar(ent, var_velocity, Float:{0.0, 0.0, 0.0});
set_entvar(ent, var_movetype, MOVETYPE_NONE);
}
}
}
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
BossCleanup()
{
g_iBossSerial++;
remove_task(TASK_EPIC_MUSIC);
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
stock BossEvMap(const ev[], out[], len)
{
if (equal(ev, "SPAWN"))        copy(out, len, "INTRO");
else if (equal(ev, "ROAR"))    copy(out, len, "IDLE");
else if (equal(ev, "SCREAM"))  copy(out, len, "ATTACK");
else if (equal(ev, "ABILITY")) copy(out, len, "ATTACK");
else                           copy(out, len, ev);
}
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
bool:PlayBossSound(const ev[])
{
new key[24];
if (!BossSndKey(ev, key, charsmax(key)))
return false;
PlayKey(0, key);
return (key[0] == 'B' && key[1] != 'O') ? true : false;
}
EmitBossSound(const ev[], Float:attn = ATTN_NONE, Float:vol = VOL_NORM)
{
if (!g_iBoss || !is_user_connected(g_iBoss))
return;
new key[24], path[128];
if (!BossSndKey(ev, key, charsmax(key)) || !TrieGetString(g_tRes, key, path, charsmax(path)) || containi(path, ".mp3") != -1)
return;
EmitSafe(g_iBoss, CHAN_STATIC, path, vol, attn, 0, PITCH_NORM);
}
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
VoiceTick(id, Float:now)
{
if (!is_user_alive(id) || !g_bZombie[id] || !(g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id]))
{
g_fStepDist[id] = 0.0;
return;
}
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
SpecialVoice(ent, const ev[])
{
new Float:now = get_gametime();
new bool:boss = (g_bBoss[ent] && ent == g_iBoss) ? true : false;
if (equal(ev, "PAIN"))
{
if (now >= g_fSndPain[ent])
{
g_fSndPain[ent] = now + floatmax(boss?3.0:0.8, get_pcvar_float(g_pBossPainCd));
if (boss)
{
g_iPainAlt[ent] = !g_iPainAlt[ent];
new key[24], path[128];
if (BossSndKey(g_iPainAlt[ent] ? "PAIN2" : "PAIN", key, charsmax(key)) && TrieGetString(g_tRes, key, path, charsmax(path)))
EmitSafe(ent, CHAN_VOICE, path, boss ? 0.55 : VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
else if (BossSndKey("PAIN", key, charsmax(key)) && TrieGetString(g_tRes, key, path, charsmax(path)))
EmitSafe(ent, CHAN_VOICE, path, boss ? 0.55 : VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}
else
EmitSpecialSound(ent, "PAIN", CHAN_VOICE, ATTN_NORM, 0.55);
}
return FMRES_SUPERCEDE;
}
if (equal(ev, "DIE"))
{
return FMRES_SUPERCEDE;
}
if (now >= g_fSndAtk[ent])
{
g_fSndAtk[ent] = now + floatmax(boss?1.4:0.6, get_pcvar_float(g_pBossAtkCd));
if (boss)
{
new key[24], path[128];
if (BossSndKey("ATTACK", key, charsmax(key)) && TrieGetString(g_tRes, key, path, charsmax(path)))
EmitSafe(ent, CHAN_VOICE, path, boss ? 0.55 : VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}
else
EmitSpecialSound(ent, "ATTACK", CHAN_VOICE, ATTN_NORM, 0.55);
}
return FMRES_SUPERCEDE;
}
BossKillTaunt(attacker)
{
if (!g_bBoss[attacker] || attacker != g_iBoss)
return;
new Float:now = get_gametime();
if (now < g_fSndKill)
return;
g_fSndKill = now + 8.0;
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
public task_EnforceRoundInfinite()
{
new v[32];
get_cvar_string("mp_round_infinite", v, charsmax(v));
if (!equal(v, "1") && contain(v, "a") == -1)
set_cvar_string("mp_round_infinite", "abcdefghijk");
}
public rg_CheckWinConditions()
{
return HC_SUPERCEDE;
}
public rg_MakeBomber(id)
{
SetHookChainReturn(ATYPE_BOOL, false);
return HC_SUPERCEDE;
}
public rg_RestartRound()
{
set_task(0.2, "BDoor536_RestoreAll");
SkyNextRound531();
g_bModePicked47 = false;
g_bForcedRound47 = false;
for(new reset47=1;reset47<=32;reset47++) { BannerRemove47(reset47); GaugeRemove47(reset47); }
VxClear();
MsRoundRestart();
CsoFlushAll();
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
remove_task(TASK_INTRO + 2);
remove_task(TASK_INTRO + 3);
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
if (get_member_game(m_bCompleteReset))
g_iRound = 1;
else
g_iRound = get_member_game(m_iTotalRoundsPlayed) + 2;
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
stock Shuffle534(arr[], n) { for (new i = n - 1; i > 0; i--) { new j = random(i + 1), t = arr[i]; arr[i] = arr[j]; arr[j] = t; } }
BuildPlan534()
{
new total = clamp(RoundsTotal(), 1, 63);
g_iPlanTotal534 = total;
new list[64], n;
for (new r = 0; r < 64; r++) { g_iPlanMode534[r] = MODE_INFECTION; g_iPlanEv534[r] = EV_NONE; }
for (new r = 2; r <= total; r++) if (!IsBossRound(r)) list[n++] = r;
new sp[MODE_TOTAL], ns;
for (new m = MODE_NEMESIS; m < MODE_BOSS; m++) sp[ns++] = m;
Shuffle534(sp, ns);
new bool:used[64], cnt = min(ns, n);
for (new i = 0; i < cnt; i++)
{
new idx = clamp((i * n) / cnt + (n / cnt) / 2, 0, n - 1);
while (used[idx]) idx = (idx + 1) % n;
used[idx] = true;
g_iPlanMode534[list[idx]] = sp[i];
}
new ev[EV_TOTAL], ne;
for (new e = EV_BLOODMOON; e < EV_TOTAL; e++) ev[ne++] = e;
Shuffle534(ev, ne);
new k, slot;
for (new idx = 0; idx < n; idx++)
{
if (used[idx]) continue;
new r = list[idx];
if (k < ne) g_iPlanEv534[r] = ev[k++];
if (slot++ % 4 == 1) g_iPlanMode534[r] = MODE_MULTI;
}
if (k < ne) g_iPlanEv534[1] = ev[k++];
new txt[512], len;
for (new r = 1; r <= total && len < charsmax(txt) - 12; r++)
len += formatex(txt[len], charsmax(txt) - len, "%d:%s%d ", r, IsBossRound(r) ? "B" : (g_iPlanMode534[r] >= MODE_NEMESIS ? "S" : (g_iPlanMode534[r] == MODE_MULTI ? "M" : "I")),
IsBossRound(r) ? 0 : (g_iPlanMode534[r] >= MODE_NEMESIS ? g_iPlanMode534[r] : g_iPlanEv534[r]));
log_amx("[Vexmira] tam rotasyon plani (%d round, %d ozel mod, %d/%d event): %s", total, cnt, k, ne, txt);
}
public cmd_Plan534(id)
{
if (id && !(get_user_flags(id) & ADMIN_BAN)) return PLUGIN_HANDLED;
if (!g_iPlanTotal534) BuildPlan534();
new txt[160], len;
console_print(id, "[Vexmira] rotasyon=%d round=%d/%d plan=%d", get_pcvar_num(g_pFullRot534), g_iRound, RoundsTotal(), g_iPlanTotal534);
for (new r = 1; r <= g_iPlanTotal534; r++)
{
new mk[24], ek[24];
formatex(mk, charsmax(mk), "MODE_NAME_%d", IsBossRound(r) ? MODE_BOSS : g_iPlanMode534[r]);
formatex(ek, charsmax(ek), "EV_NAME_%d", g_iPlanEv534[r]);
len = formatex(txt, charsmax(txt), "  %2d: %L", r, id ? id : LANG_SERVER, mk);
if (g_iPlanEv534[r] && !IsBossRound(r)) formatex(txt[len], charsmax(txt) - len, " + event %d", g_iPlanEv534[r]);
console_print(id, "%s%s", txt, r == g_iRound ? "   <== simdi" : "");
#pragma unused ek
}
return PLUGIN_HANDLED;
}
PickMode()
{
if (g_bModePicked47) return;
if (get_pcvar_num(g_pFullRot534) && (g_iPlanTotal534 != clamp(RoundsTotal(), 1, 63) || (g_iRound == 1 && !g_bPlanR1534)))
{ BuildPlan534(); g_bPlanR1534 = true; }
if (g_iRound > 1) g_bPlanR1534 = false;
new bool:plan = get_pcvar_num(g_pFullRot534) && g_iRound >= 1 && g_iRound <= g_iPlanTotal534 && g_iPlanTotal534 == clamp(RoundsTotal(), 1, 63);
g_bModePicked47 = true;
g_bForcedRound47 = (g_iForceMode >= 0);
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
else if (plan)
g_iMode = (players >= MODE_MINPL[g_iPlanMode534[g_iRound]]) ? g_iPlanMode534[g_iRound] : MODE_INFECTION;
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
new last = g_iEvent;
if (g_iMode != MODE_INFECTION && g_iMode != MODE_MULTI)
g_iEvent = EV_NONE;
else if (g_iForceEvent >= 0)
{
g_iEvent = g_iForceEvent;
g_iForceEvent = -1;
}
else if (plan)
g_iEvent = g_iPlanEv534[g_iRound];
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
for (new p = 1; p <= g_iMax; p++)
if (is_user_connected(p)) CsoNotify(p, CN_ROUND, g_iRound);
for (new p = 1; p <= g_iMax; p++)
{
if (is_user_connected(p) && !is_user_bot(p))
client_print_color(p, print_team_default, "%s %L", ChatTag("ROUND_CHAT2"), p, "ROUND_CHAT2", g_iRound, total);
}
AssignQuests();
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
for (new p = 1; p <= g_iMax; p++)
{
if (is_user_connected(p))
CsoNotify(p, CN_BOSS);
}
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
VexLocalizedAnnounceAll(key, 255, 170, 55, 3.6);
FadeAll(255, 80, 0, 50, 1.2);
BossTeaser();
return;
}
if (g_iEvent != EV_NONE)
{
formatex(key, charsmax(key), "EV_ANN_%d", g_iEvent);
new r, g, b;
EventColor(g_iEvent, r, g, b);
VexLocalizedAnnounceAll(key, r, g, b, 3.6);
EventStartFx();
}
BossTeaser();
}
BossTeaser()
{
}
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
OnRoundEnd(WinStatus:status)
{
VxClear();
if (g_bRoundEnded)
return;
g_bRoundEnded = true;
g_bCounting = false;
StopRoundMusic();
ZcCleanupAll();
OvhRemoveAll();
new bool:wasActive = g_bRoundActive;
g_bRoundActive = false;
MsRoundEnd(status, wasActive);
CsoFlushAll();
if (!wasActive)
return;
EpicRoundFinish(status);
if (status == WINSTATUS_CTS || status == WINSTATUS_TERRORISTS)
{
new note = status == WINSTATUS_CTS ? CN_HWIN : CN_ZWIN;
for (new p = 1; p <= g_iMax; p++)
if (is_user_connected(p)) CsoNotify(p, note);
}
if (status == WINSTATUS_CTS)
{
g_iHumanStreak++;
g_iZombieStreak = 0;
if (g_iHumanStreak >= 3)
LiveAll(0, "LIVE_HSTREAK", 2, g_iHumanStreak);
Radio52(5);
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
Radio52(6);
for (new id = 1; id <= g_iMax; id++)
{
if (is_user_connected(id) && g_bZombie[id] && !g_bMinion[id])
Reward(id, get_pcvar_num(g_pWinZXP), get_pcvar_num(g_pWinZAP));
}
}
if (status == WINSTATUS_CTS || status == WINSTATUS_TERRORISTS)
{
for (new id = 1; id <= g_iMax; id++)
{
if (is_user_connected(id) && !is_user_bot(id) && IsVip(id) && (g_bZombie[id] || is_user_alive(id)))
g_iVC[id] += VipRoundVC(id);
}
RoundSummary();
}
if (g_iRound >= RoundsTotal())
set_task(1.5, "task_MapEndAwards");
MapOnRoundEnd();
for (new id = 1; id <= g_iMax; id++)
{
if (is_user_connected(id))
SaveData(id);
}
SaveTop();
}
RoundSummary()
{
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
g_iRoundMvp = mvp;
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
CsoNotify(p, CN_MVP);
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
client_print_color(id, print_team_default, "%s", txt);
}
}
public task_MapEndAwards()
{
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
if (g_iCountdown <= 15) VexCountdown(p, g_iCountdown);
}
if (g_iCountdown <= 10)
{
if (g_bVoxCountdown)
{
new snd[32];
formatex(snd, charsmax(snd), "vexmira/epic/count/%s.wav", VOX_NUM[g_iCountdown]);
static cdHave[11]; new cdi = clamp(g_iCountdown, 0, 10);
if(!cdHave[cdi]) cdHave[cdi] = file_exists(fmt("sound/%s",snd),true) ? 1 : 2;
if(g_iEpicCountdown==1 || cdHave[cdi]==2) formatex(snd,charsmax(snd),"vox/%s.wav",VOX_NUM[g_iCountdown]);
for (new p = 1; p <= g_iMax; p++)
{
if (is_user_connected(p) && !(g_iSet[p] & SET_NO_AMB))
VxClientCmd527(p, "spk ^"%s^"", snd);
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
if (g_bWaiting)
{
if (CountPlaying() >= 2)
{
g_bWaiting = false;
ChatAll("GAME_COMMENCING");
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
if (g_iFrame % 130 == 65 && get_pcvar_num(g_pLiveChatter))
LiveChatter();
TickFlares();
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
if (g_iMode != MODE_BOSS && g_iFrame % 25 == 0 && random_num(1, 3) == 1)
{
for (new p = 1; p <= g_iMax; p++)
{
if (is_user_connected(p) && !(g_iSet[p] & SET_NO_AMB))
PlayKey(p, "AMBIENT");
}
}
TickAutoVote();
MapVoteTick();
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
TickMeteor()
{
if (g_iEvent != EV_METEOR)
return;
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
continue;
end[0] = out[0]; end[1] = out[1]; end[2] = out[2] - 512.0;
engfunc(EngFunc_TraceLine, out, end, IGNORE_MONSTERS, id, 0);
get_tr2(0, TR_flFraction, frac);
if (frac >= 1.0)
continue;
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
new Float:fall = 1.0 - 0.75 * (d / 220.0);
if (bossMeteor)
ExecuteHamB(Ham_TakeDamage, id, 0, (g_iBoss && is_user_connected(g_iBoss)) ? g_iBoss : 0, 30.0 * fall, DMG_BLAST);
else
ExecuteHamB(Ham_TakeDamage, id, 0, 0, g_bZombie[id] ? 150.0 * fall : 20.0 * fall, DMG_BLAST);
}
}
StartMode()
{
new players[32];
new n = GetHumans(players);
if (n < 2)
{
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
g_iCountdown = 1;
g_bCounting = true;
return;
}
g_bWaiting = true;
ShowWaiting();
return;
}
g_iStartTries = 0;
if (!g_bAnnounced)
{
remove_task(TASK_ANNOUNCE);
PickMode();
PickCalmPreset();
ApplyWorldEvent();
ApplyHostname();
task_Announce();
}
new required47 = g_bForcedRound47 ? 2 : MODE_MINPL[g_iMode];
if (n < required47)
{
log_amx("[Vexmira] Mode %d waiting: %d/%d players; selection preserved.", g_iMode, n, required47);
g_iCountdown = 5;
g_bCounting = true;
return;
}
g_bRoundActive = true;
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
EpicRoundStart();
for(new intro47=1;intro47<=g_iMax;intro47++) if(is_user_alive(intro47)) SigilSpawn47(intro47,g_bZombie[intro47]?1:0,2.5);
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
Radio52(1);
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
formatex(pkey, charsmax(pkey), "%s_YOU", key);
Chat(id, pkey);
if (g_bNemesis[id] || g_bAssassin[id])
Chat(id, "SKILL_KEYS_HINT");
HudTo(id, SL_PERS, CLR_WARN, 3.5, pkey);
}
#define VOTE_TIME 15
#define VOTE_OPTS 4
public cmd_vote(id)
{
if (!(get_user_flags(id) & ADMIN_BAN))
return PLUGIN_HANDLED;
StartVote(id, 1);
return PLUGIN_HANDLED;
}
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
new pool[32], n;
if (type == 1)
{
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
TickAutoVote()
{
new every = get_pcvar_num(g_pVoteEvery);
if (every <= 0 || g_iVoteType || g_bMapVoting || g_iForceMode >= 0 || g_iRound % every != 0)
return;
if (IsBossRound(g_iRound + 1) || RoundInList(g_pSpecialRounds, g_iRound + 1))
return;
if (RoundTimeLeft() == 75 && CountPlaying() >= 2)
StartVote(0, random_num(1, 3) == 1 ? 2 : 1);
}
public cmd_roundplan(id)
{
new list[128];
get_pcvar_string(g_pBossRounds, list, charsmax(list));
Chat(id, "PLAN_1", g_iRound, RoundsTotal());
client_print_color(id, print_team_default, "%s %L", ChatTag("PLAN_2"), id, "PLAN_2", list);
get_pcvar_string(g_pSpecialRounds, list, charsmax(list));
client_print_color(id, print_team_default, "%s %L", ChatTag("PLAN_3"), id, "PLAN_3", list);
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
engfunc(EngFunc_LightStyle, 0, "d");
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
public client_command(id)
{
if(!g_bRun526) return PLUGIN_CONTINUE;
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
public cmd_SixMemes(id)
{
g_iSet[id] ^= SET_NO_MEME;
client_print_color(id, print_team_default, "^4[VEXMIRA]^1 Meme sounds: %s", (g_iSet[id] & SET_NO_MEME) ? "OFF" : "ON");
return PLUGIN_HANDLED;
}
public cmd_SixStats(id, level, cid)
{
if (!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED;
console_print(id, "[Community] This map: attempts=%d entered=%d download-stage exits=%d exits-under-120s=%d", g_iSixAttempts,g_iSixEntered,g_iSixAborted,g_iSixShort);
console_print(id, "[Community] Log: addons/amxmodx/logs/vexmira_connections.log. Stage labels do not prove the cause.");
for (new sw;sw<NUM_SPECIAL;sw++) console_print(id,"[Arsenal8] weapon=%s ready=%d",V50_NAMES[sw],g_bVxReady[sw]);
return PLUGIN_HANDLED;
}
SixConnect(id)
{
g_fSixConnect[id]=get_gametime(); g_fSixEnter[id]=0.0;g_fSixMemeNext[id]=0.0;
g_bSixEntered[id]=false;g_bSixTracked[id]=!is_user_bot(id)&&!is_user_hltv(id);
if (!g_bSixTracked[id]) return;
g_iSixAttempts++;
if (get_pcvar_num(g_pSixLog)) log_to_file("vexmira_connections.log","CONNECT userid=%d",get_user_userid(id));
}
SixEnter(id)
{
if (!g_bSixTracked[id]) return;
g_bSixEntered[id]=true;g_fSixEnter[id]=get_gametime();g_iSixEntered++;
if(get_pcvar_num(g_pSixLog)) log_to_file("vexmira_connections.log","ENTER userid=%d connect_to_enter=%.1f",get_user_userid(id),g_fSixEnter[id]-g_fSixConnect[id]);
}
SixLeave(id, bool:drop, const reason[])
{
if (!g_bSixTracked[id]) return;
new clean[128];copy(clean,charsmax(clean),reason);replace_all(clean,charsmax(clean),"^n"," ");replace_all(clean,charsmax(clean),"^r"," ");
new Float:session=g_bSixEntered[id]?get_gametime()-g_fSixEnter[id]:0.0;
if(drop)
{
if(!g_bSixEntered[id])g_iSixAborted++;
else if(session<120.0)g_iSixShort++;
}
if(get_pcvar_num(g_pSixLog))log_to_file("vexmira_connections.log","LEAVE userid=%d entered=%d drop=%d connection=%.1f session=%.1f reason=%s",get_user_userid(id),g_bSixEntered[id],drop,get_gametime()-g_fSixConnect[id],session,clean);
g_bSixTracked[id]=false;
}
public client_connect(id)
{
if(!g_bRun526) return;
SixConnect(id);
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
ZcCore_client_putinserver(id)
{
SixEnter(id);
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
set_task(2.5, "task_JoinAnnounce", id + TASK_JOIN);
set_task(25.0, "task_Welcome", id + TASK_WELCOME2);
}
public cmd_jointeam(id)
{
if (!get_pcvar_num(g_pAutoJoinHumans))
return PLUGIN_CONTINUE;
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
if(!g_bRun526) return;
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
ZcCore_client_disconnected(id, bool:drop, message[], maxlen)
{
CameraRemove47(id);
BannerRemove47(id);
GaugeRemove47(id);
g_bThird47[id] = false;
#pragma unused maxlen
CommunityRemoveWeapons(id);
CommunityRemoveKnives(id);
remove_task(id + 64000);
SixLeave(id, drop, message);
VxClear(id); g_bVxRightHeld[id] = false;
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
if (drop && is_user_connected(id) && get_pcvar_num(g_pJoinMsg))
LiveLeave(id);
if (g_bSlotting[id])
g_iAP[id] += g_iSlotBet[id];
if (!drop && g_iTickets[id] > 0)
g_iAP[id] += g_iTickets[id] * 10;
g_iBounty[id] = 0;
g_iTickets[id] = 0;
g_bSlotting[id] = 0;
StoreRoundBuys(id);
SaveData(id);
new bool:wasZombie = g_bZombie[id] ? true : false;
if (g_bBoss[id])
g_iBoss = 0;
VoteDisconnect(id);
MapVoteDisconnect(id);
ResetPlayer(id);
RtvCheck(id);
if (g_bRoundActive && !g_bRoundEnded && wasZombie && AllowsInfection())
{
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
g_iCosOwned[id] = 0; g_iTrailSel[id] = 0; g_iKfxSel[id] = 0; g_iIfxSel[id] = 0; g_iLzOwned531[id] = 0; g_iLzSel531[id] = 0;
g_iCmOwned[id] = 0; g_iCmSelPk[id] = 0;
for (new c = 0; c < 2; c++) { g_iCommunityOwned[id][c] = 0; g_iCommunitySel[id][c] = 0; }
g_szKey[id][0] = 0; g_bLoaded[id] = false; g_iClassNext[id] = -1; g_iJobNext[id] = -1;
g_bTrailOn[id] = false;
g_bLmGiven[id] = false;
g_iAfkSec[id] = 0;
g_fNextBeat[id] = 0.0;
for (new i = 0; i < NUM_PERKS; i++)
g_iPerk[id][i] = 0;
g_iHumanSkin[id] = g_iHumanModelN > 0 ? random(g_iHumanModelN) : 0;
if (g_iRoundMvp == id)
g_iRoundMvp = 0;
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
ZcCleanup(id);
g_fLeapCool[id] = 0.0;
g_fSkillTrig[id][0] = 0.0; g_fSkillTrig[id][1] = 0.0; g_fSkillTrig[id][2] = 0.0;
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
ApplyLanguage(id)
{
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
public client_infochanged(id)
{
if(!g_bRun526) return;
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
public cmd_menu(id)
{
new TeamName:t = get_member(id, m_iTeam);
if (t != TEAM_TERRORIST && t != TEAM_CT)
return PLUGIN_CONTINUE;
ShowMainMenu(id);
return PLUGIN_HANDLED;
}
public cmd_nvg(id)
{
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
SayHandler(id, bool:teamOnly)
{
new msg[160];
read_args(msg, charsmax(msg));
remove_quotes(msg);
trim(msg);
if (!msg[0] || msg[0] == '@')
return PLUGIN_CONTINUE;
if (msg[0] == '/' || msg[0] == '!')
{
if (HandleArgCommand(id, msg) || RunChatCommand(id, msg))
return PLUGIN_HANDLED;
return PLUGIN_CONTINUE;
}
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
static const PASS[][] = { "rtv", "rockthevote", "nominate", "nextmap", "timeleft", "thetime", "currentmap", "ff", "motd" };
for (new i = 0; i < sizeof PASS && !mapWord; i++)
{
if (equali(msg, PASS[i]) || (containi(msg, PASS[i]) == 0 && msg[strlen(PASS[i])] == ' '))
return PLUGIN_CONTINUE;
}
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
new bc[3];
if (flags & (ADMIN_RCON | ADMIN_BAN))
copy(bc, charsmax(bc), "^4");
else if (IsVip(id))
copy(bc, charsmax(bc), "^3");
else
copy(bc, charsmax(bc), "^1");
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
if (g_iJob[id] == JOB_GUNNER && g_iFrame % 10 == 0)
RefillAmmo(id);
if (g_bSurvivor[id] || g_bSniper[id])
FxLight(o, 0, 120, 255, 20, 11, 5);
if (g_iEvent == EV_SPEED && g_iFrame % 2 == 0)
FxFollow(id, 0, 220, 255, 6, 4);
if (get_entvar(id, var_health) < 30.0 && !is_user_bot(id))
{
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
Radio52(4);
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
public rg_PlayerSpawn(id)
{
BannerRemove47(id);
GaugeRemove47(id);
CommunityReset(id);
set_task(0.5, "CommunityApplyKnife", id + 64000);
if (!is_user_alive(id))
return;
g_fRespawnAt[id] = 0.0;
ResetLifeData(id);
MsOnSpawn(id);
set_task(0.7,"EpicVipSpawn",id+TASK_EPIC_SPAWN);
g_iCsoIcon[id] = 0;
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
new armor = 15 * g_iPerk[id][PK_PLATING];
if (g_iJob[id] == JOB_HEAVY) armor += 100;
if (g_iJob[id] == JOB_ELITE) armor += 25;
armor += VipArmor(id);
if (armor > 0)
rg_set_user_armor(id, min(armor, 250), ARMOR_VESTHELM);
if (IsVip(id))
ApplyRender(id);
SyncMoney(id);
GiveRoundMines(id);
remove_task(id + TASK_LOADOUT);
set_task(0.3, "task_Loadout", id + TASK_LOADOUT);
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
GiveStartNades(id);
if (IsVip(id) && get_pcvar_num(g_pVipAutoPack) && !g_bVipFreeUsed[id])
VipFreePack(id);
}
public rg_TakeDamage(victim, inflictor, attacker, Float:damage, bits)
{
if (!is_user_connected(victim))
return HC_CONTINUE;
if (!g_bRoundActive)
{
SetHookChainReturn(ATYPE_INTEGER, 0);
return HC_SUPERCEDE;
}
new Float:now = get_gametime();
new Float:dmg = damage;
if (!g_bZombie[victim] && ZcCall(ZC_HEV, ZCOP_has, victim)) dmg *= 0.8;
new bool:isPlayer = (1 <= attacker <= g_iMax && attacker != victim && is_user_connected(attacker)) ? true : false;
g_iReflVictim = 0;
if (g_bZombie[victim] && g_fMadness[victim] > now)
{
SetHookChainReturn(ATYPE_INTEGER, 0);
return HC_SUPERCEDE;
}
if ((g_bZombie[victim] && g_fBurrow[victim] > now) || (isPlayer && g_bZombie[attacker] && g_fBurrow[attacker] > now))
{
SetHookChainReturn(ATYPE_INTEGER, 0);
return HC_SUPERCEDE;
}
if ((bits & DMG_BURN) && IsClassZombie(victim, ZC_MAGMA) && get_pcvar_num(g_pZc[ZCV_MAG_IMMUNE]))
{
if (isPlayer && !is_user_bot(attacker) && random_num(1, 4) == 1)
SkillDeny(attacker, "MAGMA_IMMUNE");
SetHookChainReturn(ATYPE_INTEGER, 0);
return HC_SUPERCEDE;
}
if (isPlayer)
{
if (g_bZombie[attacker] && !g_bZombie[victim])
{
if (inflictor != attacker)
return HC_CONTINUE;
FxClawHit(victim);
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
if (g_iJob[victim] == JOB_LUCKY && random_num(1, 100) <= 7)
{
Chat(victim, "LUCKY_DODGE");
SetHookChainReturn(ATYPE_INTEGER, 0);
return HC_SUPERCEDE;
}
if (vxe_mask_block(victim, attacker))
{
SetHookChainReturn(ATYPE_INTEGER, 0);
return HC_SUPERCEDE;
}
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
dmg = 9999.0;
}
else
dmg = get_pcvar_float(g_pZombieDmg) * mimicMult;
if (g_bRage[attacker] && dmg < 9000.0)
dmg *= 1.0 + float(max(0, ITEM_VAL[IT_RAGE])) / 100.0;
if (g_bAlpha[attacker] && dmg < 9000.0)
dmg *= 1.2;
}
else if (!g_bZombie[attacker] && g_bZombie[victim])
{
new Float:m = 1.0;
new WeaponIdType:wid = GetActiveWeaponId(attacker);
new bool:bulletHit = (inflictor == attacker && (bits & DMG_BULLET)) ? true : false;
new bool:headshot = (bulletHit && get_member(victim, m_LastHitGroup) == HIT_HEAD) ? true : false;
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
new sw = SpecialIndex(attacker, wid), Float:sg538 = 0.0;
if (sw >= 0 && inflictor == attacker && (bits & DMG_BULLET))
m *= SW_MULT[sw] * floatclamp(get_pcvar_float(g_pSwDmg531), 0.1, 20.0);
else if (bulletHit && sw < 0 && ms < 0 && (sg538 = vxe_sw_hit(attacker, victim, _:wid, headshot, (g_bBoss[victim] || g_bNemesis[victim] || g_bAssassin[victim]) ? 1 : 0)) > 0.0)
m *= sg538 * floatclamp(get_pcvar_float(g_pSwDmg531), 0.1, 20.0);
else if (bulletHit && ms < 0)
m *= floatclamp(get_pcvar_float(g_pGunDmg536), 0.1, 10.0);
else if (!bulletHit && wid == WEAPON_KNIFE && g_iCommunitySel[attacker][1] >= 1 && g_iCommunitySel[attacker][1] <= KN_TOTAL)
{
if (g_iCommunitySel[attacker][1] <= 4) m *= floatclamp(get_pcvar_float(g_pSkDmg538), 0.1, 20.0);
SkKnock538(victim, attacker, g_iCommunitySel[attacker][1] >= 5 ? g_fMkKb[g_iCommunitySel[attacker][1] - 5] : 1.0);
}
if (bulletHit && headshot && g_bZombie[victim]) Polish536_HeadshotSnd(attacker);
dmg *= m;
if (g_bZombie[victim] && !g_bBoss[victim]) dmg = vxe_zarmor_hit(victim, dmg);
if (g_bBoss[victim] || g_bNemesis[victim] || g_bAssassin[victim])
dmg = floatmin(dmg, floatmax(100.0, get_pcvar_float(g_pSpecCap)));
}
}
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
if (g_bHm538 && damage > 0.0 && 1 <= attacker <= g_iMax && attacker != victim && 1 <= victim <= g_iMax && g_bZombie[victim] && !g_bZombie[attacker] && is_user_alive(victim))
HitMark538(attacker, (bits & DMG_BULLET) && get_member(victim, m_LastHitGroup) == HIT_HEAD ? 1 : 0);
if (1 <= victim <= g_iMax && g_iPlantAction[victim] == 2 && damage > 0.0)
LmTakeCancel(victim, "LM_TAKE_HURT");
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
if (bullet && get_pcvar_num(g_pKnockback))
{
new Float:kbDamage = damage;
if (fx == SWE_VOID)
kbDamage *= 1.35;
ApplyKnockback(victim, attacker, wid, kbDamage);
}
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
if (g_iJob[attacker] == JOB_PYRO && random_num(1, 100) <= 15)
Ignite(victim, attacker, 3);
if (g_iJob[attacker] == JOB_CRYO && random_num(1, 100) <= 10)
Freeze(victim, 1.0);
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
new Float:force = floatmin(damage * power * 0.35, floatclamp(get_pcvar_float(g_pKBMax536), 100.0, 2000.0));
get_entvar(victim, var_velocity, vel);
vel[0] += dir[0] / len * force;
vel[1] += dir[1] / len * force;
set_entvar(victim, var_velocity, vel);
if (g_iDirLogN[DIR_KNOCK] < DIR_LOG_MAX && get_pcvar_num(g_pDbgDirs))
{
new Float:add[3];
add[0] = dir[0] / len * force;
add[1] = dir[1] / len * force;
DirCheck(DIR_KNOCK, "knockback", add, dir);
}
}
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
if (g_bHm538 && 1 <= attacker <= g_iMax && attacker != victim && g_bZombie[victim] && !g_bZombie[attacker]) HitMark538(attacker, 2);
if (1 <= attacker <= g_iMax && attacker != victim && g_bZombie[attacker] && !g_bZombie[victim] && !g_bBoss[attacker] && !g_bNemesis[attacker] && !g_bAssassin[attacker]) vxe_zup_add(attacker, 2);
CameraRemove47(victim);
GaugeRemove47(victim);
BannerShow47(victim,3,3.5);
if(attacker>=1 && attacker<=32 && attacker!=victim && is_user_alive(attacker) && IsVip(attacker) && (g_iSet[attacker]&E46_VIP_KILL)) EpicVipFx(attacker);
CommunityRemoveWeapons(victim);
CommunityRemoveKnives(victim);
remove_task(victim + 64000);
new bool:valid = (1 <= attacker <= g_iMax && attacker != victim && is_user_connected(attacker)) ? true : false;
ZcCleanup(victim);
OvhRemove(victim);
g_iSpecW[victim] = 0;
if (valid && g_bBoss[attacker] && !g_bZombie[victim])
BossKillTaunt(attacker);
new Float:o[3];
get_entvar(victim, var_origin, o);
if (g_bBoss[victim] || g_bNemesis[victim] || g_bAssassin[victim])
{
if(attacker>=1 && attacker<=32 && attacker!=victim && is_user_alive(attacker) && IsVip(attacker) && (g_iSet[attacker]&E46_VIP_KILL)) EpicVipFx(attacker);
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
if(attacker>=1 && attacker<=32 && attacker!=victim && is_user_alive(attacker) && IsVip(attacker) && (g_iSet[attacker]&E46_VIP_KILL)) EpicVipFx(attacker);
ChatAllS(g_bNemesis[victim] ? "NEMESIS_DOWN" : "ASSASSIN_DOWN", name);
if (!EmitSpecialSound(victim, "DEATH", CHAN_VOICE, ATTN_NONE))
PlayKey(0, "BOSS_DEATH");
}
if (valid && !g_bZombie[attacker])
{
if(attacker>=1 && attacker<=32 && attacker!=victim && is_user_alive(attacker) && IsVip(attacker) && (g_iSet[attacker]&E46_VIP_KILL)) EpicVipFx(attacker);
g_iBossK[attacker]++;
g_iVC[attacker] += g_bBoss[victim] ? get_pcvar_num(g_pBossKillVC) : max(0, get_pcvar_num(g_pBossKillVC) - 1);
Reward(attacker, get_pcvar_num(g_bBoss[victim] ? g_pBossKillXP : g_pSpecKillXP), get_pcvar_num(g_bBoss[victim] ? g_pBossKillAP : g_pSpecKillAP));
}
if (valid && !g_bZombie[attacker])
{
if(attacker>=1 && attacker<=32 && attacker!=victim && is_user_alive(attacker) && IsVip(attacker) && (g_iSet[attacker]&E46_VIP_KILL)) EpicVipFx(attacker);
for (new p = 1; p <= g_iMax; p++)
{
if(attacker>=1 && attacker<=32 && attacker!=victim && is_user_alive(attacker) && IsVip(attacker) && (g_iSet[attacker]&E46_VIP_KILL)) EpicVipFx(attacker);
if (is_user_alive(p) && !g_bZombie[p] && p != attacker)
Reward(p, 30, 5);
}
}
}
else if (g_bZombie[victim])
{
if(attacker>=1 && attacker<=32 && attacker!=victim && is_user_alive(attacker) && IsVip(attacker) && (g_iSet[attacker]&E46_VIP_KILL)) EpicVipFx(attacker);
FxBlood(o, 12);
FxParticles(o, 40, 70, 6);
if (g_iClass[victim] == 6 && !g_bMinion[victim])
BomberExplode(victim, o);
if (valid && !g_bZombie[attacker])
{
if(attacker>=1 && attacker<=32 && attacker!=victim && is_user_alive(attacker) && IsVip(attacker) && (g_iSet[attacker]&E46_VIP_KILL)) EpicVipFx(attacker);
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
if(attacker>=1 && attacker<=32 && attacker!=victim && is_user_alive(attacker) && IsVip(attacker) && (g_iSet[attacker]&E46_VIP_KILL)) EpicVipFx(attacker);
Reward(attacker, 10, 3);
}
if (valid)
PayBounty(attacker, victim);
g_iBounty[victim] = 0;
if (!g_bZombie[victim] && !get_pcvar_num(g_pLmKeep534))
RemovePlayerMines(victim, true);
if (g_bZombie[victim] && g_bRoundActive && AllowsRespawn() && !g_bMinion[victim] && !is_user_bot(victim))
Chat(victim, "YOU_DIED_ZOMBIE", floatround(RespawnDelay(victim)));
g_bBoss[victim] = 0;
KillTrail(victim);
g_fShield[victim] = 0.0; g_fCloak[victim] = 0.0; g_fMadness[victim] = 0.0;
g_fFrozen[victim] = 0.0; g_fSlow[victim] = 0.0;
g_iBurn[victim] = 0;
g_iStreak[victim] = 0;
set_user_rendering(victim);
if (g_bRoundActive && AllowsRespawn() && !g_bMinion[victim] && RoundTimeLeft() > 20)
g_fRespawnAt[victim] = get_gametime() + RespawnDelay(victim);
else
g_fRespawnAt[victim] = 0.0;
CheckWin();
}
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
if (now - g_fLastKill[attacker] <= floatclamp(get_pcvar_float(g_pComboTime), 2.0, 15.0))
g_iMulti[attacker]++;
else
g_iMulti[attacker] = 1;
g_fLastKill[attacker] = now;
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
public fw_ClientKill(id)
{
if (is_user_alive(id) && (g_bBoss[id] || g_bNemesis[id] || g_bAssassin[id] || g_bSurvivor[id] || g_bSniper[id]))
{
Chat(id, "NO_SUICIDE");
return FMRES_SUPERCEDE;
}
return FMRES_IGNORED;
}
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
public fw_EmitSound(ent, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
if(!g_bEmitting && ent>=1 && ent<=g_iMax && !g_bZombie[ent] && equal(sample,"weapons/zoom.wav")) {
EmitSafe(ent,channel,"vexmira/arena52/foley/scope.wav",0.6,attn,flags,pitch);return FMRES_SUPERCEDE;
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
new key[24], path[256];
if (g_bBoss[ent] || g_bNemesis[ent] || g_bAssassin[ent])
{
new r = SpecialVoice(ent, ev);
if (r != -1)
return r;
if (equal(ev, "PAIN"))
return equal(sample, "player/pl_pain", 14) ? FMRES_SUPERCEDE : FMRES_IGNORED;
}
formatex(key, charsmax(key), "Z%d_%s", g_iClass[ent], ev);
if ((!TrieGetString(g_tRes, key, path, charsmax(path)) || !path[0])
&& (!TrieGetString(g_tRes, fallback, path, charsmax(path)) || !path[0]))
return FMRES_IGNORED;
SndPick531(path, charsmax(path));
if (containi(path, ".mp3") != -1 || equal(path, sample))
return FMRES_IGNORED;
EmitSafe(ent, channel, path, volume, attn, flags, pitch);
return FMRES_SUPERCEDE;
}
public fw_PreThink(id)
{
CameraTick47(id);
CommunityPetMove49(id);
CosTick50(id);
VxReloadTick50(id);
UiHudTick52(id);
BannerTick47(id);
GaugeTick47(id);
if (!is_user_alive(id))
return FMRES_IGNORED;
ZcPreThink(id);
if (!is_user_alive(id))
return FMRES_IGNORED;
FixGravity(id);
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
#define HUB_MARKET   201
#define HUB_CLASS    202
#define HUB_CHAR     203
#define HUB_FUN      204
#define HUB_VIPADM   205
#define HUB_BACK     99
new const HUB_MARKET_ITEMS[] = { 1, 2, 18, 19 };
new const HUB_CLASS_ITEMS[]  = { 4, 5, 23 };
new const HUB_CHAR_ITEMS[]   = { 31, 20, 32, 33, 34, 16, 22 };
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
formatex(item, charsmax(item), "\rVexCoin Market"); MenuAdd(menu, item, 21);
menu_addblank(menu, 0);
formatex(item, charsmax(item), "\y%L", id, "MAINH_7"); MenuAdd(menu, item, 11);
formatex(item, charsmax(item), "\y%L%s", id, adm ? "MAINH_8A" : "MAINH_8", IsVip(id) ? " \y[*]" : "");
MenuAdd(menu, item, adm ? HUB_VIPADM : 8);
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
case 23: amxclient_cmd(id, "vex_zup"); // 5.3.9c: zombie class upgrade menu (vexmira_extra)
case 31: ShowCard(id, id);
case 32: ShowAchMenu(id);
case 33: ShowTitleMenu(id);
case 34: ShowStyleMenu(id);
case HUB_BACK: ShowMainMenu(id);
case HUB_MARKET, HUB_CLASS, HUB_CHAR, HUB_FUN, HUB_VIPADM: ShowHub(id, sel);
}
}
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
formatex(item,charsmax(item),"\yTelsiz konusmalari \r[%s]",(g_iSet[id]&SET_NO_RADIO52)?"KAPALI":"ACIK");MenuAdd(menu,item,24);
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
if (sel == 3) AmbientClient49(id);
}
else if(sel==24) g_iSet[id]^=SET_NO_RADIO52;
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
ShowMainMenu(id);
return PLUGIN_HANDLED;
}
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
case 1:
{
g_iSet[id] |= (SET_NO_FX | SET_NO_FOG | SET_NO_AMB | SET_NO_DMGNUM);
Chat(id, "FPS_PRESET_PERF");
}
case 2:
{
g_iSet[id] &= ~(SET_NO_FX | SET_NO_DMGNUM);
g_iSet[id] |= (SET_NO_FOG | SET_NO_AMB);
Chat(id, "FPS_PRESET_BAL");
}
case 3:
{
g_iSet[id] &= ~(SET_NO_FX | SET_NO_FOG | SET_NO_AMB | SET_NO_DMGNUM);
Chat(id, "FPS_PRESET_CINE");
}
case 4: PrintFpsConfig(id);
case 5: PrintNetConfig(id);
}
SendFogForEvent(id);
AmbientClient49(id);
SaveData(id);
if (sel <= 3)
ShowFpsMenu(id);
return PLUGIN_HANDLED;
}
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
VxClientCmd527(id, "spk buttons/blip1");
new p2[2];
p2[0] = id;
p2[1] = frame + 1;
set_task(0.3, "task_SlotFrame", TASK_SLOT + id, p2, 2);
return;
}
new a = random(sizeof SLOT_SYM), b = random(sizeof SLOT_SYM), c = random(sizeof SLOT_SYM);
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
LiveChatter()
{
new pick = random_num(1, 5);
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
LiveAll(0, "LIVE_RANDOM", 10);
}
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
case 20: AdminStartMapVote(id, true);
}
if (sel >= 11 && sel != 20)
ShowAdminMenu(id);
return PLUGIN_HANDLED;
}
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
ShowAdminBossMenu(id, bool:now)
{
new title[320], item[96], key[16];
VexHead(id, title, charsmax(title), "ADM_BOSS_PICK");
new menu = VexMenuCreate(title, now ? "menu_admboss_now" : "menu_admboss_next");
formatex(item, charsmax(item), "\y%L", id, "ADM_BOSS_RANDOM");
MenuAdd(menu, item, 99);
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
MenuAdd(menu,"\yOzel Silah / Jetpack Ver",18);
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
if(sel==18) { CommunityAdminEquipment(id); return PLUGIN_HANDLED; }
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
public fw_AmbientPost(ent, const Float:pos[3], const sample[], Float:vol, Float:attn, flags, pitch)
{
if (g_bAmbReplay || ent <= MaxClients || !pev_valid(ent) || !sample[0])
return FMRES_IGNORED;
new cls[20];
pev(ent, pev_classname, cls, charsmax(cls));
if (!equal(cls, "ambient_generic") || (pev(ent, pev_spawnflags) & 32))
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
g_bAmbOn[slot] = true;
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
#define ME_NUM        12
#define ME_MAXENT     256
#define MS_MAXCMD     48
#define MS_MAXMSG     32
#define MS_MAXEX      32
#define MS_LEN        112
#define MS_CHART      0.035
#define TASK_MSSTORY  42000
#define TASK_MSEX     42100
#define TASK_MSRS     42200
new const ME_NAME[ME_NUM][] = { "round_start", "freeze_end", "infection", "boss", "boss_dead", "nemesis",
"assassin", "survivor", "lasthuman", "win_humans", "win_zombies", "minute" };
#define MC_MSG 1
#define MC_RH  2
#define MC_RZ  3
#define MC_OBJ 4
#define MC_RADIO 5
#define MC_FX  6
new g_pMsStory, g_pMsObj, g_pMsMarkers, g_pMsRewards, g_pMsEvents, g_pMsDebug;
new g_iMeEnt[ME_MAXENT], g_iMeTn[ME_MAXENT], g_iMeN, g_iMeFirst[ME_NUM], g_iMeCnt[ME_NUM];
new bool:g_bMsIni, g_szMsName[2][48];
new g_szMsStory[2][6][MS_LEN], g_iMsStoryN[2];
new g_szMsObj[2][3][MS_LEN], g_iMsObjN;
new g_szMsMsgKey[MS_MAXMSG][24], g_szMsMsg[MS_MAXMSG][2][MS_LEN], g_iMsMsgN;
new g_iMsExEv[MS_MAXEX], Float:g_fMsExDelay[MS_MAXEX], g_iMsExFirst[MS_MAXEX], g_iMsExCnt[MS_MAXEX], g_iMsExN;
new g_szMsMkName[MS_MAXMK][2][32], Float:g_fMsMkPos[MS_MAXMK][3], g_iMsMkSpr[MS_MAXMK], g_iMsMkBeam[MS_MAXMK], g_iMsMkN;
new g_iMsCmdOf[OVH_MAXENT];
new g_iMsCmdType[MS_MAXCMD], g_iMsCmdArg[MS_MAXCMD], g_iMsCmdRound[MS_MAXCMD], Float:g_fMsCmdNext[MS_MAXCMD], g_iMsCmdN;
new g_iMsRound = 1, bool:g_bMsObjDone[3], bool:g_bMsLive, g_iMsSec, Float:g_fMsMsgNext;
new bool:g_bMsSeen[33], g_iMsStep[33], g_iMsTries[33];
new g_szMsSndLine[96], g_szMsSndMsg[96], g_szMsSndObj[96];
#define MS_MAXLK 8
new g_szMsLkTn[MS_MAXLK][32], g_szMsLkKey[MS_MAXLK][24], g_iMsLkObj[MS_MAXLK], bool:g_bMsLkHint[MS_MAXLK];
new g_iMsLkMsg[MS_MAXLK], g_iMsLkRound[MS_MAXLK], g_iMsLkN, bool:g_bMsSeq;
new Float:g_fMsRoundTime, g_pMsRoundTime;
new g_iMsLockOf[OVH_MAXENT];
new Float:g_fMsLkNext[33];
#define MS_MAXRADIO   32
#define MS_MAXMODEL   160
#define MS_MAXFX      192
#define MS_MAXFXKEY   64
#define MS_MAXAMB     16
#define MS_AMBPICK    6
#define TASK_MSFX     43000
#define TASK_MSRADIO  42400
#define MFX_FLARE   1
#define MFX_SMOKE   2
#define MFX_SPARKS  3
#define MFX_DUST    4
#define MFX_RING    5
#define MFX_LIGHT   6
#define MFX_SPOT    7
#define MFX_BOOM    8
#define MFX_SHAKE   9
#define MFX_CLEAR   10
#define MFX_SAFE    11
#define MFX_UNSTUCK 12
#define MFX_SND     13
#define MFX_FOG     14
#define TASK_MSFOG  42700
new const MFX_NAME[][] = { "", "flare", "smoke", "sparks", "dust", "ring", "light", "spot", "boom", "shake",
"clear", "safe", "unstuck", "snd", "fog" };
new g_szRdKey[MS_MAXRADIO][24], g_szRdFile[MS_MAXRADIO][2][48], g_szRdSub[MS_MAXRADIO][2][MS_LEN];
new Float:g_fRdLen[MS_MAXRADIO], bool:g_bRdChat[MS_MAXRADIO], bool:g_bRdLow[MS_MAXRADIO], Float:g_fRdNext[MS_MAXRADIO], g_iRdN, g_iRdChatN;
new Float:g_fRdBusy, g_iRdPending = -1, g_iRdLastChat = -1, g_iRdChatIn, g_iRdLock = -1;
new g_iMsMsgRadio[MS_MAXMSG], g_iMeRadio[ME_NUM], g_pMsRadio, g_pMsChatter;
new g_szMmPath[MS_MAXMODEL][64], Float:g_fMmPos[MS_MAXMODEL][4], g_szMmFollow[MS_MAXMODEL][32], g_szMmName[MS_MAXMODEL][32];
new g_iMmSeq[MS_MAXMODEL], Float:g_fMmFr[MS_MAXMODEL], g_iMmRm[MS_MAXMODEL], g_iMmRa[MS_MAXMODEL], g_iMmFx[MS_MAXMODEL];
new g_iMmCol[MS_MAXMODEL], g_iMmBody[MS_MAXMODEL], g_iMmSkin[MS_MAXMODEL], Float:g_fMmScale[MS_MAXMODEL], g_iMmEnt[MS_MAXMODEL], g_iMmN;
new g_iMmTgt[MS_MAXMODEL], bool:g_bMmBrkHook;
new g_szFxKey[MS_MAXFXKEY][24], g_iFxKeyN;
new g_iFxKeyOf[MS_MAXFX], g_iFxType[MS_MAXFX], Float:g_fFxPos[MS_MAXFX][3], g_iFxEnt[MS_MAXFX], Float:g_fFxP[MS_MAXFX][6];
new Float:g_fFxDelay[MS_MAXFX], g_iFxRep[MS_MAXFX], Float:g_fFxDt[MS_MAXFX], g_iFxCol[MS_MAXFX], g_iFxLeft[MS_MAXFX], g_iFxN;
new g_szFxSnd[MS_MAXFX][48], g_iMsMsgFx[MS_MAXMSG], g_iMeFx[ME_NUM];
new g_iAmbFx[MS_MAXAMB][MS_AMBPICK], g_iAmbFxN[MS_MAXAMB], g_iAmbMin[MS_MAXAMB], g_iAmbMax[MS_MAXAMB], g_iAmbIn[MS_MAXAMB];
new g_iAmbLast[MS_MAXAMB], g_iMsAmbN, g_pMsAmb;
stock MsLang(id)
{
return g_iLang[id] == 2 ? 1 : 0;
}
MsInit()
{
g_pMsStory   = register_cvar("vex_map_story", "1");
g_pMsObj     = register_cvar("vex_map_objectives", "1");
g_pMsMarkers = register_cvar("vex_map_markers", "1");
g_pMsRewards = register_cvar("vex_map_rewards", "1");
g_pMsEvents  = register_cvar("vex_map_events", "1");
g_pMsDebug   = register_cvar("vex_map_debug", "0");
g_pMsRoundTime = register_cvar("vex_roundtime", "0");
g_pMsRadio   = register_cvar("vex_map_radio", "1");
g_pMsChatter = register_cvar("vex_map_chatter", "70");
g_pMsAmb     = register_cvar("vex_map_ambience", "100");
RegisterSay("story", "hikaye", "cmd_MsStory");
register_srvcmd("vex_map_status", "srv_MsStatus");
TrieGetString(g_tRes, "UI_OPEN", g_szMsSndLine, charsmax(g_szMsSndLine));
TrieGetString(g_tRes, "ZONE_WARN", g_szMsSndMsg, charsmax(g_szMsSndMsg));
TrieGetString(g_tRes, "QUEST_DONE", g_szMsSndObj, charsmax(g_szMsSndObj));
MsModelsSpawn();
MsLoadIni();
MsRadioLink();
new name[32];
for (new e = 0; e < ME_NUM; e++)
{
formatex(name, charsmax(name), "vex_%s", ME_NAME[e]);
g_iMeFirst[e] = g_iMeN;
g_iMeCnt[e] = MsCollect(name);
}
new ent = -1, tn[64];
while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "trigger_relay")) > 0)
{
pev(ent, pev_targetname, tn, charsmax(tn));
if (equal(tn, "vexcmd_", 7) && ent < OVH_MAXENT)
MsParseCmd(ent, tn);
}
if (g_iMsCmdN)
VxRegisterHam524(Ham_Use, "trigger_relay", "fw_MsRelayUse", 0);
for (new m = 0; m < g_iMsMkN; m++)
MsMkCreate(m);
MsLockInit();
new total;
for (new e = 0; e < ME_NUM; e++)
total += g_iMeCnt[e];
log_amx("[Vexmira] Harita senaryosu: ini=%d hikaye=%d/%d gorev=%d mesaj=%d ek-olay=%d isaret=%d | vex_* hedef=%d vexcmd=%d",
g_bMsIni, g_iMsStoryN[0], g_iMsStoryN[1], g_iMsObjN, g_iMsMsgN, g_iMsExN, g_iMsMkN, total, g_iMsCmdN);
}
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
VxRegisterHam524(Ham_Use, "func_button", "fw_MsButtonUse", 0);
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
MsRadio(g_iMsMsgRadio[msg], 0.3);
return HAM_IGNORED;
}
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
MsRadioTo(g_iRdLock, activator);
}
return HAM_IGNORED;
}
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
g_iMeTn[g_iMeN] = pev(ent, pev_targetname);
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
else if (equal(tn[7], "radio_", 6))
{
type = MC_RADIO;
arg = MsRadioFind(tn[13]);
}
else if (equal(tn[7], "fx_", 3))
{
type = MC_FX;
for (new k = 0; k < g_iFxKeyN; k++)
{
if (equali(tn[10], g_szFxKey[k]))
arg = k;
}
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
MsApplyRoundTime()
{
new Float:rt = g_fMsRoundTime;
if (rt <= 0.0 && g_pMsRoundTime)
rt = floatclamp(get_pcvar_float(g_pMsRoundTime), 0.0, 60.0);
new base[16];
get_localinfo("vex_rt_base", base, charsmax(base));
if (rt > 0.0)
{
if (!base[0])
{
formatex(base, charsmax(base), "%.2f", get_cvar_float("mp_roundtime"));
set_localinfo("vex_rt_base", base);
}
if (floatabs(get_cvar_float("mp_roundtime") - rt) > 0.001)
{
set_cvar_float("mp_roundtime", rt);
log_amx("[Vexmira] mp_roundtime %.2f (%s)", rt, g_fMsRoundTime > 0.0 ? "harita ini" : "vex_roundtime");
}
}
else if (base[0])
{
set_cvar_float("mp_roundtime", str_to_float(base));
set_localinfo("vex_rt_base", "");
log_amx("[Vexmira] mp_roundtime %s (geri yuklendi)", base);
}
}
#define MSS_NONE  0
#define MSS_INFO  1
#define MSS_STORY 2
#define MSS_OBJ   3
#define MSS_MSG   4
#define MSS_EV    5
#define MSS_MK    6
#define MSS_LOCK  7
#define MSS_HINT  8
#define MSS_FX    9
#define MSS_SKIP  10
#define MSS_AMB   11
#define MSS_ARENA 12
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
new line[512], sec = MSS_NONE, lang, ln, bad, objN[2];
new key[64], val[192], a[MS_LEN], b[MS_LEN];
while (!feof(fp))
{
fgets(fp, line, charsmax(line));
ln++;
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
else if (equali(line, "[fx]"))           sec = MSS_FX;
else if (equali(line, "[ambience]"))     sec = MSS_AMB;
else if (equali(line, "[arena]"))        sec = MSS_ARENA;
else if (equali(line, "[radio]") || equali(line, "[chatter]") || equali(line, "[models]"))
sec = MSS_SKIP;
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
if (sec == MSS_SKIP)
continue;
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
else if (equali(key, "roundtime"))  g_fMsRoundTime = floatclamp(str_to_float(val), 0.0, 60.0);
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
formatex(g_szMsMsg[g_iMsMsgN][0], MS_LEN - 1, "-=[  %s  ]=-", a);
formatex(g_szMsMsg[g_iMsMsgN][1], MS_LEN - 1, "-=[  %s  ]=-", b);
g_iMsMsgN++;
}
case MSS_FX:
{
if (!MsParseFx(key, val))
MsBad(path, ln, line, bad);
}
case MSS_AMB:
{
if (!MsParseAmb(val))
MsBad(path, ln, line, bad);
}
case MSS_ARENA:
{
if (!Arena536_Parse(key, val))
MsBad(path, ln, line, bad);
}
case MSS_LOCK, MSS_HINT:
{
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
MsMkCreate(m)
{
new Float:o[3], Float:top[3];
o = g_fMsMkPos[m];
if (g_szSprBeacon[0])
{
new spr = CreateSafe51("info_target");
if (!is_nullent(spr) && spr < OVH_MAXENT)
{
set_entvar(spr, var_classname, "vex_mapmarker");
VxSM(spr, g_szSprBeacon);
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
bool:MsMkHidden(host)
{
if (is_user_alive(host))
return g_bZombie[host] != 0;
new TeamName:t = get_member(host, m_iTeam);
return t != TEAM_CT;
}
MsMkPack(es, host)
{
if (MsMkHidden(host))
set_es(es, ES_Effects, get_es(es, ES_Effects) | EF_NODRAW);
return FMRES_IGNORED;
}
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
MsFireRange(first, cnt)
{
for (new i = first, end = first + cnt; i < end; i++)
{
new ent = g_iMeEnt[i];
if (pev_valid(ent) && pev(ent, pev_targetname) == g_iMeTn[i])
ExecuteHamB(Ham_Use, ent, 0, 0, 3, 0.0);
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
if (g_iMeRadio[ev] >= 0)
MsRadio(g_iMeRadio[ev], 0.6);
if (g_iMeFx[ev] >= 0)
MsFxFire(g_iMeFx[ev]);
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
MsRoundRestart()
{
g_iMsRound++;
g_bMsLive = false;
g_iMsSec = 0;
for (new k = 0; k < 3; k++)
g_bMsObjDone[k] = false;
for (new x = 0; x < g_iMsExN; x++)
remove_task(TASK_MSEX + x);
for (new x = 0; x < g_iFxN; x++)
remove_task(TASK_MSFX + x);
for (new x = 0; x < g_iMsAmbN; x++)
g_iAmbIn[x] = 0;
remove_task(TASK_MSRADIO);
g_iRdPending = -1;
g_fRdBusy = 0.0;
g_iRdChatIn = 0;
remove_task(TASK_MSRS);
set_task(0.2, "task_MsRoundStart", TASK_MSRS);
}
public task_MsRoundStart()
{
MsModelsReset();
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
MsTick()
{
RadioTick52();
if (g_bMsLive && ++g_iMsSec % 60 == 0)
MsEvent(ME_MINUTE);
MsChatterTick();
MsAmbTick();
}
MsParseAmb(const val[])
{
if (g_iMsAmbN >= MS_MAXAMB)
return 0;
new src[384], tok[32], a = g_iMsAmbN, n;
copy(src, charsmax(src), val);
if (!MsTok(src, tok, charsmax(tok)))
return 0;
g_iAmbMin[a] = clamp(str_to_num(tok), 5, 3600);
if (!MsTok(src, tok, charsmax(tok)))
return 0;
g_iAmbMax[a] = clamp(str_to_num(tok), g_iAmbMin[a], 3600);
g_iAmbFxN[a] = 0;
while (MsTok(src, tok, charsmax(tok)) && g_iAmbFxN[a] < MS_AMBPICK)
{
new kx = -1;
for (new k = 0; k < g_iFxKeyN; k++)
{
if (equali(g_szFxKey[k], tok))
kx = k;
}
if (kx < 0)
return 0;
g_iAmbFx[a][g_iAmbFxN[a]++] = kx;
n++;
}
if (!n)
return 0;
g_iAmbIn[a] = 0;
g_iAmbLast[a] = -1;
g_iMsAmbN++;
return 1;
}
MsAmbTick()
{
new pct = get_pcvar_num(g_pMsAmb);
if (!g_bMsLive || pct <= 0 || !get_pcvar_num(g_pMsEvents))
return;
for (new a = 0; a < g_iMsAmbN; a++)
{
if (g_iAmbIn[a] <= 0)
{
g_iAmbIn[a] = max(3, random_num(g_iAmbMin[a], g_iAmbMax[a]) * 100 / pct);
continue;
}
if (--g_iAmbIn[a] > 0)
continue;
g_iAmbIn[a] = max(3, random_num(g_iAmbMin[a], g_iAmbMax[a]) * 100 / pct);
new pick = random_num(0, g_iAmbFxN[a] - 1);
if (pick == g_iAmbLast[a] && g_iAmbFxN[a] > 1)
pick = (pick + 1) % g_iAmbFxN[a];
g_iAmbLast[a] = pick;
MsFxFire(g_iAmbFx[a][pick]);
}
}
stock MsTok(src[], tok[], tlen)
{
new rest[384];
tok[0] = 0;
trim(src);
if (!src[0])
return 0;
argbreak(src, tok, tlen, rest, charsmax(rest));
copy(src, 383, rest);
return tok[0] != 0;
}
stock MsPackCol(const s[])
{
new a[8], b[8], c[8], t[32];
copy(t, charsmax(t), s);
replace_all(t, charsmax(t), ",", " ");
parse(t, a, charsmax(a), b, charsmax(b), c, charsmax(c));
return (clamp(str_to_num(a), 0, 255) << 16) | (clamp(str_to_num(b), 0, 255) << 8) | clamp(str_to_num(c), 0, 255);
}
MsPrecacheIni()
{
new map[32], path[160];
get_mapname(map, charsmax(map));
get_configsdir(path, charsmax(path));
format(path, charsmax(path), "%s/vexmira_maps/%s.ini", path, map);
new fp = fopen(path, "rt");
if (!fp)
return;
new line[512], sec, key[32], val[480], tok[64], full[96], c;
while (!feof(fp))
{
fgets(fp, line, charsmax(line));
c = contain(line, " ;");
if (c != -1)
line[c] = 0;
trim(line);
if (!line[0] || line[0] == ';' || line[0] == '#')
continue;
if (line[0] == '[')
{
sec = equali(line, "[radio]") ? 1 : (equali(line, "[chatter]") ? 2 : (equali(line, "[models]") ? 3
: (equali(line, "[fx]") ? 4 : 0)));
continue;
}
if (!sec)
continue;
c = contain(line, "=");
if (c < 1)
continue;
copy(key, min(c, charsmax(key)), line);
trim(key);
copy(val, charsmax(val), line[c + 1]);
if (sec == 4)
{
if (MsTok(val, tok, charsmax(tok)) && equali(tok, "snd") && MsTok(val, tok, charsmax(tok)))
{
formatex(full, charsmax(full), "sound/%s", tok);
if (file_exists(full))
PcSound(tok);
else
log_amx("[Vexmira] map [fx] ses yok: %s", full);
}
continue;
}
if (sec == 3)
{
if (g_iMmN >= MS_MAXMODEL || !MsTok(val, tok, charsmax(tok)))
continue;
if (!file_exists(tok))
continue; // 5.3.8: missing [models] file = silently skipped
new m = g_iMmN;
copy(g_szMmPath[m], charsmax(g_szMmPath[]), tok);
g_fMmFr[m] = 1.0;
g_iMmRa[m] = 255;
g_fMmScale[m] = 1.0;
g_iMmCol[m] = 0xFFFFFF;
new n;
while (MsTok(val, tok, charsmax(tok)))
{
if (tok[0] == '@' && !n)
{
copy(g_szMmFollow[m], charsmax(g_szMmFollow[]), tok[1]);
n = 4;
}
else if (contain(tok, ":") > 0)
{
new k = contain(tok, ":"), Float:f = str_to_float(tok[k + 1]), v = str_to_num(tok[k + 1]);
if (equal(tok, "seq:", 4))        g_iMmSeq[m] = v;
else if (equal(tok, "fr:", 3))    g_fMmFr[m] = f;
else if (equal(tok, "rm:", 3))    g_iMmRm[m] = v;
else if (equal(tok, "ra:", 3))    g_iMmRa[m] = v;
else if (equal(tok, "fx:", 3))    g_iMmFx[m] = v;
else if (equal(tok, "col:", 4))   g_iMmCol[m] = MsPackCol(tok[4]);
else if (equal(tok, "body:", 5))  g_iMmBody[m] = v;
else if (equal(tok, "skin:", 5))  g_iMmSkin[m] = v;
else if (equal(tok, "scale:", 6)) g_fMmScale[m] = f;
else if (equal(tok, "name:", 5))  copy(g_szMmName[m], charsmax(g_szMmName[]), tok[5]);
}
else if (n < 4)
g_fMmPos[m][n++] = str_to_float(tok);
}
if (n < 3)
continue;
if(!PcModel(g_szMmPath[m], false)) { log_amx("[VexMap] Decor skipped (not precached): %s",g_szMmPath[m]); continue; }
g_iMmN++;
continue;
}
if (g_iRdN >= MS_MAXRADIO || strlen(key) > 23)
continue;
new r = g_iRdN, a[MS_LEN], b[MS_LEN];
MsTok(val, tok, charsmax(tok));
g_bRdLow[r] = tok[0] == '-';
g_fRdLen[r] = floatclamp(floatabs(str_to_float(tok)), 0.5, 15.0);
// 5.3.8 lazy: only the server language (vex_res CSO_LANG tr / en / both) of every map radio line is downloaded
new rl[8]; copy(rl, charsmax(rl), GetResString("CSO_LANG", "tr"));
new keep = equali(rl, "both") ? 3 : (equali(rl, "en") ? 1 : 2);
for (new l = 0; l < 2; l++)
{
MsTok(val, tok, charsmax(tok));
formatex(full, charsmax(full), "sound/vexmira/radio/%s", tok);
if (tok[0] && (keep & (1 << l)) && file_exists(full))
{
copy(g_szRdFile[r][l], charsmax(g_szRdFile[][]), tok);
PcGeneric(full);
}
}
if (!g_szRdFile[r][0][0])
copy(g_szRdFile[r][0], charsmax(g_szRdFile[][]), g_szRdFile[r][1]);
if (!g_szRdFile[r][1][0])
copy(g_szRdFile[r][1], charsmax(g_szRdFile[][]), g_szRdFile[r][0]);
MsSplitPipe(val, a, b);
copy(g_szRdSub[r][0], MS_LEN - 1, a);
copy(g_szRdSub[r][1], MS_LEN - 1, b);
copy(g_szRdKey[r], charsmax(g_szRdKey[]), key);
g_bRdChat[r] = sec == 2;
if (sec == 2)
g_iRdChatN++;
g_iRdN++;
}
fclose(fp);
if (g_iRdN || g_iMmN)
log_amx("[Vexmira] harita v3.7: telsiz satiri %d (sohbet %d), dekor modeli %d", g_iRdN, g_iRdChatN, g_iMmN);
}
MsRadioFind(const key[])
{
for (new r = 0; r < g_iRdN; r++)
{
if (!g_bRdChat[r] && equali(g_szRdKey[r], key))
return r;
}
return -1;
}
MsRadioLink()
{
new k[32];
for (new i = 0; i < MS_MAXMSG; i++)
g_iMsMsgRadio[i] = i < g_iMsMsgN ? MsRadioFind(g_szMsMsgKey[i]) : -1;
for (new e = 0; e < ME_NUM; e++)
{
formatex(k, charsmax(k), "ev_%s", ME_NAME[e]);
g_iMeRadio[e] = MsRadioFind(k);
g_iMeFx[e] = MsFxFind(k);
}
for (new i = 0; i < MS_MAXMSG; i++)
g_iMsMsgFx[i] = i < g_iMsMsgN ? MsFxFind(g_szMsMsgKey[i]) : -1;
g_iRdLock = MsRadioFind("lock");
}
MsFxFind(const key[])
{
for (new k = 0; k < g_iFxKeyN; k++)
{
if (equali(g_szFxKey[k], key))
return k;
}
return -1;
}
MsRadioSend(r, id)
{
if(g_iSet[id]&SET_NO_RADIO52) return;
new l = MsLang(id);
if (g_szRdFile[r][l][0])
VxClientCmd527(id, "spk ^"vexmira/radio/%s^"", g_szRdFile[r][l]);
if (g_szRdSub[r][l][0])
client_print_color(id, print_team_grey, "^4[%s]^1 %s", l ? "TELSIZ" : "RADIO", g_szRdSub[r][l]);
}
MsRadioPlay(r)
{
for (new id = 1; id <= g_iMax; id++)
{
if (is_user_connected(id) && !is_user_bot(id))
MsRadioSend(r, id);
}
g_fRdBusy = get_gametime() + g_fRdLen[r] + 0.4;
if (get_pcvar_num(g_pMsDebug))
log_amx("[Vexmira] map telsiz '%s' (%.1f sn)", g_szRdKey[r], g_fRdLen[r]);
}
MsRadio(r, Float:delay = 0.0)
{
if (r < 0 || r >= g_iRdN || !get_pcvar_num(g_pMsRadio))
return;
new Float:now = get_gametime();
if (g_bRdChat[r] || g_bRdLow[r])
{
if (now >= floatmax(g_fRdBusy,g_fRadioBusy52) && now >= g_fRdNext[r])
{
g_fRdNext[r] = now + 20.0;
MsRadioPlay(r);
}
return;
}
new Float:at = floatmax(now + delay, g_fRdBusy);
if (at <= now + 0.01)
{
MsRadioPlay(r);
return;
}
g_iRdPending = r;
remove_task(TASK_MSRADIO);
set_task(at - now + 0.05, "task_MsRadioNext", TASK_MSRADIO);
g_fRdBusy = floatmax(g_fRdBusy, at);
}
public task_MsRadioNext()
{
new r = g_iRdPending;
g_iRdPending = -1;
if (r >= 0)
MsRadioPlay(r);
}
MsRadioTo(r, id)
{
if (r < 0 || !get_pcvar_num(g_pMsRadio) || get_gametime() < g_fRdBusy || is_user_bot(id))
return;
MsRadioSend(r, id);
}
MsChatterTick()
{
new avg = get_pcvar_num(g_pMsChatter);
if (!g_bMsLive || !g_iRdChatN || avg <= 0)
return;
if (g_iRdChatIn <= 0)
{
g_iRdChatIn = random_num(avg / 2, avg);
return;
}
if (--g_iRdChatIn > 0)
return;
g_iRdChatIn = random_num(avg * 6 / 10, avg * 14 / 10);
new pick = -1, n;
for (new tries = 0; tries < 8 && pick < 0; tries++)
{
n = random_num(0, g_iRdChatN - 1);
for (new r = 0; r < g_iRdN; r++)
{
if (g_bRdChat[r] && n-- == 0)
{
if (r != g_iRdLastChat || g_iRdChatN == 1)
pick = r;
break;
}
}
}
if (pick >= 0)
{
g_iRdLastChat = pick;
MsRadio(pick);
}
}
MdlBounds539(const path[], Float:mn[3], Float:mx[3])
{
mn[0] = -40.0; mn[1] = -40.0; mn[2] = 0.0; mx[0] = 40.0; mx[1] = 40.0; mx[2] = 160.0;
new fp = fopen(path, "rb", true);
if (!fp) return;
new id, raw, Float:v[12];
fread(fp, id, BLOCK_INT);
if (id == 0x54534449)
{
fseek(fp, 88, SEEK_SET);
for (new i = 0; i < 12; i++) { fread(fp, raw, BLOCK_INT); v[i] = Float:raw; }   // min max bbmin bbmax
new Float:a[3], Float:b[3];
for (new k = 0; k < 3; k++) { a[k] = floatmin(v[k], v[6 + k]); b[k] = floatmax(v[3 + k], v[9 + k]); }
if (b[0] - a[0] > 1.0 && b[2] - a[2] > 1.0 && b[2] - a[2] < 2000.0)
for (new k = 0; k < 3; k++) { mn[k] = a[k] - 8.0; mx[k] = b[k] + 8.0; }
}
fclose(fp);
}
MsModelsSpawn()
{
new Float:o[3], Float:ang[3], Float:col[3], tgt;
for (new m = 0; m < g_iMmN; m++)
{
tgt = 0;
if (g_szMmFollow[m][0])
{
tgt = engfunc(EngFunc_FindEntityByString, -1, "targetname", g_szMmFollow[m]);
if (tgt <= 0)
{
log_amx("[Vexmira] map model %s: izlenecek varlik '%s' yok", g_szMmPath[m], g_szMmFollow[m]);
continue;
}
}
new e = CreateSafe51("info_target");
if (!pev_valid(e))
continue;
set_pev(e, pev_classname, "vex_mapmodel");
VxSM(e, g_szMmPath[m]);
if (g_szMmName[m][0])
set_pev(e, pev_targetname, g_szMmName[m]);
set_pev(e, pev_solid, SOLID_NOT);
if (tgt)
{
pev(tgt, pev_origin, o);
set_pev(e, pev_movetype, MOVETYPE_FOLLOW);
set_pev(e, pev_aiment, tgt);
new Float:ofs[3], Float:mn[3], Float:mx[3];
if (o[0] == 0.0 && o[1] == 0.0 && o[2] == 0.0)
{
pev(tgt, pev_absmin, mn);
pev(tgt, pev_absmax, mx);
ofs[0] = (mn[0] + mx[0]) * 0.5;
ofs[1] = (mn[1] + mx[1]) * 0.5;
ofs[2] = mn[2] + 1.0;
o[0] = ofs[0];
o[1] = ofs[1];
o[2] = ofs[2];
}
set_pev(e, pev_v_angle, ofs);
}
else
{
o[0] = g_fMmPos[m][0];
o[1] = g_fMmPos[m][1];
o[2] = g_fMmPos[m][2];
ang[1] = g_fMmPos[m][3];
set_pev(e, pev_angles, ang);
set_pev(e, pev_movetype, MOVETYPE_NONE);
}
// 5.3.9c: real model bounds (was a 0-size point at the base -> the engine dropped the model whenever its base
// left the PVS = xmas trees / props blinking)
{ new Float:bmn[3], Float:bmx[3]; MdlBounds539(g_szMmPath[m], bmn, bmx); new Float:sc = g_fMmScale[m] > 0.01 ? g_fMmScale[m] : 1.0;
for (new k = 0; k < 3; k++) { bmn[k] *= sc; bmx[k] *= sc; }
engfunc(EngFunc_SetSize, e, bmn, bmx); }
engfunc(EngFunc_SetOrigin, e, o);
set_pev(e, pev_sequence, g_iMmSeq[m]);
set_pev(e, pev_framerate, g_fMmFr[m]);
set_pev(e, pev_animtime, get_gametime());
set_pev(e, pev_frame, 0.0);
set_pev(e, pev_body, g_iMmBody[m]);
set_pev(e, pev_skin, g_iMmSkin[m]);
set_pev(e, pev_scale, g_fMmScale[m]);
if (g_iMmRm[m] || g_iMmFx[m])
{
col[0] = float((g_iMmCol[m] >> 16) & 255);
col[1] = float((g_iMmCol[m] >> 8) & 255);
col[2] = float(g_iMmCol[m] & 255);
set_pev(e, pev_rendermode, g_iMmRm[m]);
set_pev(e, pev_renderamt, float(g_iMmRa[m]));
set_pev(e, pev_renderfx, g_iMmFx[m]);
set_pev(e, pev_rendercolor, col);
}
g_iMmEnt[m] = e;
g_iMmTgt[m] = tgt;
if (tgt && !g_bMmBrkHook)
{
new cls[32];
pev(tgt, pev_classname, cls, charsmax(cls));
if (equal(cls, "func_breakable"))
{
VxRegisterHam524(Ham_Killed, "func_breakable", "fw_MsBrkKilled", 1);
g_bMmBrkHook = true;
}
}
}
}
public fw_MsBrkKilled(ent)
{
for (new m = 0; m < g_iMmN; m++)
{
if (g_iMmTgt[m] == ent && pev_valid(g_iMmEnt[m]))
set_pev(g_iMmEnt[m], pev_effects, pev(g_iMmEnt[m], pev_effects) | EF_NODRAW);
}
}
MsModelsReset()
{
for (new m = 0; m < g_iMmN; m++)
{
if (g_iMmTgt[m] && pev_valid(g_iMmEnt[m]))
set_pev(g_iMmEnt[m], pev_effects, pev(g_iMmEnt[m], pev_effects) & ~EF_NODRAW);
}
}
MsParseFx(const key[], const val[])
{
if (g_iFxN >= MS_MAXFX)
return 0;
new src[384], tok[64], i = g_iFxN, type, n, np;
copy(src, charsmax(src), val);
if (!MsTok(src, tok, charsmax(tok)))
return 0;
for (new t = 1; t < sizeof MFX_NAME; t++)
{
if (equali(tok, MFX_NAME[t]))
type = t;
}
if (!type)
return 0;
g_szFxSnd[i][0] = 0;
if (type == MFX_SND)
{
if (!MsTok(src, tok, charsmax(tok)) || !TrieKeyExists(g_tSnd3D, tok))
return 0;
copy(g_szFxSnd[i], charsmax(g_szFxSnd[]), tok);
}
g_iFxEnt[i] = 0;
g_iFxRep[i] = 1;
g_fFxDt[i] = 0.5;
g_fFxDelay[i] = 0.0;
g_iFxCol[i] = 0xFFFFFF;
for (new k = 0; k < 6; k++)
g_fFxP[i][k] = -1.0;
while (MsTok(src, tok, charsmax(tok)))
{
new c = contain(tok, ":");
if (tok[0] == '@' && !n)
{
g_iFxEnt[i] = engfunc(EngFunc_FindEntityByString, -1, "targetname", tok[1]);
if (g_iFxEnt[i] <= 0)
{
log_amx("[Vexmira] map [fx] %s: varlik '%s' yok", key, tok[1]);
return 0;
}
}
else if (c > 0)
{
if (equal(tok, "t:", 2))        g_fFxDelay[i] = floatclamp(str_to_float(tok[2]), 0.0, 120.0);
else if (equal(tok, "rep:", 4)) g_iFxRep[i] = clamp(str_to_num(tok[4]), 1, 200);
else if (equal(tok, "dt:", 3))  g_fFxDt[i] = floatclamp(str_to_float(tok[3]), 0.1, 30.0);
else if (equal(tok, "col:", 4)) g_iFxCol[i] = MsPackCol(tok[4]);
}
else if (n < 3)
g_fFxPos[i][n++] = str_to_float(tok);
else if (np < 6)
g_fFxP[i][np++] = str_to_float(tok);
}
if (n < 3)
return 0;
new kx = -1;
for (new k = 0; k < g_iFxKeyN; k++)
{
if (equali(g_szFxKey[k], key))
kx = k;
}
if (kx < 0)
{
if (g_iFxKeyN >= MS_MAXFXKEY || strlen(key) > 23)
return 0;
kx = g_iFxKeyN++;
copy(g_szFxKey[kx], charsmax(g_szFxKey[]), key);
}
g_iFxKeyOf[i] = kx;
g_iFxType[i] = type;
g_iFxN++;
return 1;
}
stock Float:MsFxP(i, k, Float:def)
{
return g_fFxP[i][k] < 0.0 ? def : g_fFxP[i][k];
}
MsFxOrigin(i, Float:o[3])
{
o[0] = g_fFxPos[i][0];
o[1] = g_fFxPos[i][1];
o[2] = g_fFxPos[i][2];
new e = g_iFxEnt[i];
if (e > 0 && pev_valid(e))
{
new Float:eo[3];
pev(e, pev_origin, eo);
o[0] += eo[0];
o[1] += eo[1];
o[2] += eo[2];
}
}
MsFxFire(kx)
{
for (new i = 0; i < g_iFxN; i++)
{
if (g_iFxKeyOf[i] != kx || g_iFxType[i] == MFX_SAFE)
continue;
remove_task(TASK_MSFX + i);
g_iFxLeft[i] = g_iFxRep[i];
if (g_fFxDelay[i] > 0.0)
set_task(g_fFxDelay[i], "task_MsFx", TASK_MSFX + i);
else
task_MsFx(TASK_MSFX + i);
}
if (get_pcvar_num(g_pMsDebug))
log_amx("[Vexmira] map efekt '%s'", g_szFxKey[kx]);
}
public task_MsFx(tid)
{
new i = tid - TASK_MSFX;
if (i < 0 || i >= g_iFxN)
return;
MsFxRun(i);
if (--g_iFxLeft[i] > 0)
set_task(g_fFxDt[i], "task_MsFx", tid);
}
public task_MsFogEnd()
{
for (new p = 1; p <= g_iMax; p++)
SendFogForEvent(p);
}
MsFxRun(i)
{
new Float:o[3], Float:q[3], r = (g_iFxCol[i] >> 16) & 255, g = (g_iFxCol[i] >> 8) & 255, b = g_iFxCol[i] & 255;
MsFxOrigin(i, o);
switch (g_iFxType[i])
{
case MFX_CLEAR, MFX_UNSTUCK:
{
q[0] = MsFxP(i, 0, 0.0) - g_fFxPos[i][0] + o[0];
q[1] = MsFxP(i, 1, 0.0) - g_fFxPos[i][1] + o[1];
q[2] = MsFxP(i, 2, 0.0) - g_fFxPos[i][2] + o[2];
MsFxClear(i, o, q, g_iFxType[i] == MFX_UNSTUCK);
return;
}
case MFX_SND:
{
new pit = floatround(MsFxP(i, 2, 100.0));
engfunc(EngFunc_EmitAmbientSound, 0, o, g_szFxSnd[i], floatclamp(MsFxP(i, 0, 1.0), 0.05, 1.0),
floatclamp(MsFxP(i, 1, 0.8), 0.0, 4.0), 0, clamp(pit + random_num(-5, 5), 50, 200));
return;
}
case MFX_FOG:
{
new dens = clamp(floatround(MsFxP(i, 0, 30.0)), 1, 400);
for (new p = 1; p <= g_iMax; p++)
{
if (is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p] & SET_NO_FOG))
SendFogEx(p, r, g, b, dens);
}
remove_task(TASK_MSFOG);
set_task(floatclamp(MsFxP(i, 1, 8.0), 1.0, 60.0), "task_MsFogEnd", TASK_MSFOG);
return;
}
case MFX_SHAKE:
{
new Float:rad = MsFxP(i, 0, 600.0), Float:po[3];
for (new p = 1; p <= g_iMax; p++)
{
if (!is_user_alive(p) || is_user_bot(p))
continue;
pev(p, pev_origin, po);
if (get_distance_f(o, po) > rad)
continue;
message_begin(MSG_ONE_UNRELIABLE, g_msgShake, _, p);
write_short(floatround(MsFxP(i, 1, 6.0) * 4096.0));
write_short(floatround(MsFxP(i, 2, 1.5) * 4096.0));
write_short(floatround(160.0 * 256.0));
message_end();
}
return;
}
}
for (new p = 1; p <= g_iMax; p++)
{
if (!FxWants(p, o))
continue;
switch (g_iFxType[i])
{
case MFX_FLARE:
{
FxBegin(o, p);
write_byte(TE_SPRITE);
engfunc(EngFunc_WriteCoord, o[0]);
engfunc(EngFunc_WriteCoord, o[1]);
engfunc(EngFunc_WriteCoord, o[2]);
write_short(g_sprFlare);
write_byte(clamp(floatround(MsFxP(i, 0, 1.0) * 10.0), 1, 255));
write_byte(255);
message_end();
FxBegin(o, p);
write_byte(TE_DLIGHT);
engfunc(EngFunc_WriteCoord, o[0]);
engfunc(EngFunc_WriteCoord, o[1]);
engfunc(EngFunc_WriteCoord, o[2]);
write_byte(clamp(floatround(MsFxP(i, 1, 20.0)), 1, 255));
write_byte(r);
write_byte(g);
write_byte(b);
write_byte(clamp(floatround(MsFxP(i, 2, 1.0) * 10.0), 1, 255));
write_byte(10);
message_end();
}
case MFX_SMOKE:
{
FxBegin(o, p);
write_byte(TE_SMOKE);
engfunc(EngFunc_WriteCoord, o[0] + random_float(-8.0, 8.0));
engfunc(EngFunc_WriteCoord, o[1] + random_float(-8.0, 8.0));
engfunc(EngFunc_WriteCoord, o[2]);
write_short(g_sprSmoke);
write_byte(clamp(floatround(MsFxP(i, 0, 3.0) * 10.0), 1, 255));
write_byte(clamp(floatround(MsFxP(i, 1, 10.0)), 1, 255));
message_end();
}
case MFX_SPARKS:
{
for (new k = 0, nk = clamp(floatround(MsFxP(i, 0, 2.0)), 1, 6); k < nk; k++)
{
FxBegin(o, p);
write_byte(TE_SPARKS);
engfunc(EngFunc_WriteCoord, o[0] + random_float(-24.0, 24.0));
engfunc(EngFunc_WriteCoord, o[1] + random_float(-24.0, 24.0));
engfunc(EngFunc_WriteCoord, o[2]);
message_end();
}
}
case MFX_DUST, MFX_RING:
{
new Float:rad = MsFxP(i, 0, 180.0);
FxBegin(o, p);
write_byte(TE_BEAMCYLINDER);
engfunc(EngFunc_WriteCoord, o[0]);
engfunc(EngFunc_WriteCoord, o[1]);
engfunc(EngFunc_WriteCoord, o[2]);
engfunc(EngFunc_WriteCoord, o[0]);
engfunc(EngFunc_WriteCoord, o[1]);
engfunc(EngFunc_WriteCoord, o[2] + rad);
write_short(g_sprRing);
write_byte(0);
write_byte(0);
write_byte(clamp(floatround(MsFxP(i, 1, 0.6) * 10.0), 1, 255));
write_byte(g_iFxType[i] == MFX_DUST ? 60 : 16);
write_byte(0);
write_byte(g_iFxType[i] == MFX_DUST ? 120 : r);
write_byte(g_iFxType[i] == MFX_DUST ? 110 : g);
write_byte(g_iFxType[i] == MFX_DUST ? 95 : b);
write_byte(g_iFxType[i] == MFX_DUST ? 90 : 200);
write_byte(0);
message_end();
if (g_iFxType[i] != MFX_DUST)
continue;
for (new k = 0; k < 6; k++)
{
new Float:a = float(k) * 60.0 + random_float(0.0, 30.0);
FxBegin(o, p);
write_byte(TE_SMOKE);
engfunc(EngFunc_WriteCoord, o[0] + floatcos(a, degrees) * rad * 0.6);
engfunc(EngFunc_WriteCoord, o[1] + floatsin(a, degrees) * rad * 0.6);
engfunc(EngFunc_WriteCoord, o[2]);
write_short(g_sprSmoke);
write_byte(25);
write_byte(14);
message_end();
}
}
case MFX_LIGHT:
{
FxBegin(o, p);
write_byte(TE_DLIGHT);
engfunc(EngFunc_WriteCoord, o[0]);
engfunc(EngFunc_WriteCoord, o[1]);
engfunc(EngFunc_WriteCoord, o[2]);
write_byte(clamp(floatround(MsFxP(i, 0, 24.0)), 1, 255));
write_byte(r);
write_byte(g);
write_byte(b);
write_byte(clamp(floatround(MsFxP(i, 1, 0.5) * 10.0), 1, 255));
write_byte(clamp(floatround(MsFxP(i, 2, 20.0)), 0, 255));
message_end();
}
case MFX_SPOT:
{
new e = g_iFxEnt[i];
if (e <= 0 || !pev_valid(e))
continue;
q[0] = o[0] + MsFxP(i, 0, 0.0);
q[1] = o[1] + MsFxP(i, 1, 0.0);
q[2] = o[2] - MsFxP(i, 2, 300.0);
FxBegin(o, p);
write_byte(TE_BEAMENTPOINT);
write_short(e | (MsFxP(i, 5, 0.0) > 0.0 ? (1 << 12) : 0));
engfunc(EngFunc_WriteCoord, q[0]);
engfunc(EngFunc_WriteCoord, q[1]);
engfunc(EngFunc_WriteCoord, q[2]);
write_short(g_sprBeam);
write_byte(0);
write_byte(0);
write_byte(clamp(floatround(MsFxP(i, 4, 0.6) * 10.0), 1, 255));
write_byte(clamp(floatround(MsFxP(i, 3, 40.0)), 1, 255));
write_byte(0);
write_byte(r);
write_byte(g);
write_byte(b);
write_byte(70);
write_byte(0);
message_end();
}
case MFX_BOOM:
{
FxBegin(o, p);
write_byte(TE_EXPLOSION);
engfunc(EngFunc_WriteCoord, o[0]);
engfunc(EngFunc_WriteCoord, o[1]);
engfunc(EngFunc_WriteCoord, o[2]);
write_short(g_sprExplode);
write_byte(clamp(floatround(MsFxP(i, 0, 20.0)), 1, 255));
write_byte(15);
write_byte(TE_EXPLFLAG_NOSOUND);
message_end();
}
}
}
}
stock bool:MsFxHullFree(const Float:o[3], ignore)
{
new tr = create_tr2();
engfunc(EngFunc_TraceHull, o, o, 0, HULL_HUMAN, ignore, tr);
new bool:ok = !get_tr2(tr, TR_StartSolid) && !get_tr2(tr, TR_AllSolid);
free_tr2(tr);
return ok;
}
MsFxClear(i, const Float:mn[3], const Float:mx[3], bool:onlyStuck)
{
new Float:po[3], Float:best[3], Float:d, Float:bd, Float:s[3], e = g_iFxEnt[i], moved;
for (new p = 1; p <= g_iMax; p++)
{
if (!is_user_alive(p))
continue;
pev(p, pev_origin, po);
if (po[0] < mn[0] || po[0] > mx[0] || po[1] < mn[1] || po[1] > mx[1] || po[2] < mn[2] || po[2] > mx[2])
continue;
if (onlyStuck)
{
if (MsFxHullFree(po, p))
continue;
if (e > 0 && pev_valid(e))
{
new Float:emx[3];
pev(e, pev_absmax, emx);
s = po;
s[2] = emx[2] + 37.0;
if (MsFxHullFree(s, p))
{
engfunc(EngFunc_SetOrigin, p, s);
moved++;
continue;
}
}
}
else if (e > 0 && pev_valid(e))
{
new Float:emn[3];
pev(e, pev_absmin, emn);
if (pev(p, pev_groundentity) == e || po[2] > emn[2] + 30.0)
continue;
}
bd = 999999.0;
new found;
for (new k = 0; k < g_iFxN; k++)
{
if (g_iFxType[k] != MFX_SAFE)
continue;
s = g_fFxPos[k];
d = get_distance_f(po, s);
if (d < bd && MsFxHullFree(s, p))
{
bd = d;
best = s;
found = 1;
}
}
if (!found)
continue;
engfunc(EngFunc_SetOrigin, p, best);
set_pev(p, pev_velocity, Float:{0.0, 0.0, 0.0});
moved++;
if (!is_user_bot(p))
client_print(p, print_center, "%s", MsLang(p) ? "Inis alani - geri cekildin" : "Landing zone - you were moved clear");
}
if (moved && get_pcvar_num(g_pMsDebug))
log_amx("[Vexmira] map efekt %s: %d oyuncu tasindi (%s)", MFX_NAME[g_iFxType[i]], moved, g_szFxKey[g_iFxKeyOf[i]]);
}
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
if (g_iMsMsgRadio[arg] >= 0)
MsRadio(g_iMsMsgRadio[arg], 1.2);
else if (g_szMsSndMsg[0])
VxClientCmd527(0, "spk ^"%s^"", g_szMsSndMsg);
if (g_iMsMsgFx[arg] >= 0)
MsFxFire(g_iMsMsgFx[arg]);
}
case MC_RADIO:
MsRadio(arg, 0.2);
case MC_FX:
MsFxFire(arg);
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
g_bMsObjDone[arg] = true;UiAll52(60,2.0,4);
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
VxClientCmd527(0, "spk ^"%s^"", g_szMsSndObj);
}
}
}
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
MsOnSpawn(id)
{
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
VxClientCmd527(id, "spk ^"%s^"", g_szMsSndLine);
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
#define MAPV_MAX 8
MapVoteInit()
{
g_pMapVote        = register_cvar("vex_map_vote", "1");
g_pCosPreview     = register_cvar("vex_cos_preview", "10");
g_pCosDeal        = register_cvar("vex_cos_daily_deal", "25");
g_pCosHide        = register_cvar("vex_cos_hide", "1");
g_pMapPool        = register_cvar("vex_map_pool", "zm_vexmira_icefy zm_vexmira_dust zm_vexmira_7door zm_vex_laboratory");
g_pMapVoteRound   = register_cvar("vex_map_vote_round", "0");
g_pMapVoteTime    = register_cvar("vex_map_vote_time", "20");
g_pMapVoteExtend  = register_cvar("vex_map_vote_extend", "0");
g_pMapExtendRounds = register_cvar("vex_map_extend_rounds", "10");
g_pMapChangeDelay = register_cvar("vex_map_change_delay", "7.0");
g_pMapChooserGuard = register_cvar("vex_map_vote_mapchooser", "1");
g_pRtvRatio       = register_cvar("vex_rtv_ratio", "0.60");
g_pRtvMinPlayers  = register_cvar("vex_rtv_minplayers", "2");
g_pRtvMinRound    = register_cvar("vex_rtv_minround", "3");
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
VxRegisterChain524(RG_CSGameRules_ChangeLevel, "rg_ChangeLevel", false);
set_task(7.5, "task_MapChooserCheck", TASK_MAPWARN);
}
bool:MapVoteOn()
{
return get_pcvar_num(g_pMapVote) > 0 ? true : false;
}
bool:MapExists(const map[])
{
if (!map[0])
return false;
new path[64];
formatex(path, charsmax(path), "maps/%s.bsp", map);
return (file_exists(path, true) && is_map_valid(map)) ? true : false;
}
MapCandidates(out[][32], maxn)
{
new list[256], tmp[32], pos, n;
get_pcvar_string(g_pMapPool, list, charsmax(list));
while (n < maxn && (pos = argparse(list, pos, tmp, charsmax(tmp))) != -1)
{
strtolower(tmp);
if (!tmp[0] || !MapExists(tmp))
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
MapPickFallback()
{
if (g_bMapDecided && g_szNextMap[0])
return;
new maps[MAPV_MAX][32];
new n = MapCandidates(maps, MAPV_MAX);
if (n > 0)
SetNextMap(maps[random(n)]);
}
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
MapChangeAfterRound()
{
g_bMapChangeNow = true;
if (g_bRoundActive && !g_bRoundEnded)
ChatAllS("MAPV_ROUNDEND", g_szNextMap);
else
MapChangeBegin(false);
}
MapOnRoundEnd()
{
if (g_bMapChanging || !MapVoteOn())
return;
new bool:last = (MapEndsByRounds() && g_iRound >= RoundsTotal()) ? true : false;
if (!last && !g_bMapChangeNow)
return;
if(last && !g_bMapDecided) {
g_bMapChangeNow=true;
if(g_bMapVoting || StartMapVote(0,false)) {
set_task(0.2,"task_MapHold",TASK_MAPHOLD);
return;
}
}
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
g_bMapChangeNow = false;
return;
}
g_bMapChanging = true;
if (!lastRound && !g_bMapAwards)
set_task(1.5, "task_MapEndAwards");
set_task(0.2, "task_MapHold", TASK_MAPHOLD);
remove_task(TASK_MAPCHG);
set_task(floatclamp(get_pcvar_float(g_pMapChangeDelay), 3.0, 30.0), "task_MapIntermission", TASK_MAPCHG);
}
public task_MapHold()
{
if (g_bMapChanging || (g_bMapVoting && g_bRoundEnded && g_iRound>=RoundsTotal()))
set_member_game(m_flRestartRoundTime, get_gametime() + 60.0);
}
public task_MapIntermission()
{
if (!MapExists(g_szNextMap))
{
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
public rg_ChangeLevel()
{
if(g_bMapVoting) return HC_SUPERCEDE;
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
RtvReset()
{
g_iRtvCount = 0;
for (new p = 0; p <= MAX_PLAYERS; p++)
g_bRtv[p] = false;
}
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
g_bMapDecided = false;
g_szNextMap[0] = 0;
if (StartMapVote(id, changeNow))
AdminNotify(id, "ADM_MAPVOTE", g_iMapOptN);
else
console_print(id, "[Vexmira] oylama baslatilamadi (havuzda gecerli harita yok veya baska oylama suruyor)");
}
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
public plugin_natives()
{
register_library("vexmira_core45");
register_native("vxc_res_set","VxcResSet");
register_native("vxc_pc_generic","VxcPcGeneric");
register_native("vxc_res_get","VxcResGet");
register_native("vxc_set_model","VxcSetModel");
register_native("vxc_restore_model","VxcRestoreModel");
register_native("vxc_card","VxcCard");
register_native("vxc_class","VxcClass");
register_native("vxc_pc_model","VxcPcModel");
register_native("vxc_pc_sound","VxcPcSound");
register_native("vx45_corezombie","VxNativeZombie");
register_native("vx45_coreweapon","VxNativeWeapon");
register_native("vx45_corerestore","VxNativeRestore");
register_native("vx45_corepreparejet","VxNativePrepareJet");
register_native("vx45_coresurvivor","VxNativeSurvivor");
register_native("vx45_corejetpack","VxNativeJetpack");
register_native("vx47_jetgauge","VxGaugeNative47");
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
if (!trap && (equal(name, "geoip_country_ex") || equal(name, "geoip_code2_ex")))
return PLUGIN_HANDLED;
return PLUGIN_CONTINUE;
}
ZcCore_plugin_precache()
{
if (!VexAssetGuard("vexmira_core")) log_amx("[Vexmira] optional appearance asset unavailable; core continues, invalid files are skipped individually");
if (!is_regamedll())
{
set_fail_state("Vexmira requires ReGameDLL_CS + ReAPI; check meta list and amxx modules");
return;
}
g_tRes = TrieCreate();
g_tMdlTop = TrieCreate();
new Float:v48cache[2];
v48cache[0]=59.444;v48cache[1]=58.067;TrieSetArray(g_tMdlTop,"vex_boss048",v48cache,2);
v48cache[0]=34.342;v48cache[1]=32.659;TrieSetArray(g_tMdlTop,"vex_boss148",v48cache,2);
v48cache[0]=34.549;v48cache[1]=35.843;TrieSetArray(g_tMdlTop,"vex_boss248",v48cache,2);
v48cache[0]=54.244;v48cache[1]=50.077;TrieSetArray(g_tMdlTop,"vex_boss348",v48cache,2);
v48cache[0]=46.408;v48cache[1]=50.834;TrieSetArray(g_tMdlTop,"vex_boss448",v48cache,2);
v48cache[0]=38.006;v48cache[1]=30.945;TrieSetArray(g_tMdlTop,"vex_boss548",v48cache,2);
v48cache[0]=68.248;v48cache[1]=43.533;TrieSetArray(g_tMdlTop,"vex_boss648",v48cache,2);
v48cache[0]=41.794;v48cache[1]=38.217;TrieSetArray(g_tMdlTop,"vex_boss748",v48cache,2);
v48cache[0]=46.493;v48cache[1]=37.655;TrieSetArray(g_tMdlTop,"vex_boss848",v48cache,2);
v48cache[0]=90.587;v48cache[1]=60.575;TrieSetArray(g_tMdlTop,"vex_titan48",v48cache,2);
g_tSndInfo = TrieCreate();
g_tSnd2D = TrieCreate();
g_tSnd3D = TrieCreate();
g_tMdlDone = TrieCreate();
ZcPcModel("models/vexmira/community/jetpack/rpgrocket.mdl");
SetDefaultResources();
VxDefaults();
VxLeanResources();
LoadMainConfig(true);
VxDisableSW533();
HitMarkPrecache538();
CommunityPrecache();
CommunityNormalPrecache();
CommunityEventPrecache();
CommunityExtraEventPrecache();
CsoPrecache();
VxInfPrecache531();
NadeFxPrecache531();
register_forward(FM_EmitAmbientSound, "fw_AmbientPost", 1);
g_iSndBudget = clamp(str_to_num(GetResString("SOUND_BUDGET", "200")), 40, 480);
g_iSndBudget = clamp(min(g_iSndBudget, 500 - 230 - g_iMapSnd531), 40, 480);
ItemSndPrecache533();
g_iMdlBudget = clamp(str_to_num(GetResString("MODEL_BUDGET", "250")), 40, 480);
new criticalKey[24];
LoadWorldModels();
CmPrecache();
for (new w = 1; w < 31; w++)
{
formatex(criticalKey, charsmax(criticalKey), "V_%s", WEAPON_KEYNAME[w]);
GetFileModel(criticalKey, g_szWepV[w], charsmax(g_szWepV[]));
formatex(criticalKey, charsmax(criticalKey), "P_%s", WEAPON_KEYNAME[w]);
GetFileModel(criticalKey, g_szWepP[w], charsmax(g_szWepP[]));
}
for (new sw = 0; sw < NUM_SPECIAL; sw++)
{
formatex(criticalKey, charsmax(criticalKey), "SW%d_VMODEL", sw);
GetFileModel(criticalKey, g_szSWView[sw], charsmax(g_szSWView[]));
formatex(criticalKey, charsmax(criticalKey), "SW%d_PMODEL", sw);
GetFileModel(criticalKey, g_szSWPlayer[sw], charsmax(g_szSWPlayer[]));
}
PlanBossLoad();
new path[128], key[24];
for (new i = 0; i < sizeof SOUND_KEYS; i++)
{
if (!IsFallbackOnly(SOUND_KEYS[i]))
PrecacheSoundKey(SOUND_KEYS[i]);
}
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
PrecacheSoundKeyEx("UI_VOTE_START", true);
PrecacheSoundKeyEx("UI_VOTE_END", true);
PrecacheSoundKeyEx("UI_BOSS_BAR", true);
PrecacheSoundKeyEx("UI_MENU_SELECT", true);
PrecacheSoundKeyEx("UI_CLASS_SELECT", true);
for (new i = 0; i < sizeof SOUND_KEYS_V3; i++)
PrecacheSoundKey(SOUND_KEYS_V3[i]);
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
g_sprRing      = PcModel("sprites/vexmira/arena51/base_ring.spr", false);
g_sprBeam      = PcModel("sprites/vexmira/arena51/base_beam.spr", false);
g_sprLightning = PcModel("sprites/vexmira/arena51/base_lightning.spr", false);
g_sprExplode   = PcModel("sprites/vexmira/arena50/explosion.spr", false);
g_sprSmoke     = PcModel("sprites/vexmira/arena50/smoke.spr", false);
g_sprBlood      = PrecacheSafe("sprites/vexmira/arena50/blood.spr");
g_sprBloodSpray = PrecacheSafe("sprites/vexmira/arena50/bloodspray.spr");
g_sprHeadMark   = PrecacheSafe(GetResString("BOSS_MARK_SPRITE", "sprites/glow01.spr"));
g_bHeadMarkAt   = (g_sprHeadMark && SprFileFormat(GetResString("BOSS_MARK_SPRITE", "sprites/glow01.spr")) == SPR_FMT_ALPHATEST) ? true : false;
g_sprLaser      = g_sprBeam;
g_sprFlare      = PrecacheSafe("sprites/vexmira/arena50/flare.spr");
if (!g_sprFlare)
g_sprFlare  = g_sprHeadMark;
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
if (g_sprFlare && file_exists("sprites/vexmira/arena50/flare.spr", true))
{
g_sprOrb = g_sprFlare;
copy(g_szSprOrb, charsmax(g_szSprOrb), "sprites/vexmira/arena50/flare.spr");
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
g_sprChain = PrecacheResSprite("SPR_CHAIN", g_szSprChain, charsmax(g_szSprChain));
g_sprWeb   = PrecacheResSprite("SPR_WEB", g_szSprWeb, charsmax(g_szSprWeb));
g_sprSpore = PrecacheResSprite("SPR_SPORE", g_szSprSpore, charsmax(g_szSprSpore));
g_sprEmp   = PrecacheResSprite("SPR_EMP", g_szSprEmp, charsmax(g_szSprEmp));
if (!g_sprRing)      g_sprRing      = VxPcStock531("sprites/shockwave.spr");
if (!g_sprBeam)      g_sprBeam      = VxPcStock531("sprites/laserbeam.spr");
if (!g_sprLightning) g_sprLightning = VxPcStock531("sprites/lgtning.spr");
if (!g_sprExplode)   g_sprExplode   = VxPcStock531("sprites/zerogxplode.spr");
if (!g_sprSmoke)     g_sprSmoke     = VxPcStock531("sprites/steam1.spr");
if (!g_sprLaser)     g_sprLaser     = g_sprBeam;
if (!g_sprFlare)     g_sprFlare     = VxPcStock531("sprites/glow01.spr");
if (!g_sprFire)      g_sprFire      = VxPcStock531("sprites/fexplo.spr");
if (!g_sprLmBeam)    g_sprLmBeam    = g_sprBeam;
if (!g_sprChain)     g_sprChain     = g_sprBeam;
if (!g_sprWeb)       g_sprWeb       = g_sprBeam;
if (!g_sprSpore)     g_sprSpore     = g_sprFlare;
if (!g_sprEmp)       g_sprEmp       = g_sprRing;
if (!g_sprBlood)     g_sprBlood     = VxPcStock531("sprites/blood.spr");
if (!g_sprBloodSpray) g_sprBloodSpray = VxPcStock531("sprites/bloodspray.spr");
new fxbuf[64];
g_iFxSprN = 0;
for (new i = 0; i < FXS_TOTAL; i++)
{
g_sprFx[i] = PrecacheResSprite(FXS_KEY[i], fxbuf, charsmax(fxbuf));
if (g_sprFx[i])
g_iFxSprN++;
}
static const OVKEY[OVS_TOTAL][] = { "SPR_BOSSBAR", "SPR_BOSSICON", "SPR_HPBAR", "SPR_ICON_VIP", "SPR_ICON_ADMIN", "SPR_ICON_MVP", "SPR_ICON_LAST", "SPR_ICON_ALPHA", "SPR_HUMAN47", "SPR_ZOMBIE47" };
for (new i = 0; i < OVS_TOTAL; i++)
{
if (i == OVS_HUMAN47) { g_szOvhSpr[i][0] = 0; continue; }
if (PrecacheResSprite(OVKEY[i], g_szOvhSpr[i], charsmax(g_szOvhSpr[])))
ReadSprInfo(i);
else
g_szOvhSpr[i][0] = 0;
}
LoadHumanModels();
GetPlayerModel("VIP_MODEL",      g_szVipModel,   charsmax(g_szVipModel));
GetPlayerModel("ADMIN_MODEL",    g_szAdminModel, charsmax(g_szAdminModel));
GetPlayerModel("SURVIVOR_MODEL", g_szSurvModel,  charsmax(g_szSurvModel));
if (!g_szSurvModel[0])
PlayerModelFallback("gign", g_szSurvModel, charsmax(g_szSurvModel));
GetPlayerModel("SNIPER_MODEL",   g_szSnipModel,  charsmax(g_szSnipModel));
if (!g_szSnipModel[0])
PlayerModelFallback("sas", g_szSnipModel, charsmax(g_szSnipModel));
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
formatex(key, charsmax(key), "B%d_MODEL", i);
if (!g_bBossLoaded[i])
{
new bn[32], gn[48], gp[128];
if (str_to_num(GetResString("BOSS_GIANT_ALL", "0")) && !equali(GetResString("BOSS_GIANT", "file"), "off") && !equali(GetResString("BOSS_GIANT", "file"), "clone")
&& TrieGetString(g_tRes, key, bn, charsmax(bn)) && bn[0] && GmBossGiant(bn, gn, charsmax(gn)))
{ formatex(gp, charsmax(gp), "models/player/%s/%s.mdl", gn, gn); if (PcModel(gp)) PcPlayerTex(gn); }
continue;
}
new bname[32], giant[48];
g_fBossScale531 = floatclamp(str_to_float(GetResString("BOSS_SCALE", "1.6")), 1.0, 3.0);
g_iGiantMode532 = equali(GetResString("BOSS_GIANT", "file"), "clone") ? 1 : (equali(GetResString("BOSS_GIANT", "file"), "off") ? 0 : 2);
if (g_iGiantMode532 == 2 && TrieGetString(g_tRes, key, bname, charsmax(bname)) && bname[0] && GmBossGiant(bname, giant, charsmax(giant)))
{
new gpath[128]; formatex(gpath, charsmax(gpath), "models/player/%s/%s.mdl", giant, giant);
if (PcModel(gpath)) { copy(g_szBModel[i], charsmax(g_szBModel[]), giant); MdlHeadTops(giant); PcPlayerTex(giant); }
}
if (!g_szBModel[i][0])
GetPlayerModel(key, g_szBModel[i], charsmax(g_szBModel[]));
if (!g_szBModel[i][0])
PlayerModelFallback(BOSS_OLDMODEL[i], g_szBModel[i], charsmax(g_szBModel[]));
}
for (new i = 0; i < NUM_CLASSES; i++)
{
formatex(key, charsmax(key), "Z%d_MODEL", i);
GetPlayerModel(key, g_szZModel[i], charsmax(g_szZModel[]));
if (!g_szZModel[i][0])
PlayerModelFallback(CLASS_OLDMODEL[i], g_szZModel[i], charsmax(g_szZModel[]));
}
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
GetFileModel("VIP_V_KNIFE", g_szVipKnifeV, charsmax(g_szVipKnifeV));
GetFileModel("VIP_P_KNIFE", g_szVipKnifeP, charsmax(g_szVipKnifeP));
for (new w = 1; w < 31; w++)
{
formatex(key, charsmax(key), "V_%s", WEAPON_KEYNAME[w]);
GetFileModel(key, g_szWepV[w], charsmax(g_szWepV[]));
}
for (new i = 0; i < NUM_SPECIAL; i++)
{
formatex(key, charsmax(key), "SW%d_VMODEL", i);
GetFileModel(key, g_szSWView[i], charsmax(g_szSWView[]));
formatex(key, charsmax(key), "SW%d_PMODEL", i);
GetFileModel(key, g_szSWPlayer[i], charsmax(g_szSWPlayer[]));
}
for (new w = 1; w < 31; w++)
{
formatex(key, charsmax(key), "P_%s", WEAPON_KEYNAME[w]);
GetFileModel(key, g_szWepP[w], charsmax(g_szWepP[]));
}
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
MsPrecacheIni();
CommunityInspectPrecache();
PickSky();
log_amx("[Vexmira] precache: sound=%d model=%d generic=%d", g_iPcSnd, g_iPcMdl, g_iPcGen);
log_amx("[Vexmira] precache detay: eklenti 3D ses %d/%d, model+sprite %d/%d, generic %d, butceden atlanan ses %d / model %d, yuklenen boss %d",
g_iMySnd, g_iSndBudget, g_iMyMdl, g_iMdlBudget, g_iMyGen, g_iSndSkipped, g_iMdlSkipped, g_iBossLoadN);
log_amx("[Vexmira] efekt sprite'lari: %d/%d yuklendi (model+sprite butcesi %d/%d)", g_iFxSprN, FXS_TOTAL, g_iMyMdl, g_iMdlBudget);
copy(path, charsmax(path), "");
}
ZcCore_plugin_init()
{
register_forward(FM_AddToFullPack,"fw_BannerPack47",1);
register_forward(FM_SetAbsBox,"BossBounds48",1);
VxRegisterHam524(Ham_Weapon_PrimaryAttack,"weapon_knife","MeleePrimary48",0);
VxRegisterHam524(Ham_Weapon_SecondaryAttack,"weapon_knife","MeleeSecondary48",0);
VxRegisterHam524(Ham_Item_Deploy,"weapon_knife","MeleeDeploy48",1);
VxRegisterHam524(Ham_Weapon_WeaponIdle,"weapon_knife","MeleeIdle48",0);
register_message(get_user_msgid("TextMsg"),"msg_WinText47");
register_clcmd("say /3pers", "cmd_Third47");
register_clcmd("say_team /3pers", "cmd_Third47");
g_pSixTracer=register_cvar("vex_six_tracer_every","6");
g_pSixMemeCD=register_cvar("vex_meme_cooldown","8.0");
g_pSixLog=register_cvar("vex_connection_log","1");
register_clcmd("say /memes","cmd_SixMemes");
register_clcmd("say_team /memes","cmd_SixMemes");
register_concmd("vex_connection_stats","cmd_SixStats",ADMIN_RCON);
register_plugin(PLUGIN, VERSION, AUTHOR);
g_pUi52=register_cvar("vex_ui52","1");g_pRadio52=register_cvar("vex_radio52","1");g_pRadioText532=register_cvar("vex_radio_text","1");g_pRadioInterval52=register_cvar("vex_radio52_interval","90");
register_dictionary("vexmira_zombie.txt");
register_dictionary("vexmira_epic.txt");
if (!is_regamedll())
{
set_fail_state("[Vexmira] ReGameDLL_CS + ReAPI gerekli! (ReGameDLL_CS and ReAPI are required)");
return;
}
g_iMax     = clamp(get_maxplayers(), 1, 32);
g_msgFog   = get_user_msgid("Fog");
g_msgFade  = get_user_msgid("ScreenFade");
g_msgShake = get_user_msgid("ScreenShake");
g_msgDeath = get_user_msgid("DeathMsg");
g_msgScore = get_user_msgid("ScoreInfo");
g_bGeoIP   = LibraryExists("geoip", LibType_Library) ? true : false;
log_to_file("vexmira_startup.log","[530 core] vault open BEGIN");
g_hVault = nvault_open("vexmira_v1");
g_hVipVault = nvault_open("vexmira_vip");
log_to_file("vexmira_startup.log","[530 core] vault open READY");
if (g_hVault == INVALID_HANDLE)
log_amx("[Vexmira] nvault acilamadi, ilerleme kaydedilmeyecek.");
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
g_pChatBcast    = register_cvar("vex_chat_broadcast", "1");
g_pChatBuyBcast = register_cvar("vex_chat_buy_broadcast", "0");
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
g_pTipInterval  = register_cvar("vex_chat_tip_interval", "240");
g_pLiveChatter  = register_cvar("vex_live_chatter", "0");
g_pVoteEvery    = register_cvar("vex_vote_every", "4");
g_pRoundsTotal  = register_cvar("vex_rounds_total", "30");
g_pFullRot534 = register_cvar("vex_full_rotation", "1");
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
g_pPrefix        = register_cvar("vex_chat_prefix", "^4[VEX]^1");
g_pHostname      = register_cvar("vex_hostname", "VEXMIRA ZOMBIE [TR/EN] | 6 CSO + BOSS + JETPACK");
g_pHostDyn       = register_cvar("vex_hostname_dynamic", "0");
g_pEnv           = register_cvar("vex_env", "1");
g_pEnvCalm       = register_cvar("vex_env_calm_random", "1");
g_pWeather       = register_cvar("vex_weather", "1");
g_pZHPPer = register_cvar("vex_zombie_hp_per_player", "40");
g_pNemHPPer = register_cvar("vex_nemesis_hp_per_player", "1200");
g_pAsnHPPer = register_cvar("vex_assassin_hp_per_player", "800");
g_pKBMult = register_cvar("vex_knockback_mult", "1.6");
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
g_pLmZDmg534 = register_cvar("vex_lm_zombie_damage", "550");
g_pLmKeep534 = register_cvar("vex_lm_keep", "0");
g_pLmHumanMult534 = register_cvar("vex_lm_human_break_mult", "1.0");
g_pLmKillWear    = register_cvar("vex_lm_kill_wear", "100");
g_pLmPlantTime   = register_cvar("vex_lm_plant_time", "1.0");
g_pLmTakeTime    = register_cvar("vex_lm_take_time", "2.0");
g_pMeteorEvery   = register_cvar("vex_meteor_interval", "9");
g_pMeteorCount   = register_cvar("vex_meteor_count", "1");
g_pLmArmTime     = register_cvar("vex_lm_arm_time", "1.5");
g_pLmBeamWidth   = register_cvar("vex_lm_beam_width", "8");
g_pLmColorMode   = register_cvar("vex_lm_color_mode", "3");
g_pLmColor       = register_cvar("vex_lm_color", "0 200 255");
g_pLmRange       = register_cvar("vex_lm_plant_range", "128");
g_pLmTakeRange   = register_cvar("vex_lm_take_range", "170");
g_pLmMaxRange    = register_cvar("vex_lm_max_range", "600");
g_pLmBlockModes  = register_cvar("vex_lm_block_modes", "nemesis assassin");
g_pDbgDirs       = register_cvar("vex_debug_dirs", "0");
g_pCosFollow531 = register_cvar("vex_cos_follow", "1");
g_pSwDmg531 = register_cvar("vex_sw_damage_mult", "3.0");
g_pNadeFx531 = register_cvar("vex_nade_fx", "1");
g_pLzPrices531 = register_cvar("vex_laser_prices", "300 450 600 900");
g_pAutoHit531 = register_cvar("vex_auto_hitbox", "1");
g_pBlackLight531 = register_cvar("vex_blackout_light", "b");
register_cvar("vex_dbg_nxmask", "0");register_cvar("vex_debug_audio", "0");
g_pInfAmmo531 = register_cvar("vex_unlimited_bpammo", "1");
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
g_pOvhEnable     = register_cvar("vex_overhead", "1");
g_pHudStyle      = register_cvar("vex_hud_style", "1");
g_pHudTop        = register_cvar("vex_hud_top", "-1");
g_pTop532 = register_cvar("vex_topboard", "1"); g_pHpCard533 = register_cvar("vex_boss_hpcard", "1"); g_pCosSmooth532 = register_cvar("vex_cos_smooth", "1"); g_pAmbVol532 = register_cvar("vex_ambience_volume", "0.55"); g_pAmbRe532 = register_cvar("vex_ambience_restart", "120"); g_pTopPad532 = register_cvar("vex_topboard_pad", "44"); g_pTopY532 = register_cvar("vex_topboard_y", "0.01");
g_pHudRight      = register_cvar("vex_hud_right", "-1");
g_pHudMvp        = register_cvar("vex_hud_mvp", "-1");
g_pHudXp         = register_cvar("vex_hud_xp", "-1");
g_pHudOvh        = register_cvar("vex_hud_overhead", "-1");
g_pHudObjective  = register_cvar("vex_hud_objective", "-1");
g_pCso           = register_cvar("vex_cso_style", "1");
g_pCsoNotes      = register_cvar("vex_cso_notes", "2147483647");
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
g_pHudMin538 = register_cvar("vex_hud_minimal", "1");
g_pSmallBarW     = register_cvar("vex_hpbar_width", "44");
g_pIconSize      = register_cvar("vex_head_icon_size", "18");
g_pIcons         = register_cvar("vex_head_icons", "31");
g_pOvhSelf       = register_cvar("vex_overhead_self", "0");
g_pOvhMargin     = register_cvar("vex_overhead_margin", "14");
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
register_srvcmd("vex_debug_buy", "srv_DbgBuy");
register_srvcmd("vex_debug_nadefx", "srv_DbgNadeFx");register_srvcmd("vex_debug_card", "srv_DbgCard532");register_srvcmd("vex_debug_lmwall", "srv_DbgLmWall532");register_srvcmd("vex_debug_radio", "srv_DbgRadio532");
register_srvcmd("vex_debug_giant", "srv_DbgGiant");register_srvcmd("vex_debug_slim", "srv_DbgSlim534");register_srvcmd("vex_giant_build", "srv_GiantBuild533");register_srvcmd("vex_model_build", "srv_ModelBuild539");register_srvcmd("vex_mode_build", "srv_ModelBuild539");register_concmd("vex_plan", "cmd_Plan534", ADMIN_BAN, "- bu haritanin 30 round mod/event plani");register_concmd("vex_fastdl", "cmd_FastDl534", ADMIN_BAN, "- FastDL icin indirilecek dosya listesi");set_task(20.0, "task_FastDlWarn534");register_concmd("vex_kontrol", "cmd_Kontrol533", ADMIN_BAN, "- eksik ayar dosyalari, kartlar, limitler");
register_srvcmd("vex_debug_gravtest", "srv_DbgGravTest");
register_srvcmd("vex_debug_hooktest", "srv_DbgHookTest");
register_forward(FM_SetModel, "fw_SetModelPost", 1);
register_forward(FM_AddToFullPack, "fw_AddToFullPackPost", 1);
register_forward(FM_StartFrame, "GiantFrame532", 1);
PrecacheReportTotals();
OvhInit();
set_task(2.0,"CommunityCheckComponents");
g_msgWeather = get_user_msgid("ReceiveW");
static const TABLE_CMDS[][] =
{
"vex_item", "vex_class", "vex_sw", "vex_gun", "vex_job", "vex_boss_stat", "vex_boss_skill",
"vex_mode_rule", "vex_env_event", "vex_env_mode", "vex_env_boss", "vex_env_calm", "vex_cosmetic", "vex_quest", "vex_sw_text"
};
for (new i = 0; i < sizeof TABLE_CMDS; i++)
register_srvcmd(TABLE_CMDS[i], "srv_TableCmd");
register_srvcmd("vex_res", "srv_ResCmd");
register_concmd("vex_reload", "cmd_reload_cfg", ADMIN_RCON, "- vexmira.cfg dosyasini yeniden yukler");
VxRegisterChain524(RG_CSGameRules_CheckWinConditions, "rg_CheckWinConditions", false);
VxRegisterChain524(RG_CSGameRules_RestartRound,       "rg_RestartRound", false);
VxRegisterChain524(RG_CSGameRules_OnRoundFreezeEnd,   "rg_FreezeEnd", true);
VxRegisterChain524(RG_RoundEnd,                       "rg_RoundEnd", true);
VxRegisterChain524(RG_CBasePlayer_Spawn,              "rg_PlayerSpawn", true);
VxRegisterChain524(RG_CBasePlayer_TakeDamage,         "rg_TakeDamage", false);
VxRegisterChain524(RG_CBasePlayer_TakeDamage,         "rg_TakeDamagePost", true);
VxRegisterChain524(RG_CBasePlayer_Killed,             "rg_PlayerKilledPre", false);
VxRegisterChain524(RG_CBasePlayer_Killed,             "rg_PlayerKilled", true);
VxRegisterChain524(RG_CBasePlayer_ResetMaxSpeed,      "rg_ResetMaxSpeed", true);
VxRegisterChain524(RG_CBasePlayer_HasRestrictItem,    "rg_HasRestrictItem", false);
VxRegisterChain524(RG_CBasePlayer_MakeBomber,         "rg_MakeBomber", false);
VxRegisterChain524(RG_CSGameRules_FlPlayerFallDamage, "rg_FallDamage", false);
VxRegisterChain524(RG_CBasePlayerWeapon_DefaultDeploy, "rg_DefaultDeploy", false);
VxRegisterChain524(RG_CBasePlayer_DropPlayerItem,     "rg_DropPlayerItemPost", true);
VxRegisterChain524(RG_ThrowHeGrenade,                 "rg_ThrowHe", true);
VxRegisterChain524(RG_ThrowSmokeGrenade,              "rg_ThrowSmoke", true);
VxRegisterChain524(RG_ThrowFlashbang,                 "rg_ThrowFlash", true);
VxRegisterChain524(RG_CGrenade_ExplodeHeGrenade,      "rg_ExplodeHe", false);
VxRegisterChain524(RG_CGrenade_ExplodeSmokeGrenade,   "rg_ExplodeSmoke", false);
VxRegisterChain524(RG_CGrenade_ExplodeFlashbang,      "rg_ExplodeFlash", false);
VxRegisterChain524(RG_CBasePlayer_Jump,               "rg_PlayerJump", false);
VxRegisterChain524(RG_CBasePlayer_ImpulseCommands,    "rg_ImpulseCommands", false);
VxRegisterHam524(Ham_TakeDamage, "info_target", "fw_EntTakeDamage", 0);
VxRegisterHam524(Ham_Touch, "grenade", "fw_GrenadeTouch", 0);
VxRegisterHam524(Ham_Weapon_SecondaryAttack, "weapon_hegrenade", "fw_NadeAttack2", 0);
VxRegisterHam524(Ham_Weapon_SecondaryAttack, "weapon_smokegrenade", "fw_NadeAttack2", 0);
VxRegisterHam524(Ham_Weapon_SecondaryAttack, "weapon_flashbang", "fw_NadeAttack2", 0);
VxRegisterHam524(Ham_Item_Deploy, "weapon_hegrenade", "fw_NadeDeploy", 1);
VxRegisterHam524(Ham_Item_Deploy, "weapon_smokegrenade", "fw_NadeDeploy", 1);
VxRegisterHam524(Ham_Item_Deploy, "weapon_flashbang", "fw_NadeDeploy", 1);
register_message(get_user_msgid("MOTD"), "msg_Motd");
for (new i = 0; i < sizeof GUN_CLASSES; i++)
VxRegisterHam524(Ham_Weapon_PrimaryAttack, GUN_CLASSES[i], "fw_PrimaryAttackPost", 1);
register_forward(FM_ClientKill, "fw_ClientKill");
g_tCmds = TrieCreate();
g_tRoundBuys = TrieCreate();
register_clcmd("chooseteam", "cmd_menu");
register_clcmd("jointeam", "cmd_jointeam");
register_clcmd("vexmenu", "cmd_menu");
register_clcmd("nightvision", "cmd_nvg");
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
RegisterSay("models", "gorunum", "CommunityModelsCommand");
RegisterSay("knives", "bicaklar", "CommunityKnivesCommand");
RegisterSay("knife",  "bicak",    "CommunityKnivesCommand");
RegisterSay("model",  "skin",     "CommunityModelsCommand");
RegisterSay("ctmodel","karakter", "CommunityModelsCommand");
RegisterSay("jetpack","jet",      "CommunityJetCommand");
RegisterSay("hev",    "zirh",     "CommunityHevCommand");
RegisterSay("sw",     "ozelsilah","cmd_special");
register_clcmd("vex_inspect", "CommunityInspectCommand");
register_clcmd("vex_bossg","EpicDropCommand");
RegisterSay("vcmarket","coinmarket","cmd_cosmetic");
register_concmd("vex_status", "CommunityStatus", ADMIN_RCON);
register_concmd("vex_arsenal_give","cmd_ArsenalGive",ADMIN_RCON,"<name or #userid> <0..7>");
register_forward(FM_GetGameDescription,"CommunityGameDescription");
if(cvar_exists("sv_tags")) set_cvar_string("sv_tags","zombie,cso,boss,jetpack,tr,en");
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
log_to_file("vexmira_startup.log","[530 core] MapVoteInit BEGIN");
MapVoteInit();
log_to_file("vexmira_startup.log","[530 core] MapVoteInit READY");
log_to_file("vexmira_startup.log","[530 core] MsInit BEGIN");
MsInit();
log_to_file("vexmira_startup.log","[530 core] MsInit READY");
register_clcmd("+setlaser", "cmd_lm_plant");
register_clcmd("-setlaser", "cmd_lm_release");
register_clcmd("+dellaser", "cmd_lm_take");
register_clcmd("-dellaser", "cmd_lm_release_take");
register_clcmd("setlaser",  "cmd_lm_plant");
register_clcmd("dellaser",  "cmd_lm_take");
register_clcmd("vex_lm_plant", "cmd_lm_plant");
register_clcmd("vex_lm_take",  "cmd_lm_take");
register_clcmd("radio3", "cmd_radio3");
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
public plugin_cfg()
{
if(!g_bRun526) return;
log_to_file("vexmira_startup.log","[530 core] plugin_cfg BEGIN");
log_to_file("vexmira_startup.log","[530 core] duplicate guard BEGIN");
VexDuplicateGuard();
log_to_file("vexmira_startup.log","[530 core] duplicate guard READY");
server_print("[Vexmira] Vexmira Zombie Core v%s yuklendi (iki eklenti: core + gear, modul: %d/14 acik)", VERSION, ZcModulesOn());
log_amx("[Vexmira] Vexmira Zombie Core v%s", VERSION);
new n = LoadMainConfig(false);
log_amx("[Vexmira] vexmira.cfg yuklendi (%d satir).", n);
log_to_file("vexmira_startup.log","[530 core] LoadTop BEGIN");
LoadTop();
log_to_file("vexmira_startup.log","[530 core] LoadTop READY; AutoTeam BEGIN");
task_EnforceAutoTeam();
log_to_file("vexmira_startup.log","[530 core] AutoTeam READY");
remove_task(TASK_AUTOTEAM);
set_task(15.0, "task_EnforceAutoTeam", TASK_AUTOTEAM, _, _, "b");
set_task(1.5, "task_EnforceRoundInfinite", TASK_ROUNDINF);
set_task(6.0, "task_LoadConfig", TASK_CFGLOAD);
set_task(30.0, "task_Hostname", TASK_HOSTNAME, _, _, "b");
set_task(1.0, "task_MsRoundStart", TASK_MSRS);
}
public plugin_end()
{
if(!g_bRun526) return;
log_to_file("vexmira_startup.log","[5.3.0] END map unload");
if(g_tZcModelsReady!=Invalid_Trie) TrieDestroy(g_tZcModelsReady);
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
CommunityAlive(id) { return is_user_alive(id) && !g_bZombie[id] && !g_bSurvivor[id] && !g_bSniper[id] && !g_bBoss[id] && !g_bMinion[id]; }
CommunityRemoveWeapons(id) { for (new i=0;i<6;i++) ZcCall((i)+1, ZCOP_remove, id); ZcCall(ZC_MINIGUN, ZCOP_remove,id); CommunityRemoveShots(id); }
CommunityRemoveKnives(id) { for (new i=0;i<4;i++) ZcCall((i)+7, ZCOP_remove, id); }
CommunityReset(id)
{
CommunityRemoveWeapons(id); CommunityRemoveKnives(id);
ZcCall(ZC_JETPACK, ZCOP_remove, id);
ZcCall(ZC_HEV, ZCOP_remove, id);
ZcCall(ZC_MINIGUN, ZCOP_remove, id);
remove_task(id + 64000);
}
CommunityExtra(id)
{
return VxActive(id)>=0;
}
CommunityNativeZombie(id) { return id<1 || id>32 || !is_user_connected(id) || g_bZombie[id]; }
CommunityNativeWeapon(id) { return id>=1 && id<=32 ? CommunityExtra(id):0; }
CommunityNativeRestore(id) {
if (id>=1 && id<=32 && is_user_alive(id) && !g_bZombie[id]) { ApplyHumanModel(id); remove_task(id+64000); set_task(0.2,"CommunityApplyKnife",id+64000); }
return 1;
}
CommunityWeaponMenu(id)
{
new title[320],line[160];VexHead(id,title,charsmax(title),"MENU_SPECIAL");new menu=VexMenuCreate(title,"menu_special_handler");
for(new i=0;i<NUM_SPECIAL;i++) {if(i==SW_REMOVED533) continue;formatex(line,charsmax(line),"\w%s \r[%d AP]",V50_NAMES[i],SW_COST[i]);MenuAdd(menu,line,i);}
new sgn[48];for(new i=0,n=vxe_sw_count();i<n;i++) {new c=vxe_sw_info(i,sgn,charsmax(sgn));if(c<0) continue;formatex(line,charsmax(line),"\w%s \r[%d AP]",sgn,c);MenuAdd(menu,line,100+i);}
formatex(line,charsmax(line),"%L",id,"MENU_BACK");MenuAdd(menu,line,999);MenuFinish(id,menu);
}
CommunityBuyWeapon(id,i)
{
if(i>=100) {BuySg538(id,i-100);return;}
if(i<0 || i>=NUM_SPECIAL) return;
if(!CommunityAlive(id)) {Chat(id,"ZC_ALIVE_HUMAN");return;}
if(VxActive(id)==i) {Chat(id,"SHOP_ALREADY");return;}
if(g_iAP[id]<SW_COST[i]) {Chat(id,"SHOP_NOAP");return;}
if(!g_bVxReady[i]) {client_print(id,print_chat,"[VEXMIRA] %s dosyalari yuklu degil; AP harcanmadi.",V50_NAMES[i]);return;}
if(!VxGive(id,i)) {Chat(id,"SHOP_UNAVAIL");return;}
AddAP(id,-SW_COST[i],false,false);PlayKey(id,"SHOP_BUY");VxItemFxRGB531(id,SW_RGB[i][0],SW_RGB[i][1],SW_RGB[i][2]);
}
CommunityBuyGear(id,i)
{
if(i!=0) return;
if(!CommunityAlive(id)) { Chat(id,"ZC_ALIVE_HUMAN"); return; }
new price=80;
if(g_iAP[id]<price) { Chat(id,"SHOP_NOAP"); return; }
new comp=ZC_JETPACK;
if(ZcCall(comp,ZCOP_has,id)) { Chat(id,"SHOP_ALREADY"); return; }
if(!ZcCompOn(comp)) { client_print_color(id,print_team_default,"^4[Vexmira]^1 %s %L","Jetpack",id,"ZC_ITEM_OFF"); return; }
if(!ZcCall(comp,ZCOP_give,id)) { Chat(id,"SHOP_UNAVAIL"); return; }
CommunityRemoveKnives(id); AddAP(id,-price,false,false); PlayKey(id,"SHOP_BUY"); VxItemFxRGB531(id,255,150,40);
}
CommunityCoinMenu(id,c)
{
new title[320],line[160];
VexHead(id,title,charsmax(title),c?"ZC_KNIVES":"ZC_CTSKINS");
new menu=VexMenuCreate(title,"CommunityCoinHandler");
if(g_iCommunitySel[id][c]==0) formatex(line,charsmax(line),"%L [%L]",id,"ZC_STANDARD",id,"ZC_EQUIPPED");
else formatex(line,charsmax(line),"%L",id,"ZC_STANDARD");
MenuAdd(menu,line,c*10);
for(new i=0;i<(c ? KN_TOTAL : 5);i++) {
if ((!c && !g_bCommunityCtOk[i]) || (c && !KnifeReady47(i))) continue;
new knm[48]; KnifeName538(c, i, knm, charsmax(knm));
if(g_iCommunitySel[id][c]==i+1) formatex(line,charsmax(line),"%s [%L]",knm,id,"ZC_EQUIPPED");
else if(g_iCommunityOwned[id][c]&(1<<i)) formatex(line,charsmax(line),"%s [%L]",knm,id,"ZC_OWNED");
else formatex(line,charsmax(line),"%s [%d VC]",knm,KnifeCost538(c, i));
MenuAdd(menu,line,c*10+i+1);
}
formatex(line,charsmax(line),"%L",id,"MENU_BACK"); MenuAdd(menu,line,999);
MenuFinish(id,menu);
}
public CommunityCoinHandler(id,menu,item)
{
if(item<0) { menu_destroy(menu); return PLUGIN_HANDLED; }
new sel=MenuInfo(menu,item); menu_destroy(menu);
if(sel==999) { ShowCosmeticMenu(id); return PLUGIN_HANDLED; }
new c=sel/10,v=sel%10;
if(c<0 || c>1 || v<0 || v>(c ? KN_TOTAL : 5)) return PLUGIN_HANDLED;
CommunityCoinSelect(id,c,v);
CommunityCoinMenu(id,c); return PLUGIN_HANDLED;
}
CommunityCoinSelect(id,c,v)
{
if(c<0 || c>1 || v<0 || v>(c ? KN_TOTAL : 5)) return 0;
if(v && ((!c && !g_bCommunityCtOk[v-1]) || (c && !KnifeReady47(v-1)))) { Chat(id,"ZC_MISSING_COLLECTION"); return 0; }
if(v && !(g_iCommunityOwned[id][c] & (1<<(v-1)))) {
new cost=KnifeCost538(c, v-1);
if(g_iVC[id]<cost) { Chat(id,"COS_NOVC",cost); return 0; }
g_iVC[id]-=cost; g_iCommunityOwned[id][c]|=1<<(v-1); PlayKey(id,"SHOP_BUY"); VxItemFxRGB531(id,255,215,0);
}
g_iCommunitySel[id][c]=v; SaveData(id);
if(CommunityAlive(id)) {
if(!c && !ZcCall(ZC_HEV, ZCOP_has,id)) ApplyHumanModel(id);
else if(c) CommunityApplyKnife(id+64000);
}
return 1;
}
public CommunityApplyKnife(taskid)
{
new id=taskid-64000;
if(id<1 || id>32 || !CommunityAlive(id)) return;
CommunityRemoveKnives(id);
if(ZcCall(ZC_JETPACK, ZCOP_has,id) || ZcCall(ZC_HEV, ZCOP_has,id)) return;
new v=g_iCommunitySel[id][1];
if(v>=5 && v<=KN_TOTAL) { new ent=get_member(id,m_pActiveItem); if(!is_nullent(ent) && get_user_weapon(id)==CSW_KNIFE) ExecuteHamB(Ham_Item_Deploy,ent); }
else if(v && (g_iCommunityOwned[id][1] & (1<<(v-1)))) ZcCall((v-1)+7, ZCOP_give,id);
else { new ent=get_member(id,m_pActiveItem); if(!is_nullent(ent) && get_user_weapon(id)==CSW_KNIFE) ExecuteHamB(Ham_Item_Deploy,ent); }
}
CommunityPrecache()
{
MeleePrecache48();
g_iSupplySigil47=ZcPcModel("models/vexmira/epic/supply_sigil47.mdl");
for(new sg47=0;sg47<2;sg47++) g_iSigil47[sg47]=ZcPcModel(SIGIL47[sg47]);
for(new b47=3;b47<5;b47++) g_iBannerModel47[b47]=ZcPcModel(BANNER47[b47]);
g_bTitan47 = ZcPcModel("models/player/vex_titan48/vex_titan48.mdl") > 0;
new path[128];
for(new i=0;i<5;i++) { formatex(path,charsmax(path),"models/player/%s/%s.mdl",COMMUNITY_CT[i],COMMUNITY_CT[i]); if(file_exists(path,true)) g_bCommunityCtOk[i] = ZcPcModel(path)>0; else log_amx("[Community] EKSIK model: %s (bu CT gorunumu kapali)",path); }
ZcPcGeneric("models/player/vex_halo/vex_haloT.mdl");
g_bCommunityButterflyOk = g_bMkOk[0];
}
CommunityCosOrigin(ent,id,c,i)
{
new Float:o[3],Float:a[3],Float:owner[3];
if(c==0 && get_pcvar_num(g_pCosFollow531)) {
if(get_entvar(ent,var_movetype)!=MOVETYPE_FOLLOW || get_entvar(ent,var_aiment)!=id) {
set_entvar(ent,var_movetype,MOVETYPE_FOLLOW);set_entvar(ent,var_aiment,id);
get_entvar(id,var_origin,o);engfunc(EngFunc_SetOrigin,ent,o);
set_entvar(ent,var_angles,Float:{0.0,0.0,0.0});
set_entvar(ent,var_framerate,g_fCmFps[c][i]>0.0?g_fCmFps[c][i]:1.0);set_entvar(ent,var_animtime,get_gametime());
}
CmApplyCtl(ent,id,c,i);
return;
}
if(c==2 && equal(g_szCmMdl[c][i],"models/vexmira/arena52/hats/",28) && CosCanFollow49(id,c)) {
set_entvar(ent,var_movetype,MOVETYPE_FOLLOW);set_entvar(ent,var_aiment,id);
get_entvar(id,var_origin,o);engfunc(EngFunc_SetOrigin,ent,o);
set_entvar(ent,var_angles,Float:{0.0,0.0,0.0});return;
}
set_entvar(ent,var_movetype,MOVETYPE_NOCLIP);set_entvar(ent,var_aiment,0);
CommunityCosCalc(id,c,i,o,a);engfunc(EngFunc_SetOrigin,ent,o);set_entvar(ent,var_angles,a);
get_entvar(id,var_origin,owner);set_entvar(ent,var_vuser1,owner);new Float:yaw51[3];get_entvar(id,var_angles,yaw51);set_entvar(ent,var_fuser3,yaw51[1]);
}
CommunityCosCalc(id,c,i,Float:o[3],Float:a[3])
{
get_entvar(id,var_origin,o);get_entvar(id,var_angles,a);
new bool:anchored=false;
if(c!=1 && CosCanFollow49(id,c)) {
new j=c==2?1:0;
if(g_fCosAt50[id]<=0.0) {new Float:p50[3],Float:a50[3];engfunc(EngFunc_GetBonePosition,id,g_iCosBone50[id][j],p50,a50);for(new k=0;k<3;k++) g_fCosAnchor50[id][j][k]=p50[k]-o[k];}
for(new k=0;k<3;k++) o[k]+=g_fCosAnchor50[id][j][k];anchored=true;
}
new Float:x=g_fCmOfs[c][i][0],Float:yy=g_fCmOfs[c][i][1],Float:z=g_fCmOfs[c][i][2];
new bool:duck=(get_entvar(id,var_flags)&FL_DUCKING)?true:false;
if(c==2 && anchored) {
if(equali(g_szOvhMdl[id],"vex_batman47")) z-=2.0;
else if(equali(g_szOvhMdl[id],"vex_wolverine47")) z-=3.3;
else if(equali(g_szOvhMdl[id],"vex_ironman47")) z-=2.8;
else if(equali(g_szOvhMdl[id],"vex_spiderman47")) z-=2.5;
else if(equali(g_szOvhMdl[id],"vex_masterchief47")) z-=0.8;
}
new Float:y=a[1]*0.0174532925;
o[0]+=x*floatcos(y)-yy*floatsin(y);o[1]+=x*floatsin(y)+yy*floatcos(y);
if(!anchored && g_iCmAtt[c][i]==CMA_HEAD) z+=duck?g_fOvhDuck[id]:g_fOvhStand[id];
else if(!anchored && (g_iCmAtt[c][i]==CMA_BACK || (g_iCmAtt[c][i]==CMA_BONE && c==0))) z+=(duck?g_fOvhDuck[id]:g_fOvhStand[id])-18.0;
else if(!anchored && g_iCmAtt[c][i]==CMA_BONE && c==2) z+=(duck?g_fOvhDuck[id]:g_fOvhStand[id])-8.3;
if(c==1) {
g_fPetWall49[id]=1.0;
new Float:start[3],Float:down[3];start=o;start[2]+=24.0;down=start;down[2]-=100.0;
new tr=create_tr2();engfunc(EngFunc_TraceLine,start,down,IGNORE_MONSTERS,id,tr);new Float:frac;get_tr2(tr,TR_flFraction,frac);
if(z<0.0 && frac<1.0 && !get_tr2(tr,TR_StartSolid)) {get_tr2(tr,TR_vecEndPos,down);o[2]=down[2]+1.5;}
else {o[2]+=z>=0.0?z+2.0*floatsin(get_gametime()*2.4+float(id)):(duck?-18.0:-36.0);}
free_tr2(tr);
new Float:owner[3],Float:stop[3];get_entvar(id,var_origin,owner);owner[2]=o[2]+12.0;stop=o;stop[2]+=12.0;
tr=create_tr2();engfunc(EngFunc_TraceLine,owner,stop,IGNORE_MONSTERS,id,tr);get_tr2(tr,TR_flFraction,frac);
if(frac<1.0) {g_fPetWall49[id]=frac*0.8;get_tr2(tr,TR_vecEndPos,stop);o[0]=owner[0]+(stop[0]-owner[0])*0.8;o[1]=owner[1]+(stop[1]-owner[1])*0.8;}
free_tr2(tr);
} else o[2]+=z;
a[0]=g_fCmAng[c][i][0];a[1]+=g_fCmAng[c][i][1];a[2]=g_fCmAng[c][i][2];
}
CommunityNativeJetpack(id) { return id>=1 && id<=32 ? ZcCall(ZC_JETPACK, ZCOP_has,id):0; }
CommunityRemoveShots(id)
{
static const CLS[3][]={"vex_plasma_ball","vex_bow_arrow","vex_sal_flame"};
for(new i=0;i<3;i++) {
new ent=-1;
while((ent=engfunc(EngFunc_FindEntityByString,ent,"classname",CLS[i]))>0) {
if(!pev_valid(ent)) continue;
new owner=i==2?pev(ent,pev_owner):pev(ent,pev_iuser1);
if(owner==id) set_pev(ent,pev_flags,pev(ent,pev_flags)|FL_KILLME);
}
}
}
CommunityNativePrepareJet(id) { if(id>=1 && id<=32) CommunityRemoveKnives(id); return 1; }
CommunityCtReady(i)
{
return i>=0 && i<5 && g_bCommunityCtOk[i];
}
CommunityEventPrecache()
{
ModernEvents50();
}
CommunityNormalPrecache()
{
}
CommunityWorldModel(ent,const model[])
{
#pragma unused ent, model
return 0;
}
new g_iInspectSeq[31][2], Float:g_fInspectTime[31][2], Float:g_fInspectReady[33];
new g_iButterflyInspect=-1, Float:g_fButterflyInspect;
new Float:g_fLightNoteReady[33];
CommunityRestoreResource(const key[], const value[])
{
new path[192];
if(contain(value,"models/")==0 || contain(value,"sprites/")==0 || contain(value,"sound/")==0) copy(path,charsmax(path),value);
else if(containi(value,".wav")!=-1 || containi(value,".mp3")!=-1) formatex(path,charsmax(path),"sound/%s",value);
else if(containi(key,"MODEL")!=-1) formatex(path,charsmax(path),"models/player/%s/%s.mdl",value,value);
else return;
if(!file_exists(path,true)) { log_to_file("vex_restore.log","[Restore] optional original absent: %s -> %s; current resource kept",key,path); return; }
if(!CommunityLegacyFileOk(path)) { log_to_file("vex_restore.log","[Restore] invalid/incomplete original: %s -> %s; fallback kept",key,path); return; }
ResSet(key,value);
if(equal(key,"LASERMINE_MODEL")) {
ResSet("LASERMINE_ANGLES","0 0 0"); ResSet("LASERMINE_OFFSET","0.3");
ResSet("LASERMINE_EMITTER","10.3 0 0"); ResSet("LASERMINE_BODY","0");
ResSet("LASERMINE_SEQUENCE","0"); ResSet("LASERMINE_SEQNAME","idle");
ResSet("LASERMINE_DEPLOY_SEQ","deploy");
}
}
public CommunityEffectMenu(id)
{
new title[320],item[96]; VexHead(id,title,charsmax(title),"E46_COIN");
new menu=VexMenuCreate(title,"menu_cos_handler");
static const keys[3][]={"COS_CAT_TRAIL","COS_CAT_KFX","COS_CAT_IFX"};
for(new i=0;i<3;i++) { formatex(item,charsmax(item),"\y%L",id,keys[i]); MenuAdd(menu,item,i); }
MenuFinish(id,menu);
}
public CommunityModelsCommand(id) { CommunityCoinMenu(id,0); return PLUGIN_HANDLED; }
public CommunityKnivesCommand(id) { CommunityCoinMenu(id,1); return PLUGIN_HANDLED; }
public CommunityGameDescription() { forward_return(FMV_STRING,"Vexmira Zombie Plague"); return FMRES_SUPERCEDE; }
public CommunityCheckComponents() { CommunityStatus(0,0,0); for(new i=0;i<NUM_SPECIAL;i++) log_amx("[Arsenal8] %s ready=%d",V50_NAMES[i],g_bVxReady[i]); }
public CommunityStatus(id,level,cid)
{
if(id && !cmd_access(id,level,cid,1)) return PLUGIN_HANDLED;
console_print(id,"VEXMIRA %s | %d slots | inspect + 8 wings/pets/hats + 5 skins + 8 knives | map vote 30",VERSION,g_iMax);
ZcModuleStatus(id);
console_print(id,"Cosmetics ready: wings=%d pets=%d hats=%d; bosses=%d",g_iCmN[0],g_iCmN[1],g_iCmN[2],g_iBossLoadN);
return PLUGIN_HANDLED;
}
CommunityInspectRead(const path[], bool:butterfly=false, weapon=0)
{
new f=fopen(path,"rb"); if(!f) return;
new count,offset; fseek(f,164,SEEK_SET); fread(f,count,BLOCK_INT); fread(f,offset,BLOCK_INT);
if(count<1 || count>256 || offset<244) { fclose(f); return; }
for(new i=0;i<count;i++) {
new label[33],Float:fps,frames;
fseek(f,offset+i*176,SEEK_SET); fread_blocks(f,label,32,BLOCK_CHAR); label[32]=0;
if(containi(label,"inspect")==-1) continue;
fseek(f,offset+i*176+32,SEEK_SET); fread(f,_:fps,BLOCK_INT);
fseek(f,offset+i*176+56,SEEK_SET); fread(f,frames,BLOCK_INT);
new Float:dur=floatclamp(float(frames)/floatmax(fps,1.0),0.5,10.0);
if(butterfly) { g_iButterflyInspect=i; g_fButterflyInspect=dur; break; }
new slot=(containi(label,"unsil")!=-1)?1:0;
if(g_iInspectSeq[weapon][slot]<0) { g_iInspectSeq[weapon][slot]=i; g_fInspectTime[weapon][slot]=dur; }
}
fclose(f);
}
CommunityInspectPrecache()
{
for(new w=1;w<31;w++) {
g_iInspectSeq[w][0]=-1; g_iInspectSeq[w][1]=-1;
if(g_szWepV[w][0]) CommunityInspectRead(g_szWepV[w],false,w);
}
CommunityInspectRead("models/vexmira/arena48/v_balrog.mdl",true);
}
public CommunityInspectCommand(id) { CommunityInspect(id); return PLUGIN_HANDLED; }
CommunityInspect(id)
{
if(!CommunityAlive(id) || CommunityExtra(id) || ZcCall(ZC_HEV, ZCOP_has,id)) return 0;
new weapon=get_member(id,m_pActiveItem); if(is_nullent(weapon)) return 0;
new w=get_user_weapon(id); if(w<1 || w>30) return 0;
if(w==CSW_KNIFE && (ZcCall(ZC_JETPACK, ZCOP_has,id) || g_iCommunitySel[id][1]>0)) return 0;
new bool:butterfly=w==CSW_KNIFE && g_iCommunitySel[id][1]==5 && g_bCommunityButterflyOk;
new weaponState=get_member(weapon,m_Weapon_iWeaponState);
new slot=((w==CSW_M4A1 && !(weaponState&_:WPNSTATE_M4A1_SILENCED)) || (w==CSW_USP && !(weaponState&_:WPNSTATE_USP_SILENCED)))?1:0;
new seq=butterfly?g_iButterflyInspect:g_iInspectSeq[w][slot];
if(seq<0) { slot=0; seq=g_iInspectSeq[w][0]; }
if(seq<0) return 0;
if(get_gametime()<g_fInspectReady[id] || get_member(weapon,m_Weapon_fInReload)
|| get_member(weapon,m_Weapon_fInSpecialReload) || Float:get_member(id,m_flNextAttack)>0.0
|| Float:get_member(weapon,m_Weapon_flNextPrimaryAttack)>0.0
|| (get_entvar(id,var_button)&(IN_ATTACK|IN_ATTACK2|IN_RELOAD))) return 1;
new Float:dur=butterfly?g_fButterflyInspect:g_fInspectTime[w][slot];
set_entvar(id,var_weaponanim,seq);
message_begin(MSG_ONE,SVC_WEAPONANIM,_,id); write_byte(seq); write_byte(get_entvar(weapon,var_body)); message_end();
set_member(weapon,m_Weapon_flTimeWeaponIdle,dur); g_fInspectReady[id]=get_gametime()+0.7;
return 1;
}
CommunityExtraEventPrecache()
{
}
CommunityAdminEquipment(id)
{
if(!(get_user_flags(id)&ADMIN_BAN)) return;
new title[320],line[96]; VexHead(id,title,charsmax(title),"ADMM_4");
new menu=VexMenuCreate(title,"CommunityAdminEquipmentHandler");
for(new i=0;i<NUM_SPECIAL;i++) { if(i==SW_REMOVED533) continue; formatex(line,charsmax(line),"%s [%L]",V50_NAMES[i],id,"ZC_FREE"); MenuAdd(menu,line,i); }
formatex(line,charsmax(line),"%L [%L]",id,"ZC_JETPACK",id,"ZC_FREE"); MenuAdd(menu,line,10);
formatex(line,charsmax(line),"Survivor Minigun \d(%L)",id,"ZC_NEED_SURV"); MenuAdd(menu,line,12); MenuFinish(id,menu);
}
public CommunityAdminEquipmentHandler(id,menu,item)
{
if(item<0 || !(get_user_flags(id)&ADMIN_BAN)) { menu_destroy(menu); return PLUGIN_HANDLED; }
new sel=MenuInfo(menu,item); menu_destroy(menu);
new target=find_player_ex(FindPlayer_MatchUserId,g_iAdmTarget[id]);
if(!target || !is_user_alive(target)) { Chat(id,"ADM_GONE"); return PLUGIN_HANDLED; }
new ok;
if(sel>=0 && sel<NUM_SPECIAL) ok=VxGive(target,sel);
else if(sel==12) ok=ZcCall(ZC_MINIGUN, ZCOP_give,target);
else if(sel==10 && CommunityAlive(target)) {
CommunityRemoveKnives(target);
ok=ZcCall(ZC_JETPACK,ZCOP_give,target);
}
console_print(id,"[Vexmira] equipment grant: target=%d selection=%d success=%d",target,sel,ok);
log_to_file("vexmira_admin.log","equipment admin=%d target=%d selection=%d success=%d",get_user_userid(id),get_user_userid(target),sel,ok);
CommunityAdminEquipment(id); return PLUGIN_HANDLED;
}
new Float:g_fCmNativeRate[CM_CATS][CM_MAX], Float:g_fCmMoveRate48[CM_CATS][CM_MAX];
new g_iCmIdle48[CM_CATS][CM_MAX], g_iCmMove48[CM_CATS][CM_MAX];
CommunityCosMetadata(c,i)
{
new fp=fopen(g_szCmMdl[c][i],"rb"); if(!fp) return;
new count,offset,frames,Float:fps,nctl;
fseek(fp,148,SEEK_SET); fread(fp,nctl,BLOCK_INT);
g_bCmCtl[c][i]=false;
fseek(fp,164,SEEK_SET); fread(fp,count,BLOCK_INT); fread(fp,offset,BLOCK_INT);
if(count<1 || count>256) { fclose(fp); return; }
g_iCmSeq[c][i]=clamp(g_iCmSeq[c][i],0,count-1);
g_iCmIdle48[c][i]=g_iCmSeq[c][i];g_iCmMove48[c][i]=g_iCmSeq[c][i];
if(c==1) {
new label[33];
for(new q=0;q<count;q++) {
fseek(fp,offset+q*176,SEEK_SET);fread_blocks(fp,label,32,BLOCK_CHAR);label[32]=0;
if(equali(label,"walk") || equali(label,"run") || equali(label,"walk2handed")) {
g_iCmMove48[c][i]=q;fseek(fp,offset+q*176+32,SEEK_SET);fread(fp,_:fps,BLOCK_INT);fseek(fp,offset+q*176+56,SEEK_SET);fread(fp,frames,BLOCK_INT);
g_fCmMoveRate48[c][i]=frames>1?floatmax(fps,0.0)*256.0/float(frames-1):0.0;break;
}
}
}
new seq=offset+g_iCmSeq[c][i]*176;
fseek(fp,seq+32,SEEK_SET); fread(fp,_:fps,BLOCK_INT);
fseek(fp,seq+56,SEEK_SET); fread(fp,frames,BLOCK_INT); fclose(fp);
g_fCmNativeRate[c][i]=frames>1 ? floatmax(fps,0.0)*256.0/float(frames-1) : 0.0;
}
CommunityCosAnimate(ent,c,i,Float:now)
{
new Float:last=Float:get_entvar(ent,var_fuser1);
set_entvar(ent,var_fuser1,now);
if(last<=0.0 || g_fCmNativeRate[c][i]<=0.0) return;
new Float:rate=(get_entvar(ent,var_sequence)==g_iCmMove48[c][i] && g_iCmMove48[c][i]!=g_iCmIdle48[c][i])?g_fCmMoveRate48[c][i]:g_fCmNativeRate[c][i];
new Float:frame=Float:get_entvar(ent,var_frame)+floatclamp(now-last,0.0,0.25)*rate*g_fCmFps[c][i];
while(frame>=256.0) frame-=256.0;
set_entvar(ent,var_frame,frame); set_entvar(ent,var_animtime,now);
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
if(!MdlTexOk539(path, bytes)) return false;
if(!textures) { formatex(sibling,charsmax(sibling),"%sT.mdl",base); if(!MdlTexOk539(sibling, 0)) return false; }
return true;
}
fclose(fp);
if(containi(path,".spr")!=-1) return magic==0x50534449 && version==2 && bytes>42 && SprFramesOk539(path, bytes);
if(containi(path,".wav")!=-1) return magic==0x46464952 && bytes>44;
return bytes>0;
}
// 5.3.9b model guard: a model / sprite that would crash a client (texture outside the file, odd texture
// area -> "GL_Upload16: s&3", missing T.mdl textures) is never sent to players; the caller falls back
// to the old / default model. Reasons go to logs/vexmira_modelguard.log.
stock ModelGuardLog539(const path[], const why[])
{
log_to_file("vexmira_modelguard.log", "ENGELLENDI %s -> %s (oyuncuya gonderilmedi, eski/varsayilan model kullanilir)", path, why);
}
bool:MdlTexOk539(const path[], bytes)
{
if (equal(GetResString("MODEL_GUARD", "1"), "0")) return true;
new fp = fopen(path, "rb", true);
if (!fp) { ModelGuardLog539(path, "dosya acilamadi"); return false; }
if (bytes <= 0) { fseek(fp, 0, SEEK_END); bytes = ftell(fp); }
new magic, nt, ti, nbp, bpi;
fseek(fp, 0, SEEK_SET); fread(fp, magic, BLOCK_INT);
if (magic != 0x54534449 || bytes < 244) { fclose(fp); ModelGuardLog539(path, "gecersiz model basligi"); return false; }
fseek(fp, 180, SEEK_SET); fread(fp, nt, BLOCK_INT); fread(fp, ti, BLOCK_INT);
fseek(fp, 204, SEEK_SET); fread(fp, nbp, BLOCK_INT); fread(fp, bpi, BLOCK_INT);
if (nt < 0 || nt > 256 || (nt > 0 && (ti < 244 || ti + nt * 80 > bytes))) { fclose(fp); ModelGuardLog539(path, "doku tablosu bozuk"); return false; }
if (nbp < 0 || nbp > 64 || (nbp > 0 && (bpi < 244 || bpi + nbp * 76 > bytes))) { fclose(fp); ModelGuardLog539(path, "govde tablosu bozuk"); return false; }
new w, h, idx, why[64];
for (new i = 0; i < nt; i++)
{
fseek(fp, ti + i * 80 + 68, SEEK_SET);
fread(fp, w, BLOCK_INT); fread(fp, h, BLOCK_INT); fread(fp, idx, BLOCK_INT);
if (w < 1 || h < 1 || w > 4096 || h > 4096) { formatex(why, charsmax(why), "doku %d boyutu %dx%d gecersiz", i, w, h); break; }
if ((w * h) & 3) { formatex(why, charsmax(why), "doku %d boyutu %dx%d (GL_Upload16 cokmesi)", i, w, h); break; }
if (idx < 0 || idx + w * h + 768 > bytes) { formatex(why, charsmax(why), "doku %d dosya disinda (eksik/kesik dosya)", i); break; }
}
fclose(fp);
if (why[0]) { ModelGuardLog539(path, why); return false; }
return true;
}
bool:SprFramesOk539(const path[], bytes)
{
if (equal(GetResString("MODEL_GUARD", "1"), "0")) return true;
new fp = fopen(path, "rb", true);
if (!fp) return false;
new nf, pc, o, t, n, x, y, w, h, why[64];
fseek(fp, 28, SEEK_SET); fread(fp, nf, BLOCK_INT);
fseek(fp, 40, SEEK_SET); fread(fp, pc, BLOCK_SHORT);
o = 42 + pc * 3;
if (nf < 1 || nf > 2048 || pc < 0 || pc > 256) { fclose(fp); ModelGuardLog539(path, "gecersiz sprite basligi"); return false; }
for (new f = 0; f < nf && !why[0]; f++)
{
fseek(fp, o, SEEK_SET); fread(fp, t, BLOCK_INT); o += 4;
n = 1;
if (t != 0) { fread(fp, n, BLOCK_INT); o += 4 + n * 4; if (n < 1 || n > 512) { copy(why, charsmax(why), "kare grubu bozuk"); break; } }
for (new k = 0; k < n; k++)
{
if (o + 16 > bytes) { copy(why, charsmax(why), "kare dosya disinda (kesik dosya)"); break; }
fseek(fp, o, SEEK_SET); fread(fp, x, BLOCK_INT); fread(fp, y, BLOCK_INT); fread(fp, w, BLOCK_INT); fread(fp, h, BLOCK_INT);
o += 16;
if (w < 1 || h < 1 || w > 2048 || h > 2048) { formatex(why, charsmax(why), "kare %d boyutu %dx%d gecersiz", f, w, h); break; }
if ((w * h) & 3) { formatex(why, charsmax(why), "kare %d boyutu %dx%d (GL_Upload16 cokmesi)", f, w, h); break; }
o += w * h;
if (o > bytes) { formatex(why, charsmax(why), "kare %d dosya disinda (kesik dosya)", f); break; }
}
}
fclose(fp);
if (why[0]) { ModelGuardLog539(path, why); return false; }
return true;
}
stock bool:VexIsOldCopy(const title[], const ver[], plugin)
{
if (equal(title, PLUGIN) && !equal(ver, VERSION)) return true;
if (containi(title, "Vexmira") != -1 && containi(title, "Diagnostic") != -1) return true;
if (get_func_id("vex_give", plugin) >= 0 && get_func_id("vex_has", plugin) >= 0
&& get_func_id("vex_remove", plugin) >= 0) return true;
return false;
}
VexDuplicateGuard()
{
new self = get_plugin(-1);
new file[128], title[96], ver[32], author[64], status[32], list[512], n;
for (new k = 0; k < get_pluginsnum(); k++)
{
if (k == self) continue;
if (get_plugin(k, file, charsmax(file), title, charsmax(title), ver, charsmax(ver), author, charsmax(author), status, charsmax(status)) == -1)
continue;
new bool:dup = VexIsOldCopy(title, ver, k);
if (!dup && equal(title, PLUGIN) && equal(ver, VERSION) && k > self) dup = true;
if (!dup) continue;
if (equal(status, "running") || equal(status, "debug"))
pause("ac", file);
format(list, charsmax(list), "%s%s%s (%s v%s)", list, n ? ", " : "", file, title, ver);
n++;
}
if (n)
{
log_amx("[Vexmira] !!! UYARI: %d ESKI/CIFT Vexmira eklentisi bulundu ve DURAKLATILDI: %s", n, list);
log_amx("[Vexmira] !!! Bunlari plugins klasorunden ve plugins.ini / plugins-vexmira*.ini satirlarindan SILIN; vexmira_core + vexmira_gear birlikte yuklu olmalidir.");
server_print("[Vexmira] !!! WARNING: %d old/duplicate Vexmira plugin(s) PAUSED: %s", n, list);
server_print("[Vexmira] !!! Delete them and their plugins.ini lines (and configs/plugins-vexmira*.ini); Both vexmira_core and vexmira_gear are required.");
}
}
public CommunityJetCommand(id) { CommunityBuyGear(id,0); return PLUGIN_HANDLED; }
public CommunityHevCommand(id) { client_print(id,print_chat,"[VEXMIRA] HEV zirhi kaldirildi.");return PLUGIN_HANDLED; }
CommunityNativeSurvivor(id) { return id>=1 && id<=32 && g_bSurvivor[id] && is_user_alive(id); }
public CommunityBootMap() { server_cmd("changelevel zm_vexmira_icefy"); }
EpicPrecache()
{
new path[160];
AmbientPrecache49();
EpicGrenadeEvents();
if(file_exists("sprites/vexmira/arena51/gren_flare.spr",true)) g_iEpicFlare=ZcPcModel("sprites/vexmira/arena51/gren_flare.spr");
for(new i=0;i<9;i++) {
formatex(path,charsmax(path),"sprites/vexmira/arena48/boss%d_cast.spr",i);
if(file_exists(path,true) && CommunityLegacyFileOk(path)) g_iEpicGlyph[i]=ZcPcModel(path);
copy(path,charsmax(path),"sprites/vexmira/arena49/bossbar.spr");
g_bEpicBar[i]=!Ovh538(OVS_BOSSBAR) && file_exists(path,true) && CommunityLegacyFileOk(path) && ZcPcModel(path)>0;
}
for(new i=1;i<=10;i++) {
formatex(path,charsmax(path),"sound/vexmira/epic/count/%s.wav",VOX_NUM[i]);
if(file_exists(path,true)) ZcPcGeneric(path);
}
static const cues[][]={"flare"};
for(new i=0;i<sizeof cues;i++) {
formatex(path,charsmax(path),"sound/vexmira/epic/%s.wav",cues[i]);
if(file_exists(path,true)) ZcPcGeneric(path);
}
}
EpicCue(id,const cue[])
{
new path[160];formatex(path,charsmax(path),"vexmira/epic/%s.wav",cue);
new file[168];formatex(file,charsmax(file),"sound/%s",path);
if(!file_exists(file,true)) return;
if(id>0) { if(is_user_connected(id) && !is_user_bot(id) && !(g_iSet[id]&SET_NO_AMB)) VxClientCmd527(id,"spk ^"%s^"",path); return; }
for(new p=1;p<=g_iMax;p++)
if(is_user_connected(p) && !is_user_bot(p) && !(g_iSet[p]&SET_NO_AMB)) VxClientCmd527(p,"spk ^"%s^"",path);
}
public EpicDropCommand(id)
{
if(!is_user_alive(id) || !g_bBoss[id]) return PLUGIN_CONTINUE;
SkillTriggerG(id); return PLUGIN_HANDLED;
}
SkillTriggerG(id)
{
new Float:now=get_gametime();
if(id!=g_iBoss || !g_bRoundActive || !is_user_alive(id)) return;
if(g_fBossIntro>now || g_fFrozen[id]>now || g_iBossChannel!=CH_NONE || task_exists(TASK_BOSSCAST)) {
SkillDeny(id,"BSK_BUSY");return;
}
if(g_fEpicG[id]>now) { SkillDeny(id,"ABILITY_COOL",floatround(g_fEpicG[id]-now,floatround_ceil));return; }
g_fEpicG[id]=now+float(E46_G_COOLED[g_iBossType]);
BossTelegraph(1);
EpicBossCastFx();
rg_set_animation(id,PLAYER_ATTACK2);
new key[24];formatex(key,charsmax(key),"B%d_R2",g_iBossType);EmitKey(id,key,CHAN_STATIC,ATTN_NORM);
HudTo(id,SL_PERS,BOSS_RGB[g_iBossType][0],BOSS_RGB[g_iBossType][1],BOSS_RGB[g_iBossType][2],2.0,E46_BOSS_GKEY[g_iBossType]);
}
EpicBossCastFx()
{
if(!g_iBoss || !is_user_alive(g_iBoss) || g_iBossType<0 || g_iBossType>=9) return;
new Float:o[3];get_entvar(g_iBoss,var_origin,o);
if(g_iEpicGlyph[g_iBossType]) FxSpr(o,g_iEpicGlyph[g_iBossType],7,205,24.0);
FxRingEx(o,BOSS_RGB[g_iBossType][0],BOSS_RGB[g_iBossType][1],BOSS_RGB[g_iBossType][2],220,6,8,160);
}
EpicBossStart(id)
{
if(g_iBossType<0 || g_iBossType>=9) return;
if(g_bEpicBar[g_iBossType]) {
copy(g_szOvhSpr[OVS_BOSSBAR],charsmax(g_szOvhSpr[]),"sprites/vexmira/arena49/bossbar.spr");
ReadSprInfo(OVS_BOSSBAR);
}
EpicBossCastFx();
Chat(id,"E46_BOSSKEYS");
remove_task(TASK_EPIC_MUSIC);set_task(3.0,"EpicBossMusic",TASK_EPIC_MUSIC);
}
public EpicBossMusic()
{
if(!g_bRoundActive || g_bRoundEnded) return;
AmbientPath49();
for(new p=1;p<=g_iMax;p++) if(is_user_connected(p) && !is_user_bot(p)) AmbientClient49(p);
remove_task(TASK_EPIC_MUSIC);set_task(1.0,"EpicBossMusic",TASK_EPIC_MUSIC);
}
EpicRoundStart()
{
Radio52(g_iMode==MODE_BOSS?2:0);
if(!g_bRoundActive) return;
remove_task(TASK_EPIC_MUSIC);set_task(3.0,"EpicBossMusic",TASK_EPIC_MUSIC);
for(new p=1;p<=g_iMax;p++) if(is_user_alive(p) && IsVip(p) && (g_iSet[p]&E46_VIP_SPAWN)) EpicVipFx(p);
}
EpicRoundFinish(WinStatus:status)
{
remove_task(TASK_EPIC_MUSIC);
StopRoundMusic();
if(status!=WINSTATUS_CTS && status!=WINSTATUS_TERRORISTS) return;
for(new p=1;p<=g_iMax;p++) {
if(!is_user_alive(p)) continue;
if((status==WINSTATUS_CTS && !g_bZombie[p]) || (status==WINSTATUS_TERRORISTS && g_bZombie[p])) {
new Float:o[3];get_entvar(p,var_origin,o);
FxRingSmall(o,status==WINSTATUS_CTS?70:220,status==WINSTATUS_CTS?200:50,120);
SigilSpawn47(p,status==WINSTATUS_CTS?0:1,4.0);
if(IsVip(p) && (g_iSet[p]&E46_VIP_WIN)) EpicVipFx(p);
}
}
}
public EpicVipSpawn(task)
{
new id=task-TASK_EPIC_SPAWN;
if(id<1 || id>32 || !is_user_alive(id)) return;
if(IsVip(id) && (g_iSet[id]&E46_VIP_SPAWN)) EpicVipFx(id);
}
EpicVipFx(id)
{
if(!IsVip(id) || !is_user_alive(id) || get_gametime()<g_fEpicVip[id]) return;
new st=(g_iSet[id]&E46_VIP_STYLE_MASK)>>E46_VIP_STYLE_SHIFT;
if(!st) return;
g_fEpicVip[id]=get_gametime()+2.0;
new Float:o[3];get_entvar(id,var_origin,o);
FxElSmall(o,st==1?EL_FIRE:st==2?EL_ICE:EL_VOID,7);
FxRingSmall(o,st==1?230:st==2?80:170,st==1?130:st==2?210:75,st==1?45:255);
}
EpicVipMenu(id)
{
if(!IsVip(id)) { ShowVipInfo(id);return; }
new title[320],item[120];VexHead(id,title,charsmax(title),"E46_VIPFX");
new menu=VexMenuCreate(title,"EpicVipHandler");
new st=(g_iSet[id]&E46_VIP_STYLE_MASK)>>E46_VIP_STYLE_SHIFT,key[24];
formatex(key,charsmax(key),"E46_STYLE%d",st);
formatex(item,charsmax(item),"%L [%L]",id,"E46_STYLE",id,key);MenuAdd(menu,item,1);
formatex(item,charsmax(item),"%L [%L]",id,"E46_SPAWNFX",id,(g_iSet[id]&E46_VIP_SPAWN)?"ON":"OFF");MenuAdd(menu,item,2);
formatex(item,charsmax(item),"%L [%L]",id,"E46_WINFX",id,(g_iSet[id]&E46_VIP_WIN)?"ON":"OFF");MenuAdd(menu,item,3);
formatex(item,charsmax(item),"%L [%L]",id,"E46_KILLFX",id,(g_iSet[id]&E46_VIP_KILL)?"ON":"OFF");MenuAdd(menu,item,4);
formatex(item,charsmax(item),"%L",id,"E46_PREVIEW");MenuAdd(menu,item,5);
formatex(item,charsmax(item),"%L",id,"MENU_BACK");MenuAdd(menu,item,999);
MenuFinish(id,menu);
}
public EpicVipHandler(id,menu,item)
{
if(item<0 || !IsVip(id)) {menu_destroy(menu);return PLUGIN_HANDLED;}
new sel=MenuInfo(menu,item);menu_destroy(menu);
if(sel==999) { ShowVipMenu(id);return PLUGIN_HANDLED; }
switch(sel) {
case 1: {new st=((g_iSet[id]&E46_VIP_STYLE_MASK)>>E46_VIP_STYLE_SHIFT);g_iSet[id]=(g_iSet[id]&~E46_VIP_STYLE_MASK)|(((st+1)%4)<<E46_VIP_STYLE_SHIFT);}
case 2:g_iSet[id]^=E46_VIP_SPAWN;
case 3:g_iSet[id]^=E46_VIP_WIN;
case 4:g_iSet[id]^=E46_VIP_KILL;
case 5:EpicVipFx(id);
}
SaveData(id);EpicVipMenu(id);return PLUGIN_HANDLED;
}
bool:EpicLaserEndpoint(id,const Float:pos[3],const Float:normal[3])
{
new Float:a[3],Float:b[3],Float:end[3];
for(new j=0;j<3;j++) {a[j]=pos[j]+normal[j]*6.0;b[j]=a[j]+normal[j]*8192.0;}
new tr=create_tr2();engfunc(EngFunc_TraceLine,a,b,IGNORE_MONSTERS,id,tr);
new Float:frac;get_tr2(tr,TR_flFraction,frac);get_tr2(tr,TR_vecEndPos,end);free_tr2(tr);
new Float:maxRange=floatclamp(get_pcvar_float(g_pLmMaxRange),64.0,1024.0);
new Float:distance=get_distance_f(a,end);
if(frac<1.0 && distance>=24.0 && distance<=maxRange) return true;
new Float:now=get_gametime();
if(now>=g_fEpicLaserWarn[id]) {
g_fEpicLaserWarn[id]=now+1.5;
Chat(id,"E46_LASER",floatround(maxRange));
HudTo(id,SL_PERS,CLR_WARN,2.0,"E46_LASER",floatround(maxRange));
FxSparks(pos);EmitKey(id,"LM_DENY");
}
return false;
}
EpicGrenadeEvents()
{
static const events[][]={"sound/weapons/AN M14/draw.wav","sound/weapons/AN M14/pinpull.wav","sound/weapons/PL82 BSAA/deploy.wav","sound/weapons/PL82 BSAA/pinpull.wav"};
for(new i=0;i<sizeof events;i++) if(file_exists(events[i],true)) ZcPcGeneric(events[i]);
}
public VxNativeZombie(plugin, params) { if(!g_bRun526) return 0; return CommunityNativeZombie(get_param(1)); }
public VxNativeWeapon(plugin, params) { if(!g_bRun526) return 0; return CommunityNativeWeapon(get_param(1)); }
public VxNativeRestore(plugin, params) { if(!g_bRun526) return 0; return CommunityNativeRestore(get_param(1)); }
public VxNativePrepareJet(plugin, params) { if(!g_bRun526) return 0; return CommunityNativePrepareJet(get_param(1)); }
public VxNativeSurvivor(plugin, params) { if(!g_bRun526) return 0; return CommunityNativeSurvivor(get_param(1)); }
public VxNativeJetpack(plugin, params) { if(!g_bRun526) return 0; return CommunityNativeJetpack(get_param(1)); }
VxPcRemember(const m[])
{
if (g_tPcAll531 == Invalid_Trie) g_tPcAll531 = TrieCreate();
new k[96]; copy(k, charsmax(k), m); strtolower(k);
TrieSetCell(g_tPcAll531, k, 1);
g_bPcReady531 = true;
}
stock bool:VxModelOk(const m[])
{
if (!m[0]) return true;
if (!g_bPcHook531 || !g_bPcReady531 || g_tPcAll531 == Invalid_Trie) return true;
if (equal(m, "models/", 7) && contain(m[7], "/") == -1 && !equal(m[7], "zombie", 6)) return true;
new k[96]; copy(k, charsmax(k), m); strtolower(k);
if (TrieKeyExists(g_tPcAll531, k)) return true;
return VxGearKnows532(m);
}
new g_iGearPl532 = -2, g_iGearFn532 = -1;
stock bool:VxGearKnows532(const m[])
{
if (g_iGearPl532 == -2)
{
g_iGearPl532 = -1;
new n = get_pluginsnum();
for (new i = 0; i < n; i++) { new f = get_func_id("VxGearModelOkPublic", i); if (f >= 0) { g_iGearPl532 = i; g_iGearFn532 = f; break; } }
}
if (g_iGearPl532 < 0) return false;
if (callfunc_begin_i(g_iGearFn532, g_iGearPl532) != 1) return false;
callfunc_push_str(m, false);
new bool:ok = callfunc_end() == 1;
if (ok)
{
new k[96]; copy(k, charsmax(k), m); strtolower(k);
TrieSetCell(g_tPcAll531, k, 1);
}
return ok;
}
public VxModelOkPublic(const m[]) return VxModelOk(m) ? 1 : 0;
#define PC_SAFE_LIMIT531 509
public VxRhPcSoundPre531(const s[])
{
if (g_iSndTop531 < PC_SAFE_LIMIT531 || !s[0]) return HC_CONTINUE;
if (g_tSndSeen531 != Invalid_Trie && TrieKeyExists(g_tSndSeen531, s)) return HC_CONTINUE;
if (g_iSndRefused531++ < 20) log_amx("[PrecacheGuard] ses limiti (%d/512): '%s' yuklenmedi (cokme onlendi)", g_iSndTop531, s);
SetHookChainReturn(ATYPE_INTEGER, 0);
return HC_SUPERCEDE;
}
public VxRhPcSoundPost531(const s[])
{
new idx = GetHookChainReturn(ATYPE_INTEGER);
if (idx <= 0) return HC_CONTINUE;
if (g_tSndSeen531 == Invalid_Trie) g_tSndSeen531 = TrieCreate();
TrieSetCell(g_tSndSeen531, s, idx);
if (idx > g_iSndTop531) g_iSndTop531 = idx;
return HC_CONTINUE;
}
public VxRhPcGenPre531(const s[])
{
if (g_iGenTop531 < PC_SAFE_LIMIT531 || !s[0]) return HC_CONTINUE;
if (g_tGenSeen531 != Invalid_Trie && TrieKeyExists(g_tGenSeen531, s)) return HC_CONTINUE;
if (g_iGenRefused531++ < 20) log_amx("[PrecacheGuard] indirme limiti (%d/512): '%s' eklenmedi (cokme onlendi)", g_iGenTop531, s);
SetHookChainReturn(ATYPE_INTEGER, 0);
return HC_SUPERCEDE;
}
public VxRhPcGenPost531(const s[])
{
new idx = GetHookChainReturn(ATYPE_INTEGER);
if (idx <= 0) return HC_CONTINUE;
if (g_tGenSeen531 == Invalid_Trie) g_tGenSeen531 = TrieCreate();
TrieSetCell(g_tGenSeen531, s, idx);
if (idx > g_iGenTop531) g_iGenTop531 = idx;
return HC_CONTINUE;
}
MapSoundCount531()
{
new map[64], path[96]; get_mapname(map, charsmax(map));
formatex(path, charsmax(path), "maps/%s.bsp", map);
new fp = fopen(path, "rb", true);
if (!fp) return 0;
new ver, off, len;
fread(fp, ver, BLOCK_INT); fread(fp, off, BLOCK_INT); fread(fp, len, BLOCK_INT);
if (len <= 0 || len > 2000000) { fclose(fp); return 0; }
fseek(fp, off, SEEK_SET);
new Trie:seen = TrieCreate(), n, buf[256], cur[128], cl, bool:q;
new got;
while ((got = fread_blocks(fp, buf, sizeof buf, BLOCK_CHAR)) > 0 && len > 0)
{
for (new i = 0; i < got && len > 0; i++, len--)
{
new c = buf[i] & 0xFF;
if (c == '"')
{
if (q && cl > 4)
{
cur[cl] = 0;
if (containi(cur, ".wav") != -1 && !TrieKeyExists(seen, cur)) { TrieSetCell(seen, cur, 1); n++; }
}
q = !q; cl = 0;
continue;
}
if (q && cl < charsmax(cur)) cur[cl++] = c;
}
}
fclose(fp);
TrieDestroy(seen);
log_amx("[PrecacheGuard] harita %s: %d farkli ses dosyasi kullaniyor (eklenti ses butcesi buna gore ayarlanir)", map, n);
return n;
}
VxGuardInit531()
{
if (g_tPcAll531 == Invalid_Trie) g_tPcAll531 = TrieCreate();
register_forward(FM_LightStyle, "fw_LightStyle531", 0);
if (RegisterHookChain(RH_PF_precache_model_I, "VxRhPcModel531", 1)) g_bPcHook531 = true;
else log_amx("[ModelGuard] ReHLDS precache kancasi yok: model korumasi pasif");
RegisterHookChain(RH_PF_precache_sound_I, "VxRhPcSoundPre531", 0);
RegisterHookChain(RH_PF_precache_sound_I, "VxRhPcSoundPost531", 1);
RegisterHookChain(RH_PF_precache_generic_I, "VxRhPcGenPre531", 0);
RegisterHookChain(RH_PF_precache_generic_I, "VxRhPcGenPost531", 1);
g_iMapSnd531 = MapSoundCount531();
}
public VxRhPcModel531(const s[])
{
if (GetHookChainReturn(ATYPE_INTEGER) > 0) VxPcRemember(s);
return HC_CONTINUE;
}
VxGuardLog(const what[], const m[])
{
if (g_iGuardLog531 < 60) { g_iGuardLog531++; log_amx("[ModelGuard] %s: '%s' sunucuda yuklu (precache) degil -> orijinal CS modeli kullanildi (cokme onlendi)", what, m); }
}
VxStockWeaponModel(id, bool:view, out[], len)
{
new w = get_member(id, m_pActiveItem), cls[32];
out[0] = 0;
if (is_nullent(w)) return;
get_entvar(w, var_classname, cls, charsmax(cls));
if (!equal(cls, "weapon_", 7)) return;
formatex(out, len, "models/%s_%s.mdl", view ? "v" : "p", cls[7]);
if (!VxModelOk(out)) out[0] = 0;
}
VxGuardFrame()
{
new Float:t = get_gametime();
if (t == g_fGuardTime531) return;
g_fGuardTime531 = t;
if (!g_bPcReady531) return;
new m[96], st[96];
for (new id = 1; id <= g_iMax; id++)
{
if (!is_user_connected(id)) { g_iGuardV531[id] = 0; g_iGuardP531[id] = 0; continue; }
new v = pev(id, pev_viewmodel), pm = pev(id, pev_weaponmodel);
if (v != g_iGuardV531[id])
{
pev(id, pev_viewmodel2, m, charsmax(m));
if (!VxModelOk(m)) { VxGuardLog("viewmodel", m); VxStockWeaponModel(id, true, st, charsmax(st)); set_pev(id, pev_viewmodel2, st); v = pev(id, pev_viewmodel); }
g_iGuardV531[id] = v;
}
if (pm != g_iGuardP531[id])
{
pev(id, pev_weaponmodel2, m, charsmax(m));
if (!VxModelOk(m)) { VxGuardLog("weaponmodel", m); VxStockWeaponModel(id, false, st, charsmax(st)); set_pev(id, pev_weaponmodel2, st); pm = pev(id, pev_weaponmodel); }
g_iGuardP531[id] = pm;
}
}
}
public VxGuardClientData(id, sendweapons, cd)
{
VxGuardFrame();
return FMRES_IGNORED;
}
VxInfPrecache531()
{
copy(g_szInfV531, charsmax(g_szInfV531), GetResString("NADE_INFECT_V", "models/vexmira/nades/v_infect.mdl"));
copy(g_szInfP531, charsmax(g_szInfP531), GetResString("NADE_INFECT_P", "models/vexmira/nades/p_infect.mdl"));
copy(g_szInfW531, charsmax(g_szInfW531), GetResString("NADE_INFECT_W", "models/vexmira/nades/w_infect.mdl"));
if (!(file_exists(g_szInfV531, true) && ZcPcModel(g_szInfV531) > 0))
{
if (file_exists("models/zombie_plague/v_grenade_infect.mdl", true) && ZcPcModel("models/zombie_plague/v_grenade_infect.mdl") > 0) copy(g_szInfV531, charsmax(g_szInfV531), "models/zombie_plague/v_grenade_infect.mdl");
else copy(g_szInfV531, charsmax(g_szInfV531), "models/v_hegrenade.mdl");
}
if (!(file_exists(g_szInfP531, true) && ZcPcModel(g_szInfP531) > 0)) copy(g_szInfP531, charsmax(g_szInfP531), "models/p_hegrenade.mdl");
if (!(file_exists(g_szInfW531, true) && ZcPcModel(g_szInfW531) > 0)) copy(g_szInfW531, charsmax(g_szInfW531), "models/w_hegrenade.mdl");
log_amx("[Vexmira] enfeksiyon bombasi modelleri: %s | %s | %s", g_szInfV531, g_szInfP531, g_szInfW531);
}
stock VxSM(ent, const m[])
{
if (!VxModelOk(m)) { VxGuardLog("SetModel", m); return 0; }
engfunc(EngFunc_SetModel, ent, m);
return 1;
}
stock VxPlayerModelOk(const name[])
{
new p[128]; formatex(p, charsmax(p), "models/player/%s/%s.mdl", name, name);
if (VxModelOk(p)) return 1;
VxGuardLog("player model", p);
return 0;
}
stock VxSetUserModel(id, const name[], bool:upd = false)
{
if (!VxPlayerModelOk(name)) return 0;
rg_set_user_model(id, name, upd);
return 1;
}
public plugin_precache()
{
g_iIsolation526=ReadIsolation526();
log_to_file("vexmira_groups.log","[530 vexcore] selected profile=%d",g_iIsolation526);g_bRun526=(g_iIsolation526==1 || g_iIsolation526>=3);
log_to_file("vexmira_isolation.log","[530 vexcore] stage=%d full_module=%d precache BEGIN",g_iIsolation526,g_bRun526);
if(!g_bRun526) {log_to_file("vexmira_isolation.log","[530 vexcore] baseline precache READY: no custom resources/hooks");return;}
VxGuardInit531();
RegisterHookChain(RH_Con_Printf,"VxConsole524",0);
RegisterHookChain(RH_SV_ActivateServer,"VxActivatePre524",0);
RegisterHookChain(RH_SV_ActivateServer,"VxActivatePost524",1);
g_iFwPcSnd = register_forward(FM_PrecacheSound, "fw_PcSoundPost", 1);
g_iFwPcMdl = register_forward(FM_PrecacheModel, "fw_PcModelPost", 1);
g_iFwPcGen = register_forward(FM_PrecacheGeneric, "fw_PcGenericPost", 1);
if(file_exists("models/rpgrocket.mdl",true) && CommunityLegacyFileOk("models/rpgrocket.mdl")) g_bCameraReady529=(!VxPcOk531()) ? 0 : precache_model("models/rpgrocket.mdl")>0;
log_to_file("vexmira_startup.log","[5.3.0] BEGIN map preload");
if(vx521_pair_version()!=530) {set_fail_state("VEXMIRA: core + gear version mismatch. Install both v5.3.0 files together.");return;}
if(vxe_version()!=538) {set_fail_state("VEXMIRA: vexmira_extra.amxx (5.3.8) eksik/eski. core + gear + extra birlikte kurulmali.");return;}
g_pZcRewrite=register_cvar("zc_rewrite_configs","0");
new bool:force=get_pcvar_num(g_pZcRewrite)>0;
vx45_write(force);
if(force) set_pcvar_num(g_pZcRewrite,0);
if(cvar_exists("sv_auto_precache_sounds_in_models")) set_cvar_num("sv_auto_precache_sounds_in_models",0);
ZcCore_plugin_precache();
if(g_zcGuardFail) log_amx("[Vexmira] Optional core asset skipped; see AssetGuard log.");
log_to_file("vexmira_startup.log","[5.3.0] core ready; epic begin");
EpicPrecache();
log_to_file("vexmira_startup.log","[5.3.0] epic ready; arsenal begin");
VxPrecache();PrecacheContexts51();
log_to_file("vexmira_startup.log","[5.3.0] COMPLETE map preload");
log_amx("[Vex530] Precache complete: sound=%d model=%d generic=%d",max(g_iTotSnd,g_iPcSnd),max(g_iTotMdl,g_iPcMdl),max(g_iTotGen,g_iPcGen));
}
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
log_to_file("vexmira_isolation.log","[530 vexcore] plugin_init BEGIN stage=%d full=%d",g_iIsolation526,g_bRun526);
register_clcmd("vex_test","IsolationStatus526");
if(!g_bRun526) {register_plugin("Vexmira vexcore Baseline Test","5.3.1-Stable","Vexmira");log_to_file("vexmira_isolation.log","[530 vexcore] baseline plugin_init COMPLETE");return;}
log_to_file("vexmira_startup.log","[530 vexcore] plugin_init BEGIN");
register_forward(FM_UpdateClientData, "VxGuardClientData", 0);
RegisterHookChain(RG_CBasePlayerWeapon_DefaultReload, "VxReloadPre531", false);
RegisterHookChain(RG_CBasePlayerWeapon_DefaultShotgunReload, "VxShotgunReloadPre531", false);
static const GUNS531[][] = { "weapon_p228", "weapon_scout", "weapon_xm1014", "weapon_mac10", "weapon_aug", "weapon_elite",
"weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18",
"weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1",
"weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_p90" };
for (new g531 = 0; g531 < sizeof GUNS531; g531++) RegisterHam(Ham_Weapon_Reload, GUNS531[g531], "VxHamReloadPre531", 0);
ZcCore_plugin_init();
BDoor536_Init();
log_to_file("vexmira_startup.log","[530 core] base init READY");
set_task(30.0,"VexStability51",781951,_,_,"b");
VxRegisterHam524(Ham_Item_AddToPlayer,"weapon_ak47","VxAddToPlayerPost",1);
VxRegisterHam524(Ham_Weapon_PrimaryAttack,"weapon_ak47","VxAttackPre",0);
VxRegisterHam524(Ham_Weapon_Reload,"weapon_ak47","VxReload50",0);
VxRegisterHam524(Ham_Item_Holster,"weapon_ak47","VxHolster50",0);
register_forward(FM_PlaybackEvent,"VxPlaybackEvent");
register_forward(FM_UpdateClientData,"VxClientDataPost",1);
register_forward(FM_Touch,"VxProjectileTouch");register_forward(FM_Think,"VxProjectileThink");
VxRegisterChain524(RG_CBasePlayerWeapon_SendWeaponAnim,"VxSendAnim",false);
register_forward(FM_CmdStart,"fw_CmdStart");
register_forward(FM_EmitSound,"fw_EmitSound");
register_forward(FM_PlayerPreThink,"fw_PreThink");
}
public client_putinserver(id) { if(!g_bRun526) return; ZcCore_client_putinserver(id); }
public client_disconnected(id, bool:drop, message[], maxlen) { if(!g_bRun526) return; ZcCore_client_disconnected(id,drop,message,maxlen); }
ZcPcModel(const path[])
{
if(!AllowModel528(path)) return 0;
if (!file_exists(path, true) || !CommunityLegacyFileOk(path)) {
log_amx("[AssetGuard] EKSIK/BOZUK %s -> modul %s KAPALI (sunucu calismaya devam ediyor)", path, "core");
g_zcGuardFail = true;
return 0;
}
new known51;if(g_tZcModelsReady!=Invalid_Trie && TrieGetCell(g_tZcModelsReady,path,known51)) return known51;
if(max(g_iTotMdl,g_iPcMdl)>=448) {g_zcGuardFail=true;log_amx("[AssetGuard] model limit reserve: %s",path);return 0;}
new modelIndex = (!VxPcOk531()) ? 0 : precache_model(path);
RegisterTexture530(path);
if(g_tZcModelsReady==Invalid_Trie) g_tZcModelsReady=TrieCreate();
TrieSetCell(g_tZcModelsReady,path,modelIndex);
return modelIndex;
}
stock ZcPcSound(const path[])
{
if(!AllowAudio528()) return 0;
if(max(g_iTotSnd,g_iPcSnd)>=448) return 0;
new f[160]; formatex(f, charsmax(f), "sound/%s", path);
if (!file_exists(f, true)) { log_amx("[AssetGuard] UYARI eksik ses %s (atlandi)", f); return 0; }
return (!VxPcOk531()) ? 0 : precache_sound(path);
}
ZcPcGeneric(const path[])
{
if(!AllowGeneric528(path)) return 0;
if(max(g_iTotGen,g_iPcGen)>=448) {log_amx("[AssetGuard] generic reserve: %s",path);return 0;}
if (!file_exists(path, true)) { log_amx("[AssetGuard] UYARI eksik dosya %s (atlandi)", path); return 0; }
return (!VxPcOk531()) ? 0 : precache_generic(path);
}
public cmd_Third47(id)
{
if(!g_bCameraReady529) {client_print(id,print_chat,"[VEXMIRA] Kamera modeli hazir degil; models/rpgrocket.mdl dosyasini yukleyip harita degistirin.");return PLUGIN_HANDLED;}
if (!is_user_connected(id)) return PLUGIN_HANDLED;
g_bThird47[id] = !g_bThird47[id];
if (!g_bThird47[id]) CameraRemove47(id);
client_print(id, print_chat, "[VEXMIRA] 3. kisi kamera: %s. /3pers ile degistir.", g_bThird47[id] ? "ACIK" : "KAPALI");
return PLUGIN_HANDLED;
}
CameraRemove47(id)
{
if(is_user_connected(id) && !is_user_bot(id) && g_iCamera47[id]) set_view(id,CAMERA_NONE);
g_iCamera47[id]=0;
}
CameraTick47(id)
{
if(!g_bCameraReady529) return;
if(!is_user_connected(id) || is_user_bot(id)) return;
new bool:active=g_bThird47[id] && is_user_alive(id);
if(active) {new fov=get_member(id,m_iFOV);if(fov>0 && fov<60) active=false;}
if(!active) {if(g_iCamera47[id]) CameraRemove47(id);return;}
if(g_iCamera47[id]>g_iMax && pev_valid(g_iCamera47[id]) && get_entvar(g_iCamera47[id],var_owner)==id) return;
if(engfunc(EngFunc_NumberOfEntities)>=global_get(glb_maxEntities)-32) return;
if(!set_view(id,CAMERA_3RDPERSON)) return;
new ent=-1;
while((ent=engfunc(EngFunc_FindEntityByString,ent,"classname","VexdCam"))>0) {
if(get_entvar(ent,var_owner)==id) {g_iCamera47[id]=ent;break;}
}
}
bool:KnifeReady47(i) { if(i<0 || i>=KN_TOTAL) return false; if(i<4) return ZcCompOn(i+7); return g_bMkOk[i-4]; }
KnifeName538(c, i, out[], len) { if(!c) copy(out,len,COMMUNITY_CN[i]); else if(i<4) copy(out,len,COMMUNITY_KN[i]); else copy(out,len,g_szMkName[i-4]); }
KnifeCost538(c, i) { if(!c || i<4) return COMMUNITY_COIN[c][i]; return g_iMkCost[i-4]; }
BannerRemove47(id)
{
UiHudRestore52(id);
if(g_iBanner47[id]>0 && !is_nullent(g_iBanner47[id])) engfunc(EngFunc_RemoveEntity,g_iBanner47[id]);
g_iBanner47[id]=0;
}
BannerShow47(id,kind,Float:duration)
{
BannerRemove47(id);
if(!is_user_connected(id) || (g_iSet[id] & SET_NO_FX) || kind<0 || kind>4 || !g_iBannerModel47[kind]) return;
if(kind==3) FadeOne(id,0,0,0,100,duration);
new ent=CreateSafe51("info_target");
if(!ent || is_nullent(ent)) return;
g_iBanner47[id]=ent; g_iBannerKind47[id]=kind;
g_fBannerStart47[id]=get_gametime(); g_fBannerEnd47[id]=get_gametime()+duration;
set_entvar(ent,var_classname,"vex_screen47");
VxSM(ent,BANNER47[kind]);
set_entvar(ent,var_solid,SOLID_NOT);set_entvar(ent,var_movetype,MOVETYPE_NOCLIP);
set_entvar(ent,var_rendermode,kind==4?kRenderTransAlpha:kRenderTransAdd);set_entvar(ent,var_renderamt,220.0);
set_entvar(ent,var_scale,0.0183);set_entvar(ent,var_iuser4,470047);
set_entvar(ent,var_owner,id);BannerTick47(id);
}
BannerTick47(id)
{
new ent=g_iBanner47[id];if(!ent || is_nullent(ent)) return;
new Float:now=get_gametime();
if(!is_user_connected(id) || now>=g_fBannerEnd47[id]) { BannerRemove47(id);return; }
new source=id;
if(!is_user_alive(id) && get_entvar(id,var_iuser1)==4) {
new target=get_entvar(id,var_iuser2);if(target>=1 && target<=g_iMax && is_user_alive(target)) source=target;
}
new Float:o[3],Float:v[3],Float:a[3],Float:aim[3];
if(g_iCamera47[id]>0 && !is_nullent(g_iCamera47[id]) && is_user_alive(id)) {
get_entvar(g_iCamera47[id],var_origin,o);get_entvar(id,var_v_angle,a);
} else {
get_entvar(source,var_origin,o);get_entvar(source,var_view_ofs,v);
for(new j=0;j<3;j++) o[j]+=v[j];get_entvar(source,var_v_angle,a);
}
engfunc(EngFunc_MakeVectors,a);global_get(glb_v_forward,aim);
for(new j=0;j<3;j++) o[j]+=aim[j]*8.0;
if(g_iBannerKind47[id]==4 && g_iUiPage52[id]!=53 && g_iUiPage52[id]!=54) {
new Float:up52[3];global_get(glb_v_up,up52);for(new j=0;j<3;j++) o[j]+=up52[j]*1.65;
}
engfunc(EngFunc_SetOrigin,ent,o);
new fov47=get_member(id,m_iFOV);if(fov47<=0) fov47=90;
set_entvar(ent,var_scale,0.0183*floattan(float(clamp(fov47,10,120))*0.5,degrees));
set_entvar(ent,var_frame,float(g_iBannerKind47[id]==4?g_iUiPage52[id]:8));
new Float:fade=(g_iUiPage52[id]==53 || g_iUiPage52[id]==54)?1.0:floatmin(1.0,(now-g_fBannerStart47[id])*5.0)*floatmin(1.0,(g_fBannerEnd47[id]-now)*4.0);
new Float:pulse530=1.0;
if(g_iBannerKind47[id]==4 && g_iUiPage52[id]!=53 && g_iUiPage52[id]!=54) pulse530=0.875+0.125*floatsin((now-g_fBannerStart47[id])*25.132741);
set_entvar(ent,var_renderamt,fade*235.0*pulse530);
}
public fw_BannerPack47(es,e,ent,host,hostflags,player,pSet)
{
if(player || ent<=g_iMax || is_nullent(ent)) return FMRES_IGNORED;
if(get_entvar(ent,var_iuser4)==470048) { if(g_iSet[host]&SET_NO_FX) set_es(es,ES_Effects,get_es(es,ES_Effects)|EF_NODRAW);return FMRES_IGNORED; }
if(get_entvar(ent,var_iuser4)!=470047 && get_entvar(ent,var_iuser4)!=470049) return FMRES_IGNORED;
if(get_entvar(ent,var_owner)!=host || (g_iSet[host]&SET_NO_FX)) set_es(es,ES_Effects,get_es(es,ES_Effects)|EF_NODRAW);
else if(get_entvar(ent,var_iuser4)==470047) {
BannerTick47(host);new Float:pos52[3];get_entvar(ent,var_origin,pos52);set_es(es,ES_Origin,pos52);
set_es(es,ES_Velocity,Float:{0.0,0.0,0.0});set_es(es,ES_MoveType,MOVETYPE_NONE);
set_es(es,ES_Frame,Float:get_entvar(ent,var_frame));set_es(es,ES_Scale,Float:get_entvar(ent,var_scale));
set_es(es,ES_RenderAmt,floatround(Float:get_entvar(ent,var_renderamt)));
}
return FMRES_IGNORED;
}
SigilSpawn47(id,kind,Float:duration)
{
if(!is_user_alive(id) || kind<0 || kind>1 || !g_iSigil47[kind]) return;
new ent=CreateSafe51("info_target");
if(!ent || is_nullent(ent)) return;
set_entvar(ent,var_classname,"vex_sigil47");VxSM(ent,SIGIL47[kind]);
set_entvar(ent,var_solid,SOLID_NOT);set_entvar(ent,var_movetype,MOVETYPE_NOCLIP);
set_entvar(ent,var_iuser1,id);set_entvar(ent,var_iuser2,get_user_userid(id));set_entvar(ent,var_iuser4,470048);
set_entvar(ent,var_scale,0.65);set_entvar(ent,var_fuser1,get_gametime()+duration);
SetThink(ent,"SigilThink47");SigilThink47(ent);
}
public SigilThink47(ent)
{
if(is_nullent(ent)) return;
new id=get_entvar(ent,var_iuser1);new Float:now=get_gametime();
if(now>=Float:get_entvar(ent,var_fuser1) || id<1 || id>g_iMax || !is_user_alive(id) || get_user_userid(id)!=get_entvar(ent,var_iuser2)) {
engfunc(EngFunc_RemoveEntity,ent);return;
}
new Float:o[3],Float:a[3];get_entvar(id,var_origin,o);
o[2]+=OvhTopOf(id)+30.0+floatsin(now*3.0,radian)*4.0;
engfunc(EngFunc_SetOrigin,ent,o);a[1]=float(floatround(now*95.0)%360);set_entvar(ent,var_angles,a);
set_entvar(ent,var_nextthink,now+0.05);
}
new Float:g_fJetBar48[33];
public VxGaugeNative47(plugin,params)
{
if(!g_bRun526) return 0;
if(params!=3) return 0;
new id=get_param(1),percent=get_param(2),fuel=clamp(get_param(3),0,100);
if(id<1||id>g_iMax||!is_user_connected(id)) return 0;
if(percent<0) {GaugeRemove47(id);return 1;}
if(!is_user_alive(id)) return 0;
g_fGaugeEnd47[id]=get_gametime()+1.5;
new nowpct=clamp(percent,0,100),seconds=max(0,(100-nowpct+9)/10);
if(nowpct<100 && !g_iPlantAction[id] && get_gametime()>=g_fJetBar48[id]) {
rg_send_bartime2(id,10,float(nowpct),false);g_fJetBar48[id]=get_gametime()+1.0;
} else if(nowpct==100 && g_fJetBar48[id]>0.0 && !g_iPlantAction[id]) {rg_send_bartime(id,0,false);g_fJetBar48[id]=0.0;}
if(!(g_iSet[id]&SET_NO_HUD)) {
set_hudmessage(80,200,255,-1.0,0.78,0,0.0,1.2,0.0,0.0,2);
if(seconds) show_hudmessage(id,"JETPACK  |  Yakit %d%%^nFUZE DOLUMU  %d%%  /  %d sn",fuel,nowpct,seconds);
else show_hudmessage(id,"JETPACK  |  Yakit %d%%^nFUZE HAZIR  [Sag tik]",fuel);
}
return 1;
}
GaugeRemove47(id)
{
if(g_iGauge47[id]>0 && !is_nullent(g_iGauge47[id])) engfunc(EngFunc_RemoveEntity,g_iGauge47[id]);
if(is_user_connected(id) && g_fGaugeEnd47[id]>0.0) {set_hudmessage(80,200,255,-1.0,0.78,0,0.0,0.01,0.0,0.0,2);show_hudmessage(id,"");}
g_iGauge47[id]=0;g_fGaugeEnd47[id]=0.0;
if(is_user_connected(id) && g_fJetBar48[id]>0.0 && !g_iPlantAction[id]) rg_send_bartime(id,0,false);
g_fJetBar48[id]=0.0;
}
GaugeTick47(id)
{
if(g_fGaugeEnd47[id]>0.0 && (!is_user_alive(id)||get_gametime()>g_fGaugeEnd47[id])) GaugeRemove47(id);
}
TitanStomp47(id)
{
new Float:now=get_gametime();
if(now<g_fCool[id]) {SkillDeny(id,"ABILITY_COOL",floatround(g_fCool[id]-now,floatround_ceil));return;}
if(!(get_entvar(id,var_flags)&FL_ONGROUND)) {SkillDeny(id,"SKILL_NEED_GROUND");return;}
new ent=CreateSafe51("info_target");
if(!ent || is_nullent(ent)) return;
g_fCool[id]=now+18.0;
new Float:o[3];get_entvar(id,var_origin,o);engfunc(EngFunc_SetOrigin,ent,o);
set_entvar(ent,var_classname,"vex_titan_stomp47");set_entvar(ent,var_iuser1,id);
set_entvar(ent,var_iuser2,get_user_userid(id));set_entvar(ent,var_iuser3,g_iRound);
set_entvar(ent,var_solid,SOLID_NOT);set_entvar(ent,var_movetype,MOVETYPE_NONE);
FxRingEx(o,255,125,30,240,6,8);EmitKey(id,"B0_R1",CHAN_BODY,ATTN_NORM);rg_set_animation(id,PLAYER_ATTACK1);
SetThink(ent,"TitanImpact47");set_entvar(ent,var_nextthink,now+0.65);
}
public TitanImpact47(ent)
{
if(is_nullent(ent)) return;
new id=get_entvar(ent,var_iuser1);
if(id<1 || id>g_iMax || !is_user_alive(id) || !g_bRoundActive || g_bRoundEnded || g_iEvent!=EV_TITAN || !g_bFirst[id]
|| get_user_userid(id)!=get_entvar(ent,var_iuser2) || g_iRound!=get_entvar(ent,var_iuser3)) {engfunc(EngFunc_RemoveEntity,ent);return;}
new Float:o[3],Float:po[3];get_entvar(ent,var_origin,o);o[2]+=16.0;
FxRingEx(o,255,105,30,240,14,8);FxExploEl(o,EL_FIRE,12,18);EpicCue(0,"skill0");
for(new victim=1;victim<=g_iMax;victim++) {
if(!is_user_alive(victim) || g_bZombie[victim]) continue;
get_entvar(victim,var_origin,po);new Float:dist=get_distance_f(o,po);if(dist>240.0) continue;
new tr=create_tr2();engfunc(EngFunc_TraceLine,o,po,IGNORE_MONSTERS,ent,tr);new Float:frac;get_tr2(tr,TR_flFraction,frac);free_tr2(tr);if(frac<0.98) continue;
new Float:vel[3];vel[0]=po[0]-o[0];vel[1]=po[1]-o[1];new Float:len=floatsqroot(vel[0]*vel[0]+vel[1]*vel[1]);
if(len>1.0) {vel[0]*=300.0/len;vel[1]*=300.0/len;} vel[2]=210.0;set_entvar(victim,var_velocity,vel);
ExecuteHamB(Ham_TakeDamage,victim,ent,id,45.0*(1.0-dist/480.0),DMG_SONIC);
}
engfunc(EngFunc_RemoveEntity,ent);
}
public msg_WinText47(msg,dest,id)
{
if(get_msg_args()<2 || get_msg_argtype(2)!=ARG_STRING) return PLUGIN_CONTINUE;
new text[64];get_msg_arg_string(2,text,charsmax(text));
if(equal(text,"#CTs_Win") || equal(text,"#Terrorists_Win")) return PLUGIN_HANDLED;
return PLUGIN_CONTINUE;
}
CommunityCosState48(ent,id,c,i)
{
if(c!=1) return;
new Float:v[3];get_entvar(id,var_velocity,v);
new seq=v[0]*v[0]+v[1]*v[1]>1600.0?g_iCmMove48[c][i]:g_iCmIdle48[c][i];
if(get_entvar(ent,var_sequence)!=seq) {set_entvar(ent,var_sequence,seq);set_entvar(ent,var_frame,0.0);set_entvar(ent,var_animtime,get_gametime());}
}
new const Float:B48_RADIUS[]={73.335,53.709,48.229,60.847,64.140,31.390,99.053,39.908,51.787,119.421};
new const Float:B48_TOP[]={67.444,42.342,42.549,62.244,54.408,46.006,76.248,49.794,54.493,98.587};
new const Float:B48_DUCK[]={66.067,40.659,43.843,58.077,58.834,38.945,51.533,46.217,45.655,68.575};
public BossBounds48(id)
{
if(id<1 || id>g_iMax || !is_user_alive(id)) return FMRES_IGNORED;
new idx=-1;if(g_bBoss[id] && id==g_iBoss && g_iBossType>=0 && g_iBossType<9) idx=g_iBossType;
else if(g_iEvent==EV_TITAN && g_bFirst[id] && g_bZombie[id]) idx=9;
if(idx<0)
{
if(!get_pcvar_num(g_pAutoHit531)) return FMRES_IGNORED;
OvhModelTops(id);
new bool:duck531=(get_entvar(id,var_flags)&FL_DUCKING)?true:false;
new Float:top531=duck531?g_fOvhDuck[id]:g_fOvhStand[id];
new Float:hull531=duck531?18.0:36.0;
if(top531<=hull531+2.0 || top531>200.0) return FMRES_IGNORED;
new Float:hi531[3];get_entvar(id,var_absmax,hi531);
new Float:o531[3];get_entvar(id,var_origin,o531);
hi531[2]=floatmax(hi531[2],o531[2]+top531+4.0);
set_entvar(id,var_absmax,hi531);
return FMRES_IGNORED;
}
new Float:o[3],Float:lo[3],Float:hi[3];get_entvar(id,var_origin,o);
new Float:gk=(idx<9 && g_fBossScale531>1.0 && (g_iGiantMode532==1 || containi(g_szBModel[g_iBossType],"_x")!=-1))?g_fBossScale531:1.0;
new Float:r=floatclamp(B48_RADIUS[idx]*gk,24.0,160.0);
lo[0]=o[0]-r;lo[1]=o[1]-r;lo[2]=o[2]-40.0;hi[0]=o[0]+r;hi[1]=o[1]+r;
hi[2]=o[2]+((get_entvar(id,var_flags)&FL_DUCKING)?B48_DUCK[idx]:B48_TOP[idx])*gk+36.0*(gk-1.0);
set_entvar(id,var_absmin,lo);set_entvar(id,var_absmax,hi);
return FMRES_IGNORED;
}
MeleeIndex48(id)
{
if(id<1||id>g_iMax||!CommunityAlive(id)||get_user_weapon(id)!=CSW_KNIFE) return -1;
new sel=g_iCommunitySel[id][1];if(sel<5||sel>KN_TOTAL||!(g_iCommunityOwned[id][1]&(1<<(sel-1)))||!KnifeReady47(sel-1)) return -1;
if(ZcCall(ZC_HEV,ZCOP_has,id)||ZcCall(ZC_JETPACK,ZCOP_has,id)) return -1;
return sel-5;
}
MeleeAnim48(id,seq)
{
set_entvar(id,var_weaponanim,seq);
message_begin(MSG_ONE,SVC_WEAPONANIM,_,id);write_byte(seq);write_byte(0);message_end();
}
public MeleeDeploy48(weapon)
{
new id=get_member(weapon,m_pPlayer),idx=MeleeIndex48(id);if(idx<0) return HAM_IGNORED;
MeleeAnim48(id,g_iMkAnim[idx][0]);set_member(id,m_flNextAttack,0.75);set_member(weapon,m_Weapon_flTimeWeaponIdle,1.1);return HAM_IGNORED;
}
public MeleePrimary48(weapon) {return MeleeAttack48(weapon,false);}
public MeleeSecondary48(weapon) {return MeleeAttack48(weapon,true);}
public MeleeIdle48(weapon)
{
new id=get_member(weapon,m_pPlayer),idx=MeleeIndex48(id);if(idx<0) return HAM_IGNORED;
if(Float:get_member(weapon,m_Weapon_flTimeWeaponIdle)<=0.0) {MeleeAnim48(id,g_iMkAnim[idx][1]);set_member(weapon,m_Weapon_flTimeWeaponIdle,6.0);}
return HAM_SUPERCEDE;
}
MeleeAttack48(weapon,bool:heavy)
{
new id=get_member(weapon,m_pPlayer),idx=MeleeIndex48(id);if(idx<0) return HAM_IGNORED;
new Float:now=get_gametime();
if(heavy && now<g_fMelee48[id]) {set_member(weapon,m_Weapon_flNextSecondaryAttack,0.25);return HAM_SUPERCEDE;}
new Float:delay=g_fMkRate[idx][heavy?1:0];
set_member(weapon,m_Weapon_flNextPrimaryAttack,delay);set_member(weapon,m_Weapon_flNextSecondaryAttack,delay);set_member(weapon,m_Weapon_flTimeWeaponIdle,delay+0.5);
if(heavy) g_fMelee48[id]=now+delay+1.0;
MeleeAnim48(id,heavy?g_iMkAnim[idx][3]:g_iMkAnim[idx][2]);rg_set_animation(id,PLAYER_ATTACK1);
new snd[96];MkPick(heavy&&g_szMkStab[idx][0]?g_szMkStab[idx]:g_szMkSw[idx],snd,charsmax(snd));if(snd[0]) EmitSafe(id,CHAN_WEAPON,snd,0.65,ATTN_NORM);
new Float:a[3],Float:o[3],Float:ofs[3],Float:f[3],Float:end[3],Float:hit[3];get_entvar(id,var_origin,o);get_entvar(id,var_view_ofs,ofs);get_entvar(id,var_v_angle,a);
for(new j=0;j<3;j++) o[j]+=ofs[j];engfunc(EngFunc_MakeVectors,a);global_get(glb_v_forward,f);
new Float:rng=g_fMkRange[idx]*(heavy?1.2:1.0);
for(new j=0;j<3;j++) end[j]=o[j]+f[j]*rng;
new tr=create_tr2();engfunc(EngFunc_TraceLine,o,end,DONT_IGNORE_MONSTERS,id,tr);
new target=get_tr2(tr,TR_pHit);new Float:frac;get_tr2(tr,TR_flFraction,frac);
if(frac==1.0) {engfunc(EngFunc_TraceHull,o,end,DONT_IGNORE_MONSTERS,HULL_HEAD,id,tr);target=get_tr2(tr,TR_pHit);}
get_tr2(tr,TR_vecEndPos,hit);free_tr2(tr);
if(target<1||target>g_iMax||!is_user_alive(target)||!g_bZombie[target]) return HAM_SUPERCEDE;
MkPick(g_szMkHit[idx],snd,charsmax(snd));if(snd[0]) EmitSafe(id,CHAN_ITEM,snd,0.7,ATTN_NORM);
new Float:dmg=g_fMkDmg[idx][heavy?1:0];
if(g_iMkFx[idx]==6 && !random(10)) {dmg*=3.0;MkBreak538(hit);}
if(g_iMkFx[idx]==7) {if(now-g_fMkComboAt[id]>2.0) g_iMkCombo[id]=0;g_fMkComboAt[id]=now;if(++g_iMkCombo[id]>=3) {g_iMkCombo[id]=0;dmg*=1.5;FxRingEx(hit,255,210,120,110,5,4);}}
ExecuteHamB(Ham_TakeDamage,target,weapon,id,dmg,DMG_SLASH);
if(!(g_iSet[id]&SET_NO_FX)) FxRingSmall(hit,255,120,60);
if(!heavy || !is_user_alive(target)) return HAM_SUPERCEDE;
switch(g_iMkFx[idx]) {
case 0: {Ignite(target,id,2);FxExploEl(hit,EL_FIRE,5,16);}
case 1: {ChainLightning(target,id,35.0);FxSparks(hit);}
case 2: {if(!g_bBoss[target]&&!g_bNemesis[target]&&!g_bAssassin[target]) Freeze(target,0.6);FxExploEl(hit,EL_ICE,5,16);}
case 3: {new Float:v[3];for(new j=0;j<3;j++) v[j]=f[j]*180.0;v[2]=120.0;set_entvar(target,var_velocity,v);FxRingEx(hit,255,185,80,130,6,5);}
case 4: {FxExploEl(hit,EL_TOXIC,5,16);for(new k=1;k<=g_iMax;k++) if(k!=target&&is_user_alive(k)&&g_bZombie[k]&&entity_range(k,target)<140.0) ExecuteHamB(Ham_TakeDamage,k,weapon,id,g_fMkDmg[idx][1]*0.4,DMG_SLASH);}
case 6: MkBreak538(hit);
case 5: {FxExploEl(hit,EL_VOID,5,16);for(new k=1;k<=g_iMax;k++) if(is_user_alive(k)&&g_bZombie[k]&&!g_bBoss[k]&&entity_range(k,target)<220.0) {new Float:kp[3],Float:d[3],Float:vv[3];get_entvar(k,var_origin,kp);for(new j=0;j<3;j++) d[j]=hit[j]-kp[j];new Float:l=vector_length(d);if(l>1.0){for(new j=0;j<2;j++) vv[j]=d[j]/l*320.0;vv[2]=160.0;set_entvar(k,var_velocity,vv);}}}
}
return HAM_SUPERCEDE;
}
// 5.3.8: knife table from vex_res MK<n>_* (n = 1..MK_MAX); a slot without a v_ model file is hidden
MeleePrecache48()
{
static const DEF[MK_MAX][][] = {
{"Balrog-9 / Ates Yumrugu", "models/vexmira/arena48/v_balrog.mdl", "models/vexmira/arena48/p_balrog.mdl", "vexmira/arena48/melee/balrog", "6 0 1 11", "500", "0"},
{"Janus-9 / Yildirim", "models/vexmira/arena48/v_janus.mdl", "models/vexmira/arena48/p_janus.mdl", "vexmira/arena48/melee/janus", "9 0 3 11", "650", "1"},
{"", "", "", "", "0 0 1 2", "700", "2"}, {"", "", "", "", "0 0 1 2", "750", "3"}, {"", "", "", "", "0 0 1 2", "800", "4"}, {"", "", "", "", "0 0 1 2", "850", "5"} };
static const EXTRA_SND[][] = {"vexmira/arena48/melee/balrog_balrog9_charge_finish1.wav","vexmira/arena48/melee/balrog_balrog9_charge_start1.wav",
"vexmira/arena48/melee/balrog_balrog9_draw.wav","vexmira/arena48/melee/janus_janus9_stab1.wav","vexmira/arena48/melee/janus_janus9_stab2.wav"};
new key[24], val[160], parts[4][8];
for (new i = 0; i < MK_MAX; i++)
{
formatex(key, charsmax(key), "MK%d_NAME", i + 1); copy(g_szMkName[i], charsmax(g_szMkName[]), GetResString(key, DEF[i][0]));
formatex(key, charsmax(key), "MK%d_V", i + 1); copy(g_szMkV[i], charsmax(g_szMkV[]), GetResString(key, DEF[i][1]));
formatex(key, charsmax(key), "MK%d_P", i + 1); copy(g_szMkP[i], charsmax(g_szMkP[]), GetResString(key, DEF[i][2]));
formatex(key, charsmax(key), "MK%d_SND", i + 1); copy(g_szMkSnd[i], charsmax(g_szMkSnd[]), GetResString(key, DEF[i][3]));
formatex(key, charsmax(key), "MK%d_ANIM", i + 1); copy(val, charsmax(val), GetResString(key, DEF[i][4]));
parse(val, parts[0], 7, parts[1], 7, parts[2], 7, parts[3], 7);
for (new k = 0; k < 4; k++) g_iMkAnim[i][k] = str_to_num(parts[k]);
formatex(key, charsmax(key), "MK%d_COST", i + 1); g_iMkCost[i] = str_to_num(GetResString(key, DEF[i][5]));
formatex(key, charsmax(key), "MK%d_FX", i + 1); g_iMkFx[i] = str_to_num(GetResString(key, DEF[i][6]));
formatex(key, charsmax(key), "MK%d_DMG", i + 1); copy(val, charsmax(val), GetResString(key, "1.0"));
parse(val, parts[0], 7, parts[1], 7);
if (parts[1][0]) { g_fMkDmg[i][0] = floatclamp(str_to_float(parts[0]), 1.0, 5000.0); g_fMkDmg[i][1] = floatclamp(str_to_float(parts[1]), 1.0, 9000.0); }
else { new Float:mult = floatclamp(str_to_float(val), 0.1, 10.0); g_fMkDmg[i][0] = 170.0 * mult; g_fMkDmg[i][1] = 520.0 * mult; }
formatex(key, charsmax(key), "MK%d_RATE", i + 1); copy(val, charsmax(val), GetResString(key, "0.65 1.2"));
parts[1][0] = 0; parse(val, parts[0], 7, parts[1], 7);
g_fMkRate[i][0] = floatclamp(str_to_float(parts[0]), 0.2, 3.0); g_fMkRate[i][1] = parts[1][0] ? floatclamp(str_to_float(parts[1]), 0.3, 5.0) : 1.2;
MkResLong(i, "SWING", g_szMkSw[i], charsmax(g_szMkSw[])); MkResLong(i, "HIT", g_szMkHit[i], charsmax(g_szMkHit[])); MkResLong(i, "STAB", g_szMkStab[i], charsmax(g_szMkStab[]));
formatex(key, charsmax(key), "MK%d_RANGE", i + 1); g_fMkRange[i] = floatclamp(str_to_float(GetResString(key, "90")), 48.0, 200.0);
formatex(key, charsmax(key), "MK%d_KB", i + 1); g_fMkKb[i] = floatclamp(str_to_float(GetResString(key, "1.0")), 0.0, 5.0);
g_bMkOk[i] = false;
if (!g_szMkV[i][0] || !g_szMkName[i][0] || !file_exists(g_szMkV[i], true)) { g_szMkV[i][0] = 0; continue; }
g_bMkOk[i] = ZcPcModel(g_szMkV[i]) > 0;
if (g_szMkP[i][0] && file_exists(g_szMkP[i], true)) ZcPcModel(g_szMkP[i]); else g_szMkP[i][0] = 0;
if (!g_szMkSw[i][0]) { if (g_szMkSnd[i][0]) formatex(g_szMkSw[i], charsmax(g_szMkSw[]), "%s_swing.wav", g_szMkSnd[i]); else copy(g_szMkSw[i], charsmax(g_szMkSw[]), "weapons/knife_slash1.wav|weapons/knife_slash2.wav"); }
if (!g_szMkHit[i][0]) { if (g_szMkSnd[i][0]) formatex(g_szMkHit[i], charsmax(g_szMkHit[]), "%s_hit.wav", g_szMkSnd[i]); else copy(g_szMkHit[i], charsmax(g_szMkHit[]), "weapons/knife_hit1.wav|weapons/knife_hit2.wav|weapons/knife_hit3.wav|weapons/knife_hit4.wav"); }
if (!g_szMkStab[i][0] && !g_szMkSnd[i][0]) copy(g_szMkStab[i], charsmax(g_szMkStab[]), "weapons/knife_stab.wav");
MkPcList(g_szMkSw[i]); MkPcList(g_szMkHit[i]); MkPcList(g_szMkStab[i]);
if (g_iMkFx[i] == 6 && !g_iMkGib538) g_iMkGib538 = ZcPcModel("models/woodgibs.mdl");
new extra[200]; MkResLong(i, "SOUNDS", extra, charsmax(extra)); MkPcList(extra);
}
if (g_bMkOk[0] || g_bMkOk[1]) for (new k = 0; k < sizeof EXTRA_SND; k++) ZcPcSound(EXTRA_SND[k]);
}
MkResLong(i, const what[], out[], len)
{
new key[24]; formatex(key, charsmax(key), "MK%d_%s", i + 1, what); out[0] = 0;
if (g_tRes != Invalid_Trie) TrieGetString(g_tRes, key, out, len);
}
MkPcList(const list[])
{
new rest[200], one[96]; copy(rest, charsmax(rest), list);
while (rest[0]) { strtok(rest, one, charsmax(one), rest, charsmax(rest), '|'); trim(one); if (one[0] && !equal(one, "weapons/", 8) && !equali(one, "off")) ZcPcSound(one); }
}
MkPick(const list[], out[], len)
{
new n = 1; for (new k = 0; list[k]; k++) if (list[k] == '|') n++;
new want = random(n), rest[200], c; copy(rest, charsmax(rest), list); out[0] = 0;
while (rest[0]) { strtok(rest, out, len, rest, charsmax(rest), '|'); trim(out); if (c++ == want) break; }
if (equali(out, "off")) out[0] = 0;
}
bool:CosCanFollow49(id,c)
{
if(!equal(g_szCosModel49[id],g_szOvhMdl[id])) {
g_fCosAt50[id]=0.0;
copy(g_szCosModel49[id],charsmax(g_szCosModel49[]),g_szOvhMdl[id]);
g_bCosAnchor49[id][0]=false;g_bCosAnchor49[id][1]=false;g_iCosBone50[id][0]=-1;g_iCosBone50[id][1]=-1;
new path[128];formatex(path,charsmax(path),"models/player/%s/%s.mdl",g_szOvhMdl[id],g_szOvhMdl[id]);
new fp=fopen(path,"rb",true);
if(fp) {
new count,offset,lab[33];fseek(fp,140,SEEK_SET);fread(fp,count,BLOCK_INT);fread(fp,offset,BLOCK_INT);
if(count>0 && count<=128 && offset>=244) for(new b=0;b<count;b++) {
fseek(fp,offset+b*112,SEEK_SET);fread_blocks(fp,lab,32,BLOCK_CHAR);lab[32]=0;
if(equali(lab,"Bip01 Spine2")) {g_bCosAnchor49[id][0]=true;g_iCosBone50[id][0]=b;}
if(equali(lab,"Bip01 Head")) {g_bCosAnchor49[id][1]=true;g_iCosBone50[id][1]=b;}
}
fclose(fp);
}
}
return g_bCosAnchor49[id][c==2?1:0];
}
CommunityPetMove49(id)
{
if(id<1 || id>g_iMax || !is_user_alive(id)) return;
new ent=g_iCmEnt[id][1];if(!ent) return;
new Float:now=get_gametime();if(now<g_fPetMove49[id]) return;g_fPetMove49[id]=now+0.02;
if(!CmValid(ent,id)) return;
new i=g_iCmInfo[ent]%16;if(i<0 || i>=CM_MAX || g_fCmOfs[1][i][2]>=0.0) return;
new Float:o[3],Float:a[3];get_entvar(id,var_origin,o);get_entvar(id,var_angles,a);
new Float:y=a[1]*0.0174532925,Float:cs=floatcos(y),Float:sn=floatsin(y);
g_fPetRel49[id][0]=(g_fCmOfs[1][i][0]*cs-g_fCmOfs[1][i][1]*sn)*g_fPetWall49[id];
g_fPetRel49[id][1]=(g_fCmOfs[1][i][0]*sn+g_fCmOfs[1][i][1]*cs)*g_fPetWall49[id];
o[0]+=g_fPetRel49[id][0];o[1]+=g_fPetRel49[id][1];o[2]=g_fPetFloor49[id];
engfunc(EngFunc_SetOrigin,ent,o);a[0]=g_fCmAng[1][i][0];a[1]+=g_fCmAng[1][i][1];a[2]=g_fCmAng[1][i][2];set_entvar(ent,var_angles,a);
}
bool:AmbientValid49(const path[])
{
new len=strlen(path);if(len<12 || len>=159 || !equal(path,"sound/",6) || !(equali(path[len-4],".wav") || equali(path[len-4],".mp3")) || contain(path,"..")!=-1) return false;
for(new j=0;j<len;j++) if(!((path[j]>='a'&&path[j]<='z')||(path[j]>='A'&&path[j]<='Z')||(path[j]>='0'&&path[j]<='9')||path[j]=='_'||path[j]=='/'||path[j]=='.'||path[j]=='-')) return false;
return file_exists(path,true)?true:false;
}
AmbientPrecache49()
{
if(g_tAmbientReady52==Invalid_Trie) g_tAmbientReady52=TrieCreate();
static const AMB_MODE[]={0,1,2,2,3,3,1,1,7,6}, AMB_EVENT[]={0,4,5,1,3,1,5,1,0,7,1,7,7,7,3,5,2,4,5};
static const AMB_BED[][]={"calm","tension","hunt","hope","storm","frost","boss","chaos"};
new path[160],key[32];
for(new kind=0;kind<3;kind++) for(new j=0;j<(kind==0?MODE_TOTAL:(kind==1?EV_TOTAL:9));j++) {
formatex(key,charsmax(key),"AMBIENT_%s%d",kind==0?"MODE":(kind==1?"EVENT":"BOSS"),j);
if(!TrieGetString(g_tRes,key,path,charsmax(path))) {
new bed=kind==2?6:(kind==0?AMB_MODE[min(j,sizeof AMB_MODE-1)]:AMB_EVENT[min(j,sizeof AMB_EVENT-1)]);
formatex(path,charsmax(path),"sound/vexmira/s534/amb_%s.wav",AMB_BED[bed]);
if(!file_exists(path,true)) formatex(path,charsmax(path),"sound/vexmira/amb532/%s.wav",AMB_BED[bed]);
if(!file_exists(path,true)) formatex(path,charsmax(path),"sound/vexmira/arena52/ambience/%s%d.wav",kind==0?"mode":(kind==1?"event":"boss"),j);
TrieSetString(g_tRes,key,path);
}
if(path[0] && !TrieKeyExists(g_tAmbientReady52,path) && AmbientValid49(path) && (containi(path,".mp3")!=-1 ? ZcPcGeneric(path)>0 : PcSound(path[6])>0)) TrieSetCell(g_tAmbientReady52,path,1);
}
UiHudPrecache52();
RadioPrecache52();
NativePrecache52();
ZcPcSound("vexmira/arena52/foley/scope.wav");
}
AmbientPath49()
{
new key[32],path[160];
if(g_iMode==MODE_BOSS && g_iBossType>=0 && g_iBossType<9) {formatex(key,charsmax(key),"AMBIENT_BOSS%d",g_iBossType);}
else if(g_iEvent>EV_NONE && g_iEvent<EV_TOTAL) {formatex(key,charsmax(key),"AMBIENT_EVENT%d",g_iEvent);}
else {formatex(key,charsmax(key),"AMBIENT_MODE%d",g_iMode);}
// 5.3.8: file_exists() through the game file system cost ~9 ms per call every second; validate once per path
static lastKey[32], lastRaw[160], lastOk[160];
if(!TrieGetString(g_tRes,key,path,charsmax(path))) path[0]=0;
if(!equal(key,lastKey) || !equal(path,lastRaw)) {copy(lastKey,charsmax(lastKey),key);copy(lastRaw,charsmax(lastRaw),path);if(!AmbientValid49(path)) path[0]=0;copy(lastOk,charsmax(lastOk),path);}
else copy(path,charsmax(path),lastOk);
if(!equal(path,g_szAmbient49)) {copy(g_szAmbient49,charsmax(g_szAmbient49),path);g_iAmbientEpoch49++;}
}
AmbientStop52(id)
{
if(g_szAmbientPlaying52[id][0] && is_user_connected(id) && !is_user_bot(id)) {
if(containi(g_szAmbientPlaying52[id],".mp3")!=-1) VxClientCmd527(id,"mp3 stop");
else rh_emit_sound2(id,id,CHAN_STREAM,g_szAmbientPlaying52[id][6],0.0,ATTN_NONE,SND_STOP,PITCH_NORM);
}
g_szAmbientPlaying52[id][0]=0;g_iAmbientUser49[id]=0;
}
AmbientClient49(id)
{
if(id<1 || id>g_iMax || !is_user_connected(id) || is_user_bot(id)) return;
new dbg=get_cvar_num("vex_debug_audio");
if(!g_bRoundActive || g_bRoundEnded || (g_iSet[id]&SET_NO_AMB) || !g_szAmbient49[0]) {if(dbg) log_amx("[AudioDbg] ambiyans #%d yok: round=%d bitti=%d kapali=%d yol='%s'",id,g_bRoundActive,g_bRoundEnded,(g_iSet[id]&SET_NO_AMB)?1:0,g_szAmbient49);AmbientStop52(id);return;}
if(g_tAmbientReady52==Invalid_Trie || !TrieKeyExists(g_tAmbientReady52,g_szAmbient49)) {if(dbg) log_amx("[AudioDbg] ambiyans '%s' yuklenmemis",g_szAmbient49);AmbientStop52(id);return;}
new Float:now=get_gametime(),stamp=g_iAmbientEpoch49*2048+get_user_userid(id);
if(g_iAmbientUser49[id]==stamp && now<g_fAmbientNext49[id]) return;
AmbientStop52(id);
if(containi(g_szAmbient49,".mp3")!=-1) VxClientCmd527(id,"mp3 loop ^"%s^"",g_szAmbient49);
else rh_emit_sound2(id,id,CHAN_STREAM,g_szAmbient49[6],floatclamp(get_pcvar_float(g_pAmbVol532),0.05,1.0),ATTN_NONE,0,PITCH_NORM);
if(dbg) log_amx("[AudioDbg] ambiyans #%d CAL %s",id,g_szAmbient49);
copy(g_szAmbientPlaying52[id],charsmax(g_szAmbientPlaying52[]),g_szAmbient49);
g_iAmbientUser49[id]=stamp;g_fAmbientNext49[id]=now+(containi(g_szAmbient49,".mp3")!=-1?3600.0:get_pcvar_float(g_pAmbRe532));
}
CosTick50(id)
{
if(id<1 || id>g_iMax || !is_user_alive(id) || (!g_iCmEnt[id][0] && !g_iCmEnt[id][2])) return;
new Float:now=get_gametime();if(now<g_fCosAt50[id]) return;g_fCosAt50[id]=now+0.01;
OvhModelTops(id);CosCanFollow49(id,0);
new Float:o[3],Float:p[3],Float:a[3];get_entvar(id,var_origin,o);
for(new j=0;j<2;j++) if(g_iCosBone50[id][j]>=0) {
engfunc(EngFunc_GetBonePosition,id,g_iCosBone50[id][j],p,a);
for(new k=0;k<3;k++) g_fCosAnchor50[id][j][k]=p[k]-o[k];
}
for(new c=0;c<3;c+=2) {
new ent=g_iCmEnt[id][c];if(!ent || !CmValid(ent,id)) continue;
new i=g_iCmInfo[ent]%16;if(i<CM_MAX) CommunityCosOrigin(ent,id,c,i);
}
}
bool:StockModel50(const path[])
{
if(!equal(path,"models/p_",9) && !equal(path,"models/w_",9)) return false;
if(equali(path,"models/w_knife.mdl")) return false;
if(equali(path,"models/vexmira_ze/skins/vexmira_p_mp5.mdl") || equali(path,"models/vexmira_ze/skins/vexmira_w_mp5.mdl")) return true;
new candidate[64];for(new w=1;w<31;w++) {
formatex(candidate,charsmax(candidate),"models/p_%s.mdl",WEAPON_KEYNAME[w]);if(equali(path,candidate)) return true;
formatex(candidate,charsmax(candidate),"models/w_%s.mdl",WEAPON_KEYNAME[w]);if(equali(path,candidate)) return true;
}
return false;
}
public VxReload50(w)
{
new sw=VxIndex(w);if(sw<0) return HAM_IGNORED;
new id=get_member(w,m_pPlayer);if(!CommunityAlive(id)) return HAM_SUPERCEDE;
if(Float:get_entvar(w,var_fuser2)>0.0 || get_member(w,m_Weapon_iClip)>=SW_CLIP[sw] || rg_get_user_bpammo(id,WEAPON_AK47)<=0) return HAM_SUPERCEDE;
new Float:t=floatclamp(V50_RELOAD_TIME[sw],1.0,4.0);set_entvar(w,var_fuser2,get_gametime()+t);
set_member(w,m_Weapon_fInReload,false);set_member(id,m_flNextAttack,t);set_member(w,m_Weapon_flNextPrimaryAttack,t);set_member(w,m_Weapon_flTimeWeaponIdle,t+0.1);VxAnim(id,w,V50_RELOAD[sw]);
return HAM_SUPERCEDE;
}
VxReloadTick50(id)
{
if(id<1 || id>g_iMax || !is_user_alive(id) || g_bZombie[id]) return;
new w=get_member(id,m_pActiveItem);if(is_nullent(w)) return;new sw=VxIndex(w);if(sw<0) return;
new Float:until=Float:get_entvar(w,var_fuser2);if(until<=0.0 || get_gametime()<until) return;
set_entvar(w,var_fuser2,0.0);new clip=get_member(w,m_Weapon_iClip),bp=rg_get_user_bpammo(id,WEAPON_AK47),add=min(max(0,SW_CLIP[sw]-clip),bp);
set_member(w,m_Weapon_iClip,clip+add);rg_set_user_bpammo(id,WEAPON_AK47,bp-add);
}
public VxHolster50(w) {if(VxIndex(w)>=0) set_entvar(w,var_fuser2,0.0);return HAM_IGNORED;}
VxPierce51(id) {
new victim=g_iVxHit51[id];if(victim<1||victim>g_iMax||!g_bZombie[victim])return;
new Float:start[3],Float:dir[3],Float:end[3];xs_vec_sub(g_fVxEnd[id],g_fVxStart[id],dir);xs_vec_normalize(dir,dir);xs_vec_mul_scalar(dir,2.0,start);xs_vec_add(start,g_fVxEnd[id],start);xs_vec_mul_scalar(dir,320.0,end);xs_vec_add(start,end,end);
new tr=create_tr2();engfunc(EngFunc_TraceLine,start,end,DONT_IGNORE_MONSTERS,victim,tr);VxDamage(get_tr2(tr,TR_pHit),id,id,45.0);free_tr2(tr);
}
VxPellets51(id) {
new Float:a[3],Float:f[3],Float:b[3],Float:ang[3],Float:p[3];VxAim(id,a,f,b,ang);
for(new v=1;v<=g_iMax;v++) {if(!is_user_alive(v)||!g_bZombie[v])continue;get_entvar(v,var_origin,p);p[2]+=16.0;new Float:d=get_distance_f(a,p);if(d<1.0||d>360.0)continue;xs_vec_sub(p,a,p);xs_vec_normalize(p,p);if(xs_vec_dot(p,f)>0.965&&VxLOS(a,v,id))VxDamage(v,id,id,55.0*(1.0-d/480.0));}
}
VxGunkata51(id,const Float:a[3]) {
new Float:p[3],n;VxSound(id,7,6,CHAN_ITEM);FxRingEx(a,255,185,55,240,8,3);FxSprite(a,g_iSkillSpr51[7],12,200);
for(new v=1;v<=g_iMax&&n<8;v++) {if(!is_user_alive(v)||!g_bZombie[v])continue;get_entvar(v,var_origin,p);p[2]+=16.0;if(get_distance_f(a,p)>240.0||!VxLOS(a,v,id))continue;FxBeamEx(a,p,g_sprBeam,255,185,55,5,0,2,175);VxDamage(v,id,id,165.0);n++;}
}
CreateSafe51(const classname[],const bool:useHashTable=false) {
new cap=global_get(glb_maxEntities),used=engfunc(EngFunc_NumberOfEntities);
if(cap>128&&used>=cap-32) {static Float:warn51;new Float:now=get_gametime();if(now>=warn51){warn51=now+5.0;log_to_file("vexmira_stability.log","SPAWN_DENIED used=%d capacity=%d classname=%s",used,cap,classname);}return NULLENT;}
return rg_create_entity(classname,useHashTable);
}
public VexStability51() {
new players,cos,projectiles;for(new i=1;i<=g_iMax;i++)if(is_user_connected(i)){players++;for(new c;c<3;c++)if(CmValid(g_iCmEnt[i][c],i))cos++;}
for(new j;j<VX_MAX_PROJECTILES;j++)if(VxOwnedEntity(g_iVxProjectiles[j]))projectiles++;
log_to_file("vexmira_stability.log","players=%d mode=%d event=%d boss=%d entities=%d/%d cosmetics=%d projectiles=%d",players,g_iMode,g_iEvent,g_iBossType,engfunc(EngFunc_NumberOfEntities),global_get(glb_maxEntities),cos,projectiles);
}
PrecacheContexts51() {
new key[32],path[128];for(new kind;kind<2;kind++)for(new i;i<(kind?EV_TOTAL:MODE_TOTAL);i++){formatex(path,charsmax(path),"sound/vexmira/arena51/cues/%s%d.wav",kind?"event":"mode",i);ZcPcGeneric(path);}
for(new i;i<24;i++){formatex(key,charsmax(key),"Z%d_ABILITY",i);PrecacheSoundKeyEx(key,false);}
}
Float:OverheadTop52(id)
{
new Float:top=(get_entvar(id,var_flags)&FL_DUCKING)?g_fOvhDuck[id]:g_fOvhStand[id];
if(g_bBoss[id] && g_iBossType>=0 && g_iBossType<9) top=floatmax(top,(get_entvar(id,var_flags)&FL_DUCKING)?B48_DUCK[g_iBossType]:B48_TOP[g_iBossType]);
if(g_bBoss[id] && id==g_iBoss && g_iGiantMode532==1 && g_fBossScale531>1.01) {new Float:k=g_fBossScale531;top=top*k+((get_entvar(id,var_flags)&FL_DUCKING)?18.0:36.0)*(k-1.0);}
CosCanFollow49(id,2);
new bone=g_iCosBone50[id][1];
if(bone>=0) {new Float:p[3],Float:a[3],Float:o[3];engfunc(EngFunc_GetBonePosition,id,bone,p,a);get_entvar(id,var_origin,o);top=floatmax(top,p[2]-o[2]+12.0);}
return floatclamp(top,12.0,400.0);
}
bool:UiShow52(id,page,Float:duration,priority)
{
if(id<1 || id>g_iMax || !is_user_connected(id) || is_user_bot(id) || !get_pcvar_num(g_pUi52) || (g_iSet[id]&SET_NO_FX)) return false;
new key[32], r=55, g=205, b=255;
page=clamp(page,0,63);
if(get_pcvar_num(g_pHudMin538) && ((page>=29 && page<=37) || page==58 || page==59 || page==60 || page==62 || page==63)) return false;
if(page<=9) { formatex(key,charsmax(key),"MODE_ANN_%d",page); r=255; g=170; b=55; }
else if(page<=28) { formatex(key,charsmax(key),"EV_ANN_%d",page-9); r=90; g=210; b=255; }
else if(page<=37) { formatex(key,charsmax(key),"BOSS_ANN_%d",page-29); r=220; g=90; b=255; }
else if(page<=52) { VexCountdown(id,page-37); return true; }
else if(page==53) return CsoNotify(id,CN_HWIN);
else if(page==54) return CsoNotify(id,CN_ZWIN);
else if(page==55) return CsoNotify(id,CN_INFECT);
else if(page==56) return CsoNotify(id,CN_LAST);
else if(page==57) return CsoNotify(id,CN_LEVEL, g_iLevel[id]);
else if(page==58) { copy(key,charsmax(key),"EV_ANN_8"); r=75; g=200; b=255; }
else if(page==59) { formatex(key,charsmax(key),"BOSS_PHASE_%d",clamp(g_iBossPhase,1,3)); r=190; g=90; b=255; }
else if(page==60) { VexPlainAnnounce(id,"OBJECTIVE COMPLETE","GOREV TAMAMLANDI",70,220,145,duration); return true; }
else if(page==61) return CsoNotify(id,CN_HS);
else if(page==63) { VexPlainAnnounce(id,"BOSS ABILITY","BOSS YETENEGI",220,100,255,duration); return true; }
else { copy(key,charsmax(key),"ROUND_CALM"); }
VexLocalizedAnnounce(id,key,r,g,b,duration);
return true;
}
UiAll52(page,Float:duration,priority) {for(new id=1;id<=g_iMax;id++) UiShow52(id,page,duration,priority);}
RadioPrecache52()
{
new path[128];for(new i=0;i<15;i++) {
formatex(path,charsmax(path),"sound/vexmira/arena52/radio/%s.wav",RADIO_FILE52[i]);
g_bRadioReady52[i]=file_exists(path,true) && ZcPcGeneric(path)>0;
}
new enpath[128];for(new j=0;j<10;j++) {formatex(enpath,charsmax(enpath),"sound/vexmira/arena521/radio/en/%s.wav",RADIO_EN_FILES521[j]);g_bRadioEn521[j]=file_exists(enpath,true) && ZcPcGeneric(enpath)>0;}
}
Radio52(i)
{
new dbg=get_cvar_num("vex_debug_audio");
if(i<0 || i>=15 || !g_bRadioReady52[i] || !get_pcvar_num(g_pRadio52)) {if(dbg) log_amx("[AudioDbg] radio %d: hazir degil (ready=%d cvar=%d)",i,(i>=0&&i<15)?g_bRadioReady52[i]:-1,get_pcvar_num(g_pRadio52));return;}
new Float:now=get_gametime();if(now<floatmax(g_fRadioBusy52,g_fRdBusy) || now<g_fRadioAt52[i]) {if(dbg) log_amx("[AudioDbg] radio %d: mesgul/bekleme",i);return;}
if(dbg) log_amx("[AudioDbg] radio %d CAL (%s)",i,RADIO_FILE52[i]);
new path[128];formatex(path,charsmax(path),"vexmira/arena52/radio/%s.wav",RADIO_FILE52[i]);
new en=RADIO_EN_MAP521[i],enpath[128];formatex(enpath,charsmax(enpath),"vexmira/arena521/radio/en/%s.wav",RADIO_EN_FILES521[en]);
for(new p=1;p<=g_iMax;p++) if(is_user_connected(p)&&!is_user_bot(p)&&!(g_iSet[p]&(SET_NO_AMB|SET_NO_RADIO52))) {
if(g_iLang[p]==2) VxClientCmd527(p,"spk ^"%s^"",path);
else if(g_bRadioEn521[en]) VxClientCmd527(p,"spk ^"%s^"",enpath);
if(get_pcvar_num(g_pRadioText532)) {
if(g_iLang[p]==2) client_print_color(p,print_team_grey,"^4((TELSIZ))^3 %s:^1 %s ^4*kssht*",RADIO_WHO_TR52[RADIO_WHO52[i]],RADIO_TXT_TR52[i]);
else client_print_color(p,print_team_grey,"^4((RADIO))^3 %s:^1 %s ^4*kssht*",RADIO_WHO_EN52[RADIO_WHO52[i]],RADIO_TXT_EN52[i]);
}
}
g_fRadioBusy52=now+floatmax(RADIO_LENGTH52[i],RADIO_EN_LENGTH521[en])+0.8;g_fRadioAt52[i]=now+25.0;g_fRadioNext52=now+floatmax(45.0,get_pcvar_float(g_pRadioInterval52));g_iRadioLast52=i;
}
RadioEvent52(ev)
{
switch(ev) {case EV_METEOR:Radio52(7);case EV_STORM:Radio52(9);case EV_BLACKOUT,EV_NIGHT:Radio52(10);case EV_SUPPLY:Radio52(3);case EV_BLOODMOON:Radio52(1);}
}
RadioTick52()
{
if(!g_bRoundActive || g_bRoundEnded || get_gametime()<g_fRadioNext52 || !get_pcvar_num(g_pRadio52)) return;
new i=random_num(11,14);if(i==g_iRadioLast52)i=11+(i-10)%4;Radio52(i);
}
UiHudPrecache52()
{
for(new page=0;page<64;page++) g_bUiHudFiles52[page]=false;
}
UiHudRestore52(id)
{
new w=g_iUiHudWpn52[id];
if(w>=1 && w<=30 && is_user_connected(id) && get_user_userid(id)==g_iUiHudUid52[id]) {
CsoSendWL(id,g_szWL[w],w);
if(is_user_alive(id)) {new clip,ammo,cw=get_user_weapon(id,clip,ammo);if(cw>=1 && cw<=30)CsoCurW(id,cw,clip);}
}
g_iUiHudWpn52[id]=0;g_bUiHudActive52[id]=false;
}
UiHudTick52(id)
{
if(id<1 || id>g_iMax || !g_bUiHudActive52[id]) return;
new Float:now=get_gametime();
if(!is_user_connected(id) || get_user_userid(id)!=g_iUiHudUid52[id] || now>=g_fBannerEnd47[id] || (g_iSet[id]&SET_NO_FX)) {UiHudRestore52(id);return;}
if(!is_user_alive(id)) {new Float:remain=g_fBannerEnd47[id]-now;UiHudRestore52(id);BannerShow47(id,4,remain);return;}
if(!CsoFovOk(id)) {UiHudRestore52(id);return;}
new clip,ammo,w=get_user_weapon(id,clip,ammo);if(w<1 || w>30 || !g_bWL[w]) {UiHudRestore52(id);return;}
if(w!=g_iUiHudWpn52[id] && g_iUiHudWpn52[id]>0) {new old=g_iUiHudWpn52[id];CsoSendWL(id,g_szWL[old],old);}
new frame=(g_iUiPage52[id]==53 || g_iUiPage52[id]==54)?0:(floatround((now-g_fBannerStart47[id])*2.5)%2);
if(w==g_iUiHudWpn52[id] && frame==g_iUiHudFrame52[id] && now<g_fUiHudNext52[id]) return;
new name[40];formatex(name,charsmax(name),"vexmira/arena52/hud/n%02d%d",g_iUiPage52[id],frame);
CsoSendWL(id,name,w);CsoCurW(id,w,clip);g_iUiHudWpn52[id]=w;g_iUiHudFrame52[id]=frame;g_fUiHudNext52[id]=now+0.4;
}
stock HamHook:VxRegisterHam524(Ham:fn,const cls[],const cb[],post=0,bool:specialbot=false) {
new HamHook:h=RegisterHam(fn,cls,cb,post,specialbot);
return h;
}
stock HookChain:VxRegisterChain524(ReAPIFunc:fn,const cb[],post=0) {
new HookChain:h=RegisterHookChain(fn,cb,post);
return h;
}
public VxActivatePre524(runPhysics) {
log_to_file("vexmira_startup.log","[530 vexcore] ServerActivate PRE physics=%d",runPhysics);
return HC_CONTINUE;
}
public VxActivatePost524(runPhysics) {
log_to_file("vexmira_startup.log","[530 vexcore] ServerActivate POST");
return HC_CONTINUE;
}
new bool:g_bConsole524;
public VxConsole524(const line[]) {
if(g_bConsole524) return HC_CONTINUE;
if(get_gametime()>60.0 && containi(line,"error")==-1 && containi(line,"fatal")==-1 && containi(line,"overflow")==-1 && containi(line,"alloc")==-1) return HC_CONTINUE;
g_bConsole524=true;
log_to_file("vex_engine_console.log","%s",line);
g_bConsole524=false;
return HC_CONTINUE;
}
stock ReadIsolation526() {
new p[192];get_configsdir(p,charsmax(p));add(p,charsmax(p),"/vexmira_isolation.ini");
new fp=fopen(p,"rt");if(!fp) return 0;
new line[32];fgets(fp,line,charsmax(line));fclose(fp);trim(line);
return clamp(str_to_num(line),0,10);
}
public IsolationStatus526(id) {
console_print(id,"[530 vexcore] stage=%d full_module=%d; 4=assets off; 5=models only; 6=audio only; 7=sprites only",g_iIsolation526,g_bRun526);
return PLUGIN_HANDLED;
}
stock bool:StockAsset527(const path[]) {
if(StockModel50(path)) return true;
new candidate[96];
for(new w=1;w<31;w++) {formatex(candidate,charsmax(candidate),"models/v_%s.mdl",WEAPON_KEYNAME[w]);if(equali(path,candidate)) return true;}
static const players[][]={"gign","gsg9","sas","urban","leet","terror","arctic","guerilla","vip","spetsnaz","militia"};
for(new j=0;j<sizeof players;j++) {formatex(candidate,charsmax(candidate),"models/player/%s/%s.mdl",players[j],players[j]);if(equali(path,candidate)) return true;}
return false;
}
stock VxClientCmd527(id,const fmt[],any:...) {
new text[512];vformat(text,charsmax(text),fmt,3);
if(!AllowAudio528() && (containi(text,"spk ")!=-1 || containi(text,"mp3 play")!=-1)) return 0;
return client_cmd(id,"%s",text);
}
stock bool:GroupProfile528() { return g_iIsolation526>=4 && g_iIsolation526<=10; }
stock bool:AllowAudio528() { return !GroupProfile528() || g_iIsolation526==6 || g_iIsolation526==8 || g_iIsolation526==10; }
stock bool:HasSuffix528(const path[],const suffix[]) {
new a=strlen(path),b=strlen(suffix);return a>=b && equali(path[a-b],suffix);
}
stock bool:AllowModel528(const path[]) {
if(!GroupProfile528() || StockAsset527(path)) return true;
if(HasSuffix528(path,".spr")) return g_iIsolation526==7 || g_iIsolation526==9 || g_iIsolation526==10;
if(HasSuffix528(path,".mdl")) return g_iIsolation526==5 || g_iIsolation526==8 || g_iIsolation526==9;
return false;
}
stock bool:AllowGeneric528(const path[]) {
if(!GroupProfile528()) return true;
if(equal(path,"sound/",6) || HasSuffix528(path,".wav") || HasSuffix528(path,".mp3")) return g_iIsolation526==6 || g_iIsolation526==8 || g_iIsolation526==10;
if(equal(path,"sprites/",8) || HasSuffix528(path,".spr")) return g_iIsolation526==7 || g_iIsolation526==9 || g_iIsolation526==10;
if(HasSuffix528(path,".mdl")) return g_iIsolation526==5 || g_iIsolation526==8 || g_iIsolation526==9;
return equal(path,"events/",7)?true:false;
}
stock RegisterTexture530(const path[]) {
new length=strlen(path);if(length<5 || !equali(path[length-4],".mdl")) return;
new tex[192];copy(tex,charsmax(tex),path);tex[length-4]=0;add(tex,charsmax(tex),"T.mdl");
if(file_exists(tex,true)) ZcPcGeneric(tex);
}
#define BD536_MAX 48
new g_iBdEnt536[BD536_MAX], Float:g_fBdHp536[BD536_MAX], g_iBdNum536, Float:g_fBdHud536[33];
public Polish536_HeadshotSnd(id)
{
new Float:now = get_gametime();
if (now - g_fHsSnd536[id] < 0.12 || is_user_bot(id)) return;
g_fHsSnd536[id] = now;
static snd[64]; get_pcvar_string(g_pHsSnd536, snd, charsmax(snd));
if (snd[0]) client_cmd(id, "spk %s", snd);
}
public Urban536_Appearance(id, slot)
{
if (!get_pcvar_num(g_pNoUrban536) || get_member(id, m_iTeam) != 2) return HC_CONTINUE;
if (slot < 2 || slot > 4) SetHookChainArg(2, ATYPE_INTEGER, random_num(2, 4));
return HC_CONTINUE;
}
public Urban536_SpawnPost(id)
{
if (!get_pcvar_num(g_pNoUrban536) || !is_user_alive(id)) return;
new mdl[32]; cs_get_user_model(id, mdl, charsmax(mdl));
if (equali(mdl, "urban")) cs_set_user_model(id, "gign");
}
bool:Arena536_Parse(const key[], const val[])
{
new sx[16], sy[16], sz[16], sa[16];
new n = parse(val, sx, charsmax(sx), sy, charsmax(sy), sz, charsmax(sz), sa, charsmax(sa));
if (n < 3) return false;
new Float:p[4];
p[0] = str_to_float(sx); p[1] = str_to_float(sy); p[2] = str_to_float(sz); p[3] = (n >= 4) ? str_to_float(sa) : 0.0;
if (floatabs(p[0]) > 4096.0 || floatabs(p[1]) > 4096.0 || floatabs(p[2]) > 4096.0) return false;
if (equali(key, "boss")) { g_fArB536 = p; g_bArB536 = true; return true; }
if (equali(key, "human"))
{
if (g_iArHN536 >= sizeof g_fArH536) return false;
g_fArH536[g_iArHN536++] = p;
return true;
}
return false;
}
bool:Arena536_Put(id, const Float:p[4])
{
static const Float:OFF[][3] =
{
{0.0, 0.0, 0.0}, {0.0, 0.0, 12.0}, {40.0, 0.0, 4.0}, {-40.0, 0.0, 4.0}, {0.0, 40.0, 4.0}, {0.0, -40.0, 4.0},
{40.0, 40.0, 4.0}, {-40.0, -40.0, 4.0}, {40.0, -40.0, 4.0}, {-40.0, 40.0, 4.0},
{80.0, 0.0, 8.0}, {-80.0, 0.0, 8.0}, {0.0, 80.0, 8.0}, {0.0, -80.0, 8.0}, {80.0, 80.0, 8.0}, {-80.0, -80.0, 8.0},
{80.0, -80.0, 8.0}, {-80.0, 80.0, 8.0}, {120.0, 0.0, 12.0}, {-120.0, 0.0, 12.0}, {0.0, 120.0, 12.0}, {0.0, -120.0, 12.0}
};
new Float:t[3];
for (new i = 0; i < sizeof OFF; i++)
{
t[0] = p[0] + OFF[i][0]; t[1] = p[1] + OFF[i][1]; t[2] = p[2] + OFF[i][2];
if (engfunc(EngFunc_PointContents, t) == CONTENTS_SOLID) continue;
if (!IsHullFree(id, t)) continue;
engfunc(EngFunc_SetOrigin, id, t);
set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
set_entvar(id, var_basevelocity, Float:{0.0, 0.0, 0.0});
new Float:ang[3];
ang[1] = p[3];
set_entvar(id, var_angles, ang);
set_entvar(id, var_v_angle, ang);
set_entvar(id, var_fixangle, 1);
FxTeleport(t);
return true;
}
return false;
}
public task_Arena536()
{
if (!g_iBoss || !is_user_alive(g_iBoss) || !g_bArB536 || !g_iArHN536) return;
new moved;
arrayset(g_iArTp536, 0, sizeof g_iArTp536);
if (Arena536_Put(g_iBoss, g_fArB536)) { g_iArTp536[g_iBoss] = 1; moved++; }
new start = random(g_iArHN536), k;
for (new p = 1; p <= g_iMax; p++)
{
if (p == g_iBoss || !is_user_alive(p) || g_bZombie[p]) continue;
new bool:ok;
for (new j = 0; j < g_iArHN536 && !ok; j++)
{
k = (start + j) % g_iArHN536;
ok = Arena536_Put(p, g_fArH536[k]);
}
start = (k + 1) % g_iArHN536;
if (ok) { g_iArTp536[p] = 1; moved++; }
}
log_amx("[Vexmira] boss arenasi: %d oyuncu isinlandi (%d nokta)", moved, g_iArHN536);
if (!moved) return;
ChatAll("BOSS_ARENA_TP");
// 5.3.8: arena cards (ar1..ar10) already announced the teleport
set_task(0.35, "task_Arena536Fix", TASK_INTRO + 3);
}
public task_Arena536Fix()
{
static const Float:OFFS[][3] =
{
{0.0, 0.0, 18.0}, {32.0, 0.0, 0.0}, {-32.0, 0.0, 0.0}, {0.0, 32.0, 0.0}, {0.0, -32.0, 0.0},
{32.0, 32.0, 18.0}, {-32.0, -32.0, 18.0}, {32.0, -32.0, 18.0}, {-32.0, 32.0, 18.0}, {0.0, 0.0, 48.0},
{64.0, 0.0, 0.0}, {-64.0, 0.0, 0.0}, {0.0, 64.0, 0.0}, {0.0, -64.0, 0.0}
};
new Float:o[3], Float:t[3];
for (new p = 1; p <= g_iMax; p++)
{
if (!g_iArTp536[p] || !is_user_alive(p) || !IsStuck(p)) continue;
get_entvar(p, var_origin, o);
for (new i = 0; i < sizeof OFFS; i++)
{
t[0] = o[0] + OFFS[i][0]; t[1] = o[1] + OFFS[i][1]; t[2] = o[2] + OFFS[i][2];
if (IsHullFree(p, t)) { engfunc(EngFunc_SetOrigin, p, t); break; }
}
}
}
BDoor536_Init()
{
g_pArenaTp536 = register_cvar("vex_boss_arena_tp", "1");
g_pNoUrban536 = register_cvar("vex_no_urban", "1");
RegisterHookChain(RG_HandleMenu_ChooseAppearance, "Urban536_Appearance", false);
RegisterHam(Ham_Spawn, "player", "Urban536_SpawnPost", 1);
g_pGunDmg536 = register_cvar("vex_gun_damage_mult", "1.35");
g_pHudCalm538 = register_cvar("vex_hud_calm", "1");
ZupMarks538();
g_pMenuPlain538 = register_cvar("vex_menu_plain", "1");
g_pMenuGap539 = register_cvar("vex_menu_gap", "0");
g_pSkDmg538 = register_cvar("vex_sknife_damage_mult", "2.5");
g_pSkKb538 = register_cvar("vex_sknife_knockback", "430");
g_pSkBoss538 = register_cvar("vex_sknife_boss_kb", "0.25");
g_pKBMax536 = register_cvar("vex_knockback_max", "650");
g_pHsSnd536 = register_cvar("vex_headshot_sound", "buttons/blip1");
g_pBdHp536 = register_cvar("vex_bdoor_hp", "1200");
g_pBdBoss536 = register_cvar("vex_bdoor_boss_mult", "4.0");
RegisterHam(Ham_TakeDamage, "func_door", "BDoor536_TakeDamage", 0);
set_task(1.0, "BDoor536_Scan");
}
public BDoor536_Scan()
{
g_iBdNum536 = 0;
g_iBdGib536 = 0;
new ent = -1, nm[16];
while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_door")) > 0 && g_iBdNum536 < BD536_MAX)
{
pev(ent, pev_netname, nm, charsmax(nm));
if (!equal(nm, "vxbd")) continue;
g_iBdEnt536[g_iBdNum536++] = ent;
}
if (g_iBdNum536 && g_tPcAll531 != Invalid_Trie && TrieKeyExists(g_tPcAll531, "models/woodgibs.mdl"))
g_iBdGib536 = engfunc(EngFunc_ModelIndex, "models/woodgibs.mdl");
BDoor536_RestoreAll();
if (g_iBdNum536) log_amx("[Vexmira] kirilabilir kapi: %d", g_iBdNum536);
}
BDoor536_Index(ent)
{
for (new i = 0; i < g_iBdNum536; i++) if (g_iBdEnt536[i] == ent) return i;
return -1;
}
public BDoor536_RestoreAll()
{
new Float:hp = get_pcvar_float(g_pBdHp536);
for (new i = 0; i < g_iBdNum536; i++)
{
new ent = g_iBdEnt536[i];
if (!pev_valid(ent)) continue;
g_fBdHp536[i] = hp;
set_pev(ent, pev_solid, SOLID_BSP);
set_pev(ent, pev_effects, pev(ent, pev_effects) & ~EF_NODRAW);
set_pev(ent, pev_takedamage, DAMAGE_YES);
set_pev(ent, pev_health, 100000.0);
new Float:o[3]; pev(ent, pev_origin, o); engfunc(EngFunc_SetOrigin, ent, o);
}
}
public BDoor536_TakeDamage(ent, inflictor, attacker, Float:dmg, bits)
{
new i = BDoor536_Index(ent);
if (i < 0) return HAM_IGNORED;
set_pev(ent, pev_health, 100000.0);
if (attacker < 1 || attacker > 32 || !is_user_alive(attacker) || !g_bZombie[attacker] || g_fBdHp536[i] <= 0.0) return HAM_SUPERCEDE;
if (g_bBoss[attacker] || g_bNemesis[attacker] || g_bAssassin[attacker]) dmg *= get_pcvar_float(g_pBdBoss536);
g_fBdHp536[i] -= dmg;
if (g_fBdHp536[i] <= 0.0) { BDoor536_Break(ent); return HAM_SUPERCEDE; }
static const HIT536[][] = { "debris/wood1.wav", "debris/wood2.wav", "debris/wood3.wav" };
emit_sound(ent, CHAN_BODY, HIT536[random(3)], 0.8, ATTN_NORM, 0, 90 + random(20));
new Float:now = get_gametime();
if (now - g_fBdHud536[attacker] > 0.4)
{
g_fBdHud536[attacker] = now;
client_print(attacker, print_center, "KAPI / DOOR  %d%%", floatround(100.0 * g_fBdHp536[i] / floatmax(1.0, get_pcvar_float(g_pBdHp536))));
}
return HAM_SUPERCEDE;
}
BDoor536_Break(ent)
{
new Float:mn[3], Float:mx[3], Float:c[3];
pev(ent, pev_absmin, mn); pev(ent, pev_absmax, mx);
for (new k = 0; k < 3; k++) c[k] = (mn[k] + mx[k]) * 0.5;
set_pev(ent, pev_solid, SOLID_NOT);
set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW);
set_pev(ent, pev_takedamage, DAMAGE_NO);
emit_sound(ent, CHAN_BODY, random(2) ? "debris/bustcrate1.wav" : "debris/bustcrate2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
if (g_iBdGib536)
{
engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, c, 0);
write_byte(TE_BREAKMODEL);
engfunc(EngFunc_WriteCoord, c[0]); engfunc(EngFunc_WriteCoord, c[1]); engfunc(EngFunc_WriteCoord, c[2]);
engfunc(EngFunc_WriteCoord, mx[0] - mn[0]); engfunc(EngFunc_WriteCoord, mx[1] - mn[1]); engfunc(EngFunc_WriteCoord, mx[2] - mn[2]);
engfunc(EngFunc_WriteCoord, 0.0); engfunc(EngFunc_WriteCoord, 0.0); engfunc(EngFunc_WriteCoord, 40.0);
write_byte(20); write_short(g_iBdGib536); write_byte(14); write_byte(30); write_byte(0x08);
message_end();
}
client_print(0, print_center, "Bir kapi kirildi! / A door was smashed!");
}

bool:GmBossGiant(const name[], out[], len)
{
new Float:k = floatclamp(str_to_float(GetResString("BOSS_SCALE", "1.6")), 1.0, 3.0);
g_fBossScale531 = k;
if (k < 1.05) return false;
new tex = clamp(str_to_num(GetResString("BOSS_GIANT_TEX", "128")), 0, 4096);
return vxe_boss_giant(name, out, len, k, tex) ? true : false;
}
bool:GsSlim(const inPath[], const outPath[], maxTex) return vxe_gs_slim(inPath, outPath, maxTex) ? true : false;
SetDefaultResources() vxe_default_resources();
ModernEvents50() vxe_modern_events();
NativePrecache52() vxe_native_precache();
public VxcResSet(plugin, params) { new k[64], v[192]; get_string(1, k, charsmax(k)); get_string(2, v, charsmax(v)); TrieSetString(g_tRes, k, v); return 1; }
public VxcPcGeneric(plugin, params) { new p[192]; get_string(1, p, charsmax(p)); return ZcPcGeneric(p); }
public VxcResGet(plugin, params) { new k[64], v[256]; get_string(1, k, charsmax(k)); if (g_tRes == Invalid_Trie || !TrieGetString(g_tRes, k, v, charsmax(v))) v[0] = 0; set_string(2, v, get_param(3)); return v[0] != 0; }
public VxcPcModel(plugin, params) { new p[192]; get_string(1, p, charsmax(p)); return PcModel(p, false); }
public VxcPcSound(plugin, params) { new p[192]; get_string(1, p, charsmax(p)); return PcSound(p); }
// 5.3.8: special knives push zombies hard (boss / nemesis / assassin reduced), throttled per victim
SkKnock538(victim, attacker, Float:mult)
{
new Float:now = get_gametime();
if (now < g_fSkKbAt538[victim] || g_bNoKB[victim]) return;
g_fSkKbAt538[victim] = now + 0.2;
new Float:p = get_pcvar_float(g_pSkKb538) * mult;
if (g_bBoss[victim] || g_bNemesis[victim] || g_bAssassin[victim]) p *= floatclamp(get_pcvar_float(g_pSkBoss538), 0.0, 1.0);
if (p <= 1.0) return;
new Float:vo[3], Float:ao[3], Float:v[3];
get_entvar(victim, var_origin, vo); get_entvar(attacker, var_origin, ao);
new Float:dx = vo[0] - ao[0], Float:dy = vo[1] - ao[1], Float:l = floatsqroot(dx * dx + dy * dy);
if (l < 1.0) return;
get_entvar(victim, var_velocity, v);
v[0] = dx / l * p; v[1] = dy / l * p; v[2] = floatmax(v[2], 140.0);
set_entvar(victim, var_velocity, v);
}
MkBreak538(const Float:o[3])
{
new gib=g_iMkGib538;
if(gib<=0) return;
engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,o,0);write_byte(TE_BREAKMODEL);
engfunc(EngFunc_WriteCoord,o[0]);engfunc(EngFunc_WriteCoord,o[1]);engfunc(EngFunc_WriteCoord,o[2]);
write_coord(8);write_coord(8);write_coord(8);write_coord(0);write_coord(0);write_coord(40);write_byte(10);
write_short(gib);write_byte(6);write_byte(15);write_byte(0x08);message_end();
}
// 5.3.8: Arsenal-538 guns (vexmira_extra) bought from the same special weapon menu / AP wallet
BuySg538(id,i)
{
new name[48],cost=vxe_sw_info(i,name,charsmax(name));
if(cost<0) {Chat(id,"SHOP_UNAVAIL");return;}
if(!CommunityAlive(id)) {Chat(id,"ZC_ALIVE_HUMAN");return;}
if(vxe_sw_active(id)==i) {Chat(id,"SHOP_ALREADY");return;}
if(g_iAP[id]<cost) {Chat(id,"SHOP_NOAP");return;}
if(!vxe_sw_give(id,i)) {Chat(id,"SHOP_UNAVAIL");return;}
AddAP(id,-cost,false,false);PlayKey(id,"SHOP_BUY");
new rgb=vxe_sw_rgb(i);VxItemFxRGB531(id,(rgb>>16)&255,(rgb>>8)&255,rgb&255);
}
BuyItem538(id, k)
{
new name[40], cost = vxe_item_info(k, g_bZombie[id] ? 1 : 0, name, charsmax(name));
if (cost < 0 || !is_user_alive(id)) { Chat(id, "SHOP_UNAVAIL"); return; }
if (g_iAP[id] < cost) { Chat(id, "SHOP_NOAP"); return; }
if (!vxe_item_buy(id, k)) { Chat(id, "SHOP_ALREADY"); return; }
AddAP(id, -cost, false, false); PlayKey(id, "SHOP_BUY");
}
public VxcSetModel(plugin, params) { new id = get_param(1), m[32]; get_string(2, m, charsmax(m)); if (1 <= id <= g_iMax && is_user_alive(id)) VxSetUserModel(id, m, true); return 1; }
public VxcRestoreModel(plugin, params)
{
new id = get_param(1);
if (id < 1 || id > g_iMax || !is_user_alive(id)) return 0;
if (!g_bZombie[id]) ApplyHumanModel(id);
else if (!g_bBoss[id] && !g_bNemesis[id] && !g_bAssassin[id]) VxSetUserModel(id, g_szZModel[clamp(g_iClass[id], 0, NUM_CLASSES - 1)], true);
return 1;
}
public VxcCard(plugin, params) { new id = get_param(1); return (1 <= id <= g_iMax && is_user_connected(id)) ? CsoNotify(id, CN_UPGRADE, get_param(2)) : false; }
public VxcClass(plugin, params) { new id = get_param(1); return (1 <= id <= g_iMax) ? (g_bZombie[id] ? clamp(g_iClass[id], 0, NUM_CLASSES - 1) : -1) : -1; }
// 5.3.8 hit / headshot / kill feel: c538 hitmarker crosshair (hm_hit / hm_hs / hm_kill, 0.18 s) + short stock sound.
// Never over a running CSO card or the boss HP card; vex_hitmarker 0 = off.
HitMarkPrecache538()
{
g_bHm538 = false;
if (!equal(g_szCsoDir, "c539") || !str_to_num(GetResString("HITMARKER", "1"))) return;
static const F[][] = { "sprites/vexmira/c539/hm_hit.txt", "sprites/vexmira/c539/hm_hs.txt", "sprites/vexmira/c539/hm_kill.txt", "sprites/vexmira/c539/shm0.spr" };
for (new i = 0; i < sizeof F; i++) { if (!file_exists(F[i], true)) return; }
for (new i = 0; i < sizeof F; i++) PcGeneric(F[i]);
g_bHm538 = true;
}
HitMark538(id, kind)
{
if (!is_user_connected(id) || is_user_bot(id) || (g_iSet[id] & SET_NO_FX) || g_iCsoCur[id] >= 0 || g_iHpLvl533[id] >= 0) return;
static const SND[3][] = { "player/bhit_flesh-1", "buttons/blip1", "buttons/bell1" };
client_cmd(id, "spk ^"%s^"", SND[clamp(kind, 0, 2)]);
new clip, ammo, w = get_user_weapon(id, clip, ammo);
if (w < 1 || w > 30 || !g_bWL[w]) return;
static const NM[3][] = { "vexmira/c539/hm_hit", "vexmira/c539/hm_hs", "vexmira/c539/hm_kill" };
CsoSendWL(id, NM[clamp(kind, 0, 2)], w); CsoCurW(id, w, clip);
g_iHmW538[id] = w; g_fHmEnd538[id] = get_gametime() + (kind == 2 ? 0.35 : 0.18);
remove_task(id + 538700); set_task(kind == 2 ? 0.35 : 0.18, "HitMarkOff538", id + 538700);
}
public HitMarkOff538(t)
{
new id = t - 538700, w = g_iHmW538[id];
g_iHmW538[id] = 0;
if (!is_user_connected(id) || w < 1 || w > 30 || g_iCsoCur[id] >= 0 || g_iHpLvl533[id] >= 0) return;
CsoSendWL(id, g_szWL[w], w);
if (is_user_alive(id)) { new clip, ammo, cw = get_user_weapon(id, clip, ammo); if (cw >= 1 && cw <= 30) CsoCurW(id, cw, clip); }
}
