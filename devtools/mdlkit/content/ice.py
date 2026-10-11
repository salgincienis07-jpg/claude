"""zm_vexmira_ice props (owner request 2026-10-11): frozen cargo trucks, a jeep, barrels, a generator, a
rotating radar dish and campfire logs. Spawned by the plugin from the map ini [models] section (not solid:
the map has CLIP brushes where players collide). Small: 128-256 px textures, < 150 KB each.
Fixed file names (models/vexmira/ice/ice_*.mdl) so the owner can drop in replacement models later.

    cd devtools
    python3 -m mdlkit build mdlkit.content.ice:all

Contracts (origin = bottom centre, front toward +X, z up):
  ice_truck     cargo truck 320 x 112 x 150 (cab at +X), snow on the roof/box, icicles. map clip 320 x 112 x 144
  ice_jeep      jeep 176 x 84 x 76, snow on hood/roof.                                  map clip 176 x 84 x 72
  ice_barrel    oil drum r 15, h 44 (snow cap).                                         map clip 32 x 32 x 44
  ice_generator diesel generator skid 96 x 56 x 64, exhaust stack, panel lights.        map clip 96 x 56 x 64
  ice_radar     radar dish on a short pedestal, seq 0 'spin' (looped, 4 s / turn), r 56, h 112 (on a roof)
  ice_logs      campfire: log tepee + stone ring, r 40, h 30 (fire = env_sprite in the map)
  ice_tank      fuel tank 192 x 88 x 104 (axis X)                                       map clip 192 x 88 x 104
  ice_crate     wooden crate 56^3;  ice_cratem military crate 64 x 40 x 36              map clip = size
  ice_lamp      street lamp, 176 pole, lamp head at +X 40 (z 178)                        map clip 16 x 16 pole
  ice_fence     fence segment x 0..128, 48 tall                                          map clip 128 x 8 x 56
  ice_antenna   lattice radio mast 360 tall (on a roof / corner)                         map clip 40 x 40
  ice_sled      snowmobile 130 x 48 x 52                                                  map clip 128 x 48 x 40
"""
import math
import os

from . import *          # noqa: F401,F403
from .cordon import hull, slab

AREA = 'ice'


def _out(name):
    return os.path.join(CSTRIKE, 'models/vexmira/ice', name + '.mdl')


SNOW = {'type': 'cloth', 'color': (232, 238, 248), 'weave': 0.0, 'dirt': 0.08, 'seed': 2001}
ICE = {'type': 'crystal', 'color': (170, 215, 245), 'seed': 2002}


def _icicles(x0, x1, y, z, n, mat='ic_ice', ln=10.0, seed=1):
    out = []
    for k in range(n):
        x = x0 + (x1 - x0) * (k + 0.5) / n
        L = ln * (0.6 + 0.4 * math.sin(k * 2.3 + seed))
        out.append(cone((x, y, z), (x, y, z - L), 1.8, segs=5, mat=mat))
    return out


# ============================================================================================ truck
def truck():
    mats = {'tr_body': metal((52, 74, 60), seed=2101, paint=(56, 78, 62), panels=20.0, chipping=0.35, edge_wear=0.7,
                             scratches=0.4, shine=0.2),
            'tr_box': metal((88, 92, 84), seed=2102, panels=16.0, chipping=0.2, scratches=0.3, rust=0.2),
            'tr_dark': metal((34, 36, 38), seed=2103, scratches=0.3, shine=0.2),
            'tr_tire': {'type': 'rubber', 'color': (30, 30, 32), 'seed': 2104},
            'tr_glass': {'type': 'visor', 'color': (60, 90, 110), 'color2': (200, 225, 240)},
            'tr_lamp': glow((255, 235, 190)), 'tr_red': glow((255, 40, 30)),
            'ic_snow': SNOW, 'ic_ice': ICE}
    L, W = 320.0, 112.0
    x0, x1 = -L / 2, L / 2
    P = [slab(x0 + 10, x1 - 10, -40, 40, 20, 34, 'tr_dark', 'chassis'),
         # cargo box (rear)
         slab(x0, x1 - 96, -W / 2, W / 2, 36, 144, 'tr_box', 'box'),
         # cab
         hull([(x1 - 92, -52, 34), (x1 - 92, 52, 34), (x1 - 4, -52, 34), (x1 - 4, 52, 34),
               (x1 - 92, -50, 128), (x1 - 92, 50, 128), (x1 - 34, -48, 128), (x1 - 34, 48, 128),
               (x1 - 4, -52, 80), (x1 - 4, 52, 80)], 'tr_body', 'cab'),
         hull([(x1 - 33, -42, 84), (x1 - 33, 42, 84), (x1 - 31, -40, 124), (x1 - 31, 40, 124),
               (x1 - 6, -42, 84), (x1 - 6, 42, 84)], 'tr_glass', 'windscreen'),
         slab(x1 - 4, x1, -40, 40, 40, 70, 'tr_dark', 'grille'),
         slab(x1 - 2, x1 + 6, -54, 54, 30, 42, 'tr_dark', 'bumper')]
    for sy in (1, -1):
        P.append(slab(x1 - 80, x1 - 44, sy * 52.5 - 0.6, sy * 52.5 + 0.6, 84, 118, 'tr_glass', 'side_win'))
        P.append(rod((x1, sy * 34, 58), (x1 + 2, sy * 34, 58), 7, mat='tr_lamp', name='headlight', segs=10))
        P.append(slab(x0 - 1, x0 + 1, sy * 44 - 6, sy * 44 + 6, 44, 52, 'tr_red', 'taillight'))
        for xw in (x1 - 60, x0 + 70, x0 + 30):
            P.append(rod((xw, sy * 42, 22), (xw, sy * 58, 22), 22, mat='tr_tire', name='wheel', segs=12))
            P.append(rod((xw, sy * 57, 22), (xw, sy * 59, 22), 10, mat='tr_dark', name='hub', segs=8))
        P.append(slab(x1 - 90, x1 - 30, sy * 56 - 4, sy * 56 + 4, 44, 50, 'tr_dark', 'step'))
        P += _icicles(x0 + 6, x1 - 100, sy * (W / 2 + 0.5), 143, 9, seed=sy + 3)
    # snow: drift on the box roof + cab roof + hood, a bank against the left wheels
    P.append(hull([(x0 + 4, -W / 2 + 2, 144), (x0 + 4, W / 2 - 2, 144), (x1 - 100, -W / 2 + 2, 144),
                   (x1 - 100, W / 2 - 2, 144), (x0 + 20, -30, 156), (x0 + 20, 30, 154), (x1 - 116, -28, 152),
                   (x1 - 116, 26, 155)], 'ic_snow', 'snow_box'))
    P.append(hull([(x1 - 90, -46, 128), (x1 - 90, 46, 128), (x1 - 36, -44, 128), (x1 - 36, 44, 128),
                   (x1 - 80, -20, 136), (x1 - 80, 20, 135), (x1 - 46, 0, 134)], 'ic_snow', 'snow_cab'))
    P.append(hull([(x0 + 10, 56, 0), (x1 - 20, 56, 0), (x0 + 30, 72, 0), (x1 - 40, 74, 0),
                   (x0 + 40, 58, 22), (x1 - 60, 58, 18)], 'ic_snow', 'snow_bank'))
    for m in P:
        m.detail = 0.12
    dec = [dict(kind='shape', shape='vex', center=(-40, sy * (W / 2), 96), u=(1, 0, 0), v=(0, 0, 1), size=22,
                color=(160, 90, 255), depth=6, soft=0.4, facing=(0, sy, 0)) for sy in (1, -1)]
    return dict(kind='world', name='ice_truck', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                decals=dec, tex=(256, 256), out=_out('ice_truck'), preview_area=AREA, budget=0.15e6)


# ============================================================================================ jeep
def jeep():
    mats = {'jp_body': metal((70, 78, 58), seed=2201, paint=(72, 80, 60), panels=14.0, chipping=0.3, edge_wear=0.6,
                             scratches=0.4, shine=0.2),
            'jp_dark': metal((32, 33, 35), seed=2202, scratches=0.3),
            'jp_tire': {'type': 'rubber', 'color': (30, 30, 32), 'seed': 2203},
            'jp_glass': {'type': 'visor', 'color': (60, 90, 110), 'color2': (200, 225, 240)},
            'jp_lamp': glow((255, 235, 190)), 'ic_snow': SNOW, 'ic_ice': ICE}
    L, W = 176.0, 84.0
    x0, x1 = -L / 2, L / 2
    P = [hull([(x0, -W / 2, 18), (x0, W / 2, 18), (x1, -W / 2, 18), (x1, W / 2, 18),
               (x0, -W / 2, 50), (x0, W / 2, 50), (x1 - 4, -W / 2 + 2, 50), (x1 - 4, W / 2 - 2, 50)], 'jp_body', 'tub'),
         hull([(x1 - 64, -W / 2 + 2, 50), (x1 - 64, W / 2 - 2, 50), (x1 - 4, -W / 2 + 4, 50), (x1 - 4, W / 2 - 4, 50),
               (x1 - 64, -W / 2 + 4, 58), (x1 - 64, W / 2 - 4, 58), (x1 - 8, -W / 2 + 6, 56), (x1 - 8, W / 2 - 6, 56)],
              'jp_body', 'hood'),
         slab(x1 - 70, x1 - 66, -W / 2 + 4, W / 2 - 4, 50, 78, 'jp_glass', 'windscreen'),
         slab(x0 + 6, x1 - 66, -W / 2 + 2, W / 2 - 2, 72, 76, 'jp_dark', 'roof'),
         slab(x1, x1 + 6, -W / 2, W / 2, 20, 30, 'jp_dark', 'bumper'),
         rod((x0 - 4, 0, 40), (x0 - 4, 0, 40.1), 13, mat='jp_tire', name='spare', segs=10),
         slab(x0 - 10, x0 - 4, -10, 10, 28, 52, 'jp_tire', 'spare_tire')]
    for sy in (1, -1):
        P.append(rod((x0 + 8, sy * (W / 2 - 3), 50), (x0 + 8, sy * (W / 2 - 3), 72), 1.5, mat='jp_dark', name='post', segs=6))
        P.append(rod((x1 - 2, sy * 26, 44), (x1 + 2, sy * 26, 44), 6, mat='jp_lamp', name='headlight', segs=10))
        for xw in (x1 - 34, x0 + 34):
            P.append(rod((xw, sy * 34, 17), (xw, sy * 46, 17), 17, mat='jp_tire', name='wheel', segs=12))
        P += _icicles(x0 + 10, x1 - 70, sy * (W / 2 - 1), 72, 5, seed=sy)
    P.append(hull([(x0 + 8, -38, 76), (x0 + 8, 38, 76), (x1 - 68, -38, 76), (x1 - 68, 38, 76),
                   (x0 + 24, -18, 84), (x0 + 24, 18, 83), (x1 - 80, 0, 82)], 'ic_snow', 'snow_roof'))
    P.append(hull([(x1 - 62, -34, 57), (x1 - 62, 34, 57), (x1 - 10, -32, 56), (x1 - 10, 32, 56),
                   (x1 - 50, 0, 63)], 'ic_snow', 'snow_hood'))
    for m in P:
        m.detail = 0.15
    return dict(kind='world', name='ice_jeep', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(256, 128), out=_out('ice_jeep'), preview_area=AREA, budget=0.1e6)


# ============================================================================================ barrel
def barrel():
    mats = {'br_drum': metal((150, 50, 30), seed=2301, paint=(160, 54, 32), chipping=0.4, rust=0.4, scratches=0.4),
            'br_band': metal((90, 40, 26), seed=2302, rust=0.5), 'ic_snow': SNOW, 'ic_ice': ICE}
    P = [rod((0, 0, 0), (0, 0, 44), 15, mat='br_drum', name='drum', segs=12)]
    for z in (12, 30):
        P.append(rod((0, 0, z - 1.5), (0, 0, z + 1.5), 15.6, mat='br_band', name='band', segs=12))
    P.append(rod((0, 0, 44), (0, 0, 47), 14, r1=9, mat='ic_snow', name='snowcap', segs=12))
    for m in P:
        m.detail = 0.4
    dec = [dict(kind='shape', shape='vex', center=(15, 0, 22), u=(0, 1, 0), v=(0, 0, 1), size=6,
                color=(240, 220, 40), depth=4, soft=0.3, facing=(1, 0, 0))]
    return dict(kind='world', name='ice_barrel', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                decals=dec, tex=(128, 64), out=_out('ice_barrel'), preview_area=AREA, budget=0.03e6)


# ============================================================================================ generator
def generator():
    mats = {'gn_body': metal((200, 160, 30), seed=2401, paint=(210, 168, 34), panels=10.0, chipping=0.3,
                             edge_wear=0.6, scratches=0.4),
            'gn_dark': metal((36, 38, 40), seed=2402, scratches=0.3, rust=0.2),
            'gn_grill': metal((60, 62, 64), seed=2403, panels=4.0),
            'gn_green': glow((60, 255, 90)), 'gn_red': glow((255, 40, 30)), 'ic_snow': SNOW, 'ic_ice': ICE}
    P = [slab(-48, 48, -28, 28, 0, 8, 'gn_dark', 'skid'),
         slab(-44, 44, -26, 26, 8, 56, 'gn_body', 'housing'),
         slab(-40, -20, -26.6, 26.6, 16, 48, 'gn_grill', 'grille'),
         slab(10, 36, -27, -26, 26, 48, 'gn_dark', 'panel'),
         slab(14, 18, -27.6, -27, 40, 44, 'gn_green', 'led_on'),
         slab(22, 26, -27.6, -27, 40, 44, 'gn_red', 'led_fault'),
         rod((30, 14, 56), (30, 14, 76), 3.5, mat='gn_dark', name='exhaust', segs=8),
         hull([(-42, -24, 56), (-42, 24, 56), (42, -24, 56), (42, 24, 56), (-20, -8, 62), (10, 10, 63)],
              'ic_snow', 'snow')]
    P += _icicles(-40, 40, -26.5, 56, 7, ln=7)
    for m in P:
        m.detail = 0.3
    return dict(kind='world', name='ice_generator', parts=P, sequences=[dict(name='idle', frames=1)],
                materials=mats, tex=(128, 128), out=_out('ice_generator'), preview_area=AREA, budget=0.05e6)


# ============================================================================================ radar
def radar():
    mats = {'rd_base': metal((120, 124, 130), seed=2501, scratches=0.4, rust=0.15),
            'rd_dish': metal((215, 218, 222), seed=2502, panels=12.0, scratches=0.2, shine=0.4),
            'rd_dark': metal((40, 42, 46), seed=2503), 'rd_red': glow((255, 40, 30)), 'ic_snow': SNOW, 'ic_ice': ICE}
    base = [rod((0, 0, 0), (0, 0, 8), 24, r1=20, mat='rd_base', name='plinth', segs=12),
            rod((0, 0, 8), (0, 0, 60), 6, mat='rd_base', name='mast', segs=10)]
    bones = [Bone('root'), Bone('head', 'root', (0, 0, 60))]
    # dish: shallow bowl facing +X, tilted up 20 deg, on a yoke
    prof = [(0.0, 2.0), (6.0, 24.0), (12.0, 40.0), (16.0, 52.0), (13.0, 53.0), (9.0, 40.0), (3.0, 24.0), (-3.0, 2.0)]
    dish = lathe(prof, axis_start=(-8, 0, 92), axis_dir=(math.cos(math.radians(20)), 0, math.sin(math.radians(20))),
                 segs=16, mat='rd_dish', cap_start=True, cap_end=True, name='dish')
    head = [dish, slab(-14, 6, -8, 8, 60, 84, 'rd_dark', 'yoke'),
            rod((-6, 0, 92), (28, 0, 104), 2, mat='rd_dark', name='feed', segs=6),
            rod((28, 0, 104), (31, 0, 105), 4, mat='rd_red', name='feed_lamp', segs=8)]
    head = on('head', *head)
    for m in base + head:
        m.detail = 0.3

    def spin(t):
        return {'head': dict(rot=(360.0 * t, 0, 0))}
    return dict(kind='world', name='ice_radar', parts=base + head, bones=bones,
                sequences=[dict(name='spin', frames=41, fps=10, loop=True, pose=spin)], materials=mats,
                tex=(128, 128), out=_out('ice_radar'), preview_area=AREA, budget=0.06e6)


# ============================================================================================ campfire logs
def logs():
    mats = {'lg_wood': {'type': 'leather', 'color': (92, 62, 38), 'seed': 2601},
            'lg_char': {'type': 'leather', 'color': (30, 24, 20), 'seed': 2602},
            'lg_stone': {'type': 'bone', 'color': (120, 122, 126), 'seed': 2603},
            'lg_ember': glow((255, 120, 30), (255, 210, 120))}
    P = []
    for k in range(6):
        a = k * math.pi / 3
        P.append(rod((math.cos(a) * 24, math.sin(a) * 24, 2), (math.cos(a) * 3, math.sin(a) * 3, 28), 3.2,
                     mat='lg_wood' if k % 2 else 'lg_char', name='log', segs=6))
    for k in range(10):
        a = k * math.pi / 5
        P.append(sphere(6.5, center=(math.cos(a) * 34, math.sin(a) * 34, 3), segs=6, rings=4, mat='lg_stone'))
    P.append(rod((0, 0, 0), (0, 0, 3), 18, mat='lg_ember', name='embers', segs=10))
    for m in P:
        m.detail = 0.4
    return dict(kind='world', name='ice_logs', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(128, 64), out=_out('ice_logs'), preview_area=AREA, budget=0.03e6)


# ============================================================================================ fuel tank
def tank():
    """Horizontal fuel tank on two saddles: 192 x 88 x 104, origin bottom centre, axis along X."""
    mats = {'tk_body': metal((196, 198, 192), seed=2701, paint=(200, 202, 196), panels=30.0, chipping=0.25, rust=0.25,
                             edge_wear=0.5, scratches=0.3),
            'tk_dark': metal((50, 52, 54), seed=2702, rust=0.3), 'tk_rust': metal((120, 70, 40), seed=2703, rust=0.7),
            'ic_snow': SNOW, 'ic_ice': ICE}
    P = [rod((-88, 0, 58), (88, 0, 58), 40, mat='tk_body', name='shell', segs=16)]
    for sx in (-1, 1):
        P.append(lathe([(0, 40), (6, 36), (10, 24), (12, 2)], axis_start=(sx * 88, 0, 58), axis_dir=(sx, 0, 0), segs=16,
                       mat='tk_body', cap_start=False, name='dome'))
        P.append(slab(sx * 56 - 8, sx * 56 + 8, -38, 38, 0, 30, 'tk_dark', 'saddle'))
        P.append(rod((sx * 56, 0, 58), (sx * 56 + 0.1, 0, 58), 41, mat='tk_rust', name='band', segs=16))
        P.append(slab(sx * 56 - 1.5, sx * 56 + 1.5, -41, 41, 56, 60, 'tk_rust', 'strap'))
    P += [rod((20, 0, 96), (20, 0, 108), 9, mat='tk_dark', name='manhole', segs=12),
          rod((-40, 0, 96), (-40, 0, 112), 2.5, mat='tk_dark', name='vent', segs=6),
          rod((-60, -30, 30), (-60, -50, 20), 3, mat='tk_dark', name='valve', segs=8),
          hull([(-80, -24, 96), (-80, 24, 96), (80, -24, 96), (80, 24, 96), (-60, -10, 104), (60, 12, 103)],
               'ic_snow', 'snow')]
    for k in range(5):
        P.append(slab(70 - 1, 70 + 1, -38 - 0.5, -38 + 0.5, 14 + k * 16, 16 + k * 16, 'tk_dark', 'rung'))
    P += _icicles(-80, 80, -30, 82, 8, ln=8)
    for m in P:
        m.detail = 0.3
    dec = [dict(kind='shape', shape='vex', center=(0, -40, 60), u=(1, 0, 0), v=(0, 0, 1), size=18,
                color=(160, 90, 255), depth=6, soft=0.4, facing=(0, -1, 0)),
           dict(kind='sphere', center=(-70, -30, 20), radius=40, soft=1.0, color=(80, 40, 20), mode='multiply', alpha=0.5)]
    return dict(kind='world', name='ice_tank', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                decals=dec, tex=(256, 128), out=_out('ice_tank'), preview_area=AREA, budget=0.06e6)


# ============================================================================================ crates
def _crate(name, sx, sy, sz, wood):
    if wood:
        mats = {'cr_plank': {'type': 'leather', 'color': (150, 112, 70), 'seed': 2801},
                'cr_frame': {'type': 'leather', 'color': (110, 78, 46), 'seed': 2802}, 'ic_snow': SNOW, 'ic_ice': ICE}
    else:
        mats = {'cr_plank': metal((72, 82, 54), seed=2803, paint=(74, 84, 56), panels=8.0, chipping=0.3, edge_wear=0.7),
                'cr_frame': metal((44, 48, 40), seed=2804, edge_wear=0.5), 'ic_snow': SNOW, 'ic_ice': ICE}
    hx, hy = sx / 2, sy / 2
    P = [bx((sx - 4, sy - 4, sz - 2), (0, 0, (sz - 2) / 2), 'cr_plank', 'body', bevel=0.6)]
    e = 4.0
    for z in (e / 2, sz - 2 - e / 2):          # frame edges
        P.append(bx((sx, e, e), (0, -hy + e / 2, z), 'cr_frame', 'edge', 0.3))
        P.append(bx((sx, e, e), (0, hy - e / 2, z), 'cr_frame', 'edge', 0.3))
        P.append(bx((e, sy, e), (-hx + e / 2, 0, z), 'cr_frame', 'edge', 0.3))
        P.append(bx((e, sy, e), (hx - e / 2, 0, z), 'cr_frame', 'edge', 0.3))
    for xx in (-hx + e / 2, hx - e / 2):
        for yy in (-hy + e / 2, hy - e / 2):
            P.append(bx((e, e, sz - 2), (xx, yy, (sz - 2) / 2), 'cr_frame', 'post', 0.3))
    if wood:                                   # diagonal braces on the long sides
        for sg in (1, -1):
            P.append(hull([(-hx + 6, sg * (hy + 0.5), 6), (-hx + 12, sg * (hy + 0.5), 6), (hx - 6, sg * (hy + 0.5), sz - 10),
                           (hx - 12, sg * (hy + 0.5), sz - 10), (-hx + 6, sg * (hy - 1.5), 6),
                           (hx - 6, sg * (hy - 1.5), sz - 10)], 'cr_frame', 'brace'))
    P.append(hull([(-hx + 2, -hy + 2, sz - 2), (hx - 2, -hy + 2, sz - 2), (-hx + 2, hy - 2, sz - 2), (hx - 2, hy - 2, sz - 2),
                   (-hx / 2, -hy / 3, sz + 3), (hx / 3, hy / 4, sz + 4)], 'ic_snow', 'snow'))
    for m in P:
        m.detail = 0.4
    dec = [] if wood else [dict(kind='shape', shape='vex', center=(0, -hy, sz / 2), u=(1, 0, 0), v=(0, 0, 1), size=8,
                                color=(230, 230, 210), depth=4, soft=0.3, facing=(0, -1, 0))]
    return dict(kind='world', name=name, parts=P, sequences=[dict(name='idle', frames=1)], materials=mats, decals=dec,
                tex=(128, 128), out=_out(name), preview_area=AREA, budget=0.04e6)


def crate_wood():
    """Wooden supply crate 56 x 56 x 56 with frame + braces + snow cap (map clip 56^3)."""
    return _crate('ice_crate', 56, 56, 56, True)


def crate_mil():
    """Military ammo crate 64 x 40 x 36, olive, VEX stencil (map clip 64 x 40 x 36)."""
    return _crate('ice_cratem', 64, 40, 36, False)


# ============================================================================================ lamp post
def lamppost():
    """Street lamp: 176 tall pole, arm toward +X with a lamp head (glow) at x 40, z 168. Origin = foot."""
    mats = {'lp_pole': metal((52, 56, 62), seed=2901, scratches=0.3, edge_wear=0.4, rust=0.15),
            'lp_lamp': glow((255, 236, 190), (255, 250, 235)), 'ic_snow': SNOW, 'ic_ice': ICE}
    P = [rod((0, 0, 0), (0, 0, 10), 7, r1=5, mat='lp_pole', name='foot', segs=10),
         rod((0, 0, 10), (0, 0, 176), 3, r1=2.4, mat='lp_pole', name='pole', segs=10),
         tube([(0, 0, 170), (10, 0, 178), (30, 0, 180), (40, 0, 178)], [2.0, 2.0, 2.0, 2.0], segs=8, mat='lp_pole',
              name='arm'),
         hull([(28, -9, 178), (52, -9, 178), (28, 9, 178), (52, 9, 178), (32, -6, 184), (48, -6, 184), (32, 6, 184),
               (48, 6, 184)], 'lp_pole', 'head'),
         slab(30, 50, -7, 7, 176, 178, 'lp_lamp', 'lens'),
         hull([(30, -8, 184), (50, -8, 184), (30, 8, 184), (50, 8, 184), (40, 0, 188)], 'ic_snow', 'snow')]
    P += _icicles(30, 50, -9, 178, 3, ln=6)
    for m in P:
        m.detail = 0.4
    return dict(kind='world', name='ice_lamp', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(64, 64), out=_out('ice_lamp'), preview_area=AREA, budget=0.03e6)


# ============================================================================================ fence
def fence():
    """Wooden post-and-rail fence segment, 128 long along X (x 0..128), 48 tall, snow on the rails."""
    mats = {'fc_wood': {'type': 'leather', 'color': (120, 92, 62), 'seed': 3001}, 'ic_snow': SNOW, 'ic_ice': ICE}
    P = []
    for x in (4, 64, 124):
        P.append(bx((6, 6, 50), (x, 0, 25), 'fc_wood', 'post', 0.5))
        P.append(hull([(x - 3, -3, 50), (x + 3, -3, 50), (x - 3, 3, 50), (x + 3, 3, 50), (x, 0, 54)], 'ic_snow', 'cap'))
    for z in (18, 38):
        P.append(bx((128, 3, 6), (64, 0, z), 'fc_wood', 'rail', 0.4))
        P.append(bx((124, 3.4, 1.6), (64, 0, z + 3.6), 'ic_snow', 'snow', 0.6))
    for m in P:
        m.detail = 0.4
    return dict(kind='world', name='ice_fence', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(128, 128), out=_out('ice_fence'), preview_area=AREA, budget=0.03e6)


# ============================================================================================ antenna mast
def antenna():
    """Lattice radio mast 320 tall (3 legs, cross bracing), blinking-red top lamp (glow), small dishes."""
    mats = {'an_steel': metal((170, 60, 50), seed=3101, paint=(180, 64, 52), scratches=0.3, rust=0.3),
            'an_white': metal((220, 220, 216), seed=3102, scratches=0.2),
            'an_red': glow((255, 30, 20), (255, 150, 130)), 'ic_snow': SNOW, 'ic_ice': ICE}
    H, R = 320.0, 18.0
    legs = [(R * math.cos(a), R * math.sin(a)) for a in (0, 2 * math.pi / 3, 4 * math.pi / 3)]
    top = [(x * 0.35, y * 0.35) for x, y in legs]
    P = []
    for (x0, y0), (x1, y1) in zip(legs, top):
        P.append(rod((x0, y0, 0), (x1, y1, H), 1.6, mat='an_steel', name='leg', segs=5))
    n = 8
    for k in range(n):
        za, zb = H * k / n, H * (k + 1) / n
        fa, fb = 1 - 0.65 * k / n, 1 - 0.65 * (k + 1) / n
        for i in range(3):
            (xa, ya), (xb, yb) = legs[i], legs[(i + 1) % 3]
            P.append(rod((xa * fa, ya * fa, za), (xb * fb, yb * fb, zb), 0.8, mat='an_white' if k % 2 else 'an_steel',
                         name='brace', segs=4))
    P += [rod((0, 0, H), (0, 0, H + 40), 1.2, mat='an_white', name='whip', segs=5),
          rod((0, 0, H + 40), (0, 0, H + 44), 3, mat='an_red', name='lamp', segs=8)]
    for z, yaw in ((200, 0.4), (250, 2.5)):
        c = (math.cos(yaw) * 10, math.sin(yaw) * 10, z)
        P.append(lathe([(0, 1), (3, 9), (5, 13)], axis_start=c, axis_dir=(math.cos(yaw), math.sin(yaw), 0), segs=10,
                       mat='an_white', name='dish'))
    for m in P:
        m.detail = 0.3
    return dict(kind='world', name='ice_antenna', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(128, 128), out=_out('ice_antenna'), preview_area=AREA, budget=0.05e6)


# ============================================================================================ snowmobile
def snowmobile():
    """Snowmobile 120 x 48 x 48 (front skis at +X), origin bottom centre."""
    mats = {'sm_body': metal((40, 120, 220), seed=3201, paint=(40, 120, 225), panels=6.0, shine=0.5, edge_wear=0.4),
            'sm_dark': metal((30, 30, 34), seed=3202, scratches=0.3),
            'sm_seat': {'type': 'leather', 'color': (30, 30, 32), 'seed': 3203},
            'sm_glass': {'type': 'visor', 'color': (60, 90, 110), 'color2': (200, 225, 240)},
            'sm_lamp': glow((255, 240, 200)), 'ic_snow': SNOW, 'ic_ice': ICE}
    P = [hull([(-50, -18, 8), (-50, 18, 8), (40, -20, 10), (40, 20, 10), (60, -14, 20), (60, 14, 20),
               (-50, -18, 22), (-50, 18, 22), (30, -20, 34), (30, 20, 34), (52, -12, 30), (52, 12, 30)], 'sm_body', 'hood'),
         hull([(-56, -14, 4), (-56, 14, 4), (10, -14, 4), (10, 14, 4), (-56, -14, 16), (-56, 14, 16),
               (14, -14, 14), (14, 14, 14), (-60, -14, 10), (-60, 14, 10)], 'sm_dark', 'track'),
         hull([(-46, -12, 22), (-46, 12, 22), (0, -12, 22), (0, 12, 22), (-44, -11, 32), (-44, 11, 32),
               (-4, -11, 30), (-4, 11, 30)], 'sm_seat', 'seat'),
         hull([(22, -16, 34), (22, 16, 34), (30, -18, 34), (30, 18, 34), (14, -14, 52), (14, 14, 52)], 'sm_glass',
              'windshield'),
         tube([(14, 0, 34), (8, 0, 42)], [1.4, 1.4], segs=6, mat='sm_dark', name='bar_post'),
         rod((8, -20, 42), (8, 20, 42), 1.3, mat='sm_dark', name='handlebar', segs=6),
         rod((60, 0, 22), (63, 0, 22), 4, mat='sm_lamp', name='headlight', segs=8)]
    for sy in (1, -1):
        P.append(tube([(10, sy * 22, 2), (58, sy * 22, 2), (70, sy * 22, 10)], [1.8, 1.8, 1.8], segs=6, mat='sm_dark',
                      name='ski'))
        P.append(rod((40, sy * 16, 12), (40, sy * 22, 3), 1.6, mat='sm_dark', name='strut', segs=6))
    P.append(hull([(-44, -10, 32), (-44, 10, 32), (-6, -10, 30), (-6, 10, 30), (-26, 0, 36)], 'ic_snow', 'snow'))
    for m in P:
        m.detail = 0.3
    dec = [dict(kind='shape', shape='vex', center=(20, sy * 20, 24), u=(1, 0, 0), v=(0, 0, 1), size=7,
                color=(240, 240, 255), depth=4, soft=0.3, facing=(0, sy, 0)) for sy in (1, -1)]
    return dict(kind='world', name='ice_sled', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                decals=dec, tex=(128, 128), out=_out('ice_sled'), preview_area=AREA, budget=0.04e6)


def extra():
    return [tank(), crate_wood(), crate_mil(), lamppost(), fence(), antenna(), snowmobile()]


def all():   # noqa: A001
    return [truck(), jeep(), barrel(), generator(), radar(), logs()] + extra()
