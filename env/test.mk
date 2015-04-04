#
# Environment definition for dry-run of the packaging process
# 

# JENKINS used to generate OSX/MSI packages
export JENKINS_URL=https://cloudbees.ci.cloudbees.com/

# the host to publish bits to
export PKGSERVER=localhost

# where to put binary files
export WARDIR=/tmp/jenkins/war${RELEASELINE}
export MSIDIR=/tmp/jenkins/windows${RELEASELINE}
export OSXDIR=/tmp/jenkins/osx${RELEASELINE}
export DEBDIR=/tmp/jenkins/debian${RELEASELINE}
export RPMDIR=/tmp/jenkins/redhat${RELEASELINE}
export SUSEDIR=/tmp/jenkins/opensuse${RELEASELINE}

# where to put repository index and other web contents
export  RPM_WEBDIR=/tmp/jenkins/www/pkg.jenkins-ci.org.staging/redhat${RELEASELINE}
export SUSE_WEBDIR=/tmp/jenkins/www/pkg.jenkins-ci.org.staging/opensuse${RELEASELINE}
export  DEB_WEBDIR=/tmp/jenkins/www/pkg.jenkins-ci.org.staging/debian${RELEASELINE}

# URL to the aforementioned webdir
export  RPM_URL=http://localhost:9200/redhat${RELEASELINE}
export SUSE_URL=http://localhost:9200/opensuse${RELEASELINE}
export  DEB_URL=http://localhost:9200/debian${RELEASELINE}

export OSS_JENKINS=true
