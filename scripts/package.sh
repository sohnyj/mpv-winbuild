#!/bin/bash
# Pack mpv.exe, mpv.com and ffmpeg.exe of a build directory into release
# archives, named after architecture, CPU without x86-64- (v3, znver3), UTC
# date and mpv and FFmpeg commits of its revisions.txt.
#
# Usage: package.sh [--march <cpu>] [base_dir]
#   --march <cpu>  build directory build/<cpu> (default: PACKAGE_MARCH of
#                  defaults.env)
#   base_dir       location of build/, with archives written to its release/
#                  (default: repository root)
set -euo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"
# shellcheck source=defaults.env
. "${repo_root}/scripts/defaults.env"

march="${PACKAGE_MARCH}"
base_dir="${repo_root}"
while (( $# > 0 )); do
  case "$1" in
    --march) march="$2"; shift 2 ;;
    --march=*) march="${1#*=}"; shift ;;
    -h|--help) usage 0 ;;
    -*) echo "Unknown option: $1" >&2; usage 1 >&2 ;;
    *) base_dir="$1"; shift ;;
  esac
done
base_dir="$(cd "${base_dir}" && pwd)"
build_dir="${base_dir}/build/${march}"
release_dir="${base_dir}/release"

# First nine characters of the commit of <source> in revisions.txt.
revision() {
  awk -v source="$1" '$1 == source { print substr($2, 1, 9) }' \
    "${build_dir}/revisions.txt"
}

build_name="${TARGET_TRIPLE%%-*}-${march#x86-64-}"
build_date="$(date -u +%Y%m%d)"
mpv_archive="${release_dir}/mpv-${build_name}-${build_date}-git-$(revision mpv).7z"
ffmpeg_archive="${release_dir}/ffmpeg-${build_name}-${build_date}-git-$(revision ffmpeg).7z"

mkdir -p "${release_dir}"
rm -f "${mpv_archive}" "${ffmpeg_archive}"
cd "${build_dir}/sysroot/bin"
7z a -m0=lzma2 -mx=9 -ms=on "${mpv_archive}" mpv.exe mpv.com
7z a -m0=lzma2 -mx=9 -ms=on "${ffmpeg_archive}" ffmpeg.exe
