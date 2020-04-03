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
export WARDIR=/srv/releases/jenkins/war${RELEASELINE}
export MSIDIR=/srv/releases/jenkins/windows${RELEASELINE}
export OSXDIR=/srv/releases/jenkins/osx${RELEASELINE}
export DEBDIR=/srv/releases/jenkins/debian${RELEASELINE}
export RPMDIR=/srv/releases/jenkins/redhat${RELEASELINE}
export SUSEDIR=/srv/releases/jenkins/opensuse${RELEASELINE}

# where to put repository index and other web contents
export  RPM_WEBDIR=/var/www/pkg.jenkins.io.staging/redhat${RELEASELINE}
export SUSE_WEBDIR=/var/www/pkg.jenkins.io.staging/opensuse${RELEASELINE}
export  DEB_WEBDIR=/var/www/pkg.jenkins.io.staging/debian${RELEASELINE}
export  WAR_WEBDIR=/var/www/pkg.jenkins.io.staging/war${RELEASELINE}
export  MSI_WEBDIR=/var/www/pkg.jenkins.io.staging/windows${RELEASELINE}

# URL to the aforementioned webdir
export  RPM_URL=https://pkg.jenkins.io/redhat${RELEASELINE}
export SUSE_URL=https://pkg.jenkins.io/opensuse${RELEASELINE}
export  DEB_URL=https://pkg.jenkins.io/debian${RELEASELINE}
