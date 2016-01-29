#!/bin/bash -ex
/vagrant/provision/generated/common.sh

wget -q -O - @@DEB_URL@@/@@ORGANIZATION@@.key | apt-key add -
echo "deb @@DEB_URL@@ binary/" > /etc/apt/sources.list.d/@@ARTIFACTNAME@@.list

apt-get update -y
apt-get install -y @@ARTIFACTNAME@@