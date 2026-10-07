# LuaJIT builds only inside its source tree. The install step removes the
# Libs.private line of luajit.pc, whose Unix linker flags (-Wl,-E -lm -ldl)
# MinGW lacks. CCOPT and XCFLAGS also apply to the build tools, so ThinLTO goes
# into TARGET_CFLAGS.
set(luajit_make_variables
    CROSS=${TARGET_TRIPLE}-
    CC=clang
    HOST_CC=${HOST_C_COMPILER}
    TARGET_SYS=Windows
    BUILDMODE=static
    "CCOPT=-O3 -fomit-frame-pointer"
    TARGET_CFLAGS=-flto=${LTO_MODE}
    "XCFLAGS=-DLUAJIT_ENABLE_LUA52COMPAT -DNDEBUG"
    PREFIX=${SYSROOT_DIR}
    FILE_T=luajit.exe
    INSTALL_DEP=src/luajit.exe
)

ExternalProject_Add(luajit
    GIT_REPOSITORY https://github.com/LuaJIT/LuaJIT.git
    GIT_TAG v2.1
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/doc/"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${MAKE} -C <SOURCE_DIR>/src ${luajit_make_variables} amalg
    BUILD_IN_SOURCE 1
    INSTALL_COMMAND ${MAKE} ${luajit_make_variables} install
        COMMAND sed -i "/^Libs.private/d" ${SYSROOT_DIR}/lib/pkgconfig/luajit.pc
    LOG_DOWNLOAD 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_update_steps(luajit)
cleanup(luajit install)
