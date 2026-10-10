"""Vexmira cosmetics (v3.5): 5 wings, 5 hats, 5 pets bought with Vex Coin (vex_wing / vex_hat / vex_pet).

    cd devtools
    python3 -m mdlkit build mdlkit.content.cosmetics:all
    python3 -m mdlkit build mdlkit.content.cosmetics:all --only cos_wing_angel

Contracts (plugin CmTarget / CmPack, the entity yaw = player yaw, so model +X = where the player looks):
  wings  'back': origin = attach point between the shoulder blades, wings spread along +-Y and sweep
                 back (-X). Sequences: 0 idle (slow flap), 1 flap (fast).
  hats   'head': origin = top of the head (MdlHeadTops); the hat rim sits at z ~ -1.5.
                 Sequence 0 idle (halo / gem: rotate + bob, others static).
  pets   'follow': origin = centre of the pet (~10 units long). Sequence 0 idle (rotors, tails, wings).
All models: one 128x128 page, < 60 KB.
"""
import math
import numpy as np

from . import *          # noqa: F401,F403
from ..mathx import rot_x, rot_y, rot_z

AREA = 'cos'


def _out(name):
    return os.path.join(CSTRIKE, 'models/vexmira/cos', name + '.mdl')


def _spec(name, parts, bones, seqs, mats, budget=0.06e6, tex=(128, 128)):
    return dict(kind='world', name=name, parts=parts, bones=bones, sequences=seqs, materials=mats,
                tex=tex, out=_out(name), preview_area=AREA, budget=budget)


def _ring(center, r, tube_r, mat, axis='z', n=16, segs=5):
    cx, cy, cz = center
    pts = []
    for a in np.linspace(0, 2 * math.pi, n + 1):
        c, s = r * math.cos(a), r * math.sin(a)
        pts.append((cx + c, cy + s, cz) if axis == 'z' else ((cx, cy + c, cz + s) if axis == 'x' else (cx + c, cy, cz + s)))
    return tube(pts, tube_r, segs=segs, mat=mat, cap_start=False, cap_end=False)


def _gem(p0, p1, r, mat, segs=6):
    """Faceted double-pointed crystal from p0 to p1."""
    p0 = np.asarray(p0, float); p1 = np.asarray(p1, float)
    pts = [p0, p0 + (p1 - p0) * 0.3, p1]
    return flat_shaded(tube(pts, [0.02, r, 0.02], segs=segs, mat=mat, cap_start=False, cap_end=False))


# ============================================================================================ wings
SW = math.radians(28)          # sweep back angle of the wing plane
U = np.array([-math.sin(SW), math.cos(SW), 0.0])
V = np.array([0.0, 0.0, 1.0])
N = np.cross(U, V)            # forward-ish normal of the wing plane
R_W = np.column_stack([U, V, N])
W_ROOT = np.array([-1.0, 1.6, 0.0])


def _wp(u, v, d=0.0):
    return W_ROOT + u * U + v * V + d * N


def _flat(poly, thick, mat, d=0.0):
    return extrude(poly, thick, R=R_W, t=W_ROOT + d * N, mat=mat)


def _wtube(uv, radii, mat, d=0.0, segs=5):
    return tube([_wp(u, v, d) for u, v in uv], radii, segs=segs, mat=mat)


def _leaf(b, ang, L, w, n=6, tip=1.0):
    """2D feather / leaf polygon from base b along angle ang (deg)."""
    a = math.radians(ang)
    dx, dy = math.cos(a), math.sin(a)
    px, py = -dy, dx
    left, right = [], []
    for k in range(n + 1):
        s = k / n
        hw = w * (math.sin(math.pi * min(s, 0.999) ** 0.8) ** 0.6) * (1 - 0.3 * s * (1 - tip))
        cx, cy = b[0] + dx * L * s, b[1] + dy * L * s
        if 0 < k < n:
            left.append((cx + px * hw, cy + py * hw))
            right.append((cx - px * hw, cy - py * hw))
    base = (b[0] - px * w * 0.25, b[1] - py * w * 0.25)
    base2 = (b[0] + px * w * 0.25, b[1] + py * w * 0.25)
    tipp = (b[0] + dx * L, b[1] + dy * L)
    return [base2] + left + [tipp] + right[::-1] + [base]


def _wing_model(name, left_parts, mats, harness_mat, idle_amp=7.0, flap_amp=24.0, harness=None):
    bones = [Bone('root'), Bone('wl', 'root', tuple(W_ROOT)), Bone('wr', 'root', (W_ROOT[0], -W_ROOT[1], W_ROOT[2]))]
    parts = on('wl', left_parts)
    for m in left_parts:
        mm = m.mirrored(axis=1)
        mm.bone_name = 'wr'
        parts.append(mm)
    parts += on('root', harness or [bx((2.2, 4.4, 5.0), (-0.2, 0, 0.5), harness_mat, 'harness', 0.5)])

    def pose(amp, fold):
        def f(t):
            s = math.sin(2 * math.pi * t)
            return {'wl': dict(rot=(fold * s, 0, amp * s)), 'wr': dict(rot=(-fold * s, 0, -amp * s))}
        return f
    seqs = [dict(name='idle', frames=31, fps=15, loop=True, pose=pose(idle_amp, 3.0)),
            dict(name='flap', frames=17, fps=20, loop=True, pose=pose(flap_amp, 8.0))]
    return _spec(name, parts, bones, seqs, mats)


def _feather_wing(mat_a, mat_b, mat_arm, long_k=1.0, flame=False):
    P = [_wtube([(0, 0), (5, 7), (12, 12.5), (20, 15)], [1.1, 1.0, 0.8, 0.4], mat_arm)]
    # primaries (long, hanging down-out) along the arm, back layer
    for k in range(11):
        s = k / 10.0
        b = (2.5 + 17.5 * s, 4 + 11 * s)
        ang = -102 + 82 * s
        L = (9 + 9 * s) * long_k
        P.append(_flat(_leaf(b, ang, L, 2.0 + 0.4 * s, n=5, tip=0.5 if flame else 1.0), 0.4, mat_a if k % 2 else mat_b, d=-0.3))
    # coverts (short, front layer)
    for k in range(7):
        s = k / 6.0
        b = (2 + 16 * s, 5 + 9.5 * s)
        P.append(_flat(_leaf(b, -95 + 60 * s, 5.5 + 3 * s, 1.8, n=4), 0.4, mat_b if k % 2 else mat_a, d=0.3))
    # top tip feathers
    P.append(_flat(_leaf((18.5, 14.5), 25, 6 * long_k, 1.4, n=4), 0.4, mat_a, d=0.1))
    return P


def wing_angel():
    """Angel wings: layered white feathers with a soft gold arm."""
    mats = {'fa': cloth((246, 246, 250), seed=1, weave=0.0, dirt=0.05),
            'fb': cloth((222, 228, 240), seed=2, weave=0.0, dirt=0.08),
            'arm': metal((235, 200, 90), seed=3, scratches=0.1, shine=0.6, edge_wear=0.2),
            'har': metal((200, 170, 80), seed=4, scratches=0.2)}
    return _wing_model('cos_wing_angel', _feather_wing('fa', 'fb', 'arm'), mats, 'har')


def wing_demon():
    """Demon wings: bat membrane (dark red) on black bones with claws."""
    P = [_wtube([(0, 0), (5, 6), (9, 10)], [1.2, 1.0, 0.8], 'bonek')]
    tips = [(23, 7), (21, -5), (14, -13)]
    for tp in tips:
        P.append(_wtube([(9, 10), ((9 + tp[0]) / 2 + 0.5, (10 + tp[1]) / 2 + 1), tp], [0.7, 0.5, 0.15], 'bonek', segs=4))
    P.append(horn(_wp(9, 10.5), (U * 0.3 + V), 3.5, 0.6, mat='claw'))
    memb = [(0, 1.5), (9, 10), (23, 7), (18.5, 1.5), (21, -5), (15.5, -5.5), (14, -13), (7, -6), (0.5, -5)]
    P.append(_flat(memb, 0.4, 'memb', d=-0.2))
    mats = {'bonek': {'type': 'bone', 'color': (40, 30, 34), 'seed': 11},
            'claw': {'type': 'bone', 'color': (210, 200, 180), 'tip_color': (30, 20, 20), 'seed': 12},
            'memb': {'type': 'leather', 'color': (120, 14, 20), 'seed': 13},
            'har': metal((40, 36, 40), seed=14, rust=0.2)}
    return _wing_model('cos_wing_demon', P, mats, 'har', idle_amp=8.0, flap_amp=28.0)


def wing_cyber():
    """Cyber wings: Vexmira neon panels (purple) with cyan light edges on a steel arm."""
    P = [_wtube([(0, 0), (8, 7), (16, 11)], [1.2, 1.0, 0.7], 'steel', segs=6)]
    for k, (ang, L) in enumerate([(70, 9), (40, 13), (12, 16), (-15, 15), (-42, 12)]):
        b = (2 + 3.2 * k, 3 + 1.6 * k)
        a = math.radians(ang)
        dx, dy = math.cos(a), math.sin(a)
        px, py = -dy, dx
        w0, w1 = 2.3, 3.6
        quad = [(b[0] - px * w0, b[1] - py * w0), (b[0] + dx * L - px * w1, b[1] + dy * L - py * w1),
                (b[0] + dx * L + px * w1 * 0.4, b[1] + dy * L + py * w1 * 0.4), (b[0] + px * w0, b[1] + py * w0)]
        P.append(_flat(quad, 0.6, 'panel', d=-0.2 - 0.15 * (k % 2)))
        e0 = (b[0] + dx * 1.5 - px * w0 * 1.05, b[1] + dy * 1.5 - py * w0 * 1.05)
        e1 = (b[0] + dx * L - px * w1 * 1.05, b[1] + dy * L - py * w1 * 1.05)
        P.append(_wtube([e0, e1], 0.35, 'neon' if k % 2 else 'neon2', d=0.2, segs=4))
    P.append(_ring(tuple(_wp(8, 7, 0.6)), 1.3, 0.3, 'neon2', axis='y', n=10, segs=4))
    mats = {'steel': metal((70, 74, 86), seed=21, panels=1.5, shine=0.6),
            'panel': metal((70, 30, 130), seed=22, panels=2.5, edge_wear=0.4, scratches=0.2, shine=0.5),
            'neon': glow(VEX_CYAN, (220, 255, 255)),
            'neon2': glow(VEX_PURPLE, (235, 210, 255)),
            'har': metal((40, 42, 52), seed=23, panels=2)}
    harness = [bx((2.2, 4.6, 6.0), (-0.2, 0, 0.5), 'har', 'harness', 0.5), bx((0.4, 1.0, 4.0), (-1.4, 0, 0.6), 'neon', 'core', 0.1)]
    return _wing_model('cos_wing_cyber', P, mats, 'har', idle_amp=5.0, flap_amp=18.0, harness=harness)


def wing_phoenix():
    """Phoenix wings: fire feathers (orange-yellow glow) with flame-shaped tips."""
    mats = {'fa': glow((255, 120, 10), (255, 225, 110), freq=0.5),
            'fb': {'type': 'lava', 'color': (150, 30, 10), 'hot': (255, 110, 0), 'core': (255, 230, 120), 'seed': 31},
            'arm': glow((255, 80, 0), (255, 200, 80)),
            'har': metal((120, 40, 20), seed=32)}
    return _wing_model('cos_wing_phoenix', _feather_wing('fa', 'fb', 'arm', long_k=1.15, flame=True), mats, 'har',
                       idle_amp=9.0, flap_amp=26.0)


def wing_void():
    """Void crystal wings: obsidian shards fanning out with cyan crystals."""
    P = [_wtube([(0, 0), (7, 7), (14, 10)], [1.2, 1.0, 0.6], 'obs', segs=6)]
    for k, (ang, L) in enumerate([(55, 11), (28, 15), (2, 17), (-25, 14), (-52, 10)]):
        b = (2.5 + 2.6 * k, 4 + 1.2 * k)
        a = math.radians(ang)
        tip = (b[0] + math.cos(a) * L, b[1] + math.sin(a) * L)
        P.append(_gem(_wp(b[0], b[1], -0.2), _wp(tip[0], tip[1], -0.2), 2.7 - 0.2 * k, 'obs', segs=5))
        tip2 = (b[0] + math.cos(a) * L * 0.65, b[1] + math.sin(a) * L * 0.65)
        P.append(_gem(_wp(b[0] + math.cos(a) * 3, b[1] + math.sin(a) * 3, 0.9), _wp(tip2[0], tip2[1], 0.9), 1.3, 'cry', segs=5))
    mats = {'obs': {'type': 'crystal', 'color': (34, 26, 52), 'color2': (110, 80, 170), 'seed': 41},
            'cry': {'type': 'crystal', 'color': (40, 200, 255), 'color2': (220, 255, 255), 'seed': 42},
            'har': metal((30, 28, 40), seed=43)}
    return _wing_model('cos_wing_void', P, mats, 'har', idle_amp=4.0, flap_amp=14.0)


# ============================================================================================ hats
def _static(t):
    return {}


def hat_crown():
    """Royal crown: gold panels, 8 spikes with purple gems, cyan front jewel."""
    P = []
    n, r = 12, 4.7
    for k in range(n):
        a = 2 * math.pi * k / n
        b = box((0.5, 2 * math.pi * r / n * 1.08, 2.6), (0, 0, 0), bevel=0.1, mat='gold')
        b.transform(rot_z(a), (r * math.cos(a), r * math.sin(a), -0.4))
        P.append(b)
    for k in range(8):
        a = 2 * math.pi * k / 8
        c = np.array([math.cos(a), math.sin(a), 0])
        P.append(cone(tuple(c * r + (0, 0, 0.8)), tuple(c * (r + 0.4) + (0, 0, 3.6)), 0.9, segs=5, mat='gold'))
        P.append(sphere(0.55, tuple(c * (r + 0.45) + (0, 0, 3.9)), segs=6, rings=4, mat='gem'))
    P.append(_ring((0, 0, -1.6), r + 0.15, 0.35, 'gold2', n=16))
    P.append(_gem((r + 0.2, 0, 0.0), (r + 0.9, 0, 0.0), 0.9, 'jewel'))
    mats = {'gold': metal((235, 185, 50), seed=51, scratches=0.15, shine=0.8, edge_wear=0.3),
            'gold2': metal((200, 150, 40), seed=52, shine=0.7),
            'gem': {'type': 'crystal', 'color': (150, 60, 230), 'color2': (240, 200, 255), 'seed': 53},
            'jewel': {'type': 'crystal', 'color': (0, 200, 255), 'color2': (230, 255, 255), 'seed': 54}}
    return _spec('cos_hat_crown', P, [Bone('root')], [dict(name='idle', frames=1)], mats, budget=0.05e6)


def hat_halo():
    """Halo: glowing golden ring floating over the head; idle = slow spin + bob."""
    P = on('ring', [_ring((0, 0, 5.0), 4.6, 0.55, 'halo', n=20, segs=6),
                    _ring((0, 0, 5.0), 4.6, 0.25, 'core', n=20, segs=4)])
    for k in range(4):
        a = 2 * math.pi * k / 4 + 0.4
        P += on('ring', [_gem((4.6 * math.cos(a), 4.6 * math.sin(a), 4.2), (4.6 * math.cos(a), 4.6 * math.sin(a), 5.8), 0.5, 'core')])
    bones = [Bone('root'), Bone('ring', 'root', (0, 0, 5.0))]
    mats = {'halo': glow((255, 210, 60), (255, 250, 200), freq=0.6), 'core': glow((255, 255, 210), (255, 255, 255))}
    seqs = [dict(name='idle', frames=41, fps=10, loop=True,
                 pose=lambda t: {'ring': dict(pos=(0, 0, 0.7 * math.sin(2 * math.pi * t)), rot=(360 * t, 0, 0))})]
    return _spec('cos_hat_halo', P, bones, seqs, mats, budget=0.04e6)


def hat_cowboy():
    """Cowboy hat: brown leather crown with a pinch, curled brim, band with a silver buckle."""
    def brim_def(pu, p):
        p = p.copy()
        p[:, 2] += 1.6 * pu[:, 1] ** 2 - 0.3 * pu[:, 0] ** 2
        return p

    def crown_def(pu, p):
        p = p.copy()
        p[:, 2] -= 0.7 * np.exp(-(pu[:, 1] ** 2) * 18) * np.clip(pu[:, 2], 0, 1)   # top crease
        return p
    P = [ellipsoid((9.0, 7.6, 0.45), (0, 0, -1.2), segs=16, rings=5, mat='hat', deform=brim_def),
         ellipsoid((4.2, 3.6, 3.4), (0, 0, 0.6), segs=12, rings=7, mat='hat', deform=crown_def),
         _ring((0, 0, -0.2), 4.35, 0.45, 'band', n=16),
         bx((0.4, 1.4, 1.1), (4.5, 0, -0.2), 'buckle', 'buckle', 0.1)]
    mats = {'hat': {'type': 'leather', 'color': (120, 76, 40), 'seed': 61},
            'band': {'type': 'leather', 'color': (40, 26, 20), 'seed': 62},
            'buckle': metal((200, 205, 215), seed=63, shine=0.8)}
    return _spec('cos_hat_cowboy', P, [Bone('root')], [dict(name='idle', frames=1)], mats, budget=0.05e6)


def hat_viking():
    """Viking helmet: steel dome with a riveted band, nose guard and two curved horns."""
    P = [ellipsoid((4.9, 4.6, 4.6), (0.3, 0, -2.6), segs=12, rings=7, mat='steel'),
         _ring((0.3, 0, -2.6), 4.95, 0.55, 'bronze', n=16),
         bx((0.5, 1.0, 3.2), (5.2, 0, -3.6), 'bronze', 'nose', 0.15),
         bx((0.5, 0.7, 6.0), (0.4, 0, 0.6), 'bronze', 'ridge', 0.15)]
    for k in range(10):
        a = 2 * math.pi * k / 10
        P.append(sphere(0.32, (0.3 + 5.3 * math.cos(a), 5.3 * math.sin(a), -2.6), segs=5, rings=3, mat='steel'))
    for s in (1, -1):
        P.append(horn((0.3, s * 4.2, -1.2), (0, s, 0.35), 6.5, 1.3, curve=(1.2, 0, 4.0), segs=7, steps=6, mat='horn'))
    mats = {'steel': metal((150, 155, 165), seed=71, scratches=0.6, shine=0.5, edge_wear=0.6),
            'bronze': metal((170, 110, 50), seed=72, scratches=0.4, shine=0.5),
            'horn': {'type': 'horn', 'color': (225, 210, 175), 'tip_color': (70, 55, 40), 'seed': 73}}
    return _spec('cos_hat_viking', P, [Bone('root')], [dict(name='idle', frames=1)], mats, budget=0.05e6)


def hat_neon_horns():
    """Vexmira neon horns: dark curved horns with cyan tips, purple glow rings and a floating gem."""
    P = []
    for s in (1, -1):
        P.append(horn((0.8, s * 2.6, -1.5), (0.2, s * 0.45, 1.0), 6.0, 1.1, curve=(-2.5, s * 1.0, 0.5), segs=7, steps=6,
                      mat='horn'))
        P.append(_ring((0.8, s * 2.6, -1.0), 1.2, 0.28, 'neon', n=10, segs=4))
    P += on('gem', [_gem((1.0, 0, 3.2), (1.0, 0, 6.2), 1.0, 'gem')])
    bones = [Bone('root'), Bone('gem', 'root', (1.0, 0, 4.4))]
    mats = {'horn': {'type': 'horn', 'color': (45, 30, 70), 'tip_color': (90, 240, 255), 'tip_dark': 1.0, 'seed': 81},
            'neon': glow(VEX_PURPLE, (240, 215, 255)),
            'gem': glow(VEX_CYAN, (230, 255, 255))}
    seqs = [dict(name='idle', frames=31, fps=10, loop=True,
                 pose=lambda t: {'gem': dict(pos=(0, 0, 0.6 * math.sin(2 * math.pi * t)), rot=(360 * t, 0, 0))})]
    return _spec('cos_hat_neon', P, bones, seqs, mats, budget=0.04e6)


# ============================================================================================ pets
def pet_drone():
    """Mini drone: dark shell, cyan eye, four arms with spinning rotors (idle = rotors spin)."""
    P = [ellipsoid((3.4, 3.0, 1.5), (0, 0, 0), segs=12, rings=6, mat='shell'),
         ellipsoid((2.0, 1.8, 1.2), (0, 0, 1.0), segs=10, rings=5, mat='top'),
         ellipsoid((0.8, 1.3, 0.8), (3.0, 0, 0.0), segs=8, rings=5, mat='eye'),
         ellipsoid((1.6, 1.6, 0.4), (0, 0, -1.4), segs=10, rings=4, mat='eye2')]
    bones = [Bone('root')]
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        e = (5.0 * math.cos(a), 5.0 * math.sin(a), 0.6)
        P.append(cylinder((1.5 * math.cos(a), 1.5 * math.sin(a), 0.2), e, 0.45, segs=5, mat='arm'))
        P.append(cylinder((e[0], e[1], 0.0), (e[0], e[1], 1.2), 0.75, segs=8, mat='arm'))
        nm = 'rot%d' % k
        bones.append(Bone(nm, 'root', (e[0], e[1], 1.4)))
        b1 = box((5.6, 1.0, 0.3), (0, 0, 0), mat='blade'); b1.transform(rot_z(0.3 * k), (e[0], e[1], 1.4))
        P += on(nm, [b1])
    mats = {'shell': metal((40, 44, 56), seed=91, panels=2.5, shine=0.6),
            'top': metal((110, 60, 200), seed=92, panels=1.0, shine=0.7),
            'arm': metal((80, 84, 96), seed=93),
            'blade': metal((150, 155, 170), seed=94, shine=0.7),
            'eye': {'type': 'visor', 'color': (0, 200, 255), 'color2': (220, 255, 255)},
            'eye2': glow(VEX_CYAN)}
    seqs = [dict(name='idle', frames=7, fps=30, loop=True,
                 pose=lambda t: {('rot%d' % k): dict(rot=((180 if k % 2 else -180) * t * 6 / 7, 0, 0)) for k in range(4)})]
    return _spec('cos_pet_drone', P, bones, seqs, mats)


def pet_ghostcat():
    """Ghost cat: pale glowing cat with wispy tail and cyan eyes (idle = head tilt + tail sway)."""
    body = ellipsoid((3.8, 2.4, 2.4), (-1.0, 0, 0), segs=12, rings=7, mat='fur')
    P = [body]
    for s in (1, -1):
        P.append(capsule((1.6, s * 1.2, -1.2), (1.9, s * 1.2, -2.9), 0.65, segs=6, rings=2, mat='fur'))
        P.append(capsule((-3.0, s * 1.2, -1.0), (-3.2, s * 1.2, -2.9), 0.7, segs=6, rings=2, mat='fur'))
    head = [ellipsoid((2.3, 2.5, 2.2), (3.2, 0, 1.8), segs=12, rings=7, mat='fur')]
    for s in (1, -1):
        head.append(cone((3.0, s * 1.4, 3.4), (2.7, s * 1.9, 5.6), 0.9, segs=5, mat='ear'))
        head.append(ellipsoid((0.45, 0.55, 0.65), (5.2, s * 0.85, 2.2), segs=6, rings=4, mat='eye'))
    head.append(ellipsoid((0.4, 0.5, 0.3), (5.45, 0, 1.4), segs=6, rings=3, mat='ear'))
    tail = [tube([(-4.4, 0, 0.3), (-6.2, 0, 1.6), (-6.8, 0, 3.8), (-6.0, 0, 5.4), (-5.0, 0, 5.8)],
                 [0.8, 0.75, 0.65, 0.5, 0.15], segs=6, mat='wisp')]
    P += on('head', head) + on('tail', tail)
    bones = [Bone('root'), Bone('head', 'root', (2.2, 0, 1.2)), Bone('tail', 'root', (-4.4, 0, 0.3))]
    mats = {'fur': {'type': 'fur', 'color': (170, 200, 235), 'tip': (235, 248, 255), 'seed': 101},
            'ear': {'type': 'skin', 'color': (230, 170, 200), 'variation': 0.05, 'seed': 102},
            'eye': glow(VEX_CYAN, (230, 255, 255)),
            'wisp': glow((140, 200, 255), (235, 250, 255), freq=0.6)}
    seqs = [dict(name='idle', frames=31, fps=10, loop=True,
                 pose=lambda t: {'head': dict(rot=(6 * math.sin(2 * math.pi * t), 0, 8 * math.sin(2 * math.pi * t + 1))),
                                 'tail': dict(rot=(22 * math.sin(2 * math.pi * t), 0, 10 * math.sin(4 * math.pi * t)))})]
    return _spec('cos_pet_ghostcat', P, bones, seqs, mats)


def pet_dragon():
    """Baby dragon: purple scales, small bat wings (idle = fast flap), tail, horns, yellow eyes."""
    P = [ellipsoid((3.0, 2.0, 2.0), (-0.5, 0, 0), segs=12, rings=7, mat='scale'),
         ellipsoid((2.4, 1.4, 1.2), (-0.2, 0, -0.8), segs=10, rings=5, mat='belly'),
         tube([(-3.0, 0, 0), (-5.5, 0, -0.5), (-7.5, 0, 0.5), (-8.8, 0, 1.8)], [1.3, 0.9, 0.5, 0.1], segs=6, mat='scale'),
         cone((-8.6, 0, 1.6), (-9.8, 0, 2.6), 0.7, segs=4, mat='horn')]
    for s in (1, -1):
        P.append(capsule((1.0, s * 1.2, -1.2), (1.3, s * 1.2, -2.6), 0.55, segs=6, rings=2, mat='scale'))
        P.append(capsule((-1.8, s * 1.2, -1.2), (-1.9, s * 1.2, -2.6), 0.6, segs=6, rings=2, mat='scale'))
    head = [ellipsoid((1.9, 1.6, 1.5), (3.4, 0, 1.8), segs=10, rings=6, mat='scale'),
            ellipsoid((1.5, 1.0, 0.8), (5.0, 0, 1.4), segs=8, rings=5, mat='scale')]
    for s in (1, -1):
        head.append(horn((2.8, s * 0.9, 3.0), (-0.6, s * 0.3, 1.0), 2.4, 0.45, curve=(-0.8, 0, 0), segs=5, steps=4, mat='horn'))
        head.append(ellipsoid((0.4, 0.35, 0.45), (4.6, s * 1.05, 2.3), segs=6, rings=4, mat='eye'))
    P += on('head', head)
    bones = [Bone('root'), Bone('head', 'root', (2.0, 0, 1.0)), Bone('wl', 'root', (0, 1.6, 1.4)), Bone('wr', 'root', (0, -1.6, 1.4))]
    for s, nm in ((1, 'wl'), (-1, 'wr')):
        arm = tube([(0, s * 1.6, 1.4), (0.3, s * 4.0, 3.2), (-0.5, s * 7.2, 2.8)], [0.4, 0.3, 0.1], segs=4, mat='horn')
        mem = [(0.3, 1.6), (0.3, 4.0), (-0.5, 7.2), (-2.4, 6.0), (-3.0, 4.0), (-3.6, 1.6)]
        pts = [(x, s * y, 1.4 + (0.9 if y > 3 else 0)) for x, y in mem]
        poly = [(x, y) for x, y, _ in pts]
        m = extrude(poly, 0.25, t=(0, 0, 1.8), mat='memb')
        P += on(nm, [arm, m])
    mats = {'scale': {'type': 'scales', 'color': (120, 60, 190), 'seed': 111},
            'belly': {'type': 'scales', 'color': (230, 190, 120), 'freq': 0.9, 'seed': 112},
            'horn': {'type': 'horn', 'color': (230, 220, 200), 'tip_color': (80, 60, 50), 'seed': 113},
            'memb': {'type': 'leather', 'color': (190, 90, 210), 'seed': 114},
            'eye': glow((255, 220, 0), (255, 255, 200))}
    seqs = [dict(name='idle', frames=13, fps=18, loop=True,
                 pose=lambda t: {'wl': dict(rot=(0, 0, 32 * math.sin(2 * math.pi * t))),
                                 'wr': dict(rot=(0, 0, -32 * math.sin(2 * math.pi * t))),
                                 'head': dict(rot=(0, 4 * math.sin(2 * math.pi * t), 0))})]
    return _spec('cos_pet_dragon', P, bones, seqs, mats)


def pet_vexeye():
    """Vex orb eye: floating eyeball with a cyan iris inside a spinning purple ring with spikes."""
    P = [sphere(3.0, (0, 0, 0), segs=12, rings=8, mat='eyeball'),
         ellipsoid((0.8, 1.8, 1.8), (2.55, 0, 0), segs=10, rings=6, mat='iris'),
         ellipsoid((0.5, 0.8, 0.8), (3.05, 0, 0), segs=8, rings=4, mat='pupil')]
    ring = [_ring((0, 0, 0), 4.6, 0.5, 'ringm', axis='x', n=18, segs=5)]
    for k in range(6):
        a = 2 * math.pi * k / 6
        c = np.array([0, math.cos(a), math.sin(a)])
        ring.append(_gem(tuple(c * 4.9), tuple(c * 6.6), 0.5, 'spike', segs=4))
    P += on('ring', ring)
    bones = [Bone('root'), Bone('ring', 'root', (0, 0, 0))]
    mats = {'eyeball': {'type': 'bone', 'color': (235, 230, 240), 'seed': 121},
            'iris': {'type': 'visor', 'color': (0, 200, 255), 'color2': (220, 255, 255)},
            'pupil': {'type': 'flat', 'color': (10, 8, 20)},
            'ringm': metal((110, 60, 200), seed=122, shine=0.8, panels=1.5),
            'spike': glow(VEX_PURPLE, (240, 215, 255))}
    seqs = [dict(name='idle', frames=25, fps=10, loop=True, pose=lambda t: {'ring': dict(rot=(0, 0, 360 * t * 24 / 25))})]
    return _spec('cos_pet_vexeye', P, bones, seqs, mats)


def pet_flameskull():
    """Flame skull: bone skull with glowing eyes, chattering jaw and a flickering flame crest."""
    P = [ellipsoid((3.0, 2.6, 2.7), (0, 0, 0.6), segs=12, rings=8, mat='bone'),
         ellipsoid((1.6, 1.9, 1.0), (1.9, 0, -0.9), segs=10, rings=5, mat='bone')]
    for s in (1, -1):
        P.append(ellipsoid((0.5, 0.75, 0.75), (2.75, s * 1.1, 0.4), segs=8, rings=5, mat='socket'))
        P.append(ellipsoid((0.3, 0.4, 0.4), (3.0, s * 1.1, 0.4), segs=6, rings=4, mat='eye'))
    P.append(cone((2.9, 0, -0.2), (3.4, 0, -0.9), 0.45, segs=3, mat='socket'))
    jaw = [box((2.2, 2.6, 0.8), (1.6, 0, -2.2), bevel=0.25, mat='bone')]
    for k in range(5):
        jaw.append(box((0.35, 0.35, 0.5), (2.6, -1.0 + 0.5 * k, -1.65), bevel=0.05, mat='teeth'))
    P += on('jaw', jaw)
    fl = []
    for k, (x, y, h) in enumerate([(-0.6, 0, 5.5), (0.4, 0.9, 4.0), (0.4, -0.9, 4.0), (-1.8, 0.6, 3.6), (-1.8, -0.6, 3.6)]):
        fl.append(cone((x, y, 2.4), (x - 1.4, y, 2.4 + h), 1.3 if k == 0 else 0.95, segs=5, mat='fire' if k % 2 else 'fire2'))
    P += on('flame', fl)
    bones = [Bone('root'), Bone('jaw', 'root', (0.4, 0, -1.2)), Bone('flame', 'root', (-0.4, 0, 2.6))]
    mats = {'bone': {'type': 'bone', 'color': (225, 215, 190), 'seed': 131},
            'teeth': {'type': 'bone', 'color': (245, 240, 220), 'seed': 132},
            'socket': {'type': 'flat', 'color': (20, 10, 10)},
            'eye': glow((255, 120, 0), (255, 240, 160)),
            'fire': glow((255, 90, 0), (255, 220, 90), freq=0.8),
            'fire2': glow((255, 160, 20), (255, 250, 180), freq=0.8)}
    seqs = [dict(name='idle', frames=17, fps=12, loop=True,
                 pose=lambda t: {'jaw': dict(rot=(0, 9 * max(0, math.sin(4 * math.pi * t)), 0)),
                                 'flame': dict(rot=(8 * math.sin(2 * math.pi * t), 6 * math.sin(4 * math.pi * t + 1), 0))})]
    return _spec('cos_pet_flameskull', P, bones, seqs, mats)


WINGS = [wing_angel, wing_demon, wing_cyber, wing_phoenix, wing_void]
HATS = [hat_crown, hat_halo, hat_cowboy, hat_viking, hat_neon_horns]
PETS = [pet_drone, pet_ghostcat, pet_dragon, pet_vexeye, pet_flameskull]


def all():
    return [f() for f in WINGS + HATS + PETS]
