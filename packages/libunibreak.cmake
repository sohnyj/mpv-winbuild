ExternalProject_Add(libunibreak
    GIT_REPOSITORY https://github.com/adah1972/libunibreak.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ${EXEC} autoreconf -fi <SOURCE_DIR>
        COMMAND ${EXEC} <SOURCE_DIR>/configure
            --host=${TARGET_TRIPLE}
            --prefix=${SYSROOT_DIR}
            --disable-shared
            CPPFLAGS=-DNDEBUG
            "CFLAGS=-O3 -flto=${LTO_MODE}"
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(libunibreak)
cleanup(libunibreak install)
