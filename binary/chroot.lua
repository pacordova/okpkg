#!/usr/bin/env lua

dofile "/usr/okpkg/okpkg.lua"

-- download
setenv("DESTDIR", "/usr/okpkg/packages/chroot")
mkdir(os.getenv("DESTDIR"))
chdir("/usr/okpkg/sources")

os.execute [[
    git clone git://git.suckless.org/sbase
    cd sbase
    make -j5
    mkdir -p ${DESTDIR}/usr/bin ${DESTDIR}/usr/share/man/man1
    mv chroot ${DESTDIR}/usr/bin
    mv chroot.1 ${DESTDIR}/usr/share/man/man1
]]

install(makepkg(os.getenv("DESTDIR")))
