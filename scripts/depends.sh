#!/bin/sh

cd /usr/okpkg/index

printlibs(){
    sed 's/^.//' $1.index | xargs file | \
    grep -e "executable" -e "shared object" | grep ELF | cut -f 1 -d : | \
    xargs objdump -p | awk '/NEEDED/{print $2}' | sort -u
}

printdeps(){ 
    for f in `printlibs $1`; do printf "%s: %s\n" $(grep -rlie $f .) $f; done
}

printdeps xorg-server
