#!/bin/bash
# Vexmira Zombie 3.1 paketi: HEAD'deki cstrike/ (v1 oyuncu/pence modelleri, p_ak47, pilot HARIC) + derlenmis eklenti + belgeler
set -e
SP=/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad
REPO=/home/user/claude
REV=$(cd $REPO && git rev-parse HEAD)
NAME=Vexmira_Zombie_v3.2_ARA
D=$SP/interim/$NAME
rm -rf "$D"; mkdir -p "$D"
cd "$REPO"
git archive "$REV" cstrike | tar -x -C "$D"
rm -rf \
       "$D"/cstrike/models/vexmira/weapons/p_* "$D"/cstrike/maps/zm_vex_pilot.*
bash devtools/plugin/build_plugin.sh "$D/cstrike/addons/amxmodx/plugins/vexmira_zombie.amxx" | tail -1
git show "$REV:KURULUM_OKU.txt" > "$D/KURULUM_OKU.txt"
git show "$REV:DEGISIKLIKLER_v2.0.txt" > "$D/DEGISIKLIKLER_v2.0.txt"
cp -p $SP/SURUM_v3.2_OKU.txt "$D/"
cd $SP/interim && rm -f "$NAME.zip" && zip -qr9 "$NAME.zip" "$NAME"
cp -p "$SP/interim/$NAME.zip" "$REPO/$NAME.zip"
ls -la "$REPO/$NAME.zip"; du -sh "$D"
