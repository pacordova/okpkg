#!/usr/bin/env lua

-- Imports
local unpack = unpack or table.unpack
local C = unpack(loadfile("/etc/okpkg.conf")())
dofile("/usr/bin/okpkg")

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
   "libxml2", "glib2", "gobject-introspection", "xcb-proto", 
   "pygobject", "pycairo", "libtorrent-rasterbar",
}

for _, v in pairs(pkgs) do 
   purge(v); install(string.format("%s/%s-*.tar.lz", C["pkgdir"], v))
end
