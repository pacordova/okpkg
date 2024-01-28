#!/usr/bin/env lua

-- This script is cross compilation of GNU and other tools.
-- It follows LFS closely, but not exactly.
-- https://www.linuxfromscratch.org/lfs/view/stable/index.html

-- imports
require "utils"

local format, unpack = string.format, unpack or table.unpack

-- environment
setenv("MAKEOPTS", "-j5")
setenv("CFLAGS", "-O2 -fstack-protector-strong -fstack-clash-protection -fcommon -pipe")
setenv("CXXFLAGS", "-O2 -fstack-protector-strong -fstack-clash-protection -fcommon -pipe")
setenv("DESTDIR", "/mnt")
setenv("gcc_version", "13.2.0")
setenv("glibc_version", "2.38")
setenv("TARGET", "x86_64-unknown-linux-gnu")
setenv("HOST", "x86_64-unknown-linux-gnu")
setenv("PATH", "/mnt/tools/bin:/usr/sbin:/usr/bin:/sbin:/bin")

function vlook(pkgname)
    local databases = {"2"}
    for i=1,#databases do
        local fp = io.open("/usr/okpkg/db/" .. databases[i] .. ".db")
        local buf = '\n' .. fp:read("*a")
        fp:close()
        local start = buf:find('\n' .. pkgname .. " = {", 1, true)
        if start then
            buf = buf:sub(start+3+#pkgname, buf:find(';', start+1, true)-1)
            return load("return"..buf)()
        end
    end
end

function build(pkgname)
    local t = vlook(pkgname)

    chdir("/usr/okpkg/sources")

    if pkgname:match("gcc") or pkgname:match("libstdc++") then
        os.execute("cp -rp gcc13 " .. pkgname)
    end

    if pkgname:match("binutils") then
        os.execute("cp -rp binutils " .. pkgname)
    end

    chdir(pkgname)
    
    if t.pre_install then
        os.execute(t.pre_install)
    end

    if t.build:match("config") then
        if t.build:sub(1, 2) == ".." then
            mkdir("build")
            chdir("build")
        end
        _ = os.execute(t.build .. ' ' .. table.concat(t.flags,' ')) and
            os.execute "make $MAKEOPTS" and
            os.execute "make install DESTDIR=$DESTDIR"
    end

    if t.build == "make" then
        _ = os.execute("make $MAKEOPTS " .. table.concat(t.flags,' ')) and
            os.execute("make install DESTDIR=$DESTDIR " ..
                table.concat(t.flags,' '))
    end

    if not _ then
        print("error: " .. pkgname)
        os.exit()
    end

    if t.post_install then
        os.execute(t.post_install)
    end
end

-- setup
os.execute [[
    cd /usr/okpkg
    rm -r sources 2>/dev/null
    tar -xf sources.tar 2>/dev/null
    umount -l $DESTDIR
    read -p "Enter partition to format: " partition
    mkfs.ext4 "$partition"
    mount $partition $DESTDIR

    cd $DESTDIR
    lua /usr/okpkg/scripts/filesystem.lua
    tar -xf /usr/okpkg/packages/base/linux-headers*.tar.xz
]]

fp = io.open("/usr/okpkg/db/2.db")
buf = "\n" .. fp:read("*a")
fp:close()
for i in buf:gmatch("\n([%w%-%+]-) = {.-;") do
    build(i)
end

-- cleanup
os.execute [[ 
    git clone /usr/okpkg ${DESTDIR}/usr/okpkg
    tar -C ${DESTDIR}/usr/okpkg -xf /usr/okpkg/sources.tar
]]
