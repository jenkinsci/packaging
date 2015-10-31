#!/bin/bash
set -e  # Exit on any command failure

# Assume packaging is mounted to /tmp/packaging and built
yum install -y curl
yum install -y system-config-services java-1.7.0-openjdk  # First is b/c docker does not include service command, second is prereq
yum -y --nogpgcheck localinstall /tmp/packaging/target/rpm/*.rpm

service jenkins start
service jenkins status
curl http://localhost:8080