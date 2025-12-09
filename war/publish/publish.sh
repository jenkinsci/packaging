#!/bin/bash

set -euxo pipefail

: "${AGENT_WORKDIR:=/tmp}"
: "${WAR:?Require Jenkins War file}"
: "${WARDIR:? Require where to put binary files}"

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

function clean() {
	rm -rf "$D"
}

# Generate and publish site content
function generateSite() {
	"$BASE/bin/indexGenerator.py" \
		--distribution war \
		--targetDir "$D"
}

function init() {
	mkdir -p "$D" "${WARDIR}/${VERSION}/"
}

function uploadPackage() {
	sha256sum "${WAR}" | sed "s, .*, ${ARTIFACTNAME}.war," >"${WAR_SHASUM}"
	cat "${WAR_SHASUM}"

	# Update the symlink to point to most recent Windows build
	#
	# Remove anything in current directory named 'latest'
	# This is a safety measure just in case something was left there previously
	rm -rf latest

	# Create a local symlink pointing to the MSI file in the VERSION directory.
	# Don't need VERSION directory or MSI locally, just the unresolved symlink.
	# The jenkins.io page downloads http://mirrors.jenkins-ci.org/windows/latest
	# and assumes it points to the most recent MSI file.
	ln -s "${VERSION}/$(basename "$WAR")" latest

	rsync --archive \
		--verbose \
		--progress \
		"${WAR}" "${WAR_SHASUM}" latest "${WARDIR}/${VERSION}/"
}

# Site html need to be located in the binary directory
function uploadSite() {
	rsync --archive \
		--verbose \
		--progress \
		--include "HEADER.html" \
		--include "FOOTER.html" \
		--exclude "*" \
		"${D}/" "${WARDIR// /\\ }/"
}

function show() {
	echo "Parameters:"
	echo "WAR: $WAR"
	echo "WARDIR: $WARDIR"
	echo "---"
}

show
init
generateSite
uploadPackage
uploadSite
clean
