# refers to the definition of a release target
TARGET=./def/jenkins-rc.mk
include ${TARGET}

# refers to the definition of the release process execution environment
BUILDENV=./env/kohsuke.mk
include ${BUILDENV}



test:
	echo ${RPM_WEBDIR}
	/tmp/echo.sh