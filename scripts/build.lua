#!/bin/lua

-- Bootstrap
os.execute("make -C"..arg[0]:gsub("[^/]-$","..").." install")

-- Imports
dofile("/bin/okpkg")
local Dirs = dofile("/etc/okpkg.conf")
local ok = require("okutils")

-- Generate locales
os.execute("localedef -i POSIX -f ASCII      C           2>/dev/null ||:")
os.execute("localedef -i POSIX -f UTF-8      C.UTF-8     2>/dev/null ||:")
os.execute("localedef -i en_US -f ISO-8859-1 en_US       2>/dev/null ||:")
os.execute("localedef -i en_US -f UTF-8      en_US.UTF-8 2>/dev/null ||:")

local fp, buf
fp = io.open(string.format("%s/%s", Dirs.tabs, "sys"))
buf = "\n" .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
   emerge(i)
end

-- devel
emerge("samurai")

-- Fix versions and cleanup
os.execute("makewhatis /usr/share/man")
ok.chdir(Dirs.packages)
--os.rename("bash-5.3-amd64.tar.lz", "bash-5.3.009-amd64.tar.lz")
--os.rename("readline-8.3-amd64.tar.lz", "readline-8.3.003-amd64.tar.lz")
--ok.mkdir("a")
