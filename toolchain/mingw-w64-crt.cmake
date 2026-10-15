# Built without LTO: the startup objects and the functions that code generation
# calls must stay native code. Built without section splitting: most archive
# members hold a single function.
#
# clang's MinGW driver links -lssp_nonshared -lssp for -fstack-protector*, but
# mingw-w64 has those functions in libmingwex and installs no libssp, so empty
# archives are installed under those names.
ExternalProject_Add(mingw-w64-crt
    DEPENDS
        mingw-w64
        mingw-w64-headers
    DOWNLOAD_COMMAND ""
    SOURCE_DIR ${MINGW_W64_SOURCE_DIR}
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

add_cleanup_steps(mingw-w64-crt install)
