#
# Environment definition for dry-run of the packaging process
# 

# JENKINS used to generate OSX/MSI packages
export JENKINS_URL=https://cloudbees.ci.cloudbees.com/

# the host to publish bits to
export PKGSERVER=jenkins@remote
# Testing both with and without SSH_OPTS
#export SSH_OPTS=-p 22
#export SCP_OPTS=-P 22
export SSH_OPTS=-p 22 -o StrictHostKeyChecking=no
export SCP_OPTS=-P 22 -o StrictHostKeyChecking=no

# where to put binary files
export TESTDIR=$(realpath .)/pkg.jenkins.io
export WARDIR=${TESTDIR}.staging/war${RELEASELINE}
export MSIDIR=${TESTDIR}.staging/windows${RELEASELINE}
export OSXDIR=${TESTDIR}.staging/osx${RELEASELINE}
export DEBDIR=${TESTDIR}.staging/debian${RELEASELINE}/binary
export RPMDIR=${TESTDIR}.staging/redhat${RELEASELINE}
export SUSEDIR=${TESTDIR}.staging/opensuse${RELEASELINE}

export PROD_RPMDIR=${TESTDIR}/redhat${RELEASELINE}
export PROD_SUSEDIR=${TESTDIR}/opensuse${RELEASELINE}

# where to put repository index and other web contents
export  RPM_WEBDIR=${TESTDIR}.staging/redhat${RELEASELINE}
export SUSE_WEBDIR=${TESTDIR}.staging/opensuse${RELEASELINE}
export  DEB_WEBDIR=${TESTDIR}.staging/debian${RELEASELINE}
export  WAR_WEBDIR=${TESTDIR}.staging/war${RELEASELINE}
export  MSI_WEBDIR=${TESTDIR}.staging/windows${RELEASELINE}

# URL to the aforementioned webdir.
WEBSERVER=pkg.jenkins.io
export  RPM_URL=https://${WEBSERVER}/redhat${RELEASELINE}
export SUSE_URL=https://${WEBSERVER}/opensuse${RELEASELINE}
export  DEB_URL=https://${WEBSERVER}/debian${RELEASELINE}
