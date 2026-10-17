"""Vexmira 5.3.3 screen card set (CSO style, crosshair trick, ALPHTEST).

    cd devtools/sprkit && python3 make_cards533.py [--preview out_dir]

Every card is a 256x128 cell; two cells share one 256x256 sprite sheet, every card has its own .txt
(crosshair / zoom region = the cell). Drawn by the CS client centred on the crosshair.
Out: cstrike/sprites/vexmira/c533/
   s<lang><n>.spr      sheets           <card>_<lang>.txt     card scripts
   hp_<0..10>.txt + shp<n>.spr          boss HP bar (language-neutral, crosshair drawn inside)
Cards:
   big   zwin hwin mvp boss last infect nemesis assassin survivor bkill fb level round
   kill  km1 km2 km3 km4 km5 hs knife nade infd   (content in the lower half = below the crosshair)
   cd    cd1 .. cd10                               (round start countdown)
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import make_cards532 as C  # noqa: E402
from make_cards532 import Cv, text_mask, bold_text, decorate, grow, blur, vgrad, BAYER, W, H, SS  # noqa: E402
from sprlib import write_spr, read_spr, quantize_alphatest, VP_PARALLEL, TF_ALPHTEST  # noqa: E402

OUT = os.path.abspath(os.path.join(HERE, '..', '..', 'cstrike', 'sprites', 'vexmira', 'c533'))
REL = 'vexmira/c533'
FB, FS = C.FONT_B, C.FONT_S

TH = dict(C.THEMES)
TH.update({
    'infect': dict(grad=[(240, 255, 220), (150, 255, 60), (30, 140, 10)], ink=(8, 20, 4), glow=(90, 255, 40), acc=(160, 255, 60)),
    'nemesis': dict(grad=[(255, 230, 230), (255, 60, 50), (120, 0, 0)], ink=(24, 0, 0), glow=(255, 30, 30), acc=(255, 120, 60)),
    'assassin': dict(grad=[(245, 230, 255), (190, 110, 255), (80, 20, 160)], ink=(14, 2, 28), glow=(170, 80, 255), acc=(220, 160, 255)),
    'survivor': dict(grad=[(240, 252, 255), (110, 220, 255), (0, 120, 200)], ink=(2, 14, 28), glow=(40, 190, 255), acc=(200, 245, 255)),
    'bkill': dict(grad=[(245, 255, 245), (120, 255, 170), (10, 150, 80)], ink=(2, 22, 10), glow=(60, 255, 140), acc=(255, 230, 120)),
    'fb': dict(grad=[(255, 235, 230), (255, 80, 60), (150, 10, 10)], ink=(26, 2, 2), glow=(255, 40, 30), acc=(255, 200, 120)),
    'level': dict(grad=[(240, 255, 255), (90, 230, 255), (0, 130, 210)], ink=(2, 16, 30), glow=(60, 210, 255), acc=(255, 220, 120)),
    'round': dict(grad=[(255, 252, 235), (255, 210, 90), (200, 110, 10)], ink=(28, 14, 2), glow=(255, 180, 40), acc=(255, 240, 180)),
    'kill': dict(grad=[(255, 255, 255), (255, 210, 120), (220, 120, 20)], ink=(24, 10, 2), glow=(255, 160, 40), acc=(255, 70, 50)),
    'hs': dict(grad=[(255, 245, 245), (255, 90, 80), (170, 10, 20)], ink=(24, 0, 2), glow=(255, 40, 40), acc=(255, 220, 140)),
    'cd': dict(grad=[(255, 255, 255), (255, 220, 120), (230, 120, 20)], ink=(26, 10, 2), glow=(255, 150, 30), acc=(255, 80, 60)),
})

BIG = {   # card: theme, (tr big, tr sub), (en big, en sub)
    'zwin': ('zwin', ('ZOMBİLER', 'KAZANDI'), ('ZOMBIES', 'WIN')),
    'hwin': ('hwin', ('İNSANLAR', 'KAZANDI'), ('HUMANS', 'WIN')),
    'mvp': ('mvp', ('MVP', 'TURUN YILDIZI'), ('MVP', 'ROUND STAR')),
    'boss': ('boss', ('BOSS', 'GELİYOR'), ('BOSS', 'IS COMING')),
    'last': ('last', ('SON İNSAN', 'HAYATTA KAL!'), ('LAST HUMAN', 'SURVIVE!')),
    'infect': ('infect', ('ENFEKSİYON', 'SALGIN BAŞLADI'), ('INFECTION', 'THE OUTBREAK BEGINS')),
    'nemesis': ('nemesis', ('NEMESİS', 'AV BAŞLADI'), ('NEMESIS', 'THE HUNT BEGINS')),
    'assassin': ('assassin', ('SUİKASTÇI', 'KARANLIĞA DİKKAT'), ('ASSASSIN', 'WATCH THE DARK')),
    'survivor': ('survivor', ('KURTULAN', 'İNSANLIĞIN UMUDU'), ('SURVIVOR', "HUMANITY'S HOPE")),
    'bkill': ('bkill', ('BOSS', 'YENİLDİ!'), ('BOSS', 'DEFEATED!')),
    'fb': ('fb', ('İLK KAN', 'İLK ELEME'), ('FIRST BLOOD', 'FIRST KILL')),
    'level': ('level', ('SEVİYE', 'ATLADIN!'), ('LEVEL UP', 'NEW REWARDS')),
    'round': ('round', ('YENİ TUR', 'SAVAŞA HAZIR OL'), ('NEW ROUND', 'GET READY')),
}
KILL = {   # killmark: theme, tr, en, skulls
    'km1': ('kill', 'ELEME', 'KILL', 1), 'km2': ('kill', 'ÇİFT ELEME', 'DOUBLE KILL', 2),
    'km3': ('kill', 'ÜÇLÜ ELEME', 'TRIPLE KILL', 3), 'km4': ('hs', 'ÇOKLU ELEME', 'MULTI KILL', 4),
    'km5': ('hs', 'KATLİAM', 'DOMINATING', 5), 'hs': ('hs', 'KAFADAN!', 'HEADSHOT!', 0),
    'knife': ('kill', 'BIÇAKLA!', 'KNIFE KILL!', 0), 'nade': ('kill', 'BOMBAYLA!', 'GRENADE KILL!', 0),
    'infd': ('infect', 'ENFEKTE ETTİN', 'INFECTED', 0),
}


def skull(cv, cx, cy, s, th):
    X, Y = cv.X, cv.Y
    head = (((X - cx) / (6.2 * s)) ** 2 + ((Y - cy) / (5.6 * s)) ** 2 < 1).astype(float)
    jaw = ((np.abs(X - cx) < 3.6 * s) & (Y > cy + 2 * s) & (Y < cy + 7.5 * s)).astype(float)
    m = np.clip(head + jaw, 0, 1)
    eyes = ((((X - cx + 2.4 * s) / (1.7 * s)) ** 2 + ((Y - cy) / (1.9 * s)) ** 2 < 1) |
            (((X - cx - 2.4 * s) / (1.7 * s)) ** 2 + ((Y - cy) / (1.9 * s)) ** 2 < 1)).astype(float)
    cv.paint(grow(m, 1.0), th['ink'])
    cv.paint(m, vgrad(m, [(255, 255, 255), (230, 225, 210), (170, 160, 140)]))
    cv.paint(eyes, th['acc'])


def finish(cv):
    s = SS
    rgb = cv.rgb.reshape(H, s, W, s, 3).mean((1, 3))
    a = cv.a.reshape(H, s, W, s).mean((1, 3))
    return rgb, a


def cell_big(card, lang):
    th_name, tr, en = BIG[card]
    th = TH[th_name]
    big, sub = tr if lang == 'tr' else en
    cv = Cv()
    deco = card if card in ('zwin', 'hwin', 'mvp', 'boss', 'last') else None
    if deco:
        decorate(cv, deco, th, np.random.default_rng(len(card)))
    else:
        X, Y = cv.X, cv.Y
        for s in (-1, 1):            # common frame: angled light blades + ring sparks
            cv.paint(cv.poly([(128 + s * 16, 100), (128 + s * 122, 96), (128 + s * 118, 102), (128 + s * 16, 104)]), th['acc'], 0.9)
            cv.paint(cv.poly([(128 + s * 30, 20), (128 + s * 110, 16), (128 + s * 104, 20), (128 + s * 30, 23)]), th['glow'], 0.7)
        cv.paint(np.exp(-((Y - 60) / 0.9) ** 2) * np.exp(-((X - 128) / 90) ** 2), (255, 255, 255), 0.5)
    mb = text_mask(big, FB, 46 if len(big) <= 9 else 38, 128, 58 if card != 'mvp' else 60, 238)
    bold_text(cv, mb, th)
    ms = text_mask(sub, FS, 16, 128, 96, 224)
    bold_text(cv, ms, dict(th, grad=[(255, 255, 255), (235, 235, 235), (190, 190, 190)]), outline=1.6, glow=2.5, glow_a=0.35)
    return finish(cv)


def cell_kill(card, lang):
    th_name, tr, en, n = KILL[card]
    th = TH[th_name]
    text = tr if lang == 'tr' else en
    cv = Cv()
    # content sits in the lower half (y 70-126) -> just below the crosshair
    if n:
        for i in range(n):
            skull(cv, 128 + (i - (n - 1) / 2) * 17, 82, 1.15, th)
    else:
        X, Y = cv.X, cv.Y
        if card == 'hs':           # target reticle
            r = np.hypot(X - 128, Y - 82)
            cv.paint(np.clip(1 - np.abs(r - 9) / 1.2, 0, 1), th['ink'], 1.0)
            cv.paint(np.clip(1 - np.abs(r - 9) / 0.7, 0, 1), th['acc'])
            cv.paint(((r < 3)).astype(float), th['glow'])
        elif card == 'knife':
            k = cv.poly([(104, 86), (148, 76), (156, 78), (150, 82), (106, 89)])
            cv.paint(grow(k, 1.0), th['ink']); cv.paint(k, vgrad(k, [(255, 255, 255), (200, 210, 220), (120, 130, 140)]))
        elif card == 'nade':
            m = (((X - 128) / 7) ** 2 + ((Y - 84) / 8) ** 2 < 1).astype(float)
            cv.paint(grow(m, 1.0), th['ink']); cv.paint(m, vgrad(m, [(160, 200, 120), (90, 130, 60), (40, 60, 30)]))
            cv.paint(cv.line([(128, 76), (134, 72)], 2.0), (200, 200, 200))
        else:                      # infection: bio drop
            m = (((X - 128) / 7) ** 2 + ((Y - 86) / 7) ** 2 < 1).astype(float) + cv.poly([(122, 83), (128, 72), (134, 83)])
            m = np.clip(m, 0, 1)
            cv.paint(grow(m, 1.0), th['ink']); cv.paint(m, vgrad(m, [(220, 255, 160), (120, 240, 40), (30, 120, 10)]))
    mt = text_mask(text, FB, 24, 128, 111, 236)
    bold_text(cv, mt, th, outline=1.8, glow=2.5, glow_a=0.4)
    return finish(cv)


def cell_cd(n, lang):
    th = TH['cd'] if n > 3 else TH['hs']
    cv = Cv()
    X, Y = cv.X, cv.Y
    r = np.hypot(X - 128, Y - 62)
    cv.paint(np.clip(1 - np.abs(r - 40) / 1.4, 0, 1), th['glow'], 0.9)         # countdown ring
    ang = (np.arctan2(Y - 62, X - 128) + np.pi / 2) % (2 * np.pi)
    arc = (np.abs(r - 44) < 2.2) & (ang < 2 * np.pi * n / 10.0)
    cv.paint(arc.astype(float), th['acc'])
    mn = text_mask(str(n), FB, 58, 128, 62, 120)
    bold_text(cv, mn, th, outline=2.6, glow=4, glow_a=0.5)
    top = 'TUR BAŞLIYOR' if lang == 'tr' else 'ROUND STARTS IN'
    bot = 'SAVAŞA HAZIR OL' if lang == 'tr' else 'PREPARE FOR COMBAT'
    for txt, y in ((top, 12), (bot, 116)):
        m = text_mask(txt, FS, 13, 128, y, 236)
        bold_text(cv, m, dict(th, grad=[(255, 255, 255), (240, 240, 240), (200, 200, 200)]), outline=1.4, glow=2, glow_a=0.3)
    return finish(cv)


def cell_hp(level):
    """boss HP bar at the top of the cell + a small crosshair in the centre (the card replaces it)."""
    cv = Cv()
    X, Y = cv.X, cv.Y
    frac = level / 10.0
    x0, x1, y0, y1 = 40, 216, 6, 20
    frame = ((X > x0 - 2) & (X < x1 + 2) & (Y > y0 - 2) & (Y < y1 + 2)).astype(float)
    cv.paint(frame, (20, 6, 8))
    col = (60, 230, 90) if frac > 0.6 else ((255, 200, 40) if frac > 0.3 else (255, 50, 40))
    fill = ((X > x0) & (X < x0 + (x1 - x0) * frac) & (Y > y0) & (Y < y1)).astype(float)
    cv.paint(fill, vgrad(fill if fill.any() else frame, [tuple(min(255, c + 90) for c in col), col, tuple(c // 2 for c in col)]))
    for k in range(1, 10):                                   # segment ticks
        xx = x0 + (x1 - x0) * k / 10
        cv.paint(((np.abs(X - xx) < 0.5) & (Y > y0) & (Y < y1)).astype(float), (10, 4, 4), 0.8)
    lab = text_mask('BOSS', FB, 13, 22, 13, 40)
    bold_text(cv, lab, TH['boss'], outline=1.2, glow=1.5, glow_a=0.3)
    pct = text_mask('%d%%' % (level * 10), FB, 12, 236, 13, 40)
    bold_text(cv, pct, dict(TH['boss'], grad=[(255, 255, 255), (240, 240, 240), (200, 200, 200)]), outline=1.2, glow=1, glow_a=0.2)
    # crosshair (cyan, like the CS one)
    c = (90, 255, 140)
    for dx, dy, w, h in ((-9, 0, 6, 1), (9, 0, 6, 1), (0, -9, 1, 6), (0, 9, 1, 6)):
        cv.paint(((np.abs(X - (128 + dx)) < w / 2 + 0.5) & (np.abs(Y - (64 + dy)) < h / 2 + 0.5)).astype(float), c)
    return finish(cv)


def write_sheet(name, cells):
    """cells: list of (rgb, a) 256x128 -> 256x(128*len) ALPHTEST sheet"""
    rgb = np.concatenate([c[0] for c in cells], 0)
    a = np.concatenate([c[1] for c in cells], 0)
    h = rgb.shape[0]
    thr = np.tile(BAYER, (h // 8, W // 8))
    o = a > thr
    col = np.where(a[..., None] > 1e-6, rgb / np.maximum(a[..., None], 1e-6), 0)
    for k in range(len(cells)):                               # 2 px transparent border per cell
        o[k * H:k * H + 2, :] = o[k * H + H - 2:k * H + H, :] = False
    o[:, :2] = o[:, -2:] = False
    idx, pal = quantize_alphatest([np.clip(col, 0, 255)], [o])
    write_spr(os.path.join(OUT, name + '.spr'), idx, VP_PARALLEL, pal, TF_ALPHTEST)
    return np.where(o[..., None], np.array(pal, float)[idx[0]], 0)


def write_txt(card, sheet, row):
    lines = []
    for res in (320, 640):
        for k in ('crosshair', 'autoaim', 'zoom', 'zoom_autoaim'):
            lines.append('%s\t%d\t%s/%s\t0\t%d\t%d\t%d' % (k, res, REL, sheet, row * H, W, H))
        for k in ('weapon', 'weapon_s', 'ammo', 'ammo2'):
            lines.append('%s\t%d\t%s/%s\t0\t0\t4\t4' % (k, res, REL, sheet))
    with open(os.path.join(OUT, card + '.txt'), 'w', newline='\r\n') as f:
        f.write('%d\n' % len(lines))
        for ln in lines:
            f.write(ln + '\n')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--preview')
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        os.remove(os.path.join(OUT, f))
    previews = {}
    for lang in ('tr', 'en'):
        jobs = [(c + '_' + lang, lambda c=c: cell_big(c, lang)) for c in BIG]
        jobs += [(c + '_' + lang, lambda c=c: cell_kill(c, lang)) for c in KILL]
        jobs += [('cd%d_%s' % (n, lang), lambda n=n: cell_cd(n, lang)) for n in range(1, 11)]
        for i in range(0, len(jobs), 2):
            pair = jobs[i:i + 2]
            sheet = 's%s%d' % (lang, i // 2)
            cells = [fn() for _, fn in pair]
            img = write_sheet(sheet, cells)
            for r, (card, _) in enumerate(pair):
                write_txt(card, sheet, r)
                previews[card] = img[r * H:(r + 1) * H]
    for i in range(0, 11, 2):
        lv = [l for l in (i, i + 1) if l <= 10]
        sheet = 'shp%d' % (i // 2)
        img = write_sheet(sheet, [cell_hp(l) for l in lv])
        for r, l in enumerate(lv):
            write_txt('hp_%d' % l, sheet, r)
            previews['hp_%d' % l] = img[r * H:(r + 1) * H]
    files = os.listdir(OUT)
    print('%d files, %d KB' % (len(files), sum(os.path.getsize(os.path.join(OUT, f)) for f in files) // 1024))
    if a.preview:
        os.makedirs(a.preview, exist_ok=True)
        groups = {'buyuk_kartlar': [c + '_tr' for c in BIG], 'killmark': [c + '_tr' for c in KILL],
                  'geri_sayim': ['cd%d_tr' % n for n in range(10, 0, -1)], 'boss_can': ['hp_%d' % l for l in range(10, -1, -2)],
                  'ingilizce': [c + '_en' for c in ('zwin', 'hwin', 'mvp', 'boss', 'last', 'km2', 'hs')] + ['cd5_en']}
        for g, names in groups.items():
            tiles = []
            for n in names:
                t = previews[n]
                bg = np.zeros((H, W, 3)) + 45
                yy, xx = np.mgrid[0:H, 0:W]
                bg[((yy // 16 + xx // 16) % 2) == 0] = 62
                m = t.sum(-1) > 0
                tiles.append(np.where(m[..., None], t, bg).astype(np.uint8))
            cols = 2
            rows = [np.concatenate(tiles[i:i + cols] + [np.zeros_like(tiles[0])] * (cols - len(tiles[i:i + cols])), 1)
                    for i in range(0, len(tiles), cols)]
            Image.fromarray(np.concatenate(rows, 0)).resize((W * cols * 2, H * len(rows) * 2), Image.NEAREST).save(
                os.path.join(a.preview, g + '.png'))


if __name__ == '__main__':
    main()
