-- /etc/okpkg: okpkg configuration

-- Main Configuration
local C = {
   ["okdir"]       = "/usr/okpkg",
   ["distdir"]     = "/var/cache/ok/dist",
   ["workdir"]     = "/var/cache/ok/src",
   ["outdir"]      = "/var/cache/ok/out",
   ["pkgdir"]      = "/var/cache/ok/pkg",
   ["indexdir"]    = "/usr/okpkg/index",
   ["cflags"] = {
      "-march=skylake",
      "-O2",
      "-fstack-protector-strong",
      "-fstack-clash-protection",
      "-fcommon",
      "-pipe"
   },
}

-- Mirrors (note: escape any dashes)
local M = {
   ["https://ftp.gnu.org"] = "http://mirror.fcix.net",
   ["https://cran.r%-project.org"] = "https://archive.linux.duke.edu/cran",
}

-- Environment
local E = {
   ["LC_ALL"]      = "POSIX",
   ["CONFIG_SITE"] = "/etc/config.site",
   ["MAKEFLAGS"]   = "-j5",
   ["curl"]        = "curl -#fLR",
   ["ninja"]       = "samu",
   ["patch"]       = "patch -b -p1",
   ["CFLAGS"]      = table.concat(C.cflags, ' '),
   ["CXXFLAGS"]    = table.concat(C.cflags, ' '),
}

return C, E, M
