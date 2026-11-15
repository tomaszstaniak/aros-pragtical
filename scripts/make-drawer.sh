#!/bin/bash
# Assemble the portable Pragtical drawer for AROS_TARGET from a finished
# build. The result goes to build/<target>/drawer/Pragtical and is the input
# of scripts/package.sh.
#
#   AROS_TARGET=mainline scripts/make-drawer.sh <release-name>
#
# <release-name> is the AROS release label, for example 3.14.0-aros1.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"
require_aros_toolchain
# shellcheck source=toolwrap.sh
source "$SCRIPT_DIR/toolwrap.sh"

[ $# -eq 1 ] || { echo "usage: make-drawer.sh <release-name>" >&2; exit 1; }
RELEASE="$1"

MESON="$PROJECT_ROOT/.venv/bin/meson"
MESON_DIR="$BUILD_DIR/meson"
[ -f "$MESON_DIR/src/pragtical" ] || { echo "make-drawer: no build in $MESON_DIR; run scripts/build.sh" >&2; exit 1; }

STAGE="$BUILD_DIR/drawer"
DRAWER="$STAGE/Pragtical"
INSTALL="$STAGE/install"
rm -rf "$STAGE"
mkdir -p "$INSTALL" "$DRAWER"

# The portable install puts the program, data, doc and user at the top of
# the destination; the dependency subprojects add headers and libraries
# under usr/, which are not part of the application.
"$MESON" install -C "$MESON_DIR" --destdir "$INSTALL" --no-rebuild > "$STAGE/install.log" 2>&1
for item in pragtical data doc user; do
  [ -e "$INSTALL/$item" ] || { echo "make-drawer: install lacks $item" >&2; exit 1; }
  mv "$INSTALL/$item" "$DRAWER/$item"
done
rm -rf "$INSTALL"

cp "$WORK_DIR/LICENSE" "$DRAWER/LICENSE"
cp "$PROJECT_ROOT/packaging/README-AROS.txt" "$DRAWER/README-AROS.txt"
printf 'Stack 8000000\npragtical\n' > "$DRAWER/run-pragtical"

# Icons: the program icon carries the stack the editor needs, so a start
# from Workbench works; the drawer icon sits beside the drawer.
ICON_PNG="$PROJECT_ROOT/packaging/pragtical-icon.png"
python3 "$SCRIPT_DIR/make-icon.py" "$ICON_PNG" "$DRAWER/pragtical.info" --type tool --stack 8000000
python3 "$SCRIPT_DIR/make-icon.py" "$ICON_PNG" "$STAGE/Pragtical.info" --type drawer

# Package description for apkg-pack, one per target.
REVISION="${RELEASE##*-aros}"
case "$REVISION" in ''|*[!0-9]*) echo "make-drawer: release name must end in -aros<number>" >&2; exit 1 ;; esac
case "$AROS_TARGET" in
  raspi)    PKG_ARCH=aarch64; PKG_ABI=v1;  RUNTIME_LIBS="posixc.library stdc.library stdcio.library" ;;
  mainline) PKG_ARCH=x86_64;  PKG_ABI=v1;  RUNTIME_LIBS="posixc.library stdc.library stdcio.library" ;;
  *)        PKG_ARCH=x86_64;  PKG_ABI=v11; RUNTIME_LIBS="crt.library stdlib.library m.library" ;;
esac
{
  sed -e "s/@VERSION@/${RELEASE%%-*}/" -e "s/@REVISION@/$REVISION/" \
      -e "s/@ARCH@/$PKG_ARCH/" -e "s/@ABI@/$PKG_ABI/" \
      "$PROJECT_ROOT/packaging/Pragtical.arospkg.toml.in"
  for lib in $RUNTIME_LIBS cybergraphics.library gadtools.library gl.library icon.library \
             iffparse.library keymap.library lowlevel.library muimaster.library \
             commodities.library workbench.library z1.library; do
    printf '\n[[requires_system]]\ntype = "library"\nid = "%s"\n' "$lib"
  done
  printf '\n[source]\nrepository = "https://github.com/tomaszstaniak/aros-pragtical"\nrevision = "v%s"\n' "$RELEASE"
  printf '\n[launch]\nexecutable = "pragtical"\nmode       = "workbench"\n'
} > "$STAGE/Pragtical.arospkg.toml"

python3 - "$DRAWER/BUILD-MANIFEST.json" "$RELEASE" "$AROS_TARGET_NAME" \
  "$(git -C "$WORK_DIR" config project.base || true)" \
  "$(git -C "$WORK_DIR" rev-parse HEAD)" \
  "$(grep -c . "$PATCHES_DIR/series")" \
  "$("$AROS_CC_WRAPPED" --version | head -1)" \
  "$("$MESON" --version)" \
  "$SDL3_VER" \
  "$MESON_DIR/meson-info/intro-buildoptions.json" <<'PY'
import json
import sys

out, release, target, base, work, patches, compiler, meson, sdl3, options = sys.argv[1:]
wanted = ("jit", "portable", "renderer", "renderer_backend", "dirmonitor_backends",
          "ppm", "repl_history", "net")
profile = []
for option in json.load(open(options)):
    name = option["name"]
    if name in wanted or name in ("opus:hardening", "opus:rtcd"):
        value = option["value"]
        if isinstance(value, list):
            value = ",".join(value)
        elif isinstance(value, bool):
            value = "true" if value else "false"
        profile.append(f"{name}={value}")
manifest = {
    "schema": 2,
    "application": "Pragtical",
    "version": release.split("-")[0],
    "release": release,
    "target": target,
    "source": {
        "upstream": "https://github.com/pragtical/pragtical",
        "base_commit": base,
        "work_revision": work,
        "patch_series": f"patches/pragtical/series ({patches} patches)",
    },
    "build": {
        "compiler": compiler,
        "meson": meson,
        "sdl3": f"{sdl3} with the AROS port and the patches in patches/dependencies",
        "profile": sorted(profile),
        "stripped": False,
    },
}
with open(out, "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")
PY

echo "make-drawer: $DRAWER"
