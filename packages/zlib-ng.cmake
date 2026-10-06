ExternalProject_Add(zlib-ng
    GIT_REPOSITORY https://github.com/zlib-ng/zlib-ng.git
    GIT_TAG develop
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !/doc/ !/test/"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_TESTING=OFF
        -DZLIB_COMPAT=ON
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(zlib-ng)
cleanup(zlib-ng install)
