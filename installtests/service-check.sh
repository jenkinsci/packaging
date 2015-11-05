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

# Start service & capture standard error and exit code for service command
SERVICE_OUTPUT=$(service jenkins start 2>&1)
SERVICE_EXIT_CODE=$?

if [ $SERVICE_EXIT_CODE -ne 0]; then
    echo "Jenkins failed initial start with status code $SERVICE_EXIT_CODE"
    echo "Message follows"
    echo $SERVICE_OUTPUT
    exit 1
fi
sleep $SERVICE_WAIT

# Test that Jenkins is actually working... but doing a basic CurL call
CURL_OUTPUT=$(curl -sS 127.0.0.1:8080/jenkins 2>&1)
CURL_EXIT_CODE=$?
if [ $CURL_EXIT_CODE -ne 0]; then
    echo "Curl to jenkins host failed with code $CURL_EXIT_CODE"
    echo "Curl error follows"
    echo $CURL_OUTPUT
    exit 1
fi

# Check that jenkins status is correctly returned
SERVICE_OUTPUT=$(service jenkins status 2>&1)
SERVICE_EXIT_CODE=$?
if [ $SERVICE_EXIT_CODE -ne 0]; then
    echo "Jenkins inital start succeeded but status check failed with status code $SERVICE_EXIT_CODE"
    echo "Message follows"
    echo $SERVICE_OUTPUT
    exit 1
fi

# Check that jenkins restarts correctly
SERVICE_OUTPUT=$(service jenkins restart 2>&1)
SERVICE_EXIT_CODE=$?
if [ $SERVICE_EXIT_CODE -ne 0]; then
    echo "Jenkins first restart failed with exit code $SERVICE_EXIT_CODE"
    echo "Message follows"
    echo $SERVICE_OUTPUT
    exit 1
fi

sleep $SERVICE_WAIT

# Check that jenkins stops cleanly
SERVICE_OUTPUT=$(service jenkins stop 2>&1)
SERVICE_EXIT_CODE=$?
if [ $SERVICE_EXIT_CODE -ne 0]; then
    echo "Jenkins stop failed with exit code $SERVICE_EXIT_CODE"
    echo "Message follows"
    echo $SERVICE_OUTPUT
    exit 1
fi

sleep $SERVICE_WAIT

# Check that jenkins status returns correctly after stop
SERVICE_OUTPUT=$(service jenkins status 2>&1)
SERVICE_EXIT_CODE=$?
if [ $SERVICE_EXIT_CODE -ne 3]; then
    echo "Jenkins status check after stop failed with exit code $SERVICE_EXIT_CODE"
    echo "Message follows"
    echo $SERVICE_OUTPUT
    exit 1
fi

# Check that jenkins restarts correctly from stopped state
SERVICE_OUTPUT=$(service jenkins restart 2>&1)
SERVICE_EXIT_CODE=$?
if [ $SERVICE_EXIT_CODE -ne 0]; then
    echo "Jenkins first restart failed with exit code $SERVICE_EXIT_CODE"
    echo "Message follows"
    echo $SERVICE_OUTPUT
    exit 1
fi

sleep $SERVICE_WAIT

# Check that jenkins status returns correctly after restart from stop
SERVICE_OUTPUT=$(service jenkins status 2>&1)
SERVICE_EXIT_CODE=$?
if [ $SERVICE_EXIT_CODE -ne 0]; then
    echo "Jenkins status check after stop failed with exit code $SERVICE_EXIT_CODE"
    echo "Message follows"
    echo $SERVICE_OUTPUT
    exit 1
fi

# Test that Jenkins is actually working after restart... but doing a basic CurL call
CURL_OUTPUT=$(curl -sS 127.0.0.1:8080/jenkins 2>&1)
CURL_EXIT_CODE=$?
if [ $CURL_EXIT_CODE -ne 0]; then
    echo "Curl to jenkins host AFTER RESTART failed with code $CURL_EXIT_CODE"
    echo "Curl error follows"
    echo $CURL_OUTPUT
    exit 1
fi


## TODO break jenkins then try it
#mv /usr/share/jenkins/jenkins.war /usr/share/jenkins/jenkins-broken.war
