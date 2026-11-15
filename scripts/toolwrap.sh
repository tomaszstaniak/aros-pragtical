# Sourced after env.sh. Sets AROS_CC_WRAPPED and AROS_CXX_WRAPPED.
#
# The x86_64 GCC drivers are used directly. The Raspberry Pi Clang driver
# takes its SDK from the RPI_SDK environment variable and has no C++ standard
# library of its own, so Meson and the SDL3 build get two small generated
# launchers that carry both settings.
AROS_CC_WRAPPED="$AROS_CC"
AROS_CXX_WRAPPED="$AROS_CXX"

if [ "$AROS_TARGET" = raspi ]; then
  [ -n "${AROS_RASPI_CXXRT:-}" ] && [ -d "$AROS_RASPI_CXXRT/include/c++/v1" ] || {
    echo "toolwrap: set AROS_RASPI_CXXRT to a libc++ built for the target (include/c++/v1, lib)" >&2
    return 1 2>/dev/null || exit 1
  }
  mkdir -p "$BUILD_DIR/toolbin"
  AROS_CC_WRAPPED="$BUILD_DIR/toolbin/cc"
  AROS_CXX_WRAPPED="$BUILD_DIR/toolbin/c++"
  cat > "$AROS_CC_WRAPPED" <<EOF
#!/bin/sh
RPI_SDK="$AROS_SDK"; export RPI_SDK
exec "$AROS_CC" "\$@"
EOF
  cat > "$AROS_CXX_WRAPPED" <<EOF
#!/bin/sh
RPI_SDK="$AROS_SDK"; export RPI_SDK
exec "$AROS_CXX" -nostdinc++ -isystem "$AROS_RASPI_CXXRT/include/c++/v1" -L"$AROS_RASPI_CXXRT/lib" "\$@"
EOF
  chmod +x "$AROS_CC_WRAPPED" "$AROS_CXX_WRAPPED"
fi
