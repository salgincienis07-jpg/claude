#!/usr/bin/env python3
"""Vexmira render client: screenshots + r_speeds/fps from a REAL GoldSrc-protocol client.

Starts (optionally) the test server through devtools/server/run_test.py's machinery, a private
Xvfb display, and the Xash3D FWGS + cs16-client build from devtools/client/README.md; the client
connects with "connect 127.0.0.1:<port> gs" (GoldSrc protocol 48), joins as a spectator, and the
test-only AMXX helper devtools/client/vexcam.sma moves it to each requested view. Per view it
prints/saves the patched engine's "r_speeds_dump" line (wpoly/epoly/spoly/leafs/models/sprites
drawn + average fps over --fps-window seconds) and an engine screenshot (PNG) with a caption
strip.

    VEX_SERVER=$SP/serverF python3 devtools/client/shot.py --map zm_vex_laboratory --port 27065 \\
        --view "hall 0 0 64 10 90" --look "boss boss 260 30 0 50" \\
        --server-cmd "2 vex_boss 0" --server-cmd "3 sv_restart 1" --wait-boss 40 \\
        --out devtools/previews_client --prefix lab

View syntax (repeatable, taken in order: all --view first, then all --look; or use --views FILE):
    --view "<label> <x> <y> <z> <pitch> <yaw>"            fixed camera (pitch > 0 looks down)
    --look "<label> <target> [dist] [height] [yawoff] [aimz]"
          target = boss | #userid | ent:N | <player name part>; camera stands <dist> units in
          front of the target (its view yaw + yawoff), <height> above the aim point (origin+aimz)
    --views FILE   JSON list: {"label":..,"pos":[x,y,z],"ang":[pitch,yaw]} or
                              {"label":..,"look":"boss","dist":260,"height":30,"yawoff":0,"aimz":50}
Timed server commands (seconds after the client is in game): --server-cmd "<sec> <command>".
--wait-boss N: before the first --look on "boss", poll vexcam_status up to N s for a live boss.

Outputs: <out>/<prefix>_<label>.png (frame + caption), <out>/<prefix>_report.txt / .json, and the
raw client console log in the client dir (shot_client.log).
"""
import argparse
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
SP = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad'
CLIENT = os.environ.get('VEX_CLIENT', os.path.join(SP, 'client'))
GAME = os.path.join(CLIENT, 'game')
AMXXPC_DIR = os.path.join(SP, 'tools', 'bin')
ANSI = re.compile(r'\x1b\[[0-9;]*m')
RE_SPEEDS = re.compile(r'R_SPEEDS (.*)$')
RE_MODEL = re.compile(r'R_MODEL tris=(\d+) ents=(\d+) name=(\S+)')


def log(msg):
    print('[shot] %s' % msg, flush=True)


# ------------------------------------------------------------------------------------- Xvfb
class Display:
    def __init__(self, w, h):
        self.proc = None
        for n in range(90, 140):
            if not os.path.exists('/tmp/.X11-unix/X%d' % n) and not os.path.exists('/tmp/.X%d-lock' % n):
                self.num = n
                break
        else:
            raise SystemExit('no free X display number')
        self.proc = subprocess.Popen(['Xvfb', ':%d' % self.num, '-screen', '0', '%dx%dx24' % (w, h), '-nolisten', 'tcp'],
                                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(50):
            if os.path.exists('/tmp/.X11-unix/X%d' % self.num):
                break
            time.sleep(0.1)
        self.name = ':%d' % self.num

    def stop(self):
        if self.proc and self.proc.poll() is None:
            self.proc.terminate()
            try:
                self.proc.wait(5)
            except subprocess.TimeoutExpired:
                self.proc.kill()


# ------------------------------------------------------------------------------------- client
class Client:
    def __init__(self, args, display, server_dir):
        self.lines = []
        self.lock = threading.Lock()
        self.logf = open(os.path.join(CLIENT, 'shot_client.log'), 'w', buffering=1)
        cmd = ['./xash3d', '-game', 'cstrike', '-rodir', server_dir, '-dev', '1', '-windowed',
               '-width', str(args.width), '-height', str(args.height), '-nosound', '-stdincmd',
               '+cl_allowdownload', '0', '+name', args.name, '+fps_max', str(args.fps_max),
               '+r_speeds', str(args.rspeeds), '+hud_draw', '1' if args.hud else '0',
               '+con_notifytime', str(args.notify), '+cl_showfps', '0', '+scr_drawversion', '0',
               # no MOTD window, team/buy menus go to (disabled) touch configs instead of UI windows
               '+cl_hide_motd', '1', '+cl_oldtouchmenus', '1',
               # cs16-client patch: no dark spectator bars / status line over the picture
               '+vexcam_specbars', '1' if args.specbars else '0',
               '+connect', '%s gs' % args.connect]
        env = dict(os.environ, DISPLAY=display, SDL_AUDIODRIVER='dummy',
                   LD_LIBRARY_PATH=GAME + ':' + os.environ.get('LD_LIBRARY_PATH', ''))
        self.t0 = time.monotonic()
        self.proc = subprocess.Popen(cmd, cwd=GAME, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
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
                text = ANSI.sub('', line.decode('utf-8', 'replace')).rstrip('\r')
                with self.lock:
                    self.lines.append((time.monotonic(), text))
                self.logf.write('[%7.2f] %s\n' % (time.monotonic() - self.t0, text))

    def send(self, cmd):
        if self.proc.poll() is not None:
            return False
        self.logf.write('[%7.2f] >>> %s\n' % (time.monotonic() - self.t0, cmd))
        try:
            self.proc.stdin.write((cmd + '\n').encode())
            self.proc.stdin.flush()
        except (BrokenPipeError, OSError):
            return False
        return True

    def since(self, t):
        with self.lock:
            return [l for (tt, l) in self.lines if tt >= t]

    def wait_line(self, pattern, t_from, timeout):
        rx = re.compile(pattern)
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            for l in self.since(t_from):
                m = rx.search(l)
                if m:
                    return m
            if self.proc.poll() is not None:
                return None
            time.sleep(0.1)
        return None

    def alive(self):
        return self.proc.poll() is None

    def stop(self):
        if self.alive():
            self.send('disconnect')
            self.send('quit')
            try:
                self.proc.wait(8)
            except subprocess.TimeoutExpired:
                self.proc.terminate()
                try:
                    self.proc.wait(4)
                except subprocess.TimeoutExpired:
                    self.proc.kill()
        self.logf.close()


# ------------------------------------------------------------------------------------- server
def server_module(server_dir):
    os.environ['VEX_SERVER'] = server_dir
    sys.path.insert(0, os.path.join(REPO, 'devtools', 'server'))
    import run_test
    return run_test


def install_vexcam(server_dir):
    """Compile devtools/client/vexcam.sma into the server and list it in plugins-vexcam.ini."""
    plugins = os.path.join(server_dir, 'cstrike', 'addons', 'amxmodx', 'plugins')
    out = os.path.join(plugins, 'vexcam.amxx')
    src = os.path.join(HERE, 'vexcam.sma')
    if not os.path.exists(out) or os.path.getmtime(out) < os.path.getmtime(src):
        p = subprocess.run([os.path.join(AMXXPC_DIR, 'amxxpc'), src, '-i' + os.path.join(AMXXPC_DIR, 'include'),
                            '-o' + out], capture_output=True, text=True, cwd=AMXXPC_DIR)
        if p.returncode != 0 or not os.path.exists(out):
            raise SystemExit('vexcam.sma build failed:\n' + p.stdout[-2000:])
        log('built %s' % out)
    ini = os.path.join(server_dir, 'cstrike', 'addons', 'amxmodx', 'configs', 'plugins-vexcam.ini')
    with open(ini, 'w') as f:
        f.write('vexcam.amxx\t; devtools/client render camera (test server only)\n')


def start_server(args):
    rt = server_module(args.server)
    if not args.no_sync:
        rt.sync_package(verbose=False)
    if not rt.build_probe():
        raise SystemExit('vexprobe build failed')
    rt.ensure_plugins_ini(probe=True)
    if args.rebuild_plugin or (not args.no_rebuild and rt.plugin_stale()):
        if not rt.build_plugin(retries=1):
            raise SystemExit('plugin build failed')
    install_vexcam(args.server)
    rt.set_vexmira_ini(enabled=True, debug=False)
    stamp = time.strftime('%Y%m%d_%H%M%S')
    rundir = os.path.join(args.server, 'runs', '%s_%s_shot' % (stamp, args.map))
    os.makedirs(rundir, exist_ok=True)
    ns = argparse.Namespace(map=args.map, port=args.port, maxplayers=args.maxplayers, echo=False,
                            boot_timeout=60, seconds=0, until_nav=False)
    srv = rt.Server(ns, rundir)
    srv.launch()
    if not srv.map_up.wait(60):
        srv.stop()
        raise SystemExit('server map did not come up')
    args.port = ns.port
    log('server up: %s on port %d (run dir %s)' % (args.map, ns.port, rundir))
    srv.send('mp_consistency 0')      # placeholder models: FWGS and HLDS hash them differently
    srv.send('sv_allowdownload 0')
    srv.send('vex_precache_stats')
    if args.bots:
        srv.send('bot_quota %d' % args.bots)
    return srv


def server_lines_since(srv, t):
    with srv.lock:
        return [l for (tt, l) in srv.lines if tt >= t - srv.start]


def server_query(srv, cmd, pattern, timeout=3.0):
    t = time.monotonic()
    srv.send(cmd)
    end = t + timeout
    out = []
    while time.monotonic() < end:
        out = [l for l in server_lines_since(srv, t) if re.search(pattern, l)]
        if out:
            time.sleep(0.3)      # let multi-line answers finish
            return [l for l in server_lines_since(srv, t) if re.search(pattern, l)]
        time.sleep(0.1)
    return out


# ------------------------------------------------------------------------------------- views
def parse_views(args):
    views = []
    for v in args.view or []:
        p = v.split()
        if len(p) != 6:
            raise SystemExit('--view needs "<label> x y z pitch yaw": %r' % v)
        views.append({'label': p[0], 'pos': [float(x) for x in p[1:4]], 'ang': [float(p[4]), float(p[5])]})
    for v in args.look or []:
        p = v.split()
        if len(p) < 2:
            raise SystemExit('--look needs "<label> <target> [dist height yawoff aimz]": %r' % v)
        d = {'label': p[0], 'look': p[1]}
        for k, val in zip(('dist', 'height', 'yawoff', 'aimz'), p[2:]):
            d[k] = float(val)
        views.append(d)
    if args.views:
        views += json.load(open(args.views))
    return views


def place_cmd(v):
    if 'look' in v:
        return 'vexcam_look %s %g %g %g %g %d' % (v['look'], v.get('dist', 220), v.get('height', 40),
                                                 v.get('yawoff', 0), v.get('aimz', 40), 1 if v.get('track', True) else 0)
    return 'vexcam_pos %g %g %g %g %g' % (tuple(v['pos']) + tuple(v['ang']))


def parse_speeds(line):
    d = {}
    for kv in line.split():
        if '=' in kv:
            k, val = kv.split('=', 1)
            try:
                d[k] = float(val) if '.' in val else int(val)
            except ValueError:
                d[k] = val
    return d


def caption(png_in, png_out, lines):
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        shutil.copy(png_in, png_out)
        return
    im = Image.open(png_in).convert('RGB')
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf', 14)
    strip = 8 + 18 * len(lines)
    out = Image.new('RGB', (im.width, im.height + strip), (16, 16, 20))
    out.paste(im, (0, 0))
    d = ImageDraw.Draw(out)
    for i, l in enumerate(lines):
        d.text((8, im.height + 4 + 18 * i), l, font=font, fill=(235, 235, 235) if i == 0 else (170, 210, 255))
    out.save(png_out, optimize=True)


# ------------------------------------------------------------------------------------- main
def main(argv=None):
    ap = argparse.ArgumentParser(description='Vexmira render client: screenshots + r_speeds/fps')
    ap.add_argument('--server', default=os.environ.get('VEX_SERVER', os.path.join(SP, 'server')),
                    help='server dir (run_test.py layout); its valve/ + cstrike/ are mounted read-only (-rodir)')
    ap.add_argument('--map', default='zm_vex_laboratory')
    ap.add_argument('--port', type=int, default=27065)
    ap.add_argument('--maxplayers', type=int, default=32)
    ap.add_argument('--bots', type=int, default=0)
    ap.add_argument('--attach', action='store_true',
                    help='do not start a server: connect to --connect and only take spectator shots '
                         '(no vexcam positioning, no server commands)')
    ap.add_argument('--connect', help='address for --attach (default 127.0.0.1:<port>)')
    ap.add_argument('--no-sync', action='store_true')
    ap.add_argument('--no-rebuild', action='store_true', help='never compile the Vexmira plugin')
    ap.add_argument('--rebuild-plugin', action='store_true')
    ap.add_argument('--view', action='append')
    ap.add_argument('--look', action='append')
    ap.add_argument('--views')
    ap.add_argument('--server-cmd', action='append', help='"<sec> <command>" after the client is in game')
    ap.add_argument('--client-cmd', action='append', help='"<sec> <command>" for the client console')
    ap.add_argument('--wait-boss', type=float, default=0.0)
    ap.add_argument('--freeze', action='store_true', help='freeze a --look target (FL_FROZEN) while shooting it')
    ap.add_argument('--put', action='append',
                    help='"<target> x y z [yaw]": before each --look at <target>, teleport it there (dropped to '
                         'the floor, turned to yaw, frozen) - deterministic boss shots')
    ap.add_argument('--settle', type=float, default=1.5, help='seconds between positioning and measuring')
    ap.add_argument('--fps-window', type=float, default=3.0)
    ap.add_argument('--fps-max', type=int, default=200)
    ap.add_argument('--rspeeds', type=int, default=1, help='r_speeds mode drawn on screen (0 = off)')
    ap.add_argument('--no-hud', dest='hud', action='store_false')
    ap.add_argument('--specbars', action='store_true', help='keep the spectator top/bottom bars + status line')
    ap.add_argument('--notify', type=float, default=0.0, help='con_notifytime (0 hides console notify lines)')
    ap.add_argument('--width', type=int, default=1280)
    ap.add_argument('--height', type=int, default=720)
    ap.add_argument('--name', default='vexcam')
    ap.add_argument('--out', default=os.path.join(REPO, 'devtools', 'previews_client'))
    ap.add_argument('--prefix', default=None)
    ap.add_argument('--join-timeout', type=float, default=60.0)
    ap.add_argument('--hold', type=float, default=0.0, help='keep everything running N s after the last shot')
    args = ap.parse_args(argv)
    args.server = os.path.abspath(args.server)
    prefix = args.prefix or args.map
    views = parse_views(args)
    puts = {}
    for pt in args.put or []:
        puts.setdefault(pt.split()[0], []).append(pt)

    if not os.path.exists(os.path.join(GAME, 'xash3d')):
        raise SystemExit('client not built: see devtools/client/README.md (setup_client.sh)')
    if not os.path.exists(os.path.join(GAME, 'cstrike', 'sprites', 'hud.txt')):
        subprocess.check_call([sys.executable, os.path.join(HERE, 'make_client_gfx.py'), '--out', GAME])
    os.makedirs(args.out, exist_ok=True)
    shotdir = os.path.join(GAME, 'cstrike', 'scrshots')
    os.makedirs(shotdir, exist_ok=True)

    srv = None
    disp = None
    cl = None
    report = {'map': args.map, 'server': args.server, 'width': args.width, 'height': args.height,
              'renderer': None, 'views': []}

    def cleanup(*_):
        for x in (cl, srv, disp):
            try:
                if x:
                    x.stop()
            except Exception as e:      # noqa: BLE001 - teardown must continue
                log('cleanup: %s' % e)

    signal.signal(signal.SIGTERM, lambda *_: (cleanup(), sys.exit(3)))
    try:
        if not args.attach:
            srv = start_server(args)
        args.connect = args.connect or '127.0.0.1:%d' % args.port
        disp = Display(args.width, args.height)
        t_cl = time.monotonic()
        cl = Client(args, disp.name, args.server)
        log('client started on display %s -> connect %s gs' % (disp.name, args.connect))

        # in game?
        if srv:
            end = time.monotonic() + args.join_timeout
            joined = False
            while time.monotonic() < end and cl.alive():
                if server_query(srv, 'vexcam_status', r'\[vexcam\] cam', 1.0):
                    joined = True
                    break
                time.sleep(1.0)
            if not joined:
                raise SystemExit('client did not join within %ds (see %s/shot_client.log)' % (args.join_timeout, CLIENT))
        else:
            if not cl.wait_line(r'Remote host:|connected', t_cl, args.join_timeout):
                raise SystemExit('client did not connect (see %s/shot_client.log)' % CLIENT)
        m = cl.wait_line(r'GL_RENDERER: (.*)', t_cl, 1)
        report['renderer'] = m.group(1).strip() if m else None
        log('client in game')
        time.sleep(2.0)
        cl.send('jointeam 6')
        time.sleep(1.0)
        cl.send('spec_mode 3')
        t_game = time.monotonic()

        timed = []
        for spec, who in ((args.server_cmd, 'srv'), (args.client_cmd, 'cl')):
            for c in spec or []:
                mm = re.match(r'^(\d+(?:\.\d+)?)\s+(.*)$', c.strip())
                timed.append((float(mm.group(1)) if mm else 0.0, who, mm.group(2) if mm else c))
        timed.sort(key=lambda x: x[0])

        def run_timed(until):
            while timed and timed[0][0] <= until:
                _, who, c = timed.pop(0)
                log('t=%.1f %s> %s' % (time.monotonic() - t_game, who, c))
                (srv.send if who == 'srv' and srv else cl.send)(c)

        def sleep_timed(sec):
            end = time.monotonic() + sec
            while time.monotonic() < end:
                run_timed(time.monotonic() - t_game)
                time.sleep(0.05)

        sleep_timed(2.0)
        boss_waited = False
        for i, v in enumerate(views):
            label = re.sub(r'[^A-Za-z0-9_.-]', '_', v['label'])
            if srv:
                if v.get('look') == 'boss' and args.wait_boss and not boss_waited:
                    boss_waited = True
                    end = time.monotonic() + args.wait_boss
                    while time.monotonic() < end:
                        run_timed(time.monotonic() - t_game)
                        st = server_query(srv, 'vexcam_status', r'\[vexcam\] (boss|overhead)', 1.0)
                        if any('] boss ' in l and 'boss none' not in l for l in st) and \
                                any('overhead' in l and 'bossbar' in l for l in st):
                            break
                        sleep_timed(1.0)
                    sleep_timed(1.0)
                run_timed(time.monotonic() - t_game)
                placed = []
                for pt in puts.get(v.get('look'), []):
                    placed += server_query(srv, 'vexcam_put %s' % pt, r'\[vexcam\] put', 2.0)
                if placed:
                    sleep_timed(0.5)      # let the overhead entities follow the teleported target
                placed += server_query(srv, place_cmd(v), r'\[vexcam\] (pos|look)', 2.0)
                if v.get('look') and args.freeze:
                    srv.send('vexcam_freeze %s 1' % v['look'])
            else:
                placed = []
            sleep_timed(args.settle)
            t_m = time.monotonic()
            cl.send('r_speeds_dump')
            sleep_timed(args.fps_window)
            cl.send('r_speeds_dump models')
            cl.wait_line(r'R_MODELS_END', t_m, 3.0)
            dumps = [RE_SPEEDS.search(l).group(1) for l in cl.since(t_m) if RE_SPEEDS.search(l)]
            speeds = parse_speeds(dumps[-1]) if dumps else {}
            models = []
            for l in cl.since(t_m):
                mm = RE_MODEL.search(l)
                if mm:
                    models.append({'name': mm.group(3), 'tris': int(mm.group(1)), 'ents': int(mm.group(2))})
            raw = os.path.join(shotdir, '%s_%s.png' % (prefix, label))
            if os.path.exists(raw):
                os.unlink(raw)
            cl.send('screenshot scrshots/%s_%s.png' % (prefix, label))
            for _ in range(80):
                if os.path.exists(raw) and os.path.getsize(raw) > 0:
                    time.sleep(0.3)
                    break
                time.sleep(0.1)
            status = server_query(srv, 'vexcam_status', r'\[vexcam\] (cam|boss|overhead)', 1.5) if srv else []
            if v.get('look') and args.freeze and srv:
                srv.send('vexcam_freeze %s 0' % v['look'])
            if srv:
                srv.send('vexcam_stop')
            entry = {'label': v['label'], 'view': v, 'placed': [l.split('] ', 1)[-1] for l in placed],
                     'r_speeds': speeds, 'models': models,
                     'status': [l.split('] ', 1)[-1] for l in status], 'png': None}
            if os.path.exists(raw):
                out = os.path.join(args.out, '%s_%s.png' % (prefix, label))
                cam = [l for l in entry['status'] if l.startswith('cam ')]
                lines = ['%s  %s  view "%s"  %dx%d  %s' % (prefix, args.map, v['label'], args.width, args.height,
                                                          report['renderer'] or 'GL')]
                if speeds:
                    lines.append('wpoly %s  epoly %s  spoly %s  leafs %s  studio %s  sprites %s  ents %s  '
                                 'tents %s  particles %s  fps %s (avg %.1fs, software GL)' % (
                                     speeds.get('wpoly'), speeds.get('epoly'), speeds.get('spoly'),
                                     speeds.get('leafs'), speeds.get('studio_drawn'), speeds.get('sprites_drawn'),
                                     speeds.get('ents'), speeds.get('tents'), speeds.get('particles'),
                                     speeds.get('fps'), speeds.get('secs', 0)))
                if models:
                    lines.append('epoly by model: ' + '  '.join(
                        '%s %d/%d' % (os.path.basename(m['name']), m['tris'], m['ents']) for m in models[:5]) +
                        ('  (+%d more)' % (len(models) - 5) if len(models) > 5 else ''))
                if cam:
                    lines.append(cam[0])
                for l in entry['status']:
                    if l.startswith('boss ') or l.startswith('overhead '):
                        lines.append(l[:170])
                caption(raw, out, lines)
                entry['png'] = os.path.relpath(out, REPO)
            report['views'].append(entry)
            log('%-12s %s  png=%s' % (v['label'], ' '.join('%s=%s' % (k, speeds.get(k)) for k in
                                                          ('wpoly', 'epoly', 'spoly', 'leafs', 'fps')),
                                       entry['png']))
            for l in entry['placed'] + entry['status']:
                log('    %s' % l)
        if args.hold:
            sleep_timed(args.hold)
    finally:
        cleanup()

    rep_json = os.path.join(args.out, '%s_report.json' % prefix)
    with open(rep_json, 'w') as f:
        json.dump(report, f, indent=1)
    with open(os.path.join(args.out, '%s_report.txt' % prefix), 'w') as f:
        f.write('render client report: map %s, %dx%d, renderer %s\n' % (args.map, args.width, args.height,
                                                                        report['renderer']))
        for e in report['views']:
            f.write('\n[%s] %s\n' % (e['label'], e['png']))
            if e['r_speeds']:
                f.write('  r_speeds: %s\n' % ' '.join('%s=%s' % kv for kv in e['r_speeds'].items()))
            for m in e['models']:
                f.write('  model %6d tris %3d ents  %s\n' % (m['tris'], m['ents'], m['name']))
            for l in e['placed'] + e['status']:
                f.write('  %s\n' % l)
    log('report: %s' % rep_json)
    return 0 if all(e['png'] for e in report['views']) else 1


if __name__ == '__main__':
    sys.exit(main())
