# Installation testing scripts

These are two-part, they can be run locally or in CI with docker-workflow

If running in docker-workflow with imageName.inside() { steps } then you will need the sudo containers to allow installation (see the docker folder README.md)

## Installation

We have installation scripts for the core distro types (RPM, Debian pkg, SUSE RPM, which will create a working Jenkins with JDKs, etc + curl.  THESE MUST RUN AS ROOT OR IN SUDO MODE (using the sudo docker images).

Usage:

* sudo centos.sh /path/to/rpm/package.rpm
* sudo suse.sh /path/to/suse/package.rpm
* sudo debian.sh /path/to/debian/package.deb

## Validation

Validation currently is a multipstep process, and ALSO requires root/sudo, in addition curl must be installed and working.

Currently validation covers:

1. Does jenkins start using the service
  - Verify the service start command runs without an error, and service status is good after
  - Verify jenkins responds to curl calls by HTTP
2. Does jenkins stop using the service
  - Check it will stop and service status indicates service is stopped
3. Can jenkins restart using the service
  - Same deal as startup
4. Do jenkins service commands indicate failure if jenkins can't start (by moving the WAR file)

**Usage:**
* sudo service-check.sh jenkins 8080 

Or, for example jenkins-oc if that is the artifact + service packaged ARTIFACTNAME, if omitted it will default to 'jenkins'.
The second argument is the port number that jenkins runs on by default, if omitted it will default to 8080.