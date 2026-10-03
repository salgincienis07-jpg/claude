"""SDHLT compile pipeline: .map -> .bsp with every texture embedded.

    python3 -m mapkit.compile path/to/zm_x.map [--quality draft|normal|final] [--out cstrike/maps]

or from Python:
    from mapkit.compile import compile_map
    res = compile_map(map_obj_or_path, quality='final', out_dir='cstrike/maps')

Steps
  1. collect textures used by the .map; generate a per-map WAD of our vx_*
     textures (mapkit.textures) -> <work>/<map>_vx.wad
  2. rewrite worldspawn "wad" to that wad + sdhlt.wad (tool textures) and
     run CSG with -wadinclude for both, so the BSP embeds ALL textures and
     the final "wad" key is empty (clients need no .wad download)
  3. write <work>/<map>.rad (texture lights of the library)
  4. sdHLCSG -> sdHLBSP -> sdHLVIS -> sdHLRAD (threads = CPU count)
  5. parse logs: errors, warnings, LEAK (-> pointfile first point), limits
  6. copy the .bsp to out_dir (and validate with bspcheck)

Environment:
  SDHLT_TOOLS   directory with sdHL* binaries + sdhlt.wad
                (default: $SP/tools/sdhlt/tools, else devtools/mapkit/.sdhlt/tools)
  MAPKIT_WORK   work directory root (default devtools/mapkit/.build)
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Union

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))

_CANDIDATES = [
    os.environ.get('SDHLT_TOOLS', ''),
    '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/tools/sdhlt/tools',
    os.path.join(HERE, '.sdhlt', 'tools'),
]

QUALITY = {
    # CSG / BSP / VIS / RAD extra arguments
    'draft': dict(csg=[], bsp=[], vis=['-fast'], rad=['-fast', '-bounce', '1', '-pre25']),
    'normal': dict(csg=[], bsp=[], vis=[], rad=['-bounce', '3', '-smooth', '50', '-pre25']),
    'final': dict(csg=['-cliptype', 'precise'], bsp=[], vis=['-full'],
                  rad=['-extra', '-bounce', '4', '-smooth', '50', '-chop', '64', '-texchop', '32', '-pre25',
                       '-ao', '-aoscale', '32', '-aoopacity', '0.6', '-pcf', '2']),
}


def find_tools() -> str:
    for c in _CANDIDATES:
        if c and os.path.exists(os.path.join(c, 'sdHLCSG')):
            return c
    raise FileNotFoundError('SDHLT tools not found; run devtools/mapkit/build_sdhlt.sh or set SDHLT_TOOLS')


@dataclass
class StageResult:
    name: str
    seconds: float
    returncode: int
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)


@dataclass
class CompileResult:
    ok: bool
    bsp: Optional[str]
    work: str
    stages: List[StageResult]
    leak: Optional[str] = None
    total_seconds: float = 0.0
    textures: List[str] = field(default_factory=list)
    missing_textures: List[str] = field(default_factory=list)
    check: Optional[dict] = None

    def summary(self) -> str:
        lines = [f"{'OK' if self.ok else 'FAILED'}  {self.bsp or '-'}  ({self.total_seconds:.1f}s)"]
        for s in self.stages:
            lines.append(f'  {s.name:5s} {s.seconds:7.1f}s rc={s.returncode} errors={len(s.errors)} warnings={len(s.warnings)}')
            for e in s.errors[:8]:
                lines.append(f'      ERROR: {e}')
            for w in s.warnings[:8]:
                lines.append(f'      warn : {w}')
        if self.leak:
            lines.append(f'  LEAK: {self.leak}')
        if self.missing_textures:
            lines.append(f'  missing textures: {self.missing_textures}')
        return '\n'.join(lines)


_TEXRE = re.compile(r'^\s*\(\s*[-\d.e]+\s+[-\d.e]+\s+[-\d.e]+\s*\)\s*\(\s*[-\d.e]+\s+[-\d.e]+\s+[-\d.e]+\s*\)\s*\(\s*[-\d.e]+\s+[-\d.e]+\s+[-\d.e]+\s*\)\s+(\S+)')

_TOOL_TEX = {'null', 'skip', 'clip', 'hint', 'origin', 'aaatrigger', 'sky', 'bevel', 'solidhint', 'bevelhint',
             'boundingbox', 'clipbevel', 'clipbevelbrush', 'cliphull1', 'cliphull2', 'cliphull3', 'contentempty',
             'contentwater', 'noclip', 'black_hidden', 'splitface', '!cur_0', '!cur_90', '!cur_180', '!cur_270',
             '!cur_up', '!cur_dwn'}


def map_textures(map_text: str) -> List[str]:
    out = set()
    for line in map_text.splitlines():
        m = _TEXRE.match(line)
        if m:
            out.add(m.group(1))
    return sorted(out, key=str.lower)


def _set_wad_key(map_text: str, wads: List[str]) -> str:
    val = ';'.join(wads)
    # first entity = worldspawn; replace or insert its "wad" key
    head_end = map_text.index('{', map_text.index('{') + 1) if map_text.count('{') > 1 else len(map_text)
    head = map_text[:head_end]
    if re.search(r'"wad"\s+"[^"]*"', head):
        head = re.sub(r'"wad"\s+"[^"]*"', f'"wad" "{val}"', head, count=1)
    else:
        head = head.replace('"classname" "worldspawn"', f'"classname" "worldspawn"\n"wad" "{val}"', 1)
    return head + map_text[head_end:]


_STOCK_PREFIX = ('sprites/glow', 'sprites/flare', 'sprites/ledglow', 'sprites/hotglow', 'sprites/laserdot',
                 'sprites/steam1', 'sprites/bubble', 'sprites/smoke', 'sprites/laserbeam', 'sprites/xspark')


def custom_resources(map_text: str) -> List[str]:
    """Non-stock files referenced by entities (for maps/<name>.res so clients
    download them): ambient_generic sounds and env_sprite / model keys under
    vexmira/ folders."""
    out = []
    for m in re.finditer(r'"(message|model|noise|noise1|noise2)"\s+"([^"]+)"', map_text):
        key, val = m.group(1), m.group(2).replace('\\', '/')
        if val.startswith('*'):
            continue
        low = val.lower()
        if key in ('message', 'noise', 'noise1', 'noise2') and low.endswith('.wav'):
            path = 'sound/' + val
        elif low.endswith(('.spr', '.mdl')):
            path = val
        else:
            continue
        if path.lower().startswith(_STOCK_PREFIX) or 'vexmira' not in path.lower():
            continue
        out.append(path)
    return sorted(set(out))


_ERR = re.compile(r'(Error|ERROR|Fatal|fatal)[: ]')
_WARN = re.compile(r'(Warning|WARNING)[: ]')


def _parse_log(text: str):
    errs, warns = [], []
    lines = [l.strip() for l in text.splitlines()]
    for i, s in enumerate(lines):
        if not s:
            continue
        if _ERR.search(s) and 'errors' not in s.lower()[:10]:
            if s.rstrip(':').lower() in ('error', 'fatal error') and i + 1 < len(lines):
                nxt = next((l for l in lines[i + 1:i + 4] if l), '')
                s = f'{s} {nxt}'
            errs.append(s)
        elif _WARN.search(s):
            warns.append(s)
        elif 'exceeded' in s.lower() and 'MAX_' in s:
            errs.append(s)
    # merge duplicate warnings
    seen, w2 = set(), []
    for w in warns:
        if w not in seen:
            seen.add(w)
            w2.append(w)
    return errs, w2


def _run(tool: str, args: List[str], cwd: str, log: str, timeout: int) -> StageResult:
    t0 = time.time()
    with open(log, 'w') as lf:
        p = subprocess.run([tool] + args, cwd=cwd, stdout=lf, stderr=subprocess.STDOUT, timeout=timeout)
    dt = time.time() - t0
    with open(log, errors='replace') as lf:
        text = lf.read()
    errs, warns = _parse_log(text)
    if p.returncode != 0 and not errs:
        errs.append(f'{os.path.basename(tool)} exited with code {p.returncode}')
    return StageResult(os.path.basename(tool).replace('sdHL', ''), dt, p.returncode, errs, warns)


def compile_map(src: Union[str, 'object'], quality: str = 'normal', out_dir: Optional[str] = None,
                work_root: Optional[str] = None, threads: Optional[int] = None, timeout: int = 3600,
                extra: Optional[Dict[str, List[str]]] = None, check: bool = True, verbose: bool = True) -> CompileResult:
    """Compile a mapwriter.Map or a .map path. Returns CompileResult."""
    from . import textures as texlib
    from .wad import write_wad

    tools = find_tools()
    threads = threads or os.cpu_count() or 2
    q = {k: list(v) for k, v in QUALITY[quality].items()}
    for k, v in (extra or {}).items():
        q[k] = q.get(k, []) + list(v)

    if hasattr(src, 'to_str'):
        name = src.name
        text = src.to_str()
    else:
        name = os.path.splitext(os.path.basename(src))[0]
        with open(src) as f:
            text = f.read()

    work_root = work_root or os.environ.get('MAPKIT_WORK', os.path.join(HERE, '.build'))
    work = os.path.join(work_root, name)
    os.makedirs(work, exist_ok=True)
    for ext in ('.bsp', '.pts', '.lin', '.prt', '.err', '.log', '.p0', '.p1', '.p2', '.p3', '.wa_', '.ext', '.hsz', '.bsp.bak'):
        p = os.path.join(work, name + ext)
        if os.path.exists(p):
            os.remove(p)

    # 1. textures
    used = map_textures(text)
    ours, missing = [], []
    known = {n.lower(): n for n in texlib.wadnames()}
    for t in used:
        if t.lower() in _TOOL_TEX:
            continue
        if t.lower() in known:
            ours.append(known[t.lower()])
        else:
            missing.append(t)
    # animated textures need every frame
    full = []
    for t in ours:
        d = texlib.resolve(t)
        full += d.wadnames()
    full = list(dict.fromkeys(full))
    texs = texlib.build(full)
    wadpath = os.path.join(work, f'{name}_vx.wad')
    write_wad(wadpath, [texs[n] for n in full])
    sdhlt_wad = os.path.join(tools, 'sdhlt.wad')
    text = _set_wad_key(text, [wadpath, sdhlt_wad])
    mpath = os.path.join(work, name + '.map')
    with open(mpath, 'w', newline='\n') as f:
        f.write(text)
    # 3. texlights
    texlib.write_rad(os.path.join(work, name + '.rad'))

    stages: List[StageResult] = []
    t_all = time.time()
    base = ['-threads', str(threads), '-noestimate'] + (['-console', '0'] if os.name == 'nt' else [])
    leak = None
    ok = not missing
    steps = [
        ('sdHLCSG', base + ['-wadinclude', os.path.basename(wadpath), '-wadinclude', 'sdhlt.wad'] + q['csg']),
        ('sdHLBSP', base + q['bsp']),
        ('sdHLVIS', base + q['vis']),
        ('sdHLRAD', base + q['rad']),
    ]
    if ok:
        for tool, args in steps:
            log = os.path.join(work, f'{name}.{tool[4:].lower()}.log')
            r = _run(os.path.join(tools, tool), args + [mpath], work, log, timeout)
            stages.append(r)
            if verbose:
                print(f'[mapkit] {r.name}: {r.seconds:.1f}s rc={r.returncode} errors={len(r.errors)} warnings={len(r.warnings)}', flush=True)
            # leak detection
            lin = os.path.join(work, name + '.lin')
            pts = os.path.join(work, name + '.pts')
            if tool == 'sdHLBSP' and (os.path.exists(pts) or os.path.exists(lin)):
                pf = pts if os.path.exists(pts) else lin
                with open(pf) as fh:
                    first = fh.readline().strip()
                leak = f'pointfile {pf} first point: {first}'
                r.errors.append('LEAK: ' + leak)
            if r.returncode != 0 or r.errors:
                ok = False
                break
    bsp = os.path.join(work, name + '.bsp')
    if ok and not os.path.exists(bsp):
        ok = False
    res = CompileResult(ok, None, work, stages, leak, time.time() - t_all, full, missing)
    if ok:
        if out_dir:
            os.makedirs(out_dir, exist_ok=True)
            dst = os.path.join(out_dir, name + '.bsp')
            shutil.copyfile(bsp, dst)
            res.bsp = dst
            custom = custom_resources(text)
            resf = os.path.join(out_dir, name + '.res')
            if custom:
                with open(resf, 'w', newline='\n') as fh:
                    fh.write(f'// {name} custom resources (textures are embedded, sky is stock)\n')
                    for c in custom:
                        fh.write(c + '\n')
            elif os.path.exists(resf):
                os.remove(resf)
        else:
            res.bsp = bsp
        if check:
            from . import bspcheck
            rep = bspcheck.check(res.bsp)
            res.check = rep
            if rep['errors']:
                res.ok = False
    if verbose:
        print(res.summary())
        if res.check:
            from . import bspcheck
            print(bspcheck.format_report(res.check))
    return res


def main(argv=None):
    ap = argparse.ArgumentParser(description='Compile a .map with SDHLT (textures embedded)')
    ap.add_argument('map')
    ap.add_argument('--quality', default='normal', choices=sorted(QUALITY))
    ap.add_argument('--out', default=None, help='copy the .bsp here (e.g. cstrike/maps)')
    ap.add_argument('--threads', type=int, default=None)
    a = ap.parse_args(argv)
    r = compile_map(a.map, a.quality, a.out, threads=a.threads)
    return 0 if r.ok else 1


if __name__ == '__main__':
    sys.exit(main())
