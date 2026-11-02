ExternalProject_Add(amf-headers
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/amf/public/include/components ${SYSROOT_DIR}/include/AMF/components
        COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/amf/public/include/core ${SYSROOT_DIR}/include/AMF/core
    LOG_DOWNLOAD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(amf-headers
    REPOSITORY https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git
    TAG master
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /amf/public/include/"
)
add_cleanup_steps(amf-headers install)
