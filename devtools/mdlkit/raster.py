"""Small numpy triangle rasterizer shared by the previewer, the UV painter and the AO baker.

raster(tri_xy, tri_z, tri_attr, W, H, depth_test=True, cull=None)
    tri_xy  (n,3,2) pixel coordinates (x right, y down; pixel centres at +0.5)
    tri_z   (n,3)   depth (smaller = closer) or None
    tri_attr(n,3,k) per-vertex attributes interpolated with (affine) barycentrics
returns zbuf (H,W), attr (H,W,k), tid (H,W) int (-1 = empty)
"""
import numpy as np


def raster(tri_xy, tri_z, tri_attr, W, H, depth_test=True, cull=None, zbuf=None, attr=None, tid=None,
           tid_offset=0):
    n = len(tri_xy)
    k = tri_attr.shape[2] if tri_attr is not None else 0
    if zbuf is None:
        zbuf = np.full((H, W), np.inf, dtype=np.float64)
    if attr is None:
        attr = np.zeros((H, W, k), dtype=np.float64)
    if tid is None:
        tid = np.full((H, W), -1, dtype=np.int64)
    if n == 0:
        return zbuf, attr, tid
    xy = np.asarray(tri_xy, dtype=np.float64)
    x0 = np.floor(xy[:, :, 0].min(1)).astype(np.int64)
    x1 = np.ceil(xy[:, :, 0].max(1)).astype(np.int64)
    y0 = np.floor(xy[:, :, 1].min(1)).astype(np.int64)
    y1 = np.ceil(xy[:, :, 1].max(1)).astype(np.int64)
    x0 = np.clip(x0, 0, W); x1 = np.clip(x1, 0, W)
    y0 = np.clip(y0, 0, H); y1 = np.clip(y1, 0, H)
    a = xy[:, 0]; b = xy[:, 1]; c = xy[:, 2]
    area = (b[:, 0] - a[:, 0]) * (c[:, 1] - a[:, 1]) - (b[:, 1] - a[:, 1]) * (c[:, 0] - a[:, 0])
    if cull == 'cw':      # cull triangles that are clockwise on screen (y down)
        keep = area > 0
    elif cull == 'ccw':
        keep = area < 0
    else:
        keep = np.abs(area) > 1e-12
    for i in np.nonzero(keep & (x1 > x0) & (y1 > y0))[0]:
        xs = np.arange(x0[i], x1[i]) + 0.5
        ys = np.arange(y0[i], y1[i]) + 0.5
        px, py = np.meshgrid(xs, ys)
        ar = area[i]
        w0 = ((b[i, 0] - px) * (c[i, 1] - py) - (b[i, 1] - py) * (c[i, 0] - px)) / ar
        w1 = ((c[i, 0] - px) * (a[i, 1] - py) - (c[i, 1] - py) * (a[i, 0] - px)) / ar
        w2 = 1.0 - w0 - w1
        eps = -1e-7
        inside = (w0 >= eps) & (w1 >= eps) & (w2 >= eps)
        if not inside.any():
            continue
        sl = (slice(y0[i], y1[i]), slice(x0[i], x1[i]))
        if tri_z is not None:
            z = w0 * tri_z[i, 0] + w1 * tri_z[i, 1] + w2 * tri_z[i, 2]
            if depth_test:
                inside &= z < zbuf[sl]
            zb = zbuf[sl]
            zb[inside] = z[inside]
        if not inside.any():
            continue
        tb = tid[sl]
        tb[inside] = i + tid_offset
        if k:
            ab = attr[sl]
            val = (w0[..., None] * tri_attr[i, 0] + w1[..., None] * tri_attr[i, 1] + w2[..., None] * tri_attr[i, 2])
            ab[inside] = val[inside]
    return zbuf, attr, tid


def dilate(img, valid, iterations=None):
    """Fill invalid pixels with the nearest valid pixel's value (for texture padding / bleeding)."""
    from scipy import ndimage
    if valid.all() or not valid.any():
        return img
    _, (iy, ix) = ndimage.distance_transform_edt(~valid, return_indices=True)
    return img[iy, ix]
