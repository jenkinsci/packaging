#!/bin/bash -eux
set -o pipefail
cd "$(dirname "$0")"

# TODO jenkins-infra/release performs similar preparatory actions: downloading
# the WAR and importing the GPG key. A common interface for the preparatory
# actions should be designed that meets the needs of both local testing and
# releases, ideally implemented in the Makefile. Then both this repository and
# jenkins-infra/release should be refactored to consume the new functionality.

# Harcoding a safe Weekly version to 2.541 in this stable-2.541 branch for 2.541 LTS as 2.545 doesn't currently pass tests
safeWeeklyVersion="2.541"

if [[ ! -f "$WAR" ]]; then
	# # jv utilizes the JENKINS_VERSION environment variable which can be the line (latest/weekly/lts/stable) or an exact version
	# jv download --version-identifier "${jenkinsVersion}"

	# Using hardcoded safe version for this stable branch
	jv download --version-identifier "${safeWeeklyVersion}"
fi

if [[ ! -f "${WAR}.asc" ]]; then
	# # jv utilizes the JENKINS_VERSION environment variable which can be the line (latest/weekly/lts/stable) or an exact version
	# jenkinsVersion="$(jv get)"

	# Using hardcoded safe version for this stable branch
	jenkinsVersion="${safeWeeklyVersion}"

	# Download signature from Artifactory (signed by Maven during the release process)
	# TODO: switch to get.jenkins.io once https://github.com/jenkins-infra/helpdesk/issues/4055 is finished
	warSignatureUrl="https://repo.jenkins-ci.org/releases/org/jenkins-ci/main/jenkins-war/${jenkinsVersion}/jenkins-war-${jenkinsVersion}.war.asc"
	curl --fail --silent --show-error --location --output "${WAR}.asc" \
		"${warSignatureUrl}"
fi

if ! gpg --fingerprint "${GPG_KEYNAME}"; then
	gpg --import --batch "${GPG_FILE}"
fi

# produces: jenkins.war
exit 0
