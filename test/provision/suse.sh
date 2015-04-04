#!/bin/bash -ex
/vagrant/provision/generated/common.sh

zypper addrepo @@SUSE_URL@@ @@ARTIFACTNAME@@
zypper --gpg-auto-import-keys refresh
zypper install -y @@ARTIFACTNAME@@

systemctl start @@ARTIFACTNAME@@