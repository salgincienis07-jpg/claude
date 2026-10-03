# Vexmira sprite kit v3 - ortak kutuphane (SPR yazici/okuyucu, supersample tuval, nicemleme, gurultu)
# Tamamen prosedurel; dis kaynak yok. GoldSrc SPR v2 formati.
import struct
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
from scipy.spatial import cKDTree

# --- SPR sabitleri -----------------------------------------------------------
VP_PARALLEL_UPRIGHT, FACING_UPRIGHT, VP_PARALLEL, ORIENTED, VP_PARALLEL_ORIENTED = 0, 1, 2, 3, 4
TF_NORMAL, TF_ADDITIVE, TF_INDEXALPHA, TF_ALPHTEST = 0, 1, 2, 3
TYPE_NAMES = ['VP_PARALLEL_UPRIGHT', 'FACING_UPRIGHT', 'VP_PARALLEL', 'ORIENTED', 'VP_PARALLEL_ORIENTED']
TF_NAMES = ['NORMAL', 'ADDITIVE', 'INDEXALPHA', 'ALPHTEST']


def write_spr(path, frames, sprtype, pal, texfmt, beamlen=0.0):
    """frames: list of (h,w) uint8 palette index arrays. pal: 256 RGB tuples."""
    h, w = frames[0].shape
    assert len(pal) == 256
    with open(path, 'wb') as f:
        f.write(b'IDSP')
        f.write(struct.pack('<iiifiiifi', 2, sprtype, texfmt, float(np.hypot(w / 2, h / 2)),
                            w, h, len(frames), float(beamlen), 0))
        f.write(struct.pack('<h', 256))
        for c in pal:
            f.write(bytes(int(v) & 255 for v in c))
        for fr in frames:
            assert fr.shape == (h, w)
            f.write(struct.pack('<i', 0))  # SPR_SINGLE
            f.write(struct.pack('<iiii', -(w // 2), h // 2, w, h))
            f.write(np.ascontiguousarray(fr, dtype=np.uint8).tobytes())


def read_spr(path):
    """Katı ayrıştırıcı; hatada AssertionError."""
    d = open(path, 'rb').read()
    assert d[:4] == b'IDSP', 'ident'
    ver, typ, fmt, rad, w, h, nf, bl, sync = struct.unpack('<iiifiiifi', d[4:40])
    assert ver == 2, 'version'
    assert 0 <= typ <= 4, 'type'
    assert 0 <= fmt <= 3, 'texfmt'
    assert 1 <= nf <= 1000, 'numframes'
    assert 8 <= w <= 256 and 8 <= h <= 256, 'dims'
    assert abs(rad - np.hypot(w / 2, h / 2)) < 0.01, 'radius'
    pc = struct.unpack('<h', d[40:42])[0]
    assert pc == 256, 'palette count'
    pal = np.frombuffer(d[42:42 + 768], np.uint8).reshape(256, 3)
    pos = 42 + 768
    frames = []
    for _ in range(nf):
        ft = struct.unpack('<i', d[pos:pos + 4])[0]
        ox, oy, fw, fh = struct.unpack('<iiii', d[pos + 4:pos + 20])
        assert ft == 0, 'group frames not used'
        assert fw == w and fh == h, 'frame size'
        assert ox == -(w // 2) and oy == h // 2, 'origin'
        pos += 20
        frames.append(np.frombuffer(d[pos:pos + fw * fh], np.uint8).reshape(fh, fw))
        pos += fw * fh
    assert pos == len(d), ('length', pos, len(d))
    return dict(type=typ, fmt=fmt, w=w, h=h, nf=nf, pal=pal, frames=frames, size=len(d))


# --- paletler ------------------------------------------------------------------
def ramp(stops, gamma=1.0):
    """stops: [(0..1, (r,g,b)), ...] -> 256 renk (indeks = yogunluk)."""
    xs = np.array([s[0] for s in stops], float)
    cs = np.array([s[1] for s in stops], float)
    t = (np.arange(256) / 255.0) ** gamma
    pal = np.stack([np.interp(t, xs, cs[:, j]) for j in range(3)], 1)
    return [tuple(int(round(v)) for v in c) for c in np.clip(pal, 0, 255)]


def grey():
    return [(i, i, i) for i in range(256)]


def to_index(img):
    return (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8)


# --- supersample tuval -------------------------------------------------------
class Canvas:
    """Son piksel koordinatlariyla cizilir; ic cozunurluk ss kat."""

    def __init__(self, w, h, ss=4):
        self.w, self.h, self.ss = w, h, ss
        H, W = h * ss, w * ss
        self.rgb = np.zeros((H, W, 3))
        self.a = np.zeros((H, W))
        yy, xx = np.mgrid[0:H, 0:W]
        self.X = (xx + 0.5) / ss  # son piksel biriminde
        self.Y = (yy + 0.5) / ss

    def mask(self, fn):
        im = Image.new('L', (self.w * self.ss, self.h * self.ss), 0)
        fn(ImageDraw.Draw(im), self.ss)
        return np.asarray(im, float) / 255.0

    def poly(self, pts):
        s = self.ss
        return self.mask(lambda d, _: d.polygon([(x * s, y * s) for x, y in pts], fill=255))

    def ellipse(self, cx, cy, rx, ry):
        return np.clip(1.0 - (np.hypot((self.X - cx) / rx, (self.Y - cy) / ry) - 1.0) * min(rx, ry) * self.ss, 0, 1)

    def circle(self, cx, cy, r):
        return np.clip(r * self.ss - np.hypot(self.X - cx, self.Y - cy) * self.ss + 0.5, 0, 1)

    def line(self, pts, width):
        s = self.ss

        def fn(d, _):
            P = [(x * s, y * s) for x, y in pts]
            d.line(P, fill=255, width=max(1, int(round(width * s))), joint='curve')
            r = width * s / 2
            for x, y in (P[0], P[-1]):
                d.ellipse([x - r, y - r, x + r, y + r], fill=255)
        return self.mask(fn)

    def rrect(self, x0, y0, x1, y1, r):
        s = self.ss
        return self.mask(lambda d, _: d.rounded_rectangle([x0 * s, y0 * s, x1 * s - 1, y1 * s - 1], radius=r * s, fill=255))

    def paint(self, m, col, alpha=1.0):
        """src-over; col: (3,) veya (H,W,3)."""
        m = np.clip(m * alpha, 0, 1)
        col = np.asarray(col, float)
        self.rgb = self.rgb * (1 - m[..., None]) + col * m[..., None]
        self.a = self.a + m * (1 - self.a)

    def down(self):
        s = self.ss
        H, W = self.h, self.w
        rgb = self.rgb.reshape(H, s, W, s, 3).mean((1, 3))
        a = self.a.reshape(H, s, W, s).mean((1, 3))
        return rgb, a

    def downm(self, m):
        s = self.ss
        return m.reshape(self.h, s, self.w, s).mean((1, 3))


def edt_in(m, ss):
    """maske icindeki kenara uzaklik (son piksel biriminde)."""
    return ndimage.distance_transform_edt(m > 0.5) / ss


def edt_out(m, ss):
    return ndimage.distance_transform_edt(m <= 0.5) / ss


def grow(m, r, ss):
    """maskeyi r piksel buyut (yumusak kenarli)."""
    d = edt_out(m, ss)
    return np.clip(r - d + 0.5 / ss * 0 + 0.5, 0, 1) * (d > 0) + (m > 0.5)


def bevel(m, ss, sigma=1.2, light=(-0.45, -0.85), depth=1.0):
    """maskeden kabartma golgesi: -1..1 (isik ust-sol)."""
    h = ndimage.gaussian_filter(m, sigma * ss)
    gy, gx = np.gradient(h)
    gx *= ss * depth * 2.2
    gy *= ss * depth * 2.2
    nz = 1.0
    norm = np.sqrt(gx * gx + gy * gy + nz * nz)
    L = np.array([light[0], light[1], 0.55])
    L = L / np.linalg.norm(L)
    # normal = (-gx, -gy, 1)  (yuksek tarafa dogru egim isiga bakar)
    return ((-gx * L[0] - gy * L[1] + nz * L[2]) / norm - L[2]) / (1 - L[2] + 1e-9)


def lerp(a, b, t):
    a = np.asarray(a, float)
    b = np.asarray(b, float)
    t = np.asarray(t, float)
    if t.ndim:
        t = t[..., None]
    return a + (b - a) * t


def grad_stops(t, stops):
    t = np.clip(np.asarray(t, float), 0, 1)
    xs = np.array([s[0] for s in stops], float)
    cs = np.array([s[1] for s in stops], float)
    return np.stack([np.interp(t, xs, cs[:, j]) for j in range(3)], -1)


def bezier(pts, n=40):
    pts = np.asarray(pts, float)
    t = np.linspace(0, 1, n)[:, None]
    k = len(pts) - 1
    from math import comb
    out = sum(comb(k, i) * (1 - t) ** (k - i) * t ** i * pts[i] for i in range(k + 1))
    return [tuple(p) for p in out]


def ellipse_pts(cx, cy, rx, ry, rot=0.0, n=48):
    t = np.linspace(0, 2 * np.pi, n, endpoint=False)
    x, y = rx * np.cos(t), ry * np.sin(t)
    c, s = np.cos(rot), np.sin(rot)
    return [(cx + x[i] * c - y[i] * s, cy + x[i] * s + y[i] * c) for i in range(n)]


# --- nicemleme (ALPHTEST) ---------------------------------------------------
def quantize_alphatest(frames_rgb, frames_opaque, ncol=255, iters=12, seed=1):
    """Tum kareler icin ortak 255 renk palet; indeks 255 = saydam (siyah)."""
    pix = np.concatenate([np.clip(r[o], 0, 255).round().astype(np.uint8) for r, o in zip(frames_rgb, frames_opaque)])
    uniq, cnt = np.unique(pix, axis=0, return_counts=True)
    if len(uniq) <= ncol:
        centers = uniq.astype(float)
    else:
        # PIL median-cut ile baslat, sonra agirlikli Lloyd (k-means)
        im = Image.fromarray(uniq.reshape(1, -1, 3))
        q = im.quantize(ncol, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
        centers = np.array(q.getpalette()[:ncol * 3], float).reshape(-1, 3)
        u = uniq.astype(float)
        wgt = np.sqrt(cnt.astype(float))  # kucuk ama onemli renkler (kenar, parlama) ezilmesin
        for _ in range(iters):
            _, lab = cKDTree(centers).query(u)
            for k in range(len(centers)):
                sel = lab == k
                if sel.any():
                    centers[k] = (u[sel] * wgt[sel, None]).sum(0) / wgt[sel].sum()
    tree = cKDTree(centers)
    out = []
    for r, o in zip(frames_rgb, frames_opaque):
        idx = np.full(o.shape, 255, np.uint8)
        _, lab = tree.query(np.clip(r[o], 0, 255).reshape(-1, 3))
        idx[o] = lab.astype(np.uint8)
        out.append(idx)
    pal = [tuple(int(round(v)) for v in c) for c in np.clip(centers, 0, 255)]
    pal += [(0, 0, 0)] * (256 - len(pal))
    pal[255] = (0, 0, 0)
    return out, pal


def finalize_rgba(rgb, a, thr=0.5):
    """premultiplied olmayan tuval ciktisini (src-over ile zaten renk) opak maske + renk yap."""
    o = a >= thr
    col = np.where(a[..., None] > 1e-6, rgb / np.maximum(a[..., None], 1e-6), 0)
    return np.clip(col, 0, 255), o


# --- gurultu -----------------------------------------------------------------
def fbm(shape, seed, octaves=5, base=0.25, persist=0.55, wrap=True):
    rng = np.random.default_rng(seed)
    h, w = shape
    out = np.zeros(shape)
    amp, tot = 1.0, 0.0
    sigma = max(h, w) * base / 4
    for _ in range(octaves):
        n = rng.standard_normal(shape)
        n = ndimage.gaussian_filter(n, sigma, mode='wrap' if wrap else 'reflect')
        n /= (n.std() + 1e-9)
        out += amp * n
        tot += amp
        amp *= persist
        sigma /= 2.0
        if sigma < 0.6:
            break
    out /= tot
    out = (out - out.min()) / (out.max() - out.min() + 1e-9)
    return out


def sample(field, x, y):
    """alan uzerinde (x,y) [0..1) sarmal ornekleme."""
    h, w = field.shape
    return ndimage.map_coordinates(field, [np.mod(y, 1.0) * h, np.mod(x, 1.0) * w], order=1, mode='wrap')


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)
