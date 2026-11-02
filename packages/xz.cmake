ExternalProject_Add(xz
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ${EXEC} autoreconf -fi <SOURCE_DIR>
        COMMAND ${EXEC} <SOURCE_DIR>/configure
            --host=${TARGET_TRIPLE}
            --prefix=${SYSROOT_DIR}
            --disable-doc
            --disable-lzmadec
            --disable-lzmainfo
            --disable-microlzma
            --disable-nls
            --disable-scripts
            --disable-shared
            --disable-xz
            --disable-xzdec
            CPPFLAGS=-DNDEBUG
            "CFLAGS=-O3 -flto=${LTO_MODE}"
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(xz
    REPOSITORY https://github.com/tukaani-project/xz.git
    TAG master
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/cmake/
        !/doc/
        !/dos/
        !/doxygen/
        !/extra/
        !/po4a/
        !/windows/"
)
add_cleanup_steps(xz install)
