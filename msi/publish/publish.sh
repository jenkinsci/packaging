#!/bin/bash

set -euxo pipefail

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

  mkdir -p "${MSIDIR}/${VERSION}/"

  ssh "${SSH_OPTS[@]}" "$PKGSERVER" mkdir -p "$MSIDIR/${VERSION}/"

}

function skipIfAlreadyPublished(){

  if ssh "${SSH_OPTS[@]}" "$PKGSERVER" test -e "${MSIDIR}/${VERSION}/$(basename "$MSI")"; then
    echo "File already published, nothing else todo"
    exit 0

  fi
}

function uploadPackage(){

  cp "${ARTIFACTNAME}-${VERSION}.msi" "${MSI}"

  sha256sum "${MSI}" > "${MSI_SHASUM}"

  cat "${MSI_SHASUM}"

  # Local
  rsync \
    -avz \
    --ignore-existing \
    --progress \
    "${MSI}" "${MSIDIR}/${VERSION}/"

  rsync \
    -avz \
    --ignore-existing \
    --progress \
    "${MSI_SHASUM}" "${MSIDIR}/${VERSION}/"

  # Remote
  rsync \
    -avz \
    --ignore-existing \
    --progress \
    -e "ssh ${SSH_OPTS[*]}" \
    "${MSI}" "$PKGSERVER:${MSIDIR}/${VERSION}/"
  rsync \
    -avz \
    --ignore-existing \
    --progress \
    -e "ssh ${SSH_OPTS[*]}" \
    "${MSI_SHASUM}" "$PKGSERVER:${MSIDIR}/${VERSION}/"
}

# The site need to be located in the binary directory
function uploadSite(){
  rsync \
    -avz \
    --progress \
    -e "ssh ${SSH_OPTS[*]}" \
    "${D}/" "$PKGSERVER:${MSIDIR// /\\ }/"

  rsync \
    -avz \
    --progress \
    -e "ssh ${SSH_OPTS[*]}" \
    "${D}/" "${MSIDIR// /\\ }/"
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
