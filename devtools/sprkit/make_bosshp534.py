"""Vexmira 5.3.4 boss HP card drawn HIGH on the screen (crosshair trick).

The CS client draws the zoom-crosshair region centred on the screen centre, so the bar is put at the top of a
tall 128x512 cell: it shows ~205 px above the crosshair (upper part of the screen at every resolution, still
visible at 640x480). A small crosshair is drawn in the cell centre (the card replaces the real one).
Two cells (levels) side by side per 256x512 sheet (power of two: no GL resampling).

    cd devtools/sprkit && python3 make_bosshp534.py [--preview out.png]

Out: cstrike/sprites/vexmira/c534/bh_<0..10>.txt + sbh<n>.spr  (new names: clients that cached the old
centred hp_ card download the new one)
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import make_cards533 as K  # noqa: E402
from make_cards532 import Cv, text_mask, bold_text, vgrad, BAYER, SS  # noqa: E402
from sprlib import write_spr, quantize_alphatest, VP_PARALLEL, TF_ALPHTEST  # noqa: E402

OUT = os.path.abspath(os.path.join(HERE, '..', '..', 'cstrike', 'sprites', 'vexmira', 'c534'))
REL = 'vexmira/c534'
CW, CH = 128, 512            # cell
TOP = 22                     # content row 0 -> cell row TOP


def content(level):
    """128x64 content drawn in the left part of a standard canvas: BOSS label, bar, percent."""
    cv = Cv()
    X, Y = cv.X, cv.Y
    frac = level / 10.0
    x0, x1, y0, y1 = 8, 120, 24, 38
    frame = ((X > x0 - 2) & (X < x1 + 2) & (Y > y0 - 2) & (Y < y1 + 2)).astype(float)
    cv.paint(frame, (20, 6, 8))
    col = (60, 230, 90) if frac > 0.6 else ((255, 200, 40) if frac > 0.3 else (255, 50, 40))
    fill = ((X > x0) & (X < x0 + (x1 - x0) * frac) & (Y > y0) & (Y < y1)).astype(float)
    if fill.any():
        cv.paint(fill, vgrad(fill, [tuple(min(255, c + 90) for c in col), col, tuple(c // 2 for c in col)]))
    for k in range(1, 10):
        xx = x0 + (x1 - x0) * k / 10
        cv.paint(((np.abs(X - xx) < 0.5) & (Y > y0) & (Y < y1)).astype(float), (10, 4, 4), 0.8)
    lab = text_mask('BOSS', K.FB, 15, 64, 11, 110)
    bold_text(cv, lab, K.TH['boss'], outline=1.3, glow=1.6, glow_a=0.35)
    pct = text_mask('%d%%' % (level * 10), K.FB, 13, 64, 51, 110)
    bold_text(cv, pct, dict(K.TH['boss'], grad=[(255, 255, 255), (240, 240, 240), (200, 200, 200)]), outline=1.2, glow=1, glow_a=0.2)
    rgb, a = K.finish(cv)
    return rgb[:64, :CW], a[:64, :CW]


def cell(level):
    rgb = np.zeros((CH, CW, 3))
    a = np.zeros((CH, CW))
    r, al = content(level)
    rgb[TOP:TOP + 64] = r
    a[TOP:TOP + 64] = al
    c = (90, 255, 140)                     # crosshair in the centre
    cy, cx = CH // 2, CW // 2
    for dx, dy, w, h in ((-9, 0, 6, 2), (9, 0, 6, 2), (0, -9, 2, 6), (0, 9, 2, 6)):
        ys, xs = cy + dy - h // 2, cx + dx - w // 2
        rgb[ys:ys + h, xs:xs + w] = c
        a[ys:ys + h, xs:xs + w] = 1.0
    return rgb, a


def write_sheet(name, cells):
    rgb = np.concatenate([c[0] for c in cells], 1)
    a = np.concatenate([c[1] for c in cells], 1)
    if rgb.shape[1] < 256:
        pad = 256 - rgb.shape[1]
        rgb = np.concatenate([rgb, np.zeros((CH, pad, 3))], 1)
        a = np.concatenate([a, np.zeros((CH, pad))], 1)
    h, w = a.shape
    o = a > np.tile(BAYER, (h // 8, w // 8))
    col = np.where(a[..., None] > 1e-6, rgb / np.maximum(a[..., None], 1e-6), 0)
    for k in range(w // CW):
        o[:, k * CW:k * CW + 2] = o[:, k * CW + CW - 2:k * CW + CW] = False
    o[:2, :] = o[-2:, :] = False
    idx, pal = quantize_alphatest([np.clip(col, 0, 255)], [o])
    write_spr(os.path.join(OUT, name + '.spr'), idx, VP_PARALLEL, pal, TF_ALPHTEST)
    return np.where(o[..., None], np.array(pal, float)[idx[0]], 0)


def write_txt(card, sheet, x):
    lines = []
    for res in (320, 640):
        for k in ('crosshair', 'autoaim', 'zoom', 'zoom_autoaim'):
            lines.append('%s\t%d\t%s/%s\t%d\t0\t%d\t%d' % (k, res, REL, sheet, x, CW, CH))
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
        if f.startswith(('bh_', 'sbh')):
            os.remove(os.path.join(OUT, f))
    tiles = {}
    for i in range(0, 11, 2):
        lv = [l for l in (i, i + 1) if l <= 10]
        sheet = 'sbh%d' % (i // 2)
        img = write_sheet(sheet, [cell(l) for l in lv])
        for k, l in enumerate(lv):
            write_txt('bh_%d' % l, sheet, k * CW)
            tiles[l] = img[:, k * CW:(k + 1) * CW]
    files = [f for f in os.listdir(OUT) if f.startswith(('bh_', 'sbh'))]
    print('%d files, %d KB' % (len(files), sum(os.path.getsize(os.path.join(OUT, f)) for f in files) // 1024))
    if a.preview:   # 1024x768 screen mock with the card centred
        scr = np.zeros((768, 1024, 3)) + 50
        scr[::32, :] = 70
        t = tiles[6]
        y0, x0 = 384 - CH // 2, 512 - CW // 2
        m = t.sum(-1) > 0
        scr[y0:y0 + CH, x0:x0 + CW][m] = t[m]
        Image.fromarray(scr.astype(np.uint8)).save(a.preview)


if __name__ == '__main__':
    main()
