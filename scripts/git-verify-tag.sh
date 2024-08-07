#!/bin/bash

# verify the vim and tz checksum
# should be identical to the github tarball: note the `-n' gzip flag

# tempdir
tempdir=$(mktemp -d) && pushd $tempdir >/dev/null


# import gnupg keys
validpgpkeys=(
   '4F19708816918E19AAE19DEEF3F92DA383FDDE09' # Christian Brabandt <cb@256bit.org>
   '7E3792A9D8ACF7D633BC1588ED97E90E62AA7E34' # Paul Eggert <eggert@cs.ucla.edu>
   '0AD041B27CA166DDA1FE3BAEA7B3409C0CA4ED14' # Dov Grobgeld <dov.grobgeld@gmail.com>
   '053D20F17CCCA9651B2C6FCB9AB24930C0B997A2' # Khaled Hosny <khaled@aliftype.com> (@khaledhosny)
)
for k in ${validpgpkeys[@]}; do gpg --keyserver hkp://keyserver.ubuntu.com/ --recv-keys $k; done

ckone(){
    v=$(echo "$2" | sed 's/^v//')
    git clone --depth 1 --branch "$2" "$1"
    git -C `basename $1` verify-tag "$2" || exit 1
    git -C `basename $1` archive --format=tar --prefix=`basename $1`-$v/ "$2" |
        gzip -n > `basename $1`-$v.tar.gz
}

ckone https://github.com/vim/vim/ v9.1.0648
#ckone https://github.com/eggert/tz/ 2024a
#ckone https://github.com/harfbuzz/harfbuzz 9.0.0
#ckone https://github.com/fribidi/fribidi v1.0.15
#ckone https://github.com/systemd/systemd/ v256

# print sums
okpkg sha3sum *.tar.gz

# cleanup
popd >/dev/null && rm -fr $tempdir
