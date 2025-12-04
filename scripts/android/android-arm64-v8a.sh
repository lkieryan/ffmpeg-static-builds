#!/usr/bin/env bash

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/ffmpeg-common.sh"

: "${FFMPEG_VERSION:?FFMPEG_VERSION not set}"
: "${ARTIFACT_SUFFIX:?ARTIFACT_SUFFIX not set}" # expected: android-arm64-v8a
: "${API_LEVEL:?API_LEVEL not set}"

ARCH=arm64

prepare_source_dir
prepare_prefix
prepare_artifacts_dir

cd "${SRC_DIR}"

NDK_ROOT=${ANDROID_NDK_HOME:-${ANDROID_NDK_LATEST_HOME:-}}
if [[ -z "${NDK_ROOT}" ]]; then
  echo "ANDROID_NDK_HOME or ANDROID_NDK_LATEST_HOME must be set" >&2
  exit 1
fi

TOOLCHAIN="${NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"
SYSROOT="${TOOLCHAIN}/sysroot"

TARGET=aarch64-linux-android
FF_ARCH=aarch64
CPU=armv8-a

EXTRA_CFLAGS="-fPIC"
EXTRA_LDFLAGS="-fPIC"

CC="${TOOLCHAIN}/bin/${TARGET}${API_LEVEL}-clang"
CXX="${TOOLCHAIN}/bin/${TARGET}${API_LEVEL}-clang++"

CONFIGURE_FLAGS=(
  --prefix="${PREFIX}"
  --target-os=android
  --arch="${FF_ARCH}"
  --cpu="${CPU}"
  --enable-cross-compile
  --cc="${CC}"
  --cxx="${CXX}"
  --ld="${CC}"
  --ar="${TOOLCHAIN}/bin/llvm-ar"
  --ranlib="${TOOLCHAIN}/bin/llvm-ranlib"
  --strip="${TOOLCHAIN}/bin/llvm-strip"
  --nm="${TOOLCHAIN}/bin/llvm-nm"
  --cross-prefix="${TOOLCHAIN}/bin/${TARGET}-"
  --sysroot="${SYSROOT}"
  --pkg-config=pkg-config
  --disable-programs
  --disable-debug
  --disable-doc
  --disable-ffplay
  --disable-ffprobe
  --disable-avdevice
  --enable-shared
  --disable-static
  --enable-gpl
  --enable-version3
  --enable-demuxer=dash
  --enable-muxer=dash
  --enable-protocol=http
  --extra-cflags="${EXTRA_CFLAGS}"
  --extra-ldflags="${EXTRA_LDFLAGS}"
)

if ! ./configure "${CONFIGURE_FLAGS[@]}"; then
  cat ffbuild/config.log
  exit 1
fi

make -j"$(nproc)"
make install

package_build

