# Docker build environment for Jenkins packaging

This offers a simplified build environment for testing packaging

## The sudo containers ##
* These images supply sudo access to enable installation tests (which require root or sudo) with the Jenkins docker-workflow plugin.  They use an ARG to add the current user as a sudoer.
* These **MUST** be built by the build-sudo-images.sh script before use in docker workflow
* The script reads the local user ID, creates a 'mysudoer' user with sudo access in these containers with no-password sudo
* For CentOS images, the sudoer requiretty option is turned off to allow-non-terminal use
* For specific environments additional requirements for services may be added (example: initscripts for CentOS7, since service support is not baked in)
* An added perk of these is that they install the default JDK for faster testing
