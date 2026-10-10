#!/bin/bash
# Vexmira Zombie 3.5 paketi: HEAD'deki cstrike/ (p_ modelleri ve pilot test haritasi HARIC) + derlenmis eklenti + belgeler
set -e
SP=/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad
REPO=/home/user/claude
REV=$(cd $REPO && git rev-parse HEAD)
NAME=Vexmira_Zombie_v3.5
D=/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/interim/Vexmira_Zombie_v3.5
rm -rf /tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/interim/Vexmira_Zombie_v3.5
mkdir -p "$D"
cd "$REPO"
git archive "$REV" cstrike | tar -x -C "$D"
rm -f "$D"/cstrike/models/vexmira/weapons/p_* "$D"/cstrike/maps/zm_vex_pilot.*
(cd $SP/tools/bin && ./amxxpc "$D/cstrike/addons/amxmodx/scripting/vexmira_zombie.sma" -i$SP/tools/bin/include -o"$D/cstrike/addons/amxmodx/plugins/vexmira_zombie.amxx" | tail -2)
git show "$REV:KURULUM_OKU.txt" > "$D/KURULUM_OKU.txt"
git show "$REV:DEGISIKLIKLER_v2.0.txt" > "$D/DEGISIKLIKLER_v2.0.txt"
git show "$REV:devtools/release/SURUM_v3.2_OKU.txt" > "$D/SURUM_v3.2_OKU.txt"
git show "$REV:devtools/release/SURUM_v3.5_OKU.txt" > "$D/SURUM_v3.5_OKU.txt"
rm -f /tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/Vexmira_Zombie_v3.5.zip
cd $SP/interim && zip -qr9 "$SP/$NAME.zip" "$NAME"
ls -la "$SP/$NAME.zip"; du -sh "$D"
