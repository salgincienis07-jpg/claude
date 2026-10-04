# Vexmira Zombie plugin - source modules

The plugin source used to be one 23 600-line file. Since v3.1 it is split into **13 include
modules** under `cstrike/addons/amxmodx/scripting/vex/`. The compiler still produces **one**
plugin, `vexmira_zombie.amxx` - nothing changed for the server, the players or `plugins.ini`.

```
cstrike/addons/amxmodx/scripting/
  vexmira_zombie.sma      header, #include lines, entry points (plugin_natives / plugin_precache /
                          plugin_init / plugin_cfg / plugin_end)          ~ 910 lines
  vex/core.inc            constants, enums, data tables, ALL main globals  ~ 815
  vex/fx.inc              effect + sound helpers, world environment, danger zones
  vex/hud.inc             HUD, chat output, boss bar, overhead bars / icons
  vex/resources.inc       vex_res table, precache + budgets, vexmira.cfg loader, hostname
  vex/stats.inc           nvault save/load, levels, achievements, quests, TOP 15
  vex/economy.inc         AP / VC / XP, market, special weapon shop, perks, VIP, cosmetics
  vex/weapons.inc         loadout, special weapons, grenades + grenade modes, laser mines, airdrop
  vex/zombies.inc         infection / turning, classes, [R] / [F] skills (0-23), bot skills
  vex/bosses.inc          boss life cycle, phases, 27 phase skills, projectiles, boss voices
  vex/modes.inc           round flow, 1 s tick, mode start, events, mode / event vote
  vex/players.inc         connect / disconnect, language, player hooks, player menus, chat, fun, AFK
  vex/admin.inc           admin menu + admin console commands
  vex/maps.inc            map vote, RTV, next map, map change, map ambience
```

## Why one plugin and not 13 `.amxx` files

Splitting the *source* makes the code navigable; splitting the *plugin* would make the server slower:

* **No cross-plugin calls.** Inside one plugin a call is a direct `CALL` opcode (a few ns). Between
  plugins every call is a native call or `callfunc_*` (parameter marshalling, string copies, lookups
  by name) - and the modules call each other thousands of times per second (`Chat`, `HudTo`,
  `FxBegin`, `IsVip`, `AddAP`, the `g_b*` / `g_i*` player state arrays ...).
* **Shared state without copies.** All modules read the same globals (`g_bZombie[]`, `g_iClass[]`,
  `g_iBoss` ...). Separate plugins would need natives / forwards to share them on every access.
* **Every hook registered once.** One `RG_CBasePlayer_TakeDamage`, one `FM_PlayerPreThink`, one
  `FM_AddToFullPack`, one 1 s / 0.1 s task ... With N plugins each would register its own hooks
  and the engine would run N AMX calls per event (PreThink alone is ~3 000 calls/s with 31 players).
* **One JIT image, one data segment, one precache pass.** Precache budgets stay in one place
  (`vex/resources.inc`), the slot accounting (`precache toplam` log line) stays exact.
* The split is a pure source move: the build of the split source has the **same code size, data
  size and per-function instruction stream** as the old single file
  (checked with `devtools/plugin/amxx_compare.py`, see below).

## Include order (matters!)

`vexmira_zombie.sma` includes the modules in this order:

```
core, fx, hud, resources, stats, economy, weapons, zombies, bosses, modes, players, admin, maps
```

Pawn rules that decide what may live where:

* `#define`s and global variables (`new` at file level) must be **declared before first use in
  the text**. A module may use the globals of `core.inc` and of modules included *before* it.
  That is why every global that more than one module touches lives in `core.inc`.
* **Functions** may be called from anywhere, before or after their definition (also functions with
  `Float:` / `bool:` / array results - amxxpc 1.10 handles that without warnings).
* Never use `static` at file level in a module: in Pawn a file-level `static` is private to that
  `.inc` file.
* Module-local constants / tables are fine (e.g. `LM_CLASS`, `LM_PALETTE` in `weapons.inc`,
  `OVH_ICONBIT_*` in `hud.inc`) as long as only that module (or modules included later) use them.

## Module map

### `vexmira_zombie.sma` - entry points
`plugin_natives` (+ `fw_ModuleFilter` / `fw_NativeFilter`: GeoIP optional), `plugin_precache`
(resources: models, claws, sounds, sprites, boss plan, stock-sound block), `plugin_init` (all cvars,
hooks, commands, say commands, repeating tasks), `plugin_cfg` (vexmira.cfg, TOP list, hostname
task), `plugin_end` (save players, TOP list, close vaults). `PLUGIN` / `VERSION` / `AUTHOR` are
defined here (before the module includes) - bump `VERSION` here.

### `core.inc` - shared definitions
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

### `fx.inc` - effects, sounds, environment
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

### `hud.inc` - text on screen
* Personal panel `DrawHud`, aim info `DrawAimInfo`, spectator info `DrawSpecInfo`.
* DHUD slot queue (one message per screen row, no overlap): `HudTo`, `HudToS`, `HudAll`,
  `HudAllS`, `HudText`, `HudDraw`, `task_HudQueue`, `HudReset`, `HudDecorate`.
* Chat: `Chat`, `ChatAll`, `ChatAllS`, `ChatKeyName`, `ChatColorFor`, `Translate`.
* Boss HUD line `BossHud`, `AsciiBar`, `CdText`.
* Overhead indicators (boss bar sprite, small HP bars, VIP / admin / MVP / last-human / alpha
  icons; placed above the real model height read from the `.mdl`): `OvhInit`, `OvhSpawn`,
  `OvhUpdate`, `OvhRefresh`, `fw_OvhThink`, `fw_AddToFullPackPost`, `MdlHeadTops`, `OvhRemoveAll`.

### `resources.inc` - resources, precache, config
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

### `stats.inc` - persistence and progression
`GetKey`, `LoadData`, `SaveData` (nvault), `CalcLevel`, `XPForLevel`, `RankOf`, `LevelUp`,
`CheckAch`, `GrantAch`, `ClaimDaily`, `TitleName`, title / achievement / stats menus, round quests
(`AssignQuests`, `QuestEvent`, `QuestLine`, `cmd_quest`), all-time TOP 15 (`LoadTop`, `SaveTop`,
`UpdateTop`, `ShowTop10`), player card (`ShowCard`), `TopJoinAnnounce`.

### `economy.inc` - money and things you buy
`APMult`, `AddAP`, `SyncMoney`, `Reward`; market (`ShowShopMenu`, `BuyItem`, `ItemPrice`,
`Exchange`, `AnnounceBuy`); special weapon shop (`ShowSpecialMenu`, `SwPrice`); perks
(`ShowPerkMenu`); VIP / ELITE (`LoadVip`, `IsVip`, `IsElite`, `VipWelcome`, `ShowVipMenu`,
`VipFreePack`, `MaxAirJumps`, `TickVip`); cosmetics (`Cos*`, `ShowCosmeticMenu`, `DrawTrail`,
`DrawVipTrail`, `TickCosmetics`, `KillFx`, `InfectFx`).

### `weapons.inc` - weapons and gadgets
Loadout menus (`ShowPrimaryMenu`, `ShowSecondaryMenu`, `GiveLoadout`, `GiveStartNades`,
`GiveNadeStack`); special weapons (`SpecialIndex`, `rg_DefaultDeploy` v_/p_ models,
`fw_PrimaryAttackPost`, `Ignite`, `Freeze`, `ChainLightning`); `rg_HasRestrictItem`; grenades
(`rg_Throw*`, `rg_Explode*`, modes: `fw_NadeAttack2`, `NadeOnThrow`, `NadeSensor`, `NadeLaser`,
`NadeHoming`, `NadeCluster`, `task_NadeTick`, `fw_SetModelPost` w_ models); flares (`AddFlare`,
`TickFlares`); laser mines (`cmd_lm_plant`, `cmd_lm_take`, `FindPlantSpot`, `MineOrient`,
`CreateMine`, `fw_MineThink`, `MineHit`, `fw_EntTakeDamage`, `RemoveAllMines`); airdrop
(`TickAirdrop`, `SpawnAirdrop`, `fw_DropThink`, `fw_DropTouch`, `AirdropLoot`, `DropCompass`).

### `zombies.inc` - zombies and their skills
Turning: `MakeZombie`, `ApplyZombieStats`, `MakeHuman`, `MakeSurvivor`, `Infect`,
`ClearZombieRoles`, `ApplyHumanModel`, `ApplyRender`, gravity helpers; class menu
(`ShowClassMenu`); skill keys (`fw_CmdStart`, `rg_ImpulseCommands`, `cmd_drop`, `cmd_skill*`,
`SkillTrigger`); classes 0-11 `UseAbility`, Nemesis / Assassin `SpecialLeap` / `SpecialFSkill`;
classes 12-23 `UseAbilityV3` + `ButcherHook`, `HunterPounce`, `ChargerCharge`, `ArachneWeb`,
`MagmaTrail`, `VoltEmp`, `MimicDisguise`, `BurrowerDive`, `SirenLure`, `BulwarkFortify`,
`SporePlant`, `NightmareTerror`; projectiles `ZProj*` (hook chain `ChainBeamCreate`,
`HookPullThink`); per-tick `task_ZcTick`, `ZcTickZombie`, `ZcTickHuman`, `ZcCleanup*`;
`BotAbilities`; zombie vision `task_ZombieVision`; `BomberExplode`; `CheckEvolve`.

### `bosses.inc` - bosses
`StartBoss`, `TickBoss`, `BossPassive`, `BossHurt`, `BossPhaseChange`, `BossDeath`,
`BossDamageBoard`, `BossCleanup`; classic skills (`BossTelegraph`, `task_BossCast`, `BossAoE`,
`BossSlam`, ... `BossHarvest`); phase skills (27): `BossUseR`, `BossCastR`, `BossAutoR`,
`Bsk_<Boss><Skill>` (+ `task_*` helpers), channels (`StartChannel`, `task_BossChannel`), hive
eggs (`EggSpawn`), projectiles (`ProjSpawn`, `fw_ProjThink`, `fw_ProjTouch`), pools (`AddPool`,
`TickPools`); helpers `BskDmg`, `BskRad`, `BossPickHuman`, `PushFrom`, `PullTo`, `SlowHuman`,
`RootHuman`; voices: `PlayBossSound`, `EmitBossSound`, `VoiceTick`, `SpecialVoice`,
`BossKillTaunt`; `cmd_bossinfo`.

### `modes.inc` - round flow and game modes
ReAPI round hooks (`rg_CheckWinConditions`, `rg_RestartRound`, `rg_FreezeEnd`, `rg_RoundEnd`,
`OnRoundEnd`, `CheckWin`, `EndRound`), round plan (`RoundsTotal`, `IsBossRound`, `NextBoss`,
`PickMode`, `PickSpecialMode`, `cmd_roundplan`), `task_Announce`, `RoundSummary`,
`task_MapEndAwards`; the 1 s tick `task_Tick` (+ `TickRespawns`, `TickMeteor`); mode start
(`StartMode`, `StartInfection`, `StartNemesis`, `StartSurvivor`, `StartSwarm`, `StartPlague`,
`StartArmageddon`, `AnnounceRole`); events (`EventStartFx`, `TickEvents`, `StormStrike`,
`Lightning`); mode / event vote (`StartVote`, `ShowVoteMenu`, `FinishVote`, `TickAutoVote`);
counters `CountPlaying`, `CountHumans`, `CountZombies`, `GetHumans`.

### `players.inc` - players
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

### `admin.inc` - admins
`cmd_adminmenu`, `ShowAdminMenu` and its sub-menus (environment, mode, boss, event, players,
actions), `cmd_adm_mode`, `cmd_adm_event`, `cmd_adm_boss`, `cmd_adm_ap/vc/xp` (`GiveTarget`),
`cmd_vip_add/remove/list`, `GiveVipDays`, `AdminNotify`.

### `maps.inc` - maps
`MapVoteInit` (registers its own cvars / commands), `StartMapVote`, `ShowMapVoteMenu`,
`FinishMapVote`, `MapOnRoundEnd`, `MapChangeBegin`, `rg_ChangeLevel`, RTV (`cmd_rtv`,
`RtvCheck`), `cmd_nextmap`, `cmd_maps`, `cmd_adm_mapvote`; map ambience restore
(`fw_AmbientPost`, `task_AmbientRestore`).

## Where to add new things

| what | where |
|---|---|
| **cvar** | pointer `new g_pX;` in `core.inc` (next to related pointers), `g_pX = register_cvar("vex_x", "default");` in `plugin_init` (`.sma`) **and** a line `vex_x <value> // Turkce aciklama` in `cstrike/addons/amxmodx/configs/vexmira.cfg` (every setting must be in that single file, Turkish comments). A self-contained new module may register its cvars in its own `<Module>Init()` (pattern: `MapVoteInit`, `OvhInit`), called from `plugin_init`. |
| **table setting** (per class / item / boss ...) | the table in `core.inc` + a case in `ApplyTableCmd` (`resources.inc`) + the `vex_<table>` lines in `vexmira.cfg`. |
| **hook / forward** (`RegisterHookChain`, `RegisterHam`, `register_forward`, `register_message`) | register it **once** in `plugin_init` (or the module's `Init()`), handler in the module that owns the feature. If a hook already exists (e.g. `rg_TakeDamage`, `fw_PreThink`, `task_Tick`, `task_ZcTick`, `fw_AddToFullPackPost`), call your module function from the existing handler instead of registering a second one. |
| **repeating task** | prefer the existing ticks: `task_Tick` (1 s), `task_ZcTick` / `task_NadeTick` (0.1 s), `task_HudQueue` (0.2 s), `task_ZombieVision` (0.25 s). New task ids: add a unique `TASK_*` in `core.inc`. |
| **console / say command** | `register_clcmd` / `register_concmd` in `plugin_init`; chat commands with `RegisterSay("en", "tr", "handler")` (both an English and a Turkish word). |
| **menu** | `ShowXMenu(id)` + `menu_x_handler(id, menu, item)` in the owning module; use `MenuAdd` / `MenuInfo` / `MenuFinish` (`core.inc`); link it from `ShowMainMenu` / `MAIN_ORDER` (`players.inc`) or the admin menu (`admin.inc`). |
| **player-visible text** | never hard-code: add the key in **both** `[en]` and `[tr]` of `cstrike/addons/amxmodx/data/lang/vexmira_zombie.txt` (Turkish without special letters), use it through `Chat`, `ChatAll`, `HudTo`, `HudAll`, `%L`. |
| **resource** (model / sound / sprite) | a `vex_res` key in `SetDefaultResources` (`resources.inc`) + the `vex_res` line in `vexmira.cfg`; precache only through `PcModel` / `PcSound` / `PcGeneric` / `PrecacheSoundKey(Ex)` so the budget counters stay right (sounds <= 490/512, models <= 470/512 with the biggest map). 2D sounds go to `precache_generic` (`IsKey2D`). |
| **global state** | used by one module only and only after its definition -> may stay in that module; used by two or more modules -> `core.inc`. Per-player arrays must be reset in `ResetPlayer` / `ResetPlayerLate` (`players.inc`). |
| **effect** | use the `fx.inc` helpers (they skip bots, respect `SET_NO_FX`, cull by distance); do not broadcast temp entities with `MSG_BROADCAST` in hot paths. |

## Adding a new module

1. Only when a feature is big (roughly > 400 lines) and self-contained; otherwise add to the
   module that owns the topic.
2. File `vex/<name>.inc`, lower-case, with the standard header box (module name, Turkish one-line
   description, "Tek basina derlenmez").
3. Add `#include "vex/<name>.inc"` to `vexmira_zombie.sma` **after** every module whose globals /
   defines it uses (normally at the end of the list).
4. Its globals that other modules need go to `core.inc`; its own cvars / commands either in
   `plugin_init` or in a `<Name>Init()` called from `plugin_init`.
5. Update the module map in this file.
6. Packaging and tooling pick it up automatically: `devtools/release/pack*.sh` ships everything
   tracked under `cstrike/` (so `scripting/vex/*.inc` lands next to the `.sma`),
   `devtools/server/run_test.py` rebuilds when any `vex/*.inc` changes and maps stack traces of
   every module (`hud.inc::Chat (line 12)`) to the source line.

## Editing rules

* **Small, targeted edits.** Change the few lines you need (an editor `Edit` / patch of the exact
  lines). Never regenerate or rewrite a whole module with a script, never re-split / re-merge the
  files, never "reformat" a file: other agents edit the same modules in parallel, and whole-file
  rewrites silently drop their changes.
* Keep functions in their module; when you move code between modules, move whole functions
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
bash devtools/plugin/build_plugin.sh /tmp/out.amxx          # compiles .sma + vex/*.inc (amxxpc -i scripting/)
python3 devtools/plugin/amxx_compare.py old.amxx new.amxx  # pure move/refactor check (exit 0 = same program)
python3 devtools/server/run_test.py --map zm_vex_laboratory --seconds 480 --bots 16 \
    --commands devtools/server/sessions/full_session.txt --rebuild-plugin
```

The `.sma` includes the modules as `#include "vex/<name>.inc"`; amxxpc looks for quoted includes
in the current directory and next to the `.sma`, so a stock `scripting/compile.sh` /
`amxxpc vexmira_zombie.sma` works as long as the `vex/` folder sits next to the `.sma`.

Split verification (v3.1): pre-split build and split build both report header 9 796 B, code
890 008 B, data 485 124 B; `amxx_compare.py` reports the same 840 functions with identical
address-normalised code and the same data cells (only debug info differs: +903 B of file names).
