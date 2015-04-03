export RELEASELINE=

export PRODUCTNAME=JenkinsTest
export ARTIFACTNAME=jenkinsTest
export VENDOR=Jenkins Test project
export SUMMARY=Jenkins Continuous Integration Server (Test)
export PORT=7777

# the host to deploy bits to
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

# Windows packaging details
export MSI_PRODUCTCODE=e76baa9f-2bb2-49e5-b518-8a5b7d1cd084
export MSI_PRODUCTDIR=JenkinsTest
export MSI_SERVICENAME=JenkinsTestService

export OSS_JENKINS=true
