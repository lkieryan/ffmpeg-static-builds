#!/usr/bin/env bash

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/ffmpeg-common.sh"

: "${FFMPEG_VERSION:?FFMPEG_VERSION not set}"
: "${ARTIFACT_SUFFIX:?ARTIFACT_SUFFIX not set}" # expected: ios-simulator-arm64
: "${IOS_SDK:?IOS_SDK not set}"
: "${MIN_VERSION:?MIN_VERSION not set}"

IOS_ARCH=arm64

prepare_source_dir
prepare_prefix
prepare_artifacts_dir

cd "${SRC_DIR}"

SDK_PATH=$(xcrun --sdk "${IOS_SDK}" --show-sdk-path)
CC=$(xcrun --sdk "${IOS_SDK}" --find clang)
CXX=$(xcrun --sdk "${IOS_SDK}" --find clang++)
AR_BIN=$(xcrun --sdk "${IOS_SDK}" --find ar)
RANLIB_BIN=$(xcrun --sdk "${IOS_SDK}" --find ranlib)
STRIP_BIN=$(xcrun --sdk "${IOS_SDK}" --find strip)

if [[ "${IOS_SDK}" == "iphoneos" ]]; then
  MIN_FLAG="-miphoneos-version-min=${MIN_VERSION}"
else
  MIN_FLAG="-mios-simulator-version-min=${MIN_VERSION}"
fi

EXTRA_CFLAGS="-arch ${IOS_ARCH} -fembed-bitcode ${MIN_FLAG}"
EXTRA_LDFLAGS="-arch ${IOS_ARCH} ${MIN_FLAG}"

./configure \
  --prefix="${PREFIX}" \
  --target-os=darwin \
  --arch="${IOS_ARCH}" \
  --enable-cross-compile \
  --cc="${CC}" \
  --cxx="${CXX}" \
  --ld="${CC}" \
  --ar="${AR_BIN}" \
  --ranlib="${RANLIB_BIN}" \
  --strip="${STRIP_BIN}" \
  --sysroot="${SDK_PATH}" \
  --disable-programs \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --disable-ffprobe \
  --disable-avdevice \
  --enable-shared \
  --disable-static \
  --enable-gpl \
  --enable-version3 \
  --enable-demuxer=dash \
  --enable-muxer=dash \
  --enable-protocol=http \
  --extra-cflags="${EXTRA_CFLAGS}" \
  --extra-ldflags="${EXTRA_LDFLAGS}"

make -j"$(sysctl -n hw.ncpu)"
make install

package_build

