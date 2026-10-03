"""Valve220 .map writer + brush/entity helpers for GoldSrc (SDHLT compatible).

Coordinates: X east, Y north, Z up (Hammer convention). Units = inches.
Player hull 32x32x72 (origin at hull centre), crouch 32x32x36, step 18.

Quick example:
    from mapkit.mapwriter import Map, box, room, light, spawn_grid
    m = Map('zm_test', sky='night')
    m.add(room((-512, -512, 0), (512, 512, 256), wall=16, tex='vx_conc_clean',
               floor='vx_metal_floor', ceil='vx_conc_panel'))
    m.add_entity(light((0, 0, 200), (255, 240, 220), 300))
    m.add_entities(spawn_grid('info_player_start', (-400, -400), (-100, 400), 0, 32))
    m.write('zm_test.map')

Face texture specs (`tex` arguments) may be:
    'name'                              all faces
    {'top': .., 'bottom': .., 'sides': .., 'n'/'s'/'e'/'w': .., 'all': ..}
    callable(normal) -> name
"""
from __future__ import annotations

import math
from typing import Callable, Dict, Iterable, List, Optional, Sequence, Tuple, Union

import numpy as np

Vec = Tuple[float, float, float]
TexSpec = Union[str, Dict[str, str], Callable]

NULL = 'NULL'          # removed by CSG (never drawn, no lightmap)
SKIP = 'SKIP'
CLIP = 'CLIP'          # invisible player clip
HINT = 'HINT'
ORIGIN = 'ORIGIN'
TRIGGER = 'AAATRIGGER'
SKY = 'sky'
BEVEL = 'BEVEL'

# Stock skies shipped with every CS 1.6 install (gfx/env/<name>{bk,dn,ft,lf,rt,up}.tga)
STOCK_SKIES = ('desert', 'city', 'night', 'space', 'cx', 'office', 'de_storm', 'backalley',
               'morning', 'green', 'snow', 'tornsky', 'trainyard', '2desert', 'cliff', 'hav',
               'dusk', 'neb6', 'xen9', 'alien1', 'alien2', 'alien3', 'black', 'blue', 'grnplsnt')

_TEXSIZE: Dict[str, Tuple[int, int]] = {}


def tex_size(name: str) -> Tuple[int, int]:
    """Texture pixel size (vx_* from the procedural library, tool textures 64)."""
    if not _TEXSIZE:
        try:
            from . import textures
            for d in textures.REGISTRY.values():
                for n in d.wadnames():
                    _TEXSIZE[n.lower()] = (d.w, d.h)
        except Exception:  # pragma: no cover
            pass
    return _TEXSIZE.get(name.lower(), (64, 64))


# ======================================================================
# vector helpers
# ======================================================================
def _v(a) -> np.ndarray:
    return np.asarray(a, dtype=np.float64)


def _norm(a):
    a = _v(a)
    n = np.linalg.norm(a)
    return a / n if n > 0 else a


def _fmt(x: float) -> str:
    r = round(x)
    if abs(x - r) < 1e-4:
        return str(int(r))
    s = f'{x:.4f}'.rstrip('0').rstrip('.')
    return s if s not in ('-0', '') else '0'


# Quake/Hammer base axes (world aligned texturing)
_BASEAXIS = [
    ((0, 0, 1), (1, 0, 0), (0, -1, 0)),
    ((0, 0, -1), (1, 0, 0), (0, -1, 0)),
    ((1, 0, 0), (0, 1, 0), (0, 0, -1)),
    ((-1, 0, 0), (0, 1, 0), (0, 0, -1)),
    ((0, 1, 0), (1, 0, 0), (0, 0, -1)),
    ((0, -1, 0), (1, 0, 0), (0, 0, -1)),
]


def world_axes(normal) -> Tuple[np.ndarray, np.ndarray]:
    best, bu, bv = -1, None, None
    for n, u, v in _BASEAXIS:
        d = float(np.dot(normal, n))
        if d > best + 1e-6:
            best, bu, bv = d, u, v
    return _v(bu), _v(bv)


def readable_axes(normal) -> Tuple[np.ndarray, np.ndarray]:
    """Axes that show text/images unmirrored to a viewer facing the face
    (u = viewer's right, v = down). Floors/ceilings use world axes."""
    n = _norm(normal)
    if n[2] > 0.7:
        return world_axes(n)
    if n[2] < -0.7:                       # ceiling seen from below
        return _v((1, 0, 0)), _v((0, 1, 0))
    u = _norm(np.cross((0, 0, 1), n))
    return u, _v((0, 0, -1))


def face_axes(normal) -> Tuple[np.ndarray, np.ndarray]:
    """Texture axes lying in the face plane (no stretching on slopes)."""
    n = _norm(normal)
    if abs(n[2]) > 0.999:
        return world_axes(n)
    u = _norm(np.cross((0, 0, 1), n))       # horizontal
    if abs(n[2]) < 0.001:
        u = -u if np.dot(u, world_axes(n)[0]) < 0 else u
        return u, _v((0, 0, -1))
    v = _norm(np.cross(n, u))
    v = -v if v[2] > 0 else v
    wu, _ = world_axes(n)
    if np.dot(u, wu) < 0:
        u = -u
    return u, v


# ======================================================================
# faces & brushes
# ======================================================================
class Face:
    __slots__ = ('p', 'tex', 'u', 'v', 'su', 'sv', 'ou', 'ov', 'rot', 'align')

    def __init__(self, p0, p1, p2, tex, align='readable'):
        self.p = [_v(p0), _v(p1), _v(p2)]
        self.tex = tex
        self.u = self.v = None
        self.su = self.sv = None
        self.ou = self.ov = 0.0
        self.rot = 0.0
        self.align = align

    @property
    def normal(self) -> np.ndarray:
        n = np.cross(self.p[0] - self.p[1], self.p[2] - self.p[1])
        return _norm(n)

    @property
    def dist(self) -> float:
        return float(np.dot(self.normal, self.p[0]))

    def axes(self, scale=1.0):
        if self.u is not None:
            return self.u, self.v, self.su or scale, self.sv or scale, self.ou, self.ov
        if self.align == 'face':
            u, v = face_axes(self.normal)
        elif self.align == 'world':
            u, v = world_axes(self.normal)
        else:                               # 'readable' (default): never mirrored
            u, v = readable_axes(self.normal)
        return u, v, self.su or scale, self.sv or scale, self.ou, self.ov

    def set_axes(self, u, v, su=1.0, sv=1.0, ou=0.0, ov=0.0):
        self.u, self.v, self.su, self.sv, self.ou, self.ov = _v(u), _v(v), su, sv, ou, ov

    def fit(self, corner, size_u, size_v, readable=True):
        """Scale + shift so exactly one texture covers size_u x size_v units,
        starting at `corner` (texture fitting for crates, signs, doors...).
        readable=True orients it unmirrored for a viewer facing the face."""
        if readable:
            u, v = readable_axes(self.normal)
        else:
            u, v, _, _, _, _ = self.axes()
        tw, th = tex_size(self.tex)
        su = size_u / tw
        sv = size_v / th
        c = _v(corner)
        ou = -np.dot(c, u) / su
        ov = -np.dot(c, v) / sv
        self.set_axes(u, v, su, sv, ou % tw, ov % th)

    def line(self, scale=1.0) -> str:
        u, v, su, sv, ou, ov = self.axes(scale)
        pts = ' '.join('( ' + ' '.join(_fmt(c) for c in p) + ' )' for p in self.p)
        return (f'{pts} {self.tex} [ {_fmt(u[0])} {_fmt(u[1])} {_fmt(u[2])} {_fmt(ou)} ] '
                f'[ {_fmt(v[0])} {_fmt(v[1])} {_fmt(v[2])} {_fmt(ov)} ] {_fmt(self.rot)} {_fmt(su)} {_fmt(sv)}')


def _pick_tex(spec: TexSpec, normal) -> str:
    if callable(spec):
        return spec(normal)
    if isinstance(spec, str):
        return spec
    n = normal
    key = None
    if n[2] > 0.7:
        key = 'top'
    elif n[2] < -0.7:
        key = 'bottom'
    else:
        ax = max(range(2), key=lambda i: abs(n[i]))
        key = {(0, 1): 'e', (0, -1): 'w', (1, 1): 'n', (1, -1): 's'}[(ax, 1 if n[ax] > 0 else -1)]
    for k in (key, 'sides' if key in 'nsew' else None, 'all'):
        if k and k in spec:
            return spec[k]
    raise KeyError(f'texture spec has no entry for {key}: {spec}')


class Brush:
    def __init__(self, faces: List[Face]):
        self.faces = faces

    # --------------------------------------------------------------
    @classmethod
    def from_points(cls, pts: Sequence[Vec], tex: TexSpec, align='readable') -> 'Brush':
        """Convex hull brush from vertices (planes chosen through real vertices)."""
        from scipy.spatial import ConvexHull
        P = np.asarray(pts, dtype=np.float64)
        hull = ConvexHull(P)
        planes = []
        for eq in hull.equations:
            n, d = eq[:3], -eq[3]
            if not any(np.allclose(n, q[0], atol=1e-6) and abs(d - q[1]) < 1e-4 for q in planes):
                planes.append((n, d))
        cen = P[hull.vertices].mean(axis=0)
        faces = []
        V = P[hull.vertices]
        for n, d in planes:
            on = V[np.abs(V @ n - d) < 1e-3]
            a = on[0]
            b = on[np.argmax(np.linalg.norm(on - a, axis=1))]
            ab = _norm(b - a)
            off = on - a
            perp = np.linalg.norm(off - np.outer(off @ ab, ab), axis=1)
            c = on[np.argmax(perp)]
            # orient: normal = (p0 - p1) x (p2 - p1) must point outward
            p0, p1, p2 = a, b, c
            nn = np.cross(p0 - p1, p2 - p1)
            if np.dot(nn, n) < 0:
                p0, p2 = p2, p0
            faces.append(Face(p0, p1, p2, _pick_tex(tex, n), align))
        return cls(faces)

    @classmethod
    def box(cls, mins: Vec, maxs: Vec, tex: TexSpec) -> 'Brush':
        x0, y0, z0 = mins
        x1, y1, z1 = maxs
        assert x1 > x0 and y1 > y0 and z1 > z0, (mins, maxs)
        F_ = []
        # (p0, p1, p2) such that (p0-p1)x(p2-p1) is the outward normal
        F_.append(Face((x0, y0, z1), (x0, y1, z1), (x1, y0, z1), _pick_tex(tex, (0, 0, 1))))      # top
        F_.append(Face((x0, y0, z0), (x1, y0, z0), (x0, y1, z0), _pick_tex(tex, (0, 0, -1))))     # bottom
        F_.append(Face((x1, y0, z0), (x1, y0, z1), (x1, y1, z0), _pick_tex(tex, (1, 0, 0))))      # east
        F_.append(Face((x0, y0, z0), (x0, y1, z0), (x0, y0, z1), _pick_tex(tex, (-1, 0, 0))))     # west
        F_.append(Face((x0, y1, z0), (x1, y1, z0), (x0, y1, z1), _pick_tex(tex, (0, 1, 0))))      # north
        F_.append(Face((x0, y0, z0), (x0, y0, z1), (x1, y0, z0), _pick_tex(tex, (0, -1, 0))))     # south
        b = cls(F_)
        b._check()
        return b

    def _check(self):
        cen = self.center()
        for f in self.faces:
            assert np.dot(f.normal, cen) < f.dist + 1e-6, 'inward face normal'

    def vertices(self) -> np.ndarray:
        """Brush vertices (plane triple intersections inside all planes)."""
        planes = [(f.normal, f.dist) for f in self.faces]
        out = []
        n = len(planes)
        for i in range(n):
            for j in range(i + 1, n):
                for k in range(j + 1, n):
                    A = np.array([planes[i][0], planes[j][0], planes[k][0]])
                    if abs(np.linalg.det(A)) < 1e-9:
                        continue
                    p = np.linalg.solve(A, [planes[i][1], planes[j][1], planes[k][1]])
                    if all(np.dot(q[0], p) <= q[1] + 1e-3 for q in planes):
                        out.append(p)
        return np.array(out)

    def bbox(self):
        V = self.vertices()
        return V.min(axis=0), V.max(axis=0)

    def center(self):
        pts = np.array([p for f in self.faces for p in f.p])
        return pts.mean(axis=0)

    def translate(self, d: Vec) -> 'Brush':
        d = _v(d)
        for f in self.faces:
            f.p = [p + d for p in f.p]
            if f.u is not None:
                tw, th = tex_size(f.tex)
                f.ou = (f.ou - np.dot(d, f.u) / f.su) % tw
                f.ov = (f.ov - np.dot(d, f.v) / f.sv) % th
        return self

    def retex(self, tex: TexSpec, only: Optional[str] = None) -> 'Brush':
        """Change textures; only = name of the texture to replace (else all)."""
        for f in self.faces:
            if only is None or f.tex.lower() == only.lower():
                f.tex = _pick_tex(tex, f.normal)
        return self

    def face(self, direction: str) -> Face:
        d = {'top': (0, 0, 1), 'bottom': (0, 0, -1), 'e': (1, 0, 0), 'w': (-1, 0, 0), 'n': (0, 1, 0), 's': (0, -1, 0)}[direction]
        return max(self.faces, key=lambda f: float(np.dot(f.normal, d)))

    def fit_faces(self, which=('n', 's', 'e', 'w'), **kw):
        """Fit the texture once across the given box faces (crates, signs, doors)."""
        mn, mx = self.bbox()
        size = mx - mn
        for wch in which:
            f = self.face(wch)
            u, v = readable_axes(f.normal) if kw.get('readable', True) else f.axes()[:2]
            su = abs(np.dot(size, np.abs(u)))
            sv = abs(np.dot(size, np.abs(v)))
            corner = np.where(u < 0, mx, mn) * np.abs(u) + np.where(v < 0, mx, mn) * np.abs(v)
            f.fit(corner, su, sv, kw.get('readable', True))
        return self

    def to_str(self, scale_map: Dict[str, float]) -> str:
        lines = ['{']
        for f in self.faces:
            lines.append(f.line(scale_map.get(f.tex.lower(), 1.0)))
        lines.append('}')
        return '\n'.join(lines)


# ======================================================================
# entities & map
# ======================================================================
class Entity:
    def __init__(self, classname: str, brushes: Optional[List[Brush]] = None, **kv):
        self.props: Dict[str, str] = {'classname': classname}
        for k, v in kv.items():
            self[k] = v
        self.brushes: List[Brush] = list(brushes or [])

    def __setitem__(self, k, v):
        if isinstance(v, (tuple, list, np.ndarray)):
            v = ' '.join(_fmt(float(x)) for x in v)
        elif isinstance(v, float):
            v = _fmt(v)
        self.props[k] = str(v)

    def __getitem__(self, k):
        return self.props[k]

    def get(self, k, d=None):
        return self.props.get(k, d)

    @property
    def classname(self):
        return self.props['classname']

    def origin(self) -> Optional[np.ndarray]:
        o = self.props.get('origin')
        return _v([float(x) for x in o.split()]) if o else None

    def add(self, *brushes):
        for b in brushes:
            if isinstance(b, Brush):
                self.brushes.append(b)
            else:
                self.brushes.extend(b)
        return self

    def to_str(self, scale_map) -> str:
        out = ['{']
        for k, v in self.props.items():
            assert '"' not in v and '"' not in k, (k, v)
            out.append(f'"{k}" "{v}"')
        for b in self.brushes:
            out.append(b.to_str(scale_map))
        out.append('}')
        return '\n'.join(out)


class Map:
    """A whole map: worldspawn + entities."""

    def __init__(self, name: str, sky: str = 'night', wads: Sequence[str] = (), message: str = '',
                 extra: Optional[dict] = None, tex_scale: Optional[Dict[str, float]] = None):
        if sky not in STOCK_SKIES:
            raise ValueError(f'sky {sky!r} is not a stock CS sky {STOCK_SKIES}')
        self.name = name
        self.world = Entity('worldspawn', mapversion=220, skyname=sky, wad=';'.join(wads),
                            message=message or name, MaxRange=8192)
        for k, v in (extra or {}).items():
            self.world[k] = v
        self.entities: List[Entity] = []
        self.tex_scale = {k.lower(): v for k, v in (tex_scale or {}).items()}

    def add(self, *brushes):
        """Add world brushes (Brush or iterables of Brush)."""
        self.world.add(*brushes)
        return self

    def add_entity(self, *ents):
        for e in ents:
            if isinstance(e, Entity):
                self.entities.append(e)
            else:
                self.entities.extend(e)
        return self

    add_entities = add_entity

    def all_entities(self) -> List[Entity]:
        return [self.world] + self.entities

    def textures(self) -> List[str]:
        s = set()
        for e in self.all_entities():
            for b in e.brushes:
                for f in b.faces:
                    s.add(f.tex)
        return sorted(s, key=str.lower)

    def find(self, classname: str) -> List[Entity]:
        return [e for e in self.entities if e.classname == classname]

    def to_str(self) -> str:
        return '\n'.join(e.to_str(self.tex_scale) for e in self.all_entities()) + '\n'

    def write(self, path: str) -> str:
        with open(path, 'w', newline='\n') as f:
            f.write(self.to_str())
        return path

    def stats(self) -> dict:
        nb = sum(len(e.brushes) for e in self.all_entities())
        brush_ents = [e for e in self.entities if e.brushes]
        return {
            'world_brushes': len(self.world.brushes),
            'brushes': nb,
            'entities': len(self.entities) + 1,
            'brush_entities': len(brush_ents),
            'textures': len(self.textures()),
            'ct_spawns': len(self.find('info_player_start')),
            't_spawns': len(self.find('info_player_deathmatch')),
        }

    # ----------------------------------------------------------------
    def spawn_problems(self, min_spacing: float = 48.0) -> List[str]:
        """Approximate pre-compile spawn check (hull vs world brushes / spacing).
        bspcheck.check_spawns() does the exact test on the compiled hulls."""
        probs = []
        world = [(b, b.bbox()) for b in self.world.brushes]
        solid_ents = [e for e in self.entities if e.classname in ('func_wall', 'func_door', 'func_breakable')]
        for e in solid_ents:
            for b in e.brushes:
                world.append((b, b.bbox()))
        sp = [e for e in self.entities if e.classname in ('info_player_start', 'info_player_deathmatch')]
        for e in sp:
            o = e.origin()
            hmin, hmax = o - (16, 16, 36), o + (16, 16, 36)
            for b, (bmn, bmx) in world:
                if np.all(hmax > bmn + 0.01) and np.all(hmin < bmx - 0.01):
                    if all(f.tex.upper() not in (TRIGGER, 'HINT', 'SKIP') for f in b.faces):
                        if _box_hits_brush(hmin, hmax, b):
                            probs.append(f'{e.classname} at {o.tolist()} overlaps a solid brush')
                            break
        for i, a in enumerate(sp):
            for b in sp[i + 1:]:
                d = a.origin() - b.origin()
                if abs(d[2]) < 72 and max(abs(d[0]), abs(d[1])) < min_spacing:
                    probs.append(f'spawns too close: {a.origin().tolist()} {b.origin().tolist()}')
        return probs


def _box_hits_brush(hmin, hmax, b: Brush) -> bool:
    for f in b.faces:
        n, d = f.normal, f.dist
        corner = np.where(n > 0, hmin, hmax)   # box point with minimal n.x
        if np.dot(n, corner) >= d - 0.01:
            return False
    return True


# ======================================================================
# brush construction helpers (all return lists of Brush)
# ======================================================================
def box(mins: Vec, maxs: Vec, tex: TexSpec, fit: bool = False) -> List[Brush]:
    b = Brush.box(mins, maxs, tex)
    if fit:
        b.fit_faces()
    return [b]


def room(mins: Vec, maxs: Vec, wall: float = 16, tex: TexSpec = 'vx_conc_clean', floor: Optional[str] = None,
         ceil: Optional[str] = None, omit: Iterable[str] = (), sky_ceiling: bool = False) -> List[Brush]:
    """Hollow room: mins/maxs is the INTERIOR volume; shell grows outward.

    omit: subset of {'n','s','e','w','top','bottom'} to leave open (to join rooms).
    sky_ceiling: ceiling textured 'sky' (outdoor area).
    """
    x0, y0, z0 = mins
    x1, y1, z1 = maxs
    t = wall
    omit = set(omit)
    floor = floor or (tex if isinstance(tex, str) else tex.get('bottom', 'vx_conc_clean'))
    ceil = SKY if sky_ceiling else (ceil or (tex if isinstance(tex, str) else tex.get('top', 'vx_conc_clean')))
    wt = tex if isinstance(tex, str) else tex.get('sides', 'vx_conc_clean')
    out = []
    if 'bottom' not in omit:
        out += box((x0 - t, y0 - t, z0 - t), (x1 + t, y1 + t, z0), {'top': floor, 'all': wt if not sky_ceiling else wt})
    if 'top' not in omit:
        out += box((x0 - t, y0 - t, z1), (x1 + t, y1 + t, z1 + t), {'bottom': ceil, 'all': SKY if sky_ceiling else wt})
    if 'w' not in omit:
        out += box((x0 - t, y0, z0), (x0, y1, z1), wt)
    if 'e' not in omit:
        out += box((x1, y0, z0), (x1 + t, y1, z1), wt)
    if 's' not in omit:
        out += box((x0 - t, y0 - t, z0), (x1 + t, y0, z1), wt)
    if 'n' not in omit:
        out += box((x0 - t, y1, z0), (x1 + t, y1 + t, z1), wt)
    return out


def skybox(mins: Vec, maxs: Vec, t: float = 16, ground: Optional[str] = None) -> List[Brush]:
    """Seal an outdoor area: 6 sky slabs around interior mins/maxs.
    ground: if given, the floor slab is solid with this texture."""
    x0, y0, z0 = mins
    x1, y1, z1 = maxs
    out = []
    out += box((x0 - t, y0 - t, z1), (x1 + t, y1 + t, z1 + t), SKY)
    out += box((x0 - t, y0 - t, z0 - t), (x1 + t, y1 + t, z0), ground or SKY)
    out += box((x0 - t, y0, z0), (x0, y1, z1), SKY)
    out += box((x1, y0, z0), (x1 + t, y1, z1), SKY)
    out += box((x0 - t, y0 - t, z0), (x1 + t, y0, z1), SKY)
    out += box((x0 - t, y1, z0), (x1 + t, y1 + t, z1), SKY)
    return out


def wall(p0: Tuple[float, float], p1: Tuple[float, float], z0: float, z1: float, thick: float, tex: TexSpec,
         holes: Sequence[Tuple[float, float, float, float]] = (), side: str = 'center') -> List[Brush]:
    """Axis-aligned wall from p0 to p1 (x or y aligned) with rectangular holes.

    holes: (a0, a1, hz0, hz1) with a measured along the wall from p0 (units)
    and hz absolute z. side: 'center' | 'left' | 'right' placement of the
    thickness relative to the p0->p1 line (left = +90 degrees).
    """
    (ax, ay), (bx, by) = p0, p1
    horizontal = abs(by - ay) < 1e-6
    vertical = abs(bx - ax) < 1e-6
    assert horizontal ^ vertical, 'wall must be axis aligned'
    L = abs(bx - ax) if horizontal else abs(by - ay)
    sgn = 1 if (bx - ax + by - ay) > 0 else -1
    # thickness offsets
    if side == 'center':
        o0, o1 = -thick / 2, thick / 2
    else:
        left = side == 'left'
        # left normal of direction: for +x dir -> +y ; for +y dir -> -x
        if horizontal:
            nrm = sgn * (1 if left else -1)
        else:
            nrm = -sgn * (1 if left else -1)
        o0, o1 = (0, thick) if nrm > 0 else (-thick, 0)
    # split along a into columns
    cuts = {0.0, L}
    for h0, h1, _, _ in holes:
        cuts.add(max(0.0, min(L, h0)))
        cuts.add(max(0.0, min(L, h1)))
    cuts = sorted(cuts)
    out = []
    for a0, a1 in zip(cuts, cuts[1:]):
        if a1 - a0 < 1e-6:
            continue
        mid = (a0 + a1) / 2
        blocked = sorted((hz0, hz1) for h0, h1, hz0, hz1 in holes if h0 <= mid <= h1)
        z = z0
        spans = []
        for hz0, hz1 in blocked:
            if hz0 > z:
                spans.append((z, min(hz0, z1)))
            z = max(z, hz1)
        if z < z1:
            spans.append((z, z1))
        for s0, s1 in spans:
            if s1 - s0 < 1e-6:
                continue
            if horizontal:
                xa, xb = sorted((ax + sgn * a0, ax + sgn * a1))
                out += box((xa, ay + o0, s0), (xb, ay + o1, s1), tex)
            else:
                ya, yb = sorted((ay + sgn * a0, ay + sgn * a1))
                out += box((ax + o0, ya, s0), (ax + o1, yb, s1), tex)
    return out


def frame(p0, p1, z0, z1, thick, depth, tex: TexSpec, hole, trim=8) -> List[Brush]:
    """Trim frame (jambs + header) around a wall hole. p0/p1 = wall CENTRE
    line, depth = total frame depth (use wall thickness + 8 to protrude 4
    units on both sides), hole = (a0, a1, z0, z1) as in wall()."""
    (ax, ay), (bx, by) = p0, p1
    h0, h1, hz0, hz1 = hole
    horizontal = abs(by - ay) < 1e-6
    sgn = 1 if (bx - ax + by - ay) > 0 else -1
    d = depth / 2
    pieces = [(h0 - trim, h0, hz0, hz1 + trim), (h1, h1 + trim, hz0, hz1 + trim), (h0, h1, hz1, hz1 + trim)]
    out = []
    for a0, a1, s0, s1 in pieces:
        if horizontal:
            xa, xb = sorted((ax + sgn * a0, ax + sgn * a1))
            out += box((xa, ay - d, s0), (xb, ay + d, s1), tex)
        else:
            ya, yb = sorted((ay + sgn * a0, ay + sgn * a1))
            out += box((ax - d, ya, s0), (ax + d, yb, s1), tex)
    return out


_DIRS = {'+x': (1, 0), '-x': (-1, 0), '+y': (0, 1), '-y': (0, -1),
         'e': (1, 0), 'w': (-1, 0), 'n': (0, 1), 's': (0, -1)}


def stairs(origin: Vec, direction: str, width: float, height: float, rise: float = 8, run: float = 16,
           tex: TexSpec = 'vx_conc_clean', clip: bool = False) -> List[Brush]:
    """Solid staircase. origin = (x, y, z) at the bottom-front centre of the
    first step; climbs `height` toward `direction` ('+x','-y','n',...).
    Each step is a full-height block (no gaps). clip=True adds a CLIP ramp for
    smooth movement (slope = rise/run must stay < 0.7)."""
    dx, dy = _DIRS[direction]
    n = int(math.ceil(height / rise))
    rise = height / n
    x, y, z = origin
    out = []
    px, py = -dy, dx
    for i in range(n):
        a0, a1 = i * run, (i + 1) * run
        top = z + (i + 1) * rise
        c0 = (x + dx * a0 + px * width / 2, y + dy * a0 + py * width / 2)
        c1 = (x + dx * a1 - px * width / 2, y + dy * a1 - py * width / 2)
        mn = (min(c0[0], c1[0]), min(c0[1], c1[1]), z)
        mx = (max(c0[0], c1[0]), max(c0[1], c1[1]), top)
        out += box(mn, mx, tex)
    if clip:
        L = n * run
        out += wedge(origin, direction, width, L, height, CLIP)
    return out


def wedge(origin: Vec, direction: str, width: float, length: float, height: float, tex: TexSpec,
          align='face') -> List[Brush]:
    """Ramp: rises from z at origin (front edge centre) to z+height after
    `length` units in `direction`. Max walkable slope: height/length <= ~1.0
    (engine: normal.z >= 0.7 -> ~45.6 degrees)."""
    dx, dy = _DIRS[direction]
    px, py = -dy, dx
    x, y, z = origin
    pts = []
    for s in (-1, 1):
        bx, by = x + px * width / 2 * s, y + py * width / 2 * s
        pts.append((bx, by, z))
        pts.append((bx + dx * length, by + dy * length, z))
        pts.append((bx + dx * length, by + dy * length, z + height))
    b = Brush.from_points(pts, tex, align)
    return [b]


def prism(center: Tuple[float, float], radius: float, sides: int, z0: float, z1: float, tex: TexSpec,
          rot: float = 0.0, snap: float = 1.0) -> List[Brush]:
    """Vertical n-gon pillar (sides 6..16 recommended)."""
    cx, cy = center
    pts = []
    for i in range(sides):
        a = rot + 2 * math.pi * i / sides
        px = round((cx + math.cos(a) * radius) / snap) * snap
        py = round((cy + math.sin(a) * radius) / snap) * snap
        pts += [(px, py, z0), (px, py, z1)]
    return [Brush.from_points(pts, tex)]


def pipe(p0: Vec, p1: Vec, radius: float, sides: int = 8, tex: TexSpec = 'vx_pipe') -> List[Brush]:
    """Axis-aligned horizontal/vertical pipe (prism between two points)."""
    p0, p1 = _v(p0), _v(p1)
    axis = _norm(p1 - p0)
    ref = _v((0, 0, 1)) if abs(axis[2]) < 0.9 else _v((1, 0, 0))
    u = _norm(np.cross(axis, ref))
    v = np.cross(axis, u)
    pts = []
    for i in range(sides):
        a = 2 * math.pi * (i + 0.5) / sides
        off = (u * math.cos(a) + v * math.sin(a)) * radius
        pts += [tuple(np.round(p0 + off, 2)), tuple(np.round(p1 + off, 2))]
    return [Brush.from_points(pts, tex, align='face')]


def arch(center: Tuple[float, float], z_spring: float, radius: float, outer_w: float, top: float,
         depth: float, axis: str = 'x', segments: int = 8, tex: TexSpec = 'vx_stone_carved') -> List[Brush]:
    """Semicircular arch filling a rectangle above the springline.

    center: (x, y) of the opening centre; axis: wall runs along 'x' or 'y';
    opening width = 2*radius; rectangle spans +-outer_w/2 and z_spring..top.
    """
    cx, cy = center
    hw = outer_w / 2
    out = []
    corners = [(hw, top - z_spring), (-hw, top - z_spring)]
    for i in range(segments):
        a0 = math.pi * i / segments
        a1 = math.pi * (i + 1) / segments
        def inner(a):
            return (math.cos(a) * radius, math.sin(a) * radius)

        def outer(a):
            dx, dz = math.cos(a), math.sin(a)
            t = min(hw / abs(dx) if abs(dx) > 1e-9 else 1e9, (top - z_spring) / dz if dz > 1e-9 else 1e9)
            return (dx * t, dz * t)
        poly = [inner(a0), inner(a1), outer(a1), outer(a0)]
        for c in corners:
            ca = math.atan2(c[1], c[0])
            if a0 < ca < a1:
                poly.append(c)
        pts = []
        for (a, h) in poly:
            a, h = round(a, 2), round(h, 2)
            for d in (-depth / 2, depth / 2):
                if axis == 'x':
                    pts.append((cx + a, cy + d, z_spring + h))
                else:
                    pts.append((cx + d, cy + a, z_spring + h))
        out.append(Brush.from_points(pts, tex))
    return out


def railing(p0: Tuple[float, float], p1: Tuple[float, float], z: float, height: float = 40, style: str = 'masked',
            tex: str = '{vx_rail', post_tex: str = 'vx_metal_dark') -> Tuple[List[Brush], List[Brush]]:
    """Railing along an axis-aligned line at floor height z.

    Returns (visual_brushes, clip_brushes). style='masked': one thin brush with
    the {vx_rail texture (put it in a func_wall/func_illusionary with
    rendermode 4 / renderamt 255 - see masked_entity()). The clip brush keeps
    players from walking through it (put clip brushes in the world)."""
    (ax, ay), (bx, by) = p0, p1
    horizontal = abs(by - ay) < 1e-6
    vis, clip = [], []
    if horizontal:
        xa, xb = sorted((ax, bx))
        f = Brush.box((xa, ay - 1, z), (xb, ay + 1, z + height), {'n': tex, 's': tex, 'all': NULL})
        c = Brush.box((xa, ay - 4, z), (xb, ay + 4, z + height + 8), CLIP)
    else:
        ya, yb = sorted((ay, by))
        f = Brush.box((ax - 1, ya, z), (ax + 1, yb, z + height), {'e': tex, 'w': tex, 'all': NULL})
        c = Brush.box((ax - 4, ya, z), (ax + 4, yb, z + height + 8), CLIP)
    for fc in f.faces:
        if fc.tex == tex:
            tw, th = tex_size(tex)
            u, v = world_axes(fc.normal)
            fc.set_axes(u, v, 1.0, height / th, 0, (-(z + height) / (height / th)) % th)
    vis.append(f)
    clip.append(c)
    return vis, clip


def catwalk(p0: Tuple[float, float], p1: Tuple[float, float], z: float, width: float = 64, thick: float = 8,
            tex: TexSpec = 'vx_metal_diam', rails: str = 'both', rail_tex: str = '{vx_rail'):
    """Axis-aligned catwalk slab from p0 to p1 (centre line) with top at z.
    Returns (slab_brushes, rail_visual, rail_clip)."""
    (ax, ay), (bx, by) = p0, p1
    horizontal = abs(by - ay) < 1e-6
    hw = width / 2
    if horizontal:
        xa, xb = sorted((ax, bx))
        slab = box((xa, ay - hw, z - thick), (xb, ay + hw, z), tex)
        lines = [((xa, ay - hw + 2), (xb, ay - hw + 2)), ((xa, ay + hw - 2), (xb, ay + hw - 2))]
    else:
        ya, yb = sorted((ay, by))
        slab = box((ax - hw, ya, z - thick), (ax + hw, yb, z), tex)
        lines = [((ax - hw + 2, ya), (ax - hw + 2, yb)), ((ax + hw - 2, ya), (ax + hw - 2, yb))]
    sel = {'both': lines, 'left': lines[:1], 'right': lines[1:], 'none': []}[rails]
    vis, clip = [], []
    for a, b in sel:
        v, c = railing(a, b, z, tex=rail_tex)
        vis += v
        clip += c
    return slab, vis, clip


def ladder(base: Vec, facing: str, height: float, width: float = 32, depth: float = 16,
           visual_tex: str = '{vx_ladder') -> Tuple[Entity, List[Brush]]:
    """Ladder against a wall. base = (x, y, z) on the wall surface at the
    bottom centre; facing = direction the climber looks INTO the wall
    ('+x' means the wall is at +x of the ladder). Returns (func_ladder
    entity, visual brushes for a masked func_illusionary)."""
    dx, dy = _DIRS[facing]
    x, y, z = base
    px, py = -dy, dx
    # func_ladder volume: from wall outward `depth` units
    a = (x - dx * depth + px * width / 2, y - dy * depth + py * width / 2)
    b = (x - px * width / 2, y - py * width / 2)
    mn = (min(a[0], b[0]), min(a[1], b[1]), z)
    mx = (max(a[0], b[0]), max(a[1], b[1]), z + height)
    lad = Entity('func_ladder', [Brush.box(mn, mx, TRIGGER)])
    # visual: 2 unit thin slab against the wall
    a2 = (x - dx * 2 + px * width / 2, y - dy * 2 + py * width / 2)
    mn2 = (min(a2[0], b[0]), min(a2[1], b[1]), z)
    mx2 = (max(a2[0], b[0]), max(a2[1], b[1]), z + height)
    face_dir = {(1, 0): 'w', (-1, 0): 'e', (0, 1): 's', (0, -1): 'n'}[(dx, dy)]
    vis = Brush.box(mn2, mx2, {face_dir: visual_tex, 'all': NULL})
    f = vis.face(face_dir)
    tw, th = tex_size(visual_tex)
    u, v = world_axes(f.normal)
    # one texture across the width, rungs every 16 units vertically
    corner = _v(mn2) if np.dot(u, (1, 1, 0)) > 0 else _v(mx2)
    f.set_axes(u, v, width / tw, 1.0, (-np.dot(_v(corner), u) / (width / tw)) % tw, (-np.dot(_v((0, 0, z + height)), v)) % th)
    return lad, [vis]


def crate(origin: Vec, size: float = 64, tex: str = 'vx_crate_wood', height: Optional[float] = None,
          top: Optional[str] = None) -> List[Brush]:
    """Crate with the texture fitted exactly to each face. origin = bottom centre."""
    x, y, z = origin
    h = height or size
    b = Brush.box((x - size / 2, y - size / 2, z), (x + size / 2, y + size / 2, z + h),
                  {'top': top or tex, 'all': tex})
    b.fit_faces(('n', 's', 'e', 'w', 'top'))
    return [b]


def tex_fit(brushes: List[Brush], which=('n', 's', 'e', 'w')) -> List[Brush]:
    for b in brushes:
        b.fit_faces(which)
    return brushes


# ======================================================================
# entity helpers
# ======================================================================
def _o(origin):
    return tuple(float(c) for c in origin)


def light(origin: Vec, color=(255, 255, 255), brightness: float = 200, style: Optional[int] = None,
          fade: Optional[float] = None, targetname: Optional[str] = None) -> Entity:
    e = Entity('light', origin=_o(origin), _light=f'{int(color[0])} {int(color[1])} {int(color[2])} {int(brightness)}')
    if style is not None:
        e['style'] = style
    if fade is not None:
        e['_fade'] = fade
    if targetname:
        e['targetname'] = targetname
    return e


def light_spot(origin: Vec, pitch: float = -90, yaw: float = 0, color=(255, 255, 255), brightness: float = 300,
               cone: float = 30, cone2: float = 50) -> Entity:
    """Spotlight; pitch -90 points straight down."""
    return Entity('light_spot', origin=_o(origin), angles=(0, yaw, 0), pitch=pitch, _cone=cone, _cone2=cone2,
                  _light=f'{int(color[0])} {int(color[1])} {int(color[2])} {int(brightness)}')


def light_environment(pitch: float = -60, yaw: float = 135, color=(200, 210, 255), brightness: float = 120,
                      diffuse=None, origin: Vec = (0, 0, 0)) -> Entity:
    """Sun/sky light (needs sky brushes to emit). diffuse = (r,g,b,i) sky fill."""
    e = Entity('light_environment', origin=_o(origin), angles=(0, yaw, 0), pitch=pitch,
               _light=f'{int(color[0])} {int(color[1])} {int(color[2])} {int(brightness)}')
    if diffuse:
        e['_diffuse_light'] = ' '.join(str(int(c)) for c in diffuse)
    return e


def info_spawn(team: str, origin: Vec, yaw: float = 0) -> Entity:
    """team 'ct' -> info_player_start, 't' -> info_player_deathmatch.
    origin z should be floor + 37 (hull centre, 1 unit clearance)."""
    cls = 'info_player_start' if team.lower() == 'ct' else 'info_player_deathmatch'
    return Entity(cls, origin=_o(origin), angles=(0, yaw, 0))


def spawn_grid(classname_or_team: str, mins_xy: Tuple[float, float], maxs_xy: Tuple[float, float], floor_z: float,
               count: int, spacing: float = 64, yaw: Optional[float] = None, face: Optional[Tuple[float, float]] = None,
               margin: float = 24) -> List[Entity]:
    """Place `count` spawns on a grid inside a floor rectangle.

    margin: clearance from the rectangle edge to the hull edge (hull half
    width 16 is added). yaw: fixed facing; face=(x,y): face toward a point.
    Raises if the rectangle cannot hold `count` spawns."""
    cls = classname_or_team
    if cls.lower() in ('ct', 't'):
        cls = 'info_player_start' if cls.lower() == 'ct' else 'info_player_deathmatch'
    x0, y0 = mins_xy[0] + margin + 16, mins_xy[1] + margin + 16
    x1, y1 = maxs_xy[0] - margin - 16, maxs_xy[1] - margin - 16
    nx = int((x1 - x0) // spacing) + 1
    ny = int((y1 - y0) // spacing) + 1
    if nx * ny < count:
        raise ValueError(f'area holds only {nx}x{ny}={nx * ny} spawns at spacing {spacing}, need {count}')
    # centre the used grid
    used_rows = int(math.ceil(count / nx))
    gx0 = x0 + ((x1 - x0) - (nx - 1) * spacing) / 2
    gy0 = y0 + ((y1 - y0) - (used_rows - 1) * spacing) / 2
    out = []
    for i in range(count):
        cx = gx0 + (i % nx) * spacing
        cy = gy0 + (i // nx) * spacing
        if face is not None:
            yw = math.degrees(math.atan2(face[1] - cy, face[0] - cx))
        else:
            yw = yaw if yaw is not None else 0
        out.append(Entity(cls, origin=(round(cx), round(cy), floor_z + 37), angles=(0, round(yw), 0)))
    return out


def ambient(origin: Vec, sound: str, volume: int = 10, radius: str = 'medium', looped: bool = True,
            start_silent: bool = False, targetname: Optional[str] = None, pitch: int = 100) -> Entity:
    """ambient_generic. sound path relative to sound/ (e.g. 'vexmira/map/lab_hum.wav').
    radius: 'everywhere' | 'small' | 'medium' | 'large'. Looping needs a WAV
    with cue points; non-looped sounds play once when triggered."""
    flags = {'everywhere': 1, 'small': 2, 'medium': 4, 'large': 8}[radius]
    if start_silent:
        flags |= 16
    if not looped:
        flags |= 32
    e = Entity('ambient_generic', origin=_o(origin), message=sound, health=volume, pitch=pitch, pitchstart=pitch,
               spawnflags=flags)
    if targetname:
        e['targetname'] = targetname
    return e


def env_sprite(origin: Vec, model: str = 'sprites/glow01.spr', scale: float = 0.5, color=(255, 255, 255),
               renderamt: int = 200, rendermode: int = 5, framerate: float = 10, start_on: bool = True,
               targetname: Optional[str] = None) -> Entity:
    """Glow / animated sprite. rendermode 5 = additive (glows), 3 = glow.
    Stock sprites always present in CS: sprites/glow01.spr, flare1.spr,
    ledglow.spr, hotglow.spr, laserdot.spr, steam1.spr, bubble.spr."""
    e = Entity('env_sprite', origin=_o(origin), model=model, scale=scale, rendercolor=tuple(color),
               renderamt=renderamt, rendermode=rendermode, framerate=framerate, spawnflags=1 if start_on else 0)
    if targetname:
        e['targetname'] = targetname
    return e


def func_wall(brushes: List[Brush], rendermode: int = 0, renderamt: int = 255, **kw) -> Entity:
    return Entity('func_wall', brushes, rendermode=rendermode, renderamt=renderamt, **kw)


def func_illusionary(brushes: List[Brush], rendermode: int = 0, renderamt: int = 255, **kw) -> Entity:
    """Non-solid visual brushes (no clipnodes: cheap)."""
    return Entity('func_illusionary', brushes, rendermode=rendermode, renderamt=renderamt, **kw)


def masked_entity(brushes: List[Brush], solid: bool = True, **kw) -> Entity:
    """Entity for '{' masked textures: rendermode 4 (solid/alpha test) + renderamt 255."""
    cls = 'func_wall' if solid else 'func_illusionary'
    return Entity(cls, brushes, rendermode=4, renderamt=255, **kw)


def glass(brushes: List[Brush], breakable: bool = True, health: int = 20, renderamt: int = 90) -> Entity:
    """Transparent glass. rendermode 2 (texture), material 0 = glass gibs."""
    if breakable:
        return Entity('func_breakable', brushes, rendermode=2, renderamt=renderamt, material=0, health=health,
                      explodemagnitude=0, spawnobject=0)
    return Entity('func_wall', brushes, rendermode=2, renderamt=renderamt)


def breakable(brushes: List[Brush], material: int = 1, health: int = 100, **kw) -> Entity:
    """material: 0 glass, 1 wood, 2 metal, 3 flesh, 4 cinder, 5 ceiling tile, 6 computer, 7 unbreakable glass, 8 rocks."""
    return Entity('func_breakable', brushes, material=material, health=health, **kw)


def door(brushes: List[Brush], direction: str = 'up', speed: float = 100, wait: float = 4, lip: float = 8,
         sounds: int = 0, targetname: Optional[str] = None, toggle: bool = False, use_only: bool = False,
         dmg: int = 0) -> Entity:
    """func_door. direction: 'up' | 'down' | '+x' | '-x' | '+y' | '-y'.
    Zombie maps: avoid doors humans can hold shut forever (wait > 0, dmg>0)."""
    ang = {'up': (0, -1, 0), 'down': (0, -2, 0), '+x': (0, 0, 0), '-x': (0, 180, 0),
           '+y': (0, 90, 0), '-y': (0, 270, 0)}[direction]
    e = Entity('func_door', brushes, angles=ang, speed=speed, wait=wait, lip=lip, sounds=sounds, dmg=dmg)
    flags = 0
    if toggle:
        flags |= 32
    if use_only:
        flags |= 256
    e['spawnflags'] = flags
    if targetname:
        e['targetname'] = targetname
    return e


def func_water(brushes: List[Brush], current: int = 0) -> Entity:
    """Liquid entity (use a !texture). Plain world brushes with a !texture
    are cheaper (no model slot)."""
    return Entity('func_water', brushes, skin=-3, WaveHeight=0, rendermode=0)


def trigger_hurt(brushes: List[Brush], dmg: float = 20, damagetype: int = 8, targetname: Optional[str] = None) -> Entity:
    """Damage volume (AAATRIGGER brushes). damagetype 8 = burn, 0x40000 = acid (16 freeze? 256 shock...)."""
    e = Entity('trigger_hurt', brushes, dmg=dmg, damagetype=damagetype)
    if targetname:
        e['targetname'] = targetname
    return e


def func_buyzone(brushes: List[Brush], team: int = 2) -> Entity:
    return Entity('func_buyzone', brushes, team=team)


def info_map_parameters(buying: int = 0) -> Entity:
    """buying: 0 everyone can buy, 1 only CT, 2 only T, 3 nobody."""
    return Entity('info_map_parameters', buying=buying)
