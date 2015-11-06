#!/bin/bash

# Tests basic jenkins install & service behavior but not package dependencies
# This is intended for cases where time or bandwidth are tight

PACKAGING_DIR="/Users/svanoort/Documents/packaging-2/packaging"
docker run --rm -v $PACKAGING_DIR:/tmp/packaging fast-debian:wheezy /bin/bash /tmp/packaging/installtests/debian.sh && /tmp/packaging/installtests/service-check.sh
docker run --rm -v $PACKAGING_DIR:/tmp/packaging fast-centos:7 /bin/bash /tmp/packaging/installtests/centos.sh && /tmp/packaging/installtests/service-check.sh
docker run --rm -v $PACKAGING_DIR:/tmp/packaging fast-centos:6 /bin/bash /tmp/packaging/installtests/centos.sh && /tmp/packaging/installtests/service-check.sh

docker run --rm -v $PACKAGING_DIR:/tmp/packaging fast-opensuse:13.2 /bin/bash /tmp/packaging/installtests/suse.sh && /tmp/packaging/installtests/service-check.sh