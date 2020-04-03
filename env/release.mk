#
# Environment definition for official OSS Jenkins packaging
# 

# JENKINS used to generate OSX/MSI packages
export JENKINS_URL=https://cloudbees.ci.cloudbees.com/

# the host to publish bits to
export PKGSERVER=mirrorbrain@pkg.jenkins.io
export SSH_OPTS=-p 22
export SCP_OPTS=-P 22

# where to put binary files
export WARDIR=/packages/binary/war${RELEASELINE}
export MSIDIR=/packages/binary/windows${RELEASELINE}
export OSXDIR=/srv/releases/jenkins/osx${RELEASELINE}
export DEBDIR=/packages/binary/debian${RELEASELINE}
export RPMDIR=/packages/binary/redhat${RELEASELINE}
export SUSEDIR=/packages/binary/opensuse${RELEASELINE}

# where to put repository index and other web contents
export  RPM_WEBDIR=/packages/web/redhat${RELEASELINE}
export SUSE_WEBDIR=/packages/web/opensuse${RELEASELINE}
export  DEB_WEBDIR=/packages/web/debian${RELEASELINE}
export  WAR_WEBDIR=/packages/web/war${RELEASELINE}
export  MSI_WEBDIR=/packages/web/windows${RELEASELINE}

# URL to the aforementioned webdir
export  RPM_URL=https://pkg.jenkins.io/redhat${RELEASELINE}
export SUSE_URL=https://pkg.jenkins.io/opensuse${RELEASELINE}
export  DEB_URL=https://pkg.jenkins.io/debian${RELEASELINE}
