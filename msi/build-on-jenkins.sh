#!/bin/bash -ex
# this script runs on the release machine to submit the actual msi build to a Windows machine

bin=$(dirname $0)
encodedv=$($bin/encode-version.rb $VERSION)

D=/tmp/$$   # temporary directory
mkdir -p $D

# replace variables in the wxs file
eval "cat > $D/jenkins.wxs <<EOF
$(<$bin/jenkins.wxs)
EOF
" 2> /dev/null

tar cvzf $D/bundle.tgz -C $bin FindJava.java build.sh jenkins.exe.config bootstrapper.xml -C $D jenkins.wxs
java -jar $BUILD/jenkins-cli.jar dist-fork -z $D/bundle.tgz -f ${ARTIFACTNAME}.war="${WAR}" -l windows -F "${MSI}=${ARTIFACTNAME}-windows.zip" \
	bash -ex build.sh ${ARTIFACTNAME}.war $encodedv ${ARTIFACTNAME} "${PRODUCTNAME}" ${PORT}
rm -rf $D
