# iOS-style notification icon for the in-game HUD (shown at the top left when the tablet is closed).
# Output: cstrike/sprites/vexmira/ios_note.spr (icon) and ios_ring.spr (pop ring). Additive sprites:
# black is see-through, so the icon glows over the game. Procedural, no outside images.
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sprlib import write_spr, VP_PARALLEL, TF_ADDITIVE

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'cstrike', 'sprites', 'vexmira')
S, SS = 64, 8


def icon():
    W = S * SS
    im = Image.new('RGB', (W, W), (0, 0, 0))
    # soft red glow behind the tile
    glow = Image.new('L', (W, W), 0)
    ImageDraw.Draw(glow).rounded_rectangle([W * .10, W * .10, W * .90, W * .90], radius=W * .24, fill=150)
    glow = glow.filter(ImageFilter.GaussianBlur(W * .05))
    im.paste((120, 18, 30), mask=glow)
    # tile: vertical red gradient, rounded like an iOS app icon
    tile = Image.new('L', (W, W), 0)
    ImageDraw.Draw(tile).rounded_rectangle([W * .17, W * .17, W * .83, W * .83], radius=W * .17, fill=255)
    grad = Image.new('RGB', (W, W))
    gd = ImageDraw.Draw(grad)
    for y in range(W):
        t = y / W
        gd.line([(0, y), (W, y)], fill=(int(255 - 40 * t), int(70 - 40 * t), int(80 - 40 * t)))
    im.paste(grad, mask=tile)
    d = ImageDraw.Draw(im)
    # white bell
    cx, top = W * .5, W * .29
    d.ellipse([cx - W * .045, top - W * .035, cx + W * .045, top + W * .045], fill=(255, 255, 255))
    d.pieslice([cx - W * .17, top, cx + W * .17, W * .72], 180, 360, fill=(255, 255, 255))
    d.polygon([(cx - W * .17, W * .52), (cx + W * .17, W * .52), (cx + W * .22, W * .63), (cx - W * .22, W * .63)], fill=(255, 255, 255))
    d.rectangle([cx - W * .17, W * .45, cx + W * .17, W * .55], fill=(255, 255, 255))
    d.ellipse([cx - W * .06, W * .62, cx + W * .06, W * .71], fill=(255, 255, 255))
    # small white badge dot (top right)
    d.ellipse([W * .66, W * .14, W * .84, W * .32], fill=(255, 255, 255))
    d.ellipse([W * .69, W * .17, W * .81, W * .29], fill=(255, 59, 48))
    return im.resize((S, S), Image.LANCZOS)


def ring():
    W = S * SS
    im = Image.new('L', (W, W), 0)
    d = ImageDraw.Draw(im)
    d.ellipse([W * .08, W * .08, W * .92, W * .92], outline=255, width=int(W * .06))
    im = im.filter(ImageFilter.GaussianBlur(W * .02)).resize((S, S), Image.LANCZOS)
    a = np.asarray(im, float) / 255.0
    rgb = np.stack([a * 255, a * 120, a * 130], 2).astype(np.uint8)
    return Image.fromarray(rgb, 'RGB')


def save(img, name):
    q = img.quantize(colors=255, method=Image.MEDIANCUT, dither=Image.NONE)
    pal = q.getpalette()[:765]
    pal += [0] * (768 - len(pal))
    pal = [tuple(pal[i:i + 3]) for i in range(0, 768, 3)]
    idx = np.asarray(q, np.uint8)
    path = os.path.join(OUT, name)
    write_spr(path, [idx], VP_PARALLEL, pal, TF_ADDITIVE)
    img.save(os.path.join(ROOT, 'devtools', 'sprkit', name.replace('.spr', '_preview.png')))
    print(path, os.path.getsize(path))


if __name__ == '__main__':
    save(icon(), 'ios_note.spr')
    # save(ring(), 'ios_ring.spr')  (not used)
