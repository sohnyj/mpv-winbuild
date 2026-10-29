# mpv-winbuild

Windows builds of mpv and FFmpeg, cross-compiled on Linux with the apt.llvm.org
Clang/LLD toolchain.

Autobuild runs daily at UTC 00:00.

- updater: [sohnyj/app-updater](https://github.com/sohnyj/app-updater)
- single-instance mpv launcher: [sohnyj/umpv-rs](https://github.com/sohnyj/umpv-rs)

## Minimum Requirements

- **OS**: Windows 10 (x64)
- **CPU**: that of the build, in the table below

## Builds

| Build | CPU | Extra filter |
| ----- | --- | ------------ |
| `x86_64-v3` | x86-64-v3 (AVX2) | |
| `x86_64-znver3` | AMD Zen 3 or newer | |
| `x86_64-v3_cropdetect-vk` | x86-64-v3 (AVX2) | `cropdetect_vulkan` |
| `x86_64-znver3_cropdetect-vk` | AMD Zen 3 or newer | `cropdetect_vulkan` |

`cropdetect_vulkan` is the filter of
[cropdetect-vk](https://github.com/sohnyj/cropdetect-vk); both mpv and FFmpeg
of those builds have it.

## Build scripts

- The scripts run on Ubuntu 26.04, natively or on WSL2.
- Defaults such as the CPU and the LLVM version are in `scripts/defaults.env`.

| Script | Purpose |
| ------ | ------- |
| `install-dependencies.sh` | Install the build tools: Clang/LLD from apt.llvm.org, nasm, glslang and ccache, and CMake and Meson through pipx. |
| `build.sh` | Update the sources and build the runtimes and packages for a CPU into `build/<march>/sysroot`, from an empty build directory when the output of `build-inputs.sh` changed. |
| `build-inputs.sh` | Print the inputs that the stamps do not track: the versions of the build tools and Rust, the mingw-w64 runtime trees and a hash of the recipes. |
| `package.sh` | Pack `mpv.exe`, `mpv.com` and `ffmpeg.exe` of a build into `release/*.7z`. |
| `update.sh` | Move the git sources to the tips of their branches, or to the commits of the `--revisions` file of the last build. |
| `clean.sh` | Delete the build directories, stamps and sources of the given packages and toolchain components, or of every git clone under `sources/`, so that the next build downloads and builds them again. |

```bash
scripts/install-dependencies.sh
scripts/build.sh    # x86-64-v3
scripts/package.sh
```

## Information about packages

- Git (Nightly)
    - [amf-headers](https://github.com/GPUOpen-LibrariesAndSDKs/AMF)
    - [brotli](https://github.com/google/brotli)
    - [bzip2](https://gitlab.com/bzip2/bzip2)
    - [curl](https://github.com/curl/curl) (with [c-ares](https://github.com/c-ares/c-ares), [libpsl](https://github.com/rockdaboot/libpsl), [nghttp2](https://github.com/nghttp2/nghttp2), [nghttp3](https://github.com/ngtcp2/nghttp3), [ngtcp2](https://github.com/ngtcp2/ngtcp2))
    - [dav1d](https://code.videolan.org/videolan/dav1d)
    - [ffmpeg](https://github.com/FFmpeg/FFmpeg)
    - [freetype](https://github.com/freetype/freetype)
    - [fribidi](https://github.com/fribidi/fribidi)
    - [harfbuzz](https://github.com/harfbuzz/harfbuzz)
    - [lcms](https://github.com/mm2/Little-CMS)
    - [libarchive](https://github.com/libarchive/libarchive)
    - [libass](https://github.com/libass/libass)
    - [libbluray](https://code.videolan.org/videolan/libbluray) (with [libudfread](https://code.videolan.org/videolan/libudfread))
    - [libjpeg-turbo](https://github.com/libjpeg-turbo/libjpeg-turbo)
    - [libjxl](https://github.com/libjxl/libjxl) (with [highway](https://github.com/google/highway))
    - [libplacebo](https://github.com/haasn/libplacebo) (with [fast_float](https://github.com/fastfloat/fast_float), [xxhash](https://github.com/Cyan4973/xxHash))
    - [libpng](https://github.com/glennrp/libpng)
    - [libsoxr](https://github.com/chirlu/soxr)
    - [libunibreak](https://github.com/adah1972/libunibreak)
    - [libvpl](https://github.com/intel/libvpl)
    - [libxml2](https://github.com/GNOME/libxml2)
    - [libzimg](https://github.com/sekrit-twc/zimg) (with [graphengine](https://github.com/sekrit-twc/graphengine))
    - [luajit](https://github.com/LuaJIT/LuaJIT)
    - [mpv](https://github.com/mpv-player/mpv)
    - [nv-codec-headers](https://github.com/FFmpeg/nv-codec-headers)
    - [openssl](https://github.com/openssl/openssl)
    - [shaderc](https://github.com/google/shaderc) (with [glslang](https://github.com/KhronosGroup/glslang), [spirv-headers](https://github.com/KhronosGroup/SPIRV-Headers), [spirv-tools](https://github.com/KhronosGroup/SPIRV-Tools))
    - [spirv-cross](https://github.com/KhronosGroup/SPIRV-Cross)
    - [subrandr](https://github.com/afishhh/subrandr)
    - [uchardet](https://gitlab.freedesktop.org/uchardet/uchardet)
    - [vulkan-loader](https://github.com/KhronosGroup/Vulkan-Loader) (with [vulkan-headers](https://github.com/KhronosGroup/Vulkan-Headers))
    - [xz](https://github.com/tukaani-project/xz)
    - [zlib-ng](https://github.com/zlib-ng/zlib-ng)
    - [zstd](https://github.com/facebook/zstd)

- Tarball
    - [libiconv](https://ftp.gnu.org/pub/gnu/libiconv/) (1.19)

## Acknowledgements

`cmake/ExternalProject-git-options.patch`, which adds the `GIT_CLONE_FLAGS`,
`GIT_CLONE_POST_COMMAND` and `GIT_RESET` options to ExternalProject, is by
[shinchiro](https://github.com/shinchiro/mpv-winbuild-cmake).
