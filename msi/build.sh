#!/bin/bash -ex
export PATH=~/tools/native/wix:/cygdrive/c/Program\ Files/Windows\ Installer\ XML\ v3.5/bin:$PATH

war="$1"
ENCODEDVERSION="$2"
ARTIFACTNAME="$3"
PRODUCTNAME="$4"
PORT="$5"
SERVICENAME="$6"
if [ "" == "$SERVICENAME" ]; then
  echo "build.sh path/to/jenkins.war version artifactName port servicename"
  exit 1
fi

rm -rf tmp || true
mkdir tmp || true
unzip -p "$war" 'WEB-INF/lib/jenkins-core-*.jar' > tmp/core.jar
unzip -p tmp/core.jar windows-service/jenkins.exe > tmp/jenkins.exe
unzip -p tmp/core.jar windows-service/jenkins.xml > tmp/jenkins.xml 

### replace the hard coded variables

# the WAR argument  ( -jar "%BASE%\jenkins.war") 
sed -i -e "s|\bjenkins\.war\b|${ARTIFACTNAME}\.war|" tmp/jenkins.xml

# The service id (used to localte the servicce in the SCM <id>jenkins</id>)
sed -i -e "s|<id>.*</id>|<id>${SERVICENAME}</id>|" tmp/jenkins.xml

# the --httpPort=8080 argument
sed -i -e "s|8080|${PORT}|" tmp/jenkins.xml

# replace executable name to the bundled JRE
sed -i -e 's|executable.*|executable>%BASE%\\jre\\bin\\java</executable>|' tmp/jenkins.xml

# The service description - not actually used as this is installed by the msi - but people could if they wanted to...
sed -i -e "s|<description>\.*</description>|<id>${PRODUCTNAME}</id>|" tmp/jenkins.xml


# capture JRE
javac FindJava.java
JREDIR=$(java -cp . FindJava)
echo "JRE=$JREDIR"
heat dir "$JREDIR" -o jre.wxs -sfrag -sreg -nologo -srd -gg -cg JreComponents -dr JreDir -var var.JreDir

# pick up java.exe File ID
JavaExeId=$(grep java.exe jre.wxs | grep -o "fil[0-9A-F]*")

candle -dJreDir="$JREDIR" -dWAR="$war" -dJavaExeId=$JavaExeId -nologo -ext WixUIExtension -ext WixUtilExtension -ext WixFirewallExtension jenkins.wxs jre.wxs
# '-sval' skips validation. without this, light somehow doesn't work on automated build environment
# set to -dcl:low during debug and -dcl:high for release
light -o ${ARTIFACTNAME}.msi -sval -nologo -dcl:high -ext WixUIExtension -ext WixUtilExtension -ext WixFirewallExtension jenkins.wixobj jre.wixobj

set +x
signtool sign /v /f key.pkcs12 /p $(cat key.password) /t http://timestamp.verisign.com/scripts/timestamp.dll ${ARTIFACTNAME}.msi
set -x

zip ${ARTIFACTNAME}-windows.zip ${ARTIFACTNAME}.msi

# avoid bringing back files that we don't care
rm -rf tmp *.class *.wixpdb *.wixobj
