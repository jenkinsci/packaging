#!/bin/bash

set -euxo pipefail

: "${AGENT_WORKDIR:=/tmp}"
: "${GPG_KEYNAME:?Required valid gpg keyname}"
: "${BASE:?Require base directory}"
: "${SUSEDIR:? Require where to put binary files}"
: "${SUSE_WEBDIR:? Require where to put repository index and other web contents}"

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

# Convert string to array to correctly escape cli parameter
SSH_OPTS=($SSH_OPTS)
SCP_OPTS=($SCP_OPTS)

function clean(){
  rm -rf $D
}

function generateSite(){

  "$BASE/bin/indexGenerator.py" \
    --distribution opensuse \
    --targetDir "${D}"
  
  gpg --export -a --output "$D/repodata/repomd.xml.key" "${GPG_KEYNAME}"
  
  "$BASE/bin/branding.py" $D
  
  cp "$SUSE" $D/RPMS/noarch
}

function init(){
  # where to put binary files
  mkdir -p "$SUSEDIR/" # Local

  # shellcheck disable=SC2029
  ssh "${SSH_OPTS[@]}" "$PKGSERVER"  mkdir -p "'$SUSEDIR/'" # Remote

  # where to put repository index and other web contents
  mkdir -p "$SUSE_WEBDIR"

  mkdir -p $D/RPMS/noarch $D/repodata
}

function skipIfAlreadyPublished(){

  if ssh "${SSH_OPTS[@]}" "$PKGSERVER" "test -e ${SUSEDIR}/$(basename $SUSE)"; then
    echo "File already published, nothing else todo"
    exit 0

  fi

}

function show(){
  echo "Parameters:"
  echo "SUSE: $SUSE"
  echo "SUSEDIR: $SUSEDIR"
  echo "SUSE_WEBDIR: $SUSE_WEBDIR"
  echo "SSH_OPTS: ${SSH_OPTS[*]}"
  echo "PKGSERVER: $PKGSERVER"
  echo "GPG_KEYNAME: $GPG_KEYNAME"
  echo "---"
}

function uploadPackage(){
  rsync \
    --recursive \
    --verbose \
    --compress \
    --ignore-existing \
    --progress \
    "$SUSE" "$SUSEDIR/" # Local

  rsync \
    --archive \
    --verbose \
    --compress \
    --ignore-existing \
    --progress \
    -e "ssh ${SSH_OPTS[*]}" \
    "${SUSE}" "$PKGSERVER:${SUSEDIR// /\\ }" # Remote
}

function uploadSite(){

  pushd $D
    rsync \
      --recursive \
      --verbose \
      --compress \
      --progress \
      --exclude RPMS \
      --exclude "HEADER.html" \
      --exclude "FOOTER.html" \
      . "$SUSE_WEBDIR/" #Local

    # shellcheck disable=SC2029
    rsync \
      --archive \
      --verbose \
      --compress \
      --progress \
      -e "ssh ${SSH_OPTS[*]}" \
      --exclude RPMS \
      --exclude "HEADER.html" \
      --exclude "FOOTER.html" \
      . "$PKGSERVER:${SUSE_WEBDIR// /\\ }/" # Remote
  
    # generate index on the server
    # server needs 'createrepo' pacakge
    createrepo --update -o "$SUSE_WEBDIR" "$SUSEDIR/" #Local
    # shellcheck disable=SC2029
    ssh "${SSH_OPTS[@]}" "$PKGSERVER"   createrepo --update -o "'$SUSE_WEBDIR'" "'$SUSEDIR/'" # Remote

    scp \
      "${SCP_OPTS[@]}" \
      "$PKGSERVER:${SUSE_WEBDIR// /\\ }/repodata/repomd.xml" \
      repodata/ # Remote

    cp "${SUSE_WEBDIR// /\\ }/repodata/repomd.xml" repodata/ # Local

    gpg \
      --batch \
      --pinentry-mode loopback \
      -u "$GPG_KEYNAME" \
      -a \
      --detach-sign \
      --passphrase-file "$GPG_PASSPHRASE_FILE" \
      --yes \
      repodata/repomd.xml

     scp \
      "${SCP_OPTS[@]}" \
      repodata/repomd.xml.asc \
      "$PKGSERVER:${SUSE_WEBDIR// /\\ }/repodata/"

     cp repodata/repomd.xml.asc "${SUSE_WEBDIR// /\\ }/repodata/"

    # Following html need to be located inside the binary directory
    rsync \
      --compress \
      --verbose \
      --recursive \
      --include "HEADER.html" \
      --include "FOOTER.html" \
      --exclude "*" \
      --progress \
      . "$SUSEDIR/"

    rsync \
      --archive \
      --compress \
      --verbose \
      -e "ssh ${SSH_OPTS[*]}" \
      --include "HEADER.html" \
      --include "FOOTER.html" \
      --exclude "*" \
      --progress \
      . "$PKGSERVER:${SUSEDIR// /\\ }/"
    
  popd
}

show
## Disabling this function allow us to recreate and sign the Suse repository.
# the rpm package won't be overrided as we use the parameter '--ignore-existing' when we upload it
#skipIfAlreadyPublished
init
generateSite
uploadPackage
uploadSite
clean
