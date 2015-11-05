#!/bin/bash
# Verify that service correctly handles starting and stopping process

#seconds to wait for service response
SERVICE_WAIT=2  


# Check if jenkins user is present
getent passwd jenkins
USER_TEST=$?
if [ $USER_TEST -ne 0 ]; then 
    echo "User jenkins not installed"
    exit 1
fi

# Capture standard error and exit code for service command
SERVICE_OUTPUT=$(service jenkins start 2>&1)
SERVICE_EXIT_CODE=$?

# TODO CHECK exit code and service output

sleep $SERVICE_WAIT
service jenkins status

service jenkins
sleep $SERVICE_WAIT
service jenkins status
# TODO assert passed#


# BREAK JENKINS AND NOW SEE IF IT HANDLES CORRECTLY
#service jenkins stop
#sleep $SERVICE_WAIT
#service jenkins status

# Break it and NOW try it
#mv /usr/share/jenkins/jenkins.war /usr/share/jenkins/jenkins-broken.war
