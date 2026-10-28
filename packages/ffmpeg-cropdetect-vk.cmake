# Cloned into the build directory: the sources cache of the workflow comes
# from main, which does not have this package.
set(SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/ffmpeg-cropdetect-vk")

ExternalProject_Add(ffmpeg-cropdetect-vk
    GIT_REPOSITORY https://github.com/sohnyj/cropdetect-vk.git
    GIT_TAG main
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_update_steps(ffmpeg-cropdetect-vk)
add_cleanup_steps(ffmpeg-cropdetect-vk install)

# Runs before every configure: the checkout is reset after the install step.
get_property(ffmpeg_depends TARGET ffmpeg PROPERTY _EP_DEPENDS)
set(done_stamps "")
foreach(dependency IN LISTS ffmpeg_depends ITEMS ffmpeg-cropdetect-vk)
    get_property(stamp_dir TARGET ${dependency} PROPERTY _EP_STAMP_DIR)
    list(APPEND done_stamps "${stamp_dir}/${dependency}-done")
endforeach()
ExternalProject_Add_Step(ffmpeg apply-cropdetect-vk
    DEPENDEES patch
    DEPENDERS configure
    DEPENDS ${done_stamps}
    COMMAND ${CMAKE_COMMAND} -DSOURCE_DIR=<SOURCE_DIR>
        -P ${SOURCE_DIR}/patch/ffmpeg-add-cropdetect_vulkan-filter.cmake
    LOG 1
)
ExternalProject_Add_StepDependencies(ffmpeg apply-cropdetect-vk
    ffmpeg-cropdetect-vk
)

ExternalProject_Add_Step(ffmpeg check-cropdetect-vk
    DEPENDEES build
    DEPENDERS install
    COMMAND test -f <BINARY_DIR>/libavfilter/vf_cropdetect_vulkan.o
)
