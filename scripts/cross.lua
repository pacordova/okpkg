#!/bin/lua

-- This script is cross compilation of GNU and other tools.
-- It follows LFS closely, but not exactly.
-- https://www.linuxfromscratch.org/lfs/view/stable/index.html

-- Imports
ok  = require("okutils")
cfg = require("okconfig")

unpack = unpack or table.unpack

local __rc = {
   __concat = function(x, y)
      for i=1,#y do table.insert(x, y[i]) end
      return x
   end,
   __tostring = function(tbl)
      return table.concat(tbl, ' ')
   end,
   __call = function(self, ...)
      return os.execute(tostring(self .. {...})
   end,
}

rc = {
   ["cmake"] = function(...)
      local arg = setmetatable({}, __rc)
      table.insert(tbl, "cmake")
      table.insert(tbl, "-Bbuild")
      table.insert(tbl, "cmake")
      table.insert(tbl, "-Bbuild")
      table.insert(tbl, "-DCMAKE_BUILD_TYPE=Release")
      table.insert(tbl, "-DCMAKE_INSTALL_BINDIR=/bin")
      table.insert(tbl, "-DCMAKE_INSTALL_LIBDIR=/lib64")
      table.insert(tbl, "-DCMAKE_INSTALL_PREFIX=/")
      table.insert(tbl, "-DCMAKE_INSTALL_RUNSTATEDIR=/run")
      table.insert(tbl, "-DCMAKE_INSTALL_RUNSTATEDIR=/run")
      table.insert(tbl, "-DCMAKE_INSTALL_SBINDIR=../bin")
      table.insert(tbl, "-DCMAKE_INSTALL_SBINDIR=/bin")
      table.insert(tbl, "-DCMAKE_SHARED_LIBS=True")
      table.insert(tbl, "-DCMAKE_SKIP_RPATH=TRUE")
      table.insert(tbl, "-GNinja")
      table.insert(tbl, "-Wno-dev")
      return tbl(...) and rc.ninja()
   end,
   ["configure"] = function(...)
      return ok.exec(
         "sh",
         ok.exists("configure") or
         ok.exists("../configure"),
         ...
      ) and rc.make()
   end,
   ["make"] = function(...)
      return rc.make_all(...) and rc.make_install(...)
   end,
   ["make_all"] = function(...)
      return ok.exec("make", ...)
   end,
   ["make_install"] = function(...)
      return (
         ok.setenv("DESTDIR", "/mnt") and
         ok.exec("make", "install", ...) and
         ok.unsetenv("DESTDIR"))
   end,
   ["ninja"] = function()
      return (
         ok.setenv("DESTDIR", "/mnt") and
         os.execute("ninja -C build install") and
         ok.unsetenv("DESTDIR"))
   end,
}

function query(x, db)
   local i, fp, buf
   fp = io.open(string.format("%s/%s", cfg.datadir, db))
   buf = "\n" .. fp:read("*a")
   fp:close()
   i = buf:find("\n" .. x .. " =", 1, true)
   buf = buf:sub(buf:find("{", i, true), buf:find("};", i, true))
   return load("return " .. buf)()
end

function snarf(x)
   local t, fp
   
   -- lookup fixes
   if x == "libstdcxx" then 
      t = query("gcc15", "sys.db")
   elseif x:sub(1,1) == "_" then
      t = query(x:sub(2,#x), "sys.db")
   else
      t = query(x, "sys.db")
   end

   t.dist = string.format("%s/%s", cfg.distdir, ok.basename(t.url))

   -- Setup source directory
   ok.chdir(cfg.wrkobjdir)
   ok.remove_all(x)
   ok.mkdir(x) 
   ok.chdir(x)
   os.execute("tar --strip=1 -xf " .. t.dist)

   -- Patch if file exists
   fp = io.open(string.format("%s/patches/%s.diff", cfg.basedir, x))
   if fp then
      io.popen("patch -p 1", "w"):write(fp:read("*a")):close()
      fp:close()
   end

   return x
end

function build(x)
   local t = query(x, "cross.db")
   t.flags = t.flags or {}

   if x:sub(1,1) == "_" then
      ok.unsetenv("CONFIG_SITE")
   else
      ok.setenv("CONFIG_SITE", "/etc/config.site")
      ok.setenv("LIBRARY_PATH", "/mnt/lib64")
   end

   if t.prep and not os.execute(t.prep) then
      error(string.format("error: build: prep: %s", x))
   end

   if not t.build(unpack(t.flags)) then
      error(string.format("error: build: %s: %s", t.build, x))
   end

   if t.post and not os.execute(t.post) then
      error(string.format("error: build: post: %s", x))
   end

   os.execute("find /mnt -name '*.la' -delete")
end


-- Environment
ok.setenv("CFLAGS", "-O2 -fstack-protector-strong -fstack-clash-protection -ftrivial-auto-var-init=zero -pipe")
ok.setenv("CXXFLAGS", os.getenv("CFLAGS"))
ok.setenv("PATH", "/mnt/tools/bin:/bin")
ok.setenv("LC_ALL", "C")
ok.setenv("make", "/bin/make -j4")
ok.setenv("patch", "/bin/patch -p1")

-- Filesystem
dofile(string.format("%s/%s", ok.dirname(arg[0]), "mkfs.lua"))

-- CMAKE_TOOLCHAIN_FILE
ok.setenv("CMAKE_TOOLCHAIN_FILE", os.tmpname())
fp = io.open(os.getenv("CMAKE_TOOLCHAIN_FILE"), "w")
fp:write([[
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_C_COMPILER   x86_64-unknown-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER x86_64-unknown-linux-gnu-g++)
set(CMAKE_FIND_ROOT_PATH /mnt)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
]])
fp:close()

-- Build all packages in cross.db
local fp, buf
fp = io.open(string.format("%s/%s", cfg.datadir, "cross.db"))
buf = "\n" .. fp:read('*a')
fp:close()
for i in buf:gmatch("\n([%w%-%_]-) = {.-;") do
   build(snarf(i))
end

-- Cleanup
for it in dir("/mnt/usr/lib64") do
   os.rename(it, it:gsub("/usr", ""))
end
os.remove("/mnt/usr/lib64")
ok.remove_all("/mnt/tools")
ok.remove_all("/mnt/usr/lib")
ok.remove_all("/mnt/usr/x86_64-unknown-linux-gnu")
