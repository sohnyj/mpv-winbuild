# Only the library is built: simdcoverage is added whenever the SIMD extensions
# and the static library are.
ExternalProject_Add(libjpeg-turbo
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DENABLE_SHARED=OFF
        -DREQUIRE_SIMD=ON
        -DWITH_ARITH_DEC=OFF
        -DWITH_ARITH_ENC=OFF
        -DWITH_TOOLS=OFF
        -DWITH_TURBOJPEG=OFF
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target jpeg-static
    INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR>
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(libjpeg-turbo
    REPOSITORY https://github.com/libjpeg-turbo/libjpeg-turbo.git
    TAG main
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/fuzz/
        !/test/
        !/testimages/"
)
add_cleanup_steps(libjpeg-turbo install)
