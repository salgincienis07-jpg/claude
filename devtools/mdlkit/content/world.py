"""Vexmira world props (DESIGN_v3 section 5 + 13): laser mine, thrown grenades, supply crate.

    cd devtools
    python3 -m mdlkit build mdlkit.content.world:lasermine
    python3 -m mdlkit build mdlkit.content.world:all

Laser mine contract (owner feedback 2026-10-03): emitter lens along model +X, mounting face at -X with the
model origin at the centre of the mounting face, attachment 0 = lens tip (beam start). The plugin turns +X
along the wall normal. Sequences: deploy (0), idle (1, lens pulse).
"""
import math
import numpy as np

from . import *          # noqa: F401,F403
from ..geom import ellipsoid as _ell, dome as _dome, lathe as _lathe

WMATS = {
    'mine_body': metal((52, 58, 68), seed=801, panels=1.6, chipping=0.3, edge_wear=0.8, scratches=0.35, shine=0.35),
    'mine_plate': metal((34, 36, 42), seed=802, panels=2.5, edge_wear=0.9, scratches=0.5, rust=0.08),
    'mine_dark': metal((22, 23, 27), seed=803, scratches=0.25, shine=0.25),
    'mine_steel': metal((140, 146, 156), seed=804, scratches=0.5, shine=0.6, edge_wear=0.4),
    'mine_rubber': {'type': 'rubber', 'color': (26, 27, 30), 'seed': 805},
    'mine_lens': {'type': 'visor', 'color': (0, 150, 220), 'color2': (210, 255, 255)},
    'mine_cyan': glow(VEX_CYAN, (210, 255, 255), freq=0.9),
    'mine_core': glow((150, 245, 255), (255, 255, 255)),
    'mine_led': glow((255, 40, 30), (255, 200, 160)),
    'mine_hazard': metal((205, 165, 25), seed=806, panels=0, chipping=0.5, edge_wear=0.9, scratches=0.4),
    # grenades
    'fire_body': metal((150, 36, 18), seed=811, paint=(165, 40, 20), chipping=0.35, edge_wear=0.8, panels=1.2),
    'fire_glow': glow((255, 110, 0), (255, 230, 120)),
    'frost_body': metal((150, 190, 215), seed=812, paint=(170, 205, 230), chipping=0.3, edge_wear=0.8, panels=1.2),
    'frost_glow': glow((90, 210, 255), (230, 250, 255)),
    'frost_ice': {'type': 'crystal', 'color': (150, 220, 255), 'seed': 813},
    'flare_body': {'type': 'rubber', 'color': (170, 30, 26), 'seed': 814},
    'flare_cap': metal((40, 40, 44), seed=815, scratches=0.4),
    'flare_glow': glow((255, 60, 40), (255, 220, 180)),
    'nade_steel': metal((96, 100, 106), seed=816, scratches=0.5, shine=0.5),
    'nade_band': metal((32, 33, 36), seed=817),
    # crate
    'crate_body': metal((70, 78, 58), seed=821, panels=3.0, chipping=0.4, edge_wear=0.8, scratches=0.35),
    'crate_frame': metal((44, 46, 50), seed=822, edge_wear=0.9, scratches=0.5, rust=0.12),
    'crate_cyan': glow(VEX_CYAN),
    'crate_gold': glow(GOLD, (255, 250, 200)),
    'canvas': cloth((214, 204, 184), seed=823, weave=0.2, dirt=0.3, stripes=[]),
    'canvas2': cloth((40, 120, 170), seed=824, weave=0.2, dirt=0.3),
    'rope': cloth((150, 130, 90), seed=825, weave=0.4),
}


def _ring_yz(cx, r, tube_r, mat, n=14, name='ring'):
    pts = [(cx, r * math.cos(a), r * math.sin(a)) for a in np.linspace(0, 2 * math.pi, n + 1)]
    m = tube(pts, tube_r, segs=5, mat=mat, cap_start=False, cap_end=False)
    m.name = name
    return m


def _oct_lathe(profile, x0, mat, segs=8, name='housing'):
    m = _lathe(profile, axis_start=(x0, 0, 0), axis_dir=(1, 0, 0), segs=segs, mat=mat, name=name)
    return m


# ============================================================================================ laser mine
LM_HEAD = (1.4, 0.0, 0.0)          # head bone rest position (hinge at the clamp)
LM_RING = (8.2, 0.0, 0.0)
LM_TIP = 10.3                      # lens tip x (attachment 0)


def lasermine():
    """Vexmira laser mine. +X = beam direction, mounting face (wall side) at x = 0, origin = centre of the
    mounting face, attachment 0 = lens tip (10.3, 0, 0). deploy: housing slides out of the cradle and
    rolls 90 degrees into place, emitter ring spins up; idle: lens/ring pulse (ring breathes along X and
    rotates, glowing core flickers forward/back)."""
    P = []
    # --- wall plate (root): back face exactly at x = 0
    P.append(bx((1.0, 11.0, 11.0), (0.5, 0, 0), 'mine_plate', 'plate', 0.35))
    P.append(bx((0.5, 8.4, 8.4), (1.2, 0, 0), 'mine_dark', 'plate2', 0.2))
    P.append(bx((0.06, 11.2, 11.2), (0.03, 0, 0), 'mine_rubber', 'gasket', 0.0))
    for sg in (1, -1):
        for sz in (1, -1):                     # hex screws with slot
            P.append(rod((0.95, sg * 4.6, sz * 4.6), (1.35, sg * 4.6, sz * 4.6), 0.55, mat='mine_steel', name='screw', segs=6))
            P.append(bx((0.1, 0.8, 0.16), (1.38, sg * 4.6, sz * 4.6), 'mine_dark', 'slot', 0.0))
    for sz in (1, -1):                         # hazard bars top/bottom
        P.append(bx((0.25, 6.2, 0.9), (1.05, 0, sz * 4.95), 'mine_hazard', 'hazard', 0.08))
    # cradle clamps + hinge pins
    for sg in (1, -1):
        P.append(bx((3.4, 0.7, 3.2), (2.3, sg * 3.55, 0), 'mine_body', 'clamp', 0.25))
        P.append(rod((LM_HEAD[0] + 0.6, sg * 4.1, 0), (LM_HEAD[0] + 0.6, sg * 3.0, 0), 0.55, mat='mine_steel', name='pin', segs=8))
        P.append(bx((2.4, 0.16, 0.35), (2.5, sg * 3.95, 0.9), 'mine_cyan', 'clampglow', 0.0))
    # cable loop from the plate to the housing underside
    P.append(tube([(1.2, 0, -3.6), (2.0, 0, -4.6), (3.6, 0, -4.3), (4.4, 0, -3.1)], 0.32, segs=6, mat='mine_rubber'))

    # --- head (housing + emitter)
    H = []
    H.append(_oct_lathe([(0.0, 2.2), (0.3, 3.0), (4.6, 3.0), (5.4, 2.4), (6.0, 2.0)], 1.6, 'mine_body'))
    for x in (2.4, 3.3, 4.2):                  # cooling fins
        H.append(_oct_lathe([(0, 3.05), (0.08, 3.35), (0.32, 3.35), (0.4, 3.05)], x, 'mine_dark', name='fin'))
    for a in range(4):                         # glow strips on four octagon flats
        ang = a * math.pi / 2 + math.pi / 4
        c, s = math.cos(ang), math.sin(ang)
        strip = box((3.4, 0.9, 0.12), center=(3.6, 0, 2.86), mat='mine_cyan')
        strip.transform(np.array([[1, 0, 0], [0, c, -s], [0, s, c]], float))
        strip.name = 'strip'
        H.append(strip)
    H.append(bx((1.0, 0.7, 0.4), (5.8, 0, 2.3), 'mine_dark', 'ledbox', 0.08))
    H.append(bx((0.5, 0.4, 0.16), (5.8, 0, 2.55), 'mine_led', 'led', 0.0))
    H.append(rod((2.6, -1.2, 2.9), (1.6, -1.6, 5.2), 0.12, mat='mine_steel', name='antenna', segs=4))
    H.append(_ell((0.22, 0.22, 0.22), (1.6, -1.6, 5.3), segs=6, rings=4, mat='mine_led'))
    # emitter barrel with grooves and lens
    H.append(_oct_lathe([(0.0, 1.9), (0.4, 1.75), (2.6, 1.75), (2.9, 1.5), (3.2, 1.5)], 7.0, 'mine_dark', segs=12, name='barrel'))
    for x in (7.6, 8.9):
        H.append(_oct_lathe([(0, 1.78), (0.1, 1.95), (0.3, 1.95), (0.4, 1.78)], x, 'mine_steel', segs=12, name='groove'))
    H.append(_oct_lathe([(0.0, 1.45), (0.1, 1.25), (0.25, 1.15)], 10.0, 'mine_lens', segs=12, name='lens'))
    H.append(_ell((0.55, 0.55, 0.55), (LM_TIP - 0.1, 0, 0), segs=8, rings=5, mat='mine_core'))
    H = on('head', *H)
    # --- pulsing emitter ring
    RG = on('ring', _ring_yz(LM_RING[0], 2.35, 0.2, 'mine_cyan'), _ring_yz(LM_RING[0] + 0.6, 2.15, 0.12, 'mine_cyan', name='ring2'))
    for a in range(3):
        ang = a * 2 * math.pi / 3
        RG += on('ring', bx((0.5, 0.3, 0.6), (LM_RING[0] + 0.3, 2.35 * math.cos(ang), 2.35 * math.sin(ang)), 'mine_steel', 'ringclip', 0.05))

    def deploy(t):
        e = 1 - (1 - min(1.0, t * 1.25)) ** 3           # ease-out slide/roll
        spin = min(1.0, max(0.0, (t - 0.55) / 0.45))
        return {'head': dict(pos=(-2.6 * (1 - e), 0, 0), rot=(0, 0, -90 * (1 - e))),
                'ring': dict(pos=(-1.4 * (1 - e), 0, 0), rot=(0, 0, 240 * spin * spin))}

    def idle(t):
        p = math.sin(2 * math.pi * t)
        return {'ring': dict(pos=(0.35 + 0.35 * p, 0, 0), rot=(0, 0, 360 * t / 3.0)),
                'head': dict(pos=(0.03 * math.sin(4 * math.pi * t), 0, 0))}

    decals = [dict(kind='shape', shape='vex', center=(3.6, 0, 3.0), u=(1, 0, 0), v=(0, 1, 0), size=0.9,
                   color=VEX_CYAN, mode='glow', target='housing', depth=1.5),
              dict(kind='shape', shape='chevron', center=(1.1, 0, 4.95), u=(0, 1, 0), v=(0, 0, 1), size=0.45,
                   color=(20, 20, 20), target='hazard', depth=1.0),
              dict(kind='shape', shape='chevron', center=(1.1, 0, -4.95), u=(0, 1, 0), v=(0, 0, -1), size=0.45,
                   color=(20, 20, 20), target='hazard', depth=1.0)]
    hx = LM_HEAD[0]
    return dict(kind='world', name='lasermine', parts=P + H + RG,
                bones=[Bone('root'), Bone('head', 'root', LM_HEAD), Bone('ring', 'head', LM_RING)],
                sequences=[dict(name='deploy', frames=24, fps=24, pose=deploy),
                           dict(name='idle', frames=30, fps=15, loop=True, pose=idle)],
                attachments=[('head', (LM_TIP - hx, 0, 0))], materials=WMATS, decals=decals, tex=(256, 256),
                budget=0.15e6, preview_area='world')


# ============================================================================================ thrown grenades
def _w_nade(name, body):
    return dict(kind='world', name=name, parts=body, sequences=[dict(name='idle', frames=1)], materials=WMATS,
                tex=(128, 128), budget=0.15e6, preview_area='world')


def w_firebomb():
    """Fire bomb (HE slot) lying on the floor: ribbed red canister, orange glow vents, steel fuze."""
    P = [_ell((1.55, 1.55, 1.95), (0, 0, 2.05), segs=12, rings=8, mat='fire_body'),
         rod((0, 0, 0.0), (0, 0, 0.55), 1.0, mat='nade_band', name='base', segs=12, r1=1.15),
         rod((0, 0, 3.7), (0, 0, 4.3), 0.55, mat='nade_steel', name='fuze', segs=8),
         rod((0, 0, 4.3), (0, 0, 4.55), 0.7, mat='nade_band', name='cap', segs=8),
         bx((0.4, 0.55, 3.0), (-1.05, 0, 3.0), 'nade_steel', 'spoon', 0.06)]
    for z in (1.4, 2.6):
        P.append(rod((0, 0, z), (0, 0, z + 0.32), 1.62, mat='nade_band', name='rib', segs=12))
    for a in range(6):
        ang = a * math.pi / 3
        P.append(bx((0.25, 0.25, 0.7), (1.55 * math.cos(ang), 1.55 * math.sin(ang), 2.1), 'fire_glow', 'vent', 0.0))
    P.append(tube([(0.5, 0.5, 4.2), (0.9, 1.1, 4.5), (1.4, 0.8, 4.8), (1.0, 0.2, 4.7)], 0.08, segs=4, mat='nade_steel'))
    return _w_nade('w_firebomb', P)


def w_frostbomb():
    """Frost bomb (smoke slot): pale-blue cylinder with ice crystals and cyan glow windows."""
    P = [rod((0, 0, 0.2), (0, 0, 4.0), 1.15, mat='frost_body', name='body', segs=12),
         rod((0, 0, 0.0), (0, 0, 0.35), 1.2, mat='nade_band', name='base', segs=12),
         rod((0, 0, 3.9), (0, 0, 4.3), 1.2, mat='nade_band', name='top', segs=12),
         rod((0, 0, 4.3), (0, 0, 4.9), 0.5, mat='nade_steel', name='fuze', segs=8),
         bx((0.4, 0.55, 3.1), (-1.35, 0, 3.0), 'nade_steel', 'spoon', 0.06)]
    for a in range(4):
        ang = a * math.pi / 2 + math.pi / 4
        P.append(bx((0.2, 0.55, 1.8), (1.12 * math.cos(ang), 1.12 * math.sin(ang), 2.1), 'frost_glow', 'window', 0.0))
    for a, h in ((0.3, 1.3), (2.2, 1.0), (4.1, 1.5)):
        P.append(horn((1.0 * math.cos(a), 1.0 * math.sin(a), 3.6), (math.cos(a) * 0.6, math.sin(a) * 0.6, 1.0), h, 0.32,
                      mat='frost_ice'))
    return _w_nade('w_frostbomb', P)


def w_flare():
    """Signal flare (flashbang slot): red stick flare with ribbed grip, striker cap and glowing tip."""
    P = [rod((0, 0, 0.0), (0, 0, 5.2), 0.75, mat='flare_body', name='body', segs=10),
         rod((0, 0, 5.2), (0, 0, 6.0), 0.8, mat='flare_cap', name='cap', segs=10),
         _ell((0.55, 0.55, 0.45), (0, 0, 6.05), segs=8, rings=4, mat='flare_glow'),
         rod((0, 0, -0.15), (0, 0, 0.3), 0.82, mat='flare_cap', name='base', segs=10)]
    for z in (0.8, 1.4, 2.0):
        P.append(rod((0, 0, z), (0, 0, z + 0.22), 0.8, mat='nade_band', name='rib', segs=10))
    P.append(bx((1.4, 0.06, 2.0), (0, 0.76, 3.6), 'crate_gold', 'label', 0.0))
    for m in P:                                    # lying on its side on the floor
        m.transform(np.array([[0, 0, 1], [0, 1, 0], [-1, 0, 0]], float), (-3.0, 0, 0.82))
    return _w_nade('w_flare', P)


# ============================================================================================ supply crate
def supply_crate():
    """Vexmira supply crate: armoured olive crate with steel frame, cyan/gold glow strips and logo; body 0 =
    crate only (landed), body 1 = with parachute. Sequences idle (0), fall (1, sway). Base at z = 0."""
    P = [bx((24, 24, 20), (0, 0, 10.6), 'crate_body', 'crate', 0.9)]
    for sx in (1, -1):
        for sy in (1, -1):
            P.append(bx((2.2, 2.2, 21.6), (sx * 11.6, sy * 11.6, 10.8), 'crate_frame', 'post', 0.3))
            P.append(bx((3.0, 3.0, 1.4), (sx * 11.2, sy * 11.2, 0.7), 'crate_frame', 'foot', 0.3))
    for z in (1.6, 20.4):
        for sg in (1, -1):
            P.append(bx((24.6, 1.4, 1.8), (0, sg * 12.1, z), 'crate_frame', 'rail', 0.25))
            P.append(bx((1.4, 24.6, 1.8), (sg * 12.1, 0, z), 'crate_frame', 'rail', 0.25))
    for sg in (1, -1):
        P.append(bx((14, 0.3, 1.0), (0, sg * 12.05, 15.5), 'crate_cyan', 'strip', 0.0))
        P.append(bx((0.3, 14, 1.0), (sg * 12.05, 0, 15.5), 'crate_cyan', 'strip', 0.0))
        P.append(bx((2.0, 6, 1.4), (sg * 13.0, 0, 9.0), 'crate_frame', 'handle', 0.3))
        P.append(bx((6, 2.0, 1.4), (0, sg * 13.0, 9.0), 'crate_frame', 'handle', 0.3))
    P.append(bx((8, 8, 0.4), (0, 0, 20.8), 'crate_frame', 'lidplate', 0.2))
    P.append(rod((0, 0, 21.0), (0, 0, 22.2), 1.2, mat='crate_gold', name='beacon', segs=10))
    for sx in (1, -1):
        for sy in (1, -1):
            P.append(rod((sx * 3.2, sy * 3.2, 20.9), (sx * 3.2, sy * 3.2, 21.4), 0.4, mat='crate_frame', name='bolt', segs=6))
    decals = [dict(kind='shape', shape='vex', center=(12.0, 0, 9.0), u=(0, 1, 0), v=(0, 0, 1), size=3.2,
                   color=VEX_CYAN, mode='glow', target='crate', depth=2.0, facing=(1, 0, 0)),
              dict(kind='shape', shape='vex', center=(-12.0, 0, 9.0), u=(0, -1, 0), v=(0, 0, 1), size=3.2,
                   color=VEX_CYAN, mode='glow', target='crate', depth=2.0, facing=(-1, 0, 0)),
              dict(kind='shape', shape='cross', center=(0, 12.0, 9.0), u=(1, 0, 0), v=(0, 0, 1), size=2.6,
                   color=(230, 230, 220), target='crate', depth=2.0, facing=(0, 1, 0)),
              dict(kind='shape', shape='cross', center=(0, -12.0, 9.0), u=(-1, 0, 0), v=(0, 0, 1), size=2.6,
                   color=(230, 230, 220), target='crate', depth=2.0, facing=(0, -1, 0))]
    canopy = []
    c = _dome((32, 32, 15), (0, 0, 0), segs=16, rings=5, mat='canvas', bone=0)
    c.make_two_sided()
    c.translate((0, 0, 58))
    c.name = 'canopy'
    canopy.append(c)
    stripe = _dome((32.4, 32.4, 15.2), (0, 0, 0), rim=lambda ph: 0.55 if (int(ph / (math.pi / 4)) % 2) else 1.5,
                   segs=16, rings=3, mat='canvas2', bone=0)
    stripe.translate((0, 0, 58))
    canopy.append(stripe)
    for a in range(8):
        ang = a * math.pi / 4 + math.pi / 8
        canopy.append(rod((math.cos(ang) * 31, math.sin(ang) * 31, 58), (math.cos(ang) * 11, math.sin(ang) * 11, 21.5),
                          0.18, mat='rope', name='rope', segs=4))
    return dict(kind='world', name='supply_crate', parts=P,
                bones=[Bone('root'), Bone('chute', 'root', (0, 0, 22))],
                bodygroups=[('parachute', [None, on('chute', canopy)])],
                sequences=[dict(name='idle', frames=1),
                           dict(name='fall', frames=31, fps=15, loop=True,
                                pose=lambda t: {'root': dict(rot=(0, 6 * math.sin(2 * math.pi * t), 9 * math.sin(2 * math.pi * t + 1))),
                                                'chute': dict(rot=(10 * t, -4 * math.sin(2 * math.pi * t), -6 * math.sin(2 * math.pi * t + 1)))})],
                materials=WMATS, decals=decals, tex=(256, 256), budget=0.15e6, preview_area='world')


def all():
    return [lasermine(), w_firebomb(), w_frostbomb(), w_flare(), supply_crate()]
