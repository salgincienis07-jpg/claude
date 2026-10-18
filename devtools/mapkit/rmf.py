"""Worldcraft / Hammer .rmf (v2.2) reader -> plain Python objects, and a writer to Valve220 .map text.

    python3 -m mapkit.rmf in.rmf out.map        (prints a summary)

RMF 2.2 layout (little endian):
  float version, "RMF", int nvisgroups, visgroup[140], "CMapWorld" object, then world entity data.
  Every object starts with an nstring class name (byte len incl. NUL):
    CMapSolid : int visgroup, rgb[3], int nchildren(0), int nfaces, face[]
      face    : char tex[256], float 0, float uaxis[3], ushift, float vaxis[3], vshift, rot, uscale, vscale,
                byte[16], int nverts, float3 verts[], float3 planepts[3]
    CMapEntity: int visgroup, rgb[3], int nsolids, solid[], entity data, byte[2], float origin[3], int
    CMapGroup : int visgroup, rgb[3], int nobjects, object[]
    CMapWorld : int visgroup, rgb[3], int nobjects, object[], entity data, int npaths, path[]
  entity data : nstring classname, byte[4], int spawnflags, int nkeys, (nstring key, nstring value)[], byte[12]
"""
import struct
import sys


class Face:
    __slots__ = ('tex', 'u', 'ushift', 'v', 'vshift', 'rot', 'uscale', 'vscale', 'verts', 'plane')


class Solid:
    def __init__(self):
        self.faces = []


class Ent:
    def __init__(self):
        self.classname = ''
        self.flags = 0
        self.keys = []          # ordered (k, v)
        self.solids = []
        self.origin = (0.0, 0.0, 0.0)

    def get(self, k, d=None):
        for a, b in self.keys:
            if a == k:
                return b
        return d


class R:
    def __init__(self, data):
        self.d = data
        self.p = 0

    def take(self, n):
        b = self.d[self.p:self.p + n]
        self.p += n
        return b

    def i(self):
        v = struct.unpack_from('<i', self.d, self.p)[0]
        self.p += 4
        return v

    def f(self):
        v = struct.unpack_from('<f', self.d, self.p)[0]
        self.p += 4
        return v

    def fv(self, n=3):
        v = struct.unpack_from('<%df' % n, self.d, self.p)
        self.p += 4 * n
        return v

    def ns(self):
        n = self.d[self.p]
        self.p += 1
        s = self.d[self.p:self.p + n]
        self.p += n
        return s.split(b'\0')[0].decode('latin-1')

    def cstr(self, n):
        return self.take(n).split(b'\0')[0].decode('latin-1')


class RMF:
    def __init__(self, path):
        r = R(open(path, 'rb').read())
        self.version = r.f()
        if r.take(3) != b'RMF':
            raise ValueError('not an RMF file')
        nvg = r.i()
        r.take(140 * nvg)
        self.world = Ent()
        self.ents = []
        self.world_solids = []
        cls = r.ns()
        assert cls == 'CMapWorld', cls
        r.i(); r.take(3)
        n = r.i()
        for _ in range(n):
            self._obj(r, self.world_solids)
        self._entdata(r, self.world)
        self.world.solids = self.world_solids

    def _entdata(self, r, e):
        e.classname = r.ns()
        r.take(4)
        e.flags = r.i()
        nk = r.i()
        for _ in range(nk):
            k = r.ns()
            v = r.ns()
            e.keys.append((k, v))
        r.take(12)

    def _solid(self, r):
        r.i(); r.take(3)
        nch = r.i()
        s = Solid()
        nf = r.i()
        for _ in range(nf):
            f = Face()
            f.tex = r.cstr(256)
            r.f()
            f.u = r.fv(); f.ushift = r.f()
            f.v = r.fv(); f.vshift = r.f()
            f.rot = r.f(); f.uscale = r.f(); f.vscale = r.f()
            r.take(16)
            nv = r.i()
            f.verts = [r.fv() for _ in range(nv)]
            f.plane = [r.fv() for _ in range(3)]
            s.faces.append(f)
        assert nch == 0
        return s

    def _obj(self, r, sink, owner=None):
        cls = r.ns()
        if cls == 'CMapSolid':
            sink.append(self._solid(r))
        elif cls == 'CMapGroup':
            r.i(); r.take(3)
            n = r.i()
            for _ in range(n):
                self._obj(r, sink)
        elif cls == 'CMapEntity':
            r.i(); r.take(3)
            e = Ent()
            n = r.i()
            for _ in range(n):
                self._obj(r, e.solids)
            self._entdata(r, e)
            r.take(2)
            e.origin = r.fv()
            r.take(4)
            self.ents.append(e)
        else:
            raise ValueError('unknown object %r at %d' % (cls, r.p))

    # ------------------------------------------------------------ .map writer
    @staticmethod
    def _fmt(x):
        s = ('%.6f' % x).rstrip('0').rstrip('.')
        return '0' if s in ('-0', '') else s

    def face_line(self, f):
        p = ' '.join('( %s )' % ' '.join(self._fmt(c) for c in pt) for pt in f.plane)
        F = self._fmt
        return '%s %s [ %s %s %s %s ] [ %s %s %s %s ] %s %s %s' % (
            p, f.tex, F(f.u[0]), F(f.u[1]), F(f.u[2]), F(f.ushift), F(f.v[0]), F(f.v[1]), F(f.v[2]), F(f.vshift),
            F(f.rot), F(f.uscale), F(f.vscale))

    def to_map(self, extra_world_solids=(), extra_ents=(), wad=None):
        out = ['{']
        keys = list(self.world.keys)
        if wad is not None:
            keys = [(k, v) for k, v in keys if k != 'wad'] + [('wad', wad)]
        has = {k for k, _ in keys}
        out.append('"classname" "worldspawn"')
        if 'mapversion' not in has:
            out.append('"mapversion" "220"')
        for k, v in keys:
            if k != 'classname':
                out.append('"%s" "%s"' % (k, v))
        for s in list(self.world_solids) + list(extra_world_solids):
            out.append(self.solid_text(s))
        out.append('}')
        for e in list(self.ents) + list(extra_ents):
            out.append(self.ent_text(e))
        return '\n'.join(out) + '\n'

    def solid_text(self, s):
        if isinstance(s, str):
            return s
        return '{\n' + '\n'.join(self.face_line(f) for f in s.faces) + '\n}'

    def ent_text(self, e):
        if isinstance(e, str):
            return e
        o = ['{', '"classname" "%s"' % e.classname]
        if e.flags:
            o.append('"spawnflags" "%d"' % e.flags)
        for k, v in e.keys:
            if k not in ('classname', 'spawnflags'):
                o.append('"%s" "%s"' % (k, v))
        if not e.solids and e.get('origin') is None:
            o.append('"origin" "%s"' % ' '.join(self._fmt(c) for c in e.origin))
        for s in e.solids:
            o.append(self.solid_text(s))
        o.append('}')
        return '\n'.join(o)


if __name__ == '__main__':
    m = RMF(sys.argv[1])
    import collections
    print('version', m.version, 'world solids', len(m.world_solids), 'entities', len(m.ents))
    print(collections.Counter(e.classname for e in m.ents).most_common(40))
    print('world keys', m.world.keys)
    tex = collections.Counter(f.tex for s in m.world_solids for f in s.faces)
    print(len(tex), 'textures', tex.most_common(60))
    if len(sys.argv) > 2:
        open(sys.argv[2], 'w').write(m.to_map())


# ---------------------------------------------------------------- convex brush clipping
def _planes(solid):
    import numpy as np
    out = []
    for f in solid.faces:
        p0, p1, p2 = [np.array(p, float) for p in f.plane]
        n = np.cross(p2 - p0, p1 - p0)
        n /= np.linalg.norm(n)
        out.append((n, float(np.dot(n, p0)), f))
    return out


def _verts(planes, eps=0.01):
    import itertools
    import numpy as np
    pts = []
    for (n1, d1, _), (n2, d2, _), (n3, d3, _) in itertools.combinations(planes, 3):
        A = np.array([n1, n2, n3])
        if abs(np.linalg.det(A)) < 1e-6:
            continue
        p = np.linalg.solve(A, [d1, d2, d3])
        if all(np.dot(n, p) <= d + eps for n, d, _ in planes):
            pts.append(p)
    return np.array(pts) if pts else np.zeros((0, 3))


def _new_face(n, d, tex):
    """axis plane face with RMF point order (outward = cross(p2-p0, p1-p0)), world-aligned texture."""
    import numpy as np
    n = np.array(n, float)
    a = np.argmax(np.abs(n))
    t1 = np.zeros(3); t1[(a + 1) % 3] = 64
    t2 = np.zeros(3); t2[(a + 2) % 3] = 64
    p0 = n * d
    for p1, p2 in ((p0 + t1, p0 + t2), (p0 + t2, p0 + t1)):
        if np.dot(np.cross(p2 - p0, p1 - p0), n) > 0:
            break
    f = Face()
    f.tex = tex
    if a == 0:
        u, v = np.array([0, 1.0, 0]), np.array([0, 0, -1.0])
    elif a == 1:
        u, v = np.array([1.0, 0, 0]), np.array([0, 0, -1.0])
    else:
        u, v = np.array([1.0, 0, 0]), np.array([0, -1.0, 0])
    f.u, f.ushift, f.v, f.vshift, f.rot, f.uscale, f.vscale = tuple(u), 0.0, tuple(v), 0.0, 0.0, 1.0, 1.0
    f.plane = [tuple(p0), tuple(p1), tuple(p2)]
    f.verts = []
    return f


def clip_outside_box(solid, x0, y0, x1, y1, tex='d2_wall'):
    """parts of a convex solid that lie OUTSIDE the vertical box [x0,x1] x [y0,y1] (up to 4 pieces)."""
    import numpy as np
    base = _planes(solid)
    pieces_spec = [
        [((1, 0, 0), x0)],                                   # x <= x0
        [((-1, 0, 0), -x1)],                                 # x >= x1
        [((-1, 0, 0), -x0), ((1, 0, 0), x1), ((0, 1, 0), y0)],    # x0..x1, y <= y0
        [((-1, 0, 0), -x0), ((1, 0, 0), x1), ((0, -1, 0), -y1)],  # x0..x1, y >= y1
    ]
    out = []
    for spec in pieces_spec:
        extra = [(np.array(n, float), float(d), None) for n, d in spec]
        planes = base + extra
        V = _verts(planes)
        if len(V) < 4:
            continue
        span = V.max(0) - V.min(0)
        if min(span) < 0.5:
            continue
        s = Solid()
        for n, d, f in planes:
            on = np.abs(V @ n - d) < 0.05
            if on.sum() < 3:
                continue
            if f is None:
                f = _new_face(n, d, tex)
            nf = Face()
            for k in Face.__slots__:
                setattr(nf, k, getattr(f, k))
            nf.verts = [tuple(p) for p in V[on]]
            s.faces.append(nf)
        out.append(s)
    return out


def solid_bbox(solid):
    import numpy as np
    V = np.array([v for f in solid.faces for v in f.verts])
    return V.min(0), V.max(0)


def _clip_with(solid, extra_specs, tex):
    import numpy as np
    base = _planes(solid)
    out = []
    for spec in extra_specs:
        extra = []
        for n, d in spec:
            n = np.array(n, float)
            if any(np.allclose(n, bn, atol=1e-4) and abs(d - bd) < 0.05 for bn, bd, _ in base):
                continue                       # coincides with an existing face: keep the original
            extra.append((n, float(d), None))
        planes = base + extra
        V = _verts(planes)
        if len(V) < 4:
            continue
        span = V.max(0) - V.min(0)
        if min(span) < 0.5:
            continue
        s = Solid()
        for n, d, f in planes:
            on = np.abs(V @ n - d) < 0.05
            if on.sum() < 3:
                continue
            if f is None:
                f = _new_face(n, d, tex)
            nf = Face()
            for k in Face.__slots__:
                setattr(nf, k, getattr(f, k))
            nf.verts = [tuple(p) for p in V[on]]
            s.faces.append(nf)
        if len(s.faces) >= 4:
            out.append(s)
    return out


def subtract_box(solid, mn, mx, tex='d2_wall'):
    """parts of a convex solid outside the axis box mn..mx (up to 6 convex pieces); new cut faces get `tex`."""
    x0, y0, z0 = mn
    x1, y1, z1 = mx
    X = [((-1, 0, 0), -x0), ((1, 0, 0), x1)]
    XY = X + [((0, -1, 0), -y0), ((0, 1, 0), y1)]
    specs = [
        [((1, 0, 0), x0)], [((-1, 0, 0), -x1)],
        X + [((0, 1, 0), y0)], X + [((0, -1, 0), -y1)],
        XY + [((0, 0, 1), z0)], XY + [((0, 0, -1), -z1)],
    ]
    return _clip_with(solid, specs, tex)


def solid_hits_box(solid, mn, mx, eps=0.1):
    a, b = solid_bbox(solid)
    if any(a[i] >= mx[i] - eps or b[i] <= mn[i] + eps for i in range(3)):
        return False
    import numpy as np
    # exact: is any interior point of the box inside the solid? use separating planes of the solid
    planes = _planes(solid)
    corners = np.array([[x, y, z] for x in (mn[0] + eps, mx[0] - eps) for y in (mn[1] + eps, mx[1] - eps) for z in (mn[2] + eps, mx[2] - eps)])
    for n, d, _ in planes:
        if np.all(corners @ n >= d):
            return False
    return True


def box_solid(mn, mx, tex):
    """axis box as an RMF Solid (so it can be carved like dust2 brushes). tex: name or {top,bottom,side|all}."""
    import numpy as np
    s = Solid()
    mn = np.array(mn, float); mx = np.array(mx, float)
    for n, d, key in (((1, 0, 0), mx[0], 'side'), ((-1, 0, 0), -mn[0], 'side'), ((0, 1, 0), mx[1], 'side'),
                      ((0, -1, 0), -mn[1], 'side'), ((0, 0, 1), mx[2], 'top'), ((0, 0, -1), -mn[2], 'bottom')):
        t = tex if isinstance(tex, str) else tex.get(key, tex.get('all', 'd2_wall'))
        f = _new_face(n, d, t)
        a = int(np.argmax(np.abs(n)))
        val = mx[a] if n[a] > 0 else mn[a]
        o = [i for i in range(3) if i != a]
        vs = []
        for p0 in (mn[o[0]], mx[o[0]]):
            for p1 in (mn[o[1]], mx[o[1]]):
                v = [0, 0, 0]; v[a] = val; v[o[0]] = p0; v[o[1]] = p1
                vs.append(tuple(v))
        f.verts = vs
        s.faces.append(f)
    return s
