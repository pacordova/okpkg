#!/bin/lua
ok = require"okutils"
ok.chdir(arg[1])
ok.mount(".", ".", nil, 4096, nil)
ok.mount("/proc", "proc", "proc", 544783, "hidepid=1")
ok.mount("/sys", "sys", "sysfs", 544783, nil)
ok.mount("/dev", "dev", "devtmpfs", 544771, nil)
ok.chroot(".")
