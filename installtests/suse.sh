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

install_failure_message="zypper install failed on $JENKINS_SUSE_INSTALLER_FILE"

suse_zypper_install() {
    # Ignore signature verification and default to yes
    zypper --no-gpg-checks --non-interactive in $JENKINS_SUSE_INSTALLER_FILE || echo "$install_failure_message"
}

juLog -error="$JENKINS_SUSE_INSTALLER_FILE" -name=suseDockerInstall suse_zypper_install
