#!/bin/sh
x(){ [ -x "$1" ] && "$@" ; }
x /bin/update-mime-database /usr/share/mime
x /bin/update-desktop-database /usr/share/applications
x /bin/udevadm hwdb --update
x /bin/pwconv
x /bin/makewhatis /usr/share/man
x /bin/ldconfig
x /bin/grpconv
x /bin/glib-compile-schemas /usr/share/glib-2.0/schemas
x /bin/gdk-pixbuf-query-loaders --update-cache
x /bin/fstrim -a
x /bin/fc-cache -f
x /bin/dbus-uuidgen --ensure=/etc/machine-id
setcap cap_net_raw+p /bin/ping
chown -f 0:18 /usr/libexec/dbus-daemon-launch-helper
chmod -f 4750 /usr/libexec/dbus-daemon-launch-helper
chmod -f 1777 /tmp
chmod -f 0755 /bin/Xorg
