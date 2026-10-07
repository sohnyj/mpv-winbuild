# Writes spirv-cross-c-shared.pc for the static SPIRV-Cross libraries, from the
# installed spirv-cross-c.pc and the libraries the C API depends on.
#
#   cmake -D PKG_CONFIG_DIR=<dir> -P spirv-cross-write-pkg-config.cmake

cmake_minimum_required(VERSION 4.4)

file(READ "${PKG_CONFIG_DIR}/spirv-cross-c.pc" content)
string(REGEX REPLACE "\nName: [^\n]*" "\nName: spirv-cross-c-shared" content "${content}")
string(REGEX REPLACE "\nLibs: ([^\n]*)"
    "\nLibs: \\1 -lspirv-cross-hlsl -lspirv-cross-glsl -lspirv-cross-core" content "${content}")
file(WRITE "${PKG_CONFIG_DIR}/spirv-cross-c-shared.pc" "${content}")
