# CMakeLists.txt replaces -O3 with -O2 in the Release flags unless they are
# given.
ExternalProject_Add(xz
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBUILD_SHARED_LIBS=OFF
        -DXZ_DOC=OFF
        -DXZ_MICROLZMA_DECODER=OFF
        -DXZ_MICROLZMA_ENCODER=OFF
        -DXZ_NLS=OFF
        -DXZ_TOOL_LZMADEC=OFF
        -DXZ_TOOL_LZMAINFO=OFF
        -DXZ_TOOL_XZ=OFF
        -DXZ_TOOL_XZDEC=OFF
        "-DCMAKE_C_FLAGS_RELEASE=-O3 -DNDEBUG"
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(xz
    REPOSITORY https://github.com/tukaani-project/xz.git
    TAG master
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/doc/
        !/dos/
        !/doxygen/
        !/extra/
        !/po4a/
        !/windows/"
)
add_cleanup_steps(xz install)
