#!/usr/bin/env python3
"""Vexmira headless test-server harness.

Runs the real plugin on ReHLDS + ReGameDLL + Metamod-R + AMX Mod X 1.10 + ReAPI with CS bots,
feeds timed console commands, captures console + AMXX/game logs and prints a summary
(plugin/module status, run-time errors with stack lines, precache usage, crashes, rounds,
infections, bosses, emitted Vexmira sounds).

    python3 devtools/server/run_test.py --map zm_vex_testroom --seconds 360 --bots 12 \
        --commands devtools/server/sessions/full_session.txt --rebuild-plugin

Commands file: one per line "<seconds> <console command>" (seconds after the map is up;
lines without a leading number run at 0), '#' comments. Example:
    60 vex_boss 3
    61 sv_restart 1
    120 vex_mode 9
Inline: --cmd "60 vex_boss 3" (repeatable).

Every run is archived in $SP/server/runs/<stamp>_<map>/ (console.log, amxx_L.log,
amxx_error.log, game.log, summary.txt, summary.json). Exit code: 0 ok, 1 errors found, 2 crash.
"""
import argparse
import collections
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
SP = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad'
SERVER = os.environ.get('VEX_SERVER', os.path.join(SP, 'server'))
AMXXPC_DIR = os.path.join(SP, 'tools', 'bin')

SNAPSHOT = os.path.join(SERVER, 'cstrike', 'addons', 'amxmodx', 'plugins', 'vexmira_zombie.sma.snapshot')
RE_TS = re.compile(r'^L \d\d/\d\d/\d{4} - \d\d:\d\d:\d\d: ')


# ------------------------------------------------------------------------------------- install
def _link(src, dst):
    """Create/refresh a symlink dst -> src (replaces stale links, never real dirs with content)."""
    if os.path.islink(dst):
        if os.readlink(dst) == src:
            return False
        os.unlink(dst)
    elif os.path.isdir(dst):
        if os.listdir(dst):
            raise RuntimeError('refusing to replace non-empty real dir %s' % dst)
        os.rmdir(dst)
    elif os.path.exists(dst):
        os.unlink(dst)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    os.symlink(src, dst)
    return True


def sync_package(server=SERVER, verbose=True):
    """Symlink the Vexmira package from the repo into the server tree (idempotent)."""
    rc = os.path.join(REPO, 'cstrike')
    sc = os.path.join(server, 'cstrike')
    amx_r = os.path.join(rc, 'addons', 'amxmodx')
    amx_s = os.path.join(sc, 'addons', 'amxmodx')
    made = []
    # configs: vexmira*.cfg/ini/html + plugins-vexmira.ini
    for f in sorted(glob.glob(os.path.join(amx_r, 'configs', '*'))):
        b = os.path.basename(f)
        if b.startswith('vexmira') or b.startswith('plugins-vexmira'):
            if _link(f, os.path.join(amx_s, 'configs', b)):
                made.append('configs/' + b)
    # lang files (only ours; AMXX keeps its own)
    for f in sorted(glob.glob(os.path.join(amx_r, 'data', 'lang', '*'))):
        if _link(f, os.path.join(amx_s, 'data', 'lang', os.path.basename(f))):
            made.append('data/lang/' + os.path.basename(f))
    # content: per-file links (server dirs stay real, so server-only stubs/navs can live beside them)
    roots = ['sound/vexmira', 'sprites/vexmira', 'models/vexmira', 'gfx/vexmira', 'resource/vexmira']
    roots += ['models/player/' + os.path.basename(d) for d in sorted(glob.glob(os.path.join(rc, 'models', 'player', '*')))
              if os.path.isdir(d)]
    nlinks = 0
    for rel in roots:
        src_root = os.path.join(rc, rel)
        dst_root = os.path.join(sc, rel)
        if os.path.islink(dst_root):          # old style directory link
            os.unlink(dst_root)
        if not os.path.isdir(src_root):
            continue
        for root, _dirs, files in os.walk(src_root):
            for n in files:
                src = os.path.join(root, n)
                dst = os.path.join(dst_root, os.path.relpath(src, src_root))
                if _link(src, dst):
                    nlinks += 1
    if nlinks:
        made.append('%d content files' % nlinks)
    # sky textures shipped by the package (gfx/env), if any
    for f in sorted(glob.glob(os.path.join(rc, 'gfx', 'env', '*'))):
        if _link(f, os.path.join(sc, 'gfx', 'env', os.path.basename(f))):
            made.append('gfx/env/' + os.path.basename(f))
    # maps: per-file links so server-generated .nav files stay in the server tree
    smaps = os.path.join(sc, 'maps')
    os.makedirs(smaps, exist_ok=True)
    for f in sorted(glob.glob(os.path.join(rc, 'maps', '*'))):
        b = os.path.basename(f)
        dst = os.path.join(smaps, b)
        if b.endswith('.nav') and os.path.exists(dst) and not os.path.islink(dst):
            continue  # keep a locally generated nav
        if _link(f, dst):
            made.append('maps/' + b)
    # drop dangling links (files removed from the repo)
    for root, dirs, files in os.walk(sc):
        for n in dirs + files:
            p = os.path.join(root, n)
            if os.path.islink(p) and not os.path.exists(p):
                os.unlink(p)
                made.append('removed dangling ' + os.path.relpath(p, sc))
    if verbose and made:
        print('[sync] %d links updated: %s' % (len(made), ', '.join(made[:12]) + (' ...' if len(made) > 12 else '')))
    return made


def build_plugin(server=SERVER):
    out = os.path.join(server, 'cstrike', 'addons', 'amxmodx', 'plugins', 'vexmira_zombie.amxx')
    src = os.path.join(REPO, 'cstrike', 'addons', 'amxmodx', 'scripting', 'vexmira_zombie.sma')
    snap = open(src, 'rb').read()
    p = subprocess.run(['bash', os.path.join(REPO, 'devtools', 'plugin', 'build_plugin.sh'), out],
                       capture_output=True, text=True)
    # source snapshot = exactly what was compiled (stack-trace line numbers refer to it)
    with open(SNAPSHOT, 'wb') as f:
        f.write(snap)
    log = p.stdout + p.stderr
    errs = [l for l in log.splitlines() if re.search(r'\berror\b', l, re.I)]
    warns = [l for l in log.splitlines() if re.search(r'\bwarning\b', l, re.I)]
    ok = os.path.exists(out) and not errs
    print('[build] vexmira_zombie.amxx: %s (%d errors, %d warnings, %d bytes)' % (
        'OK' if ok else 'FAILED', len(errs), len(warns), os.path.getsize(out) if os.path.exists(out) else 0))
    for l in (errs + warns)[:30]:
        print('   ' + l)
    if not ok:
        print(log[-3000:])
    return ok


def build_probe(server=SERVER):
    out = os.path.join(server, 'cstrike', 'addons', 'amxmodx', 'plugins', 'vexprobe.amxx')
    src = os.path.join(HERE, 'vexprobe.sma')
    if os.path.exists(out) and os.path.getmtime(out) >= os.path.getmtime(src):
        return True
    p = subprocess.run([os.path.join(AMXXPC_DIR, 'amxxpc'), src, '-i' + os.path.join(AMXXPC_DIR, 'include'),
                        '-o' + out], capture_output=True, text=True, cwd=AMXXPC_DIR)
    ok = p.returncode == 0 and os.path.exists(out)
    print('[build] vexprobe.amxx: %s' % ('OK' if ok else 'FAILED\n' + p.stdout[-2000:]))
    return ok


def ensure_plugins_ini(server=SERVER, probe=True):
    """plugins.ini: vexprobe first (precache hooks must register before everybody else)."""
    p = os.path.join(server, 'cstrike', 'addons', 'amxmodx', 'configs', 'plugins.ini')
    lines = open(p).read().splitlines() if os.path.exists(p) else []
    lines = [l for l in lines if 'vexprobe.amxx' not in l]
    out = []
    if probe:
        out.append('vexprobe.amxx\t\t; devtools/server telemetry (test server only)')
    out += lines
    open(p, 'w').write('\n'.join(out) + '\n')


# ------------------------------------------------------------------------------------- logs
class LogTail:
    """Remember sizes of log files before the run; collect what was appended afterwards."""

    def __init__(self, pattern):
        self.pattern = pattern
        self.before = {f: os.path.getsize(f) for f in glob.glob(pattern)}

    def new_text(self):
        out = []
        for f in sorted(glob.glob(self.pattern), key=os.path.getmtime):
            start = self.before.get(f, 0)
            try:
                with open(f, 'rb') as fh:
                    fh.seek(start if os.path.getsize(f) >= start else 0)
                    out.append(fh.read().decode('utf-8', 'replace'))
            except OSError:
                pass
        return ''.join(out)


# ------------------------------------------------------------------------------------- run
def parse_commands(path, inline):
    cmds = []
    lines = []
    if path:
        lines += open(path).read().splitlines()
    lines += inline or []
    for l in lines:
        l = l.strip()
        if not l or l.startswith('#') or l.startswith('//'):
            continue
        m = re.match(r'^(\d+(?:\.\d+)?)\s+(.*)$', l)
        if m:
            cmds.append((float(m.group(1)), m.group(2)))
        else:
            cmds.append((0.0, l))
    cmds.sort(key=lambda c: c[0])
    return cmds


class Server:
    def __init__(self, args, rundir):
        self.args = args
        self.rundir = rundir
        self.lines = []          # (t, text)
        self.t0 = None           # map-up time (monotonic)
        self.start = None
        self.lock = threading.Lock()
        self.proc = None
        self.map_up = threading.Event()
        self.nav_saved = threading.Event()
        self.log = open(os.path.join(rundir, 'console.log'), 'w', buffering=1)

    def launch(self):
        a = self.args
        cmd = ['./hlds_linux', '-game', 'cstrike', '-insecure', '-nomaster', '+sv_lan', '1', '+maxplayers',
               str(a.maxplayers), '-port', str(a.port), '+ip', '127.0.0.1', '+map', a.map]
        env = dict(os.environ)
        env['LD_LIBRARY_PATH'] = SERVER + ':' + env.get('LD_LIBRARY_PATH', '')
        self.start = time.monotonic()
        self.proc = subprocess.Popen(cmd, cwd=SERVER, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT, env=env, bufsize=0)
        threading.Thread(target=self._reader, daemon=True).start()

    def _reader(self):
        buf = b''
        while True:
            ch = self.proc.stdout.read(4096)
            if not ch:
                break
            buf += ch
            while b'\n' in buf:
                line, buf = buf.split(b'\n', 1)
                self._line(line.decode('utf-8', 'replace').rstrip('\r'))
        if buf:
            self._line(buf.decode('utf-8', 'replace'))

    def _line(self, text):
        t = time.monotonic() - self.start
        with self.lock:
            self.lines.append((t, text))
        self.log.write('[%7.2f] %s\n' % (t, text))
        if 'Started map' in text or '[vexprobe] precache' in text:
            if not self.map_up.is_set():
                self.t0 = time.monotonic()
                self.map_up.set()
        if 'Navigation file' in text and 'saved' in text:
            self.nav_saved.set()
        if self.args.echo and self._interesting(text):
            print('  | %s' % text[:220])

    @staticmethod
    def _interesting(text):
        return bool(re.search(r'error|warning|fatal|vexmira\]|vexprobe\] (status|round|first emit|MISSING)|'
                              r'Mapchange|Segmentation|Host_Error|crash|Navigation', text, re.I))

    BOSSES = ['brute', 'banshee', 'overlord', 'inferno', 'reaper', 'frostlord', 'stormcaller', 'hivequeen', 'void']

    def loaded_bosses(self):
        """Boss ids in this map's boss plan, from the plugin's 'vex_precache_stats' reply."""
        with self.lock:
            lines = [l for _, l in self.lines if 'yuklenen bosslar' in l]
        if not lines:
            return []
        names = lines[-1].split(':', 1)[1] if ':' in lines[-1] else ''
        ids = []
        for n in re.split(r'[,\s]+', names.strip()):
            n = n.strip().lower()
            if n in self.BOSSES:
                ids.append(self.BOSSES.index(n))
        return ids

    def expand(self, cmd):
        """{boss0}..{bossN}: K-th boss of the loaded plan (wraps; -1 = random if unknown)."""
        def rep(m):
            ids = self.loaded_bosses()
            return str(ids[int(m.group(1)) % len(ids)]) if ids else '-1'
        return re.sub(r'\{boss(\d+)\}', rep, cmd)

    def send(self, cmd):
        if self.proc.poll() is not None:
            return False
        t = time.monotonic() - self.start
        self.log.write('[%7.2f] >>> %s\n' % (t, cmd))
        try:
            self.proc.stdin.write((cmd + '\n').encode())
            self.proc.stdin.flush()
        except (BrokenPipeError, OSError):
            return False
        return True

    def alive(self):
        return self.proc.poll() is None

    def stop(self, grace=12):
        if self.alive():
            self.send('vexprobe_status')
            self.send('amxx plugins')
            self.send('amxx modules')
            self.send('meta list')
            self.send('status')
            time.sleep(2)
            self.send('quit')
            try:
                self.proc.wait(grace)
            except subprocess.TimeoutExpired:
                self.proc.terminate()
                try:
                    self.proc.wait(5)
                except subprocess.TimeoutExpired:
                    self.proc.kill()
        time.sleep(0.3)
        self.log.close()


def run(args, quiet=False, collect_missing=False):
    stamp = time.strftime('%Y%m%d_%H%M%S')
    rundir = os.path.join(SERVER, 'runs', '%s_%s' % (stamp, args.map))
    os.makedirs(rundir, exist_ok=True)
    cs = os.path.join(SERVER, 'cstrike')
    tails = {
        'amxx_L.log': LogTail(os.path.join(cs, 'addons/amxmodx/logs/L*.log')),
        'amxx_error.log': LogTail(os.path.join(cs, 'addons/amxmodx/logs/error_*.log')),
        'game.log': LogTail(os.path.join(cs, 'logs/L*.log')),
    }
    cmds = parse_commands(args.commands, args.cmd)
    srv = Server(args, rundir)
    print('[run] %s map=%s bots=%d seconds=%d commands=%d -> %s' % (
        stamp, args.map, args.bots, args.seconds, len(cmds), rundir))
    srv.launch()
    crashed = False
    if not srv.map_up.wait(args.boot_timeout):
        print('[run] map did not come up within %ds' % args.boot_timeout)
    else:
        print('[run] map up after %.1fs' % (srv.t0 - srv.start))
        srv.send('amxx plugins')
        srv.send('vex_precache_stats')
        if args.bots:
            srv.send('bot_quota %d' % args.bots)
        pending = list(cmds)
        end = srv.t0 + args.seconds
        last_report = 0
        while time.monotonic() < end:
            if not srv.alive():
                crashed = True
                break
            now = time.monotonic() - srv.t0
            while pending and pending[0][0] <= now:
                _, c = pending.pop(0)
                c = srv.expand(c)
                print('[run] t=%5.1f > %s' % (now, c))
                srv.send(c)
            if args.until_nav and srv.nav_saved.is_set():
                print('[run] navigation file saved, stopping early')
                time.sleep(4)
                break
            if now - last_report >= 30:
                last_report = now
                print('[run] t=%4.0f alive, %d console lines' % (now, len(srv.lines)))
            time.sleep(0.2)
    if not srv.alive() and not crashed:
        crashed = True
    rc_before = srv.proc.poll()
    srv.stop()
    # collect logs
    texts = {}
    for name, tail in tails.items():
        texts[name] = tail.new_text()
        with open(os.path.join(rundir, name), 'w') as f:
            f.write(texts[name])
    for f in glob.glob(os.path.join(cs, 'addons/amxmodx/logs/vexprobe_precache_*.txt')):
        shutil.copy(f, rundir)
    if os.path.exists(SNAPSHOT):
        shutil.copy(SNAPSHOT, os.path.join(rundir, 'vexmira_zombie.sma'))
    console = [l for _, l in srv.lines]
    summ = summarize(console, texts, crashed, rc_before, srv.proc.returncode, args)
    with open(os.path.join(rundir, 'summary.json'), 'w') as f:
        json.dump(summ, f, indent=1)
    txt = format_summary(summ)
    with open(os.path.join(rundir, 'summary.txt'), 'w') as f:
        f.write(txt)
    if collect_missing:
        return sorted(set(re.findall(r'bulunamadi: (\S+\.(?:mdl|spr|wav))', texts['amxx_L.log'])))
    if not quiet:
        print(txt)
    print('[run] archived in %s' % rundir)
    if summ['crash']:
        return 2
    return 1 if (summ['runtime_errors'] or summ['fatal'] or summ['plugin_status'] not in ('running', 'debug')) else 0


# ------------------------------------------------------------------------------------- summary
def _strip(l):
    return RE_TS.sub('', l)


_SNAP = None


def _annotate(frame):
    """'[0] vexmira_zombie.sma::Func (line N)' -> + the source line from the compiled snapshot."""
    global _SNAP
    m = re.search(r'vexmira_zombie\.sma::\w+ \(line (\d+)\)', frame)
    if not m:
        return frame
    if _SNAP is None:
        try:
            _SNAP = open(SNAPSHOT, encoding='utf-8', errors='replace').read().splitlines()
        except OSError:
            _SNAP = []
    n = int(m.group(1))
    if 0 < n <= len(_SNAP):
        return '%s   | %s' % (frame, _SNAP[n - 1].strip()[:150])
    return frame


def summarize(console, texts, crashed, rc_before, rc, args):
    s = collections.OrderedDict()
    s['map'] = args.map
    s['seconds'] = args.seconds
    s['bots'] = args.bots
    s['crash'] = bool(crashed and rc_before not in (0, None))
    s['exit_code'] = rc
    allc = '\n'.join(console)
    # plugin status from the LAST "amxx plugins" listing
    status = 'not listed'
    plugin_lines = []
    for l in console:
        m = re.search(r'vexmira_zo\S*\s+(running|bad load|error|paused|stopped|debug)', l)
        if m:
            status = m.group(1)
            plugin_lines.append(re.sub(r'\s+', ' ', l.strip()))
    s['plugin_status'] = status
    s['plugin_line'] = plugin_lines[-1] if plugin_lines else ''
    probe = [re.sub(r'\s+', ' ', l.strip()) for l in console if re.search(r'vexprobe\.am\S*\s+(running|bad)', l)]
    s['load_fails'] = sorted(set(l.strip() for l in console if 'Load fails' in l or 'Plugin file open error' in l))
    s['probe_line'] = probe[-1].strip() if probe else ''
    # modules (last listing)
    mods = []
    try:
        i = max(i for i, l in enumerate(console) if 'Currently loaded modules:' in l)
        for l in console[i + 2:]:
            m = re.match(r'\s*\[\s*\d+\]\s+(.+?)\s{2,}(\S+)\s+.+?\s{2,}(\w[\w ]*?)\s*$', l)
            if not m:
                break
            mods.append('%s %s (%s)' % (m.group(1).strip(), m.group(2), m.group(3).strip()))
    except ValueError:
        pass
    s['modules'] = mods
    metas = []
    try:
        i = max(i for i, l in enumerate(console) if l.startswith('Currently loaded plugins:') and
                'description' in (console[i + 1] if i + 1 < len(console) else ''))
        for l in console[i + 2:]:
            if not re.match(r'\s*\[\s*\d+\]', l):
                break
            metas.append(re.sub(r'\s+', ' ', l.strip()))
    except ValueError:
        pass
    s['metamod_plugins'] = metas
    # AMXX run-time errors (error_*.log) grouped with their stack
    err = texts.get('amxx_error.log', '')
    groups = collections.OrderedDict()
    cur = None
    for raw in err.splitlines():
        l = _strip(raw)
        if l.startswith('Start of error session') or l.startswith('Info (map') or l.startswith('Error log'):
            continue
        if re.match(r'\[AMXX\]\s+\[\d+\]', l) and cur is not None:
            if len(cur['stack']) < 8:
                cur['stack'].append(l.replace('[AMXX]', '').strip())
            continue
        if l.startswith('[AMXX] Displaying debug trace') or l.startswith('[AMXX] Run time error'):
            if cur is not None:
                cur['head'].append(l.replace('[AMXX] ', ''))
            continue
        key = l
        cur = groups.setdefault(key, {'msg': l, 'count': 0, 'head': [], 'stack': []})
        if cur['count'] > 0:
            cur['stack_locked'] = True
        cur['count'] += 1
    # dedupe stacks collected repeatedly
    errs = []
    for g in groups.values():
        st = []
        for x in g['stack']:
            if x not in st:
                st.append(x)
        errs.append({'msg': g['msg'], 'count': g['count'], 'detail': sorted(set(g['head'])),
                     'stack': [_annotate(x) for x in st[:6]]})
    s['runtime_errors'] = errs
    # vexmira + probe log lines
    L = texts.get('amxx_L.log', '')
    vlines = [_strip(l) for l in L.splitlines() if ('[Vexmira]' in l or '[vexmira' in l.lower())
              and 'performance issue' not in l]
    s['vexmira_log'] = vlines[:80]
    s['vexmira_log_count'] = len(vlines)
    probe_lines = [_strip(l) for l in L.splitlines() if '[vexprobe]' in l]
    s['precache_probe'] = [l for l in probe_lines if '] precache' in l]
    s['precache_plugin'] = [l for l in vlines if 'precache' in l.lower() or 'toplam' in l.lower()][:6]
    s['precache_plugin'] += [l for l in console if l.startswith('[Vexmira]') and ('precache' in l or 'toplam' in l
                                                                                 or 'yuklenen boss' in l)][:6]
    finals = [l for l in probe_lines if '] final' in l]
    s['final'] = finals[-1] if finals else ''
    s['emitted'] = [l.split('] emitted', 1)[1].strip() for l in probe_lines if '] emitted' in l]
    stat = [l for l in probe_lines if '] status' in l]
    s['status_samples'] = stat[:: max(1, len(stat) // 12)][:14] + (stat[-1:] if stat else [])
    s['missing_models'] = sorted(set(l for l in probe_lines if 'MISSING' in l))
    special = collections.Counter()
    maxhp = collections.Counter()
    for l in stat:
        m = re.search(r'models: (.*)$', l)
        if m:
            for part in m.group(1).split(', '):
                name = part.rsplit(' x', 1)[0].strip()
                if re.match(r'vex_(b_|nemesis|assassin|survivor|sniper)', name):
                    special[name] += 1
        m = re.search(r'maxhp=(\d+)\((.*?) (\S*)\)', l)
        if m and m.group(3):
            maxhp[m.group(3)] = max(maxhp[m.group(3)], int(m.group(1)))
    s['special_model_samples'] = dict(special)
    s['max_hp_by_model'] = dict(maxhp)
    s['round_wins'] = dict(collections.Counter(re.findall(r'round_win t=\d+ status=(\w+)', '\n'.join(probe_lines))))
    s['round_starts'] = len([l for l in probe_lines if 'round_start' in l])
    s['round_ends'] = len([l for l in probe_lines if 'round_end' in l])
    # game log
    G = texts.get('game.log', '')
    s['game_rounds'] = len(re.findall(r'World triggered "Round_Start"', G))
    s['loaded_bosses'] = sorted(set(l.split(':', 1)[1].strip() for l in console if 'yuklenen bosslar' in l))
    s['boss_bar_lines'] = len([l for l in console if re.search(r'\[Vexmira\]\s+#\d+ bar tur', l)])
    s['boss_bar_samples'] = [l.strip() for l in console if re.search(r'\[Vexmira\]\s+#\d+ bar tur', l)][:8]
    perf = {}
    for l in L.splitlines():
        m = re.search(r'\[(\S+)\] performance issue\. Function (\S+) executed more than ([\d.]+)ms', l)
        if m:
            k = '%s::%s' % (m.group(1).replace('.amxx', ''), m.group(2))
            c, mx = perf.get(k, (0, 0.0))
            perf[k] = (c + 1, max(mx, float(m.group(3))))
    s['perf'] = ['%-45s max %7.1f ms (%dx)' % (k, v[1], v[0]) for k, v in sorted(perf.items(), key=lambda kv: -kv[1][1])]
    s['kills_logged'] = len(re.findall(r'" killed "', G))
    s['mapchanges'] = re.findall(r'Mapchange to (\S+)', allc)
    # console problems
    pats = [
        ('fatal', r'FATAL ERROR|Host_Error|Sys_Error|Segmentation fault|SIGSEGV|core dumped|terminate called'),
        ('precache_overflow', r'failed to precache because the item count is over|Too many (models|sounds)|'
                              r'PF_precache_\w+_I: .*(overflow|limit)|Precache.*overflow'),
        ('missing_file', r"Mod_LoadModel|not found|couldn't load|can't load|Couldn't open|missing from server|"
                         r'Unable to load'),
        ('amxx', r'\[AMXX\]|\[AMX\]|Plugin file open error|Module .* failed|bad load|Function not found|'
                 r'Native .* not found|failed to load'),
        ('warning', r'WARNING|Warning:|\bERROR\b'),
        ('nav', r'Navigation|navigation|Analyzing|bot_nav'),
    ]
    probs = collections.OrderedDict((k, collections.Counter()) for k, _ in pats)
    for l in console:
        if l.startswith('L ') and '[vexprobe]' in l:
            continue
        for k, p in pats:
            if re.search(p, l):
                probs[k][_strip(l).strip()[:240]] += 1
                break
    s['fatal'] = [('%dx ' % c) + l for l, c in probs['fatal'].most_common(20)]
    s['console_problems'] = {k: [('%dx ' % c) + l for l, c in v.most_common(25)] for k, v in probs.items()
                             if k != 'fatal' and v}
    s['console_tail'] = console[-25:] if s['crash'] else []
    return s


def format_summary(s):
    o = []
    w = o.append
    w('=' * 100)
    w('VEXMIRA TEST RUN  map=%s  bots=%d  seconds=%d  exit=%s  crash=%s' % (
        s['map'], s['bots'], s['seconds'], s['exit_code'], s['crash']))
    w('=' * 100)
    w('plugin vexmira_zombie.amxx : %s' % s['plugin_status'])
    if s['plugin_line']:
        w('   %s' % s['plugin_line'])
    if s['probe_line']:
        w('   %s' % s['probe_line'])
    for l in s.get('load_fails', []):
        w('   LOAD FAIL: ' + l)
    w('metamod plugins: %d' % len(s['metamod_plugins']))
    for m in s['metamod_plugins']:
        w('   ' + m)
    w('amxx modules: %s' % (', '.join(s['modules']) or '-'))
    w('-' * 100)
    w('PRECACHE')
    for l in s['precache_probe'] + s['precache_plugin']:
        w('   ' + l)
    w('-' * 100)
    w('GAMEPLAY  rounds(game log)=%d  probe round_start=%d round_end=%d  kills(game log)=%d  mapchanges=%s' % (
        s['game_rounds'], s['round_starts'], s['round_ends'], s['kills_logged'], s['mapchanges']))
    w('   loaded bosses (vex_precache_stats): %s' % (s['loaded_bosses'] or '-'))
    w('   boss/overhead bar entities reported: %d lines' % s['boss_bar_lines'])
    for l in s['boss_bar_samples']:
        w('     ' + l)
    w('   %s' % s['final'])
    w('   round winners (RG_RoundEnd): %s' % s['round_wins'])
    w('   special/boss models seen (status samples): %s' % (s['special_model_samples'] or '-'))
    w('   max HP observed per model: %s' % s['max_hp_by_model'])
    for l in s['status_samples']:
        w('   ' + l[:300])
    if s['missing_models']:
        w('   MISSING MODELS:')
        for l in s['missing_models']:
            w('     ' + l)
    if s['emitted']:
        w('   vexmira sounds emitted (%d unique):' % len(s['emitted']))
        for l in s['emitted'][:60]:
            w('     ' + l)
    if s['perf']:
        w('-' * 100)
        w('AMXX PERF LOG (amxmodx_perflog; inflated by the debug flag)')
        for l in s['perf'][:15]:
            w('   ' + l)
    w('-' * 100)
    w('AMXX RUN-TIME ERRORS: %d distinct' % len(s['runtime_errors']))
    for e in s['runtime_errors']:
        w('   %dx %s' % (e['count'], e['msg']))
        for d in e['detail']:
            w('        %s' % d)
        for st in e['stack']:
            w('        %s' % st)
    w('-' * 100)
    w('FATAL: %d' % len(s['fatal']))
    for l in s['fatal']:
        w('   ' + l)
    for k, v in s['console_problems'].items():
        w('console %s: %d distinct' % (k, len(v)))
        for l in v:
            w('   ' + l)
    w('-' * 100)
    w('[Vexmira] log lines: %d (first ones)' % s['vexmira_log_count'])
    for l in s['vexmira_log'][:40]:
        w('   ' + l[:240])
    if s['console_tail']:
        w('-' * 100)
        w('CONSOLE TAIL (crash)')
        for l in s['console_tail']:
            w('   ' + l)
    w('=' * 100)
    return '\n'.join(o) + '\n'


# ------------------------------------------------------------------------------------- main
def main(argv=None):
    ap = argparse.ArgumentParser(description='Vexmira headless CS 1.6 test server harness')
    ap.add_argument('--map', default='zm_vex_testroom')
    ap.add_argument('--seconds', type=int, default=120, help='run time after the map is up')
    ap.add_argument('--bots', type=int, default=0)
    ap.add_argument('--commands', help='timed command file ("<sec> <command>" per line)')
    ap.add_argument('--cmd', action='append', help='inline timed command "<sec> <command>"')
    ap.add_argument('--rebuild-plugin', action='store_true', help='compile the repo .sma into the server first')
    ap.add_argument('--no-vexmira', action='store_true', help='run without the Vexmira plugin (baseline)')
    ap.add_argument('--no-probe', action='store_true')
    ap.add_argument('--no-debug', action='store_true', help='load the plugin without the AMXX debug flag')
    ap.add_argument('--no-sync', action='store_true', help='do not refresh repo symlinks')
    ap.add_argument('--ensure-nav', action='store_true',
                    help='if maps/<map>.nav is missing, first run a bot learning pass (plugin disabled)')
    ap.add_argument('--until-nav', action='store_true', help='stop as soon as a .nav file is saved')
    ap.add_argument('--export-nav', action='store_true', help='copy the generated .nav into the repo maps dir')
    ap.add_argument('--stub-missing', action='store_true',
                    help='boot once, then create server-only stand-ins for every file the plugin reports as '
                         'missing ("bulunamadi"), so precache counts match a complete package')
    ap.add_argument('--clean-stubs', action='store_true', help='remove all stand-ins before running')
    ap.add_argument('--maxplayers', type=int, default=32)
    ap.add_argument('--port', type=int, default=27015)
    ap.add_argument('--boot-timeout', type=int, default=60)
    ap.add_argument('--echo', action='store_true', help='echo interesting console lines live')
    args = ap.parse_args(argv)

    vex_ini = os.path.join(SERVER, 'cstrike', 'addons', 'amxmodx', 'configs', 'plugins-vexmira.ini')
    _disable_vexmira(vex_ini, False)   # recover from an interrupted --no-vexmira / nav pass
    if not args.no_sync:
        sync_package()
    if not args.no_debug:
        # replace the repo symlink by a server-local copy with the AMXX "debug" flag (stack traces
        # with .sma line numbers); the next sync without debug restores the link
        src = os.path.join(REPO, 'cstrike', 'addons', 'amxmodx', 'configs', 'plugins-vexmira.ini')
        lines = []
        for l in open(src).read().splitlines():
            t = l.split(';')[0].strip()
            if t.endswith('.amxx'):
                l = t + ' debug'
            lines.append(l)
        if os.path.lexists(vex_ini):
            os.unlink(vex_ini)
        open(vex_ini, 'w').write('\n'.join(lines) + '\n')
    if args.no_probe:
        ensure_plugins_ini(probe=False)
    else:
        build_probe()
        ensure_plugins_ini(probe=True)
    if args.rebuild_plugin or not os.path.exists(
            os.path.join(SERVER, 'cstrike', 'addons', 'amxmodx', 'plugins', 'vexmira_zombie.amxx')):
        if not build_plugin():
            return 1

    sys.path.insert(0, HERE)
    import make_placeholders as MP
    if args.clean_stubs:
        print('[stub] removed %d stand-ins' % MP.clean_stubs(SERVER))
        sync_package(verbose=False)
    if args.stub_missing:
        pre = argparse.Namespace(**vars(args))
        pre.bots, pre.seconds, pre.commands, pre.cmd, pre.until_nav = 0, 3, None, None, False
        print('[stub] boot pass to collect missing files')
        missing = run(pre, quiet=True, collect_missing=True)
        made = MP.stub_files(sorted(set(missing) | set(MP.design_package_paths())), SERVER)
        print('[stub] %d missing reported, %d stand-ins created' % (len(missing), len(made)))
    nav = os.path.join(SERVER, 'cstrike', 'maps', args.map + '.nav')
    if args.ensure_nav and not os.path.exists(nav):
        print('[nav] %s missing -> learning pass (plugin disabled, 1 bot)' % os.path.basename(nav))
        navargs = argparse.Namespace(**vars(args))
        navargs.bots, navargs.seconds, navargs.until_nav, navargs.commands, navargs.cmd = 1, 900, True, None, None
        _disable_vexmira(vex_ini, True)
        try:
            run(navargs)
        finally:
            _disable_vexmira(vex_ini, False)
        print('[nav] %s' % ('saved %d bytes' % os.path.getsize(nav) if os.path.exists(nav) else 'NOT generated'))
    if args.no_vexmira:
        _disable_vexmira(vex_ini, True)
    try:
        rc = run(args)
    finally:
        if args.no_vexmira:
            _disable_vexmira(vex_ini, False)
    if args.export_nav and os.path.exists(nav) and not os.path.islink(nav):
        dst = os.path.join(REPO, 'cstrike', 'maps', os.path.basename(nav))
        shutil.copyfile(nav, dst)
        print('[nav] exported to %s' % dst)
    return rc


def _disable_vexmira(ini, off):
    off_path = ini + '.off'
    if off:
        if os.path.lexists(ini):
            os.replace(ini, off_path)
    else:
        if os.path.lexists(off_path):
            os.replace(off_path, ini)
        sync_package(verbose=False)


if __name__ == '__main__':
    sys.exit(main())
