#!/bin/bash
set -x  # Exit on any command failure, can't use -u because of line 6

. "$(dirname $0)/sh2ju.sh"

if [ -z "$1" ]; then
  PKG_FOLDER=$(ls /tmp/packaging/target/debian/*.deb)
else 
  PKG_FOLDER="$1"
fi

dockerInstall() {
    # Installation within Docker
    # Assume packaging is mounted to /tmp/packaging and built
    apt-get update
    # Below will fail because missing dependencies, which apt-get will install
    dpkg -i "$PKG_FOLDER" || true
    apt-get install -fy && apt-get install -fy curl
    dpkg -i "$PKG_FOLDER"
}

juLog -name=debianDockerInstall dockerInstall
