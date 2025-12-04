#!/bin/sh
curl -L https://curl.se/ca/cacert.pem > _
mv _ /etc/ssl/certs/ca-certificates.crt
