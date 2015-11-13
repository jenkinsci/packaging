#!/bin/bash

set -e  # Exit on any command failure
# Assume packaging is mounted to /tmp/packaging and built

if [ -z "$1" ]; then
  PKG_FOLDER='/tmp/packaging/target/suse/*.rpm'
else 
  PKG_FOLDER="$1"
fi

# Ignore signature verification and default to yes
zypper --non-interactive in curl
zypper --no-gpg-checks --non-interactive in $PKG_FOLDER