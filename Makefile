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

cli: ${BUILD}/jenkins-cli.jar

${BUILD}/jenkins-cli.jar:
	@mkdir ${BUILD} || true
	wget -O $@ ${JENKINS_URL}jnlpJars/jenkins-cli.jar

${MSI}: ${WAR} cli
	./msi/build-on-jenkins.sh

msi.deploy: ${MSI}
	./msi/deploy.sh
