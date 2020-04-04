# refers to the definition of a release target
BRAND ?= ./branding/test.mk
include ${BRAND}

# refers to the definition of the release process execution environment
BUILDENV ?=./env/test.mk
include ${BUILDENV}

# refers to whereabouts of code-signing keys
# CREDENTIAL ?=./credentials/test.mk

include ${CREDENTIAL}

include ./setup.mk

PACKAGE_BUILDER_VERSION:=0.3

#######################################################

clean:
	rm -rf ${TARGET} results

setup:
	bash -ex -c 'for f in */setup.sh; do $$f; done'

package: war deb rpm suse osx

publish: war.publish deb.publish rpm.publish suse.publish osx.publish

test: deb.test rpm.test suse.test

docker.images:
	docker build -t jenkins-packaging-builder:${PACKAGE_BUILDER_VERSION} ./docker
	bash ./docker/build-sudo-images.sh

# See ./docker/README.md for how to use the docker containers to run a build in docker

docker.test: docker.images
	bash ./installtests/run_tests.sh

war: ${WAR}
war.publish: ${WAR}
	mkdir -p "${WARDIR}/${VERSION}/"
	mkdir -p "${WAR_WEBDIR}"
	sha256sum ${WAR} | sed 's, .*, ${ARTIFACTNAME}.war,' > ${WAR_SHASUM}
	cat ${WAR_SHASUM}
	rsync -avz "${WAR}" "${WARDIR}/${VERSION}/${ARTIFACTNAME}.war"
	rsync -avz "${WAR_SHASUM}" "${WARDIR}/${VERSION}/"
	./bin/indexGenerator.py \
		--distribution war \
		--binaryDir "${WARDIR}" \
		--targetDir "${WAR_WEBDIR}"




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

msi: ${MSI}
msi.publish: ${MSI}
	mkdir -p "${MSIDIR}/${VERSION}/"
	mkdir -p "${MSI_WEBDIR}"
	sha256sum ${MSI} | sed 's, .*, ${ARTIFACTNAME}.msi,' > ${MSI_SHASUM}
	cat ${MSI_SHASUM}
	rsync -avz "${MSI}" "${MSIDIR}/${VERSION}/${ARTIFACTNAME}.msi"
	rsync -avz "${MSI_SHASUM}" "${MSIDIR}/${VERSION}/"
	./bin/indexGenerator.py \
		--distribution windows \
		--binaryDir "${MSIDIR}" \
		--targetDir "${WAR_WEBDIR}"

${CLI}:
	@mkdir ${TARGET} || true
	wget -O $@.tmp ${JENKINS_URL}jnlpJars/jenkins-cli.jar
	mv $@.tmp $@



test.local.setup:
	# start a test Apache server that acts as package server
	# we'll refer to this as 'test.pkg.jenkins.io'
	@mkdir -p ${TESTDIR} || true
	docker run --rm -t -i -p 9200:80 -v ${TESTDIR}:/var/www/html fedora/apache
%.test.up:
	# run this target for to set up the test target VM
	cd test; vagrant up --provision-with "" $*
	cd test; vagrant provision --provision-with "shell" $*; sleep 5
%.test.run:
	# run this target to just re-run the test against the currently running VM
	cd test; vagrant provision --provision-with serverspec $*
%.test.destroy:
	# run tis target to undo '%.test.up'
	cd test; vagrant destroy -f $*
%.test: %.test.up %.test.run %.test.destroy
	# run all the test goals in the order
