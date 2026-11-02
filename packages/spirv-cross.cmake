# mpv and libplacebo look for spirv-cross-c-shared.pc, which SPIRV-Cross
# installs only with its shared C library, so the install step writes it for
# the static libraries.
ExternalProject_Add(spirv-cross
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DSPIRV_CROSS_CLI=OFF
        -DSPIRV_CROSS_ENABLE_CPP=OFF
        -DSPIRV_CROSS_ENABLE_MSL=OFF
        -DSPIRV_CROSS_ENABLE_REFLECT=OFF
    INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND ${CMAKE_COMMAND} -D PKG_CONFIG_DIR=${SYSROOT_DIR}/lib/pkgconfig
            -P ${CMAKE_CURRENT_LIST_DIR}/spirv-cross-write-pkg-config.cmake
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(spirv-cross
    REPOSITORY https://github.com/KhronosGroup/SPIRV-Cross.git
    TAG main
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/reference/
        !/samples/
        !/shaders*
        !/tests-other/"
)
add_cleanup_steps(spirv-cross install)
