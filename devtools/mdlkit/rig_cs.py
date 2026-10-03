"""CS 1.6 compatible biped skeleton with parametric proportions.

Bone ORDER (important for the client/server gait merge, see README "gait merge"):
    0 Bip01, 1 Bip01 Pelvis,
    2..5  Bip01 L Thigh / L Calf / L Foot / L Toe0
    6..9  Bip01 R Thigh / R Calf / R Foot / R Toe0
    [lower extras: e.g. tail - parented to Pelvis/each other, BEFORE Bip01 Spine -> driven by gait]
    Bip01 Spine, Spine1, Spine2, Spine3, Neck, Head,
    L Clavicle, L UpperArm, L Forearm, L Hand, L Finger0, L Finger01, L Finger1, L Finger11,
    R Clavicle, R UpperArm, R Forearm, R Hand, R Finger0, R Finger01, R Finger1, R Finger11,
    [upper extras: wings, cape, extra arms, hook ... - never parented to Bip01 Pelvis]
The gait merge loop (cs16client GameStudioModelRenderer::StudioSetupBones and ReGameDLL
SV_StudioSetupBones) copies bones from the gait sequence starting at index 0 until it meets
"Bip01 Spine", and switches copying back ON at any bone whose PARENT is "Bip01 Pelvis". With this order
Bip01, Pelvis, both legs and lower extras come from the gait, everything else from the upper-body
sequence. validate.check_bone_order() enforces it.

Rest pose: every bone's rest rotation is IDENTITY (frames aligned with model space: +X forward,
+Y left, +Z up); joints are positioned for a standing character with feet at z = -36 (hull centre at
origin). Hands: the hand bone frame IS the weapon grip frame: +X = barrel direction, +Z = gun top,
grip axis roughly -Z; right palm faces +Y, left palm faces -Y. A p_ model whose gun is modelled in
that frame (grip at GRIP_OFFSET) sits correctly in any of our characters' hands.
"""
import math
import numpy as np

FOOT_Z = -36.0
CROUCH_FOOT_Z = -18.0

CS_BONES = [
    ('Bip01', None), ('Bip01 Pelvis', 'Bip01'),
    ('Bip01 L Thigh', 'Bip01 Pelvis'), ('Bip01 L Calf', 'Bip01 L Thigh'), ('Bip01 L Foot', 'Bip01 L Calf'),
    ('Bip01 L Toe0', 'Bip01 L Foot'),
    ('Bip01 R Thigh', 'Bip01 Pelvis'), ('Bip01 R Calf', 'Bip01 R Thigh'), ('Bip01 R Foot', 'Bip01 R Calf'),
    ('Bip01 R Toe0', 'Bip01 R Foot'),
    ('Bip01 Spine', 'Bip01 Pelvis'), ('Bip01 Spine1', 'Bip01 Spine'), ('Bip01 Spine2', 'Bip01 Spine1'),
    ('Bip01 Spine3', 'Bip01 Spine2'), ('Bip01 Neck', 'Bip01 Spine3'), ('Bip01 Head', 'Bip01 Neck'),
    ('Bip01 L Clavicle', 'Bip01 Spine3'), ('Bip01 L UpperArm', 'Bip01 L Clavicle'),
    ('Bip01 L Forearm', 'Bip01 L UpperArm'), ('Bip01 L Hand', 'Bip01 L Forearm'),
    ('Bip01 L Finger0', 'Bip01 L Hand'), ('Bip01 L Finger01', 'Bip01 L Finger0'),
    ('Bip01 L Finger1', 'Bip01 L Hand'), ('Bip01 L Finger11', 'Bip01 L Finger1'),
    ('Bip01 R Clavicle', 'Bip01 Spine3'), ('Bip01 R UpperArm', 'Bip01 R Clavicle'),
    ('Bip01 R Forearm', 'Bip01 R UpperArm'), ('Bip01 R Hand', 'Bip01 R Forearm'),
    ('Bip01 R Finger0', 'Bip01 R Hand'), ('Bip01 R Finger01', 'Bip01 R Finger0'),
    ('Bip01 R Finger1', 'Bip01 R Hand'), ('Bip01 R Finger11', 'Bip01 R Finger1'),
]

# CS hitgroups
HG_GENERIC, HG_HEAD, HG_CHEST, HG_STOMACH, HG_LEFTARM, HG_RIGHTARM, HG_LEFTLEG, HG_RIGHTLEG = range(8)


class RigSpec:
    """Proportions. All lengths are fractions of `height` unless stated otherwise.

    height        total height feet->top of head (CS human ~72; hull is 72 tall)
    shoulder_w    distance between shoulder joints / height
    hip_w         distance between hip joints / height
    leg           hip joint height / height
    arm           (upper+forearm) length / height
    hand          hand length / height
    head          head height / height
    neck          neck length / height
    torso_depth   chest depth multiplier (mesh), bulk (mesh thickness multiplier)
    """
    def __init__(self, height=72.0, shoulder_w=0.20, hip_w=0.115, leg=0.505, arm=0.335, hand=0.105,
                 head=0.143, neck=0.04, foot=0.155, bulk=1.0, limb_thick=1.0, arm_thick=1.0, leg_thick=1.0,
                 extras=None, hand_pose='grip'):
        self.height = height
        self.hand_pose = hand_pose
        self.shoulder_w = shoulder_w
        self.hip_w = hip_w
        self.leg = leg
        self.arm = arm
        self.hand = hand
        self.head = head
        self.neck = neck
        self.foot = foot
        self.bulk = bulk
        self.limb_thick = limb_thick
        self.arm_thick = arm_thick
        self.leg_thick = leg_thick
        self.extras = extras or []   # list of dicts: name, parent, pos (world rest), lower(bool)

    @staticmethod
    def preset(kind):
        if kind == 'human':
            return RigSpec()
        if kind == 'zombie':
            return RigSpec(height=71.0, shoulder_w=0.225, arm=0.36, hand=0.115, limb_thick=0.95)
        if kind == 'runner':
            return RigSpec(height=73.0, shoulder_w=0.2, leg=0.54, arm=0.37, limb_thick=0.8, bulk=0.8)
        if kind == 'tank':
            return RigSpec(height=74.0, shoulder_w=0.30, hip_w=0.14, leg=0.46, arm=0.36, hand=0.13,
                           head=0.12, bulk=1.45, limb_thick=1.45)
        if kind == 'boss':
            return RigSpec(height=110.0, shoulder_w=0.30, hip_w=0.14, leg=0.47, arm=0.38, hand=0.13,
                           head=0.12, bulk=1.4, limb_thick=1.35)
        raise ValueError(kind)


class Rig:
    def __init__(self, spec=None):
        self.spec = spec or RigSpec()
        s = self.spec
        H = s.height
        z0 = FOOT_Z
        self.names = []
        self.parent_names = []
        self.rest = {}   # name -> world rest position (3,)
        P = self.rest

        hip_z = z0 + s.leg * H
        P['Bip01'] = np.array([0.0, 0.0, hip_z + 0.03 * H])
        P['Bip01 Pelvis'] = P['Bip01'].copy()
        hw = s.hip_w * H * 0.5
        knee_z = z0 + s.leg * H * 0.53
        ankle_z = z0 + 0.045 * H
        for side, sg in (('L', 1), ('R', -1)):
            P['Bip01 %s Thigh' % side] = np.array([0.0, sg * hw, hip_z])
            P['Bip01 %s Calf' % side] = np.array([0.012 * H, sg * hw * 0.92, knee_z])
            P['Bip01 %s Foot' % side] = np.array([-0.006 * H, sg * hw * 0.88, ankle_z])
            P['Bip01 %s Toe0' % side] = np.array([-0.006 * H + s.foot * H * 0.68, sg * hw * 0.9, z0 + 0.012 * H])
        # spine: from just above the hips to the base of the neck
        neck_base = z0 + H * (1 - s.head - s.neck)
        sp0 = P['Bip01'][2] + 0.03 * H
        P['Bip01 Spine'] = np.array([-0.004 * H, 0.0, sp0])
        for k, nm in enumerate(['Bip01 Spine1', 'Bip01 Spine2', 'Bip01 Spine3']):
            t = (k + 1) / 4.0
            P[nm] = np.array([-0.006 * H * (1 - abs(t - 0.6)), 0.0, sp0 + (neck_base - sp0) * t])
        P['Bip01 Neck'] = np.array([-0.008 * H, 0.0, neck_base])
        P['Bip01 Head'] = np.array([-0.002 * H, 0.0, neck_base + s.neck * H])
        sh_z = neck_base - 0.034 * H
        swh = s.shoulder_w * H * 0.5
        ua = s.arm * H * 0.53
        fa = s.arm * H * 0.47
        for side, sg in (('L', 1), ('R', -1)):
            P['Bip01 %s Clavicle' % side] = np.array([0.006 * H, sg * 0.02 * H, sh_z - 0.005 * H])
            sh = np.array([-0.004 * H, sg * swh, sh_z])
            P['Bip01 %s UpperArm' % side] = sh
            # arms hang ~8 deg outward, elbows slightly back
            elb = sh + np.array([-0.012 * H, sg * ua * math.sin(math.radians(7)), -ua * math.cos(math.radians(7))])
            P['Bip01 %s Forearm' % side] = elb
            wr = elb + np.array([0.02 * H, sg * fa * math.sin(math.radians(4)), -fa * math.cos(math.radians(4))])
            P['Bip01 %s Hand' % side] = wr
            hl = s.hand * H
            k = hl / 7.6
            G = grip_rest_rot()
            # finger joints laid out in the GRIP frame (see module doc), then rotated into the rest pose
            if s.hand_pose == 'grip':
                f0, f01, f1, f11 = (1.2, 0.75, 0.75), (2.5, 1.55, 1.25), (4.0, -0.05, -0.45), (5.0, 1.15, -0.45)
            elif s.hand_pose == 'claw':
                f0, f01, f1, f11 = (1.3, 0.85, 0.7), (2.7, 1.5, 1.2), (4.0, -0.05, -0.45), (5.9, 0.55, -0.45)
            else:  # open
                f0, f01, f1, f11 = (1.3, 0.9, 0.6), (2.9, 1.5, 1.0), (4.0, -0.05, -0.45), (6.2, 0.0, -0.45)
            for nm, g in (('Finger0', f0), ('Finger01', f01), ('Finger1', f1), ('Finger11', f11)):
                gg = np.array([g[0], g[1] if side == 'R' else -g[1], g[2]]) * k
                P['Bip01 %s %s' % (side, nm)] = wr + G @ gg

        lower_extras = [e for e in s.extras if e.get('lower')]
        upper_extras = [e for e in s.extras if not e.get('lower')]
        order = []
        for nm, par in CS_BONES:
            if nm == 'Bip01 Spine':
                for e in lower_extras:
                    order.append((e['name'], e['parent']))
            order.append((nm, par))
        for e in upper_extras:
            order.append((e['name'], e['parent']))
        for e in s.extras:
            P[e['name']] = np.asarray(e['pos'], dtype=np.float64)
        self.names = [n for n, _ in order]
        self.index = {n: i for i, n in enumerate(self.names)}
        self.parents = [self.index[p] if p is not None else -1 for _, p in order]
        for e in lower_extras:
            # lower extras must not break the copy region: they come before Spine, fine with any parent
            pass
        for e in upper_extras:
            if e['parent'] == 'Bip01 Pelvis':
                raise ValueError('upper extra bone %s may not be parented to Bip01 Pelvis (would break the '
                                 'gait merge); mark it lower=True' % e['name'])
        self.n = len(self.names)
        self.rest_world = np.array([P[n] for n in self.names])
        # rest WORLD rotations: identity except hands/fingers (grip frame, see module doc) and extras
        self.rest_rot_world = np.repeat(np.eye(3)[None], self.n, axis=0)
        for i, nm in enumerate(self.names):
            if ' Hand' in nm or ' Finger' in nm:
                self.rest_rot_world[i] = grip_rest_rot()
        for e in s.extras:
            if 'rot' in e:
                self.rest_rot_world[self.index[e['name']]] = np.asarray(e['rot'], dtype=np.float64)
        self.rest_local_pos = np.zeros((self.n, 3))
        self.rest_local_rot = np.repeat(np.eye(3)[None], self.n, axis=0)
        for i in range(self.n):
            p = self.parents[i]
            if p < 0:
                self.rest_local_pos[i] = self.rest_world[i]
                self.rest_local_rot[i] = self.rest_rot_world[i]
            else:
                Rp = self.rest_rot_world[p]
                self.rest_local_pos[i] = Rp.T @ (self.rest_world[i] - self.rest_world[p])
                self.rest_local_rot[i] = Rp.T @ self.rest_rot_world[i]

    # ------------------------------------------------------------------ helpers
    def i(self, name):
        return self.index[name]

    def bones_for_smd(self):
        return [dict(name=n, parent=p) for n, p in zip(self.names, self.parents)]

    def rest_local(self):
        return [(self.rest_local_pos[i], self.rest_local_rot[i]) for i in range(self.n)]

    def side_bone(self, side, part):
        return self.index['Bip01 %s %s' % (side, part)]

    def mirror_map(self):
        """bone index -> mirrored bone index (L<->R)."""
        mp = {}
        for i, n in enumerate(self.names):
            if ' L ' in n:
                m = n.replace(' L ', ' R ')
            elif ' R ' in n:
                m = n.replace(' R ', ' L ')
            elif n.endswith('_L'):
                m = n[:-2] + '_R'
            elif n.endswith('_R'):
                m = n[:-2] + '_L'
            else:
                m = n
            mp[i] = self.index.get(m, i)
        return mp

    def J(self, name):
        """Rest world joint position."""
        return self.rest_world[self.index[name]].copy()

    @property
    def H(self):
        return self.spec.height


def grip_rest_rot():
    """Rest world rotation of hand/finger bones: grip frame (X barrel, Y gun-left, Z gun-top) of a relaxed
    hanging fist: barrel points down (-Z world), gun top points forward (+X world)."""
    from .mathx import rot_y
    return rot_y(math.pi / 2)


# Standard grip centre in hand-bone (grip frame) coordinates for a 72-unit human. p_ models are authored
# so the centre of the gun's grip sits here (right hand); mirror Y for the left hand.
GRIP_R = np.array([2.7, 1.25, -1.0])
GRIP_L = np.array([2.7, -1.25, -1.0])


def grip_offset(rig, side='R'):
    k = rig.spec.hand * rig.spec.height / 7.6
    return (GRIP_R if side == 'R' else GRIP_L) * k


def ao_pose_matrices(rig, arm_out=62.0, leg_out=12.0):
    """(nb,3,4) matrices mapping rest-pose model space -> a spread 'AO pose' (arms abducted, legs apart),
    used by paint.bake_textures so baked occlusion does not contain arm/leg shadows on the torso."""
    from .pose import Pose
    from .mathx import axis_angle
    p = Pose(rig)
    for side, sg in (('L', 1), ('R', -1)):
        p.rotate_world('Bip01 %s UpperArm' % side, axis_angle([1, 0, 0], sg * math.radians(arm_out)))
        p.rotate_world('Bip01 %s Thigh' % side, axis_angle([1, 0, 0], sg * math.radians(leg_out)))
    WR, WT = p.world()
    out = np.zeros((rig.n, 3, 4))
    for i in range(rig.n):
        R = WR[i] @ rig.rest_rot_world[i].T
        out[i, :, :3] = R
        out[i, :, 3] = WT[i] - R @ rig.rest_world[i]
    return out
