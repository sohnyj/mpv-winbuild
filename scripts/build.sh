#!/bin/bash
# Configure and build mpv-winbuild for a target CPU: the runtimes, then the
# packages, from sources moved to the tip of their branches.
#
# Usage: build.sh [--march <cpu>] [--mtune <cpu>] [--llvm-version <major>] [buildroot]
#   --march <cpu>           clang -march of the packages (default: TARGET_MARCH of defaults.sh;
#                           e.g. x86-64-v3, znver3)
#   --mtune <cpu>           clang -mtune of the packages (default: TARGET_MTUNE of defaults.sh)
#   --llvm-version <major>  apt.llvm.org major version (default: LLVM_VERSION of defaults.sh)
#   buildroot               location of the sources/ and build/ directories
#                           (default: the repository root)
set -euo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"
# shellcheck source=defaults.sh
. "${repo_root}/scripts/defaults.sh"

march="${TARGET_MARCH}"
mtune="${TARGET_MTUNE}"
llvm_version="${LLVM_VERSION}"
buildroot="${repo_root}"
while (( $# > 0 )); do
  case "$1" in
    --march) march="$2"; shift 2 ;;
    --march=*) march="${1#*=}"; shift ;;
    --mtune) mtune="$2"; shift 2 ;;
    --mtune=*) mtune="${1#*=}"; shift ;;
    --llvm-version) llvm_version="$2"; shift 2 ;;
    --llvm-version=*) llvm_version="${1#*=}"; shift ;;
    -h|--help) usage 0 ;;
    -*) echo "Unknown option: $1" >&2; usage 1 ;;
    *) buildroot="$1"; shift ;;
  esac
done
mkdir -p "${buildroot}"
buildroot="$(cd "${buildroot}" && pwd)"
build_dir="${buildroot}/build/${march}"

echo ">> Configure -march=${march} -mtune=${mtune} in ${build_dir}"
cmake -G Ninja --fresh -S "${repo_root}" -B "${build_dir}" \
  -DLLVM_VERSION="${llvm_version}" \
  -DTARGET_TRIPLE="${TARGET_TRIPLE}" \
  -DTARGET_CPU_FLAGS="-march=${march} -mtune=${mtune}" \
  -DRUNTIME_CPU_FLAGS="-march=${RUNTIME_MARCH} -mtune=${RUNTIME_MTUNE}" \
  -DLTO_MODE="${LTO_MODE}" \
  -DMAKE_JOBS="$(nproc)" \
  -DSYSROOT_DIR="${build_dir}/sysroot" \
  -DSOURCES_DIR="${buildroot}/sources"

echo ">> Download sources"
ninja -C "${build_dir}" download

echo ">> Update git sources"
ninja -C "${build_dir}" update

echo ">> Build"
ninja -C "${build_dir}"
