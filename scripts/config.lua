-- /etc/okpkg: okpkg configuration

-- Main Configuration
local C = {
   ["distdir"]     = "/var/cache/ok/dist",
   ["indexdir"]    = "/usr/okpkg/index",
   ["okdir"]       = "/usr/okpkg",
   ["outdir"]      = "/var/cache/ok/out",
   ["pkgdir"]      = "/var/cache/ok/pkg",
   ["srcdir"]      = "/usr/src",
   cc = {
      ["cpu"]            = "skylake",
      ["optimize"]       =  2,
      ["fortify_source"] =  2,
      ["ssp"]            = "strong",
      ["cet"]            = "none",
      ["zero"]           = "zero",
      ["relro"]          =  "full",
      ["scp"]            =  true,
      ["pie"]            =  true,
      ["common"]         =  false,
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
   ["curl"]        = "/bin/curl -fsSLR",
   ["lzip"]        = "/bin/plzip",
   ["make"]        = "/bin/make -j5",
   ["meson"]       = "/opt/python3.13/bin/meson",
   ["ninja"]       = "/bin/samu",
   ["patch"]       = "/bin/patch -bp1",
   ["python"]      = "/opt/python3.13/bin/python3.13",
   ["tar"]         = "/bin/tar",
}

-- temporary
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

return C, M, E
