#!/usr/bin/env lua

require "utils"

local format, concat, unpack = 
    string.format, table.concat, unpack or table.unpack

-- environment
setenv("SOURCE_DATE_EPOCH", "1707097417")
setenv("MAKEOPTS", "-j5")
setenv("CFLAGS", "-O2 -march=x86-64 -fstack-protector-strong -fstack-clash-protection -fcommon -pipe")
setenv("CXXFLAGS", "-O2 -march=x86-64 -fstack-protector-strong -fstack-clash-protection -fcommon -pipe")

function patch(patchfile)
    local fp = io.open(patchfile)
    if fp then
        os.execute(format("patch -p1 <%s", patchfile))
        fp:close()
    end
end

function sha256sum(file)
    local fp = io.popen(format("sha256sum %s", file))
    local buf = fp:read("*a"):sub(1, 64)
    fp:close()
    return buf
end

function get_version(path)
    local s, i, j
    s = basename(path)
    i = s:find("[.-]%d") or 0
    j = s:find("%.t")
    return s:sub(i+1, j-1)
end

function vlook(pkgname)
    local databases = {"base", "extra"}
    for i=1,#databases do
        local fp = io.open(format("/usr/okpkg/db/%s.db", databases[i]))
        local buf = '\n' .. fp:read("*a")
        fp:close()
        local start = buf:find(format("\n%s = {", pkgname), 1, true)
        if start then
            buf = buf:sub(start+3+#pkgname, buf:find('};', start+1, true))
            return load("return" .. buf)()
        end
    end
end

function download(pkgname)
    local t = vlook(pkgname)

    os.execute(format("rm -r /usr/okpkg/sources/%s 2>/dev/null", pkgname))
    chdir("/usr/okpkg/sources")
    mkdir(pkgname)
    chdir(pkgname)

    -- download
    print(t.url) 
    os.execute(format("curl -LO %s", t.url))
    assert(not t.sha256 or t.sha256 == sha256sum(basename(t.url)))

    -- extract
    os.execute(format("tar --strip-components=1 -xf %s", basename(t.url)))
    os.remove(basename(t.url))

    -- patch
    patch(format("/usr/okpkg/patches/%s.diff", pkgname))

    -- download prerequisites (gcc)
    if pkgname:sub(1,3) == "gcc" then
        os.execute "./contrib/download_prerequisites"
    end
end

function makepkg(path)
    -- ensure path exists
    if chdir(path) ~= 0 then
        print(path .. " does not exist")
        os.exit()
    end

    -- ensure SOURCE_DATE_EPOCH exists
    if not os.getenv("SOURCE_DATE_EPOCH") then
        setenv("SOURCE_DATE_EPOCH", os.time())
    end

    path = basename(path)

    -- strip, delete-unneeded, timestamp, etc.
    os.execute [[
    {
        find . -name "*.pyc" -delete
        find . -name "*.la" -delete
        find . -name "lib*a" -exec strip -g '{}' +
        find . -name "lib*so*" -exec strip --strip-unneeded '{}' +
        find ./sbin -type f -exec strip -s '{}' +
        find ./bin -type f -exec strip -s '{}' +
        find ./usr/sbin -type f -exec strip -s '{}' +
        find ./usr/bin -type f -exec strip -s '{}' +
        find ./usr/libexec -type f -exec strip --strip-unneeded '{}' +
        rm -r usr/share/info usr/share/doc usr/doc 
    } 2>/dev/null
        tar --sort=name \
            --mtime="@${SOURCE_DATE_EPOCH}" \
            --owner=0 --group=0 --numeric-owner \
            -cf ../a.tar .
        ls -a | xargs rm -r 2>/dev/null
        xz --threads=2 -f ../a.tar
    ]]

    chdir("..")
    os.rename("a.tar.xz", path .. ".tar.xz")
    os.remove(path)

    return path .. ".tar.xz"
end

function build(pkgname)
    local _, t, version

    chdir(format("/usr/okpkg/sources/%s", pkgname))

    t = vlook(pkgname)
    t.flags = t.flags or {}
    version = get_version(t.url)
    setenv("DESTDIR",format("/usr/okpkg/packages/%s-%s-x86_64",pkgname,version))

    if t.pre_install then
        os.execute(t.pre_install)
    end

    if t.build == "./autogen.sh" then
        os.execute "./autogen.sh"
        table.insert(t.flags, "--prefix=/usr")
        _ = os.execute(format("./configure %s", concat(t.flags,' '))) and
            os.execute [[ 
                make $MAKEOPTS DESTDIR= && 
                make install DESTDIR=$DESTDIR
            ]]
    end

    if t.build == "autoreconf" then
        os.execute "autoreconf -fi --include=m4"
        table.insert(t.flags, "--prefix=/usr")
        _ = os.execute(format("./configure %s", concat(t.flags,' '))) and
            os.execute [[ 
                make $MAKEOPTS DESTDIR= && 
                make install DESTDIR=$DESTDIR
            ]]
    end

    if tostring(t.build):match("config") then
        if t.build:sub(1, 2) == ".." then
            mkdir("build")
            chdir("build")
        end
        table.insert(t.flags, "--prefix=/usr")
        _ = os.execute(format("%s %s", t.build, concat(t.flags,' '))) and
            os.execute [[ 
                make $MAKEOPTS DESTDIR= && 
                make install DESTDIR=$DESTDIR
            ]]
    end

    if t.build == "cmake" then
        table.insert(t.flags, "-DCMAKE_INSTALL_PREFIX=/usr")
        table.insert(t.flags, "-DCMAKE_BUILD_TYPE=Release")
        _ = os.execute(format("cmake -B build %s", concat(t.flags,' '))) and
            os.execute [[ 
                make -C build $MAKEOPTS DESTDIR= && 
                make -C build install DESTDIR=$DESTDIR
            ]]
    end

    if t.build == "qmake" then
        _ = os.execute "qmake -makefile" and
            os.execute(
                format("make $MAKEOPTS DESTDIR= %s", concat(t.flags,' '))) and
            os.execute(
                format("make install DESTDIR=$DESTDIR %s", concat(t.flags,' ')))
    end
                
    if t.build == "make" then
        _ = os.execute(
                format("make $MAKEOPTS DESTDIR= %s", concat(t.flags,' '))) and
            os.execute(
                format("make install DESTDIR=$DESTDIR %s", concat(t.flags,' ')))
    end

    if t.build == "meson" then
        table.insert(t.flags, "-Dprefix=/usr")
        table.insert(t.flags, "-Dbuildtype=release")
        _ = os.execute(format("meson setup build %s", concat(t.flags,' '))) and
            os.execute("ninja -C build install")
    end

    if t.post_install then
        os.execute(t.post_install)
    end

    return makepkg(os.getenv("DESTDIR"))
end

function purge(pkgname)
    local fp = io.open(format("/usr/okpkg/index/%s.index", pkgname))
    if fp then
        chdir("/")
        for path in fp:lines() do
            os.remove(path)
        end
        fp:close()
    end
end

function install(file)
    local fp, buf, pkgname, offset

    local version = get_version(file)
    pkgname = basename(file:sub(1, #file-#version-8))

    fp = io.popen(format("tar -P -C / -xhvf %s 2>&1", file))
    buf = fp:read("*a")
    fp:close()
    fp = io.open(format("/usr/okpkg/index/%s.index", pkgname), "w")
    fp:write(buf)
    fp:close()
    os.execute("ldconfig")
end

function emerge(pkgname)
    download(pkgname)
    install(build(pkgname))
end

function chroot(path)
    chdir(path)
    mkdir("proc")
    mkdir("sys")
    mkdir("dev")
    os.execute [[
        mount -t proc  -o ro /proc proc/
        mount -t sysfs -o ro /sys sys/
        mount --rbind  -o ro /dev dev/
        mount --make-rslave dev/
        PS1="(chroot)# " chroot --user=root . || exit
    ]]
    os.exit()
end

function timesync()
    local fp, buf
    fp = io.popen("nc time.nist.gov 13")
    buf = fp:read("*a")
    fp:close()
    os.execute(format("date +'%%y-%%m-%%d %%H:%%M:%%S' -u -s '%s'", buf:sub(8, 25)))
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
