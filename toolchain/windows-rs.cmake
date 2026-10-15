ExternalProject_Add(windows-rs
    GIT_REPOSITORY https://github.com/microsoft/windows-rs.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /crates/libs/default/"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_update_steps(windows-rs)
add_cleanup_steps(windows-rs install)

set(WINDOWS_RS_SOURCE_DIR ${SOURCE_DIR})
