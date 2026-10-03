#!/usr/bin/env python3
"""Reader / validator for CS 1.6 bot navigation meshes (maps/<map>.nav, ZBot format v5).

Format = ReGameDLL game_shared/bot/nav_file.cpp (SaveNavigationMap / CNavArea::Save), 32-bit:
  u32 magic 0xFEEDFACE, u32 version (5), u32 bsp file size,
  place directory: u16 count, count x (u16 len, char[len]),
  u32 area count, per area:
    u32 id, u8 flags, f32 extent[6] (lo xyz, hi xyz), f32 neZ, f32 swZ,
    4 x (u32 n, u32 ids[n])                       connections N/E/S/W
    u8 n, n x (u32 id, f32 pos[3], u8 flags)      hiding spots
    u8 n, n x (u32 here, u32 prev, u8 how, u32 next, u8 how)   approach areas
    u32 n, n x (u32 from, u8 dir, u32 to, u8 dir, u8 k, k x (u32 spot, u8 t))  encounter paths
    u16 place

    python3 devtools/server/navfile.py cstrike/maps/zm_vex_harbor.nav [--bsp cstrike/maps/zm_vex_harbor.bsp]
"""
import os
import struct
import sys

MAGIC = 0xFEEDFACE


class NavError(ValueError):
    pass


class _R:
    def __init__(self, data):
        self.d = data
        self.o = 0

    def take(self, fmt):
        n = struct.calcsize(fmt)
        if self.o + n > len(self.d):
            raise NavError('truncated at byte %d' % self.o)
        v = struct.unpack_from(fmt, self.d, self.o)
        self.o += n
        return v


def read_nav(path):
    data = open(path, 'rb').read()
    r = _R(data)
    magic, version = r.take('<II')
    if magic != MAGIC:
        raise NavError('bad magic 0x%08X' % magic)
    if version != 5:
        raise NavError('unsupported nav version %d (expected 5)' % version)
    bsp_size, = r.take('<I')
    nplaces, = r.take('<H')
    places = []
    for _ in range(nplaces):
        ln, = r.take('<H')
        places.append(r.take('<%ds' % ln)[0].rstrip(b'\0').decode('latin-1'))
    narea, = r.take('<I')
    areas = []
    nhide = nenc = 0
    for _ in range(narea):
        aid, flags = r.take('<IB')
        ext = r.take('<6f')
        nez, swz = r.take('<2f')
        conn = []
        for _d in range(4):
            n, = r.take('<I')
            conn.append(list(r.take('<%dI' % n)) if n else [])
        n, = r.take('<B')
        for _h in range(n):
            r.take('<I3fB')
        nhide += n
        n, = r.take('<B')
        for _a in range(n):
            r.take('<IIBIB')
        n, = r.take('<I')
        nenc += n
        for _e in range(n):
            r.take('<IBIB')
            k, = r.take('<B')
            r.take('<' + 'IB' * k)
        place, = r.take('<H')
        areas.append({'id': aid, 'flags': flags, 'lo': ext[:3], 'hi': ext[3:], 'nez': nez, 'swz': swz,
                      'connect': conn, 'place': place})
    if r.o != len(data):
        raise NavError('%d trailing bytes' % (len(data) - r.o))
    return {'path': path, 'bytes': len(data), 'version': version, 'bsp_size': bsp_size, 'places': places,
            'areas': areas, 'hiding_spots': nhide, 'encounter_paths': nenc}


def floor_z(a, x, y):
    """Interpolated floor height of an area at (x, y) (same as CNavArea::GetZ)."""
    lo, hi = a['lo'], a['hi']
    dx, dy = hi[0] - lo[0], hi[1] - lo[1]
    u = 0.0 if dx <= 0 else min(1.0, max(0.0, (x - lo[0]) / dx))
    v = 0.0 if dy <= 0 else min(1.0, max(0.0, (y - lo[1]) / dy))
    north = lo[2] + u * (a['nez'] - lo[2])
    south = a['swz'] + u * (hi[2] - a['swz'])
    return north + v * (south - north)


def area_at(nav, p, tol=4.0):
    """Area under point p (player origin, hull center 36 above the feet), or None."""
    feet = p[2] - 36.0
    best = None
    for a in nav['areas']:
        lo, hi = a['lo'], a['hi']
        if lo[0] - tol <= p[0] <= hi[0] + tol and lo[1] - tol <= p[1] <= hi[1] + tol:
            dz = feet - floor_z(a, p[0], p[1])
            if -20.0 <= dz <= 40.0 and (best is None or abs(dz) < best[0]):
                best = (abs(dz), a)
    return best[1] if best else None


def components(nav):
    """Connected components (connections treated as undirected), largest first."""
    ids = {a['id']: a for a in nav['areas']}
    adj = {i: set() for i in ids}
    for a in nav['areas']:
        for lst in a['connect']:
            for b in lst:
                if b in adj:
                    adj[a['id']].add(b)
                    adj[b].add(a['id'])
    seen, comps = set(), []
    for i in ids:
        if i in seen:
            continue
        stack, comp = [i], []
        seen.add(i)
        while stack:
            k = stack.pop()
            comp.append(k)
            for n in adj[k]:
                if n not in seen:
                    seen.add(n)
                    stack.append(n)
        comps.append(comp)
    comps.sort(key=len, reverse=True)
    return comps


def validate(nav_path, bsp_path=None):
    """-> (ok, report dict). Checks format, bsp size stamp, area count, spawn coverage."""
    rep = {'nav': nav_path, 'errors': [], 'warnings': []}
    try:
        nav = read_nav(nav_path)
    except (OSError, NavError, struct.error) as e:
        rep['errors'].append('parse failed: %s' % e)
        return False, rep
    rep.update({'bytes': nav['bytes'], 'areas': len(nav['areas']), 'hiding_spots': nav['hiding_spots'],
                'encounter_paths': nav['encounter_paths'], 'places': len(nav['places'])})
    if len(nav['areas']) < 10:
        rep['errors'].append('only %d nav areas' % len(nav['areas']))
    comps = components(nav)
    rep['components'] = [len(c) for c in comps[:6]]
    if bsp_path:
        size = os.path.getsize(bsp_path)
        rep['bsp_size'] = size
        if size != nav['bsp_size']:
            rep['errors'].append('nav was made for a bsp of %d bytes, map is %d bytes (stale nav)' % (
                nav['bsp_size'], size))
        try:
            sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            from mapkit.bspcheck import BSP
            ents = BSP(bsp_path).entities
        except Exception as e:  # noqa: BLE001 - report, do not crash the harness
            rep['warnings'].append('bsp entities not read: %s' % e)
            ents = []
        main = set(comps[0]) if comps else set()
        cov = {'ct': [0, 0], 't': [0, 0]}
        off_main = 0
        uncovered = []
        for e in ents:
            cls = e.get('classname')
            if cls not in ('info_player_start', 'info_player_deathmatch'):
                continue
            team = 'ct' if cls == 'info_player_start' else 't'
            try:
                p = [float(x) for x in e.get('origin', '0 0 0').split()]
            except ValueError:
                continue
            p[2] += 1.0
            cov[team][1] += 1
            a = area_at(nav, p)
            if a is not None:
                cov[team][0] += 1
                if a['id'] not in main:
                    off_main += 1
            elif len(uncovered) < 8:
                uncovered.append('%s %.0f %.0f %.0f' % (team, p[0], p[1], p[2]))
        rep['spawn_coverage'] = {k: '%d/%d' % tuple(v) for k, v in cov.items()}
        miss = sum(v[1] - v[0] for v in cov.values())
        if miss:
            rep['warnings'].append('%d spawn points have no nav area under them: %s' % (miss, ', '.join(uncovered)))
        if off_main:
            rep['warnings'].append('%d spawn points are on nav islands not connected to the main mesh' % off_main)
    if len(comps) > 1:
        small = sum(len(c) for c in comps[1:])
        rep['warnings'].append('%d disconnected nav islands (%d areas outside the main mesh of %d)' % (
            len(comps) - 1, small, len(comps[0])))
    return not rep['errors'], rep


def format_report(rep):
    s = '%s: %s' % (os.path.basename(rep['nav']), 'OK' if not rep['errors'] else 'FAILED')
    if 'areas' in rep:
        s += '  %d bytes, %d areas, %d hiding spots, %d encounter paths, components %s' % (
            rep['bytes'], rep['areas'], rep['hiding_spots'], rep['encounter_paths'], rep.get('components'))
    if 'spawn_coverage' in rep:
        s += ', spawns on mesh CT %s T %s' % (rep['spawn_coverage']['ct'], rep['spawn_coverage']['t'])
    for e in rep['errors']:
        s += '\n   ERROR ' + e
    for w in rep['warnings']:
        s += '\n   warn  ' + w
    return s


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('nav', nargs='+')
    ap.add_argument('--bsp', help='bsp to check against (default: same name next to the .nav)')
    a = ap.parse_args(argv)
    rc = 0
    for n in a.nav:
        bsp = a.bsp or (os.path.splitext(n)[0] + '.bsp')
        ok, rep = validate(n, bsp if os.path.exists(bsp) else None)
        print(format_report(rep))
        rc |= 0 if ok else 1
    return rc


if __name__ == '__main__':
    sys.exit(main())
