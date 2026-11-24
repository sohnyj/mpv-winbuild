# Rust toolchain of packages written in Rust, in RUSTUP_DIR.
ExternalProject_Add(rustup
    DOWNLOAD_COMMAND ""
    CONFIGURE_COMMAND curl -sSf -o <TMP_DIR>/rustup-init.sh https://sh.rustup.rs
        COMMAND ${CARGO_EXEC} sh <TMP_DIR>/rustup-init.sh -y
            --default-host ${RUST_HOST}
            --no-modify-path
            --profile minimal
            --target ${RUST_TARGET}
    BUILD_COMMAND ${CARGO_EXEC} rustup update
    INSTALL_COMMAND ""
    LOG_CONFIGURE 1 LOG_BUILD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

ExternalProject_Add_StepDependencies(rustup patch ${CARGO_EXEC})
