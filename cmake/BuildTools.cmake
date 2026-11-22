# Programs the build runs, and the CMake package and llvm commit of the
# installed LLVM.

include_guard(GLOBAL)

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

find_program(CLANG_EXECUTABLE NAMES "clang-${LLVM_VERSION}" REQUIRED)
file(REAL_PATH "${CLANG_EXECUTABLE}" clang_real_path)
cmake_path(GET clang_real_path PARENT_PATH LLVM_TOOLS_BINARY_DIR)
cmake_path(GET LLVM_TOOLS_BINARY_DIR PARENT_PATH llvm_prefix)
set(LLVM_CMAKE_PACKAGE_DIR "${llvm_prefix}/lib/cmake/llvm")
# Reconfigure when apt upgrades clang, which can change the llvm commit.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${clang_real_path}")

set(HOST_C_COMPILER "${LLVM_TOOLS_BINARY_DIR}/clang")
set(HOST_CXX_COMPILER "${LLVM_TOOLS_BINARY_DIR}/clang++")

# LLVM tools used as binutils, found as LLVM_<TOOL>.
set(LLVM_BINUTILS ar dlltool nm objcopy objdump ranlib strip windres)
foreach(tool IN LISTS LLVM_BINUTILS)
    string(TOUPPER "LLVM_${tool}" variable)
    find_program("${variable}" NAMES "llvm-${tool}" HINTS "${LLVM_TOOLS_BINARY_DIR}" NO_DEFAULT_PATH REQUIRED)
endforeach()
find_program(PKGCONF_EXECUTABLE NAMES pkgconf REQUIRED)
find_program(NASM_EXECUTABLE NAMES nasm REQUIRED)
find_program(CCACHE_EXECUTABLE NAMES ccache REQUIRED)
find_program(MAKE_EXECUTABLE NAMES make REQUIRED)
find_package(Git REQUIRED)

# Runtimes are built at the commit of the installed LLVM, which its apt.llvm.org
# package version contains:
# 1:23.1.3~++20260922084409+67f4a076a097-1~exp1~20260922084419.77
execute_process(
    COMMAND dpkg-query --show "--showformat=\${Version}" "llvm-${LLVM_VERSION}"
    OUTPUT_VARIABLE llvm_package_version
    COMMAND_ERROR_IS_FATAL ANY
)
if(NOT llvm_package_version MATCHES "^[0-9]+:${LLVM_VERSION}\\.[0-9]+\\.[0-9]+~\\+\\+[0-9]+\\+([0-9a-f]+)-")
    message(FATAL_ERROR "llvm-${LLVM_VERSION} ${llvm_package_version} is not from an apt.llvm.org release suite")
endif()
set(LLVM_COMMIT "${CMAKE_MATCH_1}")
message(STATUS "llvm-${LLVM_VERSION} ${llvm_package_version}")
