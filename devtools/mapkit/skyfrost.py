"""skyfrost - procedural GoldSrc skybox "vexmira_frost" for zm_vexmira_icefy: arctic twilight, aurora curtains,
stars, icy mountain ranges with snow caps, blowing snow haze and the VEXMIRA logo written in the aurora over the
north (+Y: the zombie garage, where the CT spawn looks). Same cube mapping / TGA writer as skygen.py.
GoldSrc skyboxes are static images (the engine cannot animate them); the motion on this map comes from the
falling snow (env_snow) and the animated neon textures.

    cd devtools && python3 -m mapkit.skyfrost [--size 256] [--preview DIR]
"""
from __future__ import annotations

import argparse
import os

import numpy as np
from PIL import Image

from .skygen import FACES, REPO, _logo_tex, cross, face_dirs, fbm, smooth, write_tga

NAME = 'vexmira_frost'
LOGO_C = np.array([0.0, np.cos(np.radians(34)), np.sin(np.radians(34))])    # north, 30 deg up
LOGO_W, LOGO_H = 0.62, 0.15
_LOGO = None


def logo(d):
    global _LOGO
    if _LOGO is None:
        _LOGO = _logo_tex()
    c = LOGO_C
    e1 = np.array([1.0, 0.0, 0.0])                       # screen right when facing north = east
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

    tube, fill, glow, halo, bar = S('tube'), S('fill'), S('glow'), S('halo'), S('bar')
    ice = np.array([0.55, 0.95, 1.00])
    core = np.array([0.92, 1.00, 1.00])
    vio = np.array([0.70, 0.40, 1.00])
    rgb = (tube[..., None] * (0.6 * ice + 0.7 * core) + fill[..., None] * 0.8 * ice + glow[..., None] * 0.5 * ice
           + halo[..., None] * 0.35 * vio + bar[..., None] * 0.6 * vio)
    return rgb, np.clip(tube + fill + glow * 0.5, 0, 1)


def mountains(az, el):
    """Two ranges of icy peaks; returns (mask, shade, snow) for the nearest range covering each direction."""
    out_m = np.zeros_like(el)
    out_c = np.zeros(el.shape + (3,))
    for k, (base, amp, freq, col, seed) in enumerate(((0.05, 0.17, 2.5, (0.42, 0.50, 0.64), 3),
                                                      (0.02, 0.09, 4.5, (0.26, 0.31, 0.42), 9))):
        p = np.stack([np.cos(az) * freq, np.sin(az) * freq, np.full_like(az, seed)], -1)
        r = fbm(p, 5, seed)
        ridge = 1 - np.abs(2 * r - 1)                   # sharp ridges
        top = base + amp * ridge ** 1.6
        m = el < top
        depth = np.clip((top - el) / (amp + 0.02), 0, 1)
        snow = smooth(0.0, 0.05, 0.05 - (top - el)) * (ridge > 0.45)
        slope = fbm(np.stack([np.cos(az) * 40, np.sin(az) * 40, el * 60], -1), 3, seed + 5)
        c = np.array(col)[None, None] * (0.75 + 0.4 * slope[..., None]) * (1 - 0.35 * depth[..., None])
        c = c * (1 - snow[..., None]) + np.array([0.88, 0.93, 1.0]) * snow[..., None] * (0.85 + 0.15 * slope[..., None])
        out_c = np.where(m[..., None], c, out_c)
        out_m = np.maximum(out_m, m.astype(float))
    return out_m, out_c


def sky(d):
    x, y, z = d[..., 0], d[..., 1], d[..., 2]
    el = np.arcsin(np.clip(z, -1, 1))
    az = np.arctan2(y, x)
    # twilight gradient: pale ice horizon -> deep blue zenith, warmer glow in the south-west
    t = np.clip(el / (np.pi / 2), 0, 1)
    zen = np.array([0.03, 0.06, 0.16])
    hor = np.array([0.36, 0.48, 0.66])
    col = hor * (1 - t[..., None]) ** 2.2 + zen * (1 - (1 - t[..., None]) ** 2.2)
    sw = np.clip(-x * 0.7 - y * 0.7, 0, 1) * np.exp(-el / 0.18)
    col = col + sw[..., None] * np.array([0.30, 0.20, 0.25]) * 0.6
    # stars
    p = d * 220
    st = fbm(p, 1, 31)
    stars = smooth(0.92, 0.99, st) * smooth(0.12, 0.5, el)
    col = col + stars[..., None] * np.array([0.9, 0.95, 1.0])
    # aurora: curtains across the north half, waving bands, vertical rays
    wave = 0.30 + 0.07 * np.sin(az * 3.0 + 1.0) + 0.04 * np.sin(az * 7.0)
    band = np.exp(-((el - wave) / 0.06) ** 2)
    rays = 0.55 + 0.45 * fbm(np.stack([az * 18, np.zeros_like(az), np.zeros_like(az)], -1), 3, 41)
    tail = np.exp(-np.clip(el - wave, 0, None) / 0.22) * (el > wave - 0.06)
    north = smooth(-0.35, 0.25, y / np.maximum(np.sqrt(x * x + y * y), 1e-3))
    aur = (band * 0.8 + tail * 0.6) * rays * north * smooth(0.04, 0.2, el)
    green = np.array([0.20, 1.00, 0.55])
    teal = np.array([0.10, 0.75, 1.00])
    vio = np.array([0.65, 0.30, 1.00])
    mixc = green * (1 - smooth(0.0, 0.25, el - wave))[..., None] + vio * smooth(0.05, 0.3, el - wave)[..., None]
    mixc = mixc * 0.7 + teal * 0.3 * (0.5 + 0.5 * np.sin(az * 2))[..., None]
    col = col + aur[..., None] * mixc * 0.75
    # logo in the aurora
    lr, lm = logo(d)
    col = col * (1 - 0.5 * lm[..., None]) + lr
    # mountains + snow haze at the horizon
    mm, mc = mountains(az, el)
    col = np.where(mm[..., None] > 0, mc, col)
    haze = np.exp(-np.abs(el) / 0.05)
    col = col * (1 - 0.35 * haze[..., None]) + np.array([0.75, 0.82, 0.92]) * 0.35 * haze[..., None]
    # ground (below the horizon): snow field
    g = fbm(d * 30, 3, 51)
    gnd = np.array([0.70, 0.76, 0.86]) * (0.85 + 0.2 * g[..., None])
    col = np.where((el < -0.005)[..., None], gnd, col)
    return np.clip(col, 0, 1)


def render_face(face, n, ss=2):
    dd = face_dirs(face, n * ss)
    img = Image.fromarray((sky(dd) * 255 + 0.5).astype(np.uint8))
    if ss > 1:
        img = img.resize((n, n), Image.LANCZOS)
    a = np.asarray(img, np.float32) + np.random.default_rng(len(face) * 7 + ord(face[0])).normal(0, 0.6, (n, n, 3))
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
        Image.fromarray(render_face('bk', 768, 1)).save(os.path.join(a.preview, f'{NAME}_north.png'))
    print('wrote', NAME, 'faces')


if __name__ == '__main__':
    main()
