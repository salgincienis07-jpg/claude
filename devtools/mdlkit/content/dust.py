"""zm_vexmira_dust props: sun-bleached desert town set. Spawned by the plugin from the map ini [models] (not solid;
the map adds tight prop-shaped CLIP brushes so every prop can be climbed / stood on). Small textures (<= 256 px).

    cd devtools
    python3 -m mdlkit build mdlkit.content.dust:all

Contracts (origin = bottom centre, front toward +X, z up; map clip boxes in maps/zm_vexmira_dust.py CLIPS):
  dust_pickup    pickup truck 200 x 84 x 78: bed x -100..12 (rail top 46), cab x 12..76 (roof 78), hood x 76..100 (52)
  dust_wreck     rusted car wreck 176 x 76: body top 36, cabin x -40..30 roof 58
  dust_cart      wooden cart 150 x 72: bed x -60..60 top 42 with sacks, wheels r 30, shafts toward +X
  dust_palm      palm tree ~300 tall (trunk leans toward +X), fronds
  dust_stall     market stall 128 x 80: counter 40 high (y -40..0), striped awning flat top 106 (x -64..64, y -40..40)
  dust_tower     water tower: 4 legs, tank r 48 z 176..256 (flat top 256), rungs on +X side (x 50)
  dust_barrel    oil drum r 15 h 44;  dust_xbarrel  red DANGER explosive drum (no snow)
  dust_sandbag   sandbag wall 96 x 32 x 40 (along X)
  dust_crate     wooden crate 56^3
  dust_dish      satellite dish on a 64 pole (dish faces +X)
  dust_lantern   hanging lantern (origin = hook point, hangs 30 down, glowing glass)
"""
import math
import os

from . import *          # noqa: F401,F403
from .cordon import hull, slab

AREA = 'dust'


def _out(name):
    return os.path.join(CSTRIKE, 'models/vexmira/dust', name + '.mdl')


DUSTY = {'type': 'cloth', 'color': (200, 170, 120), 'weave': 0.0, 'dirt': 0.5, 'seed': 5001}


def _wheel(P, x, y, z, r, w, sy, tire='tire', hub='hub'):
    P.append(rod((x, y, z), (x, y + sy * w, z), r, mat=tire, name='wheel', segs=12))
    P.append(rod((x, y + sy * (w - 0.5), z), (x, y + sy * (w + 1), z), r * 0.5, mat=hub, name='hub', segs=8))


# ============================================================================================ pickup
def pickup():
    mats = {'pk_body': metal((196, 150, 90), seed=5101, paint=(200, 152, 92), panels=14.0, chipping=0.5, rust=0.35,
                             edge_wear=0.7, scratches=0.5, shine=0.15),
            'pk_dark': metal((40, 36, 32), seed=5102, rust=0.3), 'tire': {'type': 'rubber', 'color': (34, 32, 30), 'seed': 5103},
            'hub': metal((120, 116, 110), seed=5104, rust=0.4),
            'pk_glass': {'type': 'visor', 'color': (90, 110, 120), 'color2': (230, 220, 200)},
            'pk_lamp': glow((255, 235, 190)), 'dust': DUSTY}
    P = [slab(-100, 100, -38, 38, 16, 26, 'pk_dark', 'chassis'),
         slab(-100, 12, -42, 42, 26, 34, 'pk_body', 'bed_floor'),
         slab(-100, 12, -42, -38, 34, 46, 'pk_body', 'bed_side'), slab(-100, 12, 38, 42, 34, 46, 'pk_body', 'bed_side'),
         slab(-100, -96, -38, 38, 34, 46, 'pk_body', 'tailgate'),
         hull([(12, -42, 26), (12, 42, 26), (76, -42, 26), (76, 42, 26), (12, -40, 76), (12, 40, 76), (50, -38, 78),
               (50, 38, 78), (76, -42, 52), (76, 42, 52)], 'pk_body', 'cab'),
         hull([(52, -36, 56), (52, 36, 56), (54, -34, 74), (54, 34, 74), (72, -36, 54), (72, 36, 54)], 'pk_glass', 'wind'),
         hull([(76, -42, 26), (76, 42, 26), (100, -40, 26), (100, 40, 26), (76, -41, 52), (76, 41, 52), (98, -38, 48),
               (98, 38, 48)], 'pk_body', 'hood'),
         slab(100, 106, -42, 42, 22, 32, 'pk_dark', 'bumper'),
         hull([(-90, -30, 34), (-90, 30, 34), (-20, -30, 34), (-20, 30, 34), (-70, -10, 40), (-40, 12, 41)], 'dust', 'sand_in_bed')]
    for sy in (1, -1):
        P.append(slab(18, 46, sy * 41.5 - 0.5, sy * 41.5 + 0.5, 54, 72, 'pk_glass', 'side_win'))
        P.append(rod((100, sy * 30, 42), (102, sy * 30, 42), 5, mat='pk_lamp', name='headlight', segs=8))
        for xw in (70, -70):
            _wheel(P, xw, sy * 34, 16, 16, 10, sy)
    for m in P:
        m.detail = 0.15
    dec = [dict(kind='sphere', center=(30, 42, 40), radius=30, soft=1.0, color=(110, 60, 30), mode='multiply', alpha=0.6),
           dict(kind='shape', shape='vex', center=(40, -42, 40), u=(1, 0, 0), v=(0, 0, 1), size=8, color=(160, 90, 255),
                depth=4, soft=0.4)]
    return dict(kind='world', name='dust_pickup', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                decals=dec, tex=(256, 128), out=_out('dust_pickup'), preview_area=AREA, budget=0.08e6)


# ============================================================================================ wreck
def wreck():
    mats = {'wr_body': metal((130, 70, 40), seed=5201, paint=(150, 90, 60), chipping=0.8, rust=0.8, edge_wear=0.8),
            'wr_dark': metal((36, 30, 26), seed=5202, rust=0.6), 'tire': {'type': 'rubber', 'color': (30, 28, 26), 'seed': 5203},
            'hub': metal((90, 70, 50), seed=5204, rust=0.8), 'dust': DUSTY}
    P = [hull([(-88, -38, 8), (-88, 38, 8), (88, -38, 8), (88, 38, 8), (-86, -36, 34), (-86, 36, 34), (86, -36, 30),
               (86, 36, 30)], 'wr_body', 'body'),
         hull([(-40, -34, 34), (-40, 34, 34), (30, -34, 34), (30, 34, 34), (-30, -30, 58), (-30, 30, 58), (16, -30, 58),
               (16, 30, 58)], 'wr_body', 'cabin'),
         hull([(-30, -31, 40), (-30, 31, 40), (16, -31, 40), (16, 31, 40), (-26, -29, 55), (-26, 29, 55), (12, -29, 55),
               (12, 29, 55)], 'wr_dark', 'windows_gone'),
         hull([(-80, 20, 8), (-20, 44, 0), (20, 44, 0), (60, 20, 8), (-40, 30, 16), (30, 30, 14)], 'dust', 'sand_drift')]
    for sy in (1, -1):
        for xw in (58, -58):
            P.append(rod((xw, sy * 30, 12), (xw, sy * 38, 10), 13, mat='tire', name='flat', segs=10))
    for m in P:
        m.detail = 0.2
    return dict(kind='world', name='dust_wreck', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(128, 128), out=_out('dust_wreck'), preview_area=AREA, budget=0.05e6)


# ============================================================================================ cart
def cart():
    mats = {'ct_wood': {'type': 'leather', 'color': (150, 112, 72), 'seed': 5301},
            'ct_dark': {'type': 'leather', 'color': (96, 68, 44), 'seed': 5302},
            'ct_sack': cloth((196, 176, 132), seed=5303, dirt=0.4), 'ct_iron': metal((70, 64, 58), seed=5304, rust=0.5)}
    P = [slab(-60, 60, -36, 36, 32, 40, 'ct_wood', 'bed'),
         slab(-60, 60, -36, -32, 40, 52, 'ct_dark', 'side'), slab(-60, 60, 32, 36, 40, 52, 'ct_dark', 'side'),
         slab(-60, -56, -36, 36, 40, 52, 'ct_dark', 'back')]
    for sy in (1, -1):
        P.append(rod((0, sy * 36, 30), (0, sy * 44, 30), 30, mat='ct_dark', name='wheel', segs=14))
        P.append(rod((0, sy * 35, 30), (0, sy * 46, 30), 5, mat='ct_iron', name='hub', segs=8))
        P.append(rod((60, sy * 24, 36), (110, sy * 18, 16), 2.2, mat='ct_wood', name='shaft', segs=6))
    P.append(rod((0, -50, 30), (0, 50, 30), 2.5, mat='ct_iron', name='axle', segs=6))
    for (x, y, z) in ((-30, -12, 40), (-30, 14, 40), (8, 0, 40), (-10, 0, 56)):
        P.append(ellipsoid((15, 12, 9), center=(x, y, z + 8), segs=10, rings=6, mat='ct_sack'))
    for m in P:
        m.detail = 0.3
    return dict(kind='world', name='dust_cart', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(128, 128), out=_out('dust_cart'), preview_area=AREA, budget=0.05e6)


# ============================================================================================ palm tree
def palm():
    mats = {'pl_trunk': {'type': 'bark', 'color': (120, 92, 62), 'seed': 5401} if False else
            {'type': 'leather', 'color': (122, 94, 64), 'seed': 5401},
            'pl_leaf': {'type': 'scales', 'color': (70, 120, 44), 'seed': 5402},
            'pl_date': {'type': 'skin', 'color': (150, 80, 30), 'variation': 0.1, 'seed': 5403}}
    pts, rad = [], []
    for k in range(9):
        t = k / 8
        pts.append((26 * t * t, 0, 290 * t))
        rad.append(9 - 3 * t)
    P = [tube(pts, rad, segs=8, mat='pl_trunk', name='trunk')]
    for k in range(7):
        h = 290 * k / 7 + 10
        t = k / 7
        P.append(rod((26 * t * t, 0, h), (26 * t * t, 0, h + 5), 10 - 3 * t, mat='pl_trunk', name='ring', segs=8))
    top = (26, 0, 290)
    for k in range(9):
        a = k * 2 * math.pi / 9
        dx, dy = math.cos(a), math.sin(a)
        mid = (top[0] + dx * 60, top[1] + dy * 60, top[2] + 14)
        tip = (top[0] + dx * 120, top[1] + dy * 120, top[2] - 40)
        px, py = -dy * 14, dx * 14
        P.append(hull([top, (top[0] + px * 0.3, top[1] + py * 0.3, top[2]), mid, (mid[0] + px, mid[1] + py, mid[2] - 2),
                       (mid[0] - px, mid[1] - py, mid[2] - 2), tip], 'pl_leaf', 'frond'))
    for k in range(4):
        a = k * math.pi / 2 + 0.4
        P.append(sphere(4.5, center=(top[0] + math.cos(a) * 8, math.sin(a) * 8, top[2] - 10), segs=6, rings=4,
                        mat='pl_date'))
    for m in P:
        m.detail = 0.3
    return dict(kind='world', name='dust_palm', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(256, 128), out=_out('dust_palm'), preview_area=AREA, budget=0.05e6)


# ============================================================================================ market stall
def stall():
    mats = {'st_wood': {'type': 'leather', 'color': (140, 104, 66), 'seed': 5501},
            'st_red': cloth((200, 50, 40), seed=5502, dirt=0.2), 'st_white': cloth((236, 226, 200), seed=5503, dirt=0.25),
            'st_fruit': {'type': 'skin', 'color': (230, 140, 30), 'variation': 0.2, 'seed': 5504},
            'st_pot': {'type': 'bone', 'color': (180, 110, 70), 'seed': 5505}}
    P = [slab(-64, 64, -40, 0, 34, 40, 'st_wood', 'counter'), slab(-62, 62, -38, -34, 0, 34, 'st_wood', 'front')]
    for x in (-62, 62):
        for y in (-38, 38):
            P.append(slab(x - 2, x + 2, y - 2, y + 2, 0, 104, 'st_wood', 'post'))
    for k in range(8):                    # striped awning, flat top 106 with a front valance
        x0 = -66 + k * 16.5
        mat = 'st_red' if k % 2 == 0 else 'st_white'
        P.append(slab(x0, x0 + 16.5, -42, 42, 104, 106, mat, 'awning'))
        P.append(slab(x0, x0 + 16.5, -43, -42, 94, 106, mat, 'valance'))
    for k in range(6):
        P.append(sphere(5, center=(-48 + k * 18, -20, 45), segs=6, rings=4, mat='st_fruit'))
    for x in (-40, 30):
        P.append(lathe([(0, 8), (6, 12), (14, 9), (18, 5), (20, 6)], axis_start=(x, 20, 0), axis_dir=(0, 0, 1), segs=10,
                       mat='st_pot', name='pot'))
    for m in P:
        m.detail = 0.3
    return dict(kind='world', name='dust_stall', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(256, 128), out=_out('dust_stall'), preview_area=AREA, budget=0.05e6)


# ============================================================================================ water tower
def watertower():
    mats = {'wt_tank': metal((170, 150, 120), seed=5601, paint=(176, 156, 124), panels=20.0, rust=0.5, chipping=0.4),
            'wt_leg': metal((80, 70, 60), seed=5602, rust=0.5), 'wt_red': glow((255, 40, 30))}
    P = [rod((0, 0, 176), (0, 0, 256), 48, mat='wt_tank', name='tank', segs=16),
         rod((0, 0, 256), (0, 0, 268), 48, r1=6, mat='wt_tank', name='roof', segs=16),
         rod((0, 0, 268), (0, 0, 272), 3, mat='wt_red', name='lamp', segs=6)]
    for sx in (1, -1):
        for sy in (1, -1):
            P.append(rod((sx * 40, sy * 40, 0), (sx * 30, sy * 30, 176), 3, mat='wt_leg', name='leg', segs=6))
    for z in (60, 120):
        f = 1 - z / 176 * 0.25
        for (a, b) in (((1, 1), (1, -1)), ((1, -1), (-1, -1)), ((-1, -1), (-1, 1)), ((-1, 1), (1, 1))):
            P.append(rod((a[0] * 40 * f, a[1] * 40 * f, z), (b[0] * 40 * f, b[1] * 40 * f, z), 1.5, mat='wt_leg',
                         name='brace', segs=5))
    for k in range(16):                   # rungs on +X, ground to the tank top
        z = 8 + k * 16
        P.append(rod((50, -10, z), (50, 10, z), 1.2, mat='wt_leg', name='rung', segs=4))
    for sy in (1, -1):
        P.append(rod((50, sy * 10, 0), (50, sy * 10, 262), 1.4, mat='wt_leg', name='rail', segs=4))
    for m in P:
        m.detail = 0.25
    dec = [dict(kind='shape', shape='vex', center=(0, -48, 216), u=(1, 0, 0), v=(0, 0, 1), size=20, color=(160, 90, 255),
                depth=8, soft=0.4)]
    return dict(kind='world', name='dust_tower', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                decals=dec, tex=(128, 128), out=_out('dust_tower'), preview_area=AREA, budget=0.06e6)


# ============================================================================================ barrels
def barrel():
    mats = {'br_drum': metal((60, 90, 110), seed=5701, paint=(64, 96, 118), chipping=0.5, rust=0.6, scratches=0.4),
            'br_band': metal((50, 50, 46), seed=5702, rust=0.6)}
    P = [rod((0, 0, 0), (0, 0, 44), 15, mat='br_drum', name='drum', segs=12),
         rod((0, 0, 44), (0, 0, 45), 14, mat='br_band', name='lid', segs=12)]
    for z in (12, 30):
        P.append(rod((0, 0, z - 1.5), (0, 0, z + 1.5), 15.6, mat='br_band', name='band', segs=12))
    for m in P:
        m.detail = 0.4
    return dict(kind='world', name='dust_barrel', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(64, 64), out=_out('dust_barrel'), preview_area=AREA, budget=0.02e6)


def xbarrel():
    """Red DANGER explosive drum (same look as ice_xbarrel, no snow cap)."""
    mats = {'xb_red': metal((200, 26, 20), seed=3301, paint=(210, 28, 22), chipping=0.25, rust=0.2, scratches=0.35,
                            shine=0.45),
            'xb_haz': metal((235, 190, 20), seed=3302, paint=(240, 196, 24), chipping=0.25, scratches=0.3),
            'xb_dark': metal((30, 30, 32), seed=3303),
            'xb_label': metal((240, 200, 30), seed=3304, scratches=0.15, chipping=0.1)}
    P = [rod((0, 0, 0), (0, 0, 44), 15, mat='xb_red', name='drum', segs=16)]
    for z0 in (4, 34):
        for k in range(16):
            a0, a1 = k * math.pi / 8, (k + 1) * math.pi / 8
            pts = []
            for aa in (a0, a1):
                for r in (14.0, 15.6):
                    pts.append((r * math.cos(aa), r * math.sin(aa), z0))
                    pts.append((r * math.cos(aa + 0.25), r * math.sin(aa + 0.25), z0 + 6))
            P.append(hull(pts, 'xb_haz' if k % 2 == 0 else 'xb_dark', 'hazseg'))
    P += [rod((0, 0, 44), (0, 0, 45), 14, mat='xb_dark', name='lid', segs=16),
          rod((7, 0, 45), (7, 0, 48), 2.5, mat='xb_dark', name='cap', segs=8)]
    for m in P:
        m.detail = 0.5
    dec = []
    for sx in (1, -1):
        lab = slab(sx * 15.2 - 0.5, sx * 15.2 + 0.5, -11, 11, 16, 30, 'xb_label', 'label')
        lab.detail = 2.0
        P.append(lab)
        dec.append(dict(kind='shape', shape='danger', center=(sx * 15.8, 0, 23), u=(0, sx, 0), v=(0, 0, 1), size=5.4,
                        color=(15, 15, 15), depth=1.5, soft=0.12))
    return dict(kind='world', name='dust_xbarrel', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                decals=dec, tex=(256, 128), out=_out('dust_xbarrel'), preview_area=AREA, budget=0.07e6)


# ============================================================================================ sandbags, crate
def sandbag():
    mats = {'sb_bag': cloth((186, 162, 116), seed=5801, dirt=0.5)}
    P = []
    for row in range(3):
        n = 4 if row % 2 == 0 else 3
        off = 0 if row % 2 == 0 else 12
        for k in range(n):
            x = -36 + off + k * 24
            P.append(ellipsoid((13, 15, 7.5), center=(x, 0, 7 + row * 13), segs=8, rings=5, mat='sb_bag'))
    for m in P:
        m.detail = 0.4
    return dict(kind='world', name='dust_sandbag', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(128, 64), out=_out('dust_sandbag'), preview_area=AREA, budget=0.03e6)


def crate():
    mats = {'cr_plank': {'type': 'leather', 'color': (176, 140, 92), 'seed': 5901},
            'cr_frame': {'type': 'leather', 'color': (124, 92, 58), 'seed': 5902}}
    s, e = 56.0, 4.0
    h = s / 2
    P = [bx((s - 4, s - 4, s - 2), (0, 0, (s - 2) / 2), 'cr_plank', 'body', bevel=0.6)]
    for z in (e / 2, s - 2 - e / 2):
        P.append(bx((s, e, e), (0, -h + e / 2, z), 'cr_frame', 'edge', 0.3))
        P.append(bx((s, e, e), (0, h - e / 2, z), 'cr_frame', 'edge', 0.3))
        P.append(bx((e, s, e), (-h + e / 2, 0, z), 'cr_frame', 'edge', 0.3))
        P.append(bx((e, s, e), (h - e / 2, 0, z), 'cr_frame', 'edge', 0.3))
    for sg in (1, -1):
        P.append(hull([(-h + 6, sg * (h + 0.5), 6), (-h + 12, sg * (h + 0.5), 6), (h - 6, sg * (h + 0.5), s - 10),
                       (h - 12, sg * (h + 0.5), s - 10), (-h + 6, sg * (h - 1.5), 6), (h - 6, sg * (h - 1.5), s - 10)],
                      'cr_frame', 'brace'))
    for m in P:
        m.detail = 0.4
    return dict(kind='world', name='dust_crate', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(128, 128), out=_out('dust_crate'), preview_area=AREA, budget=0.03e6)


# ============================================================================================ dish, lantern
def dish():
    mats = {'ds_white': metal((220, 216, 206), seed=6001, scratches=0.2, chipping=0.2),
            'ds_dark': metal((60, 58, 56), seed=6002, rust=0.3)}
    P = [rod((0, 0, 0), (0, 0, 64), 2.5, mat='ds_dark', name='pole', segs=6),
         rod((0, 0, 0), (0, 0, 3), 10, mat='ds_dark', name='foot', segs=8),
         lathe([(0, 2), (4, 14), (8, 22), (6, 23), (2, 14), (-2, 2)], axis_start=(0, 0, 64),
               axis_dir=(math.cos(0.4), 0, math.sin(0.4)), segs=14, mat='ds_white', name='dish'),
         rod((2, 0, 66), (18, 0, 76), 1, mat='ds_dark', name='feed', segs=5)]
    for m in P:
        m.detail = 0.4
    return dict(kind='world', name='dust_dish', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(64, 64), out=_out('dust_dish'), preview_area=AREA, budget=0.02e6)


def lantern():
    mats = {'ln_iron': metal((50, 44, 36), seed=6101, rust=0.4), 'ln_glow': glow((255, 190, 90), (255, 236, 180))}
    P = [rod((0, 0, 0), (0, 0, -14), 0.6, mat='ln_iron', name='chain', segs=4),
         rod((0, 0, -14), (0, 0, -18), 5, r1=7, mat='ln_iron', name='cap', segs=8),
         rod((0, 0, -18), (0, 0, -30), 5, mat='ln_glow', name='glass', segs=8),
         rod((0, 0, -30), (0, 0, -33), 6, r1=4, mat='ln_iron', name='base', segs=8)]
    for m in P:
        m.detail = 0.6
    return dict(kind='world', name='dust_lantern', parts=P, sequences=[dict(name='idle', frames=1)], materials=mats,
                tex=(64, 64), out=_out('dust_lantern'), preview_area=AREA, budget=0.015e6)


def all():   # noqa: A001
    return [pickup(), wreck(), cart(), palm(), stall(), watertower(), barrel(), xbarrel(), sandbag(), crate(), dish(),
            lantern()]
