# The programs that the build runs, found once for every recipe and toolchain
# profile: Meson, the apt.llvm.org clang with its LLVM tools, the compilers for
# the build machine, and the assemblers, compilers and wrappers that the
# recipes name. Also the llvm-project commit of the installed clang.

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
cmake_path(GET clang_real_path PARENT_PATH LLVM_BINARY_DIR)
# Reconfigure when apt upgrades clang, which can move the runtimes commit.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${clang_real_path}")
# Compilers of the programs that run on the build machine during the build,
# such as code generators and configure checks.
set(HOST_C_COMPILER "${LLVM_BINARY_DIR}/clang")
set(HOST_CXX_COMPILER "${LLVM_BINARY_DIR}/clang++")

# The LLVM tools that stand in for binutils, found as LLVM_<TOOL>.
set(LLVM_BINUTILS ar dlltool nm objcopy objdump ranlib strip windres)
foreach(tool IN LISTS LLVM_BINUTILS)
    string(TOUPPER "LLVM_${tool}" variable)
    find_program("${variable}" NAMES "llvm-${tool}" HINTS "${LLVM_BINARY_DIR}" NO_DEFAULT_PATH REQUIRED)
endforeach()
find_program(PKGCONF_EXECUTABLE NAMES pkgconf REQUIRED)
find_program(NASM_EXECUTABLE NAMES nasm REQUIRED)
find_program(GLSLANG_EXECUTABLE NAMES glslang REQUIRED)
find_program(CCACHE_EXECUTABLE NAMES ccache REQUIRED)

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
