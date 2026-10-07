# compiler-rt builtins, installed into the resource directory of the build
# directory. Nothing links before the builtins exist, so the compiler checks
# only compile.
ExternalProject_Add(compiler-rt
    DEPENDS
        llvm-project
        mingw-w64-crt
    DOWNLOAD_COMMAND ""
    SOURCE_SUBDIR compiler-rt/lib/builtins
    SOURCE_DIR ${LLVM_SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_C_COMPILER_TARGET=${TARGET_TRIPLE}
        -DCMAKE_INSTALL_PREFIX=${CLANG_RESOURCE_DIR}
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY
        -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON
        -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=OFF
        -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON
    LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

cleanup(compiler-rt install)
