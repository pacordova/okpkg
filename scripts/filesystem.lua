#!/usr/bin/env lua

local ok = require("okpkg")

local chdir, mkdir, symlink = ok.chdir, ok.mkdir, ok.symlink

local fp, buf

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

-- /etc/ld.so.conf
fp = io.open("etc/ld.so.conf", 'w')
fp:write("/usr/lib64")
fp:close()

-- /etc/hostname
fp = io.open("etc/hostname", 'w')
fp:write("myhost")
fp:close()

-- /etc/hosts
fp = io.open("etc/hosts", 'w')
fp:write [[
127.0.0.1  localhost myhost
::1        localhost
]]
fp:close()


-- /etc/config.site
fp = io.open("etc/config.site", 'w')
fp:write [[
test "$libdir" = '${exec_prefix}/lib' && libdir=/usr/lib64
test "$localstatedir" = '${prefix}/var' && localstatedir=/var
test "$runstatedir" = '${localstatedir}/run' && runstatedir=/run
test "$sharedstatedir" = '${prefix}/com' && sharedstatedir=/var/lib
test "$sysconfdir" = '${prefix}/etc' && sysconfdir=/etc
test "$sbindir" = '${exec_prefix}/sbin' && sbindir=/usr/bin
test "$libexecdir" = '${exec_prefix}/libexec' && libexecdir=/usr/libexec
test -z "$with_pic" && with_pic=yes
test -z "$enable_pic" && enable_pic=yes
test -z "$enable_shared" && enable_shared=yes
test -z "$enable_static" && enable_static=no
test -z "$enable_nls" && enable_nls=no
test -z "$enable_rpath" && enable_rpath=no
test -z "$enable_tests" && enable_tests=no
test -z "$enable_werror" && enable_werror=no
test -z "$enable_debug" && enable_debug=no
]]
fp:close()

-- /etc/nsswitch.conf
fp = io.open("etc/nsswitch.conf", 'w')
fp:write [[
passwd:     files
group:      files
shadow:     files
hosts:      files dns
networks:   files
protocols:  files
services:   files
ethers:     files
rpc:        files
]]
fp:close()


-- /etc/default/useradd
fp = io.open("etc/default/useradd", 'w')
fp:write [[
GROUP=999
GROUPS=audio,video,input
HOME=/var/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/bash
SKEL=/etc/skel
CREATE_MAIL_SPOOL=yes
LOG_INIT=yes
]]

-- mknod
os.execute("mknod -m 600 dev/console c 5 1")
os.execute("mknod -m 666 dev/null c 1 3")


-- Files
-- etc/group
-- etc/inputrc
-- etc/nsswitch.conf
-- etc/passwd
-- etc/profile
-- etc/resolv.conf
-- etc/shells
-- etc/syslog.conf
-- dev/console
-- dev/null
