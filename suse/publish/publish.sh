#!/bin/bash -ex

: "${AGENT_WORKDIR:=/tmp}"

mkdir -p "$SUSEDIR/"
mkdir -p "$SUSE_WEBDIR"

rsync -avz "$SUSE" "$SUSEDIR/"

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

mkdir -p $D/RPMS/noarch $D/repodata

"$BASE/bin/indexGenerator.py" \
  --distribution suse \
  --binaryDir "$SUSEDIR" \
  --targetDir "$SUSE_WEBDIR"

cp "${GPG_PUBLIC_KEY}" $D/repodata/repomd.xml.key

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
