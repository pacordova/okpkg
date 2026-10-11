#!/bin/sh
mkdir -p /usr/share/hwdata
curl -fsSL https://uefi.org/uefi-pnp-export \
| gawk -k 'NR>1{ print $2 "\t" $1 }' \
| sort -u \
> /usr/share/hwdata/pnp.ids
