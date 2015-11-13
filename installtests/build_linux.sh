#!/bin/bash
# TODO handle root folder

docker run -it --rm -v `pwd`:/tmp/packaging jenkins-packaging-builder:0.1 /bin/bash 

# Pipe into docker
cd /tmp/packaging && make rpm suse deb BRAND=./branding/jenkins.mk BUILDENV=./env/test.mk CREDENTIAL=./credentials/test.mk WAR=jenkins.war