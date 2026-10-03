# SPR onizleme + dogrulama: her sprite'i ayristirir, temas sayfasi PNG'leri uretir.
# ALPHTEST/INDEXALPHA/NORMAL -> gercek renk + saydamlik (koyu ve acik zemin)
# ADDITIVE -> zemine toplamali (koyu zemin ve acik zemin) + rendercolor ornegi
import os, sys, glob
sys.dont_write_bytecode = True
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sprlib import read_spr, TF_ADDITIVE, TF_ALPHTEST, TF_INDEXALPHA, TF_NAMES, TYPE_NAMES

SRC = sys.argv[1] if len(sys.argv) > 1 else '/home/user/claude/cstrike/sprites/vexmira'
DST = sys.argv[2] if len(sys.argv) > 2 else '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/previews/sprites'
ONLY = sys.argv[3].split(',') if len(sys.argv) > 3 else None

DARK = np.array([34, 36, 44], float)
LIGHT = np.array([196, 200, 206], float)


def checker(h, w, c1, c2, n=8):
    yy, xx = np.mgrid[0:h, 0:w]
    m = ((yy // n + xx // n) % 2)[..., None]
    return np.where(m, c1, c2).astype(float)


def render(s, fr, bg, tint=None):
    pal = s['pal'].astype(float)
    rgb = pal[fr]
    if s['fmt'] == TF_ADDITIVE:
        if tint is not None:
            rgb = rgb * (np.array(tint, float) / 255.0)
        return np.clip(bg + rgb, 0, 255)
    if s['fmt'] == TF_ALPHTEST:
        o = (fr != 255)[..., None]
        return np.where(o, rgb, bg)
    if s['fmt'] == TF_INDEXALPHA:
        a = fr.astype(float)[..., None] / 255.0
        return bg * (1 - a) + pal[255] * a
    return rgb


def sheet(path, s, scale, maxframes=64):
    nf = min(s['nf'], maxframes)
    h, w = s['h'] * scale, s['w'] * scale
    cols = max(1, min(nf, max(1, 1024 // (w + 6))))
    rows = (nf + cols - 1) // cols
    bands = [('dark', DARK, None), ('light', LIGHT, None)]
    if s['fmt'] == TF_ADDITIVE:
        bands.append(('tint', DARK, (255, 120, 40)))
    H = 22 + len(bands) * (rows * (h + 6) + 16)
    W = max(cols * (w + 6) + 6, 420)
    out = np.zeros((H, W, 3)) + 18
    img = Image.fromarray(out.astype(np.uint8))
    dr = ImageDraw.Draw(img)
    name = os.path.basename(path)
    dr.text((6, 5), '%s  %dx%d x%d  %s/%s  %d B' % (name, s['w'], s['h'], s['nf'], TYPE_NAMES[s['type']],
                                                   TF_NAMES[s['fmt']], s['size']), fill=(230, 230, 230))
    y = 22
    for label, bgc, tint in bands:
        dr.text((6, y), label, fill=(150, 150, 150))
        y += 14
        for i in range(nf):
            bg = checker(s['h'], s['w'], bgc, bgc * 0.86 + 4, 4)
            px = render(s, s['frames'][i], bg, tint)
            px = np.repeat(np.repeat(px, scale, 0), scale, 1)
            r, c = divmod(i, cols)
            img.paste(Image.fromarray(px.astype(np.uint8)), (6 + c * (w + 6), y + r * (h + 6)))
        y += rows * (h + 6) + 2
    return img


def main():
    os.makedirs(DST, exist_ok=True)
    files = sorted(glob.glob(os.path.join(SRC, '*.spr')))
    total = 0
    for p in files:
        n = os.path.basename(p)[:-4]
        if ONLY and n not in ONLY:
            continue
        s = read_spr(p)
        total += s['size']
        scale = 3 if max(s['w'], s['h']) <= 64 else (2 if max(s['w'], s['h']) <= 128 else 2)
        if n in ('bossbar',):
            scale = 2
        im = sheet(p, s, scale, maxframes=64)
        im.save(os.path.join(DST, n + '.png'))
        print('%-18s ok  %3dx%-3d x%-3d %-22s %-10s %7d B' % (n, s['w'], s['h'], s['nf'], TYPE_NAMES[s['type']],
                                                           TF_NAMES[s['fmt']], s['size']))
    print('toplam', total, 'B')


if __name__ == '__main__':
    main()
