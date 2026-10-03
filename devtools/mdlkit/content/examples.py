"""Reference / proof specs for every builder (outputs go to $SP/mdlwork/out/examples, never to cstrike/).

    cd devtools
    python3 -m mdlkit build mdlkit.content.examples:boss_brute        # heavy 'boss' style + hull_fit + claws
    python3 -m mdlkit build mdlkit.content.examples:floaty_wraith     # 'floaty' hovering boss + claws
    python3 -m mdlkit build mdlkit.content.examples:chimera           # zombie extras: tail, wings, extra limbs,
                                                                      # horns, crystals (+ claws)
    python3 -m mdlkit build mdlkit.content.examples:world_all         # lasermine, supply crate (parachute
                                                                      # bodygroup), hive egg, spore pod, hook, w_ nade
    python3 -m mdlkit build mdlkit.content.examples:v_special         # v_ special weapon on the AK47 enum
    python3 -m mdlkit build mdlkit.content.examples:p_special         # p_ of the same gun

Copy a function into your own content module, rename (vex_b_brute ...), drop the 'out' override (the
default output paths are the real cstrike/ paths) and iterate on the look.
"""
import math
import os
import numpy as np

from . import *          # noqa: F401,F403  (the content API)
from . import SP

EX_OUT = os.path.join(SP, 'mdlwork/out/examples')
AREA = 'mdlkit_examples'


def _out(name):
    return os.path.join(EX_OUT, name + '.mdl')


# ============================================================================================ boss: heavy
def _brute_materials(rig, sh):
    k = rig.H / 72.0
    J = rig.J
    hide = skin((104, 98, 80), seed=301, variation=0.2, tint2=(78, 84, 64), tint2_amount=0.6, veins=0.45,
                vein_color=(170, 70, 10), scars=0.7, pores=0.25, wounds=0.2)
    rock = {'type': 'lava', 'color': (58, 52, 50), 'hot': (255, 120, 0), 'core': (255, 210, 120), 'freq': 0.42,
            'crack_width': 0.07, 'seed': 302}
    fur = {'type': 'fur', 'color': (70, 52, 40), 'seed': 303}
    return {
        'skin': hide, 'head': dict(hide, seed=304),
        'body': layers(hide,
                       (fur, {'meshes': ['torso'], 'z': (J('Bip01 Spine2')[2], 999), 'x': (-99, -1.5 * k), 'ragged': 1.4,
                              'seed': 6}),
                       (cloth((60, 44, 34), seed=305, dirt=0.8, stains=0.6, blood=0.3),
                        {'meshes': ['torso'], 'z': (-99, J('Bip01 Pelvis')[2] + 1.5 * k), 'ragged': 1.2, 'seed': 7},
                        (30, 22, 18))),
        'legs': layers(hide, (cloth((60, 44, 34), seed=306, dirt=0.9), {'meshes': ['leg'], 't': (-1, 0.9), 'ragged': 1.0,
                                                                        'seed': 8}, (30, 22, 18))),
        'hand': rock, 'boot': dict(hide, seed=307), 'claw': {'type': 'bone', 'color': (60, 54, 48), 'seed': 308},
        'rock': rock, 'horn': {'type': 'horn', 'color': (70, 60, 52), 'tip_color': (255, 140, 30), 'tip_dark': 0.6,
                               'seed': 309},
        'chain': metal((96, 92, 88), seed=310, rust=0.6, chipping=0.2),
        'wrap': cloth((120, 100, 70), seed=311, dirt=1.0, stains=0.8, blood=0.4),
        'eyeglow': glow((255, 140, 0)),
    }


def _brute_accessories(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    chain_pts = [J('Bip01 L Clavicle') + np.array([2.5, 3.5, 2.0]) * k, J('Bip01 Spine2') + np.array([6.5, 0, 0]) * k,
                 J('Bip01 Spine') + np.array([5.5, -4.5, 0]) * k, J('Bip01 Pelvis') + np.array([1.0, -7.0, 0]) * k]
    chain_b = [rig.index['Bip01 Spine3'], rig.index['Bip01 Spine2'], rig.index['Bip01 Spine']]
    return [
        ('shoulder_pads', dict(mat='rock', size=1.35, spikes=3, spike_mat='horn')),
        ('horns', dict(mat='horn', length=5.0, radius=1.4, curve=(1.5, 1.0, -1.5), forward=0.6)),
        ('bracers', dict(mat='rock', grow=0.9)),
        ('wraps', dict(mat='wrap', where=(('L', 'Calf', 0.2, 0.7), ('R', 'Calf', 0.25, 0.75)), grow=0.3)),
        ('chain', dict(mat='chain', points=chain_pts, bones=chain_b, link=1.3)),
        ('spikes', dict(mat='rock', n=4, length=4.0, radius=1.4, seed=3)),
        ('glow_eyes', dict(mat='eyeglow', size=0.6)),
        ('jaw_teeth', dict(mat='claw', n=4, size=1.4)),
    ]


def boss_brute(quick=False):
    """Heavy boss (Brute look): 110-unit rig, 'boss' style (heavy gait, shallow crouch), hull_fit hitboxes,
    claws built from the same spec. ~0.6 MB."""
    rs = RigSpec.preset('boss')
    rs.hand_pose = 'claw'
    rs.hand = 0.15
    return dict(
        name='ex_b_brute', style='boss', rig=rs, hull_fit=True,
        style_params=dict(hunch=18.0, heavy=1.0, lurch=0.45),
        shape=dict(hands='claw', feet='bare', muscle=1.0, hump=0.55, chest=1.18, waist=0.95, belly=0.25, claw_len=0.7,
                   head=dict(snout=0.25, jaw=1.6, brow=1.7, w=1.1, ears=0.6, sockets=1.3, mouth_open=0.4)),
        mats=dict(torso='body', arm='body', leg='legs', foot='boot', hand='hand', neck='skin', head='head', claw='claw'),
        materials=_brute_materials, accessories=_brute_accessories,
        face=dict(eye='glow', glow=(255, 140, 0), mouth='snarl', teeth=(210, 190, 140), brow_color=None, eye_size=0.8),
        tex=dict(w=512, h=512, pages=1) if not quick else dict(w=256, h=256, pages=1),
        budget=BUDGET['boss'], out=_out('ex_b_brute'), preview_area=AREA,
        claws=dict(out=_out('v_ex_brute')),
    )


# ============================================================================================ boss: floaty
def _wraith_materials(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    pale = skin((176, 186, 205), seed=401, variation=0.1, veins=0.6, vein_color=(90, 110, 170), rot=0.1)
    tulle = cloth((150, 165, 200), seed=402, weave=0.25, weave_freq=5.0, dirt=0.3, dirt_color=(70, 70, 90), tears=0.3)
    return {
        'skin': pale, 'head': dict(pale, seed=403),
        'body': layers(pale, (tulle, {'meshes': ['torso'], 'z': (-99, J('Bip01 Spine3')[2] + 1.0 * k), 'ragged': 1.5,
                                      'holes': 0.3, 'seed': 4}, (60, 70, 110)),
                       (tulle, {'meshes': ['arm'], 't': (0.5, 1.9), 'ragged': 1.5, 'holes': 0.35, 'seed': 5}, (60, 70, 110))),
        'legs': layers(dict(pale, color=(120, 130, 160)), (tulle, {'meshes': ['leg'], 't': (-1, 1.6), 'ragged': 1.2,
                                                                     'holes': 0.3, 'seed': 6})),
        'hand': dict(pale, seed=404), 'boot': dict(pale, seed=405, color=(110, 120, 150)),
        'claw': {'type': 'bone', 'color': (40, 40, 60), 'tip_color': (190, 210, 255), 'tip_dark': 0.8, 'seed': 406},
        'cape': dict(tulle, seed=407, color=(120, 135, 180)),
        'coat': dict(tulle, seed=408, color=(130, 145, 190)),
        'hair': {'type': 'hair', 'color': (210, 220, 240), 'tip': (120, 140, 200), 'seed': 409},
        'crown': {'type': 'crystal', 'color': (150, 190, 255), 'seed': 410},
        'eyeglow': glow((190, 220, 255), (255, 255, 255)),
    }


def floaty_wraith(quick=False):
    """'floaty' boss (Banshee look): hovers above the floor (dangling legs, glide locomotion, hover bob,
    deaths drop to the floor), tattered cloth, crystal crown, long claws; hull_fit; claws."""
    rs = RigSpec(height=100.0, shoulder_w=0.22, hip_w=0.11, leg=0.5, arm=0.41, hand=0.135, head=0.13, bulk=0.85,
                 limb_thick=0.8, hand_pose='claw')
    return dict(
        name='ex_b_wraith', style='floaty', rig=rs, hull_fit=True,
        style_params=dict(hunch=12.0, float_h=7.0, lurch=0.2),
        shape=dict(hands='claw', feet='bare', gaunt=0.6, muscle=0.1, chest=0.9, waist=0.8, claw_len=1.8,
                   head=dict(jaw=0.8, chin=1.2, sockets=1.6, cheek=0.8, nose=0.5, mouth_open=0.6, jaw_drop=0.3)),
        mats=dict(torso='body', arm='body', leg='legs', foot='boot', hand='hand', neck='skin', head='head', claw='claw'),
        materials=_wraith_materials,
        accessories=[('hair', dict(mat='hair', volume=1.3, length=1.0, style='long')),
                     ('cape', dict(mat='cape', length=0.95, width=15.0, tatter=0.6)),
                     ('coat_skirt', dict(mat='coat', length=0.9, flare=0.7)),
                     ('crystals', dict(mat='crown', where=(('Bip01 Head', (-0.5, 0.0, 6.0)),), size=0.8, seed=8)),
                     ('glow_eyes', dict(mat='eyeglow', size=0.6))],
        face=dict(eye='glow', glow=(200, 225, 255), mouth='open', teeth=(200, 205, 220), brow_color=None),
        tex=dict(w=512, h=512, pages=1) if not quick else dict(w=256, h=256, pages=1),
        budget=BUDGET['boss'], out=_out('ex_b_wraith'), preview_area=AREA,
        claws=dict(out=_out('v_ex_wraith')),
    )


# ============================================================================================ zombie extras
def _chimera_materials(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    hide = skin((112, 96, 120), seed=501, tint2=(80, 60, 100), tint2_amount=0.6, veins=0.8, vein_color=(170, 40, 200),
                rot=0.4, rot_color=(70, 50, 80), wounds=0.4, blood=0.3)
    chitin = {'type': 'scales', 'color': (46, 30, 60), 'seed': 502}
    return {
        'skin': hide, 'head': dict(hide, seed=503), 'hand': dict(hide, seed=504), 'boot': dict(hide, seed=505),
        'body': layers(hide, (chitin, {'meshes': ['torso'], 'x': (-99, -1.0 * k), 'z': (J('Bip01 Spine')[2], 999),
                                       'ragged': 1.5, 'seed': 6})),
        'legs': layers(hide, (cloth((50, 46, 60), seed=506, dirt=0.9, tears=0.4), {'meshes': ['leg'], 't': (-1, 1.0),
                                                                                    'ragged': 1.4, 'holes': 0.4, 'seed': 7},
                              (30, 20, 30))),
        'claw': {'type': 'bone', 'color': (210, 190, 220), 'tip_color': (60, 10, 70), 'seed': 507},
        'chitin': chitin, 'tail': dict(chitin, seed=508),
        'wing': layers({'type': 'skin', 'color': (90, 50, 110), 'variation': 0.25, 'veins': 1.0,
                        'vein_color': (200, 80, 255), 'seed': 509},
                       ({'type': 'skin', 'color': (60, 30, 70), 'seed': 510}, {'holes': 0.4, 'hole_freq': 0.2,
                                                                                'hole_size': 0.3, 'seed': 11})),
        'bone': {'type': 'bone', 'color': (200, 185, 205), 'seed': 511},
        'horn': {'type': 'horn', 'color': (60, 40, 70), 'tip_color': (220, 120, 255), 'tip_dark': 0.7, 'seed': 512},
        'crystal': {'type': 'crystal', 'color': (190, 80, 255), 'seed': 513},
        'eyeglow': glow((220, 120, 255)),
    }


def chimera(quick=False):
    """Zombie with every creature extra: tail (lower extra, gait-driven), wings + 4 back limbs (upper
    extras, animated automatically), horns, crystals. Shows the bone/size cost of extras."""
    rs = RigSpec.preset('zombie')
    rs.hand_pose = 'claw'
    rs.extras = (tail_extras(rs.height, n=4, length=26.0) + wing_extras(rs, span=0.9) +
                 limb_extras(rs, pairs=2, reach=0.85))
    return dict(
        name='ex_z_chimera', style='zombie', rig=rs,
        style_params=dict(hunch=22.0, lurch=0.5),
        shape=dict(hands='claw', feet='bare', gaunt=0.3, hump=0.3, muscle=0.3, claw_len=1.2,
                   head=dict(snout=0.4, jaw_drop=0.3, sockets=1.4, brow=1.4, ears=0.5)),
        mats=dict(torso='body', arm='body', leg='legs', foot='boot', hand='hand', neck='skin', head='head', claw='claw'),
        materials=_chimera_materials,
        accessories=[('tail', dict(mat='tail', length=26.0, radius=2.0)),
                     ('wings', dict(mat='wing', bone_mat='bone', fingers=3)),
                     ('extra_limbs', dict(mat='chitin', claw_mat='claw', radius=0.9)),
                     ('horns', dict(mat='horn', length=4.5, radius=1.0, pairs=2)),
                     ('crystals', dict(mat='crystal', where=(('Bip01 L UpperArm', (0, 1.5, 0.8)),
                                                             ('Bip01 R Thigh', (1.5, -1.5, -4.0))), size=0.8)),
                     ('glow_eyes', dict(mat='eyeglow', size=0.5))],
        face=dict(eye='glow', glow=(220, 120, 255), mouth='snarl', teeth=(220, 200, 210), brow_color=None),
        tex=dict(w=512, h=256, pages=1) if not quick else dict(w=256, h=256, pages=1),
        budget=BUDGET['zombie'], out=_out('ex_z_chimera'), preview_area=AREA,
        claws=dict(out=_out('v_ex_chimera')),
    )


# ============================================================================================ world props
WORLD_MATS = {
    'steel': metal((70, 76, 86), seed=601, panels=1, chipping=0.3),
    'dark': metal((36, 38, 44), seed=602),
    'lens': {'type': 'visor', 'color': (0, 170, 230), 'color2': (200, 255, 255)},
    'cyan': glow(VEX_CYAN),
    'purple': glow(VEX_PURPLE),
    'wood': {'type': 'leather', 'color': (120, 86, 52), 'seed': 603},
    'olive': metal((84, 92, 60), seed=604, chipping=0.35, edge_wear=0.7, scratches=0.3),
    'canvas': cloth((210, 200, 180), seed=605, weave=0.2, dirt=0.3, stripes=[]),
    'canvas2': cloth((200, 60, 40), seed=606, weave=0.2, dirt=0.3),
    'rope': cloth((150, 130, 90), seed=607, weave=0.4),
    'egg': {'type': 'skin', 'color': (120, 150, 70), 'variation': 0.25, 'veins': 1.0, 'vein_color': (200, 255, 80),
            'rot': 0.3, 'seed': 608},
    'eggglow': glow((110, 255, 0)),
    'spore': {'type': 'skin', 'color': (110, 120, 60), 'variation': 0.3, 'veins': 0.8, 'vein_color': (190, 230, 60),
              'seed': 609},
    'chitin': {'type': 'scales', 'color': (70, 60, 40), 'seed': 610},
    'hookmetal': metal((128, 126, 122), seed=611, rust=0.3, chipping=0.2),
    'blood': {'type': 'skin', 'color': (110, 20, 18), 'variation': 0.3, 'seed': 612},
    'nade': metal((150, 40, 20), seed=613),
    'nadeband': metal((40, 40, 44), seed=614),
}


def lasermine():
    """Wall-mounted laser mine: base plate on the wall (model +X = the direction the beam fires),
    armed housing that slides out and unfolds its lens. Sequences: idle (armed, pulsing lens ring),
    deploy (unfold). Attachment 0 = lens (beam origin)."""
    parts = [bx((1.2, 9.0, 9.0), (0.6, 0, 0), 'dark', 'plate', 0.4)]
    for sg in (1, -1):
        for sz in (1, -1):
            parts.append(rod((0.9, sg * 3.6, sz * 3.6), (1.6, sg * 3.6, sz * 3.6), 0.45, mat='steel', name='bolt'))
    head = on('head', bx((4.0, 6.0, 6.0), (3.0, 0, 0), 'steel', 'housing', 0.6),
              rod((5.0, 0, 0), (6.6, 0, 0), 1.8, mat='dark', name='barrel', segs=12),
              rod((6.5, 0, 0), (6.8, 0, 0), 1.35, mat='lens', name='lens', segs=12),
              bx((3.6, 0.3, 4.6), (3.1, 3.1, 0), 'cyan', 'stripe', 0.0), bx((3.6, 0.3, 4.6), (3.1, -3.1, 0), 'cyan', 'stripe', 0.0))
    ring = on('ring', rod((6.0, 0, 0), (6.4, 0, 0), 2.2, mat='cyan', name='ring', segs=12))
    return dict(kind='world', name='ex_lasermine', parts=parts + head + ring,
                bones=[Bone('root'), Bone('head', 'root', (1.2, 0, 0)), Bone('ring', 'head', (6.2, 0, 0))],
                sequences=[dict(name='idle', frames=16, fps=10, loop=True,
                                pose=lambda t: {'ring': dict(rot=(0, 0, 360 * t / 4.0))}),
                           dict(name='deploy', frames=20, fps=20,
                                pose=lambda t: {'head': dict(pos=(-3.0 * (1 - t), 0, 0), rot=(0, 0, -90 * (1 - t))),
                                                'ring': dict(pos=(-1.5 * (1 - t), 0, 0))})],
                attachments=[('head', (6.8, 0, 0))], materials=WORLD_MATS, tex=(128, 128),
                out=_out('ex_lasermine'), preview_area=AREA, budget=0.1e6)


def supply_crate():
    """Supply crate with a parachute bodygroup (body 0 = crate only, 1 = with parachute) and a falling
    sway sequence; base at z = 0."""
    parts = [bx((24, 24, 20), (0, 0, 10), 'olive', 'crate', 0.8)]
    for z in (2.0, 18.0):          # wooden skid / top slats around the box
        for sg in (1, -1):
            parts.append(bx((25.0, 1.2, 2.6), (0, sg * 12.3, z), 'wood', 'slat', 0.2))
            parts.append(bx((1.2, 25.0, 2.6), (sg * 12.3, 0, z), 'wood', 'slat', 0.2))
    parts.append(bx((10, 0.4, 3.0), (0, 12.2, 13), 'cyan', 'label', 0.0))
    parts.append(bx((10, 0.4, 3.0), (0, -12.2, 13), 'cyan', 'label', 0.0))
    canopy = []
    from ..geom import dome as _dome
    c = _dome((30, 30, 14), (0, 0, 0), segs=16, rings=5, mat='canvas', bone=0)
    c.make_two_sided()
    c.translate((0, 0, 56))
    c.name = 'canopy'
    canopy.append(c)
    stripe = _dome((30.4, 30.4, 14.2), (0, 0, 0), rim=lambda ph: 0.55 if (int(ph / (math.pi / 4)) % 2) else 1.5,
                   segs=16, rings=3, mat='canvas2', bone=0)
    stripe.translate((0, 0, 56))
    canopy.append(stripe)
    for a in range(8):
        ang = a * math.pi / 4
        canopy.append(rod((math.cos(ang) * 29, math.sin(ang) * 29, 56), (math.cos(ang) * 10, math.sin(ang) * 10, 20),
                          0.18, mat='rope', name='rope', segs=4))
    return dict(kind='world', name='ex_supply_crate', parts=parts,
                bones=[Bone('root'), Bone('chute', 'root', (0, 0, 20))],
                bodygroups=[('parachute', [None, on('chute', canopy)])],
                sequences=[dict(name='idle', frames=1),
                           dict(name='fall', frames=31, fps=15, loop=True,
                                pose=lambda t: {'root': dict(rot=(0, 6 * math.sin(2 * math.pi * t), 9 * math.sin(2 * math.pi * t + 1))),
                                                'chute': dict(rot=(10 * t, -4 * math.sin(2 * math.pi * t), -6 * math.sin(2 * math.pi * t + 1)))})],
                materials=WORLD_MATS, tex=(256, 256), out=_out('ex_supply_crate'), preview_area=AREA)


def hive_egg():
    """Hive egg: leathery egg with glowing veins; 'idle' pulse (the shell halves breathe) and 'hatch'
    (the four petals open). Bodygroup-free; petals are separate bones."""
    from ..geom import ellipsoid as _ell
    core = _ell((7, 7, 10), (0, 0, 10), segs=12, rings=8, mat='egg')
    glowc = _ell((5.5, 5.5, 8.5), (0, 0, 11), segs=10, rings=6, mat='eggglow')
    parts = [core, glowc, on('root', bx((16, 16, 1.5), (0, 0, 0.75), 'chitin', 'base', 0.6))]
    bones = [Bone('root')]
    for i in range(4):
        a = i * math.pi / 2 + math.pi / 4
        nm = 'petal%d' % i
        bones.append(Bone(nm, 'root', (math.cos(a) * 5, math.sin(a) * 5, 3)))
        pts = [(math.cos(a) * 5.5, math.sin(a) * 5.5, 3), (math.cos(a) * 8.2, math.sin(a) * 8.2, 9),
               (math.cos(a) * 6.5, math.sin(a) * 6.5, 16), (math.cos(a) * 2.0, math.sin(a) * 2.0, 20.5)]
        pet = tube(pts, [3.2, 4.0, 3.0, 0.6], segs=6, mat='chitin', bones=0)
        parts += on(nm, pet)
    pulse = lambda t: {('petal%d' % i): dict(rot=(0, 0, 0), pos=(math.cos(i * math.pi / 2 + math.pi / 4) * 0.5 * math.sin(2 * math.pi * t),
                                                                  math.sin(i * math.pi / 2 + math.pi / 4) * 0.5 * math.sin(2 * math.pi * t), 0))
                       for i in range(4)}

    def hatch2(t):
        # yaw to the petal direction, pitch outward, yaw back: expressed in the parent frame
        from ..anims import ypr as _ypr
        out = {}
        for i in range(4):
            a = i * 90 + 45
            R = _ypr(a, 0, 0) @ _ypr(0, 75 * t, 0) @ _ypr(-a, 0, 0)
            out['petal%d' % i] = dict(R=R)
        return out
    return dict(kind='world', name='ex_hive_egg', parts=parts, bones=bones,
                sequences=[dict(name='idle', frames=21, fps=12, loop=True, pose=pulse),
                           dict(name='hatch', frames=16, fps=15, pose=hatch2)],
                materials=WORLD_MATS, tex=(256, 256), out=_out('ex_hive_egg'), preview_area=AREA)


def spore_pod():
    """Sporemother trap: fleshy pod on roots with spore sacs; idle = slow breathing (sacs swell)."""
    from ..geom import ellipsoid as _ell
    parts = [_ell((6, 6, 5), (0, 0, 4.5), segs=12, rings=7, mat='spore')]
    for i in range(5):
        a = i * 2 * math.pi / 5
        parts.append(tube([(math.cos(a) * 4, math.sin(a) * 4, 2), (math.cos(a) * 8, math.sin(a) * 8, 0.6),
                           (math.cos(a) * 11, math.sin(a) * 11, 0.3)], [1.2, 0.8, 0.3], segs=5, mat='chitin'))
    bones = [Bone('root')]
    for i in range(3):
        a = i * 2 * math.pi / 3 + 0.4
        nm = 'sac%d' % i
        c = (math.cos(a) * 3.4, math.sin(a) * 3.4, 7.5)
        bones.append(Bone(nm, 'root', c))
        parts += on(nm, _ell((2.2, 2.2, 2.6), c, segs=8, rings=5, mat='eggglow'))
    return dict(kind='world', name='ex_spore_pod', parts=parts, bones=bones,
                sequences=[dict(name='idle', frames=25, fps=10, loop=True,
                                pose=lambda t: {('sac%d' % i): dict(pos=(0, 0, 0.8 * math.sin(2 * math.pi * t + i * 2.1)))
                                                for i in range(3)})],
                materials=WORLD_MATS, tex=(128, 128), out=_out('ex_spore_pod'), preview_area=AREA, budget=0.1e6)


def hook():
    """Butcher's meat hook head (the chain is a beam sprite): +X = flight direction, ring at the back."""
    pts = [(0, 0, 0), (5, 0, 0), (8.5, 0, -0.5), (10, 0, -3), (9, 0, -5.5), (6.5, 0, -6.2), (4.6, 0, -4.8)]
    parts = [tube(pts, [0.7, 0.7, 0.65, 0.6, 0.5, 0.4, 0.05], segs=7, mat='hookmetal', cap_end=False),
             tube([(-1.2, 0, 0), (0.6, 0, 0)], 1.1, segs=8, mat='dark'),
             horn((4.6, 0, -4.8), (-0.4, 0, 1.0), 2.0, 0.45, mat='hookmetal'),
             _ring_mesh()]
    blood = tube(pts[3:6], [0.68, 0.58, 0.48], segs=7, mat='blood', cap_start=False, cap_end=False)
    parts.append(blood)
    return dict(kind='world', name='ex_hook', parts=parts,
                sequences=[dict(name='idle', frames=1), dict(name='spin', frames=12, fps=24, loop=True,
                                                             pose=lambda t: {'root': dict(rot=(0, 0, 360 * t))})],
                materials=WORLD_MATS, tex=(128, 128), out=_out('ex_hook'), preview_area=AREA, budget=0.06e6)


def _ring_mesh():
    pts = [(-2.6 + 1.2 * math.cos(a), 0, 1.2 * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 9)]
    m = tube(pts, 0.35, segs=5, mat='hookmetal', cap_start=False, cap_end=False)
    m.name = 'ring'
    return m


def w_grenade():
    """Thrown grenade (w_ model): body + fuze + spoon, sitting on the floor (z = 0)."""
    from ..geom import ellipsoid as _ell
    parts = [_ell((1.4, 1.4, 1.8), (0, 0, 1.9), segs=10, rings=7, mat='nade'),
             rod((0, 0, 0.5), (0, 0, 0.9), 0.9, mat='nadeband', name='base', segs=10),
             rod((0, 0, 3.4), (0, 0, 4.1), 0.5, mat='steel', name='fuze', segs=8),
             bx((0.4, 0.5, 2.8), (-0.9, 0, 3.0), 'steel', 'spoon', 0.06),
             rod((0, 0, 2.0), (0, 0, 2.4), 1.45, mat='purple', name='band', segs=10)]
    return dict(kind='world', name='ex_w_grenade', parts=parts, sequences=[dict(name='idle', frames=1)],
                materials=WORLD_MATS, tex=(64, 64), out=_out('ex_w_grenade'), preview_area=AREA, budget=0.03e6)


def world_all():
    return [lasermine(), supply_crate(), hive_egg(), spore_pod(), hook(), w_grenade()]


# ============================================================================================ weapons
def _scifi_rifle():
    m = gun_preset('scifi_rifle')
    return m


def v_special():
    """Special weapon v_ model on the AK47 base (sequence order = ak47_e, 5001/5004 events)."""
    return dict(kind='vhuman', name='v_ex_special', vkind='ak47', gun=_scifi_rifle(), out=_out('v_ex_special'),
                materials={'gun_glow': glow((255, 60, 200)), 'gun_metal': metal((60, 50, 80), seed=701)})


def p_special():
    return dict(kind='pmodel', name='p_ex_special', meshes=_scifi_rifle(), ext='ak47', out=_out('p_ex_special'),
                materials={'gun_glow': glow((255, 60, 200)), 'gun_metal': metal((60, 50, 80), seed=701)},
                preview_area=AREA)


def all_examples():
    return [boss_brute(), floaty_wraith(), chimera()] + world_all() + [v_special(), p_special()]
