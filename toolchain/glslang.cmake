# Host tool, whose executable is passed to FFmpeg as --glslc to compile FFmpeg's
# Vulkan shaders. shaderc builds glslang for the target from the same source.
ExternalProject_Add(glslang
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_CXX_COMPILER=${HOST_CXX_COMPILER}
        -DCMAKE_C_COMPILER=${HOST_C_COMPILER}
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DENABLE_HLSL=OFF
        -DENABLE_OPT=OFF
        -DGLSLANG_TESTS=OFF
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(glslang
    REPOSITORY https://github.com/KhronosGroup/glslang.git
    BRANCH main
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/Test/
        !/gtests/"
)
add_cleanup_steps(glslang install)

ExternalProject_Get_Property(glslang INSTALL_DIR)
set(GLSLANG_EXECUTABLE ${INSTALL_DIR}/bin/glslang)
set(GLSLANG_SOURCE_DIR ${SOURCE_DIR})
