#!/bin/bash
set -e  # Exit on any command failure

# Installation within Docker
# Assume packaging is mounted to /tmp/packaging and built
apt-get update
# Below will fail because missing dependencies, which apt-get will install
dpkg -i /tmp/packaging/target/debian/*.deb || true
apt-get install -fy && apt-get install -fy curl
dpkg -i /tmp/packaging/target/debian/*.deb