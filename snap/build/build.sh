#!/bin/bash -ex
#
# build a snap package from a release build

hostname
dir=$(dirname $0)

# tmp dir
D=/tmp/$$/$$
mkdir -p $D

# snap packaging needs to touch the file in the source tree, so do this in tmp dir
# so that multiple builds can go on concurrently
cp -R $dir/* $D

# Expand variables in the definition
"$BASE/bin/branding.py" $D

# build the debian package
cp "${WAR}" $D/${ARTIFACTNAME}.war
pushd $D
  snapcraft
popd

mkdir -p "$(dirname "${SNAP}")" || true
mv $D/${ARTIFACTNAME}_${VERSION}_${ARCH}.snap ${SNAP}

rm -rf $D
