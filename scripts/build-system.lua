#!/usr/bin/env lua

-- ensure okpkg is installed
local fp; fp = io.open"/usr/bin/okpkg"
if fp then fp:close() else fp = io.open"/usr/bin/make"
   if fp then fp:close(); os.execute"cd /usr/okpkg && make && make install"; end
end

-- imports
dofile"/usr/okpkg/okpkg.lua"
local ok = require"okutils"
local chdir = ok.chdir

-- Generate locales
os.execute"localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true"
os.execute"localedef -i en_US -f UTF-8 en_US.UTF-8"

-- core system
local fp, buf
fp = io.open("/usr/okpkg/db/system.db"); buf = '\n' .. fp:read("*a"); fp:close()
for i in buf:gmatch("\n([%_%w%-%+]-) = {.-;") do
   if i == "_python" then fp = io.open"/usr/bin/python3"
      if not fp then emerge(i) else fp:close() end
   elseif i == "_perl" then fp = io.open"/usr/bin/perl"
      if not fp then emerge(i) else fp:close() end
   elseif i:sub(1, 3) == "gcc" then
      emerge(i); os.execute"/usr/okpkg/scripts/split-gcc.sh"
   else emerge(i) end
end

-- rebuilds
emerge"bison"
emerge"gperf"
emerge"glibc"
emerge"binutils"
emerge"mpfr"

-- misc post-install
os.execute"udevadm hwdb --usr --update"
os.execute"makewhatis /usr/share/man"

-- fix versions and cleanup
chdir"/usr/okpkg/packages"
os.rename("bash-5.2.32-amd64.tar.lz", "bash-5.2.032-amd64.tar.lz")
os.rename("readline-8.2.13-amd64.tar.lz", "readline-8.2.013-amd64.tar.lz")
os.rename("sqlite-3460100-amd64.tar.lz", "sqlite-3.46.1-amd64.tar.lz")
os.execute"rm -fr _*.tar.lz *no"
