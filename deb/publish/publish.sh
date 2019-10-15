#!/bin/bash -ex

: "${AGENT_WORKDIR:=/tmp}"

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
cp "${GPG_PUBLIC_KEY}" "$D/contents/${ORGANIZATION}.key"

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
  --no-default-keyring \
  --digest-algo=sha256 \
  --keyring "$GPG_KEYRING" \
  --passphrase-file "$GPG_PASSPHRASE_FILE" \
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
