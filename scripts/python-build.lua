#!/bin/lua

-- Imports
unpack = unpack or table.unpack
local Dirs = dofile("/bin/okpkg")
local ok = require("okutils")

local function install_all(X)
   for it in ok.directory_iterator(Dirs.packages) do 
      for j=1,#X do
         if ok.basename(it):sub(1, #X[j]) == X[j] then 
            purge(X[j])
            install(it)
         end
      end
   end
end

-- Build python modules
local fp, buf
fp = io.open(string.format("%s/%s", Dirs.tab, "python"))
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
   "at-spi2-core",
   "gexiv2",
   "glib2", 
   "gobject-introspection", 
   "libpwquality",
   "libtorrent-rasterbar",
   "libxml2", 
   "passwordsafe",
   "pycairo", 
   "pygobject", 
   "xcb-proto",
}
