#!/bin/bash
# Run `ninja update` in every configured build directory, which moves the git
# sources to the tips of their branches, or to the commits of the --revisions
# file the directory was last configured with.
#
# Usage: update.sh [base_dir]
#   base_dir  location of the build/ directory (default: the repository root)
set -uo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"

base_dir="${repo_root}"
while (( $# > 0 )); do
  case "$1" in
    -h|--help) usage 0 ;;
    -*) echo "Unknown option: $1" >&2; usage 1 >&2 ;;
    *) base_dir="$1"; shift ;;
  esac
done
if [[ ! -d "${base_dir}" ]]; then
  echo "No such directory: ${base_dir}" >&2
  exit 1
fi
base_dir="$(cd "${base_dir}" && pwd)"

shopt -s nullglob
status=0
found=0
for dir in "${base_dir}"/build/*/; do
  [[ -f "${dir}build.ninja" ]] || continue
  found=1
  echo ">> Update $(basename "${dir}")"
  ninja -C "${dir}" update || status=1
done

if (( found == 0 )); then
  echo "No configured build directory under ${base_dir}/build" >&2
  exit 1
fi
exit "${status}"
