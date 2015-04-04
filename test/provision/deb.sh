#!/bin/bash -ex
/vagrant/provision/generated/common.sh

wget -q -O - @@DEB_URL@@/jenkins-ci.org.key | apt-key add -
echo "deb @@DEB_URL@@ binary/" > /etc/apt/sources.list.d/@@ARTIFACTNAME@@.list

apt-get update -y
apt-get install -y @@ARTIFACTNAME@@