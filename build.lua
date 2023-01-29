local sys   = require 'unix'

unpack = table.unpack
local paste = sys.paste

local function make(env, flags)
    local cmd = {
        "/usr/bin/make",
        "--directory=" .. env.srcdir,
        unpack(flags),
        "&&",
        "/usr/bin/make",
        "--directory=" .. env.srcdir,
        "install",
        unpack(flags),
        "DESTDIR=" .. env.destdir
    }
    os.execute(paste(cmd))
end

local function configure(env, flags)
    local cmd = {
        "cd", env.srcdir, "&&",
        "./configure", unpack(flags)
    }
    make(env, {})
end

local function configure2(env, flags)
    local builddir = env.srcdir .. "/build"
    local cmd = {
        "/usr/bin/mkdir", builddir, "&&",
        "cd", builddir, "&&",
        "../configure", unpack(flags)
    }
    make(env, {})
end

local function autoreconf(env, flags)
    local file = env.srcdir .. "/autogen.sh"
    local fd   = io.open(file)
    if (fd ~= nil) then
        fd:close()
        local cmd = {
            "cd", env.srcdir, "&&",
            "./autogen.sh"
        }
    else
        local cmd = {
            "cd", env.srcdir, "&&",
            "autoreconf -fi -I m4"
        }
    end

    os.execute(paste(cmd))
    configure(env, flags)
end

local function cmake(env, flags)
    local builddir = env.srcdir .. "/build"
    local flags = {
        "-DCMAKE_INSTALL_PREFIX=" .. env.prefix,
        "-DCMAKE_BUILD_TYPE=Release",
        unpack(flags)
    }
    local cmd = {
        "/usr/bin/mkdir", builddir, "&&",
        "cd", builddir, "&&",
        "/usr/bin/cmake", "..", unpack(flags)
    }
    os.execute(paste(cmd))
    make(env, {})
end

local function meson(env, flags)
    local flags = {
        "-Dprefix=" .. env.prefix,
        "-Dbuildtype=release",
        unpack(flags)
    }
    local cmd = {
        "cd", env.srcdir, "&&",
        "/usr/bin/meson", "build", unpack(flags), "&&",
        "DESTDIR=" .. env.destdir,
        "/usr/bin/ninja -C build install"
    }
    os.execute(paste(cmd))
end

local function scons(env, flags)
    local flags = {
        "prefix=" .. env.prefix,
        "DESTDIR=" .. env.destdir,
        unpack(flags)
    }
    local cmd = {
        "/usr/bin/scons", unpack(flags), "install"
    }
    os.execute(paste(cmd))
end

local function waf(env, flags)
    local cmd = {
        "cd", env.srcdir, "&&",
        "/usr/bin/python3", "bootstrap.py", "&&",
        "/usr/bin/python3", "waf", "configure", "--prefix=" .. env.prefix, "&&",
        "/usr/bin/python3", "waf", "&&",
        "/usr/bin/python3", "waf", "install", "--destdir=" .. env.destdir
    }
    os.execute(paste(cmd))
end

local function qmake(env, flags)
    local flags = {
        "INSTALL_ROOT=" .. env.destdir,
        unpack(flags)
    }
    local cmd = {
        "cd", env.srcdir, "&&",
        "/usr/bin/qmake -makefile"
    }
    make(env, flags)
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
