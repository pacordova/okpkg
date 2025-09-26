#!/usr/bin/env lua

-------------
-- Imports --
-------------
dofile("/usr/bin/okpkg")
local dbpath = "/var/lib/okpkg/db/python.db"

---------------
-- python.db --
---------------
local fp, buf
fp = io.open(dbpath)
buf = '\n' .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do 
   if i ~= "python3" then purge(i); emerge(i) end
end

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
   os.execute(string.format("okpkg install /var/lib/okpkg/packages/*/%s-*.tar.lz", v))
end
