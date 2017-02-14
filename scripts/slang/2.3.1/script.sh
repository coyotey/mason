#!/usr/bin/env bash

MASON_NAME=slang
MASON_VERSION=2.3.1
MASON_LIB_FILE=lib/libslang.a

. ${MASON_DIR}/mason.sh

function mason_load_source {
    # https://www.kernel.org/
    mason_download \
        http://www.jedsoft.org/releases/slang/slang-${MASON_VERSION}.tar.bz2 \
        8617d4745d1be3e086adb2fb8ca349a64711afc7

    mason_extract_tar_bz2

    export MASON_BUILD_PATH=${MASON_ROOT}/.build/slang-${MASON_VERSION}
}

function mason_compile {
  unset CFLAGS
  unset LDFLAGS
    ./configure --prefix=${MASON_PREFIX} ${MASON_HOST_ARG} \
     --enable-static \
     --disable-shared \
     --disable-dependency-tracking

    make V=1 install-static
}

function mason_cflags {
    :
}

function mason_ldflags {
    :
}

function mason_static_libs {
    :
}

mason_run "$@"
