#!/bin/bash
set -x
set -o errexit
# PROCESSOR_COUNT=4

wget -O - https://cdn02.moecube.com:444/ygopro-build-materials/libevent-2.1.12-stable.tar.gz | tar zfx -
cd libevent-2.1.12-stable
./configure --prefix=$PWD/libevent-stable --disable-openssl --enable-static=yes --enable-shared=no
make -j$PROCESSOR_COUNT
make install
cd ..
mv libevent-2.1.12-stable/libevent-stable .
rm -rf libevent-2.1.12-stable
