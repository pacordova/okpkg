#!/bin/sh
/bin/curl -fsSL "https://curl.se/ca/cacert.pem" \
  -o "/etc/ssl/certs/ca-certificates.crt"
