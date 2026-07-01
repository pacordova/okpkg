#!/bin/sh
curl='/bin/curl -fsSL'
out=/etc/ssl/certs/ca-certificates.crt
$curl -o $out https://curl.se/ca/cacert.pem
chmod 644 $out
