# shaderc builds glslang, SPIRV-Tools and SPIRV-Headers from their own
# checkouts. Only the combined static library is built. mpv and libplacebo
# look for the shaderc package, which shaderc installs for its shared library,
# so the install step installs shaderc_combined.pc under that name.
ExternalProject_Add(shaderc
    DEPENDS
        glslang
        spirv-headers
        spirv-tools
    GIT_REPOSITORY https://github.com/google/shaderc.git
    GIT_TAG main
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DENABLE_GLSLANG_BINARIES=OFF
        -DSHADERC_ENABLE_HLSL=OFF
        -DSHADERC_ENABLE_WERROR_COMPILE=OFF
        -DSHADERC_GLSLANG_DIR=${GLSLANG_SOURCE_DIR}
        -DSHADERC_SKIP_COPYRIGHT_CHECK=ON
        -DSHADERC_SKIP_EXAMPLES=ON
        -DSHADERC_SKIP_EXECUTABLES=ON
        -DSHADERC_SKIP_TESTS=ON
        -DSHADERC_SPIRV_HEADERS_DIR=${SPIRV_HEADERS_SOURCE_DIR}
        -DSHADERC_SPIRV_TOOLS_DIR=${SPIRV_TOOLS_SOURCE_DIR}
        -DSPIRV_SKIP_EXECUTABLES=ON
        -DSPIRV_WERROR=OFF
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target shaderc_combined shaderc_combined-pkg-config
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/libshaderc/include/shaderc ${SYSROOT_DIR}/include/shaderc
        COMMAND ${CMAKE_COMMAND} -E copy <BINARY_DIR>/libshaderc/libshaderc_combined.a ${SYSROOT_DIR}/lib/libshaderc_combined.a
        COMMAND ${CMAKE_COMMAND} -E copy <BINARY_DIR>/shaderc_combined.pc ${SYSROOT_DIR}/lib/pkgconfig/shaderc.pc
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(shaderc)
cleanup(shaderc install)
