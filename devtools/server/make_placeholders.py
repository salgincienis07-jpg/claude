#!/usr/bin/env python3
"""Generate the Valve-content PLACEHOLDERS a headless CS 1.6 test server needs.

Steam's CDN is unreachable from the build machine, so the dedicated test server
($SP/server) has no Valve game content. Everything the engine / ReGameDLL insist on
loading at map start is generated here, procedurally and minimal but *valid*:

  * WAD3 files        valve/gfx.wad, valve/fonts.wad (empty), cstrike/decals.wad (every decal
                      name ReGameDLL registers, 16x16 masked miptex)
  * studio models     studiomdl-compiled (IDST v10) tiny boxes; every player model gets a
                      9-bone skeleton with CS hitgroups (head/chest/stomach/arms/legs) and the
                      full CS player sequence list (names + activities) so LookupSequence /
                      LookupActivity in ReGameDLL resolve exactly like with the real models.
  * sprites           16x16 single frame SPR v2 (sprkit.sprlib.write_spr)
  * text files        liblist.gam (-> Metamod-R), metamod plugins.ini, server.cfg, mapcycle.txt,
                      botprofile.db, sound/materials.txt, maps/default.txt-less, motd.txt

None of this is shipped with the package; it lives only in the server tree.
A manifest (cstrike/placeholders_manifest.json) records every generated file.

    python3 devtools/server/make_placeholders.py [--server DIR] [--force] [--extra models/foo.mdl ...]
"""
import argparse
import json
import re
import os
import shutil
import struct
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
DEVTOOLS = os.path.dirname(HERE)
sys.path.insert(0, DEVTOOLS)

SP = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad'
DEFAULT_SERVER = os.path.join(SP, 'server')
WORK = os.path.join(SP, 'srvx', 'placeholder_work')

from mdlkit.bmp8 import write_bmp8           # noqa: E402
from mdlkit.compile import run_studiomdl     # noqa: E402
from mdlkit.mdl_read import MDL              # noqa: E402
from mdlkit.anims import sequence_table      # noqa: E402
from sprkit.sprlib import write_spr, read_spr, VP_PARALLEL, TF_ADDITIVE  # noqa: E402
from mapkit.wad import make_miptex, write_wad, read_wad  # noqa: E402

# ----------------------------------------------------------------------------- lists
# Every model / sprite literal in ReGameDLL 5.30 (dlls/, game_shared/, pm_shared/) that is
# precached unconditionally or by common entities, + extras found by booting the server.
PLAYER_MODELS = ['player.mdl'] + ['player/%s/%s.mdl' % (n, n) for n in (
    'arctic', 'gign', 'gsg9', 'guerilla', 'leet', 'militia', 'sas', 'spetsnaz', 'terror', 'urban', 'vip')]
WEAPONS = ['ak47', 'aug', 'awp', 'c4', 'deagle', 'elite', 'famas', 'fiveseven', 'flashbang', 'g3sg1', 'galil',
           'glock18', 'hegrenade', 'knife', 'm249', 'm3', 'm4a1', 'mac10', 'mp5', 'p228', 'p90', 'scout', 'sg550',
           'sg552', 'smokegrenade', 'tmp', 'ump45', 'usp', 'xm1014']
SHIELD_WEAPONS = ['deagle', 'fiveseven', 'flashbang', 'glock18', 'hegrenade', 'knife', 'p228', 'smokegrenade', 'usp']
PROP_MODELS = (
    ['%s_%s.mdl' % (p, w) for w in WEAPONS for p in ('v', 'p', 'w')]
    + ['shield/%s_shield_%s.mdl' % (p, w) for w in SHIELD_WEAPONS for p in ('v', 'p')]
    + ['p_shield.mdl', 'w_shield.mdl', 'w_9mmclip.mdl', 'w_antidote.mdl', 'w_assault.mdl', 'w_backpack.mdl',
       'w_battery.mdl', 'w_kevlar.mdl', 'w_longjump.mdl', 'w_medkit.mdl', 'w_oxygen.mdl', 'w_security.mdl',
       'w_shotbox.mdl', 'w_thighpack.mdl', 'w_weaponbox.mdl', 'grenade.mdl', 'pshell.mdl', 'rshell.mdl',
       'rshell_big.mdl', 'shotgunshell.mdl', 'agibs.mdl', 'hgibs.mdl', 'can.mdl', 'ceilinggibs.mdl',
       'cindergibs.mdl', 'computergibs.mdl', 'fleshgibs.mdl', 'germangibs.mdl', 'germanygibs.mdl',
       'glassgibs.mdl', 'metalplategibs.mdl', 'rockgibs.mdl', 'woodgibs.mdl', 'stickygib.mdl', 'prdroid.mdl',
       'scientist.mdl', 'hostageA.mdl', 'hostageB.mdl', 'hostageC.mdl', 'hostageD.mdl',
       # used by AMXX stock plugins / fallbacks in vexmira_zombie.sma
       'v_tripmine.mdl', 'w_c4.mdl'])
SPRITES = ['WXplo1', 'b-tele1', 'black_smoke1', 'black_smoke2', 'black_smoke3', 'black_smoke4', 'blood',
           'bloodspray', 'bubble', 'c-tele1', 'eexplo', 'explode1', 'fast_wallpuff1', 'fexplo', 'fexplo1', 'flare1',
           'flare6', 'gas_puff_01', 'laserbeam', 'laserdot', 'ledglow', 'lgtning', 'pistol_smoke1',
           'pistol_smoke2', 'radio', 'rifle_smoke1', 'rifle_smoke2', 'rifle_smoke3', 'shadow_circle', 'smoke',
           'smokepuff', 'steam1', 'voiceicon', 'wall_puff1', 'wall_puff2', 'wall_puff3', 'wall_puff4',
           'zerogxplode',
           # common in AMXX plugins (vexmira_zombie.sma checks file_exists before using them)
           'shockwave', 'dot', 'xbeam1', 'plasma', 'muzzleflash', 'muzzleflash1', 'muzzleflash2', 'muzzleflash3',
           'xspark1', 'xspark4', 'laser', 'zbeam1', 'zbeam2', 'zbeam3', 'zbeam4', 'zbeam5', 'zbeam6', 'blueflare1',
           'redflare1', 'animglow01', 'glow01', 'spotlight01', 'hotglow', 'gargeye1', 'flare3', 'lgtning',
           'iunknown', 'arrow1', 'blast', 'explode1', 'smoke', 'ballsmoke', 'blueflare2', 'redflare2', 'yelflare1',
           'yelflare2', 'xenobeam', 'sw_ripple', 'wsplash3', 'fire', 'flame', 'fthrow', 'tele1', 'xflare1',
           'spray']
DECALS = ['{shot1', '{shot2', '{shot3', '{shot4', '{shot5', '{lambda01', '{lambda02', '{lambda03', '{lambda04',
          '{lambda05', '{lambda06', '{scorch1', '{scorch2', '{blood1', '{blood2', '{blood3', '{blood4', '{blood5',
          '{blood6', '{yblood1', '{yblood2', '{yblood3', '{yblood4', '{yblood5', '{yblood6', '{break1', '{break2',
          '{break3', '{bigshot1', '{bigshot2', '{bigshot3', '{bigshot4', '{bigshot5', '{spit1', '{spit2',
          '{bproof1', '{gargstomp', '{smscorch1', '{smscorch2', '{smscorch3', '{mommablob']

EVENTS = ['ak47', 'aug', 'awp', 'createexplo', 'createsmoke', 'deagle', 'decal_reset', 'elite_left', 'elite_right',
          'famas', 'fiveseven', 'g3sg1', 'galil', 'glock18', 'knife', 'm249', 'm3', 'm4a1', 'mac10', 'mp5n', 'p228',
          'p90', 'scout', 'sg550', 'sg552', 'tmp', 'train', 'ump45', 'usp', 'vehicle', 'xm1014']

BOT_NAMES = ['Arda', 'Baris', 'Cem', 'Deniz', 'Emre', 'Firat', 'Gorkem', 'Hakan', 'Ilker', 'Kaan', 'Levent',
             'Mert', 'Nazim', 'Okan', 'Polat', 'Riza', 'Selim', 'Tolga', 'Umut', 'Volkan', 'Yigit', 'Zafer',
             'Alpha', 'Bravo', 'Charlie', 'Delta', 'Echo', 'Foxtrot', 'Golf', 'Hotel', 'India', 'Juliet']

# ----------------------------------------------------------------------------- helpers
MANIFEST = []


def _rec(path, kind, root):
    MANIFEST.append({'path': os.path.relpath(path, root), 'kind': kind, 'size': os.path.getsize(path)})


def _write_text(path, text, root, force):
    if os.path.exists(path) and not force:
        _rec(path, 'text(kept)', root)
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', newline='\n') as f:
        f.write(text)
    _rec(path, 'text', root)


def smd_header(bones):
    out = ['version 1', 'nodes']
    for i, (name, parent, _pos) in enumerate(bones):
        out.append('%d "%s" %d' % (i, name, parent))
    out += ['end', 'skeleton', 'time 0']
    for i, (_n, _p, pos) in enumerate(bones):
        out.append('%d %.4f %.4f %.4f 0 0 0' % (i, pos[0], pos[1], pos[2]))
    out.append('end')
    return out


def box_tris(bone, mn, mx, tex):
    """12 triangles of an axis box (model space), outward winding (CCW seen from outside)."""
    x0, y0, z0 = mn
    x1, y1, z1 = mx
    c = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    faces = [((0, 3, 2, 1), (0, 0, -1)), ((4, 5, 6, 7), (0, 0, 1)), ((0, 1, 5, 4), (0, -1, 0)),
             ((2, 3, 7, 6), (0, 1, 0)), ((1, 2, 6, 5), (1, 0, 0)), ((3, 0, 4, 7), (-1, 0, 0))]
    uv = [(0, 0), (1, 0), (1, 1), (0, 1)]
    out = []
    for (a, b, cc, d), n in faces:
        for tri in ((a, b, cc), (a, cc, d)):
            out.append(tex)
            for k, vi in enumerate(tri):
                u, v = uv[(a, b, cc, d).index(vi)]
                p = c[vi]
                out.append('%d %.3f %.3f %.3f %d %d %d %.3f %.3f' % (bone, p[0], p[1], p[2], n[0], n[1], n[2], u, v))
    return out


def write_tex(path, rgb):
    idx = np.zeros((32, 32), np.uint8)
    yy, xx = np.mgrid[0:32, 0:32]
    idx[((xx // 8) + (yy // 8)) % 2 == 1] = 1
    pal = np.zeros((256, 3), np.uint8)
    pal[0] = rgb
    pal[1] = [min(255, int(v * 0.6) + 20) for v in rgb]
    write_bmp8(path, idx, pal)


# Player skeleton: (name, parent, local position) ; model origin = hull centre, feet at z = -36
PLAYER_BONES = [
    ('Bip01', -1, (0, 0, 0)),
    ('Bip01 Pelvis', 0, (0, 0, 2)),
    ('Bip01 Spine', 1, (0, 0, 6)),
    ('Bip01 Neck', 2, (0, 0, 18)),
    ('Bip01 Head', 3, (0, 0, 2)),
    ('Bip01 L UpperArm', 2, (0, 9, 15)),
    ('Bip01 R UpperArm', 2, (0, -9, 15)),
    ('Bip01 L Thigh', 1, (0, 4, -2)),
    ('Bip01 R Thigh', 1, (0, -4, -2)),
]


def _world(bones, i):
    p = np.zeros(3)
    while i >= 0:
        p += np.array(bones[i][1 + 1], float)
        i = bones[i][1]
    return p


# hitboxes: (group, bone, mins, maxs) in bone-local space
PLAYER_HBOX = [
    (1, 4, (-5, -5, 0), (6, 5, 10)),     # head  (world z 28..38 -> clipped by hull test anyway)
    (2, 2, (-6, -8, 4), (7, 8, 18)),     # chest
    (3, 2, (-6, -7, -6), (6, 7, 4)),     # stomach
    (4, 5, (-3, 0, -20), (3, 5, 0)),     # left arm
    (5, 6, (-3, -5, -20), (3, 0, 0)),    # right arm
    (6, 7, (-4, -3, -34), (4, 3, 0)),    # left leg
    (7, 8, (-4, -3, -34), (4, 3, 0)),    # right leg
]


def build_player_template(work):
    os.makedirs(work, exist_ok=True)
    write_tex(os.path.join(work, 'skin.bmp'), (90, 110, 140))
    ref = smd_header(PLAYER_BONES) + ['triangles']
    for grp, bone, mn, mx in PLAYER_HBOX:
        o = _world(PLAYER_BONES, bone)
        ref += box_tris(bone, o + np.array(mn), o + np.array(mx), 'skin.bmp')
    ref.append('end')
    open(os.path.join(work, 'ref.smd'), 'w').write('\n'.join(ref) + '\n')
    anim = smd_header(PLAYER_BONES)
    open(os.path.join(work, 'idle.smd'), 'w').write('\n'.join(anim) + '\n')
    qc = ['$modelname "ph_player.mdl"', '$cd "."', '$cdtexture "."', '$scale 1.0', '$cliptotextures',
          '$bbox -16 -16 -36 16 16 36', '$cbox -16 -16 -36 16 16 36', '$eyeposition 0 0 28',
          '$body "studio" "ref"']
    for grp, bone, mn, mx in PLAYER_HBOX:
        qc.append('$hbox %d "%s" %g %g %g %g %g %g' % ((grp, PLAYER_BONES[bone][0]) + tuple(mn) + tuple(mx)))
    # attachment used by CS clients for muzzle flashes; harmless server-side
    qc.append('$attachment 0 "Bip01 R UpperArm" 0 -4 -20')
    for s in sequence_table(nine_exts=set()):
        act = (' %s 1' % s.activity) if s.activity else ''
        loop = ' loop' if s.loop else ''
        qc.append('$sequence "%s" "idle"%s fps 30%s' % (s.name, act, loop))
    open(os.path.join(work, 'ph_player.qc'), 'w').write('\n'.join(qc) + '\n')
    out, _log = run_studiomdl(work, 'ph_player.qc')
    return out


def build_prop_template(work):
    os.makedirs(work, exist_ok=True)
    write_tex(os.path.join(work, 'skin.bmp'), (150, 150, 150))
    bones = [('root', -1, (0, 0, 0))]
    ref = smd_header(bones) + ['triangles'] + box_tris(0, (-4, -4, 0), (4, 4, 8), 'skin.bmp') + ['end']
    open(os.path.join(work, 'ref.smd'), 'w').write('\n'.join(ref) + '\n')
    open(os.path.join(work, 'idle.smd'), 'w').write('\n'.join(smd_header(bones)) + '\n')
    qc = ['$modelname "ph_prop.mdl"', '$cd "."', '$cdtexture "."', '$scale 1.0', '$cliptotextures',
          '$body "studio" "ref"', '$attachment 0 "root" 8 0 4', '$attachment 1 "root" 8 0 4']
    for i in range(16):   # weapon view models index sequences up to ~15
        qc.append('$sequence "seq%d" "idle" fps 30' % i)
    open(os.path.join(work, 'ph_prop.qc'), 'w').write('\n'.join(qc) + '\n')
    out, _log = run_studiomdl(work, 'ph_prop.qc')
    return out


def validate_mdl(path, need_seqs=()):
    m = MDL(path)
    names = set(m.seq_by_name)
    missing = [n for n in need_seqs if n not in names]
    if missing:
        raise RuntimeError('%s: missing sequences %s' % (path, missing[:5]))
    return len(m.seqs), len(m.bones), len(m.hitboxes)


def make_sprite(path):
    fr = np.zeros((16, 16), np.uint8)
    yy, xx = np.mgrid[0:16, 0:16]
    d = np.hypot(xx - 7.5, yy - 7.5)
    fr[:] = np.clip(255 - d * 32, 0, 255).astype(np.uint8)
    pal = [(i, i, i) for i in range(256)]
    write_spr(path, [fr], VP_PARALLEL, pal, TF_ADDITIVE)
    read_spr(path)


def write_empty_wad(path):
    with open(path, 'wb') as f:
        f.write(b'WAD3' + struct.pack('<ii', 0, 12))


def make_decals(path):
    tex = []
    seen = set()
    yy, xx = np.mgrid[0:16, 0:16]
    d = np.hypot(xx - 7.5, yy - 7.5)
    for n in DECALS:
        if n in seen:
            continue
        seen.add(n)
        rgba = np.zeros((16, 16, 4), np.float32)
        rgba[..., :3] = 0.15
        rgba[..., 3] = (d < 6).astype(np.float32)
        tex.append(make_miptex(n, rgba, masked=True))
    write_wad(path, tex)
    assert len(read_wad(path)) == len(seen)


# ----------------------------------------------------------------------------- text content
LIBLIST = '''// Vexmira test server (placeholder) - ReGameDLL through Metamod-R
game "Counter-Strike"
url_info "www.counter-strike.net"
url_dl ""
version "1.6"
size "184000000"
svonly "0"
secure "1"
type "multiplayer_only"
cldll "1"
hlversion "1111"
nomodels "1"
nohimodel "1"
mpentity "info_player_start"
gamedll "dlls\\mp.dll"
gamedll_linux "addons/metamod/metamod_i386.so"
gamedll_osx "dlls/cs.dylib"
trainmap "tr_1"
edicts "1800"
'''

METAMOD_PLUGINS = '''linux addons/amxmodx/dlls/amxmodx_mm_i386.so
'''

SERVER_CFG = '''// Vexmira headless test server
hostname "Vexmira test"
sv_lan 1
sv_cheats 0
mp_timelimit 0
mp_roundtime 2
mp_freezetime 1
mp_buytime 0.5
mp_autoteambalance 0
mp_limitteams 0
log on
mp_logdetail 3
mp_logmessages 1
sv_logecho 1
bot_quota_mode normal
bot_join_after_player 0
bot_auto_vacate 0
bot_chatter off
bot_difficulty 2
bot_join_team any
'''

MATERIALS = '''// placeholder materials.txt
C CONCRETE
M METAL
D DIRT
V VENT
G GRATE
T TILE
S SLOSH
W WOOD
P COMPUTER
Y GLASS
F FLESH
N SNOW
'''


def botprofile():
    lines = ['// Placeholder botprofile.db for the Vexmira test server (ReGameDLL bot_profile.cpp format)',
             '', 'Default', '\tSkill = 60', '\tAggression = 60', '\tReactionTime = 0.3', '\tAttackDelay = 0',
             '\tTeamwork = 75', '\tWeaponPreference = none', '\tCost = 2', '\tDifficulty = NORMAL',
             '\tVoicePitch = 100', '\tSkin = 0', 'End', '',
             'Template Rifleman', '\tWeaponPreference = m4a1', '\tWeaponPreference = ak47', 'End', '',
             'Template Shotgunner', '\tWeaponPreference = xm1014', '\tWeaponPreference = m3', 'End', '',
             'Template Gunner', '\tWeaponPreference = m249', '\tWeaponPreference = p90', 'End', '',
             'Template Hard', '\tSkill = 80', '\tAggression = 80', '\tReactionTime = 0.2',
             '\tDifficulty = HARD+EXPERT', 'End', '']
    tmpl = ['Rifleman', 'Shotgunner', 'Gunner', 'Rifleman+Hard']
    for i, n in enumerate(BOT_NAMES):
        lines += ['%s %s' % (tmpl[i % len(tmpl)], n),
                  '\tVoicePitch = %d' % (90 + (i * 7) % 25),
                  '\tDifficulty = EASY+NORMAL+HARD+EXPERT', 'End', '']
    return '\n'.join(lines)


# ----------------------------------------------------------------------------- package stubs
def write_silent_wav(path, seconds=0.1, rate=22050):
    n = int(seconds * rate)
    data = b'\0\0' * n
    with open(path, 'wb') as f:
        f.write(b'RIFF' + struct.pack('<I', 36 + len(data)) + b'WAVE')
        f.write(b'fmt ' + struct.pack('<IHHIIHH', 16, 1, 1, rate, rate * 2, 2, 16))
        f.write(b'data' + struct.pack('<I', len(data)) + data)


def templates():
    """(player_template, prop_template) - compiled once, cached in WORK."""
    pl = os.path.join(WORK, 'player', 'ph_player.mdl')
    pr = os.path.join(WORK, 'prop', 'ph_prop.mdl')
    if not os.path.exists(pl):
        build_player_template(os.path.join(WORK, 'player'))
    if not os.path.exists(pr):
        build_prop_template(os.path.join(WORK, 'prop'))
    return pl, pr


HUMANS = ['vex_operator', 'vex_ranger', 'vex_hazmat', 'vex_vip', 'vex_admin', 'vex_survivor', 'vex_sniper']
ZOMBIES = ['walker', 'runner', 'tank', 'banshee', 'leech', 'stalker', 'bomber', 'frost', 'spitter', 'hulk', 'voodoo',
           'phantom', 'butcher', 'hunter', 'charger', 'arachne', 'magma', 'volt', 'mimic', 'burrower', 'siren',
           'bulwark', 'sporemother', 'nightmare']
BOSSES = ['brute', 'banshee', 'overlord', 'inferno', 'reaper', 'frostlord', 'stormcaller', 'hivequeen', 'void']


def design_package_paths():
    """Every model the v3 design (devtools/DESIGN_v3.md sections 3-5) promises."""
    out = []
    pl = HUMANS + ['vex_z_' + z for z in ZOMBIES] + ['vex_b_' + b for b in BOSSES] + ['vex_nemesis', 'vex_assassin']
    out += ['models/player/%s/%s.mdl' % (n, n) for n in pl]
    out += ['models/vexmira/claws/v_%s.mdl' % n for n in ZOMBIES + BOSSES + ['nemesis', 'assassin']]
    w = ['vexblade', 'firebomb', 'frostbomb', 'flare'] + ['sw%d' % i for i in range(8)]
    out += ['models/vexmira/weapons/v_%s.mdl' % n for n in w]
    std = ['ak47', 'aug', 'awp', 'deagle', 'elite', 'famas', 'fiveseven', 'g3sg1', 'galil', 'glock18', 'm249', 'm3',
           'm4a1', 'mac10', 'mp5navy', 'p228', 'p90', 'scout', 'sg550', 'sg552', 'tmp', 'ump45', 'usp', 'xm1014']
    out += ['models/vexmira/weapons/p_%s.mdl' % n for n in std + w]
    out += ['models/vexmira/world/%s.mdl' % n for n in ('lasermine', 'supply_crate', 'hive_egg', 'spore_pod', 'hook',
                                                         'w_firebomb', 'w_frostbomb', 'w_flare')]
    return out


def stub_files(paths, server=DEFAULT_SERVER):
    """Create server-only stand-ins for package files that do not exist yet (models being built
    in parallel, Valve sounds the plugin falls back to...). Keeps precache counts realistic.
    Recorded in cstrike/stubs_manifest.json; run_test.py's sync replaces a stub with the real
    repo file as soon as it exists."""
    cs = os.path.join(server, 'cstrike')
    man_p = os.path.join(cs, 'stubs_manifest.json')
    man = json.load(open(man_p)) if os.path.exists(man_p) else {}
    pl, pr = templates()
    made = []
    for rel in paths:
        rel = rel.strip().lstrip('/')
        if not rel or '..' in rel:
            continue
        dst = os.path.join(cs, rel)
        if os.path.lexists(dst):
            continue
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if rel.endswith('.mdl'):
            shutil.copyfile(pl if rel.startswith('models/player/') else pr, dst)
        elif rel.endswith('.spr'):
            make_sprite(dst)
        elif rel.endswith('.wav'):
            write_silent_wav(dst)
        else:
            continue
        man[rel] = os.path.getsize(dst)
        made.append(rel)
    json.dump(man, open(man_p, 'w'), indent=1, sort_keys=True)
    return made


def clean_stubs(server=DEFAULT_SERVER):
    cs = os.path.join(server, 'cstrike')
    man_p = os.path.join(cs, 'stubs_manifest.json')
    if not os.path.exists(man_p):
        return 0
    n = 0
    for rel in json.load(open(man_p)):
        p = os.path.join(cs, rel)
        if os.path.isfile(p) and not os.path.islink(p):
            os.unlink(p)
            n += 1
    os.unlink(man_p)
    return n


# ----------------------------------------------------------------------------- main
def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--server', default=DEFAULT_SERVER)
    ap.add_argument('--force', action='store_true', help='overwrite existing placeholder files')
    ap.add_argument('--extra', nargs='*', default=[], help='additional models/*.mdl or sprites/*.spr paths')
    ap.add_argument('--stub', nargs='*', help='only create package stand-ins for these paths (mdl/spr/wav) and exit')
    ap.add_argument('--clean-stubs', action='store_true', help='remove all package stand-ins and exit')
    a = ap.parse_args(argv)
    if a.clean_stubs:
        print('removed %d stubs' % clean_stubs(a.server))
        return
    if a.stub is not None:
        made = stub_files(a.stub, a.server)
        print('stubbed %d: %s' % (len(made), ' '.join(made)))
        return
    root = a.server
    cs = os.path.join(root, 'cstrike')
    valve = os.path.join(root, 'valve')
    os.makedirs(cs, exist_ok=True)
    os.makedirs(valve, exist_ok=True)

    def need(p):
        return a.force or not os.path.exists(p)

    # WADs
    for p in (os.path.join(valve, 'gfx.wad'), os.path.join(valve, 'fonts.wad')):
        if need(p):
            write_empty_wad(p)
        _rec(p, 'wad', root)
    p = os.path.join(cs, 'decals.wad')
    if need(p):
        make_decals(p)
    _rec(p, 'wad', root)

    # model templates
    shutil.rmtree(WORK, ignore_errors=True)
    tpl_player, tpl_prop = templates()
    ns, nb, nh = validate_mdl(tpl_player, ['idle1', 'run', 'walk', 'ref_aim_knife', 'crouch_aim_carbine',
                                           'head_flinch', 'gut_flinch', 'left', 'right', 'crouch_die'])
    print('player template: %d seqs, %d bones, %d hitboxes, %d bytes' % (ns, nb, nh, os.path.getsize(tpl_player)))
    ns, nb, nh = validate_mdl(tpl_prop)
    print('prop template:   %d seqs, %d bones, %d bytes' % (ns, nb, os.path.getsize(tpl_prop)))

    models = [('models/' + m, tpl_player) for m in PLAYER_MODELS] + [('models/' + m, tpl_prop) for m in PROP_MODELS]
    sprites = ['sprites/%s.spr' % s for s in dict.fromkeys(SPRITES)]
    for e in a.extra:
        e = e.lstrip('/')
        if e.endswith('.mdl'):
            models.append((e, tpl_player if '/player' in e else tpl_prop))
        elif e.endswith('.spr'):
            sprites.append(e)
    for rel, tpl in models:
        p = os.path.join(cs, rel)
        if need(p):
            os.makedirs(os.path.dirname(p), exist_ok=True)
            if os.path.islink(p):
                os.unlink(p)
            shutil.copyfile(tpl, p)
        _rec(p, 'mdl', root)
    for rel in sprites:
        p = os.path.join(cs, rel)
        if need(p):
            os.makedirs(os.path.dirname(p), exist_ok=True)
            make_sprite(p)
        _rec(p, 'spr', root)

    # event scripts (the engine only checks that the file exists; content is client-side)
    for e in EVENTS:
        _write_text(os.path.join(cs, 'events', e + '.sc'), '// placeholder event script\n', root, a.force)

    # text / config files
    # ReGameDLL: ZBots are disabled on dedicated servers unless bot_enable 1 is set in game_init.cfg
    gi = os.path.join(cs, 'game_init.cfg')
    if os.path.exists(gi):
        txt = open(gi).read()
        if 'bot_enable "1"' not in txt:
            txt = re.sub(r'(?m)^bot_enable\s+"?0"?', 'bot_enable "1"', txt)
            if 'bot_enable "1"' not in txt:
                txt += '\nbot_enable "1"\n'
            open(gi, 'w').write(txt)
        _rec(gi, 'cfg(patched)', root)
    # valve.rc runs "stuffcmds": without it the +map / +maxplayers command line is ignored
    _write_text(os.path.join(valve, 'valve.rc'), '// placeholder valve.rc\nstuffcmds\n', root, a.force)
    _write_text(os.path.join(cs, 'liblist.gam'), LIBLIST, root, a.force)
    _write_text(os.path.join(cs, 'addons/metamod/plugins.ini'), METAMOD_PLUGINS, root, a.force)
    _write_text(os.path.join(cs, 'server.cfg'), SERVER_CFG, root, a.force)
    _write_text(os.path.join(cs, 'botprofile.db'), botprofile(), root, a.force)
    _write_text(os.path.join(cs, 'sound/materials.txt'), MATERIALS, root, a.force)
    _write_text(os.path.join(cs, 'mapcycle.txt'), 'zm_vex_testroom\nzm_vex_pilot\n', root, a.force)
    _write_text(os.path.join(cs, 'motd.txt'), 'Vexmira test server\n', root, a.force)
    _write_text(os.path.join(cs, 'listip.cfg'), '', root, a.force)
    _write_text(os.path.join(cs, 'banned.cfg'), '', root, a.force)
    for f in ('steam_appid.txt',):
        _write_text(os.path.join(root, f), '10\n', root, a.force)

    with open(os.path.join(cs, 'placeholders_manifest.json'), 'w') as f:
        json.dump(MANIFEST, f, indent=1)
    kinds = {}
    for m in MANIFEST:
        kinds[m['kind']] = kinds.get(m['kind'], 0) + 1
    print('placeholders: %d files %s -> %s' % (len(MANIFEST), kinds, os.path.join(cs, 'placeholders_manifest.json')))


if __name__ == '__main__':
    main()
