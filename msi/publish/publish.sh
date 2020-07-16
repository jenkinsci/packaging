#!/bin/bash

set -euxo pipefail

: "${AGENT_WORKDIR:=/tmp}"
: "${MSI:?Require Jenkins War file}"
: "${MSIDIR:? Require where to put binary files}"

# Convert string to array to correctly escape cli parameter
SSH_OPTS=($SSH_OPTS)

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

function clean(){
  rm -rf "$D"
}

# Generate and publish site content
function generateSite(){

  "$BASE/bin/indexGenerator.py" \
    --distribution windows \
    --targetDir "$MSIDIR"

}

function init(){

  mkdir -p $D

  mkdir -p "${MSIDIR}/${VERSION}/"

  ssh "${SSH_OPTS[@]}" "$PKGSERVER" mkdir -p "$MSIDIR/${VERSION}/"

}

function skipIfAlreadyPublished(){

  if ssh "${SSH_OPTS[@]}" "$PKGSERVER" test -e "${MSIDIR}/${VERSION}/$(basename "$MSI")"; then
    echo "File already published $PKGSERVER:${MSIDIR}/${VERSION}/$(basename "$MSI"), nothing else todo"
    exit 0
  fi

  if ssh "${SSH_OPTS[@]}" "$PKGSERVER" test -e "${PROD_MSIDIR}/${VERSION}/$(basename "$MSI")"; then
    echo "File already published on $PKGSERVER:${PROD_MSIDIR}/${VERSION}/$(basename "$MSI"), nothing else todo"
    exit 0
  fi
}

function uploadPackage(){

  cp "${ARTIFACTNAME}-${VERSION}.msi" "${MSI}"

  sha256sum "${MSI}" > "${MSI_SHASUM}"

  cat "${MSI_SHASUM}"

  # Local
  rsync \
    --compress \
    --verbose \
    --recursive \
    --ignore-existing \
    --progress \
    "${MSI}" "${MSIDIR}/${VERSION}/"

  rsync \
    --compress \
    --ignore-existing \
    --recursive \
    --progress \
    --verbose \
    "${MSI_SHASUM}" "${MSIDIR}/${VERSION}/"

  # Remote
  rsync \
    --archive \
    --compress \
    --verbose \
    --ignore-existing \
    --progress \
    -e "ssh ${SSH_OPTS[*]}" \
    "${MSI}" "$PKGSERVER:${MSIDIR}/${VERSION}/"

  rsync \
    --archive \
    --compress \
    --verbose \
    --ignore-existing \
    --progress \
    -e "ssh ${SSH_OPTS[*]}" \
    "${MSI_SHASUM}" "$PKGSERVER:${MSIDIR}/${VERSION}/"

  # Update the symlink to point to most recent Windows build
  #
  # Remove anything in current directory named 'latest'
  # This is a safety measure just in case something was left there previously
  rm -rf latest

  # Create a local symlink pointing to the MSI file in the VERSION directory.
  # Don't need VERSION directory or MSI locally, just the unresolved symlink.
  # The jenkins.io page downloads http://mirrors.jenkins-ci.org/windows/latest
  # and assumes it points to the most recent MSI file.
  ln -s ${VERSION}/"$(basename "$MSI")" latest

  # Copy the symlink to PKGSERVER in the root of MSIDIR
  # Overwrites the existing symlink on the destination
  rsync \
    --archive \
    --links \
    --verbose \
    -e "ssh ${SSH_OPTS[*]}" \
    latest "$PKGSERVER:${MSIDIR}/"

  # Remove the local symlink
  rm latest
}

# The site need to be located in the binary directory
function uploadSite(){
  rsync \
    --compress \
    --verbose \
    --recursive \
    --progress \
    -e "ssh ${SSH_OPTS[*]}" \
    "${D}/" "${MSIDIR// /\\ }/"

  rsync \
    --archive \
    --compress \
    --verbose \
    --progress \
    -e "ssh ${SSH_OPTS[*]}" \
    "${D}/" "$PKGSERVER:${MSIDIR// /\\ }/"
}

function show(){
  echo "Parameters:"
  echo "MSI: $MSI"
  echo "MSIDIR: $MSIDIR"
  echo "SSH_OPTS: ${SSH_OPTS[*]}"
  echo "PKGSERVER: $PKGSERVER"
  echo "---"
}

show
skipIfAlreadyPublished
init
generateSite
uploadPackage
uploadSite
