"""zm_vexmira_ice - compact snowy courtyard camp map in the classic ice_attack style (original layout).

    cd devtools && python3 -m mapkit.maps.zm_vexmira_ice [--quality final] [--preview DIR]

Top view (Y north), floor z 0, sky lid z 576, playable x -1088..1088, y -1344..1344:

    +-----------------------------------------------+
    | rock |  ZOMBIE GARAGE (T spawn, z 0..224)  | rock |   facade y 1024: 2 open doors + centre
    |      |   VEXMIRA neon over the shutter      |      |   shutter (opens at freeze end)
    |------+-------------------------------------+------|
    |                         [watchtower + pad]          |  courtyard y -1024..1024
    | BUNKER (raised room,       trucks, campfire,        |  camps: bunker (ladder / ice wall
    |  ladder + ice wall)        crates, lamps     WARE-  |  + stairs), warehouse roof (ladder
    |                                              HOUSE  |  + pad), watchtower (ladder + pad),
    | VENT corridor (L)            TUNNEL (sunken)  roof  |  vent corridor (2 mouths), tunnel
    |               CT SPAWN YARD (y -1344..-1024)        |  (2 stair wells; secret room)
    +-----------------------------------------------+

Props (trucks, jeep, tanks, crates, lamps, fences, antenna, radar, snowmobile, campfire logs) are .mdl
models from devtools/mdlkit/content/ice.py, spawned by the plugin from the map ini [models]; this file
writes that section (PROPS) and adds CLIP brushes where players collide with them.
"""
from __future__ import annotations

import argparse
import math
import os
import sys

from ..mapwriter import (CLIP, NULL, SKY, TRIGGER, Brush, Entity, Map, ambient, box, env_sprite, glass, ladder, light,
                         light_environment, masked_entity, pipe, prism, railing, skybox, spawn_grid, stairs, wall,
                         wedge)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
NAME = 'zm_vexmira_ice'
INI = os.path.join(REPO, 'cstrike', 'addons', 'amxmodx', 'configs', 'vexmira_maps', NAME + '.ini')

X0, X1, Y0, Y1 = -1088, 1088, -1344, 1344
ZSKY = 576
PW = 32           # perimeter wall thickness
PH = 320          # perimeter wall height

SNOW = 'vx_snow'
SROCK = 'vx_snow_rock'
BUNK = 'vx_bunker'
CONC = 'vx_conc_stain'
CORR = 'vx_metal_corr'
MDARK = 'vx_metal_dark'
FROST = 'vx_frost_metal'
TRIM = 'vx_trim_metal'
HAZ = 'vx_trim_hazard'
ICE = 'vx_ice'
PLANK = 'vx_wood_plank'
BRICK = 'vx_brick_grey'
LW = '~vx_light_w'
LR = '~vx_light_r'
LC = '~vx_light_c'
NEON = '+0vx_neonice'
ORG = 'ORIGIN'

TEX_SCALE = {SNOW: 2, SROCK: 2, CONC: 1.5, BUNK: 1.5, CORR: 1.5, BRICK: 1.5}

# model props: (file, x, y, z, yaw, clip (dx, dy, dz) or None) - clip is axis aligned, centred on x y
PROPS = [
    ('ice_truck', -420, 120, 0, 0, (320, 112, 144)),
    ('ice_truck', 600, -300, 0, 90, (112, 320, 144)),
    ('ice_jeep', -180, 700, 0, 180, (176, 84, 72)),
    ('ice_sled', 220, -880, 0, 60, None),
    ('ice_tank', -620, -380, 0, 90, (88, 192, 104)),
    ('ice_generator', -760, 330, 0, 90, (56, 96, 64)),
    ('ice_radar', 1000, -230, 192, 0, (48, 48, 112)),
    ('ice_antenna', 1010, 100, 192, 0, (40, 40, 360)),
    ('ice_logs', -240, -440, 0, 0, None),
    ('ice_barrel', 720, 700, 0, 0, (32, 32, 46)),
    ('ice_barrel', 756, 724, 0, 40, (32, 32, 46)),
    ('ice_barrel', 736, 668, 0, 80, (32, 32, 46)),
    ('ice_barrel', -720, 560, 0, 10, (32, 32, 46)),
    ('ice_barrel', 180, -400, 0, 30, (32, 32, 46)),
    ('ice_crate', 120, 180, 0, 0, (56, 56, 56)),
    ('ice_crate', 120, 236, 0, 90, (56, 56, 56)),
    ('ice_crate', 120, 208, 56, 20, (56, 56, 56)),
    ('ice_cratem', -60, -150, 0, 0, (64, 40, 36)),
    ('ice_cratem', -60, -110, 0, 0, (64, 40, 36)),
    ('ice_cratem', 800, 560, 0, 90, (40, 64, 36)),
    ('ice_crate', -880, 760, 0, 15, (56, 56, 56)),
    ('ice_crate', 880, -760, 0, 0, (56, 56, 56)),
    ('ice_lamp', -300, -980, 0, 90, (16, 16, 176)),
    ('ice_lamp', 300, -980, 0, 90, (16, 16, 176)),
    ('ice_lamp', -560, 900, 0, 270, (16, 16, 176)),
    ('ice_lamp', 560, 900, 0, 270, (16, 16, 176)),
    ('ice_lamp', 0, 0, 0, 0, (16, 16, 176)),
    ('ice_fence', -640, -1000, 0, 0, (128, 8, 56)),
    ('ice_fence', 512, -1000, 0, 0, (128, 8, 56)),
]
# lamp head positions (for light entities): model origin + (40, 0, 176) rotated by yaw


def _lamp_head(x, y, yaw):
    return (round(x + 40 * math.cos(math.radians(yaw))), round(y + 40 * math.sin(math.radians(yaw))), 170)


def launch(H, apex, vh, d):
    """trigger_push launch pad (same model as zm_vexmira_7door.launch): returns (speed, angles, field length)."""
    v = math.sqrt(1600.0 * (apex - H))
    a = v * v / (2.0 * H)
    t = math.sqrt(2.0 * H / a)
    sz = a + 800.0
    sp = math.hypot(vh, sz)
    pitch = -math.degrees(math.atan2(sz, vh))
    yaw = math.degrees(math.atan2(d[1], d[0]))
    return round(sp), f'{pitch:.1f} {yaw:.1f} 0', vh * t


def build(ice_detail=True) -> Map:
    m = Map(NAME, sky='snow', message='Vexmira Ice Attack', tex_scale=TEX_SCALE)
    m.world['light'] = 0
    det: list = []                 # func_detail brushes (trims, snow caps, pipes, ...)
    D = det.extend
    ents = []
    E = ents.append

    def pt(cls, name=None, **kw):
        e = Entity(cls, **kw)
        if name:
            e['targetname'] = name
        E(e)
        return e

    def snowcap(x0, y0, x1, y1, z, over=4, h=4):
        D(box((x0 - over, y0 - over, z), (x1 + over, y1 + over, z + h), {'top': SNOW, 'all': SNOW}))

    def trim_h(x0, y0, x1, y1, z, h=8, out=4):
        D(box((x0 - out, y0 - out, z), (x1 + out, y1 + out, z + h), {'top': SNOW, 'all': TRIM}))

    # ------------------------------------------------------------------ shell: sky box, ground, perimeter
    m.add(skybox((X0, Y0, -176), (X1, Y1, ZSKY)))
    G = {'top': SNOW, 'all': CONC}
    TX0, TX1, TY0, TY1 = 256, 896, -704, -608       # tunnel cut
    SX0, SX1, SY0 = 528, 656, -848                  # secret room (south of the tunnel middle)
    m.add(box((X0, -608, -176), (X1, Y1, 0), G))
    m.add(box((X0, Y0, -176), (X1, SY0, 0), G))
    m.add(box((X0, SY0, -176), (SX0, TY0, 0), G))
    m.add(box((SX1, SY0, -176), (X1, TY0, 0), G))
    m.add(box((SX0, SY0, -176), (SX1, TY0, -128), G))        # secret room floor
    m.add(box((SX0, SY0, -32), (SX1, TY0, 0), G))            # secret room roof
    m.add(box((X0, TY0, -176), (TX0, TY1, 0), G))
    m.add(box((TX1, TY0, -176), (X1, TY1, 0), G))
    m.add(box((TX0, TY0, -176), (TX1, TY1, -128), {'top': 'vx_conc_crack', 'all': CONC}))
    m.add(box((448, TY0, -16), (704, TY1, 0), G))            # tunnel roof
    # perimeter rock walls (varied heights), snow caps
    for (a, b, h) in (((X0, Y0), (X1, Y0 + PW), PH), ((X0, Y1 - PW), (X1, Y1), PH + 32),
                      ((X0, Y0), (X0 + PW, Y1), PH - 32), ((X1 - PW, Y0), (X1, Y1), PH)):
        m.add(box((a[0], a[1], 0), (b[0], b[1], h), {'top': SNOW, 'all': SROCK}))
        snowcap(a[0], a[1], b[0], b[1], h, over=0, h=6)
    # buttresses along the long walls (break the flat faces)
    for y in (-400, 600):
        for x, sx in ((X0 + PW, 1), (X1 - PW, -1)):
            D(box((min(x, x + sx * 24), y - 24, 0), (max(x, x + sx * 24), y + 24, PH - 64), {'top': SNOW, 'all': SROCK}))

    # ------------------------------------------------------------------ zombie garage (north) + facade
    GX0, GX1, GY0, GY1, GZ = -576, 576, 1056, Y1 - PW, 224
    m.add(box((X0 + PW, 1024, 0), (GX0 - 32, Y1 - PW, PH), {'top': SNOW, 'all': SROCK}))
    m.add(box((GX1 + 32, 1024, 0), (X1 - PW, Y1 - PW, PH), {'top': SNOW, 'all': SROCK}))
    m.add(box((GX0 - 32, 1024, 0), (GX0, Y1 - PW, GZ), BRICK))
    m.add(box((GX1, 1024, 0), (GX1 + 32, Y1 - PW, GZ), BRICK))
    m.add(box((GX0 - 32, 1024, GZ), (GX1 + 32, Y1 - PW, GZ + 24), {'bottom': MDARK, 'top': SNOW, 'all': CONC}))
    facade_holes = [(608 - 448, 608 - 320, 0, 128), (608 + 320, 608 + 448, 0, 128), (608 - 96, 608 + 96, 0, 160)]
    fw = wall((GX0 - 32, 1040), (GX1 + 32, 1040), 0, 304, 32, {'s': BRICK, 'n': CONC, 'all': BRICK}, holes=facade_holes)
    m.add(fw)
    snowcap(GX0 - 32, 1024, GX1 + 32, 1056, 304, over=6, h=6)
    trim_h(GX0 - 32, 1024, GX1 + 32, 1028, 168, h=10, out=2)
    # door frames (hazard trim) around the 3 openings
    for cx, hw, hh in ((-384, 64, 128), (384, 64, 128), (0, 96, 160)):
        D(box((cx - hw - 12, 1012, 0), (cx - hw, 1024, hh + 12), HAZ))
        D(box((cx + hw, 1012, 0), (cx + hw + 12, 1024, hh + 12), HAZ))
        D(box((cx - hw - 12, 1012, hh), (cx + hw + 12, 1024, hh + 12), HAZ))
    # canopy over the shutter + snow
    D(box((-160, 960, 192), (160, 1024, 200), {'top': SNOW, 'all': MDARK}))
    for x in (-150, 142):
        D(box((x, 968, 0), (x + 8, 976, 192), MDARK))
    # VEXMIRA animated neon above the shutter (south face)
    sign = Brush.box((-160, 1016, 224), (160, 1024, 284), {'s': NEON, 'all': MDARK})
    sign.fit_faces(('s',))
    m.add(sign)
    D(box((-168, 1012, 216), (168, 1024, 224), TRIM))
    E(env_sprite((0, 1000, 254), 'sprites/glow01.spr', 1.4, (170, 90, 255), 60))
    E(light((0, 980, 250), (180, 110, 255), 160))
    # shutter: opens at freeze end (plugin fires vex_freeze_end), stays open; CS restores it every round
    sh = Brush.box((-96, 1036, 0), (96, 1044, 160), {'s': CORR, 'n': CORR, 'all': MDARK})
    sh.fit_faces(('s', 'n'))
    E(Entity('func_door', [sh], targetname='ice_gate', angles='0 -1 0', speed=60, wait=-1, lip=12, sounds=0,
             spawnflags=0, _minlight=0.1))
    pt('multi_manager', 'vex_freeze_end', origin=(0, 1100, 64), ice_gate=0, ice_gate_snd=0, vexcmd_msg_gate=0.5)
    pt('ambient_generic', 'ice_gate_snd', origin=(0, 1060, 96), message='doors/doormove3.wav', health=8, pitch=90,
       pitchstart=90, spawnflags=4 | 16 | 32)
    # garage interior: red emergency light panels, pillars, T spawns
    for x in (-384, 0, 384):
        lb = Brush.box((x - 48, 1160, GZ - 4), (x + 48, 1192, GZ), {'bottom': LR, 'all': MDARK})
        lb.fit_faces(('bottom',))
        D([lb])
        E(light((x, 1176, 190), (255, 50, 40), 140))
    m.add_entities(spawn_grid('t', (GX0, GY0), (GX1, GY1), 0, 32, spacing=72, yaw=270))
    E(light((0, 1240, 120), (120, 140, 170), 70))

    # snow mounds (break the long courtyard sight lines; walkable 30-degree slopes)
    for cx, cy, ax in ((-520, -150, 'x'), (300, 120, 'y'), (-150, 520, 'x')):
        if ax == 'x':
            pts = [(cx - 120, cy - 40, 0), (cx + 120, cy - 40, 0), (cx - 120, cy + 40, 0), (cx + 120, cy + 40, 0),
                   (cx - 70, cy, 44), (cx + 70, cy, 44)]
        else:
            pts = [(cx - 40, cy - 120, 0), (cx - 40, cy + 120, 0), (cx + 40, cy - 120, 0), (cx + 40, cy + 120, 0),
                   (cx, cy - 70, 44), (cx, cy + 70, 44)]
        D([Brush.from_points(pts, SNOW)])

    # ------------------------------------------------------------------ CT spawn yard (south)
    m.add_entities(spawn_grid('ct', (-512, Y0 + PW), (512, -1032), 0, 32, spacing=72, yaw=90))
    # low concrete barriers (cover, hop-able 40)
    for x in (-440, -150, 150, 440):
        D(box((x - 56, -1000, 0), (x + 56, -984, 36), {'top': SNOW, 'all': CONC}))
        D(box((x - 56, -998, 36), (x + 56, -986, 40), SNOW))
    # floodlight mast on the south wall (lit panel)
    for x in (-700, 700):
        D(box((x - 6, Y0 + PW, 0), (x + 6, Y0 + PW + 12, 260), MDARK))
        lb = Brush.box((x - 40, Y0 + PW + 4, 260), (x + 40, Y0 + PW + 36, 268), {'bottom': LW, 'all': MDARK})
        lb.fit_faces(('bottom',))
        D([lb])
        E(light((x, Y0 + 120, 220), (225, 235, 255), 220))

    # ------------------------------------------------------------------ BUNKER (west, raised room z 128)
    BX0, BX1, BY0, BY1 = X0 + PW, -832, -224, 224
    WX0, WX1 = -1008, -944                     # stair shaft (north door under the room)
    BT = {'top': CONC, 'all': BUNK}
    m.add(box((BX0, BY0, 0), (WX0, BY1, 128), BT))
    m.add(box((WX1, BY0, 0), (BX1, BY1, 128), BT))
    m.add(box((WX0, BY0, 0), (WX1, 16, 128), BT))
    m.add(stairs((-976, 224, 0), '-y', 64, 128, rise=16, run=26, tex={'top': CONC, 'all': BUNK}, clip=True))
    # room walls (z 128..240) with door (east, at the ladder) + firing slit window
    m.add(wall((BX1 - 16, BY0), (BX1 - 16, BY1), 128, 240, 16, {'e': BUNK, 'w': CONC, 'all': BUNK}, side='right',
               holes=[(40, 120, 128, 232), (240, 400, 176, 208)]))
    m.add(wall((BX0, BY1), (BX1, BY1), 128, 240, 16, {'n': BUNK, 's': CONC, 'all': BUNK}, side='right',
               holes=[(96, 192, 176, 208)]))
    m.add(wall((BX0, BY0), (BX1, BY0), 128, 240, 16, {'s': BUNK, 'n': CONC, 'all': BUNK}, side='left'))
    m.add(box((BX0, BY0 - 16, 240), (BX1 + 24, BY1 + 16, 256), {'bottom': MDARK, 'top': SNOW, 'all': BUNK}))
    # roof overhang lip + snow + icicles, base plinth trim
    trim_h(BX0, BY0 - 16, BX1 + 24, BY1 + 16, 256, h=6, out=4)
    for k in range(7):
        y = BY0 + 24 + k * 64
        x = BX1 + 20
        D([Brush.from_points([(x - 3, y - 3, 240), (x + 3, y - 3, 240), (x, y + 3, 240), (x, y, 214 + (k % 3) * 6)], ICE)])
    # ice wall on the north stair door (breakable, ice gibs), ladder on the east face
    ice = Brush.box((WX0, BY1, 0), (WX1, BY1 + 8, 128), ICE)
    ice.fit_faces(('n', 's'))
    E(Entity('func_breakable', [ice], material=0, health=260, rendermode=2, renderamt=170, spawnobject=0,
             explodemagnitude=0, _minlight=0.2, targetname='ice_wall'))
    # balcony in front of the east door (ladder top lands on open floor, not in the doorway)
    m.add(box((BX1, -200, 0), (BX1 + 64, -88, 128), {'top': CONC, 'all': BUNK}))
    lad1, lv1 = ladder((BX1 + 64, -144, 0), '-x', 128 + 12, width=40, depth=16)
    E(lad1)
    # interior: lamp (swinging pendulum), crates, room light
    lamp = box((-944, -8, 212), (-928, 8, 216), {'bottom': LW, 'all': MDARK}) + \
        box((-938, -2, 216), (-934, 2, 240), MDARK) + box((-940, -4, 232), (-932, 4, 240), ORG)
    E(Entity('func_pendulum', lamp, speed=24, distance=14, damp=0, spawnflags=1 + 8 + 64, _minlight=0.6))
    E(light((-936, 0, 200), (255, 220, 170), 130))
    E(light((-1000, -150, 200), (200, 220, 255), 60))
    # pipes along the bunker south face
    D(pipe((BX0 + 40, BY0 - 10, 100), (BX1, BY0 - 10, 100), 5, 6, MDARK))
    D(pipe((BX1 - 10, BY0 - 10, 0), (BX1 - 10, BY0 - 10, 100), 5, 6, MDARK))

    # ------------------------------------------------------------------ WAREHOUSE (east), roof camp z 192
    WH0, WH1, WY0, WY1, WZ = 832, X1 - PW, -320, 160, 192
    m.add(box((WH0, WY0, 0), (WH1, WY1, WZ), {'top': SNOW, 'all': CORR}))
    # facade details: plinth, mid trim, window frames, roof parapets with gaps (ladder y -256..-192, pad -64..32)
    trim_h(WH0, WY0, WH1, WY1, 0, h=16, out=4)
    for (y0, y1) in ((WY0 - 2, -256), (-192, WY1 + 2)):
        trim_h(WH0 - 2, y0, WH0, y1, 120, h=6, out=0)
    for y in (-120, 90):
        fr = Brush.box((WH0 - 4, y - 32, 132), (WH0, y + 32, 172), {'w': 'vx_glass', 'all': MDARK})
        fr.fit_faces(('w',))
        D([fr])
        D(box((WH0 - 8, y - 36, 128), (WH0, y + 36, 132), SNOW))
    P = {'top': SNOW, 'all': CONC}
    # low roof curbs (8 high: step over / drop down anywhere - no trapped bots, zombies can always follow)
    for (y0, y1) in ((WY0, -256), (-192, -64), (32, WY1)):
        D(box((WH0, y0, WZ), (WH0 + 12, y1, WZ + 8), P))
    D(box((WH0, WY1 - 12, WZ), (WH1, WY1, WZ + 8), P))
    D(box((WH0, WY0, WZ), (WH1, WY0 + 12, WZ + 8), P))
    OH = {'top': SNOW, 'all': MDARK}            # roof overhang (open over the ladder and the pad landing)
    for (y0, y1) in ((WY0 - 16, -256), (-192, -64), (32, WY1 + 16)):
        D(box((WH0 - 16, y0, WZ - 8), (WH0, y1, WZ), OH))
    D(box((WH0, WY0 - 16, WZ - 8), (WH1, WY0, WZ), OH))
    D(box((WH0, WY1, WZ - 8), (WH1, WY1 + 16, WZ), OH))
    lad2, lv2 = ladder((WH0, -224, 0), '+x', WZ + 12, width=40, depth=16)
    E(lad2)
    # roof: vent box + steam pipe, light
    D(box((940, -60, WZ), (1000, 0, WZ + 40), {'top': SNOW, 'all': MDARK}))
    D(pipe((970, 40, WZ), (970, 40, WZ + 72), 6, 8, MDARK))
    E(light((950, -100, WZ + 90), (220, 230, 255), 120))
    # ALARM button on the warehouse south wall (ground) -> klaxon + red lights for 6 s
    E(Entity('func_button', box((900, WY0 - 4, 48), (932, WY0, 72), HAZ), target='ice_alarm_mm', wait=20, speed=40,
             lip=2, angles='0 90 0', sounds=11, _minlight=0.6))
    lb = Brush.box((892, WY0 - 4, 80), (940, WY0, 96), {'s': LR, 'all': MDARK})
    lb.fit_faces(('s',))
    D([lb])
    pt('multi_manager', 'ice_alarm_mm', origin=(910, -360, 64), ice_alarm_snd=0, ice_r_alarm_on=0,
       ice_r_alarm_off=6, vexcmd_msg_alarm=0)
    pt('ambient_generic', 'ice_alarm_snd', origin=(912, -340, 120), message='vexmira/map/ice_alarm.wav', health=10,
       pitch=100, pitchstart=100, spawnflags=8 | 16 | 32)
    pt('trigger_relay', 'ice_r_alarm_on', origin=(912, -360, 80), target='ice_alarm_lt', triggerstate=1)
    pt('trigger_relay', 'ice_r_alarm_off', origin=(912, -360, 96), target='ice_alarm_lt', triggerstate=0)
    pt('multi_manager', 'vex_round_start', origin=(912, -380, 96), ice_r_alarm_off=0)
    for p in ((700, -400, 160), (-300, 300, 200), (300, 600, 200)):
        E(light(p, (255, 30, 20), 260, targetname='ice_alarm_lt'))
        ents[-1]['spawnflags'] = 1

    # ------------------------------------------------------------------ WATCHTOWER + jump pads
    TX, TY, TZ = 384, 448, 224
    tx0, tx1, ty0, ty1 = TX - 80, TX + 80, TY - 80, TY + 80
    m.add(box((tx0, ty0, TZ - 16), (tx1, ty1, TZ), {'top': PLANK, 'all': FROST}))
    snowcap(tx0 + 8, ty0 + 8, tx1 - 8, ty1 - 8, TZ, over=0, h=1)
    for x in (tx0 + 4, tx1 - 20):
        for y in (ty0 + 4, ty1 - 20):
            m.add(box((x, y, 0), (x + 16, y + 16, TZ - 16), FROST))
    D(box((tx0 + 12, ty0 + 8, 100), (tx1 - 12, ty0 + 12, 108), MDARK))   # cross braces
    D(box((tx0 + 12, ty1 - 12, 100), (tx1 - 12, ty1 - 8, 108), MDARK))
    rv, rc = [], []
    for a, b in (((tx0, ty1), (tx1, ty1)), ((tx0, ty0), (tx0, ty1))):     # north + west rails; south/east open
        v, c = railing(a, b, TZ)
        rv += v
        rc += c
    m.add(rc)
    m.add(box((TX - 28, ty0, 0), (TX + 28, ty0 + 8, TZ - 16), {'s': PLANK, 'all': FROST}))   # ladder backing board
    lad3, lv3 = ladder((TX, ty0, 0), '+y', TZ + 12, width=40, depth=16)
    E(lad3)
    E(masked_entity(rv, solid=False))
    E(masked_entity(lv1 + lv2 + lv3, solid=False))
    # beacon on a pole (rotating red lamp + glow)
    D(box((tx0 + 4, ty1 - 12, TZ), (tx0 + 12, ty1 - 4, TZ + 96), MDARK))
    bc = (tx0 + 8, ty1 - 8, TZ + 104)
    beacon = box((bc[0] - 12, bc[1] - 2, bc[2] - 6), (bc[0] - 2, bc[1] + 2, bc[2] + 6), LR) + \
        box((bc[0] + 2, bc[1] - 2, bc[2] - 6), (bc[0] + 12, bc[1] + 2, bc[2] + 6), LR) + \
        box((bc[0] - 2, bc[1] - 2, bc[2] - 2), (bc[0] + 2, bc[1] + 2, bc[2] + 2), ORG)
    E(Entity('func_rotating', beacon, speed=180, spawnflags=1, rendermode=0, _minlight=1))
    E(env_sprite(bc, 'sprites/glow01.spr', 0.5, (255, 40, 30), 150))
    E(light((TX, TY, TZ + 80), (255, 80, 60), 90))
    # pads: (centre, direction, apex, target z)
    for (px, py), d, apex in (((592, TY), (-1, 0), 330), ((720, -16), (1, 0), 300)):
        sp, ang, L = launch(64, apex, 150, d)
        D(box((px - 40, py - 40, 0), (px + 40, py + 40, 2), {'top': LC, 'all': HAZ}))
        D(box((px - 48, py - 48, 0), (px + 48, py + 48, 1), {'top': HAZ, 'all': HAZ}))
        x0 = px - 40 if d[0] > 0 else px - 40 - L
        x1 = px + 40 + L if d[0] > 0 else px + 40
        E(Entity('trigger_push', box((x0, py - 40, 2), (x1, py + 40, 66), TRIGGER), speed=sp, angles=ang))
        E(env_sprite((px, py, 10), 'sprites/glow01.spr', 0.7, (60, 220, 255), 120))
        E(light((px, py, 40), (60, 220, 255), 120))

    # ------------------------------------------------------------------ VENT corridor (south-west, L shape)
    VX0, VX1, VY0, VY1, VZ = X0 + PW, -640, -800, -544, 96
    VT = {'top': SNOW, 'all': CORR}
    m.add(box((VX0, VY0, VZ), (VX1, VY1, VZ + 64), {'bottom': MDARK, 'top': SNOW, 'all': CORR}))
    m.add(box((VX0, VY0, 0), (VX1, -704, VZ), VT))
    m.add(box((VX0, -704, 0), (-960, VY1, VZ), VT))
    m.add(box((-896, -640, 0), (VX1, VY1, VZ), VT))
    trim_h(VX0, VY0, VX1, VY1, VZ + 64, h=6, out=4)
    for x, y in ((-800, -672), (-928, -672), (-928, -592)):
        lb = Brush.box((x - 16, y - 16, VZ - 4), (x + 16, y + 16, VZ), {'bottom': LW, 'all': MDARK})
        lb.fit_faces(('bottom',))
        D([lb])
        E(light((x, y, VZ - 16), (200, 225, 255), 70))
    # grate frames at both mouths
    for a, b in (((VX1, -704), (VX1 + 6, -640)), ((-960, VY1), (-896, VY1 + 6))):
        D(box((a[0], a[1], VZ - 8), (b[0], b[1], VZ), HAZ))
    D(pipe((VX0 + 40, VY0 - 12, 140), (VX1, VY0 - 12, 140), 6, 6, MDARK))

    # ------------------------------------------------------------------ TUNNEL (sunken, 2 stair wells)
    m.add(stairs((448, -656, -128), '-x', 96, 128, rise=16, run=24, tex={'top': CONC, 'all': CONC}, clip=True))
    m.add(stairs((704, -656, -128), '+x', 96, 128, rise=16, run=24, tex={'top': CONC, 'all': CONC}, clip=True))
    for x0, x1 in ((TX0, 448), (704, TX1)):          # curbs around the wells
        for y0, y1 in ((TY0 - 8, TY0), (TY1, TY1 + 8)):
            D(box((x0, y0, 0), (x1, y1, 8), HAZ))
    for x in (512, 640):
        lb = Brush.box((x - 24, -672, -20), (x + 24, -640, -16), {'bottom': LW, 'all': MDARK})
        lb.fit_faces(('bottom',))
        D([lb])
        E(light((x, -656, -40), (210, 230, 255), 90))
    D(pipe((448, TY1 - 8, -40), (704, TY1 - 8, -40), 4, 6, MDARK))
    # secret room behind a fake wall (south side of the tunnel middle)
    fake = Brush.box((SX0 + 32, TY0 - 8, -128), (SX1 - 32, TY0, -32), CONC)
    E(Entity('func_illusionary', [fake], rendermode=0, renderamt=255))
    m.add(box((SX0, TY0 - 8, -128), (SX0 + 32, TY0, -32), CONC))
    m.add(box((SX1 - 32, TY0 - 8, -128), (SX1, TY0, -32), CONC))
    E(light((592, -800, -60), (160, 90, 255), 80))
    E(Entity('func_button', box((580, SY0, -88), (604, SY0 + 4, -64), HAZ), target='ice_secret_mm', wait=60,
             speed=40, lip=2, angles='0 270 0', sounds=9, _minlight=0.8))
    sg = Brush.box((560, SY0, -60), (624, SY0 + 2, -44), {'n': '~vx_neon_vex', 'all': NULL})
    sg.fit_faces(('n',))
    D([sg])
    pt('multi_manager', 'ice_secret_mm', origin=(592, -760, -100), vexcmd_reward_h_3=0, vexcmd_msg_secret=0)

    # map -> plugin relays
    for nm in ('vexcmd_reward_h_3', 'vexcmd_msg_secret', 'vexcmd_msg_alarm', 'vexcmd_msg_gate'):
        pt('trigger_relay', nm, origin=(0, -1200, 96), triggerstate=2)

    # ------------------------------------------------------------------ campfire, breakables, props clips
    E(env_sprite((-240, -440, 30), 'sprites/vexmira/fire.spr', 0.55, (255, 255, 255), 255, framerate=10))
    E(light((-240, -440, 48), (255, 150, 60), 170))
    E(ambient((-240, -440, 24), 'vexmira/map/ice_fire.wav', volume=6, radius='small'))
    m.add(box((-276, -476, 0), (-204, -404, 12), CLIP))
    # breakable ice blocks (cover in the middle; glass gibs)
    for x, y in ((-80, 300), (-16, 300), (-48, 364)):
        b = Brush.box((x - 30, y - 30, 0), (x + 30, y + 30, 56 if (x, y) != (-48, 364) else 48), ICE)
        b.fit_faces(('n', 's', 'e', 'w', 'top'))
        E(Entity('func_breakable', [b], material=0, health=90, rendermode=2, renderamt=200, spawnobject=0,
                 explodemagnitude=0, _minlight=0.3))
    for name, x, y, z, yaw, clip in PROPS:
        if clip:
            dx, dy, dz = clip
            if dz > 60:              # tall props: clip up to the sky (no walkable/nav area on their tops)
                dz = ZSKY - z
            cx = x + 64 if name == 'ice_fence' else x
            m.add(box((cx - dx / 2, y - dy / 2, z), (cx + dx / 2, y + dy / 2, z + dz), CLIP))
        if name == 'ice_lamp':
            hx, hy, hz = _lamp_head(x, y, yaw)
            E(light((hx, hy, hz), (255, 225, 170), 150))
            E(env_sprite((hx, hy, hz + 6), 'sprites/glow01.spr', 0.35, (255, 225, 170), 110))

    # ------------------------------------------------------------------ atmosphere
    E(light_environment(pitch=-55, yaw=125, color=(215, 225, 255), brightness=170, diffuse=(150, 170, 210, 70),
                        origin=(0, 0, 500)))
    E(ambient((0, 0, 300), 'vexmira/map/ice_wind.wav', volume=3, radius='everywhere'))
    pt('env_snow', origin=(0, 0, 480))
    pt('info_map_parameters', origin=(0, -1200, 48), buying=0)

    if det:
        E(Entity('func_detail', det, zhlt_detaillevel=1))
    m.add_entities(ents)
    return m


def write_ini_models(path=INI):
    """Rewrite the [models] section of the map ini from PROPS (the rest of the ini is hand written)."""
    lines = open(path, encoding='latin-1').read().split('\n')
    out, skip = [], False
    for ln in lines:
        if ln.strip().lower().startswith('[models]'):
            skip = True
            continue
        if skip and ln.strip().startswith('['):
            skip = False
        if not skip:
            out.append(ln)
    while out and not out[-1].strip():
        out.pop()
    out += ['', '[models]             ; generated by devtools/mapkit/maps/zm_vexmira_ice.py (PROPS)']
    for name, x, y, z, yaw, _ in PROPS:
        extra = ' fr:1' if name == 'ice_radar' else ''
        out.append(f'model = models/vexmira/ice/{name}.mdl {x} {y} {z} {yaw}{extra}')
    with open(path, 'w', encoding='latin-1', newline='\n') as fh:
        fh.write('\n'.join(out) + '\n')


def write_res_extra(res_path):
    have = open(res_path).read().split('\n') if os.path.exists(res_path) else ['// %s custom resources' % NAME]
    extra = [f'models/vexmira/ice/{n}.mdl' for n in dict.fromkeys(p[0] for p in PROPS)]
    extra = [p for p in extra if p not in have]
    for p in extra:
        assert os.path.exists(os.path.join(REPO, 'cstrike', p)), p
    with open(res_path, 'w', newline='\n') as fh:
        fh.write('\n'.join([h for h in have if h] + extra) + '\n')
    return extra


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--quality', default='final')
    ap.add_argument('--out', default=os.path.join(REPO, 'cstrike', 'maps'))
    ap.add_argument('--preview', default=None)
    ap.add_argument('--dry', action='store_true')
    a = ap.parse_args(argv)
    m = build()
    print('spawn check:', m.spawn_problems() or 'OK', m.stats())
    if a.dry:
        return 0
    write_ini_models()
    from ..compile import compile_map
    r = compile_map(m, a.quality, a.out, perf={'warn_p95': 600, 'error_max': 1000})
    print(r.summary())
    if r.bsp:
        print('res extra:', write_res_extra(os.path.join(a.out, NAME + '.res')))
    if r.ok and a.preview:
        from ..preview import render_views
        for p in render_views(r.bsp, a.preview, 1200):
            print(p)
    return 0 if r.ok else 1


if __name__ == '__main__':
    sys.exit(main())
