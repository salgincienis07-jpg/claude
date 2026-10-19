"""Vexmira 5.3.8 HUD / notification sprite set (one calm theme, anti-aliased, no dithering).

    cd devtools/sprkit && python3 make_c538.py [--preview /path/preview.png]

Out: cstrike/sprites/vexmira/c538/
  crosshair-trick cards (CS client draws the zoom/crosshair region centred on screen, ALPHTEST, 1:1 pixels)
    <card>_<tr|en>.txt  -> region of sheet k<tr|en><n>.spr (256x512 sheets, cells packed: fewer files)
      big 256x128  : zwin hwin mvp boss last infect nemesis assassin survivor bkill fb level round upgrade
      kill 256x128 : km1..km5 hs knife nade infd item          (content below the crosshair, rows 74-118)
      cd 128x128   : cd1..cd10                                  (round start countdown)
      ar 256x128   : ar1..ar10                                  (boss arena teleport countdown)
    bh_<0..10>.txt -> sbh<n>.spr  boss HP bar high on screen (128x512 cell, bar at the top, crosshair in the centre)
    hm_hit.txt hm_hs.txt hm_kill.txt -> shm.spr  hitmarker crosshair cards (64x64)
  world sprites (env_sprite / TE)
    hp538.spr      128x16  ALPHTEST  frames 0..50 = 0..100 % (2 % steps), 51..61 = damage flash 0,10..100 %
    bossbar538.spr 256x32  ALPHTEST  frames 0..25 = 0..100 % (4 % steps), 26..36 = damage flash 0,10..100 %
    icons538.spr   64x64   ALPHTEST  overhead badges (frame map in ICONS)
    hit538.spr     32x32   ADDITIVE  0 hit, 1 headshot, 2 kill
"""
import argparse
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import glyphs538 as G  # noqa: E402
from hud538 import (ACC, FONT_B, FONT_N, FONT_R, PANEL_BOT, RIM, TEXT, TEXT_SUB, Canvas, write_additive,  # noqa: E402
                    write_alphatest, write_hud_txt)

OUT = os.path.abspath(os.path.join(HERE, '..', '..', 'cstrike', 'sprites', 'vexmira', 'c538t'))
REL = 'vexmira/c538t'


def dim(c, k):
    return tuple(int(v * k) for v in c)


def lite(c, k=0.45):
    return tuple(int(v + (255 - v) * k) for v in c)


# ------------------------------------------------------------------------------------------------- cards
#            family    glyph            TR title / sub                                   EN title / sub
BIG = {
    'zwin': ('zombie', G.biohazard, ('ZOMBİLER KAZANDI', 'Enfeksiyon bütün şehri sardı'), ('ZOMBIES WIN', 'The infection took the city')),
    'hwin': ('human', G.shield, ('İNSANLAR KAZANDI', 'Hayatta kalanlar direndi'), ('HUMANS WIN', 'The survivors held the line')),
    'mvp': ('gold', G.trophy, ('TURUN YILDIZI', 'MVP - en iyi oyuncu'), ('ROUND MVP', 'Most valuable player')),
    'boss': ('boss', G.horns_skull, ('BOSS SAVAŞI', 'Hep birlikte meydanda savaşın'), ('BOSS BATTLE', 'Fight together in the arena')),
    'last': ('orange', G.person, ('SON İNSAN', 'Hayatta kal, pes etme'), ('LAST HUMAN', 'Stay alive, never give up')),
    'infect': ('zombie', G.biohazard, ('ENFEKSİYON', 'Salgın başladı'), ('INFECTION', 'The outbreak has begun')),
    'nemesis': ('boss', G.horns_skull, ('NEMESİS', 'Av başladı'), ('NEMESIS', 'The hunt begins')),
    'assassin': ('violet', G.dagger, ('SUİKASTÇI', 'Karanlığa dikkat et'), ('ASSASSIN', 'Watch the dark')),
    'survivor': ('human', G.shield, ('KURTULAN', 'İnsanlığın son umudu'), ('SURVIVOR', "Humanity's last hope")),
    'bkill': ('gold', G.skull, ('BOSS YENİLDİ', 'Ödüller dağıtıldı'), ('BOSS DEFEATED', 'Rewards handed out')),
    'fb': ('boss', G.crosshair, ('İLK KAN', 'Turun ilk eleme'), ('FIRST BLOOD', 'First kill of the round')),
    'level': ('gold', G.star, ('SEVİYE ATLADIN', 'Yeni ödüller açıldı'), ('LEVEL UP', 'New rewards unlocked')),
    'round': ('teal', G.clock, ('YENİ TUR', 'Hazırlan, savaş başlıyor'), ('NEW ROUND', 'Get ready to fight')),
    'upgrade': ('violet', G.chevrons, ('SINIF GELİŞTİ', 'Yetenek gücü arttı'), ('CLASS UPGRADED', 'Your skill got stronger')),
}
KILL = {
    'km1': ('boss', 1, ('ELEME', 'KILL')), 'km2': ('boss', 2, ('ÇİFT ELEME', 'DOUBLE KILL')),
    'km3': ('boss', 3, ('ÜÇLÜ ELEME', 'TRIPLE KILL')), 'km4': ('orange', 4, ('ÇOKLU ELEME', 'MULTI KILL')),
    'km5': ('gold', 5, ('KATLİAM', 'DOMINATING')),
    'hs': ('boss', G.crosshair, ('KAFADAN', 'HEADSHOT')), 'knife': ('white', G.knife, ('BIÇAKLA', 'KNIFE KILL')),
    'nade': ('orange', G.grenade, ('BOMBAYLA', 'GRENADE KILL')), 'infd': ('zombie', G.biohazard, ('ENFEKTE ETTİN', 'INFECTED')),
    'item': ('teal', G.crate, ('İKMAL ALINDI', 'SUPPLY PICKED UP')),
}


def card_big(name, lang):
    fam, glyph, tr, en = BIG[name]
    acc = ACC[fam]
    title, sub = tr if lang == 'tr' else en
    cv = Canvas(256, 80)
    cv.panel(8, 6, 248, 74, r=9, accent=acc)
    # badge
    cx, cy = 40, 40
    b = cv.ellipse(cx, cy, 21)
    cv.paint(cv.grow(b, 1), RIM)
    cv.paint(b, cv.vgrad(dim(acc, 0.42), dim(acc, 0.22), cy - 21, cy + 21))
    cv.paint(cv.ring(cx, cy, 20.2, 1.6), acc)
    g = glyph(cv, cx, cy, 12.5)
    cv.label(g, lite(acc, 0.55), rim=False, shadow=True)
    # text
    t = cv.text(title, FONT_B, 22, 72, 33, maxw=166, anchor='lm')
    cv.label(t, TEXT)
    s = cv.text(sub, FONT_N, 10.5, 72, 56, maxw=166, anchor='lm')
    cv.label(s, TEXT_SUB, rim=False, shadow=False)
    w = cv.text('VEXMIRA', FONT_R, 6.5, 238, 15, anchor='rm')
    cv.paint(w, dim(acc, 0.85))
    return cv.result()


def card_kill(name, lang):
    fam, ic, txt = KILL[name]
    acc = ACC[fam]
    text = txt[0] if lang == 'tr' else txt[1]
    cv = Canvas(256, 112)
    cv.panel(40, 64, 216, 106, r=9, accent=acc, stripe='bottom')
    if isinstance(ic, int):
        n = ic
        for i in range(n):
            x = 128 + (i - (n - 1) / 2) * 18
            m = G.skull(cv, x, 76, 7.2)
            cv.label(m, lite(acc, 0.4) if i == n - 1 else (226, 229, 234), rim=True, shadow=False)
        t = cv.text(text, FONT_B, 14, 128, 95, maxw=160)
    else:
        b = cv.ellipse(62, 85, 14)
        cv.paint(b, cv.vgrad(dim(acc, 0.45), dim(acc, 0.22), 71, 99))
        cv.paint(cv.ring(62, 85, 13.4, 1.4), acc)
        m = ic(cv, 62, 85, 8.6)
        cv.label(m, lite(acc, 0.55), rim=False, shadow=True)
        t = cv.text(text, FONT_B, 15, 141, 86, maxw=126)
    cv.label(t, TEXT)
    return cv.result()


def ring_number(cv, cx, cy, n, acc, r=27):
    cv.paint(cv.ring(cx, cy, r, 4.2), (40, 44, 52))
    arc = cv.arc(cx, cy, r + 2.1, 4.2, 0, 360 * n / 10.0)
    cv.paint(arc, acc)
    t = cv.text(str(n), FONT_B, 30, cx, cy + 1)
    cv.label(t, TEXT)


def card_cd(n, lang):
    acc = ACC['teal'] if n > 3 else ACC['boss']
    cv = Canvas(128, 128)
    cv.panel(10, 8, 118, 120, r=12, accent=acc, stripe='top')
    t = cv.text('TUR BAŞLIYOR' if lang == 'tr' else 'ROUND STARTS', FONT_R, 8.5, 64, 22, maxw=96)
    cv.label(t, TEXT_SUB, rim=False, shadow=False)
    ring_number(cv, 64, 67, n, acc)
    t = cv.text('SANİYE' if lang == 'tr' else 'SECONDS', FONT_R, 7.5, 64, 109, maxw=96)
    cv.paint(t, dim(acc, 0.9))
    return cv.result()


def card_ar(n, lang):
    acc = ACC['boss']
    cv = Canvas(256, 80)
    cv.panel(8, 6, 248, 74, r=9, accent=acc)
    cv.paint(cv.ring(44, 40, 24, 3.6), (40, 44, 52))
    cv.paint(cv.arc(44, 40, 25.8, 3.6, 0, 360 * n / 10.0), acc)
    t = cv.text(str(n), FONT_B, 25, 44, 41)
    cv.label(t, TEXT)
    t = cv.text('BOSS ARENASI' if lang == 'tr' else 'BOSS ARENA', FONT_B, 19, 80, 30, maxw=158, anchor='lm')
    cv.label(t, TEXT)
    s = ('%d saniye sonra ışınlanacaksın' % n) if lang == 'tr' else ('Teleport in %d second%s' % (n, '' if n == 1 else 's'))
    t = cv.text(s, FONT_N, 10.5, 80, 54, maxw=158, anchor='lm')
    cv.label(t, lite(acc, 0.55), rim=False, shadow=False)
    return cv.result()


def small_crosshair(cv, cx, cy, col=(120, 240, 170)):
    for dx, dy, w, h in ((-9, 0, 6, 1.4), (9, 0, 6, 1.4), (0, -9, 1.4, 6), (0, 9, 1.4, 6)):
        m = cv.rrect(cx + dx - w / 2, cy + dy - h / 2, cx + dx + w / 2, cy + dy + h / 2, 0.3)
        cv.paint(cv.grow(m, 0.6), RIM, 0.8)
        cv.paint(m, col)


def card_bh(level):
    """128x512: boss bar panel at the top (rows 18-62), crosshair in the centre (the card replaces it)."""
    acc = ACC['boss']
    cv = Canvas(128, 512)
    cv.panel(3, 18, 125, 62, r=7, accent=None)
    m = G.horns_skull(cv, 15, 31, 6.0)
    cv.label(m, lite(acc, 0.35), rim=True, shadow=False)
    t = cv.text('BOSS', FONT_B, 10.5, 25, 31, anchor='lm')
    cv.label(t, TEXT)
    t = cv.text('%d%%' % (level * 10), FONT_B, 10.5, 119, 31, anchor='rm')
    cv.label(t, lite(acc, 0.5))
    x0, x1, y0, y1 = 9, 119, 42, 54
    trough = cv.rrect(x0, y0, x1, y1, 3)
    cv.paint(cv.grow(trough, 0.8), RIM)
    cv.paint(trough, cv.vgrad((26, 12, 14), (40, 18, 20), y0, y1))
    if level > 0:
        fx = x0 + (x1 - x0) * level / 10.0
        fill = cv.rrect(x0, y0, max(fx, x0 + 6), y1, 3)
        cv.paint(fill, cv.vgrad(lite(acc, 0.35), dim(acc, 0.62), y0, y1))
        cv.paint(fill * (cv.Y < y0 + 3.5), (255, 255, 255), 0.22)
    for k in range(1, 10):
        xx = x0 + (x1 - x0) * k / 10.0
        cv.paint(cv.rrect(xx - 0.5, y0 + 1, xx + 0.5, y1 - 1, 0.1) * trough, RIM, 0.55)
    small_crosshair(cv, 64, 256)
    return cv.result()


def card_hm(kind):
    cv = Canvas(64, 64)
    col = {'hit': (240, 242, 246), 'hs': (240, 70, 60), 'kill': (240, 70, 60)}[kind]
    m = G.target_x(cv, 32, 32, 14 if kind != 'kill' else 16, gap=0.42, w=0.15 if kind == 'hit' else 0.2)
    cv.paint(cv.grow(m, 0.8), RIM, 0.9)
    cv.paint(m, col)
    if kind == 'hs':
        r = cv.ring(32, 32, 19, 1.6)
        cv.paint(cv.grow(r, 0.6), RIM, 0.8)
        cv.paint(r, col)
    if kind == 'kill':
        s = G.skull(cv, 32, 32, 5)
        cv.paint(cv.grow(s, 0.6), RIM)
        cv.paint(s, (235, 235, 240))
    small_crosshair(cv, 32, 32)
    return cv.result()


# ------------------------------------------------------------------------------------------------- world sprites
def hp_color(f):
    stops = [(0.0, (214, 64, 54)), (0.3, (222, 128, 52)), (0.55, (220, 192, 70)), (0.8, (120, 200, 90)), (1.0, (84, 196, 120))]
    for (a, ca), (b, cb) in zip(stops, stops[1:]):
        if f <= b:
            t = (f - a) / (b - a)
            return tuple(int(ca[i] + (cb[i] - ca[i]) * t) for i in range(3))
    return stops[-1][1]


def bar_frame(w, h, f, flash=False, col=None, skull=False):
    cv = Canvas(w, h)
    col = col or hp_color(f)
    x0 = 2 + (h if skull else 0)
    x1, y0, y1 = w - 2, 2, h - 2
    shell = cv.rrect(x0 - 1, y0 - 1, x1 + 1, y1 + 1, (y1 - y0) / 2 + 1)
    cv.paint(shell, (250, 250, 250) if flash else RIM)
    trough = cv.rrect(x0, y0, x1, y1, (y1 - y0) / 2)
    cv.paint(trough, cv.vgrad((24, 27, 33), (38, 42, 50), y0, y1))
    if f > 0:
        fx = x0 + (x1 - x0) * f
        fill = cv.rrect(x0, y0, max(fx, x0 + (y1 - y0)), y1, (y1 - y0) / 2) * trough
        c = lite(col, 0.55) if flash else col
        cv.paint(fill, cv.vgrad(lite(c, 0.35), dim(c, 0.7), y0, y1))
        cv.paint(fill * (cv.Y < y0 + (y1 - y0) * 0.32), (255, 255, 255), 0.25)
    n = 10
    for k in range(1, n):
        xx = x0 + (x1 - x0) * k / n
        cv.paint(cv.rrect(xx - 0.4, y0 + 1, xx + 0.4, y1 - 1, 0.1) * trough, (0, 0, 0), 0.45)
    if skull:
        s = G.horns_skull(cv, h / 2 + 1, h / 2, h * 0.36)
        cv.paint(cv.grow(s, 0.8), RIM)
        cv.paint(s, (250, 250, 250) if flash else lite(ACC['boss'], 0.4))
    return cv.result()


ICONS = [   # frame, key, family, glyph, label
    ('admin', 'gold', G.vex, 'ADMIN'), ('vip', 'violet', G.diamond, 'VIP'), ('last', 'orange', G.person, None),
    ('mvp', 'gold', G.trophy, 'MVP'), ('alpha', 'zombie', G.biohazard, None), ('nemesis', 'boss', G.horns_skull, None),
    ('assassin', 'violet', G.dagger, None), ('survivor', 'human', G.shield, None), ('boss', 'boss', G.crown, None),
    ('sniper', 'human', G.crosshair, None), ('medic', 'zombie', G.plus, None), ('owner', 'boss', G.vex, 'OWNER'),
    # boss types (bossicon order: brute banshee overlord inferno reaper frostlord stormcaller hivequeen void)
    ('b_brute', 'boss', G.fist, None), ('b_banshee', 'violet', G.waves, None), ('b_overlord', 'gold', G.eye, None),
    ('b_inferno', 'orange', G.flame, None), ('b_reaper', 'white', G.scythe, None), ('b_frostlord', 'human', G.snowflake, None),
    ('b_stormcaller', 'teal', G.bolt, None), ('b_hivequeen', 'gold', G.hexbee, None), ('b_void', 'violet', G.swirl, None),
]


def icon(fam, glyph, label):
    acc = ACC[fam]
    cv = Canvas(64, 64)
    cy = 27 if label else 32
    pts = [(32 + 23 * np.cos(np.radians(90 + 60 * k)), cy + 23 * np.sin(np.radians(90 + 60 * k))) for k in range(6)]
    hexm = cv.poly([(x, y) for x, y in pts])
    cv.paint(cv.grow(hexm, 1.4), RIM)
    cv.paint(hexm, cv.vgrad(dim(acc, 0.55), dim(acc, 0.24), cy - 23, cy + 23))
    inner = cv.poly([(32 + (x - 32) * 0.86, cy + (y - cy) * 0.86) for x, y in pts])
    cv.paint(np.clip(hexm - inner, 0, 1), lite(acc, 0.3))
    g = glyph(cv, 32, cy, 12.5)
    cv.paint(cv.grow(g, 0.8), RIM, 0.8)
    cv.paint(g, cv.vgrad((255, 255, 255), lite(acc, 0.55), cy - 12, cy + 12))
    if label:
        rb = cv.rrect(6, 47, 58, 61, 4)
        cv.paint(cv.grow(rb, 1), RIM)
        cv.paint(rb, cv.vgrad(dim(acc, 0.9), dim(acc, 0.55), 47, 61))
        t = cv.text(label, FONT_B, 10, 32, 54.5, maxw=48)
        cv.paint(np.roll(t, 2, 0), (0, 0, 0), 0.5)
        cv.paint(t, (255, 255, 255))
    return cv.result()


def hit_frame(kind):
    cv = Canvas(32, 32)
    col = {'hit': (255, 255, 255), 'hs': (255, 70, 50), 'kill': (255, 40, 30)}[kind]
    m = G.target_x(cv, 16, 16, 13, gap=0.38, w=0.16 if kind == 'hit' else 0.21)
    cv.paint(cv.blur(m, 1.2), col, 0.45)
    cv.paint(m, col)
    if kind == 'hs':
        cv.paint(cv.ring(16, 16, 10, 1.3), col, 0.9)
    return cv.result()


# ------------------------------------------------------------------------------------------------- packing
class Packer:
    """shelf packer into 256x512 sheets (cells keep their size; offsets go into the .txt)."""

    def __init__(self, prefix):
        self.prefix = prefix
        self.sheets = []           # list of list of (name, x, y, rgb, a)

    def add(self, name, rgb, a):
        h, w = a.shape
        for sh in self.sheets:
            pos = self._fit(sh, w, h)
            if pos:
                sh.append((name, pos[0], pos[1], rgb, a))
                return
        self.sheets.append([(name, 0, 0, rgb, a)])

    @staticmethod
    def _fit(sh, w, h):
        for y in range(0, 512 - h + 1, 8):
            for x in range(0, 256 - w + 1, 64):
                if all(x + w <= ox or ox + ow <= x or y + h <= oy or oy + oh <= y
                       for _, ox, oy, r, a2 in sh for oh, ow in [a2.shape]):
                    return x, y
        return None

    def write(self, previews):
        files = []
        for i, sh in enumerate(self.sheets):
            need = max(y + a.shape[0] for _, x, y, r, a in sh)
            H = next(v for v in (64, 128, 256, 512) if v >= need)
            rgb = np.zeros((H, 256, 3))
            al = np.zeros((H, 256))
            for name, x, y, r, a in sh:
                h, w = a.shape
                rgb[y:y + h, x:x + w] = r
                al[y:y + h, x:x + w] = a
                # 1 px transparent frame per cell (GL bilinear bleeding between cells)
                al[y, x:x + w] = al[y + h - 1, x:x + w] = 0
                al[y:y + h, x] = al[y:y + h, x + w - 1] = 0
            sheet = '%s%d' % (self.prefix, i)
            imgs, _ = write_alphatest(os.path.join(OUT, sheet + '.spr'), [(rgb, al)])
            files.append(sheet + '.spr')
            for name, x, y, r, a in sh:
                h, w = a.shape
                write_hud_txt(os.path.join(OUT, name + '.txt'), '%s/%s' % (REL, sheet), x, y, w, h)
                previews[name] = imgs[0][y:y + h, x:x + w]
                files.append(name + '.txt')
        return files


# ------------------------------------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--preview')
    args = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        os.remove(os.path.join(OUT, f))
    previews = {}
    report = {'cards': {}, 'world': {}}
    for lang in ('tr', 'en'):
        pk = Packer('k%s' % lang)
        for c in KILL:
            pk.add('%s_%s' % (c, lang), *card_kill(c, lang))
        for c in BIG:
            pk.add('%s_%s' % (c, lang), *card_big(c, lang))
        for n in range(1, 11):
            pk.add('cd%d_%s' % (n, lang), *card_cd(n, lang))
        for n in range(1, 11):
            pk.add('ar%d_%s' % (n, lang), *card_ar(n, lang))
        report['cards'][lang] = pk.write(previews)
    # boss HP (two 128x512 cells per sheet)
    pk = Packer('sbh')
    for lv in range(11):
        pk.add('bh_%d' % lv, *card_bh(lv))
    report['cards']['bh'] = pk.write(previews)
    pk = Packer('shm')
    for k in ('hit', 'hs', 'kill'):
        pk.add('hm_%s' % k, *card_hm(k))
    report['cards']['hm'] = pk.write(previews)
    # world sprites
    fr = [bar_frame(128, 16, i / 50.0) for i in range(51)] + [bar_frame(128, 16, i / 10.0, flash=True) for i in range(11)]
    imgs, _ = write_alphatest(os.path.join(OUT, 'hp538.spr'), fr)
    previews['hp538'] = imgs
    fr = [bar_frame(256, 32, i / 25.0, col=ACC['boss'], skull=True) for i in range(26)] + \
         [bar_frame(256, 32, i / 10.0, flash=True, col=ACC['boss'], skull=True) for i in range(11)]
    imgs, _ = write_alphatest(os.path.join(OUT, 'bossbar538.spr'), fr)
    previews['bossbar538'] = imgs
    fr = [icon(fam, g, lab) for _, fam, g, lab in ICONS]
    imgs, _ = write_alphatest(os.path.join(OUT, 'icons538.spr'), fr)
    previews['icons538'] = imgs
    report['world']['icons538'] = {k: i for i, (k, *_r) in enumerate(ICONS)}
    imgs = write_additive(os.path.join(OUT, 'hit538.spr'), [hit_frame(k) for k in ('hit', 'hs', 'kill')])
    previews['hit538'] = imgs
    files = sorted(os.listdir(OUT))
    tot = sum(os.path.getsize(os.path.join(OUT, f)) for f in files)
    print('%d files, %d KB' % (len(files), tot // 1024))
    with open(os.path.join(HERE, 'c538_layout.json'), 'w') as f:
        json.dump(report, f, indent=1)
    if args.preview:
        make_preview(previews, args.preview)


def _bg(h, w):
    yy, xx = np.mgrid[0:h, 0:w]
    g = np.zeros((h, w, 3))
    g[:] = (96, 104, 92)                                # mid-tone "map" background (sand/stone)
    g[((yy // 24 + xx // 24) % 2) == 0] = (132, 124, 104)
    return g


def _tile(img):
    h, w = img.shape[:2]
    bg = _bg(h, w)
    m = img.sum(-1) > 0
    return np.where(m[..., None], img, bg)


def make_preview(pv, path):
    rows = []

    def row(names, scale=1):
        tiles = [_tile(pv[n]) for n in names]
        hh = max(t.shape[0] for t in tiles)
        tiles = [np.concatenate([t, _bg(hh - t.shape[0], t.shape[1])], 0) if t.shape[0] < hh else t for t in tiles]
        r = np.concatenate([np.concatenate([t, np.zeros((hh, 4, 3)) + 20], 1) for t in tiles], 1)
        if scale != 1:
            r = np.asarray(Image.fromarray(r.astype(np.uint8)).resize((r.shape[1] * scale, r.shape[0] * scale), Image.NEAREST), float)
        rows.append(r)
    big = list(BIG)
    for i in range(0, len(big), 4):
        row(['%s_tr' % c for c in big[i:i + 4]])
    kl = list(KILL)
    for i in range(0, len(kl), 4):
        row(['%s_tr' % c for c in kl[i:i + 4]])
    row(['ar5_tr', 'ar1_tr', 'cd10_tr', 'cd3_tr', 'cd1_tr'])
    row(['zwin_en', 'boss_en', 'km2_en', 'ar3_en'])
    row(['hm_hit', 'hm_hs', 'hm_kill'], 2)
    # world: hp bars + icons at 2x
    hp = pv['hp538']
    strip = [hp[k] for k in (50, 40, 25, 12, 3, 0, 61, 56)]
    row_imgs = [np.pad(s, ((4, 4), (4, 4), (0, 0))) for s in strip]
    rows.append(np.asarray(Image.fromarray(np.concatenate([_tile(r) for r in row_imgs], 1).astype(np.uint8)).resize(
        (sum(r.shape[1] for r in row_imgs) * 2, row_imgs[0].shape[0] * 2), Image.NEAREST), float))
    bb = pv['bossbar538']
    rows.append(np.concatenate([_tile(bb[k]) for k in (25, 15, 5, 36)], 1))
    ic = pv['icons538']
    rows.append(np.asarray(Image.fromarray(np.concatenate([_tile(i) for i in ic[:11]], 1).astype(np.uint8)).resize(
        (64 * 11 * 2, 128), Image.LANCZOS), float))
    rows.append(np.asarray(Image.fromarray(np.concatenate([_tile(i) for i in ic[11:]], 1).astype(np.uint8)).resize(
        (64 * (len(ic) - 11) * 2, 128), Image.LANCZOS), float))
    bh = pv['bh_7'][:80]
    rows.append(np.concatenate([_tile(pv['bh_%d' % k][:80]) for k in (10, 7, 4, 1, 0)], 1))
    W = max(r.shape[1] for r in rows)
    out = [np.concatenate([r, np.zeros((r.shape[0], W - r.shape[1], 3)) + 20], 1) for r in rows]
    out = np.concatenate([np.concatenate([r, np.zeros((6, W, 3)) + 20], 0) for r in out], 0)
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(path)
    print('preview', path, out.shape)


if __name__ == '__main__':
    main()
