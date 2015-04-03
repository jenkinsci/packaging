#!/bin/bash -ex
v=$(unzip -p "$1" META-INF/MANIFEST.MF | grep Implementation-Version | cut -d ' ' -f2 | tr -d '\r' | sed -e "s/-SNAPSHOT//" | sed -e "s/-beta-.*//")
$(dirname $0)/build-on-jenkins.sh $1 ${ARTIFACTNAME}-$v.zip
rsync -avz "${ARTIFACTNAME}-$v.zip" $PKGSERVER:$MSIDIR/
