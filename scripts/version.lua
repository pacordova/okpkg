#!/usr/bin/env lua

local ok = require"okutils"

local basename = ok.basename

local fd, fp, buf

local function curl(url) local fd, buf
   fd = io.popen(string.format("curl -L '%s'", url))
   buf = fd:read("*a")
   io.close(fd)
   return buf
end

local function vstr(path) local s, i, j
    s = basename(path)
    if s:find("^%d") then i = 0
    elseif s:find("[v._-]%d") then i = s:find("[v._-]%d")
    else return "" end
    j = s:find("%.t") or #s+1
    return s:sub(i+1, j-1):gsub("-", "_")
end

local function getv(t, pkg)
   for i=1,#t do
      if t[i]:match("^" .. pkg .. "%-%d") then return vstr(t[i]) end
   end
   return nil
end

-- list arch package versions
local arch = {}
buf = {}
table.insert(buf, curl"https://mirrors.kernel.org/archlinux/core/os/x86_64/")
table.insert(buf, curl"https://mirrors.kernel.org/archlinux/extra/os/x86_64/")
table.insert(buf, curl"https://mirrors.kernel.org/archlinux/community/os/x86_64/")
buf = table.concat(buf, '\n')
for w in string.gmatch(buf, 'href="(.-)"') do
   if string.find(w, "%.tar.zst$") then
      local s =
         basename(w):gsub(".pkg.tar.zst", ""):
         gsub("%-x86_64", ""):
         gsub("%-any", ""):
         gsub("%-%d+$", ""):
         gsub("1%%3A", ""):
         gsub("2%%3A", ""):
         gsub("%.p", "p"):
         gsub("python%-3", "python3-3"):
         gsub("libnl%-", "libnl3-"):
         gsub("libisl%-", "isl-"):
         gsub("%%2B.*", ""):
         gsub("gcr%-4", "gcr4"):
         gsub("ffnvcodec", "nv-codec")
      table.insert(arch, s)
   end
end

-- list slackware-current package versions
local slackware = {}
buf = curl"https://mirrors.kernel.org/slackware/slackware64-current/FILELIST.TXT"

for w in string.gmatch(buf, '%./(.-)\n') do
   if string.find(w, "%.txz$") then
      local s =
         basename(w):gsub("%-x86_64.-.txz", ""):
         gsub("%-noarch%-%d+", ""):
         gsub("glibc%-zoneinfo%-", "tzdata-"):
         gsub("bash%-completion%-", ""):
         gsub("20201015_cff88dd", "39"):
         gsub("20191011_e8ce9fe", "18"):
         gsub("0.18_20240915", "0.18"):
         gsub(".post1", ""):
         gsub("lvm2%-", "device-mapper-"):
         gsub("gtk%+3%-", "gtk3-")
      table.insert(slackware, s)
   end
end

-- list okpkg package versions
local okpkg = {}
fd = io.popen("find /usr/okpkg/packages/* -name '*.tar.lz' -exec basename '{}' \\;")
buf = fd:read("*a")
fd:close()
fd = io.popen("ls /usr/okpkg/packages/x")
buf = buf .. fd:read("*a")
fd:close()

for w in string.gmatch(buf, '(.-\n)') do
   local s =
      w:gsub("%-x86_64.tar.lz\n", ""):
      gsub("%-amd64.tar.lz\n", ""):
      gsub(".orig", ""):
      gsub("-stable", ""):
      gsub("_GH0", ""):
      gsub("rust%-bin", "rust"):
      gsub("cmake%-bin", "cmake"):
      gsub("nv%-codec%-headers%-n", "nv-codec-headers-")
   table.insert(okpkg, s)
end

-- compare versions for a list of packages
function version(pkglist)
   io.write("package,arch,slackware,okpkg\n")
   for i=1, #pkglist do
      local pkg = pkglist[i]:gsub("%-", "%%-")
      local arch = getv(arch, pkg)
      local slack = getv(slackware, pkg)
      local okpkg = getv(okpkg, pkg)

      -- omit when versions are the same
      if (slack and okpkg ~= slack) or (arch and okpkg ~= arch) then
         io.write(string.format("%s,%s,%s,%s\n", pkglist[i], arch, slack, okpkg))
      end
   end
end

-- get packages to check
fp = io.open("/usr/okpkg/db/system.db")
buf = '\n' .. fp:read('*a')
fp:close()
local pkgs = {}
for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do
   if i:sub(1, 3) == "gcc" then table.insert(pkgs, i:sub(1, 3))
   else table.insert(pkgs, i) end
end

if basename(arg[0]) == "version.lua" then
   version(pkgs)
end
