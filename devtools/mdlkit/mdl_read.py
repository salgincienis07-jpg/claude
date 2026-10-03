"""Parser for compiled GoldSrc studio models (IDST version 10) + engine-exact animation decoding.

    m = MDL('file.mdl')
    m.bones, m.seqs, m.hitboxes, m.attachments, m.textures, m.bodyparts
    pos, q = m.calc_rotations(seq_index, frame_float, blend=0)   # StudioCalcRotations port

Only sequence group 0 (in-file animation) is supported - our models never use external groups.
"""
import struct
import numpy as np

from .mathx import angle_quaternion_v, quaternion_slerp_v

ACTIVITY_NAMES = {}


def _load_activity_names():
    # Mirrors hlsdk dlls/activity.h ordering (ACT_RESET=0, ACT_IDLE=1, ...)
    names = ['ACT_RESET', 'ACT_IDLE', 'ACT_GUARD', 'ACT_WALK', 'ACT_RUN', 'ACT_FLY', 'ACT_SWIM', 'ACT_HOP',
             'ACT_LEAP', 'ACT_FALL', 'ACT_LAND', 'ACT_STRAFE_LEFT', 'ACT_STRAFE_RIGHT', 'ACT_ROLL_LEFT',
             'ACT_ROLL_RIGHT', 'ACT_TURN_LEFT', 'ACT_TURN_RIGHT', 'ACT_CROUCH', 'ACT_CROUCHIDLE', 'ACT_STAND',
             'ACT_USE', 'ACT_SIGNAL1', 'ACT_SIGNAL2', 'ACT_SIGNAL3', 'ACT_TWITCH', 'ACT_COWER',
             'ACT_SMALL_FLINCH', 'ACT_BIG_FLINCH', 'ACT_RANGE_ATTACK1', 'ACT_RANGE_ATTACK2',
             'ACT_MELEE_ATTACK1', 'ACT_MELEE_ATTACK2', 'ACT_RELOAD', 'ACT_ARM', 'ACT_DISARM', 'ACT_EAT',
             'ACT_DIESIMPLE', 'ACT_DIEBACKWARD', 'ACT_DIEFORWARD', 'ACT_DIEVIOLENT', 'ACT_BARNACLE_HIT',
             'ACT_BARNACLE_PULL', 'ACT_BARNACLE_CHOMP', 'ACT_BARNACLE_CHEW', 'ACT_SLEEP', 'ACT_INSPECT_FLOOR',
             'ACT_INSPECT_WALL', 'ACT_IDLE_ANGRY', 'ACT_WALK_HURT', 'ACT_RUN_HURT', 'ACT_HOVER',
             'ACT_GLIDE', 'ACT_FLY_LEFT', 'ACT_FLY_RIGHT', 'ACT_DETECT_SCENT', 'ACT_SNIFF', 'ACT_BITE',
             'ACT_THREAT_DISPLAY', 'ACT_FEAR_DISPLAY', 'ACT_EXCITED', 'ACT_SPECIAL_ATTACK1',
             'ACT_SPECIAL_ATTACK2', 'ACT_COMBAT_IDLE', 'ACT_WALK_SCARED', 'ACT_RUN_SCARED',
             'ACT_VICTORY_DANCE', 'ACT_DIE_HEADSHOT', 'ACT_DIE_CHESTSHOT', 'ACT_DIE_GUTSHOT',
             'ACT_DIE_BACKSHOT', 'ACT_FLINCH_HEAD', 'ACT_FLINCH_CHEST', 'ACT_FLINCH_STOMACH',
             'ACT_FLINCH_LEFTARM', 'ACT_FLINCH_RIGHTARM', 'ACT_FLINCH_LEFTLEG', 'ACT_FLINCH_RIGHTLEG']
    return names


ACTIVITY_LIST = _load_activity_names()
ACTIVITY_ID = {n: i for i, n in enumerate(ACTIVITY_LIST)}


def _cstr(b):
    return b.split(b'\0', 1)[0].decode('latin-1')


class MDL:
    def __init__(self, path_or_bytes):
        if isinstance(path_or_bytes, (bytes, bytearray)):
            self.data = bytes(path_or_bytes)
            self.path = None
        else:
            self.path = path_or_bytes
            with open(path_or_bytes, 'rb') as f:
                self.data = f.read()
        self._parse()

    # ------------------------------------------------------------------ parsing
    def _parse(self):
        d = self.data
        ident, ver = struct.unpack_from('<4si', d, 0)
        if ident != b'IDST':
            raise ValueError('not an IDST studio model (%r)' % ident)
        if ver != 10:
            raise ValueError('unsupported version %d' % ver)
        self.version = ver
        self.name = _cstr(d[8:72])
        (self.length,) = struct.unpack_from('<i', d, 72)
        f = struct.unpack_from('<15f', d, 76)
        self.eyeposition = np.array(f[0:3]); self.min = np.array(f[3:6]); self.max = np.array(f[6:9])
        self.bbmin = np.array(f[9:12]); self.bbmax = np.array(f[12:15])
        ints = struct.unpack_from('<27i', d, 136)
        (self.flags, self.numbones, self.boneindex, self.numbonecontrollers, self.bonecontrollerindex,
         self.numhitboxes, self.hitboxindex, self.numseq, self.seqindex, self.numseqgroups,
         self.seqgroupindex, self.numtextures, self.textureindex, self.texturedataindex,
         self.numskinref, self.numskinfamilies, self.skinindex, self.numbodyparts, self.bodypartindex,
         self.numattachments, self.attachmentindex, self.soundtable, self.soundindex,
         self.soundgroups, self.soundgroupindex, self.numtransitions, self.transitionindex) = ints
        self.header_size = 136 + 27 * 4
        self._parse_bones()
        self._parse_controllers()
        self._parse_hitboxes()
        self._parse_seqgroups()
        self._parse_seqs()
        self._parse_textures()
        self._parse_bodyparts()
        self._parse_attachments()

    def _parse_bones(self):
        d = self.data
        self.bones = []
        for i in range(self.numbones):
            o = self.boneindex + i * 112
            name = _cstr(d[o:o + 32])
            parent, flags = struct.unpack_from('<ii', d, o + 32)
            bc = struct.unpack_from('<6i', d, o + 40)
            value = struct.unpack_from('<6f', d, o + 64)
            scale = struct.unpack_from('<6f', d, o + 88)
            self.bones.append(dict(name=name, parent=parent, flags=flags, bonecontroller=list(bc),
                                   value=np.array(value), scale=np.array(scale)))
        self.bone_names = [b['name'] for b in self.bones]
        self.parents = np.array([b['parent'] for b in self.bones], dtype=np.int64)
        self.bone_value = np.array([b['value'] for b in self.bones]).reshape(-1, 6)
        self.bone_scale = np.array([b['scale'] for b in self.bones]).reshape(-1, 6)

    def _parse_controllers(self):
        self.controllers = []
        for i in range(self.numbonecontrollers):
            o = self.bonecontrollerindex + i * 24
            bone, typ, start, end, rest, index = struct.unpack_from('<iiffii', self.data, o)
            self.controllers.append(dict(bone=bone, type=typ, start=start, end=end, rest=rest, index=index))

    def _parse_hitboxes(self):
        self.hitboxes = []
        for i in range(self.numhitboxes):
            o = self.hitboxindex + i * 32
            bone, group = struct.unpack_from('<ii', self.data, o)
            v = struct.unpack_from('<6f', self.data, o + 8)
            self.hitboxes.append(dict(bone=bone, group=group, bbmin=np.array(v[:3]), bbmax=np.array(v[3:])))

    def _parse_seqgroups(self):
        self.seqgroups = []
        for i in range(self.numseqgroups):
            o = self.seqgroupindex + i * 104
            self.seqgroups.append(dict(label=_cstr(self.data[o:o + 32]), name=_cstr(self.data[o + 32:o + 96])))

    def _parse_seqs(self):
        d = self.data
        self.seqs = []
        for i in range(self.numseq):
            o = self.seqindex + i * 176
            label = _cstr(d[o:o + 32])
            fps, flags, activity, actweight, numevents, eventindex, numframes, numpivots, pivotindex, \
                motiontype, motionbone = struct.unpack_from('<fiiiiiiiiii', d, o + 32)
            lm = np.array(struct.unpack_from('<3f', d, o + 76))
            automoveposindex, automoveangleindex = struct.unpack_from('<ii', d, o + 88)
            bb = struct.unpack_from('<6f', d, o + 96)
            numblends, animindex = struct.unpack_from('<ii', d, o + 120)
            blendtype = struct.unpack_from('<2i', d, o + 128)
            blendstart = struct.unpack_from('<2f', d, o + 136)
            blendend = struct.unpack_from('<2f', d, o + 144)
            blendparent, seqgroup, entrynode, exitnode, nodeflags, nextseq = struct.unpack_from('<6i', d, o + 152)
            events = []
            for e in range(numevents):
                eo = eventindex + e * 76
                frame, event, etype = struct.unpack_from('<iii', d, eo)
                events.append(dict(frame=frame, event=event, type=etype, options=_cstr(d[eo + 12:eo + 76])))
            self.seqs.append(dict(index=i, label=label, fps=fps, flags=flags, activity=activity,
                                  activity_name=ACTIVITY_LIST[activity] if 0 <= activity < len(ACTIVITY_LIST) else str(activity),
                                  actweight=actweight, events=events, numframes=numframes, numpivots=numpivots,
                                  motiontype=motiontype, motionbone=motionbone, linearmovement=lm,
                                  bbmin=np.array(bb[:3]), bbmax=np.array(bb[3:]), numblends=numblends,
                                  animindex=animindex, blendtype=blendtype, blendstart=blendstart,
                                  blendend=blendend, seqgroup=seqgroup, entrynode=entrynode, exitnode=exitnode,
                                  nodeflags=nodeflags, nextseq=nextseq))
        self.seq_by_name = {s['label'].lower(): s['index'] for s in self.seqs}
        self._anim_cache = {}

    def _parse_textures(self):
        d = self.data
        self.textures = []
        for i in range(self.numtextures):
            o = self.textureindex + i * 80
            name = _cstr(d[o:o + 64])
            flags, w, h, index = struct.unpack_from('<iiii', d, o + 64)
            pix = np.frombuffer(d, dtype=np.uint8, count=w * h, offset=index).reshape(h, w)
            pal = np.frombuffer(d, dtype=np.uint8, count=768, offset=index + w * h).reshape(256, 3)
            self.textures.append(dict(name=name, flags=flags, width=w, height=h, index=index,
                                      pixels=pix, palette=pal))
        self.skinref = None
        if self.numskinref and self.numskinfamilies:
            self.skinref = np.frombuffer(d, dtype=np.int16, count=self.numskinref * self.numskinfamilies,
                                         offset=self.skinindex).reshape(self.numskinfamilies, self.numskinref)

    def _parse_bodyparts(self):
        d = self.data
        self.bodyparts = []
        for i in range(self.numbodyparts):
            o = self.bodypartindex + i * 76
            name = _cstr(d[o:o + 64])
            nummodels, base, modelindex = struct.unpack_from('<iii', d, o + 64)
            models = []
            for mi in range(nummodels):
                mo = modelindex + mi * 112
                models.append(self._parse_model(mo))
            self.bodyparts.append(dict(name=name, nummodels=nummodels, base=base, models=models))

    def _parse_model(self, mo):
        d = self.data
        name = _cstr(d[mo:mo + 64])
        mtype, radius = struct.unpack_from('<if', d, mo + 64)
        (nummesh, meshindex, numverts, vertinfoindex, vertindex, numnorms, norminfoindex, normindex,
         numgroups, groupindex) = struct.unpack_from('<10i', d, mo + 72)
        vbone = np.frombuffer(d, dtype=np.uint8, count=numverts, offset=vertinfoindex).copy()
        verts = np.frombuffer(d, dtype=np.float32, count=numverts * 3, offset=vertindex).reshape(-1, 3).astype(np.float64)
        nbone = np.frombuffer(d, dtype=np.uint8, count=numnorms, offset=norminfoindex).copy()
        norms = np.frombuffer(d, dtype=np.float32, count=numnorms * 3, offset=normindex).reshape(-1, 3).astype(np.float64)
        meshes = []
        for k in range(nummesh):
            o = meshindex + k * 20
            numtris, triindex, skinref, mnumnorms, mnormindex = struct.unpack_from('<5i', d, o)
            tris = self._decode_tricmds(triindex)
            meshes.append(dict(numtris=numtris, triindex=triindex, skinref=skinref, numnorms=mnumnorms,
                               normindex=mnormindex, tris=tris))
        return dict(name=name, type=mtype, radius=radius, numverts=numverts, numnorms=numnorms,
                    vert_bone=vbone, verts=verts, norm_bone=nbone, norms=norms, meshes=meshes)

    def _decode_tricmds(self, off):
        """Decode strip/fan commands into a list of triangles, each 3x(vertindex, normindex, s, t).
        Winding follows the engine (GL_TRIANGLE_STRIP/FAN semantics)."""
        d = self.data
        tris = []
        while True:
            (n,) = struct.unpack_from('<h', d, off); off += 2
            if n == 0:
                break
            fan = n < 0
            n = abs(n)
            vs = []
            for _ in range(n):
                vs.append(struct.unpack_from('<4h', d, off)); off += 8
            if fan:
                for i in range(2, n):
                    tris.append((vs[0], vs[i - 1], vs[i]))
            else:
                for i in range(2, n):
                    if i % 2 == 0:
                        tris.append((vs[i - 2], vs[i - 1], vs[i]))
                    else:
                        tris.append((vs[i - 1], vs[i - 2], vs[i]))
        return tris

    def _parse_attachments(self):
        self.attachments = []
        for i in range(self.numattachments):
            o = self.attachmentindex + i * 88
            name = _cstr(self.data[o:o + 32])
            typ, bone = struct.unpack_from('<ii', self.data, o + 32)
            org = np.array(struct.unpack_from('<3f', self.data, o + 40))
            self.attachments.append(dict(name=name, type=typ, bone=bone, org=org))

    # ------------------------------------------------------------------ animation decoding
    def anim_values(self, seq_index, blend=0):
        """Decode the full (numframes, numbones, 6) raw channel table (value + anim*scale) for a blend,
        exactly reproducing the RLE walk the engine performs. Cached."""
        key = (seq_index, blend)
        if key in self._anim_cache:
            return self._anim_cache[key]
        s = self.seqs[seq_index]
        if s['seqgroup'] != 0:
            raise NotImplementedError('external sequence groups not supported')
        nb = self.numbones
        nf = s['numframes']
        base = s['animindex'] + blend * nb * 12
        out = np.zeros((nf, nb, 6))
        d = self.data
        for b in range(nb):
            offs = struct.unpack_from('<6H', d, base + b * 12)
            for j in range(6):
                v = self.bone_value[b, j]
                if offs[j] == 0:
                    out[:, b, j] = v
                    continue
                a = base + b * 12 + offs[j]
                vals = self._rle_decode(a, nf)
                out[:, b, j] = v + vals * self.bone_scale[b, j]
        self._anim_cache[key] = out
        return out

    def _rle_decode(self, addr, nf):
        """Return per-frame raw short values (float) for frames 0..nf (nf+1 entries for interpolation
        lookups at k+1). Mirrors StudioCalcBonePosition/Quaterion indexing for integer frames."""
        d = self.data
        res = np.zeros(nf + 1)
        for k in range(nf + 1):
            p = addr
            kk = k
            valid, total = struct.unpack_from('<BB', d, p)
            if total < valid:
                kk = 0
            while total <= kk:
                kk -= total
                p += (valid + 1) * 2
                valid, total = struct.unpack_from('<BB', d, p)
                if total < valid:
                    kk = 0
            if valid > kk:
                (v,) = struct.unpack_from('<h', d, p + (kk + 1) * 2)
            else:
                (v,) = struct.unpack_from('<h', d, p + valid * 2)
            res[k] = v
        return res[:nf] if nf > 0 else res[:1]

    def calc_rotations(self, seq_index, f, blend=0):
        """Port of StudioCalcRotations for one blend: returns pos (nb,3), q (nb,4).
        f is the (float) frame; integer frame + slerp between frame k and k+1 like the engine
        (the engine reads the k+1 value from the RLE stream; on the last frame of a looping
        sequence that is the data following the last frame, which equals the last frame for our
        data since the k+1 read falls on the run's repeated value)."""
        s = self.seqs[seq_index]
        nf = s['numframes']
        if f > nf - 1:
            f = 0.0
        elif f < -0.01:
            f = -0.01
        frame = int(f)
        frac = f - frame
        vals = self.anim_values(seq_index, blend)
        k0 = min(max(frame, 0), nf - 1)
        k1 = min(k0 + 1, nf - 1)
        a0 = vals[k0]
        a1 = vals[k1]
        pos = a0[:, :3] * (1 - frac) + a1[:, :3] * frac
        q0 = angle_quaternion_v(a0[:, 3:])
        q1 = angle_quaternion_v(a1[:, 3:])
        same = np.all(np.abs(a0[:, 3:] - a1[:, 3:]) < 1e-12, axis=1)
        q = quaternion_slerp_v(q0, q1, frac)
        q[same] = q0[same]
        mt = s['motiontype']
        mb = s['motionbone']
        if mt & 0x1: pos[mb, 0] = 0.0
        if mt & 0x2: pos[mb, 1] = 0.0
        if mt & 0x4: pos[mb, 2] = 0.0
        return pos, q

    # ------------------------------------------------------------------ summaries
    def summary(self):
        lines = ['%s: %d bytes, %d bones, %d seqs, %d textures, %d bodyparts, %d hitboxes, %d attachments' % (
            self.name, len(self.data), self.numbones, self.numseq, self.numtextures, self.numbodyparts,
            self.numhitboxes, self.numattachments)]
        return '\n'.join(lines)

    def tri_count(self, body=0):
        n = 0
        for bp in self.bodyparts:
            m = bp['models'][0] if bp['models'] else None
            if m:
                n += sum(len(me['tris']) for me in m['meshes'])
        return n
