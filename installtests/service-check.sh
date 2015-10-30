#!/bin/bash
# Verify that service correctly handles starting and stopping process
set -e  # Exit on any command failure



service jenkins start
sleep 5
service jenkins status

service jenkins restart
sleep 5
service jenkins status
# TODO assert passed

# TODO check if jenkins user is present
service jenkins stop
sleep 5
service jenkins status

# Break it and NOW try it
mv /usr/share/jenkins/jenkins.war /usr/share/jenkins/jenkins-broken.war
