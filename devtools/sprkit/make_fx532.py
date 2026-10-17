"""Vexmira 5.3.2 effect sprites: smooth, additive (black = see-through), no black squares, no pixel noise.

    cd devtools/sprkit && python3 make_fx532.py [--preview out.png]

Out: cstrike/sprites/vexmira/fx532/*.spr
Every sprite is ADDITIVE (palette index = brightness, index 0 = black = invisible) except smoke.spr
(INDEXALPHA: index = opacity) which is meant for TE_SMOKE. Gradients are built at 4x and filtered
down, so even scaled up 3x in game the edges stay soft.
"""
import argparse
import os
import sys

import numpy as np
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from sprlib import write_spr, read_spr, ramp, fbm, VP_PARALLEL, TF_ADDITIVE, TF_INDEXALPHA  # noqa: E402

OUT = os.path.abspath(os.path.join(HERE, '..', '..', 'cstrike', 'sprites', 'vexmira', 'fx532'))

PAL = {
    'fire': ramp([(0, (0, 0, 0)), (0.18, (70, 6, 0)), (0.42, (200, 50, 4)), (0.65, (255, 140, 20)),
                  (0.85, (255, 214, 110)), (1, (255, 250, 230))], 0.9),
    'ice': ramp([(0, (0, 0, 0)), (0.2, (4, 20, 70)), (0.45, (20, 110, 210)), (0.7, (90, 210, 255)),
                 (0.9, (200, 245, 255)), (1, (255, 255, 255))], 0.9),
    'flare': ramp([(0, (0, 0, 0)), (0.25, (90, 30, 10)), (0.5, (255, 120, 60)), (0.75, (255, 210, 160)),
                   (1, (255, 255, 250))], 0.9),
    'toxic': ramp([(0, (0, 0, 0)), (0.2, (6, 40, 4)), (0.45, (40, 150, 10)), (0.7, (130, 245, 40)),
                   (0.9, (220, 255, 140)), (1, (250, 255, 230))], 0.9),
    'void': ramp([(0, (0, 0, 0)), (0.2, (30, 0, 60)), (0.45, (110, 30, 200)), (0.7, (190, 110, 255)),
                  (0.9, (235, 205, 255)), (1, (255, 250, 255))], 0.9),
    'shock': ramp([(0, (0, 0, 0)), (0.25, (10, 30, 80)), (0.5, (60, 140, 255)), (0.75, (170, 225, 255)),
                   (1, (255, 255, 255))], 0.9),
    'white': ramp([(0, (0, 0, 0)), (0.5, (150, 150, 150)), (1, (255, 255, 255))]),
    'laser': ramp([(0, (0, 0, 0)), (0.35, (110, 110, 110)), (0.8, (225, 225, 225)), (1, (255, 255, 255))]),
}


def grid(n, ss=1):
    m = n * ss
    c = (np.arange(m) + 0.5) / m * 2 - 1
    x, y = np.meshgrid(c, c)
    return x, y


def down(img, ss):
    if ss == 1:
        return img
    h, w = img.shape
    return img.reshape(h // ss, ss, w // ss, ss).mean(axis=(1, 3))


def finish(img, gamma=1.0):
    img = np.clip(img, 0, 1) ** gamma
    out = (img * 255 + 0.5).astype(np.uint8)
    # a 2-pixel black border: the sprite quad edge can never show a seam
    out[:2, :] = 0
    out[-2:, :] = 0
    out[:, :2] = 0
    out[:, -2:] = 0
    return out


def soft(x, e0, e1):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def burst(n, frames, seed, spikes=0, bubbles=False, ss=2):
    """expanding fireball / burst. returns brightness frames 0..1."""
    x, y = grid(n, ss)
    r = np.hypot(x, y)
    a = np.arctan2(y, x)
    noise = fbm((n * ss, n * ss), seed, octaves=6, base=0.35)
    noise2 = fbm((n * ss, n * ss), seed + 7, octaves=5, base=0.2)
    out = []
    for f in range(frames):
        t = f / (frames - 1)
        rad = 0.28 + 0.64 * t ** 0.55
        # turbulent edge: the noise pushes the boundary in/out, it rolls outwards with time
        sh = int(t * n * ss * 0.18)
        nz = np.roll(np.roll(noise, sh, 0), sh // 2, 1)
        edge = rad * (0.82 + 0.36 * nz)
        body = 1 - soft(r, edge * 0.55, edge)
        core = np.exp(-(r / (rad * (0.55 - 0.35 * t))) ** 2) * (1 - t) ** 1.4
        detail = 0.55 + 0.6 * np.roll(noise2, sh, 1)
        v = body * detail * (1 - t) ** 1.1 * 0.85 + core
        if spikes:
            sp = np.abs(np.cos(a * spikes / 2 + seed)) ** 18
            sp2 = np.abs(np.cos(a * spikes / 2 + 0.9 + seed)) ** 30
            ray = (0.8 * sp + 0.5 * sp2) * np.exp(-(r / (rad * 1.15)) ** 2) * (1 - t) ** 0.8
            v = v + ray * 0.9
        if bubbles:
            rng = np.random.default_rng(seed + f)
            for _ in range(10):
                bx, by = rng.uniform(-rad, rad, 2)
                br = rng.uniform(0.04, 0.09) * (1 + t)
                d = np.hypot(x - bx, y - by)
                v = v + 0.5 * np.exp(-((d - br) / 0.018) ** 2) * (1 - t) * (np.hypot(bx, by) < rad)
        # never reach the quad edge
        v = v * (1 - soft(r, 0.86, 0.98))
        out.append(finish(down(v, ss)))
    return out


def glowdot(n, sharp=0.18, halo=0.5, ss=4):
    x, y = grid(n, ss)
    r = np.hypot(x, y)
    v = np.exp(-(r / sharp) ** 2) + 0.35 * np.exp(-(r / halo) ** 2)
    v = v / v.max() * (1 - soft(r, 0.8, 0.98))
    return [finish(down(v, ss))]


def star(n, points=4, ss=4):
    x, y = grid(n, ss)
    r = np.hypot(x, y)
    a = np.arctan2(y, x)
    arms = np.abs(np.cos(a * points / 2)) ** 60
    v = arms * np.exp(-(r / 0.85) ** 2) + np.exp(-(r / 0.16) ** 2)
    v = v / v.max() * (1 - soft(r, 0.85, 0.98))
    return [finish(down(v, ss))]


def mist(n, frames, seed, ss=2):
    x, y = grid(n, ss)
    r = np.hypot(x, y)
    noise = fbm((n * ss, n * ss), seed, octaves=5, base=0.3)
    out = []
    for f in range(frames):
        ph = f / frames
        sh = int(ph * n * ss)
        nz = np.roll(noise, sh, 1)
        env = np.sin(np.pi * ph) * 0.6 + 0.4
        v = (1 - soft(r, 0.2, 0.92)) * (0.35 + 0.65 * nz) * env * 0.75
        out.append(finish(down(v, ss)))
    return out


def flame(n, frames, seed, ss=2):
    """looping flame tongue (rises, flickers)."""
    x, y = grid(n, ss)
    yy = -y                                      # up = +
    noise = fbm((n * ss, n * ss), seed, octaves=6, base=0.3)
    out = []
    for f in range(frames):
        sh = int(f / frames * n * ss)
        nz = np.roll(noise, sh, 0)               # scroll upward: seamless loop
        width = 0.55 * (1 - soft(yy, -0.8, 0.85)) + 0.02
        wob = (nz - 0.5) * 0.35 * (yy + 1)
        d = np.abs(x + wob) / width
        v = (1 - soft(d, 0.25, 1.0)) * (1 - soft(yy, 0.3, 0.92)) * soft(yy, -0.95, -0.6)
        v = v * (0.6 + 0.6 * nz)
        v = v + 0.5 * np.exp(-((x / 0.18) ** 2 + ((yy + 0.55) / 0.25) ** 2))
        v = v * (1 - soft(np.hypot(x, y), 0.9, 1.0))
        out.append(finish(down(np.clip(v, 0, 1), ss)))
    return out


def flare(n, frames, seed, ss=2):
    x, y = grid(n, ss)
    r = np.hypot(x, y)
    a = np.arctan2(y, x)
    out = []
    for f in range(frames):
        ph = f / frames * 2 * np.pi
        rays = (np.abs(np.cos(a * 3 + ph / 3)) ** 40 + 0.6 * np.abs(np.cos(a * 5 - ph / 5 + 0.4)) ** 70)
        v = rays * np.exp(-(r / 0.9) ** 2) * (0.85 + 0.15 * np.sin(ph))
        v += np.exp(-(r / 0.13) ** 2) + 0.45 * np.exp(-(r / 0.42) ** 2) * (0.9 + 0.1 * np.cos(ph * 2))
        v += 0.25 * np.exp(-((r - 0.55) / 0.03) ** 2)            # thin halo ring
        v = v / 1.6 * (1 - soft(r, 0.86, 0.98))
        out.append(finish(down(np.clip(v, 0, 1), ss)))
    return out


def smoke(n, frames, seed, ss=2):
    """INDEXALPHA puff: index = opacity."""
    x, y = grid(n, ss)
    r = np.hypot(x, y)
    noise = fbm((n * ss, n * ss), seed, octaves=6, base=0.35)
    out = []
    for f in range(frames):
        t = f / (frames - 1)
        rad = 0.45 + 0.45 * t
        sh = int(t * n * ss * 0.25)
        nz = np.roll(noise, -sh, 0)
        v = (1 - soft(r, rad * (0.35 + 0.4 * nz), rad)) * (0.55 + 0.45 * nz)
        v = v * (1 - t) ** 0.9 * 0.85 * (1 - soft(r, 0.85, 0.98))
        out.append(finish(down(v, ss)))
    return out


def beam(w, h, seed, core=0.12, halo=0.42, streak=0.18):
    """beam texture: across = columns (s), along = rows (t, scrolls). No gaps: every row is lit."""
    s = (np.arange(w) + 0.5) / w * 2 - 1
    t = np.arange(h) / h
    S, T = np.meshgrid(s, t)
    across = np.exp(-(S / core) ** 2) + 0.45 * np.exp(-(S / halo) ** 2)
    rng = np.random.default_rng(seed)
    # seamless energy streaks along the beam (periodic in t), small amplitude: never dark
    waves = np.zeros_like(T)
    for k in (2, 3, 5, 8):
        waves += rng.uniform(0.5, 1.0) * np.sin(2 * np.pi * (k * T + rng.uniform(0, 1)) + 3 * S * rng.uniform(-1, 1))
    waves = waves / np.abs(waves).max()
    v = across * (1 - streak + streak * (0.5 + 0.5 * waves))
    v = v / v.max()
    v[:, :1] = 0
    v[:, -1:] = 0
    return [(np.clip(v, 0, 1) * 255 + 0.5).astype(np.uint8)]


def ringtex(w, h):
    """shockwave ring texture for TE_BEAMCYLINDER: soft leading edge, fading trail."""
    s = (np.arange(w) + 0.5) / w
    v = np.exp(-((s - 0.5) / 0.22) ** 2) * (0.75 + 0.25 * np.sin(np.pi * s) ** 4)
    img = np.tile(v, (h, 1))
    img[:, :1] = 0
    img[:, -1:] = 0
    return [(np.clip(img / img.max(), 0, 1) * 255 + 0.5).astype(np.uint8)]


SPRITES = {
    # name: (builder, palette, texfmt)
    'fireball': (lambda: burst(128, 14, 11), 'fire', TF_ADDITIVE),
    'flame': (lambda: flame(64, 12, 21), 'fire', TF_ADDITIVE),
    'ember': (lambda: glowdot(32, 0.2, 0.55), 'fire', TF_ADDITIVE),
    'frostburst': (lambda: burst(128, 14, 31, spikes=10), 'ice', TF_ADDITIVE),
    'frostmist': (lambda: mist(64, 8, 41), 'ice', TF_ADDITIVE),
    'shard': (lambda: star(32, 4), 'ice', TF_ADDITIVE),
    'flare': (lambda: flare(128, 10, 51), 'flare', TF_ADDITIVE),
    'spark': (lambda: glowdot(32, 0.14, 0.4), 'flare', TF_ADDITIVE),
    'toxicburst': (lambda: burst(128, 14, 61, bubbles=True), 'toxic', TF_ADDITIVE),
    'toxicmist': (lambda: mist(64, 8, 71), 'toxic', TF_ADDITIVE),
    'voidburst': (lambda: burst(128, 14, 101, spikes=6), 'void', TF_ADDITIVE),
    'shockburst': (lambda: burst(128, 12, 111, spikes=14), 'shock', TF_ADDITIVE),
    'glow': (lambda: glowdot(64, 0.25, 0.6), 'white', TF_ADDITIVE),
    'ring': (lambda: ringtex(64, 64), 'white', TF_ADDITIVE),
    'beam': (lambda: beam(32, 128, 81), 'laser', TF_ADDITIVE),
    'beam_wide': (lambda: beam(32, 128, 82, core=0.2, halo=0.6, streak=0.3), 'laser', TF_ADDITIVE),
    'smoke': (lambda: smoke(64, 12, 91), None, TF_INDEXALPHA),
}


def smoke_pal():
    # INDEXALPHA: the colour is the LAST palette entry, the index is the opacity
    pal = [(i, i, i) for i in range(256)]
    pal[255] = (70, 66, 62)
    return pal


def preview(path, names):
    from PIL import Image
    tiles = []
    for n in names:
        d = read_spr(os.path.join(OUT, n + '.spr'))
        pal = np.array(d['pal'])
        fr = d['frames'][len(d['frames']) // 3]
        if d['fmt'] == TF_INDEXALPHA:
            col = np.zeros(fr.shape + (3,))
            col[:] = pal[255]
            a = fr[..., None] / 255.0
            bg = np.full(fr.shape + (3,), 150.0)
            rgb = bg * (1 - a) + col * a
        else:
            bg = np.full(fr.shape + (3,), 40.0)
            rgb = np.clip(bg + pal[fr], 0, 255)
        im = Image.fromarray(rgb.astype(np.uint8)).resize((160, 160), Image.BILINEAR)
        tiles.append(im)
    W = Image.new('RGB', (170 * len(tiles), 170), (20, 20, 20))
    for i, t in enumerate(tiles):
        W.paste(t, (i * 170 + 5, 5))
    W.save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--preview')
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    total = 0
    for name, (fn, pal, fmt) in SPRITES.items():
        frames = fn()
        p = os.path.join(OUT, name + '.spr')
        write_spr(p, frames, VP_PARALLEL, smoke_pal() if pal is None else PAL[pal], fmt)
        d = read_spr(p)
        total += d['size']
        print('%-12s %3dx%-3d %2d frames %7d bytes' % (name, d['w'], d['h'], d['nf'], d['size']))
    print('total %d KB' % (total // 1024))
    if a.preview:
        preview(a.preview, list(SPRITES))


if __name__ == '__main__':
    main()
