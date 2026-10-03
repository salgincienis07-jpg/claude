"""Content API for model agents: everything a spec module needs, in one import.

    from mdlkit.content import *

Write one module per area under devtools/mdlkit/content/ (e.g. content/zombies.py, content/bosses.py,
content/weapons.py, content/world.py). Each public function returns a spec (dict) or a list of specs;
build with

    cd devtools
    python3 -m mdlkit build mdlkit.content.zombies:runner              # one spec function
    python3 -m mdlkit build mdlkit.content.zombies:runner --lookdev    # textures only, seconds
    python3 -m mdlkit build mdlkit.content.zombies:runner --quick      # small textures / no AO
    python3 -m mdlkit build content/zombies.py:all                     # file path form, list of specs

Spec kinds (key 'kind', default 'player'):
  player  -> api.build_player_model(spec)   players: humans / zombies / bosses (see README "Character spec")
             spec['claws'] = True | dict(out=..., style=...) also builds models/vexmira/claws/v_<short>.mdl
  claws   -> vmodel.build_claws(spec['of'], out)              claws from a player spec ('of')
  vhuman  -> vmodel.build_human_vmodel(name, vkind, gun_meshes=..., ...)   v_ knife/grenades/special guns
  pmodel  -> guns.build_standard_pmodel(weapon, ...) or pmodel.build_pmodel(name, meshes, out, ...)
  world   -> world.build_world_model(name, parts, sequences, bodygroups=..., ...)
See content/examples.py for one complete example of every kind.
"""
import math
import os
import numpy as np

from .. import CSTRIKE, PREVIEW_DIR, WORK_DIR, SP
from ..rig_cs import RigSpec, Rig, GRIP_R, GRIP_L, FOOT_Z, CROUCH_FOOT_Z
from ..anims import ypr, keys, Style
from ..geom import (Mesh, box, ellipsoid, dome, sphere, lathe, tube, cylinder, cone, capsule, horn, extrude, ribbon,
                    noise_displace, flat_shaded)
from ..accessories import ACCESSORIES, tail_extras, wing_extras, limb_extras
from ..api import build_player_model, preview_textures, BuildError
from ..vmodel import build_claws, build_vmodel, build_human_vmodel, WEAPON_SETS, VIEW_HOLD, HUMAN_V_GUN
from ..pmodel import gun_preset, build_pmodel, preview_pmodel, BORE_Z, GUN_MATERIALS
from ..pmodel import (receiver, barrel, handguard, pistol_grip, magazine, stock, scope, rail, muzzle_brake,
                      front_sight, trigger_guard, glow_strip)
from ..guns import STANDARD, standard_gun, standard_materials, build_standard_pmodel, side, rod, bx
from ..world import build_world_model, on, Bone, world_body_value
from ..body import face_anchor

# ------------------------------------------------------------------------------------------ palette
VEX_PURPLE = (160, 90, 255)
VEX_CYAN = (0, 220, 255)
HUMAN_INFO = (0, 200, 255)
ZOMBIE_INFO = (120, 255, 40)
DANGER = (255, 40, 40)
GOLD = (255, 215, 0)

# zombie class index -> (model short name, CLASS_RGB) - DESIGN_v3.md section 3 / plugin CLASS_RGB
CLASSES = [
    ('walker', (0, 140, 0)), ('runner', (255, 140, 0)), ('tank', (40, 90, 255)), ('banshee', (200, 200, 255)),
    ('leech', (200, 0, 0)), ('stalker', (0, 110, 110)), ('bomber', (120, 255, 0)), ('frost', (0, 200, 255)),
    ('spitter', (150, 255, 0)), ('hulk', (255, 80, 0)), ('voodoo', (255, 0, 180)), ('phantom', (120, 120, 255)),
    ('butcher', (180, 30, 30)), ('hunter', (90, 90, 110)), ('charger', (200, 120, 60)), ('arachne', (140, 0, 200)),
    ('magma', (255, 90, 0)), ('volt', (80, 180, 255)), ('mimic', (160, 160, 160)), ('burrower', (140, 100, 50)),
    ('siren', (255, 90, 200)), ('bulwark', (120, 140, 120)), ('sporemother', (110, 200, 60)), ('nightmare', (120, 0, 0)),
]
CLASS_RGB = {n: c for n, c in CLASSES}
# boss index -> (short name, BOSS_RGB)
BOSSES = [('brute', (255, 120, 0)), ('banshee', (190, 210, 255)), ('overlord', (160, 0, 255)), ('inferno', (255, 50, 0)),
          ('reaper', (120, 0, 190)), ('frostlord', (0, 190, 255)), ('stormcaller', (255, 240, 80)),
          ('hivequeen', (110, 255, 0)), ('void', (220, 0, 140))]
BOSS_RGB = {n: c for n, c in BOSSES}

# size budgets in bytes (DESIGN_v3.md section 10)
BUDGET = dict(human=1.0e6, zombie=0.45e6, boss=0.7e6, claws=0.2e6, p=0.08e6, v_human=0.4e6, world=0.25e6)


# ------------------------------------------------------------------------------------------ paths
def player_out(name):
    return os.path.join(CSTRIKE, 'models/player', name, name + '.mdl')


def claws_out(short):
    """short = model name without vex_z_ / vex_b_ / vex_ (e.g. 'walker', 'brute', 'nemesis')."""
    return os.path.join(CSTRIKE, 'models/vexmira/claws', 'v_%s.mdl' % short)


def weapon_out(name):
    return os.path.join(CSTRIKE, 'models/vexmira/weapons', name + '.mdl')


def world_out(name):
    return os.path.join(CSTRIKE, 'models/vexmira/world', name + '.mdl')


def short_name(model_name):
    for pre in ('vex_z_', 'vex_b_', 'vex_'):
        if model_name.startswith(pre):
            return model_name[len(pre):]
    return model_name


# ------------------------------------------------------------------------------------------ materials
def skin(color, seed=1, **kw):
    return dict({'type': 'skin', 'color': color, 'variation': 0.12, 'seed': seed}, **kw)


def cloth(color, seed=1, **kw):
    return dict({'type': 'cloth', 'color': color, 'weave': 0.1, 'dirt': 0.4, 'seed': seed}, **kw)


def metal(color, seed=1, **kw):
    return dict({'type': 'metal', 'color': color, 'scratches': 0.4, 'shine': 0.35, 'edge_wear': 0.6, 'seed': seed}, **kw)


def glow(color, color2=None, **kw):
    return dict({'type': 'glow', 'color': color, 'color2': color2 or tuple(min(255, int(c * 0.4 + 160)) for c in color)}, **kw)


def layers(base, *layer_list):
    """layers(base_mat, (mat, where_dict), (mat, where_dict, edge_rgb), ...)"""
    L = []
    for item in layer_list:
        d = {'mat': item[0], 'where': item[1]}
        if len(item) > 2:
            d['edge'] = item[2]
        L.append(d)
    return {'type': 'layers', 'base': base, 'layers': L}


# ------------------------------------------------------------------------------------------ build dispatch
def build(spec, quick=False, lookdev=False, preview=True):
    """Build one spec of any kind (see module doc). Returns the report (list of reports for a player
    spec with claws)."""
    kind = spec.get('kind', 'player')
    if kind == 'player':
        if lookdev:
            return preview_textures(spec, quick=quick)
        rep = build_player_model(spec, quick=quick, preview=preview)
        cl = spec.get('claws')
        if cl:
            cl = cl if isinstance(cl, dict) else {}
            out = cl.get('out') or claws_out(short_name(spec['name']))
            crep = build_claws(spec, out, style=cl.get('style'), tex=cl.get('tex', (256, 256)),
                               budget=cl.get('budget', BUDGET['claws']))
            return [rep, crep]
        return rep
    if kind == 'claws':
        return build_claws(spec['of'], spec.get('out') or claws_out(short_name(spec['of']['name'])),
                           style=spec.get('style'), tex=spec.get('tex', (256, 256)), budget=spec.get('budget', BUDGET['claws']))
    if kind == 'vhuman':
        return build_human_vmodel(spec['name'], spec['vkind'], gun_meshes=spec.get('gun'), out=spec.get('out'),
                                  arms_spec=spec.get('arms'), materials=spec.get('materials'), sounds=spec.get('sounds'),
                                  muzzle=spec.get('muzzle'), tex=spec.get('tex', (256, 256)), style=spec.get('style'),
                                  budget=spec.get('budget', BUDGET['v_human']), preview=preview)
    if kind == 'pmodel':
        if spec.get('weapon') and spec.get('meshes') is None:
            return build_standard_pmodel(spec['weapon'], out=spec.get('out'), palette=spec.get('materials'),
                                         name=spec.get('name'), tex=spec.get('tex', (128, 128)), preview=preview,
                                         preview_area=spec.get('preview_area', 'mdlkit'))
        if spec.get('weapon'):
            return build_standard_pmodel(spec['weapon'], out=spec.get('out'), palette=spec.get('materials'),
                                         meshes=spec['meshes'], name=spec.get('name'), tex=spec.get('tex', (128, 128)),
                                         preview=preview, preview_area=spec.get('preview_area', 'mdlkit'))
        rep = build_pmodel(spec['name'], spec['meshes'], spec.get('out') or weapon_out(spec['name']),
                           materials=spec.get('materials'), dual=spec.get('dual', False), tex=spec.get('tex', (128, 128)),
                           preview=False)
        if preview:
            rep['previews'] = preview_pmodel(rep['out'], os.path.join(PREVIEW_DIR, spec.get('preview_area', 'mdlkit'),
                                                                      spec['name']), ext=spec.get('ext', 'rifle'))
        return rep
    if kind == 'world':
        kw = {k: v for k, v in spec.items() if k not in ('kind', 'name', 'parts')}
        kw.setdefault('preview', preview)
        return build_world_model(spec['name'], spec['parts'], **kw)
    raise ValueError('unknown spec kind %r' % kind)


__all__ = [n for n in dir() if not n.startswith('_')]
