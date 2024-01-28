#!/usr/bin/env lua

dofile "/usr/okpkg/okpkg.lua"

-- vars
pkgname = "signal-desktop"
url = "https://updates.signal.org/desktop/apt/pool/s/signal-desktop/signal-desktop_6.34.0_amd64.deb"

-- download
chdir("/usr/okpkg/packages")
mkdir(pkgname)
chdir(pkgname)
os.execute("curl -LO '" .. url .. "'")
os.execute("ar x " .. basename(url) .. " data.tar.xz")
os.execute("tar -xf data.tar.xz")
os.remove(basename(url))
os.remove("data.tar.xz")

-- copy desktop file to buffer
fd = io.open("usr/share/applications/signal-desktop.desktop")
buf = fd:read("*a")
io.close(fd)

-- rewrite modifications at destination
fd = io.open("usr/share/applications/signal-desktop.desktop", "w")
fd:write(buf:gsub("/opt/Signal", "/usr/bin"))
io.close(fd)

-- prepare package
mkdir("usr/lib64")
mkdir("usr/bin")
os.rename("opt/Signal", "usr/lib64/signal-desktop")
symlink("/usr/lib64/signal-desktop/signal-desktop", "usr/bin/signal-desktop")
os.remove("opt")

-- install
chdir("..")
install(makepkg(pkgname))
