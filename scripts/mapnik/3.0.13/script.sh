#!/usr/bin/env bash

MASON_NAME=mapnik
MASON_VERSION=3.0.13
MASON_LIB_FILE=lib/libmapnik-wkt.a

. ${MASON_DIR}/mason.sh

function mason_load_source {
    mason_download \
        https://github.com/mapnik/mapnik/releases/download/v${MASON_VERSION}/mapnik-v${MASON_VERSION}.tar.bz2 \
        1e892e849cc7b81e08f3ec8c39a49e07efb4a018

    mason_extract_tar_bz2

    export MASON_BUILD_PATH=${MASON_ROOT}/.build/mapnik-v${MASON_VERSION}

    #mkdir -p $(dirname ${MASON_BUILD_PATH})
    #if [[ ! -d ${MASON_BUILD_PATH} ]]; then
    #    git clone -b 3.0.x-mason-upgrades --single-branch http://github.com/mapnik/mapnik ${MASON_BUILD_PATH}
    #    (cd ${MASON_BUILD_PATH} && git submodule update --init deps/mapbox/variant/)
    #fi
}

function install() {
    MASON_PLATFORM_ID=$(${MASON_DIR}/mason env MASON_PLATFORM_ID)
    if [[ ! -d ${MASON_ROOT}/${MASON_PLATFORM_ID}/${1}/${2} ]]; then
        ${MASON_DIR}/mason install $1 $2
        if [[ ${3:-false} != false ]]; then
            LA_FILE=$(${MASON_DIR}/mason prefix $1 $2)/lib/$3.la
            if [[ -f ${LA_FILE} ]]; then
                perl -i -p -e 's:\Q$ENV{HOME}/build/mapbox/mason\E:$ENV{PWD}:g' ${LA_FILE}
            else
                echo "$LA_FILE not found"
            fi
        fi
    fi
    ${MASON_DIR}/mason link $1 $2
}

ICU_VERSION="55.1"

function mason_prepare_compile {
    install clang++ 3.9.1
    install ccache 3.3.1
    install jpeg_turbo 1.5.1 libjpeg
    install libpng 1.6.28 libpng
    install libtiff 4.0.7 libtiff
    install libpq 9.6.1
    install sqlite 3.16.2 libsqlite3
    install expat 2.2.0 libexpat
    install icu ${ICU_VERSION}
    install proj 4.9.3 libproj
    install pixman 0.34.0 libpixman-1
    install cairo 1.14.8 libcairo
    install webp 0.6.0 libwebp
    install libgdal 2.1.3
    install boost 1.63.0
    install boost_libsystem 1.63.0
    install boost_libfilesystem 1.63.0
    install boost_libprogram_options 1.63.0
    install boost_libregex_icu 1.63.0
    install freetype 2.7.1 libfreetype
    install harfbuzz 1.4.2-ft libharfbuzz
}

function mason_compile {
    MASON_LINKED_REL="${MASON_ROOT}/.link"
    MASON_LINKED_ABS="${MASON_ROOT}/.link"
    ls ${MASON_LINKED_ABS}
    ls ${MASON_LINKED_ABS}/bin/
    ls ${MASON_LINKED_ABS}/include/
    if [[ $(uname -s) == 'Linux' ]]; then
        echo "CUSTOM_LDFLAGS = '-Wl,-z,origin -Wl,-rpath=\\\$\$ORIGIN/../lib/ -Wl,-rpath=\\\$\$ORIGIN/../../'" > config.py
        echo "CUSTOM_CXXFLAG = '-D_GLIBCXX_USE_CXX11_ABI=0'" >> config.py
    fi
    ./configure \
        CXX="${MASON_LINKED_REL}/bin/ccache ${MASON_LINKED_REL}/bin/clang++" \
        CC="${MASON_LINKED_REL}/bin/ccache ${MASON_LINKED_REL}/bin/clang" \
        PREFIX=${MASON_PREFIX} \
        PATH_REPLACE="${HOME}/build/mapbox/mason/mason_packages:./mason_packages" \
        MAPNIK_BUNDLED_SHARE_DIRECTORY=True \
        RUNTIME_LINK="static" \
        INPUT_PLUGINS="all" \
        PATH="${MASON_LINKED_REL}/bin" \
        PKG_CONFIG_PATH="${MASON_LINKED_REL}/lib/pkgconfig" \
        PATH_REMOVE="/usr:/usr/local" \
        BOOST_INCLUDES="${MASON_LINKED_REL}/include" \
        BOOST_LIBS="${MASON_LINKED_REL}/lib" \
        ICU_INCLUDES="${MASON_LINKED_REL}/include" \
        ICU_LIBS="${MASON_LINKED_REL}/lib" \
        HB_INCLUDES="${MASON_LINKED_REL}/include" \
        HB_LIBS="${MASON_LINKED_REL}/lib" \
        PNG_INCLUDES="${MASON_LINKED_REL}/include/libpng16" \
        PNG_LIBS="${MASON_LINKED_REL}/lib" \
        JPEG_INCLUDES="${MASON_LINKED_REL}/include" \
        JPEG_LIBS="${MASON_LINKED_REL}/lib" \
        TIFF_INCLUDES="${MASON_LINKED_REL}/include" \
        TIFF_LIBS="${MASON_LINKED_REL}/lib" \
        WEBP_INCLUDES="${MASON_LINKED_REL}/include" \
        WEBP_LIBS="${MASON_LINKED_REL}/lib" \
        PROJ_INCLUDES="${MASON_LINKED_REL}/include" \
        PROJ_LIBS="${MASON_LINKED_REL}/lib" \
        PG_INCLUDES="${MASON_LINKED_REL}/include" \
        PG_LIBS="${MASON_LINKED_REL}/lib" \
        FREETYPE_INCLUDES="${MASON_LINKED_REL}/include/freetype2" \
        FREETYPE_LIBS="${MASON_LINKED_REL}/lib" \
        SVG_RENDERER = True \
        CAIRO_INCLUDES="${MASON_LINKED_REL}/include" \
        CAIRO_LIBS="${MASON_LINKED_REL}/lib" \
        SQLITE_INCLUDES="${MASON_LINKED_REL}/include" \
        SQLITE_LIBS="${MASON_LINKED_REL}/lib" \
        BENCHMARK = True \
        CPP_TESTS = True \
        PGSQL2SQLITE = True \
        XMLPARSER="ptree" \
        SVG2PNG = True || cat ${MASON_BUILD_PATH}"/config.log"
    #cat config.py
    JOBS=${MASON_CONCURRENCY} make
    make install
    if [[ $(uname -s) == 'Darwin' ]]; then
        install_name_tool -id @loader_path/libmapnik.dylib ${MASON_PREFIX}"/lib/libmapnik.dylib";
        PLUGINDIRS=${MASON_PREFIX}"/lib/mapnik/input/*.input";
        for f in $PLUGINDIRS; do
            echo $f;
            echo `basename $f`;
            install_name_tool -id plugins/input/`basename $f` $f;
            install_name_tool -change ${MASON_PREFIX}"/lib/libmapnik.dylib" @loader_path/../../libmapnik.dylib $f;
        done;
        # command line tools
        install_name_tool -change ${MASON_PREFIX}"/lib/libmapnik.dylib" @loader_path/../lib/libmapnik.dylib ${MASON_PREFIX}"/bin/mapnik-index"
        install_name_tool -change ${MASON_PREFIX}"/lib/libmapnik.dylib" @loader_path/../lib/libmapnik.dylib ${MASON_PREFIX}"/bin/mapnik-render"
        install_name_tool -change ${MASON_PREFIX}"/lib/libmapnik.dylib" @loader_path/../lib/libmapnik.dylib ${MASON_PREFIX}"/bin/shapeindex"
    fi
    # push over GDAL_DATA, ICU_DATA, PROJ_LIB
    # fix mapnik-config entries for deps
    HERE=$(pwd)
    python -c "data=open('$MASON_PREFIX/bin/mapnik-config','r').read();open('$MASON_PREFIX/bin/mapnik-config','w').write(data.replace('$HERE','.').replace('${MASON_ROOT}','./mason_packages'))"
    cat $MASON_PREFIX/bin/mapnik-config
    mkdir -p ${MASON_PREFIX}/share/gdal
    mkdir -p ${MASON_PREFIX}/share/proj
    mkdir -p ${MASON_PREFIX}/share/icu
    PROJ_LIB=${MASON_LINKED_ABS}/share/proj
    export ICU_DATA=${MASON_LINKED_ABS}/share/icu/${ICU_VERSION}
    export GDAL_DATA=${MASON_LINKED_ABS}/share/gdal
    cp -r ${GDAL_DATA}/ ${MASON_PREFIX}/share/gdal/
    cp -r ${PROJ_LIB}/ ${MASON_PREFIX}/share/proj/
    cp -r ${ICU_DATA}/*dat ${MASON_PREFIX}/share/icu/
}

function mason_cflags {
    ${MASON_PREFIX}/bin/mapnik-config --cflags
}

function mason_ldflags {
    ${MASON_PREFIX}/bin/mapnik-config --ldflags
}

function mason_static_libs {
    ${MASON_PREFIX}/bin/mapnik-config --dep-libs
}

function mason_clean {
    make clean
}

mason_run "$@"
