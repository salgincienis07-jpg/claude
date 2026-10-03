#!/bin/bash
# Reproducible build of the HLSDK studiomdl (Linux port) used by devtools/mdlkit.
#
#   devtools/mdlkit/build_studiomdl.sh [OUT_DIR]        (default: $SP/tools/smdl)
#
# Clones ValveSoftware/halflife (pinned commit), copies the studiomdl + common utility sources into a
# build directory, applies the small portability edits below with sed (no Valve source is stored in this
# repository), writes two tiny compatibility headers and compiles a 32-bit binary (studiomdl stores
# pointers in 32-bit fields, so it must be built -m32; needs gcc-multilib / 32-bit libc).
# Stock limits are unchanged (MAXSTUDIOGROUPS 16 -> up to 16 blends per sequence, MAXSTUDIOVERTS 2048).
set -euo pipefail
SP=/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad
OUT=${1:-$SP/tools/smdl}
HLSDK_COMMIT=b1b5cf5892918535619b2937bb927e46cb097ba1
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

if [ -d "$SP/tools/hlsdk/.git" ] && [ -z "${FORCE_CLONE:-}" ]; then
    SRC=$SP/tools/hlsdk
else
    git clone --quiet --filter=blob:none --no-checkout https://github.com/ValveSoftware/halflife.git "$WORK/hlsdk"
    git -C "$WORK/hlsdk" checkout --quiet $HLSDK_COMMIT -- utils/studiomdl utils/common engine/studio.h common/studio_event.h dlls/activity.h dlls/activitymap.h
    SRC=$WORK/hlsdk
fi

B=$WORK/build
mkdir -p "$B/inc/engine" "$B/inc/dlls"
cp "$SRC"/utils/studiomdl/{studiomdl.c,studiomdl.h,write.c,tristrip.c,bmpread.c} "$B/"
cp "$SRC"/utils/common/{cmdlib.c,cmdlib.h,lbmlib.c,lbmlib.h,mathlib.c,mathlib.h,scriplib.c,scriplib.h} "$B/"
cp "$SRC"/engine/studio.h "$B/inc/engine/"
cp "$SRC"/common/studio_event.h "$B/inc/engine/"
cp "$SRC"/common/studio_event.h "$B/"
cp "$SRC"/dlls/activity.h "$SRC"/dlls/activitymap.h "$B/inc/dlls/"

cat > "$B/linux_compat.h" <<'EOF'
#ifndef LINUX_COMPAT_H
#define LINUX_COMPAT_H
#include <strings.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define gamma studiomdl_gamma
#include <stdint.h>
typedef uint8_t BYTE; typedef uint16_t WORD; typedef uint32_t DWORD; typedef uint32_t ULONG; typedef int32_t LONG;
#pragma pack(push,1)
typedef struct { WORD bfType; DWORD bfSize; WORD bfReserved1; WORD bfReserved2; DWORD bfOffBits; } BITMAPFILEHEADER;
typedef struct { DWORD biSize; LONG biWidth; LONG biHeight; WORD biPlanes; WORD biBitCount; DWORD biCompression;
                 DWORD biSizeImage; LONG biXPelsPerMeter; LONG biYPelsPerMeter; DWORD biClrUsed; DWORD biClrImportant; } BITMAPINFOHEADER;
typedef struct { BYTE rgbBlue; BYTE rgbGreen; BYTE rgbRed; BYTE rgbReserved; } RGBQUAD;
#pragma pack(pop)
#define BI_RGB 0
#define MAKEWORD(a,b) ((WORD)(((BYTE)(a))|(((WORD)((BYTE)(b)))<<8)))
#define strcmpi strcasecmp
#ifndef min
#define min(a,b) (((a)<(b))?(a):(b))
#define max(a,b) (((a)>(b))?(a):(b))
#endif
#define stricmp strcasecmp
#define strnicmp strncasecmp
#define _stricmp strcasecmp
#define _strnicmp strncasecmp
#define _mkdir(p) mkdir((p), 0777)
#endif
EOF
cat > "$B/archtypes.h" <<'EOF'
#ifndef ARCHTYPES_H
#define ARCHTYPES_H
#include <stdint.h>
typedef int32_t int32; typedef uint32_t uint32; typedef int16_t int16; typedef uint16_t uint16; typedef int64_t int64; typedef uint64_t uint64;
#endif
EOF
cd "$B"
# --- portability edits (Windows headers / backslash include paths) ---
sed -i 's|#include <windows.h>|#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <stdint.h>\n#include "linux_compat.h"|; s|#include <STDIO.H>||; s|bmih.biCompression != BI_RGB|bmih.biCompression != 0|' bmpread.c
sed -i 's|#include <direct.h>|#include "linux_compat.h"|' cmdlib.c
sed -i 's|#include <WINDOWS.H>|#include "linux_compat.h"|; s|#include <STDIO.H>|#include <stdio.h>|' lbmlib.c
sed -i 's|^typedef short\t\t\tWORD;|// WORD: linux_compat.h|; s|^typedef long\t\t\tLONG;|// LONG: linux_compat.h|' lbmlib.h
sed -i 's|#include "../../engine/studio.h"|#include "linux_compat.h"\n#include "engine/studio.h"|; s|#include "../../dlls/activity.h"|#include "dlls/activity.h"|; s|#include "../../dlls/activitymap.h"|#include "dlls/activitymap.h"|' studiomdl.c
sed -i 's|^#include ".*engine.studio\.h"|#include "engine/studio.h"|' tristrip.c write.c
# cmdlib.c only includes linux_compat.h under WIN32; make sure it is always included
sed -i '1i #include "linux_compat.h"' *.c
gcc -m32 -O2 -w -fcommon -I. -Iinc -o studiomdl studiomdl.c write.c tristrip.c bmpread.c cmdlib.c lbmlib.c mathlib.c scriplib.c -lm
mkdir -p "$OUT"
cp studiomdl "$OUT/studiomdl"
echo "built $OUT/studiomdl"
"$OUT/studiomdl" 2>&1 | head -2 || true
