ExternalProject_Add(fribidi
    GIT_REPOSITORY https://github.com/fribidi/fribidi.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !/test/"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ${MESON_EXECUTABLE} setup --reconfigure <BINARY_DIR> <SOURCE_DIR>
        --buildtype=release
        --cross-file=${MESON_CROSS}
        --native-file=${MESON_NATIVE}
        --default-library=static
        --prefix=${SYSROOT_DIR}
        --wrap-mode=nofallback
        -Db_lto=true
        -Db_lto_mode=${LTO_MODE}
        -Db_ndebug=true
        -Dbin=false
        -Ddocs=false
        -Dtests=false
    BUILD_COMMAND ${MESON_EXECUTABLE} compile -C <BINARY_DIR>
    INSTALL_COMMAND ${MESON_EXECUTABLE} install -C <BINARY_DIR>
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_update_steps(fribidi)
cleanup(fribidi install)
