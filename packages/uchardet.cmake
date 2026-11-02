# The project's minimum CMake version predates policy CMP0069, so CMake ignores
# CMAKE_INTERPROCEDURAL_OPTIMIZATION unless the policy default is NEW. Only the
# library is built: the tests are added unconditionally.
ExternalProject_Add(uchardet
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_POLICY_DEFAULT_CMP0069=NEW
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBUILD_BINARY=OFF
        -DBUILD_SHARED_LIBS=OFF
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target libuchardet
    INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR>
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(uchardet
    REPOSITORY https://gitlab.freedesktop.org/uchardet/uchardet.git
    TAG master
    CLONE_FLAGS "--filter=tree:0"
)
add_cleanup_steps(uchardet install)
