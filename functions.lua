local sha2 = require 'sha2'
local sys  = require 'unix'

unpack = table.unpack

local source_date_epoch = 1000000000
local patches = "/usr/firepkg/patches"
local sources = "/usr/firepkg/sources"
local paste  = sys.paste


env = {
    "SOURCE_DATE_EPOCH=" .. source_date_epoch
}

function checksum(file, hash)
    local fd = io.open(file)
    local x = sha2.new256()
    for b in fd:lines(2^12) do
        x:add(b)
    end
    fd:close()

    verify = x:close() == hash

    if (verify) then
        io.stderr:write("sha256sum: OK")
    else
        io.stderr:write("ERROR: checksum failed")
    end

    return verify
end

function vlook(pkgname)
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

function download(pkgname)
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

function makepkg(dir)
    --cleanup
    sys.strip(dir .. "/usr/lib64", "--strip-debug") 
    sys.strip(dir .. "/usr/bin",   "--strip-all")
    sys.strip(dir .. "/bin",       "--strip-all")
    sys.rm(dir .. "/usr/share/doc")
    sys.rm(dir .. "/usr/doc")
    sys.rm(dir .. "/usr/share/info")

    --delete pyc files for reproducibility
    os.execute("/usr/bin/find . -name '.pyc' -delete")

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


-----------------------------------------

bash = vlook("bash")
print(bash.build)

download("bash")
