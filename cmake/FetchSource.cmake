# Fetches, updates and records the git sources of add_package().
#
#   cmake -D PARAMETERS=<file> -D ACTION=<action> [-D REVISION_FILE=<file>]
#         -P FetchSource.cmake
#
# PARAMETERS is written by add_package() and sets SOURCE_DIR, GIT_REPOSITORY,
# GIT_TAG, GIT_COMMIT, SPARSE_PATTERNS and GIT_SUBMODULES.
#
# ACTION is one of
#   download  Clone SOURCE_DIR unless it already holds a checkout.
#   update    Move the checkout to the tip of GIT_TAG, or to GIT_COMMIT.
#   revision  Write the checked-out revision to REVISION_FILE, touching the
#             file only when the revision changed. A checkout pinned to
#             GIT_COMMIT is first moved to that commit.

cmake_minimum_required(VERSION 4.4)

include("${PARAMETERS}")
find_package(Git REQUIRED)

function(run_git)
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" -C "${SOURCE_DIR}" ${ARGN}
        COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()

function(read_git output)
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" -C "${SOURCE_DIR}" ${ARGN}
        OUTPUT_VARIABLE value
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY
    )
    set("${output}" "${value}" PARENT_SCOPE)
endfunction()

function(fetch_branch)
    run_git(fetch --quiet --filter=tree:0 origin "${GIT_TAG}")
endfunction()

# Sets <output> to the full hash of the commit the checkout should be at, or
# to an empty string when that commit is not in the local repository.
function(find_wanted_commit output)
    if(GIT_COMMIT)
        set(revision "${GIT_COMMIT}")
    else()
        set(revision "origin/${GIT_TAG}")
    endif()
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" -C "${SOURCE_DIR}" rev-parse --verify --quiet "${revision}^{commit}"
        OUTPUT_VARIABLE commit
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE result
    )
    if(NOT result EQUAL 0)
        set(commit "")
    endif()
    set("${output}" "${commit}" PARENT_SCOPE)
endfunction()

function(check_out commit)
    run_git(checkout --quiet --force --detach "${commit}")
    if(GIT_SUBMODULES)
        run_git(submodule update --init --recursive --filter=tree:0 -- ${GIT_SUBMODULES})
    endif()
endfunction()

# Moves the checkout to the wanted commit, fetching GIT_TAG first when
# <fetch> is true or the commit is missing locally.
function(move_to_wanted_commit fetch)
    if(fetch)
        fetch_branch()
    endif()
    find_wanted_commit(commit)
    if(NOT commit)
        fetch_branch()
        find_wanted_commit(commit)
    endif()
    if(NOT commit)
        message(FATAL_ERROR "${SOURCE_DIR}: no commit ${GIT_COMMIT} on ${GIT_TAG}")
    endif()
    read_git(head rev-parse HEAD)
    if(NOT commit STREQUAL head)
        check_out("${commit}")
    endif()
endfunction()

if(ACTION STREQUAL "download")
    if(EXISTS "${SOURCE_DIR}/.git")
        return()
    endif()
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" clone --quiet --filter=tree:0 --no-checkout
                --single-branch --branch "${GIT_TAG}" "${GIT_REPOSITORY}" "${SOURCE_DIR}"
        COMMAND_ERROR_IS_FATAL ANY
    )
    if(SPARSE_PATTERNS)
        run_git(sparse-checkout set --no-cone ${SPARSE_PATTERNS})
    endif()
    move_to_wanted_commit(FALSE)
elseif(ACTION STREQUAL "update")
    if(SPARSE_PATTERNS)
        run_git(sparse-checkout set --no-cone ${SPARSE_PATTERNS})
    endif()
    move_to_wanted_commit(TRUE)
elseif(ACTION STREQUAL "revision")
    if(GIT_COMMIT)
        move_to_wanted_commit(FALSE)
    endif()
    read_git(revision rev-parse HEAD)
    if(GIT_SUBMODULES)
        read_git(submodules submodule status --recursive)
        string(APPEND revision "\n${submodules}")
    endif()
    file(WRITE "${REVISION_FILE}.new" "${revision}\n")
    file(COPY_FILE "${REVISION_FILE}.new" "${REVISION_FILE}" ONLY_IF_DIFFERENT)
    file(REMOVE "${REVISION_FILE}.new")
else()
    message(FATAL_ERROR "Unknown ACTION: ${ACTION}")
endif()
