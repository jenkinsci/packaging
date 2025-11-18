#
# Environment definition for dry-run of the packaging process
#

# where to put binary files
export BASE_PKG_DIR=/var/www/get.jenkins.io.staging
export WARDIR="${BASE_PKG_DIR}/jenkins/war${RELEASELINE}"
export MSIDIR="${BASE_PKG_DIR}/jenkins/windows${RELEASELINE}"
export DEBDIR="${BASE_PKG_DIR}/jenkins/debian${RELEASELINE}/binary"
export RPMDIR="${BASE_PKG_DIR}/jenkins/rpm${RELEASELINE}"

# where to put repository index and other web contents
export  RPM_WEBDIR=/srv/releases/jenkins/rpm${RELEASELINE}
export  MSI_WEBDIR=/srv/releases/jenkins/windows${RELEASELINE}
export  DEB_WEBDIR=/srv/releases/jenkins/debian${RELEASELINE}
export  WAR_WEBDIR=/srv/releases/jenkins/war${RELEASELINE}

# URL to the aforementioned webdir.
WEBSERVER=https://pkg.jenkins.io
export  RPM_URL=${WEBSERVER}/rpm${RELEASELINE}
export  DEB_URL=${WEBSERVER}/debian${RELEASELINE}
