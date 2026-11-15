#!/bin/bash
# Build SDL3 3.4.12 as a static library for AROS_TARGET, outside the AROS
# build system — same recipe as aros-openloco/scripts/build-sdl3.sh.
#
#   scripts/fetch-sdl3.sh
#   scripts/build-sdl3.sh
#
# Reads contrib's FILES list so the unit list cannot drift from
# SDL3-aros-staticlib. Why not the AROS build system: the ABIv11 SDK
# tree has no contrib; this is a linkable libSDL3_static.a today.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"
require_aros_toolchain

SRC="$DEPS_DIR/src/SDL3-$SDL3_VER"
[ -d "$SRC" ] || {
  echo "build-sdl3: missing $SRC — run scripts/fetch-sdl3.sh first" >&2
  exit 1
}

mkdir -p "$DEPS_DIR/src/contrib-sdl3"
for f in SDL3_static.c SDL3_intern.h mmakefile.src; do
  dest="$DEPS_DIR/src/contrib-sdl3/$f"
  [ -f "$dest" ] && continue
  curl -fsSL -o "$dest" \
      "https://raw.githubusercontent.com/aros-development-team/contrib/$CONTRIB_SDL3_COMMIT/SDL3/main/$f"
done

# shellcheck source=toolwrap.sh
source "$SCRIPT_DIR/toolwrap.sh"

exec python3 "$SCRIPT_DIR/build-sdl3.py" \
    --deps "$DEPS_DIR" \
    --sdl3-ver "$SDL3_VER" \
    --cc "$AROS_CC_WRAPPED" \
    --ar "$AROS_AR" \
    --sdk "$AROS_SDK" \
    --build "$BUILD_DIR"
