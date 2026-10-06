#!/bin/bash
# Pack mpv.exe, mpv.com and ffmpeg.exe of a build directory into the release
# archives, named after the level, the date (UTC) and the mpv and FFmpeg commits
# of its revisions.txt.
#
# Usage: package.sh [--march <cpu>] [--level <name>] [buildroot]
#   --march <cpu>   build directory build/<cpu> (default: TARGET_MARCH of defaults.env)
#   --level <name>  level in the archive names, such as v3 or znver3
#                   (default: TARGET_LEVEL of defaults.env)
#   buildroot       location of the build/ directory; the archives are written to
#                   its release/ (default: the repository root)
set -euo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"
# shellcheck source=defaults.env
. "${repo_root}/scripts/defaults.env"

march="${TARGET_MARCH}"
level="${TARGET_LEVEL}"
buildroot="${repo_root}"
while (( $# > 0 )); do
  case "$1" in
    --march) march="$2"; shift 2 ;;
    --march=*) march="${1#*=}"; shift ;;
    --level) level="$2"; shift 2 ;;
    --level=*) level="${1#*=}"; shift ;;
    -h|--help) usage 0 ;;
    -*) echo "Unknown option: $1" >&2; usage 1 ;;
    *) buildroot="$1"; shift ;;
  esac
done
buildroot="$(cd "${buildroot}" && pwd)"
build_dir="${buildroot}/build/${march}"
release_dir="${buildroot}/release"

# The first nine characters of the commit of <project> in revisions.txt.
revision() {
  awk -v project="$1" '$1 == project { print substr($2, 1, 9) }' "${build_dir}/revisions.txt"
}

name="${TARGET_TRIPLE%%-*}-${level}-$(date -u +%Y%m%d)"
mpv_archive="${release_dir}/mpv-${name}-git-$(revision mpv).7z"
ffmpeg_archive="${release_dir}/ffmpeg-${name}-git-$(revision ffmpeg).7z"

mkdir -p "${release_dir}"
rm -f "${mpv_archive}" "${ffmpeg_archive}"
cd "${build_dir}/sysroot/bin"
7z a -m0=lzma2 -mx=9 -ms=on "${mpv_archive}" mpv.exe mpv.com
7z a -m0=lzma2 -mx=9 -ms=on "${ffmpeg_archive}" ffmpeg.exe
