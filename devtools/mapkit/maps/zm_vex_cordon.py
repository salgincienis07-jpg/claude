"""zm_vex_cordon - "Cordon 7": a night harbor district of Vexmira sealed behind a military
quarantine wall (flagship map). Build spec: maps/zm_vex_cordon_SPEC.md (binding).

    cd devtools && python3 -m mapkit.maps.zm_vex_cordon [--quality draft|normal|final] [--preview DIR]
                                                        [--mock] [--dry]

STAGE 1 + 2 (this file so far): blockout + VIS + spawns; detail, textures, lighting, sprites, ambience, sounds
(`--sounds` resynthesises cstrike/sound/vexmira/map/cd_*.wav). Stage 3 wires the set-piece chains.
Every district is a sealed, sky-capped cell (outdoor) or a ceilinged room (indoor); districts are
joined only by low openings (headers <= 256) placed off-axis, by short tunnels or dog-legs, so VIS
keeps every view small. Levels: city z 0, harbor z -128, tower floors 0/192/384, roof 576.

    v  no-man's land vista (unreachable)      A  Gate 7 checkpoint (CT spawn)
    c  command post   a  supply alley         M  market street (M1 + M2, S-bend)   m arcade   p pharmacy
    R  terminus station (T spawn, derailed train, ticket block)   f1/f2 forecourt dog-legs
    H  field hospital yard, w triage ward     S  substation yard, h switch house, gantry deck (camp)
    L  lantern lane (Z-bend)                  P  Liberation Plaza (boss arena, 7 mouths)
    T0..T3 Customs Tower (lobby, offices, plant, roof + crown), 2 stair cores   t south passage
    K  Kade harbor road (2 gate arches, ramp to -128)   n stair lane   F fish market hall (loft camp)
    e  harbor steps (memorial)   Q quay + bridge cabin   ~ canal (lift bridge)   C container terminal
    B  bay vista (unreachable, freighter VIS blocker)   hangar (sealed, helicopter waits there)

Zone tool: `zone()` builds a cell from a union of rectangles: floor slab, top slab (sky or
ceiling, optional sky strips / holes), and walls 16 thick OUTSIDE the boundary, each wall facade
up to its roofline and sky above, with rectangular holes. Shared walls belong to ONE zone (the
other zone passes a `skip` hole). `--mock` adds func_detail boxes at 100 % of the spec's per-zone
face budgets (perf check of the VIS structure only, compiled to the work dir, never shipped).
"""
from __future__ import annotations

import argparse
import os
import random
import sys

import math
import struct

import numpy as np

from ..mapwriter import (CLIP, NULL, Brush, Entity, Map, ambient, box, crate, door, env_sprite, glass, ladder, light,
                         light_environment, light_spot, masked_entity, prism, readable_axes, spawn_grid, stairs,
                         wedge)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
NAME = 'zm_vex_cordon'

T = 16
INF = 100000
CORNICE = True
SKY = 'sky'
HINT, SKIP = 'HINT', 'SKIP'

# palette (spec section 11): wet night city under quarantine
FAC = 'vx_facade'
BRICK = 'vx_brick_dark'
QUAR = 'vx_quar_wall'
SHOP = 'vx_shopfront'
TARP = 'vx_tarp'
SIGNS = 'vx_signs'
ARROW = '~vx_arrow'
CHEV = '+0vx_chev'          # animated neon chevrons (chasing light toward the arrow direction)
HAZ = 'vx_trim_hazard'
MIL = 'vx_crate_mil'
LRED = '~vx_light_r'
BAY = 'vx_bay'
CONC = 'vx_conc_stain'
CRACK = 'vx_conc_crack'
ASPH = 'vx_asphalt'
PLAST = 'vx_plaster'
TILE = 'vx_tile_dirty'
MDARK = 'vx_metal_dark'
RUST = 'vx_metal_rust'
CORR = 'vx_metal_corr'
BUNK = 'vx_bunker'
WATER = '!vx_water_dk'

TEX_SCALE = {ASPH: 2, CRACK: 2, CONC: 2, FAC: 2, QUAR: 2, BAY: 4, BRICK: 1.5, TARP: 2, CORR: 2, PLAST: 1.5,
             'vx_dirt': 2, 'vx_rock': 2}


# ==============================================================================================
# geometry helpers
def _boundary(rects):
    """Boundary segments of a union of axis rectangles: (axis, line, a0, a1, sgn).
    axis 'x' = wall on the line x=line (runs along y), sgn = +1 when the outside is at +axis."""
    xs = sorted({r[0] for r in rects} | {r[2] for r in rects})
    ys = sorted({r[1] for r in rects} | {r[3] for r in rects})

    def inside(px, py):
        return any(r[0] < px < r[2] and r[1] < py < r[3] for r in rects)

    nx, ny = len(xs) - 1, len(ys) - 1
    ins = [[inside((xs[i] + xs[i + 1]) / 2, (ys[j] + ys[j + 1]) / 2) for j in range(ny)] for i in range(nx)]
    segs = []
    for i, x in enumerate(xs):
        for j in range(ny):
            lo = ins[i - 1][j] if i > 0 else False
            hi = ins[i][j] if i < nx else False
            if lo != hi:
                segs.append(('x', x, ys[j], ys[j + 1], 1 if lo else -1))
    for j, y in enumerate(ys):
        for i in range(nx):
            lo = ins[i][j - 1] if j > 0 else False
            hi = ins[i][j] if j < ny else False
            if lo != hi:
                segs.append(('y', y, xs[i], xs[i + 1], 1 if lo else -1))
    segs.sort(key=lambda s: (s[0], s[1], s[4], s[2]))
    out = []
    for s in segs:
        o = out[-1] if out else None
        if o and o[0] == s[0] and o[1] == s[1] and o[4] == s[4] and o[3] == s[2]:
            out[-1] = (o[0], o[1], o[2], s[3], o[4])
        else:
            out.append(s)
    return out, inside


def _solid(a0, a1, z0, z1, holes):
    """Solid (a, z) rectangles of the strip [a0,a1]x[z0,z1] minus holes (b0, b1, h0, h1)."""
    hs = [(max(b0, a0), min(b1, a1), max(h0, z0), min(h1, z1)) for b0, b1, h0, h1 in holes]
    hs = [h for h in hs if h[1] - h[0] > 0.5 and h[3] - h[2] > 0.5]
    bps = sorted({a0, a1} | {h[0] for h in hs} | {h[1] for h in hs})
    cols = []
    for p, q in zip(bps, bps[1:]):
        mid = (p + q) / 2
        cut = sorted((h[2], h[3]) for h in hs if h[0] < mid < h[1])
        sol, cur = [], z0
        for c0, c1 in cut:
            if c0 > cur:
                sol.append((cur, c0))
            cur = max(cur, c1)
        if cur < z1:
            sol.append((cur, z1))
        if cols and cols[-1][2] == sol and cols[-1][1] == p:
            cols[-1][1] = q
        else:
            cols.append([p, q, sol])
    return [(p, q, s0, s1) for p, q, sol in cols for s0, s1 in sol]


def rect_minus(rect, holes):
    """Axis rectangle minus rectangles -> list of rectangles (x0, y0, x1, y1)."""
    x0, y0, x1, y1 = rect
    hs = [(max(h[0], x0), max(h[1], y0), min(h[2], x1), min(h[3], y1)) for h in holes]
    hs = [h for h in hs if h[2] > h[0] and h[3] > h[1]]
    return [(p, s0, q, s1) for p, q, s0, s1 in _solid(x0, x1, y0, y1, [(h[0], h[2], h[1], h[3]) for h in hs])]


def _band(axis, line, sgn):
    return (line, line + T) if sgn > 0 else (line - T, line)


def _wall_box(axis, line, sgn, a0, a1, z0, z1, tex_in, tex_out):
    c0, c1 = _band(axis, line, sgn)
    if axis == 'x':
        inner, outer = ('w', 'e') if sgn > 0 else ('e', 'w')
        return box((c0, a0, z0), (c1, a1, z1), {inner: tex_in, outer: tex_out, 'all': tex_in})
    inner, outer = ('s', 'n') if sgn > 0 else ('n', 's')
    return box((a0, c0, z0), (a1, c1, z1), {inner: tex_in, outer: tex_out, 'all': tex_in})


class Zone:
    def __init__(self, key, rects, z0, z1):
        self.key, self.rects, self.z0, self.z1 = key, rects, z0, z1

    def centre(self):
        r = max(self.rects, key=lambda r: (r[2] - r[0]) * (r[3] - r[1]))
        return ((r[0] + r[2]) / 2, (r[1] + r[3]) / 2)


class Builder:
    def __init__(self, mock=False):
        self.m = Map(NAME + ('_mock' if mock else ''), sky='vexmira_night', tex_scale=TEX_SCALE)
        self.mock = mock
        self.det = []          # func_detail
        self.zones = {}
        self.ents = []
        self.lad_vis = {}      # area -> ladder visual brushes (one masked func_illusionary per area)
        self._hints = set()

    # ------------------------------------------------------------------ primitives
    def W(self, bl):
        self.m.add(bl)

    def D(self, bl):
        self.det += bl

    def slab(self, rect, z0, z1, tex, holes=(), sky=()):
        for r in rect_minus(rect, list(holes) + list(sky)):
            self.W(box((r[0], r[1], z0), (r[2], r[3], z1), tex))
        for s in sky:
            x0, y0, x1, y1 = max(s[0], rect[0]), max(s[1], rect[1]), min(s[2], rect[2]), min(s[3], rect[3])
            if x1 > x0 and y1 > y0:
                self.W(box((x0, y0, z0), (x1, y1, z1), SKY))

    def zone(self, key, rects, z0, z1, floor, wall, top=SKY, rl=None, rls=(), holes=(), out=None,
             top_holes=(), top_sky=(), omit=(), hint_z=None):
        """Sealed cell. rects: (x0,y0,x1,y1) interior; rl: default roofline (facade below, sky above,
        None = z1); rls: (axis, line, a0, a1, rl) roofline spans; holes: (axis, line, a0, a1, h0, h1)
        absolute (line = interior boundary coordinate); out: {(axis, line): tex} outer face texture."""
        zn = Zone(key, rects, z0, z1)
        self.zones[key] = zn
        rl = z1 if rl is None else rl
        out = out or {}
        ext = lambda r: (r[0] - T, r[1] - T, r[2] + T, r[3] + T)
        for r in rects:
            if 'bottom' not in omit:
                self.W(box((r[0] - T, r[1] - T, z0 - T), (r[2] + T, r[3] + T, z0), floor))
            if 'top' not in omit:
                th = [h for h in top_holes]
                self.slab(ext(r), z1, z1 + T, top if top != SKY else SKY, holes=th,
                          sky=top_sky if top != SKY else ())
        segs, inside = _boundary(rects)
        cols = set()
        for axis, line, a0, a1, sgn in segs:
            hl = [(h[2], h[3], h[4], h[5]) for h in holes if h[0] == axis and h[1] == line]
            spans = [(s[2], s[3], s[4]) for s in rls if s[0] == axis and s[1] == line]
            bps = sorted({a0, a1} | {v for sp in spans for v in sp[:2] if a0 < v < a1})
            tin = wall
            tout = out.get((axis, line), wall)
            for p, q in zip(bps, bps[1:]):
                mid = (p + q) / 2
                r = next((sp[2] for sp in spans if sp[0] <= mid <= sp[1]), rl)
                r = max(z0, min(r, z1))
                for b0, b1, s0, s1 in _solid(p, q, z0, r, hl):
                    self.W(_wall_box(axis, line, sgn, b0, b1, s0, s1, tin, tout))
                for b0, b1, s0, s1 in _solid(p, q, r, z1, hl):
                    self.W(_wall_box(axis, line, sgn, b0, b1, s0, s1, SKY, SKY))
                if CORNICE and z0 + 96 < r < z1 and q - p >= 32:
                    # roof cap / cornice: a 16-deep, 24-high stone band on top of the facade (visible wall
                    # thickness; the building no longer ends in a paper-thin edge against the sky)
                    i0, i1 = (line - 16, line) if sgn > 0 else (line, line + 16)
                    face_in = {'x': ('w' if sgn > 0 else 'e'), 'y': ('s' if sgn > 0 else 'n')}[axis]
                    spec = {'all': NULL, face_in: CONC, 'bottom': CONC, 'top': CONC}
                    mn = (i0, p, r - 16) if axis == 'x' else (p, i0, r - 16)
                    mx = (i1, q, r + 8) if axis == 'x' else (q, i1, r + 8)
                    self.det += box(mn, mx, spec)
            # corner columns (convex corners only)
            c0, c1 = _band(axis, line, sgn)
            for e0, e1 in ((a0 - T, a0), (a1, a1 + T)):
                cx, cy = ((c0 + c1) / 2, (e0 + e1) / 2) if axis == 'x' else ((e0 + e1) / 2, (c0 + c1) / 2)
                if inside(cx, cy):
                    continue
                k = (axis, c0, c1, e0, e1)
                if k in cols:
                    continue
                cols.add(k)
                mn = (c0, e0) if axis == 'x' else (e0, c0)
                mx = (c1, e1) if axis == 'x' else (e1, c1)
                # skip columns fully inside a skip-hole of this edge (owned by the neighbour)
                col_holes = [(h0, h1) for b0, b1, h0, h1 in hl if b0 <= e0 and b1 >= e1]
                zs = _solid(0, 1, z0, z1, [(0, 1, h0, h1) for h0, h1 in col_holes])
                for _, _, s0, s1 in zs:
                    self.W(box((mn[0], mn[1], s0), (mx[0], mx[1], s1), tin if s1 <= max(rl, z0) else SKY))
        # VIS: HINT plane in every finite opening (splits the zone exactly at its mouth) ...
        for h in holes:
            axis, line, a0, a1, h0, h1 = h
            if a0 <= -INF or a1 >= INF or h0 <= -INF or h1 >= INF or h1 >= z1:
                continue
            seg = next((sg for sg in segs if sg[0] == axis and sg[1] == line and sg[2] <= a0 and sg[3] >= a1), None)
            if seg is None:
                continue
            c0, c1 = _band(axis, line, seg[4])
            mn = (c0, a0, max(h0, z0)) if axis == 'x' else (a0, c0, max(h0, z0))
            mx = (c1, a1, min(h1, z1)) if axis == 'x' else (a1, c1, min(h1, z1))
            key = (mn, mx)
            if key not in self._hints:
                self._hints.add(key)
                self.hint(mn, mx, axis)
        # ... and an optional horizontal plane at header height (separates the open air above
        # the headers from the street level, so the leaves people stand in see less)
        if hint_z is not None:
            for r in rects:
                self.hint((r[0], r[1], hint_z), (r[2], r[3], hint_z + 8), 'z')
        return zn

    def tunnel(self, axis, a0, a1, b0, b1, z0, z1, wall, floor, ceil):
        """Passage between two zone walls: along `axis` from a0 to a1, cross-section b0..b1 x z0..z1."""
        if axis == 'x':
            self.W(box((a0, b0 - T, z0 - T), (a1, b1 + T, z0), floor))
            self.W(box((a0, b0 - T, z1), (a1, b1 + T, z1 + T), ceil))
            self.W(box((a0, b0 - T, z0), (a1, b0, z1), wall))
            self.W(box((a0, b1, z0), (a1, b1 + T, z1), wall))
        else:
            self.W(box((b0 - T, a0, z0 - T), (b1 + T, a1, z0), floor))
            self.W(box((b0 - T, a0, z1), (b1 + T, a1, z1 + T), ceil))
            self.W(box((b0 - T, a0, z0), (b0, a1, z1), wall))
            self.W(box((b1, a0, z0), (b1 + T, a1, z1), wall))

    def hint(self, mins, maxs, face):
        """HINT brush: HINT on the two faces normal to `face` axis ('x'|'y'|'z'), SKIP elsewhere."""
        keys = {'x': ('e', 'w'), 'y': ('n', 's'), 'z': ('top', 'bottom')}[face]
        self.W(box(mins, maxs, {keys[0]: HINT, keys[1]: HINT, 'all': SKIP}))

    def ladder(self, area, base, facing, height):
        e, vis = ladder(base, facing, height)
        self.ents.append(e)
        self.lad_vis.setdefault(area, []).extend(vis)

    def ent(self, e):
        self.ents.append(e)
        return e


# ==============================================================================================
# STAGE 2: dressing (func_detail props, signage, decals), lighting, sprites, ambience
# ----------------------------------------------------------------------------------------------
def P(mn, mx, tex, hide=('bottom',)):
    """Prop box; faces in `hide` (resting on the floor / against a wall) are NULL (never drawn)."""
    spec = {'all': tex}
    for h in hide:
        spec[h] = NULL
    return box(mn, mx, spec)


def _fit(f, mn, mx, u, v, tw, th, rows=1, row=0):
    """Map one texture (or one row of an atlas) exactly across the face of box (mn, mx)."""
    u, v = np.array(u, float), np.array(v, float)
    cs = [np.array((x, y, z), float) for x in (mn[0], mx[0]) for y in (mn[1], mx[1]) for z in (mn[2], mx[2])]
    pu, pv = [float(np.dot(c, u)) for c in cs], [float(np.dot(c, v)) for c in cs]
    su, sv = (max(pu) - min(pu)) / tw, (max(pv) - min(pv)) / (th / rows)
    f.set_axes(u, v, su, sv, (-min(pu) / su) % tw, (row * th / rows - min(pv) / sv) % th)


_NORM = {'n': (0, 1, 0), 's': (0, -1, 0), 'e': (1, 0, 0), 'w': (-1, 0, 0), 'top': (0, 0, 1)}
_OPP = {'n': 's', 's': 'n', 'e': 'w', 'w': 'e', 'top': 'bottom'}


def plate(face, mn, mx, tex, edge=MDARK, row=None, arrow=None, rows=4):
    """Thin plate (sign / arrow / shopfront) showing `face`; its back is NULL. row = vx_signs atlas
    row (text stays readable, the printed arrow points to the viewer's right); arrow = world
    direction (dx, dy, 0) for ~vx_arrow (symmetric, so u can follow the direction freely)."""
    if min(abs(b - a) for a, b in zip(mn, mx)) <= 4:
        edge = NULL       # thin plate: its 1-4 unit rims are never noticed -> do not draw them (r_speeds)
    br = box(mn, mx, {face: tex, _OPP[face]: NULL, 'all': edge})[0]
    f = br.face(face)
    from ..mapwriter import tex_size
    tw, th = tex_size(tex)
    n = np.array(_NORM[face], float)
    if arrow is not None:
        u = np.array(arrow, float)
        v = np.cross(n, u) if face == 'top' else np.array((0, 0, -1.0))
        _fit(f, mn, mx, u, v, tw, th)
    elif row is not None:
        u, v = readable_axes(n)
        _fit(f, mn, mx, u, v, tw, th, rows=rows, row=row)
    else:
        u, v = readable_axes(n)
        _fit(f, mn, mx, u, v, tw, th)
    return [br]


def wall_plate(face, line, a0, a1, z0, z1, tex, depth=4, **kw):
    """Plate on a wall: `face` = direction it faces (into the room), line = wall surface coordinate."""
    if face in ('e', 'w'):
        x0, x1 = (line, line + depth) if face == 'e' else (line - depth, line)
        return plate(face, (x0, a0, z0), (x1, a1, z1), tex, **kw)
    y0, y1 = (line, line + depth) if face == 'n' else (line - depth, line)
    return plate(face, (a0, y0, z0), (a1, y1, z1), tex, **kw)


def sign(face, line, a, z, row, depth=4):
    """District sign 128 x 32 (vx_signs row); `a` = left edge along the wall as the viewer sees it."""
    u, _ = readable_axes(np.array(_NORM[face], float))
    a0 = a if (u[0] + u[1]) > 0 else a - 128
    return wall_plate(face, line, a0, a0 + 128, z, z + 32, SIGNS, depth, row=row)


def floor_arrow(x, y, z, d, size=48):
    """Green EVAC arrow on the floor, pointing along world direction d = (dx, dy)."""
    h = size / 2
    return plate('top', (x - h, y - h, z), (x + h, y + h, z + 1), CHEV, arrow=(d[0], d[1], 0))


def car(cx, cy, axis, tex=RUST, z=0, burnt=False):
    """Wrecked car (2 boxes, ~9 drawn faces). axis 'x' or 'y' = long axis."""
    L, W = 104, 52
    hx, hy = (L / 2, W / 2) if axis == 'x' else (W / 2, L / 2)
    out = P((cx - hx, cy - hy, z), (cx + hx, cy + hy, z + 34), tex)
    cxo, cyo = (cx - 6, cy) if axis == 'x' else (cx, cy - 6)
    kx, ky = (hx * 0.5, hy - 4) if axis == 'x' else (hx - 4, hy * 0.5)
    out += P((cxo - kx, cyo - ky, z + 34), (cxo + kx, cyo + ky, z + 58), MDARK if not burnt else RUST)
    return out


def jersey(axis, a0, a1, c, z=0):
    """Concrete jersey barrier (trapezoid section, 32 high) along `axis` from a0 to a1 at cross coord c."""
    pts = []
    for a in (a0, a1):
        for off, zz in ((-14, 0), (14, 0), (-5, 32), (5, 32)):
            pts.append((a, c + off, z + zz) if axis == 'x' else (c + off, a, z + zz))
    b = Brush.from_points(pts, {'bottom': NULL, 'all': BUNK})
    return [b]


def tent(x0, y0, x1, y1, h=96, axis='x'):
    """Ridge tent (triangular prism, olive canvas with red cross)."""
    if axis == 'x':
        ym = (y0 + y1) / 2
        pts = [(x0, y0, 0), (x0, y1, 0), (x0, ym, h), (x1, y0, 0), (x1, y1, 0), (x1, ym, h)]
    else:
        xm = (x0 + x1) / 2
        pts = [(x0, y0, 0), (x1, y0, 0), (xm, y0, h), (x0, y1, 0), (x1, y1, 0), (xm, y1, h)]
    return [Brush.from_points(pts, {'bottom': NULL, 'all': TARP})]


def lamp_post(x, y, z=0, h=208, arm=(0, 0)):
    """Street lamp: pole + head (head bottom is an unlit fixture; the light entity does the work)."""
    out = P((x - 4, y - 4, z), (x + 4, y + 4, z + h), MDARK)
    hx, hy = x + arm[0], y + arm[1]
    if arm != (0, 0):
        out += P((min(x, hx) - 3, min(y, hy) - 3, z + h - 8), (max(x, hx) + 3, max(y, hy) + 3, z + h), MDARK, hide=())
    out += P((hx - 12, hy - 8, z + h - 14), (hx + 12, hy + 8, z + h - 4), MDARK, hide=())
    return out


def emer(face, line, a, z):
    """Red emergency cage lamp on a wall (texlight 16x16)."""
    return wall_plate(face, line, a - 8, a + 8, z, z + 16, LRED, depth=8)


def dress(b):
    D, W, E = b.D, b.W, b.ent
    ents = b.ents

    def L(p, col, br, **kw):
        e = light(p, col, br, **kw)
        ents.append(e)
        return e

    def SW(p, col, br, name, fade=None):
        """Switchable light (starts dark; styles 32+ assigned by RAD per targetname)."""
        e = light(p, col, br, targetname=name, fade=fade)
        e['spawnflags'] = 1
        ents.append(e)
        return e

    def SPR(p, col, scale=0.35, name=None, on=True, fx=0, amt=200, model='sprites/glow01.spr', fr=10):
        e = env_sprite(p, model, scale, col, amt, 5 if 'glow' in model else 5, fr, on, name)
        if fx:
            e['renderfx'] = fx
        ents.append(e)
        return e

    def AMB(p, snd, vol=6, rad='large', name=None, silent=False, pitch=100, loop=True):
        ents.append(ambient(p, 'vexmira/map/' + snd, vol, rad, loop, silent, name, pitch))

    def DEC(p, name):
        ents.append(Entity('infodecal', origin=f'{p[0]} {p[1]} {p[2]}', texture=name))

    SODIUM, MOON, FIRE, COLD, RED = (255, 170, 80), (150, 170, 220), (255, 120, 40), (170, 190, 230), (255, 40, 30)
    CYAN, WHITE = (60, 220, 255), (235, 240, 255)

    # ------------------------------------------------------------ A  Gate 7 checkpoint (CT spawn)
    D(P((-2480, 2400, 0), (-2384, 2496, 112), BUNK))                              # guard booth
    D(P((-2488, 2392, 112), (-2376, 2504, 120), MDARK, hide=()))                   # booth roof
    D(wall_plate('s', 2400, -2464, -2400, 48, 72, 'vx_glass', depth=2))            # booth window
    for a0, a1 in ((-2960, -2800), (-2480, -2320)):
        D(jersey('x', a0, a1, 2300))                                               # funnel to the gate
    D(jersey('y', 2000, 2192, -2100))
    for x0, y0 in ((-3296, 2000), (-3296, 2232)):
        D(tent(x0, y0, x0 + 176, y0 + 160, 104))                                   # field tents (W wall)
    for x, y, z, sz in ((-2360, 1460, 0, 64), (-2296, 1460, 0, 64), (-2328, 1460, 64, 56),
                        (-2160, 1452, 0, 48), (-2112, 1452, 0, 48)):
        D(crate((x, y, z), sz, MIL))
    D(P((-2216, 2396, 0), (-2120, 2480, 64), MDARK))                               # generator
    D(P((-2208, 2404, 64), (-2184, 2420, 104), MDARK))                             # exhaust
    for x in (-2944, -2176):
        D(P((x - 6, 2484, 0), (x + 6, 2496, 352), MDARK))                          # flood masts
        D(P((x - 24, 2464, 336), (x + 24, 2496, 360), MDARK, hide=()))
        D(wall_plate('s', 2464, x - 20, x + 20, 340, 356, '~vx_light_w', depth=1))
        SPR((x, 2460, 348), WHITE, 0.6, amt=170)                                   # Gate 7 flood glows (x2)
        ents.append(light_spot((x, 2440, 330), -55, 270, WHITE, 900, 40, 70))
    L((-2440, 2448, 132), RED, 70)                                                  # booth red beacon
    SPR((-2440, 2448, 128), RED, 0.25, fx=4)
    for y in (1700, 2000):
        L((-2650, y, 280), MOON, 110)                                               # moon fill (yard)
    L((-2200, 1500, 90), SODIUM, 70)
    AMB((-2650, 1984, 200), 'cd_wind.wav', 7)
    AMB((-2168, 2440, 40), 'cd_hum.wav', 5, 'medium', pitch=70)                    # generator (always on)
    # guidance: sally port + alley mouths (CT spawn view)
    D(wall_plate('w', -1984, 1820, 1876, 72, 128, ARROW, arrow=(0, 1, 0)))        # -> sally port
    D(wall_plate('w', -1984, 2156, 2212, 72, 128, ARROW, arrow=(0, -1, 0)))
    D(floor_arrow(-2240, 1500, 0, (0, -1)))                                        # -> supply alley
    D(sign('n', 1408, -2100, 200, 0))                                              # SUBSTATION over the alley
    DEC((-2600, 2100, 1), '{scorch1')
    DEC((-2380, 2300, 1), '{scorch2')

    # ------------------------------------------------------------ c command post / a supply alley
    D(P((-2960, 1272, 0), (-2832, 1336, 36), MDARK))                               # map table
    D(plate('top', (-2952, 1280, 36), (-2840, 1328, 37), 'vx_signs', row=3))      # route chart on it
    for x in (-3056, -2496):
        D(P((x, 1060, 0), (x + 48, 1100, 72), MIL))
    D(emer('s', 1392, -2900, 140))
    L((-2900, 1360, 140), RED, 70)
    L((-2896, 1300, 90), (255, 200, 140), 70)                                       # desk lamp
    SW((-2752, 1216, 150), SODIUM, 80, 'cd_lt_west')
    AMB((-2752, 1216, 100), 'cd_wind.wav', 4, 'medium', pitch=85)
    D(P((-2296, 1048, 0), (-2216, 1112, 40), TARP))                                # sandbags (alley)
    D(P((-2112, 1304, 0), (-2064, 1384, 48), MIL))
    SW((-2176, 1216, 260), SODIUM, 110, 'cd_lt_west')
    L((-2176, 1216, 200), MOON, 50)
    DEC((-2150, 1150, 1), '{blood3')

    # ------------------------------------------------------------ S substation + h switch house + gantry
    for i in range(3):
        x = -3168 + i * 352
        for j, xo in enumerate((48, 112, 176)):                                    # insulators on the 3 transformers
            D(P((x + xo - 6, -318, 192), (x + xo + 6, -306, 232), 'vx_metal_dark'))
        D(P((x - 8, -392, 0), (x, -232, 160), CORR, hide=('bottom', 'e')))         # cooling fins
        D(P((x + 224, -392, 0), (x + 232, -232, 160), CORR, hide=('bottom', 'w')))
        DEC((x + 112, -440, 1), '{scorch2' if i == 1 else '{scorch1')
    cages = []
    for i in range(3):                                                             # fence cages (one masked entity)
        x = -3168 + i * 352
        x0, x1, y0, y1 = x - 48, x + 272, -464, -160
        cages += box((x0, y1 - 2, 0), (x1, y1, 160), '{vx_fence')
        cages += box((x0, y0, 0), (x0 + 2, y1 - 2, 160), '{vx_fence')
        cages += box((x1 - 2, y0, 0), (x1, y1 - 2, 160), '{vx_fence')
    E(masked_entity(cages, solid=True))
    D(wall_plate('n', -640, -2896, -2832, 0, 128, 'vx_door_metal', depth=2))       # dummy service door
    D(wall_plate('n', -160, -2770, -2642, 120, 152, SIGNS, row=0))                 # SUBSTATION plate on cage
    D(sign('n', -640, -2800, 160, 1))                                              # HARBOR -> stair lane (W)
    D(sign('w', -1984, 230, 232, 2))                                               # CUSTOMS TOWER -> lantern lane
    D(floor_arrow(-2100, -48, 0, (1, 0)))
    D(floor_arrow(-3072, -560, 0, (0, -1)))
    D(wall_plate('e', -2736, 752, 816, 48, 80, HAZ, depth=2))            # switch house hazard plate
    D(wall_plate('s', 896, -3040, -2912, 150, 166, '~vx_light_c', depth=6))  # cyan panel strip (inside h)
    # gantry rails (masked, part of the cage entity would cross zones; use detail posts + rail texture plates)
    L((-2992, 640, 140), CYAN, 90)                                                  # breaker room cyan panel
    D(emer('e', -3200, 520, 130))
    L((-3180, 520, 130), RED, 60)
    SPR((-2816, -312, 214), CYAN, 0.5, name='cd_arc', fx=2)                        # transformer arc
    L((-2816, -312, 230), CYAN, 140)
    # indicator lamps sit ON the panel / post face (1-2 units out of it), clear of the button travel
    D(P((-2980, 886, 96), (-2972, 888, 104), '~vx_light_r', hide=('n',)))
    SPR((-2976, 885, 100), RED, 0.15, name='cd_brk_a_red')
    SPR((-2976, 885, 100), (60, 255, 80), 0.15, name='cd_brk_a_grn', on=False)
    D(P((-2252, -490, 229), (-2244, -488, 235), '~vx_light_r', hide=('s',)))
    SPR((-2248, -487, 232), RED, 0.15, name='cd_brk_b_red')
    SPR((-2248, -487, 232), (60, 255, 80), 0.15, name='cd_brk_b_grn', on=False)
    D(lamp_post(-2560, 720, arm=(0, -40)))
    D(lamp_post(-2400, -500, arm=(0, 40)))
    SW((-2560, 680, 196), SODIUM, 220, 'cd_lt_west')
    SW((-2400, -460, 196), SODIUM, 220, 'cd_lt_west')
    for p in ((-2650, 300, 300), (-3000, -300, 260), (-2300, 700, 260)):
        L(p, MOON, 120)
    AMB((-2656, 200, 220), 'cd_wind.wav', 7)
    AMB((-2816, -312, 120), 'cd_hum.wav', 7, 'medium', name='cd_hum', silent=True)

    # ------------------------------------------------------------ L lantern lane (the only flicker)
    D(lamp_post(-1552, -64, arm=(0, -40)))
    L((-1552, -104, 196), SODIUM, 160, style=10)
    SPR((-1552, -104, 200), SODIUM, 0.3, amt=150)
    L((-1824, -48, 200), MOON, 60)
    L((-1296, -432, 200), MOON, 60)
    for x, y in ((-1940, 40), (-1676, -548), (-1260, -576)):    # no bin in the plaza mouth (bot snag)
        D(P((x - 0, y, 0), (x + 24, y + 32, 40), RUST))                            # bins
    D(car(-1550, -400, 'y', MDARK))
    D(floor_arrow(-1820, -40, 0, (1, 0)))
    D(floor_arrow(-1300, -430, 0, (1, 0)))
    DEC((-1500, -300, 1), '{blood4')

    # ------------------------------------------------------------ M market street + pharmacy
    D(wall_plate('s', 2240, -1536, -1280, 0, 128, SHOP))                          # shopfronts M1 N wall
    D(wall_plate('n', 1792, -1888, -1632, 0, 128, SHOP))                          # M1 S wall (west of M2)
    D(wall_plate('e', -1600, 1200, 1456, 0, 128, SHOP))                           # M2 W wall
    D(wall_plate('w', -1216, 1300, 1556, 0, 128, SHOP))                           # M2 E wall
    D(car(-1440, 1960, 'x', RUST, burnt=True))                                     # burning car (static fire)
    D(car(-1340, 1200, 'y', MDARK))
    D(jersey('x', -1584, -1424, 1660))
    DEC((-1440, 1960, 1), '{scorch1')
    L((-1440, 1960, 70), FIRE, 160)
    L((-1440, 1960, 20), FIRE, 60)
    for p, arm in (((-1800, 1808), (0, 40)), ((-1240, 2224), (0, -40)), ((-1584, 1400), (40, 0)), ((-1232, 1000), (-40, 0))):
        D(lamp_post(p[0], p[1], arm=arm))
        SW((p[0] + arm[0], p[1] + arm[1], 196), SODIUM, 200, 'cd_lt_west')
    for p in ((-1544, 2016, 300), (-1408, 1400, 300), (-1408, 900, 260)):
        L(p, MOON, 90)
    for x, y in ((-1840, 2210), (-1780, 2180), (-1720, 2150)):
        DEC((x, y, 1), '{blood1')                                                   # drag marks into the pharmacy
    D(floor_arrow(-1760, 2016, 0, (1, 0)))
    D(floor_arrow(-1408, 1840, 0, (0, -1)))
    D(floor_arrow(-1408, 1000, 0, (0, -1)))
    D(floor_arrow(-1280, 848, 0, (1, 0)))
    D(sign('w', -1216, 1024, 200, 2))                                              # CUSTOMS TOWER -> arcade (S)
    AMB((-1544, 2016, 200), 'cd_wind.wav', 6)
    # pharmacy
    D(P((-1888, 2400, 0), (-1600, 2464, 64), MDARK, hide=('bottom', 'n')))        # counter
    for x in (-1880, -1800, -1720):
        D(P((x, 2464, 0), (x + 64, 2480, 128), MIL, hide=('bottom', 'n')))        # shelves
    L((-1744, 2368, 120), COLD, 70)
    DEC((-1700, 2330, 1), '{blood2')

    # ------------------------------------------------------------ R terminus station (T spawn)
    for x in (-896, -512, 512, 896):
        D(P((x - 16, 1840, 0), (x + 16, 1872, 448), MDARK, hide=('bottom', 'top')))  # roof columns
    for y in (1760, 2176):
        D(P((-1088, y - 8, 400), (1088, y + 8, 432), MDARK, hide=('e', 'w')))      # main trusses
    D(P((-1088, 2032, 0), (-896, 2048, 1), HAZ, hide=('bottom',)))
    D(P((-896, 2032, 0), (1088, 2048, 1), HAZ, hide=('bottom',)))                  # platform edge stripe
    for x in (-800, -416, 32):
        D(P((x, 1880, 0), (x + 96, 1904, 18), MDARK))                              # benches
    for x, y in ((-1040, 1440), (-976, 1440), (-1040, 1504)):
        D(crate((x, y, 0), 56, MIL))
    D(car(-640, 1520, 'x', MDARK))                                                  # baggage cart
    for x, face, line in ((-1088, 'e', -1088), (1088, 'w', 1088)):
        for y in (1600, 2240):
            D(emer(face, line, y, 300))
            L((x + (24 if face == 'e' else -24), y, 300), RED, 60)
    for p in ((-600, 1650, 200), (600, 1650, 200), (0, 2250, 260), (-600, 2250, 200), (600, 2200, 200)):
        L(p, COLD, 90)
    for p in ((-560, 1650, 300), (560, 1650, 300), (-300, 2250, 300), (500, 2250, 300)):
        e = SW(p, RED, 260, 'cd_lt_alarm')
        e['pattern'] = 'aaaazzzz'
    for x, face in ((-1088, 'e'), (1088, 'w')):                                   # alarm beacons on the side walls
        D(emer(face, x, 1984, 372))
        SPR((x + (10 if face == 'e' else -10), 1984, 380), RED, 0.4, name='cd_alarm_spr', on=False, fx=4)
    for x, y in ((1040, 2300), (980, 2200), (880, 2100), (760, 1980), (640, 1880), (520, 1820)):
        DEC((x, y, 1), '{blood1' if x > 800 else '{blood2')                        # trail from the breach
    DEC((1060, 2160, 1), '{scorch1')
    D(floor_arrow(672, 1440, 0, (0, -1)))
    D(floor_arrow(-672, 1440, 0, (0, -1)))
    D(sign('n', 1408, -400, 220, 2))                                               # CUSTOMS TOWER -> forecourts
    D(sign('n', 1408, 900, 220, 2))
    AMB((0, 1950, 300), 'cd_wind.wav', 5, pitch=80)
    AMB((0, 1700, 300), 'cd_siren.wav', 4, name='cd_siren_st', silent=True)
    AMB((1000, 2200, 100), 'cd_boom.wav', 10, name='cd_boom_st', silent=True, loop=False)
    # forecourts
    for xm in (-576, 576):
        D(jersey('y', 1080, 1150, xm - 150))
        L((xm, 1300, 200), MOON, 60)
        SW((xm, 1100, 200), SODIUM, 120, 'cd_lt_west' if xm < 0 else 'cd_lt_east')
        DEC((xm + 40, 1300, 1), '{blood5')

    # ------------------------------------------------------------ H field hospital + w ward
    D(tent(1200, 1500, 1456, 1660, 112))
    D(tent(1200, 1760, 1456, 1920, 112))
    D(tent(1600, 1420, 1760, 1676, 112, axis='y'))
    D(P((2040, 1440, 0), (2232, 1520, 64), MDARK))                                 # army truck chassis
    D(P((2232, 1440, 0), (2296, 1520, 80), MDARK))                                 # cab
    D(P((2040, 1440, 64), (2232, 1520, 128), TARP, hide=()))                       # cargo cover
    for x, y in ((1560, 2100), (1700, 2200), (1500, 2300)):
        D(P((x, y, 0), (x + 72, y + 32, 20), MDARK))                               # stretchers / beds
        DEC((x + 30, y + 40, 1), '{blood2')
    D(wall_plate('w', 1840, 2200, 2264, 100, 164, TARP, depth=2))                  # red-cross banner on the ward
    SPR((1846, 2232, 216), RED, 0.4)                                               # hospital red cross lamp
    L((1820, 2232, 200), RED, 120)
    for p in ((1800, 1700, 300), (1350, 2100, 260), (2300, 1800, 260)):
        L(p, MOON, 100)
    L((1328, 1580, 80), (255, 190, 120), 80)                                         # lantern inside the tent
    SW((2400, 1600, 200), SODIUM, 160, 'cd_lt_east')
    for x in (1900, 2080, 2260, 2440):                                              # ward beds
        D(P((x, 2400, 0), (x + 40, 2472, 24), MDARK, hide=('bottom', 'n')))
    W(box((2136, 2160, 168), (2264, 2224, 176), {'bottom': '~vx_light_w', 'top': NULL, 'all': MDARK}))
    L((2200, 2192, 150), (230, 240, 255), 110)
    DEC((2000, 2100, 1), '{bigblood1')
    D(sign('w', 2560, 1600, 160, 1))                                               # HARBOR -> checkpoint B arch (south)
    D(floor_arrow(2368, 1420, 0, (0, -1)))
    AMB((1800, 1900, 200), 'cd_wind.wav', 6)

    # ------------------------------------------------------------ P Liberation Plaza (boss arena)
    D(prism((0, -64), 28, 8, 96, 304, CONC))                                      # memorial column
    D(P((-48, -112, 304), (48, -16, 336), CONC, hide=()))
    D(P((-704, -656, 0), (-384, -560, 112), RUST))                                 # burnt-out bus
    DEC((-544, -608, 1), '{scorch2')
    D(car(520, 420, 'x', RUST, burnt=True))                                        # burning car (fire sprite)
    D(car(-640, 360, 'y', MDARK))
    D(car(760, -820, 'x', MDARK))
    DEC((520, 420, 1), '{scorch1')
    SPR((520, 420, 80), (255, 255, 255), 1.5, model='sprites/vexmira/fire.spr', amt=255, fr=10)
    L((520, 420, 90), FIRE, 260)
    L((520, 420, 30), FIRE, 90)
    for a0, a1, c in ((-560, -400, 900), (400, 560, 900)):
        D(jersey('x', a0, a1, c))                                                  # forecourt mouth cover
    D(jersey('y', 40, 240, 960))
    D(jersey('y', -340, -140, 960))
    D(wall_plate('s', 1024, -320, -64, 0, 128, SHOP))
    D(wall_plate('s', 1024, 64, 320, 0, 128, SHOP))
    D(wall_plate('w', 1152, 512, 768, 1000, 1064, '~vx_neon_vex', depth=4))       # crown neon (landmark)
    SPR((1300, 640, 1168), RED, 0.5, fx=4)                                         # aircraft warning light
    L((1100, 640, 1030), (200, 110, 255), 160)
    D(sign('w', 1152, 380, 150, 2))                                                # CUSTOMS TOWER at the lobby doors
    D(sign('n', -1152, 400, 240, 1))                                               # HARBOR -> steps arch
    for x, y, d in ((-480, 820, (1, 0)), (480, 820, (1, 0)), (-900, 848, (1, 0)), (-900, -432, (1, 0)),
                    (800, 224, (1, 0))):
        D(floor_arrow(x, y, 0, d))
    for p in ((-700, 600), (700, 600), (-700, -800), (700, -800), (0, 700), (0, -1000)):
        D(lamp_post(p[0], p[1], h=320))
        SW((p[0], p[1], 300), WHITE, 300, 'cd_lt_plaza')
        SW((p[0] + 20, p[1], 290), RED, 260, 'cd_lt_plazared')
    for p in ((-600, 0, 420), (600, 0, 420), (0, 600, 420), (0, -700, 420)):
        L(p, MOON, 130)
    DEC((-200, 200, 1), '{bigblood2')
    DEC((300, -300, 1), '{blood6')
    AMB((0, 0, 300), 'cd_wind.wav', 7)
    AMB((0, 0, 400), 'cd_siren.wav', 4, name='cd_siren_pz', silent=True)
    AMB((0, 200, 300), 'cd_boom.wav', 10, name='cd_boom_pz', silent=True, loop=False)

    # ------------------------------------------------------------ T Customs Tower
    D(P((1600, 400, 0), (1824, 448, 44), MDARK))                                   # lobby reception desk
    D(P((1600, 448, 0), (1640, 560, 44), MDARK))
    for x in (1300, 1500, 1700, 1900):                                             # office desks T1
        for y in (-200, 300):
            D(P((x, y, 192), (x + 96, y + 48, 222), MDARK))
    for x in (1300, 1600, 1900):                                                   # plant T2 machinery + ducts
        D(P((x, 300, 384), (x + 128, 400, 480), MDARK))
    D(P((1168, 40, 528), (2160, 88, 560), CORR, hide=('e', 'w', 'top')))            # duct run
    for key, rc in (('nw', (1184, 464, 1440, 816)), ('se', (1888, -368, 2144, -16))):
        for z in (100, 292, 484):
            D(emer('s' if key == 'nw' else 'n', rc[3] if key == 'nw' else rc[1], rc[0] + 64, z))
        L(((rc[0] + rc[2]) / 2, (rc[1] + rc[3]) / 2, 300), RED, 120)
        L(((rc[0] + rc[2]) / 2, (rc[1] + rc[3]) / 2, 600), RED, 80)
    for z in (150, 340, 530):
        for x, y in ((1450, 100), (1880, 400), (1700, -250)):
            SW((x, y, z), (230, 240, 255), 160, 'cd_lt_east')
        L((1664, 224, z - 40), COLD, 60)
    # roof deck: pad ring + lamps + AC units
    for mn, mx in (((1504, 64, 576), (1824, 80, 577)), ((1504, 368, 576), (1824, 384, 577)),
                   ((1504, 80, 576), (1520, 368, 577)), ((1808, 80, 576), (1824, 368, 577))):
        D(P(mn, mx, HAZ))
    for x, y in ((1504, 64), (1824, 64), (1504, 384), (1824, 384)):
        D(P((x - 6, y - 6, 576), (x + 6, y + 6, 592), MDARK))
        SW((x, y, 610), (120, 255, 140), 120, 'cd_lt_pad')
    D(P((1900, 600, 576), (2050, 720, 640), CORR))                                 # AC units
    D(P((1250, -300, 576), (1400, -200, 624), CORR))
    SPR((1504, 64, 595), (60, 255, 80), 0.3, name='cd_pad_grn', on=False, fx=4)    # on the pad corner posts
    SPR((1824, 384, 595), (60, 255, 80), 0.3, name='cd_pad_grn', on=False, fx=4)
    D(P((1660, -80, 606), (1668, -78, 614), '~vx_light_r', hide=('s',)))          # lamp on the beacon console front
    SPR((1664, -77, 610), RED, 0.25, name='cd_pad_red')
    L((1664, 224, 800), MOON, 140)
    AMB((1664, 224, 700), 'cd_rotor.wav', 10, name='cd_rotor', silent=True)
    AMB((1664, 224, 450), 'cd_hum.wav', 5, 'medium', name='cd_hum', silent=True)
    # south passage t
    L((1664, -480, 200), MOON, 70)
    SW((1400, -480, 200), SODIUM, 120, 'cd_lt_east')
    D(floor_arrow(1300, -480, 0, (1, 0)))
    D(floor_arrow(1984, -448, 0, (0, 1)))

    # ------------------------------------------------------------ K Kade harbor road
    for x, y in ((2496, 1200), (2496, 1140), (2440, 1200)):
        D(crate((x, y, 0), 56, MIL))
    D(car(2260, 300, 'y', MDARK))
    D(jersey('x', 2200, 2400, -150))
    for y in (1000, 160, -600):
        D(lamp_post(2500, y))
        SW((2500, y, 196), SODIUM, 220, 'cd_lt_east')
        L((2368, y, 300), MOON, 90)
    D(sign('w', 2560, 900, 160, 1))                                                # HARBOR (south)
    D(sign('e', 2176, -200, 160, 3))                                              # EVAC -> balcony / roof? (north)
    D(floor_arrow(2368, -700, 0, (0, 1)))
    AMB((2368, 100, 200), 'cd_harbor.wav', 6)

    # ------------------------------------------------------------ n stair lane + F fish market
    L((-3072, -864, 150), MOON, 80)
    D(floor_arrow(-3136, -720, 0, (0, -1)))
    for i, x in enumerate((-3200, -2944, -2688, -2432, -2176)):                     # fish stalls
        D(P((x, -1900, -128), (x + 128, -1840, -88), RUST))
        if i % 2 == 0:
            DEC((x + 60, -1820, -127), '{blood3')
    for x in (-3200, -2600, -2000):
        D(P((x, -2290, -128), (x + 96, -2240, -80), MIL, hide=('bottom', 's')))   # ice boxes
    for x in (-3000, -2400):
        D(emer('n', -2304, x, 60))
        L((x, -2280, 60), RED, 120)
    for p in ((-2850, -1700, 160), (-2250, -1700, 160)):
        L(p, MOON, 110)
    SW((-2560, -1500, 200), SODIUM, 160, 'cd_lt_harbor')
    D(wall_plate('w', -1792, -1980, -1924, 0, 56, ARROW, arrow=(0, -1, 0)))       # -> net alley shutter
    AMB((-2560, -1700, 100), 'cd_harbor.wav', 5, pitch=85)

    # ------------------------------------------------------------ e harbor steps
    D(wall_plate('n', -1232, -96, 96, 96, 160, 'vx_sign_vex', depth=4))            # memorial plaque
    L((0, -1376, 220), MOON, 90)
    SW((-300, -1400, 200), SODIUM, 120, 'cd_lt_harbor')
    SW((300, -1400, 200), SODIUM, 120, 'cd_lt_harbor')
    DEC((-200, -1300, 1), '{blood4')

    # ------------------------------------------------------------ Q quay + cabin + canal
    for x in range(-1700, 1100, 512):
        D(P((x, -2552, -128), (x + 20, -2532, -104), MDARK))                       # bollards
    for x, y in ((-1700, -1660), (-1640, -1660), (-1700, -1720)):
        D(crate((x, y, -128), 56, MIL))
    D(car(-900, -2100, 'x', MDARK, z=-128))
    D(P((200, -2300, -128), (328, -2236, -96), TARP))                              # net pile
    for x in (-1200, -200, 700):
        D(lamp_post(x, -2500, z=-128))
        SW((x, -2480, 70), SODIUM, 220, 'cd_lt_harbor')
    for p in ((-300, -2080, 120), (-1300, -2000, 120), (700, -2000, 120)):
        L(p, MOON, 110)
    D(floor_arrow(600, -1712, -128, (1, 0)))
    D(floor_arrow(-1650, -2100, -128, (1, 0)))
    D(floor_arrow(0, -1700, -128, (1, 0)))
    D(P((1100, -1744, 24), (1108, -1742, 32), '~vx_light_r', hide=('s',)))       # lamp on the console front
    SPR((1104, -1741, 28), RED, 0.15, name='cd_cab_red')
    SPR((1104, -1741, 28), (60, 255, 80), 0.15, name='cd_cab_grn', on=False)
    L((1032, -1696, 90), (255, 200, 150), 70)
    for y in (-1840, -2256):
        D(P((1136, y - 16, -128), (1168, y + 16, 384), RUST))                       # bridge towers
        D(P((1144, y - 8, 384), (1160, y + 8, 392), LRED, hide=()))      # warning lamp cap
        SPR((1152, y, 392), (255, 200, 40), 0.5, name='cd_bridge_spr', on=False, fx=4)
    SW((1248, -2048, 200), SODIUM, 160, 'cd_lt_harbor')
    AMB((0, -2100, 0), 'cd_harbor.wav', 7)
    AMB((-800, -2100, 0), 'cd_wind.wav', 4)

    # ------------------------------------------------------------ C container terminal + crane
    for y in (-2096, -1904):
        D(P((2400, y - 8, 448), (2912, y + 8, 480), RUST, hide=()))               # crane boom girders
    D(P((2528, -2096, 256), (2560, -2064, 448), RUST, hide=('bottom', 'top')))
    D(P((2752, -1936, 256), (2784, -1904, 448), RUST, hide=('bottom', 'top')))
    D(P((2704, -2096, 256), (2784, -2016, 320), CORR, hide=('bottom',)))          # crane cab (deck corner)
    for x in (1500, 2500, 3100):
        D(lamp_post(x, -1110, z=-128, h=320, arm=(0, -40)))
        SW((x, -1150, 180), SODIUM, 260, 'cd_lt_harbor')
    for p in ((2336, -1824, 200), (2900, -2300, 200), (1800, -2450, 200), (3100, -1700, 200)):
        L(p, MOON, 120)
    D(floor_arrow(2368, -1300, -128, (0, 1)))
    D(sign('s', -1088, 2000, 40, 2))                                               # CUSTOMS TOWER -> ramp up (W)
    AMB((2600, -1900, 100), 'cd_harbor.wav', 7)

    # ------------------------------------------------------------ B bay vista: freighter fire, lighthouse
    SPR((1500, -2800, 180), (255, 255, 255), 2.5, model='sprites/vexmira/fire.spr', amt=255, fr=10)
    L((1500, -2760, 200), FIRE, 500)
    D(P((-640, -3240, 448), (-560, -3160, 480), MDARK, hide=()))
    SPR((-600, -3200, 470), (255, 230, 170), 1.0, fx=0)
    L((-600, -3150, 470), (255, 230, 170), 300)
    L((0, -2900, 200), MOON, 120)

    # ------------------------------------------------------------ v vista: artillery glow + shell flashes
    SPR((-2650, 3100, 120), (255, 255, 255), 2.0, model='sprites/vexmira/fire.spr', amt=255, fr=8)
    L((-2650, 3050, 160), FIRE, 260)
    for x in (-3100, -2650, -2200):
        SW((x, 2900, 400), (255, 200, 140), 500, 'cd_lt_flash')
    for x in (-2900, -2400):
        SW((x, 2700, 200), WHITE, 260, 'cd_lt_flood_out')
    AMB((-2650, 2400, 300), 'cd_boom.wav', 5, 'everywhere', name='cd_boom_far', silent=True, loop=False)
    AMB((-2650, 1984, 300), 'cd_siren.wav', 3, 'everywhere', name='cd_siren_all', silent=True)

    # ------------------------------------------------------------ hidden hangar (lit for the helicopter body)
    L((3760, 3008, 330), MOON, 220)
    L((3760, 3008, 30), MOON, 120)

    # moon
    ents.append(light_environment(-58, 135, (150, 165, 215), 70, diffuse=(55, 65, 100, 35), origin=(0, 0, 800)))


# ==============================================================================================
# STAGE 3: interactive set pieces + story wiring (spec section 9, devtools/MAP_CONTRACT.md)
# ----------------------------------------------------------------------------------------------
def wire(b):
    D, E, ents = b.D, b.ent, b.ents
    ORG = 'ORIGIN'
    made = set()

    def pt(cls, name=None, **kw):
        e = Entity(cls, **kw)
        if name:
            e['targetname'] = name
        ents.append(e)
        return e

    def mm(name, seq, origin=(0, 0, 64)):
        """multi_manager: seq = [(target, delay)], duplicate targets get #2, #3 (max 16 per entity)."""
        assert len(seq) <= 16, name
        e = pt('multi_manager', name, origin=origin)
        seen = {}
        for tgt, dl in seq:
            seen[tgt] = seen.get(tgt, 0) + 1
            e[tgt if seen[tgt] == 1 else f'{tgt}#{seen[tgt]}'] = dl
        return e

    def rel(tgt, on):
        """State-explicit trigger_relay (triggerstate 1 = on, 0 = off): re-firing is harmless."""
        base = tgt[6:] if tgt.startswith('cd_lt_') else tgt[3:]
        name = f"cd_r_{base}_{'on' if on else 'off'}"
        if name not in made:
            made.add(name)
            pt('trigger_relay', name, target=tgt, triggerstate=1 if on else 0, origin=(0, 0, 80))
        return name

    def cmd(name):
        """Map -> plugin relay (vexcmd_*, class trigger_relay, no target)."""
        if name not in made:
            made.add(name)
            pt('trigger_relay', name, triggerstate=2, origin=(0, 0, 96))
        return name

    def button(mn, mx, name, target, master=None, lip=4, speed=40):
        e = E(Entity('func_button', box(mn, mx, HAZ), targetname=name, target=target, wait=-1, sounds=11,
                     speed=speed, lip=lip, angles=(0, -2, 0), _minlight=0.3))
        if master:
            e['master'], e['locked_sound'] = master, 14
        return e

    def rotdoor(brushes, hinge, name, dist, flags, speed):
        o = box((hinge[0] - 4, hinge[1] - 4, hinge[2] - 4), (hinge[0] + 4, hinge[1] + 4, hinge[2] + 4), ORG)
        return E(Entity('func_door_rotating', brushes + o, targetname=name, distance=dist, speed=speed, wait=-1,
                        dmg=0, lip=0, movesnd=0, stopsnd=0, spawnflags=flags, _minlight=0.2))

    def shake(name, p, amp, dur, rad, freq=40, glob=False):
        pt('env_shake', name, origin=p, amplitude=amp, duration=dur, radius=rad, frequency=freq,
           spawnflags=1 if glob else 0)

    def boomfx(name, p, mag):
        pt('env_explosion', name, origin=p, iMagnitude=mag, spawnflags=3)   # no damage, repeatable

    GRP = ('cd_lt_west', 'cd_lt_plaza', 'cd_lt_plazared', 'cd_lt_east', 'cd_lt_harbor', 'cd_lt_pad',
           'cd_lt_alarm', 'cd_lt_flash', 'cd_lt_flood_out')
    LOOPS = ('cd_hum', 'cd_siren_st', 'cd_siren_pz', 'cd_siren_all', 'cd_rotor')
    SPR_ON = ('cd_brk_a_red', 'cd_brk_b_red', 'cd_cab_red', 'cd_pad_red')
    SPR_OFF = ('cd_brk_a_grn', 'cd_brk_b_grn', 'cd_cab_grn', 'cd_pad_grn', 'cd_bridge_spr', 'cd_alarm_spr')

    # ------------------------------------------------------------ SP1 power: two breakers (Substation)
    D(P((-2996, 888, 40), (-2956, 896, 112), MDARK))                                   # breaker panel A
    button((-2988, 880, 52), (-2964, 888, 84), 'cd_brk_a', 'cd_brk_a_mm', lip=8)
    D(P((-2268, -506, 160), (-2228, -490, 236), MDARK))                                # breaker post B (gantry)
    button((-2260, -490, 196), (-2236, -482, 228), 'cd_brk_b', 'cd_brk_b_mm', lip=8)
    for k in 'ab':
        mm(f'cd_brk_{k}_mm', [('cd_ms_power', 0), (rel(f'cd_brk_{k}_red', 0), 0), (rel(f'cd_brk_{k}_grn', 1), 0)])
    pt('multisource', 'cd_ms_power', target='cd_power_mm', origin=(-2600, 400, 96))
    mm('cd_power_mm', [(rel('cd_hum', 1), 0), (rel('cd_lt_west', 1), 0.6), (rel('cd_lt_plaza', 1), 1.4),
                       (rel('cd_lt_east', 1), 2.2), (rel('cd_cab_red', 0), 2.2), (rel('cd_cab_grn', 1), 2.2),
                       (cmd('vexcmd_obj_1_done'), 2.5), (cmd('vexcmd_reward_h_5'), 2.5),
                       (cmd('vexcmd_msg_power'), 2.5)])

    # ------------------------------------------------------------ SP2 lift bridge (Quay cabin)
    D(P((1040, -1776, 0), (1128, -1744, 40), MDARK))                                   # cabin console
    button((1096, -1768, 40), (1112, -1752, 48), 'cd_bridge_btn', 'cd_bridge_mm', master='cd_ms_power')
    mm('cd_bridge_mm', [(rel('cd_bridge_spr', 1), 0), ('cd_bridge', 0.5), (rel('cd_bridge_spr', 0), 9),
                        (rel('cd_lt_harbor', 1), 8.5), ('cd_ms_bridge', 8.5), (cmd('vexcmd_obj_2_done'), 8.5),
                        (cmd('vexcmd_reward_h_8'), 8.5), (cmd('vexcmd_msg_bridge'), 8.5)])
    pt('multisource', 'cd_ms_bridge', origin=(1104, -1712, 96))

    # ------------------------------------------------------------ SP3 evac beacon + medevac helicopter ride
    # The beacon calls a medevac that LANDS on the roof pad (deck 16 above the roof: step on), waits 15 s
    # (path_corner wait) and then flies a slow sightseeing loop until the round ends: out through the
    # air window in the plaza facade, a low oval over Liberation Plaza (deck z ~265), back up through the
    # window and a lap over the tower roof. The open deck carries standing players (func_train pushes
    # riders); 40-high rails with boarding gaps. Zombie launch geysers sit 70-150 units beside the route.
    # Not passable (riders stand on it), dmg ~0 (blocked = it just waits, never reverses).
    D(P((1648, -112, 576), (1680, -80, 624), MDARK))                                   # beacon console
    button((1656, -104, 624), (1672, -88, 632), 'cd_beacon_btn', 'cd_beacon_mm', master='cd_ms_bridge')
    mm('cd_beacon_mm', [(rel('cd_lt_pad', 1), 0), (rel('cd_pad_red', 0), 0), (rel('cd_pad_grn', 1), 0),
                        (cmd('vexcmd_obj_3_done'), 0.5), (cmd('vexcmd_msg_beacon'), 0.5), (rel('cd_rotor', 1), 10),
                        ('cd_heli', 12)])
    parts = [((-128, -96, -8), (128, 96, 0), {'top': 'vx_metal_floor', 'all': MDARK}),        # open deck
             ((-112, -80, -15), (112, -72, -8), MDARK), ((-112, 72, -15), (112, 80, -8), MDARK),  # skids
             ((-176, -64, 0), (-128, 64, 40), MDARK),                                         # cockpit lower
             ((-176, -64, 40), (-136, 64, 96), 'vx_glass'),                                   # windscreen
             ((-208, -48, 0), (-176, 48, 56), MDARK),                                         # nose
             ((-176, -64, 96), (-128, 64, 104), HAZ),                                         # cabin roof
             ((124, -96, 0), (128, 96, 40), HAZ),                                             # rear rail
             ((-128, -96, 0), (-64, -92, 40), HAZ), ((64, -96, 0), (124, -92, 40), HAZ),       # side rails
             ((-128, 92, 0), (-64, 96, 40), HAZ), ((64, 92, 0), (124, 96, 40), HAZ),           # (gaps = doors)
             ((-158, -6, 104), (-146, 6, 164), MDARK),                                        # rotor mast
             ((-302, -8, 164), (-2, 8, 168), MDARK), ((-160, -150, 164), (-144, 150, 168), MDARK),  # blades
             ((128, -8, 24), (304, 8, 44), MDARK),                                            # tail boom
             ((288, -4, 44), (304, 4, 104), HAZ), ((296, 4, 56), (300, 40, 96), MDARK)]        # fin + tail rotor
    HG = np.array([3744, 3008, 100])                       # built in the sealed hangar (lit), deck top z 100
    lmn = np.min([p[0] for p in parts], axis=0)
    lmx = np.max([p[1] for p in parts], axis=0)
    cen = (lmn + lmx) / 2.0                                 # func_train puts its bbox centre on the path_corner
    body = []
    for mn, mx, tx in parts:
        body += box(tuple(HG + mn), tuple(HG + mx), tx)
    E(Entity('func_train', body, targetname='cd_heli', target='cd_hp0', speed=200, dmg=0.001, _minlight=0.3))
    # (deck centre x, y, deck top z, flags, speed for the next leg, wait, message)
    route = [((3744, 3008, 100), 0, 0, 0, None),                                       # hp0 hangar (hidden)
             ((2000, 600, 1200), 2, 200, 0, None),                                     # hp1 appears high NE
             ((1664, 224, 760), 0, 70, 0, None),                                       # hp2 over the pad
             ((1664, 224, 592), 0, 50, 15, 'cd_heli_land_mm'),                        # hp3 landed: board!
             ((1664, 224, 720), 0, 120, 0, 'cd_heli_up_mm'),                          # hp4 lift-off
             # ---- loop hp5..hp14 (hp14 -> hp5) ----
             ((850, 200, 720), 0, 110, 0, None),                                       # hp5 through the air window
             ((650, 400, 270), 0, 120, 0, None),                                       # hp6 down into the plaza
             ((-760, 400, 260), 0, 120, 0, None),                                      # hp7 north lane (geyser G1)
             ((-760, -420, 260), 0, 120, 0, None),                                     # hp8 west lane (G2)
             ((650, -440, 270), 0, 110, 0, None),                                      # hp9 south lane (G3)
             ((850, 0, 720), 0, 120, 0, None),                                         # hp10 climb to the window
             ((1400, 0, 720), 0, 110, 0, None),                                        # hp11 over the roof
             ((1820, -180, 800), 0, 110, 0, None),                                     # hp12 roof SE
             ((1820, 520, 800), 0, 110, 0, None),                                      # hp13 roof NE (geyser G4)
             ((1400, 200, 720), 0, 110, 0, None)]                                      # hp14 -> hp5
    n = len(route)
    for i, (p, fl, spd, wt, msg) in enumerate(route):
        nxt = i + 1 if i + 1 < n else 5
        e = pt('path_corner', f'cd_hp{i}', origin=tuple(np.array(p) + cen), target=f'cd_hp{nxt}', spawnflags=fl)
        if spd:
            e['speed'] = spd
        if wt:
            e['wait'] = wt
        if msg:
            e['message'] = msg
    mm('cd_heli_land_mm', [(cmd('vexcmd_reward_h_15'), 0), (cmd('vexcmd_msg_heli'), 0), ('cd_shake_roof', 0)])
    mm('cd_heli_up_mm', [(cmd('vexcmd_msg_heli_go'), 0), ('cd_shake_roof', 0)])
    shake('cd_shake_roof', (1664, 224, 640), 4, 2, 600, freq=60)

    # ------------------------------------------------------------ SP4 train breach (vex_infection)
    td = box((800, 2104, 0), (864, 2112, 96), RUST) + box((812, 2102, 48), (852, 2104, 80), 'vx_glass')
    rotdoor(td, (864, 2108, 48), 'cd_train_door', 100, 0, 600)
    boomfx('cd_breach_fx', (832, 2090, 48), 60)
    shake('cd_shake_st', (500, 2000, 64), 10, 1.5, 1600)
    mm('vex_infection', [('cd_train_door', 0), ('cd_breach_fx', 0), ('cd_shake_st', 0), ('cd_boom_st', 0),
                         (rel('cd_lt_alarm', 1), 0.3), (rel('cd_alarm_spr', 1), 0.3), (rel('cd_siren_st', 1), 1), (rel('cd_siren_st', 0), 9),
                         (cmd('vexcmd_msg_breach'), 1.5)])
    rel('cd_siren_st', 0)                                                              # ini: infection 30

    # ------------------------------------------------------------ SP5 boss arrival (Plaza billboard)
    for x in (-840, -440):
        D(P((x - 8, -876, 0), (x + 8, -860, 176), MDARK))                              # billboard legs
    bb = box((-880, -872, 176), (-400, -864, 416), SIGNS) + box((-880, -876, 168), (-400, -860, 176), MDARK)
    rotdoor(bb, (-640, -868, 172), 'cd_billboard', 85, 64, 140)                        # roll: falls south
    boomfx('cd_billboard_fx', (-640, -900, 200), 50)
    shake('cd_shake_pz', (0, 0, 64), 8, 2, 2000)
    mm('vex_boss', [(rel('cd_lt_plaza', 0), 0), (rel('cd_lt_plazared', 1), 0), (rel('cd_siren_pz', 1), 0), (rel('cd_siren_pz', 0), 8),
                    ('cd_shake_pz', 0), ('cd_boom_pz', 0), (cmd('vexcmd_msg_boss'), 1)])
    mm('cd_billboard_mm', [('cd_billboard', 0), ('cd_boom_pz', 0.7), ('cd_shake_pz', 0.7), ('cd_billboard_fx', 0.7)])
    pt('game_counter', 'cd_plaza_gate', target=rel('cd_lt_plaza', 1), master='cd_ms_power', frags=0, health=1,
       spawnflags=2, origin=(0, 0, 120))
    mm('vex_boss_dead', [(rel('cd_lt_plazared', 0), 0), (rel('cd_siren_pz', 0), 0), ('cd_plaza_gate', 0.5)])

    # ------------------------------------------------------------ SP6 shelling (every minute, two impacts)
    shake('cd_shake_far', (0, 0, 64), 3, 1.2, 9000, glob=True)
    mm('vex_minute', [('cd_boom_far', 0), (rel('cd_lt_flash', 1), 0.35), ('cd_shake_far', 0.4),
                      (rel('cd_lt_flash', 0), 0.7), ('cd_boom_far', 6), (rel('cd_lt_flash', 1), 6),
                      ('cd_shake_far', 6.1), (rel('cd_lt_flash', 0), 6.3)])

    # ------------------------------------------------------------ SP7 riot barricade (zombie goal)
    mm('cd_barricade_mm', [(cmd('vexcmd_reward_z_5'), 0), (cmd('vexcmd_msg_barricade'), 0)])

    # ------------------------------------------------------------ SP8 Gate 7 (barrier arm + win)
    D(P((-2504, 2432, 0), (-2488, 2456, 40), MDARK))                                   # barrier post
    arm = box((-2832, 2440, 40), (-2504, 2448, 48), HAZ) + box((-2504, 2438, 36), (-2472, 2450, 52), MDARK)
    rotdoor(arm, (-2496, 2444, 44), 'cd_barrier_up', 80, 128, 60)                      # pitch: arm swings up
    mm('vex_win_humans', [('cd_gate7', 0), (rel('cd_lt_flood_out', 1), 0)])

    # ------------------------------------------------------------ SP9 blackout / last human / zombie win
    mm('cd_blackout_mm', [(rel('cd_hum', 0), 0), (rel('cd_lt_west', 0), 0), (rel('cd_lt_plaza', 0), 0.3),
                          (rel('cd_lt_east', 0), 0.6), (rel('cd_lt_harbor', 0), 0.9), ('cd_boom_far', 0),
                          (cmd('vexcmd_msg_blackout'), 1)])
    for nm in ('vex_nemesis', 'vex_assassin'):
        pt('trigger_relay', nm, target='cd_blackout_mm', triggerstate=2, origin=(0, 0, 112))
    mm('vex_lasthuman', [('cd_blackout_mm', 0), (rel('cd_siren_all', 1), 1), (rel('cd_siren_all', 0), 8),
                         (rel('cd_lt_plazared', 1), 1)])
    mm('vex_win_zombies', [('cd_blackout_mm', 0), (rel('cd_lt_alarm', 1), 0), (rel('cd_lt_plazared', 1), 0),
                           (rel('cd_siren_all', 1), 0), (rel('cd_siren_all', 0), 6)])

    # ------------------------------------------------------------ lighthouse beam (always turning)
    beam = box((-850, -3204, 464), (-650, -3196, 476), '~vx_light_w') + \
        box((-550, -3204, 464), (-350, -3196, 476), '~vx_light_w') + \
        box((-604, -3204, 466), (-596, -3196, 474), ORG)
    E(Entity('func_rotating', beam, speed=30, spawnflags=1, rendermode=5, renderamt=50, _minlight=1))

    # ------------------------------------------------------------ sky effects (vexmira_night sky, always on)
    # Military searchlights in the no-man's land vista: vertical additive beams swinging east-west
    # (func_pendulum, pitch axis 128 + start on 1 + passable 8), seen over the quarantine wall from Gate 7.
    # They never stop, so the round reset needs nothing.
    for x, spd, dist in ((-2900, 14, 22), (-2350, 11, 24)):
        sb = box((x - 10, 2890, 140), (x + 10, 2910, 980), {'top': NULL, 'bottom': NULL, 'all': '~vx_light_w'}) + \
            box((x - 4, 2896, 116), (x + 4, 2904, 124), ORG)
        E(Entity('func_pendulum', sb, speed=spd, distance=dist, damp=0, spawnflags=1 + 8 + 128,
                 rendermode=5, renderamt=55, rendercolor='200 215 255', _minlight=1))
    # Distant lightning: env_beam random strikes (start on 1 + random 4) between random start/end
    # info_targets of the same name, every 0..StrikeTime s, in the north vista and over the bay.
    for tag, starts, ends, col in (
            ('v', ((-3150, 3120, 1100), (-2250, 3150, 1090), (-2700, 3100, 1110)),
             ((-2950, 3170, 380), (-2550, 3180, 440), (-2100, 3150, 320)), '200 170 255'),
            ('b', ((-1800, -3350, 1100), (300, -3300, 1110), (2600, -3350, 1090)),
             ((-1200, -3420, -150), (900, -3420, -150), (2200, -3400, -150)), '170 200 255')):
        for p in starts:
            pt('info_target', f'cd_bolt_{tag}0', origin=p)
        for p in ends:
            pt('info_target', f'cd_bolt_{tag}1', origin=p)
        pt('env_beam', LightningStart=f'cd_bolt_{tag}0', LightningEnd=f'cd_bolt_{tag}1', spawnflags=1 + 4,
           life=0.3, StrikeTime=9, NoiseAmplitude=120, BoltWidth=28, texture='sprites/laserbeam.spr',
           rendercolor=col, renderamt=230, TextureScroll=35, damage=0, Radius=256,
           origin=starts[0])

    # ------------------------------------------------------------ round reset (vex_round_start, idempotent)
    reset = [(rel(g, 0), 0) for g in GRP] + [(rel(s, 0), 0) for s in LOOPS]
    reset += [(rel(s, 1), 0) for s in SPR_ON] + [(rel(s, 0), 0) for s in SPR_OFF]
    for i in range(0, len(reset), 16):
        mm('vex_round_start', reset[i:i + 16], origin=(0, 0, 128 + i))


# ==============================================================================================
# STAGE 4 (owner feedback): launch pads + geysers, objective guidance, collapses, moving things
# ----------------------------------------------------------------------------------------------
OBJ = '~vx_objsign'


G_UP = 3200      # one vertical push field for every geyser / trampoline: apex above the pad = H * G_UP / 800


def launch(H, apex, vh, d):
    """trigger_push for a directional launch pad. GoldSrc applies a push field's vertical component as an
    ACCELERATION (pm_shared PM_AddCorrectGravity adds basevelocity.z * frametime, then clears it) and the
    horizontal part as a conveyor speed (+ momentum when leaving). A field H high accelerating at a (net of
    gravity 800) releases the player at v = sqrt(2 a H), apex = H + v^2 / 1600, after t = sqrt(2 H / a),
    while it carries him vh * t forward: returns (speed, angles, field length along d)."""
    v = math.sqrt(1600.0 * (apex - H))
    a = v * v / (2.0 * H)
    t = math.sqrt(2.0 * H / a)
    sz = a + 800.0
    sp = math.hypot(vh, sz)
    pitch = -math.degrees(math.atan2(sz, vh))
    yaw = math.degrees(math.atan2(d[1], d[0]))
    return round(sp), f'{pitch:.1f} {yaw:.1f} 0', vh * t


def lane(x, y, z, d, H, L, w=56):
    """Push field box starting on the pad (x, y) and running L (+w) along d, H high."""
    L = int(math.ceil(L / 16.0) * 16)
    x1, y1 = x + d[0] * (L + w), y + d[1] * (L + w)
    return ((min(x - w, x1 - w * abs(d[1])) if d[0] == 0 else min(x - w * d[0], x1), min(y - w, y1) if d[1] else y - w, z),
            (max(x + w, x1 + w * abs(d[1])) if d[0] == 0 else max(x - w * d[0], x1), max(y + w, y1) if d[1] else y + w, z + H))


def osign(face, line, a, z, row, arrow=None, w=192, h=48):
    """Neon objective sign (~vx_objsign, 192x48, ONE drawn face) centred at `a` along the wall.
    row: 0 = 1 TRAFO, 1 = 2 KOPRU, 2 = 3 CATI, 3 = ZIPLA! (launch pad), 4 = HELI (zombie geyser);
    the printed chevrons point along the world direction `arrow` (picks the > or < atlas row)."""
    if row < 3:
        n = np.array(_NORM[face], float)
        u, _ = readable_axes(n)
        right = arrow is None or float(np.dot(u, (arrow[0], arrow[1], 0))) >= 0
        r = row * 2 + (0 if right else 1)
    else:
        r = 3 + row
    return wall_plate(face, line, a - w / 2, a + w / 2, z, z + h, OBJ, depth=2, row=r, rows=8)


def fun(b):
    D, W, E, ents = b.D, b.W, b.ent, b.ents

    def pt(cls, name=None, **kw):
        e = Entity(cls, **kw)
        if name:
            e['targetname'] = name
        ents.append(e)
        return e

    def mm(name, seq, origin=(0, 0, 64)):
        e = pt('multi_manager', name, origin=origin)
        for tgt, dl in seq:
            e[tgt] = dl
        return e

    def cmd(name):
        if not any(e.props.get('targetname') == name and e.props['classname'] == 'trigger_relay' for e in ents):
            pt('trigger_relay', name, triggerstate=2, origin=(0, 0, 96))
        return name

    # ------------------------------------------------------------ pads: lit slab, jet beam (env_beam), light, hiss
    nb = [0]

    def pad(x, y, z, kind, d=None, r=None):
        r = r or (56 if kind == 'go' else 40)
        nb[0] += 1
        col = (60, 220, 255) if kind == 'go' else (255, 50, 40)
        # one lit slab: cyan light panel = shortcut launch pad, red = zombie heli-access geyser (zombies take
        # no fall damage in this mod; a human who rides a red geyser lands back with ~40 damage)
        D(box((x - r, y - r, z), (x + r, y + r, z + 2),
              {'top': '~vx_light_c' if kind == 'go' else LRED, 'bottom': NULL, 'all': HAZ}))
        a, bb = f'cd_jet{nb[0]}a', f'cd_jet{nb[0]}b'
        pt('info_target', a, origin=(x, y, z + 6))
        if d is None:
            end = (x, y, z + 300)
        else:
            end = (x + d[0] * 150, y + d[1] * 150, z + 170)
        pt('info_target', bb, origin=end)
        pt('env_beam', LightningStart=a, LightningEnd=bb, spawnflags=1, life=0, NoiseAmplitude=6, BoltWidth=48,
           texture='sprites/laserbeam.spr', rendercolor=col, renderamt=110, TextureScroll=60, damage=0,
           Radius=64, StrikeTime=0, origin=(x, y, z + 6))
        ents.append(light((x, y, z + 48), col, 110))
        ents.append(ambient((x, y, z + 24), 'vexmira/map/cd_jet.wav', 4, 'small'))

    def push(boxes, speed, angles):
        tb = []
        for mn, mx in boxes:
            tb += box(mn, mx, 'AAATRIGGER')
        E(Entity('trigger_push', tb, speed=speed, angles=angles))

    # Launch physics (GoldSrc pm_shared): a push field's vertical part is an ACCELERATION while you are inside
    # it (basevelocity.z * frametime) and is lost while standing on the ground, so every pad is a JUMP pad
    # (signs: ZIPLA! / JUMP!); the horizontal part is a conveyor + exit momentum. Arcs verified with a
    # frame-step simulation of that model (gravity 800, jump 268 u/s, entry speed 0 and 250) and on the
    # test server (vexprobe): see zm_vex_cordon_TEST.md.
    # S1 Liberation Plaza -> Customs Tower roof: a vertical updraft against the tower facade right under the
    # medevac air window (shared G_UP field, H 200 -> apex ~+780); hold forward: you slide up the wall,
    # pass the parapet (640) and drop ~200 onto the roof (no fall damage)
    pad(1088, -50, 0, 'go', None, r=48)
    ups_s1 = [((1040, -120, 0), (1136, 20, 200))]
    # S2 Substation express: supply-alley mouth -> gantry deck z 160 (breaker B). H 64, up 3000, fwd 550:
    # lands 800 (standing jump) .. 1170 (running) units south = deck y 140 .. -230, apex +290, clears the stairs
    pad(-2112, 940, 0, 'go', (0, -1))
    push([lane(-2112, 940, 0, (0, -1), 64, 320)], round(math.hypot(3000, 550)),
         f'{-math.degrees(math.atan2(3000, 550)):.1f} -90.0 0')
    # S3/S4 Quay express both ways: H 48, up 1600, fwd 1050 -> lands 1290..1600 units on, apex +140 (safe)
    pad(-1560, -2050, -128, 'go', (1, 0))
    pad(560, -1960, -128, 'go', (-1, 0))
    qa = f'{-math.degrees(math.atan2(1600, 1050)):.1f}'
    push([lane(-1560, -2050, -128, (1, 0), 48, 400)], round(math.hypot(1600, 1050)), qa + ' 0.0 0')
    push([lane(560, -1960, -128, (-1, 0), 48, 400)], round(math.hypot(1600, 1050)), qa + ' 180.0 0')
    D(osign('s', -1600, -1200, -40, 3, (1, 0)))
    D(osign('s', -1600, 760, -40, 3, (-1, 0)))
    # heli-access geysers (zombies): straight up, apex ~ +380, beside the medevac route
    G = [(-300, 600, 0), (-1040, 0, 0), (250, -660, 0), (2060, 170, 576)]
    for x, y, z in G:
        pad(x, y, z, 'z')
    ups = [((x - 32, y - 32, z), (x + 32, y + 32, z + 150)) for x, y, z in G]         # measured apex ~ +380

    # ------------------------------------------------------------ objective guidance (numbered, colour-coded)
    for args in (
            ('n', 1408, -2496, 150, 0, (1, 0)),        # A CT spawn: 1 TRAFO -> supply alley / command post
            ('s', 1024, -2400, 140, 0, (-1, 0)),       # S north wall: switch house is west
            ('w', -1984, 360, 230, 1, (0, -1)),        # S east wall: 2 KOPRU -> lantern lane
            ('n', -640, -2700, 250, 1, (-1, 0)),       # S south wall: 2 KOPRU -> stair lane
            ('e', -1152, -100, 230, 1, (0, -1)),       # P west: 2 KOPRU -> harbor steps
            ('n', -1152, 640, 250, 1, (-1, 0)),        # P south wall: -> arch
            ('s', 1024, -100, 230, 2, (1, 0)),         # P north: 3 CATI -> tower
            ('s', -1600, 560, 40, 1, (1, 0)),         # Q arcade: 2 KOPRU -> cabin
            ('s', -1088, 1900, 40, 2, (1, 0)),         # C: 3 CATI -> Kade ramp
            ('e', 2176, 330, 130, 2, (0, -1)),         # Km: 3 CATI -> fire escape
            ('w', 2560, -500, 140, 2, (0, 1)),         # Ks: 3 CATI -> north
    ):
        D(osign(*args))

    # ------------------------------------------------------------ travel moments (owner: one every ~600-900
    # units of every main route): trigger_multiple (wait = cooldown) -> multi_manager. Sounds are only game
    # sounds every map already precaches (bspcheck GAME_BASE_SOUNDS) or ours: no new precache slots.
    def snd(name, p, wav, vol=10, rad='medium'):
        ents.append(ambient(p, wav, vol, rad, False, True, name))

    def trig(mn, mx, target, wait):
        E(Entity('trigger_multiple', box(mn, mx, 'AAATRIGGER'), target=target, wait=wait))

    def puff(name, p):                      # dust puff: env_explosion smoke only (no fireball / damage / decal)
        pt('env_explosion', name, origin=p, iMagnitude=40, spawnflags=1 + 2 + 4 + 16)

    def jolt(name, p, amp=5, rad=500):
        pt('env_shake', name, origin=p, amplitude=amp, duration=0.8, radius=rad, frequency=60)

    # M1 market: something bangs on the pharmacy shutter from inside (dust + shake)
    snd('cd_s_bang1', (-1660, 2236, 64), 'debris/wood1.wav')
    snd('cd_s_bang2', (-1660, 2236, 64), 'debris/wood2.wav')
    snd('cd_s_bang3', (-1660, 2236, 64), 'common/bodysplat.wav')
    puff('cd_s_bpuff', (-1664, 2232, 100))
    jolt('cd_s_bshk', (-1664, 2200, 64))
    mm('cd_s_bang_mm', [('cd_s_bang1', 0), ('cd_s_bshk', 0), ('cd_s_bang2', 0.5), ('cd_s_bang3', 1.1),
                        ('cd_s_bpuff', 1.1), ('cd_s_bang1#2', 1.9)])
    trig((-1840, 1900, 0), (-1700, 2150, 72), 'cd_s_bang_mm', 25)
    # command post: the lights flicker and die, come back 3 s later (+ sparks)
    lt = light((-2752, 1216, 160), (255, 200, 140), 160, targetname='cd_lt_cpflk')
    ents.append(lt)
    snd('cd_s_spark', (-2752, 1216, 150), 'buttons/spark5.wav', 8)
    mm('cd_s_flk_mm', [('cd_lt_cpflk', 0), ('cd_s_spark', 0), ('cd_lt_cpflk#2', 0.15), ('cd_lt_cpflk#3', 0.3),
                       ('cd_lt_cpflk#4', 0.55), ('cd_lt_cpflk#5', 0.7), ('cd_lt_cpflk#6', 3.2)])
    trig((-2900, 1120, 0), (-2600, 1320, 72), 'cd_s_flk_mm', 20)
    # jump-scare silhouettes: a dark figure darts out of a wall, crosses fast and hides again (passable
    # func_train, no damage), with footsteps / a thud and the local light flickering; 20-30 s cooldown
    def shadow(tag, axis, p0, p1, trig_box, lightp):
        x, y, z = p0
        if axis == 'y':        # moves along y: thin in x, faces e/w
            sil = box((x - 2, y - 22, z - 40), (x + 2, y + 22, z + 40), {'all': NULL, 'e': '{vx_shadow', 'w': '{vx_shadow'})
            sil[0].fit_faces(('e', 'w'))
        else:                  # moves along x: thin in y, faces n/s
            sil = box((x - 22, y - 2, z - 40), (x + 22, y + 2, z + 40), {'all': NULL, 'n': '{vx_shadow', 's': '{vx_shadow'})
            sil[0].fit_faces(('n', 's'))
        E(Entity('func_train', sil, targetname=f'cd_{tag}', target=f'cd_{tag}0', speed=330, spawnflags=8,
                 rendermode=4, renderamt=255, dmg=0))
        pt('path_corner', f'cd_{tag}0', origin=p0, target=f'cd_{tag}1', spawnflags=1)      # hidden in the wall
        pt('path_corner', f'cd_{tag}1', origin=p1, target=f'cd_{tag}0', wait=0.6)          # then back + stop
        ents.append(light(lightp, (255, 190, 130), 140, targetname=f'cd_lt_{tag}'))
        snd(f'cd_s_{tag}a', p1, 'common/npc_step2.wav', 9)
        snd(f'cd_s_{tag}b', p1, 'common/bodysplat.wav', 9)
        mm(f'cd_{tag}_mm', [(f'cd_lt_{tag}', 0), (f'cd_{tag}', 0.15), (f'cd_lt_{tag}#2', 0.15), (f'cd_s_{tag}a', 0.4),
                            (f'cd_lt_{tag}#3', 0.5), (f'cd_s_{tag}b', 0.9), (f'cd_lt_{tag}#4', 1.4)])
        trig(*trig_box, f'cd_{tag}_mm', 25)

    # hidden around a corner (out of sight of the trigger zone), darts into view, goes back
    shadow('shadow', 'y', (-1550, -450, 40), (-1550, 40, 40), ((-1960, -180, 0), (-1880, 90, 72)), (-1550, -60, 170))
    shadow('shadow2', 'y', (-1408, 1500, 40), (-1408, 1920, 40), ((-1915, 1890, 0), (-1845, 2140, 72)), (-1408, 1900, 170))
    # fish market: the skylight bursts and glass rains down
    sky = E(glass(box((-2990, -1790, 236), (-2710, -1610, 240), 'vx_glass'), health=20))
    sky['targetname'], sky['spawnflags'] = 'cd_skylight', 1
    jolt('cd_s_skshk', (-2850, -1700, -100), 4)
    mm('cd_s_sky_mm', [('cd_skylight', 0), ('cd_s_skshk', 0)])
    trig((-2990, -1790, -128), (-2710, -1610, -56), 'cd_s_sky_mm', 5)
    # field hospital: the ward's side door bursts open as you pass (stays open for the round)
    dd = box((2240, 1900, 0), (2368, 1908, 128), 'vx_door_metal')
    dd[0].fit_faces(('n', 's'))
    E(Entity('func_door_rotating', dd + box((2240, 1900, 60), (2248, 1908, 68), 'ORIGIN'), targetname='cd_burst',
             distance=100, speed=400, wait=-1, dmg=0, lip=0, movesnd=0, stopsnd=0, spawnflags=2, _minlight=0.2))
    snd('cd_s_door1', (2304, 1904, 64), 'common/bodysplat.wav')
    snd('cd_s_door2', (2304, 1904, 64), 'debris/wood3.wav')
    puff('cd_s_dpuff', (2304, 1880, 60))
    jolt('cd_s_dshk', (2304, 1880, 60), 6)
    mm('cd_s_door_mm', [('cd_s_door2', 0), ('cd_s_dshk', 0), ('cd_s_door2#2', 0.7), ('cd_burst', 1.3),
                        ('cd_s_door1', 1.3), ('cd_s_dpuff', 1.3)])
    trig((2180, 1620, 0), (2440, 1840, 72), 'cd_s_door_mm', 30)

    # fun: shootable hazard barrels (smoke burst + a little ammo, once per round each)
    for i, (x, y, z) in enumerate(((-900, -240, 0), (2050, -1620, -128))):
        e = E(Entity('func_breakable', box((x - 16, y - 16, z), (x + 16, y + 16, z + 44),
                                           {'top': MDARK, 'all': HAZ}), material=0, health=40,
                     target=f'cd_barrel{i}_mm', _minlight=0.2))
        pt('env_explosion', f'cd_barrel{i}_fx', origin=(x, y, z + 30), iMagnitude=35, spawnflags=1 + 2 + 16)
        mm(f'cd_barrel{i}_mm', [(f'cd_barrel{i}_fx', 0), (cmd(f'vexcmd_reward_h_{i + 1}'), 0.2)])
    # fun: trampolines (one entity): station -> train car 2 roof, terminal -> container stack, Kade -> balcony
    tramp = [(200, 2104, 0), (2050, -1690, -128), (2330, -60, 0)]
    for x, y, z in tramp:
        D(box((x - 28, y - 28, z), (x + 28, y + 28, z + 2), {'top': CHEV, 'bottom': NULL, 'all': HAZ}))
    ups += [((x - 24, y - 24, z), (x + 24, y + 24, z + 75)) for x, y, z in tramp]      # measured apex ~ +170
    ups += ups_s1
    push(ups, G_UP, '-90 0 0')
    # fun: lobby vending machine (use it: clunk + a little ammo, 30 s cooldown)
    D(P((2096, 200, 0), (2160, 280, 104), 'vx_cont_red', hide=('bottom', 'e')))
    D(wall_plate('w', 2096, 210, 270, 70, 98, '~vx_light_w', depth=2))
    E(Entity('func_button', box((2092, 226, 40), (2096, 254, 60), HAZ), target='cd_vend_mm', wait=30, speed=50,
             lip=2, angles=(0, 0, 0), sounds=0, _minlight=0.5))
    snd('cd_s_vend', (2090, 240, 30), 'items/gunpickup2.wav', 8, 'small')
    snd('cd_s_vend2', (2090, 240, 30), 'common/bodydrop3.wav', 8, 'small')
    mm('cd_vend_mm', [('cd_s_vend2', 0.3), ('cd_s_vend', 0.6), (cmd('vexcmd_reward_h_3'), 0.6)])

    # ------------------------------------------------------------ moving things (always on, no reset needed)
    ORG = 'ORIGIN'
    dish = box((1300, 600, 1160), (1324, 680, 1216), MDARK) + box((1306, 636, 1152), (1318, 644, 1160), MDARK) + \
        box((1308, 636, 1180), (1316, 644, 1188), ORG)
    E(Entity('func_rotating', dish, speed=40, spawnflags=1, _minlight=0.3))   # radar dish on the crown
    trol = box((2440, -2016, 424), (2504, -1984, 446), MDARK) + box((2468, -2004, 376), (2476, -1996, 424), MDARK) + \
        box((2420, -2040, 336), (2524, -1960, 376), 'vx_cont_red')
    pt('path_corner', 'cd_trol0', origin=(2472, -2000, 391), target='cd_trol1', wait=2)
    pt('path_corner', 'cd_trol1', origin=(2730, -2000, 391), target='cd_trol0', wait=2)
    E(Entity('func_train', trol, target='cd_trol0', speed=40, spawnflags=8, dmg=0.001, _minlight=0.2))
    lamp = box((-700, 1796, 380), (-692, 1804, 444), MDARK) + \
        box((-716, 1780, 360), (-676, 1820, 380), {'bottom': '~vx_light_w', 'all': MDARK}) + \
        box((-700, 1796, 436), (-692, 1804, 444), ORG)
    E(Entity('func_pendulum', lamp, speed=30, distance=30, damp=0, spawnflags=1 + 8 + 64, _minlight=0.5))

    # ------------------------------------------------------------ timed collapses after freeze end (once per round;
    # func_door(_rotating) wait -1 are restored by the game on round restart; dmg 0 = blocked just waits)
    def boom(name, p, mag, snd_name):
        pt('env_explosion', name + '_fx', origin=p, iMagnitude=mag, spawnflags=3)
        pt('env_shake', name + '_sh', origin=p, amplitude=9, duration=1.5, radius=1400, frequency=40)
        ents.append(ambient(p, 'vexmira/map/cd_boom.wav', 10, 'large', False, True, snd_name))
    # C1 Kade: radio mast crashes across the north road
    mast = box((2360, 1192, 0), (2376, 1208, 400), RUST) + box((2340, 1196, 360), (2396, 1204, 368), RUST) + \
        box((2364, 1196, 4), (2372, 1204, 12), ORG)
    E(Entity('func_door_rotating', mast, targetname='cd_mast', distance=88, speed=70, wait=-1, dmg=0, lip=0,
             movesnd=0, stopsnd=0, spawnflags=64, _minlight=0.2))
    boom('cd_mast', (2368, 1100, 40), 80, 'cd_boom_kn')
    # C2 station: hanging departure board slams down onto the platform
    E(Entity('func_door', box((-760, 1490, 260), (-440, 1506, 330), SIGNS), targetname='cd_board', speed=500,
             wait=-1, lip=-190, dmg=0, movesnd=0, stopsnd=0, angles=(0, -2, 0), _minlight=0.2))
    boom('cd_board', (-600, 1520, 40), 50, 'cd_boom_rb')
    # C3 container terminal: the crane drops a container (from z 300 to the deck)
    E(Entity('func_door', box((2830, -2060, 300), (2900, -1940, 400), 'vx_cont_blue'), targetname='cd_drop',
             speed=600, wait=-1, lip=-328, dmg=0, movesnd=0, stopsnd=0, angles=(0, -2, 0), _minlight=0.2))
    boom('cd_drop', (2865, -2000, -100), 70, 'cd_boom_c')
    mm('vex_freeze_end', [('cd_mast', 50), ('cd_mast_fx', 50.8), ('cd_mast_sh', 50.8), ('cd_boom_kn', 50.8),
                          ('cd_board', 95), ('cd_board_fx', 95.3), ('cd_board_sh', 95.3), ('cd_boom_rb', 95.3),
                          ('cd_drop', 140), ('cd_drop_fx', 140.7), ('cd_drop_sh', 140.7), ('cd_boom_c', 140.7)],
       origin=(0, 0, 300))


# ==============================================================================================
def build(mock=False, mock_scale=1.0) -> Map:
    b = Builder(mock)
    Z = b.zone
    X, Y = 'x', 'y'
    sk = lambda axis, line, a0=-INF, a1=INF, h0=-INF, h1=INF: (axis, line, a0, a1, h0, h1)

    # ---------------------------------------------------------------- NORTH-WEST: cordon
    # v  no-man's land vista (unreachable). s wall = quarantine wall, owned by A.
    Z('v', [(-3328, 2576, -1984, 3200)], 0, 1152, 'vx_dirt', CONC, rl=0,
      holes=[sk(Y, 2576, h1=784)])
    # A  Gate 7 checkpoint (CT spawn yard 1344 x 1152)
    Z('A', [(-3328, 1408, -1984, 2560)], 0, 768, CRACK, QUAR, rl=448,
      rls=[(X, -3328, -INF, INF, 512)],
      holes=[(Y, 2560, -3328, -1984, 448, 768),          # over the quarantine wall into the vista
             (Y, 2560, -2768, -2512, 0, 320),            # Gate 7 (cd_gate7)
             (X, -1984, 1888, 2144, 0, 208),             # sally port -> market
             (Y, 1408, -2816, -2688, 0, 128),            # -> command post
             (Y, 1408, -2304, -2176, 0, 192)],           # -> supply alley (dog-leg N hole)
      out={(Y, 1408): PLAST, (Y, 2560): 'vx_dirt'})
    b.W(box((-3328, 2560, 448), (-1984, 2576, 768), CLIP))           # no climbing over the cordon
    # sally port tunnel A -> M1 (overpass header)
    b.tunnel(X, -1968, -1936, 1888, 2144, 0, 208, BUNK, CRACK, BUNK)
    # c  command post (indoor, doors N + S)
    Z('c', [(-3072, 1040, -2432, 1392)], 0, 176, CRACK, PLAST, top=PLAST,
      holes=[sk(Y, 1392), sk(Y, 1040)])
    # a  supply alley (dog-leg: N hole x[-2304,-2176] in A's wall, S hole x[-2176,-2048] in S's wall)
    Z('a', [(-2304, 1040, -2048, 1392)], 0, 640, CRACK, FAC, rl=320, holes=[sk(Y, 1392), sk(Y, 1040)])
    b.W(box((-2208, 1168, 0), (-2048, 1264, 192), BUNK))            # dog-leg baffle (sandbag wall, world)

    # ---------------------------------------------------------------- WEST: substation
    Z('S', [(-3328, -640, -1984, 1024)], 0, 704, CRACK, FAC, rl=448,
      rls=[(Y, 1024, -INF, INF, 384), (X, -3328, -INF, INF, 512), (X, -1984, -INF, INF, 416)],
      holes=[(Y, 1024, -2816, -2688, 0, 128), (Y, 1024, -2176, -2048, 0, 192),
             (X, -1984, -192, 96, 0, 224),                # -> lantern lane
             (Y, -640, -3200, -2944, 0, 224)],            # -> stair lane
      out={(Y, 1024): PLAST})
    # h  switch house (breaker A), doors E + S
    Z('h', [(-3200, 384, -2752, 896)], 0, 176, CRACK, CORR, top={'bottom': MDARK, 'all': CORR},
      holes=[(X, -2752, 576, 704, 0, 128), (Y, 384, -3040, -2912, 0, 128)])
    # gantry deck z 160 (camp C3): stairs N end (CLIP ramp), ladder S end
    b.W(box((-2272, -512, 144), (-2048, 480, 160), MDARK))
    b.W(stairs((-2144, 800, 0), '-y', 128, 160, rise=16, run=32, tex=MDARK, clip=True))
    b.W(box((-2192, -512, 0), (-2128, -496, 144), MDARK))            # ladder back plate
    b.ladder('S', (-2160, -512, 0), '+y', 164)
    for x, y in ((-2264, -500), (-2064, -500), (-2264, 460), (-2064, 460), (-2264, -20), (-2064, -20)):
        b.D(box((x - 8, y - 8, 0), (x + 8, y + 8, 144), MDARK))      # deck posts
    for i in range(3):                                                # transformer compounds (blockout)
        x = -3168 + i * 352
        b.D(box((x, -400, 0), (x + 224, -224, 192), MDARK))

    # ---------------------------------------------------------------- lantern lane (Z-bend)
    Z('L', [(-1968, -192, -1680, 96), (-1680, -576, -1424, 96), (-1424, -576, -1168, -288)], 0, 640,
      ASPH, BRICK, rl=352, rls=[(X, -1424, -INF, INF, 320), (X, -1680, -INF, INF, 384)],
      holes=[sk(X, -1968), sk(X, -1168)])

    # ---------------------------------------------------------------- market street + pharmacy + arcade
    Z('M', [(-1920, 1792, -1168, 2240), (-1600, 704, -1216, 1792)], 0, 704, ASPH, FAC, rl=448,
      rls=[(Y, 2240, -INF, INF, 384), (X, -1216, -INF, INF, 384)],
      holes=[(X, -1920, 1888, 2144, 0, 208),             # sally port
             (X, -1168, 1920, 2112, 0, 160),             # station side gate (roller shutter)
             (X, -1216, 736, 960, 0, 192),               # arcade -> plaza
             (Y, 2240, -1856, -1760, 0, 112),            # pharmacy door
             (Y, 2240, -1728, -1600, 48, 144)],          # pharmacy shop window (breakable)
      out={(Y, 2240): PLAST})
    Z('p', [(-1904, 2256, -1584, 2480)], 0, 160, TILE, PLAST, top=PLAST, holes=[sk(Y, 2256)])
    b.tunnel(X, -1216, -1152, 736, 960, 0, 192, CONC, ASPH, CONC)    # market arcade m
    b.tunnel(X, -1152, -1104, 1920, 2112, 0, 160, CORR, CRACK, CORR)  # station side gate
    b.D(box((-1696, 2192, 0), (-1640, 2240, 48), 'vx_crate_mil'))    # duck-jump crate under the window

    # ---------------------------------------------------------------- terminus station (T spawn)
    sky_strips = [(-1024, y, 1024, y + 64) for y in (1600, 1952, 2272)]
    R = Z('R', [(-1088, 1408, 1088, 2496)], -32, 448, 'vx_dirt', BRICK, top=CORR, top_sky=sky_strips,
          holes=[(X, -1088, 1920, 2112, 0, 160),         # side gate
                 (Y, 1408, -768, -576, 0, 192),          # -> forecourt W
                 (Y, 1408, 576, 768, 0, 192),            # -> forecourt E
                 (X, 1088, 1984, 2368, 0, 256)],         # breach -> hospital
          out={(Y, 1408): FAC, (X, 1088): FAC})
    pit = (-896, 2048, 1088, 2400)                                    # track bed -32 (terminus buffers W)
    for r in rect_minus((-1088, 1408, 1088, 2496), [pit]):
        b.W(box((r[0], r[1], -32), (r[2], r[3], 0), CRACK))
    b.W(box((-128, 1408, -32), (128, 1856, 448), CONC))               # ticket block (VIS splitter)
    # derailed train: car 1 (duck-jump roof 104), car 2 (camp C2 roof 128, ladder), car 3 in the breach
    b.D(box((-880, 2112, -32), (-400, 2240, 104), RUST))
    b.D(box((-320, 2160, -32), (352, 2288, 128), RUST))
    b.D(box((640, 2112, -32), (1072, 2240, 112), RUST))
    b.D(box((-472, 2056, 0), (-424, 2104, 56), 'vx_crate_mil'))      # duck-jump crate -> car 1
    b.W(box((-48, 2156, -32), (48, 2160, 128), NULL))                # ladder face (inside car 2 skin)
    b.ladder('R', (0, 2160, -32), '+y', 164)

    # forecourts (dog-legs R <-> P)
    for key, xr in (('f1', (-768, -384)), ('f2', (384, 768))):
        Z(key, [(xr[0], 1040, xr[1], 1392)], 0, 512, CRACK, FAC, rl=256,
          holes=[sk(Y, 1392, h1=464), sk(Y, 1040)])
        mid = (xr[0] + xr[1]) / 2
        b.W(box((mid - 32, 1168, 0), (mid + 32, 1264, 160), BUNK))    # baffle in the dog-leg

    # ---------------------------------------------------------------- field hospital + ward
    Z('H', [(1104, 1344, 2560, 2496)], 0, 640, CRACK, FAC, rl=384, rls=[(Y, 2496, -INF, INF, 448)],
      holes=[sk(X, 1104, 1408, 2496, h1=464),
             (Y, 1344, 2240, 2496, 0, 256)])             # checkpoint B arch -> Kade
    Z('w', [(1856, 1904, 2544, 2480)], 0, 176, TILE, PLAST, top={'bottom': PLAST, 'all': MDARK},
      holes=[(X, 1856, 2048, 2176, 0, 128), (Y, 1904, 2240, 2368, 0, 128)])

    # ---------------------------------------------------------------- Liberation Plaza (boss arena)
    Z('P', [(-1152, -1152, 1152, 1024)], 0, 1216, ASPH, FAC, rl=512,
      rls=[(Y, 1024, -INF, INF, 448), (Y, -1152, -INF, INF, 640), (X, 1152, -INF, INF, 640),
           (X, 1152, 448, 832, 1152)],                   # tower facade + crown
      holes=[(Y, 1024, -576, -384, 0, 192), (Y, 1024, 384, 576, 0, 192),      # forecourts
             (X, -1152, 736, 960, 0, 192), (X, -1152, -576, -288, 0, 208),    # arcade, lantern lane (flush)
             (X, 1152, 96, 352, 0, 128),                                       # lobby glass doors
             (X, 1152, -288, -128, 240, 320), (X, 1152, 176, 336, 240, 320),   # office windows (T1)
             (X, 1152, -560, -400, 0, 208),                                    # south passage t
             (X, 1152, -160, 400, 640, 920),                                   # heli air window (roof)
             (Y, -1152, -384, 384, 0, 136)],                                   # harbor steps arch (low: cuts the Q-e-P sight line)
      out={(X, 1152): PLAST})
    b.D(box((-160, -224, 0), (160, 96, 96), CONC))                   # monument plinth (blockout)

    # ---------------------------------------------------------------- Customs Tower
    nw_core, se_core = (1184, 464, 1440, 816), (1888, -368, 2144, -16)
    nw_fl, se_fl = (1184, 592, 1440, 816), (1888, -240, 2144, -16)    # stair flights + N landings
    tower = [(1168, -384, 2160, 832)]
    for key, z0, z1 in (('T0', 0, 176), ('T1', 192, 368), ('T2', 384, 560)):
        Z(key, tower, z0, z1, CRACK if key != 'T0' else TILE, PLAST,
          top={'bottom': CONC, 'all': {'T0': TILE, 'T1': CRACK, 'T2': CRACK}[key]}, top_holes=[nw_fl, se_fl],
          holes=[sk(X, 1168), sk(X, 2160)] + ([(Y, -384, 1920, 2048, 0, 112)] if key == 'T0' else []),
          out={(Y, 832): FAC, (Y, -384): FAC}, omit=('bottom',) if key != 'T0' else ())
    Z('T3', tower, 576, 1536, CRACK, CONC, rl=640, omit=('bottom',),
      holes=[sk(X, 1168, h1=1232), sk(X, 2160, h1=720)], out={(Y, 832): FAC, (Y, -384): FAC})
    for key, rc, door_side, door_span, flA, flB, dirA in (
            ('Cnw', nw_core, X, (1440, 464, 592), (1248, 592), (1376, 720), '+y'),
            ('Cse', se_core, X, (1888, -368, -240), (1952, -240), (2080, -112), '+y')):
        line, d0, d1 = door_span
        hs = [(X, line, d0, d1, L, L + 112) for L in (0, 192, 384, 576)]
        if key == 'Cse':
            hs.append((Y, -368, 1920, 2048, 0, 112))      # from the south passage
        Z(key, [rc], 0, 704, CONC, CONC, top=CONC, holes=hs, omit=('bottom',))
        nl = (rc[0], flB[1] if key == 'Cnw' else -112, rc[2], rc[3])  # north landing
        for L in (0, 192, 384):
            b.W(stairs((flA[0], flA[1], L), dirA, 128, 96, rise=12, run=16, tex=CRACK, clip=True))
            b.W(box((nl[0], nl[1], L + 80), (nl[2], nl[3], L + 96), CRACK))
            b.W(stairs((flB[0], flB[1], L + 96), '-y', 128, 96, rise=12, run=16, tex=CRACK, clip=True))
        b.W(box((flB[0] - 64, flA[1], 0), (flB[0] + 64, flB[1], 96), CONC))   # fill under the first B flight
    b.W(box((1168, 448, 720), (1456, 832, 1152), CONC))              # crown (landmark seen from the plaza)
    # tower south passage t (flank P <-> K)
    Z('t', [(1168, -560, 2160, -400)], 0, 512, ASPH, FAC, rl=256,
      holes=[sk(X, 1168), sk(X, 2160), sk(Y, -400)])

    # ---------------------------------------------------------------- Kade (3 cells split by gate arches)
    arch = lambda line: (Y, line, 2240, 2496, 0, 224)
    kw = {(X, 2176): PLAST}
    Z('Kn', [(2176, 656, 2560, 1328)], 0, 704, ASPH, BRICK, rl=448, rls=[(X, 2176, -INF, INF, 640)],
      holes=[sk(Y, 1328, h1=656), arch(656)], out=kw)
    Z('Km', [(2176, -304, 2560, 624)], 0, 704, ASPH, BRICK, rl=448, rls=[(X, 2176, -INF, INF, 640)],
      holes=[arch(624), arch(-304),
             (X, 2176, 48, 144, 192, 304),               # fire-escape balcony door into T1
             (X, 2176, 32, 96, 576, 704)], out=kw)       # roof hatch (parapet) into T3
    Z('Ks', [(2176, -1072, 2560, -336)], -128, 704, ASPH, BRICK, rl=448, rls=[(X, 2176, -INF, INF, 640)],
      holes=[arch(-336), (X, 2176, -560, -400, 0, 208), sk(Y, -1072)], out=kw)
    for r in rect_minus((2176, -1072, 2560, -336), [(2176, -1072, 2560, -800)]):
        b.W(box((r[0], r[1], -128), (r[2], r[3], 0), CRACK))
    b.W(wedge((2368, -1072, -128), '+y', 384, 272, 128, ASPH))     # ramp 0 -> -128 to the terminal
    # fire escape: balcony z 192 + ladder 1 (K floor -> balcony) + ladder 2 (balcony -> roof hatch)
    b.W(box((2176, 0, 176), (2272, 192, 192), MDARK))
    b.W(box((2256, 64, 0), (2272, 128, 176), MDARK))
    b.ladder('K', (2272, 96, 0), '-x', 196)
    b.ladder('K', (2176, 64, 192), '-x', 388)

    # ---------------------------------------------------------------- stair lane + fish market
    Z('n', [(-3200, -1072, -2944, -656)], -128, 512, CRACK, FAC, rl=256,
      holes=[sk(Y, -656, h0=0), sk(Y, -1072, h1=272)])
    b.W(box((-3200, -800, -128), (-3072, -656, 0), CRACK))           # west half: landing z 0
    b.W(stairs((-3136, -1056, -128), '+y', 128, 128, rise=16, run=32, tex=CRACK, clip=True))
    b.W(box((-3072, -1072, -128), (-2944, -656, 0), CRACK))          # east half: level walkway to the loft
    Z('F', [(-3328, -2304, -1792, -1088)], -128, 256, CONC, TILE, top=RUST,
      top_sky=[(-3000, -1800, -2700, -1600), (-2400, -1800, -2100, -1600)],
      holes=[(X, -1792, -2240, -1984, -128, 96),         # net alley -> quay (roller shutter)
             (Y, -1088, -3200, -3072, -128, -16),        # under the loft from the stair lane
             (Y, -1088, -3072, -2944, 0, 112)],          # onto the loft
      out={(X, -1792): CONC})
    b.W(box((-3328, -1280, -16), (-1792, -1088, 0), MDARK))          # loft deck z 0 (camp C5)
    for x in (-2944, -2176):
        b.W(stairs((x, -1472, -128), '+y', 96, 128, rise=16, run=24, tex=MDARK, clip=True))

    # ---------------------------------------------------------------- harbor steps
    Z('e', [(-384, -1584, 384, -1168)], -128, 640, CRACK, FAC, rl=320,
      holes=[sk(Y, -1168, h0=0), sk(Y, -1584)])
    b.W(box((-384, -1232, -128), (384, -1168, 0), CRACK))            # top landing (plaza level)
    b.W(box((-128, -1520, -128), (128, -1232, 448), CONC))           # memorial block (VIS blocker, tall: breaks the Q-e-P axis)
    for xc in (-256, 256):
        b.W(stairs((xc, -1488, -128), '+y', 256, 128, rise=16, run=32, tex=CRACK, clip=True))

    # ---------------------------------------------------------------- quay + bridge cabin + canal
    Z('Q', [(-1776, -2560, 1152, -1600)], -128, 768, CONC, FAC, rl=384,
      holes=[(Y, -1600, -384, 384, -128, 64),            # customs arcade (header z 64)
             (X, 1152, -2240, -1856, -128, 384),         # bridge gap
             sk(X, -1776, -2304, -1600, h1=272), sk(Y, -2560)],
      out={(X, 1152): CONC})
    b.W(box((912, -1792, -128), (1152, -1600, 0), CONC))             # cabin base
    Z('cab', [(928, -1776, 1136, -1616)], 0, 128, MDARK, CORR, top={'bottom': MDARK, 'all': CORR},
      holes=[(X, 928, -1760, -1664, 0, 112), (Y, -1776, 960, 1120, 48, 112)])
    b.W(stairs((656, -1712, -128), '+x', 96, 128, rise=16, run=32, tex=CONC, clip=True))
    Z('~', [(1168, -2560, 1328, -1600)], -224, 768, 'vx_rock', CONC, rl=384,
      holes=[sk(X, 1168, h0=-128), sk(X, 1328, h0=-128), sk(Y, -2560, h0=-192)])
    b.W(box((1168, -2368, -224), (1328, -1728, -176), WATER))        # wading water (48 deep; dry rock ends)
    b.W(stairs((1264, -2208, -224), '-x', 64, 96, rise=16, run=16, tex=CONC))   # exit steps W bank
    b.W(stairs((1232, -1888, -224), '+x', 64, 96, rise=16, run=16, tex=CONC))   # exit steps E bank

    # ---------------------------------------------------------------- container terminal
    Z('C', [(1344, -2560, 3328, -1088)], -128, 896, CONC, BRICK, rl=448,
      holes=[(Y, -1088, 2176, 2560, -128, 256), (X, 1344, -2240, -1856, -128, 384), sk(Y, -2560)])
    stacks = [(1408, -2272, 1536, -1824, 2),             # blocks the bridge-gap view into the terminal
              (1664, -1472, 2240, -1344, 2), (2624, -1472, 3200, -1344, 2),
              (1792, -1856, 2304, -1728, 1), (3008, -1856, 3264, -1600, 2),
              (1664, -2304, 2240, -2176, 2), (2944, -2400, 3264, -2176, 1)]
    for x0, y0, x1, y1, hgt in stacks:
        tex = 'vx_cont_red' if (x0 // 128) % 2 else 'vx_cont_blue'
        b.W(box((x0, y0, -128), (x1, y1, -128 + 128 * hgt), tex))
    # gantry crane deck z 256 (camp C4): 4 legs, leg ladder, crate hop route from the 1-high stack
    b.W(box((2528, -2096, 240), (2784, -1904, 256), RUST))
    for x, y in ((2528, -2096), (2752, -2096), (2528, -1936), (2752, -1936)):
        b.D(box((x, y, -128), (x + 32, y + 32, 240), RUST))
    b.ladder('C', (2544, -2096, -128), '+y', 388)
    for x, y, z, h in ((2312, -1716, -128, 48), (2312, -1716, -80, 48),
                       (2840, -2000, -128, 48), (2840, -2000, -80, 48), (2840, -2000, -32, 48),
                       (2840, -2000, 16, 48), (2840, -2000, 64, 48), (2840, -2000, 112, 48),
                       (2840, -2000, 160, 48)):
        pass   # crate staircase placed below (stage 2 replaces with real props)
    for i, (x, h) in enumerate(((2880, 48), (2832, 96), (2800, 144), (2800, 192), (2800, 240))):
        b.D(box((x - 24, -1904 + 8, -128), (x + 24, -1904 + 56, -128 + h), 'vx_crate_mil'))

    # ---------------------------------------------------------------- bay vista (unreachable)
    Z('B', [(-3456, -3456, 3456, -2576)], -192, 1152, BAY, SKY, rl=-192,
      rls=[(Y, -2576, -INF, INF, -96)],
      holes=[(Y, -2576, -1776, 1152, -96, 768), (Y, -2576, 1168, 1328, -96, 768),
             (Y, -2576, 1344, 3328, -96, 896)], out={(Y, -2576): CONC})
    b.W(box((-1776, -2576, -96), (1152, -2560, 768), CLIP))
    b.W(box((1168, -2576, -96), (1328, -2560, 768), CLIP))
    b.W(box((1344, -2576, -96), (3328, -2560, 896), CLIP))
    b.W(box((700, -2900, -192), (2300, -2700, 128), RUST))          # freighter hull (VIS blocker Q|C)
    b.W(box((-3456, -3456, -192), (3456, -2576, 1152), CLIP))         # the bay is never walkable (vista only)
    b.W(box((-664, -3264, -192), (-536, -3136, 448), CONC))         # lighthouse (blockout)

    # ---------------------------------------------------------------- hidden helicopter hangar
    Z('hangar', [(3456, 2752, 4080, 3264)], 0, 384, NULL, NULL, top=NULL)

    # ============================================================== VIS: extra HINT planes
    # (mouth hints come from zone(); these split the big open cells into leaves that line up with
    # the openings, so the long N-S axis Q -> e -> P -> forecourts -> R only marks a narrow strip)
    def vplane(axis, c, a0, a1, z0, z1):
        if axis == X:
            b.hint((c - 4, a0, z0), (c + 4, a1, z1), 'x')
        else:
            b.hint((a0, c - 4, z0), (a1, c + 4, z1), 'y')
    for x in (-384, 384):
        vplane(X, x, -2560, -1600, -128, 384)          # quay: arcade edges
        vplane(X, x, -1152, 1024, 0, 640)              # plaza: arch / forecourt lines
    for x in (-576, 576):
        vplane(X, x, -1152, 1024, 0, 640)
        vplane(X, x, 1408, 2496, 0, 448)               # station: forecourt hole edges
    vplane(Y, 0, -1152, 1152, 0, 640)                  # plaza centre line
    vplane(X, -1680, -192, 96, 0, 640)                 # lantern lane Z-bend joints
    vplane(X, -1424, -576, -288, 0, 640)
    for key, zh in (('P', 232), ('Q', 72), ('R', 200), ('S', 232), ('C', 264), ('A', 216), ('H', 264)):
        for r in b.zones[key].rects:
            b.hint((r[0], r[1], zh), (r[2], r[3], zh + 8), 'z')

    # ============================================================== brush entities (structural set)
    E = b.ent
    gate = E(door(box((-2768, 2560, 0), (-2512, 2576, 320), RUST), 'up', speed=60, wait=-1, lip=0,
                  targetname='cd_gate7'))
    gate['movesnd'] = 2
    E(door(box((-1136, 1920, 0), (-1120, 2112, 160), CORR), 'up', speed=120, wait=4, lip=8))     # side gate
    E(door(box((-1792, -2240, -128), (-1776, -1984, 96), CORR), 'up', speed=120, wait=4, lip=8))  # net alley
    E(door(box((-2816, 1024, 0), (-2688, 1040, 128), 'vx_door_metal'), '+x', speed=160, wait=4))  # CP south
    E(door(box((-2752, 576, 0), (-2736, 704, 128), 'vx_door_metal'), '+y', speed=160, wait=4))    # switch house
    E(door(box((1840, 2048, 0), (1856, 2176, 128), 'vx_door_metal'), '+y', speed=160, wait=4))    # ward
    E(door(box((1920, -392, 0), (2048, -376, 112), 'vx_door_metal'), '+x', speed=160, wait=4))    # SE stair door
    for y0, y1, d in ((96, 224, '-y'), (224, 352, '+y')):                                         # lobby glass
        g = E(door(box((1152, y0, 0), (1168, y1, 128), 'vx_glass'), d, speed=160, wait=4))
        g['rendermode'], g['renderamt'] = 2, 90
    br = E(door(box((1152, -2176, 240), (1344, -1920, 256), RUST), 'down', speed=48, wait=-1, lip=-368,
                targetname='cd_bridge'))                               # lowers 384 to the quay level z -128
    br['movesnd'], br['_minlight'] = 2, 0.2
    for mn, mx, hp in (((-1728, 2240, 48), (-1600, 2256, 144), 80),    # pharmacy window
                       ((1152, -288, 240), (1168, -128, 320), 80),    # office glass W
                       ((1152, 176, 240), (1168, 336, 320), 80),      # office glass E
                       ((960, -1792, 48), (1120, -1776, 112), 60)):   # cabin glass
        E(glass(box(mn, mx, 'vx_glass'), health=hp))
    bar = E(glass(box((1440, 464, 0), (1456, 592, 112), 'vx_glass'), health=1500))               # riot barricade
    bar['targetname'], bar['target'] = 'cd_barricade', 'cd_barricade_mm'
    for area, vis in b.lad_vis.items():
        E(masked_entity(vis, solid=False))

    # ============================================================== spawns
    b.ents += spawn_grid('ct', (-3200, 1536), (-2560, 1880), 0, 32, spacing=72, yaw=0)
    b.ents += spawn_grid('t', (224, 1488), (1072, 1784), 0, 32, spacing=72, yaw=90)

    # ============================================================== stage 2: detail, light, atmosphere
    dress(b)
    # ============================================================== stage 3: interactivity + story wiring
    wire(b)
    fun(b)

    # ============================================================== mock detail (perf check only)
    if mock:
        budgets = {'v': 120, 'A': 550, 'c': 160, 'a': 100, 'M': 680, 'R': 850, 'f1': 90, 'f2': 90, 'H': 450,
                   'w': 120, 'S': 600, 'h': 120, 'L': 260, 'P': 700, 'T0': 200, 'T1': 240, 'T2': 120, 'T3': 280,
                   't': 60, 'Kn': 140, 'Km': 140, 'Ks': 140, 'n': 60, 'F': 480, 'e': 160, 'Q': 520, '~': 60,
                   'C': 650, 'B': 220}
        rng = random.Random(7)
        for key, faces in budgets.items():
            zn = b.zones[key]
            for _ in range(int(faces * mock_scale) // 5):
                r = rng.choice(zn.rects)
                sx, sy = rng.randint(16, 48), rng.randint(16, 48)
                x = rng.randint(int(r[0]) + 8, int(r[2]) - 8 - sx)
                y = rng.randint(int(r[1]) + 8, int(r[3]) - 8 - sy)
                z = zn.z0 + rng.choice((0, 0, 0, 64, 128))
                b.D(box((x, y, z), (x + sx, y + sy, z + rng.randint(16, 64)), MDARK))

    # ============================================================== assemble
    m = b.m
    if b.det:
        m.add_entity(Entity('func_detail', b.det, zhlt_detaillevel=1))
    m.add_entity(b.ents)
    m.add_entity(Entity('info_map_parameters', buying=3))
    b.m._zones = b.zones
    return m


# ----------------------------------------------------------------------------------------------
# --at checkpoints (spec section 12; eye z = floor + 54)
CHECKPOINTS = [
    ('A', (-2900, 1700, 54)), ('M1', (-1600, 2016, 54)), ('R', (0, 1950, 54)), ('R T-spawn', (540, 1600, 54)),
    ('S', (-2600, 200, 54)), ('gantry', (-2160, 0, 214)), ('P centre', (0, -400, 54)), ('P NW', (-1000, 900, 54)),
    ('T3 pad', (1664, 224, 630)), ('K', (2368, 100, 54)), ('F', (-2560, -1700, -74)), ('e', (-256, -1200, 54)),
    ('Q', (0, -2100, -74)), ('C', (2600, -1900, -74)), ('crane', (2650, -2000, 310)),
]
# eye shots: (x, y, z, yaw, pitch), one per district
EYES = [
    (-2880, 1700, 54, 0, 0),        # A: CT spawn looking at the sally port
    (-1800, 2016, 54, 0, 0),        # M1 toward the station side gate
    (-1408, 1500, 54, 270, 0),      # M2 toward the arcade
    (600, 1600, 54, 90, 0),         # R: T spawn looking at the train
    (-900, 1950, 54, 0, 0),         # R platform east
    (-2600, 200, 54, 0, 0),         # S yard toward the gantry
    (-1850, -50, 54, 0, 0),         # L lane
    (-900, 800, 54, 315, 0),        # P from the NW toward the tower
    (0, -900, 54, 90, 0),           # P from the south (monument, forecourts)
    (1400, 224, 54, 0, 0),          # T0 lobby
    (1300, 224, 630, 0, 0),         # T3 roof
    (2368, 900, 54, 270, 0),        # K north cell
    (-2560, -1500, -74, 270, 0),    # F fish market
    (-256, -1200, 54, 270, -10),    # e harbor steps (west flight, down to the quay arcade)
    (-600, -2100, -74, 0, 0),       # Q toward the bridge gap
    (2368, -1200, -74, 270, 0),     # C terminal from the ramp
    (1250, 1700, 54, 20, 0),        # H yard (from the breach side)
]


# ==============================================================================================
# sounds (spec section 13): seamless loops with a cue chunk + one one-shot, fixed seeds
SOUND_DIR = os.path.join(REPO, 'cstrike', 'sound', 'vexmira', 'map')


def _write_loop(path, x, sr):
    """16-bit mono loop with cue point 0 (GoldSrc loops ambient_generic on cue)."""
    x = x - x.mean()
    x = x / (np.abs(x).max() + 1e-9) * 0.72
    pcm = np.clip(np.round(x * 32767), -32767, 32767).astype('<i2').tobytes()
    fmt = struct.pack('<HHIIHH', 1, 1, sr, sr * 2, 2, 16)
    cue = struct.pack('<I', 1) + struct.pack('<II4sIII', 1, 0, b'data', 0, 0, 0)
    body = (b'WAVE' + b'fmt ' + struct.pack('<I', len(fmt)) + fmt + b'cue ' + struct.pack('<I', len(cue)) + cue
            + b'data' + struct.pack('<I', len(pcm)) + pcm)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as fh:
        fh.write(b'RIFF' + struct.pack('<I', len(body)) + body)
    return len(x) / sr


def _cnoise(n, sr, rng, shape):
    """Circular (perfectly periodic) filtered noise: shape(freqs) -> gain."""
    spec = np.fft.rfft(rng.standard_normal(n))
    spec *= shape(np.fft.rfftfreq(n, 1 / sr))
    y = np.fft.irfft(spec, n)
    return y / (np.abs(y).max() + 1e-9)


def _place(x, ev, pos):
    idx = (pos + np.arange(len(ev))) % len(x)
    x[idx] += ev


def _creverb(x, sr, rng, decay=1.2, mix=0.3):
    """Circular reverb (FFT convolution wraps around, so the loop stays seamless)."""
    n = len(x)
    L = min(n, int(sr * decay))
    ir = rng.standard_normal(L) * np.exp(-np.arange(L) / sr * 6.0 / decay)
    h = np.zeros(n)
    h[:L] = ir
    wet = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(h), n)
    wet /= np.abs(wet).max() + 1e-9
    return x * (1 - mix) + wet * mix * np.abs(x).max()


def make_sounds(out=SOUND_DIR):
    import sys as _s
    _s.path.insert(0, os.path.join(REPO, 'devtools', 'sfx'))
    import sfx_lib as fx
    made = []
    # --- cd_wind: gusting wind + far air-raid wail + one far metal clank (6 s, 11025)
    sr, sec = 11025, 6.0
    n = int(sr * sec)
    t = np.arange(n) / sr
    rng = np.random.default_rng(7101)
    f = lambda hz: round(hz * sec) / sec
    wind = _cnoise(n, sr, rng, lambda fr: np.exp(-((fr - 260) / 220) ** 2) + 0.4 * np.exp(-((fr - 700) / 300) ** 2))
    swell = 0.55 + 0.3 * np.sin(2 * np.pi * f(1 / 6) * t) + 0.15 * np.sin(2 * np.pi * f(0.5) * t + 1.3)
    whistle = _cnoise(n, sr, rng, lambda fr: np.exp(-((fr - 1150) / 40) ** 2)) * 0.18 * (0.5 + 0.5 * np.sin(2 * np.pi * f(1 / 3) * t))
    wf = 420 + 120 * np.sin(2 * np.pi * f(1 / 6) * t - np.pi / 2)
    ph = np.cumsum(wf) / sr
    ph *= round(ph[-1]) / ph[-1]
    wail = (np.sin(2 * np.pi * ph) + 0.35 * np.sin(4 * np.pi * ph)) * 0.07
    x = wind * swell + whistle + wail
    L = int(0.9 * sr)
    tt = np.arange(L) / sr
    clank = sum(np.sin(2 * np.pi * fq * tt) * a for fq, a in ((523, 1), (1187, 0.6), (1931, 0.35))) * np.exp(-tt * 6) * 0.12
    _place(x, clank, int(3.7 * sr))
    made.append(('cd_wind.wav', _write_loop(os.path.join(out, 'cd_wind.wav'), _creverb(x, sr, rng, 1.0, 0.25), sr)))
    # --- cd_harbor: water lapping, mooring creak, distant foghorn (6 s, 11025)
    rng = np.random.default_rng(7102)
    water = _cnoise(n, sr, rng, lambda fr: np.exp(-((fr - 550) / 380) ** 2) + 0.3 * np.exp(-((fr - 1800) / 600) ** 2))
    env = np.zeros(n)
    for k in range(9):
        c, w = rng.uniform(0, n), rng.uniform(0.25, 0.6) * sr
        d = np.minimum(np.abs(np.arange(n) - c), n - np.abs(np.arange(n) - c))
        env += np.exp(-(d / w) ** 2) * rng.uniform(0.5, 1.0)
    x = water * (0.2 + env / env.max()) * 0.8
    for k in range(3):
        Lc = int(0.45 * sr)
        tc = np.arange(Lc) / sr
        fq = 140 + 40 * k
        cr = np.sign(np.sin(2 * np.pi * (fq + 30 * np.sin(2 * np.pi * 3 * tc)) * tc)) * np.sin(np.pi * tc / tc[-1]) ** 2
        cr = np.convolve(cr, np.ones(4) / 4, 'same') * 0.06
        _place(x, cr, int(rng.uniform(0, n)))
    Lh = int(2.2 * sr)
    th = np.arange(Lh) / sr
    horn_env = np.minimum(1, th / 0.25) * np.exp(-np.maximum(0, th - 1.6) * 5)
    horn = (np.sin(2 * np.pi * 110 * th) + 0.5 * np.sin(2 * np.pi * 220 * th) + 0.15 * np.sin(2 * np.pi * 330 * th)) * horn_env * 0.16
    _place(x, horn, int(1.2 * sr))
    made.append(('cd_harbor.wav', _write_loop(os.path.join(out, 'cd_harbor.wav'), _creverb(x, sr, rng, 1.4, 0.3), sr)))
    # --- cd_hum: transformer hum 50/100/150 Hz + faint 2.4 kHz buzz (3 s, 11025)
    sec, rng = 3.0, np.random.default_rng(7103)
    n = int(sr * sec)
    t = np.arange(n) / sr
    x = 0.5 * np.sin(2 * np.pi * 100 * t) + 0.35 * np.sin(2 * np.pi * 50 * t) + 0.22 * np.sin(2 * np.pi * 150 * t + 0.7)
    x += 0.08 * np.sin(2 * np.pi * 200 * t) + 0.03 * np.sign(np.sin(2 * np.pi * 2400 * t)) * (0.6 + 0.4 * np.sin(2 * np.pi * 1 * t))
    x *= 0.92 + 0.08 * np.sin(2 * np.pi * (2 / 3) * t)
    x += 0.04 * _cnoise(n, sr, rng, lambda fr: np.exp(-((fr - 3000) / 900) ** 2))
    made.append(('cd_hum.wav', _write_loop(os.path.join(out, 'cd_hum.wav'), x, sr)))
    # --- cd_siren: air-raid siren, one rise + fall per loop, mild drive + space (4 s, 11025)
    sec, rng = 4.0, np.random.default_rng(7104)
    n = int(sr * sec)
    t = np.arange(n) / sr
    prof = 0.5 - 0.5 * np.cos(2 * np.pi * t / sec)
    sf = 330 + 420 * prof ** 0.8
    ph = np.cumsum(sf) / sr
    ph *= round(ph[-1]) / ph[-1]
    x = np.sin(2 * np.pi * ph) + 0.45 * np.sin(4 * np.pi * ph) + 0.2 * np.sin(6 * np.pi * ph)
    x = np.tanh(x * 1.8) * (0.45 + 0.55 * prof)
    made.append(('cd_siren.wav', _write_loop(os.path.join(out, 'cd_siren.wav'), _creverb(x, sr, rng, 1.6, 0.35), sr)))
    # --- cd_rotor: helicopter, 5 Hz blade slap (8 per loop), turbine whine, wash (1.6 s, 11025)
    sec, rng = 1.6, np.random.default_rng(7105)
    n = int(sr * sec)
    t = np.arange(n) / sr
    x = 0.25 * _cnoise(n, sr, rng, lambda fr: np.exp(-((fr - 400) / 500) ** 2))
    Ls = int(0.09 * sr)
    ts = np.arange(Ls) / sr
    slap = (np.sin(2 * np.pi * 70 * ts) * 0.9 + rng.standard_normal(Ls) * 0.5) * np.exp(-ts * 40)
    for k in range(8):
        _place(x, slap, int(k * n / 8))
    x += 0.07 * np.sin(2 * np.pi * 1200 * t) + 0.04 * np.sin(2 * np.pi * 2400 * t + 0.3)
    made.append(('cd_rotor.wav', _write_loop(os.path.join(out, 'cd_rotor.wav'), x, sr)))
    # --- cd_boom: distant heavy impact one-shot (22050, no cue)
    fx.rng = np.random.default_rng(7106)
    b = fx.boom(2.8, 90, 28, 0.55, 1.0)
    cr = fx.crack(0.3, 900, 6000) * 0.5
    deb = fx.lp(fx.noise(2.0, 'pink'), 2500) * fx.env_lin([(0, 0), (0.1, 0.5), (1, 0)], 2.0) * 0.25
    x = fx.mix((b, 0, 1.0), (cr, 0.0, 0.6), (deb, 0.15, 0.8))
    x = fx.reverb(fx.lp(x, 3500), 2.2, 0.35)
    made.append(('cd_boom.wav', fx.write_wav3(os.path.join(out, 'cd_boom.wav'), x, max_len=3.0)))
    # --- cd_jet: launch geyser / pad - pressurised hiss + low rumble, slow pulse (1.2 s loop, 11025)
    sec, rng = 1.2, np.random.default_rng(7107)
    n = int(sr * sec)
    t = np.arange(n) / sr
    x = 0.6 * _cnoise(n, sr, rng, lambda fr: np.exp(-((fr - 2600) / 1800) ** 2))
    x += 0.5 * _cnoise(n, sr, rng, lambda fr: np.exp(-((fr - 90) / 70) ** 2))
    x *= 0.75 + 0.25 * np.sin(2 * np.pi * t / sec * 3)
    made.append(('cd_jet.wav', _write_loop(os.path.join(out, 'cd_jet.wav'), x * 0.8, sr)))
    return made


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--quality', default='normal')
    ap.add_argument('--out', default=os.path.join(REPO, 'cstrike', 'maps'))
    ap.add_argument('--preview', default=None)
    ap.add_argument('--mock', action='store_true', help='add mock detail at the spec face budgets (perf test)')
    ap.add_argument('--mock-scale', type=float, default=1.0, help='mock density as a fraction of the budgets')
    ap.add_argument('--dry', action='store_true')
    ap.add_argument('--sounds', action='store_true', help='(re)synthesise the map sounds into cstrike/sound/vexmira/map')
    a = ap.parse_args(argv)
    if a.sounds:
        for nm, sec in make_sounds():
            print(f'  sound {nm}: {sec:.2f} s')
    m = build(mock=a.mock, mock_scale=a.mock_scale)
    probs = m.spawn_problems()
    print('pre-compile spawn check:', probs or 'OK', m.stats())
    if a.dry:
        return 0 if not probs else 1
    from ..compile import compile_map
    r = compile_map(m, a.quality, None if a.mock else a.out)
    print(r.summary())
    if r.bsp and os.path.exists(r.bsp):
        from ..bspcheck import perf_at
        try:
            for (label, p), res in zip(CHECKPOINTS, perf_at(r.bsp, [pt for _, pt in CHECKPOINTS])):
                print(f"  at {label:10s} {p}: view max {res['view_max']} (yaw {res['view_yaw']:.0f}), "
                      f"PVS {res['pvs_total']}, leaves {res['visible_leaves']}, {res['contents']}")
        except Exception as ex:   # perf_at output format is informative only
            print('  (perf_at:', ex, ')')
    if r.ok and a.preview:
        from ..preview import render_views
        for p in render_views(r.bsp, a.preview, 1100, eyes=EYES):
            print(p)
    return 0 if r.ok else 1


if __name__ == '__main__':
    sys.exit(main())
