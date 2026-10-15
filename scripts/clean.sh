#!/bin/bash
# Delete the build directories, stamps and sources of the given packages and
# toolchain components, so that the next build downloads and builds them again:
# runs <name>-delete-stamps and <name>-remove-prefix-and-source.
#
# Usage: clean.sh [--package <package>]... [--toolchain <component>]...
#                 [workdir]
#   --package <package>      package to clean (repeatable)
#   --toolchain <component>  toolchain component to clean (repeatable)
#   workdir                  location of the sources/ and build/ directories
#                            (default: the repository root)
# Without --package and --toolchain, every git source clone is cleaned.
#
# Cleaning a component that builds from another's source, such as libcxx from
# llvm-project, deletes that source; clean the source's component instead.
set -uo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"

workdir="${repo_root}"
packages=()
toolchain_components=()
while (( $# > 0 )); do
  case "$1" in
    --package) packages+=("$2"); shift 2 ;;
    --package=*) packages+=("${1#*=}"); shift ;;
    --toolchain) toolchain_components+=("$2"); shift 2 ;;
    --toolchain=*) toolchain_components+=("${1#*=}"); shift ;;
    -h|--help) usage 0 ;;
    -*) echo "Unknown option: $1" >&2; usage 1 >&2 ;;
    *) workdir="$1"; shift ;;
  esac
done
if [[ ! -d "${workdir}" ]]; then
  echo "No such directory: ${workdir}" >&2
  exit 1
fi
workdir="$(cd "${workdir}" && pwd)"

sources_dir="${workdir}/sources"
if [[ ! -d "${sources_dir}" ]]; then
  echo "No sources directory under ${workdir}" >&2
  exit 1
fi

shopt -s nullglob

build_dirs=()
for dir in "${workdir}"/build/*/; do
  [[ -f "${dir}build.ninja" ]] && build_dirs+=("${dir}")
done
if (( ${#build_dirs[@]} == 0 )); then
  echo "No configured build directory under ${workdir}/build" >&2
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

echo ">> Done."
exit "${status}"
