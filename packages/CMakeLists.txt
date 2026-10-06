# Packages, built with the target profile into the sysroot.
add_toolchain_profile(target "${TARGET_CPU_FLAGS}")

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
)
foreach(package IN LISTS packages)
    set(SOURCE_LOCATION "${SOURCES_DIR}/${package}")
    include("${CMAKE_CURRENT_SOURCE_DIR}/${package}.cmake")
    ExternalProject_Add_StepDependencies("${package}" configure ${PROFILE_FILES} ${RUNTIMES})
endforeach()
set(PACKAGES ${packages} PARENT_SCOPE)
