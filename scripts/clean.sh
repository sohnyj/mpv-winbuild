#!/bin/bash
# Delete the build directories, stamps and sources of git packages, so that
# the next build clones and builds them again: runs <package>-fullclean and
# <package>-removesource.
#
# Usage: clean.sh [-p <package>]... [buildroot]
#   -p, --package <package>  package to clean (repeatable; default: every git
#                            source clone)
#   buildroot                location of the sources/ and build/ directories
#                            (default: the repository root)
set -uo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"

buildroot="${repo_root}"
packages=()
while (( $# > 0 )); do
  case "$1" in
    -p|--package) packages+=("$2"); shift 2 ;;
    --package=*) packages+=("${1#*=}"); shift ;;
    -h|--help) usage 0 ;;
    -*) echo "Unknown option: $1" >&2; usage 1 >&2 ;;
    *) buildroot="$1"; shift ;;
  esac
done
if [[ ! -d "${buildroot}" ]]; then
  echo "No such directory: ${buildroot}" >&2
  exit 1
fi
buildroot="$(cd "${buildroot}" && pwd)"

sources="${buildroot}/sources"
if [[ ! -d "${sources}" ]]; then
  echo "No sources directory under ${buildroot}" >&2
  exit 1
fi

shopt -s nullglob

build_dirs=()
for dir in "${buildroot}"/build/*/; do
  [[ -f "${dir}build.ninja" ]] && build_dirs+=("${dir}")
done
if (( ${#build_dirs[@]} == 0 )); then
  echo "No configured build directory under ${buildroot}/build" >&2
  exit 1
fi

ninja_targets="$(ninja -C "${build_dirs[0]}" -t targets all)" || exit 1

has_clean_target() {
  awk -F: -v target="$1-fullclean" \
    '$1 == target { found = 1 } END { exit !found }' <<< "${ninja_targets}"
}

if (( ${#packages[@]} == 0 )); then
  for dir in "${sources}"/*/; do
    package="$(basename "${dir}")"
    [[ -d "${dir}.git" ]] || continue
    if ! has_clean_target "${package}"; then
      echo "Skip ${package}: not a package of this checkout" >&2
      continue
    fi
    packages+=("${package}")
  done
else
  for package in "${packages[@]}"; do
    if ! has_clean_target "${package}"; then
      echo "No clean target for ${package}: not a package of this checkout" >&2
      exit 1
    fi
  done
fi
if (( ${#packages[@]} == 0 )); then
  echo "Nothing to clean under ${sources}" >&2
  exit 1
fi

status=0
for package in "${packages[@]}"; do
  echo ">> Clean ${package}"
  for dir in "${build_dirs[@]}"; do
    ninja -C "${dir}" "${package}-fullclean" || status=1
    ninja -C "${dir}" "${package}-removesource" || status=1
  done
done

echo ">> Done."
exit "${status}"
