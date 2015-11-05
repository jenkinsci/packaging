#!/bin/bash
# Verify that service correctly handles starting and stopping process
set -o nounset

#seconds to wait for service operation to finish
SERVICE_WAIT=2

# Report test results, by looking at status code same as expected
# Arg 1: test name text
# Arg 2: test status code output
# Arg 3: test expected status code to pass
# Arg 4: command output variable
function report_test {
    if [ "$2" -ne "$3" ]; then 
        echo "TEST $1 FAILED with status code $2, expected $3"
        echo "Test command output:"
        echo "$4"
    else
        echo "TEST $1 PASSED with expected status code $2"
    fi
}

# Check if jenkins user is present
getent passwd jenkins
USER_TEST=$?
report_test "Verify jenkins user created" $USER_TEST 0 $USER_TEST

# Start service & capture standard error and exit code for service command
SERVICE_OUTPUT=$(service jenkins start 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins initial service start" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

# Test that Jenkins is actually working... by doing a basic CurL call
CURL_OUTPUT=$(curl -sS 127.0.0.1:8080 -o /dev/null 2>&1)
CURL_EXIT_CODE=$?
report_test "Curl to jenkins host" $CURL_EXIT_CODE 0 $CURL_OUTPUT

# Check that jenkins status is correctly returned
SERVICE_OUTPUT=$(service jenkins status 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins service status after initial start" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

# Check that jenkins restarts correctly
SERVICE_OUTPUT=$(service jenkins restart 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins service first restart" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

sleep $SERVICE_WAIT

# Check that jenkins stops cleanly
SERVICE_OUTPUT=$(service jenkins stop 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins service stop" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

sleep $SERVICE_WAIT

# Check that jenkins status returns correctly after stop
SERVICE_OUTPUT=$(service jenkins status 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins service status check when stopped" $SERVICE_EXIT_CODE 3 $SERVICE_OUTPUT

# Check that jenkins restarts correctly from stopped state
SERVICE_OUTPUT=$(service jenkins restart 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins service restart from stopped state" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

sleep $SERVICE_WAIT

# Check that jenkins status returns correctly after restart from stop
SERVICE_OUTPUT=$(service jenkins status 2>&1)
SERVICE_EXIT_CODE=$?
report_test "Jenkins service status after restart from stopped state" $SERVICE_EXIT_CODE 0 $SERVICE_OUTPUT

# Test that Jenkins is actually working after restart... by doing a basic CurL call
CURL_OUTPUT=$(curl -sS 127.0.0.1:8080 -o /dev/null 2>&1)
CURL_EXIT_CODE=$?
report_test "Curl to jenkins host AFTER restart from stopped" $CURL_EXIT_CODE 0 $CURL_OUTPUT


## TODO break jenkins then try it
#mv /usr/share/jenkins/jenkins.war /usr/share/jenkins/jenkins-broken.war
