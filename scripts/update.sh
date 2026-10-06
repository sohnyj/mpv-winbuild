#!/bin/bash
# Move the git sources to the tip of their branches: runs `ninja update` in
# every configured build directory.
#
# Usage: update.sh [buildroot]
#   buildroot  location of the build/ directory (default: the repository root)
set -uo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"

buildroot="${repo_root}"
while (( $# > 0 )); do
  case "$1" in
    -h|--help) usage 0 ;;
    -*) echo "Unknown option: $1" >&2; usage 1 ;;
    *) buildroot="$1"; shift ;;
  esac
done
[[ -d "${buildroot}" ]] || { echo "No such directory: ${buildroot}" >&2; exit 1; }
buildroot="$(cd "${buildroot}" && pwd)"

shopt -s nullglob
status=0
found=0
for dir in "${buildroot}"/build/*/; do
  [[ -f "${dir}build.ninja" ]] || continue
  found=1
  echo ">> Update $(basename "${dir}")"
  ninja -C "${dir}" update || status=1
done

if (( found == 0 )); then
  echo "No configured build directory under ${buildroot}/build" >&2
  exit 1
fi
exit "${status}"
