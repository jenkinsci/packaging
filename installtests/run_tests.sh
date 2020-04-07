#!/bin/bash
set -ux  # Exit on any command failure or unset variables.


# Get a path to use for absolute docker path to container
PACKAGING_DIR=$(dirname $(dirname "$0"))

# Platform independence: on mac, use readlink -f to get the absolute path
if [ `which realpath` ]; then 
    PACKAGING_DIR=$(realpath "$PACKAGING_DIR")
else
    PACKAGING_DIR=$(readlink -f "$PACKAGING_DIR")
fi

echo "Packaging directory is: $PACKAGING_DIR"
docker run --rm -v "$PACKAGING_DIR":/tmp/packaging sudo-centos:7         /bin/bash /tmp/packaging/installtests/test_helper.sh /tmp/packaging/installtests/centos.sh
docker run --rm -v "$PACKAGING_DIR":/tmp/packaging sudo-debian:oldstable /bin/bash /tmp/packaging/installtests/test_helper.sh /tmp/packaging/installtests/debian.sh /tmp/packaging/installtests/service-check.sh
docker run --rm -v "$PACKAGING_DIR":/tmp/packaging sudo-debian:stable    /bin/bash /tmp/packaging/installtests/test_helper.sh /tmp/packaging/installtests/debian.sh /tmp/packaging/installtests/service-check.sh
docker run --rm -v "$PACKAGING_DIR":/tmp/packaging sudo-debian:testing   /bin/bash /tmp/packaging/installtests/test_helper.sh /tmp/packaging/installtests/debian.sh /tmp/packaging/installtests/service-check.sh
docker run --rm -v "$PACKAGING_DIR":/tmp/packaging sudo-opensuse:15.1    /bin/bash /tmp/packaging/installtests/test_helper.sh /tmp/packaging/installtests/suse.sh
docker run --rm -v "$PACKAGING_DIR":/tmp/packaging sudo-ubuntu:16.04     /bin/bash /tmp/packaging/installtests/test_helper.sh /tmp/packaging/installtests/debian.sh /tmp/packaging/installtests/service-check.sh
docker run --rm -v "$PACKAGING_DIR":/tmp/packaging sudo-ubuntu:18.04     /bin/bash /tmp/packaging/installtests/test_helper.sh /tmp/packaging/installtests/debian.sh /tmp/packaging/installtests/service-check.sh
docker run --rm -v "$PACKAGING_DIR":/tmp/packaging sudo-ubuntu:19.10     /bin/bash /tmp/packaging/installtests/test_helper.sh /tmp/packaging/installtests/debian.sh /tmp/packaging/installtests/service-check.sh
