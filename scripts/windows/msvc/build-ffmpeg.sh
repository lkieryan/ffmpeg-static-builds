#!/bin/bash
# Forked from System233/ffmpeg-msvc-prebuilt build-ffmpeg.sh (MIT)

set -e
echo -e "\n[Build $1]"
SRC_DIR=$(pwd)/$1
shift 1
cd "$SRC_DIR"

if [ "$BUILD_TYPE" == "static" ]; then
    TYPE_ARGS="--enable-static --pkg-config-flags=--static"
else
    TYPE_ARGS="--enable-shared"
fi
if [[ "$BUILD_ARCH" =~ arm ]]; then
    CROSS_ARGS="--enable-cross-compile --disable-asm"
fi

if [ "$BUILD_LICENSE" == "gpl" ]; then
    LICENSE_ARGS="--enable-gpl --enable-version3"
fi
CFLAGS="$CFLAGS -I${SRC_DIR}/compat/stdbit"
EX_BUILD_ARGS="$TYPE_ARGS $CROSS_ARGS $LICENSE_ARGS"

CFLAGS="$CFLAGS" ./configure --toolchain=msvc --arch="$BUILD_ARCH" $EX_BUILD_ARGS "$@"
make -j"$(nproc)"
make install prefix="$INSTALL_PREFIX"

