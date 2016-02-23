#!/bin/bash

set -x  # Exit on any command failure

. `dirname $0`/sh2ju.sh
# Assume packaging is mounted to /tmp/packaging and built

if [ -z "$1" ]; then
  PKG_FOLDER='/tmp/packaging/target/suse/*.rpm'
else 
  PKG_FOLDER="$1"
fi

dockerInstall() {
    # Ignore signature verification and default to yes
    zypper --non-interactive in curl
    zypper --no-gpg-checks --non-interactive in $PKG_FOLDER
}

juLog -name=suseDockerInstall dockerInstall
