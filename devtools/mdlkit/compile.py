"""Run studiomdl on a generated work directory and return the compiled file path."""
import os
import shutil
import subprocess

from . import STUDIOMDL


class CompileError(RuntimeError):
    pass


def run_studiomdl(workdir, qc_name, out_path=None, extra_args=(), timeout=300):
    """Compile workdir/qc_name. $modelname inside the QC must be a bare file name (written into
    workdir). Moves the result to out_path if given. Returns (out_path, log)."""
    if not os.path.exists(STUDIOMDL):
        raise CompileError('studiomdl not found at %s (build it with devtools/mdlkit/build_studiomdl.sh)' % STUDIOMDL)
    cmd = [STUDIOMDL] + list(extra_args) + [qc_name]
    p = subprocess.run(cmd, cwd=workdir, capture_output=True, text=True, timeout=timeout)
    log = p.stdout + p.stderr
    with open(os.path.join(workdir, 'studiomdl.log'), 'w') as f:
        f.write(log)
    # studiomdl's Error() exits with code 1; some failures only print "ERROR"
    with open(os.path.join(workdir, qc_name)) as f:
        for line in f:
            if line.startswith('$modelname'):
                mdlname = line.split('"')[1]
                break
        else:
            raise CompileError('no $modelname in qc')
    built = os.path.join(workdir, mdlname)
    if p.returncode != 0 or not os.path.exists(built) or '*** ERROR ***' in log:
        raise CompileError('studiomdl failed (rc=%d):\n%s' % (p.returncode, log[-4000:]))
    for bad in ('illegal parent bone', 'too many', 'unknown studio command', 'unknown bone',
                'unknown attachment', 'cannot find bone', 'misdirected normals'):
        if bad in log:
            raise CompileError('studiomdl reported "%s":\n%s' % (bad, log[-4000:]))
    if out_path:
        os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
        shutil.copyfile(built, out_path)
        return out_path, log
    return built, log
