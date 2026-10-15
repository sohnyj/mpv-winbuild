#!/bin/bash
# Print the inputs that change a build but that the stamps of its build
# directory do not track. build.sh starts from an empty build directory when
# they change, and the workflow puts their hash in its build cache key.
#
# Usage: build-inputs.sh [--llvm-version <major>] [workdir]
#   --llvm-version <major>  apt.llvm.org major version (default: LLVM_VERSION of
#                           defaults.env)
#   workdir                 location of the sources/ directory (default: the
#                           repository root)
set -euo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

repo_root="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"
# shellcheck source=defaults.env
. "${repo_root}/scripts/defaults.env"

llvm_version="${LLVM_VERSION}"
workdir="${repo_root}"
while (( $# > 0 )); do
  case "$1" in
    --llvm-version) llvm_version="$2"; shift 2 ;;
    --llvm-version=*) llvm_version="${1#*=}"; shift ;;
    -h|--help) usage 0 ;;
    -*) echo "Unknown option: $1" >&2; usage 1 >&2 ;;
    *) workdir="$1"; shift ;;
  esac
done
mingw_w64_source="${workdir}/sources/mingw-w64"

package_version() { dpkg-query --show --showformat='${Version}' "$1"; }

# Each value is assigned first, so that a failing command stops the script.
clang_version="$(package_version "clang-${llvm_version}")"
cmake_version="$(cmake --version | awk 'NR == 1 { print $3 }')"
glslang_version="$(package_version glslang-tools)"
meson_version="$(meson --version)"
nasm_version="$(package_version nasm)"
rust_channel=https://static.rust-lang.org/dist/channel-rust-stable.toml
rust_version="$(curl -fsSL "${rust_channel}" | awk -F '"' '
  /^\[pkg\.rust\]/ { found = 1 }
  found && /^version = / { print $2; found = 0 }')"
mingw_w64_trees=()
for dir in mingw-w64-crt mingw-w64-headers mingw-w64-libraries/winpthreads; do
  mingw_w64_trees+=("${dir} $(git -C "${mingw_w64_source}" rev-parse "HEAD:${dir}")")
done
recipes_hash="$(cd "${repo_root}" \
  && git ls-files -z --cached --others --exclude-standard \
    -- CMakeLists.txt cmake toolchain packages \
  | xargs -0 sha256sum | sha256sum | cut -d ' ' -f 1)"

echo "clang ${clang_version}"
echo "cmake ${cmake_version}"
echo "glslang ${glslang_version}"
echo "meson ${meson_version}"
echo "nasm ${nasm_version}"
echo "rust ${rust_version}"
printf '%s\n' "${mingw_w64_trees[@]}"
echo "recipes ${recipes_hash}"
