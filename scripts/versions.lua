#!/usr/bin/env lua

require "utils"

-- functions
function curl(url)
    local fd, buf
    fd = io.popen("curl -L '" .. url .. "'")
    buf = fd:read("*a")
    io.close(fd)
    return buf
end

function get_version(filelist, pkgname)
    pkgname = pkgname:gsub("%-", "%%-")
    for i, x in pairs(filelist) do
        if string.find(x, "/" .. pkgname .. "%-") then
            local v = basename(x):match("[._/-][.0-9-]*[0-9][a-z]?")
            if (v ~= nil) then
                return v:gsub("-", "."):gsub("^.", "")
            else
                return "."
            end
        end
    end
end

-- distrowatch
distrowatch = {}
buf = curl("https://distrowatch.com/packages.php")
buf = buf:gsub("Python", "python3")
buf = buf:gsub("lvm", "lvm2")
for w in string.gmatch(buf, 'href="(.-)"') do
    if string.find(w, "%.tar") then
        table.insert(distrowatch, w)
    end
end

-- arch
archlinux = {}
buf1 = curl("https://mirrors.kernel.org/archlinux/core/os/x86_64/")
buf2 = curl("https://mirrors.kernel.org/archlinux/extra/os/x86_64/")
buf3 = curl("https://mirrors.kernel.org/archlinux/community/os/x86_64/")
buf = buf1 .. "\n" .. buf2 .. "\n" .. buf3
for w in string.gmatch(buf, 'href="(.-)"') do
    if string.find(w, "%.tar.zst$") then
        table.insert(archlinux , "/" .. w)
    end
end

-- slackware
slackware = {}
buf = curl(
    "https://mirrors.kernel.org/slackware/slackware64-current/FILELIST.TXT"
)
for w in string.gmatch(buf, '%./(.-)\n') do
    if string.find(w, "%.txz$") then
        table.insert(slackware, w)
    end
end

okpkg = {}

fd = io.popen("cat /usr/okpkg/db/*.db")

for w in string.gmatch(fd:read("*a"), '"(http.-)"') do
    table.insert(okpkg, w)
end

io.close(fd)

-- manually check tzdata
-- worth to check tar mpc bc
packages = {}
fp = io.open("/usr/okpkg/db/base.db")
buf = '\n' .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do
    table.insert(packages, i)
end 

-- print as csv
io.write("package,distrowatch,archlinux,slackware,okpkg\n")
for i=1, #packages do
    local x = packages[i]
    local dw = get_version(distrowatch, x)        
    local al = get_version(archlinux, x)
    local sl = get_version(slackware, x)
    local fp = get_version(okpkg, x)
    io.write(string.format("%s,%s,%s,%s,%s\n", x, dw, al, sl, fp))
end
