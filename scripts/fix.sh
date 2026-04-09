#!/bin/bash

# update manpages
makewhatis /usr/share/man

# update font cache
fc-cache

# desktop and mime databases
update-desktop-database
update-mime-database /usr/share/mime

# glib schemas
glib-compile-schemas /usr/share/glib-2.0/schemas

# pixbuf loaders
gdk-pixbuf-query-loaders --update-cache

# commit any user changes
pwconv && grpconv

# ping capabilities
setcap cap_net_raw+p /usr/bin/ping

# dbus permissions
chown root:messagebus /usr/lib64/dbus-daemon-launch-helper
chmod 4750 /usr/lib64/dbus-daemon-launch-helper

# clock
date -u $(nc time.nist.gov 13 | awk -F'[-: ]' 'NR>1{print $3$4$5$6$2"."$7}')
hwclock --systohc && hwclock --hctosys
