# Toolchain profiles: what every build of a profile shares, in three layers.
#   compiler and linker  clang configuration file (target, sysroot, runtimes,
#                        flags), ${TARGET_TRIPLE}-* compiler wrappers through
#                        ccache, binutils links
#   build systems        CMake toolchain file, Meson cross and native files,
#                        autoconf site file, command wrapper, cargo wrapper
#   dependencies         pkg-config wrapper for static linking from the sysroot
# Switches of a single package stay in its recipe.

include_guard(GLOBAL)

include(BuildTools)

# clang resource directory: the headers of the installed clang and the builtins
# of toolchain/compiler-rt.cmake.
execute_process(
    COMMAND "${CLANG_EXECUTABLE}" -print-resource-dir
    OUTPUT_VARIABLE installed_resource_dir
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)
file(MAKE_DIRECTORY "${CLANG_RESOURCE_DIR}")
file(CREATE_LINK "${installed_resource_dir}/include" "${CLANG_RESOURCE_DIR}/include" SYMBOLIC)

# add_toolchain_profile(<profile> <cpu flags> <preprocessor flags>)
#
# Generates the profile for <cpu flags> and <preprocessor flags> in
# CMAKE_CURRENT_BINARY_DIR/<profile> and sets in the calling directory:
#
#   EXEC               command prefix with the profile's tools first in PATH
#                      and its autoconf site file
#   CARGO_EXEC         EXEC with the Rust toolchain of RUSTUP_DIR and the
#                      profile's cargo linkers; not among PROFILE_FILES
#   MAKE               make with MAKE_JOBS jobs, run through EXEC
#   TOOLCHAIN_BIN_DIR  directory of the ${TARGET_TRIPLE}-* tools
#   TOOLCHAIN_FILE     CMake toolchain file
#   MESON_CROSS_FILE   Meson cross file
#   MESON_NATIVE_FILE  Meson native file
#   PROFILE_FILES      the generated files that the patch step of every
#                      toolchain component and package depends on
function(add_toolchain_profile profile cpu_flags preprocessor_flags)
    set(PROFILE "${profile}")
    set(CPU_FLAGS "${cpu_flags}")
    set(PREPROCESSOR_FLAGS "${preprocessor_flags}")
    set(profile_dir "${CMAKE_CURRENT_BINARY_DIR}/${profile}")
    set(TOOLCHAIN_BIN_DIR "${profile_dir}/bin")
    set(CLANG_CONFIG_FILE "${profile_dir}/${TARGET_TRIPLE}.cfg")
    set(CONFIG_SITE "${profile_dir}/config.site")
    set(EXEC "${profile_dir}/exec")
    set(profile_template_dir "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/profile")

    configure_file("${profile_template_dir}/clang.cfg.in" "${CLANG_CONFIG_FILE}" @ONLY)

    foreach(driver IN ITEMS clang clang++)
        set(DRIVER "${LLVM_TOOLS_BINARY_DIR}/${driver}")
        configure_file("${profile_template_dir}/clang.sh.in" "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLE}-${driver}" @ONLY)
    endforeach()

    foreach(tool IN LISTS LLVM_BINUTILS)
        string(TOUPPER "LLVM_${tool}" variable)
        file(CREATE_LINK "${${variable}}" "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLE}-${tool}" SYMBOLIC)
    endforeach()

    configure_file("${profile_template_dir}/pkg-config.sh.in" "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLE}-pkg-config" @ONLY)
    configure_file("${profile_template_dir}/exec.sh.in" "${EXEC}" @ONLY)
    configure_file("${profile_template_dir}/cargo-exec.sh.in" "${profile_dir}/cargo-exec" @ONLY)
    configure_file("${profile_template_dir}/toolchain.cmake.in" "${profile_dir}/toolchain.cmake" @ONLY)
    configure_file("${profile_template_dir}/meson-cross.ini.in" "${profile_dir}/meson-cross.ini" @ONLY)
    configure_file("${profile_template_dir}/meson-native.ini.in" "${profile_dir}/meson-native.ini" @ONLY)
    configure_file("${profile_template_dir}/config.site.in" "${CONFIG_SITE}" @ONLY)

    set(EXEC "${EXEC}" PARENT_SCOPE)
    set(CARGO_EXEC "${profile_dir}/cargo-exec" PARENT_SCOPE)
    set(MAKE "${EXEC}" make "-j${MAKE_JOBS}" PARENT_SCOPE)
    set(TOOLCHAIN_BIN_DIR "${TOOLCHAIN_BIN_DIR}" PARENT_SCOPE)
    set(TOOLCHAIN_FILE "${profile_dir}/toolchain.cmake" PARENT_SCOPE)
    set(MESON_CROSS_FILE "${profile_dir}/meson-cross.ini" PARENT_SCOPE)
    set(MESON_NATIVE_FILE "${profile_dir}/meson-native.ini" PARENT_SCOPE)

    # configure_file() rewrites a file only when its content changes, so only
    # a changed file rebuilds what depends on it.
    set(PROFILE_FILES
        "${CLANG_CONFIG_FILE}"
        "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLE}-clang"
        "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLE}-clang++"
        "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLE}-pkg-config"
        "${EXEC}"
        "${profile_dir}/toolchain.cmake"
        "${profile_dir}/meson-cross.ini"
        "${profile_dir}/meson-native.ini"
        "${CONFIG_SITE}"
        PARENT_SCOPE
    )
endfunction()
