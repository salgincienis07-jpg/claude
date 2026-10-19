#!/usr/bin/env python3
"""5.3.8 before/after precache + download table from test-server probe files.

    python3 devtools/v53/precache_table.py BEFORE_RUN_DIR AFTER_RUN_DIR zm_vexmira_7door zm_vexmira_dust2newv5

Each run dir holds vexprobe_precache_<map>.txt (every precached name with its slot). Download = files of
the precache list (models + sounds + generic) that ship in the repo cstrike/ tree (= custom content a
client downloads on first join; stock Valve files are not counted).
"""
import os
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'cstrike'))


def load(run, mp):
    p = os.path.join(run, 'vexprobe_precache_%s.txt' % mp)
    sec, out = None, {'MODELS': [], 'SOUNDS': [], 'GENERIC': []}
    for line in open(p, errors='replace'):
        if line.startswith('== '):
            sec = line.split()[1]
            continue
        parts = line.split(None, 1)
        if sec in out and len(parts) == 2:
            out[sec].append(parts[1].strip())
    return out


def dl(lst):
    files, size = set(), 0
    for sec, names in lst.items():
        for n in names:
            path = ('sound/' + n) if sec == 'SOUNDS' else n
            full = os.path.join(REPO, path)
            if path not in files and os.path.isfile(full):
                files.add(path)
                size += os.path.getsize(full)
    return len(files), size


def main():
    before, after, maps = sys.argv[1], sys.argv[2], sys.argv[3:]
    print('| map | state | sound | model | generic | custom files | download MB |')
    print('|---|---|---|---|---|---|---|')
    for mp in maps:
        for tag, run in (('before', before), ('after', after)):
            try:
                d = load(run, mp)
            except OSError:
                print('| %s | %s | - | - | - | - | - |' % (mp, tag))
                continue
            n, sz = dl(d)
            print('| %s | %s | %d | %d | %d | %d | %.1f |' % (mp, tag, len(d['SOUNDS']), len(d['MODELS']), len(d['GENERIC']), n, sz / 1048576.0))


if __name__ == '__main__':
    main()
