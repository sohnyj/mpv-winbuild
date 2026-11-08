# Only the library is built: the utilities are added unconditionally.
# CMakeLists.txt replaces -O3 with -O2 in the Release flags unless
# CMAKE_C_FLAGS has -O3.
ExternalProject_Add(zlib-ng
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_TESTING=OFF
        -DZLIB_COMPAT=ON
        "-DCMAKE_C_FLAGS=-O3"
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target zlib-ng
    INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR>
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(zlib-ng
    REPOSITORY https://github.com/zlib-ng/zlib-ng.git
    TAG develop
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/doc/
        !/test/"
)
add_cleanup_steps(zlib-ng install)
