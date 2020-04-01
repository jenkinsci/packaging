#!/bin/bash -ex

: "${AGENT_WORKDIR:=/tmp}"

mkdir -p "$SUSEDIR/"
mkdir -p "$SUSE_WEBDIR"

rsync -avz "$SUSE" "$SUSEDIR/"

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

mkdir -p $D/RPMS/noarch $D/repodata

"$BASE/bin/indexGenerator.py" \
  --distribution opensuse \
  --binaryDir "$SUSEDIR" \
  --targetDir "$SUSE_WEBDIR"

gpg --export -a --output "$D/repodata/repomd.xml.key" "${GPG_KEYNAME}"

"$BASE/bin/branding.py" $D

cp "$SUSE" $D/RPMS/noarch

pushd $D
  rsync -avz --exclude RPMS . "$SUSE_WEBDIR/"

  # generate index on the server
  # server needs 'createrepo' pacakge
popd

createrepo --update -o "$SUSE_WEBDIR" "$SUSEDIR/"

gpg \
  --batch \
  --pinentry-mode loopback \
  -u "$GPG_KEYNAME" \
  -a \
  --detach-sign \
  --yes \
  "$SUSE_WEBDIR/repodata/repomd.xml"
