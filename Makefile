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

publish: war.publish msi.publish osx.publish deb.publish rpm.publish suse.publish

test: deb.test rpm.test suse.test


war: ${WAR}
war.publish: ${WAR}
	ssh ${PKGSERVER} mkdir -p ${WARDIR}/${VERSION}/
	rsync -avz "${WAR}" ${PKGSERVER}:${WARDIR}/${VERSION}/${ARTIFACTNAME}.war



msi: ${MSI}
${MSI}: ${WAR} ${CLI} $(shell find msi -type f)
	./msi/build-on-jenkins.sh
msi.publish: ${MSI}
	./msi/publish.sh



osx: ${OSX}
${OSX}: ${WAR} ${CLI}  $(shell find osx -type f | sed -e 's/ /\\ /g')
	./osx/build-on-jenkins.sh
osx.publish: ${OSX}
	./osx/publish.sh



deb: ${DEB}
${DEB}: ${WAR} $(shell find deb/build -type f)
	./deb/build/build.sh
deb.publish: ${DEB} $(shell find deb/publish -type f)
	./deb/publish/publish.sh



rpm: ${RPM}
${RPM}: ${WAR}  $(shell find rpm/build -type f)
	./rpm/build/build.sh
rpm.publish: ${RPM} $(shell find rpm/publish -type f)
	./rpm/publish/publish.sh

suse: ${SUSE}
${SUSE}: ${WAR}  $(shell find suse/build -type f)
	./suse/build/build.sh
suse.publish: ${SUSE} $(shell find suse/publish -type f)
	./suse/publish/publish.sh



${CLI}:
	@mkdir ${TARGET} || true
	wget -O $@ ${JENKINS_URL}jnlpJars/jenkins-cli.jar



test.local.setup:
	# start a test Apache server that acts as package server
	# we'll refer to this as 'test.pkg.jenkins-ci.org'
	@mkdir -p ${TESTDIR} || true
	docker run --rm -t -i -p 9200:80 -v ${TESTDIR}:/var/www/html fedora/apache
%.test.prepare:
    # run this target for to set up the test target VM
	cd test; vagrant up --provision-with shell $*; sleep 5
%.test.run:
    # run this target to just re-run the test against the currently running VM
	cd test; vagrant provision --provision-with serverspec $*
%.test.shutdown:
    # run tis target to undo '%.test.prepare'
	cd test; vagrant destroy -f $*
%.test: %.test.prepare %.test.run %.test.shutdown
