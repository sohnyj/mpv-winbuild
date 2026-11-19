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
#   Step record-commit, after download: record the commit for force-update.
#   Target property GIT_REPOSITORY: REPOSITORY.
#   Target property GIT_RESET_COMMAND: the command that discards the changes
#   to the checkout and checks out the target commit, for add_cleanup_steps.

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
    ExternalProject_Get_Property(${name} BINARY_DIR INSTALL_DIR SOURCE_DIR STAMP_DIR)
    get_property(git_repository TARGET ${name} PROPERTY GIT_REPOSITORY)
    get_property(reset_command TARGET ${name} PROPERTY GIT_RESET_COMMAND)

    set(reset_commands "")
    if(git_repository)
        set(reset_commands COMMAND ${reset_command})
    endif()

    ExternalProject_Add_Step(${name} delete-stamps
        COMMAND ${CMAKE_COMMAND} -D "STAMP_DIR=${STAMP_DIR}"
            -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/DeleteStamps.cmake"
        ${reset_commands}
        ALWAYS TRUE
        EXCLUDE_FROM_MAIN TRUE
        INDEPENDENT TRUE
        LOG 1
        COMMENT "Deleting the stamps of ${name}"
    )

    if(git_repository)
        # A build directory in the checkout leaves its outputs, which
        # .gitignore lists, there.
        cmake_path(IS_PREFIX SOURCE_DIR "${BINARY_DIR}" build_in_checkout)
        if(build_in_checkout)
            set(empty_build_commands COMMAND git -C ${SOURCE_DIR} clean -d --force -x)
        else()
            set(empty_build_commands
                COMMAND ${CMAKE_COMMAND} -E rm -rf ${BINARY_DIR}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${BINARY_DIR}
                COMMAND git -C ${SOURCE_DIR} clean -d --force
            )
        endif()
        ExternalProject_Add_Step(${name} remove-build-after-install
            DEPENDEES ${last_step}
            ${empty_build_commands}
            ${reset_commands}
            LOG 1
            COMMENT "Emptying the build directory of ${name} after install"
        )
    endif()

    # Configuring writes the clone script and its inputs into the stamp
    # directory, which the prefix directory holds.
    ExternalProject_Add_Step(${name} remove-prefix-and-source
        COMMAND ${CMAKE_COMMAND} -E rm -rf ${INSTALL_DIR} ${SOURCE_DIR}
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
    ExternalProject_Get_Property(${name} SOURCE_DIR STAMP_DIR)
    set(stamp_dir "${STAMP_DIR}")
    set(source_dir "${SOURCE_DIR}")
    get_property(revision GLOBAL PROPERTY "SOURCE_REVISION_${name}")

    separate_arguments(clone_flags UNIX_COMMAND "${arg_CLONE_FLAGS}")
    separate_arguments(clone_post_command UNIX_COMMAND "${arg_CLONE_POST_COMMAND}")
    if(DEFINED arg_SUBMODULES AND "${arg_SUBMODULES}" STREQUAL "")
        set(init_submodules FALSE)
    else()
        set(init_submodules TRUE)
    endif()
    set_property(TARGET ${name} PROPERTY GIT_REPOSITORY "${arg_REPOSITORY}")

    # An empty target commit is the tip of the upstream branch.
    if(NOT "${arg_RESET}" STREQUAL "")
        set(target_commit "${arg_RESET}")
    elseif(revision)
        set(target_commit "${revision}")
    else()
        set(target_commit "")
    endif()
    set(checkout_definitions
        -D "NAME=${name}"
        -D "SOURCE_DIR=${source_dir}"
        -D "STAMP_DIR=${stamp_dir}"
        -D "TARGET_COMMIT=${target_commit}"
    )
    set(checkout_script "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/GitCheckout.cmake")
    set_property(TARGET ${name} PROPERTY GIT_RESET_COMMAND
        ${CMAKE_COMMAND} ${checkout_definitions} -D ACTION=reset -P ${checkout_script})

    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/git-clone.cmake.in" "${stamp_dir}/${name}-gitclone.cmake" @ONLY)
    file(CONFIGURE
        OUTPUT "${stamp_dir}/${name}-gitsource.txt"
        CONTENT "repository=@arg_REPOSITORY@\ntag=@arg_TAG@\nsource_dir=@source_dir@\ninit_submodules=@init_submodules@\nsubmodules=@arg_SUBMODULES@\n"
        @ONLY
    )

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
        COMMAND ${CMAKE_COMMAND} ${checkout_definitions} -D ACTION=update -P ${checkout_script}
    )
    ExternalProject_Add_StepTargets(${name} force-update)

    ExternalProject_Add_Step(${name} record-commit
        DEPENDEES download
        DEPENDERS patch
        INDEPENDENT TRUE
        COMMAND ${CMAKE_COMMAND} ${checkout_definitions} -D ACTION=record -P ${checkout_script}
        LOG 1
    )
endfunction()
