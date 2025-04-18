#!/usr/bin/env lua

-- Directories
local pkgdir = "/var/lib/okpkg/packages"
local dbpath = "/var/lib/okpkg/db"

-- Imports
local unpack = unpack or table.unpack
local ok = require("okutils")
local chdir, setenv, mkdir =
   ok.chdir, ok.setenv, ok.mkdir

-- Environment
setenv("destdir", "/mnt")
chdir(dbpath)

local function install(pkgname) local fp
   chdir(pkgdir)
   fp = io.popen(string.format("find * -name '%s-*.tar.lz' | head -1", pkgname))
   os.execute(string.format("tar -C $destdir -xhf %s", fp:read("*a")))
   fp:close()
   if pkgname == "iputils" then
      os.execute"setcap cap_net_raw+p $destdir/usr/bin/ping"
   end
end


-- base package set
if #arg == 0 then arg = {"base"} end
base = { "linux" }
local fp, buf
fp = io.open("system.db")
buf = '\n' .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
    if i:sub(1, 3) == "gcc" then
        table.insert(base, "gcc-libs")
        table.insert(base, "gcc-14.2.0")
    elseif i == "perl" then
        table.insert(base, "perl-5.40.0")
    elseif i:sub(1, 1) ~= "_" then
        table.insert(base, i)
    end
end

-- devel package set
devel = {}
local fp, buf
fp = io.open("devel.db")
buf = '\n' .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
   table.insert(devel, i)
end

-- extra libraries
library = {}
local fp, buf
fp = io.open("lib.db")
buf = '\n' .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
   table.insert(library, i)
end

-- network package set
network = {}
local fp, buf
fp = io.open("net.db")
buf = '\n' .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
   table.insert(network, i)
end

-- minimal package set
minimal = {
   "iana-etc", "glibc", "zlib", "bzip2", "lzlib", "xz", "zstd", "file", "gmp",
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
   os.execute"umount -R -f -q $destdir || ! mountpoint -q $destdir" and
   os.execute(string.format("mkfs.ext4 '%s'", partition)) and
   os.execute(string.format("mount '%s' $destdir", partition))
if not status then error("error during reformat!") end

-- do-install
chdir(pkgdir)
chdir("a")
os.execute [[
   tar -C $destdir -xhf filesystem-*.tar.lz
   git clone /var/lib/okpkg $destdir/var/lib/okpkg
   git -C $destdir/var/lib/okpkg repack -adf --depth=1
   mkdir -p $destdir/var/lib/okpkg/{packages,download}
   cp -p *.tar.lz $destdir/var/lib/okpkg/packages
   cp -p /var/lib/okpkg/download/* $destdir/var/lib/okpkg/download
   rm -fr $destdir/lost+found
   curl -L https://curl.se/ca/cacert.pem > \
       $destdir/etc/ssl/certs/ca-certificates.crt
]]

-- main loop
while #arg > 0 do
   for i=1,#_G[arg[1]] do install(_G[arg[1]][i]) end
   if arg[1] == "minimal" then 
      os.execute [[
         cp -p /var/lib/okpkg/okutils.so $destdir/var/lib/okpkg
         cp -p /usr/bin/okpkg $destdir/usr/bin
         rm -fr $destdir/var/lib/okpkg/{download,packages}
         rm -fr $destdir/usr/share/{i18n,man,pkgconfig}
         rm -fr $destdir/usr/lib64/{*.a,*.o,pkgconfig,gconv}
         rm -fr $destdir/usr/include
         rm -f $destdir/etc/dinit.d/boot.d/*
         rm -f $destdir/usr/bin/localedef
         rm -f $destdir/usr/bin/{pcre2-config,pcre2grep,pcre2test}
         rm -f $destdir/usr/share/man/man1/{pcre2-config,pcre2grep,pcre2test}.1
         rm -f $destdir/usr/bin/{openssl,ocspcheck}
         rm -f $destdir/usr/share/man/man1/openssl.1
         rm -f $destdir/usr/share/man/man8/ocspcheck.8
      ]]
   end
   table.remove(arg, 1)
end
