#!/bin/bash

set -x  # Exit on any command failure, can't use -u because of check for non-zero length of arg 1

if [ -z "$1" ]; then
  JENKINS_SUSE_INSTALLER_FILE=$(ls /tmp/packaging/target/suse/*.rpm)
  # Change to /tmp/packaging so that results are written in /tmp/packaging/results
  cd /tmp/packaging
else
  JENKINS_SUSE_INSTALLER_FILE="$1"
fi

. "$(dirname $0)/sh2ju.sh"

# Read operating system information into variables

. /etc/os-release

OS="${ID}.${VERSION_ID}" # opensuse-leap.15.1 so that JUnit package naming can be used

install_failure_msg="zypper install failed on $JENKINS_SUSE_INSTALLER_FILE"

suse_zypper_install() {
    # Ignore signature verification - OpenSUSE Jenkins 2.229 package is not GPG signed (why not?)
    zypper --no-gpg-checks --non-interactive install insserv-compat $JENKINS_SUSE_INSTALLER_FILE || echo "$install_failure_msg"
}

juLog -error="$install_failure_msg" -suite="${OS}.install" -name="DockerInstall" suse_zypper_install

verify_failure_message="zypper packages check failed on jenkins package"

suse_zypper_package_check() {
    zypper --no-gpg-checks --non-interactive packages --installed-only | grep ^i.*jenkins || echo $verify_failure_message
}

juLog -error="$verify_failure_msg" -suite="${OS}.install" -name="DockerPackageCheck" suse_zypper_package_check
