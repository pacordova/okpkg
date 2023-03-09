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
        "./configure",
        unpack(flags),
        "CFLAGS='" .. env.cflags .. "'",
    }

    make{name=pkgname, flags={""}}
end

local function configure2(pkg)
    local pkgname =  pkg.name
    local srcdir  =  srcdir  .. "/" .. pkgname
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

    makedir("build")
    chdir("build")

    exec {
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
        exec {
            "./autogen.sh"
        }
    else
        exec { 
            "/usr/bin/autoreconf",
            "--force",
            "--install",
            "--include=m4" 
        }
    end

    configure(pkg)
end

local function cmake(pkg)
    local pkgname = pkg.name
    local srcdir   = srcdir .. "/" .. pkgname

    local flags = {
        "-DCMAKE_INSTALL_PREFIX=/usr",
        "-DCMAKE_BUILD_TYPE=Release",
        unpack(pkg.flags)
    }

    makedir("build")
    chdir("build")

    exec {
        "/usr/bin/cmake",
        unpack(flags)
    }
    make{}
end

local function meson(pkg)
    local pkgname = pkg.name
    local srcdir  = srcdir  .. "/" .. pkgname
    local destdir = destdir .. "/" .. pkgname

    local flags = {
        "-Dprefix=/usr",
        "-Dbuildtype=release",
        unpack(pkg.flags)
    }

    makedir("build")


    -- run meson
    exec {
        "/usr/bin/meson",
        "build",
        unpack(flags)
    }

    -- run ninja
    exec {
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
