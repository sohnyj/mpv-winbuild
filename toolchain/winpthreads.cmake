# winpthreads is a fallback: packages use the Win32 thread API, and only code
# that calls POSIX thread or clock functions pulls members of this archive in.
# Like the CRT it is built without section splitting and without LTO.
ExternalProject_Add(winpthreads
    DEPENDS
        libcxx
        mingw-w64
        mingw-w64-crt
    DOWNLOAD_COMMAND ""
    SOURCE_DIR ${MINGW_SOURCE_DIR}
    CONFIGURE_COMMAND ${EXEC} <SOURCE_DIR>/mingw-w64-libraries/winpthreads/configure
        --host=${TARGET_TRIPLE}
        --prefix=${SYSROOT_DIR}
        --disable-shared
        CPPFLAGS=-DNDEBUG
        "CFLAGS=-O3 -fno-function-sections -fno-data-sections"
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

cleanup(winpthreads install)
