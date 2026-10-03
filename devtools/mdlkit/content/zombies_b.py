"""Zombie classes 12-23 (area 'zombies-B'): player models vex_z_<name> + claws v_<name>.

    cd devtools
    python3 -m mdlkit list  mdlkit.content.zombies_b
    python3 -m mdlkit build mdlkit.content.zombies_b:butcher --lookdev
    python3 -m mdlkit build mdlkit.content.zombies_b:butcher          # player + claws -> cstrike/
    python3 -m mdlkit build mdlkit.content.zombies_b:all --only vex_z_volt

Colours follow CLASS_RGB (DESIGN_v3.md section 3); silhouettes sell the [R] ability (section 12):
Butcher apron + chained meat hook, Hunter feral hooded crouch, Charger one giant bone-shielded arm,
Arachne four spider legs on the back, Magma black crust with lava cracks, Volt battery pack + cables,
Mimic half Vexmira soldier / half flesh, Burrower dirt + digging claws + broken miner lamp, Siren long
pink hair + glowing eyes, Bulwark rock plates, Sporemother fungal sacs + mushroom caps, Nightmare smoky
multi-eyed red glow. All content is procedural and original.
"""
import math
import numpy as np

from . import *          # noqa: F401,F403  (the content API)

AREA = 'zombies-B'
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


# ============================================================================================ helpers
def _bi(rig, name):
    return rig.index[name]


def _k(rig):
    return rig.H / 72.0


def _unit(v):
    v = np.asarray(v, float)
    return v / max(np.linalg.norm(v), 1e-9)


def _align(d, up=(0, 0, 1)):
    """Rotation matrix whose local +Z is direction d."""
    z = _unit(d)
    up = np.asarray(up, float)
    if abs(np.dot(up, z)) > 0.95:
        up = np.array([1.0, 0, 0]) if abs(z[0]) < 0.9 else np.array([0, 1.0, 0])
    x = _unit(np.cross(up, z))
    y = np.cross(z, x)
    return np.stack([x, y, z], axis=1)


def _nohit(ms):
    for m in ms:
        m.no_hitbox = True
    return ms


def lumps(rig, sh, mat='sac', where=(), seed=3, flat=0.9, segs=8, rings=5, hit=False):
    """Clusters of organic lumps / sacs / rocks: where = [(bone, offset(units@72 from the bone joint),
    radius, count, spread(3))]."""
    k = _k(rig)
    rng = np.random.default_rng(seed)
    out = []
    for bone, off, r, n, spread in where:
        b = _bi(rig, bone)
        c0 = rig.J(bone) + np.array(off, float) * k
        for i in range(n):
            c = c0 + rng.uniform(-1, 1, 3) * np.array(spread, float) * k
            rr = r * rng.uniform(0.65, 1.15) * k
            out.append(ellipsoid((rr, rr * rng.uniform(0.85, 1.1), rr * flat), c, segs=segs, rings=rings, mat=mat, bone=b))
    return out if hit else _nohit(out)


def hook_mesh(top, down, side, size, k, mat='hook', bone=0, r=0.42, eye=True):
    """Meat hook: eye ring at `top`, shank along `down`, J-curve opening toward `side`, barbed point."""
    d = _unit(down)
    s = _unit(side - np.dot(side, d) * d)
    up = -d
    top = np.asarray(top, float)
    L = 4.2 * size * k
    R = 2.0 * size * k
    shank = [top + d * L * t for t in (0.0, 0.5, 1.0)]
    ctr = top + d * L + s * R
    arc = [ctr + R * (math.cos(t) * s + math.sin(t) * up) for t in np.linspace(math.pi, 2 * math.pi + 0.55, 9)[1:]]
    pts = shank + arc
    rad = np.linspace(r, r * 0.65, len(pts)) * size * k
    out = [tube(pts, rad, segs=7, mat=mat, bones=bone, cap_start=True, cap_end=True)]
    t_end = 2 * math.pi + 0.55
    tang = _unit(-math.sin(t_end) * s + math.cos(t_end) * up)
    out.append(cone(pts[-1], pts[-1] + tang * 1.1 * size * k, rad[-1] * 1.05, segs=6, mat=mat, bone=bone))
    if eye:
        er = 0.75 * size * k
        ec = top + up * er * 0.9
        ring = [ec + er * (math.cos(t) * up + math.sin(t) * np.cross(d, s)) for t in np.linspace(0, 2 * math.pi, 11)]
        out.append(tube(ring, 0.22 * size * k, segs=5, mat=mat, bones=bone, cap_start=False, cap_end=False))
    return out


def hand_hook(rig, sh, mat='hook', chain_mat='chain', side='R', size=1.25):
    """Butcher: a big meat hook gripped in the fist, chain wound around the forearm (all on arm bones,
    so it also shows in the v_ claws)."""
    from ..accessories import chain as _chain
    k = _k(rig)
    sg = 1 if side == 'L' else -1
    hb = _bi(rig, 'Bip01 %s Hand' % side)
    fb = _bi(rig, 'Bip01 %s Forearm' % side)
    H = rig.J('Bip01 %s Hand' % side)
    F1 = rig.J('Bip01 %s Finger1' % side)
    down = _unit(F1 - H)
    top = H + down * 2.2 * k + np.array([0.6, 0, 0]) * k
    out = hook_mesh(top, down, np.array([1.0, 0, 0]), size, k, mat=mat, bone=hb)
    # chain spiral around the forearm, then down to the hook eye
    A = rig.J('Bip01 %s Forearm' % side)
    ax = H - A
    fr = _align(ax)
    pts = []
    for i in range(10):
        t = 0.25 + 0.65 * i / 9
        a = i * 1.35
        pts.append(A + ax * t + (fr[:, 0] * math.cos(a) + fr[:, 1] * math.sin(a)) * 2.25 * k)
    out += _chain(rig, sh, mat=chain_mat, points=pts, bones=[fb] * (len(pts) - 1), link=0.75)
    return _nohit(out)


def belt_hooks(rig, sh, mat='hook', n=2, side='L'):
    """Small spare meat hooks hanging from the belt at one hip (pelvis bone)."""
    k = _k(rig)
    sg = 1 if side == 'L' else -1
    pb = _bi(rig, 'Bip01 Pelvis')
    P = rig.J('Bip01 Pelvis')
    out = []
    for i in range(n):
        top = P + np.array([1.5 - 3.2 * i, sg * (6.2 + 0.2 * i), -0.8]) * k
        out += hook_mesh(top, np.array([0, sg * 0.15, -1.0]), np.array([0, sg * 1.0, 0]), 0.62, k, mat=mat, bone=pb)
    return _nohit(out)


def giant_arm(rig, sh, mat='bigarm', bone_mat='bone', side='R', shield_mat='shield'):
    """Charger: one hugely swollen arm - bulging upper arm, club forearm, boulder fist with knuckle spurs,
    and a bone shield grown over the shoulder."""
    k = _k(rig)
    sg = 1 if side == 'L' else -1
    U = rig.J('Bip01 %s UpperArm' % side)
    Fo = rig.J('Bip01 %s Forearm' % side)
    H = rig.J('Bip01 %s Hand' % side)
    F1 = rig.J('Bip01 %s Finger1' % side)
    ub, fb, hb = (_bi(rig, 'Bip01 %s %s' % (side, p)) for p in ('UpperArm', 'Forearm', 'Hand'))
    out = []
    ua = [U + (Fo - U) * t for t in (0.0, 0.25, 0.55, 0.85, 1.02)]
    out.append(tube(ua, np.array([3.4, 4.6, 4.9, 4.0, 3.3]) * k, segs=12, mat=mat, bones=ub))
    fa = [Fo + (H - Fo) * t for t in (-0.05, 0.2, 0.5, 0.8, 1.0)]
    out.append(tube(fa, np.array([3.6, 4.9, 5.6, 5.2, 4.2]) * k, segs=12, mat=mat, bones=fb))
    # boulder fist around the palm (fingers / claws stay free below it)
    d = _unit(F1 - H)
    fc = H + d * 1.6 * k
    out.append(ellipsoid((3.6 * k, 3.3 * k, 3.4 * k), fc, segs=12, rings=8, mat=mat, bone=hb))
    for i, a in enumerate(np.linspace(-1, 1, 4)):
        base = fc + np.array([2.7, sg * -0.0, 0]) * k + np.array([0, a * 2.0, -0.8]) * k
        out.append(horn(base, (1.0, a * 0.25, -0.3), 2.2 * k, 0.65 * k, mat=bone_mat, bone=hb, segs=5, steps=3))
    # bone ridge along the forearm (outer side)
    for t in (0.25, 0.5, 0.75):
        p = Fo + (H - Fo) * t + np.array([-2.2, sg * 4.2, 0]) * k
        out.append(horn(p, (-0.6, sg * 1.0, 0.25), 3.0 * k, 0.9 * k, curve=(0, 0, 0.6 * k), mat=bone_mat, bone=fb,
                        segs=6, steps=4))
    # shoulder shield: thick bone plate over the shoulder + spurs
    sc = U + np.array([-0.4, sg * 1.2, 2.2]) * k
    R = _align((0.1, sg * 0.55, 1.0))
    sh_m = ellipsoid((5.2 * k, 4.6 * k, 2.2 * k), (0, 0, 0), segs=12, rings=7, mat=shield_mat, bone=ub, R=R)
    sh_m.translate(sc)
    out.append(sh_m)
    for i, (dx, dz) in enumerate(((-2.0, 1.0), (0.6, 1.6), (2.6, 0.6))):
        p = sc + np.array([dx, sg * 1.2, dz]) * k
        out.append(horn(p, (dx * 0.15, sg * 0.7, 1.0), 3.2 * k, 0.9 * k, curve=(0, 0, -0.4 * k), mat=bone_mat, bone=ub,
                        segs=6, steps=4))
    return out


def _front_pts(rig, sh, items, grow=0.6):
    """Points on the torso front surface: items = [(spine bone, y units@72, dz units@72)]."""
    from ..body import torso_mesh
    k = _k(rig)
    t = torso_mesh(rig, sh, 'tmp')
    out = []
    for bone, y, dz in items:
        z = rig.J(bone)[2] + dz * k
        sel = (np.abs(t.v[:, 2] - z) < 2.0 * k) & (np.abs(t.v[:, 1] - y * k) < 1.6 * k) & (t.v[:, 0] > 0)
        x = t.v[sel, 0].max() if sel.any() else rig.J('Bip01 Spine2')[0] + 5.0 * k
        out.append(np.array([x + grow * k, y * k, z]))
    return out


def _shell(rig, sh, **kw):
    from ..accessories import shell
    return [shell(rig, sh, **kw)]


def extra_eyes(rig, sh, mat='eyeglow', spots=(), size=0.4):
    """Additional glowing eyes on the head: spots = [(y, z)] in units@72 relative to the head centre."""
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    c = fa['center']
    rx, ry, rz = fa['radii']
    out = []
    for y, z in spots:
        yy, zz = y * k, z * k
        q = 1 - (yy / ry) ** 2 - (zz / rz) ** 2
        x = rx * math.sqrt(max(q, 0.05))
        e = ellipsoid((0.35 * k * size * 2, 0.5 * k * size * 2, 0.42 * k * size * 2), c + np.array([x - 0.05 * k, yy, zz]),
                      segs=8, rings=5, mat=mat, bone=hb)
        e.name = 'eyeglow'
        out.append(e)
    return _nohit(out)


def body_eyes(rig, sh, mat='eyeglow', where=(), size=0.5):
    """Glowing eyes on the body: where = [(bone, offset units@72 from the joint)]."""
    k = _k(rig)
    out = []
    for bone, off in where:
        c = rig.J(bone) + np.array(off, float) * k
        out.append(ellipsoid((0.45 * k * size * 2, 0.6 * k * size * 2, 0.45 * k * size * 2), c, segs=8, rings=5, mat=mat,
                             bone=_bi(rig, bone)))
    return _nohit(out)


def fangs(rig, sh, mat='fang', size=1.0):
    """Arachne: a pair of curved chelicera fangs under the mouth."""
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    out = []
    for sg in (1, -1):
        base = fa['mouth'] + np.array([-0.2, sg * 0.9, 0.1]) * k
        out.append(horn(base, (0.6, sg * 0.15, -1.0), 2.6 * k * size, 0.45 * k * size, curve=(0, -sg * 0.5 * k, 0.6 * k),
                        mat=mat, bone=hb, segs=6, steps=4))
    return _nohit(out)


def abdomen(rig, sh, mat='abdomen', size=1.0):
    """Arachne: bulbous spider abdomen behind the hips (pelvis bone, follows the gait)."""
    k = _k(rig)
    P = rig.J('Bip01 Pelvis')
    c = P + np.array([-6.6, 0, 1.6]) * k * np.array([size, 1, 1])
    R = _align((-1.0, 0, 0.55))
    m = ellipsoid((4.4 * k * size, 4.0 * k * size, 6.0 * k * size), (0, 0, 0), segs=14, rings=9, mat=mat,
                  bone=_bi(rig, 'Bip01 Pelvis'), R=R)
    m.translate(c)
    m.name = 'abdomen'
    tip = c + _unit((-1.0, 0, 0.55)) * 5.8 * k * size
    sp = cone(tip - _unit((-1.0, 0, 0.55)) * 0.5 * k, tip + _unit((-1.0, 0, 0.2)) * 1.2 * k, 0.8 * k, segs=6, mat=mat,
              bone=_bi(rig, 'Bip01 Pelvis'))
    return _nohit([m, sp])


def battery_pack(rig, sh, case='battery', cell='cell', arc='arc', cable='cable'):
    """Volt: battery pack on the back with two cells, electrode rods and cables over the shoulders into
    the chest (all on the upper spine)."""
    k = _k(rig)
    J = rig.J
    s3 = _bi(rig, 'Bip01 Spine3')
    s2 = _bi(rig, 'Bip01 Spine2')
    z = J('Bip01 Spine2')[2] + 1.5 * k
    x = J('Bip01 Spine2')[0] - 5.4 * k * rig.spec.bulk ** 0.5 - 1.8 * k
    out = [box((3.6 * k, 8.4 * k, 9.5 * k), center=(x, 0, z), bevel=0.6 * k, mat=case, bone=s2)]
    for sg in (1, -1):
        cy = sg * 2.4 * k
        c0 = np.array([x - 2.4 * k, cy, z - 4.5 * k])
        c1 = np.array([x - 2.4 * k, cy, z + 5.0 * k])
        out.append(cylinder(c0, c1, 1.6 * k, segs=12, mat=cell, bone=s2))
        for t in (0.3, 0.7):
            p = c0 + (c1 - c0) * t
            out.append(cylinder(p - np.array([0, 0, 0.35 * k]), p + np.array([0, 0, 0.35 * k]), 1.75 * k, segs=12, mat=arc,
                                bone=s2, caps=False))
        # electrode rod + glowing tip
        r0 = np.array([x - 0.6 * k, sg * 3.0 * k, z + 4.6 * k])
        r1 = r0 + np.array([-1.2, sg * 0.8, 5.0]) * k
        out.append(cylinder(r0, r1, 0.35 * k, 0.25 * k, segs=6, mat=case, bone=s3))
        out.append(ellipsoid((0.7 * k, 0.7 * k, 0.7 * k), r1, segs=8, rings=5, mat=arc, bone=s3))
        # cables: pack -> over the shoulder -> into the chest
        a = np.array([x + 0.4 * k, sg * 2.6 * k, z + 4.0 * k])
        sh_top = np.array([J('Bip01 Spine3')[0] - 1.2 * k, sg * 3.6 * k, J('Bip01 Neck')[2] + 0.2 * k])
        ch = np.array([J('Bip01 Spine3')[0] + 4.2 * k * rig.spec.bulk ** 0.5, sg * 2.6 * k, J('Bip01 Spine3')[2] - 1.0 * k])
        mid = (a + sh_top) / 2 + np.array([-1.0, 0, 1.4]) * k
        out.append(tube([a, mid, sh_top, ch], 0.55 * k, segs=6, mat=cable, bones=s3))
        # lower cable into the back
        b0 = np.array([x + 0.2 * k, sg * 3.6 * k, z - 3.0 * k])
        b1 = np.array([J('Bip01 Spine1')[0] - 4.6 * k * rig.spec.bulk ** 0.5, sg * 2.0 * k, J('Bip01 Spine1')[2]])
        out.append(tube([b0, (b0 + b1) / 2 + np.array([-1.5, sg * 0.6, 0]) * k, b1], 0.5 * k, segs=6, mat=cable,
                        bones=s2))
    return _nohit(out)


def miner_lamp(rig, sh, mat='lamp', glass='glass'):
    """Burrower: miner's lamp on the helmet front, the glass cracked and dark."""
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    c = fa['center']
    rx, ry, rz = fa['radii']
    p = c + np.array([rx * 0.75 + 0.9 * k, 0, rz * 0.72 + 0.6 * k])
    d = np.array([1.0, 0, 0.12])
    out = [cylinder(p - d * 1.2 * k, p + d * 0.6 * k, 1.05 * k, 1.25 * k, segs=10, mat=mat, bone=hb),
           cylinder(p + d * 0.55 * k, p + d * 0.75 * k, 1.0 * k, 1.0 * k, segs=10, mat=glass, bone=hb)]
    return _nohit(out)


def dig_claws(rig, sh, mat='digclaw', n=3, length=4.2, radius=0.95):
    """Burrower: broad shovel claws growing from the hands (hand bone)."""
    k = _k(rig)
    out = []
    for side, sg in (('L', 1), ('R', -1)):
        hb = _bi(rig, 'Bip01 %s Hand' % side)
        H = rig.J('Bip01 %s Hand' % side)
        F1 = rig.J('Bip01 %s Finger1' % side)
        d = _unit(F1 - H)
        for i in range(n):
            a = (i - (n - 1) / 2)
            base = H + d * 2.6 * k + np.array([0.9 * a, sg * 0.4, 0]) * k
            dirn = d + np.array([0.25 * a, sg * 0.1, 0]) + np.array([0.35, 0, 0])
            out.append(horn(base, dirn, length * k, radius * k, curve=(0.9 * k, 0, 0), mat=mat, bone=hb, segs=6, steps=4))
    return _nohit(out)


def mushrooms(rig, sh, cap='cap', stem='stem', where=(), seed=7):
    """Sporemother: mushroom caps: where = [(bone, offset units@72, direction, size)]."""
    k = _k(rig)
    out = []
    for bone, off, dirn, size in where:
        b = _bi(rig, bone)
        base = rig.J(bone) + np.array(off, float) * k
        d = _unit(dirn)
        L = 2.4 * size * k
        top = base + d * L
        out.append(cylinder(base - d * 0.6 * k, top, 0.55 * size * k, 0.45 * size * k, segs=7, mat=stem, bone=b))
        R = _align(d)
        cp = dome((2.0 * size * k, 2.0 * size * k, 1.15 * size * k), (0, 0, 0), segs=12, rings=4, mat=cap, bone=b,
                  thickness=0.25 * k)
        cp.transform(R, top - d * 0.35 * k)
        out.append(cp)
    return _nohit(out)


def smoke_tendrils(rig, sh, mat='smoke', n=6, length=7.0, seed=11):
    """Nightmare: curling smoke horns rising from shoulders and back."""
    k = _k(rig)
    J = rig.J
    rng = np.random.default_rng(seed)
    out = []
    s3 = _bi(rig, 'Bip01 Spine3')
    for i in range(n):
        sg = 1 if i % 2 == 0 else -1
        y = sg * rng.uniform(1.5, 5.5) * k
        z = J('Bip01 Spine3')[2] + rng.uniform(-2.0, 3.0) * k
        base = np.array([J('Bip01 Spine3')[0] - 3.6 * k, y, z])
        d = (-0.7, sg * rng.uniform(0.1, 0.6), 1.0)
        out.append(horn(base, d, length * rng.uniform(0.7, 1.25) * k, 1.1 * k,
                        curve=(rng.uniform(-1.5, 0.5) * k, sg * rng.uniform(0.5, 2.0) * k, rng.uniform(0, 1.5) * k),
                        mat=mat, bone=s3, segs=6, steps=6))
    return _nohit(out)


# ============================================================================================ 12 butcher
def _butcher_mats(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['butcher']
    sk = skin((172, 138, 118), seed=3201, variation=0.15, tint2=(140, 110, 120), tint2_amount=0.4, veins=0.5,
              vein_color=(110, 40, 50), rot=0.25, rot_color=(110, 80, 60), wounds=0.45, blood=0.55, scars=0.9, pores=0.2)
    apron = cloth((214, 206, 188), seed=3202, weave=0.12, weave_freq=5.0, dirt=0.5, dirt_color=(110, 90, 70), stains=0.6,
                  blood=1.0, tears=0.1)
    shirt = cloth(_dim(c, 0.62), seed=3203, weave=0.1, weave_freq=4.0, dirt=0.6, dirt_color=(60, 30, 25), stains=0.5,
                  blood=0.7, tears=0.2)
    pants = cloth((52, 46, 44), seed=3204, weave=0.1, dirt=0.8, dirt_color=(60, 40, 30), stains=0.5, blood=0.5)
    belt_z = J('Bip01 Pelvis')[2] + 0.9 * k
    front = (1.2 * k, 99)
    return {
        'skin': sk, 'head': dict(sk, seed=3205, scars=1.0, rot=0.15), 'hand': dict(sk, seed=3206, blood=1.0),
        'body': layers(sk,
                       (shirt, {'meshes': ['torso'], 'z': (belt_z - 1.0 * k, J('Bip01 Neck')[2] - 0.2 * k), 'ragged': 0.8,
                                'holes': 0.15, 'seed': 4}, (70, 10, 10)),
                       (shirt, {'meshes': ['arm'], 't': (-1.0, 0.42), 'ragged': 0.9, 'seed': 5}, (70, 10, 10)),
                       (pants, {'meshes': ['torso'], 'z': (-60, belt_z), 'seed': 6}),
                       (apron, {'meshes': ['torso'], 'x': front, 'z': (-60, J('Bip01 Spine3')[2] + 1.6 * k), 'soft': 0.3,
                                'seed': 7}, (120, 30, 20))),
        'legs': layers(sk, (pants, {'meshes': ['leg'], 't': (-1, 1.75), 'ragged': 0.8, 'holes': 0.15, 'seed': 8},
                            (25, 20, 18))),
        'boot': {'type': 'leather', 'color': (46, 34, 26), 'seed': 3207, 'blood': 0.4},
        'apron': layers(dict(apron, seed=3208), (pants, {'x': (-99, -1.0 * k), 'seed': 9})),
        'claw': {'type': 'bone', 'color': (190, 170, 140), 'tip_color': (90, 10, 10), 'tip_dark': 0.85, 'seed': 3209},
        'hook': metal((120, 116, 110), seed=3210, rust=0.75, scratches=0.7, chipping=0.0, edge_wear=0.8, blood=0.6),
        'chain': metal((96, 94, 92), seed=3211, rust=0.55, scratches=0.5),
        'belt': {'type': 'leather', 'color': (60, 36, 24), 'seed': 3212, 'blood': 0.3},
        'buckle': metal((150, 140, 110), seed=3213, rust=0.3),
        'teeth': {'type': 'bone', 'color': (200, 180, 140), 'seed': 3214},
        'eyeglow': glow((255, 60, 40), (255, 190, 160)),
    }


def butcher(quick=False):
    """12 Butcher (blood red): big-bellied bald brute in a blood-soaked butcher apron, a chained meat hook
    gripped in the right fist (chain wound round the forearm), spare hooks on the belt; heavy rolling gait."""
    rs = RigSpec(height=74.0, shoulder_w=0.27, hip_w=0.14, leg=0.46, arm=0.37, hand=0.13, head=0.135, bulk=1.4,
                 limb_thick=1.3, arm_thick=1.15)

    def acc(rig, sh):
        k = _k(rig)
        return [
            ('coat_skirt', dict(mat='apron', length=0.48, flare=0.25)),
            ('belt', dict(mat='belt', buckle_mat='buckle', pouches=0, grow=0.9)),
            (hand_hook, dict(mat='hook', chain_mat='chain', side='R', size=1.9)),
            (belt_hooks, dict(mat='hook', n=2, side='L')),
            ('chain', dict(mat='chain', points=_front_pts(rig, sh, [('Bip01 Spine3', 3.6, 2.6), ('Bip01 Spine2', 0.4, 0.6),
                                                                   ('Bip01 Spine1', -3.6, -0.2), ('Bip01 Spine', -5.4, -0.6)], 0.9),
                           bones=[_bi(rig, 'Bip01 Spine3'), _bi(rig, 'Bip01 Spine2'), _bi(rig, 'Bip01 Spine1')], link=1.1)),
            ('jaw_teeth', dict(mat='teeth', n=5, size=1.1)),
            ('glow_eyes', dict(mat='eyeglow', size=0.45)),
        ]
    return _zspec('butcher', rs,
                  dict(hunch=14.0, heavy=0.6, lurch=0.45, limp=0.1, walk_D=56.0, run_D=90.0, run_lean=10.0, stance_w=1.3,
                       arm_swing=0.9, knee_bend=0.14, aggression=1.05, claw_spread=0.8),
                  dict(muscle=0.55, belly=0.85, chest=1.15, waist=1.15, hump=0.25, claw_len=0.55, feet='shoe', neck=1.0,
                       head=dict(jaw=1.5, brow=1.5, w=1.05, sockets=1.2, ears=0.8, mouth_open=0.4, flat_top=0.2)),
                  _butcher_mats, acc,
                  dict(eye='glow', glow=(255, 70, 50), mouth='snarl', teeth=(200, 180, 140), brow_color=None, eye_size=0.7,
                       dark_sockets=0.5),
                  quick=quick)


# ============================================================================================ 13 hunter
def _hunter_mats(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['hunter']
    sk = skin((128, 122, 120), seed=3301, variation=0.16, tint2=(90, 90, 110), tint2_amount=0.5, veins=0.6,
              vein_color=(60, 50, 80), rot=0.3, rot_color=(70, 70, 60), wounds=0.4, blood=0.45, pores=0.15)
    hoodie = cloth(_dim(c, 0.85), seed=3302, weave=0.1, weave_freq=4.5, dirt=0.75, dirt_color=(40, 40, 46), stains=0.6,
                   blood=0.5, tears=0.35)
    pants = cloth((40, 42, 50), seed=3303, weave=0.08, dirt=0.85, dirt_color=(70, 60, 46), stains=0.4, blood=0.3)
    return {
        'skin': sk, 'head': dict(sk, seed=3304), 'hand': dict(sk, seed=3305, blood=0.7), 'boot': dict(sk, seed=3306),
        'body': layers(sk,
                       (hoodie, {'meshes': ['torso'], 'z': (J('Bip01 Pelvis')[2] - 0.5 * k, 60), 'ragged': 0.9, 'holes': 0.25,
                                 'seed': 4}, (30, 30, 40)),
                       (hoodie, {'meshes': ['arm'], 't': (-1.0, 0.9), 'ragged': 1.2, 'holes': 0.25, 'seed': 5}, (30, 30, 40)),
                       (pants, {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] - 0.5 * k), 'seed': 6})),
        'legs': layers(sk, (pants, {'meshes': ['leg'], 't': (-1, 1.3), 'ragged': 1.2, 'holes': 0.35, 'seed': 7}, (20, 20, 25))),
        'claw': {'type': 'bone', 'color': (70, 66, 70), 'tip_color': (230, 230, 240), 'tip_dark': 0.8, 'seed': 3307},
        'hood': dict(hoodie, seed=3308, color=_dim(c, 0.7)),
        'tatter': dict(hoodie, seed=3309, color=_dim(c, 0.6)),
        'wrap': cloth((176, 168, 146), seed=3310, weave=0.35, weave_freq=8.0, dirt=1.0, dirt_color=(90, 74, 50), blood=0.8),
        'teeth': {'type': 'bone', 'color': (210, 200, 170), 'seed': 3311},
        'eyeglow': glow((235, 235, 255), (255, 255, 255)),
    }


def hunter(quick=False):
    """13 Hunter (slate grey-blue): wiry feral pouncer in a deep hood, bandage-wrapped arms and legs; very
    low four-legged crouch with knuckles near the ground, long springy stride, white glowing eyes."""
    rs = RigSpec(height=71.0, shoulder_w=0.2, hip_w=0.11, leg=0.52, arm=0.41, hand=0.125, head=0.135, limb_thick=0.8,
                 bulk=0.82)
    return _zspec('hunter', rs,
                  dict(hunch=44.0, lurch=0.2, knee_bend=0.3, crouch_spine=6.0, crouch_tilt=26.0, walk_D=64.0, run_D=128.0,
                       run_lean=30.0, arm_swing=1.3, stance_w=1.25, claw_spread=1.35, aggression=1.45, crouch_h=0.26),
                  dict(gaunt=0.55, muscle=0.35, hump=0.35, chest=0.92, waist=0.8, claw_len=1.35,
                       head=dict(jaw=0.9, jaw_drop=0.3, sockets=1.6, cheek=1.3, nose=0.4, mouth_open=0.8, w=0.92)),
                  _hunter_mats,
                  [('hood', dict(mat='hood', depth=1.3, peak=1.4)),
                   ('wraps', dict(mat='wrap', where=(('L', 'Forearm', 0.1, 0.95), ('R', 'Forearm', 0.1, 0.95),
                                                     ('L', 'UpperArm', 0.55, 0.95), ('R', 'Calf', 0.2, 0.9),
                                                     ('L', 'Calf', 0.45, 0.95), ('R', 'Thigh', 0.3, 0.6)), grow=0.3)),
                   ('shirt_flaps', dict(mat='tatter', n=6, length=6.0, seed=31)),
                   ('jaw_teeth', dict(mat='teeth', n=6, size=0.85)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.5))],
                  dict(eye='glow', glow=(235, 235, 255), mouth='snarl', teeth=(210, 200, 170), brow_color=None,
                       eye_size=0.8, dark_sockets=0.8),
                  quick=quick)


# ============================================================================================ 14 charger
def _charger_mats(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['charger']
    sk = skin((178, 140, 108), seed=3401, variation=0.18, tint2=(150, 100, 70), tint2_amount=0.5, veins=0.7,
              vein_color=(120, 50, 40), rot=0.3, rot_color=(100, 80, 50), wounds=0.4, blood=0.45, scars=0.5)
    big = skin((190, 128, 92), seed=3402, variation=0.22, tint2=_dim(c, 0.85), tint2_amount=0.7, veins=1.0,
               vein_color=(140, 40, 40), vein_freq=0.3, wounds=0.55, blood=0.5, scars=0.8, pores=0.3)
    overall = cloth((70, 84, 104), seed=3403, weave=0.15, weave_freq=5.0, dirt=0.9, dirt_color=(80, 64, 44), stains=0.7,
                    blood=0.5, tears=0.3)
    return {
        'skin': sk, 'head': dict(sk, seed=3404), 'hand': dict(sk, seed=3405, blood=0.6), 'boot': dict(sk, seed=3406),
        'body': layers(sk,
                       (overall, {'meshes': ['torso'], 'z': (-60, J('Bip01 Spine2')[2] + 1.0 * k), 'ragged': 1.4,
                                  'holes': 0.25, 'seed': 4}, (40, 40, 50)),
                       (overall, {'meshes': ['torso'], 'z': (-60, J('Bip01 Neck')[2]), 'y': (1.6 * k, 3.4 * k), 'x': (0, 99),
                                  'soft': 0.3, 'seed': 5})),
        'legs': layers(sk, (overall, {'meshes': ['leg'], 't': (-1, 1.75), 'ragged': 0.9, 'holes': 0.3, 'seed': 6}, (40, 40, 50))),
        'bigarm': big,
        'bone': {'type': 'bone', 'color': (222, 206, 172), 'tip_color': (110, 60, 30), 'tip_dark': 0.6, 'seed': 3407},
        'shield': layers({'type': 'bone', 'color': (214, 198, 164), 'tip_dark': 0.0, 'seed': 3410},
                         (skin((150, 60, 50), seed=3411, veins=0.8, vein_color=(90, 20, 20)),
                          {'facing': (0, 0, -1), 'facing_min': 0.3, 'ragged': 0.6, 'seed': 12})),
        'claw': {'type': 'bone', 'color': (200, 180, 140), 'tip_color': (80, 30, 10), 'tip_dark': 0.8, 'seed': 3408},
        'teeth': {'type': 'bone', 'color': (210, 190, 150), 'seed': 3409},
        'eyeglow': glow((255, 150, 60), (255, 220, 170)),
    }


def charger(quick=False):
    """14 Charger (rust orange): lopsided brute whose right arm has grown into a giant club with a boulder
    fist, knuckle spurs and a bone shield over the shoulder; withered left arm, torn overalls; leaning
    shoulder-first charge."""
    rs = RigSpec(height=73.0, shoulder_w=0.25, hip_w=0.13, leg=0.47, arm=0.37, hand=0.12, head=0.132, bulk=1.2,
                 limb_thick=1.15, arm_thick=0.72)
    return _zspec('charger', rs,
                  dict(hunch=24.0, heavy=0.5, lurch=0.7, limp=0.2, walk_D=56.0, run_D=104.0, run_lean=20.0, stance_w=1.3,
                       arm_swing=0.6, knee_bend=0.16, aggression=1.2, claw_spread=0.7),
                  dict(muscle=0.7, hump=0.6, chest=1.1, waist=0.95, claw_len=0.8, neck=1.2,
                       head=dict(jaw=1.6, brow=1.6, w=1.0, sockets=1.3, mouth_open=0.6, jaw_drop=0.3)),
                  _charger_mats,
                  [(giant_arm, dict(mat='bigarm', bone_mat='bone', side='R')),
                   ('jaw_teeth', dict(mat='teeth', n=5, size=1.1)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.45))],
                  dict(eye='glow', glow=(255, 150, 60), mouth='snarl', teeth=(210, 190, 150), brow_color=None, eye_size=0.7,
                       dark_sockets=0.5),
                  quick=quick)


# ============================================================================================ 15 arachne
def _arachne_mats(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['arachne']
    sk = skin((150, 132, 160), seed=3501, variation=0.15, tint2=(110, 70, 140), tint2_amount=0.6, veins=0.9,
              vein_color=(120, 20, 160), rot=0.2, rot_color=(80, 50, 90), wounds=0.25, blood=0.25, pores=0.1)
    chitin = {'type': 'scales', 'color': (54, 22, 74), 'edge_color': (16, 6, 22), 'freq': 0.7, 'seed': 3502}
    dress = cloth((34, 24, 40), seed=3503, weave=0.08, dirt=0.5, dirt_color=(20, 10, 30), tears=0.6, stains=0.3)
    return {
        'skin': sk, 'head': dict(sk, seed=3504), 'hand': layers(dict(sk, seed=3505),
                                                                 (chitin, {'t': (0.6, 9), 'ragged': 0.5, 'seed': 3})),
        'boot': dict(chitin, seed=3506),
        'body': layers(sk,
                       (chitin, {'meshes': ['torso'], 'x': (-99, -0.5 * k), 'z': (J('Bip01 Spine')[2], 999), 'ragged': 1.8,
                                 'seed': 4}, (30, 0, 40)),
                       (chitin, {'meshes': ['arm'], 't': (0.55, 9), 'ragged': 1.2, 'seed': 5}, (30, 0, 40)),
                       (dress, {'meshes': ['torso'], 'z': (-60, J('Bip01 Spine1')[2]), 'ragged': 1.5, 'holes': 0.3, 'seed': 6},
                        (20, 0, 30))),
        'legs': layers(dict(sk, seed=3507), (dress, {'meshes': ['leg'], 't': (-1, 0.8), 'ragged': 1.5, 'holes': 0.35, 'seed': 7},
                                             (20, 0, 30)),
                       (chitin, {'meshes': ['leg'], 't': (1.0, 9), 'ragged': 0.8, 'seed': 8})),
        'chitin': chitin,
        'abdomen': layers(dict(chitin, seed=3508, color=(70, 26, 96), freq=0.45),
                          (glow(_mix(c, (255, 40, 120), 0.5), (255, 160, 220)), {'y': (-1.0 * k, 1.0 * k), 'z': (-60, 99),
                                                                                   'x': (-99, -7.0 * k), 'ragged': 0.4,
                                                                                   'seed': 9})),
        'joint': {'type': 'scales', 'color': (110, 30, 150), 'seed': 3509},
        'claw': {'type': 'bone', 'color': (40, 20, 50), 'tip_color': (200, 90, 255), 'tip_dark': 0.8, 'seed': 3510},
        'legclaw': {'type': 'horn', 'color': (30, 10, 40), 'tip_color': (180, 60, 240), 'tip_dark': 0.7, 'seed': 3511},
        'fang': {'type': 'horn', 'color': (40, 16, 46), 'tip_color': (230, 200, 240), 'tip_dark': 0.8, 'seed': 3512},
        'hair': {'type': 'hair', 'color': (24, 16, 30), 'tip': (90, 50, 120), 'seed': 3513},
        'eyeglow': glow((210, 80, 255), (255, 210, 255)),
    }


def arachne(quick=False):
    """15 Arachne (violet): spider-woman with four jointed chitin legs sprouting from the back, bulbous
    abdomen with a glowing marking, fangs and a cluster of extra violet eyes; low skittering crouch."""
    rs = RigSpec(height=70.0, shoulder_w=0.2, hip_w=0.12, leg=0.51, arm=0.38, hand=0.125, head=0.135, limb_thick=0.8,
                 bulk=0.85)
    rs.extras = limb_extras(rs, pairs=2, reach=0.95, parent='Bip01 Spine2', height=1.0, spread=1.1)
    return _zspec('arachne', rs,
                  dict(hunch=30.0, lurch=0.35, knee_bend=0.22, walk_D=60.0, run_D=108.0, run_lean=20.0, arm_swing=1.0,
                       stance_w=1.3, claw_spread=1.4, aggression=1.25, crouch_h=0.27),
                  dict(gaunt=0.45, muscle=0.15, chest=0.92, waist=0.72, hips=1.05, claw_len=1.3,
                       head=dict(jaw=0.8, sockets=1.5, cheek=1.0, nose=0.3, mouth_open=0.5, w=0.95)),
                  _arachne_mats,
                  [('extra_limbs', dict(mat='chitin', claw_mat='legclaw', radius=0.95, claw=3.0, joint_mat='joint')),
                   (abdomen, dict(mat='abdomen', size=1.0)),
                   ('hair', dict(mat='hair', volume=1.0, length=13.0, style='long')),
                   (fangs, dict(mat='fang', size=1.0)),
                   (extra_eyes, dict(mat='eyeglow', spots=((1.1, 2.2), (-1.1, 2.2), (2.0, 1.4), (-2.0, 1.4)), size=0.32)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.5))],
                  dict(eye='glow', glow=(210, 80, 255), mouth='open', teeth=(200, 180, 210), brow_color=None, eye_size=0.8,
                       dark_sockets=0.6),
                  quick=quick)


# ============================================================================================ 16 magma
def _magma_mats(rig, sh):
    J = rig.J
    k = _k(rig)
    lava = {'type': 'lava', 'color': (38, 30, 28), 'hot': (255, 96, 8), 'core': (255, 214, 90), 'freq': 0.3,
            'crack_width': 0.085, 'seed': 3601}
    crust = {'type': 'lava', 'color': (26, 22, 22), 'hot': (230, 70, 0), 'core': (255, 180, 60), 'freq': 0.5,
             'crack_width': 0.05, 'seed': 3602}
    char = cloth((30, 26, 24), seed=3603, weave=0.1, dirt=0.6, dirt_color=(70, 30, 10), stains=0.3)
    return {
        'skin': lava, 'head': dict(lava, seed=3604, crack_width=0.07), 'hand': dict(lava, seed=3605),
        'boot': dict(crust, seed=3606),
        'body': layers(lava, (char, {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] + 0.8 * k), 'ragged': 1.6,
                                     'holes': 0.45, 'hole_size': 0.4, 'seed': 4}, (255, 90, 0))),
        'legs': layers(lava, (char, {'meshes': ['leg'], 't': (-1, 0.9), 'ragged': 1.6, 'holes': 0.5, 'hole_size': 0.4,
                                     'seed': 5}, (255, 90, 0))),
        'crust': crust,
        'claw': {'type': 'bone', 'color': (30, 26, 24), 'tip_color': (255, 140, 20), 'tip_dark': 0.95, 'seed': 3607},
        'teeth': {'type': 'bone', 'color': (60, 50, 40), 'tip_color': (255, 160, 40), 'seed': 3608},
        'eyeglow': glow((255, 200, 40), (255, 250, 200)),
    }


def magma(quick=False):
    """16 Magma (lava orange): body of black volcanic crust split by glowing lava cracks, crust slabs on
    shoulders/chest/thighs, smoking spines on the back, charred rags; heavy deliberate walk."""
    rs = RigSpec(height=73.0, shoulder_w=0.25, hip_w=0.13, leg=0.48, arm=0.37, hand=0.125, head=0.13, bulk=1.2,
                 limb_thick=1.15)

    def acc(rig, sh):
        J = rig.J
        k = _k(rig)

        def at(bone, off):
            return tuple((J(bone) + np.array(off) * k) / k)
        return [
            ('shoulder_pads', dict(mat='crust', size=1.3, spikes=2, spike_mat='crust')),
            ('plates_on', dict(mat='crust', items=[
                ('Bip01 Spine2', at('Bip01 Spine2', (6.0, 2.6, 1.0)), (1.2, 3.6, 3.2), (6, -10, 8)),
                ('Bip01 Spine1', at('Bip01 Spine1', (6.0, -2.4, -0.5)), (1.2, 3.0, 2.8), (-8, -6, -6)),
                ('Bip01 L Thigh', at('Bip01 L Thigh', (3.8, 0.8, -6.5)), (1.0, 3.4, 4.2), (0, -8, 10)),
                ('Bip01 R Forearm', at('Bip01 R Forearm', (0.0, -2.2, -4.0)), (3.0, 1.0, 3.6), (0, 0, 8))])),
            ('spikes', dict(mat='crust', n=6, length=4.2, radius=1.0, seed=61)),
            ('jaw_teeth', dict(mat='teeth', n=5, size=1.0)),
            ('glow_eyes', dict(mat='eyeglow', size=0.55)),
        ]
    return _zspec('magma', rs,
                  dict(hunch=16.0, heavy=0.45, lurch=0.4, walk_D=58.0, run_D=96.0, run_lean=12.0, stance_w=1.2, arm_swing=0.9,
                       knee_bend=0.15, aggression=1.1, claw_spread=1.0),
                  dict(muscle=0.7, hump=0.35, chest=1.1, waist=0.95, claw_len=0.9,
                       head=dict(jaw=1.3, brow=1.6, sockets=1.4, mouth_open=0.6, jaw_drop=0.3, ears=0.3)),
                  _magma_mats, acc,
                  dict(eye='glow', glow=(255, 200, 40), mouth='open', teeth=(255, 170, 60), lips=(255, 120, 20),
                       brow_color=None, eye_size=0.8, brow_shadow=0.0, cheek_amount=0.0),
                  quick=quick)


# ============================================================================================ 17 volt
def _volt_mats(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['volt']
    sk = skin((150, 156, 170), seed=3701, variation=0.12, tint2=(110, 120, 150), tint2_amount=0.5, veins=1.0,
              vein_color=(40, 170, 255), vein_freq=0.26, vein_sharp=18.0, rot=0.18, rot_color=(80, 90, 100),
              wounds=0.3, blood=0.25, scars=0.6)
    jump = cloth((54, 60, 72), seed=3702, weave=0.12, weave_freq=5.0, dirt=0.7, dirt_color=(40, 40, 40), stains=0.5,
                 blood=0.3, tears=0.3,
                 stripes=[dict(normal=(0, 0, 1), offset=J('Bip01 Spine2')[2], width=0.8 * k, color=(230, 200, 30))])
    return {
        'skin': sk, 'head': dict(sk, seed=3703), 'hand': dict(sk, seed=3704),
        'boot': {'type': 'rubber', 'color': (36, 36, 40), 'seed': 3705},
        'body': layers(sk,
                       (jump, {'meshes': ['torso'], 'z': (-60, J('Bip01 Spine3')[2] + 1.5 * k), 'ragged': 1.2, 'holes': 0.3,
                               'seed': 4}, (20, 20, 30)),
                       (jump, {'meshes': ['arm'], 't': (-1.0, 0.5), 'ragged': 1.2, 'seed': 5}, (20, 20, 30))),
        'legs': layers(sk, (jump, {'meshes': ['leg'], 't': (-1, 1.7), 'ragged': 1.0, 'holes': 0.25, 'seed': 6}, (20, 20, 30))),
        'battery': metal((206, 172, 30), seed=3706, chipping=0.5, edge_wear=0.9, scratches=0.6, panels=1),
        'cell': metal(_dim(c, 0.62), seed=3707, chipping=0.35, scratches=0.5),
        'arc': glow(c, (225, 245, 255), freq=1.2),
        'cable': {'type': 'rubber', 'color': (30, 30, 34), 'seed': 3708},
        'claw': {'type': 'bone', 'color': (70, 80, 96), 'tip_color': (120, 220, 255), 'tip_dark': 0.8, 'seed': 3709},
        'teeth': {'type': 'bone', 'color': (200, 200, 190), 'seed': 3710},
        'eyeglow': glow((120, 210, 255), (240, 250, 255)),
    }


def _volt_decals(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['volt']
    D = []
    # glowing electric scars: bands around arms/legs and burn spots where the cables enter the chest
    for side in ('L', 'R'):
        for a, b, fr in (('UpperArm', 'Forearm', 0.35), ('Forearm', 'Hand', 0.55), ('Thigh', 'Calf', 0.5)):
            p0 = J('Bip01 %s %s' % (side, a)); p1 = J('Bip01 %s %s' % (side, b))
            p = p0 + (p1 - p0) * fr
            d = _unit(p1 - p0)
            D.append(dict(kind='band', normal=tuple(d), offset=float(np.dot(p, d)), width=0.45 * k, soft=0.35, color=c,
                          mode='glow', region=(tuple(p - 4.5 * k), tuple(p + 4.5 * k)), target=['body', 'legs']))
    for sg in (1, -1):
        D.append(dict(kind='sphere', center=J('Bip01 Spine3') + np.array([4.6, sg * 2.6, -1.0]) * k, radius=1.4 * k,
                      soft=0.5, color=(200, 240, 255), color2=c, mode='glow', target=['body', 'torso']))
    D.append(dict(kind='shape', shape='chevron', center=J('Bip01 Spine2') + np.array([6.0, 0, 0.5]) * k, u=(0, -1, 0),
                  v=(0, 0, 1), size=1.6 * k, soft=0.25, color=c, mode='glow', depth=3.0, target=['body', 'torso']))
    return D


def volt(quick=False):
    """17 Volt (electric blue): wiry zombie in a torn utility jumpsuit with a yellow-black battery pack on
    the back (two charged cells with glowing rings, electrode rods), cables over the shoulders into the
    chest, glowing blue veins and burn bands; twitchy jerky gait."""
    rs = RigSpec(height=72.0, shoulder_w=0.22, hip_w=0.115, leg=0.51, arm=0.37, hand=0.12, head=0.135, limb_thick=0.88,
                 bulk=0.92)
    return _zspec('volt', rs,
                  dict(hunch=18.0, lurch=0.85, limp=0.15, walk_D=62.0, run_D=104.0, run_lean=16.0, arm_swing=1.2,
                       knee_bend=0.16, stance_w=1.05, claw_spread=1.5, aggression=1.3),
                  dict(gaunt=0.4, muscle=0.25, chest=0.95, waist=0.85, claw_len=1.0, feet='shoe',
                       head=dict(jaw=1.0, sockets=1.5, mouth_open=0.7, jaw_drop=0.35, cheek=1.2)),
                  _volt_mats,
                  [(battery_pack, dict()),
                   ('hair', dict(mat='cable', volume=0.3)),
                   ('jaw_teeth', dict(mat='teeth', n=6, size=0.9)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.55))],
                  dict(eye='glow', glow=(120, 210, 255), mouth='snarl', teeth=(200, 200, 190), brow_color=None, eye_size=0.85,
                       dark_sockets=0.4),
                  decals=_volt_decals, quick=quick)


# ============================================================================================ 18 mimic
def _mimic_mats(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['mimic']
    flesh = skin((164, 70, 74), seed=3801, variation=0.25, tint2=(110, 30, 44), tint2_amount=0.7, veins=1.0,
                 vein_color=(80, 10, 20), vein_freq=0.3, wounds=0.6, blood=0.6, pores=0.4, rot=0.2, rot_color=(120, 80, 60))
    man = skin((176, 150, 130), seed=3802, variation=0.1, veins=0.3, vein_color=(120, 90, 110), wounds=0.15, blood=0.2,
               pores=0.1)
    camo = cloth(c, seed=3803, weave=0.1, weave_freq=5.0, camo=[(110, 112, 116), (70, 72, 78), (190, 190, 192)],
                 dirt=0.4, dirt_color=(70, 60, 50), stains=0.3, blood=0.4)
    # left half (+Y) = soldier, right half = flesh
    half = {'y': (0.3 * k, 99), 'ragged': 1.6, 'ragged_freq': 0.45, 'soft': 0.5}
    return {
        'skin': layers(flesh, (man, dict(half, seed=4)), ),
        'head': layers(dict(flesh, seed=3804), (man, dict(half, seed=5), (90, 20, 30))),
        'hand': layers(dict(flesh, seed=3805), ({'type': 'leather', 'color': (40, 42, 44), 'seed': 3806}, dict(half, seed=6),
                                                (90, 20, 30))),
        'boot': layers(dict(flesh, seed=3807), ({'type': 'leather', 'color': (34, 32, 30), 'seed': 3808}, dict(half, seed=7),
                                                (90, 20, 30))),
        'body': layers(flesh, (camo, dict(half, seed=8), (90, 20, 30))),
        'legs': layers(dict(flesh, seed=3809), (camo, dict(half, seed=9), (90, 20, 30))),
        'vest': layers(dict(flesh, seed=3810),
                       (metal((70, 74, 80), seed=3811, chipping=0.3, edge_wear=0.7, scratches=0.5), dict(half, seed=10),
                        (90, 20, 30))),
        'helmet': layers(dict(flesh, seed=3812),
                         (metal((92, 96, 100), seed=3813, chipping=0.4, edge_wear=0.8, scratches=0.5), dict(half, seed=11),
                          (90, 20, 30))),
        'patch': cloth((30, 34, 40), seed=3814, weave=0.2, dirt=0.2),
        'flesh': dict(flesh, seed=3815, color=(176, 60, 66)),
        'pouch': cloth((84, 86, 90), seed=3816, weave=0.2, dirt=0.4),
        'claw': {'type': 'bone', 'color': (220, 200, 190), 'tip_color': (120, 10, 20), 'tip_dark': 0.85, 'seed': 3817},
        'teeth': {'type': 'bone', 'color': (225, 215, 190), 'seed': 3818},
        'eyeglow': glow((255, 60, 60), (255, 200, 190)),
    }


def _mimic_decals(rig, sh):
    J = rig.J
    k = _k(rig)
    # a Vexmira squad emblem on the soldier half (the stolen uniform)
    return [dict(kind='shape', shape='vex', center=J('Bip01 Spine3') + np.array([5.6, 3.2, -0.5]) * k, u=(0, -1, 0),
                 v=(0, 0, 1), size=1.3 * k, soft=0.2, color=VEX_CYAN, mode='glow', depth=2.0, target=['body', 'torso'])]


def mimic(quick=False):
    """18 Mimic (grey): a Vexmira soldier half eaten by a flesh mass - left side camo uniform, vest and
    helmet, right side raw red muscle with bulging growths, extra glowing eyes and bone spurs; walks
    almost like a human (the disguise)."""
    rs = RigSpec(height=72.0, shoulder_w=0.23, hip_w=0.12, leg=0.5, arm=0.36, hand=0.12, head=0.14, limb_thick=1.0,
                 bulk=1.0)

    def acc(rig, sh):
        J = rig.J
        k = _k(rig)
        return [
            ('helmet', dict(mat='helmet', size=1.0, rails=False, mount=False)),
            ('vest', dict(mat='vest', pouches=False, collar=False, plates=False, grow=0.8)),
            ('plates_on', dict(mat='pouch', items=[
                ('Bip01 Spine1', tuple((J('Bip01 Spine1') + np.array([5.4, 3.2, 0.0]) * k) / k), (1.6, 2.0, 3.0), (0, 0, 0)),
                ('Bip01 Spine1', tuple((J('Bip01 Spine1') + np.array([5.0, 5.4, 0.0]) * k) / k), (1.6, 2.0, 3.0), (0, 0, -20))])),
            ('emblem_patch', dict(mat='patch', where='arm_L')),
            (lumps, dict(mat='flesh', seed=81, where=(
                ('Bip01 R UpperArm', (0.5, -2.2, -2.0), 2.2, 4, (1.2, 0.8, 2.2)),
                ('Bip01 R Forearm', (0.4, -1.6, -3.5), 1.8, 3, (1.0, 0.6, 2.0)),
                ('Bip01 Spine3', (2.5, -4.4, 0.5), 2.4, 4, (1.8, 1.2, 2.0)),
                ('Bip01 Spine1', (3.4, -4.0, 0.0), 2.0, 3, (1.5, 1.0, 1.5)),
                ('Bip01 Head', (0.6, -2.6, 1.8), 1.6, 3, (1.2, 0.5, 1.2)),
                ('Bip01 R Thigh', (1.6, -1.5, -6.0), 1.8, 3, (1.2, 0.8, 3.0))))),
            ('spikes', dict(mat='claw', n=3, length=3.6, radius=0.75, seed=82)),
            (body_eyes, dict(mat='eyeglow', size=0.45, where=(('Bip01 Spine3', (4.6, -4.4, 1.6)),
                                                              ('Bip01 R UpperArm', (1.8, -2.4, -4.2)),
                                                              ('Bip01 Spine1', (5.4, -4.8, 1.2))))),
            ('jaw_teeth', dict(mat='teeth', n=6, size=1.0)),
        ]
    return _zspec('mimic', rs,
                  dict(hunch=10.0, lurch=0.5, limp=0.35, walk_D=62.0, run_D=100.0, run_lean=12.0, arm_swing=1.0,
                       knee_bend=0.12, stance_w=1.0, claw_spread=1.1, aggression=1.0),
                  dict(muscle=0.45, chest=1.0, waist=0.95, claw_len=0.9, feet='boot',
                       head=dict(jaw=1.1, sockets=1.2, mouth_open=0.7, jaw_drop=0.3)),
                  _mimic_mats, acc,
                  dict(eye='glow', glow=(255, 70, 60), mouth='snarl', teeth=(225, 215, 190), brow_color=(60, 50, 40),
                       eye_size=0.8),
                  decals=_mimic_decals, quick=quick)


# ============================================================================================ 19 burrower
def _burrower_mats(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['burrower']
    sk = skin((140, 120, 100), seed=3901, variation=0.2, tint2=(110, 84, 56), tint2_amount=0.7, veins=0.4,
              vein_color=(80, 50, 40), rot=0.3, rot_color=(90, 70, 46), wounds=0.3, blood=0.3, pores=0.35)
    dirt = cloth(_dim(c, 0.72), seed=3902, weave=0.0, dirt=1.0, dirt_color=(70, 50, 28), stains=0.9)
    overall = cloth((156, 112, 52), seed=3903, weave=0.15, weave_freq=5.0, dirt=1.0, dirt_color=(80, 58, 32), stains=0.8,
                    blood=0.3, tears=0.3,
                    stripes=[dict(normal=(0, 0, 1), offset=J('Bip01 Spine1')[2], width=0.7 * k, color=(200, 190, 90))])
    grime = {'z': (-60, 99), 'ragged': 2.2, 'ragged_freq': 0.25, 'holes': 0.6, 'hole_size': 0.4, 'hole_freq': 0.1}
    return {
        'skin': layers(sk, (dirt, dict(grime, seed=4))), 'head': layers(dict(sk, seed=3904), (dirt, dict(grime, seed=5))),
        'hand': layers(dict(sk, seed=3905), (dirt, {'t': (0.3, 9), 'ragged': 1.0, 'seed': 6})),
        'boot': layers({'type': 'leather', 'color': (60, 44, 30), 'seed': 3906}, (dirt, dict(grime, seed=7))),
        'body': layers(sk,
                       (overall, {'meshes': ['torso'], 'z': (-60, J('Bip01 Spine3')[2] + 1.0 * k), 'ragged': 1.0, 'holes': 0.25,
                                  'seed': 8}, (60, 40, 20)),
                       (overall, {'meshes': ['arm'], 't': (-1, 0.4), 'ragged': 1.0, 'seed': 9}, (60, 40, 20)),
                       (dirt, dict(grime, seed=10, holes=0.7))),
        'legs': layers(sk, (overall, {'meshes': ['leg'], 't': (-1, 1.6), 'ragged': 0.8, 'holes': 0.2, 'seed': 11}, (60, 40, 20)),
                       (dirt, {'t': (0.6, 9), 'ragged': 1.5, 'seed': 12})),
        'helmet': metal((196, 160, 40), seed=3907, chipping=0.6, edge_wear=0.9, scratches=0.8, rust=0.3),
        'lamp': metal((70, 66, 60), seed=3908, rust=0.4, scratches=0.6),
        'glass': {'type': 'crystal', 'color': (110, 90, 40), 'color2': (230, 210, 140), 'freq': 0.9, 'seed': 3909},
        'clod': {'type': 'scales', 'color': (98, 72, 42), 'edge_color': (40, 28, 16), 'freq': 1.1, 'seed': 3910},
        'digclaw': {'type': 'horn', 'color': (60, 52, 44), 'tip_color': (190, 170, 130), 'tip_dark': -0.6, 'seed': 3911},
        'claw': {'type': 'bone', 'color': (80, 66, 50), 'tip_color': (30, 20, 10), 'tip_dark': 0.8, 'seed': 3912},
        'teeth': {'type': 'bone', 'color': (190, 170, 120), 'seed': 3913},
        'eyeglow': glow((255, 190, 90), (255, 240, 200)),
    }


def burrower(quick=False):
    """19 Burrower (earth brown): dirt-caked miner in grimy overalls and a dented hard hat with a broken
    lamp, huge shovel claws, clods of earth on the shoulders and back; low digging hunch, wide stance."""
    rs = RigSpec(height=70.0, shoulder_w=0.25, hip_w=0.13, leg=0.47, arm=0.38, hand=0.15, head=0.13, bulk=1.15,
                 limb_thick=1.1, arm_thick=1.15)
    return _zspec('burrower', rs,
                  dict(hunch=30.0, lurch=0.45, limp=0.1, walk_D=56.0, run_D=96.0, run_lean=20.0, stance_w=1.35,
                       arm_swing=1.1, knee_bend=0.22, aggression=1.1, claw_spread=1.2, crouch_h=0.27),
                  dict(muscle=0.6, hump=0.55, chest=1.05, waist=0.95, claw_len=0.6, feet='boot', forearm=1.2,
                       head=dict(jaw=1.2, brow=1.4, sockets=1.6, mouth_open=0.6, jaw_drop=0.3, nose=0.8)),
                  _burrower_mats,
                  [('helmet', dict(mat='helmet', size=1.05, brim=0.7, rails=False, mount=False, style='full')),
                   (miner_lamp, dict(mat='lamp', glass='glass')),
                   (dig_claws, dict(mat='digclaw', n=3, length=4.4, radius=1.0)),
                   (lumps, dict(mat='clod', seed=91, flat=0.7, where=(
                       ('Bip01 L Clavicle', (-0.5, 2.5, 1.6), 1.5, 3, (1.2, 1.0, 0.4)),
                       ('Bip01 Spine2', (-5.6, 1.0, 2.0), 1.8, 4, (0.6, 3.0, 2.5)),
                       ('Bip01 R UpperArm', (-0.5, -1.5, -1.0), 1.3, 2, (0.8, 0.5, 1.5))))),
                   ('jaw_teeth', dict(mat='teeth', n=5, size=1.0)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.4))],
                  dict(eye='glow', glow=(255, 190, 90), mouth='snarl', teeth=(190, 170, 120), brow_color=None, eye_size=0.65,
                       dark_sockets=0.7),
                  quick=quick)


# ============================================================================================ 20 siren
def _siren_mats(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['siren']
    pale = skin((210, 186, 200), seed=4001, variation=0.1, tint2=(200, 150, 190), tint2_amount=0.5, veins=0.7,
                vein_color=(200, 70, 170), rot=0.1, rot_color=(170, 130, 160), wounds=0.15, blood=0.2, pores=0.05)
    dress = cloth(_dim(c, 0.6), seed=4002, weave=0.06, weave_freq=3.0, dirt=0.4, dirt_color=(70, 30, 60), tears=0.5,
                  stains=0.3, blood=0.3)
    return {
        'skin': pale, 'head': dict(pale, seed=4003), 'hand': dict(pale, seed=4004), 'boot': dict(pale, seed=4005),
        'body': layers(pale, (dress, {'meshes': ['torso'], 'z': (-60, J('Bip01 Spine3')[2] + 0.8 * k), 'ragged': 1.4,
                                      'holes': 0.25, 'seed': 4}, (120, 30, 90))),
        'legs': layers(pale, (dress, {'meshes': ['leg'], 't': (-1, 1.0), 'ragged': 1.5, 'holes': 0.3, 'seed': 5}, (120, 30, 90))),
        'dress': dict(dress, seed=4006),
        'veil': dict(dress, seed=4007, color=_dim(c, 0.8), tears=0.7),
        'claw': {'type': 'bone', 'color': (240, 200, 230), 'tip_color': (220, 30, 160), 'tip_dark': 0.8, 'seed': 4008},
        'hair': {'type': 'hair', 'color': (255, 104, 200), 'tip': (255, 200, 240), 'seed': 4009},
        'pearl': {'type': 'crystal', 'color': (255, 160, 230), 'color2': (255, 240, 255), 'seed': 4010},
        'teeth': {'type': 'bone', 'color': (230, 220, 230), 'seed': 4011},
        'eyeglow': glow((255, 120, 220), (255, 240, 255)),
    }


def _siren_decals(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['siren']
    # glowing throat (the lullaby) + sound rings on the chest
    D = [dict(kind='sphere', center=(J('Bip01 Neck') + J('Bip01 Head')) / 2 + np.array([2.0, 0, -1.0]) * k, radius=1.6 * k,
              scale=(1.0, 1.3, 1.0), soft=0.5, color=(255, 200, 245), color2=c, mode='glow', target=['skin', 'neck', 'head'])]
    D.append(dict(kind='shape', shape='ring', center=J('Bip01 Spine3') + np.array([4.6, 0, 0.6]) * k, u=(0, -1, 0),
                  v=(0, 0, 1), size=1.6 * k, soft=0.25, color=c, mode='glow', depth=3.0, target=['body', 'torso']))
    return D


def siren(quick=False):
    """20 Siren (pink): slender pale singer with very long glowing-pink hair, glowing pink eyes and throat,
    torn flowing dress and a crystal pearl necklace; upright gliding walk, mouth open in song."""
    rs = RigSpec(height=70.0, shoulder_w=0.18, hip_w=0.12, leg=0.53, arm=0.37, hand=0.12, head=0.14, limb_thick=0.72,
                 bulk=0.76)

    def acc(rig, sh):
        k = _k(rig)
        J = rig.J
        pts = [J('Bip01 L Clavicle') + np.array([0.6, 1.0, 1.0]) * k,
               J('Bip01 Spine3') + np.array([4.2, 1.2, -0.6]) * k,
               J('Bip01 Spine3') + np.array([4.2, -1.2, -0.6]) * k,
               J('Bip01 R Clavicle') + np.array([0.6, -1.0, 1.0]) * k]
        return [
            ('hair', dict(mat='hair', volume=1.25, length=20.0, style='long')),
            ('coat_skirt', dict(mat='dress', length=0.92, flare=0.6)),
            ('shirt_flaps', dict(mat='veil', n=5, length=6.0, seed=201)),
            ('chain', dict(mat='pearl', points=pts, bones=[_bi(rig, 'Bip01 Spine3')] * 3, link=0.9)),
            ('jaw_teeth', dict(mat='teeth', n=4, size=0.7)),
            ('glow_eyes', dict(mat='eyeglow', size=0.7)),
        ]
    return _zspec('siren', rs,
                  dict(hunch=5.0, lurch=0.2, walk_D=54.0, run_D=94.0, run_lean=8.0, arm_swing=0.5, knee_bend=0.08,
                       stance_w=0.75, claw_spread=1.5, aggression=1.0),
                  dict(gaunt=0.35, muscle=0.0, chest=0.92, waist=0.7, hips=1.1, pecs=0.3, claw_len=1.3,
                       head=dict(jaw=0.75, chin=1.1, sockets=1.3, cheek=0.8, nose=0.6, mouth_open=1.0, jaw_drop=0.5, w=0.9)),
                  _siren_mats, acc,
                  dict(eye='glow', glow=(255, 130, 225), mouth='open', teeth=(230, 220, 230), lips=(170, 60, 120),
                       brow_color=None, eye_size=1.05, dark_sockets=0.4),
                  decals=_siren_decals, quick=quick)


# ============================================================================================ 21 bulwark
def _bulwark_mats(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['bulwark']
    sk = skin((122, 132, 118), seed=4101, variation=0.18, tint2=(90, 110, 90), tint2_amount=0.6, veins=0.5,
              vein_color=(60, 80, 60), scars=0.8, wounds=0.3, blood=0.25, pores=0.3, rot=0.2, rot_color=(80, 90, 70))
    stone = {'type': 'scales', 'color': (118, 126, 114), 'edge_color': (40, 46, 40), 'freq': 0.3, 'seed': 4102}
    moss = skin((70, 110, 50), seed=4103, variation=0.35, pores=0.6)
    rock = layers(stone, (moss, {'facing': (0, 0, 1), 'facing_min': 0.35, 'ragged': 1.2, 'seed': 4}))
    rags = cloth((70, 70, 60), seed=4104, weave=0.1, dirt=0.9, dirt_color=(60, 60, 44), stains=0.6, tears=0.4)
    return {
        'skin': sk, 'head': dict(sk, seed=4105), 'hand': dict(sk, seed=4106), 'boot': dict(stone, seed=4107),
        'body': layers(sk, (rags, {'meshes': ['torso'], 'z': (-60, J('Bip01 Pelvis')[2] + 1.0 * k), 'ragged': 1.2,
                                   'holes': 0.3, 'seed': 5}, (30, 30, 24)),
                       (stone, {'meshes': ['arm'], 't': (0.15, 0.4), 'ragged': 1.0, 'seed': 6})),
        'legs': layers(sk, (rags, {'meshes': ['leg'], 't': (-1, 0.9), 'ragged': 1.4, 'holes': 0.3, 'seed': 7}, (30, 30, 24)),
                       (stone, {'meshes': ['leg'], 't': (1.2, 9), 'ragged': 1.0, 'seed': 8})),
        'rock': rock,
        'shard': dict(stone, seed=4108, color=(140, 150, 136), freq=0.6),
        'claw': {'type': 'bone', 'color': (110, 116, 104), 'tip_color': (40, 44, 40), 'tip_dark': 0.8, 'seed': 4109},
        'teeth': {'type': 'bone', 'color': (180, 180, 160), 'seed': 4110},
        'eyeglow': glow((170, 255, 150), (235, 255, 230)),
    }


def bulwark(quick=False):
    """21 Bulwark (stone grey-green): massive slow brute armoured in mossy rock slabs - rock carapace on
    chest and back, boulder pauldrons, stone bracers / knee and shin slabs, a stone brow plate and rock
    shards on the back; ponderous wide-stance walk."""
    rs = RigSpec(height=75.0, shoulder_w=0.3, hip_w=0.145, leg=0.45, arm=0.36, hand=0.13, head=0.115, bulk=1.5,
                 limb_thick=1.45, arm_thick=1.1)

    def acc(rig, sh):
        J = rig.J
        k = _k(rig)

        def at(bone, off):
            return tuple((J(bone) + np.array(off) * k) / k)
        fa = face_anchor(rig, sh)
        return [
            (_shell, dict(mat='rock', name='carapace', z0=J('Bip01 Spine1')[2] - 0.5 * k, z1=J('Bip01 Spine3')[2] + 2.8 * k,
                  grow=1.1, front=1.0, back=1.15, segs=12, rings=5)),
            ('shoulder_pads', dict(mat='rock', size=1.75, spikes=0)),
            ('bracers', dict(mat='rock', grow=1.0)),
            ('knee_pads', dict(mat='rock')),
            ('plates_on', dict(mat='rock', items=[
                ('Bip01 Head', tuple((fa['brow'] + np.array([-0.2, 0, 1.2]) * k) / k), (2.0, 5.6, 1.8), (0, -18, 0)),
                ('Bip01 L Calf', at('Bip01 L Calf', (2.6, 0.4, -6.0)), (1.4, 3.0, 6.0), (0, -6, 6)),
                ('Bip01 R Calf', at('Bip01 R Calf', (2.6, -0.4, -6.0)), (1.4, 3.0, 6.0), (0, -6, -6)),
                ('Bip01 L Thigh', at('Bip01 L Thigh', (3.8, 1.2, -5.0)), (1.4, 3.6, 4.6), (0, -8, 10)),
                ('Bip01 R Thigh', at('Bip01 R Thigh', (3.8, -1.2, -7.0)), (1.4, 3.6, 4.6), (0, -8, -10)),
                ('Bip01 Pelvis', at('Bip01 Pelvis', (-4.6, 0.0, 0.5)), (1.6, 7.0, 3.4), (0, 10, 0))])),
            ('crystals', dict(mat='shard', where=(('Bip01 Spine3', (-6.5, 2.6, 2.6)), ('Bip01 Spine3', (-6.5, -2.6, 1.6)),
                                                  ('Bip01 Spine2', (-6.8, 0.0, -0.5))), size=1.25, seed=211)),
            ('jaw_teeth', dict(mat='teeth', n=4, size=1.2)),
            ('glow_eyes', dict(mat='eyeglow', size=0.5)),
        ]
    return _zspec('bulwark', rs,
                  dict(hunch=12.0, heavy=0.8, lurch=0.3, walk_D=52.0, run_D=82.0, run_lean=8.0, stance_w=1.45, arm_swing=0.5,
                       knee_bend=0.14, aggression=0.75, claw_spread=0.7),
                  dict(muscle=0.9, hump=0.4, chest=1.2, waist=1.1, belly=0.1, claw_len=0.55, neck=1.25,
                       head=dict(jaw=1.7, brow=1.8, w=1.1, sockets=1.2, ears=0.4, mouth_open=0.3, flat_top=0.5)),
                  _bulwark_mats, acc,
                  dict(eye='glow', glow=(170, 255, 150), mouth='snarl', teeth=(180, 180, 160), brow_color=None, eye_size=0.7,
                       dark_sockets=0.6),
                  quick=quick)


# ============================================================================================ 22 sporemother
def _spore_mats(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['sporemother']
    sk = skin((126, 112, 80), seed=4201, variation=0.22, tint2=(90, 120, 50), tint2_amount=0.7, veins=0.8,
              vein_color=(80, 140, 30), rot=0.55, rot_color=(110, 90, 50), rot_color2=(60, 80, 30), wounds=0.3, blood=0.2,
              pores=0.4)
    rags = cloth((86, 70, 46), seed=4202, weave=0.1, weave_freq=3.0, dirt=0.9, dirt_color=(60, 70, 30), stains=0.8,
                 tears=0.5)
    sac = skin((176, 210, 96), seed=4203, variation=0.25, veins=1.0, vein_color=(90, 130, 20), vein_freq=0.4, pores=0.5)
    return {
        'skin': sk, 'head': dict(sk, seed=4204), 'hand': dict(sk, seed=4205), 'boot': dict(sk, seed=4206),
        'body': layers(sk, (rags, {'meshes': ['torso'], 'z': (-60, J('Bip01 Spine2')[2]), 'ragged': 1.8, 'holes': 0.35,
                                   'seed': 4}, (40, 40, 20))),
        'legs': layers(sk, (rags, {'meshes': ['leg'], 't': (-1, 1.2), 'ragged': 1.6, 'holes': 0.4, 'seed': 5}, (40, 40, 20))),
        'dress': dict(rags, seed=4207),
        'sac': sac,
        'cap': layers({'type': 'skin', 'color': (120, 80, 44), 'variation': 0.3, 'rot': 0.6, 'rot_color': (200, 190, 140),
                       'rot_color2': (160, 150, 90), 'rot_freq': 0.5, 'seed': 4208},
                      (glow(c, (220, 255, 160)), {'facing': (0, 0, -1), 'facing_min': 0.2, 'seed': 6})),
        'stem': skin((200, 190, 150), seed=4209, variation=0.2, pores=0.3),
        'claw': {'type': 'bone', 'color': (150, 130, 90), 'tip_color': (60, 90, 20), 'tip_dark': 0.8, 'seed': 4210},
        'teeth': {'type': 'bone', 'color': (190, 180, 130), 'seed': 4211},
        'eyeglow': glow((170, 255, 80), (240, 255, 200)),
    }


def _spore_decals(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['sporemother']
    rng = np.random.default_rng(221)
    D = []
    # glowing spore pores on the sacs (target the sac material)
    for bone, off in (('Bip01 Spine2', (-6.0, 2.5, 1.0)), ('Bip01 Spine2', (-6.0, -2.5, 0.0)), ('Bip01 Spine', (-5.5, 0, 0.5)),
                      ('Bip01 L Clavicle', (0.0, 2.8, 2.6)), ('Bip01 R Clavicle', (0.0, -2.8, 2.6)), ('Bip01 Pelvis', (3.0, 5.0, -1.0))):
        for i in range(3):
            p = J(bone) + (np.array(off) + rng.uniform(-1.5, 1.5, 3)) * k
            D.append(dict(kind='sphere', center=p, radius=1.0 * k, soft=0.5, color=(220, 255, 120), color2=c, mode='glow',
                          target='sac'))
    return D


def sporemother(quick=False):
    """22 Sporemother (fungal green): bloated mother-zombie overgrown with veined yellow-green spore sacs on
    the back, shoulders and hips, brown mushroom caps with glowing gills on head and shoulders, rotten
    rag dress; slow swaying waddle."""
    rs = RigSpec(height=71.0, shoulder_w=0.22, hip_w=0.135, leg=0.48, arm=0.36, hand=0.12, head=0.135, bulk=1.2,
                 limb_thick=1.05)
    return _zspec('sporemother', rs,
                  dict(hunch=20.0, heavy=0.35, lurch=0.75, limp=0.15, walk_D=52.0, run_D=88.0, run_lean=10.0, stance_w=1.3,
                       arm_swing=0.8, knee_bend=0.14, aggression=0.85, claw_spread=1.1),
                  dict(gaunt=0.1, muscle=0.1, belly=0.9, chest=1.05, waist=1.1, hips=1.25, hump=0.5, claw_len=0.9,
                       head=dict(jaw=0.9, sockets=1.5, mouth_open=0.6, jaw_drop=0.3, nose=0.4)),
                  _spore_mats,
                  [('coat_skirt', dict(mat='dress', length=0.62, flare=0.45)),
                   (lumps, dict(mat='sac', seed=221, flat=0.85, where=(
                       ('Bip01 Spine2', (-6.0, 2.5, 1.0), 2.6, 3, (1.0, 1.2, 1.5)),
                       ('Bip01 Spine2', (-6.0, -2.5, 0.0), 2.4, 3, (1.0, 1.2, 1.5)),
                       ('Bip01 Spine', (-5.5, 0.0, 0.5), 2.2, 2, (0.8, 2.0, 1.0)),
                       ('Bip01 Spine3', (-3.0, 4.0, 2.6), 1.8, 2, (1.0, 0.8, 0.8)),
                       ('Bip01 Spine3', (-3.0, -4.0, 2.6), 1.8, 2, (1.0, 0.8, 0.8)),
                       ('Bip01 Pelvis', (3.0, 5.0, -1.0), 1.6, 2, (1.0, 0.6, 1.0))))),
                   (mushrooms, dict(cap='cap', stem='stem', where=(
                       ('Bip01 Head', (-0.6, 1.8, 3.8), (-0.2, 0.5, 1.0), 1.15),
                       ('Bip01 Head', (-1.6, -1.5, 3.2), (-0.5, -0.5, 1.0), 0.8),
                       ('Bip01 L UpperArm', (0.0, 1.6, 1.0), (0.0, 0.7, 1.0), 1.0),
                       ('Bip01 Spine3', (-5.0, -3.0, 2.5), (-0.7, -0.3, 1.0), 1.1),
                       ('Bip01 Spine2', (-7.0, 0.5, -2.5), (-1.0, 0.2, 0.4), 0.9)))),
                   ('jaw_teeth', dict(mat='teeth', n=5, size=0.9)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.45))],
                  dict(eye='glow', glow=(170, 255, 80), mouth='open', teeth=(190, 180, 130), brow_color=None, eye_size=0.7,
                       dark_sockets=0.6),
                  decals=_spore_decals, quick=quick)


# ============================================================================================ 23 nightmare
def _nightmare_mats(rig, sh):
    J = rig.J
    k = _k(rig)
    c = CLASS_RGB['nightmare']
    sk = skin((40, 34, 38), seed=4301, variation=0.25, tint2=(20, 16, 24), tint2_amount=0.7, veins=1.0,
              vein_color=(150, 10, 10), vein_freq=0.28, rot=0.3, rot_color=(24, 20, 22), wounds=0.3, blood=0.3, pores=0.3)
    smoke = cloth((26, 24, 28), seed=4302, weave=0.04, weave_freq=2.0, dirt=0.8, dirt_color=(60, 56, 64), stains=0.6,
                  tears=0.8)
    ember = glow(c, (255, 60, 30), freq=0.8)
    return {
        'skin': sk, 'head': dict(sk, seed=4303), 'hand': dict(sk, seed=4304), 'boot': dict(sk, seed=4305),
        'body': layers(sk, (smoke, {'meshes': ['torso'], 'z': (-60, J('Bip01 Spine2')[2]), 'ragged': 2.0, 'holes': 0.4,
                                    'seed': 4}, (90, 0, 0)),
                       (smoke, {'meshes': ['arm'], 't': (-1.0, 0.35), 'ragged': 1.8, 'holes': 0.4, 'seed': 5}, (90, 0, 0))),
        'legs': layers(sk, (smoke, {'meshes': ['leg'], 't': (-1, 1.8), 'ragged': 2.0, 'holes': 0.4, 'seed': 6}, (90, 0, 0))),
        'shroud': layers(dict(smoke, seed=4306), (ember, {'z': (-60, J('Bip01 Pelvis')[2] - 14.0 * k), 'ragged': 2.4,
                                                          'seed': 7})),
        'wisp': layers(dict(smoke, seed=4307, color=(40, 36, 44)), (ember, {'t': (0.8, 9), 'ragged': 0.4, 'seed': 8})),
        'smoke': {'type': 'horn', 'color': (34, 30, 36), 'tip_color': (150, 20, 16), 'tip_dark': 0.9, 'seed': 4308},
        'claw': {'type': 'bone', 'color': (30, 24, 28), 'tip_color': (220, 30, 20), 'tip_dark': 0.9, 'seed': 4309},
        'teeth': {'type': 'bone', 'color': (180, 160, 160), 'tip_color': (160, 0, 0), 'seed': 4310},
        'eyeglow': glow((255, 30, 20), (255, 180, 150)),
    }


def nightmare(quick=False):
    """23 Nightmare (blood red / black): tall gaunt shadow wrapped in black smoke rags and a tattered shroud
    with ember-lit edges, smoke tendrils curling up from the back, a head crowded with glowing red eyes
    and more eyes opening on the chest; long claws, jerky predatory walk."""
    rs = RigSpec(height=76.0, shoulder_w=0.2, hip_w=0.11, leg=0.52, arm=0.4, hand=0.13, head=0.13, limb_thick=0.78,
                 bulk=0.82)
    return _zspec('nightmare', rs,
                  dict(hunch=22.0, lurch=0.6, limp=0.0, walk_D=62.0, run_D=112.0, run_lean=18.0, arm_swing=0.8,
                       knee_bend=0.14, stance_w=0.95, claw_spread=1.6, aggression=1.4),
                  dict(gaunt=0.7, muscle=0.15, chest=0.9, waist=0.72, claw_len=1.6,
                       head=dict(jaw=1.0, sockets=1.9, cheek=1.3, nose=0.0, mouth_open=1.0, jaw_drop=0.55, w=0.95,
                                 cranium=1.1, ears=0.0)),
                  _nightmare_mats,
                  [('cape', dict(mat='shroud', length=0.95, width=14.0, tatter=0.8, flare=0.45)),
                   ('shirt_flaps', dict(mat='wisp', n=8, length=7.0, seed=231)),
                   (smoke_tendrils, dict(mat='smoke', n=6, length=7.5, seed=232)),
                   (extra_eyes, dict(mat='eyeglow', size=0.36, spots=((0.0, 2.6), (1.4, 2.0), (-1.4, 2.0), (2.2, 0.6),
                                                                      (-2.2, 0.6), (0.9, 3.4), (-0.9, 3.4)))),
                   (body_eyes, dict(mat='eyeglow', size=0.5, where=(('Bip01 Spine3', (4.4, 1.8, -0.5)),
                                                                    ('Bip01 Spine3', (4.4, -1.8, -0.5)),
                                                                    ('Bip01 Spine2', (5.0, 0.0, -1.0))))),
                   ('jaw_teeth', dict(mat='teeth', n=7, size=1.0)),
                   ('glow_eyes', dict(mat='eyeglow', size=0.6))],
                  dict(eye='glow', glow=(255, 30, 20), mouth='open', teeth=(180, 160, 160), lips=(90, 0, 0),
                       brow_color=None, eye_size=0.9, dark_sockets=1.0, brow_shadow=0.8, cheek_amount=0.0),
                  quick=quick)


# ============================================================================================ all
ORDER = [butcher, hunter, charger, arachne, magma, volt, mimic, burrower, siren, bulwark, sporemother, nightmare]


def all(quick=False):      # noqa: A001  (CLI entry name)
    """All 12 classes (12-23) in class order, each with claws."""
    return [f(quick) for f in ORDER]
