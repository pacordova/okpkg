#!/usr/bin/env lua

local okpath = "/var/lib/okpkg"
local dbpath = "/var/lib/okpkg/db"
local pkgdir = "/var/lib/okpkg/packages"

-- Ensure okpkg is installed
os.execute(string.format("cd %s && make && make install", okpath))

-- Imports
dofile("/usr/bin/okpkg")

local ok = require("okutils")

local chdir, mkdir, symlink =
   ok.chdir, ok.mkdir, ok.symlink

local fp, buf

-- Generate locales
os.execute("localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true")
os.execute("localedef -i en_US -f UTF-8 en_US.UTF-8")

-- core system
fp = io.open(string.format("%s/system.db", dbpath))
buf = '\n' .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
   if i == "_python" then fp = io.open("/usr/bin/python3")
      if not fp then emerge(i) else fp:close() end
   elseif i == "_perl" then fp = io.open("/usr/bin/perl")
      if not fp then emerge(i) else fp:close() end
   elseif i:sub(1, 3) == "gcc" then
      emerge(i)
      os.execute(string.format("%s/scripts/split-gcc.sh", okpath))
   else emerge(i) end
end

-- rebuilds
emerge("bison")
emerge("gperf")
emerge("glibc")
emerge("binutils")
emerge("mpfr")

-- misc post-install
os.execute("makewhatis /usr/share/man")

-- fix versions and cleanup
chdir(pkgdir)
mkdir("a")
os.rename("bash-5.2.32-amd64.tar.lz", "bash-5.2.032-amd64.tar.lz")
os.rename("readline-8.2.13-amd64.tar.lz", "readline-8.2.013-amd64.tar.lz")
os.rename("sqlite-3460100-amd64.tar.lz", "sqlite-3.46.1-amd64.tar.lz")
os.execute("mv *.tar.lz a")
os.execute("rm -fr */_*.tar.lz")
