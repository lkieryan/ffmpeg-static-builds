#!/usr/bin/env bash

set -euo pipefail

# Common helpers for all FFmpeg builds.

FFMPEG_SOURCE_URL="${FFMPEG_SOURCE_URL:-https://github.com/FFmpeg/FFmpeg}"

normalize_path() {
  local p="$1"
  if command -v cygpath >/dev/null 2>&1; then
    case "$p" in
      [A-Za-z]:\\*|[A-Za-z]:/*)
        cygpath "$p"
        return
        ;;
    esac
  fi
  printf '%s\n' "$p"
}

resolve_ffmpeg_version() {
  # When FFMPEG_VERSION is "latest", resolve it via GitHub releases.
  if [[ "${FFMPEG_VERSION:-latest}" == "latest" ]]; then
    local latest_url
    latest_url=$(curl -Ls -o /dev/null -w '%{url_effective}' "${FFMPEG_SOURCE_URL}/releases/latest")
    FFMPEG_VERSION="${latest_url##*/}"
  fi
}

prepare_source_dir() {
  local workspace src_archive

  workspace="${GITHUB_WORKSPACE:-$(pwd)}"
  workspace="$(normalize_path "${workspace}")"
  cd "${workspace}"

  src_archive="ffmpeg.tar.gz"

  curl -L "${FFMPEG_SOURCE_URL}/archive/refs/tags/${FFMPEG_VERSION}.tar.gz" -o "${src_archive}"
  tar -xf "${src_archive}"

  SRC_DIR="FFmpeg-${FFMPEG_VERSION}"
  if [[ ! -d "${SRC_DIR}" ]]; then
    SRC_DIR=$(tar -tf "${src_archive}" | head -1 | cut -d/ -f1)
  fi
}

prepare_prefix() {
  local workspace

  workspace="${GITHUB_WORKSPACE:-$(pwd)}"
  workspace="$(normalize_path "${workspace}")"
  PREFIX="${workspace}/build"
  rm -rf "${PREFIX}"
  mkdir -p "${PREFIX}"
}

prepare_artifacts_dir() {
  local workspace

  workspace="${GITHUB_WORKSPACE:-$(pwd)}"
  workspace="$(normalize_path "${workspace}")"
  ARTIFACT_DIR="${workspace}/artifacts"
  mkdir -p "${ARTIFACT_DIR}"
}

package_build() {
  : "${ARTIFACT_SUFFIX:?ARTIFACT_SUFFIX not set}"
  : "${PREFIX:?PREFIX not set}"
  : "${FFMPEG_VERSION:?FFMPEG_VERSION not set}"
  : "${ARTIFACT_DIR:?ARTIFACT_DIR not set}"

  local package_name
  package_name="ffmpeg-${FFMPEG_VERSION}-${ARTIFACT_SUFFIX}.tar.gz"

  tar -czf "${ARTIFACT_DIR}/${package_name}" -C "${PREFIX}" .
}
