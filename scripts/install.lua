#!/bin/lua

-- Imports
local unpack = unpack or table.unpack
local ok = require("okutils")
local C = unpack(loadfile("/etc/okpkg.conf")())
local chdir, setenv, mkdir =
   ok.chdir, ok.setenv, ok.mkdir

-- Directories (custom)
local pkgdir = "/var/cache/ok/pkg.new"

-- Environment
if not os.getenv("destdir") then setenv("destdir", "/mnt") end

local function install(x) local fp
   chdir(pkgdir)
   local fp = io.popen(string.format("find * -name '%s-*.tar.lz' | head -1", x))
   os.execute(string.format("tar -C $destdir -xhf %s", fp:read("*a")))
   fp:close()
   if x == "iputils" then
      os.execute("setcap cap_net_raw+p $destdir/bin/ping")
   end
end

-- base package set
if #arg == 0 then arg = {"base"} end
base = { "linux-lts" }
local fp, buf
fp = io.open("db/base")
buf = '\n' .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
    if i:sub(1, 3) == "gcc" then
        table.insert(base, "gcc-libs")
        table.insert(base, "gcc-15.2.0")
    elseif i:sub(1, 1) ~= "_" then
        table.insert(base, i)
    end
end

-- devel package set
devel = {}
local fp, buf
fp = io.open("db/devel")
buf = '\n' .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
   table.insert(devel, i)
end

-- extra libraries
library = {}
local fp, buf
fp = io.open("db/lib")
buf = '\n' .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
   table.insert(library, i)
end

-- network package set
network = {}
local fp, buf
fp = io.open("db/net")
buf = '\n' .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
   table.insert(network, i)
end

-- minimal package set
minimal = {
   "glibc", "zlib", "bzip2", "lzlib", "xz", "zstd", "file", "gmp",
   "mpfr", "attr", "acl", "gcc-libs", "libcap", "shadow", "ncurses",
   "readline", "sed", "pcre2", "grep", "oksh", "expat", "less", "gawk",
   "tzdata", "libxcrypt", "libressl", "kmod", "coreutils", "findutils", "pigz",
   "kbd", "ed", "tar", "lua", "openvi", "eudev", "procps-ng", "util-linux",
   "e2fsprogs", "dinit", "dbus", "libaio", "device-mapper", "parted",
}

-- posix package set
posix = { "dma", "at", "s-nail", "lprng", "pax" }

-- reformat the partition
io.write("Please enter a partition to format: ")
local partition = io.read()
local status =
   os.execute("umount -R -f -q $destdir || ! mountpoint -q $destdir") and
   os.execute(string.format("mkfs.ext4 '%s'", partition)) and
   os.execute(string.format("mount '%s' $destdir", partition))
if not status then error("error during reformat!") end

-- do-install
chdir(os.getenv("destdir"))
dofile("/usr/okpkg/scripts/filesystem.lua")

-- main loop
while #arg > 0 do
   for i=1,#_G[arg[1]] do install(_G[arg[1]][i]) end
   if arg[1] == "minimal" then 
      os.execute [[
         cp -f /bin/okpkg $destdir/bin
         rm -fr $destdir/usr/share/{i18n,pkgconfig}
         rm -fr $destdir/lib64/{pkgconfig,gconv}
         rm -fr $destdir/usr/include
         rm -f  $destdir/lib64/*.[ao]
         rm -f  $destdir/bin/{localedef,ocspcheck,openssl}
         rm -f  $destdir/usr/man/*1/openssl.1
         rm -f  $destdir/usr/man/*8/ocspcheck.8
         rm -f  $destdir/bin/pcre2{grep,test,-config}
         rm -f  $destdir/usr/man/*1/pcre2{grep,test,-config}.1
         rm -fr $destdir/usr/man
      ]]
   end
   table.remove(arg, 1)
end
