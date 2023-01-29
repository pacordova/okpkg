local sys   = require "unix"
local build = require "build"

unpack = table.unpack

local source_date_epoch = 1000000000
local patches = "/usr/firepkg/patches"
local sources = "/usr/firepkg/sources"
local paste  = sys.paste

local libdir = "/usr/lib64"
local prefix = "/usr"

env = {
    "SOURCE_DATE_EPOCH=" .. source_date_epoch
}


local function checksum(file, hash)
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
        io.stderr:write("sha256sum: OK")
    else
        io.stderr:write("ERROR: checksum failed")
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
end

local function makepkg(dir)
    --cleanup
    sys.strip(dir .. "/usr/lib64", "--strip-debug") 
    sys.strip(dir .. "/usr/bin",   "--strip-all")
    sys.strip(dir .. "/bin",       "--strip-all")
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
        "--mtime=@" .. source_date_epoch,
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
    local suffix    = "-x86_64.tar.xz"

    local dirflags = {
        "--localstatedir=/var",
        "--sysconfdir=/etc",
        "--libdir=" .. libdir,
        "--bindir=" .. prefix .. "/bin",
        "--sbindir=" .. prefix .. "/sbin"
    }

    destdir = "/usr/firepkg/packages/" .. pkgname

    sys.mkdir(destdir)

    version = basename:match("[._/-][.0-9-]*[0-9][a-z]?")
    version = version:gsub("-", "."):gsub("^.", "-")

    build[pkg.build]()
    makepkg(destdir)
    sys.rename(destdir .. ".tar.xz", destdir .. version .. suffix)
end


-----------------------------------------

bash = vlook("bash")
print(bash.build)

download("bash")
