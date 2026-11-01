#!/bin/sh

x(){
    [ -x "$1" ] && "$@"
}

x /bin/dbus-uuidgen --ensure=/etc/machine-id
x /bin/fc-cache -f
x /bin/fstrim -a
x /bin/gdk-pixbuf-query-loaders --update-cache
x /bin/glib-compile-schemas /usr/share/glib-2.0/schemas
x /bin/grpconv
x /bin/ldconfig
x /bin/makewhatis /usr/share/man
x /bin/pwconv
x /bin/udevadm hwdb --update
x /bin/update-desktop-database /usr/share/applications
x /bin/update-mime-database /usr/share/mime

chmod -f 0755 /bin/Xorg
chmod -f 1777 /tmp
chmod -f 4750 /usr/libexec/dbus-daemon-launch-helper
chown -f 0:18 /usr/libexec/dbus-daemon-launch-helper
setcap cap_net_raw+p /bin/ping
