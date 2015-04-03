#!/bin/bash -ex

base=$(dirname $0)

ssh $PKGSERVER mkdir -p $RPMDIR/
rsync -avz "$RPM" $PKGSERVER:$RPMDIR/

D=/tmp/$$
mkdir -p $D/RPMS/noarch
cp "$RPM" $D/RPMS/noarch

$base/gen.rb > $D/index.html
if $OSS_JENKINS; then
  cat $base/htaccess     | sed -e "s/@RELEASELINE@/${RELEASELINE}/g" | sed -e "s#@URL@#${RPM_URL}#g" > $D/.htaccess
else
  rm $D/.htaccess || true
fi
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