# Only the Windows metadata, the input of cppwinrt. cppwinrt depends on the
# file rather than on this project, so that commits that leave the file
# unchanged do not regenerate the headers.
set(WINDOWS_WINMD crates/libs/default/Windows.winmd)
ExternalProject_Add(windows-rs
    GIT_REPOSITORY https://github.com/microsoft/windows-rs.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /${WINDOWS_WINMD}"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    INSTALL_BYPRODUCTS ${SOURCE_LOCATION}/${WINDOWS_WINMD}
    LOG_DOWNLOAD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(windows-rs)
cleanup(windows-rs install)
set(WINDOWS_RS_SOURCE_DIR ${SOURCE_LOCATION})
