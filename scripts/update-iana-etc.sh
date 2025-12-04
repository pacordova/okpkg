#!/bin/sh

curl='/usr/bin/curl --fail --location'

_get_url(){
  printf "https://www.iana.org/assignments/%s/%s.xml" "$1" "$1"
}

$curl `_get_url protocol-numbers` > _
gawk -F"[<>]" '
(/<record/) { v=n="" }
(/<value/) { v=$3 }
(/<name/ && $3!~/ /) { n=$3 }
(/<\/record/ && n && v!="") { printf "%-12s %3i %s\n", tolower(n),v,n }
' _ > /etc/protocols
chmod 644 /etc/protocols
rm -f _ 

$curl `_get_url service-names-port-numbers` > _
gawk -F"[<>]" '
(/<record/) { n=u=p=c="" }
(/<name/ && !/\(/) { n=$3 }
(/<number/) { u=$3 }
(/<protocol/) { p=$3 }
(/Unassigned/ || /Reserved/ || /historic/) { c=1 }
(/<\/record/ && n && u && p && !c) { printf "%-15s %5i/%s\n", n,u,p }
' _ > /etc/services
chmod 644 /etc/services
rm -f _
