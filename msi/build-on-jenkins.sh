#!/bin/bash -ex
# this script runs on the release machine to submit the actual msi build to a Windows machine

bin=$(dirname $0)
encodedv=$($bin/encode-version.rb $VERSION)

# replace variables in the wxs file
eval "cat > /tmp/$$.wxs <<EOF
$(<$bin/jenkins.wxs)
EOF
" 2> /dev/null

tar cvzf /tmp/$$.tgz -C $bin FindJava.java build.sh /tmp/$$.wxs jenkins.exe.config bootstrapper.xml
echo java -jar $BUILD/jenkins-cli.jar dist-fork -z /tmp/$$.tgz -f ${ARTIFACTNAME}.war="${WAR}" -l windows -F "${MSI}=${ARTIFACTNAME}-windows.zip" bash -ex build.sh ${ARTIFACTNAME}.war $encodedv ${ARTIFACTNAME} "${PRODUCTNAME}" ${PORT}
rm /tmp/$$.tgz /tmp/$$.wxs
