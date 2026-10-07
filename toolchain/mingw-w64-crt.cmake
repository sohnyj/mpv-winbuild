# The CRT is built without LTO, as its startup objects and the functions code
# generation calls into must stay native code, and without section splitting,
# which gains little when most archive members hold a single function.
#
# mingw-w64 builds the stack protector functions into libmingwex and installs
# no libssp, while clang's MinGW driver links -lssp_nonshared -lssp for
# -fstack-protector*, so empty archives are installed under those names.
ExternalProject_Add(mingw-w64-crt
    DEPENDS
        mingw-w64
        mingw-w64-headers
    DOWNLOAD_COMMAND ""
    SOURCE_DIR ${MINGW_SOURCE_DIR}
    CONFIGURE_COMMAND ${EXEC} <SOURCE_DIR>/mingw-w64-crt/configure
        --host=${TARGET_TRIPLE}
        --prefix=${SYSROOT_DIR}
        --disable-lib32
        --enable-cfguard
        CPPFLAGS=-DNDEBUG
        "CFLAGS=-O3 -fno-function-sections -fno-data-sections"
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
        COMMAND ${LLVM_AR} rcs ${SYSROOT_DIR}/lib/libssp.a
        COMMAND ${LLVM_AR} rcs ${SYSROOT_DIR}/lib/libssp_nonshared.a
    LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

cleanup(mingw-w64-crt install)
