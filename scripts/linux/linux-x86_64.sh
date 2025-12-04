#!/usr/bin/env bash

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/ffmpeg-common.sh"

: "${FFMPEG_VERSION:?FFMPEG_VERSION not set}"
: "${ARTIFACT_SUFFIX:?ARTIFACT_SUFFIX not set}" # expected: linux-x86_64

resolve_ffmpeg_version
prepare_source_dir
prepare_prefix
prepare_artifacts_dir

cd "${SRC_DIR}"

JOBS=$(nproc)

./configure \
  --prefix="${PREFIX}" \
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
  --enable-pic \
  --enable-openssl

make -j"${JOBS}"
make install

package_build

