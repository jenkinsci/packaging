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
    --binaryDir "$RPMDIR" \
    --targetDir "$RPM_WEBDIR"
  
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

function init(){
  mkdir -p "$D/RPMS/noarch"

  mkdir -p "$RPMDIR/"
  # mkdir -p "$RPM_WEBDIR/" # May not be necessary
  # shellcheck disable=SC2029
  ssh "${SSH_OPTS[@]}" "$PKGSERVER"  mkdir -p "'$RPMDIR/'"
}


function uploadPackage(){
  rsync -avz "$RPM" "$RPMDIR/"
  rsync -avz -e "ssh ${SSH_OPTS[*]}"  "$RPM" "$PKGSERVER:${RPMDIR// /\\ }/"
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
    rsync -avz --exclude RPMS . "$RPM_WEBDIR/"
    rsync -avz -e "ssh ${SSH_OPTS[*]}" --exclude RPMS . "$PKGSERVER:${RPM_WEBDIR// /\\ }"
  popd
}

show
init
generateSite
uploadPackage
uploadSite
clean
