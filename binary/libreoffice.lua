#!/usr/bin/env lua

dofile "/usr/okpkg/okpkg.lua"

-- vars
pkgname = "libreoffice-bin"
url="https://download.documentfoundation.org/libreoffice/stable/7.5.1/deb/x86_64/LibreOffice_7.5.1_Linux_x86-64_deb.tar.gz"

-- download
chdir("/usr/okpkg/packages")
mkdir(pkgname)
chdir(pkgname)
os.execute("curl -L '" .. url .. "' | tar --strip-components=1 -xzf -")

-- prepare package
mkdir("usr")
mkdir("usr/bin")
os.execute [[
    find DEBS -name '*.deb' \
        -exec ar x '{}' data.tar.xz \; \
        -exec tar -xf data.tar.xz \;
]]
os.rename("opt", "usr/lib64")
symlink("/usr/lib64/libreoffice7.5/program/soffice", "usr/bin/libreoffice7.5")
symlink("/usr/bin/libreoffice7.5", "usr/bin/libreoffice")
os.execute("rm -r usr/share/applications DEBS readmes usr/local usr/lib")
os.remove("data.tar.xz")
os.rename("usr/lib64/libreoffice7.5/share/xdg", "usr/share/applications")

-- install
chdir("..")
install(makepkg(pkgname))
