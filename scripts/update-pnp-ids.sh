#!/bin/sh
curl -fs https://uefi.org/uefi-pnp-export \
| gawk > /usr/share/hwdata/pnp.ids -k 'NR>1{ print $2 "\t" $1 }'
