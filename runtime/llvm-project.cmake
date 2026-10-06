# Sources of compiler-rt, libc++, libc++abi and libunwind, at the commit the
# installed clang was built from.
add_package(llvm-project
    GIT_REPOSITORY https://github.com/llvm/llvm-project.git
    GIT_TAG "release/${LLVM_VERSION}.x"
    GIT_COMMIT "${LLVM_RUNTIMES_COMMIT}"
    SPARSE_EXCLUDE
        /*/test/
        /.ci/
        /.github/
        /bolt/
        /clang/
        /clang-tools-extra/
        /cross-project-tests/
        /flang/
        /flang-rt/
        /libclc/
        /libsycl/
        /lld/
        /lldb/
        /llvm-libgcc/
        /llvm/*
        /mlir/
        /offload/
        /openmp/
        /orc-rt/
        /polly/
        /utils/
    SPARSE_INCLUDE
        /llvm/cmake/
)
