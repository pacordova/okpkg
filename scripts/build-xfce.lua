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
emerge("firefox-bin")
build_all("/usr/okpkg/db/net.db")

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

-- firefox symlinks
os.execute [[
   install -d /usr/local/lib64
   for f in /usr/lib64/firefox/*.so; do
       ln -sf $f /usr/local/lib64/`basename $f` 
   done
]]

-- Create firefox.desktop
fp = io.open("/usr/share/applications/firefox.desktop", 'w')
fp:write [[
[Desktop Entry]
Version=1.0
Name=Firefox Web Browser
Comment=Browse the World Wide Web
GenericName=Web Browser
Keywords=Internet;WWW;Browser;Web;Explorer
Exec=apulse firefox %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=/usr/lib64/firefox/browser/chrome/icons/default/default128.png
Categories=GNOME;GTK;Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
]]
fp:close()

-- Cleanup
chdir("/usr/okpkg/packages/a")
os.rename("sqlite-3460100-amd64.tar.lz", "sqlite-3.46.1-amd64.tar.lz")
chdir("/usr/okpkg/packages/d")
os.rename("rust-bin-1.81.0-x86_64-unknown-linux-gnu-amd64.tar.lz", "rust-bin-1.81.0-amd64.tar.lz")
chdir("/usr/okpkg/packages/l")
os.rename("x264-31e19f92f00c7003fa115047ce50978bc98c3a0d-amd64.tar.lz", "x264-20231001-amd64.tar.lz")
os.rename("dav1d-1d-1.4.3-amd64.tar.lz", "dav1d-1.4.3-amd64.tar.lz")
os.rename("libuv-1.48.0-dist-amd64.tar.lz", "libuv-1.48.0-amd64.tar.lz")
chdir("/usr/okpkg/packages")
os.execute("rm -fr */_*.tar.lz")

-- You may want to edit these to your own timezone/user
symlink("/usr/share/zoneinfo/US/Eastern", "/etc/localtime")
os.execute("useradd -m pac && usermod -a -G wheel pac")
