#!/bin/bash -ex

base=$(dirname $0)

ssh $PKGSERVER mkdir -p $RPMDIR/
rsync -avz "$RPM" $PKGSERVER:$RPMDIR/

D=/tmp/$$
mkdir -p $D/RPMS/noarch

$base/gen.rb > $D/index.html
cp $base/jenkins-ci.org.key $D/

[ -d ${OVERLAY_CONTENTS}/rpm ] && cp -R ${OVERLAY_CONTENTS}/rpm/. $D
"$BASE/bin/branding.py" $D

cp "$RPM" $D/RPMS/noarch

cat  > $D/${ARTIFACTNAME}.repo << EOF
[${ARTIFACTNAME}]
name=${PRODUCTNAME}${RELEASELINE}
baseurl=${RPM_URL}
gpgcheck=1
EOF

pushd $D
  rsync -avz --exclude RPMS . $PKGSERVER:$RPM_WEBDIR
popd

# generate index on the server
# server needs 'createrepo' pacakge
ssh $PKGSERVER createrepo --update -o $RPM_WEBDIR $RPMDIR/

rm -rf $D