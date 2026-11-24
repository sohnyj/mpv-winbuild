# Source from which shaderc builds SPIRV-Tools for the target.
ExternalProject_Add(spirv-tools
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(spirv-tools
    REPOSITORY https://github.com/KhronosGroup/SPIRV-Tools.git
    BRANCH main
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/android_test/
        !/docs/
        !/kokoro/"
)

set(SPIRV_TOOLS_SOURCE_DIR ${SOURCE_DIR})
