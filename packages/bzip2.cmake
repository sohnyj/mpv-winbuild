# The Makefile has no install target for the library alone.
ExternalProject_Add(bzip2
    GIT_REPOSITORY https://sourceware.org/git/bzip2.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${MAKE} libbz2.a
        AR=${TARGET_TRIPLE}-ar
        CC=${TARGET_TRIPLE}-clang
        RANLIB=${TARGET_TRIPLE}-ranlib
        "CFLAGS=-D_FILE_OFFSET_BITS=64 -O3 -flto=${LTO_MODE}"
    BUILD_IN_SOURCE 1
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/bzlib.h ${SYSROOT_DIR}/include/bzlib.h
        COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/libbz2.a ${SYSROOT_DIR}/lib/libbz2.a
    LOG_DOWNLOAD 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_update_steps(bzip2)
add_cleanup_steps(bzip2 install)
