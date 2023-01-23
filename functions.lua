function ls(dir)
    local fd = io.popen("ls " .. dir)
    local arr = {}
    for line in fd:lines() do
        table.insert(arr, line)	
    end
    fd:close()
    return arr
end

function str(arr)
    local s = arr[1]
    for i in 2, #arr do
        s = s .. " " .. arr[i]
    end
    return s
end


function strip(dir, ...)
    arr = ls(dir)
    for file in arr do     
        io.popen(str({"/usr/bin/strip", ..., file}))
    end
end

function rm(file)
    io.popen("rm -r " .. file)
end

function compress(file)
    cmd = {
        "/usr/bin/xz",
        "--threads=0",
        "--force",
        file
    }
    io.popen(str(cmd))
    rm(file)
end

function makepkg(dir)
    --cleanup
    strip(dir .. "/usr/lib64", "--strip-debug") 
    strip(dir .. "/usr/bin",   "--strip-all")
    strip(dir .. "/bin",       "--strip-all")
    rm(dir .. "/usr/share/doc")
    rm(dir .. "/usr/doc")
    rm(dir .. "/usr/share/info")

    --delete pyc files for reproducibility
    io.popen("find . -name '.pyc' -delete")

    --make tarball
    cmd = {
        "/usr/bin/tar",
        "--sort=name",
        "-mtime=@$SOURCE_DATE_EPOCH",
        "--owner=0",
        "--group=0",
        "--numeric-owner",
        "--create",
        "--file",
        dir .. ".tar",
        unpack(ls(dir))
    }
    io.popen(str(cmd))
    
    --compress
    compress(dir .. ".tar")
end
        

extract = {
    "/usr/bin/tar",
    "--directory", "/",
    "--extract",
    "--verbose",
    "--file"
}

function tar(dir)
    io.popen("tar --sort=name --mtime=
