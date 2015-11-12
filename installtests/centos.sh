#!/bin/bash
set -e  # Exit on any command failure

if [ -z "$1" ]; then
  PKG_FOLDER='/tmp/packaging/target/rpm/*.rpm'
else 
  PKG_FOLDER="$1"
fi

# Assume packaging is mounted to /tmp/packaging and built
yum install -y curl
yum install -y system-config-services java-1.7.0-openjdk  # First is b/c docker does not include service command, second is prereq
yum -y --nogpgcheck localinstall "$PKG_FOLDER"