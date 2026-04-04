#!/bin/bash

# Various fixes
makewhatis /usr/share/man;
pwconv && grpconv;
glib-compile-schemas /usr/share/glib-2.0/schemas;
fc-cache;
update-desktop-database;
update-mime-database /usr/share/mime;
gdk-pixbuf-query-loaders --update-cache;
setcap cap_net_raw+p /usr/bin/ping;
chown root:messagebus /usr/lib64/dbus-daemon-launch-helper;
chmod 4750 /usr/lib64/dbus-daemon-launch-helper;

# fix date
date +'%y-%m-%d %H:%M:%S' -us"$(nc time.nist.gov 13|awk 'NR>1{print$2" "$3}')"
hwclock --systohc && hwclock --hctosys
