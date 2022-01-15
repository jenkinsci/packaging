#!/bin/bash -eux
set -o pipefail
cd "$(dirname "$0")"

./prep.sh
make war deb rpm suse

# produces: target/debian/jenkins_${JENKINS_VERSION}_all.deb,target/rpm/jenkins-${JENKINS_VERSION}-1.1.noarch.rpm,target/suse/jenkins-${JENKINS_VERSION}-1.2.noarch.rpm
exit 0
