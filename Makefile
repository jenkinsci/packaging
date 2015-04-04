# refers to the definition of a release target
BRAND:=./branding/test.mk
include ${BRAND}

# refers to the definition of the release process execution environment
BUILDENV:=./env/test.mk
include ${BUILDENV}

include ./setup.mk

#######################################################

clean:
	rm -rf ${TARGET}

setup:
	bash -ex -c 'for f in */setup.sh; do $$f; done'

package: war msi osx deb rpm suse

deploy: war.deploy msi.deploy osx.deploy deb.deploy rpm.deploy suse.deploy



war: ${WAR}
war.deploy: ${WAR}
	ssh ${PKGSERVER} mkdir -p ${WARDIR}/${VERSION}/
	rsync -avz "${WAR}" ${PKGSERVER}:${WARDIR}/${VERSION}/${ARTIFACTNAME}.war



msi: ${MSI}
${MSI}: ${WAR} ${CLI} $(shell find msi)
	./msi/build-on-jenkins.sh
msi.deploy: ${MSI}
	./msi/deploy.sh



osx: ${OSX}
${OSX}: ${WAR} ${CLI}  $(shell find osx)
	./osx/build-on-jenkins.sh
osx.deploy: ${OSX}
	./osx/deploy.sh



deb: ${DEB}
${DEB}: ${WAR} $(shell find debian/build)
	./debian/build/build.sh
deb.deploy: ${DEB} $(shell find debian/deploy)
	./debian/deploy/deploy.sh



rpm: ${RPM}
${RPM}: ${WAR}  $(shell find rpm/build)
	./rpm/build/build.sh
rpm.deploy: ${RPM} $(shell find rpm/deploy)
	./rpm/deploy/deploy.sh



suse: ${SUSE}
${SUSE}: ${WAR}  $(shell find suse/build)
	./suse/build/build.sh
suse.deploy: ${SUSE} $(shell find suse/deploy)
	./suse/deploy/deploy.sh



${CLI}:
	@mkdir ${TARGET} || true
	wget -O $@ ${JENKINS_URL}jnlpJars/jenkins-cli.jar
