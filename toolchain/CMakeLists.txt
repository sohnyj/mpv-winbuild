# Runtimes of the target, built with the runtime profile into the sysroot.
add_toolchain_profile(runtime "${RUNTIME_CPU_FLAGS}")

set(packages
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
foreach(package IN LISTS packages)
    set(SOURCE_LOCATION "${SOURCES_DIR}/${package}")
    include("${CMAKE_CURRENT_SOURCE_DIR}/${package}.cmake")
    # A new toolchain profile rebuilds from the patch step: cleanup() restores
    # the checkout after the install step.
    ExternalProject_Add_StepDependencies("${package}" patch ${PROFILE_FILES})
endforeach()
# The packages are built after the runtimes, but a new runtime does not rebuild
# them.
set(RUNTIMES ${packages} PARENT_SCOPE)
