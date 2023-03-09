#!/usr/bin/env lua

current_time = os.time(os.date("!*t"))
source_date_epoch = current_time - (current_time % 100000)

directory = arg[1]

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

-- strip libraries
exec {
    "/usr/bin/strip",
    "--strip-debug",
    directory .. "/usr/lib64/*",
    "2>/dev/null"
}

-- strip binaries
exec {
    "/usr/bin/strip",
    "--strip-all",
    directory .. "/usr/bin/*",
    directory .. "/bin/*",
    "2>/dev/null"
}

-- delete unneeded directories
exec {
    "/usr/bin/rm",
    "--recursive",
    directory .. "/usr/share/doc",
    directory .. "/usr/doc",
    directory .. "/usr/share/info",
    "2>/dev/null"
}

-- delete pyc files for reproducibility
exec {
    "/usr/bin/find",
    directory,
    "-name '*.pyc' -delete",
}

-- make tarball
exec {
    "/usr/bin/tar",
    "--directory=" .. directory,
    "--sort=name",
    "--mtime=@" .. source_date_epoch, 
    "--transform='s|^..||'",
    "--owner=0",
    "--group=0",
    "--numeric-owner", 
    "--create",
    "--file=" .. directory .. ".tar",
    "."
}

-- compress
exec {
    "/usr/bin/xz",
    "--threads=0",
    "--force",
    directory .. ".tar"
}

-- delete target
exec {
    "/usr/bin/rm",
    "--recursive",
    directory
}
