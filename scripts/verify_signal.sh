#!/bin/bash

VERSION=7.71.0

tempdir=$(mktemp -d) && pushd $tempdir >/dev/null

keys=('DBA36B5181D0C816F630E889D980A17457F6FB06')
for k in ${keys[@]}; do gpg --recv-keys $k; done

curl -LRO "https://updates.signal.org/desktop/apt/pool/s/signal-desktop/signal-desktop_$VERSION_amd64.deb"
curl -LRO "https://updates.signal.org/desktop/apt/dists/xenial/InRelease"
curl -LRO "https://updates.signal.org/desktop/apt/dists/xenial/main/binary-amd64/Packages.gz"

gpg2 --verify InRelease || exit 1

grep Packages.gz InRelease \
| tail -1 \
| awk '{print $1 " Packages.gz"}' \
| sha512sum -c || exit 1

sha512=`pigz -cd Packages.gz | awk 'NR==36 {print $2}'`
printf "%s %s" "$sha512" "signal-desktop_${VERSION}_amd64.deb" \
| sha512sum -c || exit 1

okpkg sha3sum "signal-desktop_${VERSION}_amd64.deb"

# Cleanup
popd >/dev/null && rm -fr $tempdir
