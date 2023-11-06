#!/bin/bash -eux

# prepare fresh directories
D=$(mktemp -d)
trap 'rm -rf "${D}"' EXIT

cp -R "$(dirname "$0")"/* "${D}"
cp "${BASE}/systemd/jenkins.service" "${D}/SOURCES"
cp "${BASE}/systemd/jenkins.sh" "${D}/SOURCES"
cp "${BASE}/systemd/migrate.sh" "${D}/SOURCES"
cp "${BASE}/systemd/jenkins.conf" "${D}/SOURCES"
"${BASE}/bin/branding.py" "${D}"

cp "${WAR}" "${D}/SOURCES/jenkins.war"

pushd "${D}"
mkdir -p BUILD RPMS SRPMS
rpmbuild -ba --define="_topdir ${PWD}" --define="_tmppath ${PWD}/tmp" --define="ver ${VERSION}" SPECS/jenkins.spec

# sign the results
find RPMS -type f -name '*.rpm' -exec rpmsign --addsign '{}' \;
find RPMS -type f -name '*.rpm' -exec rpm -qpi '{}' \;
popd

mkdir -p "$(dirname "${RPM}")"
mv "${D}"/RPMS/noarch/*.rpm "${RPM}"

exit 0
