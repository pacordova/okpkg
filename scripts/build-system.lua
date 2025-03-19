#!/usr/bin/env lua

local okpath = "/var/lib/okpkg"
local pkgdir = "/var/lib/okpkg/packages"

-- Ensure okpkg is installed
os.execute(string.format("cd %s && make && make install", okpath))

-- Imports
dofile("/usr/bin/okpkg")

local ok = require("okutils")

local chdir, mkdir, symlink =
   ok.chdir, ok.mkdir, ok.symlink

local fp, buf

local function bootstrap_meson()
   download("meson")
   symlink(string.format("%s/sources/meson/meson.py", okpath), "/usr/bin/meson")
   emerge("samurai")
end

-- Generate locales
os.execute("localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true")
os.execute("localedef -i en_US -f UTF-8 en_US.UTF-8")

-- Build core system
fp = io.open(string.format("%s/db/system.db", okpath))
buf = '\n' .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
   if i == "_python" then fp = io.open("/usr/bin/python3")
      if not fp then emerge(i) else fp:close() end
   elseif i == "_perl" then fp = io.open("/usr/bin/perl")
      if not fp then emerge(i) else fp:close() end
   elseif i == "kmod" or i == "dbus" then fp = io.open("/usr/bin/meson")
      if not fp then bootstrap_meson() else fp:close() end emerge(i)
   elseif i:sub(1, 3) == "gcc" then emerge(i)
      os.execute(string.format("%s/scripts/split-gcc.sh", okpath))
   else emerge(i) end
end

-- Rebuilds
emerge("bison")
emerge("gperf")
emerge("glibc")
emerge("binutils")
emerge("mpfr")

-- Fix versions and cleanup
chdir(pkgdir)
mkdir("a")
purge("samurai")
os.execute("makewhatis /usr/share/man")
os.rename("bash-5.2.37-amd64.tar.lz", "bash-5.2.037-amd64.tar.lz")
os.rename("readline-8.2.13-amd64.tar.lz", "readline-8.2.013-amd64.tar.lz")
os.rename("sqlite-3490100-amd64.tar.lz", "sqlite-3.49.1-amd64.tar.lz")
os.execute("mv *.tar.lz a")
os.execute("rm -fr */_*.tar.lz */samurai-*.tar.lz")
