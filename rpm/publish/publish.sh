#!/bin/bash
set -euxo pipefail

: "${AGENT_WORKDIR:=/tmp}"
: "${GPG_KEYNAME:?Require valid gpg keyname}"
: "${RPMDIR:?Require where to put binary files}"
: "${RPM_WEBDIR:?Require where to put index and other web contents}"
: "${RPM_URL:?Require rpm repository url}"
: "${RELEASELINE?Require rpm release line}"
: "${BASE:?Require base directory}"

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
baseurl=${RPM_URL}
gpgkey=${RPM_URL}/repodata/repomd.xml.key
gpgcheck=1
repo_gpgcheck=1

# Only for SUSE/openSUSE distributions with zypper
autorefresh=1
keeppackages=0
EOF

	"$BASE/bin/indexGenerator.py" \
		--distribution rpm \
		--gpg-key-info-file "${D}/${ORGANIZATION}.key.info" \
		--targetDir "$D"

	"$BASE/bin/branding.py" "$D"

	cp "$RPM" "$D/RPMS/noarch"

	createrepo_c --update -o "${RPM_WEBDIR}" "${RPMDIR}"
	cat "${RPM_WEBDIR}/repodata/repomd.xml" | \
	gpg \
		--batch \
		--pinentry-mode loopback \
		-u "$GPG_KEYNAME" \
		-a \
		--detach-sign \
		--passphrase-file "$GPG_PASSPHRASE_FILE" \
		--yes | \
		cat > "$RPM_WEBDIR/repodata/repomd.xml.asc"
}

function init() {
	mkdir -p "$D/RPMS/noarch" "${RPMDIR}" "${RPM_WEBDIR}"
}

function uploadPackage() {
	rsync --archive \
		--verbose \
		--progress \
		"$RPM" "$RPMDIR/"
}

function show() {
	echo "Parameters:"
	echo "RPM: $RPM"
	echo "RPMDIR: $RPMDIR"
	echo "RPM_WEBDIR: $RPM_WEBDIR"
	echo "GPG_KEYNAME: $GPG_KEYNAME"
	echo "---"
}

function uploadSite() {
	pushd "$D"
	rsync --archive \
		--verbose \
		--progress \
		--exclude RPMS \
		--exclude "HEADER.html" \
		--exclude "FOOTER.html" \
		. "${RPM_WEBDIR}/"

	# Following html need to be located inside the binary directory
	rsync --archive \
		--verbose \
		--progress \
		--include "HEADER.html" \
		--include "FOOTER.html" \
		--exclude "*" \
		. "${RPMDIR}/"
	popd
}

show
init
uploadPackage
generateSite
uploadSite
clean
