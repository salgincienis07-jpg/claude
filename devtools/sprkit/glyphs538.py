"""Vector glyphs for the 5.3.8 HUD set. Every function: (canvas, cx, cy, s) -> float mask at SS (s ~ radius px)."""
import math

import numpy as np


def _rot(pts, cx, cy, ang):
    c, s = math.cos(ang), math.sin(ang)
    return [(cx + (x - cx) * c - (y - cy) * s, cy + (x - cx) * s + (y - cy) * c) for x, y in pts]


def skull(cv, cx, cy, s):
    head = cv.ellipse(cx, cy - 0.12 * s, 0.82 * s, 0.74 * s)
    jaw = cv.rrect(cx - 0.48 * s, cy + 0.25 * s, cx + 0.48 * s, cy + 0.86 * s, 0.18 * s)
    eyes = cv.ellipse(cx - 0.32 * s, cy - 0.05 * s, 0.22 * s, 0.25 * s) + cv.ellipse(cx + 0.32 * s, cy - 0.05 * s, 0.22 * s, 0.25 * s)
    nose = cv.poly([(cx, cy + 0.2 * s), (cx - 0.1 * s, cy + 0.38 * s), (cx + 0.1 * s, cy + 0.38 * s)])
    teeth = sum(cv.rrect(cx + k * 0.2 * s - 0.035 * s, cy + 0.58 * s, cx + k * 0.2 * s + 0.035 * s, cy + 0.9 * s, 0.01)
                for k in (-1, 0, 1))
    return np.clip(np.clip(head + jaw, 0, 1) - eyes - nose - teeth, 0, 1)


def trophy(cv, cx, cy, s):
    cup = cv.poly([(cx - 0.62 * s, cy - 0.72 * s), (cx + 0.62 * s, cy - 0.72 * s), (cx + 0.5 * s, cy - 0.05 * s),
                   (cx + 0.18 * s, cy + 0.25 * s), (cx - 0.18 * s, cy + 0.25 * s), (cx - 0.5 * s, cy - 0.05 * s)])
    cup = np.clip(cup + cv.ellipse(cx, cy - 0.2 * s, 0.52 * s, 0.42 * s), 0, 1)
    handles = cv.ring(cx - 0.62 * s, cy - 0.38 * s, 0.24 * s, 0.11 * s) + cv.ring(cx + 0.62 * s, cy - 0.38 * s, 0.24 * s, 0.11 * s)
    stem = cv.rrect(cx - 0.08 * s, cy + 0.2 * s, cx + 0.08 * s, cy + 0.6 * s, 0.02 * s)
    base = cv.rrect(cx - 0.42 * s, cy + 0.58 * s, cx + 0.42 * s, cy + 0.82 * s, 0.06 * s)
    return np.clip(cup + handles + stem + base, 0, 1)


def shield(cv, cx, cy, s):
    pts = [(cx - 0.72 * s, cy - 0.7 * s), (cx + 0.72 * s, cy - 0.7 * s), (cx + 0.7 * s, cy + 0.05 * s),
           (cx + 0.38 * s, cy + 0.55 * s), (cx, cy + 0.86 * s), (cx - 0.38 * s, cy + 0.55 * s), (cx - 0.7 * s, cy + 0.05 * s)]
    outer = cv.poly(pts)
    gap = cv.poly([(cx + (x - cx) * 0.74, cy - 0.04 * s + (y - cy) * 0.74) for x, y in pts])
    core = cv.poly([(cx + (x - cx) * 0.56, cy - 0.06 * s + (y - cy) * 0.56) for x, y in pts])
    return np.clip(outer - gap + core, 0, 1)


def biohazard(cv, cx, cy, s):
    m = np.zeros_like(cv.a)
    for k in range(3):
        a = math.radians(-90 + k * 120)
        x, y = cx + math.cos(a) * 0.42 * s, cy + math.sin(a) * 0.42 * s
        m = m + cv.ellipse(x, y, 0.42 * s)
        x2, y2 = cx + math.cos(a) * 0.56 * s, cy + math.sin(a) * 0.56 * s
        m = m - cv.ellipse(x2, y2, 0.3 * s)
    m = np.clip(m, 0, 1)
    m = np.clip(m - cv.ellipse(cx, cy, 0.22 * s), 0, 1)
    m = np.clip(m + cv.ring(cx, cy, 0.36 * s, 0.1 * s) * 0.0 + cv.ellipse(cx, cy, 0.12 * s), 0, 1)
    return m


def star(cv, cx, cy, s, n=5, inner=0.45):
    pts = []
    for k in range(n * 2):
        r = s if k % 2 == 0 else s * inner
        a = math.radians(-90 + k * 180 / n)
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return cv.poly(pts)


def crosshair(cv, cx, cy, s):
    m = cv.ring(cx, cy, 0.62 * s, 0.13 * s)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        m = m + cv.line([(cx + dx * 0.32 * s, cy + dy * 0.32 * s), (cx + dx * 0.98 * s, cy + dy * 0.98 * s)], 0.13 * s)
    m = m + cv.ellipse(cx, cy, 0.1 * s)
    return np.clip(m, 0, 1)


def knife(cv, cx, cy, s):
    blade = cv.poly([(cx - 0.9 * s, cy + 0.15 * s), (cx + 0.55 * s, cy - 0.32 * s), (cx + 0.95 * s, cy - 0.38 * s),
                     (cx + 0.62 * s, cy - 0.05 * s), (cx - 0.82 * s, cy + 0.38 * s)])
    guard = cv.line([(cx - 0.42 * s, cy - 0.15 * s), (cx - 0.25 * s, cy + 0.42 * s)], 0.13 * s)
    grip = cv.line([(cx - 0.62 * s, cy + 0.3 * s), (cx - 0.98 * s, cy + 0.48 * s)], 0.2 * s)
    return np.clip(_rotm(cv, blade, cx, cy) + guard + grip, 0, 1)


def _rotm(cv, m, cx, cy):
    return m


def grenade(cv, cx, cy, s):
    body = cv.ellipse(cx, cy + 0.18 * s, 0.58 * s, 0.66 * s)
    top = cv.rrect(cx - 0.22 * s, cy - 0.66 * s, cx + 0.22 * s, cy - 0.38 * s, 0.05 * s)
    lever = cv.line([(cx + 0.1 * s, cy - 0.62 * s), (cx + 0.55 * s, cy - 0.5 * s), (cx + 0.62 * s, cy - 0.05 * s)], 0.1 * s)
    ring = cv.ring(cx - 0.35 * s, cy - 0.66 * s, 0.16 * s, 0.07 * s)
    bands = cv.rrect(cx - 0.6 * s, cy + 0.12 * s, cx + 0.6 * s, cy + 0.2 * s, 0.01)
    return np.clip(body + top + lever + ring - bands, 0, 1)


def clock(cv, cx, cy, s):
    m = cv.ring(cx, cy, 0.78 * s, 0.14 * s)
    m = m + cv.line([(cx, cy), (cx, cy - 0.48 * s)], 0.12 * s) + cv.line([(cx, cy), (cx + 0.36 * s, cy + 0.1 * s)], 0.12 * s)
    return np.clip(m, 0, 1)


def chevrons(cv, cx, cy, s):
    m = np.zeros_like(cv.a)
    for k in range(2):
        y = cy + 0.25 * s - k * 0.55 * s
        m = m + cv.line([(cx - 0.62 * s, y + 0.28 * s), (cx, y - 0.25 * s), (cx + 0.62 * s, y + 0.28 * s)], 0.2 * s)
    return np.clip(m, 0, 1)


def crate(cv, cx, cy, s):
    m = cv.rrect(cx - 0.72 * s, cy - 0.62 * s, cx + 0.72 * s, cy + 0.72 * s, 0.1 * s)
    inner = cv.rrect(cx - 0.52 * s, cy - 0.42 * s, cx + 0.52 * s, cy + 0.52 * s, 0.05 * s)
    cross = cv.line([(cx - 0.5 * s, cy - 0.4 * s), (cx + 0.5 * s, cy + 0.5 * s)], 0.14 * s)
    return np.clip(m - inner + cross, 0, 1)


def crown(cv, cx, cy, s):
    m = cv.poly([(cx - 0.82 * s, cy + 0.5 * s), (cx - 0.82 * s, cy - 0.45 * s), (cx - 0.42 * s, cy - 0.02 * s),
                 (cx, cy - 0.72 * s), (cx + 0.42 * s, cy - 0.02 * s), (cx + 0.82 * s, cy - 0.45 * s), (cx + 0.82 * s, cy + 0.5 * s)])
    band = cv.rrect(cx - 0.82 * s, cy + 0.32 * s, cx + 0.82 * s, cy + 0.42 * s, 0.01)
    gems = cv.ellipse(cx, cy + 0.1 * s, 0.1 * s)
    return np.clip(m - band - gems, 0, 1)


def person(cv, cx, cy, s):
    head = cv.ellipse(cx, cy - 0.45 * s, 0.3 * s)
    body = cv.poly([(cx - 0.62 * s, cy + 0.82 * s), (cx - 0.5 * s, cy + 0.08 * s), (cx - 0.25 * s, cy - 0.08 * s),
                    (cx + 0.25 * s, cy - 0.08 * s), (cx + 0.5 * s, cy + 0.08 * s), (cx + 0.62 * s, cy + 0.82 * s)])
    return np.clip(head + body, 0, 1)


def heart(cv, cx, cy, s):
    m = cv.ellipse(cx - 0.34 * s, cy - 0.22 * s, 0.4 * s) + cv.ellipse(cx + 0.34 * s, cy - 0.22 * s, 0.4 * s)
    m = m + cv.poly([(cx - 0.72 * s, cy - 0.06 * s), (cx + 0.72 * s, cy - 0.06 * s), (cx, cy + 0.8 * s)])
    return np.clip(m, 0, 1)


def plus(cv, cx, cy, s):
    return np.clip(cv.rrect(cx - 0.22 * s, cy - 0.75 * s, cx + 0.22 * s, cy + 0.75 * s, 0.06 * s) +
                   cv.rrect(cx - 0.75 * s, cy - 0.22 * s, cx + 0.75 * s, cy + 0.22 * s, 0.06 * s), 0, 1)


def dagger(cv, cx, cy, s):
    blade = cv.poly([(cx, cy - 0.95 * s), (cx + 0.16 * s, cy - 0.15 * s), (cx + 0.12 * s, cy + 0.25 * s),
                     (cx - 0.12 * s, cy + 0.25 * s), (cx - 0.16 * s, cy - 0.15 * s)])
    guard = cv.rrect(cx - 0.5 * s, cy + 0.22 * s, cx + 0.5 * s, cy + 0.36 * s, 0.05 * s)
    grip = cv.rrect(cx - 0.09 * s, cy + 0.34 * s, cx + 0.09 * s, cy + 0.78 * s, 0.03 * s)
    pom = cv.ellipse(cx, cy + 0.86 * s, 0.13 * s)
    return np.clip(blade + guard + grip + pom, 0, 1)


def horns_skull(cv, cx, cy, s):
    m = skull(cv, cx, cy + 0.12 * s, 0.82 * s)
    for d in (-1, 1):
        m = m + cv.poly([(cx + d * 0.38 * s, cy - 0.38 * s), (cx + d * 0.95 * s, cy - 0.95 * s), (cx + d * 0.66 * s, cy - 0.25 * s)])
    return np.clip(m, 0, 1)


def bolt(cv, cx, cy, s):
    return cv.poly([(cx + 0.18 * s, cy - 0.95 * s), (cx - 0.5 * s, cy + 0.1 * s), (cx - 0.02 * s, cy + 0.1 * s),
                    (cx - 0.2 * s, cy + 0.95 * s), (cx + 0.5 * s, cy - 0.14 * s), (cx + 0.02 * s, cy - 0.14 * s)])


def flame(cv, cx, cy, s):
    outer = cv.poly([(cx, cy - 0.95 * s), (cx + 0.32 * s, cy - 0.42 * s), (cx + 0.52 * s, cy - 0.62 * s), (cx + 0.66 * s, cy + 0.2 * s),
                     (cx + 0.42 * s, cy + 0.72 * s), (cx, cy + 0.86 * s), (cx - 0.42 * s, cy + 0.72 * s), (cx - 0.66 * s, cy + 0.2 * s),
                     (cx - 0.4 * s, cy - 0.3 * s)])
    outer = np.clip(outer + cv.ellipse(cx, cy + 0.32 * s, 0.62 * s, 0.52 * s), 0, 1)
    inner = cv.poly([(cx, cy - 0.15 * s), (cx + 0.28 * s, cy + 0.35 * s), (cx, cy + 0.68 * s), (cx - 0.28 * s, cy + 0.35 * s)])
    return np.clip(outer - inner, 0, 1)


def snowflake(cv, cx, cy, s):
    m = np.zeros_like(cv.a)
    for k in range(6):
        a = math.radians(k * 60)
        ex, ey = cx + math.cos(a) * 0.9 * s, cy + math.sin(a) * 0.9 * s
        m = m + cv.line([(cx, cy), (ex, ey)], 0.13 * s)
        mx, my = cx + math.cos(a) * 0.55 * s, cy + math.sin(a) * 0.55 * s
        for d in (-1, 1):
            b = a + d * math.radians(45)
            m = m + cv.line([(mx, my), (mx + math.cos(b) * 0.28 * s, my + math.sin(b) * 0.28 * s)], 0.1 * s)
    return np.clip(m, 0, 1)


def scythe(cv, cx, cy, s):
    """reaper: hooded skull"""
    hood = cv.poly([(cx - 0.85 * s, cy + 0.95 * s), (cx - 0.78 * s, cy - 0.25 * s), (cx - 0.35 * s, cy - 0.85 * s),
                    (cx + 0.2 * s, cy - 0.98 * s), (cx + 0.7 * s, cy - 0.55 * s), (cx + 0.85 * s, cy + 0.95 * s)])
    face = cv.ellipse(cx, cy + 0.05 * s, 0.5 * s, 0.6 * s)
    sk = skull(cv, cx, cy + 0.1 * s, 0.5 * s)
    return np.clip(hood - face + sk, 0, 1)


def eye(cv, cx, cy, s):
    outer = np.clip(cv.ellipse(cx, cy, 0.95 * s, 0.55 * s), 0, 1)
    iris = cv.ellipse(cx, cy, 0.36 * s)
    pupil = cv.ellipse(cx, cy, 0.14 * s, 0.3 * s)
    return np.clip(outer - iris + pupil, 0, 1)


def fist(cv, cx, cy, s):
    m = cv.rrect(cx - 0.62 * s, cy - 0.45 * s, cx + 0.62 * s, cy + 0.55 * s, 0.22 * s)
    for k in range(3):
        x = cx - 0.42 * s + k * 0.42 * s
        m = m - cv.line([(x + 0.21 * s, cy - 0.45 * s), (x + 0.21 * s, cy - 0.08 * s)], 0.06 * s)
    m = m + cv.rrect(cx - 0.4 * s, cy + 0.5 * s, cx + 0.4 * s, cy + 0.9 * s, 0.08 * s)
    return np.clip(m, 0, 1)


def swirl(cv, cx, cy, s):
    pts = []
    for k in range(60):
        t = k / 59
        a = t * 4.2 * math.pi
        r = (0.1 + 0.85 * t) * s
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return cv.line(pts, 0.16 * s)


def hexbee(cv, cx, cy, s):
    m = np.zeros_like(cv.a)
    for (dx, dy) in ((0, 0), (0.62, 0.36), (-0.62, 0.36), (0, -0.72)):
        pts = [(cx + dx * s + math.cos(math.radians(30 + 60 * k)) * 0.36 * s, cy + dy * s + math.sin(math.radians(30 + 60 * k)) * 0.36 * s)
               for k in range(6)]
        m = m + cv.poly(pts)
    return np.clip(m, 0, 1)


def waves(cv, cx, cy, s):
    m = cv.ellipse(cx - 0.55 * s, cy, 0.2 * s)
    for k in range(3):
        r = (0.38 + k * 0.28) * s
        m = m + cv.arc(cx - 0.55 * s, cy, r, 0.12 * s, 45, 135)
    return np.clip(m, 0, 1)


def vex(cv, cx, cy, s):
    """VEXMIRA emblem: angular V with a centre spike."""
    v = cv.poly([(cx - 0.9 * s, cy - 0.7 * s), (cx - 0.48 * s, cy - 0.7 * s), (cx, cy + 0.32 * s),
                 (cx + 0.48 * s, cy - 0.7 * s), (cx + 0.9 * s, cy - 0.7 * s), (cx + 0.08 * s, cy + 0.9 * s), (cx - 0.08 * s, cy + 0.9 * s)])
    spike = cv.poly([(cx, cy - 0.95 * s), (cx + 0.14 * s, cy - 0.35 * s), (cx, cy - 0.12 * s), (cx - 0.14 * s, cy - 0.35 * s)])
    return np.clip(v + spike, 0, 1)


def diamond(cv, cx, cy, s):
    outer = cv.poly([(cx - 0.9 * s, cy - 0.25 * s), (cx - 0.5 * s, cy - 0.7 * s), (cx + 0.5 * s, cy - 0.7 * s),
                     (cx + 0.9 * s, cy - 0.25 * s), (cx, cy + 0.88 * s)])
    cuts = cv.line([(cx - 0.9 * s, cy - 0.25 * s), (cx + 0.9 * s, cy - 0.25 * s)], 0.08 * s) + \
        cv.line([(cx - 0.3 * s, cy - 0.25 * s), (cx, cy + 0.8 * s), (cx + 0.3 * s, cy - 0.25 * s)], 0.07 * s)
    return np.clip(outer - cuts, 0, 1)


def target_x(cv, cx, cy, s, gap=0.35, w=0.16):
    m = np.zeros_like(cv.a)
    for dx, dy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
        m = m + cv.line([(cx + dx * gap * s, cy + dy * gap * s), (cx + dx * s, cy + dy * s)], w * s)
    return np.clip(m, 0, 1)
