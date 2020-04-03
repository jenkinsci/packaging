#!/bin/bash
set -x  # Exit on any command failure, can't use -u because of check for non-zero length of arg 1

if [ -z "$1" ]; then
  JENKINS_DEB_INSTALLER_FILE=$(ls /tmp/packaging/target/debian/*.deb)
  # Change to /tmp/packaging so that results are written in /tmp/packaging/results
  cd /tmp/packaging
else
  JENKINS_DEB_INSTALLER_FILE="$1"
fi

# Configure dpkg to be less noisy
export DEBIAN_FRONTEND=noninteractive

. "$(dirname $0)/sh2ju.sh"

install_failure_message="dpkg install failed on $JENKINS_DEB_INSTALLER_FILE file"

docker_dpkg_install() {
    # Installation within Docker
    # Update with latest list of available packages
    apt-get -q update

    # Assume packaging is already built and is available in $JENKINS_DEB_INSTALLER_FILE
    # Below will fail because missing dependencies, which apt-get will install
    echo
    echo "===== Installing $JENKINS_DEB_INSTALLER_FILE without dependencies"
    echo
    dpkg --install "$JENKINS_DEB_INSTALLER_FILE" || true

    # Install Jenkins package dependencies, then install curl while ignoring curl install output
    # Output should detect issues with Jenkins dependencies, curl is a tool needed later
    echo
    echo "===== Resolving dependencies of $JENKINS_DEB_INSTALLER_FILE with apt-get"
    echo
    apt-get -q install -fy && apt-get install -fy curl > /dev/null 2>&1

    # Remove jenkins installed by first call to dpkg
    echo
    echo "===== Removing flawed installation of $JENKINS_DEB_INSTALLER_FILE"
    echo
    dpkg --purge jenkins

    # Install Jenkins from the packaging directory
    echo
    echo "===== Installing $JENKINS_DEB_INSTALLER_FILE with dependencies already installed"
    echo
    dpkg --install "$JENKINS_DEB_INSTALLER_FILE" || echo "$install_failure_message"
}

juLog -error="$install_failure_message" -name=debianDockerInstall docker_dpkg_install

##
# Use dpkg verify to check package contents
##

verify_failure_message="dpkg verify failed on jenkins package"

docker_dpkg_verify() {
    # Use dpkg verify to check contents of the jenkins package
    echo
    echo "===== Verifying jenkins package with dpkg"
    echo
    dpkg --verify jenkins < /dev/null || echo "$verify_failure_message"
}

juLog -error="$verify_failure_message" -name=debianDockerVerify docker_dpkg_verify

##
# Use dpkg audit to check package contents
##

audit_failure_message="dpkg audit failed on jenkins package"

docker_dpkg_audit() {
    echo
    echo "===== Auditing jenkins package with dpkg"
    echo
    dpkg --audit jenkins < /dev/null || echo "$audit_failure_message"
}

juLog -error="$audit_failure_message" -name=debianDockerAudit docker_dpkg_audit
