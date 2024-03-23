#!/bin/bash

if [ ! -d /opt/gnat ]; then
    printf "error: please install adacore gnat to /opt/gnat\n"
    exit
fi

# build gcc11 with ada and d support
export PATH=/opt/gnat/bin:/usr/sbin:/usr/bin
okpkg download gcc11
okpkg build gcc11
okpkg purge gcc
bsdtar -P -C / -xf /usr/okpkg/packages/gcc11*tar.xz 2>/dev/null
rm -fr /opt

# edit gnu.db
sed -i 's/c,c++/ada,c,c++,d,fortran,go,lto,m2,objc,obj-c++/' \
    /usr/okpkg/db/gnu.db
sed -i 's/disable-bootstrap/enable-bootstrap/' \
    /usr/okpkg/db/gnu.db

# bootstrap gcc13
export PATH=/usr/sbin:/usr/bin
okpkg download gcc13
okpkg build gcc13
/usr/okpkg/scripts/split-gcc.sh
