#!/bin/lua

ok = require("okutils")

-- Filesystem
dofile(string.format("%s/%s", ok.dirname(arg[0]), "mkfs.lua"))

-- Install sys
for it in ok.directory_iterator("/var/cache/sys") do
   os.execute("tar -C /mnt -xf " .. it)
end
