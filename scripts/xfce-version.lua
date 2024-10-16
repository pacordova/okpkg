#!/usr/bin/env lua

package.path = "/usr/okpkg/scripts/?.lua;" .. package.path

require("version")

-- List packages
fp = io.popen("cat /usr/okpkg/db/{system,modules,devel,flatpak,gtk,lib,net,video,xorg,xfce}.db")
buf = '\n' .. fp:read("*a")
fp:close()
local pkgs = {}
for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do
    table.insert(pkgs, i)
end

-- extras
table.insert(pkgs, "dbus")
table.insert(pkgs, "opendoas")
table.insert(pkgs, "rust")
table.insert(pkgs, "cmake")

version(pkgs)
