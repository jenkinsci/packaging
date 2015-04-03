# war file to release
export WAR:=jenkins.war

# sanitized version number
export VERSION:=$(shell unzip -p "${WAR}" META-INF/MANIFEST.MF | grep Implementation-Version | cut -d ' ' -f2 | tr -d '\r' | sed -e "s/-SNAPSHOT//" | sed -e "s/-beta-.*//")

# directory to place marker files for build artifacts
export BUILD:=build

# where to generate MSI file?
export MSI:=${BUILD}/msi/${ARTIFACTNAME}-${VERSION}.zip

export BASE:=$(CURDIR)