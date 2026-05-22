#!/bin/lua

-- This script is cross compilation of GNU and other tools.
-- It follows LFS closely, but not exactly.
-- https://www.linuxfromscratch.org/lfs/view/stable/index.html

-- Imports
local unpack = unpack or table.unpack
local ok = require("okutils")
local C, M, E = dofile("/etc/okpkg.conf")

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

function query(x)
   local fp, buf
   x = x:gsub("%-", "%%-")
   fp = io.open(string.format("%s/db/.cross", C.okdir))
   buf = "\n" .. fp:read("*a")
   fp:close()
   buf = buf:match("\n?[^%w_]" .. x .. "%s*=%s*({.-})%s*;")
   return load("return " .. buf)()
end

function extract(x)
   local X, fp, nm 
   X = query(x)

   -- Setup source directory
   ok.chdir(C.workdir)
   ok.remove_all(x)
   ok.mkdir(x)
   ok.chdir(x)

   -- Extract 
   fp = io.open(X.fs)
   if fp then
      fp:close()
      os.execute("tar --strip-components=1 -xf " .. X.fs)
   else
      error("error: extract: source tarball does not exist!")
   end

   return X 
end

function emerge(x)
   local X = extract(x)
   X.flags = X.flags or {}

   -- Environment
   if x:match("pass1") then
      ok.setenv("CC",  "/bin/gcc")
      ok.setenv("CXX", "/bin/g++")
      ok.unsetenv("CONFIG_SITE")
   else
      ok.setenv("CC",          "/mnt/tools/bin/x86_64-unknown-linux-gnu-gcc")
      ok.setenv("CXX",         "/mnt/tools/bin/x86_64-unknown-linux-gnu-g++")
      ok.setenv("AR",          "/mnt/tools/bin/x86_64-unknown-linux-gnu-ar")
      ok.setenv("RANLIB",      "/mnt/tools/bin/x86_64-unknown-linux-gnu-ranlib")
      ok.setenv("CONFIG_SITE", "/etc/config.site")
   end

   if X.prep then os.execute(X.prep) end

   if B[X.build] then
      if not B[X.build](unpack(X.flags)) then
         error(string.format("error: build: %s: %s", X.build, x))
      end
   elseif tostring(X.build):match("config") then
      -- Check if we are doing an out of tree build.
      if tostring(X.build):sub(1, 2) == ".." then
         ok.mkdir("build") 
         ok.chdir("build")
      end
      if not B["configure"](X.build, unpack(X.flags)) then
         error(string.format("error: build: %s: %s", X.build, x))
      end
   end

   if X.post then os.execute(X.post) end
   os.execute([[ 
      find $destdir -name \*.la -delete 
   ]])
end

-- Setup the environment.
ok.setenv("CFLAGS", "-O2 -fcommon -std=gnu17 -pipe")
ok.setenv("CXXFLAGS", "-O2 -pipe")
ok.setenv("PATH", "/mnt/tools/bin:/bin")
ok.setenv("LC_ALL", "C")
ok.setenv("MAKEFLAGS", "-j5")
ok.setenv("patch", "patch -b -p1")
ok.setenv("destdir", "/mnt")

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
dofile(C.okdir .. "/scripts/filesystem.lua")

-- Build all packages in $okdir/db/.cross
local fp, buf
fp = io.open(C.okdir .. "/db/.cross")
buf = "\n" .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do 
   emerge(i) 
end

-- Cleanup
--ok.chdir(os.getenv("destdir"))
--ok.remove_all("./usr/lib")
--ok.remove_all("./usr/lib64")
--ok.remove_all("./x86_64-unknown-linux-gnu")
--os.remove("./lib")
--os.remove("./sbin")
