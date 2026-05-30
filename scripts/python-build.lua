#!/bin/lua

-- Imports
unpack = unpack or table.unpack
local C = dofile("/bin/okpkg")
local ok = require("okutils")

local function install_all(X)
   for i in ok.directory_iterator(C.pkgdir) do 
      for j=1,#X do
         if ok.basename(i):sub(1, #X[j]) == X[j] then 
            purge(X[j])
            install(i)
         end
      end
   end
end

-- Build python modules
local fp, buf
fp = io.open(string.format("%s/tab/python", C.okdir))
buf = '\n' .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do 
   if i ~= "python" then purge(i); emerge(i); end
end

purge("meson")
emerge("meson")

-- Reinstall other packages with python libraries
-- "libxml2", "glib2", "gobject-introspection", "xcb-proto", 
-- "libtorrent-rasterbar", "pygobject", "pycairo",

install_all {
   "libxml2", 
   "glib2", 
   "gobject-introspection", 
   "xcb-proto",
   "pygobject", 
   "pycairo", 
   "libtorrent-rasterbar"
}
