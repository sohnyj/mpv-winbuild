ExternalProject_Add(fast_float
    GIT_REPOSITORY https://github.com/fastfloat/fast_float.git
    GIT_TAG main
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(fast_float)
cleanup(fast_float install)
