# libc++, libc++abi and libunwind, static, on the Win32 thread API.
#
# The compiler checks are skipped because linking a C++ program needs the
# libraries built here.
add_package(libcxx
    DEPENDS
        compiler-rt
    SOURCE_FROM llvm-project
    SOURCE_SUBDIR runtimes
    PROFILE runtime
    CMAKE_ARGS
        -DCMAKE_C_COMPILER_WORKS=ON
        -DCMAKE_CXX_COMPILER_WORKS=ON
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
)
