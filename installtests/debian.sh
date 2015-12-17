#!/bin/bash
set -ex  # Exit on any command failure

if [ -z "$1" ]; then
  PKG_FOLDER='/tmp/packaging/target/debian/*.deb'
else 
  PKG_FOLDER="$1"
fi

# Installation within Docker
# Assume packaging is mounted to /tmp/packaging and built
apt-get update
# Below will fail because missing dependencies, which apt-get will install
dpkg -i "$PKG_FOLDER" || true
apt-get install -fy && apt-get install -fy curl
dpkg -i "$PKG_FOLDER"