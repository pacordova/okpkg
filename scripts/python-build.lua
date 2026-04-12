#!/usr/bin/env lua

-- Imports
unpack = unpack or table.unpack
local C = dofile("/usr/bin/okpkg")

-- Build db/python
local fp, buf
fp = io.open(string.format("%s/db/python", C["okdir"]))
buf = '\n' .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do 
   if i ~= "python3" then purge(i); emerge(i); end
end

purge("meson"); emerge("meson");

-- Reinstall other packages with python libraries
local pkgs = {
   "meson", "libxml2", "glib2", "gobject-introspection", "xcb-proto", 
   "pygobject", "pycairo", "libtorrent-rasterbar",
}

for i=1,#pkgs do purge(pkg[i]); emerge(pkg[i]); end
install(string.format("%s/libtorrent-rasterbar-2.0.12-amd64.tar.lz", C.pkgdir))
