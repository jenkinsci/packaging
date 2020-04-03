#!/bin/bash

set -euxo pipefail

: "${AGENT_WORKDIR:=/tmp}"
: "${GPG_KEYNAME:?Require valid gpg keyname}"
: "${DEB:?Require Debian package}"
: "${DEBDIR:? Require where to put binary files}"
: "${DEB_WEBDIR:? Require where to put repository index and other web contents}"
: "${DEB_URL:? Require Debian repository Url}"

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

# Convert string to array to correctly escape cli parameter
SSH_OPTS=($SSH_OPTS)

bin="$(dirname "$0")"

function clean(){
  rm -rf "$D"
}

# Generate and publish site content
function generateSite(){

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

  # Remote ftparchive-merge
  # https://github.com/kohsuke/apt-ftparchive-merge
  pushd $D/binary
    mvn org.kohsuke:apt-ftparchive-merge:1.6:merge -Durl="$DEB_URL/binary/" -Dout=../merged
  popd

  # Local ftparchive-merge

  cat $D/merged/Packages > $D/binary/Packages
  gzip -9c "$D/merged/Packages" > "$D/binary/Packages.gz"
  bzip2 -c "$D/merged/Packages" > "$D/binary/Packages.bz2"
  lzma -c "$D/merged/Packages" > "$D/binary/Packages.lzma"
  gzip -9c "$D/merged/Contents" > "$D/binary/Contents.gz"

  apt-ftparchive -c "$bin/release.conf" release "$D/binary" > "$D/binary/Release"

}

function init(){

  mkdir -p "$D/binary" "$D/contents"

  # where to put binary files
  mkdir -p "$DEBDIR" # where to put binary files

  # where to put repository index and other web contents
  mkdir -p "$DEB_WEBDIR"
  ## On remote serve
  # shellcheck disable=SC2029
  ssh "$PKGSERVER" "${SSH_OPTS[*]}" mkdir -p "$DEBDIR/"
}

function uploadPackage(){
  # Upload Debian Package
  rsync -avz "$DEB" "$DEBDIR/"
  rsync -avz -e "ssh ${SSH_OPTS[*]}" "${DEB}" "$PKGSERVER:${DEBDIR// /\\ }"
}

function uploadSite(){

  cp \
    "$D"/binary/Packages* \
    "$D"/binary/Release \
    "$D"/binary/Release.gpg \
    "$D"/binary/Contents* \
    "$D"/contents/binary

  rsync -avz "$D/contents/" "$DEB_WEBDIR/"
  rsync -avz -e "ssh ${SSH_OPTS[*]}" "${DEB}" "$PKGSERVER:${DEBDIR// /\\ }"
}

function show(){
  echo "Parameters:"
  echo "DEB: $DEB"
  echo "DEBDIR: $DEBDIR"
  echo "DEB_WEBDIR: $DEB_WEBDIR"
  echo "SSH_OPTS: $SSH_OPTS"
  echo "PKGSERVER: $PKGSERVER"
  echo "GPG_KEYNAME: $GPG_KEYNAME"
  echo "---"
}

function signSite(){
  # sign the release file
  if [ -f "$D/binary/Release.gpg" ]; then
    rm "$D/binary/Release.gpg"
  fi

  gpg \
    --batch \
    --pinentry-mode loopback \
    --digest-algo=sha256 \
    -u "$GPG_KEYNAME" \
    --passphrase-file "$GPG_PASSPHRASE_FILE" \
    -abs \
    -o "$D/binary/Release.gpg" \
    "$D/binary/Release"
}

show
init
generateSite
signSite
uploadPackage
uploadSite
clean
