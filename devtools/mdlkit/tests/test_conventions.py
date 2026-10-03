"""Compile tiny models and verify the studiomdl/engine conventions mdlkit relies on.

Run: python3 -m mdlkit.tests.test_conventions   (from devtools/)
Checks:
  1. `$origin 0 0 0 -90` -> animation root stored un-rotated (zrotation = 0).
  2. compiled triangles are clockwise seen from outside (quake order) for CCW-outward SMD input.
  3. UV v=1 maps to the top row of the BMP (t=0) and u=0 to column 0.
  4. $eyeposition mapping.
  5. bone order preserved from the reference SMD node list; unreferenced bones are dropped.
"""
import math
import os
import shutil
import numpy as np

from mdlkit import WORK_DIR, PREVIEW_DIR
from mdlkit.geom import box, pack_atlas
from mdlkit.smd import write_reference, write_animation
from mdlkit.qc import QC, Sequence
from mdlkit.bmp8 import write_bmp8
from mdlkit.compile import run_studiomdl
from mdlkit.mdl_read import MDL
from mdlkit import preview
from mdlkit.mathx import euler_to_matrix, rot_z


def main():
    wd = os.path.join(WORK_DIR, 'test_conventions')
    shutil.rmtree(wd, ignore_errors=True)
    os.makedirs(wd)
    bones = [dict(name='root', parent=-1), dict(name='arm', parent=0), dict(name='unused', parent=0)]
    rest = [(np.zeros(3), np.eye(3)), (np.array([10.0, 0, 0]), np.eye(3)), (np.array([0, 0, 5.0]), np.eye(3))]
    b0 = box((8, 8, 8), center=(0, 0, 0), bone=0, mat='a')
    b1 = box((12, 4, 4), center=(16, 0, 0), bone=1, mat='a')
    meshes = [b0, b1]
    pages = pack_atlas(meshes, 64, 64, 1, tex_prefix='tex')
    # texture: top-left quadrant red, top-right green, bottom-left blue, bottom-right white
    idx = np.zeros((64, 64), np.uint8)
    idx[:32, :32] = 1; idx[:32, 32:] = 2; idx[32:, :32] = 3; idx[32:, 32:] = 4
    pal = np.zeros((256, 3), np.uint8)
    pal[1] = (255, 0, 0); pal[2] = (0, 255, 0); pal[3] = (0, 0, 255); pal[4] = (255, 255, 255)
    write_bmp8(os.path.join(wd, pages[0]['name']), idx, pal)
    from mdlkit.api import uv_span_meshes
    write_reference(os.path.join(wd, 'ref.smd'), bones, rest, uv_span_meshes(pages, 0) + meshes)
    # animation: root rotated +30deg yaw, translated (1,2,3)
    fr = [[(np.array([1.0, 2, 3]), rot_z(math.radians(30))), (np.array([10.0, 0, 0]), np.eye(3)),
           (np.array([0, 0, 5.0]), np.eye(3))]] * 2
    write_animation(os.path.join(wd, 'idle.smd'), bones, fr)
    q = QC('test.mdl')
    q.body('body', 'ref')
    q.eye = (3, 4, 5)
    q.add(Sequence('idle', ['idle'], fps=10, loop=True))
    q.write(os.path.join(wd, 'test.qc'))
    path, log = run_studiomdl(wd, 'test.qc', extra_args=['-p'])
    m = MDL(path)
    ok = True
    # 1. zrotation
    vals = m.anim_values(0, 0)[0]
    print('root anim pos', vals[0, :3], 'rot', vals[0, 3:])
    if not (np.allclose(vals[0, :3], [1, 2, 3], atol=0.01) and abs(vals[0, 5] - math.radians(30)) < 1e-3):
        print('FAIL zrotation'); ok = False
    # 5. bone order / unused dropped
    print('bones', m.bone_names)
    if m.bone_names != ['root', 'arm']:
        print('FAIL bone list'); ok = False
    # 4. eye
    print('eye', m.eyeposition)
    if not np.allclose(m.eyeposition, [3, 4, 5]):
        print('FAIL eye'); ok = False
    # 2. winding: compare compiled winding normal with stored vertex normals
    mod = m.bodyparts[0]['models'][0]
    agree = 0; total = 0
    for me in mod['meshes']:
        for t in me['tris']:
            v = [mod['verts'][x[0]] + 0 for x in t]
            # bring to model space using bone of vertex (rest == identity rotations here)
            n = mod['norms'][t[0][1]]
            fn = np.cross(v[1] - v[0], v[2] - v[0])
            total += 1
            agree += np.dot(fn, n) < 0
    print('compiled tris clockwise-from-outside: %d/%d' % (agree, total))
    if agree != total:
        print('FAIL winding'); ok = False
    # 3. uv: find a vertex whose source uv v is max -> t should be small
    tex = m.textures[0]
    print('texture', tex['name'], tex['width'], tex['height'])
    sts = np.array([x[2:4] for me in mod['meshes'] for t in me['tris'] for x in t])
    print('s range', sts[:, 0].min(), sts[:, 0].max(), 't range', sts[:, 1].min(), sts[:, 1].max())
    # check row 0 of stored texture is the top row of our BMP (red/green)
    if not (tuple(tex['palette'][tex['pixels'][0, 0]]) == (255, 0, 0)):
        print('FAIL texture row order'); ok = False
    # 6. skin stored bit-exact (no crop/shift thanks to uv_span, palette exact thanks to $gamma 1.799)
    from mdlkit.bmp8 import read_bmp8
    sidx, spal = read_bmp8(os.path.join(wd, pages[0]['name']))
    if not (np.array_equal(sidx, tex['pixels']) and np.array_equal(spal, tex['palette'])):
        print('FAIL skin not bit-exact'); ok = False
    # 7. every compiled (s,t) equals the texel edge pack_atlas predicted
    pred = set()
    for mm in meshes:
        for i in range(len(mm.v)):
            pred.add((int(mm.attrs['_px'][i]), int(mm.attrs['_py'][i])))
    got = set((int(x[2]), int(x[3])) for me in mod['meshes'] for t in me['tris'] for x in t)
    got -= {(0, 0), (63, 0), (63, 63), (0, 63)}   # uv span corners
    if not got <= pred:
        print('FAIL uv mapping', sorted(got - pred)[:5]); ok = False
    else:
        print('uv mapping exact: %d texel coords' % len(got))
    # render
    img = preview.grid([preview.render_pose(m, 0, view=v, W=200, H=200, title=v, player=False)
                        for v in ('front', 'q', 'left', 'top')], 4)
    out = os.path.join(PREVIEW_DIR, 'mdlkit', 'test_conventions.png')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print('preview', out)
    print('ALL OK' if ok else 'SOME FAILURES')
    return ok


if __name__ == '__main__':
    main()
