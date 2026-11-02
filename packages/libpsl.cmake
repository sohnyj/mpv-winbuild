ExternalProject_Add(libpsl
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ${MESON_EXECUTABLE} setup --reconfigure <BINARY_DIR> <SOURCE_DIR>
        --buildtype=release
        --cross-file=${MESON_CROSS_FILE}
        --native-file=${MESON_NATIVE_FILE}
        --default-library=static
        --prefix=${SYSROOT_DIR}
        --wrap-mode=nofallback
        -Db_lto=true
        -Db_lto_mode=${LTO_MODE}
        -Db_ndebug=true
        -Druntime=no
        -Dtests=false
    BUILD_COMMAND ${MESON_EXECUTABLE} compile -C <BINARY_DIR>
    INSTALL_COMMAND ${MESON_EXECUTABLE} install -C <BINARY_DIR>
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(libpsl
    REPOSITORY https://github.com/rockdaboot/libpsl.git
    TAG master
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/fuzz/
        !/tests/"
    SUBMODULES
        list
)
add_cleanup_steps(libpsl install)
