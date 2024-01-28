#!/usr/bin/env lua

-- bootstrap
os.execute [[
    cd /usr/okpkg
    make && make install
]]

dofile "/usr/okpkg/okpkg.lua"

setenv("PATH", "/usr/sbin:/usr/bin")
unsetenv("PKG_CONFIG_PATH")

-- localedefs
mkdir "/usr/lib64/locale"
os.execute [[
    localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
    localedef -i en_US -f UTF-8 en_US.UTF-8
]]

fp = io.open("/usr/okpkg/db/base.db")
buf = '\n' .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do
    install(build(i))
end 

os.execute("/usr/okpkg/scripts/setup.sh")
