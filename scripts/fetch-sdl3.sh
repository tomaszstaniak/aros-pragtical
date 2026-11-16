#!/bin/bash
# Stage SDL3 3.4.12 the same way aros-openloco does: upstream tarball,
# contrib's AROS patch at a pinned commit, then our carried platform
# patches. Output: $DEPS_DIR/src/SDL3-3.4.12/
#
#   scripts/fetch-sdl3.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"

SRC="$DEPS_DIR/src"
mkdir -p "$SRC"
cd "$SRC"

TARBALL="SDL3-$SDL3_VER.tar.gz"
[ -f "$TARBALL" ] || curl -fsSL -o "$TARBALL" \
    "https://www.libsdl.org/release/$TARBALL"

if [ -d "SDL3-$SDL3_VER" ]; then
  echo "fetch-sdl3: $SRC/SDL3-$SDL3_VER already present"
  exit 0
fi

tar xzf "$TARBALL"

DIFF="SDL3-$SDL3_VER-aros.diff"
curl -fsSL -o "$DIFF" \
    "https://raw.githubusercontent.com/aros-development-team/contrib/$CONTRIB_SDL3_COMMIT/SDL3/main/$DIFF"
got=$(shasum -a 256 "$DIFF" | cut -c1-16)
[ "$got" = "$CONTRIB_SDL3_SHA256" ] || {
  echo "fetch-sdl3: $DIFF checksum $got, expected $CONTRIB_SDL3_SHA256 — refusing" >&2
  exit 1
}
patch -p1 -d "SDL3-$SDL3_VER" < "$DIFF"
patch -p1 -d "SDL3-$SDL3_VER" < "$PROJECT_ROOT/patches/dependencies/sdl3-3.4.12-langinfo-guard.diff"
patch -p1 -d "SDL3-$SDL3_VER" < "$PROJECT_ROOT/patches/dependencies/sdl3-3.4.12-aros-text-input.diff"
patch -p1 -d "SDL3-$SDL3_VER" < "$PROJECT_ROOT/patches/dependencies/sdl3-3.4.12-hidden-window-framebuffer.diff"
patch -p1 -d "SDL3-$SDL3_VER" < "$PROJECT_ROOT/patches/dependencies/sdl3-3.4.12-application-menu.diff"
patch -p1 -d "SDL3-$SDL3_VER" < "$PROJECT_ROOT/patches/dependencies/sdl3-3.4.12-optional-iconv.diff"
patch -p1 -d "SDL3-$SDL3_VER" < "$PROJECT_ROOT/patches/dependencies/sdl3-3.4.12-aros-charset-clipboard.diff"
patch -p1 -d "SDL3-$SDL3_VER" < "$PROJECT_ROOT/patches/dependencies/sdl3-3.4.12-aros-minimize-fullscreen.diff"

echo "fetch-sdl3: SDL3 $SDL3_VER ready in $SRC/SDL3-$SDL3_VER"
