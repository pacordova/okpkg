#!/usr/bin/env lua

local fp, ok

ok = require("okutils")

-- Change directory to root of new filesystem
ok.chdir(os.getenv("destdir"))

-- Cleanup
os.remove("lost+found")

--------------
-- Skeleton --
--------------
ok.mkdir("./bin")
ok.mkdir("./boot")
ok.mkdir("./boot/efi")
ok.mkdir("./etc")
ok.mkdir("./etc/default")
ok.mkdir("./etc/ssl")
ok.mkdir("./etc/ssl/certs")
ok.mkdir("./lib64")
ok.mkdir("./lib64/locale")
ok.mkdir("./lib64/pkgconfig")
ok.mkdir("./mnt")
ok.mkdir("./root")
ok.mkdir("./run/shm")
ok.mkdir("./tmp")
ok.mkdir("./usr")
ok.mkdir("./usr/include")
ok.mkdir("./usr/man")
ok.mkdir("./usr/man/man1")
ok.mkdir("./usr/man/man2")
ok.mkdir("./usr/man/man3")
ok.mkdir("./usr/man/man4")
ok.mkdir("./usr/man/man5")
ok.mkdir("./usr/man/man6")
ok.mkdir("./usr/man/man7")
ok.mkdir("./usr/man/man8")
ok.mkdir("./usr/share")
ok.mkdir("./usr/share/doc")
ok.mkdir("./usr/share/locale")
ok.mkdir("./usr/share/misc")
ok.mkdir("./usr/share/terminfo")
ok.mkdir("./usr/share/zoneinfo")
ok.mkdir("./usr/src")
ok.mkdir("./var")
ok.mkdir("./var/cache")
ok.mkdir("./var/com")
ok.mkdir("./var/home")
ok.mkdir("./var/log")
ok.mkdir("./var/mail")
ok.mkdir("./var/spool")
ok.mkdir("./proc")
ok.mkdir("./sys")
ok.mkdir("./dev")
ok.mkdir("./run")
ok.mkdir("./run/lock")

--------------
-- Symlinks --
--------------
ok.symlink("bash", "bin/sh")
ok.symlink("pigz", "bin/gzip")
ok.symlink("/proc/self/mounts", "./etc/mtab")
ok.symlink("var/home", "./home")

------------------
-- System Files --
------------------
--------------------------------------------------------------------------------
fp = io.open("./etc/ld.so.conf", "w")
fp:write("/lib64")
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./etc/hostname", "w")
fp:write("myhost")
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./etc/hosts", "w")
fp:write([[
127.0.0.1  localhost myhost
::1        localhost
]])
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./etc/config.site", "w")
fp:write([[
[ "$bindir"         = '${exec_prefix}/bin' ]     && bindir=/bin
[ "$libdir"         = '${exec_prefix}/lib' ]     && libdir=/lib64
[ "$libexecdir"     = '${exec_prefix}/libexec' ] && libexecdir=/usr/libexec
[ "$localstatedir"  = '${prefix}/var' ]          && localstatedir=/var
[ "$mandir"         = '${datarootdir}/man' ]     && mandir=/usr/man
[ "$runstatedir"    = '${localstatedir}/run' ]   && runstatedir=/run
[ "$sbindir"        = '${exec_prefix}/sbin' ]    && sbindir=/bin
[ "$sharedstatedir" = '${prefix}/com' ]          && sharedstatedir=/var/com
[ "$sysconfdir"     = '${prefix}/etc' ]          && sysconfdir=/etc
[ -z ${enable_debug+x} ]                         && enable_debug=no
[ -z ${enable_nls+x} ]                           && enable_nls=no
[ -z ${enable_pic+x} ]                           && enable_pic=yes
[ -z ${enable_rpath+x} ]                         && enable_rpath=no
[ -z ${enable_shared+x} ]                        && enable_shared=yes
[ -z ${enable_static+x} ]                        && enable_static=no
[ -z ${enable_tests+x} ]                         && enable_tests=no
[ -z ${enable_werror+x} ]                        && enable_werror=no
[ -z ${with_pic+x} ]                             && with_pic=yes
:
]])
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./etc/nsswitch.conf", "w")
fp:write([[
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
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./etc/default/useradd", "w")
fp:write([[
GROUP=999
GROUPS=audio,video,input
HOME=/var/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/bash
CREATE_MAIL_SPOOL=yes
LOG_INIT=yes
]])
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./etc/passwd", "w")
fp:write([[
root::0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
atd:x:17:17:atd daemon:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
ntp:x:87:87:Network Time Protocol:/var/empty:/usr/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/usr/bin/false
]])
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./etc/group", "w")
fp:write([[
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
ntp:x:87:
wheel:x:97:
nogroup:x:99:
users:x:999:
]])
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./etc/profile", "w")
fp:write([[
export LANG=en_US
export PATH=/bin
export PS1='\h \W \$ '
]])
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./etc/inputrc", "w")
fp:write([[
set horizontal-scroll-mode Off
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
]])
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./etc/resolv.conf", "w")
fp:write("nameserver 8.8.8.8")
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./etc/shells", "w")
fp:write([[
/bin/sh
/bin/bash
]])
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./etc/syslog.conf", "w")
fp:write([[
auth,authpriv.*                  /var/log/auth.log   ;RFC5424
*.*;auth,authpriv.none          -/var/log/syslog     ;RFC5424
kern.*                          -/var/log/kern.log   ;RFC5424
*.=emerg                         *                   ;RFC5424
*.=info;*.=notice;*.=warn;\
        auth,authpriv.none;\
        cron,daemon.none;\
        mail,news.none          -/var/log/messages   ;RFC5424
]])
fp:close()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
fp = io.open("./bin/c99", "w")
fp:write([[
#!/bin/sh
exec /bin/gcc -std=c99 "$@"
]])
fp:close()
--------------------------------------------------------------------------------

os.execute([[
   chmod 0755 ./bin/c99
   mknod -m 600 ./dev/console c 5 1
   mknod -m 666 ./dev/null c 1 3
   chattr +i ./etc/resolv.conf
   cp -f  /etc/{protocols,services} ./etc
   cp -fp {/,./}etc/ssl/certs/ca-certificates.crt
   cp -fr {/,./}lib64/dinit.d
]])

-----------
-- okpkg --
-----------
ok.mkdir("./usr/okpkg")
ok.mkdir("./var/cache/ok")
ok.mkdir("./var/cache/ok/out")
ok.mkdir("./var/cache/ok/pkg")
os.execute([[
   git clone /usr/okpkg $destdir/usr/okpkg
   git -C $destdir/usr/okpkg repack -adf --depth=1
   tar -C $destdir -xf /var/cache/ok/pkg/linux-lts-*.tar.lz
   cp -fp /var/cache/ok/pkg/linux-lts-*.tar.lz $destdir/var/cache/ok/pkg
   cp -rp /var/cache/ok/dist $destdir/var/cache/ok/dist
]])
