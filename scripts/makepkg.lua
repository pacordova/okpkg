#!/usr/bin/env lua

package.path = "/usr/firepkg/?.lua;" .. package.path

local firepkg = require "functions"

local dir = ...

-- strip libraries
exec {
    chdir(dir),
    "/usr/bin/strip",
    "--strip-debug",
    "usr/lib64/*",
    "2>/dev/null"
}

-- strip binaries
exec {
    chdir(dir),
    "/usr/bin/strip",
    "--strip-all",
    "usr/bin/*",
    "bin/*",
    "2>/dev/null"
}

-- delete unneeded directories
exec {
    chdir(dir),
    "/usr/bin/rm",
    "--recursive",
    "usr/share/doc",
    "usr/doc",
    "usr/share/info",
    "2>/dev/null"
}

-- delete pyc files for reproducibility
exec {
    "/usr/bin/find",
    dir,
    "-name '*.pyc' -delete",
    "2>/dev/null"
}

-- make tarball
exec {
    "/usr/bin/tar",
    "--directory="..directory
    "--sort=name",
    "--mtime=@"..source_date_epoch, 
    "--owner=0",
    "--group=0",
    "--numeric-owner", 
    "--create",
    "--file="..dir..".tar",
    "."
}

-- compress
exec {
    "/usr/bin/xz",
    "--threads=0",
    "--force",
    dir..".tar"
}
