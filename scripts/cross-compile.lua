#!/bin/lua

-- This script is cross compilation of GNU and other tools.
-- It follows LFS closely, but not exactly.
-- https://www.linuxfromscratch.org/lfs/view/stable/index.html

-- Imports
local unpack = unpack or table.unpack
local ok = require("okutils")
local Dirs = dofile("/etc/okpkg.conf")

B = {
   ["configure"] = function(f, ...)
      local arg = { [0]=f, ... }
      return (
         os.execute(table.concat({arg[0], unpack(arg)}, ' ')) and
         os.execute("$make") and
         os.execute("$make install DESTDIR=/mnt"))
   end,
   ["make"] = function(...)
      local arg = {
         [0]={"$make", "$make install DESTDIR=/mnt"},
         ...
      }
      return (
         os.execute(table.concat({arg[0][1], unpack(arg)}, ' ')) and
         os.execute(table.concat({arg[0][2], unpack(arg)}, ' ')))
   end,
   ["make_noinstall"] = function(...)
      local arg = {
         [0] = "$make",
         ...
      }
      return os.execute(table.concat({arg[0], unpack(arg)}, " "))
   end,
}

function query(x)
   local fp, buf
   x = x:gsub("%-", "%%-")
   fp = io.open(string.format("%s/%s", Dirs.tab, ".cross"))
   buf = "\n" .. fp:read("*a")
   fp:close()
   buf = buf:match("\n" .. x .. "%s*=%s*({.-})%s*;")
   return load("return " .. buf)()
end

function extract(x)
   local X, fp, nm 
   X = query(x)

   -- Setup source directory
   ok.chdir(Dirs.src)
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

   if x:match("pass1") then
      ok.unsetenv("CONFIG_SITE")
   else
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
   os.execute("find /mnt -name \*.la -delete")
end

-- Environment
ok.setenv("CFLAGS", "-O2 -fstack-protector-strong -fstack-clash-protection -ftrivial-auto-var-init=zero -pipe")
ok.setenv("CXXFLAGS", os.getenv("CFLAGS"))
ok.setenv("PATH", "/mnt/tools/bin:/bin")
ok.setenv("LC_ALL", "C")
ok.setenv("make", "/bin/make -j4")
ok.setenv("patch", "/bin/patch -bp1")

-- Filesystem
dofile(string.format("%s/%s", ok.dirname(arg[0]), "mkfs.lua"))

-- Build all packages in .cross
local fp, buf
fp = io.open(string.format("%s/%s", Dirs.tab, ".cross")
buf = "\n" .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do 
   emerge(i) 
end

-- Cleanup
for i in ok.directory_iterator("/mnt/usr/lib64") do
   os.rename(i, i:gsub("/usr", ""))
end
os.remove("/mnt/usr/lib64")
ok.remove_all("/mnt/tools")
ok.remove_all("/mnt/usr/x86_64-unknown-linux-gnu")
