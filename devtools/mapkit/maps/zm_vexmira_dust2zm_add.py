"""Zombie-plague additions for zm_vexmira_dust2zm (v3; was zm_vexmira_dust2v1).

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
NAME = 'zm_vexmira_dust2zm'
INI = os.path.join(REPO, 'cstrike', 'addons', 'amxmodx', 'configs', 'vexmira_maps', NAME + '.ini')
BASE_BSP = os.environ.get('D2_BASE_BSP', '')

WALL, WALL2, TRIM, CC, PLANK, METAL = 'd2_wall', 'd2_wall2', 'd2_trim', 'd2_ccrete', 'd2_plank', 'd2_metal'
CRATE, CTOP, CRS, MIL, MILT = 'd2_crate', 'd2_cratetop', 'd2_crate_s', 'd2_mil', 'd2_miltop'
STONE, PAVE, MARBLE = 'd2_stone', 'd2_pave', 'd2_marble'
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
    else:
        px = (x0 + mid) if front == 'w' else (x1 - mid)
        pa = (y1 - y0) * 0.30
        world.append(bx((px - 8, y0 + t, z), (px + 8, y0 + pa - pw / 2, z + h1), WALL))
        world.append(bx((px - 8, y0 + pa + pw / 2, z), (px + 8, y1 - t, z + h1), WALL))
        world.append(bx((px - 8, y0 + pa - pw / 2, z + 104), (px + 8, y0 + pa + pw / 2, z + h1), WALL))
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
    MASKED.append(sign_on(front, x0, y0, x1, y1, L / 2 - 64, L / 2 + 64, z + 116, z + 132, label, out=4))
    if L >= 288:
        MASKED.append(sign_on(front, x0, y0, x1, y1, 16, 80, z + 8, z + 104, 'd2_ban_bio', out=3))
        MASKED.append(sign_on(front, x0, y0, x1, y1, L - 80, L - 16, z + 8, z + 104, 'd2_ban_zm', out=3))
    big = max(lr, key=lambda s: side_len(s, x0, y0, x1, y1))
    Lg = side_len(big, x0, y0, x1, y1)
    MASKED.append(sign_on(big, x0, y0, x1, y1, Lg / 2 - 48, Lg / 2 + 48, z + 8, z + 104, 'd2_warn', out=3))
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
    MASKED.append(sign_on('s', x0, y0, x1, y1, L / 2 - 64, L / 2 + 64, z + 120, z + 136, 'd2_s_depo', out=4))
    MASKED.append(sign_on('s', x0, y0, x1, y1, 16, 80, z + 16, z + 112, 'd2_ban_zm', out=3))
    MASKED.append(sign_on('s', x0, y0, x1, y1, L - 80, L - 16, z + 16, z + 112, 'd2_ban_bio', out=3))
    MASKED.append(sign_on('n', x0, y0, x1, y1, L / 2 - 64, L / 2 + 64, z + 112, z + 176, 'd2_sign', out=3))
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
    MASKED.append(sign_on('n', x0, y0, x1, y1, L / 2 - 64, L / 2 + 64, pz + 8, pz + 24, 'd2_s_kule', out=8))
    MASKED.append(sign_on('e', x0, y0, x1, y1, L / 2 - 32, L / 2 + 32, z + 48, z + 176, 'd2_ban_bio', out=2))
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
    global WFACE
    WFACE = probe(-1000, 1300, 40, -1, 0) or -1120
    world, ents = [], []
    # floors: paved square + west defense terrace (raised)
    world.append(bx((TEX, PY0, -416), (PX1, PY1, ZPL), {'top': PAVE, 'all': TRIM}))
    world.append(bx((PX0 - 16, PY0, -416), (TEX, PY1, ZTE), {'top': CC, 'all': TRIM}))
    # perimeter walls up to the sky lid (seal the plaza)
    W = {'all': WALL}
    world.append(bx((PX0 - 16, PY1, -416), (PX1 + 16, PY1 + 16, ZSKY), W))
    world.append(bx((PX1, PY0, -416), (PX1 + 16, PY1, ZSKY), W))
    # no full west wall: the B site wall (with the B window) is the plaza's west side now; only a screen ABOVE
    # the B wall top (z 96) keeps B and the plaza out of each other's view (FPS)
    world.append(bx((WFACE, PY0, 96), (PX0, PY1, ZSKY), W))
    # terrace south facade (to the sky lid): blocks the long sight line B doors -> road -> plaza (FPS),
    # the terrace keeps its west entrance (x PX0..PX0+112) and the square keeps its gate
    world.append(bx((PX0 + 112, PY0 - 16, ZTE), (TEX - 16, PY0, ZSKY), {'s': 'd2_window', 'n': WALL2, 'all': WALL}))
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
        DET.extend(prism((bxp, byp), 14, 6, ZPL, ZPL + 56, STONE))
        DET.append(bx((bxp - 20, byp - 20, ZPL + 56), (bxp + 20, byp + 20, ZPL + 64), METAL))
        ents.append(env_sprite((bxp, byp, ZPL + 88), 'sprites/vexmira/fire.spr', 0.55, (255, 255, 255), 255, 5, 12))
        ents.append(light((bxp, byp, ZPL + 112), (255, 150, 70), 160))
    # colonnade along the north wall with banners between the columns
    k = 0
    for x in range(TEX + 64, PX1 - 32, 128):
        DET.extend(prism((x, PY1 - 40), 18, 6, ZPL, ZPL + 288, STONE))
        DET.append(bx((x - 26, PY1 - 66, ZPL + 288), (x + 26, PY1 - 14, ZPL + 304), MARBLE))
        if x + 128 < PX1 - 32:
            tex = 'd2_ban_bio' if k % 2 == 0 else 'd2_ban_zm'
            b = bx((x + 32, PY1 - 2, ZPL + 112), (x + 96, PY1, ZPL + 240), {'s': tex, 'all': NULL})
            b.fit_faces(('s',))
            MASKED.append(b)
            k += 1
    # big signs: east wall (arena + VEXMIRA) and west terrace wall
    def wsign(x, y0w, y1w, za, zb, tex, face):
        b = bx((x - 2, y0w, za), (x, y1w, zb), {face: tex, 'all': NULL}) if face == 'w' else \
            bx((x, y0w, za), (x + 2, y1w, zb), {face: tex, 'all': NULL})
        b.fit_faces((face,))
        MASKED.append(b)
    WF = WFACE
    wsign(PX1, 1300, 1556, ZPL + 120, ZPL + 248, 'd2_sign', 'w')
    wsign(PX1, 1300, 1556, ZPL + 256, ZPL + 288, 'd2_s_arena', 'w')
    wsign(WFACE, 1466, 1626, ZTE + 100, ZTE + 180, 'd2_sign', 'e')
    b = bx((WFACE, 1180, ZTE + 16), (WFACE + 2, 1300, ZTE + 136), {'e': 'd2_warn', 'all': NULL})
    b.fit_faces(('e',)); MASKED.append(b)
    b = bx((WFACE, 1466, ZTE + 70), (WFACE + 2, 1626, ZTE + 92), {'e': 'd2_s_laser', 'all': NULL})
    b.fit_faces(('e',)); MASKED.append(b)
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
        one.classname = 'func_detail'          # v3: world detail, drawn only where visible (was one map-wide entity)
        one.keys = [('zhlt_detaillevel', '1')]
        for e in lamps:
            one.solids += e.solids
        m.ents.append(one)
    for e in crates:
        m.world_solids += e.solids
    # A short top crate -> replaced by the crate tunnel
    def _in(so, a, b):
        p, q = solid_bbox(so)
        return all(p[i] >= a[i] - 1 and q[i] <= b[i] + 1 for i in range(3))
    m.world_solids = [so for so in m.world_solids if not _in(so, (600, 712, -72), (680, 792, 72))]
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


# ---------------------------------------------------------------- carving into dust2 walls (v3)
SHELLS = []          # RMF solids of the new room shells (carved together with the dust2 brushes)
CARVES = []          # boxes removed from every world brush at the end (room interiors, doorways, windows)
GLASSES = []         # (name, [Brush]) breakable glass groups
TREES = []           # xmas tree centres (kept free of spawns)
GATE = []


def probe(x, y, z, dx, dy, maxd=2000):
    """walk from an open point along (dx, dy) until solid (stage-1 BSP); returns the face coordinate."""
    if not empty(x, y, z):
        return None
    last = 0
    for d in range(4, maxd, 4):
        if not empty(x + dx * d, y + dy * d, z):
            lo, hi = last, d
            while hi - lo > 1:
                m = (lo + hi) // 2
                if empty(x + dx * m, y + dy * m, z):
                    lo = m
                else:
                    hi = m
            v = (x + dx * (hi - 0.5)) if dx else (y + dy * (hi - 0.5))
            r = round(v / 8) * 8
            return int(r if abs(r - v) <= 1.0 else round(v))
        last = d
    return None


def carve(mn, mx):
    CARVES.append((tuple(mn), tuple(mx)))


def shell_box(mn, mx, tex):
    from ..rmf import box_solid
    SHELLS.append(box_solid(mn, mx, tex))


class WallFrame:
    """coordinates relative to a corridor wall: u along the wall, w depth into the wall (0 = corridor face)."""

    def __init__(self, axis, face, sgn):
        self.axis, self.face, self.sgn = axis, face, sgn       # axis 'x' -> wall plane x = face

    def box(self, u0, u1, w0, w1, z0, z1):
        a, b = sorted((self.face + self.sgn * w0, self.face + self.sgn * w1))
        if self.axis == 'x':
            return (a, min(u0, u1), z0), (b, max(u0, u1), z1)
        return (min(u0, u1), a, z0), (max(u0, u1), b, z1)

    def pt(self, u, w, z):
        if self.axis == 'x':
            return (self.face + self.sgn * w, u, z)
        return (u, self.face + self.sgn * w, z)

    def corridor_side(self):            # brush face that looks at the corridor
        if self.axis == 'x':
            return 'w' if self.sgn > 0 else 'e'
        return 's' if self.sgn > 0 else 'n'

    def into(self):                     # ladder facing (into the wall = away from the corridor)
        return ('+x' if self.sgn > 0 else '-x') if self.axis == 'x' else ('+y' if self.sgn > 0 else '-y')

    def out(self):
        return ('-x' if self.sgn > 0 else '+x') if self.axis == 'x' else ('-y' if self.sgn > 0 else '+y')


def opening(F, u0, u1, z0, z1, W, t=16):
    """hole through a corridor wall (w 0..W) lined with its own frame, so a hollow or thin dust2 wall cannot leak."""
    shell_box(*F.box(u0 - t, u1 + t, 0, W, z0 - t, z0), WALL2)
    shell_box(*F.box(u0 - t, u1 + t, 0, W, z1, z1 + t), WALL2)
    shell_box(*F.box(u0 - t, u0, 0, W, z0, z1), WALL2)
    shell_box(*F.box(u1, u1 + t, 0, W, z0, z1), WALL2)
    carve(*F.box(u0, u1, -4, W + 1, z0, z1))


def wall_sign(F, u0, u1, z0, z1, tex, w=-1.5):
    """non-solid sign on the corridor face of the wall."""
    mn, mx = F.box(u0, u1, w, 0, z0, z1)
    side = F.corridor_side()
    b = bx(mn, mx, {side: tex, 'all': NULL})
    b.fit_faces((side,))
    MASKED.append(b)


def wall_room(name, F, a0, a1, z0, floors=2, H=120, depth=176, W=32, t=16, entr=None, label='d2_s_base',
              partition=False, glass_hp=320, ground_windows=True, mark=None, lcol=(255, 200, 150)):
    """multi-floor defense room carved behind a corridor wall.
    ground floor: open doorway (no door) + glass windows; upper floors: almost fully glass front; ladders
    through hatches; lamps; optional inner partition wall with a doorway."""
    top = z0 + floors * H
    w0, w1 = W, W + depth
    # shell
    T = {'top': CC, 'bottom': CC, 'side': WALL2}
    shell_box(*F.box(a0 - t, a1 + t, w0 - t, w1 + t, z0 - t, z0), {'top': CC, 'all': CC})
    shell_box(*F.box(a0 - t, a1 + t, w0 - t, w1 + t, top, top + t), {'bottom': CC, 'all': CC})
    shell_box(*F.box(a0 - t, a1 + t, w1, w1 + t, z0, top), WALL2)
    shell_box(*F.box(a0 - t, a0, w0, w1, z0, top), WALL2)
    shell_box(*F.box(a1, a1 + t, w0, w1, z0, top), WALL2)
    shell_box(*F.box(a0 - t, a1 + t, w0 - t, w0, z0, top), WALL2)
    carve(*F.box(a0, a1, w0, w1, z0, top))
    world, ents = [], []
    e0 = entr if entr is not None else a0 + 24
    opening(F, e0, e0 + 64, z0, z0 + 112, w0)                              # doorway (no door)
    wall_sign(F, e0 - 64, e0 + 128, z0 + 118, z0 + 142, label)
    panes = []
    L = a1 - a0
    if ground_windows:
        for u in range(int(a0 + 24), int(a1 - 88), 128):
            if u < e0 + 96 and u + 64 > e0 - 32:
                continue
            opening(F, u, u + 64, z0 + 52, z0 + 104, w0)
            panes.append(bx(*F.box(u, u + 64, w0 / 2 - 2, w0 / 2 + 2, z0 + 52, z0 + 104), GLASS))
    if panes:
        ents.append(glass(panes, health=glass_hp))
    for k in range(1, floors):
        zf = z0 + k * H
        # floor slab with a hatch in the back corner (alternating sides)
        hu0 = (a1 - 72) if k % 2 else (a0 + 24)
        hw0 = w1 - 56
        for (ua, ub, wa, wb) in ((a0, hu0, w0, w1), (hu0 + 48, a1, w0, w1), (hu0, hu0 + 48, w0, hw0), (hu0, hu0 + 48, hw0 + 48, w1)):
            if ub - ua > 0.5 and wb - wa > 0.5:
                world.append(bx(*F.box(ua, ub, wa, wb, zf - 8, zf), {'top': PLANK, 'bottom': PLANK, 'all': TRIM}))
        lad, vis = ladder(F.pt(hu0 + 24, w1, zf - H), F.into(), H + 28)
        ents.append(lad); MASKED.extend(vis)
        # glass front: posts every 128, glass between, sill 36
        gp = []
        u = a0 + 8
        while u < a1 - 8:
            u2 = min(u + 112, a1 - 8)
            opening(F, u, u2, zf + 36, zf + 108, w0)
            gp.append(bx(*F.box(u, u2, w0 / 2 - 2, w0 / 2 + 2, zf + 36, zf + 108), GLASS))
            u = u2 + 16
        ents.append(glass(gp, health=glass_hp, renderamt=110))
    wl = [w0 + (w1 - w0) * 0.25, w0 + (w1 - w0) * 0.75] if depth >= 280 else [(w0 + w1) / 2]
    ul = [a0 + (a1 - a0) * 0.3, a0 + (a1 - a0) * 0.7] if L >= 300 else [(a0 + a1) / 2]
    for k in range(floors):
        zc_ = z0 + (k + 1) * H - (8 if k < floors - 1 else 0)
        for wq in wl:
            for uq in ul:
                ents.append(light(F.pt(uq, wq, zc_ - 30), lcol, 170))
                DET.append(bx(*F.box(uq - 10, uq + 10, wq - 10, wq + 10, zc_ - 6, zc_), LAMP))
    if partition and depth >= 280:          # wall parallel to the front, doorway away from the entrance
        pw = (w0 + w1) / 2
        du = (a1 - 104) if e0 < (a0 + a1) / 2 else (a0 + 40)
        for ua, ub in ((a0, du), (du + 64, a1)):
            if ub - ua > 0.5:
                world.append(bx(*F.box(ua, ub, pw - 8, pw + 8, z0, z0 + H - 8), WALL))
        world.append(bx(*F.box(du, du + 64, pw - 8, pw + 8, z0 + 104, z0 + H - 8), WALL))
    elif partition and L >= 300:
        pu = (a0 + a1) / 2
        dw = (w0 + 24, w0 + 88) if e0 > pu else (w1 - 88, w1 - 24)
        for wa, wb in ((w0, dw[0]), (dw[1], w1)):
            world.append(bx(*F.box(pu - 8, pu + 8, wa, wb, z0, z0 + H - 8), WALL))
        world.append(bx(*F.box(pu - 8, pu + 8, dw[0], dw[1], z0 + 104, z0 + H - 8), WALL))
    # inside dressing: crates (cover), blood, a banner on the back wall
    cu = a0 + 40 if e0 > (a0 + a1) / 2 else a1 - 104
    b = bx(*F.box(cu, cu + 64, w1 - 64, w1, z0, z0 + 64), {'all': CRATE, 'top': CTOP}); b.fit_faces(('n', 's', 'e', 'w', 'top')); DET.append(b)
    MARKS.append((mark or 'Defense base | Savunma ussu', *[int(c) for c in F.pt((a0 + a1) / 2, -48, z0 + 200)]))
    PLACED.append((name, *[int(c) for c in F.box(a0, a1, w0, w1, z0, top)[0][:2]], *[int(c) for c in F.box(a0, a1, w0, w1, z0, top)[1][:2]], int(z0), label))
    LOG.append('%-12s wall room %s face %d u %d..%d z %d floors %d' % (name, F.axis, F.face, a0, a1, z0, floors))
    return world, ents


def tunnel_ashort():
    """secret tunnel: A short stair nook -> through the wall -> down into the CT ramp corridor."""
    xn = probe(632, 424, -120, 1, 0)                 # nook east wall face
    yc = probe(824, 900, -200, 0, -1)                # ramp corridor south wall face
    if xn is None or yc is None:
        LOG.append('tunnel_ashort: probe failed %s %s' % (xn, yc))
        return [], []
    zc = floor_at(824, yc + 24, -100)
    zn = floor_at(632, 424, -100)
    world, ents = [], []
    X0, X1 = 792, 856
    t = 16
    # segment 1: east from the nook (open west end), segment 2: north to the corridor (open north end)
    for (mn, mx, skip) in (((xn + 12, 392, zn), (X1, 456, zn + 112), 'w'), ((X0, 392, zc), (X1, yc - 48, zn + 112), 'n')):
        carve(mn, mx)
        shell_box((mn[0] - t, mn[1] - t, mn[2] - t), (mx[0] + t, mx[1] + t, mn[2]), CC)
        shell_box((mn[0] - t, mn[1] - t, mx[2]), (mx[0] + t, mx[1] + t, mx[2] + t), CC)
        if skip != 's':
            shell_box((mn[0] - t, mn[1] - t, mn[2]), (mx[0] + t, mn[1], mx[2]), WALL2)
        if skip != 'n':
            shell_box((mn[0] - t, mx[1], mn[2]), (mx[0] + t, mx[1] + t, mx[2]), WALL2)
        if skip != 'w':
            shell_box((mn[0] - t, mn[1], mn[2]), (mn[0], mx[1], mx[2]), WALL2)
        shell_box((mx[0], mn[1], mn[2]), (mx[0] + t, mx[1], mx[2]), WALL2)
    opening(WallFrame('y', yc, -1), X0, X1, zc, zc + 112, 48)            # exit: w 0..48 joins segment 2 (ends at yc-48)
    opening(WallFrame('x', xn, 1), 392, 456, zn, zn + 112, 12)          # entrance: w 0..12 joins segment 1 (starts at xn+12)
    # floor: flat at zn from the nook to y 600, then stairs down (north) to zc
    rise = zn - zc
    n = max(1, int(rise // 8))
    run = 16
    ys = yc - 48 - n * run
    world.append(bx((X0, 392, zc), (X1, ys, zn), {'top': CC, 'all': CC}))
    world += stairs((824, yc - 48, zc), '-y', 64, rise, rise=rise / n, run=run, tex={'top': PLANK, 'all': TRIM})
    for y in (430, (392 + yc) // 2, yc - 60):
        ents.append(light((824, y, zn + 90 if y < ys else zc + 96), (255, 60, 40), 90))
    DET.append(bx((816, 420, zn + 104), (832, 436, zn + 112), LAMP))
    b = bx((xn - 1, 344, zn + 118), (xn, 504, zn + 138), {'w': 'd2_s_tunel', 'all': NULL}); b.fit_faces(('w',)); MASKED.append(b)
    b = bx((X1 + 2, yc, zc + 118), (X1 + 162, yc + 1, zc + 138), {'n': 'd2_s_tunel', 'all': NULL}); b.fit_faces(('n',)); MASKED.append(b)
    for y in range(470, int(ys), 140):
        blood = bx((X0, y, zn + 8), (X0 + 1, y + 64, zn + 72), {'e': '{d2_blood', 'all': NULL}); blood.fit_faces(('e',)); MASKED.append(blood)
    MARKS.append(('Secret tunnel | Gizli tunel', 824, (392 + yc) // 2, zn + 160))
    LOG.append('tunnel_ashort nook %d corridor %d z %d -> %d' % (xn, yc, zn, zc))
    return world, ents


def crate_tunnel():
    """A short top: crate wall with a tunnel through the middle (crates both sides + crate roof)."""
    x0, x1, y0, y1 = 456, 680, 720, 848
    z = floor_at(568, 780, 0)
    if z is None:
        return [], []
    LOG.append('crate_tunnel z %d' % z)

    def cr(a, b, c, d, zz, h, tex=CRATE, top=CTOP):
        br = Brush.box((a, c, zz), (b, d, zz + h), {'top': top, 'bottom': top, 'all': tex})
        br.fit_faces(('n', 's', 'e', 'w', 'top'))
        DET.append(br)
    for (a, b) in ((x0, x0 + 64), (x1 - 64, x1)):
        cr(a, b, y0, y0 + 64, z, 64); cr(a, b, y0 + 64, y1, z, 64)
        cr(a, b, y0, y0 + 64, z + 64, 64, MIL, MILT); cr(a, b, y0 + 64, y1, z + 64, 64, CRS, CRS)
    cr(x0 + 64, x1 - 64, y0, y1, z + 112, 32, CTOP, CTOP)
    cr(x0 + 64, x0 + 128, y0 + 32, y0 + 96, z + 144, 48, CRS, CRS)
    DET.append(bx((560, 776, z + 104), (576, 792, z + 112), LAMP))
    return [], [light((568, 784, z + 90), (255, 190, 120), 80)]


def booth(name, x0, y0, x1, y1, h=64, open_side='s', hp=260):
    """lantern-lit glass defense booth: raised platform, glass walls (3 sides), step crate on the open side,
    lantern posts at the corners."""
    z = floor_at((x0 + x1) / 2, (y0 + y1) / 2, 200)
    if z is None or not area_ok(x0 - 8, y0 - 8, x1 + 8, y1 + 8, z, 220):
        LOG.append('%-12s booth NOT PLACED at %d %d' % (name, x0, y0))
        return [], []
    world, ents = [], []
    zt = z + h
    world.append(bx((x0, y0, z), (x1, y1, zt), {'top': PLANK, 'all': METAL}))
    panes = []
    for s_ in 'nsew':
        if s_ == open_side:
            continue
        L = side_len(s_, x0, y0, x1, y1)
        panes.append(slab_in(s_, x0, y0, x1, y1, 8, L - 8, zt, zt + 64, GLASS, 4, inset=2))
    ents.append(glass(panes, health=hp, renderamt=100))
    for xa, ya in ((x0, y0), (x1 - 8, y0), (x0, y1 - 8), (x1 - 8, y1 - 8)):
        DET.append(bx((xa, ya, zt), (xa + 8, ya + 8, zt + 120), METAL))
    for xa, ya in ((x0 + 4, y0 + 4), (x1 - 4, y1 - 4)):
        DET.append(bx((xa - 10, ya - 10, zt + 120), (xa + 10, ya + 10, zt + 124), METAL))
        DET.append(bx((xa - 7, ya - 7, zt + 104), (xa + 7, ya + 7, zt + 120), LAMP))
        ents.append(light((xa, ya, zt + 96), (255, 180, 90), 110))
    # step on the open side
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    off = {'s': (cx - 24, y0 - 48, cx + 24, y0), 'n': (cx - 24, y1, cx + 24, y1 + 48),
           'w': (x0 - 48, cy - 24, x0, cy + 24), 'e': (x1, cy - 24, x1 + 48, cy + 24)}[open_side]
    b = bx((off[0], off[1], z), (off[2], off[3], z + 36), {'all': CRS}); b.fit_faces(('n', 's', 'e', 'w')); DET.append(b)
    OCC.append((x0, y0, x1, y1))
    PLACED.append((name, x0, y0, x1, y1, z, None))
    LOG.append('%-12s booth at (%d %d)-(%d %d) z %d' % (name, x0, y0, x1, y1, z))
    return world, ents


def crate_rail(x0, y0, x1, y1, z, sides='nse'):
    """glass rail around the top of a crate stack."""
    panes = []
    for s_ in sides:
        L = side_len(s_, x0, y0, x1, y1)
        panes.append(slab_in(s_, x0, y0, x1, y1, 0, L, z, z + 44, GLASS, 4))
    return [], [glass(panes, health=200, renderamt=100)]


# ---------------------------------------------------------------- decoration
BULBS = ('~d2_bulb_r', '~d2_bulb_g', '~d2_bulb_y', '~d2_bulb_b')


def string_lights(p0, p1, z, d, spacing=96):
    """christmas bulbs along a corridor wall: from open points p0..p1 the wall is found in direction d."""
    (x0, y0), (x1, y1) = p0, p1
    L = math.hypot(x1 - x0, y1 - y0)
    n = max(1, int(L // spacing))
    k = 0
    for i in range(n + 1):
        x, y = x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n
        zz = z - 10 * math.sin(math.pi * (i % 4) / 4)          # gentle sag
        f = probe(int(x), int(y), int(zz), d[0], d[1], 600)
        if f is None:
            continue
        if d[0]:
            mn, mx = ((f - 3, y - 1.5, zz - 2), (f, y + 1.5, zz + 2)) if d[0] > 0 else ((f, y - 1.5, zz - 2), (f + 3, y + 1.5, zz + 2))
        else:
            mn, mx = ((x - 1.5, f - 3, zz - 2), (x + 1.5, f, zz + 2)) if d[1] > 0 else ((x - 1.5, f, zz - 2), (x + 1.5, f + 3, zz + 2))
        DET.append(bx(mn, mx, BULBS[k % 4]))
        k += 1
    return k


def xmas_tree(x, y, z, h=200):
    """layered pine (octagonal tiers), bulbs, star, gifts around it."""
    world = []
    DET.extend(prism((x, y), 10, 6, z, z + 32, PLANK))
    tiers = 3
    for i in range(tiers):
        r = 62 - i * 18
        za = z + 24 + i * (h - 40) / tiers
        DET.extend(prism((x, y), r, 6, za, za + (h - 40) / tiers + 6, 'd2_pine', rot=i * 0.5))
        for j in range(3 if i < 2 else 0):
            a = j * 2 * math.pi / 3 + i
            bx_, by_ = x + math.cos(a) * (r - 2), y + math.sin(a) * (r - 2)
            DET.append(bx((bx_ - 3, by_ - 3, za + 4), (bx_ + 3, by_ + 3, za + 10), BULBS[(i + j) % 4]))
    zs = z + 24 + h - 40 + 6
    DET.append(bx((x - 8, y - 8, zs), (x + 8, y + 8, zs + 16), '~d2_star'))
    for k, (dx, dy, s_) in enumerate(((70, 10, 24), (-60, 40, 20), (20, -72, 28))):
        tex = ('d2_gift_r', 'd2_gift_g', 'd2_gift_b')[k % 3]
        b = bx((x + dx - s_ / 2, y + dy - s_ / 2, z), (x + dx + s_ / 2, y + dy + s_ / 2, z + s_), tex)
        b.fit_faces(('n', 's', 'e', 'w', 'top')); DET.append(b)
    TREES.append((x, y))
    OCC.append((x - 90, y - 90, x + 90, y + 90))
    return world, [light((x, y, z + h * 0.6), (255, 200, 120), 110)]


def wreath(F_or_pos, size=48):
    x, y, z, side = F_or_pos
    if side in 'ew':
        mn, mx = ((x - 1, y - size / 2, z), (x, y + size / 2, z + size)) if side == 'w' else ((x, y - size / 2, z), (x + 1, y + size / 2, z + size))
    else:
        mn, mx = ((x - size / 2, y - 1, z), (x + size / 2, y, z + size)) if side == 's' else ((x - size / 2, y, z), (x + size / 2, y + 1, z + size))
    b = bx(mn, mx, {side: '{d2_wreath', 'all': NULL}); b.fit_faces((side,)); MASKED.append(b)


def on_wall(x, y, z, d, w, h, tex, out=1.5):
    """non-solid decal/sign on the wall found from open point (x, y, z) in direction d, centred there."""
    f = probe(int(x), int(y), int(z), d[0], d[1], 800)
    if f is None:
        LOG.append('on_wall miss %s at %d %d' % (tex, x, y))
        return None
    if d[0]:
        side = 'w' if d[0] > 0 else 'e'
        mn, mx = ((f - out, y - w / 2, z - h / 2), (f, y + w / 2, z + h / 2)) if d[0] > 0 else ((f, y - w / 2, z - h / 2), (f + out, y + w / 2, z + h / 2))
    else:
        side = 's' if d[1] > 0 else 'n'
        mn, mx = ((x - w / 2, f - out, z - h / 2), (x + w / 2, f, z + h / 2)) if d[1] > 0 else ((x - w / 2, f, z - h / 2), (x + w / 2, f + out, z + h / 2))
    b = bx(mn, mx, {side: tex, 'all': NULL}); b.fit_faces((side,)); MASKED.append(b)
    return f


def lantern(x, y, z, d, col=(255, 170, 80), bright=90):
    """wall lantern: bracket + glowing box, found on the wall in direction d from open point (x, y, z)."""
    f = probe(int(x), int(y), int(z), d[0], d[1], 600)
    if f is None:
        return None
    if d[0]:
        s_ = 1 if d[0] > 0 else -1
        cx = f - s_ * 14
        DET.append(bx((min(f, f - s_ * 22), y - 2, z + 8), (max(f, f - s_ * 22), y + 2, z + 12), METAL))
        DET.append(bx((cx - 6, y - 6, z - 8), (cx + 6, y + 6, z + 8), LAMP))
        return light((cx - s_ * 8, y, z), col, bright)
    s_ = 1 if d[1] > 0 else -1
    cy = f - s_ * 14
    DET.append(bx((x - 2, min(f, f - s_ * 22), z + 8), (x + 2, max(f, f - s_ * 22), z + 12), METAL))
    DET.append(bx((x - 6, cy - 6, z - 8), (x + 6, cy + 6, z + 8), LAMP))
    return light((x, cy - s_ * 8, z), col, bright)


def vexsign(x, y, z, d, w=256, h=128):
    """lit VEXMIRA / by SmurfSexy marquee + a light in front of it."""
    f = on_wall(x, y, z, d, w, h, 'd2_vexsign', out=2)
    if f is None:
        return []
    if d[0]:
        p = (f - d[0] * 64, y, z)
    else:
        p = (x, f - d[1] * 64, z)
    return [light(p, (140, 255, 120), 120)]


def plaza_extra():
    """v3 boss plaza dressing: VEXMIRA marquee, two xmas trees, glowing ring on the plinth, lanterns."""
    ents = []
    cx, cy = (TEX + PX1) // 2, 1420
    for i in range(8):
        a = i * 2 * math.pi / 8
        x, y = cx + math.cos(a) * 140, cy + math.sin(a) * 140
        DET.append(bx((x - 4, y - 4, ZPL), (x + 4, y + 4, ZPL + 6), BULBS[1 if i % 2 else 0]))
    for p in ((TEX + 110, PY1 - 190), (PX1 - 110, PY0 + 150)):
        w, e = xmas_tree(p[0], p[1], ZPL, 220)
        ents += e
    mx_ = (TEX + PX1) // 2
    b = bx((mx_ - 160, PY1 - 2, ZPL + 330), (mx_ + 160, PY1, ZPL + 490), {'s': 'd2_vexsign', 'all': NULL}); b.fit_faces(('s',)); MASKED.append(b)
    ents.append(light((mx_, PY1 - 80, ZPL + 410), (140, 255, 120), 140))
    # entrance gate from the road: two pillars + lintel with the arena plate, xmas banner under it
    gx0, gx1 = TEX + 40, PX1 - 40
    for gx in (gx0, gx1 - 48):
        world_g = bx((gx, PY0 + 8, ZPL), (gx + 48, PY0 + 56, ZPL + 272), {'top': STONE, 'all': STONE})
        GATE.append(world_g)
        DET.append(bx((gx - 6, PY0 + 2, ZPL + 272), (gx + 54, PY0 + 62, ZPL + 288), MARBLE))
        DET.append(bx((gx + 12, PY0 - 2, ZPL + 200), (gx + 36, PY0 + 8, ZPL + 224), LAMP))
        ents.append(light((gx + 24, PY0 - 24, ZPL + 212), (255, 170, 80), 120))
    DET.append(bx((gx0, PY0 + 16, ZPL + 288), (gx1, PY0 + 48, ZPL + 320), {'top': STONE, 'all': TRIM}))
    b = bx((gx0 + 60, PY0 + 14, ZPL + 292), (gx1 - 60, PY0 + 16, ZPL + 316), {'s': 'd2_s_arena', 'all': NULL}); b.fit_faces(('s',)); MASKED.append(b)
    b = bx((gx0 + 120, PY0 + 30, ZPL + 222), (gx1 - 120, PY0 + 32, ZPL + 282), {'s': 'd2_xmas_ban', 'n': 'd2_xmas_ban', 'all': NULL}); b.fit_faces(('s', 'n')); MASKED.append(b)
    # four tall lamp posts around the statue
    for dx, dy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        px, py = cx + dx * 220, cy + dy * 300
        if not (TEX + 40 < px < PX1 - 40 and PY0 + 80 < py < PY1 - 80):
            continue
        DET.append(bx((px - 6, py - 6, ZPL), (px + 6, py + 6, ZPL + 224), METAL))
        DET.append(bx((px - 14, py - 14, ZPL + 224), (px + 14, py + 14, ZPL + 248), LAMP))
        DET.append(bx((px - 18, py - 18, ZPL + 248), (px + 18, py + 18, ZPL + 254), METAL))
        ents.append(light((px, py, ZPL + 210), (255, 190, 120), 170))
    # barricades (crates + low steel) for dodging boss skills
    for (x0b, y0b) in ((cx - 260, cy - 40), (cx + 196, cy - 40)):
        for i, (dx, tex, top) in enumerate(((0, MIL, MILT), (64, CRS, CRS))):
            b = bx((x0b + dx, y0b, ZPL), (x0b + dx + 64, y0b + 64, ZPL + 64), {'all': tex, 'top': top}); b.fit_faces(('n', 's', 'e', 'w', 'top')); DET.append(b)
        DET.append(bx((x0b, y0b + 64, ZPL), (x0b + 128, y0b + 72, ZPL + 40), METAL))
    for x in range(TEX + 120, PX1 - 60, 192):          # lanterns on the north wall (direct, no probe)
        DET.append(bx((x - 2, PY1 - 22, ZPL + 148), (x + 2, PY1, ZPL + 152), METAL))
        DET.append(bx((x - 6, PY1 - 20, ZPL + 132), (x + 6, PY1 - 8, ZPL + 148), LAMP))
        ents.append(light((x, PY1 - 30, ZPL + 140), (255, 170, 80), 100))
    w_ = list(GATE); GATE.clear()
    return w_, ents


def decorations():
    """christmas lights / wreaths / banners / lanterns across the map + the second VEXMIRA marquee (mid)."""
    ents = []
    n = 0
    n += string_lights((-232, -120), (-232, 1000), -150, (-1, 0))     # mid west wall
    n += string_lights((-232, -120), (-232, 1000), -150, (1, 0))      # mid east wall
    n += string_lights((1640, -880), (1640, 980), -40, (-1, 0))       # long A
    n += string_lights((1640, -880), (1640, 980), -40, (1, 0))
    n += string_lights((-1900, -2050), (-950, -2050), 90, (0, -1))    # T spawn back wall
    n += string_lights((-1840, 100), (-1840, 560), -40, (-1, 0))      # B tunnel
    n += string_lights((600, 1300), (1150, 1300), 70, (0, 1))         # A site north wall
    LOG.append('string lights: %d bulbs' % n)
    for (x, y, z, d) in ((-232, 300, -200, (-1, 0)), (-232, 700, -200, (1, 0)), (1640, -400, -60, (1, 0)),
                         (1640, 600, -60, (-1, 0)), (-1400, -2050, 40, (0, -1)), (350, 1150, -170, (0, 1))):
        on_wall(x, y, z, d, 48, 48, '{d2_wreath', out=1)
    for (x, y, z, d) in ((-1300, -2050, 120, (0, -1)), (400, 1150, -120, (0, 1)), (-1750, 1000, 20, (-1, 0))):
        on_wall(x, y, z, d, 256, 64, 'd2_xmas_ban')
    ents += vexsign(-232, 520, -150, (1, 0), 256, 128)                # mid, second marquee
    # B tunnels: lanterns, blood, quarantine banners (creepy red light)
    for y in (140, 300, 460):
        l_ = lantern(-1824, y, -60, (-1, 0) if y % 320 else (1, 0), (255, 60, 40), 80)
        if l_:
            ents.append(l_)
    for (x, y) in ((-1700, -100), (-1400, -60), (-1100, -100)):
        l_ = lantern(x, y, -40, (0, -1), (255, 70, 40), 90)
        if l_:
            ents.append(l_)
    for (x, y, z, d) in ((-1824, 220, -110, (1, 0)), (-1500, -60, -90, (0, 1)), (-1250, -60, -90, (0, -1))):
        on_wall(x, y, z, d, 96, 96, '{d2_blood', out=1)
    for (x, y, z, d, t) in ((-1824, 380, -70, (-1, 0), 'd2_ban_bio'), (-1600, -80, -60, (0, -1), 'd2_ban_zm'),
                            (-1200, -80, -60, (0, 1), 'd2_ban_bio'), (-232, 100, -180, (-1, 0), 'd2_ban_zm'),
                            (1640, 200, -60, (1, 0), 'd2_ban_zm')):
        on_wall(x, y, z, d, 48, 96, t)
    # B tunnel crates (cover, against the walls) - only where the floor is free
    for (x, y) in ((-1950, -150), (-1150, -150)):
        z = floor_at(x, y, 0)
        if z is not None and area_ok(x - 32, y - 32, x + 32, y + 32, z, 80):
            b = bx((x - 32, y - 32, z), (x + 32, y + 32, z + 64), {'all': CRATE, 'top': CTOP}); b.fit_faces(('n', 's', 'e', 'w', 'top')); DET.append(b)
    # trees in the big open areas
    for (x, y) in ((-1948, -1944), (700, 1330), (380, -1616)):
        z = floor_at(x, y)
        if z is not None and area_ok(x - 80, y - 80, x + 80, y + 80, z, 240) and free_of_others(x - 80, y - 80, x + 80, y + 80):
            w, e = xmas_tree(x, y, z, 200)
            ents += e
        else:
            LOG.append('tree skipped at %d %d' % (x, y))
    return [], ents


def arena_points():
    """boss + human teleport points for the boss round (plugin [arena] section)."""
    cx, cy = (TEX + PX1) // 2, 1420
    boss = (cx, cy - 220, ZPL + 40, 90)
    hum = []
    for y in range(1170, 1900, 96):
        for x in (-1060, -980, -900, -820, -740):
            hum.append((x, y, ZTE + 37, 0))
    return boss, hum[:32]


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
def apply_carves(m):
    from ..rmf import subtract_box, solid_hits_box
    allw = list(m.world_solids) + SHELLS
    n0 = len(allw)
    for mn, mx in CARVES:
        out = []
        for so in allw:
            if solid_hits_box(so, mn, mx):
                out += subtract_box(so, mn, mx, WALL2)
            else:
                out.append(so)
        allw = out
    m.world_solids = allw
    LOG.append('carves %d: brushes %d -> %d (shells %d)' % (len(CARVES), n0, len(allw), len(SHELLS)))


def additions(m):
    global _b
    _b = None
    for l in (PLACED, OCC, LOG, DET, MASKED, MODELS, MARKS, SHELLS, CARVES, TREES):
        l.clear()
    world, ents = [], []

    def add(r):
        w, e = r
        world.extend(w); ents.extend(e)
    add(plaza())
    add(plaza_extra())
    add(fort('kale_t', -1500, -1950, front='e'))
    add(fort('bunker_a', 1150, 1380, 256, 176, front='s', label='d2_s_bunk'))
    add(tower('kule_t', -1250, -1100))
    add(crate_fort('fort_t', -1200, -2150))
    # rooms carved into the walls
    xw = probe(1640, 256, -100, -1, 0)
    xe = probe(1640, 256, -100, 1, 0)
    if xw:
        add(wall_room('long_w', WallFrame('x', xw, -1), 112, 432, -160, 2, entr=128, mark='Long defense | Long savunma'))
    if xe:
        add(wall_room('long_e', WallFrame('x', xe, 1), 96, 416, -160, 2, entr=336, depth=min(176, 2040 - xe - 48)))
    yct = probe(1250, 900, -150, 0, -1)
    if yct:
        z0 = floor_at(1208, yct + 24, -100)
        add(wall_room('ct_shelter', WallFrame('y', yct, -1), 1120, 1400, z0, 3, depth=288, entr=1176, label='d2_s_bunk',
                      partition=True, mark='CT shelter | CT siginagi'))
    xm = probe(-540, -864, -100, -1, 0)
    if xm:
        add(wall_room('mid_base', WallFrame('x', xm, -1), -968, -760, -160, 2, depth=520, entr=-896, partition=True,
                      mark='Mid base | Mid ussu'))
        xmw = probe(-1400, -864, -60, 1, 0)
        xm_depth_w = (xm - 32 - 520) - (xmw or 0) + 2 if xmw else 0
        if xmw:     # upstairs windows over the T -> B corridor too
            F2 = WallFrame('x', xmw, 1)
            gp = []
            for u in (-944, -848):
                opening(F2, u, u + 64, -40 + 36, -40 + 108, xm_depth_w)
                gp.append(bx(*F2.box(u, u + 64, 14, 18, -40 + 36, -40 + 108), GLASS))
            ents.append(glass(gp, health=320))
    add(tunnel_ashort())
    add(crate_tunnel())
    # lantern-lit glass booths at the long doors and on B (crates)
    add(booth('booth_ld_w', 344, -1260, 504, -1100, open_side='s'))
    add(booth('booth_ld_e', 760, -1260, 920, -1100, open_side='s'))
    add(booth('booth_b', -1470, 1400, -1336, 1530, open_side='w'))
    add(crate_rail(-1312, 1360, -1184, 1488, -96, 'nse'))
    add(decorations())
    apply_carves(m)
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
    if MASKED:            # one non-solid entity per map region (an entity is drawn whole when any part is visible)
        groups = {}
        for b_ in MASKED:
            c_ = b_.center()
            groups.setdefault((int(c_[0] // 1400), int(c_[1] // 1400)), []).append(b_)
        for g_ in groups.values():
            ents.append(masked_entity(g_, solid=False))
        LOG.append('masked groups %d' % len(groups))
    ents += ct + t
    ents.append('{\n"classname" "info_map_parameters"\n"buying" "3"\n}')
    for l in LOG:
        print('  [d2 add] ' + l)
    nbm = sum(1 for e in ents if hasattr(e, 'brushes') and e.brushes)
    print('  [d2 add] spawns added: ct %d (+%d dust2) t %d (+%d dust2); brush ents %d, detail brushes %d, masked %d'
          % (len(ct), len(ct_have), len(t), len(t_have), nbm, len(DET), len(MASKED)))
    sm = {}
    return [b.to_str(sm) if hasattr(b, 'to_str') else b for b in world], [e.to_str(sm) if hasattr(e, 'to_str') else e for e in ents]


LABELS = {'d2_s_kale': 'Fort | Kale', 'd2_s_bunk': 'A Bunker | A Siginagi', 'd2_s_depo': 'Depot | Depo',
          'd2_s_kule': 'Watch tower | Gozetleme kulesi'}


def write_ini(m, bsp_path=None):
    marks = []                       # the plugin shows at most 4 markers (MS_MAXMK)
    for lab, x, y, z in MARKS:
        if lab.startswith(('Boss arena', 'Long defense', 'CT shelter', 'Mid base')):
            marks.append('%s = %d %d %d' % (lab, x, y, z))
    boss, hum = arena_points()
    if bsp_path:                     # keep only points where a player fits in the compiled map
        from ..bspcheck import BSP
        bb = BSP(bsp_path)
        ok = lambda p: all(bb.point_contents((p[0] + dx, p[1] + dy, p[2] + dz), hull=1) == -1 for dx in (-16, 16) for dy in (-16, 16) for dz in (0, 16))
        hum = [p for p in hum if ok(p)]
        print('  [d2 ini] arena human points ok %d, boss point ok %s' % (len(hum), ok(boss)))
    arena = ['boss = %d %d %d %d' % boss] + ['human = %d %d %d %d' % p for p in hum]
    txt = """; zm_vexmira_dust2zm - de_dust2 zombie camp edition (latin-1, Turkce harfsiz) - MapBy:SmurfSexy
[info]
name_en = Vexmira Dust II ZM
name_tr = Vexmira Dust II ZM
roundtime = 5

[story_en]
line = Vexmira Dust II ZM - the old market town fell to the infection. Merry Christmas from the quarantine zone!
line = Camp inside the walls: glass defense rooms on long A, the 3-floor CT shelter, the mid base, secret tunnel on A short.
line = Lantern-lit glass booths at long doors and B. Bosses fight in the statue plaza - everyone is pulled in. Map by SmurfSexy.

[story_tr]
line = Vexmira Dust II ZM - eski carsi kasabasi enfeksiyona dustu. Karantina bolgesinden mutlu yillar!
line = Duvarlarin icinde kamp kur: long A camli savunma odalari, 3 katli CT siginagi, mid ussu, A short gizli tunel.
line = Long kapisi ve B'de fenerli cam kulubeler. Bosslar heykel meydaninda - herkes oraya isinlanir. Harita: SmurfSexy.

[markers]
""" + '\n'.join(marks) + '\n\n[arena]\n' + '\n'.join(arena) + '\n\n[models]\n' + '\n'.join(MODELS) + '\n'
    os.makedirs(os.path.dirname(INI), exist_ok=True)
    with open(INI, 'w', encoding='latin-1') as f:
        f.write(txt)
