# The Rust toolchain of the packages written in Rust, in RUSTUP_DIR.
ExternalProject_Add(rustup
    DOWNLOAD_COMMAND ""
    CONFIGURE_COMMAND ${CARGO_EXEC} sh -c "curl -sSf https://sh.rustup.rs | sh -s -- -y --default-host ${RUST_HOST} --target ${RUST_TARGET} --no-modify-path --profile minimal"
    BUILD_COMMAND ${CARGO_EXEC} rustup update
    INSTALL_COMMAND ""
    LOG_CONFIGURE 1 LOG_BUILD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

ExternalProject_Add_StepDependencies(rustup patch ${CARGO_EXEC})
add_cleanup_steps(rustup install)
