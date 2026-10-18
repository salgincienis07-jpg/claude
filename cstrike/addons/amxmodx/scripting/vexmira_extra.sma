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
vxc_res_set("BOSS_GIANT_TEX",    "256");
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
g_GsSegA[g_GsNS] = ix; g_GsSegB[g_GsNS] = ix + w * h + 768; g_GsSegN[g_GsNS] = (w / f) * (h / f) + 768; g_GsSegT[g_GsNS++] = t;
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
new f = g_GsTexF[t], w = g_GsTexW[t], h = g_GsTexH[t], nw = w / f, nh = h / f, ix = g_GsSegA[s];
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
GsWrI(out, no + 68, g_GsTexW[t] / g_GsTexF[t]); GsWrI(out, no + 72, g_GsTexH[t] / g_GsTexF[t]);
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
new Float:rs = float(g_GsTexW[tx] / g_GsTexF[tx]) / float(g_GsTexW[tx]);
new Float:rt = float(g_GsTexH[tx] / g_GsTexF[tx]) / float(g_GsTexH[tx]);
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
formatex(gname, charsmax(gname), "%s_x%d", name, floatround(k * 10.0));
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
