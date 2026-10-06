ExternalProject_Add(brotli
    GIT_REPOSITORY https://github.com/google/brotli.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !/java/ !/js/ !/research/ !/tests/"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBROTLI_BUILD_TOOLS=OFF
        -DBUILD_SHARED_LIBS=OFF
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(brotli)
cleanup(brotli install)
