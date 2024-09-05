#!/bin/sh

cd /usr/okpkg/packages

target=`gcc -dumpmachine`
version=`gcc -dumpversion`
pkgname=$(printf "gcc%s" $version | cut -d . -f 1)
timestamp=$(stat -c %Y "$pkgname"*.tar.lz)

mkdir gcc
tar -C gcc -xf "$pkgname"*.tar.lz

# gm2 first (includes solibs)
if [ -f gcc/usr/bin/gm2 ]; then
    mkdir -p "gcc-gm2/usr/lib64/gcc/$target/$version/plugin/"
    mkdir -p  gcc-gm2/usr/share/man/man1
    mkdir -p  gcc-gm2/usr/bin

    mv "gcc/usr/lib64/gcc/$target/$version/plugin/m2rte.so" \
       "gcc-gm2/usr/lib64/gcc/$target/$version/plugin/m2rte.so"
    mv "gcc/usr/lib64/gcc/$target/$version/cc1gm2" \
       "gcc-gm2/usr/lib64/gcc/$target/$version/"
    mv "gcc/usr/lib64/gcc/$target/$version/m2/" \
       "gcc-gm2/usr/lib64/gcc/$target/$version/"
    mv "gcc/usr/bin/$target-gm2" gcc-gm2/usr/bin
    mv  gcc/usr/share/man/man1/gm2.1 gcc-gm2/usr/share/man/man1
    mv gcc/usr/lib64/libm2* gcc-gm2/usr/lib64
    mv gcc/usr/bin/gm2 gcc-gm2/usr/bin
    find gcc-gm2 -newermt "@$timestamp" -exec touch -hd "@$timestamp" '{}' +
    mv gcc-gm2 "gcc-gm2-$version-amd64"
    okpkg makepkg "gcc-gm2-$version-amd64"
    okpkg install "gcc-gm2-$version-amd64.tar.lz"
fi

# gcc-libs
mkdir -p gcc-libs/usr/lib64
mv gcc/usr/lib64/*.so* gcc-libs/usr/lib64
find gcc-libs -newermt "@$timestamp" -exec touch -hd "@$timestamp" '{}' +
mv gcc-libs "gcc-libs-$version-amd64"
okpkg makepkg "gcc-libs-$version-amd64"
okpkg install "gcc-libs-$version-amd64.tar.lz"

# gnat
if [ -f gcc/usr/bin/gnat ]; then
    mkdir -p "gcc-ada/usr/lib64/gcc/$target/$version"
    mkdir -p  gcc-ada/usr/bin

    mv gcc/usr/bin/gnat* gcc-ada/usr/bin
    mv "gcc/usr/lib64/gcc/$target/$version/ada"* \
       "gcc-ada/usr/lib64/gcc/$target/$version/"
    mv "gcc/usr/lib64/gcc/$target/$version/gnat1" \
       "gcc-ada/usr/lib64/gcc/$target/$version/"
    find gcc-ada -newermt "@$timestamp" -exec touch -hd "@$timestamp" '{}' +
    mv gcc-ada "gcc-ada-$version-amd64"
    okpkg makepkg "gcc-ada-$version-amd64"
    okpkg install "gcc-ada-$version-amd64.tar.lz"
fi

# gdc
if [ -f gcc/usr/bin/gdc ]; then
    mkdir -p "gcc-d/usr/lib64/gcc/$target/$version/include"
    mkdir -p  gcc-d/usr/share/man/man1
    mkdir -p  gcc-d/usr/bin

    mv "gcc/usr/lib64/gcc/$target/$version/include/d" \
       "gcc-d/usr/lib64/gcc/$target/$version/include/"
    mv  gcc/usr/share/man/man1/gdc.1 \
        gcc-d/usr/share/man/man1
    mv "gcc/usr/lib64/gcc/$target/$version/d21" \
       "gcc-d/usr/lib64/gcc/$target/$version/"
    mv gcc/usr/bin/*gdc gcc-d/usr/bin
    find gcc-d -newermt "@$timestamp" -exec touch -hd "@$timestamp" '{}' +
    mv gcc-d "gcc-d-$version-amd64"
    okpkg makepkg "gcc-d-$version-amd64"
    okpkg install "gcc-d-$version-amd64.tar.lz"
fi

# objc/++
if [ -f gcc/usr/lib64/gcc/$target/$version/cc1obj ]; then
    mkdir -p "gcc-objc/usr/lib64/gcc/$target/$version/include"

    mv "gcc/usr/lib64/gcc/$target/$version/include/objc" \
       "gcc-objc/usr/lib64/gcc/$target/$version/include"
    mv "gcc/usr/lib64/gcc/$target/$version/cc1obj" \
        "gcc-objc/usr/lib64/gcc/$target/$version/"
    mv "gcc/usr/lib64/gcc/$target/$version/cc1objplus" \
       "gcc-objc/usr/lib64/gcc/$target/$version/"
    find gcc-objc -newermt "@$timestamp" -exec touch -hd "@$timestamp" '{}' +
    mv gcc-objc "gcc-objc-$version-amd64"
    okpkg makepkg "gcc-objc-$version-amd64"
    okpkg install "gcc-objc-"$version"-amd64.tar.lz"
fi

# gccgo
if [ -f gcc/usr/bin/go ]; then
    mkdir -p "gcc-go/usr/lib64/gcc/$target/$version/"
    mkdir -p  gcc-go/usr/share/man/man1
    mkdir -p  gcc-go/usr/bin

    mv "gcc/usr/lib64/gcc/$target/$version/"*go* \
       "gcc-go/usr/lib64/gcc/$target/$version/"
    mv "gcc/usr/lib64/gcc/$target/$version/buildid" \
       "gcc-go/usr/lib64/gcc/$target/$version/"
    mv "gcc/usr/lib64/gcc/$target/$version/test2json" \
       "gcc-go/usr/lib64/gcc/$target/$version/"
    mv "gcc/usr/lib64/gcc/$target/$version/vet" \
       "gcc-go/usr/lib64/gcc/$target/$version/"
    mv gcc/usr/share/man/man1/*go* gcc-go/usr/share/man/man1
    mv gcc/usr/lib64/go gcc-go/usr/lib64/go
    mv gcc/usr/lib64/libgo.a gcc-go/usr/lib64
    mv gcc/usr/lib64/libgobegin.a gcc-go/usr/lib64
    mv gcc/usr/lib64/libgolibbegin.a gcc-go/usr/lib64
    mv gcc/usr/bin/*go* gcc-go/usr/bin
    find gcc-go -newermt "@$timestamp" -exec touch -hd "@$timestamp" '{}' +
    mv gcc-go "gcc-go-$version-amd64"
    okpkg makepkg "gcc-go-$version-amd64"
    okpkg install "gcc-go-$version-amd64.tar.lz"
fi

# gcc-fortran
if [ -f gcc/usr/bin/gfortran ]; then
    mkdir -p "gcc-fortran/usr/lib64/gcc/$target/$version/include"
    mkdir -p  gcc-fortran/usr/share/man/man1
    mkdir -p  gcc-fortran/usr/bin

    mv "gcc/usr/lib64/gcc/$target/$version/finclude" \
       "gcc-fortran/usr/lib64/gcc/$target/$version/"
    mv "gcc/usr/lib64/gcc/$target/$version/include/ISO_Fortran_binding.h" \
       "gcc-fortran/usr/lib64/gcc/$target/$version/include/ISO_Fortran_binding.h"
    mv "gcc/usr/lib64/gcc/$target/$version/libcaf_single.a" \
       "gcc-fortran/usr/lib64/gcc/$target/$version/libcaf_single.a"
    mv gcc/usr/bin/*gfortran gcc-fortran/usr/bin
    mv "gcc/usr/lib64/gcc/$target/$version/f951" \
       "gcc-fortran/usr/lib64/gcc/$target/$version/f951"
    mv gcc/usr/share/man/man1/gfortran.1 \
        gcc-fortran/usr/share/man/man1/gfortran.1
    find gcc-fortran -newermt "@$timestamp" \
        -exec touch -hd "@$timestamp" '{}' +
    mv gcc-fortran "gcc-fortran-$version-amd64"
    okpkg makepkg "gcc-fortran-$version-amd64"
    okpkg install "gcc-fortran-$version-amd64.tar.lz"
fi

# finish gcc
find gcc -newermt "@$timestamp" -exec touch -hd "@$timestamp" '{}' +
mv gcc "gcc-$version-amd64"
okpkg makepkg "gcc-$version-amd64"
okpkg install "gcc-$version-amd64.tar.lz"
rm -f "$pkgname"*.tar.lz
rm -f "/usr/okpkg/index/$pkgname.index"
