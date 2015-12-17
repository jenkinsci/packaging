# Dockerized testing of package behavior

This lets you test that linux packages work correctly, by doing a full installation inside Docker containers across a range of different distros and versions and then verifying Jenkins behavior.

They are usable BOTH for integration into Jenkins CI via docker-workflow!

# Great, how do I use it?
You need docker installed. 

For convenience, it is helpful to add your current user to the docker group, so scripts can be run without sudo/root access: 


```shell
sudo usermod -a -G docker ${USER}
```

Next, build the custom sudo images for testing.  This must be done under the user you intend to use in testing (if you're doing this in CI, this should be done within jenkins). 

Note: these use templating on the Dockerfiles to supply the local user, so the Dockerfile will be modified.

```shell
bash ./docker/build-sudo-images.sh
```

These images include sudo + packages that are normally part of the OS distribution but may be missing in the base images.  (see the docker subfolder README).

Next, run the tests:
bash ./run_tests.sh


## Installation Scripts

We have installation scripts for the core distro types (RPM, Debian pkg, SUSE RPM, which will create a working Jenkins with JDKs, etc + curl for testing.  THESE MUST RUN AS ROOT OR IN SUDO MODE in the container (the sudo images above achieve this).

Usage:

* sudo centos.sh /path/to/rpm/package.rpm
* sudo suse.sh /path/to/suse/package.rpm
* sudo debian.sh /path/to/debian/package.deb

## Validation Scripts

Validation currently is a multipstep process, and ALSO requires root/sudo since you are starting/stopping services. It also depends on curl for validating the ability to handle requests.

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

Or, for example jenkins-super if that is the artifact + service packaged ARTIFACTNAME, if omitted it will default to 'jenkins'.
The second argument is the port number that jenkins runs on by default, if omitted it will default to 8080.