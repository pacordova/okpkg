-- /etc/okpkg.conf

local DIR = {
   ["OKPKG"]    = "/usr/okpkg",
   ["DATADIR"]  = "/usr/okpkg/data",
   ["TMPDIR"]   = "/usr/src",
   ["DISTDIR"]  = "/var/cache/distfiles",
   ["PKGDIR"]   = "/var/cache/packages",
   ["LOG"]      = "/var/log/packages",
}

-- Note: escape any dashes
local M = {
   ["https://ftp.gnu.org"]         = "http://mirror.fcix.net",
   ["cran.r%-project.org"]         = "cloud.r-project.org",
}

local E = {
   ["CFLAGS"]      = "-march=skylake -O2 -pipe -ftrivial-auto-var-init=zero " ..
                     "-fstack-protector-strong -fstack-clash-protection",
   ["CXXFLAGS"]    = "-march=skylake -O2 -pipe -ftrivial-auto-var-init=zero " ..
                     "-fstack-protector-strong -fstack-clash-protection",
   ["LC_ALL"]      = "POSIX",
   ["CONFIG_SITE"] = "/etc/config.site",
   ["PYTHONHOME"]  = "/opt/python3.13",
   ["cmake"]       = "/opt/cmake/bin/cmake",
   ["lzip"]        = "/bin/plzip",
   ["make"]        = "/bin/make -j4",
   ["meson"]       = "/opt/python3.13/bin/meson",
   ["ninja"]       = "/bin/samu",
   ["patch"]       = "/bin/patch -bp1",
   ["tar"]         = "/bin/tar",
}


return DIR, M, E
