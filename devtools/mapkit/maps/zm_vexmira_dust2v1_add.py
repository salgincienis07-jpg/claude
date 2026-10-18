"""Zombie-plague additions for zm_vexmira_dust2v1 (v2).

  * boss plaza: the rock field right of the CT -> B road is removed (world brushes clipped) and replaced by a
    paved battle square with a statue, braziers, colonnade, a raised defense terrace and laser zones
  * 2-floor forts: ground room split by an inner wall + door, ladder through a hatch to a glass defense room
  * depot, glass-booth watch towers, crate forts, zombie banners / warning plates / blood
  * doors are func_door "netname vxbd": humans open/close them with E, zombies smash them (vexmira_core)

Every structure is placed by a small solver against the plain dust2 BSP (stage 1, D2_BASE_BSP): the footprint
must be flat floor with the full height free and must not touch another addition. Decoration that does not seal
anything goes into one func_detail (no vis splits, cheap) - FPS stays at the dust2 level.
"""
from __future__ import annotations

import math
import os

from ..mapwriter import NULL, Brush, Entity, door, glass, breakable, ladder, light, masked_entity, prism, stairs, env_sprite
from ..rmf import Ent, clip_outside_box, solid_bbox

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
NAME = 'zm_vexmira_dust2v1'
INI = os.path.join(REPO, 'cstrike', 'addons', 'amxmodx', 'configs', 'vexmira_maps', NAME + '.ini')
BASE_BSP = os.environ.get('D2_BASE_BSP', '')

WALL, WALL2, TRIM, CC, PLANK, METAL = 'd2_wall', 'd2_wall2', 'd2_trim', 'd2_ccrete', 'd2_plank', 'd2_metal'
CRATE, CTOP, CRS, MIL, MILT = 'd2_crate', 'd2_cratetop', 'd2_crate_s', 'd2_mil', 'd2_miltop'
STONE, PAVE, MARBLE = 'vx_stone_carved', 'vx_temple_flr', 'vx_marble'
GLASS = 'vx_glass'
LAMP = '~vx_light_y'

# boss plaza box (rock field between the CT -> B road and the north edge)
PX0, PY0, PX1, PY1 = -1104, 1072, -112, 1968
ZPL = -288          # plaza floor
ZTE = -160          # west defense terrace
TEX = -656          # terrace east edge
ZSKY = 352          # dust2 sky lid bottom

_b = None
PLACED = []          # (name, x0, y0, x1, y1, z, label)
OCC = []
LOG = []
DET = []             # func_detail brushes
MASKED = []          # '{' visuals (ladders, blood) -> one func_illusionary
MODELS = []
MARKS = []


def bsp():
    global _b
    if _b is None:
        from ..bspcheck import BSP
        _b = BSP(BASE_BSP)
    return _b


def empty(x, y, z, hull=0):
    return bsp().point_contents((x, y, z), hull=hull) == -1


def floor_at(x, y, ztop=340, zmin=-600):
    prev = None
    for z in range(ztop, zmin, -4):
        e = empty(x, y, z, 1)
        if prev and not e:
            return z + 4 - 36
        prev = e
    return None


def in_plaza(x0, y0, x1, y1, m=32):
    return x0 < PX1 + m and x1 > PX0 - m and y0 < PY1 + m and y1 > PY0 - m


def area_ok(x0, y0, x1, y1, z, h, step=24):
    if in_plaza(x0, y0, x1, y1):
        return False
    xs = [x0 + 2 + i * step for i in range(int((x1 - x0 - 4) // step) + 1)] + [x1 - 2]
    ys = [y0 + 2 + i * step for i in range(int((y1 - y0 - 4) // step) + 1)] + [y1 - 2]
    for x in xs:
        for y in ys:
            if empty(x, y, z - 6):
                return False
            for zz in range(int(z + 4), int(z + h), 24):
                if not empty(x, y, zz):
                    return False
            if not empty(x, y, z + h - 2):
                return False
    return True


def free_of_others(x0, y0, x1, y1, margin=48):
    for a, b, c, d in OCC:
        if x0 < c + margin and x1 > a - margin and y0 < d + margin and y1 > b - margin:
            return False
    return True


def place(name, cx, cy, w, d, h, search=640, step=32, rot_ok=True, label=None):
    cands = [(0, 0)]
    for r in range(step, search + 1, step):
        n = max(8, int(2 * math.pi * r / step))
        cands += [(round(r * math.cos(2 * math.pi * k / n)), round(r * math.sin(2 * math.pi * k / n))) for k in range(n)]
    for dx, dy in cands:
        for rot in ((False, True) if rot_ok else (False,)):
            ww, dd = (d, w) if rot else (w, d)
            x, y = cx + dx, cy + dy
            x0, y0 = int(x - ww / 2) // 8 * 8, int(y - dd / 2) // 8 * 8
            x1, y1 = x0 + ww, y0 + dd
            if not free_of_others(x0, y0, x1, y1):
                continue
            z = floor_at(x, y)
            if z is None:
                continue
            z = round(z)
            if area_ok(x0, y0, x1, y1, z, h):
                PLACED.append((name, x0, y0, x1, y1, z, label))
                OCC.append((x0, y0, x1, y1))
                LOG.append('%-12s at (%d %d)-(%d %d) z %d%s (asked %d %d)' % (name, x0, y0, x1, y1, z, ' rot' if rot else '', cx, cy))
                return x0, y0, x1, y1, z, rot
    LOG.append('%-12s NOT PLACED near %d %d' % (name, cx, cy))
    return None


# ---------------------------------------------------------------- geometry helpers
def bx(mins, maxs, tex):
    return Brush.box(mins, maxs, tex)


def side_len(side, x0, y0, x1, y1):
    return (x1 - x0) if side in 'ns' else (y1 - y0)


def opp(side):
    return {'n': 's', 's': 'n', 'e': 'w', 'w': 'e'}[side]


def walls_with_openings(x0, y0, x1, y1, z, h, t, tex, openings):
    """four walls (thickness t, inside the rectangle); openings: (side, a, b, z0, z1), a..b measured from x0
    (n/s sides) or y0 (e/w sides)."""
    out = []
    sides = {
        's': ((x0, y0), (x1, y0 + t), 'x'), 'n': ((x0, y1 - t), (x1, y1), 'x'),
        'w': ((x0, y0 + t), (x0 + t, y1 - t), 'y'), 'e': ((x1 - t, y0 + t), (x1, y1 - t), 'y'),
    }
    for s, ((ax, ay), (bxx, by), axis) in sides.items():
        ops = sorted([o for o in openings if o[0] == s], key=lambda o: o[1])
        base = x0 if axis == 'x' else y0
        lo = ax if axis == 'x' else ay
        hi = bxx if axis == 'x' else by
        cuts = [lo]
        for o in ops:
            cuts += [base + o[1], base + o[2]]
        cuts.append(hi)

        def seg(a, b, za, zb):
            if b - a < 1 or zb - za < 1:
                return
            if axis == 'x':
                out.append(bx((a, ay, za), (b, by, zb), tex))
            else:
                out.append(bx((ax, a, za), (bxx, b, zb), tex))
        for i in range(0, len(cuts), 2):
            seg(cuts[i], cuts[i + 1], z, z + h)
        for o in ops:
            seg(base + o[1], base + o[2], z, z + o[3])
            seg(base + o[1], base + o[2], z + o[4], z + h)
    return out


def slab_in(side, x0, y0, x1, y1, a, b, za, zb, tex, th, inset=0):
    """slab of thickness th lying against the inside of `side`, offset `inset` from the outer face."""
    if side == 's':
        return bx((x0 + a, y0 + inset, za), (x0 + b, y0 + inset + th, zb), tex)
    if side == 'n':
        return bx((x0 + a, y1 - inset - th, za), (x0 + b, y1 - inset, zb), tex)
    if side == 'w':
        return bx((x0 + inset, y0 + a, za), (x0 + inset + th, y0 + b, zb), tex)
    return bx((x1 - inset - th, y0 + a, za), (x1 - inset, y0 + b, zb), tex)


def sign_on(side, x0, y0, x1, y1, a, b, za, zb, tex, out=2):
    """flat sign on the OUTSIDE of a wall face, texture fitted once across it."""
    if side == 's':
        br = bx((x0 + a, y0 - out, za), (x0 + b, y0, zb), {'s': tex, 'all': NULL})
    elif side == 'n':
        br = bx((x0 + a, y1, za), (x0 + b, y1 + out, zb), {'n': tex, 'all': NULL})
    elif side == 'w':
        br = bx((x0 - out, y0 + a, za), (x0, y0 + b, zb), {'w': tex, 'all': NULL})
    else:
        br = bx((x1, y0 + a, za), (x1 + out, y0 + b, zb), {'e': tex, 'all': NULL})
    br.fit_faces((side,))
    return br


def blood_on(side, x0, y0, x1, y1, a, za, s=96):
    MASKED.append(sign_on(side, x0, y0, x1, y1, a, a + s, za, za + s, '{d2_blood', out=1))


def ladder_at(side, x0, y0, x1, y1, a, z, h, inside=False, t=16):
    """ladder against `side` at span position a. outside: on the outer face; inside: on the inner face."""
    if not inside:
        f = {'s': ((x0 + a, y0, z), '+y'), 'n': ((x0 + a, y1, z), '-y'),
             'w': ((x0, y0 + a, z), '+x'), 'e': ((x1, y0 + a, z), '-x')}[side]
    else:
        f = {'s': ((x0 + a, y0 + t, z), '-y'), 'n': ((x0 + a, y1 - t, z), '+y'),
             'w': ((x0 + t, y0 + a, z), '-x'), 'e': ((x1 - t, y0 + a, z), '+x')}[side]
    lad, vis = ladder(f[0], f[1], h)
    MASKED.extend(vis)
    return lad


def bdoor(brushes, name, direction='up', speed=150):
    """breakable camp door: E opens / closes it, zombies smash it (vexmira_core looks for netname vxbd)."""
    e = door(brushes, direction=direction, speed=speed, wait=-1, lip=8, sounds=1, toggle=True, use_only=True)
    e['netname'] = 'vxbd'
    e['message'] = name
    return e


def lamp(x, y, z, bright=150, col=(255, 214, 160)):
    DET.append(bx((x - 12, y - 12, z - 6), (x + 12, y + 12, z), LAMP))
    return light((x, y, z - 18), col, bright)


# ---------------------------------------------------------------- forts
def fort(name, cx, cy, w=320, d=256, h1=128, front='s', label='d2_s_kale'):
    """2-floor camp fort.
    ground: front steel door (vxbd), laser vestibule in front of it, 2 glass windows per side wall, inner
    partition with a plank door (vxbd) -> back room with a ladder through a hatch.
    upstairs: glass defense room (parapet + glass panels all around, steel corner posts, roof)."""
    VEST = 112
    pl = place(name, cx, cy, w, d + VEST if front in 'ns' else d, h1 + 12 + 132, label=label) if front in 'ns' else \
        place(name, cx, cy, w + VEST, d, h1 + 12 + 132, label=label)
    if not pl:
        return [], []
    X0, Y0, X1, Y1, z, rot = pl
    if rot:
        front = {'n': 'e', 's': 'w', 'e': 'n', 'w': 's'}[front]
    # shrink: the vestibule (laser zone) is in front of the fort
    x0, y0, x1, y1 = X0, Y0, X1, Y1
    vest = None
    if front == 's':
        y0 += VEST; vest = (X0, Y0, X1, y0)
    elif front == 'n':
        y1 -= VEST; vest = (X0, y1, X1, Y1)
    elif front == 'w':
        x0 += VEST; vest = (X0, Y0, x0, Y1)
    else:
        x1 -= VEST; vest = (x1, Y0, X1, Y1)
    t = 16
    world, ents = [], []
    L = side_len(front, x0, y0, x1, y1)
    dw, da = 64, L / 2 - 32
    back = opp(front)
    lr = [s for s in 'nsew' if s not in (front, back)]
    ops = [(front, da, da + dw, 0, 112)]
    wins = []
    for s in lr:
        Ls = side_len(s, x0, y0, x1, y1)
        for a in (Ls * 0.25, Ls * 0.75):
            o = (s, a - 28, a + 28, 52, 100)
            ops.append(o); wins.append(o)
    world += walls_with_openings(x0, y0, x1, y1, z, h1, t, WALL2, ops)
    # inner partition across the middle with a doorway (plank door)
    D = side_len(lr[0], x0, y0, x1, y1)          # depth front -> back
    mid = D / 2
    pw = 56
    if front in 'ns':
        py = (y0 + mid) if front == 's' else (y1 - mid)
        pa = (x1 - x0) * 0.30
        world.append(bx((x0 + t, py - 8, z), (x0 + pa - pw / 2, py + 8, z + h1), WALL))
        world.append(bx((x0 + pa + pw / 2, py - 8, z), (x1 - t, py + 8, z + h1), WALL))
        world.append(bx((x0 + pa - pw / 2, py - 8, z + 104), (x0 + pa + pw / 2, py + 8, z + h1), WALL))
        inner = bx((x0 + pa - pw / 2, py - 4, z), (x0 + pa + pw / 2, py + 4, z + 104), PLANK)
    else:
        px = (x0 + mid) if front == 'w' else (x1 - mid)
        pa = (y1 - y0) * 0.30
        world.append(bx((px - 8, y0 + t, z), (px + 8, y0 + pa - pw / 2, z + h1), WALL))
        world.append(bx((px - 8, y0 + pa + pw / 2, z), (px + 8, y1 - t, z + h1), WALL))
        world.append(bx((px - 8, y0 + pa - pw / 2, z + 104), (px + 8, y0 + pa + pw / 2, z + h1), WALL))
        inner = bx((px - 4, y0 + pa - pw / 2, z), (px + 4, y0 + pa + pw / 2, z + 104), PLANK)
    ents.append(bdoor([inner], name + '_b'))
    # ceiling with a 48x48 hatch in the back room, far corner (opposite side of the partition doorway)
    zc = z + h1
    Lb = side_len(back, x0, y0, x1, y1)
    ha = Lb - t - 24 - 48                              # hatch span along the back wall
    hd = t                                             # hatch touches the back wall (ladder below it)
    if back == 'n':
        hx0, hy0 = x0 + ha, y1 - hd - 48
    elif back == 's':
        hx0, hy0 = x0 + ha, y0 + hd
    elif back == 'e':
        hx0, hy0 = x1 - hd - 48, y0 + ha
    else:
        hx0, hy0 = x0 + hd, y0 + ha
    hx1, hy1 = hx0 + 48, hy0 + 48
    ct = {'top': CC, 'bottom': CC, 'all': TRIM}
    for a in ((x0, y0, hx0, y1), (hx1, y0, x1, y1), (hx0, y0, hx1, hy0), (hx0, hy1, hx1, y1)):
        if a[2] - a[0] >= 1 and a[3] - a[1] >= 1:
            world.append(bx((a[0], a[1], zc), (a[2], a[3], zc + 12), ct))
    ents.append(ladder_at(back, x0, y0, x1, y1, ha + 24, z, h1 + 12 + 24, inside=True))
    # upstairs glass defense room
    z2 = zc + 12
    for s in 'nsew':
        Ls = side_len(s, x0, y0, x1, y1)
        world.append(slab_in(s, x0, y0, x1, y1, 0, Ls, z2, z2 + 40, TRIM, 12))
        world.append(slab_in(s, x0, y0, x1, y1, 0, Ls, z2 + 104, z2 + 112, TRIM, 12))
    for xa, ya in ((x0, y0), (x1 - 16, y0), (x0, y1 - 16), (x1 - 16, y1 - 16)):
        world.append(bx((xa, ya, z2 + 40), (xa + 16, ya + 16, z2 + 104), METAL))
    world.append(bx((x0 - 8, y0 - 8, z2 + 112), (x1 + 8, y1 + 8, z2 + 124), {'top': CC, 'bottom': CC, 'all': TRIM}))
    panes = []
    for s in 'nsew':
        Ls = side_len(s, x0, y0, x1, y1)
        panes.append(slab_in(s, x0, y0, x1, y1, 16, Ls - 16, z2 + 40, z2 + 104, GLASS, 4, inset=4))
    ents.append(glass(panes, health=250, renderamt=110))
    # ground glass windows
    gp = []
    for o in wins:
        gp.append(slab_in(o[0], x0, y0, x1, y1, o[1], o[2], z + o[3], z + o[4], GLASS, 4, inset=6))
    ents.append(glass(gp, health=90))
    # front steel door
    fd = slab_in(front, x0, y0, x1, y1, da, da + dw, z, z + 112, METAL, 8, inset=4)
    ents.append(bdoor([fd], name + '_a'))
    # laser vestibule: two side walls in front of the door
    vx0, vy0, vx1, vy1 = vest
    if front in 'ns':
        for xa in (x0 + da - 72, x0 + da + dw + 56):
            world.append(bx((xa, vy0, z), (xa + 16, vy1, z + 112), {'top': TRIM, 'all': WALL}))
    else:
        for ya in (y0 + da - 72, y0 + da + dw + 56):
            world.append(bx((vx0, ya, z), (vx1, ya + 16, z + 112), {'top': TRIM, 'all': WALL}))
    MARKS.append(('Laser zone | Lazer bolgesi', (vx0 + vx1) // 2, (vy0 + vy1) // 2, z + 160))
    # signs
    DET.append(sign_on(front, x0, y0, x1, y1, L / 2 - 64, L / 2 + 64, z + 116, z + 132, label, out=4))
    if L >= 288:
        DET.append(sign_on(front, x0, y0, x1, y1, 16, 80, z + 8, z + 104, 'd2_ban_bio', out=3))
        DET.append(sign_on(front, x0, y0, x1, y1, L - 80, L - 16, z + 8, z + 104, 'd2_ban_zm', out=3))
    big = max(lr, key=lambda s: side_len(s, x0, y0, x1, y1))
    Lg = side_len(big, x0, y0, x1, y1)
    DET.append(sign_on(big, x0, y0, x1, y1, Lg / 2 - 48, Lg / 2 + 48, z + 8, z + 104, 'd2_warn', out=3))
    other = [s for s in lr if s != big][0]
    Lo = side_len(other, x0, y0, x1, y1)
    blood_on(other, x0, y0, x1, y1, Lo / 2 - 48, z + 4)
    blood_on(back, x0, y0, x1, y1, 24, z + 20)
    # lights
    fy = (y0 + y1) / 2
    fx = (x0 + x1) / 2
    ents.append(lamp(fx, fy, zc))
    ents.append(lamp(fx, fy, z2 + 112, 110))
    PLACED[-1] = (name, x0, y0, x1, y1, z, label)
    return world, ents


def depot(name, cx, cy):
    """warehouse: south steel door (vxbd) + west plank barricade (breakable), glass windows, crate loft,
    walkable roof with a parapet and an outside ladder."""
    w, d, h = 384, 256, 176
    VEST = 112
    pl = place(name, cx, cy, w, d + VEST, h + 72, rot_ok=False, label='d2_s_depo')
    if not pl:
        return [], []
    x0, Y0, x1, y1, z, _ = pl
    y0 = Y0 + VEST
    t = 16
    L = x1 - x0
    da = L / 2 - 32
    ops = [('s', da, da + 64, 0, 112), ('w', d / 2 - 32, d / 2 + 32, 0, 112)]
    wins = [('e', d * 0.3 - 28, d * 0.3 + 28, 56, 104), ('e', d * 0.7 - 28, d * 0.7 + 28, 56, 104),
            ('n', L * 0.25 - 28, L * 0.25 + 28, 56, 104), ('n', L * 0.75 - 28, L * 0.75 + 28, 56, 104)]
    world = walls_with_openings(x0, y0, x1, y1, z, h, t, WALL2, ops + wins)
    world.append(bx((x0, y0, z + h), (x1, y1, z + h + 12), {'top': CC, 'bottom': CC, 'all': TRIM}))
    ents = []
    pz = z + h + 12
    gap = (d / 2 - 24, d / 2 + 24)
    for s in 'nsew':
        Ls = side_len(s, x0, y0, x1, y1)
        spans = [(0, Ls)] if s != 'e' else [(0, gap[0]), (gap[1], Ls)]
        for a, b in spans:
            DET.append(slab_in(s, x0, y0, x1, y1, a, b, pz, pz + 40, TRIM, 8))
    ents.append(ladder_at('e', x0, y0, x1, y1, d / 2, z, h + 12 + 8))
    ents.append(glass([slab_in(o[0], x0, y0, x1, y1, o[1], o[2], z + o[3], z + o[4], GLASS, 4, inset=6) for o in wins], health=90))
    ents.append(bdoor([slab_in('s', x0, y0, x1, y1, da, da + 64, z, z + 112, METAL, 8, inset=4)], name + '_a'))
    ents.append(breakable([slab_in('w', x0, y0, x1, y1, d / 2 - 32, d / 2 + 32, z, z + 112, PLANK, 8, inset=4)],
                          material=1, health=900))
    for xa in (x0 + da - 72, x0 + da + 64 + 56):
        world.append(bx((xa, Y0, z), (xa + 16, y0, z + 112), {'top': TRIM, 'all': WALL}))
    MARKS.append(('Laser zone | Lazer bolgesi', (x0 + x1) // 2, (Y0 + y0) // 2, z + 160))
    # crate loft along the north wall
    for x in range(x0 + 32, x1 - 96, 96):
        b = bx((x, y1 - 112, z), (x + 64, y1 - 48, z + 64), {'all': CRATE, 'top': CTOP})
        b.fit_faces(('n', 's', 'e', 'w', 'top'))
        DET.append(b)
    DET.append(bx((x1 - 96, y1 - 112, z), (x1 - 32, y1 - 48, z + 32), {'all': CRS}))
    DET.append(sign_on('s', x0, y0, x1, y1, L / 2 - 64, L / 2 + 64, z + 120, z + 136, 'd2_s_depo', out=4))
    DET.append(sign_on('s', x0, y0, x1, y1, 16, 80, z + 16, z + 112, 'd2_ban_zm', out=3))
    DET.append(sign_on('s', x0, y0, x1, y1, L - 80, L - 16, z + 16, z + 112, 'd2_ban_bio', out=3))
    DET.append(sign_on('n', x0, y0, x1, y1, L / 2 - 64, L / 2 + 64, z + 112, z + 176, 'd2_sign', out=3))
    blood_on('e', x0, y0, x1, y1, 16, z + 8)
    blood_on('w', x0, y0, x1, y1, d - 112, z + 24)
    ents.append(lamp((x0 + x1) / 2, (y0 + y1) / 2, z + h))
    PLACED[-1] = (name, x0, y0, x1, y1, z, 'd2_s_depo')
    return world, ents


def tower(name, cx, cy, size=160, ph=208):
    """watch tower: plank posts, platform with a hatch + inside ladder, plank parapet, breakable glass booth."""
    pl = place(name, cx, cy, size, size, ph + 128, label='d2_s_kule')
    if not pl:
        return [], []
    x0, y0, x1, y1, z, _ = pl
    world, ents = [], []
    p = 16
    for xa, ya in ((x0, y0), (x1 - p, y0), (x0, y1 - p), (x1 - p, y1 - p)):
        DET.append(bx((xa, ya, z), (xa + p, ya + p, z + ph + 112), PLANK))
    pz = z + ph
    L = size
    hx0, hy0 = x0 + L / 2 - 24, y0 + p
    world.append(bx((x0, y0, pz - 8), (hx0, y1, pz), PLANK))
    world.append(bx((hx0 + 48, y0, pz - 8), (x1, y1, pz), PLANK))
    world.append(bx((hx0, hy0 + 48, pz - 8), (hx0 + 48, y1, pz), PLANK))
    world.append(bx((hx0, y0, pz - 8), (hx0 + 48, hy0, pz), PLANK))
    # ladder in the open under the hatch, against a plank backboard
    world.append(bx((hx0, y0, z), (hx0 + 48, y0 + p, pz - 8), PLANK))
    ents.append(ladder_at('s', x0, y0, x1, y1, L / 2, z, ph + 8, inside=True, t=p))
    for s in 'nsew':
        DET.append(slab_in(s, x0, y0, x1, y1, 0, L, pz, pz + 40, PLANK, 6))
    ents.append(glass([slab_in(s, x0, y0, x1, y1, p, L - p, pz + 40, pz + 104, GLASS, 4, inset=1) for s in 'nsew'],
                      health=220, renderamt=110))
    DET.append(bx((x0 - 8, y0 - 8, pz + 112), (x1 + 8, y1 + 8, pz + 120), PLANK))
    DET.append(sign_on('n', x0, y0, x1, y1, L / 2 - 64, L / 2 + 64, pz + 8, pz + 24, 'd2_s_kule', out=8))
    DET.append(sign_on('e', x0, y0, x1, y1, L / 2 - 32, L / 2 + 32, z + 48, z + 176, 'd2_ban_bio', out=2))
    ents.append(light(((x0 + x1) / 2, (y0 + y1) / 2, pz + 96), (255, 210, 150), 90))
    return world, ents


def crate_fort(name, cx, cy):
    """U-shaped crate stack (hiding nook) with a 2-high back wall, climbable from a step crate."""
    pl = place(name, cx, cy, 256, 192, 200)
    if not pl:
        return [], []
    x0, y0, x1, y1, z, rot = pl

    def cr(x, y, s, zz, tex=CRATE, top=CTOP):
        b = Brush.box((x, y, zz), (x + s, y + s, zz + s), {'top': top, 'bottom': top, 'all': tex})
        b.fit_faces(('n', 's', 'e', 'w', 'top'))
        DET.append(b)
    if not rot:
        for i in range(0, 256, 64):
            cr(x0 + i, y1 - 64, 64, z, CRS, CRS)
            cr(x0 + i, y1 - 64, 64, z + 64, MIL, MILT)
        cr(x0, y0, 96, z)
        cr(x1 - 96, y0, 96, z)
        cr(x1 - 96, y0 + 96, 64, z, CRS, CRS)
    else:
        for i in range(0, 256, 64):
            cr(x1 - 64, y0 + i, 64, z, CRS, CRS)
            cr(x1 - 64, y0 + i, 64, z + 64, MIL, MILT)
        cr(x0, y0, 96, z)
        cr(x0, y1 - 96, 96, z)
        cr(x0 + 96, y1 - 96, 64, z, CRS, CRS)
    return [], []


# ---------------------------------------------------------------- boss plaza
def plaza():
    world, ents = [], []
    # floors: paved square + west defense terrace (raised)
    world.append(bx((TEX, PY0, -416), (PX1, PY1, ZPL), {'top': PAVE, 'all': TRIM}))
    world.append(bx((PX0, PY0, -416), (TEX, PY1, ZTE), {'top': CC, 'all': TRIM}))
    # perimeter walls up to the sky lid (seal the plaza)
    W = {'all': WALL}
    world.append(bx((PX0 - 16, PY1, -416), (PX1 + 16, PY1 + 16, ZSKY), W))
    world.append(bx((PX1, PY0, -416), (PX1 + 16, PY1, ZSKY), W))
    world.append(bx((PX0 - 16, PY0 + 96, -416), (PX0, PY1, ZSKY), W))
    # trim courses on the walls
    for zt in (ZPL + 160, ZPL + 320):
        DET.append(bx((PX0, PY1 - 8, zt), (PX1, PY1, zt + 16), TRIM))
        DET.append(bx((PX1 - 8, PY0, zt), (PX1, PY1 - 8, zt + 16), TRIM))
    # terrace stairs (one wide flight down to the square)
    sy0, sy1 = 1760, 1888
    world += stairs((TEX + 256, (sy0 + sy1) / 2, ZPL), '-x', sy1 - sy0, ZTE - ZPL, rise=8, run=16,
                    tex={'top': STONE, 'all': TRIM})
    # terrace parapets (waist high, gaps at the stairs and at the south road end)
    for a, b in ((PY0 + 128, sy0), (sy1, PY1)):
        DET.append(bx((TEX - 16, a, ZTE), (TEX, b, ZTE + 40), {'top': STONE, 'all': TRIM}))
    DET.append(bx((PX0 + 112, PY0, ZTE), (TEX, PY0 + 16, ZTE + 40), {'top': STONE, 'all': TRIM}))
    MARKS.append(('Defense terrace | Savunma terasi', (PX0 + TEX) // 2, (PY0 + PY1) // 2, ZTE + 200))
    MARKS.append(('Laser zone | Lazer bolgesi', (PX0 + TEX) // 2, PY0 + 64, ZTE + 120))
    MARKS.append(('Laser zone | Lazer bolgesi', TEX - 64, (sy0 + sy1) // 2, ZTE + 120))
    # statue on a 3-tier plinth
    cx, cy = (TEX + PX1) // 2, 1420
    ztop = ZPL
    for hs, tex, hh in ((128, STONE, 48), (96, STONE, 48), (64, MARBLE, 48)):
        world.append(bx((cx - hs, cy - hs, ztop), (cx + hs, cy + hs, ztop + hh), {'top': tex, 'all': tex}))
        ztop += hh
    MODELS.append('model = models/vexmira/world/cd_statue.mdl %d %d %d 270' % (cx, cy, ztop))
    MARKS.append(('Boss arena | Boss arenasi', cx, cy, ztop + 240))
    # braziers at the 4 plinth corners
    for dx, dy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        bxp, byp = cx + dx * 200, cy + dy * 200
        DET.extend(prism((bxp, byp), 14, 8, ZPL, ZPL + 56, STONE))
        DET.append(bx((bxp - 20, byp - 20, ZPL + 56), (bxp + 20, byp + 20, ZPL + 64), METAL))
        ents.append(env_sprite((bxp, byp, ZPL + 88), 'sprites/vexmira/fire.spr', 0.55, (255, 255, 255), 255, 5, 12))
        ents.append(light((bxp, byp, ZPL + 112), (255, 150, 70), 160))
    # colonnade along the north wall with banners between the columns
    k = 0
    for x in range(TEX + 64, PX1 - 32, 128):
        DET.extend(prism((x, PY1 - 40), 18, 8, ZPL, ZPL + 288, STONE))
        DET.append(bx((x - 26, PY1 - 66, ZPL + 288), (x + 26, PY1 - 14, ZPL + 304), MARBLE))
        if x + 128 < PX1 - 32:
            tex = 'd2_ban_bio' if k % 2 == 0 else 'd2_ban_zm'
            b = bx((x + 32, PY1 - 2, ZPL + 112), (x + 96, PY1, ZPL + 240), {'s': tex, 'all': NULL})
            b.fit_faces(('s',))
            DET.append(b)
            k += 1
    # big signs: east wall (arena + VEXMIRA) and west terrace wall
    def wsign(x, y0w, y1w, za, zb, tex, face):
        b = bx((x - 2, y0w, za), (x, y1w, zb), {face: tex, 'all': NULL}) if face == 'w' else \
            bx((x, y0w, za), (x + 2, y1w, zb), {face: tex, 'all': NULL})
        b.fit_faces((face,))
        DET.append(b)
    wsign(PX1, 1300, 1556, ZPL + 120, ZPL + 248, 'd2_sign', 'w')
    wsign(PX1, 1300, 1556, ZPL + 256, ZPL + 288, 'd2_s_arena', 'w')
    wsign(PX0, 1300, 1556, ZTE + 112, ZTE + 240, 'd2_sign', 'e')
    b = bx((PX0, 1600, ZTE + 16), (PX0 + 2, 1728, ZTE + 144), {'e': 'd2_warn', 'all': NULL})
    b.fit_faces(('e',)); DET.append(b)
    b = bx((PX0, 1100 + 96, ZTE + 72), (PX0 + 2, 1452 - 96, ZTE + 104), {'e': 'd2_s_laser', 'all': NULL})
    b.fit_faces(('e',)); DET.append(b)
    for xx, yy in ((PX1 - 2, 1180), (PX1 - 2, 1700)):
        b = bx((xx, yy, ZPL + 8), (xx + 1, yy + 96, ZPL + 104), {'w': '{d2_blood', 'all': NULL})
        b.fit_faces(('w',)); MASKED.append(b)
    # cover on the square: low walls + crates (boss fight dodging)
    for x0c, y0c, x1c, y1c in ((TEX + 96, 1180, TEX + 224, 1196), (PX1 - 224, 1180, PX1 - 96, 1196),
                               (TEX + 96, 1660, TEX + 224, 1676), (PX1 - 224, 1660, PX1 - 96, 1676)):
        DET.append(bx((x0c, y0c, ZPL), (x1c, y1c, ZPL + 48), {'top': STONE, 'all': WALL}))
    for x, y in ((PX1 - 140, 1830), (TEX + 80, 1250)):
        b = bx((x, y, ZPL), (x + 64, y + 64, ZPL + 64), {'all': CRATE, 'top': CTOP})
        b.fit_faces(('n', 's', 'e', 'w', 'top')); DET.append(b)
    # lights
    for x, y, zz, br in ((cx, cy - 300, ZPL + 260, 220), (cx, cy + 320, ZPL + 260, 200), ((PX0 + TEX) / 2, 1300, ZTE + 200, 170),
                         ((PX0 + TEX) / 2, 1750, ZTE + 200, 170)):
        ents.append(light((x, y, zz), (255, 205, 150), br))
    PLACED.append(('plaza', PX0, PY0, PX1, PY1, ZPL, 'd2_s_arena'))
    OCC.append((PX0, PY0, PX1, PY1))
    return world, ents


# ---------------------------------------------------------------- dust2 cleanup
def prepare(m):
    """merge dust2's lamp func_illusionarys + crate func_breakables (saves ~33 brush models), clip the rock
    field out of the plaza box, drop point entities inside the box."""
    lamps = [e for e in m.ents if e.classname == 'func_illusionary']
    crates = [e for e in m.ents if e.classname == 'func_breakable']
    m.ents = [e for e in m.ents if e not in lamps and e not in crates]
    if lamps:
        one = Ent()
        one.classname = 'func_illusionary'
        one.keys = [('rendermode', '0'), ('renderamt', '255'), ('rendercolor', '0 0 0'), ('skin', '-1')]
        for e in lamps:
            one.solids += e.solids
        m.ents.append(one)
    for e in crates:
        m.world_solids += e.solids
    keep, clipped, pieces = [], 0, 0
    for s in m.world_solids:
        a, b = solid_bbox(s)
        if a[0] < PX1 and b[0] > PX0 and a[1] < PY1 and b[1] > PY0 and a[2] < ZSKY - 8:
            ps = clip_outside_box(s, PX0, PY0, PX1, PY1)
            clipped += 1
            pieces += len(ps)
            keep += ps
        else:
            keep.append(s)
    m.world_solids = keep
    before = len(m.ents)
    m.ents = [e for e in m.ents if e.solids or not (PX0 < e.origin[0] < PX1 and PY0 < e.origin[1] < PY1)]
    print('  [d2 prep] lamps merged %d -> 1, crates -> world %d, plaza clip %d brushes -> %d pieces, point ents dropped %d'
          % (len(lamps), len(crates), clipped, pieces, before - len(m.ents)))


# ---------------------------------------------------------------- spawns
def spawns(team, areas, need, taken=()):
    cls = 'info_player_start' if team == 'ct' else 'info_player_deathmatch'
    out, pts = [], []
    blocked = [(a, b) for a, b in taken]
    for cx, cy, rad, yaw in areas:
        zc = floor_at(cx, cy)
        for gx in range(-rad, rad + 1, 72):
            for gy in range(-rad, rad + 1, 72):
                if len(pts) >= need:
                    break
                x, y = cx + gx, cy + gy
                if any((x - a) ** 2 + (y - b) ** 2 < 72 ** 2 for a, b, _ in pts) or \
                        any((x - a) ** 2 + (y - b) ** 2 < 72 ** 2 for a, b in blocked):
                    continue
                if any(a - 40 < x < c + 40 and b - 40 < y < d + 40 for a, b, c, d in OCC):
                    continue
                z = floor_at(x, y, int(zc) + 96)        # stay on the area's ground (no wall tops)
                if z is None or abs(z - zc) > 64:
                    continue
                o = z + 36
                if all(empty(x + dx, y + dy, o + dz, 1) for dx in (-20, 20) for dy in (-20, 20) for dz in (0, 20)):
                    pts.append((x, y, o + 1))
                    out.append('{\n"classname" "%s"\n"origin" "%d %d %d"\n"angles" "0 %d 0"\n}' % (cls, x, y, o + 1, yaw))
    return out, pts


# ---------------------------------------------------------------- main hook
def additions(m):
    global _b
    _b = None
    for l in (PLACED, OCC, LOG, DET, MASKED, MODELS, MARKS):
        l.clear()
    world, ents = [], []

    def add(r):
        w, e = r
        world.extend(w); ents.extend(e)
    add(plaza())
    add(fort('kale_t', -1500, -1950, front='e'))
    add(fort('kale_b', -1850, 1000, front='e'))
    add(fort('bunker_a', 1150, 1380, 256, 176, front='s', label='d2_s_bunk'))
    add(depot('depo_long', 1000, -1350))
    add(tower('kule_b', -2150, 600))
    add(tower('kule_long', 1730, 250))
    add(tower('kule_ct', 450, 1100))
    add(tower('kule_t', -1250, -1100))
    add(crate_fort('fort_t', -1200, -2150))
    add(crate_fort('fort_long', 1650, -350))
    add(crate_fort('fort_ct', 250, 950))
    ct_have = [e for e in m.ents if e.classname == 'info_player_start']
    t_have = [e for e in m.ents if e.classname == 'info_player_deathmatch']
    allsp = [(e.origin[0], e.origin[1]) for e in ct_have + t_have]
    for e in ct_have + t_have:
        x, y, z0 = e.origin
        f = floor_at(x, y, int(z0) + 40)
        if f is not None:
            e.origin = (x, y, f + 37)
    ct, _ = spawns('ct', [(400, 1150, 360, 270), (1000, 1150, 300, 270)], 32 - len(ct_have), allsp)
    t, _ = spawns('t', [(-1500, -2050, 420, 90), (-600, -1950, 300, 90)], 32 - len(t_have), allsp)
    if DET:
        ents.append(Entity('func_detail', list(DET), zhlt_detaillevel=1))
    if MASKED:
        ents.append(masked_entity(list(MASKED), solid=False))
    ents += ct + t
    ents.append('{\n"classname" "info_map_parameters"\n"buying" "3"\n}')
    for l in LOG:
        print('  [d2 add] ' + l)
    nbm = sum(1 for e in ents if hasattr(e, 'brushes') and e.brushes and e.classname != 'func_detail')
    print('  [d2 add] spawns added: ct %d (+%d dust2) t %d (+%d dust2); new brush ents %d, detail brushes %d'
          % (len(ct), len(ct_have), len(t), len(t_have), nbm, len(DET)))
    sm = {}
    return [b.to_str(sm) if hasattr(b, 'to_str') else b for b in world], [e.to_str(sm) if hasattr(e, 'to_str') else e for e in ents]


LABELS = {'d2_s_kale': 'Fort | Kale', 'd2_s_bunk': 'A Bunker | A Siginagi', 'd2_s_depo': 'Depot | Depo',
          'd2_s_kule': 'Watch tower | Gozetleme kulesi'}


def write_ini(m):
    marks = []                       # the plugin shows at most 4 markers (MS_MAXMK)
    for lab, x, y, z in MARKS:
        if lab.startswith(('Boss arena', 'Defense terrace')):
            marks.append('%s = %d %d %d' % (lab, x, y, z))
    for nm, x0, y0, x1, y1, z, label in PLACED:
        if nm in ('kale_b', 'bunker_a'):
            marks.append('%s = %d %d %d' % (LABELS[label], (x0 + x1) // 2, (y0 + y1) // 2, z + 300))
    txt = """; zm_vexmira_dust2v1 - de_dust2 zombie camp edition (latin-1, Turkce harfsiz) - MapBy:SmurfSexy
[info]
name_en = Vexmira Dust II (zombie camp)
name_tr = Vexmira Dust II (zombi kamp)
roundtime = 5

[story_en]
line = Vexmira Dust II - the old market town is quarantined. The infection spreads from the tunnels.
line = Camp up: 2-floor forts with glass defense rooms, the depot, the A bunker, glass watch towers.
line = Zombies smash the doors - hold the laser zones! Bosses fight in the statue plaza. Map by SmurfSexy.

[story_tr]
line = Vexmira Dust II - eski carsi kasabasi karantinada. Enfeksiyon tunellerden yayiliyor.
line = Kamp kur: camli savunma odali 2 katli kaleler, depo, A siginagi, camli gozetleme kuleleri.
line = Zombiler kapilari kirar - lazer bolgelerini tut! Bosslar heykel meydaninda. Harita: SmurfSexy.

[markers]
""" + '\n'.join(marks) + '\n\n[models]\n' + '\n'.join(MODELS) + '\n'
    os.makedirs(os.path.dirname(INI), exist_ok=True)
    with open(INI, 'w', encoding='latin-1') as f:
        f.write(txt)
