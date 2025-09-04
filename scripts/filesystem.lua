#!/usr/bin/env lua

local ok = require("okpkg")

chdir, mkdir, symlink = ok.chdir, ok.mkdir, ok.symlink

-- Change directory to root of new filesystem
chdir("/mnt")

-- Directory skeleton
mkdir("boot")
mkdir("boot/efi")
mkdir("dev")
mkdir("etc")
mkdir("etc/default")
mkdir("etc/dinit.d")
mkdir("etc/skel")
mkdir("etc/ssl")
mkdir("etc/ssl/certs")
mkdir("etc/sysconfig")
mkdir("mnt")
mkdir("proc")
mkdir("root")
mkdir("run")
mkdir("run/lock")
mkdir("run/shm")
mkdir("sys")
mkdir("tmp")
mkdir("usr")
mkdir("usr/bin")
mkdir("usr/include")
mkdir("usr/lib64")
mkdir("usr/lib64/locale")
mkdir("usr/lib64/pkgconfig")
mkdir("usr/libexec")
mkdir("usr/share")
mkdir("usr/share/doc")
mkdir("usr/share/locale")
mkdir("usr/share/man")
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
mkdir("usr/src")
mkdir("var")
mkdir("var/cache")
mkdir("var/home")
mkdir("var/lib")
mkdir("var/lib/okpkg")
mkdir("var/local")
mkdir("var/log")
mkdir("var/mail")
mkdir("var/opt")
mkdir("var/spool")
mkdir("var/tmp")

-- Symlinks
symlink("lib64", "usr/lib")
symlink("/proc/self/mounts", "etc/mtab")
symlink("/run/lock", "var/lock")
symlink("/run", "var/run")
symlink("usr/bin", "bin")
symlink("usr/lib64", "lib64")
symlink("usr/lib", "lib")
symlink("var/home", "home")
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
