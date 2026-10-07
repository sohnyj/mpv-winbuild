# Runtimes of the target, built with the runtime profile, and host tools.
add_toolchain_profile(runtime "${RUNTIME_CPU_FLAGS}")

set(projects
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

foreach(project IN LISTS projects)
    set(SOURCE_LOCATION "${SOURCES_DIR}/${project}")
    include("${CMAKE_CURRENT_SOURCE_DIR}/${project}.cmake")
    # A new toolchain profile rebuilds from the patch step: cleanup() restores
    # the checkout after the install step.
    ExternalProject_Add_StepDependencies("${project}" patch ${PROFILE_FILES})
endforeach()

# The packages are built after these projects, but a rebuilt project rebuilds
# only the packages that name it in DEPENDS.
set(TOOLCHAIN_PROJECTS ${projects} PARENT_SCOPE)
