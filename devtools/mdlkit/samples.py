"""Proof samples (also the reference examples for content agents).

    python3 -m mdlkit.samples walker|operator|claws|pak47|all [--quick] [--lookdev]

Outputs:
    cstrike/models/player/vex_z_walker/vex_z_walker.mdl
    cstrike/models/player/vex_operator/vex_operator.mdl
    cstrike/models/vexmira/claws/v_walker.mdl
    cstrike/models/vexmira/weapons/p_ak47.mdl
"""
import sys
import numpy as np

from .rig_cs import RigSpec


# =============================================================================================== walker

def walker_materials(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    belt_z = J('Bip01 Pelvis')[2] + 0.8 * k
    skin = {'type': 'skin', 'color': (128, 140, 104), 'variation': 0.16, 'tint2': (110, 95, 120), 'tint2_amount': 0.5,
            'veins': 0.75, 'vein_color': (62, 40, 70), 'rot': 0.55, 'rot_color': (72, 92, 40), 'rot_color2': (58, 40, 30),
            'wounds': 0.5, 'blood': 0.35, 'pores': 0.16, 'seed': 11}
    shirt = {'type': 'cloth', 'color': (92, 86, 70), 'plaid': (112, 30, 26), 'plaid_line': (30, 24, 20),
             'plaid_size': 2.3, 'weave': 0.08, 'dirt': 0.8, 'dirt_color': (60, 50, 34), 'stains': 0.9, 'blood': 0.65,
             'seed': 21, 'tears': 0.0}
    jeans = {'type': 'cloth', 'color': (52, 62, 82), 'weave': 0.12, 'weave_freq': 4.0, 'dirt': 0.85, 'dirt_z': 0,
             'dirt_color': (70, 58, 40), 'stains': 0.6, 'blood': 0.3, 'seed': 31, 'fold_freq': 0.25}
    shoe = {'type': 'leather', 'color': (62, 45, 32), 'blood': 0.2, 'seed': 41}
    return {
        'skin': skin,
        'head': dict(skin, rot=0.4, wounds=0.3, blood=0.5, seed=12),
        'hand': dict(skin, blood=0.7, seed=13),
        'body': {'type': 'layers', 'base': skin, 'layers': [
            {'mat': shirt, 'where': {'meshes': ['torso'], 'z': (belt_z - 1.0 * k, 60), 'ragged': 1.4, 'holes': 0.35,
                                     'hole_freq': 0.13, 'hole_size': 0.36, 'seed': 5}, 'edge': (40, 30, 25)},
            {'mat': shirt, 'where': {'meshes': ['arm'], 't': (-1.0, 0.62), 'ragged': 1.2, 'holes': 0.2, 'seed': 6},
             'edge': (40, 30, 25)},
            {'mat': jeans, 'where': {'meshes': ['torso'], 'z': (-60, belt_z), 'ragged': 0.4, 'seed': 7},
             'edge': (30, 25, 20)},
            {'mat': {'type': 'leather', 'color': (45, 32, 24), 'seed': 8},
             'where': {'meshes': ['torso'], 'z': (belt_z - 0.9 * k, belt_z + 0.5 * k), 'soft': 0.25}},
        ]},
        'legs': {'type': 'layers', 'base': skin, 'layers': [
            {'mat': jeans, 'where': {'meshes': ['leg'], 't': (-1.0, 1.82), 'ragged': 1.0, 'holes': 0.3,
                                     'hole_freq': 0.15, 'hole_size': 0.32, 'seed': 9}, 'edge': (90, 90, 95)},
        ]},
        'boot': {'type': 'layers', 'base': dict(skin, seed=14), 'layers': [
            {'mat': shoe, 'where': {'meshes': ['foot_L']}}]},
        'claw': {'type': 'bone', 'color': (196, 178, 120), 'tip_color': (40, 20, 15), 'tip_dark': 0.85, 'seed': 51},
        'shirt': dict(shirt, blood=0.5, seed=22),
        'hair': {'type': 'hair', 'color': (38, 32, 26), 'tip': (70, 62, 50), 'seed': 61},
        'bone': {'type': 'bone', 'color': (205, 195, 160), 'seed': 71},
        'teeth': {'type': 'bone', 'color': (190, 175, 120), 'seed': 72, 'tip_dark': 0.2},
        'eyeglow': {'type': 'glow', 'color': (140, 255, 40), 'color2': (230, 255, 160)},
    }


def walker_decals(rig, sh):
    from .body import face_anchor
    fa = face_anchor(rig, sh)
    k = fa['k']
    J = rig.J
    return [
        # blood drool from the mouth down the chin/neck/shirt
        dict(kind='sphere', center=fa['mouth'] + np.array([0.2, 0, -1.3]) * k, radius=1.6 * k, scale=(1, 0.9, 1.8),
             soft=0.6, color=(110, 8, 10), color2=(60, 0, 4), alpha=0.85),
        dict(kind='band', normal=(0, 1, 0), offset=0.8 * k, width=2.2 * k, soft=0.8, color=(100, 6, 8), alpha=0.75,
             region=((J('Bip01 Spine')[0] + 2.0, -10, J('Bip01 Spine1')[2]), (20, 10, J('Bip01 Neck')[2])),
             target=['body', 'torso']),
        # bite wound on the left shoulder / neck
        dict(kind='sphere', center=J('Bip01 L Clavicle') + np.array([1.0, 4.5, 2.5]) * k, radius=2.4 * k, soft=0.5,
             color=(90, 5, 8), color2=(40, 0, 3), alpha=0.95),
        # open wound behind the exposed ribs (left flank)
        dict(kind='sphere', center=J('Bip01 Spine2') + np.array([3.0, 5.2, -1.6]) * k, radius=3.2 * k, scale=(1.2, 0.8, 1.3),
             soft=0.45, color=(70, 4, 6), color2=(25, 0, 2), alpha=0.95, target=['body', 'torso']),
        # dark sunken sockets
        dict(kind='sphere', center=fa['eye_L'], radius=1.5 * k, scale=(1.0, 1.0, 0.8), soft=0.7, color=(40, 30, 35),
             mode='multiply', alpha=0.8, target='head'),
        dict(kind='sphere', center=fa['eye_R'], radius=1.5 * k, scale=(1.0, 1.0, 0.8), soft=0.7, color=(40, 30, 35),
             mode='multiply', alpha=0.8, target='head'),
    ]


def walker_spec(quick=False):
    rs = RigSpec.preset('zombie')
    rs.hand_pose = 'claw'
    return dict(
        name='vex_z_walker', style='zombie', rig=rs,
        style_params=dict(hunch=20.0, lurch=0.7, limp=0.25),
        shape=dict(hands='claw', feet='bare', gaunt=0.35, hump=0.22, muscle=0.15, claw_len=0.9,
                   head=dict(jaw_drop=0.35, sockets=1.5, cheek=1.2, mouth_open=0.7, brow=1.3, nose=0.6)),
        mats=dict(torso='body', arm='body', leg='legs', foot='boot', hand='hand', neck='skin', head='head', claw='claw'),
        materials=walker_materials,
        decals=walker_decals,
        face=dict(eye='glow', glow=(150, 255, 50), mouth='snarl', teeth=(200, 185, 130), brow_color=None, eye_size=0.9),
        accessories=[('shirt_flaps', dict(mat='shirt', n=7, length=7.0, seed=4)),
                     ('hair', dict(mat='hair', volume=0.5)),
                     ('ribs', dict(mat='bone', count=3, exposed_side=1)),
                     ('glow_eyes', dict(mat='eyeglow', size=0.5))],
        tex=dict(w=512, h=256, pages=1) if not quick else dict(w=256, h=256, pages=1),
        budget=0.45e6,
    )


# =============================================================================================== operator

NAVY = (46, 58, 90)
CYAN = (0, 220, 255)
PURPLE = (160, 90, 255)


def operator_materials(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    uni = {'type': 'cloth', 'color': NAVY, 'weave': 0.09, 'weave_freq': 3.6, 'dirt': 0.35, 'dirt_z': 15,
           'dirt_color': (60, 58, 52), 'stains': 0.25, 'seed': 101, 'fold_freq': 0.22}
    pants = dict(uni, color=(48, 56, 78), dirt=0.55, seed=102)
    skin = {'type': 'skin', 'color': (196, 152, 122), 'variation': 0.07, 'pores': 0.07, 'seed': 103,
            'tint2': (200, 130, 120), 'tint2_amount': 0.25}
    glove = {'type': 'leather', 'color': (46, 46, 50), 'seed': 104}
    boot = {'type': 'leather', 'color': (40, 38, 36), 'seed': 105}
    cyan_glow = {'type': 'glow', 'color': CYAN, 'color2': (200, 255, 255), 'freq': 0.8}
    return {
        'skin': skin,
        'head': skin,
        'hand': {'type': 'layers', 'base': glove, 'layers': [
            {'mat': {'type': 'rubber', 'color': (22, 22, 24)}, 'where': {'meshes': ['fingers', 'thumb']}}]},
        'body': {'type': 'layers', 'base': uni, 'layers': [
            # elbow pads / cuffs
            {'mat': {'type': 'rubber', 'color': (24, 26, 34)}, 'where': {'meshes': ['arm'], 't': (0.88, 1.12)}},
            {'mat': dict(uni, color=(26, 32, 48)), 'where': {'meshes': ['arm'], 't': (1.86, 2.1)}},
            # cyan stripe around the upper arms
            {'mat': cyan_glow, 'where': {'meshes': ['arm'], 't': (0.42, 0.5)}},
            {'mat': pants, 'where': {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] + 0.5 * k), 'soft': 0.3}},
        ]},
        'legs': {'type': 'layers', 'base': pants, 'layers': [
            {'mat': {'type': 'rubber', 'color': (24, 26, 34)}, 'where': {'meshes': ['leg'], 't': (1.62, 2.1)}},
            {'mat': cyan_glow, 'where': {'meshes': ['leg'], 't': (0.3, 0.36), 'x': (-3, 20)}},
        ]},
        'boot': {'type': 'layers', 'base': boot, 'layers': [
            {'mat': {'type': 'rubber', 'color': (55, 52, 48)}, 'where': {'z': (-60, -35.0), 'soft': 0.2}}]},
        'helmet': {'type': 'layers', 'base': {'type': 'metal', 'color': (60, 66, 82), 'paint': (44, 56, 86),
                                               'chipping': 0.25, 'scratches': 0.3, 'shine': 0.25, 'seed': 106},
                   'layers': [{'mat': cyan_glow, 'where': {'y': (-0.35 * k, 0.35 * k), 'x': (-20, 20), 'z': (J('Bip01 Head')[2] + 6.4 * k, 60)}}]},
        'goggle_frame': {'type': 'rubber', 'color': (20, 20, 22)},
        'lens': {'type': 'visor', 'color': (0, 170, 230), 'color2': (190, 250, 255)},
        'vest': {'type': 'layers', 'base': {'type': 'cloth', 'color': (62, 68, 78), 'weave': 0.06, 'weave_freq': 5.0,
                                             'stripes': [dict(normal=(0, 0, 1), offset=J('Bip01 Spine') [2] + i * 2.2 * k, width=0.7 * k,
                                                              color=(44, 48, 56)) for i in range(1, 8)],
                                             'dirt': 0.3, 'seed': 107},
                 'layers': [{'mat': cyan_glow, 'where': {'x': (2.0 * k, 30), 'z': (J('Bip01 Spine3')[2] + 1.2 * k, J('Bip01 Spine3')[2] + 1.6 * k), 'soft': 0.15}}]},
        'plate': {'type': 'metal', 'color': (80, 88, 104), 'paint': (40, 50, 76), 'chipping': 0.35, 'edge_wear': 0.8,
                  'scratches': 0.4, 'shine': 0.3, 'seed': 108},
        'pouch': {'type': 'cloth', 'color': (66, 72, 82), 'weave': 0.15, 'weave_freq': 6.0, 'dirt': 0.25, 'seed': 109},
        'belt': {'type': 'cloth', 'color': (20, 22, 26), 'weave': 0.2, 'weave_freq': 6.0, 'dirt': 0.1, 'seed': 110},
        'metal': {'type': 'metal', 'color': (150, 155, 165), 'scratches': 0.3, 'shine': 0.5, 'seed': 111},
        'rubber': {'type': 'rubber', 'color': (25, 25, 27)},
        'patch': {'type': 'cloth', 'color': (20, 24, 36), 'weave': 0.0, 'dirt': 0.0, 'seed': 112},
    }


def operator_decals(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    from .body import face_anchor
    fa = face_anchor(rig, sh)
    zc = J('Bip01 Spine2')[2] + 1.0 * k
    return [
        # Vexmira emblem on the chest plate (glowing cyan) and on the shoulder patch
        dict(kind='shape', shape='vex', center=(J('Bip01 Spine2')[0] + 7.0 * k, 0, zc + 0.3 * k), u=(0, -1, 0), v=(0, 0, 1),
             size=3.0 * k, soft=0.25, color=CYAN, mode='glow', depth=3.0, target=['plate', 'plate_front']),
        dict(kind='shape', shape='vex', center=J('Bip01 L UpperArm') + np.array([0.0, 2.5 * k, -3.4 * k]),
             u=(1, 0, 0), v=(0, 0, 1), size=0.95 * k, soft=0.2, color=CYAN, mode='glow', depth=2.0, target=['patch']),
        dict(kind='shape', shape='diamond', center=J('Bip01 L UpperArm') + np.array([0.0, 2.5 * k, -3.4 * k]),
             u=(1, 0, 0), v=(0, 0, 1), size=1.15 * k, soft=0.3, color=PURPLE, mode='paint', alpha=0.35, depth=2.0,
             target=['patch']),
        # back: VEXMIRA band on the vest
        dict(kind='band', normal=(0, 0, 1), offset=J('Bip01 Spine2')[2] + 2.0 * k, width=1.2 * k, soft=0.2, color=CYAN,
             mode='glow', region=((-30, -5.0 * k, -50), (J('Bip01 Spine2')[0] - 3.0 * k, 5.0 * k, 50)), target=['vest']),
    ]


def operator_accessories(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    return [
        ('helmet', dict(mat='helmet', size=1.0)),
        ('goggles', dict(mat='goggle_frame', lens='lens', on_helmet=True)),
        ('vest', dict(mat='vest', pouch_mat='pouch', plate_mat='plate')),
        ('belt', dict(mat='belt', buckle_mat='metal', pouches=2, pouch_mat='pouch')),
        ('knee_pads', dict(mat='plate')),
        ('emblem_patch', dict(mat='patch', where='arm_L')),
        ('plates_on', dict(mat='pouch', items=[
            ('Bip01 L Thigh', tuple((J('Bip01 L Thigh') + np.array([0.6, 3.2, -7.0]) * k) / k), (2.0, 1.2, 3.0), (0, 0, 0)),
            ('Bip01 R Thigh', tuple((J('Bip01 R Thigh') + np.array([0.6, -3.2, -7.0]) * k) / k), (2.0, 1.2, 3.0), (0, 0, 0))])),
    ]


def operator_spec(quick=False):
    return dict(
        name='vex_operator', style='human', rig=RigSpec.preset('human'),
        shape=dict(hands='glove', feet='boot', muscle=0.45, chest=1.04, head=dict(jaw=1.4, chin=1.0, brow=1.15, w=1.05)),
        mats=dict(torso='body', arm='body', leg='legs', foot='boot', hand='hand', neck='skin', head='head'),
        materials=operator_materials,
        decals=operator_decals,
        face=dict(eye='human', eye_color=(70, 100, 120), brow_color=(55, 40, 30), mouth='closed', hair=(48, 36, 28),
                  stubble=0.35, brow_shadow=0.45),
        accessories=operator_accessories,
        tex=dict(w=512, h=512, pages=1) if not quick else dict(w=256, h=256, pages=1),
        budget=1.0e6,
    )


SPECS = {'walker': walker_spec, 'operator': operator_spec}


def main(argv):
    from .api import build_player_model, preview_textures
    quick = '--quick' in argv
    lookdev = '--lookdev' in argv
    names = [a for a in argv if not a.startswith('--')]
    if not names or names == ['all']:
        names = ['walker', 'operator', 'claws', 'pak47']
    for n in names:
        if n in SPECS:
            spec = SPECS[n](quick)
            if lookdev:
                print(preview_textures(spec, quick=quick))
            else:
                build_player_model(spec, quick=quick)
        elif n == 'claws':
            from .vmodel import build_claws_sample
            build_claws_sample(quick=quick)
        elif n == 'pak47':
            from .pmodel import build_pak47_sample
            build_pak47_sample()


if __name__ == '__main__':
    main(sys.argv[1:])
