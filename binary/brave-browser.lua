#!/usr/bin/env lua

dofile "/usr/okpkg/okpkg.lua"

-- vars
pkgname = "brave-browser"
url = "https://github.com/brave/brave-browser/releases/download/v1.61.120/brave-browser-1.61.120-linux-amd64.zip"

-- download
chdir("/usr/okpkg/packages")
mkdir(pkgname)
chdir(pkgname)
mkdir("./usr")
mkdir("./usr/lib64")
mkdir("./usr/lib64/brave-browser")
mkdir("./usr/bin")

chdir("./usr/lib64/brave-browser")
os.execute("curl -LO '" .. url .. "'")
os.execute("unzip " .. basename(url))
os.remove(basename(url))
chdir("../../bin")
symlink("/usr/lib64/brave-browser/brave-browser", "brave-browser")

-- install
chdir("../../..")
install(makepkg(pkgname))
