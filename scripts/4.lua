#!/usr/bin/env lua

-- imports
require "utils"

-- environment
setenv("DESTDIR", "/mnt")

-- final bootstrap
os.execute [[
    cd /usr/okpkg
    rm -r sources 2>/dev/null
    tar -xf sources.tar 2>/dev/null
    umount -l $DESTDIR
    read -p "Enter partition to format: " partition
    mkfs.ext4 $partition
    mount $partition $DESTDIR

    cd $DESTDIR
    lua /usr/okpkg/scripts/filesystem.lua
    find /usr/okpkg/packages/base -name '*.tar.xz' -exec tar -xhf {} 2>/dev/null \;
    find /usr/okpkg/packages/gcc  -name '*.tar.xz' -exec tar -xhf {} 2>/dev/null \;
    git clone /usr/okpkg ${DESTDIR}/usr/okpkg
    tar -C /mnt/usr/okpkg -xf /usr/okpkg/sources.tar
    ln -s gcc ${DESTDIR}/usr/bin/cc 2>/dev/null
    ln -s gcc ${DESTDIR}/usr/bin/c99 2>/dev/null
    ln -s bash ${DESTDIR}/bin/sh 2>/dev/null
]]
