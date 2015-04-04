#!/bin/bash -ex

# get the IP address of the host of VirtualBox, and make it visible in expected name
addr=$(netstat -rn | grep ^0.0.0.0 | cut -d " " -f10)
host=$(echo @@RPM_URL@@ | tr '/' ':' | cut -d ':' -f4)
echo $addr $host | tee -a /etc/hosts > /dev/null

wget -q -O /etc/yum.repos.d/jenkins.repo @@RPM_URL@@/@@ARTIFACTNAME@@.repo
rpm --import @@RPM_URL@@/jenkins-ci.org.key

yum -y install @@ARTIFACTNAME@@

systemctl start @@ARTIFACTNAME@@