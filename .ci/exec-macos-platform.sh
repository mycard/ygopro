#!/bin/bash
set -x
set -o errexit

TARGET_PLATFORM=$(arch)
TARGET_YGOPRO_BINARY_PATH=./ygopro-platforms/ygopro-platform-$TARGET_PLATFORM
export EVENT_INCLUDE_DIR=$PWD/libevent-stable/include
export EVENT_LIB_DIR=$PWD/libevent-stable/lib
export OPUS_INCLUDE_DIR=$PWD/miniaudio/external-built/include/opus
export OPUS_LIB_DIR=$PWD/miniaudio/external-built/lib
export OPUSFILE_INCLUDE_DIR=$PWD/miniaudio/external-built/include/opus
export OPUSFILE_LIB_DIR=$PWD/miniaudio/external-built/lib
export VORBIS_INCLUDE_DIR=$PWD/miniaudio/external-built/include
export VORBIS_LIB_DIR=$PWD/miniaudio/external-built/lib
export OGG_INCLUDE_DIR=$PWD/miniaudio/external-built/include
export OGG_LIB_DIR=$PWD/miniaudio/external-built/lib

./.ci/libevent-prebuild.sh
./.ci/build-opus.sh

./premake5 gmake --cc=clang --build-freetype --build-sqlite

cd build
make config=release -j$(nproc)
cd ..

mkdir ygopro-platforms
mv bin/release/YGOPro.app $TARGET_YGOPRO_BINARY_PATH

#if [[ $TARGET_PLATFORM == "x86" ]]; then
#  install_name_tool -change /usr/local/lib/libirrklang.dylib @executable_path/../Frameworks/libirrklang.dylib $TARGET_YGOPRO_BINARY_PATH
#fi

strip $TARGET_YGOPRO_BINARY_PATH
