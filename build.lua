local function make(pkg)
    local pkgname = pkg.name
    local srcdir  = srcdir   .. "/" .. pkgname
    local destdir = destdir  .. "/" .. pkgname
    local flags = { unpack(pkg.flags) }

    exec {
        "make",
        "--directory=" .. srcdir,
        unpack(flags),
        "&&",
        "make install",
        "--directory=" .. srcdir,
        unpack(flags),
        "DESTDIR=" .. destdir
    }
end

local function configure(pkg)
    local pkgname = pkg.name
    local srcdir  = srcdir   .. "/" .. pkgname
    local dirflags = pkg.dirflags

    if dirflags == nil then
        dirflags = {
            "--localstatedir=/var",
            "--sysconfdir=/etc",
            "--libdir=/usr/lib64",
            "--bindir=/usr/bin",
            "--sbindir=/usr/sbin"
        }
    end

    local flags = {
        "--prefix=/usr",
        unpack(dirflags),
        unpack(pkg.flags)
    }

    exec {
        chdir(srcdir),
        "./configure",
        unpack(flags),
        "CFLAGS='" .. env.cflags .. "'",
    }

    make{name=pkgname, flags={""}}
end

local function configure2(pkg)
    local pkgname =  pkg.name
    local srcdir  =  srcdir  .. "/" .. pkgname
    local builddir = srcdir  .. "/" .. "build"
    local dirflags = pkg.dirflags

    if dirflags == nil then
        dirflags = {
            "--localstatedir=/var",
            "--sysconfdir=/etc",
            "--libdir=/usr/lib64",
            "--bindir=/usr/bin",
            "--sbindir=/usr/sbin"
        }
    end
    local flags = {
        unpack(dirflags),
        unpack(pkg.flags)
    }

    cleandir(builddir)

    exec {
        chdir(builddir),
        printenv(),
        "../configure",
        unpack(flags)
    }
    make{}
end

local function autoreconf(pkg)
    local pkgname = pkg.name
    local srcdir  = srcdir   .. "/" .. pkgname
    local autogen = io.open(srcdir .. "/autogen.sh")

    if (autogen ~= nil) then
        fd:close()
        local cmd = "./autogen.sh"
    else
        local cmd = "autoreconf -fi -I m4"
    end

    exec{chdir(srcdir),cmd}

    configure(pkg)
end

local function cmake(pkg)
    local pkgname = pkg.name
    local srcdir   = srcdir .. "/" .. pkgname
    local builddir = srcdir .. "/" .. "build"

    local flags = {
        "-DCMAKE_INSTALL_PREFIX=/usr",
        "-DCMAKE_BUILD_TYPE=Release",
        unpack(pkg.flags)
    }

    cleandir(builddir)

    exec {
        chdir(builddir),
        printenv(),
        "/usr/bin/cmake",
        unpack(flags)
    }
    make{}
end

local function meson(pkg)
    local pkgname = pkg.name
    local srcdir  = srcdir  .. "/" .. pkgname
    local destdir = destdir .. "/" .. pkgname
    local builddir = srcdir .. "/" .. "build"

    local flags = {
        "-Dprefix=/usr",
        "-Dbuildtype=release",
        unpack(pkg.flags)
    }

    cleandir(builddir)


    -- run meson
    exec {
        chdir(srcdir),
        "/usr/bin/meson",
        "build",
        unpack(flags)
    }

    -- run ninja
    exec {
        chdir(srcdir),
        printenv(),
        "DESTDIR=" .. destdir,
        "/usr/bin/ninja",
        "-C build",
        "install"
    }
end

local function scons(pkg)
    local pkgname = pkg.name
    local destdir = destdir .. "/" .. pkgname
    local flags = {
        "prefix=/usr",
        "DESTDIR=" .. destdir,
        unpack(pkg.flags)
    }
    exec {
        chdir(srcdir),
        printenv(),
        "scons",
        unpack(flags),
        "install"
    }
end

local function waf(pkg)
    local pkgname = pkg.name
    local srcdir  = srcdir   .. "/" .. pkgname
    local destdir = destdir  .. "/" .. pkgname
    exec {
        chdir(srcdir),
        printenv(),
        "python3 bootstrap.py &&",
        "python3 waf configure --prefix=/usr &&",
        "python3 waf &&",
        "python3 waf install --destdir=" .. destdir
    }
end

local function qmake(pkg)
    local pkgname = pkg.name
    local srcdir  = srcdir   .. "/" .. pkgname
    local destdir = destdir  .. "/" .. pkgname
    local flags = {
        "INSTALL_ROOT=" .. destdir,
        unpack(pkg.flags)
    }
    exec {
        chdir(srcdir),
        printenv(),
        "/usr/bin/qmake",
        "-makefile"
    }
    make(pkg)
end

return {
    make       = make,
    configure  = configure,
    configure2 = configure2,
    autoreconf = autoreconf,
    cmake      = cmake,
    meson      = meson,
    scons      = scons,
    waf        = waf,
    qmake      = qmake
}
