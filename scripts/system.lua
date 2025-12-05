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

local file, buf

-- Generate locales
os.execute("localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true")
os.execute("localedef -i en_US -f ISO-8859-1 en_US")
os.execute("localedef -i en_US -f UTF-8 en_US.UTF-8")

-- Bootstrap meson
download("meson")
symlink(string.format("%s/sources/meson/meson.py", okpath), "/usr/bin/meson")
emerge("samurai")

-- Build core system
file = io.open(string.format("%s/db/system.db", okpath))
buf = '\n' .. file:read("*a")
file:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
   emerge(i)
   if i:sub(1, 3) == "gcc" then
      os.execute(string.format("%s/scripts/split-gcc.sh", okpath))
   end
end

-- Rebuilds for reproducibility
rebuilds = { "binutils", "bison", "glibc", "gperf", "mpfr" }
for i=1,#rebuilds do emerge(rebuilds[i]) end

-- Fix versions and cleanup
chdir(pkgdir)
purge("_perl")
purge("_python3")
purge("samurai")
os.remove("samurai-1.2-amd64.tar.lz")
os.remove("/usr/bin/meson")
os.rename("bash-5.3-amd64.tar.lz", "bash-5.3.003-amd64.tar.lz")
os.rename("readline-8.3-amd64.tar.lz", "readline-8.3.001-amd64.tar.lz")
mkdir("a")
os.execute([[
   makewhatis /usr/share/man
   rm -fr _*.tar.lz
   mv *.tar.lz a
]])
