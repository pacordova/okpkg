unpack = table.unpack
concat = table.concat

local function make(pkg)
    if (pkg.flags == nil) then
        pkg.flags = {}
    end
    os.execute(
        "make -C " .. srcdir .. " " .. concat(pkg.flags, " ") .. " && " ..
        "make install -C " .. srcdir .. " " .. concat(pkg.flags, " ") ..
            " DESTDIR=" .. destdir
    )
end

local function configure(pkg)
    if (pkg.dirflags == nil) then
        pkg.dirflags = {
            "--localstatedir=/var",
            "--sysconfdir=/etc",
            "--libdir=/usr/lib64",
            "--bindir=/usr/bin",
            "--sbindir=/usr/sbin"
        }
    end
    local flags = {
        unpack(pkg.dirflags),
        unpack(pkg.flags)
    }
    os.execute("cd " .. srcdir .. " && ./configure " .. concat(flags, " "))
    make({})
end

local function configure2(pkg)
    local builddir = srcdir .. "/build"
    if (pkg.dirflags == nil) then
        pkg.dirflags = {
            "--localstatedir=/var",
            "--sysconfdir=/etc",
            "--libdir=/usr/lib64",
            "--bindir=/usr/bin",
            "--sbindir=/usr/sbin"
        }
    end
    local flags = {
        unpack(pkg.dirflags),
        unpack(pkg.flags)
    }
    os.execute("mkdir " .. builddir)
    os.execute("cd " .. builddir .. " && " .. "../configure " .. concat(flags, " "))
    make({})
end

local function autoreconf(pkg)
    local file = srcdir .. "/autogen.sh"
    local fd   = io.open(file)
    if (fd ~= nil) then
        fd:close()
        local cmd = "./autogen.sh"
    else
        local cmd = "autoreconf -fi -I m4"
    end
    os.execute("cd " .. srcdir .. " && " .. cmd)
    configure(pkg)
end

local function cmake(pkg)
    local builddir = srcdir .. "/build"
    local flags = {
        "-DCMAKE_INSTALL_PREFIX=/usr",
        "-DCMAKE_BUILD_TYPE=Release",
        unpack(pkg.flags)
    }
    os.execute("mkdir " .. builddir)
    os.execute(
        "cd " .. builddir " && " ..
        "cmake .. " .. concat(flags, " ")
    )
    make({})
end

local function meson(pkg)
    local flags = {
        "-Dprefix=/usr",
        "-Dbuildtype=release",
        unpack(pkg.flags)
    }
    os.execute(
        "cd " .. srcdir .. " && " ..
        "meson build " .. concat(flags, " ") .. " && " ..
        "DESTDIR=" .. destdir .. " ninja -C build install"
    )
end

local function scons(pkg)
    local flags = {
        "prefix=/usr",
        "DESTDIR=" .. destdir,
        unpack(pkg.flags)
    }
    os.execute("scons " .. concat(flags, " ") .. " install")
end

local function waf(pkg)
    os.execute(
        "cd " .. srcdir .. " && " ..
        "python3 boostrap.py && " ..
        "python3 waf configure --prefix=/usr" .. " && " ..
        "python3 waf && " ..
        "python3 waf install --destdir=" .. destdir
    )
end

local function qmake(pkg)
    local flags = {
        "INSTALL_ROOT=" .. destdir,
        unpack(pkg.flags)
    }
    os.execute(
        "cd " .. srcdir .. " && " ..
        "qmake -makefile"
    )
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
