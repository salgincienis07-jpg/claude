"""skyset - six procedural zombie-apocalypse GoldSrc skyboxes with the VEXMIRA neon logo (round rotation set).

    cd devtools && python3 -m mapkit.skyset [--size 256] [--only blood,toxic] [--preview DIR]

Names (gfx/env/<name><face>.tga): vexmira_blood, vexmira_toxic, vexmira_void, vexmira_inferno,
vexmira_eclipse, vexmira_deadlight. Same cube mapping / TGA writer as skygen.py. Every sky shows the logo
twice (two opposite directions, 26-34 deg up) so it is in view from most of a map.
"""
from __future__ import annotations

import argparse
import os

import numpy as np
from PIL import Image

from .skygen import FACES, REPO, _h, _logo_tex, cross, face_dirs, fbm, smooth, write_tga

_LOGO = None


def _dir(az, el):
    a, e = np.radians(az), np.radians(el)
    return np.array([np.cos(e) * np.cos(a), np.cos(e) * np.sin(a), np.sin(e)])


def logo_at(d, az, el, w, h, tube_c, glow_c, ghost_c, glitch=True):
    """additive neon logo centred on direction (az, el); returns (rgb, mask)."""
    global _LOGO
    if _LOGO is None:
        _LOGO = _logo_tex()
    c = _dir(az, el)
    up = np.array([0.0, 0.0, 1.0])
    e1 = np.cross(c, up)                       # screen right
    e1 /= np.linalg.norm(e1)
    e2 = np.cross(e1, c)                       # screen up
    dc = d @ c
    ok = dc > 0.3
    p = d / np.maximum(dc, 1e-3)[..., None]
    x, y = p @ e1, p @ e2
    gy = (y / h * 0.5 + 0.5)
    if glitch:
        x = x + 0.010 * ((gy > 0.56) & (gy < 0.59)) - 0.006 * ((gy > 0.30) & (gy < 0.32))
    H, W = _LOGO['tube'].shape
    u = (x / w * 0.5 + 0.5) * (W - 1)
    v = (0.5 - y / h * 0.5) * (H - 1)
    inside = ok & (u >= 0) & (u <= W - 1) & (v >= 0) & (v <= H - 1)
    ui = np.clip(u, 0, W - 1).astype(int)
    vi = np.clip(v, 0, H - 1).astype(int)

    def S(k, du=0, dv=0):
        return np.where(inside, _LOGO[k][np.clip(vi + dv, 0, H - 1), np.clip(ui + du, 0, W - 1)], 0.0)

    tube, fill, glow, halo, bar = S('tube'), S('fill'), S('glow'), S('halo'), S('bar')
    ghost = S('tube', -14, -9)
    scan = 0.86 + 0.14 * np.sin(v * 0.21) ** 2
    tube_c, glow_c, ghost_c = np.array(tube_c), np.array(glow_c), np.array(ghost_c)
    core = 0.55 * tube_c + 0.45
    rgb = (tube[..., None] * (0.55 * tube_c + 0.75 * core) + fill[..., None] * tube_c * 0.9
           + glow[..., None] * 0.6 * glow_c + halo[..., None] * 0.32 * glow_c
           + ghost[..., None] * 0.35 * ghost_c + bar[..., None] * 0.7 * ghost_c) * scan[..., None]
    return rgb, np.clip(tube + fill + glow * 0.5, 0, 1)


def clouds(d, seed, scale=0.55, cover=(0.30, 0.62)):
    dx, dy, dz = d[..., 0], d[..., 1], d[..., 2]
    k = 1.0 / (np.maximum(dz, 0) + 0.10)
    cp = np.stack([dx * k * scale, dy * k * scale, np.full_like(dx, 1.7 + seed)], -1)
    warp = fbm(cp * 0.8 + 5.1, 3, seed + 41)
    cn = fbm(cp + warp[..., None] * 1.4, 6, seed + 51)
    el = np.arcsin(np.clip(dz, -1, 1))
    cd = smooth(cover[0], cover[1], cn) * (0.55 + 0.45 * smooth(-0.02, 0.15, el))
    detail = fbm(cp * 3.0, 3, seed + 61)
    return cd, detail


def stars(d, el, amount=1.0):
    st = fbm(d * 220, 1, 31)
    return smooth(0.92, 0.99, st) * smooth(0.10, 0.5, el) * amount


def silhouette(az, el, kind, seed, height=1.0):
    """horizon silhouettes; returns mask (bool) and a small rgb extra for lit windows/fires."""
    u = (az + np.pi) / (2 * np.pi) % 1.0
    r = np.random.default_rng(seed)
    extra = np.zeros(el.shape + (3,))
    if kind in ('city', 'ruins', 'factory'):
        edges, hs = [0.0], []
        while edges[-1] < 1:
            edges.append(edges[-1] + r.uniform(0.004, 0.022))
            hh = r.uniform(0.01, 0.085) * height
            if kind == 'ruins' and r.random() < 0.35:
                hh *= r.uniform(0.2, 0.6)
            hs.append(hh)
        edges = np.array(edges[:-1] + [1.0])
        hs = np.array(hs)
        k = np.clip(np.searchsorted(edges, u, side='right') - 1, 0, len(hs) - 1)
        top = hs[k]
        if kind == 'ruins':     # broken jagged tops
            top = top * (0.85 + 0.15 * fbm(np.stack([u * 900, el * 0, np.zeros_like(u)], -1), 2, seed))
        m = el < top
        if kind == 'factory':   # chimneys
            for c in r.uniform(0, 1, 9):
                w = 0.0018
                ch = r.uniform(0.07, 0.14) * height
                m = m | ((np.abs(u - c) < w) & (el < ch))
        cu = np.floor(u * 1100).astype(np.int64)
        ce = np.floor(el * 260).astype(np.int64)
        rnd = _h(cu, ce, k, seed)
        lit = m & (el > 0.004) & (el < top - 0.006) & (rnd < (0.03 if kind == 'ruins' else 0.06))
        extra = lit[..., None] * np.array([1.0, 0.55, 0.22]) * 0.5
        return m, extra
    if kind == 'graveyard':
        base = 0.012 + 0.010 * fbm(np.stack([np.cos(az) * 3, np.sin(az) * 3, np.zeros_like(az)], -1), 3, seed)
        m = el < base
        for c in r.uniform(0, 1, 70):
            hh = r.uniform(0.018, 0.045) * height
            w = r.uniform(0.0009, 0.0016)
            du = np.abs(u - c)
            m = m | ((du < w) & (el < hh))                                   # post
            m = m | ((du < w * 4.0) & (np.abs(el - hh * 0.72) < 0.0025))    # cross arm
        return m, extra
    if kind == 'forest':
        base = 0.010 + 0.012 * fbm(np.stack([np.cos(az) * 3, np.sin(az) * 3, np.ones_like(az)], -1), 3, seed)
        m = el < base
        for c in r.uniform(0, 1, 120):
            hh = r.uniform(0.03, 0.11) * height
            du = np.abs(u - c)
            trunk = (du < 0.0010 * (1.6 - el / hh)) & (el < hh)
            br = np.zeros_like(m)
            for j in range(4):           # dead branches
                y0 = hh * r.uniform(0.45, 0.9)
                s = r.choice([-1, 1]) * r.uniform(0.5, 1.2)
                br = br | ((np.abs((u - c) - s * (el - y0) * 0.25) < 0.0006) & (el > y0) & (el < y0 + hh * 0.25))
            m = m | trunk | br
        return m, extra
    if kind == 'mountains':
        p = np.stack([np.cos(az) * 2.5, np.sin(az) * 2.5, np.full_like(az, seed)], -1)
        rr = fbm(p, 5, seed)
        top = 0.03 + 0.12 * (1 - np.abs(2 * rr - 1)) ** 1.6 * height
        return el < top, extra
    return np.zeros_like(el, bool), extra


# ------------------------------------------------------------------------------------------- themes
THEMES = {
    'blood': dict(zen=(0.025, 0.004, 0.006), hor=(0.42, 0.05, 0.04), moon=(-70, 36), moon_c=(1.0, 0.18, 0.10),
                  moon_r=0.9955, cloud=(0.20, 0.03, 0.03), under=(0.9, 0.12, 0.08), sil='ruins',
                  sil_c=(0.03, 0.006, 0.008), logo=((1.0, 0.16, 0.14), (0.9, 0.05, 0.08), (1.0, 0.6, 0.3)),
                  logo_dirs=((40, 30), (220, 28)), stars=0.6, gnd=(0.03, 0.005, 0.006)),
    'toxic': dict(zen=(0.010, 0.030, 0.012), hor=(0.30, 0.55, 0.10), moon=(70, 42), moon_c=(0.85, 1.0, 0.35),
                  moon_r=0.9993, cloud=(0.08, 0.20, 0.05), under=(0.35, 0.95, 0.15), sil='factory',
                  sil_c=(0.012, 0.025, 0.010), logo=((0.45, 1.0, 0.20), (0.25, 0.95, 0.10), (0.9, 1.0, 0.3)),
                  logo_dirs=((-30, 28), (150, 30)), stars=0.2, gnd=(0.02, 0.05, 0.015), fog=(0.35, 0.65, 0.15)),
    'void': dict(zen=(0.05, 0.0, 0.12), hor=(0.20, 0.06, 0.40), moon=None, cloud=(0.10, 0.03, 0.20),
                 under=(0.55, 0.20, 1.0), sil='mountains', sil_c=(0.02, 0.01, 0.04),
                 logo=((0.75, 0.30, 1.0), (0.55, 0.15, 0.95), (0.25, 0.95, 1.0)), logo_dirs=((90, 30), (270, 30)),
                 stars=1.0, gnd=(0.015, 0.008, 0.03), vortex=True, lightning=True),
    'inferno': dict(zen=(0.08, 0.015, 0.005), hor=(0.95, 0.35, 0.05), moon=(110, 20), moon_c=(1.0, 0.75, 0.3),
                    moon_r=0.9990, cloud=(0.20, 0.06, 0.02), under=(1.0, 0.40, 0.08), sil='city',
                    sil_c=(0.03, 0.01, 0.006), logo=((1.0, 0.55, 0.10), (1.0, 0.30, 0.02), (1.0, 0.9, 0.4)),
                    logo_dirs=((10, 30), (190, 30)), stars=0.0, gnd=(0.06, 0.015, 0.005), embers=True),
    'eclipse': dict(zen=(0.004, 0.012, 0.018), hor=(0.10, 0.16, 0.18), moon=(60, 40), moon_c=(1.0, 0.82, 0.35),
                    moon_r=0.9985, eclipse=True, cloud=(0.04, 0.05, 0.06), under=(0.6, 0.5, 0.3), sil='graveyard',
                    sil_c=(0.006, 0.008, 0.01), logo=((1.0, 0.80, 0.30), (1.0, 0.6, 0.15), (0.4, 0.9, 1.0)),
                    logo_dirs=((240, 28), (60, 18)), stars=1.0, gnd=(0.01, 0.012, 0.015), cover=(0.45, 0.75)),
    'deadlight': dict(zen=(0.004, 0.02, 0.03), hor=(0.10, 0.30, 0.34), moon=(-120, 45), moon_c=(0.85, 0.95, 1.0),
                      moon_r=0.9995, cloud=(0.03, 0.06, 0.07), under=(0.2, 0.7, 0.8), sil='forest',
                      sil_c=(0.004, 0.010, 0.012), logo=((0.30, 1.0, 0.95), (0.10, 0.8, 0.9), (0.8, 0.5, 1.0)),
                      logo_dirs=((0, 32), (180, 30)), stars=0.9, gnd=(0.01, 0.025, 0.03), aurora=True,
                      fog=(0.25, 0.45, 0.50), cover=(0.40, 0.70)),
}


def sky(d, t):
    T = THEMES[t]
    dx, dy, dz = d[..., 0], d[..., 1], d[..., 2]
    el = np.arcsin(np.clip(dz, -1, 1))
    az = np.arctan2(dy, dx)
    elp = np.maximum(el, 0)
    zen, hor = np.array(T['zen']), np.array(T['hor'])
    g = np.exp(-elp / 0.28)[..., None]
    col = zen * (1 - g) + hor * g
    col = col + stars(d, el, T.get('stars', 0))[..., None] * np.array([0.9, 0.92, 1.0])
    seed = sum(map(ord, t))
    if T.get('aurora'):
        wave = 0.35 + 0.08 * np.sin(az * 3.0 + 1.0) + 0.04 * np.sin(az * 7.0)
        band = np.exp(-((el - wave) / 0.07) ** 2)
        rays = 0.55 + 0.45 * fbm(np.stack([az * 18, np.zeros_like(az), np.zeros_like(az)], -1), 3, 41)
        tail = np.exp(-np.clip(el - wave, 0, None) / 0.22) * (el > wave - 0.06)
        aur = (band * 0.8 + tail * 0.5) * rays * smooth(0.04, 0.2, el)
        col = col + aur[..., None] * (np.array([0.15, 0.95, 0.85]) * 0.7 + np.array([0.6, 0.3, 1.0]) * 0.3
                                      * smooth(0.05, 0.3, el - wave)[..., None]) * 0.7
    if T.get('vortex'):
        # spiral storm around the zenith
        r = np.arccos(np.clip(dz, -1, 1))
        spiral = fbm(np.stack([np.cos(az + r * 6) * 3, np.sin(az + r * 6) * 3, r * 4], -1), 5, seed)
        eye = np.exp(-r / 0.10)
        vort = smooth(0.40, 0.75, spiral) * smooth(1.25, 0.2, r)
        col = col + vort[..., None] * np.array([0.45, 0.18, 0.85]) * 0.8 + eye[..., None] * np.array([0.9, 0.7, 1.0])
    md = None
    if T.get('moon'):
        mc = _dir(*T['moon'])
        md = d @ mc
        disc = smooth(T['moon_r'], T['moon_r'] + 0.00025, md)
        halo = np.exp((md - 1) / 0.004) * 0.6 + np.exp((md - 1) / 0.06) * 0.25
        moon_c = np.array(T['moon_c'])
        if T.get('eclipse'):
            ring = np.exp(-((md - T['moon_r']) / 0.00035) ** 2) * 2.5
            corona = np.exp((md - 1) / 0.012) * 1.2 * (0.7 + 0.3 * fbm(d * 40, 3, 7))
            moonrgb = (ring + corona)[..., None] * moon_c
            moonrgb = moonrgb * (1 - disc[..., None])           # black disc
            col = col * (1 - disc[..., None])
        else:
            crater = 0.8 + 0.25 * fbm(d * 90, 4, 3)
            moonrgb = (disc * 1.2 * crater + halo)[..., None] * moon_c
        col = col + moonrgb
    cd, detail = clouds(d, seed % 17, cover=T.get('cover', (0.30, 0.62)))
    under = np.exp(-elp / 0.25)[..., None] * np.array(T['under']) * 0.9
    ccol = np.array(T['cloud']) + under * (0.4 + 0.9 * detail[..., None])
    if md is not None and not T.get('eclipse'):
        ccol = ccol + (np.exp((md - 1) / 0.03) * 0.8)[..., None] * np.array(T['moon_c']) * 0.6
    if T.get('lightning'):
        for k, (a, e) in enumerate(((35, 25), (-110, 35), (160, 20))):
            fl = np.exp((d @ _dir(a, e) - 1) / 0.02)
            ccol = ccol + fl[..., None] * np.array([0.7, 0.6, 1.0]) * 0.9
            # bolt: jagged line below the flash
            bu = az - np.radians(a) + 0.02 * np.sin(el * 90 + k) + 0.01 * np.sin(el * 230)
            bolt = np.exp(-(bu / 0.0025) ** 2) * (el < np.radians(e)) * (el > 0.01)
            col = col + bolt[..., None] * np.array([0.85, 0.8, 1.0]) * 1.4
    col = col * (1 - cd[..., None] * 0.9) + ccol * cd[..., None] * 0.9
    if T.get('embers'):
        em = fbm(d * 160, 1, 77)
        ash = smooth(0.94, 0.995, em) * smooth(-0.02, 0.35, el) * (1 - smooth(0.4, 0.9, el))
        col = col + ash[..., None] * np.array([1.0, 0.45, 0.1]) * 1.3
    for (la, le) in T['logo_dirs']:
        lr, lm = logo_at(d, la, le, 0.62, 0.15, *T['logo'])
        col = col * (1 - 0.45 * lm[..., None]) + lr * (0.75 + 0.4 * cd)[..., None]
    if T.get('fog'):
        fog = np.exp(-np.abs(el) / 0.09)
        col = col * (1 - 0.45 * fog[..., None]) + np.array(T['fog']) * 0.45 * fog[..., None]
    m, extra = silhouette(az, el, T['sil'], seed, 1.0)
    col = np.where(m[..., None], np.array(T['sil_c']) + np.exp(-elp / 0.05)[..., None] * hor * 0.08, col) + extra
    gnd = np.array(T['gnd']) * (0.85 + 0.25 * fbm(d * 30, 3, 51)[..., None])
    col = np.where(((el < -0.004) & ~m)[..., None], gnd, col)
    return np.clip(col, 0, 1)


def render_face(t, face, n, ss=2):
    dd = face_dirs(face, n * ss)
    img = Image.fromarray((sky(dd, t) * 255 + 0.5).astype(np.uint8))
    if ss > 1:
        img = img.resize((n, n), Image.LANCZOS)
    a = np.asarray(img, np.float32) + np.random.default_rng(len(face) * 7 + ord(face[0])).normal(0, 0.6, (n, n, 3))
    return np.clip(a + 0.5, 0, 255).astype(np.uint8)


def panorama(t, w=1200, h=420, el0=-10, el1=80):
    az = np.radians(np.linspace(180, -180, w, endpoint=False))
    el = np.radians(np.linspace(el1, el0, h))
    A, E = np.meshgrid(az, el)
    d = np.stack([np.cos(E) * np.cos(A), np.cos(E) * np.sin(A), np.sin(E)], -1)
    return (sky(d, t) * 255 + 0.5).astype(np.uint8)


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--size', type=int, default=256)
    ap.add_argument('--out', default=os.path.join(REPO, 'cstrike', 'gfx', 'env'))
    ap.add_argument('--only', default='')
    ap.add_argument('--preview', default=None)
    a = ap.parse_args(argv)
    os.makedirs(a.out, exist_ok=True)
    names = [x for x in a.only.split(',') if x] or list(THEMES)
    for t in names:
        faces = {}
        for f in FACES:
            faces[f] = render_face(t, f, a.size)
            write_tga(os.path.join(a.out, f'vexmira_{t}{f}.tga'), faces[f])
        if a.preview:
            os.makedirs(a.preview, exist_ok=True)
            Image.fromarray(cross(faces, a.size)).save(os.path.join(a.preview, f'vexmira_{t}_cross.png'))
            Image.fromarray(panorama(t)).save(os.path.join(a.preview, f'vexmira_{t}_pano.png'))
        print('wrote vexmira_%s' % t, flush=True)


if __name__ == '__main__':
    main()
