# war file to release
export WAR?=$(error Required variable WAR must point to the jenkins.war file you are packaging)

# sanitized version number
export VERSION:=$(shell unzip -p "${WAR}" META-INF/MANIFEST.MF | grep Implementation-Version | cut -d ' ' -f2 | tr -d '\r' | sed -e "s/-SNAPSHOT//" | sed -e "s/-alpha-.*//" | sed -e "s/-beta-.*//" | sed -e "s/-rc-.*//" | tr - .)

# directory to place marker files for build artifacts
export TARGET:=target

# jenkins-cli.jar
export CLI:=${TARGET}/jenkins-cli.jar

export WAR_SHASUM=${TARGET}/SHA256SUMS

# where to generate MSI file?
export MSI:=${TARGET}/msi/${ARTIFACTNAME}-${VERSION}.zip
export MSI_SHASUM:=${TARGET}/msi/SHA256SUMS

# where to generate OSX PKG file?
export OSX=${TARGET}/osx/${ARTIFACTNAME}-${VERSION}.pkg
export OSX_SHASUM=${TARGET}/osx/SHA256SUMS

# where to generate Debian/Ubuntu DEB file?
export DEB=${TARGET}/debian/${ARTIFACTNAME}_${VERSION}_all.deb

# where to generate RHEL/CentOS RPM file?
export RPM=${TARGET}/rpm/${ARTIFACTNAME}-${VERSION}-1.1.noarch.rpm

# where to generate SUSE RPM file?
export SUSE=${TARGET}/suse/${ARTIFACTNAME}-${VERSION}-1.2.noarch.rpm

# anchored to the root of the repository
export BASE:=$(CURDIR)

# read license file and do reformatting for proper display
export LICENSE_TEXT:=$(shell cat "$(LICENSE_FILE)")
export LICENSE_TEXT_COLUMN:=$(shell fold -w 78 -s "$(LICENSE_FILE)")  # Format to 80 characters
export LICENSE_TEXT_COMMENTED:=$(shell echo "$(LICENSE_TEXT_COLUMN)" | sed  's!^!\# !g' )

# Put a dot in place of an empty line, and prepend a space
export LICENSE_TEXT_DEB:=$(shell echo "$(LICENSE_TEXT_COLUMN)" | sed -e 's!^$$!.!g' -e 's!^! !g' )

