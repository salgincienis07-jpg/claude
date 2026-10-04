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
    print('=> %s' % ('EQUIVALENT (same program, code only moved)' if same else 'DIFFERENT program'))
    return 0 if same else 1


if __name__ == '__main__':
    sys.exit(main())
