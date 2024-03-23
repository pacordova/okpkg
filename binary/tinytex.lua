#!/usr/bin/env lua

dofile "/usr/okpkg/okpkg.lua"

-- vars
pkgname = "tinytex"
url = "https://github.com/rstudio/tinytex-releases/releases/download/v2022.08/TinyTeX-1-v2022.08.tar.gz"

-- download
chdir("/usr/okpkg/packages")
mkdir(pkgname)
chdir(pkgname)
os.execute("curl -L '" .. url .. "' | tar -xzf -")

-- prepare package
mkdir("usr")
mkdir("usr/bin")
mkdir("usr/lib64")
os.rename(".TinyTeX", "usr/lib64/tinytex")
os.execute("find usr/lib64/tinytex/bin/x86_64-linux -type f " ..
    "-exec ln -s '/{}' usr/bin ';' 2>/dev/null")

chdir("..")
-- install
install(makepkg(pkgname))
