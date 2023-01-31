unpack = table.unpack
concat = table.concat

local function make(env, flags)
    os.execute(
        "make -C " .. env.srcdir .. " " .. concat(flags, " ") .. " && " ..
        "make install -C " .. env.srcdir .. " " .. concat(flags, " ") ..
            " DESTDIR=" .. env.destdir
    )
end

local function configure(env, flags)
    local flags = {
        "--localstatedir=" .. env.localstatedir,
        "--sysconfdir="     .. env.sysconfdir,
        "--libdir="        .. env.libdir,
        "--bindir="        .. env.bindir,
        "--sbindir="       .. env.sbindir,
        unpack(flags)
    }
    os.execute("cd " .. env.srcdir .. " && ./configure " .. concat(flags, " "))
    make(env, {})
end

local function configure2(env, flags)
    local builddir = env.srcdir .. "/build"
    local flags = {
        "--localstatedir=" .. env.localstatedir,
        "--sysconfdir"     .. env.sysconfdir,
        "--libdir="        .. env.libdir,
        "--bindir="        .. env.bindir,
        "--sbindir="       .. env.sbindir,
        unpack(flags)
    }
    os.execute("mkdir " .. builddir)
    os.execute("cd " .. builddir .. " && " .. "../configure " .. concat(flags, " "))
    make(env, {})
end

local function autoreconf(env, flags)
    local file = env.srcdir .. "/autogen.sh"
    local fd   = io.open(file)
    if (fd ~= nil) then
        fd:close()
        local cmd = "./autogen.sh"
    else
        local cmd = "autoreconf -fi -I m4"
    end
    os.execute("cd " .. env.srcdir .. " && " .. cmd)
    configure(env, flags)
end

local function cmake(env, flags)
    local builddir = env.srcdir .. "/build"
    local flags = {
        "-DCMAKE_INSTALL_PREFIX=" .. env.prefix,
        "-DCMAKE_BUILD_TYPE=Release",
        unpack(flags)
    }
    os.execute("mkdir " .. builddir)
    os.execute(
        "cd " .. builddir " && " ..
        "cmake .. " .. concat(flags, " ")
    )
    make(env, {})
end

local function meson(env, flags)
    local flags = {
        "-Dprefix=" .. env.prefix,
        "-Dbuildtype=release",
        unpack(flags)
    }
    os.execute(
        "cd " .. env.srcdir .. " && " ..
        "meson build " .. concat(flags, " ") .. " && " ..
        "DESTDIR=" .. env.destdir .. " ninja -C build install"
    )
end

local function scons(env, flags)
    local flags = {
        "prefix=" .. env.prefix,
        "DESTDIR=" .. env.destdir,
        unpack(flags)
    }
    os.execute("scons " .. concat(flags, " ") .. " install")
end

local function waf(env, flags)
    os.execute(
        "cd " .. env.srcdir .. " && " ..
        "python3 boostrap.py && " ..
        "python3 waf configure --prefix=" .. env.prefix .. " && " ..
        "python3 waf && " ..
        "python3 waf install --destdir=" .. env.destdir
    )
end

local function qmake(env, flags)
    local flags = {
        "INSTALL_ROOT=" .. env.destdir,
        unpack(flags)
    }
    os.execute(
        "cd " .. env.srcdir .. " && " ..
        "qmake -makefile"
    )
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
