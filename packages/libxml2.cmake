ExternalProject_Add(libxml2
    DEPENDS
        libiconv
    GIT_REPOSITORY https://github.com/GNOME/libxml2.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/doc/
        !/example/
        !/fuzz/
        !/python/
        !/result/
        !/test/"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBUILD_SHARED_LIBS=OFF
        -DLIBXML2_WITH_CATALOG=OFF
        -DLIBXML2_WITH_DEBUG=OFF
        -DLIBXML2_WITH_HTML=OFF
        -DLIBXML2_WITH_MODULES=OFF
        -DLIBXML2_WITH_PATTERN=OFF
        -DLIBXML2_WITH_PROGRAMS=OFF
        -DLIBXML2_WITH_READER=OFF
        -DLIBXML2_WITH_REGEXPS=OFF
        -DLIBXML2_WITH_TESTS=OFF
        -DLIBXML2_WITH_VALID=OFF
        -DLIBXML2_WITH_WRITER=OFF
        -DLIBXML2_WITH_XINCLUDE=OFF
        -DLIBXML2_WITH_XPATH=OFF
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_update_steps(libxml2)
cleanup(libxml2 install)
