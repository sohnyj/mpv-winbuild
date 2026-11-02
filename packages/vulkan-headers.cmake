ExternalProject_Add(vulkan-headers
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DVULKAN_HEADERS_ENABLE_TESTS=OFF
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(vulkan-headers
    REPOSITORY https://github.com/KhronosGroup/Vulkan-Headers.git
    TAG main
    CLONE_FLAGS "--filter=tree:0"
)
add_cleanup_steps(vulkan-headers install)
