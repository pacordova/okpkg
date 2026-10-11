local cfg

cfg = {
   ["basedir"]     = "/usr/okpkg",
   ["datadir"]     = "/usr/okpkg/data",
   ["distdir"]     = "/var/cache/distfiles",
   ["wrkobjdir"]   = "/usr/src",
   ["pkgdir"]      = "/var/cache",
   ["state"]       = "/var/log/packages",
   ["site"]        = "/etc/config.site",
   ["jobs"]        = "5",
   ["cpu"]         = "skylake",
}

cfg.cflags = {
   "-O2",
   "-ftrivial-auto-var-init=zero",
   "-fstack-protector-strong",
   "-fstack-clash-protection",
}

return cfg
