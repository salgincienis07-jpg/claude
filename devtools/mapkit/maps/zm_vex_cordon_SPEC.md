# zm_vex_cordon — build spec (flagship map, first map of `vex_map_pool`)

**EN title:** Cordon 7 — Vexmira Harbor Quarantine
**TR baslik:** Kordon 7 — Vexmira Liman Karantinasi

**Pitch.** Night. A harbor district of Vexmira sealed behind a military quarantine wall. The
infection came in on the last evacuation train, which lies derailed inside the terminus station.
Survivors start at the welded-shut Gate 7 checkpoint and in the station concourse. Every round has
a direction: power (west) -> lift bridge (south harbor) -> evac beacon on the Customs Tower roof
(east), while the shelling outside the wall gets closer every minute. It is big (about 6.6k x 5.8k
playable units, 9 districts, 3 levels: city 0, harbor -128, tower roof 576), but every district is
a sealed, sky-capped cell joined to the next by bends, arcades and low-header gates, so VIS keeps
every view small. Grafted ideas: Angle A (vertical tower with a roof evac pad and a crown landmark
seen from the hub), Angle C (derailed train in the station, moving lift bridge, hovering medevac).

Calibration this design is based on (earlier prototypes of the same layout, full VIS, bspcheck):
`zm_cal_cordon` (sealed sky-capped zones, 3.6k world faces, light detail): view wpoly **max 648 /
p95 554**; `zm_cal_cordon_b` (same zones, 12k faces of facade relief, open full-height
openings): **max 2300 / p95 1852** (FAILED). Lesson: the layout works, the density and the open
portals did not. This spec caps the drawable world at **~8,200 faces**, gives every zone a face
budget, and makes every zone-to-zone opening a low portal with a bend.

---------------------------------------------------------------------------------------------------

## 1. Story

Story EN (ini `[story_en]`, 6 lines):
1. Night 3 of the outbreak. The Vexmira strain rode the last evacuation train into the harbor district.
2. The army sealed Cordon 7 and welded Gate 7 shut. Nobody walks out.
3. The only way out is by air: a medevac helicopter, if it can find the Customs Tower roof.
4. Restore power at the Substation, lower the lift bridge, light the evac beacon.
5. The infected are already in the station. Every minute the shelling comes closer.
6. Stay together. Stay in the light.

Story TR (ini `[story_tr]`, Turkish letters written without special characters):
1. Salginin 3. gecesi. Vexmira virusu son tahliye treniyle liman bolgesine ulasti.
2. Ordu Kordon 7'yi muhurledi ve Kapi 7'yi kaynakla kapatti. Kimse yuruyerek cikamaz.
3. Tek cikis hava yolu: Gumruk Kulesi'nin catisini bulabilirse bir tahliye helikopteri.
4. Trafo merkezinde elektrigi ver, kaldirma koprusunu indir, tahliye isaretini yak.
5. Enfekteliler zaten istasyonda. Bombardiman her dakika yaklasiyor.
6. Birlikte kalin. Isikta kalin.

## 2. Per-round flow (what every round feels like)

| time | event | what happens in the map |
|---|---|---|
| 0:00 | `vex_round_start` | everything reset (section 8). District is **dark**: moonlight, burning wrecks, red emergency lamps, the generator floodlights of Gate 7. Wind + distant sirens. CT spawn in Gate 7 yard, T spawn in the station concourse next to the wrecked train. Objective panel shows 3 lines. |
| freeze end | `vex_freeze_end` (+ ini event) | Gate 7 barrier arm swings up (go!). Green EVAC arrows (always lit) point out of both spawns. |
| ~0:20 | `vex_infection` | **Train breach**: the rear carriage door of the derailed train blows off, explosion flash, screen shake in the station, red strobes + station siren, story line "breach". The first zombies start in the middle of the T group — panic, everybody runs. |
| any | Obj 1 Substation | humans throw **two breakers** (switch house + gantry, 512 u apart -> the team splits). Power sequence: hum starts, lights come on block by block west -> plaza -> east (2.2 s), bridge cabin panel turns green, +5 ammo packs, story line. |
| any | Obj 2 Harbor | bridge control cabin (locked until power): yellow strobes, the lift bridge deck lowers 384 u in 8 s, harbor sodium lights on, +8 ammo packs. Opens the quay -> container terminal shortcut. |
| any | Obj 3 Tower roof | evac beacon console (locked until bridge): pad lights green, rotor sound grows, 14 s later the medevac helicopter glides in and hovers over the pad, supply drop = +15 ammo packs, "hold the roof". |
| every 60 s | `vex_minute` | artillery: distant boom + global light shake + a flash on the horizon behind the quarantine wall. It "comes closer": the ini adds a 2nd boom from minute 3. |
| boss | `vex_boss` | Liberation Plaza: white floods off, red floods + plaza siren, shake; 4 s later the VEXMIRA billboard topples into the plaza with a crash. Boss arena = plaza. `vex_boss_dead`: red off, white back only if power is on. |
| nemesis / assassin | blackout | district lights die block by block, hum stops, emergency red only. |
| last human | `vex_lasthuman` | blackout + global siren + plaza red. |
| win humans | `vex_win_humans` | Gate 7 opens onto the floodlit no-man's land; the helicopter (if called) lifts off. |
| win zombies | `vex_win_zombies` | all red, sirens everywhere, district lights off. |
| zombie goal | riot barricade | zombies smash the plexiglass riot barricade in the tower lobby -> +5 ammo packs for zombies + story line. |

The three objectives are a chain on purpose (master/locked), so the flow always runs **west ->
south -> east** and visits the whole map; there are always other routes, so nothing is a dead end
if the chain is not finished.

## 3. Top plan

```
         x=-3456                    -768    0    +768                  +3456
   3200 | vvvvvvvvvvv                                          |
   3008 | vvvvvvvvvvv                                          |   v  no-man's land vista (unreachable)
   2816 | vvvvvvvvvvv                                          |   A  Gate 7 checkpoint (CT spawn, o)
   2624 | AAAAAAAAAAA                                          |   c  command post (indoor)  a alley
   2432 | AAAAAAAAAAAppp   RRRRRRRRRRRRRRRRRRHHHHHwwwwww       |   M  Market street (S-bend), m arcade
   2240 | AAAAAAAAAAAMMMMMMRRRRRRRRRRRRRRRRRRHHHHHwwwwww       |   p  pharmacy (indoor)
   2048 | AAAAAAAAAAAMMMMMMRRRRRRRRRRRRRRRRRRHHHHHwwwwww       |   R  terminus station + derailed train (T spawn, z)
   1856 | AAAAoAAAAAA  MMMMRRRRRRRRRRRRRRRRRRHHHHHHHHHHH       |   f  station forecourts (dog-legs)
   1664 | AAAAAAAAAAA  MMMMRRRRRRRRRRRRzRRRRRHHHHHHHHHHH       |   H  field hospital, w ward (indoor)
   1472 |   ccccc aa   MMMM   fff      fff   HHHHHHHHHHH       |   S  substation (OBJ 1 = 1), h switch house
   1280 |   ccccc aa   MMMM   fff      fff           KKK       |   L  lantern lane (Z-bend)
   1088 | SSSSSSSSSSS  MMMMPPPPPPPPPPPPPPPPPP        KKK       |   P  Liberation Plaza (boss arena, * monument,
    896 | ShhhhSSSSSS  MMMmPPPPPPPPPPPPPPPPPPTTTTTTTTKKK       |      b billboard)
    704 | Sh1hhSSSSSS      PPPPPPPPPPPPPPPPPPT^TTTTTTKKK       |   T  Customs Tower (lobby/offices/plant/roof,
    512 | ShhhhSSSSSS      PPPPPPPPPPPPPPPPPPTTTTTTTTKKK       |      3 = OBJ 3 pad, ^ crown landmark)
    320 | SSSSSSSSSSS      PPPPPPPPPPPPPPPPPPTTTT3TTTKKK       |   t  tower south passage
    128 | SSSSSSSSS1SLLLL  PPPPPPPPPPPPPPPPPPTTTTTTTTKKK       |   K  Kade harbor road (2 gate arches)
    -64 | SSSSSSSSSSSLLLL  PPPPPPPPP*PPPPPPPPTTTTTTTTKKK       |   n  stair lane (0 -> -128)
   -256 | SSSSSSSSSSS  LLLLPPPPPPPPPPPPPPPPPPTTTTTTTTKKK       |   F  fish market hall (indoor, -128)
   -448 | SSSSSSSSSSS  LLLLPPPPPPPPPPPPPPPPPPttttttttKKK       |   e  harbor steps (0 -> -128, memorial)
   -640 |  nn              PPPPPPPPPPPPPPPPPP        KKK       |   Q  quay (-128), 2 = OBJ 2 bridge cabin
   -832 |  nn              PPPPbPPPPPPPPPPPPP        KKK       |   ~  canal (wading water), = lift bridge
  -1024 | FFFFFFFFFFFF     PPPPPPPPPPPPPPPPPP CCCCCCCCCCCCCCCC |   C  container terminal (-128), x crane
  -1216 | FFFFFFFFFFFF           eeeeee       CCCCCCCCCCCCCCCC |   B  bay vista (unreachable, static water,
  -1408 | FFFFFFFFFFFF           eeeeee       CCCCCCCCCCCCCCCC |      moored freighter, lighthouse)
  -1600 | FFFFFFFFFFFFQQQQQQQQQQQQQQQQQQQQQ2Q~CCCCCCCCCCCCCCCC |
  -1792 | FFFFFFFFFFFFQQQQQQQQQQQQQQQQQQQQQQQ~CCCCCCCCCCCCCCCC |   blank = solid building blocks (facades
  -1984 | FFFFFFFFFFFFQQQQQQQQQQQQQQQQQQQQQQQ=CCCCCCCCCCxCCCCC |   toward the streets, CLIP-capped roofs)
  -2176 | FFFFFFFFFFFFQQQQQQQQQQQQQQQQQQQQQQQ~CCCCCCCCCCCCCCCC |
  -2368 |             QQQQQQQQQQQQQQQQQQQQQQQ~CCCCCCCCCCCCCCCC |
  -2560 |BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB|
  -3328 |BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB|
  (1 char = 128 u E-W, 1 row = 192 u N-S, north up; generator: zone table below)
```

Hidden helicopter hangar (sealed box, never visible): x[3584,3968] y[2816,3200] z[0,384].

## 4. Zones (interior boxes; walls 16 thick outside these boxes; z = floor .. sky/ceiling)

Global: X east, Y north. City level z 0, harbor level z -128, sky caps listed per zone, map bounds
x[-3472,3472] y[-3472,3216] (inside +-4096). Every outdoor zone: floor, perimeter facade walls up
to the listed **roofline**, sky brushes above the roofline up to the cap; **CLIP from every
roofline / wall top up to the sky cap** (no rooftop walking, no hook/boost escapes into vistas).
Big floors and facades use texture scale 2 (`Map(tex_scale=...)`): half the luxels per axis,
keeps lightmaps small.

| id | zone | box x | box y | z floor..cap | roofline / ceiling | notes |
|---|---|---|---|---|---|---|
| v | No-man's land vista | -3328..-1984 | 2576..3200 | 0..1152 | — | unreachable; seen over the 448 quarantine wall |
| A | Gate 7 checkpoint | -3328..-1984 | 1408..2560 | 0..768 | N wall 448 (quarantine wall), others 448-512 | CT spawn, 1344 x 1152 yard |
| c | Command post | -3072..-2432 | 1040..1392 | 0..176 | ceiling 176 | indoor, doors N + S 128 wide |
| a | Supply alley | -2304..-2048 | 1040..1392 | 0..640 | 320 | dog-leg: N hole x[-2304,-2176], S hole x[-2176,-2048] |
| M1 | Market street W leg | -1920..-1168 | 1792..2240 | 0..704 | 384 N / 448 S | 448 wide street |
| M2 | Market street S leg | -1600..-1216 | 704..1792 | 0..704 | 384-448 | 384 wide, joins M1 (no wall at the seam) |
| m | Market arcade | -1216..-1152 | 736..960 | 0..192 | header 192 | covered passage into the plaza |
| p | Pharmacy | -1904..-1584 | 2256..2480 | 0..160 | ceiling 160 | 2 ways in: door 96 + breakable shop window 128 |
| R | Terminus station | -1088..1088 | 1408..2496 | 0..448 | truss roof 448, 3 skylight strips (sky) | tracks y[2048,2400] sunk to -32, platforms y[1856,2048], concourse y[1408,1856]; ticket block x[-128,128] y[1408,1856] solid to the roof (VIS splitter) |
| f1 | Forecourt W | -768..-384 | 1040..1392 | 0..512 | 256 | N hole x[-768,-576] (into R), S hole x[-576,-384] (into P), both 192 high |
| f2 | Forecourt E | 384..768 | 1040..1392 | 0..512 | 256 | mirror: N hole x[576,768], S hole x[384,576] |
| H | Field hospital yard | 1104..2560 | 1344..2496 | 0..640 | 384-448 | tents, ambulances |
| w | Triage ward | 1856..2544 | 1904..2480 | 0..176 | ceiling 176 | indoor, 2 doors (W 128, S 128) |
| S | Substation yard | -3328..-1984 | -640..1024 | 0..704 | 384-512 | 3 transformer compounds, gantry deck z 160 along x[-2272,-2048] y[-512,480] |
| h | Switch house | -3200..-2752 | 384..896 | 0..176 | ceiling 176 | indoor, doors E + S 128 wide; breaker A |
| L | Lantern lane | seg1 -1968..-1680 / seg2 -1680..-1424 / seg3 -1424..-1168 | y -192..96 / -576..96 / -576..-288 | 0..640 | 320-384 | Z-bend, 256-288 wide |
| P | Liberation Plaza | -1152..1152 | -1152..1024 | 0..1216 | 448-640 (E side = tower facade 576 + crown) | boss arena |
| T0 | Tower lobby | 1168..2160 | -384..832 | 0..176 | ceiling 176 | 2 glass doors from P, riot barricade, 2 stair cores |
| T1 | Tower offices | 1168..2160 | -384..832 | 192..368 | ceiling 368 | windows to P (breakable glass x2), balcony on K side |
| T2 | Tower plant floor | 1168..2160 | -384..832 | 384..560 | ceiling 560 | stair cores only, ducts, machinery |
| T3 | Tower roof deck | 1168..2160 | -384..832 | 576..1536 | parapet 640, sky cap 1536 | evac pad centre (1664, 224), crown block x[1152,1424] y[512,832] up to 1152 |
| t | Tower south passage | 1168..2160 | -560..-400 | 0..512 | 256 | P <-> K flank route, door into the SE stair core |
| K | Kade (harbor road) | 2176..2560 | -1072..1328 | 0..704 | W = tower 640, E 448 | 2 gate arches at y 640 and y -320 (256 x 224 holes); ramp y[-1072,-800] 0 -> -128 |
| n | Stair lane | -3200..-2944 | -1072..-656 | -128..512 | 256 | 8 steps 16/32 down to the fish market |
| F | Fish market hall | -3328..-1792 | -2304..-1088 | -128..256 | ceiling 256 (2 skylights) | indoor, stalls, loft z 0 along the N wall (camp) |
| e | Harbor steps | -384..384 | -1584..-1168 | -128..640 | 320 | split stair around the memorial block x[-128,128] y[-1520,-1232]; P arch header 224, quay arcade header z 64 |
| Q | Quay | -1776..1152 | -2560..-1600 | -128..768 | N 384, S = sea wall top -96 | bridge cabin x[928,1120] y[-1792,-1632] floor 0 (stairs) |
| ~ | Canal | 1168..1328 | -2560..-1600 | -224..768 | banks -128 | water surface -152 (72 deep, waist-high), exit steps both banks inside the bridge gap |
| C | Container terminal | 1344..3328 | -2560..-1088 | -128..896 | 448 | container stacks are WORLD (VIS blockers), gantry crane x[2400,2912] y[-2400,-1600] cab z 256 |
| B | Bay vista | -3456..3456 | -3456..-2576 | -256..1152 | — | unreachable; static water face at -192; freighter hull x[700,2300] y[-2900,-2700] z[-192,128] (world, VIS blocker between Q and C); lighthouse breakwater at x -600 y -3200 |

## 5. Connections (all >= 128 wide; main routes >= 192)

| from -> to | opening (wall, span, z) | width | VIS treatment |
|---|---|---|---|
| A -> M1 "Sally port" | x=-1984..-1920, y[1888,2144], z 0..208 | 256 | concrete overpass header with GATE 7 sign; HINT on both mouths |
| A -> c | c N wall y=1392, x[-2816,-2688] | 128 | indoor room = natural splitter |
| A -> a | A S wall y=1408, x[-2304,-2176], z 0..192 | 128 | dog-leg (S hole offset) |
| c -> S | c S wall y=1040, x[-2816,-2688] | 128 | door (func_door auto) |
| a -> S | S N wall y=1024, x[-2176,-2048], z 0..192 | 128 | dog-leg |
| M1 -> R "station side gate" | x=-1168..-1088, y[1920,2112], z 0..160 | 192 | roller shutter (func_door, opens on touch, wait 4) |
| M2 -> P "market arcade" | m, y[736,960], z 0..192 | 224 | arcade header + columns |
| R -> f1 / f2 -> P | holes listed in zone table, z 0..192 | 192 | dog-legs, HINT at each hole |
| R -> H "breach" | x=1088..1104, y[1984,2368], z 0..256 | 384 (train car 3 lies in the middle: 2 x 128 clear) | rubble edge, header 256 |
| H -> K "checkpoint B arch" | y=1328..1344, x[2240,2496], z 0..256 | 256 | arch header |
| S -> L | x=-1984..-1968, y[-192,96], z 0..224 | 288 | Z-bend |
| L -> P | x=-1168..-1152, y[-560,-304], z 0..208 | 256 | |
| S -> n -> F | S S wall x[-3200,-2944]; F N wall same span | 256 | stair lane with header 224 at both ends |
| P -> T0 | x=1152..1168, y[96,352], two glass doors 128 each | 256 | glass doors are brush ents (rendermode 2) |
| P -> t -> K | P E wall y[-560,-400]; K W wall y[-560,-400], z 0..208 | 160 | 1008-long passage, narrow view slot |
| T0 <-> T1 <-> T2 <-> T3 | 2 stair cores NW x[1184,1312] y[464,816] and SE x[2016,2144] y[-368,-16], switchback 8/16 stairs 128 wide | 128 | floors are sealed slabs (each floor its own VIS cell) |
| K -> T1 -> T3 fire escape | ladder 1 K floor -> balcony x[2176,2272] y[0,192] z 192 (door 96 into T1); ladder 2 balcony -> parapet hatch (hole in T3 E parapet y[32,96] z 576..704) | 64 | zombie route, ladders |
| P -> e | P S wall y=-1152, x[-384,384], z 0..224 | 768 (2 x 256 flights) | arch header 224 + memorial block centre |
| e -> Q | Q N wall y=-1600, x[-384,384], z -128..64 | 768 | customs arcade header z 64 (different height from the P arch: no straight sight line P -> bay) |
| F -> Q "net alley" | x=-1792..-1776, y[-2240,-1984], z -128..96 | 256 | roller shutter (func_door, opens on touch) |
| Q -> ~ -> C bridge gap | Q E wall x=1152 and C W wall x=1344, y[-2240,-1856], z -128..384 | 384 | lift bridge spans x[1152,1344] y[-2176,-1920]; container stack 64 behind the C mouth blocks the terminal interior |
| K -> C | C N wall y=-1088, x[2176,2560], z -128..256 | 384 | ramp + header |

Routes: every zone has >= 2 exits except the indoor side rooms (pharmacy 2, ward 2, switch house 2,
command post 2). Loops: A-c/a-S-L-P-M2-M1-A (west loop), P-f1-R-f2-P (station loop), P-T-K-t-P
(tower loop), P-e-Q-~-C-K-t-P (harbor loop), S-n-F-Q-e-P (south-west loop). Zombie-favoured
shortcuts: duck-jump crates (48) into the pharmacy window, canal wading, fire-escape ladders,
container stack hops (2-high stacks with a 48 crate step) to the crane deck.

## 6. Camps (human), each reachable on foot, each with a weakness

| camp | where | entries | weakness |
|---|---|---|---|
| C1 Tower roof / evac pad (final stand) | T3, 992 x 1216 deck | 2 stair cores (128) + fire-escape hatch | 3 entries far apart; hatch ladder comes up behind the pad |
| C2 Train roof | derailed car 2 roof z 128 (station) | ladder + duck-jump from crate to car 1 roof | 360 deg open, zombies climb from both cars |
| C3 Substation gantry | z 160 deck, 224 wide | stairs N end (10 x 16) + ladder S end | long deck, two ends |
| C4 Crane deck | terminal crane z 256 platform 256 x 192 | crane leg ladder + container hop route | ladder + hop route on the opposite side |
| C5 Fish market loft | z 0 loft along F north wall, 1536 x 192 | 2 stairs (8 steps) + stair lane door | long and thin, flanked from both stairs |
| C6 Command post | indoor 640 x 352 | 2 doors | small, good for 4-6 players only |

## 7. Spawns and boss arena

* **CT 32** (`info_player_start`): Gate 7 yard, `spawn_grid('ct', (-3136, 1600), (-2632, 1816), 0, 32,
  spacing=72, yaw=0)`; tents/barriers stay outside x[-3200,-2560] y[1536,1880]. Facing east, the
  sally port and the green EVAC arrow straight ahead.
* **T 32** (`info_player_deathmatch`): station east concourse, `spawn_grid('t', (288, 1488), (792,
  1704), 0, 32, spacing=72, yaw=90)` facing the wrecked train. Keep 80 from the forecourt-E hole.
* Both sets on flat floor z 0, >= 40 from walls, none in doors/breakables/water; `Map.spawn_problems()`
  empty before compiling, bspcheck spawn test 32/32 + 32/32 after.
* **Boss arena = Liberation Plaza** (2304 x 2176, sky 1216): 7 entries (arcade, lane, 2 forecourts,
  lobby, south passage, harbor steps) so nobody is cornered and the boss cannot be blocked in one
  choke. Cover: monument plinth (r 160, h 96) + dry fountain ring (r 352, rim 32), bus wreck (NE),
  burning car (SW), abandoned sandbag emplacement (E, h 40 = hop-over), billboard after it falls
  (SW). No raised camp inside the plaza (bosses must be fought, not cheesed).

## 8. Brush entities (44 / 60 budget; every one local, < 200 faces)

All doors `movesnd 2` (doors/doormove2.wav) `stopsnd 0`, `dmg 0`, `lip 2`; auto doors `wait 4`,
touch-opened (no targetname), never lockable. All breakables `material 0` (glass) -> the only extra
stock sounds are debris/bustglass1-2. Glass: `rendermode 2 renderamt 90`. Masked `{` fences/rails:
`func_wall rendermode 4 renderamt 255`, one per area. `_minlight 0.2` on moving entities.

| # | targetname / name | class | zone | key settings | faces |
|---|---|---|---|---|---|
| 1 | cd_gate7 | func_door up 400 | A | speed 60, wait -1, opens on `vex_win_humans` | 30 |
| 2 | cd_barrier_up | func_door_rotating | A | arm 448 long, 80 deg, speed 60, wait -1, movesnd 0, ORIGIN at hinge | 12 |
| 3 | — booth window | func_breakable | A | health 60 | 6 |
| 4 | — wire + fences | func_wall rm4 | A | razor wire on the quarantine wall, yard fences | 60 |
| 5 | — CP south door | func_door +x | c | auto | 6 |
| 6 | cd_brk_a | func_button | h | lever, wait -1, sounds 11, target cd_brk_a_mm, speed 40, lip 8, angles = down | 14 |
| 7 | cd_brk_b | func_button | S gantry | same, target cd_brk_b_mm | 14 |
| 8 | — gantry ladder | func_ladder | S | z 0..164 | — |
| 9 | — compound fences | func_wall rm4 | S | 3 transformer cages | 70 |
| 10 | — switch house door | func_door | h | auto | 6 |
| 11 | — pharmacy window | func_breakable | p | health 80 | 6 |
| 12 | cd_shutter_st | func_door up | M1/R | roller shutter, auto (touch), wait 4 | 6 |
| 13 | — market grates | func_wall rm4 | M | shop grates, balcony rail | 40 |
| 14 | cd_train_door | func_door_rotating | R | carriage end door, 100 deg, speed 600, wait -1, movesnd 0 | 12 |
| 15 | — train roof ladder | func_ladder | R | 0..132 | — |
| 16 | — ticket window | func_breakable | R | health 60 | 6 |
| 17 | — platform rails | func_wall rm4 | R | | 40 |
| 18 | — ward door | func_door | w | auto | 6 |
| 19 | — ward glass | func_breakable | w | health 60 | 6 |
| 20 | — hospital fences | func_wall rm4 | H | | 40 |
| 21 | cd_billboard | func_door_rotating | P | 512 x 256 sign on 2 legs, falls 85 deg south into the planter (CLIP-filled bed x[-960,-320] y[-1136,-976]), speed 140, wait -1, movesnd 0 | 30 |
| 22 | — bus shelter glass | func_breakable | P | health 40 | 6 |
| 23 | — fountain rails | func_wall rm4 | P | | 32 |
| 24 | — lobby door W | func_door -y | T0 | glass rm2, auto | 6 |
| 25 | — lobby door E | func_door +y | T0 | glass rm2, auto | 6 |
| 26 | cd_barricade | func_breakable | T0 | plexiglass riot panels across the NW stair-core corridor, health 1500, target cd_barricade_mm | 30 |
| 27 | — office glass W | func_breakable | T1 | window to plaza, health 80 | 6 |
| 28 | — office glass E | func_breakable | T1 | window to plaza, health 80 | 6 |
| 29 | — fire escape ladder 1 | func_ladder | K | 0..196 | — |
| 30 | — fire escape ladder 2 | func_ladder | K | 192..580 | — |
| 31 | cd_beacon_btn | func_button | T3 | master cd_ms_bridge, wait -1, sounds 11, locked_sound 14, target cd_beacon_mm | 14 |
| 32 | cd_heli (body) | func_train | hangar | path cd_hp0..cd_hp4, speed 260, movesnd 0, stopsnd 0, _minlight 0.35 | 80 |
| 33 | cd_heli (rotor) | func_train rm5 amt 160 | hangar | own path cd_rp0..cd_rp4 = body path + (body bbox centre - rotor bbox centre); same speed | 4 |
| 34 | — roof rails | func_wall rm4 | T3 | parapet rails | 30 |
| 35 | — balcony rails | func_wall rm4 | K | | 16 |
| 36 | cd_bridge | func_door down 384 | ~ | deck x[1152,1344] y[-2176,-1920] z[240,256] (raised), speed 48 (8 s), wait -1 | 30 |
| 37 | cd_bridge_btn | func_button | Q cabin | master cd_ms_power, wait -1, sounds 11, locked_sound 14, target cd_bridge_mm | 14 |
| 38 | — cabin glass | func_breakable | Q | health 60 | 6 |
| 39 | — quay + canal rails | func_wall rm4 | Q/~ | sea wall rail + canal edge | 60 |
| 40 | cd_fish_shutter | func_door up | F/Q | roller shutter, auto, wait 4 | 6 |
| 41 | — crane ladder | func_ladder | C | -128..260 | — |
| 42 | — crane cab rails | func_wall rm4 | C | | 20 |
| 43 | cd_lighthouse_beam | func_rotating rm5 amt 50 | B | 2 light cones, speed 30, start on, no sound | 10 |
| 44 | — SE stair door | func_door | t/T0 | auto | 6 |

Expected precache impact: models +44 brush + glassgibs.mdl (glow01.spr and vexmira/fire.spr are
already precached by the plugin); **new sounds 9 / 10**: doors/doormove2, debris/bustglass1,
debris/bustglass2 + 6 custom (section 13). Plugin today: sounds ~442, models ~304 -> 451 / 350 of
512. Total entities target ~380 (< 600).

## 9. Interactive set pieces (entity chains)

Conventions: `mm` = multi_manager (keys `target delay`, duplicate targets use `name#2`);
`r_on` / `r_off` = trigger_relay with `triggerstate 1` / `0` (explicit state, so re-firing is
harmless); sprites and multisources are toggled. ReGameDLL `CleanUpMap` restarts lights, doors,
buttons, breakables, trains, multi_managers, multisources, sprites, ambient_generics, beams and
triggers every round (checked in ReGameDLL `multiplay_gamerules.cpp`), and `vex_round_start`
additionally forces every switchable state, so each set piece works every round.
"gated relay" = `game_counter` (frags 0, health 1, spawnflags 2 reset-on-fire, `master` = a
multisource) that fires its `target` only while the master is on.

**SP1 Power (OBJ 1, Substation)**
* `cd_brk_a` (button, switch house N wall, (-2976, 880, 64)) -> `cd_brk_a_mm`: `cd_ms_power 0`,
  `cd_brk_a_red 0` (sprite off), `cd_brk_a_grn 0` (sprite on).
* `cd_brk_b` (button, gantry S end, (-2160, -470, 210)) -> `cd_brk_b_mm`: same with `_b_`.
* `cd_ms_power` (multisource, sources = the two mms) target `cd_power_mm`:
  `cd_r_hum_on 0` (ambient `cd_hum` x2), `cd_r_west_on 0.6`, `cd_r_plaza_on 1.4`, `cd_r_east_on 2.2`,
  `cd_cab_red 2.2`, `cd_cab_grn 2.2`, `vexcmd_obj_1_done 2.5`, `vexcmd_reward_h_5 2.5`, `vexcmd_msg_power 2.5`.
* Feedback: lever drops with button11 clunk, panel sprite red -> green, transformer arc sprite pulses,
  hum fades in, lights switch on in three steps across the map.

**SP2 Lift bridge (OBJ 2, Quay)**
* `cd_bridge_btn` (cabin console (1104, -1712, 40), locked until power: click sound 14, cabin
  sprite red) -> `cd_bridge_mm`: `cd_bridge_spr 0` (2 yellow strobe sprites on the bridge towers),
  `cd_bridge 0.5` (deck lowers 8 s with doormove2), `cd_bridge_spr#2 9` (off), `cd_r_harbor_on 8.5`,
  `cd_ms_bridge 8.5`, `vexcmd_obj_2_done 8.5`, `vexcmd_reward_h_8 8.5`, `vexcmd_msg_bridge 8.5`,
  `cd_pad_red 8.5`, `cd_pad_amb 8.5` (roof console sprite red -> amber).
* `cd_ms_bridge` (multisource, source `cd_bridge_mm`) — master of the beacon button.

**SP3 Evac beacon + medevac helicopter (OBJ 3, Tower roof)**
* `cd_beacon_btn` (console at the pad edge (1664, -96, 616)) -> `cd_beacon_mm`: `cd_r_pad_on 0`
  (pad lights), `cd_pad_amb#2 0` (off), `cd_pad_grn 0` (2 green strobe sprites), `vexcmd_obj_3_done 0.5`,
  `vexcmd_msg_beacon 0.5`, `cd_r_rotor_on 10` (rotor loop, large radius), `cd_heli 14`, `cd_heli_drop_mm 25`.
* Path (body; rotor path offset): `cd_hp0` hangar (3776, 3008, 192) flags 3 (wait-for-retrigger +
  teleport) -> `cd_hp1` (2100, 780, 1400) flag 2 teleport -> `cd_hp2` (1760, 300, 1050) -> `cd_hp3`
  hover (1664, 224, 860) flag 1 (wait) -> `cd_hp4` (1400, -300, 1450) -> back to `cd_hp0`.
  Hover keeps the body bottom >= 200 above the deck (nobody can touch or be crushed). Two lights
  in the hangar match the roof light so the body is not black.
* `cd_heli_drop_mm`: `vexcmd_reward_h_15 0`, `vexcmd_msg_heli 0`, `cd_shake_roof 0` (env_shake
  r 600 amp 4 dur 2 = rotor wash), `cd_ms_heli 0` (multisource "heli is here").
* Departure: ini `win_humans 3 cd_heli_go` -> gated relay (master `cd_ms_heli`) -> `cd_heli_depart_mm`:
  `cd_heli 0` (hover -> cd_hp4 -> hangar), `cd_r_rotor_off 9`. If the heli was never called nothing happens.

**SP4 Train breach (`vex_infection`, Station)** — entity `vex_infection` = mm:
`cd_train_door 0`, `cd_breach_fx 0` (env_explosion spawnflags 1 no damage, magnitude 60, at the door),
`cd_shake_st 0` (env_shake r 1600 amp 10 freq 40 dur 1.5), `cd_boom_st 0`, `cd_r_alarm_on 0.3`
(switchable red strobe, pattern "aaaazzzz", <= 40 lit faces), `cd_alarm_spr 0.3` (2 red sprites on),
`cd_r_siren_st_on 1`, `vexcmd_msg_breach 1.5`. Ini: `infection 30 cd_r_siren_st_off`.

**SP5 Boss arrival (`vex_boss`, Plaza)** — entity `vex_boss` = mm: `cd_r_plaza_off 0`,
`cd_r_plazared_on 0`, `cd_r_siren_pz_on 0`, `cd_shake_pz 0`, `cd_boom_pz 0`, `vexcmd_msg_boss 1`.
Ini `boss 4 cd_billboard_mm`: `cd_billboard 0`, `cd_boom_pz 0.7`, `cd_shake_pz 0.7`,
`cd_billboard_fx 0.7` (env_explosion no damage). `vex_boss_dead` = mm: `cd_r_plazared_off 0`,
`cd_r_siren_pz_off 0`, `cd_plaza_gate 0.5` (gated relay, master `cd_ms_power`, target `cd_r_plaza_on`).

**SP6 Shelling (`vex_minute`)** — entity `vex_minute` = mm: `cd_boom_far 0` (everywhere, vol 5),
`cd_r_flash_on 0.35`, `cd_shake_far 0.4` (env_shake spawnflags 1 global, amp 3, dur 1.2),
`cd_r_flash_off 0.7`. `cd_lt_flash` = switchable white-orange light group out in the vista `v`
(lights only vista faces + the top of the quarantine wall). Escalation: the same mm also fires
`cd_boom_far#2 6` and `cd_shake_far#2 6.1` (a second, closer impact 6 s later), so every minute
brings two hits.

**SP7 Riot barricade (zombie goal, Tower lobby)** — `cd_barricade` breaks -> `cd_barricade_mm`:
`vexcmd_reward_z_5 0`, `vexcmd_msg_barricade 0`. The SE stair core stays open, so the barricade
never seals the tower.

**SP8 Gate 7** — `vex_freeze_end` is not used by the map; ini `freeze_end 1 cd_barrier_up` swings
the arm up. `vex_win_humans` = mm: `cd_gate7 0`, `cd_r_flood_out_on 0` (floods in the vista
behind the gate). Restart closes both.

**SP9 Blackout / last human / zombie win**
* `vex_nemesis` and `vex_assassin` = trigger_relays -> `cd_blackout_mm`: `cd_r_hum_off 0`,
  `cd_r_west_off 0`, `cd_r_plaza_off 0.3`, `cd_r_east_off 0.6`, `cd_r_harbor_off 0.9`,
  `cd_boom_far 0`, `vexcmd_msg_blackout 1`.
* `vex_lasthuman` = mm: `cd_blackout_mm 0`, `cd_r_siren_all_on 1`, `cd_r_plazared_on 1`.
* `vex_win_zombies` = mm: `cd_blackout_mm 0`, `cd_r_alarm_on 0`, `cd_r_plazared_on 0`, `cd_r_siren_all_on 0`.
* `vex_survivor`, `vex_freeze_end`: no map reaction (plugin effects only).

**Round reset** — entity `vex_round_start` = mm (all at 0): `cd_r_west_off`, `cd_r_plaza_off`,
`cd_r_plazared_off`, `cd_r_east_off`, `cd_r_harbor_off`, `cd_r_pad_off`, `cd_r_alarm_off`,
`cd_r_flash_off`, `cd_r_flood_out_off`, `cd_r_hum_off`, `cd_r_siren_st_off`, `cd_r_siren_pz_off`,
`cd_r_siren_all_off`, `cd_r_rotor_off`. Physical state (doors, bridge, billboard, train door,
buttons, multisources, heli, barricade, sprites) is restored by ReGameDLL; stage 3 verifies it.

Switchable light groups (targetnamed `light`/`light_spot`, styles 32+; no patterns except the alarm):

| group | start | lights | max overlap rule |
|---|---|---|---|
| cd_lt_west | off | sodium lamps S, L, M1, M2, c, a | |
| cd_lt_plaza | off | 6 plaza floods (white) | plaza faces: plaza + plazared + west/east only at the mouths (<= 3 styles per face, RAD limit 4 incl. style 0) |
| cd_lt_plazared | off | 6 red floods next to the white ones | |
| cd_lt_east | off | T0-T2 ceiling panels, K, H, t lamps | |
| cd_lt_harbor | off | Q, ~, C, e, F sodium + bridge towers | |
| cd_lt_pad | off | 4 pad lamps T3 | |
| cd_lt_alarm | off | 4 station red strobes (pattern) | <= 40 lit faces |
| cd_lt_flash | off | 3 lights in vista v | |
| cd_lt_flood_out | off | 2 floods in v behind the gate | |
Static (style 0, always on): moon `light_environment`, Gate 7 generator floods, red emergency
lamps (stairwells, c, F, R), fires, neon/texlights, lighthouse, screens. Animated styles: only the
lantern-lane lamp (style 10, brightness 60, <= 20 faces) and the alarm group.

## 10. Guidance plan

* **Always-lit green EVAC arrows** (`~vx_arrow`, 64 x 64 texlight on small func_detail plates at
  z 96, oriented with the face texture rotation): from the CT spawn (sally port + alley), from the
  T spawn (both forecourts), at every junction on the loop S -> L/n -> Q -> bridge -> C -> K -> tower,
  ending at the tower stair cores (30-40 arrows, 1 face each).
* **District signs** (`vx_signs` atlas 128 x 128 = four 128 x 32 plates "SUBSTATION / TRAFO",
  "HARBOR / LIMAN", "CUSTOMS TOWER / GUMRUK KULESI", "EVAC PAD / TAHLIYE", each with an arrow;
  a face shows one row via the v-shift): 2-3 per junction, under a lamp.
* **Colour leads per objective**: Substation = electric cyan (transformer arc sprite + cyan panel
  light), Bridge = yellow strobes on the two towers, Pad = green. Each objective's site glows red
  while locked, amber when available, green when done (sprites in SP1-3).
* **Landmarks**: Customs Tower crown with the VEXMIRA neon (`~vx_neon_vex`) and a red aircraft strobe,
  facing the plaza (seen from P and every plaza mouth); the station's skylight truss roof; the lift
  bridge towers; the gantry crane; the lighthouse beam sweeping over the bay; the burning freighter.
* **Plugin markers** for the open objective (ini `[markers]`).
* No dead ends: every side room has 2 exits; every street bend shows the next sign before the bend.

## 11. Atmosphere and texture/ambience fit per zone

| zone | textures (story) | light (style 0 / switchable) | sound layers | escalation |
|---|---|---|---|---|
| A Gate 7 | `vx_quar_wall` stencilled "QUARANTINE / KARANTINA - CORDON 7" with bullet scars, `vx_bunker` jersey blocks, `vx_tarp` tents, `vx_crate_mil`, wet `vx_conc_crack`, `{vx_scorch` under burnt barricade | hard white generator floods (static) + cold moon; red beacon on the booth | wind loop, distant sirens inside it, generator hum (cd_hum low pitch 70) | minute flashes over the wall, booms; win: gate opens |
| c / a | `vx_plaster` stained, maps (`~vx_screen3` radar on desk), sandbags | dim red emergency + 1 desk lamp | wind muffled (pitch 85) | |
| M Market | `vx_facade` (dark broken windows, grime streaks), `vx_shopfront` shutters, `vx_asphalt` wet, `{vx_blood1` drag marks into the pharmacy | sodium off until power; burning car orange (static) | wind | lights come on (power) |
| R Station | `vx_tile_dirty`, `vx_metal_rust` train cars, `vx_metal_dark` trusses, `{vx_blood1` + `{vx_scorch` around the breach, `~vx_light_r` emergency | cold skylight moon shafts + red emergency; alarm strobes after infection | wind through roof (pitch 80), siren after infection | breach |
| H Hospital | `vx_tarp` with red-cross, `vx_plaster` ward, blood trails, overturned beds (detail) | one flickering-free red-cross lamp (sprite) + moon | wind | |
| S Substation | `vx_conc_stain`, `vx_metal_corr` switch house, `vx_trim_hazard`, `{vx_fence` cages, `vx_signs` plates | cyan arc sprite + moon; sodium after power | wind + hum after power | power, blackout |
| L Lane | `vx_brick_dark`, wet `vx_asphalt` | one flickering lamp (style 10) - the only "horror" flicker | wind | |
| P Plaza | `vx_facade`, `vx_conc_crack`, monument `vx_conc_stain`, bus/car `vx_metal_rust`, `{vx_scorch` | moon + burning car; white floods after power; red floods at boss | wind, siren at boss | boss, billboard |
| T Tower | `vx_plaster` offices, `vx_tile_dirty` lobby, `vx_metal_corr` plant, `vx_metal_dark` roof, `vx_trim_hazard` pad ring | red emergency in stairs (static), ceiling panels after power, pad lamps after beacon | hum after power, rotor | heli |
| K Kade | `vx_brick_dark` warehouses, `vx_conc_stain` arches, wet `vx_asphalt` | sodium after power, moon | harbor + wind | |
| F Fish market | `vx_tile_dirty`, `vx_metal_rust` stalls, nets (`{vx_fence`), blood on tiles | dim red + moon through skylights | harbor muffled (pitch 85) | |
| Q / ~ / C / B | `vx_conc_stain` quay, `!vx_water_dk` canal, `vx_cont_red`/`vx_cont_blue`, `vx_metal_rust` crane/bridge, `vx_bay` static sea | moon + lighthouse; sodium after OBJ 2 | harbor loop (water, ropes, foghorn) + wind | bridge strobes, freighter fire |

Rules: dark but readable (no black zone: style-0 light everywhere >= the level of the lab's dim
corridors on the eye previews); warm vs cold contrast (sodium/fire vs moon/cyan); fog-free.

**Texture set (32 visual + tool textures):**
existing (23): `vx_asphalt vx_conc_crack vx_conc_stain vx_bunker vx_brick_dark vx_plaster
vx_tile_dirty vx_metal_rust vx_metal_corr vx_metal_dark vx_trim_hazard vx_cont_red vx_cont_blue
vx_crate_mil {vx_fence {vx_rail {vx_blood1 vx_glass ~vx_light_w ~vx_light_r ~vx_light_y
~vx_neon_vex !vx_water_dk` (+ `~vx_screen3` only if the count stays <= 33).
new, generated in `textures.py` with noise/wear/grime/edge variation (9): `vx_facade` (256, 2x2
window bays, broken/boarded/dark panes, rain streaks), `vx_shopfront` (256x128 shutter + sign band),
`vx_quar_wall` (256x128 stencil + stripes + bullet scars), `~vx_arrow` (64, green EVAC arrow,
texlight 120,255,140 / 150), `vx_signs` (128 atlas, see 10), `{vx_scorch` (128 burn decal),
`vx_tarp` (128 olive canvas, red-cross variant region), `vx_bay` (256 static night water with
light glints, no `!`), `vx_heli` (128: olive hull with rivets + "CORDON-7 MEDEVAC" in the upper
96 rows, rotor blur strip in the lower 32 rows, used via v-shift by the rotor).
Decals with intent: blood only along the outbreak story (train breach -> station -> forecourts,
hospital, fish market); scorch at shell impacts, burning wrecks and the breach; stencils only on
military surfaces.

## 12. VIS / FPS plan

Hard gates (bspcheck, final compile): view wpoly **max < 1300, p95 < 900**; target p95 <= 700 in
fight areas (P, R, T3, S, Q). PVS per leaf (360 deg) max <= 1900.

Per-zone budgets (drawable world + func_detail faces, sky excluded) and view targets:

| zone | faces | view max target | may see (PVS) | must NOT see |
|---|---|---|---|---|
| v vista | 120 | — | A | anything else |
| A Gate 7 | 550 | 700 | v, mouth of M1, a, c | R, P, S |
| c + a | 160 + 100 | 450 | A slice, S slice | M, P |
| M1 + M2 + m + p | 600 + 80 | 700 | A slice, R shutter slice, P via arcade | S, L, f |
| R station | 850 (train 200, trusses 150) | 850 | M1 slice, f1/f2, H via breach | P interior beyond the forecourt slices, A |
| f1, f2 | 90 each | 600 | R, P slices | |
| H + w | 450 + 120 | 650 | R slice, K north cell | T, P |
| S + h | 600 + 120 | 750 | c/a, L seg1, n | P, M, F |
| L | 260 | 550 | S slice, P slice | M, R |
| P plaza | 700 (incl. tower W facade + crown 80) | 900 (p95 750) | all 7 mouths, crown | Q/B (two offset headers), R hall, T floors |
| T0 / T1 / T2 / T3 | 200 / 240 / 120 / 280 | 700 | own floor, P through doors/windows, K through hatch | other floors (slabs) |
| t | 60 | 500 | P, K slices | |
| K | 420 | 650 | H, t, C slices, tower E facade | P, Q |
| n + F | 60 + 480 | 650 | S, Q slices | P, C |
| e steps | 160 | 750 | P, Q slices | B (low arcade) |
| Q + ~ + bridge | 520 + 60 + 120 | 850 | e, F, B, bridge gap slice of C | P, K |
| C terminal | 650 | 850 | K, B, gap slice of Q | P, T |
| B bay | 160 (+ freighter 60) | — | | |
| total | ~8,200 | | | |

Techniques (mandatory): sealed sky-capped cells; low headers on every opening (<= 256) with
bends/offsets; container stacks, ticket block, memorial block, freighter hull and floor slabs as
WORLD brushes (VIS blockers); everything small (cars, crates, trusses, stalls, lamps, rails' posts,
pipes, beds, tents) as `func_detail` with NULL on hidden faces; HINT brushes at every mouth listed
in section 5; facades are flat walls with `vx_facade` + at most one func_detail band (sill/cornice)
per facade face, no modelled pilasters/windows; big floors as few large faces; no water except the
canal (`!vx_water_dk` 160 x 960 -> ~45 polys) — the bay uses static `vx_bay`; brush entities local
(section 8); sprites 22 (<= 24); animated styled faces < 64; sky stock `night`.
Size targets: lightmaps <= 1.6 MB (texture scale 2 on floors/facades, switchable lights with short
`_fade`/low brightness so their style only touches nearby faces), bsp <= 4.0 MB, textures <= 1.3 MB.

`--at` checkpoints (eye z = floor + 54): A (-2900, 1700, 54) | M1 (-1600, 2016, 54) | R (0, 1950, 54) |
R T-spawn (540, 1600, 54) | S (-2600, 200, 54) | gantry (-2160, 0, 214) | P centre (0, -64, 54) |
P NW (-1000, 900, 54) | T3 pad (1664, 224, 630) | K (2368, 100, 54) | F (-2560, -1700, -74) |
e (0, -1300, -20) | Q (0, -2100, -74) | C (2600, -1900, -74) | crane (2650, -2000, 310).

## 13. Sounds (6 custom + 3 stock = 9 / 10 new)

All mono 16-bit, `cstrike/sound/vexmira/map/`, loops written with the cue chunk (reuse the writer
of `zm_vex_laboratory.make_ambient`; every periodic component an integer number of cycles; seamless
crossfade), one-shots via `sfx_lib.write_wav3` (no cue). Synthesised in the map module with
`devtools/sfx/sfx_lib.py`, fixed seeds.

| file | type | length / rate | content | used by |
|---|---|---|---|---|
| cd_wind.wav | loop | 6 s / 22050 | low gusting wind (lp noise, slow swell), a very distant air-raid wail under it, one far metal clank | ambients A, P, S, R (pitch 80), c (pitch 85), H |
| cd_harbor.wav | loop | 6 s / 22050 | water lapping on concrete (bp noise bursts), rope/mooring creak, one distant foghorn (2 harmonics) | Q, C, K, F (pitch 85) |
| cd_hum.wav | loop | 3 s / 11025 | 50 Hz transformer hum + 100/150 Hz + faint 2.4 kHz buzz | cd_hum x2 (S, T), Gate 7 generator (pitch 70, always on) |
| cd_siren.wav | loop | 4 s / 22050 | air-raid siren, one rise+fall cycle, mild distortion + reverb | cd_siren_st, cd_siren_pz, cd_siren_all |
| cd_rotor.wav | loop | 1.6 s / 22050 | helicopter: 5 Hz blade slap (8 per loop), turbine whine 1.2 kHz, wash noise | cd_rotor (T3) |
| cd_boom.wav | one-shot | 3 s / 22050 | distant heavy impact: 90 -> 30 Hz boom, crack, debris rattle, long tail | cd_boom_st, cd_boom_pz, cd_boom_far |

Stock (counted): doors/doormove2.wav, debris/bustglass1.wav, debris/bustglass2.wav. Buttons use
base sounds (button11 / lightswitch2). ambient_generic entities: 17 (11 loops, 3 one-shots, 3 sirens
start silent).

## 14. Sprites (22 env_sprite, <= 24)

`sprites/glow01.spr` (additive; already precached by the plugin): breaker red/green x4, cabin
red/green x2, bridge tower yellow strobe x2 (renderfx 4 strobe slow), pad green strobe x2 + pad
amber/red x1 (shared), tower crown red aircraft light (renderfx 4), station alarm red x2, Gate 7
flood glows x2, lighthouse lamp, substation arc cyan (renderfx 2 pulse slow), hospital red cross,
lantern lamp. `sprites/vexmira/fire.spr` (8 frames, framerate 10, scale 1.5; precached by the
plugin): burning car (P), burning freighter (B), artillery fire in the vista (v). Blinking is done
with sprite renderfx, never with animated light styles. env_beam x3 (sprites/laserbeam.spr, base):
static searchlights from the vista towers into the sky above Gate 7.

## 15. Scenario file `cstrike/addons/amxmodx/configs/vexmira_maps/zm_vex_cordon.ini` (complete)

```ini
; zm_vex_cordon - Kordon 7 senaryo dosyasi (latin-1, Turkce harfsiz)
[info]
name_en = Cordon 7 - Vexmira Harbor Quarantine
name_tr = Kordon 7 - Vexmira Liman Karantinasi

[story_en]
line = Night 3 of the outbreak. The Vexmira strain rode the last evacuation train into the harbor district.
line = The army sealed Cordon 7 and welded Gate 7 shut. Nobody walks out.
line = The only way out is by air: a medevac helicopter, if it can find the Customs Tower roof.
line = Restore power at the Substation, lower the lift bridge, light the evac beacon.
line = The infected are already in the station. Every minute the shelling comes closer.
line = Stay together. Stay in the light.

[story_tr]
line = Salginin 3. gecesi. Vexmira virusu son tahliye treniyle liman bolgesine ulasti.
line = Ordu Kordon 7'yi muhurledi ve Kapi 7'yi kaynakla kapatti. Kimse yuruyerek cikamaz.
line = Tek cikis hava yolu: Gumruk Kulesi'nin catisini bulabilirse bir tahliye helikopteri.
line = Trafo merkezinde elektrigi ver, kaldirma koprusunu indir, tahliye isaretini yak.
line = Enfekteliler zaten istasyonda. Bombardiman her dakika yaklasiyor.
line = Birlikte kalin. Isikta kalin.

[objective_en]
line = Restore power: throw BOTH breakers at the Substation (switch house + gantry)
line = Lower the lift bridge from the harbor control cabin
line = Light the evac beacon on the Customs Tower roof

[objective_tr]
line = Elektrigi ver: Trafo Merkezindeki IKI salteri da indir (salt binasi + iskele)
line = Liman kontrol kabininden kaldirma koprusunu indir
line = Gumruk Kulesi catisindaki tahliye isaretini yak

[messages]
power = District power restored! Street lights are on, the lift bridge has power. | Bolge elektrigi geldi! Sokak lambalari yandi, kopru calisiyor.
bridge = Lift bridge lowered - the harbor road to the terminal is open! | Kaldirma koprusu indi - terminale giden liman yolu acik!
beacon = Evac beacon lit! Medevac inbound - hold the tower roof! | Tahliye isareti yandi! Helikopter geliyor - kule catisini tutun!
heli = Medevac on station - supplies dropped on the roof! | Helikopter geldi - catiya ikmal birakildi!
breach = The evacuation train burst open - the infected are loose in the station! | Tahliye treni patladi - enfekteliler istasyonda serbest!
boss = Something huge is crossing Liberation Plaza... | Kurtulus Meydanindan devasa bir sey geciyor...
barricade = The infected smashed the tower barricade! | Enfekteliler kule barikatini parcaladi!
blackout = Power failure! Emergency lights only. | Elektrik kesildi! Sadece acil durum isiklari.

[events]
freeze_end 1 cd_barrier_up
infection 30 cd_r_siren_st_off
boss 4 cd_billboard_mm
win_humans 3 cd_heli_go

[markers]
Substation breakers | Trafo salterleri = -2600 400 64
Lift bridge cabin | Kopru kabini = 1024 -1712 32
Evac beacon | Tahliye isareti = 1664 224 640
```

vexcmd relays the map contains (all `trigger_relay`): `vexcmd_msg_power`, `vexcmd_msg_bridge`,
`vexcmd_msg_beacon`, `vexcmd_msg_heli`, `vexcmd_msg_breach`, `vexcmd_msg_boss`,
`vexcmd_msg_barricade`, `vexcmd_msg_blackout`, `vexcmd_reward_h_5`, `vexcmd_reward_h_8`,
`vexcmd_reward_h_15`, `vexcmd_reward_z_5`, `vexcmd_obj_1_done`, `vexcmd_obj_2_done`,
`vexcmd_obj_3_done`. vex_* entities: `vex_round_start`, `vex_infection`, `vex_boss`,
`vex_boss_dead`, `vex_minute`, `vex_nemesis`, `vex_assassin`, `vex_lasthuman`, `vex_win_humans`,
`vex_win_zombies` (the ini events cover freeze_end / delayed beats).
`vexmira.cfg`: `vex_map_pool` starts with `zm_vex_cordon`, followed only by maps that exist in
`cstrike/maps` (today `zm_vex_laboratory`).

## 16. Build plan (module `devtools/mapkit/maps/zm_vex_cordon.py`, pattern of zm_vex_laboratory.py)

Module layout: `ZONES` table (section 4) + `CONNECTIONS` (section 5) drive `shell()/zone()`
helpers (port `zone()` from the calibration prototype: sealed box, per-side roofline, sky above,
holes, CLIP caps); one function per district (`build_gate7`, `build_market`, ...); `entities_*`
per set piece; `make_sounds()`; `main(--quality, --preview, --sounds)`. Output
`cstrike/maps/zm_vex_cordon.bsp` + `.res`.

**Stage 1 — blockout + VIS + spawns**
* All zones/connections/levels exactly as sections 4-5, world blockers (ticket block, memorial,
  container stacks, slabs, freighter), stairs/ramps/ladders, CLIP caps, HINTs, sky caps; 64 spawns;
  placeholder brush entities with planned face counts (44); moon `light_environment` + rough fills;
  detail density MOCK per zone at 100 % of the section-12 face budgets (boxes of the right count).
* Accept: compile `final` VIS, no leak; `spawn_problems()` empty, bspcheck spawns 32 + 32 pass;
  **view max <= 1100, p95 <= 750** with the mock density (else move walls/headers, not detail);
  each `--at` checkpoint within its zone target; "may / must not see" table checked with `--at`
  (PVS leaves); brush ents <= 50; previews `_top` / `_oblique` read with the Read tool: no
  unreachable camp, routes >= 128, no choke < 128 on a main route. Commit.

**Stage 2 — detail + textures + lighting + atmosphere + sounds**
* 9 new textures in `textures.py` (look at `--sheet` next to existing ones; realistic wear/grime,
  correct scale, no mirrored text), all zone detail replacing the mock (budgets), decals with
  intent, signs/arrows, all lights and switchable groups, sprites, beams, ambients, the 6 sounds
  (listen-check by spectrum/peak stats: no clipping, loops seamless at the cue), hangar lighting.
* Accept: view max < 1300 (aim <= 1150), p95 <= 850, fight areas p95 <= 700 (`--at`); animated
  styled faces < 64; sprites <= 24; textures 20-35; lightmaps <= 1.6 MB; bsp <= 4.0 MB; RAD: no
  "too many light styles on a face" warning; eye previews of every zone (`--eye`, 15 checkpoints)
  read: no black zone, no stretched/misaligned/mirrored faces, palette per section 11, guidance
  visible from each spawn and junction. Commit.

**Stage 3 — interactivity + ini + nav + bots + final**
* All chains of section 9 with real geometry (button levers, bridge deck + towers, heli + rotor +
  paths, billboard, train door, gate, barrier), round reset, the ini file (section 15), cfg pool,
  `.res`, nav (`run_test.py --map zm_vex_cordon --until-nav --export-nav`, validated by
  `navfile.py`: all spawns on the mesh, no islands on main routes).
* Accept on the test server named in the stage task (`VEX_SERVER=<dir>`, `--port <p>`): map loads
  clean with the plugin, 12+ bots for >= 3 rounds; `vexprobe_fire` every vex_* name and both
  breaker / bridge / beacon buttons (`vexprobe_fire cd_brk_a` ...) in 3 consecutive rounds:
  `vexprobe_ents` shows bridge/heli/billboard/door/gate back at their start after each restart,
  locked buttons stay locked without power, heli never appears without the beacon, gated relays
  behave; precache report: new sounds <= 10, brush ents <= 60; final bspcheck all gates green;
  previews updated. Commit (map module, bsp, nav, res, ini, sounds, textures, cfg).
* Plugin side: if the plugin does not yet read `vexmira_maps/<map>.ini` / hook `vexcmd_*` relays
  (MAP_CONTRACT), report it as the remaining integration item; the map must already work
  standalone (lights, doors, effects) without it.

## 17. Self-check (three lenses)

* **FPS / engine**: every risk of the failed dense calibration is addressed (face budget ~8.2k vs
  12k, low offset portals vs full-height holes, plaza <-> bay double header, freighter hull between
  quay and terminal, facades flat); brush ents 44 local; 22 sprites; animated styles < 64 faces;
  9 new sounds; lightmaps controlled by texture scale 2; geometry inside +-3472; hangar sealed (no
  leak from path_corners). Moving entities never crush (dmg 0, heli hovers 200 up, bridge clears
  standing players in the canal, billboard falls into a CLIP-filled bed).
* **32-player gameplay**: 9 districts, 5 loops, 6 camps each with a weakness, all main routes
  192-768 wide, every room 2+ exits, spawns 1344 x 1152 yard / 2176 x 448 concourse, boss arena
  with 7 exits, objectives spread the team (2 breakers 1100 u apart), zombie goal + flank routes
  (fire escapes, canal, south passage, container hops).
* **Story / atmosphere / textures**: one coherent narrative (train -> cordon -> power -> bridge ->
  medevac) visible in the geometry; each zone's materials, light and sound tell the same thing
  (military stencils on the cordon, blood only along the outbreak path, wet asphalt and rust at the
  harbor, clean-but-abandoned civic tiles in the tower); tension escalates every minute and at
  every vex_* event; unique set pieces no other map in the pack has (derailed train breach, lift
  bridge, hovering medevac, falling billboard, shelling horizon).
