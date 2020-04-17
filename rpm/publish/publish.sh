#!/bin/bash
set -euxo pipefail

: "${AGENT_WORKDIR:=/tmp}"
: "${GPG_KEYNAME:?Require valid gpg keyname}"
: "${RPMDIR:?Require where to put binary files}"
: "${RPM_WEBDIR:?Require where to put index and other web contents}"
: "${RPM_URL:?Require rpm repository url}"
: "${RELEASELINE?Require rpm release line}"
: "${BASE:? Required base directory}"

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

# Convert string to array to correctly escape cli parameter
SSH_OPTS=($SSH_OPTS)

function clean(){
  rm -rf $D
}

function generateSite(){
  "$BASE/bin/indexGenerator.py" \
    --distribution redhat \
    --targetDir "${D}"
  
  gpg --export -a --output "$D/${ORGANIZATION}.key" "${GPG_KEYNAME}"
  
  "$BASE/bin/branding.py" "$D"
  
  cp "$RPM" "$D/RPMS/noarch"

cat  > "$D/${ARTIFACTNAME}.repo" << EOF
[${ARTIFACTNAME}]
name=${PRODUCTNAME}${RELEASELINE}
baseurl=${RPM_URL}
gpgcheck=1
EOF

  # generate index 
  # locally
  createrepo --update -o "$RPM_WEBDIR" "$RPMDIR/"
  # on the server
  # shellcheck disable=SC2029
  ssh "${SSH_OPTS[@]}" "$PKGSERVER"  createrepo --update -o "'$RPM_WEBDIR'" "'$RPMDIR/'"

}

function skipIfAlreadyPublished(){

  if ssh "${SSH_OPTS[@]}" "$PKGSERVER" test -e "${RPMDIR}/$(basename "$RPM")"; then
    echo "File already published, nothing else todo"
    exit 0

  fi
}

function init(){
  mkdir -p "$D/RPMS/noarch"

  mkdir -p "$RPMDIR/"
  # mkdir -p "$RPM_WEBDIR/" # May not be necessary
  # shellcheck disable=SC2029
  ssh "${SSH_OPTS[@]}" "$PKGSERVER"  mkdir -p "'$RPMDIR/'"
}


function uploadPackage(){
  # Local
  rsync \
    -avz \
    --ignore-existing \
    --progress \
    "$RPM" "$RPMDIR/"

  # Remote 
  rsync \
    -avz \
    -e "ssh ${SSH_OPTS[*]}" \
    --ignore-existing \
    --progress \
    "$RPM" "$PKGSERVER:${RPMDIR// /\\ }/"
}

function show(){
  echo "Parameters:"
  echo "RPM: $RPM"
  echo "RPMDIR: $RPMDIR"
  echo "RPM_WEBDIR: $RPM_WEBDIR"
  echo "SSH_OPTS: ${SSH_OPTS[*]}"
  echo "PKGSERVER: $PKGSERVER"
  echo "GPG_KEYNAME: $GPG_KEYNAME"
  echo "---"
}

function uploadSite(){
  pushd "$D"
    rsync \
      -avz \
      --exclude RPMS \
      --exclude "HEADER.html" \
      --exclude "FOOTER.html" \
      --progress \
      . "$RPM_WEBDIR/"

    rsync \
      -avz \
      -e "ssh ${SSH_OPTS[*]}" \
      --exclude RPMS \
      --exclude "HEADER.html" \
      --exclude "FOOTER.html" \
      --progress \
      . "$PKGSERVER:${RPM_WEBDIR// /\\ }/"

    # Following html need to be located inside the binary directory
    rsync \
      -avz \
      --include "HEADER.html" \
      --include "FOOTER.html" \
      --exclude "*" \
      --progress \
      . "$RPMDIR/"

    rsync \
      -rlpgoDvz \
      -e "ssh ${SSH_OPTS[*]}" \
      --include "HEADER.html" \
      --include "FOOTER.html" \
      --exclude "*" \
      -O \
      --no-o --no-g --no-perms \
      --progress \
      . "$PKGSERVER:${RPMDIR// /\\ }/"
  popd
}

show
## Disabling this function allow us to recreate and sign the RedHat repository.
# the rpm package won't be overrided as we use the parameter '--ignore-existing' when we upload it
#skipIfAlreadyPublished
init
generateSite
uploadPackage
uploadSite
clean
