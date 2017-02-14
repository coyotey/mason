#!/usr/bin/env bash

MASON_NAME=elfutils
MASON_VERSION=0.168
MASON_LIB_FILE=lib/libelf.a

. ${MASON_DIR}/mason.sh

function mason_load_source {
    mason_download \
        https://sourceware.org/elfutils/ftp/${MASON_VERSION}/${MASON_NAME}-${MASON_VERSION}.tar.bz2 \
        a2b4185e2fdca39a9818328017ba0192a6d5d6d4

    mason_extract_tar_bz2

    export MASON_BUILD_PATH=${MASON_ROOT}/.build/${MASON_NAME}-${MASON_VERSION}
}


function mason_compile {
    # Note CXXFLAGS overrides the harfbuzz default with is `-O2 -g`
    unset CFLAGS
    #export CFLAGS="${CFLAGS} -O3 -DNDEBUG"

    ./configure --prefix=${MASON_PREFIX} ${MASON_HOST_ARG} \
     --enable-static \
     --disable-shared \
     --disable-dependency-tracking

    make -j${MASON_CONCURRENCY} V=1
    make install  
}

function mason_cflags {
    echo "-I${MASON_PREFIX}/include"
}

function mason_ldflags {
    :
}

mason_run "$@"
