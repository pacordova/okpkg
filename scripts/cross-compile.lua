#!/usr/bin/env lua

-- This script is cross compilation of GNU and other tools.
-- It follows LFS closely, but not exactly.
-- https://www.linuxfromscratch.org/lfs/view/stable/index.html

local unpack = unpack or table.unpack

local ok = require("okutils")

local chdir, setenv, mkdir, basename, symlink =
   ok.chdir, ok.setenv, ok.mkdir, ok.basename, ok.symlink

local okdir   = "/usr/okpkg"
local dbpath  = "/usr/okpkg/db"
local distdir = "/var/cache/distfiles"
local tempdir = "/var/tmp/sources"

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

function _db_lookup(x)
   local file, buf, i, j
   x = string.format("\n%s = {", x)
   file = io.popen(string.format("cat %s/*.db", dbpath))
   buf = '\n' .. file:read('*a')
   file:close()
   i = buf:find(x, 1, true) or
       error(string.format("error: %s not found"))
   i = buf:find('{', i, true)
   j = buf:find('};', i, true)
   return load(string.format("return %s", buf:sub(i, j)))()
end

function _xlook(x)
   local file, buf, i, j
   file = io.open(string.format("%s/.cross.db", dbpath))
   buf = '\n' .. file:read('*a')
   file:close()
   i = buf:find(string.format("\n%s = {", x), 1, true)
   if i then i = buf:find('{', i, true); j = buf:find('};', i, true)
      return load(string.format("return %s", buf:sub(i, j)))()
   end
end

function extract(pkgname)
   local t, file, filename
   t = _xlook(pkgname) or _db_lookup(pkgname)
   filename = string.format("%s/%s", distdir, basename(t.url))

   -- Setup the source directory for build.
   chdir(tempdir)
   os.execute(string.format("rm -fr %s", pkgname))
   mkdir(pkgname)

   -- Ensure tarball exists.
   file = io.open(filename)
   if file then file:close() else error("source tarball doesn't exist!") end

   -- Extract the tarball.
   chdir(pkgname)
   os.execute(string.format("tar --strip-components=1 -xf %s", filename))
   chdir("..")

   if pkgname:sub(1,3) == "gcc" then
      extract("gmp")
      os.rename("gmp", string.format("%s/gmp", pkgname))
      extract("mpfr")
      os.rename("mpfr", string.format("%s/mpfr", pkgname))
      extract("libmpc")
      os.rename("libmpc", string.format("%s/mpc", pkgname))
      extract("isl")
      os.rename("isl", string.format("%s/isl", pkgname))
   end

   return t
end

function emerge(pkgname)
   local t = extract(pkgname)
   t.flags = t.flags or {}

   chdir(string.format("%s/%s, tempdir, pkgname)

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
setenv("CFLAGS", "-O2 -fcommon -std=gnu17 -pipe")
setenv("CXXFLAGS", "-O2 -pipe")
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

-- Base filesystem
dofile(string.format("%s/scripts/filesystem.lua", okdir)

-- Build all packages in .cross.db.
local file, buf
file = io.open(string.format("%s/.cross.db", dbpath))
buf = '\n' .. file:read('*a')
file:close()
for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do emerge(i) end
