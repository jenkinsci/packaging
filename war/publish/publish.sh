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

	rsync \
		--compress \
		--times \
		--recursive \
		--verbose \
		--ignore-existing \
		--progress \
		"${WAR}" "${WARDIR}/${VERSION}/${ARTIFACTNAME}.war"

	rsync \
		--compress \
		--times \
		--recursive \
		--verbose \
		--ignore-existing \
		--progress \
		"${WAR_SHASUM}" "${WARDIR}/${VERSION}/"
}

# Site html need to be located in the binary directory
function uploadSite() {
	rsync \
		--compress \
		--times \
		--recursive \
		--verbose \
		--include "HEADER.html" \
		--include "FOOTER.html" \
		--exclude "*" \
		--progress \
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
