# libc++, libc++abi and libunwind, static, on the Win32 thread API.
#
# Linking a program needs the libraries built here, so the configure checks link
# without libunwind and libc++, as the runtimes build does for its own checks.
ExternalProject_Add(libcxx
    DEPENDS
        compiler-rt
        llvm-project
    DOWNLOAD_COMMAND ""
    SOURCE_SUBDIR runtimes
    LIST_SEPARATOR |
    SOURCE_DIR ${LLVM_SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
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
        "-DCMAKE_EXE_LINKER_FLAGS=--unwindlib=none -nostdlib++"
    LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

cleanup(libcxx install)
