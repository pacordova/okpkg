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

--------------
-- Rebuilds --
--------------
local pkgs = {
   "meson", "libxml2", "glib2", "gobject-introspection", "xcb-proto", 
   "pygobject", "pycairo"
}
for _, v in pairs(pkgs) do purge(v); emerge(v) end
