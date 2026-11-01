#!/bin/sh
for i in /usr/share/icons/*/index.theme; do
  gtk-update-icon-cache -f "${i%/*}"
done
