ExternalProject_Add(nv-codec-headers
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${MAKE} -C <SOURCE_DIR> PREFIX=${SYSROOT_DIR} install
    LOG_DOWNLOAD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(nv-codec-headers
    REPOSITORY https://github.com/FFmpeg/nv-codec-headers.git
    TAG master
    CLONE_FLAGS "--filter=tree:0"
)
add_cleanup_steps(nv-codec-headers install)
