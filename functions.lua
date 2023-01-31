local bld = require "build"

local source_date_epoch = 1000000000
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

local function extract(file, directory)
    local fd = io.popen("tar -C " .. directory .. " --strip-components=1 -xvf " .. file)
    local arr = {}
    for line in fd:lines() do
        table.insert(arr, line)	
    end
    fd:close()
    return arr
end

local function patch(file, directory)
    local fd = io.open(file)
    if (fd ~= nil) then
        fd:close()
        os.execute("patch -d " .. directory .. " -p1 <" .. file)
    end
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
    local key = "^" .. pkgname
    local fd = io.open("/usr/firepkg/example.db", "r")
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

    os.execute("curl -LO " .. pkg.url)

    if not checksum(basename, pkg.hash) then
        return -1
    end

    os.execute("rm -r " .. srcdir .. " 2>/dev/null")
    os.execute("mkdir -p " .. srcdir)

    extract(basename, srcdir)    
    patch(patchfile, srcdir)
    os.execute("rm -r " .. basename .. " 2>/dev/null")

end

local function build(pkgname)
    local pkg       = vlook(pkgname)
    local basename  = pkg.url:gsub("^.*/", "") 

    local env = env(pkgname)

    os.execute("rm -r " .. env.destdir .. " 2>/dev/null")
    os.execute("mkdir -p " .. env.destdir)


    local version = 
        basename:match("[._/-][.0-9-]*[0-9][a-z]?"):gsub("-", "."):gsub("^.", "-")

    local pkgname = env.destdir .. version .. arch

    bld[pkg.build](env, pkg.flags)
    os.execute("/usr/firepkg/scripts/makepkg " .. env.destdir)
    os.execute("mv " .. env.destdir .. ".tar.xz " .. pkgname)

    return pkgname
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

    for i, line in ipairs(extract(file, root)) do
        fd:write("rm -d '" .. root .. line .. "' 2>/dev/null\n")
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
