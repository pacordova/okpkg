#!/usr/bin/env lua

package.path = "/usr/okpkg/scripts/?.lua;" .. package.path

require"version"

-- List packages
fp = io.open"/usr/okpkg/db/xorg.db"
buf = '\n' .. fp:read("*a")
fp:close()
fp = io.open"/usr/okpkg/db/lib.db"
buf = buf .. '\n' .. fp:read("*a")
fp:close()
fp = io.open"/usr/okpkg/db/modules.db"
buf = buf .. '\n' .. fp:read("*a")
fp:close()
fp = io.open"/usr/okpkg/db/xfce.db"
buf = buf .. '\n' .. fp:read("*a")
fp:close()

local pkgs = {}
for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do
    table.insert(pkgs, i)
end

table.insert(pkgs, "nasm")
table.insert(pkgs, "sassc")
table.insert(pkgs, "dbus")
table.insert(pkgs, "dav1d")
table.insert(pkgs, "ffmpeg")
table.insert(pkgs, "libplacebo")
table.insert(pkgs, "mpv")
table.insert(pkgs, "opendoas")
table.insert(pkgs, "ripgrep")
table.insert(pkgs, "alsa-utils")

version(pkgs)
