#!/usr/bin/env lua

local firepkg = require "functions"

local args = {...}

local cmd = table.remove(args, 1)

local flags = {
    ["-R"] = firepkg.remove,
    ["-i"] = firepkg.install,
    ["-S"] = firepkg.emerge,
    ["makepkg"]  = firepkg.makepkg,
    ["download"] = firepkg.download,
    ["build"]    = firepkg.build,
    --["timesync"] = firepkg.timesync,
    --["backup"]   = firepkg.backup,
    --["chroot"]   = firepkg.chroot,
}

if #args == 0 then 
    print("zero args")
else
    for i, arg in ipairs(args) do
        flags[cmd](arg)     
    end
end
