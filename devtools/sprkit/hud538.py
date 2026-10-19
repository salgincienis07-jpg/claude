"""Vexmira 5.3.8 HUD art kit: supersampled RGBA canvas + crisp shapes/text -> GoldSrc ALPHTEST / ADDITIVE sprites.

Design rules (owner: "smooth, not pixelated, calm colours, one theme"):
  * everything is drawn at SS x resolution and box-downsampled (true anti-aliasing inside the art)
  * ALPHTEST has no partial alpha, so panels are OPAQUE (dark slate) and every floating element gets a 1 px
    dark rim: the hard alpha edge then sits on a dark pixel and does not show as jaggies on bright scenes
  * no Bayer dithering (the old c533 cards dithered soft glows -> noisy "pixel" look)
  * palette: dark slate panels, light text, ONE accent colour per card family (muted, not neon)
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from sprlib import write_spr, quantize_alphatest  # noqa: E402

SS = 4
FONT_B = '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf'
FONT_R = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
FONT_N = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'

# theme ---------------------------------------------------------------------------------------------
PANEL_TOP = (30, 34, 42)
PANEL_BOT = (17, 19, 24)
PANEL_EDGE = (66, 74, 88)
RIM = (6, 7, 9)
TEXT = (238, 241, 245)
TEXT_SUB = (160, 168, 182)
ACC = {                       # muted accents (family colours)
    'human': (86, 168, 232), 'zombie': (118, 196, 92), 'boss': (222, 86, 72), 'gold': (226, 184, 92),
    'violet': (160, 128, 228), 'orange': (232, 146, 70), 'teal': (78, 196, 184), 'white': (220, 224, 230),
}


def _font(path, px):
    return ImageFont.truetype(path, max(1, int(round(px))))


class Canvas:
    """premultiplied-free src-over RGBA canvas at SS resolution (logical size w x h)."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.W, self.H = w * SS, h * SS
        self.rgb = np.zeros((self.H, self.W, 3))
        self.a = np.zeros((self.H, self.W))
        Y, X = np.mgrid[0:self.H, 0:self.W]
        self.X = (X + 0.5) / SS
        self.Y = (Y + 0.5) / SS

    # masks (float 0..1 at SS) -----------------------------------------------------------------------
    def _blank(self):
        return Image.new('L', (self.W, self.H), 0)

    @staticmethod
    def _arr(im):
        return np.asarray(im, float) / 255.0

    def rrect(self, x0, y0, x1, y1, r):
        im = self._blank()
        ImageDraw.Draw(im).rounded_rectangle([x0 * SS, y0 * SS, x1 * SS - 1, y1 * SS - 1], radius=r * SS, fill=255)
        return self._arr(im)

    def ellipse(self, cx, cy, rx, ry=None):
        ry = rx if ry is None else ry
        im = self._blank()
        ImageDraw.Draw(im).ellipse([(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS], fill=255)
        return self._arr(im)

    def ring(self, cx, cy, r, w):
        return np.clip(self.ellipse(cx, cy, r + w / 2) - self.ellipse(cx, cy, r - w / 2), 0, 1)

    def poly(self, pts):
        im = self._blank()
        ImageDraw.Draw(im).polygon([(x * SS, y * SS) for x, y in pts], fill=255)
        return self._arr(im)

    def line(self, pts, w):
        im = self._blank()
        d = ImageDraw.Draw(im)
        d.line([(x * SS, y * SS) for x, y in pts], fill=255, width=max(1, int(w * SS)), joint='curve')
        for x, y in (pts[0], pts[-1]):
            r = w * SS / 2
            d.ellipse([x * SS - r, y * SS - r, x * SS + r, y * SS + r], fill=255)
        return self._arr(im)

    def arc(self, cx, cy, r, w, a0, a1):
        """angles in degrees, 0 = up, clockwise."""
        im = self._blank()
        ImageDraw.Draw(im).arc([(cx - r) * SS, (cy - r) * SS, (cx + r) * SS, (cy + r) * SS],
                               a0 - 90, a1 - 90, fill=255, width=max(1, int(w * SS)))
        return self._arr(im)

    def text(self, s, path, px, cx, cy, maxw=None, anchor='mm', track=0.0):
        """text mask centred (anchor mm) or left (lm) / right (rm) at (cx, cy); shrinks to maxw."""
        while True:
            f = _font(path, px * SS)
            bb = f.getbbox(s)
            tw = (bb[2] - bb[0]) / SS + track * max(0, len(s) - 1)
            if maxw is None or tw <= maxw or px <= 6:
                break
            px -= 0.5
        im = self._blank()
        d = ImageDraw.Draw(im)
        if track:
            x = cx * SS
            if anchor[0] == 'm':
                x -= tw * SS / 2
            elif anchor[0] == 'r':
                x -= tw * SS
            for ch in s:
                d.text((x, cy * SS), ch, font=f, fill=255, anchor='l' + anchor[1])
                x += (f.getbbox(ch)[2] - f.getbbox(ch)[0]) + track * SS + (f.getlength(ch) - (f.getbbox(ch)[2] - f.getbbox(ch)[0]))
        else:
            d.text((cx * SS, cy * SS), s, font=f, fill=255, anchor=anchor)
        return self._arr(im)

    # effects ---------------------------------------------------------------------------------------
    @staticmethod
    def grow(m, px):
        im = Image.fromarray((np.clip(m, 0, 1) * 255).astype(np.uint8))
        k = int(px * SS) * 2 + 1
        return np.asarray(im.filter(ImageFilter.MaxFilter(k)), float) / 255.0

    @staticmethod
    def blur(m, px):
        im = Image.fromarray((np.clip(m, 0, 1) * 255).astype(np.uint8))
        return np.asarray(im.filter(ImageFilter.GaussianBlur(px * SS)), float) / 255.0

    def vgrad(self, c0, c1, y0, y1):
        t = np.clip((self.Y - y0) / max(1e-6, y1 - y0), 0, 1)[..., None]
        return np.array(c0, float) * (1 - t) + np.array(c1, float) * t

    def hgrad(self, c0, c1, x0, x1):
        t = np.clip((self.X - x0) / max(1e-6, x1 - x0), 0, 1)[..., None]
        return np.array(c0, float) * (1 - t) + np.array(c1, float) * t

    def paint(self, m, col, alpha=1.0):
        m = np.clip(m, 0, 1) * alpha
        col = np.broadcast_to(np.asarray(col, float), self.rgb.shape)
        self.rgb = self.rgb * (1 - m[..., None]) + col * m[..., None]
        self.a = self.a + m * (1 - self.a)

    # composite helpers -----------------------------------------------------------------------------
    def panel(self, x0, y0, x1, y1, r=6, accent=None, stripe='left'):
        m = self.rrect(x0, y0, x1, y1, r)
        if NO_PANEL:          # 5.3.8a: owner wants fully transparent cards (no grey box behind)
            return m
        self.paint(self.grow(m, 1), RIM)
        self.paint(m, self.vgrad(PANEL_TOP, PANEL_BOT, y0, y1))
        inner = self.rrect(x0 + 1, y0 + 1, x1 - 1, y1 - 1, max(1, r - 1))
        self.paint(np.clip(m - inner, 0, 1), PANEL_EDGE, 0.9)                       # 1 px edge
        hl = self.rrect(x0 + 1, y0 + 1, x1 - 1, y0 + 2.2, 1)
        self.paint(hl * inner, (255, 255, 255), 0.06)                                # faint top light
        if accent is not None:
            if stripe == 'left':
                s = self.rrect(x0 + 1, y0 + 4, x0 + 4, y1 - 4, 1.5)
            elif stripe == 'top':
                s = self.rrect(x0 + 10, y0 + 1, x1 - 10, y0 + 3, 1)
            else:
                s = self.rrect(x0 + 10, y1 - 3, x1 - 10, y1 - 1, 1)
            self.paint(s, accent)
        return m

    def label(self, mask, col, rim=True, shadow=True):
        if NO_PANEL:          # no box behind -> every text gets at least a dark drop shadow to stay readable
            shadow = True
        if shadow:
            self.paint(np.roll(np.roll(mask, int(0.8 * SS), 0), int(0.6 * SS), 1), (0, 0, 0), 0.55)
        if rim:
            self.paint(np.clip(self.grow(mask, 0.6) - mask, 0, 1), RIM, 0.9)
        self.paint(mask, col)

    def glow(self, mask, col, px=2.5, amt=0.35):
        self.paint(self.blur(mask, px) * 1.4, col, amt)

    def result(self):
        s = SS
        h, w = self.h, self.w
        a = self.a.reshape(h, s, w, s).mean((1, 3))
        pm = (self.rgb * self.a[..., None]).reshape(h, s, w, s, 3).mean((1, 3))
        rgb = np.where(a[..., None] > 1e-6, pm / np.maximum(a[..., None], 1e-6), 0)
        return np.clip(rgb, 0, 255), a


NO_PANEL = True


# sprite writers ------------------------------------------------------------------------------------
def to_alphatest(rgb, a, thr=0.5):
    return np.clip(rgb, 0, 255), a >= thr


def write_alphatest(path, frames, sprtype=2):
    """frames: list of (rgb, a) same size; one shared palette (index 255 transparent)."""
    rgbs, ops = [], []
    for rgb, a in frames:
        c, o = to_alphatest(rgb, a)
        rgbs.append(c)
        ops.append(o)
    idx, pal = quantize_alphatest(rgbs, ops)
    write_spr(path, idx, sprtype, pal, 3)
    return [np.where(o[..., None], np.array(pal, float)[i], 0) for i, o in zip(idx, ops)], ops


def write_additive(path, frames, sprtype=2):
    """frames: list of (rgb, a): additive colour = rgb * a (black = invisible)."""
    imgs = [np.clip(rgb * a[..., None], 0, 255) for rgb, a in frames]
    allpix = np.concatenate([i.reshape(-1, 3) for i in imgs]).round().astype(np.uint8)
    im = Image.fromarray(allpix.reshape(1, -1, 3))
    q = im.quantize(255, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    pal = np.array(q.getpalette()[:255 * 3], float).reshape(-1, 3)
    pal = np.concatenate([pal, np.zeros((256 - len(pal), 3))])
    from scipy.spatial import cKDTree
    tree = cKDTree(pal[:255])
    idx = []
    for i in imgs:
        _, lab = tree.query(i.reshape(-1, 3))
        idx.append(lab.reshape(i.shape[:2]).astype(np.uint8))
    write_spr(path, idx, sprtype, [tuple(int(v) for v in c) for c in pal], 1)
    return [pal[k] for k in idx]


def write_hud_txt(path, rel_sheet, x, y, w, h):
    """crosshair-trick HUD script: crosshair/zoom region = the card; weapon/ammo = 4x4 dummy."""
    lines = []
    for res in (320, 640):
        for k in ('crosshair', 'autoaim', 'zoom', 'zoom_autoaim'):
            lines.append('%s\t%d\t%s\t%d\t%d\t%d\t%d' % (k, res, rel_sheet, x, y, w, h))
        for k in ('weapon', 'weapon_s', 'ammo', 'ammo2'):
            lines.append('%s\t%d\t%s\t0\t0\t4\t4' % (k, res, rel_sheet))
    with open(path, 'w', newline='\r\n') as f:
        f.write('%d\n' % len(lines))
        for ln in lines:
            f.write(ln + '\n')
