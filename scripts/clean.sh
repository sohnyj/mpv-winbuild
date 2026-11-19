#!/bin/bash
# Delete the build directories, stamps and sources of the given packages and
# toolchain components, so that the next build downloads and builds them again:
# runs <name>-delete-stamps and <name>-remove-prefix-and-source.
#
# Usage: clean.sh [--fresh-ccache] [--package <package>]...
#                 [--toolchain <component>]... [base_dir]
#   --fresh-ccache           clear the ccache
#   --package <package>      package to clean (repeatable)
#   --toolchain <component>  toolchain component to clean (repeatable)
#   base_dir                 location of the sources/, build/ and ccache/
#                            directories (default: the repository root)
# Without --fresh-ccache, --package and --toolchain, every git clone under
# sources/ is cleaned.
#
# Cleaning a component that builds from another's source, such as libcxx from
# llvm, deletes that source; clean the source's component instead.
set -uo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"

base_dir="${repo_root}"
fresh_ccache=false
packages=()
toolchain_components=()
while (( $# > 0 )); do
  case "$1" in
    --fresh-ccache) fresh_ccache=true; shift ;;
    --package) packages+=("$2"); shift 2 ;;
    --package=*) packages+=("${1#*=}"); shift ;;
    --toolchain) toolchain_components+=("$2"); shift 2 ;;
    --toolchain=*) toolchain_components+=("${1#*=}"); shift ;;
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

# clear_ccache: empty <base_dir>/ccache. --clear keeps ccache.conf, which holds
# the size limit that build.sh writes.
clear_ccache() {
  local ccache_dir="${base_dir}/ccache"
  if [[ ! -d "${ccache_dir}" ]]; then
    echo "No ccache directory under ${base_dir}" >&2
    return 0
  fi
  echo ">> Clear ${ccache_dir}"
  ccache --dir "${ccache_dir}" --clear
}

if [[ "${fresh_ccache}" == true ]] \
  && (( ${#packages[@]} == 0 && ${#toolchain_components[@]} == 0 )); then
  clear_ccache
  exit
fi

sources_dir="${base_dir}/sources"
if [[ ! -d "${sources_dir}" ]]; then
  echo "No sources directory under ${base_dir}" >&2
  exit 1
fi

shopt -s nullglob

build_dirs=()
for dir in "${base_dir}"/build/*/; do
  [[ -f "${dir}build.ninja" ]] && build_dirs+=("${dir}")
done
if (( ${#build_dirs[@]} == 0 )); then
  echo "No configured build directory under ${base_dir}/build" >&2
  exit 1
fi

ninja_targets="$(ninja -C "${build_dirs[0]}" -t targets all)" || exit 1

# has_clean_target <directory> <name>: the recipe <name> of toolchain/ or
# packages/ has the clean targets.
has_clean_target() {
  awk -F: -v target="$1/$2-delete-stamps" \
    '$1 == target { found = 1 } END { exit !found }' <<< "${ninja_targets}"
}

names=()
if (( ${#packages[@]} == 0 && ${#toolchain_components[@]} == 0 )); then
  for dir in "${sources_dir}"/*/; do
    name="$(basename "${dir}")"
    [[ -d "${dir}.git" ]] || continue
    if ! has_clean_target packages "${name}" \
      && ! has_clean_target toolchain "${name}"; then
      echo "Skip ${name}: not a package or toolchain component of this checkout" >&2
      continue
    fi
    names+=("${name}")
  done
else
  for package in "${packages[@]}"; do
    if ! has_clean_target packages "${package}"; then
      echo "No clean target for ${package}: not a package of this checkout" >&2
      exit 1
    fi
    names+=("${package}")
  done
  for toolchain_component in "${toolchain_components[@]}"; do
    if ! has_clean_target toolchain "${toolchain_component}"; then
      echo "No clean target for ${toolchain_component}: not a toolchain component of this checkout" >&2
      exit 1
    fi
    names+=("${toolchain_component}")
  done
fi
if (( ${#names[@]} == 0 )); then
  echo "Nothing to clean under ${sources_dir}" >&2
  exit 1
fi

status=0
for name in "${names[@]}"; do
  echo ">> Clean ${name}"
  for dir in "${build_dirs[@]}"; do
    ninja -C "${dir}" "${name}-delete-stamps" || status=1
    ninja -C "${dir}" "${name}-remove-prefix-and-source" || status=1
  done
done

if [[ "${fresh_ccache}" == true ]]; then
  clear_ccache || status=1
fi

echo ">> Done."
exit "${status}"
