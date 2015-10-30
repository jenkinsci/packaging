#!/bin/bash
set -e  # Exit on any command failure

# Installation within Docker
# Assume packaging is mounted to /tmp/packaging and built
apt-get update 
dpkg -i /tmp/packaging/target/debian/*.deb
apt-get install -fy
dpkg -i /tmp/packaging/target/debian/*.deb

# Check that service will stop and start correctly, and handles failure to stop/start
bash service-check.sh