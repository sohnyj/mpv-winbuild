# libc++, libc++abi and libunwind, static, on the Win32 thread API.
#
# The compiler checks are skipped because linking a C++ program needs the
# libraries built here.
ExternalProject_Add(libcxx
    DEPENDS
        compiler-rt
        llvm-project
    DOWNLOAD_COMMAND ""
    SOURCE_DIR ${LLVM_SOURCE_DIR}
    SOURCE_SUBDIR runtimes
    LIST_SEPARATOR |
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_C_COMPILER_WORKS=ON
        -DCMAKE_CXX_COMPILER_WORKS=ON
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DLIBCXXABI_ENABLE_ASSERTIONS=OFF
        -DLIBCXXABI_ENABLE_SHARED=OFF
        -DLIBCXXABI_HAS_WIN32_THREAD_API=ON
        -DLIBCXXABI_USE_COMPILER_RT=ON
        -DLIBCXX_ENABLE_SHARED=OFF
        -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON
        -DLIBCXX_HAS_WIN32_THREAD_API=ON
        -DLIBCXX_USE_COMPILER_RT=ON
        -DLIBUNWIND_ENABLE_ASSERTIONS=OFF
        -DLIBUNWIND_ENABLE_SHARED=OFF
        -DLIBUNWIND_USE_COMPILER_RT=ON
        -DLLVM_ENABLE_RUNTIMES=libunwind|libcxxabi|libcxx
        -DLLVM_INCLUDE_TESTS=OFF
    LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

cleanup(libcxx install)
