# Static libraries. mpv and libplacebo look for spirv-cross-c-shared, which
# SPIRV-Cross installs only for its shared C library, so the install step writes
# it for the static libraries.
ExternalProject_Add(spirv-cross
    GIT_REPOSITORY https://github.com/KhronosGroup/SPIRV-Cross.git
    GIT_TAG main
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/reference/
        !/samples/
        !/shaders*
        !/tests-other/"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DSPIRV_CROSS_CLI=OFF
        -DSPIRV_CROSS_ENABLE_CPP=OFF
        -DSPIRV_CROSS_ENABLE_MSL=OFF
        -DSPIRV_CROSS_ENABLE_REFLECT=OFF
        -DSPIRV_CROSS_EXCEPTIONS_TO_ASSERTIONS=ON
    INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND ${CMAKE_COMMAND} -D PKG_CONFIG_DIR=${SYSROOT_DIR}/lib/pkgconfig
            -P ${CMAKE_CURRENT_LIST_DIR}/spirv-cross-write-pkg-config.cmake
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_update_steps(spirv-cross)
cleanup(spirv-cross install)
