#!/bin/bash

set -euxo pipefail

: "${AGENT_WORKDIR:=/tmp}"
: "${GPG_KEYNAME:?Require valid gpg keyname}"
: "${DEB:?Require Debian package}"
: "${DEBDIR:? Require where to put binary files}"
: "${DEB_WEBDIR:? Require where to put repository index and other web contents}"
: "${DEB_URL:? Require Debian repository Url}"
: "${GPG_PUBLIC_KEY_FILENAME:="${ORGANIZATION}.key"}"

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

bin="$(dirname "$0")"

function clean() {
	rm -rf "$D"
}

# Generate and publish site content
function generateSite() {
	local gpg_publickey_file="$D/contents/${GPG_PUBLIC_KEY_FILENAME}"
	local gpg_publickey_info_file="$D/contents/${GPG_PUBLIC_KEY_FILENAME}.info"
	gpg --export -a --output "${gpg_publickey_file}" "${GPG_KEYNAME}"
	gpg --import-options show-only --import "${gpg_publickey_file}" > "${gpg_publickey_info_file}"

	"$BASE/bin/indexGenerator.py" \
		--distribution debian \
		--gpg-key-info-file "${gpg_publickey_info_file}" \
		--targetDir "$D/html"

	"$BASE/bin/branding.py" "$D"

	# build package index
	# see http://wiki.debian.org/SecureApt for more details
	cp "${DEB}" "$D/binary/"

	pushd "$D"
	apt-ftparchive packages binary >binary/Packages
	apt-ftparchive contents binary >binary/Contents
	popd

	# Remote ftparchive-merge
	# https://github.com/kohsuke/apt-ftparchive-merge
	pushd "$D/binary"
	mvn -V org.kohsuke:apt-ftparchive-merge:1.6:merge -Durl="$DEB_URL/binary/" -Dout=../merged
	popd

	# Local ftparchive-merge

	cat "$D/merged/Packages" >"$D/binary/Packages"
	gzip -9c "$D/merged/Packages" >"$D/binary/Packages.gz"
	bzip2 -c "$D/merged/Packages" >"$D/binary/Packages.bz2"
	lzma -c "$D/merged/Packages" >"$D/binary/Packages.lzma"
	gzip -9c "$D/merged/Contents" >"$D/binary/Contents.gz"

	apt-ftparchive -c "$bin/release.conf" release "$D/binary" >"$D/binary/Release"
}

function init() {
	mkdir -p "$D/binary" "$D/contents" "$D/html" "$D/contents/binary" \
		"$DEBDIR" `# where to put binary files` \
		"$DEB_WEBDIR" `# where to put repository index and other web contents`
}

# Upload Debian Package
function uploadPackage() {
	rsync --archive \
		--verbose \
		--progress \
		"$DEB" "$DEBDIR/"
}

function uploadPackageSite() {
	cp \
		"$D"/binary/Packages* \
		"$D"/binary/Release \
		"$D"/binary/Release.gpg \
		"$D"/binary/Contents* \
		"$D"/contents/binary

	rsync --archive \
		--verbose \
		--progress \
		"$D/contents/" "$DEB_WEBDIR/"
}

function uploadHtmlSite() {
	rsync --archive \
		--verbose \
		--progress \
		"$D/html/" "$DEB_WEBDIR/"
}

function show() {
	echo "Parameters:"
	echo "DEB: $DEB"
	echo "DEBDIR: $DEBDIR"
	echo "DEB_WEBDIR: $DEB_WEBDIR"
	echo "GPG_KEYNAME: $GPG_KEYNAME"
	echo "GPG_PUBLIC_KEY_FILENAME: $GPG_PUBLIC_KEY_FILENAME"
	echo "---"
}

function signSite() {
	# sign the release file
	if [ -f "$D/binary/Release.gpg" ]; then
		rm "$D/binary/Release.gpg"
	fi

	gpg \
		--batch \
		--pinentry-mode loopback \
		--digest-algo=sha256 \
		-u "$GPG_KEYNAME" \
		--passphrase-file "$GPG_PASSPHRASE_FILE" \
		-abs \
		-o "$D/binary/Release.gpg" \
		"$D/binary/Release"
}

show
init
generateSite
signSite

uploadPackage
uploadPackageSite

uploadHtmlSite
clean
