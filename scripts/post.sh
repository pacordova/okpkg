#!/bin/sh

cd $(dirname $0)

# Misc
[ -x /bin/fstrim     ] && /bin/fstrim -a
[ -x /bin/udevadm    ] && /bin/udevadm hwdb --update
[ -x /bin/makewhatis ] && /bin/makewhatis /usr/share/man
[ -x /bin/pwconv     ] && /bin/pwconv
[ -x /bin/grpconv    ] && /bin/grpconv
[ -x /bin/ldconfig   ] && /bin/ldconfig
[ -f /etc/machine-id ] || /bin/dbus-uuidgen --ensure=/etc/machine-id

# Xorg
[ -x /bin/fc-cache                 ] && /bin/fc-cache -f -v
[ -x /bin/update-desktop-database  ] && /bin/update-desktop-database  /usr/share/applications
[ -x /bin/update-mime-database     ] && /bin/update-mime-database     /usr/share/mime
[ -x /bin/glib-compile-schemas     ] && /bin/glib-compile-schemas     /usr/share/glib-2.0/schemas
[ -x /bin/gdk-pixbuf-query-loaders ] && /bin/gdk-pixbuf-query-loaders --update-cache
[ -x /bin/Xorg                     ] && chmod u-s /bin/Xorg

# Cache
if [ -x /bin/gtk-update-icon-cache ]; then
  for x in /usr/share/icons/*/; do 
    /bin/gtk-update-icon-cache -f -t "$x" 
  done
fi

# Certificates
[ -x /bin/curl ] && 
/bin/curl -fsSL https://curl.se/ca/cacert.pem > _ &&
mv _ /etc/ssl/certs/ca-certificates.crt

# Permissions
setcap cap_net_raw+p /bin/ping
chown root:messagebus /usr/libexec/dbus-daemon-launch-helper
chmod 4750 /usr/libexec/dbus-daemon-launch-helper
chmod 0644 /etc/ssl/certs/ca-certificates.crt
chmod 1777 /tmp

# Clock
ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
TZ=UTC0 date $(nc time.nist.gov 13 | awk -F'[-: ]' 'NR>1{print $3$4$5$6$2"."$7}')
hwclock --systohc && hwclock --hctosys
