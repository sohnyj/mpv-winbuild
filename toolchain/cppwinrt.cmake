# A host tool that generates the C++/WinRT headers from the Windows metadata
# into the sysroot, where mpv's win32-smtc includes them.
ExternalProject_Add(cppwinrt
    DEPENDS
        windows-rs
    GIT_REPOSITORY https://github.com/microsoft/cppwinrt.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !/docs !/test"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND <INSTALL_DIR>/bin/cppwinrt -input ${WINDOWS_RS_SOURCE_DIR}/${WINDOWS_WINMD} -output ${SYSROOT_DIR}/include
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(cppwinrt)
cleanup(cppwinrt install)
