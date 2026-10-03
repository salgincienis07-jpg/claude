# mapkit — procedural Counter-Strike 1.6 map toolkit (Vexmira Zombie)

Everything a map agent needs to build an **original** GoldSrc map from Python:
procedural textures (no third-party art), a Valve220 `.map` writer with brush and
entity helpers, an SDHLT compile pipeline that embeds every texture in the BSP,
a BSP validator with an exact spawn test, and a software preview renderer.

```
devtools/mapkit/
  wad.py          WAD3 read/write, image -> miptex (4 mips, own 256-colour palette)
  texgen.py       tileable noise / voronoi / relief shading / stroke font primitives
  textures.py     91 original textures (105 wad entries incl. animation frames) + texlights
  mapwriter.py    Map / Entity / Brush, Valve220 writer, brush + entity helpers
  compile.py      CSG -> BSP -> VIS -> RAD (SDHLT), log parsing, leak report, .res
  bspcheck.py     BSP v30 parser + engine-limit / texture / spawn validator
  preview.py      top-down + oblique renders with real textures and lightmaps
  pilot.py        zm_vex_pilot test map (pipeline proof)
  selftest.py     WAD round trip + compile of every helper
  build_sdhlt.sh  clone + build seedee/SDHLT (pinned commit) with cmake
```

## Quick start

```bash
cd devtools
export MAPKIT_WORK=/tmp/mapwork                 # build dir (default devtools/mapkit/.build, gitignored)
# export SDHLT_TOOLS=/path/to/sdhlt/tools       # if not auto-detected (see compile.find_tools)
python3 -m mapkit.selftest                      # sanity check (~2 s)
python3 -m mapkit.pilot --quality final --preview /tmp/prev   # -> cstrike/maps/zm_vex_pilot.bsp
python3 -m mapkit.bspcheck ../cstrike/maps/zm_vex_pilot.bsp
python3 -m mapkit.preview  ../cstrike/maps/zm_vex_pilot.bsp /tmp/prev
python3 -m mapkit.textures --list               # texture catalogue
python3 -m mapkit.textures --sheet /tmp/sheet.png --wad /tmp/vexmira_all.wad
```

No SDHLT build yet? `devtools/mapkit/build_sdhlt.sh` (git, cmake >= 3.20, g++) builds it into
`devtools/mapkit/.sdhlt/tools`, where `compile.py` looks automatically.

## Writing a map

```python
import sys; sys.path.insert(0, 'devtools')
from mapkit.mapwriter import *          # Map, Brush, Entity + helpers
from mapkit.compile import compile_map
from mapkit.preview import render_views

m = Map('zm_vex_harbor', sky='night')   # sky must be a STOCK sky (STOCK_SKIES)
m.add(skybox((-2048, -2048, 0), (2048, 2048, 1024), ground='vx_asphalt'))
m.add(room((-512, -512, 0), (512, 512, 256), 16, 'vx_metal_corr', floor='vx_conc_crack', ceil='vx_metal_dark'))
m.add_entity(light((0, 0, 200), (255, 200, 140), 250))
m.add_entities(spawn_grid('ct', (-400, -400), (400, -100), 0, 32, spacing=72, yaw=90))
m.add_entities(spawn_grid('t',  (-400,  100), (400,  400), 0, 32, spacing=72, yaw=270))
print(m.spawn_problems(), m.stats())
r = compile_map(m, quality='final', out_dir='cstrike/maps')   # also runs bspcheck
assert r.ok, r.summary()
render_views(r.bsp, '/tmp/prev')                               # LOOK at the PNGs
```

### Coordinates and conventions
* X east, Y north, Z up, 1 unit ~ 1 inch. Floors at z=0 are easiest; spawn origin z = floor + 37.
* `Brush` faces use the Valve220 format. Default alignment `'readable'`: world-anchored (so
  coplanar neighbours line up seamlessly) but oriented so text/logos are never mirrored
  (u = viewer's right, v = down; floors world XY, ceilings flipped for viewing from below).
  Other modes: `'world'` (classic Hammer axes), `'face'` (in-plane axes for slopes, used by `wedge`/`pipe`). `Brush.fit_faces(('n','s'))` / `Face.fit()`
  stretch one texture exactly across a face (crates, doors, signs, screens). `Map(tex_scale={'vx_snow': 2})`
  scales a texture globally. Face directions: `top bottom n s e w` (n=+Y, e=+X).
* Texture specs: `'vx_conc_clean'`, or `{'top': .., 'bottom': .., 'sides': .., 'n': .., 'all': ..}`,
  or `callable(normal) -> name`.

### Brush helpers (return `list[Brush]` unless noted)
| helper | what |
|---|---|
| `box(mins, maxs, tex, fit=False)` | axis box |
| `Brush.from_points(pts, tex)` | any convex brush from vertices (hull; planes through real vertices) |
| `room(mins, maxs, wall, tex, floor=, ceil=, omit={'n',..}, sky_ceiling=False)` | hollow room, mins/maxs = interior |
| `skybox(mins, maxs, t, ground=None)` | seal an outdoor area with sky (optionally solid ground) |
| `wall(p0, p1, z0, z1, thick, tex, holes=[(a0,a1,z0,z1)], side='center'/'left'/'right')` | axis wall with rectangular door/window holes |
| `frame(p0, p1, z0, z1, thick, depth, tex, hole, trim=8)` | jambs + header around a hole |
| `stairs(origin, dir, width, height, rise=8, run=16, tex, clip=False)` | solid steps (+ optional CLIP ramp) |
| `wedge(origin, dir, width, length, height, tex)` | ramp (keep height/length <= 1) |
| `prism(center, radius, sides, z0, z1, tex)` | n-gon pillar (vertices snapped to 1 unit) |
| `pipe(p0, p1, radius, sides, tex)` | pipe between two points |
| `arch(center, z_spring, radius, outer_w, top, depth, axis, segments, tex)` | semicircular arch filler |
| `railing(p0, p1, z, height=40)` -> (visual, clip) | `{vx_rail` slab + CLIP brush |
| `catwalk(p0, p1, z, width, thick, tex, rails)` -> (slab, rail_vis, rail_clip) | walkway with rails |
| `ladder(base, facing, height, width=32, depth=16)` -> (func_ladder Entity, visual brushes) | ladder |
| `crate(origin, size, tex, height=None, top=None)` | crate with fitted texture |

### Entity helpers (return `Entity`)
`light`, `light_spot`, `light_environment` (sun + `_diffuse_light` sky fill), `info_spawn`,
`spawn_grid(team, mins_xy, maxs_xy, floor_z, count, spacing=64, yaw=|face=(x,y), margin=24)` (list),
`ambient` (ambient_generic), `env_sprite`, `func_wall`, `func_illusionary`,
`masked_entity` (rendermode 4 / renderamt 255 for `{` textures), `glass` (func_breakable,
rendermode 2), `breakable`, `door` (func_door; `'up' 'down' '+x' '-x' '+y' '-y'`), `func_water`,
`trigger_hurt`, `func_buyzone`, `info_map_parameters`. Generic: `Entity('classname', brushes, key=value)`.

Tool textures: `NULL` (removed, use on hidden faces of detail), `CLIP`, `SKIP`, `HINT`,
`ORIGIN`, `AAATRIGGER` (`TRIGGER`), `sky` (`SKY`), `BEVEL` — all from `sdhlt.wad` and embedded too.

### Compile (`compile.py`)
`compile_map(map_or_path, quality='draft'|'normal'|'final', out_dir=None, extra={'rad': [...]})`

| quality | VIS | RAD |
|---|---|---|
| draft | `-fast` | `-fast -bounce 1 -pre25` |
| normal | default | `-bounce 3 -smooth 50 -pre25` |
| final | `-full` | `-extra -bounce 4 -smooth 50 -chop 64 -texchop 32 -pre25 -ao -aoscale 32 -aoopacity 0.6 -pcf 2`, CSG `-cliptype precise` |

* Builds `<work>/<map>_vx.wad` with exactly the used `vx_*` textures (all animation frames),
  points worldspawn `wad` at it + `sdhlt.wad`, and passes `-wadinclude` for both — the final BSP
  embeds **every** texture and its `wad` key is empty (verified by bspcheck).
* Writes `<work>/<map>.rad` with the library texlights (`~` textures, lava, toxic...).
* `-pre25` keeps lightmaps safe for pre-HL25 (non-Steam) clients, common on Turkish servers.
* Leaks: BSP writes a pointfile; the result fails with `LEAK: pointfile ... first point: x y z`.
* Writes `out_dir/<map>.res` listing custom (`vexmira/`) sounds/sprites/models referenced by entities.
* Threads = CPU count; timings and parsed errors/warnings per stage in `CompileResult.summary()`.

### Validate (`bspcheck.py`)
Exit code 1 on errors. Checks lump counts/sizes vs GoldSrc limits (HLSDK `bspfile.h`: models 400,
planes/nodes/clipnodes 32767, leafs 8192, vertexes/faces/marksurfaces 65535, texinfo 8192, edges
256000, surfedges 512000, textures 512 / 2 MB, lighting 2 MB, visibility 2 MB, entdata 128 KB;
warns at 85 %), non-embedded textures, wad key, stock sky, texture sizes, face lightmap extents
(engine "Bad surface extents"), lightmap consistency, +-4096 bounds, key/value lengths, entity and
brush-model counts, and **spawns**: >= 32 `info_player_start` (CT) + 32 `info_player_deathmatch`
(T), each tested against the compiled standing player clip hull (hull 1) of the world and of
static solid brush entities (exact engine point-contents test), distance to the floor, spacing.

### Preview (`preview.py`)
`render_views(bsp, out_dir, size=1200, zcut=None, eyes=[(x, y, z, yaw, pitch), ...])` writes
`_top`, `_oblique`, `_oblique2` (orthographic, back-face culling gives cut-away interiors, `zcut`
hides faces above a height; markers: CT blue, T red, light yellow, ladder green, ambient magenta,
sprite cyan) and perspective "screenshots" at player eye height (`_eye_ct`: CT spawn centroid
looking at the T spawns, `_eye_t` the reverse, `_eye<N>` for `eyes`), all rendered from the BSP
faces with the embedded textures + RAD lightmaps (liquids unlit like the engine, unlit faces
black). CLI: `--eye X Y Z YAW PITCH` (repeatable). `Renderer(BSP(p)).render_persp(...)` for
custom shots, `contact_sheet(texs, path)` for textures. Always LOOK at these before shipping.

## Texture library (`textures.py`)

All generated by code (numpy/Pillow, fixed seeds), tileable, mid-tone for lightmaps, each with its
own 256-colour palette and 4 mip levels. Rebuilds are cached in `.texcache/` (keyed by source hash).

| category | textures |
|---|---|
| concrete | `vx_conc_clean` (256), `vx_conc_crack` (256), `vx_conc_stain` (256), `vx_conc_panel`, `vx_bunker` |
| brick | `vx_brick_red`, `vx_brick_grey`, `vx_brick_dark` |
| wall | `vx_plaster`, `vx_wallpaper`, `vx_roof_tile` |
| wood | `vx_wood_floor`, `vx_wood_plank` |
| tile / lab | `vx_tile_lab`, `vx_tile_dirty`, `vx_floor_lab`, `vx_wall_lab` |
| metal | `vx_metal_plate`, `vx_metal_diam`, `vx_metal_rust`, `vx_metal_corr`, `vx_metal_panel`, `vx_metal_dark`, `vx_metal_floor`, `vx_frost_metal`, `vx_trim_metal` (128x32), `vx_hazard`, `vx_trim_hazard` (128x32) |
| crate | `vx_crate_wood`, `vx_crate_mil` |
| container | `vx_cont_red`, `vx_cont_blue`, `vx_cont_green`, `vx_cont_orange` (256x128 sides), `vx_cont_end` |
| ground | `vx_asphalt` (256), `vx_road_line`, `vx_dirt`, `vx_grass`, `vx_snow` (256), `vx_snow_rock`, `vx_ice`, `vx_rock` (256), `vx_sand` (256), `~`-lit `vx_lavarock` |
| temple | `vx_marble`, `vx_marble_dark`, `vx_stone_carved`, `vx_temple_orn`, `vx_temple_glyph`, `vx_pillar`, `vx_temple_flr` |
| liquid | `+0vx_lava`..`+9vx_lava` (animated, lit), `+0vx_sludge`..`+5vx_sludge` (animated, lit), `!vx_toxic`, `!vx_water`, `!vx_water_dk`, `!lava_vx` (lava contents) |
| glass | `vx_glass` (rendermode 2), `{vx_glass_brk` |
| masked | `{vx_fence`, `{vx_grate`, `{vx_rail` (128x64), `{vx_ladder` (64x128) |
| overlays | `{vx_blood1`, `{vx_blood2`, `{vx_goo`, `{vx_claw` |
| machine | `vx_pipe`, `vx_pipes_wall`, `vx_vent`, `vx_server`, `vx_console` |
| screens (lit) | `~vx_screen1` charts, `~vx_screen2` terminal, `~vx_screen3` radar (128x96) |
| lights | `~vx_light_w` (128x64), `~vx_light_c`, `~vx_light_p` (128x32), `~vx_light_r`, `~vx_light_y`, `~vx_light_sq` (64x64) |
| signs | `~vx_neon_vex` VEXMIRA, `~vx_neon_dngr` DANGER, `~vx_neon_safe` SAFE ZONE (256x64), `~vx_neon_exit` (128x64), `vx_sign_bio`, `vx_sign_vex` |
| doors | `vx_door_metal`, `vx_door_wood` (64x128), `vx_door_lab` (128) |

Texlight intensities live in each `@tex(..., light=(r, g, b, intensity))` and `TEXLIGHTS`; tune with
`write_rad(path, extra={'~vx_light_w': (255, 250, 235, 2000)})` or by editing the registry.
Adding a texture: write a function decorated with `@tex('vx_name', w, h, 'category')` returning a
float RGB(A) array (or a list of frames with `frames=N`), then look at `--sheet`.

## Level design rules for CS 1.6 zombie maps

**Player geometry** (ReGameDLL `util.h`, `pm_shared`):
* standing hull 32x32x72 (origin = hull centre, feet at origin-36), eye at feet+53;
  crouched hull 32x32x36, eye at feet+30.
* step-up 18 (stairs: rise <= 16, run >= 16; 8/16 feels best). Jump apex 45 units
  (`sqrt(2*800*45)`); duck-jump clears ~58-60 (feet rise 18 more when ducking in the air).
  Design: <= 40 "hop up", 46-56 "duck-jump only" (good zombie shortcuts), >= 64 needs stairs/ladder.
* max walkable slope: plane normal z >= 0.7 (~45.6 deg); steeper surfaces are slides (use
  them on purpose, never by accident). Ramps from `wedge()`: height/length <= 1.
* clearances: ceiling >= 128 above floors people fight on (72 + 45 jump); crouch tunnels >= 40
  high (36 hull) — use 48; corridors >= 64 wide (two players), 96-128 for main zombie routes;
  doorways 64-96 wide x 112-128 high; gaps <= 32 between parallel walls trap players — avoid.

**Ladders**: `ladder()` = invisible `func_ladder` volume (AAATRIGGER, 32 wide, 10-16 deep, from
floor to ledge top + 4) + masked visual. One `func_ladder` per ladder (the engine uses the
model's bounding box centre to find the climb normal — never merge ladders). Leave a 64 wide
gap in railings at the top; keep the top edge free of overhangs.

**Spawns**: >= 32 CT (`info_player_start`) + >= 32 T (`info_player_deathmatch`) — the zombie
mod moves players around, but CS needs both sets for 32 v 32. Grid spacing >= 64 (we use 72),
origin z = floor + 37, all of one team on the same floor, facing into the map, >= 24 units
(plus the 16 hull half width) from walls, not in liquids/trigger_hurt/doors/func_wall.
`Map.spawn_problems()` before compiling, `bspcheck` exact test after.

**Human camp spots** (3-6 per map): elevated or enclosed, 1-3 entrances 64-128 wide, reachable
by zombies on foot (stairs, ladder, duck-jump) — **no unreachable camp** (no spot zombies can
only reach by hacks; check with the oblique previews); avoid one-player-wide chokes that make
a single human invincible; give each camp a weakness (second entrance, breakable glass,
ladder, a vent). Put ammo/supply props there for flavour, not cover walls that seal it.

**Zombie routes**: every area >= 2 routes, loops instead of dead ends, vents/duck-jump
shortcuts (48 high tunnels) as zombie-favoured paths, doors only as `func_door` that open on
touch with `wait` 3-4 (never lockable), no `func_door` crushing (`dmg 0`). Liquids: shallow
(<= 36) or with exits; lava/toxic = `trigger_hurt` + a wall/curb, not instant death on main paths.

**Lighting recipe**: readable but moody. Fixture brushes with `~` texlights (they light the room
realistically) + a few `light` fill entities (brightness 80-150 low, 200-300 key) with warm/cool
contrast per zone; accent colours from the palette (Vexmira purple 160,90,255 / cyan 0,220,255,
danger red, toxic green); `light_environment` (pitch -50..-75, `_diffuse_light` sky fill) for
outdoor maps; `env_sprite` glows on lamps (stock `sprites/glow01.spr`, additive, scale 0.2-1.2);
final compiles use `-extra -bounce 4 -ao`. Never leave zones black: zombies need to see humans too.

**Performance** (r_speeds): aim for < 800 wpoly / < 15k epoly in busy views. Break long sight
lines (corners, walls, raised blocks) so VIS can cull; put HINT brushes at corridor mouths; make
small detail (pipes, rails, signs, lamps) `func_illusionary`/`func_wall` or texture hidden faces
`NULL`; use `SKIP`/`CLIP` for smooth collision on stairs; keep outdoor sky boxes tight around the
playable volume; keep big flat floors as few large faces (no needless brush splits).
Brush entities each take a **model precache slot** (512 total shared with the plugin's ~100+
models): keep them < 64 (group decorative brushes into one `func_illusionary`/`func_wall`).
Entities < 600 (edicts ~900 with 32 players). Map <= 4 MB (textures dominate: ~22 KB per
128x128, ~87 KB per 256x256 — use 20-35 textures per map).

**Engine/compat limits**: geometry within +-4096 (CS player origins), texture names <= 15 chars,
texture sizes multiples of 16 and <= 256 for software/old GL, sky = stock name only
(`STOCK_SKIES`), all textures embedded (no wad downloads), `{` textures need an entity with
rendermode 4/renderamt 255, glass rendermode 2 with renderamt 60-120, `!` textures make water
contents (`!lava*` lava, `!slime*` slime), animated `+0..+9` frames play at 10 fps.
`ambient_generic` loops only if the WAV has a cue chunk (our event sounds have none, so map
ambience that must loop needs looped WAVs); sounds/sprites under `vexmira/` are listed in the
generated `maps/<map>.res` and must ship in the package.

## Pilot map

`zm_vex_pilot` (testing only) proves the pipeline: lab hall with CT spawns, sunken toxic pool
(liquid + trigger_hurt), 4 pillars, crates, container prop, east CT camp platform (grate deck
func_wall, stairs, ladder, railings + clip), SW control booth (breakable glass, lit screens,
server rack), skylight shaft (sky + light_environment + grate), VEXMIRA / DANGER / EXIT neon
texlights, auto blast door (func_door) + stone arch to the red-lit zombie den (T spawns,
blood/goo/claw overlays, heartbeat ambient). 32+32 spawns, 7 brush models, ~1.2 MB.
