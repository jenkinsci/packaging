#!/bin/bash -ex

bin=$(dirname $0)
D=/tmp/$$
mkdir $D

tar cvzf $D/script.tgz -C "$bin" .

java -jar $TARGET/jenkins-cli.jar dist-fork -z $D/script.tgz \
  -f binary/${ARTIFACTNAME}.war="${WAR}" \
  -f build.sh=$bin/build.sh -l osx -F "${OSX}=jenkins.pkg" \
  /bin/bash -ex build.sh binary/${ARTIFACTNAME}.war $VERSION $ARTIFACTNAME "$PRODUCTNAME"
rm -rf $D