#!/bin/bash -eux

# build a debian package from a release build

hostname
dir=$(dirname "$0")

# tmp dir
D=$(mktemp -d)
trap 'rm -rf "${D}"' EXIT

# debian packaging needs to touch the file in the source tree, so do this in tmp dir
# so that multiple builds can go on concurrently
cp -R "${dir}"/* "${D}"
cp "${BASE}/systemd/jenkins.service" "${D}/debian"
cp "${BASE}/systemd/jenkins.sh" "${D}"

# Create a description temp file
sed -i.bak -e 's/^\s*$/./' -e 's/^/ /' "${DESCRIPTION_FILE}"

# Expand variables in the definition
"${BASE}/bin/branding.py" "${D}/debian"

# Rewrite the file
mv "${DESCRIPTION_FILE}.bak" "${DESCRIPTION_FILE}"

cat >"${D}/debian/changelog" <<EOF
${ARTIFACTNAME} (${VERSION}) unstable; urgency=low

  * Packaged ${VERSION} https://jenkins.io/changelog${RELEASELINE}/#v${VERSION}

 -- ${AUTHOR}  $(date -R)

EOF

# build the debian package
cp "${WAR}" "${D}/${ARTIFACTNAME}.war"
pushd "${D}"
pushd debian
# rename jenkins.* to artifact.*
for f in jenkins.*; do
	mv "${f}" "${f}_"
	mv "${f}_" "${ARTIFACTNAME}$(echo "${f}" | cut -b8-)"
done
popd
mv jenkins.sh "${ARTIFACTNAME}"
debuild -Zgzip -A
popd

mkdir -p "$(dirname "${DEB}")"
mv "${D}/../${ARTIFACTNAME}_${VERSION}_all.deb" "${DEB}"

exit 0
