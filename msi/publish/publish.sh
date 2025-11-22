#!/bin/bash

set -euxo pipefail

: "${AGENT_WORKDIR:=/tmp}"
: "${MSI:?Require Jenkins War file}"
: "${MSIDIR:? Require where to put binary files}"

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

function clean() {
	rm -rf "$D"
}

# Generate and publish site content
function generateSite() {
	"$BASE/bin/indexGenerator.py" \
		--distribution windows \
		--targetDir "$MSIDIR"
}

function init() {
	mkdir -p "$D" "${MSIDIR}/${VERSION}"
}

function uploadPackage() {
	cp "${ARTIFACTNAME}-${VERSION}${RELEASELINE}.msi" "${MSI}"

	sha256sum "${MSI}" >"${MSI_SHASUM}"

	cat "${MSI_SHASUM}"

	# Local
	rsync --archive \
		--times \
		--verbose \
		--progress \
		"${MSI}" "${MSIDIR}/${VERSION}/"

	rsync --archive \
		--times \
		--verbose \
		--progress \
		"${MSI_SHASUM}" "${MSIDIR}/${VERSION}/"

	# Update the symlink to point to most recent Windows build
	#
	# Remove anything in current directory named 'latest'
	# This is a safety measure just in case something was left there previously
	rm -rf latest

	# Create a local symlink pointing to the MSI file in the VERSION directory.
	# Don't need VERSION directory or MSI locally, just the unresolved symlink.
	# The jenkins.io page downloads http://mirrors.jenkins-ci.org/windows/latest
	# and assumes it points to the most recent MSI file.
	ln -s "${VERSION}/$(basename "$MSI")" latest

	# Overwrites the existing symlink on the destination
	rsync --archive \
		--times \
		--verbose \
		--progress \
		latest "${MSIDIR}/"

	# Remove the local symlink
	rm -f latest
}

# The site need to be located in the binary directory
function uploadSite() {
	rsync --archive \
		--times \
		--verbose \
		--progress \
		"${D}/" "${MSIDIR// /\\ }/"
}

function show() {
	echo "Parameters:"
	echo "MSI: $MSI"
	echo "MSIDIR: $MSIDIR"
	echo "---"
}

show
init
generateSite
uploadPackage
uploadSite
