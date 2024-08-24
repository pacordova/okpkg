#!/bin/sh

if [ ! -d /opt/gnat ]; then
    printf "error: please install adacore gnat to /opt/gnat\n"
    exit
fi

# build gcc11 with ada and d support
export PATH=/opt/gnat/bin:/usr/bin:/usr/sbin
okpkg download gcc11
okpkg build gcc11
okpkg purge gcc
tar -C / -xhf /usr/okpkg/packages/gcc11*tar.lz 2>/dev/null
rm -fr /opt

# edit gnu.db
sed -i 's/c,c++/ada,c,c++,d,fortran,go,lto,m2,objc,obj-c++/' \
    /usr/okpkg/db/system.db

# bootstrap gcc14
export PATH=/usr/bin:/usr/sbin
okpkg download gcc14
okpkg build gcc14
/usr/okpkg/scripts/split-gcc.sh
