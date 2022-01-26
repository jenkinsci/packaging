#!/bin/bash -ex
#
# build a debian package from a release build

hostname
dir=$(dirname $0)

# tmp dir
D=/tmp/$$/$$
mkdir -p $D

# debian packaging needs to touch the file in the source tree, so do this in tmp dir
# so that multiple builds can go on concurrently
cp -R $dir/* $D

# Create a description temp file
sed -i.bak -e 's/^\s*$/./' -e 's/^/ /' $DESCRIPTION_FILE

# Expand variables in the definition
"$BASE/bin/branding.py" $D/debian

# Rewrite the file
mv "$DESCRIPTION_FILE.bak" "$DESCRIPTION_FILE"

cat >$D/debian/changelog <<EOF
${ARTIFACTNAME} ($VERSION${DEB_REVISION}) unstable; urgency=low

  * Packaged ${VERSION} https://jenkins.io/changelog${RELEASELINE}/#v${VERSION}

 -- ${AUTHOR}  $(date -R)

EOF

# build the debian package
cp "${WAR}" $D/${ARTIFACTNAME}.war
pushd $D
pushd debian
# rename jenkins.* to artifact.*
for f in jenkins.*; do
	mv $f ${f}_
	mv ${f}_ ${ARTIFACTNAME}$(echo $f | cut -b8-)
done
popd
debuild -Zgzip -A
popd

mkdir -p "$(dirname "${DEB}")" || true
mv $D/../${ARTIFACTNAME}_${VERSION}${DEB_REVISION}_all.deb ${DEB}
rm -rf $D
