-- Imports
local unpack = unpack or table.unpack
local C = unpack(loadfile("/etc/okpkg.conf")())
local ok = require("okutils")

local mkdir, symlink, pwd = 
   ok.mkdir, ok.symlink, ok.pwd

local pwd = pwd()

local dirs = {
   ["indexdir"] = "index",
   ["pkgdir"]   = "packages",
   ["workdir"]  = "sources",
   ["distdir"]  = "distfiles"
}

for k,v in pairs(dirs) do
   local f = io.open(v)
   if f then
      f:close()
   elseif C[k] == string.format("%s/%s", pwd, v) then
      mkdir(v)
   else
      symlink(C[k], v)
   end
end
