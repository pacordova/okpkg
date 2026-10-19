#!/bin/lua

-- Imports
unpack = unpack or table.unpack
local cfg = require("okconfig")
local ok  = require("okutils")

dofile("/bin/okpkg")

-- Build python modules
local fp, buf
fp = io.open(string.format("%s/%s", cfg.datadir, "python.db"))
buf = '\n' .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n   %[\"(.-)\"%]") do
   if i ~= "python" then 
      purge(i)
      emerge(i)
   end
end

purge("meson")
emerge("meson")

-- Reinstall other packages with python modules
tbl = {
   "at-spi2-core",
   "gexiv2",
   "glib",
   "gobject-introspection", 
   "libpwquality",
   "libxml2", 
-- "passwordsafe",
   "pycairo", 
   "pygobject", 
   "xcb-proto",
}

ok.chdir(cfg.pkgdir)
for de in dir(".") do
   for i=1,#tbl do
      if string.sub(de, 1, #tbl[i]) == tbl[i] then
         purge(tbl[i])
         install(de)
      end
   end
end
