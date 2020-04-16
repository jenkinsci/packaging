#!/bin/bash

set -euxo pipefail

: "${MSI:?Require Jenkins War file}"
: "${MSIDIR:? Require where to put binary files}"
: "${MSI_WEBDIR:? Require where to put repository index and other web contents}"

# Convert string to array to correctly escape cli parameter
SSH_OPTS=($SSH_OPTS)

# Generate and publish site content
function generateSite(){

  "$BASE/bin/indexGenerator.py" \
    --distribution windows \
    --targetDir "$MSI_WEBDIR"

}

function init(){

  mkdir -p "${MSIDIR}/${VERSION}/"
  mkdir -p "${MSI_WEBDIR}"

  ssh "${SSH_OPTS[@]}" "$PKGSERVER" mkdir -p "$MSIDIR/${VERSION}/"
  ssh "${SSH_OPTS[@]}" "$PKGSERVER" mkdir -p "${MSI_WEBDIR}"

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

function uploadSite(){
  rsync \
    -avz \
    --ignore-existing \
    --progress \
    -e "ssh ${SSH_OPTS[*]}" \
    "${MSI_WEBDIR}/" "$PKGSERVER:${MSI_WEBDIR// /\\ }/"

}

function show(){
  echo "Parameters:"
  echo "MSI: $MSI"
  echo "MSIDIR: $MSIDIR"
  echo "MSI_WEBDIR: $MSI_WEBDIR"
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
