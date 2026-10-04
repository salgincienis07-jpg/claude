#!/bin/bash
# Derleme: vexmira_zombie.sma (bu betigin bulundugu depo / worktree) -> $1 (varsayilan scratchpad/test.amxx)
# Kaynak TEK dosya (proje include dosyasi yok); yalniz AMXX 1.10 + ReAPI include dizini kullanilir.
T=/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/tools/bin
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SCR="$REPO/cstrike/addons/amxmodx/scripting"
SRC="$SCR/vexmira_zombie.sma"
OUT=${1:-/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/test.amxx}
cd $T && ./amxxpc "$SRC" -i$T/include -o"$OUT" 2>&1 | grep -v "^AMX Mod X Compiler\|^Copyright"
