"""Parametric humanoid body meshes (rest pose, rigidly skinned to rig_cs bones).

build_body(rig, shape, mats) -> list[Mesh] with names:
  torso, neck, head, arm_L/arm_R, hand_L/hand_R (+ fingers), leg_L/leg_R, foot_L/foot_R
Every limb is ONE continuous loft whose rings are assigned to the bone they belong to; a ring sits
exactly on each joint (assigned to the child) so bending only stretches one ring band (classic GoldSrc
skinning) and never opens holes. Shoulder/hip ends are capped and buried inside the torso.

`shape` is a dict (all optional, see DEFAULT_SHAPE); `mats` maps part -> material name.
"""
import math
import numpy as np

from .geom import Mesh, loft, Ring, tube, ellipsoid, _grid_faces, path_frames, box, flat_shaded
from .mathx import rot_y, rot_z, rot_x, look_frame, axis_angle
from .rig_cs import grip_rest_rot

DEFAULT_SHAPE = dict(
    chest=1.0, waist=1.0, hips=1.0, belly=0.0, hump=0.0, shoulders=1.0, muscle=0.35, gaunt=0.0,
    pecs=0.5, neck=1.0, neck_len=1.0, arm=1.0, forearm=1.0, thigh=1.0, calf=1.0,
    hands='glove',          # glove | bare | claw | mitten
    claw_len=1.0, claw_count=4,
    feet='boot',            # boot | bare | shoe
    head=None,              # dict, see DEFAULT_HEAD
    seg_torso=16, seg_limb=10, seg_head=16,
    sleeve_ridge=0.0,       # >0 adds a ridge ring at sleeve end (cloth thickness), value = z fraction along arm
)

DEFAULT_HEAD = dict(
    w=1.0, h=1.0, d=1.0, jaw=1.0, chin=1.0, nose=1.0, brow=1.0, cheek=1.0, sockets=1.0,
    skull_back=1.0, ears=1.0, jaw_drop=0.0, cranium=1.0, flat_top=0.0, snout=0.0, mouth_open=0.0,
)


def _merge_shape(shape):
    s = dict(DEFAULT_SHAPE)
    if shape:
        s.update(shape)
    h = dict(DEFAULT_HEAD)
    if s.get('head'):
        h.update(s['head'])
    s['head'] = h
    return s


def _interp(controls, u):
    us = [c[0] for c in controls]
    out = []
    for k in range(1, len(controls[0])):
        ys = [c[k] for c in controls]
        out.append(np.interp(u, us, ys))
    return out


def loft_points(ring_pts, ring_bones, mat, name, cap_start=False, cap_end=False, ring_t=None, size=None):
    """Loft from explicit ring point arrays (nr, segs+1, 3) (closed rings, last point == first)."""
    nr, ns, _ = ring_pts.shape
    v = ring_pts.reshape(-1, 3)
    cs = ring_pts[:, :-1].mean(1)
    L = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(cs, axis=0), axis=1))])
    tot = max(L[-1], 1e-6)
    uv = np.array([(i / (ns - 1), L[j] / tot) for j in range(nr) for i in range(ns)])
    bones = np.repeat(np.asarray(ring_bones), ns)
    f = _grid_faces(nr, ns)
    tt = np.repeat(np.asarray(ring_t if ring_t is not None else np.linspace(0, 1, nr)), ns)
    th = np.tile(np.linspace(0, 2 * math.pi, ns), nr)
    extra_v, extra_f, extra_uv, extra_b, extra_t, extra_th = [], [], [], [], [], []
    for which, on in ((0, cap_start), (nr - 1, cap_end)):
        if not on:
            continue
        ci = len(v) + len(extra_v)
        extra_v.append(cs[which]); extra_uv.append((0.5, 0.0 if which == 0 else 1.0))
        extra_b.append(ring_bones[which]); extra_t.append(tt[which * ns]); extra_th.append(0.0)
        base = which * ns
        for i in range(ns - 1):
            a, b = base + i, base + i + 1
            extra_f.append((ci, b, a) if which == 0 else (ci, a, b))
    if extra_v:
        v = np.vstack([v, extra_v]); uv = np.vstack([uv, extra_uv]); bones = np.concatenate([bones, extra_b])
        tt = np.concatenate([tt, extra_t]); th = np.concatenate([th, extra_th]); f = np.vstack([f, extra_f])
    perim = np.max(np.sum(np.linalg.norm(np.diff(ring_pts, axis=1), axis=2), axis=1))
    m = Mesh(v, f, uv, None, bones, mat, size=size or (perim, tot), name=name)
    # orientation: side faces must point away from ring centres
    sf = _grid_faces(nr, ns)
    fn = np.cross(v[sf[:, 1]] - v[sf[:, 0]], v[sf[:, 2]] - v[sf[:, 0]])
    ri = np.minimum(sf[:, 0] // ns, nr - 1)
    if np.sum(np.einsum('ij,ij->i', fn, v[sf].mean(1) - cs[ri])) < 0:
        m.f = m.f[:, ::-1].copy()
    m.attrs['t'] = tt
    m.attrs['theta'] = th
    m.recompute_normals()
    return m


def _superellipse(th, e):
    c, s = np.cos(th), np.sin(th)
    return np.sign(c) * np.abs(c) ** (2.0 / e), np.sign(s) * np.abs(s) ** (2.0 / e)


# ============================================================================================ torso

def torso_mesh(rig, sh, mat):
    H = rig.H
    k = H / 72.0
    b = rig.spec.bulk
    J = rig.J
    z_hip = J('Bip01 L Thigh')[2]
    z_neck = J('Bip01 Neck')[2]
    z_c = z_hip - 0.05 * H
    z_sh = J('Bip01 L UpperArm')[2]
    W = sh['shoulders']; CH = sh['chest']; WA = sh['waist']; HI = sh['hips']; BE = sh['belly']
    HU = sh['hump']; MU = sh['muscle']; GA = sh['gaunt']
    swh = rig.spec.shoulder_w * H * 0.5
    # control rows: (u, half width, depth front, depth back) in 72-scale units; u = 0 crotch .. 1 neck base
    def zu(z):
        return (z - z_c) / (z_neck - z_c)
    u_hip = zu(z_hip + 0.02 * H)
    u_waist = zu(J('Bip01 Spine1')[2])
    u_chest = zu(J('Bip01 Spine2')[2] + 0.02 * H)
    u_sh = zu(z_sh)
    z_top = z_neck + 0.022 * H
    u_top = zu(z_top)
    def U(z):
        return zu(z) / u_top
    ctrl = [
        (0.0, 3.0 * HI, 2.6, 3.0),
        (U(z_c + 0.012 * H), 6.0 * HI, 3.6, 4.2 * HI),
        (U(z_hip + 0.02 * H), 7.0 * HI, 4.0, 4.6 * HI),
        ((U(z_hip + 0.02 * H) + U(J('Bip01 Spine1')[2])) / 2, 6.4 * (HI + WA) / 2, 3.9 + 0.8 * BE, 4.0),
        (U(J('Bip01 Spine1')[2]), 5.8 * WA * (1 - 0.18 * GA), 3.9 + 1.6 * BE, 3.6 * (1 - 0.1 * GA)),
        ((U(J('Bip01 Spine1')[2]) + U(J('Bip01 Spine2')[2])) / 2, 6.3 * CH * (1 - 0.1 * GA),
         4.2 + 1.2 * BE + 0.2 * MU, 3.8 + 0.3 * HU),
        (U(J('Bip01 Spine2')[2] + 0.02 * H), 7.1 * CH * (1 + 0.12 * MU), 4.7 * CH * (1 + 0.15 * MU) + 0.3 * BE,
         4.1 + 0.9 * HU),
        (U(z_sh - 0.045 * H), 7.3 * W * (1 + 0.12 * MU), 4.4 * CH * (1 + 0.1 * MU), 4.2 + 1.4 * HU),
        (U(z_sh - 0.005 * H), 7.4 * W * (1 + 0.1 * MU), 3.6 * CH, 4.0 + 1.5 * HU),
        (U(z_sh + 0.016 * H), 6.3 * W * (1 + 0.15 * MU), 2.9, 3.5 + 1.2 * HU),
        (U(z_neck + 0.011 * H), 3.7 * (1 + 0.2 * MU) * sh['neck'], 2.5, 2.9 + 0.6 * HU),
        (1.0, 2.5 * sh['neck'] * (1 + 0.2 * MU), 2.2 * sh['neck'], 2.4 * sh['neck']),
    ]
    u_hip = U(z_hip); u_waist = U(J('Bip01 Spine1')[2]); u_chest = U(J('Bip01 Spine2')[2] + 0.02 * H)
    u_sh = U(z_sh)
    z_neck_top = z_top
    us = np.unique(np.concatenate([np.linspace(0, 1, 14), [u_hip, u_waist, u_chest, u_sh]]))
    us = np.array(sorted(set(np.round(us, 4))))
    segs = sh['seg_torso']
    # UV seam at the back (theta = pi); 'thw' is the wrapped angle used by the shape features
    th = np.linspace(math.pi, 3 * math.pi, segs + 1)
    ex, ey = _superellipse(th, 2.35)
    thw = (th + math.pi) % (2 * math.pi) - math.pi
    rings = []
    bones = []
    spine_z = [J(n)[2] for n in ('Bip01 Spine', 'Bip01 Spine1', 'Bip01 Spine2', 'Bip01 Spine3')]
    spine_x = [J(n)[0] for n in ('Bip01 Spine', 'Bip01 Spine1', 'Bip01 Spine2', 'Bip01 Spine3', 'Bip01 Neck')]
    spine_zz = spine_z + [z_neck]
    for u in us:
        w, df, db = _interp(ctrl, u)
        z = z_c + u * (z_neck_top - z_c)
        xc = np.interp(z, spine_zz, spine_x)
        # hump pushes the upper torso forward/up (zombie posture baked lightly in mesh)
        xc += HU * 1.2 * k * max(0.0, (u - 0.55) / 0.45) ** 1.5
        d = np.where(ex >= 0, df, db)
        x = ex * d
        y = ey * w
        # pecs / shoulder blades / spine groove
        if u > u_waist:
            pk = sh['pecs'] * CH * max(0, 1 - abs(u - (u_chest + 0.06)) / 0.18)
            bump = pk * 0.6 * (np.exp(-((thw - 0.55) ** 2) / 0.06) + np.exp(-((thw + 0.55) ** 2) / 0.06))
            x = x + bump * (ex > 0)
            sb = (0.35 + 0.4 * HU) * max(0, 1 - abs(u - (u_chest + 0.1)) / 0.2)
            bl = sb * (np.exp(-((np.abs(thw) - (math.pi - 0.6)) ** 2) / 0.08))
            x = x - bl * (ex < 0)
        groove = 0.25 * np.exp(-((np.abs(thw) - math.pi) ** 2) / 0.02) * (u > 0.2) * (u < 0.85)
        x = x + groove
        # ribs for gaunt bodies: slight front/side ripples (texture adds the rest)
        pts = np.stack([xc + x * k * b, y * k * b, np.full_like(x, z)], -1)
        rings.append(pts)
        if z < spine_z[0]:
            bn = 'Bip01 Pelvis'
        elif z < spine_z[1]:
            bn = 'Bip01 Spine'
        elif z < spine_z[2]:
            bn = 'Bip01 Spine1'
        elif z < spine_z[3]:
            bn = 'Bip01 Spine2'
        else:
            bn = 'Bip01 Spine3'
        bones.append(rig.index[bn])
    m = loft_points(np.array(rings), bones, mat, 'torso', cap_start=True, cap_end=True, ring_t=us)
    m.detail = 1.0
    return m


def neck_mesh(rig, sh, mat):
    H = rig.H; k = H / 72.0
    n0 = rig.J('Bip01 Neck'); h0 = rig.J('Bip01 Head')
    r = 2.2 * k * sh['neck'] * (1 + 0.25 * sh['muscle'])
    pts = [n0 + np.array([0.0, 0, -2.4 * k]), n0, (n0 + h0) / 2, h0 + np.array([0.4 * k, 0, 1.2 * k])]
    rad = [r * 1.2, r * 1.05, r * 0.95, r * 0.95]
    bones = [rig.index['Bip01 Neck']] * 3 + [rig.index['Bip01 Head']]
    m = tube(pts, rad, segs=10, mat=mat, bones=bones, cap_start=False, cap_end=False, radii_b=[x * 1.1 for x in rad],
             name='neck', up=(1, 0, 0))
    m.detail = 1.0
    return m


# ============================================================================================ head

def head_mesh(rig, sh, mat):
    H = rig.H; k = H / 72.0
    hp = sh['head']
    hj = rig.J('Bip01 Head')
    top = -36.0 + H
    hh = (top - hj[2]) * hp['h']
    rz = hh * 0.53
    rx = 4.2 * k * hp['d']
    ry = 3.3 * k * hp['w']
    c = hj + np.array([0.35 * k, 0, hh * 0.52])

    def deform(u, p):
        ux, uy, uz = u[:, 0], u[:, 1], u[:, 2]
        out = p.copy()
        # rounder cranium (shorter top half), longer face/jaw half
        out[:, 2] = np.where(uz > 0, out[:, 2] * 0.86, out[:, 2] * 1.04)
        out[:, 1] *= np.where(uz > 0, 1.0 + 0.04 * uz, 1.0)
        # cranium fuller at top/back
        out[:, 0] -= np.clip(-ux, 0, 1) * np.clip(uz + 0.3, 0, 1) * 0.35 * k * hp['skull_back']
        out[:, 2] += np.clip(uz, 0, 1) ** 2 * 0.3 * k * (hp['cranium'] - 1) * 3
        if hp['flat_top']:
            out[:, 2] = np.minimum(out[:, 2], rz * (1 - 0.25 * hp['flat_top']))
        # jaw: lower head narrower, pushed forward, chin
        low = np.clip(-uz - 0.05, 0, 1)
        out[:, 1] *= 1 - (0.28 - 0.12 * hp['jaw']) * low     # jaw > 1 = wider, squarer jaw
        out[:, 0] += low * np.clip(ux, 0, 1) * 0.45 * k * hp['jaw']
        out[:, 0] -= low * np.clip(-ux, 0, 1) * 1.6 * k        # jaw/neck underside goes back
        out[:, 2] -= low * np.clip(ux, 0, 1) * (0.5 * k * hp['chin'] + 1.2 * k * hp['jaw_drop'])
        # chin bump
        chin = np.exp(-(((ux - 0.82) ** 2) + uy ** 2 * 3 + (uz + 0.72) ** 2) / 0.03)
        out[:, 0] += chin * 0.45 * k * hp['chin']
        # nose
        nose = np.exp(-(((ux - 1.0) ** 2) * 2 + (uy ** 2) / 0.012 + ((uz + 0.12) ** 2) / 0.05))
        out[:, 0] += nose * 1.15 * k * hp['nose']
        # snout (bestial)
        if hp['snout']:
            sn = np.exp(-(((ux - 1.0) ** 2) + (uy ** 2) / 0.08 + ((uz + 0.3) ** 2) / 0.12))
            out[:, 0] += sn * 2.5 * k * hp['snout']
        # brow ridge
        brow = np.exp(-(((ux - 0.9) ** 2) / 0.05 + ((uz - 0.22) ** 2) / 0.006)) * (np.abs(uy) < 0.65)
        out[:, 0] += brow * 0.45 * k * hp['brow']
        # eye sockets
        for sgn in (1, -1):
            so = np.exp(-(((ux - 0.92) ** 2) / 0.03 + ((uy - sgn * 0.33) ** 2) / 0.018 + ((uz - 0.08) ** 2) / 0.012))
            out[:, 0] -= so * 0.55 * k * hp['sockets']
            ck = np.exp(-(((ux - 0.72) ** 2) / 0.04 + ((uy - sgn * 0.6) ** 2) / 0.03 + ((uz + 0.1) ** 2) / 0.02))
            out[:, 0] += ck * 0.25 * k * hp['cheek']
            out[:, 1] += sgn * ck * 0.25 * k * hp['cheek']
            # ears
            ear = np.exp(-((ux + 0.05) ** 2 / 0.02 + (uy - sgn) ** 2 / 0.04 + (uz - 0.0) ** 2 / 0.04))
            out[:, 1] += sgn * ear * 0.55 * k * hp['ears']
        # mouth slit
        mo = np.exp(-(((ux - 0.95) ** 2) / 0.04 + (uy ** 2) / 0.05 + ((uz + 0.42) ** 2) / 0.002))
        out[:, 0] -= mo * (0.2 + 0.8 * hp['mouth_open']) * k
        return out

    m = ellipsoid((rx, ry, rz), (0, 0, 0), segs=sh['seg_head'], rings=12, mat=mat,
                  bone=rig.index['Bip01 Head'], deform=deform)
    m.translate(c)
    m.name = 'head'
    m.detail = 2.2
    m.head_center = c
    m.head_radii = (rx, ry, rz)
    return m


def face_anchor(rig, sh):
    """Key face positions (rest pose, model space) for decals: eyes, mouth, nose, brow."""
    H = rig.H; k = H / 72.0
    hp = sh['head']
    hj = rig.J('Bip01 Head')
    top = -36.0 + H
    hh = (top - hj[2]) * hp['h']
    rz = hh * 0.53
    rx = 4.2 * k * hp['d']
    ry = 3.3 * k * hp['w']
    c = hj + np.array([0.35 * k, 0, hh * 0.52])
    def onsurf(ux, uy, uz, depth=0.0):
        d = np.array([ux, uy, uz]); d /= np.linalg.norm(d)
        return c + d * np.array([rx, ry, rz]) + np.array([depth, 0, 0])
    return dict(center=c, radii=(rx, ry, rz),
                eye_L=onsurf(0.92, 0.33, 0.08, -0.45 * k * hp['sockets']),
                eye_R=onsurf(0.92, -0.33, 0.08, -0.45 * k * hp['sockets']),
                mouth=onsurf(0.95, 0.0, -0.42),
                nose=onsurf(1.0, 0.0, -0.12, 1.0 * k),
                brow=onsurf(0.9, 0.0, 0.25),
                k=k)

def face_features(rig, sh, mat):
    """Separate small meshes on the Head bone: nose and ears (the head sphere is too coarse for them)."""
    fa = face_anchor(rig, sh)
    k = fa['k']
    hp = sh['head']
    hb = rig.index['Bip01 Head']
    c = fa['center']; rx, ry, rz = fa['radii']
    out = []
    if hp['nose'] > 0.05:
        n = hp['nose']
        nb = fa['nose'] - np.array([1.05 * k, 0, 0.1 * k])
        nose = ellipsoid((0.75 * k * n, 0.5 * k * (0.7 + 0.3 * n), 1.25 * k), nb, segs=8, rings=6, mat=mat, bone=hb,
                         deform=lambda u, p: p + np.array([0.0, 0.0, 0.0]) + np.outer(np.clip(-u[:, 2], 0, 1) ** 2, [0.35 * k * n, 0, 0])
                         + np.outer(np.clip(-u[:, 2], 0, 1), [0, 0, 0]) * 0 + np.column_stack([np.zeros(len(u)), u[:, 1] * np.clip(-u[:, 2], 0, 1) * 0.35 * k, np.zeros(len(u))]))
        nose.name = 'nose'
        nose.detail = 2.0
        out.append(nose)
    if hp['ears'] > 0.05:
        e = hp['ears']
        for sg in (1, -1):
            ear = ellipsoid((0.75 * k * e, 0.28 * k, 1.25 * k * e), (c[0] - 0.35 * k, sg * (ry * 0.97), fa['eye_L'][2] - 0.55 * k),
                            segs=8, rings=5, mat=mat, bone=hb)
            ear.v[:, 1] += sg * np.clip((ear.v[:, 0] - (c[0] - 0.35 * k)) * -0.25, 0, 1) * k
            ear.recompute_normals()
            ear.name = 'ear'
            ear.detail = 1.5
            out.append(ear)
    return out


# ============================================================================================ limbs


def _limb(rig, names, radii_ctrl, segs, mat, name, cap_top=True, cap_bottom=False, top_ext=0.0,
          bot_ext=0.0, flat=1.0, front_axis=(1, 0, 0), extra_rings=None):
    """Loft along a joint chain. names: joints [j0, j1, j2] (+ optional end point); radii_ctrl:
    list of (param, radius) where param runs 0 at j0 .. 1 at j1 .. 2 at j2. Rings at integer params are
    assigned to the child bone; rings in (n, n+1) to bone names[n]."""
    J = [rig.J(n) for n in names]
    d0 = J[1] - J[0]; d0 /= np.linalg.norm(d0)
    dn = J[-1] - J[-2]; dn /= np.linalg.norm(dn)
    params = sorted(set([p for p, _ in radii_ctrl] + list(range(len(J)))))
    params = [p for p in params if -1.0 <= p <= len(J)]
    pts, rads, bones = [], [], []
    rp = np.array([p for p, _ in radii_ctrl]); rr = np.array([r for _, r in radii_ctrl])
    for p in params:
        if p < 0:
            pt = J[0] + d0 * p * top_ext
            seg = 0
        elif p >= len(J) - 1:
            pt = J[-1] + dn * (p - (len(J) - 1)) * bot_ext
            seg = len(J) - 2
        else:
            i = int(math.floor(p))
            f = p - i
            pt = J[i] * (1 - f) + J[i + 1] * f
            seg = i
        pts.append(pt)
        rads.append(float(np.interp(p, rp, rr)))
        # bone: segment index; at an exact joint the child bone
        if p >= 0 and abs(p - round(p)) < 1e-9 and 0 < round(p) < len(J) - 1:
            bones.append(rig.index[names[int(round(p))]])
        else:
            bones.append(rig.index[names[min(max(seg, 0), len(names) - 2)]])
    pts = np.array(pts)
    fr = path_frames(pts, ref=np.asarray(front_axis, float))
    rings = [Ring(pts[i], fr[i], rads[i], rads[i] * flat, bones[i], t=params[i]) for i in range(len(pts))]
    m = loft(rings, segs, mat, cap_start=cap_top, cap_end=cap_bottom, name=name)
    return m


def arm_mesh(rig, sh, side, mat):
    H = rig.H; k = H / 72.0 * rig.spec.limb_thick * rig.spec.arm_thick
    A, F = sh['arm'], sh['forearm']
    mu = sh['muscle']; ga = sh['gaunt']
    sth = 1 - 0.25 * ga
    ctrl = [(-1.0, 0.35 * k), (-0.86, 1.2 * k * A), (-0.62, 1.8 * k * A * (1 + 0.1 * mu)),
            (-0.32, 2.15 * k * A * (1 + 0.15 * mu)), (0.0, 2.3 * k * A * (1 + 0.15 * mu)), (0.22, 2.15 * k * A * sth * (1 + 0.12 * mu)),
            (0.55, 2.0 * k * A * sth * (1 + 0.2 * mu)), (0.85, 1.7 * k * A * sth), (1.0, 1.62 * k * F),
            (1.22, 1.88 * k * F * sth * (1 + 0.15 * mu)), (1.6, 1.55 * k * F * sth), (1.92, 1.2 * k * F),
            (2.0, 1.18 * k * F)]
    names = ['Bip01 %s UpperArm' % side, 'Bip01 %s Forearm' % side, 'Bip01 %s Hand' % side]
    m = _limb(rig, names, ctrl, sh['seg_limb'], mat, 'arm_' + side, cap_top=True, cap_bottom=False,
              top_ext=2.2 * k, front_axis=(1, 0, 0), flat=0.92)
    if sh.get('sleeve_ridge'):
        pass
    m.detail = 1.0
    return m


def leg_mesh(rig, sh, side, mat):
    H = rig.H; k = H / 72.0 * rig.spec.limb_thick * rig.spec.leg_thick
    T, Cc = sh['thigh'], sh['calf']
    mu = sh['muscle']; ga = sh['gaunt']
    sth = 1 - 0.22 * ga
    ctrl = [(-1.0, 1.6 * k), (-0.6, 3.2 * k * T), (0.0, 3.6 * k * T * (1 + 0.1 * mu)),
            (0.3, 3.35 * k * T * sth * (1 + 0.1 * mu)), (0.7, 2.75 * k * T * sth), (0.92, 2.3 * k * T),
            (1.0, 2.2 * k * Cc), (1.12, 2.3 * k * Cc), (1.35, 2.5 * k * Cc * sth * (1 + 0.12 * mu)),
            (1.7, 1.95 * k * Cc * sth), (1.94, 1.4 * k * Cc), (2.0, 1.35 * k * Cc)]
    names = ['Bip01 %s Thigh' % side, 'Bip01 %s Calf' % side, 'Bip01 %s Foot' % side]
    m = _limb(rig, names, ctrl, sh['seg_limb'], mat, 'leg_' + side, cap_top=True, cap_bottom=False,
              top_ext=3.0 * k, front_axis=(1, 0, 0), flat=1.0)
    m.detail = 0.9
    return m


def foot_mesh(rig, sh, side, mat):
    H = rig.H; k = H / 72.0 * (rig.spec.limb_thick ** 0.5)
    a = rig.J('Bip01 %s Foot' % side)
    t = rig.J('Bip01 %s Toe0' % side)
    ground = -36.0
    style = sh['feet']
    fb = rig.index['Bip01 %s Foot' % side]
    tb = rig.index['Bip01 %s Toe0' % side]
    L = t[0] - a[0]
    heel_x = a[0] - 0.36 * L
    toe_x = t[0] + 0.42 * L
    boot = style in ('boot', 'shoe')
    hgt = (a[2] - ground)
    # cross sections along X: (x, half width, top z, bottom z)
    wscale = 1.12 if boot else 1.0
    sec = [
        (heel_x, 1.25 * k * wscale, a[2] + (0.9 if boot else 0.3) * k, ground),
        (a[0] - 0.1 * L, 1.65 * k * wscale, a[2] + (1.6 if boot else 0.6) * k, ground),
        (a[0] + 0.45 * L, 1.85 * k * wscale, ground + hgt * 0.75, ground),
        (t[0], 2.0 * k * wscale, ground + hgt * 0.42, ground),
        (t[0] + 0.25 * L, 1.85 * k * wscale, ground + hgt * 0.36, ground + 0.05),
        (toe_x, 1.2 * k * wscale, ground + hgt * 0.24, ground + 0.15 * k),
    ]
    segs = 10
    rings = []
    bones = []
    th = np.linspace(0, 2 * math.pi, segs + 1)
    c, s = np.cos(th), np.sin(th)
    for x, hw, zt, zb in sec:
        zc = (zt + zb) / 2; hz = (zt - zb) / 2
        # rounded rectangle cross section in the Y-Z plane
        yy = np.sign(s) * np.abs(s) ** 0.6 * hw
        zz = zc + np.sign(c) * np.abs(c) ** 0.6 * hz
        pts = np.stack([np.full_like(yy, x), a[1] + yy, zz], -1)
        rings.append(pts)
        bones.append(tb if x > t[0] - 0.05 else fb)
    rings = np.array(rings)
    m = loft_points(rings, bones, mat, 'foot_' + side, cap_start=True, cap_end=True)
    m.detail = 0.9
    return m


# ============================================================================================ hands

def _hand_parts(rig, side, sh, mat_hand, mat_claw):
    """Hand geometry built in the GRIP frame of the hand bone, then moved to the rest pose."""
    H = rig.H
    hl = rig.spec.hand * H
    k = hl / 7.6
    sg = 1 if side == 'R' else -1   # palm side is +Y for the right hand
    G = grip_rest_rot()
    wr = rig.J('Bip01 %s Hand' % side)
    style = sh['hands']
    bh = rig.index['Bip01 %s Hand' % side]
    b1 = rig.index['Bip01 %s Finger1' % side]; b11 = rig.index['Bip01 %s Finger11' % side]
    b0 = rig.index['Bip01 %s Finger0' % side]; b01 = rig.index['Bip01 %s Finger01' % side]
    meshes = []
    th = 1.25 if style in ('glove', 'mitten') else 1.0

    def to_world(m):
        m.v = (m.v @ G.T) + wr
        m.n = m.n @ G.T
        return m

    # palm: loft along grip-X from wrist to knuckles, cross-section in the Y(thickness) x Z(height) plane
    secs = [(-0.6, 0.75, 1.0, 0.95), (0.5, 0.85, 1.35, 1.3), (2.2, 0.85, 1.55, 1.75), (3.6, 0.78, 1.45, 1.75),
            (4.3, 0.6, 1.2, 1.5)]
    segs = 10
    thv = np.linspace(0, 2 * math.pi, segs + 1)
    c, s = np.cos(thv), np.sin(thv)
    rings = []
    for x, ty, zt, zb in secs:
        yy = np.sign(c) * np.abs(c) ** 0.7 * ty * k * th
        zz = np.where(s >= 0, np.abs(s) ** 0.7 * zt, -np.abs(s) ** 0.7 * zb) * k * th
        rings.append(np.stack([np.full_like(yy, x * k), yy, zz - 0.25 * k], -1))
    palm = loft_points(np.array(rings), [bh] * len(secs), mat_hand, 'hand_' + side, cap_start=True, cap_end=True)
    meshes.append(to_world(palm))

    f1 = rig.rest_local_pos[b1]; f11 = rig.rest_local_pos[b11]   # in grip frame (hand-local)
    p_k = f1                      # knuckle joint
    p_m = f1 + f11                # middle joint
    tip_dir = (p_m - p_k) / np.linalg.norm(p_m - p_k)
    if style in ('glove', 'mitten', 'bare'):
        # four-finger mitten wrapped around the grip: proximal + distal segment
        curl_tip = p_m + np.array([-1.2, sg * 1.25, 0]) * k
        if rig.spec.hand_pose != 'grip':
            curl_tip = p_m + tip_dir * 1.9 * k
        path = [p_k - tip_dir * 0.4 * k, p_k, (p_k + p_m) / 2, p_m, (p_m + curl_tip) / 2, curl_tip]
        bones = [b1, b1, b1, b11, b11, b11]
        zr = [1.7, 1.75, 1.7, 1.6, 1.5, 1.25]
        yr = [0.7, 0.72, 0.7, 0.66, 0.6, 0.45]
        pts = np.array(path)
        fr = path_frames(pts, ref=np.array([0, 0, 1.0]))
        rings = [Ring(pts[i], fr[i], yr[i] * k * th, zr[i] * k * th, bones[i]) for i in range(len(pts))]
        # Ring frame x is perpendicular to tangent and roughly along Z -> 'a' along x
        rings = [Ring(pts[i], fr[i], zr[i] * k * th, yr[i] * k * th, bones[i]) for i in range(len(pts))]
        fing = loft(rings, 8, mat_hand, cap_start=True, cap_end=True, name='fingers_' + side)
        fing.transform(np.eye(3), np.array([0, 0, -0.3 * k]))
        meshes.append(to_world(fing))
    else:
        # claw hands: separate fingers with claws
        n = int(sh.get('claw_count', 4))
        zs = np.linspace(1.25, -1.9, n) * k
        fan = np.linspace(0.22, -0.32, n)   # fingers fan out from the knuckles
        cl = sh.get('claw_len', 1.0)
        for fi in range(n):
            off = np.array([0, 0, zs[fi] + 0.45 * k])
            ln = (1.0 - 0.12 * abs(fi - 1.2)) * k
            base = p_k + off * 0.8 - tip_dir * 0.3 * k
            fd = tip_dir + np.array([0, 0, fan[fi]])
            fd /= np.linalg.norm(fd)
            mid = p_k + off * 0.9 + fd * np.linalg.norm(p_m - p_k)
            curl = np.array([0.0, sg * 0.45, 0]) * k
            tip = mid + fd * 1.6 * ln + curl
            fg = tube([base, p_k + off, (p_k + p_m) / 2 + off, mid, tip],
                      np.array([0.48, 0.5, 0.45, 0.4, 0.3]) * k, segs=6, mat=mat_hand,
                      bones=[b1, b1, b1, b11, b11], cap_start=True, cap_end=True, name='finger%d_%s' % (fi, side))
            meshes.append(to_world(fg))
            d = tip - mid; d /= np.linalg.norm(d)
            claw = tube([tip - d * 0.25 * k, tip + d * 1.0 * k * cl + curl * 0.4,
                         tip + d * 2.0 * k * cl + np.array([0, sg * 0.8, 0]) * k * cl],
                        np.array([0.36, 0.22, 0.02]) * k, segs=5, mat=mat_claw, bones=[b11, b11, b11],
                        cap_start=True, cap_end=False, name='claw%d_%s' % (fi, side))
            claw.attrs['t'] = np.repeat(np.array([0.0, 0.5, 1.0]), 6)[:len(claw.v)] if len(claw.v) == 18 else np.linspace(0, 1, len(claw.v))
            meshes.append(to_world(claw))
    # thumb
    t0 = rig.rest_local_pos[b0]; t01 = t0 + rig.rest_local_pos[b01]
    td = (t01 - t0) / np.linalg.norm(t01 - t0)
    ttip = t01 + td * 1.4 * k + (np.array([0.3, sg * 0.5, 0.1]) * k if rig.spec.hand_pose == 'grip' else 0)
    thumb = tube([t0 - td * 0.6 * k, t0, t01, ttip], np.array([0.75, 0.7, 0.58, 0.45]) * k * th, segs=7,
                 mat=mat_hand, bones=[b0, b0, b01, b01], cap_start=True, cap_end=True, name='thumb_' + side)
    meshes.append(to_world(thumb))
    if style == 'claw':
        d = ttip - t01; d /= np.linalg.norm(d)
        tc = tube([ttip - d * 0.2 * k, ttip + d * 1.2 * k * sh.get('claw_len', 1.0)], np.array([0.3, 0.02]) * k,
                  segs=5, mat=mat_claw, bones=[b01, b01], cap_start=True, cap_end=False, name='thumbclaw_' + side)
        meshes.append(to_world(tc))
    for mm in meshes:
        mm.detail = 1.4
    return meshes


# ============================================================================================ build

def build_body(rig, shape=None, mats=None):
    sh = _merge_shape(shape)
    mats = dict(dict(torso='body', neck='skin', head='head', arm='body', hand='hand', leg='legs', foot='boot',
                     claw='claw'), **(mats or {}))
    out = [torso_mesh(rig, sh, mats['torso']), neck_mesh(rig, sh, mats['neck']), head_mesh(rig, sh, mats['head'])]
    out += face_features(rig, sh, mats['head'])
    for side in ('L', 'R'):
        out.append(arm_mesh(rig, sh, side, mats['arm']))
        out.append(leg_mesh(rig, sh, side, mats['leg']))
        out.append(foot_mesh(rig, sh, side, mats['foot']))
        out += _hand_parts(rig, side, sh, mats['hand'], mats['claw'])
    return out, sh
