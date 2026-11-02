ExternalProject_Add(libunibreak
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
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

add_git_steps(libunibreak
    REPOSITORY https://github.com/adah1972/libunibreak.git
    TAG master
    CLONE_FLAGS "--filter=tree:0"
)
add_cleanup_steps(libunibreak install)
