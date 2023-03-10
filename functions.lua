local B = require "build"
local linux = require "linux"

unpack = table.unpack
chdir = linux.chdir
setenv = linux.setenv

source_date_epoch = os.time(os.date("!*t")) % 100000 * 100000
setenv("CC", "/usr/bin/gcc", 1)
setenv("CXX", "/usr/bin/g++", 1)
setenv("CFLAGS", "-march=x86-64 -mavx -Os -fstack-protector-strong -fcommon -pipe", 1)
setenv("CXXFLAGS", "-march=x86-64 -mavx -Os -fstack-protector-strong -fcommon -pipe", 1)
setenv("SOURCE_DATE_EPOCH", source_date_epoch, 1)
setenv("KBUILD_BUILD_TIMESTAMP", source_date_epoch, 1)
setenv("LC_ALL", "en_US.UTF-8", 1)

arch   = "-x86_64.tar.xz"
srcdir   = "/usr/firepkg/sources"
destdir  = "/usr/firepkg/packages"
patchdir = "/usr/firepkg/patches"

databases = { 
    "/usr/firepkg/db/base.db",
    "/usr/firepkg/db/misc.db",
    "/usr/firepkg/db/dev.db",
    "/usr/firepkg/db/xfce.db",
}
        
-- exec wrapper
function exec(cmd)
    local fd = io.popen(table.concat(cmd, " "))
    local output = {}
    for line in fd:lines() do
        print(line)
        table.insert(output, line)
    end
    fd:close()
    return output
end

-- clean and recreate dir
function makedir(dir)
    exec {
        "rm -r " .. dir .. " 2>/dev/null;",
        "mkdir -p " .. dir
    }
end

local function checksum(file, hash)
    local basename  = file:gsub("^.*/", "") 

    local arr = exec{"sha256sum " .. file}

    verify = arr[1]:gsub(" .*$", "") == hash

    if (verify) then
        io.stderr:write(basename .. ": OK\n")
    else
        io.stderr:write("ERROR: checksum failed for " .. basename)
    end

    return verify
end

local function vlook(pkgname)
    local key = "^" .. pkgname .. "="
    for i, db in ipairs(databases) do
        local fd = io.open(db, "r")
        for line in fd:lines() do
            if line:find(key) then
                load(line:gsub(key, "arr="))()
                fd:close()
                if arr.flags == nil then arr.flags = {}; end
                arr.name = pkgname
                return arr
            end
        end
    end
end

local function download(pkgname)
    local pkg       = vlook(pkgname)
    local archive   = pkg.url:gsub("^.*/", "") 
    local patchfile = patchdir .. "/" .. pkgname .. ".diff"
    local srcdir    = srcdir .. "/" .. pkgname

    exec {
        "/usr/bin/curl",
        "--location",
        "--remote-name",
        pkg.url
    }

    if not checksum(archive, pkg.hash) then
        return -1
    end

    -- clean and recreate srcdir
    makedir(srcdir)

    -- extract downloaded source to srcdir 
    exec {
        "/usr/bin/tar",
        "--directory=" .. srcdir,
        "--strip-components=1",
        "--extract",
        "--file=" .. archive 
    }

    -- if there is a patch, patch it up
    local patch = io.open(patchfile)
    if (patch ~= nil) then
        patch:close()
        exec {
            "/usr/bin/patch",
            "--directory=" .. dir,
            "--strip=1",
            "--input=" .. patchfile
        }
    end

    -- remove the downloaded archive
    exec{"rm -r "..archive.." 2>/dev/null"}
end

local function build(pkgname)
    local pkg      = vlook(pkgname)
    local srcdir   = srcdir  .. "/" .. pkgname
    local destdir  = destdir .. "/" .. pkgname
    local basename = pkg.url:gsub("^.*/", "") 
    
    -- clean and recreate destdir
    makedir(destdir)


    local version = basename:match("[._/-][.0-9-]*[0-9][a-z]?")
    if version ~= nil then
        version = version:gsub("-", "."):gsub("^.", "-")
    else
        version = basename
    end

    local pkgname = destdir .. version .. arch

    chdir(srcdir)
    B[pkg.build](pkg)

    -- makepkg
    exec {
        "/usr/firepkg/scripts/makepkg.lua", 
        destdir
    } 

    -- rename
    rename(destdir .. ".tar.xz", pkgname)

    return pkgname
end

local function install(pkg)
    local basename = pkg:gsub("^.*/", "")
    local version  = basename:match("[._/-][.0-9-]*[0-9][a-z]?")

    if version == nil then 
        version = "" 
    end

    local pkgname  = basename:gsub(version, ""):gsub(arch, "")

    local uninstaller = "/usr/firepkg/uninstall/uninstall-" .. pkgname .. ".sh"

    fd = io.open(uninstaller, "w+")
    fd:write("#!/bin/sh\n")
    fd:write("rm -r '/usr/firepkg/sources/" .. pkgname .. "' 2>/dev/null\n")
    fd:write("rm -r '/usr/firepkg/packages/" .. pkgname .. "' 2>/dev/null\n")
    fd:write("rm -d '" .. uninstaller .. "' 2>/dev/null\n")

    -- install to root
    local index = exec {
        "/usr/bin/tar",
        "--directory=/",
        "--strip-components=0",
        "--extract",
        "--verbose",
        "--file=" .. pkg
    }

    -- write the uninstall script
    for i, line in ipairs(index) do
        fd:write("rm -d '/" .. line .. "' 2>/dev/null\n")
    end

    fd:close()

    exec{"chmod +x " .. uninstaller}
end

local function uninstall(pkgname)
    local uninstaller = "/usr/firepkg/uninstall/uninstall-" .. pkgname .. ".sh"

    local fd = io.open(uninstaller)
    if (fd ~= nil) then
        fd:close()
        exec{"sh " .. uninstaller}
    end
end

local function emerge(pkgname)
    uninstall(pkgname)
    download(pkgname)
    install(build(pkgname))
end

return {
    download  = download,
    build     = build,
    install   = install,
    uninstall = uninstall,
    emerge    = emerge
}
