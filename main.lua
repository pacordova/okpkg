#!/usr/bin/env lua

LUA_PATH = "/usr/firepkg/?.lua"

local firepkg = require "functions"

local args = {...}

local cmd = table.remove(args, 1)

local flags = {
    ["-R"] = firepkg.uninstall,
    ["-i"] = firepkg.install,
    ["-S"] = firepkg.emerge,
    ["download"] = firepkg.download,
    ["build"]    = firepkg.build,
    ["makepkg"]  = function(arg) os.execute("/usr/firepkg/scripts/makepkg " .. arg); end,
    ["timesync"] = function() os.execute("/usr/firepkg/scripts/timesync"); end,
    ["backup"]   = function() os.execute("/usr/firepkg/scripts/backup.rc"); end,
    ["chroot"]   = function(arg) os.execute("/usr/firepkg/scripts/chroot " .. arg); end,
}

if #args == 0 then 
    print("zero args")
else
    for i, arg in ipairs(args) do
        flags[cmd](arg)     
    end
end
