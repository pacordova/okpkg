#!/bin/bash

if [ ! -f /usr/bin/okpkg ]; then
    cd /usr/okpkg
    make && make install
fi

if [ -d /lost+found ]; then
    rm -r /lost+found
fi

if [ ! -d /usr/lib64/locale ]; then
    mkdir -p /usr/lib64/locale
    localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
    localedef -i en_US -f UTF-8 en_US.UTF-8
fi

if [ -x "$(command -v dbus-uuidgen)" ]; then
    dbus-uuidgen --ensure
fi

if [ -x "$(command -v passwd)" ]; then
    passwd -d root
    pwconv && grpconv
    useradd -D --gid 999
fi

if [ -x "$(command -v chattr)" ]; then
    chattr +i /etc/resolv.conf
fi

if [ ! -d /etc/default ]; then
    mkdir -p /etc/default
fi

if [ -x "$(command -v curl)" ] && [ ! -d /etc/ssl/certs ]; then
    mkdir -p /etc/ssl/certs && cd /etc/ssl/certs
    curl -Lk http://curl.se/ca/cacert.pem -o ca-certificates.crt
fi

if [ -x "$(command -v udevadm)" ]; then
    udevadm hwdb --update
fi

if [ ! -f /etc/nscd.conf ] && [ -f /usr/okpkg/sources/glibc/nscd/nscd.conf ]; then
    cp /usr/okpkg/sources/glibc/nscd/nscd.conf /etc/nscd.conf
fi

if [ ! -d /var/db ]; then
    mkdir -p /var/db
fi

if [ -x "$(command -v makewhatis)" ]; then
    makewhatis /usr/share/man
fi

# extra packages
#okpkg emerge libnl libsigsegv libusb
#okpkg emerge cmake json-c
#okpkg emerge meson ninja libfuse glib2
#okpkg emerge wpa_supplicant
#okpkg emerge iptables libmnl connman

# purge build tools
#okpkg purge cmake meson ninja
#okpkg purge bison gawk gettext gperf flex m4 pkgconf texinfo binutils
#okpkg purge gcc gcc-fortran gcc-d gm2 gcc-go gcc-ada gcc-objc
#okpkg purge python3 perl 

# Once the initial system is built:
# 1. Install adacore into /opt/gnat
# 2. Build gcc11 with ada and d support
# 3. Use gcc11 to rebuild gcc13
# 4. Split gcc13
