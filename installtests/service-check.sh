#!/bin/bash
# Verify that linux init services correctly handle starting and stopping Jenkins
set -o nounset

#seconds to wait for service operation to finish
SERVICE_WAIT=2

# TODO allow passing the artifact name as an arg

# Read artifact name as first arg
if [ -z "$1" ]; then
    ARTIFACT_NAME=jenkins
else
    ARTIFACT_NAME="$1"
fi

error_count=0

# Report test results, by looking at status code same as expected
# Arg 1: test name text
# Arg 2: test status code output
# Arg 3: test expected status code to pass
# Arg 4: command output variable
function report_test {
    if [ "$2" -ne "$3" ]; then 
        echo "TEST FAILED - $1 - with status code $2, expected $3"
        echo "Test command output:"
        echo "$4"
        error_count=$((error_count+1))
    else
        echo "TEST PASSED - $1  with expected status code $2"
    fi
}

# Check if jenkins user is present
# TODO add check for jenkins group too...
getent passwd $ARTIFACT_NAME
USER_TEST=$?
report_test "Verify jenkins user created" $USER_TEST 0 $USER_TEST

SERVICE_OUTPUT=$(service $ARTIFACT_NAME start 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins initial service start" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

echo "Pausing briefly to allow for initial Jenkins startup"
sleep 5 # Delay for initial startup before server becomes responsive
CURL_OUTPUT=$(curl -sS 127.0.0.1:8080 -o /dev/null 2>&1)
CURL_EXIT_CODE=$?
report_test "Curl to jenkins host" $CURL_EXIT_CODE 0 $CURL_OUTPUT

SERVICE_OUTPUT=$(service $ARTIFACT_NAME status 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins service status after initial start" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

SERVICE_OUTPUT=$(service $ARTIFACT_NAME restart 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins service first restart from running" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

sleep $SERVICE_WAIT

SERVICE_OUTPUT=$(service $ARTIFACT_NAME stop 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins service stop" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

sleep $SERVICE_WAIT

SERVICE_OUTPUT=$(service $ARTIFACT_NAME status 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins service status check when stopped" $SERVICE_EXIT_CODE 3 $SERVICE_OUTPUT

SERVICE_OUTPUT=$(service $ARTIFACT_NAME restart 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins service restart from stopped state" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

sleep $SERVICE_WAIT

SERVICE_OUTPUT=$(service $ARTIFACT_NAME status 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins service status after restart from stopped state" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

echo "Waiting briefly for service to start before trying to communicate with it"
sleep 5
CURL_OUTPUT=$(curl -sS 127.0.0.1:8080 -o /dev/null 2>&1)
CURL_EXIT_CODE=$?
report_test "Curl to jenkins host AFTER restart from stopped" $CURL_EXIT_CODE 0 $CURL_OUTPUT


## BREAK jenkins and then see how the service scripts behave
service $ARTIFACT_NAME stop
sleep $SERVICE_WAIT

JENKINS_WAR_PATH=$(dirname $(readlink -f $(cd / && find -iname $ARTIFACT_NAME.war | grep -v /tmp)))
mv "$JENKINS_WAR_PATH/${ARTIFACT_NAME}.war" "$JENKINS_WAR_PATH/${ARTIFACT_NAME}-broken.war"

# Should fail to start
SERVICE_OUTPUT=$(service $ARTIFACT_NAME start 2>&1)
SERVICE_EXIT_CODE=$?
TESTNAME="Start Jenkins service where Jenkins will fail to start"
if [ $SERVICE_EXIT_CODE -eq 0 ]; then 
    echo "$TESTNAME FAILED with status code $SERVICE_EXIT_CODE, expected NOT 0 (failure)"
    echo "Test command output:"
    echo "$SERVICE_OUTPUT"
    error_count=$((error_count+1))
else
    echo "$TESTNAME PASSED with status code $SERVICE_EXIT_CODE"
fi

# Should fail to start
SERVICE_OUTPUT=$(service $ARTIFACT_NAME restart 2>&1)
SERVICE_EXIT_CODE=$?
TESTNAME="Restart Jenkins service where Jenkins will fail to start"
if [ $SERVICE_EXIT_CODE -eq 0 ]; then 
    echo "$TESTNAME FAILED with status code $SERVICE_EXIT_CODE, expected NOT 0 (failure)"
    echo "Test command output:"
    echo "$SERVICE_OUTPUT"
    error_count=$((error_count+1))
else
    echo "$TESTNAME PASSED with status code $SERVICE_EXIT_CODE"
fi

mv "$JENKINS_WAR_PATH/${ARTIFACT_NAME}-broken.war" "$JENKINS_WAR_PATH/${ARTIFACT_NAME}.war"

echo "TOTAL service check test failure count: $error_count"
if [ $error_count -ne 0 ]; then
    exit $error_count
fi