ExternalProject_Add(nv-codec-headers
    GIT_REPOSITORY https://github.com/FFmpeg/nv-codec-headers.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_TAG master
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${MAKE} -C <SOURCE_DIR> PREFIX=${SYSROOT_DIR} install
    LOG_DOWNLOAD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(nv-codec-headers)
cleanup(nv-codec-headers install)
