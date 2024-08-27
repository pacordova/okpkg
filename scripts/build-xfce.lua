#!/usr/bin/env lua

-- Ensure okpkg is installed
os.execute [[
   if [ ! -x /usr/bin/okpkg ] && [ -x /usr/bin/make ]; then
      cd /usr/okpkg && make && make install
   fi
]]

-- Imports
dofile("/usr/okpkg/okpkg.lua")
local ok = require("okutils")
local mkdir, symlink, chdir =
   ok.mkdir, ok.symlink, ok.chdir
local fp, buf

-- Builds and installs all packages in a single db file
local function emerge_all(db) local fp, buf
   fp = io.open(db)
   buf = '\n' .. fp:read('*a')
   fp:close()
   for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do emerge(i)
      if i == "librsvg" or i == "gdk-pixbuf2" then
         os.execute("gdk-pixbuf-query-loaders --update-cache")
      end
   end
end

-- Install system packages to track in /usr/okpkg/index
os.execute("okpkg install /usr/okpkg/packages/a/*.tar.lz")

-- Generate locales
os.execute("localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true")
os.execute("localedef -i en_US -f UTF-8 en_US.UTF-8")

-- Modules
emerge_all("/usr/okpkg/db/modules.db")
mkdir("/usr/okpkg/packages/m")
os.execute("mv /usr/okpkg/packages/python-*.tar.lz /usr/okpkg/packages/m")
os.execute("mv /usr/okpkg/packages/perl-*.tar.lz /usr/okpkg/packages/m")


-- Development tools
emerge_all("/usr/okpkg/db/devel.db")
emerge("rust-bin")
emerge("cmake-bin")
mkdir("/usr/okpkg/packages/d")
os.execute("mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/d")

-- Libraries
emerge_all("/usr/okpkg/db/lib.db")
mkdir("/usr/okpkg/packages/l")
os.execute("mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/l")

-- Network tools
emerge_all("/usr/okpkg/db/net.db")
emerge("firefox-bin")
mkdir("/usr/okpkg/packages/n")
os.execute("mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/n")

-- Xorg
emerge_all("/usr/okpkg/db/xorg.db")
mkdir("/usr/okpkg/packages/x")
os.execute("mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/x")

-- XFCE
emerge_all("/usr/okpkg/db/xfce.db")
mkdir("/usr/okpkg/packages/xf")
os.execute("mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/xf")

-- Rebuilds
emerge("dbus")
emerge("libva")
emerge("gdk-pixbuf2")

-- Post-install
os.execute("udevadm hwdb --usr --update")
os.execute("setcap cap_net_raw+p /usr/bin/ping")
os.execute("makewhatis /usr/share/man")
os.execute("pwconv && grpconv")
os.execute("glib-compile-schemas /usr/share/glib-2.0/schemas")
os.execute("fc-cache")
os.execute("update-desktop-database")
os.execute("update-mime-database /usr/share/mime")
os.execute("gdk-pixbuf-query-loaders --update-cache")

-- Update the icon caches
os.execute("gtk-update-icon-cache /usr/share/icons/elementary-xfce-darkest")
os.execute("gtk-update-icon-cache /usr/share/icons/elementary-xfce-darkest")
os.execute("gtk-update-icon-cache /usr/share/icons/elementary-xfce-darker")
os.execute("gtk-update-icon-cache /usr/share/icons/hicolor")
os.execute("gtk-update-icon-cache /usr/share/icons/elementary-xfce")
os.execute("gtk-update-icon-cache /usr/share/icons/elementary-xfce-dark")
os.execute("gtk-update-icon-cache /usr/share/icons/Adwaita")

-- Set XFCE default terminal
symlink("st", "/usr/bin/xfce4-terminal")

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
chdir("/usr/okpkg/packages/l")
os.rename("sqlite-3460100-amd64.tar.lz", "sqlite-3.46.1-amd64.tar.lz")
os.rename("x264-31e19f92f00c7003fa115047ce50978bc98c3a0d-amd64.tar.lz", "x264-20231001-amd64.tar.lz")
os.rename("dav1d-1d-1.4.3-amd64.tar.lz", "dav1d-1.4.3-amd64.tar.lz")
chdir("/usr/okpkg/packages")
os.execute("rm -fr */_*.tar.lz")

-- You may want to edit these to your own timezone/user
symlink("/usr/share/zoneinfo/US/Eastern", "/etc/localtime")
os.execute("useradd -m pac && usermod -a -G wheel pac")
