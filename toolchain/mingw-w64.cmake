# Sources of the MinGW-w64 headers, CRT and winpthreads.
ExternalProject_Add(mingw-w64
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(mingw-w64
    REPOSITORY https://github.com/mingw-w64/mingw-w64.git
    TAG master
    CLONE_FLAGS "--filter=tree:0"
)
add_cleanup_steps(mingw-w64 install)

set(MINGW_W64_SOURCE_DIR ${SOURCE_DIR})
