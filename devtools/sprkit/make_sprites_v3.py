# Vexmira Zombie v3 sprite uretici (tamamen prosedurel, sabit tohumlu).
#   python3 make_sprites_v3.py [cikti_klasoru] [ad1,ad2,...]
# v2 sprite'lari (make_sprites.py) aynen kalir; bu betik sadece v3 dosyalarini yazar.
#
# Oyunda kullanim (eklenti icin):
#   * ALPHTEST sprite'lar (bossbar, hpbar_small, bossicon, icon_*): gercek renkli; env_sprite icin
#     rendermode = kRenderTransAlpha (4), renderamt = 255, framerate = 0, frame = kare no.
#     rendercolor etkisizdir. Palet indeksi 255 saydam.
#   * ADDITIVE sprite'lar: kRenderTransAdd; TE_SPRITE / TE_EXPLOSION ile de kullanilir (10 fps, 1 dongu).
#     Renkli paletliler kendi rengini tasir; gri olanlar (slash, shock, web, chain) rendercolor / isin rengi ile boyanir.
#   * Boyutlar 2'nin kuvveti secildi: GoldSrc GL (gl_round_down 3) 192x24 gibi boyutlari 128x16'ya kucultup
#     bulaniklastirir; 256x32 / 128x16 / 64x64 / 128x128 yeniden orneklenmeden yuklenir.
import os, sys
sys.dont_write_bytecode = True
import numpy as np
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sprlib import *  # noqa

OUT = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith('-') else '/home/user/claude/cstrike/sprites/vexmira'
ONLY = sys.argv[2].split(',') if len(sys.argv) > 2 else None

SS = 4

# ============================================================================
# CAN BARLARI
# ============================================================================
GOLD = [(0.0, (70, 40, 8)), (0.35, (150, 100, 28)), (0.6, (222, 172, 70)), (0.82, (255, 226, 140)), (1.0, (255, 250, 220))]
FILL_STOPS = [(0.0, (128, 0, 10)), (0.35, (206, 22, 16)), (0.72, (244, 78, 12)), (1.0, (255, 160, 24))]


def frame_material(cv, outer, bands):
    """outer: dis sekil maskesi. bands: (kalinlik, tur) listesi icten disa degil, distan ice.
    tur: 'line' renk | 'gold' metal sirt. Donus: kalan ic maske, ic uzaklik alani."""
    d = edt_in(outer, cv.ss)
    gy, gx = np.gradient(ndimage.gaussian_filter(d, cv.ss * 0.6))
    gn = np.hypot(gx, gy) + 1e-9
    gx, gy = gx / gn, gy / gn
    vy = (cv.Y - cv.Y.min()) / (cv.Y.max() - cv.Y.min())
    start = 0.0
    for thick, kind in bands:
        m = ((d > start) & (d <= start + thick)).astype(float)
        if kind == 'gold':
            t = (d - start) / thick  # 0 dis, 1 ic
            k = 1 - 2 * t  # dis yamac +, ic yamac -
            nx, ny = -gx * k, -gy * k  # yuzey normali (2B)
            shade = 0.5 + 0.42 * (nx * -0.35 + ny * -0.94) + 0.18 * (0.5 - vy)
            ridge = np.exp(-((t - 0.42) / 0.16) ** 2) * 0.18  # sirt parlamasi
            col = grad_stops(np.clip(shade + ridge, 0, 1), GOLD)
            cv.paint(m, col)
        else:
            cv.paint(m, kind)
        start += thick
    inner = (d > start).astype(float)
    return inner, d - start


def bar_frames(W, H, outer_pts, bands, crest, fill_stops, nframes=51, ticks=10, hatch=True, tick_notch=True):
    cv = Canvas(W, H, SS)
    outer = cv.poly(outer_pts)
    # dis kontur (golge gibi 1px siyah) zaten bands[0]
    if crest:
        crest(cv, before=True)
    inner, di = frame_material(cv, outer, bands)
    # bos oluk: koyu, ust kenarda ic golge
    vy_in = np.where(inner > 0, cv.Y, np.nan)
    ytop = np.nanmin(vy_in)
    ybot = np.nanmax(vy_in)
    v = np.clip((cv.Y - ytop) / (ybot - ytop), 0, 1)
    rec = np.clip(di / 2.5, 0, 1)
    empty = lerp((10, 3, 4), (34, 12, 14), rec * (0.55 + 0.45 * v))
    cv.paint(inner, empty)
    if crest:
        crest(cv, before=False)
    base_rgb, base_a = cv.down()
    inner_d = cv.downm(inner)
    di_d = cv.downm(np.where(inner > 0, di, 0)) / np.maximum(inner_d, 1e-6)
    # yatay aralik (orta satirda)
    rows = np.where(inner_d.max(1) > 0.5)[0]
    mid = (rows[0] + rows[-1]) // 2
    cols = np.where(inner_d[mid] > 0.5)[0]
    xl, xr = cols[0], cols[-1] + 1
    yy, xx = np.mgrid[0:H, 0:W]
    y0, y1 = rows[0], rows[-1] + 1
    vv = (yy + 0.5 - y0) / (y1 - y0)  # 0 ust .. 1 alt
    u = (xx + 0.5 - xl) / (xr - xl)
    # dolgu rengi
    fill = grad_stops(u, fill_stops)
    shine = np.clip(1 - vv / 0.45, 0, 1) ** 1.3 * 0.42
    fill = lerp(fill, (255, 236, 205), shine)
    fill = fill * (1 - 0.42 * np.clip((vv - 0.62) / 0.38, 0, 1))[..., None]
    fill = fill * (0.78 + 0.22 * np.clip(di_d / 1.5, 0, 1))[..., None]  # ic kenar golgesi
    if hatch:
        hm = ((xx + yy) % 7 == 0) & (vv > 0.4)
        fill = np.where(hm[..., None], fill * 1.12 + 6, fill)
    # bolum cizgileri
    tick_x = [int(round(xl + k * (xr - xl) / ticks)) for k in range(1, ticks)]
    tickm = np.isin(xx, tick_x)
    fill_t = np.where(tickm[..., None], fill * 0.42, fill)
    empty_t = np.where((tickm & (vv > 0.15))[..., None] & (inner_d[..., None] > 0.5), base_rgb + np.array([30, 14, 12]), base_rgb)
    base_t = np.where(inner_d[..., None] > 0.5, empty_t, base_rgb)
    if tick_notch:
        # altin cercevede bolum centikleri (alt ve ust kenarda 1px koyu)
        pass
    rgb0, op = finalize_rgba(base_t, base_a)
    fills = []
    for i in range(nframes):
        p = i / (nframes - 1)
        xe = xl + int(round(p * (xr - xl)))
        fm = (inner_d > 0.5) & (xx < xe)
        col = np.where(fm[..., None], fill_t, rgb0)
        if 0 < i < nframes - 1:
            edge = fm & (xx == xe - 1)
            col = np.where(edge[..., None], lerp(col, (255, 244, 210), 0.78), col)
            edge2 = fm & (xx == xe - 2)
            col = np.where(edge2[..., None], lerp(col, (255, 220, 160), 0.3), col)
        if 0 < i < nframes - 1:
            # bos tarafta hafif sicak isima (dolgu ucundan sizan isik)
            glow = (inner_d > 0.5) & (xx >= xe) & (xx < xe + 3)
            gk = np.clip(1 - (xx - xe) / 3.0, 0, 1) * 0.35
            col = np.where(glow[..., None], lerp(col, (200, 60, 20), gk), col)
        fills.append(col)
    return fills, [op] * nframes


def bossbar():
    W, H = 256, 32
    yt, yb = 5, 27
    pts = [(1, 16), (1 + (16 - yt), yt), (W - 1 - (16 - yt), yt), (W - 1, 16), (W - 1 - (yb - 16), yb), (1 + (yb - 16), yb)]

    # cerceve katmanlari (distan ice): kontur, altin, koyu ic cizgi
    bands = [(1.0, (12, 7, 5)), (3.0, 'gold'), (1.0, (26, 10, 8))]
    frames, ops = bar_frames(W, H, pts, bands, None, FILL_STOPS, 51, 10)
    # ust kat: uc civileri + ust orta arma (altin kalkan, kirmizi tas)
    cv = Canvas(W, H, SS)
    for x in (8.5, W - 8.5):
        st = cv.circle(x, 16, 2.1)
        cv.paint(grow(st, 0.8, cv.ss), (10, 6, 4))
        cv.paint(st, grad_stops(np.clip(0.55 + 0.45 * bevel(st, cv.ss, 0.5), 0, 1), GOLD))
    cx = W / 2
    c_out = cv.poly([(cx - 15, 6), (cx - 10, 1), (cx - 4, 3), (cx, 0), (cx + 4, 3), (cx + 10, 1), (cx + 15, 6), (cx, 10)])
    cv.paint(grow(c_out, 1.0, cv.ss), (10, 6, 4))
    sh = bevel(c_out, cv.ss, sigma=0.9)
    cv.paint(c_out, grad_stops(np.clip(0.55 + 0.45 * sh - 0.3 * (cv.Y / 12 - 0.3), 0, 1), GOLD))
    gem = cv.ellipse(cx, 4.8, 3.3, 2.7)
    cv.paint(grow(gem, 0.8, cv.ss), (40, 6, 6))
    cv.paint(gem, grad_stops(np.clip(0.5 + 0.5 * bevel(gem, cv.ss, 0.5), 0, 1),
                             [(0, (90, 0, 6)), (0.5, (220, 20, 30)), (0.85, (255, 120, 110)), (1, (255, 230, 220))]))
    orgb, oa = cv.down()
    ocol, oop = finalize_rgba(orgb, oa)
    frames = [np.where(oop[..., None], ocol, f) for f in frames]
    ops = [o | oop for o in ops]
    idx, pal = quantize_alphatest(frames, ops)
    return idx, VP_PARALLEL, pal, TF_ALPHTEST


def hpbar_small():
    W, H = 128, 16
    yt, yb = 2, 14
    pts = [(1, 8), (1 + (8 - yt), yt), (W - 1 - (8 - yt), yt), (W - 1, 8), (W - 1 - (yb - 8), yb), (1 + (yb - 8), yb)]
    bands = [(1.0, (12, 7, 5)), (1.5, 'gold'), (0.6, (26, 10, 8))]
    stops = [(0.0, (120, 0, 30)), (0.4, (200, 16, 40)), (0.75, (240, 60, 30)), (1.0, (255, 140, 30))]
    frames, ops = bar_frames(W, H, pts, bands, None, stops, 51, 5, hatch=False)
    idx, pal = quantize_alphatest(frames, ops)
    return idx, VP_PARALLEL, pal, TF_ALPHTEST



# ============================================================================
# AMBLEMLER (boss ikonlari + kafa ustu ikonlar)  ALPHTEST 64x64
# ============================================================================
BOSS_RGB = [(255, 120, 0), (190, 210, 255), (160, 0, 255), (255, 50, 0), (120, 0, 190),
            (0, 190, 255), (255, 240, 80), (110, 255, 0), (220, 0, 140)]
OUTLINE = (8, 6, 10)


def mats(theme):
    t = np.array(theme, float)
    wh = np.array((255, 255, 255), float)
    return {
        'theme': [(0, t * 0.22), (0.45, t * 0.7), (0.75, t * 0.95 + 8), (1, t * 0.35 + wh * 0.65)],
        'themedark': [(0, t * 0.1), (0.5, t * 0.35), (0.85, t * 0.6), (1, t * 0.6 + wh * 0.3)],
        'gold': GOLD,
        'bone': [(0, (64, 54, 46)), (0.45, (172, 160, 140)), (0.75, (226, 218, 198)), (1, (255, 252, 240))],
        'pale': [(0, t * 0.35), (0.5, t * 0.45 + wh * 0.4), (0.8, t * 0.2 + wh * 0.78), (1, wh)],
        'dark': [(0, (6, 4, 8)), (0.6, (26, 20, 30)), (1, (60, 52, 66))],
        'steel': [(0, (34, 30, 48)), (0.5, (120, 116, 146)), (0.8, (200, 202, 222)), (1, (255, 255, 255))],
        'horn': [(0, (50, 26, 18)), (0.4, (140, 96, 70)), (0.75, (222, 186, 146)), (1, (255, 242, 220))],
        'fire': [(0, (110, 8, 0)), (0.4, (226, 56, 0)), (0.75, (255, 160, 20)), (1, (255, 246, 190))],
        'core': [(0, (255, 140, 0)), (0.5, (255, 214, 60)), (1, (255, 255, 230))],
        'ice': [(0, (16, 54, 104)), (0.45, (50, 160, 226)), (0.78, (168, 232, 255)), (1, (255, 255, 255))],
        'cloud': [(0, (24, 26, 38)), (0.55, (82, 88, 116)), (1, (176, 182, 210))],
        'bolt': [(0, (210, 140, 0)), (0.4, (255, 218, 40)), (0.8, (255, 250, 170)), (1, (255, 255, 255))],
        'wing': [(0, (50, 80, 64)), (0.55, (140, 196, 164)), (1, (236, 255, 240))],
        'red': [(0, (80, 0, 6)), (0.5, (214, 18, 28)), (0.85, (255, 120, 110)), (1, (255, 230, 220))],
        'blue': [(0, (0, 20, 90)), (0.5, (30, 90, 230)), (0.85, (130, 180, 255)), (1, (235, 245, 255))],
        'green': [(0, (0, 60, 10)), (0.5, (30, 190, 40)), (0.85, (150, 255, 140)), (1, (240, 255, 235))],
        'cyan': [(0, (0, 40, 70)), (0.5, (0, 170, 230)), (0.85, (120, 230, 255)), (1, (240, 255, 255))],
        'silver': [(0, (50, 54, 64)), (0.5, (150, 156, 170)), (0.85, (225, 230, 238)), (1, (255, 255, 255))],
        'white': [(0, (150, 160, 170)), (0.6, (225, 232, 240)), (1, (255, 255, 255))],
    }


class Painter:
    def __init__(self, cv, theme):
        self.cv, self.M = cv, mats(theme)
        self.theme = np.array(theme, float)

    def shade(self, m, sigma=1.1, vgrad=0.22, base=0.55, amp=0.42):
        cv = self.cv
        ys = np.where(m > 0.5, cv.Y, np.nan)
        if np.all(np.isnan(ys)):
            return np.zeros_like(m)
        y0, y1 = np.nanmin(ys), np.nanmax(ys)
        v = (cv.Y - y0) / max(1e-6, y1 - y0)
        return np.clip(base + amp * bevel(m, cv.ss, sigma) + vgrad * (0.5 - v), 0, 1)

    def __call__(self, m, mat, outline=1.2, sigma=1.1, vgrad=0.22, base=0.55, amp=0.42, alpha=1.0):
        cv = self.cv
        if outline > 0:
            cv.paint(grow(m, outline, cv.ss), OUTLINE, alpha)
        if isinstance(mat, str):
            col = grad_stops(self.shade(m, sigma, vgrad, base, amp), self.M[mat])
        else:
            col = mat
        cv.paint(m, col, alpha)


def horn_poly(center_pts, w0, w1=0.0, n=40):
    c = np.array(bezier(center_pts, n))
    d = np.gradient(c, axis=0)
    d /= np.linalg.norm(d, axis=1)[:, None] + 1e-9
    nrm = np.stack([-d[:, 1], d[:, 0]], 1)
    w = np.linspace(w0, w1, n)[:, None] / 2
    left = c + nrm * w
    right = c - nrm * w
    return [tuple(p) for p in np.concatenate([left, right[::-1]])]


def mirror(pts, cx=32.0):
    return [(2 * cx - x, y) for x, y in pts]


def badge(cv, theme):
    """altin cerceveli yuvarlak madalyon; ic yaricap dondurur."""
    t = np.array(theme, float)
    cx = cy = 32.0
    disc = cv.circle(cx, cy, 30.6)
    d = edt_in(disc, cv.ss)
    r = np.hypot(cv.X - cx, cv.Y - cy)
    # dis kontur
    cv.paint(disc, OUTLINE)
    # altin halka (sirt golgeleme)
    gm = ((d > 1.0) & (d <= 4.2)).astype(float)
    tt = (d - 1.0) / 3.2
    k = 1 - 2 * tt
    nx, ny = (cv.X - cx) / (r + 1e-6) * k, (cv.Y - cy) / (r + 1e-6) * k
    sh = 0.52 + 0.42 * (nx * -0.42 + ny * -0.9) + np.exp(-((tt - 0.4) / 0.17) ** 2) * 0.16
    cv.paint(gm, grad_stops(np.clip(sh, 0, 1), GOLD))
    # ic koyu cizgi
    cv.paint(((d > 4.2) & (d <= 5.0)).astype(float), (14, 8, 6))
    # zemin: tema renkli radyal gradyan
    inner = (d > 5.0).astype(float)
    rr = np.clip(r / 25.6, 0, 1)
    bg = lerp(t * 0.34 + 6, t * 0.06 + 4, rr ** 0.8)
    # tema renkli ic kenar isiltisi
    bg = lerp(bg, t * 0.55, np.exp(-((rr - 0.97) / 0.05) ** 2) * 0.6)
    cv.paint(inner, bg)
    # altin halkada 4 civi
    for a in (np.pi / 4, 3 * np.pi / 4, 5 * np.pi / 4, 7 * np.pi / 4):
        st = cv.circle(cx + 27.9 * np.cos(a), cy + 27.9 * np.sin(a), 1.25)
        cv.paint(st, grad_stops(np.clip(0.55 + 0.5 * bevel(st, cv.ss, 0.35), 0, 1), GOLD))
    return 25.4


def glyph_brute(cv, P):
    P(cv.rrect(23.5, 41, 40.5, 56, 2.5), 'theme')
    P(cv.rrect(21.5, 44, 42.5, 49, 1.5), 'steel', outline=1.0)  # zincir bilezik
    for x in (25, 30, 35, 40):
        P(cv.rrect(x - 1.6, 44.4, x + 1.6, 48.6, 1.2), 'steel', outline=0.7)
    P(cv.rrect(16.5, 24, 47.5, 45, 5), 'theme')
    tops = [19.5, 16.5, 16.5, 19]
    for k in range(4):
        x0 = 16.5 + k * 7.75
        P(cv.rrect(x0, tops[k], x0 + 7.75, 31.5, 3.6), 'theme', outline=1.0)
    P(cv.rrect(13.5, 30, 36, 37.5, 3.7), 'theme', outline=1.0)
    # eklem catlaklari (kaya yumruk)
    for (a, b) in (((20, 26), (22, 28)), ((44, 35), (41, 39)), ((28, 40), (31, 42.5))):
        cv.paint(cv.line([a, b], 0.7), OUTLINE, 0.8)


def glyph_banshee(cv, P):
    hair = [(32, 11), (24, 12), (16, 19), (13, 30), (13, 42), (9, 54), (16, 49), (17, 57), (22, 47), (25, 52), (26, 40), (26, 26)]
    P(cv.poly(hair), 'themedark')
    P(cv.poly(mirror(hair)), 'themedark')
    P(cv.poly([(32, 11), (22, 15), (20, 22), (32, 18), (44, 22), (42, 15)]), 'themedark')
    face = cv.ellipse(32, 31, 10, 15)
    P(face, 'pale', sigma=1.6, amp=0.35, base=0.6)
    for sx in (-1, 1):
        eye = cv.poly([(32 + sx * 2.2, 27.6), (32 + sx * 8.4, 24.6), (32 + sx * 7.8, 29.8), (32 + sx * 3.2, 30.4)])
        cv.paint(eye, OUTLINE)
        cv.paint(cv.circle(32 + sx * 5.6, 28.4, 1.15), (230, 245, 255))
    mouth = cv.ellipse(32, 40.5, 4.2, 7.2)
    cv.paint(grow(mouth, 0.5, cv.ss), (40, 40, 60))
    cv.paint(mouth, lerp((4, 2, 10), (60, 70, 120), np.clip((cv.Y - 34) / 14, 0, 1) ** 2))
    # gozyaslari / cizikler
    for sx in (-1, 1):
        cv.paint(cv.line([(32 + sx * 5.6, 31.5), (32 + sx * 6.2, 37)], 0.8), (90, 100, 150), 0.9)


def glyph_overlord(cv, P):
    P(cv.rrect(24.5, 38, 39.5, 50.5, 3), 'bone')
    P(cv.ellipse(32, 33.5, 12.5, 11.5), 'bone', sigma=1.4)
    for sx in (-1, 1):
        cv.paint(cv.ellipse(32 + sx * 5, 35, 3.6, 4.0), OUTLINE)
        cv.paint(cv.circle(32 + sx * 5, 35.4, 1.5), lerp(P.theme, (255, 255, 255), 0.45))
    cv.paint(cv.poly([(32, 38.6), (30.1, 42.4), (33.9, 42.4)]), OUTLINE)
    cv.paint(cv.line([(25.6, 45.3), (38.4, 45.3)], 0.8), OUTLINE)
    for x in (28.2, 30.9, 33.6, 36.3):
        cv.paint(cv.line([(x, 45.3), (x, 49.6)], 0.7), OUTLINE, 0.85)
    crown = [(18.5, 26.5), (18.5, 12.5), (23.2, 19.5), (26, 9.5), (29, 18.5), (32, 5.5), (35, 18.5), (38, 9.5), (40.8, 19.5), (45.5, 12.5), (45.5, 26.5)]
    P(cv.poly(crown), 'gold', sigma=0.9)
    cv.paint(cv.line([(18.8, 21.6), (45.2, 21.6)], 0.6), (110, 70, 20), 0.8)
    for x, y in ((18.5, 12.5), (26, 9.5), (32, 5.5), (38, 9.5), (45.5, 12.5)):
        b = cv.circle(x, y, 1.35)
        P(b, 'gold', outline=0.7, sigma=0.35)
    g = cv.ellipse(32, 23.6, 2.2, 2.4)
    P(g, 'red', outline=0.7, sigma=0.5)
    for x in (24.5, 39.5):
        P(cv.circle(x, 23.8, 1.5), 'theme', outline=0.7, sigma=0.4)


def glyph_inferno(cv, P):
    for sx in (-1, 1):
        pts = horn_poly([(32 + sx * 8, 40), (32 + sx * 19, 36), (32 + sx * 21, 20), (32 + sx * 16, 8)], 8.5, 0.6)
        P(cv.poly(pts), 'horn', sigma=1.0)
        # boynuz halkalari
        for t in (0.25, 0.42, 0.58):
            c = bezier([(32 + sx * 8, 40), (32 + sx * 19, 36), (32 + sx * 21, 20), (32 + sx * 16, 8)], 101)[int(t * 100)]
            cv.paint(cv.line([(c[0] - 3.2, c[1] + sx * 0.4 - 1), (c[0] + 3.2, c[1] - sx * 0.4 + 1)], 0.6), OUTLINE, 0.55)
    flame = [(32, 55), (24, 51), (19.5, 43), (20.5, 33), (24.5, 25.5), (26, 32), (28.5, 21), (27.5, 10.5), (34, 19), (36.5, 12.5), (40, 23.5), (42.5, 19.5), (44.5, 30), (44.5, 42), (40.5, 50.5)]
    P(cv.poly(flame), 'fire', sigma=1.3, vgrad=-0.3)
    core = [(32, 52.5), (27, 48.5), (25.8, 41.5), (28.8, 34), (30.2, 38), (32.6, 29), (35, 35.5), (37.2, 32.5), (38.4, 42), (36.8, 48.6)]
    P(cv.poly(core), 'core', outline=0, sigma=1.0, vgrad=-0.3, base=0.6)
    # alevde iki goz yarigi (iblis yuzu izlenimi)
    for sx in (-1, 1):
        cv.paint(cv.poly([(32 + sx * 1.6, 43.4), (32 + sx * 5.6, 41.2), (32 + sx * 5.0, 44.4), (32 + sx * 2.0, 45.0)]), (120, 20, 0), 0.9)


def glyph_reaper(cv, P):
    hood = [(30, 11.5), (21, 16.5), (15.5, 28), (13.5, 42), (11, 55), (18, 50), (23, 56), (30, 51), (37, 56), (42, 50), (48, 54), (45.5, 42), (44, 28), (39, 16.5)]
    P(cv.poly(hood), 'themedark', sigma=1.6, base=0.62)
    for x0 in (23.5, 36.5):
        cv.paint(cv.line([(x0, 40), (x0 + (x0 - 30) * 0.3, 52)], 0.7), OUTLINE, 0.6)
    cv.paint(cv.ellipse(30, 31.5, 9, 11), OUTLINE)
    P(cv.ellipse(30, 31.2, 6.4, 7.8), 'bone', outline=0, sigma=1.0)
    for sx in (-1, 1):
        cv.paint(cv.ellipse(30 + sx * 2.7, 30.2, 2.1, 2.5), OUTLINE)
        cv.paint(cv.circle(30 + sx * 2.7, 30.6, 1.0), lerp(P.theme, (255, 255, 255), 0.6))
    cv.paint(cv.poly([(30, 33.2), (29, 35), (31, 35)]), OUTLINE)
    cv.paint(cv.line([(27.4, 37.2), (32.6, 37.2)], 0.7), OUTLINE, 0.9)
    for x in (28.6, 30, 31.4):
        cv.paint(cv.line([(x, 36.4), (x, 38.2)], 0.5), OUTLINE, 0.8)
    P(cv.line([(48.5, 60), (44.5, 9)], 3.4), 'themedark', outline=1.0)
    for y in (44, 49):
        x = 48.5 + (44.5 - 48.5) * (60 - y) / 51
        P(cv.line([(x - 2.4, y), (x + 2.4, y - 0.4)], 1.3), 'gold', outline=0.6, sigma=0.4)
    outer = bezier([(45.5, 9.5), (34, -1), (12, 2), (3.5, 22.5)], 40)
    inner = bezier([(3.5, 22.5), (12.5, 9.5), (29, 6.5), (44, 15.5)], 40)
    P(cv.poly(outer + inner), 'steel', sigma=0.9)
    cv.paint(cv.line(bezier([(6, 19.5), (13.5, 9.8), (28.5, 7.7), (42, 14.2)], 30), 0.8), lerp(P.theme, (255, 255, 255), 0.6), 0.95)
    P(cv.circle(45, 12, 3.0), 'theme', outline=0.9, sigma=0.6)
    cv.paint(cv.circle(45, 12, 1.0), (255, 230, 255))


def glyph_frostlord(cv, P):
    def crystal(pts, axis):
        m = cv.poly(pts)
        P(m, 'ice', sigma=0.8)
        # sag yuz golgeli (faset)
        cv.paint(m * (cv.X > axis), (0, 40, 90), 0.38)
        top = min(p[1] for p in pts)
        bot = max(p[1] for p in pts)
        cv.paint(cv.line([(axis, top + 1.5), (axis, bot - 1.5)], 0.6) * m, (220, 250, 255), 0.6)
    left = [(11.5, 47), (12, 31), (17, 21), (22.5, 30), (22.5, 47), (17, 53)]
    crystal(left, 17)
    crystal(mirror(left), 47)
    crystal([(32, 5.5), (40.5, 17.5), (40.5, 44), (32, 57), (23.5, 44), (23.5, 17.5)], 32)
    cv.paint(cv.line([(23.8, 17.8), (32, 21.5), (40.2, 17.8)], 0.6), (255, 255, 255), 0.7)
    # parilti
    for x, y, s in ((38.5, 12.5, 3.4), (16, 25, 2.2)):
        st = cv.poly([(x, y - s), (x + s * 0.25, y - s * 0.25), (x + s, y), (x + s * 0.25, y + s * 0.25), (x, y + s), (x - s * 0.25, y + s * 0.25), (x - s, y), (x - s * 0.25, y - s * 0.25)])
        cv.paint(st, (255, 255, 255))


def glyph_storm(cv, P):
    cloud = np.zeros_like(cv.X)
    for x, y, r in ((21.5, 22.5, 6.5), (30.5, 16.5, 8.5), (40.5, 19.5, 7.5), (46, 25, 5), (17, 26.5, 4.5)):
        cloud = np.maximum(cloud, cv.circle(x, y, r))
    cloud = np.maximum(cloud, cv.rrect(16, 22, 50, 30.5, 4))
    P(cloud, 'cloud', sigma=1.6)
    bolt = [(35.5, 23), (23, 40.5), (31.5, 40.5), (25, 58.5), (44.5, 34.5), (35.5, 34.5), (41.5, 23)]
    P(cv.poly(bolt), 'bolt', sigma=0.8)
    for pts in (((14, 34), (11.5, 38), (14, 39), (11, 44)), ((49, 33), (52.5, 37), (49.5, 38.5), (53, 43))):
        cv.paint(grow(cv.line(pts, 1.0), 0.6, cv.ss), OUTLINE)
        cv.paint(cv.line(pts, 1.0), (255, 245, 150))


def glyph_hive(cv, P):
    for sx in (-1, 1):
        P(cv.poly(ellipse_pts(32 + sx * 10.5, 25, 11.5, 4.6, sx * -0.55)), 'wing', outline=0.9, sigma=1.0)
        P(cv.poly(ellipse_pts(32 + sx * 9.5, 32.5, 8.5, 3.4, sx * 0.4)), 'wing', outline=0.9, sigma=0.9)
    for sx in (-1, 1):
        for pts in (((29.5, 28), (21, 23.5), (16.5, 17.5)), ((29.5, 31), (18.5, 33), (13.5, 39)), ((30, 34), (22, 42), (19, 51))):
            pp = [(32 + sx * (32 - x) * -1, y) if False else (32 - sx * (32 - x), y) for x, y in pts]
            P(cv.line(pp, 1.5), 'themedark', outline=0.8, sigma=0.4)
    ab = cv.ellipse(32, 44, 7.6, 11.2)
    P(ab, 'theme', sigma=1.4)
    for y in (38.5, 43.5, 48.5):
        cv.paint(ab * np.clip(1 - np.abs(cv.Y - y) / 0.9, 0, 1), (10, 30, 0), 0.75)
    P(cv.ellipse(32, 29.5, 5.6, 4.8), 'theme', sigma=1.0)
    for sx in (-1, 1):
        P(cv.line([(32 + sx * 1.8, 17.5), (32 + sx * 5, 11), (32 + sx * 10, 8.5)], 1.0), 'themedark', outline=0.7, sigma=0.3)
    P(cv.circle(32, 21.2, 4.4), 'theme', sigma=0.9)
    for sx in (-1, 1):
        cv.paint(cv.ellipse(32 + sx * 2.1, 21.4, 1.4, 1.9), (255, 40, 30))
    crown = [(28.4, 17.6), (28.4, 13.4), (30.3, 15.6), (32, 12.2), (33.7, 15.6), (35.6, 13.4), (35.6, 17.6)]
    P(cv.poly(crown), 'gold', outline=0.7, sigma=0.4)


def glyph_void(cv, P):
    cx, cy = 32.0, 32.0
    r = np.hypot(cv.X - cx, cv.Y - cy)
    th = np.arctan2(cv.Y - cy, cv.X - cx)
    t = P.theme
    arms = 0.5 + 0.5 * np.cos(3 * (th + 2.4 * np.log(np.maximum(r, 0.5) / 6.0)))
    arms = arms ** 2.2
    prof = np.exp(-((r - 10.5) / 7.5) ** 2)
    I = np.clip(prof * (0.25 + 0.95 * arms), 0, 1)
    disk = cv.circle(cx, cy, 24.6)
    col = grad_stops(I, [(0, t * 0.07), (0.35, t * 0.45), (0.7, t * 0.95), (0.9, t * 0.5 + 120), (1, (255, 236, 250))])
    cv.paint(disk, col)
    # foton halkasi + olay ufku
    ring = np.clip(1 - np.abs(r - 7.6) / 1.3, 0, 1)
    cv.paint(ring, lerp(t, (255, 255, 255), 0.65))
    cv.paint(cv.circle(cx, cy, 6.4), (3, 0, 6))
    # yuzen parcalar
    for x, y, s, a in ((14, 16, 2.6, 0.3), (50, 45, 2.2, 1.1), (47, 15, 1.7, 2.0), (16, 48, 1.6, 0.8)):
        pts = [(x + s * np.cos(a + k * 2.1 + (k % 2) * 0.4), y + s * np.sin(a + k * 2.1 + (k % 2) * 0.4)) for k in range(3)]
        P(cv.poly(pts), 'dark', outline=0.6, sigma=0.4)
        cv.paint(cv.line([pts[0], pts[1]], 0.5), t * 0.6 + 90, 0.9)


BOSS_GLYPHS = [glyph_brute, glyph_banshee, glyph_overlord, glyph_inferno, glyph_reaper,
               glyph_frostlord, glyph_storm, glyph_hive, glyph_void]


def bossicon():
    frames, ops = [], []
    for k, g in enumerate(BOSS_GLYPHS):
        cv = Canvas(64, 64, SS)
        badge(cv, BOSS_RGB[k])
        P = Painter(cv, BOSS_RGB[k])
        g(cv, P)
        rgb, a = cv.down()
        col, o = finalize_rgba(rgb, a)
        frames.append(col)
        ops.append(o)
    idx, pal = quantize_alphatest(frames, ops)
    return idx, VP_PARALLEL, pal, TF_ALPHTEST


def star_pts(cx, cy, ro, ri, n=5, rot=-np.pi / 2):
    pts = []
    for k in range(2 * n):
        r = ro if k % 2 == 0 else ri
        a = rot + k * np.pi / n
        pts.append((cx + r * np.cos(a), cy + r * np.sin(a)))
    return pts


def head_icon(draw, theme=(255, 255, 255)):
    cv = Canvas(64, 64, SS)
    P = Painter(cv, theme)
    draw(cv, P)
    rgb, a = cv.down()
    col, o = finalize_rgba(rgb, a)
    idx, pal = quantize_alphatest([col], [o])
    return idx, VP_PARALLEL, pal, TF_ALPHTEST


def icon_vip():
    def d(cv, P):
        crown = [(8, 47), (6, 19), (19.5, 31), (32, 9), (44.5, 31), (58, 19), (56, 47)]
        P(cv.poly(crown), 'gold', outline=1.8, sigma=1.2)
        # ic kivrim cizgileri
        for pts in (((10, 41), (20, 35), (32, 33), (44, 35), (54, 41)),):
            cv.paint(cv.line(bezier(pts, 20), 0.8), (120, 76, 18), 0.7)
        P(cv.rrect(7, 42, 57, 53, 2.5), 'gold', outline=1.5, sigma=0.9)
        cv.paint(cv.line([(9, 44.2), (55, 44.2)], 0.7), (255, 245, 200), 0.6)
        for x, y in ((6, 19), (32, 9), (58, 19)):
            P(cv.circle(x, y, 3.4), 'gold', outline=1.2, sigma=0.5)
        P(cv.ellipse(32, 47.5, 4.2, 3.4), 'red', outline=0.9, sigma=0.6)
        for x in (17, 47):
            P(cv.poly([(x, 44.4), (x + 3, 47.5), (x, 50.6), (x - 3, 47.5)]), 'blue', outline=0.9, sigma=0.5)
        P(cv.ellipse(32, 27, 2.6, 3.4), 'green', outline=0.8, sigma=0.5)
        cv.paint(cv.poly(star_pts(23, 36.5, 2.4, 0.6, 4, 0)), (255, 255, 240))
    return head_icon(d, (255, 215, 0))


def icon_admin():
    def d(cv, P):
        sh = [(32, 4.5), (54.5, 11.5), (52.5, 35), (32, 59), (11.5, 35), (9.5, 11.5)]
        m = cv.poly(sh)
        P(m, 'gold', outline=1.8, sigma=1.0)
        di = edt_in(m, cv.ss)
        inner = (di > 3.4).astype(float)
        y = (cv.Y - 6) / 50
        cv.paint(grow(inner, 0.6, cv.ss) * m, (30, 4, 4))
        col = grad_stops(np.clip(0.55 + 0.38 * bevel(inner, cv.ss, 2.0) + 0.25 * (0.5 - y), 0, 1),
                         [(0, (40, 0, 4)), (0.45, (150, 6, 16)), (0.8, (226, 40, 40)), (1, (255, 150, 140))])
        cv.paint(inner, col)
        # orta ayirma cizgisi (kalkan iki yarim)
        cv.paint(inner * (cv.X > 32), (0, 0, 0), 0.22)
        st = cv.poly(star_pts(32, 31, 15.5, 6.4))
        P(st, 'silver', outline=1.3, sigma=0.8)
        cv.paint(st * (cv.X > 32), (40, 50, 70), 0.25)
    return head_icon(d, (255, 40, 40))


def icon_mvp():
    def d(cv, P):
        for sx in (-1, 1):
            ring = np.clip(cv.ellipse(32 + sx * 15.5, 20, 7.5, 8.5) - cv.ellipse(32 + sx * 15.5, 20, 4.2, 5.2), 0, 1)
            ring = ring * (sx * (cv.X - 32) > 12)
            P(ring, 'gold', outline=1.4, sigma=0.7)
        P(cv.rrect(27.5, 33, 36.5, 46, 1.5), 'gold', outline=1.4, sigma=0.7)
        cup = bezier([(15, 8), (15.5, 28), (24, 37), (32, 37)], 20) + bezier([(32, 37), (40, 37), (48.5, 28), (49, 8)], 20)
        P(cv.poly(cup), 'gold', outline=1.8, sigma=1.4)
        P(cv.rrect(14, 6.5, 50, 11, 1.5), 'gold', outline=1.3, sigma=0.6)
        P(cv.rrect(21, 45, 43, 50, 1.2), 'gold', outline=1.3, sigma=0.6)
        P(cv.rrect(17, 49.5, 47, 58, 2), [(0, (20, 14, 10)), (1, (90, 60, 40))] and 'dark', outline=1.5, sigma=0.6)
        cv.paint(cv.rrect(25, 52, 39, 55.5, 0.8), (230, 190, 90))
        P(cv.poly(star_pts(32, 21.5, 8.6, 3.6)), 'white', outline=1.0, sigma=0.5)
        cv.paint(cv.line([(19.5, 13), (20.5, 26)], 1.2), (255, 250, 220), 0.7)
    return head_icon(d, (255, 215, 0))


def icon_lasthuman():
    def d(cv, P):
        r = np.hypot(cv.X - 32, cv.Y - 32)
        th = np.arctan2(cv.Y - 32, cv.X - 32)
        ring = np.clip(1 - np.abs(r - 26.5) / 3.0 * 1.0, 0, 1) ** 0.4 * (np.abs(r - 26.5) < 3.0)
        gaps = np.abs(((th / (np.pi / 2)) % 1) - 0.5) > 0.06  # 4 kucuk bosluk (0,90,180,270)
        ring = ring * gaps
        P(ring.astype(float), 'cyan', outline=1.4, sigma=0.6)
        for a in range(4):
            ang = a * np.pi / 2
            x0, y0 = 32 + 21 * np.cos(ang), 32 + 21 * np.sin(ang)
            x1, y1 = 32 + 29.5 * np.cos(ang), 32 + 29.5 * np.sin(ang)
            P(cv.line([(x0, y0), (x1, y1)], 2.6), 'cyan', outline=1.0, sigma=0.4)
        body = cv.ellipse(32, 51, 13.5, 12.5) * (r < 21.0)
        P(np.maximum(body, cv.circle(32, 26.5, 7.2)), 'white', outline=1.6, sigma=1.1)
    return head_icon(d, (0, 200, 255))


def icon_alpha():
    def d(cv, P):
        sp = cv.poly(star_pts(32, 32, 31, 23.5, 12, -np.pi / 2))
        P(sp, [(0, (40, 0, 0))] and 'red', outline=1.6, sigma=1.0, base=0.38, amp=0.35)
        P(cv.circle(32, 32, 20), [(0, 0, 0)] and 'dark', outline=1.2, sigma=1.5)
        bowl = np.clip(cv.ellipse(27.5, 34.5, 11.5, 10.5) - cv.ellipse(28.5, 34.5, 6.0, 5.4), 0, 1)
        tail = cv.line(bezier([(46.5, 19), (39.5, 30), (37, 41), (50, 48.5)], 30), 5.6)
        g = np.maximum(bowl, tail)
        P(g, 'green', outline=1.5, sigma=0.9)
    return head_icon(d, (120, 255, 40))


# ============================================================================
# EFEKTLER (ADDITIVE)
# ============================================================================
PAL = {
    'white': ramp([(0, (0, 0, 0)), (0.45, (96, 100, 108)), (0.8, (205, 210, 220)), (1, (255, 255, 255))]),
    'steel': ramp([(0, (0, 0, 0)), (0.3, (52, 46, 44)), (0.65, (138, 132, 128)), (0.88, (214, 210, 204)), (1, (255, 252, 246))]),
    'spore': ramp([(0, (0, 0, 0)), (0.3, (34, 46, 6)), (0.6, (120, 160, 30)), (0.85, (206, 240, 96)), (1, (250, 255, 210))]),
    'emp': ramp([(0, (0, 0, 0)), (0.3, (0, 24, 90)), (0.6, (20, 120, 255)), (0.85, (130, 220, 255)), (1, (255, 255, 255))]),
    'shock': ramp([(0, (0, 0, 0)), (0.4, (40, 70, 90)), (0.75, (150, 200, 225)), (1, (255, 255, 255))]),
    'heal': ramp([(0, (0, 0, 0)), (0.3, (0, 56, 18)), (0.6, (30, 190, 70)), (0.85, (150, 255, 160)), (1, (245, 255, 245))]),
    'gold': ramp([(0, (0, 0, 0)), (0.3, (70, 40, 0)), (0.6, (220, 150, 10)), (0.85, (255, 225, 90)), (1, (255, 255, 230))]),
    'infect': ramp([(0, (0, 0, 0)), (0.3, (70, 0, 4)), (0.6, (200, 12, 22)), (0.85, (255, 96, 70)), (1, (255, 225, 200))]),
    'ice': ramp([(0, (0, 0, 0)), (0.3, (0, 34, 80)), (0.6, (40, 150, 230)), (0.85, (170, 235, 255)), (1, (255, 255, 255))]),
    'void': ramp([(0, (0, 0, 0)), (0.3, (40, 0, 60)), (0.55, (150, 0, 170)), (0.8, (240, 40, 170)), (0.93, (255, 160, 220)), (1, (255, 245, 255))]),
    'toxic': ramp([(0, (0, 0, 0)), (0.3, (10, 50, 0)), (0.6, (70, 190, 0)), (0.85, (190, 255, 40)), (1, (250, 255, 200))]),
    'fire': ramp([(0, (0, 0, 0)), (0.22, (70, 6, 0)), (0.45, (190, 40, 0)), (0.65, (250, 110, 10)), (0.82, (255, 190, 50)), (1, (255, 252, 220))]),
}


def pgrid(n):
    y, x = np.mgrid[0:n, 0:n]
    c = (n - 1) / 2.0
    X, Y = (x - c) / (n / 2.0), (y - c) / (n / 2.0)
    return X, Y, np.hypot(X, Y), np.arctan2(Y, X)


def lines_img(n, segs, width, ss=4):
    """segs: [((x0,y0),(x1,y1), parlaklik)] normalize [-1,1]; AA cizgi yogunlugu."""
    im = np.zeros((n * ss, n * ss))
    from PIL import Image as _I, ImageDraw as _D
    for (a, b, v) in segs:
        L = _I.new('L', (n * ss, n * ss), 0)
        d = _D.Draw(L)
        P = [((p[0] + 1) * n / 2 * ss, (p[1] + 1) * n / 2 * ss) for p in (a, b)]
        d.line(P, fill=255, width=max(1, int(round(width * ss))))
        im = np.maximum(im, np.asarray(L, float) / 255 * v)
    return im.reshape(n, ss, n, ss).mean((1, 3))


def polyline_img(n, polys, width, ss=4):
    from PIL import Image as _I, ImageDraw as _D
    im = np.zeros((n * ss, n * ss))
    for pts, v in polys:
        L = _I.new('L', (n * ss, n * ss), 0)
        d = _D.Draw(L)
        P = [((p[0] + 1) * n / 2 * ss, (p[1] + 1) * n / 2 * ss) for p in pts]
        d.line(P, fill=255, width=max(1, int(round(width * ss))), joint='curve')
        im = np.maximum(im, np.asarray(L, float) / 255 * v)
    return im.reshape(n, ss, n, ss).mean((1, 3))


def glowify(img, sig, amt):
    return np.clip(img + ndimage.gaussian_filter(img, sig) * amt, 0, 1)


def fx(frames, pal, typ=VP_PARALLEL, gamma=1.0):
    fr = [to_index(np.clip(f, 0, 1) ** gamma) for f in frames]
    # kenar pikselleri sifir (bilinear sizinti / kare kenari cizgisi olmasin)
    for f in fr:
        f[0, :] = f[-1, :] = 0
        f[:, 0] = f[:, -1] = 0
    return fr, typ, PAL[pal], TF_ADDITIVE


def slash():
    n, N = 128, 6
    X, Y, _, _ = pgrid(n)
    frames = []
    for k in range(N):
        p = min(1.0, (k + 1) / 3.0)          # supurme ilerlemesi
        fade = [1, 1, 1, 0.8, 0.5, 0.22][k]
        img = np.zeros((n, n))
        for j, R in enumerate((1.1, 1.3, 1.5)):
            cx, cy = -0.7, 0.65
            r = np.hypot(X - cx, Y - cy)
            ang = np.arctan2(Y - cy, X - cx)
            a0, a1 = -1.5, 0.0
            s = (ang - a0) / (a1 - a0)
            lag = j * 0.06
            ps = np.clip(p - lag, 0, 1)
            w = 0.075 * np.sin(np.pi * np.clip(s, 0, 1)) ** 0.8 * (1.0 - 0.15 * j)
            core = np.exp(-((r - R) / np.maximum(w, 1e-3)) ** 2) * ((s >= 0) & (s <= ps))
            head = np.exp(-((s - ps) / 0.06) ** 2) * (k < 3)
            img = np.maximum(img, core * (0.75 + 0.5 * head))
        img = glowify(img, 3.0, 0.9) * fade
        if k >= 3:
            img = ndimage.gaussian_filter(img, 0.6 * (k - 2))
        frames.append(img)
    return fx(frames, 'white', gamma=0.9)


def chain():
    W, H, ss = 32, 64, 4
    yy, xx = np.mgrid[0:H * ss, 0:W * ss]
    X = (xx + 0.5) / ss - 16
    Y = (yy + 0.5) / ss
    img = np.zeros_like(X)
    # yuz-on halka (y=16) : yuvarlak dikdortgen halka kesiti
    for cy in (16.0, 16.0 + 64):
        for cyy in (cy, cy - 64):
            dx = np.maximum(np.abs(X) - 3.5, 0)
            dy = np.maximum(np.abs(Y - cyy) - 9.0, 0)
            d = np.hypot(dx, dy)  # merkez cizgisine uzaklik ~ halka yaricapi 6
            tube = np.clip(1 - ((d - 6.0) / 2.6) ** 2, 0, 1)
            img = np.maximum(img, np.sqrt(tube) * (0.55 + 0.45 * np.clip(-(X) / 10 + 0.5, 0, 1)))
    # yan (kenardan gorunen) halka (y=48): dar cubuk + uclari
    for cyy in (48.0, 48.0 - 64):
        d = np.hypot(X, np.maximum(np.abs(Y - cyy) - 13.5, 0))
        tube = np.clip(1 - (d / 4.2) ** 2, 0, 1)
        groove = 1 - 0.55 * np.exp(-(X / 0.9) ** 2) * (np.abs(Y - cyy) < 10.5)
        img = np.maximum(img, np.sqrt(tube) * 0.85 * groove * (0.75 + 0.25 * np.clip(-X / 4 + 0.5, 0, 1)))
    img = img.reshape(H, ss, W, ss).mean((1, 3))
    # parlama cizgisi
    img = np.clip(img * 1.05, 0, 1)
    fr = to_index(img)
    return [fr], VP_PARALLEL, PAL['steel'], TF_ADDITIVE


def web():
    n, N = 128, 6
    rng = np.random.default_rng(31)
    ns = 12
    angs = np.sort((np.arange(ns) + rng.uniform(-0.18, 0.18, ns)) * 2 * np.pi / ns)
    frames = []
    for k in range(N):
        g = [0.35, 0.65, 0.9, 1.0, 1.0, 1.0][k]
        segs = []
        for a in angs:
            segs.append(((0, 0), (0.95 * g * np.cos(a), 0.95 * g * np.sin(a)), 0.9))
        polys = []
        rad = 0.1
        i = 0
        while rad < 0.92 * g:
            pts = []
            for j in range(ns + 1):
                a0 = angs[j % ns] + (2 * np.pi if j == ns else 0)
                a1 = angs[(j + 1) % ns] + (2 * np.pi if j + 1 >= ns else 0)
                if j == ns:
                    break
                for t in np.linspace(0, 1, 6):
                    a = a0 + (a1 - a0) * t
                    rr = rad * (1 - 0.12 * np.sin(np.pi * t)) * (1 + 0.04 * np.sin(i * 1.7 + j))
                    pts.append((rr * np.cos(a), rr * np.sin(a)))
            polys.append((pts, 0.75))
            rad += 0.09 + 0.012 * i
            i += 1
        img = np.maximum(lines_img(n, segs, 1.1), polyline_img(n, polys, 0.9))
        # damla parlamalari
        img = glowify(img, 1.6, 0.6)
        X, Y, r, _ = pgrid(n)
        img *= np.clip(1.15 - r * 0.45, 0, 1)
        img *= [1, 1, 1, 1, 0.85, 0.65][k]
        img += np.exp(-(r / 0.08) ** 2) * 0.5
        frames.append(img)
    return fx(frames, 'white')


def spore():
    n, N = 64, 8
    rng = np.random.default_rng(5)
    X, Y, r, _ = pgrid(n)
    blobs = [(a + rng.uniform(-0.3, 0.3), rng.uniform(0.08, 0.3), rng.uniform(0.18, 0.28)) for a in np.linspace(0, 2 * np.pi, 9, endpoint=False)]
    parts = [(a + rng.uniform(-0.15, 0.15), rng.uniform(0.3, 0.9), rng.uniform(0.6, 1.0)) for a in np.linspace(0, 2 * np.pi, 26, endpoint=False)]
    frames = []
    for k in range(N):
        t = k / (N - 1)
        img = np.zeros((n, n))
        for a, d0, s in blobs:
            d = d0 + 0.45 * t
            bx, by = d * np.cos(a) * 0.9, d * np.sin(a) * 0.8 + 0.05 - 0.08 * t
            sz = s * (0.7 + 0.9 * t)
            img += np.exp(-((X - bx) ** 2 + (Y - by) ** 2) / sz ** 2) * 0.42
        img = img * (1 - t ** 1.6)
        for a, sp, b in parts:
            d = 0.1 + sp * 0.8 * t ** 0.7
            px, py = d * np.cos(a), d * np.sin(a) - 0.08 * t
            img += np.exp(-((X - px) ** 2 + (Y - py) ** 2) / 0.035 ** 2) * b * (1 - t) * 0.9
        frames.append(np.clip(img, 0, 1))
    return fx(frames, 'spore')


def bolt_path(rng, a, r0, r1, steps=9, jag=0.13):
    pts = []
    for i in range(steps + 1):
        f = i / steps
        rr = r0 + (r1 - r0) * f
        aa = a + (rng.uniform(-jag, jag) / max(rr, 0.15) if 0 < i < steps else 0)
        pts.append((rr * np.cos(aa), rr * np.sin(aa)))
    return pts


def emp():
    n, N = 128, 8
    rng = np.random.default_rng(17)
    X, Y, r, th = pgrid(n)
    ang_noise = fbm((64, 64), 3, base=0.3)
    frames = []
    for k in range(N):
        t = k / (N - 1)
        R = 0.12 + 0.8 * t ** 0.65
        mod = 0.6 + 0.8 * sample(ang_noise, th / (2 * np.pi) + 0.5, np.full_like(th, 0.1 + 0.11 * k))
        ring = np.exp(-((r - R) / (0.035 + 0.03 * t)) ** 2) * mod
        inner = np.clip(1 - r / R, 0, 1) ** 2 * 0.25 * (1 - t)
        polys = []
        for b in range(7):
            a = rng.uniform(0, 2 * np.pi)
            pts = bolt_path(rng, a, 0.05, R * rng.uniform(0.85, 1.05))
            polys.append((pts, 1.0))
            # dal
            j = rng.integers(3, 7)
            if j < len(pts):
                a2 = np.arctan2(pts[j][1], pts[j][0]) + rng.uniform(-0.6, 0.6)
                r2 = np.hypot(*pts[j])
                br = bolt_path(rng, a2, r2, min(R, r2 + 0.25), 4, 0.08)
                polys.append((br, 0.7))
        bolts = polyline_img(n, polys, 1.1 if k < 5 else 0.8) * (1 - 0.8 * t)
        core = np.exp(-(r / (0.18 * (1 - 0.7 * t) + 0.02)) ** 2) * (1 - t) ** 1.5
        img = ring + inner + glowify(bolts, 2.2, 1.2) + core
        img *= (1 - 0.6 * t ** 2)
        frames.append(glowify(np.clip(img, 0, 1), 3.0, 0.35))
    return fx(frames, 'emp')


def shock():
    n, N = 128, 6
    X, Y, r, th = pgrid(n)
    frames = []
    for k in range(N):
        t = k / (N - 1)
        R = 0.2 + 0.74 * t ** 0.7
        w = 0.05 + 0.05 * t
        ring = np.exp(-((r - R) / w) ** 2)
        lead = np.exp(-((r - R - w * 0.6) / (w * 0.35)) ** 2) * 0.6
        trail = np.clip(1 - (R - r) / (R * 0.55), 0, 1) * (r < R) * 0.28
        img = (ring + lead + trail) * (1 - t ** 1.5 * 0.85)
        frames.append(np.clip(img, 0, 1))
    return fx(frames, 'shock')


def plus_shape(X, Y, cx, cy, s, th=0.32):
    ax, ay = np.abs(X - cx) / s, np.abs(Y - cy) / s
    m = ((ax < th) & (ay < 1)) | ((ay < th) & (ax < 1))
    return m.astype(float)


def heal():
    n, N = 64, 8
    X, Y, r, _ = pgrid(n)
    rng = np.random.default_rng(9)
    crosses = [(-0.5, 0.45, 0.19, 0.0), (0.42, 0.6, 0.22, 0.12), (0.0, 0.35, 0.26, 0.28), (-0.38, 0.75, 0.15, 0.45), (0.5, 0.2, 0.15, 0.55)]
    dots = [(rng.uniform(-0.8, 0.8), rng.uniform(-0.2, 0.9), rng.uniform(0, 1)) for _ in range(14)]
    frames = []
    for k in range(N):
        t = k / (N - 1)
        img = np.exp(-(np.hypot(X, Y - 0.25) / 0.6) ** 2) * 0.35 * np.sin(np.pi * min(1, t * 1.4 + 0.15))
        for cx, cy, s, d in crosses:
            lt = (t - d) / 0.75
            if 0 <= lt <= 1:
                yy = cy - 0.9 * lt
                env = np.sin(np.pi * lt) ** 0.6
                m = ndimage.gaussian_filter(plus_shape(X, Y, cx, yy, s), 0.6)
                inner = ndimage.gaussian_filter(plus_shape(X, Y, cx, yy, s * 0.62, 0.22), 0.5)
                img = np.maximum(img, (m * 0.62 + inner * 0.38 + ndimage.gaussian_filter(m, 2.0) * 0.25) * env)
        for dx, dy, ph in dots:
            lt = (t + ph) % 1
            yy = dy - 1.0 * lt
            img += np.exp(-((X - dx) ** 2 + (Y - yy) ** 2) / 0.03 ** 2) * np.sin(np.pi * lt) * 0.9
        frames.append(np.clip(img, 0, 1))
    return fx(frames, 'heal')


def levelup():
    n, N = 128, 8
    X, Y, r, th = pgrid(n)
    rng = np.random.default_rng(23)
    sparks = [(rng.uniform(-0.7, 0.7), rng.uniform(0.0, 0.8), rng.uniform(0.4, 1.0), rng.uniform(0, 0.4)) for _ in range(22)]
    frames = []
    for k in range(N):
        t = k / (N - 1)
        rot = 0.25 * t
        rays = np.abs(np.cos(8 * (th + rot))) ** 30 * np.exp(-(r / (0.35 + 0.55 * t)) ** 2)
        rays2 = np.abs(np.cos(8 * (th - rot) + np.pi / 2)) ** 60 * np.exp(-(r / (0.3 + 0.35 * t)) ** 2) * 0.6
        R = 0.15 + 0.75 * t ** 0.6
        ring = np.exp(-((r - R) / 0.035) ** 2) * (1 - t) * 0.9
        star4 = np.exp(-((np.abs(X) * np.abs(Y)) / 0.0009)) * np.exp(-(r / 0.55) ** 2) * (1 - 0.5 * t)
        core = np.exp(-(r / 0.16) ** 2)
        img = (rays * 0.9 + rays2 + star4 * 0.8) * (1 - t ** 2) + ring + core * (1 - 0.6 * t)
        for sx, sy, sp, d in sparks:
            lt = (t - d) / (1 - d) if t >= d else -1
            if lt < 0:
                continue
            px, py = sx * (0.5 + 0.6 * lt), sy - 1.1 * lt * sp
            img += np.exp(-((X - px) ** 2 + (Y - py) ** 2) / 0.022 ** 2) * (1 - lt) * 1.0
        frames.append(glowify(np.clip(img, 0, 1), 2.0, 0.3))
    return fx(frames, 'gold')


def infect():
    n, N = 64, 8
    X, Y, r, th = pgrid(n)
    rng = np.random.default_rng(41)
    drops = [(rng.uniform(0, 2 * np.pi), rng.uniform(0.6, 1.1), rng.uniform(0.05, 0.1)) for _ in range(16)]
    frames = []
    for k in range(N):
        t = k / (N - 1)
        R = 0.22 + 0.28 * t ** 0.5
        spikes = 1 + 0.18 * np.maximum(np.cos(9 * th + 0.4 * k), 0) ** 6
        cell = np.exp(-((r / (R * spikes)) ** 6))
        membrane = np.exp(-((r - R * spikes) / 0.05) ** 2)
        nucleus = np.exp(-(np.hypot(X - 0.06, Y + 0.04) / (R * 0.45)) ** 2) * 0.4
        img = (cell * 0.35 + membrane * 0.9 + nucleus) * (1 - t ** 1.3)
        for a, sp, s in drops:
            d = 0.2 + sp * t ** 0.6
            px, py = d * np.cos(a), d * np.sin(a) + 0.25 * t ** 2
            img += np.exp(-((X - px) ** 2 + (Y - py) ** 2) / (s * (1 - 0.4 * t)) ** 2) * (1 - t) * 1.1
        frames.append(glowify(np.clip(img, 0, 1), 1.5, 0.4))
    return fx(frames, 'infect')


def shard_field(n, shards, grow_f, ss=2):
    """shards: [(aci, uzunluk, genislik, parlaklik)] merkezden cikan ucgen kristaller."""
    from PIL import Image as _I, ImageDraw as _D
    acc = np.zeros((n * ss, n * ss))
    for a, L, w, b in shards:
        L = L * grow_f
        if L < 0.02:
            continue
        ca, sa = np.cos(a), np.sin(a)
        base = 0.06
        tip = ((base + L) * ca, (base + L) * sa)
        p1 = (base * ca - w * sa, base * sa + w * ca)
        p2 = (base * ca + w * sa, base * sa - w * ca)
        mid = ((base + L * 0.35) * ca, (base + L * 0.35) * sa)
        for poly, v in (([p1, tip, mid], b), ([p2, tip, mid], b * 0.62)):
            Li = _I.new('L', (n * ss, n * ss), 0)
            P = [((p[0] + 1) * n / 2 * ss, (p[1] + 1) * n / 2 * ss) for p in poly]
            _D.Draw(Li).polygon(P, fill=255)
            acc = np.maximum(acc, np.asarray(Li, float) / 255 * v)
    return acc.reshape(n, ss, n, ss).mean((1, 3))


def ice():
    n, N = 128, 8
    rng = np.random.default_rng(13)
    X, Y, r, th = pgrid(n)
    shards = [(a + rng.uniform(-0.15, 0.15), rng.uniform(0.35, 0.85), rng.uniform(0.05, 0.11), rng.uniform(0.7, 1.0))
              for a in np.linspace(0, 2 * np.pi, 11, endpoint=False)]
    shards += [(rng.uniform(0, 2 * np.pi), rng.uniform(0.15, 0.35), rng.uniform(0.03, 0.06), 0.8) for _ in range(9)]
    mist = fbm((128, 128), 77, base=0.25)
    tw = [(rng.uniform(-0.7, 0.7), rng.uniform(-0.7, 0.7), rng.uniform(0, 1)) for _ in range(10)]
    frames = []
    for k in range(N):
        t = k / (N - 1)
        g = min(1.0, (k + 1) / 4.0) ** 0.7
        sh = shard_field(n, shards, g)
        edge = np.clip(sh - ndimage.gaussian_filter(sh, 1.0), 0, 1) * 2.0
        img = sh * 0.75 + edge
        img += np.clip(mist - 0.35, 0, 1) * np.exp(-(r / (0.5 + 0.4 * t)) ** 2) * 0.55
        img += np.exp(-(r / 0.14) ** 2) * (1 - t) * 0.8
        for sx, sy, ph in tw:
            v = np.sin(np.pi * ((t * 1.5 + ph) % 1))
            img += np.exp(-((np.abs(X - sx) * np.abs(Y - sy)) / 0.00025)) * np.exp(-(np.hypot(X - sx, Y - sy) / 0.07) ** 2) * v
        img *= 1 - 0.55 * max(0, t - 0.55) / 0.45
        frames.append(glowify(np.clip(img, 0, 1), 2.0, 0.35))
    return fx(frames, 'ice')


def void():
    n, N = 128, 10
    X, Y, r, th = pgrid(n)
    nz = fbm((128, 128), 101, base=0.2)
    frames = []
    for k in range(N):
        ph = k / N * 2 * np.pi / 3  # 3 kollu sarmal -> kusursuz dongu
        lr = np.log(np.maximum(r, 0.02) / 0.2)
        arms = (0.5 + 0.5 * np.cos(3 * (th - ph) + 4.6 * lr)) ** 1.8
        arms2 = (0.5 + 0.5 * np.cos(6 * (th - ph) + 7.0 * lr + 1.0)) ** 4 * 0.45
        tex = sample(nz, (th - ph) / (2 * np.pi) * 2, lr * 0.3)
        prof = np.exp(-((r - 0.4) / 0.32) ** 2)
        img = prof * (0.18 + 0.8 * arms + arms2) * (0.55 + 0.7 * tex)
        img += np.exp(-((r - 0.22) / 0.06) ** 2) * 0.35
        img += np.exp(-((r - 0.17) / 0.025) ** 2) * 1.0
        img *= smoothstep(0.1, 0.15, r)
        img *= np.clip(1.25 - r * 1.1, 0, 1)
        frames.append(glowify(np.clip(img, 0, 1), 2.0, 0.3))
    return fx(frames, 'void')


def toxic():
    n, N = 128, 8
    X, Y, r, th = pgrid(n)
    F = fbm((256, 256), 55, base=0.18, persist=0.6)
    G = fbm((256, 256), 56, base=0.08)
    rng = np.random.default_rng(57)
    bub = [(rng.uniform(-0.45, 0.45), rng.uniform(-0.3, 0.45), rng.uniform(0.03, 0.07), rng.uniform(0, 1)) for _ in range(8)]
    frames = []
    for k in range(N):
        t = k / (N - 1)
        R = 0.4 + 0.45 * t ** 0.6
        n1 = sample(F, X / R * 0.3 + 0.5, Y / R * 0.3 + 0.5 + 0.05 * t)
        n2 = sample(G, X * 0.6 + 0.3 * t, Y * 0.6 - 0.2 * t)
        edge = R * (0.75 + 0.5 * (n1 - 0.5))
        body = smoothstep(edge, edge - 0.25, r)
        img = body * (0.25 + 0.55 * n2 + 0.3 * n1) * (1 - 0.5 * t)
        for bx, by, s, ph in bub:
            lt = (t * 1.3 + ph) % 1
            yy = by - 0.3 * lt
            rb = np.hypot(X - bx, Y - yy)
            img += np.exp(-((rb - s) / 0.012) ** 2) * np.sin(np.pi * lt) * 0.45 * body
        img *= 1 - t ** 3
        frames.append(np.clip(img, 0, 1))
    return fx(frames, 'toxic')


def explosion(kind, n=128, N=12, seed=3):
    X, Y, r, th = pgrid(n)
    F = fbm((256, 256), seed, base=0.16, persist=0.6)
    G = fbm((256, 256), seed + 1, base=0.1, persist=0.5)
    rng = np.random.default_rng(seed + 2)
    sparks = [(rng.uniform(0, 2 * np.pi), rng.uniform(0.6, 1.0)) for _ in range(18)]
    shards = [(a + rng.uniform(-0.12, 0.12), rng.uniform(0.4, 0.8), rng.uniform(0.04, 0.08), 1.0)
              for a in np.linspace(0, 2 * np.pi, 9, endpoint=False)]
    frames = []
    for k in range(N):
        t = k / (N - 1)
        R = 0.2 + 0.7 * (1 - (1 - t) ** 2.4)
        if kind == 'void':
            # once ice coken halka, sonra patlama
            if t < 0.3:
                R = 0.75 - 1.6 * t
            else:
                R = 0.28 + 0.65 * (1 - (1 - (t - 0.3) / 0.7) ** 2.2)
        swirl = 0.0
        if kind == 'void':
            swirl = 2.2 * (1 - t) * np.exp(-r * 1.5)
        u = (X * np.cos(swirl) - Y * np.sin(swirl)) / R
        v = (X * np.sin(swirl) + Y * np.cos(swirl)) / R
        lump = 0.3 if kind != 'toxic' else 0.24
        # alan bukumu (domain warp) -> kabaran bulut kenarlari
        wx = sample(G, u * 0.25 + 0.1, v * 0.25 + 0.7 + 0.05 * t) - 0.5
        wy = sample(G, u * 0.25 + 0.6, v * 0.25 + 0.2 - 0.05 * t) - 0.5
        n1 = sample(F, u * lump + 0.5 + wx * 0.35, v * lump + 0.5 + wy * 0.35 + 0.04 * t)
        n2 = sample(G, u * 0.5 + 0.2 + 0.25 * t + wx * 0.2, v * 0.5 - 0.15 * t + wy * 0.2)
        edge = R * (0.9 + 0.7 * (n1 - 0.5) * (1.25 if kind == 'toxic' else 1.0))
        body = smoothstep(edge, edge - 0.18 * R - 0.04, r)
        heat = np.clip(1 - (r / (R + 1e-6)) * 0.8, 0, 1)
        hot = (1 - t) ** 1.3
        dens = body * np.clip(0.34 + 0.95 * (n1 - 0.4) + 0.45 * (n2 - 0.5), 0.1, 1.0)
        if kind == 'fire':
            img = dens * (0.36 + 0.85 * heat * hot + 0.2 * n1)
            img += np.exp(-(r / (0.42 * R + 0.04)) ** 2) * hot ** 1.6 * 0.65 * (0.6 + 0.6 * n1)
            hollow = 1 - (t ** 1.6) * np.exp(-(r / (R * 0.55)) ** 2) * 0.85
            img *= hollow * (1 - t ** 2.2 * 0.75)
        elif kind == 'toxic':
            img = dens * (0.35 + 0.6 * heat * (0.4 + 0.6 * hot) + 0.3 * n1)
            img += np.exp(-(r / 0.2) ** 2) * hot ** 3 * 0.9
            img *= 1 - t ** 2.0 * 0.8
            # kabarciklar
            for j, (a, sp) in enumerate(sparks[:7]):
                lt = (t * 1.6 + j * 0.37) % 1.0
                d = R * (0.15 + 0.55 * ((sp * 7.3) % 1.0))
                bx, by = d * np.cos(a * 3), d * np.sin(a * 3) - 0.25 * lt
                rb = np.hypot(X - bx, Y - by)
                s = 0.025 + 0.03 * lt
                img += np.exp(-((rb - s) / 0.011) ** 2) * np.sin(np.pi * lt) * 0.55 * body
        elif kind == 'ice':
            img = dens * (0.25 + 0.5 * heat * hot + 0.25 * n1) * 0.85
            g = min(1.0, (k + 1) / 3.5) ** 0.6
            sh = shard_field(n, shards, g * 1.1)
            edgeh = np.clip(sh - ndimage.gaussian_filter(sh, 1.0), 0, 1) * 2.0
            img = np.maximum(img, (sh * 0.7 + edgeh) * (1 - t ** 1.5))
            img += np.exp(-(r / 0.22) ** 2) * hot ** 2
            img *= 1 - t ** 2.2 * 0.7
        else:  # void
            rw = R * (1 + 0.08 * (n1 - 0.5))
            ring = np.exp(-((r - rw) / (0.045 + 0.04 * t)) ** 2) * (0.55 + 0.7 * n2)
            arms = (0.5 + 0.5 * np.cos(3 * th + 4.0 * np.log(np.maximum(r, 0.03) / 0.3) - 5 * t)) ** 3
            img = dens * (0.2 + 0.5 * n2 + 0.6 * arms) * 0.75 + ring
            img *= smoothstep(0.06 + 0.12 * (1 - abs(t - 0.3)), 0.2 + 0.1 * (1 - abs(t - 0.3)), r)
            if 0.25 <= t <= 0.45:
                img += np.exp(-(r / 0.12) ** 2) * 1.2
            img *= 1 - t ** 2.0 * 0.7
        # kivilcimlar (ilk kareler)
        if kind in ('fire', 'ice') and t < 0.6:
            segs = []
            for a, sp in sparks:
                d0 = R * 0.8 + 0.5 * sp * t
                d1 = d0 + 0.12 * (1 - t)
                segs.append(((d0 * np.cos(a), d0 * np.sin(a)), (d1 * np.cos(a), d1 * np.sin(a)), 1.0 - t / 0.6))
            img = np.maximum(img, lines_img(n, segs, 1.2, 2))
        if k == 0:
            img += np.exp(-(r / 0.3) ** 2) * 0.9
        img *= np.clip((0.98 - r) / 0.08, 0, 1)  # kare kenarinda kesik olmasin
        frames.append(glowify(np.clip(img, 0, 1), 2.0, 0.25))
    pal = {'fire': 'fire', 'ice': 'ice', 'toxic': 'toxic', 'void': 'void'}[kind]
    return fx(frames, pal, gamma=0.95)


# ============================================================================
SPRITES = {
    'bossbar': bossbar,
    'hpbar_small': hpbar_small,
    'bossicon': bossicon,
    'icon_vip': icon_vip,
    'icon_admin': icon_admin,
    'icon_mvp': icon_mvp,
    'icon_lasthuman': icon_lasthuman,
    'icon_alpha': icon_alpha,
    'slash': slash,
    'chain': chain,
    'web': web,
    'spore': spore,
    'emp': emp,
    'shock': shock,
    'heal': heal,
    'levelup': levelup,
    'infect': infect,
    'ice': ice,
    'void': void,
    'toxic': toxic,
    'explo_fire': lambda: explosion('fire', seed=3),
    'explo_ice': lambda: explosion('ice', seed=11),
    'explo_toxic': lambda: explosion('toxic', seed=21),
    'explo_void': lambda: explosion('void', seed=31),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    total = 0
    for name, fn in SPRITES.items():
        if ONLY and name not in ONLY:
            continue
        frames, typ, pal, fmt = fn()
        p = os.path.join(OUT, name + '.spr')
        write_spr(p, frames, typ, pal, fmt)
        s = read_spr(p)
        assert s['w'] % 8 == 0 and s['h'] % 8 == 0 and max(s['w'], s['h']) <= 256, name
        assert len(frames) == s['nf'] and all(np.array_equal(a, b) for a, b in zip(frames, s['frames'])), name
        if fmt == TF_ALPHTEST:
            assert tuple(s['pal'][255]) == (0, 0, 0), name
            for f in s['frames']:
                assert (f == 255).any() and (f != 255).any(), name  # hem saydam hem opak piksel
        else:
            assert all(f.max() > 0 for f in s['frames']) or name in ('spore', 'heal', 'infect', 'toxic'), name
        total += s['size']
        print('%-14s %3dx%-3d x%-3d %s/%s %7d B' % (name, s['w'], s['h'], s['nf'], TYPE_NAMES[typ], TF_NAMES[fmt], s['size']))
    print('toplam', total)
    assert total <= 2_500_000, 'boyut butcesi asildi'


if __name__ == '__main__':
    main()
