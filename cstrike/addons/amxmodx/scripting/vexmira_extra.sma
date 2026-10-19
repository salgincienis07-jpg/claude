/* Vexmira Zombie - EXTRA module (5.3.8). Third main plugin: keeps vexmira_core.sma under the panel's 1 MB
   source limit. Holds: resource defaults, giant boss model builder/slimmer, event precache lists, and the
   5.3.8 systems (kill feel, unprecacher, zombie class upgrades, special knife/gun slots).
   Load order (plugins-vexmira.ini): vexmira_core.amxx, vexmira_gear.amxx, vexmira_extra.amxx */
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <xs>
#include <nvault>
#include <reapi>
#pragma dynamic 32768
#pragma tabsize 0
#define VXE_VERSION 538
native vxc_res_set(const key[], const value[]);
native vxc_pc_generic(const path[]);
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

public plugin_natives()
{
register_library("vexmira_extra");
register_native("vxe_boss_giant","N_BossGiant");
register_native("vxe_gs_slim","N_GsSlim");
register_native("vxe_default_resources","N_DefRes");
register_native("vxe_modern_events","N_Modern");
register_native("vxe_native_precache","N_NatPre");
register_native("vxe_version","N_Version");
register_native("vxe_sw_hit","N_SwHit");
register_native("vxe_unprecache_count","N_Unpc");
register_native("vxe_zup_level","N_ZupLevel");
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
}
public N_Version(plugin, params) return VXE_VERSION;
public N_BossGiant(plugin, params)
{
new name[64], out[64];
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
register_plugin("Vexmira Extra", "5.3.8", "Vexmira");
ZupInit();
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
stock GsKnifeOf(q, nq)
{
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
new gname[48], src[160], dst[160], dir[96], t1[160], t2[160];
formatex(gname, charsmax(gname), "%s_x%dt%d", name, floatround(k * 10.0), tex); // 5.3.9b: texture limit in the name -> smaller copy is a NEW file (no stale big download)
formatex(src, charsmax(src), "models/player/%s/%s.mdl", name, name);
formatex(dir, charsmax(dir), "models/player/%s", gname);
formatex(dst, charsmax(dst), "%s/%s.mdl", dir, gname);
new mark[32];
formatex(mark, charsmax(mark), "vexgiant534 t%d", tex);
if (!file_exists(dst, true) || !GsMarked(dst, mark))
{
if (!file_exists(src, true)) return false;
if (!dir_exists(dir)) mkdir(dir);
if (!GmCopy(src, dst) || !GmPatch(dst, k)) { delete_file(dst); log_amx("[GiantBoss] %s olusturulamadi (dosya/klasor izni?) - normal boyut", dst); return false; }
new tmp[168], s0 = file_size(dst, 0), bool:slim;
formatex(tmp, charsmax(tmp), "%s.tmp", dst);
if (GsSlim(dst, tmp, tex) && GmCopy(tmp, dst)) slim = true;
delete_file(tmp);
GsMark(dst, mark);
formatex(t1, charsmax(t1), "models/player/%s/%sT.mdl", name, name);
formatex(t2, charsmax(t2), "%s/%sT.mdl", dir, gname);
if (file_exists(t1, true) && !file_exists(t2, true)) GmCopy(t1, t2);
log_amx("[GiantBoss] dev model uretildi: %s (x%.1f) %d KB%s", dst, k, file_size(dst, 0) / 1024, slim ? "" : " (inceltilemedi, tam kopya)");
if (slim) log_amx("[GiantBoss] inceltildi: %d KB -> %d KB (kullanilmayan silah animasyonlari + doku %d px)", s0 / 1024, file_size(dst, 0) / 1024, tex);
}
if (!CommunityLegacyFileOk(dst)) return false;
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

ModernEvents50()
{
static const paths[][]={"sound/vexmira/arena52/native/default/usp/0.wav",
"sound/vexmira/arena52/native/default/usp/1.wav",
"sound/vexmira/arena52/native/default/usp/2.wav",
"sound/vexmira/arena52/native/default/usp/3.wav",
"sound/vexmira/arena52/native/default/usp/4.wav",
"sound/vexmira/arena52/native/default/usp/5.wav",
"sound/vexmira/arena52/native/default/usp/6.wav",
"sound/vexmira/arena52/native/default/elite/0.wav",
"sound/vexmira/arena52/native/default/elite/1.wav",
"sound/vexmira/arena52/native/default/elite/2.wav",
"sound/vexmira/arena52/native/default/elite/3.wav",
"sound/vexmira/arena52/native/default/elite/4.wav",
"sound/vexmira/arena52/native/default/elite/5.wav",
"sound/vexmira/arena52/native/default/m249/0.wav",
"sound/vexmira/arena52/native/default/m249/1.wav",
"sound/vexmira/arena52/native/default/m249/2.wav",
"sound/vexmira/arena52/native/default/m249/3.wav",
"sound/vexmira/arena52/native/default/m249/4.wav",
"sound/vexmira/arena52/native/default/m249/5.wav",
"sound/vexmira/arena52/native/default/famas/0.wav",
"sound/vexmira/arena52/native/default/famas/1.wav",
"sound/vexmira/arena52/native/default/famas/2.wav",
"sound/vexmira/arena52/native/default/g3sg1/0.wav",
"sound/vexmira/arena52/native/default/g3sg1/1.wav",
"sound/vexmira/arena52/native/default/g3sg1/2.wav",
"sound/vexmira/arena52/native/default/ak47/0.wav",
"sound/vexmira/arena52/native/default/ak47/1.wav",
"sound/vexmira/arena52/native/default/ak47/2.wav",
"sound/vexmira/arena52/native/default/ump45/0.wav",
"sound/vexmira/arena52/native/default/ump45/1.wav",
"sound/vexmira/arena52/native/default/ump45/2.wav",
"sound/vexmira/arena52/native/default/sg552/0.wav",
"sound/vexmira/arena52/native/default/sg552/1.wav",
"sound/vexmira/arena52/native/default/sg552/2.wav",
"sound/vexmira/arena52/native/default/scout/0.wav",
"sound/vexmira/arena52/native/default/scout/1.wav",
"sound/vexmira/arena52/native/default/scout/2.wav",
"sound/vexmira/arena52/native/default/m4a1/0.wav",
"sound/vexmira/arena52/native/default/m4a1/1.wav",
"sound/vexmira/arena52/native/default/m4a1/2.wav",
"sound/vexmira/arena52/native/default/m4a1/3.wav",
"sound/vexmira/arena52/native/default/m4a1/4.wav",
"sound/vexmira/arena52/native/default/m4a1/5.wav",
"sound/vexmira/arena52/native/default/knife/0.wav",
"sound/vexmira/arena52/native/default/mac10/0.wav",
"sound/vexmira/arena52/native/default/mac10/1.wav",
"sound/vexmira/arena52/native/default/mac10/2.wav",
"sound/vexmira/arena52/native/default/mac10/3.wav",
"sound/vexmira/arena52/native/default/fiveseven/0.wav",
"sound/vexmira/arena52/native/default/fiveseven/1.wav",
"sound/vexmira/arena52/native/default/fiveseven/2.wav",
"sound/vexmira/arena52/native/default/fiveseven/3.wav",
"sound/vexmira/arena52/native/default/mp5/0.wav",
"sound/vexmira/arena52/native/default/mp5/1.wav",
"sound/vexmira/arena52/native/default/mp5/2.wav",
"sound/vexmira/arena52/native/default/deagle/0.wav",
"sound/vexmira/arena52/native/default/deagle/1.wav",
"sound/vexmira/arena52/native/default/deagle/2.wav",
"sound/vexmira/arena52/native/default/c4/0.wav",
"sound/vexmira/arena52/native/default/sg550/0.wav",
"sound/vexmira/arena52/native/default/sg550/1.wav",
"sound/vexmira/arena52/native/default/sg550/2.wav",
"sound/vexmira/arena52/native/default/galil/0.wav",
"sound/vexmira/arena52/native/default/galil/1.wav",
"sound/vexmira/arena52/native/default/galil/2.wav",
"sound/vexmira/arena52/native/default/p90/0.wav",
"sound/vexmira/arena52/native/default/p90/1.wav",
"sound/vexmira/arena52/native/default/p90/2.wav",
"sound/vexmira/arena52/native/default/p90/3.wav",
"sound/vexmira/arena52/native/default/xm1014/0.wav",
"sound/vexmira/arena52/native/default/xm1014/1.wav",
"sound/vexmira/arena52/native/default/aug/0.wav",
"sound/vexmira/arena52/native/default/aug/1.wav",
"sound/vexmira/arena52/native/default/aug/2.wav",
"sound/vexmira/arena52/native/default/aug/3.wav",
"sound/vexmira/arena52/native/default/aug/4.wav",
"sound/vexmira/arena52/native/default/m3/0.wav",
"sound/vexmira/arena52/native/default/m3/1.wav",
"sound/vexmira/arena52/native/default/awp/0.wav",
"sound/vexmira/arena52/native/default/awp/1.wav",
"sound/vexmira/arena52/native/default/awp/2.wav",
"sound/vexmira/arena52/native/default/awp/3.wav",
"sound/vexmira/arena52/native/default/awp/4.wav",
"sound/vexmira/arena52/native/default/glock18/0.wav",
"sound/vexmira/arena52/native/default/glock18/1.wav",
"sound/vexmira/arena52/native/default/glock18/2.wav",
"sound/vexmira/arena52/native/default/glock18/3.wav",
"sound/vexmira/arena52/native/default/p228/0.wav",
"sound/vexmira/arena52/native/default/p228/1.wav",
"sound/vexmira/arena52/native/default/p228/2.wav",
"sound/vexmira/arena52/native/default/p228/3.wav",
"sound/vexmira/arena52/native/default/p228/4.wav",
"sound/vexmira/arena52/native/default/tmp/0.wav",
"sound/vexmira/arena52/native/default/tmp/1.wav",
"sound/vexmira/arena52/native/default/tmp/2.wav",
"sound/vexmira/arena51/native/arsenal/1/0.wav",
"sound/vexmira/arena51/native/arsenal/1/1.wav",
"sound/vexmira/arena51/native/arsenal/1/2.wav",
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
"sound/vexmira/arena51/native/arsenal/3/0.wav",
"sound/vexmira/arena51/native/arsenal/3/1.wav",
"sound/vexmira/arena51/native/arsenal/3/2.wav",
"sound/vexmira/arena51/native/arsenal/3/3.wav",
"sound/vexmira/arena51/native/arsenal/2/0.wav",
"sound/vexmira/arena51/native/arsenal/2/1.wav",
"sound/vexmira/arena51/native/arsenal/2/2.wav",
"sound/vexmira/arena51/native/arsenal/7/0.wav",
"sound/vexmira/arena51/native/arsenal/7/1.wav",
"sound/vexmira/arena51/native/arsenal/7/2.wav",
"sound/vexmira/arena51/native/arsenal/7/3.wav",
"sound/vexmira/arena51/native/arsenal/7/4.wav",
"sound/vexmira/arena51/native/arsenal/7/5.wav",
"sound/vexmira/arena51/native/arsenal/7/6.wav",
"sound/vexmira/arena51/native/arsenal/0/0.wav",
"sound/vexmira/arena51/native/arsenal/0/1.wav",
"sound/vexmira/arena51/native/arsenal/6/0.wav",
"sound/vexmira/arena51/native/arsenal/6/1.wav",
"sound/vexmira/arena51/native/arsenal/6/2.wav",
"sound/vexmira/arena51/native/arsenal/6/3.wav",
"sound/vexmira/arena51/native/arsenal/6/4.wav",
"sound/vexmira/arena51/native/arsenal/6/5.wav",
"sound/vexmira/arena51/native/arsenal/6/6.wav",
"sound/vexmira/arena51/native/arsenal/6/7.wav",
"sound/vexmira/arena51/native/arsenal/6/8.wav",
"sound/vexmira/arena51/native/arsenal/4/0.wav",
"sound/vexmira/arena51/native/arsenal/4/1.wav",
"sound/vexmira/arena51/native/arsenal/4/2.wav",
"sound/vexmira/arena51/native/arsenal/4/3.wav"};
for(new i;i<sizeof paths;i++) vxc_pc_generic(paths[i]);
vxc_pc_generic("sound/vexmira/arena52/foley/pin.wav");
}
NativePrecache52() {
new const paths[][]={
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
"sound/vexmira/arena52/foley/draw.wav",
"sound/vexmira/arena52/foley/pin.wav",
"sound/vexmira/arena52/foley/throw.wav"
};
for(new i=0;i<sizeof paths;i++) if(containi(paths[i],"/arsenal/4/")==-1) vxc_pc_generic(paths[i]);
}
// ============================================================================================
// 5.3.8 ARSENAL-538: special guns on stock bases (m249 / xm1014 / mp5navy / usp / elite).
// Same flow as the Arsenal-8 guns: bought from the core special weapon menu with AP, damage goes
// through the core damage pipeline (core asks vxe_sw_hit for the multiplier), precache through the
// core registry (vxc_pc_*), all stats from vexmira.cfg (vex_res SG<n>_*). A slot without its v_ file
// is hidden.
// ============================================================================================
#define SG_MAX 8
#define SG_TAG 5380
native vxc_res_get(const key[], out[], len);
native vxc_pc_model(const path[]);
native vxc_pc_sound(const path[]);
native vx45_corezombie(id);
new g_szSgName[SG_MAX][48], g_szSgBase[SG_MAX][24], g_szSgV[SG_MAX][96], g_szSgP[SG_MAX][96], g_szSgW[SG_MAX][96];
new g_szSgFire[SG_MAX][200], g_szSgFire2[SG_MAX][96], g_iSgAnim[SG_MAX][6], g_iSgClip[SG_MAX], g_iSgAmmo[SG_MAX], g_iSgCost[SG_MAX], g_iSgFx[SG_MAX];
new Float:g_fSgDmg[SG_MAX], Float:g_fSgRate[SG_MAX], Float:g_fSgKb[SG_MAX], g_iSgRgb[SG_MAX][3], bool:g_bSgOk[SG_MAX], WeaponIdType:g_iSgWid[SG_MAX];
new g_iSgShots[33], g_iSgClipPre[33], Float:g_fSgAltAt[33], bool:g_bSgDual[33], g_iSgPoison[33], g_iSgPoisonBy[33], Float:g_fSgPoisonAt[33];
new g_iSgEv[31][2];
new g_sprBeam538, g_sprExplo538, g_sprFire538, g_sprSmoke538, g_iSgN, g_iMaxPl538, bool:g_bSgHooked[31];
new const SG_DEF[SG_MAX][][] = {
{"Portal Gun", "weapon_m249", "1.4", "0.12", "40", "200", "2.5", "1", "30", "60 160 255"},
{"Balrog-VII", "weapon_m249", "1.3", "0.09", "120", "360", "1.5", "2", "32", "255 120 40"},
{"Balrog-XI", "weapon_xm1014", "1.5", "0.25", "12", "96", "6.0", "3", "34", "255 80 30"},
{"MP7 Nemesis", "weapon_mp5navy", "1.35", "0.07", "45", "270", "1.0", "4", "28", "90 230 90"},
{"Charger-7", "weapon_m249", "1.25", "0.08", "100", "300", "1.2", "5", "36", "120 200 255"},
{"Chicken USP", "weapon_usp", "2.0", "0.15", "20", "120", "3.0", "6", "20", "255 220 120"},
{"Skull-2", "weapon_elite", "1.8", "0.11", "36", "180", "2.0", "7", "26", "200 60 60"},
{"", "weapon_usp", "1.6", "0.2", "12", "96", "2.0", "0", "24", "180 120 255"} };
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
new rest[256], one[96]; copy(rest, charsmax(rest), list);
while (rest[0]) { strtok(rest, one, charsmax(one), rest, charsmax(rest), '|'); trim(one); if (one[0]) vxc_pc_sound(one); }
}
SgPick(const list[], out[], len)
{
new n = 1; for (new k = 0; list[k]; k++) if (list[k] == '|') n++;
new want = random(n), rest[200], c; copy(rest, charsmax(rest), list); out[0] = 0;
while (rest[0]) { strtok(rest, out, len, rest, charsmax(rest), '|'); trim(out); if (c++ == want) break; }
}
public plugin_precache()
{
UnpcSetup();
ItemsPrecache538();
new key[24], val[256], a[6][8];
for (new i = 0; i < SG_MAX; i++)
{
g_bSgOk[i] = false;
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
formatex(key, charsmax(key), "SG%d_FX", i + 1); SgRes(key, SG_DEF[i][7], val, charsmax(val)); g_iSgFx[i] = clamp(str_to_num(val), 0, 7);
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
g_sprBeam538 = vxc_pc_model("sprites/laserbeam.spr");
g_sprExplo538 = vxc_pc_model("sprites/zerogxplode.spr");
g_sprFire538 = vxc_pc_model("sprites/fexplo.spr");
g_sprSmoke538 = vxc_pc_model("sprites/steam1.spr");
static const EVF[][] = {"m249", "xm1014", "mp5n", "usp", "elite_left", "elite_right"};
static const WeaponIdType:EVW[] = {WEAPON_M249, WEAPON_XM1014, WEAPON_MP5N, WEAPON_USP, WEAPON_ELITE, WEAPON_ELITE};
new ev[48];
for (new k = 0; k < sizeof EVF; k++) { formatex(ev, charsmax(ev), "events/%s.sc", EVF[k]); g_iSgEv[_:EVW[k]][k == 5 ? 1 : 0] = engfunc(EngFunc_PrecacheEvent, 1, ev); }
}
log_amx("[Arsenal538] %d / %d ozel silah hazir", g_iSgN, SG_MAX);
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
RegisterHam(Ham_Weapon_Reload, g_szSgBase[i], "SgReloadPost", 1);
RegisterHam(Ham_Item_PostFrame, g_szSgBase[i], "SgPostFrame", 0);
}
if (g_iSgN)
{
register_forward(FM_CmdStart, "SgCmdStart");
register_forward(FM_SetModel, "SgSetModel");
register_forward(FM_PlaybackEvent, "SgEvent");
register_concmd("vex_sg_give", "SgCmdGive", ADMIN_RCON, "<name or #userid> <1..8>");
set_task(0.5, "SgPoisonTick", 538538, _, _, "b");
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
g_iSgShots[id] = 0; g_bSgDual[id] = false;
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
public SgAttackPre(weapon)
{
new i = SgIndex(weapon); if (i < 0) return HAM_IGNORED;
new id = get_member(weapon, m_pPlayer); g_iSgClipPre[id] = get_member(weapon, m_Weapon_iClip);
return HAM_IGNORED;
}
public SgAttackPost(weapon)
{
new i = SgIndex(weapon); if (i < 0) return HAM_IGNORED;
new id = get_member(weapon, m_pPlayer);
if (id < 1 || id > g_iMaxPl538 || get_member(weapon, m_Weapon_iClip) >= g_iSgClipPre[id]) return HAM_IGNORED;
new Float:rate = g_fSgRate[i] * ((g_iSgFx[i] == 7 && g_bSgDual[id]) ? 0.5 : 1.0);
set_member(weapon, m_Weapon_flNextPrimaryAttack, rate);
new snd[96]; SgPick(g_szSgFire[i], snd, charsmax(snd));
g_iSgShots[id]++;
if (g_iSgFx[i] == 2 && g_iSgShots[id] % 10 == 0 && g_szSgFire2[i][0]) copy(snd, charsmax(snd), g_szSgFire2[i]);
if (snd[0]) emit_sound(id, CHAN_WEAPON, snd, 0.85, ATTN_NORM, 0, PITCH_NORM);
new seq = g_iSgAnim[i][2 + random(3)];
SgAnim(id, seq);
if (g_iSgFx[i] == 1) set_member(weapon, m_Weapon_iClip, g_iSgClip[i]); // energy gun: never reloads
return HAM_IGNORED;
}
public SgReloadPre(weapon)
{
new i = SgIndex(weapon); if (i < 0) return HAM_IGNORED;
new id = get_member(weapon, m_pPlayer);
new clip = get_member(weapon, m_Weapon_iClip);
if (clip >= g_iSgClip[i] || rg_get_user_bpammo(id, g_iSgWid[i]) <= 0 || g_iSgFx[i] == 1) return HAM_SUPERCEDE;
g_iSgClipPre[id] = clip; set_member(weapon, m_Weapon_iClip, 0);
return HAM_IGNORED;
}
public SgReloadPost(weapon)
{
new i = SgIndex(weapon); if (i < 0) return HAM_IGNORED;
new id = get_member(weapon, m_pPlayer);
set_member(weapon, m_Weapon_iClip, g_iSgClipPre[id]);
if (g_iSgWid[i] != WEAPON_XM1014 && get_member(weapon, m_Weapon_fInReload) && g_iSgAnim[i][5] >= 0) SgAnim(id, g_iSgAnim[i][5]);
return HAM_IGNORED;
}
public SgPostFrame(weapon)
{
new i = SgIndex(weapon); if (i < 0) return HAM_IGNORED;
if (g_iSgWid[i] == WEAPON_XM1014) return HAM_IGNORED; // shotgun reloads shell by shell (stock)
new id = get_member(weapon, m_pPlayer);
if (get_member(weapon, m_Weapon_fInReload) && Float:get_member(id, m_flNextAttack) <= 0.0)
{
new clip = get_member(weapon, m_Weapon_iClip), bp = rg_get_user_bpammo(id, g_iSgWid[i]);
new j = min(g_iSgClip[i] - clip, bp);
if (j > 0) { set_member(weapon, m_Weapon_iClip, clip + j); rg_set_user_bpammo(id, g_iSgWid[i], bp - j); }
set_member(weapon, m_Weapon_fInReload, 0);
}
return HAM_IGNORED;
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
// right click: charger laser / balrog-XI flame ball / skull-2 dual mode / portal blast
public SgCmdStart(id, uc)
{
if (!(get_uc(uc, UC_Buttons) & IN_ATTACK2)) return FMRES_IGNORED;
new i = SgActive(id); if (i < 0) return FMRES_IGNORED;
new fx = g_iSgFx[i]; if (fx != 3 && fx != 5 && fx != 7 && fx != 1 && fx != 6) return FMRES_IGNORED;
set_uc(uc, UC_Buttons, get_uc(uc, UC_Buttons) & ~IN_ATTACK2);
if (fx == 6) return FMRES_IGNORED;
new Float:now = get_gametime(); if (now < g_fSgAltAt[id]) return FMRES_IGNORED;
switch (fx)
{
case 7: { g_bSgDual[id] = !g_bSgDual[id]; g_fSgAltAt[id] = now + 0.6; client_print(id, print_center, g_bSgDual[id] ? "CIFT ATIS" : "TEK ATIS"); }
case 5: { g_fSgAltAt[id] = now + 6.0; SgBeamShot(id, i, 400.0); }
case 3: { g_fSgAltAt[id] = now + 4.0; SgFlameBall(id, i); }
case 1: { g_fSgAltAt[id] = now + 3.0; SgBeamShot(id, i, 150.0); }
}
return FMRES_IGNORED;
}
SgEye(id, Float:o[3], Float:f[3])
{
new Float:ofs[3], Float:a[3]; pev(id, pev_origin, o); pev(id, pev_view_ofs, ofs); xs_vec_add(o, ofs, o);
pev(id, pev_v_angle, a); engfunc(EngFunc_MakeVectors, a); global_get(glb_v_forward, f);
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
if (!spr) return;
engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, o, 0); write_byte(TE_EXPLOSION);
engfunc(EngFunc_WriteCoord, o[0]); engfunc(EngFunc_WriteCoord, o[1]); engfunc(EngFunc_WriteCoord, o[2] + 10.0);
write_short(spr); write_byte(scale); write_byte(20); write_byte(TE_EXPLFLAG_NOSOUND); message_end();
}
// piercing beam: every zombie on the line takes dmg
SgBeamShot(id, i, Float:dmg)
{
new Float:o[3], Float:f[3], Float:e[3]; SgEye(id, o, f);
for (new k = 0; k < 3; k++) e[k] = o[k] + f[k] * 4096.0;
engfunc(EngFunc_TraceLine, o, e, IGNORE_MONSTERS, id, 0); get_tr2(0, TR_vecEndPos, e);
SgBeam(o, e, i, g_iSgFx[i] == 5 ? 60 : 30);
if (g_szSgFire2[i][0]) emit_sound(id, CHAN_ITEM, g_szSgFire2[i], 0.9, ATTN_NORM, 0, PITCH_NORM);
new w = get_member(id, m_pActiveItem);
for (new v = 1; v <= g_iMaxPl538; v++)
{
if (v == id || !is_user_alive(v) || !vx45_corezombie(v)) continue;
new Float:p[3]; pev(v, pev_origin, p);
new Float:d[3], Float:seg[3]; xs_vec_sub(p, o, d); xs_vec_sub(e, o, seg);
new Float:len = xs_vec_len(seg); if (len < 1.0) continue;
new Float:t = xs_vec_dot(d, seg) / (len * len); if (t < 0.0 || t > 1.0) continue;
new Float:c[3]; for (new k = 0; k < 3; k++) c[k] = o[k] + seg[k] * t;
if (get_distance_f(c, p) > 40.0) continue;
ExecuteHamB(Ham_TakeDamage, v, w > 0 ? w : id, id, dmg, DMG_ENERGYBEAM);
if (g_iSgFx[i] == 1) SgPush(v, f, 520.0 * g_fSgKb[i] / 2.5);
}
}
SgFlameBall(id, i)
{
new Float:o[3], Float:f[3], Float:e[3]; SgEye(id, o, f);
for (new k = 0; k < 3; k++) e[k] = o[k] + f[k] * 900.0;
engfunc(EngFunc_TraceLine, o, e, DONT_IGNORE_MONSTERS, id, 0); get_tr2(0, TR_vecEndPos, e);
SgBeam(o, e, i, 20); SgExplo(e, g_sprFire538, 18);
SgArea(id, e, 130.0, 160.0, 6);
}
SgArea(id, const Float:at[3], Float:radius, Float:dmg, burnTicks)
{
new w = get_member(id, m_pActiveItem);
for (new v = 1; v <= g_iMaxPl538; v++)
{
if (v == id || !is_user_alive(v) || !vx45_corezombie(v)) continue;
new Float:p[3]; pev(v, pev_origin, p);
if (get_distance_f(p, at) > radius) continue;
ExecuteHamB(Ham_TakeDamage, v, w > 0 ? w : id, id, dmg, DMG_BURN);
if (burnTicks > 0) { g_iSgPoison[v] = burnTicks; g_iSgPoisonBy[v] = id; g_fSgPoisonAt[v] = 15.0; }
}
}
SgPush(v, const Float:dir[3], Float:speed)
{
new Float:vel[3]; pev(v, pev_velocity, vel);
vel[0] = dir[0] * speed; vel[1] = dir[1] * speed; vel[2] = floatmax(vel[2], 120.0);
set_pev(v, pev_velocity, vel);
}
// damage-over-time (poison / burn): 0.5 s ticks, damage in g_fSgPoisonAt
public SgPoisonTick()
{
for (new v = 1; v <= g_iMaxPl538; v++)
{
if (g_iSgPoison[v] <= 0) continue;
new by = g_iSgPoisonBy[v];
if (!is_user_alive(v) || !vx45_corezombie(v) || !is_user_connected(by)) { g_iSgPoison[v] = 0; continue; }
g_iSgPoison[v]--;
ExecuteHamB(Ham_TakeDamage, v, by, by, g_fSgPoisonAt[v], DMG_POISON);
}
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
if (g_iSgFx[i] == 7 && g_bSgDual[att]) m *= 0.8;
new Float:o[3], Float:f[3], Float:p[3]; SgEye(att, o, f); pev(vic, pev_origin, p);
new boss = get_param(5);
if (g_fSgKb[i] > 0.0 && !boss) SgPush(vic, f, 60.0 * g_fSgKb[i]);
switch (g_iSgFx[i])
{
case 1: { SgBeam(o, p, i, 12); if (!boss) set_member(vic, m_flVelocityModifier, 0.5); }
case 2: if (g_iSgShots[att] % 10 == 0) { SgExplo(p, g_sprExplo538, 8); SgAreaLater(att, p, 90.0, 60.0); }
case 3: if (g_iSgShots[att] % 4 == 0) { g_iSgPoison[vic] = 6; g_iSgPoisonBy[vic] = att; g_fSgPoisonAt[vic] = 12.0; }
case 4: { g_iSgPoison[vic] = 6; g_iSgPoisonBy[vic] = att; g_fSgPoisonAt[vic] = 5.0; if (!boss) SgGlow(vic); }
case 6: if (!boss && random(100) < 15) { set_member(vic, m_flVelocityModifier, 0.0); SgExplo(p, g_sprSmoke538, 6); client_print(att, print_center, "TAVUK!"); }
case 7: if (head && g_sprExplo538) SgExplo(p, g_sprSmoke538, 4);
}
return m;
}
new Float:g_fSgAreaAt[33][3], Float:g_fSgAreaR[33], Float:g_fSgAreaD[33];
SgAreaLater(id, const Float:at[3], Float:r, Float:d)
{
g_fSgAreaAt[id] = at; g_fSgAreaR[id] = r; g_fSgAreaD[id] = d;
RequestFrame("SgAreaFrame", id);
}
public SgAreaFrame(id) { if (is_user_alive(id)) SgArea(id, g_fSgAreaAt[id], g_fSgAreaR[id], g_fSgAreaD[id], 0); }
SgGlow(v)
{
set_rendering(v, kRenderFxGlowShell, 60, 230, 60, kRenderNormal, 12);
remove_task(v + 538600); set_task(3.0, "SgGlowOff", v + 538600);
}
public SgGlowOff(t) { new v = t - 538600; if (is_user_connected(v)) set_rendering(v); }
public client_disconnected(id) { Disc538(id); g_iSgPoison[id] = 0; g_bSgDual[id] = false; remove_task(id + 538600); }
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
new g_iZupVault = INVALID_HANDLE, g_iZupPts[33][24], g_iZupLvl[33][24], g_iZupStep[ZUP_MAX], bool:g_bZupLoaded[33];
new g_sprZupRing;
ZupInit()
{
new v[64]; vxc_res_get("ZUP_STEPS", v, charsmax(v)); if (!v[0]) copy(v, charsmax(v), "40 110 220 380 600");
new a[ZUP_MAX][8]; parse(v, a[0], 7, a[1], 7, a[2], 7, a[3], 7, a[4], 7);
for (new i = 0; i < ZUP_MAX; i++) g_iZupStep[i] = max(1, str_to_num(a[i]));
for (new i = 1; i < ZUP_MAX; i++) if (g_iZupStep[i] <= g_iZupStep[i - 1]) g_iZupStep[i] = g_iZupStep[i - 1] * 2;
g_iZupVault = nvault_open("vexmira_zup");
register_clcmd("say /upgrade", "ZupMenu"); register_clcmd("say /yukselt", "ZupMenu"); register_clcmd("say_team /upgrade", "ZupMenu");
register_clcmd("say_team /yukselt", "ZupMenu"); register_clcmd("vex_zup", "ZupMenu");
}
ZupKey(id, out[], len) { new a[36]; get_user_authid(id, a, charsmax(a)); if (!a[0] || equal(a, "BOT") || contain(a, "LAN") != -1 || contain(a, "PENDING") != -1) get_user_name(id, a, charsmax(a)); formatex(out, len, "zup_%s", a); }
ZupLoad(id)
{
g_bZupLoaded[id] = true;
for (new c = 0; c < 24; c++) { g_iZupPts[id][c] = 0; g_iZupLvl[id][c] = 0; }
if (g_iZupVault == INVALID_HANDLE || is_user_bot(id)) return;
new key[64], data[256]; ZupKey(id, key, charsmax(key));
if (!nvault_get(g_iZupVault, key, data, charsmax(data))) return;
new tok[12], c, pos;
while (c < 24 && (pos = argparse(data, pos, tok, charsmax(tok))) != -1) { g_iZupPts[id][c] = str_to_num(tok); g_iZupLvl[id][c] = ZupLevelOf(g_iZupPts[id][c]); c++; }
}
ZupSave(id)
{
if (g_iZupVault == INVALID_HANDLE || is_user_bot(id) || !g_bZupLoaded[id]) return;
new key[64], data[256], n[12]; ZupKey(id, key, charsmax(key));
for (new c = 0; c < 24; c++) { formatex(n, charsmax(n), c ? " %d" : "%d", g_iZupPts[id][c]); add(data, charsmax(data), n); }
nvault_set(g_iZupVault, key, data);
}
ZupLevelOf(pts) { new l; while (l < ZUP_MAX && pts >= g_iZupStep[l]) l++; return l; }
public client_putinserver(id) ZupLoad(id);
public N_ZupLevel(plugin, params) { new id = get_param(1), c = get_param(2); if (id < 1 || id > 32 || c < 0 || c >= 24) return 0; if (!g_bZupLoaded[id]) ZupLoad(id); return g_iZupLvl[id][c]; }
public N_ZupAdd(plugin, params)
{
new id = get_param(1), pts = get_param(2), c = vxc_class(id);
if (id < 1 || id > 32 || c < 0 || c >= 24 || pts <= 0 || !is_user_connected(id)) return 0;
if (!g_bZupLoaded[id]) ZupLoad(id);
new old = g_iZupLvl[id][c];
g_iZupPts[id][c] = min(g_iZupPts[id][c] + pts, 100000);
g_iZupLvl[id][c] = ZupLevelOf(g_iZupPts[id][c]);
if (g_iZupLvl[id][c] > old) ZupLevelUp(id, c);
ZupSave(id);
return g_iZupLvl[id][c];
}
ZupLevelUp(id, c)
{
new lv = g_iZupLvl[id][c];
client_print_color(id, print_team_default, "^4[VEXMIRA]^1 %s sinifi ^4Seviye %d^1! Bekleme -%d%%, menzil +%d%%, hasar +%d%%", ZUP_NAME[c], lv, 6 * lv, 6 * lv, 8 * lv);
vxc_card(id, lv);
client_cmd(id, "spk ^"items/suitchargeok1^"");
new Float:o[3]; pev(id, pev_origin, o);
ZupRing(o, lv, 260);
message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
write_short(1 << 11); write_short(1 << 10); write_short(0); write_byte(255); write_byte(200); write_byte(60); write_byte(70); message_end();
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
if (!g_bZupLoaded[id]) ZupLoad(id);
new title[160], line[96], cur = vxc_class(id);
formatex(title, charsmax(title), "\wZombi Sinif Yukseltme  \d(enfekte +1, insan oldur +2)");
new m = menu_create(title, "ZupMenuH");
for (new c = 0; c < 24; c++)
{
new lv = g_iZupLvl[id][c], need = lv < ZUP_MAX ? g_iZupStep[lv] : 0;
if (lv < ZUP_MAX) formatex(line, charsmax(line), "\w%s %s\d Sv %d  %d/%d", ZUP_NAME[c], c == cur ? "\w*" : "", lv, g_iZupPts[id][c], need);
else formatex(line, charsmax(line), "\w%s %s\d Sv %d  MAKS", ZUP_NAME[c], c == cur ? "\w*" : "", lv);
menu_additem(m, line);
}
menu_setprop(m, MPROP_NUMBER_COLOR, "\r");
menu_display(id, m, 0);
return PLUGIN_HANDLED;
}
public ZupMenuH(id, m, item) { menu_destroy(m); return PLUGIN_HANDLED; }
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
if (k == 0) { if (z || g_bMask[id]) return 0; g_bMask[id] = true; if (g_bItMdl[0]) vxc_set_model(id, g_szItMask); client_print_color(id, print_team_default, "^4[VEXMIRA]^1 Maske takildi: ^4bir sonraki enfeksiyonu engeller^1."); }
else { if (!z || g_fZArmor[id] > 0.0) return 0; g_fZArmor[id] = float(g_iItArmorHp); if (g_bItMdl[1]) vxc_set_model(id, g_szItArmor); client_print_color(id, print_team_default, "^4[VEXMIRA]^1 Zirh giyildi: ^4%d^1 hasar boyunca %%%d daha az hasar.", g_iItArmorHp, floatround(g_fItArmorCut * 100.0)); }
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
client_print_color(v, print_team_default, "^4[VEXMIRA]^1 Maske enfeksiyonu ^4engelledi^1 ve kirildi!");
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
public ItemsReset538() { for (new i = 1; i <= 32; i++) { g_bMask[i] = false; g_fZArmor[i] = 0.0; } }
public ItemsSpawn538(id) { if (is_user_alive(id)) { g_bMask[id] = false; g_fZArmor[id] = 0.0; } }
Disc538(id) { g_bZupLoaded[id] = false; g_bMask[id] = false; g_fZArmor[id] = 0.0; }
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
