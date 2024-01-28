#!/usr/bin/env lua

dofile "/usr/okpkg/okpkg.lua"

-- clean
chdir("/usr/okpkg")
os.execute("rm -r sources 2>/dev/null")
mkdir("sources")
chdir("sources")

fp = io.open("/usr/okpkg/db/base.db")
buf = "\n" .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%w%-]-) = {.-;") do
    print(i)
    download(i)
end

for i in string.gmatch(buf, "([%w%-]-)={.-;") do
    print(i)
    download(i)
end

download("gcc13")
download("gcc11")

os.execute [[
    cd /usr/okpkg 
    rm sources.tar
    tar -cf sources.tar sources
]]
