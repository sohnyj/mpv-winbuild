# Steps added to the external projects: the toolchain components and packages.
#
# add_cleanup_steps(<name> <last step>)
#   Step targets:
#     <name>-delete-stamps             delete the stamps and reset a git
#                                      checkout
#     <name>-remove-prefix-and-source  delete the prefix directory (build
#                                      directory, stamps) and the source
#   Only with a git source of its own, given to add_git_steps before:
#     step remove-build-after-install  after <last step>, empty the build
#                                      directory and reset the checkout
#
# add_git_steps(<name> REPOSITORY <url> TAG <branch> [CLONE_FLAGS <flags>]
#               [CLONE_POST_COMMAND <git arguments>] [RESET <commit>]
#               [SUBMODULES <path>...])
#   For an external project with DOWNLOAD_COMMAND "".
#   Step clone, before download: clone the branch TAG of REPOSITORY with
#   CLONE_FLAGS, run git with CLONE_POST_COMMAND, reset to RESET and update
#   SUBMODULES (all of them when not given, none when given as ""). Runs again
#   when REPOSITORY, TAG, the source directory or the submodules change, and
#   clones again when the checkout has another origin or branch. A changed
#   RESET reaches the checkout through force-update.
#   Step target <name>-force-update: fetch, move the checkout to RESET, else
#   to its commit in SOURCE_REVISIONS_FILE, else to its upstream branch, and
#   delete the stamps when the checkout was patched and the commit or the
#   download changed since.
#   Step write-head, after download: record the commit.
#   Target property GIT_REPOSITORY: REPOSITORY.

# The "<source> <commit>" lines of SOURCE_REVISIONS_FILE, as the revisions
# target writes them.
if(SOURCE_REVISIONS_FILE)
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${SOURCE_REVISIONS_FILE}")
    file(STRINGS "${SOURCE_REVISIONS_FILE}" revision_lines)
    foreach(line IN LISTS revision_lines)
        string(REGEX MATCH "^([^ ]+) ([^ ]+)$" match "${line}")
        set_property(GLOBAL PROPERTY "SOURCE_REVISION_${CMAKE_MATCH_1}" "${CMAKE_MATCH_2}")
    endforeach()
endif()

function(add_cleanup_steps name last_step)
    get_property(build_in_source TARGET ${name} PROPERTY _EP_BUILD_IN_SOURCE)
    get_property(git_repository TARGET ${name} PROPERTY GIT_REPOSITORY)

    # Step commands do not expand <STAMP_DIR>; <LOG_DIR> is the same directory.
    if(git_repository)
        if(build_in_source)
            set(remove_command git -C <SOURCE_DIR> clean -dfx)
        else()
            set(remove_command bash -c "find <BINARY_DIR> -mindepth 1 -delete && git -C <SOURCE_DIR> clean -df")
        endif()
        set(reset_checkout_commands COMMAND <LOG_DIR>/reset-head.sh)
    endif()

    ExternalProject_Add_Step(${name} delete-stamps
        COMMAND find <LOG_DIR> -type f ! -iname *.cmake -size 0c -delete # the stamps are the empty files
        ${reset_checkout_commands}
        ALWAYS TRUE
        EXCLUDE_FROM_MAIN TRUE
        INDEPENDENT TRUE
        LOG 1
        COMMENT "Deleting all stamp files of ${name}"
    )

    if(git_repository)
        ExternalProject_Add_Step(${name} remove-build-after-install
            DEPENDEES ${last_step}
            COMMAND ${remove_command}
            ${reset_checkout_commands}
            LOG 1
            COMMENT "Emptying the build directory of ${name} after install"
        )
    endif()

    ExternalProject_Add_Step(${name} remove-prefix-and-source
        COMMAND rm -rf <INSTALL_DIR> <SOURCE_DIR>
        COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target rebuild_cache
        ALWAYS TRUE
        EXCLUDE_FROM_MAIN TRUE
        INDEPENDENT TRUE
        LOG 1
        COMMENT "Deleting the prefix directory and the source of ${name}"
    )
    ExternalProject_Add_StepTargets(${name} delete-stamps remove-prefix-and-source)
endfunction()

function(add_git_steps name)
    cmake_parse_arguments(PARSE_ARGV 1 arg ""
        "REPOSITORY;TAG;CLONE_FLAGS;CLONE_POST_COMMAND;RESET" "SUBMODULES")
    if(arg_UNPARSED_ARGUMENTS OR arg_KEYWORDS_MISSING_VALUES OR NOT arg_REPOSITORY OR NOT arg_TAG)
        message(FATAL_ERROR "add_git_steps(${name}): give REPOSITORY and TAG, and a value after each keyword")
    endif()
    get_property(stamp_dir TARGET ${name} PROPERTY _EP_STAMP_DIR)
    get_property(source_dir TARGET ${name} PROPERTY _EP_SOURCE_DIR)
    get_property(revision GLOBAL PROPERTY "SOURCE_REVISION_${name}")

    separate_arguments(clone_flags UNIX_COMMAND "${arg_CLONE_FLAGS}")
    separate_arguments(clone_post_command UNIX_COMMAND "${arg_CLONE_POST_COMMAND}")
    if(DEFINED arg_SUBMODULES AND "${arg_SUBMODULES}" STREQUAL "")
        set(init_submodules FALSE)
    else()
        set(init_submodules TRUE)
    endif()
    set_property(TARGET ${name} PROPERTY GIT_REPOSITORY "${arg_REPOSITORY}")

    if(NOT "${arg_RESET}" STREQUAL "")
        set(commit "${arg_RESET}")
    elseif(revision)
        set(commit "${revision}")
    else()
        set(commit "\${upstream}")
    endif()

    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/git-clone.cmake.in" "${stamp_dir}/${name}-gitclone.cmake" @ONLY)
    file(CONFIGURE
        OUTPUT "${stamp_dir}/${name}-gitsource.txt"
        CONTENT "repository=@arg_REPOSITORY@\ntag=@arg_TAG@\nsource_dir=@source_dir@\ninit_submodules=@init_submodules@\nsubmodules=@arg_SUBMODULES@\n"
        @ONLY
    )
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/reset-head.sh.in" "${stamp_dir}/reset-head.sh" @ONLY)

    ExternalProject_Add_Step(${name} clone
        DEPENDEES mkdir
        DEPENDERS download
        DEPENDS "${stamp_dir}/${name}-gitsource.txt"
        INDEPENDENT TRUE
        COMMAND ${CMAKE_COMMAND} -P "${stamp_dir}/${name}-gitclone.cmake"
        LOG 1
    )

    ExternalProject_Add_Step(${name} force-update
        ALWAYS TRUE
        EXCLUDE_FROM_MAIN TRUE
        INDEPENDENT TRUE
        WORKING_DIRECTORY <SOURCE_DIR>
        COMMAND bash -c "[ -e <SOURCE_DIR>/.git ] && git fetch --filter=tree:0 --no-recurse-submodules || true"
        COMMAND ${stamp_dir}/reset-head.sh
    )
    ExternalProject_Add_StepTargets(${name} force-update)

    ExternalProject_Add_Step(${name} write-head
        DEPENDEES download
        DEPENDERS patch
        INDEPENDENT TRUE
        WORKING_DIRECTORY <SOURCE_DIR>
        COMMAND bash -c "git rev-parse HEAD > ${stamp_dir}/HEAD"
        LOG 1
    )
endfunction()
