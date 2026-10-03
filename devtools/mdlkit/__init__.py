"""mdlkit - procedural GoldSrc studio model (.mdl v10) toolkit for the Vexmira Zombie package.

See README.md. Main entry points live in mdlkit.api (build_player_model, build_claws, build_vmodel,
build_pmodel, build_world_model) and the CLI (python3 -m mdlkit ...).
"""
import os

SP = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad'
STUDIOMDL = os.environ.get('MDLKIT_STUDIOMDL', os.path.join(SP, 'tools/smdl/studiomdl'))
PREVIEW_DIR = os.environ.get('MDLKIT_PREVIEWS', os.path.join(SP, 'previews'))
WORK_DIR = os.environ.get('MDLKIT_WORK', os.path.join(SP, 'mdlwork'))
REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
CSTRIKE = os.path.join(REPO, 'cstrike')
