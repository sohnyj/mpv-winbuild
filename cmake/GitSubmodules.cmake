# Submodule functions of the clone script and GitCheckout.cmake.

# git_checked_out_submodules(<variable> <git executable> <directory>): paths of
# submodules checked out in the directory, not recursively.
function(git_checked_out_submodules variable git_executable directory)
    execute_process(
        COMMAND "${git_executable}" submodule --quiet foreach "printf '%s\\n' \"$sm_path\""
        WORKING_DIRECTORY "${directory}"
        OUTPUT_VARIABLE output
        COMMAND_ERROR_IS_FATAL ANY
    )
    string(REGEX MATCHALL "[^\n]+" paths "${output}")
    set(${variable} ${paths} PARENT_SCOPE)
endfunction()

# git_check_out_submodules(<git executable> <directory> [<path>...]): checks out
# submodules of the directory at the paths, or all of them without a path, then
# all of theirs. URLs are synchronized from .gitmodules level by level, since
# the .gitmodules that lists the submodules of a submodule exists only once that
# submodule is checked out.
function(git_check_out_submodules git_executable directory)
    execute_process(
        COMMAND "${git_executable}" submodule --quiet sync -- ${ARGN}
        WORKING_DIRECTORY "${directory}"
        COMMAND_ERROR_IS_FATAL ANY
    )
    execute_process(
        COMMAND "${git_executable}" submodule update --init -- ${ARGN}
        WORKING_DIRECTORY "${directory}"
        COMMAND_ERROR_IS_FATAL ANY
    )
    git_checked_out_submodules(checked_out_paths "${git_executable}" "${directory}")
    foreach(path IN LISTS checked_out_paths)
        git_check_out_submodules("${git_executable}" "${directory}/${path}")
    endforeach()
endfunction()

# git_update_submodules(<git executable> <source directory> <init submodules>
#                       [<path>...])
#
# Brings submodules of the checkout in the source directory to the configuration
# of add_git_steps, which is no submodules when <init submodules> is false,
# otherwise the submodules at the paths, or all of them without a path. Those
# are checked out recursively at the commits of the checkout, from the URLs of
# its .gitmodules. Other checked-out submodules are deinitialized.
function(git_update_submodules git_executable source_dir init_submodules)
    set(paths ${ARGN})

    git_checked_out_submodules(checked_out_paths "${git_executable}" "${source_dir}")
    set(unwanted_paths "")
    if(NOT init_submodules)
        set(unwanted_paths ${checked_out_paths})
    elseif(paths)
        set(unwanted_paths ${checked_out_paths})
        list(REMOVE_ITEM unwanted_paths ${paths})
    endif()
    if(unwanted_paths)
        execute_process(
            COMMAND "${git_executable}" submodule deinit --force -- ${unwanted_paths}
            WORKING_DIRECTORY "${source_dir}"
            COMMAND_ERROR_IS_FATAL ANY
        )
    endif()

    if(init_submodules)
        git_check_out_submodules("${git_executable}" "${source_dir}" ${paths})
    endif()
endfunction()
