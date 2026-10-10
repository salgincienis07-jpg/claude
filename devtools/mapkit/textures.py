"""Vexmira original procedural texture library (all generated from code).

Usage:
    from mapkit import textures
    textures.names()                        # all base names
    texs = textures.build(['vx_conc_clean', 'vx_lava'])  # -> {wadname: MipTex}
    textures.build_wad('/path/vexmira.wad')  # everything
    textures.TEXLIGHTS                      # {wadname: (r, g, b, intensity)}

Naming: every texture starts with vx_ after its engine prefix:
    vx_*        normal          ~vx_*  texture light (RAD .rad entry)
    {vx_*       masked          !vx_*  water-type liquid, !lava_vx = lava
    +0vx_* ..   animated frames (registered once, expanded to +0..+N)
"""
from __future__ import annotations

import hashlib
import math
import os
from dataclasses import dataclass
from typing import Callable, Dict, Iterable, List, Optional, Tuple

import numpy as np

from .texgen import (F, Canvas, ao, apply_shade, bevel_mask, blur, cracks, draw_text,
                     fbm, fill, grain, grid_cells, mix, per_cell, ramp, rgb, rivets,
                     scratches, shade, splatter, streaks, stroke_mask, text_width,
                     value_noise, value_noise_at, voronoi, white)
from .wad import MipTex, make_miptex, write_wad

VEX_PURPLE = (160, 90, 255)
VEX_CYAN = (0, 220, 255)


@dataclass
class TexDef:
    name: str
    w: int
    h: int
    fn: Callable
    cat: str
    light: Optional[Tuple[int, int, int, int]]
    dither: bool
    frames: int
    desc: str

    def wadnames(self) -> List[str]:
        if self.frames:
            return [f'+{i}{self.name}' for i in range(self.frames)]
        return [self.name]


REGISTRY: Dict[str, TexDef] = {}


def tex(name, w=128, h=128, cat='misc', light=None, dither=False, frames=0, desc=''):
    def deco(fn):
        assert name not in REGISTRY, name
        REGISTRY[name] = TexDef(name, w, h, fn, cat, light, dither, frames, desc)
        return fn
    return deco


def _rng(name: str, k: int = 0):
    s = int(hashlib.md5(f'{name}:{k}'.encode()).hexdigest()[:8], 16)
    return np.random.default_rng(s)


# =====================================================================
# shared material bases
# =====================================================================
def concrete(h, w, rng, tone=(132, 130, 125), var=0.16, pores=0.0035, rough=0.5):
    big = fbm(h, w, 3, rng, 6, 0.55)
    mid = fbm(h, w, 12, rng, 4, 0.5)
    fine = white(h, w, rng)
    t = np.array(tone, F) / 255
    img = t * (1 + (big - 0.5) * var * 2)[..., None] * (1 + (mid - 0.5) * var)[..., None]
    p = (fine < pores).astype(F) * (0.4 + 0.6 * fbm(h, w, 16, rng, 2))
    p = np.clip(blur(p, 0.5) * 2.2, 0, 1)
    hgt = mid * 0.4 + fine * 0.06 * rough - p * 0.35
    img = apply_shade(img, shade(hgt, 2.0))
    img = img * (1 - p * 0.18)[..., None]
    # aggregate specks
    sp = fine > 0.985
    img[sp] *= 1.12
    return np.clip(img, 0, 1), hgt


def wood_grain(h, w, rng, base=(150, 105, 62), dark=(90, 58, 32), along='x', rings=10.0):
    if along == 'x':
        g = fbm(h, w, 3, rng, 5, aspect=(1, 10))
        ys = np.mgrid[0:h, 0:w][0].astype(F)
        ring = np.sin((ys / h * rings + g * 3.0) * 2 * math.pi)
    else:
        g = fbm(h, w, 3, rng, 5, aspect=(10, 1))
        xs = np.mgrid[0:h, 0:w][1].astype(F)
        ring = np.sin((xs / w * rings + g * 3.0) * 2 * math.pi)
    t = np.clip(0.5 + 0.5 * ring, 0, 1) ** 2.2
    fine = fbm(h, w, 8, rng, 3, aspect=(4, 0.5) if along == 'x' else (0.5, 4))
    img = mix(fill(h, w, base), fill(h, w, dark), t * 0.65 + fine * 0.25)
    return img, t


def steel(h, w, rng, tone=(118, 124, 130), brushed=True):
    if brushed:
        b = fbm(h, w, 2, rng, 5, aspect=(1, 24))
    else:
        b = fbm(h, w, 6, rng, 4)
    m = fbm(h, w, 3, rng, 4)
    t = np.array(tone, F) / 255
    img = t * (0.9 + 0.12 * b + 0.1 * (m - 0.5))[..., None]
    sc = scratches(h, w, rng, n=int(h * w / 400), length=(4, h / 5), width=0.5)
    img = img * (1 + 0.18 * sc)[..., None]
    return np.clip(img, 0, 1).astype(F)


def rust_layer(h, w, rng, img, cover=0.45, cells=4):
    m = fbm(h, w, cells, rng, 6, 0.6)
    edge = np.clip((m - (1 - cover)) * 5, 0, 1)
    rc = ramp(fbm(h, w, 16, rng, 4), [(0, (60, 28, 14)), (0.45, (128, 58, 22)), (0.75, (170, 90, 40)), (1, (110, 70, 45))])
    pits = (white(h, w, rng) < 0.05 * edge).astype(F)
    rc = rc * (1 - 0.4 * blur(pits, 0.5))[..., None]
    out = mix(img, rc, edge)
    return out, edge


def grime(img, rng, amount=0.3, cells=4, color=(40, 34, 26)):
    g = fbm(img.shape[0], img.shape[1], cells, rng, 5, 0.55)
    t = np.clip((g - 0.45) * 2, 0, 1) * amount
    return mix(img, fill(img.shape[0], img.shape[1], color), t)


def bolts(cv_h, cv_w, pts, r=2.4):
    """Height map with domed bolt heads."""
    cv = Canvas(cv_h, cv_w)
    rivets(cv, pts, r)
    m = cv.mask()
    return blur(m, r * 0.45)


def glow(mask, sigma, color, strength=1.0):
    g = blur(mask, sigma)
    g = g / max(g.max(), 1e-6)
    return g[..., None] * (np.array(color, F) / 255) * strength


def screen_fx(img, rng, scan=0.12):
    h, w = img.shape[:2]
    ys = np.mgrid[0:h, 0:w][0]
    s = 1 - scan * (ys % 2)
    return np.clip(img * s[..., None], 0, 1)


# =====================================================================
# CONCRETE
# =====================================================================
@tex('vx_conc_clean', 256, 256, 'concrete', desc='smooth poured concrete')
def t_conc_clean(rng, w, h):
    img, _ = concrete(h, w, rng, (140, 139, 134), 0.12)
    # faint formwork pour lines
    ys = np.mgrid[0:h, 0:w][0]
    line = ((ys % 64) == 0).astype(F) + 0.5 * ((ys % 64) == 1)
    img = img * (1 - 0.08 * line)[..., None]
    return grain(img, rng, 0.03)


@tex('vx_conc_crack', 256, 256, 'concrete', desc='cracked worn concrete')
def t_conc_crack(rng, w, h):
    img, hgt = concrete(h, w, rng, (128, 126, 120), 0.2)
    c = cracks(h, w, rng, n=9, thickness=1.6, coverage=0.6)
    c2 = cracks(h, w, rng, n=30, thickness=0.9, coverage=0.4) * 0.7
    cc = np.maximum(c, c2)
    img = apply_shade(img, shade(-cc * 1.2, 2.0))
    img = img * (1 - 0.65 * cc)[..., None]
    img = grime(img, rng, 0.25, 3)
    # chipped spalls
    sp = np.clip((fbm(h, w, 6, rng, 4) - 0.78) * 8, 0, 1)
    img = mix(img, img * 0.88, sp * 0.6)
    return grain(img, rng, 0.03)


@tex('vx_conc_stain', 256, 256, 'concrete', desc='water/rust stained concrete wall')
def t_conc_stain(rng, w, h):
    img, _ = concrete(h, w, rng, (138, 134, 126), 0.16)
    s = streaks(h, w, rng, density=40)
    img = mix(img, img * rgb(70, 66, 58) * 1.8, s * 0.55)
    r = streaks(h, w, rng, density=18) * np.clip(fbm(h, w, 4, rng, 3) * 2 - 0.9, 0, 1)
    img = mix(img, fill(h, w, (120, 66, 30)), r * 0.6)
    img = grime(img, rng, 0.35, 2, (50, 52, 40))
    return grain(img, rng, 0.03)


@tex('vx_conc_panel', 128, 128, 'concrete', desc='concrete panels with tie holes')
def t_conc_panel(rng, w, h):
    img, _ = concrete(h, w, rng, (150, 148, 142), 0.12)
    lx, ly, cid = grid_cells(h, w, 64, 64)
    hm = bevel_mask(lx, ly, 64, 64, 2, 1.5)
    img = img * (0.94 + 0.12 * per_cell(cid, rng))[..., None]
    cv = Canvas(h, w)
    for px in (0, 64):
        for py in (0, 64):
            for ox, oy in ((14, 14), (50, 14), (14, 50), (50, 50)):
                cv.ellipse(px + ox, py + oy, 2.6, 2.6)
    holes = cv.mask()
    ring = np.clip(blur(holes, 1.4) * 2 - holes, 0, 1)
    hgt = hm - holes * 0.8 + ring * 0.1
    img = apply_shade(img, shade(hgt, 3.0)) * ao(hgt, 2, 0.5)[..., None]
    img = img * (1 - holes * 0.55)[..., None]
    img = mix(img, img * 0.7, streaks(h, w, rng, 30) * 0.4)
    return grain(img, rng, 0.03)


@tex('vx_bunker', 128, 128, 'concrete', desc='military bunker wall, olive band')
def t_bunker(rng, w, h):
    img, _ = concrete(h, w, rng, (128, 128, 120), 0.18)
    ys = np.mgrid[0:h, 0:w][0]
    paint = (ys >= 64).astype(F)
    band = ((ys >= 58) & (ys < 64)).astype(F)
    wear = np.clip((fbm(h, w, 8, rng, 4) - 0.62) * 6, 0, 1)
    olive = fill(h, w, (78, 88, 58)) * (0.9 + 0.2 * fbm(h, w, 6, rng, 3))[..., None]
    img = mix(img, olive, paint * (1 - wear))
    img = mix(img, fill(h, w, (200, 160, 30)), band * (1 - wear * 0.8))
    lx, ly, cid = grid_cells(h, w, 128, 32)
    img = img * (1 - 0.18 * (ly == 0))[..., None]
    img = grime(img, rng, 0.35, 3, (36, 36, 30))
    return grain(img, rng, 0.03)


# =====================================================================
# BRICK / PLASTER / WALLPAPER / WOOD
# =====================================================================
def brick(rng, w, h, palette, mortar=(150, 145, 135), bw=32, bh=16, soot=0.0):
    lx, ly, cid = grid_cells(h, w, bw, bh, 0.5)
    chip = fbm(h, w, 16, rng, 3)
    hm = bevel_mask(lx, ly, bw, bh, 2.6, 2.2)
    hm = hm * np.clip(1.3 - chip * 0.6, 0, 1)
    body = (hm > 0.05).astype(F)
    t = per_cell(cid, rng)
    col = ramp(t, palette)
    mott = fbm(h, w, 8, rng, 4)
    col = col * (0.82 + 0.3 * mott)[..., None]
    col = col * (1 + 0.1 * (white(h, w, rng) - 0.5))[..., None]
    mc = fill(h, w, mortar) * (0.85 + 0.25 * fbm(h, w, 24, rng, 3))[..., None]
    img = mix(mc, col, np.clip(hm * 3, 0, 1))
    hgt = hm * 0.8 + mott * 0.15
    img = apply_shade(img, shade(hgt, 3.0)) * ao(hgt, 2.5, 0.5)[..., None]
    if soot:
        img = grime(img, rng, soot, 3, (20, 18, 16))
    return grain(img, rng, 0.03)


@tex('vx_brick_red', 128, 128, 'brick')
def t_brick_red(rng, w, h):
    return brick(rng, w, h, [(0, (120, 44, 30)), (0.5, (150, 62, 40)), (0.8, (165, 82, 52)), (1, (110, 50, 38))])


@tex('vx_brick_grey', 128, 128, 'brick')
def t_brick_grey(rng, w, h):
    return brick(rng, w, h, [(0, (95, 95, 98)), (0.6, (128, 126, 124)), (1, (150, 146, 140))], mortar=(105, 102, 98))


@tex('vx_brick_dark', 128, 128, 'brick', desc='soot blackened brick (ruins)')
def t_brick_dark(rng, w, h):
    return brick(rng, w, h, [(0, (90, 40, 30)), (0.6, (120, 60, 42)), (1, (95, 75, 60))], mortar=(110, 104, 96), soot=0.6)


@tex('vx_plaster', 128, 128, 'wall', desc='cracked plaster with exposed brick')
def t_plaster(rng, w, h):
    base = fill(h, w, (184, 176, 160)) * (0.9 + 0.15 * fbm(h, w, 4, rng, 5))[..., None]
    br = brick(rng, w, h, [(0, (125, 50, 35)), (1, (160, 80, 50))])
    hole = np.clip((fbm(h, w, 3, rng, 6, 0.6) - 0.66) * 10, 0, 1)
    img = mix(base, br, hole)
    edge = np.clip(blur(hole, 1.2) * 2.5 - hole * 2.5, 0, 1)
    img = apply_shade(img, shade(-hole * 0.6 + fbm(h, w, 16, rng, 3) * 0.15, 3))
    img = img * (1 - 0.25 * edge)[..., None]
    c = cracks(h, w, rng, 12, 1.0, 0.5)
    img = img * (1 - 0.5 * c)[..., None]
    img = mix(img, img * 0.75, streaks(h, w, rng, 20) * 0.5)
    return grain(img, rng, 0.03)


@tex('vx_wallpaper', 128, 128, 'wall', desc='faded damask wallpaper, peeling')
def t_wallpaper(rng, w, h):
    bg = fill(h, w, (92, 108, 88))
    cv = Canvas(h, w)
    # damask medallions (big at tile centre + corners, small between)
    def medallion(cx, cy, s):
        pts = []
        for i in range(97):
            a = i / 96 * 2 * math.pi
            r = s * (10 + 5 * abs(math.cos(2 * a)) ** 0.6 + 2.5 * math.cos(6 * a))
            pts.append((cx + math.sin(a) * r * 0.8, cy - math.cos(a) * r * 1.25))
        cv.poly(pts, wrap=True)
        cv.ellipse(cx, cy, 4.5 * s, 7 * s, v=0, wrap=True)
        cv.ellipse(cx, cy, 2.2 * s, 3.5 * s, v=255, wrap=True)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cv.ellipse(cx + dx * 17 * s, cy + dy * 24 * s, 1.8 * s, 1.8 * s, wrap=True)
    medallion(32, 32, 1.35)
    medallion(96, 96, 1.35)
    for cx, cy in ((96, 32), (32, 96)):
        cv.poly([(cx, cy - 9), (cx + 5, cy), (cx, cy + 9), (cx - 5, cy)], wrap=True)
    m = cv.mask()
    img = mix(bg, fill(h, w, (160, 150, 100)), m * 0.75)
    # vertical pinstripes
    xs = np.mgrid[0:h, 0:w][1]
    img = img * (1 - 0.1 * ((xs % 64) < 2))[..., None]
    fade = fbm(h, w, 3, rng, 5)
    img = mix(img, fill(h, w, (150, 150, 120)), fade * 0.3)
    img = mix(img, img * 0.6, streaks(h, w, rng, 24) * 0.5)
    peel = np.clip((fbm(h, w, 4, rng, 6) - 0.74) * 10, 0, 1)
    plaster = fill(h, w, (176, 168, 150)) * (0.9 + 0.2 * fbm(h, w, 12, rng, 3))[..., None]
    img = mix(img, plaster, peel)
    img = apply_shade(img, shade(peel * 0.5, 3))
    return grain(img, rng, 0.03)


@tex('vx_wood_floor', 128, 128, 'wood', desc='varnished plank floor')
def t_wood_floor(rng, w, h):
    lx, ly, cid = grid_cells(h, w, 128, 16, 0.0)
    ys, xs = np.mgrid[0:h, 0:w]
    row = ys // 16
    seam_x = (per_cell(row, rng, 0, 128)).astype(np.int64)
    img, ring = wood_grain(h, w, rng, (156, 104, 60), (96, 58, 30), 'x', rings=22)
    t = per_cell(row * 2 + ((xs - seam_x) % 128 > 64), rng)
    img = img * (0.8 + 0.35 * t)[..., None]
    gap = ((ly == 0) | (((xs - seam_x) % 128) == 0) | (((xs - seam_x) % 128) == 64)).astype(F)
    hgt = -gap + ring * 0.08
    img = apply_shade(img, shade(hgt, 2.0)) * (1 - 0.55 * gap)[..., None]
    img = grime(img, rng, 0.2, 4, (50, 34, 22))
    return grain(img, rng, 0.025)


@tex('vx_wood_plank', 128, 128, 'wood', desc='weathered vertical planks')
def t_wood_plank(rng, w, h):
    img, ring = wood_grain(h, w, rng, (130, 112, 88), (70, 58, 44), 'y', rings=14)
    xs = np.mgrid[0:h, 0:w][1]
    pid = xs // 21 if False else (xs * 6) // w
    img = img * (0.78 + 0.35 * per_cell(pid, rng))[..., None]
    lx = (xs * 6) % w / 6.0
    gap = ((xs * 6) % w < 6).astype(F)
    hgt = -gap * 0.8 + ring * 0.1
    cv = Canvas(h, w)
    for i in range(6):
        cx = (i + 0.5) * w / 6
        for y in (10, 74):
            cv.ellipse(cx - 4, y, 1.2, 1.2)
            cv.ellipse(cx + 4, y, 1.2, 1.2)
    nails = cv.mask()
    img = apply_shade(img, shade(hgt + nails * 0.5, 2.5))
    img = img * (1 - 0.6 * gap)[..., None]
    img = mix(img, fill(h, w, (60, 60, 64)), nails * 0.8)
    img = grime(img, rng, 0.3, 3, (40, 40, 36))
    return grain(img, rng, 0.03)


@tex('vx_roof_tile', 128, 128, 'wall', desc='terracotta roof tiles')
def t_roof(rng, w, h):
    rows, tw = 8, 16
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    row = (ys // rows / 2).astype(np.int64)
    rh = h / 8
    row = (ys // rh).astype(np.int64)
    ly = ys - row * rh
    sx = (xs + (row % 2) * tw / 2) % w
    col = (sx // tw).astype(np.int64)
    lx = sx - col * tw
    # each tile: rounded bottom edge, curved profile across
    prof = np.sin(lx / tw * math.pi)
    bottom = np.clip((rh - ly) / 3.0, 0, 1)
    hgt = prof * 0.6 + ly / rh * 0.5
    edge = 1 - bottom
    cid = row * 20 + col
    t = per_cell(cid, rng)
    col_img = ramp(t, [(0, (150, 70, 40)), (0.5, (176, 88, 50)), (1, (130, 74, 52))])
    img = col_img * (0.8 + 0.3 * fbm(h, w, 8, rng, 4))[..., None]
    img = apply_shade(img, shade(hgt, 3.0))
    shadow = np.clip(1 - ly / 4.0, 0, 1)  # shadow cast by the tile row above
    img = img * (1 - 0.45 * shadow)[..., None] * (1 - 0.3 * (np.abs(lx - tw / 2) > tw / 2 - 1))[..., None]
    img = grime(img, rng, 0.35, 3, (40, 46, 30))
    return grain(img, rng, 0.03)


# =====================================================================
# TILES / LAB
# =====================================================================
def tiles(rng, w, h, tile=32, color=(214, 222, 226), grout=(140, 146, 150), gap=2.0):
    lx, ly, cid = grid_cells(h, w, tile, tile)
    hm = bevel_mask(lx, ly, tile, tile, gap, 1.5)
    t = per_cell(cid, rng)
    tc = fill(h, w, color) * (0.95 + 0.07 * t)[..., None] * (0.96 + 0.06 * fbm(h, w, 6, rng, 3))[..., None]
    gloss = np.clip(1 - (lx + ly) / tile, 0, 1) * 0.06
    tc = tc + gloss[..., None]
    gc = fill(h, w, grout) * (0.9 + 0.15 * fbm(h, w, 32, rng, 2))[..., None]
    img = mix(gc, tc, np.clip(hm * 4, 0, 1))
    img = apply_shade(img, shade(hm * 0.6, 3)) * ao(hm, 1.5, 0.4)[..., None]
    return img, hm, cid


@tex('vx_tile_lab', 128, 128, 'tile', desc='white lab wall tiles')
def t_tile_lab(rng, w, h):
    img, _, _ = tiles(rng, w, h)
    return grain(img, rng, 0.02)


@tex('vx_tile_dirty', 128, 128, 'tile', desc='filthy cracked lab tiles')
def t_tile_dirty(rng, w, h):
    img, hm, cid = tiles(rng, w, h, color=(196, 204, 196), grout=(96, 92, 80))
    broke = (per_cell(cid, rng) > 0.75).astype(F)
    c = cracks(h, w, rng, 14, 1.0, 0.9) * broke
    img = img * (1 - 0.6 * c)[..., None]
    miss = (per_cell(cid, rng) > 0.93).astype(F) * (hm > 0)
    conc, _ = concrete(h, w, rng, (96, 94, 88))
    img = mix(img, conc, miss)
    img = grime(img, rng, 0.55, 4, (70, 66, 40))
    img = mix(img, img * rgb(110, 60, 40) * 1.6, streaks(h, w, rng, 18) * 0.45)
    return grain(img, rng, 0.03)


@tex('vx_floor_lab', 128, 128, 'tile', desc='sci-fi lab floor plates with cyan inlay')
def t_floor_lab(rng, w, h):
    base = steel(h, w, rng, (150, 156, 164), brushed=False)
    lx, ly, cid = grid_cells(h, w, 64, 64)
    hm = bevel_mask(lx, ly, 64, 64, 3, 2)
    inner = bevel_mask(lx - 8, ly - 8, 48, 48, 0, 1.0) * ((lx >= 8) & (lx < 56) & (ly >= 8) & (ly < 56))
    img = base * (0.92 + 0.1 * per_cell(cid, rng))[..., None]
    hgt = hm * 0.6 - inner * 0.15
    # cyan inlay along the plate seams
    seam = ((lx < 2) | (lx > 61) | (ly < 2) | (ly > 61)).astype(F)
    bolt = bolts(h, w, [(x, y) for x in (6, 58, 70, 122) for y in (6, 58, 70, 122)], 2.0)
    hgt = hgt + bolt * 0.8
    img = apply_shade(img, shade(hgt, 3)) * ao(hgt, 2, 0.4)[..., None]
    img = mix(img, fill(h, w, (16, 120, 150)), seam * 0.6)
    img = grime(img, rng, 0.2, 4)
    return grain(img, rng, 0.02)


@tex('vx_wall_lab', 128, 128, 'tile', desc='white lab wall panel, purple/cyan stripe')
def t_wall_lab(rng, w, h):
    base = fill(h, w, (206, 210, 216)) * (0.94 + 0.08 * fbm(h, w, 4, rng, 4))[..., None]
    ys, xs = np.mgrid[0:h, 0:w]
    seam = ((xs % 64) < 2).astype(F) + ((ys % 128) < 2)
    hgt = -np.clip(seam, 0, 1) * 0.8
    stripe_p = ((ys >= 84) & (ys < 92)).astype(F)
    stripe_c = ((ys >= 94) & (ys < 97)).astype(F)
    img = mix(base, fill(h, w, VEX_PURPLE) * 0.8, stripe_p)
    img = mix(img, fill(h, w, (0, 190, 220)), stripe_c)
    bolt = bolts(h, w, [(x, y) for x in (6, 58, 70, 122) for y in (8, 120)], 1.6)
    img = apply_shade(img, shade(hgt + bolt * 0.6, 2.5))
    img = img * (1 - 0.35 * np.clip(seam, 0, 1))[..., None]
    img = grime(img, rng, 0.12, 3)
    return grain(img, rng, 0.02)


# =====================================================================
# METAL
# =====================================================================
@tex('vx_metal_plate', 128, 128, 'metal', desc='riveted steel plate')
def t_metal_plate(rng, w, h):
    img = steel(h, w, rng, (124, 130, 136))
    lx, ly, _ = grid_cells(h, w, 128, 128)
    hm = bevel_mask(lx, ly, 128, 128, 2, 3)
    pts = [(x, y) for x in range(8, 128, 16) for y in (6, 122)] + [(x, y) for x in (6, 122) for y in range(24, 112, 16)]
    hgt = hm * 0.6 + bolts(h, w, pts, 2.2) * 0.9
    img = apply_shade(img, shade(hgt, 3)) * ao(hgt, 2, 0.4)[..., None]
    img = grime(img, rng, 0.2, 3)
    return grain(img, rng, 0.02)


@tex('vx_metal_diam', 128, 128, 'metal', desc='diamond tread plate')
def t_metal_diam(rng, w, h):
    base = steel(h, w, rng, (140, 144, 148), brushed=False)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    c = 16
    cx = np.floor(xs / c); cy = np.floor(ys / c)
    u = xs - (cx + 0.5) * c
    v = ys - (cy + 0.5) * c
    sgn = np.where((cx + cy) % 2 == 0, 1.0, -1.0)
    a = math.pi / 4
    ru = (u * math.cos(a) + sgn * v * math.sin(a))
    rv = (-sgn * u * math.sin(a) + v * math.cos(a))
    d = (ru / 7.0) ** 2 + (rv / 1.9) ** 2
    hm = np.sqrt(np.clip(1 - d, 0, 1))
    hgt = hm * 0.9
    img = apply_shade(base, shade(hgt, 3.5))
    img = img + (hm > 0.5)[..., None] * 0.05
    img = grime(img, rng, 0.35, 4)
    return grain(img, rng, 0.02)


@tex('vx_metal_rust', 128, 128, 'metal', desc='rusted steel plate')
def t_metal_rust(rng, w, h):
    img = steel(h, w, rng, (110, 112, 114))
    img, edge = rust_layer(h, w, rng, img, 0.55)
    lx, ly, _ = grid_cells(h, w, 64, 128)
    hm = bevel_mask(lx, ly, 64, 128, 2, 2)
    pts = [(x, y) for x in (6, 58, 70, 122) for y in range(8, 128, 24)]
    hgt = hm * 0.5 + bolts(h, w, pts, 2.4) * 0.8 - edge * 0.15 + fbm(h, w, 16, rng, 3) * edge * 0.2
    img = apply_shade(img, shade(hgt, 3)) * ao(hgt, 2, 0.4)[..., None]
    img = mix(img, fill(h, w, (100, 50, 20)), streaks(h, w, rng, 30) * 0.5)
    return grain(img, rng, 0.03)


@tex('vx_metal_corr', 128, 128, 'metal', desc='corrugated galvanised sheet')
def t_metal_corr(rng, w, h):
    img = steel(h, w, rng, (150, 156, 160), brushed=False)
    xs = np.mgrid[0:h, 0:w][1].astype(F)
    prof = np.sin(xs / 16 * 2 * math.pi)
    img = apply_shade(img, shade(prof * 2.2, 1.0, light=(-0.8, -0.3, 0.8)))
    img, _ = rust_layer(h, w, rng, img, 0.25, 3)
    img = mix(img, fill(h, w, (90, 60, 40)), streaks(h, w, rng, 40) * 0.4)
    return grain(img, rng, 0.025)


@tex('vx_metal_panel', 128, 128, 'metal', desc='sci-fi gunmetal panel, cyan stripe')
def t_metal_panel(rng, w, h):
    img = steel(h, w, rng, (78, 84, 96), brushed=False)
    cv = Canvas(h, w)
    cv.poly([(10, 4), (118, 4), (124, 10), (124, 70), (118, 76), (10, 76), (4, 70), (4, 10)])
    p1 = cv.mask()
    cv = Canvas(h, w)
    cv.poly([(10, 84), (54, 84), (60, 90), (60, 118), (54, 124), (10, 124), (4, 118), (4, 90)])
    cv.poly([(74, 84), (118, 84), (124, 90), (124, 118), (118, 124), (74, 124), (68, 118), (68, 90)])
    p2 = cv.mask()
    hgt = blur(p1 + p2, 0.8) * 0.6
    ys, xs = np.mgrid[0:h, 0:w]
    vents = (((ys >= 96) & (ys < 112) & (xs >= 76) & (xs < 116) & ((ys % 4) < 2))).astype(F)
    hgt = hgt - vents * 0.5
    bolt = bolts(h, w, [(14, 14), (114, 14), (14, 66), (114, 66), (14, 114), (50, 114)], 1.8)
    img = apply_shade(img, shade(hgt + bolt, 3)) * ao(hgt, 2, 0.5)[..., None]
    stripe = ((ys >= 36) & (ys < 42) & (xs >= 14) & (xs < 114)).astype(F)
    img = mix(img, fill(h, w, VEX_CYAN) * 0.85, stripe)
    img = mix(img, fill(h, w, VEX_PURPLE) * 0.8, ((ys >= 44) & (ys < 46) & (xs >= 14) & (xs < 114)).astype(F))
    cv = Canvas(h, w)
    cv.text('VX-' + str(int(rng.integers(10, 99))), 16, 92, 10, 1.4)
    img = mix(img, fill(h, w, (210, 210, 200)), cv.mask() * 0.75)
    img = grime(img, rng, 0.2, 3)
    return grain(img, rng, 0.02)


@tex('vx_metal_dark', 128, 128, 'metal', desc='dark worn steel')
def t_metal_dark(rng, w, h):
    img = steel(h, w, rng, (70, 74, 78))
    lx, ly, _ = grid_cells(h, w, 128, 64)
    hm = bevel_mask(lx, ly, 128, 64, 2, 2)
    img = apply_shade(img, shade(hm * 0.5, 3))
    img = grime(img, rng, 0.3, 3, (20, 20, 20))
    return grain(img, rng, 0.02)


@tex('vx_metal_floor', 128, 128, 'metal', desc='bolted floor plates')
def t_metal_floor(rng, w, h):
    img = steel(h, w, rng, (112, 114, 116), brushed=False)
    lx, ly, cid = grid_cells(h, w, 64, 64)
    hm = bevel_mask(lx, ly, 64, 64, 2, 1.5)
    img = img * (0.9 + 0.15 * per_cell(cid, rng))[..., None]
    pts = [(x, y) for x in (5, 59, 69, 123) for y in (5, 59, 69, 123)]
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    # anti-slip dimples
    dimple = ((np.sin(xs / 8 * 2 * math.pi) * np.sin(ys / 8 * 2 * math.pi)) > 0.8).astype(F)
    hgt = hm * 0.5 + bolts(h, w, pts, 2.0) * 0.8 + blur(dimple, 0.6) * 0.15
    img = apply_shade(img, shade(hgt, 3)) * ao(hgt, 2, 0.4)[..., None]
    img = grime(img, rng, 0.35, 4)
    return grain(img, rng, 0.02)


@tex('vx_frost_metal', 128, 128, 'metal', desc='frost-covered steel plate')
def t_frost_metal(rng, w, h):
    img = t_metal_plate(rng, w, h)
    f = fbm(h, w, 4, rng, 6, 0.6)
    lx, ly, _ = grid_cells(h, w, 128, 128)
    edge = np.clip(1 - np.minimum(np.minimum(lx, 127 - lx), np.minimum(ly, 127 - ly)) / 30, 0, 1)
    cover = np.clip((f * 0.7 + edge * 0.7 - 0.72) * 4, 0, 1)
    cryst = fbm(h, w, 32, rng, 3)
    frost = ramp(cryst, [(0, (190, 210, 230)), (0.6, (225, 236, 245)), (1, (250, 252, 255))])
    img = mix(img, frost, cover * 0.9)
    img = apply_shade(img, shade(cover * 0.4 + cryst * cover * 0.2, 3))
    return grain(img, rng, 0.02)


@tex('vx_trim_metal', 128, 32, 'metal', desc='metal trim strip with bolts')
def t_trim_metal(rng, w, h):
    img = steel(h, w, rng, (100, 104, 110))
    ys = np.mgrid[0:h, 0:w][0].astype(F)
    hgt = np.clip(np.minimum(ys, h - 1 - ys) / 3, 0, 1) * 0.6
    hgt = hgt + bolts(h, w, [(x, 16) for x in range(8, 128, 32)], 2.4)
    img = apply_shade(img, shade(hgt, 3))
    return grain(grime(img, rng, 0.2, 2), rng, 0.02)


def hazard(rng, w, h, period=32):
    ys, xs = np.mgrid[0:h, 0:w]
    s = (((xs + ys) % period) < period / 2).astype(F)
    s = blur(s, 0.5)
    img = mix(fill(h, w, (28, 28, 28)), fill(h, w, (228, 178, 24)), s)
    wear = np.clip((fbm(h, w, 8, rng, 5) - 0.66) * 6, 0, 1)
    sc = scratches(h, w, rng, 40, (4, 20), 0.8)
    img = mix(img, steel(h, w, rng, (130, 130, 128)), np.clip(wear + sc * 0.6, 0, 1))
    return grime(img, rng, 0.3, 4)


@tex('vx_hazard', 128, 128, 'metal', desc='yellow/black hazard stripes')
def t_hazard(rng, w, h):
    return grain(hazard(rng, w, h), rng, 0.02)


@tex('vx_trim_hazard', 128, 32, 'metal', desc='hazard stripe trim')
def t_trim_hazard(rng, w, h):
    img = hazard(rng, w, h, 32)
    ys = np.mgrid[0:h, 0:w][0]
    edge = ((ys < 3) | (ys >= h - 3)).astype(F)
    img = mix(img, steel(h, w, rng, (90, 92, 96)), edge)
    img = apply_shade(img, shade(-edge * 0.5, 2))
    return grain(img, rng, 0.02)


# =====================================================================
# CRATES / CONTAINERS
# =====================================================================
@tex('vx_crate_wood', 128, 128, 'crate', desc='wooden supply crate')
def t_crate_wood(rng, w, h):
    img, ring = wood_grain(h, w, rng, (168, 124, 76), (110, 74, 40), 'x', rings=26)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    plank = (ys // 21.4).astype(np.int64)
    img = img * (0.85 + 0.25 * per_cell(plank, rng))[..., None]
    gaps = ((ys % 21.4) < 1.2).astype(F)
    fr = 12
    frame = ((xs < fr) | (xs >= w - fr) | (ys < fr) | (ys >= h - fr)).astype(F)
    cv = Canvas(h, w)
    cv.poly([(fr, h - fr - 14), (fr, h - fr), (fr + 14, h - fr), (w - fr, fr + 14), (w - fr, fr), (w - fr - 14, fr)])
    brace = cv.mask() * (1 - frame)
    fimg, _ = wood_grain(h, w, rng, (178, 132, 82), (120, 80, 44), 'y', rings=10)
    fimg2, _ = wood_grain(h, w, rng, (178, 132, 82), (120, 80, 44), 'x', rings=10)
    vert = ((xs < fr) | (xs >= w - fr)).astype(F)
    fimg = mix(fimg2, fimg, vert)
    img = mix(img, fimg, np.clip(frame + brace, 0, 1))
    hm = np.clip(frame + brace, 0, 1)
    edge = blur(hm, 1.0)
    hgt = edge * 0.8 - gaps * 0.5 * (1 - hm) + ring * 0.05
    nails = bolts(h, w, [(6, 6), (122, 6), (6, 122), (122, 122), (6, 64), (122, 64), (64, 6), (64, 122)], 1.6)
    img = apply_shade(img, shade(hgt, 3.0)) * ao(hgt, 2.5, 0.6)[..., None]
    img = mix(img, fill(h, w, (70, 70, 72)), nails)
    cv = Canvas(h, w)
    cv.text('VX', 30, 44, 14, 2.4)
    st = cv.mask() * (1 - hm) * (fbm(h, w, 16, rng, 3) > 0.3)
    img = mix(img, fill(h, w, (40, 30, 26)), st * 0.6)
    img = grime(img, rng, 0.25, 3)
    return grain(img, rng, 0.03)


@tex('vx_crate_mil', 128, 128, 'crate', desc='military ammo/supply crate (olive)')
def t_crate_mil(rng, w, h):
    base = fill(h, w, (84, 94, 58)) * (0.9 + 0.15 * fbm(h, w, 6, rng, 4))[..., None]
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    fr = 10
    frame = ((xs < fr) | (xs >= w - fr) | (ys < fr) | (ys >= h - fr)).astype(F)
    rib = ((np.abs(ys - 64) < 4)).astype(F)
    hm = np.clip(frame + rib, 0, 1)
    hgt = blur(hm, 1.0) * 0.8
    hgt = hgt + bolts(h, w, [(5, 5), (123, 5), (5, 123), (123, 123), (5, 64), (123, 64)], 2.0)
    img = apply_shade(base, shade(hgt, 3)) * ao(hgt, 2.5, 0.5)[..., None]
    cv = Canvas(h, w)
    cv.text('VX-07', 0, 0, 1)  # warm-up no-op (keeps rng stable)
    cv = Canvas(h, w)
    tw = text_width('VX-07', 18)
    cv.text('VX-07', (w - tw) / 2, 24, 18, 2.6)
    tw2 = text_width('VEXMIRA', 9)
    cv.text('VEXMIRA', (w - tw2) / 2, 80, 9, 1.4)
    tw3 = text_width('SUPPLY 7.62', 7)
    cv.text('SUPPLY 7.62', (w - tw3) / 2, 96, 7, 1.1)
    st = cv.mask() * np.clip(fbm(h, w, 12, rng, 3) * 1.6, 0, 1)
    img = mix(img, fill(h, w, (215, 205, 160)), st * 0.85)
    wear = np.clip((fbm(h, w, 10, rng, 4) - 0.7) * 5, 0, 1) * blur(hm, 2) * 1.5
    img = mix(img, steel(h, w, rng, (130, 130, 125)), np.clip(wear, 0, 1))
    img = grime(img, rng, 0.25, 3)
    return grain(img, rng, 0.025)


def container(rng, w, h, color, label):
    xs = np.mgrid[0:h, 0:w][1].astype(F)
    ys = np.mgrid[0:h, 0:w][0].astype(F)
    p = (xs % 16) / 16
    prof = np.clip(np.minimum(p, 1 - p) * 6 - 0.5, 0, 1)   # trapezoid ribs
    rail = ((ys < 8) | (ys >= h - 8)).astype(F)
    base = fill(h, w, color) * (0.88 + 0.2 * fbm(h, w, 4, rng, 5))[..., None]
    hgt = prof * 1.2 * (1 - rail) + rail * 1.5
    img = apply_shade(base, shade(hgt, 1.6, light=(-0.8, -0.4, 0.8))) * ao(hgt, 2, 0.3)[..., None]
    img = mix(img, img * 0.8, rail)
    img, _ = rust_layer(h, w, rng, img, 0.18, 6)
    img = mix(img, fill(h, w, (110, 52, 22)), streaks(h, w, rng, 50) * 0.5)
    cv = Canvas(h, w)
    tw = text_width(label, 20, 1.4)
    cv.text(label, w - tw - 24, 22, 20, 3.0, spacing=1.4)
    tw2 = text_width('VEXMIRA LOGISTICS', 8)
    cv.text('VEXMIRA LOGISTICS', w - tw2 - 24, 50, 8, 1.3)
    cv.text('MAX GROSS 30480 KG', 20, h - 30, 6, 1.0)
    st = cv.mask() * np.clip(fbm(h, w, 16, rng, 3) * 1.8, 0, 1)
    img = mix(img, fill(h, w, (230, 228, 220)), st * 0.85)
    img = grime(img, rng, 0.25, 3)
    return grain(img, rng, 0.025)


@tex('vx_cont_red', 256, 128, 'container')
def t_cont_red(rng, w, h):
    return container(rng, w, h, (150, 38, 30), 'VXMU 204')


@tex('vx_cont_blue', 256, 128, 'container')
def t_cont_blue(rng, w, h):
    return container(rng, w, h, (34, 70, 140), 'VXMU 517')


@tex('vx_cont_green', 256, 128, 'container')
def t_cont_green(rng, w, h):
    return container(rng, w, h, (44, 104, 60), 'VXMU 338')


@tex('vx_cont_orange', 256, 128, 'container')
def t_cont_orange(rng, w, h):
    return container(rng, w, h, (196, 104, 28), 'VXMU 871')


@tex('vx_cont_end', 128, 128, 'container', desc='container doors (end)')
def t_cont_end(rng, w, h):
    base = fill(h, w, (70, 80, 92)) * (0.9 + 0.2 * fbm(h, w, 4, rng, 4))[..., None]
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    p = (ys % 12) / 12
    prof = np.clip(np.minimum(p, 1 - p) * 6 - 0.5, 0, 1) * 0.5
    seam = (np.abs(xs - 64) < 1.5).astype(F)
    bars = np.zeros((h, w), F)
    for bx in (20, 46, 82, 108):
        bars = np.maximum(bars, (np.abs(xs - bx) < 2.5).astype(F))
    hand = ((ys > 58) & (ys < 70) & ((np.abs(xs - 30) < 6) | (np.abs(xs - 98) < 6))).astype(F)
    frame = ((xs < 6) | (xs >= w - 6) | (ys < 6) | (ys >= h - 6)).astype(F)
    hgt = prof - seam + bars * 1.2 + hand * 1.4 + frame * 1.0
    img = apply_shade(base, shade(hgt, 2)) * ao(hgt, 2, 0.4)[..., None]
    img, _ = rust_layer(h, w, rng, img, 0.25)
    img = grime(img, rng, 0.25, 3)
    return grain(img, rng, 0.025)


# =====================================================================
# GROUND / NATURE
# =====================================================================
@tex('vx_asphalt', 256, 256, 'ground')
def t_asphalt(rng, w, h):
    n = fbm(h, w, 4, rng, 6)
    img = fill(h, w, (62, 62, 64)) * (0.85 + 0.3 * n)[..., None]
    wn = white(h, w, rng)
    img[wn > 0.93] *= 1.35
    img[wn < 0.05] *= 0.6
    img = mix(img, fill(h, w, (40, 40, 42)), np.clip((fbm(h, w, 3, rng, 4) - 0.6) * 4, 0, 1) * 0.6)
    c = cracks(h, w, rng, 8, 1.4, 0.5)
    img = mix(img, fill(h, w, (22, 22, 24)), c * 0.9)
    oil = np.clip((fbm(h, w, 5, rng, 4) - 0.78) * 6, 0, 1)
    img = mix(img, fill(h, w, (26, 24, 28)), oil * 0.6)
    img = apply_shade(img, shade(fbm(h, w, 64, rng, 2) * 0.25 - c * 0.4, 2))
    return grain(img, rng, 0.03)


@tex('vx_road_line', 128, 128, 'ground', desc='asphalt with double yellow line (along Y)')
def t_road_line(rng, w, h):
    img = t_asphalt(rng, 128, 128)
    xs = np.mgrid[0:h, 0:w][1]
    line = (((xs >= 54) & (xs < 61)) | ((xs >= 67) & (xs < 74))).astype(F)
    line = blur(line, 0.4)
    wear = np.clip(fbm(h, w, 12, rng, 4) * 1.5 - 0.2, 0, 1)
    img = mix(img, fill(h, w, (210, 170, 40)), line * wear * 0.9)
    return grain(img, rng, 0.02)


@tex('vx_dirt', 128, 128, 'ground')
def t_dirt(rng, w, h):
    n = fbm(h, w, 4, rng, 6)
    img = ramp(n, [(0, (70, 52, 36)), (0.5, (108, 82, 56)), (1, (136, 110, 80))])
    f1, f2, idx = voronoi(h, w, 70, rng)
    peb_on = per_cell(idx, rng) > 0.55
    psize = per_cell(idx, rng, 2.0, 6.5)
    peb = np.clip(1 - f1 / psize, 0, 1) * peb_on
    peb = peb * (0.6 + 0.4 * fbm(h, w, 24, rng, 2))
    pc = ramp(per_cell(idx, rng), [(0, (110, 104, 96)), (1, (150, 140, 124))])
    img = mix(img, pc, np.clip(peb * 3, 0, 1))
    hgt = n * 0.5 + np.sqrt(peb) * 0.8 + fbm(h, w, 32, rng, 2) * 0.2
    img = apply_shade(img, shade(hgt, 3)) * ao(hgt, 2, 0.5)[..., None]
    return grain(img, rng, 0.04)


@tex('vx_grass', 128, 128, 'ground')
def t_grass(rng, w, h):
    n = fbm(h, w, 4, rng, 5)
    img = ramp(n, [(0, (42, 58, 24)), (0.6, (58, 80, 30)), (1, (78, 92, 40))])
    dirt = np.clip((fbm(h, w, 3, rng, 5) - 0.72) * 5, 0, 1)
    img = mix(img, fill(h, w, (96, 76, 50)), dirt * 0.8)
    layers = [((48, 70, 26), 600), ((72, 100, 36), 700), ((110, 132, 56), 450), ((150, 150, 80), 120)]
    for col, n_bl in layers:
        cv = Canvas(h, w)
        for _ in range(n_bl):
            x, y = rng.random() * w, rng.random() * h
            a = -math.pi / 2 + rng.normal(0, 0.5)
            L = rng.uniform(4, 10)
            cv.line([(x, y), (x + math.cos(a) * L, y + math.sin(a) * L)], rng.uniform(0.6, 1.2), wrap=True, joint=False)
        m = cv.mask()
        img = mix(img, fill(h, w, col), m * 0.9)
    img = apply_shade(img, shade(n * 0.4, 2))
    return grain(img, rng, 0.04)


@tex('vx_snow', 256, 256, 'ground')
def t_snow(rng, w, h):
    n = fbm(h, w, 4, rng, 6, 0.55)
    img = ramp(n, [(0, (196, 208, 226)), (0.5, (226, 233, 242)), (1, (244, 247, 252))])
    hgt = n * 1.2 + fbm(h, w, 32, rng, 3) * 0.1
    img = apply_shade(img, shade(hgt, 3, amount=0.6))
    sp = white(h, w, rng) > 0.996
    img[sp] = 1.0
    return grain(img, rng, 0.015)


@tex('vx_snow_rock', 128, 128, 'ground', desc='rock with snow on top surfaces')
def t_snow_rock(rng, w, h):
    rock = t_rock(rng, w, h)
    n = fbm(h, w, 4, rng, 6)
    snowmask = np.clip((n - 0.45) * 5, 0, 1)
    sn = ramp(fbm(h, w, 16, rng, 3), [(0, (205, 215, 230)), (1, (246, 248, 252))])
    img = mix(rock, sn, snowmask)
    return grain(img, rng, 0.02)


@tex('vx_ice', 128, 128, 'ground', desc='frozen ice sheet with cracks')
def t_ice(rng, w, h):
    n = fbm(h, w, 3, rng, 6)
    img = ramp(n, [(0, (70, 120, 160)), (0.5, (120, 170, 205)), (1, (190, 222, 240))])
    c = cracks(h, w, rng, 10, 1.1, 0.8, warp=4)
    c2 = cracks(h, w, rng, 24, 0.7, 0.5, warp=3) * 0.6
    cc = np.maximum(c, c2)
    img = mix(img, fill(h, w, (235, 245, 255)), cc * 0.8)
    deep = blur(cc, 3) * 0.6
    img = mix(img, fill(h, w, (60, 100, 140)), deep * 0.3)
    bub = (white(h, w, rng) > 0.992).astype(F)
    img = mix(img, fill(h, w, (230, 240, 250)), blur(bub, 0.5) * 2)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    sheen = np.clip(np.sin((xs + ys) / w * 2 * math.pi * 2) * 0.5 + 0.5, 0, 1) ** 6 * 0.12
    img = img + sheen[..., None]
    return grain(img, rng, 0.015)


@tex('vx_rock', 256, 256, 'ground', desc='faceted grey-brown rock')
def t_rock(rng, w, h):
    f1, f2, idx = voronoi(h, w, 28 if w >= 256 else 14, rng)
    n = fbm(h, w, 6, rng, 6)
    t = per_cell(idx, rng)
    img = ramp(t * 0.5 + n * 0.5, [(0, (78, 74, 68)), (0.5, (118, 112, 102)), (1, (146, 138, 124))])
    facet = f1 / (f1 + f2 + 1e-3)
    gap = np.clip(1 - (f2 - f1) / 2.5, 0, 1)
    hgt = (1 - facet) * 1.2 + n * 0.8 - gap * 0.8
    img = apply_shade(img, shade(hgt, 3)) * ao(hgt, 3, 0.6)[..., None]
    img = img * (1 - 0.5 * gap)[..., None]
    moss = np.clip((fbm(h, w, 4, rng, 4) - 0.7) * 4, 0, 1)
    img = mix(img, img * rgb(110, 130, 80) * 1.4, moss * 0.4)
    return grain(img, rng, 0.03)


@tex('vx_sand', 256, 256, 'ground', desc='rippled sand')
def t_sand(rng, w, h):
    n = fbm(h, w, 3, rng, 5)
    ys = np.mgrid[0:h, 0:w][0].astype(F)
    warp = (fbm(h, w, 3, rng, 3) - 0.5) * 20
    rip = np.sin((ys + warp) / h * 2 * math.pi * 14)
    img = ramp(n, [(0, (176, 150, 104)), (0.5, (200, 176, 128)), (1, (218, 196, 150))])
    hgt = rip * 0.35 + n * 0.4
    img = apply_shade(img, shade(hgt, 2.5))
    wn = white(h, w, rng)
    img[wn > 0.97] *= 0.8
    img[wn < 0.02] *= 1.15
    return grain(img, rng, 0.03)


@tex('vx_lavarock', 128, 128, 'ground', light=(255, 110, 30, 180), desc='basalt with glowing magma cracks (texlight)')
def t_lavarock(rng, w, h):
    f1, f2, idx = voronoi(h, w, 16, rng)
    n = fbm(h, w, 6, rng, 5)
    img = ramp(n, [(0, (24, 20, 20)), (1, (66, 56, 52))])
    gap = np.clip(1 - (f2 - f1) / 3.0, 0, 1)
    hgt = (1 - f1 / (f1 + f2 + 1e-3)) * 1.0 + n * 0.6
    img = apply_shade(img, shade(hgt, 3))
    hot = ramp(np.clip(gap, 0, 1), [(0, (60, 10, 0)), (0.5, (230, 80, 10)), (1, (255, 210, 90))])
    img = mix(img, hot, np.clip(gap * 1.3, 0, 1))
    img = img + glow(gap, 2.5, (200, 60, 0), 0.35)
    return np.clip(grain(img, rng, 0.02), 0, 1)


# =====================================================================
# MARBLE / TEMPLE
# =====================================================================
def marble(rng, w, h, base_stops, vein_col, vein2=None, tile=64):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    turb = fbm(h, w, 3, rng, 6, 0.6)
    t = np.sin((xs / w * 2 + ys / h * 1) * 2 * math.pi + turb * 9)
    vein = np.clip(1 - np.abs(t) / 0.13, 0, 1) ** 1.2
    vein = np.maximum(vein, np.clip(1 - np.abs(t) / 0.45, 0, 1) * 0.3)
    vein = vein * (0.5 + 0.7 * fbm(h, w, 6, rng, 3))
    img = ramp(fbm(h, w, 4, rng, 5), base_stops)
    img = mix(img, fill(h, w, vein_col), vein * 0.85)
    if vein2 is not None:
        t2 = np.sin((xs / w * 1 - ys / h * 2) * 2 * math.pi + fbm(h, w, 4, rng, 6) * 7)
        v2 = np.clip(1 - np.abs(t2) / 0.07, 0, 1)
        img = mix(img, fill(h, w, vein2), np.clip(v2, 0, 1) * 0.6)
    lx, ly, cid = grid_cells(h, w, tile, tile)
    hm = bevel_mask(lx, ly, tile, tile, 1.5, 1.0)
    img = img * (0.95 + 0.08 * per_cell(cid, rng))[..., None]
    img = apply_shade(img, shade(hm * 0.4, 3)) * (0.75 + 0.25 * np.clip(hm * 4, 0, 1))[..., None]
    return grain(img, rng, 0.015)


@tex('vx_marble', 128, 128, 'temple', desc='white marble tiles, grey/gold veins')
def t_marble(rng, w, h):
    return marble(rng, w, h, [(0, (205, 200, 190)), (1, (232, 228, 220))], (120, 118, 116), (180, 150, 80))


@tex('vx_marble_dark', 128, 128, 'temple', desc='dark green-black marble, pale veins')
def t_marble_dark(rng, w, h):
    return marble(rng, w, h, [(0, (26, 40, 34)), (1, (52, 70, 60))], (170, 190, 180), (200, 170, 90))


def sandstone(rng, w, h, tone=(188, 160, 116)):
    n = fbm(h, w, 6, rng, 6)
    img = ramp(n, [(0, tuple(int(c * 0.78) for c in tone)), (0.5, tone), (1, tuple(min(255, int(c * 1.12)) for c in tone))])
    ys = np.mgrid[0:h, 0:w][0].astype(F)
    strata = np.sin(ys / h * 2 * math.pi * 9 + fbm(h, w, 3, rng, 3) * 6) * 0.04
    img = img * (1 + strata)[..., None]
    pits = (white(h, w, rng) < 0.02).astype(F)
    img = img * (1 - blur(pits, 0.6) * 0.8)[..., None]
    return img, n


@tex('vx_stone_carved', 128, 128, 'temple', desc='large dressed sandstone blocks')
def t_stone_carved(rng, w, h):
    img, n = sandstone(rng, w, h)
    lx, ly, cid = grid_cells(h, w, 64, 32, 0.5)
    hm = bevel_mask(lx, ly, 64, 32, 2.5, 4) * (1.1 - 0.25 * fbm(h, w, 12, rng, 3))
    img = img * (0.9 + 0.16 * per_cell(cid, rng))[..., None]
    hgt = np.clip(hm, 0, 1) * 0.8 + n * 0.2
    img = apply_shade(img, shade(hgt, 3)) * ao(hgt, 3, 0.6)[..., None]
    img = grime(img, rng, 0.25, 3, (70, 60, 40))
    return grain(img, rng, 0.03)


@tex('vx_temple_orn', 128, 128, 'temple', desc='carved frieze with meander + rosettes')
def t_temple_orn(rng, w, h):
    img, n = sandstone(rng, w, h, (196, 168, 120))
    cv = Canvas(h, w)
    # meander (greek key) in the band y 44..84, period 32
    for x0 in range(0, 128, 32):
        pts = [(x0, 80), (x0, 48), (x0 + 24, 48), (x0 + 24, 72), (x0 + 10, 72), (x0 + 10, 58), (x0 + 16, 58)]
        cv.line(pts, 3.2, wrap=True, joint=False)
        cv.line([(x0, 80), (x0 + 32, 80)], 3.2, wrap=True, joint=False)
    key = cv.mask()
    cv = Canvas(h, w)
    for cx in (16, 48, 80, 112):
        for cy in (18, 110):
            cv.ellipse(cx, cy, 9, 9)
    ros_out = cv.mask()
    cv = Canvas(h, w)
    for cx in (16, 48, 80, 112):
        for cy in (18, 110):
            for k in range(8):
                a = k / 8 * 2 * math.pi
                cv.ellipse(cx + math.cos(a) * 5, cy + math.sin(a) * 5, 2.4, 2.4)
            cv.ellipse(cx, cy, 2.2, 2.2)
    petals = cv.mask()
    ys = np.mgrid[0:h, 0:w][0]
    bands = (((ys >= 36) & (ys < 40)) | ((ys >= 88) & (ys < 92))).astype(F)
    border = (((ys >= 0) & (ys < 3)) | (ys >= 125)).astype(F)
    hgt = 1.0 - key * 0.7 - ros_out * 0.6 + petals * 0.5 + bands * 0.5 - border * 0.6 + n * 0.15
    img = apply_shade(img, shade(hgt, 3.5)) * ao(hgt, 2.5, 0.7)[..., None]
    # traces of ancient paint in recesses
    img = mix(img, fill(h, w, (40, 120, 120)), np.clip(key * 1.2, 0, 1) * 0.35)
    img = mix(img, fill(h, w, (180, 140, 50)), petals * 0.35)
    img = grime(img, rng, 0.25, 3, (70, 60, 40))
    return grain(img, rng, 0.03)


@tex('vx_temple_glyph', 128, 128, 'temple', desc='stone wall with carved glyphs')
def t_temple_glyph(rng, w, h):
    img, n = sandstone(rng, w, h, (176, 150, 112))
    cv = Canvas(h, w)
    for gy in range(3):
        for gx in range(3):
            cx, cy = 22 + gx * 42, 22 + gy * 42
            # frame
            cv.line([(cx - 16, cy - 16), (cx + 16, cy - 16), (cx + 16, cy + 16), (cx - 16, cy + 16), (cx - 16, cy - 16)], 1.6)
            # random glyph from strokes on a 3x3 point lattice
            P = [(cx + (i - 1) * 9, cy + (j - 1) * 9) for j in range(3) for i in range(3)]
            for _ in range(int(rng.integers(3, 6))):
                a, b = rng.choice(9, 2, replace=False)
                cv.line([P[a], P[b]], 2.6)
            if rng.random() < 0.5:
                cv.ellipse(cx, cy, 3, 3)
    m = cv.mask()
    hgt = -m * 0.8 + n * 0.2
    img = apply_shade(img, shade(hgt, 3.5)) * ao(hgt, 2, 0.6)[..., None]
    img = mix(img, fill(h, w, (30, 140, 150)), m * 0.4)
    img = grime(img, rng, 0.3, 3, (60, 50, 35))
    return grain(img, rng, 0.03)


@tex('vx_pillar', 128, 128, 'temple', desc='fluted column surface (wrap around prisms)')
def t_pillar(rng, w, h):
    img, n = sandstone(rng, w, h, (204, 186, 150))
    xs = np.mgrid[0:h, 0:w][1].astype(F)
    fl = np.cos((xs % 16) / 16 * 2 * math.pi)
    hgt = -np.clip(fl, -1, 0.3) * 0.8 + n * 0.2
    img = apply_shade(img, shade(hgt, 2.5, light=(-0.9, -0.2, 0.7))) * ao(hgt, 2, 0.4)[..., None]
    img = grime(img, rng, 0.3, 2, (70, 60, 40))
    return grain(img, rng, 0.025)


@tex('vx_temple_flr', 128, 128, 'temple', desc='worn temple floor slabs with moss')
def t_temple_flr(rng, w, h):
    img, n = sandstone(rng, w, h, (160, 140, 110))
    lx, ly, cid = grid_cells(h, w, 64, 64)
    hm = bevel_mask(lx, ly, 64, 64, 3, 3)
    img = img * (0.88 + 0.2 * per_cell(cid, rng))[..., None]
    c = cracks(h, w, rng, 8, 1.2, 0.5)
    hgt = hm * 0.7 - c * 0.6 + n * 0.2
    img = apply_shade(img, shade(hgt, 3)) * ao(hgt, 2.5, 0.6)[..., None]
    img = img * (1 - 0.5 * c)[..., None]
    moss = np.clip((1 - np.clip(hm * 3, 0, 1)) * 0.7 + (fbm(h, w, 6, rng, 4) - 0.6) * 2, 0, 1)
    img = mix(img, fill(h, w, (60, 84, 40)), moss * 0.55)
    return grain(img, rng, 0.03)


# =====================================================================
# LIQUIDS / ANIMATED
# =====================================================================
def _loop_noise(h, w, rng, cells, octaves, frames, radius):
    """Return a callable f(k) giving a tileable fbm whose domain moves on a
    circle so frame `frames` == frame 0 (seamless loop)."""
    grids = []
    c = cells
    for o in range(octaves):
        grids.append((c, rng.random((c, c)).astype(F)))
        c *= 2
    ys, xs = np.mgrid[0:h, 0:w].astype(F)

    def f(k, phase=0.0):
        a = 2 * math.pi * k / frames + phase
        ox, oy = math.cos(a) * radius, math.sin(a) * radius
        out = np.zeros((h, w), F)
        amp, tot = 1.0, 0.0
        for i, (cc, g) in enumerate(grids):
            s = 1.0 / (1 + i * 0.6)
            out += amp * value_noise_at(g, (xs + ox * s) * cc / w, (ys + oy * s) * cc / h)
            tot += amp
            amp *= 0.5
        return out / tot
    return f


@tex('vx_lava', 128, 128, 'liquid', light=(255, 120, 40, 300), frames=10, desc='animated lava (+0..+9), use with trigger_hurt')
def t_lava(rng, w, h):
    hot = _loop_noise(h, w, rng, 4, 5, 10, 6.0)
    f1, f2, idx = voronoi(h, w, 18, rng)
    plate = np.clip((f2 - f1 - 2) / 6, 0, 1) * (per_cell(idx, rng) > 0.25)
    crust_n = fbm(h, w, 12, rng, 4)
    frames = []
    for k in range(10):
        t = hot(k)
        t = (t - t.min()) / (t.max() - t.min() + 1e-6)
        pulse = 0.5 + 0.5 * math.sin(2 * math.pi * k / 10)
        heat = np.clip(t * 1.1 + 0.08 * pulse - plate * 0.9, 0, 1)
        img = ramp(heat, [(0, (30, 10, 6)), (0.3, (120, 20, 4)), (0.6, (230, 90, 10)), (0.85, (255, 180, 50)), (1, (255, 240, 160))])
        crust = ramp(crust_n, [(0, (24, 18, 16)), (1, (60, 44, 36))])
        img = mix(img, crust, plate * (1 - heat * 0.6))
        img = apply_shade(img, shade(plate * 0.6 + crust_n * plate * 0.3, 3))
        frames.append(img)
    return frames


@tex('vx_sludge', 128, 128, 'liquid', light=(120, 255, 40, 120), frames=6, desc='animated bubbling toxic sludge (+0..+5)')
def t_sludge(rng, w, h):
    flow = _loop_noise(h, w, rng, 4, 5, 6, 4.0)
    bubbles = [(rng.random() * w, rng.random() * h, rng.uniform(2, 6), rng.random()) for _ in range(26)]
    frames = []
    for k in range(6):
        t = flow(k)
        t = (t - t.min()) / (t.max() - t.min() + 1e-6)
        img = ramp(t, [(0, (20, 50, 10)), (0.5, (70, 150, 20)), (0.8, (140, 220, 40)), (1, (210, 255, 120))])
        cv = Canvas(h, w)
        cvr = Canvas(h, w)
        for x, y, r, ph in bubbles:
            p = (k / 6 + ph) % 1.0
            rr = r * (0.3 + p)
            if p < 0.85:
                cv.ellipse(x, y, rr, rr, wrap=True)
                cvr.ellipse(x - rr * 0.3, y - rr * 0.3, rr * 0.35, rr * 0.35, wrap=True)
        b = cv.mask()
        img = apply_shade(img, shade(blur(b, 1.0) * 1.2 + t * 0.4, 3))
        img = mix(img, fill(h, w, (230, 255, 160)), cvr.mask() * 0.8)
        frames.append(img)
    return frames


@tex('!vx_toxic', 128, 128, 'liquid', light=(110, 255, 50, 90), desc='toxic liquid (water contents, engine warps it)')
def t_toxic(rng, w, h):
    n = fbm(h, w, 4, rng, 5)
    f1, f2, _ = voronoi(h, w, 20, rng)
    foam = np.clip(1 - (f2 - f1) / 3, 0, 1) * np.clip(fbm(h, w, 3, rng, 3) * 2 - 0.6, 0, 1)
    img = ramp(n, [(0, (30, 90, 16)), (0.6, (80, 180, 30)), (1, (160, 240, 60))])
    img = mix(img, fill(h, w, (210, 255, 150)), foam * 0.7)
    return grain(img, rng, 0.02)


@tex('!vx_water', 128, 128, 'liquid', desc='clear blue-green water with caustics')
def t_water(rng, w, h):
    n = fbm(h, w, 3, rng, 5)
    f1, f2, _ = voronoi(h, w, 24, rng)
    caus = np.clip(1 - (f2 - f1) / 4, 0, 1) ** 1.5
    img = ramp(n, [(0, (20, 60, 80)), (0.5, (36, 96, 112)), (1, (60, 130, 140))])
    img = mix(img, fill(h, w, (150, 210, 220)), blur(caus, 0.7) * 0.5)
    return grain(img, rng, 0.015)


@tex('!vx_water_dk', 128, 128, 'liquid', desc='dark night harbour water')
def t_water_dk(rng, w, h):
    n = fbm(h, w, 3, rng, 5, aspect=(1, 2))
    img = ramp(n, [(0, (8, 16, 24)), (0.6, (16, 34, 46)), (1, (40, 66, 80))])
    hl = np.clip((fbm(h, w, 8, rng, 3, aspect=(2, 1)) - 0.7) * 4, 0, 1)
    img = mix(img, fill(h, w, (90, 120, 140)), hl * 0.4)
    return grain(img, rng, 0.015)


@tex('!lava_vx', 128, 128, 'liquid', light=(255, 110, 30, 260), desc='liquid lava (CONTENTS_LAVA, swim-able; add trigger_hurt)')
def t_lava_liq(rng, w, h):
    n = fbm(h, w, 4, rng, 6)
    img = ramp(n, [(0, (90, 14, 4)), (0.4, (200, 60, 8)), (0.75, (255, 150, 30)), (1, (255, 230, 140))])
    f1, f2, _ = voronoi(h, w, 14, rng)
    crust = np.clip((f2 - f1 - 3) / 6, 0, 1) * 0.6
    img = mix(img, fill(h, w, (40, 16, 10)), crust)
    return grain(img, rng, 0.02)


# =====================================================================
# GLASS / MASKED
# =====================================================================
@tex('vx_glass', 128, 128, 'glass', desc='window glass (use rendermode 2, renderamt ~90)')
def t_glass(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    img = ramp(ys / h, [(0, (150, 190, 205)), (1, (110, 150, 170))])
    refl = np.clip(np.sin((xs + ys * 0.8) / w * 2 * math.pi * 1.5) * 0.5 + 0.5, 0, 1) ** 8
    img = img + refl[..., None] * 0.35
    img = img * (0.95 + 0.1 * fbm(h, w, 4, rng, 4))[..., None]
    dirt = np.clip(1 - np.minimum(np.minimum(xs, w - 1 - xs), np.minimum(ys, h - 1 - ys)) / 14, 0, 1)
    img = mix(img, fill(h, w, (90, 96, 90)), dirt * 0.5)
    return np.clip(grain(img, rng, 0.015), 0, 1)


@tex('{vx_glass_brk', 128, 128, 'glass', desc='broken glass pane (masked)')
def t_glass_brk(rng, w, h):
    img = t_glass(rng, w, h)
    f1, f2, idx = voronoi(h, w, 22, rng, points=None)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    d = np.sqrt((xs - 70) ** 2 + (ys - 60) ** 2)
    pts_c = rng.random((22, 2)) * [w, h]
    f1, f2, idx = voronoi(h, w, 22, rng, points=pts_c)
    cd = np.sqrt((pts_c[:, 0] - 64) ** 2 + (pts_c[:, 1] - 60) ** 2)
    gone = (cd < 34) | (rng.random(22) < 0.12)
    alpha = (~gone[idx]).astype(F)
    alpha = np.where(f2 - f1 < 0.8, 0.0, alpha)  # thin cracks between shards
    frame = np.minimum(np.minimum(xs, w - 1 - xs), np.minimum(ys, h - 1 - ys)) < 3
    alpha = np.where(frame, 1.0, alpha)
    edge = np.clip(1 - (f2 - f1) / 1.2, 0, 1)
    img = mix(img, fill(h, w, (220, 240, 245)), edge * 0.6)
    return np.concatenate([img, alpha[..., None]], -1)


@tex('{vx_fence', 128, 128, 'masked', desc='chain link fence (masked; func_wall rendermode 4)')
def t_fence(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    p = 16
    m1 = (xs + ys) % p
    m2 = (xs - ys) % p
    d1 = np.minimum(m1, p - m1) / math.sqrt(2)
    d2 = np.minimum(m2, p - m2) / math.sqrt(2)
    wire = np.clip(1.25 - np.minimum(d1, d2), 0, 1)
    over = (d1 < d2).astype(F)
    col = steel(h, w, rng, (150, 154, 156), brushed=False)
    col = col * (0.75 + 0.35 * over)[..., None] * (0.8 + 0.4 * np.clip(1 - np.minimum(d1, d2), 0, 1))[..., None]
    col, _ = rust_layer(h, w, rng, col, 0.15)
    return np.concatenate([col, (wire > 0.35).astype(F)[..., None]], -1)


@tex('{vx_grate', 128, 128, 'masked', desc='bar grating floor/wall (masked)')
def t_grate(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    bar = ((xs % 8) < 3).astype(F)
    cross = ((ys % 32) < 3).astype(F)
    a = np.clip(bar + cross, 0, 1)
    col = steel(h, w, rng, (96, 100, 104))
    hgt = blur(a, 0.7)
    col = apply_shade(col, shade(hgt, 3))
    col = grime(col, rng, 0.3, 4)
    return np.concatenate([col, a[..., None]], -1)


@tex('{vx_rail', 128, 64, 'masked', desc='safety railing (masked)')
def t_rail(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    top = ((ys >= 2) & (ys < 9)).astype(F)
    mid = ((ys >= 28) & (ys < 33)).astype(F)
    kick = (ys >= 54).astype(F)
    post = (((xs % 64) >= 2) & ((xs % 64) < 9)).astype(F)
    a = np.clip(top + mid + kick + post, 0, 1)
    col = mix(fill(h, w, (200, 160, 30)), steel(h, w, rng, (110, 110, 110)), kick)
    prof = np.where(top > 0, np.sin((ys - 2) / 7 * math.pi), 0) + np.where(mid > 0, np.sin((ys - 28) / 5 * math.pi), 0)
    prof = prof + np.where((post > 0) & (top + mid == 0), np.sin(((xs % 64) - 2) / 7 * math.pi), 0)
    col = col * (0.6 + 0.55 * np.clip(prof, 0, 1))[..., None]
    col = grime(col, rng, 0.3, 3)
    return np.concatenate([col, a[..., None]], -1)


@tex('{vx_ladder', 64, 128, 'masked', desc='steel ladder (masked; pair with func_ladder)')
def t_ladder(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    rails = (((xs >= 4) & (xs < 12)) | ((xs >= 52) & (xs < 60))).astype(F)
    rung = ((ys % 16) >= 6) & ((ys % 16) < 10) & (xs >= 8) & (xs < 56)
    a = np.clip(rails + rung, 0, 1)
    col = steel(h, w, rng, (120, 122, 124), brushed=False)
    prof = np.where(rails > 0, np.sin(((xs % 48) - 4) / 8 * math.pi), np.sin(((ys % 16) - 6) / 4 * math.pi))
    col = col * (0.55 + 0.6 * np.clip(prof, 0, 1))[..., None]
    col, _ = rust_layer(h, w, rng, col, 0.2)
    return np.concatenate([col, a[..., None]], -1)


def _blood(rng, w, h, col_dark, col_lit):
    m = splatter(h, w, rng)
    hgt = blur(m, 1.5)
    img = mix(fill(h, w, col_dark), fill(h, w, col_lit), fbm(h, w, 8, rng, 3) * 0.6)
    img = apply_shade(img, shade(hgt, 4))
    img = img * (0.6 + 0.4 * m)[..., None]
    return np.concatenate([img, (m > 0.45).astype(F)[..., None]], -1)


@tex('{vx_blood1', 128, 128, 'decal', desc='blood splatter overlay (masked)')
def t_blood1(rng, w, h):
    return _blood(rng, w, h, (70, 4, 4), (140, 12, 10))


@tex('{vx_blood2', 128, 128, 'decal')
def t_blood2(rng, w, h):
    return _blood(rng, w, h, (60, 6, 4), (120, 20, 12))


@tex('{vx_goo', 128, 128, 'decal', desc='green zombie goo splatter (masked)')
def t_goo(rng, w, h):
    return _blood(rng, w, h, (40, 80, 10), (130, 200, 40))


@tex('{vx_claw', 128, 128, 'decal', desc='claw marks scratched on surfaces (masked)')
def t_claw(rng, w, h):
    cv = Canvas(h, w)
    for i in range(4):
        x0 = 30 + i * 18 + rng.normal(0, 2)
        pts = [(x0 + t * 22 + math.sin(t * 3) * 3, 14 + t * 100) for t in np.linspace(0, 1, 12)]
        wd = [3.4, 4.2, 4.0, 3.0][i]
        for j in range(len(pts) - 1):
            ww = wd * math.sin((j + 0.5) / (len(pts) - 1) * math.pi) + 0.6
            cv.line([pts[j], pts[j + 1]], ww)
    m = cv.mask()
    img = mix(fill(h, w, (30, 24, 20)), fill(h, w, (80, 30, 24)), blur(m, 1) * 0.5)
    return np.concatenate([img, (m > 0.4).astype(F)[..., None]], -1)


# =====================================================================
# PIPES / VENTS / MACHINES
# =====================================================================
@tex('vx_pipe', 128, 128, 'machine', desc='painted pipe surface with flange and label band')
def t_pipe(rng, w, h):
    img = steel(h, w, rng, (90, 110, 96), brushed=False)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    fl = (xs < 10).astype(F)
    hgt = fl * 1.0 + bolts(h, w, [(5, y) for y in range(8, 128, 16)], 1.8) * fl
    img = apply_shade(img, shade(hgt, 3)) * ao(hgt, 2, 0.5)[..., None]
    band = ((xs >= 60) & (xs < 92)).astype(F)
    img = mix(img, fill(h, w, (210, 170, 30)), band)
    cv = Canvas(h, w)
    for y in (20, 84):
        cv.text('BIO', 63, y, 10, 1.6)
        cv.poly([(84, y), (90, y + 5), (84, y + 10)])
    img = mix(img, fill(h, w, (30, 30, 30)), cv.mask())
    img = grime(img, rng, 0.3, 3)
    return grain(img, rng, 0.02)


@tex('vx_pipes_wall', 128, 128, 'machine', desc='wall covered with horizontal pipes')
def t_pipes_wall(rng, w, h):
    conc, _ = concrete(h, w, rng, (96, 96, 92))
    img = conc
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    for cy, r, col in ((22, 14, (110, 120, 128)), (56, 9, (150, 60, 40)), (80, 7, (60, 120, 70)), (106, 14, (120, 120, 116))):
        d = np.abs(ys - cy) / r
        m = (d < 1).astype(F)
        prof = np.sqrt(np.clip(1 - d * d, 0, 1))
        pc = steel(h, w, rng, col, brushed=False) * (0.35 + 0.8 * prof * (1 - 0.4 * (ys - cy) / r))[..., None]
        # joints
        j = ((xs % 64) < 5).astype(F) * m
        pc = pc * (1 + 0.25 * j)[..., None]
        sh = np.clip(1 - np.abs(ys - (cy + r + 3)) / 4, 0, 1) * (1 - m)
        img = img * (1 - 0.45 * sh)[..., None]
        img = mix(img, pc, m)
    img = grime(img, rng, 0.3, 3)
    return grain(img, rng, 0.02)


@tex('vx_vent', 128, 128, 'machine', desc='louvred air vent')
def t_vent(rng, w, h):
    img = steel(h, w, rng, (130, 134, 138), brushed=False)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    frame = ((xs < 10) | (xs >= w - 10) | (ys < 10) | (ys >= h - 10)).astype(F)
    sl = (ys - 10) % 12
    slat_h = np.where(frame > 0, 1.0, np.clip(1 - sl / 12, 0, 1) * 0.9)
    dark = np.where(frame > 0, 0.0, np.clip((sl - 8) / 4, 0, 1))
    hgt = slat_h + frame * 0.6 + bolts(h, w, [(5, 5), (122, 5), (5, 122), (122, 122)], 2.0)
    img = apply_shade(img, shade(hgt, 2.5)) * (1 - 0.8 * dark)[..., None]
    img = grime(img, rng, 0.4, 4, (40, 38, 34))
    return grain(img, rng, 0.02)


@tex('vx_server', 128, 128, 'machine', desc='server rack front with LEDs')
def t_server(rng, w, h):
    img = steel(h, w, rng, (46, 48, 54), brushed=False)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    unit = (ys // 16).astype(np.int64)
    ly = ys % 16
    seam = (ly < 1).astype(F)
    side = ((xs < 8) | (xs >= w - 8)).astype(F)
    vents = ((xs >= 60) & (xs < 118) & (ly >= 4) & (ly < 12) & ((xs % 3) < 1.2)).astype(F)
    hgt = -seam * 0.7 + side * 0.6 - vents * 0.4
    img = apply_shade(img, shade(hgt, 3))
    img = img * (1 - 0.6 * vents)[..., None]
    cv_g = Canvas(h, w); cv_a = Canvas(h, w); cv_c = Canvas(h, w)
    for u in range(8):
        for i in range(int(rng.integers(2, 6))):
            x = 14 + i * 6
            c = [cv_g, cv_a, cv_c][int(rng.integers(0, 3))]
            c.ellipse(x, u * 16 + 8, 1.4, 1.4)
        cv_c.rect(40, u * 16 + 5, 54, u * 16 + 11) if rng.random() < 0.4 else None
    for c, col in ((cv_g, (40, 255, 90)), (cv_a, (255, 170, 20)), (cv_c, (0, 220, 255))):
        m = c.mask()
        img = mix(img, fill(h, w, col), m)
        img = img + glow(m, 1.5, col, 0.25)
    return np.clip(grain(img, rng, 0.015), 0, 1)


@tex('vx_console', 128, 128, 'machine', desc='control desk with buttons/levers')
def t_console(rng, w, h):
    img = steel(h, w, rng, (70, 76, 84), brushed=False)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    panels = (((xs >= 6) & (xs < 60) & (ys >= 6) & (ys < 60)) | ((xs >= 68) & (xs < 122) & (ys >= 6) & (ys < 122)) |
              ((xs >= 6) & (xs < 60) & (ys >= 68) & (ys < 122))).astype(F)
    hgt = -blur(panels, 0.8) * 0.4
    cv = Canvas(h, w)
    cols = [(220, 40, 40), (40, 200, 60), (230, 190, 30), (0, 200, 255), (160, 90, 255)]
    buttons = []
    for by in range(3):
        for bx in range(3):
            buttons.append((14 + bx * 16, 14 + by * 16, cols[int(rng.integers(0, 5))]))
    btn_h = bolts(h, w, [(x, y) for x, y, _ in buttons], 5)
    hgt = hgt + btn_h * 0.8
    sl = Canvas(h, w)
    for i in range(5):
        x = 78 + i * 9
        sl.rect(x, 16, x + 3, 110)
    slot = sl.mask()
    knob = Canvas(h, w)
    for i in range(5):
        y = 20 + rng.random() * 80
        knob.rect(76 + i * 9, y, 83 + i * 9, y + 6)
    km = knob.mask()
    hgt = hgt - slot * 0.5 + km * 0.7
    img = apply_shade(img, shade(hgt, 3)) * ao(hgt, 2, 0.5)[..., None]
    for x, y, c in buttons:
        cv = Canvas(h, w)
        cv.ellipse(x, y, 4.2, 4.2)
        m = cv.mask()
        img = mix(img, fill(h, w, c) * (0.7 + 0.5 * apply_shade(np.ones((h, w, 3), F), shade(btn_h, 4))), m)
    img = img * (1 - 0.6 * slot)[..., None]
    scr = ((xs >= 10) & (xs < 56) & (ys >= 74) & (ys < 116)).astype(F)
    g = Canvas(h, w)
    pts = [(12 + i * 2, 96 + math.sin(i * 0.5) * 10 * rng.random()) for i in range(22)]
    g.line(pts, 1.0)
    img = mix(img, fill(h, w, (6, 24, 20)), scr)
    img = mix(img, fill(h, w, (60, 255, 140)), g.mask() * scr)
    return np.clip(grain(img, rng, 0.015), 0, 1)


def _screen(rng, w, h, draw, tint=(0, 220, 255), bezel=(36, 38, 44)):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    b = 6
    inside = ((xs >= b) & (xs < w - b) & (ys >= b) & (ys < h - b)).astype(F)
    img = steel(h, w, rng, bezel, brushed=False)
    img = apply_shade(img, shade(blur(1 - inside, 1.0) * 0.8, 3))
    scr = ramp(ys / h, [(0, (6, 14, 26)), (1, (10, 22, 36))])
    cv = Canvas(h, w)
    draw(cv, b, w - b, h - b)
    m = cv.mask()
    content = scr + m[..., None] * (np.array(tint, F) / 255)
    content = content + glow(m, 1.5, tint, 0.4)
    content = screen_fx(content, rng, 0.18)
    img = mix(img, content, inside)
    return np.clip(img, 0, 1)


@tex('~vx_screen1', 128, 96, 'screen', light=(80, 200, 255, 60), desc='monitor: charts (lit)')
def t_screen1(rng, w, h):
    def draw(cv, x0, x1, y1):
        cv.text('VEXMIRA', x0 + 4, x0 + 3, 7, 1.2)
        cv.rect(x0 + 2, x0 + 12, x1 - 2, x0 + 13)
        pts = [(x0 + 4 + i * 4, 40 + math.sin(i * 0.7) * 8 + rng.normal(0, 3)) for i in range(15)]
        cv.line(pts, 1.1)
        for i in range(8):
            hh = rng.uniform(6, 26)
            cv.rect(70 + i * 6, 58 - hh, 74 + i * 6, 58, v=170)
        for i in range(4):
            cv.rect(x0 + 4, 64 + i * 6, x0 + 4 + rng.uniform(20, 56), 66 + i * 6, v=140)
        cv.ellipse(100, 76, 8, 8, v=120)
    return _screen(rng, w, h, draw)


@tex('~vx_screen2', 128, 96, 'screen', light=(80, 255, 120, 60), desc='terminal text screen (lit)')
def t_screen2(rng, w, h):
    lines = ['VEXMIRA BIOTECH', '> SUBJ 07 STATUS', '  INFECTED 98%', '> CONTAIN: FAIL', '> LOCKDOWN 3', '> EVAC ROUTE B', '_']
    def draw(cv, x0, x1, y1):
        for i, s in enumerate(lines):
            cv.text(s, x0 + 3, x0 + 3 + i * 11, 6, 1.0, v=255 if i == 0 else 200)
    return _screen(rng, w, h, draw, tint=(60, 255, 120))


@tex('~vx_screen3', 128, 96, 'screen', light=(255, 80, 80, 60), desc='radar screen, red blips (lit)')
def t_screen3(rng, w, h):
    def draw(cv, x0, x1, y1):
        cx, cy = 64, 48
        for r in (12, 24, 36):
            pts = [(cx + math.cos(a) * r, cy + math.sin(a) * r) for a in np.linspace(0, 2 * math.pi, 48)]
            cv.line(pts, 0.8, v=120)
        cv.line([(cx - 38, cy), (cx + 38, cy)], 0.6, v=90)
        cv.line([(cx, cy - 38), (cx, cy + 38)], 0.6, v=90)
        cv.poly([(cx, cy), (cx + 36, cy - 10), (cx + 30, cy - 22)], v=110)
        for _ in range(9):
            a = rng.random() * 2 * math.pi
            r = rng.uniform(6, 34)
            cv.ellipse(cx + math.cos(a) * r, cy + math.sin(a) * r, 1.8, 1.8, v=255)
        cv.text('HOSTILES 09', 10, 82, 5, 0.9)
    return _screen(rng, w, h, draw, tint=(255, 70, 60))


# =====================================================================
# LIGHTS / NEON / SIGNS
# =====================================================================
def _lamp(rng, w, h, col, housing=(90, 92, 96), shape='panel'):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    img = steel(h, w, rng, housing, brushed=False)
    b = 5
    inner = ((xs >= b) & (xs < w - b) & (ys >= b) & (ys < h - b)).astype(F)
    img = apply_shade(img, shade(blur(1 - inner, 1.0) * 0.8, 3))
    c = np.array(col, F) / 255
    if shape == 'tubes':
        t = np.zeros((h, w), F)
        n = 2 if h <= 64 else 3
        for i in range(n):
            cy = b + (h - 2 * b) * (i + 0.5) / n
            d = np.abs(ys - cy) / ((h - 2 * b) / n * 0.32)
            t = np.maximum(t, np.clip(1 - d * d, 0, 1))
        diff = 0.45 + 0.55 * t
    elif shape == 'cage':
        d = np.sqrt((xs - w / 2) ** 2 + (ys - h / 2) ** 2) / (w / 2 - b)
        diff = np.clip(1.05 - d * d * 0.6, 0, 1)
        bars = ((np.abs(xs - w / 2) < 1.5) | (np.abs(ys - h / 2) < 1.5) | (np.abs(d - 0.6) < 0.05)).astype(F)
        diff = diff * (1 - 0.7 * bars)
    else:
        d = np.maximum(np.abs(xs - w / 2) / (w / 2 - b), np.abs(ys - h / 2) / (h / 2 - b))
        diff = 0.8 + 0.2 * (1 - d)
    lit = np.clip(c * 0.85 + 0.15, 0, 1)[None, None] * diff[..., None] + (diff[..., None] ** 6) * 0.18
    img = mix(img, np.clip(lit, 0, 1), inner)
    return np.clip(img, 0, 1)


@tex('~vx_light_w', 128, 64, 'light', light=(255, 250, 235, 1400), desc='fluorescent ceiling fixture (white)')
def t_light_w(rng, w, h):
    return _lamp(rng, w, h, (255, 250, 236), shape='tubes')


@tex('~vx_light_c', 128, 32, 'light', light=(60, 220, 255, 900), desc='cyan strip light')
def t_light_c(rng, w, h):
    return _lamp(rng, w, h, (40, 220, 255), (60, 64, 72))


@tex('~vx_light_p', 128, 32, 'light', light=(170, 100, 255, 900), desc='Vexmira purple strip light')
def t_light_p(rng, w, h):
    return _lamp(rng, w, h, (170, 100, 255), (60, 60, 70))


@tex('~vx_light_r', 64, 64, 'light', light=(255, 40, 30, 700), desc='red emergency cage lamp')
def t_light_r(rng, w, h):
    return _lamp(rng, w, h, (255, 40, 30), (70, 70, 72), 'cage')


@tex('~vx_light_y', 64, 64, 'light', light=(255, 180, 90, 1200), desc='sodium/industrial cage lamp')
def t_light_y(rng, w, h):
    return _lamp(rng, w, h, (255, 186, 100), (80, 80, 76), 'cage')


@tex('~vx_light_sq', 64, 64, 'light', light=(240, 245, 255, 1600), desc='square white panel light')
def t_light_sq(rng, w, h):
    return _lamp(rng, w, h, (240, 245, 255))


def _neon(rng, w, h, text, tube_col, under=None, bg=(30, 28, 34), th=None, italic=0.0, spacing=1.35):
    img = steel(h, w, rng, bg, brushed=False)
    img = grime(img, rng, 0.3, 3, (10, 10, 12))
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    edge = ((xs < 3) | (xs >= w - 3) | (ys < 3) | (ys >= h - 3)).astype(F)
    img = apply_shade(img, shade(edge * 0.6, 2))
    th = th or h * 0.5
    tw = text_width(text, th, spacing) + italic * th
    x0 = (w - tw) / 2
    y0 = (h - th) / 2 - (h * 0.06 if under else 0)
    cv = Canvas(h, w)
    draw_text(cv, text, x0, y0, th, th * 0.13, spacing=spacing, italic=italic)
    m = cv.mask()
    cvc = Canvas(h, w)
    draw_text(cvc, text, x0, y0, th, th * 0.05, spacing=spacing, italic=italic)
    core = cvc.mask()
    c = np.array(tube_col, F) / 255
    img = img + glow(m, h * 0.09, tube_col, 0.9) + glow(m, h * 0.03, tube_col, 0.6)
    img = mix(img, np.clip(c * 1.1 + 0.15, 0, 1)[None, None] * np.ones((h, w, 3), F), m)
    img = mix(img, np.ones((h, w, 3), F) * np.clip(c * 0.3 + 0.75, 0, 1), core * 0.9)
    if under:
        uc, uy = under
        cvu = Canvas(h, w)
        cvu.line([(x0, h - h * 0.17), (x0 + tw, h - h * 0.17)], th * 0.09)
        mu = cvu.mask()
        img = img + glow(mu, h * 0.07, uc, 0.8)
        img = mix(img, np.ones((h, w, 3), F) * np.clip(np.array(uc, F) / 255 * 0.8 + 0.3, 0, 1), mu)
    return np.clip(img, 0, 1)


@tex('~vx_neon_vex', 256, 64, 'sign', light=(200, 100, 255, 500), dither=True, desc='VEXMIRA neon sign (purple + cyan underline)')
def t_neon_vex(rng, w, h):
    return _neon(rng, w, h, 'VEXMIRA', (190, 90, 255), under=(VEX_CYAN, 0), th=30, italic=0.18)


@tex('~vx_neon_exit', 128, 64, 'sign', light=(60, 255, 100, 300), dither=True, desc='EXIT neon sign (green)')
def t_neon_exit(rng, w, h):
    return _neon(rng, w, h, 'EXIT', (50, 255, 90), th=28)


@tex('~vx_neon_dngr', 256, 64, 'sign', light=(255, 50, 40, 400), dither=True, desc='DANGER neon sign (red)')
def t_neon_dngr(rng, w, h):
    return _neon(rng, w, h, 'DANGER', (255, 40, 30), under=((255, 170, 0), 0), th=28)


@tex('~vx_neon_safe', 256, 64, 'sign', light=(40, 220, 255, 400), dither=True, desc='SAFE ZONE neon sign (cyan)')
def t_neon_safe(rng, w, h):
    return _neon(rng, w, h, 'SAFE ZONE', (0, 220, 255), th=24, spacing=1.2)


@tex('vx_sign_bio', 64, 64, 'sign', desc='biohazard warning plate')
def t_sign_bio(rng, w, h):
    img = fill(h, w, (230, 186, 30)) * (0.92 + 0.12 * fbm(h, w, 4, rng, 4))[..., None]
    cx, cy = 32, 34
    cv = Canvas(h, w)
    for k in range(3):
        a = -math.pi / 2 + k * 2 * math.pi / 3
        cv.ellipse(cx + math.cos(a) * 9, cy + math.sin(a) * 9, 10, 10)
    outer = cv.mask()
    cv = Canvas(h, w)
    for k in range(3):
        a = -math.pi / 2 + k * 2 * math.pi / 3
        cv.ellipse(cx + math.cos(a) * 12, cy + math.sin(a) * 12, 7, 7)
    cv.ellipse(cx, cy, 3.5, 3.5)
    inner = cv.mask()
    cv = Canvas(h, w)
    cv.ellipse(cx, cy, 8, 8)
    ring_o = cv.mask()
    cv = Canvas(h, w)
    cv.ellipse(cx, cy, 6, 6)
    ring_i = cv.mask()
    sym = np.clip(outer - inner, 0, 1)
    sym = np.clip(sym + np.clip(ring_o - ring_i, 0, 1) * (1 - inner), 0, 1)
    img = mix(img, fill(h, w, (20, 20, 20)), sym)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    frame = ((xs < 3) | (xs >= w - 3) | (ys < 3) | (ys >= h - 3)).astype(F)
    img = mix(img, fill(h, w, (20, 20, 20)), frame)
    img = mix(img, steel(h, w, rng), np.clip((fbm(h, w, 8, rng, 4) - 0.75) * 5, 0, 1))
    return grain(img, rng, 0.02)


@tex('vx_sign_vex', 128, 64, 'sign', desc='Vexmira corporate wall plate')
def t_sign_vex(rng, w, h):
    img = steel(h, w, rng, (40, 30, 64), brushed=True)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    frame = ((xs < 3) | (xs >= w - 3) | (ys < 3) | (ys >= h - 3)).astype(F)
    img = apply_shade(img, shade(frame * 0.8, 2))
    cv = Canvas(h, w)
    cv.poly([(12, 14), (20, 14), (28, 40), (36, 14), (44, 14), (31, 50), (25, 50)])
    logo = cv.mask()
    img = mix(img, fill(h, w, VEX_CYAN), logo)
    img = img + glow(logo, 2, VEX_CYAN, 0.25)
    cv = Canvas(h, w)
    cv.text('VEXMIRA', 52, 18, 10, 1.7, spacing=0.9)
    cv.text('BIOTECH', 52, 36, 7, 1.0, spacing=0.9)
    img = mix(img, fill(h, w, (230, 225, 255)), cv.mask())
    return np.clip(grain(img, rng, 0.02), 0, 1)


@tex('vx_door_metal', 64, 128, 'door', desc='steel door with hazard band')
def t_door_metal(rng, w, h):
    img = steel(h, w, rng, (92, 98, 106))
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    frame = ((xs < 4) | (xs >= w - 4) | (ys < 4) | (ys >= h - 4)).astype(F)
    panel1 = ((xs >= 10) & (xs < 54) & (ys >= 12) & (ys < 56)).astype(F)
    panel2 = ((xs >= 10) & (xs < 54) & (ys >= 76) & (ys < 116)).astype(F)
    band = ((ys >= 60) & (ys < 70)).astype(F)
    hgt = frame * 0.8 - blur(panel1 + panel2, 0.8) * 0.4
    handle = ((xs >= 48) & (xs < 54) & (ys >= 62) & (ys < 74)).astype(F)
    hgt = hgt + handle * 1.4
    img = apply_shade(img, shade(hgt, 3)) * ao(hgt, 2, 0.4)[..., None]
    img = mix(img, hazard(rng, w, h, 16), band * (1 - handle))
    img = grime(img, rng, 0.25, 3)
    return grain(img, rng, 0.02)


@tex('vx_door_lab', 128, 128, 'door', desc='sliding lab blast door (two halves)')
def t_door_lab(rng, w, h):
    img = steel(h, w, rng, (180, 186, 194), brushed=False)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    seam = (np.abs(xs - 64) < 1).astype(F)
    chev = ((((xs - 64) * np.sign(xs - 64) + ys * 0.0 + np.abs(ys - 64)) % 24) < 12) & (np.abs(xs - 64) < 30) & (ys > 96) & (ys < 116)
    stripe = ((ys >= 20) & (ys < 26)).astype(F)
    frame = ((xs < 5) | (xs >= w - 5) | (ys < 5) | (ys >= h - 5)).astype(F)
    win = (((np.abs(xs - 40) < 10) | (np.abs(xs - 88) < 10)) & (ys >= 36) & (ys < 62)).astype(F)
    hgt = frame * 0.8 - seam - win * 0.5
    img = apply_shade(img, shade(hgt, 3)) * ao(hgt, 2, 0.4)[..., None]
    img = mix(img, fill(h, w, VEX_CYAN), stripe * 0.9)
    img = mix(img, fill(h, w, (230, 180, 20)), chev.astype(F))
    img = mix(img, fill(h, w, (20, 30, 40)) + 0.15 * (ys / h)[..., None], win)
    cv = Canvas(h, w)
    cv.text('LAB 7', 46, 72, 12, 2.0)
    img = mix(img, fill(h, w, (40, 40, 50)), cv.mask())
    img = grime(img, rng, 0.2, 3)
    return grain(img, rng, 0.02)


@tex('vx_door_wood', 64, 128, 'door', desc='old wooden door')
def t_door_wood(rng, w, h):
    img, ring = wood_grain(h, w, rng, (120, 76, 44), (70, 42, 22), 'y', 8)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    frame = ((xs < 6) | (xs >= w - 6) | (ys < 6) | (ys >= h - 6) | (np.abs(ys - 60) < 4)).astype(F)
    hgt = frame * 0.7 + ring * 0.1
    knob = ((xs - 50) ** 2 + (ys - 66) ** 2 < 12).astype(F)
    img = apply_shade(img, shade(hgt + knob, 3)) * ao(hgt, 2.5, 0.5)[..., None]
    img = mix(img, fill(h, w, (170, 140, 60)), knob)
    img = grime(img, rng, 0.3, 3)
    return grain(img, rng, 0.03)


# =====================================================================
# CORDON 7 (zm_vex_cordon): wet night harbor city under military quarantine
# =====================================================================
def _wet(img, rng, amount=0.35):
    """Rain darkening + faint sheen streaks (outdoor surfaces)."""
    h, w = img.shape[:2]
    wet = np.clip((fbm(h, w, 3, rng, 5, 0.6) - 0.35) * 2.2, 0, 1) * amount
    img = img * (1 - 0.35 * wet)[..., None]
    sh = np.clip((fbm(h, w, 12, rng, 3) - 0.72) * 4, 0, 1) * wet
    return np.clip(img + sh[..., None] * 0.08, 0, 1)


def _stencil(cv_mask, rng, h, w):
    """Spray-paint stencil: broken coverage + overspray."""
    cover = np.clip(fbm(h, w, 12, rng, 3) * 1.9 - 0.15, 0, 1)
    return np.clip(cv_mask * cover + blur(cv_mask, 1.6) * 0.18, 0, 1)


def _bullets(h, w, rng, n):
    hgt = np.zeros((h, w), F)
    cv = Canvas(h, w)
    for _ in range(n):
        x, y = rng.uniform(4, w - 4), rng.uniform(4, h - 4)
        r = rng.uniform(1.6, 3.2)
        cv.ellipse(x, y, r, r)
    m = cv.mask()
    ring = np.clip(blur(m, 2.2) * 2.4 - m, 0, 1)
    return m, ring


@tex('vx_facade', 256, 256, 'cordon', desc='Cordon 7 tenement facade: 2x2 window bays (dark/broken/boarded), rain streaks')
def t_facade(rng, w, h):
    img, hgt = concrete(h, w, rng, (128, 118, 104), 0.2)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    # storey band + cornice line
    band = ((ys % 128) < 10).astype(F)
    img = mix(img, img * 0.78, band)
    hgt = hgt + band * 0.6
    kinds = ['dark', 'broken', 'boarded', 'dark']
    rng.shuffle(kinds)
    winm = np.zeros((h, w), F)
    for k, (cx, cy) in enumerate(((64, 64), (192, 64), (64, 192), (192, 192))):
        x0, x1, y0, y1 = cx - 30, cx + 30, cy - 36, cy + 40
        m = ((xs >= x0) & (xs < x1) & (ys >= y0) & (ys < y1)).astype(F)
        frm = ((xs >= x0 - 5) & (xs < x1 + 5) & (ys >= y0 - 5) & (ys < y1 + 9)).astype(F) - m
        sill = ((xs >= x0 - 8) & (xs < x1 + 8) & (ys >= y1 + 4) & (ys < y1 + 10)).astype(F)
        hgt = hgt + frm * 0.5 + sill * 0.9 - m * 0.8
        img = mix(img, fill(h, w, (150, 144, 132)), sill * 0.6)
        glass = ramp(fbm(h, w, 6, rng, 3), [(0, (8, 10, 14)), (1, (28, 34, 44))])
        mull = ((np.abs(xs - cx) < 1.5) | (np.abs(ys - (cy - 6)) < 1.5)).astype(F) * m
        if kinds[k] == 'broken':
            shard = cracks(h, w, rng, 8, 1.0, 0.6) * m
            glass = mix(fill(h, w, (4, 4, 6)), glass, np.clip(shard * 3, 0, 1))
        if kinds[k] == 'boarded':
            pl = (((ys - y0) % 18) < 14).astype(F) * m
            wood, _ = wood_grain(h, w, rng, (110, 84, 56), (60, 42, 26), 'x', 14)
            glass = mix(fill(h, w, (6, 6, 8)), wood * 0.85, pl)
        img = mix(img, glass, m)
        img = mix(img, fill(h, w, (60, 56, 50)), mull * (kinds[k] != 'boarded'))
        winm = winm + m
        # soot / rain streak below each window
        st = np.clip(1 - np.abs(xs - cx) / 34, 0, 1) * ((ys > y1 + 10) & (ys < y1 + 70)).astype(F)
        st = st * np.exp(-(ys - y1 - 10) / 40) * fbm(h, w, 16, rng, 2, aspect=(0.2, 3))
        img = img * (1 - 0.45 * st)[..., None]
    img = apply_shade(img, shade(hgt, 2.4)) * ao(hgt, 2.5, 0.4)[..., None]
    img = mix(img, img * 0.62, streaks(h, w, rng, 40, 0.5) * 0.55 * (1 - winm))
    img = grime(img, rng, 0.35, 3, (34, 30, 26))
    img = _wet(img, rng, 0.25)
    return grain(img, rng, 0.025)


@tex('vx_shopfront', 256, 128, 'cordon', desc='closed shop: grimy sign band over a dented roller shutter')
def t_shopfront(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    img = steel(h, w, rng, (112, 116, 112), brushed=False)
    slat = np.sin(ys / 4.0 * math.pi) * 0.5 + 0.5
    img = apply_shade(img, shade(slat * 0.8, 1.6))
    img, _ = rust_layer(h, w, rng, img, 0.22, 5)
    band = (ys < 30).astype(F)
    sb = steel(h, w, rng, (52, 70, 62), brushed=True)
    cv = Canvas(h, w)
    cv.text('ECZANE - APOTEK', 22, 9, 12, 2.0, spacing=1.3)
    sb = mix(sb, fill(h, w, (200, 196, 170)), cv.mask() * np.clip(fbm(h, w, 12, rng, 3) * 1.8, 0, 1))
    img = mix(img, sb, band)
    edge = (np.abs(ys - 30) < 2).astype(F)
    img = mix(img, fill(h, w, (20, 20, 20)), edge)
    # graffiti tag: red X + "ENFEKTE" stencil
    cv = Canvas(h, w)
    cv.line([(150, 50), (220, 110)], 4)
    cv.line([(220, 50), (150, 110)], 4)
    cv.text('ENFEKTE', 30, 70, 12, 2.4, spacing=1.3)
    img = mix(img, fill(h, w, (150, 18, 14)), _stencil(cv.mask(), rng, h, w) * 0.85)
    img = grime(img, rng, 0.35, 3)
    return grain(img, rng, 0.025)


@tex('vx_quar_wall', 256, 128, 'cordon', desc='military quarantine wall: concrete T-wall, yellow/black band, stencil, bullet scars')
def t_quar_wall(rng, w, h):
    img, hgt = concrete(h, w, rng, (138, 136, 126), 0.18)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    seam = (np.abs(xs - 128) < 1.5) | (xs < 1.5) | (xs > w - 2)
    hgt = hgt - seam.astype(F) * 0.8
    stripe = (ys >= 96) & (ys < 116)
    hz = (((xs + ys) % 32) < 16).astype(F)
    hzc = mix(fill(h, w, (210, 168, 30)), fill(h, w, (22, 22, 20)), hz)
    img = mix(img, hzc, stripe.astype(F) * np.clip(fbm(h, w, 10, rng, 3) * 1.7, 0, 1))
    cv = Canvas(h, w)
    cv.text('QUARANTINE', 18, 16, 16, 2.6, spacing=1.3)
    cv.text('KARANTINA - CORDON 7', 20, 46, 9, 1.6, spacing=1.3)
    cv.text('ATES SERBEST BOLGE', 20, 66, 7, 1.3, spacing=1.3)
    img = mix(img, fill(h, w, (20, 20, 18)), _stencil(cv.mask(), rng, h, w) * 0.9)
    m, ring = _bullets(h, w, rng, 16)
    hgt = hgt - m * 1.2 + ring * 0.3
    img = apply_shade(img, shade(hgt, 2.4))
    img = mix(img, fill(h, w, (60, 58, 54)), m * 0.8)
    img = mix(img, img * 0.7, streaks(h, w, rng, 40) * 0.5)
    img = grime(img, rng, 0.3, 3)
    img = _wet(img, rng, 0.3)
    return grain(img, rng, 0.025)


@tex('~vx_arrow', 64, 64, 'cordon', light=(120, 255, 140, 150), desc='green EVAC arrow plate (texlight), arrow points to +u (texture right)')
def t_arrow(rng, w, h):
    img = steel(h, w, rng, (34, 40, 36), brushed=False)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    cv = Canvas(h, w)
    cv.poly([(8, 26), (34, 26), (34, 14), (56, 32), (34, 50), (34, 38), (8, 38)])
    m = cv.mask()
    img = img + glow(m, 4, (80, 255, 120), 0.7)
    img = mix(img, fill(h, w, (170, 255, 180)), m)
    frame = ((xs < 2) | (xs >= w - 2) | (ys < 2) | (ys >= h - 2)).astype(F)
    img = mix(img, fill(h, w, (16, 18, 16)), frame)
    return grain(np.clip(img, 0, 1), rng, 0.02)


@tex('vx_signs', 128, 128, 'cordon', desc='district sign atlas: 4 rows of 128x32 (SUBSTATION, HARBOR, CUSTOMS TOWER, EVAC PAD)')
def t_signs(rng, w, h):
    rows = [('SUBSTATION', 'TRAFO', (28, 70, 110)), ('HARBOR', 'LIMAN', (24, 80, 60)),
            ('CUSTOMS TOWER', 'GUMRUK KULESI', (90, 70, 24)), ('EVAC PAD', 'TAHLIYE', (30, 100, 40))]
    img = np.zeros((h, w, 3), F)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    for i, (en, tr, col) in enumerate(rows):
        y0 = i * 32
        sub = steel(32, w, rng, col, brushed=True)
        sub = grime(sub, rng, 0.3, 3)
        cv = Canvas(32, w)
        th = min(10.0, 92 / max(1e-3, text_width(en, 1.0, 1.1)))
        cv.text(en, 5, 4, th, max(1.2, th * 0.17), spacing=1.1)
        tt = min(7.0, 92 / max(1e-3, text_width(tr, 1.0, 1.1)))
        cv.text(tr, 5, 19, tt, max(1.0, tt * 0.18), spacing=1.1)
        cv.poly([(104, 11), (113, 11), (113, 6), (123, 16), (113, 26), (113, 21), (104, 21)])
        sub = mix(sub, fill(32, w, (236, 236, 226)), cv.mask())
        yy, xx = np.mgrid[0:32, 0:w].astype(F)
        fr = ((xx < 2) | (xx >= w - 2) | (yy < 2) | (yy >= 30)).astype(F)
        sub = mix(sub, fill(32, w, (200, 200, 190)), fr * 0.7)
        img[y0:y0 + 32] = sub
    img = mix(img, img * 0.7, streaks(h, w, rng, 30) * 0.4)
    return grain(img, rng, 0.02)


def _neon_tube(h, w, mask, col, rng, core=0.55):
    """Neon tube look on a dark backplate: coloured halo (blurred mask) + bright tinted core."""
    c = np.array(col, F) / 255.0
    halo = blur(mask, 2.2)
    halo = halo / (halo.max() + 1e-6)
    img = fill(h, w, (14, 14, 18)) + halo[..., None] * c[None, None, :] * 0.85
    corecol = c * (1 - core) + core
    img = mix(img, np.broadcast_to(corecol, (h, w, 3)).copy(), np.clip(mask, 0, 1))
    return img


NEON_ROWS = [('1', 'TRAFO', 1, (255, 170, 30)), ('1', 'TRAFO', -1, (255, 170, 30)),
             ('2', 'KOPRU', 1, (40, 200, 255)), ('2', 'KOPRU', -1, (40, 200, 255)),
             ('3', 'CATI', 1, (70, 255, 110)), ('3', 'CATI', -1, (70, 255, 110)),
             ('^', 'ZIPLA!', 0, (255, 70, 230)), ('^', 'HELI', 0, (255, 50, 40))]


@tex('~vx_objsign', 128, 256, 'cordon', light=(255, 235, 220, 140), desc='neon objective signs, 8 rows of 128x32: '
     '1 TRAFO > / < 1 TRAFO (amber), 2 KOPRU (cyan), 3 CATI (green), ZIPLA! launch pad (magenta), HELI zombie geyser (red)')
def t_objsign(rng, w, h):
    img = np.zeros((h, w, 3), F)
    for i, (num, word, ar, col) in enumerate(NEON_ROWS):
        cv = Canvas(32, w)
        x0 = 22 if ar < 0 else 4
        # number in a tube ring
        cx = x0 + 12
        yy, xx = np.mgrid[0:32, 0:w].astype(F)
        ring = (np.abs(np.hypot(xx - cx, yy - 16) - 10.5) < 1.3).astype(F)
        if num == '^':
            cv.poly([(cx, 9), (cx + 6, 17), (cx + 2, 17), (cx + 2, 23), (cx - 2, 23), (cx - 2, 17), (cx - 6, 17)])
        else:
            cv.text(num, cx - 4, 10, 12, 2.0, spacing=1.0)
        tx = x0 + 28
        avail = (w - 26 if ar > 0 else w - 4) - tx
        th = min(14.0, avail / max(1e-3, text_width(word, 1.0, 1.15)))
        cv.text(word, tx, (32 - th) / 2, th, max(1.6, th * 0.15), spacing=1.15)
        if ar > 0:
            for k in (0, 7):
                cv.line([(w - 20 + k, 9), (w - 13 + k, 16), (w - 20 + k, 23)], 2.0)
        elif ar < 0:
            for k in (0, 7):
                cv.line([(19 - k, 9), (12 - k, 16), (19 - k, 23)], 2.0)
        m = np.clip(cv.mask() + ring, 0, 1)
        sub = _neon_tube(32, w, m, col, rng)
        fr = ((xx < 1) | (xx >= w - 1) | (yy < 1) | (yy >= 31)).astype(F)
        sub = mix(sub, fill(32, w, (40, 40, 46)), fr)
        img[i * 32:(i + 1) * 32] = np.clip(sub, 0, 1)
    return grain(img, rng, 0.01)


@tex('vx_chev', 64, 64, 'cordon', light=(90, 255, 150, 70), frames=8,
     desc='animated neon floor chevrons (+0..+7): a light wave chases along +u (texture right), 0.8 s loop')
def t_chev(rng, w, h):
    frames = []
    yy, xx = np.mgrid[0:h, 0:w].astype(F)
    base = steel(h, w, rng, (22, 26, 24), brushed=False)
    frame = ((xx < 2) | (xx >= w - 2) | (yy < 2) | (yy >= h - 2)).astype(F)
    for f in range(8):
        img = mix(base, fill(h, w, (10, 12, 11)), frame)
        for k, cx in enumerate((14, 30, 46)):
            cv = Canvas(h, w)
            cv.line([(cx - 6, 14), (cx + 6, 32), (cx - 6, 50)], 4.0)
            m = cv.mask()
            phase = (f / 8.0 - k / 3.0) % 1.0          # wave travels toward +u
            lvl = 0.25 + 0.75 * max(0.0, math.cos(phase * 2 * math.pi)) ** 2
            img = img + glow(m, 3, (60, 255, 130), 0.5 * lvl)
            img = mix(img, fill(h, w, (150, 255, 180)) * lvl + fill(h, w, (20, 60, 30)) * (1 - lvl), m)
        frames.append(np.clip(img, 0, 1))
    return frames


@tex('{vx_shadow', 64, 128, 'decal', desc='masked shambling zombie silhouette (dark, ragged edge), for a passing figure')
def t_shadow(rng, w, h):
    cv = Canvas(h, w)
    cv.poly([(27, 10), (37, 9), (40, 20), (36, 27), (46, 34), (55, 58), (50, 60), (43, 42), (42, 70),
             (47, 98), (49, 124), (41, 124), (35, 96), (31, 80), (26, 98), (21, 124), (13, 124), (17, 95),
             (21, 70), (20, 44), (8, 52), (4, 48), (17, 32), (25, 27), (23, 19)])
    m = cv.mask()
    m = np.clip(m + (value_noise(h, w, 8, 16, rng) > 0.8) * blur(m, 2.0) * 0.8, 0, 1)
    img = np.zeros((h, w, 4), F)
    img[..., :3] = fill(h, w, (12, 10, 12)) + value_noise(h, w, 4, 8, rng)[..., None] * 0.05
    img[..., 3] = (m > 0.5).astype(F)
    return img


@tex('{vx_scorch', 128, 128, 'decal', desc='burn / blast scorch decal (masked)')
def t_scorch(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    r = np.hypot(xs - 64, ys - 64) / 60
    n = fbm(h, w, 6, rng, 5, 0.6)
    a = np.clip(1.25 - r - (n - 0.5) * 0.9, 0, 1)
    img = ramp(np.clip(1 - a + n * 0.3, 0, 1), [(0, (8, 7, 6)), (0.55, (26, 22, 18)), (1, (60, 50, 40))])
    rays = np.clip((np.cos(np.arctan2(ys - 64, xs - 64) * 13 + n * 6) - 0.4), 0, 1) * np.clip(1.1 - r, 0, 1)
    img = img * (1 - 0.3 * rays)[..., None]
    alpha = ((a + rays * 0.3) > 0.35).astype(F)
    return np.concatenate([img, alpha[..., None]], -1)


@tex('vx_tarp', 128, 128, 'cordon', desc='olive military canvas; red cross in the upper-left 64x64 cell (fit for hospital tents)')
def t_tarp(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    weave = (np.sin(xs * 1.6) * np.sin(ys * 1.6)) * 0.5 + 0.5
    base = fill(h, w, (92, 98, 66)) * (0.85 + 0.25 * fbm(h, w, 4, rng, 5))[..., None]
    img = base * (0.94 + 0.06 * weave)[..., None]
    fold = fbm(h, w, 3, rng, 4, aspect=(1, 4))
    img = apply_shade(img, shade(fold * 1.4, 2.0))
    cross = (((np.abs(xs - 32) < 6) & (np.abs(ys - 32) < 20)) | ((np.abs(ys - 32) < 6) & (np.abs(xs - 32) < 20))).astype(F)
    disc = (np.hypot(xs - 32, ys - 32) < 27).astype(F)
    img = mix(img, fill(h, w, (196, 190, 172)), disc * 0.85)
    img = mix(img, fill(h, w, (150, 22, 18)), cross)
    img = grime(img, rng, 0.35, 4, (40, 34, 22))
    img = mix(img, img * 0.7, streaks(h, w, rng, 30) * 0.4)
    return grain(img, rng, 0.03)


@tex('vx_bay', 256, 256, 'cordon', desc='static night sea with moon glints (unreachable vista water, no liquid contents)')
def t_bay(rng, w, h):
    n = fbm(h, w, 4, rng, 5, aspect=(1, 3))
    img = ramp(n, [(0, (4, 10, 16)), (0.6, (10, 24, 34)), (1, (24, 44, 58))])
    waves = fbm(h, w, 16, rng, 3, aspect=(1, 5))
    gl = np.clip((waves - 0.68) * 6, 0, 1) * np.clip(fbm(h, w, 3, rng, 3) * 1.6 - 0.3, 0, 1)
    img = mix(img, fill(h, w, (120, 140, 160)), gl * 0.45)
    return grain(img, rng, 0.012)


@tex('vx_heli', 128, 128, 'cordon', desc='olive medevac hull with rivets + CORDON-7 MEDEVAC (rows 0-95), rotor blur strip (rows 96-127)')
def t_heli(rng, w, h):
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    img = steel(h, w, rng, (78, 86, 58), brushed=False)
    pan = (((xs % 32) < 1) | ((ys % 24) < 1)).astype(F)
    rv = bolts(h, w, [(x + 3, y + 3) for x in range(0, w, 8) for y in range(0, 96, 24)], 1.2)
    img = apply_shade(img, shade(rv - pan * 0.5, 2.0))
    cv = Canvas(h, w)
    cv.text('CORDON-7', 10, 30, 12, 2.0, spacing=1.2)
    cv.text('MEDEVAC', 10, 54, 10, 1.8, spacing=1.2)
    img = mix(img, fill(h, w, (220, 220, 210)), cv.mask())
    img = grime(img, rng, 0.3, 3)
    blur_strip = ys >= 96
    rot = fill(h, w, (40, 42, 40)) * (0.6 + 0.4 * fbm(h, w, 2, rng, 3, aspect=(8, 1)))[..., None]
    img = np.where(blur_strip[..., None], rot, img)
    return grain(img, rng, 0.02)


# =====================================================================
# public API
# =====================================================================
def names(cat: Optional[str] = None) -> List[str]:
    return [n for n, d in REGISTRY.items() if cat is None or d.cat == cat]


def wadnames() -> List[str]:
    out = []
    for d in REGISTRY.values():
        out += d.wadnames()
    return out


def _texlights():
    out = {}
    for d in REGISTRY.values():
        if d.light:
            for n in d.wadnames():
                out[n] = d.light
    return out


TEXLIGHTS = _texlights()


def resolve(name: str) -> TexDef:
    """Find a TexDef from a base or wad name (+3vx_lava -> vx_lava)."""
    if name in REGISTRY:
        return REGISTRY[name]
    if name.startswith('+') and name[2:] in REGISTRY:
        return REGISTRY[name[2:]]
    low = name.lower()
    for k, d in REGISTRY.items():
        if k.lower() == low or (low.startswith('+') and low[2:] == k.lower()):
            return d
    raise KeyError(name)


def render(name: str):
    """Return list of (wadname, float RGB(A) image)."""
    d = resolve(name)
    rng = _rng(d.name)
    res = d.fn(rng, d.w, d.h)
    if d.frames:
        assert len(res) == d.frames, d.name
        return [(n, np.clip(np.asarray(r, F), 0, 1)) for n, r in zip(d.wadnames(), res)]
    return [(d.name, np.clip(np.asarray(res, F), 0, 1))]


_CACHE_DIR = os.environ.get('MAPKIT_TEXCACHE', os.path.join(os.path.dirname(os.path.abspath(__file__)), '.texcache'))


def _src_hash():
    h = hashlib.md5()
    here = os.path.dirname(os.path.abspath(__file__))
    for f in ('textures.py', 'texgen.py', 'wad.py'):
        with open(os.path.join(here, f), 'rb') as fh:
            h.update(fh.read())
    return h.hexdigest()[:12]


def build(names_: Optional[Iterable[str]] = None, cache: bool = True) -> Dict[str, MipTex]:
    """Generate MipTex objects for base names (None = all). Results are cached
    in .texcache/ keyed by a hash of the generator sources."""
    from .wad import read_wad
    base = list(REGISTRY) if names_ is None else [resolve(n).name for n in names_]
    base = list(dict.fromkeys(base))
    out: Dict[str, MipTex] = {}
    key = _src_hash()
    cdir = os.path.join(_CACHE_DIR, key)
    for b in base:
        d = REGISTRY[b]
        cfile = os.path.join(cdir, b.replace('~', 'T_').replace('{', 'M_').replace('!', 'L_').replace('+', 'A_') + '.wad')
        if cache and os.path.exists(cfile):
            for k, v in read_wad(cfile).items():
                out[v.name] = v
            continue
        mts = [make_miptex(n, img, dither=d.dither) for n, img in render(b)]
        for m in mts:
            out[m.name] = m
        if cache:
            if not os.path.isdir(cdir) and os.path.isdir(_CACHE_DIR):
                import shutil   # drop caches of older generator versions
                for old in os.listdir(_CACHE_DIR):
                    shutil.rmtree(os.path.join(_CACHE_DIR, old), ignore_errors=True)
            os.makedirs(cdir, exist_ok=True)
            write_wad(cfile, mts)
    return out


def build_wad(path: str, names_: Optional[Iterable[str]] = None) -> int:
    texs = build(names_)
    return write_wad(path, texs.values())


def write_rad(path: str, extra: Optional[Dict[str, Tuple[int, int, int, int]]] = None):
    """Write a RAD texlight file (name r g b intensity) for all ~/light textures."""
    lights = dict(TEXLIGHTS)
    if extra:
        lights.update(extra)
    with open(path, 'w') as f:
        for n, (r, g, b, i) in lights.items():
            f.write(f'{n} {r} {g} {b} {i}\n')


def main(argv=None):
    """CLI: build the full library wad and/or a contact sheet."""
    import argparse
    import time
    from .wad import validate_wad
    ap = argparse.ArgumentParser(description='Vexmira procedural texture library')
    ap.add_argument('--wad', help='write all textures to this WAD3 file')
    ap.add_argument('--sheet', help='write a contact sheet PNG')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('names', nargs='*')
    a = ap.parse_args(argv)
    names_ = a.names or None
    if a.list:
        for d in REGISTRY.values():
            lt = f' light={d.light}' if d.light else ''
            fr = f' frames={d.frames}' if d.frames else ''
            print(f'{d.name:16s} {d.w}x{d.h:<4d} {d.cat:10s}{fr}{lt}  {d.desc}')
        return 0
    t0 = time.time()
    texs = build(names_)
    print(f'{len(texs)} textures in {time.time() - t0:.1f}s')
    if a.wad:
        size = write_wad(a.wad, texs.values())
        probs = validate_wad(a.wad)
        print(f'{a.wad}: {size} bytes, validation: {probs or "OK"}')
    if a.sheet:
        from .preview import contact_sheet
        print(contact_sheet(texs, a.sheet))
    return 0


if __name__ == '__main__':
    import sys
    sys.exit(main())
