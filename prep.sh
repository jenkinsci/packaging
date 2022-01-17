#!/bin/bash -eux
set -o pipefail
cd "$(dirname "$0")"

# TODO jenkins-infra/release performs similar preparatory actions: downloading
# the WAR and importing the GPG key. A common interface for the preparatory
# actions should be designed that meets the needs of both local testing and
# releases, ideally implemented in the Makefile. Then both this repository and
# jenkins-infra/release should be refactored to consume the new functionality.

if [[ ! -f $WAR ]]; then
	mkdir -p "$(dirname "${WAR}")"
	jv download
fi

if ! gpg --fingerprint "${GPG_KEYNAME}"; then
	gpg --import --batch "${GPG_KEYRING}" "${GPG_SECRET_KEYRING}"
fi

# produces: jenkins.war
exit 0
