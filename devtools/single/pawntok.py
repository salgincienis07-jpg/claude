"""Minimal Pawn (AMX Mod X dialect) tokenizer used by make_single.py.

Tokens are (kind, text) pairs; joining all texts gives the input back unchanged.
kinds: ws, nl, comment, str, chr, ident, num, punct
The escape character is '^' (AMXX default ctrlchar).
"""
import re

_IDENT = re.compile(r'[A-Za-z_@][A-Za-z0-9_@]*')
_NUM = re.compile(r'[0-9][A-Za-z0-9_.]*')
_WS = re.compile(r'[ \t\r\f\v]+')


def tokenize(src):
    toks = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == '\n':
            toks.append(('nl', c)); i += 1; continue
        m = _WS.match(src, i)
        if m:
            toks.append(('ws', m.group())); i = m.end(); continue
        if src.startswith('//', i):
            j = src.find('\n', i)
            j = n if j < 0 else j
            toks.append(('comment', src[i:j])); i = j; continue
        if src.startswith('/*', i):
            j = src.find('*/', i + 2)
            j = n if j < 0 else j + 2
            toks.append(('comment', src[i:j])); i = j; continue
        if c == '"':
            j = i + 1
            while j < n and src[j] != '"' and src[j] != '\n':
                if src[j] == '^' and j + 1 < n and src[j + 1] != '\n':
                    j += 2
                else:
                    j += 1
            j = min(j + 1, n)
            toks.append(('str', src[i:j])); i = j; continue
        if c == "'":
            j = i + 1
            while j < n and src[j] != "'" and src[j] != '\n':
                if src[j] == '^' and j + 1 < n:
                    j += 2
                else:
                    j += 1
            j = min(j + 1, n)
            toks.append(('chr', src[i:j])); i = j; continue
        m = _IDENT.match(src, i)
        if m:
            toks.append(('ident', m.group())); i = m.end(); continue
        m = _NUM.match(src, i)
        if m:
            toks.append(('num', m.group())); i = m.end(); continue
        toks.append(('punct', c)); i += 1
    return toks


def join(toks):
    return ''.join(t for _k, t in toks)


def idents(src):
    return {t for k, t in tokenize(src) if k == 'ident'}


def sig(toks, i, step=1):
    """index of the next significant token from i (inclusive) in direction step, or -1"""
    n = len(toks)
    while 0 <= i < n:
        if toks[i][0] not in ('ws', 'nl', 'comment'):
            return i
        i += step
    return -1


def match_paren(toks, i):
    """toks[i] is '(' / '[' / '{'; return index of the matching closer"""
    o = toks[i][1]
    c = {'(': ')', '[': ']', '{': '}'}[o]
    d = 0
    for j in range(i, len(toks)):
        k, t = toks[j]
        if k != 'punct':
            continue
        if t == o:
            d += 1
        elif t == c:
            d -= 1
            if d == 0:
                return j
    raise ValueError('unbalanced %s at token %d' % (o, i))


def split_args(toks, lp, rp):
    """argument token lists of a call whose parens are toks[lp] / toks[rp]"""
    args, cur, d = [], [], 0
    for j in range(lp + 1, rp):
        k, t = toks[j]
        if k == 'punct' and t in '([{':
            d += 1
        elif k == 'punct' and t in ')]}':
            d -= 1
        if d == 0 and k == 'punct' and t == ',':
            args.append(cur); cur = []
            continue
        cur.append(toks[j])
    if cur or args:
        args.append(cur)
    return args


def find_calls(toks, name):
    """yield (ident_index, lparen_index, rparen_index) for every call/definition `name(`"""
    out = []
    for i, (k, t) in enumerate(toks):
        if k == 'ident' and t == name:
            p = sig(toks, i - 1, -1)
            if p >= 0 and toks[p] == ('punct', '.'):
                continue
            j = sig(toks, i + 1)
            if j >= 0 and toks[j] == ('punct', '('):
                out.append((i, j, match_paren(toks, j)))
    return out
