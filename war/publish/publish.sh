#!/bin/bash

set -euxo pipefail

: "${AGENT_WORKDIR:=/tmp}"
: "${WAR:?Require Jenkins War file}"
: "${WARDIR:? Require where to put binary files}"
: "${WAR_WEBDIR:? Require where to put repository index and other web contents}"

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

function clean() {
	rm -rf "$D"
}

# Convert string to array to correctly escape cli parameter
SSH_OPTS=($SSH_OPTS)

# Generate and publish site content
function generateSite() {
	"$BASE/bin/indexGenerator.py" \
		--distribution war \
		--targetDir "$D"
}

function init() {
	mkdir -p $D

	mkdir -p "${WARDIR}/${VERSION}/"

	ssh "${SSH_OPTS[@]}" "$PKGSERVER" mkdir -p "$WARDIR/${VERSION}/"
}

function skipIfAlreadyPublished() {
	if ssh "${SSH_OPTS[@]}" "$PKGSERVER" test -e "${WARDIR}/${VERSION}/${ARTIFACTNAME}.war"; then
		echo "File already published, nothing else todo"
		exit 0
	fi
}

function uploadPackage() {
	sha256sum "${WAR}" | sed "s, .*, ${ARTIFACTNAME}.war," >"${WAR_SHASUM}"
	cat "${WAR_SHASUM}"

	# Local
	rsync \
		--compress \
		--recursive \
		--verbose \
		--ignore-existing \
		--progress \
		"${WAR}" "${WARDIR}/${VERSION}/${ARTIFACTNAME}.war"

	rsync \
		--compress \
		--recursive \
		--verbose \
		--ignore-existing \
		--progress \
		"${WAR_SHASUM}" "${WARDIR}/${VERSION}/"

	# Remote
	rsync \
		--archive \
		--compress \
		--verbose \
		-e "ssh ${SSH_OPTS[*]}" \
		--ignore-existing \
		--progress \
		"${WAR}" "$PKGSERVER:${WARDIR}/${VERSION}/${ARTIFACTNAME}.war"

	rsync \
		--archive \
		--compress \
		--verbose \
		-e "ssh ${SSH_OPTS[*]}" \
		--ignore-existing \
		--progress \
		"${WAR_SHASUM}" "$PKGSERVER:${WARDIR}/${VERSION}/"
}

# Site html need to be located in the binary directory
function uploadSite() {
	rsync \
		--compress \
		--recursive \
		--verbose \
		--include "HEADER.html" \
		--include "FOOTER.html" \
		--exclude "*" \
		--progress \
		-e "ssh ${SSH_OPTS[*]}" \
		"${D}/" "${WARDIR// /\\ }/"

	rsync \
		--archive \
		--compress \
		--verbose \
		--include "HEADER.html" \
		--include "FOOTER.html" \
		--exclude "*" \
		--progress \
		-e "ssh ${SSH_OPTS[*]}" \
		"${D}/" "$PKGSERVER:${WARDIR// /\\ }/"
}

function show() {
	echo "Parameters:"
	echo "WAR: $WAR"
	echo "WARDIR: $WARDIR"
	echo "SSH_OPTS: ${SSH_OPTS[*]}"
	echo "PKGSERVER: $PKGSERVER"
	echo "---"
}

show
skipIfAlreadyPublished
init
generateSite
uploadPackage
uploadSite
clean
