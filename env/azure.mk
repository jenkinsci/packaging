#
# Environment definition for dry-run of the packaging process
# 
# the host to publish bits to
# Temporary real pkgserver
export PKGSERVER=mirrorbrain@20.186.155.37
export SSH_OPTS='-p 22 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
export SCP_OPTS='-P 22 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

# where to put binary files
export WARDIR=/srv/releases/jenkins/war${RELEASELINE}
export MSIDIR=/srv/releases/jenkins/windows${RELEASELINE}
export DEBDIR=/srv/releases/jenkins/debian${RELEASELINE}/binary
export RPMDIR=/srv/releases/jenkins/redhat${RELEASELINE}
export SUSEDIR=/srv/releases/jenkins/opensuse${RELEASELINE}

# where to put repository index and other web contents
export  RPM_WEBDIR=/srv/releases/jenkins/redhat${RELEASELINE}
export  SUSE_WEBDIR=/srv/releases/jenkins/opensuse${RELEASELINE}
export  DEB_WEBDIR=/srv/releases/jenkins/debian${RELEASELINE}
export  WAR_WEBDIR=/srv/releases/jenkins/war${RELEASELINE}

# URL to the aforementioned webdir.
WEBSERVER=pkg.jenkins.io
export  RPM_URL=https://${WEBSERVER}/redhat${RELEASELINE}
export SUSE_URL=https://${WEBSERVER}/opensuse${RELEASELINE}
export  DEB_URL=https://${WEBSERVER}/debian${RELEASELINE}
