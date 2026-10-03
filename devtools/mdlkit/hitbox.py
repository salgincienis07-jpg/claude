"""Hitbox generation for CS player models.

CS hitgroups: 1 head, 2 chest, 3 stomach, 4 left arm, 5 right arm, 6 left leg, 7 right leg.
Boxes are computed from the rest-pose vertices bound to each bone, expressed in bone-local space and
shrunk a little (CS hitboxes are slightly tighter than the mesh).

hull_fit: for oversized characters (bosses ~100-120 units tall) every box can be re-mapped so that the
REST pose hitboxes fit inside the 32x32x72 player hull (the engine first traces against the hull bbox,
so anything outside the hull can never be hit). The mapping scales world positions about the feet
(z) and the vertical axis (xy) and is converted back to bone-local offsets, so the boxes still follow
their bones when animated.
"""
import numpy as np

from .rig_cs import HG_HEAD, HG_CHEST, HG_STOMACH, HG_LEFTARM, HG_RIGHTARM, HG_LEFTLEG, HG_RIGHTLEG

DEFAULT_GROUPS = {
    'Bip01 Pelvis': HG_STOMACH, 'Bip01 Spine': HG_STOMACH, 'Bip01 Spine1': HG_STOMACH,
    'Bip01 Spine2': HG_CHEST, 'Bip01 Spine3': HG_CHEST, 'Bip01 Neck': HG_CHEST, 'Bip01 Head': HG_HEAD,
    'Bip01 L UpperArm': HG_LEFTARM, 'Bip01 L Forearm': HG_LEFTARM, 'Bip01 L Hand': HG_LEFTARM,
    'Bip01 R UpperArm': HG_RIGHTARM, 'Bip01 R Forearm': HG_RIGHTARM, 'Bip01 R Hand': HG_RIGHTARM,
    'Bip01 L Thigh': HG_LEFTLEG, 'Bip01 L Calf': HG_LEFTLEG, 'Bip01 L Foot': HG_LEFTLEG,
    'Bip01 R Thigh': HG_RIGHTLEG, 'Bip01 R Calf': HG_RIGHTLEG, 'Bip01 R Foot': HG_RIGHTLEG,
}
# children whose vertices are folded into the parent's box
FOLD = {'Bip01 L Finger0': 'Bip01 L Hand', 'Bip01 L Finger01': 'Bip01 L Hand', 'Bip01 L Finger1': 'Bip01 L Hand',
        'Bip01 L Finger11': 'Bip01 L Hand', 'Bip01 R Finger0': 'Bip01 R Hand', 'Bip01 R Finger01': 'Bip01 R Hand',
        'Bip01 R Finger1': 'Bip01 R Hand', 'Bip01 R Finger11': 'Bip01 R Hand', 'Bip01 L Toe0': 'Bip01 L Foot',
        'Bip01 R Toe0': 'Bip01 R Foot', 'Bip01 Clavicle': None}


def compute_hitboxes(rig, meshes, groups=None, shrink=0.88, extra=None, min_size=1.0):
    """Returns list of (group, bone_name, mins(3), maxs(3)) in bone-local space."""
    groups = dict(DEFAULT_GROUPS, **(groups or {}))
    pts = {}
    for m in meshes:
        if getattr(m, 'no_hitbox', False):
            continue
        for b in np.unique(m.bone):
            name = rig.names[b]
            tgt = FOLD.get(name, name)
            if tgt is None or tgt not in groups:
                continue
            pts.setdefault(tgt, []).append(m.v[m.bone == b])
    out = []
    for name, g in groups.items():
        if name not in pts or name not in rig.index:
            continue
        P = np.vstack(pts[name])
        i = rig.index[name]
        Rw = rig.rest_rot_world[i]
        local = (P - rig.rest_world[i]) @ Rw   # world -> bone local (R^T (p - o))
        lo = np.percentile(local, 2, axis=0); hi = np.percentile(local, 98, axis=0)
        c = (lo + hi) / 2; h = np.maximum((hi - lo) / 2 * shrink, min_size / 2)
        out.append((g, name, c - h, c + h))
    for e in (extra or []):
        out.append(e)
    return out


def hull_fit(rig, boxes, hull_min=(-16, -16, -36), hull_max=(16, 16, 36), margin=0.5, keep_groups=(4, 5)):
    """Remap rest-pose boxes into the hull (see module doc). Returns new boxes.
    keep_groups: hitgroups left at their natural size/position (default the arms: their bones swing far
    from the rest pose, so a remapped bone-local offset would throw the box metres away in aim poses;
    arm boxes above the hull simply cannot be hit, which is harmless)."""
    hmin = np.array(hull_min, float) + margin
    hmax = np.array(hull_max, float) - margin
    corners_w = []
    for g, name, mn, mx in boxes:
        i = rig.index[name]
        Rw = rig.rest_rot_world[i]; o = rig.rest_world[i]
        cs = np.array([[mx[0] if a & 1 else mn[0], mx[1] if a & 2 else mn[1], mx[2] if a & 4 else mn[2]] for a in range(8)])
        corners_w.append(cs @ Rw.T + o)
    allc = np.vstack(corners_w)
    lo, hi = allc.min(0), allc.max(0)
    sz = min(1.0, (hmax[2] - hmin[2]) / max(hi[2] - lo[2], 1e-6))
    sxy = min(1.0, (hmax[0] - hmin[0]) / max(hi[0] - lo[0], 1e-6), (hmax[1] - hmin[1]) / max(hi[1] - lo[1], 1e-6))
    def mapw(p):
        q = p.copy()
        q[:, 2] = hmin[2] + (p[:, 2] - lo[2]) * sz
        q[:, 0] = p[:, 0] * sxy
        q[:, 1] = p[:, 1] * sxy
        return q
    out = []
    for (g, name, mn, mx), cw in zip(boxes, corners_w):
        if g in keep_groups:
            out.append((g, name, mn, mx))
            continue
        i = rig.index[name]
        Rw = rig.rest_rot_world[i]; o = rig.rest_world[i]
        cm = mapw(cw)
        local = (cm - o) @ Rw
        out.append((g, name, local.min(0), local.max(0)))
    return out


def fit_boxes_to_poses(rig, boxes, poses, margin=0.6, keep_groups=(4, 5)):
    """Vertically re-centre (and if needed shrink) hitboxes so their centres stay inside the hull in every
    sample pose. poses: list of (Pose, zlo, zhi) - e.g. standing and crouched aim poses at the 9-blend
    corners. Each box gets one bone-local offset (applied along the bone's rest-world up axis)."""
    out = []
    for g, name, mn, mx in boxes:
        if g in keep_groups:
            out.append((g, name, mn, mx))
            continue
        i = rig.index[name]
        lo_d, hi_d = -1e9, 1e9
        hz_max = 0.0
        for pose, zlo, zhi in poses:
            WR, WT = pose.world()
            c = (np.asarray(mn) + np.asarray(mx)) / 2
            cw = WR[i] @ c + WT[i]
            # half height of the box in world z in this pose
            hz = 0.5 * np.abs(WR[i][2, :]) @ (np.asarray(mx) - np.asarray(mn)) * 0.5
            hz_max = max(hz_max, hz)
            lo_d = max(lo_d, zlo + margin - cw[2])
            hi_d = min(hi_d, zhi - margin - cw[2])
        mn = np.asarray(mn, float).copy(); mx = np.asarray(mx, float).copy()
        if lo_d <= hi_d:
            d = 0.0 if lo_d <= 0.0 <= hi_d else (lo_d if lo_d > 0 else hi_d)
        else:
            d = (lo_d + hi_d) / 2
        if abs(d) > 1e-6:
            # world up expressed in the bone's rest frame
            up_local = rig.rest_rot_world[i].T @ np.array([0, 0, d])
            mn += up_local; mx += up_local
        out.append((g, name, mn, mx))
    return out
