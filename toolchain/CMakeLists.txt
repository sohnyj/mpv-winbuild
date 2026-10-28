# Toolchain components: the runtimes of the target, built with the runtime
# profile, and host tools.
add_toolchain_profile(runtime "${RUNTIME_CPU_FLAGS}")

set(toolchain_components
    # depth 0
    llvm-project
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
    # A changed toolchain profile rebuilds from the patch step, since the
    # checkout is reset after the install step.
    ExternalProject_Add_StepDependencies("${toolchain_component}" patch ${PROFILE_FILES})
endforeach()

set(TOOLCHAIN_COMPONENTS ${toolchain_components} PARENT_SCOPE)
