-- /etc/okpkg: okpkg configuration

local C, E, M

-- Main Configuration
C = {
   ["okdir"]       = "/usr/okpkg",
   ["distdir"]     = "/var/cache/ok/dist",
   ["workdir"]     = "/var/cache/ok/src",
   ["outdir"]      = "/var/cache/ok/out",
   ["pkgdir"]      = "/var/cache/ok/pkg",
   ["indexdir"]    = "/usr/okpkg/index",
   ["config_site"] = "/etc/config.site",
   ["login"]       = "pac",
   ["tz"]          = "US/Eastern",
   ["ninja"]       = "/usr/bin/samu",
   ["meson"]       = "/usr/bin/meson",
   ["cflags"] = {
      "-O2",
      "-march=x86-64-v2",
      "-fstack-protector-strong",
      "-fstack-clash-protection",
      "-fcommon",
      "-pipe"
   },
   ["jobs"] = 5,
}

-- Mirrors
-- Note: Excape any dashes
M = {
   ["https://ftp.gnu.org"]         = "http://mirror.fcix.net",
   ["https://cran.r%-project.org"] = "https://archive.linux.duke.edu/cran",
}

-- Environment
E = {
   ["LC_ALL"]      = "POSIX",
   ["CONFIG_SITE"] = "/etc/config.site",
   ["CFLAGS"]      = table.concat(C.cflags, ' '),
   ["CXXFLAGS"]    = table.concat(C.cflags, ' '),
   ["MAKEFLAGS"]   = "-j5",
   ["ninja"]       = C.ninja,
   ["meson"]       = C.meson,
   ["patch"]       = "patch -b -p1",
}

return {C, E, M}
