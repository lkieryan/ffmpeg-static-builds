#!/usr/bin/env bash

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/ffmpeg-common.sh"

: "${FFMPEG_VERSION:?FFMPEG_VERSION not set}"
: "${ARTIFACT_SUFFIX:?ARTIFACT_SUFFIX not set}" # expected: windows-msvc-x86_64

resolve_ffmpeg_version
prepare_source_dir
prepare_prefix
prepare_artifacts_dir

WORKSPACE=$(cygpath "${GITHUB_WORKSPACE}")
cd "${WORKSPACE}"

cd "${SRC_DIR}"

VCPKG_ROOT="${GITHUB_WORKSPACE}/vcpkg"
TRIPLET_STATIC="x64-windows-static"
TRIPLET_DYNAMIC="x64-windows"

INCLUDE_MSYS=$(cygpath -m "${VCPKG_ROOT}/installed/${TRIPLET_STATIC}/include")
LIB_MSYS=$(cygpath -m "${VCPKG_ROOT}/installed/${TRIPLET_STATIC}/lib")
LIB_POSIX=$(cygpath "${VCPKG_ROOT}/installed/${TRIPLET_STATIC}/lib")

PKGCONF_DIR=$(cygpath "${VCPKG_ROOT}/installed/${TRIPLET_DYNAMIC}/tools/pkgconf")
PKGCONF_BIN="${PKGCONF_DIR}/pkgconf.exe"
if [[ ! -x "${PKGCONF_BIN}" ]]; then
  echo "pkgconf not found at ${PKGCONF_BIN}" >&2
  exit 1
fi

export PKG_CONFIG="${PKGCONF_BIN} --msvc-syntax"
export PKG_CONFIG_PATH
PKG_CONFIG_PATH=$(cygpath -m "${VCPKG_ROOT}/installed/${TRIPLET_STATIC}/lib/pkgconfig")
export PKG_CONFIG_LIBDIR="${PKG_CONFIG_PATH}"
export PKG_CONFIG_SYSTEM_LIBRARY_PATH
PKG_CONFIG_SYSTEM_LIBRARY_PATH=$(cygpath -m "${VCPKG_ROOT}/installed/${TRIPLET_STATIC}/lib")
export PKG_CONFIG_SYSTEM_INCLUDE_PATH
PKG_CONFIG_SYSTEM_INCLUDE_PATH=$(cygpath -m "${VCPKG_ROOT}/installed/${TRIPLET_STATIC}/include")
export PATH="${PATH}:$(cygpath "${VCPKG_ROOT}/installed/${TRIPLET_DYNAMIC}/bin"):${PKGCONF_DIR}"

echo "Resolved include dir: ${INCLUDE_MSYS}"
echo "Resolved lib dir: ${LIB_MSYS}"

./configure \
  --toolchain=msvc \
  --arch=x86_64 \
  --target-os=win64 \
  --prefix="${PREFIX}" \
  --disable-avfilter \
  --enable-static \
  --disable-shared \
  --enable-demuxer=dash \
  --enable-muxer=dash \
  --enable-protocol=http \
  --enable-protocol=https \
  --enable-gpl \
  --enable-version3 \
  --enable-schannel \
  --enable-zlib \
  --enable-nonfree \
  --disable-doc \
  --disable-ffplay \
  --disable-ffprobe \
  --disable-ffmpeg \
  --extra-cflags="-I${INCLUDE_MSYS}" \
  --extra-ldflags="-LIBPATH:${LIB_MSYS}"

# Disable MSVC dependency generation to avoid awk /including/ errors.
make CCDEP= CXXDEP= ASDEP= HOSTCCDEP=
make CCDEP= CXXDEP= ASDEP= HOSTCCDEP= install

if [[ -f "${LIB_POSIX}/zlib.lib" ]]; then
  cp "${LIB_POSIX}/zlib.lib" "${PREFIX}/lib/"
  cp "${LIB_POSIX}/zlib.lib" "${PREFIX}/lib/z.lib"
fi

package_build
