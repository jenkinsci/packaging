#!/bin/bash
set -x  # Exit on any command failure, can't use -u because of check for non-zero length of arg 1

if [ -z "$1" ]; then
  JENKINS_WAR_FILE=$(ls /tmp/packaging/target/war/*.war | head -n 1)
  # Change to /tmp/packaging so that results are written in /tmp/packaging/results
  cd /tmp/packaging
else
  JENKINS_WAR_FILE="$1"
fi

. "$(dirname $0)/sh2ju.sh"

# Debian testing does not set a VERSION_ID, /etc/os-release will replace for stable and oldstable

VERSION_ID=testing

# Read operating system information into variables

. /etc/os-release

OS="${ID}.${VERSION_ID}" # debian.10 or ubuntu.19.10 so that JUnit package naming can be used

strict_signed_war_file_verification_failed="strict signing verification failed on $JENKINS_WAR_FILE"

verify_strict_signed_war_file() {

    jarsigner -verify -strict -signedjar $JENKINS_WAR_FILE $JENKINS_WAR_FILE || echo "$strict_signed_war_file_verification_failed"

}

juLog -error="$strict_signed_war_file_verification_failed" -suite="${OS}.signing" -name="StrictVerifySignedWarFile" verify_strict_signed_war_file

if [[ "$CHECK_CERTS" == "true" ]]; then
    strict_certs_signed_war_file_verification_failed="strict signing verification with certs failed on $JENKINS_WAR_FILE"

    verify_strict_certs_signed_war_file() {

        jarsigner -verify -verbose -strict -certs -signedjar $JENKINS_WAR_FILE $JENKINS_WAR_FILE || echo "$strict_certs_signed_war_file_verification_failed"

    }

    juLog -error="$strict_certs_signed_war_file_verification_failed" -suite="${OS}.signing" -name="StrictCertsVerifySignedWarFile" verify_strict_certs_signed_war_file
fi
