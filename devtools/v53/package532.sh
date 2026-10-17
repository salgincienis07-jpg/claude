#!/bin/bash
# Vexmira 5.3.2 delivery zip: ONLY files changed/new since 5.3.1 + the full zm_vexmira_7door map (bsp, nav, res,
# map ini and every file its .res lists). Usage: devtools/v53/package532.sh <amxx_dir> <out.zip>
set -e
REPO=$(cd "$(dirname "$0")/../.." && pwd)
AMXX=${1:?amxx dir}
OUT=${2:?out zip}
STAGE=$(mktemp -d)
C=$STAGE/cstrike
R=$REPO/cstrike
mkdir -p $C/addons/amxmodx/{scripting,plugins,configs/vexmira_maps,data/lang} $C/sprites/vexmira $C/maps
# plugins + single config + language
cp $R/addons/amxmodx/scripting/vexmira_core.sma $R/addons/amxmodx/scripting/vexmira_gear.sma $C/addons/amxmodx/scripting/
cp $AMXX/vexmira_core.amxx $AMXX/vexmira_gear.amxx $C/addons/amxmodx/plugins/
cp $R/addons/amxmodx/configs/vexmira.cfg $C/addons/amxmodx/configs/
cp $R/addons/amxmodx/data/lang/vexmira_zombie.txt $C/addons/amxmodx/data/lang/
# new 5.3.2 sprites: smooth additive effects + big screen cards
cp -r $R/sprites/vexmira/fx532 $R/sprites/vexmira/c532 $C/sprites/vexmira/
# 7door map
cp $R/maps/zm_vexmira_7door.bsp $R/maps/zm_vexmira_7door.nav $R/maps/zm_vexmira_7door.res $C/maps/
cp $R/addons/amxmodx/configs/vexmira_maps/zm_vexmira_7door.ini $C/addons/amxmodx/configs/vexmira_maps/
grep -v '^//' $R/maps/zm_vexmira_7door.res | tr -d '\r' | while read -r f; do
  [ -z "$f" ] && continue
  mkdir -p "$C/$(dirname "$f")"
  cp "$R/$f" "$C/$f"
done
cp $REPO/devtools/v53/KURULUM_5.3.2.txt $STAGE/
rm -f "$OUT"
(cd $STAGE && zip -qr9 "$OUT" .)
echo "$OUT $(du -h "$OUT" | cut -f1) $(cd $STAGE && find . -type f | wc -l) files"
rm -rf $STAGE
