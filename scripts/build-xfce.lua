#!/usr/bin/env lua

-- Ensure okpkg is installed
os.execute [[
   if [ ! -x /usr/bin/okpkg ] && [ -x /usr/bin/make ]; then
      cd /usr/okpkg && make && make install
   fi
]]

-- Imports
dofile("/usr/okpkg/okpkg.lua")

local unpack = unpack or table.unpack

local ok = require("okutils")

local chdir, mkdir, symlink =
   ok.chdir, ok.mkdir, ok.symlink

local fp, buf

local dirs = {
   ["/usr/okpkg/db/devel.db"]   = "/usr/okpkg/packages/d",
   ["/usr/okpkg/db/flatpak.db"] = "/usr/okpkg/packages/b",
   ["/usr/okpkg/db/fonts.db"]   = "/usr/okpkg/packages/f",
   ["/usr/okpkg/db/glib.db"]    = "/usr/okpkg/packages/l",
   ["/usr/okpkg/db/gtk.db"]     = "/usr/okpkg/packages/x",
   ["/usr/okpkg/db/lib.db"]     = "/usr/okpkg/packages/l",
   ["/usr/okpkg/db/modules.db"] = "/usr/okpkg/packages/m",
   ["/usr/okpkg/db/net.db"]     = "/usr/okpkg/packages/n",
   ["/usr/okpkg/db/video.db"]   = "/usr/okpkg/packages/v",
   ["/usr/okpkg/db/xfce.db"]    = "/usr/okpkg/packages/xf",
   ["/usr/okpkg/db/xorg.db"]    = "/usr/okpkg/packages/x",
}

-- Builds and installs all packages in a single db file
local function build_all(x)
   local fp, buf
   fp = io.open(x)
   buf = '\n' .. fp:read('*a')
   fp:close()
   for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do emerge(i)
      if i == "librsvg" or i == "gdk-pixbuf2" then
         os.execute("gdk-pixbuf-query-loaders --update-cache")
      end
   end
   mkdir(dirs[x])
   os.execute("mv /usr/okpkg/packages/*.tar.lz " .. dirs[x])
   os.execute("rm -fr /usr/okpkg/sources/*")
end

-- Generate locales
os.execute("localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true")
os.execute("localedef -i en_US -f UTF-8 en_US.UTF-8")

-- Install system packages to track in /usr/okpkg/index
os.execute("okpkg install /usr/okpkg/packages/*.tar.lz")
mkdir("/usr/okpkg/packages/a")
os.execute("mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/a")

-- Modules
build_all("/usr/okpkg/db/modules.db")

-- itstool needs libxml2
emerge("libxml2")
os.execute("rm -f /usr/okpkg/packages/libxml2-*.tar.lz")

-- Development tools
emerge("rust-bin")
build_all("/usr/okpkg/db/devel.db")

-- Libraries
build_all("/usr/okpkg/db/lib.db")

-- Network tools
build_all("/usr/okpkg/db/net.db")
emerge("firefox-bin")
os.execute("mv /usr/okpkg/packages/firefox-*.tar.lz /usr/okpkg/packages/n")

-- Fonts
build_all("/usr/okpkg/db/fonts.db")

-- Xorg
build_all("/usr/okpkg/db/xorg.db")

-- GTK+
build_all("/usr/okpkg/db/gtk.db")

-- XFCE
build_all("/usr/okpkg/db/xfce.db")

-- Flatpak
build_all("/usr/okpkg/db/flatpak.db")

-- Video
build_all("/usr/okpkg/db/video.db")

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
chdir("/usr/okpkg/packages")
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
