#!/usr/bin/env lua

dofile "/usr/okpkg/okpkg.lua"

-- vars
pkgname = "rust-bin"
url = "https://static.rust-lang.org/dist/rust-1.76.0-x86_64-unknown-linux-gnu.tar.gz"

-- download
chdir("/usr/okpkg/packages")
mkdir(pkgname)
chdir(pkgname)
os.execute("curl -L '" .. url .. "' | tar -xzf -")

-- prepare package
mkdir("usr")
os.rename(basename(url):sub(1, -8), "tmp")
setenv("DESTDIR", string.format("/usr/okpkg/packages/%s", pkgname))
os.execute("./tmp/install.sh --destdir=$DESTDIR")
unsetenv("DESTDIR")
os.rename("usr", "tmp/usr")
os.rename("tmp/usr/local", "usr")
os.rename("usr/lib", "usr/lib64")
os.execute("rm -r tmp")

-- install
chdir("..")
install(makepkg(pkgname))
