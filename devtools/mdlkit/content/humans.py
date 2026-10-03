"""Vexmira human (CT) player models - DESIGN_v3.md section 3.

    cd devtools
    python3 -m mdlkit list  mdlkit.content.humans
    python3 -m mdlkit build mdlkit.content.humans:ranger --lookdev
    python3 -m mdlkit build mdlkit.content.humans:all --only vex_ranger

Seven CT models, one family: every model carries Vexmira cyan (0,220,255) glow trims and a purple
(160,90,255) accent / emblem, on top of its own theme:

  vex_operator  standard CT: dark navy tactical uniform, helmet, goggles, cyan stripes, Vexmira emblem
  vex_ranger    sand/khaki field soldier: beret + bandana, rolled sleeves, big backpack with bedroll
  vex_hazmat    yellow-black protective suit, hood, gas mask + face lens, twin oxygen tanks with hose
  vex_vip       gold-white armoured elite, purple cape strip, crested helmet with a golden visor
  vex_admin     black-red commander, long coat, officer cap, red glowing visor band
  vex_survivor  heavy juggernaut: bulky scratched armour, huge shoulder plates, dirty and wounded
  vex_sniper    camo cloak sniper: ragged camo cloak + hood, face mask, purple monocular

All human specs use style 'human' (all CS weapon sequences 9-blend), 512x512 skin, budget 1.0 MB.
Custom gear pieces are registered into accessories.ACCESSORIES under 'hum_*' names (module-local, no
library change).
"""
import math
import numpy as np

from . import *                                   # noqa: F401,F403
from .. import samples as _samples
from ..accessories import ACCESSORIES, _bi, _k, _spine_bone_for_z
from ..mathx import rot_x, rot_y, rot_z

CYAN = VEX_CYAN
PURPLE = VEX_PURPLE
AREA = 'humans'


def _cyan_glow():
    return {'type': 'glow', 'color': CYAN, 'color2': (200, 255, 255), 'freq': 0.8}


def _purple_glow():
    return {'type': 'glow', 'color': PURPLE, 'color2': (225, 200, 255), 'freq': 0.8}


def _base(name, rig, materials, accessories, decals, face, shape=None, quick=False):
    return dict(
        name=name, style='human', rig=rig,
        shape=shape or dict(hands='glove', feet='boot', muscle=0.45),
        mats=dict(torso='body', arm='body', leg='legs', foot='boot', hand='hand', neck='skin', head='head'),
        materials=materials, decals=decals, face=face, accessories=accessories,
        tex=dict(w=512, h=512, pages=1) if not quick else dict(w=256, h=256, pages=1),
        budget=BUDGET['human'], preview_area=AREA,
    )


def _emblem(center, u, v, size, color=CYAN, mode='glow', target=None, depth=2.0, shape='vex', alpha=1.0, soft=0.22):
    d = dict(kind='shape', shape=shape, center=tuple(center), u=u, v=v, size=size, soft=soft, color=color, mode=mode,
             depth=depth, alpha=alpha)
    if target:
        d['target'] = target
    return d


# =============================================================================================== custom gear

def _beret(rig, sh, mat='beret', band='beret_band', badge='badge', tilt=0.32):
    fa = face_anchor(rig, sh)
    k = fa['k']; c = fa['center']; rx, ry, rz = fa['radii']
    hb = _bi(rig, 'Bip01 Head')
    top = ellipsoid((rx * 1.2, ry * 1.32, rz * 0.4), (0, 0, 0), segs=16, rings=7, mat=mat, bone=hb)
    top.transform(rot_x(tilt), c + np.array([-0.5 * k, -0.7 * k, rz * 0.66]))
    top.name = 'beret'
    zb = c[2] + rz * 0.42
    s = math.sqrt(max(0.05, 1 - 0.42 ** 2))
    ring = lathe([(-0.32 * k, 1.0), (0.32 * k, 1.0)], axis_start=(0, 0, 0), segs=16, mat=band, bone=hb,
                 cap_start=False, cap_end=False)
    ring.transform(None, (c[0] - 0.25 * k, c[1], zb), scale=(rx * s + 0.45 * k, ry * s + 0.5 * k, 1.0))
    ring.name = 'beret_band'
    bd = box((0.3 * k, 0.9 * k, 1.0 * k), center=(c[0] + rx * 0.92, c[1] + ry * 0.4, c[2] + rz * 0.6),
             bevel=0.1 * k, mat=badge, bone=hb)
    bd.name = 'badge'
    out = [top, ring, bd]
    for m in out:
        m.detail = 1.3
    return out


def _bandana(rig, sh, mat='bandana'):
    """Scarf knotted around the neck with a triangle hanging over the upper chest."""
    k = _k(rig)
    J = rig.J
    nb = _bi(rig, 'Bip01 Neck'); sb = _bi(rig, 'Bip01 Spine3')
    n = J('Bip01 Neck')
    ang = np.linspace(0, 2 * math.pi, 15)
    pts = [np.array([n[0] + 2.85 * k * math.cos(a) + 0.2 * k, 2.75 * k * math.sin(a), n[2] + 0.3 * k + 0.5 * k * math.cos(a)])
           for a in ang]
    ring = tube(pts, 0.85 * k, segs=6, mat=mat, bones=nb, cap_start=False, cap_end=False, radii_b=1.15 * k,
                ref=np.array([0, 0, 1.0]))
    ring.name = 'bandana'
    x0 = n[0] + 3.1 * k
    tri = ribbon([np.array([x0, 0, n[2] + 0.4 * k]), np.array([x0 + 0.9 * k, 0, n[2] - 1.8 * k]),
                  np.array([x0 + 1.4 * k, 0, n[2] - 3.6 * k]), np.array([x0 + 1.5 * k, 0, n[2] - 4.9 * k])],
                 [5.0 * k, 3.8 * k, 1.9 * k, 0.3 * k], normal_hint=(1, 0, 0), mat=mat, bones=[nb, sb, sb, sb],
                 two_sided=True, width_dir=(0, 1, 0))
    tri.name = 'bandana_tri'
    return [ring, tri]


def _bedroll(rig, sh, mat='bedroll', strap='strap', pack_size=(4.0, 9.5, 11.0)):
    k = _k(rig)
    J = rig.J
    zc = J('Bip01 Spine2')[2] + 1.0 * k
    b = _spine_bone_for_z(rig, zc)
    x = J('Bip01 Spine2')[0] - 4.6 * k - pack_size[0] * 0.5 * k
    zt = zc + pack_size[2] * 0.5 * k + 1.35 * k
    roll = cylinder((x - 0.3 * k, -6.2 * k, zt), (x - 0.3 * k, 6.2 * k, zt), 1.55 * k, segs=12, mat=mat, bone=b)
    roll.name = 'bedroll'
    out = [roll]
    for y in (-3.6, 3.6):
        s = cylinder((x - 0.3 * k, (y - 0.35) * k, zt), (x - 0.3 * k, (y + 0.35) * k, zt), 1.7 * k, segs=12, mat=strap,
                     bone=b)
        s.name = 'roll_strap'
        out.append(s)
    # shoulder straps over the front of the shoulders (bound to Spine3)
    sb = _bi(rig, 'Bip01 Spine3')
    for sg in (1, -1):
        cl = J('Bip01 %s Clavicle' % ('L' if sg > 0 else 'R'))
        pts = [np.array([x + 1.5 * k, sg * 3.6 * k, zc + 4.5 * k]), np.array([cl[0] - 1.2 * k, sg * 3.6 * k, cl[2] + 1.5 * k]),
               np.array([cl[0] + 2.4 * k, sg * 3.7 * k, cl[2] + 1.0 * k]), np.array([cl[0] + 4.7 * k, sg * 3.6 * k, cl[2] - 2.5 * k])]
        st = ribbon(pts, 1.4 * k, normal_hint=(0, 0, 1), mat=strap, bones=sb, two_sided=True, width_dir=(0, 1, 0))
        st.name = 'pack_strap'
        out.append(st)
    return out


def _faceplate(rig, sh, mat='lens', frame='mask'):
    """Big full-face lens (hazmat): curved visor over the eyes with a rubber rim."""
    fa = face_anchor(rig, sh)
    k = fa['k']; c = fa['center']; rx, ry, rz = fa['radii']
    hb = _bi(rig, 'Bip01 Head')
    e = (fa['eye_L'] + fa['eye_R']) / 2
    rim = ellipsoid((1.8 * k, ry * 1.1, 2.5 * k), (e[0] - 0.6 * k, 0, e[2] - 0.2 * k), segs=14, rings=7, mat=frame, bone=hb)
    rim.name = 'face_rim'
    lens = ellipsoid((1.55 * k, ry * 0.95, 1.7 * k), (e[0] - 0.25 * k, 0, e[2] + 0.25 * k), segs=14, rings=7, mat=mat, bone=hb)
    lens.name = 'face_lens'
    for m in (rim, lens):
        m.detail = 1.4
    return [rim, lens]


def _hose(rig, sh, mat='hose', tank_x=None):
    fa = face_anchor(rig, sh)
    k = fa['k']
    J = rig.J
    m0 = fa['mouth'] + np.array([0.6 * k, 0, 0.4 * k])
    zc = J('Bip01 Spine2')[2] + 1.0 * k
    tx = J('Bip01 Spine2')[0] - 4.6 * k - 0.75 * k - 1.5 * k if tank_x is None else tank_x
    hb = _bi(rig, 'Bip01 Head'); nb = _bi(rig, 'Bip01 Neck'); sb = _bi(rig, 'Bip01 Spine3')
    n = J('Bip01 Neck')
    ua = J('Bip01 R UpperArm')
    pts = [m0 + np.array([1.2 * k, -1.0 * k, -1.6 * k]),
           np.array([n[0] + 2.6 * k, -3.0 * k, n[2] + 0.6 * k]),
           np.array([n[0] + 0.4 * k, ua[1] * 0.55, ua[2] + 3.4 * k]),
           np.array([n[0] - 3.2 * k, ua[1] * 0.5, ua[2] + 3.0 * k]),
           np.array([tx + 0.6 * k, -1.7 * k, zc + 8.0 * k])]
    h = tube(pts, 0.5 * k, segs=7, mat=mat, bones=[hb, nb, sb, sb, sb], cap_start=True, cap_end=True)
    h.name = 'hose'
    return [h]


def _officer_cap(rig, sh, mat='cap', band='cap_band', peak='cap_peak', badge='badge'):
    fa = face_anchor(rig, sh)
    k = fa['k']; c = fa['center']; rx, ry, rz = fa['radii']
    hb = _bi(rig, 'Bip01 Head')
    z0 = c[2] + rz * 0.3
    # crown: unit-radius lathe scaled to the head ellipse, flaring out to the flat top
    prof = [(0.0, 0.98), (rz * 0.42, 1.02), (rz * 0.72, 1.18), (rz * 0.86, 1.22), (rz * 0.92, 0.9), (rz * 0.94, 0.02)]
    cr = lathe(prof, axis_start=(0, 0, 0), segs=18, mat=mat, bone=hb, cap_start=False, cap_end=False)
    s = math.sqrt(max(0.05, 1 - 0.3 ** 2))
    cr.transform(None, (c[0] - 0.35 * k, c[1], z0), scale=(rx * s + 0.45 * k, ry * s + 0.5 * k, 1.0))
    cr.name = 'cap'
    bd = lathe([(-0.05 * k, 1.0), (rz * 0.3, 1.04)], segs=18, mat=band, bone=hb, cap_start=False, cap_end=False)
    bd.transform(None, (c[0] - 0.35 * k, c[1], z0), scale=(rx * s + 0.6 * k, ry * s + 0.65 * k, 1.0))
    bd.name = 'cap_band'
    # peak (visor brim) - flattened half ellipsoid at the front
    pk = ellipsoid((2.6 * k, ry * 0.95, 0.28 * k), (0, 0, 0), segs=12, rings=4, mat=peak, bone=hb,
                   deform=lambda u, q: np.where(u[:, 0:1] < 0, q * np.array([0.15, 1, 1]), q))
    pk.transform(rot_y(0.32), (c[0] + rx * 0.8, c[1], z0 + 0.15 * k))
    pk.name = 'cap_peak'
    bg = box((0.35 * k, 1.6 * k, 1.6 * k), center=(c[0] + rx * s + 0.3 * k, c[1], z0 + rz * 0.62), bevel=0.1 * k,
             mat=badge, bone=hb)
    bg.transform(rot_y(-0.25) if False else None)
    bg.name = 'badge'
    out = [cr, bd, pk, bg]
    for m in out:
        m.detail = 1.3
    return out


def _visor_band(rig, sh, mat='redvisor', frame='visor_frame', width=1.5, spread=1.15):
    """Glowing visor band across the eyes (wraps to the temples)."""
    fa = face_anchor(rig, sh)
    k = fa['k']; c = fa['center']; rx, ry, rz = fa['radii']
    hb = _bi(rig, 'Bip01 Head')
    vz = fa['eye_L'][2] + 0.1 * k
    ang = np.linspace(-spread, spread, 11)
    pts = np.array([[c[0] + (rx + 0.75 * k) * math.cos(a), c[1] + (ry + 0.8 * k) * math.sin(a), vz] for a in ang])
    vis = ribbon(pts, width * k, normal_hint=(1, 0, 0), mat=mat, bones=hb, two_sided=True, width_dir=(0, 0, 1))
    vis.name = 'visor'
    ang2 = np.linspace(-spread - 0.15, spread + 0.15, 13)
    pts2 = np.array([[c[0] + (rx + 0.45 * k) * math.cos(a), c[1] + (ry + 0.5 * k) * math.sin(a), vz] for a in ang2])
    fr = tube(pts2, 0.25 * k, segs=4, mat=frame, bones=hb, radii_b=(width * 0.5 + 0.3) * k, cap_start=True,
              cap_end=True, ref=np.array([0, 0, 1.0]))
    fr.name = 'visor_frame'
    vis.detail = 1.4
    fr.detail = 1.4
    return [fr, vis]


def _face_mask(rig, sh, mat='mask'):
    """Cloth face wrap over nose / mouth / chin (sniper)."""
    fa = face_anchor(rig, sh)
    k = fa['k']; c = fa['center']; rx, ry, rz = fa['radii']
    hb = _bi(rig, 'Bip01 Head')
    zc = fa['mouth'][2] + 0.25 * k
    m = ellipsoid((rx * 1.0 + 0.4 * k, ry * 1.06 + 0.35 * k, 2.6 * k), (c[0] + 0.0 * k, c[1], zc), segs=14, rings=7,
                  mat=mat, bone=hb,
                  deform=lambda u, q: np.where((u[:, 0:1] < -0.2), q * np.array([0.92, 1, 1]), q))
    m.name = 'facemask'
    m.detail = 1.3
    return [m]


def _monocular(rig, sh, mat='scope_metal', lens='mono_lens', side='R'):
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    e = fa['eye_' + side]
    sg = 1 if side == 'L' else -1
    p0 = e + np.array([0.1 * k, 0, 0.1 * k]); p1 = e + np.array([2.3 * k, sg * 0.1 * k, 0.1 * k])
    tb = cylinder(p0, p1, 0.85 * k, 0.95 * k, segs=10, mat=mat, bone=hb)
    tb.name = 'monocular'
    ln = ellipsoid((0.15 * k, 0.8 * k, 0.8 * k), p1 + np.array([0.05 * k, 0, 0]), segs=10, rings=5, mat=lens, bone=hb)
    ln.name = 'mono_lens'
    # strap arm to the temple
    arm = box((2.6 * k, 0.3 * k, 0.5 * k), center=(e[0] - 0.9 * k, e[1] + sg * 1.6 * k, e[2] + 0.4 * k), mat=mat, bone=hb)
    for m in (tb, ln, arm):
        m.detail = 1.4
    return [tb, ln, arm]


def _gorget(rig, sh, mat='armor', grow=1.0):
    """Armoured collar ring around the neck base (juggernaut)."""
    k = _k(rig)
    J = rig.J
    n = J('Bip01 Neck')
    sb = _bi(rig, 'Bip01 Spine3')
    g = lathe([(-1.2 * k, 3.9 * k + grow * k), (0.4 * k, 3.6 * k + grow * k), (1.6 * k, 3.0 * k + grow * k)],
              axis_start=(n[0] - 0.4 * k, 0, n[2] - 0.6 * k), segs=14, mat=mat, bone=sb, cap_start=False, cap_end=False)
    g.make_two_sided()
    g.name = 'gorget'
    return [g]


def _shell_list(rig, sh, **kw):
    from ..accessories import shell
    m = shell(rig, sh, **kw)
    return m if isinstance(m, list) else [m]


ACCESSORIES.update({'hum_shell': _shell_list, 'hum_beret': _beret, 'hum_bandana': _bandana, 'hum_bedroll': _bedroll, 'hum_faceplate': _faceplate,
                    'hum_hose': _hose, 'hum_officer_cap': _officer_cap, 'hum_visor_band': _visor_band,
                    'hum_face_mask': _face_mask, 'hum_monocular': _monocular, 'hum_gorget': _gorget})


# =============================================================================================== operator

def operator(quick=False):
    """vex_operator - standard CT (navy tactical uniform, helmet, goggles, cyan stripes, Vexmira emblem)."""
    spec = _samples.operator_spec(quick)
    spec['preview_area'] = AREA
    return spec


# =============================================================================================== ranger

KHAKI = (176, 152, 106)
KHAKI_D = (138, 118, 82)


def _ranger_materials(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    shirt = cloth(KHAKI, seed=201, weave=0.1, weave_freq=3.8, dirt=0.55, dirt_z=10, dirt_color=(110, 92, 60),
                  stains=0.35, fold_freq=0.24)
    pants = cloth(KHAKI_D, seed=202, weave=0.12, weave_freq=4.0, dirt=0.7, dirt_z=-5, dirt_color=(96, 78, 50),
                  stains=0.4, fold_freq=0.25)
    skin_m = skin((182, 136, 100), seed=203, variation=0.08, pores=0.08, tint2=(170, 110, 90), tint2_amount=0.25)
    glove = {'type': 'leather', 'color': (112, 84, 54), 'seed': 204}
    cy = _cyan_glow()
    return {
        'skin': skin_m, 'head': skin_m,
        'hand': layers(glove, ({'type': 'leather', 'color': dict(skin_m)['color'], 'seed': 205}, {'meshes': ['fingers']})),
        'body': layers(shirt,
                       # rolled sleeves: bare forearms, rolled cuff band
                       (skin_m, {'meshes': ['arm'], 't': (1.22, 2.2)}),
                       (cloth((150, 128, 88), seed=206, weave=0.2, weave_freq=6.0), {'meshes': ['arm'], 't': (1.04, 1.22)}),
                       (cy, {'meshes': ['arm'], 't': (0.36, 0.42)}),
                       (pants, {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] + 0.5 * k), 'soft': 0.3})),
        'legs': layers(pants, ({'type': 'leather', 'color': (92, 70, 46), 'seed': 207}, {'meshes': ['leg'], 't': (1.7, 2.2)})),
        'boot': layers({'type': 'leather', 'color': (96, 72, 46), 'seed': 208},
                       ({'type': 'rubber', 'color': (40, 34, 28)}, {'z': (-60, -35.0), 'soft': 0.2})),
        'webbing': cloth((112, 102, 70), seed=209, weave=0.18, weave_freq=6.0, dirt=0.5, dirt_color=(90, 76, 50),
                         stripes=[dict(normal=(0, 0, 1), offset=J('Bip01 Spine')[2] + i * 2.4 * k, width=0.5 * k,
                                       color=(84, 76, 52)) for i in range(1, 7)]),
        'pouch': cloth((124, 112, 76), seed=210, weave=0.15, weave_freq=6.0, dirt=0.5),
        'pack': cloth((120, 106, 72), seed=211, weave=0.14, weave_freq=5.0, dirt=0.6, dirt_color=(88, 72, 46),
                      stains=0.4, fold_freq=0.3),
        'bedroll': cloth((84, 92, 62), seed=212, weave=0.2, weave_freq=5.0, dirt=0.5,
                         stripes=[dict(normal=(0, 1, 0), offset=y * k, width=0.4 * k, color=(60, 66, 44))
                                  for y in (-5, -2.5, 0, 2.5, 5)]),
        'strap': {'type': 'leather', 'color': (70, 54, 38), 'seed': 213},
        'belt': {'type': 'leather', 'color': (78, 58, 40), 'seed': 214},
        'beret': cloth((62, 44, 92), seed=215, weave=0.22, weave_freq=7.0, dirt=0.15, fold_freq=0.4),
        'beret_band': {'type': 'leather', 'color': (30, 26, 24), 'seed': 216},
        'badge': metal((200, 170, 90), seed=217, scratches=0.2, shine=0.6),
        'bandana': cloth((150, 40, 36), seed=218, weave=0.12, weave_freq=5.0, dirt=0.3, fold_freq=0.5,
                         camo=[(150, 40, 36), (120, 30, 30), (175, 70, 50)], camo_freq=0.5),
        'hair': {'type': 'hair', 'color': (58, 42, 30), 'tip': (84, 64, 44), 'seed': 219},
        'metal': metal((150, 150, 140), seed=220),
        'rubber': {'type': 'rubber', 'color': (32, 30, 28)},
        'patch': cloth((40, 34, 60), seed=221, weave=0.0, dirt=0.0),
        'plate': cloth((122, 108, 74), seed=222, weave=0.15, weave_freq=6.0, dirt=0.6),
    }


def _ranger_decals(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    from ..body import face_anchor as _fa
    fa = _fa(rig, sh)
    c = fa['center']; rx, ry, rz = fa['radii']
    return [
        _emblem((c[0] + rx * 0.9 + 0.2 * k, c[1] + ry * 0.38, c[2] + rz * 0.62), (0, -1, 0), (0, 0, 1), 0.7 * k,
                target=['badge'], depth=1.0),
        _emblem(J('Bip01 L UpperArm') + np.array([0.0, 2.5 * k, -3.4 * k]), (1, 0, 0), (0, 0, 1), 0.95 * k,
                target=['patch']),
        _emblem(J('Bip01 L UpperArm') + np.array([0.0, 2.5 * k, -3.4 * k]), (1, 0, 0), (0, 0, 1), 1.15 * k,
                color=PURPLE, mode='paint', alpha=0.4, shape='diamond', target=['patch'], soft=0.3),
        # cyan chevron on the backpack flap, purple stencil band
        _emblem((J('Bip01 Spine2')[0] - 9.0 * k, 0, J('Bip01 Spine2')[2] + 3.0 * k), (0, 1, 0), (0, 0, 1), 1.6 * k,
                shape='chevron', target=['pack'], depth=3.0),
        dict(kind='band', normal=(0, 0, 1), offset=J('Bip01 Spine2')[2] - 1.0 * k, width=0.6 * k, soft=0.2, color=CYAN,
             mode='glow', region=((-40, -6 * k, -50), (J('Bip01 Spine2')[0] - 7.0 * k, 6 * k, 50)), target=['pack']),
        # dust on the face / sweat stains
        dict(kind='sphere', center=fa['mouth'] + np.array([0, 0, -1.0 * k]), radius=2.2 * k, soft=0.8,
             color=(150, 120, 90), mode='multiply', alpha=0.25, target='head'),
    ]


def _ranger_accessories(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    return [
        ('hair', dict(mat='hair', volume=0.45)),
        ('hum_beret', dict(mat='beret', band='beret_band', badge='badge')),
        ('hum_bandana', dict(mat='bandana')),
        ('vest', dict(mat='webbing', pouch_mat='pouch', plates=False, collar=False, grow=0.55)),
        ('backpack', dict(mat='pack', size=(4.0, 9.5, 11.0))),
        ('hum_bedroll', dict(mat='bedroll', strap='strap')),
        ('belt', dict(mat='belt', buckle_mat='metal', pouches=3, pouch_mat='pouch', holster=False)),
        ('emblem_patch', dict(mat='patch', where='arm_L')),
        ('sleeve_cuffs', dict(mat='plate', part='Calf', at=0.8, grow=0.5)),
        ('plates_on', dict(mat='pouch', items=[
            ('Bip01 L Thigh', tuple((J('Bip01 L Thigh') + np.array([0.4, 3.5, -8.0]) * k) / k), (2.4, 1.3, 3.2), (0, 0, 0)),
            ('Bip01 R Thigh', tuple((J('Bip01 R Thigh') + np.array([0.4, -3.5, -8.0]) * k) / k), (2.4, 1.3, 3.2), (0, 0, 0))])),
    ]


def ranger(quick=False):
    """vex_ranger - sand/khaki field soldier, purple beret + bandana, backpack with bedroll."""
    rs = RigSpec(height=72.0, shoulder_w=0.205, limb_thick=1.0)
    return _base('vex_ranger', rs, _ranger_materials, _ranger_accessories, _ranger_decals,
                 face=dict(eye='human', eye_color=(62, 48, 34), brow_color=(55, 40, 28), mouth='closed',
                           hair=(58, 42, 30), stubble=0.6, brow_shadow=0.5),
                 shape=dict(hands='glove', feet='boot', muscle=0.5, chest=1.02,
                            head=dict(jaw=1.25, chin=1.1, brow=1.2, w=1.03, nose=1.1)),
                 quick=quick)


# =============================================================================================== hazmat

HAZ_Y = (226, 188, 34)


def _hazmat_materials(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    suit = cloth(HAZ_Y, seed=301, weave=0.04, weave_freq=3.0, dirt=0.45, dirt_z=-8, dirt_color=(110, 96, 44),
                 stains=0.35, fold_freq=0.32)
    blk = {'type': 'rubber', 'color': (28, 28, 30), 'seed': 302}
    cy = _cyan_glow()
    skin_m = skin((200, 160, 130), seed=303, variation=0.07)
    sz = J('Bip01 Spine1')[2]
    return {
        'skin': skin_m, 'head': skin_m,
        'hand': blk,
        'body': layers(suit,
                       (blk, {'meshes': ['arm'], 't': (1.72, 2.2)}),
                       (blk, {'meshes': ['arm'], 't': (0.5, 0.64)}),
                       (cy, {'meshes': ['arm'], 't': (0.555, 0.585)}),
                       (blk, {'meshes': ['torso'], 'z': (sz - 0.8 * k, sz + 0.8 * k)}),
                       (cy, {'meshes': ['torso'], 'z': (sz - 0.18 * k, sz + 0.18 * k)}),
                       (blk, {'meshes': ['torso'], 'y': (-0.45 * k, 0.45 * k), 'x': (0, 30),
                              'z': (J('Bip01 Pelvis')[2], J('Bip01 Neck')[2] + 2 * k)})),
        'legs': layers(suit,
                       (blk, {'meshes': ['leg'], 't': (1.55, 2.2)}),
                       (blk, {'meshes': ['leg'], 't': (0.55, 0.68)}),
                       (cy, {'meshes': ['leg'], 't': (0.6, 0.63)})),
        'boot': layers(blk, ({'type': 'rubber', 'color': (60, 58, 50)}, {'z': (-60, -35.0), 'soft': 0.2})),
        'hood': layers(suit, (blk, {'z': (J('Bip01 Head')[2] - 1.0 * k, J('Bip01 Head')[2] + 1.2 * k), 'x': (-30, 30)})),
        'mask': {'type': 'rubber', 'color': (34, 34, 38), 'seed': 304},
        'filter': layers(metal((90, 94, 100), seed=305, scratches=0.3),
                         (cy, {'x': (-60, 60), 'meshes': ['filter']})) if False else metal((84, 88, 96), seed=305, scratches=0.3),
        'lens': {'type': 'visor', 'color': (20, 150, 190), 'color2': (190, 250, 255)},
        'pack': {'type': 'rubber', 'color': (40, 40, 44), 'seed': 306},
        'tank': layers(metal((206, 210, 214), seed=307, scratches=0.35, shine=0.55, chipping=0.2),
                       (cy, {'z': (J('Bip01 Spine2')[2] + 4.0 * k, J('Bip01 Spine2')[2] + 4.5 * k)}),
                       (metal((60, 62, 70), seed=308), {'z': (J('Bip01 Spine2')[2] + 7.0 * k, 60)})),
        'hose': {'type': 'rubber', 'color': (30, 30, 34), 'seed': 309},
        'belt': {'type': 'rubber', 'color': (30, 30, 32), 'seed': 310},
        'metal': metal((160, 162, 168), seed=311),
        'pouch': cloth((60, 60, 58), seed=312, weave=0.15, weave_freq=6.0, dirt=0.3),
        'rubber': blk,
    }


def _hazmat_decals(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    z2 = J('Bip01 Spine2')[2] + 1.6 * k
    return [
        # Vexmira emblem on the chest (cyan) with a purple ring, biohazard-like ring on the back
        _emblem((J('Bip01 Spine2')[0] + 6.0 * k, 3.0 * k, z2), (0, -1, 0), (0, 0, 1), 1.5 * k, target=['body'], depth=3.0),
        _emblem((J('Bip01 Spine2')[0] + 6.0 * k, 3.0 * k, z2), (0, -1, 0), (0, 0, 1), 2.1 * k, color=PURPLE,
                shape='ring', target=['body'], depth=3.0, mode='paint'),
        _emblem((J('Bip01 Spine2')[0] - 6.0 * k, 0, J('Bip01 Spine1')[2] - 1.2 * k), (0, 1, 0), (0, 0, 1), 2.2 * k,
                color=(30, 30, 30), shape='ring', target=['body'], depth=3.0, mode='paint'),
        _emblem((J('Bip01 Spine2')[0] - 6.0 * k, 0, J('Bip01 Spine1')[2] - 1.2 * k), (0, 1, 0), (0, 0, 1), 1.3 * k,
                color=PURPLE, shape='vex', target=['body'], depth=3.0, mode='paint'),
        _emblem((J('Bip01 Spine2')[0] - 9.5 * k, 0, J('Bip01 Spine2')[2] + 1.0 * k), (0, 1, 0), (0, 0, 1), 1.2 * k,
                shape='diamond', target=['pack'], depth=2.0),
    ]


def _hazmat_accessories(rig, sh):
    return [
        ('hood', dict(mat='hood', depth=0.8, peak=0.6)),
        ('gasmask', dict(mat='mask', filt='filter')),
        ('hum_faceplate', dict(mat='lens', frame='mask')),
        ('backpack', dict(mat='pack', size=(1.6, 8.0, 9.0), tanks=2, tank_mat='tank')),
        ('hum_hose', dict(mat='hose')),
        ('belt', dict(mat='belt', buckle_mat='metal', pouches=2, pouch_mat='pouch')),
        ('sleeve_cuffs', dict(mat='belt', part='Forearm', at=0.78, grow=0.55)),
        ('sleeve_cuffs', dict(mat='belt', part='Calf', at=0.78, grow=0.6)),
    ]


def hazmat(quick=False):
    """vex_hazmat - yellow-black protective suit, hood, gas mask with face lens, oxygen tanks + hose."""
    rs = RigSpec(height=72.0, shoulder_w=0.205, bulk=1.12, limb_thick=1.1)
    return _base('vex_hazmat', rs, _hazmat_materials, _hazmat_accessories, _hazmat_decals,
                 face=dict(eye='human', eye_color=(60, 90, 110), brow_color=(70, 50, 35), mouth='closed', stubble=0.0),
                 shape=dict(hands='glove', feet='boot', muscle=0.2, chest=1.05, waist=1.08, belly=0.1,
                            head=dict(w=1.02)),
                 quick=quick)


# =============================================================================================== vip

GOLD_M = (222, 178, 64)
WHITE_A = (226, 226, 232)


def _vip_materials(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    gold = metal(GOLD_M, seed=401, scratches=0.25, shine=0.7, edge_wear=0.5, chipping=0.05)
    white = metal(WHITE_A, seed=402, paint=WHITE_A, scratches=0.2, shine=0.45, edge_wear=0.4, chipping=0.1, panels=0.5)
    under = cloth((46, 30, 74), seed=403, weave=0.1, weave_freq=5.0, dirt=0.1)
    suit = cloth((214, 214, 222), seed=404, weave=0.06, weave_freq=4.0, dirt=0.15, fold_freq=0.2)
    cy = _cyan_glow()
    skin_m = skin((206, 162, 130), seed=405, variation=0.06)
    return {
        'skin': skin_m, 'head': skin_m,
        'hand': layers({'type': 'leather', 'color': (224, 220, 212), 'seed': 406},
                       (gold, {'meshes': ['fingers', 'thumb']})),
        'body': layers(suit,
                       (under, {'meshes': ['arm'], 't': (0.85, 1.15)}),
                       (gold, {'meshes': ['arm'], 't': (0.2, 0.32)}),
                       (cy, {'meshes': ['arm'], 't': (0.32, 0.36)}),
                       (cloth((200, 200, 210), seed=407, weave=0.06), {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] + 0.5 * k)})),
        'legs': layers(suit,
                       (under, {'meshes': ['leg'], 't': (0.88, 1.12)}),
                       (gold, {'meshes': ['leg'], 't': (1.62, 2.2)}),
                       (cy, {'meshes': ['leg'], 't': (0.3, 0.34), 'x': (-3, 20)})),
        'boot': layers(white, (gold, {'z': (-60, -34.5), 'soft': 0.2})),
        'gold': gold,
        'white': white,
        'visor': {'type': 'glow', 'color': (255, 186, 40), 'color2': (255, 246, 200), 'freq': 1.4},
        'vest': layers(white, (cy, {'x': (2.0 * k, 30), 'z': (J('Bip01 Spine3')[2] + 1.0 * k, J('Bip01 Spine3')[2] + 1.4 * k), 'soft': 0.15}),
                       (gold, {'z': (-60, J('Bip01 Spine')[2] + 0.2 * k)})),
        'plate': gold,
        'cape': cloth((112, 54, 196), seed=408, weave=0.08, weave_freq=5.0, dirt=0.1, fold_freq=0.5,
                      stripes=[dict(normal=(0, 1, 0), offset=0.0, width=0.5 * k, color=(0, 200, 240))]),
        'belt': layers(white, (gold, {'z': (J('Bip01 Pelvis')[2] + 0.2 * k, J('Bip01 Pelvis')[2] + 1.0 * k)})),
        'metal': gold,
        'pouch': white,
        'rubber': {'type': 'rubber', 'color': (40, 36, 44)},
        'hair': {'type': 'hair', 'color': (120, 96, 60), 'tip': (170, 140, 90), 'seed': 409},
    }


def _vip_decals(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    zc = J('Bip01 Spine2')[2] + 1.0 * k
    return [
        _emblem((J('Bip01 Spine2')[0] + 7.0 * k, 0, zc + 0.3 * k), (0, -1, 0), (0, 0, 1), 3.0 * k,
                target=['plate', 'plate_front'], depth=3.0),
        _emblem((J('Bip01 Spine2')[0] + 7.0 * k, 0, zc + 0.3 * k), (0, -1, 0), (0, 0, 1), 4.0 * k, color=PURPLE,
                shape='ring', mode='paint', alpha=0.75, target=['plate', 'plate_front'], depth=3.0),
        # purple diamonds on the shoulder plates
        _emblem(J('Bip01 L UpperArm') + np.array([0, 3.2 * k, 1.5 * k]), (1, 0, 0), (0, 0, 1), 1.3 * k, color=PURPLE,
                shape='diamond', mode='paint', target=['gold', 'shoulderpad'], depth=3.0),
        _emblem(J('Bip01 R UpperArm') + np.array([0, -3.2 * k, 1.5 * k]), (-1, 0, 0), (0, 0, 1), 1.3 * k, color=PURPLE,
                shape='diamond', mode='paint', target=['gold', 'shoulderpad'], depth=3.0),
    ]


def _vip_accessories(rig, sh):
    return [
        ('helmet', dict(mat='gold', visor_mat='visor', style='full', crest=0.9, rails=False, mount=False, ear_guards=True,
                        size=1.02)),
        ('vest', dict(mat='vest', plate_mat='plate', pouches=False, collar=True, grow=0.8)),
        ('shoulder_pads', dict(mat='gold', size=1.2)),
        ('bracers', dict(mat='gold', grow=0.45)),
        ('knee_pads', dict(mat='gold')),
        ('belt', dict(mat='belt', buckle_mat='gold', pouches=0)),
        ('cape', dict(mat='cape', length=0.72, width=7.0, tatter=0.0, flare=0.4)),
    ]


def vip(quick=False):
    """vex_vip - gold-white armoured elite, purple cape strip, crested helmet with golden visor."""
    rs = RigSpec(height=72.0, shoulder_w=0.21)
    return _base('vex_vip', rs, _vip_materials, _vip_accessories, _vip_decals,
                 face=dict(eye='human', eye_color=(60, 110, 150), brow_color=(110, 84, 50), mouth='closed',
                           hair=(120, 96, 60), stubble=0.0, brow_shadow=0.35),
                 shape=dict(hands='glove', feet='boot', muscle=0.5, chest=1.06, head=dict(jaw=1.2, chin=1.1)),
                 quick=quick)


# =============================================================================================== admin

RED = (190, 18, 26)


def _admin_materials(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    coat = cloth((30, 28, 34), seed=501, weave=0.05, weave_freq=3.5, dirt=0.15, fold_freq=0.3)
    red = cloth(RED, seed=502, weave=0.06, weave_freq=4.0, dirt=0.05)
    lea = {'type': 'leather', 'color': (24, 22, 26), 'seed': 503}
    skin_m = skin((190, 148, 120), seed=504, variation=0.07, pores=0.08)
    pg = _purple_glow()
    return {
        'skin': skin_m, 'head': skin_m,
        'hand': lea,
        'body': layers(coat,
                       (red, {'meshes': ['arm'], 't': (1.78, 1.92)}),
                       (cloth((70, 40, 120), seed=505, weave=0.06), {'meshes': ['arm'], 't': (0.32, 0.56)}),
                       (pg, {'meshes': ['arm'], 't': (0.32, 0.35)}),
                       (pg, {'meshes': ['arm'], 't': (0.53, 0.56)}),
                       (red, {'meshes': ['torso'], 'y': (-0.5 * k, 0.5 * k), 'x': (0, 30), 'z': (-60, J('Bip01 Spine3')[2])})),
        'legs': layers(cloth((36, 34, 40), seed=506, weave=0.06, fold_freq=0.25),
                       (red, {'meshes': ['leg'], 'y': (2.6 * k, 3.4 * k), 't': (0, 1.5)}),
                       (red, {'meshes': ['leg'], 'y': (-3.4 * k, -2.6 * k), 't': (0, 1.5)}),
                       (lea, {'meshes': ['leg'], 't': (1.35, 2.2)})),
        'boot': layers(lea, ({'type': 'rubber', 'color': (16, 16, 18)}, {'z': (-60, -35.0), 'soft': 0.2})),
        'coat': layers(coat,
                       (red, {'z': (-60, J('Bip01 Pelvis')[2] - 0.75 * (J('Bip01 Pelvis')[2] + 36.0) + 1.2 * k)}),
                       (red, {'y': (-0.5 * k, 0.5 * k), 'x': (0, 30), 'z': (-60, J('Bip01 Spine3')[2] + 0.5 * k)})),
        'cap': cloth((26, 24, 30), seed=507, weave=0.04, dirt=0.05),
        'cap_band': red,
        'cap_peak': {'type': 'leather', 'color': (14, 14, 16), 'seed': 508},
        'badge': metal((210, 30, 36), seed=509, shine=0.7, scratches=0.1),
        'redvisor': {'type': 'glow', 'color': (255, 30, 30), 'color2': (255, 170, 150), 'freq': 0.9},
        'visor_frame': metal((40, 40, 46), seed=510, shine=0.6),
        'plate': layers(metal((32, 30, 36), seed=511, shine=0.55, edge_wear=0.5, scratches=0.25),
                        (red, {'z': (J('Bip01 L UpperArm')[2] + 1.4 * k, 60)})),
        'belt': {'type': 'leather', 'color': (20, 18, 20), 'seed': 512},
        'metal': metal((170, 160, 150), seed=513, shine=0.6),
        'pouch': lea,
        'rubber': {'type': 'rubber', 'color': (20, 20, 22)},
        'hair': {'type': 'hair', 'color': (30, 26, 24), 'tip': (60, 56, 54), 'seed': 514},
        'patch': cloth((26, 24, 30), seed=515, weave=0.0, dirt=0.0),
    }


def _admin_decals(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    zc = J('Bip01 Spine2')[2] + 1.6 * k
    return [
        _emblem((J('Bip01 Spine2')[0] + 6.0 * k, 3.2 * k, zc), (0, -1, 0), (0, 0, 1), 1.3 * k, color=PURPLE,
                target=['vest', 'coat'], depth=3.0),
        # back: large Vexmira emblem in purple glow with a red ring
        _emblem((J('Bip01 Spine2')[0] - 7.0 * k, 0, zc), (0, 1, 0), (0, 0, 1), 3.0 * k, color=PURPLE,
                target=['vest', 'coat'], depth=3.0),
        _emblem((J('Bip01 Spine2')[0] - 7.0 * k, 0, zc), (0, 1, 0), (0, 0, 1), 4.0 * k, color=RED, shape='ring',
                mode='paint', target=['vest', 'coat'], depth=3.0),
        _emblem(J('Bip01 L UpperArm') + np.array([0.0, 2.5 * k, -3.4 * k]), (1, 0, 0), (0, 0, 1), 0.95 * k,
                target=['patch'], color=PURPLE),
    ]


def _admin_accessories(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    return [
        ('hair', dict(mat='hair', volume=0.4)),
        ('hum_officer_cap', dict(mat='cap', band='cap_band', peak='cap_peak', badge='badge')),
        ('hum_visor_band', dict(mat='redvisor', frame='visor_frame')),
        ('hum_shell', dict(z0=J('Bip01 Pelvis')[2] - 1.0 * k, z1=J('Bip01 L UpperArm')[2] + 0.4 * k, grow=0.75, mat='coat',
                       name='coat_top', rings=8, bottom_flare=0.6)),
        ('coat_skirt', dict(mat='coat', length=0.8, flare=0.35)),
        ('shoulder_pads', dict(mat='plate', size=0.85)),
        ('belt', dict(mat='belt', buckle_mat='metal', pouches=1, pouch_mat='pouch', grow=0.95)),
        ('sleeve_cuffs', dict(mat='coat', part='Forearm', at=0.82, grow=0.55)),
        ('emblem_patch', dict(mat='patch', where='arm_L')),
    ]


def admin(quick=False):
    """vex_admin - black-red commander, long coat, officer cap, red glowing visor band."""
    rs = RigSpec(height=72.0, shoulder_w=0.205)
    return _base('vex_admin', rs, _admin_materials, _admin_accessories, _admin_decals,
                 face=dict(eye='human', eye_color=(90, 60, 50), brow_color=(30, 26, 24), mouth='closed',
                           hair=(30, 26, 24), stubble=0.25, brow_shadow=0.55),
                 shape=dict(hands='glove', feet='boot', muscle=0.4, chest=1.03,
                            head=dict(jaw=1.3, chin=1.15, brow=1.25, cheek=0.9)),
                 quick=quick)


# =============================================================================================== survivor

STEEL = (88, 96, 92)


def _survivor_materials(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    armor = metal(STEEL, seed=601, paint=(78, 86, 74), chipping=0.55, edge_wear=0.9, scratches=0.7, rust=0.35,
                  shine=0.3, blood=0.35, panels=0.6)
    under = cloth((58, 58, 56), seed=602, weave=0.14, weave_freq=4.0, dirt=0.85, dirt_z=20, dirt_color=(70, 60, 44),
                  stains=0.7, blood=0.45, tears=0.25, fold_freq=0.25)
    cy = _cyan_glow()
    skin_m = skin((176, 132, 106), seed=603, variation=0.1, scars=0.6, wounds=0.15, blood=0.25)
    return {
        'skin': skin_m, 'head': skin_m,
        'hand': layers({'type': 'leather', 'color': (52, 46, 40), 'seed': 604, 'blood': 0.4},
                       ({'type': 'rubber', 'color': (30, 30, 30)}, {'meshes': ['fingers', 'thumb']})),
        'body': layers(under,
                       (armor, {'meshes': ['arm'], 't': (0.0, 0.62)}),
                       (cy, {'meshes': ['arm'], 't': (0.62, 0.66)})),
        'legs': layers(under,
                       (armor, {'meshes': ['leg'], 't': (0.12, 0.62), 'x': (-1.0 * k, 30)}),
                       (armor, {'meshes': ['leg'], 't': (1.1, 2.2)})),
        'boot': layers({'type': 'leather', 'color': (44, 40, 36), 'seed': 605, 'blood': 0.3},
                       (metal((70, 74, 72), seed=606, rust=0.4, chipping=0.4), {'z': (-60, -34.0), 'soft': 0.2})),
        'armor': armor,
        'helmet': layers(armor, (cy, {'y': (-0.3 * k, 0.3 * k), 'x': (-20, 20), 'z': (J('Bip01 Head')[2] + 7.2 * k, 60)})),
        'slit': {'type': 'glow', 'color': CYAN, 'color2': (210, 255, 255), 'freq': 1.2},
        'vest': layers(armor, (cy, {'x': (2.0 * k, 30), 'z': (J('Bip01 Spine3')[2] + 1.2 * k, J('Bip01 Spine3')[2] + 1.6 * k), 'soft': 0.15})),
        'plate': metal((104, 110, 104), seed=607, paint=(92, 100, 88), chipping=0.6, edge_wear=1.0, scratches=0.7,
                       rust=0.3, blood=0.3, shine=0.3),
        'pouch': cloth((70, 70, 62), seed=608, weave=0.18, weave_freq=6.0, dirt=0.8, stains=0.5, blood=0.3),
        'belt': cloth((36, 36, 34), seed=609, weave=0.2, weave_freq=6.0, dirt=0.5),
        'bandage': cloth((206, 196, 170), seed=610, weave=0.3, weave_freq=7.0, dirt=0.8, dirt_color=(140, 120, 90),
                         stains=0.6, blood=0.8),
        'metal': metal((140, 140, 134), seed=611, rust=0.3),
        'rubber': {'type': 'rubber', 'color': (28, 28, 28)},
    }


def _survivor_decals(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    zc = J('Bip01 Spine2')[2] + 1.0 * k
    return [
        _emblem((J('Bip01 Spine2')[0] + 8.0 * k, 0, zc + 0.4 * k), (0, -1, 0), (0, 0, 1), 2.6 * k,
                target=['plate', 'plate_front'], depth=3.0),
        # purple tally / hazard stripes painted on the shoulder plates
        _emblem(J('Bip01 L UpperArm') + np.array([0.3 * k, 3.6 * k, 1.6 * k]), (1, 0, 0), (0, 0, 1), 1.7 * k,
                color=PURPLE, shape='chevron', mode='paint', target=['plate', 'shoulderpad'], depth=3.0, alpha=0.85),
        _emblem(J('Bip01 R UpperArm') + np.array([0.3 * k, -3.6 * k, 1.6 * k]), (-1, 0, 0), (0, 0, 1), 1.7 * k,
                color=PURPLE, shape='chevron', mode='paint', target=['plate', 'shoulderpad'], depth=3.0, alpha=0.85),
        # claw scratches / blood splatter on the chest armour and the back
        dict(kind='sphere', center=J('Bip01 Spine2') + np.array([6.0 * k, -3.0 * k, -2.0 * k]), radius=2.4 * k,
             scale=(1, 0.6, 1.6), soft=0.5, color=(96, 8, 10), color2=(50, 0, 4), alpha=0.85, mode='blood'),
        dict(kind='sphere', center=J('Bip01 Spine1') + np.array([-5.0 * k, 2.5 * k, 0.0]), radius=2.8 * k, soft=0.5,
             color=(90, 6, 8), color2=(40, 0, 3), alpha=0.8, mode='blood'),
        dict(kind='sphere', center=J('Bip01 R Thigh') + np.array([3.0 * k, -1.0 * k, -6.0 * k]), radius=2.0 * k, soft=0.5,
             color=(90, 6, 8), color2=(40, 0, 3), alpha=0.8, mode='blood'),
    ]


def _survivor_accessories(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    th = lambda s, d: tuple((J('Bip01 %s Thigh' % s) + np.array(d) * k) / k)
    cf = lambda s, d: tuple((J('Bip01 %s Calf' % s) + np.array(d) * k) / k)
    return [
        ('helmet', dict(mat='helmet', visor_mat='slit', style='full', ear_guards=True, size=1.1, low=0.4, rails=True,
                        rail_mat='plate', mount=False)),
        ('hum_gorget', dict(mat='armor', grow=1.3)),
        ('vest', dict(mat='vest', pouch_mat='pouch', plate_mat='plate', grow=1.5, collar=False)),
        ('shoulder_pads', dict(mat='plate', size=1.65)),
        ('bracers', dict(mat='plate', grow=0.9)),
        ('knee_pads', dict(mat='plate')),
        ('belt', dict(mat='belt', buckle_mat='metal', pouches=4, pouch_mat='pouch', grow=1.6)),
        ('wraps', dict(mat='bandage', where=(('L', 'UpperArm', 0.62, 0.95), ('R', 'Thigh', 0.62, 0.9)), grow=0.35)),
        ('plates_on', dict(mat='plate', items=[
            ('Bip01 L Thigh', th('L', (2.6, 0.6, -7.0)), (1.4, 4.4, 6.5), (0, -6, 0)),
            ('Bip01 R Thigh', th('R', (2.6, -0.6, -7.0)), (1.4, 4.4, 6.5), (0, -6, 0)),
            ('Bip01 L Calf', cf('L', (2.4, 0.0, -7.5)), (1.3, 3.4, 8.5), (0, -4, 0)),
            ('Bip01 R Calf', cf('R', (2.4, 0.0, -7.5)), (1.3, 3.4, 8.5), (0, -4, 0))])),
    ]


def survivor(quick=False):
    """vex_survivor - heavy juggernaut armour, huge shoulder plates, scratched, dirty and wounded."""
    rs = RigSpec(height=72.0, shoulder_w=0.23, hip_w=0.125, bulk=1.28, limb_thick=1.22, head=0.138)
    return _base('vex_survivor', rs, _survivor_materials, _survivor_accessories, _survivor_decals,
                 face=dict(eye='human', eye_color=(80, 90, 90), brow_color=(50, 38, 30), mouth='closed', stubble=0.8,
                           brow_shadow=0.6),
                 shape=dict(hands='glove', feet='boot', muscle=0.7, chest=1.12, waist=1.1, shoulders=1.1,
                            head=dict(jaw=1.45, chin=1.1, brow=1.3, w=1.08)),
                 quick=quick)


# =============================================================================================== sniper

CAMO = [(86, 94, 62), (58, 64, 42), (124, 116, 82), (40, 42, 32)]


def _sniper_materials(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    camo = cloth(CAMO[0], seed=701, camo=CAMO, camo_freq=0.11, weave=0.1, weave_freq=4.0, dirt=0.5,
                 dirt_color=(70, 62, 44), fold_freq=0.3)
    camo2 = dict(camo, seed=702, camo_freq=0.09, dirt=0.65)
    skin_m = skin((188, 146, 116), seed=703, variation=0.08)
    pg = _purple_glow()
    cy = _cyan_glow()
    return {
        'skin': skin_m, 'head': skin_m,
        'hand': layers({'type': 'leather', 'color': (64, 58, 44), 'seed': 704},
                       ({'type': 'leather', 'color': (176, 136, 108), 'seed': 705}, {'meshes': ['fingers']})),
        'body': layers(camo, (cy, {'meshes': ['arm'], 't': (0.4, 0.44)}),
                       (camo2, {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] + 0.5 * k), 'soft': 0.3})),
        'legs': layers(camo2, (cloth((52, 54, 40), seed=706, weave=0.2), {'meshes': ['leg'], 't': (1.62, 2.2)})),
        'boot': layers({'type': 'leather', 'color': (58, 50, 38), 'seed': 707},
                       ({'type': 'rubber', 'color': (30, 28, 24)}, {'z': (-60, -35.0), 'soft': 0.2})),
        'hood': layers(dict(camo, seed=708), (cy, {'z': (J('Bip01 Head')[2] + 9.5 * k, 60), 'y': (-0.3 * k, 0.3 * k)})),
        'cloak': cloth(CAMO[1], seed=709, camo=CAMO, camo_freq=0.12, weave=0.25, weave_freq=6.0, dirt=0.6,
                       tears=0.4, fold_freq=0.5),
        'ghillie': cloth((70, 78, 46), seed=710, camo=[(70, 78, 46), (96, 92, 58), (48, 54, 34)], camo_freq=0.3,
                         weave=0.4, weave_freq=9.0, dirt=0.4),
        'mask': cloth((44, 46, 38), seed=711, weave=0.25, weave_freq=7.0, dirt=0.2, fold_freq=0.6),
        'scope_metal': metal((42, 44, 46), seed=712, shine=0.5, scratches=0.3),
        'mono_lens': pg,
        'vest': cloth((72, 76, 54), seed=713, weave=0.16, weave_freq=6.0, dirt=0.5,
                      stripes=[dict(normal=(0, 0, 1), offset=J('Bip01 Spine')[2] + i * 2.3 * k, width=0.5 * k,
                                    color=(54, 58, 40)) for i in range(1, 7)]),
        'pouch': cloth((80, 82, 58), seed=714, weave=0.15, weave_freq=6.0, dirt=0.5),
        'belt': cloth((44, 44, 36), seed=715, weave=0.2, weave_freq=6.0, dirt=0.3),
        'plate': cloth((66, 70, 50), seed=716, weave=0.2, weave_freq=6.0, dirt=0.5),
        'metal': metal((120, 120, 112), seed=717),
        'rubber': {'type': 'rubber', 'color': (30, 30, 28)},
        'patch': cloth((40, 34, 60), seed=718, weave=0.0, dirt=0.0),
    }


def _sniper_decals(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    from ..body import face_anchor as _fa
    fa = _fa(rig, sh)
    return [
        _emblem(J('Bip01 L UpperArm') + np.array([0.0, 2.5 * k, -3.4 * k]), (1, 0, 0), (0, 0, 1), 0.95 * k,
                target=['patch']),
        _emblem(J('Bip01 L UpperArm') + np.array([0.0, 2.5 * k, -3.4 * k]), (1, 0, 0), (0, 0, 1), 1.15 * k,
                color=PURPLE, mode='paint', alpha=0.4, shape='diamond', target=['patch'], soft=0.3),
        # dark camo face paint around the eyes
        dict(kind='band', normal=(0, 0, 1), offset=fa['eye_L'][2], width=1.6 * k, soft=0.7, color=(60, 66, 44),
             mode='multiply', alpha=0.55, target='head'),
    ]


def _sniper_accessories(rig, sh):
    J = rig.J
    k = rig.H / 72.0
    return [
        ('hood', dict(mat='hood', depth=1.15, peak=1.3)),
        ('hum_face_mask', dict(mat='mask')),
        ('hum_monocular', dict(mat='scope_metal', lens='mono_lens', side='R')),
        ('vest', dict(mat='vest', pouch_mat='pouch', plates=False, collar=False, grow=0.5)),
        ('cape', dict(mat='cloak', length=0.82, width=14.0, tatter=0.65, flare=0.42)),
        ('shirt_flaps', dict(mat='ghillie', n=10, length=5.0, seed=7, z=J('Bip01 Spine3')[2] + 1.5 * k)),
        ('belt', dict(mat='belt', buckle_mat='metal', pouches=2, pouch_mat='pouch')),
        ('knee_pads', dict(mat='plate')),
        ('emblem_patch', dict(mat='patch', where='arm_L')),
    ]


def sniper(quick=False):
    """vex_sniper - camo-cloaked sniper: ragged camo cloak, hood, face mask, purple monocular."""
    rs = RigSpec(height=72.0, shoulder_w=0.198, limb_thick=0.96)
    return _base('vex_sniper', rs, _sniper_materials, _sniper_accessories, _sniper_decals,
                 face=dict(eye='human', eye_color=(70, 90, 60), brow_color=(50, 40, 30), mouth='closed', stubble=0.3,
                           brow_shadow=0.6),
                 shape=dict(hands='glove', feet='boot', muscle=0.35, chest=1.0, head=dict(jaw=1.1, brow=1.2)),
                 quick=quick)


# =============================================================================================== all

def all(quick=False):    # noqa: A001 - CLI entry point name
    """All 7 human (CT) models."""
    return [operator(quick), ranger(quick), hazmat(quick), vip(quick), admin(quick), survivor(quick), sniper(quick)]
