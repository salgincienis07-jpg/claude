"""zm_vexmira_dust - sunny desert town camp map in the classic zm_dust_world / dust2 camp style (original layout).

    cd devtools && python3 -m mapkit.maps.zm_vexmira_dust [--quality final]

Top view (Y north), floor z 0, sky lid z 640, playable x -1152..1152, y -1280..1280:

    +------------------------------------------------------------+
    |                 T YARD (T spawn, inside the old fort)        |
    |======= side gate ===== GATE (opens at freeze end) ===== side gate =======|  fort wall y 928..960
    | BAZAAR + BALCONY (camp: stairs / jump pad)        [SNIPER TOWER] (ladder / bridge)
    |   cellar under the market (camp: stairs / hatch,       |   ROOFTOP HOUSE (ladder / pad)
    |   secret room behind a fake wall, ceiling fan)          |
    | ARCH TUNNEL (camp: 2 mouths +       MARKET (well, stalls, gong, palms, cart)
    |  a breakable plank barricade)                                  water tower prop (ladder)
    |   SW house               wreck             SE house                                   |
    |                 CT YARD (CT spawn, sandstorm button, MapBy sign on the roof house)   |
    +------------------------------------------------------------+

Props are mdlkit models (devtools/mdlkit/content/dust.py, models/vexmira/dust/) spawned by the plugin from the
map ini [models] (written from PROPS); CLIPS are tight prop-shaped CLIP boxes so every prop can be stood on.
Explosive DANGER barrels: invisible func_breakable (wood, explodemagnitude) + followed model (plugin hides it
when it explodes and brings it back every round).
"""
from __future__ import annotations

import argparse
import math
import os
import sys

from ..mapwriter import (CLIP, NULL, TRIGGER, Brush, Entity, Map, ambient, arch, box, env_sprite, ladder, light,
                         light_environment, masked_entity, prism, railing, skybox, spawn_grid, stairs, wall, wedge)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
NAME = 'zm_vexmira_dust'
INI = os.path.join(REPO, 'cstrike', 'addons', 'amxmodx', 'configs', 'vexmira_maps', NAME + '.ini')

X0, X1, Y0, Y1 = -1152, 1152, -1280, 1280
ZSKY = 640
PW = 32
PH = 288

SAND = 'vx_sand'
PLAST = 'vx_plaster'
STONE = 'vx_stone_carved'
SSTONE = 'vx_temple_flr'
ORN = 'vx_temple_orn'
PLANK = 'vx_wood_plank'
ROOF = 'vx_roof_tile'
BRICK = 'vx_brick_red'
DOOR = 'vx_door_wood'
SHOP = 'vx_shopfront'
TARP = 'vx_tarp'
MDARK = 'vx_metal_dark'
HAZ = 'vx_trim_hazard'
LY = '~vx_light_y'
LC = '~vx_light_c'
ORG = 'ORIGIN'
TEX_SCALE = {SAND: 2, PLAST: 1.5, STONE: 1.5, SSTONE: 1.5, BRICK: 1.5}

# props: (model, x, y, z, yaw)  yaw multiple of 90 (clips are axis aligned)
PROPS = [
    ('dust_pickup', 720, -1100, 0, 90),
    ('dust_sandbag', 720, -950, 0, 0),             # step onto the pickup bed
    ('dust_wreck', 200, -560, 0, 0),
    ('dust_cart', 260, 180, 0, 90),
    ('dust_stall', -260, -240, 0, 90), ('dust_stall', 260, -260, 0, 270),
    ('dust_stall', -380, 120, 0, 0), ('dust_stall', 520, 40, 0, 180),
    ('dust_palm', -160, -420, 0, 0), ('dust_palm', 440, -360, 0, 90), ('dust_palm', -620, 300, 0, 180),
    ('dust_palm', 640, 700, 0, 270), ('dust_palm', -880, -1000, 0, 0), ('dust_palm', 860, -760, 0, 90),
    ('dust_tower', 900, -480, 0, 0),
    ('dust_barrel', 960, -560, 0, 0), ('dust_barrel', 992, -540, 0, 90), ('dust_barrel', -420, -880, 0, 0),
    ('dust_barrel', 120, 760, 0, 0), ('dust_barrel', 150, 784, 0, 180),
    ('dust_sandbag', 928, 470, 256, 0), ('dust_sandbag', -620, 670, 128, 0), ('dust_sandbag', 980, -40, 192, 90),
    ('dust_sandbag', -200, -900, 0, 0), ('dust_sandbag', 200, -900, 0, 0),
    ('dust_crate', -1000, -650, 0, 0), ('dust_crate', -1000, -594, 0, 0), ('dust_crate', -1000, -622, 56, 0),
    ('dust_crate', 560, 820, 0, 0), ('dust_crate', -130, 820, 0, 0),
    ('dust_dish', 1060, -150, 192, 180),
]
CLIPS = {
    'dust_pickup': [(-100, -42, 0, 12, 42, 46), (12, -42, 0, 76, 42, 78), (76, -42, 0, 100, 42, 52)],
    'dust_wreck': [(-88, -38, 0, 88, 38, 36), (-40, -34, 36, 30, 34, 58)],
    'dust_cart': [(-60, -44, 0, 60, 44, 42)],
    'dust_palm': [(-8, -8, 0, 8, 8, 200)],
    'dust_stall': [(-64, -40, 0, 64, 0, 40), (-66, -43, 100, 66, 42, 106)] +
                  [(x - 3, y - 3, 0, x + 3, y + 3, 100) for x in (-62, 62) for y in (-38, 38)],
    'dust_tower': [(-34, -34, 176, 34, 34, 256)] + [(x - 5, y - 5, 0, x + 5, y + 5, 176) for x in (-35, 35) for y in (-35, 35)],
    'dust_barrel': [(-15, -15, 0, 15, 15, 45)],
    'dust_sandbag': [(-48, -16, 0, 48, 16, 40)],
    'dust_crate': [(-28, -28, 0, 28, 28, 56)],
    'dust_dish': [(-4, -4, 0, 4, 4, 64)],
}
STAND = [('pickup bed', 690, -1130, 46), ('pickup cab', 720, -1050, 78), ('wreck roof', 195, -560, 58),
         ('cart', 260, 180, 42), ('stall awning', -260, -240, 106), ('water tower', 900, -480, 256),
         ('crate pile', -1000, -622, 112), ('sandbag', 720, -950, 40)]
# models without clips (lanterns hang, flags are thin)
DECOR = [('models/vexmira/dust/dust_lantern.mdl', x, 640, 118, 0) for x in (-660, -560, -460, -400)] + \
        [('models/vexmira/dust/dust_lantern.mdl', x, 0, 140, 0) for x in (-40, 40)] + \
        [('models/vexmira/world/cd_flag.mdl', 1080, 200, 192, 180), ('models/vexmira/world/cd_flag.mdl', -480, 944, 296, 0),
         ('models/vexmira/world/cd_flag.mdl', 480, 944, 296, 180), ('models/vexmira/world/cd_flag.mdl', 940, 486, 256, 180)]
XBARRELS = [(-256, 870), (256, 870), (-896, -520), (210, 470), (-120, 560), (790, -150)]


def prop_clips(name, x, y, z, yaw):
    out = []
    c, s_ = round(math.cos(math.radians(yaw))), round(math.sin(math.radians(yaw)))
    for (x0, y0, z0, x1, y1, z1) in CLIPS.get(name, []):
        pts = [(x + px * c - py * s_, y + px * s_ + py * c) for px, py in ((x0, y0), (x1, y1))]
        out.append(((min(p[0] for p in pts), min(p[1] for p in pts), z + z0),
                    (max(p[0] for p in pts), max(p[1] for p in pts), z + z1)))
    return out


def launch(H, apex, vh, d):
    v = math.sqrt(1600.0 * (apex - H))
    a = v * v / (2.0 * H)
    t = math.sqrt(2.0 * H / a)
    sz = a + 800.0
    sp = math.hypot(vh, sz)
    pitch = -math.degrees(math.atan2(sz, vh))
    yaw = math.degrees(math.atan2(d[1], d[0]))
    return round(sp), f'{pitch:.1f} {yaw:.1f} 0', vh * t


def build() -> Map:
    m = Map(NAME, sky='vexmira_sand', message='Vexmira Dust - MapBy:SmurfSexy', tex_scale=TEX_SCALE)
    m.world['light'] = 0
    det: list = []
    D = det.extend
    ents = []
    E = ents.append

    def pt(cls, name=None, **kw):
        e = Entity(cls, **kw)
        if name:
            e['targetname'] = name
        E(e)
        return e

    def cap(x0, y0, x1, y1, z, over=4, h=6, tex=SSTONE):
        D(box((x0 - over, y0 - over, z), (x1 + over, y1 + over, z + h), {'all': tex}))

    def plate(face, mn, mx, tex, back=MDARK):
        b = Brush.box(mn, mx, {face: tex, 'all': back})
        b.fit_faces((face,))
        return b

    # ------------------------------------------------------------------ shell + ground (cellar / well cut)
    m.add(skybox((X0, Y0, -208), (X1, Y1, ZSKY)))
    G = {'top': SAND, 'all': SSTONE}
    CX0, CX1, CY0, CY1, CZ = -288, -32, 352, 576, -128          # cellar room
    WX1, WY0, WY1 = 160, 416, 512                               # stair well x -32..160
    HX0, HX1, HY0, HY1 = -256, -208, 528, 576                   # hatch (open to the north wall: ladder)
    SRX0 = -400                                                 # secret room x -400..-288, y 400..496
    m.add(box((X0, Y0, -208), (X1, CY0, 0), G))
    m.add(box((X0, CY1, -208), (X1, Y1, 0), G))
    m.add(box((X0, CY0, -208), (SRX0, CY1, 0), G))
    m.add(box((SRX0, CY0, -208), (CX0, 400, 0), G))
    m.add(box((SRX0, 496, -208), (CX0, CY1, 0), G))
    m.add(box((SRX0, 400, -208), (CX0, 496, -128), G))
    m.add(box((SRX0, 400, -32), (CX0, 496, 0), G))
    m.add(box((WX1, CY0, -208), (X1, CY1, 0), G))
    m.add(box((CX0, CY0, -208), (WX1, CY1, CZ), {'top': 'vx_temple_flr', 'all': SSTONE}))
    for (a, b) in (((CX0, CY0), (CX1, HY0)), ((CX0, HY0), (HX0, HY1)), ((HX1, HY0), (CX1, HY1))):
        m.add(box((a[0], a[1], -16), (b[0], b[1], 0), {'bottom': PLANK, 'top': SAND, 'all': SSTONE}))
    m.add(box((CX1, CY0, CZ), (WX1, WY0, 0), G))
    m.add(box((CX1, WY1, CZ), (WX1, CY1, 0), G))
    m.add(stairs((CX1, (WY0 + WY1) / 2, CZ), '+x', WY1 - WY0, 128, rise=16, run=24, tex={'top': SSTONE, 'all': STONE},
                 clip=True))
    # perimeter town walls (varied heights) with a stone cap
    for (a, b, h) in (((X0, Y0), (X1, Y0 + PW), PH), ((X0, Y1 - PW), (X1, Y1), PH + 32),
                      ((X0, Y0), (X0 + PW, Y1), PH - 32), ((X1 - PW, Y0), (X1, Y1), PH)):
        m.add(box((a[0], a[1], 0), (b[0], b[1], h), {'top': SSTONE, 'all': PLAST}))
        cap(a[0], a[1], b[0], b[1], h, over=0)

    # ------------------------------------------------------------------ old fort wall + T yard
    gates = [(1152 - 320, 1152 - 192, 0, 144), (1152 + 192, 1152 + 320, 0, 144), (1152 - 64, 1152 + 64, 0, 160)]
    m.add(wall((X0, 944), (X1, 944), 0, PH, 32, {'s': STONE, 'n': PLAST, 'all': STONE}, holes=gates))
    cap(X0, 928, X1, 960, PH, over=4, h=8)
    for cx in (-256, 256):
        D(arch((cx, 944), 80, 64, 128, 144, 32, 'x', 6, ORN))
    gb = plate('s', (-64, 940, 0), (64, 948, 160), DOOR, PLANK)
    gb.face('n').tex = DOOR
    E(Entity('func_door', [gb], targetname='dust_gate', angles='0 -1 0', speed=70, wait=-1, lip=12, sounds=0,
             _minlight=0.1))
    pt('multi_manager', 'vex_freeze_end', origin=(0, 1000, 64), dust_gate=0, dust_gate_snd=0, vexcmd_msg_gate=0.5)
    pt('ambient_generic', 'dust_gate_snd', origin=(0, 960, 96), message='doors/doormove3.wav', health=8, pitch=85,
       pitchstart=85, spawnflags=4 | 16 | 32)
    m.add_entities(spawn_grid('t', (-512, 960), (512, Y1 - PW), 0, 32, spacing=72, yaw=270))
    E(light((0, 1100, 200), (255, 170, 110), 160))
    # VEXMIRA neon above the main gate
    m.add(plate('s', (-160, 924, 184), (160, 928, 264), '+0vx_neonice'))
    E(env_sprite((0, 912, 224), 'sprites/glow01.spr', 1.4, (170, 90, 255), 60))
    E(light((0, 880, 224), (180, 110, 255), 150))

    # ------------------------------------------------------------------ CT yard (south)
    m.add_entities(spawn_grid('ct', (-512, Y0 + PW), (512, -960), 0, 32, spacing=72, yaw=90))
    for x in (-420, 420):                                  # low adobe walls (cover, hop 36)
        D(box((x - 72, -930, 0), (x + 72, -914, 36), {'top': SSTONE, 'all': PLAST}))
    # sandstorm button on the south wall
    sb = plate('n', (-24, Y0 + PW, 48), (24, Y0 + PW + 4, 80), LY, HAZ)
    E(Entity('func_button', [sb], target='dust_storm_mm', wait=40, speed=40, lip=2, angles='0 270 0', sounds=0,
             _minlight=0.8))
    pt('multi_manager', 'dust_storm_mm', origin=(0, Y0 + 80, 64), vexcmd_fx_sandstorm=0, dust_storm_snd=0,
       vexcmd_msg_storm=0)
    pt('ambient_generic', 'dust_storm_snd', origin=(0, 0, 300), message='vexmira/map/dust_storm.wav', health=10,
       pitch=100, pitchstart=100, spawnflags=1 | 16 | 32)

    # ------------------------------------------------------------------ SW / SE houses (cover, sight blockers)
    for (hx0, hx1) in ((-640, -384), (384, 640)):
        m.add(box((hx0, -704, 0), (hx1, -448, 176), {'top': ROOF, 'all': PLAST}))
        cap(hx0, -704, hx1, -448, 176, over=8, h=8, tex=ORN)
        D([plate('n', (hx0 + 96, -448, 0), (hx0 + 160, -444, 112), DOOR, PLANK)])
        for wx in (hx0 + 24, hx1 - 64):
            D([plate('n', (wx, -448, 96), (wx + 40, -444, 136), SHOP, PLANK)])

    # ------------------------------------------------------------------ ARCH TUNNEL (west) + plank barricade
    TX0, TX1, TY0, TY1, TZ = -960, -832, -448, 448, 160
    m.add(box((X0 + PW, TY0, 0), (TX0, TY1, 224), {'top': SSTONE, 'all': STONE}))
    m.add(box((TX0, TY0, TZ), (-800, TY1, TZ + 32), {'bottom': PLANK, 'top': SSTONE, 'all': STONE}))
    m.add(wall((TX1 + 16, TY0), (TX1 + 16, TY1), 0, TZ, 32, {'e': PLAST, 'w': STONE, 'all': STONE},
               holes=[(400, 496, 0, 112)]))
    for y in (TY0 + 8, TY1 - 8):
        D(arch((-896, y), 96, 64, 128, TZ, 16, 'x', 6, ORN))
    bar = [Brush.box((TX1, -48, 0), (TX1 + 32, 48, 112), {'e': PLANK, 'w': PLANK, 'all': PLANK})]
    E(Entity('func_breakable', bar, material=1, health=220, spawnobject=0, explodemagnitude=0, _minlight=0.1))
    for y in (-300, 0, 300):
        lb = plate('bottom', (-920, y - 16, TZ - 4), (-872, y + 16, TZ), LY)
        D([lb])
        E(light((-896, y, TZ - 24), (255, 190, 110), 90))

    # ------------------------------------------------------------------ cellar (under the market) + secret room
    lad_c, lv_c = ladder(((HX0 + HX1) / 2, CY1, CZ), '+y', 140, width=32, depth=16)
    E(lad_c)
    for (x, y) in ((-200, 400), (-80, 520)):
        E(light((x, y, -40), (255, 180, 100), 90))
    fan = box((-224, 456, -30), (-96, 472, -27), PLANK) + box((-168, 400, -30), (-152, 528, -27), PLANK) + \
        box((-164, 460, -27), (-156, 468, -16), MDARK) + box((-162, 462, -26), (-158, 466, -22), ORG)
    E(Entity('func_rotating', fan, speed=90, spawnflags=1, _minlight=0.3))
    fake = Brush.box((CX0, 416, CZ), (CX0 + 8, 480, -32), STONE)
    E(Entity('func_illusionary', [fake]))
    m.add(box((CX0, 400, CZ), (CX0 + 8, 416, -32), STONE))
    m.add(box((CX0, 480, CZ), (CX0 + 8, 496, -32), STONE))
    m.add(box((CX0, 400, -32), (CX0 + 8, 496, -16), STONE))
    E(Entity('func_button', box((SRX0, 436, -88), (SRX0 + 4, 460, -64), HAZ), target='dust_secret_mm', wait=60,
             speed=40, lip=2, angles='0 180 0', sounds=0, _minlight=0.8))
    D([plate('e', (SRX0, 416, -60), (SRX0 + 2, 480, -44), '+0vx_mapby', NULL)])
    E(light((-344, 448, -60), (160, 90, 255), 80))
    pt('multi_manager', 'dust_secret_mm', origin=(-344, 448, -100), vexcmd_reward_h_3=0, vexcmd_msg_secret=0)

    # ------------------------------------------------------------------ MARKET: well, gong, pad to the balcony
    D(prism((0, 0), 48, 8, 0, 32, {'top': SSTONE, 'all': STONE}))
    m.add(prism((0, 0), 34, 8, 28, 30, '!vx_water'))
    for (x, y) in ((-44, -44), (44, -44), (-44, 44), (44, 44)):
        D(box((x - 4, y - 4, 32), (x + 4, y + 4, 140), PLANK))
    D(box((-60, -60, 140), (60, 60, 148), {'all': ROOF}))
    # gong (the plate is the button)
    D(box((-232, -132, 0), (-226, -126, 120), PLANK) + box((-232, -50, 0), (-226, -44, 120), PLANK) +
      box((-232, -132, 120), (-226, -44, 126), PLANK))
    gong = plate('e', (-230, -112, 44), (-226, -64, 108), ORN, ORN)
    E(Entity('func_button', [gong], target='dust_gong_snd', wait=3, speed=20, lip=2, angles='0 180 0', sounds=0,
             _minlight=0.4))
    pt('ambient_generic', 'dust_gong_snd', origin=(-228, -88, 76), message='vexmira/map/dust_gong.wav', health=10,
       pitch=100, pitchstart=100, spawnflags=8 | 16 | 32)
    E(light((0, 0, 200), (255, 200, 140), 180))

    # ------------------------------------------------------------------ BAZAAR + market balcony (camp)
    BZX0, BZX1, BZY0 = -704, -352, 704
    m.add(box((BZX0, BZY0, 0), (BZX1, 928, 256), {'top': ROOF, 'all': PLAST}))
    cap(BZX0, BZY0, BZX1, 928, 256, over=6, h=8, tex=ORN)
    D([plate('s', (-560, BZY0 - 4, 128), (-496, BZY0, 240), DOOR, PLANK)])
    for wx in (-680, -440):
        D([plate('s', (wx, BZY0 - 4, 160), (wx + 64, BZY0, 216), SHOP, PLANK)])
    D([plate('s', (-660, BZY0 - 4, 20), (-400, BZY0, 100), 'vx_sign_vexhd', PLANK)])
    BDY0 = 608
    m.add(box((BZX0, BDY0, 120), (BZX1, BZY0, 128), {'top': PLANK, 'bottom': PLANK, 'all': PLANK}))
    for x in (BZX0 + 8, -528, BZX1 - 16):
        D(box((x, BDY0 + 4, 0), (x + 8, BDY0 + 12, 120), PLANK))
    rv, rc = [], []
    for a, b in (((BZX0, BDY0), (-560, BDY0)), ((-464, BDY0), (BZX1, BDY0))):
        v, c = railing(a, b, 128)
        rv += v
        rc += c
    m.add(rc)
    m.add(stairs((-160, (BDY0 + BZY0) / 2, 0), '-x', BZY0 - BDY0, 128, rise=16, run=24,
                 tex={'top': PLANK, 'all': SSTONE}, clip=True))
    for x in (-640, -500, -400):
        E(light((x, 640, 96), (255, 180, 90), 80))

    # ------------------------------------------------------------------ ROOFTOP HOUSE (east) + SNIPER TOWER
    RX0, RX1, RY0, RY1, RZ = 832, X1 - PW, -192, 256, 192
    m.add(box((RX0, RY0, 0), (RX1, RY1, RZ), {'top': ROOF, 'all': PLAST}))
    for (y0, y1) in ((RY0, -112), (-80, 40), (168, RY1)):
        D(box((RX0, y0, RZ), (RX0 + 10, y1, RZ + 8), SSTONE))
    D(box((RX0, RY0, RZ), (RX1, RY0 + 10, RZ + 8), SSTONE))
    lad_r, lv_r = ladder((RX0, -96, 0), '+x', RZ + 12, width=32, depth=16)
    E(lad_r)
    m.add(plate('w', (RX0 - 4, -16, 100), (RX0, 240, 164), '+0vx_mapby'))      # MapBy:SmurfSexy (west face)
    E(env_sprite((RX0 - 24, 112, 132), 'sprites/glow01.spr', 1.6, (255, 90, 220), 70))
    E(light((RX0 - 60, 112, 132), (255, 110, 230), 140))
    for y in (-150, 200):
        D([plate('w', (RX0 - 4, y - 20, 40), (RX0, y + 20, 88), SHOP, PLANK)])
    # sniper tower
    SX0, SX1, SY0, SY1, SZ = 864, 992, 384, 512, 256
    m.add(box((SX0, SY0, 0), (SX1, SY1, SZ), {'top': PLANK, 'all': STONE}))
    m.add(box((SX0, SY1 - 16, SZ), (SX1, SY1, SZ + 32), {'top': SSTONE, 'all': STONE}))
    m.add(box((SX1 - 16, SY0, SZ), (SX1, SY1 - 16, SZ + 32), {'top': SSTONE, 'all': STONE}))
    cap(SX0, SY0, SX1, SY1, SZ - 8, over=6, h=8, tex=ORN)
    lad_t, lv_t = ladder((SX0 - 6, 448, 0), '+x', SZ + 12, width=32, depth=16)
    E(lad_t)
    D(wedge((928, RY1, RZ), '+y', 64, SY0 - RY1, SZ - RZ, {'all': PLANK}))       # plank bridge roof -> tower
    E(masked_entity(lv_c + lv_r + lv_t + rv, solid=False))
    E(light((928, 448, SZ + 60), (255, 170, 110), 110))
    # water tower ladder (prop rungs on its +X side)
    lad_w, _ = ladder((934, -480, 0), '-x', 268, width=24, depth=16)
    E(lad_w)

    # ------------------------------------------------------------------ jump pads, speed strips
    for (px, py), d, apex in (((744, 120), (1, 0), 300), ((-512, 420), (0, 1), 236)):
        sp, ang, L = launch(64, apex, 150, d)
        D(box((px - 40, py - 40, 0), (px + 40, py + 40, 2), {'top': LC, 'all': HAZ}))
        if d[0]:
            mn, mx = (px - 40, py - 40, 2), (px + 40 + L, py + 40, 66)
        else:
            mn, mx = (px - 40, py - 40, 2), (px + 40, py + 40 + L, 66)
        E(Entity('trigger_push', box(mn, mx, TRIGGER), speed=sp, angles=ang))
        E(env_sprite((px, py, 10), 'sprites/glow01.spr', 0.7, (60, 220, 255), 120))
        E(light((px, py, 40), (60, 220, 255), 110))
    for (x0, y0, x1, y1, yaw) in ((-760, -1100, -696, -820, 90), (40, -420, 104, -180, 90)):
        pl = Brush.box((x0, y0, 0), (x1, y1, 1), {'top': '+0vx_chev2', 'all': HAZ})
        u = (math.cos(math.radians(yaw)), math.sin(math.radians(yaw)), 0)
        pl.face('top').set_axes(u, (-u[1], u[0], 0), 1.0, 1.0, 0, 0)
        D([pl])
        E(Entity('trigger_push', box((x0, y0, 1), (x1, y1, 40), TRIGGER), speed=650, angles=f'0 {yaw} 0'))
        E(light(((x0 + x1) / 2, (y0 + y1) / 2, 24), (60, 220, 255), 90))

    # ------------------------------------------------------------------ explosive barrels, props, relays
    for i, (x, y) in enumerate(XBARRELS):
        E(Entity('func_breakable', prism((x, y), 15, 6, 0, 46, NULL), targetname=f'dust_xb{i + 1}', material=1,
                 health=20, explodemagnitude=110, spawnobject=0, rendermode=2, renderamt=0, spawnflags=0))
    for name, x, y, z, yaw in PROPS:
        for mn, mx in prop_clips(name, x, y, z, yaw):
            m.add(box(mn, mx, CLIP))
    for lx, ly, lz in ((-560, 640, 100), (0, 0, 120)):
        E(env_sprite((lx, ly, lz), 'sprites/glow01.spr', 0.4, (255, 190, 90), 120))
    for nm in ('vexcmd_reward_h_3', 'vexcmd_msg_secret', 'vexcmd_msg_gate', 'vexcmd_msg_storm', 'vexcmd_fx_sandstorm'):
        pt('trigger_relay', nm, origin=(0, -1200, 96), triggerstate=2)

    # ------------------------------------------------------------------ atmosphere
    E(light_environment(pitch=-28, yaw=170, color=(255, 196, 140), brightness=210, diffuse=(200, 150, 140, 70),
                        origin=(0, 0, 560)))
    E(ambient((0, 0, 300), 'vexmira/map/ice_wind.wav', volume=2, radius='everywhere'))
    pt('info_map_parameters', origin=(0, -1200, 48), buying=0)
    if det:
        E(Entity('func_detail', det, zhlt_detaillevel=1))
    m.add_entities(ents)
    return m


def write_ini_models(path=INI):
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
    out += ['', '[models]             ; generated by devtools/mapkit/maps/zm_vexmira_dust.py (PROPS, DECOR, XBARRELS)']
    for name, x, y, z, yaw in PROPS:
        out.append(f'model = models/vexmira/dust/{name}.mdl {x} {y} {z} {yaw}')
    for path_, x, y, z, yaw in DECOR:
        extra = ' fr:1' if 'flag' in path_ else ''
        out.append(f'model = {path_} {x} {y} {z} {yaw}{extra}')
    out.append('; explosive barrels: the model follows the func_breakable (hidden when it explodes, back every round)')
    for i in range(len(XBARRELS)):
        out.append(f'model = models/vexmira/dust/dust_xbarrel.mdl @dust_xb{i + 1}')
    with open(path, 'w', encoding='latin-1', newline='\n') as fh:
        fh.write('\n'.join(out) + '\n')


def write_res_extra(res_path):
    have = open(res_path).read().split('\n') if os.path.exists(res_path) else ['// %s custom resources' % NAME]
    extra = [f'models/vexmira/dust/{n}.mdl' for n in dict.fromkeys([p[0] for p in PROPS] + ['dust_xbarrel'])]
    extra += list(dict.fromkeys(p[0] for p in DECOR))
    extra = [p for p in extra if p not in have]
    for p in extra:
        assert os.path.exists(os.path.join(REPO, 'cstrike', p)), p
    with open(res_path, 'w', newline='\n') as fh:
        fh.write('\n'.join([h for h in have if h] + extra) + '\n')
    return extra


def verify_props(bsp_path):
    import numpy as np
    from ..bspcheck import BSP
    b = BSP(bsp_path)
    bad = []
    for label, x, y, ztop in STAND:
        free = b.point_contents(np.array([x, y, ztop + 37.0]), 1) != -2
        rest = b.point_contents(np.array([x, y, ztop + 34.0]), 1) == -2
        print(f'  stand {label:13s} ({x} {y} {ztop}): free={free} rests={rest}')
        if not (free and rest):
            bad.append(label)
    return bad


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--quality', default='final')
    ap.add_argument('--out', default=os.path.join(REPO, 'cstrike', 'maps'))
    ap.add_argument('--dry', action='store_true')
    a = ap.parse_args(argv)
    m = build()
    print('spawn check:', m.spawn_problems() or 'OK', m.stats())
    if a.dry:
        return 0
    write_ini_models()
    from ..compile import compile_map
    r = compile_map(m, a.quality, a.out, perf={'warn_p95': 650, 'error_max': 1000})
    print(r.summary())
    if r.bsp:
        print('res extra:', write_res_extra(os.path.join(a.out, NAME + '.res')))
        print('prop stand problems:', verify_props(r.bsp) or 'none')
    return 0 if r.ok else 1


if __name__ == '__main__':
    sys.exit(main())
