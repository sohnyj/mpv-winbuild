# Toolchain profiles on top of the apt.llvm.org clang.
#
# A profile holds what every build of the profile shares, in three layers:
#   compiler and linker  the clang configuration file, with the target, the
#                        sysroot, the runtimes and the flags of the whole
#                        target; the ${TARGET_TRIPLE}-* compiler wrappers,
#                        which run clang through ccache; the binutils links
#   build systems        a CMake toolchain file, Meson cross and native files,
#                        an autoconf site file and a command wrapper, which
#                        give each build system its tools, the sysroot and the
#                        compilers for the build machine
#   dependencies         a pkg-config wrapper that queries the sysroot for
#                        static linking
# Switches of a single package stay in its recipe. A setting kept here only
# because no package needs otherwise says so in a comment.

include_guard(GLOBAL)

include(BuildTools)

# clang resource directory: the builtin headers of the installed clang and the
# compiler-rt builtins built for the target (toolchain/compiler-rt.cmake).
execute_process(
    COMMAND "${CLANG_EXECUTABLE}" -print-resource-dir
    OUTPUT_VARIABLE clang_resource_dir
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)
file(MAKE_DIRECTORY "${RESOURCE_DIR}")
file(CREATE_LINK "${clang_resource_dir}/include" "${RESOURCE_DIR}/include" SYMBOLIC)

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
#   MESON_NATIVE    Meson native file
#   PROFILE_FILES   every generated file a configure step depends on
function(add_toolchain_profile profile cpu_flags)
    set(PROFILE "${profile}")
    set(CPU_FLAGS "${cpu_flags}")
    set(profile_dir "${CMAKE_CURRENT_BINARY_DIR}/${profile}")
    set(BIN_DIR "${profile_dir}/bin")
    set(CONFIG_FILE "${profile_dir}/${TARGET_TRIPLE}.cfg")
    set(CONFIG_SITE "${profile_dir}/config.site")
    set(profile_template_dir "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/profile")

    configure_file("${profile_template_dir}/clang.cfg.in" "${CONFIG_FILE}" @ONLY)

    foreach(driver IN ITEMS clang clang++)
        set(DRIVER "${LLVM_BINARY_DIR}/${driver}")
        configure_file("${profile_template_dir}/compiler.sh.in" "${BIN_DIR}/${TARGET_TRIPLE}-${driver}" @ONLY)
    endforeach()

    foreach(tool IN LISTS LLVM_BINUTILS)
        string(TOUPPER "LLVM_${tool}" variable)
        file(CREATE_LINK "${${variable}}" "${BIN_DIR}/${TARGET_TRIPLE}-${tool}" SYMBOLIC)
    endforeach()

    configure_file("${profile_template_dir}/pkg-config.sh.in" "${BIN_DIR}/${TARGET_TRIPLE}-pkg-config" @ONLY)
    configure_file("${profile_template_dir}/exec.sh.in" "${profile_dir}/exec" @ONLY)
    configure_file("${profile_template_dir}/toolchain.cmake.in" "${profile_dir}/toolchain.cmake" @ONLY)
    configure_file("${profile_template_dir}/meson-cross.ini.in" "${profile_dir}/meson-cross.ini" @ONLY)
    configure_file("${profile_template_dir}/meson-native.ini.in" "${profile_dir}/meson-native.ini" @ONLY)
    configure_file("${profile_template_dir}/config.site.in" "${CONFIG_SITE}" @ONLY)

    set(EXEC "${profile_dir}/exec" PARENT_SCOPE)
    set(MAKE "${profile_dir}/exec" make "-j${MAKE_JOBS}" PARENT_SCOPE)
    set(TOOLCHAIN_BIN_DIR "${BIN_DIR}" PARENT_SCOPE)
    set(TOOLCHAIN_FILE "${profile_dir}/toolchain.cmake" PARENT_SCOPE)
    set(MESON_CROSS "${profile_dir}/meson-cross.ini" PARENT_SCOPE)
    set(MESON_NATIVE "${profile_dir}/meson-native.ini" PARENT_SCOPE)
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
        "${profile_dir}/meson-native.ini"
        "${CONFIG_SITE}"
        PARENT_SCOPE
    )
endfunction()
