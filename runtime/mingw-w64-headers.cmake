add_package(mingw-w64-headers
    SOURCE_FROM mingw-w64
    PROFILE runtime
    CONFIGURE_COMMAND
        <SOURCE_DIR>/mingw-w64-headers/configure
        --host=x86_64-w64-mingw32
        --prefix=<INSTALL_DIR>
    INSTALL_COMMAND make install
)
