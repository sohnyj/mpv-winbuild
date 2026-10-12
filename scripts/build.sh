#!/bin/bash
# Configure and build runtimes and packages for a target CPU. Commits of git
# sources are written to build/<cpu>/revisions.txt. When build-inputs.sh output
# differs from build/<cpu>/build-inputs.txt, the build directory is emptied
# first.
#
# Usage: build.sh [--march <cpu>] [--mtune <cpu>] [--llvm-version <major>]
#                 [--revisions <file>] [--sources-only] [base_dir]
#   --march <cpu>           clang -march of packages, such as x86-64-v3 or
#                           znver3 (default: PACKAGE_MARCH of defaults.env),
#                           where a _cropdetect suffix only names the build
#                           directory
#   --mtune <cpu>           clang -mtune of packages (default: PACKAGE_MTUNE of
#                           defaults.env)
#   --llvm-version <major>  apt.llvm.org major version (default: LLVM_VERSION of
#                           defaults.env)
#   --revisions <file>      move git sources to the commits of a revisions.txt
#                           instead of their branch tips (a recipe's COMMIT
#                           takes precedence)
#   --sources-only          stop after updating sources and writing
#                           revisions.txt
#   base_dir                location of sources/, ccache/ and build/ (default:
#                           repository root)
set -euo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"
# shellcheck source=defaults.env
. "${repo_root}/scripts/defaults.env"

llvm_version="${LLVM_VERSION}"
march="${PACKAGE_MARCH}"
mtune="${PACKAGE_MTUNE}"
revisions_file=""
sources_only=false
base_dir="${repo_root}"
while (( $# > 0 )); do
  case "$1" in
    --march) march="$2"; shift 2 ;;
    --march=*) march="${1#*=}"; shift ;;
    --mtune) mtune="$2"; shift 2 ;;
    --mtune=*) mtune="${1#*=}"; shift ;;
    --llvm-version) llvm_version="$2"; shift 2 ;;
    --llvm-version=*) llvm_version="${1#*=}"; shift ;;
    --revisions) revisions_file="$(realpath "$2")"; shift 2 ;;
    --revisions=*) revisions_file="$(realpath "${1#*=}")"; shift ;;
    --sources-only) sources_only=true; shift ;;
    -h|--help) usage 0 ;;
    -*) echo "Unknown option: $1" >&2; usage 1 >&2 ;;
    *) base_dir="$1"; shift ;;
  esac
done
mkdir -p "${base_dir}"
base_dir="$(cd "${base_dir}" && pwd)"
build_dir="${base_dir}/build/${march}"
build_inputs_file="${build_dir}/build-inputs.txt"

configure() {
  echo ">> Configure -march=${march} -mtune=${mtune} in ${build_dir}"
  cmake -G Ninja --fresh -S "${repo_root}" -B "${build_dir}" \
    -DLLVM_VERSION="${llvm_version}" \
    -DTARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DPACKAGE_CPU_FLAGS="-march=${march%_cropdetect} -mtune=${mtune}" \
    -DPACKAGE_RUST_CPU_FLAGS="-C target-cpu=${march%_cropdetect}" \
    -DRUNTIME_CPU_FLAGS="-march=${RUNTIME_MARCH} -mtune=${RUNTIME_MTUNE}" \
    -DLTO_MODE="${LTO_MODE}" \
    -DMAKE_JOBS="$(nproc)" \
    -DCCACHE_DIR="${base_dir}/ccache" \
    -DSOURCES_DIR="${base_dir}/sources" \
    -DRUSTUP_DIR="${build_dir}/rustup" \
    -DSYSROOT_DIR="${build_dir}/sysroot" \
    -DSOURCE_REVISIONS_FILE="${revisions_file}"
}

configured_before=false
if [[ -f "${build_dir}/build.ninja" ]]; then
  configured_before=true
fi
configure

echo ">> Download sources"
ninja -C "${build_dir}" download

echo ">> Update git sources"
ninja -C "${build_dir}" update
ninja -C "${build_dir}" revisions
if [[ "${sources_only}" == true ]]; then
  exit 0
fi

# The inputs include trees of the mingw-w64 checkout, so they are read after
# the update.
build_inputs="$("${repo_root}/scripts/build-inputs.sh" \
  --llvm-version "${llvm_version}" "${base_dir}")"
if [[ "${configured_before}" == true ]] && [[ ! -f "${build_inputs_file}" \
  || "$(< "${build_inputs_file}")" != "${build_inputs}" ]]; then
  echo ">> Start from empty build directory, since the build-inputs.sh output" \
    "changed"
  rm -rf "${build_dir:?}"
  configure
  ninja -C "${build_dir}" revisions
fi
echo "${build_inputs}" > "${build_inputs_file}"

echo ">> Build"
ccache --dir "${base_dir}/ccache" --max-size "${CCACHE_MAXSIZE}"
ninja -C "${build_dir}"
