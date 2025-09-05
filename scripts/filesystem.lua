#!/usr/bin/env lua

local ok = require("okpkg")

local chdir, mkdir, symlink = ok.chdir, ok.mkdir, ok.symlink

local file

-- Change directory to root of new filesystem
chdir(os.getenv("destdir"))

-- Remove directory fresh partition
os.remove("lost+found")

--------------
-- Skeleton --
--------------
mkdir("boot")
mkdir("boot/efi")
mkdir("dev")
mkdir("etc")
mkdir("etc/default")
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
mkdir("var/local")
mkdir("var/log")
mkdir("var/mail")
mkdir("var/opt")
mkdir("var/spool")
mkdir("var/tmp")

--------------
-- Symlinks --
--------------
symlink("lib64", "usr/lib")
symlink("/proc/self/mounts", "etc/mtab")
symlink("/run/lock", "var/lock")
symlink("/run", "var/run")
symlink("usr/bin", "bin")
symlink("usr/lib64", "lib64")
symlink("usr/lib", "lib")
symlink("var/home", "home")
symlink("/var/lib/okpkg/sources/linux-lts", "usr/src/linux")

------------------
-- System Files --
------------------
--------------------------------------------------------------------------------
file = io.open("etc/ld.so.conf", 'w')
file:write("/usr/lib64")
file:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
file = io.open("etc/hostname", 'w')
file:write("myhost")
file:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
file = io.open("etc/hosts", 'w')
file:write([[
127.0.0.1  localhost myhost
::1        localhost
]])
file:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
file = io.open("etc/config.site", 'w')
file:write([[
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
]])
file:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
file = io.open("etc/nsswitch.conf", 'w')
file:write([[
passwd:     files
group:      files
shadow:     files
hosts:      files dns
networks:   files
protocols:  files
services:   files
ethers:     files
rpc:        files
]])
file:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
file = io.open("etc/default/useradd", 'w')
file:write([[
GROUP=999
GROUPS=audio,video,input
HOME=/var/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/bash
SKEL=/etc/skel
CREATE_MAIL_SPOOL=yes
LOG_INIT=yes
]])
file:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
file = io.open("etc/passwd")
file:write([[
root::0:0:root:/root:/usr/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
atd:x:17:17:atd daemon:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
ntp:x:87:87:Network Time Protocol:/var/empty:/usr/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/usr/bin/false
]])
file:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
file = io.open("etc/group")
file:write([[
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
atd:x:17:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
nogroup:x:99:
users:x:999:
]])
file:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
file = io.open("etc/profile", 'w')
file:write([[
if test `id -u` = 0; then export PS1='# '; else export PS1='$ '; fi
export LANG=en_US.utf8
]])
file:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
file = io.open("etc/inputrc", 'w')
file:write([[
set meta-flag On
set input-meta On
set convert-meta Off
set output-meta On
set bell-style none
set enable-keypad on
"\eOd": backward-word
"\eOc": forward-word
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert
"\eOH": beginning-of-line
"\eOF": end-of-line
"\e[H": beginning-of-line
"\e[F": end-of-line
]])
file:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
file = io.open("etc/resolv.conf", 'w')
file:write("nameserver 8.8.8.8")
file:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
file = io.open("etc/shells", 'w')
file:write([[
/bin/sh
/bin/bash
]])
file:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
file = io.open("etc/syslog.conf", 'w')
file:write([[
auth,authpriv.*                  /var/log/auth.log
*.*;auth,authpriv.none          -/var/log/syslog
kern.*                          -/var/log/kern.log
mail.*                          -/var/log/mail.log
mail.err                         /var/log/mail.err
*.=emerg *

*.=info;*.=notice;*.=warn;\
        auth,authpriv.none;\
        cron,daemon.none;\
        mail,news.none          -/var/log/messages
]])
file:close()
--------------------------------------------------------------------------------

--------------
-- Finalize --
--------------
os.execute([[
   mknod -m 600 dev/console c 5 1
   mknod -m 666 dev/null c 1 3
   curl -LO "https://curl.se/ca/cacert.pem"
   mv cacert.pem etc/ssl/certs/ca-certificates.crt
   cp -rp /etc/dinit.d etc/dinit.d
   git clone /var/lib/okpkg var/lib/okpkg
   git -C var/lib/okpkg repack -adf --depth=1
   mkdir -p var/lib/okpkg/{packages,download}
   cp -p /var/lib/okpkg/download/* var/lib/okpkg/download
   tar -xhf /var/lib/okpkg/packages/a/linux-lts-*.tar.lz
   cp -p /var/lib/okpkg/packages/a/linux-lts-*.tar.lz var/lib/okpkg/packages
]])
