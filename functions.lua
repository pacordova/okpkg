local sys = require "unix"
local bld = require "build"

unpack = table.unpack

local source_date_epoch = 1000000000
local paste  = sys.paste
local root   = "/"
local arch   = "-x86_64.tar.xz"

local function env(pkgname) 
    if pkgname == nil then
        pkgname = ""
    end
    return {
        source_date_epoch = 1000000000,
        libdir            = "/usr/lib64",
        prefix            = "/usr",
        srcdir            = "/usr/firepkg/sources/" .. pkgname,
        destdir           = "/usr/firepkg/packages/" .. pkgname,
        bindir            = "/usr/bin",
        sbindir           = "/usr/sbin",
        sysconfdir        = "/etc",
        localstatedir     = "/var",
        root              = "/"
    }
end


local function checksum(file, hash)
    local basename  = file:gsub("^.*/", "") 

    local cmd = {
        "/usr/bin/sha256sum",
        file,
    }
    local fd = io.popen(paste(cmd))
    local arr = {}
    for line in fd:lines() do
        table.insert(arr, line)	
    end
    fd:close()

    verify = arr[1]:gsub(" .*$", "") == hash

    if (verify) then
        io.stderr:write(basename.. ": OK\n")
    else
        io.stderr:write("ERROR: checksum failed for " .. basename)
    end

    return verify
end

local function vlook(pkgname)
    local key = "^" .. pkgname
    local fd = io.open("example.db", "r")
    for line in fd:lines() do
        if line:find(key) then
            load(line:gsub(key, "arr"))()
            break
        end
    end
    fd:close()

    if arr.flags == nil then
        arr.flags = {}
    end 

    return arr
end

local function download(pkgname)
    local pkg       = vlook(pkgname)
    local basename  = pkg.url:gsub("^.*/", "") 
    local patchfile = "/usr/firepkg/patches/" .. pkgname .. ".diff"
    local srcdir    = "/usr/firepkg/sources/" .. pkgname

    local cmd = {
        "/usr/bin/curl",
        "--location",
        "--remote-name",
        pkg.url
    }
    os.execute(paste(cmd))

    if not checksum(basename, pkg.hash) then
        return -1
    end

    sys.mkdir(srcdir)
    sys.extract(basename, srcdir)    
    sys.patch(patchfile, srcdir)
    sys.rm(basename)
    return x
end

local function makepkg(dir)
    local env = env()

    --cleanup
    sys.strip(dir .. env.libdir, "--strip-debug") 
    sys.strip(dir .. env.bindir, "--strip-all")
    sys.strip(dir .. "/bin",     "--strip-all")
    sys.rm(dir .. "/usr/share/doc")
    sys.rm(dir .. "/usr/doc")
    sys.rm(dir .. "/usr/share/info")

    --delete pyc files for reproducibility
    local cmd = {
        "/usr/bin/find",
        dir,
        "-name '.pyc' -delete"
    }
    os.execute(paste(cmd))

    --make tarball
    local cmd = {
        "/usr/bin/tar",
        "--directory=" .. dir,
        "--sort=name",
        "--mtime=@" .. env.source_date_epoch,
        "--owner=0",
        "--group=0",
        "--numeric-owner",
        "--create",
        "--file",
        dir .. ".tar",
        unpack(sys.ls(dir))
    }
    os.execute(paste(cmd))

    --compress
    sys.compress(dir .. ".tar")
end

local function build(pkgname)
    local pkg       = vlook(pkgname)
    local basename  = pkg.url:gsub("^.*/", "") 

    local env = env(pkgname)

    sys.mkdir(env.destdir)

    local version = 
        basename:match("[._/-][.0-9-]*[0-9][a-z]?"):gsub("-", "."):gsub("^.", "-")

    pkgfile = env.destdir .. version .. arch

    bld[pkg.build](env, pkg.flags)
    makepkg(env.destdir)
    sys.rename(env.destdir .. ".tar.xz", pkgfile)

    return pkgfile
end

local function install(file)
    local basename = file:gsub("^.*/", "")
    local version  = basename:match("[._/-][.0-9-]*[0-9][a-z]?")
    local pkgname  = basename:gsub(version, ""):gsub(arch, "")

    local uninstaller = "/usr/firepkg/uninstall/uninstall-" .. pkgname .. ".sh"

    fd = io.open(uninstaller, "w+")
    fd:write("#!/bin/sh\n")
    fd:write("rm -r '/usr/firepkg/sources/" .. pkgname .. "' 2>/dev/null\n")
    fd:write("rm -r '/usr/firepkg/packages/" .. pkgname .. "' 2>/dev/null\n")
    fd:write("rm -d '" .. uninstaller .. "' 2>/dev/null\n")

    for i, line in ipairs(sys.extract(file, root)) do
        fd:write("rm -d '" .. root .. line .. "' 2>/dev/null\n")
    end

    fd:close()

    os.execute("/usr/bin/chmod +x " .. uninstaller)
end

local function uninstall(pkgname)
    local uninstaller = "/usr/firepkg/uninstall/uninstall-" .. pkgname .. ".sh"

    local fd = io.open(uninstaller)
    if (fd ~= nil) then
        fd:close()
        os.execute("/bin/sh " .. uninstaller)
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
    makepkg   = makepkg,
    emerge    = emerge
}
