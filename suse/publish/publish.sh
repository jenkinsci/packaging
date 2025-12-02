#!/bin/bash

set -euxo pipefail

: "${AGENT_WORKDIR:=/tmp}"
: "${GPG_KEYNAME:?Required valid gpg keyname}"
: "${BASE:?Require base directory}"
: "${SUSEDIR:? Require where to put binary files}"
: "${SUSE_WEBDIR:? Require where to put repository index and other web contents}"

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

function clean() {
	rm -rf "$D"
}

function generateSite() {
	local gpg_publickey="$D/repodata/repomd.xml.key"
	mkdir -p "$(dirname "${gpg_publickey}")"
	gpg --export -a --output "${gpg_publickey}" "${GPG_KEYNAME}"
	gpg --import-options show-only --import "${gpg_publickey}" >"$D/${ORGANIZATION}.key.info"

	cat >"$D/${ARTIFACTNAME}.repo" <<EOF
[${ARTIFACTNAME}]
name=${PRODUCTNAME}${RELEASELINE}
enabled=1
type=rpm-md
baseurl=${SUSE_URL}
gpgkey=${SUSE_URL}/repodata/repomd.xml.key
gpgcheck=1
repo_gpgcheck=1

autorefresh=1
keeppackages=0
EOF

	"$BASE/bin/indexGenerator.py" \
		--distribution opensuse \
		--targetDir "${D}"

	"$BASE/bin/branding.py" "$D"

	cp "$SUSE" "$D/RPMS/noarch"

	createrepo_c --update -o "${SUSE_WEBDIR}" "${SUSEDIR}"
	cat "${SUSE_WEBDIR}/repodata/repomd.xml" | \
	gpg \
		--batch \
		--pinentry-mode loopback \
		-u "$GPG_KEYNAME" \
		-a \
		--detach-sign \
		--passphrase-file "$GPG_PASSPHRASE_FILE" \
		--yes | \
		cat > "$SUSE_WEBDIR/repodata/repomd.xml.asc"
}

function init() {
	mkdir -p "${D}/RPMS/noarch" "${D}/repodata" "${SUSEDIR}" "${SUSE_WEBDIR}"
}

function show() {
	echo "Parameters:"
	echo "SUSE: $SUSE"
	echo "SUSEDIR: $SUSEDIR"
	echo "SUSE_WEBDIR: $SUSE_WEBDIR"
	echo "SUSE_URL: $SUSE_URL"
	echo "GPG_KEYNAME: $GPG_KEYNAME"
	echo "---"
}

function uploadPackage() {
	rsync --archive \
		--verbose \
		--progress \
		"${SUSE}" "${SUSEDIR}/" # Local
}

function uploadSite() {
	pushd "$D"
	rsync --archive \
		--verbose \
		--progress \
		--exclude RPMS \
		--exclude "HEADER.html" \
		--exclude "FOOTER.html" \
		. "${SUSE_WEBDIR}/" #Local

	# Following html need to be located inside the binary directory
	rsync --archive \
		--verbose \
		--progress \
		--include "HEADER.html" \
		--include "FOOTER.html" \
		--exclude "*" \
		--progress \
		. "${SUSEDIR}/"
	popd
}

show
init
uploadPackage
generateSite
uploadSite
clean
