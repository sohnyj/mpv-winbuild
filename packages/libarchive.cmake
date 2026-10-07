# mpv reads 7zip, ISO 9660, RAR, RAR5 and zip archives, alone or inside
# bzip2, gzip and xz streams, and never sets a passphrase. Only the libraries
# those formats decompress with are enabled, and every library libarchive
# would otherwise pick up when found is turned on or off explicitly.
ExternalProject_Add(libarchive
    DEPENDS
        bzip2
        libiconv
        xz
        zlib-ng
        zstd
    GIT_REPOSITORY https://github.com/libarchive/libarchive.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/contrib/
        !/doc/
        !/examples/
        !/test_utils/"
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR}
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DBUILD_SHARED_LIBS=OFF
        -DENABLE_BZip2=ON
        -DENABLE_CAT=OFF
        -DENABLE_CNG=OFF
        -DENABLE_CPIO=OFF
        -DENABLE_EXPAT=OFF
        -DENABLE_ICONV=ON
        -DENABLE_LIBB2=OFF
        -DENABLE_LIBXML2=OFF
        -DENABLE_LZ4=OFF
        -DENABLE_LZMA=ON
        -DENABLE_MD=OFF
        -DENABLE_OPENSSL=OFF
        -DENABLE_PCRE2POSIX=OFF
        -DENABLE_PCREPOSIX=OFF
        -DENABLE_TAR=OFF
        -DENABLE_TEST=OFF
        -DENABLE_UNZIP=OFF
        -DENABLE_WIN32_XMLLITE=OFF
        -DENABLE_ZLIB=ON
        -DENABLE_ZSTD=ON
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(libarchive)
cleanup(libarchive install)
