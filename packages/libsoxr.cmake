# The project requires a CMake older than policy CMP0069, which then ignores
# CMAKE_INTERPROCEDURAL_OPTIMIZATION; the policy default enables LTO.
ExternalProject_Add(libsoxr
    GIT_REPOSITORY https://github.com/chirlu/soxr.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_TESTS=OFF
        -DCMAKE_POLICY_DEFAULT_CMP0069=NEW
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
        -DWITH_DEV_TRACE=OFF
        -DWITH_LSR_BINDINGS=OFF
        -DWITH_OPENMP=OFF
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_update_steps(libsoxr)
cleanup(libsoxr install)
