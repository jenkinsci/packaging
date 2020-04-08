#!/bin/bash
set -ux  # Exit on any command failure or unset variables.

# Get a path to use for absolute docker path to container
PKG_SRC_DIR=$(dirname $(dirname "$0"))

# Platform independence: on mac, use readlink -f to get the absolute path
if [ `which realpath` ]; then
    PKG_SRC_DIR=$(realpath "$PKG_SRC_DIR")
else
    PKG_SRC_DIR=$(readlink -f "$PKG_SRC_DIR")
fi

echo "Packaging directory is: $PKG_SRC_DIR"

PKG_TMP_DIR=/tmp/packaging
TEST_DIR=$PKG_TMP_DIR/installtests

TEST_INSTALL_CENTOS="/bin/bash $TEST_DIR/test_helper.sh $TEST_DIR/signing-checks.sh $TEST_DIR/centos.sh"
TEST_INSTALL_DEBIAN_AND_SERVICES="/bin/bash $TEST_DIR/test_helper.sh $TEST_DIR/signing-checks.sh $TEST_DIR/debian.sh $TEST_DIR/service-check.sh"
TEST_INSTALL_FEDORA="/bin/bash $TEST_DIR/test_helper.sh $TEST_DIR/signing-checks.sh $TEST_DIR/fedora.sh"
TEST_INSTALL_SUSE="/bin/bash $TEST_DIR/test_helper.sh $TEST_DIR/signing-checks.sh $TEST_DIR/suse.sh"

docker run --rm -v "$PKG_SRC_DIR":$PKG_TMP_DIR                        sudo-fedora:31        $TEST_INSTALL_FEDORA
docker run --rm -v "$PKG_SRC_DIR":$PKG_TMP_DIR                        sudo-centos:7         $TEST_INSTALL_CENTOS
docker run --rm -v "$PKG_SRC_DIR":$PKG_TMP_DIR                        sudo-debian:oldstable $TEST_INSTALL_DEBIAN_AND_SERVICES
docker run --rm -v "$PKG_SRC_DIR":$PKG_TMP_DIR --env CHECK_CERTS=true sudo-debian:stable    $TEST_INSTALL_DEBIAN_AND_SERVICES
docker run --rm -v "$PKG_SRC_DIR":$PKG_TMP_DIR                        sudo-debian:testing   $TEST_INSTALL_DEBIAN_AND_SERVICES
docker run --rm -v "$PKG_SRC_DIR":$PKG_TMP_DIR                        sudo-opensuse:15.1    $TEST_INSTALL_SUSE
docker run --rm -v "$PKG_SRC_DIR":$PKG_TMP_DIR                        sudo-ubuntu:16.04     $TEST_INSTALL_DEBIAN_AND_SERVICES
docker run --rm -v "$PKG_SRC_DIR":$PKG_TMP_DIR                        sudo-ubuntu:18.04     $TEST_INSTALL_DEBIAN_AND_SERVICES
docker run --rm -v "$PKG_SRC_DIR":$PKG_TMP_DIR                        sudo-ubuntu:19.10     $TEST_INSTALL_DEBIAN_AND_SERVICES
