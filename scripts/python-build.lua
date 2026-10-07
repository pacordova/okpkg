#!/bin/lua

-- Imports
unpack = unpack or table.unpack
local D = dofile("/bin/okpkg")
local ok = require("okutils")

local function install_all(X)
   for de in dir(D["PKGDIR"]) do 
      for j=1,#X do
         if ok.basename(de):sub(1, #X[j]) == X[j] then 
            purge(X[j])
            install(de)
         end
      end
   end
end

-- Build python modules
local fp, buf
fp = io.open(string.format("%s/%s", D["DATADIR"], "python.db"))
buf = '\n' .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do 
   if i ~= "python" then purge(i); emerge(i); end
end

purge("meson")
emerge("meson")

-- Reinstall other packages with python modules
install_all {
   "at-spi2-core",
   "gexiv2",
   "glib2", 
   "gobject-introspection", 
   "libpwquality",
   "libxml2", 
   "passwordsafe",
   "pycairo", 
   "pygobject", 
   "xcb-proto",
}
