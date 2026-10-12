# Cloned into the build directory, since the workflow's sources cache comes
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
    BRANCH main
    CLONE_FLAGS "--filter=tree:0"
)

# Runs before every configure, since the checkout is reset after install.
ExternalProject_Get_Property(ffmpeg DEPENDS)
set(done_stamps "")
foreach(dependency IN LISTS DEPENDS ITEMS ffmpeg-cropdetect-filters)
    ExternalProject_Get_Property(${dependency} STAMP_DIR)
    list(APPEND done_stamps "${STAMP_DIR}/${dependency}-done")
endforeach()
ExternalProject_Add_Step(ffmpeg apply-cropdetect-filters
    DEPENDEES patch
    DEPENDERS configure
    DEPENDS ${done_stamps}
    COMMAND ${CMAKE_COMMAND} -DSOURCE_DIR=<SOURCE_DIR>
        -P ${SOURCE_DIR}/patch/ffmpeg-add-cropdetect_vulkan-filter.cmake
    COMMAND ${CMAKE_COMMAND} -DSOURCE_DIR=<SOURCE_DIR>
        -P ${SOURCE_DIR}/patch/ffmpeg-add-cropdetect_cuda-filter.cmake
    LOG 1
)
ExternalProject_Add_StepDependencies(ffmpeg apply-cropdetect-filters
    ffmpeg-cropdetect-filters
)

ExternalProject_Add_Step(ffmpeg check-cropdetect_vulkan
    DEPENDEES build
    DEPENDERS install
    COMMAND test -f <BINARY_DIR>/libavfilter/vf_cropdetect_vulkan.o
)
ExternalProject_Add_Step(ffmpeg check-cropdetect_cuda
    DEPENDEES build
    DEPENDERS install
    COMMAND test -f <BINARY_DIR>/libavfilter/vf_cropdetect_cuda.o
)
