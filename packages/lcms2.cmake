ExternalProject_Add(lcms2
    GIT_REPOSITORY https://github.com/mm2/Little-CMS.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/doc/
        !/fuzzers/
        !/testbed/"
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
        -Dtests=disabled
    BUILD_COMMAND ${MESON_EXECUTABLE} compile -C <BINARY_DIR>
    INSTALL_COMMAND ${MESON_EXECUTABLE} install -C <BINARY_DIR>
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_update_steps(lcms2)
add_cleanup_steps(lcms2 install)
