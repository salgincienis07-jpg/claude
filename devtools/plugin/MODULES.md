# Vexmira Zombie plugin - source sections

The plugin is **one self-contained source file**,
`cstrike/addons/amxmodx/scripting/vexmira_zombie.sma` (~24 300 lines), compiled to **one** plugin,
`vexmira_zombie.amxx`. It needs only the stock AMXX 1.10 includes + ReAPI 5.26 `reapi.inc`, so it
compiles with any compiler (local `compile.exe` / `compile.sh`, drag-and-drop on `amxxpc`, web
compilers) - **no extra folder, no `#include` of project files**.

History: during 3.1 the source was briefly split into 13 `vex/*.inc` include files. The owner
compiles the plugin standalone, where the compiler could not find `vex/`, so the files were merged
back into the single `.sma` (the merged build was checked with `amxx_compare.py`: same program).
**Keep it one file.** Never move code into `#include "..."` project files again.

The file is divided into 13 sections, each starting with a header box
`/*  BOLUM n/13: NAME  */`. Jump between them by searching for `BOLUM `.

```
vexmira_zombie.sma
  header             PLUGIN / VERSION / AUTHOR, library includes
  BOLUM  1/13 CORE        constants, enums, data tables, ALL main globals
  BOLUM  2/13 FX          effect + sound helpers, world environment, danger zones
  BOLUM  3/13 HUD         HUD, chat output, boss bar, overhead bars / icons
  BOLUM  4/13 KAYNAKLAR   vex_res table, precache + budgets, vexmira.cfg loader, hostname
  BOLUM  5/13 ISTATISTIK  nvault save/load, levels, achievements, quests, TOP 15
  BOLUM  6/13 EKONOMI     AP / VC / XP, market, special weapon shop, perks, VIP, cosmetics
  BOLUM  7/13 SILAHLAR    loadout, special weapons, grenades + grenade modes, laser mines, airdrop
  BOLUM  8/13 ZOMBILER    infection / turning, classes, [R] / [F] skills (0-23), bot skills
  BOLUM  9/13 BOSSLAR     boss life cycle, phases, 27 phase skills, projectiles, boss voices
  BOLUM 10/13 MODLAR      round flow, 1 s tick, mode start, events, mode / event vote
  BOLUM 11/13 OYUNCULAR   connect / disconnect, language, player hooks, player menus, chat, fun, AFK
  BOLUM 12/13 ADMIN       admin menu + admin console commands
  BOLUM 13/13 HARITALAR   map vote, RTV, next map, map change, map ambience
  entry points       plugin_natives / plugin_precache / plugin_init / plugin_cfg / plugin_end
```

## Why one plugin and not 13 `.amxx` files

Splitting the *plugin* would make the server slower:

* **No cross-plugin calls.** Inside one plugin a call is a direct `CALL` opcode (a few ns). Between
  plugins every call is a native call or `callfunc_*` (parameter marshalling, string copies, lookups
  by name) - and the sections call each other thousands of times per second (`Chat`, `HudTo`,
  `FxBegin`, `IsVip`, `AddAP`, the `g_b*` / `g_i*` player state arrays ...).
* **Shared state without copies.** All sections read the same globals (`g_bZombie[]`, `g_iClass[]`,
  `g_iBoss` ...). Separate plugins would need natives / forwards to share them on every access.
* **Every hook registered once.** One `RG_CBasePlayer_TakeDamage`, one `FM_PlayerPreThink`, one
  `FM_AddToFullPack`, one 1 s / 0.1 s task ... With N plugins each would register its own hooks
  and the engine would run N AMX calls per event (PreThink alone is ~3 000 calls/s with 31 players).
* **One JIT image, one data segment, one precache pass.** Precache budgets stay in one place
  (KAYNAKLAR section), the slot accounting (`precache toplam` log line) stays exact.

## Section order (matters!)

Pawn rules that decide what may live where:

* `#define`s and global variables (`new` at file level) must be **declared before first use in
  the text**. A section may use the globals of CORE and of sections placed *before* it.
  That is why every global that more than one section touches lives in CORE.
* **Functions** may be called from anywhere, before or after their definition (also functions with
  `Float:` / `bool:` / array results - amxxpc 1.10 handles that without warnings).
* Section-local constants / tables are fine (e.g. `LM_CLASS`, `LM_PALETTE` in SILAHLAR,
  `OVH_ICONBIT_*` in HUD) as long as only that section (or sections placed later) use them.

## Section map

### Entry points (end of the file)
`plugin_natives` (+ `fw_ModuleFilter` / `fw_NativeFilter`: GeoIP optional), `plugin_precache`
(resources: models, claws, sounds, sprites, boss plan, stock-sound block), `plugin_init` (all cvars,
hooks, commands, say commands, repeating tasks), `plugin_cfg` (vexmira.cfg, TOP list, hostname
task), `plugin_end` (save players, TOP list, close vaults). `PLUGIN` / `VERSION` / `AUTHOR` are
defined at the top of the file - bump `VERSION` there.

### BOLUM 1/13: CORE (`core`) - shared definitions
* Counts: `MAX_LEVEL`, `NUM_CLASSES` (24), `NUM_BOSSES` (9), `NUM_JOBS`, `NUM_ITEMS`, `NUM_SPECIAL` ...
* Task ids `TASK_*` (keep them unique: `TASK_x + id` ranges must not overlap), HUD rows `Y_*`,
  DHUD slots `SL_*`, colours `CLR_*`, settings bits `SET_NO_*`, `MENU_TAG`, `CHAT_PREFIX`.
* Enums: modes `MODE_*`, events `EV_*`, jobs `JOB_*`, items `IT_*`, perks `PK_*`, zombie classes
  `ZC_*`, class cvars `ZCV_*`, boss channels `CH_*`, projectiles `PJ_*`, elements `EL_*`, effect
  sprites `FXS_*`, overhead sprites `OVS_*`.
* Data tables (defaults, overwritten by `vexmira.cfg` table commands): `CLASS_*`, `BOSS_*`,
  `ITEM_*`, `SW_*`, `JOB_LVL`, `PRIM_*` / `SEC_*`, `KB_POWER`, `ENV_*`, `BSK_*` (boss skill
  cool-down / damage / radius), `QUEST_NEED/XP/AP`, `TRAIL_PRICE`, `KFX_PRICE`, `IFX_PRICE`.
* All player state arrays (`g_b*[33]`, `g_i*[33]`, `g_f*[33]`), round state (`g_iRound`,
  `g_iMode`, `g_iEvent`, `g_iBoss` ...), every cvar pointer `g_p*`, resource strings `g_sz*`,
  sprite indexes `g_spr*`, precache counters.
* Small helpers: `ChatTag` (chat prefix per message key), `MenuInfo` / `MenuAdd` / `MenuFinish`.

### BOLUM 2/13: FX (`fx`) - effects, sounds, environment
* World environment: `CurrentEnv`, `PickCalmPreset`, `ApplyWorldEvent`, `ApplyEnvAll`,
  `SendFogForEvent`, `SendFog*`, `SendWeather` (light / fog / weather per event, mode and boss).
* Temp-entity helpers (all per-client, filtered by distance / settings with `FxWants`):
  `FxBegin`, `FxRing*`, `FxBeam*`, `FxSprite`, `FxSpr`, `FxExploEl`, `FxElSmall`, `FxLight`,
  `FxExplosion`, `FxBlood`, `FxTrail`, `FxHeadMark`, `FxFollow`, `FxDisk`, `FxFunnel` ...;
  beam entities `BeamCreate` / `BeamColor` / `BeamPoints` / `BeamEntHand`.
* Screen: `FadeOne`, `FadeAll`, `FadeEx`, `FadeClear`, `ShakeOne`, `ShakeEx`, `ShakeAll`.
* Sounds: `PlayKey` (2D, `spk` / `mp3`), `EmitKey`, `EmitKeyPos`, `EmitSafe` (loop guard),
  `PlayVoxAll`, `StopRoundMusic`, `StopAllClientSounds`, `SndIs2DOnly`, `SpkAround`.
* Danger zones (team-visible ground warnings): `ZoneSpawn`, `fw_ZoneThink`, `RemoveAllZones`, `FloorAt`.
* `AnimByName` (start a model sequence by name).

### BOLUM 3/13: HUD (`hud`) - text on screen
* Personal panel `DrawHud`, aim info `DrawAimInfo`, spectator info `DrawSpecInfo`.
* DHUD slot queue (one message per screen row, no overlap): `HudTo`, `HudToS`, `HudAll`,
  `HudAllS`, `HudText`, `HudDraw`, `task_HudQueue`, `HudReset`, `HudDecorate`.
* Chat: `Chat`, `ChatAll`, `ChatAllS`, `ChatKeyName`, `ChatColorFor`, `Translate`.
* Boss HUD line `BossHud`, `AsciiBar`, `CdText`.
* Overhead indicators (boss bar sprite, small HP bars, VIP / admin / MVP / last-human / alpha
  icons; placed above the real model height read from the `.mdl`): `OvhInit`, `OvhSpawn`,
  `OvhUpdate`, `OvhRefresh`, `fw_OvhThink`, `fw_AddToFullPackPost`, `MdlHeadTops`, `OvhRemoveAll`.

### BOLUM 4/13: KAYNAKLAR (`resources`) - resources, precache, config
* `SetDefaultResources`, `SetModelResources`, `SetClassResources`: default `vex_res` keys.
* `LoadResourceIni`, `ResSet`, `GetResString`, `GetPlayerModel`, `GetFileModel`, `LoadHumanModels`,
  `LoadWorldModels`, `ReadSprInfo`, `PrecacheResSprite`, `PickSky`.
* Precache with budgets: `PcSound`, `PcModel`, `PcGeneric`, `PrecacheSoundKey(Ex)`, `IsKey2D`
  (2D sounds go to `precache_generic`), stock sound block (`SetupStockSoundBlock` ...),
  `PrecacheReportTotals` (`precache toplam` log line), `srv_PrecacheStats` (`vex_precache_stats`).
* Boss loading plan (max 4 bosses per map): `PlanBossLoad`, `BossIsLoaded`.
* WAV checks: `ScanWav`, `SndLooped`, `SndLength`.
* Single config file: `LoadMainConfig`, `ApplyConfigNow`, `ApplyTableCmd` (`vex_item`,
  `vex_class`, `vex_boss_skill` ... table commands), `srv_TableCmd`, `srv_ResCmd`, `cmd_reload_cfg`.
* Server name: `ApplyHostname`, `HostTag`, `task_Hostname`.

### BOLUM 5/13: ISTATISTIK (`stats`) - persistence and progression
`GetKey`, `LoadData`, `SaveData` (nvault), `CalcLevel`, `XPForLevel`, `RankOf`, `LevelUp`,
`CheckAch`, `GrantAch`, `ClaimDaily`, `TitleName`, title / achievement / stats menus, round quests
(`AssignQuests`, `QuestEvent`, `QuestLine`, `cmd_quest`), all-time TOP 15 (`LoadTop`, `SaveTop`,
`UpdateTop`, `ShowTop10`), player card (`ShowCard`), `TopJoinAnnounce`.

### BOLUM 6/13: EKONOMI (`economy`) - money and things you buy
`APMult`, `AddAP`, `SyncMoney`, `Reward`; market (`ShowShopMenu`, `BuyItem`, `ItemPrice`,
`Exchange`, `AnnounceBuy`); special weapon shop (`ShowSpecialMenu`, `SwPrice`); perks
(`ShowPerkMenu`); VIP / ELITE (`LoadVip`, `IsVip`, `IsElite`, `VipWelcome`, `ShowVipMenu`,
`VipFreePack`, `MaxAirJumps`, `TickVip`); cosmetics (`Cos*`, `ShowCosmeticMenu`, `DrawTrail`,
`DrawVipTrail`, `TickCosmetics`, `KillFx`, `InfectFx`).

### BOLUM 7/13: SILAHLAR (`weapons`) - weapons and gadgets
Loadout menus (`ShowPrimaryMenu`, `ShowSecondaryMenu`, `GiveLoadout`, `GiveStartNades`,
`GiveNadeStack`); special weapons (`SpecialIndex`, `rg_DefaultDeploy` v_/p_ models,
`fw_PrimaryAttackPost`, `Ignite`, `Freeze`, `ChainLightning`); `rg_HasRestrictItem`; grenades
(`rg_Throw*`, `rg_Explode*`, modes: `fw_NadeAttack2`, `NadeOnThrow`, `NadeSensor`, `NadeLaser`,
`NadeHoming`, `NadeCluster`, `task_NadeTick`, `fw_SetModelPost` w_ models); flares (`AddFlare`,
`TickFlares`); laser mines (`cmd_lm_plant`, `cmd_lm_take`, `FindPlantSpot`, `MineOrient`,
`CreateMine`, `fw_MineThink`, `MineHit`, `fw_EntTakeDamage`, `RemoveAllMines`); airdrop
(`TickAirdrop`, `SpawnAirdrop`, `fw_DropThink`, `fw_DropTouch`, `AirdropLoot`, `DropCompass`).

### BOLUM 8/13: ZOMBILER (`zombies`) - zombies and their skills
Turning: `MakeZombie`, `ApplyZombieStats`, `MakeHuman`, `MakeSurvivor`, `Infect`,
`ClearZombieRoles`, `ApplyHumanModel`, `ApplyRender`, gravity helpers; class menu
(`ShowClassMenu`); skill keys (`fw_CmdStart`, `rg_ImpulseCommands`, `cmd_drop`, `cmd_skill*`,
`SkillTrigger`); classes 0-11 `UseAbility`, Nemesis / Assassin `SpecialLeap` / `SpecialFSkill`;
classes 12-23 `UseAbilityV3` + `ButcherHook`, `HunterPounce`, `ChargerCharge`, `ArachneWeb`,
`MagmaTrail`, `VoltEmp`, `MimicDisguise`, `BurrowerDive`, `SirenLure`, `BulwarkFortify`,
`SporePlant`, `NightmareTerror`; projectiles `ZProj*` (hook chain `ChainBeamCreate`,
`HookPullThink`); per-tick `task_ZcTick`, `ZcTickZombie`, `ZcTickHuman`, `ZcCleanup*`;
`BotAbilities`; zombie vision `task_ZombieVision`; `BomberExplode`; `CheckEvolve`.

### BOLUM 9/13: BOSSLAR (`bosses`) - bosses
`StartBoss`, `TickBoss`, `BossPassive`, `BossHurt`, `BossPhaseChange`, `BossDeath`,
`BossDamageBoard`, `BossCleanup`; classic skills (`BossTelegraph`, `task_BossCast`, `BossAoE`,
`BossSlam`, ... `BossHarvest`); phase skills (27): `BossUseR`, `BossCastR`, `BossAutoR`,
`Bsk_<Boss><Skill>` (+ `task_*` helpers), channels (`StartChannel`, `task_BossChannel`), hive
eggs (`EggSpawn`), projectiles (`ProjSpawn`, `fw_ProjThink`, `fw_ProjTouch`), pools (`AddPool`,
`TickPools`); helpers `BskDmg`, `BskRad`, `BossPickHuman`, `PushFrom`, `PullTo`, `SlowHuman`,
`RootHuman`; voices: `PlayBossSound`, `EmitBossSound`, `VoiceTick`, `SpecialVoice`,
`BossKillTaunt`; `cmd_bossinfo`.

### BOLUM 10/13: MODLAR (`modes`) - round flow and game modes
ReAPI round hooks (`rg_CheckWinConditions`, `rg_RestartRound`, `rg_FreezeEnd`, `rg_RoundEnd`,
`OnRoundEnd`, `CheckWin`, `EndRound`), round plan (`RoundsTotal`, `IsBossRound`, `NextBoss`,
`PickMode`, `PickSpecialMode`, `cmd_roundplan`), `task_Announce`, `RoundSummary`,
`task_MapEndAwards`; the 1 s tick `task_Tick` (+ `TickRespawns`, `TickMeteor`); mode start
(`StartMode`, `StartInfection`, `StartNemesis`, `StartSurvivor`, `StartSwarm`, `StartPlague`,
`StartArmageddon`, `AnnounceRole`); events (`EventStartFx`, `TickEvents`, `StormStrike`,
`Lightning`); mode / event vote (`StartVote`, `ShowVoteMenu`, `FinishVote`, `TickAutoVote`);
counters `CountPlaying`, `CountHumans`, `CountZombies`, `GetHumans`.

### BOLUM 11/13: OYUNCULAR (`players`) - players
Connection (`client_connect`, `client_putinserver`, `DoLoad`, `client_disconnected`,
`ResetPlayer`, `ResetRoundData`, `ResetLifeData`, `ResetPlayerLate`), welcome / MOTD, language
(`ApplyLanguage`, `SetLanguage`); say / console command routing (`client_command`,
`RegisterSay`, `RunChatCommand`, `SayHandler`, tags `GetStaffTag`, `RoleTag`); player commands
(`cmd_menu` ... `cmd_unstuck`); menus (`ShowMainMenu`, profile, job, style, settings, language,
FPS / net config); player hooks (`rg_PlayerSpawn`, `rg_TakeDamage(Post)`, `ApplyKnockback`,
`rg_PlayerKilled(Pre)`, `KillStreak`, `rg_ResetMaxSpeed`, `rg_FallDamage`, `rg_PlayerJump`,
`fw_PreThink`, `fw_EmitSound`, `fw_ClientKill`); per-second player tick `TickPlayers`
(`HealTo`, `DoctorAura`, `RefillAmmo`); scoreboard `SendDeathMsg`, `UpdateScore`; fun commands
(dice, slot, lotto, gift, bounty ...); live server chatter (`Live*`); AFK manager `TickAfk`.

### BOLUM 12/13: ADMIN (`admin`) - admins
`cmd_adminmenu`, `ShowAdminMenu` and its sub-menus (environment, mode, boss, event, players,
actions), `cmd_adm_mode`, `cmd_adm_event`, `cmd_adm_boss`, `cmd_adm_ap/vc/xp` (`GiveTarget`),
`cmd_vip_add/remove/list`, `GiveVipDays`, `AdminNotify`.

### BOLUM 13/13: HARITALAR (`maps`) - maps
`MapVoteInit` (registers its own cvars / commands), `StartMapVote`, `ShowMapVoteMenu`,
`FinishMapVote`, `MapOnRoundEnd`, `MapChangeBegin`, `rg_ChangeLevel`, RTV (`cmd_rtv`,
`RtvCheck`), `cmd_nextmap`, `cmd_maps`, `cmd_adm_mapvote`; map ambience restore
(`fw_AmbientPost`, `task_AmbientRestore`).

## Where to add new things

| what | where |
|---|---|
| **cvar** | pointer `new g_pX;` in CORE section (next to related pointers), `g_pX = register_cvar("vex_x", "default");` in `plugin_init` (`.sma`) **and** a line `vex_x <value> // Turkce aciklama` in `cstrike/addons/amxmodx/configs/vexmira.cfg` (every setting must be in that single file, Turkish comments). A self-contained new section may register its cvars in its own `<Module>Init()` (pattern: `MapVoteInit`, `OvhInit`), called from `plugin_init`. |
| **table setting** (per class / item / boss ...) | the table in CORE section + a case in `ApplyTableCmd` (KAYNAKLAR section) + the `vex_<table>` lines in `vexmira.cfg`. |
| **hook / forward** (`RegisterHookChain`, `RegisterHam`, `register_forward`, `register_message`) | register it **once** in `plugin_init` (or the section's `Init()`), handler in the section that owns the feature. If a hook already exists (e.g. `rg_TakeDamage`, `fw_PreThink`, `task_Tick`, `task_ZcTick`, `fw_AddToFullPackPost`), call your section function from the existing handler instead of registering a second one. |
| **repeating task** | prefer the existing ticks: `task_Tick` (1 s), `task_ZcTick` / `task_NadeTick` (0.1 s), `task_HudQueue` (0.2 s), `task_ZombieVision` (0.25 s). New task ids: add a unique `TASK_*` in CORE section. |
| **console / say command** | `register_clcmd` / `register_concmd` in `plugin_init`; chat commands with `RegisterSay("en", "tr", "handler")` (both an English and a Turkish word). |
| **menu** | `ShowXMenu(id)` + `menu_x_handler(id, menu, item)` in the owning section; use `MenuAdd` / `MenuInfo` / `MenuFinish` (CORE section); link it from `ShowMainMenu` / `MAIN_ORDER` (OYUNCULAR section) or the admin menu (ADMIN section). |
| **player-visible text** | never hard-code: add the key in **both** `[en]` and `[tr]` of `cstrike/addons/amxmodx/data/lang/vexmira_zombie.txt` (Turkish without special letters), use it through `Chat`, `ChatAll`, `HudTo`, `HudAll`, `%L`. |
| **resource** (model / sound / sprite) | a `vex_res` key in `SetDefaultResources` (KAYNAKLAR section) + the `vex_res` line in `vexmira.cfg`; precache only through `PcModel` / `PcSound` / `PcGeneric` / `PrecacheSoundKey(Ex)` so the budget counters stay right (sounds <= 490/512, models <= 470/512 with the biggest map). 2D sounds go to `precache_generic` (`IsKey2D`). |
| **global state** | used by one section only and only after its definition -> may stay in that section; used by two or more sections -> CORE section. Per-player arrays must be reset in `ResetPlayer` / `ResetPlayerLate` (OYUNCULAR section). |
| **effect** | use the FX section helpers (they skip bots, respect `SET_NO_FX`, cull by distance); do not broadcast temp entities with `MSG_BROADCAST` in hot paths. |

## Adding a new section

1. Only when a feature is big (roughly > 400 lines) and self-contained; otherwise add to the
   section that owns the topic.
2. Put it **inside `vexmira_zombie.sma`** (never a separate include file), with the standard header
   box `/*  BOLUM n/N: NAME  */` + a Turkish one-line description, **after** every section whose
   globals / defines it uses (normally right before the entry points), and renumber the headers.
3. Its globals that other sections need go to CORE; its own cvars / commands either in
   `plugin_init` or in a `<Name>Init()` called from `plugin_init`.
4. Update the section map in this file.

## Editing rules

* **Small, targeted edits.** Change the few lines you need (an editor `Edit` / patch of the exact
  lines). Never regenerate or rewrite the file / a whole section with a script, never split it into
  include files, never "reformat" it: other agents may edit the same file, and whole-file
  rewrites silently drop their changes.
* Keep functions in their section; when you move code between sections, move whole functions
  verbatim and prove it with `amxx_compare.py` (below) before you change anything else.
* Comments in Turkish without special letters (like the existing code); player text only via the
  lang file (EN + TR).
* After every change: `bash devtools/plugin/build_plugin.sh <out.amxx>` must print **0 errors,
  0 warnings**, then run the test server (`devtools/server/README.md`), at least the full session
  for gameplay changes, and check `precache toplam` for resource changes.
* Hot paths (`fw_PreThink`, `fw_AddToFullPackPost`, `fw_CmdStart`, `rg_TakeDamage`,
  `task_ZcTick`, `task_NadeTick`, `fw_*Think`) run hundreds to thousands of times per second:
  no `formatex` / `%L` / trie lookups / traces per call unless gated by a timer; see
  `devtools/plugin/PERF_BASELINE.md` for the measured cost of each.

## Build and verify

```bash
bash devtools/plugin/build_plugin.sh /tmp/out.amxx          # amxxpc vexmira_zombie.sma (+ AMXX/ReAPI includes)
python3 devtools/plugin/amxx_compare.py old.amxx new.amxx  # pure move/refactor check (exit 0 = same program)
python3 devtools/server/run_test.py --map zm_vex_laboratory --seconds 480 --bots 16 \
    --commands devtools/server/sessions/full_session.txt --rebuild-plugin
```

Merge verification (v3.1): the single-file build compiled standalone (only the AMXX + ReAPI
include folder, no project include path, 0 errors / 0 warnings) and `amxx_compare.py` against
the earlier split build reports `EQUIVALENT (same program, code only moved)`.
