# Packages, built with the package profile into the sysroot.
add_toolchain_profile(package "${PACKAGE_CPU_FLAGS}")

# Packages by depth: the longest chain of DEPENDS below each package.
set(packages
    # depth 0
    amf-headers
    brotli
    bzip2
    c-ares
    dav1d
    fast_float
    fribidi
    glslang
    highway
    lcms2
    libiconv
    libjpeg-turbo
    libpsl
    libsoxr
    libudfread
    libunibreak
    libvpl
    luajit
    nghttp2
    nghttp3
    nv-codec-headers
    spirv-cross
    spirv-headers
    spirv-tools
    uchardet
    vulkan-headers
    xxhash
    xz
    zlib-ng
    zstd
    # depth 1
    libarchive
    libjxl
    libpng
    libxml2
    libzimg
    openssl
    shaderc
    vulkan-loader
    # depth 2
    freetype2
    libplacebo
    ngtcp2
    # depth 3
    curl
    harfbuzz
    libbluray
    # depth 4
    libass
    subrandr
    # depth 5
    ffmpeg
    # depth 6
    mpv
)

foreach(package IN LISTS packages)
    set(SOURCE_LOCATION "${SOURCES_DIR}/${package}")
    include("${CMAKE_CURRENT_SOURCE_DIR}/${package}.cmake")
    # A new toolchain profile rebuilds from the patch step: cleanup() restores
    # the checkout after the install step.
    ExternalProject_Add_StepDependencies("${package}" patch ${PROFILE_FILES})
    ExternalProject_Add_StepDependencies("${package}" configure ${TOOLCHAIN_PROJECTS})
endforeach()

set(PACKAGES ${packages} PARENT_SCOPE)
