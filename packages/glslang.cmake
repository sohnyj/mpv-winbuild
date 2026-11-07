ExternalProject_Add(glslang
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(glslang
    REPOSITORY https://github.com/KhronosGroup/glslang.git
    TAG main
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/Test/
        !/gtests/"
)
add_cleanup_steps(glslang install)

set(GLSLANG_SOURCE_DIR ${SOURCE_DIR})
