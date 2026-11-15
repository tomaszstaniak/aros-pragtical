# Single place for machine-local paths and upstream pins. Override with
# environment variables; optional ignored local.env; scripts must not
# hardcode paths elsewhere.
#
# Precedence: existing environment, then local.env, then the defaults below.
# Relative values in local.env resolve against the directory that contains it.

# --- project root and local.env --------------------------------------------
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$PROJECT_ROOT/local.env" ]; then
  eval "$(python3 - "$PROJECT_ROOT/local.env" <<'PY'
import os, shlex, sys
from pathlib import Path
path = Path(sys.argv[1])
base = path.parent
for raw in path.read_text().splitlines():
    line = raw.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    key, val = line.split("=", 1)
    key = key.strip()
    val = val.strip()
    if len(val) >= 2 and val[0] == val[-1] and val[0] in "\"'":
        val = val[1:-1]
    if not key or key in os.environ:
        continue
    candidate = Path(val)
    if val and not candidate.is_absolute():
        val = str((base / candidate).resolve())
    print(f"export {key}={shlex.quote(val)}")
PY
)"
fi

# --- AROS target selection -------------------------------------------------
# one | mainline. Default is ABIv11 / AROS One (project decision 2026-09-20).
# Actual machine paths come from the environment or ignored local.env.
AROS_TARGET="${AROS_TARGET:-one}"

case "$AROS_TARGET" in
  mainline)
    AROS_GCC_ROOT="${AROS_GCC_ROOT:-${AROS_MAINLINE_GCC_ROOT:-}}"
    AROS_SDK="${AROS_SDK:-${AROS_MAINLINE_SDK:-}}"
    AROS_SHARED="${AROS_SHARED:-${AROS_MAINLINE_SHARED:-}}"
    ;;
  one)
    AROS_GCC_ROOT="${AROS_GCC_ROOT:-${AROS_ONE_GCC_ROOT:-}}"
    AROS_SDK="${AROS_SDK:-${AROS_ONE_SDK:-}}"
    AROS_SHARED="${AROS_SHARED:-${AROS_ONE_SHARED:-}}"
    ;;
  raspi)
    AROS_GCC_ROOT="${AROS_GCC_ROOT:-${AROS_RASPI_GCC_ROOT:-}}"
    AROS_SDK="${AROS_SDK:-${AROS_RASPI_SDK:-}}"
    AROS_SHARED="${AROS_SHARED:-}"
    ;;
  *)
    echo "scripts/env.sh: unknown AROS_TARGET '$AROS_TARGET' (mainline|one|raspi)" >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

# The Raspberry Pi target is AArch64 and uses the Clang toolchain; the two
# x86_64 targets use GCC.
case "$AROS_TARGET" in
  raspi)
    AROS_CPU="aarch64"
    AROS_TARGET_NAME="aros-aarch64-abiv1-raspi"
    AROS_CC="${AROS_CC:-$AROS_GCC_ROOT/aarch64-aros-clang}"
    AROS_CXX="${AROS_CXX:-$AROS_GCC_ROOT/aarch64-aros-clang++}"
    # libc++ headers and libraries built for the target (C++ dependencies).
    AROS_RASPI_CXXRT="${AROS_RASPI_CXXRT:-}"
    ;;
  mainline)
    AROS_CPU="x86_64"
    AROS_TARGET_NAME="aros-x86_64-abiv1-pc"
    ;;
  *)
    AROS_CPU="x86_64"
    AROS_TARGET_NAME="aros-x86_64-abiv11-pc"
    ;;
esac
AROS_CC="${AROS_CC:-$AROS_GCC_ROOT/$AROS_CPU-aros-gcc}"
AROS_CXX="${AROS_CXX:-$AROS_GCC_ROOT/$AROS_CPU-aros-g++}"
AROS_AR="${AROS_AR:-$AROS_GCC_ROOT/$AROS_CPU-aros-ar}"
AROS_STRIP="${AROS_STRIP:-$AROS_GCC_ROOT/$AROS_CPU-aros-strip}"
AROS_BUILD_VOLUME="${AROS_BUILD_VOLUME:-}"

require_aros_toolchain() {
  if [ -z "$AROS_GCC_ROOT" ] || [ -z "$AROS_SDK" ]; then
    echo "scripts/env.sh: set AROS_GCC_ROOT and AROS_SDK (or their target-specific forms) in local.env or the environment" >&2
    return 1
  fi
}

# --- Upstream pin ----------------------------------------------------------
REPO_ID="${REPO_ID:-pragtical}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/pragtical/pragtical.git}"

# SDL3 3.4.12 — same stack as aros-openloco.
SDL3_VER="${SDL3_VER:-3.4.12}"
# Pinned contrib commit for SDL3-3.4.12-aros.diff (and SDL3_static.c).
# Identical to aros-openloco/scripts/fetch-deps.sh as of 2026-09-20.
CONTRIB_SDL3_COMMIT="${CONTRIB_SDL3_COMMIT:-200499623c8be1f65a7567fcb4c8f62b343936e4}"
CONTRIB_SDL3_SHA256="${CONTRIB_SDL3_SHA256:-d4ce803bc97a257a}"

# --- Project layout --------------------------------------------------------
UPSTREAM_DIR="$PROJECT_ROOT/upstream/$REPO_ID"
WORK_DIR="$PROJECT_ROOT/work/$REPO_ID"
PATCHES_DIR="$PROJECT_ROOT/patches/$REPO_ID"
BUILD_DIR="$PROJECT_ROOT/build/$AROS_TARGET"
DEPS_DIR="$PROJECT_ROOT/deps/$AROS_TARGET"
