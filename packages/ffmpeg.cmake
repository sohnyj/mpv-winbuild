# The configure step stops the build when features that configure turns off
# without an error are missing: the AVX-512 assembly, and the SPIR-V compiler
# (glslang on PATH), which configure keeps out of config.h; avgblur_vulkan
# depends on nothing else.
ExternalProject_Add(ffmpeg
    DEPENDS
        amf-headers
        bzip2
        curl
        dav1d
        freetype2
        fribidi
        harfbuzz
        lcms2
        libass
        libbluray
        libiconv
        libjxl
        libplacebo
        libsoxr
        libvpl
        libxml2
        libzimg
        nv-codec-headers
        openssl
        spirv-headers
        vulkan-loader
        xz
        zlib-ng
    GIT_REPOSITORY https://github.com/FFmpeg/FFmpeg.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !/tests/ref/fate/"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ${EXEC} <SOURCE_DIR>/configure
        --cross-prefix=${TARGET_TRIPLE}-
        --cc=${TARGET_TRIPLE}-clang
        --cxx=${TARGET_TRIPLE}-clang++
        --nvcc=${CLANG_EXECUTABLE}
        --host-cc=${HOST_C_COMPILER}
        --windres=${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLE}-windres
        --prefix=${SYSROOT_DIR}
        --arch=${TARGET_PROCESSOR}
        --target-os=mingw32
        --pkg-config-flags=--static
        --extra-cflags=-DNDEBUG
        --extra-libs=-lc++
        --enable-amf
        --enable-bzlib
        --enable-cuda-llvm
        --enable-d3d11va
        --enable-d3d12va
        --enable-ffnvcodec
        --enable-gpl
        --enable-iconv
        --enable-lcms2
        --enable-libass
        --enable-libbluray
        --enable-libcurl
        --enable-libdav1d
        --enable-libfreetype
        --enable-libfribidi
        --enable-libharfbuzz
        --enable-libjxl
        --enable-libplacebo
        --enable-libsoxr
        --enable-libvpl
        --enable-libxml2
        --enable-libzimg
        --enable-lto=${LTO_MODE}
        --enable-lzma
        --enable-mediafoundation
        --enable-nvdec
        --enable-nvenc
        --enable-openssl
        --enable-version3
        --enable-vulkan
        --enable-zlib
        --disable-cuvid
        --disable-debug
        --disable-doc
        --disable-dxva2
        --disable-ffplay
        --disable-ffprobe
        --disable-indev=gdigrab
        --disable-indev=vfwcap
        --disable-vaapi
        --disable-protocol=gopher
        --disable-protocol=gophers
        --disable-protocol=mmsh
        --disable-protocol=mmst
        --disable-protocol=prompeg
        --disable-protocol=udplite
        COMMAND grep -q "^#define HAVE_AVX512_EXTERNAL 1$" config.h
        COMMAND grep -q "^#define HAVE_AVX512ICL_EXTERNAL 1$" config.h
        COMMAND grep -q "^#define CONFIG_AVGBLUR_VULKAN_FILTER 1$" config_components.h
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(ffmpeg)
cleanup(ffmpeg install)
