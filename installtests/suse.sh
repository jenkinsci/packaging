#!/bin/bash

set -e  # Exit on any command failure
# Assume packaging is mounted to /tmp/packaging and built

# Ignore signature verification and default to yes
zypper --no-gpg-checks --non-interactive in /tmp/packaging/target/suse/*.rpm

yum install -y system-config-services java-1.7.0-openjdk  # First is b/c docker does not include service command, second is prereq
yum -y --nogpgcheck localinstall /tmp/packaging/target/suse/*.rpm
service jenkins start
service jenkins status

curl http://localhost:8080