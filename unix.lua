local function paste(arr)
    local s = ""
    for i, v in ipairs(arr) do
        s = s .. " " .. v
    end
    return s
end

local function ls(dir)
    local cmd = {
        "/usr/bin/ls",
        dir,
        "2>/dev/null"
    }
    local fd = io.popen(paste(cmd))
    local arr = {}
    for line in fd:lines() do
        table.insert(arr, line)	
    end
    fd:close()
    return arr
end

local function strip(dir, ...)
    local arr = ls(dir)
    for _, file in ipairs(arr) do     
        local cmd = {
            "/usr/bin/strip",
            ...,
            file
        }  
        os.execute(paste(cmd))
    end
end

local function rm(file)
    local cmd = {
        "/usr/bin/rm",
        "--recursive",
        file,
        "2>/dev/null"
    }
    os.execute(paste(cmd))
end

local function mkdir(directory)
    rm(directory)
    local cmd = {
        "/usr/bin/mkdir",
        "--parents",
        directory
    }
    os.execute(paste(cmd))
end

local function compress(file)
    local cmd = {
        "/usr/bin/xz",
        "--threads=0",
        "--force",
        file
    }
    os.execute(paste(cmd))
    rm(file)
end

local function extract(file, directory)
    local cmd = {
        "/usr/bin/tar",
        "--directory=" .. directory,
        "--strip-components=1",
        "--extract",
        "--file",
        file
    }
    os.execute(paste(cmd))
end

local function patch(file, directory)
    local fd = io.open(file)
    if (fd ~= nil) then
        fd:close()
        local cmd = {
            "/usr/bin/patch",
            "--directory=" .. directory,
            "--strip=1",
            "<" .. file
        }
        os.execute(paste(cmd))
    end
end

local function rename(old, new)
    local cmd = {
        "/usr/bin/mv",
        old,
        new
    }
    os.execute(paste(cmd))
end

return {
    paste    = paste,
    ls       = ls,
    strip    = strip,
    rm       = rm,
    mkdir    = mkdir,
    compress = compress,
    extract  = extract,
    patch    = patch,
    rename   = rename
}
