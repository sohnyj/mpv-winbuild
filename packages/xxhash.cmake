ExternalProject_Add(xxhash
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_SUBDIR build/cmake
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBUILD_SHARED_LIBS=OFF
        -DXXHASH_BUILD_XXHSUM=OFF
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(xxhash
    REPOSITORY https://github.com/Cyan4973/xxHash.git
    TAG dev
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/cli/
        !/doc/
        !/fuzz/
        !/tests/"
)
add_cleanup_steps(xxhash install)
