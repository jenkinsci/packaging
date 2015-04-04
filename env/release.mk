#
# Environment definition for official OSS Jenkins packaging
# 

# JENKINS used to generate OSX/MSI packages
export JENKINS_URL=https://cloudbees.ci.cloudbees.com/

# the host to publish bits to
export PKGSERVER=www-data@pkg.jenkins-ci.org

# where to put binary files
export WARDIR=/srv/releases/jenkins/war${RELEASELINE}
export MSIDIR=/srv/releases/jenkins/windows${RELEASELINE}
export OSXDIR=/srv/releases/jenkins/osx${RELEASELINE}
export DEBDIR=/srv/releases/jenkins/debian${RELEASELINE}
export RPMDIR=/srv/releases/jenkins/redhat${RELEASELINE}
export SUSEDIR=/srv/releases/jenkins/opensuse${RELEASELINE}

# where to put repository index and other web contents
export  RPM_WEBDIR=/var/www/pkg.jenkins-ci.org.staging/redhat${RELEASELINE}
export SUSE_WEBDIR=/var/www/pkg.jenkins-ci.org.staging/opensuse${RELEASELINE}
export  DEB_WEBDIR=/var/www/pkg.jenkins-ci.org.staging/debian${RELEASELINE}

# URL to the aforementioned webdir
export  RPM_URL=http://pkg.jenkins-ci.org/redhat${RELEASELINE}
export SUSE_URL=http://pkg.jenkins-ci.org/opensuse${RELEASELINE}
export  DEB_URL=http://pkg.jenkins-ci.org/debian${RELEASELINE}

# additoinal contents to be overlayed during publishing
export OVERLAY_CONTENTS=$BASE/env/release
