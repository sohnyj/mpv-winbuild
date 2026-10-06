# zimg's configure defines NDEBUG unless --enable-debug is given.
ExternalProject_Add(libzimg
    GIT_REPOSITORY https://github.com/sekrit-twc/zimg.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_TAG master
    GIT_CLONE_FLAGS "--filter=tree:0"
    GIT_SUBMODULES
        graphengine
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} autoreconf -fi <SOURCE_DIR>
        COMMAND ${EXEC} <SOURCE_DIR>/configure
            --host=${TARGET_TRIPLE}
            --prefix=${SYSROOT_DIR}
            --disable-shared
            "CXXFLAGS=-O3 -flto=${LTO_MODE}"
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(libzimg)
cleanup(libzimg install)
