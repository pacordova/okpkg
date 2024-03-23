#!/bin/bash

cd /usr/okpkg/packages

target=x86_64-pc-linux-gnu
version=13.2.0
pkgname=gcc13
timestamp=$(stat -c %Y gcc13*.tar.xz)

mkdir gcc
tar -C gcc -xf "$pkgname"*.tar.xz

# gcc-libs
mkdir -p gcc-libs/usr/lib64
mv gcc/usr/lib64/libgcc_s.so* gcc-libs/usr/lib64
mv gcc/usr/lib64/libstdc++.so* gcc-libs/usr/lib64
find gcc-libs -newermt "@$timestamp" \
    -exec touch -hd "@$timestamp" '{}' +
mv gcc-libs gcc-libs-"$version"-x86_64
okpkg makepkg gcc-libs-"$version"-x86_64
okpkg install gcc-libs-"$version"-x86_64.tar.xz

if [ -f gcc/usr/bin/gnat ]; then
    mkdir -p gcc-ada/usr/libexec/gcc/"$target"/"$version"
    mkdir -p gcc-ada/usr/lib64/gcc/"$target"/"$version" 
    mkdir -p gcc-ada/usr/bin

    mv gcc/usr/bin/gnat* gcc-ada/usr/bin
    mv gcc/usr/lib64/gcc/"$target"/"$version"/ada* \
       gcc-ada/usr/lib64/gcc/"$target"/"$version"/
    mv gcc/usr/libexec/gcc/"$target"/"$version"/gnat1 \
        gcc-ada/usr/libexec/gcc/"$target"/"$version"/
    find gcc-ada -newermt "@$timestamp" \
        -exec touch -hd "@$timestamp" '{}' +
    mv gcc-ada gcc-ada-"$version"-x86_64
    okpkg makepkg gcc-ada-"$version"-x86_64
    okpkg install gcc-ada-"$version"-x86_64.tar.xz
fi

if [ -f gcc/usr/bin/gdc ]; then
    mkdir -p gcc-d/usr/lib64/gcc/"$target"/"$version"/include 
    mkdir -p gcc-d/usr/libexec/gcc/"$target"/"$version"/ 
    mkdir -p gcc-d/usr/share/man/man1
    mkdir -p gcc-d/usr/lib64 
    mkdir -p gcc-d/usr/bin

    mv gcc/usr/lib64/gcc/"$target"/"$version"/include/d \
        gcc-d/usr/lib64/gcc/"$target"/"$version"/include
    mv gcc/usr/share/man/man1/gdc.1 \
        gcc-d/usr/share/man/man1
    mv gcc/usr/libexec/gcc/"$target"/"$version"/d21 \
        gcc-d/usr/libexec/gcc/"$target"/"$version"/
    mv gcc/usr/lib64/libgphobos* gcc-d/usr/lib64
    mv gcc/usr/lib64/libgdruntime* gcc-d/usr/lib64
    mv gcc/usr/bin/*gdc gcc-d/usr/bin
    find gcc-d -newermt "@$timestamp" \
        -exec touch -hd "@$timestamp" '{}' +
    mv gcc-d gcc-d-"$version"-x86_64
    okpkg makepkg gcc-d-"$version"-x86_64
    okpkg install gcc-d-"$version"-x86_64.tar.xz
fi

if [ -f gcc/usr/libexec/gcc/"$target"/"$version"/cc1obj ]; then
    mkdir -p gcc-objc/usr/lib64/gcc/"$target"/"$version"/include 
    mkdir -p gcc-objc/usr/libexec/gcc/"$target"/"$version" 
    mkdir -p gcc-objc/usr/lib64

    mv gcc/usr/lib64/gcc/"$target"/"$version"/include/objc \
        gcc-objc/usr/lib64/gcc/"$target"/"$version"/include
    mv gcc/usr/libexec/gcc/"$target"/"$version"/cc1obj \
        gcc-objc/usr/libexec/gcc/"$target"/"$version"/
    mv gcc/usr/libexec/gcc/"$target"/"$version"/cc1objplus \
        gcc-objc/usr/libexec/gcc/"$target"/"$version"/
    mv gcc/usr/lib64/libobjc* \
        gcc-objc/usr/lib64
    find gcc-objc -newermt "@$timestamp" \
        -exec touch -hd "@$timestamp" '{}' +
    mv gcc-objc gcc-objc-"$version"-x86_64
    okpkg makepkg gcc-objc-"$version"-x86_64
    okpkg install gcc-objc-"$version"-x86_64.tar.xz
fi


if [ -f gcc/usr/bin/gm2 ]; then
    mkdir -p gm2/usr/lib64/gcc/"$target"/"$version"/plugin/ 
    mkdir -p gm2/usr/lib64/gcc/"$target"/"$version"/ 
    mkdir -p gm2/usr/libexec/gcc/"$target"/"$version" 
    mkdir -p gm2/usr/share/man/man1 
    mkdir -p gm2/usr/lib64 
    mkdir -p gm2/usr/bin

    mv gcc/usr/lib64/gcc/"$target"/"$version"/plugin/m2rte.so \
        gm2/usr/lib64/gcc/"$target"/"$version"/plugin/m2rte.so
    mv gcc/usr/libexec/gcc/"$target"/"$version"/cc1gm2 \
        gm2/usr/libexec/gcc/"$target"/"$version"/
    mv gcc/usr/lib64/gcc/"$target"/"$version"/m2/ \
        gm2/usr/lib64/gcc/"$target"/"$version"/
    mv gcc/usr/bin/"$target"-gm2 gm2/usr/bin
    mv gcc/usr/share/man/man1/gm2.1 gm2/usr/share/man/man1
    mv gcc/usr/lib64/libm2* gm2/usr/lib64
    mv gcc/usr/bin/gm2 gm2/usr/bin
    find gm2 -newermt "@$timestamp" \
        -exec touch -hd "@$timestamp" '{}' +
    mv gm2 gm2-"$version"-x86_64
    okpkg makepkg gm2-"$version"-x86_64
    okpkg install gm2-"$version"-x86_64.tar.xz
fi

if [ -f gcc/usr/bin/go ]; then
    mkdir -p gcc-go/usr/libexec/gcc/"$target"/"$version"/ 
    mkdir -p gcc-go/usr/share/man/man1 
    mkdir -p gcc-go/usr/lib64/ 
    mkdir -p gcc-go/usr/bin 

    mv gcc/usr/libexec/gcc/"$target"/"$version"/*go* \
        gcc-go/usr/libexec/gcc/"$target"/"$version"/
    mv gcc/usr/libexec/gcc/"$target"/"$version"/buildid \
        gcc-go/usr/libexec/gcc/"$target"/"$version"/
    mv gcc/usr/libexec/gcc/"$target"/"$version"/test2json \
        gcc-go/usr/libexec/gcc/"$target"/"$version"/
    mv gcc/usr/libexec/gcc/"$target"/"$version"/vet \
        gcc-go/usr/libexec/gcc/"$target"/"$version"/
    mv gcc/usr/share/man/man1/*go* gcc-go/usr/share/man/man1
    mv gcc/usr/lib64/go gcc-go/usr/lib64/go
    mv gcc/usr/lib64/libgo.a gcc-go/usr/lib64
    mv gcc/usr/lib64/libgo.so* gcc-go/usr/lib64
    mv gcc/usr/lib64/libgobegin.a gcc-go/usr/lib64
    mv gcc/usr/lib64/libgolibbegin.a gcc-go/usr/lib64
    mv gcc/usr/bin/*go* gcc-go/usr/bin
    find gcc-go -newermt "@$timestamp" \
        -exec touch -hd "@$timestamp" '{}' +
    mv gcc-go gcc-go-"$version"-x86_64
    okpkg makepkg gcc-go-"$version"-x86_64
    okpkg install gcc-go-"$version"-x86_64.tar.xz
fi


# gcc-fortran
if [ -f gcc/usr/bin/gfortran ]; then
    mkdir -p gcc-fortran/usr/lib64/gcc/"$target"/"$version"/include 
    mkdir -p gcc-fortran/usr/libexec/gcc/"$target"/"$version" 
    mkdir -p gcc-fortran/usr/share/man/man1
    mkdir -p gcc-fortran/usr/bin 

    mv gcc/usr/lib64/gcc/"$target"/"$version"/finclude \
        gcc-fortran/usr/lib64/gcc/"$target"/"$version"
    mv gcc/usr/lib64/gcc/"$target"/"$version"/include/ISO_Fortran_binding.h \
        gcc-fortran/usr/lib64/gcc/"$target"/"$version"/include/ISO_Fortran_binding.h
    mv gcc/usr/lib64/gcc/"$target"/"$version"/libcaf_single.a \
        gcc-fortran/usr/lib64/gcc/"$target"/"$version"/libcaf_single.a
    mv gcc/usr/lib64/libgfortran* gcc-fortran/usr/lib64
    mv gcc/usr/bin/*gfortran gcc-fortran/usr/bin
    mv gcc/usr/libexec/gcc/"$target"/"$version"/f951 \
        gcc-fortran/usr/libexec/gcc/"$target"/"$version"/f951
    mv gcc/usr/share/man/man1/gfortran.1 \
        gcc-fortran/usr/share/man/man1/gfortran.1
    find gcc-fortran -newermt "@$timestamp" \
        -exec touch -hd "@$timestamp" '{}' +
    mv gcc-fortran gcc-fortran-"$version"-x86_64
    okpkg makepkg gcc-fortran-"$version"-x86_64
    okpkg install gcc-fortran-"$version"-x86_64.tar.xz
fi

# finish gcc
find gcc -newermt "@$timestamp" \
    -exec touch -hd "@$timestamp" '{}' +
mv gcc gcc-"$version"-x86_64
okpkg makepkg gcc-"$version"-x86_64
okpkg install gcc-"$version"-x86_64.tar.xz

rm -f "$pkgname"*.tar.xz
rm -f "/usr/okpkg/index/$pkgname.index"
