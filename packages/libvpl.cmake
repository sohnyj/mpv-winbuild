ExternalProject_Add(libvpl
    GIT_REPOSITORY https://github.com/intel/libvpl.git
    GIT_TAG main
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/api/tests/
        !/doc/
        !/libvpl/test/"
    UPDATE_COMMAND ""
    PATCH_COMMAND git -C <SOURCE_DIR> restore .
        COMMAND git -C <SOURCE_DIR> apply ${CMAKE_CURRENT_LIST_DIR}/libvpl-avoid-wcscpy_s-defines-on-mingw.patch
    SOURCE_DIR ${SOURCE_LOCATION}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBUILD_EXPERIMENTAL=OFF
        -DBUILD_SHARED_LIBS=OFF
        -DINSTALL_EXAMPLES=OFF
    LOG_DOWNLOAD 1 LOG_PATCH 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_update_steps(libvpl)
cleanup(libvpl install)
