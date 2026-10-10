"""skygen - procedural GoldSrc skybox "vexmira_night" (Cordon 7 night storm sky with the VEXMIRA hologram).

    cd devtools && python3 -m mapkit.skygen [--size 256] [--out ../cstrike/gfx/env] [--preview DIR]

The whole cube is ONE function of the view direction (Quake axes: X east, Y north, Z up), sampled per
face, so the seams match exactly. GoldSrc GL face mapping (gl_warp.c, st_to_vec + skytexorder), image
column s from left to right, image row t from top (+1) to bottom (-1):
    rt (+X): d = ( 1, -s,  t)      lf (-X): d = (-1,  s,  t)
    bk (+Y): d = ( s,  1,  t)      ft (-Y): d = (-s, -1,  t)
    up (+Z): d = (-t, -s,  1)      dn (-Z): d = ( t, -s, -1)
Files: 24-bit uncompressed TGA, bottom-left origin (what the engine's TGA loader expects), 256 x 256
(the size every renderer / old client accepts). The VEXMIRA hologram hangs above the Customs Tower in the
east (+X, the direction the CT spawn and Liberation Plaza look toward), 38 degrees up.
"""
from __future__ import annotations

import argparse
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
NAME = 'vexmira_night'
FACES = ('rt', 'lf', 'bk', 'ft', 'up', 'dn')
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'

MOON = np.array([np.cos(np.radians(48)) * np.cos(np.radians(-135)),
                 np.cos(np.radians(48)) * np.sin(np.radians(-135)), np.sin(np.radians(48))])
FLASH = np.array([np.cos(np.radians(25)) * np.cos(np.radians(150)), np.cos(np.radians(25)) * np.sin(np.radians(150)),
                  np.sin(np.radians(25))])                                   # static lightning-lit cloud (NW)
LOGO_C = np.array([np.cos(np.radians(38)), 0.0, np.sin(np.radians(38))])     # east, 38 deg up
LOGO_W, LOGO_H = 0.95, 0.22                                                   # tangent-plane extents


def face_dirs(face, n):
    s = (np.arange(n) + 0.5) / n * 2 - 1
    S, T = np.meshgrid(s, -s)                      # row 0 = t +1 (top)
    one = np.ones_like(S)
    d = {'rt': (one, -S, T), 'lf': (-one, S, T), 'bk': (S, one, T), 'ft': (-S, -one, T),
         'up': (-T, -S, one), 'dn': (T, -S, -one)}[face]
    d = np.stack(d, -1)
    return d / np.linalg.norm(d, axis=-1, keepdims=True)


# ---------------------------------------------------------------- noise
_RNG = np.random.default_rng(7)
_TAB = _RNG.random(1 << 16)


def _h(ix, iy, iz, seed):
    h = (ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791) ^ (seed * 2654435761)
    return _TAB[h & 0xFFFF]


def vnoise(p, seed=0):
    i = np.floor(p).astype(np.int64)
    f = p - i
    u = f * f * (3 - 2 * f)
    x, y, z = i[..., 0], i[..., 1], i[..., 2]
    ux, uy, uz = u[..., 0], u[..., 1], u[..., 2]
    r = 0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (ux if dx else 1 - ux) * (uy if dy else 1 - uy) * (uz if dz else 1 - uz)
                r = r + w * _h(x + dx, y + dy, z + dz, seed)
    return r


def fbm(p, octaves=6, seed=0, gain=0.5):
    a, s, tot = 1.0, 0.0, 0.0
    for k in range(octaves):
        s = s + a * vnoise(p * (2.0 ** k), seed + k)
        tot += a
        a *= gain
    return s / tot


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


# ---------------------------------------------------------------- logo (tangent plane texture)
def _logo_tex():
    W, H = 2600, 600
    img = Image.new('L', (W, H), 0)
    dr = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype(FONT, 380)
    except OSError:
        font = ImageFont.load_default()
    txt = 'VEXMIRA'
    bb = dr.textbbox((0, 0), txt, font=font, stroke_width=0)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    # letter spacing: draw per character
    xs, x = [], 0
    for ch in txt:
        b = dr.textbbox((0, 0), ch, font=font)
        xs.append(x - b[0])
        x += (b[2] - b[0]) + 70
    x -= 70
    ox, oy = (W - x) // 2, (H - th) // 2 - bb[1]
    for ch, cx in zip(txt, xs):
        dr.text((ox + cx, oy), ch, fill=255, font=font)
    m = np.asarray(img, np.float32) / 255
    # neon tube: outline ring of the glyphs (hollow letters) + thin core
    er = np.asarray(img.filter(ImageFilter.MinFilter(17)), np.float32) / 255
    tube = np.clip(m - er, 0, 1)
    tube = np.asarray(Image.fromarray((tube * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3)),
                      np.float32) / 255
    fill = m * 0.22
    glow = np.asarray(img.filter(ImageFilter.GaussianBlur(28)), np.float32) / 255
    halo = np.asarray(img.filter(ImageFilter.GaussianBlur(90)), np.float32) / 255
    # underline bar + bracket ticks ("projected HUD")
    bar = np.zeros_like(m)
    y0 = int(oy + th + bb[1] + 40)
    bar[y0:y0 + 12, (W - x) // 2:(W + x) // 2] = 1
    bar[y0 - 60:y0 + 12, (W - x) // 2 - 40:(W - x) // 2 - 28] = 1
    bar[y0 - 60:y0 + 12, (W + x) // 2 + 28:(W + x) // 2 + 40] = 1
    bar = np.asarray(Image.fromarray((bar * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2)),
                     np.float32) / 255
    return dict(tube=tube, fill=fill, glow=glow, halo=halo, bar=bar)


_LOGO = None


def logo(d):
    """Returns (rgb add, mask) of the hologram for directions d."""
    global _LOGO
    if _LOGO is None:
        _LOGO = _logo_tex()
    c = LOGO_C
    e1 = np.array([0.0, -1.0, 0.0])                        # screen right when facing east
    e2 = np.cross(e1, c) * -1                               # screen up
    e2 = e2 / np.linalg.norm(e2)
    if e2[2] < 0:
        e2 = -e2
    dc = d @ c
    ok = dc > 0.3
    p = d / np.maximum(dc, 1e-3)[..., None]
    x = p @ e1
    y = p @ e2
    tex = _LOGO
    H, W = tex['tube'].shape
    # glitch: two horizontal slices shifted sideways
    gy = (y / LOGO_H * 0.5 + 0.5)
    x = x + 0.012 * ((gy > 0.58) & (gy < 0.61))
    u = (x / LOGO_W * 0.5 + 0.5) * (W - 1)
    v = (0.5 - y / LOGO_H * 0.5) * (H - 1)
    inside = ok & (u >= 0) & (u <= W - 1) & (v >= 0) & (v <= H - 1)
    ui = np.clip(u, 0, W - 1).astype(int)
    vi = np.clip(v, 0, H - 1).astype(int)

    def S(k):
        return np.where(inside, tex[k][vi, ui], 0.0)

    tube, fill, glow, halo, bar = S('tube'), S('fill'), S('glow'), S('halo'), S('bar')
    # chromatic offset: cyan ghost slightly up-left
    ui2 = np.clip(u - 14, 0, W - 1).astype(int)
    vi2 = np.clip(v - 9, 0, H - 1).astype(int)
    ghost = np.where(inside, tex['tube'][vi2, ui2], 0.0)
    scan = 0.86 + 0.14 * np.sin(v * 0.21) ** 2
    purple = np.array([0.80, 0.30, 1.00])
    core = np.array([1.00, 0.85, 1.00])
    cyan = np.array([0.20, 0.90, 1.00])
    rgb = (tube[..., None] * (0.55 * purple + 0.75 * core) + fill[..., None] * purple
           + glow[..., None] * 0.55 * purple + halo[..., None] * 0.30 * np.array([0.55, 0.15, 0.85])
           + ghost[..., None] * 0.35 * cyan + bar[..., None] * 0.7 * cyan) * scan[..., None]
    return rgb, np.clip(tube + fill + glow * 0.5, 0, 1)


# ---------------------------------------------------------------- skyline
def _skyline_tables():
    r = np.random.default_rng(11)
    layers = []
    for lay, (wmin, wmax, hmin, hmax, gap) in enumerate(((0.003, 0.012, 0.012, 0.050, 0.0),
                                                         (0.006, 0.030, 0.000, 0.105, 0.25))):
        edges, hs = [0.0], []
        while edges[-1] < 1:
            w = r.uniform(wmin, wmax)
            h = r.uniform(hmin, hmax) ** 1.0
            if r.random() < gap:
                h = r.uniform(0.0, 0.012)
            # taller blocks toward the north (city) and the east (tower district), low in the south (bay)
            edges.append(edges[-1] + w)
            hs.append(h)
        edges = np.array(edges[:-1] + [1.0])
        hs = np.array(hs)
        layers.append((edges, hs))
    return layers


_SKY = _skyline_tables()


def skyline(az, el):
    """Returns (mask_far, mask_near, rgb_near_extra) ; az in [-pi, pi]."""
    u = (az + np.pi) / (2 * np.pi) % 1.0
    # height envelope: harbor (south, az ~ -90 deg) is open water with cranes, city elsewhere
    env = 0.35 + 0.65 * smooth(0.25, 0.9, np.sin(az) * 0.5 + 0.5 + 0.35 * np.cos(az))
    out = []
    for edges, hs in _SKY:
        k = np.clip(np.searchsorted(edges, u, side='right') - 1, 0, len(hs) - 1)
        h = hs[k] * env
        out.append((k, h, (el < h)))
    (kf, hf, mf), (kn, hn, mn) = out
    # windows on the near layer
    cu = np.floor(u * 1100).astype(np.int64)
    ce = np.floor(el * 260).astype(np.int64)
    rnd = _h(cu, ce, kn, 99)
    lit = mn & (el > 0.004) & (el < hn - 0.006) & (rnd < 0.075)
    wcol = np.where((rnd < 0.012)[..., None], np.array([0.25, 0.75, 0.85]), np.array([1.0, 0.62, 0.25]))
    extra = lit[..., None] * wcol * (0.35 + 2.5 * _h(cu, ce, 5, 7))[..., None] * 0.55
    # red aircraft-warning lights on the tallest near blocks
    edges, hs = _SKY[1]
    tall = np.where(hs * 1.0 > 0.085)[0]
    for t in tall:
        cuu = (edges[t] + edges[t + 1]) * 0.5
        ca = cuu * 2 * np.pi - np.pi
        envt = 0.35 + 0.65 * smooth(0.25, 0.9, np.sin(ca) * 0.5 + 0.5 + 0.35 * np.cos(ca))
        ht = hs[t] * envt
        if ht < 0.06:
            continue
        da = (np.angle(np.exp(1j * (az - ca))))
        r2 = (da / 0.006) ** 2 + ((el - ht - 0.004) / 0.006) ** 2
        extra = extra + (np.exp(-r2) * 2.2 + np.exp(-r2 / 9) * 0.35)[..., None] * np.array([1.0, 0.08, 0.04])
    return mf, mn, extra


# ---------------------------------------------------------------- the sky function
def sky(d):
    dx, dy, dz = d[..., 0], d[..., 1], d[..., 2]
    el = np.arcsin(np.clip(dz, -1, 1))
    az = np.arctan2(dy, dx)
    ca, sa = np.cos(az), np.sin(az)

    # horizon fire glow per direction (burning city north + east, freighter south-east)
    gn = fbm(np.stack([ca * 1.6, sa * 1.6, np.full_like(ca, 3.3)], -1), 4, 21)
    glow_amt = np.clip(0.35 + 1.3 * (gn - 0.45) + 0.25 * np.cos(az - np.radians(70)), 0.12, 1.2)
    elp = np.maximum(el, 0)
    hz = np.exp(-elp / 0.10) * glow_amt
    hz2 = np.exp(-elp / 0.35) * glow_amt

    zen = np.array([0.020, 0.020, 0.045])
    mid = np.array([0.060, 0.040, 0.085])
    fire = np.array([0.85, 0.30, 0.08])
    col = zen + (mid - zen) * np.exp(-elp / 0.7)[..., None]
    col = col + hz[..., None] * fire * 0.75 + hz2[..., None] * np.array([0.30, 0.09, 0.10]) * 0.6

    # aurora-like Vexmira haze (purple -> cyan curtains)
    ce = 0.50 + 0.12 * np.sin(2 * az + 0.6) + 0.06 * np.sin(5 * az)
    band = np.exp(-((el - ce) / 0.16) ** 2)
    rays = fbm(np.stack([ca * 9, sa * 9, el * 1.5], -1), 4, 33)
    rays = smooth(0.35, 0.85, rays)
    mixc = 0.5 + 0.5 * np.sin(az * 1.0 + 1.2)
    acol = np.array([0.42, 0.10, 0.62]) * (1 - mixc[..., None]) + np.array([0.06, 0.45, 0.55]) * mixc[..., None]
    aur = (band * (0.25 + rays))[..., None] * acol * 0.55

    # cloud layer (planar projection -> perspective near the horizon)
    k = 1.0 / (np.maximum(dz, 0) + 0.10)
    cp = np.stack([dx * k * 0.55, dy * k * 0.55, np.full_like(dx, 1.7)], -1)
    warp = fbm(cp * 0.8 + 5.1, 3, 41)
    cn = fbm(cp + warp[..., None] * 1.4, 7, 51)
    cd = smooth(0.30, 0.62, cn) * (0.55 + 0.45 * smooth(-0.02, 0.15, el))
    detail = fbm(cp * 3.0, 4, 61)
    # underside light: fire from below near the horizon, purple haze higher, moon rim
    md = d @ MOON
    under = hz2[..., None] * np.array([0.75, 0.28, 0.10]) * 1.5 + band[..., None] * acol * 0.35
    rim = (np.exp((md - 1) / 0.03) * 0.9)[..., None] * np.array([0.65, 0.70, 0.85])
    flash = np.exp((d @ FLASH - 1) / 0.03)[..., None] * np.array([0.55, 0.60, 0.95]) * 0.8
    cloud = flash + np.array([0.050, 0.040, 0.060]) + under * (0.4 + 0.9 * detail[..., None]) + rim * (1 - cd)[..., None]

    # moon behind thin clouds
    disc = smooth(0.99945, 0.99965, md)
    halo = np.exp((md - 1) / 0.004) * 0.6 + np.exp((md - 1) / 0.05) * 0.15
    mcol = np.array([0.92, 0.94, 1.0])
    moon = (disc * 1.1 + halo)[..., None] * mcol

    col = col + aur * (1 - 0.75 * cd)[..., None] + moon * (1 - 0.8 * cd)[..., None]
    col = col * (1 - cd[..., None] * 0.92) + cloud * cd[..., None] * 0.92 + aur * cd[..., None] * 0.35

    # searchlight beams (volumetric in the haze): 2 aimed at the hologram, 3 sweeping elsewhere
    beams = np.zeros_like(col)
    for baz, tilt, tgt, w in ((-25, 0, True, 0.010), (28, 0, True, 0.010), (150, 62, False, 0.012),
                              (-150, -55, False, 0.012), (100, 70, False, 0.010)):
        b = np.array([np.cos(np.radians(baz)), np.sin(np.radians(baz)), 0.0])
        if tgt:
            t = LOGO_C
        else:
            t = np.array([np.cos(np.radians(baz + tilt * 0.3)) * np.cos(np.radians(tilt)),
                          np.sin(np.radians(baz + tilt * 0.3)) * np.cos(np.radians(tilt)), np.sin(np.radians(abs(tilt)))])
        n = np.cross(b, t)
        n /= np.linalg.norm(n)
        along = d @ b
        dist = np.abs(d @ n)
        fw = np.exp(-(dist / (w * (1 + 1.5 * (1 - np.clip(along, 0, 1))))) ** 2)
        seg = smooth(-0.02, 0.03, el) * np.clip(along, 0, 1) ** 2 * (np.arccos(np.clip(d @ t, -1, 1)) < np.arccos(b @ t) + 0.02)
        beams = beams + (fw * seg)[..., None] * np.array([0.55, 0.62, 0.75]) * 0.55
    col = col + beams * (0.55 + 0.6 * cd)[..., None]

    # VEXMIRA hologram projected into the clouds
    lrgb, lm = logo(d)
    col = col + lrgb * (0.60 + 0.55 * cd)[..., None]

    # skyline (far layer hazed, near layer black with windows + red lights)
    mf, mn, extra = skyline(az, el)
    farc = np.array([0.10, 0.045, 0.035]) + hz[..., None] * fire * 0.30
    nearc = np.array([0.014, 0.011, 0.016]) + hz[..., None] * fire * 0.05
    col = np.where(mf[..., None], farc, col)
    col = np.where(mn[..., None], nearc, col)
    col = col + extra

    # below the horizon: dark ground / water with a little fire reflection
    below = el < 0
    gnd = np.array([0.012, 0.010, 0.016]) + (np.exp(el / 0.05) * glow_amt)[..., None] * fire * 0.12
    col = np.where(below[..., None] & ~mn[..., None], gnd, col)
    return np.clip(col, 0, 1)


def render_face(face, n, ss=2):
    d = face_dirs(face, n * ss)
    c = sky(d)
    img = Image.fromarray((np.clip(c, 0, 1) ** (1 / 1.0) * 255 + 0.5).astype(np.uint8))
    if ss > 1:
        img = img.resize((n, n), Image.LANCZOS)
    a = np.asarray(img, np.float32)
    a = a + np.random.default_rng(hash(face) & 0xFFFF).normal(0, 0.6, a.shape)   # grain vs banding
    return np.clip(a + 0.5, 0, 255).astype(np.uint8)


def write_tga(path, rgb):
    h, w, _ = rgb.shape
    hdr = bytes([0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, w & 255, w >> 8, h & 255, h >> 8, 24, 0])
    data = rgb[::-1, :, ::-1].tobytes()                     # bottom-up rows, BGR
    with open(path, 'wb') as f:
        f.write(hdr + data)


def panorama(w=1536, h=640, el0=-20, el1=90):
    az = np.radians(np.linspace(180, -180, w, endpoint=False))   # left = west... looking around clockwise
    el = np.radians(np.linspace(el1, el0, h))
    A, E = np.meshgrid(az, el)
    d = np.stack([np.cos(E) * np.cos(A), np.cos(E) * np.sin(A), np.sin(E)], -1)
    return (sky(d) * 255 + 0.5).astype(np.uint8)


def cross(faces, n):
    img = np.zeros((3 * n, 4 * n, 3), np.uint8)
    for f, (r, c) in {'bk': (1, 0), 'rt': (1, 1), 'ft': (1, 2), 'lf': (1, 3), 'up': (0, 1), 'dn': (2, 1)}.items():
        img[r * n:(r + 1) * n, c * n:(c + 1) * n] = faces[f]
    return img


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--size', type=int, default=256)
    ap.add_argument('--out', default=os.path.join(REPO, 'cstrike', 'gfx', 'env'))
    ap.add_argument('--preview', default=None, help='also write cross + panorama PNGs here')
    a = ap.parse_args(argv)
    os.makedirs(a.out, exist_ok=True)
    faces = {}
    for f in FACES:
        faces[f] = render_face(f, a.size)
        write_tga(os.path.join(a.out, f'{NAME}{f}.tga'), faces[f])
        print('wrote', os.path.join(a.out, f'{NAME}{f}.tga'))
    if a.preview:
        os.makedirs(a.preview, exist_ok=True)
        Image.fromarray(cross(faces, a.size)).save(os.path.join(a.preview, f'{NAME}_cross.png'))
        Image.fromarray(panorama()).save(os.path.join(a.preview, f'{NAME}_panorama.png'))
        Image.fromarray(render_face('rt', 768, 1)).save(os.path.join(a.preview, f'{NAME}_east_vexmira.png'))
        print('previews in', a.preview)


if __name__ == '__main__':
    main()
