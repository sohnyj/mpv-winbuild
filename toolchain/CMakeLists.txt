# Toolchain components: the runtimes of the target, built with the runtime
# profile, and host tools. The runtime profile has no _FORTIFY_SOURCE: built
# with it, mingw-w64-crt's __memcpy_chk loops forever instead of copying. It has
# no stack protector either, since mingw-w64-crt sets __stack_chk_guard while
# frames of its own startup code have yet to return.
add_toolchain_profile(runtime "${RUNTIME_CPU_FLAGS}" "" "")

set(toolchain_components
    # depth 0
    glslang
    llvm
    mingw-w64
    rustup
    windows-rs
    # depth 1
    cppwinrt
    mingw-w64-headers
    # depth 2
    mingw-w64-crt
    # depth 3
    compiler-rt
    # depth 4
    libcxx
    # depth 5
    winpthreads
)

foreach(toolchain_component IN LISTS toolchain_components)
    set(SOURCE_DIR "${SOURCES_DIR}/${toolchain_component}")
    include("${CMAKE_CURRENT_SOURCE_DIR}/${toolchain_component}.cmake")
    # When the toolchain profile changes, the steps from patch on run again,
    # since the checkout is reset after the install step.
    ExternalProject_Add_StepDependencies("${toolchain_component}" patch ${PROFILE_FILES})
endforeach()

set(TOOLCHAIN_COMPONENTS ${toolchain_components} PARENT_SCOPE)
set(GLSLANG_EXECUTABLE ${GLSLANG_EXECUTABLE} PARENT_SCOPE)
set(GLSLANG_SOURCE_DIR ${GLSLANG_SOURCE_DIR} PARENT_SCOPE)
