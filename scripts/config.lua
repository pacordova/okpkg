#!/bin/lua

local Dirs = {
   distfiles  = "/var/cache/distfiles",
   log        = "/var/log/packages",
   out        = "/var/db/repos/okpkg/out",
   packages   = "/var/cache/packages",
   patches    = "/var/db/repos/okpkg/patches",
   src        = "/usr/src",
   tabs       = "/var/db/repos/okpkg/tabs",
}

-- Note: escape any dashes
local Mir = {
   ["https://ftp.gnu.org"]         = "http://mirror.fcix.net",
   ["https://cran.r%-project.org"] = "https://archive.linux.duke.edu/cran",
}

local Env = {
   ["LC_ALL"]      = "POSIX",
   ["CONFIG_SITE"] = "/etc/config.site",
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
