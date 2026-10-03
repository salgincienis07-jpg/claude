"""Accessory library: gear, armour, clothing pieces and creature features attached to rig bones.

Every function: fn(rig, sh, **params) -> list[Mesh] built in the REST pose (model space) and rigidly
bound to bones. Pieces that span several spine bones are lofted ring-by-ring like the torso so they bend
with it. Names are what character specs use in 'accessories'.
"""
import math
import numpy as np

from .geom import Mesh, box, ellipsoid, tube, loft, Ring, horn, ribbon, extrude, cylinder, path_frames, flat_shaded, dome
from .body import loft_points, _superellipse, face_anchor
from .mathx import rot_x, rot_y, rot_z, axis_angle, look_frame


def _k(rig):
    return rig.H / 72.0


def _bi(rig, name):
    return rig.index[name]


def _spine_bone_for_z(rig, z):
    J = rig.J
    names = ['Bip01 Pelvis', 'Bip01 Spine', 'Bip01 Spine1', 'Bip01 Spine2', 'Bip01 Spine3']
    zs = [J('Bip01 Spine')[2], J('Bip01 Spine1')[2], J('Bip01 Spine2')[2], J('Bip01 Spine3')[2]]
    i = int(np.searchsorted(zs, z))
    return rig.index[names[i]]


def _shell_front_x(rig, sh, z, grow):
    """Front-most x of the torso surface (+grow) around height z (for placing gear on the chest)."""
    from .body import torso_mesh
    t = torso_mesh(rig, sh, 'tmp')
    sel = np.abs(t.v[:, 2] - z) < 2.5 * _k(rig)
    sel &= np.abs(t.v[:, 1]) < 3.0 * _k(rig)
    if not sel.any():
        return rig.J('Bip01 Spine2')[0] + 5.0 * _k(rig)
    return t.v[sel, 0].max() + grow * _k(rig)


def shell(rig, sh, z0, z1, grow=0.6, mat='vest', name='vest', front=1.0, back=1.0, segs=16, rings=7,
          open_front=False, side_scale=1.0, bottom_flare=0.0, x_shift=0.0):
    """Torso-hugging shell (vest, coat top, armour) between heights z0..z1 (model space), thickness `grow`
    over the torso surface. Sampled from the actual torso loft so it follows the body shape."""
    from .body import torso_mesh, _merge_shape
    t = torso_mesh(rig, sh, 'tmp')
    k = _k(rig)
    nseg = sh['seg_torso'] + 1
    ring_pts = t.v[: (len(t.v) // nseg) * nseg].reshape(-1, nseg, 3)
    ring_pts = ring_pts[:len(ring_pts)]
    zr = ring_pts[:, 0, 2]
    zs = np.linspace(z0, z1, rings)
    th_new = np.linspace(0, 2 * math.pi, segs + 1)
    th_old = np.linspace(0, 2 * math.pi, nseg)
    out = []
    bones = []
    for z in zs:
        j = int(np.clip(np.searchsorted(zr, z), 1, len(zr) - 1))
        f = (z - zr[j - 1]) / max(zr[j] - zr[j - 1], 1e-6)
        R = ring_pts[j - 1] * (1 - f) + ring_pts[j] * f
        c = R[:-1].mean(0)
        rel = R - c
        # resample around
        xs = np.interp(th_new, th_old, rel[:, 0]); ys = np.interp(th_new, th_old, rel[:, 1])
        d = np.stack([xs, ys], -1)
        n = np.linalg.norm(d, axis=1, keepdims=True)
        dn = d / np.maximum(n, 1e-6)
        fl = bottom_flare * max(0.0, (z1 - z) / max(z1 - z0, 1e-6) - 0.5) * 2
        g = grow * k + fl * k
        sc = np.where(xs > 0, front, back)
        p2 = d + dn * g
        p2[:, 0] *= np.where(xs > 0, front, back)
        p2[:, 1] *= side_scale
        pts = np.column_stack([c[0] + x_shift * k + p2[:, 0], c[1] + p2[:, 1], np.full(len(xs), z)])
        out.append(pts)
        bones.append(_spine_bone_for_z(rig, z))
    m = loft_points(np.array(out), bones, mat, name, cap_start=False, cap_end=False)
    m.make_two_sided() if open_front else None
    return m


# ---------------------------------------------------------------------------------------------- head gear

def helmet(rig, sh, mat='helmet', brim=0.0, visor_mat=None, size=1.0, low=0.0, spike=0.0, crest=0.0, name='helmet',
           ear_guards=False, rails=True, rail_mat=None, mount=True, style='combat'):
    """Combat helmet: thick dome down to the brow at the front, above the ears at the sides, to the
    nape at the back. style 'combat' (FAST-like cut-outs) or 'full' (rounder, covers more)."""
    fa = face_anchor(rig, sh)
    k = fa['k']
    c = fa['center']; rx, ry, rz = fa['radii']
    hb = _bi(rig, 'Bip01 Head')
    s = size
    eye_z = fa['eye_L'][2]
    # rim latitude (relative to the dome centre) by azimuth: front higher (brow), sides above ears, back low
    cz = c[2] + 0.35 * k
    def rim(ph):
        f = math.cos(ph)
        brow = math.asin(max(-0.9, min(0.9, (eye_z + 1.2 * k - cz) / (rz * 1.05 * s))))
        side = -0.12 - low * 0.3 if style == 'combat' else -0.45 - low * 0.3
        back = -0.55 - low * 0.3
        if f > 0:
            return brow * f ** 2 + side * (1 - f ** 2)
        return back * f ** 2 + side * (1 - f ** 2)
    dm = dome((rx * 1.12 * s + 0.35 * k, ry * 1.14 * s + 0.35 * k, rz * 1.06 * s + 0.5 * k), (0, 0, 0), rim=rim, segs=18,
              rings=6, mat=mat, bone=hb, thickness=0.45 * k)
    dm.translate((c[0] - 0.4 * k, c[1], cz))
    dm.name = name
    out = [dm]
    rm = rail_mat or mat
    if rails:
        for sg in (1, -1):
            r = box((3.4 * k, 0.45 * k, 0.7 * k), center=(c[0] - 0.6 * k, sg * (ry * 1.14 * s + 0.45 * k), cz - 0.2 * k),
                    bevel=0.12 * k, mat=rm, bone=hb)
            r.name = name + '_rail'
            out.append(r)
    if mount:
        mt = box((0.6 * k, 1.6 * k, 1.1 * k), center=(c[0] + rx * 1.12 * s - 0.1 * k, 0, eye_z + 2.4 * k), bevel=0.15 * k,
                 mat=rm, bone=hb)
        mt.name = name + '_mount'
        out.append(mt)
    if brim:
        out.append(tube([c + np.array([rx * 1.05, 0, 0.9 * k]), c + np.array([rx * 1.05 + brim * k, 0, 0.6 * k])],
                        [ry * 0.9, ry * 0.9], segs=8, mat=mat, bones=hb, radii_b=[0.25 * k, 0.25 * k]))
    if visor_mat:
        vz = eye_z + 0.1 * k
        ang = np.linspace(-1.05, 1.05, 9)
        pts = np.array([[c[0] + (rx + 0.85 * k) * math.cos(a), c[1] + (ry + 0.9 * k) * math.sin(a), vz] for a in ang])
        vis = ribbon(pts, 2.2 * k, normal_hint=(1, 0, 0), mat=visor_mat, bones=hb, two_sided=True, width_dir=(0, 0, 1))
        vis.name = name + '_visor'
        out.append(vis)
    if spike:
        out.append(horn(c + np.array([-0.5 * k, 0, rz * 0.9]), (0.2, 0, 1), spike * k, 0.8 * k, mat=mat, bone=hb))
    if crest:
        out.append(extrude([(-4.5, 0), (3, 0), (2, 1.6 * crest), (-3, 2.4 * crest), (-5.5, 1.0)], 0.6 * k,
                           R=rot_x(math.pi / 2), t=c + np.array([0, 0.3 * k, rz * 0.85]), mat=mat, bone=hb))
    if ear_guards:
        for sg in (1, -1):
            out.append(ellipsoid((1.3 * k, 0.45 * k, 1.6 * k), c + np.array([0.0, sg * (ry + 0.55 * k), -0.6 * k]),
                                 segs=8, rings=5, mat=mat, bone=hb))
    for m in out:
        m.detail = 1.3
    return out


def goggles(rig, sh, mat='goggle_frame', lens='lens', on_helmet=False, strap=True):
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    c = fa['center']; rx, ry, rz = fa['radii']
    out = []
    zz = fa['eye_L'][2] + (2.2 * k if on_helmet else 0.15 * k)
    for side, sg in (('eye_L', 1), ('eye_R', -1)):
        e = fa[side].copy(); e[2] = zz
        base = e + np.array([0.3 * k, 0, 0])
        cup = tube([base - np.array([0.6 * k, 0, 0]), base + np.array([0.5 * k, 0, 0])], [0.95 * k, 0.9 * k], segs=10,
                   mat=mat, bones=hb, cap_start=False, cap_end=False, up=(0, 0, 1))
        cup.name = 'goggle_cup'
        out.append(cup)
        ln = ellipsoid((0.18 * k, 0.86 * k, 0.8 * k), base + np.array([0.55 * k, 0, 0]), segs=10, rings=5, mat=lens, bone=hb)
        ln.name = 'goggle_lens'
        out.append(ln)
    if strap:
        ang = np.linspace(-2.6, 2.6, 15)
        pts = np.array([[c[0] + (rx + 0.25 * k) * math.cos(a), c[1] + (ry + 0.3 * k) * math.sin(a), zz] for a in ang])
        st = tube(pts, 0.32 * k, segs=4, mat=mat, bones=hb, radii_b=0.75 * k, cap_start=False, cap_end=False,
                  ref=np.array([0, 0, 1.0]))
        st.name = 'goggle_strap'
        out.append(st)
    for m in out:
        m.detail = 1.4
    return out


def gasmask(rig, sh, mat='mask', filt='filter'):
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    m0 = fa['mouth'] + np.array([0.6 * k, 0, 0.4 * k])
    out = [ellipsoid((2.2 * k, 2.6 * k, 2.3 * k), m0 - np.array([0.9 * k, 0, 0]), segs=12, rings=7, mat=mat, bone=hb)]
    out.append(cylinder(m0 + np.array([0.6 * k, 0, -0.6 * k]), m0 + np.array([2.4 * k, 0, -1.4 * k]), 1.2 * k, 1.25 * k,
                        segs=10, mat=filt, bone=hb))
    return out


def hood(rig, sh, mat='hood', depth=1.0, peak=1.0):
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    c = fa['center']; rx, ry, rz = fa['radii']

    def deform(u, p):
        q = p.copy()
        # open the face: front vertices pulled back to make a deep opening
        front = (u[:, 0] > 0.35) & (u[:, 2] < 0.55)
        q[front, 0] = q[front, 0] * 0.55 - 0.4 * k * depth
        q[:, 2] += np.clip(u[:, 2], 0, 1) ** 3 * 1.2 * k * peak
        q[:, 0] -= np.clip(u[:, 2], 0, 1) ** 3 * 0.8 * k * peak
        return q
    hm = ellipsoid((rx + 1.0 * k, ry + 1.0 * k, rz + 0.9 * k), (0, 0, 0), segs=14, rings=9, mat=mat, bone=hb, deform=deform)
    hm.translate(c + np.array([-0.4 * k, 0, 0.2 * k]))
    hm.make_two_sided()
    hm.detail = 1.2
    return [hm]


def hair(rig, sh, mat='hair', length=0.0, volume=1.0, style='crop'):
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    c = fa['center']; rx, ry, rz = fa['radii']
    out = []

    def deform(u, p):
        q = p.copy()
        low = u[:, 2] < 0.05
        q[low] = q[low] * np.array([1, 1, 0.2]) + np.array([0, 0, 0.05 * rz])
        front = (u[:, 0] > 0.55) & (u[:, 2] < 0.6)
        q[front, 0] -= 0.8 * k
        return q
    cap = ellipsoid((rx + 0.35 * k * volume, ry + 0.4 * k * volume, rz + 0.45 * k * volume), (0, 0, 0), segs=14, rings=8,
                    mat=mat, bone=hb, deform=deform)
    cap.translate(c + np.array([-0.3 * k, 0, 0.1 * k]))
    out.append(cap)
    if length > 0:
        # long strands: ribbons hanging from the back/sides of the head down the back
        for i, a in enumerate(np.linspace(-1.9, 1.9, 7)):
            if abs(a) < 0.3:
                continue
            st = c + np.array([(rx * 0.8) * math.cos(math.pi - a * 0.5) - 0.3 * k, ry * 0.95 * math.sin(a * 0.75), 0.6 * k])
            pts = [st + np.array([-0.4 * k * j, 0, -length * k * j / 4]) for j in range(5)]
            r = ribbon(pts, 2.4 * k, normal_hint=(math.cos(a * 0.6), math.sin(a * 0.6) * 0.3, 0), mat=mat,
                       bones=[hb, hb, hb, _bi(rig, 'Bip01 Neck'), _bi(rig, 'Bip01 Spine3')], tatter=0.4, seed=i)
            out.append(r)
    for m in out:
        m.detail = 1.0
    return out


# ---------------------------------------------------------------------------------------------- torso gear

def vest(rig, sh, mat='vest', z0=None, z1=None, grow=0.9, pouches=True, pouch_mat='pouch', collar=True, plates=True,
         plate_mat='plate'):
    J = rig.J
    k = _k(rig)
    z0 = J('Bip01 Spine')[2] - 0.5 * k if z0 is None else z0
    z1 = J('Bip01 L UpperArm')[2] - 0.6 * k if z1 is None else z1
    out = [shell(rig, sh, z0, z1, grow=grow, mat=mat, name='vest', rings=7, front=1.06, back=1.05)]
    if plates:
        zc = J('Bip01 Spine2')[2] + 1.0 * k
        b = _spine_bone_for_z(rig, zc)
        # plate sits on top of the vest front (find the vest surface depth at this height)
        vx = _shell_front_x(rig, sh, zc, grow)
        fr = box((1.2 * k, 9.0 * k, 9.5 * k), center=(vx + 0.45 * k, 0, zc), bevel=0.4 * k, mat=plate_mat, bone=b)
        fr.name = 'plate_front'
        out.append(fr)
    if pouches:
        zp = J('Bip01 Spine')[2] + 1.6 * k
        b = _spine_bone_for_z(rig, zp)
        for i, y in enumerate((-3.6, -1.2, 1.2, 3.6)):
            p = box((1.7 * k, 2.1 * k, 3.4 * k), center=(J('Bip01 Spine')[0] + 5.2 * k, y * k, zp), bevel=0.35 * k,
                    mat=pouch_mat, bone=b)
            p.name = 'pouch'
            out.append(p)
        # radio on the left chest
        zr = J('Bip01 Spine3')[2] - 0.5 * k
        r = box((1.5 * k, 1.8 * k, 3.2 * k), center=(J('Bip01 Spine3')[0] + 5.0 * k, 4.6 * k, zr), bevel=0.3 * k,
                mat=pouch_mat, bone=_spine_bone_for_z(rig, zr))
        r.name = 'radio'
        out.append(r)
        out.append(cylinder((J('Bip01 Spine3')[0] + 5.0 * k, 5.2 * k, zr + 1.5 * k),
                            (J('Bip01 Spine3')[0] + 4.6 * k, 5.4 * k, zr + 5.0 * k), 0.22 * k, 0.15 * k, segs=5,
                            mat='rubber', bone=_spine_bone_for_z(rig, zr)))
    if collar:
        zc = J('Bip01 Neck')[2]
        ang = np.linspace(0, 2 * math.pi, 13)
        pts = [np.array([J('Bip01 Neck')[0] + 3.0 * k * math.cos(a) - 0.3 * k, 3.1 * k * math.sin(a), zc - 0.6 * k]) for a in ang]
        col = tube(pts, 0.7 * k, segs=5, mat=mat, bones=_bi(rig, 'Bip01 Spine3'), cap_start=False, cap_end=False,
                   radii_b=1.0 * k, ref=np.array([0, 0, 1.0]))
        col.name = 'collar'
        out.append(col)
    return out


def belt(rig, sh, mat='belt', buckle_mat='metal', z=None, grow=0.45, pouches=2, pouch_mat='pouch', holster=False):
    J = rig.J
    k = _k(rig)
    z = J('Bip01 Pelvis')[2] + 0.6 * k if z is None else z
    out = [shell(rig, sh, z - 0.9 * k, z + 0.9 * k, grow=grow, mat=mat, name='belt', rings=3)]
    bk = box((0.5 * k, 2.0 * k, 1.5 * k), center=(J('Bip01 Pelvis')[0] + 4.3 * k + grow * k, 0, z), mat=buckle_mat,
             bone=_bi(rig, 'Bip01 Pelvis'), bevel=0.15 * k)
    bk.name = 'buckle'
    out.append(bk)
    for i in range(pouches):
        y = (5.2 if i % 2 == 0 else -5.2) * k
        p = box((2.0 * k, 1.6 * k, 2.6 * k), center=(J('Bip01 Pelvis')[0] + 1.6 * k - (i // 2) * 3.2 * k, y + (0.8 if y > 0 else -0.8) * k, z - 0.8 * k),
                bevel=0.3 * k, mat=pouch_mat, bone=_bi(rig, 'Bip01 Pelvis'))
        p.name = 'beltpouch'
        out.append(p)
    return out


def backpack(rig, sh, mat='pack', size=(3.5, 9.0, 10.0), tanks=0, tank_mat='metal'):
    J = rig.J
    k = _k(rig)
    zc = J('Bip01 Spine2')[2] + 1.0 * k
    b = _spine_bone_for_z(rig, zc)
    x = J('Bip01 Spine2')[0] - 4.6 * k - size[0] * 0.5 * k
    out = [box(np.array(size) * k, center=(x, 0, zc), bevel=0.8 * k, mat=mat, bone=b)]
    out[0].name = 'backpack'
    for i in range(tanks):
        y = (i - (tanks - 1) / 2) * 3.4 * k
        t = cylinder((x - 1.5 * k, y, zc - 5.0 * k), (x - 1.5 * k, y, zc + 7.0 * k), 1.5 * k, segs=10, mat=tank_mat, bone=b)
        t.name = 'tank'
        out.append(t)
    return out


def shoulder_pads(rig, sh, mat='plate', size=1.0, spikes=0, spike_mat='horn'):
    k = _k(rig)
    out = []
    for side, sg in (('L', 1), ('R', -1)):
        b = _bi(rig, 'Bip01 %s UpperArm' % side)
        c = rig.J('Bip01 %s UpperArm' % side) + np.array([0.0, sg * 0.9 * k, 0.9 * k])
        p = ellipsoid((3.0 * k * size, 2.8 * k * size, 2.4 * k * size), c, segs=10, rings=6, mat=mat, bone=b,
                      deform=lambda u, q: np.where(u[:, 2:3] < -0.2, q * np.array([1, 1, 0.3]) - np.array([0, 0, 0.0]), q))
        p.name = 'shoulderpad'
        out.append(p)
        for i in range(spikes):
            a = (i - (spikes - 1) / 2) * 0.6
            out.append(horn(c + np.array([math.sin(a) * 1.5 * k, sg * 1.2 * k, 1.6 * k * size]),
                            (math.sin(a) * 0.3, sg * 0.5, 1), 3.5 * k * size, 0.7 * k * size, mat=spike_mat, bone=b))
    return out


def knee_pads(rig, sh, mat='plate'):
    k = _k(rig)
    out = []
    for side, sg in (('L', 1), ('R', -1)):
        b = _bi(rig, 'Bip01 %s Calf' % side)
        c = rig.J('Bip01 %s Calf' % side) + np.array([2.2 * k, 0, -0.5 * k])
        p = ellipsoid((1.0 * k, 2.2 * k, 2.6 * k), c, segs=8, rings=5, mat=mat, bone=b)
        p.name = 'kneepad'
        out.append(p)
    return out


def bracers(rig, sh, mat='plate', grow=0.5):
    """Forearm guards / sleeves cuffs."""
    k = _k(rig)
    out = []
    for side in 'LR':
        b = _bi(rig, 'Bip01 %s Forearm' % side)
        e = rig.J('Bip01 %s Forearm' % side); w = rig.J('Bip01 %s Hand' % side)
        p0 = e + (w - e) * 0.3; p1 = e + (w - e) * 0.92
        t = tube([p0, p1], [2.0 * k + grow * k, 1.45 * k + grow * k], segs=9, mat=mat, bones=b, cap_start=False, cap_end=False)
        t.name = 'bracer'
        t.make_two_sided()
        out.append(t)
    return out


def sleeve_cuffs(rig, sh, mat='cloth', at=0.85, part='Forearm', grow=0.35):
    k = _k(rig)
    out = []
    for side in 'LR':
        b = _bi(rig, 'Bip01 %s %s' % (side, part))
        a = rig.J('Bip01 %s %s' % (side, part))
        child = {'UpperArm': 'Forearm', 'Forearm': 'Hand', 'Thigh': 'Calf', 'Calf': 'Foot'}[part]
        c = rig.J('Bip01 %s %s' % (side, child))
        p = a + (c - a) * at
        r = {'UpperArm': 2.1, 'Forearm': 1.45, 'Thigh': 3.0, 'Calf': 1.9}[part] * k + grow * k
        t = tube([p - (c - a) * 0.04, p + (c - a) * 0.04], [r, r * 0.97], segs=10, mat=mat, bones=b, cap_start=False,
                 cap_end=False)
        t.make_two_sided()
        out.append(t)
    return out


def coat_skirt(rig, sh, mat='coat', length=0.75, flare=0.3, split=True, segs=4):
    """Long coat lower part as 4 panels following the thighs / pelvis (front L/R, back L/R)."""
    k = _k(rig)
    J = rig.J
    out = []
    z0 = J('Bip01 Pelvis')[2] - 0.5 * k
    L = length * (J('Bip01 Pelvis')[2] - (-36.0))
    for side, sg in (('L', 1), ('R', -1)):
        th = _bi(rig, 'Bip01 %s Thigh' % side); cf = _bi(rig, 'Bip01 %s Calf' % side)
        for fb, x0 in (('f', 4.2), ('b', -4.6)):
            pts = [np.array([x0 * k + (0.3 if fb == 'f' else -0.6) * k * j, sg * (3.6 + flare * j * 1.3) * k, z0 - L * j / 4]) for j in range(5)]
            bones = [_bi(rig, 'Bip01 Pelvis'), th, th, th if j < 3 else cf, cf]
            bones = [_bi(rig, 'Bip01 Pelvis'), th, th, cf, cf]
            r = ribbon(pts, 7.0 * k, normal_hint=(1 if fb == 'f' else -1, 0, 0), mat=mat, bones=bones, two_sided=True,
                       tatter=0.25, seed=hash((side, fb)) % 1000, width_dir=(0, 1, 0))
            r.name = 'coat_%s%s' % (fb, side)
            out.append(r)
    return out


def cape(rig, sh, mat='cape', length=0.8, width=13.0, tatter=0.3, bones=None):
    k = _k(rig)
    J = rig.J
    top = J('Bip01 Spine3') + np.array([-4.2 * k, 0, 2.5 * k])
    L = length * (top[2] + 36.0)
    pts = [top + np.array([-1.2 * k * j - 0.4 * k * j * j, 0, -L * j / 5]) for j in range(6)]
    if bones is None:
        sb = _bi(rig, 'Bip01 Spine3')
        bones = [sb, sb, _bi(rig, 'Bip01 Spine2'), _bi(rig, 'Bip01 Spine1'), _bi(rig, 'Bip01 Spine'), _bi(rig, 'Bip01 Pelvis')]
    w = [width * 0.75 * k, width * k, width * 1.08 * k, width * 1.15 * k, width * 1.22 * k, width * 1.28 * k]
    r = ribbon(pts, w, normal_hint=(-1, 0, 0), mat=mat, bones=bones, two_sided=True, tatter=tatter, seed=7,
               width_dir=(0, 1, 0))
    r.name = 'cape'
    return [r]


def shirt_flaps(rig, sh, mat='shirt', n=5, length=6.0, seed=3, z=None):
    """Torn hanging shirt strips around the lower torso (zombie clothing)."""
    k = _k(rig)
    J = rig.J
    rng = np.random.default_rng(seed)
    z = J('Bip01 Spine')[2] - 0.5 * k if z is None else z
    out = []
    from .body import torso_mesh
    for i in range(n):
        a = rng.uniform(-math.pi, math.pi)
        dx, dy = math.cos(a), math.sin(a)
        r = np.array([dx * 4.6 * k * (1.0 if dx > 0 else 1.05), dy * 6.6 * k, 0])
        top = np.array([J('Bip01 Spine')[0], 0, z]) + r * 1.02
        ln = length * k * rng.uniform(0.6, 1.2)
        pts = [top + np.array([dx * 0.25 * k * j, dy * 0.25 * k * j, -ln * j / 3]) for j in range(4)]
        b = _bi(rig, 'Bip01 Pelvis')
        rb = ribbon(pts, rng.uniform(1.8, 3.2) * k, normal_hint=(dx, dy, 0), mat=mat, bones=b, two_sided=True,
                    tatter=0.5, seed=i + seed)
        rb.name = 'flap'
        out.append(rb)
    return out


def ribs(rig, sh, mat='bone', count=4, exposed_side=1):
    """Exposed rib bones on one side of the chest (zombie gore)."""
    k = _k(rig)
    J = rig.J
    b = _bi(rig, 'Bip01 Spine2')
    out = []
    for i in range(count):
        z = J('Bip01 Spine1')[2] + (1.0 + i * 1.5) * k
        ang = np.linspace(0.25, 1.1, 5) * exposed_side
        pts = [np.array([J('Bip01 Spine2')[0] + 4.2 * k * math.cos(a), 6.0 * k * math.sin(a), z - 0.4 * k * j]) for j, a in enumerate(ang)]
        t = tube(pts, 0.32 * k, segs=5, mat=mat, bones=b if z > J('Bip01 Spine2')[2] else _bi(rig, 'Bip01 Spine1'))
        t.name = 'rib'
        out.append(t)
    return out


def horns(rig, sh, mat='horn', length=6.0, radius=1.2, curve=(0.0, 0.0, -2.0), spread=1.0, pairs=1, forward=0.3):
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    c = fa['center']; rx, ry, rz = fa['radii']
    out = []
    for p in range(pairs):
        for sg in (1, -1):
            base = c + np.array([0.6 * k - p * 1.6 * k, sg * ry * 0.65, rz * 0.65 - p * 0.8 * k])
            d = np.array([forward - 0.3 * p, sg * 0.7 * spread, 0.85])
            cv = np.array([curve[0] - p, sg * curve[1], curve[2]]) * k
            out.append(horn(base, d, length * k * (1 - 0.25 * p), radius * k * (1 - 0.2 * p), curve=cv, mat=mat, bone=hb))
    return out


def spikes(rig, sh, mat='horn', bone='Bip01 Spine3', n=5, length=3.5, radius=0.7, spread=(-6, 6), z_range=None,
           side='back', seed=1):
    """Row of spikes along the back (or shoulders) bound to spine bones by height."""
    k = _k(rig)
    J = rig.J
    rng = np.random.default_rng(seed)
    out = []
    zs = np.linspace(*(z_range or (J('Bip01 Spine1')[2], J('Bip01 Spine3')[2] + 2.5 * k)), n)
    for i, z in enumerate(zs):
        b = _spine_bone_for_z(rig, z)
        base = np.array([J('Bip01 Spine2')[0] - 4.0 * k, 0, z])
        d = np.array([-1.0, rng.uniform(-0.15, 0.15), 0.55])
        out.append(horn(base, d, length * k * rng.uniform(0.8, 1.25), radius * k, curve=(0, 0, 0.8 * k), mat=mat, bone=b))
    return out


def crystals(rig, sh, mat='crystal', where=(('Bip01 Spine3', (-3.5, 3.0, 2.0)), ('Bip01 L UpperArm', (0, 1.5, 0.8))),
             size=1.0, seed=5):
    """Clusters of crystal shards (hexagonal prisms with pointed tips)."""
    k = _k(rig)
    rng = np.random.default_rng(seed)
    out = []
    for bname, off in where:
        b = _bi(rig, bname)
        base = rig.J(bname) + np.array(off) * k
        for j in range(3):
            d = np.array([rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6), 1.0])
            d = d / np.linalg.norm(d)
            if off[0] < 0:
                d[0] -= 0.6
            L = rng.uniform(2.5, 4.5) * k * size
            r = rng.uniform(0.5, 0.9) * k * size
            pts = [base, base + d * L * 0.75, base + d * L]
            out.append(tube(pts, [r, r, 0.02 * k], segs=6, mat=mat, bones=b, cap_start=True, cap_end=False))
    return out


def tail(rig, sh, mat='skin', length=24.0, radius=2.2, bones=None, curve=1.0):
    """Tail mesh along extra bones named 'Tail0'..'TailN' (must exist in the rig as lower extras)."""
    k = _k(rig)
    names = [n for n in rig.names if n.startswith('Tail')]
    if not names:
        raise ValueError('tail accessory needs rig extras Tail0..TailN (see rig_presets.tail_extras)')
    pts = [rig.J(n) for n in names]
    last = pts[-1] + (pts[-1] - pts[-2])
    pts = pts + [last]
    bs = [rig.index[n] for n in names] + [rig.index[names[-1]]]
    rad = np.linspace(radius, radius * 0.15, len(pts)) * k
    return [tube(pts, rad, segs=8, mat=mat, bones=bs, cap_start=True, cap_end=True, name='tail')]


def tail_extras(rig_spec_height=72.0, n=4, length=26.0, droop=0.6):
    """RigSpec extras for a tail (lower extras, parented to the pelvis -> driven by the gait)."""
    k = rig_spec_height / 72.0
    z = -36.0 + 0.55 * rig_spec_height
    ex = []
    prev = 'Bip01 Pelvis'
    for i in range(n):
        x = -4.0 * k - length * k * (i + 1) / n * 0.95
        zz = z - length * k * droop * ((i + 1) / n) ** 1.5 * 0.5
        nm = 'Tail%d' % i
        ex.append(dict(name=nm, parent=prev, pos=(x + length * k / n * 0.95, 0, z - (length * k * droop * (i / n) ** 1.5 * 0.5)), lower=True))
        prev = nm
    return ex


def glow_eyes(rig, sh, mat='eyeglow', size=0.55):
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    out = []
    for side in ('eye_L', 'eye_R'):
        e = ellipsoid((0.3 * k * size * 2, 0.55 * k * size * 2, 0.4 * k * size * 2), fa[side] + np.array([0.15 * k, 0, 0]),
                      segs=8, rings=5, mat=mat, bone=hb)
        e.name = 'eyeglow'
        e.no_hitbox = True
        out.append(e)
    return out


def jaw_teeth(rig, sh, mat='teeth', n=6, size=1.0):
    fa = face_anchor(rig, sh)
    k = fa['k']
    hb = _bi(rig, 'Bip01 Head')
    m = fa['mouth']
    out = []
    for i in range(n):
        y = (i - (n - 1) / 2) * 0.45 * k
        for up in (1, -1):
            base = m + np.array([0.15 * k, y, 0.35 * k * up])
            out.append(horn(base, (0.2, 0, -up), 0.9 * k * size, 0.18 * k, mat=mat, bone=hb, segs=4, steps=2))
    return out


def chain(rig, sh, mat='metal', points=None, bones=None, link=1.0):
    """Chain as a sequence of small flat links along given rest points (bound per point)."""
    k = _k(rig)
    out = []
    P = np.asarray(points, float)
    for i in range(len(P) - 1):
        a, b = P[i], P[i + 1]
        n = max(2, int(np.linalg.norm(b - a) / (1.2 * k * link)))
        for j in range(n):
            c = a + (b - a) * (j + 0.5) / n
            d = (b - a) / np.linalg.norm(b - a)
            up = np.array([0, 0, 1.0]) if abs(d[2]) < 0.9 else np.array([1.0, 0, 0])
            R = look_frame(d, up)
            if j % 2:
                R = R @ rot_x(math.pi / 2)
            lk = ellipsoid((0.75 * k * link, 0.42 * k * link, 0.16 * k * link), (0, 0, 0), segs=6, rings=3, mat=mat,
                           bone=bones[i] if bones is not None else 0, R=R)
            lk.translate(c)
            out.append(lk)
    m = Mesh.merge(out, name='chain')
    m.size = (8.0 * k, 4.0 * k * len(P))
    return [m]


def plates_on(rig, sh, mat='plate', items=()):
    """Generic boxes bound to bones: items = [(bone, center(3, model space), size(3), rot_deg(3)), ...]."""
    k = _k(rig)
    out = []
    for bone, c, s, r in items:
        m = box(np.array(s) * k, center=(0, 0, 0), bevel=0.25 * k, mat=mat, bone=_bi(rig, bone))
        R = rot_z(math.radians(r[2])) @ rot_y(math.radians(r[1])) @ rot_x(math.radians(r[0]))
        m.transform(R, np.array(c) * k)
        out.append(m)
    return out


def wraps(rig, sh, mat='bandage', where=(('L', 'Forearm', 0.4, 0.9),), grow=0.25):
    """Bandage wraps (spiral bands) around limb segments."""
    k = _k(rig)
    out = []
    for side, part, a0, a1 in where:
        b = _bi(rig, 'Bip01 %s %s' % (side, part))
        child = {'UpperArm': 'Forearm', 'Forearm': 'Hand', 'Thigh': 'Calf', 'Calf': 'Foot'}[part]
        p = rig.J('Bip01 %s %s' % (side, part)); c = rig.J('Bip01 %s %s' % (side, child))
        r0 = {'UpperArm': 2.2, 'Forearm': 1.75, 'Thigh': 3.4, 'Calf': 2.4}[part] * k + grow * k
        r1 = {'UpperArm': 1.8, 'Forearm': 1.3, 'Thigh': 2.6, 'Calf': 1.5}[part] * k + grow * k
        pts = [p + (c - p) * t for t in np.linspace(a0, a1, 5)]
        rr = [r0 + (r1 - r0) * t for t in np.linspace(a0, a1, 5)]
        t = tube(pts, rr, segs=10, mat=mat, bones=b, cap_start=False, cap_end=False)
        t.make_two_sided()
        out.append(t)
    return out


def emblem_patch(rig, sh, mat='patch', where='arm_L'):
    k = _k(rig)
    if where in ('arm_L', 'arm_R'):
        side = where[-1]; sg = 1 if side == 'L' else -1
        b = _bi(rig, 'Bip01 %s UpperArm' % side)
        c = rig.J('Bip01 %s UpperArm' % side) + np.array([0.0, sg * 2.35 * k, -3.4 * k])
        m = box((1.9 * k, 0.25 * k, 2.2 * k), center=c, mat=mat, bone=b)
        m.name = 'patch'
        return [m]
    raise ValueError(where)



# ============================================================================================ wings / extra limbs
# Upper extras (parented to the spine, NOT the pelvis) -> driven by the upper-body sequences, so they move
# in every in-game pose. anims.AnimBuilder animates bones named Wing_* (flap / glide / fold in deaths) and
# XLimb_* (sway / strike / curl in deaths) automatically; Style(extra_bone_anim=fn) can add more.

def _base_rig(spec_or_height):
    """Rig without extras for a RigSpec (exact joint positions) or a bare height (default proportions)."""
    from .rig_cs import Rig, RigSpec
    if isinstance(spec_or_height, RigSpec):
        rs = RigSpec(**{kk: v for kk, v in spec_or_height.__dict__.items() if kk != 'extras'})
    else:
        rs = RigSpec(height=float(spec_or_height))
    return Rig(rs)


def wing_extras(rig_spec_height=72.0, span=1.0, parent='Bip01 Spine3', up=1.0, back=1.0):
    """RigSpec extras for a pair of wings: Wing_L0 (shoulder blade) -> Wing_L1 (wrist) -> Wing_L2 (tip)
    and the mirrored R chain. span scales the reach (1.0 ~ 0.9 x body height wing span).
    rig_spec_height: the RigSpec itself (preferred: exact joints) or its height.
        rs = RigSpec.preset('boss'); rs.extras = wing_extras(rs)"""
    R = _base_rig(rig_spec_height)
    k = R.H / 72.0
    bk = R.spec.bulk ** 0.5
    ps = R.J(parent)
    ex = []
    for side, sg in (('L', 1), ('R', -1)):
        p0 = ps + np.array([-4.2 * k * back * bk, sg * 2.8 * k * bk, 1.0 * k])
        p1 = p0 + np.array([-5.0 * k * back, sg * 13.0 * k * span, 9.0 * k * up * span])
        p2 = p1 + np.array([-4.0 * k * back, sg * 15.0 * k * span, -2.0 * k * span])
        ex += [dict(name='Wing_%s0' % side, parent=parent, pos=tuple(p0)),
               dict(name='Wing_%s1' % side, parent='Wing_%s0' % side, pos=tuple(p1)),
               dict(name='Wing_%s2' % side, parent='Wing_%s1' % side, pos=tuple(p2))]
    return ex


def wings(rig, sh, mat='wing', bone_mat='bone', fingers=3, droop=1.0, tatter=0.25, seed=9, rows=6):
    """Membrane wings (bat / demon style) on the Wing_* extras: a leading-edge bone strut, `fingers`
    spines fanning from the wrist and a two-sided membrane whose trailing edge droops toward the hips.
    Set the membrane material 'masked' or use a 'layers' material with holes for torn wings."""
    k = _k(rig)
    rng = np.random.default_rng(seed)
    out = []
    for side, sg in (('L', 1), ('R', -1)):
        names = ['Wing_%s%d' % (side, i) for i in range(3)]
        if not all(n in rig.index for n in names):
            raise ValueError('wings accessory needs rig extras %s (accessories.wing_extras)' % names)
        P0, P1, P2 = [rig.J(n) for n in names]
        b0, b1, b2 = [rig.index[n] for n in names]
        # leading edge polyline (shoulder -> wrist -> tip) and trailing edge points
        lead = [P0 + (P1 - P0) * t for t in np.linspace(0, 1, 4)] + [P1 + (P2 - P1) * t for t in np.linspace(0, 1, 4)[1:]]
        lead_b = [b0, b0, b0, b1, b1, b1, b1]
        low_z = rig.J('Bip01 Spine')[2] - 2.0 * k
        trail = []
        for i, p in enumerate(lead):
            u = i / (len(lead) - 1)
            depth = (p[2] - low_z) * (0.95 - 0.55 * u ** 1.5) * droop
            scallop = 1.0 - 0.18 * abs(math.sin(u * math.pi * fingers))
            q = p + np.array([-2.0 * k * (1 - u), 0, -depth * scallop])
            if tatter > 0 and 0 < i < len(lead) - 1:
                q = q + np.array([0, 0, depth * rng.uniform(0, tatter * 0.35)])
            trail.append(q)
        vs, uvs, bb = [], [], []
        for i in range(len(lead)):
            for j in range(rows):
                v = j / (rows - 1)
                vs.append(lead[i] * (1 - v) + trail[i] * v)
                uvs.append((i / (len(lead) - 1), 1.0 - v))
                bb.append(lead_b[i] if v < 0.85 or i > 0 else b0)
        f = []
        for i in range(len(lead) - 1):
            for j in range(rows - 1):
                a = i * rows + j; b = (i + 1) * rows + j
                tri = [(a, b, b + 1), (a, b + 1, a + 1)]
                f += tri if sg > 0 else [(x, z, y) for x, y, z in tri]
        span_len = float(sum(np.linalg.norm(np.diff(np.array(lead), axis=0), axis=1)))
        m = Mesh(np.array(vs), np.array(f), np.array(uvs), None, np.array(bb), mat,
                 size=(span_len, float(np.max([np.linalg.norm(a - b) for a, b in zip(lead, trail)]))), name='wing')
        m.make_two_sided()
        m.no_hitbox = True
        out.append(m)
        # bones: leading edge strut + finger spines
        strut = tube([P0, P1, P2], [0.75 * k, 0.5 * k, 0.12 * k], segs=6, mat=bone_mat, bones=[b0, b1, b1])
        strut.name = 'wingbone'
        strut.no_hitbox = True
        out.append(strut)
        for fi in range(fingers):
            i = 3 + int(round((fi + 1) * 3 / (fingers + 1)))
            tgt = trail[min(i, len(trail) - 1)] * 0.92 + lead[min(i, len(lead) - 1)] * 0.08
            fg = tube([P1, (P1 + tgt) / 2 + np.array([0, 0, 0.6 * k]), tgt], [0.35 * k, 0.25 * k, 0.08 * k], segs=5,
                      mat=bone_mat, bones=b1, cap_end=False)
            fg.name = 'wingbone'
            fg.no_hitbox = True
            out.append(fg)
        claw = horn(P1, (0.3, sg * 0.2, 1.0), 2.2 * k, 0.35 * k, curve=(0.8 * k, 0, 0), mat=bone_mat, bone=b1)
        claw.no_hitbox = True
        out.append(claw)
    return out


def limb_extras(rig_spec_height=72.0, pairs=2, parent='Bip01 Spine2', reach=1.0, prefix='XLimb', front=0.0,
                height=0.0, spread=1.0):
    """RigSpec extras for extra limbs (spider legs on the back, extra arms, tentacles): per limb
    <prefix>_<L|R><n>_0 (root) -> _1 (knee) -> _2 (foot/claw tip). pairs = limbs per side.
    rig_spec_height: the RigSpec (preferred) or its height. front > 0 moves the roots toward the chest
    (extra arms), height raises them (units at 72)."""
    R = _base_rig(rig_spec_height)
    k = R.H / 72.0
    bk = R.spec.bulk ** 0.5
    pp = R.J(parent)
    ex = []
    for n in range(pairs):
        a = (n - (pairs - 1) / 2.0)            # spread the roots along the back
        for side, sg in (('L', 1), ('R', -1)):
            base = '%s_%s%d' % (prefix, side, n)
            p0 = pp + np.array([(-3.5 * bk + front) * k - a * 2.0 * k, sg * 3.2 * k * bk, height * k - a * 3.0 * k])
            dirn = np.array([-0.35 - 0.5 * a + front * 0.1, sg * 1.0 * spread, 0.0])
            dirn /= np.linalg.norm(dirn)
            p1 = p0 + dirn * 12.0 * k * reach + np.array([0, 0, 9.0 * k * reach])
            p2 = p1 + dirn * 10.0 * k * reach + np.array([0, 0, -16.0 * k * reach])
            ex += [dict(name=base + '_0', parent=parent, pos=tuple(p0)),
                   dict(name=base + '_1', parent=base + '_0', pos=tuple(p1)),
                   dict(name=base + '_2', parent=base + '_1', pos=tuple(p2))]
    return ex


def extra_limbs(rig, sh, mat='skin', claw_mat='claw', prefix='XLimb', radius=1.1, claw=2.5, joint_mat=None):
    """Segmented limbs along every <prefix>_* chain created by limb_extras (chitin legs, bony arms)."""
    k = _k(rig)
    out = []
    roots = sorted(set(n[:-2] for n in rig.names if n.startswith(prefix + '_') and n.endswith('_0')))
    if not roots:
        raise ValueError('extra_limbs needs rig extras from accessories.limb_extras(prefix=%r)' % prefix)
    for base in roots:
        P = [rig.J(base + '_%d' % i) for i in range(3)]
        B = [rig.index[base + '_%d' % i] for i in range(3)]
        tip = P[2] + (P[2] - P[1]) / max(np.linalg.norm(P[2] - P[1]), 1e-6) * claw * k
        seg1 = tube([P[0], (P[0] + P[1]) / 2, P[1]], [radius * k, radius * 1.15 * k, radius * 0.8 * k], segs=7,
                    mat=mat, bones=[B[0], B[0], B[0]])
        seg2 = tube([P[1], (P[1] + P[2]) / 2, P[2]], [radius * 0.8 * k, radius * 0.7 * k, radius * 0.45 * k], segs=7,
                    mat=mat, bones=[B[1], B[1], B[1]])
        joint = ellipsoid((radius * 1.05 * k,) * 3, P[1], segs=8, rings=5, mat=joint_mat or mat, bone=B[1])
        c = horn(P[2], tip - P[2], claw * k, radius * 0.45 * k, mat=claw_mat, bone=B[2])
        for m, nm in ((seg1, 'xlimb'), (seg2, 'xlimb'), (joint, 'xlimb_joint'), (c, 'xlimb_claw')):
            m.name = nm
            m.no_hitbox = True
            out.append(m)
    return out

ACCESSORIES = {
    'helmet': helmet, 'goggles': goggles, 'gasmask': gasmask, 'hood': hood, 'hair': hair, 'vest': vest, 'belt': belt,
    'backpack': backpack, 'shoulder_pads': shoulder_pads, 'knee_pads': knee_pads, 'bracers': bracers,
    'sleeve_cuffs': sleeve_cuffs, 'coat_skirt': coat_skirt, 'cape': cape, 'shirt_flaps': shirt_flaps, 'ribs': ribs,
    'horns': horns, 'spikes': spikes, 'crystals': crystals, 'tail': tail, 'glow_eyes': glow_eyes,
    'jaw_teeth': jaw_teeth, 'chain': chain, 'plates_on': plates_on, 'wraps': wraps, 'emblem_patch': emblem_patch,
    'shell': shell, 'wings': wings, 'extra_limbs': extra_limbs,
}
