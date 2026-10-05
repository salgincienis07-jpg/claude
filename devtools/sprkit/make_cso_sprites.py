# Vexmira v3.4 - CSO tarzi EKRAN bildirim sprite'lari (killmark yontemi), ANIMASYONLU + yari saydam
#   python3 make_cso_sprites.py [cikti_koku]      (varsayilan: /home/user/claude/cstrike/sprites/vexmira/cso)
#
# Yontem (eklenti BOLUM 3 "CSO EKRAN BILDIRIMI"): oyuncunun elindeki silah icin WeaponList mesaji
# "vexmira/cso/<ad>" adiyla gonderilir; istemci sprites/vexmira/cso/<ad>.txt dosyasini yukler ve
# "crosshair / zoom" bolgesini ekranin TAM ORTASINA cizer (SPR_DrawHoles = ALPHTEST, tek kare).
#
# ANIMASYON: istemci nisangah sprite'ini tek kare cizer; bu yuzden her animasyon karesi ayri bir
# bolge + .txt betigidir ve eklenti kisa araliklarla (0.1 sn zamanlayici, sadece kare degisince)
# betigi degistirir. Kare dizisi:
#   a  giris cizgisi  (ortak, renksiz isik cizgisi + yildiz parlamasi)     -> fxa_<duzen>
#   b  giris parlamasi (ortak, genis isik patlamasi + halka + partikul)    -> fxb_<duzen>
#   g  kayan isik     (nota ozel: parlak kenar + capraz isik seridi + yildiz)  -> <ad>_g
#   m  ana kare       (nota ozel)                                         -> <ad>_m
#   (g / m nabiz gibi donusur)
#   c  cikis         (ortak, sonen cizgiler + dagilan partikul)           -> fxc_<duzen>
# Ardisik kareler HER ZAMAN farkli sprite sayfasindadir (m*, g*, fx1/fx2/fx3, rnd*): istemci ayni
# sayfanin baska bolgesine gecisi bazen yenilemez.
#
# YARI SAYDAMLIK: nisangah ALPHTEST cizilir (piksel ya tam opak ya yok). Yumusak parilti / saydam
# plaka "ordered dither" (8x8 Bayer) ile verilir: alfa 0.4 -> piksellerin ~%40'i. Siyah kutu yok.
#
# Duzenler (bolge boyutu; nisangah = bolge merkezi):
#   c  orta bant   256x40   (nisangaha ortali)
#   l  alt bant    256x80   (icerik alt 40 satir: nisangahin hemen altinda)
#   k  killmark    128x96   (icerik alt 46 satir)
#   r  round       128x40   (fx: orta bandin ortasi kirpilir)
import os, sys, glob
sys.dont_write_bytecode = True
import numpy as np
from PIL import ImageFont
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sprlib import *  # noqa

OUT = sys.argv[1] if len(sys.argv) > 1 else '/home/user/claude/cstrike/sprites/vexmira/cso'
PREV = os.environ.get('CSO_PREVIEW')  # dolu ise: tum karelerin PNG onizlemesi buraya
REL = 'vexmira/cso'
SS = 3
FONT = '/usr/share/fonts/truetype/liberation/LiberationSans-BoldItalic.ttf'
if not os.path.exists(FONT):
    FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'

ACC = {
    'cyan': (40, 225, 255), 'purple': (175, 105, 255), 'gold': (255, 196, 60),
    'red': (255, 60, 70), 'green': (110, 255, 70),
}
TEXT_GRAD = {
    'purple': [(0.0, (250, 242, 255)), (0.5, (214, 178, 255)), (1.0, (150, 84, 245))],
    'cyan': [(0.0, (240, 255, 255)), (0.5, (140, 240, 255)), (1.0, (10, 175, 235))],
    'gold': [(0.0, (255, 253, 232)), (0.5, (255, 222, 120)), (1.0, (232, 146, 24))],
    'red': [(0.0, (255, 240, 240)), (0.5, (255, 134, 124)), (1.0, (218, 26, 44))],
    'green': [(0.0, (244, 255, 238)), (0.5, (160, 255, 120)), (1.0, (46, 196, 36))],
}
VIOLET = (40, 14, 78)
INK = (12, 4, 26)
WHITE = (255, 255, 255)
GOLD = ACC['gold']

BAYER = np.array([[0, 32, 8, 40, 2, 34, 10, 42], [48, 16, 56, 24, 50, 18, 58, 26],
                  [12, 44, 4, 36, 14, 46, 6, 38], [60, 28, 52, 20, 62, 30, 54, 22],
                  [3, 35, 11, 43, 1, 33, 9, 41], [51, 19, 59, 27, 49, 17, 57, 25],
                  [15, 47, 7, 39, 13, 45, 5, 37], [63, 31, 55, 23, 61, 29, 53, 21]], float)
BAYER = (BAYER + 0.5) / 64.0


# ---------------------------------------------------------------------------
# yardimcilar
# ---------------------------------------------------------------------------
def blur(cv, m, r):
    return ndimage.gaussian_filter(m, r * cv.ss)


def glow(cv, m, r, col, k=1.0):
    g = blur(cv, m, r)
    mx = g.max()
    if mx > 1e-6:
        cv.paint(np.clip(g / mx * k, 0, 1), col)


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def text_mask(cv, text, cx, cy, size, maxw=None):
    s = cv.ss
    while True:
        f = ImageFont.truetype(FONT, int(size * s))
        bb = f.getbbox(text)
        w = (bb[2] - bb[0]) / s
        if maxw is None or w <= maxw or size <= 8:
            break
        size -= 1
    h = (bb[3] - bb[1]) / s
    x0 = cx - w / 2 - bb[0] / s
    y0 = cy - h / 2 - bb[1] / s
    m = cv.mask(lambda d, _: d.text((x0 * s, y0 * s), text, font=f, fill=255))
    return m, (cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2)


def paint_text(cv, text, cx, cy, size, grad, maxw=None, glowcol=None, shine=0.0, sweep_x=None):
    m, (x0, y0, x1, y1) = text_mask(cv, text, cx, cy, size, maxw)
    if glowcol is not None:
        glow(cv, m, 2.6, glowcol, 0.55 + 0.35 * shine)
    cv.paint(np.clip(grow(m, 1.1, cv.ss), 0, 1), INK, 0.92)
    t = np.clip((cv.Y - y0) / max(1.0, (y1 - y0)), 0, 1)
    cv.paint(m, grad_stops(t, TEXT_GRAD[grad]))
    hl = m * np.exp(-((cv.Y - (y0 + (y1 - y0) * 0.22)) / max(1.0, (y1 - y0) * 0.13)) ** 2) * 0.55
    cv.paint(hl, WHITE)
    if sweep_x is not None:
        # capraz kayan isik seridi (sadece harflerin ustunde)
        band = np.exp(-(((cv.X - sweep_x) + (cv.Y - cy) * 0.55) / 5.0) ** 2)
        cv.paint(m * band * 0.85, WHITE)
    return x0, y0, x1, y1


def star(cv, cx, cy, r, col=WHITE, k=1.0):
    """4 kollu yildiz parlamasi"""
    dx, dy = np.abs(cv.X - cx), np.abs(cv.Y - cy)
    arm = np.exp(-dy / (0.08 * r + 0.25)) * np.clip(1 - dx / r, 0, 1) ** 2
    arm += np.exp(-dx / (0.08 * r + 0.25)) * np.clip(1 - dy / (r * 0.7), 0, 1) ** 2
    core = np.exp(-((dx ** 2 + dy ** 2) / (0.18 * r) ** 2))
    cv.paint(np.clip((arm + core) * k, 0, 1), col)


def particles(cv, rng, x0, y0, x1, y1, n, cols, rmin=0.5, rmax=1.3, amin=0.45, amax=1.0, bias=None):
    for _ in range(n):
        if bias == 'ends':
            u = rng.beta(0.6, 0.6)
        else:
            u = rng.random()
        x = x0 + (x1 - x0) * u
        y = y0 + (y1 - y0) * rng.random()
        r = rng.uniform(rmin, rmax)
        c = cols[rng.integers(len(cols))]
        cv.paint(cv.circle(x, y, r), c, rng.uniform(amin, amax))


def blade(x0, y0, x1, y1, tip=12):
    """uclari sivri egik plaka (CSO bandi)"""
    ym = (y0 + y1) / 2
    return [(x0 + tip, y0), (x1 - tip * 0.4, y0), (x1, ym), (x1 - tip, y1), (x0 + tip * 0.4, y1), (x0, ym)]


def plate(cv, x0, y0, x1, y1, acc, shine=0.0, tip=12, alpha=0.62):
    """yari saydam koyu mor plaka: uclara dogru eriyen, neon ust/alt cizgi + parilti"""
    m = cv.poly(blade(x0, y0, x1, y1, tip))
    w = x1 - x0
    fadex = smooth(0, w * 0.22, cv.X - x0) * smooth(0, w * 0.22, x1 - cv.X)
    vy = np.clip((cv.Y - y0) / (y1 - y0), 0, 1)
    fill = grad_stops(vy, [(0, (70, 30, 128)), (0.45, VIOLET), (1, (18, 6, 40))])
    cv.paint(m * (0.35 + 0.65 * fadex), fill, alpha)
    # neon kenar: sadece ust ve alt, uclara dogru solar
    d = edt_in(m, cv.ss)
    edge = ((d > 0) & (d <= 1.2)).astype(float)
    horiz = np.exp(-((cv.X - (x0 + x1) / 2) / (w * (0.30 + 0.12 * shine))) ** 2)
    e = edge * np.clip(horiz * 1.4, 0, 1)
    glow(cv, e, 2.2 + shine, acc, 0.45 + 0.35 * shine)
    cv.paint(e, acc)
    cv.paint(e * np.clip(horiz * 1.6 - 0.6, 0, 1), WHITE, 0.6 + 0.4 * shine)
    # ic ince isik
    cv.paint(((d > 2.6) & (d <= 3.3)).astype(float) * horiz, acc, 0.35)
    return m


def chevrons(cv, cx, cy, side, acc, n=2, s=1.0):
    for k in range(n):
        x = cx + side * k * 6 * s
        pts = [(x, cy - 6 * s), (x + side * 4 * s, cy - 6 * s), (x + side * 10 * s, cy), (x + side * 4 * s, cy + 6 * s),
               (x, cy + 6 * s), (x + side * 6 * s, cy)]
        cv.paint(cv.poly(pts), acc, 0.95 - k * 0.35)


# ---------------------------------------------------------------------------
# simgeler (rozet ici / bant uclari)
# ---------------------------------------------------------------------------
def icon(cv, kind, cx, cy, r, acc, shine=0.0):
    """r ~ yaricap; acc vurgu rengi"""
    def solid(m, col, out=1.0):
        cv.paint(np.clip(grow(m, out, cv.ss), 0, 1), INK, 0.9)
        cv.paint(m, col)

    if kind == 'skull':
        head = cv.ellipse(cx, cy - r * 0.15, r * 0.82, r * 0.76)
        jaw = cv.rrect(cx - r * 0.46, cy + r * 0.3, cx + r * 0.46, cy + r * 0.8, r * 0.12)
        m = np.clip(head + jaw, 0, 1)
        vy = np.clip((cv.Y - (cy - r)) / (2 * r), 0, 1)
        solid(m, grad_stops(vy, [(0, (255, 255, 255)), (1, (190, 170, 230))]))
        for sx in (-1, 1):
            cv.paint(cv.ellipse(cx + sx * r * 0.32, cy - r * 0.1, r * 0.22, r * 0.25), INK)
            cv.paint(cv.circle(cx + sx * r * 0.32, cy - r * 0.1, r * 0.07), acc)
        cv.paint(cv.poly([(cx, cy + r * 0.12), (cx - r * 0.1, cy + r * 0.3), (cx + r * 0.1, cy + r * 0.3)]), INK)
        for k in (-1, 0, 1):
            cv.paint(cv.line([(cx + k * r * 0.18, cy + r * 0.45), (cx + k * r * 0.18, cy + r * 0.78)], max(0.8, r * 0.07)), INK)
    elif kind == 'crown':
        pts = [(cx - r, cy + r * 0.55), (cx - r, cy - r * 0.35), (cx - r * 0.5, cy + r * 0.05), (cx, cy - r * 0.75),
               (cx + r * 0.5, cy + r * 0.05), (cx + r, cy - r * 0.35), (cx + r, cy + r * 0.55)]
        m = cv.poly(pts)
        vy = np.clip((cv.Y - (cy - r)) / (2 * r), 0, 1)
        solid(m, grad_stops(vy, [(0, (255, 250, 210)), (0.5, (255, 205, 70)), (1, (190, 110, 10))]))
        cv.paint(cv.rrect(cx - r, cy + r * 0.35, cx + r, cy + r * 0.6, 1), (150, 80, 10))
        for x in (-1, 0, 1):
            cv.paint(cv.circle(cx + x * r * 0.55, cy + r * 0.45, r * 0.09), ACC['red'] if x == 0 else ACC['cyan'])
        for x, y in ((-r, -r * 0.35), (0, -r * 0.75), (r, -r * 0.35)):
            cv.paint(cv.circle(cx + x, cy + y, r * 0.13), (255, 245, 200))
    elif kind == 'warn':
        tri = cv.poly([(cx, cy - r), (cx + r * 1.05, cy + r * 0.8), (cx - r * 1.05, cy + r * 0.8)])
        solid(tri, grad_stops(np.clip((cv.Y - (cy - r)) / (1.8 * r), 0, 1), [(0, (255, 230, 120)), (1, (255, 150, 20))]))
        cv.paint(cv.line([(cx, cy - r * 0.35), (cx, cy + r * 0.25)], r * 0.22), INK)
        cv.paint(cv.circle(cx, cy + r * 0.52, r * 0.13), INK)
    elif kind == 'splat':
        rng = np.random.default_rng(int(cx * 7 + cy))
        m = cv.circle(cx, cy, r * 0.55)
        for _ in range(9):
            a = rng.uniform(0, 2 * np.pi)
            d = rng.uniform(0.45, 1.0) * r
            m = np.maximum(m, cv.circle(cx + np.cos(a) * d, cy + np.sin(a) * d, rng.uniform(0.12, 0.3) * r))
            m = np.maximum(m, cv.line([(cx, cy), (cx + np.cos(a) * d * 0.9, cy + np.sin(a) * d * 0.9)], r * 0.18))
        solid(m, grad_stops(np.clip((cv.Y - (cy - r)) / (2 * r), 0, 1), [(0, (200, 255, 150)), (1, (40, 170, 30))]))
        cv.paint(cv.circle(cx - r * 0.18, cy - r * 0.2, r * 0.14), WHITE, 0.8)
    elif kind == 'up':
        for k in range(2):
            y = cy + r * 0.45 - k * r * 0.75
            pts = [(cx - r * 0.9, y + r * 0.2), (cx, y - r * 0.6), (cx + r * 0.9, y + r * 0.2), (cx + r * 0.55, y + r * 0.45),
                   (cx, y - r * 0.05), (cx - r * 0.55, y + r * 0.45)]
            solid(cv.poly(pts), acc if k == 0 else (255, 255, 255))
    elif kind == 'clock':
        ring = np.clip(cv.circle(cx, cy, r) - cv.circle(cx, cy, r * 0.74), 0, 1)
        solid(ring, acc)
        cv.paint(cv.circle(cx, cy, r * 0.74), VIOLET, 0.7)
        cv.paint(cv.line([(cx, cy), (cx, cy - r * 0.55)], r * 0.14), WHITE)
        cv.paint(cv.line([(cx, cy), (cx + r * 0.4, cy + r * 0.12)], r * 0.14), WHITE)
        cv.paint(cv.rrect(cx - r * 0.25, cy - r * 1.35, cx + r * 0.25, cy - r * 1.05, 1), acc)
    elif kind == 'shield':
        pts = [(cx - r * 0.85, cy - r * 0.8), (cx, cy - r * 1.0), (cx + r * 0.85, cy - r * 0.8), (cx + r * 0.75, cy + r * 0.2),
               (cx, cy + r), (cx - r * 0.75, cy + r * 0.2)]
        m = cv.poly(pts)
        solid(m, grad_stops(np.clip((cv.X - (cx - r)) / (2 * r), 0, 1), [(0, (230, 255, 255)), (0.5, acc), (1, (10, 90, 150))]))
        cv.paint(cv.line([(cx, cy - r * 0.8), (cx, cy + r * 0.8)], r * 0.12), WHITE, 0.7)
    elif kind == 'blade':
        b = cv.poly([(cx - r, cy + r * 0.85), (cx + r * 0.75, cy - r * 0.95), (cx + r, cy - r), (cx + r * 0.9, cy - r * 0.7),
                     (cx - r * 0.8, cy + r)])
        solid(b, grad_stops(np.clip((cv.X - (cx - r)) / (2 * r), 0, 1), [(0, (150, 160, 200)), (1, (255, 255, 255))]))
        cv.paint(cv.line([(cx - r * 0.75, cy + r * 0.35), (cx - r * 0.3, cy + r * 0.8)], r * 0.2), GOLD)
    elif kind == 'drop':
        m = np.maximum(cv.circle(cx, cy + r * 0.3, r * 0.62),
                       cv.poly([(cx, cy - r), (cx + r * 0.55, cy + r * 0.05), (cx - r * 0.55, cy + r * 0.05)]))
        solid(m, grad_stops(np.clip((cv.Y - (cy - r)) / (2 * r), 0, 1), [(0, (255, 150, 150)), (1, (170, 0, 20))]))
        cv.paint(cv.ellipse(cx - r * 0.22, cy + r * 0.2, r * 0.12, r * 0.22), WHITE, 0.8)
    elif kind == 'claw':
        for k in (-1, 0, 1):
            cv.paint(cv.line([(cx - r * 0.7 + k * r * 0.45, cy - r), (cx + r * 0.2 + k * r * 0.45, cy + r)], r * 0.22), INK, 0.9)
            cv.paint(cv.line([(cx - r * 0.7 + k * r * 0.45, cy - r), (cx + r * 0.2 + k * r * 0.45, cy + r)], r * 0.12), acc)
    elif kind == 'grenade':
        body = cv.ellipse(cx, cy + r * 0.15, r * 0.6, r * 0.75)
        solid(body, grad_stops(np.clip((cv.Y - (cy - r)) / (2 * r), 0, 1), [(0, (170, 230, 130)), (1, (40, 90, 30))]))
        for k in (-1, 0, 1):
            cv.paint(cv.line([(cx - r * 0.55, cy + r * 0.15 + k * r * 0.3), (cx + r * 0.55, cy + r * 0.15 + k * r * 0.3)], 0.7), (30, 60, 20))
        cv.paint(cv.rrect(cx - r * 0.25, cy - r * 0.85, cx + r * 0.25, cy - r * 0.5, 1), (210, 210, 220))
        cv.paint(cv.line([(cx + r * 0.2, cy - r * 0.75), (cx + r * 0.6, cy - r * 0.25)], r * 0.12), (230, 230, 240))
    elif kind == 'target':
        ring = np.clip(cv.circle(cx, cy, r) - cv.circle(cx, cy, r * 0.8), 0, 1)
        solid(ring, acc)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            solid(cv.line([(cx + dx * r * 0.45, cy + dy * r * 0.45), (cx + dx * r * 1.25, cy + dy * r * 1.25)], r * 0.16), acc, 0.8)
        cv.paint(cv.circle(cx, cy, r * 0.16), WHITE)
    if shine > 0:
        star(cv, cx + r * 0.5, cy - r * 0.6, r * 1.3, WHITE, shine)


def hexbadge(cv, cx, cy, r, acc, shine=0.0):
    hexo = cv.poly([(cx + r * np.cos(a), cy + r * np.sin(a)) for a in np.radians(np.arange(30, 390, 60))])
    glow(cv, hexo, 3.5 + 1.5 * shine, acc, 0.45 + 0.35 * shine)
    vy = np.clip((cv.Y - (cy - r)) / (2 * r), 0, 1)
    cv.paint(hexo, grad_stops(vy, [(0, (90, 40, 160)), (1, (20, 6, 44))]), 0.7)
    d = edt_in(hexo, cv.ss)
    cv.paint(((d > 0) & (d <= 1.5)).astype(float), acc)
    cv.paint(((d > 0) & (d <= 0.8)).astype(float), WHITE, 0.35 + 0.5 * shine)
    cv.paint(((d > 3.0) & (d <= 3.6)).astype(float), acc, 0.45)


# ---------------------------------------------------------------------------
# icerik: bant (orta / alt), killmark, round
# ---------------------------------------------------------------------------
def banner(cv, ox, oy, w, h, sp, frame):
    """oy..oy+h: icerik kutusu (40-48 satir). frame: 'm' ana, 'g' kayan isik / nabiz"""
    g = frame == 'g'
    shine = 1.0 if g else 0.0
    acc = ACC[sp['col']]
    rng = np.random.default_rng(sum(map(ord, sp['name'])) + (7 if g else 0))
    cx, cy = ox + w / 2, oy + h / 2
    y0, y1 = oy + 5, oy + h - 4
    fx = sp.get('fx')
    # arka efektler (plakanin altinda)
    if fx == 'burst':  # seviye atlama: isik huzmesi patlamasi
        ang = np.arctan2(cv.Y - cy, (cv.X - cx) * 0.35)
        rays = (np.cos(ang * 14) * 0.5 + 0.5) ** 6
        rr = np.hypot((cv.X - cx) / (w * 0.5), (cv.Y - cy) / (h * 0.9))
        cv.paint(rays * np.clip(1 - rr, 0, 1) ** 1.2, acc, 0.55 + 0.35 * shine)
    if fx == 'splash':  # enfeksiyon: yesil sicrama damlalari
        r2 = np.random.default_rng(len(sp['name']))
        for _ in range(26):
            side = -1 if r2.random() < 0.5 else 1
            x = cx + side * r2.uniform(w * 0.18, w * 0.47)
            y = r2.uniform(y0 - 3, y1 + 3)
            cv.paint(cv.circle(x, y, r2.uniform(0.8, 2.6)), (90, 230, 50), r2.uniform(0.35, 0.8))
    m = plate(cv, ox + 6, y0, ox + w - 6, y1, acc, shine)
    if fx == 'hazard':  # boss: uyari serit cercevesi (plaka ici, uclarda)
        stripe = ((((cv.X - cv.Y) / 5.0) % 2) < 1).astype(float)
        zone = m * ((cv.X < ox + 46) | (cv.X > ox + w - 46)).astype(float) * (np.abs(cv.Y - cy) > (h / 2 - 11)).astype(float)
        cv.paint(zone * stripe, (255, 190, 30), 0.75)
        cv.paint(zone * (1 - stripe), (30, 0, 0), 0.6)
    # uc simgeleri / sevronlar
    ic = sp.get('icon')
    pad = 44 if ic else 30
    if ic:
        for side in (-1, 1):
            ix = cx + side * (w / 2 - 25)
            icon(cv, ic, ix, cy + 1, 8.5, acc, 0.0)
        if g:
            star(cv, cx - w / 2 + 29, cy - 6, 9, WHITE, 0.9)
    else:
        chevrons(cv, ox + 22, cy, 1, acc, 2)
        chevrons(cv, ox + w - 22, cy, -1, acc, 2)
    # partikuller (uclarda yogun)
    particles(cv, rng, ox + 8, y0 - 3, ox + w - 8, y1 + 3, 34 if g else 22, [acc, WHITE, (200, 170, 255)], bias='ends')
    # yazi
    sub = sp.get('sub')
    sweep = (ox + w * 0.70) if g else None
    if sub:
        paint_text(cv, sub, cx, y0 + 7, 8, 'gold', w - 2 * pad - 30)
        x0, ty0, x1, ty1 = paint_text(cv, sp['text'], cx, cy + 5, 19, sp['col'], w - 2 * pad, acc, shine, sweep)
    else:
        x0, ty0, x1, ty1 = paint_text(cv, sp['text'], cx, cy + 0.5, 22, sp['col'], w - 2 * pad, acc, shine, sweep)
    if g:
        # kayan isik: plaka ustunde capraz serit + yildiz
        band = np.exp(-(((cv.X - sweep) + (cv.Y - cy) * 0.55) / 9.0) ** 2)
        cv.paint(m * band * 0.35, WHITE)
        star(cv, sweep + 3, y0 + 1, 14, WHITE, 1.0)
        star(cv, x0 + 4, ty1 - 2, 7, (255, 240, 200), 0.8)


def killmark(cv, ox, oy, sp, frame):
    """oy..oy+46 icerik (bolgenin alt kismi)"""
    g = frame == 'g'
    shine = 1.0 if g else 0.0
    acc = ACC[sp['col']]
    cx, cy = ox + 64, oy + 23
    rng = np.random.default_rng(len(sp['name']) * 31 + (5 if g else 0))
    # yan kanat isik cizgileri
    for side in (-1, 1):
        for k in range(3):
            y = cy - 6 + k * 6
            x_a, x_b = cx + side * 25, cx + side * (52 - k * 7)
            ln = cv.line([(x_a, y), (x_b, y)], 1.2)
            fade = smooth(0, 1, 1 - np.abs(cv.X - x_a) / max(1, abs(x_b - x_a)))
            cv.paint(ln * fade, acc, 0.9 - k * 0.2)
            cv.paint(ln * fade, WHITE, (0.3 + 0.5 * shine) * (1 - k * 0.3))
    hexbadge(cv, cx, cy, 21, acc, shine)
    icon(cv, sp['icon'], cx, cy, 11, acc, 0.0)
    particles(cv, rng, cx - 56, cy - 20, cx + 56, cy + 20, 26 if g else 16, [acc, WHITE], bias='ends')
    if g:
        band = np.exp(-(((cv.X - (cx + 6)) + (cv.Y - cy) * 0.6) / 4.0) ** 2)
        hexo = cv.poly([(cx + 21 * np.cos(a), cy + 21 * np.sin(a)) for a in np.radians(np.arange(30, 390, 60))])
        cv.paint(hexo * band * 0.5, WHITE)
        star(cv, cx + 15, cy - 15, 15, WHITE, 1.0)


def round_cell(cv, ox, oy, n):
    w, h = 128, 40
    cx, cy = ox + w / 2, oy + h / 2
    plate(cv, ox + 4, oy + 5, ox + w - 4, oy + h - 4, ACC['cyan'], 0.0, tip=9)
    rng = np.random.default_rng(n)
    particles(cv, rng, ox + 6, oy + 2, ox + w - 6, oy + h - 2, 12, [ACC['cyan'], WHITE], bias='ends')
    paint_text(cv, 'ROUND', cx, oy + 11, 8, 'gold', 80)
    paint_text(cv, str(n), cx, cy + 4, 19, 'purple', 90, ACC['purple'])
    chevrons(cv, ox + 20, cy + 4, 1, ACC['cyan'], 2, 0.7)
    chevrons(cv, ox + w - 20, cy + 4, -1, ACC['cyan'], 2, 0.7)


# ortak giris / cikis kareleri (renksiz: beyaz-lavanta cekirdek, mor-camgobegi parilti)
def fx_cell(cv, ox, oy, w, h, kind, compact=False):
    cx, cy = ox + w / 2, oy + h / 2
    rng = np.random.default_rng({'a': 1, 'b': 2, 'c': 3}[kind] + (10 if compact else 0))
    if compact:  # killmark: halka
        if kind == 'a':
            ring = np.exp(-((np.hypot(cv.X - cx, cv.Y - cy) - 9) / 1.4) ** 2)
            cv.paint(ring, (190, 160, 255), 0.9)
            star(cv, cx, cy, 22, WHITE, 1.0)
        elif kind == 'b':
            rr = np.hypot(cv.X - cx, cv.Y - cy)
            cv.paint(np.exp(-((rr - 20) / 2.2) ** 2), ACC['cyan'], 0.9)
            cv.paint(np.exp(-((rr - 20) / 0.9) ** 2), WHITE, 0.9)
            cv.paint(np.exp(-(rr / 11) ** 2), (230, 210, 255), 0.75)
            ang = np.arctan2(cv.Y - cy, cv.X - cx)
            rays = (np.cos(ang * 8) * 0.5 + 0.5) ** 8 * np.clip(1 - rr / 40, 0, 1)
            cv.paint(rays, WHITE, 0.8)
            star(cv, cx, cy, 34, WHITE, 1.0)
            particles(cv, rng, cx - 40, cy - 20, cx + 40, cy + 20, 26, [ACC['cyan'], WHITE, (200, 160, 255)])
        else:
            rr = np.hypot(cv.X - cx, cv.Y - cy)
            ang = np.arctan2(cv.Y - cy, cv.X - cx)
            dots = (np.cos(ang * 18) > 0.3).astype(float)
            cv.paint(np.exp(-((rr - 22) / 1.3) ** 2) * dots, (190, 160, 255), 0.7)
            particles(cv, rng, cx - 50, cy - 18, cx + 50, cy + 18, 20, [ACC['cyan'], (200, 160, 255)], amin=0.3, amax=0.7)
        return
    if kind == 'a':  # ince isik cizgisi + yildiz
        core = np.exp(-((cv.Y - cy) / 0.9) ** 2) * np.exp(-((cv.X - cx) / (w * 0.22)) ** 2)
        cv.paint(np.clip(blur(cv, core, 2.5) * 3, 0, 1), (150, 110, 255), 0.8)
        cv.paint(core, WHITE)
        star(cv, cx, cy, 30, WHITE, 1.0)
        particles(cv, rng, cx - w * 0.25, cy - 4, cx + w * 0.25, cy + 4, 14, [ACC['cyan'], WHITE])
    elif kind == 'b':  # genis isik patlamasi
        bandy = np.exp(-((cv.Y - cy) / (h * 0.24)) ** 2) * np.exp(-((cv.X - cx) / (w * 0.42)) ** 4)
        cv.paint(bandy, (120, 70, 230), 0.55)
        cv.paint(np.exp(-((cv.Y - cy) / (h * 0.1)) ** 2) * np.exp(-((cv.X - cx) / (w * 0.38)) ** 4), (220, 200, 255), 0.7)
        cv.paint(np.exp(-((cv.Y - cy) / 0.9) ** 2) * np.exp(-((cv.X - cx) / (w * 0.48)) ** 6), WHITE)
        ell = np.hypot((cv.X - cx) / (w * 0.36), (cv.Y - cy) / (h * 0.42))
        cv.paint(np.exp(-((ell - 1) / 0.05) ** 2), ACC['cyan'], 0.85)
        star(cv, cx, cy, 44, WHITE, 1.0)
        particles(cv, rng, ox + 10, cy - h * 0.42, ox + w - 10, cy + h * 0.42, 50, [ACC['cyan'], WHITE, (200, 160, 255)])
    else:  # cikis: iki sonuk cizgi + dagilan partikul
        for yy in (cy - h * 0.36, cy + h * 0.36):
            ln = np.exp(-((cv.Y - yy) / 0.8) ** 2) * np.exp(-((cv.X - cx) / (w * 0.18)) ** 2)
            cv.paint(ln, (200, 170, 255), 0.75)
        cv.paint(np.exp(-((cv.Y - cy) / 0.7) ** 2) * np.exp(-((cv.X - cx) / (w * 0.08)) ** 2), WHITE, 0.8)
        particles(cv, rng, ox + 20, cy - h * 0.4, ox + w - 20, cy + h * 0.4, 40, [ACC['cyan'], (200, 160, 255), WHITE],
                  amin=0.25, amax=0.65, bias='ends')


# ---------------------------------------------------------------------------
# sayfa paketleme + yazma
# ---------------------------------------------------------------------------
def dither(rgb, a):
    h, w = a.shape
    thr = np.tile(BAYER, (h // 8 + 1, w // 8 + 1))[:h, :w]
    o = a > thr
    col = np.where(a[..., None] > 1e-6, rgb / np.maximum(a[..., None], 1e-6), 0)
    # cok saydam piksel parlak kalsin (dither seyrek nokta = isik tozu)
    return np.clip(col, 0, 255), o


def pow2(n):
    p = 8
    while p < n:
        p *= 2
    return p


class Sheet:
    """256 genislikte raf paketleyici (raflar yukseklige gore azalan sirada doldurulur)"""

    def __init__(self, name):
        self.name, self.items, self.x, self.y, self.rowh = name, [], 0, 0, 0

    def fits(self, w, h):
        if self.rowh and self.x + w <= 256 and h <= self.rowh:
            return True
        return self.y + self.rowh + h <= 256

    def add(self, w, h, draw, txts):
        if not (self.rowh and self.x + w <= 256 and h <= self.rowh):
            self.x, self.y, self.rowh = 0, self.y + self.rowh, h
        self.items.append((self.x, self.y, w, h, draw, txts))
        self.x += w


def write_txt(name, sheet, x, y, w, h):
    spr = '%s/%s' % (REL, sheet)
    lines = []
    for res in (320, 640):
        for k in ('crosshair', 'autoaim', 'zoom', 'zoom_autoaim'):
            lines.append('%s\t%d\t%s\t%d\t%d\t%d\t%d' % (k, res, spr, x, y, w, h))
        for k in ('weapon', 'weapon_s', 'ammo', 'ammo2'):
            lines.append('%s\t%d\t%s\t0\t0\t4\t4' % (k, res, spr))
    with open(os.path.join(OUT, name + '.txt'), 'w', newline='\r\n') as f:
        f.write('%d\n' % len(lines))
        for ln in lines:
            f.write(ln + '\n')


def render_sheet(sh):
    H = pow2(max(y + h for x, y, w, h, _, _ in sh.items))
    cv = Canvas(256, H, SS)
    for x, y, w, h, draw, txts in sh.items:
        draw(cv, x, y)
    rgb, a = cv.down()
    col, o = dither(rgb, a)
    o[0:4, 0:4] = False  # saydam kose (weapon/ammo girdileri)
    for x, y, w, h, draw, txts in sh.items:
        for (tn, dx, dy, tw, th) in txts:
            write_txt(tn, sh.name, x + dx, y + dy, tw, th)
    idx, pal = quantize_alphatest([col], [o])
    p = os.path.join(OUT, sh.name + '.spr')
    write_spr(p, idx, VP_PARALLEL, pal, TF_ALPHTEST)
    if PREV:
        from PIL import Image
        bg = np.zeros((H, 256, 3)) + np.array([60, 70, 80])
        yy, xx = np.mgrid[0:H, 0:256]
        bg[((yy // 16 + xx // 16) % 2) == 0] = (95, 105, 115)
        img = np.where(o[..., None], np.array(pal, float)[idx[0]], bg)
        Image.fromarray(img.astype(np.uint8)).resize((512, H * 2), Image.NEAREST).save(os.path.join(PREV, sh.name + '.png'))
    return os.path.getsize(p)


# ---------------------------------------------------------------------------
# icerik tablolari
# ---------------------------------------------------------------------------
def S(name, text, col, sub=None, icon=None, fx=None):
    return {'name': name, 'text': text, 'col': col, 'sub': sub, 'icon': icon, 'fx': fx}


# killmark (128x96 bolge, icerik alt 46 satir)
KM = [S('km1', '', 'cyan', icon='skull'), S('hs', '', 'red', icon='target'), S('nade', '', 'gold', icon='grenade')]
# alt bantlar (256x88, icerik alt 40 satir)
LOW = [
    S('km2', 'DOUBLE KILL', 'cyan', 'x2 COMBO', 'skull'),
    S('km3', 'TRIPLE KILL', 'purple', 'x3 COMBO', 'skull'),
    S('km4', 'MULTI KILL', 'gold', 'x4 COMBO', 'skull'),
    S('km5', 'MEGA KILL', 'red', 'x5 COMBO', 'skull'),
    S('last_en', 'LAST HUMAN', 'gold', 'STAND ALONE', 'shield'),
    S('last_tr', 'SON INSAN', 'gold', 'TEK BASINA', 'shield'),
    S('level_en', 'LEVEL UP', 'cyan', 'NEW RANK', 'up', 'burst'),
    S('level_tr', 'SEVIYE ATLADIN', 'cyan', 'YENI RUTBE', 'up', 'burst'),
    S('knife_en', 'KNIFE KILL', 'gold', 'HUMILIATION', 'blade'),
    S('knife_tr', 'BICAKLA OLDURDUN', 'gold', 'REZALET', 'blade'),
]
# orta bantlar (256x48)
MID = [
    S('mvp', 'M V P', 'gold', 'MOST VALUABLE PLAYER', 'crown', 'burst'),
    S('hwin_en', 'HUMANS WIN', 'cyan', 'ROUND CLEAR', 'shield'),
    S('hwin_tr', 'INSANLAR KAZANDI', 'cyan', 'ROUND TEMIZ', 'shield'),
    S('zwin_en', 'ZOMBIES WIN', 'red', 'OUTBREAK', 'claw'),
    S('zwin_tr', 'ZOMBILER KAZANDI', 'red', 'SALGIN', 'claw'),
    S('boss_en', 'BOSS INCOMING', 'red', 'WARNING', 'warn', 'hazard'),
    S('boss_tr', 'BOSS GELIYOR', 'red', 'DIKKAT', 'warn', 'hazard'),
    S('infect_en', 'INFECTION', 'green', 'ZOMBIE OUTBREAK', 'splat', 'splash'),
    S('infect_tr', 'ENFEKSIYON', 'green', 'ZOMBI SALGINI', 'splat', 'splash'),
    S('nemesis', 'NEMESIS', 'red', 'ROUND', 'skull'),
    S('assassin', 'ASSASSIN', 'purple', 'ROUND', 'blade'),
    S('survivor', 'SURVIVOR', 'cyan', 'ROUND', 'shield'),
    S('fb_en', 'FIRST BLOOD', 'red', 'ROUND', 'drop'),
    S('fb_tr', 'ILK KAN', 'red', 'ROUND', 'drop'),
    S('bkill_en', 'BOSS KILLED', 'gold', 'VICTORY', 'crown', 'burst'),
    S('bkill_tr', 'BOSS OLDURULDU', 'gold', 'ZAFER', 'crown', 'burst'),
    S('ten_en', '10 SECONDS LEFT', 'cyan', 'SURVIVE', 'clock'),
    S('ten_tr', 'SON 10 SANIYE', 'cyan', 'HAYATTA KAL', 'clock'),
    S('infd_en', 'INFECTED', 'green', 'YOU ARE A ZOMBIE', 'splat', 'splash'),
    S('infd_tr', 'ENFEKTE OLDUN', 'green', 'ARTIK ZOMBISIN', 'splat', 'splash'),
]
NROUNDS = 30


def pack(prefix, items):
    """items: (w, h, draw, txts) -> sayfalar prefix1, prefix2... (ilk uyan sayfaya, azalan yukseklik)"""
    sheets = []
    for it in sorted(items, key=lambda t: (-t[1], -t[0])):
        for sh in sheets:
            if sh.fits(it[0], it[1]):
                break
        else:
            sh = Sheet('%s%d' % (prefix, len(sheets) + 1))
            sheets.append(sh)
        sh.add(*it)
    return sheets


def main():
    os.makedirs(OUT, exist_ok=True)
    if PREV:
        os.makedirs(PREV, exist_ok=True)
    for f in glob.glob(os.path.join(OUT, '*.spr')) + glob.glob(os.path.join(OUT, '*.txt')):
        os.remove(f)
    groups = {'m': [], 'g': []}
    for fr in ('m', 'g'):
        for sp in MID:
            groups[fr].append((256, 40, lambda cv, x, y, sp=sp, fr=fr: banner(cv, x, y, 256, 40, sp, fr),
                               [('%s_%s' % (sp['name'], fr), 0, 0, 256, 40)]))
        for sp in LOW:
            groups[fr].append((256, 80, lambda cv, x, y, sp=sp, fr=fr: banner(cv, x, y + 40, 256, 40, sp, fr),
                               [('%s_%s' % (sp['name'], fr), 0, 0, 256, 80)]))
        for sp in KM:
            groups[fr].append((128, 96, lambda cv, x, y, sp=sp, fr=fr: killmark(cv, x, y + 50, sp, fr),
                               [('%s_%s' % (sp['name'], fr), 0, 0, 128, 96)]))
    # killmark giris kareleri ana sayfalarda: a -> g sayfasi, b -> m sayfasi (dizi a,b,g,m,g,m..,c hep sayfa degistirir)
    groups['g'].append((128, 96, lambda cv, x, y: fx_cell(cv, x, y + 50, 128, 46, 'a', True), [('fxa_k', 0, 0, 128, 96)]))
    groups['m'].append((128, 96, lambda cv, x, y: fx_cell(cv, x, y + 50, 128, 46, 'b', True), [('fxb_k', 0, 0, 128, 96)]))
    sheets = pack('m', groups['m']) + pack('g', groups['g'])
    # ortak kareler: fx1 = a (giris cizgisi) + killmark cikisi, fx2 = b (parlama) + c (cikis)
    fx1, fx2 = Sheet('fx1'), Sheet('fx2')
    for sh, kind in ((fx1, 'a'), (fx2, 'b'), (fx2, 'c')):
        sh.add(256, 80, lambda cv, x, y, k=kind: fx_cell(cv, x, y + 40, 256, 40, k), [('fx%s_l' % kind, 0, 0, 256, 80)])
        sh.add(256, 40, lambda cv, x, y, k=kind: fx_cell(cv, x, y, 256, 40, k),
               [('fx%s_c' % kind, 0, 0, 256, 40), ('fx%s_r' % kind, 64, 0, 128, 40)])
    fx1.add(128, 96, lambda cv, x, y: fx_cell(cv, x, y + 50, 128, 46, 'c', True), [('fxc_k', 0, 0, 128, 96)])
    sheets += [fx1, fx2]
    # round 1..30: 12 / sayfa (128x40)
    for si in range((NROUNDS + 11) // 12):
        sh = Sheet('rnd%d' % (si + 1))
        for j in range(12):
            n = si * 12 + j + 1
            if n > NROUNDS:
                break
            sh.add(128, 40, lambda cv, x, y, n=n: round_cell(cv, x, y, n), [('rnd%d' % n, 0, 0, 128, 40)])
        sheets.append(sh)
    total = 0
    for sh in sheets:
        total += render_sheet(sh)
    ntxt = len(glob.glob(os.path.join(OUT, '*.txt')))
    print('sayfa %d (%s), sprite toplam %d bytes, txt %d' % (len(sheets), ' '.join(s.name for s in sheets), total, ntxt))


if __name__ == '__main__':
    main()
