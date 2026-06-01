#!/bin/lua

-- Bootstrap
os.execute("make -C"..arg[0]:gsub("[^/]-/[^/]-$","").." install")

-- Imports
dofile("/bin/okpkg")
local Dirs = dofile("/etc/okpkg.conf")
local ok = require("okutils")

-- Generate locales
os.execute("localedef -i POSIX -f ASCII      C           2>/dev/null ||:")
os.execute("localedef -i POSIX -f UTF-8      C.UTF-8     2>/dev/null ||:")
os.execute("localedef -i en_US -f ISO-8859-1 en_US       2>/dev/null ||:")
os.execute("localedef -i en_US -f UTF-8      en_US.UTF-8 2>/dev/null ||:")

-- Build core system
local fp, buf
fp = io.open(string.format("%s/%s", Dirs.tabs, "sys"))
buf = "\n" .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
   emerge(i)
   if i == "_python" then
      dofile("%s/%s", ok.dirname(arg[0]), "python-bootstrap.lua")
      emerge("samurai")
   end
   if i:sub(1, 3) == "gcc" then
      --os.execute("./split-gcc.sh")
   end
end

-- Rebuilds for reproducibility
--rebuilds = { "binutils", "bison", "glibc", "gperf", "mpfr" }
--for i=1,#rebuilds do emerge(rebuilds[i]) end

-- Fix versions and cleanup
os.execute("makewhatis /usr/share/man")
ok.chdir(Dirs.packages)
--purge("_perl")
--purge("_python3")
--purge("samurai")
--os.remove("samurai-1.2-amd64.tar.lz")
--os.remove("/bin/meson")
--os.rename("bash-5.3-amd64.tar.lz", "bash-5.3.009-amd64.tar.lz")
--os.rename("readline-8.3-amd64.tar.lz", "readline-8.3.003-amd64.tar.lz")
--ok.mkdir("a")
