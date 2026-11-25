# Sources of MinGW-w64 headers, CRT and winpthreads.
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
    REPOSITORY https://git.code.sf.net/p/mingw-w64/mingw-w64
    BRANCH master
    CLONE_FLAGS "--sparse"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/build-aux/
        !/mingw-w64-tools/"
)

set(MINGW_W64_SOURCE_DIR ${SOURCE_DIR})
