# devtools/server — headless CS 1.6 test server for Vexmira Zombie

A real **ReHLDS 3.15 + ReGameDLL 5.30 + Metamod-R 1.3 + AMX Mod X 1.10 (built from source) +
ReAPI 5.26** dedicated server that runs the actual `vexmira_zombie.sma` with CS bots, so runtime
errors, precache-limit problems and broken models/maps show up before release.
Steam's CDN is unreachable from the build machine, so there is **no Valve game content**: every
file the engine/game insists on is a generated placeholder, and Steam itself is replaced by an
offline stub. The server lives outside the repo: `$SP/server`
(`$SP = /tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad`).

| file | what |
|---|---|
| `run_test.py` | the harness: sync package links, (re)build plugin, boot, timed console commands, log capture, summary; `--nav-all` (bot nav meshes for the package), `--maps-smoke` (per-map runtime check) |
| `vexprobe.sma` | telemetry plugin loaded first: exact precache slot usage (ReHLDS hooks), team/infection/model/HP samples, round winners, every `vexmira/*` sound actually played, map checks (spawn points, spawn usage, stuck / in-solid bots, fall + world deaths) |
| `navfile.py` | reader/validator for `maps/<map>.nav` (ZBot v5): format, bsp-size stamp, area count, nav islands, spawn points on the mesh |
| `make_placeholders.py` | Valve-content placeholders (WADs, 159 studiomdl models, 80 sprites, event scripts, cfgs, botprofile.db) + package stand-ins (`--stub`, `--clean-stubs`) |
| `make_testmap.py` | `zm_vex_testroom` boot map (mapkit + SDHLT, 32 CT + 32 T spawns, platform + stairs + ladder) |
| `steamstub/` | `steam_stub.cpp` + `build.sh`: offline `libsteam_api.so` built against ReHLDS' Steam SDK headers |
| `sessions/full_session.txt` | the ~7 min reference session (modes, events, every loaded boss) |

## Setup from scratch (≈10 min, all from open-source releases)

```bash
SP=/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad
S=$SP/server; X=$SP/srvx; mkdir -p $S $X; cd $X
# 1. binaries (release zips in $SP/tools/srvdl)
for z in $SP/tools/srvdl/*.zip; do d=$(basename $z .zip); mkdir -p $d; unzip -oq $z -d $d; done
cp -a rehlds-bin-3.15.0.896/bin/linux32/* $S/
mkdir -p $S/cstrike/addons/metamod
cp -a regamedll-bin-5.30.0.814/bin/linux32/cstrike/* $S/cstrike/          # cs.so, delta.lst, game.cfg, game_init.cfg
cp metamod-bin-1.3.0.149/addons/metamod/metamod_i386.so $S/cstrike/addons/metamod/
# 2. AMX Mod X 1.10 from source (32-bit; needs: sudo apt-get install nasm; pip install ./ambuild)
cp -a $SP/tools/amxmodx amxmodx-src
git clone https://github.com/alliedmodders/amtl amxmodx-src/public/amtl && git -C amxmodx-src/public/amtl checkout bee3fc5
git clone https://github.com/alliedmodders/metamod-hl1; git clone https://github.com/alliedmodders/hlsdk
git clone https://github.com/alliedmodders/ambuild && pip install ./ambuild
sed -i "229a\        cxx.cflags += ['-Wno-error=return-local-addr']" amxmodx-src/AMBuildScript   # gcc 13 vs bundled sqlite
mkdir amxmodx-src/build && cd amxmodx-src/build
python3 ../configure.py --enable-optimize --no-mysql --metamod=../../metamod-hl1 --hlsdk=../../hlsdk --disable-auto-versioning
ambuild
cp -a packages/base/addons/amxmodx $S/cstrike/addons/ && cp -a packages/cstrike/addons/amxmodx/. $S/cstrike/addons/amxmodx/
# 3. ReAPI module
unzip -oq $SP/tools/reapi.zip -d $X/reapi && cp $X/reapi/addons/amxmodx/modules/reapi_amxx_i386.so $S/cstrike/addons/amxmodx/modules/
# 4. offline Steam + placeholders + boot map + navigation mesh
bash /home/user/claude/devtools/server/steamstub/build.sh          # -> $S/libsteam_api.so
cd /home/user/claude/devtools
python3 server/make_placeholders.py                                # WADs, models, sprites, cfgs, botprofile.db ...
python3 server/make_testmap.py                                     # -> $S/cstrike/maps/zm_vex_testroom.bsp
cd /home/user/claude && python3 devtools/server/run_test.py --seconds 5   # first run: bot learns testroom -> .nav
```

Things that had to be solved (keep in mind when rebuilding):
* `valve/gfx.wad` must exist (empty WAD3 is enough), `decals.wad` needs every ReGameDLL decal name.
* `valve/valve.rc` with `stuffcmds` — without it the `+map` command line is silently ignored.
* `events/*.sc` must exist (`Host_Error: EV_Precache ... missing from server`).
* Real `libsteam_api.so` dies with `FATAL ERROR: Unable to initialize Steam` (no steamclient.so);
  the stub answers SteamGameServer_Init, hands out anonymous SteamIDs to bots, never sends packets.
* ReGameDLL disables ZBots on dedicated servers unless `bot_enable "1"` in `game_init.cfg`
  (make_placeholders patches it). Without a `.nav` the first bot learns the map (~2 s here).

## Running

```bash
cd /home/user/claude
python3 devtools/server/run_test.py                      # quick check: zm_vex_testroom, 12 bots, 150 s
python3 devtools/server/run_test.py --map zm_vex_pilot   # any map in cstrike/maps (repo maps are linked)
python3 devtools/server/run_test.py --bots 12 --seconds 480 \
    --commands devtools/server/sessions/full_session.txt --rebuild-plugin       # reference session (~8 min)
python3 devtools/server/run_test.py --nav-all            # bot .nav for every zm_vex_* map -> repo cstrike/maps/
python3 devtools/server/run_test.py --maps-smoke         # every zm_vex_* map 60 s / 12 bots, per-map table
```

The plugin is recompiled automatically whenever the repo `.sma` differs from the last installed
build (`--rebuild-plugin` forces it, `--no-rebuild` never builds). The build goes to a temp file and
is installed only when it is clean; a failed build (another agent mid-edit) is retried
`--build-retries` times (default 3) 60 s apart, a build whose source changed while compiling is
redone after 10 s. If the map has no `.nav`, a learning pass runs first (plugin off, 1 bot, ~5-20 s).

| option | meaning |
|---|---|
| `--map M` | map in `$S/cstrike/maps` (repo maps are linked there automatically), default `zm_vex_testroom` |
| `--seconds N` | run time after the map is up (default 150) |
| `--bots N` | `bot_quota N` right after map start (default 12, 0 = none) |
| `--commands F`, `--cmd "T cmd"` | timed console commands (`T` = seconds after map start; `#` comments) |
| `--rebuild-plugin` / `--no-rebuild` / `--build-retries N` | force / skip the compile of the repo `.sma` (`devtools/plugin/build_plugin.sh`, + source snapshot for stack lines); default = compile when changed |
| `--stub-missing` | boot once, then create server-only stand-ins for every model the design promises and every file the plugin logs as missing (`bulunamadi`), so precache counts match a complete package. Real repo files always win (sync replaces stubs by links). `--clean-stubs` removes them. |
| `--no-ensure-nav` | do not run the nav learning pass when `maps/<map>.nav` is missing (default: run it) |
| `--until-nav` / `--export-nav` | stop as soon as a `.nav` is saved / copy the server's `.nav` into the repo maps dir |
| `--nav-all` | for every repo `cstrike/maps/zm_vex_*.bsp` except the pilot: boot with plugin off + 1 bot until the bot system saves `maps/<map>.nav`, validate it (`navfile.py`), copy it to repo `cstrike/maps/` (0644). Maps whose repo `.nav` is already valid for the current `.bsp` (size stamp) are skipped unless `--force-nav`. `--maps a,b` limits the list (naming `zm_vex_pilot` includes it), `--nav-out DIR` exports elsewhere, `--nav-timeout` (900 s) per map |
| `--maps-smoke` | boot every repo `zm_vex_*.bsp` (pilot included) for `--smoke-seconds` (60) with `--bots` (12); missing / stale nav is generated first (server only; add `--export-nav` to also ship it). Prints a per-map table + details, saved as `$S/runs/maps_smoke_<stamp>.txt/.json`. Exit 1 if a map did not load cleanly or had AMXX errors |
| `--no-vexmira` | baseline without the plugin; `--no-debug` loads it without the AMXX `debug` flag; `--no-probe` without vexprobe |
| `--echo` | stream interesting console lines live |

Console commands of the plugin (server console has all admin rights):
`vex_mode <0-9>` (0 infection 1 multi 2 nemesis 3 assassin 4 survivor 5 sniper 6 swarm 7 plague
8 armageddon 9 boss), `vex_event <0-18>`, `vex_boss <-1..8>` (only the bosses in the map's boss
plan are loaded), all apply to the next round — follow with `sv_restart 1`. `vexprobe_status`
prints a probe sample on demand.

Every run is archived in `$S/runs/<stamp>_<map>/`: `console.log` (timestamped, `>>>` = sent
commands), `amxx_L.log`, `amxx_error.log`, `game.log`, `vexprobe_precache_<map>.txt` (every
precached name with its slot index), `vexmira_zombie.sma` (the compiled source), `summary.txt`,
`summary.json`. Exit code 0 = clean, 1 = runtime errors / plugin not running, 2 = crash.

### Maps smoke report
| column | meaning |
|---|---|
| loaded | map came up, no crash / Host_Error, plugin `running`/`debug` |
| spawns ct/t | `info_player_start` / `info_player_deathmatch` entities (design: >= 32 each) |
| used ct/t | distinct spawn points of that kind players actually spawned on (the plugin re-spawns infected players as T, so the T set is used most) |
| blk/fl | spawn points whose player hull starts in solid / that are more than 18 u above the floor (hull traces in the engine, incl. brush entities) |
| stack | spawns on top of another living player (too few free spawn points) |
| stuck | bot pressed move keys but stayed within 48 u for 10 s with no enemy within 160 u (heuristic: also catches crowds pushing into each other; positions are listed) |
| solid | living bot whose origin is inside world solid |
| fall / world | fall-damage deaths / deaths by worldspawn, `trigger_hurt` or another non-player entity (positions listed) |
| precache | engine slot usage (probe) model/sound/generic of 512 |
| err / fatal | distinct AMXX run-time errors / fatal console lines |
| nav | areas of the validated `.nav` (or why it is missing/invalid) |

`python3 devtools/server/navfile.py <map>.nav [--bsp <map>.bsp]` validates a nav by itself:
exact parse of the file, bsp size stamp (stale nav after a map recompile), >= 10 areas, nav
islands (areas not connected to the main mesh), every spawn point standing on a nav area.

### Summary contents
plugin + module status, Metamod plugin list, precache usage (probe: highest slot index = real
engine usage incl. map brush models; plugin's own count), rounds / round winners / infections /
kills, special & boss models seen, max HP per model, every `vexmira/*` sound the engine played
(proof that abilities/boss skills fired), MAP CHECKS (spawn points / usage, stuck, in-solid, fall
and world deaths with positions), AMXX run-time errors grouped with their debug stack and
the matching source line, console fatal / precache-overflow / missing-file / AMXX / warning lines.

## Layout of `$S` (server root)

```
hlds_linux engine_i486.so libsteam_api.so(stub) ...      ReHLDS
valve/gfx.wad fonts.wad valve.rc                         placeholders
cstrike/dlls/cs.so delta.lst game.cfg game_init.cfg      ReGameDLL (bot_enable 1)
cstrike/liblist.gam -> addons/metamod/metamod_i386.so   Metamod-R, plugins.ini -> amxmodx_mm_i386.so
cstrike/addons/amxmodx/...                               AMXX 1.10 build + reapi_amxx_i386.so
   configs/plugins.ini            vexprobe.amxx first, then the stock AMXX plugins
   configs/plugins-vexmira.ini    written per run: copy with "debug" / link to the repo (--no-debug) / absent (plugin off)
   configs/vexmira*.cfg/html, data/lang/vexmira_zombie.txt      -> repo (symlinks)
cstrike/{sound,sprites,models}/vexmira/**, models/player/vex_*/**  -> repo (per-file symlinks)
cstrike/maps/*.bsp|res|nav -> repo, zm_vex_testroom.bsp + generated *.nav local (a local .nav wins over the repo link)
cstrike/{models,sprites,events,...}  Valve placeholders (placeholders_manifest.json)
cstrike/stubs_manifest.json          package stand-ins created by --stub-missing
runs/<stamp>_<map>/                  archived runs
```

## Limits of this setup
* Placeholder Valve models are boxes with a 9-bone CS skeleton and the CS hitgroups; bots
  aim/shoot at them normally, but nothing visual can be judged here (no client).
* Bots never press the plugin's skill keys; only abilities the plugin triggers for bots
  itself (and boss AI) run. Menus / HUD / client-side sprites are not exercised.
* Sounds and 2D `spk` sounds are not decoded by a dedicated server; the probe only proves that
  the engine was asked to play them. Valve sound files are absent (precache of stock sounds still
  happens, the engine does not open sound files).
* Precache numbers depend on the map's boss plan (the plugin loads 4 bosses per map) and on the
  `--stub-missing` stand-ins present in the server tree (`stubs_manifest.json`; `--clean-stubs`).
* Several harness runs can share one server tree only one at a time (same logs / plugin file);
  parallel agents use their own copies via `VEX_SERVER=$SP/serverB ...`. The UDP port is picked
  automatically (first free from `--port`).
* Nav meshes are generated by the stock ZBot learner from the spawn points; areas a bot cannot
  walk to from a spawn (e.g. only reachable by a ladder the learner skips) get no nav and bots
  will not go there.
