#!/bin/bash

set -x  # Exit on any command failure, can't use -u because of check for non-zero length of arg 1

if [ -z "$1" ]; then
  JENKINS_FEDORA_INSTALLER_FILE=$(ls /tmp/packaging/target/centos/*.rpm)
  # Change to /tmp/packaging so that results are written in /tmp/packaging/results
  cd /tmp/packaging
else
  JENKINS_FEDORA_INSTALLER_FILE="$1"
fi

. "$(dirname $0)/sh2ju.sh"

# Read operating system information into variables

. /etc/os-release

OS="${ID}.${VERSION_ID}" # fedora.31 so that JUnit package naming can be used

#######################################################################

install_failure_msg="dnf install failed on $JENKINS_FEDORA_INSTALLER_FILE"

centos_dnf_install() {
    dnf install -y $JENKINS_FEDORA_INSTALLER_FILE || echo $install_failure_msg
}

juLog -error=dnf.install.failed.on -suite="${OS}.install" -name="DockerInstall" centos_dnf_install

#######################################################################

info_failure_message="dnf info check failed on jenkins package"

centos_dnf_info_check() {
    dnf info jenkins | grep 'Jenkins is an open source automation server' || echo $info_failure_message
}

juLog -error=dnf.info.check.failed.on.jenkins.package -suite="${OS}.install" -name="DockerInfoCheck" centos_dnf_info_check

#######################################################################

signing_check_failure_message="rpm signing check failed on jenkins package"

centos_rpm_signing_check() {
    rpm --checksig $JENKINS_FEDORA_INSTALLER_FILE || echo $signing_check_failure_message
}

juLog -error=rpm.signing.check.failed.on.jenkins.package -suite="${OS}.install" -name="DockerSigningCheck" centos_rpm_signing_check
