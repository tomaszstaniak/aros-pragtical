#!/bin/bash
# Cross-configure and compile Pragtical for AROS_TARGET.
#
#   scripts/fetch-sdl3.sh && scripts/build-sdl3.sh
#   scripts/build.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"
require_aros_toolchain

apply_meson_dependency_patch() {
  local name="$1"
  local patch_file="$2"
  local source_dir="$WORK_DIR/subprojects/$name"

  [ -d "$source_dir" ] || return 0
  [ -f "$source_dir/meson.build" ] || {
    echo "build: missing $source_dir/meson.build for dependency patch" >&2
    exit 1
  }

  if patch -d "$source_dir" -p1 --dry-run --forward < "$patch_file" >/dev/null 2>&1; then
    patch -d "$source_dir" -p1 --forward < "$patch_file"
  elif patch -d "$source_dir" -p1 --dry-run --reverse < "$patch_file" >/dev/null 2>&1; then
    echo "build: dependency patch already applied to $name"
  else
    echo "build: dependency patch does not apply to $name: $patch_file" >&2
    exit 1
  fi
}

MESON="${PROJECT_ROOT}/.venv/bin/meson"
[ -x "$MESON" ] || {
  echo "build: missing $MESON — python3 -m venv .venv && .venv/bin/pip install 'meson>=0.63'" >&2
  exit 1
}
[ -f "$DEPS_DIR/lib/libSDL3_static.a" ] || {
  echo "build: missing SDL3 — run scripts/fetch-sdl3.sh && scripts/build-sdl3.sh" >&2
  exit 1
}
[ -d "$WORK_DIR" ] || {
  echo "build: missing $WORK_DIR — run scripts/bootstrap.sh" >&2
  exit 1
}

mkdir -p "$DEPS_DIR/lib/pkgconfig"
# SDK freetype2.pc still has unexpanded %PKGCONFIG_LIBS% placeholders.
cat > "$DEPS_DIR/lib/pkgconfig/freetype2.pc" <<EOF
prefix=$AROS_SDK
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: FreeType 2
Version: 2.14.1
Libs: -L\${libdir} -lfreetype2.static
Cflags: -I\${includedir}
EOF

CROSS="$BUILD_DIR/meson-cross.ini"
"$SCRIPT_DIR/write-meson-cross.sh" "$CROSS"

MESON_DIR="$BUILD_DIR/meson"
# Opus cannot detect CPU features at run time on AArch64 AROS. NEON is part
# of the base architecture there, so the fixed code paths lose nothing.
TARGET_OPTIONS=()
if [ "$AROS_TARGET" = raspi ]; then
  TARGET_OPTIONS+=(-Dopus:rtcd=disabled)
fi
if [ -f "$MESON_DIR/build.ninja" ]; then
  echo "build: reconfigure $MESON_DIR"
  "$MESON" setup --reconfigure \
    --cross-file "$CROSS" \
    --wrap-mode=default \
    -Djit=false \
    -Dportable=true \
    -Drenderer=true \
    -Ddirmonitor_backends=aros,dummy \
    -Dppm=false \
    -Drepl_history=false \
    -Dnet=false \
    -Drenderer_backend=surface \
    -Dopus:hardening=false \
    ${TARGET_OPTIONS[@]+"${TARGET_OPTIONS[@]}"} \
    "$MESON_DIR" \
    "$WORK_DIR"
else
  rm -rf "$MESON_DIR"
  "$MESON" setup \
    --cross-file "$CROSS" \
    --wrap-mode=default \
    -Djit=false \
    -Dportable=true \
    -Drenderer=true \
    -Ddirmonitor_backends=aros,dummy \
    -Dppm=false \
    -Drepl_history=false \
    -Dnet=false \
    -Drenderer_backend=surface \
    -Dopus:hardening=false \
    ${TARGET_OPTIONS[@]+"${TARGET_OPTIONS[@]}"} \
    "$MESON_DIR" \
    "$WORK_DIR"
fi

apply_meson_dependency_patch \
  "harfbuzz-13.0.1" \
  "$PROJECT_ROOT/patches/dependencies/harfbuzz-13.0.1-aros-pthread.diff"
apply_meson_dependency_patch \
  "opus-1.6.1" \
  "$PROJECT_ROOT/patches/dependencies/opus-1.6.1-hardening-stack-protector.diff"

"$MESON" compile -C "$MESON_DIR"
echo "build: $MESON_DIR"
