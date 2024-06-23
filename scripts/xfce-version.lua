#!/usr/bin/env lua

local ok = require"okutils"

local basename = ok.basename

local fd, fp, buf

local function curl(url)
    local fd, buf
    fd = io.popen("curl -L '" .. url .. "'")
    buf = fd:read("*a")
    io.close(fd)
    return buf
end

local function vstr(path)
    local s, i, j
    s = basename(path)

    if s:find("^%d") then 
        i = 0
    elseif s:find("[v._-]%d") then
        i = s:find("[v._-]%d") 
    else
        return ""
    end

    j = s:find("%.t") or #s+1

    return s:sub(i+1, j-1):gsub("-", "_")
end

local function getv(t, pkg)
    for i=1,#t do
        if t[i]:match("^" .. pkg .. "%%-") then
            return vstr(t[i])
        elseif t[i]:gsub("^", "xorg-"):match("^" .. pkg .. "%%-") then
            return vstr(t[i])
        end
    end
    return nil
end

-- List packages
fp = io.open"/usr/okpkg/db/xorg.db"
buf = '\n' .. fp:read("*a")
fp:close()

local pkgs = {}
for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do
    table.insert(pkgs, i)
end

fp = io.open"/usr/okpkg/db/xfce.db"
buf = '\n' .. fp:read("*a")
fp:close()

for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do
    table.insert(pkgs, i)
end


local arch = {}
buf = {}

table.insert(buf, curl"https://mirrors.kernel.org/archlinux/core/os/x86_64/")
table.insert(buf, curl"https://mirrors.kernel.org/archlinux/extra/os/x86_64/")
table.insert(buf, curl"https://mirrors.kernel.org/archlinux/community/os/x86_64/")

buf = table.concat(buf, '\n')

for w in string.gmatch(buf, 'href="(.-)"') do
    if string.find(w, "%.tar.zst$") then
        local s
        s = basename(w):gsub(".pkg.tar.zst", "")
        s = s:gsub("%-x86_64", "")
        s = s:gsub("%-any", "")
        s = s:gsub("%-%d+$", "")
        s = s:gsub("1%%3A", "")
        s = s:gsub("2%%3A", "")
        s = s:gsub("%.p", "p")
        s = s:gsub("python%-", "python3-")
        s = s:gsub("libnl%-", "libnl3-")
        s = s:gsub("libisl%-", "isl-")
        s = s:gsub("vulkan%-icd", "vulkan-")
        table.insert(arch , s)
    end
end

local slackware = {}
buf = 
    curl"https://mirrors.kernel.org/slackware/slackware64-current/FILELIST.TXT"

for w in string.gmatch(buf, '%./(.-)\n') do
    if string.find(w, "%.txz$") then
        local s
        s = basename(w):gsub("%-x86_64.-.txz", "")
        s = s:gsub("%-noarch%-%d+", "")
        s = s:gsub("glibc%-zoneinfo%-", "tzdata-")
        s = s:gsub("bash%-completion%-", "")
        table.insert(slackware, s)
    end
end

local okpkg = {}

fd = io.popen("ls /usr/okpkg/packages/x")
buf = fd:read("*a")
for w in string.gmatch(buf, '(.-\n)') do
    local s = w:gsub("%-x86_64.tar.lz\n", "")
    s = s:gsub(".orig", "")
    s = s:gsub("-stable", "")
    s = s:gsub("_GH0", "")
    table.insert(okpkg, s)
end
io.close(fd)

-- print as csv
io.write("package,arch,slackware,okpkg\n")
for i=1, #pkgs do
   local pkg = pkgs[i]:gsub("%-", "%%-")
   local arch = getv(arch, pkg)
   local slack = getv(slackware, pkg)
   local okpkg = getv(okpkg, pkg)
    
   -- omit when versions are the same
   if (slack and okpkg ~= slack) or (arch and okpkg ~= arch) then
      io.write(string.format("%s,%s,%s,%s\n", pkgs[i], arch, slack, okpkg))
   end
end
