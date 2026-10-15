cmake_minimum_required(VERSION 4.4)
project(mpv-winbuild LANGUAGES NONE)

if(NOT CMAKE_GENERATOR MATCHES "^Ninja")
    message(FATAL_ERROR "Configure with the Ninja generator (-G Ninja).")
endif()

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

# Inputs, passed by scripts/build.sh.
set(LLVM_VERSION "" CACHE STRING "Major version of the apt.llvm.org toolchain")
set(TARGET_TRIPLE "" CACHE STRING "Target triple, such as x86_64-w64-mingw32")
set(PACKAGE_CPU_FLAGS "" CACHE STRING "clang CPU flags of the packages, such as -march=x86-64-v3 -mtune=generic")
set(PACKAGE_RUST_CPU_FLAGS "" CACHE STRING "rustc CPU flags of the packages, such as -C target-cpu=x86-64-v3")
set(RUNTIME_CPU_FLAGS "" CACHE STRING "clang CPU flags of the runtimes")
set(LTO_MODE "" CACHE STRING "clang -flto mode of the packages, such as thin")
set(MAKE_JOBS "" CACHE STRING "Parallel jobs of the make builds")
set(SYSROOT_DIR "" CACHE PATH "Directory the runtimes and packages are installed into")
set(SOURCES_DIR "" CACHE PATH "Directory holding the source checkouts, shared between build directories")
set(RUSTUP_DIR "" CACHE PATH "Directory of the Rust toolchain, shared between build directories")
set(CCACHE_DIR "" CACHE PATH "ccache directory of the compiler wrappers")
# Empty moves the git sources to the tips of their branches.
set(SOURCE_REVISIONS_FILE "" CACHE FILEPATH "File of <source> <commit> lines that the git sources are moved to")

foreach(variable IN ITEMS LLVM_VERSION TARGET_TRIPLE PACKAGE_CPU_FLAGS PACKAGE_RUST_CPU_FLAGS RUNTIME_CPU_FLAGS LTO_MODE MAKE_JOBS SYSROOT_DIR SOURCES_DIR RUSTUP_DIR CCACHE_DIR)
    if(NOT ${variable})
        message(FATAL_ERROR "Set ${variable}; scripts/build.sh passes it.")
    endif()
endforeach()

# The architecture component of the triple.
string(REGEX MATCH "^[^-]+" TARGET_PROCESSOR "${TARGET_TRIPLE}")
set(RUST_TARGET "${TARGET_PROCESSOR}-pc-windows-gnullvm")
# The triple of the build machine, for build scripts and procedural macros.
set(RUST_HOST "${CMAKE_HOST_SYSTEM_PROCESSOR}-unknown-linux-gnu")
# RUST_TARGET and RUST_HOST as cargo's environment variable names spell them.
string(MAKE_C_IDENTIFIER "${RUST_TARGET}" RUST_TARGET_IDENTIFIER)
string(TOUPPER "${RUST_TARGET_IDENTIFIER}" RUST_TARGET_IDENTIFIER)
string(MAKE_C_IDENTIFIER "${RUST_HOST}" RUST_HOST_IDENTIFIER)
string(TOUPPER "${RUST_HOST_IDENTIFIER}" RUST_HOST_IDENTIFIER)

set(CLANG_RESOURCE_DIR "${PROJECT_BINARY_DIR}/resource")
set(THINLTO_CACHE_DIR "${PROJECT_BINARY_DIR}/thinlto")

include(PatchedExternalProject)
include(BuildTools)
include(ToolchainProfile)
include(CustomSteps)

set_property(DIRECTORY PROPERTY EP_STEP_TARGETS download)

add_subdirectory(toolchain)
add_subdirectory(packages)

# The toolchain components and packages, and those with a git source.
set(external_projects ${TOOLCHAIN_COMPONENTS} ${PACKAGES})
set(git_sources "")
foreach(external_project IN LISTS external_projects)
    get_property(git_repository TARGET ${external_project} PROPERTY _EP_GIT_REPOSITORY)
    if(git_repository)
        list(APPEND git_sources ${external_project})
    endif()
endforeach()
list(TRANSFORM git_sources APPEND "-force-update" OUTPUT_VARIABLE update_targets)
list(TRANSFORM external_projects APPEND "-download" OUTPUT_VARIABLE download_targets)
list(TRANSFORM external_projects APPEND "-delete-stamps" OUTPUT_VARIABLE delete_stamps_targets)

add_custom_target(update)
add_dependencies(update ${update_targets})
add_custom_target(download)
add_dependencies(download ${download_targets})
add_custom_target(delete-stamps)
add_dependencies(delete-stamps ${delete_stamps_targets})

# revisions writes the checked-out commit of every git source to
# revisions.txt, in the form that SOURCE_REVISIONS_FILE reads.
set(git_source_lines "")
foreach(git_source IN LISTS git_sources)
    get_property(source_dir TARGET ${git_source} PROPERTY _EP_SOURCE_DIR)
    string(APPEND git_source_lines "${git_source} ${source_dir}\n")
endforeach()
file(WRITE "${PROJECT_BINARY_DIR}/git-sources.txt" "${git_source_lines}")
add_custom_target(revisions
    COMMAND ${CMAKE_COMMAND}
        -D "GIT_SOURCES_FILE=${PROJECT_BINARY_DIR}/git-sources.txt"
        -D "REVISIONS_FILE=${PROJECT_BINARY_DIR}/revisions.txt"
        -P "${PROJECT_SOURCE_DIR}/cmake/WriteRevisions.cmake"
    VERBATIM
)
