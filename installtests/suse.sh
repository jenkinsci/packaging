#!/bin/bash

set -e  # Exit on any command failure
# Assume packaging is mounted to /tmp/packaging and built

# Ignore signature verification and default to yes
zypper --no-gpg-checks --non-interactive in /tmp/packaging/target/suse/*.rpm
#service jenkins start
#service jenkins status

#curl http://localhost:8080