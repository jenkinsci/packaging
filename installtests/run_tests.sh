#!/bin/bash

PACKAGING_DIR="/Users/svanoort/Documents/packaging-2/packaging"
docker run --rm -v "$PACKAGING_DIR":/tmp/packaging sudo-debian:wheezy /bin/bash /tmp/packaging/installtests/debian.sh && /tmp/packaging/installtests/service-check.sh
docker run --rm -v "$PACKAGING_DIR":/tmp/packaging sudo-centos:7 /bin/bash /tmp/packaging/installtests/centos.sh && /tmp/packaging/installtests/service-check.sh
docker run --rm -v "$PACKAGING_DIR":/tmp/packaging sudo-centos:6 /bin/bash /tmp/packaging/installtests/centos.sh && /tmp/packaging/installtests/service-check.sh

docker run --rm -v "$PACKAGING_DIR":/tmp/packaging sudo-opensuse:13.2 /bin/bash /tmp/packaging/installtests/suse.sh && /tmp/packaging/installtests/service-check.sh