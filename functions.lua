local bld = require "build"

source_date_epoch = 1000000000
arch   = "-x86_64.tar.xz"
srcdir   = "/usr/firepkg/sources"
destdir  = "/usr/firepkg/packages"
patchdir = "/usr/firepkg/patches"

databases = {
    "/usr/firepkg/db/base.db",
    "/usr/firepkg/db/misc.db",
    "/usr/firepkg/db/xfce.db",
}

unpack = table.unpack

function execute(cmd)
    local fd = io.popen(table.concat(cmd, " "))
    local stdout = {}
    for line in fd:lines() do
        table.insert(stdout, line)
    end
    fd:close()
    return stdout 
end

-- clean and recreate dir
function cleandir(dir)
    execute {
        "rm -r " .. dir .. " 2>/dev/null;",
        "mkdir -p " .. dir
    }
end

function chdir(dir)       
    return "cd " .. dir .. " && "
end

local function checksum(file, hash)
    local basename  = file:gsub("^.*/", "") 

    local arr = execute{"sha256sum " .. file}

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

    execute {
        "/usr/bin/curl",
        "--location",
        "--remote-name",
        pkg.url
    }

    if not checksum(archive, pkg.hash) then
        return -1
    end

    -- clean and recreate srcdir
    cleandir(srcdir)

    -- extract downloaded source to srcdir 
    execute {
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
        execute {
            "/usr/bin/patch",
            "--directory=" .. dir,
            "--strip=1",
            "--input=" .. patchfile
        }
    end

    -- remove the downloaded archive
    execute{"rm -r "..archive.." 2>/dev/null"}
end

local function build(pkgname)
    local pkg      = vlook(pkgname)
    local srcdir   = srcdir  .. "/" .. pkgname
    local destdir  = destdir .. "/" .. pkgname
    local basename = pkg.url:gsub("^.*/", "") 
    
    -- clean and recreate destdir
    cleandir(destdir)


    local version = 
        basename:match("[._/-][.0-9-]*[0-9][a-z]?"):gsub("-", "."):gsub("^.", "-")

    local pkgname = destdir .. version .. arch

    bld[pkg.build](pkg)
    execute{"/usr/firepkg/scripts/makepkg "..destdir}
    execute{"mv "..destdir..".tar.xz "..pkgname}
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
    local index = execute {
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

    execute{"chmod +x " .. uninstaller}
end

local function uninstall(pkgname)
    local uninstaller = "/usr/firepkg/uninstall/uninstall-" .. pkgname .. ".sh"

    local fd = io.open(uninstaller)
    if (fd ~= nil) then
        fd:close()
        execute{"sh " .. uninstaller}
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
