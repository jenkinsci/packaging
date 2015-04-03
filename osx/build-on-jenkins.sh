#!/bin/bash -ex

bin=$(dirname $0)
D=/tmp/$$
mkdir $D

tar cvzf $D/script.tgz -C "$bin" .
v=$(unzip -p "$2" META-INF/MANIFEST.MF | grep Implementation-Version | cut -d ' ' -f2 | tr -d '\r' | sed -e "s/-SNAPSHOT//" | sed -e "s/-beta-.*//")
buildsh="$1/osx/build.sh"
[ -e "$buildsh" ] || buildsh="$(dirname $0)/build.sh"
java -jar $BUILD/jenkins-cli.jar dist-fork -z $D/script.tgz \
  -f binary/${ARTIFACTNAME}.war="${WAR}" \
  -f build.sh=$bin/build.sh -l osx -F "${OSX}=${ARTIFACTNAME}-${VERSION}.pkg" /bin/bash -ex build.sh binary/${ARTIFACTNAME}.war $VERSION $ARTIFACTNAME "$PRODUCTNAME"
rm -rf /tmp/$$