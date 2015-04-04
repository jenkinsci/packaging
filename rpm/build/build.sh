#!/bin/bash -e

# prepare fresh directories
D=/tmp/$$
mkdir $D

cp -R "$(dirname "$0")"/* $D
$BASE/bin/branding.sh $D

cp "$WAR" $D/SOURCES/jenkins.war

pushd $D
  mkdir -p BUILD RPMS SRPMS
  rpmbuild -ba --define="_topdir $PWD" --define="_tmppath $PWD/tmp" --define="ver $VERSION" SPECS/jenkins.spec

  # sign the results
  for rpm in $(find RPMS -name '*.rpm'); do
    $BASE/bin/rpm-sign $(cat $GPG_PASSPHRASE_FILE) $rpm
  done
popd

mkdir "$(dirname "${RPM}")" || true
mv $D/RPMS/noarch/*.rpm ${RPM}

rm -rf $D