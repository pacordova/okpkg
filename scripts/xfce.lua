#!/usr/bin/env lua

-- Paths
local okpath = "/var/lib/okpkg"
local dbpath = "/var/lib/okpkg/db"
local pkgdir = "/var/lib/okpkg/packages"
local srcpath = "/var/lib/okpkg/sources"

-- Ensure okpkg is installed
os.execute(string.format("cd %s && make && make install", okpath))

-- Imports
dofile("/usr/bin/okpkg")

local unpack = unpack or table.unpack

local ok = require("okutils")

local chdir, mkdir, symlink =
   ok.chdir, ok.mkdir, ok.symlink

local fp, buf

local dirs = {
   ["devel.db"]   = "d",
   ["flatpak.db"] = "b",
   ["fonts.db"]   = "f",
   ["gnupg.db"]   = "n",
   ["gtk.db"]     = "x",
   ["libs.db"]    = "l",
   ["python.db"]  = "py",
   ["perl.db"     = "pl",
   ["net.db"]     = "n",
   ["video.db"]   = "v",
   ["xfce.db"]    = "xf",
   ["xorg.db"]    = "x",
}

-- Builds and installs all packages in a single db file
local function build_all(x)
   local fp, buf
   fp = io.open(string.format("%s/%s", dbpath, x))
   buf = '\n' .. fp:read('*a')
   fp:close()
   for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do emerge(i)
      if i == "librsvg" or i == "gdk-pixbuf2" then
         os.execute("gdk-pixbuf-query-loaders --update-cache")
      end
   end
   chdir(pkgdir)
   mkdir(dirs[x])
   os.execute("mv *.tar.lz " .. dirs[x])
   os.execute("rm -fr " .. srcpath)
   mkdir(srcpath)
end

-- Generate locales
os.execute("localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true")
os.execute("localedef -i en_US -f UTF-8 en_US.UTF-8")

-- Install system packages to track in indexdir
chdir(pkgdir)
os.execute("okpkg install *.tar.lz")
mkdir("a")
os.execute("mv *.tar.lz a")

-- itstool needs libxml2
emerge("libxml2")
os.execute(string.format("rm -f %s/libxml2-*.tar.lz", pkgdir))

build_all("python.db")
build_all("perl.db")
build_all("devel.db")
build_all("libs.db")
build_all("net.db")
build_all("gnupg.db")
build_all("fonts.db")
build_all("xorg.db")
build_all("gtk.db")
build_all("xfce.db")
build_all("video.db")
build_all("flatpak.db")

-- Rebuilds
emerge("dbus")
emerge("libva")
emerge("gdk-pixbuf2")

-- Post-install
os.execute("makewhatis /usr/share/man")
os.execute("pwconv && grpconv")
os.execute("glib-compile-schemas /usr/share/glib-2.0/schemas")
os.execute("fc-cache")
os.execute("update-desktop-database")
os.execute("update-mime-database /usr/share/mime")
os.execute("gdk-pixbuf-query-loaders --update-cache")

-- Set XFCE default terminal
symlink("st", "/usr/bin/xfce4-terminal")

-- apulse firefox
fp = io.open("/usr/bin/firefox", 'w')
fp:write [[
#!/bin/sh
/usr/bin/apulse /usr/lib64/firefox/firefox
]]
fp:close()
os.execute("chmod 755 /usr/bin/firefox")

-- Cleanup
chdir(pkgdir)
os.rename("a/sqlite-3460100-amd64.tar.lz", "a/sqlite-3.46.1-amd64.tar.lz")
os.rename("d/rust-bin-1.82.0-x86_64-unknown-linux-gnu-amd64.tar.lz", "d/rust-bin-1.82.0-amd64.tar.lz")
os.rename("l/x264-31e19f92f00c7003fa115047ce50978bc98c3a0d-amd64.tar.lz", "l/x264-20231001-amd64.tar.lz")
os.rename("l/dav1d-1d-1.5.0-amd64.tar.lz", "l/dav1d-1.5.0-amd64.tar.lz")
os.rename("l/libuv-1.49.2-dist-amd64.tar.lz", "l/libuv-1.49.2-amd64.tar.lz")
os.rename("l/libinih-r58-amd64.tar.lz", "l/libinih-58-amd64.tar.lz")
os.rename("v/nv-codec-headers-n12.2.72.0-amd64.tar.lz", "v/nv-codec-headers-12.2.72.0-amd64.tar.lz")
os.execute("rm -fr */_*.tar.lz")

-- You may want to edit these to your own timezone/user
symlink("/usr/share/zoneinfo/US/Eastern", "/etc/localtime")
os.execute("useradd -m pac && usermod -a -G wheel pac")
