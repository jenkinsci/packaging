# war file to release
export WAR:=jenkins.war

# sanitized version number
export VERSION:=$(shell unzip -p "${WAR}" META-INF/MANIFEST.MF | grep Implementation-Version | cut -d ' ' -f2 | tr -d '\r' | sed -e "s/-SNAPSHOT//" | sed -e "s/-beta-.*//")

# directory to place marker files for build artifacts
export BUILD:=build

# where to generate MSI file?
export MSI:=${BUILD}/msi/${ARTIFACTNAME}-${VERSION}.zip

# where to generate OSX PKG file?
export OSX=${BUILD}/osx/${ARTIFACTNAME}-${VERSION}.pkg

# where to generate Debian/Ubuntu DEB file?
export DEB=${BUILD}/debian/${ARTIFACTNAME}_${VERSION}_all.deb

# where to generate RHEL/CentOS RPM file?
export RPM=${BUILD}/rpm/${ARTIFACTNAME}-${VERSION}-1.1.noarch.rpm

# where to generate SUSE RPM file?
export SUSE=${BUILD}/rpm/${ARTIFACTNAME}-${VERSION}-1.2.noarch.rpm

export BASE:=$(CURDIR)