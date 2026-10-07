ExternalProject_Add(amf-headers
    GIT_REPOSITORY https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /amf/public/include/"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/amf/public/include/components ${SYSROOT_DIR}/include/AMF/components
        COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/amf/public/include/core ${SYSROOT_DIR}/include/AMF/core
    LOG_DOWNLOAD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_update_steps(amf-headers)
cleanup(amf-headers install)
