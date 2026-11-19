# cmake -D ACTION=<record|reset|update> -D GIT_EXECUTABLE=<git> -D NAME=<name>
#       -D SOURCE_DIR=<directory> -D STAMP_DIR=<directory>
#       [-D TARGET_COMMIT=<commit>] -P GitCheckout.cmake
#
# Keeps the git checkout of the external project NAME at its target commit:
# TARGET_COMMIT, or the tip of its upstream branch when TARGET_COMMIT is empty.
#   record  write the checked-out commit to <STAMP_DIR>/<NAME>-commit.txt
#   reset   discard the changes to the checkout and check out the target
#           commit; when the build has gone past the patch step with another
#           commit or with an earlier download, delete the stamps
#   update  fetch, then reset
# Without a checkout, nothing is done: the clone step makes one.

if(NOT EXISTS "${SOURCE_DIR}/.git")
    return()
endif()

set(commit_file "${STAMP_DIR}/${NAME}-commit.txt")

# git_output(<variable> <git argument>...): the trimmed output of git in the
# checkout, or an empty string when git fails.
function(git_output variable)
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" ${ARGN}
        WORKING_DIRECTORY "${SOURCE_DIR}"
        OUTPUT_VARIABLE output
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        RESULT_VARIABLE result
    )
    if(NOT result EQUAL 0)
        set(output "")
    endif()
    set(${variable} "${output}" PARENT_SCOPE)
endfunction()

if(ACTION STREQUAL "record")
    git_output(commit rev-parse HEAD)
    file(WRITE "${commit_file}" "${commit}\n")
    return()
endif()

if(ACTION STREQUAL "update")
    # An unreachable remote leaves the checkout at the commits it has.
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" fetch --filter=tree:0 --no-recurse-submodules
        WORKING_DIRECTORY "${SOURCE_DIR}"
        RESULT_VARIABLE result
    )
    if(NOT result EQUAL 0)
        message(WARNING "${NAME}: git fetch failed")
    endif()
elseif(NOT ACTION STREQUAL "reset")
    message(FATAL_ERROR "Unknown ACTION: ${ACTION}")
endif()

if(TARGET_COMMIT STREQUAL "")
    git_output(commit rev-parse --verify --quiet "@{upstream}^{commit}")
    if(commit STREQUAL "")
        git_output(commit rev-parse HEAD)
    endif()
else()
    git_output(commit rev-parse --verify --quiet "${TARGET_COMMIT}^{commit}")
    if(commit STREQUAL "")
        message(FATAL_ERROR "${NAME}: no commit ${TARGET_COMMIT} in ${SOURCE_DIR}")
    endif()
endif()

# The steps after patch saw the recorded commit as it was downloaded; another
# commit, or a download that ran again, invalidates all of them.
set(patch_stamp "${STAMP_DIR}/${NAME}-patch")
set(download_stamp "${STAMP_DIR}/${NAME}-download")
set(source_changed FALSE)
if(EXISTS "${patch_stamp}")
    set(recorded_commit "")
    if(EXISTS "${commit_file}")
        file(STRINGS "${commit_file}" recorded_commit LIMIT_COUNT 1)
    endif()
    if(NOT recorded_commit STREQUAL commit)
        set(source_changed TRUE)
    elseif("${download_stamp}" IS_NEWER_THAN "${patch_stamp}"
        AND NOT "${patch_stamp}" IS_NEWER_THAN "${download_stamp}")
        set(source_changed TRUE)
    endif()
endif()

execute_process(
    COMMAND "${GIT_EXECUTABLE}" reset --hard --quiet "${commit}"
    WORKING_DIRECTORY "${SOURCE_DIR}"
    COMMAND_ERROR_IS_FATAL ANY
)
if(source_changed)
    message(STATUS "${NAME}: the source changed after the patch step; deleting the stamps")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -D "STAMP_DIR=${STAMP_DIR}"
            -P "${CMAKE_CURRENT_LIST_DIR}/DeleteStamps.cmake"
        COMMAND_ERROR_IS_FATAL ANY
    )
endif()
file(WRITE "${commit_file}" "${commit}\n")
execute_process(
    COMMAND "${GIT_EXECUTABLE}" submodule --quiet update --recursive
    WORKING_DIRECTORY "${SOURCE_DIR}"
    COMMAND_ERROR_IS_FATAL ANY
)
