#!/bin/bash
set -x  # Exit on any command failure or unset variables, can't use -u because of line 6

if [ -z "$1" ]; then
  PKG_FOLDER=$(ls /tmp/packaging/target/rpm/*.rpm)
  # Change to /tmp/packaging so that results are written in /tmp/packaging/results
  cd /tmp/packaging
else
  PKG_FOLDER="$1"
fi

. "$(dirname $0)/sh2ju.sh"

install_failure_message="yum install command failed on $PKG_FOLDER"

centos_docker_install() {
    # Tests need the curl command
    # Docker image does not include the service command
    # Tests need the yum-verify command
    yum install -y curl system-config-services yum-verify # docker does not include service command
    # Assumes rpm file is available as $PKG_FOLDER
    yum -y localinstall "$PKG_FOLDER" || echo "$install_failure_message"
}

juLog -error="$install_failure_message" -name=centosDockerInstall centos_docker_install
