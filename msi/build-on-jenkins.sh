#!/bin/bash -ex
bin=$(dirname $0)
tar cvzf /tmp/$$.tgz -C $bin FindJava.java build.sh ${ARTIFACTNAME}.wxs jenkins.exe.config bootstrapper.xml
encodedv=$($bin/encode-version.rb $VERSION)
echo java -jar $BUILD/jenkins-cli.jar dist-fork -z /tmp/$$.tgz -f ${ARTIFACTNAME}.war="${WAR}" -l windows -F "${MSI}=${ARTIFACTNAME}-$v-windows.zip" bash -ex build.sh ${ARTIFACTNAME}.war $encodedv ${ARTIFACTNAME} "${PRODUCTNAME}" ${PORT}
rm /tmp/$$.tgz
