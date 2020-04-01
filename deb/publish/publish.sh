#!/bin/bash -ex

: "${AGENT_WORKDIR:=/tmp}"
: "${GPG_KEYNAME:?Required valid gpg keyname}"

bin="$(dirname "$0")"

## Publish Binary
#
mkdir -p "$DEBDIR"
mkdir -p "$DEB_WEBDIR"

rsync -avz "$DEB" "$DEBDIR/"

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

# Generate and publish site content
##
mkdir -p "$D/binary" "$D/contents"
cp -R "$bin/contents/." "$D/contents"

gpg --export -a --output "$D/contents/${ORGANIZATION}.key" "${GPG_KEYNAME}"

"$BASE/bin/indexGenerator.py" \
  --distribution debian \
  --binaryDir "$DEBDIR" \
  --targetDir "$DEB_WEBDIR"

"$BASE/bin/branding.py" "$D"

# build package index
# see http://wiki.debian.org/SecureApt for more details
cp "${DEB}" "$D/binary/"
pushd "$D"
  apt-ftparchive packages binary > binary/Packages
  apt-ftparchive contents binary > binary/Contents
popd

apt-ftparchive -c "$bin/release.conf" release "$D/binary" > "$D/binary/Release"

# sign the release file
rm "$D/binary/Release.gpg" || true

gpg \
  --batch \
  --pinentry-mode loopback \
  --digest-algo=sha256 \
  -u "$GPG_KEYNAME" \
  -abs \
  -o "$D/binary/Release.gpg" \
  "$D/binary/Release"

cp \
  "$D"/binary/Packages* \
  "$D"/binary/Release \
  "$D"/binary/Release.gpg \
  "$D"/binary/Contents* \
  "$D"/contents/binary

rsync -avz "$D/contents/" "$DEB_WEBDIR/"

rm -rf "$D"
