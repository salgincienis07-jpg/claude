"""skysand - procedural GoldSrc skybox "vexmira_sand" for zm_vexmira_dust: desert sunset, low sun in the west,
layered dunes and mesas, streaky clouds lit from below, and VEXMIRA glowing in the clouds over the north (+Y,
where the CT spawn looks). Static (GoldSrc skies cannot animate); the motion comes from map effects.
Same cube mapping / TGA writer as skygen.py.

    cd devtools && python3 -m mapkit.skysand [--size 256] [--preview DIR]
"""
from __future__ import annotations

import argparse
import os

import numpy as np
from PIL import Image

from .skygen import FACES, REPO, _logo_tex, cross, face_dirs, fbm, smooth, write_tga

NAME = 'vexmira_sand'
LOGO_C = np.array([0.0, np.cos(np.radians(30)), np.sin(np.radians(30))])
LOGO_W, LOGO_H = 0.62, 0.15
SUN = np.array([-np.cos(np.radians(7)), 0.25 * np.cos(np.radians(7)), np.sin(np.radians(7))])
SUN = SUN / np.linalg.norm(SUN)
_LOGO = None


def logo(d):
    global _LOGO
    if _LOGO is None:
        _LOGO = _logo_tex()
    c = LOGO_C
    e1 = np.array([1.0, 0.0, 0.0])
    e2 = np.cross(c, e1) * -1
    e2 = e2 / np.linalg.norm(e2)
    if e2[2] < 0:
        e2 = -e2
    dc = d @ c
    ok = dc > 0.3
    p = d / np.maximum(dc, 1e-3)[..., None]
    x, y = p @ e1, p @ e2
    H, W = _LOGO['tube'].shape
    u = (x / LOGO_W * 0.5 + 0.5) * (W - 1)
    v = (0.5 - y / LOGO_H * 0.5) * (H - 1)
    inside = ok & (u >= 0) & (u <= W - 1) & (v >= 0) & (v <= H - 1)
    ui = np.clip(u, 0, W - 1).astype(int)
    vi = np.clip(v, 0, H - 1).astype(int)

    def S(k):
        return np.where(inside, _LOGO[k][vi, ui], 0.0)

    tube, fill, glow, halo = S('tube'), S('fill'), S('glow'), S('halo')
    gold = np.array([1.0, 0.78, 0.40])
    core = np.array([1.0, 0.95, 0.85])
    mag = np.array([0.85, 0.35, 0.75])
    rgb = (tube[..., None] * (0.55 * gold + 0.6 * core) + fill[..., None] * 0.5 * gold + glow[..., None] * 0.45 * gold
           + halo[..., None] * 0.35 * mag)
    return rgb, np.clip(tube + fill * 0.6 + glow * 0.4, 0, 1)


def dunes(az, el):
    out_m = np.zeros_like(el)
    out_c = np.zeros(el.shape + (3,))
    for base, amp, freq, col, seed, mesa in ((0.035, 0.09, 2.0, (0.55, 0.36, 0.30), 3, True),
                                            (0.015, 0.045, 4.0, (0.80, 0.52, 0.32), 9, False)):
        p = np.stack([np.cos(az) * freq, np.sin(az) * freq, np.full_like(az, seed)], -1)
        r = fbm(p, 4, seed)
        if mesa:                                          # flat-topped mesas in the far range
            top = base + amp * smooth(0.45, 0.55, r) + 0.01 * r
        else:
            top = base + amp * (0.5 + 0.5 * np.sin(az * 9 + r * 6)) * r
        m = el < top
        lit = 0.6 + 0.6 * np.clip(-np.cos(az - np.pi) * 0.5 + 0.5, 0, 1) * (0.5 + r)
        c = np.array(col)[None, None] * lit[..., None] * (1 - 0.4 * np.clip((top - el) / 0.06, 0, 1))[..., None]
        out_c = np.where(m[..., None], c, out_c)
        out_m = np.maximum(out_m, m.astype(float))
    return out_m, out_c


def sky(d):
    x, y, z = d[..., 0], d[..., 1], d[..., 2]
    el = np.arcsin(np.clip(z, -1, 1))
    az = np.arctan2(y, x)
    t = np.clip(el / (np.pi / 2), 0, 1)
    hor = np.array([1.00, 0.62, 0.34])
    mid = np.array([0.78, 0.42, 0.42])
    zen = np.array([0.46, 0.32, 0.50])
    a = (1 - t[..., None]) ** 3
    col = hor * a + mid * (1 - a) * (1 - t[..., None]) + zen * t[..., None]
    sd = np.clip(d @ SUN, -1, 1)
    col = col + np.array([1.0, 0.75, 0.40]) * (np.exp((sd - 1) * 9) * 0.55 + np.exp((sd - 1) * 120) * 2.0)[..., None]
    # streaky clouds (stretched noise), lit from below near the sun
    p = np.stack([x * 3.0, y * 3.0, z * 14.0], -1) / np.maximum(z + 0.25, 0.1)[..., None]
    c = fbm(p, 5, 61)
    cl = smooth(0.52, 0.75, c) * smooth(0.03, 0.12, el) * (1 - smooth(0.6, 1.2, el))
    ccol = np.array([0.95, 0.55, 0.45]) * (0.6 + 0.8 * np.exp((sd - 1) * 3))[..., None] + np.array([0.15, 0.05, 0.1])
    col = col * (1 - 0.8 * cl[..., None]) + ccol * 0.8 * cl[..., None]
    lr, lm = logo(d)
    col = col * (1 - 0.35 * lm[..., None]) + lr
    mm, mc = dunes(az, el)
    col = np.where(mm[..., None] > 0, mc, col)
    haze = np.exp(-np.abs(el) / 0.04)
    col = col * (1 - 0.3 * haze[..., None]) + np.array([1.0, 0.70, 0.45]) * 0.3 * haze[..., None]
    g = fbm(d * 25, 3, 71)
    gnd = np.array([0.78, 0.58, 0.38]) * (0.85 + 0.2 * g[..., None])
    col = np.where((el < -0.005)[..., None], gnd, col)
    return np.clip(col, 0, 1)


def render_face(face, n, ss=2):
    dd = face_dirs(face, n * ss)
    img = Image.fromarray((sky(dd) * 255 + 0.5).astype(np.uint8))
    if ss > 1:
        img = img.resize((n, n), Image.LANCZOS)
    a = np.asarray(img, np.float32) + np.random.default_rng(len(face) * 11 + ord(face[0])).normal(0, 0.6, (n, n, 3))
    return np.clip(a + 0.5, 0, 255).astype(np.uint8)


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--size', type=int, default=256)
    ap.add_argument('--out', default=os.path.join(REPO, 'cstrike', 'gfx', 'env'))
    ap.add_argument('--preview', default=None)
    a = ap.parse_args(argv)
    faces = {}
    for f in FACES:
        faces[f] = render_face(f, a.size)
        write_tga(os.path.join(a.out, f'{NAME}{f}.tga'), faces[f])
    if a.preview:
        os.makedirs(a.preview, exist_ok=True)
        Image.fromarray(cross(faces, a.size)).save(os.path.join(a.preview, f'{NAME}_cross.png'))
    print('wrote', NAME, 'faces')


if __name__ == '__main__':
    main()
