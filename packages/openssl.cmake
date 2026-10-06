# Built inside the source tree: since commit 8c547ec7e1, Configure with no-apps
# fails in a separate build directory, which lacks apps/include.
ExternalProject_Add(openssl
    DEPENDS
        brotli
        zlib-ng
        zstd
    GIT_REPOSITORY https://github.com/openssl/openssl.git
    GIT_TAG master
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone
        /*
        !/VMS/
        !/demos/
        !/dev/
        !/os-dep/
        !/test/"
    GIT_SUBMODULES ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${SOURCE_LOCATION}
    CONFIGURE_COMMAND ${EXEC} <SOURCE_DIR>/Configure
        --cross-compile-prefix=${TARGET_TRIPLE}-
        --prefix=${SYSROOT_DIR}
        --libdir=lib
        -flto=${LTO_MODE}
        CC=clang
        mingw64
        enable-brotli
        enable-ec_nistp_64_gcc_128
        enable-zlib
        enable-zstd
        no-apps
        no-aria
        no-ascon128
        no-async
        no-autoload-config
        no-bf
        no-blake2
        no-camellia
        no-cast
        no-cmac
        no-cmp
        no-cms
        no-ct
        no-dh
        no-docs
        no-dsa
        no-dso
        no-ec2m
        no-err
        no-filenames
        no-gost
        no-hmac-drbg-kdf
        no-http
        no-idea
        no-ikev2kdf
        no-integrity-only-ciphers
        no-kbkdf
        no-krb5kdf
        no-legacy
        no-md4
        no-mdc2
        no-multiblock
        no-nextprotoneg
        no-ocb
        no-psk
        no-quic
        no-rc2
        no-rc4
        no-rfc3779
        no-rmd160
        no-scrypt
        no-seed
        no-shared
        no-siphash
        no-sm3
        no-sm4
        no-snmpkdf
        no-srp
        no-srtpkdf
        no-sshkdf
        no-sskdf
        no-ssl-trace
        no-thread-pool
        no-tls1-method
        no-tls1_1-method
        no-ts
        no-whirlpool
        no-winstore
        no-x942kdf
        no-x963kdf
    BUILD_COMMAND ${MAKE} build_sw
    BUILD_IN_SOURCE 1
    INSTALL_COMMAND ${MAKE} install_sw
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    LOG_MERGED_STDOUTERR 1 LOG_OUTPUT_ON_FAILURE 1
)

force_rebuild_git(openssl)
cleanup(openssl install)
