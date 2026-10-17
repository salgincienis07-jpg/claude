"""Vexmira 5.3.2 big screen cards (round end / MVP / boss / last human), CSO "ZOMBIE WIN" style.

    cd devtools/sprkit && python3 make_cards532.py [--preview dir]

Each card is ONE 256x128 sprite + ONE .txt (crosshair trick, drawn centred on screen by the CS client,
ALPHTEST: index 255 = transparent). Only 2 download slots per card (the 5.3.1 animated set needed ~120,
which filled the 512 download list). Out: cstrike/sprites/vexmira/c532/<card>_<lang>.spr/.txt
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from sprlib import write_spr, read_spr, quantize_alphatest, VP_PARALLEL, TF_ALPHTEST  # noqa: E402

OUT = os.path.abspath(os.path.join(HERE, '..', '..', 'cstrike', 'sprites', 'vexmira', 'c532'))
REL = 'vexmira/c532'
W, H, SS = 256, 128, 4
FONT_B = '/usr/share/fonts/truetype/liberation/LiberationSans-BoldItalic.ttf'
FONT_S = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'

BAYER = np.array([[0, 32, 8, 40, 2, 34, 10, 42], [48, 16, 56, 24, 50, 18, 58, 26],
                  [12, 44, 4, 36, 14, 46, 6, 38], [60, 28, 52, 20, 62, 30, 54, 22],
                  [3, 35, 11, 43, 1, 33, 9, 41], [51, 19, 59, 27, 49, 17, 57, 25],
                  [15, 47, 7, 39, 13, 45, 5, 37], [63, 31, 55, 23, 61, 29, 53, 21]], float)
BAYER = (BAYER + 0.5) / 64.0

THEMES = {
    # fill gradient top -> bottom, outline, glow, accent
    'zwin': dict(grad=[(255, 255, 210), (190, 255, 70), (40, 150, 10)], ink=(14, 22, 6), glow=(120, 255, 40),
                 acc=(220, 30, 30)),
    'hwin': dict(grad=[(245, 252, 255), (120, 210, 255), (10, 110, 220)], ink=(4, 12, 30), glow=(40, 170, 255),
                 acc=(200, 240, 255)),
    'mvp': dict(grad=[(255, 255, 235), (255, 214, 90), (205, 120, 10)], ink=(30, 16, 2), glow=(255, 190, 40),
                acc=(255, 240, 170)),
    'boss': dict(grad=[(255, 236, 236), (255, 90, 70), (150, 0, 40)], ink=(28, 2, 8), glow=(255, 40, 60),
                 acc=(190, 80, 255)),
    'last': dict(grad=[(255, 252, 240), (255, 200, 120), (225, 90, 20)], ink=(28, 10, 2), glow=(255, 140, 40),
                 acc=(255, 230, 200)),
}
TEXT = {
    'zwin': {'en': ('ZOMBIES', 'WIN'), 'tr': ('ZOMBİLER', 'KAZANDI')},
    'hwin': {'en': ('HUMANS', 'WIN'), 'tr': ('İNSANLAR', 'KAZANDI')},
    'mvp': {'en': ('MVP', 'ROUND STAR'), 'tr': ('MVP', 'TURUN YILDIZI')},
    'boss': {'en': ('BOSS', 'IS COMING'), 'tr': ('BOSS', 'GELİYOR')},
    'last': {'en': ('LAST HUMAN', 'SURVIVE!'), 'tr': ('SON İNSAN', 'HAYATTA KAL!')},
}


def text_mask(text, font_path, size, cx, cy, maxw):
    """supersampled mask of text centred at (cx, cy) final px; shrinks to fit maxw."""
    while True:
        f = ImageFont.truetype(font_path, int(size * SS))
        l, t, r, b = f.getbbox(text)
        if (r - l) / SS <= maxw or size < 8:
            break
        size -= 1
    im = Image.new('L', (W * SS, H * SS), 0)
    d = ImageDraw.Draw(im)
    d.text((cx * SS - (l + r) / 2, cy * SS - (t + b) / 2), text, font=f, fill=255)
    return np.asarray(im, float) / 255.0


def vgrad(mask, stops):
    ys = np.where(mask.max(1) > 0.5)[0]
    y0, y1 = (ys.min(), ys.max()) if len(ys) else (0, mask.shape[0] - 1)
    t = np.clip((np.arange(mask.shape[0]) - y0) / max(1, y1 - y0), 0, 1)[:, None]
    c = np.array(stops, float)
    col = np.where(t[..., None] < 0.5, c[0] + (c[1] - c[0]) * (t[..., None] / 0.5),
                   c[1] + (c[2] - c[1]) * ((t[..., None] - 0.5) / 0.5))
    return np.broadcast_to(col, mask.shape + (3,))


class Cv:
    def __init__(self):
        self.rgb = np.zeros((H * SS, W * SS, 3))
        self.a = np.zeros((H * SS, W * SS))
        yy, xx = np.mgrid[0:H * SS, 0:W * SS]
        self.X, self.Y = (xx + 0.5) / SS, (yy + 0.5) / SS

    def paint(self, m, col, alpha=1.0):
        m = np.clip(m * alpha, 0, 1)
        col = np.asarray(col, float)
        if col.ndim == 1:
            col = col[None, None, :]
        self.rgb = self.rgb * (1 - m[..., None]) + col * m[..., None]
        self.a = self.a + m * (1 - self.a)

    def line(self, pts, width):
        im = Image.new('L', (W * SS, H * SS), 0)
        d = ImageDraw.Draw(im)
        d.line([(x * SS, y * SS) for x, y in pts], fill=255, width=max(1, int(width * SS)), joint='curve')
        return np.asarray(im, float) / 255.0

    def poly(self, pts):
        im = Image.new('L', (W * SS, H * SS), 0)
        ImageDraw.Draw(im).polygon([(x * SS, y * SS) for x, y in pts], fill=255)
        return np.asarray(im, float) / 255.0


def grow(m, px):
    return np.clip(ndimage.maximum_filter(m, size=int(px * SS * 2) | 1), 0, 1)


def blur(m, px):
    return ndimage.gaussian_filter(m, px * SS)


def bold_text(cv, mask, th, outline=2.2, glow=3.5, glow_a=0.42):
    cv.paint(np.clip(blur(grow(mask, 1.5), glow) * 1.5, 0, 1) ** 1.5, th["glow"], glow_a)       # soft aura
    cv.paint(grow(mask, outline), th['ink'])                                            # thick outline
    fill = vgrad(mask, th['grad'])
    cv.paint(mask, fill)
    # bevel: light from top-left
    sh = np.roll(np.roll(mask, int(1.2 * SS), 0), int(0.6 * SS), 1)
    hi = np.clip(mask - sh, 0, 1)
    cv.paint(hi, (255, 255, 255), 0.85)
    lo = np.clip(mask - np.roll(np.roll(mask, -int(1.2 * SS), 0), -int(0.6 * SS), 1), 0, 1)
    cv.paint(lo, th['ink'], 0.45)


def decorate(cv, card, th, rng):
    X, Y = cv.X, cv.Y
    if card == 'zwin':
        for k, x in enumerate((70, 112, 154)):                    # claw slashes behind the text
            m = cv.poly([(x - 4, 8), (x + 2, 8), (x + 34, 100), (x + 30, 104)])
            cv.paint(blur(m, 0.6), th['acc'], 0.9)
            cv.paint(blur(cv.poly([(x - 1, 10), (x + 1, 10), (x + 31, 98), (x + 30, 99)]), 0.4), (255, 170, 160), 0.8)
    elif card == 'hwin':
        for s in (-1, 1):                                       # chevrons + light rails
            cx = 128 + s * 112
            for j in range(3):
                o = s * j * 7
                cv.paint(cv.line([(cx + o - s * 6, 48), (cx + o, 58), (cx + o - s * 6, 68)], 2.6), th['glow'], 0.9 - j * 0.25)
            cv.paint(cv.line([(128 + s * 20, 104), (128 + s * 120, 104)], 1.2), th['acc'], 0.8)
    elif card == 'mvp':
        cx, cy, r = 128, 20, 13                                 # star
        pts = []
        for i in range(10):
            a = -np.pi / 2 + i * np.pi / 5
            rr = r if i % 2 == 0 else r * 0.45
            pts.append((cx + rr * np.cos(a), cy + rr * np.sin(a)))
        st = cv.poly(pts)
        cv.paint(blur(grow(st, 1.5), 4), th['glow'], 0.6)
        cv.paint(grow(st, 1.2), th['ink'])
        cv.paint(st, vgrad(st, th['grad']))
        for s in (-1, 1):                                       # laurel arcs
            for i in range(6):
                a = np.pi / 2 + s * (0.5 + i * 0.2)
                x, y = 128 + 70 * np.cos(a) * -1, 72 + 40 * np.sin(a)
                x = 128 + s * (60 + i * 7)
                y = 98 - i * 9 + (i * i) * 0.6
                leaf = ((X - x) / 5.5) ** 2 + ((Y - y) / 2.6) ** 2 < 1
                cv.paint(leaf.astype(float), (255, 205, 80), 0.95)
    elif card == 'boss':
        for s in (-1, 1):                                       # horns
            h = cv.poly([(128 + s * 40, 30), (128 + s * 62, 4), (128 + s * 54, 28), (128 + s * 48, 40)])
            cv.paint(grow(h, 1.2), th['ink'])
            cv.paint(h, vgrad(h, [(255, 240, 220), (220, 200, 170), (120, 90, 70)]))
        fl = np.zeros_like(X)
        for i in range(14):                                     # flame tongues at the bottom
            x = 40 + i * 13 + rng.uniform(-3, 3)
            hgt = rng.uniform(14, 26)
            fl = np.maximum(fl, np.clip(1 - (np.abs(X - x) / (5 * (1 - np.clip((118 - Y) / hgt, 0, 1)) + 0.01)), 0, 1)
                            * (Y < 120) * (Y > 118 - hgt))
        cv.paint(blur(fl, 0.8), th['acc'], 0.85)
    elif card == 'last':
        cx, cy = 128, 62                                        # crosshair ring behind
        r = np.hypot(X - cx, Y - cy)
        ring = np.clip(1 - np.abs(r - 50) / 1.6, 0, 1)
        cv.paint(ring, th['glow'], 0.8)
        for a in range(4):
            ang = a * np.pi / 2
            cv.paint(cv.line([(cx + 44 * np.cos(ang), cy + 44 * np.sin(ang)), (cx + 60 * np.cos(ang), cy + 60 * np.sin(ang))], 2.4),
                     th['glow'], 0.9)
    # a horizontal light streak through the middle (all cards)
    streak = np.exp(-((Y - 62) / 0.9) ** 2) * np.exp(-((X - 128) / 90) ** 2)
    cv.paint(streak, (255, 255, 255), 0.55)


def render(card, lang):
    th = THEMES[card]
    big, sub = TEXT[card][lang]
    rng = np.random.default_rng(hash(card) & 0xffff)
    cv = Cv()
    decorate(cv, card, th, rng)
    mb = text_mask(big, FONT_B, 46 if len(big) <= 9 else 40, 128, 58 if card != 'mvp' else 60, 238)
    bold_text(cv, mb, th)
    ms = text_mask(sub, FONT_S, 17, 128, 96, 220)
    bold_text(cv, ms, dict(th, grad=[(255, 255, 255), (235, 235, 235), (190, 190, 190)]), outline=1.6, glow=3, glow_a=0.35)
    if card == 'zwin':                                          # toxic drips from the big word
        cols = np.where(mb.max(0) > 0.5)[0] / SS
        for x in rng.choice(cols, 7, replace=False):
            y0 = 70
            ln = rng.uniform(8, 18)
            drip = np.clip(1 - np.hypot((cv.X - x) / 1.6, np.clip(cv.Y - y0, 0, ln) - (cv.Y - y0)) , 0, 1) * (cv.Y > y0 - 2) * (cv.Y < y0 + ln + 2)
            drip = np.maximum(drip, ((cv.X - x) / 2.2) ** 2 + ((cv.Y - y0 - ln) / 2.2) ** 2 < 1)
            cv.paint(grow(drip.astype(float), 0.8), th['ink'])
            cv.paint(drip.astype(float), (130, 230, 40))
    # down-sample + dither (ALPHTEST: soft parts become dotted light)
    s = SS
    rgb = cv.rgb.reshape(H, s, W, s, 3).mean((1, 3))
    a = cv.a.reshape(H, s, W, s).mean((1, 3))
    thr = np.tile(BAYER, (H // 8, W // 8))
    o = a > thr
    col = np.where(a[..., None] > 1e-6, rgb / np.maximum(a[..., None], 1e-6), 0)
    o[0:2, :] = o[-2:, :] = False
    o[:, 0:2] = o[:, -2:] = False
    idx, pal = quantize_alphatest([np.clip(col, 0, 255)], [o])
    name = '%s_%s' % (card, lang)
    write_spr(os.path.join(OUT, name + '.spr'), idx, VP_PARALLEL, pal, TF_ALPHTEST)
    lines = []
    for res in (320, 640):
        for k in ('crosshair', 'autoaim', 'zoom', 'zoom_autoaim'):
            lines.append('%s\t%d\t%s/%s\t0\t0\t%d\t%d' % (k, res, REL, name, W, H))
        for k in ('weapon', 'weapon_s', 'ammo', 'ammo2'):
            lines.append('%s\t%d\t%s/%s\t0\t0\t4\t4' % (k, res, REL, name))
    with open(os.path.join(OUT, name + '.txt'), 'w', newline='\r\n') as f:
        f.write('%d\n' % len(lines))
        for ln in lines:
            f.write(ln + '\n')
    return idx[0], pal, o


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--preview')
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    tiles = []
    for card in TEXT:
        for lang in ('tr', 'en'):
            idx, pal, o = render(card, lang)
            p = np.array(pal, float)[idx]
            bg = np.zeros((H, W, 3)) + 70
            yy, xx = np.mgrid[0:H, 0:W]
            bg[((yy // 16 + xx // 16) % 2) == 0] = 95
            tiles.append(np.where(o[..., None], p, bg).astype(np.uint8))
            print(card, lang, read_spr(os.path.join(OUT, '%s_%s.spr' % (card, lang)))['size'])
    if a.preview:
        rows = [np.concatenate(tiles[i:i + 2], 1) for i in range(0, len(tiles), 2)]
        Image.fromarray(np.concatenate(rows, 0)).resize((W * 4, H * len(rows) * 2), Image.NEAREST).save(a.preview)


if __name__ == '__main__':
    main()
