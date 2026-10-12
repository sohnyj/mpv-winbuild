# Cloned into the build directory: the sources cache of the workflow comes
# from main, which does not have this package.
set(SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/ffmpeg-cropdetect-filters")

ExternalProject_Add(ffmpeg-cropdetect-filters
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(ffmpeg-cropdetect-filters
    REPOSITORY https://github.com/sohnyj/cropdetect-filters.git
    TAG main
)
add_cleanup_steps(ffmpeg-cropdetect-filters install)

# Runs before every configure: the checkout is reset after the install step.
get_property(ffmpeg_depends TARGET ffmpeg PROPERTY _EP_DEPENDS)
set(done_stamps "")
foreach(dependency IN LISTS ffmpeg_depends ITEMS ffmpeg-cropdetect-filters)
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
    ffmpeg-cropdetect-filters
)

# Runs after apply-cropdetect-vk, and so again whenever that step does: both
# scripts insert lines into the same files of ffmpeg.
ExternalProject_Add_Step(ffmpeg apply-cropdetect-cu
    DEPENDEES apply-cropdetect-vk
    DEPENDERS configure
    COMMAND ${CMAKE_COMMAND} -DSOURCE_DIR=<SOURCE_DIR>
        -P ${SOURCE_DIR}/patch/ffmpeg-add-cropdetect_cuda-filter.cmake
    LOG 1
)

ExternalProject_Add_Step(ffmpeg check-cropdetect-vk
    DEPENDEES build
    DEPENDERS install
    COMMAND test -f <BINARY_DIR>/libavfilter/vf_cropdetect_vulkan.o
)
ExternalProject_Add_Step(ffmpeg check-cropdetect-cu
    DEPENDEES build
    DEPENDERS install
    COMMAND test -f <BINARY_DIR>/libavfilter/vf_cropdetect_cuda.o
)
