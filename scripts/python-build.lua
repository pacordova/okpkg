#!/usr/bin/env lua

-- Imports
unpack = unpack or table.unpack
local C = dofile("/usr/bin/okpkg")
local ok = require("okutils")

local function findpkg(x)
   for f in ok.directory_iterator(C.pkgdir) do
      if ok.basename(f):sub(1, #x) == x then return f end
   end
end

-- Build db/python
local fp, buf
fp = io.open(string.format("%s/db/python", C.okdir))
buf = '\n' .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do 
   if i ~= "python3" then purge(i); emerge(i); end
end

purge"meson"; emerge"meson"

-- Reinstall other packages with python libraries
local X = {
   "libxml2", "glib2", "gobject-introspection", "xcb-proto", 
   "libtorrent-rasterbar", "pygobject", "pycairo",
}

for i=1,#pkgs do install(findpkg(X[i])) end
