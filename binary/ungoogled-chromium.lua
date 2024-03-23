#!/usr/bin/env lua

dofile "/usr/okpkg/okpkg.lua"

-- vars
pkgname = "ungoogled-chromium"
url = "https://github.com/clickot/ungoogled-chromium-binaries/releases/download/112.0.5615.121-1/ungoogled-chromium_112.0.5615.121-1.1_linux.tar.xz"

-- download and make package
chdir("/usr/okpkg/packages")
mkdir(pkgname)
chdir(pkgname)
mkdir("usr")
mkdir("usr/bin")
mkdir("usr/lib64")
mkdir("usr/lib64/chromium")
chdir("usr/lib64/chromium")
os.execute("curl -LO '" .. url .. "'")
os.execute("tar --strip-components=1 -xf " .. basename(url))
os.remove(basename(url))
os.rename("chrome", "chromium")
symlink("/usr/lib64/chromium/chromium", "../../bin/chromium")

-- install
chdir("/usr/okpkg/packages")
install(makepkg(pkgname))
