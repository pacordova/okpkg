#!/bin/sh
curl="/usr/bin/curl --fail --location"
capath="/etc/ssl/certs"
mkdir -p `dirname "$capath"` && cd "$capath"
$curl "https://curl.se/ca/cacert.pem" > _
mv _ ca-certificates.crt
