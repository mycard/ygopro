#!/bin/bash
set -x
set -o errexit

MINIAUDIO_REPO="https://github.com/mackron/miniaudio"
MINIAUDIO_REF="0.11.25"

if [ ! -d "miniaudio/.git" ]; then
  rm -rf miniaudio
  git clone --depth=1 -b "$MINIAUDIO_REF" "$MINIAUDIO_REPO" miniaudio
else
  git -C miniaudio remote set-url origin "$MINIAUDIO_REPO"
  git -C miniaudio fetch --depth=1 origin "refs/tags/$MINIAUDIO_REF"
  git -C miniaudio checkout -f FETCH_HEAD
fi

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

install_external "ogg" "https://mat-cacher.moenext.com/https://github.com/xiph/ogg/releases/download/v1.3.6/libogg-1.3.6.tar.gz?sha256sum=83e6704730683d004d20e21b8f7f55dcb3383cdf84c0daedf30bde175f774638"
install_external "opus" "https://mat-cacher.moenext.com/https://github.com/xiph/opus/releases/download/v1.5.2/opus-1.5.2.tar.gz?sha256sum=65c1d2f78b9f2fb20082c38cbe47c951ad5839345876e46941612ee87f9a7ce1"
install_external "opusfile" "https://mat-cacher.moenext.com/https://github.com/xiph/opusfile/releases/download/v0.12/opusfile-0.12.tar.gz?sha256sum=118d8601c12dd6a44f52423e68ca9083cc9f2bfe72da7a8c1acb22a80ae3550b"
install_external "vorbis" "https://mat-cacher.moenext.com/https://github.com/xiph/vorbis/releases/download/v1.3.7/libvorbis-1.3.7.tar.gz?sha256sum=0e982409a9c3fc82ee06e08205b1355e5c6aa4c36bca58146ef399621b0ce5ab"
