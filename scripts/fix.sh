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

# fix /run/user
#mkdir -m 1777 /run/user
chmod 1777 /run/user
chmod 0700 /run/user/*

# fix /tmp
#rm -rf /tmp/* /tmp/.[!.]* /tmp/..?*
#mkdir -p -m 1777 /tmp/.ICE-unix /tmp/.X11-unix
chmod 1777 /tmp /tmp/.ICE-unix /tmp/.X11-unix


