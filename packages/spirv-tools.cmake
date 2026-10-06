# Source only: shaderc builds it.
ExternalProject_Add(spirv-tools
    GIT_REPOSITORY https://github.com/KhronosGroup/SPIRV-Tools.git
    GIT_TAG main
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !/android_test/ !/docs/ !/kokoro/"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(spirv-tools)
cleanup(spirv-tools install)
set(SPIRV_TOOLS_SOURCE_DIR ${SOURCE_LOCATION})
