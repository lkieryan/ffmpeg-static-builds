#!/usr/bin/env bash

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/ffmpeg-common.sh"

: "${FFMPEG_VERSION:?FFMPEG_VERSION not set}"
: "${ARTIFACT_SUFFIX:?ARTIFACT_SUFFIX not set}" # expected: linux-arm64

resolve_ffmpeg_version
prepare_source_dir
prepare_prefix
prepare_artifacts_dir

cd "${SRC_DIR}"

JOBS=$(nproc)

export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
export AR=aarch64-linux-gnu-ar
export AS=aarch64-linux-gnu-as
export LD=aarch64-linux-gnu-ld
export NM=aarch64-linux-gnu-nm
export RANLIB=aarch64-linux-gnu-ranlib
export STRIP=aarch64-linux-gnu-strip

# Use arm64 pkg-config files and libraries
export PKG_CONFIG=pkg-config
export PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig
export PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=/

./configure \
  --prefix="${PREFIX}" \
  --arch=aarch64 \
  --target-os=linux \
  --enable-cross-compile \
  --cross-prefix=aarch64-linux-gnu- \
  --enable-shared \
  --disable-static \
  --enable-gpl \
  --enable-version3 \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --disable-ffprobe \
  --disable-ffmpeg \
  --enable-demuxer=dash \
  --enable-muxer=dash \
  --enable-protocol=http \
  --enable-protocol=https \
  --enable-libxml2 \
  --enable-openssl

make -j"${JOBS}"
make install

package_build

