# refers to the definition of a release target
TARGET:=./def/jenkins-rc.mk
include ${TARGET}

# refers to the definition of the release process execution environment
BUILDENV:=./env/kohsuke.mk
include ${BUILDENV}

include ./setup.mk

msi: ${MSI}

test:
	@echo RPM_WEBDIR=${RPM_WEBDIR}
	@echo VERSION=${VERSION}

MSI_ENCODED_VERSION=$(shell ./msi/encode-version.rb ${VERSION})

cli: ${BUILD}/jenkins-cli.jar

${BUILD}/jenkins-cli.jar:
	wget -o $@ ${JENKINS_URL}jnlpJars/jenkins-cli.jar

${MSI}: ${WAR}
	./msi/build-on-jenkins.sh
