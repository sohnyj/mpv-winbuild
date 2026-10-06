# The Rust toolchain for the target, installed into RUSTUP_LOCATION through
# the environment of EXEC.
ExternalProject_Add(rustup
    DOWNLOAD_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} sh -c "curl -sSf https://sh.rustup.rs | sh -s -- -y --target ${RUST_TARGET} --no-modify-path --profile minimal"
    BUILD_COMMAND ${EXEC} rustup update
    INSTALL_COMMAND ""
    LOG_CONFIGURE 1 LOG_BUILD 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

cleanup(rustup install)
