ExternalProject_Add(ngtcp2
    DEPENDS
        openssl
    GIT_REPOSITORY https://github.com/ngtcp2/ngtcp2.git
    GIT_TAG main
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/tests/"
    GIT_SUBMODULES ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
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

add_git_update_steps(ngtcp2)
cleanup(ngtcp2 install)
