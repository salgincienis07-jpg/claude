"""Engine-exact math helpers (ports of HLSDK / cs16client studio math).

Conventions (verified against hlsdk utils/common/mathlib.c + cl_dll/studio_util.cpp):
  * SMD / MDL bone rotation triple r = (rx, ry, rz) radians.
    Matrix R = Rz(rz) @ Ry(ry) @ Rx(rx)   (studiomdl AngleMatrix, "matrix = (Z * Y) * X")
  * AngleQuaternion(r) is the quaternion of that same matrix, stored (x, y, z, w).
  * Engine model space: +X forward, +Y left, +Z up (yaw 0 faces +X).
All functions use float64 numpy arrays.
"""
import math
import numpy as np

# ----------------------------------------------------------------------------- rotations

def rot_x(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]], dtype=np.float64)


def rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]], dtype=np.float64)


def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]], dtype=np.float64)


def euler_to_matrix(r):
    """studiomdl AngleMatrix with radians: Rz @ Ry @ Rx."""
    return rot_z(r[2]) @ rot_y(r[1]) @ rot_x(r[0])


def matrix_to_euler(m):
    """Inverse of euler_to_matrix -> (rx, ry, rz) radians, each in [-pi, pi]."""
    m = np.asarray(m, dtype=np.float64)
    sp = -m[2, 0]
    sp = max(-1.0, min(1.0, sp))
    ry = math.asin(sp)
    if abs(sp) < 0.999999:
        rx = math.atan2(m[2, 1], m[2, 2])
        rz = math.atan2(m[1, 0], m[0, 0])
    else:  # gimbal lock: put everything in rz
        rx = 0.0
        rz = math.atan2(-m[0, 1], m[1, 1])
    return np.array([rx, ry, rz], dtype=np.float64)


def axis_angle(axis, ang):
    axis = np.asarray(axis, dtype=np.float64)
    n = np.linalg.norm(axis)
    if n < 1e-12 or abs(ang) < 1e-12:
        return np.eye(3)
    x, y, z = axis / n
    c, s = math.cos(ang), math.sin(ang)
    C = 1 - c
    return np.array([[c + x * x * C, x * y * C - z * s, x * z * C + y * s],
                     [y * x * C + z * s, c + y * y * C, y * z * C - x * s],
                     [z * x * C - y * s, z * y * C + x * s, c + z * z * C]])


def rot_between(a, b):
    """Minimal rotation matrix taking direction a onto direction b."""
    a = np.asarray(a, dtype=np.float64); b = np.asarray(b, dtype=np.float64)
    a = a / np.linalg.norm(a); b = b / np.linalg.norm(b)
    v = np.cross(a, b)
    c = float(np.dot(a, b))
    s = np.linalg.norm(v)
    if s < 1e-9:
        if c > 0:
            return np.eye(3)
        # 180 degrees: any perpendicular axis
        p = np.array([1.0, 0, 0]) if abs(a[0]) < 0.9 else np.array([0, 1.0, 0])
        ax = np.cross(a, p)
        return axis_angle(ax, math.pi)
    return axis_angle(v, math.atan2(s, c))


def look_frame(fwd, up_hint=(0, 0, 1)):
    """Rotation whose columns are (x=fwd, y=left, z=up) built from a forward vector."""
    f = np.asarray(fwd, dtype=np.float64)
    f = f / np.linalg.norm(f)
    u = np.asarray(up_hint, dtype=np.float64)
    l = np.cross(u, f)
    if np.linalg.norm(l) < 1e-6:
        l = np.cross(np.array([0, 1.0, 0]) if abs(f[1]) < 0.9 else np.array([1.0, 0, 0]), f)
    l /= np.linalg.norm(l)
    u2 = np.cross(f, l)
    return np.stack([f, l, u2], axis=1)


def orthonormalize(m):
    u, _, vt = np.linalg.svd(m)
    r = u @ vt
    if np.linalg.det(r) < 0:
        u[:, -1] *= -1
        r = u @ vt
    return r

# ----------------------------------------------------------------------------- engine quaternion math

def angle_quaternion(angles):
    """cl_dll studio_util.cpp AngleQuaternion (angles radians [x,y,z]) -> q (x,y,z,w)."""
    sy, cy = math.sin(angles[2] * 0.5), math.cos(angles[2] * 0.5)
    sp, cp = math.sin(angles[1] * 0.5), math.cos(angles[1] * 0.5)
    sr, cr = math.sin(angles[0] * 0.5), math.cos(angles[0] * 0.5)
    return np.array([sr * cp * cy - cr * sp * sy,
                     cr * sp * cy + sr * cp * sy,
                     cr * cp * sy - sr * sp * cy,
                     cr * cp * cy + sr * sp * sy], dtype=np.float64)


def angle_quaternion_v(angles):
    """Vectorised AngleQuaternion: angles (...,3) -> (...,4)."""
    a = np.asarray(angles, dtype=np.float64)
    sy, cy = np.sin(a[..., 2] * 0.5), np.cos(a[..., 2] * 0.5)
    sp, cp = np.sin(a[..., 1] * 0.5), np.cos(a[..., 1] * 0.5)
    sr, cr = np.sin(a[..., 0] * 0.5), np.cos(a[..., 0] * 0.5)
    return np.stack([sr * cp * cy - cr * sp * sy,
                     cr * sp * cy + sr * cp * sy,
                     cr * cp * sy - sr * sp * cy,
                     cr * cp * cy + sr * sp * sy], axis=-1)


def quaternion_slerp(p, q, t):
    """cl_dll QuaternionSlerp, exact port (including the 'backwards' flip and the 180deg branch)."""
    p = np.asarray(p, dtype=np.float64)
    q = np.array(q, dtype=np.float64)
    a = float(np.sum((p - q) ** 2))
    b = float(np.sum((p + q) ** 2))
    if a > b:
        q = -q
    cosom = float(np.dot(p, q))
    qt = np.zeros(4)
    if (1.0 + cosom) > 0.000001:
        if (1.0 - cosom) > 0.000001:
            omega = math.acos(max(-1.0, min(1.0, cosom)))
            sinom = math.sin(omega)
            sclp = math.sin((1.0 - t) * omega) / sinom
            sclq = math.sin(t * omega) / sinom
        else:
            sclp = 1.0 - t
            sclq = t
        qt = sclp * p + sclq * q
    else:
        qt[0] = -q[1]; qt[1] = q[0]; qt[2] = -q[3]; qt[3] = q[2]
        sclp = math.sin((1.0 - t) * (0.5 * math.pi))
        sclq = math.sin(t * (0.5 * math.pi))
        qt[:3] = sclp * p[:3] + sclq * qt[:3]
    return qt


def quaternion_slerp_v(p, q, t):
    """Vectorised slerp over (...,4) arrays with scalar t (same math as the engine)."""
    p = np.asarray(p, dtype=np.float64)
    q = np.array(q, dtype=np.float64)
    a = np.sum((p - q) ** 2, axis=-1)
    b = np.sum((p + q) ** 2, axis=-1)
    q = np.where((a > b)[..., None], -q, q)
    cosom = np.sum(p * q, axis=-1)
    out = np.empty_like(p)
    normal = (1.0 + cosom) > 0.000001
    lin = (1.0 - cosom) <= 0.000001
    omega = np.arccos(np.clip(cosom, -1, 1))
    sinom = np.sin(omega)
    with np.errstate(divide='ignore', invalid='ignore'):
        sclp = np.where(lin, 1.0 - t, np.sin((1.0 - t) * omega) / sinom)
        sclq = np.where(lin, t, np.sin(t * omega) / sinom)
    out[:] = sclp[..., None] * p + sclq[..., None] * q
    if not np.all(normal):
        idx = ~normal
        qq = q[idx]
        alt = np.stack([-qq[:, 1], qq[:, 0], -qq[:, 3], qq[:, 2]], axis=-1)
        s1 = math.sin((1.0 - t) * (0.5 * math.pi)); s2 = math.sin(t * (0.5 * math.pi))
        alt[:, :3] = s1 * p[idx][:, :3] + s2 * alt[:, :3]
        out[idx] = alt
    return out


def quaternion_matrix(q):
    """cl_dll QuaternionMatrix -> 3x3."""
    x, y, z, w = q
    return np.array([
        [1.0 - 2.0 * y * y - 2.0 * z * z, 2.0 * x * y - 2.0 * w * z, 2.0 * x * z + 2.0 * w * y],
        [2.0 * x * y + 2.0 * w * z, 1.0 - 2.0 * x * x - 2.0 * z * z, 2.0 * y * z - 2.0 * w * x],
        [2.0 * x * z - 2.0 * w * y, 2.0 * y * z + 2.0 * w * x, 1.0 - 2.0 * x * x - 2.0 * y * y]])


def quaternion_matrix_v(q):
    q = np.asarray(q, dtype=np.float64)
    x, y, z, w = q[..., 0], q[..., 1], q[..., 2], q[..., 3]
    m = np.empty(q.shape[:-1] + (3, 3))
    m[..., 0, 0] = 1.0 - 2.0 * y * y - 2.0 * z * z
    m[..., 0, 1] = 2.0 * x * y - 2.0 * w * z
    m[..., 0, 2] = 2.0 * x * z + 2.0 * w * y
    m[..., 1, 0] = 2.0 * x * y + 2.0 * w * z
    m[..., 1, 1] = 1.0 - 2.0 * x * x - 2.0 * z * z
    m[..., 1, 2] = 2.0 * y * z - 2.0 * w * x
    m[..., 2, 0] = 2.0 * x * z - 2.0 * w * y
    m[..., 2, 1] = 2.0 * y * z + 2.0 * w * x
    m[..., 2, 2] = 1.0 - 2.0 * x * x - 2.0 * y * y
    return m


def entity_matrix(yaw_deg=0.0, pitch_deg=0.0, roll_deg=0.0, origin=(0, 0, 0)):
    """Entity rotation as built by StudioSetUpTransform (angles[PITCH] negated, hlsdk AngleMatrix
    PITCH/YAW/ROLL order) -> 3x4."""
    p = math.radians(-pitch_deg); y = math.radians(yaw_deg); r = math.radians(roll_deg)
    sy, cy = math.sin(y), math.cos(y)
    sp, cp = math.sin(p), math.cos(p)
    sr, cr = math.sin(r), math.cos(r)
    m = np.zeros((3, 4))
    m[0, 0] = cp * cy; m[1, 0] = cp * sy; m[2, 0] = -sp
    m[0, 1] = sr * sp * cy + cr * -sy; m[1, 1] = sr * sp * sy + cr * cy; m[2, 1] = sr * cp
    m[0, 2] = cr * sp * cy + -sr * -sy; m[1, 2] = cr * sp * sy + -sr * cy; m[2, 2] = cr * cp
    m[:, 3] = origin
    return m


def concat(a, b):
    """ConcatTransforms for 3x4 matrices."""
    out = np.empty((3, 4))
    out[:, :3] = a[:, :3] @ b[:, :3]
    out[:, 3] = a[:, :3] @ b[:, 3] + a[:, 3]
    return out


def mat34(R, t):
    m = np.zeros((3, 4)); m[:, :3] = R; m[:, 3] = t
    return m


def wrap_pi(a):
    return (a + math.pi) % (2 * math.pi) - math.pi


def smoothstep(e0, e1, x):
    t = np.clip((np.asarray(x, dtype=np.float64) - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    return a + (b - a) * t
