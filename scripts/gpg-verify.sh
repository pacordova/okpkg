#!/bin/sh

# Verify the github tarball checksums
# The checksum should be identical to the github tarball (with `gzip -n`)
# Note: you need gzip, pigz gives a different checksum
# If you want to compare to Arch Linux checksums do:
# git -c core.abbrev=no archive --format=tar "$TAG" | sha256sum

oldpwd=`pwd`
tempdir=`mktemp -d`
curl='/bin/curl -fsSL --remote-name-all'

_cksum_gh(){
  git clone --depth 1 --branch "$2" "$1"
  git -C ${1##*/} verify-tag "$2" || exit 1
  git -C ${1##*/} archive --format=tar --prefix=${1##*/}-${2#v}/ "$2" \
  | gzip -n > ${1##*/}-${2#v}.tar.gz
}

_cksum_gl(){
  git clone --depth 1 --branch "$2" "$1"
  git -C ${1##*/} verify-tag "$2" || exit 1
  git -C ${1##*/} archive --format=tar --prefix=${1##*/}-${2}-$(git -C ${1##*/} rev-parse HEAD)/ "$2" \
  | gzip -n > ${1##*/}-${2}.tar.gz
  cp -f ${1##*/}-${2}.tar.gz /tmp
}

_cksum_signal(){
  $curl https://updates.signal.org/desktop/apt/dists/xenial/{InRelease,main/binary-amd64/Packages}
  gpg -d InRelease >/dev/null || exit 1
  awk '/[0-9a-f]{128}/&&/Packages$/{print$1,"Packages"}' InRelease | sha512sum -c || exit 1
  curl -LRO https://updates.signal.org/desktop/apt/pool/s/signal-desktop/signal-desktop_$1_amd64.deb
  grep -e 'Filename:' -e 'SHA512' Packages \
  | paste - - \
  | awk 'gsub(/.*\//, "", $2){ print $4,$2 }' \
  | grep signal-desktop_$1_amd64.deb \
  | sha512sum -c || exit 1
}

_cksum_kernel(){
  $curl https://cdn.kernel.org/pub/linux/kernel/v${1%%.*}.x/linux-$1.tar.{xz,sign}
  xz -d linux-$1.tar.xz
  gpg --verify linux-$1.tar.sign linux-$1.tar || exit 1
  xz --lzma2=preset=9e,dict=8MiB linux-$1.tar
}

cd "$tempdir"

_cksum_kernel 6.12.103
#_cksum_signal 8.23.0
#_cksum_gl https://gitlab.com/lvmteam/lvm2 v2_03_41
#_cksum_gh https://github.com/vim/vim v9.1.1980
#_cksum_gh https://github.com/vcrhonek/hwdata v0.406
#_cksum_gh https://github.com/yshui/picom v13
#_cksum_gh https://github.com/eggert/tz 2026c
#_cksum_gh https://github.com/pnggroup/libpng v1.6.44
#_cksum_gh https://github.com/harfbuzz/harfbuzz 9.0.0
#_cksum_gh https://github.com/fribidi/fribidi v1.0.15
#_cksum_gh https://github.com/systemd/systemd/ v256

for f in *.{tar.xz,tar.gz,deb}; do [ -f $f ] && okpkg b3sum $f; done

cd "$oldpwd" && rm -fr "$tempdir"
