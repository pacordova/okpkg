#!/bin/lua

-- This script is cross compilation of GNU and other tools.
-- It follows LFS closely, but not exactly.
-- https://www.linuxfromscratch.org/lfs/view/stable/index.html

-- Imports
local unpack = unpack or table.unpack
local ok = require("okutils")
local Dirs = dofile("/etc/okpkg.conf")

B = {
   ["cmake"] = function(...)
      local arg = {
         [0] = "$cmake -B build -G Ninja -Wno-dev",
         "-DCMAKE_TOOLCHAIN_FILE=/etc/cross.cmake",
         "-DCMAKE_BUILD_TYPE=Release",
         "-DCMAKE_INSTALL_PREFIX=/usr",
         "-DCMAKE_INSTALL_LIBDIR=../lib64",
         "-DCMAKE_INSTALL_{,S}BINDIR=../bin",
         "-DCMAKE_INSTALL_RUNSTATEDIR=/run",
         "-DCMAKE_SHARED_LIBS=True",
         "-DCMAKE_SKIP_RPATH=TRUE",
         ...
      }
      return (
         os.execute(table.concat({arg[0], unpack(arg)}, " ")) and
         os.execute("DESTDIR=/mnt $ninja -C build install"))
   end,
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

function query(x, tab)
   local i, fp, buf
   fp = io.open(Dirs.tabs .. "/" .. tab)
   buf = "\n" .. fp:read("*a")
   fp:close()
   i = buf:find("\n" .. x .. " =", 1, true)
   buf = buf:sub(buf:find("{", i, true), buf:find("};", i, true))
   return load("return " .. buf)()
end

function extract(x)
   local X, fp
   
   -- lookup fixes
   if x == "libstdcxx" then 
      X = query("gcc16", "sys")
   elseif x:sub(1,1) == "_" then
      X = query(x:sub(2,#x), "sys")
   else
      X = query(x, "sys")
   end

   X.dist = string.format("%s/%s", Dirs.distfiles, ok.basename(X.url))

   -- Setup source directory
   assert(
      ok.chdir(Dirs.src) and
      ok.remove_all(x) and
      ok.mkdir(x) and
      ok.chdir(x) and
      os.execute("tar --strip-components=1 -xf " .. X.dist))
   
   return x
end

function build(x)
   local X = query(x, "cross")
   X.flags = X.flags or {}

   if x:sub(1,1) == "_" then
      ok.unsetenv("CONFIG_SITE")
   else
      ok.setenv("CONFIG_SITE", "/etc/config.site")
      ok.setenv("LIBRARY_PATH", "/mnt/lib64")
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
   os.execute("find /mnt -name '*.la' -delete")
end


-- Environment
ok.setenv("CFLAGS", "-O2 -fstack-protector-strong -fstack-clash-protection -ftrivial-auto-var-init=zero -pipe")
ok.setenv("CXXFLAGS", os.getenv("CFLAGS"))
ok.setenv("PATH", "/mnt/tools/bin:/bin")
ok.setenv("LC_ALL", "C")
ok.setenv("make", "/bin/make -j4")
ok.setenv("patch", "/bin/patch -bp1")
ok.setenv("cmake", "/opt/cmake/bin/cmake")
ok.setenv("ninja", "/bin/samu")

-- Filesystem
dofile(string.format("%s/%s", ok.dirname(arg[0]), "mkfs.lua"))

-- Build all packages in cross
local fp, buf
fp = io.open(string.format("%s/%s", Dirs.tabs, "cross"))
buf = "\n" .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n([%w%-%_]-) = {.-;") do
   build(extract(i))
end

-- Cleanup
for it in ok.directory_iterator("/mnt/usr/lib64") do
   os.rename(it, it:gsub("/usr", ""))
end
os.remove("/mnt/usr/lib64")
ok.remove_all("/mnt/tools")
ok.remove_all("/mnt/usr/lib")
ok.remove_all("/mnt/usr/x86_64-unknown-linux-gnu")
