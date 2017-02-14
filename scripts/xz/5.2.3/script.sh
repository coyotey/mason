#!/usr/bin/env bash

MASON_NAME=xz
MASON_VERSION=5.2.3
MASON_LIB_FILE=lib/liblzma.a

. ${MASON_DIR}/mason.sh

function mason_load_source {
    mason_download \
        http://tukaani.org/xz/xz-${MASON_VERSION}.tar.gz \
        147ce202755a3d846dc17479999671c7cadf0c2f

    mason_extract_tar_gz

    export MASON_BUILD_PATH=${MASON_ROOT}/.build/xz-${MASON_VERSION}
}

function mason_compile {
    unset CFLAGS
    #export CFLAGS="${CFLAGS:-} ${MASON_ZLIB_CFLAGS} -O3 -DNDEBUG"
    #export LDFLAGS="${CFLAGS:-} ${MASON_ZLIB_LDFLAGS}"

    ./configure \
        --prefix=${MASON_PREFIX} \
        ${MASON_HOST_ARG} \
        --enable-static \
        --with-pic \
        --disable-shared \
        --disable-dependency-tracking

    V=1 VERBOSE=1 make install -j${MASON_CONCURRENCY}
}

function mason_strip_ldflags {
    shift # -L...
    shift # -lpng16
    echo "$@"
}

function mason_ldflags {
    mason_strip_ldflags $(`mason_pkgconfig` --static --libs)
}

function mason_clean {
    make clean
}

mason_run "$@"
