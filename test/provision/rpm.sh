#!/bin/bash -ex
/vagrant/provision/generated/common.sh

wget -q -O /etc/yum.repos.d/@@ARTIFACTNAME@@.repo @@RPM_URL@@/@@ARTIFACTNAME@@.repo
rpm --import @@RPM_URL@@/@@ORGANIZATION@@.key

yum check-update || true
#TODO Java baseline is not fixed
yum -y install java @@ARTIFACTNAME@@

systemctl start @@ARTIFACTNAME@@
