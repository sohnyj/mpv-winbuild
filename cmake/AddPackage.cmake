# add_package(<name>
#     [DEPENDS <package>...]
#     [GIT_REPOSITORY <url> [GIT_TAG <branch>] [GIT_COMMIT <commit>]
#      [SPARSE_EXCLUDE <pattern>...] [SPARSE_INCLUDE <pattern>...]
#      [GIT_SUBMODULES <path>...]]
#     [SOURCE_FROM <package>]
#     [SOURCE_SUBDIR <dir>]
#     [PROFILE runtime|target]
#     [INSTALL_DIR <dir>]
#     [CMAKE_ARGS <argument>...]
#     [CONFIGURE_COMMAND <command>...]
#     [BUILD_COMMAND <command>...]
#     [INSTALL_COMMAND <command>...])
#
# Adds an ExternalProject for one package.
#
# Sources come either from GIT_REPOSITORY or from the checkout of another
# package (SOURCE_FROM). A git source is cloned into SOURCES_DIR/<name> with
# a treeless partial clone of GIT_TAG (default master), optionally pinned to
# GIT_COMMIT. SPARSE_EXCLUDE leaves paths out of the checkout and
# SPARSE_INCLUDE takes paths back in; both use sparse-checkout patterns. Only
# the submodules in GIT_SUBMODULES are checked out.
#
# The checkout moves only through the <name>-update targets (aggregated by
# "update"). Every build records the checked-out revision and rebuilds the
# package, and through DEPENDS its dependents, only when that revision changed.
#
# PROFILE selects the toolchain profile (default target). CMAKE_ARGS selects a
# CMake build with the profile's toolchain file, the Release build type and,
# for the target profile, interprocedural optimization (ThinLTO). Otherwise the
# CONFIGURE, BUILD and INSTALL commands are used as given, with the profile's
# bin directory first in PATH. INSTALL_DIR defaults to SYSROOT_DIR. Arguments
# holding a list separate its items with "|".

include_guard(GLOBAL)
include(ExternalProject)

cmake_host_system_information(RESULT MAKE_JOBS QUERY NUMBER_OF_LOGICAL_CORES)
set(FETCH_SOURCE_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/FetchSource.cmake")

function(add_package name)
    cmake_parse_arguments(PARSE_ARGV 1 arg
        ""
        "GIT_REPOSITORY;GIT_TAG;GIT_COMMIT;SOURCE_FROM;SOURCE_SUBDIR;PROFILE;INSTALL_DIR"
        "DEPENDS;SPARSE_EXCLUDE;SPARSE_INCLUDE;GIT_SUBMODULES;CMAKE_ARGS;CONFIGURE_COMMAND;BUILD_COMMAND;INSTALL_COMMAND"
    )
    if(arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "add_package(${name}): unknown arguments ${arg_UNPARSED_ARGUMENTS}")
    endif()
    if(NOT arg_PROFILE)
        set(arg_PROFILE target)
    endif()
    if(NOT arg_INSTALL_DIR)
        set(arg_INSTALL_DIR "${SYSROOT_DIR}")
    endif()
    if(NOT arg_GIT_TAG)
        set(arg_GIT_TAG master)
    endif()

    string(TOUPPER "${arg_PROFILE}" profile)
    if(NOT DEFINED "${profile}_TOOLCHAIN_FILE")
        message(FATAL_ERROR "add_package(${name}): unknown PROFILE ${arg_PROFILE}")
    endif()
    set(bin_dir "${${profile}_BIN_DIR}")
    set(toolchain_file "${${profile}_TOOLCHAIN_FILE}")

    set(depends ${arg_DEPENDS})
    set(arguments
        PREFIX "${PROJECT_BINARY_DIR}/packages/${name}"
        INSTALL_DIR "${arg_INSTALL_DIR}"
        LIST_SEPARATOR "|"
        LOG_DOWNLOAD ON
        LOG_PATCH ON
        LOG_CONFIGURE ON
        LOG_BUILD ON
        LOG_INSTALL ON
        LOG_MERGED_STDOUTERR ON
        LOG_OUTPUT_ON_FAILURE ON
    )

    if(arg_GIT_REPOSITORY)
        set(source_dir "${SOURCES_DIR}/${name}")
        set(sparse_patterns "")
        if(arg_SPARSE_EXCLUDE)
            list(APPEND sparse_patterns "/*")
            list(TRANSFORM arg_SPARSE_EXCLUDE PREPEND "!")
            list(APPEND sparse_patterns ${arg_SPARSE_EXCLUDE})
        endif()
        list(APPEND sparse_patterns ${arg_SPARSE_INCLUDE})

        set(parameters "${PROJECT_BINARY_DIR}/sources/${name}.cmake")
        file(CONFIGURE OUTPUT "${parameters}" CONTENT [=[
set(SOURCE_DIR "@source_dir@")
set(GIT_REPOSITORY "@arg_GIT_REPOSITORY@")
set(GIT_TAG "@arg_GIT_TAG@")
set(GIT_COMMIT "@arg_GIT_COMMIT@")
set(SPARSE_PATTERNS "@sparse_patterns@")
set(GIT_SUBMODULES "@arg_GIT_SUBMODULES@")
]=] @ONLY)

        set(fetch_command "${CMAKE_COMMAND}" -D "PARAMETERS=${parameters}")
        set(download_command ${fetch_command} -D ACTION=download -P "${FETCH_SOURCE_SCRIPT}")
        list(APPEND arguments SOURCE_DIR "${source_dir}")
    elseif(arg_SOURCE_FROM)
        ExternalProject_Get_Property("${arg_SOURCE_FROM}" SOURCE_DIR)
        set(download_command "")
        list(APPEND arguments SOURCE_DIR "${SOURCE_DIR}")
        list(APPEND depends "${arg_SOURCE_FROM}")
    else()
        message(FATAL_ERROR "add_package(${name}): GIT_REPOSITORY or SOURCE_FROM is required")
    endif()

    if(depends)
        list(APPEND arguments DEPENDS ${depends})
    endif()
    if(arg_SOURCE_SUBDIR)
        list(APPEND arguments SOURCE_SUBDIR "${arg_SOURCE_SUBDIR}")
    endif()

    set(environment "PATH=path_list_prepend:${bin_dir}")
    list(APPEND arguments
        CONFIGURE_ENVIRONMENT_MODIFICATION "${environment}"
        BUILD_ENVIRONMENT_MODIFICATION "${environment}"
        INSTALL_ENVIRONMENT_MODIFICATION "${environment}"
    )

    # Commands are passed quoted: an empty command must reach ExternalProject
    # as an empty argument to replace the default step.
    if(DEFINED arg_CMAKE_ARGS OR "CMAKE_ARGS" IN_LIST arg_KEYWORDS_MISSING_VALUES)
        set(cmake_args
            "-DCMAKE_TOOLCHAIN_FILE=${toolchain_file}"
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        )
        if(arg_PROFILE STREQUAL "target")
            list(APPEND cmake_args -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON)
        endif()
        ExternalProject_Add("${name}" ${arguments}
            DOWNLOAD_COMMAND "${download_command}"
            UPDATE_COMMAND ""
            CMAKE_ARGS ${cmake_args} ${arg_CMAKE_ARGS}
        )
    else()
        ExternalProject_Add("${name}" ${arguments}
            DOWNLOAD_COMMAND "${download_command}"
            UPDATE_COMMAND ""
            CONFIGURE_COMMAND "${arg_CONFIGURE_COMMAND}"
            BUILD_COMMAND "${arg_BUILD_COMMAND}"
            INSTALL_COMMAND "${arg_INSTALL_COMMAND}"
        )
    endif()

    if(arg_GIT_REPOSITORY)
        ExternalProject_Add_StepTargets("${name}" download)

        set(revision_file "${PROJECT_BINARY_DIR}/revisions/${name}")
        add_custom_target("${name}-revision"
            COMMAND ${fetch_command} -D ACTION=revision -D "REVISION_FILE=${revision_file}" -P "${FETCH_SOURCE_SCRIPT}"
            BYPRODUCTS "${revision_file}"
            VERBATIM
        )
        add_dependencies("${name}-revision" "${name}-download")
        # Like the download and patch steps around it, this step depends on
        # no other package.
        ExternalProject_Add_Step("${name}" source-revision
            DEPENDEES download
            DEPENDERS patch
            DEPENDS "${revision_file}"
            INDEPENDENT TRUE
        )

        add_custom_target("${name}-update"
            COMMAND ${fetch_command} -D ACTION=update -P "${FETCH_SOURCE_SCRIPT}"
            VERBATIM
        )
        add_dependencies("${name}-update" "${name}-download")
        set_property(GLOBAL APPEND PROPERTY SOURCE_UPDATE_TARGETS "${name}-update")
    endif()
endfunction()
