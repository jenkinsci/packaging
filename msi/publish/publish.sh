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

	rsync --archive \
		--verbose \
		--progress \
		"${MSI}" "${MSI_SHASUM}" "${MSIDIR}/${VERSION}/"

	# Update the symlink to point to most recent MSI directory
	pushd "${MSIDIR}"
	rm -rf latest # This is a safety measure just in case something was left there previously
	ln -s "${VERSION}" latest
	popd
}

# The site need to be located in the binary directory
function uploadSite() {
	rsync --archive \
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
