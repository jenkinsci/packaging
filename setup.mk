# war file to release
export WAR?=$(error Required variable WAR must point to the jenkins.war file you are packaging)

# sanitized version number
export VERSION:=$(shell unzip -p "${WAR}" META-INF/MANIFEST.MF | grep Implementation-Version | cut -d ' ' -f2 | tr -d '\r' | sed -e "s/-SNAPSHOT//" | sed -e "s/-beta-.*//")

# directory to place marker files for build artifacts
export TARGET:=target

# jenkins-cli.jar
export CLI:=${TARGET}/jenkins-cli.jar

# where to generate MSI file?
export MSI:=${TARGET}/msi/${ARTIFACTNAME}-${VERSION}.zip

# where to generate OSX PKG file?
export OSX=${TARGET}/osx/${ARTIFACTNAME}-${VERSION}.pkg

# where to generate Debian/Ubuntu DEB file?
export DEB=${TARGET}/debian/${ARTIFACTNAME}_${VERSION}_all.deb

# where to generate RHEL/CentOS RPM file?
export RPM=${TARGET}/rpm/${ARTIFACTNAME}-${VERSION}-1.1.noarch.rpm

# where to generate SUSE RPM file?
export SUSE=${TARGET}/suse/${ARTIFACTNAME}-${VERSION}-1.2.noarch.rpm

export BASE:=$(CURDIR)