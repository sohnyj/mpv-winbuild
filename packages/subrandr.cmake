# The Rust code is compiled to LLVM bitcode for the ThinLTO of the final link
# (-Clinker-plugin-lto). cargo xtask runs cargo again, so every setting goes
# through the environment.
ExternalProject_Add(subrandr
    DEPENDS
        freetype2
        harfbuzz
    GIT_REPOSITORY https://github.com/afishhh/subrandr.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${EXEC} ${CMAKE_COMMAND} -E env
        CARGO_NET_GIT_FETCH_WITH_CLI=true
        CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1
        CARGO_PROFILE_RELEASE_LTO=thin
        CARGO_PROFILE_RELEASE_PANIC=abort
        CARGO_PROFILE_RELEASE_STRIP=true
        "CARGO_TARGET_${RUST_TARGET_IDENTIFIER}_RUSTFLAGS=${TARGET_RUST_FLAGS} -Clinker-plugin-lto"
        cargo xtask install
        --prefix ${SYSROOT_DIR}
        --target ${RUST_TARGET}
        --shared-library false
        --static-library true
    BUILD_IN_SOURCE 1
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_BUILD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(subrandr)
cleanup(subrandr install)
