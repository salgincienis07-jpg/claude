# Vexmira v3.2 - CSO tarzi EKRAN bildirim sprite'lari (killmark yontemi) + HUD betikleri (.txt)
#   python3 make_cso_sprites.py [cikti_koku]      (varsayilan: /home/user/claude/cstrike/sprites/vexmira/cso)
#
# Yontem (eklenti BOLUM 3 "CSO EKRAN BILDIRIMI"): oyuncunun elindeki silah icin WeaponList mesaji
# "vexmira/cso/<ad>" adiyla gonderilir; istemci sprites/vexmira/cso/<ad>.txt dosyasini yukler ve
# "crosshair / autoaim / zoom / zoom_autoaim" girdisindeki bolgeyi ekranin TAM ORTASINA (nisangah
# noktasina ortali) cizer. Sure bitince orijinal WeaponList geri gonderilir.
#
# Tum sayfalar 256x256 ALPHTEST (indeks 255 saydam): nisangah SPR_DrawHoles ile cizilir.
# Bolge turleri:
#   * killmark  128x128 hucre: icerik alt 64 satirda -> nisangahin hemen ALTINDA gorunur
#   * alt bant  256x128 hucre: icerik alt 64 satirda -> nisangahin altinda (catisma aninda)
#   * orta bant 256x64  hucre: nisangaha ortali (round basi / sonu anlari)
#   * round     128x64  hucre: "ROUND" + buyuk sayi (1..30)
# Her betikte ayrica weapon / weapon_s / ammo / ammo2 girdileri saydam 4x4 koseyi gosterir
# (gosterim suresince silah secim / mermi ikonu bos gorunur, sayilar yerinde kalir).
import os, sys
sys.dont_write_bytecode = True
import numpy as np
from PIL import ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sprlib import *  # noqa

OUT = sys.argv[1] if len(sys.argv) > 1 else '/home/user/claude/cstrike/sprites/vexmira/cso'
REL = 'vexmira/cso'
SS = 4
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
if not os.path.exists(FONT):
    FONT = '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf'

PURPLE = (160, 90, 255)
CYAN = (0, 220, 255)
GOLD = (255, 200, 60)
DARK = (14, 6, 30)
TEXT_GRAD = {
    'purple': [(0.0, (245, 235, 255)), (0.45, (205, 165, 255)), (1.0, (140, 70, 240))],
    'cyan': [(0.0, (235, 255, 255)), (0.45, (120, 240, 255)), (1.0, (0, 170, 230))],
    'gold': [(0.0, (255, 252, 225)), (0.45, (255, 220, 110)), (1.0, (225, 140, 20))],
    'red': [(0.0, (255, 235, 235)), (0.45, (255, 120, 110)), (1.0, (210, 20, 40))],
    'green': [(0.0, (240, 255, 235)), (0.45, (150, 255, 110)), (1.0, (40, 190, 30))],
}


def text_mask(cv, text, cx, cy, size, maxw=None):
    """metni (cx,cy) ortali ciz; maxw asilirsa kucult. Donus: maske, (x0,y0,x1,y1)."""
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


def paint_text(cv, text, cx, cy, size, grad='purple', maxw=None, outline=2.0):
    m, (x0, y0, x1, y1) = text_mask(cv, text, cx, cy, size, maxw)
    cv.paint(np.clip(grow(m, outline, cv.ss), 0, 1), DARK)
    t = np.clip((cv.Y - y0) / max(1.0, (y1 - y0)), 0, 1)
    cv.paint(m, grad_stops(t, TEXT_GRAD[grad]))
    # ust parlama cizgisi
    hl = m * np.exp(-((cv.Y - (y0 + (y1 - y0) * 0.18)) / max(1.0, (y1 - y0) * 0.12)) ** 2) * 0.5
    cv.paint(hl, (255, 255, 255))


def plate(cv, x0, y0, x1, y1, accent=CYAN, slant=10):
    """CSO bandi: egik uclu koyu plaka, ust/alt camgobegi cizgi, uclarda altin vurgu."""
    pts = [(x0 + slant, y0), (x1, y0), (x1 - slant, y1), (x0, y1)]
    outer = cv.poly(pts)
    vy = np.clip((cv.Y - y0) / (y1 - y0), 0, 1)
    cv.paint(outer, grad_stops(vy, [(0, (52, 20, 96)), (0.5, (26, 10, 54)), (1, (12, 4, 28))]))
    d = edt_in(outer, cv.ss)
    cv.paint(((d > 0) & (d <= 1.6)).astype(float), accent)
    cv.paint(((d > 1.6) & (d <= 2.6)).astype(float), (40, 16, 80))
    # ic ince mor cizgi
    cv.paint(((d > 3.6) & (d <= 4.4)).astype(float), PURPLE, 0.55)
    # uclarda altin ucgen vurgu
    cv.paint(cv.poly([(x0 + slant + 2, y0 + 3), (x0 + slant + 16, y0 + 3), (x0 + slant + 6, y0 + 12)]), GOLD)
    cv.paint(cv.poly([(x1 - slant - 2, y1 - 3), (x1 - slant - 16, y1 - 3), (x1 - slant - 6, y1 - 12)]), GOLD)


def banner(cv, ox, oy, w, h, text, grad, accent=CYAN, sub=None):
    plate(cv, ox + 4, oy + 6, ox + w - 4, oy + h - 6, accent)
    if sub:
        paint_text(cv, sub, ox + w / 2, oy + 15, 9, 'gold', w - 60, 1.2)
        paint_text(cv, text, ox + w / 2, oy + h / 2 + 6, 22, grad, w - 44)
    else:
        paint_text(cv, text, ox + w / 2, oy + h / 2, 25, grad, w - 44)


def skull(cv, cx, cy, r, col=(240, 236, 255)):
    head = cv.ellipse(cx, cy - r * 0.15, r, r * 0.92)
    jaw = cv.rrect(cx - r * 0.55, cy + r * 0.45, cx + r * 0.55, cy + r * 1.0, r * 0.15)
    m = np.clip(head + jaw, 0, 1)
    cv.paint(np.clip(grow(m, 1.6, cv.ss), 0, 1), DARK)
    vy = np.clip((cv.Y - (cy - r)) / (2 * r), 0, 1)
    cv.paint(m, grad_stops(vy, [(0, (255, 255, 255)), (1, (175, 150, 220))]))
    for sx in (-1, 1):
        cv.paint(cv.ellipse(cx + sx * r * 0.38, cy - r * 0.05, r * 0.26, r * 0.3), (40, 0, 60))
    cv.paint(cv.poly([(cx, cy + r * 0.2), (cx - r * 0.12, cy + r * 0.42), (cx + r * 0.12, cy + r * 0.42)]), (40, 0, 60))
    for k in (-1, 0, 1):
        cv.paint(cv.line([(cx + k * r * 0.2, cy + r * 0.58), (cx + k * r * 0.2, cy + r * 0.95)], max(1.0, r * 0.07)), (40, 0, 60))


def badge(cv, cx, cy, r, ring=CYAN):
    """altigen rozet: altin kenar + mor ic"""
    hexo = cv.poly([(cx + r * np.cos(a), cy + r * np.sin(a)) for a in np.radians(np.arange(30, 390, 60))])
    d = edt_in(hexo, cv.ss)
    cv.paint(np.clip(grow(hexo, 1.5, cv.ss), 0, 1), DARK)
    sh = bevel(hexo, cv.ss, 1.5)
    cv.paint(hexo, grad_stops(np.clip(0.55 + 0.45 * sh, 0, 1), [(0, (110, 70, 10)), (0.6, (230, 175, 60)), (1, (255, 245, 200))]))
    inner = (d > 3.2).astype(float)
    vy = np.clip((cv.Y - (cy - r)) / (2 * r), 0, 1)
    cv.paint(inner, grad_stops(vy, [(0, (120, 60, 220)), (1, (34, 10, 70))]))
    cv.paint(((d > 3.2) & (d <= 4.2)).astype(float), ring)


def wings(cv, cx, cy, r, n, col=CYAN):
    """rozetin iki yaninda n kat kanat seridi (seri gostergesi)"""
    for side in (-1, 1):
        for k in range(n):
            x0 = cx + side * (r + 3 + k * 7)
            pts = [(x0, cy - 9 + k), (x0 + side * 5, cy - 9 + k), (x0 + side * 9, cy), (x0 + side * 5, cy + 9 - k), (x0, cy + 9 - k), (x0 + side * 4, cy)]
            m = cv.poly(pts)
            cv.paint(np.clip(grow(m, 1.0, cv.ss), 0, 1), DARK)
            c = GOLD if k == n - 1 and n >= 3 else col
            cv.paint(m, c)


def killmark(cv, ox, oy, kind):
    cx, cy = ox + 64, oy + 64 + 30  # icerik alt yarida
    if kind.startswith('km'):
        n = int(kind[2:])
        ring = [CYAN, CYAN, PURPLE, GOLD, (255, 70, 70)][n - 1]
        if n >= 2:
            wings(cv, cx, cy, 24, n - 1, CYAN if n < 5 else (255, 90, 90))
        badge(cv, cx, cy, 24, ring)
        skull(cv, cx, cy - 1, 11)
        if n > 1:
            # sayi rozetin sag altinda
            paint_text(cv, str(n), cx + 17, cy + 15, 13, 'gold', None, 1.6)
    elif kind == 'hs':
        badge(cv, cx, cy, 25, (255, 60, 60))
        skull(cv, cx, cy - 1, 11)
        ring_m = np.clip(cv.circle(cx, cy - 2, 15) - cv.circle(cx, cy - 2, 12.8), 0, 1)
        cv.paint(ring_m, (255, 50, 50))
        for a in range(4):
            dx, dy = [(1, 0), (-1, 0), (0, 1), (0, -1)][a]
            cv.paint(cv.line([(cx + dx * 11, cy - 2 + dy * 11), (cx + dx * 19, cy - 2 + dy * 19)], 2.0), (255, 50, 50))
        wings(cv, cx, cy, 25, 2, (255, 90, 90))
    elif kind == 'knife':
        badge(cv, cx, cy, 25, GOLD)
        blade = cv.poly([(cx - 15, cy + 13), (cx + 12, cy - 15), (cx + 16, cy - 17), (cx + 14, cy - 11), (cx - 12, cy + 16)])
        cv.paint(np.clip(grow(blade, 1.2, cv.ss), 0, 1), DARK)
        cv.paint(blade, grad_stops(np.clip((cv.X - (cx - 15)) / 32, 0, 1), [(0, (160, 170, 200)), (1, (255, 255, 255))]))
        cv.paint(cv.line([(cx - 12, cy + 8), (cx - 6, cy + 14)], 3.0), GOLD)
        cv.paint(cv.line([(cx - 13, cy + 15), (cx - 17, cy + 19)], 3.4), (90, 50, 20))
        wings(cv, cx, cy, 25, 2, GOLD)
    elif kind == 'nade':
        badge(cv, cx, cy, 25, (255, 140, 30))
        body = cv.ellipse(cx, cy + 3, 10, 12)
        cv.paint(np.clip(grow(body, 1.2, cv.ss), 0, 1), DARK)
        cv.paint(body, grad_stops(np.clip((cv.Y - (cy - 9)) / 24, 0, 1), [(0, (150, 220, 120)), (1, (40, 90, 30))]))
        for k in (-1, 0, 1):
            cv.paint(cv.line([(cx - 9, cy + 3 + k * 5), (cx + 9, cy + 3 + k * 5)], 0.8), (30, 60, 20))
        cv.paint(cv.rrect(cx - 4, cy - 13, cx + 4, cy - 8, 1.0), (200, 200, 210))
        cv.paint(cv.line([(cx + 3, cy - 12), (cx + 10, cy - 4)], 2.0), (220, 220, 230))
        cv.paint(cv.circle(cx - 6, cy - 14, 3.0) - cv.circle(cx - 6, cy - 14, 1.6), GOLD)
        wings(cv, cx, cy, 25, 2, (255, 150, 40))


def round_cell(cv, ox, oy, n):
    plate(cv, ox + 3, oy + 4, ox + 125, oy + 60, CYAN, 8)
    paint_text(cv, 'ROUND', ox + 64, oy + 16, 9, 'gold', 90, 1.2)
    paint_text(cv, str(n), ox + 64, oy + 38, 24, 'purple', 100, 2.0)


def to_sheet(cv):
    rgb, a = cv.down()
    col, o = finalize_rgba(rgb, a, 0.5)
    # kenarlar sert (ALPHTEST): tam saydam koseler korunur
    return col, o


TXT = {}  # ad -> (sayfa, x, y, w, h)


def save_sheet(name, cv):
    col, o = to_sheet(cv)
    o[0:4, 0:4] = False  # saydam kose (weapon/ammo girdileri icin)
    idx, pal = quantize_alphatest([col], [o])
    p = os.path.join(OUT, name + '.spr')
    write_spr(p, idx, VP_PARALLEL, pal, TF_ALPHTEST)
    return os.path.getsize(p)


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


# ---------------------------------------------------------------------------
# icerik tablolari
# ---------------------------------------------------------------------------
KILLMARKS = ['km1', 'hs', 'nade']  # tek sayfa (km1.spr)
# v3.3: COMBO (2..5 oldurme pencere icinde) = buyuk yazili alt bant. Ardisik seviyeler FARKLI
# sayfada (cmb1 / cmb2): istemci ayni sayfanin baska bolgesine gecmeyi bazen yenilemez.
COMBO = [('km2', 'DOUBLE KILL', 'cyan', CYAN, 2), ('km3', 'TRIPLE KILL', 'purple', PURPLE, 3),
         ('km4', 'MULTI KILL', 'gold', GOLD, 4), ('km5', 'MEGA KILL', 'red', (255, 70, 70), 5)]
# orta bantlar: (dosya adi, metin, renk, vurgu, ust kucuk yazi)
MID = [
    ('mvp', 'M V P', 'gold', GOLD, 'MOST VALUABLE PLAYER'),
    ('hwin_en', 'HUMANS WIN', 'cyan', CYAN, None),
    ('hwin_tr', 'INSANLAR KAZANDI', 'cyan', CYAN, None),
    ('zwin_en', 'ZOMBIES WIN', 'red', (255, 60, 60), None),
    ('zwin_tr', 'ZOMBILER KAZANDI', 'red', (255, 60, 60), None),
    ('boss_en', 'BOSS INCOMING', 'red', GOLD, 'WARNING'),
    ('boss_tr', 'BOSS GELIYOR', 'red', GOLD, 'DIKKAT'),
    ('infect_en', 'INFECTION', 'green', (120, 255, 60), 'ZOMBIE OUTBREAK'),
    ('infect_tr', 'ENFEKSIYON', 'green', (120, 255, 60), 'ZOMBI SALGINI'),
    ('nemesis', 'NEMESIS', 'red', (255, 60, 60), 'ROUND'),
    ('assassin', 'ASSASSIN', 'purple', PURPLE, 'ROUND'),
    ('survivor', 'SURVIVOR', 'cyan', CYAN, 'ROUND'),
]
LOW = [
    ('last_en', 'LAST HUMAN', 'gold', GOLD, None),
    ('last_tr', 'SON INSAN', 'gold', GOLD, None),
    ('level_en', 'LEVEL UP', 'cyan', CYAN, None),
    ('level_tr', 'SEVIYE ATLADIN', 'cyan', CYAN, None),
    # v3.3: zombiye bicakla oldurme (killmark sinifi, nisangah alti)
    ('knife_en', 'KNIFE KILL', 'gold', GOLD, 'HUMILIATION'),
    ('knife_tr', 'BICAKLA OLDURDUN', 'gold', GOLD, 'REZALET'),
]
# v3.3: ek orta bantlar (vex_cso_notes 128)
MID2 = [
    ('fb_en', 'FIRST BLOOD', 'red', (255, 60, 60), 'ROUND'),
    ('fb_tr', 'ILK KAN', 'red', (255, 60, 60), 'ROUND'),
    ('bkill_en', 'BOSS KILLED', 'gold', GOLD, 'VICTORY'),
    ('bkill_tr', 'BOSS OLDURULDU', 'gold', GOLD, 'ZAFER'),
    ('ten_en', '10 SECONDS LEFT', 'cyan', CYAN, 'SURVIVE'),
    ('ten_tr', 'SON 10 SANIYE', 'cyan', CYAN, 'HAYATTA KAL'),
    ('infd_en', 'INFECTED', 'green', (120, 255, 60), 'YOU ARE A ZOMBIE'),
    ('infd_tr', 'ENFEKTE OLDUN', 'green', (120, 255, 60), 'ARTIK ZOMBISIN'),
]
NROUNDS = 30


def main():
    os.makedirs(OUT, exist_ok=True)
    total = 0
    # killmark: 1 sayfa x 3 hucre (128x128)
    cv = Canvas(256, 256, SS)
    for j, k in enumerate(KILLMARKS):
        ox, oy = (j % 2) * 128, (j // 2) * 128
        killmark(cv, ox, oy, k)
        write_txt(k, 'km1', ox, oy, 128, 128)
    total += save_sheet('km1', cv)
    # combo: 2 sayfa x 2 (256x128, icerik alt 64); km2/km4 -> cmb1, km3/km5 -> cmb2
    for si in range(2):
        cv = Canvas(256, 256, SS)
        for j in range(2):
            name, text, grad, acc, n = COMBO[j * 2 + si]
            oy = j * 128
            banner(cv, 0, oy + 64, 256, 64, text, grad, acc, 'x%d COMBO' % n)
            write_txt(name, 'cmb%d' % (si + 1), 0, oy, 256, 128)
        total += save_sheet('cmb%d' % (si + 1), cv)
    # v3.3 ek orta bantlar: 2 sayfa x 4 (256x64)
    for si in range(2):
        cv = Canvas(256, 256, SS)
        for j in range(4):
            name, text, grad, acc, sub = MID2[si * 4 + j]
            oy = j * 64
            banner(cv, 0, oy, 256, 64, text, grad, acc, sub)
            write_txt(name, 'mid%d' % (si + 4), 0, oy, 256, 64)
        total += save_sheet('mid%d' % (si + 4), cv)
    # orta bantlar: 3 sayfa x 4 (256x64)
    for si in range(3):
        cv = Canvas(256, 256, SS)
        for j in range(4):
            name, text, grad, acc, sub = MID[si * 4 + j]
            oy = j * 64
            banner(cv, 0, oy, 256, 64, text, grad, acc, sub)
            write_txt(name, 'mid%d' % (si + 1), 0, oy, 256, 64)
        total += save_sheet('mid%d' % (si + 1), cv)
    # alt bantlar: 3 sayfa x 2 (256x128, icerik alt 64)
    for si in range(3):
        cv = Canvas(256, 256, SS)
        for j in range(2):
            name, text, grad, acc, sub = LOW[si * 2 + j]
            oy = j * 128
            banner(cv, 0, oy + 64, 256, 64, text, grad, acc, sub)
            write_txt(name, 'low%d' % (si + 1), 0, oy, 256, 128)
        total += save_sheet('low%d' % (si + 1), cv)
    # round 1..30: 4 sayfa x 8 (128x64)
    for si in range((NROUNDS + 7) // 8):
        cv = Canvas(256, 256, SS)
        for j in range(8):
            n = si * 8 + j + 1
            if n > NROUNDS:
                break
            ox, oy = (j % 2) * 128, (j // 2) * 64
            round_cell(cv, ox, oy, n)
            write_txt('rnd%d' % n, 'rnd%d' % (si + 1), ox, oy, 128, 64)
        total += save_sheet('rnd%d' % (si + 1), cv)
    print('sprite toplam %d bytes, txt %d' % (total, len([f for f in os.listdir(OUT) if f.endswith('.txt')])))


if __name__ == '__main__':
    main()
