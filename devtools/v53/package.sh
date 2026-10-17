#!/bin/bash
# Vexmira 5.3.1 delivery zip: plugins (.sma + compiled .amxx), single config, lang, and the NEW assets only
# (skies, infection bomb + laser mine models, CSO cards). Usage: devtools/v53/package.sh <amxx_dir> <out.zip>
set -e
REPO=$(cd "$(dirname "$0")/../.." && pwd)
AMXX=${1:?amxx dir}
OUT=${2:?out zip}
STAGE=$(mktemp -d)
C=$STAGE/cstrike
mkdir -p $C/addons/amxmodx/{scripting,plugins,configs,data/lang} $C/gfx/env $C/models/vexmira $C/sprites/vexmira
R=$REPO/cstrike
cp $R/addons/amxmodx/scripting/vexmira_core.sma $R/addons/amxmodx/scripting/vexmira_gear.sma $C/addons/amxmodx/scripting/
cp $AMXX/vexmira_core.amxx $AMXX/vexmira_gear.amxx $C/addons/amxmodx/plugins/
cp $R/addons/amxmodx/configs/vexmira.cfg $R/addons/amxmodx/configs/plugins-vexmira.ini $C/addons/amxmodx/configs/
cp $R/addons/amxmodx/data/lang/vexmira_zombie.txt $R/addons/amxmodx/data/lang/vexmira_epic.txt $C/addons/amxmodx/data/lang/
for t in blood toxic void inferno eclipse deadlight; do cp $R/gfx/env/vexmira_${t}*.tga $C/gfx/env/; done
cp -r $R/models/vexmira/nades $R/models/vexmira/lasermine $C/models/vexmira/
cp -r $R/sprites/vexmira/cso $C/sprites/vexmira/
cp $REPO/devtools/v53/KURULUM_5.3.1.txt $STAGE/
rm -f "$OUT"
(cd $STAGE && zip -qr9 "$OUT" .)
rm -rf $STAGE
echo "$OUT $(du -h "$OUT" | cut -f1)"
