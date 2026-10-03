"""Zombie classes 0-11 (area 'zombies-A'): player models vex_z_<name> + claws v_<name>.

    cd devtools
    python3 -m mdlkit list  mdlkit.content.zombies_a
    python3 -m mdlkit build mdlkit.content.zombies_a:runner --lookdev
    python3 -m mdlkit build mdlkit.content.zombies_a:runner          # player + claws -> cstrike/
    python3 -m mdlkit build mdlkit.content.zombies_a:all --only vex_z_tank

Colours follow CLASS_RGB (DESIGN_v3.md section 3). Every class has its own silhouette (rig proportions +
accessories) and its own motion (style_params: hunch / lurch / limp / stride / lean / arm swing ...).
All content is procedural and original.
"""
import math
import numpy as np

from . import *          # noqa: F401,F403  (the content API)

AREA = 'zombies-A'
MATS = dict(torso='body', arm='body', leg='legs', foot='boot', hand='hand', neck='skin', head='head', claw='claw')


def _dim(c, f):
    return tuple(int(max(0, min(255, v * f))) for v in c)


def _mix(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def _zspec(name, rs, style_params, shape, materials, accessories, face, decals=None, quick=False, style='zombie',
           **extra):
    rs.hand_pose = 'claw'
    sp = dict(
        name='vex_z_' + name, style=style, rig=rs, style_params=style_params,
        shape=dict(dict(hands='claw', feet='bare'), **shape), mats=dict(MATS), materials=materials,
        accessories=accessories, face=face,
        tex=dict(w=512, h=256, pages=1) if not quick else dict(w=256, h=256, pages=1),
        budget=BUDGET['zombie'], preview_area=AREA, claws=True,
    )
    if decals is not None:
        sp['decals'] = decals
    sp.update(extra)
    return sp


# ============================================================================================ custom parts
def _bi(rig, name):
    return rig.index[name]


def pustules(rig, sh, mat='pustule', where=(), seed=3):
    """Bulging boils: where = [(bone, offset(units@72, from the bone joint), radius, count, spread)]."""
    k = rig.H / 72.0
    rng = np.random.default_rng(seed)
    out = []
    for bone, off, r, n, spread in where:
        b = _bi(rig, bone)
        c0 = rig.J(bone) + np.array(off) * k
        for i in range(n):
            c = c0 + rng.uniform(-1, 1, 3) * np.array(spread) * k
            rr = r * rng.uniform(0.6, 1.15) * k
            out.append(ellipsoid((rr, rr, rr * 0.9), c, segs=8, rings=5, mat=mat, bone=b))
    return out


def lamprey_mouth(rig, sh, mat='lip', inner='maw', length=2.6, radius=1.5):
    """Leech: a round sucker mouth pushed out of the face (funnel + dark throat disc)."""
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    m = fa['mouth'] + np.array([-0.6 * k, 0, 0.2 * k])
    d = np.array([1.0, 0, -0.25])
    d /= np.linalg.norm(d)
    p1 = m + d * length * k
    funnel = tube([m, m + d * length * 0.6 * k, p1], [radius * 0.9 * k, radius * 1.05 * k, radius * 1.35 * k], segs=12,
                  mat=mat, bones=hb, cap_start=False, cap_end=False)
    rim = tube([p1 - d * 0.35 * k, p1 + d * 0.15 * k], [radius * 1.45 * k, radius * 1.2 * k], segs=12, mat=mat, bones=hb,
               cap_start=False, cap_end=False)
    throat = cylinder(p1 - d * 0.6 * k, p1 - d * 0.1 * k, radius * 1.15 * k, radius * 1.15 * k, segs=12, mat=inner,
                      bone=hb)
    teeth = []
    for i in range(8):
        a = 2 * math.pi * i / 8
        off = np.array([0, math.cos(a), math.sin(a)]) * radius * 1.0 * k
        base = p1 + off - d * 0.05 * k
        teeth.append(cone(base, base + d * 0.15 * k - off * 0.45, 0.28 * k, segs=4, mat='teeth', bone=hb))
    return [funnel, rim, throat] + teeth


def face_mask(rig, sh, mat='mask', horn_mat=None):
    """Voodoo: carved oval mask over the face (eye holes painted by decals), optional small horns."""
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    c = fa['center']
    rx, ry, rz = fa['radii']

    def deform(u, p):
        q = p.copy()
        q[:, 0] -= np.clip(-u[:, 0], 0, 1) * rx * 0.9          # flatten the back -> shield shape
        return q
    m = ellipsoid((0.9 * k, ry * 1.08, rz * 1.32), c + np.array([rx * 0.92, 0, -0.6 * k]), segs=12, rings=8, mat=mat,
                  bone=hb, deform=deform)
    out = [m]
    if horn_mat:
        for sg in (1, -1):
            base = c + np.array([rx * 0.75, sg * ry * 0.65, rz * 0.75])
            out.append(horn(base, (0.2, sg * 0.5, 1.0), 4.0 * k, 0.55 * k, curve=(0, sg * 0.8 * k, 1.2 * k), mat=horn_mat,
                            bone=hb))
    return out


def throat_sac(rig, sh, mat='sac', size=1.0):
    """Spitter: swollen acid sac under the jaw / front of the long neck."""
    k = rig.H / 72.0
    nb = _bi(rig, 'Bip01 Neck')
    c = (rig.J('Bip01 Neck') + rig.J('Bip01 Head')) / 2 + np.array([1.8, 0, -0.6]) * k
    return [ellipsoid((1.9 * k * size, 2.0 * k * size, 2.2 * k * size), c, segs=10, rings=6, mat=mat, bone=nb)]


def bone_charms(rig, sh, mat='bone', n=7):
    """Voodoo: small skulls / teeth hanging from a necklace around the upper chest."""
    k = rig.H / 72.0
    out = []
    b = _bi(rig, 'Bip01 Spine3')
    c = rig.J('Bip01 Spine3')
    for i in range(n):
        a = (i - (n - 1) / 2) / ((n - 1) / 2)              # -1..1 across the chest
        p = c + np.array([4.4 - 0.9 * a * a, a * 4.0, -1.2 - 1.5 * (1 - a * a)]) * k
        if i == n // 2:
            out.append(ellipsoid((0.9 * k, 1.1 * k, 1.25 * k), p + np.array([0.3, 0, -0.6]) * k, segs=8, rings=6,
                                 mat=mat, bone=b))
        else:
            out.append(cone(p, p + np.array([0.3, 0, -1.8]) * k, 0.4 * k, segs=5, mat=mat, bone=b))
    return out


def _chain_pts(rig, k, z_drop=2.0):
    J = rig.J
    return [J('Bip01 L Clavicle') + np.array([0.5, 1.5, 1.5]) * k,
            J('Bip01 Spine3') + np.array([4.6, 1.8, -z_drop]) * k,
            J('Bip01 Spine3') + np.array([4.6, -1.8, -z_drop]) * k,
            J('Bip01 R Clavicle') + np.array([0.5, -1.5, 1.5]) * k]


# ============================================================================================ 0 walker
def walker(quick=False):
    """0 Walker: the classic rotting civilian (reference sample spec, green 0,140,0)."""
    from ..samples import walker_spec
    sp = walker_spec(quick)
    sp.update(preview_area=AREA, claws=True)
    return sp


# ============================================================================================ 1 runner
def _runner_mats(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['runner']
    sk = skin((150, 128, 104), seed=1101, variation=0.15, veins=0.6, vein_color=(80, 40, 60), rot=0.35,
              rot_color=(96, 82, 46), wounds=0.45, blood=0.4, pores=0.15)
    jacket = cloth(_dim(c, 0.92), seed=1102, weave=0.06, weave_freq=5.0, dirt=0.75, dirt_color=(70, 50, 30), stains=0.7,
                   blood=0.55, tears=0.2,
                   stripes=[dict(normal=(0, 0, 1), offset=J('Bip01 Spine3')[2] + 1.0 * k, width=0.9 * k, color=(235, 230, 220))])
    pants = cloth((40, 40, 48), seed=1103, weave=0.05, dirt=0.8, dirt_z=-10, dirt_color=(80, 64, 44), stains=0.5, blood=0.3)
    white = cloth((225, 222, 212), seed=1104, weave=0.0, dirt=0.7, dirt_color=(110, 90, 60))
    orange = cloth(_dim(c, 0.95), seed=1105, weave=0.0, dirt=0.5)
    belt_z = J('Bip01 Pelvis')[2] + 0.8 * k
    return {
        'skin': sk, 'head': dict(sk, seed=1106, rot=0.25), 'hand': dict(sk, seed=1107, blood=0.6),
        'body': layers(sk,
                       (jacket, {'meshes': ['torso'], 'z': (belt_z - 1.0 * k, J('Bip01 Neck')[2] + 0.3 * k), 'ragged': 1.0,
                                 'holes': 0.25, 'hole_freq': 0.14, 'seed': 5}, (60, 30, 10)),
                       (jacket, {'meshes': ['arm'], 't': (-1.0, 1.45), 'ragged': 1.0, 'holes': 0.2, 'seed': 6}, (60, 30, 10)),
                       (white, {'meshes': ['arm'], 't': (-1.0, 1.4), 'y': (-0.45 * k, 0.45 * k), 'x': (-30, -0.2 * k)}),
                       (pants, {'meshes': ['torso'], 'z': (-60, belt_z), 'ragged': 0.3, 'seed': 7})),
        'legs': layers(sk, (pants, {'meshes': ['leg'], 't': (-1.0, 1.75), 'ragged': 1.1, 'holes': 0.25, 'seed': 8},
                            (20, 20, 24)),
                       (orange, {'meshes': ['leg'], 't': (-1.0, 1.7), 'x': (-0.55 * k, 0.55 * k), 'ragged': 0.2, 'seed': 9})),
        'boot': layers(dict(sk, seed=1108), ({'type': 'rubber', 'color': (215, 210, 200)}, {'meshes': ['foot_L'],
                                                                                           'z': (-60, -34.0)}),
                       (cloth((60, 64, 80), seed=1109, weave=0.15, dirt=0.9, dirt_color=(70, 55, 40)),
                        {'meshes': ['foot_L'], 'z': (-34.0, 60)})),
        'claw': {'type': 'bone', 'color': (200, 180, 130), 'tip_color': (60, 25, 10), 'tip_dark': 0.8, 'seed': 1110},
        'shirt': dict(jacket, seed=1111),
        'hair': {'type': 'hair', 'color': (60, 40, 26), 'tip': (110, 80, 50), 'seed': 1112},
        'band': cloth((235, 235, 235), seed=1113, weave=0.2, weave_freq=7.0, dirt=0.6, blood=0.5),
        'teeth': {'type': 'bone', 'color': (200, 185, 130), 'seed': 1114, 'tip_dark': 0.2},
        'eyeglow': glow((255, 160, 20), (255, 230, 150)),
    }


def runner(quick=False):
    """1 Runner (orange): skinny, long-legged, leaning far forward in a torn tracksuit with sweatband;
    long fast stride, big arm pumping, aggressive."""
    rs = RigSpec(height=73.0, shoulder_w=0.195, hip_w=0.11, leg=0.55, arm=0.37, hand=0.11, head=0.135,
                 limb_thick=0.78, bulk=0.78)
    return _zspec('runner', rs,
                  dict(hunch=30.0, lurch=0.25, run_D=124.0, walk_D=72.0, run_lean=24.0, arm_swing=1.7, knee_bend=0.16,
                       aggression=1.35, claw_spread=1.1, stance_w=0.85),
                  dict(gaunt=0.55, muscle=0.12, chest=0.88, waist=0.82, claw_len=0.9,
                       head=dict(jaw_drop=0.4, sockets=1.5, cheek=1.4, mouth_open=0.9, w=0.92, nose=0.7)),
                  _runner_mats,
                  [('hair', dict(mat='hair', volume=0.4)),
                   ('wraps', dict(mat='band', where=(('L', 'Forearm', 0.82, 0.95), ('R', 'Forearm', 0.82, 0.95)), grow=0.3)),
                   ('shirt_flaps', dict(mat='shirt', n=5, length=5.0, seed=11)),
                   ('jaw_teeth', dict(mat='teeth', n=6, size=0.9)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.5))],
                  dict(eye='glow', glow=(255, 160, 30), mouth='snarl', teeth=(205, 190, 130), brow_color=None, eye_size=0.85),
                  quick=quick)


# ============================================================================================ 2 tank
def _tank_mats(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['tank']
    sk = skin((122, 116, 128), seed=1201, variation=0.18, tint2=(90, 96, 130), tint2_amount=0.55, veins=0.7,
              vein_color=(40, 60, 150), scars=0.8, wounds=0.35, blood=0.3, pores=0.2, rot=0.2)
    plate = metal((95, 100, 110), seed=1202, paint=_dim(c, 0.75), chipping=0.45, edge_wear=0.9, rust=0.35, scratches=0.6)
    pants = cloth((58, 62, 50), seed=1203, weave=0.12, dirt=0.9, dirt_color=(70, 60, 40), stains=0.6, blood=0.35)
    return {
        'skin': sk, 'head': dict(sk, seed=1204), 'hand': dict(sk, seed=1205, blood=0.5), 'boot': dict(sk, seed=1206),
        'body': layers(sk, (pants, {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] + 1.6 * k), 'ragged': 1.2,
                                    'seed': 5}, (30, 30, 24))),
        'legs': layers(sk, (pants, {'meshes': ['leg'], 't': (-1, 1.2), 'ragged': 1.3, 'holes': 0.3, 'seed': 6}, (30, 30, 24))),
        'claw': {'type': 'bone', 'color': (170, 160, 140), 'tip_color': (30, 30, 60), 'tip_dark': 0.8, 'seed': 1207},
        'plate': plate, 'shard': metal((150, 155, 165), seed=1208, rust=0.5, chipping=0.2),
        'strap': {'type': 'leather', 'color': (40, 34, 30), 'seed': 1209},
        'teeth': {'type': 'bone', 'color': (190, 180, 140), 'seed': 1210},
        'eyeglow': glow((60, 130, 255), (200, 225, 255)),
    }


def _tank_acc(rig, sh):
    J = rig.J
    k = rig.H / 72.0

    def at(bone, off):
        return tuple((J(bone) + np.array(off) * k) / k)
    return [
        ('shoulder_pads', dict(mat='plate', size=1.35, spikes=2, spike_mat='shard')),
        ('bracers', dict(mat='plate', grow=0.8)),
        ('plates_on', dict(mat='plate', items=[
            ('Bip01 Spine2', at('Bip01 Spine2', (6.6, 1.8, 0.5)), (1.0, 4.6, 5.2), (8, -12, 6)),
            ('Bip01 Spine', at('Bip01 Spine', (5.6, -2.2, 0.0)), (1.0, 4.0, 3.6), (-10, -6, -4)),
            ('Bip01 Spine3', at('Bip01 Spine3', (-5.5, 0, 0.5)), (1.0, 6.4, 5.0), (0, 14, 0)),
            ('Bip01 L Thigh', at('Bip01 L Thigh', (2.6, 1.0, -7.0)), (1.0, 3.2, 4.4), (0, -8, 10)),
            ('Bip01 Head', at('Bip01 Head', (-0.5, 0, 6.6)), (5.0, 4.6, 0.9), (0, -6, 0))])),
        ('spikes', dict(mat='shard', n=4, length=4.0, radius=0.9, seed=7)),
        ('chain', dict(mat='strap', points=_chain_pts(rig, k, 3.5), bones=[_bi(rig, 'Bip01 Spine3')] * 3, link=1.2)),
        ('jaw_teeth', dict(mat='teeth', n=4, size=1.2)),
        ('glow_eyes', dict(mat='eyeglow', size=0.55)),
    ]


def tank(quick=False):
    """2 Tank (blue): huge muscle mass with blue-painted steel plates hammered into chest, back, head and
    thigh, armoured shoulders; slow heavy upright gait, wide stance, little arm swing."""
    rs = RigSpec(height=74.0, shoulder_w=0.31, hip_w=0.145, leg=0.45, arm=0.36, hand=0.13, head=0.12, bulk=1.5,
                 limb_thick=1.45, arm_thick=1.1)
    return _zspec('tank', rs,
                  dict(hunch=12.0, heavy=0.65, lurch=0.35, run_D=86.0, walk_D=56.0, stance_w=1.35, arm_swing=0.55,
                       knee_bend=0.14, run_lean=8.0, aggression=0.8, claw_spread=0.8),
                  dict(muscle=1.0, hump=0.45, chest=1.2, waist=1.05, belly=0.15, claw_len=0.6, neck=1.4,
                       head=dict(jaw=1.6, brow=1.7, w=1.1, sockets=1.2, ears=0.6, mouth_open=0.3, flat_top=0.4)),
                  _tank_mats, _tank_acc,
                  dict(eye='glow', glow=(80, 150, 255), mouth='snarl', teeth=(200, 190, 150), brow_color=None, eye_size=0.75),
                  quick=quick)


# ============================================================================================ 3 banshee
def _banshee_mats(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['banshee']
    pale = skin((196, 198, 222), seed=1301, variation=0.08, veins=0.7, vein_color=(110, 110, 190), rot=0.12,
                rot_color=(150, 150, 190), wounds=0.15, blood=0.15, pores=0.05)
    dress = cloth(_dim(c, 0.82), seed=1302, weave=0.25, weave_freq=5.0, dirt=0.4, dirt_color=(80, 80, 110), tears=0.4,
                  stains=0.3, blood=0.2)
    return {
        'skin': pale, 'head': dict(pale, seed=1303, veins=0.4), 'hand': dict(pale, seed=1304), 'boot': dict(pale, seed=1305),
        'body': layers(pale, (dress, {'meshes': ['torso'], 'z': (-60, J('Bip01 Spine3')[2] + 1.2 * k), 'ragged': 1.6,
                                      'holes': 0.3, 'seed': 4}, (90, 90, 140)),
                       (dress, {'meshes': ['arm'], 't': (-1.0, 0.45), 'ragged': 1.5, 'holes': 0.3, 'seed': 5}, (90, 90, 140))),
        'legs': layers(pale, (dress, {'meshes': ['leg'], 't': (-1, 1.1), 'ragged': 1.6, 'holes': 0.35, 'seed': 6},
                              (90, 90, 140))),
        'claw': {'type': 'bone', 'color': (60, 60, 90), 'tip_color': (220, 220, 255), 'tip_dark': 0.8, 'seed': 1306},
        'dress': dict(dress, seed=1307), 'veil': dict(dress, seed=1308, color=_dim(c, 0.95), tears=0.6),
        'hair': {'type': 'hair', 'color': (226, 228, 240), 'tip': (150, 150, 210), 'seed': 1309},
        'teeth': {'type': 'bone', 'color': (210, 210, 220), 'seed': 1310},
        'eyeglow': glow((210, 220, 255), (255, 255, 255)),
    }


def banshee(quick=False):
    """3 Banshee (pale lavender): slim pale ghost woman, very long white hair, long tattered dress;
    upright drifting walk, short strides, arms barely swinging, wide-spread long claws, screaming mouth."""
    rs = RigSpec(height=70.0, shoulder_w=0.18, hip_w=0.12, leg=0.52, arm=0.37, hand=0.12, head=0.14, limb_thick=0.72,
                 bulk=0.78)
    return _zspec('banshee', rs,
                  dict(hunch=6.0, lurch=0.15, limp=0.0, walk_D=50.0, run_D=88.0, run_lean=6.0, arm_swing=0.3,
                       knee_bend=0.08, stance_w=0.7, claw_spread=1.6, aggression=1.1),
                  dict(gaunt=0.5, muscle=0.0, chest=0.9, waist=0.72, hips=1.08, pecs=0.2, claw_len=1.6,
                       head=dict(jaw=0.8, chin=1.1, sockets=1.6, cheek=0.8, nose=0.6, mouth_open=1.0, jaw_drop=0.55, w=0.92)),
                  _banshee_mats,
                  [('hair', dict(mat='hair', volume=1.2, length=19.0, style='long')),
                   ('coat_skirt', dict(mat='dress', length=0.95, flare=0.55)),
                   ('shirt_flaps', dict(mat='veil', n=6, length=6.0, seed=13)),
                   ('jaw_teeth', dict(mat='teeth', n=5, size=0.8)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.6))],
                  dict(eye='glow', glow=(215, 225, 255), mouth='open', teeth=(210, 210, 220), brow_color=None, eye_size=1.0,
                       dark_sockets=0.6),
                  quick=quick)


# ============================================================================================ 4 leech
def _leech_mats(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['leech']
    sk = skin((122, 74, 78), seed=1401, variation=0.2, tint2=(90, 40, 60), tint2_amount=0.6, veins=1.0,
              vein_color=(230, 16, 20), rot=0.35, rot_color=(80, 30, 40), wounds=0.6, blood=0.7, pores=0.3)
    rags = cloth((54, 44, 40), seed=1402, weave=0.1, dirt=1.0, dirt_color=(50, 30, 25), stains=0.9, blood=0.8, tears=0.5)
    return {
        'skin': sk, 'head': dict(sk, seed=1403, veins=1.0), 'hand': dict(sk, seed=1404, blood=0.9),
        'boot': dict(sk, seed=1405),
        'body': layers(sk, (rags, {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] + 1.2 * k), 'ragged': 1.4,
                                   'holes': 0.4, 'seed': 4}, (30, 15, 15))),
        'legs': layers(sk, (rags, {'meshes': ['leg'], 't': (-1, 1.0), 'ragged': 1.5, 'holes': 0.4, 'seed': 5}, (30, 15, 15))),
        'claw': {'type': 'bone', 'color': (120, 40, 40), 'tip_color': (20, 0, 0), 'tip_dark': 0.9, 'seed': 1406},
        'lip': skin((150, 50, 60), seed=1407, variation=0.25, veins=1.0, vein_color=(255, 40, 40), blood=0.8, wounds=0.3),
        'maw': {'type': 'skin', 'color': (40, 4, 8), 'variation': 0.3, 'veins': 0.5, 'vein_color': (120, 0, 0), 'seed': 1408},
        'sucker': {'type': 'horn', 'color': (120, 50, 60), 'tip_color': (220, 20, 30), 'tip_dark': 0.5, 'seed': 1409},
        'teeth': {'type': 'bone', 'color': (220, 200, 180), 'seed': 1410},
        'eyeglow': glow(c, (255, 140, 120)),
    }


def leech(quick=False):
    """4 Leech (red): wet dark-red skin with bright red veins, round lamprey sucker mouth full of teeth,
    feeding tubes along the spine; low crawling crouch with a twitchy lurch."""
    rs = RigSpec(height=70.0, shoulder_w=0.22, hip_w=0.115, leg=0.49, arm=0.38, hand=0.12, head=0.135, limb_thick=0.88,
                 bulk=0.95)
    return _zspec('leech', rs,
                  dict(hunch=34.0, lurch=0.9, limp=0.1, walk_D=58.0, run_D=100.0, run_lean=16.0, knee_bend=0.22,
                       arm_swing=0.8, stance_w=1.15, claw_spread=1.3, aggression=1.25, crouch_h=0.27),
                  dict(gaunt=0.45, hump=0.4, muscle=0.25, chest=0.95, waist=0.85, claw_len=1.1, neck_len=1.2,
                       head=dict(snout=0.5, jaw=0.7, chin=0.6, sockets=1.7, nose=0.0, ears=0.3, cranium=1.1, w=0.95)),
                  _leech_mats,
                  [(lamprey_mouth, dict(mat='lip', inner='maw')),
                   ('spikes', dict(mat='sucker', n=5, length=3.2, radius=0.85, seed=21)),
                   ('ribs', dict(mat='teeth', count=3, exposed_side=-1)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.4))],
                  dict(eye='glow', glow=(255, 30, 30), mouth='closed', lips=(120, 30, 40), brow_color=None, eye_size=0.7,
                       dark_sockets=0.6),
                  quick=quick)


# ============================================================================================ 5 stalker
def _stalker_mats(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['stalker']
    sk = skin((104, 112, 108), seed=1501, variation=0.14, tint2=(60, 80, 80), tint2_amount=0.5, veins=0.6,
              vein_color=(20, 70, 70), rot=0.3, rot_color=(50, 60, 50), wounds=0.3, blood=0.3)
    hoodie = cloth(_dim(c, 0.62), seed=1502, weave=0.12, weave_freq=4.5, dirt=0.7, dirt_color=(30, 36, 32), stains=0.6,
                   blood=0.35, tears=0.3)
    pants = cloth((34, 38, 40), seed=1503, weave=0.08, dirt=0.8, dirt_color=(50, 46, 36), stains=0.4)
    return {
        'skin': sk, 'head': dict(sk, seed=1504), 'hand': dict(sk, seed=1505, blood=0.5), 'boot': dict(sk, seed=1506),
        'body': layers(sk,
                       (hoodie, {'meshes': ['torso'], 'z': (J('Bip01 Pelvis')[2] - 0.5 * k, 60), 'ragged': 0.8, 'holes': 0.2,
                                 'seed': 4}, (10, 30, 30)),
                       (hoodie, {'meshes': ['arm'], 't': (-1.0, 1.55), 'ragged': 1.2, 'holes': 0.2, 'seed': 5}, (10, 30, 30)),
                       (pants, {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] - 0.5 * k), 'seed': 6})),
        'legs': layers(sk, (pants, {'meshes': ['leg'], 't': (-1, 1.6), 'ragged': 1.0, 'holes': 0.3, 'seed': 7}, (15, 15, 15))),
        'claw': {'type': 'bone', 'color': (40, 50, 50), 'tip_color': (0, 220, 200), 'tip_dark': 0.85, 'seed': 1507},
        'hood': dict(hoodie, seed=1508), 'coat': dict(hoodie, seed=1509, color=_dim(c, 0.5)),
        'wrap': cloth((90, 96, 86), seed=1510, weave=0.3, weave_freq=7.0, dirt=1.0, blood=0.5),
        'eyeglow': glow((0, 255, 220), (190, 255, 250)),
    }


def stalker(quick=False):
    """5 Stalker (dark teal): skinny, hooded, very long arms with long blade claws, teal glow eyes in the
    hood shadow; deep sneaking knee-bent crouch-walk, wide stance, long silent strides."""
    rs = RigSpec(height=73.0, shoulder_w=0.19, hip_w=0.11, leg=0.53, arm=0.41, hand=0.14, head=0.13, limb_thick=0.72,
                 bulk=0.78)
    return _zspec('stalker', rs,
                  dict(hunch=26.0, lurch=0.2, knee_bend=0.26, stance_w=1.3, walk_D=70.0, run_D=118.0, run_lean=20.0,
                       arm_swing=0.35, claw_spread=1.5, aggression=1.15, crouch_h=0.26),
                  dict(gaunt=0.7, muscle=0.15, chest=0.86, waist=0.78, claw_len=2.3, claw_count=3,
                       head=dict(jaw=0.8, sockets=1.8, cheek=0.7, nose=0.4, mouth_open=0.3, w=0.9)),
                  _stalker_mats,
                  [('hood', dict(mat='hood', depth=1.25, peak=1.4)),
                   ('coat_skirt', dict(mat='coat', length=0.5, flare=0.35)),
                   ('wraps', dict(mat='wrap', where=(('L', 'Forearm', 0.35, 0.95), ('R', 'Forearm', 0.35, 0.95),
                                                     ('L', 'Calf', 0.5, 0.95), ('R', 'Calf', 0.5, 0.95)), grow=0.28)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.55))],
                  dict(eye='glow', glow=(0, 255, 220), mouth='closed', brow_color=None, eye_size=0.8, dark_sockets=0.8),
                  quick=quick)


# ============================================================================================ 6 bomber
def _bomber_mats(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['bomber']
    sk = skin((150, 150, 96), seed=1601, variation=0.2, tint2=(110, 130, 60), tint2_amount=0.6, veins=0.9,
              vein_color=(90, 170, 20), rot=0.5, rot_color=(100, 120, 30), rot_color2=(70, 60, 30), wounds=0.3, blood=0.2)
    shirt = cloth((170, 160, 130), seed=1602, weave=0.08, dirt=1.0, dirt_color=(110, 120, 50), stains=1.0, blood=0.3, tears=0.5)
    pants = cloth((70, 60, 46), seed=1603, weave=0.12, dirt=0.9, dirt_color=(90, 100, 40), stains=0.6)
    return {
        'skin': sk, 'head': dict(sk, seed=1604), 'hand': dict(sk, seed=1605), 'boot': dict(sk, seed=1606),
        'body': layers(sk,
                       (shirt, {'meshes': ['torso'], 'z': (J('Bip01 Spine2')[2], 60), 'x': (-60, 2.5 * k), 'ragged': 1.6,
                                'holes': 0.4, 'seed': 4}, (60, 60, 30)),
                       (shirt, {'meshes': ['arm'], 't': (-1.0, 0.45), 'ragged': 1.4, 'seed': 5}, (60, 60, 30)),
                       (pants, {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] + 0.2 * k), 'ragged': 1.0, 'seed': 6},
                        (40, 30, 20))),
        'legs': layers(sk, (pants, {'meshes': ['leg'], 't': (-1, 1.3), 'ragged': 1.3, 'holes': 0.3, 'seed': 7}, (40, 30, 20))),
        'claw': {'type': 'bone', 'color': (190, 190, 120), 'tip_color': (60, 90, 10), 'tip_dark': 0.8, 'seed': 1607},
        'pustule': {'type': 'glow', 'color': _dim(c, 0.85), 'color2': (230, 255, 150), 'freq': 1.2},
        'shirt': dict(shirt, seed=1608),
        'teeth': {'type': 'bone', 'color': (180, 180, 110), 'seed': 1609},
        'eyeglow': glow(c, (220, 255, 160)),
    }


def _bomber_decals(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    fa = face_anchor(rig, sh)
    c = CLASS_RGB['bomber']
    return [
        dict(kind='sphere', center=J('Bip01 Spine') + np.array([7.5, 0, 1.0]) * k, radius=5.0 * k, scale=(0.6, 1.2, 1.1),
             soft=0.7, color=(90, 140, 20), mode='multiply', alpha=0.5, target=['body', 'torso']),
        dict(kind='sphere', center=fa['mouth'] + np.array([0.3, 0, -1.6]) * k, radius=1.5 * k, scale=(1, 0.9, 2.2), soft=0.6,
             color=c, color2=(60, 120, 0), mode='glow', alpha=0.7),
    ]


def bomber(quick=False):
    """6 Bomber (lime): grossly bloated belly covered in glowing green pustules (also on back, shoulders and
    neck), strained torn shirt; waddling wide-legged gait with heavy side lurch and a limp."""
    rs = RigSpec(height=70.0, shoulder_w=0.23, hip_w=0.14, leg=0.47, arm=0.34, hand=0.115, head=0.14, bulk=1.25,
                 limb_thick=1.1)

    def acc(rig, sh):
        return [
            (pustules, dict(mat='pustule', seed=5, where=[
                ('Bip01 Spine', (8.5, 0, 0.5), 1.5, 9, (1.0, 4.5, 3.5)),
                ('Bip01 Spine1', (7.0, 0, 1.5), 1.2, 4, (1.0, 4.0, 2.0)),
                ('Bip01 Spine2', (-5.0, 0, 0), 1.3, 6, (1.0, 4.5, 3.0)),
                ('Bip01 L UpperArm', (0, 2.2, -3.0), 0.9, 3, (1.2, 0.6, 2.5)),
                ('Bip01 R UpperArm', (0, -2.2, -3.0), 0.9, 3, (1.2, 0.6, 2.5)),
                ('Bip01 Neck', (0, 2.0, 0.5), 0.8, 2, (1.0, 0.5, 0.8)),
                ('Bip01 L Thigh', (2.0, 1.5, -6.0), 0.9, 2, (1.0, 1.0, 3.0))])),
            ('shirt_flaps', dict(mat='shirt', n=6, length=4.5, seed=17)),
            ('jaw_teeth', dict(mat='teeth', n=5, size=0.9)),
            ('glow_eyes', dict(mat='eyeglow', size=0.5)),
        ]
    return _zspec('bomber', rs,
                  dict(hunch=8.0, lurch=1.0, limp=0.3, heavy=0.35, walk_D=50.0, run_D=82.0, run_lean=6.0, stance_w=1.4,
                       arm_swing=0.75, knee_bend=0.14, aggression=0.9, claw_spread=0.9),
                  dict(belly=1.25, chest=1.1, waist=1.3, hips=1.15, muscle=0.05, gaunt=0.0, claw_len=0.7,
                       head=dict(jaw=1.2, cheek=1.5, sockets=1.2, mouth_open=0.8, jaw_drop=0.3, w=1.08)),
                  _bomber_mats, acc,
                  dict(eye='glow', glow=(160, 255, 40), mouth='open', teeth=(180, 180, 110), brow_color=None, eye_size=0.8),
                  decals=_bomber_decals, quick=quick)


# ============================================================================================ 7 frost
def _frost_mats(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['frost']
    sk = skin((172, 200, 222), seed=1701, variation=0.12, tint2=(220, 235, 250), tint2_amount=0.6, veins=0.8,
              vein_color=(20, 70, 160), rot=0.15, rot_color=(120, 150, 190), wounds=0.25, blood=0.1, scars=0.3)
    parka = cloth((52, 66, 90), seed=1702, weave=0.1, weave_freq=3.5, dirt=0.8, dirt_color=(220, 235, 250), dirt_z=60,
                  stains=0.3, tears=0.4, blood=0.15)
    return {
        'skin': sk, 'head': dict(sk, seed=1703), 'hand': dict(sk, seed=1704), 'boot': dict(sk, seed=1705),
        'body': layers(sk,
                       (parka, {'meshes': ['torso'], 'z': (-60, J('Bip01 Spine2')[2] + 1.0 * k), 'ragged': 1.5, 'holes': 0.35,
                                'seed': 4}, (200, 225, 245)),
                       (parka, {'meshes': ['arm'], 't': (0.55, 1.4), 'ragged': 1.4, 'holes': 0.3, 'seed': 5}, (200, 225, 245))),
        'legs': layers(sk, (parka, {'meshes': ['leg'], 't': (-1, 1.5), 'ragged': 1.3, 'holes': 0.3, 'seed': 6},
                            (200, 225, 245))),
        'claw': {'type': 'crystal', 'color': (150, 220, 255), 'seed': 1706},
        'ice': {'type': 'crystal', 'color': _mix(c, (230, 250, 255), 0.35), 'seed': 1707},
        'hair': {'type': 'hair', 'color': (225, 238, 250), 'tip': (120, 190, 240), 'seed': 1708},
        'teeth': {'type': 'bone', 'color': (210, 225, 235), 'seed': 1709},
        'eyeglow': glow(c, (220, 250, 255)),
    }


def frost(quick=False):
    """7 Frost (ice blue): blue-white frozen skin with dark-blue veins, ice crystal clusters growing from
    back, shoulders, head, forearms and knee, frosted rags; stiff frozen gait (straight knees, limp)."""
    rs = RigSpec(height=72.0, shoulder_w=0.225, hip_w=0.12, leg=0.5, arm=0.355, hand=0.115, head=0.14, limb_thick=1.0,
                 bulk=1.05)
    return _zspec('frost', rs,
                  dict(hunch=14.0, lurch=0.45, limp=0.45, knee_bend=0.04, walk_D=54.0, run_D=90.0, run_lean=8.0,
                       arm_swing=0.45, stance_w=1.1, aggression=0.85, claw_spread=1.2),
                  dict(gaunt=0.3, muscle=0.35, hump=0.2, claw_len=1.1,
                       head=dict(jaw=1.1, sockets=1.4, brow=1.3, mouth_open=0.5, jaw_drop=0.25)),
                  _frost_mats,
                  [('crystals', dict(mat='ice', size=1.15, seed=31, where=(
                      ('Bip01 Spine3', (-4.0, 2.4, 1.0)), ('Bip01 Spine2', (-4.2, -2.6, 0.0)), ('Bip01 Spine1', (-4.0, 1.0, 0.0)),
                      ('Bip01 L UpperArm', (0, 1.8, 0.5)), ('Bip01 R UpperArm', (0, -1.8, 0.5)),
                      ('Bip01 Head', (-1.0, 1.0, 7.4)), ('Bip01 L Forearm', (0.5, 1.2, -4.0)),
                      ('Bip01 R Calf', (1.5, -0.5, -2.0))))),
                   ('hair', dict(mat='hair', volume=0.45)),
                   ('jaw_teeth', dict(mat='teeth', n=5, size=1.0)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.55))],
                  dict(eye='glow', glow=(80, 220, 255), mouth='snarl', teeth=(210, 225, 235), brow_color=None, eye_size=0.85),
                  quick=quick)


# ============================================================================================ 8 spitter
def _spitter_mats(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['spitter']
    sk = skin((140, 146, 90), seed=1801, variation=0.18, tint2=(170, 170, 70), tint2_amount=0.5, veins=0.8,
              vein_color=(150, 200, 20), rot=0.55, rot_color=(110, 100, 40), wounds=0.45, blood=0.2, scars=0.3)
    rags = cloth((80, 74, 54), seed=1802, weave=0.12, dirt=1.0, dirt_color=(120, 140, 40), stains=1.0, tears=0.5, blood=0.2)
    acid = {'type': 'glow', 'color': _dim(c, 0.9), 'color2': (240, 255, 140), 'freq': 1.0}
    return {
        'skin': sk, 'head': dict(sk, seed=1803), 'hand': dict(sk, seed=1804), 'boot': dict(sk, seed=1805),
        'body': layers(sk,
                       (rags, {'meshes': ['torso'], 'z': (-60, J('Bip01 Spine1')[2]), 'ragged': 1.6, 'holes': 0.4, 'seed': 4},
                        (50, 50, 20)),
                       (rags, {'meshes': ['arm'], 't': (-1, 0.35), 'ragged': 1.4, 'seed': 5}, (50, 50, 20))),
        'legs': layers(sk, (rags, {'meshes': ['leg'], 't': (-1, 1.0), 'ragged': 1.5, 'holes': 0.4, 'seed': 6}, (50, 50, 20))),
        'claw': {'type': 'bone', 'color': (200, 200, 120), 'tip_color': (90, 140, 0), 'tip_dark': 0.8, 'seed': 1806},
        'sac': layers(dict(sk, color=(180, 200, 80), veins=1.0, vein_color=(220, 255, 60), seed=1807),
                      (acid, {'holes': 0.5, 'hole_freq': 0.5, 'hole_size': 0.4, 'seed': 8})),
        'acid': acid, 'bone': {'type': 'bone', 'color': (210, 200, 150), 'seed': 1808},
        'teeth': {'type': 'bone', 'color': (200, 200, 120), 'seed': 1809},
        'eyeglow': glow(c, (240, 255, 170)),
    }


def _spitter_decals(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    fa = face_anchor(rig, sh)
    c = CLASS_RGB['spitter']
    return [
        dict(kind='sphere', center=fa['mouth'] + np.array([0.4, 0, -1.6]) * k, radius=1.6 * k, scale=(1, 0.9, 2.4),
             soft=0.5, color=c, color2=(80, 160, 0), mode='glow', alpha=0.9),
        dict(kind='band', normal=(0, 1, 0), offset=0.3 * k, width=1.8 * k, soft=0.7, color=c, mode='glow', alpha=0.75,
             region=((J('Bip01 Spine')[0] + 2.0, -10, J('Bip01 Spine1')[2]), (20, 10, J('Bip01 Neck')[2])),
             target=['body', 'torso']),
        dict(kind='sphere', center=J('Bip01 Spine2') + np.array([5.0, -3.0, -2.0]) * k, radius=2.4 * k, soft=0.6,
             color=(60, 70, 10), mode='multiply', alpha=0.7, target=['body', 'torso']),
    ]


def spitter(quick=False):
    """8 Spitter (yellow-green): long craning neck with a glowing acid sac under the jaw, acid drool down
    the chest, acid blisters on the back, exposed ribs; head-bobbing forward lurch."""
    rs = RigSpec(height=74.0, shoulder_w=0.2, hip_w=0.11, leg=0.5, arm=0.36, hand=0.115, head=0.125, neck=0.085,
                 limb_thick=0.82, bulk=0.85)

    def acc(rig, sh):
        return [
            (throat_sac, dict(mat='sac', size=1.0)),
            (pustules, dict(mat='acid', seed=9, where=[('Bip01 Spine2', (-4.6, 0, 0.5), 1.0, 5, (0.6, 3.5, 2.5)),
                                                        ('Bip01 Spine3', (-3.8, 0, 1.5), 0.8, 3, (0.6, 3.0, 1.5))])),
            ('ribs', dict(mat='bone', count=4, exposed_side=-1)),
            ('jaw_teeth', dict(mat='teeth', n=6, size=1.0)),
            ('glow_eyes', dict(mat='eyeglow', size=0.5)),
        ]
    return _zspec('spitter', rs,
                  dict(hunch=24.0, lurch=0.55, limp=0.15, walk_D=62.0, run_D=98.0, run_lean=14.0, arm_swing=0.9,
                       knee_bend=0.13, stance_w=1.0, aggression=1.2, claw_spread=1.0),
                  dict(gaunt=0.6, muscle=0.15, chest=0.92, waist=0.8, neck=0.75, neck_len=2.0, claw_len=1.0,
                       head=dict(jaw=1.3, snout=0.3, sockets=1.5, mouth_open=1.0, jaw_drop=0.6, nose=0.3, d=1.1)),
                  _spitter_mats, acc,
                  dict(eye='glow', glow=(180, 255, 40), mouth='open', teeth=(200, 200, 120), brow_color=None, eye_size=0.8),
                  decals=_spitter_decals, quick=quick)


# ============================================================================================ 9 hulk
def _hulk_mats(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['hulk']
    sk = skin((112, 96, 88), seed=1901, variation=0.2, tint2=(140, 90, 70), tint2_amount=0.45, veins=0.8,
              vein_color=(255, 100, 0), scars=0.9, wounds=0.4, blood=0.2, pores=0.3)
    wound = {'type': 'lava', 'color': (90, 60, 50), 'hot': c, 'core': (255, 200, 110), 'freq': 0.5, 'crack_width': 0.06,
             'seed': 1902}
    pants = cloth((52, 50, 60), seed=1903, weave=0.1, dirt=0.9, dirt_color=(80, 60, 40), stains=0.6, blood=0.4, tears=0.5)
    return {
        'skin': sk, 'head': dict(sk, seed=1904), 'hand': dict(sk, seed=1905, blood=0.5), 'boot': dict(sk, seed=1906),
        'body': layers(sk,
                       (wound, {'meshes': ['arm'], 't': (0.3, 1.9), 'x': (-60, 0.0), 'ragged': 1.8, 'holes': 0.55,
                                'hole_freq': 0.2, 'seed': 4}),
                       (wound, {'meshes': ['torso'], 'z': (J('Bip01 Spine1')[2], J('Bip01 Neck')[2]), 'x': (-60, -2.0 * k),
                                'ragged': 2.0, 'holes': 0.5, 'hole_freq': 0.18, 'seed': 5}),
                       (pants, {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] + 1.0 * k), 'ragged': 1.2, 'seed': 6},
                        (30, 30, 30))),
        'legs': layers(sk, (pants, {'meshes': ['leg'], 't': (-1, 0.9), 'ragged': 1.5, 'holes': 0.3, 'seed': 7}, (30, 30, 30))),
        'claw': {'type': 'bone', 'color': (150, 120, 100), 'tip_color': (255, 110, 20), 'tip_dark': 0.6, 'seed': 1907},
        'wound': wound, 'bone': {'type': 'bone', 'color': (200, 180, 150), 'seed': 1908},
        'teeth': {'type': 'bone', 'color': (190, 170, 130), 'seed': 1909},
        'eyeglow': glow(c, (255, 210, 140)),
    }


def _hulk_decals(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['hulk']
    D = []
    for bone, off, r in (('Bip01 Spine2', (6.5, 2.5, 1.0), 2.0), ('Bip01 Spine', (6.8, -3.0, 0.5), 1.6),
                         ('Bip01 L Thigh', (2.5, 1.5, -6.0), 1.4)):
        D.append(dict(kind='sphere', center=J(bone) + np.array(off) * k, radius=r * k, scale=(0.6, 1.0, 1.7), soft=0.45,
                      color=c, color2=(120, 20, 0), mode='glow', alpha=0.9, target=['body', 'torso', 'legs']))
    return D


def hulk(quick=False):
    """9 Hulk (orange): giant hunched body with massive arms and fists hanging to the knees, glowing orange
    wound cracks on arms/back/chest, bone spurs; knuckle-dragging heavy gait with wide arm swing."""
    rs = RigSpec(height=74.0, shoulder_w=0.34, hip_w=0.14, leg=0.43, arm=0.43, hand=0.155, head=0.11, bulk=1.55,
                 limb_thick=1.45, arm_thick=1.4, leg_thick=1.1)
    return _zspec('hulk', rs,
                  dict(hunch=32.0, heavy=0.85, lurch=0.5, walk_D=58.0, run_D=94.0, run_lean=12.0, stance_w=1.45,
                       arm_swing=1.35, knee_bend=0.18, aggression=1.3, claw_spread=0.7),
                  dict(muscle=1.0, hump=0.8, chest=1.25, waist=0.95, shoulders=1.25, arm=1.15, forearm=1.3, claw_len=0.55,
                       head=dict(jaw=1.7, brow=1.9, w=1.0, sockets=1.1, ears=0.4, mouth_open=0.4, cranium=0.9)),
                  _hulk_mats,
                  [('spikes', dict(mat='bone', n=5, length=3.2, radius=0.9, seed=41)),
                   ('shoulder_pads', dict(mat='wound', size=1.0, spikes=3, spike_mat='bone')),
                   ('jaw_teeth', dict(mat='teeth', n=4, size=1.3)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.5))],
                  dict(eye='glow', glow=(255, 120, 20), mouth='snarl', teeth=(190, 170, 130), brow_color=None, eye_size=0.7),
                  decals=_hulk_decals, quick=quick)


# ============================================================================================ 10 voodoo
def _voodoo_mats(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['voodoo']
    sk = skin((88, 72, 84), seed=2001, variation=0.18, tint2=(70, 50, 80), tint2_amount=0.6, veins=0.6,
              vein_color=(200, 0, 150), rot=0.3, rot_color=(60, 50, 50), wounds=0.25, blood=0.2, scars=0.4)
    straw = {'type': 'fur', 'color': (120, 92, 54), 'seed': 2002}
    wrap = cloth((90, 30, 80), seed=2003, weave=0.2, weave_freq=5.0, dirt=0.7, dirt_color=(50, 30, 30), stains=0.6, tears=0.4,
                 stripes=[dict(normal=(0, 0, 1), offset=J('Bip01 Pelvis')[2] - i * 2.0 * k, width=0.5 * k, color=(220, 40, 170))
                          for i in range(1, 6)])
    return {
        'skin': sk, 'head': dict(sk, seed=2004), 'hand': dict(sk, seed=2005), 'boot': dict(sk, seed=2006),
        'body': layers(sk, (wrap, {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] + 1.4 * k), 'ragged': 1.0, 'seed': 4},
                            (40, 10, 40))),
        'legs': layers(sk, (wrap, {'meshes': ['leg'], 't': (-1, 0.55), 'ragged': 1.3, 'seed': 5}, (40, 10, 40))),
        'claw': {'type': 'bone', 'color': (220, 210, 190), 'tip_color': (180, 0, 130), 'tip_dark': 0.7, 'seed': 2007},
        'mask': layers({'type': 'bone', 'color': (214, 204, 180), 'seed': 2008},
                       ({'type': 'flat', 'color': (40, 10, 30)}, {'z': (J('Bip01 Head')[2] + 2.4 * k, J('Bip01 Head')[2] + 3.2 * k),
                                                                   'y': (-2.6 * k, 2.6 * k), 'holes': 0.0})),
        'bone': {'type': 'bone', 'color': (220, 210, 185), 'seed': 2009},
        'straw': straw, 'skirt': dict(straw, seed=2010, color=(104, 78, 44)),
        'horn': {'type': 'horn', 'color': (60, 40, 50), 'tip_color': c, 'tip_dark': 0.6, 'seed': 2011},
        'hair': {'type': 'hair', 'color': (28, 20, 26), 'tip': (120, 20, 90), 'seed': 2012},
        'rope': {'type': 'leather', 'color': (70, 50, 34), 'seed': 2013},
        'eyeglow': glow(c, (255, 170, 230)),
    }


def _voodoo_decals(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['voodoo']
    pk = (190, 60, 255)
    fa = face_anchor(rig, sh)
    D = []
    # glowing ritual tattoos: chest sigil, back sigil, rings on arms and thighs
    D.append(dict(kind='shape', shape='ring', center=J('Bip01 Spine2') + np.array([6.6, 0, 0.5]) * k, u=(0, -1, 0), v=(0, 0, 1),
                  size=2.6 * k, soft=0.25, color=c, mode='glow', depth=3.0, target=['body', 'torso']))
    D.append(dict(kind='shape', shape='diamond', center=J('Bip01 Spine2') + np.array([6.6, 0, 0.5]) * k, u=(0, -1, 0),
                  v=(0, 0, 1), size=1.3 * k, soft=0.25, color=pk, mode='glow', depth=3.0, target=['body', 'torso']))
    D.append(dict(kind='shape', shape='skull', center=J('Bip01 Spine2') + np.array([-6.0, 0, 1.0]) * k, u=(0, 1, 0), v=(0, 0, 1),
                  size=2.4 * k, soft=0.25, color=c, mode='glow', depth=3.0, target=['body', 'torso']))
    for i, z in enumerate((J('Bip01 Spine')[2], J('Bip01 Spine1')[2] + 0.5 * k)):
        D.append(dict(kind='shape', shape='chevron', center=J('Bip01 Spine') + np.array([6.4, 0, z - J('Bip01 Spine')[2] - 1.0 * k]),
                      u=(0, -1, 0), v=(0, 0, 1), size=1.4 * k, soft=0.25, color=pk, mode='glow', depth=3.0,
                      target=['body', 'torso']))
    for side in ('L', 'R'):
        for bone, fr in (('UpperArm', 0.45), ('Forearm', 0.5)):
            a = J('Bip01 %s %s' % (side, bone))
            nxt = J('Bip01 %s %s' % (side, 'Forearm' if bone == 'UpperArm' else 'Hand'))
            p = a + (nxt - a) * fr
            d = nxt - a
            d = d / np.linalg.norm(d)
            D.append(dict(kind='band', normal=tuple(d), offset=float(np.dot(p, d)), width=0.6 * k, soft=0.3, color=c,
                          mode='glow', region=(tuple(p - 4.0 * k), tuple(p + 4.0 * k)), target=['body']))
    # mask eye holes (dark) with a magenta glow inside
    for e in ('eye_L', 'eye_R'):
        D.append(dict(kind='sphere', center=fa[e] + np.array([1.4, 0, 0]) * k, radius=0.9 * k, scale=(1.0, 1.0, 0.7), soft=0.3,
                      color=(255, 120, 220), color2=c, mode='glow', target='mask'))
    D.append(dict(kind='shape', shape='cross', center=fa['center'] + np.array([fa['radii'][0] * 1.9, 0, 2.6 * k]),
                  u=(0, -1, 0), v=(0, 0, 1), size=0.9 * k, soft=0.3, color=(120, 0, 80), mode='paint', depth=2.0, target='mask'))
    return D


def voodoo(quick=False):
    """10 Voodoo (magenta): witch-doctor zombie with a carved bone mask and small horns, bone-charm
    necklace, glowing magenta ritual tattoos, straw skirt and dreadlock hair; swaying ritual gait."""
    rs = RigSpec(height=72.0, shoulder_w=0.21, hip_w=0.115, leg=0.51, arm=0.37, hand=0.12, head=0.14, limb_thick=0.85,
                 bulk=0.9)

    def acc(rig, sh):
        k = rig.H / 72.0
        return [
            (face_mask, dict(mat='mask', horn_mat='horn')),
            ('hair', dict(mat='hair', volume=0.9, length=12.0, style='long')),
            ('chain', dict(mat='rope', points=_chain_pts(rig, k, 1.5), bones=[_bi(rig, 'Bip01 Spine3')] * 3, link=0.8)),
            (bone_charms, dict(mat='bone', n=7)),
            ('coat_skirt', dict(mat='skirt', length=0.55, flare=0.5)),
            ('wraps', dict(mat='rope', where=(('L', 'Forearm', 0.8, 0.95), ('R', 'Forearm', 0.8, 0.95),
                                              ('L', 'Calf', 0.75, 0.9)), grow=0.25)),
            ('glow_eyes', dict(mat='eyeglow', size=0.4)),
        ]
    return _zspec('voodoo', rs,
                  dict(hunch=12.0, lurch=0.75, limp=0.0, walk_D=58.0, run_D=96.0, run_lean=10.0, arm_swing=1.25,
                       knee_bend=0.15, stance_w=1.15, aggression=0.95, claw_spread=1.45),
                  dict(gaunt=0.45, muscle=0.25, chest=0.95, waist=0.82, claw_len=1.2,
                       head=dict(jaw=1.0, sockets=1.3, mouth_open=0.3)),
                  _voodoo_mats, acc,
                  dict(eye='glow', glow=(255, 60, 200), mouth='closed', brow_color=None, eye_size=0.7),
                  decals=_voodoo_decals, quick=quick)


# ============================================================================================ 11 phantom
def _phantom_mats(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    c = CLASS_RGB['phantom']
    ecto = skin((134, 134, 196), seed=2101, variation=0.15, tint2=(100, 90, 200), tint2_amount=0.6, veins=0.9,
                vein_color=(190, 200, 255), rot=0.15, rot_color=(90, 80, 160), wounds=0.0, blood=0.0)
    mist = cloth(_dim(c, 0.55), seed=2102, weave=0.3, weave_freq=4.0, dirt=0.5, dirt_color=(30, 20, 70), tears=0.6, stains=0.2)
    wisp = {'type': 'glow', 'color': _dim(c, 0.9), 'color2': (210, 210, 255), 'freq': 0.9}
    return {
        'skin': ecto, 'head': dict(ecto, seed=2103), 'hand': dict(ecto, seed=2104), 'boot': dict(ecto, seed=2105),
        'body': layers(ecto,
                       (mist, {'meshes': ['torso'], 'z': (-60, J('Bip01 Spine3')[2] + 1.6 * k), 'ragged': 1.8, 'holes': 0.35,
                               'seed': 4}, (60, 60, 160)),
                       (mist, {'meshes': ['arm'], 't': (0.3, 1.8), 'ragged': 1.8, 'holes': 0.4, 'seed': 5}, (60, 60, 160))),
        'legs': layers(dict(ecto, color=(90, 90, 170)),
                       (mist, {'meshes': ['leg'], 't': (-1, 1.7), 'ragged': 1.5, 'holes': 0.3, 'seed': 6}, (60, 60, 160)),
                       (wisp, {'meshes': ['leg'], 't': (1.6, 9), 'ragged': 1.5, 'seed': 7})),
        'claw': {'type': 'crystal', 'color': (160, 160, 255), 'seed': 2106},
        'shroud': layers(dict(mist, seed=2107, color=_dim(c, 0.48)),
                         (wisp, {'z': (-60, J('Bip01 Pelvis')[2] - 12.0 * k), 'ragged': 2.0, 'seed': 8})),
        'hood': dict(mist, seed=2108, color=_dim(c, 0.4)),
        'wisp': wisp,
        'eyeglow': glow((200, 200, 255), (255, 255, 255)),
    }


def phantom(quick=False):
    """11 Phantom (blue-violet): hovering hooded spirit ('floaty' style: dangling legs, glide locomotion,
    deaths drop to the floor) wrapped in glowing blue-purple mist cloth, ghostly crystal claws."""
    rs = RigSpec(height=68.0, shoulder_w=0.2, hip_w=0.11, leg=0.5, arm=0.39, hand=0.13, head=0.14, limb_thick=0.75,
                 bulk=0.8)
    return _zspec('phantom', rs,
                  dict(hunch=10.0, float_h=5.0, lurch=0.15, arm_swing=0.5, claw_spread=1.4, aggression=1.1),
                  dict(gaunt=0.6, muscle=0.05, chest=0.88, waist=0.75, claw_len=1.6,
                       head=dict(jaw=0.8, sockets=1.9, cheek=0.7, nose=0.2, mouth_open=0.7, jaw_drop=0.4, w=0.92)),
                  _phantom_mats,
                  [('hood', dict(mat='hood', depth=1.15, peak=1.2)),
                   ('cape', dict(mat='shroud', length=0.9, width=13.0, tatter=0.7, flare=0.4)),
                   ('coat_skirt', dict(mat='shroud', length=0.95, flare=0.6)),
                   ('shirt_flaps', dict(mat='wisp', n=5, length=5.0, seed=23)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.65))],
                  dict(eye='glow', glow=(210, 210, 255), mouth='open', teeth=(190, 190, 230), brow_color=None, eye_size=1.0,
                       dark_sockets=0.8),
                  style='floaty', quick=quick)


# ============================================================================================ all
ORDER = [walker, runner, tank, banshee, leech, stalker, bomber, frost, spitter, hulk, voodoo, phantom]


def all(quick=False):      # noqa: A001  (CLI entry name)
    """All 12 classes (0-11) in class order, each with claws."""
    return [f(quick) for f in ORDER]


def new(quick=False):
    """Classes 1-11 (walker is the reference sample, already built)."""
    return [f(quick) for f in ORDER[1:]]
