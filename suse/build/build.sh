#!/bin/bash -e

# prepare fresh directories
D=/tmp/$$
mkdir $D

cp -R "$(dirname "$0")"/* $D
cp "$WAR" $D/SOURCES/jenkins.war
cat SOURCES/jenkins.repo.in | sed -e "s#@URL@#${SUSE_URL}/#g" > $D/SOURCES/jenkins.repo

pushd $D
  mkdir -p BUILD RPMS SRPMS
  rpmbuild -ba --define="_topdir $PWD" --define="_tmppath $PWD/tmp" --define="ver $VERSION" SPECS/jenkins.spec

  # sign the results
  for rpm in $(find RPMS -name '*.rpm'); do
    $BASE/bin/rpm-sign $(cat $GPG_PASSPHRASE_FILE) $rpm
  done
popd

mkdir "$(dirname "${SUSE}")" || true
mv $D/RPMS/noarch/*.rpm ${SUSE}

rm -rf $D