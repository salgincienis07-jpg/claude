# iPad notification card for the CSO card system (c539 set): only an iOS-style bell icon.
# The card is drawn by the client as the weapon's zoom crosshair, so it stays fixed on the screen
# (above the crosshair) exactly like the other CSO cards.
# Output: cstrike/sprites/vexmira/c539/ipad.spr + ipad_tr.txt + ipad_en.txt
import os, sys
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sprlib import write_spr, quantize_alphatest, VP_PARALLEL, TF_ALPHTEST

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'cstrike', 'sprites', 'vexmira', 'c539')
W, H, SS = 256, 112, 8
ICON = 60  # px, top centre of the card


def card():
    w, h = W * SS, H * SS
    rgba = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(rgba)
    s = ICON * SS
    x0, y0 = (w - s) // 2, 2 * SS
    # dark outline so the icon reads on bright and dark maps
    d.rounded_rectangle([x0 - 2 * SS, y0 - 2 * SS, x0 + s + 2 * SS, y0 + s + 2 * SS], radius=int(s * .26), fill=(20, 8, 12, 255))
    # red tile (vertical gradient)
    tile = Image.new('L', (w, h), 0)
    ImageDraw.Draw(tile).rounded_rectangle([x0, y0, x0 + s, y0 + s], radius=int(s * .23), fill=255)
    grad = Image.new('RGBA', (w, h))
    gd = ImageDraw.Draw(grad)
    for y in range(y0, y0 + s):
        t = (y - y0) / s
        gd.line([(x0, y), (x0 + s, y)], fill=(int(255 - 35 * t), int(72 - 30 * t), int(84 - 30 * t), 255))
    rgba.paste(grad, mask=tile)
    # white bell
    cx, top = x0 + s * .5, y0 + s * .17
    white = (255, 255, 255, 255)
    d.ellipse([cx - s * .06, top - s * .045, cx + s * .06, top + s * .06], fill=white)
    d.pieslice([cx - s * .23, top, cx + s * .23, y0 + s * .78], 180, 360, fill=white)
    d.rectangle([cx - s * .23, y0 + s * .44, cx + s * .23, y0 + s * .62], fill=white)
    d.polygon([(cx - s * .23, y0 + s * .60), (cx + s * .23, y0 + s * .60), (cx + s * .30, y0 + s * .72), (cx - s * .30, y0 + s * .72)], fill=white)
    d.ellipse([cx - s * .08, y0 + s * .71, cx + s * .08, y0 + s * .83], fill=white)
    # badge dot
    bx, by, br = x0 + s * .86, y0 + s * .14, s * .16
    d.ellipse([bx - br - 2 * SS, by - br - 2 * SS, bx + br + 2 * SS, by + br + 2 * SS], fill=(20, 8, 12, 255))
    d.ellipse([bx - br, by - br, bx + br, by + br], fill=white)
    d.ellipse([bx - br * .62, by - br * .62, bx + br * .62, by + br * .62], fill=(255, 59, 48, 255))
    img = rgba.resize((W, H), Image.LANCZOS)
    a = np.asarray(img, float)
    rgb, alpha = a[..., :3], a[..., 3] / 255.0
    return rgb, alpha >= 0.5


def main():
    rgb, opaque = card()
    frames, pal = quantize_alphatest([rgb], [opaque])
    os.makedirs(OUT, exist_ok=True)
    write_spr(os.path.join(OUT, 'ipad.spr'), frames, VP_PARALLEL, pal, TF_ALPHTEST)
    rows = []
    for res in (320, 640):
        for k in ('crosshair', 'autoaim', 'zoom', 'zoom_autoaim'):
            rows.append('%s\t%d\tvexmira/c539/ipad\t0\t0\t%d\t%d' % (k, res, W, H))
        for k in ('weapon', 'weapon_s', 'ammo', 'ammo2'):
            rows.append('%s\t%d\tvexmira/c539/ipad\t0\t0\t4\t4' % (k, res))
    txt = '%d\n%s\n' % (len(rows), '\n'.join(rows))
    for lang in ('tr', 'en'):
        open(os.path.join(OUT, 'ipad_%s.txt' % lang), 'w', newline='\r\n').write(txt)
    prev = np.zeros((H, W, 3), np.uint8)
    prev[opaque] = np.array([pal[i] for i in frames[0][opaque]], np.uint8)
    Image.fromarray(prev).resize((W * 2, H * 2), Image.NEAREST).save(os.path.join(ROOT, 'devtools', 'sprkit', 'ipad_card_preview.png'))
    print('ok', os.path.getsize(os.path.join(OUT, 'ipad.spr')))


if __name__ == '__main__':
    main()
