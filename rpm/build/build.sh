#!/bin/bash

set -e

# prepare fresh directories
D=$(mktemp -d)
trap 'rm -rf "$D"' EXIT

cp -R "$(dirname "$0")"/* $D
"$BASE/bin/branding.py" $D

cp "$WAR" $D/SOURCES/jenkins.war

pushd $D
mkdir -p BUILD RPMS SRPMS
rpmbuild -ba --define="_topdir $PWD" --define="_tmppath $PWD/tmp" --define="ver $VERSION" SPECS/jenkins.spec

# sign the results
for rpm in $(find RPMS -name '*.rpm'); do
	rpmsign --addsign "${rpm}"
	rpm -qpi "${rpm}"
done
popd

mkdir -p "$(dirname "${RPM}")" || true
mv $D/RPMS/noarch/*.rpm "${RPM}"
