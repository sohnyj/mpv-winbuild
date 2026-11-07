# A host tool that generates the C++/WinRT headers from the Windows metadata
# into the sysroot, where mpv's win32-smtc includes them.
ExternalProject_Add(cppwinrt
    DEPENDS
        windows-rs
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_DIR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_CXX_COMPILER=${HOST_CXX_COMPILER}
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND <INSTALL_DIR>/bin/cppwinrt -input ${WINDOWS_RS_SOURCE_DIR}/crates/libs/default -output ${SYSROOT_DIR}/include
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_steps(cppwinrt
    REPOSITORY https://github.com/microsoft/cppwinrt.git
    TAG master
    CLONE_FLAGS "--sparse --filter=tree:0"
    CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/docs/
        !/natvis/
        !/nuget/
        !/test/
        !/vsix/"
)
add_cleanup_steps(cppwinrt install)
