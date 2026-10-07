ExternalProject_Add(libplacebo
    DEPENDS
        fast_float
        lcms2
        shaderc
        spirv-cross
        vulkan-loader
        xxhash
    GIT_REPOSITORY https://github.com/haasn/libplacebo.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--filter=tree:0"
    GIT_SUBMODULES
        3rdparty/jinja
        3rdparty/markupsafe
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ${MESON_EXECUTABLE} setup --reconfigure <BINARY_DIR> <SOURCE_DIR>
        --buildtype=release
        --cross-file=${MESON_CROSS}
        --native-file=${MESON_NATIVE}
        --default-library=static
        --prefix=${SYSROOT_DIR}
        --wrap-mode=nofallback
        -Db_lto=true
        -Db_lto_mode=${LTO_MODE}
        -Db_ndebug=true
        -Dd3d11=enabled
        -Ddemos=false
        -Ddovi=enabled
        -Dgl-proc-addr=disabled
        -Dglslang=disabled
        -Dlcms=enabled
        -Dlibdovi=disabled
        -Dopengl=disabled
        -Dshaderc=enabled
        -Dunwind=disabled
        -Dvk-proc-addr=enabled
        -Dvulkan=enabled
        -Dxxhash=enabled
    BUILD_COMMAND ${MESON_EXECUTABLE} compile -C <BINARY_DIR>
    INSTALL_COMMAND ${MESON_EXECUTABLE} install -C <BINARY_DIR>
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(libplacebo)
cleanup(libplacebo install)
