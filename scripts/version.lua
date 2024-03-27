#!/usr/bin/env lua

package.cpath = package.cpath .. ";/usr/okpkg/?.so"

require "okutils"

pkgs = {
    "iana-etc", "glibc", "zlib", "bzip2", "xz", "zstd", "file", "m4",
    "flex", "pkgconf", "binutils", "gmp", "mpfr", "libmpc", "attr", "acl", 
    "libxcrypt", "isl", "gcc", "binutils", "which", "gperf", "libcap", 
    "libmd", "libbsd", "shadow", "ncurses", "readline", "sed", "psmisc", 
    "bison", "pcre2", "grep", "bash", "expat", "inetutils", "less", "tcsh", 
    "mawk", "tzdata", "perl", "libressl", "kmod", "curl", "python3", "samurai", 
    "meson", "coreutils", "check", "diffutils", "findutils", "pigz", "libtirpc",
    "iproute2", "kbd", "make", "lzip", "ed", "patch", "tar", "lua", "vim", 
    "eudev", "mandoc", "procps-ng", "util-linux", "dcron", "e2fsprogs", 
    "libarchive", "sysklogd", "dbus", "openresolv", "dhcpcd",
    "libxml2", "libxslt", "iputils", "acpid", "cmake", "dma", "at", 
    "dosfstools", "htop", "git", "gnupg1", "libpcap", "iftop", "popt", 
    "logrotate", "lsof", "lzo", "lzop", "nano", "openssh", "pax", "rsync", 
    "s-nail", "sharutils", "sudo", "time", "libevent", "tmux",
    "gawk", "gzip",
}

function curl(url)
    local fd, buf
    fd = io.popen("curl -L '" .. url .. "'")
    buf = fd:read("*a")
    io.close(fd)
    return buf
end

function _vstr(path)
    local s, i, j
    s = basename(path)

    if s:find("^%d") then 
        i = 0
    elseif s:find("[v.-]%d") then
        i = s:find("[v.-]%d") 
    else
        return ""
    end

    j = s:find("%.t") or #s+1

    return s:sub(i+1, j-1)
end

function getv(t, pkg)
    for i=1,#t do
        if t[i]:match("^" .. pkg .. "%%-") then
            return _vstr(t[i])
        end
    end
    return nil
end

-- arch
archlinux = {}
buf1 = curl("https://mirrors.kernel.org/archlinux/core/os/x86_64/")
buf2 = curl("https://mirrors.kernel.org/archlinux/extra/os/x86_64/")
buf3 = curl("https://mirrors.kernel.org/archlinux/community/os/x86_64/")
buf = buf1 .. "\n" .. buf2 .. "\n" .. buf3
for w in string.gmatch(buf, 'href="(.-)"') do
    if string.find(w, "%.tar.zst$") then
        local s
        s = basename(w):gsub(".pkg.tar.zst", "")
        s = s:gsub("%-x86_64", "")
        s = s:gsub("%-any", "")
        s = s:gsub("%-%d+$", "")
        s = s:gsub("1%%3A", "")
        s = s:gsub("python%-", "python3-")
        s = s:gsub("libisl%-", "isl-")
        table.insert(archlinux , s)
    end
end

-- slackware
slackware = {}
buf = curl(
    "https://mirrors.kernel.org/slackware/slackware64-current/FILELIST.TXT"
)
for w in string.gmatch(buf, '%./(.-)\n') do
    if string.find(w, "%.txz$") then
        local s
        s = basename(w):gsub("%-x86_64.-.txz", "")
        s = s:gsub("%-noarch%-%d+", "")
        s = s:gsub("glibc%-zoneinfo%-", "tzdata-")
        s = s:gsub("bash%-completion%-", "")
        table.insert(slackware, s)
    end
end

okpkg = {}
fd = io.popen("ls /usr/okpkg/packages/base")
buf = fd:read("*a")
for w in string.gmatch(buf, '(.-\n)') do
    local s = w:gsub("%-x86_64.tar.xz\n", "")
    table.insert(okpkg, s)
end
io.close(fd)

-- print as csv
io.write("package,archlinux,slackware,okpkg\n")
for i=1, #pkgs do
    local pkg = pkgs[i]:gsub("%-", "%%-")
    local arch = getv(archlinux, pkg)
    local slack = getv(slackware, pkg)
    local okpkg = getv(okpkg, pkg)
    
    -- fill nil
    if not arch then arch = slack end
    if not slack then slack = arch end

    -- omit when versions are the same
    if okpkg ~= slack or okpkg ~= arch then
        io.write(string.format("%s,%s,%s,%s\n", pkgs[i], arch, slack, okpkg))
    end
end
print("Remember to check dinit and bc manually!")

