#!/bin/bash
# Delete what the next build would reuse, so that it downloads and builds again.
#
# Usage: clean.sh [--fresh-build] [--fresh-ccache] [--package <package>]...
#                 [--toolchain <component>]... [base_dir]
#   --fresh-build            delete sources/ and build/, as the fresh_build
#                            input of the workflow ignores their caches
#   --fresh-ccache           clear the ccache, as the fresh_ccache input of the
#                            workflow ignores its cache
#   --package <package>      package to clean (repeatable)
#   --toolchain <component>  toolchain component to clean (repeatable)
#   base_dir                 location of the sources/, build/ and ccache/
#                            directories (default: the repository root)
# Without --fresh-build, --fresh-ccache, --package and --toolchain, print this
# help.
#
# Cleaning a package or toolchain component deletes its build directories,
# stamps and source: runs <name>-delete-stamps and
# <name>-remove-prefix-and-source. Cleaning a component that builds from
# another's source, such as libcxx from llvm, deletes that source; clean the
# source's component instead.
set -uo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"

base_dir="${repo_root}"
fresh_build=false
fresh_ccache=false
packages=()
toolchain_components=()
while (( $# > 0 )); do
  case "$1" in
    --fresh-build) fresh_build=true; shift ;;
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
recipes_given=false
if (( ${#packages[@]} > 0 || ${#toolchain_components[@]} > 0 )); then
  recipes_given=true
fi
if [[ "${fresh_build}" == false && "${fresh_ccache}" == false \
  && "${recipes_given}" == false ]]; then
  usage 0
fi
if [[ "${fresh_build}" == true && "${recipes_given}" == true ]]; then
  echo "--fresh-build deletes every package and toolchain component:" \
    "drop --package and --toolchain" >&2
  exit 1
fi
if [[ ! -d "${base_dir}" ]]; then
  echo "No such directory: ${base_dir}" >&2
  exit 1
fi
base_dir="$(cd "${base_dir}" && pwd)"

ninja_targets=""

# has_clean_target <directory> <name>: the recipe <name> of toolchain/ or
# packages/ has the clean targets.
has_clean_target() {
  awk -F: -v target="$1/$2-delete-stamps" \
    '$1 == target { found = 1 } END { exit !found }' <<< "${ninja_targets}"
}

# delete_sources_and_build: delete <base_dir>/sources and <base_dir>/build. The
# stamps of every build directory refer to the shared sources, so both are
# deleted together.
delete_sources_and_build() {
  echo ">> Delete ${base_dir}/sources and ${base_dir}/build"
  rm -rf -- "${base_dir}/sources" "${base_dir}/build"
}

# clean_recipes: run the clean targets of the packages and toolchain components
# in every configured build directory. Every name is checked before anything is
# deleted.
clean_recipes() {
  local sources_dir="${base_dir}/sources"
  if [[ ! -d "${sources_dir}" ]]; then
    echo "No sources directory under ${base_dir}" >&2
    exit 1
  fi

  local build_dirs=() dir
  shopt -s nullglob
  for dir in "${base_dir}"/build/*/; do
    [[ -f "${dir}build.ninja" ]] && build_dirs+=("${dir}")
  done
  shopt -u nullglob
  if (( ${#build_dirs[@]} == 0 )); then
    echo "No configured build directory under ${base_dir}/build" >&2
    exit 1
  fi

  ninja_targets="$(ninja -C "${build_dirs[0]}" -t targets all)" || exit 1

  local package toolchain_component
  for package in "${packages[@]}"; do
    if ! has_clean_target packages "${package}"; then
      echo "No clean target for ${package}: not a package of this checkout" >&2
      exit 1
    fi
  done
  for toolchain_component in "${toolchain_components[@]}"; do
    if ! has_clean_target toolchain "${toolchain_component}"; then
      echo "No clean target for ${toolchain_component}: not a toolchain component of this checkout" >&2
      exit 1
    fi
  done

  local name result=0
  for name in "${packages[@]}" "${toolchain_components[@]}"; do
    echo ">> Clean ${name}"
    for dir in "${build_dirs[@]}"; do
      ninja -C "${dir}" "${name}-delete-stamps" || result=1
      ninja -C "${dir}" "${name}-remove-prefix-and-source" || result=1
    done
  done
  return "${result}"
}

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

status=0
if [[ "${fresh_build}" == true ]]; then
  delete_sources_and_build || status=1
fi
if [[ "${recipes_given}" == true ]]; then
  clean_recipes || status=1
fi
if [[ "${fresh_ccache}" == true ]]; then
  clear_ccache || status=1
fi

echo ">> Done."
exit "${status}"
