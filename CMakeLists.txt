cmake_minimum_required(VERSION 4.4)
project(mpv-winbuild LANGUAGES NONE)

if(NOT CMAKE_GENERATOR MATCHES "^Ninja")
    message(FATAL_ERROR "Configure with the Ninja generator (-G Ninja).")
endif()

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

# Inputs. scripts/build.sh passes every one of them, with the defaults of
# scripts/defaults.sh; CI calls the script.
set(LLVM_VERSION "" CACHE STRING "Major version of the apt.llvm.org toolchain")
set(TARGET_TRIPLE "" CACHE STRING "Target triple, such as x86_64-w64-mingw32")
set(TARGET_CPU_FLAGS "" CACHE STRING "clang CPU flags of the packages, such as -march=x86-64-v3 -mtune=generic")
set(TARGET_RUST_FLAGS "" CACHE STRING "rustc CPU flags of the packages, such as -C target-cpu=x86-64-v3")
set(RUNTIME_CPU_FLAGS "" CACHE STRING "clang CPU flags of the runtimes")
set(LTO_MODE "" CACHE STRING "clang -flto mode of the packages, such as thin")
set(MAKE_JOBS "" CACHE STRING "Parallel jobs of the make builds")
set(SYSROOT_DIR "" CACHE PATH "Directory the runtimes and packages are installed into")
set(SOURCES_DIR "" CACHE PATH "Directory holding the source checkouts, shared between build directories")
set(RUSTUP_LOCATION "" CACHE PATH "Directory of the Rust toolchain, shared between build directories")
foreach(variable IN ITEMS LLVM_VERSION TARGET_TRIPLE TARGET_CPU_FLAGS TARGET_RUST_FLAGS RUNTIME_CPU_FLAGS LTO_MODE MAKE_JOBS SYSROOT_DIR SOURCES_DIR RUSTUP_LOCATION)
    if(NOT ${variable})
        message(FATAL_ERROR "Set ${variable}; scripts/build.sh passes it.")
    endif()
endforeach()

find_program(MESON_EXECUTABLE NAMES meson REQUIRED)
execute_process(
    COMMAND "${MESON_EXECUTABLE}" --version
    OUTPUT_VARIABLE meson_version
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)
if(meson_version VERSION_LESS 1.12)
    message(FATAL_ERROR "Meson 1.12 or newer is required, found ${meson_version}")
endif()

# The architecture component of the triple.
string(REGEX MATCH "^[^-]+" TARGET_PROCESSOR "${TARGET_TRIPLE}")
set(RUST_TARGET "${TARGET_PROCESSOR}-pc-windows-gnullvm")
# The form of RUST_TARGET in the names of cargo's environment variables.
string(MAKE_C_IDENTIFIER "${RUST_TARGET}" RUST_TARGET_IDENTIFIER)
string(TOUPPER "${RUST_TARGET_IDENTIFIER}" RUST_TARGET_IDENTIFIER)
set(RESOURCE_DIR "${PROJECT_BINARY_DIR}/resource")
set(THINLTO_CACHE_DIR "${PROJECT_BINARY_DIR}/thinlto")

include(PatchedExternalProject)
include(Toolchain)
include(CustomSteps)

set_property(DIRECTORY PROPERTY EP_STEP_TARGETS download)

add_subdirectory(toolchain)
add_subdirectory(packages)

set(projects ${RUNTIMES} ${PACKAGES})
set(repositories "")
foreach(project IN LISTS projects)
    get_property(git_repository TARGET ${project} PROPERTY _EP_GIT_REPOSITORY)
    if(git_repository)
        list(APPEND repositories ${project})
    endif()
endforeach()
list(TRANSFORM repositories APPEND "-force-update" OUTPUT_VARIABLE update_targets)
list(TRANSFORM projects APPEND "-download" OUTPUT_VARIABLE download_targets)
list(TRANSFORM projects APPEND "-fullclean" OUTPUT_VARIABLE fullclean_targets)

add_custom_target(update)
add_dependencies(update ${update_targets})
add_custom_target(download)
add_dependencies(download ${download_targets})
add_custom_target(package-fullclean)
add_dependencies(package-fullclean ${fullclean_targets})
