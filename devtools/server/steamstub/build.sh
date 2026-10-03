#!/bin/bash
# Build the offline libsteam_api.so stub (32-bit) against ReHLDS' Steam SDK headers.
#   devtools/server/steamstub/build.sh [rehlds_source_dir] [out]
set -e
SP=/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad
REHLDS=${1:-$SP/srvx/rehlds-src}
OUT=${2:-$SP/server/libsteam_api.so}
if [ ! -f "$REHLDS/rehlds/public/steam/steam_gameserver.h" ]; then
  git clone --depth 1 --filter=blob:none --sparse https://github.com/dreamstalker/rehlds.git "$REHLDS"
  git -C "$REHLDS" sparse-checkout set rehlds/public rehlds/common
fi
HERE=$(cd "$(dirname "$0")" && pwd)
g++ -m32 -O2 -shared -fPIC -fvisibility=hidden -std=c++11 -w \
  -I"$HERE/inc" -I"$REHLDS/rehlds/public/steam" -I"$REHLDS/rehlds/public" -I"$REHLDS/rehlds/common" \
  -o "$OUT" "$HERE/steam_stub.cpp" -static-libstdc++ -static-libgcc
echo "built $OUT ($(stat -c %s "$OUT") bytes)"
