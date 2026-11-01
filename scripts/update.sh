#!/bin/sh

x(){
    [ -x "$1" ] && "$@"
}

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

[ -f /bin/Xorg ] && chmod u-s /bin/Xorg
[ -f /bin/ping ] && setcap cap_net_raw+p /bin/ping
[ -f /etc/machine-id ] || /bin/dbus-uuidgen --ensure=/etc/machine-id
[ -f /usr/libexec/dbus-daemon-launch-helper ] && 
chmod 4750 /usr/libexec/dbus-daemon-launch-helper &&
chown root:messagebus /usr/libexec/dbus-daemon-launch-helper
chmod 1777 /tmp
