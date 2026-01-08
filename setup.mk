# war file to release
export WAR?=$(error Required variable WAR must point to the jenkins.war file you are packaging)
export WAR_SHASUM=${ARTIFACTNAME}.war.sha256

# sanitized version number
export VERSION:=$(shell unzip -p "${WAR}" META-INF/MANIFEST.MF | grep Implementation-Version | cut -d ' ' -f2 | tr -d '\r' | sed -e "s/-SNAPSHOT//" | sed -e "s/-alpha-.*//" | sed -e "s/-beta-.*//" | sed -e "s/-rc-.*//" | sed -e "s/-rc.*//" | tr - .)

# directory to place marker files for build artifacts
export TARGET:=target

# jenkins-cli.jar
export CLI:=${TARGET}/jenkins-cli.jar

# MSI file to release
export MSI?=$(error Required variable MSI must point to the jenkins.msi file you are packaging)
export MSI_SHASUM:=${MSI}.sha256

# where to generate Debian/Ubuntu DEB file?
export DEB=${TARGET}/debian/${ARTIFACTNAME}_${VERSION}_all.deb

# What is the RPM Build Number ("Release" in the RPM spec, also known as "package suffix"). Can be overriden by setting 'RPM_RELEASENUMBER' env. var .
export RPM_RELEASENUMBER ?= 1
# where to generate RHEL/CentOS RPM file?
export RPM=${TARGET}/rpm/${ARTIFACTNAME}-${VERSION}-${RPM_RELEASENUMBER}.noarch.rpm

# anchored to the root of the repository
export BASE:=$(CURDIR)

# read license file and do reformatting for proper display
export LICENSE_TEXT:=$(shell cat "$(LICENSE_FILE)")
export LICENSE_TEXT_COLUMN:=$(shell fold -w 78 -s "$(LICENSE_FILE)")  # Format to 80 characters
export LICENSE_TEXT_COMMENTED:=$(shell echo "$(LICENSE_TEXT_COLUMN)" | sed  's!^!\# !g' )

# Put a dot in place of an empty line, and prepend a space
export LICENSE_TEXT_DEB:=$(shell echo "$(LICENSE_TEXT_COLUMN)" | sed -e 's!^$$!.!g' -e 's!^! !g' )
