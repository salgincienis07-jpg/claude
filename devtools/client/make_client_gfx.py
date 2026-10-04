#!/usr/bin/env python3
"""Generate the client-only 2D resources the Xash3D FWGS render client needs.

The test server ships no Valve content: its valve/gfx.wad and valve/fonts.wad are empty
placeholders, and the engine refuses to start without "gfx/conchars". This script builds
free replacements from DejaVu fonts (Bitstream Vera / public-domain-style license,
/usr/share/fonts/truetype/dejavu) into the CLIENT's writable game dir, which shadows the
read-only server tree (-rodir):

    <client>/game/valve/gfx.wad    conchars (16x16 fixed grid, 256x256) + creditsfont (HUD text)
    <client>/game/valve/fonts.wad  font0 / font1 / font2 (console fonts, variable width)
    <client>/game/cstrike/sprites/hud.txt + 640hud_vexcl.spr + 640radar_vexcl.spr
                                   a generated HUD set (digits, health/armor/money icons, damage
                                   icons, radar disc). cs16-client aborts with "Failed to get
                                   number_0 sprite index" without a hud.txt.

Format: WAD3 with qfont_t lumps (type 0x46), exactly as Image_LoadFNT / Con_LoadVariableWidthFont
in xash3d-fwgs read them: header(16) + charinfo[256] (startoffset = y*256+x, charwidth),
then width*16*height palette indices, short 256, 768-byte palette, 64 pad bytes.
Palette index 255 is transparent (LUMP_MASKED); 0..254 is a white ramp so glyph edges keep
their antialiasing.

    python3 devtools/client/make_client_gfx.py [--out <client>/game]
"""
import argparse
import os
import struct

from PIL import Image, ImageDraw, ImageFont

SP = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad'
DEFAULT_OUT = os.path.join(SP, 'client', 'game')
DEJAVU = '/usr/share/fonts/truetype/dejavu'
TYP_QFONT = 0x46
ATLAS_W = 256


def palette():
    pal = bytearray()
    for i in range(256):
        v = min(255, int(i * 255 / 254)) if i < 255 else 0
        pal += bytes((v, v, v))
    return bytes(pal)


def coverage_to_index(img):
    """L-mode coverage image -> palette indices (255 = transparent)."""
    out = bytearray(img.width * img.height)
    px = img.tobytes()
    for i, c in enumerate(px):
        out[i] = 255 if c < 8 else min(254, c)
    return bytes(out)


def charset_char(code):
    try:
        return bytes([code]).decode('cp1252')
    except UnicodeDecodeError:
        return None


def qfont_lump(atlas_l, rowcount, rowheight, infos):
    """atlas_l: L image 256 x H coverage; infos: 256 (startoffset, charwidth)."""
    h = atlas_l.height
    hdr = struct.pack('<4i', ATLAS_W // 16, h, rowcount, rowheight)
    ci = b''.join(struct.pack('<hH', so if so < 32768 else so - 65536, cw) for so, cw in infos)
    data = coverage_to_index(atlas_l)
    lump = hdr + ci + data + struct.pack('<h', 256) + palette() + b'\0' * 64
    # sanity: matches the "Half-Life 1.1.0.0 font style" size test in Image_LoadFNT
    assert len(lump) == 16 + 256 * 4 + h * ATLAS_W + 2 + 768 + 64
    return lump


def variable_font(ttf, px, pad=1, bold_stroke=0):
    font = ImageFont.truetype(ttf, px)
    asc, desc = font.getmetrics()
    rowheight = asc + desc + 2
    glyphs = []
    for code in range(256):
        ch = charset_char(code) if code >= 32 else None
        if ch is None or not ch.isprintable():
            glyphs.append((code, None, max(2, px // 3)))
            continue
        w = int(round(font.getlength(ch))) + bold_stroke
        glyphs.append((code, ch, max(1, w)))
    # pack rows
    x, y, rows = 0, 0, 1
    places = []
    for code, ch, w in glyphs:
        if x + w + pad > ATLAS_W:
            x, y, rows = 0, y + rowheight, rows + 1
        places.append((code, ch, w, x, y))
        x += w + pad
    h = y + rowheight
    if h * ATLAS_W > 65535:
        raise SystemExit('font %s %dpx does not fit a 256-wide atlas addressed by 16-bit offsets' % (ttf, px))
    atlas = Image.new('L', (ATLAS_W, h), 0)
    d = ImageDraw.Draw(atlas)
    infos = []
    for code, ch, w, gx, gy in places:
        if ch is not None:
            d.text((gx, gy + 1), ch, font=font, fill=255, stroke_width=bold_stroke, stroke_fill=255)
        infos.append((gy * ATLAS_W + gx, w))
    return qfont_lump(atlas, rows, rowheight, infos), atlas


def fixed_conchars(ttf, cell=16):
    font = ImageFont.truetype(ttf, cell - 3)
    atlas = Image.new('L', (cell * 16, cell * 16), 0)
    d = ImageDraw.Draw(atlas)
    infos = []
    for code in range(256):
        cx, cy = (code % 16) * cell, (code // 16) * cell
        ch = charset_char(code) if code >= 32 else None
        if ch is not None and ch.isprintable():
            w = font.getlength(ch)
            d.text((cx + (cell - w) / 2, cy + 1), ch, font=font, fill=255)
        infos.append((cy * ATLAS_W + cx, cell))
    return qfont_lump(atlas, 16, cell, infos), atlas


def write_wad(path, lumps):
    """lumps: list of (name, type, bytes)."""
    body = bytearray()
    entries = []
    off = 12
    for name, typ, data in lumps:
        entries.append((off, len(data), typ, name))
        body += data
        off += len(data)
        while off % 4:
            body += b'\0'
            off += 1
    table = bytearray()
    for pos, size, typ, name in entries:
        nm = name.encode('ascii')[:15].ljust(16, b'\0')
        table += struct.pack('<iiibbbb', pos, size, size, typ, 0, 0, 0) + nm
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(b'WAD3' + struct.pack('<ii', len(lumps), off))
        f.write(body)
        f.write(table)


# ------------------------------------------------------------------------------------- HUD
SPR_VP_PARALLEL, SPR_ADDITIVE = 2, 1


def write_spr(path, img_l):
    """Single-frame GoldSrc SPR v2 (additive, grey palette) from an L image."""
    w, h = img_l.size
    pal = b''.join(bytes((i, i, i)) for i in range(256))
    with open(path, 'wb') as f:
        f.write(b'IDSP' + struct.pack('<iiifiiifi', 2, SPR_VP_PARALLEL, SPR_ADDITIVE,
                                      float((w * w + h * h) ** 0.5 / 2), w, h, 1, 0.0, 0))
        f.write(struct.pack('<h', 256) + pal)
        f.write(struct.pack('<iiiii', 0, -(w // 2), h // 2, w, h))
        f.write(img_l.tobytes())


DMG_NAMES = ['dmg_bio', 'dmg_poison', 'dmg_chem', 'dmg_cold', 'dmg_drown', 'dmg_heat', 'dmg_gas',
             'dmg_rad', 'dmg_shock', 'dmg_concuss']
WEAPONS = ['p228', 'scout', 'hegrenade', 'xm1014', 'c4', 'mac10', 'aug', 'sg550', 'elite', 'fiveseven',
           'ump45', 'sg552', 'galil', 'famas', 'usp', 'glock18', 'awp', 'mp5navy', 'm249', 'm3', 'm4a1',
           'tmp', 'g3sg1', 'deagle', 'ak47', 'p90', 'knife', 'grenade', 'flashbang', 'smokegrenade']


def make_hud(out):
    """Atlas layout (x, y, w, h) on a 256x256 sheet; names follow the stock CS 1.6 hud.txt."""
    sheet = Image.new('L', (256, 256), 0)
    d = ImageDraw.Draw(sheet)
    big = ImageFont.truetype(os.path.join(DEJAVU, 'DejaVuSans-Bold.ttf'), 22)
    small = ImageFont.truetype(os.path.join(DEJAVU, 'DejaVuSans-Bold.ttf'), 12)
    entries = []

    def put(name, x, y, w, h):
        entries.append((name, '640hud_vexcl', x, y, w, h))

    def text(x, y, w, h, s, font=big):
        tw = font.getlength(s)
        asc, desc = font.getmetrics()
        d.text((x + (w - tw) / 2, y + (h - asc - desc) / 2), s, font=font, fill=255)

    # row 0: digits 20x24 (must be consecutive: the client indexes number_0 + n)
    for n in range(10):
        text(n * 20, 0, 20, 24, str(n))
        put('number_%d' % n, n * 20, 0, 20, 24)
    d.rectangle((202, 2, 203, 21), fill=255)
    put('divider', 201, 0, 4, 24)
    text(208, 0, 18, 24, '$')
    put('dollar', 208, 0, 18, 24)
    text(228, 0, 14, 24, '+')
    put('plus', 228, 0, 14, 24)
    text(242, 0, 14, 24, '-')
    put('minus', 242, 0, 14, 24)
    # row 1 (y 24..48): health cross, armor, stopwatch, bucket digits
    d.rectangle((8, 28, 15, 43), fill=255); d.rectangle((2, 32, 21, 39), fill=255)
    put('cross', 0, 24, 24, 24)
    for i, (nm, full, helm) in enumerate((('suit_empty', 0, 0), ('suit_full', 1, 0),
                                          ('suithelmet_empty', 0, 1), ('suithelmet_full', 1, 1))):
        x = 24 + i * 24
        poly = [(x + 3, 27), (x + 21, 27), (x + 21, 37), (x + 12, 46), (x + 3, 37)]
        (d.polygon(poly, fill=200) if full else d.polygon(poly, outline=200))
        if helm:
            d.ellipse((x + 7, 25, x + 17, 33), outline=255)
        put(nm, x, 24, 24, 24)
    d.ellipse((122, 27, 141, 46), outline=255, width=2); d.line((131, 36, 131, 29), fill=255, width=2)
    d.line((131, 36, 136, 36), fill=255, width=2)
    put('stopwatch', 120, 24, 24, 24)
    for i in range(5):
        text(144 + i * 20, 26, 20, 20, str(i + 1), small)
        d.rectangle((144 + i * 20, 26, 163 + i * 20, 45), outline=120)
        put('bucket%d' % (i + 1), 144 + i * 20, 26, 20, 20)
    put('bucket0', 144, 26, 20, 20)
    # row 2 (y 48..80): damage / status icons 32x32
    labels = ['BIO', 'PSN', 'CHM', 'CLD', 'H2O', 'HOT', 'GAS', 'RAD', 'SHK', 'CON']
    for i, nm in enumerate(DMG_NAMES):
        x, y = (i % 8) * 32, 48 + (i // 8) * 32
        d.rectangle((x + 2, y + 2, x + 29, y + 29), outline=200)
        text(x, y, 32, 32, labels[i], small)
        put(nm, x, y, 32, 32)
    for i, (nm, lab) in enumerate((('c4', 'C4'), ('defuser', 'DEF'), ('buyzone', 'BUY'), ('rescue', 'RES'),
                                   ('escape', 'ESC'), ('vipsafety', 'VIP'))):
        x, y = 64 + i * 32, 80
        d.ellipse((x + 2, y + 2, x + 29, y + 29), outline=220)
        text(x, y, 32, 32, lab, small)
        put(nm, x, y, 32, 32)
    # row 4 (y 112..): flashlight, kill icons, selection frame
    d.rectangle((2, 116, 27, 127), outline=200); put('flash_empty', 0, 112, 32, 20)
    d.rectangle((34, 116, 59, 127), fill=200); put('flash_full', 32, 112, 32, 20)
    d.rectangle((64, 118, 95, 125), fill=160); put('flash_beam', 64, 112, 32, 20)
    d.ellipse((104, 114, 121, 129), outline=255); d.rectangle((108, 126, 117, 131), fill=255)
    put('d_skull', 100, 112, 26, 20)
    d.ellipse((130, 114, 147, 131), outline=255); d.line((128, 122, 150, 122), fill=255)
    put('d_headshot', 126, 112, 26, 20)
    d.rectangle((152, 112, 255, 151), outline=255, width=2)
    put('selection', 152, 112, 104, 40)
    for w in WEAPONS:   # generic kill icon for every stock weapon name
        put('d_' + w, 0, 140, 48, 16)
    d.polygon([(2, 148), (40, 144), (46, 148), (40, 152)], fill=230)
    for nm in ('d_teammate', 'd_world', 'd_worldspawn', 'd_trigger_hurt', 'd_vexmira'):
        put(nm, 0, 140, 48, 16)
    # status: item pickups / title placeholders point at blank space
    for nm in ('title_half', 'title_life', 'item_battery', 'item_healthkit', 'item_longjump', 'item_kevlar',
               'item_assaultsuit', 'item_thighpack', 'radarcross', 'crosshair', 'autoaim'):
        put(nm, 240, 240, 16, 16)
    # radar (separate 128x128 sprite)
    radar = Image.new('L', (128, 128), 0)
    rd = ImageDraw.Draw(radar)
    rd.ellipse((1, 1, 126, 126), outline=180, width=2)
    rd.line((64, 8, 64, 120), fill=70); rd.line((8, 64, 120, 64), fill=70)
    radar_op = Image.new('L', (128, 128), 0)
    ImageDraw.Draw(radar_op).ellipse((1, 1, 126, 126), fill=40, outline=180, width=2)
    entries.append(('radar', '640radar_vexcl', 0, 0, 128, 128))
    entries.append(('radaropaque', '640radaro_vexcl', 0, 0, 128, 128))

    spr = os.path.join(out, 'cstrike', 'sprites')
    os.makedirs(spr, exist_ok=True)
    write_spr(os.path.join(spr, '640hud_vexcl.spr'), sheet)
    write_spr(os.path.join(spr, '640radar_vexcl.spr'), radar)
    write_spr(os.path.join(spr, '640radaro_vexcl.spr'), radar_op)
    lines = ['%d' % (len(entries) * 2)]
    for res in (320, 640):
        for name, sp, x, y, w, h in entries:
            lines.append('%-18s %d %-16s %d %d %d %d' % (name, res, sp, x, y, w, h))
    with open(os.path.join(spr, 'hud.txt'), 'w') as f:
        f.write('\n'.join(lines) + '\n')
    return sheet, len(entries)


def make_scope_arcs(out):
    """sprites/scope_arc{_nw,_ne,,_sw}.tga: quarter-circle masks (black outside, clear inside).
    cs16-client Host_Errors at connect when they are missing (sniperscope.cpp)."""
    n = 256
    centers = {'scope_arc_nw': (n, n), 'scope_arc_ne': (0, n), 'scope_arc': (0, 0), 'scope_arc_sw': (n, 0)}
    spr = os.path.join(out, 'cstrike', 'sprites')
    os.makedirs(spr, exist_ok=True)
    for name, (cx, cy) in centers.items():
        img = Image.new('RGBA', (n, n), (0, 0, 0, 255))
        mask = Image.new('L', (n * 4, n * 4), 0)
        ImageDraw.Draw(mask).ellipse(((cx - n) * 4, (cy - n) * 4, (cx + n) * 4, (cy + n) * 4), fill=255)
        mask = mask.resize((n, n), Image.LANCZOS)
        img.putalpha(Image.eval(mask, lambda v: 255 - v))
        img.save(os.path.join(spr, name + '.tga'))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--out', default=DEFAULT_OUT, help='client game root (contains valve/ and cstrike/)')
    ap.add_argument('--preview', help='also save the atlases as PNG into this directory')
    a = ap.parse_args()
    mono = os.path.join(DEJAVU, 'DejaVuSansMono.ttf')
    sans = os.path.join(DEJAVU, 'DejaVuSans.ttf')
    sansb = os.path.join(DEJAVU, 'DejaVuSans-Bold.ttf')
    conchars, conchars_img = fixed_conchars(mono)
    credits, credits_img = variable_font(sansb, 15)
    f0, f0i = variable_font(sans, 11)
    f1, f1i = variable_font(sans, 13)
    f2, f2i = variable_font(sansb, 15)
    write_wad(os.path.join(a.out, 'valve', 'gfx.wad'),
              [('conchars', TYP_QFONT, conchars), ('creditsfont', TYP_QFONT, credits)])
    write_wad(os.path.join(a.out, 'valve', 'fonts.wad'),
              [('font0', TYP_QFONT, f0), ('font1', TYP_QFONT, f1), ('font2', TYP_QFONT, f2),
               ('creditsfont', TYP_QFONT, credits)])
    hud_sheet, n_hud = make_hud(a.out)
    make_scope_arcs(a.out)
    print('[gfx] wrote %s/cstrike/sprites/hud.txt (%d names x 2 res) + 640hud_vexcl.spr + radar' % (a.out, n_hud))
    if a.preview:
        hud_sheet.save(os.path.join(a.preview, 'hud.png')) if a.preview else None
        os.makedirs(a.preview, exist_ok=True)
        for n, im in (('conchars', conchars_img), ('creditsfont', credits_img), ('font0', f0i),
                      ('font1', f1i), ('font2', f2i)):
            im.save(os.path.join(a.preview, n + '.png'))
    print('[gfx] wrote %s/valve/gfx.wad (conchars, creditsfont) and fonts.wad (font0-2, creditsfont)' % a.out)


if __name__ == '__main__':
    main()
