-- /etc/okpkg: okpkg configuration

-- Main Configuration
local C = {
   ["okdir"]       = "/usr/okpkg",
   ["distdir"]     = "/var/cache/ok/dist",
   ["workdir"]     = "/var/cache/ok/src",
   ["outdir"]      = "/var/cache/ok/out",
   ["pkgdir"]      = "/var/cache/ok/pkg",
   ["indexdir"]    = "/usr/okpkg/index",
   cc = {
      ["cpu"]      = "skylake",
      ["optimize"] =  2,
      ["fort"]     =  2,
      ["ssp"]      = "strong",
      ["cet"]      = "none",
      ["zero"]     = "zero",
      ["relro"]    =  "full",
      ["scp"]      =  true,
      ["pie"]      =  true,
      ["common"]   =  false,
   }
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
   ["meson"]       = "meson",
}

-- temporary
local cflags = {
   "-march=skylake",
   "-O2",
   "-fstack-protector-strong",
   "-fstack-clash-protection",
   "-ftrivial-auto-var-init=zero",
   "-Wl,-z,relro,-z,now",
   "-pipe",
}

E.CFLAGS = table.concat(cflags, ' ')
E.CXXFLAGS = table.concat(cflags, ' ')

return C, M, E
