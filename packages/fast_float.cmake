ExternalProject_Add(fast_float
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(fast_float
    REPOSITORY https://github.com/fastfloat/fast_float.git
    TAG main
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/tests/"
)
add_cleanup_steps(fast_float install)
