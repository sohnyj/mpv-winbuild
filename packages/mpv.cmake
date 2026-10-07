ExternalProject_Add(mpv
    DEPENDS
        amf-headers
        cppwinrt
        curl
        ffmpeg
        lcms2
        libarchive
        libass
        libbluray
        libiconv
        libjpeg-turbo
        libplacebo
        libzimg
        luajit
        nv-codec-headers
        shaderc
        spirv-cross
        subrandr
        uchardet
        vulkan-loader
        zlib-ng
    GIT_REPOSITORY https://github.com/mpv-player/mpv.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/fuzzers
        !/test"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ${MESON_EXECUTABLE} setup --reconfigure <BINARY_DIR> <SOURCE_DIR>
        --buildtype=release
        --cross-file=${MESON_CROSS}
        --native-file=${MESON_NATIVE}
        --prefer-static
        --prefix=${SYSROOT_DIR}
        --wrap-mode=nofallback
        -Db_lto=true
        -Db_lto_mode=${LTO_MODE}
        -Db_ndebug=true
        -Damf=enabled
        -Dcdda=disabled
        -Dcplugins=disabled
        -Dcuda-hwaccel=enabled
        -Dcuda-interop=enabled
        -Dd3d-hwaccel=enabled
        -Dd3d11=enabled
        -Dd3d9-hwaccel=disabled
        -Ddirect3d=disabled
        -Ddvdnav=disabled
        -Dgl=disabled
        -Diconv=enabled
        -Djavascript=disabled
        -Djpeg=enabled
        -Dlcms2=enabled
        -Dlibarchive=enabled
        -Dlibavdevice=enabled
        -Dlibbluray=enabled
        -Dlibcurl=enabled
        -Dlibmpv=false
        -Dlua=luajit
        -Dmanpage-build=disabled
        -Drubberband=disabled
        -Dshaderc=enabled
        -Dspirv-cross=enabled
        -Dsubrandr=enabled
        -Duchardet=enabled
        -Dvapoursynth=disabled
        -Dvector=enabled
        -Dvulkan=enabled
        -Dwasapi=enabled
        -Dwin32-smtc=enabled
        -Dwin32-threads=enabled
        -Dzimg=enabled
        -Dzlib=enabled
    BUILD_COMMAND ${MESON_EXECUTABLE} compile -C <BINARY_DIR>
    INSTALL_COMMAND ${MESON_EXECUTABLE} install -C <BINARY_DIR> --no-rebuild --tags runtime
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

add_git_update_steps(mpv)
cleanup(mpv install)
