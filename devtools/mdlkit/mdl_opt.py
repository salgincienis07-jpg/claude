"""Post-compile optimiser: share byte-identical animation blocks between sequences.

studiomdl writes, per sequence, one self-contained block [numblends*numbones mstudioanim_t headers]
[RLE values] whose offsets are relative to each header, so identical blocks can be shared by pointing
several seqdesc.animindex at one copy. The file is rebuilt and every absolute offset that lies after
the animation region is shifted. The result is verified by decoding every sequence of both files.

Layout written by studiomdl (write.c WriteFile): header, bones, bone controllers, attachments, hitboxes,
ANIMATIONS, seqdescs (+events, pivots), seqgroups, transitions, bodyparts/models/meshes/verts,
textures (+skinref, pixel data).
"""
import struct
import numpy as np

from .mdl_read import MDL


def _u32(b, o):
    return struct.unpack_from('<i', b, o)[0]


def dedupe_animations(path, out=None, verify=True):
    m = MDL(path)
    d = bytearray(m.data)
    seqs = m.seqs
    if not seqs:
        return 0
    starts = sorted(set(s['animindex'] for s in seqs))
    region_start = starts[0]
    region_end = m.seqindex
    if not (region_start < region_end):
        raise RuntimeError('unexpected layout (animation region not before seqdescs)')
    bounds = starts + [region_end]
    blocks = {}
    for a, b in zip(bounds[:-1], bounds[1:]):
        blocks[a] = bytes(d[a:b])
    # unique blocks in original order
    new_region = bytearray()
    new_off = {}
    seen = {}
    for a in starts:
        blk = blocks[a]
        if blk in seen:
            new_off[a] = seen[blk]
        else:
            off = region_start + len(new_region)
            seen[blk] = off
            new_off[a] = off
            new_region += blk
            while len(new_region) % 4:
                new_region += b'\0'
    delta = len(new_region) - (region_end - region_start)
    if delta == 0:
        if out and out != path:
            open(out, 'wb').write(m.data)
        return 0

    def sh(v):
        return v + delta if v >= region_end else v

    out_b = bytearray(d[:region_start]) + new_region + bytearray(d[region_end:])
    # header fields (offsets into the file)
    hdr_fields = {'boneindex': 144, 'bonecontrollerindex': 152, 'hitboxindex': 160, 'seqindex': 168,
                  'seqgroupindex': 176, 'textureindex': 184, 'texturedataindex': 188, 'skinindex': 200,
                  'bodypartindex': 208, 'attachmentindex': 216, 'soundindex': 224, 'soundgroupindex': 232,
                  'transitionindex': 240}
    for name, o in hdr_fields.items():
        v = _u32(d, o)
        if v:
            struct.pack_into('<i', out_b, o, sh(v))
    struct.pack_into('<i', out_b, 72, len(out_b))
    # seqdescs: positions shift too
    seqindex_new = sh(m.seqindex)
    for i, s in enumerate(seqs):
        o = seqindex_new + i * 176
        for fo in (32 + 20, 32 + 32, 88, 92):   # eventindex, pivotindex, automoveposindex, automoveangleindex
            v = _u32(out_b, o + fo)
            if v:
                struct.pack_into('<i', out_b, o + fo, sh(v))
        struct.pack_into('<i', out_b, o + 124, new_off[s['animindex']])
    # bodyparts / models / meshes
    bpi = sh(m.bodypartindex)
    for i in range(m.numbodyparts):
        o = bpi + i * 76
        nummodels = _u32(out_b, o + 64)
        mi = _u32(out_b, o + 72)
        struct.pack_into('<i', out_b, o + 72, sh(mi))
        mi2 = sh(mi)
        for j in range(nummodels):
            mo = mi2 + j * 112
            nummesh = _u32(out_b, mo + 72)
            for fo in (76, 84, 88, 96, 100, 108):   # meshindex vertinfoindex vertindex norminfoindex normindex groupindex
                v = _u32(out_b, mo + fo)
                if v:
                    struct.pack_into('<i', out_b, mo + fo, sh(v))
            mei = _u32(out_b, mo + 76)
            for k in range(nummesh):
                me = mei + k * 20
                for fo in (4, 16):   # triindex, normindex
                    v = _u32(out_b, me + fo)
                    if v:
                        struct.pack_into('<i', out_b, me + fo, sh(v))
    # textures
    ti = sh(m.textureindex)
    for i in range(m.numtextures):
        o = ti + i * 80
        v = _u32(out_b, o + 76)
        struct.pack_into('<i', out_b, o + 76, sh(v))
    out = out or path
    if verify:
        n = MDL(bytes(out_b))
        _verify_same(m, n)
    with open(out, 'wb') as f:
        f.write(out_b)
    return -delta


def _verify_same(a, b):
    assert a.numseq == b.numseq and a.numbones == b.numbones
    for i in range(a.numseq):
        for q in range(a.seqs[i]['numblends']):
            va = a.anim_values(i, q); vb = b.anim_values(i, q)
            if not np.array_equal(va, vb):
                raise RuntimeError('dedupe verification failed at seq %d blend %d' % (i, q))
        if a.seqs[i]['events'] != b.seqs[i]['events']:
            raise RuntimeError('events differ after dedupe (seq %d)' % i)
    for ta, tb in zip(a.textures, b.textures):
        if not (np.array_equal(ta['pixels'], tb['pixels']) and np.array_equal(ta['palette'], tb['palette'])):
            raise RuntimeError('texture changed after dedupe')
    for pa, pb in zip(a.bodyparts, b.bodyparts):
        for ma, mb in zip(pa['models'], pb['models']):
            if not (np.array_equal(ma['verts'], mb['verts']) and np.array_equal(ma['norms'], mb['norms'])):
                raise RuntimeError('vertices changed after dedupe')
            for xa, xb in zip(ma['meshes'], mb['meshes']):
                if xa['tris'] != xb['tris'] or xa['skinref'] != xb['skinref']:
                    raise RuntimeError('meshes changed after dedupe')
    for ha, hb in zip(a.hitboxes, b.hitboxes):
        if ha['bone'] != hb['bone'] or not np.allclose(ha['bbmin'], hb['bbmin']):
            raise RuntimeError('hitboxes changed')
    if a.attachments and [x['bone'] for x in a.attachments] != [x['bone'] for x in b.attachments]:
        raise RuntimeError('attachments changed')
