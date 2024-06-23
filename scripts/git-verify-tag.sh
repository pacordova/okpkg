#!/bin/bash

# verify the vim and tz checksum
# should be identical to the github tarball: note the `-n' gzip flag
# the `-6' flag is used for compatibility with pigz which uses `-9' by default

# tempdir
tempdir=$(mktemp -d) && pushd $tempdir >/dev/null


# import gnupg keys
validpgpkeys=('4F19708816918E19AAE19DEEF3F92DA383FDDE09'  # Christian Brabandt <cb@256bit.org>
              '7E3792A9D8ACF7D633BC1588ED97E90E62AA7E34') # Paul Eggert <eggert@cs.ucla.edu>
for k in ${validpgpkeys[@]}; do gpg --keyserver hkp://keyserver.ubuntu.com/ --recv-keys $k; done

ckone(){
    v=$(echo "$2" | sed 's/^v//')
    git clone --depth 1 --branch "$2" "$1"
    git -C `basename $1` verify-tag "$2" || exit 1
    git -C `basename $1` archive --format=tar --prefix=`basename $1`-$v/ "$2" |
        gzip -n -6 > `basename $1`-$v.tar.gz
}

ckone https://github.com/vim/vim/ v9.1.0496
ckone https://github.com/eggert/tz/ 2024a
#ckone https://github.com/systemd/systemd/ v256

# print sums
sha3-256sum *.tar.gz

# cleanup
popd >/dev/null && rm -fr $tempdir
