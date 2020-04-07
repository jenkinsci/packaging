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

# Debian testing does not set a VERSION_ID, /etc/os-release will replace for stable and oldstable

VERSION_ID=testing

# Read operating system information into variables

. /etc/os-release

OS="${ID}.${VERSION_ID}" # debian.10 or ubuntu.19.10 so that JUnit package naming can be used

install_failure_message="dpkg install failed on $JENKINS_DEB_INSTALLER_FILE file"

docker_dpkg_install() {
    # Assume packaging is already built and is available in $JENKINS_DEB_INSTALLER_FILE
    # Below will fail because missing dependencies, which apt-get will install
    echo
    echo "===== Installing $JENKINS_DEB_INSTALLER_FILE without dependencies"
    echo
    dpkg --install "$JENKINS_DEB_INSTALLER_FILE" || true

    # Install Jenkins package dependencies.
    # Output should detect issues with Jenkins dependencies
    echo
    echo "===== Resolving dependencies of $JENKINS_DEB_INSTALLER_FILE with apt-get"
    echo
    apt-get -q install -fy

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

juLog -error="$install_failure_message" -suite="${OS}.install" -name="DockerInstall" docker_dpkg_install

##
# Use dpkg verify to check package contents
##

verify_failure_message="dpkg verify failed on jenkins package"

docker_dpkg_verify() {
    if [[ $OS =~ ubuntu[.]1[89].* ]]; then
        # Hide the Ubuntu 18 and Ubuntu 19 deletion of changelog.gz
        # Unclear why those distributions delete changelog.gz, while
        # Ubuntu 16, Debian 9, Debian 10, and Debian testing do not.
        tmpdir=/tmp/$$
        dpkg-deb -x $JENKINS_DEB_INSTALLER_FILE $tmpdir
        if [ ! -f /usr/share/doc/jenkins/changelog.gz ]; then
            mv $tmpdir/usr/share/doc/jenkins/changelog.gz /usr/share/doc/jenkins/
        fi
        rm -rf $tmpdir
    fi
    # Use dpkg verify to check contents of the jenkins package
    echo
    echo "===== Verifying jenkins package with dpkg"
    echo
    dpkg --verify --verify-format=rpm jenkins < /dev/null || echo "$verify_failure_message ???"
}

# dpkg error messages with three consecutive question marks indicate a verification exception
juLog -error="[?][?][?]" -suite="${OS}.install" -name="DockerVerify" docker_dpkg_verify

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

juLog -error="$audit_failure_message" -suite="${OS}.install" -name="DockerAudit" docker_dpkg_audit
