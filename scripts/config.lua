-- /etc/okpkg: okpkg configuration

-- Directories
local C = {
   ["distdir"]     = "/var/cache/ok/dist",
   ["indexdir"]    = "/usr/okpkg/index",
   ["okdir"]       = "/usr/okpkg",
   ["outdir"]      = "/var/cache/ok/out",
   ["pkgdir"]      = "/var/cache/ok/pkg",
   ["srcdir"]      = "/usr/src",
}

-- Note: escape any dashes
local M = {
   ["https://ftp.gnu.org"] = "http://mirror.fcix.net",
   ["https://cran.r%-project.org"] = "https://archive.linux.duke.edu/cran",
}

-- Environment
local E = {
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

local cc = {
   ["cpu"]            = "skylake",
   ["optimize"]       =  2,
   ["ssp"]            = "strong",
   ["cet"]            = "none",
   ["init_stack"]     = "zero",
   ["scp"]            =  true,
 --["pie"]            =  true,
 --["common"]         =  false,
}

local cflags = {
   "-march=skylake",
   "-O2",
   "-fstack-protector-strong",
   "-fstack-clash-protection",
   "-ftrivial-auto-var-init=zero",
   "-pipe",
}

E.CFLAGS = table.concat(cflags, ' ')
E.CXXFLAGS = table.concat(cflags, ' ')
E.FORCE_UNSAFE_CONFIGURE = 1

return C, M, E
