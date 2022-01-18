#!/bin/bash

set -e

# prepare fresh directories
D=$(mktemp -d)
trap 'rm -rf "$D"' EXIT

# HACK: needs to go in https://github.com/jenkins-infra/docker-packaging/blob/main/Dockerfile if this works
apt update && apt -y install mock

cp -R "$(dirname "$0")"/* $D
"$BASE/bin/branding.py" $D

cp "$WAR" $D/SOURCES/jenkins.war

pushd $D
  mkdir -p BUILD RPMS SRPMS
  rpmbuild -bs --define="_topdir $PWD" --define="_tmppath $PWD/tmp" --define="ver $VERSION" SPECS/jenkins.spec
  mock --define="ver $VERSION" --resultdir=RPMS --root=epel-7-x86_64 SRPMS/*.rpm

  # sign the results
  for rpm in $(find RPMS -name '*.rpm'); do
    rpmsign --addsign "${rpm}"
    rpm -qpi "${rpm}"
  done
popd

mkdir -p "$(dirname "${RPM}")" || true
mv $D/RPMS/*.noarch*.rpm "${RPM}"
