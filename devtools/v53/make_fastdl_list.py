"""FASTDL_LISTESI.txt: every custom file a player can download on the Vexmira server (all maps, all bosses,
all config paths), so the owner can fill the FastDL folder once.

Sources: every file path / model name in vexmira.cfg (owner assets included), the files the test server really
precached on the Vexmira maps (vexprobe dumps), the boss giant copies, the map list (bsp + res + their .res
entries) and everything this repo ships under cstrike/. Stock CS 1.6 content is left out.

    python3 devtools/v53/make_fastdl_list.py <out.txt> [extra maps...]
"""
import glob
import json
import os
import re
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
CS = os.path.join(REPO, 'cstrike')
SP = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad'
SRV = os.path.join(SP, 'server', 'cstrike')
EXT = ('.mdl', '.spr', '.wav', '.mp3', '.tga', '.bmp', '.wad', '.txt', '.bsp', '.res')
OBSOLETE = ('sound/vexmira/meme/', 'sound/vexmira/amb532/', 'sound/vexmira/skill532/', 'sound/vexmira/item533/', 'sound/vexmira/arena51/classes/', 'sprites/vexmira/c532/', 'sprites/vexmira/cso/', 'sprites/vexmira/c533/hp_', 'sprites/vexmira/c533/shp',
            'maps/zm_vex_testroom', 'maps/zm_vex_pilot')
DIRS = ('models/', 'sound/', 'sprites/', 'gfx/', 'maps/', 'overviews/', 'resource/')


def stock():
    out = set()
    p = os.path.join(SRV, 'placeholders_manifest.json')
    if os.path.exists(p):
        for m in json.load(open(p)):
            out.add(m['path'].split('/', 1)[1].lower() if '/' in m['path'] else m['path'].lower())
    return out


def owner_stubs():
    p = os.path.join(SRV, 'stubs_manifest.json')
    if not os.path.exists(p):
        return set()
    d = json.load(open(p))
    items = d if isinstance(d, list) else d.get('files', [])
    return set((x['path'] if isinstance(x, dict) else x).replace('cstrike/', '', 1).lower() for x in items)


def norm(v):
    v = v.strip().strip('"').replace('\\', '/').lstrip('/')
    if not v.lower().endswith(EXT):
        return None
    if v.lower().endswith(('.wav', '.mp3')) and not v.lower().startswith('sound/'):
        v = 'sound/' + v
    if not v.lower().startswith(DIRS):
        return None
    return v


def main():
    out_path = sys.argv[1]
    maps = [m for m in sys.argv[2:]]
    cfg = open(os.path.join(CS, 'addons/amxmodx/configs/vexmira.cfg'), encoding='latin-1').read()
    files = set()
    for line in cfg.splitlines():
        code = line.split('//', 1)[0]
        for tok in re.findall(r'"([^"]+)"', code) + code.split():
            for part in re.split(r'[\s,;|]+', tok):
                n = norm(part)
                if n:
                    files.add(n)
        m = re.match(r'\s*vex_res\s+(\w*MODEL\w*)\s+"([A-Za-z0-9_\-]+)"', code)
        if m and '/' not in m.group(2) and m.group(2):
            nm = m.group(2)
            files.add('models/player/%s/%s.mdl' % (nm, nm))
            if re.match(r'B\d_MODEL', m.group(1)):
                files.add('models/player/%s_x16/%s_x16.mdl' % (nm, nm))
    for d in glob.glob(os.path.join(SRV, 'addons/amxmodx/data/vexmira_fastdl_hepsi.txt')):
        for l in open(d):
            n = norm(l.split('//')[0])
            if n:
                files.add(n)
    runs = sorted(glob.glob(os.path.join(SP, 'server/runs/*_zm_vexmira_7door')))
    for dump in glob.glob(os.path.join(runs[-1], 'vexprobe_precache_zm_vexmira_7door.txt')) if runs else []:
        for l in open(dump, errors='ignore'):
            parts = l.split()
            if len(parts) >= 2:
                n = norm(parts[-1])
                if n:
                    files.add(n)
    vex_maps = []
    for b in glob.glob(os.path.join(CS, 'maps', 'zm_vexmira_*.bsp')):
        vex_maps.append(os.path.basename(b)[:-4])
    for m in vex_maps + maps:
        files.add('maps/%s.bsp' % m)
        res = os.path.join(CS, 'maps', m + '.res')
        if os.path.exists(res):
            files.add('maps/%s.res' % m)
            for l in open(res, errors='ignore'):
                n = norm(l.split('//')[0])
                if n:
                    files.add(n)
    st, own = stock(), owner_stubs()
    keep = []
    for f in sorted(files, key=str.lower):
        lf = f.lower()
        if lf in st or any(lf.startswith(x) for x in OBSOLETE):
            continue
        in_repo = os.path.exists(os.path.join(CS, f))
        if not (in_repo or lf in own or 'vex' in lf or f in cfg or lf.startswith('maps/')):
            continue
        keep.append((f, os.path.getsize(os.path.join(CS, f)) if in_repo else 0))
    with open(out_path, 'w', newline='\r\n') as o:
        o.write('// VEXMIRA ZOMBIE - FastDL DOSYA LISTESI (sunucudaki cstrike/ klasorune gore yollar)\n')
        o.write('// Bu dosyalarin HEPSINI FastDL klasorune AYNI klasor yapisiyla kopyala.\n')
        o.write('// Sunucuda olmayan bir dosya varsa atla (o model/ses o haritada kullanilmiyordur).\n')
        o.write('// Haritalarin .res dosyasi varsa, .res icinde yazan dosyalari da kopyala.\n')
        o.write('// Sunucu her harita acilisinda kendi listesini de yazar: addons/amxmodx/data/vexmira_fastdl_hepsi.txt\n')
        o.write('// Toplam %d dosya\n\n' % len(keep))
        cur = None
        for f, sz in keep:
            top = f.split('/')[0]
            if top != cur:
                o.write('\n// ---- %s ----\n' % top)
                cur = top
            o.write(f + '\n')
    print(out_path, len(keep))


if __name__ == '__main__':
    main()
