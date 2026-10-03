"""Validation of compiled models against engine / client / server expectations.

validate_player(path) checks (errors fail the build, warnings are reported):
  * file parses, IDST v10, single sequence group, size budget
  * bone count <= 128 and the CS bone names exist
  * gait-merge partition (exact client/server loop) puts Bip01, Pelvis, legs in the gait set and
    Spine..Head + arms (+ upper extras) in the upper set
  * full sequence table: names, hard-coded indices (walk 3, jump 6, swim 8, treadwater 9), deaths in
    101..159 and nothing else there, all 9-blend sequences < 101, gait activities unique, death
    activities present, walk/run/crouchrun LX with linearmovement[0] > 0
  * 9-blend sequences for the expected extensions
  * hitboxes: groups 1..7 present; head/chest/stomach box centres inside the hull for standing and
    crouched aim poses at all 9 blend corners
  * textures: power-of-two, <= 512
  * submodels < 2048 vertices / normals
  * winding vs normal consistency (inverted normals detector)
  * feet on the ground in idle1 / crouch_idle, deaths end on the floor
"""
import math
import os
import numpy as np

from .mdl_read import MDL, ACTIVITY_ID
from .anims import sequence_table, GUN_EXTS
from . import preview as PV

CS_REQUIRED_BONES = ['Bip01', 'Bip01 Pelvis', 'Bip01 Spine', 'Bip01 Spine1', 'Bip01 Spine2', 'Bip01 Spine3',
                     'Bip01 Neck', 'Bip01 Head', 'Bip01 L Clavicle', 'Bip01 L UpperArm', 'Bip01 L Forearm',
                     'Bip01 L Hand', 'Bip01 R Clavicle', 'Bip01 R UpperArm', 'Bip01 R Forearm', 'Bip01 R Hand',
                     'Bip01 L Thigh', 'Bip01 L Calf', 'Bip01 L Foot', 'Bip01 R Thigh', 'Bip01 R Calf',
                     'Bip01 R Foot']
GAIT_BONES = ['Bip01', 'Bip01 Pelvis', 'Bip01 L Thigh', 'Bip01 L Calf', 'Bip01 L Foot', 'Bip01 R Thigh',
              'Bip01 R Calf', 'Bip01 R Foot']

BUDGETS = {'human': 1.0e6, 'zombie': 0.45e6, 'boss': 0.7e6, 'claws': 0.2e6, 'p': 0.08e6, 'v_human': 0.4e6}


def gait_partition(m):
    """Exact port of the client/server copy loop. Returns set of bone names taken from the gait."""
    copy = True
    out = set()
    for i in range(m.numbones):
        par = m.parents[i]
        if m.bone_names[i] == 'Bip01 Spine':
            copy = False
        elif par >= 0 and m.bone_names[par] == 'Bip01 Pelvis':
            copy = True
        if copy:
            out.add(m.bone_names[i])
    return out


def check_winding(m):
    """Fraction of triangles whose compiled winding disagrees with their vertex normals."""
    bad = tot = 0
    for bp in m.bodyparts:
        for mod in bp['models']:
            if mod['numverts'] == 0:
                continue
            # rest pose world positions: bone transforms of the reference = sequence-independent?
            # vertices are stored bone-local; use the default bone values (reference pose)
            bones = _ref_bones(m)
            V = np.einsum('nij,nj->ni', bones[mod['vert_bone'], :, :3], mod['verts']) + bones[mod['vert_bone'], :, 3]
            N = np.einsum('nij,nj->ni', bones[mod['norm_bone'], :, :3], mod['norms'])
            for me in mod['meshes']:
                if not me['tris']:
                    continue
                t = np.array(me['tris'])
                a, b, c = V[t[:, 0, 0]], V[t[:, 1, 0]], V[t[:, 2, 0]]
                fn = np.cross(b - a, c - a)
                nn = N[t[:, 0, 1]] + N[t[:, 1, 1]] + N[t[:, 2, 1]]
                area = np.linalg.norm(fn, axis=1)
                ok = area > 1e-6
                d = np.einsum('ij,ij->i', fn, nn)
                bad += int(np.sum((d > 0) & ok))       # engine order is clockwise-from-outside -> dot < 0
                tot += int(np.sum(ok))
    return bad, tot


def _ref_bones(m):
    from .mathx import angle_quaternion_v, quaternion_matrix_v
    R = quaternion_matrix_v(angle_quaternion_v(m.bone_value[:, 3:]))
    out = np.zeros((m.numbones, 3, 4))
    for i in range(m.numbones):
        bm = np.zeros((3, 4)); bm[:, :3] = R[i]; bm[:, 3] = m.bone_value[i, :3]
        p = m.parents[i]
        if p < 0:
            out[i] = bm
        else:
            out[i, :, :3] = out[p, :, :3] @ bm[:, :3]
            out[i, :, 3] = out[p, :, :3] @ bm[:, 3] + out[p, :, 3]
    return out


def hitbox_world(m, bones):
    res = []
    for hb in m.hitboxes:
        B = bones[hb['bone']]
        mn, mx = hb['bbmin'], hb['bbmax']
        cs = np.array([[mx[0] if a & 1 else mn[0], mx[1] if a & 2 else mn[1], mx[2] if a & 4 else mn[2]] for a in range(8)])
        w = cs @ B[:, :3].T + B[:, 3]
        res.append((hb['group'], m.bone_names[hb['bone']], w))
    return res


def validate_player(path, budget=None, expect_nine=None, kind=None, float_h=0.0):
    """float_h: hover height of 'floaty' characters (feet may be that much higher; no foot-slide check)."""
    E, W = [], []
    stats = {}
    m = MDL(path)
    size = os.path.getsize(path)
    stats['size'] = size
    stats['bones'] = m.numbones
    stats['seqs'] = m.numseq
    stats['textures'] = ['%s %dx%d' % (t['name'], t['width'], t['height']) for t in m.textures]
    stats['tris'] = m.tri_count()
    if budget and size > budget:
        E.append('size %d > budget %d' % (size, budget))
    if m.numseqgroups != 1:
        E.append('model uses %d sequence groups (must be 1)' % m.numseqgroups)
    if m.numbones > 128:
        E.append('too many bones %d' % m.numbones)
    for b in CS_REQUIRED_BONES:
        if b not in m.bone_names:
            E.append('missing bone %s' % b)
    gp = gait_partition(m)
    for b in GAIT_BONES:
        if b in m.bone_names and b not in gp:
            E.append('bone %s is not driven by the gait (bone order broken)' % b)
    for b in CS_REQUIRED_BONES:
        if b not in GAIT_BONES and b in gp:
            E.append('upper-body bone %s would be overwritten by the gait (bone order broken)' % b)
    stats['gait_bones'] = sorted(gp)
    # sequences
    table = sequence_table(expect_nine)
    names = [s['label'] for s in m.seqs]
    for i, sd in enumerate(table):
        if i >= len(names) or names[i] != sd.name:
            E.append('sequence %d should be %s (found %s)' % (i, sd.name, names[i] if i < len(names) else None))
            break
    fixed = {3: 'walk', 6: 'jump', 8: 'swim', 9: 'treadwater'}
    for i, n in fixed.items():
        if i < len(names) and names[i] != n:
            E.append('client hard-codes sequence %d = %s, found %s' % (i, n, names[i]))
    death_names = {'death1', 'death2', 'death3', 'head', 'gutshot', 'left', 'back', 'right', 'forward',
                   'crouch_die', 'chestshot'}
    for s in m.seqs:
        i = s['index']
        isdeath = s['label'] in death_names
        if 101 <= i <= 159 and not isdeath:
            E.append('non-death sequence %s at %d inside death range 101..159' % (s['label'], i))
        if isdeath and not (101 <= i <= 159):
            E.append('death sequence %s at %d outside 101..159' % (s['label'], i))
        if s['numblends'] == 9 and i >= 101:
            E.append('9-blend sequence %s at index %d >= 101 (server skips gait merge)' % (s['label'], i))
        if s['seqgroup'] != 0:
            E.append('sequence %s in external group' % s['label'])
    for act in ('ACT_IDLE', 'ACT_CROUCHIDLE', 'ACT_WALK', 'ACT_RUN', 'ACT_CROUCH', 'ACT_HOP', 'ACT_LEAP', 'ACT_SWIM',
                'ACT_HOVER'):
        n = sum(1 for s in m.seqs if s['activity'] == ACTIVITY_ID[act])
        if n != 1:
            E.append('activity %s used by %d sequences (must be exactly 1)' % (act, n))
    for act in ('ACT_DIESIMPLE', 'ACT_DIEBACKWARD', 'ACT_DIEFORWARD', 'ACT_DIE_HEADSHOT', 'ACT_DIE_CHESTSHOT',
                'ACT_DIE_GUTSHOT', 'ACT_DIE_BACKSHOT'):
        if not any(s['activity'] == ACTIVITY_ID[act] for s in m.seqs):
            E.append('no sequence for %s' % act)
    for n in ('walk', 'run', 'crouchrun'):
        s = m.seqs[m.seq_by_name[n]]
        if not (s['motiontype'] & 0x40) or s['linearmovement'][0] <= 0:
            E.append('%s: needs LX motion with linearmovement[0] > 0 (got %s)' % (n, s['linearmovement']))
        stats['lm_' + n] = round(float(s['linearmovement'][0]), 2)
    for s in m.seqs:
        parts = s['label'].split('_', 2)
        if len(parts) == 3 and parts[0] in ('ref', 'crouch') and parts[1] in ('aim', 'shoot', 'shoot2', 'reload'):
            ext = parts[2]
            want9 = expect_nine is None or ext in expect_nine
            if want9 and s['numblends'] != 9:
                E.append('%s should have 9 blends (has %d)' % (s['label'], s['numblends']))
    # textures
    for t in m.textures:
        for d in (t['width'], t['height']):
            if d > 512 or (d & (d - 1)):
                W.append('texture %s %dx%d not power of two <= 512' % (t['name'], t['width'], t['height']))
    # vertex limits
    for bp in m.bodyparts:
        for mod in bp['models']:
            if mod['numverts'] >= 2048 or mod['numnorms'] >= 2048:
                E.append('submodel %s has %d verts / %d norms (limit 2048)' % (mod['name'], mod['numverts'], mod['numnorms']))
    bad, tot = check_winding(m)
    stats['winding_bad'] = '%d/%d' % (bad, tot)
    if tot and bad / tot > 0.02:
        W.append('%d of %d triangles have winding opposite to their normals (inverted normals?)' % (bad, tot))
    # hitboxes
    groups = set(hb['group'] for hb in m.hitboxes)
    for g in range(1, 8):
        if g not in groups:
            E.append('no hitbox in group %d' % g)
    gi = m.seq_by_name.get('idle1', 1)
    ci = m.seq_by_name.get('crouch_idle', 2)
    worst = 0.0
    for crouch, seqname, gait in ((False, 'ref_aim_knife', gi), (True, 'crouch_aim_knife', ci)):
        if seqname.lower() not in m.seq_by_name:
            continue
        si = m.seq_by_name[seqname]
        zlo, zhi = (-18, 18) if crouch else (-36, 36)
        for bl in ((0, 0), (127, 127), (255, 255), (0, 255), (255, 0)):
            bones = PV.setup_bones(m, si, 0.0, bl, gait, 0.0, player=True)
            for g, bn, w in hitbox_world(m, bones):
                c = w.mean(0)
                outz = max(0, c[2] - zhi, zlo - c[2])
                outxy = max(0, abs(c[0]) - 16, abs(c[1]) - 16)
                # traces are AABB-culled against the hull: anything above/below it can never be hit by a
                # level shot; sideways overhang is still reachable (ray AABBs are long), so warn only
                if g in (1, 2, 3) and outz > 0.5:
                    E.append('hitbox %s (group %d) centre above/below the hull by %.1f in %s blend %s' % (bn, g, outz, seqname, bl))
                if g in (1, 2, 3) and outxy > 4.0:
                    W.append('hitbox %s (group %d) centre %.1f outside the hull sideways in %s blend %s' % (bn, g, outxy, seqname, bl))
                worst = max(worst, outz)
    stats['hitbox_max_out'] = round(worst, 2)
    # feet / deaths
    # foot sliding: replay the client's gait-frame advance (gaitframe += dist / lm * numframes) and measure
    # how far a planted foot drifts in world space during stance
    for nm in ('walk', 'run', 'crouchrun'):
        si = m.seq_by_name[nm]
        sd = m.seqs[si]
        lm = sd['linearmovement'][0]
        N = sd['numframes']
        if lm <= 0 or float_h > 0:
            continue
        worst = 0.0
        for foot in ('Bip01 L Foot', 'Bip01 R Foot'):
            fi = m.bone_names.index(foot)
            xs = []
            for k in range(int(N * 4)):
                gf = (k / 4.0) % (N - 1)
                bones = PV.setup_bones(m, si, gf, (127, 127), None, 0.0, player=True)
                p = bones[fi][:, 3]
                dist = (k / 4.0) * lm / N
                xs.append((p[0] + dist, p[2]))
            xs = np.array(xs)
            low = xs[:, 1] < xs[:, 1].min() + 0.6
            if low.sum() > 2:
                # contiguous planted segments: drift = range of world x while planted
                seg = []
                cur = []
                for i, lo in enumerate(low):
                    if lo:
                        cur.append(xs[i, 0])
                    elif cur:
                        seg.append(cur); cur = []
                if cur:
                    seg.append(cur)
                for sgm in seg:
                    if len(sgm) > 2:
                        worst = max(worst, max(sgm) - min(sgm))
        stats['slide_' + nm] = round(float(worst), 2)
        if worst > 4.0:
            W.append('%s: planted foot slides %.1f units' % (nm, worst))
    for nm, floor in (('idle1', -36), ('crouch_idle', -18)):
        si = m.seq_by_name[nm]
        bones = PV.setup_bones(m, si, 0.0, (127, 127), None, 0.0, player=True)
        feet = [bones[m.bone_names.index(b)][:, 3][2] for b in ('Bip01 L Foot', 'Bip01 R Foot') if b in m.bone_names]
        stats['ankle_z_' + nm] = [round(float(f), 2) for f in feet]
        if feet and (min(feet) < floor - 0.5 or min(feet) > floor + 8 + float_h):
            E.append('%s: ankles at %s, floor is %d' % (nm, feet, floor))
    ib = PV.setup_bones(m, m.seq_by_name['idle1'], 0.0, (127, 127), None, 0.0, player=True)
    hscale = max(1.0, (ib[:, 2, 3].max() + 36 + 5) / 72.0)
    stats['height_scale'] = round(float(hscale), 2)
    for s in m.seqs:
        if s['label'] in death_names:
            si = s['index']
            bones = PV.setup_bones(m, si, s['numframes'] - 1.001, (127, 127), None, 0.0, player=True)
            zs = bones[:, 2, 3]
            floor = -18 if s['label'] == 'crouch_die' else -36
            if zs.min() < floor - 2.5 * hscale:
                W.append('death %s: a joint ends %.1f units below the floor' % (s['label'], floor - zs.min()))
            if zs.max() > floor + 26 * hscale:
                W.append('death %s: body still upright at the end (max joint z %.1f)' % (s['label'], zs.max()))
    if not m.attachments:
        W.append('no attachments')
    return dict(path=path, errors=E, warnings=W, stats=stats)


def format_report(rep):
    L = ['== %s' % rep.get('out', rep.get('path'))]
    for k, v in rep['stats'].items():
        if k == 'gait_bones':
            continue
        L.append('  %-16s %s' % (k, v))
    for e in rep['errors']:
        L.append('  ERROR   ' + e)
    for w in rep['warnings']:
        L.append('  warning ' + w)
    if 'previews' in rep:
        for p in rep['previews']:
            L.append('  preview ' + p)
    return '\n'.join(L)
