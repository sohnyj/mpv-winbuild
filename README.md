# mpv-winbuild

Windows builds of mpv and FFmpeg, cross-compiled on Linux with the apt.llvm.org
LLVM toolchain.

- Every git source of packages and toolchain is built from the latest commit of
  its branch at build time.
- The `-march` and `-mtune` values in `scripts/defaults.env` are applied to
  runtimes and packages.
- The build system uses CMake's ExternalProject module as shipped, extended
  through its public API.

Autobuild runs daily at UTC 00:00.

- updater: [sohnyj/app-updater](https://github.com/sohnyj/app-updater)
- single-instance mpv launcher: [sohnyj/umpv-rs](https://github.com/sohnyj/umpv-rs)

## Minimum Requirements

- **OS**: Windows 10 (x64)
- **CPU**: see [Builds](#builds)

## Builds

| Build | CPU | Extra filters |
| ----- | --- | ------------- |
| `x86_64-v3` | AVX2 required | |
| `x86_64-znver3` | AMD Zen 3 or newer | |
| `x86_64-v3_cropdetect` | AVX2 required | [`cropdetect_filters`](https://github.com/sohnyj/cropdetect-filters) |
| `x86_64-znver3_cropdetect` | AMD Zen 3 or newer | [`cropdetect_filters`](https://github.com/sohnyj/cropdetect-filters) |

## Build scripts

- The scripts run on Ubuntu 26.04, natively or on WSL2.
- Defaults such as CPU and LLVM version are in `scripts/defaults.env`.

| Script | Purpose |
| ------ | ------- |
| `install-dependencies.sh` | Install build tools. |
| `build.sh` | Update sources and build runtimes and packages for a CPU into `build/<march>/sysroot`. |
| `build-inputs.sh` | Print inputs that stamps do not track. `build.sh` empties the build directory when they change. |
| `package.sh` | Pack `mpv.exe`, `mpv.com` and `ffmpeg.exe` into `release/*.7z`. |
| `update.sh` | Move git sources to their branch tips, or to the commits that `build.sh --revisions` set. |
| `clean.sh` | Delete build directories, stamps and sources, or clear the ccache. |

```bash
scripts/install-dependencies.sh
scripts/build.sh    # x86-64-v3
scripts/package.sh
```

## CMake functions

Recipes in `toolchain/` and `packages/` call these functions from `cmake/`.

```cmake
add_toolchain_profile(<profile> <cpu flags> <preprocessor flags>
                      <code generation flags>)
add_git_steps(<name> REPOSITORY <url> BRANCH <branch>
              [CLONE_FLAGS <flags>] [CLONE_POST_COMMAND <git arguments>]
              [COMMIT <commit>] [SUBMODULES <path>...]
              [PATCHES <file>...] [PATCH_FLAGS <flags>])
add_cleanup_steps(<name> <last step>)
```

| Function | Purpose |
| -------- | ------- |
| `add_toolchain_profile` | Generate a toolchain profile for CPU, preprocessor and code generation flags. |
| `add_git_steps` | Clone a git source and keep its checkout at the target commit. |
| `add_cleanup_steps` | Add step targets that delete stamps, or prefix and source, and for a git source clean its build directory and checkout after `<last step>`. |

| `add_git_steps` option | Purpose |
| ---------------------- | ------- |
| `REPOSITORY`, `BRANCH` | Clone `BRANCH` of `REPOSITORY`. |
| `CLONE_FLAGS` | Pass these flags to `git clone`, such as `--sparse --filter=tree:0`. |
| `CLONE_POST_COMMAND` | Run git with these arguments after cloning, such as `sparse-checkout set`. |
| `COMMIT` | Check out this commit instead of the branch tip or the commit that `build.sh --revisions` set. |
| `SUBMODULES` | Check out only these submodules, or none when given as `""`. Without it, all submodules are checked out. |
| `PATCHES` | Apply these patch files with `git apply`, in order. Relative paths are relative to the recipe directory. |
| `PATCH_FLAGS` | Pass these flags to `git apply`, such as `--3way`. |

## Information about packages

- Git (Nightly)
    - [amf-headers](https://github.com/GPUOpen-LibrariesAndSDKs/AMF)
    - [brotli](https://github.com/google/brotli)
    - [bzip2](https://sourceware.org/git/bzip2.git)
    - [curl](https://github.com/curl/curl) (with [c-ares](https://github.com/c-ares/c-ares), [libpsl](https://github.com/rockdaboot/libpsl), [nghttp2](https://github.com/nghttp2/nghttp2), [nghttp3](https://github.com/ngtcp2/nghttp3), [ngtcp2](https://github.com/ngtcp2/ngtcp2))
    - [dav1d](https://code.videolan.org/videolan/dav1d)
    - [ffmpeg](https://github.com/FFmpeg/FFmpeg)
    - [freetype](https://github.com/freetype/freetype)
    - [fribidi](https://github.com/fribidi/fribidi)
    - [harfbuzz](https://github.com/harfbuzz/harfbuzz)
    - [lcms2](https://github.com/mm2/Little-CMS)
    - [libarchive](https://github.com/libarchive/libarchive)
    - [libass](https://github.com/libass/libass)
    - [libbluray](https://code.videolan.org/videolan/libbluray) (with [libudfread](https://code.videolan.org/videolan/libudfread))
    - [libjpeg-turbo](https://github.com/libjpeg-turbo/libjpeg-turbo)
    - [libjxl](https://github.com/libjxl/libjxl) (with [highway](https://github.com/google/highway))
    - [libplacebo](https://github.com/haasn/libplacebo) (with [fast_float](https://github.com/fastfloat/fast_float), [xxhash](https://github.com/Cyan4973/xxHash))
    - [libpng](https://github.com/pnggroup/libpng)
    - [libsoxr](https://sourceforge.net/p/soxr/code)
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
    - [libiconv](https://ftp.gnu.org/pub/gnu/libiconv/) (1.19.1)

## Acknowledgements

The `CLONE_FLAGS`, `CLONE_POST_COMMAND` and `COMMIT` options of `add_git_steps`
and the steps that clean an external project and move a git checkout to its
target commit are modeled on
[shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake).

## License

Licensed under the GNU General Public License v3.0 or later.
