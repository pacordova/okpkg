#!/bin/sh

libexecdir=/usr/libexec
mandir=/usr/share/man

# sys
[ -x /bin/fstrim     ] && /bin/fstrim -a
[ -x /bin/udevadm    ] && /bin/udevadm hwdb --update
[ -x /bin/makewhatis ] && /bin/makewhatis "$mandir"
[ -x /bin/pwconv     ] && /bin/pwconv
[ -x /bin/grpconv    ] && /bin/grpconv
[ -f /etc/machine-id ] || /bin/dbus-uuidgen --ensure=/etc/machine-id

# xorg
[ -x /bin/fc-cache                 ] && /bin/fc-cache
[ -x /bin/update-desktop-database  ] && /bin/update-desktop-database  /usr/share/applications
[ -x /bin/update-mime-database     ] && /bin/update-mime-database     /usr/share/mime
[ -x /bin/glib-compile-schemas     ] && /bin/glib-compile-schemas     /usr/share/glib-2.0/schemas
[ -x /bin/gdk-pixbuf-query-loaders ] && /bin/gdk-pixbuf-query-loaders --update-cache

# gtk-update-icon-cache
if [ -x /bin/gtk-update-icon-cache ]; then
  for dir in /usr/share/icons/*/; do 
    /bin/gtk-update-icon-cache -f -t "$dir" 
  done
fi

# cap
setcap cap_net_raw+p /bin/ping
chown root:messagebus $libexecdir/dbus-daemon-launch-helper
chmod 4750 $libexecdir/dbus-daemon-launch-helper
chmod 1777 /tmp

# clock
ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
TZ=UTC0 date $(nc time.nist.gov 13 | awk -F'[-: ]' 'NR>1{print $3$4$5$6$2"."$7}')
hwclock --systohc && hwclock --hctosys
