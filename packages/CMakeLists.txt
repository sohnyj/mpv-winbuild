# Packages, built with the package profile into the sysroot.
add_toolchain_profile(package "${PACKAGE_CPU_FLAGS}" "-D_FORTIFY_SOURCE=3")

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
    libzimg
    luajit
    nghttp2
    nghttp3
    nv-codec-headers
    spirv-cross
    spirv-headers
    spirv-tools
    subrandr
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
    # depth 5
    ffmpeg
    # depth 6
    mpv
)

foreach(package IN LISTS packages)
    set(SOURCE_DIR "${SOURCES_DIR}/${package}")
    include("${CMAKE_CURRENT_SOURCE_DIR}/${package}.cmake")
    # A changed toolchain profile rebuilds from the patch step, since the
    # checkout is reset after the install step.
    ExternalProject_Add_StepDependencies("${package}" patch ${PROFILE_FILES})
    # The toolchain components are built first, but a rebuilt component
    # rebuilds only the packages that name it in DEPENDS.
    ExternalProject_Add_StepDependencies("${package}" configure ${TOOLCHAIN_COMPONENTS})
endforeach()

set(PACKAGES ${packages} PARENT_SCOPE)
