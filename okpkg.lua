#!/usr/bin/env lua

package.cpath = package.cpath .. ";/usr/okpkg/?.so"

require "okutils"

local unpack = unpack or table.unpack

-- environment
setenv("MAKEOPTS", "-j5")
setenv("CFLAGS", "-O2 -march=x86-64 -fstack-protector -fcommon -pipe")
setenv("CXXFLAGS", "-O2 -march=x86-64 -fstack-protector -fcommon -pipe")
setenv("LC_ALL", "POSIX")

local databases = { "system", "extra", "gnu", "lib", "xorg", "xfce" }

-- sets the source_date_epoch equal to a file
function source_date_epoch(filename)
    local fp, buf
    fp = io.popen("stat -c '%Y' " .. filename)
    buf = fp:read("*a")
    fp:close()
    buf = buf:sub(1, buf:find('\n')-1)
    setenv("SOURCE_DATE_EPOCH", tonumber(buf))
end

function vstr(path)
    local s, i, j
    s = basename(path)

    if s:find("^%d") then 
        i = 0
    elseif s:find("[v.-]%d") then
        i = s:find("[v.-]%d") 
    else
        return ""
    end

    j = s:find("%.t")

    return s:sub(i+1, j-1)
end

function _vlook(pkgname)
    for i=1,#databases do
        local fp = io.open(string.format("/usr/okpkg/db/%s.db", databases[i]))
        local buf = '\n' .. fp:read("*a")
        fp:close()
        local start = buf:find(string.format("\n%s = {", pkgname), 1, true)
        if start then
            buf = buf:sub(start+3+#pkgname, buf:find('};', start+1, true))
            return load("return" .. buf)()
        end
    end
end

function download(pkgname)
    -- vars
    local t = _vlook(pkgname)
    local f = basename(t.url)
    local srcdir = string.format("/usr/okpkg/sources/%s", pkgname)
    local patchfile = string.format("/usr/okpkg/patches/%s.patch", pkgname)

    -- change mirrors
    t.url = t.url:gsub("ftp.gnu.org", "mirrors.ocf.berkeley.edu")

    -- setup srcdir
    os.execute(string.format("rm -fr %s", srcdir))
    mkdir(srcdir)

    -- download file if not already downloaded
    chdir("/usr/okpkg/download")
    f = basename(t.url)
    print(string.format("okpkg download %s:\n url: %s\n filename: %s",
            pkgname, t.url, f))
    local fp = io.open(f)
    if fp then
        fp:close()
    else
        os.execute(string.format("curl -LOR %s", t.url))
    end

    -- timestamp
    source_date_epoch(f)

    -- checksums
    if not os.execute(string.format('grep "%s" b2sums | b2sum -c', f)) then
        os.remove(f)
        error("bad checksum: " .. pkgname)
    end

    -- extract
    os.execute(
        string.format("bsdtar -C %s --strip-components 1 -xf %s", srcdir, f))
    chdir(srcdir)


    -- patch
    local fp = io.open(patchfile)
    if fp then
        os.execute(string.format("patch -p1 <%s", patchfile))
        fp:close()
    end

    os.execute [[ find . -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + ]]
end

function makepkg(path)
    -- ensure path exists
    if chdir(path) ~= 0 then
        error(path .. " does not exist")
    end

    source_date_epoch(".")
    path = basename(path)

    -- strip, delete-unneeded, timestamp, etc.
    os.execute [[
        find . -name "*.pyc" -delete
        find . -name "*.la" -delete
        find . -name "lib*a" -exec strip -g '{}' +
        find . -name "lib*so*" -exec strip --strip-unneeded '{}' +
        find usr/bin -type f -exec strip -s '{}' + 2>/dev/null
        rm -fr usr/doc usr/share/info usr/share/doc usr/share/locale \
            usr/share/gtk-doc usr/share/man/de usr/share/man/fr \
            usr/share/man/pl usr/share/man/pt_BR usr/share/man/ro \
            usr/share/man/sv usr/share/man/uk
        find . -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' +
        find . | sort | bsdtar --no-recursion -T - -cf $PWD.tar
        xz --threads=2 -f $PWD.tar
        touch -hd "@$SOURCE_DATE_EPOCH" $PWD.tar.xz
    ]]

    chdir("..")
    os.execute("rm -r " .. path)

    return path .. ".tar.xz"
end

function build(pkgname)
    local _, t, version

    chdir(string.format("/usr/okpkg/sources/%s", pkgname))

    source_date_epoch(".")

    t = _vlook(pkgname)
    t.flags = t.flags or {}
    version = vstr(t.url)
    setenv("DESTDIR",
        string.format("/usr/okpkg/packages/%s-%s-x86_64",pkgname,version))

    if t.prepare then
        os.execute(t.prepare)
    end

    if t.build == "./autogen.sh" then
        os.execute "./autogen.sh"
        table.insert(t.flags, "--prefix=/usr")
        local flags = table.concat(t.flags, ' ')
        _ = os.execute(string.format("./configure %s", flags)) and
            os.execute [[ 
                make "$MAKEOPTS" DESTDIR= && 
                make install DESTDIR="$DESTDIR"
            ]]
    end

    if t.build == "autoreconf" then
        os.execute "autoreconf -fi --include=m4"
        table.insert(t.flags, "--prefix=/usr")
        local flags = table.concat(t.flags, ' ')
        _ = os.execute(string.format("./configure %s", flags)) and
            os.execute [[ 
                make "$MAKEOPTS" DESTDIR= && 
                make install DESTDIR="$DESTDIR"
            ]]
    end

    if tostring(t.build):match("config") then
        if t.build:sub(1, 2) == ".." then
            mkdir("build")
            chdir("build")
        end
        table.insert(t.flags, "--prefix=/usr")
        local flags = table.concat(t.flags, ' ')
        _ = os.execute(
                string.format("%s %s", t.build, flags)) and
            os.execute [[ 
                make "$MAKEOPTS" DESTDIR= && 
                make install DESTDIR="$DESTDIR"
            ]]
    end

    if t.build == "cmake" then
        table.insert(t.flags, "-DCMAKE_INSTALL_PREFIX=/usr")
        table.insert(t.flags, "-DCMAKE_BUILD_TYPE=Release") 
        table.insert(t.flags, "-DCMAKE_SHARED_LIBS=True")
        local flags = table.concat(t.flags, ' ')
        _ = os.execute(string.format("cmake -B build %s", flags)) and
            os.execute [[ 
                make -C build "$MAKEOPTS" DESTDIR= && 
                make -C build install DESTDIR="$DESTDIR"
            ]]
    end

    if t.build == "qmake" then
        local flags = table.concat(t.flags, ' ')
        _ = os.execute "qmake -makefile" and
            os.execute(
                string.format('make "$MAKEOPTS" DESTDIR= %s', flags)) and
            os.execute(
                string.format('make install DESTDIR="$DESTDIR" %s', flags))
    end
                
    if t.build == "make" then
        local flags = table.concat(t.flags, ' ')
        _ = os.execute(
                string.format('make "$MAKEOPTS" DESTDIR= %s', flags)) and
            os.execute(
                string.format('make install DESTDIR="$DESTDIR" %s', flags))
    end

    if t.build == "meson" then
        table.insert(t.flags, "-Dprefix=/usr")
        table.insert(t.flags, "-Dbuildtype=release")
        local flags = table.concat(t.flags, ' ')
        _ = os.execute(string.format("meson setup build %s", flags)) and
            os.execute("ninja -C build install")
    end

    if t.post then
        os.execute(t.post)
    end

    os.execute [[ 
        find "$DESTDIR" -exec touch -hd "@$SOURCE_DATE_EPOCH" '{}' + 
    ]]

    return makepkg(os.getenv("DESTDIR"))
end

function purge(pkgname)
    local fp = io.open(string.format("/usr/okpkg/index/%s.index", pkgname))
    if fp then
        chdir("/")
        for path in fp:lines() do
            os.remove(path)
        end
        fp:close()
        os.remove(string.format("/usr/okpkg/index/%s.index", pkgname))
    end
end

function install(file)
    local fp, buf, pkgname, offset

    local version = vstr(file)
    if #version > 0 then
        pkgname = basename(file:sub(1, #file-#version-8))
    else    
        pkgname = basename(file:sub(1, #file-7))
    end

    fp = io.popen(string.format("bsdtar -P -C / -xvf %s 2>&1", file))
    buf = fp:read("*a")
    buf = buf:gsub("^x ", "")
    buf = buf:gsub("\nx ", "\n")
    fp:close()
    fp = io.open(string.format("/usr/okpkg/index/%s.index", pkgname), "w")
    fp:write(buf)
    fp:close()
    os.execute("ldconfig")
end

function emerge(pkgname)
    download(pkgname)
    install(build(pkgname))
end

function timesync()
    local fp, buf
    fp = io.popen("nc time.nist.gov 13")
    buf = fp:read("*a")
    buf = buf:sub(8, 25)
    fp:close()
    os.execute(
        string.format("date +'%%y-%%m-%%d %%H:%%M:%%S' -u -s '%s'", buf))
    os.execute("hwclock --systohc --utc")
    os.exit()
end

function install_bootloader()
    os.execute [[
        efibootmgr -c -d /dev/nvme0n1 -p 1 -L 'slackware' -l '\vmlinuz' \
            -u 'root=/dev/nvme0n1p2 rw'
    ]]
    os.exit()
end

function build_kernel()
    chdir("/usr/src/linux")
    os.execute [[ 
        make clean
        cp kernel.config .config
        make -j5 bzImage modules 
        cp arch/x86/boot/bzImage /boot/efi/vmlinuz
        make modules_install
    ]]
    os.exit()
end
