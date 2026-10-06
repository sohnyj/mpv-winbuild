# Steps added to the external projects of the recipes.
#
# cleanup(<name> <last step>)
#   After <last step>, empties the build directory and resets the git
#   checkout. Adds the step targets <name>-fullclean (delete the stamps),
#   <name>-liteclean (delete the build and install stamps), <name>-removebuild
#   and <name>-removeprefix (delete the prefix and the source).
#
# force_rebuild_git(<name>)
#   Adds the step target <name>-force-update, which fetches the git source and
#   moves it to GIT_RESET, else to its commit in SOURCE_REVISIONS, else to its
#   upstream branch; when that changes the checked-out commit, it deletes the
#   stamps so that the next build rebuilds the project. A source that already
#   exists is not cloned again.

# The "<project> <commit>" lines of SOURCE_REVISIONS, as written by the
# revisions target.
if(SOURCE_REVISIONS)
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${SOURCE_REVISIONS}")
    file(STRINGS "${SOURCE_REVISIONS}" revision_lines)
    foreach(line IN LISTS revision_lines)
        string(REGEX MATCH "^([^ ]+) ([^ ]+)$" match "${line}")
        set_property(GLOBAL PROPERTY "SOURCE_REVISION_${CMAKE_MATCH_1}" "${CMAKE_MATCH_2}")
    endforeach()
endif()

function(cleanup _name _last_step)
    get_property(_build_in_source TARGET ${_name} PROPERTY _EP_BUILD_IN_SOURCE)
    get_property(_git_repository TARGET ${_name} PROPERTY _EP_GIT_REPOSITORY)
    get_property(stamp_dir TARGET ${_name} PROPERTY _EP_STAMP_DIR)
    get_property(source_dir TARGET ${_name} PROPERTY _EP_SOURCE_DIR)

    if(_git_repository)
        if(_build_in_source)
            set(remove_cmd git -C <SOURCE_DIR> clean -dfx)
        else()
            set(remove_cmd bash -c "find <BINARY_DIR> -mindepth 1 -delete && git -C <SOURCE_DIR> clean -df")
        endif()
        set(COMMAND_FORCE_UPDATE COMMAND bash -c "[ -e <SOURCE_DIR>/.git ] && git -C <SOURCE_DIR> am --abort 2> /dev/null || true"
                                 COMMAND ${stamp_dir}/reset_head.sh
                                 COMMAND bash -c "[ -e <SOURCE_DIR>/.git ] && git -C <SOURCE_DIR> restore . || true")
    endif()

    # <STAMP_DIR> doesn't resolve into full path, so <LOG_DIR> is used instead since its same folder.
    ExternalProject_Add_Step(${_name} fullclean
        COMMAND find <LOG_DIR> -type f ! -iname *.cmake -size 0c -delete # remove 0 byte files which are stamp files
        ${COMMAND_FORCE_UPDATE}
        ALWAYS TRUE
        EXCLUDE_FROM_MAIN TRUE
        INDEPENDENT TRUE
        LOG 1
        COMMENT "Deleting all stamp files of ${_name} package"
    )

    ExternalProject_Add_Step(${_name} liteclean
        COMMAND rm -f <LOG_DIR>/${_name}-build
                      <LOG_DIR>/${_name}-install
        ALWAYS TRUE
        EXCLUDE_FROM_MAIN TRUE
        INDEPENDENT TRUE
        LOG 1
        COMMENT "Deleting build, install stamp files of ${_name} package"
    )

    if(_git_repository)
        ExternalProject_Add_Step(${_name} postremovebuild
            DEPENDEES ${_last_step}
            COMMAND ${remove_cmd}
            ${COMMAND_FORCE_UPDATE}
            LOG 1
            COMMENT "Deleting build directory of ${_name} package after install"
        )

        ExternalProject_Add_Step(${_name} removebuild
            DEPENDEES fullclean
            COMMAND ${remove_cmd}
            ALWAYS TRUE
            EXCLUDE_FROM_MAIN TRUE
            INDEPENDENT TRUE
            LOG 1
            COMMENT "Deleting build directory of ${_name} package"
        )
        ExternalProject_Add_StepTargets(${_name} removebuild)
    endif()

    ExternalProject_Add_Step(${_name} removeprefix
        COMMAND rm -rf <INSTALL_DIR> ${source_dir}
        COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target rebuild_cache
        ALWAYS TRUE
        EXCLUDE_FROM_MAIN TRUE
        INDEPENDENT TRUE
        LOG 1
        COMMENT "Deleting everything about ${_name} package"
    )
    ExternalProject_Add_StepTargets(${_name} fullclean liteclean removeprefix)
endfunction()

function(force_rebuild_git _name)
    get_property(git_reset TARGET ${_name} PROPERTY _EP_GIT_RESET)
    get_property(stamp_dir TARGET ${_name} PROPERTY _EP_STAMP_DIR)
    get_property(source_dir TARGET ${_name} PROPERTY _EP_SOURCE_DIR)
    get_property(revision GLOBAL PROPERTY "SOURCE_REVISION_${_name}")

    if(NOT "${git_reset}" STREQUAL "")
        set(target "${git_reset}")
    elseif(revision)
        set(target "${revision}")
    else()
        set(target "\${upstream}")
    endif()

    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/reset_head.sh.in" "${stamp_dir}/reset_head.sh"
        FILE_PERMISSIONS ${executable_permissions}
        @ONLY
    )

    ExternalProject_Add_Step(${_name} force-update
        ALWAYS TRUE
        EXCLUDE_FROM_MAIN TRUE
        INDEPENDENT TRUE
        WORKING_DIRECTORY <SOURCE_DIR>
        COMMAND bash -c "[ -e <SOURCE_DIR>/.git ] && git am --abort 2> /dev/null || true"
        COMMAND bash -c "[ -e <SOURCE_DIR>/.git ] && git fetch --filter=tree:0 --no-recurse-submodules || true"
        COMMAND ${stamp_dir}/reset_head.sh
    )
    ExternalProject_Add_StepTargets(${_name} force-update)

    ExternalProject_Add_Step(${_name} write-head
        DEPENDERS patch
        INDEPENDENT TRUE
        WORKING_DIRECTORY <SOURCE_DIR>
        COMMAND bash -c "git rev-parse HEAD > ${stamp_dir}/HEAD"
        LOG 1
    )

    # The git clone script deletes the source and clones it again unless
    # gitclone-lastrun.txt is newer than gitinfo.txt, so an existing checkout,
    # which the build directories share, is marked as cloned. The step is
    # decided when it runs: one added only once the source exists would rerun
    # the download step after the first clone.
    ExternalProject_Add_Step(${_name} check-git
        DEPENDERS download
        INDEPENDENT TRUE
        WORKING_DIRECTORY ${stamp_dir}
        COMMAND bash -c "[ ! -e <SOURCE_DIR>/.git ] || cp ${_name}-gitinfo.txt ${_name}-gitclone-lastrun.txt"
        COMMAND bash -c "[ -e <SOURCE_DIR>/.git ] || rm -f ${_name}-gitclone-lastrun.txt"
        LOG 1
    )
endfunction()
