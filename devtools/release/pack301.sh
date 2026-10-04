#!/bin/bash
# Vexmira Zombie 3.0.1 ARA paketi: depodaki cstrike/ (v1 oyuncu + pence modelleri ve p_ak47 HARIC) + belgeler -> zip
set -e
SP=/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad
REPO=/home/user/claude
NAME=Vexmira_Zombie_v3.0.1_ARA
D=$SP/interim/$NAME
rm -rf "$D"; mkdir -p "$D"
cd "$REPO"
git ls-files cstrike | grep -v \
  -e '^cstrike/models/player/vex_' \
  -e '^cstrike/models/vexmira/claws/' \
  -e '^cstrike/models/vexmira/weapons/p_' \
  -e '^cstrike/maps/zm_vex_pilot' \
  > $SP/pack301.list
# derlenmis eklenti: guncel .sma'dan
bash devtools/plugin/build_plugin.sh "$REPO/cstrike/addons/amxmodx/plugins/vexmira_zombie.amxx" >/dev/null 2>&1 || \
  bash $SP/build.sh "$REPO/cstrike/addons/amxmodx/plugins/vexmira_zombie.amxx"
while read -r f; do
  mkdir -p "$D/$(dirname "$f")"; cp -p "$f" "$D/$f"
done < $SP/pack301.list
cp -p KURULUM_OKU.txt DEGISIKLIKLER_v2.0.txt "$D/"
cp -p $SP/ARA_SURUM_v3.0.1_OKU.txt "$D/"
# haritada oylama icin mapcycle: yalniz mevcut harita
printf 'zm_vex_laboratory\n' > "$D/cstrike/mapcycle_vexmira.txt"
cd $SP/interim && rm -f "$NAME.zip" && zip -qr9 "$NAME.zip" "$NAME"
cp -p "$SP/interim/$NAME.zip" "$REPO/$NAME.zip"
ls -la "$REPO/$NAME.zip"; du -sh "$D"
