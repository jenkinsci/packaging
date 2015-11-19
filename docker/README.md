# Docker build environment for Jenkins packaging

This offers a simplified build environment for testing packaging

To build the image:
`docker build -t jenkins-packaging-builder:0.1 .`

## To use it: ##
* Use with Jenkins as a build environment with WAR + packaging mounted in
* OR: copy the war into your packaging folder and mount it as a volume
  - Within the packaging folder: `docker run -it --rm -v "\`pwd\`":/tmp/packaging -w /tmp/packaging jenkins-packaging-builder:0.1 /bin/bash`
  - Within the container: `cd /tmp/packaging`
  - Set up (shouldn't be needed, but why not): `WAR="jenkins.war" make setup`
  - Make your magic package: `make deb BRAND=./branding/jenkins.mk BUILDENV=./env/test.mk CREDENTIAL=./credentials/test.mk WAR=jenkins.war`
  - Yes, it will work with "make rpm..."  or "make suse..."

## The sudo containers ##
* These images are supply sudo access to enable installation tests (which require root or sudo) with the Jenkins docker-workflow plugin 
* These **MUST** be built by the build-sudo-images.sh script before use in docker workflow
* The script reads the local user ID, creates a 'mysudoer' user with sudo access in these containers with no-password sudo
* For CentOS images, the sudoer requiretty option is turned off to allow-non-terminal use
* For specific environments additional requirements for services may be added (example: initscripts for CentOS7, since service support is not baked in)
* An added perk of these is that the debian-based ones update the apt database to save time on future installs