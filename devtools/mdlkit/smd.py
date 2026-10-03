"""SMD (studiomdl source) writers.

Coordinates are written in ENGINE model space (+X forward, +Y left, +Z up) and the QC we emit uses
`$origin 0 0 0 -90`, which sets studiomdl's zrotation to 0 so nothing gets rotated (see qc.py).

Triangles must be counter-clockwise when seen from outside with outward normals (studiomdl flips
them for the engine; verified by its -r 'tag reversed' check: dot(cross(v1-v0, v2-v0), n) > 0).
"""
import numpy as np

from .mathx import matrix_to_euler


def _fmt(v):
    s = '%.6f' % v
    if s == '-0.000000':
        s = '0.000000'
    return s


def write_nodes(f, bones):
    f.write('nodes\n')
    for i, b in enumerate(bones):
        f.write('%d "%s" %d\n' % (i, b['name'], b['parent']))
    f.write('end\n')


def write_reference(path, bones, rest_local, meshes):
    """bones: list of {'name','parent'}; rest_local: list of (pos(3), R(3x3)) local transforms.
    meshes: iterable of objects with .tris -> list of (texture, [(bone, pos, nrm, (u,v)) x3])
    or a geom.Mesh-like with arrays (see geom.Mesh.smd_triangles)."""
    with open(path, 'w', newline='\n') as f:
        f.write('version 1\n')
        write_nodes(f, bones)
        f.write('skeleton\ntime 0\n')
        for i, (p, R) in enumerate(rest_local):
            r = matrix_to_euler(R)
            f.write('%d %s %s %s %s %s %s\n' % (i, _fmt(p[0]), _fmt(p[1]), _fmt(p[2]),
                                                 _fmt(r[0]), _fmt(r[1]), _fmt(r[2])))
        f.write('end\ntriangles\n')
        for m in meshes:
            for tex, verts in m.smd_triangles():
                f.write(tex + '\n')
                for (bone, p, n, uv) in verts:
                    f.write('%d %s %s %s %s %s %s %s %s\n' % (
                        bone, _fmt(p[0]), _fmt(p[1]), _fmt(p[2]),
                        _fmt(n[0]), _fmt(n[1]), _fmt(n[2]), _fmt(uv[0]), _fmt(uv[1])))
        f.write('end\n')


def write_animation(path, bones, frames):
    """frames: list (time) of list (bone) of (pos(3), R(3x3) or euler(3))."""
    with open(path, 'w', newline='\n') as f:
        f.write('version 1\n')
        write_nodes(f, bones)
        f.write('skeleton\n')
        for t, fr in enumerate(frames):
            f.write('time %d\n' % t)
            for i, (p, R) in enumerate(fr):
                R = np.asarray(R)
                r = matrix_to_euler(R) if R.shape == (3, 3) else R
                f.write('%d %s %s %s %s %s %s\n' % (i, _fmt(p[0]), _fmt(p[1]), _fmt(p[2]),
                                                     _fmt(r[0]), _fmt(r[1]), _fmt(r[2])))
        f.write('end\n')
