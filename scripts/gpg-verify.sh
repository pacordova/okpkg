#!/bin/sh

# Verify the github tarball checksums
# The checksum should be identical to the github tarball (with `gzip -n`)
# Note: you need gzip, pigz gives a different checksum

oldpwd=`pwd`
tempdir=`mktemp -d`
curl='curl --remote-name-all'

_cksum_gh(){
   git clone --depth 1 --branch "$2" "$1"
   git -C ${1##*/} verify-tag "$2" || exit 1
   git -C ${1##*/} archive --format=tar --prefix=${1##*/}-${2#v}/ "$2" | 
      gzip -n > ${1##*/}-${2#v}.tar.gz
}

_cksum_signal(){
   $curl -s https://updates.signal.org/desktop/apt/dists/xenial/{InRelease,main/binary-amd64/Packages}
   gpg -d InRelease >/dev/null || exit 1
   awk '/[0-9a-f]{128}/&&/Packages$/{print$1,"Packages"}' InRelease | sha512sum -c || exit 1
   sed -n '31s|Filename: |https://updates.signal.org/desktop/apt/|p' Packages | $curl -# @-
   printf "%s %s" `sed -n '36s|SHA512: ||p' Packages` *.deb | sha512sum -c || exit 1
}

cd "$tempdir"

_cksum_signal
_cksum_gh https://github.com/vim/vim v9.1.1980
#_cksum_gh https://github.com/vcrhonek/hwdata v0.402
#_cksum_gh https://github.com/yshui/picom v12.5
_cksum_gh https://github.com/eggert/tz 2025c
#_cksum_gh https://github.com/pnggroup/libpng v1.6.44
#_cksum_gh https://github.com/harfbuzz/harfbuzz 9.0.0
#_cksum_gh https://github.com/fribidi/fribidi v1.0.15
#_cksum_gh https://github.com/systemd/systemd/ v256

for f in *.{tar.gz,deb}; do [ -f $f ] && okpkg sha3sum $f; done

cd "$oldpwd" && rm -fr "$tempdir"
