# winpthreads is a fallback: packages use the Win32 thread API, and only code
# that calls POSIX thread or clock functions pulls members of this archive in.
# Like the CRT it is built without section splitting and without LTO.
#
# llvm-windres preprocesses with the x86_64-w64-mingw32-clang next to the path
# it was started from, so RC is an absolute path into the profile.
add_package(winpthreads
    DEPENDS
        libcxx
        mingw-w64-crt
    SOURCE_FROM mingw-w64
    PROFILE runtime
    CONFIGURE_COMMAND
        <SOURCE_DIR>/mingw-w64-libraries/winpthreads/configure
        --host=x86_64-w64-mingw32
        --prefix=<INSTALL_DIR>
        --disable-shared
        CC=x86_64-w64-mingw32-clang
        "RC=${RUNTIME_BIN_DIR}/x86_64-w64-mingw32-windres"
        "CFLAGS=-O3 -fno-function-sections -fno-data-sections"
        CPPFLAGS=-DNDEBUG
    BUILD_COMMAND make -j${MAKE_JOBS}
    INSTALL_COMMAND make install
)
