#!/usr/bin/env lua

local unpack = unpack or table.unpack

local ok = require("okutils")

local chdir, basename = ok.chdir, ok.basename

mymirror = "https://mirrors.kernel.org"

local function curl(path) 
   local file, buf
   file = io.popen(string.format("curl -L %s/%s", mymirror, path))
   buf = file:read("*a")
   file:close()
   return buf
end

local function parse_version(path) 
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

local function get_version(t, pkg)
   for i=1,#t do
      if t[i]:match("^" .. pkg .. "%-%d") then 
         return parse_version(t[i]) 
      end
   end
   return nil
end

function version(pkglist)
   io.write("package,archlinux,slackware,okpkg\n")
   for i=1, #pkglist do
      local pkgname, row
      pkgname = pkglist[i]:gsub("%-", "%%-")
      row = {
         get_version(archlinux, pkgname),
         get_version(slackware, pkgname),
         get_version(okpkg, pkgname)
      }
      if (row[3] and row[2] and row[3] ~= row[2]) or
         (row[3] and row[1] and row[3] ~= row[1])
      then
         io.write(string.format("%s,%s,%s,%s\n", pkglist[i], unpack(row)))
      end
   end
end

---------------
-- archlinux --
---------------
archlinux = {}
local buf = curl("archlinux/{core,extra,community}/os/x86_64/")

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
      table.insert(archlinux, s)
   end
end

-----------------------
-- slackware-current --
-----------------------
slackware = {}
local buf = curl("slackware/slackware64-current/FILELIST.TXT")

for w in string.gmatch(buf, '%./(.-)\n') do
   if string.find(w, "%.txz$") then
      local s =
         basename(w):gsub("%-x86_64.-.txz", ""):
         gsub("%-noarch%-%d+", ""):
         gsub("glibc%-zoneinfso%-", "tzdata-"):
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

-----------
-- okpkg --
-----------
okpkg = {}
local file, buf

chdir("/var/lib/okpkg/packages")
file = io.popen("find * -name '*.tar.lz' -exec basename '{}' \\;")
buf = file:read("*a")
file:close()

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

--------------
-- main loop -
--------------
pkglist = {}
local file, buf

file = io.popen("cat /var/lib/okpkg/db/*.db")
buf = '\n' .. file:read("*a")
file:close()

for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do
    table.insert(pkglist, i)
end

if basename(arg[0]) == "version.lua" then
   version(pkglist)
end
