#!/bin/sh
curl="/bin/curl -fsSL"
capath="/etc/ssl/certs"
mkdir -p `dirname "$capath"` && cd "$capath"
$curl "https://curl.se/ca/cacert.pem" > _
mv _ ca-certificates.crt
