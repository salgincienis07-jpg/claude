#!/usr/bin/env python3
"""Build the VEXMIRA iPad stylesheet for the CS 1.6 MOTD browser (Chromium 18).

cstrike/vexmira_web/src/ipad.src.css  ->  cstrike/vexmira_web/ipad.css.js  (window.VXCSS template)

* linear-gradient(<modern angle>, ...)  -> -webkit-linear-gradient(<legacy angle>, ...)
* radial-gradient(<legacy args>)         -> -webkit-radial-gradient(...)   (source already uses legacy args)
* transform / transition / animation / filter / user-select get their -webkit- twin
* @keyframes are emitted twice (@-webkit-keyframes with -webkit-transform inside)
* var(--x) stays in the template; ipad.js fills it per theme / accent and injects a <style>.
Both very old (Chromium 18) and current Chromium render the -webkit- gradient syntax.
"""
import re, json, os, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'cstrike', 'vexmira_web')
SRC = os.path.join(ROOT, 'src', 'ipad.src.css')
OUT = os.path.join(ROOT, 'ipad.css.js')

PREFIX_PROPS = ('transform', 'transition', 'animation', 'animation-duration', 'animation-delay', 'animation-name',
                'animation-direction', 'animation-iteration-count', 'animation-timing-function', 'filter', 'user-select')


def split_args(s):
    out, depth, cur = [], 0, ''
    for ch in s:
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        if ch == ',' and depth == 0:
            out.append(cur.strip()); cur = ''
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def find_call(s, name, start=0):
    i = s.find(name + '(', start)
    if i < 0:
        return None
    j = i + len(name) + 1; depth = 1
    while j < len(s) and depth:
        if s[j] == '(':
            depth += 1
        elif s[j] == ')':
            depth -= 1
        j += 1
    return i, j


SIDES = {'to bottom': 'top', 'to top': 'bottom', 'to right': 'left', 'to left': 'right'}


def conv_linear(args):
    a = args[0]
    m = re.match(r'^(-?[\d.]+)deg$', a)
    if m:
        legacy = 90 - float(m.group(1))
        legacy = ((legacy + 180) % 360) - 180
        return ['%gdeg' % legacy] + args[1:]
    if a in SIDES:
        return [SIDES[a]] + args[1:]
    return ['top'] + args  # default: to bottom


def convert_value(v):
    for name in ('repeating-linear-gradient', 'linear-gradient', 'radial-gradient'):
        pos = 0
        while True:
            f = find_call(v, name, pos)
            if not f:
                break
            i, j = f
            if v[max(0, i - 8):i] == '-webkit-':
                pos = j; continue
            inner = v[i + len(name) + 1:j - 1]
            args = split_args(inner)
            if 'linear' in name:
                args = conv_linear(args)
            rep = '-webkit-' + name + '(' + ','.join(args) + ')'
            v = v[:i] + rep + v[j:]
            pos = i + len(rep)
    return v


def process_decls(body, in_keyframes=False):
    out = []
    for decl in [d for d in body.split(';') if d.strip()]:
        if ':' not in decl:
            out.append(decl); continue
        p, v = decl.split(':', 1)
        p = p.strip(); v = v.strip()
        if 'gradient(' in v:
            v = convert_value(v)
        if p in PREFIX_PROPS:
            wv = v.replace('transform', '-webkit-transform') if p.startswith('transition') else v
            out.append('-webkit-%s:%s' % (p, wv))
        out.append('%s:%s' % (p, v))
    return ';'.join(out)


def process(css):
    css = re.sub(r'/\*.*?\*/', '', css, flags=re.S)
    res, i = [], 0
    while i < len(css):
        if css.startswith('@keyframes', i):
            j = css.index('{', i); name = css[i + 10:j].strip()
            depth, k = 1, j + 1
            while depth:
                if css[k] == '{': depth += 1
                elif css[k] == '}': depth -= 1
                k += 1
            inner = css[j + 1:k - 1]
            frames = re.findall(r'([^{}]+)\{([^}]*)\}', inner)
            std = ''.join('%s{%s}' % (s.strip(), process_decls(b, True)) for s, b in frames)
            wk = ''.join('%s{%s}' % (s.strip(), process_decls(b, True).replace('transform:', '-webkit-transform:').replace('-webkit--webkit-', '-webkit-')) for s, b in frames)
            res.append('@-webkit-keyframes %s{%s}@keyframes %s{%s}' % (name, wk, name, std))
            i = k; continue
        if css.startswith('@media', i):
            j = css.index('{', i); head = css[i:j]
            depth, k = 1, j + 1
            while depth:
                if css[k] == '{': depth += 1
                elif css[k] == '}': depth -= 1
                k += 1
            res.append(head + '{' + process(css[j + 1:k - 1]) + '}')
            i = k; continue
        j = css.find('{', i)
        if j < 0:
            break
        k = css.index('}', j)
        sel = css[i:j].strip()
        res.append('%s{%s}' % (sel, process_decls(css[j + 1:k])))
        i = k + 1
    return ''.join(res)


def main():
    src = open(SRC, encoding='utf-8').read()
    out = process(src)
    bad = [w for w in ('display:grid', 'display:flex', ' gap:', 'inset:', 'vh;', 'vw;', 'min(', 'clamp(', 'aspect-ratio', 'backdrop-filter', 'conic-gradient') if w in out]
    if bad:
        print('WARNING: unsupported in Chromium 18:', bad)
    with open(OUT, 'w', encoding='utf-8') as f:
        f.write('/* generated by devtools/tablet/build_web.py from src/ipad.src.css - do not edit */\nwindow.VXCSS=' + json.dumps(out) + ';\n')
    print('ipad.css.js: %d bytes css' % len(out))


if __name__ == '__main__':
    main()
