cmake_minimum_required(VERSION 4.4)
project(mpv-winbuild LANGUAGES NONE)

if(NOT CMAKE_GENERATOR MATCHES "^Ninja")
    message(FATAL_ERROR "Configure with the Ninja generator (-G Ninja).")
endif()

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
include(CpuLevels)

# The scripts and CI pass these; scripts/defaults.sh holds their defaults.
set(LLVM_VERSION "" CACHE STRING "Major version of the apt.llvm.org toolchain")
set(TARGET_LEVEL "" CACHE STRING "CPU level the packages are built for (cmake/CpuLevels.cmake)")
set(TARGET_TUNE "" CACHE STRING "clang -mtune for the packages; empty for the tuning of TARGET_LEVEL")
get_property(cpu_levels GLOBAL PROPERTY CPU_LEVELS)
set_property(CACHE TARGET_LEVEL PROPERTY STRINGS ${cpu_levels})
foreach(variable IN ITEMS LLVM_VERSION TARGET_LEVEL)
    if(NOT ${variable})
        message(FATAL_ERROR "Set ${variable}; scripts/defaults.sh holds the default.")
    endif()
endforeach()
if(NOT LLVM_VERSION MATCHES "^[0-9]+$")
    message(FATAL_ERROR "LLVM_VERSION is a major version such as 23, not ${LLVM_VERSION}")
endif()

set(SOURCES_DIR "${PROJECT_SOURCE_DIR}/sources" CACHE PATH
    "Directory holding the source checkouts, shared between build directories")

include(Toolchain)
include(AddPackage)

# The runtimes are built for x86-64-v3 at every level, and the packages of
# every level link against them.
cpu_level_flags(x86-64-v3 runtime_cpu_flags)
add_toolchain_profile(runtime ${runtime_cpu_flags})
cpu_level_flags("${TARGET_LEVEL}" target_cpu_flags TUNE "${TARGET_TUNE}")
add_toolchain_profile(target ${target_cpu_flags})

foreach(recipe IN ITEMS
    llvm-project
    mingw-w64
    mingw-w64-headers
    mingw-w64-crt
    compiler-rt
    libcxx
    winpthreads
)
    include("runtime/${recipe}.cmake")
endforeach()

get_property(update_targets GLOBAL PROPERTY SOURCE_UPDATE_TARGETS)
add_custom_target(update)
add_dependencies(update ${update_targets})
