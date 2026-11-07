# zimg's configure defines NDEBUG unless --enable-debug is given.
ExternalProject_Add(libzimg
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
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

add_git_steps(libzimg
    REPOSITORY https://github.com/sekrit-twc/zimg.git
    TAG master
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/_msvc/
        !/test/"
    SUBMODULES
        graphengine
)
add_cleanup_steps(libzimg install)
