# mdlkit — procedural GoldSrc studio-model toolkit (Vexmira Zombie v3)

Pure Python (numpy/scipy/Pillow) + the HLSDK `studiomdl` Linux port. Everything is generated from code:
meshes, textures (8-bit BMP), animations (SMD), QC; then compiled, post-optimised, validated against the
real engine/client/server logic and rendered to preview PNGs.

```
cd devtools
python3 -m mdlkit samples all            # build the 4 proof samples (see below)
python3 -m mdlkit samples walker --lookdev   # fast texture look-dev (no compile)
python3 -m mdlkit info   ../cstrike/models/player/vex_operator/vex_operator.mdl
python3 -m mdlkit validate ../cstrike/models/player/vex_z_walker/vex_z_walker.mdl --nine knife
python3 -m mdlkit preview  FILE.mdl [--zombie] [--v] [--seq ref_aim_ak47 --frame 0 --view q]
python3 -m mdlkit seqtable [--zombie]
python3 -m mdlkit test                   # convention self-test (compiles tiny models)
```
studiomdl: `$SP/tools/smdl/studiomdl` (override with `MDLKIT_STUDIOMDL`). Rebuild it with
`devtools/mdlkit/build_studiomdl.sh [OUT_DIR]` (clones ValveSoftware/halflife @ b1b5cf58, applies sed
portability edits, `gcc -m32`; the result is byte-identical to the original manual build and produces
byte-identical models). Previews go to `$SP/previews/<area>/` (`MDLKIT_PREVIEWS`), work files to `$SP/mdlwork`.

## Modules

| module | purpose |
|---|---|
| `mathx` | engine-exact math: AngleQuaternion, QuaternionSlerp (incl. flip/180° branch), QuaternionMatrix, studiomdl AngleMatrix (Rz·Ry·Rx), entity matrix |
| `smd`, `qc`, `bmp8` | SMD writers, QC builder, 8-bit BMP writer + quantiser (median cut + k-means, ordered dither, masked palette 255) |
| `geom` | Mesh class + primitives (box/bevel box, ellipsoid, dome, lathe, loft/tube along curve, capsule, horn/spike, extrude, ribbon/cloth strip), mirroring, atlas packing |
| `raster` | numpy triangle rasteriser (preview, UV baking, AO) |
| `paint` | 3D procedural painters + UV baking (+ AO, decals, layered materials) |
| `rig_cs` | CS biped rig (exact bone names/order), parametric proportions, grip frame, AO pose |
| `pose` | FK, two-bone IK with twist-stable frames, finger curl |
| `body`, `accessories`, `characters` | parametric humanoid body + gear/creature parts + spec assembly |
| `anims` | complete CS player sequence table + human / zombie / boss styles |
| `hitbox` | CS hitgroup boxes, hull fitting for oversized bosses |
| `api` | `build_player_model(spec)`, `preview_textures(spec)` |
| `vmodel` | v_ models: claws + CT weapons (enum-exact sequence sets, 5001/5004 events) |
| `pmodel` | gun builder parts/presets + p_ models |
| `mdl_read` | full IDST v10 parser + RLE animation decoder |
| `mdl_opt` | post-compile animation block de-duplication (verified) |
| `preview` | software renderer of COMPILED models with the client's bone setup (9-blend, gait merge, walk hack) |
| `validate` | engine/client/server rule checks |
| `samples` | proof samples = reference specs |

## Coordinate systems & studiomdl conventions (all verified by `mdlkit test`)

* Model space = engine space: **+X forward, +Y left, +Z up**; yaw 0 faces +X.
* QC always has `$origin 0 0 0 -90`: this sets studiomdl's `zrotation` to 0 (stock default is +90°
  added to every root bone), so SMD root data is stored exactly as written.
* SMD rotations are Euler (x,y,z) radians with R = Rz·Ry·Rx (studiomdl AngleMatrix).
* SMD triangles: counter-clockwise seen from outside with outward normals; studiomdl reverses them to the
  engine's clockwise order (engine culls GL_FRONT). `validate` re-checks the compiled winding vs normals.
* UVs: v = 0 bottom of the BMP. studiomdl stores s = int(u·(W−1)), t = (H−1) − int(v·(H−1)) and the
  engine samples at s/W, t/H, so `pack_atlas` snaps every vertex to an integer texel edge.
* `$eyeposition a b c` is stored as (−b, a, c); `qc.QC.eye` takes engine coordinates.
* Bones are ordered by first use across the reference SMDs (model 0 first); unused bones are dropped.
  `api.anchor_bones` adds a hidden 0.02-unit triangle per bone to submodel 0 to guarantee the order.
* Textures are compiled with `-p` (power-of-two skins; GoldSrc GL rounds NPOT sizes down otherwise).
  studiomdl crops each skin to the used UV range, so pack pages full.
* Limits: 2048 verts / normals per submodel (we keep < 2000 and split into bodyparts automatically),
  128 bones, 16 blends, sequence block < 64 KB of RLE data, events options < 64 chars, 4 attachments.

## Player model rules (CS 1.6 client + ReGameDLL)

**Origin = hull centre**: standing feet at z = −36 (hull 32×32×72), crouch feet at z = −18 (crouch hull
32×32×36). `$bbox`/`$cbox` = (−16,−16,−36)…(16,16,36).

**Bone order / gait merge.** cs16client `GameStudioModelRenderer::StudioSetupBones` and ReGameDLL
`SV_StudioSetupBones` copy bones from the gait sequence from index 0 until a bone named `Bip01 Spine`,
then switch copying on again at any bone whose parent is `Bip01 Pelvis`. mdlkit order:
`Bip01, Bip01 Pelvis, L Thigh, L Calf, L Foot, L Toe0, R Thigh, R Calf, R Foot, R Toe0, [lower extras],
Bip01 Spine, Spine1, Spine2, Spine3, Neck, Head, L Clavicle, L UpperArm, L Forearm, L Hand, L Finger0,
L Finger01, L Finger1, L Finger11, R …, [upper extras]` → gait drives root/pelvis/legs (+tail),
the upper-body sequence drives everything else. Upper extras must never be parented to the pelvis.

**Rest frames.** Every bone's rest rotation is identity (axes = model axes) except hands/fingers whose
frame is the **grip frame**: +X = barrel direction, +Z = gun top, +Y = gun left; right palm faces +Y,
left palm −Y. The grip centre is `rig_cs.GRIP_R/GRIP_L` in hand coordinates. p_ guns are modelled in
gun space and bound to a root bone `Bip01 R Hand` (+`Bip01 L Hand` for dual) → the engine's merge by
bone NAME places them correctly in every vex_* character's hands.

**Sequence table** (`python3 -m mdlkit seqtable`), derived from the sources:

| index | sequences | notes |
|---|---|---|
| 0 | dummy | gaitsequence 0 = "no gait" in the client |
| 1–7 | idle1 ACT_IDLE, crouch_idle ACT_CROUCHIDLE, **walk (3)** ACT_WALK LX, run ACT_RUN LX, crouchrun ACT_CROUCH LX, **jump (6)** ACT_HOP, longjump ACT_LEAP | gait sequences (`LookupActivity`), each activity exactly once |
| **8, 9** | swim ACT_SWIM, treadwater ACT_HOVER | full body, client skips the gait merge for 8/9 |
| 10–93 | `<crouch|ref>_<aim|shoot|[shoot2]|[reload]>_<ext>` for carbine onehanded dualpistols rifle mp5 shotgun m249 grenade knife c4 ak47 shieldgun shieldknife shieldgren shielded shield | `GetAnimDesired`; all 9-blend for humans, only knife for zombies/bosses |
| 94, 95 | gut_flinch, head_flinch | looked up by name |
| 96–100 | pad0..pad4 | padding so deaths start at 101 |
| **101–111** | death1 DIESIMPLE, death2 DIEBACKWARD, death3 DIEFORWARD, head DIE_HEADSHOT, gutshot DIE_GUTSHOT, left, back DIE_BACKSHOT, right, forward DIEFORWARD, crouch_die, chestshot DIE_CHESTSHOT | client: no gait merge for 101..159; nothing else may live there; every 9-blend sequence must be < 101 (server merges gait only below 101) |

**9-blend layout** (client `numblends == 9` code + `CalculateYawBlend` / `StudioPlayerBlend`):
blend index = row·3 + col. `blending[0]` (s) picks the column: col 0 = upper body twisted **+90° (left)**
relative to the legs, col 1 = 0°, col 2 = −90° (right). `blending[1]` (t) picks the row: row 0 = aim
**+45° up**, row 1 = level, row 2 = −45° down (entity pitch = −v_angle/3, ×3, ±45° range). The client
subtracts 26 from `blending[0]` when the gait is sequence 3 (walk) → our walk gait yaws the pelvis −18.35°
to cancel it. Aim pitch is split between the spine (kp) and the arms; the gun frame is levelled
independently of hunch / crouch lean (`UpperBody.aim_frame`).

**Gait linear movement.** The client advances `gaitframe += dist / linearmovement[0] * numframes`, so
walk/run/crouchrun use LX motion extraction with `linearmovement[0] = D·N/(N−1)` (no foot sliding).

**Upper-body sequences** store root/pelvis/legs at their REST values (the engine replaces them with the
gait) → zero animation data for those channels; they are authored against the real gait pelvis pose.

**Hitboxes / hitgroups**: 1 head, 2 chest (Spine2, Spine3, Neck), 3 stomach (Pelvis, Spine, Spine1),
4/5 left/right arm (UpperArm, Forearm, Hand+fingers), 6/7 left/right leg (Thigh, Calf, Foot+toe). Traces
are AABB-culled against the hull, so `validate` requires head/chest/stomach box centres inside the hull
vertically in standing AND crouched aim poses at all blend corners (crouch keeps the head under +18).
Oversized bosses: `spec['hull_fit'] = True` remaps rest-pose boxes into the hull (bone-local offsets).
Attachment 0 = right hand muzzle area (used by the client when the p_ model has no attachments).

**Size budgets** (`validate`): human ≤ 1.0 MB (operator 0.87 MB with a 512² skin), zombie ≤ 0.45 MB
(walker 0.35 MB, 512×256), boss ≤ 0.7 MB, claws ≤ 0.2 MB, p_ ≤ 0.08 MB, v_ human ≤ 0.4 MB.
Animation data dominates: each blend costs 12 bytes × bones of headers. Humans: all weapon sequences
9-blend; shield*/c4 sequences reuse the aim pose (de-duplicated by `mdl_opt`). Zombies/bosses: knife
9-blend, all other weapon sequences 1-frame single-blend placeholders (names must exist).

## Character spec (see `samples.py`)

```python
spec = dict(
  name='vex_z_walker', style='zombie',            # human | zombie | boss | floaty
  style_params=dict(hunch=20, lurch=0.7, limp=0.25, run_D=96, crouch_h=0.29, claw_spread=1.0),
  rig=RigSpec.preset('zombie'),                  # height, shoulder_w, hip_w, leg, arm, hand, head, neck, bulk,
                                                 # limb_thick, hand_pose 'grip'|'claw'|'open', extras=[...]
  shape=dict(hands='claw', feet='bare', gaunt=0.35, hump=0.22, muscle=0.15, belly=0, chest=1, waist=1,
             head=dict(jaw_drop=0.35, sockets=1.5, nose=0.6, ears=1, snout=0, ...)),
  mats=dict(torso='body', arm='body', leg='legs', foot='boot', hand='hand', neck='skin', head='head', claw='claw'),
  materials=fn(rig, sh) or dict,                 # name -> paint material (see below)
  decals=fn(rig, sh) or list,                    # 3D decals (rest pose model space)
  face=dict(eye='human'|'glow'|'dead', glow=(r,g,b), mouth='closed'|'open'|'snarl', ...),
  accessories=[('helmet', {...}), ('vest', {...}), ('horns', {...}), ...] or fn(rig, sh),
  tex=dict(w=512, h=256, pages=1), budget=0.45e6, hull_fit=False, nine_exts=None|{'knife'},
)
build_player_model(spec)        # -> cstrike/models/player/<name>/<name>.mdl + previews + report
preview_textures(spec)          # fast rest-pose look-dev of the painted textures (no compile)
```

**Materials** (`paint.py`): `skin` (variation, tint2, veins, rot, wounds, blood, scars), `cloth` (weave,
folds, plaid, camo, stripes, dirt, stains, tears, blood), `metal`/`armor` (paint + chipping, edge wear,
panels, scratches, rust), `leather`, `rubber`, `glow` (emissive, skips AO), `fur`, `hair`, `scales`,
`crystal`, `lava` (glowing cracks), `bone`/`horn` (rings, dark tips), `visor`, `flat`, and `layers`
(base + layers with `where` conditions: meshes, z/x/y ranges, limb parameter `t`, ragged edges, worley
holes, facing). Noise is evaluated in 3D rest-pose space, so patterns are seamless across UV islands.
AO is baked in a spread "AO pose" (arms/legs away from the body).
**Decals**: `sphere`, `band`, `shape` (SDF emblems: vex logo, circle, ring, diamond, cross, chevron, skull,
slit, bar) with modes paint / multiply / add / glow / blood, optional `target` mesh/material names.
**Accessories** (`accessories.py`): helmet, goggles, gasmask, hood, hair, vest, belt, backpack,
shoulder_pads, knee_pads, bracers, sleeve_cuffs, coat_skirt, cape, shirt_flaps, ribs, horns, spikes,
crystals, tail (+`tail_extras` rig bones), glow_eyes, jaw_teeth, chain, plates_on, wraps, emblem_patch, shell.

## View models / p_ / world

* `vmodel.build_claws(spec, out)` — claw arms from a zombie/boss spec (same materials), knife sequence
  order (idle, slash1, slash2, draw, stab, stab_miss, midslash1, midslash2).
* `vmodel.build_vmodel(name, arms_spec, kind, gun_meshes, out)` — CT arms (use the operator spec) + gun;
  `kind` ∈ knife, hegrenade, flashbang, smokegrenade, ak47, m4a1, m249, awp, xm1014, deagle, p90, sg550
  (sequence lists = ReGameDLL enums), muzzle 5001 events on shoot sequences, 5004 stock reload sounds.
  View space: origin = eye, +X view direction (fov 90).
* `pmodel.gun_preset(kind)` + parts (receiver, barrel, handguard, pistol_grip, magazine, stock, scope,
  rail, muzzle_brake, glow_strip …); `pmodel.build_pmodel(name, meshes, out, dual=False)`.

## How to add a new character

1. Copy `walker_spec` / `operator_spec` in `samples.py` into your own module; set name, style, RigSpec
   proportions, shape, materials, accessories, decals, colours (CLASS_RGB from DESIGN_v3.md).
2. Iterate the look with `preview_textures(spec)` (seconds) and read the PNG.
3. `build_player_model(spec)`; read all 6 preview sheets (turn, blend9, moves, actions, deaths, hitbox).
4. For zombies/bosses also `vmodel.build_claws(spec, 'cstrike/models/vexmira/claws/v_<name>.mdl')`.

## Quality checklist

- [ ] `validate` has no errors; size within budget; winding_bad ≈ 0
- [ ] silhouette readable from front/side/back at 260 px; colours match the class colour
- [ ] textures painted (noise, AO, decals), no magenta (missing material), no visible UV seams on faces
- [ ] blend9 sheet: torso twists left/right, gun/claws aim up/down correctly
- [ ] moves sheet: feet on the floor, crouch inside the 36-unit hull, jump tucks, swim horizontal
- [ ] deaths end lying on the floor (no floating, no limbs through the floor)
- [ ] hitbox sheet: boxes cover the body, head box on the head, inside the hull vertically
- [ ] p_ preview: gun in the right hand, support hand on the handguard
- [ ] v_ preview: arms visible, nothing closer than ~4 units, sequence order = enum

## Known limitations

* Rigid skinning only (GoldSrc): joints stretch one ring band; extreme poses pinch.
* The hand grip frame matches our characters and p_ models; Valve's stock p_ models were not available
  for comparison, so stock p_ weapons in our hands may be rotated (we replace all p_ models).
* cs16client is a reimplementation of the official client; the hard-coded indices/blend logic it uses are
  mirrored here (the official client is closed source).
