# Only the library is built. The install step installs the devel tag (library,
# header, pkg-config file): the alias script of the programs cannot handle
# Windows executable names.
ExternalProject_Add(bzip2
    GIT_REPOSITORY https://gitlab.com/bzip2/bzip2.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--filter=tree:0"
    GIT_SUBMODULES ""
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
    BUILD_COMMAND ${MESON_EXECUTABLE} compile -C <BINARY_DIR> bz2
    INSTALL_COMMAND ${MESON_EXECUTABLE} install -C <BINARY_DIR> --no-rebuild --tags devel
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(bzip2)
cleanup(bzip2 install)
