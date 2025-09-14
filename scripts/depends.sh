#!/bin/sh

cd /var/lib/okpkg/index

listlibs(){
    sed 's/^.//' $1 | xargs file | \
    grep -e "executable" -e "shared object" | grep ELF | cut -f 1 -d :
}

printlibs(){
    listlibs $1 | xargs objdump -p | awk '/NEEDED/{print $2}' | sort -u
}

notfound(){
   sed 's/^.//' $1 | xargs file | \
   grep -e "executable" -e "shared object" | grep ELF | cut -f 1 -d : \
   xargs ldd | grep -e ":" -e "not found"
}

printdeps(){
    for f in `printlibs $1.index`; do
        printf "%s: %s\n" $f $(grep -rlie $f . | sed 's:^\./::;s:\.index$::')
    done
}

for i in /var/lib/okpkg/index/*.index; do
  for l in `listlibs $i`; do
    x=`ldd $l 2>/dev/null | grep "not found"`
    if ! test -z "$x" ; then
      printf "%s: %s: %s\n" "$i" "$l"
      printf "%s\n" "$x"
    fi
  done
done
