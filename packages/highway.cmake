ExternalProject_Add(highway
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBUILD_SHARED_LIBS=OFF
        -DHWY_ENABLE_CONTRIB=OFF
        -DHWY_ENABLE_EXAMPLES=OFF
        -DHWY_ENABLE_IO=OFF
        -DHWY_ENABLE_LIST_TARGETS=OFF
        -DHWY_ENABLE_TESTS=OFF
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(highway
    REPOSITORY https://github.com/google/highway.git
    TAG master
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/g3doc/"
)
add_cleanup_steps(highway install)
