#!/usr/bin/env lua

-- Ensure okpkg is installed
local fp; fp = io.open"/usr/bin/okpkg"
if fp then fp:close() else fp = io.open"/usr/bin/make"
   if fp then fp:close(); os.execute"cd /usr/okpkg && make && make install"; end
end

-- Imports
dofile"/usr/okpkg/okpkg.lua"
local ok = require"okutils"
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
         os.execute"gdk-pixbuf-query-loaders --update-cache"
      end
   end
end

-- Rebuilds all arguments (for reproducibility)
local function rebuild(...)
   for i=1,#arg do emerge(arg[i]) end
end

-- Install and move system packages to /usr/okpkg/packages/a
os.execute"okpkg install /usr/okpkg/packages/*.tar.lz"
mkdir"/usr/okpkg/packages/a"
os.execute"mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/a"

-- Generate locales
os.execute"localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true"
os.execute"localedef -i en_US -f UTF-8 en_US.UTF-8"

-- Modules
emerge_all"/usr/okpkg/db/modules.db"
mkdir"/usr/okpkg/packages/py"
mkdir"/usr/okpkg/packages/perl"
os.execute"mv /usr/okpkg/packages/python-*.tar.lz /usr/okpkg/packages/py"
os.execute"mv /usr/okpkg/packages/perl-*.tar.lz /usr/okpkg/packages/perl"

-- Development tools
emerge_all"/usr/okpkg/db/dev.db"
mkdir"/usr/okpkg/packages/d"
os.execute"mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/d"

-- Libraries
emerge_all"/usr/okpkg/db/lib.db"
mkdir"/usr/okpkg/packages/l"
os.execute"mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/l"

-- Network tools
emerge_all"/usr/okpkg/db/net.db"
mkdir"/usr/okpkg/packages/n"
os.execute"mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/n"

-- Rust
emerge"rust-bin"

-- Xorg
emerge_all"/usr/okpkg/db/xorg.db"; 
rebuild("dbus", "libva")
mkdir"/usr/okpkg/packages/x"
os.execute"mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/x"

-- XFCE
emerge_all"/usr/okpkg/db/xfce.db"
rebuild("gdk-pixbuf2")
mkdir"/usr/okpkg/packages/xfce"
os.execute"mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/xfce"

-- Other useful packages
emerge"firefox-bin"

-- Post-install
os.execute"udevadm hwdb --usr --update"
os.execute"setcap cap_net_raw+p /usr/bin/ping"
os.execute"makewhatis /usr/share/man"
os.execute"pwconv && grpconv"
os.execute"glib-compile-schemas /usr/share/glib-2.0/schemas"
os.execute"fc-cache"
os.execute"update-desktop-database"
os.execute"update-mime-database /usr/share/mime"
os.execute"gdk-pixbuf-query-loaders --update-cache"

-- Update the icon caches
os.execute"gtk-update-icon-cache /usr/share/icons/elementary-xfce-darkest"
os.execute"gtk-update-icon-cache /usr/share/icons/elementary-xfce-darkest"
os.execute"gtk-update-icon-cache /usr/share/icons/elementary-xfce-darker"
os.execute"gtk-update-icon-cache /usr/share/icons/hicolor"
os.execute"gtk-update-icon-cache /usr/share/icons/elementary-xfce"
os.execute"gtk-update-icon-cache /usr/share/icons/elementary-xfce-dark"
os.execute"gtk-update-icon-cache /usr/share/icons/Adwaita"

-- Set XFCE default terminal
symlink("st", "/usr/bin/xfce4-terminal")

-- Cleanup
chdir"/usr/okpkg/packages/l"
os.rename("sqlite-3460000-amd64.tar.lz", "sqlite-3.46.0-amd64.tar.lz")
os.rename("x264--amd64.tar.lz", "x264-20231114-amd64.tar.lz")
os.rename("dav1d-1d-1.4.3-amd64.tar.lz", "dav1d-1.4.3-amd64.tar.lz")
chdir".."
os.execute"rm -fr _*.tar.lz *no"

-- You may want to edit these to your own timezone/user
symlink("/usr/share/zoneinfo/US/Eastern", "/etc/localtime")
os.execute"useradd -m pac && usermod -a -G wheel pac"
