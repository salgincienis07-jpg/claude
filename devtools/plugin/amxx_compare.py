#!/usr/bin/env python3
"""amxx_compare.py - are two AMXX builds the same program?

    python3 devtools/plugin/amxx_compare.py old.amxx new.amxx

Prints the AMX segment sizes (header / code / data / debug) of both files and checks, for a
refactor that only MOVES code (e.g. splitting the .sma into vex/*.inc modules):
  * code / data / header sizes equal,
  * data segment = same multiset of cells (globals + string literals, order may differ),
  * every function compiles to the same instruction stream: functions are compared as a multiset,
    operands that are code/data addresses (calls, jumps, globals, literals) are ignored, native
    calls (sysreq.c) are compared by native NAME (the native table order follows first use).
Exit 0 = equivalent, 1 = different. Debug info (file names / line numbers) is never compared.
"""
import collections
import struct
import sys
import zlib

# AMX opcode -> (name, operand cells); from the AMXX 1.10 compiler (libpc300/sc6.c, opcodelist)
OPS = {
    1: ('load.pri', 1), 2: ('load.alt', 1), 3: ('load.s.pri', 1), 4: ('load.s.alt', 1), 5: ('lref.pri', 1),
    6: ('lref.alt', 1), 7: ('lref.s.pri', 1), 8: ('lref.s.alt', 1), 9: ('load.i', 0), 10: ('lodb.i', 1),
    11: ('const.pri', 1), 12: ('const.alt', 1), 13: ('addr.pri', 1), 14: ('addr.alt', 1),
    15: ('stor.pri', 1), 16: ('stor.alt', 1), 17: ('stor.s.pri', 1), 18: ('stor.s.alt', 1),
    19: ('sref.pri', 1), 20: ('sref.alt', 1), 21: ('sref.s.pri', 1), 22: ('sref.s.alt', 1),
    23: ('stor.i', 0), 24: ('strb.i', 1), 25: ('lidx', 0), 26: ('lidx.b', 1), 27: ('idxaddr', 0),
    28: ('idxaddr.b', 1), 29: ('align.pri', 1), 30: ('align.alt', 1), 31: ('lctrl', 1), 32: ('sctrl', 1),
    33: ('move.pri', 0), 34: ('move.alt', 0), 35: ('xchg', 0), 36: ('push.pri', 0), 37: ('push.alt', 0),
    38: ('push.r', 1), 39: ('push.c', 1), 40: ('push', 1), 41: ('push.s', 1), 42: ('pop.pri', 0),
    43: ('pop.alt', 0), 44: ('stack', 1), 45: ('heap', 1), 46: ('proc', 0), 47: ('ret', 0), 48: ('retn', 0),
    49: ('call', 1), 50: ('call.pri', 0), 51: ('jump', 1), 52: ('jrel', 1), 53: ('jzer', 1), 54: ('jnz', 1),
    55: ('jeq', 1), 56: ('jneq', 1), 57: ('jless', 1), 58: ('jleq', 1), 59: ('jgrtr', 1), 60: ('jgeq', 1),
    61: ('jsless', 1), 62: ('jsleq', 1), 63: ('jsgrtr', 1), 64: ('jsgeq', 1), 65: ('shl', 0), 66: ('shr', 0),
    67: ('sshr', 0), 68: ('shl.c.pri', 1), 69: ('shl.c.alt', 1), 70: ('shr.c.pri', 1), 71: ('shr.c.alt', 1),
    72: ('smul', 0), 73: ('sdiv', 0), 74: ('sdiv.alt', 0), 75: ('umul', 0), 76: ('udiv', 0),
    77: ('udiv.alt', 0), 78: ('add', 0), 79: ('sub', 0), 80: ('sub.alt', 0), 81: ('and', 0), 82: ('or', 0),
    83: ('xor', 0), 84: ('not', 0), 85: ('neg', 0), 86: ('invert', 0), 87: ('add.c', 1), 88: ('smul.c', 1),
    89: ('zero.pri', 0), 90: ('zero.alt', 0), 91: ('zero', 1), 92: ('zero.s', 1), 93: ('sign.pri', 0),
    94: ('sign.alt', 0), 95: ('eq', 0), 96: ('neq', 0), 97: ('less', 0), 98: ('leq', 0), 99: ('grtr', 0),
    100: ('geq', 0), 101: ('sless', 0), 102: ('sleq', 0), 103: ('sgrtr', 0), 104: ('sgeq', 0),
    105: ('eq.c.pri', 1), 106: ('eq.c.alt', 1), 107: ('inc.pri', 0), 108: ('inc.alt', 0), 109: ('inc', 1),
    110: ('inc.s', 1), 111: ('inc.i', 0), 112: ('dec.pri', 0), 113: ('dec.alt', 0), 114: ('dec', 1),
    115: ('dec.s', 1), 116: ('dec.i', 0), 117: ('movs', 1), 118: ('cmps', 1), 119: ('fill', 1),
    120: ('halt', 1), 121: ('bounds', 1), 122: ('sysreq.pri', 0), 123: ('sysreq.c', 1), 125: ('line', 2),
    127: ('srange', 2), 128: ('jump.pri', 0), 129: ('switch', 1), 130: ('casetbl', 0), 131: ('swap.pri', 0),
    132: ('swap.alt', 0), 133: ('pushaddr', 1), 134: ('nop', 0), 135: ('sysreq.d', 1), 136: ('symtag', 1),
    137: ('break', 0),
}

# opcodes whose operand is an address (code or data) -> ignored when comparing functions
ADDR_OPS = {'const.pri', 'const.alt', 'push.c', 'call', 'jump', 'jzer', 'jnz', 'jeq', 'jneq', 'jless', 'jleq',
            'jgrtr', 'jgeq', 'jsless', 'jsleq', 'jsgrtr', 'jsgeq', 'switch', 'load.pri', 'load.alt',
            'stor.pri', 'stor.alt', 'push', 'inc', 'dec', 'zero', 'load.i', 'lref.pri', 'lref.alt',
            'sref.pri', 'sref.alt', 'addr.pri', 'addr.alt', 'pushaddr'}


def load(path):
    d = open(path, 'rb').read()
    magic, ver, n = struct.unpack('<IHB', d[:7])
    if magic != 0x414d5858:
        raise SystemExit('%s: not an .amxx file' % path)
    off = 7
    for _ in range(n):
        cellsize, disksize, imagesize, memsize, offs = struct.unpack('<BIIII', d[off:off + 17])
        off += 17
        if cellsize == 4:
            return zlib.decompress(d[offs:offs + disksize])
    raise SystemExit('%s: no 32-bit section' % path)


def analyse(path):
    img = load(path)
    (size, _magic, _fv, _av, _flags, defsize, cod, dat, hea, stp, _cip, publics, natives, libraries,
     _pubvars, _tags, _nametable) = struct.unpack('<iHBBhhiiiiiiiiiii', img[:56])
    names = []
    for o in range(natives, libraries, defsize):
        _addr, nofs = struct.unpack('<ii', img[o:o + 8])
        names.append(img[nofs:img.index(b'\0', nofs)].decode())
    code = struct.unpack('<%di' % ((dat - cod) // 4), img[cod:dat])
    funcs, cur, k = [], [], 0
    funcs.append(cur)
    while k < len(code):
        op = code[k]
        if op == 46:                                  # proc: a new function starts
            cur = []
            funcs.append(cur)
        if op == 130:                                 # casetbl: n, default, n x (value, address)
            n = code[k + 1]
            cur.append(('casetbl', n) + tuple(code[k + 3 + 2 * i] for i in range(n)))
            k += 3 + 2 * n
            continue
        name, nargs = OPS[op]
        args = code[k + 1:k + 1 + nargs]
        if name == 'sysreq.c':
            cur.append((name, names[args[0]]))
        elif name in ADDR_OPS:
            cur.append((name,))
        else:
            cur.append((name,) + tuple(args))
        k += 1 + nargs
    return {
        'header': cod, 'code': dat - cod, 'data': hea - dat, 'stack': stp - hea,
        'debug': len(img) - size, 'funcs': collections.Counter(tuple(f) for f in funcs), 'nfuncs': len(funcs) - 1,
        'datacells': collections.Counter(struct.unpack('<%di' % ((hea - dat) // 4), img[dat:hea])),
        'natives': sorted(names),
    }


# ----------------------------------------------------------------------------- symbolic check
# Uses the debug info (amxdbg.h: files, lines, symbols) that amxxpc writes by default. Every
# function is compared BY NAME, with each address operand replaced by what it points to:
#   call -> callee name, jumps / switch / case table -> offset inside the function,
#   global / static variable -> (name, offset), string / array literal -> its cells,
#   sysreq.c -> native name.
# This also catches what the multiset check above cannot see (a call to another function or a
# load from another global with the same opcode shape).
CODE_OPS = {'jump', 'jzer', 'jnz', 'jeq', 'jneq', 'jless', 'jleq', 'jgrtr', 'jgeq', 'jsless', 'jsleq',
            'jsgrtr', 'jsgeq', 'switch'}
DATA_OPS = {'load.pri', 'load.alt', 'stor.pri', 'stor.alt', 'lref.pri', 'lref.alt', 'sref.pri', 'sref.alt',
            'inc', 'dec', 'zero', 'push'}
MAYBE_DATA_OPS = {'const.pri', 'const.alt', 'push.c'}      # a number or the address of a global / literal


def parse_debug(img, size):
    """-> (files, symbols) from the amxdbg block behind the AMX image; symbols are tuples
    (address, codestart, codeend, ident, vclass, dims, name)."""
    d = img[size:]
    if len(d) < 22:
        return None
    (_dsize, magic, _fv, _av, _flags, nfiles, nlines, nsyms, _ntags, _naut, _nst) = struct.unpack('<iHbbhhhhhhh', d[:22])
    if magic != 0xf1ef:
        return None
    o, files = 22, []
    for _ in range(nfiles & 0xffff):
        addr = struct.unpack('<I', d[o:o + 4])[0]
        e = d.index(b'\0', o + 4)
        files.append((addr, d[o + 4:e].decode('utf-8', 'replace')))
        o = e + 1
    o += (nlines & 0xffff) * 8
    syms = []
    for _ in range(nsyms & 0xffff):
        addr, _tag, cs, ce, ident, vclass, ndim = struct.unpack('<IhIIbbh', d[o:o + 18])
        e = d.index(b'\0', o + 18)
        name = d[o + 18:e].decode('utf-8', 'replace')
        o = e + 1
        dims = []
        for _ in range(ndim):
            dims.append(struct.unpack('<hI', d[o:o + 6])[1])
            o += 6
        syms.append((addr, cs, ce, ident, vclass, tuple(dims), name))
    return files, syms


def symbolic(path):
    img = load(path)
    (size, _magic, _fv, _av, _flags, defsize, cod, dat, hea, _stp, _cip, publics, natives, libraries,
     _pubvars, _tags, _nametable) = struct.unpack('<iHBBhhiiiiiiiiiii', img[:56])
    dbg = parse_debug(img, size)
    if dbg is None:
        return None
    _files, syms = dbg
    natnames = []
    for o in range(natives, libraries, defsize):
        _addr, nofs = struct.unpack('<ii', img[o:o + 8])
        natnames.append(img[nofs:img.index(b'\0', nofs)].decode())
    pubs = {}
    for o in range(publics, natives, defsize):
        addr, nofs = struct.unpack('<ii', img[o:o + 8])
        pubs[img[nofs:img.index(b'\0', nofs)].decode()] = addr
    code = struct.unpack('<%di' % ((dat - cod) // 4), img[cod:dat])
    data = struct.unpack('<%di' % ((hea - dat) // 4), img[dat:hea])
    ncell = len(data)

    funcs = sorted((s[0], s[2], s[6]) for s in syms if s[3] == 9)          # (start, end, name)
    fname = {}
    seen = collections.Counter()
    for start, _end, name in funcs:
        seen[name] += 1
        fname[start] = name if seen[name] == 1 else '%s#%d' % (name, seen[name])

    def owner(cs):
        for start, end, name in funcs:
            if start <= cs < end:
                return fname[start]
        return None

    def extent(addr, dims):
        """cells of a global: plain variable / 1-D array from dims, multi-dim arrays by walking the
        indirection vectors (ragged string tables have an open last dimension)."""
        if not dims:
            return 1
        if len(dims) == 1:
            return max(dims[0], 1)
        base = addr // 4
        end = base + dims[0]
        for i in range(dims[0]):
            if base + i >= ncell:
                break
            row = (addr + 4 * i + data[base + i]) // 4
            sub = extent(row * 4, dims[1:]) if len(dims) > 2 or dims[1] else None
            if sub is None:                                   # open last dimension: up to the 0 cell
                k = row
                while k < ncell and data[k] != 0:
                    k += 1
                sub = k - row + 1
            end = max(end, row + sub)
        return end - base

    gvars = []                                                  # (start cell, end cell, key)
    for addr, cs, _ce, ident, vclass, dims, name in syms:
        if ident in (1, 3) and vclass in (0, 2):
            own = owner(cs) if vclass == 2 else None
            key = '%s::%s' % (own, name) if own else name
            gvars.append((addr // 4, addr // 4 + extent(addr, dims), key, dims))
    gvars.sort()
    starts = [g[0] for g in gvars]

    import bisect

    def resolve_data(addr):
        if addr % 4 or not 0 <= addr < ncell * 4:
            return ('#', addr)
        c = addr // 4
        i = bisect.bisect_right(starts, c) - 1
        if i >= 0 and gvars[i][0] <= c < gvars[i][1]:
            return ('G', gvars[i][2], c - gvars[i][0])
        k, lit = c, []                                          # literal: its cells up to the 0 cell
        while k < ncell and len(lit) < 512:
            lit.append(data[k])
            if data[k] == 0:
                break
            k += 1
        return ('L', tuple(lit))

    out = {}
    for start, end, _name in funcs:
        k, toks = start // 4, []
        stop = end // 4
        while k < stop:
            op = code[k]
            if op == 130:
                n = code[k + 1]
                toks.append(('casetbl', n, code[k + 2] - start) +
                            tuple((code[k + 3 + 2 * i], code[k + 4 + 2 * i] - start) for i in range(n)))
                k += 3 + 2 * n
                continue
            name, nargs = OPS[op]
            args = code[k + 1:k + 1 + nargs]
            if name == 'call':
                toks.append((name, fname.get(args[0], '?%d' % args[0])))
            elif name in CODE_OPS:
                toks.append((name, args[0] - start))
            elif name in DATA_OPS:
                toks.append((name, resolve_data(args[0])))
            elif name in MAYBE_DATA_OPS:
                toks.append((name, args[0], resolve_data(args[0])))
            elif name == 'sysreq.c':
                toks.append((name, natnames[args[0]]))
            else:
                toks.append((name,) + tuple(args))
            k += 1 + nargs
        out[fname[start]] = toks
    gcontent = {key: (dims, data[s:e]) for s, e, key, dims in gvars}
    return {'funcs': out, 'globals': gcontent,
            'publics': {p: fname.get(a, '?%d' % a) for p, a in pubs.items()}}


def same_tok(x, y):
    """const.pri / const.alt / push.c: equal when they point to the same global / literal, or when
    they are the same number that is not an address in either build."""
    if x == y:
        return True
    if len(x) == 3 and len(y) == 3 and x[0] == y[0] and x[0] in MAYBE_DATA_OPS:
        if x[2][0] in 'GL' and x[2] == y[2]:
            return True
    return False


def symbolic_compare(pa, pb, show=8):
    a, b = symbolic(pa), symbolic(pb)
    if a is None or b is None:
        print('symbolic check: no debug info in one of the files (compile without -d0)')
        return None
    ok = True
    fa, fb = set(a['funcs']), set(b['funcs'])
    if fa != fb:
        ok = False
        print('functions only in A: %s' % sorted(fa - fb)[:show])
        print('functions only in B: %s' % sorted(fb - fa)[:show])
    bad = []
    for f in sorted(fa & fb):
        ta, tb = a['funcs'][f], b['funcs'][f]
        if len(ta) != len(tb) or not all(same_tok(x, y) for x, y in zip(ta, tb)):
            bad.append(f)
            if len(bad) <= show:
                for i, (x, y) in enumerate(zip(ta, tb)):
                    if not same_tok(x, y):
                        print('  %s: instruction %d: %r != %r' % (f, i, x, y))
                        break
                else:
                    print('  %s: %d vs %d instructions' % (f, len(ta), len(tb)))
    ga, gb = a['globals'], b['globals']
    gbad = sorted(k for k in set(ga) | set(gb) if ga.get(k) != gb.get(k))
    pbad = sorted(k for k in set(a['publics']) | set(b['publics']) if a['publics'].get(k) != b['publics'].get(k))
    print('%-48s %s' % ('functions by name (%d, operands resolved)' % len(fa & fb),
                        'same' if not bad and fa == fb else 'DIFFERENT (%d)' % len(bad)))
    print('%-48s %s' % ('globals by name (%d, size + initial value)' % len(set(ga) & set(gb)),
                        'same' if not gbad else 'DIFFERENT %s' % gbad[:show]))
    print('%-48s %s' % ('publics -> function', 'same' if not pbad else 'DIFFERENT %s' % pbad[:show]))
    return ok and not bad and not gbad and not pbad


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    a, b = analyse(sys.argv[1]), analyse(sys.argv[2])
    print('%-10s %12s %12s' % ('', 'A', 'B'))
    for key in ('header', 'code', 'data', 'stack', 'debug', 'nfuncs'):
        print('%-10s %12d %12d%s' % (key, a[key], b[key], '' if a[key] == b[key] or key == 'debug' else '   <-- differs'))
    checks = [
        ('sizes (header/code/data/stack)', all(a[k] == b[k] for k in ('header', 'code', 'data', 'stack'))),
        ('natives', a['natives'] == b['natives']),
        ('data cells (multiset)', a['datacells'] == b['datacells']),
        ('functions (address-normalised code, multiset)', a['funcs'] == b['funcs']),
    ]
    for name, ok in checks:
        print('%-48s %s' % (name, 'same' if ok else 'DIFFERENT'))
    if a['funcs'] != b['funcs']:
        print('functions only in A: %d, only in B: %d' % (sum((a['funcs'] - b['funcs']).values()),
                                                         sum((b['funcs'] - a['funcs']).values())))
    same = all(ok for _, ok in checks)
    sym = symbolic_compare(sys.argv[1], sys.argv[2])
    if sym is False:
        same = False
    print('=> %s' % ('EQUIVALENT (same program, code only moved)' if same else 'DIFFERENT program'))
    return 0 if same else 1


if __name__ == '__main__':
    sys.exit(main())
