#!/bin/bash
set -x
set -o errexit

source .ci/prepare-repo
prepare_repo "https://code.moenext.com/mycard/miniaudio.git" "miniaudio"

cp -rf miniaudio/extras/miniaudio_split/miniaudio.* miniaudio/

mkdir -p miniaudio/external

install_external() {
  dir="$1"
  url="$2"
  if [ ! -d "miniaudio/external/$dir" ]; then
    mkdir -p "miniaudio/external/$dir"
    # Download the external library and strip one level of directories from the archive
    wget -O - "$url" | tar --strip-components=1 -C "miniaudio/external/$dir" -zxf -
  fi
}

install_external "ogg" "https://mat-cacher.moenext.com/https://github.com/xiph/ogg/releases/download/v1.3.5/libogg-1.3.5.tar.gz"
install_external "opus" "https://mat-cacher.moenext.com/https://github.com/xiph/opus/releases/download/v1.5.2/opus-1.5.2.tar.gz"
install_external "opusfile" "https://mat-cacher.moenext.com/https://github.com/xiph/opusfile/releases/download/v0.12/opusfile-0.12.tar.gz"
install_external "vorbis" "https://mat-cacher.moenext.com/https://github.com/xiph/vorbis/releases/download/v1.3.7/libvorbis-1.3.7.tar.gz"
