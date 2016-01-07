#
# Environment definition for dry-run of the packaging process
# 

# JENKINS used to generate OSX/MSI packages
export JENKINS_URL=https://cloudbees.ci.cloudbees.com/

# the host to publish bits to
export PKGSERVER=${USER}@localhost

# where to put binary files
export TESTDIR==$(realpath .)/pkg.jenkins-ci.org
export WARDIR=${TESTDIR}/war${RELEASELINE}
export MSIDIR=${TESTDIR}/windows${RELEASELINE}
export OSXDIR=${TESTDIR}/osx${RELEASELINE}
export DEBDIR=${TESTDIR}/debian${RELEASELINE}/binary
export RPMDIR=${TESTDIR}/redhat${RELEASELINE}
export SUSEDIR=${TESTDIR}/opensuse${RELEASELINE}

# where to put repository index and other web contents
export  RPM_WEBDIR=${TESTDIR}/redhat${RELEASELINE}
export SUSE_WEBDIR=${TESTDIR}/opensuse${RELEASELINE}
export  DEB_WEBDIR=${TESTDIR}/debian${RELEASELINE}

# URL to the aforementioned webdir.
WEBSERVER=test.pkg.jenkins-ci.org:9200
export  RPM_URL=http://${WEBSERVER}/redhat${RELEASELINE}
export SUSE_URL=http://${WEBSERVER}/opensuse${RELEASELINE}
export  DEB_URL=http://${WEBSERVER}/debian${RELEASELINE}

# additoinal contents to be overlayed during publishing
export OVERLAY_CONTENTS=${BASE}/env/release
