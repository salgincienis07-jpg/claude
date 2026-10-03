"""Procedural mesh primitives for GoldSrc studio models.

Mesh = one UV island + one material (painted later through paint.py).
  v    (n,3)  rest-pose model-space positions (engine space: +X fwd, +Y left, +Z up)
  n    (n,3)  normals (outward)
  uv   (n,2)  island-local UV in [0,1] (v=0 bottom, v=1 top, like the BMP)
  f    (m,3)  triangles, counter-clockwise seen from outside
  bone (n,)   rigid bone index per vertex (GoldSrc supports exactly one bone per vertex)
  mat         material name (key into the painter table)
  size        (U_len, V_len) approximate world-unit extent of the UV domain (for atlas packing)
  attrs       dict of per-vertex float arrays that painters may use (e.g. 't' along a tube)

All builders return Mesh objects; combine with Mesh.merge() only when they share material/island.
"""
import math
import numpy as np

from .mathx import look_frame, rot_between, axis_angle


class Mesh:
    def __init__(self, v, f, uv=None, n=None, bone=0, mat='default', size=(1.0, 1.0), name='', two_sided=False):
        self.v = np.asarray(v, dtype=np.float64).reshape(-1, 3)
        self.f = np.asarray(f, dtype=np.int64).reshape(-1, 3)
        self.uv = np.zeros((len(self.v), 2)) if uv is None else np.asarray(uv, dtype=np.float64).reshape(-1, 2)
        if np.isscalar(bone):
            self.bone = np.full(len(self.v), int(bone), dtype=np.int64)
        else:
            self.bone = np.asarray(bone, dtype=np.int64).reshape(-1)
        self.mat = mat
        self.size = tuple(size)
        self.name = name
        self.attrs = {}
        self.texture = None          # filled by atlas packing: texture file name
        self.atlas_uv = None         # filled by atlas packing: final uv in the texture
        self.island = None           # (tex_index, x0, y0, w, h) pixel rect
        self.detail = 1.0            # texel density multiplier for atlas packing
        if n is None:
            self.recompute_normals()
        else:
            self.n = np.asarray(n, dtype=np.float64).reshape(-1, 3)
        if two_sided:
            self.make_two_sided()

    # ------------------------------------------------------------------ basic ops
    def copy(self):
        m = Mesh(self.v.copy(), self.f.copy(), self.uv.copy(), self.n.copy(), self.bone.copy(), self.mat,
                 self.size, self.name)
        m.attrs = {k: v.copy() for k, v in self.attrs.items()}
        m.detail = self.detail
        return m

    def recompute_normals(self, smooth=True):
        v, f = self.v, self.f
        fn = np.cross(v[f[:, 1]] - v[f[:, 0]], v[f[:, 2]] - v[f[:, 0]])
        n = np.zeros_like(v)
        if smooth:
            # weld by position so UV seams do not show as lighting seams
            key = np.round(v * 1000).astype(np.int64)
            _, inv = np.unique(key, axis=0, return_inverse=True)
            inv = inv.reshape(-1)
            acc = np.zeros((inv.max() + 1, 3))
            for k in range(3):
                np.add.at(acc, inv[f[:, k]], fn)
            n = acc[inv]
        else:
            for k in range(3):
                np.add.at(n, f[:, k], fn)
        ln = np.linalg.norm(n, axis=1, keepdims=True)
        ln[ln < 1e-12] = 1
        self.n = n / ln
        return self

    def transform(self, R=None, t=(0, 0, 0), scale=None):
        R = np.eye(3) if R is None else np.asarray(R, dtype=np.float64)
        if scale is not None:
            S = np.diag(np.broadcast_to(np.asarray(scale, dtype=np.float64), (3,)))
            M = R @ S
            self.v = self.v @ M.T + np.asarray(t)
            Ninv = np.linalg.inv(M).T
            nn = self.n @ Ninv.T
            self.n = nn / np.maximum(np.linalg.norm(nn, axis=1, keepdims=True), 1e-12)
            if np.linalg.det(M) < 0:
                self.f = self.f[:, ::-1].copy()
        else:
            self.v = self.v @ R.T + np.asarray(t)
            self.n = self.n @ R.T
        return self

    def translate(self, t):
        self.v = self.v + np.asarray(t)
        return self

    def set_bone(self, b):
        self.bone = np.full(len(self.v), int(b), dtype=np.int64)
        return self

    def flip(self):
        self.f = self.f[:, ::-1].copy()
        self.n = -self.n
        return self

    def make_two_sided(self):
        nv = len(self.v)
        back = Mesh(self.v.copy(), self.f[:, ::-1].copy(), self.uv.copy(), -self.n.copy(), self.bone.copy())
        self.f = np.vstack([self.f, back.f + nv])
        self.v = np.vstack([self.v, back.v])
        self.n = np.vstack([self.n, back.n])
        self.uv = np.vstack([self.uv, back.uv])
        self.bone = np.concatenate([self.bone, back.bone])
        for k in list(self.attrs):
            self.attrs[k] = np.concatenate([self.attrs[k], self.attrs[k]])
        # mark the added back side: texture baking lets the front faces win the shared texels
        self.attrs['_back'] = np.concatenate([np.zeros(nv), np.ones(nv)])
        return self

    def mirrored(self, axis=1, bone_map=None):
        """Mirror across a plane (axis index, default Y=left/right). Winding is fixed so it stays outward."""
        m = self.copy()
        m.v[:, axis] *= -1
        m.n[:, axis] *= -1
        m.f = m.f[:, ::-1].copy()
        if bone_map is not None:
            m.bone = np.array([bone_map.get(int(b), int(b)) for b in m.bone], dtype=np.int64)
        return m

    @staticmethod
    def merge(meshes, mat=None, name=''):
        meshes = [m for m in meshes if m is not None and len(m.f)]
        vs, fs, uvs, ns, bs = [], [], [], [], []
        off = 0
        keys = set(meshes[0].attrs) if meshes else set()
        for m in meshes:
            keys &= set(m.attrs)
        attrs = {k: [] for k in keys}
        for m in meshes:
            vs.append(m.v); fs.append(m.f + off); uvs.append(m.uv); ns.append(m.n); bs.append(m.bone)
            for k in keys:
                attrs[k].append(m.attrs[k])
            off += len(m.v)
        out = Mesh(np.vstack(vs), np.vstack(fs), np.vstack(uvs), np.vstack(ns), np.concatenate(bs),
                   mat or meshes[0].mat, meshes[0].size, name or meshes[0].name)
        for k in keys:
            out.attrs[k] = np.concatenate(attrs[k])
        return out

    def area(self):
        v, f = self.v, self.f
        return 0.5 * np.linalg.norm(np.cross(v[f[:, 1]] - v[f[:, 0]], v[f[:, 2]] - v[f[:, 0]]), axis=1).sum()

    def bounds(self):
        return self.v.min(0), self.v.max(0)

    def smd_triangles(self):
        """Yield (texture_name, [(bone, pos, nrm, uv) x3]) for the SMD writer."""
        uv = self.atlas_uv if self.atlas_uv is not None else self.uv
        tex = self.texture or (self.mat + '.bmp')
        for tri in self.f:
            yield tex, [(int(self.bone[i]), self.v[i], self.n[i], uv[i]) for i in tri]


# ---------------------------------------------------------------------------------------------------
# helpers

def _grid_faces(rows, cols, wrap=False):
    """Quad grid faces for (rows x cols) vertices. If wrap, the last column connects to... (we
    duplicate the seam column instead, so wrap is only used for caps). CCW with u to the right and
    v upward when the surface normal points to the viewer."""
    f = []
    for r in range(rows - 1):
        for c in range(cols - 1):
            a = r * cols + c
            b = a + 1
            d = a + cols
            e = d + 1
            f.append((a, b, e))
            f.append((a, e, d))
    return np.array(f, dtype=np.int64).reshape(-1, 3)


def _orient_outward(mesh, center=None):
    """Flip faces so normals point away from center (for closed convex-ish shapes)."""
    v, f = mesh.v, mesh.f
    c = v.mean(0) if center is None else np.asarray(center)
    fn = np.cross(v[f[:, 1]] - v[f[:, 0]], v[f[:, 2]] - v[f[:, 0]])
    fc = v[f].mean(1)
    if np.sum(np.einsum('ij,ij->i', fn, fc - c)) < 0:
        mesh.f = mesh.f[:, ::-1].copy()
    return mesh


# ---------------------------------------------------------------------------------------------------
# primitives

def box(size=(1, 1, 1), center=(0, 0, 0), bevel=0.0, mat='default', bone=0, segs=1):
    """Axis-aligned box (optionally with chamfered edges). UV: 6 faces packed 3x2 in the island."""
    sx, sy, sz = [s * 0.5 for s in size]
    b = min(bevel, sx * 0.9, sy * 0.9, sz * 0.9)
    faces = [  # normal, u axis, v axis
        ((1, 0, 0), (0, 1, 0), (0, 0, 1)),
        ((-1, 0, 0), (0, -1, 0), (0, 0, 1)),
        ((0, 1, 0), (-1, 0, 0), (0, 0, 1)),
        ((0, -1, 0), (1, 0, 0), (0, 0, 1)),
        ((0, 0, 1), (0, 1, 0), (-1, 0, 0)),
        ((0, 0, -1), (0, 1, 0), (1, 0, 0)),
    ]
    half = np.array([sx, sy, sz])
    vs, fs, uvs, ns = [], [], [], []
    for k, (nn, uu, vv) in enumerate(faces):
        nn = np.array(nn, float); uu = np.array(uu, float); vv = np.array(vv, float)
        hu = abs(uu @ half); hv = abs(vv @ half); hn = abs(nn @ half)
        cu, cv = k % 3, k // 3
        base = len(vs)
        n = segs + 1
        for j in range(n):
            for i in range(n):
                a = -1 + 2 * i / segs
                bb = -1 + 2 * j / segs
                pu = a * (hu - b)
                pv = bb * (hv - b)
                p = nn * hn + uu * pu + vv * pv
                vs.append(p)
                ns.append(nn)
                uvs.append(((cu + 0.04 + 0.92 * (i / segs)) / 3.0, (cv + 0.04 + 0.92 * (j / segs)) / 2.0))
        fs += [tuple(x + base for x in t) for t in _grid_faces(n, n)]
    m = Mesh(np.array(vs) + np.asarray(center), fs, uvs, ns, bone, mat,
             size=(3 * max(size[0], size[1]), 2 * max(size[1], size[2])))
    if b > 0:
        # chamfer: fill the gaps between faces with strips (cheap approach: add bevel faces by convex hull)
        from scipy.spatial import ConvexHull
        pts = m.v - np.asarray(center)
        hull = ConvexHull(pts)
        tris = hull.simplices
        hm = Mesh(pts[np.unique(tris)], [], bone=bone, mat=mat)
        # rebuild as hull mesh with box-projected UVs
        hv = pts
        hf = tris.copy()
        # scipy hull simplices have arbitrary winding: orient EVERY face outward (the hull is convex)
        fn = np.cross(hv[hf[:, 1]] - hv[hf[:, 0]], hv[hf[:, 2]] - hv[hf[:, 0]])
        inward = np.einsum('ij,ij->i', fn, hv[hf].mean(1)) < 0
        hf[inward] = hf[inward][:, ::-1]
        hm = Mesh(hv, hf, None, None, bone, mat, size=m.size)
        hm = flat_shaded(hm)
        hm.uv = box_project_uv(hm.v, hm.n, half)
        hm.translate(center)
        return hm
    return m


def flat_shaded(m):
    """Unweld so every face has its own vertices + face normal (hard edges)."""
    v = m.v[m.f].reshape(-1, 3)
    uv = m.uv[m.f].reshape(-1, 2)
    bone = m.bone[m.f].reshape(-1)
    f = np.arange(len(v)).reshape(-1, 3)
    fn = np.cross(v[f[:, 1]] - v[f[:, 0]], v[f[:, 2]] - v[f[:, 0]])
    fn /= np.maximum(np.linalg.norm(fn, axis=1, keepdims=True), 1e-12)
    n = np.repeat(fn, 3, axis=0)
    out = Mesh(v, f, uv, n, bone, m.mat, m.size, m.name)
    for k, a in m.attrs.items():
        out.attrs[k] = a[m.f].reshape(-1)
    return out


def box_project_uv(v, n, half):
    """Per-vertex UV by dominant-axis projection into a 3x2 cell layout (matches box())."""
    uv = np.zeros((len(v), 2))
    half = np.maximum(np.asarray(half, float), 1e-6)
    ax = np.argmax(np.abs(n), axis=1)
    for i in range(len(v)):
        p = v[i] / half
        a = ax[i]
        s = 1 if n[i, a] > 0 else -1
        if a == 0:
            k = 0 if s > 0 else 1; u, w = p[1] * s, p[2]
        elif a == 1:
            k = 2 if s > 0 else 3; u, w = -p[0] * s, p[2]
        else:
            k = 4 if s > 0 else 5; u, w = p[1], -p[0] * s
        cu, cv = k % 3, k // 3
        uv[i] = ((cu + 0.04 + 0.92 * (u * 0.5 + 0.5)) / 3.0, (cv + 0.04 + 0.92 * (w * 0.5 + 0.5)) / 2.0)
    return np.clip(uv, 0, 1)


def ellipsoid(radii=(1, 1, 1), center=(0, 0, 0), segs=12, rings=8, mat='default', bone=0,
              deform=None, R=None, phi0=math.pi):
    """Lat-long ellipsoid, poles on local Z. deform(p_unit(n,3), p(n,3)) -> displaced p (optional).
    phi0: longitude of the UV seam (default pi = back, so faces never sit on a seam)."""
    rx, ry, rz = radii
    vs, uvs = [], []
    for j in range(rings + 1):
        th = math.pi * j / rings           # 0 = bottom pole
        z = -math.cos(th)
        r = math.sin(th)
        for i in range(segs + 1):
            ph = phi0 + 2 * math.pi * i / segs
            vs.append((r * math.cos(ph), r * math.sin(ph), z))
            uvs.append((i / segs, j / rings))
    unit = np.array(vs)
    p = unit * np.array([rx, ry, rz])
    if deform is not None:
        p = deform(unit, p)
    faces = _grid_faces(rings + 1, segs + 1)
    # remove degenerate pole triangles
    vv = p
    keep = []
    for t in faces:
        a, b, c = vv[t[0]], vv[t[1]], vv[t[2]]
        if np.linalg.norm(np.cross(b - a, c - a)) > 1e-10:
            keep.append(t)
    m = Mesh(p, np.array(keep), np.array(uvs), None, bone, mat,
             size=(2 * math.pi * max(rx, ry), math.pi * rz + max(rx, ry)))
    m.attrs['lat'] = np.array([uv[1] for uv in uvs])
    m.attrs['lon'] = np.array([uv[0] for uv in uvs])
    _orient_outward(m, (0, 0, 0))
    m.recompute_normals()
    if R is not None:
        m.transform(R)
    m.translate(center)
    return m


def dome(radii=(1, 1, 1), center=(0, 0, 0), rim=None, segs=16, rings=6, mat='default', bone=0, deform=None,
         two_sided=True, thickness=0.0):
    """Open cap of an ellipsoid from the top pole down to a rim whose latitude (radians, 0 = equator,
    negative = below) depends on the azimuth phi (0 = +X front): rim(phi) -> lat. Used for helmets,
    hoods, hair caps. thickness > 0 adds an inner shell + lip instead of two-sided faces."""
    rx, ry, rz = radii
    if rim is None:
        rim = lambda phi: -0.2
    vs, uvs = [], []
    for j in range(rings + 1):
        for i in range(segs + 1):
            ph = math.pi + 2 * math.pi * i / segs
            lat_rim = rim(ph)
            lat = math.pi / 2 - (math.pi / 2 - lat_rim) * (j / rings)
            u = (math.cos(lat) * math.cos(ph), math.cos(lat) * math.sin(ph), math.sin(lat))
            vs.append(u)
            uvs.append((i / segs, 1 - 0.75 * j / rings))
    unit = np.array(vs)
    p = unit * np.array([rx, ry, rz])
    if deform is not None:
        p = deform(unit, p)
    f = _grid_faces(rings + 1, segs + 1)
    keep = [t for t in f if np.linalg.norm(np.cross(p[t[1]] - p[t[0]], p[t[2]] - p[t[0]])) > 1e-10]
    m = Mesh(p, np.array(keep), np.array(uvs), None, bone, mat, size=(2 * math.pi * max(rx, ry), math.pi * rz))
    _orient_outward(m, (0, 0, 0))
    m.recompute_normals()
    if thickness > 0:
        inner = m.copy()
        sc = np.array([(rx - thickness) / rx, (ry - thickness) / ry, (rz - thickness) / rz])
        inner.v = inner.v * sc
        inner.flip()
        n = len(m.v)
        # lip: connect the rim rings
        rim0 = np.arange(rings * (segs + 1), (rings + 1) * (segs + 1))
        lip = []
        for i in range(segs):
            a, b = rim0[i], rim0[i + 1]
            lip.append((a, n + b, b)); lip.append((a, n + a, n + b))
        allv = np.vstack([m.v, inner.v])
        allf = np.vstack([m.f, inner.f + n, np.array(lip)])
        uv = np.vstack([m.uv, (inner.uv - np.array([0, 0.25])) * np.array([1, 0.27])])
        out = Mesh(allv, allf, uv, None, bone, mat, size=m.size)
        # fix lip orientation
        out.recompute_normals()
        out.translate(center)
        return out
    if two_sided:
        m.make_two_sided()
    m.translate(center)
    return m


def sphere(r=1.0, center=(0, 0, 0), segs=12, rings=8, **kw):
    return ellipsoid((r, r, r), center, segs, rings, **kw)


class Ring:
    """Cross-section description for loft(): center c (3), frame (3x3 columns x=side1,y=side2,z=tangent),
    radii (a, b) along frame x/y, optional profile fn(theta)->multiplier and per-ring bone."""
    def __init__(self, c, frame, a, b=None, bone=0, profile=None, t=0.0):
        self.c = np.asarray(c, dtype=np.float64)
        self.frame = np.asarray(frame, dtype=np.float64)
        self.a = a
        self.b = a if b is None else b
        self.bone = bone
        self.profile = profile
        self.t = t


def loft(rings, segs=10, mat='default', cap_start=False, cap_end=False, theta0=math.pi, name='',
         uv_u_range=(0.0, 1.0)):
    """Generic tube through a list of Ring cross-sections. Vertex count = len(rings)*(segs+1).
    UV: u around (0..1, seam duplicated), v along (arc length normalised). attrs: 't' (ring param),
    'theta' (angle around)."""
    nr = len(rings)
    vs, uvs, bones, ts, ths = [], [], [], [], []
    # arc length for v
    cs = np.array([r.c for r in rings])
    seg_len = np.linalg.norm(np.diff(cs, axis=0), axis=1)
    L = np.concatenate([[0], np.cumsum(seg_len)])
    total = L[-1] if L[-1] > 1e-9 else 1.0
    perim = []
    for j, r in enumerate(rings):
        pr = 0
        prev = None
        for i in range(segs + 1):
            th = theta0 + 2 * math.pi * i / segs
            mul = r.profile(th) if r.profile is not None else 1.0
            local = np.array([math.cos(th) * r.a * mul, math.sin(th) * r.b * mul, 0.0])
            p = r.c + r.frame @ local
            vs.append(p)
            u = uv_u_range[0] + (uv_u_range[1] - uv_u_range[0]) * i / segs
            uvs.append((u, L[j] / total))
            bones.append(r.bone)
            ts.append(r.t)
            ths.append(th)
            if prev is not None:
                pr += np.linalg.norm(p - prev)
            prev = p
        perim.append(pr)
    faces = _grid_faces(nr, segs + 1)
    vs = np.array(vs)
    extra_f = []
    extra_v = []
    extra_uv = []
    extra_b = []
    extra_t = []
    extra_th = []
    if cap_start or cap_end:
        for which in ([0] if cap_start else []) + ([nr - 1] if cap_end else []):
            r = rings[which]
            ci = len(vs) + len(extra_v)
            extra_v.append(r.c)
            extra_uv.append((0.5, 0.0 if which == 0 else 1.0))
            extra_b.append(r.bone)
            extra_t.append(r.t)
            extra_th.append(0.0)
            base = which * (segs + 1)
            for i in range(segs):
                a, b = base + i, base + i + 1
                if which == 0:
                    extra_f.append((ci, b, a))
                else:
                    extra_f.append((ci, a, b))
    if extra_v:
        vs = np.vstack([vs, np.array(extra_v)])
        uvs = uvs + extra_uv
        bones = bones + extra_b
        ts = ts + extra_t
        ths = ths + extra_th
        faces = np.vstack([faces, np.array(extra_f)])
    m = Mesh(vs, faces, np.array(uvs), None, np.array(bones), mat,
             size=(max(perim) if perim else 1.0, total), name=name)
    # make outward: check the side surface using ring centres
    v, f = m.v, m.f[:len(_grid_faces(nr, segs + 1))]
    fn = np.cross(v[f[:, 1]] - v[f[:, 0]], v[f[:, 2]] - v[f[:, 0]])
    # nearest ring centre per face
    fc = v[f].mean(1)
    ring_idx = np.minimum(f[:, 0] // (segs + 1), nr - 1)
    out = fc - cs[ring_idx]
    if np.sum(np.einsum('ij,ij->i', fn, out)) < 0:
        m.f = m.f[:, ::-1].copy()
    m.attrs['t'] = np.array(ts, dtype=np.float64)
    m.attrs['theta'] = np.array(ths, dtype=np.float64)
    m.recompute_normals()
    return m


def path_frames(points, up=(0, 0, 1), ref=None):
    """Rotation-minimising frames along a polyline. Returns list of 3x3 (cols: x, y, tangent)."""
    P = np.asarray(points, dtype=np.float64)
    n = len(P)
    T = np.zeros_like(P)
    for i in range(n):
        if i == 0:
            d = P[1] - P[0]
        elif i == n - 1:
            d = P[-1] - P[-2]
        else:
            d = P[i + 1] - P[i - 1]
        T[i] = d / max(np.linalg.norm(d), 1e-12)
    ref = np.asarray(ref if ref is not None else up, dtype=np.float64)
    x = np.cross(ref, T[0])
    if np.linalg.norm(x) < 1e-6:
        x = np.cross(np.array([1.0, 0, 0]) if abs(T[0][0]) < 0.9 else np.array([0, 1.0, 0]), T[0])
    x /= np.linalg.norm(x)
    frames = []
    for i in range(n):
        if i > 0:
            R = rot_between(T[i - 1], T[i])
            x = R @ x
            x -= T[i] * np.dot(x, T[i])
            x /= max(np.linalg.norm(x), 1e-12)
        y = np.cross(T[i], x)
        frames.append(np.stack([x, y, T[i]], axis=1))
    return frames


def tube(points, radii, segs=8, mat='default', bones=0, cap_start=True, cap_end=True, radii_b=None,
         up=(0, 0, 1), profile=None, ref=None, name=''):
    """Tube along a polyline. radii: scalar or per-point; bones: scalar or per-point."""
    P = np.asarray(points, dtype=np.float64)
    n = len(P)
    ra = np.broadcast_to(np.asarray(radii, dtype=np.float64), (n,))
    rb = ra if radii_b is None else np.broadcast_to(np.asarray(radii_b, dtype=np.float64), (n,))
    bs = np.broadcast_to(np.asarray(bones), (n,))
    fr = path_frames(P, up, ref)
    rings = [Ring(P[i], fr[i], max(ra[i], 1e-4), max(rb[i], 1e-4), int(bs[i]), profile, t=i / max(n - 1, 1))
             for i in range(n)]
    return loft(rings, segs, mat, cap_start, cap_end, name=name)


def lathe(profile_pts, axis_start=(0, 0, 0), axis_dir=(0, 0, 1), segs=12, mat='default', bone=0,
          cap_start=True, cap_end=True, name=''):
    """Surface of revolution: profile_pts = [(h, r), ...] along axis."""
    a0 = np.asarray(axis_start, dtype=np.float64)
    d = np.asarray(axis_dir, dtype=np.float64); d /= np.linalg.norm(d)
    fr = look_frame(d, (0, 0, 1) if abs(d[2]) < 0.9 else (1, 0, 0))
    frame = np.stack([fr[:, 1], fr[:, 2], d], axis=1)
    rings = [Ring(a0 + d * h, frame, max(r, 1e-4), max(r, 1e-4), bone, t=k / max(len(profile_pts) - 1, 1))
             for k, (h, r) in enumerate(profile_pts)]
    return loft(rings, segs, mat, cap_start, cap_end, name=name)


def cylinder(p0, p1, r0, r1=None, segs=10, mat='default', bone=0, caps=True):
    r1 = r0 if r1 is None else r1
    return tube([p0, p1], [r0, r1], segs, mat, bone, caps, caps)


def cone(base, tip, r, segs=8, mat='default', bone=0):
    return tube([base, tip], [r, 1e-3], segs, mat, bone, True, False)


def capsule(p0, p1, r, segs=10, rings=3, mat='default', bone=0, r1=None):
    """Capsule as a tube with hemispherical ring sequences at both ends."""
    p0 = np.asarray(p0, float); p1 = np.asarray(p1, float)
    r1 = r if r1 is None else r1
    d = p1 - p0
    L = np.linalg.norm(d)
    dn = d / max(L, 1e-9)
    pts, rad = [], []
    for k in range(rings, 0, -1):
        a = (math.pi / 2) * k / rings
        pts.append(p0 - dn * r * math.sin(a)); rad.append(max(r * math.cos(a), 0.02 * r))
    pts.append(p0); rad.append(r)
    pts.append(p1); rad.append(r1)
    for k in range(1, rings + 1):
        a = (math.pi / 2) * k / rings
        pts.append(p1 + dn * r1 * math.sin(a)); rad.append(max(r1 * math.cos(a), 0.02 * r1))
    return tube(pts, rad, segs, mat, bone, True, True)


def horn(base, direction, length, r, curve=(0, 0, 0), segs=6, steps=5, mat='horn', bone=0, twist_up=(0, 0, 1)):
    """Curved tapering spike: base point, initial direction, length, base radius, curve vector
    (added quadratically along the length)."""
    base = np.asarray(base, float)
    d = np.asarray(direction, float); d /= np.linalg.norm(d)
    c = np.asarray(curve, float)
    pts = [base + d * length * (k / steps) + c * (k / steps) ** 2 for k in range(steps + 1)]
    rad = [r * (1 - k / steps) ** 0.9 + 0.02 * r for k in range(steps + 1)]
    rad[-1] = 0.01 * r
    return tube(pts, rad, segs, mat, bone, True, False, up=twist_up)


def extrude(poly2d, depth, R=None, t=(0, 0, 0), mat='default', bone=0, bevel=0.0):
    """Extrude a CCW 2D polygon (x,y) along local +Z by depth (centred). Simple convex/concave ear clip
    for caps. Local frame: polygon in XY plane."""
    P = np.asarray(poly2d, dtype=np.float64)
    n = len(P)
    # ensure CCW
    area = 0.5 * np.sum(P[:, 0] * np.roll(P[:, 1], -1) - np.roll(P[:, 0], -1) * P[:, 1])
    if area < 0:
        P = P[::-1]
    tri = ear_clip(P)
    h = depth * 0.5
    top = np.column_stack([P, np.full(n, h)])
    bot = np.column_stack([P, np.full(n, -h)])
    vs, fs, uvs = [], [], []
    mn, mx = P.min(0), P.max(0)
    span = np.maximum(mx - mn, 1e-6)
    # caps (uv: planar, top in left half, bottom in right half)
    for cap, z, flip, uoff in ((top, h, False, 0.0), (bot, -h, True, 0.5)):
        base = len(vs)
        for p in cap:
            vs.append(p)
            q = (p[:2] - mn) / span
            uvs.append((uoff + 0.02 + 0.46 * q[0], 0.35 + 0.63 * q[1]))
        for a, b, c in tri:
            fs.append((base + a, base + c, base + b) if flip else (base + a, base + b, base + c))
    # sides
    per = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(np.vstack([P, P[:1]]), axis=0), axis=1))])
    for i in range(n):
        j = (i + 1) % n
        base = len(vs)
        u0 = per[i] / per[-1]; u1 = per[i + 1] / per[-1]
        vs += [bot[i], bot[j], top[j], top[i]]
        uvs += [(0.02 + 0.96 * u0, 0.02), (0.02 + 0.96 * u1, 0.02), (0.02 + 0.96 * u1, 0.31), (0.02 + 0.96 * u0, 0.31)]
        fs += [(base, base + 1, base + 2), (base, base + 2, base + 3)]
    m = Mesh(np.array(vs), fs, np.array(uvs), None, bone, mat, size=(max(per[-1], 2 * span.max()), span.max() * 1.6))
    m = flat_shaded(m)
    if R is not None or t is not None:
        m.transform(R if R is not None else np.eye(3), t)
    return m


def ear_clip(P):
    """Triangulate simple CCW polygon -> list of index triples."""
    idx = list(range(len(P)))
    out = []

    def is_convex(a, b, c):
        return (P[b][0] - P[a][0]) * (P[c][1] - P[a][1]) - (P[b][1] - P[a][1]) * (P[c][0] - P[a][0]) > 1e-12

    def inside(p, a, b, c):
        def s(p1, p2, p3):
            return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1])
        d1, d2, d3 = s(p, P[a], P[b]), s(p, P[b], P[c]), s(p, P[c], P[a])
        neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
        pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
        return not (neg and pos)

    guard = 0
    while len(idx) > 3 and guard < 10000:
        guard += 1
        found = False
        for k in range(len(idx)):
            a, b, c = idx[k - 1], idx[k], idx[(k + 1) % len(idx)]
            if not is_convex(a, b, c):
                continue
            if any(inside(P[o], a, b, c) for o in idx if o not in (a, b, c)):
                continue
            out.append((a, b, c))
            idx.pop(k)
            found = True
            break
        if not found:
            break
    if len(idx) == 3:
        out.append(tuple(idx))
    elif len(idx) > 3:  # fallback fan
        for k in range(1, len(idx) - 1):
            out.append((idx[0], idx[k], idx[k + 1]))
    return out


def ribbon(points, widths, normal_hint=(0, 0, 1), mat='cloth', bones=0, two_sided=True, tatter=0.0,
           seed=0, width_dir=None):
    """Cloth strip along a polyline: width perpendicular to the path (in the plane of normal_hint).
    tatter > 0 cuts a ragged lower edge (random shortening of the last rows)."""
    P = np.asarray(points, dtype=np.float64)
    n = len(P)
    W = np.broadcast_to(np.asarray(widths, dtype=np.float64), (n,))
    bs = np.broadcast_to(np.asarray(bones), (n,))
    rng = np.random.default_rng(seed)
    cols = 5
    vs, uvs, bb = [], [], []
    L = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))])
    for i in range(n):
        if width_dir is not None:
            side = np.asarray(width_dir, float)
        else:
            t = P[min(i + 1, n - 1)] - P[max(i - 1, 0)]
            side = np.cross(np.asarray(normal_hint, float), t)
        side = side / max(np.linalg.norm(side), 1e-9)
        for c in range(cols):
            s = (c / (cols - 1) - 0.5)
            p = P[i] + side * W[i] * s
            if tatter > 0 and i == n - 1:
                p = p - (P[i] - P[i - 1]) * rng.uniform(0, tatter)
            vs.append(p)
            uvs.append((c / (cols - 1), 1.0 - L[i] / max(L[-1], 1e-9)))
            bb.append(int(bs[i]))
    f = _grid_faces(n, cols)
    m = Mesh(np.array(vs), f, np.array(uvs), None, np.array(bb), mat, size=(float(W.max()), float(L[-1])))
    if two_sided:
        m.make_two_sided()
    return m


def noise_displace(mesh, amp, freq=0.5, seed=0, along_normal=True):
    """Low-frequency value-noise displacement (organic lumps). Uses rest positions -> continuous."""
    from .paint import noise3
    nval = noise3(mesh.v * freq, seed) * 2 - 1
    if along_normal:
        mesh.v = mesh.v + mesh.n * (amp * nval)[:, None]
    mesh.recompute_normals()
    return mesh


# ---------------------------------------------------------------------------------------------------
# atlas packing

def pack_atlas(meshes, tex_w=256, tex_h=256, max_textures=4, density=None, pad=3, tex_prefix='skin',
               fixed=None):
    """Shelf-pack mesh UV islands into textures. Each mesh keeps its island-local UV in [0,1];
    the packer scales islands by `density` (pixels per world unit), finds the largest density that
    fits into the allowed pages (binary search when density is None) and writes mesh.atlas_uv /
    mesh.island / mesh.texture. Returns list of page dicts [{'name', 'w', 'h', 'islands': [...]}].
    `fixed`: optional {mesh_index: page_index} to force islands onto a page."""
    sizes = []
    for m in meshes:
        u, v = m.size
        dt = getattr(m, 'detail', 1.0)
        sizes.append((max(u * dt, 0.05), max(v * dt, 0.05)))

    def try_pack(d):
        rects = []
        for i, (u, v) in enumerate(sizes):
            w = int(math.ceil(u * d)) + 2 * pad
            h = int(math.ceil(v * d)) + 2 * pad
            w = max(w, 2 * pad + 4); h = max(h, 2 * pad + 4)
            if w > tex_w or h > tex_h:
                return None
            rects.append((i, w, h))
        order = sorted(rects, key=lambda r: -r[2])
        pages = [[]]
        shelves = [[]]  # per page: list of [y, height, x_cursor]
        placed = {}
        for i, w, h in order:
            ok = False
            for pi in range(len(pages)):
                for sh in shelves[pi]:
                    if h <= sh[1] and sh[2] + w <= tex_w:
                        placed[i] = (pi, sh[2], sh[0], w, h)
                        sh[2] += w
                        ok = True
                        break
                if ok:
                    break
                ytop = sum(s[1] for s in shelves[pi])
                if ytop + h <= tex_h:
                    shelves[pi].append([ytop, h, w])
                    placed[i] = (pi, 0, ytop, w, h)
                    ok = True
                    break
            if not ok:
                if len(pages) >= max_textures:
                    return None
                pages.append([]); shelves.append([[0, h, w]])
                placed[i] = (len(pages) - 1, 0, 0, w, h)
        return placed, len(pages)

    if density is None:
        lo, hi = 0.5, 64.0
        best = None
        for _ in range(28):
            mid = (lo + hi) / 2
            r = try_pack(mid)
            if r is None:
                hi = mid
            else:
                lo = mid
                best = (mid, r)
        if best is None:
            raise RuntimeError('atlas packing failed even at minimum density')
        density, (placed, npages) = best
    else:
        r = try_pack(density)
        if r is None:
            raise RuntimeError('atlas packing failed at density %g' % density)
        placed, npages = r
    pages = [dict(name='%s%d.bmp' % (tex_prefix, p), w=tex_w, h=tex_h, islands=[]) for p in range(npages)]
    for i, m in enumerate(meshes):
        pi, x, y, w, h = placed[i]
        m.island = (pi, x, y, w, h)
        m.texture = pages[pi]['name']
        # inner rect (without padding) in pixel space; y measured from TOP of image.
        # studiomdl stores s = int(u*(W-1)), t = (H-1) - int(v*(H-1)) and the engine samples at s/W, t/H
        # (texel edges), so we snap every vertex to an integer texel-edge coordinate and pick u/v so the
        # truncation lands exactly on it.
        ix0, iy0 = x + pad, y + pad
        iw, ih = w - 2 * pad, h - 2 * pad
        sx = np.round(ix0 + m.uv[:, 0] * iw)
        ty = np.round(iy0 + (1 - m.uv[:, 1]) * ih)
        u = np.clip((sx + 0.25) / (tex_w - 1), 0, 1)
        v = np.clip(((tex_h - 1) - ty + 0.25) / (tex_h - 1), 0, 1)
        m.atlas_uv = np.column_stack([u, v])
        m.attrs['_px'] = sx
        m.attrs['_py'] = ty
        pages[pi]['islands'].append(i)
    for p in pages:
        p['density'] = density
    return pages
