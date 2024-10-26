#!/usr/bin/env lua

-- This script is cross compilation of GNU and other tools.
-- It follows LFS closely, but not exactly.
-- https://www.linuxfromscratch.org/lfs/view/stable/index.html

local unpack = unpack or table.unpack

local ok = require"okutils"

local chdir, setenv, mkdir, basename, symlink =
   ok.chdir, ok.setenv, ok.mkdir, ok.basename, ok.symlink

B = {
   ["configure"] = function(f, ...)
      local arg = { [0]=f, ... }
      return (
         os.execute(table.concat({arg[0], unpack(arg)}, ' ')) and
         os.execute("make") and
         os.execute("make install DESTDIR=$destdir"))
   end,
   ["make"] = function(...)
      local arg = { 
         [0]={"make", "make install DESTDIR=$destdir"}, 
         ... 
      }
      return (
         os.execute(table.concat({arg[0][1], unpack(arg)}, ' ')) and
         os.execute(table.concat({arg[0][2], unpack(arg)}, ' ')))
   end,
}


local function vlook(pkgname) local fp, buf, i, j
   fp = io.open("/var/lib/okpkg/db/.cross.db")
   buf = '\n' .. fp:read('*a')
   fp:close()
   i = buf:find(string.format("\n%s = {", pkgname), 1, true)
   if i then i = buf:find('{', i, true); j = buf:find('};', i, true)
      return load(string.format("return %s", buf:sub(i, j)))()
   end
end

local function get_url(pkgname) local fp, buf, i, j
   pkgname = pkgname:gsub("gcc%-.*", "gcc%%d+")
   pkgname = pkgname:gsub("binutils%-.*", "binutils")
   pkgname = pkgname:gsub("%-", "%%-")
   fp = io.open("/var/lib/okpkg/db/system.db")
   buf = '\n' .. fp:read('*a')
   fp:close()
   i = buf:find(string.format("\n%s = {", pkgname), 1)
   if i then i = buf:find('"', i); j = buf:find('"', i+1)-1
      return buf:sub(i, j)
   end
end

local function extract(pkgname) 
   local t, f, fp
   t = vlook(pkgname)
   f = basename(get_url(pkgname))

   -- Setup the source directory for build.
   chdir("/var/lib/okpkg/sources")
   os.execute("rm -fr " .. pkgname)
   mkdir(pkgname)

   -- Ensure tarball exists.
   fp = io.open(string.format("../download/%s", f))
   if fp then fp:close() else error("source tarball doesn't exist!") end

   -- Extract the tarball.
   os.execute(string.format(
      "tar -C %s --strip-components=1 -xf ../download/%s", pkgname, f))

   if pkgname:sub(1,3) == "gcc" then
      extract"gmp"; extract"mpfr"; extract"libmpc"; extract"isl"
      os.rename("gmp", string.format("%s/gmp", pkgname))
      os.rename("mpfr", string.format("%s/mpfr", pkgname))
      os.rename("libmpc", string.format("%s/mpc", pkgname))
      os.rename("isl", string.format("%s/isl", pkgname))
   end

   return t
end

local function emerge(pkgname) 
   local t = extract(pkgname)
   t.flags = t.flags or {}

   chdir("/var/lib/okpkg/sources/" .. pkgname)

   if t.prepare then os.execute(t.prepare) end

   if B[t.build] then
      if not B[t.build](unpack(t.flags)) then 
         error(string.format("error: build: %s: %s", t.build, x))
      end
   elseif tostring(t.build):match("config") then
      -- Check if we are doing an out of tree build.
      if tostring(t.build):sub(1, 2) == ".." then 
         mkdir("build") 
         chdir("build") 
      end
      if not B["configure"](t.build, unpack(t.flags)) then
         error(string.format("error: build: %s: %s", t.build, x))
      end
   end

   if t.post then os.execute(t.post) end
   os.execute"find $destdir -name '*.la' -delete"
end

-- Setup the environment.
setenv("CFLAGS", "-O2 -fcommon -pipe")
setenv("CXXFLAGS", os.getenv("CFLAGS"))
setenv("PATH", "/mnt/tools/bin:/usr/bin:/usr/sbin")
setenv("LC_ALL", "POSIX")
setenv("MAKEFLAGS", "-j5")
setenv("patch", "patch -b -p1")
setenv("destdir", "/mnt")

-- Reformat the partition specified at command line.
io.write("Please enter a partition/device to format: ")
local dev = io.read()
if not (
   os.execute("umount -R -f -q $destdir || ! mountpoint -q $destdir") and
   os.execute("mkfs.ext4 " .. dev) and
   os.execute(string.format("mount '%s' $destdir", dev)))
then
   error("error: reformat")
end

-- Install filesystem and kernel-headers.
-- Cross compile needs lib symlinks.
chdir(os.getenv("destdir"))
os.execute("tar -xhf /var/lib/okpkg/packages/a/filesystem-*.tar.lz")
os.execute("tar -xhf /var/lib/okpkg/packages/a/linux-*.tar.lz")
symlink("lib64", "usr/lib")
symlink("usr/lib", "lib")

-- Build all packages in /var/lib/okpkg/db/.cross.db.
local fp, buf
fp = io.open("/var/lib/okpkg/db/.cross.db")
buf = '\n' .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do emerge(i) end

chdir("/var/lib/okpkg/packages/a")
os.execute [[
   git clone /var/lib/okpkg $destdir/var/lib/okpkg
   git -C $destdir/var/lib/okpkg repack -adf --depth=1
   mkdir -p $destdir/var/lib/okpkg/{packages,download}
   cp -p linux-*.tar.lz filesystem*.tar.lz $destdir/var/lib/okpkg/packages
   cp -p /var/lib/okpkg/download/* $destdir/var/lib/okpkg/download
   curl -L https://curl.se/ca/cacert.pem > \
       $destdir/etc/ssl/certs/ca-certificates.crt
   rm -fr $destdir/{lost+found,tools,lib} $destdir/usr/{lib,libexec,var}
]]
