#!/bin/sh

libexecdir=/usr/libexec
mandir=/usr/share/man

# sys
[ -x /bin/fstrim     ] && /bin/fstrim -a
[ -x /bin/udevadm    ] && /bin/udevadm hwdb --update
[ -x /bin/makewhatis ] && /bin/makewhatis "$mandir"
[ -x /bin/pwconv     ] && /bin/pwconv
[ -x /bin/grpconv    ] && /bin/grpconv

# xorg
[ -x /bin/fc-cache                 ] && /bin/fc-cache
[ -x /bin/update-desktop-database  ] && /bin/update-desktop-database
[ -x /bin/update-mime-database     ] && /bin/update-mime-database /usr/share/mime
[ -x /bin/glib-compile-schemas     ] && /bin/glib-compile-schemas /usr/share/glib-2.0/schemas
[ -x /bin/gdk-pixbuf-query-loaders ] && /bin/gdk-pixbuf-query-loaders --update-cache

# cap
setcap cap_net_raw+p /bin/ping
chown root:messagebus $libexecdir/dbus-daemon-launch-helper
chmod 4750 $libexecdir/dbus-daemon-launch-helper

# clock
ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
TZ=UTC0 date $(nc time.nist.gov 13 | awk -F'[-: ]' 'NR>1{print $3$4$5$6$2"."$7}')
hwclock --systohc && hwclock --hctosys
