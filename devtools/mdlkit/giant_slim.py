"""Reference implementation of the 5.3.4 giant-boss "slim" copy (the plugin does the same in Pawn, GmSlim534).

A giant boss copy is downloaded by every player, so it is made smaller than the original:
  * weapon sequences the boss never plays ((ref|crouch)_(aim|shoot|shoot2|reload)_<weapon>, weapon != knife)
    keep their seqdesc (names / indices stay identical) but point at the matching knife sequence's
    animation block; the now unreferenced blocks are cut out of the file;
  * textures larger than max_tex are downscaled by a power of two (nearest texel, palette kept) and the
    s/t texel coordinates of the meshes that use them are scaled with them.
Every absolute offset in the file is remapped. Layout independent (no assumption on section order).

    python3 -m mdlkit.giant_slim in.mdl out.mdl [max_tex]
"""
import re
import struct
import sys

WEAPON_SEQ = re.compile(r'^(ref|crouch)_(aim|shoot|shoot2|reload)_(.+)$')


def _i(d, o):
    return struct.unpack_from('<i', d, o)[0]


def slim(src, max_tex=256):
    d = bytearray(src)
    if _i(d, 0) != 0x54534449 or _i(d, 4) != 10:
        return None
    length = len(d)
    ptr = []                       # positions of absolute offset fields

    def P(pos, cond=True):
        if cond and 0 < _i(d, pos) <= length:
            ptr.append(pos)
    hdr = dict(nb=_i(d, 140), ns=_i(d, 164), si=_i(d, 168), nsg=_i(d, 172), sgi=_i(d, 176), nt=_i(d, 180),
               ti=_i(d, 184), nsr=_i(d, 192), nsf=_i(d, 196), ski=_i(d, 200), nbp=_i(d, 204), bpi=_i(d, 208))
    for o in (144, 152, 160, 168, 176, 184, 188, 200, 208, 216, 224, 232, 240):
        P(o)
    ns = hdr['ns']
    seqs = []
    for q in range(ns):
        o = hdr['si'] + q * 176
        lab = d[o:o + 32].split(b'\0')[0].decode('latin-1').lower()
        seqs.append(dict(o=o, lab=lab, ai=_i(d, o + 124), sg=_i(d, o + 156)))
        P(o + 52, _i(d, o + 48) > 0)
        P(o + 64, _i(d, o + 60) > 0)
        P(o + 88); P(o + 92)
    for b in range(hdr['nbp']):
        o = hdr['bpi'] + b * 76
        nm, mi = _i(d, o + 64), _i(d, o + 72)
        P(o + 72)
        for m in range(nm):
            mo = mi + m * 112
            for f in (76, 84, 88, 96, 100, 108):
                P(mo + f)
            for k in range(_i(d, mo + 72)):
                me = _i(d, mo + 76) + k * 20
                P(me + 4); P(me + 16)
    for t in range(hdr['nt']):
        P(hdr['ti'] + t * 80 + 76)
    # anim blocks are only cut when everything is in seqgroup 0 at data offset 0
    anim_ok = ns > 0 and all(s['sg'] == 0 for s in seqs) and (hdr['nsg'] < 1 or _i(d, hdr['sgi'] + 100) == 0)
    if not anim_ok:
        return bytes(d)            # external / offset sequence groups: copy unchanged
    starts = set(_i(d, p) for p in ptr) | {length} | set(s['ai'] for s in seqs if 0 < s['ai'] < length)

    def end_of(a):
        return min(x for x in starts if x > a)
    segs = []                      # (start, end, new_bytes)
    redirect = {}
    if True:
        by = {s['lab']: s for s in seqs}
        for s in seqs:
            m = WEAPON_SEQ.match(s['lab'])
            if not m or m.group(3) == 'knife' or m.group(3).endswith('knife'):
                continue
            tgt = by.get('%s_%s_knife' % (m.group(1), 'shoot' if m.group(2).startswith('shoot') else 'aim'))
            if tgt is not None and tgt['ai'] != s['ai']:
                redirect[s['o']] = tgt
        keep = set(s['ai'] for s in seqs if s['o'] not in redirect)
        for a in sorted(set(s['ai'] for s in seqs if s['o'] in redirect) - keep):
            segs.append((a, end_of(a), b''))
    # textures
    tex_ratio = {}
    if hdr['nt'] > 0 and max_tex >= 16:
        facs = []
        for t in range(hdr['nt']):
            o = hdr['ti'] + t * 80
            fl, w, h, ix = struct.unpack_from('<4i', d, o + 64)
            f = 1
            if not (fl & 2):           # chrome textures stay
                while max(w, h) // f > max_tex and w // (f * 2) >= 16 and h // (f * 2) >= 16:
                    f *= 2
            if ix + w * h + 768 > end_of(ix):
                f = 1
            facs.append(f)
        if hdr['nsf'] > 1:             # several skin families: one factor for all
            g = min(facs)
            facs = [g] * len(facs)
        for t, f in enumerate(facs):
            if f == 1:
                continue
            o = hdr['ti'] + t * 80
            fl, w, h, ix = struct.unpack_from('<4i', d, o + 64)
            nw, nh = w // f, h // f
            px = bytearray(nw * nh)
            for y in range(nh):
                row = ix + y * f * w
                px[y * nw:(y + 1) * nw] = d[row:row + w][0:nw * f:f]
            segs.append((ix, ix + w * h + 768, bytes(px) + bytes(d[ix + w * h:ix + w * h + 768])))
            struct.pack_into('<ii', d, o + 68, nw, nh)
            tex_ratio[t] = (nw / w, nh / h)
    if not segs:
        return bytes(d)
    segs.sort()
    for a, b in zip(segs, segs[1:]):
        if a[1] > b[0]:
            return None

    def remap(off):
        r = off
        for a, b, nb in segs:
            if b <= off:
                r -= (b - a) - len(nb)
            elif a <= off:
                break
        return r
    # redirect seqdescs (fields copied from the knife sequence): fps, numframes, numblends, animindex,
    # blendtype/start/end, blendparent
    for o, tgt in redirect.items():
        t = tgt['o']
        d[o + 32:o + 36] = d[t + 32:t + 36]
        d[o + 56:o + 60] = d[t + 56:t + 60]
        d[o + 120:o + 156] = d[t + 120:t + 156]
    animpos = [s['o'] + 124 for s in seqs]
    for p in ptr + animpos:
        struct.pack_into('<i', d, p, remap(_i(d, p)))
    out = bytearray()
    pos = 0
    for a, b, nb in segs:
        out += d[pos:a]; out += nb; pos = b
    out += d[pos:]
    struct.pack_into('<i', out, 72, len(out))
    if tex_ratio:
        _scale_st(out, tex_ratio)
    return bytes(out)


def _scale_st(d, tex_ratio):
    nbp, bpi, nsr, ski = _i(d, 204), _i(d, 208), _i(d, 192), _i(d, 200)
    done = set()
    for b in range(nbp):
        o = bpi + b * 76
        for m in range(_i(d, o + 64)):
            mo = _i(d, o + 72) + m * 112
            for k in range(_i(d, mo + 72)):
                me = _i(d, mo + 76) + k * 20
                tri, sref = _i(d, me + 4), _i(d, me + 8)
                if tri in done or not (0 <= sref < nsr):
                    continue
                tex = struct.unpack_from('<h', d, ski + sref * 2)[0]
                if tex not in tex_ratio:
                    continue
                done.add(tri)
                rs, rt = tex_ratio[tex]
                p = tri
                while True:
                    n = struct.unpack_from('<h', d, p)[0]; p += 2
                    if n == 0:
                        break
                    for _ in range(abs(n)):
                        s, t = struct.unpack_from('<2h', d, p + 4)
                        struct.pack_into('<2h', d, p + 4, int(s * rs), int(t * rt))
                        p += 8


if __name__ == '__main__':
    src = open(sys.argv[1], 'rb').read()
    res = slim(src, int(sys.argv[3]) if len(sys.argv) > 3 else 256)
    if res is None:
        sys.exit('not slimmed')
    open(sys.argv[2], 'wb').write(res)
    print('%d -> %d bytes (%.0f%%)' % (len(src), len(res), 100.0 * len(res) / len(src)))
