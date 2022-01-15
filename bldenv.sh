#!/bin/bash -eux
set -o pipefail
cd "$(dirname "$0")"

WORKSPACE=${WORKSPACE:-/packaging}
JENKINS_VERSION=${JENKINS_VERSION:-latest}
JENKINS_DOWNLOAD_URL=${JENKINS_DOWNLOAD_URL:-https://repo.jenkins-ci.org/releases/org/jenkins-ci/main/jenkins-war/}
WAR=${WAR:-${WORKSPACE}/target/war/jenkins.war}
MSI=${MSI:-${WORKSPACE}/target/msi/jenkins.msi}
BRAND=${BRAND:-${WORKSPACE}/branding/common}
RELEASELINE=${RELEASELINE:-}
ORGANIZATION=${ORGANIZATION:-example.org}
BUILDENV=${BUILDENV:-${WORKSPACE}/env/test.mk}
CREDENTIAL=${CREDENTIAL:-${WORKSPACE}/credentials/test.mk}
GPG_KEYNAME=${GPG_KEYNAME:-test}
GPG_KEYRING=${GPG_KEYRING:-${WORKSPACE}/credentials/${GPG_KEYNAME}.gpg}
GPG_SECRET_KEYRING=${GPG_SECRET_KEYRING:-${WORKSPACE}/credentials/${GPG_KEYNAME}.secret.gpg}

if [[ $# -eq 0 ]]; then
	exec docker run \
		-e "WORKSPACE=${WORKSPACE}" \
		-e "JENKINS_VERSION=${JENKINS_VERSION}" \
		-e "JENKINS_DOWNLOAD_URL=${JENKINS_DOWNLOAD_URL}" \
		-e "WAR=${WAR}" \
		-e "MSI=${MSI}" \
		-e "BRAND=${BRAND}" \
		-e "RELEASELINE=${RELEASELINE}" \
		-e "ORGANIZATION=${ORGANIZATION}" \
		-e "BUILDENV=${BUILDENV}" \
		-e "CREDENTIAL=${CREDENTIAL}" \
		-e "GPG_KEYNAME=${GPG_KEYNAME}" \
		-e "GPG_KEYRING=${GPG_KEYRING}" \
		-e "GPG_SECRET_KEYRING=${GPG_SECRET_KEYRING}" \
		-it \
		--rm \
		-v "${PWD}:${WORKSPACE}" \
		-w "${WORKSPACE}" \
		jenkinsciinfra/packaging:latest \
		/bin/bash
else
	exec docker run \
		-e "WORKSPACE=${WORKSPACE}" \
		-e "JENKINS_VERSION=${JENKINS_VERSION}" \
		-e "JENKINS_DOWNLOAD_URL=${JENKINS_DOWNLOAD_URL}" \
		-e "WAR=${WAR}" \
		-e "MSI=${MSI}" \
		-e "BRAND=${BRAND}" \
		-e "RELEASELINE=${RELEASELINE}" \
		-e "ORGANIZATION=${ORGANIZATION}" \
		-e "BUILDENV=${BUILDENV}" \
		-e "CREDENTIAL=${CREDENTIAL}" \
		-e "GPG_KEYNAME=${GPG_KEYNAME}" \
		-e "GPG_KEYRING=${GPG_KEYRING}" \
		-e "GPG_SECRET_KEYRING=${GPG_SECRET_KEYRING}" \
		--rm \
		-v "${PWD}:${WORKSPACE}" \
		-w "${WORKSPACE}" \
		jenkinsciinfra/packaging:latest \
		/bin/bash -c "$*"
fi
