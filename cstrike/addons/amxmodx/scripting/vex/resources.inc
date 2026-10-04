/* ================================================================== */
/*  Vexmira Zombie - modul: vex/resources.inc  (KAYNAKLAR)            */
/*  vex_res kaynak tablosu, precache + butceler (ses / model /        */
/*  generic), boss yukleme plani, oyuncu / dunya modelleri, tek       */
/*  ayar dosyasi (vexmira.cfg) yukleyici, sunucu adi.                 */
/*  Tek basina derlenmez: vexmira_zombie.sma include eder.            */
/*  Modul haritasi + kurallar: devtools/plugin/MODULES.md             */
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
    DefSound("ZAP",            "vexmira/zap.wav",             "weapons/electro4.wav");
    DefSound("MVP",            "vexmira/mvp.wav",             "events/task_complete.wav");
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
        formatex(val, charsmax(val), "vex_b_%s", BOSS_FILE[b]);
        TrieSetString(g_tRes, key, val);
        formatex(key, charsmax(key), "B%d_CLAW", b);
        formatex(val, charsmax(val), "models/vexmira/claws/v_%s.mdl", BOSS_FILE[b]);
        TrieSetString(g_tRes, key, val);
    }
    TrieSetString(g_tRes, "NEMESIS_MODEL",  "vex_nemesis");
    TrieSetString(g_tRes, "ASSASSIN_MODEL", "vex_assassin");
    TrieSetString(g_tRes, "NEMESIS_CLAW",   "models/vexmira/claws/v_nemesis.mdl");
    TrieSetString(g_tRes, "ASSASSIN_CLAW",  "models/vexmira/claws/v_assassin.mdl");
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
        formatex(val, charsmax(val), "models/vexmira/weapons/v_sw%d.mdl", i);
        TrieSetString(g_tRes, key, val);
        formatex(key, charsmax(key), "SW%d_PMODEL", i);
        formatex(val, charsmax(val), "models/vexmira/weapons/p_sw%d.mdl", i);
        TrieSetString(g_tRes, key, val);
    }

    // Dunya modelleri
    TrieSetString(g_tRes, "LASERMINE_MODEL", "models/vexmira/world/lasermine.mdl");
    // LASERMINE_BODY / LASERMINE_SEQUENCE / LASERMINE_SKIN: yazilmazsa modele gore secilir
    // (Vexmira lazeri: govde 0, animasyon "idle"; kurulurken "deploy")
    TrieSetString(g_tRes, "AIRDROP_MODEL",   "models/vexmira/world/supply_crate.mdl");
    TrieSetString(g_tRes, "EGG_MODEL",       "models/vexmira/world/hive_egg.mdl");
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
        formatex(val, charsmax(val), "vex_z_%s", CLASS_FILE[i]);
        TrieSetString(g_tRes, key, val);

        formatex(key, charsmax(key), "Z%d_CLAW", i);
        formatex(val, charsmax(val), "models/vexmira/claws/v_%s.mdl", CLASS_FILE[i]);
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
    TrieSetString(g_tRes, "HOOK_MODEL",  "models/vexmira/world/hook.mdl");
    TrieSetString(g_tRes, "SPORE_MODEL", "models/vexmira/world/spore_pod.mdl");
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
    "NEM_RAGE"
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
        MdlHeadTops(out);
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

#define CFG_MAXARGS 12

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
    if (equali(args[0], "vex_sw"))
    {
        // vex_sw <no> <fiyat AP> <level> <hasar carpani> <yedek mermi>
        if ((i = TblIdx(args, argc, 6, NUM_SPECIAL)) >= 0)
        {
            SW_COST[i]   = max(0, str_to_num(args[2]));
            SW_LVL[i]    = clamp(str_to_num(args[3]), 1, MAX_LEVEL);
            SW_MULT[i]   = floatmax(0.1, str_to_float(args[4]));
            SW_BPAMMO[i] = clamp(str_to_num(args[5]), 1, 999);
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
