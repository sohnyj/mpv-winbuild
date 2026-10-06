# Toolchain profiles on top of the apt.llvm.org clang.
#
# A profile is a directory under TOOLCHAIN_DIR holding the
# x86_64-w64-mingw32-* compiler wrappers and binutils links, a pkg-config
# wrapper, the clang configuration file and a CMake toolchain file. Every
# generated file lives inside the build directory, so build directories for
# different CPU levels never affect each other.

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

set(TOOLCHAIN_DIR "${PROJECT_BINARY_DIR}/toolchain")
set(SYSROOT_DIR "${PROJECT_BINARY_DIR}/sysroot")
set(RESOURCE_DIR "${TOOLCHAIN_DIR}/resource")
set(THINLTO_CACHE_DIR "${PROJECT_BINARY_DIR}/thinlto")

# clang resource directory: the builtin headers of the installed clang and the
# compiler-rt builtins built for the target (runtime/compiler-rt.cmake).
file(MAKE_DIRECTORY "${RESOURCE_DIR}")
file(CREATE_LINK "${clang_resource_dir}/include" "${RESOURCE_DIR}/include" SYMBOLIC)

set(executable_permissions
    OWNER_READ OWNER_WRITE OWNER_EXECUTE
    GROUP_READ GROUP_EXECUTE
    WORLD_READ WORLD_EXECUTE
)

# add_toolchain_profile(<profile> <cpu-flag>...)
#
# Generates TOOLCHAIN_DIR/<profile> and sets <PROFILE>_BIN_DIR and
# <PROFILE>_TOOLCHAIN_FILE in the calling scope.
function(add_toolchain_profile profile)
    set(PROFILE "${profile}")
    set(profile_dir "${TOOLCHAIN_DIR}/${profile}")
    set(BIN_DIR "${profile_dir}/bin")
    set(CONFIG_FILE "${profile_dir}/x86_64-w64-windows-gnu.cfg")
    set(templates "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/templates")

    list(JOIN ARGN "\n" CPU_FLAGS)
    configure_file("${templates}/clang.cfg.in" "${CONFIG_FILE}" @ONLY)

    foreach(driver IN ITEMS clang clang++)
        set(DRIVER "${LLVM_BINARY_DIR}/${driver}")
        configure_file("${templates}/compiler.sh.in" "${BIN_DIR}/x86_64-w64-mingw32-${driver}"
            FILE_PERMISSIONS ${executable_permissions}
            @ONLY
        )
    endforeach()

    foreach(tool IN LISTS binutils)
        string(TOUPPER "LLVM_${tool}" variable)
        file(CREATE_LINK "${${variable}}" "${BIN_DIR}/x86_64-w64-mingw32-${tool}" SYMBOLIC)
    endforeach()

    configure_file("${templates}/pkg-config.sh.in" "${BIN_DIR}/x86_64-w64-mingw32-pkg-config"
        FILE_PERMISSIONS ${executable_permissions}
        @ONLY
    )
    configure_file("${templates}/toolchain.cmake.in" "${profile_dir}/toolchain.cmake" @ONLY)

    string(TOUPPER "${profile}" prefix)
    set("${prefix}_BIN_DIR" "${BIN_DIR}" PARENT_SCOPE)
    set("${prefix}_TOOLCHAIN_FILE" "${profile_dir}/toolchain.cmake" PARENT_SCOPE)
endfunction()
