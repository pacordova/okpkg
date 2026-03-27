-- /etc/okpkg: okpkg configuration

-- Main Configuration
local C = {
   ["okdir"]       = "/usr/okpkg",
   ["distdir"]     = "/var/cache/ok/dist",
   ["workdir"]     = "/var/cache/ok/src",
   ["outdir"]      = "/var/cache/ok/out",
   ["pkgdir"]      = "/var/cache/ok/pkg",
   ["indexdir"]    = "/usr/okpkg/index",
   ["opt-level"]   = 2
   ["cpu"]         = "skylake"
   ["cflags"] = {
      "-march=skylake",
      "-O2",
      "-fstack-protector-strong",
      "-fstack-clash-protection",
      "-fcommon",
      "-pipe"
   },
}

local cflags = {
   ["optimize"] =  2,              -- -Olevel 
   ["cpu"]      = "skylake",       -- -march=cpu
   ["ssp"]      = "strong",        -- -fstack-protector{,-all,-strong,-explicit}
   ["cet"]      = "none",          -- -fcf-protection=[full|branch|return|none|check]
   ["zeroinit"] = "uninitialized", -- -ftrivial-auto-var-init=[uninitialized|pattern|zero]
   ["scp"]      = true,            -- -fstack-clash-protection
   ["pie"]      =  true,           -- -fpie -pie 
   ["relro"]    =  true,           -- -Wl,-z,relro,-z,now
   ["common"]   =  true,           -- -f{,no-}common
   ["pipe"]     =  true,           -- -pipe
   ["frtfy"]    =  false,          -- -D_FORTIFY_SOURCE=[0-3]
   ["assert"]   =  false,          -- -D_GLIBCXX_ASSERTIONS
}

cflags = string.format("%s -O%s -march=%s -fcf-protection=%s
cflags.ssp = ("-f%sstack-protector-%s"):format( 
   unpack {{"no-",""},{"",""},{"","-all"},{"","-strong"}}[cflags.ssp])
)

if cflags.ssp == "no" then
   cflags.ssp = "-fno-stack-protector"
elseif cflags.ssp == "yes" then
   cflags.ssp = "-fstack-protector"
else
   cflags.ssp = "-fstack-protector-" .. cflags.ssp
end



local cflags = "-O{optimize} -march={cpu} {SSP[ssp]} 

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
   ["CFLAGS"]      = table.concat(C.cflags, ' '),
   ["CXXFLAGS"]    = table.concat(C.cflags, ' '),
}

return C, M, E
