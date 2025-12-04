#!/bin/sh

protocols="https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xml"
services="https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml"

oldpwd=`pwd`
tempdir=`mktemp -d`
curl='/usr/bin/curl --fail --location --remote-name'


cd "$tempdir"

$curl "$protocols"
gawk -F"[<>]" '
(/<record/) { v=n="" }
(/<value/) { v=$3 }
(/<name/ && $3!~/ /) { n=$3 }
(/<\/record/ && n && v!="") { printf "%-12s %3i %s\n", tolower(n),v,n }
' ${protocols##*/} > /etc/protocols

$curl "$services"
gawk -F"[<>]" '
(/<record/) { n=u=p=c="" }
(/<name/ && !/\(/) { n=$3 }
(/<number/) { u=$3 }
(/<protocol/) { p=$3 }
(/Unassigned/ || /Reserved/ || /historic/) { c=1 }
(/<\/record/ && n && u && p && !c) { printf "%-15s %5i/%s\n", n,u,p }
' ${services##*/} > /etc/services

cd "$oldpwd" && rm -fr "$tempdir"
