#!/bin/lua

ok = require("okutils")

-- Reformat
io.write("Please enter a partition/device to format: ")
local dev = io.read()
if os.execute("umount -R -f -q /mnt || ! mountpoint -q /mnt") and
   os.execute("mkfs.ext4 " .. dev) and
   os.execute("mount " .. dev .. " /mnt")
then
   ok.current_path("/mnt") 
   os.remove("lost+found")
else
   error("error: reformat")
end

-- Skeleton
ok.create_directory("./bin")
ok.create_directory("./boot")
ok.create_directory("./boot/efi")
ok.create_directory("./dev")
ok.create_directory("./etc")
ok.create_directory("./etc/default")
ok.create_directory("./etc/ssl")
ok.create_directory("./etc/ssl/certs")
ok.create_directory("./home")
ok.create_directory("./lib64")
ok.create_directory("./lib64/locale")
ok.create_directory("./lib64/pkgconfig")
ok.create_directory("./mnt")
ok.create_directory("./opt")
ok.create_directory("./proc")
ok.create_directory("./root")
ok.create_directory("./run")
ok.create_directory("./run/lock")
ok.create_directory("./run/shm")
ok.create_directory("./sys")
ok.create_directory("./tmp")
ok.create_directory("./usr")
ok.create_directory("./usr/bin")
ok.create_directory("./usr/include")
ok.create_directory("./usr/libexec")
ok.create_directory("./usr/share")
ok.create_directory("./usr/share/doc")
ok.create_directory("./usr/share/locale")
ok.create_directory("./usr/share/man")
ok.create_directory("./usr/share/man/man1")
ok.create_directory("./usr/share/man/man2")
ok.create_directory("./usr/share/man/man3")
ok.create_directory("./usr/share/man/man4")
ok.create_directory("./usr/share/man/man5")
ok.create_directory("./usr/share/man/man6")
ok.create_directory("./usr/share/man/man7")
ok.create_directory("./usr/share/man/man8")
ok.create_directory("./usr/share/man/man9")
ok.create_directory("./usr/share/misc")
ok.create_directory("./usr/share/terminfo")
ok.create_directory("./usr/share/zoneinfo")
ok.create_directory("./usr/src")
ok.create_directory("./var")
ok.create_directory("./var/cache")
ok.create_directory("./var/cache/packages")
ok.create_directory("./var/db")
ok.create_directory("./var/log")
ok.create_directory("./var/spool")
ok.create_directory("./var/spool/mail")

-- Symlinks
ok.create_symlink("lib64", "./lib")
ok.create_symlink("../../bin/env", "./usr/bin/env")
ok.create_symlink("bash",    "./bin/sh")
ok.create_symlink("flex",    "./bin/lex")
ok.create_symlink("gcc",     "./bin/cc")
ok.create_symlink("lbzip2",  "./bin/bzip2")
--ok.create_symlink("pigz",    "./bin/gzip")
ok.create_symlink("pkgconf", "./bin/pkg-config")
ok.create_symlink("plzip",   "./bin/lzip")
ok.create_symlink("samu",    "./bin/ninja")

--------------------------------------------------------------------------------
fp = io.open("./etc/ld.so.conf", "w")
fp:write("/lib64")
fp:close()
--------------------------------------------------------------------------------
fp = io.open("./etc/hostname", "w")
fp:write("myhost")
fp:close()
--------------------------------------------------------------------------------
fp = io.open("./etc/hosts", "w")
fp:write([[
127.0.0.1  localhost myhost
::1        localhost
]])
fp:close()
--------------------------------------------------------------------------------
fp = io.open("./etc/config.site", "w")
fp:write([[
[ -z ${with_pic+x}                             ] && with_pic=yes
[ -z ${enable_tests+x}                         ] && enable_tests=no
[ -z ${enable_static+x}                        ] && enable_static=no
[ -z ${enable_shared+x}                        ] && enable_shared=yes
[ -z ${enable_rpath+x}                         ] && enable_rpath=no
[ -z ${enable_pic+x}                           ] && enable_pic=yes
[ -z ${enable_nls+x}                           ] && enable_nls=no
[ -z ${enable_debug+x}                         ] && enable_debug=no
[ '${prefix}/var'          = "$localstatedir"  ] && localstatedir=/var
[ '${prefix}/include'      = "$includedir"     ] && includedir=/usr/include
[ '${prefix}/etc'          = "$sysconfdir"     ] && sysconfdir=/etc
[ '${prefix}/com'          = "$sharedstatedir" ] && sharedstatedir=/var
[ '${localstatedir}/run'   = "$runstatedir"    ] && runstatedir=/run
[ '${exec_prefix}/sbin'    = "$sbindir"        ] && sbindir=/bin
[ '${exec_prefix}/libexec' = "$libexecdir"     ] && libexecdir=/usr/libexec
[ '${exec_prefix}/lib'     = "$libdir"         ] && libdir=/lib64
[ '${exec_prefix}/bin'     = "$bindir"         ] && bindir=/bin
:
]])
fp:close()
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
fp = io.open("./etc/default/useradd", "w")
fp:write([[
GROUP=999
GROUPS=audio,video,input
HOME=/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/bash
CREATE_MAIL_SPOOL=yes
LOG_INIT=yes
]])
fp:close()
--------------------------------------------------------------------------------
fp = io.open("./etc/passwd", "w")
fp:write([[
root::0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
atd:x:17:17:atd daemon:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/bin/false
ntp:x:87:87:Network Time Protocol:/var/empty:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
]])
fp:close()
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
fp = io.open("./etc/profile", "w")
fp:write([[
export LANG=en_US
export PATH=/bin
export PS1='\h \W \$ '
]])
fp:close()
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
fp = io.open("./etc/resolv.conf", "w")
fp:write("nameserver 8.8.8.8")
fp:close()
--------------------------------------------------------------------------------
fp = io.open("./etc/shells", "w")
fp:write([[
/bin/sh
/bin/bash
]])
fp:close()
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
fp = io.open("./bin/c99", "w")
fp:write([[
#!/bin/sh
exec /bin/gcc -std=c99 "$@"
]])
fp:close()
--------------------------------------------------------------------------------
fp = io.open("./lib64/pkgconfig/lua.pc", "w")
fp:write([[
Name: Lua
Description: An Extensible Extension Language
Version: 5.5.0
Requires:
Libs: -L/lib64 -llua -lm
Cflags: -I/usr/include
]])
fp:close()
--------------------------------------------------------------------------------

-- Misc
os.execute([[
   mknod -m 600 ./dev/console c 5 1
   mknod -m 666 ./dev/null c 1 3
   chattr +i ./etc/resolv.conf
   chmod 0755 ./bin/c99
   chmod 1777 ./tmp
   #git clone --depth=1 {file:///,./}usr/okpkg
   tar -xf /var/cache/sys/cmake-bin-*.tar.lz
   tar -xf /var/cache/sys/linux-lts-*.tar.lz
   cp -a /var/cache/sys/linux-lts-*.tar.lz ./var/cache/packages
   cp -a {/,./}etc/dinit.d
   cp -a {/,./}var/cache/distfiles
   cp -f  /etc/{protocols,services} ./etc
   cp -f /etc/rc.local /etc/syslog.conf /etc/fstab ./etc
   cp -f {/,./}etc/ssl/certs/ca-certificates.crt
]])
