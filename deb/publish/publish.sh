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
    --targetDir "$D/html"
  
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

  mkdir -p "$D/binary" "$D/contents" "$D/html"

  # where to put binary files
  mkdir -p "$DEBDIR" # where to put binary files

  # where to put repository index and other web contents
  mkdir -p "$DEB_WEBDIR"
  ## On remote serve
  # shellcheck disable=SC2029
  ssh "${SSH_OPTS[@]}" "$PKGSERVER" mkdir -p "$DEBDIR/"
}

function skipIfAlreadyPublished(){

  if ssh "${SSH_OPTS[@]}" "$PKGSERVER" test -e "${DEBDIR}/$(basename "$DEB")"; then
    echo "File already published $PKGSERVER:$PROD_DEBDIR, nothing else todo"
    return 0
  fi

  if ssh "${SSH_OPTS[@]}" "$PKGSERVER" test -e "${PROD_DEBDIR}/$(basename "$DEB")"; then
    echo "File already published on $PKGSERVER:$PROD_DEBDIR, nothing else todo"
    exit 0
  fi
  return 1

}

# Upload Debian Package
function uploadPackage(){
  rsync \
    --verbose \
    --recursive \
    --compress \
    --ignore-existing \
    --progress \
    "$DEB" "$DEBDIR/"

  rsync \
    --archive \
    --verbose \
    --compress \
    --ignore-existing \
    --progress \
    -e "ssh ${SSH_OPTS[*]}" \
    "${DEB}" "$PKGSERVER:${DEBDIR// /\\ }"
}

function uploadPackageSite(){

  cp \
    "$D"/binary/Packages* \
    "$D"/binary/Release \
    "$D"/binary/Release.gpg \
    "$D"/binary/Contents* \
    "$D"/contents/binary

  rsync \
    --verbose \
    --recursive \
    --compress \
    --progress \
    "$D/contents/" "$DEB_WEBDIR/"

  rsync \
    --archive \
    --compress \
    --progress \
    --verbose \
    -e "ssh ${SSH_OPTS[*]}" \
    "$D/contents/" "$PKGSERVER:${DEB_WEBDIR// /\\ }/"
}

function uploadHtmlSite(){

  # Html file need to be located in the binary directory
  rsync \
    --include "HEADER.html" \
    --include "FOOTER.html" \
    --exclude "*" \
    --compress \
    --recursive \
    --progress \
    --verbose \
    "$D/html/" "$DEBDIR/"

  rsync \
    --archive \
    --compress \
    --include "index.html" \
    --exclude "*" \
    --progress \
    --verbose \
    -e "ssh ${SSH_OPTS[*]}" \
    "$D/html/" "$PKGSERVER:${DEB_WEBDIR// /\\ }/"

  rsync \
    --archive \
    --compress \
    --include "HEADER.html" \
    --include "FOOTER.html" \
    --exclude "*" \
    --progress \
    --verbose \
    -e "ssh ${SSH_OPTS[*]}" \
    "$D/html/" "$PKGSERVER:${DEBDIR// /\\ }/"
}

function show(){
  echo "Parameters:"
  echo "DEB: $DEB"
  echo "DEBDIR: $DEBDIR"
  echo "DEB_WEBDIR: $DEB_WEBDIR"
  echo "SSH_OPTS: ${SSH_OPTS[*]}"
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
## Disabling this function allow us to recreate and sign the repository.
# the debian package won't be overrided as we use the parameter '--ignore-existing'
#skipIfAlreadyPublished
init
generateSite
signSite

if ! skipIfAlreadyPublished; then
  uploadPackage
  uploadPackageSite
fi

uploadHtmlSite
clean
