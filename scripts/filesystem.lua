#!/usr/bin/env lua

if #arg ~= 1 then
    error("usage: lua filesystem.lua [DIRECTORY]")
end

package.cpath = package.cpath .. ";/usr/okpkg/?.so"

require "okutils"


if chdir(arg[1]) ~= 0 then
    error(string.format("error: directory does not exist: %s", arg[1]))
end

-- mkdirs
mkdir("boot")
mkdir("dev")
mkdir("etc")
mkdir("etc/default")
mkdir("etc/ssl")
mkdir("etc/ssl/certs")
mkdir("home")
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
mkdir("usr/sbin")
mkdir("usr/include")
mkdir("usr/lib")
mkdir("usr/lib64")
mkdir("usr/lib64/locale")
mkdir("usr/lib64/pkgconfig")
mkdir("var")
mkdir("var/db")
mkdir("var/lib")
mkdir("var/lib/dbus")
mkdir("var/log")
mkdir("var/tmp")

-- symlinks
symlink("usr/bin", "bin")
symlink("usr/sbin", "sbin")
symlink("usr/lib", "lib")
symlink("usr/lib64", "lib64")
symlink("/proc/self/mounts", "etc/mtab")
symlink("../run", "var/run")
symlink("../run/lock", "var/lock")

-- mknod files
os.execute [[
    mknod -m 600 dev/console c 5 1
    mknod -m 666 dev/null c 1 3
]]

-- passwd
fp = io.open("etc/passwd", 'w')
fp:write [[
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/usr/bin/false
]]
fp:close()

-- group
fp = io.open("etc/group", 'w')
fp:write [[
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
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
nogroup:x:99:
users:x:999:
]]
fp:close()

-- ld.so.conf
fp = io.open("etc/ld.so.conf", 'w')
fp:write("/usr/lib64")
fp:close()

-- inputrc
fp = io.open("etc/inputrc", 'w')
fp:write [[
set meta-flag On
set input-meta On
set convert-meta Off
set output-meta On
set bell-style none
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
]]
fp:close()

-- shells
fp = io.open("etc/shells", 'w')
fp:write [[
/bin/bash
/bin/sh
]]
fp:close()

-- profile
fp = io.open("etc/profile", 'w')
fp:write [[
export LANG=en_US.utf8
export PS1='# '
]]
fp:close()

-- hosts
fp = io.open("etc/hosts", 'w')
fp:write [[
127.0.0.1  localhost hostname
::1        localhost
]]
fp:close()

-- resolv.conf
fp = io.open("etc/resolv.conf", 'w')
fp:write("nameserver 8.8.8.8")
fp:close()

-- nsswitch
fp = io.open("etc/nsswitch.conf", 'w')
fp:write [[
passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files
]]
fp:close()

-- syslog
fp = io.open("etc/syslog.conf", 'w')
fp:write [[
auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *
]]
fp:close()

-- update-ca-certificates
fp = io.open("usr/bin/update-ca-certificates", 'w')
fp:write [[
#!/bin/bash
cd /etc/ssl/certs
curl -LO https://curl.se/ca/cacert.pem
mv cacert.pem ca-certificates.crt
]]
fp:close()
os.execute("chmod +x usr/bin/update-ca-certificates")

-- update-grub
fp = io.open("usr/bin/update-grub", 'w')
fp:write [[
#!/bin/bash
grub-mkconfig -o /boot/grub/grub.cfg
]]
fp:close()
os.execute("chmod +x usr/bin/update-grub")
