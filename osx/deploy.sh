#!/bin/bash -ex
# Usage deploy.sh <workspace> <war>
v=$(unzip -p "$2" META-INF/MANIFEST.MF | grep Implementation-Version | cut -d ' ' -f2 | tr -d '\r' | sed -e "s/-SNAPSHOT//" | sed -e "s/-beta-.*//")
export JENKINS_URL=http://jenkins.local/
if [ -d "$1/osx" ]; then
  $(dirname $0)/build-on-jenkins.sh "$1" "$2" ${ARTIFACTNAME}-$v.pkg
  rsync -avz "${ARTIFACTNAME}-$v.pkg" $PKGSERVER:$OSXDIR/
fi
