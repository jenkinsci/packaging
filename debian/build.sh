#!/bin/bash -ex
#
# build a debian package from a release build

dir=$(dirname $0)

cat << EOF
${ARTIFACTNAME} ($VERSION) unstable; urgency=low

  * Packaged ${VERSION}

 -- Kohsuke Kawaguchi <kk@kohsuke.org>  $(date -R)

EOF > debian/changelog

# build the debian package
sudo apt-get install -y devscripts || true

cp "${WAR}" ${ARTIFACTNAME}.war
pwd
# pick up debian package refactoring by looking for changes in 4a599d1de36e79cad296ef740a5c7f06db535b9f
if [ -f debian/jenkins.dirs ]; then
    debuild -us -uc -A
else
    debuild -us -uc -B
fi
# this creates ../jenkins_${VERSION}_all.deb

