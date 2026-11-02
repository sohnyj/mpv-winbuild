ExternalProject_Add(c-ares
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DCARES_BUILD_TOOLS=OFF
        -DCARES_SHARED=OFF
        -DCARES_STATIC=ON
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(c-ares
    REPOSITORY https://github.com/c-ares/c-ares.git
    TAG main
    CLONE_FLAGS "--filter=tree:0"
)
add_cleanup_steps(c-ares install)
