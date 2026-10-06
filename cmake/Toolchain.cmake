# Toolchain profiles on top of the apt.llvm.org clang.
#
# A profile holds the ${TARGET_TRIPLE}-* compiler wrappers and binutils links,
# a pkg-config wrapper, the clang configuration file, a CMake toolchain file,
# a Meson cross file, an autoconf site file and a command wrapper. It defines
# tools and paths only; build switches stay in the recipes.

include_guard(GLOBAL)

find_program(CLANG_EXECUTABLE NAMES "clang-${LLVM_VERSION}" REQUIRED)
file(REAL_PATH "${CLANG_EXECUTABLE}" clang_real_path)
cmake_path(GET clang_real_path PARENT_PATH LLVM_BINARY_DIR)
# Reconfigure when apt upgrades clang, which can move the runtimes commit.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${clang_real_path}")

set(binutils ar dlltool nm objcopy objdump ranlib strip windres)
foreach(tool IN LISTS binutils)
    string(TOUPPER "LLVM_${tool}" variable)
    find_program("${variable}" NAMES "llvm-${tool}" HINTS "${LLVM_BINARY_DIR}" NO_DEFAULT_PATH REQUIRED)
endforeach()
find_program(PKGCONF_EXECUTABLE NAMES pkgconf REQUIRED)
find_program(NASM_EXECUTABLE NAMES nasm REQUIRED)
find_program(CCACHE_EXECUTABLE NAMES ccache REQUIRED)

execute_process(
    COMMAND "${CLANG_EXECUTABLE}" -print-resource-dir
    OUTPUT_VARIABLE clang_resource_dir
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)

# The llvm-project runtimes are built from release/<LLVM_VERSION>.x at the
# commit the installed clang was built from. apt.llvm.org records it in the
# package version of its release suites, for example
# 1:23.1.3~++20260922084409+67f4a076a097-1~exp1~20260922084419.77.
execute_process(
    COMMAND dpkg-query --show "--showformat=\${Version}" "clang-${LLVM_VERSION}"
    OUTPUT_VARIABLE clang_package_version
    COMMAND_ERROR_IS_FATAL ANY
)
if(NOT clang_package_version MATCHES "^[0-9]+:${LLVM_VERSION}\\.[0-9]+\\.[0-9]+~\\+\\+[0-9]+\\+([0-9a-f]+)-")
    message(FATAL_ERROR "clang-${LLVM_VERSION} ${clang_package_version} is not from an apt.llvm.org release suite")
endif()
set(LLVM_RUNTIMES_COMMIT "${CMAKE_MATCH_1}")
message(STATUS "clang-${LLVM_VERSION} ${clang_package_version}")

# clang resource directory: the builtin headers of the installed clang and the
# compiler-rt builtins built for the target (toolchain/compiler-rt.cmake).
file(MAKE_DIRECTORY "${RESOURCE_DIR}")
file(CREATE_LINK "${clang_resource_dir}/include" "${RESOURCE_DIR}/include" SYMBOLIC)

set(executable_permissions
    OWNER_READ OWNER_WRITE OWNER_EXECUTE
    GROUP_READ GROUP_EXECUTE
    WORLD_READ WORLD_EXECUTE
)

# add_toolchain_profile(<profile> <cpu flags>)
#
# Generates the profile in CMAKE_CURRENT_BINARY_DIR/<profile>, compiling for
# <cpu flags>, and sets, in the calling directory, the values the recipes pass
# to their build systems:
#
#   EXEC            command prefix that runs a command with the profile's
#                   tools first in PATH and its autoconf site file
#   MAKE            make with MAKE_JOBS jobs, run through EXEC
#   TOOLCHAIN_BIN_DIR  directory of the ${TARGET_TRIPLE}-* tools; llvm-windres
#                   finds its preprocessor only when started by this path
#   TOOLCHAIN_FILE  CMake toolchain file
#   MESON_CROSS     Meson cross file
#   PROFILE_FILES   every generated file a configure step depends on
function(add_toolchain_profile profile cpu_flags)
    set(PROFILE "${profile}")
    set(CPU_FLAGS "${cpu_flags}")
    set(profile_dir "${CMAKE_CURRENT_BINARY_DIR}/${profile}")
    set(BIN_DIR "${profile_dir}/bin")
    set(CONFIG_FILE "${profile_dir}/${TARGET_TRIPLE}.cfg")
    set(CONFIG_SITE "${profile_dir}/config.site")
    set(templates "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/templates")

    configure_file("${templates}/clang.cfg.in" "${CONFIG_FILE}" @ONLY)

    foreach(driver IN ITEMS clang clang++)
        set(DRIVER "${LLVM_BINARY_DIR}/${driver}")
        configure_file("${templates}/compiler.sh.in" "${BIN_DIR}/${TARGET_TRIPLE}-${driver}"
            FILE_PERMISSIONS ${executable_permissions}
            @ONLY
        )
    endforeach()

    foreach(tool IN LISTS binutils)
        string(TOUPPER "LLVM_${tool}" variable)
        file(CREATE_LINK "${${variable}}" "${BIN_DIR}/${TARGET_TRIPLE}-${tool}" SYMBOLIC)
    endforeach()

    configure_file("${templates}/pkg-config.sh.in" "${BIN_DIR}/${TARGET_TRIPLE}-pkg-config"
        FILE_PERMISSIONS ${executable_permissions}
        @ONLY
    )
    configure_file("${templates}/exec.sh.in" "${profile_dir}/exec"
        FILE_PERMISSIONS ${executable_permissions}
        @ONLY
    )
    configure_file("${templates}/toolchain.cmake.in" "${profile_dir}/toolchain.cmake" @ONLY)
    configure_file("${templates}/meson-cross.ini.in" "${profile_dir}/meson-cross.ini" @ONLY)
    configure_file("${templates}/config.site.in" "${CONFIG_SITE}" @ONLY)

    set(EXEC "${profile_dir}/exec" PARENT_SCOPE)
    set(MAKE "${profile_dir}/exec" make "-j${MAKE_JOBS}" PARENT_SCOPE)
    set(TOOLCHAIN_BIN_DIR "${BIN_DIR}" PARENT_SCOPE)
    set(TOOLCHAIN_FILE "${profile_dir}/toolchain.cmake" PARENT_SCOPE)
    set(MESON_CROSS "${profile_dir}/meson-cross.ini" PARENT_SCOPE)
    # configure_file() rewrites a file only when its content changes, so
    # depending on these reconfigures packages only after a real change.
    set(PROFILE_FILES
        "${CONFIG_FILE}"
        "${BIN_DIR}/${TARGET_TRIPLE}-clang"
        "${BIN_DIR}/${TARGET_TRIPLE}-clang++"
        "${BIN_DIR}/${TARGET_TRIPLE}-pkg-config"
        "${profile_dir}/exec"
        "${profile_dir}/toolchain.cmake"
        "${profile_dir}/meson-cross.ini"
        "${CONFIG_SITE}"
        PARENT_SCOPE
    )
endfunction()
