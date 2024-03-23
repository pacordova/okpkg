#!/usr/bin/env lua

dofile "/usr/okpkg/okpkg.lua"

-- vars
pkgname = "rg"
url = "https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep-13.0.0-x86_64-unknown-linux-musl.tar.gz"

-- download
chdir("/usr/okpkg/packages")
mkdir(pkgname)
chdir(pkgname)
mkdir("tmp")
chdir("tmp")
os.execute("curl -LO '" .. url .. "'")
os.execute("tar --strip-components=1 -xf " .. basename(url))
os.remove(basename(url))
chdir("..")

-- prepare package
mkdir("usr")
mkdir("usr/bin")
mkdir("usr/share")
mkdir("usr/share/man")
mkdir("usr/share/man/man1")
os.rename("tmp/rg", "usr/bin/rg")
os.rename("tmp/doc/rg.1", "usr/share/man/man1/rg.1")
os.execute("rm -r tmp")

-- install
chdir("..")
install(makepkg(pkgname))
