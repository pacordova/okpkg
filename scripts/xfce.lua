#!/usr/bin/env lua

-- Ensure okpkg is installed
os.execute("make -C /usr/okpkg install")

local unpack = unpack or table.unpack
local C = unpack(loadfile("/etc/okpkg.conf")())
local ok = require("okutils")
local chdir, mkdir, symlink =
   ok.chdir, ok.mkdir, ok.symlink

function remove_all(x) 
   os.execute("rm -fr " .. x) 
end

-- Builds and installs all packages in a single db file
local function build_all(x)
   local fp, buf
   fp = io.open(string.format("%s/db/%s", C["okdir"], x))
   buf = '\n' .. fp:read('*a')
   fp:close()
   for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do 
      if i == "librsvg" or 
         i == "gdk-pixbuf2" 
      then
         emerge(i); os.execute("gdk-pixbuf-query-loaders --update-cache");
      else 
         emerge(i);
      end
   end
   remove_all(C["workdir"]); mkdir(C["workdir"]);
end

-- Generate locales
os.execute("localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true")
os.execute("localedef -i en_US -f ISO-8859-1 en_US")
os.execute("localedef -i en_US -f UTF-8 en_US.UTF-8")

-- Install base packages to track in indexdir
setenv("destdir", "/")
dofile(string.format("%s/scripts/install.lua", C["okdir"]))
unsetenv("destdir")

build_all("python.db")
build_all("perl.db")
emerge("libxml2") -- itstool needs libxml2
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
os.execute("setcap cap_net_raw+p /usr/bin/ping")
os.execute("chown root:messagebus /usr/lib64/dbus-daemon-launch-helper")

-- Set XFCE default terminal
local fp = io.open("/usr/bin/xfce4-terminal", 'w')
fp:write [[
#!/bin/sh
/usr/bin/st -e tmux new-session -A
]]
fp:close()
os.execute("chmod 755 /usr/bin/xfce4-terminal")

-- apulse firefox
local fp = io.open("/usr/bin/firefox", 'w')
fp:write [[
#!/bin/sh
/usr/bin/apulse /usr/lib64/firefox/firefox
]]
fp:close()
os.execute("chmod 755 /usr/bin/firefox")

-- Cleanup
chdir(C["outdir"])
os.rename("sqlite-3460100-amd64.tar.lz", "sqlite-3.46.1-amd64.tar.lz")
os.rename("rust-bin-1.82.0-x86_64-unknown-linux-gnu-amd64.tar.lz", "rust-bin-1.82.0-amd64.tar.lz")
os.rename("x264-31e19f92f00c7003fa115047ce50978bc98c3a0d-amd64.tar.lz", "x264-20231001-amd64.tar.lz")
os.rename("dav1d-1d-1.5.0-amd64.tar.lz", "dav1d-1.5.0-amd64.tar.lz")
os.rename("libuv-1.49.2-dist-amd64.tar.lz", "libuv-1.49.2-amd64.tar.lz")
os.rename("libinih-r58-amd64.tar.lz", "libinih-58-amd64.tar.lz")
os.rename("nv-codec-headers-n12.2.72.0-amd64.tar.lz", "nv-codec-headers-12.2.72.0-amd64.tar.lz")
os.execute("rm -f _*.tar.lz")

-- You may want to edit these to your own timezone/user
symlink("/usr/share/zoneinfo/" .. C["tz"], "/etc/localtime")
os.execute("useradd -m -G audio,input,video,wheel " .. C["whoami"])
