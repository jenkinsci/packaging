#!/bin/bash

set -x  # Exit on any command failure, can't use -u because of check for non-zero length of arg 1

if [ -z "$1" ]; then
  JENKINS_CENTOS_INSTALLER_FILE=$(ls /tmp/packaging/target/centos/*.rpm)
  # Change to /tmp/packaging so that results are written in /tmp/packaging/results
  cd /tmp/packaging
else
  JENKINS_CENTOS_INSTALLER_FILE="$1"
fi

. "$(dirname $0)/sh2ju.sh"

# Read operating system information into variables

. /etc/os-release

OS="${ID}.${VERSION_ID}" # opencentos-leap.15.1 so that JUnit package naming can be used

#######################################################################

install_failure_msg="yum install failed on $JENKINS_CENTOS_INSTALLER_FILE"

centos_yum_install() {
    # Intentionally do not add yum repo - install file is local
    # wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
    yum install -y $JENKINS_CENTOS_INSTALLER_FILE || echo $install_failure_msg
}

juLog -error=yum.install.failed.on -suite="${OS}.install" -name="DockerInstall" centos_yum_install

#######################################################################

verify_failure_message="yum verify check failed on jenkins verify"

centos_yum_verify_check() {
    yum verify jenkins || echo $verify_failure_message
}

juLog -error=yum.verify.check.failed.on.jenkins.verify -suite="${OS}.install" -name="DockerPackageCheck" centos_yum_verify_check

#######################################################################

info_failure_message="yum info check failed on jenkins package"

centos_yum_info_check() {
    yum info jenkins | grep 'Jenkins is an open source automation server' || echo $info_failure_message
}

juLog -error=yum.info.check.failed.on.jenkins.package -suite="${OS}.install" -name="DockerInfoCheck" centos_yum_info_check
