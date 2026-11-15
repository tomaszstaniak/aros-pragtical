#!/bin/bash
# Finalize a prepared Pragtical drawer as an AROS package. This strips only
# non-needed symbols, updates the existing manifest and verifies the ZIP by
# extracting it again. It does not change the build profile or runtime claims.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"

if [ $# -ne 2 ]; then
  echo "usage: scripts/package.sh <Pragtical-drawer> <output.zip>" >&2
  exit 1
fi

DRAWER="$(cd "$1" && pwd)"
OUTPUT="$2"
BINARY="$DRAWER/pragtical"
MANIFEST="$DRAWER/BUILD-MANIFEST.json"
STRIP_FLAGS=(--strip-unneeded --remove-section .comment)

[ "$(basename "$DRAWER")" = Pragtical ] || {
  echo "package: drawer must be named Pragtical: $DRAWER" >&2
  exit 1
}
[ -f "$BINARY" ] || { echo "package: missing $BINARY" >&2; exit 1; }
[ -f "$MANIFEST" ] || { echo "package: missing $MANIFEST" >&2; exit 1; }
[ -x "$AROS_STRIP" ] || { echo "package: strip not executable: $AROS_STRIP" >&2; exit 1; }
command -v zip >/dev/null
command -v unzip >/dev/null

mkdir -p "$(dirname "$OUTPUT")"
OUTPUT="$(cd "$(dirname "$OUTPUT")" && pwd)/$(basename "$OUTPUT")"
case "$OUTPUT" in
  "$DRAWER"/*) echo "package: output ZIP must be outside the drawer" >&2; exit 1 ;;
esac

python3 - "$MANIFEST" "$BINARY" "$AROS_STRIP" "${STRIP_FLAGS[@]}" <<'PY'
import hashlib
import json
import os
import subprocess
import sys

manifest_path, binary, strip = sys.argv[1:4]
flags = sys.argv[4:]
with open(manifest_path) as f:
    manifest = json.load(f)
build = manifest.setdefault("build", {})

def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()

current_hash = sha256(binary)
if build.get("stripped"):
    if build.get("strip_flags") != flags:
        raise SystemExit("package: drawer was stripped with different flags; rebuild it")
    if build.get("binary_sha256") != current_hash:
        raise SystemExit("package: stripped binary differs from the manifest")
    original_hash = build.get("unstripped_binary_sha256")
    if not original_hash:
        raise SystemExit("package: missing unstripped_binary_sha256")
    print("package: safe strip already applied")
else:
    original_hash = current_hash
    original_size = os.path.getsize(binary)
    subprocess.run([strip, *flags, binary], check=True)
    stripped_size = os.path.getsize(binary)
    if stripped_size >= original_size:
        raise SystemExit("package: safe strip did not reduce the binary size")

build["binary_sha256"] = sha256(binary)
build["binary_size"] = os.path.getsize(binary)
build["unstripped_binary_sha256"] = original_hash
build["stripped"] = True
build["strip_flags"] = flags
with open(manifest_path, "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")
print(f"package: binary {build['binary_size']} bytes, sha256 {build['binary_sha256']}")
PY

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/aros-pragtical-package.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT
ARCHIVE="$TMP_DIR/package.zip"
DESCRIPTION="$(dirname "$DRAWER")/Pragtical.arospkg.toml"
if [ -f "$DESCRIPTION" ]; then
  # A drawer prepared by make-drawer.sh has a package description beside
  # it. apkg-pack then writes the archive: the drawer, its icon, the
  # embedded manifest and application.json.
  [ -n "${APKG_PACK:-}" ] && [ -f "$APKG_PACK" ] || {
    echo "package: set APKG_PACK to apkg-pack.pyz (local.env)" >&2
    exit 1
  }
  python3 "$APKG_PACK" check "$DRAWER"
  python3 "$APKG_PACK" build "$DRAWER" --output "$ARCHIVE"
  python3 "$APKG_PACK" check "$ARCHIVE"
else
  (
    cd "$(dirname "$DRAWER")"
    zip -q -9 -r "$ARCHIVE" Pragtical
  )
fi
unzip -t "$ARCHIVE" >/dev/null
mkdir "$TMP_DIR/extracted"
unzip -q "$ARCHIVE" -d "$TMP_DIR/extracted"
diff -qr -x application.json "$DRAWER" "$TMP_DIR/extracted/Pragtical"
mv "$ARCHIVE" "$OUTPUT"
(
  cd "$(dirname "$OUTPUT")"
  shasum -a 256 "$(basename "$OUTPUT")" > SHA256SUMS
)
printf 'package: %s\n' "$OUTPUT"
cat "$(dirname "$OUTPUT")/SHA256SUMS"
