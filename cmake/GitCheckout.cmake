# cmake -D ACTION=<patch|record|reset|update> -D GIT_EXECUTABLE=<git>
#       -D NAME=<name> -D SOURCE_DIR=<directory> -D STAMP_DIR=<directory>
#       [-D TARGET_COMMIT=<commit>] -P GitCheckout.cmake
#
# Keeps the git checkout of external project NAME at its target commit, which is
# TARGET_COMMIT, or the tip of its upstream branch when TARGET_COMMIT is empty.
#   patch   discard changes to the checkout and apply patches of
#           <STAMP_DIR>/<NAME>-gitpatches.cmake with its patch flags
#   record  write the checked-out commit to <STAMP_DIR>/<NAME>-commit.txt
#   reset   discard changes to the checkout, check out the target commit,
#           delete stamps when the source was patched without a recorded commit
#           or at another commit, bring submodules to
#           <STAMP_DIR>/<NAME>-gitsubmodules.cmake, and apply patches
#   update  fetch, then reset
# Does nothing without a checkout, which the clone step makes.

if(NOT EXISTS "${SOURCE_DIR}/.git")
    return()
endif()

set(commit_file "${STAMP_DIR}/${NAME}-commit.txt")

# git_output(<variable> <git argument>...): trimmed output of git in the
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

# apply_patches(): applies patches with patch flags, in order, to the checkout,
# which has no changes. They are also applied to the index, so resetting the
# checkout deletes the files they add.
function(apply_patches)
    include("${STAMP_DIR}/${NAME}-gitpatches.cmake")
    foreach(patch IN LISTS patches)
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" apply --index ${patch_flags} "${patch}"
            WORKING_DIRECTORY "${SOURCE_DIR}"
            COMMAND_ERROR_IS_FATAL ANY
        )
    endforeach()
endfunction()

if(ACTION STREQUAL "patch")
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" reset --hard --quiet
        WORKING_DIRECTORY "${SOURCE_DIR}"
        COMMAND_ERROR_IS_FATAL ANY
    )
    apply_patches()
    return()
endif()

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
        message(WARNING "Failed to fetch '${NAME}'")
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
        message(FATAL_ERROR "No commit ${TARGET_COMMIT} in ${SOURCE_DIR} for '${NAME}'")
    endif()
endif()

# Steps after patch ran on the recorded commit as downloaded. They are invalid
# when no commit is recorded or the target commit differs, and deletion_reason
# names the case. A download that runs again, as the clone step makes it do when
# the repository, branch, source directory or submodules change, reruns them
# through their dependencies.
set(patch_stamp "${STAMP_DIR}/${NAME}-patch")
set(deletion_reason "")
if(EXISTS "${patch_stamp}")
    set(recorded_commit "")
    if(EXISTS "${commit_file}")
        file(STRINGS "${commit_file}" recorded_commit LIMIT_COUNT 1)
    endif()
    if(recorded_commit STREQUAL "")
        set(deletion_reason "no commit recorded")
    elseif(NOT recorded_commit STREQUAL commit)
        set(deletion_reason "source moved from ${recorded_commit} to ${commit}")
    endif()
endif()

execute_process(
    COMMAND "${GIT_EXECUTABLE}" reset --hard --quiet "${commit}"
    WORKING_DIRECTORY "${SOURCE_DIR}"
    COMMAND_ERROR_IS_FATAL ANY
)
if(NOT deletion_reason STREQUAL "")
    message(STATUS "Deleting stamps for '${NAME}': ${deletion_reason}")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -D "STAMP_DIR=${STAMP_DIR}"
            -P "${CMAKE_CURRENT_LIST_DIR}/DeleteStamps.cmake"
        COMMAND_ERROR_IS_FATAL ANY
    )
endif()
file(WRITE "${commit_file}" "${commit}\n")
include("${CMAKE_CURRENT_LIST_DIR}/GitSubmodules.cmake")
include("${STAMP_DIR}/${NAME}-gitsubmodules.cmake")
git_update_submodules("${GIT_EXECUTABLE}" "${SOURCE_DIR}" ${init_submodules} ${submodules})
apply_patches()
