#
# Environment definition for dry-run of the packaging process
#

# where to put binary files
export TESTDIR=$(realpath .)/pkg.jenkins.io
export WARDIR=${TESTDIR}/war${RELEASELINE}
export MSIDIR=${TESTDIR}/windows${RELEASELINE}
export DEBDIR=${TESTDIR}/debian${RELEASELINE}/binary
export RPMDIR=${TESTDIR}/redhat${RELEASELINE}
export SUSEDIR=${TESTDIR}/opensuse${RELEASELINE}

# where to put repository index and other web contents
export  RPM_WEBDIR=${TESTDIR}/redhat${RELEASELINE}
export SUSE_WEBDIR=${TESTDIR}/opensuse${RELEASELINE}
export  DEB_WEBDIR=${TESTDIR}/debian${RELEASELINE}
export  MSI_WEBDIR=${TESTDIR}/windows${RELEASELINE}

# URL to the aforementioned webdir.
WEBSERVER=https://pkg.jenkins.io
export  RPM_URL=${WEBSERVER}/rpm${RELEASELINE}
export SUSE_URL=${WEBSERVER}/opensuse${RELEASELINE}
export  DEB_URL=${WEBSERVER}/debian${RELEASELINE}
