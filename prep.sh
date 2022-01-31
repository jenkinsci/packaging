#!/bin/bash -eux
set -o pipefail
cd "$(dirname "$0")"

# TODO jenkins-infra/release performs similar preparatory actions: downloading
# the WAR and importing the GPG key. A common interface for the preparatory
# actions should be designed that meets the needs of both local testing and
# releases, ideally implemented in the Makefile. Then both this repository and
# jenkins-infra/release should be refactored to consume the new functionality.

if [[ ! -f $WAR ]]; then
	# TODO Jenkins 2.333
	curl -o jenkins.war https://repo.jenkins-ci.org/incrementals/org/jenkins-ci/main/jenkins-war/2.333-rc32035.1a_4204434750/jenkins-war-2.333-rc32035.1a_4204434750.war
fi

if ! gpg --fingerprint "${GPG_KEYNAME}"; then
	gpg --import --batch "${GPG_FILE}"
fi

# produces: jenkins.war
exit 0
