#!/bin/bash -ex
/vagrant/provision/generated/common.sh

wget -q -O /etc/yum.repos.d/jenkins.repo @@RPM_URL@@/@@ARTIFACTNAME@@.repo
rpm --import @@RPM_URL@@/jenkins-ci.org.key

yum -y install java @@ARTIFACTNAME@@

systemctl start @@ARTIFACTNAME@@