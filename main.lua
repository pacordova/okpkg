#!/usr/bin/env lua

local firepkg = require "functions"

local args = {...}

local flag = table.remove(args, 1)

if #args == 0 then 
    print("zero args")
else
    for i, pkgname in ipairs(args) do
        if flag == "-S" then
            firepkg.uninstall(pkgname)
            firepkg.download(pkgname)
            firepkg.install(firepkg.build(pkgname))
        end
        if flag == "-R" then
            firepkg.uninstall(pkgname)
        end
        if flag == "-i" then
            firepkg.install(pkgname)
        end
        if flag == "makepkg" then
            firepkg.makepkg(pkgname)
        end
        if flag == "download" then
            firepkg.download(pkgname)
        end
        if flag == "build" then
            firepkg.build(pkgname)
        end
    end
end
