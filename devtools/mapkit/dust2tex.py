"""Original dust-style textures for zm_vexmira_dust2v1 (no Valve art: the de_dust2 source uses cs_dust.wad,
which is replaced by these procedural look-alikes, embedded in the BSP -> nothing extra to download).

Importing this module registers the textures in mapkit.textures.REGISTRY.
RMF texture name -> ours: RMF_TEX below.
"""
import math

import numpy as np

from .texgen import (F, Canvas, ao, apply_shade, bevel_mask, blur, cracks, fbm, fill, grain, grid_cells, mix,
                     per_cell, shade, streaks)
from .textures import bolts, grime, sandstone, tex, wood_grain

SANDW = (204, 176, 128)     # sun-bleached sandstone plaster


def _grade(img, amt=1.0):
    """dust2zm look: dark, desaturated, cold grey-green with a rusty undertone in the shadows (zombie theme)."""
    img = np.asarray(img, F)
    a = img[..., 3:] if img.shape[-1] == 4 else None
    c = img[..., :3]
    lum = (c @ np.array([0.30, 0.59, 0.11], F))[..., None]
    c = lum + (c - lum) * (1 - 0.55 * amt)                     # desaturate
    tint = np.array([0.86, 0.96, 0.90], F)                      # cold grey-green
    rust = np.array([1.05, 0.78, 0.66], F)
    sh = np.clip(1 - lum * 1.6, 0, 1)                           # shadows get a rusty / dried-blood tone
    c = c * (tint * (1 - sh * 0.35 * amt) + rust * sh * 0.35 * amt)
    c = c * (1 - 0.42 * amt)                                     # darker
    c = np.clip(c, 0, 1)
    return np.concatenate([c, a], -1) if a is not None else c


def dtex(name, w=128, h=128, cat='dust2', amt=1.0, **kw):
    """@tex + the dark zombie grade"""
    def deco(fn):
        def g(rng, ww, hh):
            return _grade(fn(rng, ww, hh), amt)
        tex(name, w, h, cat, **kw)(g)
        return fn
    return deco
SANDD = (176, 146, 100)

RMF_TEX = {
    '-0cssandwall': 'd2_wall', '-1cssandwall': 'd2_wall2', 'sandtrim': 'd2_trim', 'sandroad': 'd2_road',
    '-2sand': 'd2_sand2', '-0sand': 'd2_sand', '-0sandrock': 'd2_rock', 'sandccrete': 'd2_ccrete',
    'sandwlldoor': 'd2_door', 'sandwlldoor2': 'd2_gate', 'sandwllwndw': 'd2_window', 'sandcrtlrgsd': 'd2_crate',
    'sandcrtlrgtp': 'd2_cratetop', 'sandcrtsmsd': 'd2_crate_s', 'mltrycrtesd': 'd2_mil', 'mltrycrtesd2': 'd2_mil2',
    'mltrycrtetp': 'd2_miltop', 'generic011': 'vx_metal_dark', '+0~fifties_lgt2': '~vx_light_y', '+0~white': '~vx_light_c',
    'aaatrigger': 'AAATRIGGER', 'sky': 'sky',
}


def _plaster(rng, w, h, tone, crack=10, patches=True):
    base = fill(h, w, tone) * (0.88 + 0.18 * fbm(h, w, 4, rng, 5))[..., None]
    n = fbm(h, w, 24, rng, 4)
    img = apply_shade(base, shade(n * 0.35, 2.5))
    if patches:   # flaked plaster showing the darker stone under it
        hole = np.clip((fbm(h, w, 3, rng, 6, 0.6) - 0.68) * 9, 0, 1)
        img = mix(img, img * 0.78, hole)
        img = img * (1 - 0.18 * np.clip(blur(hole, 1.2) * 2.5 - hole * 2.5, 0, 1))[..., None]
    c = cracks(h, w, rng, crack, 0.9, 0.45)
    img = img * (1 - 0.35 * c)[..., None]
    img = mix(img, img * 0.82, streaks(h, w, rng, 14, 0.5) * 0.45)
    return img


@dtex('d2_wall', 128, 128, 'dust2', desc='dust2 style: sun-bleached plaster wall over sandstone')
def t_wall(rng, w, h):
    return grain(grime(_plaster(rng, w, h, SANDW), rng, 0.18, 3, (120, 96, 60)), rng, 0.03)


@dtex('d2_wall2', 128, 128, 'dust2', desc='dust2 style: plaster wall, older, more cracks')
def t_wall2(rng, w, h):
    return grain(grime(_plaster(rng, w, h, (196, 166, 120), crack=16), rng, 0.28, 3, (110, 88, 56)), rng, 0.035)


@dtex('d2_trim', 128, 32, 'dust2', desc='dust2 style: sandstone trim course')
def t_trim(rng, w, h):
    img, n = sandstone(rng, w, h, (182, 150, 104))
    lx, ly, cid = grid_cells(h, w, 32, 32, 0.0)
    hm = bevel_mask(lx, ly, 32, 32, 2.0, 3) * (1.05 - 0.2 * fbm(h, w, 8, rng, 3))
    img = img * (0.92 + 0.14 * per_cell(cid, rng))[..., None]
    img = apply_shade(img, shade(np.clip(hm, 0, 1) * 0.8 + n * 0.2, 3)) * ao(hm, 2, 0.5)[..., None]
    return grain(grime(img, rng, 0.2, 2, (90, 72, 44)), rng, 0.03)


@dtex('d2_road', 256, 256, 'dust2', desc='dust2 style: packed sand road with cart ruts and stones')
def t_road(rng, w, h):
    base = fill(h, w, (170, 140, 98)) * (0.85 + 0.25 * fbm(h, w, 6, rng, 5))[..., None]
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    rut = np.exp(-((xs - 80) % w - 0) ** 2 / 200.0) + np.exp(-((xs - 176) % w) ** 2 / 200.0)
    rut = np.clip(rut * (0.6 + 0.4 * fbm(h, w, 8, rng, 3)), 0, 1)
    img = mix(base, base * 0.8, rut * 0.6)
    pebble = np.clip((fbm(h, w, 64, rng, 2) - 0.72) * 6, 0, 1)
    img = apply_shade(img, shade(pebble * 0.6 + fbm(h, w, 32, rng, 3) * 0.2 - rut * 0.2, 3))
    return grain(img, rng, 0.04)


def _sand(rng, w, h, tone):
    base = fill(h, w, tone) * (0.9 + 0.18 * fbm(h, w, 5, rng, 5))[..., None]
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    rip = np.sin((ys + 6 * fbm(h, w, 4, rng, 3) * 10) / h * 2 * math.pi * 9) * 0.5 + 0.5
    img = apply_shade(base, shade(rip * 0.25 + fbm(h, w, 40, rng, 3) * 0.2, 2.5))
    return grain(img, rng, 0.04)


@dtex('d2_sand', 256, 256, 'dust2', desc='dust2 style: wind-rippled sand')
def t_sand(rng, w, h):
    return _sand(rng, w, h, (206, 174, 122))


@dtex('d2_sand2', 256, 256, 'dust2', desc='dust2 style: darker trodden sand')
def t_sand2(rng, w, h):
    return _sand(rng, w, h, (186, 154, 106))


@dtex('d2_rock', 128, 128, 'dust2', desc='dust2 style: weathered desert rock')
def t_rock(rng, w, h):
    n = fbm(h, w, 6, rng, 6)
    img = fill(h, w, (164, 132, 94)) * (0.75 + 0.45 * n)[..., None]
    c = cracks(h, w, rng, 14, 1.4, 0.6, warp=9)
    img = apply_shade(img, shade(n * 0.7 - c * 0.4, 4))
    img = img * (1 - 0.3 * c)[..., None]
    return grain(grime(img, rng, 0.25, 3, (90, 70, 44)), rng, 0.04)


@dtex('d2_ccrete', 128, 128, 'dust2', desc='dust2 style: sandy concrete')
def t_ccrete(rng, w, h):
    img = fill(h, w, (176, 160, 134)) * (0.88 + 0.16 * fbm(h, w, 8, rng, 5))[..., None]
    pits = np.clip((fbm(h, w, 48, rng, 2) - 0.75) * 5, 0, 1)
    img = apply_shade(img, shade(-pits * 0.4 + fbm(h, w, 16, rng, 3) * 0.15, 3))
    img = img * (1 - 0.3 * cracks(h, w, rng, 6, 0.8, 0.4))[..., None]
    return grain(grime(img, rng, 0.2, 3), rng, 0.03)


def _planks(rng, w, h, tone=(150, 104, 62), dark=(92, 60, 34), plank=16):
    img, ring = wood_grain(h, w, rng, tone, dark, 'y', rings=12)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    pid = (xs // plank).astype(np.int64)
    img = img * (0.82 + 0.3 * per_cell(pid, rng))[..., None]
    gap = ((xs % plank) < 1.2).astype(F)
    img = apply_shade(img, shade(ring * 0.05 - gap * 0.6, 3))
    return img


# sizes measured from the de_dust2 source faces (so the RMF alignment fits): door 96x160, gate 128x160, window 64x256
@dtex('d2_door', 96, 160, desc='dust2zm: weathered blue-grey plank door (88 px leaf, 4 px frame), blood hand print')
def t_door(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    img = _plaster(rng, w, h, (150, 130, 100), crack=4, patches=False)
    door = ((xs >= 4) & (xs < w - 4) & (ys >= 4)).astype(F)
    wood = _planks(rng, w, h, (92, 110, 122), (44, 54, 64), 22)
    img = mix(img, wood, door)
    rail = (((np.abs(ys - 34) < 4) | (np.abs(ys - 128) < 4)) & (door > 0)).astype(F)
    img = mix(img, fill(h, w, (58, 54, 50)) * (0.8 + 0.3 * fbm(h, w, 12, rng, 3))[..., None], rail)
    img = mix(img, fill(h, w, (30, 28, 26)), bolts(h, w, [(x, y) for x in (12, 30, 66, 84) for y in (34, 128)], 1.8))
    ring = ((np.abs(np.hypot(xs - 74, ys - 84) - 5) < 1.4)).astype(F)
    img = mix(img, fill(h, w, (40, 36, 30)), ring)
    frame = np.clip(blur(door, 1.5) * 3 - door * 3, 0, 1)
    img = img * (1 - 0.55 * frame)[..., None]
    from .texgen import splatter
    hand = np.clip(splatter(h, w, rng, 4, 0.12, 4), 0, 1) * (np.hypot(xs - 40, ys - 92) < 26)
    img = mix(img, fill(h, w, BLOOD), (hand > 0.5) * 0.85)
    return grain(grime(img, rng, 0.35, 3), rng, 0.03)


@dtex('d2_gate', 128, 160, desc='dust2zm: heavy gate leaf with iron bands (two tiles = double gate)')
def t_gate(rng, w, h):
    img = _planks(rng, w, h, (128, 92, 56), (76, 50, 28), 32)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    band = ((np.abs(ys - 30) < 7) | (np.abs(ys - 130) < 7)).astype(F)
    img = mix(img, fill(h, w, (60, 56, 52)) * (0.8 + 0.3 * fbm(h, w, 16, rng, 3))[..., None], band)
    edge = ((xs < 3) | (xs >= w - 3)).astype(F)
    img = img * (1 - 0.6 * edge)[..., None]
    pts = [(x, y) for y in (30, 130) for x in range(12, 128, 24)]
    img = mix(img, fill(h, w, (34, 32, 30)), bolts(h, w, pts, 2.4))
    img = mix(img, img * 0.55, np.clip(fbm(h, w, 5, rng, 4) - 0.55, 0, 1) * 1.5 * (ys > 110))
    return grain(grime(img, rng, 0.35, 3), rng, 0.03)


@dtex('d2_window', 64, 256, desc='dust2zm: plaster wall with a narrow boarded window (rows 44..140)')
def t_window(rng, w, h):
    img = _plaster(rng, w, h, SANDW, crack=8, patches=True)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    win = ((xs >= 12) & (xs < 52) & (ys >= 44) & (ys < 140)).astype(F)
    dark = fill(h, w, (16, 18, 18)) * (0.8 + 0.3 * fbm(h, w, 6, rng, 3))[..., None]
    img = mix(img, dark, win)
    boards = np.zeros((h, w), F)
    for y0, sl in ((60, 0.25), (92, -0.2), (120, 0.15)):
        boards = np.maximum(boards, ((np.abs(ys - y0 - (xs - 32) * sl) < 5) & (xs >= 8) & (xs < 56)).astype(F))
    pl = _planks(rng, w, h, (120, 88, 56), (70, 48, 28), 64)
    img = mix(img, pl, boards)
    img = img * (1 - 0.5 * np.clip(blur(win, 2) * 3 - win * 3, 0, 1))[..., None]
    sill = ((xs >= 8) & (xs < 56) & (ys >= 140) & (ys < 148)).astype(F)
    img = mix(img, fill(h, w, (150, 124, 90)), sill)
    return grain(grime(img, rng, 0.25, 3), rng, 0.03)


def _crate(rng, w, h, tone, dark, stencil=None):
    img, ring = wood_grain(h, w, rng, tone, dark, 'x', rings=20)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    fr = max(6, w // 11)
    frame = ((xs < fr) | (xs >= w - fr) | (ys < fr) | (ys >= h - fr)).astype(F)
    cv = Canvas(h, w)
    cv.poly([(fr, h - fr - fr), (fr, h - fr), (2 * fr, h - fr), (w - fr, 2 * fr), (w - fr, fr), (w - 2 * fr, fr)])
    brace = cv.mask() * (1 - frame)
    fimg, _ = wood_grain(h, w, rng, tuple(min(255, c + 12) for c in tone), dark, 'y', rings=8)
    img = mix(img, fimg, np.clip(frame + brace, 0, 1))
    hm = np.clip(frame + brace, 0, 1)
    img = apply_shade(img, shade(blur(hm, 1.0) * 0.8 + ring * 0.05, 3)) * ao(hm, 2.5, 0.5)[..., None]
    if stencil:
        cv = Canvas(h, w)
        cv.text(stencil, w * 0.3, h * 0.38, h * 0.11, 2.0)
        st = cv.mask() * (1 - hm) * (fbm(h, w, 16, rng, 3) > 0.28)
        img = mix(img, fill(h, w, (44, 34, 28)), st * 0.6)
    return grain(grime(img, rng, 0.25, 3), rng, 0.03)


@dtex('d2_crate', 128, 128, 'dust2', desc='dust2 style: big wooden crate side, VEXMIRA stencil')
def t_crate(rng, w, h):
    return _crate(rng, w, h, (176, 134, 84), (112, 76, 42), 'VX')


@dtex('d2_cratetop', 128, 128, 'dust2', desc='dust2 style: big wooden crate lid')
def t_cratetop(rng, w, h):
    return _crate(rng, w, h, (168, 128, 80), (108, 72, 40))


@dtex('d2_crate_s', 64, 64, 'dust2', desc='dust2 style: small wooden crate')
def t_crate_s(rng, w, h):
    return _crate(rng, w, h, (170, 128, 78), (108, 72, 40))


def _mil(rng, w, h, label=True):
    img = fill(h, w, (86, 96, 62)) * (0.85 + 0.2 * fbm(h, w, 6, rng, 4))[..., None]
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    rib = (((xs % 32) < 3) | (ys < 4) | (ys >= h - 4) | (xs < 4) | (xs >= w - 4)).astype(F)
    img = apply_shade(img, shade(rib * 0.7 + fbm(h, w, 16, rng, 3) * 0.1, 3))
    if label:
        cv = Canvas(h, w)
        cv.text('VX', 18, 24, 12, 2.2)
        img = mix(img, fill(h, w, (220, 210, 170)), cv.mask() * 0.85)
    return grain(grime(img, rng, 0.3, 2, (50, 46, 30)), rng, 0.04)


@dtex('d2_mil', 64, 64, 'dust2', desc='dust2 style: olive military crate')
def t_mil(rng, w, h):
    return _mil(rng, w, h)


@dtex('d2_mil2', 64, 64, 'dust2', desc='dust2 style: olive military crate (plain side)')
def t_mil2(rng, w, h):
    return _mil(rng, w, h, False)


@dtex('d2_miltop', 64, 64, 'dust2', desc='dust2 style: olive military crate lid')
def t_miltop(rng, w, h):
    return _mil(rng, w, h, False)


# ---------------------------------------------------------------- zombie-camp additions
@dtex('d2_plank', 128, 128, 'dust2', desc='camp barricade planks (bright wood)')
def t_plank(rng, w, h):
    img = _planks(rng, w, h, (160, 116, 70), (98, 64, 36), 32)
    img = mix(img, fill(h, w, (60, 58, 56)), bolts(h, w, [(x, y) for x in (16, 48, 80, 112) for y in (12, 116)], 2.0))
    return grain(grime(img, rng, 0.25, 3), rng, 0.03)


@dtex('d2_metal', 128, 128, 'dust2', desc='camp steel plate, sand dusted')
def t_metal(rng, w, h):
    img = fill(h, w, (120, 112, 100)) * (0.85 + 0.2 * fbm(h, w, 8, rng, 4))[..., None]
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    seam = (((xs % 64) < 2) | ((ys % 64) < 2)).astype(F)
    img = apply_shade(img, shade(-seam * 0.5 + fbm(h, w, 24, rng, 3) * 0.1, 3))
    pts = [(x, y) for x in range(8, 128, 16) for y in (6, 58, 70, 122)]
    img = mix(img, fill(h, w, (70, 66, 60)), bolts(h, w, pts, 1.6))
    img = mix(img, fill(h, w, (196, 168, 122)), np.clip(fbm(h, w, 6, rng, 4) - 0.55, 0, 1) * 1.2)
    return grain(img, rng, 0.03)


def _board(rng, w, h):
    """sign board: dark weathered planks in a riveted steel frame with rust runs (dust2zm)."""
    img = _planks(rng, w, h, (96, 66, 40), (54, 36, 20), 32)
    img = np.asarray(img, F)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    fw = max(4, min(w, h) // 14)
    frame = ((xs < fw) | (xs >= w - fw) | (ys < fw) | (ys >= h - fw)).astype(F)
    steel = fill(h, w, (70, 72, 74)) * (0.75 + 0.35 * fbm(h, w, 10, rng, 4))[..., None]
    img = mix(img, steel, frame)
    img = apply_shade(img, shade(blur(frame, 1.0) * 0.9, 3)) * ao(frame, 2.0, 0.5)[..., None]
    pts = [(x, y) for x in (fw / 2, w - fw / 2) for y in np.linspace(fw / 2, h - fw / 2, max(2, h // 32))]
    pts += [(x, y) for y in (fw / 2, h - fw / 2) for x in np.linspace(fw / 2, w - fw / 2, max(2, w // 32))]
    img = mix(img, fill(h, w, (34, 30, 28)), bolts(h, w, pts, max(1.2, fw * 0.3)))
    rust = streaks(h, w, rng, 10, 0.4) * np.clip(fbm(h, w, 6, rng, 3) * 1.6 - 0.5, 0, 1)
    img = mix(img, fill(h, w, (110, 52, 24)), rust * 0.5)
    return grime(img, rng, 0.25, 3)


def _glow_text(rng, w, h, img, mask, color, glow=3.0, outline=True):
    """bright text with a dark outline and a soft glow halo (reads well in a dark map)."""
    halo = np.clip(blur(mask, glow) * 2.2, 0, 1)
    img = mix(img, img * 0.4 + fill(h, w, color) * 0.35, halo * 0.8)
    if outline:
        ol = np.clip(blur(mask, 1.2) * 4, 0, 1)
        img = mix(img, fill(h, w, (8, 8, 8)), np.clip(ol - mask, 0, 1))
    hi = tuple(min(255, int(c * 1.0 + 60)) for c in color)
    return mix(img, fill(h, w, hi) * (0.85 + 0.2 * fbm(h, w, 12, rng, 3))[..., None], mask)


def _cloth(rng, w, h, tone):
    img = fill(h, w, tone) * (0.8 + 0.3 * fbm(h, w, 6, rng, 4))[..., None]
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    fold = 0.5 + 0.5 * np.sin(xs / w * 2 * math.pi * 3 + 2 * fbm(h, w, 3, rng, 2))
    img = apply_shade(img, shade(fold * 0.5, 2.5))
    weave = (((xs % 3) < 1) ^ ((ys % 3) < 1)).astype(F)
    return img * (0.95 + 0.05 * weave)[..., None]


def _drips(h, w, rng, n=10, top=0, ymax=None):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    out = np.zeros((h, w))
    ymax = ymax or h
    for _ in range(n):
        x = rng.uniform(4, w - 4)
        y0 = top + rng.uniform(0, 6)
        ln = rng.uniform(10, (ymax - top) * 0.6)
        r = rng.uniform(1.2, 2.6)
        body = (np.abs(xs - x) < r) & (ys >= y0) & (ys < y0 + ln)
        drop = (xs - x) ** 2 + (ys - (y0 + ln)) ** 2 < (r * 1.6) ** 2
        out = np.maximum(out, (body | drop).astype(F))
    return out


def _biohazard(d, cx, cy, r, k):
    import math as _m
    for i in range(3):
        a = _m.radians(90 + i * 120)
        x, y = cx + _m.cos(a) * r * 0.55, cy - _m.sin(a) * r * 0.55
        d.ellipse([(x - r * 0.48) * k, (y - r * 0.48) * k, (x + r * 0.48) * k, (y + r * 0.48) * k], fill=255)
        x2, y2 = cx + _m.cos(a) * r * 0.75, cy - _m.sin(a) * r * 0.75
        d.ellipse([(x2 - r * 0.3) * k, (y2 - r * 0.3) * k, (x2 + r * 0.3) * k, (y2 + r * 0.3) * k], fill=0)
    d.ellipse([(cx - r * 0.28) * k, (cy - r * 0.28) * k, (cx + r * 0.28) * k, (cy + r * 0.28) * k], fill=0)
    d.ellipse([(cx - r * 0.16) * k, (cy - r * 0.16) * k, (cx + r * 0.16) * k, (cy + r * 0.16) * k], fill=255)
    d.ellipse([(cx - r * 0.95) * k, (cy - r * 0.95) * k, (cx + r * 0.95) * k, (cy + r * 0.95) * k], outline=255, width=int(3 * k))


def _ctext(d, k, w, txt, y, px, bold=True):
    from .textures import _font
    f = _font(int(px * k), bold)
    bb = d.textbbox((0, 0), txt, font=f)
    while bb[2] - bb[0] > w * k * 0.92 and px > 6:          # shrink to fit
        px -= 1
        f = _font(int(px * k), bold)
        bb = d.textbbox((0, 0), txt, font=f)
    d.text(((w * k - (bb[2] - bb[0])) / 2 - bb[0], y * k - bb[1]), txt, font=f, fill=255)


BLOOD = (150, 12, 10)


@tex('d2_sign', 256, 128, 'dust2', desc='zombie board: VEXMIRA (blood, glow) / ENFEKTE BOLGE - INFECTED ZONE / MapBy: SmurfSexy')
def t_sign(rng, w, h):
    from .textures import _ss_mask
    img = _board(rng, w, h) * 0.7
    m1 = _ss_mask(w, h, lambda d, k: _ctext(d, k, w, 'VEXMIRA', 14, 40))
    drip = _drips(h, w, rng, 14, 48, 72) * np.clip(blur(m1, 6) * 4, 0, 1)
    img = _glow_text(rng, w, h, img, m1, (190, 20, 16), 4)
    img = mix(img, fill(h, w, BLOOD), drip)
    m2 = _ss_mask(w, h, lambda d, k: _ctext(d, k, w, 'ENFEKTE BOLGE - INFECTED ZONE', 72, 12))
    img = _glow_text(rng, w, h, img, m2, (120, 230, 60), 2)
    m3 = _ss_mask(w, h, lambda d, k: _ctext(d, k, w, 'MapBy: SmurfSexy', 96, 16))
    img = _glow_text(rng, w, h, img, m3, (220, 210, 190), 2)
    return grain(img, rng, 0.02)


@tex('d2_vexsign', 256, 128, 'dust2', light=(120, 255, 90, 40),
     desc='lit marquee: VEXMIRA (toxic green) + by SmurfSexy (red) - texlight, two of them in the map')
def t_vexsign(rng, w, h):
    from .textures import _ss_mask
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    img = fill(h, w, (22, 24, 26)) * (0.8 + 0.3 * fbm(h, w, 8, rng, 4))[..., None]
    fw = 8
    frame = ((xs < fw) | (xs >= w - fw) | (ys < fw) | (ys >= h - fw)).astype(F)
    img = mix(img, fill(h, w, (80, 82, 86)), frame)
    bulbs = np.zeros((h, w), F)
    for x in range(12, w - 8, 16):
        for y in (4, h - 4):
            bulbs = np.maximum(bulbs, (np.hypot(xs - x, ys - y) < 2.6).astype(F))
    for y in range(20, h - 8, 16):
        for x in (4, w - 4):
            bulbs = np.maximum(bulbs, (np.hypot(xs - x, ys - y) < 2.6).astype(F))
    img = mix(img, fill(h, w, (255, 220, 120)), np.clip(blur(bulbs, 1.5) * 2, 0, 1))
    m1 = _ss_mask(w, h, lambda d, k: _ctext(d, k, w, 'VEXMIRA', 18, 46))
    img = _glow_text(rng, w, h, img, m1, (90, 255, 60), 5)
    m2 = _ss_mask(w, h, lambda d, k: _ctext(d, k, w, 'by SmurfSexy', 80, 20))
    img = _glow_text(rng, w, h, img, m2, (255, 40, 40), 3)
    from .texgen import splatter
    img = mix(img, fill(h, w, BLOOD), (np.clip(splatter(h, w, rng, 3, 0.1, 6), 0, 1) > 0.6) * (1 - m1) * (1 - m2) * 0.7)
    return grain(img, rng, 0.015)


@tex('d2_ban_bio', 64, 128, 'dust2', desc='hanging banner: biohazard + KARANTINA / QUARANTINE')
def t_ban_bio(rng, w, h):
    from .textures import _ss_mask
    img = _cloth(rng, w, h, (150, 120, 20))
    m = _ss_mask(w, h, lambda d, k: (_biohazard(d, 32, 44, 24, k), _ctext(d, k, w, 'KARANTINA', 84, 10),
                                      _ctext(d, k, w, 'QUARANTINE', 100, 8)))
    img = mix(img, fill(h, w, (18, 16, 12)), m)
    img = mix(img, img * 0.5, _drips(h, w, rng, 6, 0, 40) * 0.5)
    return grain(grime(img, rng, 0.3, 3, (60, 40, 20)), rng, 0.03)


@tex('d2_ban_zm', 64, 128, 'dust2', desc='hanging banner: black cloth, blood hand + ZOMBIE ZONE')
def t_ban_zm(rng, w, h):
    from .textures import _ss_mask
    img = _cloth(rng, w, h, (30, 28, 30))
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    palm = ((xs - 32) ** 2 / 14 ** 2 + (ys - 52) ** 2 / 16 ** 2 < 1).astype(F)
    fingers = np.zeros((h, w))
    for i, (fx, ln) in enumerate(((20, 18), (27, 24), (34, 26), (41, 22))):
        fingers = np.maximum(fingers, ((np.abs(xs - fx) < 3) & (ys > 52 - 16 - ln) & (ys < 52)).astype(F))
    hand = np.clip(palm + fingers + _drips(h, w, rng, 8, 60, 100) * (np.abs(xs - 32) < 16), 0, 1)
    img = mix(img, fill(h, w, BLOOD), hand * np.clip(0.8 + 0.4 * fbm(h, w, 8, rng, 3), 0, 1))
    m = _ss_mask(w, h, lambda d, k: (_ctext(d, k, w, 'ZOMBIE', 98, 11), _ctext(d, k, w, 'ZONE', 112, 11)))
    img = mix(img, fill(h, w, (220, 210, 190)), m)
    return grain(img, rng, 0.03)


@tex('d2_warn', 128, 128, 'dust2', desc='hazard plate: biohazard + TEHLIKE / DANGER - ENFEKSIYON')
def t_warn(rng, w, h):
    from .textures import _ss_mask
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    img = fill(h, w, (220, 180, 30)) * (0.85 + 0.2 * fbm(h, w, 6, rng, 4))[..., None]
    stripe = ((((xs + ys) // 12) % 2 == 0) & ((ys < 14) | (ys >= h - 14))).astype(F)
    img = mix(img, fill(h, w, (20, 18, 14)), stripe)
    m = _ss_mask(w, h, lambda d, k: (_biohazard(d, 64, 52, 28, k), _ctext(d, k, w, 'TEHLIKE  DANGER', 90, 13)))
    img = mix(img, fill(h, w, (20, 18, 14)), m)
    img = mix(img, fill(h, w, BLOOD), _drips(h, w, rng, 5, 14, 70) * 0.8)
    return grain(grime(img, rng, 0.35, 3, (70, 50, 20)), rng, 0.03)


@tex('{d2_blood', 128, 128, 'dust2', desc='masked blood splatter + hand prints for walls (rendermode 4)')
def t_blood(rng, w, h):
    from .texgen import splatter
    m = np.clip(splatter(h, w, rng, 10, 0.3, 6), 0, 1)
    img = fill(h, w, BLOOD) * (0.7 + 0.4 * fbm(h, w, 12, rng, 3))[..., None]
    alpha = (m > 0.45).astype(F)
    return np.concatenate([img, alpha[..., None]], -1)


def _plate(rng, w, h, txt, color=(220, 36, 28)):
    """riveted steel plate, stencil text with glow + outline (dust2zm)."""
    from .textures import _font, _ss_mask
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    img = fill(h, w, (58, 60, 62)) * (0.8 + 0.3 * fbm(h, w, 10, rng, 4))[..., None]
    edge = ((xs < 2) | (xs >= w - 2) | (ys < 2) | (ys >= h - 2)).astype(F)
    img = apply_shade(img, shade(blur(edge, 1) * 0.8 + fbm(h, w, 24, rng, 3) * 0.1, 3))
    img = mix(img, fill(h, w, (26, 24, 22)), bolts(h, w, [(5, 5), (w - 5, 5), (5, h - 5), (w - 5, h - 5)], 1.6))
    stripe = ((((xs + ys) // 6) % 2 == 0) & ((xs < 14) | (xs >= w - 14))).astype(F)
    img = mix(img, fill(h, w, (200, 160, 30)), stripe * 0.9)

    def t(d, k):
        px = 17
        f = _font(int(px * k))
        bb = d.textbbox((0, 0), txt, font=f)
        while bb[2] - bb[0] > (w - 36) * k and px > 8:
            px -= 1
            f = _font(int(px * k))
            bb = d.textbbox((0, 0), txt, font=f)
        d.text(((w * k - (bb[2] - bb[0])) / 2 - bb[0], (h * k - (bb[3] - bb[1])) / 2 - bb[1]), txt, font=f, fill=255)
    m = _ss_mask(w, h, t)
    img = _glow_text(rng, w, h, img, m, color, 1.6)
    rust = streaks(h, w, rng, 6, 0.5) * np.clip(fbm(h, w, 6, rng, 3) * 1.6 - 0.6, 0, 1)
    return grain(mix(img, fill(h, w, (110, 52, 24)), rust * 0.5), rng, 0.02)


@tex('d2_s_kale', 256, 32, 'dust2', desc='plate: KALE / FORT')
def t_s_kale(rng, w, h):
    return _plate(rng, w, h, 'KALE  FORT')


@tex('d2_s_depo', 256, 32, 'dust2', desc='plate: DEPO / DEPOT')
def t_s_depo(rng, w, h):
    return _plate(rng, w, h, 'DEPO  DEPOT')


@tex('d2_s_kule', 256, 32, 'dust2', desc='plate: KULE / TOWER')
def t_s_kule(rng, w, h):
    return _plate(rng, w, h, 'KULE  TOWER')


@tex('d2_s_bunk', 256, 32, 'dust2', desc='plate: SIGINAK / BUNKER')
def t_s_bunk(rng, w, h):
    return _plate(rng, w, h, 'SIGINAK BUNKER')


@tex('d2_s_arena', 256, 32, 'dust2', desc='plate: BOSS ARENASI / BOSS ARENA')
def t_s_arena(rng, w, h):
    return _plate(rng, w, h, 'BOSS ARENASI  BOSS ARENA')


@tex('d2_s_laser', 256, 32, 'dust2', desc='plate: LAZER BOLGESI / LASER ZONE')
def t_s_laser(rng, w, h):
    return _plate(rng, w, h, 'LAZER BOLGESI  LASER ZONE', (255, 200, 40))


@tex('d2_s_base', 256, 32, 'dust2', desc='plate: SAVUNMA USSU / DEFENSE BASE')
def t_s_base(rng, w, h):
    return _plate(rng, w, h, 'SAVUNMA USSU  DEFENSE BASE', (90, 230, 60))


@tex('d2_s_tunel', 256, 32, 'dust2', desc='plate: GIZLI TUNEL / SECRET TUNNEL')
def t_s_tunel(rng, w, h):
    return _plate(rng, w, h, 'GIZLI TUNEL  SECRET TUNNEL', (255, 200, 40))


# ---------------------------------------------------------------- christmas (no snow)
@tex('d2_pine', 64, 64, 'dust2', desc='christmas tree needles (dark green, layered)')
def t_pine(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    img = fill(h, w, (22, 70, 34)) * (0.7 + 0.5 * fbm(h, w, 16, rng, 4))[..., None]
    needles = np.clip(np.sin((xs * 0.9 + ys * 1.7) * 1.3) * np.sin((xs * 1.6 - ys * 0.8) * 1.1), 0, 1)
    img = apply_shade(img, shade(needles * 0.4 + fbm(h, w, 32, rng, 3) * 0.3, 3))
    tier = ((ys % 16) / 16.0)
    return grain(img * (0.75 + 0.35 * tier)[..., None], rng, 0.04)


def _gift(rng, w, h, paper, ribbon):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    img = fill(h, w, paper) * (0.85 + 0.2 * fbm(h, w, 8, rng, 3))[..., None]
    dots = ((((xs + 4) % 12) - 6) ** 2 + (((ys + 4) % 12) - 6) ** 2 < 4).astype(F)
    img = mix(img, img * 1.35, dots * 0.6)
    rb = ((np.abs(xs - w / 2) < 5) | (np.abs(ys - h / 2) < 5)).astype(F)
    img = mix(img, fill(h, w, ribbon), rb)
    img = apply_shade(img, shade(blur(rb, 1) * 0.6, 3))
    return grain(img, rng, 0.03)


@tex('d2_gift_r', 64, 64, 'dust2', desc='gift box: red paper, gold ribbon')
def t_gift_r(rng, w, h):
    return _gift(rng, w, h, (150, 20, 22), (230, 190, 60))


@tex('d2_gift_g', 64, 64, 'dust2', desc='gift box: green paper, red ribbon')
def t_gift_g(rng, w, h):
    return _gift(rng, w, h, (24, 110, 46), (200, 30, 30))


@tex('d2_gift_b', 64, 64, 'dust2', desc='gift box: blue paper, silver ribbon')
def t_gift_b(rng, w, h):
    return _gift(rng, w, h, (30, 50, 140), (210, 214, 220))


def _bulb(rng, w, h, color):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    r = np.hypot(xs - w / 2 + 0.5, ys - h / 2 + 0.5) / (w / 2)
    c = np.array(color, F) / 255
    img = c * np.clip(1.25 - r * 0.6, 0, 1.3)[..., None]
    return np.clip(img + np.clip(0.6 - r, 0, 1)[..., None] * 0.8, 0, 1)


@tex('~d2_bulb_r', 16, 16, 'dust2', light=(255, 40, 30, 60), desc='christmas bulb red (texlight)')
def t_bulb_r(rng, w, h):
    return _bulb(rng, w, h, (255, 40, 30))


@tex('~d2_bulb_g', 16, 16, 'dust2', light=(40, 255, 60, 60), desc='christmas bulb green (texlight)')
def t_bulb_g(rng, w, h):
    return _bulb(rng, w, h, (40, 255, 60))


@tex('~d2_bulb_y', 16, 16, 'dust2', light=(255, 210, 60, 60), desc='christmas bulb gold (texlight)')
def t_bulb_y(rng, w, h):
    return _bulb(rng, w, h, (255, 210, 60))


@tex('~d2_bulb_b', 16, 16, 'dust2', light=(60, 120, 255, 60), desc='christmas bulb blue (texlight)')
def t_bulb_b(rng, w, h):
    return _bulb(rng, w, h, (60, 120, 255))


@tex('~d2_star', 32, 32, 'dust2', light=(255, 220, 90, 120), desc='tree-top star (texlight)')
def t_star(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    a = np.arctan2(ys - h / 2, xs - w / 2)
    r = np.hypot(xs - w / 2, ys - h / 2)
    star = (r < (6 + 8 * np.abs(np.cos(a * 2.5)))).astype(F)
    return np.clip(fill(h, w, (255, 210, 70)) * (0.5 + 0.7 * star)[..., None], 0, 1)


@tex('{d2_wreath', 64, 64, 'dust2', desc='masked christmas wreath with red bow (rendermode 4)')
def t_wreath(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    r = np.hypot(xs - 32, ys - 32)
    ring = ((r > 15) & (r < 29)).astype(F) * (fbm(h, w, 16, rng, 3) > 0.25)
    img = fill(h, w, (26, 92, 40)) * (0.6 + 0.6 * fbm(h, w, 20, rng, 3))[..., None]
    berries = np.zeros((h, w), F)
    for i in range(10):
        ang = rng.uniform(0, 2 * math.pi)
        bx_, by_ = 32 + math.cos(ang) * 22, 32 + math.sin(ang) * 22
        berries = np.maximum(berries, (np.hypot(xs - bx_, ys - by_) < 2.6).astype(F))
    img = mix(img, fill(h, w, (220, 30, 30)), berries)
    bow = (((np.abs(xs - 32) < 10) & (np.abs(ys - 50) < 5)) | (np.hypot(xs - 32, ys - 50) < 4)).astype(F)
    img = mix(img, fill(h, w, (200, 20, 20)), bow)
    alpha = np.clip(ring + berries + bow, 0, 1)
    return np.concatenate([img, (alpha > 0.5).astype(F)[..., None]], -1)


@tex('d2_xmas_ban', 256, 64, 'dust2', desc='banner: MUTLU YILLAR / HAPPY NEW YEAR - VEXMIRA')
def t_xmas_ban(rng, w, h):
    from .textures import _ss_mask
    img = _cloth(rng, w, h, (120, 16, 18))
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    hem = ((ys < 5) | (ys >= h - 5)).astype(F)
    img = mix(img, fill(h, w, (220, 190, 70)), hem)
    m = _ss_mask(w, h, lambda d, k: (_ctext(d, k, w, 'MUTLU YILLAR  HAPPY NEW YEAR', 10, 18),
                                      _ctext(d, k, w, 'VEXMIRA ZOMBIE', 38, 14)))
    img = _glow_text(rng, w, h, img, m, (240, 220, 160), 2)
    return grain(img, rng, 0.03)


# graded copies of the plaza stones (dark zombie look like the rest of the map)
def _graded_copy(new, src, amt=0.8):
    from .textures import REGISTRY as _R
    t = _R[src]

    def fn(rng, w, h, _f=t.fn):
        return _f(rng, w, h)
    dtex(new, t.w, t.h, amt=amt, desc='dust2zm graded copy of ' + src)(fn)


for _n, _s in (('d2_stone', 'vx_stone_carved'), ('d2_pave', 'vx_temple_flr'), ('d2_marble', 'vx_marble')):
    _graded_copy(_n, _s)


def _ring(rng, w, h, color, txt):
    """masked floor marker: glowing ring + label (rendermode 4 decal brush on the floor)."""
    from .textures import _ss_mask
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    r = np.hypot(xs - w / 2 + 0.5, ys - h / 2 + 0.5)
    ring = ((r > w * 0.40) & (r < w * 0.48)).astype(F)
    ticks = ((np.abs(((np.arctan2(ys - h / 2, xs - w / 2) / (2 * math.pi) * 16) % 1) - 0.5) < 0.12) &
             (r > w * 0.30) & (r < w * 0.38)).astype(F)
    m = _ss_mask(w, h, lambda d, k: _ctext(d, k, w, txt, h * 0.42, 16))
    a = np.clip(ring + ticks + m, 0, 1)
    img = fill(h, w, color) * (0.8 + 0.3 * fbm(h, w, 8, rng, 3))[..., None]
    return np.concatenate([img, (a > 0.5).astype(F)[..., None]], -1)


@tex('{d2_ring_boss', 128, 128, 'dust2', desc='floor marker: BOSS spawn ring (masked)')
def t_ring_boss(rng, w, h):
    return _ring(rng, w, h, (230, 30, 24), 'BOSS')


@tex('{d2_ring_hum', 128, 128, 'dust2', desc='floor marker: human teleport ring (masked)')
def t_ring_hum(rng, w, h):
    return _ring(rng, w, h, (60, 230, 90), 'INSAN')


@tex('d2_s_cave', 256, 32, 'dust2', desc='plate: MAGARA / CAVE')
def t_s_cave(rng, w, h):
    return _plate(rng, w, h, 'KARANLIK MAGARA  DARK CAVE', (230, 40, 30))


@tex('d2_s_bkale', 256, 32, 'dust2', desc='plate: B KALESI / B FORT')
def t_s_bkale(rng, w, h):
    return _plate(rng, w, h, 'B KALESI  B FORT', (90, 230, 60))


@tex('d2_s_balkon', 256, 32, 'dust2', desc='plate: CAM BALKON / GLASS BALCONY')
def t_s_balkon(rng, w, h):
    return _plate(rng, w, h, 'CAM BALKON  GLASS BALCONY', (120, 200, 255))


@tex('{d2_arena', 256, 256, 'dust2', desc='floor decal: big boss-arena circle with runes and biohazard (masked)')
def t_arena(rng, w, h):
    from .textures import _ss_mask
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    r = np.hypot(xs - w / 2 + 0.5, ys - h / 2 + 0.5) / (w / 2)
    ang = np.arctan2(ys - h / 2, xs - w / 2)
    rings = ((np.abs(r - 0.96) < 0.025) | (np.abs(r - 0.80) < 0.015) | (np.abs(r - 0.62) < 0.012)).astype(F)
    runes = (((np.abs(((ang / (2 * math.pi)) * 24) % 1 - 0.5) < 0.18) & (r > 0.83) & (r < 0.93)) &
             (fbm(h, w, 24, rng, 2) > 0.45)).astype(F)
    spokes = ((np.abs(((ang / (2 * math.pi)) * 8) % 1 - 0.5) < 0.02) & (r > 0.62) & (r < 0.80)).astype(F)
    m = np.clip(rings + runes + spokes, 0, 1) * (r <= 1.0)
    img = fill(h, w, (170, 24, 18)) * (0.75 + 0.35 * fbm(h, w, 10, rng, 3))[..., None]
    return np.concatenate([img, (m > 0.5).astype(F)[..., None]], -1)
