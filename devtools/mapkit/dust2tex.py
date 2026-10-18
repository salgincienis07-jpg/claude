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


@tex('d2_wall', 128, 128, 'dust2', desc='dust2 style: sun-bleached plaster wall over sandstone')
def t_wall(rng, w, h):
    return grain(grime(_plaster(rng, w, h, SANDW), rng, 0.18, 3, (120, 96, 60)), rng, 0.03)


@tex('d2_wall2', 128, 128, 'dust2', desc='dust2 style: plaster wall, older, more cracks')
def t_wall2(rng, w, h):
    return grain(grime(_plaster(rng, w, h, (196, 166, 120), crack=16), rng, 0.28, 3, (110, 88, 56)), rng, 0.035)


@tex('d2_trim', 128, 32, 'dust2', desc='dust2 style: sandstone trim course')
def t_trim(rng, w, h):
    img, n = sandstone(rng, w, h, (182, 150, 104))
    lx, ly, cid = grid_cells(h, w, 32, 32, 0.0)
    hm = bevel_mask(lx, ly, 32, 32, 2.0, 3) * (1.05 - 0.2 * fbm(h, w, 8, rng, 3))
    img = img * (0.92 + 0.14 * per_cell(cid, rng))[..., None]
    img = apply_shade(img, shade(np.clip(hm, 0, 1) * 0.8 + n * 0.2, 3)) * ao(hm, 2, 0.5)[..., None]
    return grain(grime(img, rng, 0.2, 2, (90, 72, 44)), rng, 0.03)


@tex('d2_road', 256, 256, 'dust2', desc='dust2 style: packed sand road with cart ruts and stones')
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


@tex('d2_sand', 256, 256, 'dust2', desc='dust2 style: wind-rippled sand')
def t_sand(rng, w, h):
    return _sand(rng, w, h, (206, 174, 122))


@tex('d2_sand2', 256, 256, 'dust2', desc='dust2 style: darker trodden sand')
def t_sand2(rng, w, h):
    return _sand(rng, w, h, (186, 154, 106))


@tex('d2_rock', 128, 128, 'dust2', desc='dust2 style: weathered desert rock')
def t_rock(rng, w, h):
    n = fbm(h, w, 6, rng, 6)
    img = fill(h, w, (164, 132, 94)) * (0.75 + 0.45 * n)[..., None]
    c = cracks(h, w, rng, 14, 1.4, 0.6, warp=9)
    img = apply_shade(img, shade(n * 0.7 - c * 0.4, 4))
    img = img * (1 - 0.3 * c)[..., None]
    return grain(grime(img, rng, 0.25, 3, (90, 70, 44)), rng, 0.04)


@tex('d2_ccrete', 128, 128, 'dust2', desc='dust2 style: sandy concrete')
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


@tex('d2_door', 128, 192, 'dust2', desc='dust2 style: blue-grey wooden door in a sandstone frame')
def t_door(rng, w, h):
    img = _plaster(rng, w, h, SANDW, crack=6, patches=False)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    dx0, dx1, dy0 = 20, 108, 28
    arch = (ys - dy0) < -np.sqrt(np.clip(44 ** 2 - (xs - 64) ** 2, 0, None)) + 44
    door = ((xs >= dx0) & (xs < dx1) & (ys >= dy0 - 16) & ~((ys < dy0 + 28) & arch)).astype(F)
    wood = _planks(rng, w, h, (96, 116, 128), (52, 64, 74), 22)
    img = mix(img, wood, door)
    frame = np.clip(blur(door, 2.0) * 3 - door * 3, 0, 1)
    img = img * (1 - 0.45 * frame)[..., None]
    nails = bolts(h, w, [(30, 80), (98, 80), (30, 150), (98, 150), (64, 120)], 2.0)
    img = mix(img, fill(h, w, (60, 56, 52)), nails)
    return grain(grime(img, rng, 0.25, 3), rng, 0.03)


@tex('d2_gate', 256, 256, 'dust2', desc='dust2 style: big double wooden gate with iron bands')
def t_gate(rng, w, h):
    img = _planks(rng, w, h, (140, 98, 58), (86, 56, 30), 32)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    band = ((np.abs(ys - 48) < 7) | (np.abs(ys - 208) < 7)).astype(F)
    img = mix(img, fill(h, w, (66, 62, 58)) * (0.8 + 0.3 * fbm(h, w, 16, rng, 3))[..., None], band)
    seam = (np.abs(xs - 128) < 2).astype(F)
    img = img * (1 - 0.6 * seam)[..., None]
    pts = [(x, y) for y in (48, 208) for x in range(16, 256, 32)]
    img = mix(img, fill(h, w, (40, 38, 36)), bolts(h, w, pts, 2.6))
    return grain(grime(img, rng, 0.3, 3), rng, 0.03)


@tex('d2_window', 128, 128, 'dust2', desc='dust2 style: plaster wall with a shuttered window')
def t_window(rng, w, h):
    img = _plaster(rng, w, h, SANDW, crack=6, patches=False)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    win = ((xs >= 34) & (xs < 94) & (ys >= 30) & (ys < 98)).astype(F)
    sh = _planks(rng, w, h, (86, 120, 120), (46, 66, 66), 10)
    slat = ((ys % 8) < 2).astype(F)
    sh = sh * (1 - 0.35 * slat)[..., None]
    img = mix(img, sh, win)
    img = img * (1 - 0.5 * np.clip(blur(win, 2) * 3 - win * 3, 0, 1))[..., None]
    sill = ((xs >= 28) & (xs < 100) & (ys >= 98) & (ys < 106)).astype(F)
    img = mix(img, fill(h, w, (160, 130, 92)), sill)
    return grain(grime(img, rng, 0.2, 3), rng, 0.03)


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


@tex('d2_crate', 128, 128, 'dust2', desc='dust2 style: big wooden crate side, VEXMIRA stencil')
def t_crate(rng, w, h):
    return _crate(rng, w, h, (176, 134, 84), (112, 76, 42), 'VX')


@tex('d2_cratetop', 128, 128, 'dust2', desc='dust2 style: big wooden crate lid')
def t_cratetop(rng, w, h):
    return _crate(rng, w, h, (168, 128, 80), (108, 72, 40))


@tex('d2_crate_s', 64, 64, 'dust2', desc='dust2 style: small wooden crate')
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


@tex('d2_mil', 64, 64, 'dust2', desc='dust2 style: olive military crate')
def t_mil(rng, w, h):
    return _mil(rng, w, h)


@tex('d2_mil2', 64, 64, 'dust2', desc='dust2 style: olive military crate (plain side)')
def t_mil2(rng, w, h):
    return _mil(rng, w, h, False)


@tex('d2_miltop', 64, 64, 'dust2', desc='dust2 style: olive military crate lid')
def t_miltop(rng, w, h):
    return _mil(rng, w, h, False)


# ---------------------------------------------------------------- zombie-camp additions
@tex('d2_plank', 128, 128, 'dust2', desc='camp barricade planks (bright wood)')
def t_plank(rng, w, h):
    img = _planks(rng, w, h, (160, 116, 70), (98, 64, 36), 32)
    img = mix(img, fill(h, w, (60, 58, 56)), bolts(h, w, [(x, y) for x in (16, 48, 80, 112) for y in (12, 116)], 2.0))
    return grain(grime(img, rng, 0.25, 3), rng, 0.03)


@tex('d2_metal', 128, 128, 'dust2', desc='camp steel plate, sand dusted')
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
    img = _planks(rng, w, h, (124, 84, 48), (78, 50, 28), 32)
    img = np.asarray(img, F)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    frame = ((xs < 5) | (xs >= w - 5) | (ys < 5) | (ys >= h - 5)).astype(F)
    img = mix(img, fill(h, w, (70, 44, 24)), frame)
    return grime(img, rng, 0.2, 3)


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
    d.text(((w * k - (bb[2] - bb[0])) / 2 - bb[0], y * k - bb[1]), txt, font=f, fill=255)


BLOOD = (150, 12, 10)


@tex('d2_sign', 256, 128, 'dust2', desc='zombie board: VEXMIRA (blood) / ENFEKTE BOLGE - INFECTED ZONE / MapBy: SmurfSexy')
def t_sign(rng, w, h):
    from .textures import _ss_mask
    img = _board(rng, w, h) * 0.62
    m1 = _ss_mask(w, h, lambda d, k: _ctext(d, k, w, 'VEXMIRA', 12, 38))
    m1 = np.clip(m1 + _drips(h, w, rng, 14, 44, 70) * blur(m1, 6).clip(0, 1) * 4, 0, 1)
    m2 = _ss_mask(w, h, lambda d, k: (_ctext(d, k, w, 'ENFEKTE BOLGE - INFECTED ZONE', 66, 12),
                                      _ctext(d, k, w, 'MapBy: SmurfSexy', 94, 16)))
    img = mix(img, fill(h, w, BLOOD) * (0.8 + 0.3 * fbm(h, w, 12, rng, 3))[..., None], m1)
    img = mix(img, fill(h, w, (230, 222, 205)), m2 * np.clip(0.7 + 0.6 * fbm(h, w, 16, rng, 3), 0, 1))
    return grain(img, rng, 0.02)


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


def _plate(rng, w, h, txt, color=(210, 30, 24)):
    from .textures import _font, _ss_mask
    img = _board(rng, w, h) * 0.6

    def t(d, k):
        f = _font(int(17 * k))
        bb = d.textbbox((0, 0), txt, font=f)
        d.text(((w * k - (bb[2] - bb[0])) / 2 - bb[0], (h * k - (bb[3] - bb[1])) / 2 - bb[1]), txt, font=f, fill=255)
    m = _ss_mask(w, h, t)
    return grain(mix(img, fill(h, w, color), m), rng, 0.02)


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
