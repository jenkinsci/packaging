# refers to the definition of a release target
TARGET:=./def/jenkins-rc.mk
include ${TARGET}

# refers to the definition of the release process execution environment
BUILDENV:=./env/kohsuke.mk
include ${BUILDENV}

include ./setup.mk

#######################################################

clean:
	rm -rf ${BUILD}

setup:
	bash -ex -c 'for f in */setup.sh; do $$f; done'

msi: ${MSI}
${MSI}: ${WAR} cli
	./msi/build-on-jenkins.sh
msi.deploy: ${MSI}
	./msi/deploy.sh



osx: ${OSX}
${OSX}: ${WAR} cli
	./osx/build-on-jenkins.sh
osx.deploy: ${OSX}
	./osx/deploy.sh



deb: ${DEB}
${DEB}: ${WAR}
	./debian/build/build.sh
deb.deploy: ${DEB}
	./debian/deploy/deploy.sh



cli: ${BUILD}/jenkins-cli.jar
${BUILD}/jenkins-cli.jar:
	@mkdir ${BUILD} || true
	wget -O $@ ${JENKINS_URL}jnlpJars/jenkins-cli.jar
