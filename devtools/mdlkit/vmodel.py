"""First-person view models (v_): claws and CT weapons.

VIEW SPACE (verified with preview.render_viewmodel, which mirrors V_CalcRefdef): the model origin is the
camera (eye) position, +X = view direction, +Y = left, +Z = up; CS default fov 90 (4:3). Everything must
stay in front of the near plane (~4 units).

Sequence order = ReGameDLL weapon enums (weapons.h), e.g. knife_e: IDLE, ATTACK1HIT, ATTACK2HIT, DRAW,
STABHIT, STABMISS, MIDATTACK1HIT, MIDATTACK2HIT. See WEAPON_SETS.

Rig: the CS biped (rig_cs) with arms only (unused bones are dropped by studiomdl) + weapon bones:
    v_weapon (child of Bip01 R Hand, frame = grip frame, origin = grip centre)
    v_mag    (child of v_weapon)  magazine / shell
    v_slide  (child of v_weapon)  slide / bolt / pump
Events: 5001 muzzle flash (options e.g. "20" = scale 2, sprite 0) at frame 0 of shoot sequences with
attachment 0 at the muzzle; 5004 client sounds (stock CS paths) on reload/draw frames.
"""
import math
import os
import numpy as np

from .rig_cs import Rig, RigSpec, grip_rest_rot, GRIP_R, GRIP_L, grip_offset
from .pose import Pose
from .mathx import rot_x, rot_y, rot_z, axis_angle
from .anims import ypr, keys, _slerp_mat, support_rot_for_fore
from .geom import pack_atlas, Mesh
from .qc import QC, Sequence
from .smd import write_reference, write_animation
from .body import face_anchor

# name, motion, frames, fps, loop
WEAPON_SETS = {
    'knife': [('idle', 'idle', 31, 15, True), ('slash1', 'slash_r', 13, 30, False), ('slash2', 'slash_l', 13, 30, False),
              ('draw', 'draw', 16, 24, False), ('stab', 'stab', 25, 25, False), ('stab_miss', 'stab', 25, 25, False),
              ('midslash1', 'mid_r', 11, 30, False), ('midslash2', 'mid_l', 11, 30, False)],
    'grenade': [('idle', 'idle', 31, 15, True), ('pullpin', 'pullpin', 16, 24, False), ('throw', 'throw', 14, 30, False),
                ('draw', 'draw', 14, 24, False)],
    'ak47': [('idle1', 'idle', 31, 15, True), ('reload', 'reload', 31, 12, False), ('draw', 'draw', 14, 24, False),
             ('shoot1', 'shoot', 7, 30, False), ('shoot2', 'shoot', 7, 30, False), ('shoot3', 'shoot', 7, 30, False)],
    'p90': [('idle1', 'idle', 31, 15, True), ('reload', 'reload', 33, 10, False), ('draw', 'draw', 14, 24, False),
            ('shoot1', 'shoot', 7, 30, False), ('shoot2', 'shoot', 7, 30, False), ('shoot3', 'shoot', 7, 30, False)],
    'm4a1': [('idle', 'idle', 31, 15, True), ('shoot1', 'shoot', 7, 30, False), ('shoot2', 'shoot', 7, 30, False),
             ('shoot3', 'shoot', 7, 30, False), ('reload', 'reload', 31, 10, False), ('draw', 'draw', 14, 24, False),
             ('add_silencer', 'attach', 25, 12, False), ('idle_unsil', 'idle', 31, 15, True),
             ('shoot1_unsil', 'shoot', 7, 30, False), ('shoot2_unsil', 'shoot', 7, 30, False),
             ('shoot3_unsil', 'shoot', 7, 30, False), ('reload_unsil', 'reload', 31, 10, False),
             ('draw_unsil', 'draw', 14, 24, False), ('detach_silencer', 'detach', 25, 12, False)],
    'm249': [('idle1', 'idle', 31, 15, True), ('shoot1', 'shoot', 7, 30, False), ('shoot2', 'shoot', 7, 30, False),
             ('reload', 'reload_box', 41, 8, False), ('draw', 'draw', 14, 24, False)],
    'awp': [('idle', 'idle', 31, 15, True), ('shoot', 'shoot_bolt', 25, 18, False), ('shoot2', 'shoot_bolt', 25, 18, False),
            ('shoot3', 'shoot_bolt', 25, 18, False), ('reload', 'reload', 31, 10, False), ('draw', 'draw', 14, 24, False)],
    'xm1014': [('idle', 'idle', 31, 15, True), ('fire1', 'shoot', 9, 30, False), ('fire2', 'shoot', 9, 30, False),
               ('reload', 'insert', 11, 20, False), ('after_reload', 'pump', 13, 24, False),
               ('start_reload', 'start_reload', 11, 24, False), ('draw', 'draw', 14, 24, False)],
    'deagle': [('idle1', 'idle', 31, 15, True), ('shoot1', 'shoot_pistol', 9, 30, False),
               ('shoot2', 'shoot_pistol', 9, 30, False), ('shoot_empty', 'shoot_pistol', 9, 30, False),
               ('reload', 'reload_pistol', 25, 12, False), ('draw', 'draw', 14, 24, False)],
    'sg550': [('idle', 'idle', 31, 15, True), ('shoot', 'shoot', 7, 30, False), ('shoot2', 'shoot', 7, 30, False),
              ('reload', 'reload', 31, 10, False), ('draw', 'draw', 14, 24, False)],
}
WEAPON_SETS['hegrenade'] = WEAPON_SETS['flashbang'] = WEAPON_SETS['smokegrenade'] = WEAPON_SETS['grenade']

# stock CS 1.6 sounds for 5004 events: motion -> list of (fraction of the sequence, sound)
STOCK_SOUNDS = {
    'ak47': {'reload': [(0.25, 'weapons/ak47_clipout.wav'), (0.62, 'weapons/ak47_clipin.wav'), (0.85, 'weapons/ak47_boltpull.wav')]},
    'm4a1': {'reload': [(0.25, 'weapons/m4a1_clipout.wav'), (0.62, 'weapons/m4a1_clipin.wav'), (0.85, 'weapons/m4a1_boltpull.wav')],
             'draw': [(0.3, 'weapons/m4a1_deploy.wav')], 'attach': [(0.6, 'weapons/m4a1_silencer_on.wav')],
             'detach': [(0.4, 'weapons/m4a1_silencer_off.wav')]},
    'sg550': {'reload': [(0.25, 'weapons/sg550_clipout.wav'), (0.62, 'weapons/sg550_clipin.wav'), (0.85, 'weapons/sg550_boltpull.wav')]},
    'p90': {'reload': [(0.2, 'weapons/p90_cliprelease.wav'), (0.3, 'weapons/p90_clipout.wav'), (0.62, 'weapons/p90_clipin.wav'),
                       (0.85, 'weapons/p90_boltpull.wav')]},
    'm249': {'reload_box': [(0.12, 'weapons/m249_coverup.wav'), (0.3, 'weapons/m249_boxout.wav'), (0.55, 'weapons/m249_boxin.wav'),
                            (0.7, 'weapons/m249_chain.wav'), (0.85, 'weapons/m249_coverdown.wav')]},
    'awp': {'reload': [(0.25, 'weapons/awp_clipout.wav'), (0.62, 'weapons/awp_clipin.wav')],
            'shoot_bolt': [(0.45, 'weapons/boltpull1.wav')], 'draw': [(0.4, 'weapons/awp_deploy.wav')]},
    'xm1014': {'insert': [(0.5, 'weapons/m3_insertshell.wav')], 'pump': [(0.4, 'weapons/m3_pump.wav')]},
    'deagle': {'reload_pistol': [(0.25, 'weapons/de_clipout.wav'), (0.6, 'weapons/de_clipin.wav')],
               'draw': [(0.4, 'weapons/de_deploy.wav')]},
    'knife': {'draw': [(0.05, 'weapons/knife_deploy1.wav')]},
    'grenade': {'pullpin': [(0.5, 'weapons/pinpull.wav')]},
}
STOCK_SOUNDS['hegrenade'] = STOCK_SOUNDS['flashbang'] = STOCK_SOUNDS['smokegrenade'] = STOCK_SOUNDS['grenade']

MUZZLE = {'ak47': '30', 'm4a1': '20', 'sg550': '20', 'p90': '10', 'm249': '30', 'awp': '30', 'xm1014': '30',
          'deagle': '20'}

# grip pose (gun frame origin in view space, yaw/pitch/roll of the gun) per weapon family
VIEW_HOLD = {
    # grip = gun-frame origin (grip centre) in view space, rot = (yaw, pitch, roll) of the gun: roll > 0 cants
    # the top to the right so the left side faces the camera (classic CS staging); scale = gun mesh scale
    # (v_ guns are drawn ~1.3x larger than p_ guns); fore/fore_z = support-hand point (unscaled gun units)
    'rifle': dict(grip=(9.5, -6.4, -7.6), rot=(6.0, -2.0, 26.0), fore=9.0, fore_z=1.9, scale=1.3),
    'lmg': dict(grip=(9.0, -6.6, -8.4), rot=(5.0, -1.5, 22.0), fore=9.0, fore_z=1.9, scale=1.25),
    'sniper': dict(grip=(9.5, -6.4, -7.8), rot=(6.0, -2.0, 24.0), fore=9.0, fore_z=1.9, scale=1.25),
    'smg': dict(grip=(9.0, -5.8, -7.2), rot=(7.0, -3.0, 24.0), fore=6.5, fore_z=1.9, scale=1.3),
    'shotgun': dict(grip=(9.5, -6.2, -7.6), rot=(6.0, -2.0, 24.0), fore=9.3, fore_z=1.5, scale=1.25),
    'pistol': dict(grip=(11.0, -4.6, -6.4), rot=(6.0, -6.0, 18.0), fore=None, scale=1.35),
    'knife': dict(grip=(9.0, -6.2, -6.6), rot=(15.0, -30.0, -15.0), fore=None, scale=1.2),
    'grenade': dict(grip=(10.5, -5.0, -5.6), rot=(15.0, -25.0, 10.0), fore=None, scale=1.3),
}
FAMILY = {'ak47': 'rifle', 'm4a1': 'rifle', 'sg550': 'sniper', 'awp': 'sniper', 'p90': 'smg', 'm249': 'lmg',
          'xm1014': 'shotgun', 'deagle': 'pistol', 'knife': 'knife', 'hegrenade': 'grenade', 'flashbang': 'grenade',
          'smokegrenade': 'grenade', 'grenade': 'grenade'}

ARM_PREFIX = ('arm_', 'hand_', 'finger', 'fingers_', 'thumb', 'claw', 'thumbclaw', 'bracer', 'wrap', 'cuff', 'sleeve')


class ViewRig:
    def __init__(self, spec_rig=None, weapon=True):
        rs = spec_rig if isinstance(spec_rig, RigSpec) else RigSpec(**(spec_rig or {})) if isinstance(spec_rig, dict) else RigSpec()
        base = Rig(rs)
        extras = list(rs.extras)
        if weapon:
            G = grip_rest_rot()
            wr = base.J('Bip01 R Hand')
            gp = wr + G @ grip_offset(base, 'R')
            extras += [dict(name='v_weapon', parent='Bip01 R Hand', pos=gp, rot=G),
                       dict(name='v_mag', parent='v_weapon', pos=gp + G @ np.array([2.6, 0, 1.0]), rot=G),
                       dict(name='v_slide', parent='v_weapon', pos=gp + G @ np.array([0.0, 0, 2.4]), rot=G)]
        rs2 = RigSpec(**{k: v for k, v in rs.__dict__.items() if k != 'extras'})
        rs2.extras = extras
        self.rig = Rig(rs2)
        self.weapon = weapon


def view_arm_meshes(spec, rig):
    """Body + accessories of a character spec, keeping only meshes on arm/hand bones."""
    from .characters import assemble
    meshes, materials, decals, extra = assemble(rig, spec)
    arm_bones = set(i for i, n in enumerate(rig.names) if any(s in n for s in ('UpperArm', 'Forearm', 'Hand', 'Finger')))
    keep = []
    for m in meshes:
        if np.all(np.isin(m.bone, list(arm_bones))) or m.name.startswith(ARM_PREFIX):
            if not np.all(np.isin(m.bone, list(arm_bones))):
                continue
            keep.append(m)
    return keep, materials, decals, extra


class ViewAnim:
    """Generates view-space poses. Root placement: the rig is moved so its eyes are at the origin and the
    shoulders sit `shoulder_drop` lower / `shoulder_out` wider (classic v_ staging)."""

    def __init__(self, rig, sh, kind='knife', claws=False, style=None):
        self.rig = rig
        self.k = rig.H / 72.0
        fa = face_anchor(rig, sh)
        self.eye = (fa['eye_L'] + fa['eye_R']) / 2
        self.kind = kind
        self.fam = FAMILY.get(kind, 'rifle')
        self.claws = claws
        self.st = style or {}
        self.drop = self.st.get('shoulder_drop', 3.0)
        self.out_ = self.st.get('shoulder_out', 1.0)

    def base(self):
        p = Pose(self.rig)
        # place the whole skeleton so that the eye is at the origin (scaled rigs: keep arms near camera)
        root = -self.eye + self.rig.rest_world[0] + np.array([-1.0, 0, -self.drop])
        p.set_root(root, np.eye(3))
        # spread the clavicles a little so upper arms come from the screen corners
        for side, sg in (('L', 1), ('R', -1)):
            p.local_rot('Bip01 %s Clavicle' % side, ypr(sg * 4, 0, sg * -6 * self.out_))
        return p

    def place(self, p, side, wrist_or_grip, R, pole, is_grip=True):
        sg = 1 if side == 'L' else -1
        if is_grip:
            wrist = wrist_or_grip - R @ grip_offset(self.rig, side)
        else:
            wrist = wrist_or_grip
        p.two_bone_ik('Bip01 %s UpperArm' % side, 'Bip01 %s Forearm' % side, 'Bip01 %s Hand' % side, wrist,
                      pole if pole is not None else np.array([-0.3, sg * 1.0, -0.8]), end_rot=R)

    # ------------------------------------------------------------------ claws
    def claw_R(self, A_down=15, inward=12, roll=20, side='R'):
        sg = 1 if side == 'L' else -1
        base = rot_x(-math.pi / 2) if side == 'R' else rot_x(math.pi / 2)
        return ypr(-sg * inward, A_down, -sg * roll) @ base

    def claws_pose(self, motion, t):
        k = self.k * self.st.get('claw_scale', 1.0)
        p = self.base()
        br = math.sin(2 * math.pi * t)
        restR = np.array([12.5, -8.0, -6.6])
        restL = np.array([12.5, 8.0, -6.6])
        pR, pL = restR.copy(), restL.copy()
        dR, iR, dL, iL = 6.0, 22.0, 6.0, 22.0
        cR = cL = -0.15
        if motion == 'idle':
            pR = restR + np.array([0.4 * br, 0.3 * br, 0.5 * br])
            pL = restL + np.array([-0.4 * br, -0.3 * br, 0.5 * -br])
            cR = -0.15 + 0.12 * br; cL = -0.15 - 0.12 * br
        elif motion == 'draw':
            u = keys(t, [(0, 1.0), (0.7, -0.08), (1.0, 0.0)])
            pR = restR + np.array([-6.0, -4.0, -14.0]) * u
            pL = restL + np.array([-6.0, 4.0, -14.0]) * u
            dR = dL = 18 + 40 * u
            cR = cL = keys(t, [(0, 0.4), (0.6, -0.5), (1.0, -0.15)])
        elif motion in ('slash_r', 'slash_l', 'mid_r', 'mid_l'):
            right = motion.endswith('_r')
            mid = motion.startswith('mid')
            if mid:
                ks = [(0, 0.0), (0.25, -1.0), (0.55, 1.0), (1.0, 0.0)]
            else:
                ks = [(0, 0.0), (0.3, -1.0), (0.55, 1.0), (0.75, 0.8), (1.0, 0.0)]
            s = float(keys(t, ks))
            if mid:   # horizontal slash across the view
                wind = np.array([12.0, -16.0, -6.0]); hit = np.array([19.0, 6.0, -7.5])
            else:     # diagonal: up-outside -> down-inside
                wind = np.array([10.0, -15.0, 1.0]); hit = np.array([19.0, 5.0, -12.0])
            path = keys(t, [(0, restR), (ks[1][0], wind), (ks[2][0], hit), (1.0, restR)])
            dd = keys(t, [(0, 18.0), (ks[1][0], -55.0 if not mid else -10.0), (ks[2][0], 35.0), (1.0, 18.0)])
            ii = keys(t, [(0, 15.0), (ks[1][0], -25.0), (ks[2][0], 55.0), (1.0, 15.0)])
            cc = keys(t, [(0, -0.15), (ks[1][0], -0.55), (ks[2][0], 0.35), (1.0, -0.15)])
            other = (restL if right else restR) + np.array([-1.5 * abs(s), 0, -1.5 * abs(s)])
            if right:
                pR, dR, iR, cR = path, float(dd), float(ii), float(cc)
                pL = other
            else:
                pL = path * np.array([1, -1, 1])
                dL, iL, cL = float(dd), float(ii), float(cc)
                pR = other
        elif motion == 'stab':
            u = float(keys(t, [(0, 0.0), (0.3, -0.6), (0.5, 1.0), (0.7, 0.9), (1.0, 0.0)]))
            pR = restR + np.array([10.0 * u, 5.0 * max(u, 0), 3.0 * max(u, 0)])
            pL = restL + np.array([10.0 * u, -5.0 * max(u, 0), 3.0 * max(u, 0)])
            dR = dL = 18 - 25 * max(u, 0) + 30 * max(-u, 0)
            iR = iL = 15 + 10 * max(u, 0)
            cR = cL = -0.15 + 0.5 * max(u, 0) - 0.4 * max(-u, 0)
        self.place(p, 'R', pR * k, self.claw_R(dR, iR, 20, 'R'), np.array([-0.4, -1.0, -0.7]), is_grip=False)
        self.place(p, 'L', pL * k, self.claw_R(dL, iL, 20, 'L'), np.array([-0.4, 1.0, -0.7]), is_grip=False)
        p.fingers('R', cR, 0.0, 1.0)
        p.fingers('L', cL, 0.0, 1.0)
        return p

    # ------------------------------------------------------------------ guns (generic)
    def gun_pose(self, motion, t):
        h = dict(VIEW_HOLD[self.fam], **(self.st.get('hold') or {}))
        p = self.base()
        k = self.k
        gp = np.array(h['grip'])
        yaw, pit, roll = h['rot']
        mag_off = np.zeros(3)
        slide_off = np.zeros(3)
        lhand = None
        br = math.sin(2 * math.pi * t)
        if motion == 'idle':
            gp = gp + np.array([0, 0.1 * br, 0.15 * br])
        elif motion in ('shoot', 'shoot_pistol', 'shoot_bolt'):
            a = float(keys(t, [(0, 0), (0.15, 1), (0.6, 0.25), (1, 0)])) if motion != 'shoot_bolt' else float(keys(t, [(0, 0), (0.06, 1), (0.3, 0.2), (1, 0)]))
            gp = gp + np.array([-1.4 * a, 0, 0.35 * a])
            pit -= 6 * a
            if motion == 'shoot_pistol':
                slide_off = np.array([-1.2 * float(keys(t, [(0, 0), (0.1, 1), (0.35, 0)])), 0, 0])
            if motion == 'shoot_bolt':
                b = float(keys(t, [(0, 0), (0.3, 0), (0.45, 1), (0.6, 1), (0.75, 0), (1, 0)]))
                slide_off = np.array([-2.6 * b, 0, 0])
                roll += 12 * b
        elif motion == 'draw':
            u = float(keys(t, [(0, 1), (0.75, -0.04), (1, 0)]))
            gp = gp + np.array([-4.0, -3.0, -10.0]) * u
            pit += 35 * u; roll += 25 * u
        elif motion in ('reload', 'reload_pistol', 'reload_box'):
            tilt = float(keys(t, [(0, 0), (0.12, 1), (0.85, 1), (1, 0)]))
            gp = gp + np.array([-1.5, 2.0, 1.0]) * tilt
            roll -= 25 * tilt; pit += 10 * tilt; yaw += 10 * tilt
            m = float(keys(t, [(0, 0), (0.25, 0), (0.35, 1), (0.55, 1), (0.66, 0), (1, 0)]))
            mag_off = np.array([0.5, 0, -6.0]) * m
        elif motion in ('attach', 'detach'):
            u = float(keys(t, [(0, 0), (0.2, 1), (0.8, 1), (1, 0)]))
            gp = gp + np.array([-1.0, 2.5, 0.5]) * u
            yaw += 15 * u
        elif motion in ('insert', 'start_reload', 'pump'):
            u = float(keys(t, [(0, 0), (0.5, 1), (1, 0)]))
            roll -= 15 * (motion != 'pump')
            if motion == 'pump':
                slide_off = np.array([-2.5 * u, 0, 0])
        elif motion in ('slash_r', 'slash_l', 'mid_r', 'mid_l', 'stab') and self.fam == 'knife':
            if motion == 'stab':
                u = float(keys(t, [(0, 0), (0.3, -0.7), (0.5, 1.0), (0.7, 0.9), (1, 0)]))
                gp = gp + np.array([8.0 * u, 3.0 * max(u, 0), 3.5 * max(u, 0) + 2.0 * max(-u, 0)])
                pit -= 25 * max(u, 0) - 20 * max(-u, 0)
            else:
                back = motion.endswith('_l')
                mid = motion.startswith('mid')
                s_ = float(keys(t, [(0, 0), (0.28, -1), (0.55, 1), (0.8, 0.7), (1, 0)]))
                if back:
                    s_ = -s_
                gp = gp + np.array([4.0 * (1 - abs(s_)) + 3.0, 7.0 * s_, (1.0 if mid else 4.0) * -s_])
                yaw += 45 * s_
                roll += (25 if mid else 60) * s_
                pit += (5 if mid else 25) * s_
        elif motion == 'pullpin':
            u = float(keys(t, [(0, 0), (0.5, 1), (1, 1)]))
            gp = gp + np.array([0, 2.0, 1.0]) * u
        elif motion == 'throw':
            u = float(keys(t, [(0, 0), (0.35, -1), (0.6, 1), (1, 1.2)]))
            gp = gp + np.array([4.0 * u, 3.0 * max(u, 0), 4.0 * -min(u, 0) - 6 * max(u - 0.8, 0)])
            pit += 40 * min(u, 0) + 30 * max(u, 0)
        G = ypr(yaw, pit, roll)
        grip = gp * k
        self.place(p, 'R', grip, G, np.array([-0.3, -1.0, -0.9]))
        # support hand
        gs = self.st.get('gun_scale', h.get('scale', 1.0))
        if h.get('fore'):
            fp = grip + G @ np.array([h['fore'] * k * gs, 0, h['fore_z'] * k * gs])
            RL = support_rot_for_fore(G)
            if motion in ('reload', 'reload_box'):
                mw = grip + G @ (np.array([2.8, 0, -4.0]) + mag_off) * k
                pouch = np.array([6.0, 4.0, -22.0]) * k
                tgt = keys(t, [(0, fp), (0.2, mw), (0.36, mw + np.array([0, 0, -4.0 * k])), (0.48, pouch),
                               (0.6, mw + np.array([0, 0, -3.0 * k])), (0.7, mw), (0.85, fp), (1, fp)])
                RLm = G @ ypr(-80, 0, 70)
                w = float(keys(t, [(0, 0), (0.15, 1), (0.8, 1), (1, 0)]))
                RL = _slerp_mat(RL, RLm, w)
                fp = tgt
            elif motion == 'pump' or motion == 'insert' or motion == 'start_reload':
                if motion == 'pump':
                    fp = fp + G @ slide_off * k
                else:
                    u = float(keys(t, [(0, 0), (0.5, 1), (1, 0)]))
                    fp = keys(t, [(0, fp), (0.5, grip + G @ np.array([2.5, 0, -3.5]) * k), (1, fp)])
            self.place(p, 'L', fp, RL, np.array([-0.2, 1.0, -0.9]))
        else:
            # pistols: support hand cups the grip; knife/grenade: left hand lower-left, mostly hidden
            if self.fam == 'pistol':
                wR = p.wpos('Bip01 R Hand')
                RL = G @ ypr(0, 0, -30)
                tgt = wR + G @ np.array([-0.4, 2.6, -2.2]) * k
                if motion == 'reload_pistol':
                    tgt = keys(t, [(0, tgt), (0.25, grip + G @ np.array([0, 2.5, -6.0]) * k),
                                   (0.45, np.array([6, 6, -20.0]) * k), (0.6, grip + G @ np.array([0, 2.5, -6.0]) * k),
                                   (1.0, tgt)])
                self.place(p, 'L', tgt, RL, np.array([-0.3, 1.0, -0.9]), is_grip=False)
            else:
                self.place(p, 'L', np.array([10.0, 9.0, -14.0]) * k, ypr(-30, 20, 60), np.array([-0.3, 1.0, -0.9]),
                           is_grip=False)
        if self.rig.index.get('v_mag') is not None:
            i = self.rig.index['v_mag']
            p.t[i] = self.rig.rest_local_pos[i] + mag_off * k
            j = self.rig.index['v_slide']
            p.t[j] = self.rig.rest_local_pos[j] + slide_off * k
            p.dirty()
        p.fingers('R', 0.0)
        p.fingers('L', 0.0)
        return p

    def frames(self, motion, n):
        out = []
        for f in range(n):
            t = f / max(n - 1, 1)
            out.append(self.claws_pose(motion, t) if self.claws else self.gun_pose(motion, t))
        return out


def build_vmodel(name, arms_spec, kind='knife', gun_meshes=None, out=None, claws=False, tex=(256, 256),
                 materials=None, sounds=None, muzzle=None, preview=True, style=None, budget=0.4e6):
    """Compile a v_ model.
    arms_spec: character spec whose arms/hands/sleeves are used (same materials as the player model).
    kind: weapon set key (WEAPON_SETS) -> sequence order/timing; claws=True uses the claw motion set.
    gun_meshes: meshes in GUN SPACE (pmodel.gun_preset) bound to v_weapon; meshes named 'mag*' bind to v_mag,
    'slide*'/'pump*' to v_slide."""
    from . import CSTRIKE, PREVIEW_DIR
    from .api import _workdir, write_textures
    from .paint import bake_textures
    from .compile import run_studiomdl
    from .mdl_opt import dedupe_animations
    from .pmodel import GUN_MATERIALS, muzzle_point
    from .body import _merge_shape
    wd = _workdir(name)
    vr = ViewRig(arms_spec.get('rig'), weapon=gun_meshes is not None)
    rig = vr.rig
    arm_meshes, mats, decals, extra = view_arm_meshes(arms_spec, rig)
    mats = dict(mats)
    mats.update(GUN_MATERIALS)
    mats.update(materials or {})
    meshes = list(arm_meshes)
    if gun_meshes is not None:
        wi = rig.index['v_weapon']
        G = rig.rest_rot_world[wi]
        o = rig.rest_world[wi]
        gs = (style or {}).get('gun_scale', VIEW_HOLD[FAMILY.get(kind, 'rifle')].get('scale', 1.0))
        for gm in gun_meshes:
            m = gm.copy()
            m.v = (m.v * gs) @ G.T + o
            m.n = m.n @ G.T
            nm = m.name or ''
            b = 'v_mag' if nm.startswith('mag') else ('v_slide' if nm.startswith(('slide', 'pump')) else 'v_weapon')
            m.set_bone(rig.index[b])
            meshes.append(m)
    pages = pack_atlas(meshes, tex[0], tex[1], 1, tex_prefix=name[:12] + '_')
    baked = bake_textures(meshes, pages, mats, decals, ao=True, ao_dirs=24)
    write_textures(wd, baked, dither=4.0)
    bones = rig.bones_for_smd()
    from .api import uv_span_meshes
    hb = rig.index['Bip01 R Hand']
    write_reference(os.path.join(wd, 'ref.smd'), bones, rig.rest_local(),
                    uv_span_meshes(pages, hb, rig.rest_world[hb]) + meshes)
    sh = extra.get('shape') or _merge_shape(arms_spec.get('shape'))
    va = ViewAnim(rig, sh, kind, claws=claws, style=style)
    q = QC(name + '.mdl')
    q.body('arms', 'ref')
    if gun_meshes is not None:
        wi = rig.index['v_weapon']
        mz = muzzle_point(gun_meshes) * gs
        q.attachment(0, 'v_weapon', mz)
    else:
        q.attachment(0, 'Bip01 R Hand', grip_offset(rig, 'R') + np.array([6.0, 0, 0]))
    snd = dict(STOCK_SOUNDS.get(kind, {}))
    snd.update(sounds or {})
    for sname, motion, n, fps, loop in WEAPON_SETS[kind]:
        frames = va.frames(motion, n)
        fn = 'v_' + sname
        write_animation(os.path.join(wd, fn + '.smd'), bones, [p.to_frame() for p in frames])
        ev = []
        if motion.startswith('shoot') and gun_meshes is not None:
            ev.append((5001, 0, muzzle or MUZZLE.get(kind, '20')))
        for frac, path in snd.get(motion, []):
            ev.append((5004, int(round(frac * (n - 1))), path))
        q.add(Sequence(sname, [fn], fps=fps, loop=loop, events=ev))
    q.write(os.path.join(wd, name + '.qc'))
    out = out or os.path.join(CSTRIKE, 'models/vexmira/weapons', name + '.mdl')
    run_studiomdl(wd, name + '.qc', out, extra_args=['-p'])
    dedupe_animations(out)
    rep = validate_vmodel(out, kind, budget)
    if preview:
        rep['previews'] = preview_vmodel(out, os.path.join(PREVIEW_DIR, 'mdlkit', name))
    print(_fmt(rep))
    if rep['errors']:
        raise RuntimeError('\n'.join(rep['errors']))
    return rep


def validate_vmodel(path, kind, budget):
    from .mdl_read import MDL
    from . import preview as PV
    m = MDL(path)
    E, W = [], []
    names = [s['label'] for s in m.seqs]
    want = [s[0] for s in WEAPON_SETS[kind]]
    if names != want:
        E.append('sequence order %s != enum %s' % (names, want))
    size = os.path.getsize(path)
    if size > budget:
        E.append('size %d > budget %d' % (size, budget))
    # everything in front of the near plane and roughly on screen in every frame
    worst_near = 99.0
    for s in m.seqs:
        for f in np.linspace(0, max(s['numframes'] - 1, 0), min(6, s['numframes'])):
            bones = PV.setup_bones(m, s['index'], f, (0, 0), None, 0, player=False)
            tris = PV.posed_triangles(m, bones)
            P = np.vstack([t['pos'].reshape(-1, 3) for t in tris])
            vis = P[P[:, 0] > 0]
            # points within the 90x73 deg frustum must be > 4 units ahead (near clip)
            inside = (np.abs(vis[:, 1]) < vis[:, 0] * 1.0) & (np.abs(vis[:, 2]) < vis[:, 0] * 0.75)
            if inside.any():
                worst_near = min(worst_near, vis[inside, 0].min())
    if worst_near < 3.0:
        W.append('geometry %.1f units in front of the camera (near clip ~4): may be clipped' % worst_near)
    return dict(out=path, errors=E, warnings=W, stats=dict(size=size, seqs=names, tris=m.tri_count(),
                                                          textures=[(t['name'], t['width'], t['height']) for t in m.textures],
                                                          nearest=round(worst_near, 2)))


def preview_vmodel(path, outbase):
    from .mdl_read import MDL
    from . import preview as PV
    m = MDL(path)
    ims = []
    for s in m.seqs:
        n = s['numframes']
        for f in sorted(set([0, n // 3, (2 * n) // 3, n - 1])):
            ims.append(PV.render_viewmodel(m, s['index'], float(min(f, n - 1.001)), W=240, H=180,
                                           title='%s f%d' % (s['label'], f)))
    p = outbase + '_view.png'
    os.makedirs(os.path.dirname(p), exist_ok=True)
    PV.grid(ims, 4).save(p)
    return [p]


def _fmt(rep):
    L = ['== %s' % rep['out']]
    for k, v in rep['stats'].items():
        L.append('  %-10s %s' % (k, v))
    for e in rep['errors']:
        L.append('  ERROR ' + e)
    for w in rep['warnings']:
        L.append('  warning ' + w)
    for p in rep.get('previews', []):
        L.append('  preview ' + p)
    return '\n'.join(L)


def build_claws(spec, out, style=None, tex=(256, 256), budget=0.2e6):
    """Claw viewmodel (knife sequence layout) using the arms/hands/claws of a zombie/boss character spec."""
    return build_vmodel(os.path.splitext(os.path.basename(out))[0], spec, kind='knife', gun_meshes=None, out=out,
                        claws=True, tex=tex, style=style, budget=budget)


def build_claws_sample(quick=False):
    from . import CSTRIKE
    from .samples import walker_spec
    out = os.path.join(CSTRIKE, 'models/vexmira/claws/v_walker.mdl')
    return build_claws(walker_spec(), out)


# ============================================================================================ human v_ models

# v_ kind -> standard gun shape (guns.STANDARD key) used when no gun meshes are given
HUMAN_V_GUN = {'knife': 'knife', 'hegrenade': 'hegrenade', 'flashbang': 'flashbang', 'smokegrenade': 'smokegrenade',
               'ak47': 'ak47', 'm4a1': 'm4a1', 'm249': 'm249', 'awp': 'awp', 'xm1014': 'xm1014', 'deagle': 'deagle',
               'p90': 'p90', 'sg550': 'sg550'}


def build_human_vmodel(name, kind, gun_meshes=None, out=None, arms_spec=None, materials=None, sounds=None,
                       muzzle=None, tex=(256, 256), budget=0.4e6, preview=True, style=None):
    """Vexmira CT arms (operator spec unless arms_spec is given) + a gun, with the exact ReGameDLL sequence
    order of `kind` (WEAPON_SETS: knife, hegrenade, flashbang, smokegrenade, ak47, m4a1, m249, awp, xm1014,
    deagle, p90, sg550), 5001 muzzle-flash events on shoot sequences (attachment 0 = muzzle) and 5004
    stock sound events (STOCK_SOUNDS, override per motion with sounds={'reload': [(0.3, 'weapons/x.wav')]}).
    gun_meshes: GUN SPACE meshes (guns.standard_gun / pmodel.gun_preset / your own); default = the
    standard shape of the base weapon. Meshes named mag* follow v_mag, slide*/pump* follow v_slide.
    out default: cstrike/models/vexmira/weapons/<name>.mdl"""
    from .guns import standard_gun, standard_materials
    from .samples import operator_spec
    std = HUMAN_V_GUN[kind]
    gm = gun_meshes if gun_meshes is not None else standard_gun(std)
    mats = standard_materials(std)
    mats.update(materials or {})
    return build_vmodel(name, arms_spec or operator_spec(), kind=kind, gun_meshes=gm, out=out, tex=tex,
                        materials=mats, sounds=sounds, muzzle=muzzle, preview=preview, style=style, budget=budget)
