#!/usr/bin/env lua

-- ensure okpkg is installed
local fp; fp = io.open"/usr/bin/okpkg"
if fp then fp:close() else fp = io.open"/usr/bin/make"
   if fp then fp:close(); os.execute"cd /usr/okpkg && make && make install"; end
end

-- imports
dofile"/usr/okpkg/okpkg.lua"
local ok = require"okutils"
local mkdir, symlink =
   ok.mkdir, ok.symlink

-- locals
local fp, buf

local function emerge_all(db) local fp, buf
   fp = io.open(db)
   buf = '\n' .. fp:read('*a')
   fp:close()
   for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do emerge(i)
      if i == "librsvg" or i == "gdk-pixbuf" then
         os.execute"gdk-pixbuf-query-loaders --update-cache"
      end
   end
end

-- install and move system packages to /usr/okpkg/packages/a
os.execute"okpkg install /usr/okpkg/packages/*.tar.lz"
mkdir"/usr/okpkg/packages/a"
os.execute"mv /usr/okpkg/packages/*.tar.lz /usr/okpkg/packages/a"

-- build all
emerge_all"/usr/okpkg/db/modules.db"
emerge"nasm"
emerge_all"/usr/okpkg/db/lib.db"
emerge"sassc"
emerge_all"/usr/okpkg/db/xorg.db"
emerge"dbus"
dofile"/usr/okpkg/binary/rust.lua"
emerge"libfdk-aac"
emerge"dav1d"
emerge"ffmpeg"
emerge_all"/usr/okpkg/db/xfce.db"
emerge"libplacebo"
emerge"uchardet"
emerge"mpv"

-- other useful packages
dofile"/usr/okpkg/binary/firefox-nightly.lua"
emerge"opendoas"
emerge"ripgrep"
emerge"alsa-utils"

-- misc post-install
os.execute"udevadm hwdb --usr --update"
os.execute"setcap cap_net_raw+p /usr/bin/ping"
os.execute"makewhatis /usr/share/man"
os.execute"glib-compile-schemas /usr/share/glib-2.0/schemas"
os.execute"fc-cache"
os.execute"gtk-update-icon-cache"
os.execute"update-desktop-database"
os.execute"update-mime-database /usr/share/mime"

-- xfce default terminal
symlink("st", "/usr/bin/xfce4-terminal")

-- rootless xorg
mkdir"/etc/X11"
fp = io.open("/etc/X11/Xwrapper.config", 'w')
fp:write"needs_root_rights = no"
fp:close()
mkdir"/etc/X11/xinit"
fp = io.open("/etc/X11/xinit/xserverrc", 'w')
fp:write [[
#!/bin/sh
exec /usr/bin/Xorg -nolisten tcp "$@" vt1
]]
fp:close()
os.execute"chmod +x /etc/X11/xinit/xserverrc"

-- personal timezone
symlink("/usr/share/zoneinfo/US/Eastern", "/etc/localtime")

-- adduser
os.execute"useradd -m pac && usermod -a -G wheel pac"

-- cleanup
os.execute"rm -fr _*.tar.lz *no"
