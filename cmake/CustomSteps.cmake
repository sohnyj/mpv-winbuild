# Steps added to the external projects: the toolchain components and packages.
#
# add_cleanup_steps(<name> <last step>)
#   Step targets:
#     <name>-delete-stamps             delete the stamps and reset a git
#                                      checkout
#     <name>-delete-build-stamps       delete the build and install stamps
#     <name>-remove-prefix-and-source  delete the prefix directory (build
#                                      directory, stamps) and the source
#   Only with a git source of its own:
#     <name>-remove-build              <name>-delete-stamps, then empty the
#                                      build directory
#     step remove-build-after-install  after <last step>, empty the build
#                                      directory and reset the checkout
#
# add_git_update_steps(<name>)
#   Step target <name>-force-update: fetch, move the checkout to GIT_RESET, else
#   to its commit in SOURCE_REVISIONS_FILE, else to its upstream branch, and
#   delete the stamps when the commit changed.
#   Steps write-head, which records the commit, and mark-cloned.

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
    get_property(git_repository TARGET ${name} PROPERTY _EP_GIT_REPOSITORY)
    get_property(stamp_dir TARGET ${name} PROPERTY _EP_STAMP_DIR)
    get_property(source_dir TARGET ${name} PROPERTY _EP_SOURCE_DIR)

    if(git_repository)
        if(build_in_source)
            set(remove_command git -C <SOURCE_DIR> clean -dfx)
        else()
            set(remove_command bash -c "find <BINARY_DIR> -mindepth 1 -delete && git -C <SOURCE_DIR> clean -df")
        endif()
        set(reset_checkout_commands COMMAND ${stamp_dir}/reset-head.sh)
    endif()

    # Step commands do not expand <STAMP_DIR>; <LOG_DIR> is the same directory.
    ExternalProject_Add_Step(${name} delete-stamps
        COMMAND find <LOG_DIR> -type f ! -iname *.cmake -size 0c -delete # the stamps are the empty files
        ${reset_checkout_commands}
        ALWAYS TRUE
        EXCLUDE_FROM_MAIN TRUE
        INDEPENDENT TRUE
        LOG 1
        COMMENT "Deleting all stamp files of ${name}"
    )

    ExternalProject_Add_Step(${name} delete-build-stamps
        COMMAND rm -f <LOG_DIR>/${name}-build
                      <LOG_DIR>/${name}-install
        ALWAYS TRUE
        EXCLUDE_FROM_MAIN TRUE
        INDEPENDENT TRUE
        LOG 1
        COMMENT "Deleting the build and install stamp files of ${name}"
    )

    if(git_repository)
        ExternalProject_Add_Step(${name} remove-build-after-install
            DEPENDEES ${last_step}
            COMMAND ${remove_command}
            ${reset_checkout_commands}
            LOG 1
            COMMENT "Emptying the build directory of ${name} after install"
        )

        ExternalProject_Add_Step(${name} remove-build
            DEPENDEES delete-stamps
            COMMAND ${remove_command}
            ALWAYS TRUE
            EXCLUDE_FROM_MAIN TRUE
            INDEPENDENT TRUE
            LOG 1
            COMMENT "Emptying the build directory of ${name}"
        )
        ExternalProject_Add_StepTargets(${name} remove-build)
    endif()

    ExternalProject_Add_Step(${name} remove-prefix-and-source
        COMMAND rm -rf <INSTALL_DIR> ${source_dir}
        COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target rebuild_cache
        ALWAYS TRUE
        EXCLUDE_FROM_MAIN TRUE
        INDEPENDENT TRUE
        LOG 1
        COMMENT "Deleting the prefix directory and the source of ${name}"
    )
    ExternalProject_Add_StepTargets(${name} delete-stamps delete-build-stamps remove-prefix-and-source)
endfunction()

function(add_git_update_steps name)
    get_property(git_reset TARGET ${name} PROPERTY _EP_GIT_RESET)
    get_property(stamp_dir TARGET ${name} PROPERTY _EP_STAMP_DIR)
    get_property(source_dir TARGET ${name} PROPERTY _EP_SOURCE_DIR)
    get_property(revision GLOBAL PROPERTY "SOURCE_REVISION_${name}")

    if(NOT "${git_reset}" STREQUAL "")
        set(commit "${git_reset}")
    elseif(revision)
        set(commit "${revision}")
    else()
        set(commit "\${upstream}")
    endif()

    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/reset-head.sh.in" "${stamp_dir}/reset-head.sh" @ONLY)

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
        DEPENDERS patch
        INDEPENDENT TRUE
        WORKING_DIRECTORY <SOURCE_DIR>
        COMMAND bash -c "git rev-parse HEAD > ${stamp_dir}/HEAD"
        LOG 1
    )

    # Marks an existing checkout as cloned: the clone script clones again
    # unless gitclone-lastrun.txt is newer than gitinfo.txt. Checked at build
    # time, since a step added only when the source exists would rerun the
    # download after the first clone.
    ExternalProject_Add_Step(${name} mark-cloned
        DEPENDERS download
        INDEPENDENT TRUE
        WORKING_DIRECTORY ${stamp_dir}
        COMMAND bash -c "[ ! -e <SOURCE_DIR>/.git ] || cp ${name}-gitinfo.txt ${name}-gitclone-lastrun.txt"
        COMMAND bash -c "[ -e <SOURCE_DIR>/.git ] || rm -f ${name}-gitclone-lastrun.txt"
        LOG 1
    )
endfunction()
