#!/bin/bash -ex

base=$(dirname $0)

ssh $SSH_OPTS $PKGSERVER mkdir -p "'$SUSEDIR/'"
rsync -avz -e "ssh $SSH_OPTS" "${SUSE}" "$PKGSERVER:$(echo $SUSEDIR | sed 's/ /\\ /g')/"

D=/tmp/$$
mkdir -p $D/RPMS/noarch $D/repodata

"$base/gen.rb" > $D/index.html
cp "${GPG_PUBLIC_KEY}" $D/repodata/repomd.xml.key

[ -d "${OVERLAY_CONTENTS}/suse" ] && cp -R "${OVERLAY_CONTENTS}/suse/." $D
"$BASE/bin/branding.py" $D

cp "$SUSE" $D/RPMS/noarch

pushd $D
  rsync -avz -e "ssh $SSH_OPTS" --exclude RPMS . "$PKGSERVER:$(echo $SUSE_WEBDIR | sed 's/ /\\ /g')"

  # generate index on the server
  # server needs 'createrepo' pacakge
  ssh $SSH_OPTS $PKGSERVER createrepo --update -o "'$SUSE_WEBDIR'" "'$SUSEDIR/'"

  # sign the final artifact and upload the signature
  scp $SSH_OPTS "$PKGSERVER:$(echo $SUSE_WEBDIR | sed 's/ /\\ /g')/repodata/repomd.xml" repodata/

  gpg --batch --no-use-agent --no-default-keyring --keyring "$GPG_KEYRING" --secret-keyring="$GPG_SECRET_KEYRING" --passphrase-file "$GPG_PASSPHRASE_FILE" \
    -a --detach-sign --yes repodata/repomd.xml
  scp $SSH_OPTS repodata/repomd.xml.asc "$PKGSERVER:$(echo $SUSE_WEBDIR | sed 's/ /\\ /g')/repodata/"
popd
