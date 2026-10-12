#!/usr/bin/env python3
"""Build the single-file Vexmira plugin  scripting/zombie_core.sma  from the v4.2 multi-file sources.

  python3 devtools/single/make_single.py [--out PATH] [--inc DIR]

What it does (see the header comment of the generated file for the runtime side):
  * core: scripting/vexmira_core.sma with the vex_*.inc files and ReAPI (+ cssdk_const) inlined;
    natives / callfunc / filename lookups replaced by a component table (ZcCall).
  * 14 item plugins become internal modules: every identifier the module defines gets a module
    prefix (jan_, pla_, ...), string literals naming a module function are renamed with it,
    AMXX forwards (plugin_init, plugin_precache, client_putinserver, client_disconnect[ed]) are
    called by one dispatcher, tasks get a per-module id range (remove_task() can no longer hit
    another module's or the core's tasks), identical FM forwards / CurWeapon events of several
    modules are hooked once and dispatched in Pawn.
  * precache of a missing file never happens in a module: the module is switched off instead.
  * configs/vexmira.cfg, configs/vexmira_maps/*.ini, configs/vexmira_motd_*.html and
    data/lang/vexmira_zombie.txt are embedded and written out at plugin_precache when absent.
"""
import argparse
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pawntok as P  # noqa: E402

REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
AMX = os.path.join(REPO, 'cstrike', 'addons', 'amxmodx')
SCR = os.path.join(AMX, 'scripting')
SP = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad'
DEF_INC = os.path.join(SP, 'tools', 'bin', 'include')

VERSION = '4.3.0-Single'

# key, source, component id (0 = not a shop component)
MODS = [
    ('jan', 'vx42_janus7', 1),
    ('pla', 'vx42_plasma', 2),
    ('thb', 'vx42_thunderbolt', 3),
    ('eth', 'vx42_ethereal', 4),
    ('sal', 'vx42_salamander', 5),
    ('bow', 'vx42_bow', 6),
    ('drs', 'vx42_dragonsword', 7),
    ('kat', 'vx42_katana', 8),
    ('lsb', 'vx42_lightsaber', 9),
    ('hax', 'vx42_horseaxe', 10),
    ('hev', 'vx42_hev', 11),
    ('jet', 'vx42_jetpack', 12),
    ('mgn', 'vx42_minigun', 13),
    ('diag', 'vx42_diagnostic', 0),
]

STD_INCLUDES = ['amxmodx', 'amxmisc', 'engine', 'fakemeta', 'fakemeta_util', 'hamsandwich', 'fun',
                'cstrike', 'xs', 'nvault', 'geoip']

FORWARDS = ['plugin_init', 'plugin_precache', 'plugin_cfg', 'plugin_end', 'plugin_natives',
            'client_putinserver', 'client_disconnect', 'client_disconnected', 'client_connect',
            'client_authorized', 'client_command', 'client_infochanged']

# item-plugin natives -> core functions (taking id directly)
NATMAP = {
    'is_zombie': 'CommunityNativeZombie',
    'is_extra_weapon': 'CommunityNativeWeapon',
    'knife_allowed': 'CommunityNativeKnife',
    'restore_appearance': 'CommunityNativeRestore',
    'has_jetpack': 'CommunityNativeJetpack',
    'prepare_jetpack': 'CommunityNativePrepareJet',
    'is_survivor': 'CommunityNativeSurvivor',
}
CORE_DEFS = set()
IFACE = ['vex_give', 'vex_has', 'vex_remove', 'vex_infected']

PAWN_KEYWORDS = set('''new static const stock public forward native enum if else for while do switch case default
return break continue goto sizeof tagof defined char true false operator state sleep exit assert
define include tryinclude endinput pragma undef endif elseif emit error Float bool any _'''.split())

# FM forwards that may be dispatched (signature of the dispatcher; parameter tags matter)
FM_SIGS = {
    ('FM_TraceLine', 0): ['Float:@[3]', 'Float:@[3]', '@', '@', '@'],
    ('FM_TraceHull', 0): ['Float:@[3]', 'Float:@[3]', '@', '@', '@', '@'],
    ('FM_CmdStart', 0): ['@', '@', '@'],
    ('FM_UpdateClientData', 1): ['@', '@', '@'],
    ('FM_EmitSound', 0): ['@', '@', '@[]', 'Float:@', 'Float:@', '@', '@'],
    ('FM_PlaybackEvent', 0): ['@', '@', '@', 'Float:@', 'Float:@[3]', 'Float:@[3]', 'Float:@', 'Float:@',
                              '@', '@', '@', '@'],
    ('FM_SetModel', 0): ['@', '@[]'],
    ('FM_PlayerPreThink', 0): ['@'],
}


def die(msg):
    print('make_single: ERROR: ' + msg)
    sys.exit(1)


def read(p):
    with open(p, encoding='latin-1') as fh:
        return fh.read()


# ------------------------------------------------------------------------------------------ includes
def strip_guard(txt, name):
    """remove the '#if defined _x_included / #endinput / #endif / #define _x_included' guard"""
    txt2 = re.sub(r'#if\s+defined\s+\w+\s*\n\s*#endinput\s*\n\s*#endif\s*\n\s*#define\s+\w+[^\n]*\n', '', txt, count=1)
    if '#endinput' in txt2:
        die('include guard of %s not understood' % name)
    return txt2


def inline_reapi(incdir):
    seen = set()

    def one(name):
        if name in seen:
            return ''
        seen.add(name)
        p = os.path.join(incdir, name + '.inc')
        txt = strip_guard(read(p), name)
        out = []
        for line in txt.split('\n'):
            m = re.match(r'\s*#include\s*[<"]([\w./]+?)(?:\.inc)?[>"]', line)
            if m:
                inc = os.path.basename(m.group(1))
                if inc.startswith('reapi') or inc == 'cssdk_const':
                    out.append(one(inc))
                    continue
                if inc in STD_INCLUDES:
                    out.append('// (std) ' + line.strip())
                    continue
                die('unexpected include %s in %s' % (inc, name))
            out.append(line)
        return '// ---- inlined %s.inc ----\n' % name + '\n'.join(out) + '\n'
    return one('reapi')


def exclusion_set(incdir):
    ex = set(PAWN_KEYWORDS)
    for p in glob.glob(os.path.join(incdir, '*.inc')):
        b = os.path.basename(p)
        if b.startswith('reapi') or b == 'cssdk_const.inc':
            continue        # modules never included ReAPI: names they share with it are renamed
        ex |= P.idents(read(p))
    ex |= P.idents(asset_guard_src())
    return ex


def asset_guard_src():
    g = read(os.path.join(SCR, 'include', 'vex_asset_guard.inc'))
    fatal = ('log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); '
             'set_fail_state(required); return false;')
    n = g.count(fatal)
    if n < 10:
        die('asset guard fatal pattern not found (%d)' % n)
    g = g.replace(fatal, 'log_amx("[AssetGuard] %s -> %s modulu KAPALI, sunucu calismaya devam ediyor (dosyayi sunucuya ve FastDL e yukle)",'
                         'required,scope); g_zcGuardFail=true; return false;')
    g = g.replace('stock VexPcSnd(const s[], bool:emitted)\n{\n    if (emitted) { precache_sound(s); return; }',
                  'stock VexPcSnd(const s[], bool:emitted)\n{\n    if (emitted) { ZcPcSound(s); return; }')
    if 'ZcPcSound' not in g:
        die('VexPcSnd pattern')
    return g


# ------------------------------------------------------------------------------------------ module parse
def statement_end(toks, i):
    """index of the token that ends the statement starting at i (';' or a newline at depth 0 that
    does not follow ',' '=' or an opening bracket)"""
    d = 0
    last = None
    for j in range(i, len(toks)):
        k, t = toks[j]
        if k == 'punct':
            if t in '([{':
                d += 1
            elif t in ')]}':
                d -= 1
            elif t == ';' and d == 0:
                return j
        if k == 'nl' and d == 0 and last is not None and last not in (',', '=', '(', '[', '{', '+', '-', '*', '|', '&', '?', ':'):
            return j
        if k not in ('ws', 'nl', 'comment'):
            last = t
    return len(toks)


def module_defs(toks):
    """names the module defines at file level: macros, globals, enum members/tags, functions"""
    names, funcs = set(), set()
    depth = 0
    pdepth = 0
    i, n = 0, len(toks)
    line_start = True
    while i < n:
        k, t = toks[i]
        if k == 'nl':
            line_start = True
            i += 1
            continue
        if k in ('ws', 'comment'):
            i += 1
            continue
        if line_start and t == '#':
            j = P.sig(toks, i + 1)
            if toks[j][1] == 'define':
                m = P.sig(toks, j + 1)
                names.add(toks[m][1])
            while i < n and toks[i][0] != 'nl':
                if toks[i][1] == '\\' and P.sig(toks, i + 1) != -1 and toks[i + 1][0] == 'nl':
                    i += 2
                    continue
                i += 1
            continue
        line_start = False
        if k == 'punct' and t == '{':
            depth += 1
        elif k == 'punct' and t == '}':
            depth -= 1
        elif k == 'punct' and t in '([':
            pdepth += 1
        elif k == 'punct' and t in ')]':
            pdepth -= 1
        elif depth == 0 and pdepth == 0 and k == 'ident':
            if t in ('new', 'static', 'const') and not is_func_head(toks, i):
                e = statement_end(toks, i)
                names |= declarators(toks, i + 1, e)
                i = e
                continue
            if t == 'enum':
                j = P.sig(toks, i + 1)
                while toks[j][0] == 'ident' or toks[j][1] == ':':
                    if toks[j][0] == 'ident' and toks[j][1] != '_':
                        names.add(toks[j][1])
                    j = P.sig(toks, j + 1)
                if toks[j][1] == '(':
                    j = P.sig(toks, P.match_paren(toks, j) + 1)
                if toks[j][1] != '{':
                    die('enum parse at %r' % P.join(toks[i:i + 20]))
                e = P.match_paren(toks, j)
                expect = True
                d2 = 0
                for q in range(j + 1, e):
                    kk, tt = toks[q]
                    if kk == 'punct' and tt in '([{':
                        d2 += 1
                    elif kk == 'punct' and tt in ')]}':
                        d2 -= 1
                    elif d2 == 0 and kk == 'punct' and tt == ',':
                        expect = True
                    elif d2 == 0 and expect and kk == 'ident':
                        nx = P.sig(toks, q + 1)
                        if toks[nx][1] == ':':
                            continue        # tag
                        names.add(tt)
                        expect = False
                i = e + 1
                continue
            pv = P.sig(toks, i - 1, -1)
            first = pv < 0 or any(toks[q][0] == 'nl' for q in range(pv + 1, i)) or toks[pv][1] in (';', '}')
            if t in ('public', 'stock', 'forward') or (first and is_func_head(toks, i)):
                f = func_name_at(toks, i)
                if f:
                    funcs.add(f)
        i += 1
    return names | funcs, funcs


def is_func_head(toks, i):
    return func_name_at(toks, i) is not None


def func_name_at(toks, i):
    """if the tokens from i look like '[public|stock|static] [Tag:]name(' return name"""
    j = i
    while toks[j][1] in ('public', 'stock', 'static', 'forward'):
        j = P.sig(toks, j + 1)
    if toks[j][0] != 'ident':
        return None
    nx = P.sig(toks, j + 1)
    if toks[nx][1] == ':':
        j = P.sig(toks, nx + 1)
        if toks[j][0] != 'ident':
            return None
        nx = P.sig(toks, j + 1)
    if toks[nx][1] == '(':
        return toks[j][1]
    return None


def declarators(toks, a, e):
    out = set()
    expect = True
    d = 0
    in_init = False
    j = a
    while j < e:
        k, t = toks[j]
        if k == 'punct' and t in '([{':
            d += 1
        elif k == 'punct' and t in ')]}':
            d -= 1
        elif d == 0 and k == 'punct' and t == ',':
            expect, in_init = True, False
        elif d == 0 and k == 'punct' and t == '=':
            in_init = True
        elif d == 0 and expect and not in_init and k == 'ident' and t not in ('const', 'static', 'new'):
            nx = P.sig(toks, j + 1)
            if toks[nx][1] != ':':
                out.add(t)
                expect = False
        j += 1
    return out


def func_def(toks, name):
    """(name_idx, lparen, rparen, body_open, body_close) of the definition of `name`"""
    for (i, lp, rp) in P.find_calls(toks, name):
        b = P.sig(toks, rp + 1)
        if b < 0:
            continue
        pv = P.sig(toks, i - 1, -1)
        if pv >= 0 and toks[pv][1] == ':':
            pv = P.sig(toks, P.sig(toks, pv - 1, -1) - 1, -1)
        at_line = pv < 0 or toks[pv][1] in ('public', 'stock', 'static', '}', ';') or \
            any(toks[q][0] == 'nl' for q in range(pv + 1, i))
        if not at_line:
            continue
        if toks[b][1] == '{':
            return i, lp, rp, b, P.match_paren(toks, b)
        if toks[b][0] in ('ident',):     # single statement body
            return i, lp, rp, b, None
    return None


def params_of(toks, lp, rp):
    out = []
    for a in P.split_args(toks, lp, rp):
        s = P.join(a).strip()
        if not s:
            continue
        s = re.sub(r'\s*=.*$', '', s, flags=re.S)
        float_tag = bool(re.search(r'\bFloat\s*:', s))
        nm = re.findall(r'([A-Za-z_@]\w*)\s*(?:\[[^\]]*\]\s*)*$', s)
        out.append((nm[0] if nm else None, float_tag, s))
    return out


def returns_value(toks, b, e):
    if e is None:
        return False
    for j in range(b, e):
        if toks[j] == ('ident', 'return'):
            nx = P.sig(toks, j + 1)
            if toks[nx][1] not in (';', '}'):
                # 'return' followed by a newline then '}' counts as void
                if any(toks[q][0] == 'nl' for q in range(j + 1, nx)) and toks[nx][1] == '}':
                    continue
                return True
    return False


# ------------------------------------------------------------------------------------------ modules
class Mod:
    pass


def process_module(idx, key, srcname, comp, excl, report):
    m = Mod()
    m.idx, m.key, m.src, m.comp = idx, key, srcname, comp
    m.pfx = key + '_'
    m.taskoff = (idx + 1) << 24
    txt = read(os.path.join(SCR, srcname + '.sma'))
    # includes / pragmas
    txt = re.sub(r'(?m)^[ \t]*#include[^\n]*$', '', txt)
    txt = re.sub(r'(?m)^[ \t]*#pragma[ \t]+dynamic[^\n]*$', '', txt)
    # component registration and plugin registration
    txt, nrc = re.subn(r'\bvex_register_component\s*\(\s*\d+\s*\)\s*;?', '', txt)
    if comp and nrc != 1:
        die('%s: vex_register_component x%d' % (srcname, nrc))
    txt, nrp = re.subn(r'\bregister_plugin\s*\((?:[^()"\n]|"(?:\^.|[^"^\n])*")*\)\s*;?', '', txt)
    if nrp != 1:
        die('%s: register_plugin x%d' % (srcname, nrp))
    toks = P.tokenize(txt)
    # natives -> core functions
    for i, (k, t) in enumerate(toks):
        if k == 'ident':
            for pre in ('vex_', 'vx42_'):
                if t.startswith(pre) and t[len(pre):] in NATMAP:
                    toks[i] = ('ident', NATMAP[t[len(pre):]])
    defs, funcs = module_defs(toks)
    publics = set(re.findall(r'\bpublic\s+(?:\w+\s*:\s*)?(\w+)\s*\(', P.join([t for t in toks if t[0] != 'comment'])))
    used = {t for k, t in toks if k == 'ident'}
    protect = set(NATMAP.values()) | {'g_zcGuardFail', 'VexAssetGuard', 'VexPcSnd'}
    ren = {}
    for name in (used - excl) | defs:
        if name in protect or name in PAWN_KEYWORDS:
            continue
        if name in FORWARDS:
            if name in funcs:
                ren[name] = m.pfx + name
            continue
        if name in excl and name not in defs and name not in CORE_DEFS:
            continue
        ren[name] = m.pfx + name
    import hashlib
    for a, b in list(ren.items()):
        if len(b) > 31:
            h = hashlib.md5(a.encode()).hexdigest()[:3]
            ren[a] = b[:27] + '_' + h
    if len(set(ren.values())) != len(ren):
        die('%s: rename collision' % srcname)
    m.forwards = [f for f in FORWARDS if f in funcs]
    m.iface = [f for f in IFACE if f in funcs]
    fun_new = {ren.get(f, f) for f in funcs}
    renamed_strings = set()
    for i, (k, t) in enumerate(toks):
        if k == 'ident' and t in ren:
            p = P.sig(toks, i - 1, -1)
            if p >= 0 and toks[p] == ('punct', '.') and t not in defs:
                continue    # named argument of a std native
            toks[i] = ('ident', ren[t])
        elif k == 'str':
            inner = t[1:-1]
            if inner in publics and inner in ren:
                toks[i] = ('str', '"%s"' % ren[inner])
                renamed_strings.add(inner)
    report.append('%s: %d identifiers renamed, %d function-name strings renamed: %s' % (
        srcname, len(ren), len(renamed_strings), ', '.join(sorted(renamed_strings))))
    m.funcs = fun_new
    m.toks = toks
    return m


def transform_tasks(m, report):
    toks = m.toks
    OFF = 'ZC_TOFF_%s' % m.key.upper()
    callbacks = set()
    edits = []      # (start, end, replacement token list)
    for name in ('set_task', 'remove_task', 'task_exists', 'change_task'):
        for (i, lp, rp) in P.find_calls(toks, name):
            args = P.split_args(toks, lp, rp)
            pos = 2 if name == 'set_task' else 0
            if name == 'set_task':
                cb = P.join(args[1]).strip()
                if not (cb.startswith('"') and cb.endswith('"')):
                    die('%s: set_task with non-literal callback %s' % (m.src, cb))
                callbacks.add(cb[1:-1])
            newargs = [P.join(a) for a in args]
            if len(newargs) <= pos:
                newargs += [''] * (pos + 1 - len(newargs))
            cur = newargs[pos].strip()
            if cur in ('', '_', '0'):
                newargs[pos] = ' ' + OFF
            else:
                newargs[pos] = ' (%s) + %s' % (cur, OFF)
            edits.append((lp, rp, [('punct', '(')] + P.tokenize(','.join(newargs)) + [('punct', ')')]))
    for (a, b, rep) in sorted(edits, key=lambda e: -e[0]):
        toks[a:b + 1] = rep
    # prologue in task callbacks: undo the offset
    for cb in sorted(callbacks):
        fd = func_def(toks, cb)
        if not fd:
            die('%s: task callback %s not found' % (m.src, cb))
        i, lp, rp, b, e = fd
        ps = params_of(toks, lp, rp)
        if not ps:
            continue
        pname = ps[-1][0]
        pro = ' if (%s >= %s && %s < %s + 0x1000000) %s -= %s; ' % (pname, OFF, pname, OFF, pname, OFF)
        if e is None:
            # single statement body: wrap in braces
            se = statement_end(toks, b)
            toks[se:se] = [('punct', ' }')]
            toks[b:b] = P.tokenize('{' + pro)
        else:
            toks[b + 1:b + 1] = P.tokenize(pro)
    report.append('%s: tasks -> id range %s=0x%X, callbacks: %s' % (m.src, OFF, m.taskoff, ', '.join(sorted(callbacks))))


def transform_precache(m):
    toks = m.toks
    edits = []
    for (i, lp, rp) in P.find_calls(toks, 'engfunc'):
        args = P.split_args(toks, lp, rp)
        a0 = P.join(args[0]).strip()
        mp = {'EngFunc_PrecacheModel': 'ZcPcModel', 'EngFunc_PrecacheSound': 'ZcPcSound',
              'EngFunc_PrecacheGeneric': 'ZcPcGeneric'}
        if a0 in mp:
            rest = ','.join(P.join(a) for a in args[1:])
            edits.append((i, rp, P.tokenize('%s(%s)' % (mp[a0], rest.strip()))))
    for (a, b, rep) in sorted(edits, key=lambda e: -e[0]):
        toks[a:b + 1] = rep
    for i, (k, t) in enumerate(toks):
        if k == 'ident' and t in ('precache_model', 'precache_sound', 'precache_generic'):
            toks[i] = ('ident', {'precache_model': 'ZcPcModel', 'precache_sound': 'ZcPcSound',
                                 'precache_generic': 'ZcPcGeneric'}[t])


def collect_hooks(m, fm_hooks, ev_hooks):
    """register_forward(FM_x, "cb"[, post]) / register_event("CurWeapon", "cb", "be", "1=1") statements"""
    toks = m.toks
    edits = []
    for (i, lp, rp) in P.find_calls(toks, 'register_forward'):
        pv = P.sig(toks, i - 1, -1)
        if pv >= 0 and toks[pv][1] not in (';', '{', '}', ')') and not any(toks[q][0] == 'nl' for q in range(pv + 1, i)):
            continue        # return value used
        args = [P.join(a).strip() for a in P.split_args(toks, lp, rp)]
        post = 1 if len(args) > 2 and args[2] in ('1', 'true') else 0
        key = (args[0], post)
        if key not in FM_SIGS:
            continue
        fm_hooks.setdefault(key, []).append((m, args[1].strip('"')))
        edits.append((i, rp, key))
    for (i, lp, rp) in P.find_calls(toks, 'register_event'):
        args = [P.join(a).strip() for a in P.split_args(toks, lp, rp)]
        if args[0] == '"CurWeapon"' and args[2:] == ['"be"', '"1=1"']:
            ev_hooks.append((m, args[1].strip('"')))
            edits.append((i, rp, 'CurWeapon'))
    for (a, b, key) in sorted(edits, key=lambda e: -e[0]):
        if key == 'CurWeapon':
            rep = 'g_zcEvCurWeapon |= (1<<%d)' % m.idx
        else:
            rep = 'g_zcFm[%s] |= (1<<%d)' % (fm_slot(key), m.idx)
        toks[a:b + 1] = P.tokenize(rep)


def fm_slot(key):
    return 'ZCFM_%s%s' % (key[0][3:], '_P' if key[1] else '')


def handler_info(m, fname):
    fd = func_def(m.toks, fname)
    if not fd:
        die('%s: handler %s not found' % (m.src, fname))
    i, lp, rp, b, e = fd
    return params_of(m.toks, lp, rp), returns_value(m.toks, b, e)


def gen_dispatchers(fm_hooks, ev_hooks, mods):
    out = []
    keys = sorted(fm_hooks)
    out.append('enum { %s, ZCFM_COUNT };' % ', '.join(fm_slot(k) for k in keys))
    out.append('new g_zcFm[ZCFM_COUNT], g_zcEvCurWeapon;')
    body = []
    for key in keys:
        sigp = FM_SIGS[key]
        params = [s.replace('@', 'a%d' % (n + 1)) for n, s in enumerate(sigp)]
        pnames = ['a%d' % (n + 1) for n in range(len(sigp))]
        ptags = [s.startswith('Float:') for s in sigp]
        fn = 'ZcFmD_%s%s' % (key[0][3:], '_P' if key[1] else '')
        body.append('public %s(%s)\n{' % (fn, ', '.join(params)))
        body.append('    new m = g_zcFm[%s], r = FMRES_IGNORED, t;\n    #pragma unused t' % fm_slot(key))
        for (mod, h) in fm_hooks[key]:
            ps, rv = handler_info(mod, h)
            args = []
            for n, (pn, fl, raw) in enumerate(ps):
                a = pnames[n]
                if '[' not in raw and fl != ptags[n]:
                    a = ('Float:' if fl else '_:') + a
                args.append(a)
            call = '%s(%s)' % (h, ', '.join(args))
            if rv:
                body.append('    if (m & (1<<%d)) { t = %s; if (t > r) r = t; }' % (mod.idx, call))
            else:
                body.append('    if (m & (1<<%d)) %s;' % (mod.idx, call))
        body.append('    return r;\n}')
    body.append('public ZcEvD_CurWeapon(id)\n{\n    new m = g_zcEvCurWeapon;')
    for (mod, h) in ev_hooks:
        ps, rv = handler_info(mod, h)
        body.append('    if (m & (1<<%d)) %s(%s);' % (mod.idx, h, 'id' if ps else ''))
    body.append('}')
    reg = ['ZcRegisterDispatchers()\n{']
    for key in keys:
        fn = 'ZcFmD_%s%s' % (key[0][3:], '_P' if key[1] else '')
        reg.append('    if (g_zcFm[%s]) register_forward(%s, "%s"%s);' % (fm_slot(key), key[0], fn, ', 1' if key[1] else ''))
    reg.append('    if (g_zcEvCurWeapon) register_event("CurWeapon", "ZcEvD_CurWeapon", "be", "1=1");')
    reg.append('}')
    return '\n'.join(out), '\n'.join(body + reg)


# ------------------------------------------------------------------------------------------ core
def rep1(txt, old, new, count=1):
    n = txt.count(old)
    if n != count:
        die('core patch: expected %d x %r, found %d' % (count, old[:80], n))
    return txt.replace(old, new)


def subn1(txt, pat, new, count=None, flags=0):
    txt2, n = re.subn(pat, new, txt, flags=flags)
    if n == 0 or (count is not None and n != count):
        die('core patch regex %r: %d matches' % (pat[:80], n))
    return txt2


def build_core():
    core = read(os.path.join(SCR, 'vexmira_core.sma'))
    for inc in ('vex_community_core', 'vex_event_sounds', 'vex_normal_world', 'vex_restore_features'):
        core = rep1(core, '#include "include/%s.inc"' % inc,
                    '// ---- inlined %s.inc ----\n%s' % (inc, read(os.path.join(SCR, 'include', inc + '.inc'))))
    core = rep1(core, '''#include <amxmodx>
#include "include/vex_asset_guard.inc"
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <nvault>
#include <reapi>
#include <geoip>

#pragma dynamic 32768
''', '@@ZC_HEADER@@\n')
    core = rep1(core, '#define VERSION  "4.2.0"', '#define VERSION  "%s"' % VERSION)
    # forwards owned by the dispatcher
    for f in ('plugin_init', 'plugin_precache', 'client_putinserver', 'client_disconnected'):
        core = subn1(core, r'(?m)^public %s\(' % f, 'ZcCore_%s(' % f, count=1)
    # natives -> plain functions
    core = rep1(core, '''    register_library("vx42_community");
    register_native("vx42_register_component", "CommunityRegisterComponent");
    register_native("vx42_prepare_jetpack", "CommunityNativePrepareJet");
    register_native("vx42_has_jetpack", "CommunityNativeJetpack");
    register_native("vx42_is_survivor", "CommunityNativeSurvivor");
    register_native("vx42_is_zombie", "CommunityNativeZombie");
    register_native("vx42_is_extra_weapon", "CommunityNativeWeapon");
    register_native("vx42_knife_allowed", "CommunityNativeKnife");
    register_native("vx42_restore_appearance", "CommunityNativeRestore");
''', '    // 4.3: no natives - the item modules are compiled in (component table ZcCall).\n')
    core = subn1(core, r'public (CommunityNative\w+)\(plugin,\s*params\)\s*\{\s*new id=get_param\(1\);', r'\1(id) {', count=7)
    # component registry / filename lookup / callfunc -> component table
    a = core.index('new g_CommunityComponents[13];')
    b = core.index('CommunityAlive(id) {')
    core = core[:a] + '''// 4.3.0-Single: items are internal modules. ZcCall(component, op, id) calls them directly
// (component ids: 1-6 special weapons in COMMUNITY_WP order, 7-10 knives in COMMUNITY_KP order,
// 11 HEV, 12 Jetpack, 13 Minigun). A module whose assets are missing is off (ZcCompOn()==false).
''' + core[b:]
    core = subn1(core, r'CommunityCall\(\s*COMMUNITY_WP\[([^\]]+)\]\s*,\s*"vex_(\w+)"\s*,', r'ZcCall((\1)+1, ZCOP_\2,')
    core = subn1(core, r'CommunityCall\(\s*COMMUNITY_KP\[([^\]]+)\]\s*,\s*"vex_(\w+)"\s*,', r'ZcCall((\1)+7, ZCOP_\2,')
    core = subn1(core, r'CommunityCall\(\s*"vx42_(\w+)\.amxx"\s*,\s*"vex_(\w+)"\s*,', lambda mm: 'ZcCall(ZC_%s, ZCOP_%s,' % (mm.group(1).upper(), mm.group(2)))
    core = rep1(core, 'ok=CommunityCall(sel==10?"vx42_jetpack.amxx":"vx42_hev.amxx","vex_give",target);',
                'ok=ZcCall(sel==10?ZC_JETPACK:ZC_HEV,ZCOP_give,target);')
    core = rep1(core, '''    new plugin[32]; copy(plugin,charsmax(plugin),i?"vx42_hev.amxx":"vx42_jetpack.amxx");
    if(CommunityCall(plugin,"vex_has",id)) { Chat(id,"SHOP_ALREADY"); return; }
    if(!CommunityCall(plugin,"vex_give",id)) { Chat(id,"SHOP_UNAVAIL"); return; }''',
                '''    new comp=i?ZC_HEV:ZC_JETPACK;
    if(ZcCall(comp,ZCOP_has,id)) { Chat(id,"SHOP_ALREADY"); return; }
    if(!ZcCompOn(comp)) { client_print_color(id,print_team_default,"^4[Vexmira]^1 %s %L",i?"HEV":"Jetpack",id,"ZC_ITEM_OFF"); return; }
    if(!ZcCall(comp,ZCOP_give,id)) { Chat(id,"SHOP_UNAVAIL"); return; }''')
    core = rep1(core, '''    new index=CommunityPluginIndex(COMMUNITY_WP[i]);
    if(index<0 || get_func_id("vex_give",index)<0) {
        client_print_color(id,print_team_default,"^4[Vexmira]^1 %s eklentisi hazir degil. Yonetici: vex_status",COMMUNITY_WN[i]);
        log_amx("[Community] unavailable component %s; run vex_status",COMMUNITY_WP[i]); return;
    }''', '''    if(!ZcCompOn(i+1)) {
        client_print_color(id,print_team_default,"^4[Vexmira]^1 %s %L",COMMUNITY_WN[i],id,"ZC_ITEM_OFF");
        log_amx("[Community] module off (missing asset): %s; run vex_status",COMMUNITY_WN[i]); return;
    }''')
    core = rep1(core, 'console_print(id,"[Community] weapon=%s plugin_loaded=%d",COMMUNITY_WN[sw],CommunityPluginIndex(COMMUNITY_WP[sw])>=0);',
                'console_print(id,"[Community] weapon=%s module_on=%d",COMMUNITY_WN[sw],ZcCompOn(sw+1));')
    a = core.index('    static const filenames[13][]={"vx42_janus7.amxx"')
    b = core.index('    console_print(id,"Cosmetics ready:')
    core = core[:a] + '''    ZcModuleStatus(id);
''' + core[b:]
    if 'CommunityCall' in core or 'CommunityPluginIndex' in core or 'callfunc_begin_i(function' in core:
        die('core still has CommunityCall / CommunityPluginIndex')
    # duplicate guard: only OLD multi-file Vexmira plugins are paused
    a = core.index('stock bool:VexIsOldCopy(')
    b = core.index('public CommunityJetCommand(id)')
    core = core[:a] + DUP_GUARD + '\n' + core[b:]
    core = rep1(core, 'server_print("[Vexmira] Vexmira Zombie Core v%s yuklendi (vexmira_core.amxx + plugins-vexmira42.ini)", VERSION);',
                'server_print("[Vexmira] Vexmira Zombie Core v%s yuklendi (tek dosya: zombie_core.amxx, modul: %d/14 acik)", VERSION, ZcModulesOn());')
    return core


DUP_GUARD = r'''// 4.3.0-Single: every item is compiled into this plugin. Old multi-file Vexmira plugins (any name the
// panel gave them) would hook everything twice, so they are paused with a loud warning.
// The test is by file name pattern / plugin title, never by our own file name (the panel may rename us).
stock bool:VexIsOldCopy(const file[], const title[], const ver[])
{
    new lower[128]; copy(lower, charsmax(lower), file); strtolower(lower);
    if (containi(lower, "vexmira_zombie") != -1 || containi(lower, "vexmirazombie") != -1) return true;
    if (containi(lower, "vexmira_core") != -1 || containi(lower, "vexmiracore") != -1) return true;
    // vex_*.amxx / vx42_*.amxx and panel copies like 12_vex_janus7.amxx, 3vx42janus7.amxx
    if (containi(lower, "vx42") != -1) return true;
    new base[128]; copy(base, charsmax(base), lower);
    new s = 0; while (base[s] >= '0' && base[s] <= '9') s++;
    while (base[s] == '_' || base[s] == '-') s++;
    if (equal(base[s], "vex_", 4) || equal(base[s], "vex", 3) && !equal(base[s], "vexprobe", 8)) {
        if (containi(base[s], ".amxx") != -1) return true;
    }
    // an older core under any file name (same title, other version)
    if (equal(title, PLUGIN) && !equal(ver, VERSION)) return true;
    if (containi(title, "Vexmira Independent Diagnostic") != -1) return true;
    return false;
}

VexDuplicateGuard()
{
    new self = get_plugin(-1);
    new file[128], title[96], ver[32], author[64], status[32], list[512], n;
    for (new k = 0; k < get_pluginsnum(); k++)
    {
        if (k == self) continue;
        if (get_plugin(k, file, charsmax(file), title, charsmax(title), ver, charsmax(ver), author, charsmax(author), status, charsmax(status)) == -1)
            continue;
        new bool:dup = VexIsOldCopy(file, title, ver);
        // a second copy of this single plugin (same title + version): the first one loaded wins
        if (!dup && equal(title, PLUGIN) && equal(ver, VERSION) && k > self) dup = true;
        if (!dup) continue;
        if (equal(status, "running") || equal(status, "debug"))
            pause("ac", file);
        format(list, charsmax(list), "%s%s%s (%s v%s)", list, n ? ", " : "", file, title, ver);
        n++;
    }
    if (n)
    {
        log_amx("[Vexmira] !!! UYARI: %d ESKI/CIFT Vexmira eklentisi bulundu ve DURAKLATILDI: %s", n, list);
        log_amx("[Vexmira] !!! Bunlari plugins klasorunden ve plugins.ini / plugins-vexmira*.ini satirlarindan SILIN; zombie_core.amxx tek basina yeterli.");
        server_print("[Vexmira] !!! WARNING: %d old/duplicate Vexmira plugin(s) PAUSED: %s", n, list);
        server_print("[Vexmira] !!! Delete them and their plugins.ini lines (and configs/plugins-vexmira*.ini); zombie_core.amxx alone is enough.");
    }
}
'''


# ------------------------------------------------------------------------------------------ embedded files
def pawn_str(s):
    s = s.replace('\r', '')
    s = s.replace('^', '^^').replace('"', '^"').replace('\t', '^t')
    return '"%s"' % s


def embed(name, path):
    lines = read(path).split('\n')
    if lines and lines[-1] == '':
        lines.pop()
    body = ',\n'.join(pawn_str(l) for l in lines) if lines else '""'
    return 'new const %s[][] = {\n%s\n};\n' % (name, body)


def embedded_files():
    """[(array name, kind, relative path)] kind: cfg (configs dir), lang (data/lang)"""
    out = [('ZC_F_CFG', 'cfg', 'vexmira.cfg', os.path.join(AMX, 'configs', 'vexmira.cfg')),
           ('ZC_F_LANG', 'lang', 'vexmira_zombie.txt', os.path.join(AMX, 'data', 'lang', 'vexmira_zombie.txt'))]
    for p in sorted(glob.glob(os.path.join(AMX, 'configs', 'vexmira_motd_*.html'))):
        b = os.path.basename(p)
        out.append(('ZC_F_MOTD_' + b[len('vexmira_motd_'):-5].upper(), 'cfg', b, p))
    for p in sorted(glob.glob(os.path.join(AMX, 'configs', 'vexmira_maps', '*.ini'))):
        b = os.path.basename(p)
        out.append(('ZC_F_MAP_' + re.sub(r'\W', '_', b[:-4]).upper()[:20], 'cfg', 'vexmira_maps/' + b, p))
    return out


# ------------------------------------------------------------------------------------------ main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(SCR, 'zombie_core.sma'))
    ap.add_argument('--inc', default=DEF_INC)
    ap.add_argument('--report', action='store_true')
    args = ap.parse_args()

    report = []
    core_txt = build_core()
    CORE_DEFS.update(module_defs(P.tokenize(core_txt))[0])
    excl = exclusion_set(args.inc)
    excl |= {'COMMUNITY_WP'}
    mods = []
    fm_hooks, ev_hooks = {}, []
    for idx, (key, src, comp) in enumerate(MODS):
        m = process_module(idx, key, src, comp, excl, report)
        transform_tasks(m, report)
        transform_precache(m)
        collect_hooks(m, fm_hooks, ev_hooks)
        mods.append(m)
    for key in list(fm_hooks):
        if len(fm_hooks[key]) < 2:          # single user: keep the module's own registration
            (mm, h) = fm_hooks.pop(key)[0]
            fix = 'g_zcFm[%s] |= (1<<%d)' % (fm_slot(key), mm.idx)
            txt = P.join(mm.toks)
            txt = rep1(txt, fix, 'register_forward(%s, "%s"%s)' % (key[0], h, ', 1' if key[1] else ''))
            mm.toks = P.tokenize(txt)
    disp_decl, disp_body = gen_dispatchers(fm_hooks, ev_hooks, mods)

    core = core_txt
    header = HEADER.replace('@@VERSION@@', VERSION)
    header += '\n'.join('#include <%s>' % i for i in STD_INCLUDES) + '\n\n#pragma dynamic 32768\n\n'
    header += inline_reapi(args.inc)
    header += '\n// ==================================================================== zombie_core glue (declarations)\n'
    header += PRE_GLUE.replace('@@MODCOUNT@@', str(len(mods)))
    for m in mods:
        header += '#define ZC_TOFF_%s 0x%X\n' % (m.key.upper(), m.taskoff)
    header += disp_decl + '\n'
    header += '\n// ---- inlined vex_asset_guard.inc (4.3: a missing asset switches only that module off) ----\n'
    header += asset_guard_src()
    core = core.replace('@@ZC_HEADER@@', header)

    parts = [core]
    for m in mods:
        parts.append('\n\n/* %s\n   MODULE %-4s  from %s.sma  (prefix %s, component %d, task ids 0x%X..)\n   %s */\n' % (
            '=' * 96, m.key, m.src, m.pfx, m.comp, m.taskoff, '=' * 96))
        parts.append(P.join(m.toks))
    parts.append('\n\n/* %s\n   GLUE: forward dispatchers, component table, embedded configs\n   %s */\n' % ('=' * 96, '=' * 96))
    parts.append(gen_glue(mods))
    parts.append(disp_body + '\n')
    files = embedded_files()
    for (nm, kind, rel, p) in files:
        parts.append(embed(nm, p))
    parts.append(gen_writer(files))
    out = ''.join(parts)
    out = re.sub(r'[ \t]+\n', '\n', out)
    with open(args.out, 'w', encoding='latin-1', newline='\n') as fh:
        fh.write(out)
    print('make_single: wrote %s (%d lines, %d bytes)' % (args.out, out.count('\n'), len(out)))
    if args.report:
        print('\n'.join(report))
        for k, v in sorted(fm_hooks.items()):
            print('FM dispatch %s: %s' % (k, ', '.join('%s:%s' % (m.key, h) for m, h in v)))
        print('CurWeapon dispatch: %s' % ', '.join('%s:%s' % (m.key, h) for m, h in ev_hooks))


HEADER = r'''/*
    =====================================================================
      ===  V E X M I R A  ===      Vexmira Zombie Core  v@@VERSION@@

      TEK DOSYA / SINGLE FILE:  zombie_core.sma -> zombie_core.amxx
      plugins.ini icin tek satir yeterli:   zombie_core.amxx
      (plugins-vexmira42.ini GEREKMEZ; panel dosyayi yeniden adlandirsa da calisir)

      Icerik: cekirdek mod + 13 esya modulu (Janus-7, Plasma, Thunderbolt, Ethereal,
      Salamander, Bow, Dragon Sword, Katana, Lightsaber, Horse Axe, HEV, Jetpack,
      Survivor Minigun) + tani modulu (vex_diagnose). Yalniz standart AMXX 1.10
      include dosyalari kullanilir; ReAPI tanimlari bu dosyanin icindedir.
      Gerekli moduller: reapi, fakemeta, hamsandwich, engine, cstrike, fun, nvault
      (geoip istege bagli). ReHLDS + ReGameDLL_CS gerekli.

      Ayar dosyalari (vexmira.cfg, vexmira_maps/*.ini, vexmira_motd_*.html,
      data/lang/vexmira_zombie.txt) bu dosyanin icinde gomuludur: sunucuda yoksa
      ilk acilista yazilir, varsa DOKUNULMAZ (duzenlemeleriniz korunur).
      Yeniden yazdirmak icin: zc_writeconfigs (konsol)  veya  zc_rewrite_configs 1 + harita degisimi.
      Ses / model / sprite dosyalari ayri dosyalardir ve sunucuda bulunmalidir.

      Bu dosya devtools/single/make_single.py ile v4.2 kaynaklarindan uretilmistir.
    =====================================================================
*/

'''

PRE_GLUE = r'''// component ids (shop / admin / restore code calls ZcCall(component, op, id))
#define ZC_JANUS7      1
#define ZC_PLASMA      2
#define ZC_THUNDERBOLT 3
#define ZC_ETHEREAL    4
#define ZC_SALAMANDER  5
#define ZC_BOW         6
#define ZC_DRAGONSWORD 7
#define ZC_KATANA      8
#define ZC_LIGHTSABER  9
#define ZC_HORSEAXE    10
#define ZC_HEV         11
#define ZC_JETPACK     12
#define ZC_MINIGUN     13
enum { ZCOP_give = 0, ZCOP_has, ZCOP_remove, ZCOP_infected };
#define ZC_MODS @@MODCOUNT@@
new bool:g_bZcOn[ZC_MODS];        // module index -> assets ok and initialised
new bool:g_zcGuardFail;           // set by VexAssetGuard / ZcPc* while a module precaches
new g_zcCurMod = -1;              // module currently precaching (for log lines)
new g_pZcRewrite;
'''


def gen_glue(mods):
    o = []
    o.append('new const ZC_MOD_NAME[ZC_MODS][] = { %s };' % ', '.join('"%s"' % m.src for m in mods))
    o.append('new const ZC_MOD_COMP[ZC_MODS] = { %s };' % ', '.join(str(m.comp) for m in mods))
    o.append('''
// component id -> module index (or -1)
ZcCompMod(comp)
{
    for (new i = 0; i < ZC_MODS; i++) if (ZC_MOD_COMP[i] == comp) return i;
    return -1;
}
bool:ZcCompOn(comp)
{
    new i = ZcCompMod(comp);
    return i >= 0 && g_bZcOn[i];
}
ZcModulesOn()
{
    new n; for (new i = 0; i < ZC_MODS; i++) if (g_bZcOn[i]) n++;
    return n;
}
ZcModuleStatus(id)
{
    for (new i = 0; i < ZC_MODS; i++)
        console_print(id, "module %-18s component %2d : %s", ZC_MOD_NAME[i], ZC_MOD_COMP[i], g_bZcOn[i] ? "ON" : "OFF (missing/damaged asset, see amxx log)");
    for (new i = 0; i < ZC_MODS; i++)
        if (!g_bZcOn[i]) log_amx("[Community] NOT READY: module %s is off (missing/damaged asset)", ZC_MOD_NAME[i]);
}
''')
    # ZcCall
    o.append('ZcCall(comp, op, id)\n{\n    if (!ZcCompOn(comp) || id < 1 || id > 32) return 0;\n    switch (comp)\n    {')
    for m in mods:
        if not m.comp:
            continue
        o.append('        case %d: switch (op) {' % m.comp)
        for f in m.iface:
            op = f[4:]
            o.append('            case ZCOP_%s: return %s%s(id);' % (op, m.pfx, f))
        o.append('        }')
    o.append('    }\n    return 0;\n}\n')
    # precache wrappers
    o.append('''// 4.3: modules never precache a missing file; a missing model/sprite switches the module off.
ZcPcModel(const path[])
{
    if (!file_exists(path, true)) {
        log_amx("[AssetGuard] EKSIK %s -> modul %s KAPALI (sunucu calismaya devam ediyor)", path, g_zcCurMod >= 0 ? ZC_MOD_NAME[g_zcCurMod] : "?");
        g_zcGuardFail = true;
        return 0;
    }
    return precache_model(path);
}
ZcPcSound(const path[])
{
    new f[160]; formatex(f, charsmax(f), "sound/%s", path);
    if (!file_exists(f, true)) { log_amx("[AssetGuard] UYARI eksik ses %s (atlandi)", f); return 0; }
    return precache_sound(path);
}
ZcPcGeneric(const path[])
{
    if (!file_exists(path, true)) { log_amx("[AssetGuard] UYARI eksik dosya %s (atlandi)", path); return 0; }
    return precache_generic(path);
}
''')
    # forward dispatchers
    def calls(fwd, args, cond=True):
        out = []
        for m in mods:
            for f in fwd:
                if f in m.forwards:
                    a = args if f != 'client_disconnect' else 'id'
                    out.append('    if (g_bZcOn[%d]) %s%s(%s);' % (m.idx, m.pfx, f, a))
        return '\n'.join(out)
    pre = []
    for m in mods:
        if 'plugin_precache' in m.forwards:
            pre.append('    g_zcCurMod = %d; g_zcGuardFail = false; %splugin_precache(); g_bZcOn[%d] = !g_zcGuardFail;' % (m.idx, m.pfx, m.idx))
        else:
            pre.append('    g_bZcOn[%d] = true;' % m.idx)
    o.append('''public plugin_precache()
{
    // 1) configs + lang first: vexmira.cfg / map ini are read during precache, lang in plugin_init
    g_pZcRewrite = register_cvar("zc_rewrite_configs", "0");
    new bool:force = get_pcvar_num(g_pZcRewrite) > 0;
    ZcWriteConfigs(force);
    if (force) set_pcvar_num(g_pZcRewrite, 0);
    // 2) core
    ZcCore_plugin_precache();
    // 3) item modules (each one switches itself off if one of its files is missing)
%s
    g_zcCurMod = -1;
    for (new i = 0; i < ZC_MODS; i++)
        if (!g_bZcOn[i]) log_amx("[Vexmira] modul %%s KAPALI: eksik/bozuk dosya (yukaridaki AssetGuard satirlari). Diger her sey calisiyor.", ZC_MOD_NAME[i]);
}

public plugin_init()
{
    ZcCore_plugin_init();
%s
    ZcRegisterDispatchers();
    register_concmd("zc_writeconfigs", "ZcCmdWriteConfigs", ADMIN_RCON, "- gomulu vexmira.cfg / lang / harita ini / motd dosyalarini yeniden yazar (USTUNE YAZAR)");
    register_concmd("zc_modules", "ZcCmdModules", ADMIN_RCON, "- dahili esya modullerinin durumu");
}

public client_putinserver(id)
{
    ZcCore_client_putinserver(id);
%s
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
    ZcCore_client_disconnected(id, drop, message, maxlen);
%s
}

public ZcCmdModules(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED;
    console_print(id, "Vexmira Zombie Core %%s - %%d/%%d modul acik", VERSION, ZcModulesOn(), ZC_MODS);
    ZcModuleStatus(id);
    return PLUGIN_HANDLED;
}
''' % ('\n'.join(pre), calls(['plugin_init'], ''), calls(['client_putinserver'], 'id'),
       calls(['client_disconnect', 'client_disconnected'], 'id, drop, message, maxlen')))
    for m in mods:
        extra = set(m.forwards) - {'plugin_init', 'plugin_precache', 'client_putinserver', 'client_disconnect', 'client_disconnected'}
        if extra:
            die('%s: forward(s) %s not dispatched' % (m.src, extra))
    return '\n'.join(o)


def gen_writer(files):
    o = ['''// ---- embedded configuration files ----------------------------------------------------------
// Written at plugin_precache when missing (never overwritten unless forced), so a fresh server
// works with just zombie_core.amxx. Paths are the normal AMXX paths.
ZcWriteLines(const path[], const lines[][], n, bool:force)
{
    if (!force && file_exists(path)) return 0;
    new f = fopen(path, "wt");
    if (!f) { log_amx("[Vexmira] HATA: %s yazilamadi (klasor izni?)", path); return -1; }
    for (new i = 0; i < n; i++) { fputs(f, lines[i]); fputs(f, "^n"); }
    fclose(f);
    log_amx("[Vexmira] varsayilan dosya yazildi: %s (%d satir)", path, n);
    server_print("[Vexmira] varsayilan dosya yazildi: %s", path);
    return 1;
}

ZcEnsureDir(const dir[])
{
    if (!dir_exists(dir)) mkdir(dir);
}

ZcWriteConfigs(bool:force)
{
    new cfg[96], data[96], path[192], n;
    get_configsdir(cfg, charsmax(cfg));
    get_localinfo("amxx_datadir", data, charsmax(data));
    if (!data[0]) copy(data, charsmax(data), "addons/amxmodx/data");
    ZcEnsureDir(cfg);
    formatex(path, charsmax(path), "%s/vexmira_maps", cfg); ZcEnsureDir(path);
    ZcEnsureDir(data);
    formatex(path, charsmax(path), "%s/lang", data); ZcEnsureDir(path);
''']
    for (nm, kind, rel, p) in files:
        base = 'cfg' if kind == 'cfg' else 'data'
        sub = rel if kind == 'cfg' else 'lang/' + rel
        o.append('    formatex(path, charsmax(path), "%%s/%s", %s); if (ZcWriteLines(path, %s, sizeof %s, force) > 0) n++;' % (sub, base, nm, nm))
    o.append('''    return n;
}

public ZcCmdWriteConfigs(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED;
    new n = ZcWriteConfigs(true);
    console_print(id, "[Vexmira] %d dosya varsayilan haliyle yeniden yazildi. vex_reload veya harita degisimi ile gecerli olur.", n);
    return PLUGIN_HANDLED;
}
''')
    return '\n'.join(o)


if __name__ == '__main__':
    main()
