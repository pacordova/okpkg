#!/usr/bin/env lua

-------------
-- Imports --
-------------
dofile("/usr/bin/okpkg")

---------------
-- python.db --
---------------
local fp, buf
fp = io.open(string.format("%s/db/python.db", C.okdir)
buf = '\n' .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do 
   if i ~= "python3" then purge(i); emerge(i) end
end

purge("meson")
emerge("meson")

--------------
-- Renstall --
--------------
local pkgs = {
   "libxml2", "glib2", "gobject-introspection", "xcb-proto", 
   "pygobject", "pycairo", "libtorrent-rasterbar",
}
for _, v in pairs(pkgs) do 
   purge(v)
   os.execute(string.format("okpkg install %s/*/%s-*.tar.lz", C.pkgdir, v))
end
