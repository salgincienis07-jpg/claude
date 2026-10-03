"""Procedural texture primitives (numpy): tileable noise, voronoi, shading,
shape masks and an original stroke font. All functions are deterministic for
a given numpy Generator and every result tiles seamlessly (wrap-around).

Images are float32 arrays in 0..1, shape (H, W) for masks / height maps and
(H, W, 3) for colour.
"""
from __future__ import annotations

import math
from typing import Iterable, List, Sequence, Tuple

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

F = np.float32


# ----------------------------------------------------------------------
# noise
# ----------------------------------------------------------------------
def _smooth(t):
    return t * t * (3 - 2 * t)


def value_noise_at(grid: np.ndarray, x: np.ndarray, y: np.ndarray) -> np.ndarray:
    """Sample periodic lattice `grid` (gh, gw) at lattice coords x, y (float arrays)."""
    gh, gw = grid.shape
    x0 = np.floor(x).astype(np.int64)
    y0 = np.floor(y).astype(np.int64)
    fx = _smooth(x - x0)
    fy = _smooth(y - y0)
    x0m, x1m = x0 % gw, (x0 + 1) % gw
    y0m, y1m = y0 % gh, (y0 + 1) % gh
    a = grid[y0m, x0m]
    b = grid[y0m, x1m]
    c = grid[y1m, x0m]
    d = grid[y1m, x1m]
    return (a + (b - a) * fx) * (1 - fy) + (c + (d - c) * fx) * fy


def value_noise(h: int, w: int, cx: int, cy: int, rng, ox=0.0, oy=0.0) -> np.ndarray:
    """Tileable value noise with cx x cy lattice cells across the image."""
    grid = rng.random((cy, cx)).astype(F)
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    return value_noise_at(grid, (xs + ox) * cx / w, (ys + oy) * cy / h).astype(F)


def fbm(h: int, w: int, cells: int, rng, octaves: int = 5, persistence: float = 0.5,
        aspect: Tuple[float, float] = (1, 1), warp=None) -> np.ndarray:
    """Tileable fractal noise normalised to 0..1.

    aspect=(ax, ay) multiplies the cell counts per axis (streaks: (4,1) etc.).
    warp=(dx, dy) pixel offset arrays for domain warping.
    """
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    if warp is not None:
        xs = xs + warp[0]
        ys = ys + warp[1]
    out = np.zeros((h, w), F)
    amp, tot = 1.0, 0.0
    c = cells
    for o in range(octaves):
        cx = max(1, int(round(c * aspect[0])))
        cy = max(1, int(round(c * aspect[1])))
        grid = rng.random((cy, cx)).astype(F)
        out += amp * value_noise_at(grid, xs * cx / w, ys * cy / h)
        tot += amp
        amp *= persistence
        c *= 2
        if c > max(h, w):
            break
    out /= tot
    lo, hi = out.min(), out.max()
    return ((out - lo) / max(hi - lo, 1e-6)).astype(F)


def white(h, w, rng) -> np.ndarray:
    return rng.random((h, w)).astype(F)


def voronoi(h: int, w: int, n: int, rng, points=None):
    """Tileable voronoi: returns (F1, F2, cell_id) with distances in pixels."""
    if points is None:
        points = rng.random((n, 2)) * [w, h]
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    f1 = np.full((h, w), 1e9, F)
    f2 = np.full((h, w), 1e9, F)
    idx = np.zeros((h, w), np.int32)
    for i, (px, py) in enumerate(points):
        dx = np.abs(xs - px)
        dx = np.minimum(dx, w - dx)
        dy = np.abs(ys - py)
        dy = np.minimum(dy, h - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < f1
        f2 = np.where(closer, f1, np.minimum(f2, d))
        idx = np.where(closer, i, idx)
        f1 = np.where(closer, d, f1)
    return f1, f2, idx


def blur(a: np.ndarray, s: float) -> np.ndarray:
    if a.ndim == 3:
        return np.stack([ndimage.gaussian_filter(a[..., i], s, mode='wrap') for i in range(a.shape[2])], -1).astype(F)
    return ndimage.gaussian_filter(a, s, mode='wrap').astype(F)


# ----------------------------------------------------------------------
# colour helpers
# ----------------------------------------------------------------------
def rgb(*c) -> np.ndarray:
    if len(c) == 1:
        c = c[0]
    return np.array(c, F) / (255.0 if max(c) > 1.0 else 1.0)


def ramp(t: np.ndarray, stops: Sequence[Tuple[float, Sequence[float]]]) -> np.ndarray:
    """Map scalar field t (0..1) through colour stops [(pos, (r,g,b) 0..255)]."""
    pos = np.array([s[0] for s in stops], F)
    cols = np.array([s[1] for s in stops], F) / 255.0
    out = np.empty(t.shape + (3,), F)
    for ch in range(3):
        out[..., ch] = np.interp(t, pos, cols[:, ch])
    return out


def mix(a, b, t):
    t = np.asarray(t, F)
    if t.ndim == 2 and np.ndim(a) == 3 or (t.ndim == 2 and np.ndim(b) == 3):
        t = t[..., None]
    return (a * (1 - t) + b * t).astype(F)


def fill(h, w, color) -> np.ndarray:
    return np.broadcast_to(rgb(color), (h, w, 3)).astype(F).copy()


def shade(height: np.ndarray, strength: float = 4.0, light=(-0.55, -0.7, 0.9),
          amount: float = 1.0) -> np.ndarray:
    """Baked relief lighting factor (~1.0 on flat areas) from a height map."""
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * 0.5 * strength
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * 0.5 * strength
    nz = 1.0 / np.sqrt(dx * dx + dy * dy + 1)
    nx, ny = -dx * nz, -dy * nz
    L = np.array(light, F)
    L = L / np.linalg.norm(L)
    lam = nx * L[0] + ny * L[1] + nz * L[2]
    flat = L[2]
    f = 1.0 + (lam - flat) / flat * amount
    return np.clip(f, 0.25, 1.9).astype(F)


def apply_shade(img: np.ndarray, factor: np.ndarray) -> np.ndarray:
    return np.clip(img * factor[..., None], 0, 1).astype(F)


def ao(height: np.ndarray, radius: float = 3.0, amount: float = 0.6) -> np.ndarray:
    """Cheap cavity / ambient-occlusion factor from a height map."""
    b = blur(height, radius)
    cav = np.clip((b - height) * 4.0, 0, 1)
    return (1.0 - cav * amount).astype(F)


def grain(img: np.ndarray, rng, amount: float = 0.04) -> np.ndarray:
    n = (rng.random(img.shape[:2]).astype(F) - 0.5) * amount
    return np.clip(img + n[..., None], 0, 1).astype(F)


def levels(img, black=0.0, white=1.0, gamma=1.0):
    return np.clip(((img - black) / (white - black)) ** (1.0 / gamma), 0, 1).astype(F)


# ----------------------------------------------------------------------
# masks / drawing (PIL, 4x supersampled for anti-aliasing, wrap aware)
# ----------------------------------------------------------------------
class Canvas:
    """Grayscale supersampled drawing surface returning a float mask."""

    def __init__(self, h, w, ss=4):
        self.h, self.w, self.ss = h, w, ss
        self.im = Image.new('L', (w * ss, h * ss), 0)
        self.d = ImageDraw.Draw(self.im)

    def _offsets(self, wrap):
        if not wrap:
            return [(0, 0)]
        return [(ox, oy) for ox in (-self.w, 0, self.w) for oy in (-self.h, 0, self.h)]

    def rect(self, x0, y0, x1, y1, v=255, wrap=False, radius=0):
        s = self.ss
        for ox, oy in self._offsets(wrap):
            box = [(x0 + ox) * s, (y0 + oy) * s, (x1 + ox) * s - 1, (y1 + oy) * s - 1]
            if radius:
                self.d.rounded_rectangle(box, radius * s, fill=v)
            else:
                self.d.rectangle(box, fill=v)

    def ellipse(self, cx, cy, rx, ry, v=255, wrap=False):
        s = self.ss
        for ox, oy in self._offsets(wrap):
            self.d.ellipse([(cx - rx + ox) * s, (cy - ry + oy) * s, (cx + rx + ox) * s, (cy + ry + oy) * s], fill=v)

    def poly(self, pts, v=255, wrap=False):
        s = self.ss
        for ox, oy in self._offsets(wrap):
            self.d.polygon([((x + ox) * s, (y + oy) * s) for x, y in pts], fill=v)

    def line(self, pts, width=1.0, v=255, wrap=False, joint=True):
        s = self.ss
        for ox, oy in self._offsets(wrap):
            p = [((x + ox) * s, (y + oy) * s) for x, y in pts]
            self.d.line(p, fill=v, width=max(1, int(round(width * s))), joint='curve' if joint else None)
            if joint:
                r = width * s / 2
                for x, y in p:
                    self.d.ellipse([x - r, y - r, x + r, y + r], fill=v)

    def text(self, txt, x, y, height, width=None, v=255, spacing=1.25, italic=0.0, wrap=False):
        draw_text(self, txt, x, y, height, width, v, spacing, italic, wrap)

    def mask(self) -> np.ndarray:
        im = self.im.resize((self.w, self.h), Image.BOX)
        return np.asarray(im, F) / 255.0


# --- original stroke font (grid 4 x 6, y down) -------------------------
_O = [(1, 0), (3, 0), (4, 1), (4, 5), (3, 6), (1, 6), (0, 5), (0, 1), (1, 0)]
GLYPHS = {
    'A': [[(0, 6), (0, 2), (2, 0), (4, 2), (4, 6)], [(0, 3.6), (4, 3.6)]],
    'B': [[(0, 3), (0, 0), (3, 0), (4, 1), (4, 2), (3, 3), (0, 3), (0, 6), (3, 6), (4, 5), (4, 4), (3, 3)]],
    'C': [[(4, 0.6), (3.4, 0), (1, 0), (0, 1), (0, 5), (1, 6), (3.4, 6), (4, 5.4)]],
    'D': [[(0, 0), (0, 6), (2.8, 6), (4, 4.8), (4, 1.2), (2.8, 0), (0, 0)]],
    'E': [[(4, 0), (0, 0), (0, 6), (4, 6)], [(0, 3), (3, 3)]],
    'F': [[(4, 0), (0, 0), (0, 6)], [(0, 3), (3, 3)]],
    'G': [[(4, 1), (3, 0), (1, 0), (0, 1), (0, 5), (1, 6), (3, 6), (4, 5), (4, 3.2), (2.2, 3.2)]],
    'H': [[(0, 0), (0, 6)], [(4, 0), (4, 6)], [(0, 3), (4, 3)]],
    'I': [[(1, 0), (3, 0)], [(2, 0), (2, 6)], [(1, 6), (3, 6)]],
    'J': [[(4, 0), (4, 5), (3, 6), (1, 6), (0, 5)]],
    'K': [[(0, 0), (0, 6)], [(4, 0), (0, 3.6)], [(1.4, 2.6), (4, 6)]],
    'L': [[(0, 0), (0, 6), (4, 6)]],
    'M': [[(0, 6), (0, 0), (2, 3), (4, 0), (4, 6)]],
    'N': [[(0, 6), (0, 0), (4, 6), (4, 0)]],
    'O': [_O],
    'P': [[(0, 6), (0, 0), (3, 0), (4, 1), (4, 2), (3, 3), (0, 3)]],
    'Q': [_O, [(2.6, 4.6), (4, 6.2)]],
    'R': [[(0, 6), (0, 0), (3, 0), (4, 1), (4, 2), (3, 3), (0, 3)], [(2, 3), (4, 6)]],
    'S': [[(4, 1), (3, 0), (1, 0), (0, 1), (0, 2), (1, 3), (3, 3), (4, 4), (4, 5), (3, 6), (1, 6), (0, 5)]],
    'T': [[(0, 0), (4, 0)], [(2, 0), (2, 6)]],
    'U': [[(0, 0), (0, 5), (1, 6), (3, 6), (4, 5), (4, 0)]],
    'V': [[(0, 0), (2, 6), (4, 0)]],
    'W': [[(0, 0), (1, 6), (2, 2.6), (3, 6), (4, 0)]],
    'X': [[(0, 0), (4, 6)], [(4, 0), (0, 6)]],
    'Y': [[(0, 0), (2, 3), (4, 0)], [(2, 3), (2, 6)]],
    'Z': [[(0, 0), (4, 0), (0, 6), (4, 6)]],
    '0': [_O, [(3.4, 0.9), (0.6, 5.1)]],
    '1': [[(1, 1.2), (2, 0), (2, 6)], [(1, 6), (3, 6)]],
    '2': [[(0, 1), (1, 0), (3, 0), (4, 1), (4, 2.2), (0, 6), (4, 6)]],
    '3': [[(0, 0), (4, 0), (2, 2.5), (3, 2.5), (4, 3.5), (4, 5), (3, 6), (1, 6), (0, 5)]],
    '4': [[(3, 6), (3, 0), (0, 4), (4, 4)]],
    '5': [[(4, 0), (0, 0), (0, 3), (3, 3), (4, 4), (4, 5), (3, 6), (0, 6)]],
    '6': [[(4, 0), (1, 0), (0, 1), (0, 5), (1, 6), (3, 6), (4, 5), (4, 4), (3, 3), (0, 3)]],
    '7': [[(0, 0), (4, 0), (1.5, 6)]],
    '8': [[(1, 3), (0, 2), (0, 1), (1, 0), (3, 0), (4, 1), (4, 2), (3, 3), (1, 3), (0, 4), (0, 5), (1, 6), (3, 6), (4, 5), (4, 4), (3, 3)]],
    '9': [[(4, 3), (1, 3), (0, 2), (0, 1), (1, 0), (3, 0), (4, 1), (4, 5), (3, 6), (0, 6)]],
    '-': [[(0.6, 3), (3.4, 3)]],
    '.': [[(1.8, 5.7), (2.2, 5.7)]],
    '/': [[(0, 6), (4, 0)]],
    ':': [[(2, 1.6), (2, 1.9)], [(2, 4.6), (2, 4.9)]],
    '>': [[(0.5, 0.5), (3.5, 3), (0.5, 5.5)]],
    '<': [[(3.5, 0.5), (0.5, 3), (3.5, 5.5)]],
    '!': [[(2, 0), (2, 4)], [(2, 5.6), (2, 5.9)]],
    '_': [[(0, 6), (4, 6)]],
    '#': [[(1.3, 0), (0.7, 6)], [(3.3, 0), (2.7, 6)], [(0, 2), (4, 2)], [(0, 4), (4, 4)]],
    '%': [[(0, 6), (4, 0)], [(0.6, 0.6), (0.7, 0.7)], [(3.3, 5.3), (3.4, 5.4)]],
    '+': [[(2, 1.5), (2, 4.5)], [(0.5, 3), (3.5, 3)]],
    '=': [[(0.5, 2), (3.5, 2)], [(0.5, 4), (3.5, 4)]],
    ' ': [],
}


def text_width(txt: str, height: float, spacing: float = 1.25) -> float:
    s = height / 6.0
    return len(txt) * (4 + spacing * 4 * 0.5) * s - spacing * 4 * 0.5 * s


def draw_text(cv: Canvas, txt, x, y, height, width=None, v=255, spacing=1.25, italic=0.0, wrap=False):
    """Draw text with the stroke font. (x, y) = top-left; width = stroke px."""
    s = height / 6.0
    if width is None:
        width = max(1.0, s * 0.9)
    adv = (4 + spacing * 4 * 0.5) * s
    for i, ch in enumerate(txt.upper()):
        for stroke in GLYPHS.get(ch, []):
            pts = [(x + i * adv + (gx + italic * (6 - gy)) * s, y + gy * s) for gx, gy in stroke]
            cv.line(pts, width, v, wrap=wrap)


def stroke_mask(h, w, txt, height, width=None, spacing=1.25, italic=0.0) -> np.ndarray:
    """Centered text mask."""
    cv = Canvas(h, w)
    tw = text_width(txt, height, spacing) + italic * height
    draw_text(cv, txt, (w - tw) / 2, (h - height) / 2, height, width, 255, spacing, italic)
    return cv.mask()


# ----------------------------------------------------------------------
# structured patterns
# ----------------------------------------------------------------------
def grid_cells(h, w, cw, ch, offset_rows=0.0):
    """Running bond / grid cell coordinates.

    Returns (local_x, local_y, cell_id) with local coords in pixels.
    offset_rows: fraction of cw to shift every second row (0.5 = running bond)
    """
    ys, xs = np.mgrid[0:h, 0:w]
    row = ys // ch
    shift = ((row % 2) * offset_rows * cw).astype(np.int64)
    xx = (xs + shift) % w
    col = xx // cw
    lx = xx - col * cw
    ly = ys - row * ch
    ncols = int(math.ceil(w / cw))
    cid = row * (ncols + 1) + col
    return lx.astype(F), ly.astype(F), cid


def bevel_mask(lx, ly, cw, ch, gap, bevel):
    """Height map of a rectangular block with mortar gap and bevelled edge."""
    dx = np.minimum(lx, cw - 1 - lx) - gap / 2.0
    dy = np.minimum(ly, ch - 1 - ly) - gap / 2.0
    d = np.minimum(dx, dy)
    return np.clip(d / max(bevel, 1e-3), 0, 1).astype(F)


def per_cell(cid, rng, lo=0.0, hi=1.0):
    vals = rng.uniform(lo, hi, int(cid.max()) + 1).astype(F)
    return vals[cid]


def scratches(h, w, rng, n=60, length=(6, 30), width=0.6, angle=None) -> np.ndarray:
    cv = Canvas(h, w)
    for _ in range(n):
        x, y = rng.random() * w, rng.random() * h
        a = rng.random() * math.pi if angle is None else angle + rng.normal(0, 0.15)
        L = rng.uniform(*length)
        cv.line([(x, y), (x + math.cos(a) * L, y + math.sin(a) * L)], width, int(rng.uniform(90, 255)), wrap=True, joint=False)
    return cv.mask()


def rivets(cv: Canvas, pts, r=2.2, v=255):
    for x, y in pts:
        cv.ellipse(x, y, r, r, v)


def streaks(h, w, rng, density=24, length=0.35) -> np.ndarray:
    """Vertical drip / water streaks, 0..1 (strong at top)."""
    n = fbm(h, w, 4, rng, octaves=3, aspect=(density / 4.0, 0.25))
    n = np.clip((n - 0.45) * 2.2, 0, 1)
    return n.astype(F)


def cracks(h, w, rng, n=10, thickness=1.2, coverage=0.55, warp=6.0) -> np.ndarray:
    """Crack mask from warped voronoi edges, partly masked out."""
    wx = (fbm(h, w, 4, rng, 4) - 0.5) * warp * 2
    wy = (fbm(h, w, 4, rng, 4) - 0.5) * warp * 2
    pts = rng.random((n, 2)) * [w, h]
    ys, xs = np.mgrid[0:h, 0:w].astype(F)
    xs = (xs + wx) % w
    ys = (ys + wy) % h
    f1 = np.full((h, w), 1e9, F)
    f2 = np.full((h, w), 1e9, F)
    for px, py in pts:
        dx = np.abs(xs - px); dx = np.minimum(dx, w - dx)
        dy = np.abs(ys - py); dy = np.minimum(dy, h - dy)
        d = np.sqrt(dx * dx + dy * dy)
        c = d < f1
        f2 = np.where(c, f1, np.minimum(f2, d))
        f1 = np.where(c, d, f1)
    edge = np.clip(1.0 - (f2 - f1) / thickness, 0, 1)
    keep = fbm(h, w, 3, rng, 3)
    keep = np.clip((keep - (1 - coverage)) * 6, 0, 1)
    fine = fbm(h, w, 16, rng, 3)
    return (edge * keep * (0.6 + 0.4 * fine)).astype(F)


def splatter(h, w, rng, blobs=14, spread=0.32, drips=5) -> np.ndarray:
    """Organic splatter alpha mask centred in the tile (not tiling at edges)."""
    cv = Canvas(h, w)
    cx, cy = w / 2, h / 2
    cv.ellipse(cx, cy, w * 0.16, h * 0.14)
    for _ in range(blobs):
        a = rng.random() * 2 * math.pi
        r = rng.random() ** 0.7 * w * spread
        s = rng.uniform(0.02, 0.07) * w
        cv.ellipse(cx + math.cos(a) * r, cy + math.sin(a) * r, s, s * rng.uniform(0.6, 1.2))
        # a thin trail toward the centre
        cv.line([(cx, cy), (cx + math.cos(a) * r, cy + math.sin(a) * r)], s * 0.6)
    for _ in range(drips):
        x = cx + rng.uniform(-0.18, 0.18) * w
        y0 = cy + rng.uniform(0, 0.1) * h
        L = rng.uniform(0.15, 0.4) * h
        wd = rng.uniform(0.012, 0.03) * w
        cv.line([(x, y0), (x + rng.normal(0, 1.5), y0 + L)], wd)
        cv.ellipse(x, y0 + L, wd * 1.2, wd * 1.4)
    for _ in range(40):
        a = rng.random() * 2 * math.pi
        r = rng.uniform(0.25, 0.46) * w
        s = rng.uniform(0.5, 2.2)
        cv.ellipse(cx + math.cos(a) * r, cy + math.sin(a) * r, s, s)
    m = cv.mask()
    m = np.clip(m * (0.85 + 0.3 * fbm(h, w, 8, rng, 3)), 0, 1)
    return m.astype(F)
