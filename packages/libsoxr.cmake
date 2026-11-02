# The project's minimum CMake version, 3.1, is below 3.5, the oldest that
# CMake 4 accepts, and predates policy CMP0069, so CMake ignores
# CMAKE_INTERPROCEDURAL_OPTIMIZATION unless the policy default is NEW.
ExternalProject_Add(libsoxr
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_POLICY_DEFAULT_CMP0069=NEW
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_TESTS=OFF
        -DWITH_DEV_TRACE=OFF
        -DWITH_LSR_BINDINGS=OFF
        -DWITH_OPENMP=OFF
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(libsoxr
    REPOSITORY https://github.com/chirlu/soxr.git
    TAG master
    CLONE_FLAGS "--filter=tree:0"
)
add_cleanup_steps(libsoxr install)
