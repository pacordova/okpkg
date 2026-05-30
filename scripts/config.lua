-- /etc/okpkg: okpkg configuration

local Dirs = {
   tab  = "/var/db/repos/okpkg/tab",
   idx  = "/var/db/repos/okpkg/idx",
   out  = "/var/cache/okpkg/out",
   pkg  = "/var/cache/okpkg/pkg",
   dist = "/var/cache/okpkg/dist",
   src  = "/usr/src",
}

-- Note: escape any dashes
local Mir = {
   ["https://ftp.gnu.org"] = "http://mirror.fcix.net",
   ["https://cran.r%-project.org"] = "https://archive.linux.duke.edu/cran",
}

-- Environment
local Env = {
   ["LC_ALL"]      = "POSIX",
   ["CONFIG_SITE"] = "/etc/config.site",
   ["curl"]        = "/bin/curl -fLR",
   ["lzip"]        = "/bin/plzip",
   ["make"]        = "/bin/make -j4",
   ["meson"]       = "/opt/python3.13/bin/meson",
   ["ninja"]       = "/bin/samu",
   ["patch"]       = "/bin/patch -bp1",
   ["python"]      = "/opt/python3.13/bin/python3.13",
   ["tar"]         = "/bin/tar",
}

local cflags = {
   "-march=skylake",
   "-O2",
   "-fstack-protector-strong",
   "-fstack-clash-protection",
   "-ftrivial-auto-var-init=zero",
   "-pipe",
}

Env.CFLAGS = table.concat(cflags, ' ')
Env.CXXFLAGS = table.concat(cflags, ' ')
Env.FORCE_UNSAFE_CONFIGURE = 1

return Dirs, Mir, Env
