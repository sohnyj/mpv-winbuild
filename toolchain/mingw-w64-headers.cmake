ExternalProject_Add(mingw-w64-headers
    DEPENDS
        mingw-w64
    DOWNLOAD_COMMAND ""
    SOURCE_DIR ${MINGW_SOURCE_DIR}
    CONFIGURE_COMMAND ${EXEC} <SOURCE_DIR>/mingw-w64-headers/configure
        --host=${TARGET_TRIPLE}
        --prefix=${SYSROOT_DIR}
    BUILD_COMMAND ""
    INSTALL_COMMAND ${MAKE} install
    LOG_CONFIGURE 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

cleanup(mingw-w64-headers install)
