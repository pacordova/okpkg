local cfg

cfg = {
   ["basedir"]     = "/usr/okpkg",
   ["datadir"]     = "/usr/okpkg/data",
   ["distdir"]     = "/var/cache/distfiles",
   ["wrkobjdir"]   = "/usr/src",
   ["pkgdir"]      = "/var/cache/packages",
   ["state"]       = "/var/log/packages",
   ["site"]        = "/etc/config.site",
   ["jobs"]        = "5",
}

cfg.cflags = {
   ["cpu"]           = "skylake",
   ["opt_level"]     = "2",
   ["auto_var_init"] = "zero",
   ["ssp"]           = "strong",
}

return cfg
