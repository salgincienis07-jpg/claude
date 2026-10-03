#!/usr/bin/env bash
# Build seedee's SDHLT map compilers (sdHLCSG/BSP/VIS/RAD/RIPENT) on Linux.
#
#   devtools/mapkit/build_sdhlt.sh [DEST]          (default: devtools/mapkit/.sdhlt)
#   SDHLT_REF=<commit|tag> devtools/mapkit/build_sdhlt.sh
#
# Binaries + sdhlt.wad + lights.rad end up in $DEST/tools; compile.py finds
# them there automatically (or point SDHLT_TOOLS at any other build).
# Requirements: git, cmake >= 3.20, g++ (C++17), make.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="${1:-$HERE/.sdhlt}"
REF="${SDHLT_REF:-df45198b3c03a5a09e9d1aead9c9457e51753e39}"   # tested with mapkit
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"

if [ ! -d "$DEST/.git" ]; then
    git clone https://github.com/seedee/SDHLT.git "$DEST"
fi
git -C "$DEST" fetch --quiet origin || true
git -C "$DEST" checkout --quiet "$REF"

cmake -S "$DEST" -B "$DEST/build" -DCMAKE_BUILD_TYPE=Release > "$DEST/build-cmake.log"
cmake --build "$DEST/build" -j "$JOBS" > "$DEST/build-make.log" 2>&1 || { tail -40 "$DEST/build-make.log"; exit 1; }

for t in sdHLCSG sdHLBSP sdHLVIS sdHLRAD sdRIPENT; do
    test -x "$DEST/tools/$t" || { echo "missing $t"; exit 1; }
done
test -f "$DEST/tools/sdhlt.wad" || { echo "missing sdhlt.wad"; exit 1; }
echo "SDHLT ($REF) built in $DEST/tools"
echo "use: export SDHLT_TOOLS=$DEST/tools"
