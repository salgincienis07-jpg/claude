"""Complete CS 1.6 player sequence set + procedural animation styles ('human', 'zombie', 'boss', 'floaty').

Derived from sources (see README "sequence table"):
  * cs16client GameStudioModelRenderer.cpp: ANIM_WALK_SEQUENCE 3, ANIM_JUMP_SEQUENCE 6, ANIM_SWIM_1 8,
    ANIM_SWIM_2 9, deaths 101..159 (no gait merge), emotions 198..207.
  * regamedll player.cpp SetAnimation / GetAnimDesired: "<ref|crouch>_<aim|shoot|shoot2|reload|run>_<ext>",
    gait via LookupActivity(ACT_IDLE/WALK/RUN/CROUCH/CROUCHIDLE/HOP/LEAP), swim ACT_SWIM/ACT_HOVER,
    flinches "head_flinch"/"gut_flinch", deaths by activity (ACT_DIESIMPLE, DIEBACKWARD, DIEFORWARD,
    DIE_HEADSHOT, DIE_CHESTSHOT, DIE_GUTSHOT, DIE_BACKSHOT) and by name ("left", "right", "crouch_die").
  * extensions set by regamedll wpn_shared/*.cpp: carbine onehanded dualpistols rifle mp5 shotgun m249
    grenade knife c4 ak47 + shield variants shieldgun shieldknife shieldgren shielded shield.
  * 9-blend layout (client numblends==9 code + CalculateYawBlend/StudioPlayerBlend):
      index = row*3 + col;  col 0/1/2 = upper body twisted +90 (left) / 0 / -90 (right) relative to legs
      row 0/1/2 = aim pitch +45 (up) / 0 / -45 (down).
  * walk (index 3) client hack: blending[0] -= 26 (~18.35 deg more left twist) -> our walk gait yaws the
    pelvis -18.35 deg to compensate.
"""
import math
import os
import numpy as np

from .pose import Pose
from .mathx import rot_x, rot_y, rot_z, axis_angle, look_frame, smoothstep, lerp, rot_between
from .rig_cs import FOOT_Z, CROUCH_FOOT_Z, grip_offset, GRIP_R, GRIP_L
from .qc import Sequence
from .smd import write_animation

D2R = math.pi / 180.0
WALK_HACK_DEG = 26.0 / 127.5 * 90.0

YAWS = (90.0, 0.0, -90.0)      # col 0,1,2
PITCHES = (45.0, 0.0, -45.0)   # row 0,1,2

# ------------------------------------------------------------------------------------------ table

GUN_EXTS = ['carbine', 'onehanded', 'dualpistols', 'rifle', 'mp5', 'shotgun', 'm249', 'grenade', 'knife', 'c4',
            'ak47', 'shieldgun', 'shieldknife', 'shieldgren', 'shielded', 'shield']
EXT_ACTIONS = {
    'carbine': ['aim', 'shoot', 'reload'], 'onehanded': ['aim', 'shoot', 'reload'],
    'dualpistols': ['aim', 'shoot', 'shoot2', 'reload'], 'rifle': ['aim', 'shoot', 'reload'],
    'mp5': ['aim', 'shoot', 'reload'], 'shotgun': ['aim', 'shoot', 'reload'], 'm249': ['aim', 'shoot', 'reload'],
    'grenade': ['aim', 'shoot'], 'knife': ['aim', 'shoot'], 'c4': ['aim', 'shoot'],
    'ak47': ['aim', 'shoot', 'reload'], 'shieldgun': ['aim', 'shoot', 'reload'], 'shieldknife': ['aim', 'shoot'],
    'shieldgren': ['aim', 'shoot'], 'shielded': ['aim', 'shoot'], 'shield': ['aim', 'shoot'],
}

DEATHS = [  # name, activity, kind
    ('death1', 'ACT_DIESIMPLE', 'crumple'),
    ('death2', 'ACT_DIEBACKWARD', 'backward'),
    ('death3', 'ACT_DIEFORWARD', 'forward'),
    ('head', 'ACT_DIE_HEADSHOT', 'headshot'),
    ('gutshot', 'ACT_DIE_GUTSHOT', 'gut'),
    ('left', None, 'left'),
    ('back', 'ACT_DIE_BACKSHOT', 'backshot'),
    ('right', None, 'right'),
    ('forward', 'ACT_DIEFORWARD', 'forward2'),
    ('crouch_die', None, 'crouch'),
    ('chestshot', 'ACT_DIE_CHESTSHOT', 'chest'),
]


class SeqDef:
    def __init__(self, name, kind, activity=None, ext=None, action=None, crouch=False, loop=False, motion=None,
                 nine=False):
        self.name = name
        self.kind = kind            # dummy gait swim upper flinch pad death
        self.activity = activity
        self.ext = ext
        self.action = action
        self.crouch = crouch
        self.loop = loop
        self.motion = motion
        self.nine = nine


def sequence_table(nine_exts=None):
    """Ordered SeqDef list. nine_exts: set of extensions that get 9 blends (None = all)."""
    T = [SeqDef('dummy', 'dummy'),
         SeqDef('idle1', 'gait', 'ACT_IDLE', action='idle', loop=True),
         SeqDef('crouch_idle', 'gait', 'ACT_CROUCHIDLE', action='crouch_idle', loop=True),
         SeqDef('walk', 'gait', 'ACT_WALK', action='walk', loop=True, motion='LX'),
         SeqDef('run', 'gait', 'ACT_RUN', action='run', loop=True, motion='LX'),
         SeqDef('crouchrun', 'gait', 'ACT_CROUCH', action='crouchrun', loop=True, motion='LX'),
         SeqDef('jump', 'gait', 'ACT_HOP', action='jump'),
         SeqDef('longjump', 'gait', 'ACT_LEAP', action='longjump'),
         SeqDef('swim', 'swim', 'ACT_SWIM', action='swim', loop=True),
         SeqDef('treadwater', 'swim', 'ACT_HOVER', action='treadwater', loop=True)]
    for ext in GUN_EXTS:
        acts = EXT_ACTIONS[ext]
        nine = nine_exts is None or ext in nine_exts
        for pre in ('crouch', 'ref'):
            for a in acts:
                T.append(SeqDef('%s_%s_%s' % (pre, a, ext), 'upper', ext=ext, action=a, crouch=(pre == 'crouch'),
                                loop=(a == 'aim'), nine=nine))
    T.append(SeqDef('gut_flinch', 'flinch', action='gut'))
    T.append(SeqDef('head_flinch', 'flinch', action='head'))
    k = 0
    while len(T) < 101:
        T.append(SeqDef('pad%d' % k, 'pad'))
        k += 1
    for name, act, kind in DEATHS:
        T.append(SeqDef(name, 'death', act, action=kind, crouch=(kind == 'crouch')))
    assert len(T) <= 160
    return T

# ------------------------------------------------------------------------------------------ styles


class Style:
    """Animation style parameters. kind: human | zombie | boss | floaty."""
    def __init__(self, kind='human', **kw):
        self.kind = kind
        z = kind in ('zombie', 'boss')
        self.hunch = kw.get('hunch', 22.0 if kind == 'zombie' else (14.0 if kind == 'boss' else 3.0))
        self.walk_D = kw.get('walk_D', 64.0)
        self.run_D = kw.get('run_D', 100.0 if kind == 'human' else 96.0)
        self.crouch_D = kw.get('crouch_D', 40.0)
        self.stance_w = kw.get('stance_w', 1.0)      # foot spacing multiplier
        self.knee_bend = kw.get('knee_bend', 0.06 if kind == 'human' else 0.12)
        self.lurch = kw.get('lurch', 0.0 if kind == 'human' else (0.6 if kind == 'zombie' else 0.35))
        self.limp = kw.get('limp', 0.0)
        self.heavy = kw.get('heavy', 1.0 if kind == 'boss' else 0.0)
        self.arm_swing = kw.get('arm_swing', 1.0)
        self.claws = kw.get('claws', kind != 'human')
        self.float_h = kw.get('float_h', 6.0 if kind == 'floaty' else 0.0)
        self.speed_fps = kw.get('fps', 30.0)
        self.aggression = kw.get('aggression', 1.0)
        self.run_lean = kw.get('run_lean', 3.0 if kind == 'human' else 10.0)
        # crouched pelvis height / standing pelvis height. Bosses use hull-fitted hitboxes (hitbox.hull_fit),
        # whose bone-local offsets assume a near-standing pelvis height -> shallow crouch.
        self.crouch_h = kw.get('crouch_h', 0.45 if kind in ('boss', 'floaty') else 0.29)
        self.crouch_tilt = kw.get('crouch_tilt', 15.0 if kind in ('boss', 'floaty') else 28.0)    # deg
        self.crouch_spine = kw.get('crouch_spine', 16.0)  # extra spine hunch in crouch_* upper sequences
        self.extra_bone_anim = kw.get('extra_bone_anim')  # callable(pose, t, context)
        self.claw_spread = kw.get('claw_spread', 1.0)


# ------------------------------------------------------------------------------------------ helpers

def ease(t):
    return t * t * (3 - 2 * t)


def keys(t, ks):
    """Piecewise smooth interpolation through (time, value) keys (values scalars or arrays)."""
    ts = [k[0] for k in ks]
    if t <= ts[0]:
        return np.asarray(ks[0][1], dtype=np.float64)
    if t >= ts[-1]:
        return np.asarray(ks[-1][1], dtype=np.float64)
    for i in range(len(ks) - 1):
        if ts[i] <= t <= ts[i + 1]:
            u = (t - ts[i]) / max(ts[i + 1] - ts[i], 1e-9)
            u = ease(u)
            return np.asarray(ks[i][1], dtype=np.float64) * (1 - u) + np.asarray(ks[i + 1][1], dtype=np.float64) * u


def ypr(yaw=0.0, pitch=0.0, roll=0.0):
    """World/local rotation from yaw (about Z, + = left), pitch (+ = nose DOWN, about Y), roll (about X)."""
    return rot_z(yaw * D2R) @ rot_y(pitch * D2R) @ rot_x(roll * D2R)


SPINE = ['Bip01 Spine', 'Bip01 Spine1', 'Bip01 Spine2', 'Bip01 Spine3']


def apply_spine(pose, yaw=0.0, pitch=0.0, roll=0.0, w=(0.2, 0.27, 0.28, 0.25), neck=0.0, head=None):
    """Distribute a torso rotation over the 4 spine bones (local, applied in order)."""
    for b, wi in zip(SPINE, w):
        pose.local_rot(b, ypr(yaw * wi, pitch * wi, roll * wi))
    if head is not None:
        hy, hp, hr = head
        pose.local_rot('Bip01 Neck', ypr(hy * 0.4, hp * 0.4, hr * 0.4))
        pose.local_rot('Bip01 Head', ypr(hy * 0.6, hp * 0.6, hr * 0.6))


def chest_frame(pose):
    """Origin = midpoint of the shoulder joints, rotation = Spine3 world rotation."""
    pL = pose.wpos('Bip01 L UpperArm'); pR = pose.wpos('Bip01 R UpperArm')
    return (pL + pR) / 2, pose.wrot('Bip01 Spine3')


def ground_points(pose, hands=True, core=False, arms=True):
    """Approximate body surface sample points (joint positions +- radius) for ground alignment.
    core=True: only torso/head/upper limbs (the parts a lying body rests on)."""
    rig = pose.rig
    WR, WT = pose.world()
    k = rig.H / 72.0 * max(1.0, rig.spec.bulk ** 0.5)
    pts = []
    rad = {'Bip01 Head': 4.5, 'Bip01 Neck': 2.5, 'Bip01 Spine3': 5.0, 'Bip01 Spine2': 5.0, 'Bip01 Spine1': 4.5,
           'Bip01 Spine': 4.5, 'Bip01 Pelvis': 4.5}
    for nm, r in rad.items():
        p = WT[rig.index[nm]]
        if nm == 'Bip01 Head':
            p = p + WR[rig.index[nm]] @ np.array([0.4, 0, 4.6]) * k
        pts.append(p - np.array([0, 0, r * k]))
    if not core:
        for i, nm in enumerate(rig.names):
            if not nm.startswith(('Bip01', 'Wing_', 'XLimb_')):
                pts.append(WT[i] - np.array([0, 0, 1.2 * k]))
    for side in 'LR':
        for nm, r in (('UpperArm', 2.2), ('Forearm', 1.8), ('Hand', 1.5), ('Thigh', 3.5), ('Calf', 2.4),
                      ('Foot', 1.5), ('Toe0', 0.8), ('Finger11', 0.6)):
            if not hands and nm in ('Hand', 'Finger11'):
                continue
            if core and nm not in ('UpperArm', 'Thigh'):
                continue
            if not arms and nm in ('UpperArm', 'Forearm', 'Hand', 'Finger11'):
                continue
            p = WT[rig.index['Bip01 %s %s' % (side, nm)]]
            pts.append(p - np.array([0, 0, r * k]))
    return np.array(pts)


def ground_align(pose, floor):
    """Shift the root so the lowest approximate surface point touches `floor`."""
    z = ground_points(pose)[:, 2].min()
    pose.t[0] = pose.t[0] + np.array([0, 0, floor - z])
    pose.dirty()

# ------------------------------------------------------------------------------------------ legs / gait


class Gait:
    def __init__(self, rig, style):
        self.rig = rig
        self.st = style
        self.H = rig.H
        self.k = rig.H / 72.0
        self.hip_h = rig.J('Bip01 Pelvis')[2] - FOOT_Z     # pelvis height above ground (rest)
        self.leg_len = (np.linalg.norm(rig.rest_local_pos[rig.i('Bip01 L Calf')]) +
                        np.linalg.norm(rig.rest_local_pos[rig.i('Bip01 L Foot')]))
        self.ankle_h = rig.J('Bip01 L Foot')[2] - FOOT_Z
        self.foot_y = rig.J('Bip01 L Foot')[1] * style.stance_w

    def place_legs(self, pose, feet, poles=None):
        """feet: dict side -> (ankle world pos, foot world rotation)."""
        for side in 'LR':
            ank, R = feet[side]
            pole = poles[side] if poles else (pose.wrot('Bip01 Pelvis') @ np.array([1.0, 0.0, 0.0]) + np.array([0, 0, 0.0]))
            pose.two_bone_ik('Bip01 %s Thigh' % side, 'Bip01 %s Calf' % side, 'Bip01 %s Foot' % side, ank, pole,
                             end_rot=R)

    def hover_h(self, crouch=False):
        """Height of the floating floor above the real floor ('floaty' style: float_h > 0)."""
        return self.st.float_h * (0.6 if crouch else 1.0) * self.k

    def standing(self, pose, crouch=False, t=0.0, spread=1.0, bob=0.0, hover=0.0):
        """Neutral stance (frame 0 of idle1 / crouch_idle). Crouch keeps the whole body inside the
        36-unit crouch hull: deep squat, pelvis ~0.36 of the standing hip height, forward lean.
        Floaty styles (float_h > 0) hover float_h (+hover) above the floor with dangling, toes-down feet."""
        floor = CROUCH_FOOT_Z if crouch else FOOT_Z
        st = self.st
        k = self.k
        floaty = st.float_h > 0
        if floaty:
            floor = floor + self.hover_h(crouch) + hover
        if crouch:
            ph = self.hip_h * st.crouch_h
        else:
            ph = self.hip_h * (1 - st.knee_bend) - bob
        root = np.array([0.0 - (2.0 * k if crouch else 0.0), 0.0, floor + ph])
        tilt = (st.crouch_tilt if crouch else 0.0) + (st.hunch * 0.3 if st.kind != 'human' else 0.0)
        pose.set_root(root, ypr(0, tilt, 0))
        feet = {}
        for side, sg in (('L', 1), ('R', -1)):
            if crouch:
                fx = (3.5 if side == 'L' else -1.5) * k
                fz = floor + self.ankle_h + (0.0 if side == 'L' else 1.6 * k)
                Rf = ypr(sg * 12, 0 if side == 'L' else 22, 0)
                fy = sg * abs(self.foot_y) * 1.35 * spread
            else:
                fx = (1.5 if side == 'L' else -1.0) * k
                fz = floor + self.ankle_h
                Rf = ypr(sg * (6 + 6 * (st.kind != 'human')), 0, 0)
                fy = sg * abs(self.foot_y) * spread
            if floaty:   # dangling legs: feet a little apart and back, toes pointing down
                fx = (0.5 if side == 'L' else -2.0) * k
                fz = floor + self.ankle_h + (0.8 if side == 'L' else 1.6) * k
                Rf = ypr(sg * 8, 38 if side == 'L' else 48, 0)
            feet[side] = (np.array([fx, fy, fz]), Rf)
        poles = {s: np.array([1.0, sg * (0.45 if crouch else 0.15), 0.0]) for s, sg in (('L', 1), ('R', -1))}
        self.place_legs(pose, feet, poles)
        return pose

    def cycle(self, kind, nframes):
        """Locomotion cycle frames (Pose list) in extracted space + linear movement distance."""
        st = self.st
        k = self.k
        crouch = kind == 'crouchrun'
        if kind == 'walk':
            D, duty, lift, bob_a, lean = st.walk_D * k, 0.6, 3.2 * k, 0.9 * k, 2.0
        elif kind == 'run':
            D, duty, lift, bob_a, lean = st.run_D * k, 0.38, 7.0 * k, 1.6 * k, st.run_lean
        else:
            D, duty, lift, bob_a, lean = st.crouch_D * k, 0.62, 2.6 * k, 0.6 * k, st.crouch_tilt
        if st.heavy:
            lift *= 0.8; bob_a *= 1.5
        floor = CROUCH_FOOT_Z if crouch else FOOT_Z
        N = nframes
        if st.float_h > 0:
            return self._glide(kind, N, D, lean, floor + self.hover_h(crouch), crouch)
        frames = []
        for f in range(N):
            ph = f / (N - 1)
            pose = Pose(self.rig)
            feet = {}
            for side, sg, off in (('L', 1, 0.0), ('R', -1, 0.5)):
                p = (ph + off) % 1.0
                limp = st.limp * (side == 'R')
                if p < duty:
                    s = p / duty
                    x = D * duty * (0.5 - s)
                    z = 0.0
                    pitch = keys(s, [(0, -14), (0.15, 0), (0.7, 0), (1.0, 32)])   # heel strike .. toe off
                else:
                    s = (p - duty) / (1 - duty)
                    x = D * duty * (-0.5 + ease(s))
                    z = lift * math.sin(math.pi * s) ** 1.2 * (1 - 0.5 * limp)
                    if kind == 'run':
                        z += 2.5 * k * math.sin(math.pi * min(1, s * 1.6)) * (s < 0.62)
                    pitch = keys(s, [(0, 35), (0.35, 20), (0.8, -10), (1.0, -14)])
                fy = sg * abs(self.foot_y) * (1.3 if crouch else 1.0)
                ank = np.array([x, fy, floor + self.ankle_h + z])
                if pitch > 0:   # toe-off: rotate about the toe so the ball stays near the ground
                    ank[2] += math.sin(pitch * D2R) * 6.5 * k * 0.8
                    ank[0] -= (1 - math.cos(pitch * D2R)) * 6.5 * k * 0.5
                elif pitch < 0:  # heel strike: rotate about the heel
                    ank[2] += math.sin(-pitch * D2R) * 2.0 * k
                Rf = ypr(sg * (5 + 4 * (st.kind != 'human')), pitch, 0)
                feet[side] = (ank, Rf)
            # pelvis
            two = 2 * math.pi * ph * 2
            if kind == 'run':
                bob = -bob_a * math.cos(two)   # lowest mid-stance
            else:
                bob = bob_a * math.cos(two)
            sway = math.sin(2 * math.pi * ph) * (1.0 if kind != 'run' else 0.5) * k
            yaw = math.sin(2 * math.pi * ph) * (6 if kind == 'walk' else 9) * (-1)
            roll = math.sin(2 * math.pi * ph) * 3.5
            lurch = st.lurch * math.sin(2 * math.pi * ph + 0.6)
            if kind == 'walk':
                yaw -= WALK_HACK_DEG
            hh = self.hip_h * (st.crouch_h + 0.02 if crouch else (1 - st.knee_bend - (0.03 if kind == 'run' else 0.0)))
            root = np.array([(-2.0 * k if crouch else 0.0) + lurch * 1.0 * k, sway * 0.3 + lurch * 0.6 * k,
                             floor + hh + bob])
            pose.set_root(root, ypr(yaw + lurch * 6, lean + (st.hunch * 0.25 if st.kind != 'human' else 0) + lurch * 3,
                                     roll + lurch * 4))
            poles = {}
            for side, sg in (('L', 1), ('R', -1)):
                poles[side] = np.array([1.0, sg * 0.12, 0.0])
            self.place_legs(pose, feet, poles)
            frames.append(pose)
        lm = D * N / (N - 1)
        return frames, lm

    def _glide(self, kind, N, D, lean, floor, crouch):
        """'floaty' locomotion: no steps - the body glides with a slow bob, leaning into the motion while
        the dangling legs trail behind and sway. Linear movement is kept (the client needs it)."""
        st = self.st
        k = self.k
        frames = []
        run = kind == 'run'
        hh = self.hip_h * (st.crouch_h + 0.02 if crouch else (1 - st.knee_bend))
        for f in range(N):
            ph = f / (N - 1)
            pose = Pose(self.rig)
            w = 2 * math.pi * ph
            bob = 1.2 * k * math.sin(w)
            yaw = 4.0 * math.sin(w) - (WALK_HACK_DEG if kind == 'walk' else 0.0)
            tilt = (lean + (14.0 if run else 7.0)) if not crouch else lean
            root = np.array([0.0, 0.6 * k * math.sin(w), floor + hh + bob])
            pose.set_root(root, ypr(yaw, tilt + 2.0 * math.sin(w + 0.7), 3.0 * math.sin(w)))
            feet = {}
            for side, sg, off in (('L', 1, 0.0), ('R', -1, math.pi)):
                sw = math.sin(w + off)
                trail = (5.0 if run else 3.0) * k
                ank = np.array([-trail + 1.5 * k * sw, sg * abs(self.foot_y) * 0.9,
                                floor + self.ankle_h + (2.0 + 1.2 * sw) * k + (2.0 * k if run else 0.0)])
                feet[side] = (ank, ypr(sg * 8, 50 + 10 * sw, 0))
            poles = {s_: np.array([1.0, sg_ * 0.15, 0.0]) for s_, sg_ in (('L', 1), ('R', -1))}
            self.place_legs(pose, feet, poles)
            frames.append(pose)
        return frames, D * N / (N - 1)

    def jump(self, nframes, long=False):
        """ACT_HOP / ACT_LEAP gait: legs tuck up while airborne (the player origin moves, not the model)."""
        frames = []
        k = self.k
        for f in range(nframes):
            t = f / (nframes - 1)
            pose = Pose(self.rig)
            tuck = keys(t, [(0, 0.15), (0.3, 1.0), (0.75, 0.85), (1.0, 0.4)])
            root = np.array([0.0, 0.0, FOOT_Z + self.hover_h() + self.hip_h * (1 - self.st.knee_bend) + 1.5 * k * tuck])
            pose.set_root(root, ypr(0, (10 if long else 6) * tuck, 0))
            feet = {}
            for side, sg in (('L', 1), ('R', -1)):
                if long:
                    fx = (10.0 if side == 'L' else -12.0) * k * tuck
                    fz = FOOT_Z + self.hover_h() + self.ankle_h + tuck * (14.0 if side == 'L' else 8.0) * k
                    pitch = (-10 if side == 'L' else 45) * tuck
                else:
                    fx = (2.0 if side == 'L' else -2.5) * k * tuck
                    fz = FOOT_Z + self.hover_h() + self.ankle_h + tuck * (17.0 if side == 'L' else 13.0) * k
                    pitch = 35 * tuck
                feet[side] = (np.array([fx, sg * abs(self.foot_y) * 1.1, fz]), ypr(sg * 8, pitch, 0))
            poles = {s: np.array([1.0, sg * 0.2, 0]) for s, sg in (('L', 1), ('R', -1))}
            self.place_legs(pose, feet, poles)
            frames.append(pose)
        return frames


# ------------------------------------------------------------------------------------------ weapon holds
# Positions are in the CHEST frame (origin = shoulder midpoint, axes = Spine3) for a 72-unit human and
# are scaled by rig height. Gun frame orientation: (yaw, pitch, roll) relative to the chest frame.
# 'fore' = distance along the gun X axis from the right grip centre to the support-hand grip point,
# 'fore_down' = height (gun Z) of the support-hand grip point above the right grip centre (the handguard
# axis; the bore is pmodel.BORE_Z = 2.4 above the grip centre).

HOLDS = {
    'rifle':   dict(grip=(13.0, -5.2, -2.6), rot=(4, 0, 0), fore=9.5, fore_down=1.9, left='fore',
                    elbowR=(-0.3, -1.0, -0.7), elbowL=(0.1, 0.5, -1.0), head=(8, 8, 6)),
    'carbine': dict(grip=(12.5, -5.0, -3.0), rot=(5, 2, 0), fore=8.5, fore_down=1.9, left='fore',
                    elbowR=(-0.3, -1.0, -0.7), elbowL=(0.1, 0.5, -1.0), head=(6, 6, 4)),
    'ak47':    dict(grip=(12.8, -5.2, -2.9), rot=(5, 2, 0), fore=9.0, fore_down=1.9, left='fore',
                    elbowR=(-0.3, -1.0, -0.7), elbowL=(0.1, 0.5, -1.0), head=(6, 6, 4)),
    'mp5':     dict(grip=(12.0, -4.8, -3.2), rot=(6, 3, 0), fore=7.0, fore_down=1.9, left='fore',
                    elbowR=(-0.3, -1.0, -0.7), elbowL=(0.1, 0.5, -1.0), head=(5, 5, 3)),
    'shotgun': dict(grip=(12.5, -5.0, -3.4), rot=(5, 3, 0), fore=9.3, fore_down=1.5, left='fore',
                    elbowR=(-0.3, -1.0, -0.7), elbowL=(0.1, 0.5, -1.0), head=(6, 6, 4)),
    'm249':    dict(grip=(10.5, -6.0, -7.0), rot=(6, -6, 0), fore=9.5, fore_down=1.9, left='fore',
                    elbowR=(-0.5, -1.0, -0.4), elbowL=(0.2, 0.6, -1.0), head=(3, 3, 0)),
    'onehanded': dict(grip=(18.5, -1.8, -0.5), rot=(2, 0, 0), left='cup',
                      elbowR=(-0.2, -1.0, -1.0), elbowL=(-0.2, 1.0, -1.0), head=(2, 4, 0)),
    'dualpistols': dict(grip=(17.5, -4.6, -1.8), gripL=(17.5, 4.6, -1.8), rot=(3, 0, -10), rotL=(-3, 0, 10),
                        left='pistol', elbowR=(-0.2, -1.0, -1.0), elbowL=(-0.2, 1.0, -1.0), head=(0, 3, 0)),
    'knife':   dict(grip=(10.0, -6.5, -6.5), rot=(10, -20, 0), left='guard', guardL=(8.0, 4.5, -3.5),
                    elbowR=(-0.3, -1.0, -1.0), elbowL=(0.0, 1.0, -1.0), head=(0, 2, 0)),
    'grenade': dict(grip=(8.0, -6.0, -4.0), rot=(10, -10, 0), left='guard', guardL=(10.0, 4.0, -3.0),
                    elbowR=(-0.4, -1.0, -0.6), elbowL=(0.0, 1.0, -1.0), head=(0, 2, 0)),
    'c4':      dict(grip=(9.5, -2.8, -9.0), rot=(5, 10, 0), left='c4', gripL=(9.5, 2.8, -9.0),
                    elbowR=(-0.2, -1.0, -0.8), elbowL=(-0.2, 1.0, -0.8), head=(0, 10, 0)),
    'shieldgun': dict(grip=(14.0, -6.5, 0.5), rot=(0, 0, 0), left='shield', guardL=(10.0, 1.5, -1.0),
                      elbowR=(-0.2, -1.0, -1.0), elbowL=(0.0, 1.0, -0.5), head=(0, 2, 0)),
    'shieldknife': dict(grip=(10.0, -7.0, -4.0), rot=(10, -20, 0), left='shield', guardL=(10.0, 1.5, -1.0),
                        elbowR=(-0.3, -1.0, -1.0), elbowL=(0.0, 1.0, -0.5), head=(0, 2, 0)),
    'shieldgren': dict(grip=(8.0, -7.0, -4.0), rot=(10, -10, 0), left='shield', guardL=(10.0, 1.5, -1.0),
                       elbowR=(-0.4, -1.0, -0.6), elbowL=(0.0, 1.0, -0.5), head=(0, 2, 0)),
    'shielded': dict(grip=(8.0, -5.0, -3.0), rot=(10, 10, 0), left='shield', guardL=(10.5, 1.0, 3.0),
                     elbowR=(-0.4, -1.0, -0.6), elbowL=(0.0, 1.0, -0.2), head=(0, 6, 0)),
    'shield': dict(grip=(8.0, -5.0, -3.0), rot=(10, 10, 0), left='shield', guardL=(10.5, 1.0, 3.0),
                   elbowR=(-0.4, -1.0, -0.6), elbowL=(0.0, 1.0, -0.2), head=(0, 6, 0)),
}


def support_rot_for_fore(G):
    """Left hand frame wrapping a handguard whose axis is the gun X (palm up)."""
    gx, gy, gz = G[:, 0], G[:, 1], G[:, 2]
    Zl = gx
    Yl = -gz
    Xl = np.cross(Yl, Zl)
    return np.stack([Xl, Yl, Zl], axis=1)


class UpperBody:
    """Upper body pose builder for one model (rig + style)."""
    def __init__(self, rig, style):
        self.rig = rig
        self.st = style
        self.k = rig.H / 72.0
        self.gait = Gait(rig, style)

    def base(self, crouch=False):
        """Pose with the root/legs of the gait frame this upper-body pose will be merged onto
        (idle1 or crouch_idle). export_sequences() resets those bones to the rest pose afterwards (the
        engine replaces them with the gait anyway), so only the spine/arm LOCAL rotations matter -
        but they are authored against the real pelvis orientation."""
        pose = Pose(self.rig)
        self.gait.standing(pose, crouch=crouch)
        return pose

    def torso(self, pose, yaw, pitch, crouch=False, extra=(0, 0, 0), kp=0.5, head_extra=(0, 0, 0)):
        st = self.st
        hunch = st.hunch + (st.crouch_spine if crouch else 0.0)
        # pitch: + up ; our ypr pitch: + = nose down -> negate
        if crouch:
            kp = kp * 0.5          # crouched: the arms take most of the aim pitch (head stays in the hull)
        sp_pitch = -pitch * kp + hunch + extra[1]
        apply_spine(pose, yaw=yaw + extra[0], pitch=sp_pitch, roll=extra[2])
        # head keeps looking along the aim: undo hunch, take the rest of the pitch
        hp = -pitch * (1 - kp) * (0.45 if crouch else 0.8) - hunch * 0.85 + head_extra[1]
        pose.local_rot('Bip01 Neck', ypr(head_extra[0] * 0.4, hp * 0.4, head_extra[2] * 0.4))
        pose.local_rot('Bip01 Head', ypr(head_extra[0] * 0.6, hp * 0.6, head_extra[2] * 0.6))

    def aim_frame(self, pose, yaw, pitch, kp=0.5):
        """Aim frame anchored at the shoulders: yaw of the chest, pitch exactly the requested aim pitch
        (independent of hunch / crouch lean), no roll."""
        o, R = chest_frame(pose)
        fx = R[:, 0]
        cy = math.degrees(math.atan2(fx[1], fx[0]))
        return o, ypr(cy, -pitch, 0)

    def hold(self, pose, ext, yaw, pitch, kick=None, crouch=False, override=None, lhand=None, kp=0.5):
        """Place both arms for weapon extension `ext`. kick: dict with 'back','up','roll','yaw' offsets
        in gun frame (recoil), lhand: optional override for the support hand world target/rot."""
        h = dict(HOLDS[ext])
        if override:
            h.update(override)
        k = self.k
        o, A = self.aim_frame(pose, yaw, pitch, kp)
        gp = o + A @ (np.array(h['grip']) * k)
        G = A @ ypr(*h['rot'])
        if kick:
            gp = gp + G @ np.array([-kick.get('back', 0.0), kick.get('side', 0.0), kick.get('up', 0.0)]) * k
            G = G @ ypr(kick.get('yaw', 0.0), -kick.get('pitch', 0.0), kick.get('roll', 0.0))
        self._place_hand(pose, 'R', gp, G, A @ np.array(h['elbowR']))
        mode = h['left']
        if lhand is not None:
            tgt, RL, pole = lhand
            self._place_wrist(pose, 'L', tgt, RL, pole if pole is not None else A @ np.array(h['elbowL']))
        elif mode == 'fore':
            fp = gp + G @ np.array([h['fore'] * k, 0.0, h['fore_down'] * k])
            RL = support_rot_for_fore(G)
            self._place_hand(pose, 'L', fp, RL, A @ np.array(h['elbowL']))
        elif mode == 'cup':
            # support hand wraps the shooting hand from below/left
            wristR = pose.wpos('Bip01 R Hand')
            RL = G @ ypr(0, 0, -35)
            tgt = wristR + G @ np.array([-0.6, 2.4, -2.0]) * k
            self._place_wrist(pose, 'L', tgt, RL, A @ np.array(h['elbowL']))
        elif mode == 'pistol':
            gpl = o + A @ (np.array(h['gripL']) * k)
            GL = A @ ypr(*h['rotL'])
            if kick and kick.get('left'):
                kk = kick['left']
                gpl = gpl + GL @ np.array([-kk.get('back', 0.0), 0, kk.get('up', 0.0)]) * k
                GL = GL @ ypr(0, -kk.get('pitch', 0.0), 0)
            self._place_hand(pose, 'L', gpl, GL, A @ np.array(h['elbowL']))
        elif mode == 'c4':
            gpl = o + A @ (np.array(h['gripL']) * k)
            self._place_hand(pose, 'L', gpl, A @ ypr(-90, 0, 0) @ ypr(0, 0, 90), A @ np.array(h['elbowL']))
        else:  # guard / shield: fist in front of the chest
            gl = o + A @ (np.array(h['guardL']) * k)
            RL = A @ ypr(-60 if mode == 'shield' else -20, -30 if mode == 'shield' else 10, 70 if mode == 'shield' else 0)
            self._place_wrist(pose, 'L', gl, RL, A @ np.array(h['elbowL']))
        return gp, G, o, A

    def _place_hand(self, pose, side, grip_pt, Rg, pole):
        go = grip_offset(self.rig, side)
        wrist = grip_pt - Rg @ go
        self._place_wrist(pose, side, wrist, Rg, pole)

    def _place_wrist(self, pose, side, wrist, Rg, pole):
        # clavicle shrug toward the target a little
        cl = 'Bip01 %s Clavicle' % side
        sh = pose.wpos('Bip01 %s UpperArm' % side)
        d = wrist - sh
        pose.rotate_world(cl, axis_angle(np.cross(pose.wpos(cl) - sh, d) if np.linalg.norm(np.cross(pose.wpos(cl) - sh, d)) > 1e-6 else [0, 0, 1], 0.0))
        pose.two_bone_ik('Bip01 %s UpperArm' % side, 'Bip01 %s Forearm' % side, 'Bip01 %s Hand' % side,
                         wrist, pole, end_rot=Rg)


# ------------------------------------------------------------------------------------------ generators

def _fingers(pose, curlR=0.0, curlL=0.0, thumbR=0.0, thumbL=0.0, spreadR=0.0, spreadL=0.0):
    pose.fingers('R', curlR, thumbR, spreadR)
    pose.fingers('L', curlL, thumbL, spreadL)


class AnimBuilder:
    """Generates every SeqDef for a rig/style. Produces per-sequence list-of-blends of list-of-Pose."""

    def __init__(self, rig, style, nine_exts=None, hooks=None):
        self.rig = rig
        self.st = style
        self.ub = UpperBody(rig, style)
        self.gait = self.ub.gait
        self.k = rig.H / 72.0
        self.nine_exts = nine_exts
        self.hooks = hooks or {}

    # ---------------------------------------------------------------- upper body (human)
    def human_upper(self, ext, action, crouch, yaw, pitch, nfr):
        frames = []
        for f in range(nfr):
            t = f / max(nfr - 1, 1)
            pose = self.ub.base(crouch)
            extra = np.zeros(3)
            kick = None
            lhand = None
            curlL = 0.0
            if action == 'shoot' or action == 'shoot2':
                if ext in ('knife', 'shieldknife'):
                    pose, done = self._human_knife(pose, ext, crouch, yaw, pitch, t)
                    frames.append(pose)
                    continue
                if ext in ('grenade', 'shieldgren'):
                    pose = self._human_throw(pose, ext, crouch, yaw, pitch, t)
                    frames.append(pose)
                    continue
                if ext == 'c4':
                    a = math.sin(math.pi * t)
                    extra = np.array([0, 12 * a, 0])
                    kick = dict(up=-3 * a, back=-1 * a)
                else:
                    heavy = {'shotgun': 1.6, 'm249': 0.7, 'rifle': 1.3, 'onehanded': 1.0}.get(ext, 1.0)
                    a = keys(t, [(0, 0), (0.12, 1.0), (0.5, 0.35), (1.0, 0.0)])
                    kick = dict(back=1.6 * a * heavy, pitch=7 * a * heavy, up=0.4 * a)
                    extra = np.array([0, -2.0 * a * heavy, 0])
                    if ext == 'dualpistols':
                        if action == 'shoot2':
                            kick = dict(left=dict(back=1.6 * a, pitch=9 * a))
                        else:
                            kick = dict(back=1.6 * a, pitch=9 * a)
                    if ext == 'shotgun':
                        # pump: support hand slides back and forth
                        pump = keys(t, [(0, 0), (0.35, 0), (0.55, 1), (0.8, 0)])
                        kick['pump'] = pump
            elif action == 'reload':
                pose = self._human_reload(pose, ext, crouch, yaw, pitch, t)
                frames.append(pose)
                continue
            self.ub.torso(pose, yaw, pitch, crouch, extra=extra, head_extra=HOLDS[ext].get('head', (0, 0, 0)))
            if kick and 'pump' in kick:
                pump = kick.pop('pump')
                gp, G, o, A = self.ub.hold(pose, ext, yaw, pitch, kick=kick, crouch=crouch)
                fp = gp + G @ np.array([(HOLDS[ext]['fore'] - 3.5 * pump) * self.k, 0, HOLDS[ext]['fore_down'] * self.k])
                self.ub._place_hand(pose, 'L', fp, support_rot_for_fore(G), A @ np.array(HOLDS[ext]['elbowL']))
            else:
                self.ub.hold(pose, ext, yaw, pitch, kick=kick, crouch=crouch)
            _fingers(pose, 0.0, curlL)
            frames.append(pose)
        return frames

    def _human_knife(self, pose, ext, crouch, yaw, pitch, t):
        # slash: right arm wind-up to the right then sweep across to the left
        sw = keys(t, [(0, 0.0), (0.25, -1.0), (0.55, 1.0), (1.0, 0.0)])
        self.ub.torso(pose, yaw, pitch, crouch, extra=np.array([-25 * sw, 4 * abs(sw), 0]))
        ov = dict(grip=(12.0 + 4 * (1 - abs(sw)), -6.5 + 9 * sw, -3.0 + 2 * abs(sw)), rot=(-40 * sw + 10, -10, 25 * sw))
        self.ub.hold(pose, ext, yaw, pitch, override=ov, crouch=crouch)
        return pose, True

    def _human_throw(self, pose, ext, crouch, yaw, pitch, t):
        wind = keys(t, [(0, 0.0), (0.35, 1.0), (0.6, -0.6), (1.0, 0.0)])
        self.ub.torso(pose, yaw, pitch, crouch, extra=np.array([-20 * wind, -8 * wind, 0]))
        if wind > 0:
            ov = dict(grip=(1.0 - 6 * wind, -8.0, 4.0 + 6 * wind), rot=(20, 40 * wind, 0))
        else:
            ov = dict(grip=(10.0 - 10 * wind, -5.0, -3.0 + 2 * wind), rot=(10, -10, 0))
        self.ub.hold(pose, ext, yaw, pitch, override=ov, crouch=crouch)
        return pose

    def _human_reload(self, pose, ext, crouch, yaw, pitch, t):
        k = self.k
        h = HOLDS[ext]
        tilt = keys(t, [(0, 0), (0.15, 1), (0.85, 1), (1.0, 0)])
        self.ub.torso(pose, yaw, pitch, crouch, extra=np.array([0, 6 * tilt, 0]), head_extra=(0, 10 * tilt, 0))
        ov = dict(grip=(np.array(h['grip']) + np.array([-3.0, 1.5, -1.5]) * tilt).tolist(),
                  rot=(h['rot'][0] + 10 * tilt, h['rot'][1] + 18 * tilt, h['rot'][2] - 28 * tilt))
        if ext in ('onehanded', 'shieldgun', 'dualpistols'):
            ov['grip'] = (np.array(h['grip']) + np.array([-7.0, 2.0, -2.0]) * tilt).tolist()
        # support hand path: grip -> magwell -> pouch (left hip) -> magwell -> bolt -> grip
        gp, G, o, A = self.ub.hold(pose, ext, yaw, pitch, override=ov, crouch=crouch,
                                   lhand=(np.zeros(3), np.eye(3), None))
        magwell = gp + G @ (np.array([3.5, 0.0, -4.5]) * k)
        pouch = o + A @ (np.array([4.0, 6.0, -14.0]) * k)
        if ext in ('onehanded', 'shieldgun', 'dualpistols'):
            magwell = gp + G @ (np.array([-0.5, 0.0, -4.0]) * k)
        if 'fore' in h:
            fore = gp + G @ np.array([h['fore'] * k, 0, h['fore_down'] * k])
        else:
            fore = magwell
        bolt = gp + G @ (np.array([2.0, -2.5, 1.5]) * k)
        if ext == 'shotgun':
            path = [(0.0, fore), (0.15, magwell), (0.3, pouch), (0.45, magwell), (0.6, pouch), (0.75, magwell),
                    (0.9, fore), (1.0, fore)]
        elif ext == 'm249':
            top = gp + G @ (np.array([3.0, 1.5, 3.5]) * k)
            path = [(0.0, fore), (0.15, top), (0.3, magwell), (0.45, pouch), (0.62, magwell), (0.78, top),
                    (0.9, fore), (1.0, fore)]
        else:
            path = [(0.0, fore), (0.15, magwell), (0.32, magwell + G @ np.array([0, 0, -3.0 * k])), (0.48, pouch),
                    (0.66, magwell + G @ np.array([0, 0, -2.0 * k])), (0.76, magwell), (0.86, bolt), (1.0, fore)]
        tgt = keys(t, path)
        if 'fore' in h:
            RLf = support_rot_for_fore(G)
        else:
            RLf = G @ ypr(0, 0, -35)
        RLm = A @ ypr(-60, 30, 60)
        w = keys(t, [(0, 0), (0.12, 1), (0.88, 1), (1.0, 0)])
        from .pose import blend_poses
        RL = _slerp_mat(RLf, RLm, float(w))
        go = grip_offset(self.rig, 'L')
        wrist = tgt - RL @ go
        self.ub._place_wrist(pose, 'L', wrist, RL, A @ np.array(h['elbowL']))
        return pose

    # ---------------------------------------------------------------- upper body (zombie / boss)
    def claw_rot(self, A, side, down=20.0, inward=15.0, roll=0.0):
        """Claw hand orientation: fingers (grip X) forward, palm down (+Y grip of the right hand / -Y of
        the left hand faces down), then pitched `down`, yawed `inward`, rolled."""
        sg = 1 if side == 'L' else -1
        base = rot_x(-math.pi / 2) if side == 'R' else rot_x(math.pi / 2)
        return A @ ypr(-sg * inward, down, -sg * roll) @ base

    def _claw_pose(self, pose, crouch, yaw, pitch, br):
        k = self.k
        sp = self.st.claw_spread
        extra = np.array([3 * br, 3 * br, 2 * br])
        self.ub.torso(pose, yaw, pitch, crouch, extra=extra, kp=0.6, head_extra=(4 * br, -6, 5 * br))
        o, A = self.ub.aim_frame(pose, yaw, pitch, kp=0.6)
        for side, sg in (('R', -1), ('L', 1)):
            ph = br * (1 if side == 'R' else -1)
            tgt = o + A @ (np.array([12.5 + 1.0 * ph, sg * (6.0 * sp + 0.8 * ph), -4.0 + 1.2 * ph]) * k)
            R = self.claw_rot(A, side, down=15 + 6 * ph, inward=12, roll=20)
            self.ub._place_wrist(pose, side, tgt, R, A @ np.array([-0.2, sg * 1.0, -0.6]))
        _fingers(pose, -0.1 + 0.15 * br, -0.1 - 0.15 * br, -0.3, -0.3, 1.0, 1.0)
        return pose

    def claw_upper(self, action, crouch, yaw, pitch, nfr):
        k = self.k
        frames = []
        for f in range(nfr):
            t = f / max(nfr - 1, 1)
            pose = self.ub.base(crouch)
            if action == 'aim':
                self._claw_pose(pose, crouch, yaw, pitch, math.sin(2 * math.pi * t))
            else:  # slash (shoot): big right swipe with a follow-through, left arm counter
                sw = keys(t, [(0, 0.0), (0.3, -1.0), (0.55, 1.0), (0.8, 0.6), (1.0, 0.0)])
                lunge = keys(t, [(0, 0), (0.45, 1), (1.0, 0)])
                extra = np.array([-28 * sw, 10 * lunge + 6 * abs(sw), 8 * sw])
                self.ub.torso(pose, yaw, pitch, crouch, extra=extra, kp=0.6, head_extra=(10 * sw, -4, 0))
                o, A = self.ub.aim_frame(pose, yaw, pitch, kp=0.6)
                rest = np.array([12.5, -6.0, -4.0])
                wind = np.array([1.0, -10.0, 7.0])
                hit = np.array([15.0, 3.0, -6.0])
                follow = np.array([9.0, 7.0, -10.0])
                pR = keys(t, [(0, rest), (0.3, wind), (0.55, hit), (0.8, follow), (1.0, rest)])
                tgtR = o + A @ (pR * k)
                dR = keys(t, [(0, 15.0), (0.3, -70.0), (0.55, 25.0), (0.8, 45.0), (1.0, 15.0)])
                iR = keys(t, [(0, 12.0), (0.3, -20.0), (0.55, 45.0), (0.8, 60.0), (1.0, 12.0)])
                RR = self.claw_rot(A, 'R', down=float(dR), inward=float(iR), roll=20)
                self.ub._place_wrist(pose, 'R', tgtR, RR, A @ np.array([-0.2, -1.0, -0.2]))
                tgtL = o + A @ (np.array([10.5 - 2 * sw, 6.5 + 1.5 * sw, -4.5]) * k)
                RL = self.claw_rot(A, 'L', down=20, inward=15, roll=20)
                self.ub._place_wrist(pose, 'L', tgtL, RL, A @ np.array([-0.2, 1.0, -0.6]))
                c = keys(t, [(0, -0.1), (0.3, -0.5), (0.55, 0.35), (1.0, -0.1)])
                _fingers(pose, float(c), -0.1, -0.3, -0.3, 1.0, 1.0)
            frames.append(pose)
        return frames

    def placeholder(self, crouch):
        """1-frame pose for weapon sequences zombies/bosses never use (names must exist)."""
        if self.st.kind == 'human':
            return self.human_upper('rifle', 'aim', crouch, 0.0, 0.0, 1)
        return self.claw_upper('aim', crouch, 0.0, 0.0, 1)

    # ---------------------------------------------------------------- flinch
    def flinch(self, which, nfr):
        frames = []
        for f in range(nfr):
            t = f / (nfr - 1)
            a = keys(t, [(0, 0), (0.2, 1), (1, 0)])
            if self.st.kind == 'human':
                fr = self.human_upper('rifle', 'aim', False, 0, 0, 1)[0] if False else None
            pose = self.ub.base(False)
            if which == 'head':
                self.ub.torso(pose, 0, 0, extra=np.array([6 * a, -10 * a, 4 * a]), head_extra=(10 * a, -25 * a, 8 * a))
            else:
                self.ub.torso(pose, 0, 0, extra=np.array([-5 * a, 18 * a, -3 * a]), head_extra=(0, 12 * a, 0))
            if self.st.kind == 'human':
                self.ub.hold(pose, 'rifle', 0, 0, kick=dict(back=2 * a, pitch=-10 * a, roll=10 * a))
            else:
                o, A = self.ub.aim_frame(pose, 0, 0)
                for side, sg in (('R', -1), ('L', 1)):
                    tgt = o + A @ (np.array([10.0 - 4 * a, sg * (8.0 + 2 * a), -3.0 - 2 * a]) * self.k)
                    self.ub._place_wrist(pose, side, tgt, self.claw_rot(A, side, down=15 + 40 * a, inward=12),
                                         A @ np.array([-0.3, sg * 1.0, -0.8]))
                _fingers(pose, -0.3 + 0.6 * a, -0.3 + 0.6 * a)
            frames.append(pose)
        return frames

    # ---------------------------------------------------------------- swim
    def swim(self, kind, nfr):
        frames = []
        k = self.k
        for f in range(nfr):
            t = f / (nfr - 1)
            ph = 2 * math.pi * t
            pose = Pose(self.rig)
            if kind == 'swim':
                pose.set_root(np.array([0, 0, -2.0 * k]), ypr(0, 70, 0))
                apply_spine(pose, 0, -10, 0)
                pose.local_rot('Bip01 Neck', ypr(0, -25, 0)); pose.local_rot('Bip01 Head', ypr(0, -30, 0))
                for side, sg in (('L', 1), ('R', -1)):
                    a = math.sin(ph)
                    o, A = chest_frame(pose)
                    tgt = o + A @ (np.array([0.0, sg * (6 + 9 * (1 - a)), 14.0 + 6 * a]) * k)
                    self.ub._place_wrist(pose, side, tgt, A @ ypr(0, 90, sg * 90), A @ np.array([0, sg, 0.2]))
                    kick = math.sin(ph * 2 + (0 if side == 'L' else math.pi))
                    hip = pose.wpos('Bip01 %s Thigh' % side)
                    W = pose.wrot('Bip01 Pelvis')
                    ank = hip + W @ (np.array([4.0 * kick, sg * 1.0, -30.0]) * k)
                    pose.two_bone_ik('Bip01 %s Thigh' % side, 'Bip01 %s Calf' % side, 'Bip01 %s Foot' % side, ank,
                                     W @ np.array([1.0, 0, 0.0]), end_rot=W @ ypr(0, 40, 0))
            else:
                pose.set_root(np.array([0, 0, pose.t[0][2] - 1.0 * k + 0.6 * k * math.sin(ph)]), ypr(0, 4, 0))
                apply_spine(pose, 0, 4, 0)
                o, A = chest_frame(pose)
                for side, sg in (('L', 1), ('R', -1)):
                    a = math.sin(ph + (0 if side == 'L' else 0.5))
                    tgt = o + A @ (np.array([6.0 + 3 * a, sg * 12.0, -10.0]) * k)
                    self.ub._place_wrist(pose, side, tgt, A @ ypr(0, 0, sg * (60 + 30 * a)), A @ np.array([-0.5, sg, -0.5]))
                    kick = math.sin(ph + (0 if side == 'L' else math.pi))
                    hip = pose.wpos('Bip01 %s Thigh' % side)
                    ank = hip + np.array([4.0 * kick * k, sg * 2.0 * k, -26.0 * k + 3 * k * max(0, kick)])
                    pose.two_bone_ik('Bip01 %s Thigh' % side, 'Bip01 %s Calf' % side, 'Bip01 %s Foot' % side, ank,
                                     np.array([1.0, 0, 0]), end_rot=ypr(0, 30, 0))
            frames.append(pose)
        return frames

    # ---------------------------------------------------------------- deaths
    DEATH_CFG = {
        # end orientation (yaw, pitch, roll) via ypr, fall direction (x,y), knee bends (L,R), arms, timing
        'crumple':  dict(end=(150, 90, -20), dirn=(0.3, 0.6), knees=(0.8, 0.9), arms='limp', imp=0.62, kneel=0.5),
        'backward': dict(end=(0, -90, 8), dirn=(-1, 0.1), knees=(0.25, 0.4), arms='spread', imp=0.55, kneel=0.0),
        'forward':  dict(end=(0, 90, -6), dirn=(1, 0), knees=(0.2, 0.35), arms='under', imp=0.6, kneel=0.15),
        'forward2': dict(end=(25, 88, 18), dirn=(1, 0.35), knees=(0.55, 0.2), arms='forward', imp=0.62, kneel=0.3),
        'headshot': dict(end=(-15, -88, -10), dirn=(-1, -0.15), knees=(0.15, 0.3), arms='spread', imp=0.42, kneel=0.0),
        'gut':      dict(end=(-10, 86, -30), dirn=(1, -0.1), knees=(0.9, 0.85), arms='gut', imp=0.75, kneel=0.85),
        'left':     dict(end=(-70, 10, 85), dirn=(0.2, -1), knees=(0.6, 0.3), arms='front', imp=0.58, kneel=0.3),
        'backshot': dict(end=(10, 90, 5), dirn=(1, 0.05), knees=(0.3, 0.25), arms='forward', imp=0.5, kneel=0.0),
        'right':    dict(end=(70, 10, -85), dirn=(0.2, 1), knees=(0.3, 0.6), arms='front', imp=0.58, kneel=0.3),
        'crouch':   dict(end=(-25, 88, -25), dirn=(1, -0.2), knees=(0.8, 0.9), arms='under', imp=0.5, kneel=0.6),
        'chest':    dict(end=(20, -88, 15), dirn=(-1, 0.3), knees=(0.45, 0.2), arms='spread', imp=0.5, kneel=0.1),
    }

    def death(self, kind, nfr):
        k = self.k
        crouch = kind == 'crouch'
        floor = CROUCH_FOOT_Z if crouch else FOOT_Z
        cfg = self.DEATH_CFG[kind]
        boss = self.st.kind == 'boss'
        # --- start pose
        p0 = self.ub.base(crouch)
        if self.st.kind == 'human':
            self.ub.torso(p0, 0, 0, crouch)
            self.ub.hold(p0, 'rifle', 0, 0)
        else:
            self._claw_pose(p0, crouch, 0, 0, 0.0)
        R0 = p0.R[0].copy()
        root0 = p0.t[0].copy()
        Rend = ypr(*cfg['end'])
        dirn = np.array(list(cfg['dirn']) + [0.0]); dirn /= max(np.linalg.norm(dirn), 1e-9)
        feet0 = {s: (p0.wpos('Bip01 %s Foot' % s), p0.wrot('Bip01 %s Foot' % s)) for s in 'LR'}
        hands0 = {s: (p0.wpos('Bip01 %s Hand' % s), p0.wrot('Bip01 %s Hand' % s)) for s in 'LR'}
        imp = cfg['imp']
        face_down = cfg['end'][1] > 45 and abs(cfg['end'][2]) < 60
        frames = []
        for f in range(nfr):
            t = f / (nfr - 1)
            # fall progress: accelerate until impact, small rebound, settle
            if t < imp:
                u = t / imp
                a = u * u * (1.15 - 0.15 * u)
            else:
                u = (t - imp) / (1 - imp)
                a = 1.0 + 0.06 * math.sin(math.pi * min(1, u * 1.6)) * (1 - u)
            a_c = min(a, 1.0)
            kneel = cfg['kneel'] * math.sin(math.pi * min(1.0, t / max(imp, 1e-3)) * 0.5) if cfg['kneel'] else 0.0
            pose = Pose(self.rig)
            R = _slerp_mat(R0, Rend, min(1.0, a * 1.0))
            pose.set_root(root0 + dirn * 12.0 * k * a_c - np.array([0, 0, 6.0 * k * kneel]), R)
            # spine / head
            if kind == 'gut':
                apply_spine(pose, 0, 35 * min(1, t * 2.5) - 15 * a_c, 0)
            elif cfg['end'][1] < 0:   # on the back: arch back then relax
                apply_spine(pose, 8 * a_c, -12 * a_c, 6 * a_c)
            else:
                apply_spine(pose, -10 * a_c, 8 * a_c, -8 * a_c)
            hy = (55 if face_down else 35) * a_c if kind != 'headshot' else 40 * min(1, t * 4)
            if kind == 'headshot':
                hp = -30 * min(1, t * 4) + 10 * a_c
            elif face_down:
                hp = -22 * a_c          # lift the face off the floor, head turned to the side
            else:
                hp = -8 * a_c
            pose.local_rot('Bip01 Neck', ypr(hy * 0.4, hp * 0.4, 10 * a_c))
            pose.local_rot('Bip01 Head', ypr(hy * 0.6, hp * 0.6, 12 * a_c))
            # legs: early -> feet planted where they stood (knees buckle); late -> relaxed lying legs
            W = pose.wrot('Bip01 Pelvis')
            wplant = max(0.0, 1.0 - a * 1.6)
            for side, sg in (('L', 1), ('R', -1)):
                hip = pose.wpos('Bip01 %s Thigh' % side)
                ll = self.gait.leg_len
                bend = cfg['knees'][0 if side == 'L' else 1]
                if face_down:
                    # prone: legs almost straight, heels slightly up (a strong bend would prop the pelvis up)
                    bend = bend * 0.35
                    lyl = hip + W @ np.array([-ll * 0.28 * bend, sg * ll * (0.12 + 0.1 * a_c), -ll * (0.95 - 0.25 * bend)])
                else:
                    lyl = hip + W @ np.array([ll * 0.55 * bend, sg * ll * (0.12 + 0.1 * a_c), -ll * (0.97 - 0.5 * bend)])
                # relaxed legs fall onto the floor
                if a_c > 0.3:
                    zt = floor + self.gait.ankle_h + (pose.t[0][2] - root0[2]) * 0
                    lyl[2] = lyl[2] * (1 - smoothstep(0.3, 1.0, a_c)) + max(floor + self.gait.ankle_h * 0.8, min(lyl[2], hip[2])) * smoothstep(0.3, 1.0, a_c) if False else lyl[2]
                ank = lyl
                if wplant > 0:
                    ank = feet0[side][0] * wplant + lyl * (1 - wplant)
                pose.two_bone_ik('Bip01 %s Thigh' % side, 'Bip01 %s Calf' % side, 'Bip01 %s Foot' % side, ank,
                                 W @ np.array([1.0, sg * 0.25, 0.0]),
                                 end_rot=_slerp_mat(feet0[side][1], W @ ypr(sg * 20, 35, 0), a_c))
            self._tail_flatten(pose, t)
            # ground align: feet carry the body at the start, the torso rests on the floor at the end
            zall = ground_points(pose)[:, 2].min()
            zcore = ground_points(pose, core=True)[:, 2].min()
            wc = smoothstep(0.55, 0.95, a_c)
            fl0 = floor + self.gait.hover_h(crouch) * (1 - smoothstep(0.0, 0.7, a_c))
            pose.t[0] = pose.t[0] + np.array([0, 0, fl0 - (zall * (1 - wc) + zcore * wc)])
            pose.dirty()
            # late phase: drop the feet onto the floor (no legs sticking up in the air)
            dropw = smoothstep(0.5, 1.0, a_c)
            if dropw > 0:
                W = pose.wrot('Bip01 Pelvis')
                for side, sg in (('L', 1), ('R', -1)):
                    ank = pose.wpos('Bip01 %s Foot' % side)
                    ank[2] = ank[2] * (1 - dropw) + (floor + self.gait.ankle_h * 0.9) * dropw
                    pose.two_bone_ik('Bip01 %s Thigh' % side, 'Bip01 %s Calf' % side, 'Bip01 %s Foot' % side, ank,
                                     W @ np.array([1.0, sg * 0.25, 0.0]), end_rot=pose.wrot('Bip01 %s Foot' % side))
            # arms: blend from the weapon hold into a resting placement on the floor
            o, A = chest_frame(pose)
            sh = {s: pose.wpos('Bip01 %s UpperArm' % s) for s in 'LR'}
            for side, sg in (('L', 1), ('R', -1)):
                mode = cfg['arms']
                body_up = A[:, 2]; body_left = A[:, 1]; body_fwd = A[:, 0]
                if mode == 'spread':
                    off = body_left * sg * 16.0 + body_up * (3.0 if side == 'L' else -2.0)
                elif mode == 'forward':
                    off = body_up * (12.0 if side == 'L' else 9.0) + body_left * sg * 8.0
                elif mode == 'under':
                    off = -body_up * 9.0 + body_left * sg * 3.0 + body_fwd * 1.5
                elif mode == 'gut':
                    off = -body_up * 12.0 + body_fwd * 4.0 + body_left * sg * 1.5
                elif mode == 'front':
                    off = body_fwd * 9.0 + body_left * sg * 2.5 - body_up * (2.0 if side == 'L' else 6.0)
                else:
                    off = body_left * sg * 10.0 - body_up * (10.0 if side == 'R' else 4.0)
                tgt = sh[side] + off * k
                # arms come to rest ON the floor
                tgt[2] = tgt[2] * (1 - smoothstep(0.55, 1.0, a_c)) + (floor + 1.8 * k) * smoothstep(0.55, 1.0, a_c)
                w = smoothstep(0.1, 0.85, a)
                start = hands0[side][0] + (pose.t[0] - root0)
                tgt = start * (1 - w) + tgt * w
                Rh = _slerp_mat(hands0[side][1], A @ ypr(sg * 30, 70, sg * 80), float(w))
                pole = A @ np.array([-0.4, sg * 1.0, -0.3]) * (1 - w) + np.array([0, 0, 1.0]) * w
                self.ub._place_wrist(pose, side, tgt, Rh, pole)
                pose.fingers(side, 0.25 * w - (0.35 if self.st.claws else 0) * (1 - w), 0.2 * w)
            # final ground correction (arms may have changed the lowest point; hands may sink slightly)
            pts = ground_points(pose, hands=False, arms=False)
            low = pts[:, 2].min()
            if low < floor:
                pose.t[0] = pose.t[0] + np.array([0, 0, floor - low])
                pose.dirty()
            frames.append(pose)
        return frames

    # ---------------------------------------------------------------- dispatch
    def build(self, sd):
        """Returns (list of blends -> list of Pose, fps, linear movement). Extra bones (tails, wings, user
        extras) are animated after the main generator by _extras()."""
        blends, fps, lm = self._build_raw(sd)
        if any(n.startswith(('Tail', 'Wing_', 'XLimb_')) for n in self.rig.names) or self.st.extra_bone_anim:
            for bl in blends:
                n = len(bl)
                for f, p in enumerate(bl):
                    self._extras(p, sd, f / max(n - 1, 1))
        return blends, fps, lm

    def _extras(self, pose, sd, t):
        rig = self.rig
        tails = [n for n in rig.names if n.startswith('Tail')]
        if tails:
            if sd.kind == 'gait' or sd.kind in ('dummy', 'pad', 'swim'):
                amp = {'walk': 14, 'run': 10, 'crouchrun': 12, 'idle': 6}.get(sd.action, 5)
                for i, nm in enumerate(tails):
                    sw = amp * math.sin(2 * math.pi * (t * (2 if sd.action in ('walk', 'run', 'crouchrun') else 1) - i * 0.18))
                    pose.local_rot(nm, rig.rest_local_rot[rig.index[nm]] @ ypr(sw, 4 + 3 * i, 0))
        self._wings(pose, sd, t)
        self._xlimbs(pose, sd, t)
        if self.st.extra_bone_anim:
            self.st.extra_bone_anim(pose, sd, t, self)

    def _wings(self, pose, sd, t):
        """Wing_<L|R><0..2> (accessories.wing_extras): hover flapping for floaty styles, half-folded
        breathing otherwise, a strong beat in attacks, folded back while swimming / dying."""
        rig = self.rig
        if 'Wing_L0' not in rig.index:
            return
        floaty = self.st.float_h > 0
        w = 2 * math.pi * t
        if sd.kind == 'death':
            fold, lift, amp = 25 + 45 * t, -15 - 25 * t, 4.0 * (1 - t)
        elif sd.kind == 'swim':
            fold, lift, amp = 60.0, -10.0, 4.0
        elif sd.kind == 'upper' and sd.action in ('shoot', 'shoot2'):
            fold, lift, amp = 5.0, 10.0, 38.0
        elif floaty:
            fold, lift, amp = 12.0, 8.0, 26.0
        else:
            fold, lift, amp = 32.0, -6.0, 7.0
        for side, sg in (('L', 1), ('R', -1)):
            a = lift + amp * math.sin(w)
            pose.local_rot('Wing_%s0' % side, ypr(sg * fold, 0, sg * a))
            pose.local_rot('Wing_%s1' % side, ypr(sg * fold * 0.4, 0, sg * (amp * 0.5 * math.sin(w - 0.9) - 4)))
            if 'Wing_%s2' % side in rig.index:
                pose.local_rot('Wing_%s2' % side, ypr(0, 0, sg * amp * 0.3 * math.sin(w - 1.6)))
            if sd.kind == 'death':
                ch = [n for n in ('Wing_%s0' % side, 'Wing_%s1' % side, 'Wing_%s2' % side) if n in rig.index]
                self._flatten_chain(pose, ch, smoothstep(0.35, 0.95, t), down=0.25,
                                    floor=CROUCH_FOOT_Z if sd.crouch else FOOT_Z)

    def _xlimbs(self, pose, sd, t):
        """XLimb_<L|R><n>_<0..2> (accessories.limb_extras): idle sway with per-limb phase, a stab in attacks
        and curling up in deaths."""
        rig = self.rig
        roots = sorted(set(n[:-2] for n in rig.names if n.startswith('XLimb_') and n.endswith('_0')))
        w = 2 * math.pi * t
        for i, base in enumerate(roots):
            sg = 1 if base[6] == 'L' else -1
            ph = i * 1.3
            if sd.kind == 'death':
                c = smoothstep(0.0, 0.8, t)
                r0, p0_, r1 = -25 * c, 10 * c, -70 * c
            elif sd.kind == 'upper' and sd.action in ('shoot', 'shoot2'):
                s_ = float(keys(t, [(0, 0.0), (0.3, -1.0), (0.55, 1.0), (1.0, 0.0)]))
                r0, p0_, r1 = 18 * s_, -25 * s_, -20 * max(s_, 0) + 25 * max(-s_, 0)
            else:
                r0, p0_, r1 = 6 * math.sin(w + ph), 5 * math.sin(w + ph + 1.0), 8 * math.sin(w + ph + 2.0)
            pose.local_rot(base + '_0', ypr(0, p0_, sg * r0))
            pose.local_rot(base + '_1', ypr(0, 0, sg * r1))
            if sd.kind == 'death':
                self._flatten_chain(pose, [n for n in (base + '_0', base + '_1', base + '_2') if n in rig.index],
                                    smoothstep(0.35, 0.95, t), down=0.3,
                                    floor=CROUCH_FOOT_Z if sd.crouch else FOOT_Z)

    def _flatten_chain(self, pose, names, w, down=0.15, lift=0.0, floor=None):
        """Rotate each bone of a chain (in order) so its segment lies (almost) horizontal: used in deaths
        so tails / wings / extra limbs rest on the floor instead of pointing into it or up into the air.
        floor: keep every joint at least ~1 unit above this height."""
        if w <= 0:
            return
        rig = self.rig
        for a, b in zip(names[:-1], names[1:]):
            WR, WT = pose.world()
            ia, ib = rig.index[a], rig.index[b]
            cur = WT[ib] - WT[ia]
            L = np.linalg.norm(cur)
            if L < 1e-6:
                continue
            h = cur.copy(); h[2] = 0.0
            if np.linalg.norm(h) < 0.2 * L:
                h = WR[ia][:, 0].copy(); h[2] = 0.0
                if np.linalg.norm(h) < 1e-6:
                    h = np.array([1.0, 0, 0])
            h /= np.linalg.norm(h)
            tgt = h - np.array([0, 0, down - lift])
            if floor is not None:
                tgt /= np.linalg.norm(tgt)
                dz = float(np.clip(floor + 1.0 * self.k - WT[ia][2], tgt[2] * L, 0.6 * L)) / L
                tgt = h * math.sqrt(max(1.0 - dz * dz, 0.0)) + np.array([0, 0, dz])
            Rw = rot_between(cur / L, tgt / np.linalg.norm(tgt)) @ WR[ia]
            pose.set_world_rot(a, _slerp_mat(WR[ia], Rw, w))

    def _tail_flatten(self, pose, t):
        rig = self.rig
        tails = [n for n in rig.names if n.startswith('Tail')]
        if len(tails) < 2:
            return
        self._flatten_chain(pose, tails, smoothstep(0.25, 0.9, t), down=0.08)   # floor handled by ground align

    def _build_raw(self, sd):
        st = self.st
        lm = 0.0
        if sd.kind == 'dummy' or sd.kind == 'pad':
            p = Pose(self.rig)
            self.gait.standing(p)
            return [[p]], 10.0, 0.0
        if sd.kind == 'gait':
            a = sd.action
            if a == 'idle':
                frs = []
                n = 16
                for f in range(n):
                    p = Pose(self.rig)
                    if st.float_h > 0:   # hovering: the whole body bobs up and down
                        self.gait.standing(p, hover=-1.4 * self.k * (1 - math.cos(2 * math.pi * f / (n - 1))) / 2)
                    else:
                        self.gait.standing(p, bob=0.25 * self.k * (1 - math.cos(2 * math.pi * f / (n - 1))) / 2)
                    frs.append(p)
                return [frs], 8.0, 0.0
            if a == 'crouch_idle':
                p = Pose(self.rig)
                self.gait.standing(p, crouch=True)
                return [[p]], 10.0, 0.0
            if a in ('walk', 'run', 'crouchrun'):
                n = {'walk': 31, 'run': 23, 'crouchrun': 31}[a]
                frs, lm = self.gait.cycle(a, n)
                return [frs], 30.0, lm
            if a in ('jump', 'longjump'):
                return [self.gait.jump(20, long=(a == 'longjump'))], 30.0, 0.0
        if sd.kind == 'swim':
            return [self.swim(sd.action, 25)], 18.0, 0.0
        if sd.kind == 'flinch':
            return [self.flinch(sd.action, 6)], 20.0, 0.0
        if sd.kind == 'death':
            n = 24 if st.kind != 'boss' else 28
            return [self.death(sd.action, n)], 20.0 if st.kind != 'boss' else 16.0, 0.0
        if sd.kind == 'upper':
            nine = sd.nine
            if st.kind == 'human':
                nfr, fps = {'aim': (1, 10.0), 'shoot': (5, 24.0), 'shoot2': (5, 24.0), 'reload': (15, 6.0)}[sd.action]
                if sd.ext in STATIC_EXTS:
                    # shields / c4 are not used in the zombie mod: every action = the aim pose (identical
                    # data is shared by mdl_opt.dedupe_animations, so these cost almost nothing)
                    nfr, fps = 1, 10.0
                    gen = lambda y, p: self.human_upper(sd.ext, 'aim', sd.crouch, y, p, 1)
                    blends = [gen(YAWS[c], PITCHES[r]) for r in range(3) for c in range(3)] if nine else [gen(0.0, 0.0)]
                    return blends, fps, 0.0
                if sd.ext in ('knife', 'shieldknife') and sd.action == 'shoot':
                    nfr, fps = 8, 24.0
                if sd.ext in ('grenade', 'shieldgren') and sd.action == 'shoot':
                    nfr, fps = 10, 20.0
                if sd.ext == 'shotgun' and sd.action == 'shoot':
                    nfr, fps = 8, 12.0
                if sd.ext == 'shotgun' and sd.action == 'reload':
                    nfr, fps = 17, 6.0
                gen = lambda y, p: self.human_upper(sd.ext, sd.action, sd.crouch, y, p, nfr)
            else:
                if sd.ext == 'knife':
                    nfr, fps = {'aim': (13, 8.0), 'shoot': (11, 24.0)}.get(sd.action, (1, 10.0))
                    gen = lambda y, p: self.claw_upper(sd.action, sd.crouch, y, p, nfr)
                else:
                    return [self.placeholder(sd.crouch)], 10.0, 0.0
            if not nine:
                return [gen(0.0, 0.0)], fps, 0.0
            blends = []
            for row in range(3):
                for col in range(3):
                    blends.append(gen(YAWS[col], PITCHES[row]))
            return blends, fps, 0.0
        raise ValueError(sd.kind)


STATIC_EXTS = {'shieldgun', 'shieldknife', 'shieldgren', 'shielded', 'shield', 'c4'}

GAIT_SET_NAMES = {'Bip01', 'Bip01 Pelvis', 'Bip01 L Thigh', 'Bip01 L Calf', 'Bip01 L Foot', 'Bip01 L Toe0',
                  'Bip01 R Thigh', 'Bip01 R Calf', 'Bip01 R Foot', 'Bip01 R Toe0'}


def _slerp_mat(A, B, t):
    from .pose import mat_to_quat_v
    from .mathx import quaternion_slerp, quaternion_matrix
    qa = mat_to_quat_v(A[None])[0]; qb = mat_to_quat_v(B[None])[0]
    return quaternion_matrix(quaternion_slerp(qa, qb, t))


# ------------------------------------------------------------------------------------------ export

def export_sequences(rig, style, workdir, nine_exts=None, prefix='', events=None, only=None, progress=False):
    """Write every sequence SMD into workdir and return list of qc.Sequence (ordered).
    nine_exts: None = all upper-body sequences 9-blend (humans); for zombies pass {'knife'}."""
    table = sequence_table(nine_exts)
    ab = AnimBuilder(rig, style, nine_exts)
    bones = rig.bones_for_smd()
    seqs = []
    cache = {}
    for i, sd in enumerate(table):
        if only is not None and sd.name not in only:
            continue
        blends, fps, lm = ab.build(sd)
        names = []
        gait_set = [i for i, n in enumerate(rig.names) if n in GAIT_SET_NAMES or rig.parents[i] == 1 or
                    (i < rig.index['Bip01 Spine'])]
        for bi, frames in enumerate(blends):
            fn = '%sa_%s%s' % (prefix, sd.name, ('_b%d' % bi) if len(blends) > 1 else '')
            fr = [p.to_frame() for p in frames]
            if sd.kind in ('upper', 'flinch'):
                # the engine replaces these bones with the gait -> store the rest values (zero anim data)
                for frm in fr:
                    for gi in gait_set:
                        if gi < rig.index['Bip01 Spine'] or rig.names[gi] in GAIT_SET_NAMES:
                            frm[gi] = (rig.rest_local_pos[gi].copy(), rig.rest_local_rot[gi].copy())
            if lm:
                # add linear motion to the root so studiomdl's LX extraction recovers lm exactly
                N = len(fr)
                for f in range(N):
                    pos, R = fr[f][0]
                    fr[f][0] = (pos + np.array([lm * f / (N - 1), 0, 0]), R)
            write_animation(os.path.join(workdir, fn + '.smd'), bones, fr)
            names.append(fn)
        ev = (events or {}).get(sd.name)
        seqs.append(Sequence(sd.name, names, fps=fps, loop=sd.loop, activity=sd.activity,
                             motion=sd.motion, events=ev))
        if progress:
            print('  seq %3d %-26s blends=%d frames=%d' % (i, sd.name, len(blends), len(blends[0])))
    return seqs, table
