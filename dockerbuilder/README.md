# Docker build environment for Jenkins packaging

This offers a simplified build environment for testing packaging

To build the image:
`docker build -t jenkins-packaging-builder:0.1 .`

## To use it: ##
* Use with Jenkins as a build environment with WAR + packaging mounted in
* OR: copy the war into your packaging folder and mount it as a volume
  - `docker run -it --rm -v $PACKAGING_FOLDER:/tmp/packaging jenkins-packaging-builder:0.1 /bin/bash`
  - Within the container, create a working copy: `cp -rf /tmp/packaging /tmp/packaging-working && cd /tmp/packaging-working`
  - Set up: `WAR="jenkins.war" make setup`
  - Make your magic package