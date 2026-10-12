add_toolchain_profile(package "${PACKAGE_CPU_FLAGS}" "-D_FORTIFY_SOURCE=3" "-fstack-protector-strong")

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
    freetype
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
    # after ffmpeg, to which it adds steps
    ffmpeg-cropdetect-filters
    # depth 6
    mpv
)

foreach(package IN LISTS packages)
    set(SOURCE_DIR "${SOURCES_DIR}/${package}")
    include("${CMAKE_CURRENT_SOURCE_DIR}/${package}.cmake")
    add_cleanup_steps("${package}")
    # When the toolchain profile changes, steps from patch on run again, since
    # the checkout is reset after install.
    ExternalProject_Add_StepDependencies("${package}" patch ${PROFILE_FILES})
    # Toolchain components are built first, but rebuilding a component rebuilds
    # only packages that list it in DEPENDS.
    ExternalProject_Add_StepDependencies("${package}" configure ${TOOLCHAIN_COMPONENTS})
endforeach()

set(PACKAGES ${packages} PARENT_SCOPE)
