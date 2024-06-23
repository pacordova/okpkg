#!/usr/bin/env lua

local ok = require"okutils"

local chdir, mkdir, setenv, unsetenv, pwd, basename =
    ok.chdir, ok.mkdir, ok.setenv, ok.unsetenv, ok.pwd, ok.basename

local pkgname = "rust-1.78.0-x86_64"
local url = "https://static.rust-lang.org/dist/rust-1.78.0-x86_64-unknown-linux-gnu.tar.xz"

-- Download file if not already downloaded
chdir("/usr/okpkg/download")
print(string.format("okpkg download %s:\n url: %s\n filename: %s",
        pkgname, url, basename(url)))
local fp = io.open(basename(url))
if fp then
    fp:close()
else
    os.execute(string.format("curl -LOR %s", url))
end

-- Extract
chdir("/usr/okpkg/sources")
mkdir(pkgname)
chdir(pkgname)
os.execute(string.format("tar --strip-components=1 -xf /usr/okpkg/download/%s", basename(url)))

-- Install Rust
-- Uninstaller located at /usr/lib64/rustlib/uninstall.sh
os.execute [[
    ./install.sh --prefix=/usr \
        --destdir=/ \
        --libdir=/usr/lib64
]]
