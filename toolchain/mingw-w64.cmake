# Sources of the MinGW-w64 headers, CRT and winpthreads.
ExternalProject_Add(mingw-w64
    GIT_REPOSITORY https://github.com/mingw-w64/mingw-w64.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(mingw-w64)
cleanup(mingw-w64 install)
set(MINGW_SOURCE_DIR ${SOURCE_LOCATION})
