#!/usr/bin/env bash

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/ffmpeg-common.sh"

: "${FFMPEG_VERSION:?FFMPEG_VERSION not set}"
: "${ARTIFACT_SUFFIX:?ARTIFACT_SUFFIX not set}" # expected: windows-mingw-x86_64

resolve_ffmpeg_version
prepare_source_dir
prepare_prefix
prepare_artifacts_dir

export MINGW_PREFIX=/mingw64
export PATH="${MINGW_PREFIX}/bin:${PATH}"

cd "${SRC_DIR}"

# Map x86_64-w64-mingw32-* tools if only generic ones exist.
if [[ -x "${MINGW_PREFIX}/bin/x86_64-w64-mingw32-gcc-ar" ]]; then
  export AR="${MINGW_PREFIX}/bin/x86_64-w64-mingw32-gcc-ar"
  ln -sf "${AR}" "${MINGW_PREFIX}/bin/x86_64-w64-mingw32-ar"
elif [[ -x "${MINGW_PREFIX}/bin/ar" ]]; then
  export AR="${MINGW_PREFIX}/bin/ar"
  ln -sf "${AR}" "${MINGW_PREFIX}/bin/x86_64-w64-mingw32-ar"
fi

if [[ -x "${MINGW_PREFIX}/bin/x86_64-w64-mingw32-gcc-ranlib" ]]; then
  export RANLIB="${MINGW_PREFIX}/bin/x86_64-w64-mingw32-gcc-ranlib"
  ln -sf "${RANLIB}" "${MINGW_PREFIX}/bin/x86_64-w64-mingw32-ranlib"
elif [[ -x "${MINGW_PREFIX}/bin/ranlib" ]]; then
  export RANLIB="${MINGW_PREFIX}/bin/ranlib"
  ln -sf "${RANLIB}" "${MINGW_PREFIX}/bin/x86_64-w64-mingw32-ranlib"
fi

if [[ -x "${MINGW_PREFIX}/bin/x86_64-w64-mingw32-gcc-nm" ]]; then
  export NM="${MINGW_PREFIX}/bin/x86_64-w64-mingw32-gcc-nm"
  ln -sf "${NM}" "${MINGW_PREFIX}/bin/x86_64-w64-mingw32-nm"
elif [[ -x "${MINGW_PREFIX}/bin/nm" ]]; then
  export NM="${MINGW_PREFIX}/bin/nm"
  ln -sf "${NM}" "${MINGW_PREFIX}/bin/x86_64-w64-mingw32-nm"
fi

if [[ ! -x "${MINGW_PREFIX}/bin/x86_64-w64-mingw32-dlltool" && -x "${MINGW_PREFIX}/bin/dlltool" ]]; then
  ln -sf "${MINGW_PREFIX}/bin/dlltool" "${MINGW_PREFIX}/bin/x86_64-w64-mingw32-dlltool"
fi

export PKG_CONFIG_PATH="${MINGW_PREFIX}/lib/pkgconfig"
export PKG_CONFIG="${MINGW_PREFIX}/bin/pkg-config"

CC="${MINGW_PREFIX}/bin/x86_64-w64-mingw32-gcc"
CXX="${MINGW_PREFIX}/bin/x86_64-w64-mingw32-g++"

CC="${CC}" CXX="${CXX}" \
./configure \
  --prefix="${PREFIX}" \
  --target-os=mingw32 \
  --arch=x86_64 \
  --enable-cross-compile \
  --cross-prefix=x86_64-w64-mingw32- \
  --pkg-config=x86_64-w64-mingw32-pkg-config \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --disable-ffprobe \
  --disable-ffmpeg \
  --enable-demuxer=dash \
  --enable-muxer=dash \
  --enable-protocol=http \
  --enable-protocol=https \
  --enable-openssl \
  --enable-libxml2 \
  --enable-shared \
  --disable-static \
  --enable-gpl \
  --enable-version3 \
  --extra-libs="-lssl -lcrypto -lws2_32 -lgdi32 -lz -lcrypt32 -lbcrypt"

make -j"$(nproc)" STRIP=":"
make install-libs install-headers STRIP=":"

package_build

