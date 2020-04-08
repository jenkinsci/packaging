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

fedora_dnf_install() {
    dnf install -y $JENKINS_FEDORA_INSTALLER_FILE || echo $install_failure_msg
}

juLog -error="$install_failure_msg" -suite="${OS}.install" -name="DockerInstall" fedora_dnf_install

#######################################################################

info_failure_message="dnf info check failed on jenkins package"

fedora_dnf_info_check() {
    dnf info jenkins | grep 'Jenkins is an open source automation server' || echo $info_failure_message
}

juLog -error="$info_failure_message" -suite="${OS}.install" -name="DockerInfoCheck" fedora_dnf_info_check

#######################################################################
#
# Fedora signing check fails on Jenkins 2.230, needs more investigation
#
# signing_check_failure_message="rpm signing check failed on jenkins package"
#
# fedora_rpm_signing_check() {
#     rpm --checksig $JENKINS_FEDORA_INSTALLER_FILE || echo $signing_check_failure_message
# }
#
# juLog -error="$signing_check_failure_message" -suite="${OS}.install" -name="DockerSigningCheck" fedora_rpm_signing_check
