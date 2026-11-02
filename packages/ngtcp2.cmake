ExternalProject_Add(ngtcp2
    DEPENDS
        openssl
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBUILD_TESTING=OFF
        -DENABLE_LIB_ONLY=ON
        -DENABLE_SHARED_LIB=OFF
        "-DCMAKE_EXE_LINKER_FLAGS=-lbrotlicommon -lbrotlidec -lbrotlienc -lz -lzstd"
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(ngtcp2
    REPOSITORY https://github.com/ngtcp2/ngtcp2.git
    TAG main
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/tests/"
    SUBMODULES ""
)
add_cleanup_steps(ngtcp2 install)
