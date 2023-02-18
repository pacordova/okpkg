local bld = require "build"

local source_date_epoch = 1000000000
local arch   = "-x86_64.tar.xz"
local databases = {
    "/usr/firepkg/db/base.db"
}


local function execute(cmd)
    local fd = io.popen(table.concat(cmd, " "))
    local stdout = {}
    for line in fd:lines() do
        table.insert(stdout, line)
    end
    fd:close()
    return stdout 
end

local function tmp(pkgname) 
    if pkgname == nil then
        pkgname = ""
    end
    return "/usr/firepkg/sources/" .. pkgname, "/usr/firepkg/packages/" .. pkgname
end

local function checksum(file, hash)
    local basename  = file:gsub("^.*/", "") 

    local fd = io.popen("sha256sum " .. file)
    local arr = {}
    for line in fd:lines() do
        table.insert(arr, line)	
    end
    fd:close()

    verify = arr[1]:gsub(" .*$", "") == hash

    if (verify) then
        io.stderr:write(basename .. ": OK\n")
    else
        io.stderr:write("ERROR: checksum failed for " .. basename)
    end

    return verify
end

local function vlook(pkgname)
    srcdir, destdir = tmp(pkgname)
    local key = "^" .. pkgname .. "="
    for i, db in ipairs(databases) do
        local fd = io.open(db, "r")
        for line in fd:lines() do
            if line:find(key) then
                load(line:gsub(key, "arr="))()
                fd:close()
                if arr.flags == nil then arr.flags = {}; end
                return arr
            end
        end
    end
end

local function download(pkgname)
    local pkg       = vlook(pkgname)
    local archive  = pkg.url:gsub("^.*/", "") 
    local patchfile = "/usr/firepkg/patches/" .. pkgname .. ".diff"
    local srcdir    = "/usr/firepkg/sources/" .. pkgname

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
    execute {
        "/usr/bin/rm",
        "--recursive",
        srcdir
    }
    execute {
        "/usr/bin/mkdir",
        "--parents",
        srcdir,
    }

    -- extract downloaded source to srcdir 
    execute {
        "/usr/bin/tar",
        "--directory=" .. srcdir,
        "--strip-components=1",
        "--extract",
        "--file=" .. archive 
    }

    -- if there is a patch, patch it up
    local fd = io.open(patchfile)
    if (fd ~= nil) then
        fd:close()
        execute {
            "/usr/bin/patch",
            "--directory=" .. dir,
            "--strip=1",
            "--input=" .. patchfile
        }
    end

    -- remove the downloaded archive
    execute {
        "/usr/bin/rm",
        "--recursive",
        archive,
        "2>/dev/null"
    }
end

local function build(pkgname)
    srcdir, destdir = tmp(pkgname)
    local pkg       = vlook(pkgname)
    local basename  = pkg.url:gsub("^.*/", "") 

    
    -- clean and recreate destdir
    execute {
        "/usr/bin/rm",
        "--recursive",
        destdir,
        "2>/dev/null"
    }
    execute {
        "/usr/bin/mkdir",
        "--parents",
        destdir
    }


    local version = 
        basename:match("[._/-][.0-9-]*[0-9][a-z]?"):gsub("-", "."):gsub("^.", "-")

    local pkgname = destdir .. version .. arch

    bld[pkg.build]({srcdir, destdir}, pkg)
    execute {
        "/usr/firepkg/scripts/makepkg",
        destdir
    }
    execute {
        "/usr/bin/mv",
        destdir .. ".tar.xz",
        pkgname
    }

    return pkgname
end

local function install(pkg)
    local basename = file:gsub("^.*/", "")
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

    os.execute("chmod +x " .. uninstaller)
end

local function uninstall(pkgname)
    local uninstaller = "/usr/firepkg/uninstall/uninstall-" .. pkgname .. ".sh"

    local fd = io.open(uninstaller)
    if (fd ~= nil) then
        fd:close()
        os.execute("sh " .. uninstaller)
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
