#!/bin/bash
# Verify that linux init services correctly handle starting and stopping Jenkins
# ARGUMENTS: first argument is the artifact name, jenkins by default if not given
# Second argument is the port number it will run on for testing

. `dirname $0`/sh2ju.sh

SERVICE_WAIT=5
MAX_START_WAIT=120
MAX_STOP_WAIT=45

# Read artifact name as first arg
if [ -z "$1" ]; then
    ARTIFACT_NAME=jenkins
else
    ARTIFACT_NAME="$1"
fi

if [ -z "$2" ]; then
    PORT=8080
else
    PORT="$2"
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

# Run a test and look for a specific result
# Keep running the test every second until it either passes or timout occurs
function repeatedly_test {
    local run_command="$1"
    local expected_status=$2
    local max_time=$3
    local test_name="$4"
    local elapsed=0
    local exit_code=0
    local output=""

    while [ $elapsed -lt $max_time ]; do
        output=$(eval $run_command)
        exit_code=$?
        if [ $exit_code -ne "$expected_status" ]; then
            # Failed, let's wait and retry if time is left
            elapsed=$((elapsed+1))
            sleep 1
        else  # Success!
            report_test "$test_name" $exit_code $expected_status "$output"
            return 0
        fi
    done
    report_test "$test_name - with repeated tests on timeout $max_time" $exit_code $expected_status "$output"
    return 1
}

# Check if jenkins user is present
# TODO add check for jenkins group too...
getent passwd "$ARTIFACT_NAME"
USER_TEST=$?
juLog -name=createUserTest report_test "Verify $ARTIFACT_NAME user created" $USER_TEST 0 $USER_TEST

SERVICE_OUTPUT=$(service "$ARTIFACT_NAME" start 2>&1)
SERVICE_EXIT_CODE=$?
juLog -name=initialServiceStartTest report_test "$ARTIFACT_NAME initial service start" $SERVICE_EXIT_CODE 0 "$SERVICE_OUTPUT"

# Try to check service status and verify it eventually resolves as running
COMMAND='service "$ARTIFACT_NAME" status 2>&1'
juLog -name=serviceStatusRunningTest repeatedly_test "$COMMAND" 0 "$MAX_START_WAIT" "$ARTIFACT_NAME service status after initial start"

# Try to curl the server and verify status resolves as started
COMMAND='curl -sS 127.0.0.1:$PORT -o /dev/null 2>&1'
juLog -name=curlTest repeatedly_test "$COMMAND" 0 "$MAX_START_WAIT" "Curl to host"

SERVICE_OUTPUT=$(service "$ARTIFACT_NAME" restart 2>&1)
SERVICE_EXIT_CODE=$?
juLog -name=serviceRestartTest report_test "$ARTIFACT_NAME service first restart from running" $SERVICE_EXIT_CODE 0 "$SERVICE_OUTPUT"

sleep $SERVICE_WAIT

SERVICE_OUTPUT=$(service "$ARTIFACT_NAME" stop 2>&1)
SERVICE_EXIT_CODE=$?
juLog -name=serviceStopTest report_test "$ARTIFACT_NAME service stop" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

# Test status comes up as stopped eventually
COMMAND='service "$ARTIFACT_NAME" status 2>&1'
juLog -name=serviceStatusStoppedTest repeatedly_test "$COMMAND" 3 "$MAX_STOP_WAIT" "$ARTIFACT_NAME service status check when stopped"

SERVICE_OUTPUT=$(service "$ARTIFACT_NAME" restart 2>&1)
SERVICE_EXIT_CODE=$?
juLog -name=serviceRestartFromStoppedTest report_test "$ARTIFACT_NAME service restart from stopped state" $SERVICE_EXIT_CODE 0 "$SERVICE_OUTPUT"

# Try to check service status and verify it eventually resolves as running
COMMAND='service "$ARTIFACT_NAME" status 2>&1'
juLog -name=serviceRestartedCheckTest repeatedly_test "$COMMAND" 0 "$MAX_START_WAIT" "$ARTIFACT_NAME service status after restart from stopped state"

# Try to curl the server and verify status resolves as started
COMMAND='curl -sS 127.0.0.1:$PORT -o /dev/null 2>&1'
juLog -name=curlAfterRestartedTest repeatedly_test "$COMMAND" 0 "$MAX_START_WAIT" "Curl to host AFTER restart from stopped"


## BREAK jenkins and then see how the service scripts behave
service $ARTIFACT_NAME stop
sleep $SERVICE_WAIT

JENKINS_WAR_PATH=$(dirname $(cd / && readlink -f $(cd / && find -iname $ARTIFACT_NAME.war 2>/dev/null | grep -v /tmp | grep -v workspace | grep -v packaging | grep -v Permission)))
echo "JENKINS WAR FOUND AT $JENKINS_WAR_PATH"
mv "$JENKINS_WAR_PATH/${ARTIFACT_NAME}.war" "$JENKINS_WAR_PATH/${ARTIFACT_NAME}-broken.war"

# Should fail to start
SERVICE_OUTPUT=$(service "$ARTIFACT_NAME" start 2>&1)
SERVICE_EXIT_CODE=$?
TESTNAME="Start $ARTIFACT_NAME service where it should fail to start"
if [ $SERVICE_EXIT_CODE -eq 0 ]; then
    echo "$TESTNAME FAILED with status code $SERVICE_EXIT_CODE, expected NOT 0 (failure)"
    echo "Test command output:"
    echo "$SERVICE_OUTPUT"
    error_count=$((error_count+1))
else
    echo "$TESTNAME PASSED with status code $SERVICE_EXIT_CODE"
fi

# Should fail to start
SERVICE_OUTPUT=$(service "$ARTIFACT_NAME" restart 2>&1)
SERVICE_EXIT_CODE=$?
TESTNAME="Restart $ARTIFACT_NAME service where it should fail to start"
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
