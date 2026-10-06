# ExternalProject of the running CMake with ExternalProject-git-options.patch,
# which adds the GIT_CLONE_FLAGS, GIT_CLONE_POST_COMMAND and GIT_RESET options.
# The module is copied again at every configure, so it always matches the
# running CMake.

set(modules_dir "${PROJECT_BINARY_DIR}/cmake/Modules")
file(REMOVE_RECURSE "${modules_dir}")
file(COPY
    "${CMAKE_ROOT}/Modules/ExternalProject.cmake"
    "${CMAKE_ROOT}/Modules/ExternalProject"
    DESTINATION "${modules_dir}"
)
execute_process(
    COMMAND patch -p1 -i "${CMAKE_CURRENT_LIST_DIR}/ExternalProject-git-options.patch"
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}/cmake"
    OUTPUT_QUIET
    COMMAND_ERROR_IS_FATAL ANY
)
include("${modules_dir}/ExternalProject.cmake")
