# mpv-winbuild

Windows builds of mpv and FFmpeg, cross-compiled on Linux with the apt.llvm.org
Clang/LLD toolchain.

Autobuild runs daily at UTC 00:00.

- updater: [sohnyj/app-updater](https://github.com/sohnyj/app-updater)
- single-instance mpv launcher: [sohnyj/umpv-rs](https://github.com/sohnyj/umpv-rs)

## Minimum Requirements

- **OS**: Windows 10 or later
- **CPU**: x86-64-v3 (AVX2)
    - The `znver3` build requires AMD Zen 3.

## Build scripts

The scripts run on Ubuntu 26.04, natively or on WSL2. Defaults such as the CPU
and the LLVM version are in `scripts/defaults.env`. Every script prints its
options with `--help`. All but `install-dependencies.sh` take an optional
trailing `buildroot`, the directory that holds `sources/`, `build/`, `ccache/`,
`rustup/` and `release/` (default: the repository root).

| Script | Purpose |
| ------ | ------- |
| `install-dependencies.sh` | Install the build tools: Clang/LLD from apt.llvm.org, nasm, glslang and ccache, and CMake and Meson through pipx. |
| `build.sh` | Update the sources and build the runtimes and packages for a CPU into `build/<march>/sysroot`, from an empty build directory when the output of `cache-key.sh` changed. |
| `cache-key.sh` | Print the inputs that the stamps do not track: the versions of the build tools and Rust, the mingw-w64 runtime trees and a hash of the recipes. |
| `package.sh` | Pack `mpv.exe`, `mpv.com` and `ffmpeg.exe` of a build into `release/*.7z`. |
| `update.sh` | Move the git sources to the tips of their branches, or to the commits of the `--revisions` file of the last build. |
| `clean.sh` | Delete the build directories, stamps and sources of the git packages given with `--package`, or of all of them, so that the next build clones and builds them again. |

```bash
scripts/install-dependencies.sh
scripts/build.sh    # x86-64-v3
scripts/package.sh
```

## Information about packages

- Git (Nightly)
    - amf-headers
    - brotli
    - bzip2
    - curl (with c-ares, libpsl, nghttp2, nghttp3, ngtcp2)
    - dav1d
    - ffmpeg
    - freetype2
    - fribidi
    - harfbuzz
    - lcms2
    - libarchive
    - libass
    - libbluray (with libudfread)
    - libjpeg-turbo
    - libjxl (with highway)
    - libplacebo (with fast_float, xxhash)
    - libpng
    - libsoxr
    - libunibreak
    - libvpl
    - libxml2
    - libzimg (with graphengine)
    - luajit
    - mpv
    - nv-codec-headers
    - openssl
    - shaderc (with glslang, spirv-headers, spirv-tools)
    - spirv-cross
    - subrandr
    - uchardet
    - vulkan-loader (with vulkan-headers)
    - xz
    - zlib-ng
    - zstd

- Tarball
    - libiconv (1.19)

## Acknowledgements

`cmake/ExternalProject-git-options.patch`, which adds the `GIT_CLONE_FLAGS`,
`GIT_CLONE_POST_COMMAND` and `GIT_RESET` options to ExternalProject, is by
[shinchiro](https://github.com/shinchiro/mpv-winbuild-cmake).
