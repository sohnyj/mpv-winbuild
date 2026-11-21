# git_update_submodules(<git executable> <source directory> <init submodules>
#                       [<path>...])
#
# Brings the submodules of the checkout in the source directory to the
# configuration of add_git_steps: with <init submodules> false none of them,
# otherwise the submodules at the paths, or all of them without a path. Those
# are initialized and checked out recursively at the commits of the checkout;
# the other checked-out submodules are deinitialized.

function(git_update_submodules git_executable source_dir init_submodules)
    set(paths ${ARGN})

    execute_process(
        COMMAND "${git_executable}" submodule --quiet foreach "printf '%s\\n' \"$sm_path\""
        WORKING_DIRECTORY "${source_dir}"
        OUTPUT_VARIABLE output
        COMMAND_ERROR_IS_FATAL ANY
    )
    string(REGEX MATCHALL "[^\n]+" checked_out_paths "${output}")

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
        execute_process(
            COMMAND "${git_executable}" submodule update --init --recursive -- ${paths}
            WORKING_DIRECTORY "${source_dir}"
            COMMAND_ERROR_IS_FATAL ANY
        )
    endif()
endfunction()
