ExternalProject_Add(xz
    GIT_REPOSITORY https://github.com/tukaani-project/xz.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/cmake/
        !/doc/
        !/dos/
        !/doxygen/
        !/extra/
        !/po4a/
        !/windows/"
    UPDATE_COMMAND ""
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

force_rebuild_git(xz)
cleanup(xz install)
