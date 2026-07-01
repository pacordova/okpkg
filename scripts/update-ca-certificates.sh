#!/bin/sh
curl='/bin/curl -fsSL'
tmpfile=$(mktemp)
$curl -o $tmpfile https://curl.se/ca/cacert.pem
[ -f $tmpfile ] && mv $tmpfile /etc/ssl/certs/ca-certificates.crt
