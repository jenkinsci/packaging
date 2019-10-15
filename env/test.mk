#
# Environment definition for dry-run of the packaging process
# 

# JENKINS used to generate OSX/MSI packages
export JENKINS_URL=https://cloudbees.ci.cloudbees.com/

# the host to publish bits to
export PKGSERVER=${USER}@localhost
export SSH_OPTS=
export SCP_OPTS=

# where to put binary files
export TESTDIR=$(realpath .)/pkg.jenkins.io
export WARDIR=/packages/binary/war${RELEASELINE}
export MSIDIR=/packages/binary/windows${RELEASELINE}
export OSXDIR=export OSXDIR=${TESTDIR}/osx${RELEASELINE}
export DEBDIR=/packages/binary/debian${RELEASELINE}
export RPMDIR=/packages/binary/redhat${RELEASELINE}
export SUSEDIR=/packages/binary/opensuse${RELEASELINE}

# where to put repository index and other web contents
export  RPM_WEBDIR=/packages/web/redhat${RELEASELINE}
export SUSE_WEBDIR=/packages/web/opensuse${RELEASELINE}
export  DEB_WEBDIR=/packages/web/debian${RELEASELINE}

# URL to the aforementioned webdir.
WEBSERVER=test.pkg.jenkins.io:9200
export  RPM_URL=http://${WEBSERVER}/redhat${RELEASELINE}
export SUSE_URL=http://${WEBSERVER}/opensuse${RELEASELINE}
export  DEB_URL=http://${WEBSERVER}/debian${RELEASELINE}
