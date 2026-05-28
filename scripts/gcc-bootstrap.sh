#!/bin/sh

PKGDIR=/var/cache/packages
DBPATH=/usr/okpkg/db

if [ ! -d /opt/gnat ]; then
    printf "error: please install adacore gnat to /opt/gnat\n"
    exit
fi

# build gcc11 with ada and d support
export PATH=/opt/gnat/bin:/bin
okpkg download gcc11
okpkg build gcc11
okpkg purge gcc
tar -C / -xhf "$PKGDIR/gcc11"*tar.lz 2>/dev/null
rm -fr /opt

# edit db/sys
sed -e 's/c,c++/ada,c,c++,d,fortran,go,lto,m2,objc,obj-c++/' \
    -i "$DBPATH/sys"

# bootstrap gcc14
export PATH=/bin
okpkg download gcc14
okpkg build gcc14
./split-gcc.sh
