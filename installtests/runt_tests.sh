#!/bin/bash

PACKAGING_DIR="/Users/svanoort/Documents/packaging-2/packaging"
docker run --rm -v $PACKAGING_DIR:/tmp/packaging debian:wheezy /bin/bash /tmp/packaging/installtests/debian.sh
docker run --rm -v $PACKAGING_DIR:/tmp/packaging centos:7 /bin/bash /tmp/packaging/installtests/centos.sh
docker run --rm -v $PACKAGING_DIR:/tmp/packaging centos:6 /bin/bash /tmp/packaging/installtests/centos.sh

#TODO SuSe test
#docker run --rm -v $PACKAGING_DIR:/tmp/packaging centos:6 /bin/bash /tmp/packaging/installtests/centos.sh
