#!/bin/bash
# Derleme: vexmira_zombie.sma -> scratchpad/test.amxx
T=/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/tools/bin
SRC=/home/user/claude/cstrike/addons/amxmodx/scripting/vexmira_zombie.sma
OUT=${1:-/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/test.amxx}
cd $T && ./amxxpc $SRC -i$T/include -o$OUT 2>&1 | grep -v "^AMX Mod X Compiler\|^Copyright"
