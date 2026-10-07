#!/bin/bash
# Install the host tools needed to build mpv-winbuild on Ubuntu 26.04.
#
# Usage: install-dependencies.sh [--llvm-version <major>]
#   --llvm-version <major>  apt.llvm.org major version (default: LLVM_VERSION of
#                           defaults.env)
#
# Run as a regular user: system packages are installed through sudo, and
# CMake and Meson are installed into the user's pipx environment.
set -euo pipefail

usage() { sed -n '2,${/^#/!q;s/^# \?//p}' "$0"; exit "${1:-0}"; }

script_dir="$(dirname "$(realpath "$0")")"
# shellcheck source=defaults.env
. "${script_dir}/defaults.env"

llvm_version="${LLVM_VERSION}"
while (( $# > 0 )); do
  case "$1" in
    --llvm-version) llvm_version="$2"; shift 2 ;;
    --llvm-version=*) llvm_version="${1#*=}"; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 >&2 ;;
  esac
done

if (( EUID == 0 )); then
  echo "Run as a regular user, not with sudo: pipx installs into the" \
    "invoking user's home, and the script calls sudo where it needs it." >&2
  exit 1
fi

# shellcheck source=/dev/null
. /etc/os-release
codename="${VERSION_CODENAME}"

suite="llvm-toolchain-${codename}-${llvm_version}"
release_url="https://apt.llvm.org/${codename}/dists/${suite}/Release"
if ! curl -fsIL "${release_url}" > /dev/null; then
  echo "apt.llvm.org has no release suite ${suite}" >&2
  exit 1
fi

sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key \
  | sudo tee /etc/apt/keyrings/apt.llvm.org.asc > /dev/null
sudo tee /etc/apt/sources.list.d/apt.llvm.org.sources > /dev/null <<EOF
Types: deb
URIs: https://apt.llvm.org/${codename}/
Suites: ${suite}
Components: main
Signed-By: /etc/apt/keyrings/apt.llvm.org.asc
EOF

sudo apt-get update
sudo apt-get install -y \
  7zip \
  autoconf \
  automake \
  autopoint \
  build-essential \
  ca-certificates \
  ccache \
  "clang-${llvm_version}" \
  curl \
  git \
  glslang-tools \
  "libclang-common-${llvm_version}-dev" \
  libtool \
  "lld-${llvm_version}" \
  "llvm-${llvm_version}" \
  make \
  nasm \
  ninja-build \
  pipx \
  pkgconf \
  python3

pipx install cmake
pipx install meson
