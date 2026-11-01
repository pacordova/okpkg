#!/bin/sh
ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
TZ=UTC0 date $(nc time.nist.gov 13 | awk -F'[-: ]' 'NR>1{print $3$4$5$6$2"."$7}')
hwclock --systohc && hwclock --hctosys
