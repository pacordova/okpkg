#!/usr/bin/env lua

local ok = require("okpkg")

chdir, mkdir, symlink = ok.chdir, ok.mkdir, ok.symlink

-- Change directory to root of new filesystem
chdir("/mnt")

-- Directory skeleton
mkdir("boot")
mkdir("boot/efi")
mkdir("dev")
mkdir("proc")
mkdir("etc")
mkdir("sys")
mkdir("etc/opt")
mkdir("etc/dinit.d")
mkdir("etc/skel")
mkdir("etc/ssl")
mkdir("etc/ssl/certs")
mkdir("etc/default")
mkdir("etc/sysconfig")
mkdir("mnt")
mkdir("root")
mkdir("tmp")
mkdir("usr")
mkdir("usr/bin")
mkdir("usr/include")
mkdir("usr/lib64")
mkdir("usr/lib64/pkgconfig")
mkdir("usr/lib64/locale")
mkdir("usr/libexec")
mkdir("usr/share")
mkdir("usr/share/color")
mkdir("usr/share/dict")
mkdir("usr/share/doc")
mkdir("usr/share/info")
mkdir("usr/share/locale")
mkdir("usr/share/man")
mkdir("usr/src")
mkdir("usr/share/man/man1")
mkdir("usr/share/man/man2")
mkdir("usr/share/man/man3")
mkdir("usr/share/man/man4")
mkdir("usr/share/man/man5")
mkdir("usr/share/man/man6")
mkdir("usr/share/man/man7")
mkdir("usr/share/man/man8")
mkdir("usr/share/misc")
mkdir("usr/share/terminfo")
mkdir("usr/share/zoneinfo")
mkdir("var")
mkdir("var/cache")
mkdir("var/home")
mkdir("var/lib")
mkdir("var/lib/color")
mkdir("var/lib/locate")
mkdir("var/lib/misc")
mkdir("var/lib/okpkg")
mkdir("var/local")
mkdir("var/log")
mkdir("var/mail")
mkdir("var/opt")
mkdir("var/spool")
mkdir("var/tmp")
mkdir("run")
mkdir("run/lock")
mkdir("run/shm")

-- Symlinks
symlink("lib64", "usr/lib")
symlink("/run/lock", "var/lock")
symlink("/run", "var/run")
symlink("usr/bin", "bin")
symlink("usr/lib64", "lib64")
symlink("usr/lib", "lib")
symlink("var/home", "home")
symlink("/proc/self/mounts", "etc/mtab")
symlink("/var/lib/okpkg/sources/linux-lts", "usr/src/linux")

-- Files
-- etc/config.site
-- etc/default/useradd
-- etc/group
-- etc/hostname
-- etc/hosts
-- etc/inputrc
-- etc/ld.so.conf
-- etc/nsswitch.conf
-- etc/passwd
-- etc/profile
-- etc/resolv.conf
-- etc/shells
-- etc/syslog.conf
-- dev/console
-- dev/null
--
os.execute [[
   touch var/log/{btmp,lastlog,faillog,wtmp}
   chgrp utmp /var/log/lastlog
   chmod 664  /var/log/lastlog
   chmod 600  /var/log/btmp
]]
