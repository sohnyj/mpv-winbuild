# The CRT is built without section splitting and without LTO: its startup
# objects and the functions code generation calls into must stay native code.
#
# mingw-w64 builds the stack protector functions into libmingwex and installs
# no libssp, while clang's MinGW driver links -lssp_nonshared -lssp for
# -fstack-protector*. Empty archives satisfy those libraries.
add_package(mingw-w64-crt
    DEPENDS
        mingw-w64-headers
    SOURCE_FROM mingw-w64
    PROFILE runtime
    CONFIGURE_COMMAND
        <SOURCE_DIR>/mingw-w64-crt/configure
        --host=x86_64-w64-mingw32
        --prefix=<INSTALL_DIR>
        --disable-lib32
        --enable-cfguard
        CC=x86_64-w64-mingw32-clang
        "CFLAGS=-O3 -fno-function-sections -fno-data-sections"
        CPPFLAGS=-DNDEBUG
    BUILD_COMMAND make -j${MAKE_JOBS}
    INSTALL_COMMAND make install
        COMMAND "${LLVM_AR}" rcs <INSTALL_DIR>/lib/libssp.a
        COMMAND "${LLVM_AR}" rcs <INSTALL_DIR>/lib/libssp_nonshared.a
)
