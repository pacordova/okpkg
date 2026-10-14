#!/bin/sh
curl -fs https://uefi.org/uefi-pnp-export \
|> /usr/share/hwdata/pnp.ids gawk -k 'NR>1{ print $2 "\t" $1 }'
