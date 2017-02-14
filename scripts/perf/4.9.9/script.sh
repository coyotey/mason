#!/usr/bin/env bash

MASON_NAME=perf
MASON_VERSION=4.9.9
MASON_LIB_FILE=bin/perf

. ${MASON_DIR}/mason.sh

function mason_load_source {
    # https://www.kernel.org/
    mason_download \
        https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${MASON_VERSION}.tar.xz \
        b45b464dbf36c360fbeb5d73c4648b5f14d92fc9

    mason_extract_tar_xz

    export MASON_BUILD_PATH=${MASON_ROOT}/.build/linux-${MASON_VERSION}
}

function mason_prepare_compile {
    CCACHE_VERSION=3.3.1
    ${MASON_DIR}/mason install ccache ${CCACHE_VERSION}
    MASON_CCACHE=$(${MASON_DIR}/mason prefix ccache ${CCACHE_VERSION})
    ${MASON_DIR}/mason install binutils 2.27
    MASON_BINUTILS=$(${MASON_DIR}/mason prefix binutils 2.27)
    ${MASON_DIR}/mason install bzip2 1.0.6
    MASON_BZIP2=$(${MASON_DIR}/mason prefix bzip2 1.0.6)
    ${MASON_DIR}/mason install elfutils 0.168
    MASON_ELFUTILS=$(${MASON_DIR}/mason prefix elfutils 0.168)
    EXTRA_CFLAGS="-m64 -I${MASON_BINUTILS}/include -I${MASON_BZIP2}/include -I${MASON_ELFUTILS}/include"
    EXTRA_LDFLAGS="-L${MASON_BZIP2}/lib -L${MASON_ELFUTILS}/lib -L${MASON_BINUTILS}/lib"
}

# https://perf.wiki.kernel.org/index.php/Jolsa_Howto_Install_Sources
# https://askubuntu.com/questions/50145/how-to-install-perf-monitoring-tool/306683
# https://www.spinics.net/lists/linux-perf-users/msg03040.html
# https://software.intel.com/en-us/articles/linux-perf-for-intel-vtune-Amplifier-XE
function mason_compile {
    # JOBS=${MASON_CONCURRENCY} \
    mkdir -p /tmp/build/perf
    #  -C tools/perf \
    #  O=/tmp/build/perf \
    #       FEATURES_DUMP=1 \
    # note: LIBELF is needed for symbols + node --perf_basic_prof_only_functions
    make V=1 VF=1 \
      NO_LIBNUMA=1 \
      NO_LIBAUDIT=1 \
      NOLIBBIONIC=1 \
      NO_LIBUNWIND=1 \
      NO_BACKTRACE=1 \
      NO_DWARF=1 \
      NO_LIBELF=1 \
      NO_LZMA=1 \
      NO_LIBCRYPTO=1 \
      NO_LIBPERL=1 \
      NO_SLANG=1 \
      NO_NEWT=1 \
      NO_GTK2=1 \
      LDFLAGS="${EXTRA_LDFLAGS}" \
      NO_LIBPYTHON=1 \
      WERROR=0 \
      EXTRA_CFLAGS="${EXTRA_CFLAGS}"
    make install

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
