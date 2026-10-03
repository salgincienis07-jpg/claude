"""mdlkit command line.

    cd devtools && python3 -m mdlkit <command> ...

commands:
  info FILE.mdl                     header / bones / sequences / hitboxes / textures summary
  validate FILE.mdl [--player|--v KIND|--p] [--budget BYTES] [--nine EXT,EXT]
  preview FILE.mdl [--out BASE] [--human|--zombie] [--v] [--seq NAME --frame F --view V]
  build MODULE:FUNC [--quick]       build a player model from a spec function (python module path)
  samples [walker|operator|claws|pak47|all] [--quick] [--lookdev]
  seqtable [--zombie]               print the CS player sequence table mdlkit generates
  test                              compile tiny test models and check studiomdl/engine conventions
"""
import os
import sys


def _arg(argv, name, default=None):
    if name in argv:
        i = argv.index(name)
        return argv[i + 1]
    return default


def main(argv):
    if not argv or argv[0] in ('-h', '--help', 'help'):
        print(__doc__)
        return 0
    cmd, rest = argv[0], argv[1:]
    if cmd == 'info':
        from .mdl_read import MDL
        m = MDL(rest[0])
        print(m.summary())
        print('bones:')
        for i, b in enumerate(m.bones):
            print('  %3d %-24s parent %3d' % (i, b['name'], b['parent']))
        print('sequences:')
        for s in m.seqs:
            print('  %3d %-26s fr=%3d fps=%5.1f bl=%d %s%s lm=%s ev=%d' % (
                s['index'], s['label'], s['numframes'], s['fps'], s['numblends'],
                s['activity_name'] if s['activity'] else '', ' loop' if s['flags'] & 1 else '',
                [round(float(x), 2) for x in s['linearmovement']], len(s['events'])))
        print('hitboxes:')
        for h in m.hitboxes:
            print('  group %d %-20s %s %s' % (h['group'], m.bone_names[h['bone']], h['bbmin'].round(2), h['bbmax'].round(2)))
        print('attachments:', [(m.bone_names[a['bone']], a['org'].round(2).tolist()) for a in m.attachments])
        print('textures:', [(t['name'], t['width'], t['height'], t['flags']) for t in m.textures])
        print('bodyparts:', [(b['name'], [(mm['name'], mm['numverts']) for mm in b['models']]) for b in m.bodyparts])
        return 0
    if cmd == 'validate':
        path = rest[0]
        if '--v' in rest:
            from .vmodel import validate_vmodel, _fmt
            rep = validate_vmodel(path, _arg(rest, '--v'), float(_arg(rest, '--budget', 0.4e6)))
            print(_fmt(rep))
        elif '--p' in rest:
            from .mdl_read import MDL
            m = MDL(path)
            print(m.summary(), m.bone_names)
            rep = {'errors': [] if 'Bip01 R Hand' in m.bone_names else ['no Bip01 R Hand bone']}
            print(rep)
        else:
            from .validate import validate_player, format_report
            nine = _arg(rest, '--nine')
            rep = validate_player(path, budget=float(_arg(rest, '--budget', 0)) or None,
                                  expect_nine=set(nine.split(',')) if nine else None)
            print(format_report(rep))
        return 1 if rep['errors'] else 0
    if cmd == 'preview':
        from . import preview as PV, PREVIEW_DIR
        from .mdl_read import MDL
        path = rest[0]
        base = _arg(rest, '--out', os.path.join(PREVIEW_DIR, 'mdlkit', os.path.splitext(os.path.basename(path))[0]))
        if '--seq' in rest:
            m = MDL(path)
            img = PV.render_pose(m, _arg(rest, '--seq'), float(_arg(rest, '--frame', 0)), view=_arg(rest, '--view', 'q'),
                                 gaitseq=m.seq_by_name.get('idle1'), W=400, H=500)
            img.save(base + '_single.png')
            print(base + '_single.png')
        elif '--v' in rest:
            from .vmodel import preview_vmodel
            print(preview_vmodel(path, base))
        elif os.path.basename(path).startswith('p_'):
            from .pmodel import preview_pmodel
            print(preview_pmodel(path, base))
        else:
            print(PV.player_previews(path, base, human='--zombie' not in rest))
        return 0
    if cmd == 'build':
        import importlib
        modname, func = rest[0].split(':')
        sys.path.insert(0, os.getcwd())
        mod = importlib.import_module(modname)
        spec = getattr(mod, func)()
        from .api import build_player_model
        build_player_model(spec, quick='--quick' in rest)
        return 0
    if cmd == 'samples':
        from .samples import main as smain
        smain(rest)
        return 0
    if cmd == 'seqtable':
        from .anims import sequence_table
        for i, sd in enumerate(sequence_table({'knife'} if '--zombie' in rest else None)):
            print('%3d %-26s %-8s %-18s %s' % (i, sd.name, sd.kind, sd.activity or '', '9-blend' if sd.nine and sd.kind == 'upper' else ''))
        return 0
    if cmd == 'test':
        from .tests.test_conventions import main as tmain
        return 0 if tmain() else 1
    print(__doc__)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
