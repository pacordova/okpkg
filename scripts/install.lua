#!/bin/lua

unpack = unpack or table.unpack
ok = require("okutils")
ok.setenv("destdir", "/mnt")

-- Reformat (partition from prompt)
io.write("Please enter a partition/device to format: ")
local dev = io.read()
if not (
   os.execute("umount -R -f -q $destdir || ! mountpoint -q $destdir") and
   os.execute("mkfs.ext4 " .. dev) and
   os.execute(string.format("mount '%s' $destdir", dev)))
then
   error("error: reformat")
end

-- Filesystem
dofile(string.format("%s/%s", ok.dirname(arg[0]), "filesystem.lua"))

-- Install sys
for i in ok.directory_iterator("/var/cache/sys") do
   os.execute("tar -C $destdir -xf " .. i)
end
