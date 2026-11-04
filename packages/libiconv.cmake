set(LIBICONV_VERSION 1.19.1)

ExternalProject_Add(libiconv
    URL
        https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz
        https://mirrors.kernel.org/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz
    URL_HASH SHA256=9a06844846d664d7122161700c10a64480d7c7bcead3091925a785b38c91edab
    DOWNLOAD_DIR ${SOURCES_DIR}
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ${EXEC} <SOURCE_DIR>/configure
        --host=${TARGET_TRIPLE}
        --prefix=${SYSROOT_DIR}
        --enable-extra-encodings
        --disable-shared
        CPPFLAGS=-DNDEBUG
        "CFLAGS=-O3 -flto=${LTO_MODE}"
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_cleanup_steps(libiconv install)
