#!/bin/bash -ex

base=$(dirname $0)

ssh $PKGSERVER mkdir -p $SUSEDIR/
rsync -avz "$1" $PKGSERVER:$SUSEDIR/

D=/tmp/$$
mkdir -p $D/RPMS/noarch $D/repodata
cp "$SUSE" $D/RPMS/noarch

$base/gen.rb > $D/index.html

[ -d ${OVERLAY_CONTENTS}/suse ] && cp -R ${OVERLAY_CONTENTS}/suse/* $D

cp $base/jenkins-ci.org.key $D/repodata/repomd.xml.key

pushd $D
  rsync -avz --exclude RPMS . $PKGSERVER:$SUSE_WEBDIR

  # generate index on the server
  # server needs 'createrepo' pacakge
  ssh $PKGSERVER createrepo --update -o $SUSE_WEBDIR $SUSEDIR/

  # sign the final artifact and upload the signature
  scp $PKGSERVER:$SUSE_WEBDIR/repodata/repomd.xml repodata/

  gpg -a --detach-sign --yes --no-use-agent --passphrase-file $GPG_PASSPHRASE_FILE repodata/repomd.xml
  scp repodata/repomd.xml.asc $PKGSERVER:$SUSE_WEBDIR/repodata/
popd
