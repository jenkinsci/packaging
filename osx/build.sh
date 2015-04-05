#!/bin/bash

WAR="$1"
VERSION="$2"
ARTIFACTNAME="${3:-jenkins}"
PRODUCTNAME="${4:-Jenkins}"

# Usage
if [ -z "$WAR" ]; then
	echo "Usage: build.sh path/to/jenkins.war"
	exit 1
fi

# Set up build tools
PACKAGEMAKER_APP=$(mdfind "kMDItemCFBundleIdentifier == com.apple.PackageMaker")
if [ -z "$PACKAGEMAKER_APP" ]; then
    PACKAGEMAKER_APP=/Applications/PackageMaker.app
    if [ ! -d "$PACKAGEMAKER_APP" ]; then
        echo "Error: PackageMaker.app not found" >&2
        exit 1
    fi
fi

PACKAGEMAKER="${PACKAGEMAKER_APP}/Contents/MacOS/PackageMaker"

# Get the Jenkins version number
cp "$WAR" $(dirname $0)/jenkins.war.tmp
if [ -z "$VERSION" ]; then
  VERSION=$(unzip -p $(dirname $0)/jenkins.war.tmp META-INF/MANIFEST.MF | grep Implementation-Version | cut -d ' ' -f2 | tr -d '\r' | sed -e "s/-SNAPSHOT//" | tr - . )
fi
echo Version is $VERSION
PKG_NAME="${ARTIFACTNAME}.pkg"
PKG_TITLE="${PRODUCTNAME} ${VERSION}"
rm $(dirname $0)/jenkins.war.tmp

# Fiddle with the package document so it points to the jenkins.war file provided
PACKAGEMAKER_DOC="$(dirname $0)/JenkinsInstaller.pmdoc"
mv $PACKAGEMAKER_DOC/01jenkins-contents.xml $PACKAGEMAKER_DOC/01jenkins-contents.xml.orig
sed s,"pt=\".*\" m=","pt=\"${WAR}\" m=",g $PACKAGEMAKER_DOC/01jenkins-contents.xml.orig > $PACKAGEMAKER_DOC/01jenkins-contents.xml
mv $PACKAGEMAKER_DOC/01jenkins.xml $PACKAGEMAKER_DOC/01jenkins.xml.orig
sed s,"<installFrom mod=\"true\">.*</installFrom>","<installFrom mod=\"true\">${WAR}</installFrom>",g $PACKAGEMAKER_DOC/01jenkins.xml.orig > $PACKAGEMAKER_DOC/01jenkins.xml

mkdir -p /tmp/test
cp -R * /tmp/test

# Build the package
"${PACKAGEMAKER}" \
	--doc "${PACKAGEMAKER_DOC}" \
	--out "unsigned-${PKG_NAME}" \
	--version "${VERSION}" \
	--title "${PKG_TITLE}"

# sign the package. the 'security' tool needs keychain file to be specified in full path
SIGN_IDENTITY="$(security find-identity $PWD/jenkins.keychain | grep "1)" | head -n1 | cut -f4 -d' ')"
set +x
security unlock-keychain -p $(cat ./jenkins.keychain.password | tr -d '\n') $PWD/jenkins.keychain
set -x
productsign --keychain $PWD/jenkins.keychain --sign "$SIGN_IDENTITY" unsigned-${PKG_NAME} ${PKG_NAME}
security lock-keychain $PWD/jenkins.keychain
rm jenkins.keychain jenkins.keychain.password

# Reset the fiddling so git doesn't get confused
mv $PACKAGEMAKER_DOC/01jenkins.xml.orig $PACKAGEMAKER_DOC/01jenkins.xml
mv $PACKAGEMAKER_DOC/01jenkins-contents.xml.orig $PACKAGEMAKER_DOC/01jenkins-contents.xml
