#!/bin/bash
# Configure and build the runtimes and packages for a target CPU, from sources
# at the tips of their branches or at the commits of --revisions. The commits
# are written to build/<cpu>/revisions.txt.
#
# Usage: build.sh [--march <cpu>] [--mtune <cpu>] [--llvm-version <major>]
#                 [--revisions <file>] [--sources-only] [buildroot]
#   --march <cpu>           clang -march of the packages (default: PACKAGE_MARCH of defaults.env;
#                           e.g. x86-64-v3, znver3)
#   --mtune <cpu>           clang -mtune of the packages (default: PACKAGE_MTUNE of defaults.env)
#   --llvm-version <major>  apt.llvm.org major version (default: LLVM_VERSION of defaults.env)
#   --revisions <file>      move the git sources to the commits of a revisions.txt
#                           instead of the tips of their branches
#   --sources-only          stop after updating the sources and writing revisions.txt
#   buildroot               location of the sources/, rustup/, ccache/ and build/ directories
#                           (default: the repository root)
set -euo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"
# shellcheck source=defaults.env
. "${repo_root}/scripts/defaults.env"

llvm_version="${LLVM_VERSION}"
march="${PACKAGE_MARCH}"
mtune="${PACKAGE_MTUNE}"
revisions=""
sources_only=false
buildroot="${repo_root}"
while (( $# > 0 )); do
  case "$1" in
    --march) march="$2"; shift 2 ;;
    --march=*) march="${1#*=}"; shift ;;
    --mtune) mtune="$2"; shift 2 ;;
    --mtune=*) mtune="${1#*=}"; shift ;;
    --llvm-version) llvm_version="$2"; shift 2 ;;
    --llvm-version=*) llvm_version="${1#*=}"; shift ;;
    --revisions) revisions="$(realpath "$2")"; shift 2 ;;
    --revisions=*) revisions="$(realpath "${1#*=}")"; shift ;;
    --sources-only) sources_only=true; shift ;;
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
  -DPACKAGE_CPU_FLAGS="-march=${march} -mtune=${mtune}" \
  -DPACKAGE_RUST_FLAGS="-C target-cpu=${march}" \
  -DRUNTIME_CPU_FLAGS="-march=${RUNTIME_MARCH} -mtune=${RUNTIME_MTUNE}" \
  -DLTO_MODE="${LTO_MODE}" \
  -DMAKE_JOBS="$(nproc)" \
  -DSYSROOT_DIR="${build_dir}/sysroot" \
  -DSOURCES_DIR="${buildroot}/sources" \
  -DRUSTUP_DIR="${buildroot}/rustup" \
  -DCCACHE_DIR="${buildroot}/ccache" \
  -DSOURCE_REVISIONS_FILE="${revisions}"

echo ">> Download sources"
ninja -C "${build_dir}" download

echo ">> Update git sources"
ninja -C "${build_dir}" update
ninja -C "${build_dir}" revisions
if [[ "${sources_only}" == true ]]; then
  exit 0
fi

echo ">> Build"
ccache --dir "${buildroot}/ccache" --max-size "${CCACHE_MAXSIZE}"
ninja -C "${build_dir}"
