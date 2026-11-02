ExternalProject_Add(windows-rs
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(windows-rs
    REPOSITORY https://github.com/microsoft/windows-rs.git
    TAG master
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /crates/libs/default/"
)
add_cleanup_steps(windows-rs install)

set(WINDOWS_RS_SOURCE_DIR ${SOURCE_DIR})
