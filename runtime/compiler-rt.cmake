# compiler-rt builtins, installed into the clang resource directory of the
# build directory.
add_package(compiler-rt
    DEPENDS
        mingw-w64-crt
    SOURCE_FROM llvm-project
    SOURCE_SUBDIR compiler-rt/lib/builtins
    PROFILE runtime
    INSTALL_DIR "${RESOURCE_DIR}"
    CMAKE_ARGS
        -DCMAKE_C_COMPILER_TARGET=x86_64-w64-windows-gnu
        -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY
        -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON
        -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=OFF
        -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON
)
