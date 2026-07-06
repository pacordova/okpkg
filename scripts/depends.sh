#!/bin/sh

indexdir=/var/log/packages
cachedir=/var/db/depends
rm -fr $cachedir
mkdir -p $cachedir

# Lists all binary files in a file list from stdin
# usage: listelf < FILE
listelf(){
  sed 's|^.||' \
  | xargs file \
  | awk -F: '(/executable/||/shared object/)&&/ELF/{print $1}'
}

ldd_all(){
  find /bin /lib64 -exec file '{}' + \
  | awk -F: '(/executable/||/shared object/)&&/ELF/{print $1}' \
  | xargs ldd 2>/dev/null
}

# objdump all ELF files in stdin
# usage: dump_all < FILE
dump_all(){
  listelf | xargs objdump -p 2>/dev/null
}

# Filters for NEEDED in objdump
# usage: dump_needed < FILE
dump_needed(){
  dump_all | awk '/NEEDED/{print $2}' | uniq
}

# Filters for RUNPATH and concatenates with ld.so.conf
# usage: dump_runpath < FILE
dump_runpath(){
  dump_all | awk '/RUNPATH/{print $2}' | cat - /etc/ld.so.conf | uniq
}

# Finds NEEDED files in idx to list dependencies
# usage: deps < FILE
deps(){
  dump_needed | grep -f- -l "$indexdir/"*
}

# Search cache for reverse dependencies
revdeps(){
  grep "$1" -l "$cachedir/"*
}

# Create/update cache of dependencies
mkcache(){
  for f in "$indexdir/"*; do deps < "$f" > "$cachedir/${f##*/}"; done
}

# Simple but unsafe way to find broken packages
# usage: unsafe < FILE
unsafe(){
  listelf | xargs ldd 2>/dev/null | grep "not found"
}

# Traditional but unsafe
#for f in $indexdir/*; do unsafe < $f | sed "s|^|[$f]: |"; done

mkcache
#revdeps eudev
#revdeps upower
