# Sources of compiler-rt, libc++, libc++abi and libunwind, at the commit the
# installed clang was built from.
ExternalProject_Add(llvm
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(llvm
    REPOSITORY https://github.com/llvm/llvm-project.git
    TAG release/${LLVM_VERSION}.x
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/*/test/
        !/.ci/
        !/.github/
        !/bolt/
        !/clang/
        !/clang-tools-extra/
        !/cross-project-tests/
        !/flang/
        !/flang-rt/
        !/libclc/
        !/libsycl/
        !/lld/
        !/lldb/
        !/llvm-libgcc/
        !/llvm/*
        !/mlir/
        !/offload/
        !/openmp/
        !/orc-rt/
        !/polly/
        !/utils/
        /llvm/cmake/"
    RESET ${LLVM_COMMIT}
)
add_cleanup_steps(llvm install)

set(LLVM_SOURCE_DIR ${SOURCE_DIR})
