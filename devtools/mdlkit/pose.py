"""Pose representation, forward kinematics and IK helpers on top of rig_cs.Rig.

A Pose stores per-bone LOCAL rotation (3x3) and LOCAL translation (rest offsets by default).
World transforms are computed lazily. Because every rest rotation is identity, a bone's world rotation
directly says how its rest geometry is rotated in model space.
"""
import math
import numpy as np

from .mathx import rot_x, rot_y, rot_z, rot_between, axis_angle, orthonormalize


class Pose:
    def __init__(self, rig):
        self.rig = rig
        n = rig.n
        self.R = rig.rest_local_rot.copy()
        self.t = rig.rest_local_pos.copy()
        self._W = None

    def copy(self):
        p = Pose(self.rig)
        p.R = self.R.copy()
        p.t = self.t.copy()
        return p

    def dirty(self):
        self._W = None

    def world(self):
        if self._W is None:
            n = self.rig.n
            WR = np.zeros((n, 3, 3))
            WT = np.zeros((n, 3))
            for i in range(n):
                p = self.rig.parents[i]
                if p < 0:
                    WR[i] = self.R[i]
                    WT[i] = self.t[i]
                else:
                    WR[i] = WR[p] @ self.R[i]
                    WT[i] = WR[p] @ self.t[i] + WT[p]
            self._W = (WR, WT)
        return self._W

    def wpos(self, name):
        i = self.rig.index[name] if isinstance(name, str) else name
        return self.world()[1][i].copy()

    def wrot(self, name):
        i = self.rig.index[name] if isinstance(name, str) else name
        return self.world()[0][i].copy()

    def local_rot(self, name, R, mode='set'):
        i = self.rig.index[name] if isinstance(name, str) else name
        if mode == 'set':
            self.R[i] = R
        elif mode == 'pre':   # rotate in parent space (applied after existing)
            self.R[i] = R @ self.R[i]
        else:                 # post: rotate in bone local space
            self.R[i] = self.R[i] @ R
        self.dirty()

    def set_world_rot(self, name, Rw):
        i = self.rig.index[name] if isinstance(name, str) else name
        p = self.rig.parents[i]
        if p < 0:
            self.R[i] = Rw
        else:
            WR, _ = self.world()
            self.R[i] = WR[p].T @ Rw
        self.dirty()

    def rotate_world(self, name, Rw_delta):
        """Apply a world-space rotation to a bone (about its own joint), children follow."""
        Rw = self.wrot(name)
        self.set_world_rot(name, Rw_delta @ Rw)

    def set_root(self, pos=None, R=None):
        i = 0
        if pos is not None:
            self.t[i] = pos
        if R is not None:
            self.R[i] = R
        self.dirty()

    # ------------------------------------------------------------------ IK
    def two_bone_ik(self, upper, lower, end, target, pole, end_rot=None, soft=0.995):
        """Place joint `end` at `target` by rotating `upper` and `lower` in world space.
        pole: world direction the middle joint should bend towards. end_rot: optional world rotation
        for the end bone (else it keeps its local rotation relative to `lower`)."""
        rig = self.rig
        iu, il, ie = rig.index[upper], rig.index[lower], rig.index[end]
        WR, WT = self.world()
        a = WT[iu]
        # rest segment vectors (in rest/world-aligned frames; local == rest direction because rest R = I)
        u_rest = rig.rest_local_pos[il]          # upper -> mid
        l_rest = rig.rest_local_pos[ie]          # mid -> end
        L1 = np.linalg.norm(u_rest); L2 = np.linalg.norm(l_rest)
        tgt = np.asarray(target, dtype=np.float64)
        d = tgt - a
        dist = np.linalg.norm(d)
        maxr = (L1 + L2) * soft
        minr = abs(L1 - L2) * 1.02 + 1e-3
        if dist > maxr:
            d = d / dist * maxr; dist = maxr
        if dist < minr:
            d = d / max(dist, 1e-9) * minr; dist = minr
        dn = d / dist
        # angle at upper joint
        cosA = (L1 * L1 + dist * dist - L2 * L2) / (2 * L1 * dist)
        A = math.acos(max(-1.0, min(1.0, cosA)))
        pole = np.asarray(pole, dtype=np.float64)
        pv = pole - dn * np.dot(pole, dn)
        if np.linalg.norm(pv) < 1e-6:
            pv = np.cross(dn, np.array([0, 0, 1.0]))
            if np.linalg.norm(pv) < 1e-6:
                pv = np.cross(dn, np.array([1.0, 0, 0]))
        pv /= np.linalg.norm(pv)
        mid = a + (dn * math.cos(A) + pv * math.sin(A)) * L1
        # build world rotations mapping rest (segment dir, bend normal) frames onto new ones.
        # rest bend plane: for the rest pose use the plane containing u_rest and l_rest (or a default)
        rest_n = np.cross(u_rest, l_rest)
        if np.linalg.norm(rest_n) < 1e-6 * L1 * L2:
            rest_n = np.cross(u_rest, np.array([1.0, 0, 0])) if abs(u_rest[0]) < 0.9 * L1 else np.cross(u_rest, [0, 1.0, 0])
        rest_n /= np.linalg.norm(rest_n)
        new_u = mid - a
        new_l = tgt if dist == np.linalg.norm(tgt - a) else a + d
        new_l = (a + d) - mid
        new_n = np.cross(new_u, new_l)
        if np.linalg.norm(new_n) < 1e-9:
            new_n = np.cross(new_u, pv)
        new_n /= np.linalg.norm(new_n)
        Ru = _frame_map(u_rest, rest_n, new_u, new_n)
        Rl = _frame_map(l_rest, rest_n, new_l, new_n)
        keep_end_world = None
        if end_rot is None:
            keep_end_world = None
        self.set_world_rot(upper, Ru)
        self.set_world_rot(lower, Rl)
        if end_rot is not None:
            self.set_world_rot(end, end_rot)
        return mid

    def aim_bone(self, name, child, target, up_hint=None):
        """Rotate bone (world) minimally so the child's joint points at target."""
        rig = self.rig
        i = rig.index[name]
        c = rig.index[child]
        WR, WT = self.world()
        cur = WR[i] @ rig.rest_local_pos[c]
        want = np.asarray(target) - WT[i]
        self.set_world_rot(name, rot_between(cur, want) @ WR[i])

    def fingers(self, side, curl=0.0, thumb=0.0, spread=0.0):
        """Curl fingers relative to the rest hand shape (+ = close, - = open).
        Finger bones live in the grip frame: the knuckle line is grip-Z, palm faces +Y (right hand) /
        -Y (left hand), so flexion is a rotation about local Z towards the palm."""
        sg = 1 if side == 'R' else -1
        z = np.array([0, 0, 1.0])
        r1 = axis_angle(z, sg * math.radians(50) * curl)
        r2 = axis_angle(z, sg * math.radians(55) * curl)
        sp = axis_angle(np.array([0, 1.0, 0]), math.radians(12) * spread)
        self.local_rot('Bip01 %s Finger1' % side, self.rig.rest_local_rot[self.rig.index['Bip01 %s Finger1' % side]] @ r1 @ sp)
        self.local_rot('Bip01 %s Finger11' % side, self.rig.rest_local_rot[self.rig.index['Bip01 %s Finger11' % side]] @ r2)
        t1 = axis_angle(np.array([1.0, 0, 0.4]), sg * math.radians(30) * thumb)
        self.local_rot('Bip01 %s Finger0' % side, self.rig.rest_local_rot[self.rig.index['Bip01 %s Finger0' % side]] @ t1)
        self.local_rot('Bip01 %s Finger01' % side, self.rig.rest_local_rot[self.rig.index['Bip01 %s Finger01' % side]] @ axis_angle(np.array([1.0, 0, 0.2]), sg * math.radians(30) * thumb))

    # ------------------------------------------------------------------ export
    def to_frame(self, root_override_R=None):
        """List of (local pos, local R) for the SMD writer."""
        return [(self.t[i].copy(), self.R[i].copy()) for i in range(self.rig.n)]


def _frame_map(a_rest, n_rest, a_new, n_new):
    """Rotation taking orthonormal frame (a_rest, n_rest, a x n) to (a_new, n_new, a x n)."""
    def fr(a, n):
        a = a / np.linalg.norm(a)
        n = n - a * np.dot(n, a)
        n = n / np.linalg.norm(n)
        return np.stack([a, n, np.cross(a, n)], axis=1)
    return fr(a_new, n_new) @ fr(a_rest, n_rest).T


def blend_poses(p1, p2, t):
    """Slerp local rotations / lerp translations between two poses (same rig)."""
    from .mathx import quaternion_slerp_v, quaternion_matrix_v
    out = p1.copy()
    q1 = mat_to_quat_v(p1.R); q2 = mat_to_quat_v(p2.R)
    q = quaternion_slerp_v(q1, q2, t)
    out.R = quaternion_matrix_v(q)
    out.t = p1.t * (1 - t) + p2.t * t
    out.dirty()
    return out


def mat_to_quat_v(R):
    R = np.asarray(R)
    q = np.zeros(R.shape[:-2] + (4,))
    tr = R[..., 0, 0] + R[..., 1, 1] + R[..., 2, 2]
    for idx in np.ndindex(R.shape[:-2]):
        m = R[idx]
        t = tr[idx]
        if t > 0:
            s = math.sqrt(t + 1.0) * 2
            w = 0.25 * s; x = (m[2, 1] - m[1, 2]) / s; y = (m[0, 2] - m[2, 0]) / s; z = (m[1, 0] - m[0, 1]) / s
        elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
            s = math.sqrt(1.0 + m[0, 0] - m[1, 1] - m[2, 2]) * 2
            w = (m[2, 1] - m[1, 2]) / s; x = 0.25 * s; y = (m[0, 1] + m[1, 0]) / s; z = (m[0, 2] + m[2, 0]) / s
        elif m[1, 1] > m[2, 2]:
            s = math.sqrt(1.0 + m[1, 1] - m[0, 0] - m[2, 2]) * 2
            w = (m[0, 2] - m[2, 0]) / s; x = (m[0, 1] + m[1, 0]) / s; y = 0.25 * s; z = (m[1, 2] + m[2, 1]) / s
        else:
            s = math.sqrt(1.0 + m[2, 2] - m[0, 0] - m[1, 1]) * 2
            w = (m[1, 0] - m[0, 1]) / s; x = (m[0, 2] + m[2, 0]) / s; y = (m[1, 2] + m[2, 1]) / s; z = 0.25 * s
        q[idx] = (x, y, z, w)
    return q
