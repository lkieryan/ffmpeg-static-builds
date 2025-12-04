#!/bin/bash
# Forked from System233/ffmpeg-msvc-prebuilt build.sh (MIT) and adapted

HELP_MSG="Usage: build.sh <x86,amd64,arm,arm64> [static,shared] [gpl,lgpl] ...FF_ARGS"
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

if [ -z "$BUILD_ARCH" ]; then
    echo "$HELP_MSG" >&2
    exit 1
fi

shift 3 || true
FF_ARGS=$@

echo BUILD_ARCH="$BUILD_ARCH"
echo BUILD_TYPE="$BUILD_TYPE"
echo BUILD_LICENSE="$BUILD_LICENSE"
echo FF_ARGS="$FF_ARGS"

# Ensure FFmpeg source tree exists (FFmpeg/), download tarball if needed.
FFMPEG_SOURCE_URL="${FFMPEG_SOURCE_URL:-https://github.com/FFmpeg/FFmpeg}"
if [ -z "${FFMPEG_VERSION:-}" ]; then
    echo "FFMPEG_VERSION not set" >&2
    exit 1
fi

WORKSPACE="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$WORKSPACE"

if [ ! -d FFmpeg ]; then
    echo "Downloading FFmpeg ${FFMPEG_VERSION}..."
    curl -L "${FFMPEG_SOURCE_URL}/archive/refs/tags/${FFMPEG_VERSION}.tar.gz" -o ffmpeg.tar.gz
    tar -xf ffmpeg.tar.gz
    SRC_DIR="FFmpeg-${FFMPEG_VERSION}"
    if [ ! -d "$SRC_DIR" ]; then
        SRC_DIR=$(tar -tf ffmpeg.tar.gz | head -1 | cut -d/ -f1)
    fi
    mv "$SRC_DIR" FFmpeg
fi

cd "$SCRIPT_DIR"

./build-ffmpeg.sh FFmpeg $FF_ARGS

# Package /usr/local into artifacts tarball
if [ -z "${ARTIFACT_SUFFIX:-}" ]; then
    echo "ARTIFACT_SUFFIX not set" >&2
    exit 1
fi

WORKSPACE="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ARTIFACT_DIR="${WORKSPACE}/artifacts"
mkdir -p "${ARTIFACT_DIR}"
PACKAGE_NAME="ffmpeg-${FFMPEG_VERSION}-${ARTIFACT_SUFFIX}.tar.gz"

cd "${INSTALL_PREFIX}"
tar -czf "${ARTIFACT_DIR}/${PACKAGE_NAME}" .

