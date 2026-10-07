# Toolchain profiles: what every build of a profile shares, in three layers.
#   compiler and linker  clang configuration file (target, sysroot, runtimes,
#                        flags), ${TARGET_TRIPLE}-* compiler wrappers through
#                        ccache, binutils links
#   build systems        CMake toolchain file, Meson cross and native files,
#                        autoconf site file, command wrapper
#   dependencies         pkg-config wrapper for static linking from the sysroot
# Switches of a single package stay in its recipe. A setting here that only
# reflects what no package needs otherwise says so.

include_guard(GLOBAL)

include(BuildTools)

# clang resource directory: the headers of the installed clang and the builtins
# of toolchain/compiler-rt.cmake.
execute_process(
    COMMAND "${CLANG_EXECUTABLE}" -print-resource-dir
    OUTPUT_VARIABLE clang_resource_dir
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)
file(MAKE_DIRECTORY "${CLANG_RESOURCE_DIR}")
file(CREATE_LINK "${clang_resource_dir}/include" "${CLANG_RESOURCE_DIR}/include" SYMBOLIC)

# add_toolchain_profile(<profile> <cpu flags>)
#
# Generates the profile for <cpu flags> in CMAKE_CURRENT_BINARY_DIR/<profile>
# and sets in the calling directory:
#
#   EXEC            command prefix with the profile's tools first in PATH and
#                   its autoconf site file
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
    set(CLANG_CONFIG_FILE "${profile_dir}/${TARGET_TRIPLE}.cfg")
    set(CONFIG_SITE "${profile_dir}/config.site")
    set(profile_template_dir "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/profile")

    configure_file("${profile_template_dir}/clang.cfg.in" "${CLANG_CONFIG_FILE}" @ONLY)

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
        "${CLANG_CONFIG_FILE}"
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
