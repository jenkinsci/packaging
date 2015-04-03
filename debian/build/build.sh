#!/bin/bash -ex
#
# build a debian package from a release build

dir=$(dirname $0)

# tmp dir
D=/tmp/$$/$$
mkdir -p $D

# debian packaging needs to touch the file in the source tree, so do this in tmp dir
# so that multiple builds can go on concurrently
cp -R $dir/* $D

cat > $D/debian/changelog << EOF
${ARTIFACTNAME} ($VERSION) unstable; urgency=low

  * Packaged ${VERSION}

 -- Kohsuke Kawaguchi <kk@kohsuke.org>  $(date -R)

EOF

# build the debian package
cp "${WAR}" $D/${ARTIFACTNAME}.war
pushd $D
  debuild -us -uc -A
popd

mkdir "$(dirname "${DEB}")"
mv $D/../jenkins_${VERSION}_all.deb ${DEB}

rm -rf $D