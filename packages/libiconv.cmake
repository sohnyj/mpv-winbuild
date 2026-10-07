set(LIBICONV_VERSION 1.19)
ExternalProject_Add(libiconv
    URL
        https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz
        https://mirrors.kernel.org/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz
    URL_HASH SHA256=88dd96a8c0464eca144fc791ae60cd31cd8ee78321e67397e25fc095c4a19aa6
    DOWNLOAD_DIR ${SOURCES_DIR}
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ${EXEC} <SOURCE_DIR>/configure
        --host=${TARGET_TRIPLE}
        --prefix=${SYSROOT_DIR}
        --disable-shared
        --enable-extra-encodings
        CPPFLAGS=-DNDEBUG
        "CFLAGS=-O3 -flto=${LTO_MODE}"
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

cleanup(libiconv install)
