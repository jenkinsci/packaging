#!/bin/bash

set -euxo pipefail

: "${WAR:?Require Jenkins War file}"
: "${WARDIR:? Require where to put binary files}"
: "${WAR_WEBDIR:? Require where to put repository index and other web contents}"

# Convert string to array to correctly escape cli parameter
SSH_OPTS=($SSH_OPTS)

# Generate and publish site content
function generateSite(){

  "$BASE/bin/indexGenerator.py" \
    --distribution war \
    --targetDir "$WAR_WEBDIR"

}

function init(){

  mkdir -p "${WARDIR}/${VERSION}/"
  mkdir -p "${WAR_WEBDIR}"

  ssh "${SSH_OPTS[@]}" "$PKGSERVER" mkdir -p "$WARDIR/${VERSION}/"
  ssh "${SSH_OPTS[@]}" "$PKGSERVER" mkdir -p "${WAR_WEBDIR}"

}

function skipIfAlreadyPublished(){

  if ssh "${SSH_OPTS[@]}" "$PKGSERVER" test -e "${WARDIR}/${VERSION}/${ARTIFACTNAME}.war"; then
    echo "File already published, nothing else todo"
    exit 0

  fi
}

function uploadPackage(){

  sha256sum "${WAR}" | sed "s, .*, ${ARTIFACTNAME}.war," > "${WAR_SHASUM}"
  cat "${WAR_SHASUM}"

  # Local
  rsync \
    -avz \
    --ignore-existing \
    --progress \
    "${WAR}" "${WARDIR}/${VERSION}/${ARTIFACTNAME}.war"

  rsync \
    -avz \
    --ignore-existing \
    --progress \
    "${WAR_SHASUM}" "${WARDIR}/${VERSION}/"

  # Remote
  rsync \
    -avz \
    -e "ssh ${SSH_OPTS[*]}" \
    --ignore-existing \
    --progress \
    "${WAR}" "$PKGSERVER:${WARDIR}/${VERSION}/${ARTIFACTNAME}.war"

  rsync \
    -avz \
    -e "ssh ${SSH_OPTS[*]}" \
    --ignore-existing \
    --progress \
    "${WAR_SHASUM}" "$PKGSERVER:${WARDIR}/${VERSION}/"
}

function uploadSite(){
  rsync \
    -avz \
    --ignore-existing \
    --progress \
    -e "ssh ${SSH_OPTS[*]}" \
    "${WAR_WEBDIR}/" "$PKGSERVER:${WAR_WEBDIR// /\\ }/"

}

function show(){
  echo "Parameters:"
  echo "WAR: $WAR"
  echo "WARDIR: $WARDIR"
  echo "WAR_WEBDIR: $WAR_WEBDIR"
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
