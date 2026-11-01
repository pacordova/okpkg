#!/bin/sh
curl -fso/etc/ssl/cert.pem https://curl.se/ca/cacert.pem
chmod 0644 /etc/ssl/cert.pem
mkdir -p /etc/ssl/certs && ln -sf ../cert.pem /etc/ssl/certs/ca-certificates.crt
