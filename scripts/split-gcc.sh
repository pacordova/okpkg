#!/bin/sh

cd /usr/okpkg/packages
version=13.2.0

if [ -f gcc*.tar.xz ]; then
    mkdir gcc-libs gcc-fortran gcc gcc-ada gcc-d gcc-objc gm2 gcc-go
    tar -C gcc -xf gcc*.tar.xz

    # gcc-libs
    mkdir -p gcc-libs/usr/lib64
    mv gcc/usr/lib64/*so* gcc-libs/usr/lib64

    # gnat
    mkdir -p \
        gcc-ada/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/ \
        gcc-ada/usr/libexec/gcc/x86_64-pc-linux-gnu/$version \
        gcc-ada/usr/bin

    mv gcc/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/adalib/ \
        gcc-ada/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/
    mv gcc/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/adainclude/ \
        gcc-ada/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/
    mv gcc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/gnat1 \
        gcc-ada/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/
    mv gcc/usr/bin/gnat* gcc-ada/usr/bin

    # gdc
    mkdir -p \
        gcc-d/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/include/d/ \
        gcc-d/usr/share/man/man1 \
        gcc-d/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/ \
        gcc-d/usr/lib64 \
        gcc-d/usr/bin

    mv gcc/usr/share/man/man1/gdc.1 gcc-d/usr/share/man/man1
    mv gcc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/d21 \
        gcc-d/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/
    mv gcc/usr/lib64/libgphobos.a gcc-d/usr/lib64
    mv gcc/usr/lib64/libgdruntime.a gcc-d/usr/lib64
    mv gcc/usr/bin/gdc gcc-d/usr/bin
    mv gcc/usr/bin/x86_64-pc-linux-gnu-gdc gcc-d/usr/bin

    # objc / objc++
    mkdir -p \
        gcc-objc/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/include/objc \
        gcc-objc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version \
        gcc-objc/usr/lib64

    mv gcc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/cc1obj \
        gcc-objc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/
    mv gcc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/cc1objplus \
        gcc-objc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/
    mv gcc/usr/lib64/libobjc.a gcc-objc/usr/lib64

    # m2
    mkdir -p \
        gm2/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/m2/ \
        gm2/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/plugin/ \
        gm2/usr/share/man/man1 \
        gm2/usr/libexec/gcc/x86_64-pc-linux-gnu/$version \
        gm2/usr/lib64 \
        gm2/usr/bin

    mv gcc/usr/share/man/man1/gm2.1 gm2/usr/share/man/man1
    mv gcc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/cc1gm2 \
        gm2/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/
    mv gcc/usr/lib64/libm2pim.a gm2/usr/lib64
    mv gcc/usr/lib64/libm2min.a gm2/usr/lib64
    mv gcc/usr/lib64/libm2log.a gm2/usr/lib64
    #mv gcc/usr/lib64/libm2iso.a gm2/usr/lib64
    mv gcc/usr/lib64/libm2cor.a gm2/usr/lib64
    mv gcc-libs/usr/lib64/libm2pim* gm2/usr/lib64
    mv gcc-libs/usr/lib64/libm2min* gm2/usr/lib64
    mv gcc-libs/usr/lib64/libm2log* gm2/usr/lib64
    mv gcc-libs/usr/lib64/libm2iso* gm2/usr/lib64
    mv gcc-libs/usr/lib64/libm2cor* gm2/usr/lib64
    mv gcc/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/plugin/m2rte.so \
        gm2/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/plugin/m2rte.so
    mv gcc/usr/bin/gm2 gm2/usr/bin
    mv gcc/usr/bin/x86_64-pc-linux-gnu-gm2 gm2/usr/bin
    
    # go
    mkdir -p \
        gcc-go/usr/lib64/ \
        gcc-go/usr/bin \
        gcc-go/usr/share/man/man1 \
        gcc-go/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/ \

    mv gcc/usr/lib64/go gcc-go/usr/lib64/go
    mv gcc/usr/share/man/man1/go.1 gcc-go/usr/share/man/man1
    mv gcc/usr/share/man/man1/gofmt.1 gcc-go/usr/share/man/man1
    mv gcc/usr/share/man/man1/gccgo.1 gcc-go/usr/share/man/man1
    mv gcc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/go1 \
        gcc-go/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/
    mv gcc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/cgo \
        gcc-go/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/
    mv gcc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/buildid \
        gcc-go/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/
    mv gcc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/test2json \
        gcc-go/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/
    mv gcc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/vet \
        gcc-go/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/
    mv gcc/usr/lib64/libgo.a gcc-go/usr/lib64
    mv gcc/usr/lib64/libgobegin.a gcc-go/usr/lib64
    mv gcc/usr/lib64/libgolibbegin.a gcc-go/usr/lib64
    mv gcc/usr/bin/go gcc-go/usr/bin
    mv gcc/usr/bin/gofmt gcc-go/usr/bin
    mv gcc/usr/bin/x86_64-pc-linux-gnu-gccgo gcc-go/usr/bin

    
    # gcc-fortran
    mkdir -p \
        gcc-fortran/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/include \
        gcc-fortran/usr/libexec/gcc/x86_64-pc-linux-gnu/$version \
        gcc-fortran/usr/bin \
        gcc-fortran/usr/share/man/man1
    mv gcc/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/finclude \
        gcc-fortran/usr/lib64/gcc/x86_64-pc-linux-gnu/$version
    mv gcc/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/include/ISO_Fortran_binding.h \
        gcc-fortran/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/include/ISO_Fortran_binding.h
    mv gcc/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/libcaf_single.a \
        gcc-fortran/usr/lib64/gcc/x86_64-pc-linux-gnu/$version/libcaf_single.a
    mv gcc/usr/lib64/libgfortran.a \
        gcc-fortran/usr/lib64/libgfortran.a
    mv gcc/usr/lib64/libgfortran.spec \
        gcc-fortran/usr/lib64/libgfortran.spec
    mv gcc/usr/bin/*gfortran \
        gcc-fortran/usr/bin
    mv gcc/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/f951 \
        gcc-fortran/usr/libexec/gcc/x86_64-pc-linux-gnu/$version/f951
    mv gcc/usr/share/man/man1/gfortran.1 \
        gcc-fortran/usr/share/man/man1/gfortran.1

    # make the packages
    mv gcc-libs gcc-libs-$version-x86_64
    mv gcc gcc-$version-x86_64
    mv gcc-fortran gcc-fortran-$version-x86_64
    mv gcc-d gcc-d-$version-x86_64
    mv gm2 gm2-$version-x86_64
    mv gcc-go gcc-go-$version-x86_64
    mv gcc-ada gcc-ada-$version-x86_64
    mv gcc-objc gcc-objc-$version-x86_64

    okpkg makepkg \
        gcc-libs-$version-x86_64 \
        gcc-$version-x86_64 \
        gcc-fortran-$version-x86_64 \
        gcc-d-$version-x86_64 \
        gm2-$version-x86_64 \
        gcc-go-$version-x86_64 \
        gcc-ada-$version-x86_64 \
        gcc-objc-$version-x86_64
fi
