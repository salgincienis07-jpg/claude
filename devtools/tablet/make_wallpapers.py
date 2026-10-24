#!/usr/bin/env python3
"""VEXMIRA iPad wallpapers (iPadOS-style soft light + flowing shapes, dark zombie palettes).

Writes cstrike/vexmira_pad4/wp4_<n>.jpg (1600x1000). Order matches the tablet's wallpaper list:
0 Kizil Sis, 1 Ucurum, 2 Zehir, 3 Altigen, 4 Kor, 5 Mor Safak, 6 Gece Mavisi, 7 Vexmira.
"""
import os, math
import numpy as np
from PIL import Image, ImageFilter, ImageDraw, ImageFont

W, H = 1600, 1000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'cstrike', 'vexmira_pad4')
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
u, v = xx / W, yy / H
rng = np.random.default_rng(7)


def blob(cx, cy, rx, ry, col, a=1.0):
    d = ((u - cx) / rx) ** 2 + ((v - cy) / ry) ** 2
    m = np.exp(-d * 1.6) * a
    return m[..., None] * np.array(col, np.float32)[None, None, :] / 255.0


def wave(base, amp, freq, phase, thick, col, a=1.0, soft=0.05):
    """iPadOS-like flowing ribbon: band around a sine curve, lit edge on top."""
    y0 = base + amp * np.sin(u * freq * 2 * math.pi + phase) + amp * 0.35 * np.sin(u * freq * 5.1 + phase * 1.7)
    dist = v - y0
    band = 1.0 / (1.0 + np.exp(-dist / soft)) * (1.0 / (1.0 + np.exp((dist - thick) / (soft * 2))))
    edge = np.exp(-(dist / 0.006) ** 2) * 0.55
    m = (band * 0.75 + edge) * a
    return m[..., None] * np.array(col, np.float32)[None, None, :] / 255.0


def finish(img, vign=0.55, grain=0.018):
    d = np.sqrt((u - 0.5) ** 2 * 1.2 + (v - 0.48) ** 2 * 1.6)
    img = img * (1 - vign * np.clip(d - 0.15, 0, 1)[..., None] ** 1.3)
    img = img + rng.normal(0, grain, img.shape).astype(np.float32)
    return np.clip(img, 0, 1)


def save(img, n):
    im = Image.fromarray((img * 255).astype(np.uint8), 'RGB').filter(ImageFilter.GaussianBlur(0.6))
    p = os.path.join(OUT, 'wp4_%d.jpg' % n)
    im.save(p, quality=84, optimize=True, progressive=False)
    print(p, os.path.getsize(p) // 1024, 'KB')
    return im


def base(c1, c2):
    t = np.clip(v * 0.8 + u * 0.2, 0, 1)[..., None]
    return np.array(c1, np.float32) / 255 * (1 - t) + np.array(c2, np.float32) / 255 * t


def make():
    os.makedirs(OUT, exist_ok=True)
    # 0 Kizil Sis - crimson fog
    img = base((26, 4, 10), (6, 2, 4)) + blob(.18, .1, .55, .45, (230, 30, 60), .75) + blob(.85, .9, .5, .4, (120, 0, 30), .6)
    img += wave(.58, .07, .7, 0.5, .25, (200, 20, 50), .55) + wave(.7, .05, .9, 2.0, .3, (90, 6, 24), .7)
    save(finish(img), 0)
    # 1 Ucurum - teal abyss
    img = base((2, 10, 16), (1, 3, 6)) + blob(.5, 1.05, .6, .45, (0, 170, 190), .55) + blob(.1, .2, .35, .3, (0, 80, 120), .4)
    img += wave(.62, .06, .6, 1.2, .3, (0, 140, 160), .45) + wave(.75, .04, .8, 3.0, .3, (0, 60, 90), .6)
    save(finish(img), 1)
    # 2 Zehir - toxic green
    img = base((6, 16, 4), (1, 4, 1)) + blob(.72, .15, .5, .4, (110, 230, 40), .6) + blob(.15, .85, .45, .35, (30, 110, 10), .5)
    img += wave(.55, .08, .65, 4.0, .28, (90, 200, 30), .4) + wave(.72, .05, .9, 1.0, .3, (20, 80, 10), .6)
    save(finish(img), 2)
    # 3 Altigen - red hex grid over dark
    img = base((14, 3, 7), (3, 1, 2)) + blob(.5, .45, .7, .6, (170, 12, 40), .45)
    im = Image.fromarray((finish(img, grain=.012) * 255).astype(np.uint8), 'RGB')
    dr = ImageDraw.Draw(im, 'RGBA'); r = 46
    for j in range(-1, H // int(r * 1.5) + 2):
        for i in range(-1, int(W / (r * 1.732)) + 2):
            cx = i * r * 1.732 + (j % 2) * r * 0.866; cy = j * r * 1.5
            pts = [(cx + r * math.cos(math.radians(60 * k + 30)), cy + r * math.sin(math.radians(60 * k + 30))) for k in range(6)]
            d = math.hypot(cx / W - .5, cy / H - .45)
            dr.polygon(pts, outline=(255, 40, 70, int(max(10, 70 - d * 110))))
    img = np.asarray(im).astype(np.float32) / 255 + blob(.5, .45, .3, .25, (255, 40, 70), .12)
    save(np.clip(img, 0, 1), 3)
    # 4 Kor - embers
    img = base((10, 4, 3), (30, 8, 4)) + blob(.5, 1.1, .7, .5, (255, 100, 20), .75) + blob(.85, .2, .35, .3, (120, 20, 0), .4)
    img += wave(.66, .05, .7, 2.2, .3, (255, 120, 30), .35)
    for _ in range(220):
        x, y = rng.random(), .45 + rng.random() * .55
        img += blob(x, y, .004, .006, (255, 160, 60), rng.random() * .9)
    save(finish(img), 4)
    # 5 Mor Safak - purple dawn
    img = base((14, 6, 26), (4, 2, 10)) + blob(.15, .2, .5, .45, (150, 70, 255), .6) + blob(.9, .85, .45, .4, (230, 50, 140), .45)
    img += wave(.6, .07, .55, 0.0, .3, (140, 70, 240), .45) + wave(.74, .05, .85, 2.5, .3, (200, 40, 120), .4)
    save(finish(img), 5)
    # 6 Gece Mavisi - midnight blue
    img = base((6, 12, 28), (2, 3, 9)) + blob(.5, -.05, .7, .45, (60, 110, 230), .5) + blob(.2, .9, .4, .3, (20, 40, 110), .5)
    img += wave(.6, .06, .6, 3.3, .3, (60, 120, 255), .35) + wave(.76, .04, .9, .7, .3, (30, 60, 150), .5)
    for _ in range(160):
        img += blob(rng.random(), rng.random() * .5, .0015, .0024, (220, 230, 255), rng.random() * .8)
    save(finish(img), 6)
    # 7 Vexmira - premium dark red with soft V light
    img = base((20, 4, 9), (4, 1, 3)) + blob(.5, .42, .55, .5, (200, 14, 44), .55) + blob(.5, 1.0, .9, .3, (90, 0, 20), .5)
    img += wave(.68, .045, .6, 1.6, .32, (220, 30, 60), .35)
    img = finish(img)
    vm = np.zeros((H, W), np.float32)
    im = Image.fromarray((vm * 255).astype(np.uint8), 'L'); dr = ImageDraw.Draw(im)
    cx, cy, s = W / 2, H * .42, 210
    dr.polygon([(cx - s, cy - s * .8), (cx - s * .55, cy - s * .8), (cx, cy + s * .55), (cx + s * .55, cy - s * .8), (cx + s, cy - s * .8), (cx, cy + s)], fill=255)
    m = np.asarray(im.filter(ImageFilter.GaussianBlur(3))).astype(np.float32) / 255
    glow = np.asarray(im.filter(ImageFilter.GaussianBlur(40))).astype(np.float32) / 255
    img = img + glow[..., None] * np.array([.55, .05, .12], np.float32) * .8
    img = img * (1 - m[..., None] * .55) + m[..., None] * (np.array([.20, .02, .05], np.float32) + .35 * (1 - v[..., None]) * np.array([.9, .2, .3], np.float32))
    save(np.clip(img, 0, 1), 7)


if __name__ == '__main__':
    make()
